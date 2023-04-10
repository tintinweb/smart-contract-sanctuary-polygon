/**
 *Submitted for verification at polygonscan.com on 2023-04-09
*/

/**
 *Submitted for verification at polygonscan.com on 2022-11-11
*/

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0 <9.0;


contract PolyGonDapp {
    using SafeMath for uint256;

   
    address payable public DepositAddress;
    
    constructor(address payable devacc)  {
       
        DepositAddress = devacc;
       
    }
   
    function deposit(uint amount) public payable returns(uint){
     
        DepositAddress.transfer(amount);
       
        return 1;
    }
}


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}