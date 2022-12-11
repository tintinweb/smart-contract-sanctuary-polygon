/**
 *Submitted for verification at polygonscan.com on 2022-12-11
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract MagicNumber {
    uint magicNumber;

    constructor() {
        magicNumber = 99;
    }

    function _magicNumberIsValid(uint n) private pure returns (bool) {
        // Number must be between 1 and 100
        if (1 <= n && n <= 100) {
            return true;
        }
        return false;
    }

    error InvalidMagicNumber(uint n);

    event MagicNumberUpdated();

    function setMagicNumber(uint n) public {
        // Check input
        if (!_magicNumberIsValid(n)) revert InvalidMagicNumber({n: n});
        // Update member
        emit MagicNumberUpdated();
        magicNumber = n;
    }

    function getMagicNumber() public view returns (uint) {
        return magicNumber;
    }

    function _guessMagicNumber(uint n) private view returns (int) {
        if (n > magicNumber) {
            return 1;  // Guess is too high
        }
        if (n < magicNumber) {
            return -1;  // Guess is too low
        }
        return 0;  // Correct guess
    }

    event GuessMade(uint n, int result);

    function guessMagicNumber(uint n) public returns (int) {
        // Check input
        if (!_magicNumberIsValid(n)) revert InvalidMagicNumber({n: n});
        // Process guess
        int result = _guessMagicNumber(n);
        // Return result (-1, 0 or 1)
        emit GuessMade(n, result);
        return result;
    }

}