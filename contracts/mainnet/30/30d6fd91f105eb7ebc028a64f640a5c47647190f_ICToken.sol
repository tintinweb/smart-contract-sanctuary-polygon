/**
 *Submitted for verification at polygonscan.com on 2022-12-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/*
 * Author : Mantas Noreika
 * Date   : 10-11/2022
 * @title ERC20 Only
 * @dev Create a sample ERC20 standard token == 77000000
 */
 
contract SafeExec {

function sub(uint256 a, uint256 b) internal pure returns (bool) {
 if(b <= a){
 return true;
 }
 return false;
 }
function add(uint256 a, uint256 b) internal pure returns (bool) {
 uint256 c = a + b;
if(c >= a){
 return true;
 }
 return false;
 }
}

contract  ICToken is SafeExec{
   
    
    address payable owner;    // Owner of contract
    address assistance = 0x72723951A415284222d76607125a18a7f239FB6f; // mint wallet
    address icn = 0xf93b7fbA85A96367DDb4e8d9944f4c1f476a4dDC;       // ICNetwork wallet

    string public name = "ICToken";
    string public symbol = "ICT";
    uint256 public decimals = 0;                  // No decimal points
    uint currentSupply;                           // supply in circulation
    uint maxSupply = 77000000;                    // Maximum Total Supply allowed

    mapping (address => uint)  balances;   // Balances of tokens at address
    mapping (address => mapping(address => uint)) allowance; // allownaces of tokens

  constructor ()                     // Initialize owner and supply stored at owners address
    {
        currentSupply = 36000000;
        owner = payable(msg.sender);
        balances[msg.sender] = currentSupply;
        
    }

      modifier onlyBy(){              // Only owner
        require(owner==msg.sender,"! Only Owner Allowed");
        _;
        
    }

     modifier andAssistance(){       // Owners address and private address's only
        require((assistance==msg.sender) || (owner==msg.sender) || (icn==msg.sender),"! Owner or Assistance Allowed");
        _;
        
    }
                // ---=== Below events ===---
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
   
    event Deducted(address indexed owner, uint value);
    event OwnerSet(address indexed Owner);
               // ---===   End Events   ===---
  
               
    function assist(uint amount)public andAssistance{   
     require(balances[owner]>amount,"Insuficient Funds");
     balances[owner] -=amount;                     // transfer to private address
     balances[assistance] += amount;
     emit Deducted(owner,amount);
    }

    function transfer(address recipient, uint amount) public returns (bool) { // transfer to
       if (amount > balances[msg.sender]){
            revert("Insuficient Balance");
       }
        require(add(balances[recipient], amount)==true,"! Overflow");
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) public returns (bool) {  
        require(balances[msg.sender]>amount,"Insufficient Balance");
        allowance[msg.sender][spender] += amount;             //address allow to address spend some ICT 
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address _from, address _to,uint amount)      
        public returns (bool) {           // Transfer allownace 
        require(allowance[_from][_to] > amount,"Transfer is impossible '\n' No allowance !");
        allowance[_from][_to] -= amount;
        balances[_from] -= amount;
        balances[_to] += amount;
        emit Transfer(_from, _to, amount);
        return true;
    }

    function mint(address _to,uint _amount) public andAssistance returns(uint){
        require(owner==msg.sender,"! Only Owner");
        require(currentSupply<(maxSupply-_amount));
        balances[_to] += _amount;                  // Mint additional ICT tokens
        currentSupply += _amount;
        emit Transfer(_to, owner, _amount);
        return balances[owner];
    }

    function burn(uint _amount)public andAssistance{
        require(owner==msg.sender,"! Only Owner");              // Burn ICT tokens
        require(sub(balances[owner],_amount)==true,"Overflow");
        require((currentSupply -_amount)>50000000,"! Minimum Limit Reached");
        balances[owner] -= _amount;
        currentSupply -= _amount;
        maxSupply -= _amount;
        emit Deducted(msg.sender, _amount);
    }

    function balanceOf(address user)public view returns(uint){
        return balances[user];
    }

    function supply()public view  returns(uint currentsupply){
    return currentSupply;
   }

    function totalSupply()public view  returns(uint mxsupply){
    return maxSupply;
   }

   function getOwner()public view  returns(address creator){
   creator=owner;
   }

}