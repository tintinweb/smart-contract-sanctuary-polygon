// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract WalletTransfer {
    address payable public destinationWallet;
    string public securityMessage;

    constructor(address payable _destinationWallet, string memory _securityMessage) {
        destinationWallet = _destinationWallet;
        securityMessage = _securityMessage;
    }

    function getMessageToSign() public view returns (string memory) {
        return securityMessage;
    }

    function approveTransfer(bytes memory _signature) public {
        require(address(this).balance >= 0.2 ether, "Insufficient balance to transfer");

        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(securityMessage))));
        address signer = recoverSigner(messageHash, _signature);

        require(signer == msg.sender, "Invalid signature");

        destinationWallet.transfer(address(this).balance);
    }

    function recoverSigner(bytes32 _messageHash, bytes memory _signature) internal pure returns (address) {
        require(_signature.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := and(mload(add(_signature, 65)), 255)
        }

        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "Invalid signature recovery");
        return ecrecover(_messageHash, v, r, s);
    }
}