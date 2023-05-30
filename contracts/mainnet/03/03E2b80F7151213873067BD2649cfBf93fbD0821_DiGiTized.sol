// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./IToken.sol";

contract DiGiTized is IToken
{
    address private _owner;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowed;
    mapping(address => bool) private _isTaxFreeAddr;

    address private _taxAddr;
    uint8 private _tax;
    bool private _isTaxable;
    uint256 private _totalTaxCollected;

    constructor(string memory _name_, string memory _symbol_, uint8 _decimals_, uint256 _totalSupply_, address _taxAddr_, uint8 _tax_)
    {
        _owner = msg.sender;
        _isTaxFreeAddr[_owner] = true;

        _name = _name_;
        _symbol = _symbol_;
        _decimals = _decimals_;
        _totalSupply = _totalSupply_ * (10 ** _decimals);

        _taxAddr = _taxAddr_;
        _tax = _tax_;
        _isTaxable = false;

        _balance[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
        
    }

    function name() external view returns (string memory)
    {
        return _name;
    }

    function symbol() external view returns (string memory)
    {
        return _symbol;
    }

    function decimals() external view returns (uint8)
    {
        return _decimals;
    }

    function totalSupply() external view returns (uint256)
    {
        return _totalSupply;
    }

    function balanceOf(address owner) external view returns (uint256)
    {
        return _balance[owner];
    }

    function transfer(address recipient, uint256 amount) external returns (bool)
    {
        require(_balance[msg.sender] > 0, "Zero Balance!");
        require(_balance[msg.sender] >= amount, "Low Balance!");
        _balance[msg.sender] -= amount;
        if(_isTaxable && !_isTaxFreeAddr[msg.sender])
        {
            _totalTaxCollected += amount * _tax/100;
            _balance[_taxAddr] += amount * _tax/100;
            emit Transfer(msg.sender, _taxAddr, amount * _tax/100);
            _balance[recipient] += amount * (1 - _tax/100);
            emit Transfer(msg.sender, recipient, amount * (1 - _tax/100));
        }
        else
        {
            _balance[recipient] += amount;
            emit Transfer(msg.sender, recipient, amount);
        }
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256)
    {
        return _allowed[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool)
    {
        _allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function decreaseAllowance(address spender, uint256 amount) external returns (bool)
    {
        require(_allowed[msg.sender][spender] >= amount, "Allowance Can't be less than Zero!");
        _allowed[msg.sender][spender] -= amount;
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function increaseAllowance(address spender, uint256 amount) external returns (bool)
    {
        _allowed[msg.sender][spender] += amount;
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool)
    {
        require(_allowed[sender][msg.sender] > 0, "Zero Allowance!");
        require(_allowed[sender][msg.sender] >= amount, "Low Allowance!");
        require(_balance[sender] > 0, "Zero Balance!");
        require(_balance[sender] >= amount, "Low Balance!");
        _allowed[sender][msg.sender] -= amount;
        _balance[sender] -= amount;
        if(_isTaxable && !_isTaxFreeAddr[msg.sender])
        {
            _totalTaxCollected += amount * _tax/100;
            _balance[_taxAddr] += amount * _tax/100;
            emit Transfer(sender, _taxAddr, amount * _tax/100);
            _balance[recipient] += amount * (1 - _tax/100);
            emit Transfer(sender, recipient, amount * (1 - _tax/100));
        }
        else
        {
            _balance[recipient] += amount;
            emit Transfer(sender, recipient, amount);
        }
        return true;
    }

    modifier onlyOwner
    {
        require(msg.sender == _owner, "Permission Denied, You're not the Owner!");
        _;
    }

    function burn(address account, uint256 amount) onlyOwner external returns (bool)
    {
        require(_balance[account] > 0, "Zero Balance!");
        require(_balance[account] >= amount, "Low Balance!");
        _totalSupply -= amount;
        _balance[account] -= amount;
        emit Transfer(account, address(0), amount);
        return true;
    }

    function mint(address account, uint256 amount) onlyOwner external returns (bool)
    {
        _totalSupply += amount;
        _balance[account] += amount;
        emit Transfer(address(0), account, amount);
        return true;
    }

    function isTaxFreeAddr(address account) external view returns (bool)
    {
        return _isTaxFreeAddr[account];
    }

    function regTaxFreeAddr(address account) onlyOwner external returns (bool)
    {
        require(!_isTaxFreeAddr[account], "Already registered as Tax-Free Address!");
        _isTaxFreeAddr[account] = true;
        emit TaxFreeReg(account, true, block.timestamp);
        return true;
    }

    function deRegTaxFreeAddr(address account) onlyOwner external returns (bool)
    {
        require(_isTaxFreeAddr[account], "Already deregistered as Tax-Free Address!");
        _isTaxFreeAddr[account] = false;
        emit TaxFreeReg(account, false, block.timestamp);
        return true;
    }

    function isTaxable() external view returns (bool)
    {
        return _isTaxable;
    }

    function enableTaxation() onlyOwner external returns (bool)
    {
        require(!_isTaxable, "Taxation already Enabled!");
        _isTaxable = true;
        emit Taxation(true, block.timestamp);
        return true;
    }

    function disableTaxation() onlyOwner external returns (bool)
    {
        require(_isTaxable, "Taxation already Disabled!");
        _isTaxable = false;
        emit Taxation(false, block.timestamp);
        return true;
    }

    function totalTaxCollected() external view returns (uint256)
    {
        return _totalTaxCollected;
    }
}