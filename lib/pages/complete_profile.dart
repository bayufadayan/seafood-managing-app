import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prak_mobpro/component/my_button.dart';
import 'package:prak_mobpro/component/toast.dart';
import 'package:prak_mobpro/pages/home_screen.dart';

class CompleteProfileAfterRegist extends StatefulWidget {
  const CompleteProfileAfterRegist({super.key});

  @override
  State<CompleteProfileAfterRegist> createState() =>
      _CompleteProfileAfterRegistState();
}

class _CompleteProfileAfterRegistState
    extends State<CompleteProfileAfterRegist> {
  final TextEditingController fullname = TextEditingController();
  final TextEditingController address = TextEditingController();
  String? _imageUrl;
  bool _isUploading = false;
  bool _isLoading = false;

  // ambil email dari user auth
  Future<String> getCurrentUserEmail() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    return currentUser?.email ?? '';
  }

  // ambil image berdasarkan email user auth
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

  // fungsi update data ke doc collection
  Future<void> _updateUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    if (fullname.text == "" || address.text == "") {
      showToast('Please fill in the fields or you can skip this step');
      setState(() {
        _isLoading = false;
      });
      return;
    }
    String userEmail = FirebaseAuth.instance.currentUser!.email!;
    await FirebaseFirestore.instance.collection('users').doc(userEmail).update({
      'fullname': fullname.text.toUpperCase(),
      'address': address.text,
      'image' : _imageUrl,
    });
    showToast('Profile Completed');
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (context) => HomeScreen()));
    fullname.clear();
    address.clear();
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

  Widget _buildProfileImage() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: SizedBox(
          width: 105,
          child: Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: _imageUrl != null && _imageUrl != 'No Image'
                    ? NetworkImage(_imageUrl!)
                    : null,
                child: _isUploading
                    ? CircularProgressIndicator() // Tampilkan ini saat mengunggah
                    : (_imageUrl != null && _imageUrl != 'No Image'
                        ? null
                        : Icon(Icons.person,
                            size: 50, color: Colors.grey.shade800)),
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
                        foregroundColor: MaterialStateProperty.all<Color>(
                            Colors.white), // Warna ikon
                      ),
                    )),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Complete Your Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.deepOrange.shade700,
                Colors.orangeAccent.shade200
              ],
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 25, right: 20, left: 20),
        child: ListView(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileImage(),
                SizedBox(height: 20),
                Text(
                  'Your Fullname',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                TextField(
                  controller: fullname,
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Colors.deepOrange),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.deepOrange),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    fillColor: Colors.white,
                    filled: true,
                    hintText: "Masukan Nama Lengkap",
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Text(
                  'Your Email',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                FutureBuilder<String>(
                  future: getCurrentUserEmail(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      return TextField(
                        enabled: false,
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          fillColor: Colors.grey.shade300,
                          filled: true,
                          hintText: snapshot.data,
                          hintStyle: TextStyle(color: Colors.grey.shade600),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 15, horizontal: 20),
                        ),
                      );
                    } else {
                      return const CircularProgressIndicator();
                    }
                  },
                ),
                SizedBox(
                  height: 10,
                ),
                Text(
                  'Your Address',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                TextField(
                  controller: address,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Colors.deepOrange),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.deepOrange),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    fillColor: Colors.white,
                    filled: true,
                    hintText: "Masukan Alamat",
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                MyButton(
                  onTap: () async {
                    await _updateUserProfile();
                  },
                  text: 'Next',
                  isLoading: _isLoading,
                ),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                          builder: (context) => HomeScreen()));
                    },
                    child: Text(
                      'Skip this step',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
