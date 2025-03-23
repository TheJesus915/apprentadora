import 'package:flutter/material.dart';
import 'mis_productos_page.dart';
import 'rentas_page.dart';

class DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Dashboard"),
          backgroundColor: Colors.amber,
          bottom: TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.shopping_cart), text: "Mis Productos"),
              Tab(icon: Icon(Icons.assignment), text: "Mis Rentas"),
            ],
          ),
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
