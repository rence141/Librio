# Librio: LLM Model Integration Guide

**Date:** 2026-08-22  
**Status:** Ready for Implementation  
**Target:** Week 17-18 (2026-09-29 to 2026-10-06)

---

## 🎯 OBJECTIVE

Download, bundle, and integrate the Gemma 3 1B GGUF model for on-device inference.

---

## 📋 PREREQUISITES

### **Required**
- [ ] 3GB free disk space (for model file)
- [ ] 4GB RAM (for model loading)
- [ ] Internet connection (for download)
- [ ] HuggingFace account (optional, for faster downloads)

### **Device Requirements**
- [ ] Infinix-Note50 (4GB RAM, Android 13)
- [ ] Similar low-end Android devices

---

## 🔧 STEP 1: DOWNLOAD GEMMA 3 1B MODEL

### **1.1 Download from HuggingFace**

```bash
# Option 1: Using curl (recommended)
mkdir -p apps/mobile/assets/models
cd apps/mobile/assets/models

# Download Gemma 3 1B Q4_K_M (quantized, ~2.5GB)
curl -L -o gemma-3-1b-q4_k_m.gguf \
  https://huggingface.co/google/gemma-3-1b-gguf/resolve/main/gemma-3-1b-q4_k_m.gguf

# Verify download
ls -lh gemma-3-1b-q4_k_m.gguf
# Should show: ~2.5GB
```

### **1.2 Alternative: Using HuggingFace CLI**

```bash
# Install HuggingFace CLI
pip install huggingface-hub

# Download model
huggingface-cli download google/gemma-3-1b-gguf \
  gemma-3-1b-q4_k_m.gguf \
  --local-dir apps/mobile/assets/models
```

### **1.3 Verify Model Integrity**

```bash
# Check file size
ls -lh apps/mobile/assets/models/gemma-3-1b-q4_k_m.gguf

# Expected: ~2.5GB

# Check SHA256 (optional)
sha256sum apps/mobile/assets/models/gemma-3-1b-q4_k_m.gguf
```

---

## 📦 STEP 2: CONFIGURE FLUTTER ASSETS

### **2.1 Update pubspec.yaml**

```yaml
# apps/mobile/pubspec.yaml

flutter:
  uses-material-design: true
  
  assets:
    - assets/models/gemma-3-1b-q4_k_m.gguf
```

### **2.2 Update .gitignore**

```bash
# .gitignore

# LLM weights (never commit)
*.gguf
*.litertlm
*.bin
*.safetensors
apps/mobile/assets/models/
```

---

## 🔌 STEP 3: IMPLEMENT LLM SERVICE

### **3.1 Create LLM Service**

