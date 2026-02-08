import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:record_platform_interface/record_platform_interface.dart';

const _fmediaBin = 'fmedia';
const _pipeProcName = 'record_linux';

class RecordLinux extends RecordPlatform {
  static void registerWith() {
    RecordPlatform.instance = RecordLinux();
  }

  RecordState _state = RecordState.stop;
  String? _path;
  StreamController<RecordState>? _stateStreamCtrl;

  @override
  Future<void> create(String recorderId) async {}

  @override
  Future<void> dispose(String recorderId) {
    _stateStreamCtrl?.close();
    return stop(recorderId);
  }

  @override
  Future<Amplitude> getAmplitude(String recorderId) {
    return Future.value(Amplitude(current: -160.0, max: -160.0));
  }

  @override
  Future<bool> hasPermission(String recorderId, {bool request = true}) {
    return Future.value(true);
  }

  @override
  Future<bool> isEncoderSupported(
      String recorderId, AudioEncoder encoder) async {
    switch (encoder) {
      case AudioEncoder.aacLc:
      case AudioEncoder.aacHe:
      case AudioEncoder.flac:
      case AudioEncoder.opus:
      case AudioEncoder.wav:
        return true;
      default:
        return false;
    }
  }

  @override
  Future<bool> isPaused(String recorderId) {
    return Future.value(_state == RecordState.pause);
  }

  @override
  Future<bool> isRecording(String recorderId) {
    return Future.value(_state == RecordState.record);
  }

  @override
  Future<void> pause(String recorderId) async {
    if (_state == RecordState.record) {
      await _callFMedia(['--globcmd=pause'], recorderId: recorderId);

      _updateState(RecordState.pause);
    }
  }

  @override
  Future<void> resume(String recorderId) async {
    if (_state == RecordState.pause) {
      await _callFMedia(['--globcmd=unpause'], recorderId: recorderId);

      _updateState(RecordState.record);
    }
  }

  @override
  Future<void> start(
    String recorderId,
    RecordConfig config, {
    required String path,
  }) async {
    await stop(recorderId);

    final file = File(path);
    if (file.existsSync()) await file.delete();

    final supported = await isEncoderSupported(recorderId, config.encoder);
    if (!supported) {
      throw Exception('${config.encoder} is not supported.');
    }

    String numChannels;
    if (config.numChannels == 6) {
      numChannels = '5.1';
    } else if (config.numChannels == 8) {
      numChannels = '7.1';
    } else if (config.numChannels == 1 || config.numChannels == 2) {
      numChannels = config.numChannels.toString();
    } else {
      throw Exception('${config.numChannels} config is not supported.');
    }

    await _callFMedia(
      [
        '--notui',
        '--background',
        '--record',
        '--out=$path',
        '--rate=${config.sampleRate}',
        '--channels=$numChannels',
        '--globcmd=listen',
        '--gain=6.0',
        if (config.device != null) '--dev-capture=${config.device!.id}',
        ..._getEncoderSettings(config.encoder, config.bitRate),
      ],
      onStarted: () {
        _path = path;
        _updateState(RecordState.record);
      },
      consumeOutput: false,
      recorderId: recorderId,
    );
  }

  @override
  Future<Stream<Uint8List>> startStream(
      String recorderId, RecordConfig config) async {
    throw UnimplementedError('startStream is not supported on Linux.');
  }

  @override
  Future<String?> stop(String recorderId) async {
    final path = _path;

    await _callFMedia(['--globcmd=stop'], recorderId: recorderId);
    await _callFMedia(['--globcmd=quit'], recorderId: recorderId);

    _updateState(RecordState.stop);

    return path;
  }

  @override
  Future<void> cancel(String recorderId) async {
    final path = await stop(recorderId);

    if (path != null) {
      final file = File(path);

      if (file.existsSync()) {
        file.deleteSync();
      }
    }
  }

  @override
  Future<List<InputDevice>> listInputDevices(String recorderId) async {
    final outStreamCtrl = StreamController<List<int>>();

    final out = <String>[];
    outStreamCtrl.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((chunk) {
      out.add(chunk);
    });

    try {
      await _callFMedia(['--list-dev'],
          recorderId: '', outStreamCtrl: outStreamCtrl);

      return _listInputDevices(recorderId, out);
    } finally {
      outStreamCtrl.close();
    }
  }

  @override
  Stream<RecordState> onStateChanged(String recorderId) {
    _stateStreamCtrl ??= StreamController(
      onCancel: () {
        _stateStreamCtrl?.close();
        _stateStreamCtrl = null;
      },
    );

    return _stateStreamCtrl!.stream;
  }

  List<String> _getEncoderSettings(AudioEncoder encoder, int bitRate) {
    switch (encoder) {
      case AudioEncoder.aacLc:
        return ['--aac-profile=LC', ..._getAacQuality(bitRate)];
      case AudioEncoder.aacHe:
        return ['--aac-profile=HEv2', ..._getAacQuality(bitRate)];
      case AudioEncoder.flac:
        return ['--flac-compression=6', '--format=int16'];
      case AudioEncoder.opus:
        final rate = (bitRate ~/ 1000).clamp(6, 510);
        return ['--opus-bitrate=$rate'];
      case AudioEncoder.wav:
        return ['--format=int16'];
      default:
        return [];
    }
  }

  List<String> _getAacQuality(int bitRate) {
    final rate = (bitRate ~/ 1000).clamp(16, 500);
    return ['--aac-quality=$rate'];
  }

  void _updateState(RecordState state) {
    _state = state;
    _stateStreamCtrl?.add(state);
  }

  Future<void> _callFMedia(
    List<String> args, {
    void Function()? onStarted,
    bool consumeOutput = true,
    String recorderId = '',
    StreamController<List<int>>? outStreamCtrl,
  }) async {
    if (!kIsWeb && !Platform.isLinux) return;

    final process = await Process.start(_fmediaBin, [
      '--dev=coreaudio',
      '--pidfile=$recorderId',
      '--pipe=$recorderId',
      ...args,
    ]);

    onStarted?.call();

    if (consumeOutput) {
      process.stderr.listen(outStreamCtrl?.add ?? (_) {});
      process.stdout.listen(outStreamCtrl?.add ?? (_) {});
    }
  }

  List<InputDevice> _listInputDevices(String recorderId, List<String> raw) {
    final devices = <InputDevice>[];

    for (final line in raw) {
      if (line.startsWith('#')) continue;
      final parts = line.split('\t');
      if (parts.length < 2) continue;

      devices.add(InputDevice(
        id: parts[0],
        label: parts[1],
      ));
    }

    return devices;
  }
}
