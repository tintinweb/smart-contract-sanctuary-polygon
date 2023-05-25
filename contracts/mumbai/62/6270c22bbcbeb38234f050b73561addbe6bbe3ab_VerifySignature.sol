/**
 *Submitted for verification at polygonscan.com on 2023-05-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract VerifySignature {
    enum BuyingAssetType {
        ERC1155,
        ERC721
    }

    mapping (address=>Order) orders;

    struct Order {
        address seller;
        address buyer;
        address erc20Address;
        address nftAddress;
        BuyingAssetType nftType;
        uint256 unitPrice;
        bool skipRoyalty;
        uint256 amount;
        uint256 tokenId;
        // string tokenURI;
        uint256 supply;
        uint96 royaltyFee;
        uint256 qty;
        uint256 endDate;
        bytes sellerOrdersignature;
        bytes buyerOrdersignature;
    }

    function validateOrder(Order calldata order) public returns (bool) {
        bytes32 sellerOrderhash = getOrderSellerHash(order);
        bytes32 sellerOrderhashMessage=prefixed(sellerOrderhash);

        require(order.seller == recoverSigner(sellerOrderhashMessage,order.sellerOrdersignature),"Invalid order");

        orders[msg.sender]=order;
        
        return true;
    }

    function getOrderSellerHash(
        Order calldata order
    ) public pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                order.seller,
                order.erc20Address,
                order.nftAddress,
                order.nftType,
                order.unitPrice,
                order.skipRoyalty,
                order.tokenId,
                order.supply,
                order.royaltyFee,
                order.endDate
            )
        );
    }

    function prefixed(bytes32 _messageHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function recoverSigner(
        bytes32 _signedMessageHash,
        bytes memory _signature
    ) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_signedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

}