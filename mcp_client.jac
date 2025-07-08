import anyio;
import mcp;
import os;
import from mcp.client { streamable_http }


with entry {
    MCP_SERVER_URL = os.getenv('MCP_SERVER_URL', 'http://localhost:8899/mcp');
}


def call_mcp_tool(name: str, arguments:dict) -> str {
    async def _call()  -> str {
        async with streamable_http.streamablehttp_client(MCP_SERVER_URL) as (read, write, _)  {
            async with mcp.ClientSession(read, write) as sess  {
                await sess.initialize();
                result = await sess.call_tool(name=name, arguments=arguments);
                if result.isError {
                    return f"'MCP error: '{result.error.message}";
                }
            if (result.structuredContent and ('result' in result.structuredContent) ) {
                return result.structuredContent[ 'result' ];
            } if (result.content and (len(result.content) > 0) ) {
                return result.content[ 0 ].text;
            } }
        }
    }
    return anyio.run(_call);
}