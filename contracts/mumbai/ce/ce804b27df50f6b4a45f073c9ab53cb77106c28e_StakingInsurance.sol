/**
 *Submitted for verification at polygonscan.com on 2023-04-15
*/

/**
 *Submitted for verification at polygonscan.com on 2023-04-15
*/

//SPDX-License-Identifier: None
pragma solidity ^0.6.0;
interface IStaking {
    function getOrderLengthAddress(address _addr) external view returns(uint256);
    function getOrders(address _addr,uint index) view external returns(uint256 amount,uint256 deposit_time);
}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract StakingInsurance {
    IStaking public staking = IStaking(0x13afC234b9A3F6605B8b0cbb211Ed0673cA16454);
    mapping(address => uint256) public unstake;
    uint256 private constant timeStepdaily =10*60;   
    IERC20 public tokenDAI; 
    constructor(address _token) public {        
        tokenDAI = IERC20(_token);
    }
    function getOrderscheck(address _addr,uint index) view external returns(uint256,uint256)
    {
        (uint256 amount,uint256 deposit_time) = staking.getOrders(_addr,index);
        return (amount,deposit_time);
    }
    function payout() external {
        uint256 amount = stakePayoutOf();
        require(amount > 0, "StakingInsurance: ZERO_AMOUNT");    
        unstake[msg.sender] += amount;
        tokenDAI.transfer(msg.sender,amount); 
    }
    function stakePayoutOf() public view returns(uint256){
        uint256 unstakeamount=0;
        uint256 orderlength=staking.getOrderLengthAddress(msg.sender);
        for(uint8 i = 0; i < orderlength; i++){
            (uint256 amount,uint256 deposit_time) = staking.getOrders(msg.sender,i);            
            if(block.timestamp>deposit_time+timeStepdaily){ 
                unstakeamount +=amount*15/100;
            }
        }
        return (unstakeamount-unstake[msg.sender]);
    }
}