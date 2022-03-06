/**
 *Submitted for verification at polygonscan.com on 2022-03-06
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

// todo:
// - multiply owners

contract Originstamp {
    address public owner;
    mapping(bytes32 => bytes32) public docHashTx;
    mapping(bytes32 => uint256) public docHashTime;
    mapping(bytes32 => bytes32) public newVersions;

    event Registered(bytes32 indexed docHash);
    event NewVersionRegistered(bytes32 indexed docHash, bytes32 indexed expiredDocHash);

    modifier onlyOwner() {
        require(msg.sender == owner, "Sender not authorized");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function register(bytes32 _docHash) public onlyOwner() {
        docHashTime[_docHash] = block.timestamp;
        emit Registered(_docHash);
    }

    function registerMultiply(bytes32[] calldata _docHashes) public onlyOwner() {
        for(uint i = 0; i < _docHashes.length; i++) {
            bytes32 _docHash = _docHashes[i];
            docHashTime[_docHash] = block.timestamp;
            emit Registered(_docHash);
        }
    }

    function registerNewVersion(bytes32 _docHash, bytes32 _expiredDocHash) public onlyOwner() {
        docHashTime[_docHash] = block.timestamp;
        newVersions[_expiredDocHash] = _docHash;
        emit NewVersionRegistered(_docHash, _expiredDocHash);
    }

    function setTransaction(bytes32 _docHash, bytes32 _txHash) public onlyOwner() {
        docHashTx[_docHash] = _txHash;
    }

    function setTransactionMultiply(bytes32[] calldata _docHashes, bytes32 _txHash) public onlyOwner() {
        for(uint i = 0; i < _docHashes.length; i++) {
            docHashTx[_docHashes[i]] = _txHash;
        }
    }
}