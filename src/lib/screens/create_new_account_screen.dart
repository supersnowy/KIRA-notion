// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clipboard/clipboard.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jdenticon/jdenticon.dart';

import 'package:kira_auth/utils/export.dart';
import 'package:kira_auth/widgets/export.dart';
import 'package:kira_auth/models/export.dart';
import 'package:kira_auth/blocs/export.dart';
import 'package:kira_auth/services/export.dart';
import 'package:kira_auth/data/account_repository.dart';

class CreateNewAccountScreen extends StatefulWidget {
  CreateNewAccountScreen();

  @override
  _CreateNewAccountScreenState createState() => _CreateNewAccountScreenState();
}

class _CreateNewAccountScreenState extends State<CreateNewAccountScreen> {
  StatusService statusService = StatusService();
  IAccountRepository accountRepository = IAccountRepository();
  bool isNetworkHealthy = false;
  bool passwordsMatch, loading = false;

  String passwordError;
  Account currentAccount;
  String mnemonic;
  bool seedCopied = false, exportEnabled = false;
  List<String> wordList = [];

  FocusNode createPasswordFocusNode;
  FocusNode confirmPasswordFocusNode;
  FocusNode accountNameFocusNode;
  FocusNode seedPhraseNode;

  TextEditingController seedPhraseController;
  TextEditingController createPasswordController;
  TextEditingController confirmPasswordController;
  TextEditingController accountNameController;

  @override
  void initState() {
    super.initState();

    this.passwordsMatch = false;
    seedPhraseNode = FocusNode();
    seedPhraseController = TextEditingController();
    this.createPasswordFocusNode = FocusNode();
    this.confirmPasswordFocusNode = FocusNode();
    this.accountNameFocusNode = FocusNode();

    this.createPasswordController = TextEditingController();
    this.confirmPasswordController = TextEditingController();
    this.accountNameController = TextEditingController();
    accountNameController.text = "My account";

    getNodeStatus();
  }

