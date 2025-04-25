import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class upload extends StatefulWidget {
  upload({super.key, this.userImage, this.addData});

  final userImage;
  final addData;

  @override
  State<upload> createState() => _uploadState();
}

class _uploadState extends State<upload> {
  var inputData = TextEditingController();
  String? downloadUrl;
  Future<void> uploadImage() async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageRef =
      FirebaseStorage.instance.ref().child('uploads/$fileName.jpg');
      UploadTask uploadTask = storageRef.putFile(widget.userImage);
      TaskSnapshot snapshot = await uploadTask;

      // 다운로드 URL 가져오기
      String url = await snapshot.ref.getDownloadURL();
      setState(() {
        downloadUrl = url;
        widget.addData(downloadUrl, inputData);
      });

      print('업로드 완료! 다운로드 URL: $downloadUrl');


    } catch (e) {
      print('업로드 실패: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('이미지 업로드 화면'),
        actions: [
          IconButton(
              onPressed: () async {
                await uploadImage();
                Navigator.pop(context);
              },
              icon: Icon(Icons.upload)),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.file(widget.userImage),
          Center(
            child: SizedBox(
              width: 350,
              child: TextField(
                  controller: inputData,
                  decoration: InputDecoration(
                    hintText: '내용',
                    hintStyle: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.w800),
                  )),
            ),
          )
        ],
      ),
    );
  }
}
