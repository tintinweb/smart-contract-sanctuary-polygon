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
    uint256 public totalAuctions;
    ERC20 public WeirdToken;
    ERC721 public EWP;
    address public auctionStarter;

    constructor(address _auctionStarter, address _EWP, address _WeirdToken) {
        auctionStarter = _auctionStarter;
        EWP = ERC721(_EWP);
        WeirdToken = ERC20(_WeirdToken);
    }

    function batchStartAuction(uint256[] memory ids, uint256[] memory startTimestamps, uint256[] memory endTimestamps, uint256[] memory minPrices) public {
        require(msg.sender == auctionStarter);
        require(ids.length == startTimestamps.length && ids.length == minPrices.length);
        for (uint256 i = 0; i < ids.length; i++) {
            startAuction(ids[i], startTimestamps[i], endTimestamps[i], minPrices[i]);
        }
    }

    function startAuction(uint256 id, uint256 startTimestamp, uint256 endTimestamp, uint256 minPrice) public {
        require(msg.sender == auctionStarter);
        currentPrice[id] = minPrice;
        currentAddress[id] = auctionStarter;
        timestampFinished[id] = endTimestamp;
        timestampStarted[id] = startTimestamp;

        EWP.safeTransferFrom(msg.sender, address(this), id);
        auctionId[totalAuctions] = id;
        totalAuctions++;
    }

    function cancelAuction(uint256 id) public {
        require(msg.sender == auctionStarter);

        currentPrice[id] = 0;
        currentAddress[id] = address(0);
        timestampFinished[id] = 0;
        timestampStarted[id] = 0;

        EWP.transferFrom(address(this), auctionStarter, id);
    }

    function bid(uint256 id, uint256 amount) public {
        require(block.timestamp > timestampStarted[id], "Auction not yet started");
        require(block.timestamp < timestampFinished[id], "Auction already finished");
        require(currentPrice[id] < amount, "Bid underpriced");

        if(block.timestamp + 600 > timestampFinished[id]) {
            timestampFinished[id] = block.timestamp + 600;
        }

        if(currentAddress[id] != auctionStarter) {
            WeirdToken.transfer(currentAddress[id], currentPrice[id]);
        }

        WeirdToken.transferFrom(msg.sender, address(this), amount);

        currentPrice[id] = amount;
        currentAddress[id] = msg.sender;
    }

    function finalize(uint256 id) public {
        require(block.timestamp >= timestampFinished[id], "Auction not yet finished");
        require(currentAddress[id] == msg.sender);
        EWP.safeTransferFrom(address(this), msg.sender, id);
        WeirdToken.transfer(0x000000000000000000000000000000000000dEaD, currentPrice[id]);
    }

    function getAllAuctions() public view returns (uint256[] memory) {
        uint256 totalOpenAuctions = 0;
        for (uint256 i = 0; i < totalAuctions; i++) {
            if(timestampStarted[auctionId[i]] >= block.timestamp && timestampFinished[auctionId[i]] <= block.timestamp) {
                totalOpenAuctions++;
            }
        }

        uint256[] memory auctionIds = new uint256[](totalOpenAuctions);
        uint256 index = 0;
        for (uint256 i = 0; i < totalAuctions; i++) {
            if(timestampStarted[auctionId[i]] >= block.timestamp && timestampFinished[auctionId[i]] <= block.timestamp) {
                auctionIds[index] = auctionId[i];
                index++;
            }
        }
        return auctionIds;
    }

    function setAuctionStarter(address _auctionStarter) public onlyOwner {
        auctionStarter = _auctionStarter;
    }
}