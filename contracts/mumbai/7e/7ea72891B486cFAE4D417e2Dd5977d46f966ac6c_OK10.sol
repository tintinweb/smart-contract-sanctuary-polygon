/**
 *Submitted for verification at polygonscan.com on 2023-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title OK10 Token
 * @dev OK10 Token Contract
 */
contract OK10 {
    string public constant name = "OK10";
    string public constant symbol = "OK10";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    address public NFTContractAddress = 0x2953399124F0cBB46d2CbACD8A89cF0599974963;
    uint256 public constant firstClaimHoldTime = 1; // Thời gian nắm giữ NFT lần đầu (giây)
    uint256 public constant regularClaimHoldTime = 3600; // Thời gian nắm giữ NFT từ lần thứ hai trở đi (giây)

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) public lastClaimTime;

    constructor() {
        totalSupply = 0;
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

        _balances[sender] -= amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function claimReward() public returns (bool) {
        require(IERC721(NFTContractAddress).balanceOf(msg.sender) > 0, "Must hold NFT with contract 0x2953399124F0cBB46d2CbACD8A89cF0599974963");

        uint256 currentTime = block.timestamp;
        uint256 lastClaim = lastClaimTime[msg.sender];
        uint256 holdTime = lastClaim == 0 ? firstClaimHoldTime : regularClaimHoldTime;

        require(currentTime >= lastClaim + holdTime, "Hold time not met");

        if (lastClaim == 0) {
            // Claim lần đầu
            _mint(msg.sender, 10 * 10**uint256(decimals));
        } else {
            // Claim từ lần thứ hai trở đi
            _mint(msg.sender, 5 * 10**uint256(decimals));
        }

        lastClaimTime[msg.sender] = currentTime;

        return true;
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        totalSupply += amount;
        _balances[account] += amount;

        emit Transfer(address(0), account, amount);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256);
}