import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kira_auth/models/export.dart';
import 'package:kira_auth/services/export.dart';
import 'package:kira_auth/service_manager.dart';

class TokenService {
  final _storageService = getIt<StorageService>();

  Token feeToken;
  String currentAddress;
  List<Token> tokens = [];
  List<String> faucetTokens = [];

  void initialize() async {
    Account currentAccount = await _storageService.getCurrentAccount();
    currentAddress = currentAccount.hexAddress;

    tokens = await _storageService.getTokenBalance(currentAddress);
    faucetTokens = await _storageService.getFaucetTokens();
    feeToken = await _storageService.getFeeToken();
  }

  void setFeeToken(Token fToken) async {
    feeToken = fToken;
    await _storageService.setFeeToken(fToken.toString());
  }

  Future<void> getTokens(String address) async {
    print("--- GET TOKEN BALANCE ---");
    currentAddress = address;
    List<Token> tokenList = [];

    var apiUrl = await _storageService.getLiveRpcUrl();

    var tokenAliases =
        await http.get(apiUrl[0] + "/api/kira/tokens/aliases", headers: {'Access-Control-Allow-Origin': apiUrl[1]});
    var tokenAliasesData = json.decode(tokenAliases.body);
    // tokenAliasesData = tokenAliasesData['data'];

    var balance = await http
        .get(apiUrl[0] + "/api/cosmos/bank/balances/$address", headers: {'Access-Control-Allow-Origin': apiUrl[1]});
    var balanceData = json.decode(balance.body);
    var coins = balanceData['balances'];

    Pagination pagination = Pagination.fromJson(balanceData['pagination']);

    if (tokenAliasesData != null) {
      for (int i = 0; i < tokenAliasesData.length; i++) {
        String assetName = tokenAliasesData[i]['name'].toString();
        String graphicalSymbol = tokenAliasesData[i]['icon'];

        if (graphicalSymbol == null || graphicalSymbol.toString() == '') {
          switch (assetName) {
            case 'KIRA':
              graphicalSymbol = 'http://kira-network.s3-eu-west-1.amazonaws.com/assets/img/tokens/kex.svg';
              break;
            case 'Test TestCoin':
              graphicalSymbol = 'http://kira-network.s3-eu-west-1.amazonaws.com/assets/img/tokens/test.svg';
              break;
            case 'Samolean TestCoin':
              graphicalSymbol = 'http://kira-network.s3-eu-west-1.amazonaws.com/assets/img/tokens/samolean.svg';
              break;
          }
        }

        Token token = Token(
            graphicalSymbol: graphicalSymbol,
            assetName: assetName,
            ticker: tokenAliasesData[i]['symbol'],
            balance: 0,
            denomination: tokenAliasesData[i]['denoms'][0].toString(),
            decimals: tokenAliasesData[i]['decimals'],
            pagination: pagination);

        if (coins != null) {
          for (int j = 0; j < coins.length; j++) {
            if (tokenAliasesData[i]['denoms'].contains(coins[j]['denom']) == true) {
              token.balance = double.tryParse(coins[j]['amount']);
              token.denomination = coins[j]['denom'].toString();
            }
          }
        }

        tokenList.add(token);
      }
    }

    // if (coins != null) {
    //   for (int i = 0; i < coins.length; i++) {
    //     Token token = Token(
    //         graphicalSymbol: Tokens.atom,
    //         assetName: coins[i]['denom'].toString(),
    //         ticker: coins[i]['denom'].toString(),
    //         balance: double.tryParse(coins[i]['amount']),
    //         denomination: coins[i]['denom'].toString(),
    //         decimals: 6,
    //         pagination: pagination);
    //     tokenList.add(token);
    //   }
    // }

    tokens = tokenList;
    _storageService.setTokenBalance(address, jsonEncode(tokenList));
  }

  Future<String> faucet(String address, String token) async {
    var apiUrl = await _storageService.getLiveRpcUrl();

    String url = apiUrl[0] + "/api/faucet?claim=$address&token=$token";
    String response = "Success!";

    var data = await http.get(url, headers: {'Access-Control-Allow-Origin': apiUrl[1]});
    var bodyData = json.decode(data.body);
    // var header = data.headers;
    // print(header['interx_signature']);

    if (bodyData['hash'] != null) {
      response = "Success!";
    }
    switch (bodyData['code']) {
      case 0:
        response = "Internal Server Error";
        break;
      case 1:
        response = "Failed to send tokens";
        break;
      case 100:
        response = "Invalid address";
        break;
      case 101:
        response = "Claim time left";
        break;
      case 102:
        response = "Invalid token";
        break;
      case 103:
        response = "No need to send tokens";
        break;
      case 104:
        response = "Can't send tokens, less than minimum amount";
        break;
      case 105:
        response = "Not enough tokens in faucet server";
        break;
    }
    return response;
  }

  Future<void> getAvailableFaucetTokens() async {
    List<String> tokenList = [];
    var apiUrl = await _storageService.getLiveRpcUrl();

    var response = await http.get(apiUrl[0] + "/api/faucet", headers: {'Access-Control-Allow-Origin': apiUrl[1]});
    var body = json.decode(response.body);
    var coins = body['balances'];

    if (coins != null) {
      for (int i = 0; i < coins.length; i++) {
        tokenList.add(coins[i]['denom']);
      }
    }

    faucetTokens = tokenList;
    _storageService.setFaucetTokens(response.body);
  }
}
