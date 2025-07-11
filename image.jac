import from mtllm.llm {Model}
import from mtllm.types {Image, Text}

glob llm = Model(model_name="gpt-4o-mini");

'Personality of the Person'
enum Personality {
   INTROVERT = "Introvert",
   EXTROVERT = "Extrovert"
}

obj Person {
    has full_name: str,
        year_of_death: str,
        personality: Personality;
}

def get_person_info(image_content: Image) -> Person by llm();

with entry {
    image = Image("/home/udith/jaseci_mtllm_pg/jac-rag-chatbot/photo.jpg");
    person_obj = get_person_info(image);
    print(person_obj);
}