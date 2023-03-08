/**
 *Submitted for verification at polygonscan.com on 2023-03-08
*/

//SPDX-License-Identifier: None
pragma solidity ^0.6.0;

contract BlessNetworkBooster {   
    
    address private creation;
    event booster(address indexed user,uint256 value);
    event withdraw(address indexed user,uint256 value);
    constructor() public {     
        creation=msg.sender;   
    }
    
    function BuyBooster() external payable{        
        require(msg.value>=10e18, "Amount should be 10 matic!");
        emit booster(msg.sender,msg.value);
    }  
    
    function boosterWithdraw(address _user,uint256 _amount) external
    {
        require(msg.sender==creation,"Only owner");
        payable(_user).transfer(_amount); 
        emit withdraw(_user,_amount);
    }
    
}