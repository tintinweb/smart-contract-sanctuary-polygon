// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract MagicNumber {
    // Storage
    uint256 public constant decimals = 1e18;
    mapping(address => uint256) public magicNumber;
    uint256 magicSum;
    uint256 participantCount;

    // Events
    event NewNumberSet(uint256 indexed magicNumber, address indexed owner);
    event NewNumberReset(uint256 indexed magicNumber, address indexed owner);

    // Errors
    error ZeroNumberNotAllowed();

    /**
     *
     * @param _magicNumber : Put magicNumber with the precision of 18 decimal places eg. 22.44 should be put as: 22440000000000000000
     */
    function setNumber(uint256 _magicNumber) public {
        if (_magicNumber == 0) revert ZeroNumberNotAllowed();

        uint256 existingMagicNumber = magicNumber[msg.sender];
        if (existingMagicNumber == 0) {
            // gas-golfing by avoiding overflow-check
            unchecked {
                participantCount += 1;
            }
            emit NewNumberSet(_magicNumber, msg.sender);
        } else {
            magicSum -= existingMagicNumber;
            emit NewNumberReset(_magicNumber, msg.sender);
        }

        magicNumber[msg.sender] = _magicNumber;
        magicSum += _magicNumber;
    }

    /**
     *
     * @return _magicSum The sum of all magicNumbers put till now
     * @return _participantCount The number of participants involved in the contribution of the MagicSum
     */
    function getMagicStats()
        public
        view
        returns (uint256 _magicSum, uint256 _participantCount)
    {
        _magicSum = magicSum;
        _participantCount = participantCount;
    }
}