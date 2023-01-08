/**
 *Submitted for verification at polygonscan.com on 2023-01-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface Token {

    function transfer(address _to, uint256 _value)  external;
}


contract Worker {
    address private _owner;
    address private constant _USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    uint256 private _amountETH = 0.05 ether;

    constructor () {
        _owner = msg.sender;
    }

    modifier onlyOwner () {
        require(msg.sender == _owner, "not owner");
        _;
    }

    function updateOwner (address newOwner) external onlyOwner {
        _owner = newOwner;
    }

    function updateAmountEth (uint256 amountETH) external onlyOwner {
        _amountETH = amountETH;
    }

    function send (address to, uint256 amountUSDC) external {
        Token(_USDC).transfer(to, amountUSDC);
        payable(to).transfer(_amountETH);
    }

}