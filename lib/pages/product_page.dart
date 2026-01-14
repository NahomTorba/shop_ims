import 'package:flutter/material.dart';
import 'package:shop_ims/models/models.dart';
import 'package:shop_ims/services/dao.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key, required User user});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final ProductDao _productDao = ProductDao();

  final _nameController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _stockController = TextEditingController();

  Future<void> _addProduct() async {
    final product = Product(
      name: _nameController.text,
      purchasePrice: double.parse(_purchasePriceController.text),
      salePrice: double.parse(_salePriceController.text),
      stockQuantity: int.parse(_stockController.text),
    );

    await _productDao.insertProduct(product);

    _clearFields();
    setState(() {});
  }

  void _clearFields() {
    _nameController.clear();
    _purchasePriceController.clear();
    _salePriceController.clear();
    _stockController.clear();
  }

  Future<void> _deleteProduct(int id) async {
    await _productDao.deleteProduct(id);
    setState(() {});
  }

  void _showEditDialog(Product product) {
    _nameController.text = product.name;
    _purchasePriceController.text = product.purchasePrice.toString();
    _salePriceController.text = product.salePrice.toString();
    _stockController.text = product.stockQuantity.toString();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: _purchasePriceController, decoration: const InputDecoration(labelText: 'Purchase Price')),
            TextField(controller: _salePriceController, decoration: const InputDecoration(labelText: 'Sale Price')),
            TextField(controller: _stockController, decoration: const InputDecoration(labelText: 'Stock')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final updated = Product(
                id: product.id,
                name: _nameController.text,
                purchasePrice: double.parse(_purchasePriceController.text),
                salePrice: double.parse(_salePriceController.text),
                stockQuantity: int.parse(_stockController.text),
              );

              await _productDao.updateProduct(updated);
              _clearFields();
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product Management')),
      body: Column(
        children: [
          // ADD PRODUCT FORM
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Product Name')),
                TextField(
                  controller: _purchasePriceController,
                  decoration: const InputDecoration(labelText: 'Purchase Price'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _salePriceController,
                  decoration: const InputDecoration(labelText: 'Sale Price'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _stockController,
                  decoration: const InputDecoration(labelText: 'Stock Quantity'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _addProduct,
                  child: const Text('Add Product'),
                ),
              ],
            ),
          ),

          const Divider(),

          // PRODUCT LIST
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: _productDao.getProducts(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final products = snapshot.data!;
                if (products.isEmpty) {
                  return const Center(child: Text('No products found'));
                }

                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Card(
                      child: ListTile(
                        title: Text(product.name),
                        subtitle: Text(
                          'Buy: ${product.purchasePrice} | Sell: ${product.salePrice} | Stock: ${product.stockQuantity}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showEditDialog(product),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteProduct(product.id!),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
