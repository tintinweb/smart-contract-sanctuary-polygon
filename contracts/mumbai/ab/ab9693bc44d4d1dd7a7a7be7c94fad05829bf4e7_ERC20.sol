/**
 *Submitted for verification at polygonscan.com on 2023-04-19
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.5.0 <0.9.0;

contract ERC20 {

string public symbol;
string public name;
uint8 public decimals;
uint public totalSupply;
uint public cirSupply;
uint public maxSupply;
uint public burned;
uint public mintable;
address public owner;
address public contractCreator;
address public burningAddress;


//Accounts Database
mapping(address=>uint) public balanceOf;
mapping(address=>mapping(address=>uint)) allowance;

//events for frontend

event Transfer(address indexed from, address indexed to, uint amount);
event Approval(address indexed msgSender, address spender, uint amount);


constructor(string memory _symbol, string memory _name, uint8 _decimals, uint _totalSupply, uint _maximumSupply)
{
symbol = _symbol;
name = _name;
decimals= _decimals;
maxSupply = _maximumSupply * (10**decimals);
totalSupply = _totalSupply * (10**decimals);
owner = msg.sender;
contractCreator=owner;
balanceOf[owner] = totalSupply;
mintable = maxSupply-totalSupply;
emit Transfer(address(0), owner, _totalSupply);
}

modifier ownerOnly(){
require(msg.sender==owner);
_;
}
modifier mintAvail(uint _amount){
require(_amount<=mintable,"Amount can't be more than mintable tokens");
_;
}

modifier balAvail(uint _amount){
require(_amount<=balanceOf[msg.sender],"Enter amount less than your current balance");
_;
}


//TransferOwnership

function transferOwnerShip(address _address) public {
owner = _address;
}

//Check Balance

function checkBal(address userAddress) public view returns (uint) {
return balanceOf[userAddress];
}


// Minting


function mintToOwner(uint _amount) public ownerOnly() mintAvail(_amount){


totalSupply += _amount;
if (owner!=contractCreator) {
cirSupply+=_amount;
}
balanceOf[owner] += _amount;
mintable = maxSupply-totalSupply;

}


function mintToOther(address receiverAddress, uint _amount) public ownerOnly() mintAvail(_amount){
require(receiverAddress!=owner, "Use MintToOwner function.");

totalSupply += _amount;
balanceOf[receiverAddress] += _amount;

if(receiverAddress!=contractCreator && receiverAddress!=burningAddress)
{cirSupply+=_amount;}

burned = balanceOf[burningAddress];
mintable = maxSupply-totalSupply;

}

//

//Burning
function Burn(uint _amount) public balAvail(_amount) {

if(msg.sender!=contractCreator)
{cirSupply-=_amount;}

balanceOf[msg.sender]-=_amount;
balanceOf[burningAddress] += _amount;
burned = balanceOf[burningAddress];

}


//

//Transfer
function transfer(address receiverAddress, uint _amount) public returns(bool) {

balanceOf[msg.sender] -= _amount;
balanceOf[receiverAddress]+= _amount;


//From ContractCreator, Circulation Increase
if(msg.sender==contractCreator){cirSupply+=_amount;}
//To ContractCreator or Burning Address, Circulation Decrease
if(receiverAddress==contractCreator || receiverAddress==burningAddress){cirSupply-=_amount;}
burned = balanceOf[burningAddress];

emit Transfer(msg.sender, receiverAddress, _amount);
return true;

}


//
//TransferFrom for interacting with third-party contracts
function transferFrom(address _from, address _to, uint _amount) public returns(bool) {
require(allowance[_from][_to]>=_amount);

balanceOf[_from] -= _amount;
balanceOf[_to]+= _amount;
allowance[_from][_to]-= _amount;

emit Transfer(_from, _to, _amount);
return true;
}

//Approve
function approve(address _spender, uint _amount) public returns(bool) {
    allowance[msg.sender][_spender]=_amount;
    emit Approval(msg.sender, _spender, _amount);
    return true;
}

//Manage Allowance

function increaseAllowance(address _spender, uint _increaseBy) public {
    allowance[msg.sender][_spender]+= _increaseBy;
}

function decreaseAllowance(address _spender, uint _decreaseBy) public {
    allowance[msg.sender][_spender]-= _decreaseBy;
}




//

//Transfer to Contract
function ContractTransfer(address receiverAddress, uint _amount) public {
require(_amount<=balanceOf[tx.origin], "Enter amount less than your current balance.");
require(receiverAddress!=burningAddress, "Not a valid contract address.");

balanceOf[tx.origin] -= _amount;
balanceOf[receiverAddress]+= _amount;

//From ContractCreator, Circulation Increase
if (tx.origin==contractCreator) {
cirSupply+=_amount;
}
//To ContractCreator, Circulation Decrease
if(receiverAddress==contractCreator) {
cirSupply-=_amount;
}

}



}//Contract END.