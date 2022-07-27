// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

contract web3Task {

    string private hash;

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

    uint256 public deposits = owner.balance;

    function setHash(string calldata _hash) external {
        hash = _hash;
    }

    function getHash() external view returns(string memory) {
        return hash;
    }

    function transfer() public payable {
        (bool sent, ) = payable(owner).call{value: msg.value}("");
        require(sent, "Failed to send matic");
    }

}