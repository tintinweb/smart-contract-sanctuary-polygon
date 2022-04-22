/**
 *Submitted for verification at polygonscan.com on 2022-04-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 public number;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store_number(uint256 num) public payable{
        //require(msg.value >= 0.015 ether, "To store a number you must send at least 0.015 ether");

        number = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }

    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}