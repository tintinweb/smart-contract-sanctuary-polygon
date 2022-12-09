/**
 *Submitted for verification at polygonscan.com on 2022-12-08
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.7;

contract CryptoPenguin {
    struct Collectible {
        address tokenContract;
        string tokenId;
        string title;
        string imageUrl;
        string collectionName;
        string network;
    }

    mapping(address => Collectible[]) internal collectors;

    function removeFromCollectors(uint index) internal {
        require(index < collectors[msg.sender].length);
        collectors[msg.sender][index] = collectors[msg.sender][collectors[msg.sender].length-1];
        collectors[msg.sender].pop();
    }

    function compareTokenIds(string memory token1, string memory token2) private pure returns(bool) {
        return keccak256(abi.encodePacked(token1)) == keccak256(abi.encodePacked(token2));
    }

    function addToCollection(address tokenContract, string memory tokenId, string memory title, string memory imageUrl, string memory collectionName, string memory network) public {
        Collectible memory c = Collectible({ tokenContract: tokenContract, tokenId: tokenId, title: title, imageUrl: imageUrl, collectionName: collectionName, network: network });
        collectors[msg.sender].push(c);
    }

    function removeFromCollection(address tokenContract, string memory tokenId) public {
        Collectible[] memory collectibles = collectors[msg.sender];
        bool hasDeleted = false;

        for (uint i = 0; i < collectibles.length; i++) {
            if (collectibles[i].tokenContract == tokenContract && compareTokenIds(collectibles[i].tokenId, tokenId)) {
                removeFromCollectors(i);
                hasDeleted = true;
                return;
            }
        }

        require(hasDeleted, "No data was found");
    }

    function getCollectibles() public view returns (Collectible[] memory) {
        return collectors[msg.sender];
    }
}