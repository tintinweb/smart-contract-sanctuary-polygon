// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

import "./VRFConsumerBase.sol";

contract RandomNumberOnlyTime is VRFConsumerBase {
    bytes32 internal keyHash;
    uint256 internal fee;
    address payable public _owner;
    bytes32 public requestId;
    uint256 public randomNumber;
    uint256 lastBlockNumber;
    
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
        lastBlockNumber = block.number;
    }
    
    /** 
     * Requests randomness 
     */
    function getRandomNumber() public returns (bytes32) {
        uint256 currentBlockNumber = block.number;
        if(currentBlockNumber != lastBlockNumber) {
            require(LINK.balanceOf(address(this)) > fee, "Not enough LINK - fill contract with faucet");
            requestId = requestRandomness(keyHash, fee);
            lastBlockNumber = currentBlockNumber;
            return requestId;
        }
    }

    function setFeeRandomNumber(uint256 _fee) external {
        require(msg.sender == _owner, "Only owner can set fee random number");
        require(_fee > 0, "Fee random number is invalid");
        fee = _fee;
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 _requestId, uint256 _randomNumber) internal override {
        require(requestId == _requestId, "Wrong requestId");
        randomNumber = _randomNumber;
    }
}