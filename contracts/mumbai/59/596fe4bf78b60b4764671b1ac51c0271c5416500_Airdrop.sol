/**
 *Submitted for verification at polygonscan.com on 2022-03-07
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract Airdrop {

    function airdropNFT(address _token, address[] calldata _to, uint[] calldata _id) external {

        require(_to.length == _id.length, "length not matching");

        for (uint i = 0; i < _to.length; i++) {
            IERC721(_token).safeTransferFrom(msg.sender, _to[i], _id[i]);
        }
    }
}