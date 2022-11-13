/**
 *Submitted for verification at polygonscan.com on 2022-11-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract multiSig {
    address public owner;
    address public receiver;
    address public sig1;
    bool public signedSig1 = false;
    address public sig2;
    bool public signedSig2 = false; 

    constructor(address _sig1, address _sig2, address _receiver) {
        owner = msg.sender;
        require((_sig1 != owner && _sig2 != owner) && (_sig1 != _receiver && _sig2 != _receiver),"signers are not allowed to be owner or receiver");
        sig1 = _sig1;
        sig2 = _sig2;
        receiver = _receiver;
    }

    modifier isOwner() {
        require(msg.sender == owner,"you are not the owner");
        _;
    }
    function receptor() external payable {}

    function sendMoney(uint256 withdraw) external isOwner {
        if (signedSig1 && signedSig2) {
            require(address(this). balance > withdraw,"not enough funds");
            (bool success,) = receiver.call{value : withdraw}("");
		    require(success, "fallo envio");
            signedSig1 = false;
            signedSig2 = false;  
        } else revert("need authorized signatures");
    }

    function sign() external {
        if (msg.sender == sig1) {
            signedSig1 = true;
        } else if (msg.sender == sig2) {
            signedSig2 = true;
            }
            else revert("you are not a valid signer");
    }
}