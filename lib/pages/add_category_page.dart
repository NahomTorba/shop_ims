import 'package:flutter/material.dart';
import 'package:shop_ims/services/dao.dart';
import 'package:shop_ims/models/models.dart';

class AddCategoryPage extends StatefulWidget {
  const AddCategoryPage({super.key});

  @override
  State<AddCategoryPage> createState() => _AddCategoryPageState();
}

class _AddCategoryPageState extends State<AddCategoryPage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final CategoryDao _categoryDao = CategoryDao();
  bool _isLoading = false;
  
  // Icon Selection
  int _selectedIconIndex = 0;
  final List<Map<String, dynamic>> _categoryIcons = [
    {'icon': Icons.cake, 'label': 'Sweet'},
    {'icon': Icons.local_drink, 'label': 'Bottle'},
    {'icon': Icons.shopping_bag, 'label': 'Bag'},
    {'icon': Icons.diamond, 'label': 'Jewellery'},
    {'icon': Icons.edit, 'label': 'Writing'},
    {'icon': Icons.menu_book, 'label': 'Paper'},
    {'icon': Icons.checkroom, 'label': 'Clothes'},
    {'icon': Icons.devices, 'label': 'Tech'},
  ];

  Future<void> _saveCategory() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a category name')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    final category = Category(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    await _categoryDao.insertCategory(category);

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Add Category', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.blue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CATEGORY NAME',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'e.g., Luxury Pens, Fine Art',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'DESCRIPTION',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                     controller: _descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Describe the items in this category for better inventory tracking...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Category Icon',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildIconGrid(),
            const SizedBox(height: 32),
            const Text(
              '* Categories help organize your inventory and generate more accurate sales reports.',
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 12),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveCategory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FA8C8), // Light blue similar to design
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
             const SizedBox(height: 16),
             Center(child: TextButton(onPressed: ()=> Navigator.pop(context), 
             child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold),))),
          ],
        ),
      ),
    );
  }

  Widget _buildIconGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: _categoryIcons.length,
      itemBuilder: (context, index) {
        final iconData = _categoryIcons[index];
        final isSelected = _selectedIconIndex == index;
        return _buildIconItem(iconData['icon'], iconData['label'], isSelected, index);
      },
    );
  }
  
  Widget _buildIconItem(IconData icon, String label, bool selected, int index) {
      return InkWell(
        onTap: () {
          setState(() {
            _selectedIconIndex = index;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE0F2F1) : Colors.white,
            border: Border.all(color: selected ? Colors.teal : Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? Colors.teal : Colors.black87),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(
                color: selected ? Colors.teal : Colors.black87,
                fontWeight: FontWeight.bold
                )
              ),
            ],
          ),
        ),
      );
  }
}
