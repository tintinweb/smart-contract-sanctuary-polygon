/**
 *Submitted for verification at polygonscan.com on 2023-02-02
*/

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.0;

contract Escrow {
    address payable public user1;
    address payable public user2;
    address payable public admin;
    uint256 public user1Amount;
    uint256 public user2Amount;

    constructor(address payable _admin) public {
        admin = _admin;
    }

    function deposit(address payable _user) public payable {
        if (_user == user1) {
            user1Amount += msg.value;
        } else if (_user == user2) {
            user2Amount += msg.value;
        }
    }

    function distributeFunds() public {
        require(msg.sender == admin, "Only the admin can distribute funds");

        uint256 user1Payout = user1Amount * 9 / 10;
        uint256 adminPayout = user1Amount / 10;

        require(user1.send(user1Payout), "Payout to user 1 failed");
        require(admin.send(adminPayout), "Payout to admin failed");
    }
}