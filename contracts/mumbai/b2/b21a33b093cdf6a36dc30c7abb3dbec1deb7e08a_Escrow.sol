/**
 *Submitted for verification at polygonscan.com on 2023-02-08
*/

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.0;

/***
* @author: sriharikapu
* @email : [email protected]
* @website : www.sriharikapu.com
*/


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction underflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

}


contract Escrow {

    using SafeMath for uint256;

    struct EscrowData {
        address payable user1;
        address payable user2;
        uint256 user1Amount;
        uint256 user2Amount;
        uint256 user1Payout;
        uint256 user2Payout;
        uint256 adminPayout;
        bool fundsDistributed;
    }

    address payable public admin;
    EscrowData[] public escrows;

    constructor(address payable _admin) public {
        admin = _admin;
    }

    function depositForUser1(uint256 _escrowIndex) public payable {
        require(msg.value == 100000000000000000, "Only 0.1 MATIC Deposit is allowed !"); // Minimum deposit amount 0.1 MATIC
        EscrowData storage escrow = escrows[_escrowIndex];
        escrow.user1Amount += msg.value;
    }

    function depositForUser2(uint256 _escrowIndex) public payable {
        require(msg.value == 100000000000000000, "Only 0.1 MATIC Deposit is allowed !"); // Minimum deposit amount 0.1 MATIC
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
            user2Payout: 0,
            adminPayout: 0,
            fundsDistributed: false
        });

        escrows.push(newEscrow);

        return escrows.length - 1;
    }

    function distributeFunds(uint256 _escrowIndex, bool _pickedUser) public {
        EscrowData storage escrow = escrows[_escrowIndex];

        require(!escrow.fundsDistributed, "Funds have already been distributed");
        require(msg.sender == admin, "Only the admin can distribute funds");

        uint256 totalAmount = escrow.user1Amount + escrow.user2Amount;
        uint256 userPayout = totalAmount * 9 / 10;
        uint256 adminPayout = totalAmount / 10;

        if(_pickedUser == true){
            require(escrow.user1.send(userPayout), "Payout to user 1 failed");
            require(admin.send(adminPayout), "Payout to admin failed");
            escrow.user1Payout += userPayout;
            escrow.adminPayout += adminPayout;
            
        } else if(_pickedUser == false){
            require(escrow.user2.send(userPayout), "Payout to user 2 failed");
            require(admin.send(adminPayout), "Payout to admin failed");   
            escrow.user2Payout += userPayout;
            escrow.adminPayout += adminPayout;

        }

        escrow.fundsDistributed = true;
    }

}