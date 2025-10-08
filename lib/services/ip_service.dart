import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class IPService {
  static Future<String?> getDeviceIPAddress() async {
    try {
      // Try to get IP from multiple sources for better reliability
      final List<Future<String?>> ipFutures = [
        _getIPFromHttpbin(),
        _getIPFromIpify(),
        _getIPFromIpapi(),
      ];

      // Wait for the first successful result
      for (final future in ipFutures) {
        try {
          final ip = await future.timeout(const Duration(seconds: 5));
          if (ip != null && ip.isNotEmpty) {
            return ip;
          }
        } catch (e) {
          // Continue to next method if this one fails
          continue;
        }
      }

      // Fallback: try to get local IP (for development/testing)
      return await _getLocalIP();
    } catch (e) {
      // If all methods fail, return a default value
      return 'unknown';
    }
  }

  static Future<String?> _getIPFromHttpbin() async {
    try {
      final response = await http.get(
        Uri.parse('https://httpbin.org/ip'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['origin'] as String?;
      }
    } catch (e) {
      // Ignore errors and try next method
    }
    return null;
  }

  static Future<String?> _getIPFromIpify() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.ipify.org?format=json'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['ip'] as String?;
      }
    } catch (e) {
      // Ignore errors and try next method
    }
    return null;
  }

  static Future<String?> _getIPFromIpapi() async {
    try {
      final response = await http.get(
        Uri.parse('https://ipapi.co/ip/'),
        headers: {'Accept': 'text/plain'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        return response.body.trim();
      }
    } catch (e) {
      // Ignore errors and try next method
    }
    return null;
  }

  static Future<String?> _getLocalIP() async {
    try {
      // For local development, try to get the device's local IP
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      // Ignore errors
    }
    return null;
  }
}
