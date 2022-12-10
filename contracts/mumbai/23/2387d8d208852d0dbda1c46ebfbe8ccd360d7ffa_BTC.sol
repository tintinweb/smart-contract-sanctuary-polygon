/**
 *Submitted for verification at polygonscan.com on 2022-12-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract BTC {
    string public name     = "Tether USD";
    string public symbol   = "USDT";
    uint8  public decimals = 18;
    uint256 public totalSupply = 0;
    uint256 public maxMint = 50000000000000000000000;
    uint256 public balanceBeforeMintShouldBeLessThan = 1000000000000000000000;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;

    constructor() {
        balanceOf[msg.sender] += maxMint;
        totalSupply += maxMint;
    }

    function mint(address to, uint256 amount) public {
        require(amount <= maxMint, "Don't be too greedy. Take less amount. See the maxMint amount.");
        require(balanceOf[to] < balanceBeforeMintShouldBeLessThan, "Don't be too greedy. You have enough balance.");
        balanceOf[to] += amount;
        totalSupply += amount;
    }

    function approve(address to, uint256 amount) public returns (bool) {
        allowance[msg.sender][to] = amount;
        emit Approval(msg.sender, to, amount);
        return true;
    }

    function transfer(address to, uint amount) public returns (bool) {
        return transferFrom(msg.sender, to, amount);
    }

    function transferFrom(address src, address to, uint256 amount)
        public
        returns (bool)
    {
        require(balanceOf[src] >= amount);

        if (src != msg.sender) {
            require(allowance[src][msg.sender] >= amount);
            allowance[src][msg.sender] -= amount;
        }

        balanceOf[src] -= amount;
        balanceOf[to] += amount;

        emit Transfer(src, to, amount);

        return true;
    }
}