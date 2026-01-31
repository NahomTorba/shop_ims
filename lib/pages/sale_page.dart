import 'package:flutter/material.dart';
import 'package:shop_ims/models/models.dart';
import 'package:shop_ims/services/dao.dart';

class SalePage extends StatefulWidget {
  const SalePage({super.key});

  @override
  State<SalePage> createState() => _SalePageState();
}

class _SalePageState extends State<SalePage> {
  final ProductDao _productDao = ProductDao();
  final CategoryDao _categoryDao = CategoryDao();
  final InventoryMovementDao _movementDao = InventoryMovementDao();

  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<Category> _categories = [];
  
  Product? _selectedProduct;
  Category? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  
  bool _isLoading = true;
  bool _isProcessingSale = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final products = await _productDao.getProducts();
      final categories = await _categoryDao.getCategories();
      
      setState(() {
        _allProducts = products;
        _filteredProducts = products;
        _categories = categories;
        _isLoading = false;
      });
      _filterProducts();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error loading data: $e')),
        );
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
        final matchesQuery = product.name.toLowerCase().contains(query) || (product.productCode?.toLowerCase().contains(query) ?? false);
        final matchesCategory = _selectedCategory == null || product.categoryId == _selectedCategory!.id;
        return matchesQuery && matchesCategory;
      }).toList();
    });
  }
  
  void _selectProduct(Product product) {
    setState(() {
      _selectedProduct = product;
    });
    _showQuantityDialog(product);
  }

  void _showQuantityDialog(Product product) {
    _quantityController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sell ${product.name}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Available Stock: ${product.currentStock ?? 0}', 
                 style: TextStyle(color: (product.currentStock ?? 0) < 5 ? Colors.red : Colors.grey[600])),
            const SizedBox(height: 16),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Quantity to Sell',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
             const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessingSale ? null : () {
                    Navigator.pop(context);
                    _recordSale();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D7697), // Teal
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isProcessingSale 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Text('Confirm Sale'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _recordSale() async {
    if (_selectedProduct == null) return;
    
    final quantityText = _quantityController.text;
    if (quantityText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter quantity')),
      );
      return;
    }
    
    final int? quantity = int.tryParse(quantityText);
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity')),
      );
      return;
    }
    
    final currentStock = _selectedProduct!.currentStock ?? 0;
    if (quantity > currentStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Not enough stock! Available: $currentStock')),
      );
      return;
    }

    setState(() => _isProcessingSale = true);

    try {
      // Create Inventory Movement Record (Type: OUT)
      final movement = InventoryMovement(
        productId: _selectedProduct!.id!,
        userId: 1, // Assuming default Admin user ID 1 for now, or fetch from session
        movementType: 'OUT',
        quantity: quantity,
        unitPrice: _selectedProduct!.salePrice,
        movementDate: DateTime.now().toIso8601String(),
        reason: 'Sale',
      );
      
      await _movementDao.insertMovement(movement);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sale recorded successfully!'), backgroundColor: Colors.green),
        );
        _quantityController.clear();
        setState(() {
          _selectedProduct = null;
        });
        _loadData(); // Refresh data to show updated stock
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error recording sale: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingSale = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('New Sale', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
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
                          hintText: 'Search product...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Categories
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
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Products', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(height: 8),
                  
                  // Product List
                  Expanded(
                    child: _filteredProducts.isEmpty
                        ? const Center(child: Text('No products found'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredProducts.length,
                            itemBuilder: (context, index) {
                               final product = _filteredProducts[index];
                               final stock = product.currentStock ?? 0;
                               return Card(
                                 margin: const EdgeInsets.only(bottom: 12),
                                 elevation: 2,
                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                 child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text('Price: ${product.salePrice} ETB'),
                                        const SizedBox(height: 4),
                                        Text('Stock: $stock', 
                                            style: TextStyle(color: stock <= 5 ? Colors.red : Colors.green)),
                                      ],
                                    ),
                                    trailing: ElevatedButton(
                                      onPressed: () => _selectProduct(product),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF2D7697).withValues(alpha: 0.1),
                                        foregroundColor: const Color(0xFF2D7697),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: const Text('Sell'),
                                    ),
                                 ),
                               );
                            },
                        ),
                  ),
              ],
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
        side: const BorderSide(color: Colors.transparent)
      ),
    );
  }
}
