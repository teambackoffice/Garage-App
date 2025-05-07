import 'package:flutter/material.dart';

class details extends StatefulWidget {
  const details({super.key});

  @override
  State<details> createState() => _detailsState();
}

class _detailsState extends State<details> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
          onTap: (){
            Navigator.pop(context);
          },
            child: Container(child: Icon(Icons.arrow_back_ios,color: Colors.black,))),
        title: Text('Details',style: TextStyle(
          color: Colors.black
        ),),
      ),
    );
  }
}
