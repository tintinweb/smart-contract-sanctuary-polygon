// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

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
error AUCTION__SELLER();
error SALEPRICE__ZERO();
error WITHDRAW__FAILED();
error SALE__ALREADYSTARTED();
error SALE__TYPEINVALID();
error SALE__NOTAUCTION();
error SALE__BUYNOTACTIVE();
error SALE__BUYTOOLOW();
error SALE__BUYSELLER();

contract NFTMarketplace is IERC721Receiver {
    enum NFT_SALE_STATE {
        NOT_FOR_SALE,
        AUCTION_SALE,
        BUY_NOW_SALE
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
    }

    uint256[] public marketItemIds;

    address payable public owner;

    mapping(uint256 => MarketItem) public idMarketItem;
    mapping(uint256 => mapping(address => uint256)) public bidders;
    mapping(uint256 => NFT_SALE_STATE) public nftSaleState;

    event MarketItemCreated(
        address payable indexed seller,
        address payable owner,
        uint256 indexed bidValue,
        uint256 indexed endAt,
        uint256 tokenId,
        Bidder highestBidder
    );
    event Bid(
        address payable indexed bidder,
        uint256 indexed bidValue,
        uint256 indexed tokenId
    );
    event Withdraw(address indexed bidder, uint256 amount);
    event End(address indexed highestBidder, uint highestBid);
    event Buy(address indexed buyer, uint256 indexed tokenId);

    constructor() {
        owner = payable(msg.sender);
    }

    /**
     * @notice purpose of this function is to allow user to begin the sell process of their nft
     * @param _nft this is the contract address of the nft
     * @param _nftId refers to the nft id attempted to be sold
     * @param _type refers to the type of nft sale
     * @dev _type cannot be 0
     */
    function sellerSelect(
        IERC721A _nft,
        uint256 _nftId,
        NFT_SALE_STATE _type,
        uint256 _price
    ) external {
        if (msg.sender != _nft.ownerOf(_nftId)) revert NOT__NFTOWNER();
        // might not need this revert if marketplace is owner of nft
        if (nftSaleState[_nftId] != NFT_SALE_STATE.NOT_FOR_SALE)
            revert SALE__ALREADYSTARTED();
        if (_price == 0) revert SALEPRICE__ZERO();

        if (_type == NFT_SALE_STATE.AUCTION_SALE) {
            nftSaleState[_nftId] = NFT_SALE_STATE.AUCTION_SALE;
            _createAuction(_nft, _nftId, _price);
        } else if (_type == NFT_SALE_STATE.BUY_NOW_SALE) {
            nftSaleState[_nftId] = NFT_SALE_STATE.BUY_NOW_SALE;
            _buyNow(_nft, _nftId, _price);
        } else {
            revert SALE__TYPEINVALID();
        }
    }

    function purchaseNFT(IERC721A _nft, uint256 _nftId) external payable {
        if (msg.sender == _nft.ownerOf(_nftId)) revert SALE__BUYSELLER();
        if (
            nftSaleState[_nftId] == NFT_SALE_STATE.NOT_FOR_SALE ||
            nftSaleState[_nftId] == NFT_SALE_STATE.AUCTION_SALE
        ) revert SALE__BUYNOTACTIVE();
        if (msg.value != idMarketItem[_nftId].initialPrice)
            revert SALE__BUYTOOLOW();
        nftSaleState[_nftId] = NFT_SALE_STATE.NOT_FOR_SALE;
        _nft.safeTransferFrom(address(this), msg.sender, _nftId);
        (bool sent, bytes memory data) = idMarketItem[_nftId].seller.call{
            value: msg.value
        }("");
        if (!sent) revert WITHDRAW__FAILED();
        emit Buy(msg.sender, _nftId);
    }

    function _buyNow(IERC721A _nft, uint256 _nftId, uint256 _price) private {
        marketItemIds.push(_nftId);
        idMarketItem[_nftId] = MarketItem(
            _nft,
            payable(msg.sender),
            payable(address(this)),
            _nftId,
            0,
            _price,
            Bidder(payable(address(0)), 0)
        );
        _nft.safeTransferFrom(msg.sender, address(this), _nftId);
        // emit event
        emit MarketItemCreated(
            payable(msg.sender),
            payable(address(this)),
            _price,
            0,
            _nftId,
            Bidder(payable(address(0)), 0)
        );
    }

    function _createAuction(
        IERC721A _nft,
        uint256 _nftId,
        uint256 _startingBid
    ) private {
        // if checks pass and nft is trasnferred, create market item
        idMarketItem[_nftId] = MarketItem(
            _nft,
            payable(msg.sender),
            payable(address(this)),
            _nftId,
            block.timestamp + 5 minutes,
            _startingBid,
            Bidder(payable(address(0)), 0)
        );

        marketItemIds.push(_nftId);
        // transfer nft from seller to marketplace contract
        _nft.safeTransferFrom(msg.sender, address(this), _nftId);

        // emit event

        emit MarketItemCreated(
            payable(msg.sender),
            payable(address(this)),
            _startingBid,
            block.timestamp + 5 minutes,
            _nftId,
            Bidder(payable(address(0)), 0)
        );
    }

    function bid(uint256 _nftId) external payable {
        if (nftSaleState[_nftId] == NFT_SALE_STATE.NOT_FOR_SALE)
            revert AUCTION__NOTSTARTED();
        if (nftSaleState[_nftId] == NFT_SALE_STATE.BUY_NOW_SALE)
            revert SALE__NOTAUCTION();
        if (block.timestamp > idMarketItem[_nftId].endAt)
            revert AUCTION__ENDED();
        if (msg.sender == idMarketItem[_nftId].seller) revert AUCTION__SELLER();

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
        if ((nftSaleState[_nftId] == NFT_SALE_STATE.NOT_FOR_SALE)) {
            revert AUCTION__NOTSTARTED();
        }
        if (nftSaleState[_nftId] == NFT_SALE_STATE.BUY_NOW_SALE)
            revert SALE__NOTAUCTION();
        if (block.timestamp < idMarketItem[_nftId].endAt) {
            revert AUCTION__NOTENDED();
        }

        if (idMarketItem[_nftId].highestBidder.bidder != address(0)) {
            idMarketItem[_nftId].owner = idMarketItem[_nftId]
                .highestBidder
                .bidder;
            idMarketItem[_nftId].nft.safeTransferFrom(
                address(this),
                idMarketItem[_nftId].highestBidder.bidder,
                _nftId
            );
            (bool sent, bytes memory data) = idMarketItem[_nftId].seller.call{
                value: idMarketItem[_nftId].highestBidder.bidValue
            }("");
            require(sent, "Can't pay seller");
        } else {
            idMarketItem[_nftId].owner = idMarketItem[_nftId].seller;
            idMarketItem[_nftId].nft.safeTransferFrom(
                address(this),
                idMarketItem[_nftId].seller,
                _nftId
            );
        }
        nftSaleState[_nftId] = NFT_SALE_STATE.NOT_FOR_SALE;
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
            if (
                nftSaleState[marketItemIds[i]] == NFT_SALE_STATE.AUCTION_SALE ||
                nftSaleState[marketItemIds[i]] == NFT_SALE_STATE.BUY_NOW_SALE
            ) {
                ++count;
            }
        }

        MarketItem[] memory listed = new MarketItem[](count);
        uint256 listedIndex = 0;
        for (uint256 i = 0; i < marketItemIds.length; i++) {
            if (
                nftSaleState[marketItemIds[i]] == NFT_SALE_STATE.AUCTION_SALE ||
                nftSaleState[marketItemIds[i]] == NFT_SALE_STATE.BUY_NOW_SALE
            ) {
                listed[listedIndex] = idMarketItem[marketItemIds[i]];
                ++listedIndex;
            }
        }
        return listed;
    }
}