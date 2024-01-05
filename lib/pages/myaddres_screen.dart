import 'package:flutter/material.dart';
import 'package:prak_mobpro/component/my_button.dart';

class MyAddressScreen extends StatelessWidget {
  final String myaddress;
  const MyAddressScreen({super.key, required this.myaddress});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.deepOrange,
        title: Text(
          'Your Address',
          style: TextStyle(color: Colors.deepOrange),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: ListView(
          children: [
            Container(
              height: MediaQuery.of(context).size.height / 3,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(width: 2, color: Colors.grey),
              ),
              // Mau pake maps beneran agak ribet keknya, kapan2 weh
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/fakemap.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Divider(
                thickness: 2,
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height / 6,
                maxHeight: double.infinity,
              ),
              child: Card(
                elevation: 3,
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                          colors: [Colors.orange, Colors.deepOrange])),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(
                              Icons.maps_home_work,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              'Address',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                        Divider(
                          color: Colors.white,
                        ),
                        Text(
                          myaddress,
                          style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey.shade100),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20,),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 100),
              child: MyButton(onTap: (){
                Navigator.pop(context);
              }, text: "Back")
            )
          ],
        ),
      ),
    );
  }
}
