// SPDX-License-Identifier: MIT
//Caution: Only deployer of smart contract can take out any ether from this contract
pragma solidity ^0.8.9;

contract Liquidity {

    address payable owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(){
        owner = payable(msg.sender);
    }

    function balance() public view returns (uint256){
        return(address(this).balance);
    }

    function withdraw(uint256 amount) public onlyOwner {
        (bool sent, bytes memory data) = payable(msg.sender).call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    fallback() payable external {}

    receive() payable external {}
}