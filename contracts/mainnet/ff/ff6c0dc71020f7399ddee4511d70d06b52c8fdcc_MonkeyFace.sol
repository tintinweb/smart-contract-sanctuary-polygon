/**
 *Submitted for verification at polygonscan.com on 2023-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MonkeyFace {
    string public name = "Monkey Face";
    string public symbol = "MF";
    uint256 public totalSupply;
    uint256 public constant initialSupply = 44000000000 * 10**18;
    uint256 public constant salePercentage = 70;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Paused(bool paused);

    bool public paused;

    constructor() {
        totalSupply = initialSupply;
        balanceOf[msg.sender] = totalSupply * salePercentage / 100;
        balanceOf[address(this)] = totalSupply - balanceOf[msg.sender];
        paused = false;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    function transfer(address to, uint256 value) external notPaused returns (bool) {
        require(to != address(0), "Invalid recipient address");
        require(value > 0, "Invalid transfer amount");
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external notPaused returns (bool) {
        require(to != address(0), "Invalid recipient address");
        require(value > 0, "Invalid transfer amount");
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;

        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external notPaused returns (bool) {
        require(spender != address(0), "Invalid spender address");

        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function burn(uint256 value) external notPaused returns (bool) {
        require(value > 0, "Invalid burn amount");
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        balanceOf[msg.sender] -= value;
        totalSupply -= value;

        emit Burn(msg.sender, value);
        emit Transfer(msg.sender, address(0), value);
        return true;
    }

    function pause() external returns (bool) {
        require(!paused, "Contract is already paused");
        paused = true;
        emit Paused(true);
        return true;
    }

    function unpause() external returns (bool) {
        require(paused, "Contract is not paused");
        paused = false;
        emit Paused(false);
        return true;
    }
}