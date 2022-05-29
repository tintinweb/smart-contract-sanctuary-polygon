/**
 *Submitted for verification at polygonscan.com on 2022-05-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface ITroops {
    function walletOfOwner(address _owner) external view returns (uint256[] memory);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IEnumerable {
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenByIndex(uint256 index) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

contract SwapG4N9 {
    // requires this contract to be approved by the minting contract to handle all the tokens

    function transferAllTroops(address to_address) external
    {
        address troop_contract_address = 0xb195991d16c1473bdF4b122A2eD0245113fCb2F9;
        ITroops troops_contract = ITroops(troop_contract_address);

        // query for all the troops
        //check that msg.sender == owner of tokenID to be swapped
        uint256[] memory all_tokens = troops_contract.walletOfOwner(msg.sender);

        //transfer all token to this address
        for(uint256 i = 0; i< all_tokens.length; i++) {
            troops_contract.safeTransferFrom(msg.sender, to_address, uint256(all_tokens[i]));
        }        
    }
    // requires approval for all
    function transferAllEnumerable(address from_address, address to_address) external
    {
        IEnumerable erc721_enumerable = IEnumerable(from_address);
        bool isApproved = erc721_enumerable.isApprovedForAll(msg.sender, address(this));
        require(isApproved);

        uint256 balance = erc721_enumerable.balanceOf(msg.sender);

        //transfer all token to this address
        for(uint256 i = 0; i < balance; i++) {
            uint256 tokenId = erc721_enumerable.tokenOfOwnerByIndex(msg.sender, i);
            erc721_enumerable.safeTransferFrom(msg.sender, to_address, tokenId);
        }
    }
}