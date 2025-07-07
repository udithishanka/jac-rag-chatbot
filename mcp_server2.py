from __future__ import annotations
from jaclang.runtimelib.builtin import *
from jaclang import JacMachineInterface as _
import sys;
import os

from rag import RagEngine, WebSearch
from mcp.server.fastmcp.tools import Tool
from mcp.server.fastmcp import FastMCP

rag_engine: RagEngine = RagEngine()
web_search: WebSearch = WebSearch()

async def tool_search_docs(query: str) -> str:
    return rag_engine.search(query)

async def tool_search_web(query: str) -> str:
    web_search_results = web_search.search(query)
    if not web_search_results:
        return 'Mention No results found for the web search'
    return web_search_results


mcp = FastMCP(name='RAG-MCP', tools=[Tool.from_function(tool_search_docs, description='Search PDF docs', name='search_docs'), Tool.from_function(tool_search_web, description='Search the web', name='search_web')], port=8899)
mcp.run('streamable-http')