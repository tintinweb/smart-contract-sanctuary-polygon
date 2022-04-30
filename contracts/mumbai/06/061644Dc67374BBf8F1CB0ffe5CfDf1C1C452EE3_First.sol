/**
 *Submitted for verification at polygonscan.com on 2022-04-29
*/

// SPDX-License-Identifier:Muaz Hafeez
pragma solidity 0.8.7;

contract First{

    function send_Ether() public payable {
    }
    function get_Balance() public view returns(uint) {
        return address(this).balance;
    }
    function Withdraw_All(address payable _to) public{
        _to.transfer(address(this).balance);
    }
}