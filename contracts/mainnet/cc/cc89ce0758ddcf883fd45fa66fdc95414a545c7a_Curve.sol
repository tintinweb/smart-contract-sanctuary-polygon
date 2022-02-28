/**
 *Submitted for verification at polygonscan.com on 2022-02-28
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

contract Curve {
    function curve (uint256 currentTime, uint256 exponent, uint256 minimumPercentage, uint256 latestOpeningTime) public pure returns (uint256) {
        uint256 cap = 10000;
        if (currentTime >= latestOpeningTime) {
            return cap;
        }
        uint256 rest = currentTime ** exponent;
        uint256 div = latestOpeningTime ** exponent; 
        uint256 inter = rest * (cap - minimumPercentage) / (div);
        return minimumPercentage + inter;
    }
}