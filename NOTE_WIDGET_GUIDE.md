# 📝 Note Drafting Widget Guide

## 📋 **Overview**

You now have comprehensive Flutter widgets for AI-powered clinical note generation! These widgets integrate seamlessly with your existing ABA data collection app.

## 🎯 **Available Widgets**

### **1. NoteDraftingWidget** - Full-Featured Widget
- Complete note generation interface
- AI-powered note creation
- Streaming support
- RAG context customization
- Save/clear functionality
- Error handling

### **2. CompactNoteDraftingWidget** - Space-Saving Widget
- Minimal interface for tight spaces
- Quick note generation
- Essential functionality only

### **3. NotePreviewWidget** - Display Widget
- Show generated notes
- Edit/regenerate options
- Session information display

## 🚀 **Quick Start**

### **Basic Usage**
```dart
import 'package:datasheets/widgets/note_drafting_widget.dart';
import 'package:datasheets/services/note_drafting_service.dart';

// Create session data
final session = SessionData(
  providerName: 'Jane Doe, BCBA',
  npi: 'ATYPICAL',
  clientName: 'A.B.',
  dob: '2015-08-03',
  date: '2025-10-18',
  startTime: '09:00',
  endTime: '10:00',
  durationMinutes: 60,
  serviceName: 'Adaptive Behavior Treatment',
  cpt: '97153',
  modifiers: ['UC'],
  pos: '11',
  goalsList: ['task independence', 'manding'],
  behaviors: 'Calm, cooperative; brief off-task moments.',
  interventions: 'Least-to-most prompting; differential reinforcement.',
  dataSummary: 'Achieved ~90% independence on targeted tasks.',
  caregiver: 'Parent observed; reinforced strategies.',
  plan: 'Increase task complexity; fade prompts further.',
);

// Use the widget
NoteDraftingWidget(
  session: session,
  onNoteChanged: (note) => print('Note changed: $note'),
  onNoteSaved: (note) => print('Note saved: $note'),
)
```

### **Compact Usage**
```dart
CompactNoteDraftingWidget(
  session: session,
  onNoteChanged: (note) => print('Note changed: $note'),
)
```

### **Preview Usage**
```dart
NotePreviewWidget(
  note: generatedNote,
  session: session,
  onEdit: () => print('Edit note'),
  onRegenerate: () => print('Regenerate note'),
)
```

## 🎨 **Widget Features**

### **NoteDraftingWidget Features**
- ✅ **AI Note Generation** - One-click note creation
- ✅ **Streaming Generation** - Real-time note building
- ✅ **RAG Context** - Custom instructions for AI
- ✅ **Session Display** - Shows client and session info
- ✅ **Error Handling** - User-friendly error messages
- ✅ **Save/Clear** - Note management functions
- ✅ **Read-Only Mode** - For viewing only
- ✅ **Status Indicators** - Loading and progress states

### **CompactNoteDraftingWidget Features**
- ✅ **Quick Generation** - Simple AI note creation
- ✅ **Space Efficient** - Minimal UI footprint
- ✅ **Essential Functions** - Core functionality only
- ✅ **Error Handling** - Basic error display

### **NotePreviewWidget Features**
- ✅ **Note Display** - Clean note presentation
- ✅ **Session Info** - Client and session details
- ✅ **Action Buttons** - Edit and regenerate options
- ✅ **Selectable Text** - Copy note content

## 📱 **Integration Examples**

