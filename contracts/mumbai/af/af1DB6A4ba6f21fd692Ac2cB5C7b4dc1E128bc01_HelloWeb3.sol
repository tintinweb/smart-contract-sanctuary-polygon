// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract HelloWeb3{
    string public _string = "Hello Web3!";
    
    event NewData(string indexed data);

    function setString(string calldata _newData) external {
        _string = _newData;
        emit NewData(_newData);
    }

    function sayHello() view public returns(string memory) {
        return _string;
    }
}