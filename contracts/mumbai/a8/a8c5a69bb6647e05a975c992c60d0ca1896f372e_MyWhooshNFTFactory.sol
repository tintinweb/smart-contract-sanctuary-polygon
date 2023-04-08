/**
 *Submitted for verification at polygonscan.com on 2023-04-07
*/

/**
 *Submitted for verification at polygonscan.com on 2023-04-07
*/

/**
 *Submitted for verification at polygonscan.com on 2023-03-30
*/

// SPDX-License-Identifier: MIT
// Author: BazzMeo
pragma solidity ^0.8.4;


/* MyWhoosh NFT Factory
    Create new MyWhoosh NFT collection
*/
contract MyWhooshNFTFactory {
    // owner address => nft list
    mapping(address => address[]) private nfts;
    // nft address => bool (existence)
    mapping(address => bool) private MyWhooshNFT;
    // nft address => Royality Recipient Address 
    mapping (address => address) private recipient ;
    // nft address => Amount of Royalty 
    mapping (address => uint256) private royalty ;

    event CreatedNFTCollection(
        address creator,
        address nft,
        string name,
        uint256 createdTime,
        address royaltyRecipient,
        uint256 royaltyTotal
    );

    function createNFTCollection(
        string memory _name,
        address nft,
        address _royaltyRecipient,
        uint256 _royaltyTotal

    
    ) public {
        nfts[msg.sender].push(nft);
        MyWhooshNFT[nft] = true;
        recipient[nft] = _royaltyRecipient;
        royalty[nft]=_royaltyTotal;
        emit CreatedNFTCollection(msg.sender, nft, _name, block.timestamp,_royaltyRecipient,_royaltyTotal);
    }

    function getOwnCollections() external view returns (address[] memory) {
        return nfts[msg.sender];
    }

    function isMyWhooshNFT(address _nft) external view returns (bool) {
        return MyWhooshNFT[_nft];
    }

    function getMyWhooshNFTRoyality(address _nft) external view returns (uint256)
    {
        return royalty[_nft];
    }
    function getMyWhooshNFTRoyalityRecipient(address _nft)external view returns(address)
    {
        return recipient[_nft];
    }
}