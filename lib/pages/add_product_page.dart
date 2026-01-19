import 'package:flutter/material.dart';
import 'package:shop_ims/services/dao.dart';
import 'package:shop_ims/models/models.dart';
import 'package:intl/intl.dart';

class AddProductPage extends StatefulWidget {
  final Product? product; // If provided, we are in EDIT mode
  const AddProductPage({super.key, this.product});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _stockQuantityController = TextEditingController();
  final _productCodeController = TextEditingController();
  DateTime? _expirationDate;
  Category? _selectedCategory;
  
  final ProductDao _productDao = ProductDao();
  final CategoryDao _categoryDao = CategoryDao();
  
  List<Category> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.product != null) {
      _initEditMode();
    }
  }

  void _initEditMode() {
    final p = widget.product!;
    _nameController.text = p.name;
    _descriptionController.text = p.description ?? '';
    _costPriceController.text = p.purchasePrice.toString();
    _salePriceController.text = p.salePrice.toString();
    _stockQuantityController.text = p.stockQuantity.toString();
    _productCodeController.text = p.productCode ?? '';
    
    if (p.expirationDate != null) {
      try {
        _expirationDate = DateFormat('MM/dd/yyyy').parse(p.expirationDate!);
      } catch (e) {
        // Handle parsing error if format changed
      }
    }
    // Category pre-selection happens in _loadCategories
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final categories = await _categoryDao.getCategories();
      setState(() {
        _categories = categories;
        if (widget.product != null && widget.product!.categoryId != null) {
           try {
             _selectedCategory = categories.firstWhere((c) => c.id == widget.product!.categoryId);
           } catch (e) {
             // Category might have been deleted
           }
        }
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _expirationDate) {
      setState(() {
        _expirationDate = picked;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (_nameController.text.isEmpty ||
        _costPriceController.text.isEmpty ||
        _salePriceController.text.isEmpty ||
        _stockQuantityController.text.isEmpty ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields (including Category)')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isEdit = widget.product != null;
      
      final product = Product(
        id: isEdit ? widget.product!.id : null, 
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        purchasePrice: double.parse(_costPriceController.text.trim()),
        salePrice: double.parse(_salePriceController.text.trim()),
        stockQuantity: int.parse(_stockQuantityController.text.trim()),
        productCode: _productCodeController.text.trim().isNotEmpty ? _productCodeController.text.trim() : null,
        expirationDate: _expirationDate != null
            ? DateFormat('MM/dd/yyyy').format(_expirationDate!)
            : null,
        categoryId: _selectedCategory?.id,
        // Preserve Date_Added if editing, set new if adding
        dateAdded: isEdit 
            ? widget.product!.dateAdded 
            : DateTime.now().toIso8601String(),
      );

      if (isEdit) {
        await _productDao.updateProduct(product);
      } else {
        await _productDao.insertProduct(product);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving product: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Product' : 'Add New Product',
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.blue),
          onPressed: () => Navigator.pop(context),
        ),
        leadingWidth: 80,
      ),
      body: _isLoading && _categories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('BASIC DETAILS'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         _buildLabel('Product Name'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameController,
                          decoration: _inputDecoration('e.g. Fountain Pen Blue'),
                        ),
                        const SizedBox(height: 16),
                        _buildLabel('Category*'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<Category>(
                          value: _selectedCategory,
                          items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                          onChanged: (val) => setState(() => _selectedCategory = val),
                          decoration: _inputDecoration('Select Category'),
                          validator: (val) => val == null ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildLabel('Description'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: _inputDecoration('Enter product details, material...'),
                        ),
                         const SizedBox(height: 16),
                        _buildLabel('Product Code (Optional)'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _productCodeController,
                          decoration: _inputDecoration('e.g. SKU-12345'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('PRICING & STOCK'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: _cardDecoration(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Cost Price'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _costPriceController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: _inputDecoration('\$ 0.00'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: _cardDecoration(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Sale Price'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _salePriceController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: _inputDecoration('\$ 0.00'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                   Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Stock Quantity'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _stockQuantityController,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration('0').copyWith(
                                   suffixIcon: IconButton(
                                     icon: const Icon(Icons.archive_outlined, color: Colors.grey),
                                     onPressed: () {}, // Could hook up to a scanner later
                                   ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  _buildSectionHeader('ADDITIONAL INFO'),
                  const SizedBox(height: 8),
                   Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Expiration Date'),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _expirationDate == null
                                      ? 'mm/dd/yyyy'
                                      : DateFormat('MM/dd/yyyy').format(_expirationDate!),
                                  style: TextStyle(
                                    color: _expirationDate == null ? Colors.grey[500] : Colors.black87,
                                    fontSize: 16,
                                  ),
                                ),
                                 const Icon(Icons.calendar_today_outlined, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4FA8C8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(isEdit ? Icons.save : Icons.add_circle, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(isEdit ? 'Save Changes' : 'Add Product to Inventory', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey[600],
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600, // Semi-bold
        color: Colors.black87,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
