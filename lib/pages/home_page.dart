import 'package:flutter/material.dart';
import 'package:shop_ims/pages/add_category_page.dart';
import 'package:shop_ims/pages/add_product_page.dart';
import 'package:shop_ims/pages/more_reports.dart';
import 'package:shop_ims/pages/sale_page.dart';
import 'package:shop_ims/pages/stock_page.dart';
import 'package:shop_ims/services/dao.dart';
import 'package:shop_ims/models/models.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  
  // DAOs
  final ProductDao _productDao = ProductDao();
  final InventoryMovementDao _movementDao = InventoryMovementDao();

  // State variables for dashboard
  int _totalItems = 0;
  int _lowStockCount = 0;
  double _invValue = 0.0;
  double _salesToday = 0.0;
  double _profitToday = 0.0;
  
  // Recent Activity
  List<InventoryMovement> _recentActivity = [];
  final Map<int, Product> _productCache = {}; 
  
  // Search
  final TextEditingController _searchController = TextEditingController();
  List<Product> _allProducts = []; 
  List<InventoryMovement> _searchResults = [];
  bool _isSearching = false;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _searchController.addListener(_onSearchChanged);
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _isSearching = query.isNotEmpty;
      if (_isSearching) {
        _searchResults = _recentActivity.where((item) {
           final product = _productCache[item.productId];
           return product?.name.toLowerCase().contains(query) ?? false;
        }).toList();
      }
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      final products = await _productDao.getProducts();
      final movements = await _movementDao.getMovements();
      
      _allProducts = products;
      
      // Calculate Total Items & Inventory Value
      int totalItems = 0;
      double invValue = 0;
      int lowStock = 0;
      
      _productCache.clear();
      for (var p in products) {
        int stock = p.currentStock ?? 0;
        totalItems += stock;
        invValue += p.purchasePrice * stock;
        if (stock <= p.lowStockThreshold) {
          lowStock++;
        }
        if (p.id != null) {
          _productCache[p.id!] = p;
        }
      }

      // Calculate Today's Stats
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      double salesToday = 0;
      double profitToday = 0;
      
      for (var m in movements) {
        if (m.movementDate.startsWith(todayStr)) {
          if (m.movementType == 'OUT') {
            salesToday += (m.quantity * (m.unitPrice ?? 0));
            
            // Calculate Profit
            final product = _productCache[m.productId];
            if (product != null) {
              double costPrice = product.purchasePrice;
              double salePrice = m.unitPrice ?? 0;
              profitToday += (salePrice - costPrice) * m.quantity;
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _totalItems = totalItems;
          _lowStockCount = lowStock;
          _invValue = invValue;
          _salesToday = salesToday;
          _profitToday = profitToday;
          _recentActivity = movements.take(10).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  void _onItemTapped(int index) {
      if (index == 1) {
         // Stock Page
         Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const StockPage()),
        ).then((_) => _loadDashboardData());
      } else if (index == 2) {
        // Sale Page
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SalePage()),
        ).then((_) => _loadDashboardData()); 
      } else if(index == 3){
        // more reports page
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ReportsPage()),
        ).then((_) => _loadDashboardData());
      } else {
        setState(() {
          _selectedIndex = index;
        });
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], 
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: Column(
            children: [
               Padding(
                 padding: const EdgeInsets.all(16.0),
                 child: _buildHeader(),
               ),
               Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
                 child: _buildSearchBar(),
               ),
               const SizedBox(height: 16),
               Expanded(
                 child: _isSearching 
                    ? _buildSearchResults()
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _isLoading 
                                ? const Center(child: CircularProgressIndicator()) 
                                : _buildDashboardGrid(),
                            const SizedBox(height: 24),
                            _buildRecentActivityHeader(),
                            const SizedBox(height: 16),
                            _isLoading 
                                ? const SizedBox() 
                                : _buildRecentActivityList(_recentActivity),
                          ],
                        ),
                      ),
               ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'HOME'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_turned_in_outlined), label: 'STOCK'),
          BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'SALE'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'MORE'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddOptions(context);
        },
        backgroundColor: const Color(0xFF2D7697),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(child: Text('No activity found'));
    }
    return _buildRecentActivityList(_searchResults);
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 20,
              child: Icon(
                Icons.account_circle_outlined,
                size: 40,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
                const Text(
                  'Shop Manager',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.notifications_none, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildDashboardGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDashboardCard(
                icon: Icons.inventory_2_outlined,
                iconColor: Colors.blue,
                toolTip: "Total Items",
                value: _totalItems.toString(),
                subtitle: 'Total Items',
                trend: null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDashboardCard(
                icon: Icons.warning_amber_rounded,
                iconColor: Colors.orange,
                toolTip: "Low Stock",
                value: _lowStockCount.toString(),
                subtitle: 'Low Stock',
                footer: _lowStockCount > 0 ? 'Needs attention' : 'Good standing',
                footerColor: _lowStockCount > 0 ? Colors.orange : Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDashboardCard(
                icon: Icons.attach_money,
                iconColor: Colors.green,
                toolTip: "Sales Today",
                value: '\$${_salesToday.toStringAsFixed(2)}',
                subtitle: "Today's Sale",
                trend: null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDashboardCard(
                icon: Icons.show_chart,
                iconColor: Colors.purple,
                toolTip: "Profit Today",
                value: '\$${_profitToday.toStringAsFixed(2)}',
                subtitle: "Profit",
                trend: null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDashboardCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String subtitle,
    required String toolTip,
    String? trend,
    bool trendUp = true,
    String? footer,
    Color? footerColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          if (footer != null) ...[
             const SizedBox(height: 8),
             Text(
              footer,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: footerColor,
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
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
          hintText: 'Search activity or items...',
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildRecentActivityHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        TextButton(
          onPressed: () {},
          child: const Text('View all'),
        ),
      ],
    );
  }

  Widget _buildRecentActivityList(List<InventoryMovement> movements) {
    if (movements.isEmpty) {
       return const Center(
         child: Padding(
           padding: EdgeInsets.all(16.0),
           child: Text("No recent activity"),
         ),
       );
    }
    
    return Column(
      children: movements.map((item) {
        return _buildMovementItem(item);
      }).toList(),
    );
  }
  
  Widget _buildMovementItem(InventoryMovement movement) {
    final product = _productCache[movement.productId];
    String timeAgo = _getTimeAgo(movement.movementDate);
    
    String action = '';
    IconData icon = Icons.history;
    Color color = Colors.grey;
    
    if (movement.movementType == 'IN') {
      action = 'Stock In: +${movement.quantity}';
      icon = Icons.arrow_downward;
      color = Colors.green;
    } else if (movement.movementType == 'OUT') {
      action = 'Stock Out: -${movement.quantity}';
      icon = Icons.arrow_upward;
      color = Colors.red;
    } else {
      action = 'Adjustment: ${movement.quantity}';
      icon = Icons.tune;
      color = Colors.orange;
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: _buildActivityItem(
        item: product?.name ?? 'Unknown Product',
        action: action,
        time: timeAgo,
        icon: icon,
        color: color,
      ),
    );
  }
  
  String _getTimeAgo(String dateStr) {
     try {
        final date = DateTime.parse(dateStr);
        final diff = DateTime.now().difference(date);
        if (diff.inMinutes < 60) {
          return '${diff.inMinutes} MINS AGO';
        } else if (diff.inHours < 24) {
          return '${diff.inHours} HRS AGO';
        } else if (diff.inDays == 1) {
          return 'YESTERDAY';
        } else {
          return '${diff.inDays} DAYS AGO';
        }
    } catch(e) {
        return '';
    }
  }

  Widget _buildActivityItem({
    required String item,
    required String action,
    required String time,
    required IconData icon,
    required Color color,
    Color? actionColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  action,
                  style: TextStyle(
                    fontSize: 14,
                    color: actionColor ?? Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Add Category'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddCategoryPage()),
                ).then((_) => _loadDashboardData());
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_box),
              title: const Text('Add Product'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddProductPage()),
                ).then((_) => _loadDashboardData());
              },
            ),
          ],
        );
      },
    );
  }
}
