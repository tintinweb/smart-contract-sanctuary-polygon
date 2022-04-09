/**
 *Submitted for verification at polygonscan.com on 2022-04-08
*/

pragma solidity ^0.8.0;

contract FileHash {
    mapping(bytes32 => bool) public documentsByte;
    mapping(string => bool) public documentsString;
    string[] public testString;

    function notarizeByte(bytes32 hash) public {
        documentsByte[hash] = true;
    }

    function notarizeString(string memory hash) public {
        documentsString[hash] = true;
    }
    function notarizeWithName(string memory hash, string memory company) public {
        documentsString[hash] = true;
    }
    function testManipulation(string memory hash) public {
        testString.push(string(abi.encodePacked("hash:", hash)));
    }
}