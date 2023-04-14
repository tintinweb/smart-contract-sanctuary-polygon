/**
 *Submitted for verification at polygonscan.com on 2023-04-14
*/

// Sources flattened with hardhat v2.13.1 https://hardhat.org

// File contracts/ContractExchange.sol

//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.1;

interface IERC721{
    function safeTransferFrom(address from, address to, uint tokenId) external;
}

contract ContractExchange {
    

    function myTransfer(address nftContractAddress, address to, uint tokenId) external payable {
            IERC721(nftContractAddress).safeTransferFrom(msg.sender, to, tokenId);
    }
    
    

}