```dart
// apps/mobile/lib/services/llm_service.dart

import 'package:flutter/foundation.dart';
import 'model_loader.dart';

/// LLM Service for on-device inference
class LlmService {
  static final LlmService _instance = LlmService._internal();
  
  factory LlmService() {
    return _instance;
  }
  
  LlmService._internal();
  
  late ModelLoader _modelLoader;
  bool _modelInitialized = false;
  
  /// Initialize LLM service
  Future<bool> initialize(ModelLoader modelLoader) async {
    try {
      _modelLoader = modelLoader;
      
      // Check if model exists
      final modelExists = await _modelLoader.modelExists();
      if (!modelExists) {
        if (kDebugMode) {
          print('⚠️ Model not found. Download from:');
          print('   https://huggingface.co/google/gemma-3-1b-gguf');
        }
        return false;
      }
      
      // Load model
      final modelPath = _modelLoader.modelPath;
      if (modelPath == null) {
        return false;
      }
      
      // Initialize llamadart with model
      // TODO: Implement actual model loading with llamadart
      // final llm = await LlamaModel.load(modelPath);
      
      _modelInitialized = true;
      
      if (kDebugMode) {
        print('✅ LLM service initialized');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ LLM initialization failed: $e');
      }
      return false;
    }
  }
  
  /// Generate response from prompt
  Future<String> generateResponse(String prompt) async {
    if (!_modelInitialized) {
      return 'Model not initialized. Please download the model file.';
    }
    
    try {
      if (kDebugMode) {
        print('🤖 Generating response for: $prompt');
      }
      
      // TODO: Implement actual inference with llamadart
      // final response = await llm.generate(prompt);
      
      // For now, return placeholder
      final response = 'This is a placeholder response. '
          'Actual LLM inference will be implemented when model is available.';
      
      if (kDebugMode) {
        print('✅ Response generated');
      }
      
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Generation failed: $e');
      }
      return 'Error generating response: $e';
    }
  }
  
  /// Stream response from prompt
  Stream<String> streamResponse(String prompt) async* {
    if (!_modelInitialized) {
      yield 'Model not initialized. Please download the model file.';
      return;
    }
    
    try {
      if (kDebugMode) {
        print('🤖 Streaming response for: $prompt');
      }
      
      // TODO: Implement streaming inference with llamadart
      // Stream tokens as they are generated
      
      // For now, yield placeholder
      yield 'This is a placeholder response. ';
      yield 'Actual LLM inference will be implemented when model is available.';
      
      if (kDebugMode) {
        print('✅ Stream complete');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Streaming failed: $e');
      }
      yield 'Error generating response: $e';
    }
  }
  
  /// Check if model is initialized
  bool get isInitialized => _modelInitialized;
  
  /// Get model info
  Future<Map<String, dynamic>> getModelInfo() async {
    return await _modelLoader.getModelInfo();
  }
}
```

### **3.2 Update main.dart**

```dart
// apps/mobile/lib/main.dart

import 'services/llm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ... existing initialization code ...
  
  final llmService = LlmService();
  final modelInitialized = await llmService.initialize(modelLoader);
  
  if (!modelInitialized) {
    print('⚠️ Model not available. App will run in demo mode.');
  }
  
  runApp(LibrioApp(
    // ... existing parameters ...
    llmService: llmService,
  ));
}
```

---

## 💬 STEP 4: IMPLEMENT CHAT SCREEN

### **4.1 Create Chat Screen**

```dart
// apps/mobile/lib/screens/chat_screen.dart

import 'package:flutter/material.dart';
import '../services/llm_service.dart';

class ChatScreen extends StatefulWidget {
  final LlmService llmService;
  
  const ChatScreen({
    super.key,
    required this.llmService,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> messages = [];
  final TextEditingController controller = TextEditingController();
  bool isLoading = false;
  
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
  
  Future<void> sendMessage(String text) async {
    if (text.isEmpty) return;
    
    setState(() {
      messages.add(ChatMessage(text: text, isUser: true));
      isLoading = true;
    });
    
    controller.clear();
    
    try {
      // Stream response from LLM
      final stream = widget.llmService.streamResponse(text);
      
      String fullResponse = '';
      
      await for (final token in stream) {
        setState(() {
          fullResponse += token;
          
          // Update or create AI message
          if (messages.isNotEmpty && !messages.last.isUser) {
            messages[messages.length - 1] = ChatMessage(
              text: fullResponse,
              isUser: false,
            );
          } else {
            messages.add(ChatMessage(text: fullResponse, isUser: false));
          }
        });
      }
    } catch (e) {
      setState(() {
        messages.add(ChatMessage(
          text: 'Error: $e',
          isUser: false,
        ));
      });
    } finally {
      setState(() => isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat with Tutor')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return Align(
                  alignment: message.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: message.isUser
                          ? Colors.deepPurple
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: message.isUser ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      hintText: 'Ask a question...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: isLoading
                      ? null
                      : () => sendMessage(controller.text),
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  
  ChatMessage({required this.text, required this.isUser});
}
```

---

## 🧪 STEP 5: TEST MODEL LOADING

### **5.1 Test on Emulator**

```bash
# Start emulator
flutter emulators --launch Pixel_5_API_31

# Run app
cd apps/mobile
flutter run

# Check logs
flutter logs | grep "LLM\|Model"
```

