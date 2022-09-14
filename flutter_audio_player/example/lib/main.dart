import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_audio_player/flutter_audio_player.dart';
// import 'package:flutter_audio_player_platform_interface/flutter_audio_player_platform_interface.dart';
import 'package:flutter_audio_player_platform_interface/audio_data_source.dart';

void main() {
  // DartVLC.initialize();
  runApp(MaterialApp(
    home: HomePage(),
  ));
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (BuildContext context) {
                return MyApp();
              },
            ));
          },
          child: const Text('player'),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    AudioPlayer().dispose().then((value) async {
      await AudioPlayer().init();
      AudioPlayer()
          .open(AudioDataSource.network(
              'https://aiteacher-teaching-resource-1251316161.file.myqcloud.com/private/edudata/product/oxford/v2/followReadMp3/917e23f1abc732398dbc740a0a068a91/0027_11.mp3'))
          .then((value) {
        AudioPlayer().current?.listen((event) {
          print('==== current ${event.toString()}');
        });
        AudioPlayer().playlistFinished?.listen((event) {
          print('==== playlistFinished ${event.toString()}');
        });

        AudioPlayer().currentPosition?.listen((event) {
          print('==== currentPosition ${AudioPlayer().currentPosition?.value.toString()}');
        });
        AudioPlayer().isPlaying?.listen((event) {
          print('==== isPlaying ${AudioPlayer().isPlaying?.value.toString()}');
        });
        AudioPlayer().onReadyToPlay?.listen((event) {
          print('==== onReadyToPlay ${event.toString()}');
        });
        AudioPlayer().volume?.listen((event) {
          print('==== volume ${event.toString()}');
        });

        AudioPlayer().playerState?.listen((event) {
          print('==== playerState ${event.toString()}');
        });

        AudioPlayer().playSpeed?.listen((event) {
          print('==== playSpeed ${event.toString()}');
        });
      });
    });
  }

  @override
  void dispose() {
    AudioPlayer().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () async {
                  await AudioPlayer().open(AudioDataSource.network(
                      'https://aiteacher-teaching-resource-1251316161.file.myqcloud.com/private/edudata/product/oxford/v2/followReadMp3/917e23f1abc732398dbc740a0a068a91/0027_11.mp3'));
                },
                child: const Text('open'),
              ),
              TextButton(
                onPressed: () async {
                  await AudioPlayer().play();
                },
                child: const Text('play'),
              ),
              TextButton(
                onPressed: () async {
                  await AudioPlayer().pause();
                },
                child: const Text('pause'),
              ),
              TextButton(
                onPressed: () async {
                  await AudioPlayer().seek(const Duration(seconds: 5));
                },
                child: const Text('seek'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                },
                child: const Text('return'),
              ),
              // ProgressIndicator(
              //   color: Colors.yellow,
              //   value: AudioPlayer().currentPosition,
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
