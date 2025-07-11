import from mtllm.llm {Model}
import from mtllm.types {Video}

glob llm = Model(model_name="gpt-4o");

def is_aligned(video: Video, text: str) -> bool by llm(method="Chain-of-Thoughts", context="Mugen is the moving character");

with entry {
    video = Video("/home/udith/jaseci_mtllm_pg/jac-rag-chatbot/mugen.mp4", 1);
    text = "Mugen jumps off and collects few coins.";
    print(is_aligned(video, text));
}