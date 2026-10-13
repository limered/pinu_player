import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

const videoId = 'cPGTw1rNjrU';

class Episode {
  const Episode(this.label, this.start, this.end);
  final String label;
  final double start;
  final double? end;
}

const episodes = [
  Episode('Episode 1 (0–311 s)', 0, 311),
  Episode('Episode 2 (311–611 s)', 311, 611),
  Episode('Episode 3 (612 s–end)', 612, null),
];

void main() => runApp(const SpikeApp());

class SpikeApp extends StatelessWidget {
  const SpikeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Pingu spike',
        theme: ThemeData(colorSchemeSeed: Colors.blue),
        home: const HomePage(),
      );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool nocookie = true;
  bool controls = false;
  bool setOrigin = false;
  bool ownStop = true;
  bool wakelock = true;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Pingu embed spike — $videoId')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final e in episodes)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PlayerPage(
                        episode: e,
                        nocookie: nocookie,
                        controls: controls,
                        setOrigin: setOrigin,
                        ownStop: ownStop,
                        wakelock: wakelock,
                      ),
                    ),
                  ),
                  child: Text(e.label, style: const TextStyle(fontSize: 20)),
                ),
              ),
            const Divider(),
            SwitchListTile(
              title: const Text('privacyEnhancedMode (youtube-nocookie.com)'),
              value: nocookie,
              onChanged: (v) => setState(() => nocookie = v),
            ),
            SwitchListTile(
              title: const Text('Show YouTube controls'),
              value: controls,
              onChanged: (v) => setState(() => controls = v),
            ),
            SwitchListTile(
              title: const Text('Set origin = https://www.youtube.com'),
              subtitle: const Text('Try this if error 152/153 appears'),
              value: setOrigin,
              onChanged: (v) => setState(() => setOrigin = v),
            ),
            SwitchListTile(
              title: const Text('Own stop at end bound'),
              subtitle: const Text(
                  'Off = let YouTube handle endSeconds, to see what it shows afterwards'),
              value: ownStop,
              onChanged: (v) => setState(() => ownStop = v),
            ),
            SwitchListTile(
              title: const Text('Wakelock during playback'),
              subtitle: const Text('Off = control run for the standby test'),
              value: wakelock,
              onChanged: (v) => setState(() => wakelock = v),
            ),
          ],
        ),
      );
}

class PlayerPage extends StatefulWidget {
  const PlayerPage({
    super.key,
    required this.episode,
    required this.nocookie,
    required this.controls,
    required this.setOrigin,
    required this.ownStop,
    required this.wakelock,
  });

  final Episode episode;
  final bool nocookie;
  final bool controls;
  final bool setOrigin;
  final bool ownStop;
  final bool wakelock;

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late final YoutubePlayerController controller;
  final log = <String>[];
  final watch = Stopwatch()..start();
  StreamSubscription<YoutubePlayerValue>? valueSub;
  StreamSubscription<YoutubeVideoState>? stateSub;
  PlayerState state = PlayerState.unknown;
  YoutubeError error = YoutubeError.none;
  Duration position = Duration.zero;
  bool wakelockOn = false;
  bool done = false;
  bool firstPositionLogged = false;

  void add(String msg) {
    final t = (watch.elapsedMilliseconds / 1000).toStringAsFixed(1);
    setState(() => log.insert(0, '[$t s] $msg'));
    debugPrint('SPIKE [$t s] $msg');
  }

  @override
  void initState() {
    super.initState();
    controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: true,
      startSeconds: widget.episode.start,
      endSeconds: widget.episode.end,
      params: YoutubePlayerParams(
        showControls: widget.controls,
        showFullscreenButton: false,
        strictRelatedVideos: true,
        privacyEnhancedMode: widget.nocookie,
        origin: widget.setOrigin ? 'https://www.youtube.com' : null,
        interfaceLanguage: 'de',
        enableCaption: false,
      ),
    );
    add('start ${widget.episode.label} nocookie=${widget.nocookie} '
        'controls=${widget.controls} origin=${widget.setOrigin} ownStop=${widget.ownStop}');

    valueSub = controller.stream.listen((v) {
      if (v.playerState != state) {
        state = v.playerState;
        add('state → ${state.name}');
        _syncWakelock();
        if (state == PlayerState.ended) _finish('PlayerState.ended');
      }
      if (v.error != error) {
        error = v.error;
        add('ERROR → ${error.name} (code ${error.code})');
      }
    });

    stateSub = controller.videoStateStream.listen((s) {
      setState(() => position = s.position);
      final secs = s.position.inMilliseconds / 1000;
      if (!firstPositionLogged && secs > 0) {
        firstPositionLogged = true;
        add('first position ${secs.toStringAsFixed(2)} s '
            '(requested start ${widget.episode.start})');
      }
      final end = widget.episode.end;
      if (widget.ownStop && end != null && secs >= end - 0.3) {
        _finish('own stop at ${secs.toStringAsFixed(2)} s');
      }
    });
  }

  Future<void> _syncWakelock() async {
    final want = widget.wakelock && state == PlayerState.playing;
    if (want == wakelockOn) return;
    await WakelockPlus.toggle(enable: want);
    final actual = await WakelockPlus.enabled;
    setState(() => wakelockOn = actual);
    add('wakelock → $actual');
  }

  Future<void> _finish(String reason) async {
    if (done) return;
    done = true;
    add('FINISH: $reason, position ${(position.inMilliseconds / 1000).toStringAsFixed(2)} s');
    if (!widget.ownStop) return; // observe what YouTube shows after its own stop
    await controller.pauseVideo();
    await WakelockPlus.disable();
    if (!mounted) return;
    setState(() => wakelockOn = false);
  }

  @override
  void dispose() {
    valueSub?.cancel();
    stateSub?.cancel();
    WakelockPlus.disable();
    controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final secs = (position.inMilliseconds / 1000).toStringAsFixed(1);
    return Scaffold(
      appBar: AppBar(title: Text(widget.episode.label)),
      body: Column(
        children: [
          Stack(
            children: [
              YoutubePlayer(controller: controller),
              if (done && widget.ownStop)
                Positioned.fill(
                  child: Container(
                    color: Colors.lightBlue.shade100,
                    alignment: Alignment.center,
                    child: const Text('Fertig! 🐧', style: TextStyle(fontSize: 40)),
                  ),
                ),
            ],
          ),
          Container(
            width: double.infinity,
            color: Colors.black87,
            padding: const EdgeInsets.all(8),
            child: Text(
              'pos $secs s | state ${state.name} | error ${error.name} | wakelock $wakelockOn',
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                for (final l in log)
                  Text(l, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
