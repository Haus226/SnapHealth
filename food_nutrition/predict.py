import numpy as np
import os
from flask import Flask, request, make_response
import numpy as np
from PIL import Image
import time
import threading, werkzeug
import json
from sklearn.preprocessing import StandardScaler
import tensorflow as tf
from tensorflow import keras

app = Flask(__name__)
app.config["DEBUG"] = True

mean = np.array([2.56363430e+02, 7.33971313e+00, 2.61689099e+01, 9.00596559e+00,
                   5.73073905e+00, 1.49130057e+01, 2.49028021e-02, 3.62616988e+00,
                   3.56952805e-02])

std = np.array([7.11202240e+01, 3.18900623e+00, 1.02698777e+01, 1.03793033e+01,
                   3.77882835e+00, 7.53279707e+00, 2.63631380e-02, 2.63860028e+00,
                   1.98664601e-02])

scaler = StandardScaler()
scaler.mean_ = mean
scaler.scale_ = std
scaler.var_ = std ** 2

model = tf.keras.models.load_model(r"food_nutrition_predict\foodNutrition.h5")
nutrition = ["energy", "protein", "carbohydrates", "sugars", "fiber", "fat", "cholesterol", "minerals", "vitamins"]

@app.route("/predict", methods=["POST"])
def predict():
    print("Received")
    file = request.files["image"]
    print(request)
    filename = werkzeug.utils.secure_filename(file.filename)
    
    image = Image.open(file)
    image = image.convert("RGB")
    image = image.resize((224, 224))
    image = np.array(image)
    image = image.reshape((1, 224, 224, 3))
    results = model.predict(image)
    results = scaler.inverse_transform(np.array(results).flatten().reshape(1, -1))
    print(results)
    final_results = {
        nutrition[idx]:str(round(results[0][idx], 2)) for idx in range(len(nutrition))
    }
    print(final_results)
    return json.dumps(final_results)

@app.route("/test", methods=["GET"])
def test():
    response = make_response("", 200)
    return response

if __name__ == "__main__":
    app.run(port=8000)
