import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class EmailService extends ChangeNotifier {
  final String _baseUrl = kIsWeb
      ? 'https://gmail-backend-1-wlx4.onrender.com/api/email'
      : 'https://gmail-backend-1-wlx4.onrender.com/api/email';

  Future<List<Map<String, dynamic>>> listEmails(String folder, {String? labelId}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    if (token == null) throw 'No token found';

    final uri = Uri.parse('$_baseUrl/list/$folder${labelId != null ? "?labelId=$labelId" : ""}');
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    throw jsonDecode(response.body)['error'] ?? 'Failed to fetch emails';
  }

  Future<Map<String, dynamic>> getEmailDetails(String emailId) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt');
  if (token == null) throw 'No token found';

  final uri = Uri.parse('$_baseUrl/$emailId');
  final response = await http.get(
    uri,
    headers: {'Authorization': 'Bearer $token'},
  );
  if (response.statusCode == 200) {
    return Map<String, dynamic>.from(jsonDecode(response.body));
  }
  throw jsonDecode(response.body)['error'] ?? 'Failed to fetch email details';
}

  Future<void> sendEmail({
    required List<String> recipients,
    List<String>? cc,
    List<String>? bcc,
    required String subject,
    required String body,
    List<XFile>? attachments,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    if (token == null) throw 'No token found';

    var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/send'));
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['recipients'] = jsonEncode(recipients);
    if (cc != null) request.fields['cc'] = jsonEncode(cc);
    if (bcc != null) request.fields['bcc'] = jsonEncode(bcc);
    request.fields['subject'] = subject;
    request.fields['body'] = body;

    if (attachments != null) {
      for (var file in attachments) {
        final mimeType = file.mimeType ?? _getMimeType(file.name);
        if (kIsWeb) {
          final bytes = await file.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes(
            'attachments',
            bytes,
            filename: file.name,
            contentType: MediaType.parse(mimeType),
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath(
            'attachments',
            file.path,
            contentType: MediaType.parse(mimeType),
          ));
        }
      }
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    if (response.statusCode != 200) {
      throw jsonDecode(responseBody)['error'] ?? 'Failed to send email';
    }
  }

  Future<void> saveDraft({
    List<String>? recipients,
    List<String>? cc,
    List<String>? bcc,
    String? subject,
    String? body,
    List<XFile>? attachments,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    if (token == null) throw 'No token found';

    var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/save-draft'));
    request.headers['Authorization'] = 'Bearer $token';
    if (recipients != null) request.fields['recipients'] = jsonEncode(recipients);
    if (cc != null) request.fields['cc'] = jsonEncode(cc);
    if (bcc != null) request.fields['bcc'] = jsonEncode(bcc);
    if (subject != null) request.fields['subject'] = subject;
    if (body != null) request.fields['body'] = body;

    if (attachments != null) {
      for (var file in attachments) {
        final mimeType = file.mimeType ?? _getMimeType(file.name);
        if (kIsWeb) {
          final bytes = await file.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes(
            'attachments',
            bytes,
            filename: file.name,
            contentType: MediaType.parse(mimeType),
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath(
            'attachments',
            file.path,
            contentType: MediaType.parse(mimeType),
          ));
        }
      }
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    if (response.statusCode != 200) {
      throw jsonDecode(responseBody)['error'] ?? 'Failed to save draft';
    }
  }

  Future<void> reply(String emailId, String body, List<XFile>? attachments) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    if (token == null) throw 'No token found';

    var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/reply/$emailId'));
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['body'] = body;

    if (attachments != null) {
      for (var file in attachments) {
        final mimeType = file.mimeType ?? _getMimeType(file.name);
        if (kIsWeb) {
          final bytes = await file.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes(
            'attachments',
            bytes,
            filename: file.name,
            contentType: MediaType.parse(mimeType),
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath(
            'attachments',
            file.path,
            contentType: MediaType.parse(mimeType),
          ));
        }
      }
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    if (response.statusCode != 200) {
      throw jsonDecode(responseBody)['error'] ?? 'Failed to reply';
    }
  }

  Future<void> forward(String emailId, List<String> recipients, String body, List<XFile>? attachments) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    if (token == null) throw 'No token found';

    var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/forward/$emailId'));
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['recipients'] = jsonEncode(recipients);
    request.fields['body'] = body;

    if (attachments != null) {
      for (var file in attachments) {
        final mimeType = file.mimeType ?? _getMimeType(file.name);
        if (kIsWeb) {
          final bytes = await file.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes(
            'attachments',
            bytes,
            filename: file.name,
            contentType: MediaType.parse(mimeType),
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath(
            'attachments',
            file.path,
            contentType: MediaType.parse(mimeType),
          ));
        }
      }
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    if (response.statusCode != 200) {
      throw jsonDecode(responseBody)['error'] ?? 'Failed to forward';
    }
  }

  Future<void> markRead(String emailId, bool isRead) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    if (token == null) throw 'No token found';

    final response = await http.patch(
      Uri.parse('$_baseUrl/mark-read/$emailId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'isRead': isRead}),
    );
    if (response.statusCode != 200) {
      throw jsonDecode(response.body)['error'] ?? 'Failed to mark read';
    }
  }

  Future<void> starEmail(String emailId, bool isStarred) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    if (token == null) throw 'No token found';

    final response = await http.patch(
      Uri.parse('$_baseUrl/star/$emailId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'isStarred': isStarred}),
    );
    if (response.statusCode != 200) {
      throw jsonDecode(response.body)['error'] ?? 'Failed to star email';
    }
  }

  Future<void> moveToTrash(String emailId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    if (token == null) throw 'No token found';

    final response = await http.patch(
      Uri.parse('$_baseUrl/move-to-trash/$emailId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw jsonDecode(response.body)['error'] ?? 'Failed to move to trash';
    }
  }

Future<List<Map<String, dynamic>>> searchEmails({
    String? keyword,
    String? from,
    String? to,
    bool? hasAttachment,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1, // Add pagination
    int limit = 20,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    if (token == null) throw Exception('No token found');

    final queryParams = <String, String>{};
    if (keyword != null && keyword.trim().isNotEmpty) {
      queryParams['keyword'] = Uri.encodeComponent(keyword.trim());
    }
    if (from != null && from.trim().isNotEmpty) {
      queryParams['from'] = Uri.encodeComponent(from.trim());
    }
    if (to != null && to.trim().isNotEmpty) {
      queryParams['to'] = Uri.encodeComponent(to.trim());
    }
    if (hasAttachment != null) {
      queryParams['hasAttachment'] = hasAttachment.toString();
    }
    if (startDate != null) {
      queryParams['startDate'] = startDate.toUtc().toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toUtc().toIso8601String();
    }
    queryParams['page'] = page.toString();
    queryParams['limit'] = limit.toString();

    final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: queryParams);
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 10), onTimeout: () {
      throw Exception('Search request timed out');
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      throw Exception('Invalid response format');
    }
    throw Exception(jsonDecode(response.body)['error'] ?? 'Search failed');
  }

  Future<List<Map<String, dynamic>>> getLabels() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    if (token == null) throw 'No token found';

    final response = await http.get(
      Uri.parse('$_baseUrl/labels'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    throw jsonDecode(response.body)['error'] ?? 'Failed to fetch labels';
  }

  Future<void> createLabel(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    if (token == null) throw 'No token found';

    final response = await http.post(
      Uri.parse('$_baseUrl/labels'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode != 200) {
      throw jsonDecode(response.body)['error'] ?? 'Failed to create label';
    }
  }

  Future<void> deleteLabel(String labelId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    if (token == null) throw 'No token found';

    final response = await http.delete(
      Uri.parse('$_baseUrl/labels/$labelId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw jsonDecode(response.body)['error'] ?? 'Failed to delete label';
    }
  }

  Future<void> renameLabel(String labelId, String newName) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    if (token == null) throw 'No token found';

    final response = await http.patch(
      Uri.parse('$_baseUrl/labels/$labelId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'name': newName}),
    );
    if (response.statusCode != 200) {
      throw jsonDecode(response.body)['error'] ?? 'Failed to rename label';
    }
  }

  Future<void> assignLabel(String emailId, String labelId, String action) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    if (token == null) throw 'No token found';

    final response = await http.patch(
      Uri.parse('$_baseUrl/emails/$emailId/labels'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'labelId': labelId, 'action': action}),
    );
    if (response.statusCode != 200) {
      throw jsonDecode(response.body)['error'] ?? 'Failed to assign/remove label';
    }
  }

  Future<void> setAutoReply(bool enabled, String? message) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    if (token == null) throw 'No token found';

    final response = await http.post(
      Uri.parse('$_baseUrl/auto-reply'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'enabled': enabled, 'message': message}),
    );
    if (response.statusCode != 200) {
      throw jsonDecode(response.body)['error'] ?? 'Failed to set auto reply';
    }
  }

  String _getMimeType(String filename) {
    final extension = filename.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

Future<Map<String, dynamic>> getEmailById(String emailId) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt');
  if (token == null) throw 'No token found';

  final response = await http.get(
    Uri.parse('$_baseUrl/emails/$emailId'),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    return Map<String, dynamic>.from(jsonDecode(response.body));
  } else {
    final error = jsonDecode(response.body)['error'];
    throw Exception('Failed to load email: $error');
  }
}

//delete email by id
Future<void> deleteEmailPermanently(String emailId) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt');
  if (token == null) throw 'No token found';

  // URL đúng là .../api/email/:emailId, không có /emails/
  final uri = Uri.parse('$_baseUrl/$emailId');
  
  final response = await http.delete(
    uri,
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode != 200) {
    final error = jsonDecode(response.body)['error'];
    throw Exception('Failed to permanently delete email: $error');
  }
}
}