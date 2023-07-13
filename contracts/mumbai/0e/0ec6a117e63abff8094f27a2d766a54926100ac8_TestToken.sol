/**
 *Submitted for verification at polygonscan.com on 2023-07-12
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.2;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TestToken is IERC20 {
    string public name;
    string public symbol;
    uint8  public immutable override decimals;
    mapping (address => uint256) public override balanceOf;
    uint256 private _totalSupply;
    mapping (address => mapping (address => uint256)) public override allowance;

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _amount) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        balanceOf[msg.sender] = _amount * 10 ** _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 balance = balanceOf[account];
        require(balance >= amount, "ERC20: burn amount exceeds balance");

        balanceOf[account] = balance - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function approve(address spender, uint256 value) external override returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external override returns (bool) {
        require(to != address(0) && to != address(this));
        uint256 balance = balanceOf[msg.sender];
        require(balance >= value, "ERC20: transfer amount exceeds balance");
        balanceOf[msg.sender] = balance - value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external override returns (bool) {
        require(to != address(0) && to != address(this));
        if (from != msg.sender) {
            uint256 allowed = allowance[from][msg.sender];
            if (allowed != type(uint256).max) {
                require(allowed >= value, "ERC20: request exceeds allowance");
                uint256 reduced = allowed - value;
                allowance[from][msg.sender] = reduced;
                emit Approval(from, msg.sender, reduced);
            }
        }
        uint256 balance = balanceOf[from];
        require(balance >= value, "ERC20: transfer amount exceeds balance");
        balanceOf[from] = balance - value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
        return true;
    }
}