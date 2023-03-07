
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

Widget cachedNetworkImage(String mediaUrl, BuildContext context) {
  return Container(
    height: MediaQuery.of(context).size.width *.9,
    child: CachedNetworkImage(
      imageUrl: mediaUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => const Padding(
        padding: EdgeInsets.all(20.0),
        child: CircularProgressIndicator(),
      ),
      errorWidget: (context, url , widget) => const Icon(Icons.error),
    ),
  );
}
