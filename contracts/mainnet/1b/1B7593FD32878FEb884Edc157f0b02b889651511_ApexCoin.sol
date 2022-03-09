/**
 *Submitted for verification at polygonscan.com on 2022-03-09
*/

// SPDX-License-Identifier: None
pragma solidity 0.8.0;

contract ApexCoin{
    mapping (address => uint256) public balanceOf;
    string  public name = "ApexCoin";
    string public symbol = "APC";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000000000000000 *(10 **decimals);

    mapping (address =>mapping(address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor(){
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply );
    }
    function transfer(address _to, uint256 _value) public returns (bool success){
        require (balanceOf[msg.sender] >= _value, "Not enought ApexCoins!");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value );

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(allowance[_from][msg.sender] >= _value, "Transfer not approved");
        require(balanceOf[_from] >= _value, "Not enough tokens to transfer" );

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success){
        allowance[msg.sender][_spender] = _value;
        emit Approval (msg.sender, _spender, _value);
        
        return true;
    }
    
}