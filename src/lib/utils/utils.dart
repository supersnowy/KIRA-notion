import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kira_auth/utils/colors.dart';

const int PAGE_COUNT = 10;

void showToast(String message) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_LONG,
    gravity: ToastGravity.BOTTOM,
    timeInSecForIosWeb: 2,
    backgroundColor: KiraColors.purple1.withOpacity(0.8),
    webBgColor: "#fff",
    textColor: KiraColors.purple1,
    webPosition: "center",
    fontSize: 16,
  );
}

void copyText(String message) {
  Clipboard.setData(ClipboardData(text: message));
}

String getIPOnly(String address) {
  String rpcUrl = address;

  rpcUrl = rpcUrl.replaceAll('https://cors-anywhere.kira.network/', '');
  rpcUrl = rpcUrl.replaceAll('http://', '');
  rpcUrl = rpcUrl.replaceAll('https://', '');
  rpcUrl = rpcUrl.replaceAll('/api', '');

  List<String> urlArray = rpcUrl.split(':');
  return urlArray[0];
}
