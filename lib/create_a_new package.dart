import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CreatePackagePage extends StatefulWidget {
  const CreatePackagePage({super.key});

  @override
  State<CreatePackagePage> createState() => _CreatePackagePageState();
}

class _CreatePackagePageState extends State<CreatePackagePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _laborTotalController = TextEditingController(text: '0');
  final TextEditingController _partsTotalController = TextEditingController(text: '0');
  final TextEditingController _discountController = TextEditingController(text: '0');
  final TextEditingController _grandTotalController = TextEditingController(text: '0');

  bool isDoorstep = false;
  bool publishToPortal = false;
  String? selectedPackageType;
  bool isSubmitting = false;

  Future<void> _submitPackage() async {
    final packName = _nameController.text.trim();
    final packType = selectedPackageType;

    if (packName.isEmpty || packType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Package name and type are required")),
      );
      return;
    }

    final url = 'https://garage.teambackoffice.com/api/method/garage.garage.auth.create_new_package';

    final body = {
      "pack_name": packName,
      "pack_type": packType,
      "parts_items": [
        {"item_name": "Wheel", "qty": 4, "rate": 300}
      ],
      "service_items": [
        {"item_name": "Air filter cleaning", "qty": 1, "rate": 450}
      ]
    };

    setState(() => isSubmitting = true);

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"data": body}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['message'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Package created successfully"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${data['message'] ?? 'Failed to create package'}"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Exception: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Package Details'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Price will be calculated only if all individual item\'s price are available',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(_nameController, 'Package name'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Package type',
                border: OutlineInputBorder(),
              ),
              value: selectedPackageType,
              items: ['Basic', 'Premium', 'Custom'].map((type) => DropdownMenuItem(
                value: type,
                child: Text(type),
              )).toList(),
              onChanged: (value) => setState(() => selectedPackageType = value),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Available Doorstep Service?'),
              value: isDoorstep,
              onChanged: (value) => setState(() => isDoorstep = value),
            ),
            const SizedBox(height: 12),
            _buildMultilineField(_descriptionController, 'Description'),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('SERVICES', style: TextStyle(fontWeight: FontWeight.w600)),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('ADD'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600),
                )
              ],
            ),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('PARTS', style: TextStyle(fontWeight: FontWeight.w600)),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('ADD'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600),
                )
              ],
            ),

            const SizedBox(height: 20),
            _buildRadioOptions(),

            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.camera_alt),
                label: const Text('Add Image'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600),
              ),
            ),

            const SizedBox(height: 20),
            _buildGreenField('Labor Total', _laborTotalController),
            _buildGreenField('Parts Total', _partsTotalController),
            _buildGreenField('Applied discount', _discountController),
            _buildGreenField('Grand Total', _grandTotalController),

            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Publish to portal'),
              value: publishToPortal,
              onChanged: (val) => setState(() => publishToPortal = val),
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : _submitPackage,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black87),
                child: isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Create Package'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildMultilineField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildGreenField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.green),
          ),
        ),
      ),
    );
  }

  Widget _buildRadioOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RadioListTile(
          value: 'generic',
          groupValue: 'generic',
          onChanged: (_) {},
          title: const Text('Generic Package (Applicable for all Models)', style: TextStyle(color: Colors.green)),
        ),
        RadioListTile(
          value: 'class',
          groupValue: '',
          onChanged: (_) {},
          title: const Text('Select Class (i.e Hatchback, Sedan etc.)'),
        ),
        RadioListTile(
          value: 'model_specific',
          groupValue: '',
          onChanged: (_) {},
          title: const Text('Specific package for Vehicle Brand(s) and/or Model(s)'),
        ),
      ],
    );
  }
}