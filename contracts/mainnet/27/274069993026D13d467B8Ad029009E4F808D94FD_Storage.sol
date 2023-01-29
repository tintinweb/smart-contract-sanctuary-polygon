/**
 *Submitted for verification at polygonscan.com on 2023-01-29
*/

// SPDX-License-Identifier: None
pragma solidity ^0.8.14;

// @openzepplin/contracts/token/ERC20/IERC20
// License: MIT
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract Storage {

    address private owner;
    address[] public shareholders;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function setShareholders(address[] memory _shareholders) onlyOwner public {
        shareholders = _shareholders;
    }

    function payout(IERC20 token) external returns(uint256) {
        uint TokenBalance = token.balanceOf(address(this));
        uint transaction_fee = ( TokenBalance / 100000000 ) * 1000000;
        token.transfer(owner, transaction_fee);
        
        uint postFeeBalance = TokenBalance - transaction_fee;
        for(uint i = 0; i < shareholders.length; i++) {
            uint amount = postFeeBalance / shareholders.length;
            token.transfer(shareholders[i], amount);
        }
    }

    // function payout(IERC20 token) external {
    //     uint totalBalance = token.balanceOf(address(this));
    //     for(uint i = 0; i < shareholders.length; i++) {
    //         uint bal = totalBalance / shareholders.length;
    //         token.transfer(shareholders[i], bal);
    //     }
    // }
}