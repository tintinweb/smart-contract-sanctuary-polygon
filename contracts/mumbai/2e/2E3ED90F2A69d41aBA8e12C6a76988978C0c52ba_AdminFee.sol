/**
 *Submitted for verification at polygonscan.com on 2023-06-13
*/

/**
 *Submitted for verification at Arbiscan on 2023-03-23
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;


// interface 
interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// Contract for DevFee
contract AdminFee {
    address public admin;
    address public token; // Token address 
    
    constructor(address _token) {    
        admin = msg.sender;
        token = _token;
    }

    function setToken(address _token) public onlyAdmin() {
        token = _token;
    }
    
    // function for updating admin only can be updated by the admin
    function updateAdmin(address newAdmin) external {
        require(msg.sender == admin, 'only admin can access this contract');
        admin = newAdmin;
    }

    // function to withdraw token only by admin 
    function withdraw(uint256 amount) external onlyAdmin() {
        require(msg.sender == admin, 'only admin');
        IERC20(token).transfer(msg.sender, amount);    
    }
    // Modifier only admin
    modifier onlyAdmin() {
        require(msg.sender == admin, 'only admin');
        _;
    }
    
}