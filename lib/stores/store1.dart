import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final auth = FirebaseAuth.instance;
final firestore = FirebaseFirestore.instance;

class Store extends ChangeNotifier {
  var name = auth.currentUser?.email;
  var follower = 0;
  var friend = false;
  var profileImage = [];
  var liked=[];

  getLiked() async {
    var snapshot = await firestore
        .collection('liked')
        .where('user', isEqualTo:   auth.currentUser?.email ?? '')
        .get();
    liked = snapshot.docs.map((doc) => doc['postId'] as String).toList();
    print(liked);
    notifyListeners();
  }

  addLiked(docId) async{
    if (docId == null || auth.currentUser?.uid==null) {
      return;
    }

    var tempData = {
      "user": auth.currentUser?.email ?? "anonymous",
      "postId": docId,
    };

    var newDoc = await firestore.collection('liked').add({
      "user": auth.currentUser?.email ?? "anonymous",
      "postId": docId,
    });
    await getLiked();
  }

  deleteLiked(docId) async{
    var snapshot = await firestore
        .collection('liked')
        .where('user', isEqualTo:   auth.currentUser?.email ?? '')
        .where('postId', isEqualTo: docId)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }

    await getLiked();
  }

  void observeAuthChanges() {
    auth.authStateChanges().listen((User? user) async {
      if (user == null) {
        // 로그아웃됨
        print('사용자가 로그아웃했습니다.');

      } else {
        // 로그인됨
        print('사용자 로그인됨: ${user.email}');
        await getLiked();
      }
    });
  }

  getData(inputName) async{
    try{
      var userData;
      name = auth.currentUser?.email ?? ' ';

      if(inputName == name){
        var userDocs = await firestore.collection('user').where('name', isEqualTo: auth.currentUser?.email ?? '').get();
        userData = userDocs.docs.map((doc) => doc.data()).toList();
        follower = userData[0]['follower'];
        print('난 나야');
      }
      else{
        print('난 남이야');
        print(inputName);
        var userDocs = await firestore.collection('user').where('name', isEqualTo: inputName).get();
        userData = userDocs.docs.map((doc) => doc.data()).toList();
        follower = userData[0]['follower'];
        name = inputName;
      }

      //사진
      var result = await http
          .get(Uri.parse(userData[0]['pictures']));
      var result2 = jsonDecode(result.body);
      profileImage = result2;
      notifyListeners();

      // await firestore.collection('product').add({'name' : '내복', 'price' : 5000});
      // var result = await firestore.collection('product').where().get();

    }catch(e){
      print('데이터 get하는 과정에서 에러 발생');
      print(e);
    }
  }

  addFollower() {
    if (friend) {
      follower--;
    } else {
      follower++;
    }
    friend = !friend;
    notifyListeners();
  }
}
