/**
 *Submitted for verification at polygonscan.com on 2022-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract Emitter {
    bytes32 private eip712DomainHash;
    struct Order {
        address collection;
        uint256 tokenId;
        address signer;
        bool isAsk;
        uint256 totalAmt;
        Payment exchange;
        Payment prePayment;
        bool isERC721;
        uint256 tokenAmt;
        uint256 refererrAmt;
        address reservedAddress;
        uint256 nonce;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
    struct Payment {
        uint256 paymentAmt;
        address paymentAddress;
    }

    constructor() {
        eip712DomainHash = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes('GOLOM.IO')),
                keccak256(bytes('1')),
                1,
                address(this)
            )
        );
    }

    event NewOrder(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed signer,
        bool isAsk,
        uint256 totalAmt,
        uint256 exchangeAmt,
        address exchangeAddress,
        uint256 prePaymentAmt,
        address prePaymentAaddress,
        bool isERC721,
        uint256 tokenAmt,
        uint256 refererrAmt,
        uint256 nonce,
        uint256 deadline
    );

    function hashPayment(Payment memory p) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256('payment(uint256 paymentAmt,address paymentAddress)'),
                    p.paymentAmt,
                    p.paymentAddress
                )
            );
    }

    function hashOrder(Order memory o) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        'order(address collection,uint256 tokenId,address signer,bool isAsk,uint256 totalAmt,payment exchange,payment prePayment,bool isERC721,uint256 tokenAmt,uint256 refererrAmt,address reservedAddress,uint256 nonce,uint256 deadline)payment(uint256 paymentAmt,address paymentAddress)'
                    ),
                    o.collection,
                    o.tokenId,
                    o.signer,
                    o.isAsk,
                    o.totalAmt,
                    hashPayment(o.exchange),
                    hashPayment(o.prePayment),
                    o.isERC721,
                    o.tokenAmt,
                    o.refererrAmt,
                    o.reservedAddress,
                    o.nonce,
                    o.deadline
                )
            );
    }

    function emitOrder(Order memory o) internal {
        emit NewOrder(
            o.collection,
            o.tokenId,
            o.signer,
            o.isAsk,
            o.totalAmt,
            o.exchange.paymentAmt,
            o.exchange.paymentAddress,
            o.prePayment.paymentAmt,
            o.prePayment.paymentAddress,
            o.isERC721,
            o.tokenAmt,
            o.refererrAmt,
            o.nonce,
            o.deadline
        );
    }

    function encodeOrder(Order memory o) internal pure returns (bytes memory) {
        return
            abi.encode(
                o.isAsk,
                o.totalAmt,
                o.exchange.paymentAmt,
                o.exchange.paymentAddress,
                o.prePayment.paymentAmt,
                o.prePayment.paymentAddress,
                o.isERC721,
                o.tokenAmt,
                o.refererrAmt,
                o.nonce,
                o.deadline
            );
    }

    function pushOrder(Order memory o) public {
        {
            bytes32 hashStruct = hashOrder(o);
            bytes32 hash = keccak256(abi.encodePacked('\x19\x01', eip712DomainHash, hashStruct));
            address signaturesigner = ecrecover(hash, o.v, o.r, o.s);
            require(signaturesigner == o.signer, 'invalid signature');
        }
        emitOrder(o);
    }
}