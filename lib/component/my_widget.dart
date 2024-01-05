import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {

  void _showPopupHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Help'),
          content: Center(
            child: Text('Aplikasi Pencatatan Stock gudang \n1. Menambahkan stock \n2.Membaca stock \n3.Mengupdate data stock \n4. Menghapus stock \n\n Halaman halaman di aplikasi Gudang \n- Home Page \n- Input Barang Page \n- Stock Barang Page \n- Profile Page \n- Drawer'),
          ),
          actions: <Widget>[
            // Tombol tutup dialog
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  void _showPopupAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('About'),
          content: Center(
            child: Text('Developer Gudang \n1. Muhamad Bayu Fadayan \n2. Fathur PakaPradana \n3. Ajiz Abdul Majid \n4. Fakhriza Sidhqi Wafiq Fauzi'),
          ),
          actions: <Widget>[
            // Tombol tutup dialog
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        dividerColor: Colors.transparent
      ),
      child: ExpansionTile(
        iconColor: Colors.white,
        collapsedIconColor: Colors.white,
        title: Text("More Menu", style: TextStyle(color: Colors.white),),
        leading: const Icon(
            Icons.more_horiz,
            color: Colors.white,
          ),
        children: [
          ListTile(
          leading: const Icon(
            Icons.question_mark,
            color: Colors.white,
          ),
          title: const Text(
            "Help",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.normal,
            ),
          ),
          onTap: () {
            _showPopupHelpDialog(context);
          },
        ),
          ListTile(
          leading: const Icon(
            Icons.info,
            color: Colors.white,
          ),
          title: const Text(
            "About",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.normal,
            ),
          ),
          onTap: () {
            _showPopupAboutDialog(context);
          },
        ),
        ]
      ),
    );
  }
}
