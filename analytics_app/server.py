"""
Olist Analytics MCP Server.

Exposes the dbt-modeled OLIST.MARTS layer to Claude as MCP tools.
Tools:
  - get_schema_context() -> structured description of marts + columns
  - run_query(sql)       -> execute read-only SELECT against OLIST.MARTS
"""

import json
import os
import re
from pathlib import Path

import snowflake.connector
from dotenv import load_dotenv
from mcp.server.fastmcp import FastMCP

# Load credentials from .env (sits next to this file)
load_dotenv(Path(__file__).parent / ".env")

# Path to the dbt manifest (relative to repo root)
MANIFEST_PATH = (
    Path(__file__).parent.parent
    / "olist_analytics"
    / "target"
    / "manifest.json"
)

# MCP server instance — the name is what Claude Desktop will show
mcp = FastMCP("olist-analytics")


def _snowflake_connection():
    """Open a fresh Snowflake connection scoped to OLIST.MARTS."""
    return snowflake.connector.connect(
        account=os.environ["SNOWFLAKE_ACCOUNT"],
        user=os.environ["SNOWFLAKE_USER"],
        password=os.environ["SNOWFLAKE_PASSWORD"],
        warehouse=os.environ["SNOWFLAKE_WAREHOUSE"],
        database=os.environ["SNOWFLAKE_DATABASE"],
        schema=os.environ["SNOWFLAKE_SCHEMA"],
        role=os.environ["SNOWFLAKE_ROLE"],
    )


def _load_marts_schema():
    """
    Parse manifest.json and return only the marts models with their
    descriptions and column descriptions — the curated schema surface.
    """
    if not MANIFEST_PATH.exists():
        return {
            "error": (
                f"manifest.json not found at {MANIFEST_PATH}. "
                "Run `dbtf compile --write-catalog` in the dbt project first."
            )
        }

    manifest = json.loads(MANIFEST_PATH.read_text())
    marts = {}

    for node_id, node in manifest.get("nodes", {}).items():
        # Only include models in the marts folder
        if node.get("resource_type") != "model":
            continue
        if "marts" not in node.get("fqn", []):
            continue

        name = node["name"]
        marts[name] = {
            "description": node.get("description", "").strip(),
            "columns": {
                col_name: col.get("description", "").strip()
                for col_name, col in node.get("columns", {}).items()
            },
        }

    return marts


@mcp.tool()
def get_schema_context() -> str:
    """
    Return a structured description of every model and column available to query.
    Use this BEFORE writing SQL to understand the available tables, columns,
    grain, and any gotchas documented in column descriptions.
    """
    schema = _load_marts_schema()
    if "error" in schema:
        return schema["error"]

    # Format as readable text — Claude parses prose well
    lines = ["# OLIST.MARTS — available models", ""]
    for model, info in sorted(schema.items()):
        lines.append(f"## {model}")
        if info["description"]:
            lines.append(info["description"])
        lines.append("")
        lines.append("Columns:")
        for col, desc in info["columns"].items():
            line = f"  - {col}"
            if desc:
                line += f" — {desc}"
            lines.append(line)
        lines.append("")

    return "\n".join(lines)


# Patterns we refuse to execute, no matter what
_FORBIDDEN_PATTERNS = [
    r"\bINSERT\b",
    r"\bUPDATE\b",
    r"\bDELETE\b",
    r"\bDROP\b",
    r"\bTRUNCATE\b",
    r"\bALTER\b",
    r"\bCREATE\b",
    r"\bMERGE\b",
    r"\bGRANT\b",
    r"\bREVOKE\b",
]


def _validate_sql(sql: str) -> str | None:
    """Return an error message if the SQL is unsafe; None if it's OK."""
    upper = sql.upper()
    for pattern in _FORBIDDEN_PATTERNS:
        if re.search(pattern, upper):
            return f"Query rejected: contains forbidden keyword matching {pattern}."
    if not re.search(r"\bSELECT\b", upper) and not re.search(r"\bWITH\b", upper):
        return "Query rejected: must be a SELECT or WITH (CTE) statement."
    return None


@mcp.tool()
def run_query(sql: str) -> str:
    """
    Execute a read-only SELECT (or WITH/CTE) query against OLIST.MARTS.
    Returns the results as JSON. The query is validated to reject any
    write statements. Limit results to keep responses manageable —
    add LIMIT clauses for exploratory queries.
    """
    error = _validate_sql(sql)
    if error:
        return error

    try:
        conn = _snowflake_connection()
        with conn.cursor(snowflake.connector.DictCursor) as cur:
            cur.execute(sql)
            rows = cur.fetchall()
            # Convert any non-JSON-serializable types (dates, decimals) to strings
            rows = [
                {k: (str(v) if v is not None else None) for k, v in r.items()}
                for r in rows
            ]
        conn.close()

        return json.dumps(
            {
                "row_count": len(rows),
                "rows": rows[:100],  # cap returned rows so context doesn't explode
                "truncated": len(rows) > 100,
            },
            indent=2,
        )
    except Exception as e:
        return f"Query failed: {e}"


if __name__ == "__main__":
    mcp.run()