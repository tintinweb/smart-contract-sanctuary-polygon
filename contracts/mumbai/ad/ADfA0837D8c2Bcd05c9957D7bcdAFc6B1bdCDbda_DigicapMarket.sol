// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import './ERC1155Holder.sol';

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Manager is Ownable, Pausable {
    using Strings for uint256;
    // FEE
    uint256 public xUser = 250; // 2.5%
    uint256 public xBuyer = 250; // 2.5%
    uint256 public xCreator = 1500;
    uint256 public zProfitToCreator = 5000; // 10% profit
    mapping(address => bool) public paymentMethod;
    mapping(address => bool) public isFarmingNFTs;
    mapping(address => bool) public isOperator;
    mapping(address => bool) public isRetailer;

    mapping(string => uint256) private commissionSellers;
    mapping(string => bool) public isCommissionSellerSets;

    mapping(string => uint256) private commissionBuyers;
    mapping(string => bool) public isCommissionBuyerSets;

    event SetCommissions(
        uint256[] _categoryIds,
        uint256[] _branchIds,
        uint256[] _collectionIds,
        address[] _minters,
        uint256[] _sellerCommissions,
        uint256[] _buyerCommissions
    );

    event SetSystemFee(
        uint256 xUser,
        uint256 xBuyer,
        uint256 yRefRate,
        uint256 zProfitToCreator
    );

    modifier onlyOperator() {
        require(isOperator[msg.sender], "Only-operator");
        _;
    }

    constructor() {
        isOperator[msg.sender] = true;
    }

    function whiteListOperator(address _operator, bool _whitelist)
        external
        onlyOwner
    {
        isOperator[_operator] = _whitelist;
    }

    function whiteListRetailer(address _retailer, bool _whitelist)
        external
        onlyOwner
    {
        isRetailer[_retailer] = _whitelist;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unPause() public onlyOwner {
        _unpause();
    }

    function setSystemFee(
        uint256 _xUser,
        uint256 _xBuyer,
        uint256 _yRefRate,
        uint256 _zProfitToCreator
    ) external onlyOwner {
        _setSystemFee(_xUser, _xBuyer, _yRefRate, _zProfitToCreator);
        emit SetSystemFee(_xUser, _xBuyer, _yRefRate, _zProfitToCreator);
    }

    function _setSystemFee(
        uint256 _xUser,
        uint256 _xBuyer,
        uint256 _xCreator,
        uint256 _zProfitToCreator
    ) internal {
        xUser = _xUser;
        xBuyer = _xBuyer;
        xCreator = _xCreator;
        zProfitToCreator = _zProfitToCreator;
    }

    function setPaymentMethod(address _token, bool _status)
        public
        onlyOwner
        returns (bool)
    {
        paymentMethod[_token] = _status;
        if (_token != address(0)) {
            IERC20(_token).approve(msg.sender, type(uint256).max);
            IERC20(_token).approve(address(this), type(uint256).max);
        }
        return true;
    }

    function setCommissions(
        uint256[] memory _categoryIds,
        uint256[] memory _branchIds,
        uint256[] memory _collectionIds,
        address[] memory _minters,
        uint256[] memory _sellerCommissions,
        uint256[] memory _buyerCommissions
    ) public onlyOwner {
        require(
            _categoryIds.length > 0 &&
                _categoryIds.length == _sellerCommissions.length &&
                _categoryIds.length == _buyerCommissions.length &&
                _categoryIds.length == _branchIds.length &&
                _categoryIds.length == _collectionIds.length &&
                _categoryIds.length == _minters.length,
            "Invalid-input"
        );
        for (uint256 i = 0; i < _categoryIds.length; i++) {
            _setCommission(
                _categoryIds[i],
                _branchIds[i],
                _collectionIds[i],
                _minters[i],
                _sellerCommissions[i],
                _buyerCommissions[i]
            );
        }

        emit SetCommissions(
            _categoryIds,
            _branchIds,
            _collectionIds,
            _minters,
            _sellerCommissions,
            _buyerCommissions
        );
    }

    function _setCommission(
        uint256 _categoryId,
        uint256 _branchId,
        uint256 _collecttionId,
        address _minter,
        uint256 _sellerCommission,
        uint256 _buyerCommission
    ) private onlyOwner {
        require(_categoryId > 0, "Invalid-categoryId");
        if (_minter != address(0)) {
            require(_collecttionId > 0, "Invalid-collecttionId");
        }

        if (_collecttionId > 0) {
            require(_branchId > 0, "Invalid-branchId");
        }

        string memory _config = mapConfigId(
            _categoryId,
            _branchId,
            _collecttionId,
            _minter
        );

        commissionSellers[_config] = _sellerCommission;
        isCommissionSellerSets[_config] = true;

        commissionBuyers[_config] = _buyerCommission;
        isCommissionBuyerSets[_config] = true;
    }

    function getCommissionSeller(
        uint256 _categoryId,
        uint256 _branchId,
        uint256 _collecttionId,
        address _minter
    ) public view returns (uint256) {
        string memory _config = mapConfigId(
            _categoryId,
            _branchId,
            _collecttionId,
            _minter
        );

        if (isCommissionSellerSets[_config]) {
            return commissionSellers[_config];
        }

        _config = mapConfigId(
            _categoryId,
            _branchId,
            _collecttionId,
            address(0)
        );
        if (isCommissionSellerSets[_config]) {
            return commissionSellers[_config];
        }

        _config = mapConfigId(_categoryId, _branchId, 0, address(0));
        if (isCommissionSellerSets[_config]) {
            return commissionSellers[_config];
        }

        _config = mapConfigId(_categoryId, 0, 0, address(0));
        if (isCommissionSellerSets[_config]) {
            return commissionSellers[_config];
        }

        return xUser;
    }

    function getCommissionBuyer(
        uint256 _categoryId,
        uint256 _branchId,
        uint256 _collecttionId,
        address _minter
    ) public view returns (uint256) {
        string memory _config = mapConfigId(
            _categoryId,
            _branchId,
            _collecttionId,
            _minter
        );

        if (isCommissionBuyerSets[_config]) {
            return commissionBuyers[_config];
        }

        _config = mapConfigId(
            _categoryId,
            _branchId,
            _collecttionId,
            address(0)
        );
        if (isCommissionBuyerSets[_config]) {
            return commissionBuyers[_config];
        }

        _config = mapConfigId(_categoryId, _branchId, 0, address(0));
        if (isCommissionBuyerSets[_config]) {
            return commissionBuyers[_config];
        }

        _config = mapConfigId(_categoryId, 0, 0, address(0));
        if (isCommissionBuyerSets[_config]) {
            return commissionBuyers[_config];
        }

        return xBuyer;
    }

    function mapConfigId(
        uint256 _categoryId,
        uint256 _branchId,
        uint256 _collecttionId,
        address _minter
    ) public pure returns (string memory) {
        uint256 _minterId = uint256(uint160(_minter));
        string memory _config = string(
            abi.encodePacked(
                "Ca",
                _categoryId.toString(),
                "Br",
                _branchId.toString(),
                "Co",
                _collecttionId.toString(),
                "M",
                Strings.toString(_minterId)
            )
        );
        if (_branchId == 0) {
            return string(abi.encodePacked("Ca", _categoryId.toString()));
        }

        if (_collecttionId == 0) {
            return
                string(
                    abi.encodePacked(
                        "Ca",
                        _categoryId.toString(),
                        "Br",
                        _branchId.toString()
                    )
                );
        }

        if (_minterId == 0) {
            return
                string(
                    abi.encodePacked(
                        "Ca",
                        _categoryId.toString(),
                        "Br",
                        _branchId.toString(),
                        "Co",
                        _collecttionId.toString()
                    )
                );
        }
        return _config;
    }

    /**
     * @notice withdrawFunds
     */
    function withdrawFunds(address payable _beneficiary, address _tokenAddress)
        external
        onlyOwner
        whenPaused
    {
        uint256 _withdrawAmount;
        if (_tokenAddress == address(0)) {
            _beneficiary.transfer(address(this).balance);
            _withdrawAmount = address(this).balance;
        } else {
            _withdrawAmount = IERC20(_tokenAddress).balanceOf(address(this));
            IERC20(_tokenAddress).transfer(_beneficiary, _withdrawAmount);
        }
    }
}

contract DigicapMarket is Manager, ERC721Holder, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address payable;
    using ECDSA for bytes32;

    address public nFTAddress;

    address public verifier;
    address public feeTo;
    uint256 public constant ZOOM_USDT = 10**6;
    uint256 public constant ZOOM_FEE = 10**4;
    uint256 public totalOrders;
    uint256 public totalBids;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    struct Order {
        address owner;
        address paymentToken;
        uint256 tokenId;
        uint256 price; // price of 1 NFT in paymentToken
        uint256 commissionFromBuyer;
        uint256 commissionToSeller;
        uint256 expTime;
        bool isOnsale; // true: on sale, false: cancel
    }

    struct Bid {
        address bidder;
        address paymentToken;
        uint256 tokenId;
        uint256 bidPrice;
        uint256 commissionFromBuyer;
        uint256 expTime;
        bool status; // 1: available | 2: done | 3: reject
    }

    struct BuyerCommissionInput {
        uint256 orderId;
        address paymentToken;
        uint256 tokenId;
        uint256 amount;
        address minter;
    }

    struct TaxPromoCodeInfo {
        bool isPercent;
        uint256 tax;
        uint256 promoCodeNft;
        uint256 promoCodeServiceFee;
    }

    struct BuyerCommissionOutput {
        uint256 amountToBuyer;
        uint256 commissionFromBuyer;
        uint256 promocodeAmount;
        uint256 taxAmount;
    }

    mapping(uint256 => Order) public orders;
    mapping(bytes32 => uint256) private orderID;
    mapping(uint256 => Bid) public bids;
    mapping(address => mapping(uint256 => uint256)) public amountFirstSale;
    mapping(address => mapping(bytes32 => uint256)) public farmingAmount;
    mapping(bytes32 => bool) public isBid;

    event OrderCreated(
        uint256 indexed _orderId,
        uint256 indexed _tokenId,
        uint256 _price,
        address _paymentToken,
        uint256 expTime
    );
    event Buy(
        uint256 _itemId,
        address _paymentToken,
        uint256 _paymentAmount,
        uint256 _promocodeAmount,
        uint256 _taxAmount
    );
    event OrderCancelled(uint256 indexed _orderId);
    event OrderUpdated(uint256 indexed _orderId);
    event BidCreated(
        uint256 indexed _bidId,
        uint256 indexed _tokenId,
        uint256 _price,
        address _paymentToken,
        uint256 expTime
    );
    event AcceptBid(uint256 indexed _bidId);
    event BidUpdated(uint256 indexed _bidId);
    event BidCancelled(uint256 indexed _bidId);
    event VerifierSet(address indexed _verifier);
    event NFTAddressSet(address indexed _nFTAddress);

    constructor(address verifier_, address nFTAddress_, address feeto_) Manager() {
        verifier = verifier_;
        nFTAddress = nFTAddress_;
        feeTo = feeto_;
    }

    /**
     * @dev Function to set new verifier
     * @param _verifier new verifier address to set
     * Emit VerifierSet event
     */
    function setVerifier(address _verifier) external onlyOwner {
        require(_verifier != address(0), "Invalid-address");
        require(_verifier != verifier, "Verifier-already-set");
        verifier = _verifier;
        emit VerifierSet(_verifier);
    }

    /**
     * @dev Function to set new NFT address
     * @param _nFTAddress new verifier address to set
     * Emit NFTAddressSet event
     */
    function setNFTAddress(address _nFTAddress) external onlyOwner {
        require(_nFTAddress != address(0), "Invalid-address");
        require(_nFTAddress != nFTAddress, "NFT-address-already-set");
        bool isERC721 = IERC721(_nFTAddress).supportsInterface(
            _INTERFACE_ID_ERC721
        );
        require(isERC721, "Token-is-not-ERC721");
        nFTAddress = _nFTAddress;
        emit NFTAddressSet(_nFTAddress);
    }

    function _paid(
        address _token,
        address _to,
        uint256 _amount
    ) private {
        require(_to != address(0), "Invalid-address");
        if (_token == address(0)) {
            payable(_to).sendValue(_amount);
        } else {
            IERC20(_token).safeTransfer(_to, _amount);
        }
    }

    /**
     * @dev Matching order mechanism
     * @param _buyer is address of buyer
     * @param _orderId is id of order
     * @param _paymentToken is payment method (USDT, BNB, ...)
     * @param _price is matched price
     */
    function _match(
        address _buyer,
        address _paymentToken,
        uint256 _orderId,
        uint256 _price,
        uint256 _commissionFromBuyer,
        uint256 _taxAmount
    ) private returns (bool) {
        Order memory order = orders[_orderId];
        (
            uint256 _categoryId,
            uint256 _branchId,
            uint256 _collectionId
        ) = callGetCategoryToken(order.tokenId);
        uint256 _commission = getCommissionSeller(
            _categoryId,
            _branchId,
            _collectionId,
            _buyer
        );
        order.commissionToSeller = (_price * _commission) / ZOOM_FEE;
        uint256 amountToSeller = _price - order.commissionToSeller;
        // send payment to seller 
        _paid(_paymentToken, order.owner, amountToSeller);
        // send nft to buyer
        IERC721(nFTAddress).safeTransferFrom(
            address(this),
            _buyer,
            order.tokenId
        );
        // send payment to feeTo
        _paid(_paymentToken, feeTo, _commissionFromBuyer + order.commissionToSeller + _taxAmount);
        order.isOnsale = false;
        order.commissionFromBuyer = _commissionFromBuyer;
        orders[_orderId] = order;
        return true;
    }

    function callGetCategoryToken(uint256 _tokenId)
        private
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        (bool success, bytes memory data) = nFTAddress.call(
            abi.encodeWithSignature("getConfigToken(uint256)", _tokenId)
        );

        (
            uint256 _categoryId,
            uint256 _branchId,
            uint256 _collectionId
        ) = success ? abi.decode(data, (uint256, uint256, uint256)) : (0, 0, 0);
        return (_categoryId, _branchId, _collectionId);
    }

    function calBuyerCommission(BuyerCommissionInput memory _buyerCommission)
        private
        returns (BuyerCommissionOutput memory)
    {
        (
            uint256 _categoryId,
            uint256 _branchId,
            uint256 _collectionId
        ) = callGetCategoryToken(
                _buyerCommission.tokenId
            );
        uint256 _commission = getCommissionBuyer(
            _categoryId,
            _branchId,
            _collectionId,
            _buyerCommission.minter
        );

        BuyerCommissionOutput memory _buyerCommissionOutput;

        _buyerCommissionOutput.commissionFromBuyer = (_buyerCommission.amount * _commission) /
            ZOOM_FEE;
        _buyerCommissionOutput.amountToBuyer = _buyerCommission.amount + _buyerCommissionOutput.commissionFromBuyer;
        return _buyerCommissionOutput;
    }

    function calBuyerCommissionHasSign(
        BuyerCommissionInput memory _buyerCommission,
        TaxPromoCodeInfo memory _taxPromoCodeInfo,
        bytes memory _signature
    ) private returns (BuyerCommissionOutput memory) {
        require(_taxPromoCodeInfo.tax <= ZOOM_FEE, "Invalid tax");
        if (_taxPromoCodeInfo.isPercent) {
            require(
                _taxPromoCodeInfo.promoCodeNft <= ZOOM_FEE,
                "Invalid promoCodeNft"
            );
            require(
                _taxPromoCodeInfo.promoCodeServiceFee <= ZOOM_FEE,
                "Invalid promoCodeServiceFee"
            );
        }

        (
            uint256 _categoryId,
            uint256 _branchId,
            uint256 _collectionId
        ) = callGetCategoryToken(
                _buyerCommission.tokenId
            );
        uint256 _commission = getCommissionBuyer(
            _categoryId,
            _branchId,
            _collectionId,
            _buyerCommission.minter
        );

        BuyerCommissionOutput memory _buyerCommissionOutput;

        if (verifyMessage(_buyerCommission, _signature)) {
            if (_taxPromoCodeInfo.isPercent) {
                uint256 _commissionAmount = (_buyerCommission.amount *
                    _commission) / ZOOM_FEE;
                uint256 _buyerAmount = (_buyerCommission.amount *
                    (ZOOM_FEE - _taxPromoCodeInfo.promoCodeNft)) / ZOOM_FEE;
                _buyerCommissionOutput.commissionFromBuyer =
                    (((_commissionAmount *
                        (ZOOM_FEE - _taxPromoCodeInfo.promoCodeNft)) /
                        ZOOM_FEE) *
                        (ZOOM_FEE - _taxPromoCodeInfo.promoCodeServiceFee)) /
                    ZOOM_FEE;

                _buyerCommissionOutput.amountToBuyer =
                    _buyerAmount +
                    _buyerCommissionOutput.commissionFromBuyer;
                _buyerCommissionOutput.promocodeAmount =
                    _commissionAmount +
                    _buyerCommission.amount -
                    _buyerCommissionOutput.amountToBuyer;
            } else {
                uint256 _buyerAmount = _buyerCommission.amount >
                    _taxPromoCodeInfo.promoCodeNft
                    ? _buyerCommission.amount - _taxPromoCodeInfo.promoCodeNft
                    : 0;
                uint256 _commissionAmount = (_buyerAmount * _commission) /
                    ZOOM_FEE;
                _buyerCommissionOutput.commissionFromBuyer = _commissionAmount >
                    _taxPromoCodeInfo.promoCodeServiceFee
                    ? _commissionAmount - _taxPromoCodeInfo.promoCodeServiceFee
                    : 0;

                _buyerCommissionOutput.amountToBuyer =
                    _buyerAmount +
                    _buyerCommissionOutput.commissionFromBuyer;
                _buyerCommissionOutput.promocodeAmount =
                    _commissionAmount +
                    _buyerCommission.amount -
                    _buyerCommissionOutput.amountToBuyer;
            }

            if (_taxPromoCodeInfo.tax > 0) {
                _buyerCommissionOutput.taxAmount =
                    (_buyerCommissionOutput.amountToBuyer *
                        _taxPromoCodeInfo.tax) /
                    ZOOM_FEE;
                _buyerCommissionOutput.amountToBuyer += _buyerCommissionOutput
                    .taxAmount;
            }

            return _buyerCommissionOutput;
        }
        _buyerCommissionOutput.commissionFromBuyer =
            (_buyerCommission.amount * _commission) /
            ZOOM_FEE;
        _buyerCommissionOutput.amountToBuyer =
            _buyerCommission.amount +
            _buyerCommissionOutput.commissionFromBuyer;
        return _buyerCommissionOutput;
    }

    /**
     * @dev Allow user create order on market
     * @param _tokenId is id of NFTs
     * @param _price is price per item in payment method (example 50 USDT)
     * @param _paymentToken is payment method (USDT, BNB, ...)
     */
    function createOrder(
        address _paymentToken, // payment method
        uint256 _tokenId,
        uint256 _price, // price of 1 nft
        uint256 _expTime
    ) external whenNotPaused returns (uint256 _orderId) {
        require(
            paymentMethod[_paymentToken],
            "Payment-method-does-not-support"
        );

        require(_expTime > block.timestamp, "Invalid-expired-time");

        IERC721(nFTAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId
        );

        Order memory newOrder;
        newOrder.isOnsale = true;
        newOrder.owner = msg.sender;
        newOrder.price = _price;
        newOrder.tokenId = _tokenId;
        newOrder.paymentToken = _paymentToken;
        newOrder.expTime = _expTime;

        orders[totalOrders] = newOrder;
        _orderId = totalOrders;
        totalOrders++;
        bytes32 _id = keccak256(
            abi.encodePacked(nFTAddress, _tokenId, msg.sender)
        );
        orderID[_id] = _orderId;

        emit OrderCreated(
            _orderId,
            _tokenId,
            _price,
            _paymentToken,
            _expTime
        );
        return _orderId;
    }

    function buy(
        uint256 _orderId,
        address _paymentToken,
        TaxPromoCodeInfo memory _taxPromoCodeInfo,
        bytes calldata _signature
    ) external payable whenNotPaused returns (bool) {
        Order memory order = orders[_orderId];
        require(order.owner != address(0), "Invalid-order-id");
        require(
            _paymentToken == order.paymentToken,
            "Payment-method-does-not-support"
        );
        require(order.isOnsale, "Not-available-to-buy");
        require(order.expTime > block.timestamp, "Order-expired");

        uint256 orderAmount = order.price;
        BuyerCommissionOutput memory _buyerCommissionOutput = calBuyerCommissionHasSign(
                BuyerCommissionInput(
                    _orderId,
                    _paymentToken,
                    order.tokenId,
                    orderAmount,
                    msg.sender
                ),
                _taxPromoCodeInfo,
                _signature
            );

        if (_paymentToken == address(0) && msg.value > 0) {
            require(msg.value >= _buyerCommissionOutput.amountToBuyer, "Not-enough-to-buy");
        } else {
            IERC20(_paymentToken).safeTransferFrom(
                msg.sender,
                address(this),
                _buyerCommissionOutput.amountToBuyer
            );
        }

        emit Buy(
            _orderId,
            _paymentToken,
            _buyerCommissionOutput.amountToBuyer,
            _buyerCommissionOutput.promocodeAmount,
            _buyerCommissionOutput.taxAmount
        );
        uint256 _amountToSeller = _buyerCommissionOutput.amountToBuyer < orderAmount
            ? _buyerCommissionOutput.amountToBuyer
            : orderAmount;
        return
            _match(
                msg.sender,
                _paymentToken,
                _orderId,
                _amountToSeller,
                _buyerCommissionOutput.commissionFromBuyer,
                _buyerCommissionOutput.taxAmount
            );
    }

    function createBid(
        address _paymentToken, // payment method
        uint256 _tokenId,
        uint256 _price, // price of 1 nft
        uint256 _expTime
    ) external payable whenNotPaused returns (uint256 _bidId) {
        bytes32 _id = keccak256(
            abi.encodePacked(nFTAddress, _tokenId, msg.sender)
        );
        require(!isBid[_id], "User-has-bid");
        require(
            paymentMethod[_paymentToken],
            "Payment-method-does-not-support"
        );
        require(_expTime > block.timestamp, "Invalid-expired-time");
        Bid memory newBid;
        newBid.bidder = msg.sender;
        newBid.bidPrice = _price;
        newBid.tokenId = _tokenId;

        BuyerCommissionOutput memory _buyerCommissionOutput = calBuyerCommission(
                BuyerCommissionInput(
                    0,
                    _paymentToken,
                    _tokenId,
                    _price,
                    msg.sender
                )
            );

        if (msg.value > 0) {
            require(msg.value >= _buyerCommissionOutput.amountToBuyer, "Invalid-amount");
            newBid.paymentToken = address(0);
        } else {
            newBid.paymentToken = _paymentToken;
            IERC20(newBid.paymentToken).safeTransferFrom(
                msg.sender,
                address(this),
                _buyerCommissionOutput.amountToBuyer
            );
        }

        newBid.commissionFromBuyer = _buyerCommissionOutput.commissionFromBuyer;
        newBid.status = true;
        newBid.expTime = _expTime;
        bids[totalBids] = newBid;
        _bidId = totalBids;
        totalBids++;

        isBid[_id] = true;

        emit BidCreated(
            _bidId,
            _tokenId,
            _buyerCommissionOutput.amountToBuyer,
            newBid.paymentToken,
            _expTime
        );
        return _bidId;
    }

    function acceptBid(uint256 _bidId) external whenNotPaused returns (bool) {
        Bid memory bid = bids[_bidId];
        require(bid.status, "Invalid-quantity-or-bid-cancelled");
        require(bid.expTime > block.timestamp, "Bid-expired");

        bytes32 _id = keccak256(
            abi.encodePacked(nFTAddress, bid.tokenId, msg.sender)
        );
        uint256 _orderId = orderID[_id];
        Order memory order = orders[_orderId];
        require(
            order.owner == msg.sender && order.isOnsale,
            "Oops!Wrong-order-owner-or-cancelled"
        );
        require(order.expTime > block.timestamp, "Order-expired");
        
        emit AcceptBid(_bidId);
        bid.status = false;
        bids[_bidId] = bid;

        isBid[_id] = false;

        return
            _match(
                bid.bidder,
                bid.paymentToken,
                _orderId,
                bid.bidPrice,
                bid.commissionFromBuyer,
                0
            );
    }

    function cancelOrder(uint256 _orderId) external whenNotPaused {
        Order memory order = orders[_orderId];
        require(
            order.owner == msg.sender && order.isOnsale,
            "Oops!Wrong-order-owner-or-cancelled"
        );
        IERC721(nFTAddress).safeTransferFrom(
            address(this),
            order.owner,
            order.tokenId
        );

        order.isOnsale = false;
        orders[_orderId] = order;
        emit OrderCancelled(_orderId);
    }

    function cancelBid(uint256 _bidId) external whenNotPaused nonReentrant {
        Bid memory bid = bids[_bidId];
        require(bid.bidder == msg.sender, "Invalid-bidder");
        require(bid.status, "Bid-cancelled-or-accepted");
        bytes32 _id = keccak256(
            abi.encodePacked(nFTAddress, bid.tokenId, msg.sender)
        );
        uint256 payBackAmount = bid.bidPrice + bid.commissionFromBuyer;
        if (payBackAmount > 0) {
            if (bid.paymentToken != address(0)) {
                IERC20(bid.paymentToken).safeTransfer(
                    bid.bidder,
                    payBackAmount
                );
            } else {
                payable(msg.sender).sendValue(payBackAmount);
            }
        }
        bid.status = false;
        bids[_bidId] = bid;

        isBid[_id] = false;

        emit BidCancelled(_bidId);
    }

    function updateOrder(uint256 _orderId, uint256 _price, uint256 _expTime)
        external
        whenNotPaused
    {
        Order memory order = orders[_orderId];
        require(
            order.owner == msg.sender && order.isOnsale,
            "Oops!Wrong-order-owner-or-cancelled"
        );
        require(order.expTime > block.timestamp, "Order-expired");
        require(order.price != _price || order.expTime != _expTime, "Invalid-update-info");
        
        if(order.expTime != _expTime){
            require(_expTime > block.timestamp, "Invalid-expired-time");
            order.expTime = _expTime;
        }
        
        if(order.price != _price){
            order.price = _price;
        }

        orders[_orderId] = order;
        emit OrderUpdated(_orderId);
    }

    function updateBid(uint256 _bidId, uint256 _bidPrice, uint256 _expTime)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        Bid memory bid = bids[_bidId];
        require(bid.bidder == msg.sender, "Invalid-bidder");
        require(bid.status, "Bid-cancelled-or-accepted");
        require(bid.expTime > block.timestamp, "Bid-expired");
        require(bid.bidPrice != _bidPrice || bid.expTime != _expTime, "Invalid-update-info");

        if(bid.expTime != _expTime){
            require(_expTime > block.timestamp, "Invalid-expired-time");
            bid.expTime = _expTime;
        }

        if(bid.bidPrice != _bidPrice){
            BuyerCommissionOutput memory _buyerCommissionOutput = calBuyerCommission(
                BuyerCommissionInput(
                    0,
                    bid.paymentToken,
                    bid.tokenId,
                    _bidPrice,
                    msg.sender
                )
            );
            uint256 _amountToBuyerOld = bid.bidPrice + bid.commissionFromBuyer;

            bool isExcess = _amountToBuyerOld > _buyerCommissionOutput.amountToBuyer;
            uint256 amount = isExcess
                ? _amountToBuyerOld - _buyerCommissionOutput.amountToBuyer
                : _buyerCommissionOutput.amountToBuyer - _amountToBuyerOld;

            if (bid.paymentToken != address(0)) {
                if (isExcess) {
                    IERC20(bid.paymentToken).safeTransfer(bid.bidder, amount);
                } else {
                    IERC20(bid.paymentToken).safeTransferFrom(
                        bid.bidder,
                        address(this),
                        amount
                    );
                }
            } else {
                if (isExcess) {
                    payable(msg.sender).sendValue(amount);
                } else {
                    require(msg.value >= amount, "Invalid-amount");
                }
            }

            bid.bidPrice = _bidPrice;
            bid.commissionFromBuyer = _buyerCommissionOutput.commissionFromBuyer;
        }
        
        bids[_bidId] = bid;
        emit BidUpdated(_bidId);
    }

    function verifyMessage(
        BuyerCommissionInput memory _buyerCommission,
        bytes memory signature
    ) public view returns (bool) {
        if (signature.length == 0) return false;
        bytes32 dataHash = encodeData(
            _buyerCommission.orderId,
            nFTAddress,
            _buyerCommission.paymentToken,
            _buyerCommission.tokenId
        );
        bytes32 signHash = ECDSA.toEthSignedMessageHash(dataHash);
        address recovered = ECDSA.recover(signHash, signature);
        return recovered == verifier;
    }

    function encodeData(
        uint256 _orderId,
        address _token,
        address _paymentToken,
        uint256 _tokenId
    ) public view returns (bytes32) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return
            keccak256(
                abi.encode(id, _orderId, _token, _paymentToken, _tokenId)
            );
    }

    function setApproveForAll(address _token, address _spender)
        external
        onlyOwner
    {
        IERC721(_token).setApprovalForAll(_spender, true);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}