// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/**
 * @title Define main levels and required levels per features;
 * @author Pedrojok01
 */

library LevelLib {
    /// @notice Define level to unlock main blockchain features
    uint8 public constant BEGINNER = 0;
    uint8 public constant NEWBIE = 1;
    uint8 public constant INTERMEDIATE = 2;
    uint8 public constant UADVANCED = 3;
    uint8 public constant ULTIMATE = 4;
    uint8 public constant JUGGERNAUT = 5;
    uint8 public constant GRAN_MASTER = 6;

    /**
     * @notice Check if a feature is unlocked based on an xp amount
     * @param _xp Player's xp
     * @param _required Level required to unlock the feature (see constant above)
     * @return isUnlocked True if unlocked || False if locked
     */
    function isUnlockedPerXp(uint256 _xp, uint8 _required) external pure returns (bool isUnlocked) {
        isUnlocked = getLevelFromXp(_xp) >= _required ? true : false;
    }

    /**
     * @notice Check if a feature is unlocked based on a player level
     * @param _level Player's xp
     * @param _required Level required to unlock the feature (see constant above)
     * @return isUnlocked True if unlocked || False if locked
     */
    function isUnlockedPerLvl(uint8 _level, uint8 _required) external pure returns (bool isUnlocked) {
        isUnlocked = _level >= _required ? true : false;
    }

    /**
     * @notice Get a player level based on his cumulated xp
     * @param _xp Player's xp
     * @return level The player level based on his xp
     */
    function getLevelFromXp(uint256 _xp) public pure returns (uint8 level) {
        if (_xp < 1000) {
            level = 0;
        } else if (_xp >= 1000 && _xp < 10_000) {
            level = 1;
        } else if (_xp >= 10_000 && _xp < 100_000) {
            level = 2;
        } else if (_xp >= 100_000 && _xp < 1_000_000) {
            level = 3;
        } else if (_xp >= 1_000_000 && _xp < 10_000_000) {
            level = 4;
        } else if (_xp >= 10_000_000 && _xp < 100_000_000) {
            level = 5;
        } else if (_xp >= 100_000_000) {
            level = 6;
        }
    }
}