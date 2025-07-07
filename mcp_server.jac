import sys;
import os;
import from rag {RagEngine, WebSearch}
import from mcp.server.fastmcp.tools {Tool}
import from mcp.server.fastmcp {FastMCP}

glob rag_engine: RagEngine = RagEngine();
glob web_search: WebSearch = WebSearch();


with entry {
    async def tool_search_docs(query: str) -> str {
        return rag_engine.search(query);
    }

    async def tool_search_web(query: str) -> str{
        web_search_results = web_search.search(query);
        if not web_search_results {
            return "Mention No results found for the web search";
        }
        return web_search_results;
    }

    mcp = FastMCP(
        name="RAG-MCP",
        tools=[
            Tool.from_function(tool_search_docs, description="Search PDF docs", name="search_docs"),
            Tool.from_function(tool_search_web, description="Search the web", name="search_web"),
        ],
        port=8899,  # Run the MCP server over HTTP on port 8899
    );
    mcp.run("streamable-http");
}
