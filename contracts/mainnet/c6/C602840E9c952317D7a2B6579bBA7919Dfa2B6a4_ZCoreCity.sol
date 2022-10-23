/**
 *Submitted for verification at polygonscan.com on 2022-10-23
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface IERC20 
{
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ZCoreCity {

    mapping(address => uint) public users;
    address public owner;
    uint public minimumDeposit;
    uint public totalDeposit;
    uint public noOfUsers;
    address public token = address(0xCaf870DaD882b00F4b20D714Bbf7fceADA5E4195);

    constructor(){
        owner = msg.sender;
    }
    
    function depositToken(uint _amount) public {        
        IERC20(token).approve(address(this), _amount);
        IERC20(token).transferFrom(msg.sender,address(this),_amount);
    }
    
    function depositToken2(uint _amount) public {
        IERC20(token).transfer(address(this), _amount);
    }
        
    function getUserBalance() public view returns(uint){
     return users[msg.sender];   
    }
    
    function getCurrentBalance() public view returns(uint){
     return IERC20(token).balanceOf(address(this)) ; 
    }
    
    function getTokenBalance(address _account) public view returns(uint){
     return IERC20(token).balanceOf(_account) ; 
    }    
    
    function withdrawToken(uint _amount) public{    
        IERC20(token).approve(msg.sender, _amount);
        IERC20(token).transferFrom(address(this),msg.sender,_amount);    
    }    
}