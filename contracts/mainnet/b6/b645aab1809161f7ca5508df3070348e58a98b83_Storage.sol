/**
 *Submitted for verification at polygonscan.com on 2022-10-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Storage {

    uint256 number;

    /**
     * @dev Store value in variable
     * @param _num value to store
     */
    function store(uint256 _num) public {
        number = _num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}