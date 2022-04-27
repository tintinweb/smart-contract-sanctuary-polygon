/**
 *Submitted for verification at polygonscan.com on 2022-04-26
*/

// SPDX-License-Identifier: MIT - by @anto6314

// cType : 1 -> Withdraw
// cType : 2 -> setApprovers
// cType : 3 -> setOwnership

pragma solidity 0.8.7;

contract Treasury {
    uint private depositId = 0;
    uint private confirmationId = 0;
    uint private lastDepositId = 0;
    uint private lastConfirmationId = 0;

    bool public hasOwnership = true;

    address private admin = address(msg.sender);
    address private treasury = address(this);
    address private lastAdmin = 0x0000000000000000000000000000000000000000;

    mapping(uint256 => Deposit) private deposits;
    mapping(uint256 => Confirmation) public confirmations;

    address[] public approvers = [
        0x0000000000000000000000000000000000000000,
        0x0000000000000000000000000000000000000000
    ];

    struct Deposit {
        uint id;
        uint ammount;
        address payable from;
    }

    struct Confirmation {
        uint id;
        uint cType;
        uint ammount;
        bool approvation1;
        bool approvation2;
        bool isApproved;
        bool isDone;
        address payable receiver;
    }

    modifier onlyAdmin() {
        require(hasOwnership == true, "The contract has no ownership");
        require(msg.sender == admin, 'Only the admin can call this function');
        _;
    }

    modifier onlyApprover1() {
        require(msg.sender == approvers[0], 'Only the first approver can call this function');
        _;
    }

    modifier onlyApprover2() {
        require(msg.sender == approvers[1], 'Only the second approver can call this function');
        _;
    }

    function receiveMoney() public payable returns (uint) {
        deposits[depositId] = Deposit(depositId, msg.value, payable(msg.sender));
        lastDepositId = depositId;
        depositId = depositId+1;
        return lastDepositId;
    }

    function withdrawMoney(address payable to, uint amount, uint id) public {
        require(msg.sender == approvers[0] || msg.sender == approvers[1], "Only the approvers can call this function");
        require(amount <= getBalance(), "not enough funds.");
        if(checkConfirmation(id, to) == true){
            to.transfer(amount);
        } else {
            revert();
        }
    }

    function initialSetApprovers (address approver1, address approver2) public onlyAdmin {
        approvers[0] = payable(approver1);
        approvers[1] = payable(approver2);
    }

    function setApprover (address newApprover, address receiver, uint slot, uint id) public {
        require(msg.sender == approvers[0] || msg.sender == approvers[1], "Only the approvers can call this function");
        uint cType = getCType(id);

        if (cType == 2) {
            if(checkConfirmation(id, receiver) == true){
                approvers[slot] = payable(newApprover);
                confirmations[id].isDone = true;
            } else {
                revert();
            }
        } else {
            revert();
        }
    }

    function restoreOwnership (address newAdmin, address receiver, uint id) public {
        require(msg.sender == approvers[0] || msg.sender == approvers[1], "Only the approvers can call this function");
        uint cType = getCType(id);

        if (cType == 3) {
            if(checkConfirmation(id, receiver) == true){
                admin = payable(newAdmin);
                hasOwnership = true;
                confirmations[id].isDone = true;
            } else {
                revert();
            }
        } else {
            revert();
        }
    }

    function getBalance() public view returns (uint256){
        require(msg.sender == approvers[0] || msg.sender == approvers[1], "Only the approvers can call this function");
        return payable(address(this)).balance;
    }

    function renounceOwnership() public onlyAdmin {
        lastAdmin = admin;
        admin = 0x0000000000000000000000000000000000000000;
        hasOwnership = false;
    }

    function checkConfirmation(uint id, address receiver) private returns (bool) {
        require(msg.sender == approvers[0] || msg.sender == approvers[1], "Only the approvers can call this function");
        if (confirmations[id].isDone == true) {
            return false;
        } else {
            if (confirmations[id].receiver == receiver) {
                if (confirmations[id].approvation1 == true && confirmations[id].approvation2 == true) {
                    confirmations[id].isApproved = true;
                    return true;
                } else {
                    return false;
                }
            } else {
                return false;
            }
        }
    }

    function getCType(uint id) internal view returns (uint) {
        require(msg.sender == approvers[0] || msg.sender == approvers[1], "Only the approvers can call this function");
        return confirmations[id].cType;
    }

    function newConfirmation(address payable receiver, uint ctype, uint ammount) public {
        require(msg.sender == approvers[0] || msg.sender == approvers[1], "Only the approvers can call this function");
        confirmations[confirmationId] = Confirmation(confirmationId, ctype, ammount, false, false, false, false, receiver);
        lastConfirmationId = confirmationId;
        confirmationId = confirmationId+1;
    }

    function confirmation1(uint id) public onlyApprover1 {
        confirmations[id].approvation1 = true;
    }

    function confirmation2(uint id) public onlyApprover2 {
        confirmations[id].approvation2 = true;
    }

    receive() external payable {
        receiveMoney();
    }
}