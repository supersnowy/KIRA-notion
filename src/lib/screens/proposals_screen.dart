import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kira_auth/helpers/export.dart';
import 'package:kira_auth/utils/export.dart';
import 'package:kira_auth/widgets/export.dart';
import 'package:kira_auth/services/export.dart';
import 'package:kira_auth/models/export.dart';
import 'package:kira_auth/service_manager.dart';

class ProposalsScreen extends StatefulWidget {
  @override
  _ProposalsScreenState createState() => _ProposalsScreenState();
}

class _ProposalsScreenState extends State<ProposalsScreen> {
  final _proposalService = getIt<ProposalService>();

  List<Proposal> proposals = [];
  List<int> voteable = [0, 2];
  String pendingTxHash;
  String cancelAccountNumber;
  String cancelSequence;
  bool isFiltering = false;
  String query = "";
  bool moreLoading = false;

  Account currentAccount;
  String feeAmount;
  Token feeToken;
  String expandedId;
  bool isNetworkHealthy = false;
  int page = 1;
  StreamController proposalController = StreamController.broadcast();

  @override
  void initState() {
    super.initState();

    // setTopBarStatus(true);
    getNodeStatus();
    getCachedFeeAmount();
    getFeeToken();
    getCurrentAccount();
    getProposals(false);
  }

  getCurrentAccount() async {
    final _accountService = getIt<AccountService>();
    final _storageService = getIt<StorageService>();
    Account curAccount = _accountService.currentAccount;

    if (_accountService.currentAccount == null) {
      curAccount = await _storageService.getCurrentAccount();
    }

    if (mounted) {
      setState(() {
        currentAccount = curAccount;
      });
    }
  }

