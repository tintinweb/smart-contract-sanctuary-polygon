// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract Oracle {

    event $set(bytes32 hash, bytes32 addr);
    event $remove(bytes32 hash, bytes32 addr);
    event $clear(bytes32 hash);

    struct HashBN {
        bytes32 hash;
        uint blockNumber;
    }

    address public owner;

    bool public start;

    HashBN[] hashArr;

    mapping(bytes32 => uint) public hashIMap;

    mapping(bytes32 => bytes32[]) oracleMap;

    mapping(bytes32 => mapping(bytes32 => uint)) public oracleIMap;

    modifier onlyOwner(){
        require(msg.sender == owner, "Insufficient Permissions");
        _;
    }

    modifier isStart(){
        require(start || msg.sender == owner, "The contract is not open and cannot be operated");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setStart(bool value) public onlyOwner {
        start = value;
    }

    function get(bytes32 hash) public view returns (bytes32[] memory){
        return oracleMap[hash];
    }

    function getFileList() public view onlyOwner returns (HashBN[] memory){
        return hashArr;
    }

    function set(bytes32 hash, bytes32 addr) public isStart {

        require(oracleIMap[hash][addr] == 0, "Address already exists");

        oracleMap[hash].push(addr);
        oracleIMap[hash][addr] = oracleMap[hash].length;

        if (hashIMap[hash] == 0) {
            hashArr.push(HashBN(hash, block.number));
            hashIMap[hash] = hashArr.length;
        }

        emit $set(hash, addr);
    }

    function remove(bytes32 hash, bytes32 addr) public isStart {
        uint index = oracleIMap[hash][addr];
        require(index != 0, "Address does not exist");

        bytes32[] storage arr = oracleMap[hash];

        for (uint i = index - 1; i < arr.length - 1; i++) {
            arr[i] = arr[i + 1];
        }

        arr.pop();

        delete oracleIMap[hash][addr];

        if (arr.length == 0) {
            delSingleHash(hash);
        }
        emit $remove(hash, addr);
    }

    function clear(bytes32 hash) public onlyOwner {
        uint len = oracleMap[hash].length;
        require(len != 0, "Hash does not exist");

        for (uint i = 0; i < len; i++) {
            bytes32 addr = oracleMap[hash][i];
            delete oracleIMap[hash][addr];
        }

        delete oracleMap[hash];

        delSingleHash(hash);

        emit $clear(hash);
    }

    function delSingleHash(bytes32 hash) private {
        uint index = hashIMap[hash];
        require(index != 0, "Hash does not exist");
        for (uint i = index - 1; i < hashArr.length - 1; i++) {
            hashArr[i] = hashArr[i + 1];
        }
        hashArr.pop();
        delete hashIMap[hash];
    }
}