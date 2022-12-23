// SPDX-License-Identifier: MIT

 import "./IERC20.sol";
 pragma solidity ^0.8.0; 

  contract ERC20 is IERC20
  {
    string private _name = "Fan Token System";
    string private _symbol = "FTS";
    uint8 private _decimals = 18;
    uint256 private _totalSuply ;

    mapping ( address => uint256 ) _balances;
    mapping (address => mapping (address => uint256) ) _allowed;

    constructor (uint256 tokenAmount) 
    {
        uint256 _inittotalSupply = tokenAmount * 10 ** _decimals;
        _totalSuply = _inittotalSupply;
        _balances[msg.sender] = _totalSuply;
    }

    function name () public view  returns (string memory) {

        return _name;
    }

    function symbol () public view returns (string memory) {

        return _symbol;
    }

    function decimals () public view returns (uint256) {

        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {

        return _totalSuply;
    }

    function balanceOf(address owner) public view override returns (uint256) {

        require (
            owner != address(0), 'this address is zero');

        return _balances [owner];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {

        require (
            owner != address(0), 'this address is the zero');
        require (
            spender != address(0), 'this address is the zero');

            return _allowed[owner][spender];
    }

    function approve (address spender, uint256 value) public override returns (bool) {
        
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);

        return true;
    }

    function transfer (address to, uint256 value) public override returns (bool) {
        
        require(
        _balances[msg.sender] >= value, 'balance too low');

        _balances[msg.sender] -= value;
        _totalSuply -= value * (1 gwei / 2);
        _balances[to] += value;
        emit Transfer((msg.sender), to, value);

        return true;
    }

    function transferFrom (address from, address to, uint256 value) public override returns (bool) {

        require (
            _balances[from] >= value, "balance to low");
        require (
            _allowed[msg.sender][to] >= value, "allowance to low");

        _balances[from] -= value;
        _totalSuply -= value * (1 gwei / 2);
        _balances[to] += value;

        emit Transfer(from, to, value);
        return true;
    }
  }