/**
 *Submitted for verification at polygonscan.com on 2022-09-10
*/

// Sources flattened with hardhat v2.11.1 https://hardhat.org

// File contracts/Exchange.sol

//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.1;

interface IERC721 {
    function safeTransferFrom(address from, address to, uint tokenId) external;
}

contract Exchange {
    uint transferPrice = 1000000;
    function changeTransferPrice(uint _newNumber) external {
        transferPrice = _newNumber;
    }
    function transferNFT(address nftAddress, address to, uint tokenId) external payable {
        IERC721(nftAddress).safeTransferFrom(msg.sender, to, tokenId);
    }

    function contractBalance() external view returns(uint) {
        return address(this).balance;
    }
}