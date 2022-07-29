/**
 *Submitted for verification at polygonscan.com on 2022-07-29
*/

// File: CustomNameTag.sol


pragma solidity ^0.8.0;

contract Ownable {
     
    address private _owner;

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
    require(owner() == msg.sender, "Ownership Assertion: Caller of the function is not the owner.");
      _;
    }
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        _owner = newOwner;
    }
}