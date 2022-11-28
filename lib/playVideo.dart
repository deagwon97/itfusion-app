// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

/// An example of using the plugin, controlling lifecycle and playback of the
/// video.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

Future<Map<String, dynamic>> getJson(String videoName) async {
  var url = Uri.https(
      'itfusion.deagwon.com', 'movie/caption/json', {'name': videoName});
  var response = await http.get(url);
  var jsonResponse = await json.decode(utf8.decode(response.bodyBytes))
      as Map<String, dynamic>;
  return jsonResponse;
}

Future<Map<String, dynamic>> getVideoLink(String videoName) async {
  var url =
      Uri.https('itfusion.deagwon.com', 'movie/file', {'name': videoName});
  var response = await http.get(url);
  var jsonResponse = await json.decode(utf8.decode(response.bodyBytes))
      as Map<String, dynamic>;
  return jsonResponse;
}

class PlayVideo extends StatefulWidget {
  const PlayVideo({Key? key, required this.videoName}) : super(key: key);
  final String videoName;

  @override
  PlayVideoState createState() => PlayVideoState();
}

class PlayVideoState extends State<PlayVideo> {
  late VideoPlayerController _controller;

  // Future getPathFuture = Future.delayed(const Duration(seconds: 1000));
  Future futureGetJson = Future.delayed(const Duration(seconds: 1000));
  late Map<String, dynamic> subtitleJsonRes;

