/**
 *Submitted for verification at polygonscan.com on 2022-12-06
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract Incinerator {
    address public incineratorWallet = 0xC08AF4fb5Dc4E1bb707a384dBA75011028cD67e1;
    address public owner;
    constructor() {
        owner = msg.sender;
    }

    function changeIncineratorWallet(address _incineratorWallet) public onlyOwner {
        incineratorWallet = _incineratorWallet;
    }

    function send() public payable {
        bool sent = payable(incineratorWallet).send(msg.value);
        require(sent, "Sending was unsuccessful");
    }

    function transferOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
}