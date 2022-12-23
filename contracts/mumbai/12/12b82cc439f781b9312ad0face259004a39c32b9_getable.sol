/**
 *Submitted for verification at polygonscan.com on 2022-12-23
*/

// File: contracts/first.sol



pragma solidity ^0.8.0;
contract getable{
    uint256 a=2;
    uint256 monery=3;
    function reused(uint256 n,uint256 m) public{
        a=n;
        monery=m;
    }
    function getvalue() public view returns(uint256,uint256){
           return (a,monery);
    }
}