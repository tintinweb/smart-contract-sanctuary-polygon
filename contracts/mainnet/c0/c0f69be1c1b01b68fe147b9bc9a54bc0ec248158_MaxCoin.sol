/**
 *Submitted for verification at polygonscan.com on 2022-03-24
*/

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);

    function approve(address _spender, uint256 _value) external returns (bool);

    function allowance(address _owner, address _spender) external view returns (uint256);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

interface TokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes memory _extraData) external;
}

contract ERC20 is IERC20 {
    uint256 internal _totalSupply;
    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowances;

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view virtual override returns (uint256) {
        return _balances[_owner];
    }

    function transfer(address _to, uint256 _value) public virtual override returns (bool) {
        require(msg.sender != address(0), "MaxCoin: transfer from the zero address");
        require(_balances[msg.sender] >= _value, "MaxCoin: transfer from insufficent balance" );
        require(_balances[_to] + _value > _balances[_to], "MaxCoin: transfer to balance out of bound");
        _balances[msg.sender] -= _value;
        _balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public virtual override returns (bool) {
        require(msg.sender != address(0), "MaxCoin: transfer from the zero address");
        require(_balances[_from] >= _value, "MaxCoin: transfer from insufficent balance");
        require(_allowances[_from][msg.sender] >= _value, "MaxCoin: transfer from insufficent allowance");
        require(_balances[_to] + _value > _balances[_to], "MaxCoin: transfer to balance out of bound");
        _balances[_to] += _value;
        _balances[_from] -= _value;
        _allowances[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public virtual override returns (bool) {
        require(msg.sender != address(0), "MaxCoin: approve from the zero address");
        require(_spender != address(0), "MaxCoin: approve to the zero address");
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view virtual override returns (uint256) {
        return _allowances[_owner][_spender];
    }

}

contract MaxCoin is ERC20 { 
    address public owner;
    string public name;    
    string public symbol;            
    uint8 public decimals;         
    string public version = '0.1';  

    constructor (uint256 _initialAmount, string memory _name, string memory _symbol, uint8 _decimals) {
        owner = msg.sender;
        _balances[msg.sender] = _initialAmount; 
        _totalSupply = _initialAmount;   
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function increaseAllowance(address _spender, uint256 _addedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][_spender];
        require(currentAllowance + _addedValue > currentAllowance, "ERC20: increased allowance out of bound");
        uint256 newValue = currentAllowance + _addedValue;
        approve(_spender, newValue);
        return true;
    }

    function decreaseAllowance(address _spender, uint256 _reducedValue ) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][_spender];
        require(currentAllowance >= _reducedValue, "MaxCoin: decreased allowance below zero");
        uint256 newValue = currentAllowance - _reducedValue;
        approve(_spender, newValue);
        return true;
    }
    
    function mint(address _target, uint256 _amount) public onlyOwner returns (bool success){
        require(_target != address(0), "MaxCoin: mint to the zero address");
        _balances[_target] += _amount;
        _totalSupply += _amount;
        emit Transfer(address(0), owner, _amount);
        emit Transfer(owner, _target, _amount);
        return true;
    }

    function burn(address _target, uint256 _amount) public onlyOwner returns (bool success) {
        require(_target != address(0), "MaxCoin: burn from the zero address");
        uint256 targetBalance = _balances[_target];
        require(targetBalance >= _amount, "MaxCoin: burn amount exceeds balance");
        _balances[_target] = targetBalance - _amount;
        _totalSupply -= _amount;
        emit Transfer(_target, address(0), _amount);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public virtual returns (bool) {
        approve(_spender, _value);
        TokenRecipient(_spender).receiveApproval(msg.sender, _value, address(this), _extraData);
        return true;
    }
    
}