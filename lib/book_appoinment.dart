import 'package:flutter/material.dart';
import 'package:garage_app/request_page.dart';
import 'appoinmnent_page.dart';
import 'confirm_page.dart';
import 'cancel_page.dart'; // 👈 Import your Cancel page

class BookAppointment extends StatefulWidget {
  const BookAppointment({super.key});

  @override
  State<BookAppointment> createState() => _BookAppointmentState();
}

class _BookAppointmentState extends State<BookAppointment> {
  late double h;
  late double w;

  @override
  Widget build(BuildContext context) {
    h = MediaQuery.of(context).size.height;
    w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "Appointment",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),

        centerTitle: true,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.deepPurple),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(w * 0.05),
          child: Column(
            children: [
              buildOptionCard(
                label: 'Book',
                icon: Icons.calendar_month_outlined,
                color1: Colors.teal, // First color for gradient
                color2: Colors.green, // Second color for gradient
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AppointmentPage()));
                },
              ),
              const SizedBox(height: 20),
              buildOptionCard(
                label: 'Cancel',
                icon: Icons.cancel_outlined,
                color1: Colors.orange, // First color for gradient
                color2: Colors.red, // Second color for gradient
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const Cancel()));
                },
              ),
              const SizedBox(height: 20),
              buildOptionCard(
                label: 'Confirmed',
                icon: Icons.check_circle_outline,
                color1: Colors.pink, // First color for gradient
                color2: Colors.purple, // Second color for gradient
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ConfirmPage()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildOptionCard({
    required String label,
    required IconData icon,
    required Color color1,
    required Color color2,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: h * 0.08,
        width: w * 0.9,
        decoration: BoxDecoration(
          // Applying gradient color to the container background
          gradient: LinearGradient(
            colors: [color1.withOpacity(0.8), color2.withOpacity(0.8)], // Gradient for background
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon stays with the original color
            Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white, // White text for contrast
              ),
            ),
          ],
        ),
      ),
    );
  }
}
