//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract Pay {

    receive() external payable {}

    function showBalance() external view returns(uint){
        return address(this).balance;
    }
    
}