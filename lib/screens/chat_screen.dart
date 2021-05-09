import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';

class ChatScreen extends StatefulWidget {
  static const String id = "chat_screen";
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  User loggedInUser;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  String messageText;
  TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
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
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('messages')
                      .orderBy('timeStamp')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return CircularProgressIndicator(
                        backgroundColor: Colors.lightBlueAccent,
                      );
                    }
                    final messages = snapshot.data.docs.reversed;
                    List<Widget> messageBubbles = [];
                    for (var message in messages) {
                      String text = message.get('text');
                      String sender = message.get('sender');
                      messageBubbles.add(MessageBubble(
                        isMe: loggedInUser.email == sender,
                        sender: sender,
                        message: text,
                      ));
                    }
                    return ListView(
                      reverse: true,
                      children: messageBubbles,
                    );
                  }),
            ),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: controller,
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      controller.clear();
                      _firestore.collection("messages").add({
                        'text': messageText,
                        'sender': loggedInUser.email,
                        'timeStamp': FieldValue.serverTimestamp()
                      });
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

  void getCurrentUser() {
    final user = _auth.currentUser;
    if (user != null) {
      print(user);
      loggedInUser = user;
    }
  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble({this.isMe, this.sender, this.message});
  final bool isMe;
  final String message;
  final String sender;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Text(
            sender,
            style: TextStyle(color: Colors.black, fontSize: 12.0),
          ),
          Visibility(
            visible: true,
            child: Material(
              borderRadius: isMe
                  ? BorderRadius.only(
                      bottomLeft: Radius.circular(30.0),
                      bottomRight: Radius.circular(30.0),
                      topRight: Radius.circular(30.0),
                    )
                  : BorderRadius.only(
                      bottomLeft: Radius.circular(30.0),
                      bottomRight: Radius.circular(30.0),
                      topLeft: Radius.circular(30.0),
                    ),
              elevation: 5.0,
              color: isMe ? Colors.white : Colors.lightBlueAccent,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                child: Text(
                  message,
                  style: TextStyle(
                    color: isMe ? Colors.black : Colors.white,
                    fontSize: 15.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