  bool isFillBlank = false;
  String selectedCaption = "";
  String meaning = "";
  String? blankCaption;
  int syncsIdx = 0;

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft, // 가로 왼쪽 방향
    ]);
    super.initState();

    getVideoLink(widget.videoName).then((response) {
      print('response $response');
      _controller = VideoPlayerController.network(response['url'])
        ..initialize().then((_) {
          futureGetJson = getJson(widget.videoName);
          futureGetJson.then((res) {
            subtitleJsonRes = res;

            _controller.addListener(() {
              setState(() {
                if (_controller.value.isPlaying) {
                  setState(() {
                    if (res!["subtitles"][0]["body"]["syncs"][syncsIdx]
                            ["text"] ==
                        "&nbsp;") {
                      syncsIdx++;
                      return;
                    }
                    if (_controller.value.position.inMilliseconds >=
                        (res!["subtitles"][0]["body"]["syncs"][syncsIdx]
                            ["startTime"] as int)) {
                      selectedCaption = res!["subtitles"][0]["body"]["syncs"]
                          [syncsIdx]["text"] as String;
                      blankCaption = "";
                      meaning = "";
                      var extras = res!["subtitles"][0]["body"]["syncs"]
                          [syncsIdx]["extras"];
                      for (var idx = 0; idx < extras.length; idx++) {
                        if (extras[idx]["properties"]["level"] == 1) {
                          blankCaption = ("$blankCaption (___)");
                          meaning =
                              ("$meaning ${extras[idx]["properties"]["original"]}-${extras[idx]["properties"]["meaning"]}/");
                        } else {
                          blankCaption =
                              ("$blankCaption ${extras[idx]["properties"]["variant"]! as String}");
                        }
                      }
                    }
                    if (_controller.value.position.inMilliseconds >=
                        (res!["subtitles"][0]["body"]["syncs"][syncsIdx]
                            ["endTime"] as int)) {
                      _controller.pause();
                      syncsIdx++;
                    }
                  });
                }
              });
            });
            _controller.setLooping(true);
            _controller.initialize().then((_) => setState(() {}));
          });
        });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp, // 가로 왼쪽 방향
    ]);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp, // 가로 왼쪽 방향
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Container(
            height: MediaQuery.of(context).size.height,
            color: Colors.black,
            alignment: Alignment.center,
            child: FutureBuilder(
              future: Future.wait([futureGetJson]),
              builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                if (snapshot.hasData) {
                  return AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: <Widget>[
                        VideoPlayer(_controller),
                        _ControlsOverlay(controller: _controller),
                        ClosedCaption(
                            text: isFillBlank ? selectedCaption : blankCaption,
                            textStyle: const TextStyle(
                                fontSize: 15, color: Colors.white)),
                        VideoProgressIndicator(_controller,
                            allowScrubbing: true),
                        Container(
                            alignment: Alignment.center,
                            child: Column(children: [
                              const Padding(
                                  padding: EdgeInsets.symmetric(
                                vertical: 20,
                                // horizontal: 16,
                              )),
                              Text(
                                meaning,
                                style: const TextStyle(
                                    backgroundColor:
                                        Color.fromRGBO(0, 0, 0, 0.5),
                                    fontSize: 16,
                                    color: Colors.white),
                              ),
                              const Padding(
                                  padding: EdgeInsets.symmetric(
                                vertical: 40,
                                // horizontal: 16,
                              )),
                              !_controller.value.isPlaying
                                  ? Container(
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          OutlinedButton(
                                              onPressed: () {
                                                if (syncsIdx > 0) {
                                                  syncsIdx = syncsIdx - 1;
                                                }
                                                _controller.seekTo(Duration(
                                                    milliseconds: subtitleJsonRes[
                                                                    "subtitles"][0]
                                                                ["body"]
                                                            ["syncs"][syncsIdx]
                                                        ["startTime"] as int));
                                              },
                                              style: OutlinedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.black, //<-- SEE HERE
                                              ),
                                              child: const Text("prev",
                                                  style: TextStyle(
                                                      fontSize: 30,
                                                      color: Colors.white))),
                                          const Padding(
                                              padding: EdgeInsets.symmetric(
                                            horizontal: 16,
                                          )),
                                          OutlinedButton(
                                              onPressed: () {
                                                isFillBlank =
                                                    isFillBlank ? false : true;
                                                _controller.seekTo(Duration(
                                                    milliseconds:
                                                        subtitleJsonRes["subtitles"]
                                                                            [0]
                                                                        ["body"]
                                                                    ["syncs"]
                                                                [syncsIdx - 1][
                                                            "endTime"] as int));
                                              },
                                              style: OutlinedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.black, //<-- SEE HERE
                                              ),
                                              child: const Text("fill blank",
                                                  style: TextStyle(
                                                      fontSize: 30,
                                                      color: Colors.white))),
                                          const Padding(
                                              padding: EdgeInsets.symmetric(
                                            horizontal: 16,
                                          )),
                                          OutlinedButton(
                                              onPressed: () {
                                                if (_controller
                                                    .value.isPlaying) {
                                                  syncsIdx++;
                                                }
                                                _controller.seekTo(Duration(
                                                    milliseconds: 1 +
                                                        subtitleJsonRes["subtitles"]
                                                                            [0]
                                                                        ["body"]
                                                                    ["syncs"]
                                                                [syncsIdx][
                                                            "startTime"] as int));
                                                _controller.play();
                                              },
                                              style: OutlinedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.black, //<-- SEE HERE
                                              ),
                                              child: const Text("next",
                                                  style: TextStyle(
                                                      fontSize: 30,
                                                      color: Colors.white)))
                                        ],
                                      ))
                                  : Container()
                            ]))
                      ],
                    ),
                  );
                } else {
                  return const Text('loading');
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlsOverlay extends StatelessWidget {
  const _ControlsOverlay({Key? key, required this.controller})
      : super(key: key);

  static const List<Duration> _exampleCaptionOffsets = <Duration>[
    Duration(seconds: -10),
    Duration(seconds: -3),
    Duration(seconds: -1, milliseconds: -500),
    Duration(milliseconds: -250),
    Duration.zero,
    Duration(milliseconds: 250),
    Duration(seconds: 1, milliseconds: 500),
    Duration(seconds: 3),
    Duration(seconds: 10),
  ];
  static const List<double> _examplePlaybackRates = <double>[
    0.25,
    0.5,
    1.0,
    1.5,
    2.0,
    3.0,
    5.0,
    10.0,
  ];

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        // AnimatedSwitcher(
        //   duration: const Duration(milliseconds: 50),
        //   reverseDuration: const Duration(milliseconds: 200),
        //   child: controller.value.isPlaying
        //       ? const SizedBox.shrink()
        //       : Container(
        //           color: Colors.black26,
        //           child: const Center(
        //             child: Icon(
        //               Icons.play_arrow,
        //               color: Colors.white,
        //               size: 100.0,
        //               semanticLabel: 'Play',
        //             ),
        //           ),
        //         ),
        // ),
        // GestureDetector(
        //   onTap: () {
        //     controller.value.isPlaying ? controller.pause() : controller.play();
        //   },
        // ),
        Align(
          alignment: Alignment.topLeft,
          child: PopupMenuButton<Duration>(
            initialValue: controller.value.captionOffset,
            tooltip: 'Caption Offset',
            onSelected: (Duration delay) {
              controller.setCaptionOffset(delay);
            },
            itemBuilder: (BuildContext context) {
              return <PopupMenuItem<Duration>>[
                for (final Duration offsetDuration in _exampleCaptionOffsets)
                  PopupMenuItem<Duration>(
                    value: offsetDuration,
                    child: Text('${offsetDuration.inMilliseconds}ms'),
                  )
              ];
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                // Using less vertical padding as the text is also longer
                // horizontally, so it feels like it would need more spacing
                // horizontally (matching the aspect ratio of the video).
                vertical: 12,
                horizontal: 16,
              ),
              child: Text('${controller.value.captionOffset.inMilliseconds}ms'),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topRight,
          child: PopupMenuButton<double>(
            initialValue: controller.value.playbackSpeed,
            tooltip: 'Playback speed',
            onSelected: (double speed) {
              controller.setPlaybackSpeed(speed);
            },
            itemBuilder: (BuildContext context) {
              return <PopupMenuItem<double>>[
                for (final double speed in _examplePlaybackRates)
                  PopupMenuItem<double>(
                    value: speed,
                    child: Text('${speed}x'),
                  )
              ];
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                // Using less vertical padding as the text is also longer
                // horizontally, so it feels like it would need more spacing
                // horizontally (matching the aspect ratio of the video).
                vertical: 12,
                horizontal: 16,
              ),
              child: Text('${controller.value.playbackSpeed}x'),
            ),
          ),
        ),
      ],
    );
  }
}
