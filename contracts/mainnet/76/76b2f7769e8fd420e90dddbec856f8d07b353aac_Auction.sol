// SPDX-License-Identifier: MIT

/*
 __    __    ___  ____  ____   ___        ____  __ __  ____   __  _  _____
|  |__|  |  /  _]|    ||    \ |   \      |    \|  |  ||    \ |  |/ ]/ ___/
|  |  |  | /  [_  |  | |  D  )|    \     |  o  )  |  ||  _  ||  ' /(   \_ 
|  |  |  ||    _] |  | |    / |  D  |    |   _/|  |  ||  |  ||    \ \__  |
|  `  '  ||   [_  |  | |    \ |     |    |  |  |  :  ||  |  ||     \/  \ |
 \      / |     | |  | |  .  \|     |    |  |  |     ||  |  ||  .  |\    |
  \_/\_/  |_____||____||__|\_||_____|    |__|   \__,_||__|__||__|\_| \___|
                                                                          
*/
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC721.sol";
import "./ERC721Holder.sol";
import "./Ownable.sol";

contract Auction is ERC721Holder, Ownable {
    mapping(uint256 => uint256) public timestampFinished;
    mapping(uint256 => uint256) public timestampStarted;
    mapping(uint256 => uint256) public currentPrice;
    mapping(uint256 => address) public currentAddress;
    mapping(uint256 => uint256) public auctionId;
    mapping(uint256 => uint256) public startPrice;
    uint256 public totalAuctions;
    ERC20 public WeirdToken;
    ERC721 public EWP;
    address public auctionStarter;

    constructor(address _auctionStarter, address _EWP, address _WeirdToken) {
        auctionStarter = _auctionStarter;
        EWP = ERC721(_EWP);
        WeirdToken = ERC20(_WeirdToken);
    }

    function batchStartAuction(uint256[] memory tokenIds, uint256[] memory startTimestamps, uint256[] memory endTimestamps, uint256[] memory minPrices) public {
        require(msg.sender == auctionStarter);
        require(tokenIds.length == startTimestamps.length && tokenIds.length == minPrices.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            startAuction(tokenIds[i], startTimestamps[i], endTimestamps[i], minPrices[i]);
        }
    }

    function startAuction(uint256 tokenId, uint256 startTimestamp, uint256 endTimestamp, uint256 minPrice) public {
        require(msg.sender == auctionStarter);
        currentPrice[tokenId] = minPrice;
        startPrice[tokenId] = minPrice;
        currentAddress[tokenId] = auctionStarter;
        timestampFinished[tokenId] = endTimestamp;
        timestampStarted[tokenId] = startTimestamp;

        EWP.safeTransferFrom(msg.sender, address(this), tokenId);
        auctionId[totalAuctions] = tokenId;
        totalAuctions++;
    }

    function cancelAuction(uint256 tokenId) public {
        require(msg.sender == auctionStarter);

        currentPrice[tokenId] = 0;
        currentAddress[tokenId] = address(0);
        timestampFinished[tokenId] = 0;
        timestampStarted[tokenId] = 0;

        EWP.transferFrom(address(this), auctionStarter, tokenId);
    }

    function bid(uint256 tokenId, uint256 amount) public {
        require(block.timestamp > timestampStarted[tokenId], "Auction not yet started");
        require(block.timestamp < timestampFinished[tokenId], "Auction already finished");
        require(currentPrice[tokenId] < amount, "Bid underpriced");

        if(block.timestamp + 600 > timestampFinished[tokenId]) {
            timestampFinished[tokenId] = block.timestamp + 600;
        }

        if(currentAddress[tokenId] != auctionStarter) {
            WeirdToken.transfer(currentAddress[tokenId], currentPrice[tokenId]);
        }

        WeirdToken.transferFrom(msg.sender, address(this), amount);

        currentPrice[tokenId] = amount;
        currentAddress[tokenId] = msg.sender;
    }

    function finalize(uint256 tokenId) public {
        require(block.timestamp >= timestampFinished[tokenId], "Auction not yet finished");
        require(currentAddress[tokenId] == msg.sender);
        EWP.safeTransferFrom(address(this), msg.sender, tokenId);
        WeirdToken.transfer(0x000000000000000000000000000000000000dEaD, currentPrice[tokenId]);
    }

    function getAllLiveAuctions() public view returns (uint256[] memory) {
        uint256 totalOpenAuctions = 0;
        for (uint256 i = 0; i < totalAuctions; i++) {
            if(timestampStarted[auctionId[i]] <= block.timestamp && timestampFinished[auctionId[i]] >= block.timestamp) {
                totalOpenAuctions++;
            }
        }

        uint256[] memory auctionIds = new uint256[](totalOpenAuctions);
        uint256 index = 0;
        for (uint256 i = 0; i < totalAuctions; i++) {
            if(timestampStarted[auctionId[i]] <= block.timestamp && timestampFinished[auctionId[i]] >= block.timestamp) {
                auctionIds[index] = auctionId[i];
                index++;
            }
        }
        return auctionIds;
    }

    function totalLiveAuctions() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < totalAuctions; i++) {
            if(timestampStarted[auctionId[i]] <= block.timestamp && timestampFinished[auctionId[i]] >= block.timestamp) {
                total++;
            }
        }
        return total;
    }

    function setAuctionStarter(address _auctionStarter) public onlyOwner {
        auctionStarter = _auctionStarter;
    }
}