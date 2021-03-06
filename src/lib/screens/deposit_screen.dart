import 'dart:async';
import 'package:flutter/material.dart';
import 'package:clipboard/clipboard.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jdenticon/jdenticon.dart';

import 'package:kira_auth/utils/export.dart';
import 'package:kira_auth/models/export.dart';
import 'package:kira_auth/widgets/export.dart';
import 'package:kira_auth/services/export.dart';
import 'package:kira_auth/service_manager.dart';

class DepositScreen extends StatefulWidget {
  @override
  _DepositScreenState createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final _storageService = getIt<StorageService>();
  final _transactionService = getIt<TransactionService>();
  final _accountService = getIt<AccountService>();

  Account currentAccount;
  Timer timer;
  String networkId = Strings.noAvailableNetworks;
  List<String> networkIds = [Strings.noAvailableNetworks];
  List<Transaction> transactions = [];
  bool copied1, copied2, isNetworkHealthy = false;
  bool initialFetched = false;
  String expandedHash;

  FocusNode depositNode;
  TextEditingController depositController;
  int page = 1;
  StreamController transactionsController = StreamController.broadcast();
  int sortIndex = 0;
  bool isAscending = true;

  @override
  void initState() {
    super.initState();

    this.depositNode = FocusNode();
    this.depositController = TextEditingController();
    this.copied1 = false;
    this.copied2 = false;

    getNodeStatus();
    getDepositTransactions();
  }

  @override
  void dispose() {
    depositController.dispose();
    transactionsController.close();
    super.dispose();
  }

