import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../stores/store1.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final auth = FirebaseAuth.instance;
final firestore = FirebaseFirestore.instance;

class Follower extends StatefulWidget {
  const Follower({super.key, this.isUser, this.name});
  final isUser;
  final name;

  @override
  State<Follower> createState() => _FollowerState();
}

class _FollowerState extends State<Follower> {

  getPicture() async{
    await context.read<Store>().getData(widget.name);
  }


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getPicture();
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey,
          ),
          Text('팔로워 ${context.watch<Store>().follower}명', style: TextStyle(fontSize: 15),),
          widget.isUser ? SizedBox.shrink() :
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              backgroundColor: Colors.blueAccent,
            ),
            onPressed: (){
              context.read<Store>().addFollower();
            },
            child: Text('팔로우', style: TextStyle(
              fontSize: 15,
              color: Colors.white,

            ),),
          ),

        ],
      ),
    );
  }
}
