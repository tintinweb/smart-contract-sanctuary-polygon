// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {KomonERC1155} from "KomonERC1155.sol";
import {Modifiers} from "Modifiers.sol";

contract CreatorSpaceFacet201 is KomonERC1155, Modifiers {
    function removeRemainedMaxSupply(uint256 tokenId, uint256 leftTokens)
        external
        onlyAdmin
    {
        _removeRemainedMaxSupply(tokenId, leftTokens);
    }
}