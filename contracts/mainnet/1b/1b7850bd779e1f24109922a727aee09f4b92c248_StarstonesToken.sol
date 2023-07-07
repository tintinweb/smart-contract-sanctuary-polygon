/**
 *Submitted for verification at polygonscan.com on 2023-07-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract StarstonesToken is IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    
    string private constant _name = "Starstones";
    string private constant _symbol = "STST";
    uint256 private constant _totalSupply = 5000000 * 10 ** 18; // Total supply of 5,000,000 Starstones with 18 decimal places

    address private constant _treasuryAddress = 0xFca0B346479Fd6bb0363BD921Ba67f205E691194;
    address private constant _teamAddress = 0xa4Eb3E0170b127C17F2049D9125F54D1D586903F;
    uint256 private constant _treasuryTokens = _totalSupply * 75 / 100; // 75% of the total supply allocated to the treasury address
    uint256 private constant _teamTokens = _totalSupply * 25 / 100; // 25% of the total supply allocated to the team address
    
    address private _owner;

    constructor() {
        _balances[_treasuryAddress] = _treasuryTokens;
        _balances[_teamAddress] = _teamTokens;
        _owner = _treasuryAddress;
        
        emit Transfer(address(0), _treasuryAddress, _treasuryTokens);
        emit Transfer(address(0), _teamAddress, _teamTokens);
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function decimals() external pure override returns (uint8) {
        return 18;
    }

    function totalSupply() external pure override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }
    
    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }
}