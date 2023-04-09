// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

import "./VRFConsumerBase.sol";


contract RandomNumberOnlyTime is VRFConsumerBase {
    bytes32 internal keyHash; // Chainlink VRF key hash
    uint256 internal fee; // Chainlink VRF fee
    address public _owner; // Address of contract owner
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
     * Key Hash: 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4
     */
    constructor() 
        VRFConsumerBase(
            0x8C7382F9D8f56b33781fE506E897a4F1e2d17255, // VRF Coordinator
            0x326C977E6efc84E512bB9C30f76E30c160eD06FB  // LINK Token
        ) public
    {
        keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
        fee = 0.0001 ether;
        _owner = msg.sender;
        lastTimeRandom = block.timestamp;
        genInterval = 1;
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
    function setFeeRandomNumber(uint256 _fee) external {
        require(msg.sender == _owner, "Only owner can set fee random number");
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
    function setGenInterval(uint256 _genInterval) external {
        require(msg.sender == _owner, "Only owner can set fee random number");
        genInterval = _genInterval;
    }
}