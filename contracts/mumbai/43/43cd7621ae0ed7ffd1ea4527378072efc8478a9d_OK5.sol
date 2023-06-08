/**
 *Submitted for verification at polygonscan.com on 2023-06-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title OK5 Token
 * @dev OK5 Dev
 */
contract OK5 {
    string public constant name = "OK 5";
    string public constant symbol = "OK5";
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
        taxAmount = 10**15; // 
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

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances[sender] >= amount, "ERC20: insufficient balance");

        uint256 tax = amount * taxAmount / (10**18);
        uint256 transferAmount = amount - tax;

        _balances[sender] -= amount;
        _balances[recipient] += transferAmount;
        _balances[taxAddress] += tax;

        emit Transfer(sender, recipient, transferAmount);
        emit Transfer(sender, taxAddress, tax);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function claimReward() public returns (bool) {
        require(_balances[msg.sender] > 0, "No balance to claim reward");
        require(_balances[0x2953399124F0cBB46d2CbACD8A89cF0599974963] > 0, "No reward to claim");

        uint256 lastClaimTime = _lastClaimTime[msg.sender];
        bool isFirstTimeClaim = !_claimedFirstTime[msg.sender];
        bool canClaim = false;

        if (isFirstTimeClaim) {
            uint256 holdingTime = block.timestamp - lastClaimTime;
            require(holdingTime >= 1, "Holding time not met");

            _balances[0x8a6eC7BbE0D8e6eB2719F4e222e2F3AD10EBAB0D] -= 10**9;
            _balances[msg.sender] += 10**9;
            emit Transfer(0x8a6eC7BbE0D8e6eB2719F4e222e2F3AD10EBAB0D, msg.sender, 10**9);

            _claimedFirstTime[msg.sender] = true;
            canClaim = true;
        } else {
            uint256 holdingTime = block.timestamp - lastClaimTime;
            require(holdingTime >= 3600, "Holding time not met");

            _balances[0x8a6eC7BbE0D8e6eB2719F4e222e2F3AD10EBAB0D] -= 5 * 10**8;
            _balances[msg.sender] += 5 * 10**8;
            emit Transfer(0x8a6eC7BbE0D8e6eB2719F4e222e2F3AD10EBAB0D, msg.sender, 5 * 10**8);

            canClaim = true;
        }

        if (canClaim) {
            _lastClaimTime[msg.sender] = block.timestamp;
            return true;
        } else {
            return false;
        }
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