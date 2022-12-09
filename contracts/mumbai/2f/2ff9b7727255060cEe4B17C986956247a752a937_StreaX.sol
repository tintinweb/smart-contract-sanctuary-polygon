/**
 *Submitted for verification at polygonscan.com on 2022-12-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


contract StreaX {

string public name = "StreaX";
string public symbol = "STX";

uint public totalSupply;
address owner;

mapping(address=>uint) holders;

modifier onlyOwner{            
    require(msg.sender == owner, "YOU ARE NOT OWNER");
    _;
}

constructor(){
    owner = msg.sender;         //assing owner while deplying 
}


//owner can change owner
function changeOwner(address _new) onlyOwner external {
    owner = _new;
}


//see balance of any address
function balanceOf(address _of) view external returns(uint){
    return  holders[_of];
}


//owner can create new token
function createToken(uint _amt) onlyOwner external {
        totalSupply += _amt;
        holders[owner] += _amt;
}


//owner can issue new token to any address
function issueToken(uint _amt,address _to) onlyOwner external {
     totalSupply += _amt;
     holders[_to] += _amt;
}


//transfer token from one address to another
function transfer(uint _amt,address _to) external{
    holders[msg.sender] -= _amt;
    holders[_to] += _amt;
}

}