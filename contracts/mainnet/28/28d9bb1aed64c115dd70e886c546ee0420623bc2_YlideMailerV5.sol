// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import './Owned.sol';

contract YlideMailerV5 is Owned {

    uint128 public contentPartFee = 0;
    uint128 public recipientFee = 0;
    address payable public beneficiary;

    event MailPush(uint256 indexed recipient, address indexed sender, uint256 msgId, bytes key);
    event MailContent(uint256 indexed msgId, address indexed sender, uint16 parts, uint16 partIdx, bytes content);
    event MailBroadcast(address indexed sender, uint256 msgId);

    constructor() {
        beneficiary = payable(msg.sender);
    }

    function setFees(uint128 _contentPartFee, uint128 _recipientFee) public onlyOwner {
        contentPartFee = _contentPartFee;
        recipientFee = _recipientFee;
    }

    function setBeneficiary(address payable _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }

    function buildHash(uint256 senderAddress, uint32 uniqueId, uint32 time) public pure returns (uint256 _hash) {
        bytes memory data = bytes.concat(bytes32(senderAddress), bytes4(uniqueId), bytes4(time));
        _hash = uint256(sha256(data));
    }

    // Virtual function for initializing bulk message sending
    function getMsgId(uint256 senderAddress, uint32 uniqueId, uint32 initTime) public pure returns (uint256 msgId) {
        msgId = buildHash(senderAddress, uniqueId, initTime);
    }

    // Send part of the long message
    function sendMultipartMailPart(uint32 uniqueId, uint32 initTime, uint16 parts, uint16 partIdx, bytes calldata content) public {
        if (block.timestamp < initTime) {
            revert();
        }
        if (block.timestamp - initTime >= 600) {
            revert();
        }

        uint256 msgId = buildHash(uint256(uint160(msg.sender)), uniqueId, initTime);

        emit MailContent(msgId, msg.sender, parts, partIdx, content);

        if (contentPartFee > 0) {
            beneficiary.transfer(contentPartFee);
        }
    }

    // Add recipient keys to some message
    function addRecipients(uint32 uniqueId, uint32 initTime, uint256[] calldata recipients, bytes[] calldata keys) public {
        uint256 msgId = buildHash(uint256(uint160(msg.sender)), uniqueId, initTime);
        
        for (uint i = 0; i < recipients.length; i++) {
            emit MailPush(recipients[i], msg.sender, msgId, keys[i]);
        }

        if (recipientFee * recipients.length > 0) {
            beneficiary.transfer(uint128(recipientFee * recipients.length));
        }
    }

    function sendSmallMail(uint32 uniqueId, uint256 recipient, bytes calldata key, bytes calldata content) public {
        uint256 msgId = buildHash(uint256(uint160(msg.sender)), uniqueId, uint32(block.timestamp));

        emit MailContent(msgId, msg.sender, 1, 0, content);
        emit MailPush(recipient, msg.sender, msgId, key);

        if (contentPartFee + recipientFee > 0) {
            beneficiary.transfer(uint128(contentPartFee + recipientFee));
        }
    }

    function sendBulkMail(uint32 uniqueId, uint256[] calldata recipients, bytes[] calldata keys, bytes calldata content) public {
        uint256 msgId = buildHash(uint256(uint160(msg.sender)), uniqueId, uint32(block.timestamp));

        emit MailContent(msgId, msg.sender, 1, 0, content);

        for (uint i = 0; i < recipients.length; i++) {
            emit MailPush(recipients[i], msg.sender, msgId, keys[i]);
        }

        if (contentPartFee + recipientFee * recipients.length > 0) {
            beneficiary.transfer(uint128(contentPartFee + recipientFee * recipients.length));
        }
    }

    function broadcastMail(uint32 uniqueId, bytes calldata content) public {
        uint256 msgId = buildHash(uint256(uint160(msg.sender)), uniqueId, uint32(block.timestamp));

        emit MailContent(msgId, msg.sender, 1, 0, content);
        emit MailBroadcast(msg.sender, msgId);

        if (contentPartFee > 0) {
            beneficiary.transfer(uint128(contentPartFee));
        }
    }

    function broadcastMailHeader(uint32 uniqueId, uint32 initTime) public {
        uint256 msgId = buildHash(uint256(uint160(msg.sender)), uniqueId, initTime);

        emit MailBroadcast(msg.sender, msgId);
    }
}