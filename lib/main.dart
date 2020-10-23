import 'dart:async';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'player/PositionSeekWidget.dart';

void main() {
  runApp(
    MaterialApp(home: Player()),
  );
}

class Player extends StatefulWidget {
  @override
  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  FlutterAudioQuery audioQuery;
  @override
  void initState() {
    audioQuery = FlutterAudioQuery();
    getPermission();
    super.initState();
  }

  void getPermission() async {
    var status = await Permission.storage.status;
    if (status.isUndetermined) Permission.storage.request();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        // appBar: AppBar(
        //   actions: [
        //     IconButton(
        //       onPressed: () => Navigator.push(
        //           context,
        //           MaterialPageRoute(
        //             builder: (context) => Play(),
        //           )),
        //       icon: Icon(Icons.play_circle_fill_outlined),
        //     ),
        //   ],
        // ),
        body: FutureBuilder(
          future: audioQuery.getSongs(),
          builder: (context, snapshot) {
            List<SongInfo> songInfo = snapshot.data;
            if (snapshot.hasData)
              return SongWidget(
                songList: songInfo,
              );
            return Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}

class SongWidget extends StatefulWidget {
  SongWidget({this.songList, Key key}) : super(key: key);

  final List<SongInfo> songList;

  @override
  _SongWidgetState createState() => _SongWidgetState();
}

class _SongWidgetState extends State<SongWidget> {
  final audioPlayer = AssetsAudioPlayer();

  FlutterAudioQuery audioQuery = FlutterAudioQuery();

  int currentIndex = 0;
  int id;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (int index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
              icon: Icon(
                Icons.playlist_play,
                size: 30,
              ),
              label: 'Songs'),
          BottomNavigationBarItem(
              icon: Icon(
                Icons.album,
                size: 30,
              ),
              label: 'Albums'),
          BottomNavigationBarItem(
              icon: Icon(
                Icons.account_circle_outlined,
                size: 30,
              ),
              label: 'Artists'),
          // BottomNavigationBarItem(
          //     icon: Icon(
          //       Icons.play_arrow,
          //       size: 30,
          //     ),
          //     label: 'Play'),
        ],
      ),
      body: IndexedStack(
        index: currentIndex,
        children: [
          ListView.builder(
            itemCount: widget.songList.length ?? 0,
            itemBuilder: (_, idx) {
              return Card(
                child: ListTile(
                  title: Text('${widget.songList[idx].title}'),
                  leading: FutureBuilder(
                    future: audioQuery.getArtwork(
                        type: ResourceType.SONG, id: widget.songList[idx].id),
                    builder: (context, snap) {
                      if (snap.data == null) return CircularProgressIndicator();
                      if (snap.data.isEmpty)
                        return CircleAvatar(
                          child: Image.asset('icons/icon.png'),
                          backgroundColor: Colors.white10,
                        );
                      return CircleAvatar(
                        child: Image.memory(snap.data),
                        backgroundColor: Colors.white10,
                      );
                    },
                  ),
                  onTap: () {
                    audioPlayer.stop();
                    print(widget.songList[idx].toString());
                    setState(() {
                      id = idx;
                      audioPlayer
                          .open(Audio.file(widget.songList[id].filePath));
                    });

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Play(
                          audioPlayer: audioPlayer,
                          songList: widget.songList,
                          id: idx,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          FutureBuilder<List<AlbumInfo>>(
            future: audioQuery.getAlbums(),
            builder: (_, snap) {
              return ListView.builder(
                itemCount: snap.data?.length ?? 0,
                itemBuilder: (_, idx) {
                  AlbumInfo albumInfo = snap.data[idx];
                  return ListTile(
                    leading: FutureBuilder(
                      future: FlutterAudioQuery().getArtwork(
                          type: ResourceType.ALBUM, id: snap.data[idx].id),
                      builder: (_, snap) {
                        if (snap.data == null)
                          return CircularProgressIndicator();
                        if (snap.data.isEmpty)
                          return CircleAvatar(
                            child: Image.asset('icons/icon.png'),
                            backgroundColor: Colors.white10,
                          );
                        return CircleAvatar(
                          child: Image.memory(snap.data),
                          backgroundColor: Colors.white10,
                        );
                      },
                    ),
                    title: Text('Title: ${albumInfo.title}'),
                    subtitle: Text('Year: ${albumInfo.firstYear}'),
                    onTap: () {},
                  );
                },
              );
            },
          ),
          FutureBuilder<List<ArtistInfo>>(
            future: audioQuery.getArtists(),
            builder: (_, snap) {
              return ListView.builder(
                shrinkWrap: true,
                itemCount: snap.data?.length ?? 0,
                itemBuilder: (_, idx) {
                  ArtistInfo artistInfo = snap.data[idx];
                  return ListTile(
                      title: Text('${artistInfo.name}'),
                      subtitle: Row(
                        children: [
                          Text('No of Albums: ${artistInfo.numberOfAlbums}'),
                          SizedBox(width: 20.0),
                          Text('No of Tracks: ${artistInfo.numberOfTracks}'),
                        ],
                      ));
                },
              );
            },
          ),
          // Play(
          //   audioPlayer: audioPlayer,
          //   id: id ?? 0,
          //   songList: widget.songList ?? null,
          // ),
        ],
      ),
    );
  }
}

class Play extends StatefulWidget {
  Play({this.audioPlayer, this.songList, this.id});

  int id;
  final List songList;
  final audioPlayer;

  @override
  _PlayState createState() => _PlayState();
}

class _PlayState extends State<Play> {
  @override
  void initState() {
    super.initState();
    // p
    print('============init===========');
  }

  @override
  void dispose() {
    super.dispose();
    print('========disposed=========');
  }

  play() {
    widget.audioPlayer.open(
      Audio.file(widget.songList[widget.id].filePath),
    );
  }

  void next() {
    setState(() {
      if (widget.id <= widget.songList.length) widget.id++;
      Future.delayed(Duration(milliseconds: 100)).then((value) => play());
    });
  }

  void previous() {
    setState(() {
      if (widget.id > 0) {
        widget.id--;
        Future.delayed(Duration(milliseconds: 100)).then((value) => play());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: WillPopScope(
        onWillPop: () {
          Navigator.pop(context);
          return null;
        },
        child: Scaffold(
          // appBar: AppBar(),
          body: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: 500,
                  width: 500,
                  child: FutureBuilder(
                    future: FlutterAudioQuery().getArtwork(
                        type: ResourceType.SONG,
                        id: widget.songList[widget.id].id),
                    builder: (_, snap) {
                      if (snap.data == null)
                        return Container(
                            child: CircularProgressIndicator(),
                            height: 200,
                            width: 200);
                      if (snap.data.isEmpty)
                        return Container(
                            child: Image.asset('icons/icon.png'),
                            height: 200,
                            width: 200);
                      return Container(
                          child: Image.memory(snap.data, scale: 1.5),
                          height: 200,
                          width: 200);
                    },
                  ),
                ),
                SizedBox(height: 20.0),
                Center(
                  child: Text(
                      widget.id == null
                          ? ''
                          : '${widget.songList[widget.id].title}',
                      style: TextStyle(fontSize: 25.0),
                      textAlign: TextAlign.center),
                ),
                SizedBox(
                  height: 10.0,
                ),
                Center(
                  child: Text(
                      widget.id == null
                          ? ''
                          : '${widget.songList[widget.id].artist}',
                      style: TextStyle(fontSize: 15.0),
                      textAlign: TextAlign.center),
                ),
                SizedBox(
                  height: 10.0,
                ),
                Center(
                  child: Text(
                      widget.id == null
                          ? ''
                          : '${widget.songList[widget.id].album}',
                      style: TextStyle(fontSize: 15.0),
                      textAlign: TextAlign.center),
                ),
                SizedBox(height: 20.0),
                PlayerBuilder.realtimePlayingInfos(
                    player: widget.audioPlayer,
                    builder: (_, d) {
                      return PositionSeekWidget(
                          currentPosition: d.currentPosition == null
                              ? Duration(seconds: 0)
                              : d.currentPosition,
                          duration: d.duration == null
                              ? Duration(seconds: 0)
                              : d.duration,
                          seekTo: (d) {
                            widget.audioPlayer.seek(d ?? Duration(seconds: 0));
                          });
                    }),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                        color: Colors.blue,
                        icon: Icon(
                          Icons.arrow_left,
                          size: 50.0,
                        ),
                        onPressed: () {
                          previous();
                        }),
                    SizedBox(
                      width: 25,
                    ),
                    PlayerBuilder.isPlaying(
                        player: widget.audioPlayer,
                        builder: (_, snap) {
                          return IconButton(
                              color: Colors.blue,
                              icon: snap == true
                                  ? Icon(
                                      Icons.pause_circle_filled,
                                      size: 50.0,
                                    )
                                  : Icon(
                                      Icons.play_circle_fill_outlined,
                                      size: 50.0,
                                    ),
                              onPressed: () {
                                widget.audioPlayer.playOrPause();

                                snap = !snap;
                              });
                        }),
                    SizedBox(
                      width: 25,
                    ),
                    IconButton(
                      onPressed: () {
                        next();
                      },
                      color: Colors.blue,
                      icon: Icon(
                        Icons.arrow_right,
                        size: 50.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
