import 'package:flutter/material.dart';
import 'package:insta_app/pages/post_screen.dart';
import 'package:insta_app/widgets/custom_image.dart';
import 'package:insta_app/widgets/post.dart';

class PostTile extends StatelessWidget {
  final Post post;
  PostTile(this.post);

  showPost(BuildContext context){
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PostScreen(
              postId: post.postId,
              userId: post.ownerId,
            )));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ()=> showPost(context),
      child: cachedNetworkImage(post.mediaUrl,context),
    );
  }
}
