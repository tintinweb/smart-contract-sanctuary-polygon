/**
 *Submitted for verification at polygonscan.com on 2022-06-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.5.0;


contract QBTC {

    string public name;
    string public symbol;
    uint8 public decimals; 
    uint256 public TotalSupply;
    mapping (address => uint256) public balancesOf;
    mapping (address => mapping(address => uint256)) public allowance;

    constructor() public {
        name = "Quantic Bitcoin";
        symbol = "QBTC";
        decimals = 18;
        TotalSupply = 21000000 * (uint256(10) ** decimals);
        balancesOf[msg.sender] = TotalSupply;


     }


    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balancesOf[msg.sender] >= _value);
        balancesOf[msg.sender] -= _value;
        balancesOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
            allowance[msg.sender][_spender] = _value;
            emit Approval(msg.sender, _spender, _value);
            return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {

            require(balancesOf[_from] >= _value);
            require(allowance[_from][msg.sender] >= _value);
            balancesOf[_from] -= _value;
            balancesOf[_to] += _value;
            allowance[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
    }


}