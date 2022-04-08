/**
 *Submitted for verification at polygonscan.com on 2022-04-07
*/

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.4;

contract VerifySignature{

    function getHash(string memory str) public pure returns (bytes32){
        return keccak256(abi.encodePacked(str));
    }

    function getEthSignedHash(bytes32 _messageHash) public pure returns (bytes32){
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function verify(bytes32 _ethSignedMessageHash, bytes memory _signature)public pure returns(address){
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
        r := mload(add(_signature, 32))
        s := mload(add(_signature, 64))
        v := and(mload(add(_signature, 65)), 255)
        }
        if (v < 27) v += 27;

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }
}