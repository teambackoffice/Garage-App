import 'package:flutter/material.dart';

import '../main.dart';

class ServiceAndParts extends StatefulWidget {
  const ServiceAndParts({super.key});

  @override
  State<ServiceAndParts> createState() => _ServiceAndPartsState();
}

class _ServiceAndPartsState extends State<ServiceAndParts> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        leading: Icon(Icons.arrow_back_ios_new_outlined,color: Colors.black),
        backgroundColor: Colors.white,
        title: Text(
          "Parts",style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600
        ),
        ),
      ),
      body: Padding(
        padding:  EdgeInsets.all(w*0.03),
        child: Column(
          children: [
            SizedBox(height: h*0.03,),
            TextFormField(
              decoration: InputDecoration(
                hintText: "Search",
                labelText: "Search",
                fillColor: Colors.grey[200],
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            SizedBox(height: h*0.03,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: h*0.1,
                  width: w*0.3,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                          offset: Offset(2, 4),
                        ),
                      ],
                      borderRadius: BorderRadius.circular(w*0.03)
                  ),
                  child:Center(child: Text('Parchase order')) ,
                ),
                SizedBox(width: w*0.25,),
                Container(
                  height: h*0.1,
                  width: w*0.3,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                          offset: Offset(2, 4),
                        ),
                      ],
                      borderRadius: BorderRadius.circular(w*0.03)
                  ),
                  child:Center(child: Text('View Alert')) ,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: h*0.1,
                  width: w*0.3,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                          offset: Offset(2, 4),
                        ),
                      ],
                      borderRadius: BorderRadius.circular(w*0.03)
                  ),
                  child:Center(child: Text('Counter sale')) ,
                ),
                SizedBox(height: h*0.2),
                SizedBox(width: h*0.12),
                Container(
                  height: h*0.1,
                  width: w*0.3,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                          offset: Offset(2, 4),
                        ),
                      ],
                      borderRadius: BorderRadius.circular(w*0.03)
                  ),
                  child:Center(child: Text('Stock in')) ,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}