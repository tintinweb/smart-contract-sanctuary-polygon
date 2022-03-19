/**
 *Submitted for verification at polygonscan.com on 2022-03-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

    //Interface
interface IERC1155 {
        function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;        
        function isApprovedForAll(address account, address operator) external view returns (bool);
        function setApprovalForAll(address operator, bool approved) external;        
        }

interface IERC721{    
    function safeTransferFrom(address from, address to, uint256 tokenId) external;    
    function approve(address to, uint256 tokenId) external;     
    function getApproved(uint256 tokenId) external view returns (address operator);     
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    }

contract Airdrop {

//airdrop1155
function doAirdrop1155 (IERC1155 tokenAddress, address[] calldata recipients, uint256[] calldata tokenId, uint256[] calldata amount ) public {
require(
            recipients.length == tokenId.length &&
                recipients.length == amount.length,
            "Recipients and Ids must be same amount"
        );
for(uint i = 0; i < recipients.length; i++){
    tokenAddress.safeTransferFrom(msg.sender, recipients[i], tokenId[i], amount[i], "");
        }
    }

//airdrop721
function doAirdrop721(IERC721 tokenAddress, address[] calldata recipients, uint256[] calldata tokenId) public {
    require(recipients.length == tokenId.length, "Recipients and Id must be same length");
    for(uint256 i = 0; i < recipients.length; i++ ){
        tokenAddress.safeTransferFrom(msg.sender, recipients[i], tokenId[i]);
    }
}

}