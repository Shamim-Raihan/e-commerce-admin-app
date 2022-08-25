import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom_admin_batch5/models/product_model.dart';
import 'package:ecom_admin_batch5/providers/product_provider.dart';
import 'package:ecom_admin_batch5/utils/constants.dart';
import 'package:ecom_admin_batch5/utils/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';

class ProductDetailsPage extends StatelessWidget {
  static const String routeName = '/product_details';

  const ProductDetailsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pid = ModalRoute.of(context)!.settings.arguments as String;
    final provider = Provider.of<ProductProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: provider.getProductById(pid),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final product = ProductModel.fromMap(snapshot.data!.data()!);
              provider.getPurchaseByProduct(pid);
              return ListView(
                children: [
                  FadeInImage.assetNetwork(
                    placeholder: 'images/placeholder.jpg',
                    image: product.imageUrl!,
                    fadeInCurve: Curves.bounceInOut,
                    fadeInDuration: const Duration(seconds: 3),
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          _showRePurchaseBottomSheet(context, (price, dty, dt){
                            EasyLoading.show(status: 'Please wait');
                            provider.rePurchase(pid, price, dty, dt, product.category!).then((value) {
                              EasyLoading.dismiss();
                              Navigator.pop(context);
                            }).catchError((error){
                              EasyLoading.dismiss();
                              showMsg(context, 'could not save');
                            });
                          });
                        },
                        child: const Text('Re-Purchase'),
                      ),
                      TextButton(
                        onPressed: () {
                          _showPurchaseHistoryBottomSheet(context);
                        },
                        child: const Text('Purchase History'),
                      ),
                    ],
                  ),
                  ListTile(
                    title: Text(product.name!),
                    trailing: IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.edit),
                    ),
                  ),
                  ListTile(
                    title: Text('$currencySymbol${product.salesPrice}'),
                    trailing: IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.edit),
                    ),
                  ),
                  ListTile(
                    title: const Text('Product Description'),
                    subtitle: Text(product.description ?? 'Not Available'),
                    trailing: IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.edit),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Available'),
                    value: product.available,
                    onChanged: (value) {
                      provider.updateProduct(
                          product.id!, productAvailable, value);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Featured'),
                    value: product.featured,
                    onChanged: (value) {
                      provider.updateProduct(
                          product.id!, productFeatured, value);
                    },
                  ),
                ],
              );
            }
            if (snapshot.hasError) {
              return const Center(
                child: Text('Failed'),
              );
            }
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        ),

    );
  }

  void _showPurchaseHistoryBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Consumer<ProductProvider>(
        builder: (context, provider, child) => ListView.builder(
          itemCount: provider.purchaseListOfSpecificProduct.length,
          itemBuilder: (context, index) {
            final purModel = provider.purchaseListOfSpecificProduct[index];
            return ListTile(
              //textColor: Colors.blue,
              title: Text(getFormattedDateTime(
                  purModel.dateModel.timestamp.toDate(), 'dd/MM/yyyy')),
              subtitle: Text('Quantity: ${purModel.quantity}'),
              trailing: Text('$currencySymbol${purModel.price}'),
            );
          },
        ),
      ),
    );
  }

  void _showRePurchaseBottomSheet(
    BuildContext context,
      Function(num price, num quantity, DateTime dt) onSave) {
    final qController = TextEditingController();
    final pController = TextEditingController();
    ValueNotifier<DateTime> _dateTimeNotifier = ValueNotifier(DateTime.now());
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (context) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(
                  height: 80,
                ),
                TextField(
                  controller: pController,
                  keyboardType: TextInputType.number,
                  decoration:
                      InputDecoration(filled: true, hintText: 'Purchase price'),
                ),
                SizedBox(
                  height: 10,
                ),
                TextField(
                  controller: qController,
                  keyboardType: TextInputType.number,
                  decoration:
                      InputDecoration(filled: true, hintText: 'Quantity'),
                ),
                Card(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () async {
                          _dateTimeNotifier.value = await _selectDate(context);
                        },
                        child: const Text('Select purchase Date'),
                      ),
                      Chip(
                        label: ValueListenableBuilder<DateTime>(
                          valueListenable: _dateTimeNotifier,
                          builder: (context, value, child) =>
                              Text(getFormattedDateTime(value, 'dd/MM/yyyy')),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    onSave(num.parse(pController.text), num.parse(qController.text), _dateTimeNotifier.value);
                    // Navigator.pop(context);
                  },
                  child: const Text('Repurchase'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Close'),
                ),
              ],
            ));
  }

  Future<DateTime> _selectDate(BuildContext context) async {
    final selectedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(1980),
        lastDate: DateTime.now());

    if (selectedDate != null) {
      return selectedDate;
    }
    return DateTime.now();
  }
}
