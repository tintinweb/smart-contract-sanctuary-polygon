/**
 *Submitted for verification at polygonscan.com on 2022-09-07
*/

pragma solidity >=0.4.5 <0.9.0;

contract Lottery {
 
 address owner;
 address payable[] participants;
 
 constructor(){
     owner = msg.sender;
 }
 
 modifier onlyOwner {
     require ( msg.sender == owner );
     _;
 }
 
 function Owner() public view returns(address){
     return msg.sender;
 }
 
 function getBalance() onlyOwner public view returns(uint){
     return address(this).balance;
 }
 
 receive() external payable {
     require ( msg.sender != owner, "Owner not send" );
     require ( msg.value == 2 ether, "Invalid amount" );
     participants.push(payable(msg.sender));
 }
 
 function transferAmount() public view returns(uint) {
     uint amount = (getBalance() / 100) * 95;
     return amount;
 }
 
 function random() onlyOwner public view returns(uint){
    return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, participants.length)));
 }
 
 function Winner() onlyOwner public payable{
     address payable winner;
     uint index = random() % participants.length;
     winner = participants[index];
     winner.transfer(transferAmount());
     participants = new address payable[](0);
 }
 
 
    
    
}