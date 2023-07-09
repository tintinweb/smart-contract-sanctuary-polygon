/**
 *Submitted for verification at polygonscan.com on 2023-07-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestnetContribution {
    address payable public immutable owner;
    address payable public immutable beneficiary;
    bool public materialReleaseConditionMet = false;
    uint256 public deadline;
    uint256 public countdownPeriod;
    uint256 public threshold;
    bool public isKeySet = false;

    bytes32 public keyPlaintextHash;
    bytes public keyCiphertext;
    bytes public keyPlaintext;

    mapping(address => uint256) public amountContributedByAddress;

    event Contribute(address indexed contributor, uint256 amount);
    event Decryptable(address indexed lastContributor);
    event Withdraw(address indexed beneficiary, uint256 amount);

    constructor(
        uint256 _countdownPeriod,
        uint256 _threshold,
        address payable _beneficiary
    ) {
        countdownPeriod = _countdownPeriod;
        deadline = block.timestamp + _countdownPeriod;
        owner = payable(msg.sender);
        threshold = _threshold;
        beneficiary = _beneficiary;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    modifier onlyBeneficiary() {
        require(
            msg.sender == beneficiary,
            "Only the beneficiary can call this function."
        );
        _;
    }

    function commitSecret(bytes32 _hash, bytes memory _ciphertext) external onlyOwner {
        require(!isKeySet, "Key already set.");

        keyPlaintextHash = _hash;
        keyCiphertext = _ciphertext;
        isKeySet = true;
    }

    function revealSecret(bytes memory secret) external {
        require(materialReleaseConditionMet, "Material has not been set for a release.");
        require(keccak256(secret) == keyPlaintextHash, "Invalid secret provided, hash does not match.");
        keyPlaintext = secret;
    }

    function contribute() external payable {
        require(block.timestamp < deadline, "Cannot contribute after the deadline");
        require(isKeySet, "Key has not been set.");

        amountContributedByAddress[msg.sender] += msg.value; // Add contribution to the mapping

        if (address(this).balance >= threshold) {
            materialReleaseConditionMet = true;
            emit Decryptable(msg.sender);
        }

        deadline = block.timestamp + countdownPeriod;

        emit Contribute(msg.sender, msg.value);
    }

    function resetClock() external onlyOwner {
        deadline = block.timestamp + countdownPeriod;
    }

    function setMaterialReleaseConditionMet(bool status) external onlyOwner {
        materialReleaseConditionMet = status;
    }

    receive() external payable {
        emit Contribute(msg.sender, msg.value);
    }

    function withdraw() external onlyBeneficiary {
        require(deadline < block.timestamp, "Cannot withdraw funds before deadline");

        if (materialReleaseConditionMet) {
            require(keyPlaintext.length > 0, "Material has been released but key has not been revealed.");
        }

        beneficiary.transfer(address(this).balance);
        emit Withdraw(beneficiary, address(this).balance);
    }
}