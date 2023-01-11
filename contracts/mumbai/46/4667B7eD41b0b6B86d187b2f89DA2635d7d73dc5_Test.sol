/**
 *Submitted for verification at polygonscan.com on 2023-01-10
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Test {

    string baseURI = "https://gateway.pinata.cloud/ipfs/QmSf9gGkDwjvjdAqGvHp5qKqyN8vMjcftK54kZU4bCRCzE/";

    function concatenate(string memory a,string memory b) public pure returns (string memory){
        return string(abi.encodePacked(a,b));
    }
    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function getDegreeName(string memory rollNumber, string memory secretKey) public pure returns(bytes32) {
        string memory degreeName = string(abi.encodePacked(rollNumber,secretKey));
        bytes32 degreeNameHash = keccak256(abi.encodePacked(degreeName));
        return degreeNameHash;
    }
    
}