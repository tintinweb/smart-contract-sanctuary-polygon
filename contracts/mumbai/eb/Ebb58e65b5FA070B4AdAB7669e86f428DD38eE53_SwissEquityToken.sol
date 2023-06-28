/**
 *Submitted for verification at polygonscan.com on 2023-06-27
*/

// SPDX-License-Identifier: MIT
// Swiss Equity Token 1.0
// Author: Christian Ewerhart, University of Zurich

pragma solidity ^0.8.0;

contract SwissEquityToken {

    struct Investor {
        uint balance;
        uint shares;
        uint fractions;
        bool known;
        uint ID;
        bytes32 hash;
        bool recoverable;
    }

    mapping(address => Investor) public registry;
    mapping(address => mapping(address => uint)) public allowance;

    string public name; 
    string public symbol;
    uint8 public immutable decimals;
    uint public totalSupply;
    uint public totalShares;

    address public issuer;
    address public deputy;
    address[] public investors;
    uint public immutable ONE_SHARE;
    uint public treasuryShares; // owned by issuer but inaccessible
    bool public paused;

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
    event Registered(address indexed account, bytes32 hash, bool recoverable);
    event Recovered(address indexed oldAccount, address indexed newAccount);

    modifier onlyIssuer() {
        require((msg.sender == issuer) || (msg.sender == deputy), "not eligible");
        _;
    }

// ************************* Launch Module ************************* 
    
    constructor() {
        name = "CE Token 1.0";
        symbol = "CE 1.0";
        decimals = 18;
        ONE_SHARE = 10 ** decimals;
        totalShares = 10000000;
        totalSupply = totalShares * ONE_SHARE;
        issuer = msg.sender;
        deputy = 0x41EaC9c0E5EA02ae690f37CdA6fB1cdDECD752b1;
        registry[issuer].balance = totalSupply;
        registry[issuer].shares = totalShares;
        registry[issuer].known = true;
        investors.push(issuer);
    }

// ************************* Shareholder Module *************************   

    function balanceOf(address _account) public view returns (uint256) {return registry[_account].balance;}
    
    function sharesOf(address _account) public view returns (uint) {return registry[_account].shares;}
    
    function fractionsOf(address _account) public view virtual returns (uint) {return registry[_account].fractions;}

    function transfer(address _to, uint _amount) public returns (bool) {
        settleTransfer(msg.sender, _to, _amount);
        return true;
    }

    function transferShares(address _to, uint _shares) public {
        settleTransfer(msg.sender, _to, _shares * ONE_SHARE);
    }

    function transferFrom(address _from, address _to, uint _amount) public returns (bool) {
        require(_amount <= allowance[_from][msg.sender], "exceeds allowance");
        allowance[_from][msg.sender] -= _amount;
        settleTransfer(_from, _to, _amount);
        return true;
    }

    function approve(address _spender, uint _amount) public returns (bool) {
        allowance[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    function register(bytes32 _hash, bool _recoverable) public {
        registry[msg.sender].hash = _hash;
        registry[msg.sender].recoverable = _recoverable;
        emit Registered(msg.sender, _hash, _recoverable);
    }

// ************************* Settlement Module *************************  

    function settleTransfer(address _from, address _to, uint _amount) internal virtual {
        require(paused == false, "paused");
        require(_amount <= registry[_from].balance, "exceeds balance");
        registry[_from].balance -= _amount; // debit
        registry[_to].balance += _amount; // credit

        uint _shares = _amount / ONE_SHARE; 
        uint _fractions = _amount % ONE_SHARE; 
        uint checkSum = treasuryShares + registry[_from].shares + registry[_to].shares;
        
        if (_fractions > registry[_from].fractions) { // insufficient fractions to settle debit: one share is swapped into fractions
            registry[_from].shares -= 1;
            treasuryShares += 1;
            registry[_from].fractions += ONE_SHARE;
        }

        registry[_from].shares -= _shares;
        registry[_to].shares += _shares;
        registry[_from].fractions -= _fractions;
        registry[_from].fractions += _fractions;
        
        if (_fractions + registry[_to].fractions >= ONE_SHARE) { // too many fractions resulting from credit: swap is reversed
            registry[_to].shares += 1;
            treasuryShares -= 1;
            registry[_from].fractions -= ONE_SHARE;
        }
               
        assert(registry[_from].shares == registry[_from].balance / ONE_SHARE);
        assert(registry[_from].fractions == registry[_from].balance % ONE_SHARE);
        assert(registry[_to].shares == registry[_to].balance / ONE_SHARE);
        assert(registry[_to].fractions == registry[_to].balance % ONE_SHARE);
        assert(checkSum == treasuryShares + registry[_from].shares + registry[_to].shares);
        
        if (registry[_to].known == false) {
            investors.push(_to);
            registry[_to].ID = investors.length;
            registry[_to].known = true;
        } 

        emit Transfer(_from, _to, _amount);
    }

// ************************* Issuer Module ************************* 

    function numberOfInvestors() public view returns(uint) {return investors.length;}

    function pause(bool _paused) public onlyIssuer {
        paused = _paused;
    }

    function recover(address _oldAccount, address _newAccount) public onlyIssuer {
        require(registry[_oldAccount].recoverable || _oldAccount == issuer, "Not recoverable");
        require(registry[_newAccount].known == false, "In use");
        registry[_newAccount] = registry[_oldAccount];
        investors[registry[_newAccount].ID] = _newAccount;
        if (_oldAccount == issuer) {issuer = _newAccount;}
        delete registry[_oldAccount];
        emit Recovered(_oldAccount, _newAccount);
    }

    function raise(uint _shares) public onlyIssuer {
        uint _amount = _shares * ONE_SHARE;
        registry[issuer].balance += _amount;
        registry[issuer].shares += _shares; 
        totalSupply += _amount;
        totalShares += _shares;
        emit Transfer(address(0), issuer, _amount);
    }

    function changeDeputy(address _deputy) public onlyIssuer {
        deputy = _deputy;
    }
}