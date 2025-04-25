import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import './style.dart' as style;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';


// 다른 위젯들 import
import 'stores/store1.dart';
import 'Widgets/Follower.dart';
import 'Widgets/upload.dart';
import 'Widgets/HomeTap.dart';
import 'notification.dart';
import 'Widgets/shop.dart';
import 'Widgets/Login.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

final auth = FirebaseAuth.instance;
final firestore = FirebaseFirestore.instance;
final ImagePicker _picker = ImagePicker();

void main() async{

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (c) => Store()),
  ], child: MaterialApp(theme: style.theme, home: MyApp())));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var tap = 0;
  var lastDoc;
  var data = [];
  var docsId = [];
  var userImage;

  getData() async {
    try{
      lastDoc = await firestore.collection('post').limit(3).get();
      context.read<Store>().getLiked();

      setState(() {
        data = lastDoc.docs.map((doc) => doc.data()).toList();
        docsId = lastDoc.docs.map((doc) => doc.id).toList();
      });
    }catch(e){
      print(e);
      print('데이터 불러오기 실패');
    }

  }

  addData(image, inputData) async {
    if (inputData.text == '' || auth.currentUser?.uid==null) {
      return;
    }

    var tempData = {
      "id": data.length,
      "image": image, // 여기서 image는 파일 경로 또는 File 객체
      "likes": 30,
      "date": "?",
      "content": inputData.text,
      "user": "test"
    };

    var newDoc = await firestore.collection('post').add({
      "id": data.length,
      "image": image,         // 이 값은 String (예: Firebase Storage URL) 이어야 함!
      "likes": 30,
      "date": DateTime.now().toIso8601String(), // 또는 원하는 날짜 형식으로 설정
      "content": inputData.text,
      "user": auth.currentUser?.email ?? "anonymous" // 실제 로그인 유저 이메일 사용
    });

    setState(() {
      data.add(tempData);
      docsId.add(newDoc.id);
    });
  }



  @override
  void initState() {
    super.initState();
    initNotification(context);
    Future.microtask(() {
      getData(); // 여기선 context 사용 가능
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Instagram'),
        actions: [
          auth.currentUser?.uid != null
              ?
          Container(
            margin: EdgeInsets.fromLTRB(0, 0, 10, 0),
            child: IconButton(
              onPressed: () async {
                var picker = ImagePicker();
                var image = await picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  setState(() {
                    userImage = File(image.path);
                  });
                }

                Navigator.push(context, MaterialPageRoute(builder: (c) {
                  return upload(userImage: userImage, addData: addData);
                }));
              },
              icon: Icon(Icons.add_box_outlined),
            ),
          ) : SizedBox.shrink(), // 사용자가 로그인하지 않았을 경우 actions를 null로 설정
          auth.currentUser?.uid != null
              ?
              IconButton(onPressed: () async{
                bool? result = await Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (c, a1, a2) => Profile(isUser: true, name: auth.currentUser!.email ),
                    transitionsBuilder: (c, a1, a2, child) => FadeTransition(
                      opacity: a1,
                      child: child,
                    ),
                  ),
                );
                if (result == true) {
                  setState(() {}); // 로그아웃 후 UI 업데이트
                }

              }, icon: Icon(Icons.person))
              : IconButton(onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (c){return LoginPage();}));
                setState(() {

                });
          }, icon: Icon(Icons.person_outline))
        ]


      ),
      body: [HomeTap(data: data, lastDoc: lastDoc, docsId: docsId), Shop()][tap],
      bottomNavigationBar: BottomNavigationBar(
        iconSize: 30,
        showUnselectedLabels: false,
        showSelectedLabels: false,
        currentIndex: tap,
        onTap: (i) {
          setState(() {
            tap = i;
          });
        },
        items: [
          BottomNavigationBarItem(
              label: '홈',
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home)),
          BottomNavigationBarItem(
              label: '샵',
              icon: Icon(Icons.shopping_bag_outlined),
              activeIcon: Icon(Icons.shopping_bag))
        ],
      ),
    );
  }
}

class Profile extends StatefulWidget {
  const Profile({super.key, this.isUser, this.name});
  final isUser;
  final name;

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {

  logout() async{
    await auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.name),
          actions: [
            widget.isUser == true
                ?
            IconButton(onPressed: () async {
              await auth.signOut();
              Navigator.pop(context, true); // 'true'를 반환하여 로그아웃 감지
            }, icon: Icon(Icons.logout))
                : SizedBox.shrink()
          ],

        ),
        body: CustomScrollView(

          slivers: [
            SliverToBoxAdapter(
              child: Container(
                margin: EdgeInsets.fromLTRB(0, 10, 0, 10), // 여기서 margin을 설정
                child: Follower(isUser: widget.isUser, name: widget.name),
              ),
            ),
            SliverGrid(
              delegate: SliverChildBuilderDelegate(
                    (c, i) =>
                    Container(
                        child:
                        Image.network(context
                            .watch<Store>()
                            .profileImage[i])),
                childCount: context
                    .watch<Store>()
                    .profileImage
                    .length,
              ),
              gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
            )
          ],
        ));
  }
}