/**
 *Submitted for verification at polygonscan.com on 2022-09-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract MyTest1{
    string name;
    address public owner;

     event OwnerSet(address indexed oldOwner, address indexed newOwner);

    constructor(string memory name_) {
        name = name_;
        owner = msg.sender;
    }
    
     function update_name(string memory newname) public{
         name = newname;
    }

    function get_name() public view returns (string memory) {
        return name;
    }

    modifier isOwner() {
     require(msg.sender == owner, "Caller is not owner");
     _;
    }

    function changeOwner(address newowner) public isOwner {
        emit OwnerSet(owner, newowner);
        owner = newowner;
    }

    function killSelf()  public {
     if (owner == msg.sender) { 
          selfdestruct(payable(owner));
       }
    }

}