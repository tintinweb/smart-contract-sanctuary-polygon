// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

import "./VRFConsumerBase.sol";
import "./Ownable.sol";

contract RandomNumberOnlyTime is VRFConsumerBase, Ownable {
    bytes32 internal keyHash; // Chainlink VRF key hash
    uint256 internal fee; // Chainlink VRF fee
    bytes32 public requestId; // Chainlink VRF request ID
    uint256 public randomResult; // Generated random number
    uint256 private lastTimeRandom; // Timestamp of the last generated random number
    uint256 private genInterval; // Time interval (in seconds) between each random number generation

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
    function getRandomNumber() public returns (bytes32) {
        require(LINK.balanceOf(address(this)) > fee, "Not enough LINK - fill contract with faucet");
        if(block.timestamp - lastTimeRandom > genInterval) {
            requestId = requestRandomness(keyHash, fee);
            lastTimeRandom = block.timestamp;
            return requestId;
        }
    }

    /** 
     * Create random number from chainlink server
     */
    function setFeeRandomNumber(uint256 _fee) external onlyOwner{
        require(_fee > 0, "Fee random number is invalid");
        fee = _fee;
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 _requestId, uint256 _randomResult) internal override {
        require(requestId == _requestId, "Wrong requestId");
        randomResult = _randomResult;
    }

    /**
    * @dev Sets the generation interval for creating random numbers.
    * @param _genInterval The new generation interval to set.
    * Requirements:
    * The caller must be the contract owner.
    */
    function setGenInterval(uint256 _genInterval) external onlyOwner{
        genInterval = _genInterval;
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