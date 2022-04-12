// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IERC20.sol";
import "./Ownable.sol";

contract ERC20 is IERC20, Ownable {
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    constructor(string memory _name, string memory _symbol, uint _totalSupply) {
        name = _name;
        symbol = _symbol;
        decimals = 18;
        mint(_totalSupply * 1 ether);
    }

    function mint(uint amount) public onlyOwner {
        totalSupply += amount;
        balanceOf[msg.sender] += amount;     
        emit Transfer(address(0), msg.sender, amount);
    }

    function burn(uint amount) external onlyOwner {
        totalSupply -= amount;
        balanceOf[msg.sender] -= amount;    
        emit Transfer(msg.sender, address(0), amount);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) external returns (bool) {
        uint256 currentAllowance = allowance[sender][recipient];    
        require(currentAllowance >= amount, "ERC20: insufficient allowance");   
        _approve(sender, recipient, currentAllowance - amount);
        _transfer(sender, recipient, amount);
        return true;
    }

    function _transfer(address from, address recipient, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(balanceOf[from] >= amount, "ERC20: transfer amount exceeds balance");

        balanceOf[from] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(from, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}