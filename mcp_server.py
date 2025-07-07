import anyio
from mcp.server.fastmcp import FastMCP
from mcp.server.fastmcp.tools import Tool
from rag import RagEngine, WebSearch

rag_engine = RagEngine()
web_search = WebSearch()

async def tool_search_docs(query: str) -> str:
    """Search indexed documents for the query"""
    return rag_engine.search(query)

async def tool_search_web(query: str) -> str:
    """Perform a web search using Serper"""
    return web_search.search(query)

mcp = FastMCP(
    name="RAG-MCP",
    tools=[
        Tool.from_function(tool_search_docs, description="Search PDF docs"),
        Tool.from_function(tool_search_web, description="Search the web"),
    ],
    port=8899,
)

if __name__ == "__main__":
    # Run the MCP server over HTTP on port 8899
    anyio.run(lambda: mcp.run("streamable-http"))


