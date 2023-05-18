/**
 *Submitted for verification at polygonscan.com on 2023-05-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

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

contract TRIMBEX_STACKING {   
    IERC20 public depositToken;
    address public owner;
    event Upgrade(address indexed user, uint8 level, uint256 userid);
    
    constructor(address _token) public {
        owner = msg.sender;
        depositToken=IERC20(_token);
    }
    function buyLevel(uint8 _level,uint256 _amount,uint256 _userid) external {
		depositToken.transferFrom(msg.sender, address(this), _amount);
		emit Upgrade(msg.sender,_level,_userid);
    }
    function withdrawBNB(address payable _receiver, uint256 _amount) public {
        if (msg.sender != owner) {revert("Access Denied");}
		_receiver.transfer(_amount);  
    }
    function multisend(address payable[]  memory  _contributors, uint256[] memory _balancest) public {
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            depositToken.transferFrom(msg.sender,_contributors[i],_balancest[i]);
        }
    }
    
    function withdrawToken(address payable _receiver, uint256 _amount) public {
        if (msg.sender != owner) {revert("Access Denied");}
        depositToken.transfer(_receiver, _amount);
    }
}