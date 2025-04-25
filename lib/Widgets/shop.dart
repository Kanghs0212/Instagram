import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
final auth = FirebaseAuth.instance;
final firestore = FirebaseFirestore.instance;

class Shop extends StatefulWidget {
  const Shop({super.key});

  @override
  State<Shop> createState() => _ShopState();
}

class _ShopState extends State<Shop> {

  Future<List<Map<String, dynamic>>> getData() async{
    try{
      var result = await firestore.collection('product').get();

      // await firestore.collection('product').add({'name' : '내복', 'price' : 5000});
      // var result = await firestore.collection('product').where().get();

      if(result.docs.isNotEmpty){
        List<Map<String, dynamic>> dataList =
        result.docs.map((doc) => doc.data()).toList();

        return dataList;
      }
      else{
        print('공백 데이터');
        return [];
      }
    }catch(e){
      print('데이터 get하는 과정에서 에러 발생');
      return [];
    }
  }

  // register() async{
  //   try {
  //     var result = await auth.createUserWithEmailAndPassword(
  //       email: "kim@test.com",
  //       password: "123456",
  //     );
  //     print(result.user);
  //   } catch (e) {
  //     print(e);
  //   }
  // }


  logout() async{
    await auth.signOut();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getData();
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: getData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('상품이 없습니다.', style: TextStyle(fontSize: 18)));
          }
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var product = snapshot.data![index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 3,
                child: ListTile(
                  leading: Icon(Icons.shopping_bag, color: Colors.blueAccent),
                  title: Text(product['name'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${product['price']}원', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                      Text('판매자: ${product['who']}', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
