// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

contract Testament {
    /*================= STRUCT =====================*/
    struct Will {
        address testator;
        uint256 creationTimestamp;
        uint256 assetAmount;
        address[] beneficiaries;
        uint8[] allocationPercentages;
        address[] witness;
        bool activated;
        uint8 confirmationMissAmount;
        uint256 lastConfirmationTimestamp;
    }

    /*================= STAGE =====================*/
    constructor(address _owner) {
        will.testator = _owner;
    }

    Will private will;
    mapping(address => bool) private witnessAccepted;

    /*================= EVENT =====================*/
    event ConfirmationRequestSent(
        address indexed testator,
        uint256 confirmationTime
    );
    event WillCreated(address indexed testator, uint256 creationTimestamp);
    event WillActivated(address indexed testator);
    event ProofOfLifeSuccess(address indexed testator);
    event MoneyTransferred(
        address indexed sender,
        address receiver,
        uint256 amount
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /*================= MODIFIER =====================*/
    modifier onlyNonActivated() {
        require(!will.activated, "Will activated");
        _;
    }

    modifier onlyOwner() {
        require(will.testator == msg.sender, "Caller is not the owner");
        _;
    }

    /*================= FUNCTION =====================*/
    function create(
        address[] memory _beneficiaries,
        uint8[] memory _allocationPercentages,
        address[] memory _witness
    ) external payable {
        require(
            _beneficiaries.length == _allocationPercentages.length,
            "Beneficiaries and percentages must have the same length"
        );
        require(
            _beneficiaries.length > 0,
            "At least one beneficiary must be specified"
        );

        will = Will(
            msg.sender,
            block.timestamp,
            msg.value,
            _beneficiaries,
            _allocationPercentages,
            _witness,
            false,
            0,
            block.timestamp
        );

        emit WillCreated(msg.sender, block.timestamp);
    }

    //TODO: miss case request active will
    function activateWill() internal onlyNonActivated {
        will.activated = true;

        //Distribute assets to the beneficiaries
        distributeAssets();

        emit WillActivated(msg.sender);
    }

    //Called chainlink: using automation
    function sendProofOfLifeRequest() external onlyNonActivated {
        if (will.confirmationMissAmount >= 5) {
            activateWill();
        } else {
            uint256 lastConfirmationTime = will.lastConfirmationTimestamp;

            //The time between two confirmations is 356 days
            uint256 confirmationInterval = 0 seconds;

            if (
                block.timestamp >= lastConfirmationTime + confirmationInterval
            ) {
                //Update the confirmation time
                will.lastConfirmationTimestamp = block.timestamp;
                will.confirmationMissAmount++;

                emit ConfirmationRequestSent(msg.sender, block.timestamp);
            }
        }
    }

    function proofOfLife() external onlyNonActivated onlyOwner {
        will.confirmationMissAmount--;

        //Check if the activation threshold is reached
        if (will.confirmationMissAmount >= 5) {
            activateWill();
        } else {
            will.confirmationMissAmount = 0;
        }

        emit ProofOfLifeSuccess(msg.sender);
    }

    function distributeAssets() private onlyNonActivated {
        uint256 totalAssetAmount = will.assetAmount;
        address[] memory beneficiaries = will.beneficiaries;
        uint8[] memory allocationPercentages = will.allocationPercentages;
        uint256 beneficiariesSize = beneficiaries.length;

        address beneficiary;
        uint8 allocationPercentage;
        uint256 beneficiaryAmount;
        for (uint256 i = 0; i < beneficiariesSize; i++) {
            beneficiary = beneficiaries[i];
            allocationPercentage = allocationPercentages[i];
            beneficiaryAmount = (totalAssetAmount * allocationPercentage) / 100;

            transferTo(beneficiary, beneficiaryAmount);
        }
    }

    function transferTo(address _recipient, uint256 amount)
    private
    onlyNonActivated
    {
        payable(_recipient).transfer(amount);
        emit MoneyTransferred(address(this), _recipient, amount);
    }

    function deposit() public payable onlyNonActivated {
        //check sender's will
        will.assetAmount += msg.value;
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(will.assetAmount >= amount, "Insufficient balance");

        will.assetAmount -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    function changeOwner(address _newOwner) public onlyOwner {
        require(_newOwner != will.testator, "New owner is the zero address");
        emit OwnershipTransferred(will.testator, _newOwner);
        will.testator = _newOwner;
    }

    function getAllBeneficiaries() public view returns (address[] memory) {
        return will.beneficiaries;
    }

    function getAllocationPercentages() public view returns (uint8[] memory) {
        return will.allocationPercentages;
    }

    function getAssetAmount() public view returns (uint256) {
        return will.assetAmount;
    }

    function getConfirmationMissAmount() public view returns (uint8) {
        return will.confirmationMissAmount;
    }

    function getConfirmationTimestamp() public view returns (uint256) {
        return will.lastConfirmationTimestamp;
    }

    function getTestator() public view returns (address) {
        return will.testator;
    }

    function getStatusWill() public view returns (bool) {
        return will.activated;
    }

    function getCreationTimestamp() public view returns (uint256) {
        return will.creationTimestamp;
    }
}