import 'package:flutter/material.dart';

void showMessage(BuildContext context, String message) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(message),
          );
        });
  }

Widget buildIndicator(int cur, int index) {
  return Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: cur == index ? Colors.pink[50] : Colors.grey,
    ),
  );
}

class Disease {
  // Or use the keyword late
  String name;
  int id;
  String category;
  Disease({this.name = "", this.id = -1, this.category = ""});
}

List<Disease> brain = [
  Disease(name: "Alzheimer", id: 0, category: "Brain"),
  Disease(name: "Glioma", id: 1, category: "Brain"),
  Disease(name: "Meningioma", id: 2, category: "Brain"),
  Disease(name: "Pituitary", id: 3, category: "Brain")
];

List<Disease> lung = [
  Disease(name: "Lung Adenocarcinoma", id: 4, category: "Lung"),
  Disease(name: "Covid-19", id: 5, category: "Lung"),
  Disease(name: "Lung Benign Tissue", id: 6, category: "Lung"),
  Disease(name: "Lung Squamous Cell Carcinoma", id: 7, category: "Lung"),
  Disease(name: "Pneumonia", id: 8, category: "Lung"),
  Disease(name: "Tuberculosis", id: 9, category: "Lung"),
];

List<Disease> eye = [
  Disease(name: "Cataract", id: 10, category: "Eye"),
  Disease(name: "Choroidal Neovascularization", id: 11, category: "Eye"),
  Disease(name: "Glaucoma", id: 12, category: "Eye"),
  Disease(name: "Diabetic Macular Edema ", id: 13, category: "Eye"),
  Disease(name: "Diabetic Retinopathy", id: 14, category: "Eye"),
  Disease(name: "Drusen", id: 15, category: "Eye"),
];

List<Disease> oral = [
  Disease(name: "Oral Squamous Cell Carcinoma", id: 16, category: "Oral")
];

List<Disease> lymphoma = [
  Disease(name: "Chronic Lymphocytic Leukemia", id: 17, category: "Lymphoma"),
  Disease(name: "Follicular Lymphoma", id: 18, category: "Lymphoma"),
  Disease(name: "Mantle Cell Lymphoma", id: 19, category: "Lymphoma"),
];

List<Disease> colon = [
    Disease(name: "Colon Adenocarcinoma", id: 20, category: "Lymphoma"),
    Disease(name: "Colon Benign Tissue", id: 21, category: "Lymphoma"),
];

List<Disease> kidney = [
  Disease(name: "Kidney Cyst", id: 22, category: "Kidney"),
  Disease(name: "Kidney Stone", id: 23, category: "Kidney"),
  Disease(name: "Kidney Tumor", id: 24, category: "Kidney"),
];

List<Disease> cervix = [
  Disease(name: "Cervix Cancer", id: 25, category: "Cervix")
];

List<Disease> breast = [
  Disease(name: "Breast Benign", id: 26, category: "Breast"),
  Disease(name: "Breast Malignant", id: 27, category: "Breast"),
];

List<Disease> leukemia = [
  Disease(name: "Acute Lymphocytic Leukemia (ALL)", id: 28, category: "Leukemia")
];


List<String> diseaseNames = [
  "Alzheimer",
  "Glioma",
  "Meningioma",
  "Pituitary",
  "Lung Adenocarcinoma",
  "Covid-19",
  "Lung Benign Tissue",
  "Lung Squamous Cell Carcinoma",
  "Pneumonia",
  "Tuberculosis",
  "Cataract",
  "Choroidal Neovascularization",
  "Glaucoma",
  "Diabetic Macular Edema",
  "Diabetic Retinopathy",
  "Drusen",
  "Oral Squamous Cell Carcinoma",
  "Chronic Lymphocytic Leukemia",
  "Follicular Lymphoma",
  "Mantle Cell Lymphoma",
  "Colon Adenocarcinoma",
  "Colon Benign Tissue",
  "Kidney Cyst",
  "Kidney Stone",
  "Kidney Tumor",
  "Cervix Cancer",
  "Breast Benign",
  "Breast Malignant",
  "Acute Lymphocytic Leukemia"
];
