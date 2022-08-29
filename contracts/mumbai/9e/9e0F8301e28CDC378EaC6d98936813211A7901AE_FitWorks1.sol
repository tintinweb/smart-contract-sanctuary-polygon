/**
 *Submitted for verification at polygonscan.com on 2022-08-29
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract FitWorks1 {

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public _owner = msg.sender;

    string private _name;
    string private _symbol;

    uint256 _decimals;
    uint256 private _totalSupply;

    event Transfer_(address indexed from, address indexed to, uint256 value);

    event Approval_(address indexed owner, address indexed spender, uint256 value);

    modifier onlyOwner {
        require(msg.sender == _owner);
        _;

    }


    constructor() {
        _name = "FitWorks1";
        _symbol = "FTW1";
        _decimals = 18;
        _totalSupply = 10000000000 * 10 ** uint256(_decimals);
        _balances[msg.sender] = _totalSupply;
    }


    function name() public view virtual returns(string memory) {
        return _name;
    }

    function symbol() public view virtual returns(string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns(uint256) {
        return 18;
    }

    function totalSupply() public view virtual returns(uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual returns(uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual returns(bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual onlyOwner returns(uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual onlyOwner returns(bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function bulkTransfer(address[] memory to, uint[] memory value) public virtual onlyOwner returns(bool) {
        uint arrayLength = value.length;
        require(arrayLength == to.length, "Invalid parameters");
        uint balance = _balances[msg.sender];
        for (uint i = 0; i < arrayLength; i++) {
            balance -= value[i];
            _balances[to[i]] += value[i];
            emit Transfer_(msg.sender, to[i], value[i]);
        }
        _balances[msg.sender] = balance;
        return true;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _owner = newOwner;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual onlyOwner returns(bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual onlyOwner returns(bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function _transfer(address from, address to, uint256 amount) public virtual onlyOwner returns(bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(from, to, amount);
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;
        emit Transfer_(from, to, amount);
        _afterTokenTransfer(from, to, amount);
        return true;
    }

    function _mint(address account, uint256 amount) external onlyOwner virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer_(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) external onlyOwner virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit Transfer_(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval_(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _msgSender() internal view virtual returns(address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns(bytes calldata) {
        return msg.data;
    }


}