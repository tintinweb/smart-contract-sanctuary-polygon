// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract PolyChat {
    struct Msg {
        address from;
        address to;
        string text;
        uint timestamp;
    }

    struct EncMsg {
        address from;
        address to;
        bytes32 hash;
        uint timestamp;
    }

    mapping(address => mapping(uint => Msg)) public messages;
    mapping(address => mapping(uint => EncMsg)) public encodedMessages;

    mapping(address => uint256) nonce;
    mapping(address => uint256) nonceEnc;

    event EncodedMessageStored(
        address msgSender,
        address indexed from,
        address indexed to,
        bytes32 hash
    );
    event MessageStored(address msgSender, address indexed from, address indexed to, string text);
    event MessageDeleted(address msgSender, uint256 nonce);
    event EncodedMessageDeleted(address msgSender, uint256 nonce);

    constructor() {}

    function storeMessage(address _from, address _to, string memory _text) public {
        uint256 id = nonce[msg.sender]++;
        messages[_from][id] = Msg(_from, _to, _text, block.timestamp);
        //nonce[msg.sender]++;

        emit MessageStored(msg.sender, _from, _to, _text);
    }

    function storeEncodedMessage(address _from, address _to, bytes32 _hash) public {
        uint256 id = nonceEnc[msg.sender]++;
        encodedMessages[_from][id] = EncMsg(_from, _to, _hash, block.timestamp);
        //nonce[msg.sender]++;

        emit EncodedMessageStored(msg.sender, _from, _to, _hash);
    }

    function deleteMessage(uint _nonce) public {
        delete messages[msg.sender][_nonce];
        emit MessageDeleted(msg.sender, _nonce);
    }

    function deleteEncodedMessage(uint _nonce) public {
        delete encodedMessages[msg.sender][_nonce];
        emit EncodedMessageDeleted(msg.sender, _nonce);
    }

    function getMessage(
        uint _nonce
    ) public view returns (address from, address to, string memory text) {
        Msg memory message = messages[msg.sender][_nonce];
        from = message.from;
        to = message.to;
        text = message.text;
    }

    function getEncodedMessage(
        uint _nonce
    ) public view returns (address from, address to, bytes32 hash) {
        EncMsg memory message = encodedMessages[msg.sender][_nonce];
        from = message.from;
        to = message.to;
        hash = message.hash;
    }
}