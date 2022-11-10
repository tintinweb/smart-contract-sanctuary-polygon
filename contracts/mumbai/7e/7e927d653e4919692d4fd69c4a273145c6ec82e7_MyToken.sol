/**
 *Submitted for verification at polygonscan.com on 2022-11-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20{
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract MyToken is IERC20 {

    string private _name;
    string private _symbol; //代币名称
    uint8 private _decimal; 
    uint256 private _totalSupply;   //总币量

    mapping (address => uint256) private balances;  //记录每个人账户的钱
    mapping (address => mapping (address => uint256)) private allowances;   //允许谁话我多少钱 adam(zhangsan) => 100  adam允许zhangsan花他100

    constructor(string memory _na,string memory _sym,uint8 _deci, uint256 _initialSupply){
        _name = _na;
        _symbol = _sym;
        _decimal = _deci;
        _totalSupply = _initialSupply;

        balances[msg.sender] = _initialSupply;
    }


    function name() external override view returns (string memory){
        return _name;
    }
    function symbol() external override view returns (string memory){
        return _symbol;
    }
    function decimals() external override view returns (uint8){
        return _decimal;
    }
    function totalSupply() external override view returns (uint256){
        return _totalSupply;
    }
    function balanceOf(address _owner) external override view returns (uint256 balance){
        return  balances[_owner];
    }
    function transfer(address _to, uint256 _amount) external override returns (bool success){
        // 把我的钱给谁,我的钱必须大于value
        require(balances[msg.sender] >= _amount,"Not enough amount!");
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        emit Transfer(msg.sender, _to, _amount);
        return true;

    }

    function transferFrom(address _from, address _to, uint256 _value) external override returns (bool success){
        uint _allowance = allowances[_from][msg.sender];
        uint leftAllowance = _allowance - _value;
        require(leftAllowance >= 0,"Not enought allowance!");
        allowances[_from][msg.sender] = leftAllowance;
        require(balances[_from] > _value,"Not enought Amount");
        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from,_to,_value);
        return true;

    }

    function approve(address _spender, uint256 _value) external override returns (bool success){
        // 允许_spender调用花我多少钱
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender,_spender,_value);
        return true;

    }
    function allowance(address _owner, address _spender) external override view returns (uint256 remaining){
        return allowances[_owner][_spender];
    }
}