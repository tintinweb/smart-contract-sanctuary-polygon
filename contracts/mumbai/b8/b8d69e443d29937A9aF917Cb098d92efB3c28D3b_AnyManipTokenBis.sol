/**
 *Submitted for verification at polygonscan.com on 2022-06-11
*/

// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract AnyManipToken{
    function consumeTokens(address consumer, uint toConsume) public{}
}

contract AnyManipTokenBis{
    AnyManipToken AnyManipContract;

    event ActionExecuted(address, string, uint);
    constructor(address TokenContract){
        AnyManipContract = AnyManipToken(TokenContract);
    }
    function executeAction(string memory action, uint amount) public{
        AnyManipContract.consumeTokens(msg.sender,amount);
        emit ActionExecuted(msg.sender,action,amount);
    }
}