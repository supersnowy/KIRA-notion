// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async' show Future;
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:kira_auth/services/export.dart';
import 'package:kira_auth/service_manager.dart';

Future<List<String>> loadInterxURL() async {
  final _storageService = getIt<StorageService>();

  String rpcUrl = await _storageService.getInterxRPCUrl();

  String origin = html.window.location.host + html.window.location.pathname;
  origin = origin.replaceAll('/', '');

  if (rpcUrl == null) return ["", origin];

  bool startsWithHttp = rpcUrl.startsWith('http://') || !rpcUrl.startsWith('http');
  bool noHttp = !rpcUrl.startsWith('http');
  bool isSucceed = false;

  if (rpcUrl != null) {
    if (rpcUrl.startsWith('https://cors-anywhere.kira.network/')) {
    } else if (rpcUrl.startsWith('http://') || !rpcUrl.startsWith('http')) {
      // If there's no HTTP or starts with only HTTP
      rpcUrl = rpcUrl.replaceAll('http://', '');
      List<String> urlArray = rpcUrl.split(':');

      if (urlArray.length == 2) {
        int port = int.tryParse(urlArray[1]);
        if (port == null || port < 1024 || port > 65535) {
          rpcUrl = urlArray[0] + ':11000';
        }
      } else if (noHttp) {
        // Incase of No HTTP
        var response;

        try {
          // Check with raw rpc url
          response = await http.get(rpcUrl + "/api/kira/status",
              headers: {'Access-Control-Allow-Origin': origin}).timeout(Duration(seconds: 3));

          if (response.body.contains('node_info') == true) {
            isSucceed = true;
            _storageService.setLiveRpcUrl(rpcUrl, origin);
          }
        } catch (e) {
          print(e);
        }

        if (isSucceed == false) {
          try {
            // Check Port-Added-Rpc-Url
            response = await http.get("https://" + rpcUrl + "/api/kira/status",
                headers: {'Access-Control-Allow-Origin': origin}).timeout(Duration(seconds: 3));

            if (response.body.contains('node_info') == true) {
              isSucceed = true;
              rpcUrl = 'https://' + rpcUrl;
              _storageService.setLiveRpcUrl(rpcUrl, origin);
            }
          } catch (e) {
            print(e);
          }

          if (isSucceed == false) {
            try {
              // Check after adding https
              response = await http.get('https://' + rpcUrl + ":11000/api/kira/status",
                  headers: {'Access-Control-Allow-Origin': origin}).timeout(Duration(seconds: 3));

              if (response.body.contains('node_info') == true) {
                isSucceed = true;
                rpcUrl = 'https://' + rpcUrl + ':11000';
                _storageService.setLiveRpcUrl(rpcUrl, origin);
              }
            } catch (e) {
              print(e);
            }

            if (isSucceed == false) {
              rpcUrl = rpcUrl + ':11000';
            }
          }
        }
      } else {
        rpcUrl = rpcUrl + ':11000';
      }

      if (isSucceed == false && ((startsWithHttp && !noHttp) || noHttp) && rpcUrl.isNotEmpty) {
        rpcUrl = 'http://' + rpcUrl;
        rpcUrl = 'https://cors-anywhere.kira.network/' + rpcUrl;
        _storageService.setLiveRpcUrl(rpcUrl, origin);
      }
    }

    return [rpcUrl, origin];
  }

  return ["", origin];
}

Future<List> loadConfig() async {
  final _storageService = getIt<StorageService>();

  String config = await rootBundle.loadString('assets/config.json');
  bool autoConnect = json.decode(config)['autoconnect'];
  List<String> rpcUrls = json.decode(config)['api_url'].cast<String>();

  var rpcUrl = rpcUrls[0];
  if (autoConnect == true) await _storageService.setInterxRPCUrl(rpcUrl);

  if (rpcUrl.contains('http://') == false) {
    return [autoConnect, "http://" + rpcUrl];
  }

  return [autoConnect, rpcUrl];
}
