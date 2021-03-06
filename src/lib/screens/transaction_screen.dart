import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:kira_auth/utils/export.dart';
import 'package:kira_auth/widgets/export.dart';
import 'package:kira_auth/models/export.dart';
import 'package:kira_auth/services/export.dart';
import 'package:kira_auth/service_manager.dart';

class TransactionScreen extends StatefulWidget {
  final String txHash;
  const TransactionScreen(String txHash) : this.txHash = txHash;

  @override
  _TransactionScreenState createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final _storageService = getIt<StorageService>();
  final _networkService = getIt<NetworkService>();

  BlockTransaction transaction;
  bool isNetworkHealthy = false;

  @override
  void initState() {
    super.initState();

    getNodeStatus();
    getTransaction();
  }

  void getNodeStatus() async {
    final _statusService = getIt<StatusService>();
    bool networkHealth = _statusService.isNetworkHealthy;
    NodeInfo nodeInfo = _statusService.nodeInfo;

    if (nodeInfo == null) {
      final _storageService = getIt<StorageService>();
      nodeInfo = await _storageService.getNodeStatusData("NODE_INFO");
    }

    if (mounted) {
      setState(() {
        isNetworkHealthy = nodeInfo == null ? false : networkHealth;
      });
    }
  }

  void getTransaction() async {
    if ((widget.txHash ?? '').isNotEmpty) await _networkService.searchTransaction(widget.txHash);
    if (mounted) {
      setState(() {
        transaction = _networkService.transaction;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _storageService.checkPasswordExpired().then((success) {
      if (success) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });

    return Scaffold(
      body: HeaderWrapper(
        isNetworkHealthy: isNetworkHealthy,
        childWidget: Container(
            alignment: Alignment.center,
            margin: EdgeInsets.symmetric(vertical: ResponsiveWidget.isSmallScreen(context) ? 10 : 50),
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                      margin: EdgeInsets.only(bottom: 40),
                      child: Text(
                        Strings.txDetails,
                        textAlign: TextAlign.left,
                        style: TextStyle(color: KiraColors.white, fontSize: 30, fontWeight: FontWeight.w900),
                      )),
                  transaction != null
                      ? addTransactionDetails()
                      : Center(
                          child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )),
                ],
              ),
            ))));
  }

  Widget addTransactionDetails() {
    final fieldWidth = ResponsiveWidget.isSmallScreen(context) ? 80.0 : 150.0;
    Map<String, CopyableText> details = transaction.messages.isNotEmpty ? transaction.messages[0].getDetails() : {};

    return Card(
        color: KiraColors.purple1.withOpacity(0.2),
        child: Container(
          padding: EdgeInsets.all(10),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: fieldWidth,
                    child: Text("Transaction Hash",
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            color: KiraColors.white.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(width: 20),
                  Flexible(
                      child: InkWell(
                          onTap: () {
                            copyText(transaction.getHash);
                            showToast(Strings.txHashCopied);
                          },
                          child: Text(transaction.getHash,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: KiraColors.white.withOpacity(0.8), fontSize: 14))))
                ],
              ),
              SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: fieldWidth,
                    child: Text("Status",
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            color: KiraColors.white.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(width: 20),
                  Container(
                      padding: EdgeInsets.only(top: 4, left: 8, right: 8, bottom: 4),
                      child: Text(transaction.status,
                          style: TextStyle(color: KiraColors.white.withOpacity(0.8), fontSize: 16)),
                      decoration: BoxDecoration(
                          color: KiraColors.purple1.withOpacity(0.8), borderRadius: BorderRadius.circular(4)))
                ],
              ),
              SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: fieldWidth,
                    child: Text("Block",
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            color: KiraColors.white.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(width: 20),
                  Text(transaction.getHeightString(),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: KiraColors.white.withOpacity(0.8), fontSize: 14))
                ],
              ),
              SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: fieldWidth,
                    child: Text("Timestamp",
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            color: KiraColors.white.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(width: 20),
                  Text(
                    transaction.getLongTimeString(),
                    style: TextStyle(color: KiraColors.white.withOpacity(0.8), fontSize: 14),
                  )
                ],
              ),
              ...details.keys
                  .map((key) => Column(children: [
                        SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: fieldWidth,
                              child: Text(key,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      color: KiraColors.white.withOpacity(0.8),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ),
                            SizedBox(width: 20),
                            Flexible(
                                child: details[key].isCopyable
                                    ? InkWell(
                                        onTap: () {
                                          copyText(details[key].value);
                                          showToast(details[key].toast);
                                        },
                                        child: Text(
                                          details[key].value,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: KiraColors.white.withOpacity(0.8), fontSize: 14),
                                        ))
                                    : Text(
                                        details[key].value,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: KiraColors.white.withOpacity(0.8), fontSize: 14),
                                      ))
                          ],
                        ),
                      ]))
                  .toList(),
            ],
          ),
        ));
  }
}
