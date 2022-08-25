import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom_admin_batch5/db/db_helper.dart';
import 'package:ecom_admin_batch5/models/category_model.dart';
import 'package:ecom_admin_batch5/models/purchase_model.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/date_model.dart';
import '../models/product_model.dart';

class ProductProvider extends ChangeNotifier {
  List<ProductModel> productList = [];
  List<PurchaseModel> purchaseListOfSpecificProduct = [];
  List<CategoryModel> categoryList = [];

  Future<void> addCategory(CategoryModel categoryModel) =>
      DbHelper.addNewCategory(categoryModel);

  Future<void> addNewProduct(ProductModel productModel,
      PurchaseModel purchaseModel, CategoryModel categoryModel) {
    final count = categoryModel.productCount + purchaseModel.quantity;
    return DbHelper.addProduct(
        productModel, purchaseModel, categoryModel.id!, count);
  }

  Future<void> rePurchase(String pid, num price, num qty, DateTime dateTime, String category) {
    final catModel = getCategoryModelByCatName(category);
    catModel.productCount += qty;
    final purchaseModel = PurchaseModel(
        dateModel: DateModel(
            timestamp: Timestamp.fromDate(dateTime),
            day: dateTime.day,
            month: dateTime.month,
            year: dateTime.year),
        price: price,
        quantity: qty,
        productId: pid);
    return DbHelper.rePurchase(purchaseModel, catModel);
  }

  getAllCategories() {
    DbHelper.getAllCategories().listen((event) {
      categoryList = List.generate(event.docs.length,
          (index) => CategoryModel.fromMap(event.docs[index].data()));
      notifyListeners();
    });
  }

  getAllProducts() {
    DbHelper.getAllProducts().listen((event) {
      productList = List.generate(event.docs.length,
          (index) => ProductModel.fromMap(event.docs[index].data()));
      notifyListeners();
    });
  }

  getPurchaseByProduct(String id) {
    DbHelper.getPurchaseByProductId(id).listen((event) {
      purchaseListOfSpecificProduct = List.generate(event.docs.length,
          (index) => PurchaseModel.fromMap(event.docs[index].data()));
      print(purchaseListOfSpecificProduct.length);
      notifyListeners();
    });
  }

  CategoryModel getCategoryModelByCatName(String name) {
    return categoryList.firstWhere((element) => element.name == name);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getProductById(String id) =>
      DbHelper.getProductById(id);

  Future<void> updateProduct(String id, String field, dynamic value) {
    return DbHelper.updateProduct(id, {field: value});
  }

  Future<String> updateImage(XFile xFile) async {
    final imageName = DateTime.now().millisecondsSinceEpoch.toString();
    final photoRef =
        FirebaseStorage.instance.ref().child('Pictures/$imageName');
    final uploadTask = photoRef.putFile(File(xFile.path));
    final snapshot = await uploadTask.whenComplete(() => null);
    return snapshot.ref.getDownloadURL();
  }
}
