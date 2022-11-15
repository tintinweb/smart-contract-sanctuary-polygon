// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;


contract KwikTrustTesting{

    event checkString(string name);
    event checkBytes(bytes data);

    function getString(bytes calldata _name) public returns (string memory){
        string memory name = string(_name);
        emit checkString(name);
        emit checkBytes(_name);

        return name;
    }

    function getBytes(string memory _data) public returns (bytes memory){
        bytes memory data = bytes(_data);
        emit checkString(_data);
        emit checkBytes(data);
        return data;
    }
    
}