import os
from flask import Flask, request, make_response
from keras.models import load_model
import numpy as np
from PIL import Image
import time
import threading, werkzeug
import json



app = Flask(__name__)
app.config["DEBUG"] = True

def load_and_append(model_folder, model_name, models, acc, pred, img, idx):
    model_path = f"model/{model_folder}/{model_name}"
    models.append(m := load_model(model_path))
    acc[idx] = float(model_name.split("_")[1].replace(".h5", ""))
    pred[idx] = m.predict(img) * acc[idx]
    print(f"{model_name} Done !!!")

def ensembleThreading(model_folder, model_used:list, img, classes):
    start = time.time()
    model_names = sorted(os.listdir(f"model/{model_folder}"))
    model_names = [model_names[idx] for idx in range(len(model_names)) if model_used[idx]]
    acc = [0] * model_used.count(1)
    pred = [0] * model_used.count(1)
    models = []

    threads = []
    # Start a thread for each model
    for idx, m in enumerate(model_names):
        thread = threading.Thread(target=load_and_append, args=(model_folder, m, models, acc, pred, img, idx))
        thread.start()
        threads.append(thread)

    # Wait for all threads to finish
    for thread in threads:
        thread.join()

    print(acc)
    print(pred)

    y_pred = pred[0]
    if len(pred) > 1:
        for i in range(1, len(pred)):
            y_pred = y_pred + pred[i]
        print("Before normalization : ", y_pred)
        y_pred = (y_pred - np.min(y_pred)) / (np.max(y_pred) - np.min(y_pred))
        print("After normalization : ", y_pred)
    end = time.time()
    print("Time used : ", end - start)

    # results = {"time":str(round(end - start, 4)) + " seconds"}
    results = {}

    for idx, c in enumerate(classes):
        results[c] = str(round(y_pred[0][idx], 4))
    print(results)
    return json.dumps(results)
 

def ensemble(model_folder, img, classes):
    start = time.time()
    models_name = os.listdir(f"model/{model_folder}")
    acc = []
    models = []
    for m in models_name:
        models.append(load_model(f"model/{model_folder}/{m}"))
        acc.append(float(m.split("_")[1].replace(".h5", "")))

    pred = []

    for idx, m in enumerate(models):
        pred.append(m.predict(img) * acc[idx])
    
    y_pred = pred[0]
    for i in range(1, len(pred)):
        y_pred = y_pred + pred[i]
    
    print("Before normalization : ", y_pred)
    y_pred = (y_pred - np.min(y_pred)) / (np.max(y_pred) - np.min(y_pred))
    print("After normalization : ", y_pred)
    end = time.time()
    print("Time used : ", end - start)

    results = {"time":str(round(end - start, 4)) + " seconds"}

    for idx, c in enumerate(classes):
        results[c] = str(round(y_pred[0][idx], 4))
    print(results)
    return results




@app.route("/<string:model_used>/<int:disease_id>", methods=["POST"])
def predict(model_used, disease_id):
    print("Received")
    file = request.files["image"]
    print(request)
    filename = werkzeug.utils.secure_filename(file.filename)
    print(filename)
    classes = []
    model_folder = ""
    model_names = ["DenseNet201, InceptionV3, Xception, VGG-19"]
    models = [0, 0, 0, 0]
    for idx, m in enumerate(model_used):
        if m == "1":
            models[idx] = 1

    if disease_id == 0:
        classes = ["Mild Demented", "Non Demented", "Moderate Demented", "Very Mild Demented"]
        model_folder = "alzheimer"
    elif disease_id in [1, 2, 3]:
        classes = ["Glioma", "Meningioma", "Pituitary Tumor"]
        model_folder = "brain_cancer"
    elif disease_id in [4, 6, 7]:
        classes = ["Lung Adenocarcinoma", "Lung Benign Tissue", "Lung Squamous Cell Carcinoma"]
        model_folder = "lung_cancer"
    elif disease_id in [5, 8, 9]:
        classes = ["Covid-19", "Normal", "Pneumonia", "Tuberculosis"]
        model_folder = "pneumonia_covid_tuberculosis"
    elif disease_id in [10, 12, 14]:
        classes = ["Cataract", "Diabetic Retinopathy", "Glaucoma", "Normal"]
        model_folder = "eye"
    elif disease_id in [11, 13, 15]:
        classes = ["Choroidal Neovascularization", "Diabetic Macular Edema", "Drusen", "Normal"]
        model_folder = "retina"
    elif disease_id == 16:
        classes = ["Normal", "Oral Squamous Cell Carcinoma"]
        model_folder = "oral_cancer"
    elif disease_id in [17, 18, 19]:
        classes = ["Chronic Lymphocytic Leukemia", "Follicular Lymphoma", "Mantle Cell Lymphoma"]
        model_folder = "lymphoma_cancer"
    elif disease_id in [20, 21]:
        classes = ["Colon Adenocarcinoma", "Colon Benign Tissue"]
        model_folder = "colon_cancer"
    elif disease_id == [22, 23, 24]:
        classes = ["Cyst", "Normal", "Kidney Stone", "Kidney Tumor"]
        model_folder = "kidney"
    elif disease_id == 25:
        classes = ["Dyskeratotic(Abnormal)", "Koilocytotic(Abnormal)", "Metaplastic(Benign)", "Parabasal(Normal)", "Superficial-Intermediate(Normal)"]
        model_folder = "cervix_cancer"
    elif disease_id in [26, 27]:
        classes = ["Breast Benign", "Breast Malignant"]
        model_folder = "breast_cancer"
    elif disease_id == 28:
        classes = ["Benign", "Early-B ALL", "Pre-B ALL", "Pro-B ALL"]
        model_folder = "all"

    
    image = Image.open(file)
    image = image.convert("RGB")
    image = image.resize((224, 224))
    image = np.array(image)
    print(image.shape)
    image = image.reshape((1, 224, 224, 3))
    print(image.shape)

    return ensembleThreading(model_folder, models, image, classes)


@app.route("/<int:model_used>", methods=["GET"])
def test(model_used):
    response = make_response("", 200)
    return response


if __name__ == "__main__":
    app.run(port=9000)
    
