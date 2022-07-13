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
    mapping(uint256 => uint256) public auctionTimestampFinished;
    mapping(uint256 => uint256) public auctionTimestampStarted;
    mapping(uint256 => uint256) public currentPriceMapping;
    mapping(uint256 => address) public currentAddress;
    mapping(uint256 => uint256) public auctionToTokenId;
    mapping(uint256 => uint256) public tokenToAuctionId;
    mapping(uint256 => uint256) public startPrice;
    mapping(uint256 => address) public winnerAddress;
    uint256 public totalAuctions;
    ERC20 public WeirdToken = ERC20(0xcB8BCDb991B45bF5D78000a0b5C0A6686cE43790);
    ERC721 public EWP = ERC721(0x4571038F92F02bD812fA05Eb6260483a7614a05D);
    address public auctionStarter;
    uint256 public finalCooldown = 0;

    constructor(address _auctionStarter) {
        auctionStarter = _auctionStarter;
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
        currentPriceMapping[tokenId] = minPrice;
        startPrice[tokenId] = minPrice;
        currentAddress[tokenId] = auctionStarter;
        auctionTimestampFinished[totalAuctions] = endTimestamp;
        auctionTimestampStarted[totalAuctions] = startTimestamp;

        EWP.safeTransferFrom(msg.sender, address(this), tokenId);
        auctionToTokenId[totalAuctions] = tokenId;
        tokenToAuctionId[tokenId] = totalAuctions;
        totalAuctions++;
    }

    function cancelAuction(uint256 tokenId) public {
        require(msg.sender == auctionStarter);

        currentPriceMapping[tokenId] = 0;
        startPrice[tokenId] = 0;
        currentAddress[tokenId] = address(0);
        auctionTimestampStarted[auctionToTokenId[tokenId]] = 0;
        auctionTimestampFinished[auctionToTokenId[tokenId]] = 0;
        tokenToAuctionId[tokenId] = 0;

        EWP.transferFrom(address(this), auctionStarter, tokenId);
    }

    function bid(uint256 tokenId, uint256 amount) public {
        require(block.timestamp > auctionTimestampStarted[tokenToAuctionId[tokenId]], "Auction not yet started");
        require(block.timestamp < auctionTimestampFinished[tokenToAuctionId[tokenId]], "Auction already finished");
        require(currentPrice(tokenId) < amount, "Bid underpriced");
        require(amount >= currentPrice(tokenId) + 1*10^18);

        if(block.timestamp + finalCooldown > auctionTimestampFinished[tokenToAuctionId[tokenId]]) {
            auctionTimestampFinished[tokenToAuctionId[tokenId]] = block.timestamp + finalCooldown;
        }

        if(currentAddress[tokenId] != auctionStarter) {
            WeirdToken.transfer(currentAddress[tokenId], currentPrice(tokenId));
        }

        WeirdToken.transferFrom(msg.sender, address(this), amount);

        currentPriceMapping[tokenId] = amount;
        currentAddress[tokenId] = msg.sender;
    }

    function finalize(uint256 tokenId) public {
        require(block.timestamp >= auctionTimestampFinished[tokenToAuctionId[tokenId]], "Auction not yet finished");
        EWP.safeTransferFrom(address(this), currentAddress[tokenId], tokenId);
        WeirdToken.transfer(0x000000000000000000000000000000000000dEaD, currentPrice(tokenId));
        winnerAddress[tokenId] = currentAddress[tokenId];
    }

    function getAllLiveAuctions() public view returns (uint256[] memory) {
        uint256 totalOpenAuctions = 0;
        for (uint256 i = 0; i < totalAuctions; i++) {
            if(auctionTimestampStarted[i] <= block.timestamp && auctionTimestampFinished[i] >= block.timestamp) {
                totalOpenAuctions++;
            }
        }

        uint256[] memory tokenIds = new uint256[](totalOpenAuctions);
        uint256 index = 0;
        for (uint256 i = 0; i < totalAuctions; i++) {
            if(auctionTimestampStarted[i] <= block.timestamp && auctionTimestampFinished[i] >= block.timestamp) {
                tokenIds[index] = auctionToTokenId[i];
                index++;
            }
        }
        return tokenIds;
    }

    function totalLiveAuctions() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < totalAuctions; i++) {
            if(auctionTimestampStarted[i] <= block.timestamp && auctionTimestampFinished[i] >= block.timestamp) {
                total++;
            }
        }
        return total;
    }

    function upcomingAuctions() public view returns (uint256[] memory) {
        uint256 totalUpcomingAuctions = 0;
        for (uint256 i = 0; i < totalAuctions; i++) {
            if(auctionTimestampStarted[i] >= block.timestamp) {
                totalUpcomingAuctions++;
            }
        }

        uint256[] memory tokenIds = new uint256[](totalUpcomingAuctions);
        uint256 index = 0;
        for (uint256 i = 0; i < totalAuctions; i++) {
            if(auctionTimestampStarted[i] >= block.timestamp) {
                tokenIds[index] = auctionToTokenId[i];
                index++;
            }
        }
        return tokenIds;
    }

    function previousAuctions() public view returns (uint256[] memory) {
        uint256 totalFinishedAuctions = 0;
        for (uint256 i = 0; i < totalAuctions; i++) {
            if(auctionTimestampFinished[i] <= block.timestamp) {
                if(winnerAddress[auctionToTokenId[i]] != address(0)) {
                    totalFinishedAuctions++;
                }
            }
        }

        uint256[] memory tokenIds = new uint256[](totalFinishedAuctions);
        uint256 index = 0;
        for (uint256 i = 0; i < totalAuctions; i++) {
            if(auctionTimestampFinished[i] <= block.timestamp) {
                if(winnerAddress[auctionToTokenId[i]] != address(0)) {
                    totalFinishedAuctions++;
                    tokenIds[index] = auctionToTokenId[i];
                    index++;
                }
            }
        }
        return tokenIds;
    }

    function currentPrice(uint256 tokenId) public view returns(uint256) {
        if(currentPriceMapping[tokenId] == startPrice[tokenId]) {
            return startPrice[tokenId] - 1*10^18;
        } else {
            return currentPriceMapping[tokenId];
        }
    }

    function timestampStarted(uint256 tokenId) public view returns(uint256) {
        return auctionTimestampStarted[tokenToAuctionId[tokenId]];
    }

    function timestampFinished(uint256 tokenId) public view returns(uint256) {
        return auctionTimestampFinished[tokenToAuctionId[tokenId]];
    }

    function setFinalCooldown(uint256 time) public onlyOwner {
        finalCooldown = time;
    }

    function setAuctionStarter(address _auctionStarter) public onlyOwner {
        auctionStarter = _auctionStarter;
    }
}