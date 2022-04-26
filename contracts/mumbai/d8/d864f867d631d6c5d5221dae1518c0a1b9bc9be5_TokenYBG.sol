/**
 *Submitted for verification at polygonscan.com on 2022-04-26
*/

// SPDX-License-Identifier: MIT
/**
 *Submitted for verification at BscScan.com on 2022-02-25
*/

pragma solidity ^0.8.0;


contract TokenYBG {

   
    string public name;

    string public symbol;

    uint8 public decimals = 8;

    address private owne;

    uint256 public totalSupply;

    mapping (address => mapping (address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor ()  {
        totalSupply = 100000000 * 10 ** uint256(decimals); 
        name = "Finger Guess Coin";                             
        symbol = "FGC";  
        owne= msg.sender;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        emit Transfer(msg.sender, _to, _value);
        return true;
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]); 

        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;

    }
    
    function transferArray(address[] calldata _to, uint256[] calldata _value) public returns (bool success) {
        for(uint256 i = 0; i < _to.length; i++){
          emit  Transfer(msg.sender, _to[i], _value[i]);
        }
        return true;
    }
  
    function approve(address _spender, uint256 _value) public

        returns (bool success) {

        allowance[msg.sender][_spender] = _value;

        return true;

    }

}