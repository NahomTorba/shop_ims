import 'package:flutter/material.dart';
import 'package:shop_ims/models/models.dart';
import 'package:shop_ims/pages/add_category_page.dart';
import 'package:shop_ims/services/dao.dart';
import 'package:shop_ims/pages/add_product_page.dart';

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  final ProductDao _productDao = ProductDao();
  final CategoryDao _categoryDao = CategoryDao();
  final InventoryMovementDao _movementDao = InventoryMovementDao();

  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<Category> _categories = [];
  Category? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final products = await _productDao.getProducts();
      final categories = await _categoryDao.getCategories();

      setState(() {
        _allProducts = products;
        _categories = categories;
        _isLoading = false;
      });
      _filterProducts();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  void _onSearchChanged() {
    _filterProducts();
  }

  void _onCategorySelected(Category? category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterProducts();
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        final matchesCategory =
            _selectedCategory == null ||
            product.categoryId == _selectedCategory!.id;
        final matchesQuery =
            product.name.toLowerCase().contains(query) ||
            (product.productCode?.toLowerCase().contains(query) ?? false);
        return matchesCategory && matchesQuery;
      }).toList();
    });
  }

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
          'Are you sure you want to delete ${product.name}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (product.id != null) {
        await _productDao.deleteProduct(product.id!);
        _loadData(); // Refresh list
      }
    }
  }

  void _editProduct(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddProductPage(product: product)),
    ).then((_) => _loadData()); // Refresh on return
  }

  void _showRestockDialog(Product product) {
    final quantityController = TextEditingController();
    final costController = TextEditingController(
      text: product.purchasePrice.toString(),
    );
    final saleController = TextEditingController(
      text: product.salePrice.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Restock ${product.name}',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Quantity to Add',
                  hintText: 'e.g., 50',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: costController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Unit Cost',
                  hintText: 'Cost per item',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: saleController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Sale Price',
                  hintText: 'Selling price per item',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final qty = int.tryParse(quantityController.text);
              final cost = double.tryParse(costController.text);
              final sale = double.tryParse(saleController.text);

              if (qty != null && qty > 0 && cost != null && sale != null) {
                Navigator.pop(context);
                _restockProduct(product, qty, cost, sale);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D7697),
              foregroundColor: Colors.white,
            ),
            child: const Text('Restock'),
          ),
        ],
      ),
    );
  }

  Future<void> _restockProduct(
    Product product,
    int quantity,
    double cost,
    double sale,
  ) async {
    setState(() => _isLoading = true);
    try {
      // 1. Update Product Prices if changed
      if (product.purchasePrice != cost || product.salePrice != sale) {
        final updatedProduct = Product(
          id: product.id,
          name: product.name,
          description: product.description,
          purchasePrice: cost,
          salePrice: sale,
          productCode: product.productCode,
          expirationDate: product.expirationDate,
          lowStockThreshold: product.lowStockThreshold,
          categoryId: product.categoryId,
          supplierId: product.supplierId,
          dateAdded: product.dateAdded,
          currentStock: product.currentStock,
        );
        await _productDao.updateProduct(updatedProduct);
      }

      // 2. Insert Inventory Movement
      final movement = InventoryMovement(
        productId: product.id!,
        userId: 1, // Default Admin
        movementType: 'IN',
        quantity: quantity,
        unitPrice: cost,
        movementDate: DateTime.now().toIso8601String(),
        reason: 'Restock via Stock Page',
      );

      await _movementDao.insertMovement(movement);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restocked ${product.name} successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error restocking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showProductDetails(Product product) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Code: ${product.productCode ?? 'N/A'}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              'Stock:',
              '${product.currentStock ?? 0}',
              valueColor: (product.currentStock ?? 0) <= 5
                  ? Colors.orange
                  : Colors.black87,
            ),
            _buildDetailRow(
              'Sale Price:',
              '\$${product.salePrice.toStringAsFixed(2)}',
            ),
            _buildDetailRow(
              'Cost Price:',
              '\$${product.purchasePrice.toStringAsFixed(2)}',
            ),
            _buildDetailRow('Category:', _getCategoryName(product.categoryId)),
            if (product.description != null &&
                product.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Description:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                product.description!,
                style: TextStyle(color: Colors.grey[800]),
              ),
            ],

            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteProduct(product);
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _editProduct(product);
                    },
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D7697),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryName(int? id) {
    if (id == null) return 'N/A';
    try {
      return _categories.firstWhere((c) => c.id == id).name;
    } catch (e) {
      return 'Unknown';
    }
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 16, color: valueColor ?? Colors.black87),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Stock Management',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.blue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.search, color: Colors.grey),
                        hintText: 'Search stock...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Categories
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Categories',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 50,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length + 1,
                    separatorBuilder: (c, i) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildCategoryChip(null, 'All');
                      }
                      final category = _categories[index - 1];
                      return _buildCategoryChip(category, category.name);
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Product List
                Expanded(
                  child: _filteredProducts.isEmpty
                      ? const Center(child: Text('No products found'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      '${product.salePrice.toStringAsFixed(2)} ETB',
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Stock: ${product.currentStock ?? 0}',
                                      style: TextStyle(
                                        color: (product.currentStock ?? 0) <= 5
                                            ? Colors.orange
                                            : Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.add_shopping_cart,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () =>
                                          _showRestockDialog(product),
                                      tooltip: 'Restock',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () => _editProduct(product),
                                    ),
                                  ],
                                ),
                                onTap: () => _showProductDetails(product),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) {
              return Wrap(
                children: [
                  ListTile(
                    leading: const Icon(Icons.add_box),
                    title: const Text('Add Product'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddProductPage(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.category),
                    title: const Text('Add Category'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddCategoryPage(),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
        backgroundColor: const Color(0xFF2D7697),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCategoryChip(Category? category, String label) {
    bool isSelected = _selectedCategory?.id == category?.id;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          _onCategorySelected(category);
        }
      },
      selectedColor: const Color(0xFF2D7697),
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.transparent),
      ),
    );
  }
}
