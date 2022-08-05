/**
 *Submitted for verification at polygonscan.com on 2022-08-05
*/

/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFireBotItems {
    function open_box(address account, uint256 box_id) external;
}

contract item_selector {
    IFireBotItems public items = IFireBotItems(0x2e14520C30370d114612552616964a3bCeD6176E);

    function open_box_wanted(address account, uint256 box_id, uint256 wanted_id) external {
        uint rnd = block.timestamp;
        rnd = uint(keccak256(abi.encodePacked(rnd, block.difficulty, address(this))));
        if (rnd % 5 + 5 == wanted_id) {
            items.open_box(account, box_id);
        }
    }

    function open_box_unwanted(address account, uint256 box_id, uint256 unwanted_id) external {
        uint rnd = block.timestamp;
        rnd = uint(keccak256(abi.encodePacked(rnd, block.difficulty, address(this))));
        if (rnd % 5 + 5 != unwanted_id) {
            items.open_box(account, box_id);
        }
    }

    function open_gold_box_wanted(address account, uint256 wanted_id, uint256 want_at_least) external {
        uint rnd = block.timestamp;
        uint256 found = 0;
        for (uint i=0; i<27; i++) {
			rnd = uint(keccak256(abi.encodePacked(rnd, block.difficulty, msg.sender)));
			if (rnd % 5 + 5 == wanted_id) {
                found++;
            }
        }
        if (found >= want_at_least) {
            items.open_box(account, 4);
        }
    }

    function open_gold_box_unwanted(address account, uint256 unwanted_id, uint256 want_at_maximum) external {
        uint rnd = block.timestamp;
        uint256 found = 0;
        for (uint i=0; i<27; i++) {
			rnd = uint(keccak256(abi.encodePacked(rnd, block.difficulty, msg.sender)));
			if (rnd % 5 + 5 == unwanted_id) {
                found++;
            }
        }
        if (found <= want_at_maximum) {
            items.open_box(account, 4);
        }
    }
}