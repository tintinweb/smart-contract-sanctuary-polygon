/**
 *Submitted for verification at polygonscan.com on 2022-12-29
*/

pragma solidity >= 0.8.11 <0.9.0;
contract Resolver {
    event Deposit(address indexed _from, address indexed _to, uint _value);
    event CalledBy(address caller);

 function hitCount(address from, address to, uint256 amount) external returns (bool){
    emit Deposit(from,to,amount);
    emit CalledBy(msg.sender);
     return true;
 }
}