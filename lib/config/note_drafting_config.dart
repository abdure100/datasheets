/// Configuration for the Note Drafting Service
class NoteDraftingConfig {
  // API Configuration
  static const String apiUrl = 'https://arawello.ai/v1/chat/completions';
  static const String model = 'meta-llama/Meta-Llama-3.1-8B-Instruct';
  static const double temperature = 0.3;
  static const int maxTokens = 500;
  
  // Optional: Add your API key here
  // For production, consider using environment variables or secure storage
  static const String apiKey = 'ca4d912f0e81d40a50293afdd7547fe604937bf638e4cad6eba69527d5810289'; // Set to your API key if needed
  
  // Alternative API configurations
  static const String openaiApiUrl = 'https://api.openai.com/v1/chat/completions';
  static const String? openaiApiKey = null; // Set to your OpenAI API key if needed
  
  // Default RAG context for note generation
  static const String defaultRagContext = '''
- Use SOAP tone; avoid speculation.
- Payer requires explicit minutes and CPT/Modifiers alignment.
- Focus on measurable outcomes and data-driven observations.
- Include specific behavioral observations and interventions used.
- Maintain professional, objective tone suitable for payer review.
- If information is missing, state it plainly (e.g., "time_out not provided").
''';
  
  // System prompt for note generation
  static const String systemPrompt = '''
You are a clinical documentation assistant for a behavioral health / ABA EMR.
- Generate concise, factual first-draft notes from structured inputs.
- Do not fabricate; only use provided data and context.
- Maintain professional, objective tone suitable for payer review.
- If information is missing, state it plainly (e.g., "time_out not provided").
''';
  
  // Get API key (checks multiple sources)
  static String? getApiKey() {
    // First check if apiKey is set
    if (apiKey != null && apiKey!.isNotEmpty) {
      return apiKey;
    }
    
    // Check for OpenAI API key
    if (openaiApiKey != null && openaiApiKey!.isNotEmpty) {
      return openaiApiKey;
    }
    
    // In a real app, you might check environment variables here
    // For now, return null to indicate no API key is configured
    return null;
  }
  
  // Get API URL (checks configuration)
  static String getApiUrl() {
    // If OpenAI API key is available, use OpenAI endpoint
    if (openaiApiKey != null && openaiApiKey!.isNotEmpty) {
      return openaiApiUrl;
    }
    
    // Otherwise, use the default arawello.ai endpoint
    return apiUrl;
  }
  
  // Check if API is configured
  static bool get isConfigured => getApiKey() != null;
  
  // Get configuration summary
  static Map<String, dynamic> getConfigSummary() {
    return {
      'apiUrl': getApiUrl(),
      'model': model,
      'temperature': temperature,
      'maxTokens': maxTokens,
      'hasApiKey': isConfigured,
      'apiKeySource': apiKey != null ? 'noteDrafting' : 
                     openaiApiKey != null ? 'openai' : 'none',
    };
  }
}
