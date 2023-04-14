/**
 *Submitted for verification at polygonscan.com on 2023-04-14
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

/**
    @author The Calystral Team
    @title A contract interface for onchain randomness
*/
interface IRandomizer {
    /* ========== CONSTANTS ========== */
    /* ========== DATA STRUCTURES ========== */
    /* ========== EVENTS ========== */
    /**
        @dev MUST emit when any random position is assigned.
        The `userAddress` argument MUST be the user's address.
        The `position` argument MUST be the random position.
    */
    event OnRandomPositionAssigned(
        address indexed userAddress,
        uint256 position
    );

    /* ========== EXTERNAL FUNCTIONS ========== */
    /**
        @notice Assigns a user a random positon.
        @dev Assigns a user a random positon.
        Uint256 as the position space where each position is unique due to chance.
        `_randomnessNonce` is increased after the whole loop sine gasLeft() is used as well.
        Emits the `OnRandomPositionAssigned` event.
        @param userAddresses  The user's address to be assigned
    */
    function assignRandomPosition(address[] calldata userAddresses) external;
    /* ========== VIEW FUNCTIONS ========== */
    /* ========== RESTRICTED FUNCTIONS ========== */
}

/**
    @author The Calystral Team
    @title A contract for Randomization
*/
contract GeneralRandomizer is IRandomizer {
    /*==============================
    =            EVENTS            =
    ==============================*/

    /*==============================
    =          CONSTANTS           =
    ==============================*/

    /*==============================
    =            STORAGE           =
    ==============================*/
    /// @dev A counter which is used to prevent identical outcomes for multiple rolls within the same block.
    uint256 private _randomnessNonce;

    /*==============================
    =          MODIFIERS           =
    ==============================*/

    /*==============================
    =          CONSTRUCTOR         =
    ==============================*/
    /** 
        @notice Creates and initializes the contract.
        @dev Creates and initializes the contract.
    */
    constructor() {}

    /*==============================
    =      PUBLIC & EXTERNAL       =
    ==============================*/
    function assignRandomPosition(address[] calldata userAddresses) public {
        for (uint256 i = 0; i < userAddresses.length; i++) {
            emit OnRandomPositionAssigned(
                userAddresses[i],
                _getRandomUnit256()
            );
        }
        _randomnessNonce++;
    }

    /*==============================
    =          RESTRICTED          =
    ==============================*/

    /*==============================
    =          VIEW & PURE         =
    ==============================*/
    /**
        @dev Returns a semi random number between 0 and uint256-1.
        The randomness is based on:
            - the block timestamp: general random seed (unknown before transaction)
            - gasleft: prevent same outcome for multiple rolls within one tx
            - a nonce: prevent same outcome for multiple txs within the same block
        @return Semi-Random uint256
    */
    function _getRandomUnit256() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        gasleft(),
                        _randomnessNonce
                    )
                )
            );
    }

    /*==============================
    =      INTERNAL & PRIVATE      =
    ==============================*/
}