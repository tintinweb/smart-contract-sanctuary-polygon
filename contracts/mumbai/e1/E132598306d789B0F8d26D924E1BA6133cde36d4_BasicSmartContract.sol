/**
 *Submitted for verification at polygonscan.com on 2023-01-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract BasicSmartContract {
    string public stateVariable = "MY DATA IS HERE";

    uint256 public changeStateVariable;

    constructor(){
    }

    function ChangeState(uint256 _changeStateVariable) public payable {
        changeStateVariable = _changeStateVariable;
    }
     function ChangeStateSrting(string memory value) public  {
        stateVariable = value;
    }
}