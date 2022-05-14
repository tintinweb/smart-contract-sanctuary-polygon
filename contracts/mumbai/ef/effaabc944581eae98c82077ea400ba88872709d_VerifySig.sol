/**
 *Submitted for verification at polygonscan.com on 2022-05-13
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;


contract VerifySig{
    
    function verify(address _signer, string memory _message, bytes memory _sig)
        external pure returns(bool){
            bytes32 messageHash = getMessgeHash(_message);
            bytes32 ethSigneMessageHash = getEthSignedMessageHash(messageHash);
            return recover(ethSigneMessageHash, _sig) == _signer;
        }
    //第一次哈希运算
    function getMessgeHash(string memory _message) public pure returns(bytes32){
        return keccak256(abi.encodePacked(_message));
    }

    //签名的结果第二次哈希运算 一次有可以被破解
    function getEthSignedMessageHash(bytes32  _messageHash) public pure returns(bytes32){
        return keccak256(abi.encodePacked(_messageHash));
    }
    //恢复签名
    function recover(bytes32 _ethSignedMessageHas,bytes memory _sig) public pure returns(address){
        (bytes32 r,bytes32 s,uint8 v) = _split(_sig);
        return ecrecover(_ethSignedMessageHas,v,r,s);
    }

    function _split(bytes memory _sig) internal pure returns(bytes32 r,bytes32 s ,uint8 v){
        require(_sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(_sig,32))
            s := mload(add(_sig,64))
            v := byte(0,mload(add(_sig,96))) 
        }
    }
}