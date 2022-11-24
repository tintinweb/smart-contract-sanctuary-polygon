/**
 *Submitted for verification at polygonscan.com on 2022-11-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IERC20 {

    function balanceOf(address account) external view returns (uint256);

  
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

}

contract SideContract {
    event Transfer(address indexed from, address indexed to, uint256 value);
    IERC20 public tokenContract =
        IERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);

    function getBalance(address add) public view returns (uint256) {
        return tokenContract.balanceOf(add);
    }

    function withdraw(address destination, uint256 amount) public {
        tokenContract.transferFrom(msg.sender, destination, amount);
        emit Transfer(msg.sender, destination, amount);
    }

    function deposit(address destination, uint256 amount) public {
        tokenContract.transferFrom(msg.sender, destination, amount);
        emit Transfer(msg.sender, destination, amount);
    }
}