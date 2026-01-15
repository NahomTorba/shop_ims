import 'package:flutter/material.dart';
import 'package:shop_ims/pages/add_category_page.dart';
import 'package:shop_ims/pages/add_product_page.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildDashboardGrid(),
                const SizedBox(height: 24),
                _buildSearchBar(),
                const SizedBox(height: 24),
                _buildRecentActivityHeader(),
                const SizedBox(height: 16),
                _buildRecentActivityList(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          // TODO: Implement navigation logic
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'HOME'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_turned_in_outlined), label: 'STOCK'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'ORDERS'),
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
                color: Colors.black.withOpacity(0.05),
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
                value: '1,240',
                subtitle: 'Total Items',
                trend: '+2.5%',
                trendUp: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDashboardCard(
                icon: Icons.warning_amber_rounded,
                iconColor: Colors.orange,
                 toolTip: "Low Stock",
                value: '12',
                subtitle: 'Low Stock',
                footer: 'Needs attention',
                footerColor: Colors.orange,
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
                 toolTip: "Inv. Value",
                value: '\$14.2k',
                subtitle: 'Inv. Value',
                trend: '-1.2%',
                trendUp: false,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDashboardCard(
                icon: Icons.shopping_cart_outlined,
                iconColor: Colors.purple,
                 toolTip: "Orders Today",
                value: '24',
                subtitle: 'Orders Today',
                trend: '+10%',
                trendUp: true,
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
            color: Colors.black.withOpacity(0.05),
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
              color: iconColor.withOpacity(0.1),
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
            color: Colors.black.withOpacity(0.05),
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
    return Column(
      children: [
        _buildActivityItem(
          item: 'Muji-style Gel Pen (B...',
          action: 'Sold 5 units',
          time: '2 MINS AGO',
          icon: Icons.edit,
          color: Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildActivityItem(
          item: 'Linen Hardcover Journal',
          action: 'Restocked 50 units',
          time: '1 HR AGO',
          icon: Icons.book,
          color: Colors.amber,
        ),
        const SizedBox(height: 12),
        _buildActivityItem(
          item: 'Brass Paperclips',
          action: 'Stock correction (-2)',
          time: '3 HRS AGO',
          actionColor: Colors.red,
          icon: Icons.attach_file,
          color: Colors.orange,
        ),
         const SizedBox(height: 12),
        _buildActivityItem(
          item: 'Handmade Cotton Pa...',
          action: 'Sold 12 packs',
          time: 'YESTERDAY',
          icon: Icons.note,
          color: Colors.brown,
        ),
      ],
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
            color: Colors.black.withOpacity(0.05),
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
              color: color.withOpacity(0.2),
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
                );
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
                );
              },
            ),
          ],
        );
      },
    );
  }
}
