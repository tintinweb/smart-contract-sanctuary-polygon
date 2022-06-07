// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

/**
 * @title Nomo random number generator mock
 */
contract RandGeneratorMock {
    /**
     * @notice Send random to requester contract
     * @return _random Random number
     */
    function requestRandomNumber() external pure returns (uint256 _random) {
        _random = 6468405660736672612606363894041542649540182964495095084337802469636617584972;
    }
}