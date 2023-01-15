// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract HDMHandshake {
    event HandshakePosted (
        address indexed inviter,
        address indexed invitee,
        bytes indexed offer
    );

    event HandshakeAnswered (
        address indexed inviter,
        address indexed invitee,
        bytes indexed offer
    );

    function postHandshake(address _invitee, bytes calldata _encryptedOffer) public {
        require(
            msg.sender != _invitee,
            "HDMHandshake: cannot post a handshake with yourself."
        );

        emit HandshakePosted(
            msg.sender,
            _invitee,
            _encryptedOffer
        );
    }

    function answerHandshake(address _inviter, bytes calldata _encryptedOffer) public {
        require(
            msg.sender != _inviter,
            "HDMHandshake: cannot answer a handshake of yourself."
        );

        emit HandshakePosted(
            _inviter,
            msg.sender,
            _encryptedOffer
        );
    }
}