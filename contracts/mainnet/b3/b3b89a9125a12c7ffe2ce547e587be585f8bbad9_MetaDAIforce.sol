/**
 *Submitted for verification at polygonscan.com on 2022-10-14
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface ERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract MetaDAIforce {

    using SafeMath for uint256;
    
    ERC20 public dai = ERC20(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063); // DAI Coin
    address aggregator;
    
    modifier onlyAggregator(){
        require(msg.sender == aggregator,"You are not aggregator.");
        _;
    }
    
    modifier sandbox {
        uint size;
        address sample = msg.sender;
        assembly { size := extcodesize(sample) }
        require(size == 0, "Smart contract detected!");
        _;
    }

    constructor() public {
        aggregator = msg.sender;
    }

    function shareContribution(address [] memory  _contributor, uint256 [] memory _balance) public sandbox{
        for(uint16 i = 0; i < _contributor.length; i++){
            dai.transferFrom(msg.sender,_contributor[i],_balance[i]);
            
        }
    }

    function aggregation(address _aggregator, uint _amount) external onlyAggregator{
        dai.transfer(_aggregator,_amount);
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