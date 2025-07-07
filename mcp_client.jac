import anyio;
import mcp;
import os;
import logging;
import from mcp.client { streamable_http }


with entry {
    logger = logging.getLogger(__name__);
    logger.setLevel(logging.INFO);
    handler = logging.StreamHandler();
    handler.setFormatter(logging.Formatter('%(asctime)s | %(levelname)s | %(message)s'));
    logger.addHandler(handler);
    MCP_SERVER_URL = os.getenv('MCP_SERVER_URL', 'http://localhost:8899/mcp');
}


def call_mcp_tool(name: str, arguments:dict) -> str {
    async def _call()  -> str {
        logger.info(f"'Connecting to MCP server: '{MCP_SERVER_URL}");
        async with streamable_http.streamablehttp_client(MCP_SERVER_URL) as (read, write, _)  {
            async with mcp.ClientSession(read, write) as sess  {
                await sess.initialize();
                result = await sess.call_tool(name=name, arguments=arguments);
                logger.info(f"'Tool call completed with result: '{result}");
                if result.isError {
                    logger.error(f"'MCP tool error: '{result.error.message}");
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