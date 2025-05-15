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
  var following=[];
  var docRef;
  var lastDoc;

  // 포스트 데이터
  var data = [];
  var docsId = [];

  addPicture(String? loc) async {
    if(loc == null){
      return;
    }

    var querySnapshot = await firestore
        .collection('pictures')
        .where('user', isEqualTo: auth.currentUser?.email)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      var newDoc = await firestore.collection('pictures').add({
        "user": auth.currentUser?.email ?? "anonymous",
        "loc": [loc],
      });

    }else{
      var postRef = querySnapshot.docs.first.reference;
      print(postRef);
      await firestore.runTransaction((transaction) async {
        var snapshot = await transaction.get(postRef);
        if (!snapshot.exists) return;

        List<dynamic> locList = snapshot.data()?['loc'] ?? [];
        locList.add(loc);


        transaction.update(postRef, {'loc': locList});
      });
    }
    notifyListeners();

  }

  getFollowing() async {
    var snapshot = await firestore
        .collection('following')
        .where('follower', isEqualTo:   auth.currentUser?.email ?? '')
        .get();
    following = snapshot.docs.map((doc) => doc['target'] as String).toList();
    print(following);
    notifyListeners();
  }

  addFollowing() async{
    if ( auth.currentUser?.uid == name) {
      return;
    }

    var newDoc = await firestore.collection('following').add({
      "follower": auth.currentUser?.email ?? "anonymous",
      "target": name,
    });
    await getFollowing();
  }

  deleteFollowing() async{
    var snapshot = await firestore
        .collection('following')
        .where('follower', isEqualTo:   auth.currentUser?.email ?? '')
        .where('target', isEqualTo: name)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }

    await getFollowing();
  }

  getLiked() async {
    var snapshot = await firestore
        .collection('liked')
        .where('user', isEqualTo:   auth.currentUser?.email ?? '')
        .get();
    liked = snapshot.docs.map((doc) => doc['postId'] as String).toList();
    notifyListeners();
  }

  addLiked(docId) async{
    if (docId == null || auth.currentUser?.uid==null) {
      return;
    }

    var newDoc = await firestore.collection('liked').add({
      "user": auth.currentUser?.email ?? "anonymous",
      "postId": docId,
    });

    // 포스트의 좋아요 개수 증가
    int currentLikes=0;
    var postRef = firestore.collection('post').doc(docId);

    await firestore.runTransaction((transaction) async {
      var snapshot = await transaction.get(postRef);
      if (!snapshot.exists) return;

      currentLikes = snapshot.data()?['likes'] ?? 0;
      currentLikes++;
      transaction.update(postRef, {
        'likes': currentLikes ,
      });
    });

    int index = docsId.indexOf(docId); // docId의 인덱스 찾기
    if (index != -1) {
      data[index]['likes'] = currentLikes; // 해당 인덱스의 likes 값 갱신
      notifyListeners(); // UI 업데이트
    }

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

    // 포스트 좋아요 개수 감소
    int currentLikes=0;
    var postRef = firestore.collection('post').doc(docId);

    await firestore.runTransaction((transaction) async {
      var snapshot = await transaction.get(postRef);
      if (!snapshot.exists) return;

      currentLikes = snapshot.data()?['likes'] ?? 0;
      currentLikes--;

      transaction.update(postRef, {
        'likes': currentLikes,
      });
    });

    int index = docsId.indexOf(docId); // docId의 인덱스 찾기
    if (index != -1) {
      data[index]['likes'] = currentLikes; // 해당 인덱스의 likes 값 갱신
      notifyListeners(); // UI 업데이트
    }

    await getLiked();
  }

  void observeAuthChanges() {
    auth.authStateChanges().listen((User? user) async {
      if (user == null) {
        // 로그아웃됨
        print('사용자가 로그아웃했습니다.');
        liked.clear();
        following.clear();
        notifyListeners();
      } else {
        // 로그인됨
        print('사용자 로그인됨: ${user.email}');
        await getLiked();
        await getFollowing();
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
      }
      else{
        var userDocs = await firestore.collection('user').where('name', isEqualTo: inputName).get();
        userData = userDocs.docs.map((doc) => doc.data()).toList();
        docRef = userDocs.docs.first.reference;
        if(following.contains(inputName)){
          friend=true;
        }else {
          friend=false;
        }
        follower = userData[0]['follower'];
        name = inputName;
      }

      var userPics = await firestore.collection('pictures').where('user', isEqualTo: inputName).get();

      if (userPics.docs.isNotEmpty) {
        List<dynamic>? locList = userPics.docs[0].data()['loc'];
        print(locList);
        profileImage = locList!;
      }

      notifyListeners();


    }catch(e){
      print('데이터 get하는 과정에서 에러 발생');
      print(e);
    }
  }

  addFollower() async {
    if (friend) {
      follower--;
      deleteFollowing();
    } else {
      follower++;
      addFollowing();
    }

    await docRef.update({
      'follower':  follower,
    });

    friend = !friend;
    notifyListeners();
  }
}
