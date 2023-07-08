// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./IERC721Receiver.sol";

interface IERC721A {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    function ownerOf(uint256 tokenId) external view returns (address owner);
}

error NOT__NFTOWNER();
error AUCTION__ALREADYSTARTED();
error AUCTION__NOTSTARTED();
error AUCTION__ENDED();
error AUCTION__NOTENDED();
error AUCTION__TOOLOW();
error BID__ZERO();
error WITHDRAW__FAILED();

contract NFTMarketplace is IERC721Receiver {
    enum BID_STATE {
        NOT_STARTED,
        STARTED
    }

    struct Bidder {
        address payable bidder;
        uint256 bidValue;
    }

    struct MarketItem {
        IERC721A nft;
        address payable seller;
        address payable owner;
        uint256 tokenId;
        uint256 endAt;
        uint256 initialPrice;
        Bidder highestBidder;
        BID_STATE bidState;
    }

    uint256[] public marketItemIds;

    address payable public owner;

    mapping(uint256 => MarketItem) public idMarketItem;
    mapping(uint256 => mapping(address => uint256)) public bidders;

    event MarketItemCreated(
        address payable indexed seller,
        address payable owner,
        uint256 indexed bidValue,
        uint256 indexed endAt,
        uint256 tokenId,
        Bidder highestBidder,
        BID_STATE bidState
    );
    event Bid(
        address payable indexed bidder,
        uint256 indexed bidValue,
        uint256 indexed tokenId
    );
    event Withdraw(address indexed bidder, uint256 amount);
    event End(address indexed highestBidder, uint highestBid);

    constructor() {
        owner = payable(msg.sender);
    }

    function createAuction(
        IERC721A _nft,
        uint256 _nftId,
        uint256 _startingBid
    ) public {
        if (msg.sender != _nft.ownerOf(_nftId)) revert NOT__NFTOWNER();
        if (idMarketItem[_nftId].bidState == BID_STATE.STARTED)
            revert AUCTION__ALREADYSTARTED();
        if (_startingBid == 0) revert BID__ZERO();

        // transfer nft from seller to marketplace contract
        _nft.safeTransferFrom(msg.sender, address(this), _nftId);

        // if checks pass and nft is trasnferred, create market item
        idMarketItem[_nftId] = MarketItem(
            _nft,
            payable(msg.sender),
            payable(address(this)),
            _nftId,
            block.timestamp + 5 minutes,
            _startingBid,
            Bidder(payable(address(0)), 0),
            BID_STATE.STARTED
        );

        marketItemIds.push(_nftId);

        // emit event
        emit MarketItemCreated(
            payable(msg.sender),
            payable(address(this)),
            _startingBid,
            block.timestamp + 5 minutes,
            _nftId,
            Bidder(payable(address(0)), 0),
            BID_STATE.STARTED
        );
    }

    function bid(uint256 _nftId) external payable {
        if (idMarketItem[_nftId].bidState == BID_STATE.NOT_STARTED)
            revert AUCTION__NOTSTARTED();
        if (block.timestamp > idMarketItem[_nftId].endAt)
            revert AUCTION__ENDED();

        // check if highest bidder is currently 0 address,
        // if so, set highest bidder to msg.sender if they meet initial bid value
        // if not, check if msg.sender is higher than current highest bidder
        if (idMarketItem[_nftId].highestBidder.bidder == address(0)) {
            if (msg.value >= idMarketItem[_nftId].initialPrice) {
                idMarketItem[_nftId].highestBidder.bidder = payable(msg.sender);
                idMarketItem[_nftId].highestBidder.bidValue = msg.value;
            } else {
                revert AUCTION__TOOLOW();
            }
        } else {
            // allow previous highestBidder to withdraw their bid
            if (msg.value > idMarketItem[_nftId].highestBidder.bidValue) {
                // update previous highest bidder's balance before setting new highest bidder
                bidders[_nftId][
                    idMarketItem[_nftId].highestBidder.bidder
                ] = idMarketItem[_nftId].highestBidder.bidValue;

                // set new highest bidder
                idMarketItem[_nftId].highestBidder.bidder = payable(msg.sender);
                idMarketItem[_nftId].highestBidder.bidValue = msg.value;
            } else {
                revert AUCTION__TOOLOW();
            }
        }
        emit Bid(payable(msg.sender), msg.value, idMarketItem[_nftId].tokenId);
    }

    function withdraw(uint256 _nftId) external payable {
        uint bal = bidders[_nftId][msg.sender];
        bidders[_nftId][msg.sender] = 0;
        (bool sent, bytes memory data) = payable(msg.sender).call{value: bal}(
            ""
        );
        if (!sent) revert WITHDRAW__FAILED();
        emit Withdraw(msg.sender, bal);
    }

    function end(uint256 _nftId) external {
        if ((idMarketItem[_nftId].bidState == BID_STATE.NOT_STARTED)) {
            revert AUCTION__NOTSTARTED();
        }
        if (block.timestamp < idMarketItem[_nftId].endAt) {
            revert AUCTION__NOTENDED();
        }

        if (idMarketItem[_nftId].highestBidder.bidder != address(0)) {
            idMarketItem[_nftId].nft.safeTransferFrom(
                address(this),
                idMarketItem[_nftId].highestBidder.bidder,
                _nftId
            );
            idMarketItem[_nftId].owner = idMarketItem[_nftId]
                .highestBidder
                .bidder;
            (bool sent, bytes memory data) = idMarketItem[_nftId].seller.call{
                value: idMarketItem[_nftId].highestBidder.bidValue
            }("");
            require(sent, "Can't pay seller");
        } else {
            idMarketItem[_nftId].nft.safeTransferFrom(
                address(this),
                idMarketItem[_nftId].seller,
                _nftId
            );
            idMarketItem[_nftId].owner = idMarketItem[_nftId].seller;
        }
        idMarketItem[_nftId].bidState = BID_STATE.NOT_STARTED;

        emit End(
            idMarketItem[_nftId].highestBidder.bidder,
            idMarketItem[_nftId].highestBidder.bidValue
        );
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public override returns (bytes4) {
        // Implement your logic here, e.g., emit an event, do something with the data, etc.

        // Return this function's selector to confirm the successful receipt of the token.
        return this.onERC721Received.selector;
    }

    function getAllListed() external view returns (MarketItem[] memory) {
        // determine length based on which items are active / have not been claimed by highest bidder
        uint256 count = 0;
        for (uint256 i = 0; i < marketItemIds.length; i++) {
            if (idMarketItem[marketItemIds[i]].bidState == BID_STATE.STARTED) {
                ++count;
            }
        }

        MarketItem[] memory listed = new MarketItem[](count);
        uint256 listedIndex = 0;
        for (uint256 i = 0; i < marketItemIds.length; i++) {
            if (idMarketItem[marketItemIds[i]].bidState == BID_STATE.STARTED) {
                listed[listedIndex] = idMarketItem[marketItemIds[i]];
                ++listedIndex;
            }
        }
        return listed;
    }
}