# SnapHealth

- An Android mobile application that offers medical image analysis for health screening.
- Integrate Firebase for secure user data storage
- Utilize Python as a backend language to enable model predictions on a cloud server if deployed.
- Present users with detailed information on medical conditions, including descriptions, symptoms, and available treatments.
- Offer a user-friendly interface for easy navigation and accessibility.

## Usage of Python
- [`predict.py`](train_and_predict/predict.py) is the Flask app used to interact with flutter app to receive medical image and return the prediction
- [`train.ipynb`](train_and_predict/train.ipynb) is the python files that contains the code written for training where the dataset is organized such that each class folder in the dataset contains test, train and val folders

## Diseases supported
The diseases in the same line use the same models to predict they are just different classes
- Brain
  - Alzheimer
  - Glioma, Meningioma, Pituitary
- Lung
  - Lung Adenocarcinoma, Lung Benign Tissue, Lung Squamous Cell Carcinoma
  - Covid-19, Pneumonia, Tuberculosis
- Eye
  - Cataract, Glaucoma, Diabetic Retinopathy
  - Choroidal Neovascularization, Diabetic Macular Edema, Drusen
- Oral
  - Oral Squamous Cell Carcinoma
- Lymphoma
  - Chronic Lymphocytic Leukemia, Follicular Lymphoma, Mantle Cell Lymphoma
- Colon
  - Colon Adenocarcinoma, Colon Benign Tissue
- Kidney
  - Kidney Cyst, Kidney Stone, Kidney Tumor
- Cervix
  - Cervix Cancer (5 different classes for tissue)
- Breast
  - Breast Benign, Breast Malignant
- Leukemia
  - Acute Lymphocytic Leukemia (4 different claases for tissue)
## CNN Models provided
- VGG-19
- InceptionV3
- Xception
- DenseNet201
- Ensemble model of the models above
