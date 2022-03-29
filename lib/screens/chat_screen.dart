import 'package:chat_app/screens/login_screen.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firestore = FirebaseFirestore.instance;
late User loggedInUser;

class ChatScreen extends StatefulWidget {
  static const String id = 'chat_screen';

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;

  late String messageText;
  late final messageTextController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    try {
      final newuser = await _auth.currentUser;
      if (newuser != null) {
        loggedInUser = newuser;
        print('Currently logged in User: ${loggedInUser.email}');
      }
    } catch (e) {
      print(e);
    }
  }

  // void getMessages()async{
  //   final messages =await _firestore.collection('messages').get();
  //  for( var message in messages.docs) {
  //    print(message.data());
  //  }
  // }

  void messagesStream() async {
    await for (var snapshot in _firestore.collection('messages').snapshots()) {
      for (var message in snapshot.docs) {
        print(message.data);
      }
    }
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
                // messagesStream();
                // // getMessages();
                // Implement logout functionality
                _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Viper'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ChatStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  // Text('${loggedInUser.email}'),
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        //Do something with the user input.
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      messageTextController.clear();
                      //Implement send functionality.
                      _firestore.collection('messages').add(
                          {'text': messageText, 'sender': loggedInUser.email});
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

class MessageBubble extends StatelessWidget {
  const MessageBubble(
      {required this.text, required this.sender, required this.isMe});

  final String text;
  final String sender;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          '$sender',
          style: TextStyle(fontSize: 12, color: Colors.black26),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Material(
            color: isMe ? Colors.white70 : Colors.purple.shade400,
            elevation: 4,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$text',
                    style: isMe?TextStyle(fontSize: 12, color: Colors.black):TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  Text('${DateTime.now().toLocal()}',style: isMe?TextStyle(fontSize: 8, color: Colors.black):TextStyle(fontSize: 8, color: Colors.white))
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ChatStream extends StatelessWidget {
  const ChatStream({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('messages').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                backgroundColor: Colors.lightGreen,
              ),
            );
          }
          //reversed is used to to arrange the messages in right order, also added reverse as true in listview
          final messages = snapshot.data?.docs.reversed;

          List<MessageBubble> messageBubbbles = [];
          for (var message in messages!) {
            final messageText = message['text'];
            final messageSender = message['sender'];
            final currentUser = loggedInUser.email;

            final messageBubble = MessageBubble(
                text: messageText,
                sender: messageSender,
                isMe: currentUser == messageSender);
            messageBubbbles.add(messageBubble);
          }
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: ListView(
                reverse: true,
                children: messageBubbbles,
              ),
            ),
          );
        });
  }
}
