pragma solidity ^0.8.0;

contract MultiSig {
    address public owner1;
    address public owner2;
    mapping(address => bool) public approvals;

    constructor() {
        // Set the initial owners to address(0) to indicate they are not yet registered
        owner1 = address(0);
        owner2 = address(0);
    }

    function register() external {
        require(owner1 == address(0) || owner2 == address(0), "Owners already registered");
        require(!approvals[msg.sender], "Already registered");

        if (owner1 == address(0)) {
            owner1 = msg.sender;
        } else if (owner2 == address(0)) {
            owner2 = msg.sender;
        }

        approvals[msg.sender] = true;
    }

    function approve() external {
        require(owner1 == msg.sender || owner2 == msg.sender, "Unauthorized approver");
        approvals[msg.sender] = true;
    }

    function revokeApproval() external {
        require(owner1 == msg.sender || owner2 == msg.sender, "Unauthorized revoker");
        approvals[msg.sender] = false;
    }

    function isApproved() public view returns (bool) {
        return approvals[owner1] && approvals[owner2];
    }
}