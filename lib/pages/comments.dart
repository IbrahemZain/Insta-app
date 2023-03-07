import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:insta_app/pages/home.dart';
import 'package:insta_app/widgets/header.dart';
import 'package:insta_app/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;

final DateTime _timestamp = DateTime.now();
String postID;

class Comments extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String postMediaUrl;

  Comments({this.postId, this.ownerId, this.postMediaUrl});

  @override
  CommentsState createState() => CommentsState(
        postId: this.postId,
        ownerId: this.ownerId,
        postMediaUrl: this.postMediaUrl,
      );
}

class CommentsState extends State<Comments> {
  TextEditingController commentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool commentNotValid = true;

  final String postId;
  final String ownerId;
  final String postMediaUrl;

  @override
  void initState() {
    postID = postId;
    super.initState();
  }

  CommentsState({this.postId, this.ownerId, this.postMediaUrl});

  buildComments() {
    return StreamBuilder(
        stream: commentsRef
            .doc(postId)
            .collection('comments')
            .orderBy("timestamp", descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          List<Comment> comments = [];
          snapshot.data.docs.forEach((doc) {
            comments.add(Comment.fromDocument(doc));
          });
          return ListView(
            children: comments,
          );
        });
  }

  addComment() {
    commentsRef.doc(postId).collection("comments").add({
      "username": currentUser.username,
      "comment": commentController.text,
      "timestamp": _timestamp,
      "avatarUrl": currentUser.photoUrl,
      "userId": currentUser.id,
      'commentId': DateTime.now().toString(),
    });
    bool isNotPostOwner = currentUser.id != ownerId;
    if (isNotPostOwner) {
      activityFeedRef.doc(ownerId).collection('feedItems').add({
        "type": "comment",
        "commentData": commentController.text,
        "username": currentUser.username,
        "userId": currentUser.id,
        "userProfileImg": currentUser.photoUrl,
        "actionId": postId,
        "mediaUrl": postMediaUrl,
        "timestamp": timestamp,
      });
    }
    commentController.clear();
  }

  validComment() {
    if (!_formKey.currentState.validate()) {
      setState(() {
        commentNotValid = true;
      });
    } else {
      setState(() {
        commentNotValid = false;
      });
      addComment();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: "Comments"),
      body: Column(
        children: <Widget>[
          Expanded(child: buildComments()),
          const Divider(),
          ListTile(
            title: Form(
              key: _formKey,
              child: TextFormField(
                controller: commentController,
                validator: (val) {
                  if (val.isEmpty) {
                    return "Please enter comment";
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: "Write a comment...",
                ),
              ),
            ),
            trailing: TextButton(
              onPressed: validComment,
              style: ElevatedButton.styleFrom(),
              // borderSide: BorderSide.none,
              child: const Text("Post"),
            ),
          ),
        ],
      ),
    );
  }
}

class Comment extends StatelessWidget {
  final String username;
  final String userId;
  final String avatarUrl;
  final String comment;
  final String commentId;
  final Timestamp timestamp;

  Comment({
    this.username,
    this.userId,
    this.avatarUrl,
    this.comment,
    this.timestamp,
    this.commentId,
  });

  factory Comment.fromDocument(DocumentSnapshot doc) {
    return Comment(
      username: doc['username'],
      userId: doc['userId'],
      comment: doc['comment'],
      timestamp: doc['timestamp'],
      avatarUrl: doc['avatarUrl'],
      commentId: doc['commentId'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          title: Text(comment),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(avatarUrl),
          ),
          subtitle: Text(timeago.format(timestamp.toDate())),
        ),
        const Divider(),
      ],
    );
  }
}