// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IERC20.sol";
import "./Owner.sol";
import "./ReentrancyGuard.sol";
import "./IERC1155.sol";
import "./Counters.sol";

interface NFTS{
    function artistOf(uint256 _tokenId) external view returns(address);
}

contract Marketplace is Owner, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter public totalOrders;

    // COMISIONES POR CADA VENTA
    // comision para el dueno del contrato
    // comision para el artista o creardor del nft
    // varaible con % o valor maximo para setear los % de comisiones

    // PERMITIRA SUBASTAS
    // variable con % minimo de incremento para hacer una puja en subasta

    address public payTokenContract;
    address public NftsContract;

    uint256 public artistFeePercentage; // example: 500 = 5%
    uint256 public sellFeePercentage;   // example: 500 = 5%
    address public walletReceivingSellfee;

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

    constructor(uint256 _artistFeePercentage, uint256 _sellFeePercentage, address _walletReceivingSellfee, address _payTokenContract, address _NftsContract) {
        setFeeWallets(_walletReceivingSellfee);
        setArtistFeePercentage(_artistFeePercentage);
        setSellFeePercentage(_sellFeePercentage);
        setContractsAddress(_payTokenContract, _NftsContract);
    }

    function setContractsAddress(address _payTokenContract, address _NftsContract) public isOwner {
        payTokenContract = _payTokenContract;
        NftsContract = _NftsContract;
        emit Set_TokenContracts(_payTokenContract, _NftsContract);
    }

    function setFeeWallets(address _walletReceivingSellfee) public isOwner {
        walletReceivingSellfee = _walletReceivingSellfee;
    }

    function modifyLockNewSellOrders(bool _newValue) external isOwner{
        lockNewSellOrders = _newValue;
    }

    function setArtistFeePercentage(uint256 _newVal) public isOwner {
        require(_newVal <= 9900, "the new value should range from 0 to 9900");
        emit SetArtistFee(artistFeePercentage, _newVal);
        artistFeePercentage = _newVal;
    }

    function setSellFeePercentage(uint256 _newVal) public isOwner {
        require(_newVal <= 9900, "the new value should range from 0 to 9900");
        emit SetSellFee(sellFeePercentage, _newVal);
        sellFeePercentage = _newVal;
    }

    function getArtistFee(uint256 _amount) public view returns(uint256){
        return (_amount*artistFeePercentage)/(10**4);
    }

    function getSellFee(uint256 _amount) public view returns(uint256){
        return (_amount*sellFeePercentage)/(10**4);
    }

    function _computePercent(uint256 _amount, uint256 _feeAmount) internal pure returns (uint256) {
        return (_amount*_feeAmount)/(10**4);
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
        require(marketList[_orderId].amount >= _amountToBuy, "the amount to buy is not available");

        marketList[_orderId].amount -= _amountToBuy;
        if(marketList[_orderId].amount <= 0){
            marketList[_orderId].status = false;
        }

        uint256 totalPay = marketList[_orderId].price * _amountToBuy;
        uint256 artistFee = getArtistFee(totalPay);
        uint256 sellFee = getSellFee(totalPay);
        uint256 sellerProfit = totalPay - (artistFee + sellFee);
        address artistAddress = NFTS(NftsContract).artistOf(marketList[_orderId].token_id);
        IERC20(payTokenContract).transferFrom(msg.sender, marketList[_orderId].seller, sellerProfit);
        IERC20(payTokenContract).transferFrom(msg.sender, artistAddress, artistFee);
        IERC20(payTokenContract).transferFrom(msg.sender, walletReceivingSellfee, sellFee);

        IERC1155(NftsContract).safeTransferFrom(address(this), msg.sender, marketList[_orderId].token_id, _amountToBuy, "");
        emit OrderSuccessful(_orderId, marketList[_orderId].token_id, marketList[_orderId].seller, marketList[_orderId].price, _amountToBuy, msg.sender);
    }

    function reverseOrders(uint256[] memory _orders_id) external isOwner{
        for (uint256 i=0; i<_orders_id.length; i++) {
            if(marketList[_orders_id[i]].status == true){
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
        // require(_exists(_tokenId), 'ERC721: nonexistent token');
        require(marketList[_orderId].sell_method == 2, "MARKET: It's not open to bids");
        // require(marketList[_orderId].locked == true, "MARKET: It's not locked for bids");
        require(marketList[_orderId].status == true, "MARKET: It's not for sale currently");
        _;
    }

    function minAmountForBid(uint256 _orderId) public view isOpenToAuctions(_orderId) returns (uint256){
        uint256 maxValue = (marketList[_orderId].price  >= _bids[_orderId].amount) ? marketList[_orderId].price : _bids[_orderId].amount;
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

    // QUEDASTE AQUI TERMINAR DE CHECAR LA FUNCION Y SEGUIR CON LO DEMAS QUE SEA NECESARIO PARA TERMINAR LAS SUBASTAS
    // function resolveAuction(uint256 _orderId) external isOnAuctions(_orderId) auctionsEnded(_orderId) nonReentrant{
    //     require(_bids[_orderId].amount >= marketList[_orderId].price, "MARKET: There is nothing pending to solve");

    //     address tokenSeller = marketList[_orderId].seller;
    //     uint256 sellerProceeds = _bids[_orderId].amount;
    //     // uint256 feesByTransfer = _payTxFee(_tokenId, true); // pay fees by auctions
    //     IERC20(acceptedToken).transfer(tokenSeller, sellerProceeds.sub(feesByTransfer));

    //     _transfer(tokenSeller, _bids[_tokenId].bidder, _tokenId);

    //     _tokenMeta[_tokenId].price = _bids[_tokenId].amount;
    //     delete _bids[_tokenId];

    //     emit OrderAuctionResolved(_tokenId, tokenSeller, _tokenMeta[_tokenId].price, ownerOf(_tokenId));
    // }



    


    


    



































































    // mapping(uint256 => TokenMeta) public _tokenMeta;
    // mapping(uint256 => Bid) public _bids;

    // uint256 public feeSellTokens = 20000; // 2 %
    // uint256 public minIncrement = 20000; // 2 % min increment for new bids from highest
    // uint256 public maxAllowedRoyalties = 500000; // 50 %
    // address public acceptedToken;

    // // NFTS contract address
    // address public NFTS_address;

    // struct TokenMeta {
    //     uint256 id;
    //     string name;
    //     bool sale;
    //     uint256 sell_method; // 1 : fixed, 2 : bids
    //     uint256 expire_at;
    //     uint256 price;
    //     uint256 royalty;
    //     address artist;
    //     bool locked;
    //     string id_collection;
    //     uint256 amount;
    // }

    // struct Bid {
    //     address bidder;
    //     uint256 amount;
    // }



    // // Events
    // event OrderSuccessful(
    //     uint256 indexed assetId,
    //     address indexed seller,
    //     uint256 totalPrice,
    //     address indexed buyer
    // );

    // event OrderAuctionResolved(
    //     uint256 indexed assetId,
    //     address indexed seller,
    //     uint256 totalPrice,
    //     address indexed buyer
    // );
    // event ChangedSalesFee(uint256 salesFee);
    // event ChangedMinIncrement(uint256 newMinIncrement);
    // event ChangedSalesTokenStatus(
    //     uint256 indexed tokenId,
    //     address indexed who,
    //     bool status,
    //     uint256 price,
    //     uint256 sell_method,
    //     uint256 expire_at
    // );
    // event ChangedMaxAllowedRoyalties(uint256 maxRoyalties);
    // event NewHighestBid(uint256 indexed tokenId, address indexed bidder, uint256 newHighestBid);
    // event RefundCoinsFromAuction(uint256 indexed tokenId, address indexed bidder, uint256 amount);
    // event NewProfit(uint256 indexed tokenId, address indexed admin, uint256 time, uint256 amount);
    // event TransferOutsideMarket(
    //     address indexed sender,
    //     address indexed receiver,
    //     uint256 indexed tokenId,
    //     uint256 time
    // );
    // event WithdrawnProfits(address indexed receiver, uint256 amount, uint256 time);


    // constructor(address _acceptedToken) {        
    //     setAcceptedToken(_acceptedToken);
    // }

    // function setAcceptedToken(address _acceptedToken) public onlyOwner {
    //     acceptedToken = _acceptedToken;
    // }

    // function setFeeSellTokens(uint256 _newFeeSellTokens) public onlyOwner {
    //     require(_newFeeSellTokens < 500000, 'ERC721: Max Allowed Royalties 50%');
    //     feeSellTokens = _newFeeSellTokens;
    //     emit ChangedSalesFee(feeSellTokens);
    // }

    // function setMinIncrement(uint256 _newMinIncrement) public onlyOwner {
    //     minIncrement = _newMinIncrement;
    //     emit ChangedMinIncrement(_newMinIncrement);
    // }

    // function canBuy(address _from, uint256 _tokenId) public view returns (bool) {
    //     return IERC20(acceptedToken).balanceOf(_from) >= _tokenMeta[_tokenId].price;
    // }

    // /**
    // * @dev calculate royalty to pay if buy token
    // * @param _tokenId uint256
    // */
    // function calculaRoyaltyToBePaid(uint256 _tokenId) public view returns (uint256, uint256, uint256) {
    //     uint256 feeSellToken = _computePercent(_tokenMeta[_tokenId].price, feeSellTokens);
    //     uint256 feeArtistSellToken = _computePercent(_tokenMeta[_tokenId].price, _tokenMeta[_tokenId].royalty);
    //     uint256 sellerProceeds = _tokenMeta[_tokenId].price - feeSellToken - feeArtistSellToken;
    //     return (sellerProceeds, feeSellToken, feeArtistSellToken);
    // }

    // function setMaxAllowedRoyalties(uint256 _newMaxAllowedRoyalties) public onlyOwner {
    //     require(_newMaxAllowedRoyalties < 500000, 'ERC721: Max Allowed Royalties 50%');
    //     maxAllowedRoyalties = _newMaxAllowedRoyalties;
    //     emit ChangedMaxAllowedRoyalties(maxAllowedRoyalties);
    // }


    // // CHECAR ESTA FUNCION
    // modifier isOnAuctions(uint256 _tokenId) {
    //     require(_exists(_tokenId), 'ERC721: nonexistent token');
    //     require(_tokenMeta[_tokenId].sell_method == 2, "ERC721: It's not open to bids");
    //     require(_tokenMeta[_tokenId].locked == true, "ERC721: It's not locked for bids");
    //     require(_tokenMeta[_tokenId].sale == true, "ERC721: It's not for sale currently");
    //     _;
    // }

    // modifier isOpenToAuctions(uint256 _tokenId) {
    //     require(block.timestamp < _tokenMeta[_tokenId].expire_at, 'ERC721: Time expired to do bids');
    //     _;
    // }

    // modifier auctionsEnded(uint256 _tokenId) {
    //     require(block.timestamp >= _tokenMeta[_tokenId].expire_at, 'ERC721: Time no expired yet');
    //     _;
    // }

    // receive() external payable {
    //     revert();
    // }

    // fallback() external payable {
    //     revert();
    // }

    // function withdraw() public onlyOwner {
    //     uint256 balance = IERC20(acceptedToken).balanceOf(address(this));
    //     IERC20(acceptedToken).transfer(owner(), balance);
    //     emit WithdrawnProfits(owner(), balance, block.timestamp);
    // }


    // function minAmountForBid(uint256 _tokenId) public view isOpenToAuctions(_tokenId) returns (uint256) {
    //     uint256 maxValue = _tokenMeta[_tokenId].price.max(_bids[_tokenId].amount);
    //     uint256 amountRequired = _computePercent(maxValue, minIncrement);
    //     return maxValue + amountRequired;
    // }

    // function timeLeftToCloseAuctions(uint256 _tokenId) public view returns (uint256) {
    //     if (block.timestamp >= _tokenMeta[_tokenId].expire_at) {
    //         return 0;
    //     }

    //     uint256 left = _tokenMeta[_tokenId].expire_at - block.timestamp;
    //     return (left > 0) ? left : 0;
    // }

    // function highestBid(uint256 _tokenId) public view isOnAuctions(_tokenId) returns (uint256) {
    //     return _tokenMeta[_tokenId].price.max(_bids[_tokenId].amount);
    // }
    

    // function bid(uint256 _tokenId, uint256 _amount) external isOnAuctions(_tokenId) isOpenToAuctions(_tokenId) nonReentrant {
    //     require(ownerOf(_tokenId) != _msgSender(), "ERC721: Owner can't bid on its token");
    //     require(IERC20(acceptedToken).allowance(_msgSender(), address(this)) >= _amount, 'ERC720: Insufficient balance to offer amount to buy NFT');
    //     uint256 amountRequired = minAmountForBid(_tokenId);
    //     require(_amount >= amountRequired, 'ERC721: Bid amount lower than current min bids');

    //     address oldBidder = _bids[_tokenId].bidder;
    //     uint256 oldAmount = _bids[_tokenId].amount;

    //     _bids[_tokenId] = Bid({ bidder: _msgSender(), amount: _amount });

    //     if (oldBidder != address(0) && oldAmount > 0) {
    //         IERC20(acceptedToken).transfer(oldBidder, oldAmount);
    //         emit RefundCoinsFromAuction(_tokenId, oldBidder, oldAmount);
    //     }

    //     IERC20(acceptedToken).transferFrom(_msgSender(), address(this), _amount);
    //     emit NewHighestBid(_tokenId, _msgSender(), _amount);
    // }


    // // CHECAR ESTA FUNCION
    // function resolveAuction(uint256 _tokenId) external isOnAuctions(_tokenId) auctionsEnded(_tokenId) {
    //     require(_bids[_tokenId].amount >= _tokenMeta[_tokenId].price, 'There is nothing pending to solve');

    //     address tokenSeller = ownerOf(_tokenId);
    //     uint256 sellerProceeds = _bids[_tokenId].amount;
    //     uint256 feesByTransfer = _payTxFee(_tokenId, true); // pay fees by auctions
    //     IERC20(acceptedToken).transfer(tokenSeller, sellerProceeds.sub(feesByTransfer));

    //     _transfer(tokenSeller, _bids[_tokenId].bidder, _tokenId);

    //     _tokenMeta[_tokenId].price = _bids[_tokenId].amount;
    //     delete _bids[_tokenId];

    //     emit OrderAuctionResolved(_tokenId, tokenSeller, _tokenMeta[_tokenId].price, ownerOf(_tokenId));
    // }










}