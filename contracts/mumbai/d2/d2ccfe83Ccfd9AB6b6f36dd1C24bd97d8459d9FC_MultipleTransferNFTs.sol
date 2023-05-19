/**
 *Submitted for verification at polygonscan.com on 2023-05-18
*/

//SPDX-License-Identifier: Unlicense
/*
░██████╗██████╗░███████╗███████╗██████╗░░░░░░░░██████╗████████╗░█████╗░██████╗░
██╔════╝██╔══██╗██╔════╝██╔════╝██╔══██╗░░░░░░██╔════╝╚══██╔══╝██╔══██╗██╔══██╗
╚█████╗░██████╔╝█████╗░░█████╗░░██║░░██║█████╗╚█████╗░░░░██║░░░███████║██████╔╝
░╚═══██╗██╔═══╝░██╔══╝░░██╔══╝░░██║░░██║╚════╝░╚═══██╗░░░██║░░░██╔══██║██╔══██╗
██████╔╝██║░░░░░███████╗███████╗██████╔╝░░░░░░██████╔╝░░░██║░░░██║░░██║██║░░██║
╚═════╝░╚═╝░░░░░╚══════╝╚══════╝╚═════╝░░░░░░░╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝
*/
pragma solidity 0.8.11;

interface INFT {
    function getPopularity(uint256 _tokenId) external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function setApprovalForAll(address operator, bool _approved) external;
}

contract MultipleTransferNFTs{
    function transfer(uint256[] memory _tokenIds,address _nftAddress,address _receiver) public{
         for (uint256 index = 0; index < _tokenIds.length; index++) {
                INFT(_nftAddress).transferFrom(msg.sender,_receiver,_tokenIds[index]);
         }
    }
}