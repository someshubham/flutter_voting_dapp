//* Solidity overview and Deploying contract - Aditya Thakur
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Voting {
    mapping(string => uint256) public votes;

    event Vote(address voter, string candidate);

    constructor() {
        votes["tabs"] = 0;
        votes["spaces"] = 0;
    }

    function getTotalVotes(string memory candidate)
        public
        view
        returns (uint256)
    {
        return votes[candidate];
    }

    function vote(string memory candidate) public payable {
        emit Vote(msg.sender, candidate);
        votes[candidate] = votes[candidate] + 1;
    }
}
