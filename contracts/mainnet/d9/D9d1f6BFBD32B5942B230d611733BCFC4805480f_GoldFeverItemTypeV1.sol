//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;
import {IGoldFeverItemType} from "./interfaces/IGoldFeverItemType.sol";

contract GoldFeverItemTypeV1 is IGoldFeverItemType {
    function getItemType(uint256 itemId)
        external
        pure
        override
        returns (uint256 typeId)
    {
        if (itemId & ((1 << 4) - 1) == 1) {
            // Version 1
            typeId = (itemId >> 4) & ((1 << 20) - 1);
        }
    }

    function createItemId(uint256 counter, uint256 typeId)
        external
        pure
        override
        returns (uint256 itemId)
    {
        itemId = (counter << 24) + ((typeId << 4) + 1);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IGoldFeverItemType {
    function getItemType(uint256 itemId) external view returns (uint256 typeId);

    function createItemId(uint256 counter, uint256 typeId)
        external
        view
        returns (uint256 itemId);
}