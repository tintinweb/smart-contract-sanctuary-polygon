// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface NFT {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract NFTEscrow {
    struct Trade {
        uint256 id;
        address nftContract;
        uint256 tokenId;
        address seller;
        address buyer;
        uint256 price;
        bool completed;
    }

    mapping(uint256 => Trade) public Trades;
    uint256 public totalTrades = 0;

    event newTrade(uint256 indexed _id, Trade _trade);
    event tradeCompleted(uint256 indexed _id, Trade _trade);
    event tradeCancelled(uint256 indexed _id, Trade _trade);

    function startTrade(
        address _NFTContract,
        uint256 _tokenId,
        address _buyer,
        uint256 _price
    ) public {
        _getNft(_NFTContract, _tokenId);
        Trades[totalTrades] = Trade(
            totalTrades,
            _NFTContract,
            _tokenId,
            msg.sender,
            _buyer,
            _price,
            false
        );
        emit newTrade(totalTrades, Trades[totalTrades]);
        totalTrades++;
    }

    function cancelTrade(uint256 _tradeId) public {
        Trade memory _trade = Trades[_tradeId];
        require(_trade.seller == msg.sender, "Only seller can cancel a trade!");
        Trades[_tradeId].completed = true;
        _sendNft(_trade.nftContract, _trade.tokenId);
    }

    function accept(uint256 _tradeId) public payable {
        Trade memory _trade = Trades[_tradeId];
        // Confirm correct payment and correct buyer
        require(_trade.buyer == msg.sender, "Invalid buyer!");
        require(msg.value >= _trade.price, "Incorrect amount!");

        Trades[_tradeId].completed = true;

        // Send Nft
        _sendNft(_trade.nftContract, _trade.tokenId);

        // Send MATIC
        payable(_trade.seller).transfer(msg.value);

        emit tradeCompleted(_tradeId, Trades[_tradeId]);
    }

    // Gets the NFT from user addresss and store in this contract
    function _getNft(address _NFTContract, uint256 _tokenId) private {
        NFT _nft = NFT(_NFTContract);
        // Requires that msg.sender is the owner of the token
        require(_nft.ownerOf(_tokenId) == msg.sender, "Not owner");

        // Transfers NFT to this smart contract
        _nft.transferFrom(msg.sender, address(this), _tokenId);
    }

    // Send the NFT to user
    function _sendNft(address _NFTContract, uint256 _tokenId) private {
        // Send token
        NFT _nft = NFT(_NFTContract);
        _nft.safeTransferFrom(address(this), msg.sender, _tokenId);
    }
}