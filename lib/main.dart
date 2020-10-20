import 'dart:typed_data';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:audio_manager/audio_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

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
  _SongWidgetState createState() => _SongWidgetState(songList: this.songList);
}

class _SongWidgetState extends State<SongWidget> {
  final audioPlayer = AssetsAudioPlayer();
  _SongWidgetState({this.songList});

  final List<SongInfo> songList;

  int currentIndex = 0;
  var songs = [];
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
        ],
      ),
      body: IndexedStack(
        index: currentIndex,
        children: [
          ListView.builder(
            shrinkWrap: true,
            itemCount: songList?.length ?? 0,
            itemBuilder: (_, idx) {
              SongInfo song = songList[idx];
              songs.add(song.filePath);
              return Card(
                child: ListTile(
                  title: Text('${song.title}'),
                  leading: FutureBuilder(
                    future: FlutterAudioQuery().getArtwork(
                        type: ResourceType.ARTIST, id: song.artistId),
                    builder: (context, snapshot) {
                      if (snapshot.hasData)
                        return CircleAvatar(
                          child: Image.memory(snapshot.data),
                          backgroundColor: Colors.white10,
                        );
                      return CircleAvatar(
                        child: Image.asset('icons/icon.png'),
                        backgroundColor: Colors.white10,
                      );
                    },
                  ),
                  onTap: () {
                    audioPlayer.stop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Play(
                          image: song.artistId,
                          name: song.title,
                          songpath: song.filePath,
                          audioPlayer: audioPlayer,
                          songList: songList,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          FutureBuilder<List<AlbumInfo>>(
            future: FlutterAudioQuery().getAlbums(),
            builder: (_, snap) {
              return ListView.builder(
                shrinkWrap: true,
                itemCount: snap.data?.length ?? 0,
                itemBuilder: (_, idx) {
                  AlbumInfo albumInfo = snap.data[idx];
                  return ListTile(
                    leading: FutureBuilder(
                      future: FlutterAudioQuery().getArtwork(
                          type: ResourceType.ALBUM, id: albumInfo.id),
                      builder: (_, snap) {
                        if (snap.hasData)
                          return CircleAvatar(
                            child: Image.memory(snap.data),
                            backgroundColor: Colors.white10,
                          );
                        return CircleAvatar(
                          child: Image.asset('icons/icon.png'),
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
            future: FlutterAudioQuery().getArtists(),
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
        ],
      ),
    );
  }
}

class Play extends StatefulWidget {
  Play({this.name, this.image, this.songpath, this.audioPlayer, this.songList});

  final image;
  final name;
  final songpath;
  List songList;
  final AssetsAudioPlayer audioPlayer;

  @override
  _PlayState createState() => _PlayState();
}

class _PlayState extends State<Play> {
  bool isplay = false;
  int path = 0;
  List<AudioInfo> songs = [];
  var duration;
  var icon = Icon(
    Icons.pause_circle_filled,
    size: 50.0,
  );

  AudioManager audioManager;

  @override
  void initState() {
    super.initState();
    audioManager = AudioManager.instance;
    audioManager.audioList = songs;
    isplay = true;

    play();
  }

  play() {
    setState(() {
      //     audioPlayer.updateCurrentAudioNotification(
      //       metas: Metas(title: name),
      //     );
      //     audioPlayer.open(
      //       Audio.file(songpath),
      //       showNotification: true,
      //       notificationSettings: NotificationSettings(
      //           customNextAction: (player) => next(),
      //           customPrevAction: (player) => previous(),
      //           seekBarEnabled: false),
      //     );
      audioManager.start('file://${widget.songpath}', widget.name);
    });
  }

  void next() {
    setState(() {
      //     path++;
      //     play();
      //     print(songList.length);
      // audioManager.next();
    });
  }

  // void previous() {
  //   setState(() {
  //     if (path > 0) {
  //       path--;
  //       play();
  //     }
  //     print(audioPlayer.current.value.audio.duration);
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: FutureBuilder<Uint8List>(
                future: FlutterAudioQuery()
                    .getArtwork(type: ResourceType.ARTIST, id: widget.image),
                builder: (context, snapshot) {
                  if (snapshot.hasData)
                    return CircleAvatar(
                      child: Image.memory(snapshot.data),
                      radius: 100.0,
                      backgroundColor: Colors.white10,
                    );
                  return CircleAvatar(
                    child: Image.asset('icons/icon.png'),
                    backgroundColor: Colors.white10,
                  );
                },
              ),
            ),
            SizedBox(
              height: 30.0,
            ),
            Center(
              child: Text(
                '${widget.name}',
                style: TextStyle(
                  fontSize: 20.0,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: IconButton(
                      color: Colors.amber,
                      icon: Icon(
                        Icons.arrow_left,
                        size: 50.0,
                      ),
                      onPressed: () {
                        // previous();
                      }),
                ),
                Center(
                  child: IconButton(
                      color: Colors.amber,
                      icon: icon,
                      onPressed: () {
                        widget.audioPlayer.playOrPause();
                        setState(() {
                          isplay = !isplay;

                          isplay == true
                              ? icon = Icon(
                                  Icons.pause_circle_filled,
                                  size: 50.0,
                                )
                              : icon = Icon(
                                  Icons.play_circle_fill_outlined,
                                  size: 50.0,
                                );
                        });
                      }),
                ),
                Center(
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        // next();
                      });
                    },
                    color: Colors.amber,
                    icon: Icon(
                      Icons.arrow_right,
                      size: 50.0,
                    ),
                  ),
                ),
                Center(
                  child: IconButton(
                    icon: Icon(
                      Icons.stop,
                      color: Colors.red,
                      size: 50.0,
                    ),
                    onPressed: () {
                      widget.audioPlayer.stop();
                      isplay = false;
                      setState(() {
                        icon = Icon(
                          Icons.play_circle_fill_outlined,
                          size: 50.0,
                        );
                      });
                    },
                  ),
                )
              ],
            ),
            SizedBox(
              height: 30.0,
            ),
          ],
        ),
      ),
    );
  }
}
