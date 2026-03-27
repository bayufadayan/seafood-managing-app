import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:g_stock/component/toast.dart';
import 'package:g_stock/model/item.dart';
import 'package:g_stock/pages/home_screen.dart';

class StockScreen extends StatefulWidget {
  final Item item;
  final List<Item> items;

  const StockScreen({super.key, required this.item, required this.items});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  Item? _updatedItem;

  void _showEditPopup() {
    final item = _updatedItem ?? widget.item;
    final TextEditingController itemName =
        TextEditingController(text: item.name);
    final TextEditingController itemCount =
        TextEditingController(text: item.stock.toString());
    final TextEditingController expiredDateController =
        TextEditingController(text: item.expiredDate);

    // Select tanggal
    Future<void> selectDate(BuildContext context) async {
      DateTime temp;
      try {
        temp = DateFormat('EEE, d/M/yyyy').parse(item.expiredDate);
      } catch (_) {
        temp = DateTime.now().add(const Duration(days: 2));
      }
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: temp,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        setState(() {
          expiredDateController.text = DateFormat('EEE, d/M/y').format(picked);
        });
      }
    }

    bool validateInputs(String name, int? stock) {
      if (name.isEmpty || stock == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All fields must be filled in')),
        );
        return false;
      }
      return true;
    }

    Future<void> updateProduct(
        String name, int stock, String expiredDate) async {
      try {
        await FirebaseFirestore.instance
            .collection('items')
            .doc(widget.item.id)
            .update({
          'itemName': name,
          'itemCount': stock,
          'expiredDate': expiredDate,
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item updated successfully')),
        );
        Navigator.of(context).pop(true);
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update product: $error')),
        );
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            title: const Text('Edit Detail Produk'),
            content: SizedBox(
              height: MediaQuery.of(context).size.height / 3,
              child: ListView(
                children: [
                  TextField(
                    controller: itemName,
                    decoration: const InputDecoration(labelText: 'Nama Barang'),
                  ),
                  TextField(
                    controller: itemCount,
                    decoration: const InputDecoration(labelText: 'Jumlah'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    readOnly: true,
                    controller: expiredDateController,
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Kadaluarsa',
                    ),
                    onTap: () {
                      selectDate(context);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (validateInputs(
                      itemName.text, int.tryParse(itemCount.text))) {
                    updateProduct(
                      itemName.text,
                      int.tryParse(itemCount.text)!,
                      expiredDateController.text,
                    );
                  }
                },
                child: const Text('Simpan'),
              ),
            ]);
      },
    );
  }

  Future<void> _deleteItem(String itemId) async {
    await FirebaseFirestore.instance.collection('items').doc(itemId).delete();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item deleted successfully')),
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  void _showAlertDialog(BuildContext context, String itemId) {
    final item = _updatedItem ?? widget.item;
    final Widget cancelButton = ElevatedButton(
      child: const Text(
        'Cancel',
        style: TextStyle(color: Color.fromARGB(255, 83, 83, 83)),
      ),
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Action cancelled')),
        );
        Navigator.of(context).pop();
      },
    );
    final Widget continueButton = ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
      onPressed: () async {
        await _deleteItem(itemId);
      },
      child: const Text(
        'Continue',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
    final AlertDialog alert = AlertDialog(
      title: Text(
        'Delete item \'${item.name}\' ?',
        style: TextStyle(
          color: Colors.red.shade900,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        'Are you sure you want to delete the item ${item.name}? This action will delete it permanently.',
      ),
      actions: [
        cancelButton,
        continueButton,
      ],
    );
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  // Navigasi kiri kanan
  void _navigateToNextOrPreviousItem(bool isNext) {
    final int currentIndex = widget.items.indexOf(widget.item);
    if (isNext && currentIndex < widget.items.length - 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => StockScreen(
            item: widget.items[currentIndex + 1],
            items: widget.items,
          ),
        ),
      );
    } else if (!isNext && currentIndex > 0) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => StockScreen(
            item: widget.items[currentIndex - 1],
            items: widget.items,
          ),
        ),
      );
    } else {
      showToast('No more items');
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final String? imageUrl = await _uploadImageToFirebase(File(image.path));
      if (imageUrl != null) {
        await FirebaseFirestore.instance
            .collection('items')
            .doc(widget.item.id)
            .update({'itemPicture': imageUrl});
      }
    }
  }

  // upload image ke firestore storage
  Future<String?> _uploadImageToFirebase(File imageFile) async {
    final String fileName = 'items/${DateTime.now().millisecondsSinceEpoch}';
    final Reference storageReference =
        FirebaseStorage.instance.ref().child(fileName);

    final UploadTask uploadTask = storageReference.putFile(imageFile);
    await uploadTask.whenComplete(() => {});

    return storageReference.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        title: const Text(
          'STOCK BARANG',
          style: TextStyle(color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.deepOrange.shade700,
                Colors.orangeAccent.shade200
              ], // Atur warna sesuai keinginan
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _showAlertDialog(context, widget.item.id);
            },
            icon: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showEditPopup();
        },
        backgroundColor: Colors.orange,
        child: const Icon(
          Icons.edit,
          color: Colors.white,
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height / 3,
                decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(20)),
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepOrange.shade700,
                        Colors.orangeAccent.shade200
                      ],
                    )),
                child: Column(
                  children: [
                    const SizedBox(
                      height: 25,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () => _navigateToNextOrPreviousItem(false),
                          icon: const Icon(
                            Icons.arrow_circle_left_rounded,
                            size: 35,
                            color: Colors.white,
                          ),
                        ),
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('items')
                              .doc(widget.item.id)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (snapshot.hasData && snapshot.data!.exists) {
                              final itemData =
                                  snapshot.data!.data() as Map<String, dynamic>;
                              _updatedItem =
                                  Item.fromMap(itemData, snapshot.data!.id);
                              final item = _updatedItem!;

                              return Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    height: 155,
                                    width: 250,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey.shade200,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: item.imageUrl.isNotEmpty &&
                                              item.imageUrl != 'No Image'
                                          ? Image.network(
                                              item.imageUrl,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            )
                                          : Image.asset(
                                              'assets/no_image.png',
                                              width: double.infinity,
                                              fit: BoxFit.contain,
                                            ),
                                    ),
                                  ),
                                  // Tombol kamera
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: GestureDetector(
                                      onTap: _pickImage,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          shape: BoxShape.circle,
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.camera_alt,
                                            color: Colors.white,
                                            size: 30,
                                          ),
                                          onPressed:
                                              _pickImage, // Fungsi untuk memilih gambar
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              return const Center(
                                  child: Text('Item not found'));
                            }
                          },
                        ),
                        IconButton(
                          onPressed: () => _navigateToNextOrPreviousItem(true),
                          icon: const Icon(
                            Icons.arrow_circle_right_rounded,
                            size: 35,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('items')
                        .doc(widget.item.id)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(
                          color: Colors.deepOrange,
                        ));
                      }

                      if (snapshot.hasData && snapshot.data!.exists) {
                        final itemData =
                            snapshot.data!.data() as Map<String, dynamic>;
                        _updatedItem =
                            Item.fromMap(itemData, snapshot.data!.id);
                        final item = _updatedItem!;

                        return MyProductDetails(
                          productName: item.name,
                          productDescription:
                              'Saat ini \'${item.name}\' tersisa ${item.stock} dan akan kadaluarsa pada ${item.expiredDate}',
                          productQuantity: item.stock,
                          productExpiredDate: item.expiredDate,
                        );
                      } else {
                        return const Center(child: Text('Item not found'));
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 200,
            left: (MediaQuery.of(context).size.width / 2) / 2,
            right: (MediaQuery.of(context).size.width / 2) / 2,
            child: Container(
              margin: const EdgeInsets.only(bottom: 15),
              width: MediaQuery.of(context).size.width / 2,
              height: 50,
              child: Card(
                color: Colors.white,
                elevation: 5,
                child: Center(
                    child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    widget.item.code,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 20),
                  ),
                )),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MyProductDetails extends StatefulWidget {
  final String productName;
  final String productDescription;
  final int productQuantity;
  final String productExpiredDate;

  const MyProductDetails({
    super.key,
    required this.productName,
    required this.productDescription,
    required this.productQuantity,
    required this.productExpiredDate,
  });

  @override
  State<MyProductDetails> createState() => _MyProductDetailsState();
}

class _MyProductDetailsState extends State<MyProductDetails> {
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
          padding: const EdgeInsets.only(top: 25),
          child: ListView(
            // crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nama Barang',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange),
              ),
              Text(
                widget.productName.toUpperCase(),
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(height: 10),
              const Text(
                'Deskripsi',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange),
              ),
              Text(
                widget.productDescription,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              const Text(
                'Stock',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange),
              ),
              Text(
                '${widget.productQuantity} items',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              const Text(
                'Expired Date',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
              Text(widget.productExpiredDate),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
