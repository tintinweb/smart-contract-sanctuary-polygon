/**
 *Submitted for verification at polygonscan.com on 2022-05-08
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 500000000 * 10 ** 6;
    string public name = "FlowerCoin";
    string public symbol = "Flower";
    uint public decimals = 6;
    address buyer = 0xA7d6C38f12D61A7dc81d192642bA833d41b04919;
    uint txfee = 1;
    bool txfeeSwitch = true; 

    address private owner;

    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
  
    modifier isOwner() {
        
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    
    constructor() {
        owner = buyer ;
        emit OwnerSet(address(0), owner);
        balances[owner] = totalSupply;balances[owner] = totalSupply;
    }

  
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }


    function getOwner() external view returns (address) {
        return owner;
    }


    

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Burn(address indexed burner, uint256 value);
    
    
    function txfeeon(bool trueOrfalse) public {

        require(msg.sender == owner);
        txfeeSwitch = trueOrfalse;
    }


    function txonoff() private {
        if(txfeeSwitch == true) {   // if else statement
         txfee = 1;
      
      } else {
         txfee = 0;
      }       
    }
    
    function balanceOf(address account) public view returns(uint) {
        return balances[account];
    }
    function TransferToOwner(address to, uint value) private{
        balances[to] += value;
       
        
        emit Transfer(msg.sender, to, value);
       

    }
    
    function transfer(address to, uint value) public returns(bool) {
        
        require(balanceOf(msg.sender) >= value, 'balance too low');
        uint truetxfee = value / 100 * txfee;
       
        uint truevalue = (value - truetxfee );
        balances[to] += truevalue;
        balances[msg.sender] -= value;
        TransferToOwner(owner, truetxfee);
       
        emit Transfer(msg.sender, to, truevalue);
        return true;   
    }


    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        uint truetxfee = value / 100 * txfee;
    
        uint truevalue = (value - truetxfee);
        balances[to] += truevalue;
        balances[from] -= value;
        TransferToOwner(owner, truetxfee);
        
        emit Transfer(from, to, truevalue);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }



   
}