import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:g_stock/model/item.dart';
import 'package:g_stock/pages/stock_screen.dart';

class GridDashboard extends StatefulWidget {
  final ValueChanged<Item> onItemTap;
  final String search;

  const GridDashboard(
      {super.key, required this.onItemTap, required this.search});

  @override
  State<GridDashboard> createState() => _GridDashboardState();
}

class _GridDashboardState extends State<GridDashboard> {
  List<Item> items = [];

  Future<void> _deleteItem(String itemId) async {
    await FirebaseFirestore.instance.collection('items').doc(itemId).delete();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item deleted successfully')),
    );
    Navigator.of(context).pop();
  }

  void _showAlertDialog(BuildContext context, String itemId, String itemName) {
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
        'Delete item \'$itemName\'?',
        style: TextStyle(
          color: Colors.red.shade900,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        'Are you sure you want to delete the item $itemName? This action will delete it permanently.',
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

  @override
  Widget build(BuildContext context) {
    Stream<QuerySnapshot> stream;
    if (widget.search.isEmpty) {
      stream = FirebaseFirestore.instance.collection('items').snapshots();
    } else {
      stream = FirebaseFirestore.instance
          .collection('items')
          .orderBy('itemName')
          .startAt([widget.search]).endAt(
              ['${widget.search}\uf8ff']).snapshots();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No items found'));
        }

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          items = snapshot.data!.docs
              .map((doc) =>
                  Item.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();
        }
        return GridView.builder(
          itemCount: snapshot.data!.docs.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.8,
          ),
          itemBuilder: (context, index) {
            Item item = items[index];
            return GestureDetector(
              onTap: () => widget.onItemTap(item),
              child: _buildItemCard(item),
            );
          },
        );
      },
    );
  }

  Widget _buildItemCard(Item item) {
    return LayoutBuilder(builder: (context, constraints) {
      final double cardHeight = constraints.maxHeight;
      final double cardWidth = constraints.maxWidth;

      return Card(
        elevation: 4,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Stack(
          children: [
            item.imageUrl.isNotEmpty && item.imageUrl != 'No Image'
                ? Image.network(
                    item.imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    height: cardHeight,
                  )
                : Image.asset(
                    'assets/no_image.png',
                    width: double.infinity,
                    fit: BoxFit.cover,
                    height: cardHeight,
                  ),
            Positioned(
              top: 0,
              child: Container(
                width: cardWidth,
                height: cardHeight / 5,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black38, Color.fromARGB(50, 0, 0, 0)],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 15,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.only(left: 5, right: 5),
                height: cardHeight / 4,
                color: Colors.deepOrange.withValues(alpha: 0.8),
                child: Column(
                  children: <Widget>[
                    Text(
                      item.code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color.fromARGB(200, 255, 255, 255),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      item.name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -7,
              right: -9,
              child: PopupMenuButton<String>(
                onSelected: (String value) {
                  if (value == 'Edit') {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) =>
                          StockScreen(item: item, items: items),
                    ));
                  } else if (value == 'Delete') {
                    _showAlertDialog(context, item.id, item.name);
                  }
                },
                itemBuilder: (BuildContext context) {
                  return {'Edit', 'Delete'}.map((String choice) {
                    return PopupMenuItem<String>(
                      value: choice,
                      child: Text(choice),
                    );
                  }).toList();
                },
                icon: const Icon(Icons.more_vert, color: Colors.white),
              ),
            ),
            Positioned(
              top: 4,
              left: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Expired on',
                    style: TextStyle(color: Colors.white, fontSize: 9),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    item.expiredDate,
                    style: TextStyle(color: Colors.white, fontSize: 9),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          ],
        ),
      );
    });
  }
}
