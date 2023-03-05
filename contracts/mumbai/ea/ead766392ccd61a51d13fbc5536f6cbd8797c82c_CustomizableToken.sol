/**
 *Submitted for verification at polygonscan.com on 2023-03-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract CustomizableToken {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000000;
    mapping(address => uint256) private _balances;

    constructor(string memory _name, string memory _symbol, uint256 _totalSupply) {
        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
        _balances[msg.sender] = _totalSupply;
    }

    function setTokenInfo(string memory _name, string memory _symbol) public {
        require(msg.sender == owner(), "Unauthorized");
        name = _name;
        symbol = _symbol;
    }

    function owner() public view returns (address) {
        return msg.sender;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(_balances[msg.sender] >= amount, "Insufficient balance");

        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function bulkTransfer(address[] memory recipients, uint256[] memory amounts) public {
        require(recipients.length == amounts.length, "Invalid input length");
        for (uint256 i = 0; i < recipients.length; i++) {
            require(IERC20(address(this)).transfer(recipients[i], amounts[i]), "Transfer failed");
        }
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
}