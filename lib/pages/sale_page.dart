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
  final SaleDao _saleDao = SaleDao();

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
      _selectedProduct = null;
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
      
      if (_selectedProduct != null && !_filteredProducts.contains(_selectedProduct)) {
        _selectedProduct = null;
      }
    });
  }

  Future<void> _recordSale() async {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product')),
      );
      return;
    }
    
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
    
    if (quantity > _selectedProduct!.stockQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Not enough stock! Available: ${_selectedProduct!.stockQuantity}')),
      );
      return;
    }

    setState(() => _isProcessingSale = true);

    try {
      // 1. Create Sale Record
      final sale = Sale(
        productId: _selectedProduct!.id!,
        quantitySold: quantity,
        unitPrice: _selectedProduct!.salePrice,
        totalPrice: _selectedProduct!.salePrice * quantity,
        saleDate: DateTime.now().toIso8601String(),
      );
      
      await _saleDao.insertSale(sale);
      
      // 2. Update Product Stock
      final updatedProduct = Product(
        id: _selectedProduct!.id,
        name: _selectedProduct!.name,
        description: _selectedProduct!.description,
        purchasePrice: _selectedProduct!.purchasePrice,
        salePrice: _selectedProduct!.salePrice,
        stockQuantity: _selectedProduct!.stockQuantity - quantity,
        productCode: _selectedProduct!.productCode,
        expirationDate: _selectedProduct!.expirationDate,
        lowStockThreshold: _selectedProduct!.lowStockThreshold,
        categoryId: _selectedProduct!.categoryId,
        supplierId: _selectedProduct!.supplierId,
      );
      
      await _productDao.updateProduct(updatedProduct);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sale recorded successfully!'), backgroundColor: Colors.green),
        );
        _quantityController.clear();
        setState(() {
          _selectedProduct = null;
        });
        _loadData(); // Refresh data
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
      backgroundColor: Colors.grey[50], // Light background
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Search Bar
                   Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
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
                  const SizedBox(height: 16),
                  
                  // Categories
                  const Text('Categories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 50,
                    child: ListView.separated(
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
                  
                  const SizedBox(height: 24),
                  
                  // Product Dropdown
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Select Product', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<Product>(
                          value: _selectedProduct,
                          isExpanded: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          hint: const Text('Choose a product'),
                          items: _filteredProducts.map((product) {
                            return DropdownMenuItem(
                              value: product,
                              child: Text('${product.name} (Stock: ${product.stockQuantity})'),
                            );
                          }).toList(),
                          onChanged: (Product? value) {
                            setState(() {
                              _selectedProduct = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                   const SizedBox(height: 16),
                   
                   if (_selectedProduct != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Row(
                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                               children: [
                                 Text(_selectedProduct!.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                 Text('\$${_selectedProduct!.salePrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                               ],
                             ),
                             const SizedBox(height: 8),
                             Text('Available Stock: ${_selectedProduct!.stockQuantity}', style: TextStyle(color: _selectedProduct!.stockQuantity > 5 ? Colors.grey : Colors.red)),
                             const Divider(height: 24),
                             const Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                             const SizedBox(height: 8),
                             TextField(
                               controller: _quantityController,
                               keyboardType: TextInputType.number,
                               decoration: InputDecoration(
                                 hintText: 'Enter quantity',
                                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                               ),
                             ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedProduct = null;
                                  _quantityController.clear();
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isProcessingSale ? null : _recordSale,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2D7697),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isProcessingSale 
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Confirm Sale'),
                            ),
                          ),
                        ],
                      ),
                   ],
                ],
              ),
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
    );
  }
}
