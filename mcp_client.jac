import anyio;
import mcp;
import from mcp.client {streamable_http};
import os;

"""Simple MCP client implemented in JAC."""

glob MCP_SERVER_URL: str = os.getenv('MCP_SERVER_URL', 'http://localhost:8899/mcp');

def call_mcp_tool(name: str, arguments: dict) -> str {
    async def _call() -> str {
        async with streamable_http.streamablehttp_client(MCP_SERVER_URL) as (read, write, _):
            async with mcp.ClientSession(read, write) as sess {
                await sess.initialize();
                result = await sess.call_tool(name=name, arguments=arguments);
                if result.isError {
                    return f"MCP error: {result.error.message}";
                }
                return str(result.result);
            }
    }
    return anyio.run(_call);
}
