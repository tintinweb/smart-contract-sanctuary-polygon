/**
 *Submitted for verification at polygonscan.com on 2023-06-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract RedirectFunds {
    address payable internal _implOwner;
    address internal _owner;

    constructor(address payable implOwner) {
        _implOwner = implOwner;
        _owner = msg.sender;
    }

    function implOwner() public view returns (address) {
        return _implOwner;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function setImplOwner(address payable _newImplOwner) public {
        require(msg.sender == _owner, "Only owner can change the recipient");
        _implOwner = _newImplOwner;
    }

    function setOwner(address payable _newOwner) public {
        require(msg.sender == _owner, "Only owner can change the recipient");
        _owner = _newOwner;
    }

}