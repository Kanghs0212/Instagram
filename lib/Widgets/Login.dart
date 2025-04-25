
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

final auth = FirebaseAuth.instance;


class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<bool> login(String email, String password) async{
    try {
      await auth.signInWithEmailAndPassword(
          email: email,
          password: password,
      );
      // 로그인 후 currentUser가 null이 아닌지 확인
      if (auth.currentUser != null) {
        return true;
      } else {
        print("로그인은 성공했지만 currentUser가 null임");
        return false;
      }
    } catch (e) {
      print("로그인 에러 발생: $e");
      return false;
    }

  }

  showLoginFailMessage(){
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('로그인 실패'),
          content: Text('아이디 혹은 비밀번호가 다릅니다.'),
        );
      },
    );

    // 2초 후에 팝업 자동 닫기
    Future.delayed(Duration(milliseconds: 1500), () {
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("로그인")),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "환영합니다!",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: "이메일",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "비밀번호",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    backgroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    String email = emailController.text;
                    String password = passwordController.text;
                    var flag = await login(email,password);

                    if(flag){
                      Navigator.pop(context);
                    }
                    else{
                      showLoginFailMessage();
                    }
                  },
                  child: Text("로그인" , style: TextStyle(color: Colors.black), ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    backgroundColor: Colors.white, // 버튼 배경 흰색
                  ),
                  onPressed: () {
                    print("회원가입 페이지 이동");
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Text(
                      "회원가입",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
