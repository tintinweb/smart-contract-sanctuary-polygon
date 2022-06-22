/**
 *Submitted for verification at polygonscan.com on 2022-06-22
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC20 {
    function totalSupply() external view returns (uint _totalSupply);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _currentValue, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event TransferFrom(address indexed _spender, address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _oldValue, uint256 _value);
}

contract Nikita is ERC20{
    string public constant symbol = "NKT";
    string public constant name = "Nikita";
    uint8 public constant decimals = 18;

    uint private constant __totalSupply = 1000000000000000000000000;

    mapping (address => uint) private __balanceOf;

    mapping (address => mapping (address => uint)) private __allowances;

    constructor() {
        __balanceOf[msg.sender] = __totalSupply;
    }

    function totalSupply() public pure override returns (uint _totalSupply) {
        _totalSupply = __totalSupply;
    }

    function balanceOf(address _addr) public view override returns (uint balance) {
        return __balanceOf[_addr];
    }

    function transfer(address _to, uint256 _value) public override returns (bool success) {
        if (_value > 0 && _value <= balanceOf(msg.sender)) {
            __balanceOf[msg.sender] -= _value;
            __balanceOf[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        }
        return false;
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
        if (__allowances[_from][msg.sender] > 0 &&
            _value > 0 &&
            __allowances[_from][msg.sender] >= _value 
            && !isContract(_to)) {
                __allowances[_from][msg.sender] -= _value;
                __balanceOf[_from] -= _value;
                __balanceOf[_to] += _value;
                emit TransferFrom(msg.sender, _from, _to, _value);
                return true;
        }
        return false;
    }

    function approve(address _spender, uint256 _currentValue, uint256 _value) public override returns (bool success) {
        if (__allowances[msg.sender][_spender] == _currentValue) {
            __allowances[msg.sender][_spender] = _value;
            emit Approval(msg.sender, _spender, _currentValue, _value);
        }
        return false;
    }

    function allowance(address _owner, address _spender) public view override returns (uint256 remaining) {
        return __allowances[_owner][_spender];
    }

    function isContract(address _addr) public view returns (bool) {
        // NOT A FOOLPROOF METHOD IF FUNCTION CALLED BY CONTRACT FROM CONSTRUCTOR

        uint codeSize;

        assembly {
            codeSize := extcodesize(_addr)
        }

        return codeSize > 0;

        // or
        // return _addr.code.length > 0;
    }
}