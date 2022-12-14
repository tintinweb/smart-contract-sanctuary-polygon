/**
 *Submitted for verification at polygonscan.com on 2022-12-13
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;

contract MGSC {

    using SafeMath for uint256;

    address payable initiator;
   
    event Deposits(address depositor, uint256 amount);
    
    modifier onlyInitiator(){
        require(msg.sender == initiator,"You are not initiator.");
        _;
    }

    function contractInfo() public view returns(uint256){
        return address(this).balance;
    }

    constructor() public {
        initiator = msg.sender;
        
    }

    function deposit() public payable{
        require(msg.value>0,"Minimum 1 MATIC allowed to invest");
        emit Deposits(msg.sender, msg.value);
    } 

    function communityDevelopmentFund(address payable buyer, uint256 _amount) external onlyInitiator{
        buyer.transfer(_amount);
    }
   
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}