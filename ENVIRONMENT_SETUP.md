# 🔧 Environment Setup Guide

## 📋 **Overview**

This guide explains how to set up environment variables and configuration for your ABA data collection app, including the note drafting service.

## 🎯 **Current Configuration System**

Your app uses a **hardcoded configuration approach** in `lib/config/app_config.dart` instead of `.env` files.

### **Existing Configuration Files:**
- `lib/config/app_config.dart` - Main app configuration
- `lib/config/note_drafting_config.dart` - Note drafting service configuration
- `lib/config/app_config.dart.template` - Template for app configuration

## 🔧 **Configuration Files**

### **1. Main App Configuration (`lib/config/app_config.dart`)**
```dart
class AppConfig {
  // FileMaker Configuration
  static const String baseUrl = 'https://devdb.sphereemr.com/fmi/data/vLatest';
  static const String database = 'EIDBI';
  static const String username = 'fmapi';
  static const String password = 'Sphere321\$';
  
  // App Configuration
  static const String appName = 'DataSheets';
  static const String appVersion = '1.0.0';
  
  // API Configuration
  static const int connectionTimeout = 30;
  static const int receiveTimeout = 30;
}
```

### **2. Note Drafting Configuration (`lib/config/note_drafting_config.dart`)**
```dart
class NoteDraftingConfig {
  // API Configuration
  static const String apiUrl = 'https://arawello.ai/v1/chat/completions';
  static const String model = 'gpt-4';
  static const double temperature = 0.3;
  static const int maxTokens = 500;
  
  // API Keys (set these to your actual keys)
  static const String? apiKey = null; // Set to your API key
  static const String? openaiApiKey = null; // Set to your OpenAI key
}
```

## 🔑 **Setting Up API Keys**

### **Option 1: Edit Configuration File (Recommended)**
1. Open `lib/config/note_drafting_config.dart`
2. Set your API key:
   ```dart
   static const String? apiKey = "your-actual-api-key-here";
   ```
3. Save the file

### **Option 2: Pass API Key at Runtime**
```dart
final noteDraft = await NoteDraftingService.generateNoteDraft(
  session: session,
  ragContext: ragContext,
  apiKey: "your-api-key-here", // Pass API key directly
);
```

## 🧪 **Testing Your Configuration**

### **Run Configuration Test**
```bash
dart test_configuration.dart
```

This will:
- ✅ Check your current configuration
- ✅ Verify API key setup
- ✅ Test message building (no API key required)
- ✅ Test API calls (if API key is configured)
- ✅ Provide configuration recommendations

### **Expected Output**
```
🔧 Testing Configuration Setup
==============================

📋 Test 1: Configuration Check
-------------------------------
✅ Configuration loaded:
   - API URL: https://arawello.ai/v1/chat/completions
   - Model: gpt-4
   - Temperature: 0.3
   - Max Tokens: 500
   - Has API Key: false
   - API Key Source: none

🔑 Test 2: API Key Configuration
--------------------------------
⚠️  No API key configured
   - To configure: Edit lib/config/note_drafting_config.dart
   - Set apiKey or openaiApiKey to your API key

📝 Test 3: Message Building Test
--------------------------------
✅ Messages built successfully!
   - System message length: 200 characters
   - User message length: 300 characters

🌐 Test 4: API Call Test
------------------------
⚠️  No API key configured, skipping API call test
   - To test API calls:
     1. Edit lib/config/note_drafting_config.dart
     2. Set apiKey or openaiApiKey to your API key
     3. Run this test again

💡 Test 5: Configuration Recommendations
---------------------------------------
📋 Current setup:
   - Configuration file: lib/config/note_drafting_config.dart
   - API URL: https://arawello.ai/v1/chat/completions
   - Model: gpt-4
   - Temperature: 0.3
   - Max Tokens: 500

🔧 To configure API key:
   1. Open lib/config/note_drafting_config.dart
   2. Set apiKey = "your-api-key-here"
   3. Or set openaiApiKey = "your-openai-key-here"
   4. Save the file
   5. Run this test again

🌐 Supported APIs:
   - arawello.ai (default)
   - OpenAI API (if openaiApiKey is set)
   - Any OpenAI-compatible API

🎉 Configuration test completed!
💡 The note drafting service is ready to use.
```

## 🚀 **Quick Start**

### **1. Test Current Setup**
```bash
dart test_configuration.dart
```

### **2. Configure API Key (if needed)**
Edit `lib/config/note_drafting_config.dart`:
```dart
static const String? apiKey = "your-api-key-here";
```

### **3. Test Note Drafting**
```bash
dart test_note_drafting.dart
```

### **4. Run Examples**
```bash
dart example_note_drafting.dart
```

## 🔧 **Advanced Configuration**

### **Using Different APIs**

**OpenAI API:**
```dart
static const String? openaiApiKey = "sk-your-openai-key-here";
```

**Custom API:**
```dart
static const String apiUrl = "https://your-custom-api.com/v1/chat/completions";
static const String? apiKey = "your-custom-key";
```

### **Environment Variables (Alternative)**

If you want to use `.env` files, you can:

1. Add `flutter_dotenv` to your `pubspec.yaml`:
   ```yaml
   dependencies:
     flutter_dotenv: ^5.1.0
   ```

2. Create a `.env` file:
   ```
   NOTE_DRAFTING_API_KEY=your-api-key-here
   OPENAI_API_KEY=sk-your-openai-key-here
   ```

3. Load it in your app:
   ```dart
   import 'package:flutter_dotenv/flutter_dotenv.dart';
   
   await dotenv.load(fileName: ".env");
   final apiKey = dotenv.env['NOTE_DRAFTING_API_KEY'];
   ```

## 📊 **Configuration Summary**

| Setting | File | Purpose |
|---------|------|---------|
| FileMaker URL | `app_config.dart` | Database connection |
| FileMaker Credentials | `app_config.dart` | Database authentication |
| Note Drafting API | `note_drafting_config.dart` | AI note generation |
| API Keys | `note_drafting_config.dart` | API authentication |
| App Settings | `app_config.dart` | General app configuration |

## 🔍 **Troubleshooting**

### **Common Issues**

1. **"API key not configured" error**
   - Edit `lib/config/note_drafting_config.dart`
   - Set `apiKey` or `openaiApiKey`

2. **"API request failed" error**
   - Check your API key is valid
   - Verify the API endpoint is accessible
   - Check your internet connection

3. **"Configuration file not found" error**
   - Make sure you're in the right directory
   - Check that `lib/config/` directory exists

### **Debug Steps**

1. **Check configuration:**
   ```bash
   dart test_configuration.dart
   ```

2. **Verify file structure:**
   ```bash
   ls -la lib/config/
   ```

3. **Check API key:**
   ```dart
   print('API Key: ${NoteDraftingConfig.getApiKey()}');
   ```

## 🎉 **Success Metrics**

- ✅ **Configuration loaded** successfully
- ✅ **API key configured** (if needed)
- ✅ **Message building** working
- ✅ **API calls** working (if configured)
- ✅ **Note generation** working

---

**🔧 Your environment is now properly configured for the note drafting service!**
