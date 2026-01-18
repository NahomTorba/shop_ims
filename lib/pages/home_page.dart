import 'package:flutter/material.dart';
import 'package:shop_ims/pages/add_category_page.dart';
import 'package:shop_ims/pages/add_product_page.dart';
import 'package:shop_ims/pages/sale_page.dart'; // Import SalePage
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
  final SaleDao _saleDao = SaleDao();

  // State variables for dashboard
  int _totalItems = 0;
  int _lowStockCount = 0;
  double _invValue = 0.0;
  int _salesTodayCount = 0;
  double _salesTodayValue = 0.0;
  double _profitToday = 0.0;
  List<Sale> _recentSales = [];
  Map<int, Product> _productCache = {}; // Cache for product details in recent activity

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      final products = await _productDao.getProducts();
      final sales = await _saleDao.getSales();
      
      // Calculate Total Items & Inventory Value
      int totalItems = 0;
      double invValue = 0;
      int lowStock = 0;
      
      for (var p in products) {
        totalItems += p.stockQuantity;
        invValue += p.purchasePrice * p.stockQuantity;
        if (p.stockQuantity <= p.lowStockThreshold) {
          lowStock++;
        }
        if (p.id != null) {
          _productCache[p.id!] = p;
        }
      }

      // Calculate Today's Stats
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      int salesCount = 0;
      double salesValue = 0;
      double profit = 0;
      List<Sale> todaysSalesList = [];

      // Filter for recent sales (simplified: just showing last few sales)
      // Ideally query with limit and order by in DAO
      List<Sale> recentSales = List.from(sales);
      recentSales.sort((a, b) => b.saleDate.compareTo(a.saleDate)); // Sort desc
      
      for (var s in sales) {
        // Assuming Sale_Date is stored as ISO string or similar that contains yyyy-MM-dd
        if (s.saleDate.startsWith(todayStr)) {
          salesCount += s.quantitySold;
          salesValue += s.totalPrice;
          
          final productKey = s.productId;
          if (_productCache.containsKey(productKey)) {
             final product = _productCache[productKey]!;
             // Profit = (Unit Price - Cost Price) * Qty
             // Note: This uses CURRENT cost price, which might differ from cost at time of purchase
             profit += (s.unitPrice - product.purchasePrice) * s.quantitySold;
          }
          todaysSalesList.add(s);
        }
      }

      if (mounted) {
        setState(() {
          _totalItems = totalItems;
          _lowStockCount = lowStock;
          _invValue = invValue;
          _salesTodayCount = salesCount;
          _salesTodayValue = salesValue;
          _profitToday = profit;
          _recentSales = recentSales.take(5).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  void _onItemTapped(int index) {
      if (index == 2) {
        // Navigate to Sale Page
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SalePage()),
        ).then((_) => _loadDashboardData()); // Refresh on return
      } else {
        setState(() {
          _selectedIndex = index;
        });
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _isLoading 
                      ? const Center(child: CircularProgressIndicator()) 
                      : _buildDashboardGrid(),
                  const SizedBox(height: 24),
                  _buildSearchBar(),
                  const SizedBox(height: 24),
                  _buildRecentActivityHeader(),
                  const SizedBox(height: 16),
                  _isLoading 
                      ? const SizedBox() 
                      : _buildRecentActivityList(),
                ],
              ),
            ),
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
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'HOME'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_turned_in_outlined), label: 'STOCK'),
          BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'SALE'), // Changed from ORDERS
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

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
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
    // Determine trends (placeholder logic for now, could be compared to yesterday)
    // For now, static positive trends
    
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
                trend: null, // Removed static trend
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
                 toolTip: "Today's Profit",
                value: '\$${_profitToday.toStringAsFixed(2)}',
                subtitle: "Today's Profit",
                trend: null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDashboardCard(
                icon: Icons.shopping_bag_outlined, // Changed icon
                iconColor: Colors.purple,
                 toolTip: "Sales Today",
                value: '\$${_salesTodayValue.toStringAsFixed(2)}',
                subtitle: "Sales Today",
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
          const SizedBox(height: 8),
          if (trend != null)
            Row(
              children: [
                Icon(
                  trendUp ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: trendUp ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  trend,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: trendUp ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          if (footer != null)
            Text(
              footer,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: footerColor,
              ),
            ),
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
      child: const TextField(
        decoration: InputDecoration(
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

  Widget _buildRecentActivityList() {
    if (_recentSales.isEmpty) {
       return const Center(
         child: Padding(
           padding: EdgeInsets.all(16.0),
           child: Text("No recent activity"),
         ),
       );
    }
    
    return Column(
      children: _recentSales.map((sale) {
        final product = _productCache[sale.productId];
        // Format time nicely
        // Assuming saleDate is ISO string for now
        String timeAgo = sale.saleDate; 
        try {
            final date = DateTime.parse(sale.saleDate);
            final diff = DateTime.now().difference(date);
            if (diff.inMinutes < 60) {
              timeAgo = '${diff.inMinutes} MINS AGO';
            } else if (diff.inHours < 24) {
              timeAgo = '${diff.inHours} HRS AGO';
            } else {
              timeAgo = 'YESTERDAY'; // Simplified
            }
        } catch(e) {
            // keep original string if parse fails
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _buildActivityItem(
            item: product?.name ?? 'Unknown Product',
            action: 'Sold ${sale.quantitySold} units',
            time: timeAgo,
            icon: Icons.shopping_bag,
            color: Colors.teal,
          ),
        );
      }).toList(),
    );
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
