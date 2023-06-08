//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Main.sol";

contract Escrow {
    address public depositor;
    address public beneficiary;
    address public arbiter;
    bool public isApproved = false;
    uint public amount;

    event Approved(uint256 balance);

    modifier onlyMainContract() {
        require(msg.sender == depositor, "Only Main contract can esceute");
        _;
    }

    constructor(address _arbiter) payable {
        arbiter = _arbiter;

        depositor = msg.sender;
        amount = msg.value;
    }

    function cancelEscrow(address _arbiter) public onlyMainContract {
        (bool sent, ) = _arbiter.call{value: amount}("");
        require(sent, "Failed to send ETH");
    }

    function approve(address _beneficiary) public payable onlyMainContract {
        isApproved = true;
        beneficiary = _beneficiary;
        (bool sent, ) = beneficiary.call{value: amount}("");
        require(sent, "Failed to send Eth");

        emit Approved(amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Escrow.sol";

contract Main {
    //Initalize Escrow Contract
    Escrow public escrowInitialized;
    //Structs for each new EscrowContract
    struct Escrow_info {
        address escrowContract;
        string ownerUserName;
        uint256 issueId;
        uint256 repo;
        uint256 url;
    }

    //Struct for each new Developer who wants to use our Service
    struct Developer_info {
        address developerAddress;
        string loginName;
    }

    //Array of all the Escrow Structs
    Escrow_info[] public Escrows;
    //Array of all the Developer Structs
    Developer_info[] public Developers;

    //ERRORS

    //Event fired when a new Escrow/bounty is created
    event EscrowCreated(
        address indexed escrowContract,
        address indexed arbiter,
        address indexed depositor,
        uint256 amount,
        string ownerUserName,
        uint256 issueId,
        uint256 repo,
        uint256 url
    );
    event EscrowClosed(address indexed escrowContract, uint256 issueId);
    event EscrowClosedAfterApprove(
        address indexed escrowContract,
        uint256 issueId
    );

    //Event fired when a new Developer signIn
    event NewDeveloper(address indexed developer, string loginName);

    constructor(address escrowContractAddress) {
        // Initialize the Escrow contract
        escrowInitialized = Escrow(escrowContractAddress);
    }

    function setEscrowAddress(address escrowContractAddress) internal {
        escrowInitialized = Escrow(escrowContractAddress);
    }

    /**
     *
     * @param _developer address of the developer. We get this from wallet
     * @param _loginName loginName formGithub, we get this from singIn SSO
     */
    function addDeveloper(address _developer, string memory _loginName) public {
        Developers.push(Developer_info(_developer, _loginName));
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
        uint256 _issueId,
        uint256 _repo,
        uint256 _url
    ) public payable {
        Escrow newEscrow = new Escrow{value: msg.value}(_arbiter);

        Escrows.push(
            Escrow_info(
                address(newEscrow),
                _ownerUserName,
                _issueId,
                _repo,
                _url
            )
        );

        emit EscrowCreated(
            address(newEscrow),
            _arbiter,
            msg.sender,
            msg.value,
            _ownerUserName,
            _issueId,
            _repo,
            _url
        );
    }

    /**
     *
     * @param escrowContractAddress address from escrow contract that we want to delete
     */
    function deleteEscrowArray(
        address escrowContractAddress
    ) external returns (uint256) {
        setEscrowAddress(escrowContractAddress);
        uint256 arrayLength = Escrows.length;

        if (arrayLength == 0) {
            revert("No escrows found");
        }
        for (uint256 i = 0; i < arrayLength; i++) {
            if (Escrows[i].escrowContract == escrowContractAddress) {
                if (i < arrayLength - 1) {
                    Escrows[i] = Escrows[arrayLength - 1];
                }
                emit EscrowClosed(escrowContractAddress, Escrows[i].issueId);
                Escrows.pop();

                escrowInitialized.cancelEscrow(msg.sender);
                return i;
            }
        }
        revert("Escrow contract not found");
    }

    /**
     *
     * @param escrowContractAddress address of the escrow contract that we want to approve
     * @param beneficiary who get the money after approve
     */
    function deleteEscrowArrayWhenApproved(
        address escrowContractAddress,
        address beneficiary
    ) external returns (uint256) {
        setEscrowAddress(escrowContractAddress);
        uint256 arrayLength = Escrows.length;

        if (arrayLength == 0) {
            revert("No escrows found");
        }
        for (uint256 i = 0; i < arrayLength; i++) {
            if (Escrows[i].escrowContract == escrowContractAddress) {
                if (i < arrayLength - 1) {
                    Escrows[i] = Escrows[arrayLength - 1];
                }
                emit EscrowClosedAfterApprove(
                    escrowContractAddress,
                    Escrows[i].issueId
                );
                Escrows.pop();

                escrowInitialized.approve(beneficiary);
                return i;
            }
        }
        revert("Escrow contract not found");
    }

    function getEscrows() public view returns (Escrow_info[] memory) {
        return Escrows;
    }

    function getDevelopers() public view returns (Developer_info[] memory) {
        return Developers;
    }
}