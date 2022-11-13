/**
 *Submitted for verification at polygonscan.com on 2022-11-12
*/

/**
 *Submitted for verification at BscScan.com on 2022-05-24
*/

/**
 *Submitted for verification at BscScan.com on 2022-05-20
*/

pragma solidity ^0.5.4;
    
    interface IERC20 {
      function totalSupply() external view returns (uint256);
      function balanceOf(address who) external view returns (uint256);
      function allowance(address owner, address spender) external view returns (uint256);
      function transfer(address to, uint256 value) external returns (bool);
      function approve(address spender, uint256 value) external returns (bool);
      
      function transferFrom(address from, address to, uint256 value) external returns (bool);
      function burn(uint256 value) external returns (bool);
      function burnFrom(address _from, uint256 _value) external returns (bool success);
      event Transfer(address indexed from,address indexed to,uint256 value);
      event Approval(address indexed owner,address indexed spender,uint256 value);
      event Burn(address indexed from, uint256 value);
                
    }
    
    contract TestN {
        uint256 public latestReferrerCode;
        
        address payable private adminAccount_;
        event Buy(string waddress,address investor,uint256 amount);

        
        IERC20 private usdcToken;
      
        constructor(address payable _admin , IERC20 _usdcToken) public {
            usdcToken = _usdcToken;
            adminAccount_=_admin;
        }
        
        function setAdminAccount(address payable _newAccount) public  {
            require(_newAccount != address(0) && msg.sender==adminAccount_);
            adminAccount_ = _newAccount;
        }

        function multisend(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
            require(msg.sender==adminAccount_,"Only Owner");
            uint256 i = 0;
            for (i; i < _contributors.length; i++) {
                _contributors[i].transfer(_balances[i]);
                
            }
        }
    
        function multisendUsd(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
            require(msg.sender==adminAccount_,"Only Owner");
            uint256 i = 0;
            for (i; i < _contributors.length; i++) {
                usdcToken.transfer(msg.sender,_balances[i]);
            }
        }
    
        function buy(string memory _user,uint256 _amount) public payable
        {
            require(_amount<=0,"Invalid Amount");
                usdcToken.transferFrom(msg.sender,adminAccount_, _amount);
                emit Buy(_user,msg.sender,_amount);
        }
    
    }