/**
 *Submitted for verification at polygonscan.com on 2023-06-08
*/

//WELCOME FELLOW HARD WORKERS OF THE UNIVERSE WORKING 9 TO 5'S AND THOSE WHO ARE SO RICH YOU CAN'T FATHOM THIS IS FOR YOU.ETH
// Loading 2piecemcnugget.eth // Loading Bestbuyguy.eth // Loading Frenchfrytoshi.eth
// @DEV = Frytoshi Nakamoto 
// WELCOME TO 9TO5IVE TOKEN ALSO KNOWN AS "NINE" OR NINETOFIVE THIS IS YOUR GATEWAY OUT OF THE MATRIX 
// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract NinetoFive {
    string private constant _name = "Ninetofive";
    string private constant _symbol = "9nine";
    uint8 private constant _decimals = 18;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    address private constant _burnAddress = 0x000000000000000000000000000000000000dEaD; // Frytoshi sets the burn address
    address private _owner;
    uint256 private _maxWalletSize;
    bool private _isOwnershipRenounced;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipRenounced(address indexed previousOwner);

    constructor() {
        _owner = msg.sender;
        _totalSupply = 200_000_000_000 * 10**uint256(_decimals);
        _maxWalletSize = (_totalSupply * 3) / 100;
        _balances[msg.sender] = _totalSupply;
        uint256 burnAmount = (_totalSupply * 25) / 100;
        _balances[_owner] -= burnAmount;
        _balances[_burnAddress] += burnAmount;
        _isOwnershipRenounced = false;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only the owner can call this function");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
        _isOwnershipRenounced = true;
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
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

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: transfer amount must be greater than zero");
        require(_balances[sender] >= amount, "ERC20: insufficient balance");

        if (sender != _owner) {
            require(_balances[recipient] + amount <= _maxWalletSize, "Exceeds maximum wallet size");
        }

        _balances[sender] -= amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function burn(uint256 amount) public {
        require(_balances[msg.sender] >= amount, "ERC20: burn amount exceeds balance");
        require(amount > 0, "ERC20: burn amount must be greater than zero");

        uint256 burnAmount = (amount * 25) / 100;
        _balances[msg.sender] -= amount;
        _totalSupply -= burnAmount;
        _balances[_burnAddress] += burnAmount;

        emit Transfer(msg.sender, _burnAddress, burnAmount);
    }

    function getMaxWalletSize() public view returns (uint256) {
        return _maxWalletSize;
    }

    function isOwnershipRenounced() public view returns (bool) {
        return _isOwnershipRenounced;
    }
}