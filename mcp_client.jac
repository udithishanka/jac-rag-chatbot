import mcp_client;
import os;

glob MCP_SERVER_URL: str = os.getenv("MCP_SERVER_URL", "http://localhost:8899/mcp");

def call_mcp_tool(name: str, arguments: dict) -> str {
    return mcp_client.call_mcp_tool(name, arguments);
}

obj MCPClient {
    has server_url: str = MCP_SERVER_URL;
    
    def call_tool(name: str, arguments: dict) -> str {
        return call_mcp_tool(name, arguments);
    }
    
    def search_docs(query: str) -> str {
        return self.call_tool("search_docs", {"query": query});
    }
    
    def search_web(query: str) -> str {
        return self.call_tool("search_web", {"query": query});
    }
}

with entry {
    client = MCPClient();
    print("MCP Client initialized with server URL:", client.server_url);
}
