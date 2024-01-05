import 'dart:io';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:prak_mobpro/component/my_button.dart';
import 'package:prak_mobpro/component/my_input_field.dart';
import 'package:prak_mobpro/component/my_widget.dart';
import 'package:prak_mobpro/component/toast.dart';
import 'package:prak_mobpro/model/item.dart';
import 'package:prak_mobpro/pages/home_screen.dart';
import 'package:prak_mobpro/pages/login_page.dart';
import 'package:prak_mobpro/pages/profile_screen.dart';
import 'package:prak_mobpro/pages/splash.dart';
import 'package:prak_mobpro/pages/stock_screen.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController itemName = TextEditingController();
  TextEditingController itemCode = TextEditingController();
  TextEditingController itemCount = TextEditingController();
  TextEditingController expiredDate = TextEditingController();
  TextEditingController itemPictures = TextEditingController();
  bool _isLoading = false;
  bool _isUploading = false;

  List<Item> items = [];

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  void loadItems() async {
    var collection = FirebaseFirestore.instance.collection('items');
    var querySnapshot = await collection.get();
    List<Item> itemsLoad = [];
    for (var queryDocumentSnapshot in querySnapshot.docs) {
      Map<String, dynamic> data = queryDocumentSnapshot.data();
      String documentId = queryDocumentSnapshot.id;
      Item item = Item.fromMap(data, documentId);
      itemsLoad.add(item);
    }
    setState(() {
      items = itemsLoad;
    });
  }

  void navigateToStockScreenWithFirstItem() async {
    if (items.isNotEmpty) {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => StockScreen(
            item: items.first,
            items: items,
          ),
        ),
      );

      if (result == true) {
        loadItems();
      }
    } else {
      showToast('No item found! Please add item first');
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()));
    }
  }

  // SignOut
  Future<void> signOut() async {
    FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SplashScreen()),
    );
  }

  // buat di drawer ambil data user
  Stream<DocumentSnapshot> getUserData() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .snapshots();
    } else {
      return Stream.empty();
    }
  }

  // Gambar Item nya
  String? _uploadedFileURL;
  String? _uploadedFileName;

  // upload ke storage
  Future<void> _uploadImage(File imageFile) async {
    setState(() {
      _isUploading = true;
    });
    String fileName = 'items/${imageFile.path.split('/').last}';
    Reference storageReference = FirebaseStorage.instance.ref().child(fileName);

    UploadTask uploadTask = storageReference.putFile(imageFile);
    await uploadTask.whenComplete(() => null);

    String fileURL = await storageReference.getDownloadURL();
    setState(() {
      _uploadedFileURL = fileURL;
      _uploadedFileName = imageFile.path.split('/').last;
      _isUploading = false;
    });
  }

  // Fungsi ambil gambar
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      File imageFile = File(image.path);
      await _uploadImage(imageFile);
    }
  }

  // create item
  Future<void> _createItem() async {
    setState(() {
      _isLoading = true;
    });
    CollectionReference items = FirebaseFirestore.instance.collection('items');

    await items.add({
      'itemName': itemName.text,
      'itemCode': itemCode.text,
      'itemCount': int.parse(itemCount.text),
      'expiredDate': expiredDate.text,
      'itemPicture': _uploadedFileURL ?? 'No Image',
    }).then((value) {
      showToast('Item Added',
          bgcolor: Colors.grey.shade300, textColor: Colors.black);
      setState(() {
        _isLoading = false;
      });
      _clearForm();
      Navigator.of(context)
          .push(MaterialPageRoute(builder: ((context) => const HomeScreen())));
    }).catchError((error) {
      setState(() {
        _isLoading = false;
      });
      showToast("Failed to add item: $error");
    });
  }

  bool _validateInputs() {
    return itemName.text.isNotEmpty &&
        itemCode.text.isNotEmpty &&
        itemCount.text.isNotEmpty &&
        expiredDate.text.isNotEmpty;
  }

  void _clearForm() {
    itemName.clear();
    itemCode.clear();
    itemCount.clear();
    expiredDate.clear();
    itemPictures.clear();
    setState(() {
      _uploadedFileURL = null;
    });
  }

  void _showInfo(BuildContext context) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      animType: AnimType.rightSlide,
      title: 'INFO!',
      desc: 'Work In Progress',
      btnOkOnPress: () {},
    )..show();
  }
  void _showLogout(BuildContext context) {
    AwesomeDialog(
            context: context,
            dialogType: DialogType.warning,
            animType: AnimType.rightSlide,
            title: 'Logout?',
            desc: 'Are you sure want to logout?',
            btnOkOnPress: () {
              signOut();
            },
            btnCancelOnPress: () {})
        .show();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Builder(builder: (context) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 5,
                ),
                IconButton(
                    onPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                    icon: const Icon(Icons.menu, color: Colors.deepOrange)),
              ],
            );
          }),
          title: const Text(
            "INPUT BARANG",
            style: TextStyle(
              color: Colors.deepOrange,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
                onPressed: () {
                  _showInfo(context);
                },
                icon: const Icon(
                  Icons.notifications,
                  color: Colors.deepOrange,
                )),
            const SizedBox(
              width: 5,
            )
          ],
        ),
        drawer: _myDrawer(context),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: ListView(
            children: [
              const SizedBox(
                height: 20,
              ),
              //nama barang
              const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "Nama Barang",
                    style: TextStyle(
                        color: Colors.deepOrange,
                        fontSize: 16,
                        fontWeight: FontWeight.normal),
                  ),
                ],
              ),
              const SizedBox(
                height: 5,
              ),

              MyInputField(
                controller: itemName,
                hintText: "Masukkan Nama Barang",
                obscureText: false,
                icon: Icon(
                  Icons.card_giftcard,
                  color: Colors.deepOrange,
                ),
              ),
              SizedBox(
                height: 10,
              ),

              //Kode barang
              const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "Kode Barang",
                    style: TextStyle(
                        color: Colors.deepOrange,
                        fontSize: 16,
                        fontWeight: FontWeight.normal),
                  ),
                ],
              ),
              const SizedBox(
                height: 5,
              ),

              MyInputField(
                controller: itemCode,
                hintText: "Masukkan Kode Barang",
                obscureText: false,
                icon: Icon(
                  Icons.tag,
                  color: Colors.deepOrange,
                ),
              ),

              SizedBox(
                height: 10,
              ),

              //Jumlah barang
              const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "Jumlah Barang",
                    style: TextStyle(
                        color: Colors.deepOrange,
                        fontSize: 16,
                        fontWeight: FontWeight.normal),
                  ),
                ],
              ),
              const SizedBox(
                height: 5,
              ),

              MyInputField(
                isNumber: true,
                controller: itemCount,
                hintText: "Masukkan Jumlah Barang",
                obscureText: false,
                icon: Icon(
                  Icons.all_inclusive,
                  color: Colors.deepOrange,
                ),
              ),

              SizedBox(
                height: 10,
              ),

              //Expired barang
              const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "Expired Date",
                    style: TextStyle(
                        color: Colors.deepOrange,
                        fontSize: 16,
                        fontWeight: FontWeight.normal),
                  ),
                ],
              ),
              const SizedBox(
                height: 5,
              ),

              MyInputField(
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2030),
                  );
                  if (pickedDate != null) {
                    String formattedDate =
                        DateFormat('EEE, d/M/y').format(pickedDate);
                    expiredDate.text = formattedDate;
                  }
                },
                controller: expiredDate,
                hintText: "Masukkan Expired Date",
                obscureText: false,
                icon: Icon(Icons.calendar_month, color: Colors.deepOrange),
                readOnly: true, // Membuat TextField hanya bisa diakses via klik
              ),

              SizedBox(
                height: 10,
              ),

              //Gambar barang
              const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "Pilih Gambar",
                    style: TextStyle(
                        color: Colors.deepOrange,
                        fontSize: 16,
                        fontWeight: FontWeight.normal),
                  ),
                ],
              ),
              const SizedBox(
                height: 5,
              ),

              MyInputField(
                onTap: _pickImage,
                readOnly: true,
                controller: itemPictures,
                hintText: _uploadedFileName ?? "Masukkan Gambar",
                obscureText: false,
                suffixIcon: _isUploading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 3.0,
                          color: Colors.deepOrange,
                        ),
                      )
                    : Icon(Icons.upload_file),
                icon: Icon(
                  Icons.image,
                  color: Colors.deepOrange,
                ),
              ),

              SizedBox(
                height: 10,
              ),

              const SizedBox(
                height: 20,
              ),

              MyButton(
                onTap: () {
                  if (_validateInputs()) {
                    _createItem();
                  } else {
                    showToast(
                        'Please fill in the data. Only images can be blank');
                  }
                },
                text: "Input Data",
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Drawer _myDrawer(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width, // Lebar drawer
      backgroundColor: Colors.deepOrange.shade800,
      child: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Colors.deepOrange.shade600, Colors.orangeAccent.shade200],
          ),
        ),
        child: Column(
          children: [
            //header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: () => _scaffoldKey.currentState?.closeDrawer(),
                      icon: const Icon(
                        Icons.close_outlined,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        _showInfo(context);
                      },
                      icon:
                          const Icon(Icons.notifications, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                  ],
                )
              ],
            ),

            const SizedBox(
              height: 10,
            ),

            //header drawer

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(width: 10),

                    StreamBuilder<DocumentSnapshot>(
                      stream: getUserData(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator(); // Tampilkan loading saat data sedang diambil
                        }
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }
                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.grey.shade500,
                            child: Icon(Icons.person,
                                size: 30, color: Colors.white),
                          );
                        }

                        Map<String, dynamic> userData =
                            snapshot.data!.data() as Map<String, dynamic>;
                        String imageUrl =
                            userData['image'] ?? 'path/to/default/image';

                        return imageUrl != 'No Image'
                            ? CircleAvatar(
                                radius: 25,
                                backgroundImage: NetworkImage(imageUrl),
                              )
                            : CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.grey.shade500,
                                child: Icon(Icons.person,
                                    size: 30, color: Colors.white),
                              );
                      },
                    ),
                    SizedBox(
                      width: 5,
                    ),

                    //status dan nama
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "STATUS",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w200),
                        ),
                        StreamBuilder<DocumentSnapshot>(
                          stream: getUserData(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return CircularProgressIndicator(
                                  color: Colors.white);
                            }
                            if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}',
                                  style: TextStyle(color: Colors.white));
                            }
                            if (!snapshot.hasData || !snapshot.data!.exists) {
                              return Text('No Name',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 17,
                                      color: Colors.white));
                            }

                            Map<String, dynamic> userData =
                                snapshot.data!.data() as Map<String, dynamic>;
                            String fullName = userData['fullname'] ?? 'No Name';

                            return Text(
                              fullName,
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 17,
                                  color: Colors.white),
                            );
                          },
                        )
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const ProfileScreen()));
                      },
                      icon: const Icon(
                        Icons.settings,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    )
                  ],
                ),
              ],
            ),

            //garis
            Divider(
              color: Colors.white.withAlpha(155),
              // height: 0.5,
              thickness: 1,
              indent: 10,
              endIndent: 10,
            ),

            const SizedBox(
              height: 5,
            ),
            //menu

            //menu dashboard
            ListTile(
              leading: const Icon(
                Icons.dashboard,
                color: Colors.white,
              ),
              title: const Text(
                "Dashboard",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.normal),
              ),
              onTap: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (context) => const HomeScreen()));
              },
            ),

            //menu input barang
            ListTile(
              leading: const Icon(
                Icons.input,
                color: Colors.white,
              ),
              title: const Text(
                "Input Barang",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.normal),
              ),
              onTap: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => InputScreen()));
              },
            ),

            //menu stock barang
            ListTile(
              leading: const Icon(
                Icons.card_giftcard,
                color: Colors.white,
              ),
              title: const Text(
                "Stock Barang",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.normal),
              ),
              onTap: () {
                navigateToStockScreenWithFirstItem();
              },
            ),

            //garis
            Divider(
              color: Colors.white.withAlpha(155),

              // height: 0.5,
              thickness: 1,
              indent: 10,
              endIndent: 10,
            ),

            //menu lain

            //menu lainya
            // ListTile(
            //   leading: const Icon(
            //     Icons.more_horiz,
            //     color: Colors.white,
            //   ),
            //   title: const Text(
            //     "Menu Lainnya",
            //     style: TextStyle(
            //         color: Colors.white, fontWeight: FontWeight.normal),
            //   ),
            //   onTap: () {},
            // ),

            MyWidget(),

            const SizedBox(
              height: 25,
            ),

            //logout
            TextButton(
              onPressed: () {
                _showLogout(context);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                margin: const EdgeInsets.fromLTRB(5, 10, 5, 10),
                height: 50,
                width: 120,
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Icon(Icons.logout, color: Colors.deepOrange),
                    Text(
                      "Logout",
                      style: TextStyle(
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.w500),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
