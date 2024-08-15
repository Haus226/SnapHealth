import os
from flask import Flask, request, make_response, send_file, jsonify
import numpy as np
from PIL import Image
import werkzeug
import torch
from torchcam.methods import GradCAM
from torchvision import transforms
import torch.nn as nn
import torch.nn.functional as F
import os
from firebase_admin import credentials, initialize_app, storage
cred = credentials.Certificate("YOUR CREDENTIAL JSON FILE")
initialize_app(cred, {'storageBucket': 'YOUR STORAGE BUCKET FOR TRANSFER BETWEEN FLUTTER AND PYTHON'})
bucket = storage.bucket()


class Ensemble(nn.Module):
    def __init__(self, num_classes, models, acc, mean, std):
        super(Ensemble, self).__init__()
        self.effi_v2s = models[0]
        self.densenet = models[1]
        self.regnet = models[2]
        self.convnext = models[3]
        self.fc = nn.Linear(in_features=len(models) * 4, out_features=num_classes)
        self.acc = acc
        self.mean = mean
        self.std = std

    def forward(self, x):
        o1 = self.effi_v2s(x)
        o2 = self.densenet(x)
        o3 = self.regnet(x)
        o4 = self.convnext(x)

        concatenated_outputs = torch.cat((o1, o2, o3, o4), dim=1)
        x = torch.flatten(concatenated_outputs, start_dim=1)
        x = self.fc(x)
        return x


app = Flask(__name__)
app.config["DEBUG"] = True



@app.route("/predict/<int:disease_id>", methods=["POST"])
def predict(disease_id):
    print("Received")
    file = request.files["image"]
    user = request.form.get("user")
    print("User:", user)
    print(request)
    filename = werkzeug.utils.secure_filename(file.filename)


    classes = []
    model_folder = ""
 
    if disease_id == 0:
        classes = ["Mild Demented", "Non Demented", "Moderate Demented", "Very Mild Demented"]
        model_folder = "Alzheimer"
    elif disease_id in [1, 2, 3]:
        classes = ["Glioma", "Meningioma", "Normal", "Pituitary"]
        model_folder = "Brain"
    elif disease_id in [4, 6, 7]:
        classes = ["Lung Adenocarcinoma", "Lung Benign Tissue", "Lung Squamous Cell Carcinoma"]
        model_folder = "Lung_cancer"
    elif disease_id in [5, 8, 9]:
        classes = ["Covid-19", "Normal", "Pneumonia", "Tuberculosis"]
        model_folder = "Pneumonia_covid_tuberculosis"
    elif disease_id in [10, 12, 14]:
        classes = ["Cataract", "Diabetic Retinopathy", "Glaucoma", "Normal"]
        model_folder = "Eye"
    elif disease_id in [11, 13, 15]:
        classes = ["Choroidal Neovascularization", "Diabetic Macular Edema", "Drusen", "Normal"]
        model_folder = "Retina"
    elif disease_id == 16:
        classes = ["Normal", "Oral Squamous Cell Carcinoma"]
        model_folder = "Oral_cancer"
    elif disease_id in [17, 18, 19]:
        classes = ["Chronic Lymphocytic Leukemia", "Follicular Lymphoma", "Mantle Cell Lymphoma"]
        model_folder = "Lymphoma_cancer"
    elif disease_id in [20, 21]:
        classes = ["Colon Adenocarcinoma", "Colon Benign Tissue"]
        model_folder = "Colon_cancer"
    elif disease_id == [22, 23, 24]:
        classes = ["Cyst", "Normal", "Kidney Stone", "Kidney Tumor"]
        model_folder = "Kidney"
    elif disease_id == 25:
        classes = ["Dyskeratotic(Abnormal)", "Koilocytotic(Abnormal)", "Metaplastic(Benign)", "Parabasal(Normal)", "Superficial-Intermediate(Normal)"]
        model_folder = "Cervix_cancer"
    elif disease_id in [26, 27]:
        classes = ["Breast Benign", "Breast Malignant"]
        model_folder = "Breast_cancer"
    elif disease_id == 28:
        classes = ["Benign", "Early-B ALL", "Pre-B ALL", "Pro-B ALL"]
        model_folder = "All"

    
    image = Image.open(file)
    models = os.listdir(r"E:\SnapHealth\diseases_predict\model")
    for m in models:
        if model_folder in m:
            print(m)
            model = torch.load(r"E:/SnapHealth/diseases_predict/model/" +  m, map_location=torch.device('cpu'))
            model.eval()
            break
    transform = transforms.Compose([
        transforms.ToTensor(),
        transforms.Resize((256, 256), antialias=True),
        transforms.Lambda(lambda t: t / 255.0),
        transforms.Normalize(model.mean, model.std)
    ])

    effi_v2s = model.effi_v2s.features[-1]
    densenet = model.densenet.features[-1]
    regnet = model.regnet.trunk_output[-1]
    convnext = model.convnext.features[-1]
    target_layers = [effi_v2s, densenet, regnet, convnext]

    sample = transform(image)

    heatmap, probabilities = gradCAM(model, target_layers, image, sample)
    response = {}
    print(probabilities)
    for idx, c in enumerate(classes):
        response[c] = str(round(probabilities[0][idx] * 100, 4))

    heatmap.save(f"predicted_{filename}")
    blob = bucket.blob(f"{user}_disease/predicted_{filename}")
    blob.upload_from_filename(f"predicted_{filename}")
    os.remove(os.getcwd() + f"/predicted_{filename}")
    print(blob.media_link)
    blob.make_public()
    response["url"] = blob.public_url

    import json
    print(json.dumps(response))
    return json.dumps(response)




@app.route("/test", methods=["GET"])
def test():
    response = make_response("", 200)
    return response

def gradCAM(model, target_layers, image, sample):

    heatmaps = []
    for m in target_layers:
        for param in m.parameters():
            param.requires_grad = True
    for layer in target_layers:
        with GradCAM(model, target_layer=layer) as cam:
            out = model(sample.unsqueeze(0))
            probabilities = F.softmax(out, dim=1).cpu().detach().numpy()
            act = cam(out.squeeze(0).argmax().item(), out)
            act = act[0].numpy()
            heatmaps.append(act)
    heatmaps_array = np.array(heatmaps)
    concatenated_heatmap = np.concatenate(heatmaps_array, axis=0)
    combined_heatmap = np.max(concatenated_heatmap, axis=0)

    import matplotlib.pyplot as plt
    from torchcam.utils import overlay_mask
    from torchvision.transforms.functional import to_pil_image
    result = overlay_mask(image, to_pil_image(combined_heatmap, mode="F"), alpha=0.8, colormap="jet")
    return result, probabilities

if __name__ == "__main__":
    app.run(port=9000)
    
