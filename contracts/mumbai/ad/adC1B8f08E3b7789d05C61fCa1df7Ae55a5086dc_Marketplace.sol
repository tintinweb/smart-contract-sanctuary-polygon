// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IERC20.sol";
import "./Owner.sol";
import "./ReentrancyGuard.sol";
import "./IERC1155.sol";
import "./Counters.sol";
import "./ERC1155Holder.sol";

interface NFTS{
    function artistOf(uint256 _tokenId) external view returns(address);
}

contract Marketplace is Owner, ReentrancyGuard, ERC1155Holder {
    using Counters for Counters.Counter;
    Counters.Counter public totalOrders;

    address public payTokenContract;
    address public NftsContract;

    uint256 public sellFeePercentage;   // example: 500 = 5%
    address public walletReceivingSellFee;

    uint256 public minIncrement; // example: 500 = 5% (min increment for new bids from highest)

    bool public lockNewSellOrders;
    mapping(uint256 => SellOrder) public marketList;
    mapping(uint256 => Bid) private _bids;

    struct SellOrder {
        uint256 token_id;
        uint256 amount;
        uint256 price;
        address seller;
        bool status; // false:closed, true: open
        uint256 sell_method; // 1 : fixed, 2 : bids
        uint256 expire_at;
        uint256 royalty;
    }

    struct Bid {
        address bidder;
        uint256 amount;
    }

    // Events
    event OrderAdded(
        uint256 order_id,
        uint256 indexed token_id,
        address indexed seller,
        uint256 price,
        uint256 amount,
        uint256 sell_method,
        uint256 expire_at
    );
    event OrderSuccessful(
        uint256 order_id,
        uint256 indexed token_id,
        address indexed seller,
        uint256 price,
        uint256 amount,
        address indexed buyer
    );
    event OrderAuctionResolved(
        uint256 order_id,
        uint256 indexed token_id,
        address indexed seller,
        uint256 totalPrice,
        uint256 amount,
        address indexed buyer
    );
    event OrderCanceled(
        uint256 order_id,
        uint256 indexed token_id,
        address indexed seller,
        uint256 price
    );

    event SetPriceOfSellOrder(
        uint256 order_id,
        uint256 newPrice
    );

    event SetArtistFee(uint256 oldValue, uint256 newValue);

    event SetSellFee(uint256 oldValue, uint256 newValue);

    event RefundCoinsFromAuction(uint256 indexed orderId, address indexed bidder, uint256 amount);
    event NewHighestBid(uint256 indexed orderId, address indexed bidder, uint256 newHighestBid);

    event Set_TokenContracts(address payTokenContract, address NftsContract);

    event Set_WalletReceivingSellFee(address walletReceivingSellFee);

    event Set_LockNewSellOrders(bool lockStatus);

    event Set_MinIncrementForBids(uint256 minIncrement);

    event Change_SellOrder(uint256 indexed orderId, uint256 price, uint256 expire_at);

    constructor(uint256 _minIncrementForBids, uint256 _sellFeePercentage, address _walletReceivingSellFee, address _payTokenContract, address _NftsContract) {
        setMinIncrementForBids(_minIncrementForBids);
        setSellFeePercentage(_sellFeePercentage);
        setWalletReceivingSellFee(_walletReceivingSellFee);
        setContractsAddress(_payTokenContract, _NftsContract);
    }

    function setContractsAddress(address _payTokenContract, address _NftsContract) public isOwner {
        payTokenContract = _payTokenContract;
        NftsContract = _NftsContract;
        emit Set_TokenContracts(_payTokenContract, _NftsContract);
    }

    function setWalletReceivingSellFee(address _walletReceivingSellFee) public isOwner {
        walletReceivingSellFee = _walletReceivingSellFee;
        emit Set_WalletReceivingSellFee(_walletReceivingSellFee);
    }

    function setLockNewSellOrders(bool _newVal) external isOwner{
        lockNewSellOrders = _newVal;
        emit Set_LockNewSellOrders(_newVal);
    }

    function setMinIncrementForBids(uint256 _newVal) public isOwner {
        minIncrement = _newVal;
        emit Set_MinIncrementForBids(_newVal);
    }

    function setSellFeePercentage(uint256 _newVal) public isOwner {
        require(_newVal <= 9900, "the new value should range from 0 to 9900");
        emit SetSellFee(sellFeePercentage, _newVal);
        sellFeePercentage = _newVal;
    }

    function _computePercent(uint256 _amount, uint256 _feePercentage) internal pure returns (uint256) {
        return (_amount*_feePercentage)/(10**4);
    }

    function newSellOrder(uint256 _token_id, uint256 _amount, uint256 _price, uint256 _sell_method, uint256 _expire_at, uint256 _royalty) external returns (uint256) {
        require(lockNewSellOrders == false, "cannot currently create new sales orders");
        require(IERC1155(NftsContract).balanceOf(msg.sender, _token_id) >= _amount, "you don't have enough balance to sell");
        require(_price > 0, "price must be greater than 0");
        IERC1155(NftsContract).safeTransferFrom(msg.sender, address(this), _token_id, _amount, "");

        totalOrders.increment();
        uint256 newOrderId = totalOrders.current();
        marketList[newOrderId] = SellOrder(
            _token_id,
            _amount,
            _price,
            msg.sender,
            true,
            _sell_method,
            _expire_at,
            _royalty
        );

        emit OrderAdded(newOrderId, _token_id, msg.sender, _price, _amount, _sell_method, _expire_at);
        return newOrderId;
    }


    function cancelSellOrder(uint256 _orderId) external nonReentrant{
        require(marketList[_orderId].seller == msg.sender, "you are not authorized to cancel this order");
        require(marketList[_orderId].status == true, "this order sell already closed");
        if(marketList[_orderId].sell_method == 2){
            require(block.timestamp >= marketList[_orderId].expire_at, 'MARKET: time no expired yet');
            require(_bids[_orderId].bidder == address(0) && _bids[_orderId].amount == 0, "MARKET: there is a pending auction to be resolved");
        }

        marketList[_orderId].status = false;
        IERC1155(NftsContract).safeTransferFrom(address(this), marketList[_orderId].seller, marketList[_orderId].token_id, marketList[_orderId].amount, "");
        emit OrderCanceled(_orderId, marketList[_orderId].token_id, marketList[_orderId].seller, marketList[_orderId].price);
    }

    function setPriceOfSellOrder(uint256 _orderId, uint256 _newPrice) external nonReentrant{
        require(marketList[_orderId].seller == msg.sender, "you are not authorized to set price of this order");
        require(marketList[_orderId].status == true, "this order sell already closed");

        marketList[_orderId].price = _newPrice;
        emit SetPriceOfSellOrder(_orderId, _newPrice);
    }


    function buy(uint256 _orderId, uint256 _amountToBuy) external nonReentrant{
        require(msg.sender != address(0) && msg.sender != marketList[_orderId].seller, "current sender is already owner of this token");
        require(marketList[_orderId].status == true, "this sell order is closed");
        require(marketList[_orderId].sell_method == 1, "this sell order is on auction");
        require(marketList[_orderId].amount >= _amountToBuy, "the amount to buy is not available");

        marketList[_orderId].amount -= _amountToBuy;
        if(marketList[_orderId].amount <= 0){
            marketList[_orderId].status = false;
        }

        uint256 totalPay = marketList[_orderId].price * _amountToBuy;        
        uint256 artistFee = _computePercent(totalPay, marketList[_orderId].royalty);
        uint256 sellFee = _computePercent(totalPay, sellFeePercentage);
        uint256 sellerProfit = totalPay - (artistFee + sellFee);
        address artistAddress = NFTS(NftsContract).artistOf(marketList[_orderId].token_id);
        IERC20(payTokenContract).transferFrom(msg.sender, marketList[_orderId].seller, sellerProfit);
        IERC20(payTokenContract).transferFrom(msg.sender, artistAddress, artistFee);
        IERC20(payTokenContract).transferFrom(msg.sender, walletReceivingSellFee, sellFee);

        IERC1155(NftsContract).safeTransferFrom(address(this), msg.sender, marketList[_orderId].token_id, _amountToBuy, "");
        emit OrderSuccessful(_orderId, marketList[_orderId].token_id, marketList[_orderId].seller, marketList[_orderId].price, _amountToBuy, msg.sender);
    }

    function reverseOrders(uint256[] memory _orders_id) external isOwner{
        for (uint256 i=0; i<_orders_id.length; i++) {
            if(marketList[_orders_id[i]].status == true){
                
                if(marketList[_orders_id[i]].sell_method == 2){
                    if(block.timestamp >= marketList[_orders_id[i]].expire_at && _bids[_orders_id[i]].bidder == address(0) && _bids[_orders_id[i]].amount == 0){
                        // the order has already expired and there are no bids
                    }else{
                        continue;
                    }
                }

                marketList[_orders_id[i]].status = false;
                IERC1155(NftsContract).safeTransferFrom(address(this), marketList[_orders_id[i]].seller, marketList[_orders_id[i]].token_id, marketList[_orders_id[i]].amount, "");
                emit OrderCanceled(_orders_id[i], marketList[_orders_id[i]].token_id, marketList[_orders_id[i]].seller, marketList[_orders_id[i]].price);
            }
        }
    }


    modifier isOpenToAuctions(uint256 _orderId) {
        require(block.timestamp < marketList[_orderId].expire_at, 'MARKET: Time expired to do bids');
        _;
    }

    modifier auctionsEnded(uint256 _orderId) {
        require(block.timestamp >= marketList[_orderId].expire_at, 'MARKET: Time no expired yet');
        _;
    }

    modifier isOnAuctions(uint256 _orderId) {
        require(marketList[_orderId].sell_method == 2, "MARKET: It's not open to bids");
        require(marketList[_orderId].status == true, "MARKET: It's not for sale currently");
        _;
    }

    function minAmountForBid(uint256 _orderId) public view isOpenToAuctions(_orderId) returns (uint256){
        uint256 totalOrderPrice = marketList[_orderId].price * marketList[_orderId].amount;
        uint256 maxValue = (totalOrderPrice  >= _bids[_orderId].amount) ? totalOrderPrice : _bids[_orderId].amount;
        uint256 amountRequired = _computePercent(maxValue, minIncrement);
        return maxValue + amountRequired;
    }

    function bid(uint256 _orderId, uint256 _amount) external isOnAuctions(_orderId) isOpenToAuctions(_orderId) nonReentrant{
        require(marketList[_orderId].seller != msg.sender, "MARKET: Owner can't bid on its token");
        uint256 amountRequired = minAmountForBid(_orderId);
        require(_amount >= amountRequired, 'MARKET: Bid amount lower than current min bids');

        address oldBidder = _bids[_orderId].bidder;
        uint256 oldAmount = _bids[_orderId].amount;

        _bids[_orderId] = Bid({ bidder: msg.sender, amount: _amount });

        if (oldBidder != address(0) && oldAmount > 0) {
            IERC20(payTokenContract).transfer(oldBidder, oldAmount);
            emit RefundCoinsFromAuction(_orderId, oldBidder, oldAmount);
        }

        IERC20(payTokenContract).transferFrom(msg.sender, address(this), _amount);
        emit NewHighestBid(_orderId, msg.sender, _amount);
    }

    function resolveAuction(uint256 _orderId) external isOnAuctions(_orderId) auctionsEnded(_orderId) nonReentrant{
        SellOrder memory order = marketList[_orderId];
        uint256 totalOrderPrice = order.price * order.amount;
        require(_bids[_orderId].amount >= totalOrderPrice, "MARKET: There is nothing pending to solve");

        marketList[_orderId].status = false;
        address tokenSeller = order.seller;
        uint256 sellerProceeds = _bids[_orderId].amount;
        address bidder = _bids[_orderId].bidder;

        uint256 artistFee = _computePercent(sellerProceeds, order.royalty);
        uint256 sellFee = _computePercent(sellerProceeds, sellFeePercentage);
        uint256 feesByTransfer = artistFee + sellFee;
        address artistAddress = NFTS(NftsContract).artistOf(order.token_id);
        IERC20(payTokenContract).transfer(tokenSeller, sellerProceeds - feesByTransfer);
        IERC20(payTokenContract).transfer(artistAddress, artistFee);
        IERC20(payTokenContract).transfer(walletReceivingSellFee, sellFee);

        IERC1155(NftsContract).safeTransferFrom(address(this), bidder, order.token_id, order.amount, "");

        delete _bids[_orderId];
        emit OrderAuctionResolved(_orderId, order.token_id, tokenSeller, sellerProceeds, order.amount, bidder);
    }


    function changeSellOrder(uint256 _orderId, uint256 _price, uint256 _expire_at) external nonReentrant{
        require(marketList[_orderId].seller == msg.sender, "you are not authorized to change this order");
        require(marketList[_orderId].status == true, "this sell order is closed");
        if(marketList[_orderId].sell_method == 2){
            require(block.timestamp >= marketList[_orderId].expire_at, 'MARKET: time no expired yet');
            require(_bids[_orderId].bidder == address(0) && _bids[_orderId].amount == 0, "MARKET: there is a pending auction to be resolved");
        }

        marketList[_orderId].price = _price;
        marketList[_orderId].expire_at = _expire_at;
        
        emit Change_SellOrder(_orderId, _price, _expire_at);
    }

    
    function ResolveOrder(uint256 _orderId, uint256 _amountToBuy, address _buyer) external isOwner nonReentrant{
        require(msg.sender == marketList[_orderId].seller, "you are not authorized to resolve this order");
        require(marketList[_orderId].status == true, "this sell order is closed");
        require(marketList[_orderId].sell_method == 1, "this sell order is on auction");
        require(marketList[_orderId].amount >= _amountToBuy, "the amount to buy is not available");

        marketList[_orderId].amount -= _amountToBuy;
        if(marketList[_orderId].amount <= 0){
            marketList[_orderId].status = false;
        }

        IERC1155(NftsContract).safeTransferFrom(address(this), _buyer, marketList[_orderId].token_id, _amountToBuy, "");
        emit OrderSuccessful(_orderId, marketList[_orderId].token_id, marketList[_orderId].seller, marketList[_orderId].price, _amountToBuy, _buyer);
    }


}