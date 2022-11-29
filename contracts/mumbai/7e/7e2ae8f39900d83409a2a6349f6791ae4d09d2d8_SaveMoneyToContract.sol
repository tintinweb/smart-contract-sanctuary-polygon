/**
 *Submitted for verification at polygonscan.com on 2022-11-28
*/

// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.7.0;
contract SaveMoneyToContract{
    address payable public MySelf;
    constructor() public {
        MySelf = msg.sender;
    }

    modifier onlyMe {
        require(msg.sender == MySelf);
        _;
    }
    
    function Save() payable public{
        require(msg.value == 0.1 ether);
    }
    function Withdraw() onlyMe public{
        MySelf.transfer(0.1 ether);
    }

}