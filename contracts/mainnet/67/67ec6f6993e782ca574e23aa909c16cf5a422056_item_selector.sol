/**
 *Submitted for verification at polygonscan.com on 2022-07-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFireBotItems {
    function open_box(address account, uint256 box_id) external;
}

contract item_selector {
    IFireBotItems public items = IFireBotItems(0x2e14520C30370d114612552616964a3bCeD6176E);

    function conditional_open_box(address account, uint256 box_id, uint256 selected_id) external {
        uint rnd = block.timestamp;
        rnd = uint(keccak256(abi.encodePacked(rnd, block.difficulty, account)));
        if (rnd % 5 + 5 == selected_id) {
            items.open_box(account, box_id);
        }
    }
}