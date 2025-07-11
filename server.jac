import sys;
import logging;

# Configure logging
with entry {
    logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(message)s",
    stream=sys.stdout,
    force=True
);
}


import from mtllm.llm {Model}
import from tools {RagEngine}
import os;
import base64;
import requests;
import anyio;
import mcp_client;

glob rag_engine:RagEngine = RagEngine();
glob llm = Model(model_name='gpt-4o-mini', verbose=True);
glob MCP_SERVER_URL: str = os.getenv('MCP_SERVER_URL', 'http://localhost:8899/mcp');


"""Available tools: 'search_docs' or 'search_web' with {"query": "your query"}.

Only use a dictionary with plain key-value string pairs for `arguments`.

Correct:
{
  "name": "search_web",
  "arguments": {"query": "weather in Moratuwa, Sri Lanka"}
}

Do NOT use:
{
  "name": "search_web",
  "arguments": [{"key": "query", "value": "weather..."}]
}

arguments should be a dictionary with the required parameters for the tool. arguments={"query": "example"}
"""
def use_mcp_tool(name: str, arguments: dict[str, str]) -> str {
    logging.info(f"Calling tool '{name}' with arguments: {arguments}");
    result = mcp_client.call_mcp_tool(name=name, arguments=arguments);
    logging.info(f"Tool '{name}' returned result: {result}");
    return result;
}

node Session {
    has id: str;
    has chat_history: list[dict];
    has status: int = 1;

    "Generate a helpful response to the user's message. Use available mcp tool when needed."
    def respond(message:str, chat_history:list[dict]) -> str
        by llm(
            method="ReAct",
            tools=([use_mcp_tool]),
            messages=chat_history,
            max_react_iterations=6
        );
}


walker interact {
    has message: str;
    has session_id: str;

    can init_session with `root entry {
         visit [-->](`?Session)(?id == self.session_id) else {
            session_node = here ++> Session(id=self.session_id, chat_history=[], status=1);
            print("Session Node Created");
            visit session_node;
        }
    }

    can chat with Session entry {
        here.chat_history.append({"role": "user", "content": self.message});
        response = here.respond(
            message=self.message,
            chat_history=here.chat_history,
        );

        here.chat_history.append({"role": "assistant", "content": response});

        report {"response": response};
    }
}

walker upload_pdf {
    has file_name: str;
    has file_data: str;

    can save_doc with `root entry {
        if not os.path.exists(rag_engine.file_path) {
            os.makedirs(rag_engine.file_path);
        }
        file_path = os.path.join(rag_engine.file_path, self.file_name);
        data = base64.b64decode(self.file_data.encode('utf-8'));
        with open(file_path, 'wb') as f {
            f.write(data);
        }
        rag_engine.add_file(file_path);
        report {"status": "uploaded"};
    }
}




