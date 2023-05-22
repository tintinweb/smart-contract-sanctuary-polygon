// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EscrowGuindoVersion.sol";

contract EscrowFactory {
    //Structs for each new EscrowContract
    struct Escrow {
        address escrowContract;
        string ownerUserName;
        uint256 issueId;
    }

    //Struct for each new Developer who wants to use our Service
    struct Developer {
        address developer;
        string loginName;
    }

    //Array of all the Escrow Structs
    Escrow[] public deployedEscrows;
    //Array of all the Developer Structs
    Developer[] public developers;

    //Event fired when a new Escrow/bounty is created
    event EscrowCreated(
        address indexed escrowContract,
        address indexed arbiter,
        address indexed depositor,
        uint256 amount,
        string ownerUserName,
        uint256 issueId
    );

    //Event fired when a new Developer signIn
    event NewDeveloper(address indexed developer, string loginName);

    /**
     *
     * @param _developer address of the developer. We get this from wallet
     * @param _loginName loginName formGithub, we get this from singIn SSO
     */
    function addDeveloper(address _developer, string memory _loginName) public {
        developers.push(Developer(_developer, _loginName));

        emit NewDeveloper(_developer, _loginName);
    }

    /**
     *
     *  @param _arbiter address of the arbiter who can apporve the payment
     *  @param _ownerUserName string with the name of the owner of the issue/repo
     *  @param _issueId uint256 with the numeric Id of the issue
     */

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