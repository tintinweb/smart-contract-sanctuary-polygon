/**
 *Submitted for verification at polygonscan.com on 2022-11-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Exercise4 {

    address private owner;
    address private signer1;
    address private signer2;
    address private destinationAddress;
    bool private signed1 = false;
    bool private signed2 = false;

    // signer1 = 0xF12B4dAb269496016Fee2373e97b90473e589364 --> @JoanbaDK12
    // signer2 = 0x8Ab4d89CA5564D828Af77b32628761d6CD20CBCf --> @Level Ledger
    constructor (address _signer1, address _signer2) {
        owner = msg.sender;
        destinationAddress = msg.sender;
        if (_signer1 == _signer2 || _signer1 == owner || _signer1 == destinationAddress) {
            revert();
        }
        signer1 = _signer1;
        if (_signer2 == _signer1 || _signer1 == owner || _signer1 == destinationAddress) {
            revert();
        }
        signer2 = _signer2;
    }

    modifier mustBeASigner() {
        if (msg.sender != signer1 && msg.sender != signer2) {
            revert();
        }
        _;
    }

    modifier signedWallet() {
        if (!signed1 || !signed2) {
            revert();
        }
        _;
    }

    function wallet() external payable {}

    function sign() external  mustBeASigner {
        if (msg.sender == signer1) {
            signed1 = true;
        }
        if (msg.sender == signer2) {
            signed2 = true;
        }
    }

    function withdraw() external signedWallet {
        address payable to = payable (owner);
        bool success = to.send(address(this).balance);
        if (!success) {
            revert();
        }
    }
}