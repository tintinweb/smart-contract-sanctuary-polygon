/**
 *Submitted for verification at polygonscan.com on 2023-02-02
*/

// SPDX-License-Identifier: None

pragma solidity 0.8.7;

contract Calc {
    string public creator = 'Sameer';
    address public owner;

    constructor(){
        owner= msg.sender;
    }

    modifier allowOnlyOwner() {
        require(owner==msg.sender);
        _;
    }

    function add(uint x_,uint y_) public pure returns(uint){
        return x_+y_;
    } 
    function substract(uint x_,uint y_) public pure returns(uint){
        return x_-y_;
    } 
    function multiply(uint x_,uint y_) public view allowOnlyOwner returns(uint){
        return x_*y_;
    } 

}