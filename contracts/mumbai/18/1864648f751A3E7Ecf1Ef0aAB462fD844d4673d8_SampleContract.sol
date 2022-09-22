/**
 *Submitted for verification at polygonscan.com on 2022-09-21
*/

pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

contract SampleContract {
    address public manager;
    address[] public players;
    
    constructor() {
        manager = msg.sender;
    }

    function sendMoneyToAccount(address payable account) public {
        require(msg.sender == manager, "Caller is not owner");
        uint256 amount = 1 ether;
        account.transfer(amount);
    }

    function sendMulti(address payable [] memory _addrs) payable public {
        uint256 prize2 = msg.value / 4;
        uint256 prize3 = prize2 / 2;
        uint256 subPrize = prize2 + prize3;
        uint256 prize1 = subPrize;
        _addrs[0].transfer(prize1);
        _addrs[1].transfer(prize2);
        _addrs[2].transfer(prize3);
    }
}