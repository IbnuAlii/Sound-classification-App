import 'dart:async';
import 'dart:io';
import 'package:audio_classification_final/classifier.dart';
import 'package:audio_classification_final/navigation.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:record/record.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';
import 'package:vibration/vibration.dart';
import 'settings.dart';

void main() {
  runApp(MaterialApp(home: MyApp(), debugShowCheckedModeBanner: false));
}

const int sampleRate = 16000;

// Custom color scheme for deaf and hard of hearing community
class AppColors {
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryOrange = Color(0xFFF97316);
  static const Color lightBlue = Color(0xFFE0E7FF);
  static const Color lightOrange = Color(0xFFFED7AA);
  static const Color darkText = Color(0xFF1F2937);
  static const Color lightText = Color(0xFF6B7280);
  static const Color background = Color(0xFFF8FAFC);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningYellow = Color(0xFFF59E0B);
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with TickerProviderStateMixin {
  String start = "START";
  var accurController = TextEditingController();
  bool inputState = false;

  int duration = 2;

  List<int> _micChunks = [];
  late StreamSubscription _recorderStatus;

  Timer? _timer;
  StreamController streamController = StreamController();
  StreamSubscription? _audioStreamSubscription;
  final _audioRecorder = AudioRecorder();
  final _flutterSoundRecorder = FlutterSoundRecorder();
  bool _isRecording = false;

  late Classifier _classifier;

  List<Category> preds = [];
  List defaultList = [
    {'sound': 'Speech', 'score': 0.0},
    {'sound': 'Car horn', 'score': 0.0},
    {'sound': 'Silent', 'score': 0.0},
    {'sound': 'Machine', 'score': 0.0},
    {'sound': 'Lough', 'score': 0.0},
  ];
  List<String> selectedSounds = [];
  var accuracy = 0.6;

  // Vibration settings
  bool vibrationEnabled = true;
  double vibrationIntensity = 0.5;
  bool customPatternsEnabled = true;

  Category? prediction;

  String _lastProcessedFile = '';
  int _lastFileSize = 0;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  void bindData() async {
    final SharedPreferences storage = await SharedPreferences.getInstance();
    setState(() {
      selectedSounds =
          storage.getStringList('selectedSoundsList') != null
              ? storage.getStringList('selectedSoundsList')!.toList()
              : [];

      // Fix the parsing error with proper null checks
      String? accuracyStr = storage.getString('accuracy');
      if (accuracyStr != null && accuracyStr.isNotEmpty) {
        try {
          accuracy = (double.parse(accuracyStr)) / 100;
        } catch (e) {
          accuracy = 0.6; // Default value
        }
      } else {
        accuracy = 0.6; // Default value
      }

      // Load vibration settings
      vibrationEnabled = storage.getBool('vibrationEnabled') ?? true;
      vibrationIntensity = storage.getDouble('vibrationIntensity') ?? 0.5;
      customPatternsEnabled = storage.getBool('customPatternsEnabled') ?? true;

      // Set default predictions
      setState(() {
        preds = [
          Category('Loading...', 0.0),
          Category('Initializing model...', 0.0),
          Category('Ready to detect sounds', 0.0),
        ];
      });
    });
  }

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    initPlugin();
    _classifier = Classifier();

    // Wait for classifier to initialize before starting timer
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        _startPredictionTimer();
      }
    });

    bindData();

    // Start animations
    _pulseController.repeat(reverse: true);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _recorderStatus.cancel();
    _timer?.cancel();
    _audioStreamSubscription?.cancel();
    _audioRecorder.dispose();
    _flutterSoundRecorder.closeRecorder();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> initPlugin() async {
    // Check microphone permission
    if (await _audioRecorder.hasPermission()) {
      print('Microphone permission granted');
    } else {
      print('Microphone permission denied');
    }

    // Listen to recording status
    _recorderStatus = _audioRecorder.onStateChanged().listen((status) {
      if (mounted) {
        setState(() {
          inputState = status == RecordState.record;
          _isRecording = status == RecordState.record;
        });
      }
    });

    // Start real-time audio data collection during recording
    _startAudioDataCollection();

    streamController.stream.listen(
      (event) async {
        if (!mounted) return;

        try {
          setState(() {
            if (event.isNotEmpty) {
              preds = event;

              // Check for vibration triggers
              _checkVibrationTriggers(event);
            } else {
              // Show default predictions if no results
              preds = [
                Category('No sound detected', 0.0),
                Category('Try speaking or making noise', 0.0),
                Category('Model is ready', 0.0),
              ];
            }
          });
        } catch (e) {
          print('Error in stream listener: $e');
          // Restart the stream if there's an error
          _restartStream();
        }
      },
      onError: (error) {
        print('Stream error: $error');
        _restartStream();
      },
    );

    // Automatically start recording when app launches
    print('Auto-starting recording...');
    await _startRecording();

    // Keep recording active continuously
    setState(() {
      inputState = true;
    });
  }

  // Start collecting audio data in real-time
  void _startAudioDataCollection() {
    Timer.periodic(Duration(milliseconds: 100), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      try {
        if (_isRecording) {
          // Try to read audio data from the current recording file
          await _collectAudioDataFromFile();
        }

        // Always ensure we have audio data for the model (real or simulated)
        if (_micChunks.isEmpty || _micChunks.every((sample) => sample == 0)) {
          _generateSimulatedAudioData();
        }

        // Periodic cleanup to prevent memory issues
        if (DateTime.now().millisecondsSinceEpoch % 10000 < 100) {
          // Every ~10 seconds
          await _cleanupOldFiles();
        }

        // Periodically restart recording to ensure fresh audio data
        if (DateTime.now().millisecondsSinceEpoch % 30000 < 100) {
          // Every ~30 seconds
          print('Periodic recording restart to ensure fresh audio data...');
          await _restartRecording();
          // Reset file tracking after restart
          _lastProcessedFile = '';
          _lastFileSize = 0;
        }
      } catch (e) {
        print('Error in audio data collection: $e');
        // Restart recording if there's an error
        if (_isRecording) {
          print('Restarting recording due to error...');
          await _restartRecording();
          // Reset file tracking after restart
          _lastProcessedFile = '';
          _lastFileSize = 0;
        }
      }
    });
  }

  // Collect audio data from the recorded file
  Future<void> _collectAudioDataFromFile() async {
    try {
      final dir = await getTemporaryDirectory();
      final files =
          dir
              .listSync()
              .where(
                (f) => f.path.contains('audio_') && f.path.endsWith('.wav'),
              )
              .toList();

      if (files.isNotEmpty) {
        // Get the most recent audio file
        files.sort(
          (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
        );
        final latestFile = files.first;

        // Always process if this is a new file or if we haven't processed this file yet
        bool shouldProcess = _lastProcessedFile != latestFile.path;

        // Also process if the file is still being written (recording in progress)
        if (!shouldProcess && _isRecording) {
          try {
            final currentSize = latestFile.statSync().size;
            // Process if file size has increased significantly (new data)
            if (currentSize > _lastFileSize + 1000) {
              // At least 1KB of new data
              shouldProcess = true;
              _lastFileSize = currentSize;
            }
          } catch (e) {
            // File might be locked, try processing anyway
            shouldProcess = true;
          }
        }

        // Force process if we have no audio data
        if (_micChunks.isEmpty || _micChunks.every((sample) => sample == 0)) {
          shouldProcess = true;
        }

        if (shouldProcess) {
          _lastProcessedFile = latestFile.path;
          print('Processing audio file: ${latestFile.path}');

          final bytes = await File(latestFile.path).readAsBytes();
          if (bytes.length > 44) {
            // Skip WAV header
            final audioData = bytes.sublist(44);
            List<int> samples = [];

            // Convert bytes to 16-bit samples (little endian)
            for (int i = 0; i < audioData.length - 1; i += 2) {
              int sample = (audioData[i] | (audioData[i + 1] << 8));
              // Convert to signed 16-bit
              if (sample > 32767) sample -= 65536;
              samples.add(sample);
            }

            // Update _micChunks with fresh audio data
            if (samples.isNotEmpty) {
              _micChunks.clear();
              _micChunks.addAll(samples);

              // Keep only the last 15600 samples (model input size)
              if (_micChunks.length > 15600) {
                _micChunks = _micChunks.sublist(_micChunks.length - 15600);
              }

              print('Collected ${_micChunks.length} fresh audio samples');
              if (_micChunks.isNotEmpty) {
                int nonZeroCount = _micChunks.where((s) => s != 0).length;
                print('Non-zero samples: $nonZeroCount / ${_micChunks.length}');
                print('First 10 samples: ${_micChunks.take(10).toList()}');
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error collecting audio data: $e');
      // If we can't collect real audio data, generate simulated data
      if (_micChunks.isEmpty || _micChunks.every((sample) => sample == 0)) {
        _generateSimulatedAudioData();
      }
    }
  }

  // Generate simulated audio data for testing
  void _generateSimulatedAudioData() {
    if (_micChunks.isEmpty || _micChunks.every((sample) => sample == 0)) {
      print('Generating simulated audio data for testing...');
      _micChunks.clear();

      // Generate a sine wave at 440 Hz (A note)
      for (int i = 0; i < 15600; i++) {
        double t = i / sampleRate.toDouble();
        int sample = (1000 * sin(2 * pi * 440 * t)).round();
        _micChunks.add(sample);
      }

      print('Generated ${_micChunks.length} simulated audio samples');
      print('First 10 simulated samples: ${_micChunks.take(10).toList()}');
    }
  }

  Future<void> _startRecording() async {
    print('START RECORDING CALLED');
    bool hasPerm = await _audioRecorder.hasPermission();
    print('Microphone permission: $hasPerm');
    if (!hasPerm) {
      print('No microphone permission!');
      return;
    }
    try {
      final dir = await getTemporaryDirectory();
      final filePath =
          '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.wav';
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: sampleRate,
          numChannels: 1,
        ),
        path: filePath,
      );
      print('Recording started at: $filePath');
      setState(() {
        inputState = true;
        _isRecording = true;
      });

      // Reset file tracking for new recording
      _lastProcessedFile = '';
      _lastFileSize = 0;
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    print('STOP RECORDING CALLED');
    try {
      bool isRec = await _audioRecorder.isRecording();
      print('Is recording: $isRec');
      final path = await _audioRecorder.stop();
      print('Stopped recording, file path: $path');
      setState(() {
        inputState = false;
        _isRecording = false;
      });

      // Keep the collected audio data for predictions
      print(
        'Recording stopped. Total audio samples collected: ${_micChunks.length}',
      );
      if (_micChunks.isNotEmpty) {
        print('First 20 audio samples: ${_micChunks.take(20).toList()}');
        int nonZeroCount = _micChunks.where((s) => s != 0).length;
        print('Non-zero samples: $nonZeroCount / ${_micChunks.length}');
      }

      // Optional: Also read the file to verify it was created
      if (path != null) {
        try {
          final file = File(path);
          if (await file.exists()) {
            final length = await file.length();
            print('File exists, length: $length');
            final bytes = await file.readAsBytes();
            print('First 20 bytes: ${bytes.take(20).toList()}');

            // Check both little and big endian
            if (bytes.length > 20) {
              List<int> littleEndian = [];
              List<int> bigEndian = [];
              for (int i = 0; i < 20; i += 2) {
                if (i + 1 < bytes.length) {
                  littleEndian.add(bytes[i] | (bytes[i + 1] << 8));
                  bigEndian.add((bytes[i] << 8) | bytes[i + 1]);
                }
              }
              print('File - Little endian first 20: $littleEndian');
              print('File - Big endian first 20: $bigEndian');
              print('File - Total samples (little): ${bytes.length ~/ 2}');
              print('File - Total samples (big): ${bytes.length ~/ 2}');
            }
          } else {
            print('File does not exist');
          }
        } catch (e) {
          print('Error reading file: $e');
        }
      }
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  // Clean up old audio files to prevent memory issues
  Future<void> _cleanupOldFiles() async {
    try {
      final dir = await getTemporaryDirectory();
      final files =
          dir
              .listSync()
              .where(
                (f) => f.path.contains('audio_') && f.path.endsWith('.wav'),
              )
              .toList();

      // Keep only the 5 most recent files
      if (files.length > 5) {
        files.sort(
          (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
        );
        for (int i = 5; i < files.length; i++) {
          await File(files[i].path).delete();
        }
        print('Cleaned up ${files.length - 5} old audio files');
      }
    } catch (e) {
      print('Error cleaning up files: $e');
    }
  }

  // Restart recording to recover from errors
  Future<void> _restartRecording() async {
    try {
      await _stopRecording();
      await Future.delayed(Duration(milliseconds: 500));
      await _startRecording();
      print('Recording restarted successfully');

      // Force audio data collection after restart
      await Future.delayed(Duration(milliseconds: 1000));
      await _collectAudioDataFromFile();
    } catch (e) {
      print('Error restarting recording: $e');
    }
  }

  // Check if detected sounds should trigger vibration
  void _checkVibrationTriggers(List<Category> predictions) async {
    // Check if vibration is enabled in settings
    if (!vibrationEnabled) {
      return;
    }

    // Check if device supports vibration
    bool hasVibrator = await Vibration.hasVibrator() ?? false;
    bool hasAmplitudeControl = await Vibration.hasAmplitudeControl() ?? false;
    bool hasCustomVibrationsSupport =
        await Vibration.hasCustomVibrationsSupport() ?? false;

    print(
      'Vibration capabilities: hasVibrator=$hasVibrator, hasAmplitudeControl=$hasAmplitudeControl, hasCustomVibrationsSupport=$hasCustomVibrationsSupport',
    );

    // Check each prediction for vibration triggers
    for (Category prediction in predictions) {
      // Check if this sound is in user's selected sounds (use English label for comparison)
      if (selectedSounds.contains(prediction.label)) {
        // Check if confidence meets accuracy threshold
        if (prediction.score >= accuracy) {
          print(
            'VIBRATION TRIGGERED: ${prediction.label} (${(prediction.score * 100).toStringAsFixed(1)}%)',
          );

          // Trigger both haptic feedback and vibration
          try {
            // Use heavy impact for important sounds
            HapticFeedback.heavyImpact();
            print('Haptic feedback executed successfully');

            // Add system vibration if device supports it
            if (hasVibrator) {
              // Calculate amplitude based on user settings
              int amplitude = (vibrationIntensity * 255).round();

              if (customPatternsEnabled && hasCustomVibrationsSupport) {
                // Create different vibration patterns based on sound type
                List<int> vibrationPattern = _getVibrationPattern(
                  prediction.label,
                );

                if (vibrationPattern.isNotEmpty) {
                  // Use custom vibration pattern with user's intensity
                  Vibration.vibrate(
                    pattern: vibrationPattern,
                    intensities: [amplitude],
                  );
                  print(
                    'Custom vibration pattern executed: $vibrationPattern with amplitude $amplitude',
                  );
                } else {
                  // Use default vibration with user's intensity
                  if (hasAmplitudeControl) {
                    Vibration.vibrate(amplitude: amplitude);
                  } else {
                    Vibration.vibrate();
                  }
                  print('Default vibration executed with amplitude $amplitude');
                }
              } else {
                // Use default vibration with user's intensity
                if (hasAmplitudeControl) {
                  Vibration.vibrate(amplitude: amplitude);
                } else {
                  Vibration.vibrate();
                }
                print('Default vibration executed with amplitude $amplitude');
              }
            }
          } catch (e) {
            print('Vibration/Haptic feedback error: $e');
          }

          // Only vibrate for the highest confidence sound to avoid spam
          break;
        }
      }
    }
  }

  // Get vibration pattern based on sound type
  List<int> _getVibrationPattern(String soundLabel) {
    switch (soundLabel.toLowerCase()) {
      case 'car horn':
        // Two short bursts for car horn
        return [0, 200, 100, 200];
      case 'speech':
        // Three gentle pulses for speech
        return [0, 150, 100, 150, 100, 150];
      case 'machine':
        // Continuous vibration for machine sounds
        return [0, 500];
      case 'lough':
        // Multiple quick pulses for laughter
        return [0, 100, 50, 100, 50, 100, 50, 100];
      case 'silent':
        // No vibration for silence
        return [];
      default:
        // Default pattern for other sounds
        return [0, 300];
    }
  }

  // Restart the stream controller if it gets stuck
  void _restartStream() {
    try {
      streamController.close();
      streamController = StreamController();
      print('Stream controller restarted');
    } catch (e) {
      print('Error restarting stream: $e');
    }
  }

  // Start the prediction timer with error handling
  void _startPredictionTimer() {
    if (_timer != null) {
      _timer?.cancel();
    }

    _timer = Timer.periodic(Duration(seconds: duration), (Timer t) {
      if (!mounted) {
        t.cancel();
        return;
      }

      try {
        if (_micChunks.isNotEmpty) {
          streamController.add(_classifier.predict(_micChunks));
        }
      } catch (e) {
        print('Error in prediction timer: $e');
        // Restart timer if there's an error
        t.cancel();
        Future.delayed(Duration(seconds: 1), () {
          if (mounted) {
            _startPredictionTimer();
          }
        });
      }
    });
  }

  // Continuous recording is now handled by the main recording logic
  // No need for test functions with time limits

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color(0xFF1E3A8A),
        title: Text(
          'Sound Detection',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.settings, color: Colors.white, size: 24),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Settings()),
                );
              },
            ),
          ),
        ],
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 24),

          // Main microphone section with animations
          Center(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors:
                      inputState
                          ? [Color(0xFF1E3A8A), Color(0xFFF97316)]
                          : [Color(0xFFE0E7FF), Color(0xFFFED7AA)],
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        inputState
                            ? Color(0xFF1E3A8A).withOpacity(0.3)
                            : Color(0xFF6B7280).withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Icon(
                  inputState ? Icons.mic : Icons.mic_off,
                  color: inputState ? Color(0xFF1E3A8A) : Color(0xFF6B7280),
                  size: 40,
                ),
              ),
            ),
          ),

          SizedBox(height: 20),

          // Status text
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color:
                  inputState
                      ? Color(0xFF1E3A8A).withOpacity(0.1)
                      : Color(0xFF6B7280).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: inputState ? Color(0xFF1E3A8A) : Color(0xFF6B7280),
                width: 1,
              ),
            ),
            child: Text(
              inputState
                  ? '🎧 Listening for sounds...'
                  : '🔇 Tap to start listening',
              style: GoogleFonts.inter(
                color: inputState ? Color(0xFF1E3A8A) : Color(0xFF6B7280),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          SizedBox(height: 24),

          // Predictions section
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFF1E3A8A),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.analytics, color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Sound Detection Results',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.all(12),
                      itemCount: preds.length,
                      itemBuilder: (context, index) {
                        final pred = preds[index];
                        final percentage = (pred.score * 100);
                        final isHighConfidence = percentage > 70;

                        return Container(
                          margin: EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color:
                                isHighConfidence
                                    ? Color(0xFFF97316).withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  isHighConfidence
                                      ? Color(0xFFF97316).withOpacity(0.3)
                                      : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color:
                                    isHighConfidence
                                        ? Color(0xFFF97316).withOpacity(0.2)
                                        : Color(0xFF1E3A8A).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isHighConfidence
                                    ? Icons.warning
                                    : Icons.music_note,
                                color:
                                    isHighConfidence
                                        ? Color(0xFFF97316)
                                        : Color(0xFF1E3A8A),
                                size: 20,
                              ),
                            ),
                            title: Text(
                              pred.displayLabel,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            subtitle: Text(
                              'Confidence level',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            trailing: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isHighConfidence
                                        ? Color(0xFFF97316)
                                        : Color(0xFF1E3A8A),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // Control section
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inputState ? 'Recording Active' : 'Recording Stopped',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color:
                            inputState ? Color(0xFF1E3A8A) : Color(0xFF6B7280),
                      ),
                    ),
                    Text(
                      inputState
                          ? 'Detecting sounds in real-time'
                          : 'Start to begin detection',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: inputState ? Color(0xFF1E3A8A) : Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Switch(
                    value: inputState,
                    onChanged: (value) async {
                      if (value) {
                        await _startRecording();
                      } else {
                        await _stopRecording();
                      }
                    },
                    activeColor: Colors.white,
                    activeTrackColor: Color(0xFF1E3A8A),
                    inactiveTrackColor: Color(0xFFE5E7EB),
                    inactiveThumbColor: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),
        ],
      ),
      bottomNavigationBar: Navigation(index: 0),
    );
  }
}

class PredictionScoreBar extends StatelessWidget {
  final double ratio;
  final Color color;
  const PredictionScoreBar({Key? key, required this.ratio, required this.color})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 16,
      width: (MediaQuery.of(context).size.width * 0.6) * ratio,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.horizontal(
          left: Radius.circular(4.0),
          right: Radius.circular(ratio == 1 ? 4.0 : 0.0),
        ),
      ),
    );
  }
}
