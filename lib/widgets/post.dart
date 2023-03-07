import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:insta_app/models/user.dart';
import 'package:insta_app/pages/activity_feed.dart';
import 'package:insta_app/pages/comments.dart';
import 'package:insta_app/pages/home.dart';
import 'package:insta_app/pages/profile.dart';
import 'package:insta_app/widgets/custom_image.dart';
import 'package:insta_app/widgets/progress.dart';

// import 'package:animator/animator.dart';
import 'package:animations/animations.dart';

class Post extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  final dynamic likes;

  Post({
    this.postId,
    this.ownerId,
    this.username,
    this.location,
    this.description,
    this.mediaUrl,
    this.likes,
  });

  factory Post.fromDocument(DocumentSnapshot doc) {
    return Post(
      postId: doc['postId'],
      ownerId: doc['ownerId'],
      username: doc['username'],
      location: doc['location'],
      description: doc['description'],
      mediaUrl: doc['mediaUrl'],
      likes: doc['likes'],
    );
  }

  int getLikeCount(likes) {
    // if no likes, return 0
    if (likes == null) {
      return 0;
    }
    int count = 0;
    // if the key is explicitly set to true, add a like
    likes.values.forEach((val) {
      if (val == true) {
        count += 1;
      }
    });
    return count;
  }

  @override
  _PostState createState() => _PostState(
        postId: this.postId,
        ownerId: this.ownerId,
        username: this.username,
        location: this.location,
        description: this.description,
        mediaUrl: this.mediaUrl,
        likes: this.likes,
        likeCount: getLikeCount(this.likes),
      );
}

class _PostState extends State<Post> with SingleTickerProviderStateMixin {
  final String currentUserId = currentUser.id;
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  int likeCount;
  Map likes;
  bool isLiked;
  bool showHeart = false;
  AnimationController controller;
  Animation sizeAnimation;

  _PostState({
    this.postId,
    this.ownerId,
    this.username,
    this.location,
    this.description,
    this.mediaUrl,
    this.likes,
    this.likeCount,
  });

  @override
  void initState() {
    super.initState();
    getCurrentStateOfLikedPost();
    controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    sizeAnimation = Tween<double>(begin: .8, end: .4).animate(controller);
  }

  buildPostHeader() {
    return FutureBuilder(
      future: usersRef.doc(ownerId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        User user = User.fromDocument(snapshot.data);
        bool isPostOwner = currentUserId == ownerId;
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(user.photoUrl),
            backgroundColor: Colors.grey,
          ),
          title: GestureDetector(
            onTap: () => showProfile(context,profileId: user.id),
            child: Text(
              user.username,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          subtitle: Text(location),
          trailing: isPostOwner ? IconButton(
            onPressed: () => handleDeletePost(context),
            icon: const Icon(Icons.more_vert),
          ) : const Text(''),
        );
      },
    );
  }

  handleDeletePost(BuildContext context){
    return showDialog(context: context, builder: (context){
      return SimpleDialog(
        title: const Text("Remove this post?"),
        children: [
          SimpleDialogOption(
            onPressed: (){
              Navigator.pop(context);
              deletePost();
            },
            child: const Text("Delete",style: TextStyle(color: Colors.red)),
          ),
          SimpleDialogOption(
            onPressed: (){
              Navigator.pop(context);
            },
            child: const Text("Cancel",),
          ),
        ],
      );
    });
  }

