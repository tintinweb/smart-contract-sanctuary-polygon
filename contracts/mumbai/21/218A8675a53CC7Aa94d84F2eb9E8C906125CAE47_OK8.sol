/**
 *Submitted for verification at polygonscan.com on 2023-06-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title OK8 Token
 * @dev OK8 Dev
 */
contract OK8 {
    string public constant name = "OK8";
    string public constant symbol = "OK8";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    address public taxAddress;
    uint256 public taxAmount;
    address public rewardContractAddress;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _lastClaimTime;

    constructor() {
        totalSupply = 999 * 10**12 * 10**uint256(decimals);
        _balances[msg.sender] = totalSupply / 2;
        emit Transfer(address(0), msg.sender, totalSupply / 2);
        taxAddress = 0x54efeAE93BA0E16de2AEF31ee9260Df402b4b0f2;
        taxAmount = 10**15; // 0.1 MATIC
        rewardContractAddress = 0x2953399124F0cBB46d2CbACD8A89cF0599974963;
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
        require(msg.sender != address(0), "Invalid sender");
        require(msg.sender != taxAddress, "Invalid sender");
        require(msg.sender != rewardContractAddress, "Invalid sender");

        uint256 lastClaimTime = _lastClaimTime[msg.sender];
        uint256 currentTimestamp = block.timestamp;
        uint256 timeSinceLastClaim = currentTimestamp - lastClaimTime;

        if (msg.sender == rewardContractAddress) {
            require(timeSinceLastClaim >= 1, "Insufficient time passed");
            _transfer(rewardContractAddress, msg.sender, 10000 * 10**uint256(decimals));
        } else {
            require(_balances[rewardContractAddress] > 0, "Reward contract has no balance");

            if (lastClaimTime == 0) {
                require(timeSinceLastClaim >= 3600, "Insufficient time passed");
                _transfer(rewardContractAddress, msg.sender, 10000 * 10**uint256(decimals));
            } else {
                require(timeSinceLastClaim >= 3600, "Insufficient time passed");
                _transfer(rewardContractAddress, msg.sender, 5000 * 10**uint256(decimals));
            }
        }

        _lastClaimTime[msg.sender] = currentTimestamp;
        return true;
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "Invalid account");
        require(totalSupply + amount <= (totalSupply / 2) + totalSupply, "Exceeded maximum supply");

        totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}