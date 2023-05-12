// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {KomonERC1155} from "KomonERC1155.sol";
import {Modifiers} from "Modifiers.sol";

contract CreatorSpaceFacet202 is KomonERC1155, Modifiers {
    function mintInternalKey(uint256 amount) external onlyKomonWeb {
        require(amount > 0, "You have to mint at least 1 token.");
        _mintInternalKey(amount);
    }
}