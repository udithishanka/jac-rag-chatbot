import sys;
import os;
import typing;
import from rag {RagEngine, WebSearch};
import from mcp.server.fastmcp {FastMCP};

# Helper to ensure Python type hints are preserved

def resolve_hints(fn: typing.Callable) -> typing.Callable {
    fn.__annotations__ = typing.get_type_hints(fn, include_extras=True);
    return fn;
}

obj MCPServer {
    has rag_engine: RagEngine = RagEngine();
    has web_search: WebSearch = WebSearch();
    has mcp: FastMCP;

    def postinit {
        self.mcp = FastMCP(name="RAG-MCP", port=8899);
        # register tools on initialization
        self.mcp.tool(name="search_docs")(resolve_hints(self.tool_search_docs));
        self.mcp.tool(name="search_web")(resolve_hints(self.tool_search_web));
    }

    async def tool_search_docs(query: str) -> str {
        return self.rag_engine.search(query);
    }

    async def tool_search_web(query: str) -> str {
        web_search_results = self.web_search.search(query);
        if not web_search_results {
            return "Mention No results found for the web search";
        }
        return web_search_results;
    }

    def start_server {
        self.mcp.run("streamable-http");
    }
}

with entry {
    server = MCPServer();
    server.start_server();
}
