/**
 *Submitted for verification at polygonscan.com on 2023-02-02
*/

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.0;

contract Escrow {
    struct EscrowData {
        address payable user1;
        address payable user2;
        uint256 user1Amount;
        uint256 user2Amount;
        uint256 user1Payout;
        uint256 adminPayout;
        bool fundsDistributed;
    }

    address payable public admin;
    EscrowData[] public escrows;

    constructor(address payable _admin) public {
        admin = _admin;
    }

    function depositForUser1(uint256 _escrowIndex) public payable {
        EscrowData storage escrow = escrows[_escrowIndex];
        escrow.user1Amount += msg.value;
    }

    function depositForUser2(uint256 _escrowIndex) public payable {
        EscrowData storage escrow = escrows[_escrowIndex];
        escrow.user2Amount += msg.value;
    }

    function createEscrow(address payable _user1, address payable _user2) public returns (uint256) {
        EscrowData memory newEscrow = EscrowData({
            user1: _user1,
            user2: _user2,
            user1Amount: 0,
            user2Amount: 0,
            user1Payout: 0,
            adminPayout: 0,
            fundsDistributed: false
        });

        escrows.push(newEscrow);

        return escrows.length - 1;
    }

function distributeFunds(uint256 _escrowIndex) public {
    EscrowData storage escrow = escrows[_escrowIndex];

    require(!escrow.fundsDistributed, "Funds have already been distributed");
    require(msg.sender == admin, "Only the admin can distribute funds");

    uint256 totalAmount = escrow.user1Amount + escrow.user2Amount;
    uint256 user1Payout = totalAmount * 9 / 10;
    uint256 adminPayout = totalAmount / 10;

    require(escrow.user1.send(user1Payout), "Payout to user 1 failed");
    require(escrow.user2.send((totalAmount - user1Payout)), "Payout to user 2 failed");
    require(admin.send(adminPayout), "Payout to admin failed");

    escrow.fundsDistributed = true;
}

}