// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract LogicContract {
    uint public x;

    function setX(uint _x ) external {
        x = _x;
    }
}

contract MasterContract {
    uint public value;
    address public contractAddress;
    
    function setValueX(uint _x ) public {
        LogicContract(contractAddress).setX(_x);
    }

    function setContractAddress(address _contractOneAddress ) external {
        contractAddress = _contractOneAddress;
    }
}