/**
 *Submitted for verification at polygonscan.com on 2022-07-04
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface IVerifier {
    function verifyProof(uint[2] memory a, uint[2][2] memory b, uint[2] memory c, 
        uint[6] memory input) external view returns (bool r);
}

contract FusionCredit {
    address owner;
    IVerifier public verifier;
    uint[2] public pubkey;
    mapping(address => ScoreData) public scores;

    struct ScoreData {
        uint16 score;
        uint16 version;
        uint48 timestamp;
    }

   modifier onlyOwner {
      require(msg.sender == owner);
      _;
   }

    constructor(IVerifier _verifier, uint[2] memory _pubkey) {
        owner = msg.sender;
        verifier = _verifier;
        pubkey = _pubkey;
    }

    function setVerifier(IVerifier _verifier) public onlyOwner {
        verifier = _verifier;
    }

    function setPubkey(uint[2] memory _pubkey) public onlyOwner {
        pubkey = _pubkey;
    }

    function getScore(address _addr) public view returns(uint score, uint version, uint timestamp) {
        ScoreData memory scoreData = scores[_addr];
        return (scoreData.score, scoreData.version, scoreData.timestamp);
    }

    function setScore(uint score, uint version, uint timestamp, uint[8] memory proof) public {
        require(verifier != IVerifier(address(0)), "Verifier not set");

        ScoreData memory scoreData = scores[msg.sender];
        require(version >= scoreData.version, "Can't use earlier version");
        require(timestamp > scoreData.timestamp, "Can't use earlier timestamp");

        uint[6] memory input = [score, version, timestamp, uint(uint160(msg.sender)), pubkey[0], pubkey[1]];
        uint[2] memory a = [proof[0], proof[1]];
        uint[2][2] memory b = [[proof[2], proof[3]], [proof[4], proof[5]]];
        uint[2] memory c = [proof[6], proof[7]];
        require(verifier.verifyProof(a, b, c, input), "Proof not valid");

        scores[msg.sender] = ScoreData(uint16(score), uint16(version), uint48(timestamp));
    }
}