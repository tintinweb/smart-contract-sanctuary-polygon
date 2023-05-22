// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./VRFConsumerBase.sol";
import "./AccessControl.sol";

contract RandomNumberOnlyTime is VRFConsumerBase, AccessControl {
    bytes32 internal keyHash; // Chainlink VRF key hash
    uint256 internal fee; // Chainlink VRF fee
    bytes32 public requestId; // Chainlink VRF request ID
    uint256 private lastTimeRandom; // Timestamp of the last generated random number
    uint256 private genInterval; // Time interval (in seconds) between each random number generation
    uint256 private randomNumber; // random number

    bytes32 public constant RANDOM_NUMBER_FLAG =
        keccak256("RANDOM_NUMBER_FLAG");
    bytes32 public constant UPDATER_FEE_RANDOM =
        keccak256("UPDATER_FEE_RANDOM");
    bytes32 public constant CLAIM_TOKEN_FLAG = keccak256("CLAIM_TOKEN_FLAG");

    /**
     * Constructor inherits VRFConsumerBase
     *
     * Network: Polygon (Matic) Mumbai Testnet
     * Chainlink VRF Coordinator address: 0x3d2341ADb2D31f1c5530cDC622016af293177AE0
     * LINK token address:                0xb0897686c545045aFc77CF20eC7A532E3120E0F1
     * Key Hash: 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4
     */
    constructor()
        VRFConsumerBase(
            0x3d2341ADb2D31f1c5530cDC622016af293177AE0, // VRF Coordinator
            0xb0897686c545045aFc77CF20eC7A532E3120E0F1 // LINK Token
        )
    {
        keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da; // Key hash for VRF job on Polygon mainnet
        fee = 0.0001 ether; // 0.0001 LINK
        lastTimeRandom = block.timestamp;
        genInterval = 1;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(RANDOM_NUMBER_FLAG, msg.sender);
        _grantRole(UPDATER_FEE_RANDOM, msg.sender);
        _grantRole(CLAIM_TOKEN_FLAG, msg.sender);
    }

    /**
     * Requests randomness
     */
    function getRandomNumber()
        public
        onlyRole(RANDOM_NUMBER_FLAG)
        returns (bytes32)
    {
        require(
            LINK.balanceOf(address(this)) > fee,
            "Not enough LINK - fill contract with faucet"
        );
        if (block.timestamp - lastTimeRandom > genInterval) {
            requestId = requestRandomness(keyHash, fee);
            lastTimeRandom = block.timestamp;
            return requestId;
        }
    }

    /**
     * Requests get random number
     */
    function randomResult()
        public
        view
        onlyRole(RANDOM_NUMBER_FLAG)
        returns (uint256)
    {
        return randomNumber;
    }

    /**
     * Create random number from chainlink server
     */
    function setFeeRandomNumber(
        uint256 _fee
    ) external onlyRole(UPDATER_FEE_RANDOM) {
        require(_fee > 0, "Fee random number is invalid");
        fee = _fee;
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(
        bytes32 _requestId,
        uint256 _randomResult
    ) internal override {
        require(requestId == _requestId, "Wrong requestId");
        randomNumber = _randomResult;
    }

    /**
     * @dev Sets the generation interval for creating random numbers.
     * @param _genInterval The new generation interval to set.
     * Requirements:
     * The caller must be the contract owner.
     */
    function setGenInterval(
        uint256 _genInterval
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        genInterval = _genInterval;
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