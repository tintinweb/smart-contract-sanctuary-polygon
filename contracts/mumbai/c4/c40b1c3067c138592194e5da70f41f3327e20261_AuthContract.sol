/**
 *Submitted for verification at polygonscan.com on 2023-04-13
*/

pragma solidity ^0.8.0;

contract AuthContract {
    address owner;

    constructor() {
        owner = tx.origin;
    }

    function doSomething() public {
        require(tx.origin == owner, "Only the contract owner can perform this action");
        // perform some action
    }

    function withdraw() public {
        require(tx.origin == owner, "Only the contract owner can withdraw funds");
        payable(owner).transfer(address(this).balance);
    }

    function fund() public payable {
        // no authentication required to fund the contract
    }
}