/**
 *Submitted for verification at polygonscan.com on 2022-05-25
*/

pragma solidity >= 0.7.0 < 0.9.0;

// SPDX-License-Identifier: MIT

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract BulkAirdrop {

    constructor () {}

    function airdrop_erc721(IERC721 _token, address[] calldata _to, uint256[] calldata _id) public {

        require(_to.length == _id.length);
        for (uint256 i = 0; i < _id.length; i++) {
            _token.safeTransferFrom(msg.sender, _to[i], _id[i]);
        }

    }



}