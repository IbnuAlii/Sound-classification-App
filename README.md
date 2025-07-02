# Sound Detection App for Deaf and Hard of Hearing Community

A Flutter-based mobile application designed to help deaf and hard of hearing individuals detect and identify sounds in their environment through real-time audio classification using TensorFlow Lite.

## 🌟 Features

### 🎯 Core Functionality
- **Real-time Sound Detection**: Continuously monitors and classifies sounds using YAMNet model
- **Somali Language Support**: Complete Somali translations for all sound labels
- **Vibration Alerts**: Customizable vibration patterns for detected sounds
- **Accessibility Focused**: Designed specifically for the deaf and hard of hearing community

### 📱 User Interface
- **Modern Design**: Deep blue and vibrant orange color scheme
- **Accessible Typography**: Clear, readable fonts with proper contrast
- **Smooth Animations**: Engaging visual feedback and transitions
- **Responsive Layout**: Works on various screen sizes

### ⚙️ Customization Options
- **Sound Selection**: Choose which sounds to monitor (30+ sound categories)
- **Sensitivity Control**: Adjust detection threshold (0-100%)
- **Vibration Settings**: 
  - Enable/disable vibration alerts
  - Adjust vibration intensity
  - Custom vibration patterns for different sounds
- **Language Display**: Somali labels with English subtitles

### 🔧 Technical Features
- **TensorFlow Lite Integration**: Efficient on-device sound classification
- **Continuous Recording**: Real-time audio processing with automatic restarts
- **Battery Optimized**: Efficient audio processing to preserve battery life
- **Cross-platform**: Works on Android and iOS devices

## 🎵 Supported Sound Categories

The app can detect and classify over 500 different sounds, including:

### 🏠 Household Sounds
- Door knocks, slams, and doorbells
- Kitchen appliances (blender, microwave, dishwasher)
- Household tools (vacuum cleaner, hair dryer)
- Electronic devices (television, radio, telephone)

### 🚗 Transportation
- Vehicle horns and alarms
- Car, bus, truck, and motorcycle sounds
- Train whistles and horns
- Aircraft and helicopter sounds

### 🐾 Animals
- Domestic pets (dogs, cats, birds)
- Farm animals (cattle, sheep, goats, chickens)
- Wild animals and bird calls

### 🎵 Music and Entertainment
- Musical instruments (piano, guitar, drums)
- Different music genres
- Applause and cheering

### 🚨 Safety and Emergency
- Fire alarms and smoke detectors
- Emergency vehicle sirens
- Gunshots and explosions
- Thunder and weather sounds

### 👥 Human Sounds
- Speech and conversations
- Laughter and crying
- Coughing, sneezing, and breathing
- Footsteps and movement

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.7.2 or higher)
- Android Studio / Xcode
- Android device or emulator / iOS device or simulator

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/IbnuAlii/Sound-classification-App.git
   cd Sound-classification-App
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Permissions Required
- **Microphone**: For audio recording and sound detection
- **Vibration**: For haptic feedback alerts

## 📖 Usage Guide

### First Time Setup
1. **Grant Permissions**: Allow microphone and vibration access when prompted
2. **Configure Settings**: Go to Settings tab to customize your experience
3. **Select Sounds**: Choose which sounds you want to monitor
4. **Adjust Sensitivity**: Set your preferred detection threshold

### Using the App
1. **Start Detection**: Toggle the recording switch to begin sound detection
2. **Monitor Results**: View real-time sound classifications on the main screen
3. **Receive Alerts**: Get vibration notifications for detected sounds
4. **Review History**: Check recent detections and confidence levels

### Settings Configuration
- **Sound Events**: Select/deselect specific sounds to monitor
- **Sensitivity**: Adjust detection threshold (higher = more sensitive)
- **Vibration Settings**: 
  - Enable/disable vibration alerts
  - Set vibration intensity (light to strong)
  - Choose custom patterns for different sounds

## 🛠️ Technical Architecture

### Dependencies
- **tflite_flutter**: TensorFlow Lite integration
- **record**: Audio recording functionality
- **flutter_sound**: Audio processing
- **vibration**: Haptic feedback
- **shared_preferences**: Settings persistence
- **google_fonts**: Typography
- **auto_size_text**: Responsive text sizing

### Model Information
- **YAMNet**: You Only Look Once (YOLO) Audio Neural Network
- **Input**: 16kHz mono audio, 0.975 seconds duration
- **Output**: 521 sound classes with confidence scores
- **Model Size**: ~16MB optimized for mobile devices

### File Structure
```
lib/
├── main.dart              # Main application entry point
├── classifier.dart         # TensorFlow Lite integration
├── somali_translations.dart # Somali language translations
├── settings.dart          # Settings page UI
├── navigation.dart        # Bottom navigation bar
├── about.dart            # About page
└── splash.dart           # Splash screen

assets/
├── yamnet.tflite         # TensorFlow Lite model
├── yamnet_class_map.csv  # Sound class labels
└── images/               # App images and icons
```

## 🌍 Somali Language Support

The app includes comprehensive Somali translations for all sound labels, making it accessible to Somali-speaking users. Features include:

- **Primary Display**: Somali labels shown as main text
- **Secondary Display**: English labels shown as subtitles
- **Complete Coverage**: 500+ sound categories translated
- **Cultural Relevance**: Contextually appropriate translations

### Example Translations
- Cough → Qufac
- Car horn → Koor moto
- Door knock → Gunqax
- Fire alarm → Fire alarm
- Speech → Hadalka
- Music → Muusik

## 🔧 Development

### Building for Production

**Android APK:**
```bash
flutter build apk --release
```

**Android App Bundle:**
```bash
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

### Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📱 Screenshots

*[Screenshots will be added here]*

## 🤝 Acknowledgments

- **YAMNet Model**: Google Research for the audio classification model
- **Flutter Community**: For excellent documentation and packages
- **Somali Language Experts**: For accurate translations and cultural context
- **Deaf and Hard of Hearing Community**: For valuable feedback and testing

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

For support, questions, or feature requests:
- Create an issue on GitHub
- Contact the development team
- Check the documentation

## 🔄 Version History

- **v1.0.0**: Initial release with core functionality
  - Real-time sound detection
  - Somali language support
  - Vibration alerts
  - Accessibility features

---

**Made with ❤️ for the Deaf and Hard of Hearing Community**
