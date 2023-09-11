import 'package:flutter/material.dart';
import 'package:thunderbird/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firestore = FirebaseFirestore.instance;
User? loggedInUser;
List docID = [];

class ChatScreen extends StatefulWidget {
  static const String id = 'chat_screen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;
  String? messageText;
  final controller = TextEditingController();
  bool isMe = false;


  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }


  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser;

      if (user != null) {
        loggedInUser = user;
        print(loggedInUser?.email);
      }
    } catch (e) {
      print(e);
    }
  }







  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.logout),
              onPressed: () {
                _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessagesStream(),


            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: controller,
                      onChanged: (value) {
                        messageText=value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  TextButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStatePropertyAll(Colors.lightBlueAccent),
                    ),
                    onPressed: () {

                      if(messageText!=null && loggedInUser!=null){
                        final Timestamp timestamp = Timestamp.now();
                        _firestore.collection('messages').add({
                          'text':messageText,
                          'sender':loggedInUser?.email,
                          'time':timestamp,
                        });
                      }
                      messageText = null;
                      controller.clear();

                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class MessagesStream extends StatelessWidget {


  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('messages').orderBy('time',descending: true).snapshots(),
      builder: (context,snapshot){
        if(!snapshot.hasData){
          return Center(
            child: CircularProgressIndicator(
              color: Colors.lightBlueAccent,
            ),
          );
        }

        final messages = snapshot.data?.docs;
        List<MesssageBubble> messageBubbles =[];
        for(var message in messages!){


          final messageText = message['text'];
          final senderName = message['sender'];
          final currentUser = loggedInUser?.email;

          final messageBubble =MesssageBubble(
              text: messageText,
              sender: senderName,
               isMe:currentUser==senderName,

          );

          messageBubbles.add(messageBubble);
        }

        return Expanded(
          child: ListView(
            reverse: true,
            padding: EdgeInsets.symmetric(horizontal: 10,vertical: 20),
            children: messageBubbles,
          ),
        );


      },
    );
  }
}



class MesssageBubble extends StatelessWidget {
  MesssageBubble({ required this.text, required this.sender, required this.isMe});
  final String text;
  final String sender;
  final bool isMe;
  @override
  Widget build(BuildContext context) {
    return  Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: isMe? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(sender,style: TextStyle(
            color: Colors.black54,
            fontSize: 12,
          ),),
          SizedBox(
            height: 2,
          ),
          Material(
            borderRadius: isMe? BorderRadius.only(topLeft: Radius.circular(30.0) ,
                bottomLeft: Radius.circular(30.0),
                bottomRight: Radius.circular(30.0),):
            BorderRadius.only(topRight: Radius.circular(30.0) ,
              bottomLeft: Radius.circular(30.0),
              bottomRight: Radius.circular(30.0),),
            elevation: 5,
            color: isMe? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10,horizontal: 20),
              child: Text('$text',
                style: TextStyle(
                  color: isMe? Colors.white : Colors.black,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

