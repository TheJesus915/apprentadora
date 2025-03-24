import 'package:flutter/material.dart';
import 'mis_productos_page.dart';
import 'rentas_page.dart';

class DashboardPage extends StatelessWidget {
  final Color titleColor;

  DashboardPage({this.titleColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Dashboard",
            style: TextStyle(color: titleColor),
          ),
          backgroundColor: Color(0xFF00345E),
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () {
                // Add your logout logic here
                Navigator.of(context).pushReplacementNamed('/login');
              },
            ),
          ],
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white, // Color for selected tab icon and text
            unselectedLabelColor: Colors.grey, // Color for unselected tab icon and text
            tabs: [
              Tab(icon: Icon(Icons.shopping_cart), text: "Mis Productos"),
              Tab(icon: Icon(Icons.assignment), text: "Mis Rentas"),
            ],
          ),
          iconTheme: IconThemeData(color: Colors.white), // Color for action icons
        ),
        body: TabBarView(
          children: [
            MisProductosPage(),
            RentasPage(),
          ],
        ),
      ),
    );
  }
}