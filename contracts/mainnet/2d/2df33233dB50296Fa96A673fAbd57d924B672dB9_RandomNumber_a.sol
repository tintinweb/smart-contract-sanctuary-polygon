// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

import "./VRFConsumerBase.sol";
import "./Ownable.sol";

contract RandomNumber_a is VRFConsumerBase, Ownable {
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomResult;
    
    /**
     * Constructor inherits VRFConsumerBase
     * 
     * Network: Polygon (Matic) Mumbai Testnet
     * Chainlink VRF Coordinator address: 0x8C7382F9D8f56b33781fE506E897a4F1e2d17255
     * LINK token address:                0x326C977E6efc84E512bB9C30f76E30c160eD06FB
     * Key Hash: 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da
     */
    constructor() 
        VRFConsumerBase(
            0x3d2341ADb2D31f1c5530cDC622016af293177AE0, // VRF Coordinator
            0xb0897686c545045aFc77CF20eC7A532E3120E0F1  // LINK Token
        ) public
    {
        keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da; // Key hash for VRF job on Polygon mainnet
        fee = 0.0001 ether; // 0.0001 LINK
    }
    
    /** 
     * Requests randomness 
     */
    function getRandomNumber() public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) > fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }
    
    /** 
     * Requests set fee random number 
     */
    function setFeeRandomNumber(uint256 _fee) external onlyOwner {
        require(_fee > 0, "Fee random number is invalid");
        fee = _fee;
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
    }
    
    /**
     * Allows the contract owner to claim any LINK tokens that were sent to the contract
     */
    function ownerClaimToken() external onlyOwner {
        // Get the current balance of LINK tokens in the contract
        uint256 balance = LINK.balanceOf(address(this));

        // Make sure there are actually LINK tokens to claim
        require(balance > 0, "Not enough LINK for owner claim token");

        // Transfer the LINK tokens to the owner of the contract
        LINK.transfer(owner(), balance);
    }
}