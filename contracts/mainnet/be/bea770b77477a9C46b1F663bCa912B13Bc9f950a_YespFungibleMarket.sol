//Custom NFT Marketplace Contract, for trading ERC1155 collections on the Yesports Digital Marketplace.

pragma solidity ^0.8.9;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./YespMarketUtils.sol";

import "./interface/IWETH.sol";
import "./interface/IYespFeeProcessor.sol";

// General
error YESP_NotOwnerOrAdmin();
error YESP_TradingPaused();
error YESP_CollectionNotEnabled();

// Trade Creation
error YESP_NoEscrowedSell();
error YESP_ZeroPrice();
error YESP_BuyerAccountUnderfunded();
error YESP_EscrowCurrencyUnderfunded();
error YESP_SellAssetBalanceLow();
error YESP_ContractNotApproved();
error YESP_PaymentTokenNotApproved();

// Trade Fulfillment
error YESP_OrderExpired();
error YESP_OrderDoesNotExist();
error YESP_NotAuthorized();
error YESP_TradeNotPartialFill();
error YESP_NotEnoughTokensToFulfillBuy();
error YESP_NotEnoughInEscrow();
error YESP_NotEnoughSellerAllowance();
error YESP_NotEnoughMakerFunds();
error YESP_AmountOverQuantity();
error YESP_NotEnoughTokensToFulfill();
error YESP_SellFulfillUnderfunded();
error YESP_BuyOrderWithValue();
error YESP_TransferFailed();

// Escrow
error YESP_EscrowOverWithdraw();
error YESP_WithdrawNotEnabled();

// Util
error YESP_IntegerOverFlow();