  void getProposals(bool loadNew) async {
    setState(() {
      moreLoading = !loadNew;
    });
    await _proposalService.getProposals(loadNew, account: currentAccount != null ? currentAccount.bech32Address : '');
    setState(() {
      moreLoading = false;
      proposals.clear();
      proposals.addAll(_proposalService.proposals);

      var uri = Uri.dataFromString(html.window.location.href);
      Map<String, String> params = uri.queryParameters;
      var keyword = query;
      if (params.containsKey("info")) keyword = params['info'].toLowerCase();

      proposalController.add(keyword);
    });
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

  void getCachedFeeAmount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      int cfeeAmount = prefs.getInt('FEE_AMOUNT');
      if (cfeeAmount.runtimeType != Null)
        feeAmount = cfeeAmount.toString();
      else
        feeAmount = '100';
    });
  }

  void getFeeToken() async {
    final _storageService = getIt<StorageService>();
    final _tokenService = getIt<TokenService>();
    Token fToken = _tokenService.feeToken;

    if (fToken == null) {
      fToken = await _storageService.getFeeToken();
    }

    if (mounted) {
      setState(() {
        feeToken = fToken;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    addHeaderTitle(),
                    isFiltering ? addSearchInput() : Container(),
                    addTableHeader(),
                    moreLoading
                        ? addLoadingIndicator()
                        : proposals.isEmpty
                            ? Container(
                                margin: EdgeInsets.only(top: 20, left: 20),
                                child: Text("No proposals to show",
                                    style: TextStyle(
                                        color: KiraColors.white, fontSize: 18, fontWeight: FontWeight.bold)))
                            : addProposalsTable(),
                  ],
                ),
              ))));
  }

  Widget addLoadingIndicator() {
    return Container(
        alignment: Alignment.center,
        child: Container(
          width: 20,
          height: 20,
          margin: EdgeInsets.symmetric(vertical: 0, horizontal: 30),
          padding: EdgeInsets.all(0),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ));
  }

  Widget addHeaderTitle() {
    return Container(
        margin: EdgeInsets.only(bottom: 20),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                Strings.proposals,
                textAlign: TextAlign.left,
                style: TextStyle(color: KiraColors.white, fontSize: 30, fontWeight: FontWeight.w900),
              ),
              Container(
                margin: EdgeInsets.only(right: 20),
                child: isFiltering
                    ? InkWell(
                    onTap: () {
                      this.setState(() {
                        isFiltering = false;
                        expandedId = "";
                      });
                    },
                    child: Icon(Icons.close, color: KiraColors.white, size: 30))
                    : Tooltip(
                  message: Strings.proposalQuery,
                  waitDuration: Duration(milliseconds: 500),
                  decoration: BoxDecoration(color: KiraColors.purple1, borderRadius: BorderRadius.circular(4)),
                  verticalOffset: 20,
                  preferBelow: ResponsiveWidget.isSmallScreen(context),
                  margin: EdgeInsets.only(
                      right: ResponsiveWidget.isSmallScreen(context)
                          ? 20
                          : ResponsiveWidget.isMediumScreen(context)
                          ? 50
                          : 110),
                  textStyle: TextStyle(color: KiraColors.white.withOpacity(0.8)),
                  child: InkWell(
                    onTap: () {
                      this.setState(() {
                        isFiltering = true;
                        expandedId = "";
                      });
                    },
                    child: Icon(Icons.search, color: KiraColors.white, size: 30),
                  ),
                ),
              ),
            ],
        ),
    );
  }

  Widget addSearchInput() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      width: 500,
      child: AppTextField(
        hintText: Strings.proposalQuery,
        labelText: Strings.search,
        textInputAction: TextInputAction.search,
        maxLines: 1,
        autocorrect: false,
        keyboardType: TextInputType.text,
        textAlign: TextAlign.left,
        onChanged: (String newText) {
          this.setState(() {
            query = newText.toLowerCase();
            expandedId = "";
            proposalController.add(query);
          });
        },
        padding: EdgeInsets.only(bottom: 15),
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16.0,
          color: KiraColors.white,
          fontFamily: 'NunitoSans',
        ),
        topMargin: 10,
      ),
    );
  }

  Widget addTableHeader() {
    return Container(
      padding: EdgeInsets.all(5),
      margin: EdgeInsets.only(top: 20, right: 40, bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text("ID",
                textAlign: TextAlign.center,
                style: TextStyle(color: KiraColors.kGrayColor, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 2,
            child: Text("Title",
                textAlign: TextAlign.center,
                style: TextStyle(color: KiraColors.kGrayColor, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 1,
            child: Text("Status",
                textAlign: TextAlign.center,
                style: TextStyle(color: KiraColors.kGrayColor, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 1,
            child: Text("Time",
                textAlign: TextAlign.center,
                style: TextStyle(color: KiraColors.kGrayColor, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget addProposalsTable() {
    return Container(
        margin: EdgeInsets.only(bottom: 50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProposalsTable(
              page: page,
              setPage: (newPage) => this.setState(() {
                page = newPage;
              }),
              isFiltering: query.isNotEmpty,
              proposals: proposals,
              voteable: voteable,
              expandedId: expandedId,
              onTapRow: (id) => this.setState(() {
                expandedId = id;
              }),
              totalPages: (_proposalService.totalCount / PAGE_COUNT).ceil(),
              loadMore: () => getProposals(false),
              controller: proposalController,
              onTapVote: (proposalId, option) => sendProposal(proposalId, option),
            ),
          ],
        ));
  }

  showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CustomDialog(contentWidgets: [
          Text(
            Strings.kiraNetwork,
            style: TextStyle(fontSize: 22, color: KiraColors.kPurpleColor, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 15),
          Text(Strings.loading, style: TextStyle(fontSize: 20, color: KiraColors.black, fontWeight: FontWeight.w600)),
          SizedBox(height: 15),
          TextButton(
              onPressed: () async {
                cancelTransaction(pendingTxHash);
              },
              child: SizedBox(
                  width: 100,
                  height: 36,
                  child: Center(
                      child: Text(
                    Strings.cancel,
                    style: TextStyle(fontSize: 14, color: KiraColors.danger),
                  )))),
        ]);
      },
    );
  }

  cancelTransaction(String txHash) async {
    final message = MsgSend(
        fromAddress: currentAccount.bech32Address,
        toAddress: currentAccount.bech32Address,
        amount: [StdCoin(denom: feeToken.denomination, amount: '1')]);
    final feeV = StdCoin(amount: feeAmount + '0', denom: feeToken.denomination);
    final fee = StdFee(gas: '200000', amount: [feeV]);

    final stdTx = TransactionBuilder.buildStdTx([message], stdFee: fee, memo: 'Cancel transaction');

    try {
      final signedStdTx = await TransactionSigner.signStdTx(currentAccount, stdTx,
          accountNumber: cancelAccountNumber, sequence: cancelSequence);
      await TransactionSender.broadcastStdTx(account: currentAccount, stdTx: signedStdTx);
    } catch (error) {}
    cancelAccountNumber = '';
    cancelSequence = '';
  }

  sendProposal(String proposalId, int option) async {
    final vote = MsgVote(voter: currentAccount.bech32Address, proposalId: proposalId, option: option);

    final feeV = StdCoin(amount: feeAmount, denom: feeToken.denomination);
    final fee = StdFee(gas: '200000', amount: [feeV]);
    final voteTx = TransactionBuilder.buildVoteTx([vote], stdFee: fee, memo: 'Vote to proposal $proposalId');

    showLoading();

    var result;
    try {
      // Sign the transaction
      final signedVoteTx = await TransactionSigner.signVoteTx(currentAccount, voteTx);
      cancelAccountNumber = signedVoteTx.accountNumber;
      cancelSequence = signedVoteTx.sequence;

      // Broadcast signed transaction
      result = await TransactionSender.broadcastVoteTx(account: currentAccount, voteTx: signedVoteTx);
    } catch (error) {
      result = error.toString();
    }
    Navigator.of(context, rootNavigator: true).pop();

    String voteResult, txHash;
    if (result == null) {
      voteResult = Strings.voteCancelled;
    } else if (result is String) {
      if (result.contains("-")) result = jsonDecode(result.split("-")[1])['message'];
      voteResult = result;
    } else if (result == false) {
      voteResult = Strings.invalidVote;
    } else if (result['height'] == "0") {
      if (result['check_tx']['log'].toString().contains("invalid")) voteResult = Strings.invalidVote;
    } else {
      txHash = result['hash'];
      if (result['deliver_tx']['log'].toString().contains("failed")) {
        voteResult = result['deliver_tx']['log'].toString();
      } else {
        voteResult = Strings.voteSuccess;
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomDialog(
          contentWidgets: [
            Text(
              Strings.kiraNetwork,
              style: TextStyle(fontSize: 22, color: KiraColors.kPurpleColor, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 15),
            Text(voteResult.isEmpty ? Strings.invalidVote : voteResult,
                style: TextStyle(fontSize: 20), textAlign: TextAlign.center),
            SizedBox(height: 22),
            (txHash ?? '').isEmpty
                ? Container()
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      RichText(
                          text: new TextSpan(children: [
                        new TextSpan(text: 'TxHash: ', style: TextStyle(color: KiraColors.black)),
                        new TextSpan(
                            text: '0x$txHash'.replaceRange(7, txHash.length - 3, '....'),
                            style: TextStyle(color: KiraColors.kPrimaryColor),
                            recognizer: new TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.pushReplacementNamed(context, '/transactions/0x$txHash');
                              }),
                      ])),
                      InkWell(
                        onTap: () {
                          copyText("0x$txHash");
                          showToast(Strings.txHashCopied);
                        },
                        child: Icon(Icons.copy, size: 20, color: KiraColors.kPrimaryColor),
                      )
                    ],
                  )
          ],
        );
      },
    );
  }
}
