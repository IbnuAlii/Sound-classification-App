import 'package:audio_classification_final/navigation.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:google_fonts/google_fonts.dart';
import 'somali_translations.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  List<String> sounds = [
    'Silence (Aamusnaan)',
    'Vehicle horn, car horn, honking',
    'Knock',
    'Alarm',
    'Noise',
    'Speech',
    'Music',
    'Rain',
    'Fire',
    'Vehicle',
    'Telephone',
    'Crying, sobbing',
    'Baby cry',
    'Car',
    'Door',
    'Doorbell',
    'Alarm clock',
    'Siren',
    'Fire alarm',
    'Gunshot, gunfire',
    'Television',
    'Radio',
    'Ringtone',
    'Sliding door',
    'Engine',
    'Hands',
    'Finger snapping',
    'Clapping',
    'Cough',
    'Walk, footsteps',
  ];
  List<String> tempList = [
    'Silence (Aamusnaan)',
    'Vehicle horn, car horn, honking',
    'Knock',
    'Alarm',
    'Noise',
    'Speech',
    'Music',
    'Rain',
    'Fire',
    'Vehicle',
    'Telephone',
    'Crying, sobbing',
    'Baby cry',
    'Car',
    'Door',
    'Doorbell',
    'Alarm clock',
    'Siren',
    'Fire alarm',
    'Gunshot, gunfire',
    'Television',
    'Radio',
    'Ringtone',
    'Sliding door',
    'Engine',
    'Hands',
    'Finger snapping',
    'Clapping',
    'Cough',
    'Walk, footsteps',
  ];
  List<String> selectedSounds = [];

  var accuracy = 60;
  var _isLoading = false;
  final _scrollController = ScrollController();
  var searchController = TextEditingController();
  var accurController = TextEditingController();

  // Vibration settings
  bool vibrationEnabled = true;
  double vibrationIntensity = 0.5; // 0.0 to 1.0
  bool customPatternsEnabled = true;

  // Function to get appropriate icon for each sound
  IconData getSoundIcon(String sound) {
    String lowerSound = sound.toLowerCase();

    if (lowerSound.contains('silence') || lowerSound.contains('aamusnaan')) {
      return Icons.volume_off;
    } else if (lowerSound.contains('horn') || lowerSound.contains('honking')) {
      return Icons.car_crash;
    } else if (lowerSound.contains('knock')) {
      return Icons.door_front_door;
    } else if (lowerSound.contains('alarm')) {
      return Icons.alarm;
    } else if (lowerSound.contains('noise')) {
      return Icons.volume_up;
    } else if (lowerSound.contains('speech')) {
      return Icons.record_voice_over;
    } else if (lowerSound.contains('music')) {
      return Icons.music_note;
    } else if (lowerSound.contains('rain')) {
      return Icons.water_drop;
    } else if (lowerSound.contains('fire')) {
      return Icons.local_fire_department;
    } else if (lowerSound.contains('vehicle') || lowerSound.contains('car')) {
      return Icons.directions_car;
    } else if (lowerSound.contains('telephone') ||
        lowerSound.contains('ringtone')) {
      return Icons.phone;
    } else if (lowerSound.contains('crying') ||
        lowerSound.contains('baby cry') ||
        lowerSound.contains('sobbing')) {
      return Icons.child_care;
    } else if (lowerSound.contains('door')) {
      return Icons.door_front_door;
    } else if (lowerSound.contains('doorbell')) {
      return Icons.doorbell;
    } else if (lowerSound.contains('siren')) {
      return Icons.emergency;
    } else if (lowerSound.contains('gunshot') ||
        lowerSound.contains('gunfire')) {
      return Icons.gps_fixed;
    } else if (lowerSound.contains('television') || lowerSound.contains('tv')) {
      return Icons.tv;
    } else if (lowerSound.contains('radio')) {
      return Icons.radio;
    } else if (lowerSound.contains('engine')) {
      return Icons.engineering;
    } else if (lowerSound.contains('hands') ||
        lowerSound.contains('clapping')) {
      return Icons.pan_tool;
    } else if (lowerSound.contains('finger snapping')) {
      return Icons.touch_app;
    } else if (lowerSound.contains('cough')) {
      return Icons.health_and_safety;
    } else if (lowerSound.contains('walk') ||
        lowerSound.contains('footsteps')) {
      return Icons.directions_walk;
    } else {
      return Icons.volume_up; // Default icon
    }
  }

  void saveSelectedSounds() async {
    final SharedPreferences storage = await SharedPreferences.getInstance();
    storage.setStringList('selectedSoundsList', selectedSounds);
    storage.setString('accuracy', accurController.text);

    // Save vibration settings
    storage.setBool('vibrationEnabled', vibrationEnabled);
    storage.setDouble('vibrationIntensity', vibrationIntensity);
    storage.setBool('customPatternsEnabled', customPatternsEnabled);

    setState(() {
      _isLoading = false;
    });
    AwesomeDialog(
      context: context,
      autoHide: Duration(seconds: 3),
      dialogType: DialogType.success,
      animType: AnimType.rightSlide,
      transitionAnimationDuration: Duration(milliseconds: 500),
      title: 'Settings Updated',
      desc: 'Your sound detection and vibration settings have been updated',
      // btnCancelOnPress: () {},
      btnOkOnPress: () {},
      btnOkColor: Color(0xFFFE9879),
    )..show();
  }

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
          accuracy = int.parse(accuracyStr);
        } catch (e) {
          accuracy = 60; // Default value
        }
      } else {
        accuracy = 60; // Default value
      }

      accurController.text = accuracy.toString();

      // Load vibration settings
      vibrationEnabled = storage.getBool('vibrationEnabled') ?? true;
      vibrationIntensity = storage.getDouble('vibrationIntensity') ?? 0.5;
      customPatternsEnabled = storage.getBool('customPatternsEnabled') ?? true;
    });
    // print(selectedSounds);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    bindData();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xFFF1F5F9),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: Text(
            'Settings',
            style: GoogleFonts.inter(
              color: Color(0xFF1E3A8A),
              fontWeight: FontWeight.w700,
              fontSize: 22,
              letterSpacing: -0.5,
            ),
          ),
          automaticallyImplyLeading: false,
          centerTitle: true,
          actions: [
            Container(
              margin: EdgeInsets.only(right: 16),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF1E3A8A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.settings, color: Color(0xFF1E3A8A), size: 20),
            ),
          ],
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Compact Top Section
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      spreadRadius: 0,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1E3A8A), Color(0xFFF97316)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.hearing, color: Colors.white, size: 20),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sound Detection',
                            style: GoogleFonts.inter(
                              color: Color(0xFF1E3A8A),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '${selectedSounds.length} of ${sounds.length} sounds selected',
                            style: GoogleFonts.inter(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Compact Sensitivity Section
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            spreadRadius: 0,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Color(0xFFF97316).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.vibration,
                              color: Color(0xFFF97316),
                              size: 16,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Sensitivity:',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                              ),
                              child: TextField(
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                controller: accurController,
                                onChanged: (value) => {print(value)},
                                decoration: InputDecoration(
                                  hintText: "60",
                                  hintStyle: GoogleFonts.inter(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF1E3A8A), Color(0xFFF97316)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '%',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 12),

                    // Vibration Settings Section
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            spreadRadius: 0,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Color(0xFF1E3A8A).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.vibration,
                                  color: Color(0xFF1E3A8A),
                                  size: 16,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Vibration Settings',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),

                          // Vibration Toggle
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Enable Vibration',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              Switch(
                                value: vibrationEnabled,
                                onChanged: (value) {
                                  setState(() {
                                    vibrationEnabled = value;
                                  });
                                },
                                activeColor: Color(0xFF1E3A8A),
                                activeTrackColor: Color(
                                  0xFF1E3A8A,
                                ).withOpacity(0.3),
                              ),
                            ],
                          ),

                          if (vibrationEnabled) ...[
                            SizedBox(height: 8),

                            // Vibration Intensity
                            Text(
                              'Vibration Intensity',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            SizedBox(height: 4),
                            Slider(
                              value: vibrationIntensity,
                              min: 0.0,
                              max: 1.0,
                              divisions: 10,
                              activeColor: Color(0xFF1E3A8A),
                              inactiveColor: Color(0xFFE2E8F0),
                              onChanged: (value) {
                                setState(() {
                                  vibrationIntensity = value;
                                });
                              },
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Light',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                                Text(
                                  '${(vibrationIntensity * 100).round()}%',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E3A8A),
                                  ),
                                ),
                                Text(
                                  'Strong',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 8),

                            // Custom Patterns Toggle
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Custom Vibration Patterns',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                                Switch(
                                  value: customPatternsEnabled,
                                  onChanged: (value) {
                                    setState(() {
                                      customPatternsEnabled = value;
                                    });
                                  },
                                  activeColor: Color(0xFFF97316),
                                  activeTrackColor: Color(
                                    0xFFF97316,
                                  ).withOpacity(0.3),
                                ),
                              ],
                            ),

                            if (customPatternsEnabled) ...[
                              SizedBox(height: 4),
                              Text(
                                'Different patterns for different sounds',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: Color(0xFF94A3B8),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),

                    SizedBox(height: 12),

                    // Sound Events Section - Docked to fill available space
                    Container(
                      height:
                          MediaQuery.of(context).size.height -
                          420, // Adjusted height for vibration section
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            spreadRadius: 0,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Header with Select All and Save buttons
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                              ),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.music_note,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Sound Events',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Select sounds to monitor',
                                        style: GoogleFonts.inter(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Select All Button
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (selectedSounds.length ==
                                          sounds.length) {
                                        selectedSounds.clear();
                                      } else {
                                        selectedSounds = List<String>.from(
                                          sounds,
                                        );
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          selectedSounds.length == sounds.length
                                              ? Icons.check_circle
                                              : Icons.select_all,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          selectedSounds.length == sounds.length
                                              ? 'Deselect'
                                              : 'Select All',
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                // Save Settings Button
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isLoading = true;
                                    });
                                    saveSelectedSounds();
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFF97316),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _isLoading
                                            ? Container(
                                              width: 12,
                                              height: 12,
                                              padding: const EdgeInsets.all(
                                                1.0,
                                              ),
                                              child:
                                                  const CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 1.5,
                                                  ),
                                            )
                                            : Icon(
                                              Icons.save_alt,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                        SizedBox(width: 4),
                                        Text(
                                          _isLoading ? "Saving..." : "Save",
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Scrollable Sound Events List
                          Expanded(
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: EdgeInsets.all(12),
                              itemCount: sounds.length,
                              itemBuilder: (context, index) {
                                final sound = sounds[index];
                                final isSelected = selectedSounds.contains(
                                  sound,
                                );

                                return Container(
                                  margin: EdgeInsets.only(bottom: 6),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? Color(0xFFFEF3C7)
                                            : Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? Color(0xFFF59E0B)
                                              : Color(0xFFE2E8F0),
                                      width: 1,
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    leading: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color:
                                            isSelected
                                                ? Color(
                                                  0xFFF97316,
                                                ).withOpacity(0.15)
                                                : Color(
                                                  0xFF1E3A8A,
                                                ).withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        getSoundIcon(sound),
                                        color:
                                            isSelected
                                                ? Color(0xFFF97316)
                                                : Color(0xFF1E3A8A),
                                        size: 16,
                                      ),
                                    ),
                                    title: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          SomaliTranslations.getSomaliTranslation(
                                            sound,
                                          ),
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                        if (SomaliTranslations.getSomaliTranslation(
                                              sound,
                                            ) !=
                                            sound)
                                          Text(
                                            sound,
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w400,
                                              fontSize: 10,
                                              color: Color(0xFF6B7280),
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: Container(
                                      decoration: BoxDecoration(
                                        color:
                                            isSelected
                                                ? Color(0xFFF97316)
                                                : Colors.grey.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Checkbox(
                                        value: isSelected,
                                        onChanged: (value) {
                                          setState(() {
                                            if (value == true) {
                                              selectedSounds.add(sound);
                                            } else {
                                              selectedSounds.remove(sound);
                                            }
                                          });
                                        },
                                        activeColor: Colors.transparent,
                                        checkColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
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

                    SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Navigation(index: 2),
      ),
    );
  }
}
