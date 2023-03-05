/**
 *Submitted for verification at polygonscan.com on 2023-03-04
*/

/**
* Simple test smart contract
* @author Farbod Shams <[email protected]>
**/

pragma solidity ^0.8.0;

contract Counter {
    uint private i;
    address private owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this method");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function increase() public {
        i = i + 1;
    }

    function decrease() public {
        require(i > 0, "Counter cannot be less than zero");
        i = i - 1;
    }

    function setManually(uint value) public onlyOwner {
        i = value;
    }

    function getCounter() public view returns(uint) {
        return i;
    }

    function getSender() public view onlyOwner returns(address) {
        return msg.sender;
    }
}