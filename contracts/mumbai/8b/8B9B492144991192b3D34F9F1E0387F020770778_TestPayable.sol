// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

contract TestPayable {
    // Payable address can receive Ether
    address payable public owner;

    // Payable constructor can receive Ether
    constructor(address payable _owner) {
        owner = _owner;
    }

    // Function to deposit Ether into this contract.
    // Call this function along with some Ether.
    // The balance of this contract will be automatically updated.
    function deposit() public payable {}

    // Call this function along with some Ether.
    // The function will throw an error since this function is not payable.
    function notPayable() public {}

    // Function to withdraw all Ether from this contract.
    function withdraw() public {
        // get the amount of Ether stored in this contract
        uint amount = address(this).balance;

        // send all Ether to owner
        // Owner can receive Ether since the address of owner is payable
        (bool success, ) = owner.call{ value: amount }("");
        require(success, "Failed to send Ether");
    }

    // Function to transfer Ether from this contract to address from input
    function transfer(address payable _to, uint _amount) public {
        // Note that "to" is declared as payable
        (bool success, ) = _to.call{ value: _amount }("");
        require(success, "Failed to send Ether");
    }

    // Function to deposit AND waste gas.
    // repeat - waste gas on writing storage in a loop.
    // junk - dynamic buffer to stress the function size.
    mapping(uint256 => uint256) public xxx;
    uint256 public offset;

    function depositAndWasteGas(uint256 repeat, string calldata /*junk*/) public payable {
        for (uint256 i = 1; i <= repeat; i++) {
            offset++;
            xxx[offset] = i;
        }
    }
}