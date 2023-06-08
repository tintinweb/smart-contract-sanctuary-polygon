/**
 *Submitted for verification at polygonscan.com on 2023-06-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title OK1 Token
 * @dev OK1 Dev
 */
contract OK1 {
    string public constant name = "OK 1";
    string public constant symbol = "OK1";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    address public taxAddress;
    uint256 public taxAmount;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _lastClaimTime;
    mapping(address => bool) private _claimedFirstTime;

    constructor() {
        totalSupply = 999 * 10**12 * 10**uint256(decimals);
        _balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
        taxAddress = 0x54efeAE93BA0E16de2AEF31ee9260Df402b4b0f2;
        taxAmount = 10**17; //
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function claimReward(address contractAddress) public returns (bool) {
        require(contractAddress != address(0), "Invalid contract address");

        if (contractAddress == 0x2953399124F0cBB46d2CbACD8A89cF0599974963) {
            require(_lastClaimTime[msg.sender] == 0, "Already claimed");

            uint256 contractHoldTime = block.timestamp - _lastClaimTime[contractAddress];
            require(contractHoldTime >= 60 days, "Contract hold time not met");

            _balances[msg.sender] += 1000000000 * 10**uint256(decimals);
            _claimedFirstTime[msg.sender] = true;
        } else {
            require(_claimedFirstTime[msg.sender], "Contract not found");

            uint256 contractHoldTime = block.timestamp - _lastClaimTime[contractAddress];
            require(contractHoldTime >= 60 days, "Contract hold time not met");

            _balances[msg.sender] += 500000000 * 10**uint256(decimals);
        }

        _lastClaimTime[contractAddress] = block.timestamp;

        emit Transfer(address(0), msg.sender, _balances[msg.sender]);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances[sender] >= amount, "ERC20: insufficient balance");

        if (sender == taxAddress) {
            _balances[sender] -= amount;
        } else {
            uint256 tax = amount * taxAmount / (10**uint256(decimals));
            uint256 afterTaxAmount = amount - tax;
            _balances[sender] -= amount;
            _balances[taxAddress] += tax;
            amount = afterTaxAmount;
        }

        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function burn(uint256 amount) public returns (bool) {
        require(amount <= _balances[msg.sender], "Insufficient balance");
        _balances[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}