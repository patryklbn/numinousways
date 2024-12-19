import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerScreen extends StatefulWidget {
  final String audioUrl;
  final String title;

  AudioPlayerScreen({required this.audioUrl, required this.title});

  @override
  _AudioPlayerScreenState createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  late AudioPlayer _player;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      await _player.setUrl(widget.audioUrl);
      _duration = _player.duration ?? Duration.zero;

      // Listen for changes in player state
      _player.playerStateStream.listen((state) {
        setState(() {
          _isPlaying = state.playing;
        });
      });

      // Listen for position changes
      _player.positionStream.listen((pos) {
        setState(() {
          _position = pos;
        });
      });
    } catch (e) {
      print("Error loading audio: $e");
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Color(0xFFB4347F);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: accentColor,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD7CCC8), Color(0xFFBCAAA4)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Track Title
                Text(
                  widget.title,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),

                // Rounded rectangle image
                Expanded(
                  child: Center(
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 12,
                            color: Colors.black26,
                            offset: Offset(0, 6),
                          ),
                        ],
                        image: DecorationImage(
                          image: AssetImage('assets/images/myretreat/meditation.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 30),

                // Slider, Duration, and Playback Controls
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Slider
                    Slider(
                      activeColor: accentColor,
                      inactiveColor: Colors.grey[300],
                      min: 0,
                      max: _duration.inSeconds.toDouble(),
                      value: _position.inSeconds.toDouble().clamp(0, _duration.inSeconds.toDouble()),
                      onChanged: (value) async {
                        final newPos = Duration(seconds: value.toInt());
                        await _player.seek(newPos);
                      },
                    ),
                    // Duration Text
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(_position), style: TextStyle(color: Colors.black87)),
                        Text(_formatDuration(_duration), style: TextStyle(color: Colors.black87)),
                      ],
                    ),

                    SizedBox(height: 30),

                    // Playback Controls (Previous, Play/Pause, Next)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          iconSize: 40,
                          icon: Icon(Icons.skip_previous),
                          color: accentColor,
                          onPressed: () {
                            // Implement previous track logic if needed
                          },
                        ),
                        SizedBox(width: 30),
                        IconButton(
                          iconSize: 60,
                          icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
                          color: accentColor,
                          onPressed: () {
                            if (_isPlaying) {
                              _player.pause();
                            } else {
                              _player.play();
                            }
                          },
                        ),
                        SizedBox(width: 30),
                        IconButton(
                          iconSize: 40,
                          icon: Icon(Icons.skip_next),
                          color: accentColor,
                          onPressed: () {
                            // Implement next track logic if needed
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 30),
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
