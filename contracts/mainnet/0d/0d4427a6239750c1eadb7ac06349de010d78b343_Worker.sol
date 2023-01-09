/**
 *Submitted for verification at polygonscan.com on 2023-01-09
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

    function amountETH () external view returns (uint256) {
        return _amountETH;
    }

    function owner () external view returns (address) {
        return _owner;
    }

    function updateOwner (address newOwner) external onlyOwner {
        _owner = newOwner;
    }

    function updateAmountEth (uint256 amountETH_) external onlyOwner {
        _amountETH = amountETH_;
    }

    function send (address to, uint256 amountUSDC, bool sendETH) external onlyOwner {
        Token(_USDC).transfer(to, amountUSDC);
        if (sendETH) payable(to).transfer(_amountETH);
    }

    receive() external payable { }

}