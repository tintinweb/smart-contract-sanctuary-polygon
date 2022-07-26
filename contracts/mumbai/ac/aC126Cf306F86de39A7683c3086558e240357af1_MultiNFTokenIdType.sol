// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Collection of functions related to uint256 used as token identifiers
 */
 /// @custom:oz-upgrades-unsafe-allow external-library-linking
library MultiNFTokenIdType {
    /**
     * Use the upper 128 bits to store the type-id
     */
    uint256 private constant TYPEID_MASK = uint256(type(uint128).max) << 128;
    /**
     * Use the lower 128 bits to store the index
     */
    uint256 private constant NFT_INDEX_MASK = type(uint128).max;

    /**
     * @dev Returns true if the token id only has token-type information.
     */
    function isNonFungibleType(uint256 id_) public pure returns (bool) {
        // A token id with only the token-type,  does not have an index.
        return (id_ & NFT_INDEX_MASK == 0);
    }

    /**
     * @dev Returns true if the token id represents the nf token and also has non-fungible index in the lower 128 bits.
     */
    function isNonFungibleItem(uint256 id_) public pure returns (bool) {
        // token id has the type and index both.
        return (id_ & NFT_INDEX_MASK != 0);
    }

    /**
     * @dev Returns the lower 128 bits of the token id as the non-fungible index for the non-fungible token.
     */
    function getNonFungibleIndex(uint256 id_) public pure returns (uint128) {
        return uint128((id_ & NFT_INDEX_MASK) >> 128);
    }

    /**
     * @dev Returns the upper 128 bits of the token id as the token-type for the non-fungible token.
     */
    function getNonFungibleType(uint256 id_) public pure returns (uint128) {
        return uint128((id_ & TYPEID_MASK) >> 128);
    }

    /**
     * @dev Returns the tokenType value expanded to uint256
     */
    function toNonFungibleType256(uint128 tokenType_)
        public
        pure
        returns (uint256)
    {
        // move token-type to upper-128 bits
        return uint256(uint128(tokenType_)) << 128;
    }

    /**
     * @dev Returns the token-index value expanded to uint256
     */
    function toNonFungibleIndex256(uint128 tokenIndex_)
        public
        pure
        returns (uint256)
    {
        // conversion to higher types adds padding bits to left
        // so we are good with the default conversion where lower-128 bits will have token index
        return uint256(tokenIndex_);
    }

    function generateTokenIdFromTokenType128(
        uint128 tokenType_,
        uint128 tokenIndex_
    ) public pure returns (uint256 id) {
        id = (uint256(uint128(tokenType_)) << 128) | uint128(tokenIndex_);
    }

    function generateTokenIdFromTokenType256(
        uint256 tokenType_,
        uint128 tokenIndex_
    ) public pure returns (uint256 id) {
        id = (tokenType_ & TYPEID_MASK) | uint128(tokenIndex_);
    }
}