### **5.2 Test on Physical Device**

```bash
# Connect device via USB
adb devices

# Run app
flutter run -d <device-id>

# Monitor performance
flutter run --profile

# Check model loading time
# Should be <5 seconds on Infinix-Note50
```

### **5.3 Test Inference**

```bash
# In chat screen:
# 1. Type: "What is 2+2?"
# 2. Wait for response
# 3. Check response time (should be <10 seconds)
# 4. Check battery usage
# 5. Check memory usage
```

---

## 📊 STEP 6: OPTIMIZE MODEL PERFORMANCE

### **6.1 Quantization**

```bash
# Model is already quantized (Q4_K_M)
# This provides:
# - 2.5GB file size
# - ~4GB RAM usage
# - ~28 tokens/second inference speed
# - Acceptable quality
```

### **6.2 Caching**

```dart
// In llm_service.dart
// Cache model in memory after first load
// Avoid reloading on each request
```

### **6.3 Batch Processing**

```dart
// Process multiple requests in sequence
// Avoid concurrent inference (uses too much memory)
```

---

## 🚀 STEP 7: INTEGRATE WITH CHAT SCREEN

### **7.1 Update HomeScreen**

```dart
// In home_screen.dart
// Replace chat tab placeholder with actual ChatScreen

Widget _buildChatTab() {
  return ChatScreen(llmService: widget.llmService);
}
```

### **7.2 Test End-to-End**

```bash
# 1. Launch app
# 2. Navigate to Chat tab
# 3. Ask a question
# 4. Verify response is generated
# 5. Check performance metrics
```

---

## 📋 MODEL INTEGRATION CHECKLIST

- [ ] Model downloaded (2.5GB)
- [ ] Model placed in assets/models/
- [ ] pubspec.yaml updated with asset
- [ ] LLM service implemented
- [ ] Chat screen implemented
- [ ] Model loading tested
- [ ] Inference tested
- [ ] Performance acceptable
- [ ] Memory usage acceptable
- [ ] Battery usage acceptable
- [ ] End-to-end testing complete

---

## 🚨 TROUBLESHOOTING

### **Issue: Model File Not Found**

```bash
# Check file exists
ls -lh apps/mobile/assets/models/gemma-3-1b-q4_k_m.gguf

# Check pubspec.yaml has asset
grep "gemma-3-1b-q4_k_m.gguf" apps/mobile/pubspec.yaml

# Rebuild app
flutter clean
flutter pub get
flutter run
```

### **Issue: Model Loading Fails**

```bash
# Check logs
flutter logs | grep "Model\|LLM"

# Verify model file integrity
file apps/mobile/assets/models/gemma-3-1b-q4_k_m.gguf
# Should show: data

# Check llamadart is installed
grep "llamadart" apps/mobile/pubspec.yaml
```

### **Issue: Inference is Slow**

```bash
# Check device specs
# Infinix-Note50: 4GB RAM, Helio G99 processor

# Reduce batch size
# Use quantized model (already done)
# Disable other apps

# Expected speed: 20-30 tokens/second
```

### **Issue: Out of Memory**

```bash
# Check available RAM
# Infinix-Note50: 4GB total, ~2GB available

# Model uses ~1.5GB
# App uses ~500MB
# Total: ~2GB (acceptable)

# If OOM:
# 1. Close other apps
# 2. Restart device
# 3. Use smaller model (not recommended)
```

---

## 📞 NEXT STEPS

1. [ ] Download Gemma 3 1B GGUF model
2. [ ] Place model in assets/models/
3. [ ] Update pubspec.yaml
4. [ ] Implement LLM service
5. [ ] Implement chat screen
6. [ ] Test model loading
7. [ ] Test inference
8. [ ] Optimize performance
9. [ ] End-to-end testing

---

Generated: 2026-08-22  
Target Integration: Week 17-18 (2026-09-29 to 2026-10-06)
