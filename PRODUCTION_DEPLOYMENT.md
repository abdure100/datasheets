# Production Deployment Guide

## Configuration Changes Required

### 1. Update MCP API Base URL (NEW)

Edit `lib/config/app_config.dart`:

```dart
// MCP API Configuration - UPDATE FOR PRODUCTION
static const String mcpBaseUrl = 'https://YOUR_PRODUCTION_DOMAIN.com/api';
// Example: 'https://your-domain.com/api'

// Sanctum Token (store securely in production)
static String? sanctumToken; // Set this from secure storage
```

**What to change:**
- `mcpBaseUrl`: Your production MCP API base URL
- `sanctumToken`: Your Laravel Sanctum authentication token (should be stored securely, not hardcoded)

### 2. Update FileMaker Server URL and Credentials

Edit `lib/config/app_config.dart`:

```dart
class AppConfig {
  // PRODUCTION Configuration
  static const String baseUrl = 'https://YOUR_PRODUCTION_SERVER.com/fmi/data/vLatest';
  static const String database = 'YOUR_PRODUCTION_DATABASE';
  static const String username = 'YOUR_PRODUCTION_USERNAME';
  static const String password = 'YOUR_PRODUCTION_PASSWORD';
  
  // Keep these the same
  static const String appName = 'DataSheets';
  static const String appVersion = '1.0.0';
  static const int connectionTimeout = 30;
  static const int receiveTimeout = 30;
}
```

### 3. Update Note Drafting API (if needed)

Edit `lib/config/note_drafting_config.dart` if your note generation service URL or API key needs to change:

```dart
static const String apiUrl = 'https://YOUR_PRODUCTION_API_URL/v1/chat/completions';
static const String apiKey = 'YOUR_PRODUCTION_API_KEY';
```

### 4. Checklist Before Deployment

- [ ] Update `mcpBaseUrl` to production MCP API server
- [ ] Set up secure storage for Sanctum token (don't hardcode)
- [ ] Update `baseUrl` to production FileMaker server
- [ ] Update `database` name if different in production
- [ ] Update `username` and `password` for production
- [ ] Verify production FileMaker server has:
  - Data API enabled
  - Same layout names (`api_appointments`, `api_staffs`, etc.)
  - Same field names (`assignedto_name`, `staff_title`, etc.)
- [ ] Test authentication with production credentials
- [ ] Test note generation API if URL changed
- [ ] Remove or secure any hardcoded credentials
- [ ] Build production app (not debug)
- [ ] Test on production server before release

### 5. FileMaker Server Requirements

Ensure your production FileMaker server has:
- **Layouts**: `api_appointments`, `api_staffs`, `api_sessiondata`, `api_patients`, `dapi-patient_programs`
- **Fields in `api_appointments`**:
  - `PrimaryKey` (visit ID)
  - `assignedto_name` (staff name)
  - `staff_title` (staff title/credential)
  - `visit_notes` (notes field)
  - All other required fields

### 6. Testing After Deployment

**MCP API Testing:**
1. Test MCP chat endpoint with visitId and assignmentId
2. Test context retrieval endpoint
3. Verify Sanctum token authentication works
4. Test OpenAI-compatible completions endpoint

**FileMaker Testing:**

1. Test login with production credentials
2. Test creating a visit
3. Test saving session data
4. Test generating notes
5. Test saving notes to `visit_notes` field
6. Verify `assignedto_name` and `staff_title` are populated correctly

## MCP API Integration

### Basic Usage

```dart
import 'package:datasheets/services/mcp_service.dart';
import 'package:datasheets/config/app_config.dart';

// Initialize MCP service with token
final mcpService = MCPService(
  baseUrl: AppConfig.mcpBaseUrl, // or override with custom URL
  token: AppConfig.sanctumToken ?? 'YOUR_TOKEN_HERE',
);

// Send chat message with context
final response = await mcpService.chat(
  message: 'Tell me about my recent sessions',
  visitId: '12345',
  assignmentId: '67890',
);

print('AI Response: ${response['response']}');

// Get context only
final context = await mcpService.getContext(
  visitId: '12345',
  assignmentId: '67890',
);
```

### Integration with Note Generation

You can replace or supplement the existing note generation with MCP:

```dart
// In note_drafting_service.dart or similar
final mcpService = MCPService(token: sanctumToken);

final response = await mcpService.completions(
  messages: [
    {'role': 'user', 'content': 'Generate a clinical note for this session'}
  ],
  visitId: visit.id,
  assignmentId: assignment.id,
  model: 'meta-llama/Meta-Llama-3.1-8B-Instruct',
);
```

## Security Notes

⚠️ **IMPORTANT**: Never commit production credentials to version control!

- The `app_config.dart` file contains sensitive credentials
- **Store Sanctum token securely** - use `flutter_secure_storage` or similar
- Consider using environment variables or secure configuration management
- Use different credentials for dev/staging/production
- **MCP tokens should never be hardcoded** - use secure storage

