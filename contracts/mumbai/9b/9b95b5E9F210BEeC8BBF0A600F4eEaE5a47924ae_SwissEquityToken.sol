/**
 *Submitted for verification at polygonscan.com on 2023-06-28
*/

// *******************************************
// SPDX-License-Identifier: MIT
// Swiss Equity Token 1.5
// Author: Smart Contracts Lab, UZH
// Created: June 28, 2023
// *******************************************

pragma solidity ^0.8.19;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address to, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address from, address to, uint amount) external returns (bool);
}

contract SwissEquityToken is IERC20 {

    struct Investor {
        uint balance;
        uint shares;
        uint fractions;
        bool known;
        uint ID;
        bytes32 hash;
        bool recoverable;
    }

    mapping(address => Investor) private _registry;
    mapping(address => mapping(address => uint)) private _allowance;
    string private _name; 
    string private _symbol;
    uint8 private immutable _decimals;
    uint private _totalSupply;
    
    uint public _totalShares;
    address public _issuer;
    address public _deputy;
    address[] public _investors;
    uint public immutable _ONE_SHARE;
    uint public _treasuryShares; // owned by issuer but inaccessible
    bool public _paused;

    event Registered(address indexed account, bytes32 hash, bool recoverable);
    event Recovered(address indexed oldAccount, address indexed newAccount);

    modifier onlyIssuer() {
        require((msg.sender == _issuer) || (msg.sender == _deputy), "only issuer");
        _;
    }

// ************************* Launch Module ************************* 
    
    constructor() {
        _name = "Swiss Equity Token";
        _symbol = "SET";
        _decimals = 18;
        _ONE_SHARE = 10 ** _decimals;
        _totalShares = 10000000;
        _totalSupply = _totalShares * _ONE_SHARE;
        _issuer = msg.sender;
        _deputy = 0x41EaC9c0E5EA02ae690f37CdA6fB1cdDECD752b1; 
        _registry[_issuer].balance = _totalSupply;
        _registry[_issuer].shares = _totalShares;
        _registry[_issuer].known = true;
        _investors.push(_issuer);
    }

// ************************* Shareholder Module ************************* 

    function name() public virtual view returns (string memory) {return _name;}
    
    function symbol() public virtual view returns (string memory) {return _symbol;}
    
    function decimals() public virtual view returns (uint8) {return _decimals;}
    
    function totalSupply() public virtual view returns (uint)  {return _totalSupply;}
    
    function balanceOf(address owner) public virtual view returns (uint) {return _registry[owner].balance;} 
    
    function transfer(address to, uint value) public virtual returns (bool) {
        settleTransfer(msg.sender, to, value);
        return(true);
    }

    function allowance(address owner, address spender) public virtual view returns (uint) {return _allowance[owner][spender];}  
    
    function approve(address spender, uint value) public virtual returns (bool) {
        _allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
       function transferFrom(address from, address to, uint value) public virtual returns (bool) {
        require(value <= _allowance[from][msg.sender],"allowance too low");
        settleTransfer(from, to, value);
        _allowance[from][msg.sender] -= value;
        return true;
        }

    function sharesOf(address owner) public view returns (uint) {return _registry[owner].shares;}    
    
    function fractionsOf(address owner) public view returns (uint) {return _registry[owner].fractions;}
    
    function transferShares(address to, uint shares) public returns (bool) {
        settleTransfer(msg.sender, to, shares * _ONE_SHARE);
        return(true);
    }
    function register(bytes32 hash, bool recoverable) public {
        require(_registry[msg.sender].known);
        _registry[msg.sender].hash = hash;
        _registry[msg.sender].recoverable = recoverable;
        emit Registered(msg.sender, hash, recoverable);
    }

// ************************* Settlement Module *************************  

    function settleTransfer(address from, address to, uint value) internal {
        require(_paused == false, "paused");
        require(value <= _registry[from].balance, "balance too low");
        
        uint _shares = value / _ONE_SHARE; 
        uint _fractions = value % _ONE_SHARE; 
        uint _checkSum = _treasuryShares + _registry[from].shares + _registry[to].shares;
        
        _registry[from].balance -= value; // debit
        _registry[to].balance += value; // credit

        if (_fractions > _registry[from].fractions) { // insufficient fractions to settle debit: one share is swapped into fractions
            _registry[from].shares -= 1;
            _treasuryShares += 1;
            _registry[from].fractions += _ONE_SHARE;
        }

        _registry[from].shares -= _shares;
        _registry[to].shares += _shares;
        _registry[from].fractions -= _fractions;
        _registry[to].fractions += _fractions;
            
        if (_registry[to].fractions >= _ONE_SHARE) { // too many fractions resulting from credit: swap is reversed
            _registry[to].shares += 1;
            _treasuryShares -= 1;
            _registry[to].fractions -= _ONE_SHARE;
        } 

        assert(_registry[from].shares == _registry[from].balance / _ONE_SHARE);
        assert(_registry[from].fractions == _registry[from].balance % _ONE_SHARE);
        assert(_registry[to].shares == _registry[to].balance / _ONE_SHARE);
        assert(_registry[to].fractions == _registry[to].balance % _ONE_SHARE);
        assert(_checkSum == _treasuryShares + _registry[from].shares + _registry[to].shares);

        if (_registry[to].known == false) {
            _investors.push(to);
            _registry[to].ID = _investors.length;
            _registry[to].known = true;
        } 
        
        emit Transfer(from, to, value);
    }

// ************************* Issuer Module ************************* 

    function numberOfInvestors() public view returns(uint) {return _investors.length;}

    function pause(bool paused) public onlyIssuer { _paused = paused;}

    function recover(address oldAccount, address newAccount) public onlyIssuer {
        require(_registry[oldAccount].recoverable || oldAccount == _issuer, "Not recoverable");
        require(_registry[newAccount].known == false, "In use");
        
        _registry[newAccount] = _registry[oldAccount];
        _investors[_registry[newAccount].ID] = newAccount;
        if (oldAccount == _issuer) {_issuer = newAccount;}
        
        delete _registry[oldAccount];
        emit Recovered(oldAccount, newAccount);
    }

    function raise(uint shares) public onlyIssuer {
        uint _value = shares * _ONE_SHARE;
        _registry[_issuer].balance += _value;
        _registry[_issuer].shares += shares; 
        _totalSupply += _value;
        _totalShares += shares;
        emit Transfer(address(0), _issuer, _value);
    }

    function changeDeputy(address deputy) public onlyIssuer { _deputy = deputy; }
}