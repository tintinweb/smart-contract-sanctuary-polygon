/**
 *Submitted for verification at polygonscan.com on 2022-02-16
*/

pragma solidity 0.7.4;
contract Dummy {
uint public dummy_entry;
constructor() public {
dummy_entry = 69;
}
function SetDummy(uint new_dummy) public {
dummy_entry = new_dummy;
}
}