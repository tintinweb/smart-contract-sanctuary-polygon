// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EmailSystem {
    struct Email {
        string sender;
        string recipient;
        string subject;
        string body;
        bool isSent;
    }

    mapping(address => Email[]) private inbox;
    mapping(address => bool) private hasAccess;

    event EmailSent(address indexed sender, address indexed recipient, string subject);

    modifier onlyOwner() {
        require(hasAccess[msg.sender], "Access denied");
        _;
    }

    function grantAccess() external {
        hasAccess[msg.sender] = true;
    }

    function revokeAccess() external {
        hasAccess[msg.sender] = false;
    }

    function sendEmail(address _recipient, string memory _subject, string memory _body) external onlyOwner {
        Email memory newEmail = Email({
            sender: toAsciiString(msg.sender),
            recipient: toAsciiString(_recipient),
            subject: _subject,
            body: _body,
            isSent: true
        });

        inbox[_recipient].push(newEmail);
        emit EmailSent(msg.sender, _recipient, _subject);
    }

    function getInbox() external view returns (Email[] memory) {
        require(hasAccess[msg.sender], "Access denied");
        return inbox[msg.sender];
    }

function toAsciiString(address _address) internal pure returns (string memory) {
    bytes memory s = new bytes(40);
    for (uint i = 0; i < 20; i++) {
        uint8 b = uint8(uint160(_address) / (2**(8*(19 - i))));
        uint8 hi = b / 16;
        uint8 lo = b - 16 * hi;
        s[2*i] = char(hi);
        s[2*i+1] = char(lo);
    }
    return string(s);
}

function char(uint8 b) internal pure returns (bytes1 c) {
    if (b < 10) return bytes1(b + 0x30);
    else return bytes1(b + 0x57);
}



    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}