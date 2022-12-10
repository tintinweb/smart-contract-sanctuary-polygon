/**
 *Submitted for verification at polygonscan.com on 2022-12-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Storage {

    address[] players;

    constructor () payable {
    }

    function getBalance() public view returns (uint256) {
      return address(this).balance;
    }

    function sendEther(address payable receiver) public {
        receiver.transfer(1 ether);
    }
    
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
}