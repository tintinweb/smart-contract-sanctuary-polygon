/**
 *Submitted for verification at polygonscan.com on 2022-05-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Main coin information
contract SmartBEP20Token {
    // Initialize addresses mapping
    mapping(address => uint) public balances;
    // Total supply (in this case 1000 tokens)
    uint public totalSupply;
    // Tokens Name
    string public name = "SmartR Token";
    // Tokens Symbol
    string public symbol = "STR";
    // Total Decimals (max 18)
    uint public decimals = 18;
    //Owner of the token
    address public Owner;

    //Some functions can only be performed by the owner:
    modifier onlyOwner {
        require(msg.sender==Owner,"Only Owner can Call");
        _;
    }
    // Transfers
    event Transfer(address indexed from, address indexed to, uint value);
    
    // Event executed only ones uppon deploying the contract
    constructor(uint _totalSupply) {
        // Give all created tokens to adress that deployed the contract
        balances[msg.sender] = _totalSupply;
        totalSupply=_totalSupply;
    }
    //The user will buy the tokens for fiat currency
    function buyTokens(address addr, uint amount) onlyOwner public {
    transferFrom(address(this),addr,amount);

    }
    // Check balances
    function balanceOf(address addr) public view returns(uint) {
        return balances[addr];
    }
    // marketFare + (10% for the platform owner)
    function transferFare(uint marketFare, address driverAddress) public payable {
        uint ownerShare = ((marketFare)/100)*10;
        require(msg.value > marketFare+ownerShare, "Not Enough Balance");
        transferFrom(msg.sender,address(this),ownerShare);
        transferFrom(msg.sender,driverAddress,ownerShare);
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)
    {
         require(_value <= balanceOf(_from));
       // require(_value <= allowance[_from][msg.sender]);
        // add the balance for transferFrom
        balances[_to] += _value;
        // subtract the balance for transferFrom
        balances[_from] -= _value;
        //allowance[msg.sender][_from] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    // Transfering coins function
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'Insufficient balance');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
}