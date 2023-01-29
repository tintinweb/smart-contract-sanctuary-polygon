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

    function getBalance(IERC20 token) public view returns(uint256) {
        return token.balanceOf(address(this));
    }

    function getShareholders() public view returns(address[] memory) {
        return shareholders;
    }

    function payout(IERC20 token) external {
        uint totalBalance = token.balanceOf(address(this));
        token.transfer(owner, totalBalance);
    }
}