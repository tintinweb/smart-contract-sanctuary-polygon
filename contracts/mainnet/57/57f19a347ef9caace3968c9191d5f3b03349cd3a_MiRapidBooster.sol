/**
 *Submitted for verification at polygonscan.com on 2023-03-02
*/

pragma solidity >=0.4.23 <0.6.0;
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

contract MiRapidBooster {
   
    IERC20 public tokenDAI;
    address private creation;
    event booster(address indexed user,uint256 value);
    event withdraw(address indexed user,uint256 value);
    constructor(address _token) public {     
        creation=msg.sender;   
        tokenDAI = IERC20(_token);
    }
    
    function BuyBooster(uint256 _amount) external {
        tokenDAI.transferFrom(msg.sender, address(this),_amount);
        require(_amount>=15e6, "Amount should be 15 usdt!");
        emit booster(msg.sender,_amount);
    }   
    
    function IncomeWithdraw(address _user,uint256 _amount) external
    {
        require(msg.sender==creation,"Only owner");
        tokenDAI.transfer(_user,_amount); 
        emit withdraw(_user,_amount);
    }
    
}