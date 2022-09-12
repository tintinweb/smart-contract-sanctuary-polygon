/**
 *Submitted for verification at polygonscan.com on 2022-09-11
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.1;

interface IERC721 {
    function safeTransferFrom(address from, address to, uint tokenId) external;
}


contract Exchange {


    function myTransfer( address nftContractAddress, address to, uint tokenId) external payable {
        IERC721(nftContractAddress).safeTransferFrom(msg.sender, to, tokenId);
    }


}