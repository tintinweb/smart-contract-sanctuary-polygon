// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EscrowGuindoVersion.sol";

contract EscrowFactory {
    struct Escrow {
        address escrowContract;
        string ownerUserName;
        uint256 issueId;
    }
    struct Developer {
        address developer;
        string loginName;
    }

    Escrow[] public deployedEscrows;
    Developer[] public developers;

    event EscrowCreated(
        address indexed escrowContract,
        address indexed arbiter,
        address indexed depositor,
        uint256 amount,
        string ownerUserName,
        uint256 issueId
    );

    event NewDeveloper(address indexed developer, string loginName);

    function addDeveloper(address _developer, string memory _loginName) public {
        developers.push(Developer(_developer, _loginName));
    }

    function createEscrow(
        address _arbiter,
        string memory _ownerUserName,
        uint256 _issueId
    ) public payable {
        EscrowGuindoVersion newEscrow = new EscrowGuindoVersion{
            value: msg.value
        }(_arbiter);

        deployedEscrows.push(
            Escrow(address(newEscrow), _ownerUserName, _issueId)
        );

        emit EscrowCreated(
            address(newEscrow),
            _arbiter,
            msg.sender,
            msg.value,
            _ownerUserName,
            _issueId
        );
    }

    function getDeployedEscrows() public view returns (Escrow[] memory) {
        return deployedEscrows;
    }

    function getDevelopers() public view returns (Developer[] memory) {
        return developers;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EscrowGuindoVersion {
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