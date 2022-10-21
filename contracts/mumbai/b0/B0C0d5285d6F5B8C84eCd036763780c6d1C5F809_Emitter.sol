/**
 *Submitted for verification at polygonscan.com on 2022-05-31
 */

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract Emitter {
    bytes32 private eip712DomainHash;
    struct Order {
        address collection; // NFT contract address
        uint256 tokenId; // order for which tokenId of the collection
        address signer; // maker of order address
        uint256 orderType; // 0 if selling nft for eth , 1 if offering weth for nft,2 if offering weth for collection with special criteria root
        uint256 totalAmt; // price value of the trade // total amt maker is willing to give up per unit of amount
        Payment exchange; // payment agreed by maker of the order to pay on succesful filling of trade this amt is subtracted from totalamt
        Payment prePayment; // another payment , can be used for royalty, facilating trades
        bool isERC721; // standard of the collection , if 721 then true , if 1155 then false
        uint256 tokenAmt; // token amt useful if standard is 1155 if >1 means whole order can be filled tokenAmt times
        uint256 refererrAmt; // amt to pay to the address that helps in filling your order
        bytes32 root; // A merkle root derived from each valid tokenId — set to 0 to indicate a collection-level or tokenId-specific order.
        address reservedAddress; // if not address(0) , only this address can fill the order
        uint256 nonce; // nonce of order usefull for cancelling in bulk
        uint256 deadline; // timestamp till order is valid epoch timestamp in secs
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    event NewOrder(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed signer,
        uint256 orderType,
        uint256 totalAmt,
        Payment exchange,
        Payment prePayment,
        bool isERC721,
        uint256 tokenAmt,
        uint256 refererrAmt,
        bytes32 root,
        address reservedAddress,
        uint256 nonce,
        uint256 deadline,
        Signature sig
    );

    struct Payment {
        uint256 paymentAmt;
        address paymentAddress;
    }

    struct Amounts {
        uint256 totalAmt;
        uint256 tokenAmt;
        uint256 refererrAmt;
    }

    constructor(address _golomTrader) {
        eip712DomainHash = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes('GOLOM.IO')),
                keccak256(bytes('1')),
                5,
                _golomTrader
            )
        );
    }

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    // uint256 exchangeAmt,
    // address exchangeAddress,
    // uint256 prePaymentAmt,
    // address prePaymentAaddress,

    function hashPayment(Payment calldata p) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256('payment(uint256 paymentAmt,address paymentAddress)'),
                    p.paymentAmt,
                    p.paymentAddress
                )
            );
    }

    function hashOrder(Order calldata o) private pure returns (bytes32) {
        return _hashOrderinternal(o, [o.nonce, o.deadline]);
    }

    function _hashOrderinternal(Order calldata o, uint256[2] memory extra) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        'order(address collection,uint256 tokenId,address signer,uint256 orderType,uint256 totalAmt,payment exchange,payment prePayment,bool isERC721,uint256 tokenAmt,uint256 refererrAmt,bytes32 root,address reservedAddress,uint256 nonce,uint256 deadline)payment(uint256 paymentAmt,address paymentAddress)'
                    ),
                    o.collection,
                    o.tokenId,
                    o.signer,
                    o.orderType,
                    o.totalAmt,
                    hashPayment(o.exchange),
                    hashPayment(o.prePayment),
                    o.isERC721,
                    o.tokenAmt,
                    o.refererrAmt,
                    o.root,
                    o.reservedAddress,
                    extra
                )
            );
    }

    function pushOrder(Order calldata o) public {
        {
            bytes32 hashStruct = hashOrder(o);
            bytes32 hash = keccak256(abi.encodePacked('\x19\x01', eip712DomainHash, hashStruct));
            address signatureSigner = ecrecover(hash, o.v, o.r, o.s);

            require(signatureSigner == o.signer, 'invalid signature');
        }

        Signature memory sig = Signature(o.v, o.r, o.s);

        emitOrder(o, sig);
    }

    function emitOrder(Order calldata o, Signature memory sig) internal {
        emit NewOrder(
            o.collection,
            o.tokenId,
            o.signer,
            o.orderType,
            o.totalAmt,
            o.exchange,
            o.prePayment,
            o.isERC721,
            o.tokenAmt,
            o.refererrAmt,
            o.root,
            o.reservedAddress,
            o.nonce,
            o.deadline,
            sig
        );
    }
}