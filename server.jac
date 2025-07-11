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
import from mtllm.types {Image, Video, Text}
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

Correct:
{
  "name": "search_docs",
  "arguments": {"query": "example"}
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

    "Generate a helpful response to the user's message. Use available mcp tool when needed. Consider any uploaded media context."
    def respond(message:str, chat_history:list[dict]) -> str
        by llm(
            method="ReAct",
            tools=([use_mcp_tool]),
            messages=chat_history,
            max_react_iterations=6
        );
    
    def chat_with_image(img: Image, text: Text) -> str by llm();

    def chat_with_video(video: Video, text: Text) -> str by llm(method="Chain-of-Thoughts");
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


walker analyze_image {
    has file_name: str;
    has file_data: str;
    has session_id: str;
    has message: str = None;

    can init_session with `root entry {
         visit [-->](`?Session)(?id == self.session_id) else {
            session_node = here ++> Session(id=self.session_id, chat_history=[], status=1);
            print("Session Node Created for image analysis");
            visit session_node;
        }
    }

    can chat with Session entry {
        if not os.path.exists('uploads') {
            os.makedirs('uploads');
        }
        file_path = os.path.join('uploads', self.file_name);
        data = base64.b64decode(self.file_data.encode('utf-8'));
        with open(file_path, 'wb') as f {
            f.write(data);
        }
        img = Image(file_path);
        text = self.message if self.message else "Describe the image content.";
        desc = here.chat_with_image(img, text);
        
        # Add to chat history as a system message about the uploaded image
        context_msg = f"User uploaded an image '{self.file_name}'. Analysis: {desc}";
        here.chat_history.append({"role": "system", "content": context_msg});
        
        if self.message {
            here.chat_history.append({"role": "user", "content": self.message});
            response = here.chat_with_image(
                img=img,
                text=self.message,
                chat_history=here.chat_history
            );
            here.chat_history.append({"role": "assistant", "content": response});
            report {"description": desc, "response": response};
        } else {
            report {"description": desc};
        }
    }
}

walker analyze_video {
    has file_name: str;
    has file_data: str;
    has session_id: str;
    has message: str = None;

    can init_session with `root entry {
         visit [-->](`?Session)(?id == self.session_id) else {
            session_node = here ++> Session(id=self.session_id, chat_history=[], status=1);
            print("Session Node Created for video analysis");
            visit session_node;
        }
    }

    can summarize with Session entry {
        if not os.path.exists('uploads') {
            os.makedirs('uploads');
        }
        file_path = os.path.join('uploads', self.file_name);
        data = base64.b64decode(self.file_data.encode('utf-8'));
        with open(file_path, 'wb') as f {
            f.write(data);
        }
        video = Video(file_path, 1);
        text = self.message if self.message else "Summarize the video content.";
        summary = here.chat_with_video(video, text);
        
        # Add to chat history as a system message about the uploaded video
        context_msg = f"User uploaded a video '{self.file_name}'. Summary: {summary}";
        here.chat_history.append({"role": "system", "content": context_msg});
        
        if self.message {
            here.chat_history.append({"role": "user", "content": self.message});
            response = here.chat_with_video(
                video=video,
                text=self.message,
                chat_history=here.chat_history
            );
            here.chat_history.append({"role": "assistant", "content": response});
            report {"summary": summary, "response": response};
        } else {
            report {"summary": summary};
        }
    }
}