  void unmount() {
    timer.cancel();
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
        if (nodeInfo != null && nodeInfo.network.isNotEmpty) {
          networkIds.clear();
          networkIds.add(nodeInfo.network);
          networkId = nodeInfo.network;
          isNetworkHealthy = networkHealth;
        } else {
          isNetworkHealthy = false;
        }
      });
    }
  }

  getDepositTransactions() async {
    Account curAccount;
    curAccount = _accountService.currentAccount;
    if (curAccount == null) {
      curAccount = await _storageService.getCurrentAccount();
    }

    if (mounted) {
      setState(() {
        currentAccount = curAccount;
        depositController.text = curAccount != null ? curAccount.bech32Address : '';
      });
    }

    if (curAccount != null) {
      List<Transaction> _transactions = _transactionService.transactions;

      if (_transactions.length == 0) {
        _transactions = await _storageService.getTransactions(curAccount.bech32Address);
      }

      if (_transactions.length == 0) {
        bool result = await _transactionService.getTransactions(curAccount.bech32Address);
        if (!result)
          setState(() {
            initialFetched = false;
          });
        _transactions = _transactionService.transactions;
      }

      if (mounted) {
        setState(() {
          transactions = _transactions.where((element) => element.action == "Deposit").toList();
          initialFetched = true;
        });
      }
    }
  }

  void autoPress() {
    timer = new Timer(const Duration(seconds: 2), () {
      setState(() {
        if (copied1) copied1 = false;
        if (copied2) copied2 = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final _storageService = getIt<StorageService>();
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
                constraints: BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    addHeaderTitle(),
                    if (currentAccount != null) addGravatar(context),
                    ResponsiveWidget.isSmallScreen(context) ? addInformationSmall() : addInformationBig(),
                    addTableHeader(),
                    !initialFetched
                        ? addLoadingIndicator()
                        : transactions.isEmpty
                            ? Container(
                                margin: EdgeInsets.only(top: 20, left: 20),
                                child: Text("No deposit transactions to show",
                                    style: TextStyle(
                                        color: KiraColors.white, fontSize: 18, fontWeight: FontWeight.bold)))
                            : addTransactionsTable(),
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
        margin: EdgeInsets.only(bottom: 40),
        child: Text(
          Strings.deposit,
          textAlign: TextAlign.left,
          style: TextStyle(color: KiraColors.white, fontSize: 30, fontWeight: FontWeight.w900),
        ));
  }

  Widget addTableHeader() {
    List<String> titles = ResponsiveWidget.isSmallScreen(context) ? ['Tx Hash', 'Sender', 'Status']
        : ['Tx Hash', 'Sender', 'Amount', 'Time', 'Status'];
    List<int> flexes = [2, 2, 1, 1, 1];

    return Container(
    padding: EdgeInsets.all(5),
    margin: EdgeInsets.only(top: 30, right: 40, bottom: 20),
    child: Row(
    children: titles
        .asMap()
        .map(
    (index, title) => MapEntry(
    index,
    Expanded(
    flex: flexes[index],
    child: InkWell(
    onTap: () => this.setState(() {
    if (sortIndex == index)
    isAscending = !isAscending;
    else {
    sortIndex = index;
    isAscending = true;
    }
    expandedHash = '';
    refreshTableSort();
    }),
    child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: sortIndex != index
    ? [
    Text(title,
    style: TextStyle(
    color: KiraColors.kGrayColor, fontSize: 16, fontWeight: FontWeight.bold)),
    ]
        : [
    Text(title,
    style: TextStyle(
    color: KiraColors.kGrayColor, fontSize: 16, fontWeight: FontWeight.bold)),
    SizedBox(width: 5),
    Icon(isAscending ? Icons.arrow_upward : Icons.arrow_downward,
    color: KiraColors.white),
    ],
    )))),
    )
        .values
        .toList(),
    ),
    );
    }

  Widget availableNetworks() {
    return Container(
        decoration: BoxDecoration(
            border: Border.all(width: 2, color: KiraColors.kPurpleColor),
            color: KiraColors.transparent,
            borderRadius: BorderRadius.circular(9)),
        // dropdown below..
        child: DropdownButtonHideUnderline(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.only(top: 10, left: 15, bottom: 0),
                child: Text(Strings.availableNetworks, style: TextStyle(color: KiraColors.kGrayColor, fontSize: 12)),
              ),
              ButtonTheme(
                alignedDropdown: true,
                child: DropdownButton<String>(
                    dropdownColor: KiraColors.kPurpleColor,
                    value: networkId,
                    icon: Icon(Icons.arrow_drop_down),
                    iconSize: 32,
                    underline: SizedBox(),
                    onChanged: (String netId) {
                      setState(() {
                        networkId = netId;
                      });
                    },
                    items: networkIds.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Container(
                            height: 25,
                            alignment: Alignment.topCenter,
                            child: Text(value, style: TextStyle(color: KiraColors.white, fontSize: 18))),
                      );
                    }).toList()),
              ),
            ],
          ),
        ));
  }

  Widget depositAddress() {
    return AppTextField(
      hintText: Strings.depositAddress,
      labelText: Strings.depositAddress,
      focusNode: depositNode,
      controller: depositController,
      textInputAction: TextInputAction.done,
      maxLines: 1,
      autocorrect: false,
      keyboardType: TextInputType.text,
      textAlign: TextAlign.left,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: KiraColors.white,
        fontFamily: 'NunitoSans',
      ),
    );
  }

  Widget qrCode() {
    return Container(
      width: 180,
      height: 180,
      margin: EdgeInsets.symmetric(vertical: 0, horizontal: 30),
      padding: EdgeInsets.all(0),
      decoration: new BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: new Border.all(
          color: KiraColors.kPurpleColor,
          width: 3,
        ),
      ),
      // dropdown below..
      child: QrImage(
        data: currentAccount != null ? currentAccount.bech32Address : '',
        embeddedImage: AssetImage(Strings.logoQRImage),
        embeddedImageStyle: QrEmbeddedImageStyle(
          size: Size(60, 60),
        ),
        version: QrVersions.auto,
        size: 300,
      ),
    );
  }

  Widget addInformationBig() {
    return Container(
      margin: EdgeInsets.only(bottom: 70),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                availableNetworks(),
                SizedBox(height: 50),
                depositAddress(),
              ],
            ),
          ),
          SizedBox(width: 30),
          qrCode(),
          SizedBox(width: 80),
        ],
      ),
    );
  }

  Widget addInformationSmall() {
    return Container(
      margin: EdgeInsets.only(bottom: 70),
      child: Column(
        children: [
          availableNetworks(),
          SizedBox(height: 30),
          depositAddress(),
          SizedBox(height: 30),
          qrCode(),
        ],
      ),
    );
  }

  Widget addGravatar(BuildContext context) {
    final String reducedAddress =
        currentAccount.bech32Address.replaceRange(10, currentAccount.bech32Address.length - 7, '....');

    return Container(
        margin: EdgeInsets.only(bottom: 30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            InkWell(
              onTap: () {
                FlutterClipboard.copy(currentAccount.bech32Address).then((value) => {
                      setState(() {
                        copied1 = !copied1;
                      }),
                      if (copied1 == true) {autoPress()}
                    });
              },
              borderRadius: BorderRadius.circular(500),
              onHighlightChanged: (value) {},
              child: Container(
                width: 75,
                height: 75,
                padding: EdgeInsets.all(2),
                decoration: new BoxDecoration(
                  color: KiraColors.kPurpleColor,
                  shape: BoxShape.circle,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(1000),
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: SvgPicture.string(
                      Jdenticon.toSvg(currentAccount.bech32Address, 100, 10),
                      fit: BoxFit.contain,
                      height: 70,
                      width: 70,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 20,
            ),
            AnimatedContainer(
              duration: Duration(milliseconds: 200),
              curve: Curves.easeIn,
              child: InkWell(
                onTap: () {
                  copyText(currentAccount.bech32Address);
                  showToast(Strings.publicAddressCopied);
                },
                child: Text(copied1 ? Strings.copied : reducedAddress,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      fontFamily: 'NunitoSans',
                      color: copied1 ? KiraColors.green3 : KiraColors.white.withOpacity(0.8),
                      letterSpacing: 1,
                    )),
              ),
            ),
          ],
        ));
  }

  Widget addTransactionsTable() {
    return Container(
        margin: EdgeInsets.only(bottom: 50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TransactionsTable(
              page: page,
              setPage: (newPage) => this.setState(() {
                page = newPage;
              }),
              isDeposit: true,
              transactions: transactions,
              expandedHash: expandedHash,
              onTapRow: (hash) => this.setState(() {
                expandedHash = hash;
              }),
              controller: transactionsController,
            )
          ],
        ));
  }

  refreshTableSort() {
    if (sortIndex == 0) {
      transactions.sort((a, b) => isAscending ? a.hash.compareTo(b.hash) : b.hash.compareTo(a.hash));
    } else if (sortIndex == 1) {
      transactions.sort((a, b) => isAscending ? a.sender.compareTo(b.sender) : b.sender.compareTo(a.sender));
    } else if (sortIndex == 2) {
      if (ResponsiveWidget.isSmallScreen(context))
        transactions.sort((a, b) => isAscending ? a.status.compareTo(b.status) : b.status.compareTo(a.status));
      else
        transactions.sort((a, b) => isAscending ? a.amount.compareTo(b.amount) : b.amount.compareTo(a.amount));
    } else if (sortIndex == 3) {
      transactions.sort((a, b) => isAscending ? a.time.compareTo(b.time) : b.time.compareTo(a.time));
    } else {
      transactions.sort((a, b) => isAscending ? a.status.compareTo(b.status) : b.status.compareTo(a.status));
    }
    transactionsController.add(null);
  }
}
