/**
 *Submitted for verification at polygonscan.com on 2022-08-21
*/

pragma solidity ^0.8.7;

contract auction  {
    mapping(address => uint) public bidders;

    function make_bid() public payable{
        require(msg.value > 0);
        bidders[msg.sender] += msg.value;
    }


    function return_money(address to) public payable{
        payable(to).transfer(bidders[to]);
        bidders[to] = 0;
    }

}