from flask import Flask, request, jsonify
from langchain_chroma import Chroma
from langchain_community.embeddings.sentence_transformer import SentenceTransformerEmbeddings
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_community.document_loaders import PyPDFLoader
import glob, os

directory = r"YOUR DATA SOURCES"
pdf_files = glob.glob(os.path.join(directory, "*.pdf"))

text_splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=200)
embedding_function = SentenceTransformerEmbeddings(model_name="all-MiniLM-L6-v2")

all_docs = []

# PLACE TO STORE THE VECTOR DATABASE BUILT
vectorstore = Chroma(
    persist_directory="db/",
    collection_name="medical_db",
    embedding_function=embedding_function
)

existing_docs = vectorstore.get()["metadatas"]
existing_pdf_names = set()
for doc in existing_docs:
    if "source" in doc.keys():
        existing_pdf_names.add(doc["source"])

for pdf in pdf_files:
    pdf_name = os.path.basename(pdf)
    
    # Check if the PDF has already been processed
    if pdf_name in existing_pdf_names:
        print(f"{pdf_name} has already been processed. Skipping.")
        continue
    else:
        print(f"Embedding new pdf {pdf_name}")

    loader = PyPDFLoader(pdf)
    docs = loader.load()
    print(f"Loaded {len(docs)} pages from {pdf}")
    # Split the documents
    splits = text_splitter.split_documents(docs)
    print(f"Split into {len(splits)} chunks")
    
    # Add metadata to each split document
    for split in splits:
        split.metadata["source"] = os.path.basename(pdf)
    
    all_docs.extend(splits)

if all_docs:
    vectorstore.add_documents(documents=all_docs)
    print(f"Adding new documents...")
else:
    print("No new documents to add.")

print("Update done...")

retriever = vectorstore.as_retriever(
    search_kwargs={'k': 5}
)

app = Flask(__name__)
app.config["DEBUG"] = True

@app.route("/query", methods=["POST"])
def query():
    data = request.get_json()
    query_text = data.get('query')
    print(query_text)

    # Retrieve documents based on query
    retrieved_docs = retriever.invoke(query_text)
    
    # Prepare response
    response = ""

    for idx, doc in enumerate(retrieved_docs):
        source = doc.metadata["source"]
        page = doc.metadata["page"]
        content = doc.page_content
        print(source, page)
        response += f"Source ({source} at page {page}): {content}\n\n"

    return jsonify(response)


if __name__ == "__main__":
    app.run(port=7000)
    