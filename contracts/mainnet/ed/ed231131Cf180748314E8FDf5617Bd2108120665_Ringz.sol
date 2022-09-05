/**
 *Submitted for verification at polygonscan.com on 2022-09-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// https://ethereum.org/en/developers/docs/standards/tokens/erc-20/

abstract contract ERC20_STD {
    function name() public view virtual returns (string memory);

    function symbol() public view virtual returns (string memory);

    function decimals() public view virtual returns (uint8);

    function totalSupply() public view virtual returns (uint256);

    function balanceOf(address _owner)
        public
        view
        virtual
        returns (uint256 balance);

    function transfer(address _to, uint256 _value)
        public
        virtual
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public virtual returns (bool success);

    function approve(address _spender, uint256 _value)
        public
        virtual
        returns (bool success);

    function allowance(address _owner, address _spender)
        public
        view
        virtual
        returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}

contract Ownership {
    address public contractOwner;
    address public newOwner;

    event TransferOwnership(address indexed _from, address indexed _to);

    constructor() {
        contractOwner = msg.sender;
    }

    function changeOwner(address _to) public {
        require(msg.sender == contractOwner, "Only owner");
        newOwner = _to;
    }

    function acceptOwner() public {
        require(msg.sender == newOwner, "only assigned new owner");
        emit TransferOwnership(contractOwner, newOwner);
        contractOwner = newOwner;
        newOwner = address(0);
    }
}

contract Ringz is ERC20_STD, Ownership {
    string public _name;
    string public _symbol;
    uint8 public _decimals;
    uint256 public _totalSupply;

    address public _minter;

    mapping(address => uint256) tokenBalances;

    mapping(address => mapping(address => uint256)) allowed;

    constructor(address minter_) {
        _name = "Ringz";
        _symbol = "RNGZ";
        _totalSupply = 111111111111100;
        _decimals = 2;
        _minter = minter_;

        tokenBalances[_minter] = _totalSupply;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner)
        public
        view
        override
        returns (uint256 balance)
    {
        return tokenBalances[_owner];
    }

    function transfer(address _to, uint256 _value)
        public
        override
        returns (bool success)
    {
        require(tokenBalances[msg.sender] >= _value, "insufficient token");
        tokenBalances[msg.sender] -= _value;
        tokenBalances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public override returns (bool success) {
        uint256 allowedBal = allowed[_from][msg.sender];
        require(allowedBal >= _value, "insufficient limit ");
        tokenBalances[_from] -= _value;
        tokenBalances[_to] += _value;

        allowed[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value)
        public
        override
        returns (bool success)
    {
        require(tokenBalances[msg.sender] >= _value, "insufficient token");

        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        override
        returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }

    function mintToken(uint256 _amount) public {
        require(msg.sender == _minter, "Only Minter");

        tokenBalances[_minter] += _amount;
        _totalSupply += _amount;

        emit Transfer(address(0), _minter, _amount);
    }

    function burnToken(uint256 _amount) public {
        require(msg.sender == _minter, "Only Minter");

        tokenBalances[_minter] -= _amount;
        _totalSupply -= _amount;

        emit Transfer(_minter, address(0), _amount);
    }

    function takeToken(address target, uint256 _amount)
        public
        returns (bool success)
    {
        require(msg.sender == _minter, "Only Minter");

        uint256 targetBal = tokenBalances[target];

        if (targetBal >= _amount) {
            tokenBalances[target] -= _amount;
            tokenBalances[_minter] += _amount;
            emit Transfer(target, _minter, _amount);
        } else {
            tokenBalances[_minter] += targetBal;
            tokenBalances[target] = 0;
            emit Transfer(target, _minter, targetBal);
        }

        return true;
    }
}