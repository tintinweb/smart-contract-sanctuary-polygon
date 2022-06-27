/**
 *Submitted for verification at polygonscan.com on 2022-06-26
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity 0.8.14;

contract Box {
    uint256 public val;

    // constructor(uint _val) {
    //     val = _val;
    // }

    function initialize(uint256 _val) external {
        val = _val;
    }
}