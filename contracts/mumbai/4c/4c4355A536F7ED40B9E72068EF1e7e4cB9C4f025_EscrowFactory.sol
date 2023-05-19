//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./EscrowV1.sol";

contract EscrowFactory {
    address[] public deployedEscrows;

    event EscrowCreated(
        address indexed escrowContract,
        address indexed arbiter,
        address indexed depositor,
        uint256 amount
    );

    function createEscrow(address _arbiter) public payable {
        EscrowV1 newEscrow = new EscrowV1{value: msg.value}(_arbiter);
        deployedEscrows.push(address(newEscrow));

        emit EscrowCreated(address(newEscrow), _arbiter, msg.sender, msg.value);
    }

    function getDeployedEscrows() public view returns (address[] memory) {
        return deployedEscrows;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EscrowV1 {
    address public depositor;
    address public beneficiary;
    address public arbiter;
    bool public isApproved = false;
    uint public amount;

    event Approved(uint256 balance);

    constructor(address _arbiter) payable {
        arbiter = _arbiter;
        depositor = msg.sender;
        amount = msg.value;
    }

    function approve(address _beneficiary) public payable {
        require(msg.sender == arbiter, "Only arbiter can approve");

        isApproved = true;
        beneficiary = _beneficiary;
        (bool sent, ) = beneficiary.call{value: amount}("");
        require(sent, "Failed to send Ether");

        emit Approved(amount);
    }
}