import anyio
import mcp
from mcp.client import streamable_http
import os

MCP_SERVER_URL = os.getenv("MCP_SERVER_URL", "http://localhost:8899/mcp")

def call_mcp_tool(name: str, arguments: dict) -> str:
    async def _call() -> str:
        async with streamable_http.streamablehttp_client(MCP_SERVER_URL) as (read, write, _):
            async with mcp.ClientSession(read, write) as sess:
                await sess.initialize()
                result = await sess.call_tool(name=name, arguments=arguments)
                if result.isError:
                    return f"MCP error: {result.error.message}"
                return str(result.result)
    return anyio.run(_call)