  void getNodeStatus() async {
    await statusService.getNodeStatus();

    if (mounted) {
      setState(() {
        if (statusService.nodeInfo.network.isNotEmpty) {
          DateTime latestBlockTime = DateTime.tryParse(statusService.syncInfo.latestBlockTime);
          isNetworkHealthy = DateTime.now().difference(latestBlockTime).inMinutes > 1 ? false : true;
        } else {
          isNetworkHealthy = false;
        }
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
          margin: EdgeInsets.only(top: 50, bottom: 50),
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  addHeaderTitle(),
                  addDescription(),
                  addPassword(),
                  // if (currentAccount != null) addExportButton(),
                  if (currentAccount != null) addMnemonicDescription(),
                  if (currentAccount != null) addMnemonic(),
                  if (currentAccount != null) addCopyButton(),
                  if (currentAccount != null) addQrCode(),
                  if (currentAccount != null) addPublicAddress(),
                  if (loading) addLoadingIndicator(),
                  ResponsiveWidget.isSmallScreen(context) ? addButtonsSmall() : addButtonsBig(),
                  if (currentAccount != null) addCreateAccount()
                ],
              ))),
    ));
  }

  Widget addHeaderTitle() {
    return Container(
        margin: EdgeInsets.only(bottom: 40),
        child: Text(
          Strings.createNewAccount,
          textAlign: TextAlign.left,
          style: TextStyle(color: KiraColors.white, fontSize: 30, fontWeight: FontWeight.w900),
        ));
  }

  Widget addDescription() {
    return Container(
        margin: EdgeInsets.only(bottom: 30),
        child: Row(children: <Widget>[
          Expanded(
              child: Text(
            Strings.passwordDescription,
            textAlign: TextAlign.left,
            style: TextStyle(color: KiraColors.green3, fontSize: 18),
          ))
        ]));
  }

  Widget addPassword() {
    return Container(
        // padding: EdgeInsets.symmetric(horizontal: 20),
        margin: EdgeInsets.only(bottom: 0),
        child: Column(
          children: [
            AppTextField(
              hintText: Strings.accountName,
              labelText: Strings.accountName,
              focusNode: accountNameFocusNode,
              controller: accountNameController,
              textInputAction: TextInputAction.done,
              maxLines: 1,
              autocorrect: false,
              keyboardType: TextInputType.text,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18.0,
                color: KiraColors.white,
                fontFamily: 'NunitoSans',
              ),
            ),
            SizedBox(height: 20),
            AppTextField(
              hintText: Strings.password,
              labelText: Strings.password,
              focusNode: createPasswordFocusNode,
              controller: createPasswordController,
              textInputAction: TextInputAction.done,
              maxLines: 1,
              autocorrect: false,
              obscureText: true,
              keyboardType: TextInputType.text,
              textAlign: TextAlign.left,
              onChanged: (String newText) {
                if (passwordError != null) {
                  setState(() {
                    passwordError = null;
                  });
                }
                if (confirmPasswordController.text == createPasswordController.text) {
                  if (mounted) {
                    setState(() {
                      passwordsMatch = true;
                    });
                  }
                } else {
                  if (mounted) {
                    setState(() {
                      passwordsMatch = false;
                    });
                  }
                }
              },
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 23.0,
                color: KiraColors.white,
                fontFamily: 'NunitoSans',
              ),
            ),
            SizedBox(height: 20),
            AppTextField(
              hintText: Strings.confirmPassword,
              labelText: Strings.confirmPassword,
              focusNode: confirmPasswordFocusNode,
              controller: confirmPasswordController,
              textInputAction: TextInputAction.done,
              obscureText: true,
              maxLines: 1,
              autocorrect: false,
              keyboardType: TextInputType.text,
              textAlign: TextAlign.left,
              onChanged: (String newText) {
                if (passwordError != null) {
                  setState(() {
                    passwordError = null;
                  });
                }
                if (confirmPasswordController.text == createPasswordController.text) {
                  if (mounted) {
                    setState(() {
                      passwordsMatch = true;
                    });
                  }
                } else {
                  if (mounted) {
                    setState(() {
                      passwordsMatch = false;
                    });
                  }
                }
              },
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 23.0,
                color: KiraColors.white,
                fontFamily: 'NunitoSans',
              ),
            ),
            if (this.passwordError != null) SizedBox(height: 15),
            Container(
              alignment: AlignmentDirectional(0, 0),
              margin: EdgeInsets.only(bottom: 20),
              child: Text(this.passwordError == null ? "" : passwordError,
                  style: TextStyle(
                    fontSize: 13.0,
                    color: KiraColors.kYellowColor,
                    fontFamily: 'NunitoSans',
                    fontWeight: FontWeight.w600,
                  )),
            ),
          ],
        ));
  }

  Widget addLoadingIndicator() {
    return Container(
        margin: EdgeInsets.only(bottom: 30, top: 0),
        alignment: Alignment.center,
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 0, horizontal: 30),
          padding: EdgeInsets.all(0),
          child: Text("Generating now ...",
              style: TextStyle(
                fontSize: 16.0,
                color: KiraColors.kYellowColor,
                fontFamily: 'NunitoSans',
                fontWeight: FontWeight.w600,
              )),
        ));
  }

  Widget addButtonsBig() {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            CustomButton(
              key: Key('go_back'),
              text: Strings.back,
              width: 220,
              height: 60,
              style: 1,
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
            CustomButton(
              key: Key('create_account'),
              text: currentAccount == null ? Strings.generate : Strings.generateAgain,
              width: 220,
              height: 60,
              style: 2,
              onPressed: () async {
                setState(() {
                  loading = true;
                });

                Future.delayed(const Duration(milliseconds: 500), () async {
                  await submitAndEncrypt(context);
                });
              },
            )
          ]),
    );
  }

  Widget addMnemonicDescription() {
    return Container(
        margin: EdgeInsets.only(bottom: 20),
        child: Row(children: <Widget>[
          Expanded(
              child: Text(
            Strings.seedPhraseDescription,
            textAlign: TextAlign.left,
            style: TextStyle(color: KiraColors.green3.withOpacity(0.8), fontSize: 15),
          ))
        ]));
  }

  Widget addMnemonic() {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: Container(
          child: MnemonicDisplay(
        rowNumber: ResponsiveWidget.isSmallScreen(context) ? 8 : 6,
        wordList: wordList,
        isCopied: seedCopied,
      )),
    );
  }

  Widget addCopyButton() {
    return Container(
        margin: EdgeInsets.only(bottom: 60),
        alignment: Alignment.centerLeft,
        child: CustomButton(
          key: Key('copy'),
          text: seedCopied ? Strings.copied : Strings.copy,
          width: 130,
          height: 36.0,
          style: 1,
          fontSize: 14,
          onPressed: () {
            FlutterClipboard.copy(mnemonic).then((value) => {
                  setState(() {
                    seedCopied = !seedCopied;
                  })
                });
          },
        ));
  }

  Widget addPublicAddress() {
    // final String gravatar = gravatarService.getIdenticon(currentAccount != null ? currentAccount.bech32Address : "");

    String bech32Address = currentAccount != null ? currentAccount.bech32Address : "";

    return Container(
        margin: EdgeInsets.only(bottom: 30),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.center, children: [
          InkWell(
            onTap: () {
              FlutterClipboard.copy(currentAccount.bech32Address)
                  .then((value) => {showToast(Strings.publicAddressCopied)});
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
          Expanded(
            flex: 1,
            child: AppTextField(
              hintText: Strings.publicAddress,
              labelText: Strings.publicAddress,
              focusNode: seedPhraseNode,
              controller: seedPhraseController..text = bech32Address,
              textInputAction: TextInputAction.done,
              maxLines: 1,
              autocorrect: false,
              keyboardType: TextInputType.text,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18.0,
                color: KiraColors.white,
                fontFamily: 'NunitoSans',
              ),
            ),
          ),
        ]));
  }

  Widget addQrCode() {
    return Container(
        margin: EdgeInsets.only(bottom: 60),
        alignment: Alignment.center,
        child: Container(
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
            embeddedImage: AssetImage(Strings.logoImage),
            embeddedImageStyle: QrEmbeddedImageStyle(
              size: Size(80, 80),
            ),
            version: QrVersions.auto,
            size: 300,
          ),
        ));
  }

  Widget addExportButton() {
    return Container(
        margin: EdgeInsets.only(bottom: 60),
        alignment: Alignment.centerLeft,
        child: CustomButton(
          key: Key('export'),
          text: Strings.export,
          width: 130,
          height: 36.0,
          style: 1,
          fontSize: 14,
          onPressed: () {
            if (exportEnabled) {
              final text = currentAccount.toJsonString();
              // prepare
              final bytes = utf8.encode(text);
              final blob = html.Blob([bytes]);
              final url = html.Url.createObjectUrlFromBlob(blob);
              final anchor = html.document.createElement('a') as html.AnchorElement
                ..href = url
                ..style.display = 'none'
                ..download = currentAccount.name + '.json';
              html.document.body.children.add(anchor);

              // download
              anchor.click();

              // cleanup
              html.document.body.children.remove(anchor);
              html.Url.revokeObjectUrl(url);
            }
          },
        ));
  }

  Widget addButtonsSmall() {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            CustomButton(
              key: Key('create_account'),
              text: Strings.next,
              height: 60,
              style: 2,
              onPressed: () async {
                setState(() {
                  loading = true;
                });

                Future.delayed(const Duration(milliseconds: 500), () async {
                  await submitAndEncrypt(context);
                });
              },
            ),
            SizedBox(height: 30),
            CustomButton(
              key: Key('go_back'),
              text: Strings.back,
              height: 60,
              style: 1,
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ]),
    );
  }

  Widget addCreateAccount() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
      Ink(
        child: Text(
          "or",
          textAlign: TextAlign.center,
          style: TextStyle(color: KiraColors.kGrayColor, fontSize: 16),
        ),
      ),
      SizedBox(height: 20),
      CustomButton(
        key: Key('create_account'),
        text: Strings.createAccount,
        fontSize: 18,
        height: 60,
        style: 1,
        onPressed: () {
          setAccountData(currentAccount.toJsonString());
          BlocProvider.of<AccountBloc>(context).add(SetCurrentAccount(currentAccount));
          BlocProvider.of<ValidatorBloc>(context).add(GetCachedValidators(currentAccount.hexAddress));

          final text = currentAccount.toJsonString();
          // prepare
          final bytes = utf8.encode(text);
          final blob = html.Blob([bytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.document.createElement('a') as html.AnchorElement
            ..href = url
            ..style.display = 'none'
            ..download = currentAccount.name + '.json';
          html.document.body.children.add(anchor);

          // download
          anchor.click();

          // cleanup
          html.document.body.children.remove(anchor);
          html.Url.revokeObjectUrl(url);
        },
      )
    ]);
  }

  Future<void> submitAndEncrypt(BuildContext context) async {
    if (createPasswordController.text.isEmpty || confirmPasswordController.text.isEmpty) {
      if (mounted) {
        setState(() {
          passwordError = Strings.passwordBlank;
        });
      }
    } else if (createPasswordController.text != confirmPasswordController.text) {
      if (mounted) {
        setState(() {
          passwordError = Strings.passwordDontMatch;
        });
      }
    } else if (createPasswordController.text.length < 5) {
      if (mounted) {
        setState(() {
          passwordError = Strings.passwordLengthShort;
        });
      }
    } else {
      // Create new account
      accountRepository.createNewAccount(createPasswordController.text, accountNameController.text).then((account) {
        // BlocProvider.of<AccountBloc>(context)
        //     .add(CreateNewAccount(currentAccount);
        setState(() {
          loading = false;
          currentAccount = account;
          mnemonic = decryptAESCryptoJS(currentAccount.encryptedMnemonic, currentAccount.secretKey);
          wordList = mnemonic.split(' ');
        });
      });
    }
  }
}