  deletePost() async {
    // delete post itself
    postsRef
        .doc(ownerId)
        .collection('userPosts')
        .doc(postId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Home()));
        // Navigator.pop(context);
      }
    });
    // delete uploaded image for thep ost
    storageRef.child("post_$postId.jpg").delete();
    // then delete all activity feed notifications
    QuerySnapshot activityFeedSnapshot = await activityFeedRef
        .doc(ownerId)
        .collection("feedItems")
        .where('postId', isEqualTo: postId)
        .get();
    activityFeedSnapshot.docs.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    // then delete all comments
    QuerySnapshot commentsSnapshot = await commentsRef
        .doc(postId)
        .collection('comments')
        .get();
    commentsSnapshot.docs.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  handleLikePost() {
    bool _isLiked = likes[currentUserId] == true;
    if (_isLiked) {
      postsRef
          .doc(ownerId)
          .collection('userPosts')
          .doc(postId)
          .update({'likes.$currentUserId': false});
      removeLikeFromActivityFeed();
      setState(() {
        likeCount--;
        isLiked = false;
        likes[currentUserId] = false;
      });
    } else if (_isLiked == false) {
      postsRef
          .doc(ownerId)
          .collection('userPosts')
          .doc(postId)
          .update({"likes.$currentUserId": true});
      addLikeToActivityFeed();
      setState(() {
        likeCount++;
        isLiked = true;
        likes[currentUserId] = true;
        showHeart = true;
      });
      Timer(const Duration(milliseconds: 500), () {
        setState(() {
          showHeart = false;
        });
      });
    }
  }

  addLikeToActivityFeed() {
    // add notification for only like made by other user not the owner post

    bool isNotPostOwner = currentUserId != ownerId;
    if (isNotPostOwner) {
      activityFeedRef.doc(ownerId).collection('feedItems').doc(postId).set({
        "type": "like",
        "username": currentUser.username,
        "userId": currentUser.id,
        "userProfileImg": currentUser.photoUrl,
        "actionId": postId, //
        "mediaUrl": mediaUrl,
        "timestamp": timestamp,
        "commentData": " ",
      });
    }
  }

  removeLikeFromActivityFeed() {
    bool isNotPostOwner = currentUserId != ownerId;
    if (isNotPostOwner) {
      activityFeedRef
          .doc(ownerId)
          .collection('feedItems')
          .doc(postId)
          .get()
          .then((doc) {
        if (doc.exists) {
          doc.reference.delete();
        }
      });
    }
  }

  buildPostImage() {
    return GestureDetector(
      onDoubleTap: handleLikePost,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          cachedNetworkImage(mediaUrl, context),
          showHeart
              ? Opacity(
                  opacity: sizeAnimation.value,
                  child: const Center(
                    child: Icon(
                      Icons.favorite,
                      size: 90,
                      color: Colors.red,
                    ),
                  ),
                )
              : const Text(""),

          // showHeart ? Animator(
          //   duration: const Duration(milliseconds: 300),
          //   tween: Tween(begin: .8, end: .4),
          //   curve: Curves.elasticOut,
          //   cycles: 0,
          //   builder: (context, anim, child) {
          //     return ScaleTransition(
          //       scale: anim.value,
          //       child: const Icon(
          //         Icons.favorite,
          //         size: 90,
          //         color: Colors.red,
          //       ),
          //     );
          //   },
          // ): const Text(""),
          // showHeart
          //     ? const Icon(
          //         Icons.favorite,
          //         size: 90,
          //         color: Colors.red,
          //       )
          //     : const Text(""),
        ],
      ),
    );
  }

  buildPostFooter() {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const Padding(padding: EdgeInsets.only(top: 40.0, left: 20.0)),
            GestureDetector(
              onTap: handleLikePost,
              child: Icon(
                isLiked == true ? Icons.favorite : Icons.favorite_border,
                size: 28.0,
                color: Colors.pink,
              ),
            ),
            const Padding(padding: EdgeInsets.only(right: 20.0)),
            GestureDetector(
              onTap: () => showComments(
                context,
                postId: postId,
                ownerId: ownerId,
                mediaUrl: mediaUrl,
              ),
              child: Icon(
                Icons.chat,
                size: 28.0,
                color: Colors.blue[900],
              ),
            ),
          ],
        ),
        Row(
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(left: 20.0),
              child: Text(
                "$likeCount likes",
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(left: 20.0),
              child: Text(
                "$username ",
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(child: Text(description))
          ],
        ),
      ],
    );
  }

  getCurrentStateOfLikedPost() async {
    isLiked = (await postsRef
        .doc(ownerId)
        .collection('userPosts')
        .doc(postId)
        .get('likes.$currentUserId' as GetOptions)) as bool;
  }

  @override
  Widget build(BuildContext context) {
    isLiked = (likes[currentUserId] == true);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        buildPostHeader(),
        buildPostImage(),
        buildPostFooter()
      ],
    );
  }
}

showComments(BuildContext context,
    {String postId, String ownerId, String mediaUrl}) {
  Navigator.push(context, MaterialPageRoute(
    builder: (context) {
      return Comments(
        postId: postId,
        ownerId: ownerId,
        postMediaUrl: mediaUrl,
      );
    },
  ));
}
