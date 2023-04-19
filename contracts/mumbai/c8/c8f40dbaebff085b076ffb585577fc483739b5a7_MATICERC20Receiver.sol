/**
 *Submitted for verification at polygonscan.com on 2023-04-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract MATICERC20Receiver {
    address private _owner;

    constructor () {
        _owner = msg.sender;
    }

    function onERC20Received(address token, address from, uint256 amount, bytes memory data) public returns(bytes4) {
        require(msg.sender == token, "Only tokens allowed");
        require(from != address(0), "Invalid sender address");
        
        IERC20(token).transferFrom(from, address(this), amount);
        
        return bytes4(keccak256("onERC20Received(address,address,uint256,bytes)"));
    }

    function withdrawToken(address token, uint256 amount) public {
        require(msg.sender == _owner, "Only owner can withdraw");
        IERC20(token).transfer(_owner, amount);
    }

    function getBalance(address token) public view returns(uint256) {
        return IERC20(token).balanceOf(address(this));
    }
}