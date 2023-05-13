/**
 *Submitted for verification at polygonscan.com on 2023-05-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Fungible Token
 * @dev Fungible token
 */

contract FungibleToken {

    // deployer : 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4 - 19900
    // user1 : 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2 - 80
    // user2 : 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db - 20

    // name 
    string iname;
    // symbol
    string isymbol;
    // decimals
    uint8 idecimals;
    // total supply 
    uint256 itotalSupply;
    // balances
    mapping(address => uint256) balances;

    // contructor
    constructor(string memory _name, string memory _symbol, uint8 _decimals){
        iname = _name;
        isymbol = _symbol;
        idecimals = _decimals;
        itotalSupply = 20000;
        balances[msg.sender] = 20000;        
    }

    // gives back the name of the token
    function name() public view returns (string memory) {
        return iname;
    }

    // gives back you the symbol of your token 
    function symbol() public view returns (string memory) {
        return isymbol;
    }

    // number of decimals of your token
    function decimals() public view returns (uint8){
        return idecimals;
    }

    // query function gives back the total number of tokens
    function totalSupply() public view returns (uint256) {
        return itotalSupply;
    }

    // query giving back the number of tokens
    function balanceOf(address _owner) public view returns (uint256 balance){
        return balances[_owner];
    }

    // transfers a number of tokens to somebody
    function transfer(address _to, uint256 _value) public returns (bool success) {
        // decerease my balance
        balances[msg.sender] -= _value;
        // increase somebody-s balance
        balances[_to] += _value;
        // emit an event
        emit Transfer(msg.sender,_to,_value);
        return true;
    }

    function mint(address _to, uint256 _amount) public {
        //give token
        balances[_to] += _amount;
        // increase total supply
        itotalSupply += _amount;
    }

    // 3 party transfer
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        return true;
    }

    // 3 party transfer
    function approve(address _spender, uint256 _value) public returns (bool success) {
        return true;
    }

    // query for three party transfer
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return 0;
    }

    // Transfer event 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // 3 party transfer event
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


}