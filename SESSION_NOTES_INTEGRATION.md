# 📝 Session Notes Integration Guide

## 🎯 **What You Need to Do**

To add note generation to your existing session flow, you have **3 options**:

## **Option 1: Use the New Session Page (Recommended)**

### **Step 1: Replace Your Current Session Page**
```dart
// In your routing (main.dart or wherever you define routes)
// Change from:
// '/session': (context) => SessionPage(...)

// To:
'/session': (context) => SessionWithNotesPage(...)
```

### **Step 2: Update Navigation**
```dart
// In start_visit_page.dart, change the navigation to:
Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (context) => SessionWithNotesPage(
      visit: createdVisit,
      client: selectedClient,
    ),
  ),
);
```

## **Option 2: Add Notes to Existing Session Page**

### **Step 1: Add Imports**
```dart
// Add to lib/screens/session_page.dart
import '../services/note_drafting_service.dart';
import '../widgets/note_drafting_widget.dart';
```

### **Step 2: Add State Variables**
```dart
// Add to _SessionPageState class
bool _showNotes = false;
String _generatedNote = '';
```

### **Step 3: Add Note Generation Method**
```dart
// Add this method to _SessionPageState
Future<void> _generateNotes() async {
  if (widget.visit == null || widget.client == null) return;

  try {
    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
    final sessionRecords = sessionProvider.sessionRecords;
    
    final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
    final assignments = await fileMakerService.getProgramAssignments(widget.client!.id);

    final sessionData = NoteDraftingService.convertSessionRecordsToSessionData(
      visit: widget.visit!,
      client: widget.client!,
      sessionRecords: sessionRecords,
      assignments: assignments,
      providerName: 'Jane Doe, BCBA',
      npi: 'ATYPICAL',
    );

    final noteDraft = await NoteDraftingService.generateNoteDraft(
      session: sessionData,
      ragContext: 'Use SOAP tone; focus on measurable outcomes.',
    );

    setState(() {
      _generatedNote = noteDraft;
      _showNotes = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Clinical note generated successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error generating note: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

### **Step 4: Add Generate Notes Button**
```dart
// Add to AppBar actions in build method
if (!_showNotes)
  IconButton(
    onPressed: _generateNotes,
    icon: const Icon(Icons.auto_awesome),
    tooltip: 'Generate Clinical Notes',
  ),
```

### **Step 5: Add Notes Display**
```dart
// Add after the session info card in build method
if (_showNotes) ...[
  Card(
    color: Colors.blue[50],
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notes, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Generated Clinical Note',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _showNotes = false),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: SelectableText(
              _generatedNote,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    ),
  ),
  const SizedBox(height: 16),
],
```

## **Option 3: Add Notes Widget to Existing Page**

### **Simple Integration**
```dart
// Add this anywhere in your session page build method
CompactNoteDraftingWidget(
  session: sessionData, // Convert your visit/client to SessionData
  onNoteChanged: (note) => setState(() => currentNote = note),
)
```

## 🚀 **How It Works**

### **Before Ending Session:**
1. **Collect Data** - Use your existing data collection widgets
2. **Save Data** - Click "Save Data" on each program card
3. **Generate Notes** - Click the "Generate Notes" button (✨ icon)
4. **Review Notes** - Generated note appears in a card
5. **End Session** - Click "End Session" (note is saved automatically)

### **What Happens:**
- ✅ **AI analyzes your session data** (trials, frequency, duration, etc.)
- ✅ **Generates professional clinical note** in SOAP format
- ✅ **Shows note in a clean, readable format**
- ✅ **Allows you to copy/edit the note**
- ✅ **Saves note when you end the session**

## 📱 **User Experience**

### **Session Flow:**
```
1. Start Session → 2. Collect Data → 3. Save Data → 4. Generate Notes → 5. End Session
```

### **Visual Indicators:**
- **✨ Icon** - Generate notes button
- **📝 Card** - Generated note display
- **💾 Icon** - Save note button
- **🛑 Button** - End session (with note confirmation)

## 🎯 **Quick Start (5 Minutes)**

**Easiest way to get started:**

1. **Copy the new session page:**
   ```bash
   cp lib/screens/session_with_notes_page.dart lib/screens/session_page.dart
   ```

2. **Update your routing to use the new page**

3. **Test it:**
   - Start a session
   - Collect some data
   - Click the ✨ button to generate notes
   - See the professional note appear!

## ✅ **Benefits**

- **Professional Notes** - AI-generated clinical documentation
- **Time Saving** - No manual note writing
- **Consistent Format** - SOAP format for all notes
- **Data Integration** - Uses your actual session data
- **Easy to Use** - One-click note generation
- **Payer Ready** - Professional quality for insurance

---

**🎉 Your session flow now includes AI-powered note generation!**

**Next Steps:**
1. Choose an integration option
2. Test with a real session
3. Customize the RAG context if needed
4. Enjoy professional clinical notes! 📝✨
