/**
 *Submitted for verification at polygonscan.com on 2023-04-24
*/

//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

interface IBEP20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract MyToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;


    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    uint256 public taxRate = 3;
    address public taxRecipient;

    IBEP20 public BUSD;

    constructor(
        string memory _name,
        string memory _symbol
    ) {
        name = _name;
        symbol = _symbol;
        decimals = 18;
        totalSupply = 60000000 * 10 ** uint256(decimals);
        BUSD = IBEP20(0x8BBF3E1a4AD207325dFaDDc58AF1e08F60d14A5E);
        taxRecipient = 0x990CAA2AF4233934f2E42dC4DF789e86fceCE672;
        balanceOf[msg.sender] = totalSupply;
    }

    function buyToken(uint256 busdAmount) external {
        if (totalSupply == 0) {
            // If total supply is 0, initialize it and distribute tokens evenly
            uint256 ownerAmount = busdAmount / 2;
            uint256 buyerAmount = busdAmount - ownerAmount;
            balanceOf[msg.sender] += buyerAmount;
            balanceOf[owner] += ownerAmount;
            totalSupply += busdAmount;
        } 
        uint256 taxAmount = busdAmount * taxRate / 100;
        uint256 tokenAmount = (busdAmount - taxAmount) * 10 ** uint256(decimals) / tokenPrice();

        BUSD.transferFrom(msg.sender, address(this), busdAmount);
        _transfer(address(this), msg.sender, tokenAmount);
        _transfer(address(this), taxRecipient, taxAmount);
    }

    function sellToken(uint256 tokenAmount) external {
        uint256 taxAmount = tokenAmount * taxRate / 100;
        uint256 busdAmount = (tokenAmount - taxAmount) * tokenPrice() / 10 ** uint256(decimals);

        _transfer(msg.sender, address(this), tokenAmount);
        _transfer(address(this), taxRecipient, taxAmount);
        BUSD.transfer(msg.sender, busdAmount);
    }

    function transfer(address recipient, uint256 tokenAmount) external returns (bool) {
        uint256 taxAmount = tokenAmount * taxRate / 100;
        _transfer(msg.sender, recipient, tokenAmount - taxAmount);
        _transfer(msg.sender, taxRecipient, taxAmount);
        return true;
    }

    function tokenPrice() public view returns (uint256) {
        return totalSupply == 0 ? 1 ether : BUSD.balanceOf(address(this)) * 10 ** uint256(decimals) / totalSupply;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(balanceOf[sender] >= amount, "Insufficient balance");

        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
}