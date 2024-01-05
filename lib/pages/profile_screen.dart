import 'dart:io';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prak_mobpro/component/my_button.dart';
import 'package:prak_mobpro/component/toast.dart';
import 'package:prak_mobpro/pages/home_screen.dart';
import 'package:prak_mobpro/pages/login_page.dart';
import 'package:prak_mobpro/pages/myaddres_screen.dart';
import 'package:prak_mobpro/pages/splash.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController fullName = TextEditingController();
  final TextEditingController address = TextEditingController();
  String? _imageUrl;
  bool _isUploading = false;

  void _showInfo(BuildContext context) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      animType: AnimType.rightSlide,
      title: 'INFO!',
      desc: 'Work In Progress',
      btnOkOnPress: () {
      },
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
      btnCancelOnPress: (){}
    ).show();
  }

  Future<void> _loadProfileImage() async {
    String userEmail = FirebaseAuth.instance.currentUser!.email!;
    var userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userEmail)
        .get();
    if (userDoc.exists && userDoc.data()!.containsKey('image')) {
      setState(() {
        _imageUrl = userDoc.data()!['image'];
      });
    }
  }

  Future<String> _getUserFullName() async {
    String userEmail = FirebaseAuth.instance.currentUser!.email!;
    var userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userEmail)
        .get();
    return userDoc.data()?['fullname'] ?? 'No Name';
  }

  Future<String> _getUserAdress() async {
    String userEmail = FirebaseAuth.instance.currentUser!.email!;
    var userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userEmail)
        .get();
    return userDoc.data()?['address'] ?? 'No Address';
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => SplashScreen()),
    );
  }

  // fungsi ambil gambar dari device
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
        String userEmail = FirebaseAuth.instance.currentUser!.email!;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userEmail)
            .update({'image': imageUrl});
      }
    }

    setState(() {
      _isUploading = false;
    });
  }

  // upload image ke firestore storage
  Future<String?> _uploadImageToFirebase(File imageFile) async {
    String fileName =
        'user_images/${DateTime.now().millisecondsSinceEpoch.toString()}';
    Reference storageReference = FirebaseStorage.instance.ref().child(fileName);

    UploadTask uploadTask = storageReference.putFile(imageFile);
    await uploadTask.whenComplete(() => {});

    return await storageReference.getDownloadURL();
  }

  Future<void> _updateUserProfile() async {
    if (fullName.text.isEmpty || address.text.isEmpty) {
      showToast('Please fill in all the fields');
      return;
    }

    String userEmail = FirebaseAuth.instance.currentUser!.email!;
    await FirebaseFirestore.instance.collection('users').doc(userEmail).update({
      'fullname': fullName.text.toUpperCase(),
      'address': address.text,
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.of(context).pop();
    }).catchError((error) {
      showToast('Failed to update profile: $error');
    });
  }

  void popup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Detail'),
          content: SizedBox(
            height: (MediaQuery.of(context).size.height / 2) / 2.5,
            child: ListView(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: fullName,
                      decoration: InputDecoration(labelText: 'Full Name'),
                      onChanged: (value) {
                        // editedProductName = value;
                      },
                    ),
                    // email dan password keknya agak males buat di edit
                    // TextField(
                    //   decoration: InputDecoration(labelText: 'Email'),
                    //   onChanged: (value) {
                    //     // editedProductName = value;
                    //   },
                    // ),
                    // TextField(
                    //   decoration: InputDecoration(labelText: 'Password'),
                    //   onChanged: (value) {
                    //     // editedProductDescription = value;
                    //   },
                    // ),
                    TextField(
                      controller: address,
                      decoration: InputDecoration(labelText: 'Address'),
                      onChanged: (value) {},
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Action Cancelled')),
                );
                // showToast('Action Cancelled');
              },
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                _updateUserProfile();
              },
              child: Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  // buat fullname
  Future<void> _loadProfileData() async {
    var fullNameText = await _getUserFullName();
    var addressText = await _getUserAdress();
    setState(() {
      fullName.text = fullNameText;
      address.text = addressText;
    });
    _loadProfileImage();
  }

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
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
            'PROFILE',
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
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            popup();
          },
          backgroundColor: Colors.orange,
          child: Icon(
            Icons.edit,
            color: Colors.white,
          ),
        ),
        body: ListView(children: [
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: SizedBox(
                        width: 140,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 70,
                              backgroundColor: Colors.grey.shade300,
                              backgroundImage:
                                  _imageUrl != null && _imageUrl != 'No Image'
                                      ? NetworkImage(_imageUrl!)
                                      : null,
                              child: _isUploading
                                  ? CircularProgressIndicator()
                                  : (_imageUrl != null &&
                                          _imageUrl != 'No Image'
                                      ? null
                                      : Icon(Icons.person,
                                          size: 70,
                                          color: Colors.grey.shade800)),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                  height: 40,
                                  width: 40,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(100),
                                      color: Colors.blue),
                                  child: IconButton(
                                    onPressed: _pickImage,
                                    icon: Icon(Icons.camera_alt),
                                    style: ButtonStyle(
                                      foregroundColor:
                                          MaterialStateProperty.all<Color>(
                                              Colors.white), // Warna ikon
                                    ),
                                  )),
                            )
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Text(
                      "STATUS",
                      style: TextStyle(
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                          fontSize: 16),
                    ),
                    FutureBuilder<String>(
                      future: _getUserFullName(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          return Text(
                            snapshot.data!,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 20,
                            ),
                          );
                        }
                        return CircularProgressIndicator(color: Colors.white);
                      },
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: (){
                        _showInfo(context);
                      },
                      child: MenuProfileList(
                        title: 'Change Email',
                        icon: Icons.email,
                        endIcon: false,
                      ),
                    ),
                    Divider(
                      color: Colors.grey.withAlpha(155),

                      // height: 0.5,
                      thickness: 1,
                      indent: 10,
                      endIndent: 10,
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: (){
                        _showInfo(context);
                      },
                      child: MenuProfileList(
                        title: 'Change Password',
                        icon: Icons.key,
                        endIcon: false,
                      ),
                    ),
                    Divider(
                      color: Colors.grey.withAlpha(155),

                      // height: 0.5,
                      thickness: 1,
                      indent: 10,
                      endIndent: 10,
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () async {
                        String address = await _getUserAdress();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                MyAddressScreen(myaddress: address),
                          ),
                        );
                      },
                      child: MenuProfileList(
                        title: 'Alamat',
                        icon: Icons.map,
                        endIcon: false,
                      ),
                    ),
                    Divider(
                      color: Colors.grey.withAlpha(155),

                      // height: 0.5,
                      thickness: 1,
                      indent: 10,
                      endIndent: 10,
                    ),
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 50),
                      child: MyButton(
                          onTap: () {
                            _showLogout(context);
                          },
                          text: 'Logout'),
                    )
                  ],
                ),
              )
            ],
          ),
        ]),
      ),
    );
  }
}

class MenuProfileList extends StatelessWidget {
  const MenuProfileList(
      {Key? key,
      required this.title,
      required this.icon,
      // required this.onPress,
      this.endIcon = true,
      this.textColor})
      : super(key: key);

  final String title;
  final IconData icon;
  final bool endIcon;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            color: Colors.transparent,
          ),
          child: Icon(
            icon,
            color: Colors.deepOrange,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(color: textColor),
        ),
        trailing: endIcon
            ? Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  color: Colors.grey.withOpacity(0.1),
                ),
                child: const Icon(
                  Icons.edit,
                  color: Colors.grey,
                ))
            : null);
  }
}
