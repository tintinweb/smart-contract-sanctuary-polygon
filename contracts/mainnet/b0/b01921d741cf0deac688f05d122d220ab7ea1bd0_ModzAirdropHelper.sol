// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ModzAirdropHelper {

    uint8 constant public ISSUED_ID_BITS = 216;

    mapping(uint => uint) indexes;

    function setIndex(uint tokenType, uint offset) external {
        require(msg.sender == 0xd27b09df7eFf79c0ffC0Dda228235cB3a3C4C577, "403");
        indexes[tokenType] = offset;
    }

    function airdropFrom(
        IERC721 erc721,
        uint tokenType,
        address[] calldata tos,
        uint[] calldata amounts
    ) external {
        require(msg.sender == 0xd27b09df7eFf79c0ffC0Dda228235cB3a3C4C577, "403");
        require(tos.length == amounts.length, "ERR");

        uint index = indexes[tokenType];

        for (uint i = 0; i < tos.length; i++) {
            address to = tos[i];

            for (uint j = 0; j < amounts[i]; j++) {
                index += 1;
                uint tokenId = encodeTokenId(tokenType, index);
                erc721.transferFrom(msg.sender, to, tokenId);
            }
        }
        indexes[tokenType] = index;
    }

    function encodeTokenId(uint256 _itemId, uint256 _issuedId) public pure returns (uint256 id) {
        assembly {
            id := or(shl(ISSUED_ID_BITS, _itemId), _issuedId)
        }
    }

}

interface IERC721 {

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

}