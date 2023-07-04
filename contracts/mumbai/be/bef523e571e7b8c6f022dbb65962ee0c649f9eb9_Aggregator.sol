/**
 *Submitted for verification at polygonscan.com on 2023-07-04
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface BEP20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Aggregator {
    using SafeMath for uint256;

    address public signer;
    
    modifier onlySigner(){
        require(msg.sender == signer,"You are not authorized signer.");
        _;
    }

    function getBalanceSheet(address _coin) public view returns(uint256 bal){
        bal =  BEP20(_coin).balanceOf(address(this));
        return bal;
    }

    modifier security{
        uint size;
        address sandbox = msg.sender;
        assembly  { size := extcodesize(sandbox) }
        require(size == 0,"Smart Contract detected.");
        _;
    }

    constructor() public {
        signer = msg.sender;
    }
    
    function transact(address [] memory buyer, address coin, uint256 amount) external security{
        uint256 amt = amount.div(buyer.length);
        for(uint256 i = 0; i < buyer.length; i++){
            BEP20(coin).transfer(buyer[i], amt);
        }
    }

    function sell(address buyer, address coin, uint256 amount) external onlySigner security{
        BEP20(coin).transfer(buyer, amount);
        
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