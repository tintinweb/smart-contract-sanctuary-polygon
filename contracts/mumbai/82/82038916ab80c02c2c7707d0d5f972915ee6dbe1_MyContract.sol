/**
 *Submitted for verification at polygonscan.com on 2022-06-11
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

interface IVRFUtils {
    function fastVerify(
        uint256[4] memory proof,
        bytes memory message,
        uint256[2] memory uPoint,
        uint256[4] memory vComponents
    ) external view returns (bool);

    function gammaToHash(uint256 _gammaX, uint256 _gammaY)
        external
        pure
        returns (bytes32);
}

interface ICoordinator {
    function requestRandomness() external returns (uint256);

    function getVrfUtilsAddr() external view returns (address);
}

abstract contract VRFConsumer {
    /* Contracts */
    IVRFUtils private _utils;
    ICoordinator private _coordinator;

    /* VRF options */
    bool private _shouldVerify;
    bool private _silent;

    constructor() {}

    /**
     * @dev Setup various VRF related settings:
     * - Coordinator Address: Kenshi VRF coordinator address
     * - Should Verify: Set if the received randomness should be verified
     * - Silent: Set if an event should be emitted on randomness delivery
     */
    function setupVRF(
        address coordinatorAddr,
        bool shouldVerify,
        bool silent
    ) internal {
        _coordinator = ICoordinator(coordinatorAddr);

        address _vrfUtilsAddr = _coordinator.getVrfUtilsAddr();
        _utils = IVRFUtils(_vrfUtilsAddr);

        _shouldVerify = shouldVerify;
        _silent = silent;
    }

    /**
     * @dev Setup VRF, short version.
     */
    function setupVRF(address coordinatorAddr) internal {
        setupVRF(coordinatorAddr, false, false);
    }

    /**
     * @dev Sets the Kenshi VRF coordinator address.
     */
    function setVRFCoordinatorAddr(address coordinatorAddr) internal {
        _coordinator = ICoordinator(coordinatorAddr);
    }

    /**
     * @dev Sets the Kenshi VRF verifier address.
     */
    function setVRFUtilsAddr(address vrfUtilsAddr) internal {
        _utils = IVRFUtils(vrfUtilsAddr);
    }

    /**
     * @dev Sets if the received random number should be verified.
     */
    function setVRFShouldVerify(bool shouldVerify) internal {
        _shouldVerify = shouldVerify;
    }

    /**
     * @dev Sets if should emit an event once the randomness is fulfilled.
     */
    function setVRFIsSilent(bool silent) internal {
        _silent = silent;
    }

    /**
     * @dev Request a random number.
     *
     * @return {requestId} Use to map received random numbers to requests.
     */
    function requestRandomness() internal returns (uint256) {
        return _coordinator.requestRandomness();
    }

    event RandomnessFulfilled(
        uint256 requestId,
        uint256 randomness,
        uint256[4] _proof,
        bytes _message
    );

    /**
     * @dev Called by the VRF Coordinator.
     */
    function onRandomnessReady(
        uint256[4] memory proof,
        bytes memory message,
        uint256[2] memory uPoint,
        uint256[4] memory vComponents,
        uint256 requestId
    ) external {
        require(
            msg.sender == address(_coordinator),
            "Consumer: Only Coordinator can fulfill"
        );

        if (_shouldVerify) {
            bool isValid = _utils.fastVerify(
                proof,
                message,
                uPoint,
                vComponents
            );
            require(isValid, "Consumer: Proof is not valid");
        }

        bytes32 beta = _utils.gammaToHash(proof[0], proof[1]);
        uint256 randomness = uint256(beta);

        if (!_silent) {
            emit RandomnessFulfilled(requestId, randomness, proof, message);
        }

        fulfillRandomness(requestId, randomness);
    }

    /**
     * @dev You need to override this function in your smart contract.
     */
    function fulfillRandomness(uint256 requestId, uint256 randomness)
        internal
        virtual;
}

contract MyContract is VRFConsumer {
    constructor() {
        setupVRF(0xB2B448eBF7b44C5d1b3Ded988525789A12bEABD9);
    }
    
    function getRandomNumber() public {
        uint256 requestId = requestRandomness();
    }
    
    event RandomnessReceived(uint256 randomness);
    
    function fulfillRandomness(uint256 requestId, uint256 randomness) internal override {
        emit RandomnessReceived(randomness);
    }
}