contract YespFungibleMarket is ReentrancyGuard, Ownable {
    using YespMarketUtils for bytes32[];

    event TradeOpened( bytes32 indexed tradeId, address indexed token, uint256 indexed tokenId, uint256 quantity, uint256 price, address maker, uint256 expiry, uint256 timestamp, TradeFlags tradeFlags);
    event TradeAccepted(bytes32 indexed tradeId, address indexed token, uint256 indexed tokenId, uint256 quantity, uint256 price, address oldOwner, address newOwner, TradeType tradeType, uint256 expiry, uint256 timestamp);
    event TradeCancelled( bytes32 indexed tradeId, address indexed token,  uint256 indexed tokenId, uint256 quantity, uint256 price, address maker, uint256 expiry, uint256 timestamp, TradeFlags tradeFlags);
    event EscrowReturned(address indexed user, uint256 indexed price);
    event CollectionModified(address indexed token, bool indexed enabled, address indexed owner, uint256 collectionOwnerFee, uint256 timestamp);

    uint256 constant MAX_INT = ~uint256(0);
    uint128 constant SMOL_MAX_INT = ~uint128(0);
    uint128 constant SMOLLER_MAX_INT = ~uint64(0);

    // Fees are out of 10000, to allow for 0.1% stepped fees.
    uint256 public defaultCollectionOwnerFee; //0%
    uint256 public totalEscrowedAmount;
    uint256 public nonce = 1;

    IWETH public TOKEN; //WETH
    IYespFeeProcessor public YespFeeProcessor;

    //
    enum TradeType { BUY, SELL }

    struct TradeFlags {
        TradeType tradeType;
        bool allowPartialFills;
        bool isEscrowed;
    }

    struct Trade {
        uint256 tokenId;
        uint256 quantity;
        uint128 price;
        uint64 expiry;
        uint64 posInUserRegister;
        address ca;
        address maker;
        TradeFlags tradeFlags;
    }

    // Admin flags
    bool public tradingPaused = false;
    bool public feesOn = true;
    bool public collectionOwnersCanSetRoyalties = true;
    bool public usersCanWithdrawEscrow = false; // admin controlled manual escape hatch. users can always withdraw by cancelling offers.

    // Collection / Order / Escrow / Admin data storage 
    mapping(address => bool) public collectionTradingEnabled;
    mapping(address => address) public collectionOwners;
    mapping(address => uint256) public collectionOwnerFees;
    mapping(address => uint256) public totalInEscrow;
    mapping(address => bool) public administrators;
    mapping(bytes32 => Trade) public trades;
    mapping(address => bytes32[]) sellOrdersByUser;
    mapping(address => bytes32[]) buyOrdersByUser;

    function getSellOrdersByUser(address user) external view returns(bytes32[] memory orderHashes) {
        orderHashes = sellOrdersByUser[user];
    }

    function getBuyOrdersByUser(address user) external view returns(bytes32[] memory orderHashes) {
        orderHashes = buyOrdersByUser[user];
    }

    constructor(address _token, address _yespFeeProcessor) {
        TOKEN = IWETH(_token);
        YespFeeProcessor = IYespFeeProcessor(_yespFeeProcessor);
        administrators[msg.sender] = true;
    }

    modifier onlyAdmins() {
        if (!(administrators[_msgSender()] || owner() == _msgSender()))
            revert YESP_NotOwnerOrAdmin();
        _;
    }

    //---------------------------------
    //
    //            TRADES
    //
    //---------------------------------
    /**
     * @dev Opens a buy or sell order
     * @param ca Contract address of 1155 to list
     * @param tokenId `tokenId` of 1155 on `ca` to list
     * @param quantity quantity of `tokenId` to list
     * @param price price per token, where price for the entire listing equals `price` * `quantity`
     * @param expiry timestamp for order expiry
     * @param tradeFlags tradeflag struct to determine trade type (buy/sell), allow partial fills
     *        flag, and whether or not the trade is escrowed (requires submission of ETH, only for
     *        open buy orders)
     */
    function openTrade(address ca, uint256 tokenId, uint256 quantity, uint256 price, uint256 expiry, TradeFlags calldata tradeFlags) external payable nonReentrant {
        // Common checks
        if (tradingPaused) revert YESP_TradingPaused();
        if (!collectionTradingEnabled[ca]) revert YESP_CollectionNotEnabled();
        if (expiry != 0 && expiry < block.timestamp) revert YESP_OrderExpired();
        if (price == 0) revert YESP_ZeroPrice();
        if (price > SMOL_MAX_INT || expiry > SMOLLER_MAX_INT) revert YESP_IntegerOverFlow();

        // Validate for buy or sell
        if (tradeFlags.tradeType == TradeType.BUY) {
            uint256 totalPrice = price * quantity;
            _validateBuyOrder(totalPrice, tradeFlags);
            if (tradeFlags.isEscrowed) {
                totalEscrowedAmount += totalPrice;
                totalInEscrow[msg.sender] += totalPrice;
            }
        } else {
            _validateSellOrder(ca, msg.sender, tokenId, quantity, tradeFlags);
        }

        bytes32 tradeId = _buildTradeId(msg.sender);
        uint256 posInRegister;

        if (tradeFlags.tradeType == TradeType.BUY) {
            posInRegister = buyOrdersByUser[msg.sender].length;
            buyOrdersByUser[msg.sender].push(tradeId);
        } else {
            posInRegister = sellOrdersByUser[msg.sender].length;
            sellOrdersByUser[msg.sender].push(tradeId);
        }

        trades[tradeId] = Trade(tokenId, quantity, uint128(price), uint64(expiry), uint64(posInRegister), ca, msg.sender, tradeFlags);
        emit TradeOpened(tradeId, ca, tokenId, quantity, price, msg.sender, expiry, block.timestamp, tradeFlags);
    }

    // Cancel a trade that the sender initiated. 
    function cancelTrade(bytes32 tradeId) external nonReentrant {
        // Validate that trade can be cancelled.
        Trade memory _trade = trades[tradeId];
        if (_trade.price == 0) revert YESP_OrderDoesNotExist();

        // If this is an escrowed offer, we want to limit who can cancel it to the trade creator and admins, for unexpected-eth-pushing-is-bad security reasons.
        // If it's not escrowed (and won't cause eth to go flying around), then the public can cancel offers that have expired.
        bool privilegedDeletoooor = _trade.maker == msg.sender || administrators[msg.sender];
        bool expiredNonEscrowedTrade = !_trade.tradeFlags.isEscrowed && (_trade.expiry != 0 && _trade.expiry < block.timestamp);
        if (!privilegedDeletoooor && !expiredNonEscrowedTrade) revert YESP_NotAuthorized(); 

        uint256 totalPrice = _trade.price * _trade.quantity;

        // Check if valid return of escrowed funds
        if ((_trade.tradeFlags.isEscrowed) && (totalInEscrow[_trade.maker] < totalPrice || totalEscrowedAmount < totalPrice) ) revert YESP_EscrowOverWithdraw();

        // Cleanup data structures
        delete trades[tradeId];
        if (_trade.tradeFlags.tradeType == TradeType.BUY) {
            buyOrdersByUser[_trade.maker].swapPop(_trade.posInUserRegister);
        } else if (_trade.tradeFlags.tradeType == TradeType.SELL) {
            sellOrdersByUser[_trade.maker].swapPop(_trade.posInUserRegister);
        }

        //Return escrowed funds if necessary. `_trade.tradeFlags.isEscrowed` should never have a value if the order type is a sell.
        if (_trade.tradeFlags.isEscrowed) _returnEscrow(_trade.maker, totalPrice);

        emit TradeCancelled(tradeId, _trade.ca, _trade.tokenId, _trade.quantity, _trade.price, _trade.maker, _trade.expiry, block.timestamp, _trade.tradeFlags);
    }

    // Called to accept any open, valid, unexpired trade, whether it's a buy or a sell.
    function acceptTrade(bytes32 tradeId, uint256 amount) external payable nonReentrant {
        if (tradingPaused) revert YESP_TradingPaused();

        Trade memory _trade = trades[tradeId];

        if (!collectionTradingEnabled[_trade.ca]) revert YESP_CollectionNotEnabled();
        if (_trade.price == 0) revert YESP_OrderDoesNotExist();
        if (_trade.expiry != 0 && _trade.expiry < block.timestamp) revert YESP_OrderExpired();
        if (!_trade.tradeFlags.allowPartialFills && amount != _trade.quantity) revert YESP_TradeNotPartialFill();
        if (amount > _trade.quantity) revert YESP_AmountOverQuantity();

        uint256 totalPrice = _trade.price * amount;

        // Depending on whether this was initially a buy or sell order, set the seller and purchaser accordingly.
        (address seller, address purchaser) = (_trade.tradeFlags.tradeType == TradeType.SELL) ? (_trade.maker, msg.sender) : (msg.sender, _trade.maker);

        if (_trade.tradeFlags.tradeType == TradeType.SELL) {
            _fulfillSellOrder(tradeId, _trade, seller, purchaser, totalPrice, amount);
        } else if (_trade.tradeFlags.tradeType == TradeType.BUY) {
            _fulfillBuyOrder(tradeId, _trade, seller, purchaser, totalPrice, amount);
        } else {
            revert("Trade in invalid state.");
        }

        emit TradeAccepted(tradeId, _trade.ca, _trade.tokenId, amount, _trade.price, seller, purchaser, _trade.tradeFlags.tradeType, _trade.expiry, block.timestamp);
    }

    function _validateSellOrder(address ca, address maker, uint256 tokenId, uint256 quantity, TradeFlags memory tradeFlags) internal view {
        if (IERC1155(ca).balanceOf(maker, tokenId) < quantity) revert YESP_SellAssetBalanceLow(); // Non Fungible? Ser those are non-existent.
        if (!IERC1155(ca).isApprovedForAll(maker, address(this))) revert YESP_ContractNotApproved(); // Need a lil' trust in this working relationship.
        if (tradeFlags.isEscrowed) revert YESP_NoEscrowedSell(); // We don't tokens out of your wallet. Screw that.
    }

    function _validateBuyOrder(uint256 totalPrice, TradeFlags memory tradeFlags ) internal view {
        // Escrowed bid - didn't send enough ETH for requested quantity.
        if (tradeFlags.isEscrowed && msg.value < totalPrice) revert YESP_EscrowCurrencyUnderfunded();
        // Non-escrowed bid - didn't set allowance for marketplace contract.
        if (!tradeFlags.isEscrowed && TOKEN.allowance(msg.sender, address(this)) < totalPrice) revert YESP_PaymentTokenNotApproved();
        // Non-escrowed bid - ur a broke boi or non-boi.
        if (!tradeFlags.isEscrowed && TOKEN.balanceOf(msg.sender) < totalPrice) revert YESP_BuyerAccountUnderfunded();
    }

    function _buildTradeId(address user) internal returns (bytes32 tradeId) {
      unchecked {++nonce;}
      tradeId = keccak256(
          abi.encodePacked(user, block.timestamp, nonce)
      );
    }

    function _processFees( address ca,  uint256 amount, address oldOwner, address newOwner) private {
        if (feesOn) {
            (uint256 totalAdminFeeAmount, uint256 collectionOwnerFeeAmount, uint256 remainder) = _calculateAmounts(ca, amount, oldOwner, newOwner);
            _sendEth(oldOwner, remainder);
            if (collectionOwnerFeeAmount != 0) _sendEth(collectionOwners[ca], collectionOwnerFeeAmount);
            if (totalAdminFeeAmount != 0) _sendEth(address(YespFeeProcessor), totalAdminFeeAmount);
        } else {
            _sendEth(oldOwner, amount);
        }
    }

    //---------------------------------
    //
    //      PUBLIC GETTERS + ESCROW
    //
    //---------------------------------
    function addMoneyToEscrow() external payable nonReentrant {
        if (!usersCanWithdrawEscrow) revert YESP_WithdrawNotEnabled();
        totalEscrowedAmount += msg.value;
        totalInEscrow[msg.sender] += msg.value;
    }

    function withdrawMoneyFromEscrow(uint256 amount) external nonReentrant {
        if (!usersCanWithdrawEscrow) revert YESP_WithdrawNotEnabled();
        if (totalInEscrow[msg.sender] < amount) revert YESP_EscrowOverWithdraw();
        _returnEscrow(msg.sender, amount);
    }

    function getEscrowedAmount(address user) external view returns (uint256) {
        return totalInEscrow[user];
    }

    function getCollectionOwner(address ca) external view returns (address) {
        return collectionOwners[ca];
    }

    function computeOrderHash(address user, address token, uint256 tokenId, uint256 userNonce) public view returns (bytes32 offerHash) {
        return keccak256(abi.encode(user, token, tokenId, userNonce, block.timestamp));
    }

    // Marketplace platform fee calc checks whichever trader (maker/taker) has a higher stake / more of a discount.
    function totalAdminFees(address seller, address purchaser) public view returns(uint256 totalFee) {
        totalFee = Math.min(YespFeeProcessor.getTotalFee(seller), YespFeeProcessor.getTotalFee(purchaser));
    }

    function checkEscrowAmount(address user) external view returns (uint256) {
        return totalInEscrow[user];
    }

    function isCollectionTrading(address ca) external view returns (bool) {
        return collectionTradingEnabled[ca];
    }

    function getCollectionFee(address ca) external view returns (uint256) {
        return collectionOwnerFees[ca];
    }

    function getTrade(bytes32 tradeID) public view returns (Trade memory) {
        return trades[tradeID];
    }

    function isValidTrade(bytes32 tradeID) external view returns (bool validTrade) {
        Trade memory trade = getTrade(tradeID);
        IERC1155 token = IERC1155(trade.ca);
        //if selling tokens, valid if seller has approved tokens for sale
        bool tokenApproved = trade.tradeFlags.tradeType == TradeType.SELL ? token.isApprovedForAll(trade.maker, address(this)) : true;
        validTrade = (trade.expiry > block.timestamp || trade.expiry == 0) && tokenApproved;
    }

    //---------------------------------
    //
    //        ADMIN FUNCTIONS
    //
    //---------------------------------
    function setAdmin(address admin, bool value) external onlyOwner {
        administrators[admin] = value;
    }

    function setTrading(bool value) external onlyOwner {
        require(tradingPaused != value, "Already set to that value.");
        tradingPaused = value;
    }

    function setCollectionTrading(address ca, bool value) external onlyAdmins {
        require(collectionTradingEnabled[ca] != value, "Already set to that value.");
        collectionTradingEnabled[ca] = value;
    }

    function setCollectionOwner(address ca, address _owner) external onlyAdmins {
        collectionOwners[ca] = _owner;
    }

    function setCollectionOwnerFee(address ca, uint256 fee) external {
        bool verifiedCollectionOwner = collectionOwnersCanSetRoyalties && (_msgSender() == collectionOwners[ca]);
        require(_msgSender() == owner() || verifiedCollectionOwner);
        require(fee <= 1000, "Max 10% fee");
        collectionOwnerFees[ca] = fee;
    }

    // Convenience function for listing / ~Partially~ implements EIP2981
    function listCollection(address ca, bool tradingEnabled, address _royaltyWallet, uint256 _fee) external onlyAdmins {
        uint256 fee = _fee;
        address royaltyWallet = _royaltyWallet;
        if (IERC165(ca).supportsInterface(0x2a55205a)) {
            (address receiver, uint256 royaltyAmount) = IERC2981(ca).royaltyInfo(1, 1 ether);
            royaltyWallet = receiver;
            fee = (10000 * royaltyAmount / 1 ether) >= 1000 ? 1000 : 10000 * royaltyAmount / 1 ether;
        }

        collectionTradingEnabled[ca] = tradingEnabled;
        collectionOwners[ca] = royaltyWallet;
        collectionOwnerFees[ca] = fee;
        emit CollectionModified(ca, tradingEnabled, _royaltyWallet, _fee, block.timestamp);
    }

    function setDefaultCollectionOwnerFee(uint256 fee) external onlyOwner {
        require(fee <= 1000, "Max 10% fee");
        defaultCollectionOwnerFee = fee;
    }

    function setFeesOn(bool _value) external onlyOwner {
        feesOn = _value;
    }

    function setCollectionOwnersCanSetRoyalties(bool _value) external onlyOwner {
        collectionOwnersCanSetRoyalties = _value;
    }

    // Emergency only - Recover Tokens
    function recoverToken(address _token, uint256 amount) external onlyOwner {
        IERC20(_token).transfer(owner(), amount);
    }

    // Emergency only - Recover 1155s
    function recover1155(address _token, uint256 tokenId, uint256 amount) external onlyOwner {
        IERC1155(_token).safeTransferFrom(address(this), owner(), tokenId, amount, "");
    }

    // Emergency only - Recover ETH/MOVR/GLMR/WHATEVER
    function recoverGAS(address to, uint256 amount) external onlyOwner {
        _sendEth(to, amount);
    }

    //---------------------------------
    //
    //        PRIVATE HELPERS
    //
    //---------------------------------

    function _fulfillSellOrder(bytes32 tradeId, Trade memory _trade, address seller, address purchaser, uint256 totalPrice, uint256 amount) internal {
        // Check allowance and balance of token seller and verify that buyer sent enough ETH.
        if (!IERC1155(_trade.ca).isApprovedForAll(seller, address(this))) revert YESP_ContractNotApproved();
        if (IERC1155(_trade.ca).balanceOf(seller, _trade.tokenId) < amount) revert YESP_NotEnoughTokensToFulfill();
        if (msg.value < totalPrice) revert YESP_SellFulfillUnderfunded();

        // We validate that amount < quantity in acceptTrade.
        uint256 remainingQuantity = _trade.quantity - amount;

        if (remainingQuantity == 0) {
            sellOrdersByUser[_trade.maker].swapPop(_trade.posInUserRegister);
            delete trades[tradeId];
        } else {
            trades[tradeId].quantity -= amount;
        }

        IERC1155(_trade.ca).safeTransferFrom(seller, purchaser, _trade.tokenId, amount, "");
        _processFees(_trade.ca, totalPrice, seller, purchaser);
    }

    // Could use a future refactor to make escrow and non-escrow arms less interwoven.
    function _fulfillBuyOrder(bytes32 tradeId, Trade memory _trade, address seller, address purchaser, uint256 totalPrice, uint256 amount) internal {
        // Check allowance and balance of token seller and buy order fultiller (trade maker).
        if (msg.value > 0) revert YESP_BuyOrderWithValue();
        if (!IERC1155(_trade.ca).isApprovedForAll(seller, address(this))) revert YESP_ContractNotApproved();
        if (IERC1155(_trade.ca).balanceOf(seller, _trade.tokenId) < amount) revert YESP_NotEnoughTokensToFulfill();
        
        if (_trade.tradeFlags.isEscrowed) {
            // Escrow only logic - validate that trade maker either has enough escrowed funds. 
            if (totalInEscrow[_trade.maker] < totalPrice) revert YESP_NotEnoughInEscrow();
            totalEscrowedAmount -= totalPrice;
            totalInEscrow[purchaser] -= totalPrice;
        } else {
            // Non-Escrowed checks - validated that trademaker has enough WETH and the marketplace has a sufficient WETH allowance.
            if (TOKEN.balanceOf(_trade.maker) < totalPrice) revert YESP_NotEnoughMakerFunds();
            if (TOKEN.allowance(_trade.maker, address(this)) < totalPrice) revert YESP_NotEnoughSellerAllowance();
        }

        uint256 remainingQuantity = _trade.quantity - amount;

        if (remainingQuantity == 0) {
            buyOrdersByUser[_trade.maker].swapPop(_trade.posInUserRegister);
            delete trades[tradeId];
        } else {
            trades[tradeId].quantity -= amount;
        }

        IERC1155(_trade.ca).safeTransferFrom(seller, purchaser, _trade.tokenId, amount, "");
        
        if (_trade.tradeFlags.isEscrowed) {
            _processFees(_trade.ca, totalPrice, seller, purchaser);
        } else {
            bool success = TOKEN.transferFrom(purchaser, address(this), totalPrice);
            if (!success) revert YESP_TransferFailed();
            TOKEN.withdraw(totalPrice);
            _processFees(_trade.ca, totalPrice, seller, purchaser);
        }
    }

    // I love you, you love me, we're a happy fee-mily
    function _calculateAmounts(address ca, uint256 amount, address oldOwner, address newOwner) private view returns (uint256, uint256, uint256) {
        uint256 _collectionOwnerFee = collectionOwnerFees[ca] == 0
            ? defaultCollectionOwnerFee
            : collectionOwnerFees[ca];

        uint256 totalAdminFee = (amount * totalAdminFees(oldOwner, newOwner)) / 10000;
        uint256 collectionOwnerFeeAmount = (amount * _collectionOwnerFee) / 10000;
        uint256 remainder = amount - (totalAdminFee + collectionOwnerFeeAmount);
        return (totalAdminFee, collectionOwnerFeeAmount, remainder);
    }

    function _returnEscrow(address user, uint256 amount) private {
        totalEscrowedAmount -= amount;
        totalInEscrow[user] -= amount;
        _sendEth(user, amount);
        emit EscrowReturned(user, amount);
    }

    function _sendEth(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    // Required in order to receive MOVR/GLMR.
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

pragma solidity ^0.8.14;

library YespMarketUtils {
    function swapPop(bytes32[] storage self, uint256 index) internal {
        self[index] = self[self.length-1];
        self.pop();
    }

    function swapPop(address[] storage self, uint256 index) internal {
        self[index] = self[self.length-1];
        self.pop();
    }
}

pragma solidity >=0.4.18;

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256) external;
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function balanceOf(address) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

pragma solidity ^0.8.0;

interface IYespFeeProcessor {
    function devFee() external view returns(uint256);
    function secondaryFee() external view returns(uint256);
    function tertiaryFee() external view returns(uint256);
    function totalFee() external view returns(uint256);
    function getTotalFee(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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