### **1. Add to Session Page**
```dart
// In your session page
class SessionPage extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Your existing session UI
          Expanded(
            child: NoteDraftingWidget(
              session: currentSession,
              onNoteChanged: (note) {
                setState(() {
                  currentNote = note;
                });
              },
              onNoteSaved: (note) {
                // Save to database
                saveNoteToDatabase(note);
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

### **2. Add to Session Details**
```dart
// In session details page
class SessionDetailsPage extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Session details
          SessionInfoWidget(session: session),
          
          // Note generation
          CompactNoteDraftingWidget(
            session: session,
            onNoteChanged: (note) {
              // Update note in real-time
            },
          ),
          
          // Show generated note
          if (generatedNote.isNotEmpty)
            NotePreviewWidget(
              note: generatedNote,
              session: session,
              onEdit: () => _editNote(),
              onRegenerate: () => _regenerateNote(),
            ),
        ],
      ),
    );
  }
}
```

### **3. Add to Modal/Dialog**
```dart
// In a modal dialog
void showNoteDraftingModal(BuildContext context, SessionData session) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      child: Container(
        height: 600,
        child: NoteDraftingWidget(
          session: session,
          onNoteSaved: (note) {
            Navigator.pop(context);
            // Handle saved note
          },
        ),
      ),
    ),
  );
}
```

## ⚙️ **Configuration Options**

### **NoteDraftingWidget Parameters**
```dart
NoteDraftingWidget(
  session: session,                    // Required: Session data
  initialNote: 'Existing note...',    // Optional: Pre-filled note
  onNoteChanged: (note) {},           // Optional: Note change callback
  onNoteSaved: (note) {},             // Optional: Note save callback
  readOnly: false,                     // Optional: Read-only mode
  ragContext: 'Custom instructions',   // Optional: AI instructions
)
```

### **CompactNoteDraftingWidget Parameters**
```dart
CompactNoteDraftingWidget(
  session: session,                    // Required: Session data
  initialNote: 'Existing note...',    // Optional: Pre-filled note
  onNoteChanged: (note) {},           // Optional: Note change callback
  readOnly: false,                     // Optional: Read-only mode
)
```

### **NotePreviewWidget Parameters**
```dart
NotePreviewWidget(
  note: 'Generated note...',          // Required: Note content
  session: session,                    // Required: Session data
  onEdit: () {},                       // Optional: Edit callback
  onRegenerate: () {},                 // Optional: Regenerate callback
)
```

## 🎯 **Use Cases**

### **1. Session Completion**
- Generate notes after data collection
- Review and edit AI-generated content
- Save notes to database

### **2. Note Review**
- Display existing notes
- Allow editing and regeneration
- Show session context

### **3. Quick Notes**
- Fast note generation in tight spaces
- Essential functionality only
- Minimal UI footprint

### **4. Note Templates**
- Pre-fill with existing notes
- Customize AI instructions
- Consistent note format

## 🔧 **Customization**

### **Custom RAG Context**
```dart
NoteDraftingWidget(
  session: session,
  ragContext: '''
- Use SOAP format
- Focus on measurable outcomes
- Include specific data points
- Maintain professional tone
  ''',
)
```

### **Read-Only Mode**
```dart
NoteDraftingWidget(
  session: session,
  readOnly: true,  // Disables editing and generation
)
```

### **Custom Callbacks**
```dart
NoteDraftingWidget(
  session: session,
  onNoteChanged: (note) {
    // Real-time updates
    updateNotePreview(note);
  },
  onNoteSaved: (note) {
    // Save to database
    saveNote(note);
    showSuccessMessage();
  },
)
```

## 🧪 **Testing**

### **Run Widget Tests**
```bash
dart test_note_widget.dart
```

### **Test Different Scenarios**
- High-performing sessions
- Challenging sessions
- Mixed performance sessions
- Different session types

## 📊 **Widget Comparison**

| Feature | NoteDraftingWidget | CompactNoteDraftingWidget | NotePreviewWidget |
|---------|-------------------|---------------------------|-------------------|
| AI Generation | ✅ | ✅ | ❌ |
| Streaming | ✅ | ❌ | ❌ |
| RAG Context | ✅ | ❌ | ❌ |
| Save/Clear | ✅ | ❌ | ❌ |
| Edit/Regenerate | ✅ | ❌ | ✅ |
| Session Display | ✅ | ❌ | ✅ |
| Space Usage | Large | Small | Medium |
| Use Case | Full Interface | Quick Notes | Display Only |

## 🎉 **Success Metrics**

- ✅ **3 Widget Types** - Full, compact, and preview
- ✅ **AI Integration** - Seamless note generation
- ✅ **Real-time Updates** - Live note editing
- ✅ **Error Handling** - User-friendly messages
- ✅ **Customizable** - Flexible configuration
- ✅ **Responsive** - Works on different screen sizes
- ✅ **Professional** - Clinical note quality
- ✅ **Easy Integration** - Drop-in widgets

---

**📝 Your note drafting widgets are ready for production use!**

**🎯 Next Steps:**
1. Integrate widgets into your existing pages
2. Test with real session data
3. Customize RAG context for your needs
4. Add to your app's navigation

**💡 Pro Tip:** Start with the `CompactNoteDraftingWidget` for quick integration, then upgrade to the full `NoteDraftingWidget` for complete functionality!
