/**
 *Submitted for verification at polygonscan.com on 2022-04-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Test {

    uint public value;
    constructor() {
        value = 0;
    }

    function setValue(uint _value) external {
        value = _value;
    }
    function getValue() external view returns (uint) {
        return value;
    }
}