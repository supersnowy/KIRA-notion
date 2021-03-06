import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kira_auth/models/account.dart';
import 'package:kira_auth/models/cosmos_account.dart';
import 'package:kira_auth/services/export.dart';
import 'package:kira_auth/service_manager.dart';

class QueryService {
  static Future<CosmosAccount> getAccountData(Account account) async {
    final _storageService = getIt<StorageService>();
    var apiUrl = await _storageService.getLiveRpcUrl();

    final endpoint = apiUrl[0] + "/api/cosmos/auth/accounts/${account.bech32Address}";
    var response = await http.get(endpoint, headers: {'Access-Control-Allow-Origin': apiUrl[1]});

    if (response.statusCode != 200) {
      throw Exception(
        "Expected status code 200 but got ${response.statusCode} - ${response.body}",
      );
    }

    var data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data.containsKey("account")) {
      data = data["account"];
    }

    // var headerData = response.headers;
    // var signature = headerData['interx_signature'];
    return CosmosAccount.fromJson(data);
  }
}
