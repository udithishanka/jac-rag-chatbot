import logging
import sys
import os

log_dir = "logs"
os.makedirs(log_dir, exist_ok=True)
log_file_path = os.path.join(log_dir, "mcp_server.log")

logging.basicConfig(
    level=logging.DEBUG,  # Or INFO if you want less verbosity
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler(log_file_path),
        logging.StreamHandler(sys.stdout)  # Logs also to console
    ]
)
logger = logging.getLogger(__name__)

from mcp.server.fastmcp import FastMCP
from mcp.server.fastmcp.tools import Tool
from tools import RagEngine, WebSearch

rag_engine = RagEngine()
web_search = WebSearch()

async def tool_search_docs(query: str) -> str:
    """Search indexed documents for the query"""
    logger.info(f"Searching documents with query: {query}")
    try:
        result = rag_engine.search(query)
        logger.debug(f"Document search result: {result}")
        return result
    except Exception as e:
        logger.exception("Error while searching documents")
        return "An error occurred while searching documents."

async def tool_search_web(query: str) -> str:
    logger.info(f"Performing web search for query: {query}")
    try:
        web_search_results = web_search.search(query)
        logger.info(f"Raw search result: {repr(web_search_results)}")  # <<<< ADD THIS
        logger.info(f"Processed web search result: {web_search_results}")

        return web_search_results
    except Exception as e:
        logger.exception("Exception during web search")
        return "An error occurred while performing web search."


mcp = FastMCP(
    name="RAG-MCP",
    tools=[
        Tool.from_function(tool_search_docs, description="Search PDF docs", name="search_docs"),
        Tool.from_function(tool_search_web, description="Search the web", name="search_web"),
    ],
    port=8899,  # Run the MCP server over HTTP on port 8899
)

if __name__ == "__main__":
    mcp.run("streamable-http")


