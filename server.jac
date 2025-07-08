import logging;
import sys;

with entry{
    logging.basicConfig(
    level=logging.INFO,                 # show INFO and above
    stream=sys.stdout,                  # send to console
    format="%(asctime)s | %(levelname)s | %(message)s",
    );
}
import from mtllm.llm {Model}
import from rag {RagEngine, WebSearch}
import os;
import base64;
import requests;
import anyio;
import mcp;
import mcp_client;

glob rag_engine:RagEngine = RagEngine();
glob llm = Model(model_name='gpt-4o', verbose=True);

glob web_search: WebSearch = WebSearch();
glob MCP_SERVER_URL: str = os.getenv('MCP_SERVER_URL', 'http://localhost:8899/mcp');

def search_web(query: str) -> str {
    return web_search.search(query=query);
}

def search_docs(query: str) -> str {
    return rag_engine.search(query=query);
}


"""Available Tool names are 'search_docs', 'search_web'. arguments is what you need to look for."""
def search_web(name: str, arguments: dict) -> str {
    logging.info(f"Calling MCP tool: {name} with arguments: {arguments}");
    response = mcp_client.call_mcp_tool(name=name, arguments=arguments);
    logging.info(f"MCP tool response: {response}");
    return response;
}


node Session {
    has id: str;
    has chat_history: list[dict];
    has status: int = 1;

    "Respond to a user message using the chat history and using mcp tool with correct names."
    def respond(message:str, chat_history:list[dict], allow_mcp: bool=True) -> str
        by llm(
            method="ReAct",
            tools=([search_web] if allow_mcp else []), # [search_docs, search_web] + 
            max_react_iterations=6
        );
}


walker interact {
    has message: str;
    has session_id: str;
    has allow_mcp: bool = True;

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
            allow_mcp=self.allow_mcp
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




