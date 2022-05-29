/**
 *Submitted for verification at polygonscan.com on 2022-05-29
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.14;

interface IERC721Min {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC721Enumerable {
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

contract BatchERC721 {
    // requires approval for all
    function transferAllEnumerable(address contract_address, address to_address) external
    {
        IERC721Enumerable erc721_enumerable = IERC721Enumerable(contract_address);
        bool isApproved = erc721_enumerable.isApprovedForAll(msg.sender, address(this));
        require(isApproved);

        uint256 balance = erc721_enumerable.balanceOf(msg.sender);

        //transfer all token to this address
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = erc721_enumerable.tokenOfOwnerByIndex(msg.sender, balance - i - 1);
            erc721_enumerable.safeTransferFrom(msg.sender, to_address, tokenId);
        }
    }
    // requires approval for transferred tokens
    function transferBatch(address contract_address, address to_address, uint256[] memory tokenIds) external
    {
        IERC721Min erc721 = IERC721Min(contract_address);
        //transfer all token to this address
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            erc721.safeTransferFrom(msg.sender, to_address, tokenId);
        }
    }
}