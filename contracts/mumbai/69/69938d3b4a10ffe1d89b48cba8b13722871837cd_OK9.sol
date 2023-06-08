/**
 *Submitted for verification at polygonscan.com on 2023-06-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title OK9 Token
 * @dev OK9 Dev
 */
contract OK9 {
    string public constant name = "OK9";
    string public constant symbol = "OK9";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    address public taxAddress;
    uint256 public taxAmount;

    address private contractAddress = 0x2953399124F0cBB46d2CbACD8A89cF0599974963;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _lastClaimTime;

    constructor() {
        totalSupply = 999 * 10**12 * 10**uint256(decimals);
        uint256 contractBalance = totalSupply / 2;
        _balances[msg.sender] = contractBalance;
        _balances[contractAddress] = contractBalance;
        emit Transfer(address(0), msg.sender, contractBalance);
        emit Transfer(address(0), contractAddress, contractBalance);

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

    function burn(uint256 amount) public returns (bool) {
        require(amount <= _balances[msg.sender], "Insufficient balance");
        _balances[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }

    function claimReward() public returns (bool) {
        require(msg.sender != address(0), "Invalid sender address");

        if (msg.sender == contractAddress) {
            revert("Contract address cannot claim rewards");
        }

        if (_balances[msg.sender] == 0) {
            revert("No tokens to claim rewards");
        }

        if (msg.sender != tx.origin || !isContract(contractAddress)) {
            revert("Claiming address must be a wallet with the contract");
        }

        uint256 lastClaimTime = _lastClaimTime[msg.sender];
        uint256 elapsedTime = block.timestamp - lastClaimTime;

        if (lastClaimTime == 0) {
            // First claim
            require(elapsedTime >= 5154000, "Minimum holding time not reached");
            _mint(msg.sender, 1000000000 * 10**uint256(decimals));
        } else {
            // Subsequent claim
            require(elapsedTime >= 5154000, "Minimum holding time not reached");
            _mint(msg.sender, 500000000 * 10**uint256(decimals));
        }

        _lastClaimTime[msg.sender] = block.timestamp;
        return true;
    }

    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function _mint(address account, uint256 amount) private {
        totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}