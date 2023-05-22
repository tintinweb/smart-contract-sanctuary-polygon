// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./VRFConsumerBase.sol";
import "./AccessControl.sol";

contract RandomNumber is VRFConsumerBase, AccessControl {
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 private randomNumber;
    
    bytes32 public constant RANDOM_NUMBER_FLAG = keccak256("RANDOM_NUMBER_FLAG"); 
    bytes32 public constant UPDATER_FEE_RANDOM = keccak256("UPDATER_FEE_RANDOM"); 
    bytes32 public constant CLAIM_TOKEN_FLAG = keccak256("CLAIM_TOKEN_FLAG"); 
    
    /**
     * Constructor inherits VRFConsumerBase
     * 
     * Network: Polygon (Matic)
     * Chainlink VRF Coordinator address: 0x3d2341ADb2D31f1c5530cDC622016af293177AE0
     * LINK token address:                0xb0897686c545045aFc77CF20eC7A532E3120E0F1
     * Key Hash: 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da
     */
    constructor() 
        VRFConsumerBase(
            0x3d2341ADb2D31f1c5530cDC622016af293177AE0, // VRF Coordinator
            0xb0897686c545045aFc77CF20eC7A532E3120E0F1  // LINK Token
        ) 
    {
        keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da; // Key hash for VRF job on Polygon mainnet
        fee = 0.0001 ether; // 0.0001 
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(RANDOM_NUMBER_FLAG, msg.sender);
        _grantRole(UPDATER_FEE_RANDOM, msg.sender);
        _grantRole(CLAIM_TOKEN_FLAG, msg.sender);
    }
    
    /** 
     * Requests randomness 
     */
    function getRandomNumber() public onlyRole(RANDOM_NUMBER_FLAG) returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) > fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }
    
    /** 
     * Requests get random number
     */
    function randomResult() public onlyRole(RANDOM_NUMBER_FLAG) view returns(uint256) {
        return randomNumber;
    }
    
    /** 
     * Requests set fee random number 
     */
    function setFeeRandomNumber(uint256 _fee) external onlyRole(UPDATER_FEE_RANDOM) {
        require(_fee > 0, "Fee random number is invalid");
        fee = _fee;
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomNumber = randomness;
    }
    
    /**
     * Allows the contract owner to claim any LINK tokens that were sent to the contract
     */
    function ownerClaimToken() external onlyRole(CLAIM_TOKEN_FLAG) {
        // Get the current balance of LINK tokens in the contract
        uint256 balance = LINK.balanceOf(address(this));

        // Make sure there are actually LINK tokens to claim
        require(balance > 0, "Not enough LINK for owner claim token");

        // Transfer the LINK tokens to the owner of the contract
        LINK.transfer(msg.sender, balance);
    }
}