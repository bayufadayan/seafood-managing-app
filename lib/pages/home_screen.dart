import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:prak_mobpro/component/grid_view.dart';
import 'package:prak_mobpro/component/my_widget.dart';
import 'package:prak_mobpro/component/toast.dart';
import 'package:prak_mobpro/model/item.dart';
import 'package:prak_mobpro/pages/input_screen.dart';
import 'package:prak_mobpro/pages/profile_screen.dart';
import 'package:prak_mobpro/pages/splash.dart';
import 'package:prak_mobpro/pages/stock_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // final _searchController = TextEditingController();
  var search = '';
  List<Item> items = [];

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  void loadItems() async {
    var collection = FirebaseFirestore.instance.collection('items');
    var querySnapshot = await collection.get();
    List<Item> items = [];
    for (var queryDocumentSnapshot in querySnapshot.docs) {
      Map<String, dynamic> data = queryDocumentSnapshot.data();
      String documentId = queryDocumentSnapshot.id;
      Item item = Item.fromMap(data, documentId);
      items.add(item);
    }
    setState(() {
      this.items = items;
    });
  }

  // buat menu stock yang ada di drawer
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
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => SplashScreen()),
    );
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
            "Dashboard",
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
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (context) => InputScreen()));
          },
          child: Icon(
            Icons.add,
            color: Colors.white,
          ),
          backgroundColor: Colors.orange,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              const SizedBox(
                height: 15,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.deepOrange.shade700,
                      Colors.orangeAccent.shade200
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: TextField(
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      hintText: "Search",
                      hintStyle: TextStyle(color: Colors.white),
                      filled: true,
                      border: InputBorder.none,
                      fillColor:
                          Colors.transparent, // Set latar belakang transparan
                    ),
                    style: TextStyle(color: Colors.white),
                    // controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        search = value;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              Expanded(
                child: GridDashboard(
                  onItemTap: (Item item) {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => StockScreen(
                        item: item,
                        items: items,
                      ),
                    ));
                  },
                  search: search,
                ),
              )
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
