/**
 *Submitted for verification at polygonscan.com on 2022-03-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract verify {

    function VerifyMessage(bytes32 _hashedMessage, uint8 _v, bytes32 _r, bytes32 _s) public pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _hashedMessage));
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        return signer;
    }

    function EncodeAndVerifyMessage(uint256 tokenId, address voterAddress,  uint8 _v, bytes32 _r, bytes32 _s) public pure returns (address) {
        bytes32 payloadHash = keccak256(abi.encode(tokenId, voterAddress));
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", payloadHash));       
        
        address signer = ecrecover(messageHash, _v, _r, _s);
        return signer;
    }

    function VerifyTextMessage(string memory textMsg, uint8 _v, bytes32 _r, bytes32 _s) public pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, textMsg));
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        return signer;
    }

}