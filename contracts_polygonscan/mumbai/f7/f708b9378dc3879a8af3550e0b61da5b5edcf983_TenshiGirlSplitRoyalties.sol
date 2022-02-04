/**
 *Submitted for verification at polygonscan.com on 2022-02-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract TenshiGirlSplitRoyalties {

    constructor(address _owner) {
        owner = _owner;
    }

    uint public counter = 1;
    address public owner;

    struct Info {
        address wallet;
        uint amount;
    }

    mapping(uint => Info) public _rewards;

    function addReward(address wallet, uint amount) external {
        require(msg.sender == owner, "Not the owner!");
        _rewards[counter].wallet = wallet;
        _rewards[counter].amount = amount;
        counter++;
    }

    function split() internal  {
        for (uint i; i < counter; i++) {
            Info memory info = _rewards[i];
            payable(info.wallet).transfer(info.amount);
            delete info;
        }
        counter = 1;
    } 

    receive() external payable {
        split();
    }
}