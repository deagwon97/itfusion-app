import 'dart:io';

import 'package:flutter/material.dart';
import 'package:itfusion/playVideo.dart';
import 'package:path_provider/path_provider.dart';

class VideoList extends StatefulWidget {
  const VideoList({Key? key}) : super(key: key);
  @override
  State<VideoList> createState() => VideoListState();
}

class VideoListState extends State<VideoList> {
  String directory = "";
  List<FileSystemEntity> fileList = [];
  List<String> videoNameList = [];
  Future getPathFuture = Future.delayed(const Duration(seconds: 1000));

  @override
  void initState() {
    super.initState();
    getPathFuture = getApplicationDocumentsDirectory();
    getPathFuture.then((value) {
      setState(() {
        fileList = Directory(value.path).listSync();
        for (var idx = 0; idx < fileList.length; idx++) {
          String fileName = fileList[idx].toString().replaceAll("'", "");
          if (fileName.split("/").last.split(".").last == "mp4") {
            videoNameList.add(fileName.split("/").last.split(".").first);
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: getPathFuture,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: videoNameList.length,
              itemBuilder: (context, index) {
                final videoName = videoNameList[index];
                return ListTile(
                  title: Text(
                    videoName,
                  ),
                  subtitle: Text(
                    videoName,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Scaffold(
                                body: PlayVideo(videoName: videoName))));
                  },
                );
              },
            );
          } else {
            return Text("loading");
          }
        });
  }
}
