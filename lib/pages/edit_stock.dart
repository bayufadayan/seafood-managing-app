
import 'package:flutter/material.dart';

class MyProductDetails extends StatefulWidget {
  final String productName;
  final String productDescription;
  final int productQuantity;

  const MyProductDetails({
    super.key,
    required this.productName,
    required this.productDescription,
    required this.productQuantity,
  });

  @override
  State<MyProductDetails> createState() => _MyProductDetailsState();
}

class _MyProductDetailsState extends State<MyProductDetails> {
  late String currentProductName;
  late String currentProductDescription;
  late int currentProductQuantity;

  String editedProductName = '';
  String editedProductDescription = '';
  int editedProductQuantity = 0;

  @override
  void initState() {
    super.initState();
    currentProductName = widget.productName;
    currentProductDescription = widget.productDescription;
    currentProductQuantity = widget.productQuantity;
  }

  void showEditPopup() {
    editedProductName = currentProductName;
    editedProductDescription = currentProductDescription;
    editedProductQuantity = currentProductQuantity;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Detail Produk'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Nama Barang'),
                onChanged: (value) {
                  editedProductName = value;
                },
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Deskripsi'),
                onChanged: (value) {
                  editedProductDescription = value;
                },
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Jumlah'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  editedProductQuantity = int.tryParse(value) ?? 0;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                // Implementasikan logika penyimpanan di sini
                // Setelah penyimpanan selesai, panggil setState untuk memperbarui tampilan
                setState(() {
                  currentProductName = editedProductName;
                  currentProductDescription = editedProductDescription;
                  currentProductQuantity = editedProductQuantity;
                });
                Navigator.of(context).pop();
              },
              child: Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        color: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nama Barang',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                currentProductName,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'Deskripsi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                currentProductDescription,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'Jumlah',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                currentProductQuantity.toString(),
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
                
            ],
          ),
        ),
      ),
    );
  }
}