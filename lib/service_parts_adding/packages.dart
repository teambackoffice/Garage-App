import 'package:flutter/material.dart';
import 'package:garage_app/controller/packagecontroller.dart';
import 'package:provider/provider.dart';

class PackageScreen extends StatefulWidget {
   PackageScreen({super.key});

  @override
  State<PackageScreen> createState() => _PackageScreenState();
}

class _PackageScreenState extends State<PackageScreen> {
  void initState() {
    super.initState();
    // Automatically fetch packages on screen load
  
    context.read<PackageController>().getPackageDetails();
    
  }

   

  @override
  Widget build(BuildContext context) {
    return 
    Consumer<PackageController>(
      builder: (context, controller, child) {
        final data = controller.packageDetails;
        return Center(
          child: ElevatedButton(
            onPressed: () {
              showDialog(
            context: context,
            builder: (BuildContext context) {
              return Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                backgroundColor: Colors.white,
                child: Container(
                  padding: EdgeInsets.all(16),
                  height: 400, // Make it bigger
                  width: MediaQuery.of(context).size.width * 0.8, // Responsive width
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select a Package',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.grey),
                            onPressed: () => Navigator.of(context).pop(),
                          )
                        ],
                      ),
                      SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: data!.data.length,
                          itemBuilder: (context, index) {
                            return Card(
                              elevation: 4,
                              margin: EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: Icon(Icons.local_offer, color: Colors.teal),
                                title: Text(
                                  data!.data[index].name,
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${data.data[index].name} selected')),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 10),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('Cancel'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
            },
            child: Text('Choose Packages'),
          ),
        );
      }
    );
  }
}
