/**
 *Submitted for verification at polygonscan.com on 2023-03-03
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

library Encryption {
    function encrypt(bytes memory data, bytes memory password) internal pure returns (bytes memory) {
        bytes memory encrypted = new bytes(data.length);
        for (uint i = 0; i < data.length; i++) {
            encrypted[i] = data[i] ^ password[i % password.length];
        }
        return encrypted;
    }

    function decrypt(bytes memory data, bytes memory password) internal pure returns (bytes memory) {
        bytes memory decrypted = new bytes(data.length);
        for (uint i = 0; i < data.length; i++) {
            decrypted[i] = data[i] ^ password[i % password.length];
        }
        return decrypted;
    }
}

contract MedicalDataStorage {

    mapping(address => bytes) userInfo;

    function fillUSerInfo(bytes memory encryptedInfo) public{
        userInfo[msg.sender] = encryptedInfo;
    }

    function getUSerInfo(address userAddress, string memory password) public view returns(string memory){
        return testDecryption(userInfo[userAddress], password);
    }

    function convertToBytes(string memory text) internal pure returns (bytes memory) {
        bytes memory textBytes = bytes(text);
        return textBytes;
    }

    function convertToString(bytes memory data) internal pure returns (string memory) {
        string memory text = string(data);
        return text;
    }

    function testEncryption(string memory _data, string memory _password) public pure returns (bytes memory) {
        bytes memory data = convertToBytes(_data);
        bytes memory password = convertToBytes(_password);
        return Encryption.encrypt(data, password);
    }

    function testDecryption(bytes memory encryptedData, string memory _password) public pure returns (string memory) {
        bytes memory password = convertToBytes(_password);
        return convertToString(Encryption.decrypt(encryptedData, password));
    }
}