/**
 *Submitted for verification at polygonscan.com on 2022-07-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.5.0;

contract Verifier {
    uint256 constant chainId =80001;
    address constant verifyingContract = 0x1C56346CD2A2Bf3202F771f50d3D14a367B48070;
    bytes32 constant salt = 0xf2d857f4a3edcb9b78b4d503bfe733db1e3f6cdc2b7971ee739626c97e86a558;

    string private constant EIP712_DOMAIN  = "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)";
    string private constant IDENTITY_TYPE = "Identity(uint256 userId,address wallet)";
    string private constant BID_TYPE = "Bid(uint256 amount,Identity bidder)Identity(uint256 userId,address wallet)";

    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256(abi.encodePacked(EIP712_DOMAIN));
    bytes32 private constant IDENTITY_TYPEHASH = keccak256(abi.encodePacked(IDENTITY_TYPE));
    bytes32 private constant BID_TYPEHASH = keccak256(abi.encodePacked(BID_TYPE));
    bytes32 private constant DOMAIN_SEPARATOR = keccak256(abi.encode(
        EIP712_DOMAIN_TYPEHASH,
        keccak256("My amazing dApp"),
        keccak256("2"),
        chainId,
        verifyingContract,
        salt
    ));

    struct Identity {
        uint256 userId;
        address wallet;
    }

    struct Bid {
        uint256 amount;
        Identity bidder;
    }

    function hashIdentity(Identity memory identity) private pure returns (bytes32) {
        return keccak256(abi.encode(
            IDENTITY_TYPEHASH,
            identity.userId,
            identity.wallet
        ));
    }

    function hashBid(Bid memory bid) private pure returns (bytes32){
        return keccak256(abi.encodePacked(
            "\\x19\\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(
                BID_TYPEHASH,
                bid.amount,
                hashIdentity(bid.bidder)
            ))
        ));
    }

    function verify() public pure returns (bool) {
        Identity memory bidder = Identity({
            userId: 323,
            wallet: 0x3333333333333333333333333333333333333333
        });

        Bid memory bid = Bid({
            amount: 100,
            bidder: bidder
        });

        bytes32 sigR = 0x3c46a0265169a3e11d860d6a1d657e566864da5891d15a9baebfa021346dac71;
        bytes32 sigS = 0x7b465208debddc58fbad71a37faaaf66223eae680719d864b6495b17f1526c1c;
        uint8 sigV = 27;
        address signer = 0xAC1e2722F7CCb1B990Cbe11Ff294922663481A51;

        return signer == ecrecover(hashBid(bid), sigV, sigR, sigS);
    }
}