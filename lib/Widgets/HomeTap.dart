import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:instagram/stores/store1.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final firestore = FirebaseFirestore.instance;
final auth = FirebaseAuth.instance;

class HomeTap extends StatefulWidget {
  HomeTap({super.key, this.data, this.lastDoc, this.docsId});

  var data;
  var lastDoc;
  var docsId;

  @override
  State<HomeTap> createState() => _HomeTapState();
}

class _HomeTapState extends State<HomeTap> {
  var scroll = ScrollController();
  var flag = false;
  var alreadySeeMessage = false;
  var isError = false;

  showLoginMessage(){
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('로그인 필요'),
          content: Text('로그인을 후 이용해 주세요.'),
        );
      },
    );

    // 2초 후에 팝업 자동 닫기
    Future.delayed(Duration(milliseconds: 1500), () {
      Navigator.of(context).pop();
    });
  }

  getData() async {
    try{
      var nextResult = await firestore
          .collection('post')
          .startAfterDocument(widget.lastDoc.docs.last)
          .limit(3)
          .get();

      setState(() {
        widget.lastDoc = nextResult;
        var tmpData =  nextResult.docs.map((doc) => doc.data()).toList();
        var tmpIds = nextResult.docs.map((doc) => doc.id).toList();

        widget.data.addAll(tmpData);
        widget.docsId.addAll(tmpIds);
      });
      isError = false;

    }catch(e){
      print(e);
      isError = true;
    }
  }

  pressLikeButton(String docId) async {
    var store = Provider.of<Store>(context, listen: false);
    var flag = store.liked.contains(docId);

    if(flag){
      await store.deleteLiked(docId);
    }else{
      await store.addLiked(docId);
    }

  }


  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    scroll.addListener(() {
      if (scroll.position.pixels == scroll.position.maxScrollExtent && !flag) {
        if(auth.currentUser?.uid!=null){
          getData();
          flag = true;
          alreadySeeMessage = false;
          if(!isError){
            Future.delayed(Duration(seconds: 1), () {
              flag = false;
            });
          }
        }
        else if(auth.currentUser?.uid==null && !alreadySeeMessage){
          showLoginMessage();
          alreadySeeMessage=true;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isNotEmpty) {
      return ListView.builder(
          itemCount: widget.data.length,
          controller: scroll,
          itemBuilder: (context, i) {
            return Container(
              margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  widget.data[i]['image'].runtimeType == String
                      ? Image.network(widget.data[i]['image'])  // URL이면 네트워크 이미지
                      : Image.file(widget.data[i]['image']),
                  Container(
                    margin: EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            await pressLikeButton(widget.docsId[i]);
                            setState(() {});
                          },
                          child: Icon(
                            context.watch<Store>().liked.contains(widget.docsId[i])
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 24, // 필요에 따라 크기 지정
                          ),
                        ),
                        Text('좋아요 ${widget.data[i]['likes']}'),
                        Row(
                          children: [
                            GestureDetector(
                              child: Text(widget.data[i]['user']),
                              onTap: () {
                                if (auth.currentUser?.uid != null) {
                                  var name = auth.currentUser?.email ?? '';
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (c, a1, a2) => Profile(isUser: name==widget.data[i]['user'], name: widget.data[i]['user']),
                                      transitionsBuilder: (c, a1, a2, child) => FadeTransition(
                                        opacity: a1,
                                        child: child,
                                      ),
                                    ),
                                  );
                                } else {
                                  // 로그인되지 않았을 때 팝업 띄우기
                                  showLoginMessage();
                                }
                              },
                            ),
                            Text('  '),
                            Text(widget.data[i]['content']),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            );
          });
    } else {
      return CircularProgressIndicator();
    }
  }
}
