import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:prak_mobpro/component/toast.dart';
import 'package:prak_mobpro/model/item.dart';
import 'package:prak_mobpro/pages/home_screen.dart';

class StockScreen extends StatefulWidget {
  final Item item;
  final List<Item> items;

  const StockScreen({Key? key, required this.item, required this.items})
      : super(key: key);

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  String editedProductName = '';
  int editedProductQuantity = 0;
  dynamic updatedItem;
  bool _isUploading = false;
  String? _imageUrl;

  void _showEditPopup() {
    TextEditingController itemName =
        TextEditingController(text: updatedItem.name);
    TextEditingController itemCount =
        TextEditingController(text: updatedItem.stock.toString());
    TextEditingController expiredDateController =
        TextEditingController(text: updatedItem.expiredDate.toString());

    //Select tanggal
    Future<void> selectDate(BuildContext context) async {
      DateTime temp;
      try {
        temp = DateFormat('EEE, d/M/yyyy').parse(updatedItem.expiredDate);
      } catch (e) {
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

    bool _validateInputs(
        String name, int? stock, String? expiredDateController) {
      if (name.isEmpty || stock == null) {
        stock = widget.item.stock;
        name = widget.item.name;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('All fields must be filled in')),
        );
        return false;
      }
      return true;
    }

    void _updateProduct(String name, int stock, String expiredDate) async {
      await FirebaseFirestore.instance
          .collection('items')
          .doc(widget.item.id)
          .update({
        'itemName': name,
        'itemCount': stock,
        'expiredDate': expiredDate,
      }).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item updated successfully')),
        );
        Navigator.of(context).pop(true);
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update product: $error')),
        );
      });
      // .whenComplete(() => setState(() => isLoading = false));
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            title: Text('Edit Detail Produk'),
            content: SizedBox(
              height: MediaQuery.of(context).size.height / 3,
              child: ListView(
                children: [
                  TextField(
                    controller: itemName,
                    decoration: InputDecoration(labelText: 'Nama Barang'),
                    onChanged: (value) {
                      editedProductName = value;
                    },
                  ),
                  TextField(
                    controller: itemCount,
                    decoration: InputDecoration(labelText: 'Jumlah'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      editedProductQuantity = int.tryParse(value) ?? 0;
                    },
                  ),
                  TextField(
                    readOnly: true,
                    controller: expiredDateController,
                    decoration:
                        InputDecoration(labelText: 'Tanggal Kadaluarsa'),
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
                child: Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_validateInputs(
                      itemName.text,
                      int.tryParse(itemCount.text),
                      expiredDateController.text)) {
                    _updateProduct(itemName.text, int.tryParse(itemCount.text)!,
                        expiredDateController.text);
                  }
                },
                child: Text('Simpan'),
              ),
            ]);
      },
    );
  }

  Future<void> _deleteItem(String itemId) async {
    await FirebaseFirestore.instance.collection('items').doc(itemId).delete();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item deleted successfully')),
      );
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => HomeScreen()),
          (route) => false);
    }
  }

  showAlertDialog(BuildContext context, String itemId) {
    Widget cancelButton = ElevatedButton(
      child: const Text(
        "Cancel",
        style: TextStyle(color: Color.fromARGB(255, 83, 83, 83)),
      ),
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action cancelled')),
        );
        Navigator.of(context).pop();
      },
    );
    Widget continueButton = ElevatedButton(
      child: const Text(
        "Continue",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
      onPressed: () async {
        await _deleteItem(itemId);
      },
    );
    AlertDialog alert = AlertDialog(
      title: Expanded(
        child: Text(
          'Delete item \'${updatedItem.name}\' ?',
          style: TextStyle(
            color: Colors.red.shade900,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      content: Text(
          "Are you sure you want to delete the item ${updatedItem.name}? This action will delete it permanently."),
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
    int currentIndex = widget.items.indexOf(widget.item);
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

    setState(() {
      _isUploading = true;
    });

    if (image != null) {
      String? imageUrl = await _uploadImageToFirebase(File(image.path));
      if (imageUrl != null) {
        setState(() {
          _imageUrl = imageUrl;
        });
        await FirebaseFirestore.instance
            .collection('items')
            .doc(widget.item.id)
            .update({'itemPicture': imageUrl});
      }
    }

    setState(() {
      _isUploading = false;
    });
  }

  // upload image ke firestore storage
  Future<String?> _uploadImageToFirebase(File imageFile) async {
    String fileName =
        'items/${DateTime.now().millisecondsSinceEpoch.toString()}';
    Reference storageReference = FirebaseStorage.instance.ref().child(fileName);

    UploadTask uploadTask = storageReference.putFile(imageFile);
    await uploadTask.whenComplete(() => {});

    return await storageReference.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: ((context) => const HomeScreen())),
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
              showAlertDialog(context, widget.item.id);
            },
            icon: Icon(
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
        child: Icon(
          Icons.edit,
          color: Colors.white,
        ),
        backgroundColor: Colors.orange,
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
                    SizedBox(
                      height: 25,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () => _navigateToNextOrPreviousItem(false),
                          icon: Icon(
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
                              return Center(child: CircularProgressIndicator());
                            }

                            if (snapshot.hasData && snapshot.data!.exists) {
                              var itemData =
                                  snapshot.data!.data() as Map<String, dynamic>;
                              updatedItem =
                                  Item.fromMap(itemData, snapshot.data!.id);

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
                                      child: updatedItem.imageUrl != "" &&
                                              updatedItem.imageUrl != 'No Image'
                                          ? Image.network(
                                              updatedItem.imageUrl,
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
                                          icon: Icon(
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
                              return Center(child: Text("Item not found"));
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
                        return Center(
                            child: CircularProgressIndicator(
                          color: Colors.deepOrange,
                        ));
                      }

                      if (snapshot.hasData && snapshot.data!.exists) {
                        var itemData =
                            snapshot.data!.data() as Map<String, dynamic>;
                        updatedItem = Item.fromMap(itemData, snapshot.data!.id);

                        return MyProductDetails(
                          productName: updatedItem.name,
                          productDescription:
                              'Saat ini \'${updatedItem.name}\' tersisa ${updatedItem.stock} dan akan kadaluarsa pada ${updatedItem.expiredDate}',
                          productQuantity: updatedItem.stock,
                          productExpiredDate: updatedItem.expiredDate,
                        );
                      } else {
                        return Center(child: Text("Item not found"));
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
              margin: EdgeInsets.only(bottom: 15),
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
  String productName;
  String productDescription;
  int productQuantity;
  String productExpiredDate;

  MyProductDetails({
    super.key,
    required this.productName,
    required this.productDescription,
    required this.productQuantity,
    required this.productExpiredDate,
  });

  @override
  _MyProductDetailsState createState() => _MyProductDetailsState();
}

class _MyProductDetailsState extends State<MyProductDetails> {
  String editedProductName = '';
  String editedProductDescription = '';
  int editedProductQuantity = 0;
  DateTime editedProductExpiredDate = DateTime.now();

  // void _showEditPopup() {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text('Edit Detail Produk'),
  //         content: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             TextField(
  //               decoration: InputDecoration(labelText: 'Nama Barang'),
  //               onChanged: (value) {
  //                 editedProductName = value;
  //               },
  //             ),
  //             TextField(
  //               decoration: InputDecoration(labelText: 'Deskripsi'),
  //               onChanged: (value) {
  //                 editedProductDescription = value;
  //               },
  //             ),
  //             TextField(
  //               decoration: InputDecoration(labelText: 'Jumlah'),
  //               keyboardType: TextInputType.number,
  //               onChanged: (value) {
  //                 editedProductQuantity = int.tryParse(value) ?? 0;
  //               },
  //             ),
  //           ],
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //             child: Text('Batal'),
  //           ),
  //           ElevatedButton(
  //             onPressed: () {
  //               // Implementasikan logika penyimpanan di sini
  //               // Setelah penyimpanan selesai, panggil setState untuk memperbarui tampilan
  //               setState(() {
  //                 widget.productName = editedProductName;
  //                 widget.productDescription = editedProductDescription;
  //                 widget.productQuantity = editedProductQuantity;
  //               });
  //               Navigator.of(context).pop();
  //             },
  //             child: Text('Simpan'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

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
              Text(
                'Nama Barang',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange),
              ),
              Text(
                widget.productName.toUpperCase(),
                style: TextStyle(fontSize: 22),
              ),
              SizedBox(height: 10),
              Text(
                'Deskripsi',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange),
              ),
              Text(
                widget.productDescription,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10),
              Text(
                'Stock',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange),
              ),
              Text(
                '${widget.productQuantity.toString()} items',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10),
              Text(
                'Expired Date',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
              Text(widget.productExpiredDate),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
