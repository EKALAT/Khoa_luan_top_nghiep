import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

typedef TokenReader = String? Function();
typedef BaseUrlReader = String Function();

class MultipartFilePayload {
  const MultipartFilePayload({
    required this.field,
    required this.path,
    this.filename,
  });

  final String field;
  final String path;
  final String? filename;
}

class ApiClient {
  ApiClient({
    required BaseUrlReader baseUrlReader,
    required TokenReader tokenReader,
    http.Client? httpClient,
    Duration requestTimeout = const Duration(seconds: 12),
  }) : _baseUrlReader = baseUrlReader,
       _tokenReader = tokenReader,
       _httpClient = httpClient ?? http.Client(),
       _requestTimeout = requestTimeout;

  final BaseUrlReader _baseUrlReader;
  final TokenReader _tokenReader;
  final http.Client _httpClient;
  final Duration _requestTimeout;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParameters,
    bool authenticated = true,
  }) async {
    final response = await _send(
      () => _httpClient.get(
        _buildUri(path, queryParameters),
        headers: _buildHeaders(authenticated: authenticated),
      ),
    );

    return _decodeResponse(response);
  }

  Future<List<int>> getBytes(
    String path, {
    Map<String, String>? queryParameters,
    bool authenticated = true,
  }) async {
    final response = await _send(
      () => _httpClient.get(
        _buildUri(path, queryParameters),
        headers: _buildHeaders(authenticated: authenticated),
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException.fromResponse(response.statusCode, response.body);
    }

    return response.bodyBytes;
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    bool authenticated = true,
  }) async {
    final response = await _send(
      () => _httpClient.post(
        _buildUri(path, queryParameters),
        headers: _buildHeaders(authenticated: authenticated),
        body: jsonEncode(body ?? const <String, dynamic>{}),
      ),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    bool authenticated = true,
  }) async {
    final response = await _send(
      () => _httpClient.put(
        _buildUri(path, queryParameters),
        headers: _buildHeaders(authenticated: authenticated),
        body: jsonEncode(body ?? const <String, dynamic>{}),
      ),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, String>? queryParameters,
    bool authenticated = true,
  }) async {
    final response = await _send(
      () => _httpClient.delete(
        _buildUri(path, queryParameters),
        headers: _buildHeaders(authenticated: authenticated),
      ),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    Map<String, String>? fields,
    List<MultipartFilePayload>? files,
    bool authenticated = true,
  }) async {
    final request = http.MultipartRequest('POST', _buildUri(path, null));
    request.headers.addAll(
      _buildHeaders(authenticated: authenticated, includeContentType: false),
    );

    if (fields != null && fields.isNotEmpty) {
      request.fields.addAll(fields);
    }

    for (final file in files ?? const <MultipartFilePayload>[]) {
      request.files.add(
        await http.MultipartFile.fromPath(
          file.field,
          file.path,
          filename: file.filename,
        ),
      );
    }

    final response = await _sendStreamed(() => request.send());
    return _decodeResponse(response);
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request().timeout(_requestTimeout);
    } on TimeoutException {
      throw ApiException.timeout(_requestTimeout);
    } on http.ClientException catch (error) {
      throw ApiException.network(details: error.message);
    }
  }

  Future<http.Response> _sendStreamed(
    Future<http.StreamedResponse> Function() request,
  ) async {
    try {
      final response = await request().timeout(_requestTimeout);
      return http.Response.fromStream(response);
    } on TimeoutException {
      throw ApiException.timeout(_requestTimeout);
    } on http.ClientException catch (error) {
      throw ApiException.network(details: error.message);
    }
  }

  Uri _buildUri(String path, Map<String, String>? queryParameters) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final baseUrl = _baseUrlReader().replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$baseUrl$normalizedPath').replace(
      queryParameters:
          queryParameters == null || queryParameters.isEmpty
              ? null
              : queryParameters,
    );
  }

  Map<String, String> _buildHeaders({
    required bool authenticated,
    bool includeContentType = true,
  }) {
    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (includeContentType) {
      headers['Content-Type'] = 'application/json';
    }

    final token = _tokenReader();
    if (authenticated && token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException.fromResponse(response.statusCode, response.body);
    }

    if (response.body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = _tryDecodeBody(response.body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    return <String, dynamic>{'data': decoded};
  }

  dynamic _tryDecodeBody(String body) {
    try {
      return jsonDecode(body);
    } on FormatException {
      throw ApiException.invalidResponse();
    }
  }
}
