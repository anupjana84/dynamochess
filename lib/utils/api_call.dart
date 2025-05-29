import 'dart:convert';

import 'package:dynamochess/models/network_model.dart';
import 'package:http/http.dart' as http;

class ApiCall {
  static Future<NetworkResponse> getApiCall(String url) async {
    const token = "";
    try {
      http.Response response = await http.get(Uri.parse(url), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return NetworkResponse(
          statusCode: response.statusCode,
          isSuccess: true,
          responseData: data,
        );
      } else if (response.statusCode == 401) {
        return NetworkResponse(
          statusCode: response.statusCode,
          isSuccess: false,
        );
      } else {
        return NetworkResponse(
          statusCode: response.statusCode,
          isSuccess: false,
        );
      }
    } catch (e) {
      return NetworkResponse(
        statusCode: -1,
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }

  static Future<NetworkResponse> postApiCall(String url,
      {Map<String, dynamic>? body}) async {
    const token = "";

    try {
      http.Response response = await http.post(Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        return NetworkResponse(
          statusCode: response.statusCode,
          isSuccess: true,
          responseData: data,
        );
      } else if (response.statusCode == 401 || response.statusCode == 400) {
        // print(response.statusCode);
        // print(response.body);
        return NetworkResponse(
          statusCode: response.statusCode,
          isSuccess: false,
          errorMessage: response.body,
        );
      } else {
        return NetworkResponse(
          statusCode: response.statusCode,
          isSuccess: false,
        );
      }
    } catch (e) {
      // print(e.toString());
      return NetworkResponse(
        statusCode: -1,
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }
}
