/**
 *Submitted for verification at polygonscan.com on 2022-02-02
*/

pragma solidity ^0.8.1;
contract SendMoneyExample {
uint public balanceReceived;
function receiveMoney() public payable {
balanceReceived += msg.value;
}
function getBalance() public view returns(uint) {
return address(this).balance;
}
function withdrawMoney() public {
address payable to = payable(msg.sender);
to.transfer(getBalance());
}
function withdrawMoneyTo(address payable _to) public {
_to.transfer(getBalance());
}
}