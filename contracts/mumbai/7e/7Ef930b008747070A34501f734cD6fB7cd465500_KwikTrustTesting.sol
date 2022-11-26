// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;


contract KwikTrustTesting{

    string public name;
    bytes public data;

    event checkString(string name);
    event checkBytes(bytes data);

    function getString(bytes calldata _name) public returns (string memory){
        name = string(_name);
        emit checkString(name);

        return name;
    }

    function getBytes(string memory _data) public returns (bytes memory){
        data = bytes(_data);
        emit checkBytes(data);
        return data;
    }
    
}