# jac-rag-chatbot

This project demonstrates a simple Retrieval-Augmented Generation (RAG) chatbot built with Jaseci. It exposes a Streamlit based front‑end and an API powered back‑end.

The server now integrates optional web search via the [Serper](https://serper.dev) API. Set the `SERPER_API_KEY` environment variable before starting the server to enable this feature.

### MCP integration

This repo also exposes a simple [Model Context Protocol](https://github.com/anthropic-ai/mcp) server. Start it with `python mcp_server.py` to provide additional tools over MCP. When enabled, the backend will connect to the MCP server specified by the `MCP_SERVER_URL` environment variable (defaults to `http://localhost:8899/mcp`) and let the language model call the registered tools during a chat session.

## Uploading PDFs

1. Start the Jaseci server with `server.jac`.
2. Launch the Streamlit app using `app.jac`.
3. Use the *Upload PDF* widget to select one or more PDF files. The files are sent to the back‑end and stored under the `docs/` directory. The RAG engine indexes them immediately so future questions can reference their content.

