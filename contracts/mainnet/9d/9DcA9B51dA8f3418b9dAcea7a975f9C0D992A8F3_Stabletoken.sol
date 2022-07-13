/**
 *Submitted for verification at polygonscan.com on 2022-07-13
*/

// SPDX-License-Identifier: CC-BY-SA 4.0
// https://creativecommons.org/licenses/by-sa/4.0/

// TL;DR: The creator of this contract (@LogETH) is not liable for any damages associated with using the following code
// This contract must be deployed with credits toward the original creator, @LogETH.
// You must indicate if changes were made in a reasonable manner, but not in any way that suggests I endorse you or your use.
// If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.
// You may not apply legal terms or technological measures that legally restrict others from doing anything the license permits.
// This TL;DR is solely an explaination and is not a representation of the license.

// By deploying this contract, you agree to the license above and the terms and conditions that come with it.

pragma solidity >=0.7.0 <0.9.0;

contract Stabletoken{

//// This contract is a special stablecoin that allows transfers only while its pegged to a dollar

    // How to setup this contract

    // Step 1: Configure the contstructor to the values you want, make sure to double and triple check!
    // Step 2: Deploy the contract
    // Step 3: That's pretty much it, you can start using it from there


//// Commissioned by Spagetti#7777 on 6/17/2022

    // the constructor that activates when you deploy the contract, this is where you change settings before deploying.
    
    constructor(){

        name = "Stable token";
        decimals = 18;
        symbol = "STB";

        tolerance = 100; // what % deviation in BPS should transfers be blocked 
    }

//////////////////////////                                                          /////////////////////////
/////////////////////////                                                          //////////////////////////
////////////////////////            Variables that this contract has:             ///////////////////////////
///////////////////////                                                          ////////////////////////////
//////////////////////                                                          /////////////////////////////


    uint Nonce;
    uint tolerance;
    uint MAXLTV;

    function isPriceBelow() internal view returns (bool){

        if(1 <= (price - tolerance*(price/10000))){

            return false;
        }
        else{return true;}
    }


//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////             Visible functions this contract has:             ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////

    function mintTokens(uint amount) public {

        balances[msg.sender] += amount;
    }

    function EditDEX(address WhatDEX) public {

        DEX = WhatDEX;
    }

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    string public name;
    uint8 public decimals = 18;
    string public symbol;
    uint public totalSupply;
    address DEX;

    function mint(uint amount, address Who) internal {

        balances[Who] += amount;
        totalSupply += amount;
        emit Transfer(msg.sender, Who, amount);
    }

    function burn(uint amount, address Who) internal {

        require(amount < balances[Who], "You cannot burn more tokens than you have");

        balances[Who] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {

        require(balances[msg.sender] >= _value, "You can't send more tokens than you have");
        if(isPriceBelow()){

            require(msg.sender == DEX, "The current price is below peg, you cannot sell");
        }

        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(address(0), _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {

        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value, "You can't send more tokens than you have or the approval isn't enough");
        if(isPriceBelow()){

            require(msg.sender == DEX, "The current price is below peg, you cannot sell");
        }

        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }


    function balanceOf(address _owner) public view returns (uint256 balance) {

        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {

        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value); 
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {

        return allowed[_owner][_spender];
    }

    uint public price;

    function updatePrice(uint x) public {

        price = x;
    }

//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////      Internal and external functions this contract has:      ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////



}

//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////      Contracts that this contract uses, contractception!     ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////