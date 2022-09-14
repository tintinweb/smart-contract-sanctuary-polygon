/**
 *Submitted for verification at polygonscan.com on 2022-09-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }

    function increment() external returns (uint256) {
        number = number + 1;
        return number;
    }

    function decrement() external returns (uint256) {
        number = number - 1;
        return number;
    }

    function addToNumber(uint256 a, uint256 b) external returns (uint256) {
        number = number + a + b;
        return number;
    }
}