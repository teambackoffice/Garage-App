import 'package:flutter/material.dart';
import 'package:garage_app/part_parchase.dart';
import 'package:garage_app/vendor.dart';
import 'add_expenses.dart';
import 'income.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    Widget buildCard(String title, IconData icon, Color color, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          height: h * 0.10,
          width: double.infinity,
          margin: EdgeInsets.only(bottom: h * 0.02),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(w * 0.03),
          ),
          child: Row(
            children: [
              SizedBox(width: w * 0.04),
              Icon(icon, size: w * 0.08, color: color),
              SizedBox(width: w * 0.04),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: w * 0.045,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: w * 0.045, color: color),
              SizedBox(width: w * 0.04),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        elevation: 1,
        backgroundColor: Colors.white,
        title: const Text(
          'Account',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(w * 0.04),
        child: Column(
          children: [
            SizedBox(height: h * 0.015),
            buildCard('Expense', Icons.money_off, Colors.black, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddExpensePage()));
            }),
            buildCard('Part Purchase', Icons.shopping_cart, Colors.black, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PartPurchasePage()));
            }),
            buildCard('Income', Icons.attach_money, Colors.black, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const Account()));
            }),
            buildCard('Vendor Dues', Icons.receipt_long, Colors.black, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AllDuePage()));
            }),
          ],
        ),
      ),
    );
  }
}
