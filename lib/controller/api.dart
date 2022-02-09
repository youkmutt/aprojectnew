import 'package:http/http.dart' as http;
import 'dart:convert';

class API {
  Future<dynamic> apiPost(String url,dynamic body) async {
    var tempParam = jsonDecode(body.toString());
    tempParam['isMobile']= true;
    body = jsonEncode(tempParam);

    final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: body,
        encoding: Encoding.getByName("utf-8")
    );

    return response;
  }

}