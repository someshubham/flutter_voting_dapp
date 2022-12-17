// ignore_for_file: prefer_typing_uninitialized_variables, prefer_const_constructors, use_build_context_synchronously, unnecessary_brace_in_string_interps, avoid_print, sort_child_properties_last

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Client httpClient;

  late Web3Client ethClient;

  String myAddress = "0xD2bfDeE01E876779D7745A89a90e50C9BA24D3d3";
  String blockchainUrl = "http://127.0.0.1:7545";
  String contractAddress = "0xB0a860776df4CED0d1C27F9665C6fe8e46C942E3";
  String walletKey =
      "fcd70c6baaec4df729a4e6411e23e71c61720ecef1003f5a15e22998861a07c9";

  var totalVotesA;
  var totalVotesB;

  @override
  void initState() {
    httpClient = Client();
    ethClient = Web3Client(blockchainUrl, httpClient);
    getTotalVotes();
    super.initState();
  }

  void updateContractAddress(String address) {
    setState(() => {contractAddress = address});
  }

  void updateMyAddress(String address) {
    setState(() => {myAddress = address});
  }

  void updateWalletKey(String key) {
    setState(() => {walletKey = key});
  }

  void updateBlockchainUrl(String url) {
    setState(() => {blockchainUrl = url});
  }

  Future<DeployedContract> getContract() async {
    String abiFile = await rootBundle.loadString("build/contracts/Voting.json");

    final jsonAbi = jsonDecode(abiFile);

    final abi = jsonAbi['abi'];

    final contractAbi = ContractAbi.fromJson(jsonEncode(abi), "Voting");
    final ethContractAddress = EthereumAddress.fromHex(contractAddress);
    final contract = DeployedContract(contractAbi, ethContractAddress);

    return contract;
  }

  Future<List<dynamic>> callFunction(String name, String candidate) async {
    final contract = await getContract();
    final function = contract.function(name);
    final result = await ethClient
        .call(contract: contract, function: function, params: [candidate]);
    return result;
  }

  Future<void> getTotalVotes() async {
    List<dynamic> resultsA = await callFunction("getTotalVotes", "tabs");
    List<dynamic> resultsB = await callFunction("getTotalVotes", "spaces");
    totalVotesA = resultsA[0];
    totalVotesB = resultsB[0];

    setState(() {});
  }

  snackBar({String? label}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label!,
              style: TextStyle(
                fontSize: 20,
              ),
            ),
            CircularProgressIndicator(
              color: Colors.white,
            )
          ],
        ),
        duration: Duration(days: 1),
        backgroundColor: Color(0xff8047E2),
      ),
    );
  }

  Future<void> vote(bool voteTabs) async {
    // Pass in parameter
    String voteFor = "spaces";
    if (voteTabs) {
      voteFor = "tabs";
    } else {
      voteFor = "spaces";
    }
    print("Vote was for ${voteFor}");

    snackBar(label: "Recording vote");
    //obtain private key for write operation
    Credentials key = EthPrivateKey.fromHex(walletKey);

    //obtain our contract from abi in json file
    final contract = await getContract();

    // extract function from json file
    final function = contract.function("vote");

    //send transaction using the our private key, function and contract
    await ethClient.sendTransaction(
        key,
        Transaction.callContract(
          contract: contract,
          function: function,
          parameters: [voteFor],
        ),
        chainId: 4);
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    snackBar(label: "verifying vote");
    //set a 20 seconds delay to allow the transaction to be verified before trying to retrieve the balance
    Future.delayed(const Duration(seconds: 20), () {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      snackBar(label: "retrieving votes");
      getTotalVotes();

      ScaffoldMessenger.of(context).clearSnackBars();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        elevation: 0,
        title: Text("Wallet Ballot"),
        backgroundColor: Color(0xff8047E2),
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 32),
            Container(
              padding: EdgeInsets.all(30),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: Color(0xff8047E2),
                  borderRadius: BorderRadius.all(Radius.circular(20))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      CircleAvatar(
                        child: Text("Frontier"),
                        radius: 52,
                        foregroundImage: AssetImage('assets/crypto.png'),
                        backgroundColor: Color(0xffCC703C),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Text(
                        "Votes: ${totalVotesA ?? ""}",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      )
                    ],
                  ),
                  Column(
                    children: [
                      CircleAvatar(
                        child: Text(
                          "Other",
                          style: TextStyle(
                            fontSize: 20,
                          ),
                        ),
                        foregroundImage: AssetImage('assets/others.png'),
                        radius: 52,
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Text(
                        "Votes: ${totalVotesB ?? ""}",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 30,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () {
                    vote(true);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Frontier Wallet',
                      style: TextStyle(
                        fontSize: 20,
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: StadiumBorder(),
                    backgroundColor: Color(0xffCC703C),
                  ),
                ),
                SizedBox(
                  height: 30,
                ),
                ElevatedButton(
                  onPressed: () {
                    vote(false);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Other Wallets',
                      style: TextStyle(
                        fontSize: 20,
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(shape: StadiumBorder()),
                )
              ],
            ),
            // Column(
            //   children: [
            //     TextFormField(
            //       decoration: const InputDecoration(
            //         border: UnderlineInputBorder(),
            //         labelText: 'Enter the contract address',
            //       ),
            //       onChanged: (text) {
            //         updateContractAddress(text);
            //       },
            //     ),
            //     TextFormField(
            //       decoration: const InputDecoration(
            //         border: UnderlineInputBorder(),
            //         labelText: 'Enter your address',
            //       ),
            //       onChanged: (text) {
            //         updateMyAddress(text);
            //       },
            //     ),
            //     TextFormField(
            //       decoration: const InputDecoration(
            //         border: UnderlineInputBorder(),
            //         labelText: 'Enter your key',
            //       ),
            //       onChanged: (text) {
            //         updateWalletKey(text);
            //       },
            //     ),
            //     TextFormField(
            //       decoration: const InputDecoration(
            //         border: UnderlineInputBorder(),
            //         labelText: "Enter the blockchain URL",
            //       ),
            //       onChanged: (text) {
            //         updateBlockchainUrl(text);
            //       },
            //     ),
            //   ],
            // )
          ],
        ),
      ),
    );
  }
}
