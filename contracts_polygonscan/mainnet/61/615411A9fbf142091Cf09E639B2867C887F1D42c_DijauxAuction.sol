// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DijauxFunctions.sol";
import "./ERC721HolderUpgradeable.sol";

contract DijauxAuction is DijauxFunctions, ERC721HolderUpgradeable {

    struct Auction {
        address seller;
        uint256 auction_endtime;
        uint256 auction_highestbid;
        address auction_highestbidder;
    }

    uint256 public totalHoldings;
    uint256[] public tokenIdToIndexArray;
    mapping(uint256 => Auction) public tokenIdToAuction;
    mapping(uint256 => uint256) public tokenIdToIndex;

    function GettokenIdToIndex() external view returns (uint256[] memory) {
        return tokenIdToIndexArray;
    }

    function CreateAuction(
        uint128 _tokenId,
        uint256 _endTime
    ) public payable {
        require(msg.sender == ERC721Upgradeable(address(this)).ownerOf(_tokenId),"not owner");
        require(_endTime >= block.timestamp,"time invalid");
        ERC721Upgradeable(address(this)).safeTransferFrom(msg.sender, address(this), _tokenId);
        Auction memory auction =
        Auction({
            seller: msg.sender,
            auction_endtime: _endTime,
            auction_highestbid: 0,
            auction_highestbidder: address(0)
        });
        tokenIdToAuction[_tokenId] = auction;
        tokenIdToIndexArray.push(_tokenId);
        tokenIdToIndex[_tokenId] = totalHoldings;
        totalHoldings++;
    }

    function PlaceBid(uint256 _tokenId) public payable {
        Auction memory auction = tokenIdToAuction[_tokenId];
        require(block.timestamp <= auction.auction_endtime, "times up");
        require(msg.value > auction.auction_highestbid, "less price");

        if (msg.value > auction.auction_highestbid) { 
            payable(auction.auction_highestbidder).transfer(auction.auction_highestbid);
            tokenIdToAuction[_tokenId].auction_highestbid = msg.value;
            tokenIdToAuction[_tokenId].auction_highestbidder = msg.sender;
        }
    }

    function FinalizedAuction(uint256 _tokenId, uint256 _charge) public payable {
        Auction memory auction = tokenIdToAuction[_tokenId];
        DijauxPiece memory dijauxpiecemem = allDijauxPieces[_tokenId];
        require(msg.sender == auction.seller,"not seller");
        
        if(auction.auction_highestbidder != address(0)) {
            uint256 ChargeGoesToCreator = ((auction.auction_highestbid - ((auction.auction_highestbid * _charge) / 100)) * dijauxpiecemem.royalties) / 100;
            uint256 finalValuePrice = (auction.auction_highestbid - ((auction.auction_highestbid * _charge) / 100)) - ChargeGoesToCreator;
            payable(0x01a9223C008F5e86a54776c00BAB58141dD8D008).transfer(((auction.auction_highestbid * _charge) / 100) / 2);
            payable(0xb81593939decf7F053c9Dc9bc69BFB8E2A90E9eB).transfer(((auction.auction_highestbid * _charge) / 100) / 2);
            payable(dijauxpiecemem.creator).transfer(ChargeGoesToCreator);
            payable(msg.sender).transfer(finalValuePrice);
            ERC721Upgradeable(address(this)).safeTransferFrom(address(this), auction.auction_highestbidder , _tokenId);
            dijauxpiecemem.price = auction.auction_highestbid;
        }else {
            ERC721Upgradeable(address(this)).safeTransferFrom(address(this), msg.sender , _tokenId);
        }
        dijauxpiecemem.forsale = false;
        allDijauxPieces[_tokenId] = dijauxpiecemem;
        delete tokenIdToAuction[_tokenId];
        delete tokenIdToIndexArray[tokenIdToIndex[_tokenId]];
        delete tokenIdToIndex[_tokenId];
    }

}