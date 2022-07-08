/**
 *Submitted for verification at polygonscan.com on 2022-07-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FxBaseChildTunnel {

    address public fxChild = 0x8397259c983751DAf40400790063935a11afa28a;
    address public fxRootTunnel = 0xB7712bEb0E4e9bA950fcfe38Fb66e33eEb35Fd3C;

    address public msgSender;
    address public txOrigin;
    bool public msgSenderIsTxOrigin;
    
    event MsgSender(address indexed msgSender);
    event TxOrigin(address indexed txOrigin);
    event MsgSenderIsTxOrigin(bool indexed _msgSenderIsTxOrigin);

    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");

        msgSender = msg.sender;
        txOrigin = tx.origin;
        msgSenderIsTxOrigin = msg.sender == tx.origin;

        emit MsgSender(msg.sender);
        emit TxOrigin(tx.origin);
        emit MsgSenderIsTxOrigin(msg.sender == tx.origin);
    }

}