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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./Manage/DePOFeeManage.sol";
import "./Manage/DePOOfferManage.sol";

contract DePO is DePOFeeManage, DePOOfferManage {

    constructor(
        uint256 initSellerFee,
        uint256 initTakerFee,
        address initFeeReceiver
    ) DePOFeeManage(initSellerFee, initTakerFee, initFeeReceiver) {

    }
}

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract DePOCountryDictionary is Ownable {
    using Counters for Counters.Counter;

    // Available Countries
    struct Country {
        uint256 id;
        string code;
        bool available;
    }

    Counters.Counter private _countryCounter;
    mapping(uint256 => Country) private _countries;

    event CountryAdded(uint256 id, address owner);
    event CountryDisabled(uint256 id, address owner);
    event CountryEnabled(uint256 id, address owner);

    // Country methods
    function addCountry(string memory code) public onlyOwner() returns (uint256){
        _countryCounter.increment();
        uint256 countryId = _countryCounter.current();

        Country memory country = Country(countryId, code, true);
        _countries[countryId] = country;

        emit CountryAdded(countryId, _msgSender());

        return countryId;
    }

    function disableCountry(uint256 countryId) public onlyOwner() {
        _countries[countryId].available = false;

        emit CountryDisabled(countryId, _msgSender());
    }

    function enableCountry(uint256 countryId) public onlyOwner() {
        _countries[countryId].available = true;

        emit CountryEnabled(countryId, _msgSender());
    }

    function getCountry(uint256 countryId) public view returns (Country memory){
        return _countries[countryId];
    }
}

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./DePOCountryDictionary.sol";

abstract contract DePOCurrencyDictionary is DePOCountryDictionary {
    using Counters for Counters.Counter;

    // Available currencies for country
    struct Currency {
        uint256 id;
        uint256 countryId;
        string currencyName;
        bool available;
    }

    Counters.Counter private _currencyCounter;
    // countryId => currencyId => Currency
    mapping(uint256 => mapping(uint256 => Currency)) private _currencies;

    event CurrencyAdded(uint256 id, uint256 countryId, address owner);
    event CurrencyDisabled(uint256 id, uint256 countryId, address owner);
    event CurrencyEnabled(uint256 id, uint256 countryId, address owner);

    // Currency methods
    function addCurrency(uint256 countryId, string memory name) public onlyOwner() returns (uint256){
        _currencyCounter.increment();
        uint256 currencyId = _currencyCounter.current();

        require(getCountry(countryId).available, "Country is not available");

        Currency memory currency = Currency(currencyId, countryId, name, true);
        _currencies[countryId][currencyId] = currency;

        emit CurrencyAdded(currencyId, countryId, _msgSender());

        return currencyId;
    }

    function disableCurrency(uint256 countryId, uint256 currencyId) public onlyOwner() {
        _currencies[countryId][currencyId].available = false;

        emit CurrencyDisabled(currencyId, countryId, _msgSender());
    }

    function enableCurrency(uint256 countryId, uint256 currencyId) public onlyOwner() {
        _currencies[countryId][currencyId].available = true;

        emit CurrencyEnabled(currencyId, countryId, _msgSender());
    }

    function getCurrency(uint256 countryId, uint256 currencyId) public view returns (Currency memory){
        return _currencies[countryId][currencyId];
    }
}

pragma solidity ^0.8.0;

import "./DePOPaymentMethodsDictionary.sol";
import "./DePOCountryDictionary.sol";
import "./DePOCurrencyDictionary.sol";
import "./DePOPaymentMethodsDictionary.sol";
import "./DePOTokenDictionary.sol";

abstract contract DePODictionary is DePOCountryDictionary, DePOCurrencyDictionary, DePOPaymentMethodsDictionary, DePOTokenDictionary{
}

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./DePOCountryDictionary.sol";

abstract contract DePOPaymentMethodsDictionary is DePOCountryDictionary {
    using Counters for Counters.Counter;

    // Available payment methods for each country
    struct PaymentMethod {
        uint256 id;
        uint256 countryId;
        string methodName;
        bool available;
    }

    mapping(uint256 => Counters.Counter) private _paymentMethodCounter;
    // countryId => paymentMethodId => PaymentMethod
    mapping(uint256 => mapping(uint256 => PaymentMethod)) private _paymentMethods;

    event PaymentMethodAdded(uint256 id, uint256 countryId, address owner);
    event PaymentMethodDisabled(uint256 id, uint256 countryId, address owner);
    event PaymentMethodEnabled(uint256 id, uint256 countryId, address owner);

    // Payment methods
    function addPaymentMethod(uint256 countryId, string memory name) public onlyOwner() returns (uint256){
        _paymentMethodCounter[countryId].increment();
        uint256 paymentMethodId = _paymentMethodCounter[countryId].current();

        require(getCountry(countryId).available, "Country is not available");

        PaymentMethod memory paymentMethod = PaymentMethod(paymentMethodId, countryId, name, true);
        _paymentMethods[countryId][paymentMethodId] = paymentMethod;

        emit PaymentMethodAdded(paymentMethodId, countryId, _msgSender());

        return paymentMethodId;
    }

    function disablePaymentMethod(uint256 countryId, uint256 paymentMethodId) public onlyOwner() {
        _paymentMethods[countryId][paymentMethodId].available = false;

        emit PaymentMethodDisabled(paymentMethodId, countryId, _msgSender());
    }

    function enablePaymentMethod(uint256 countryId, uint256 paymentMethodId) public onlyOwner() {
        _paymentMethods[countryId][paymentMethodId].available = true;

        emit PaymentMethodEnabled(paymentMethodId, countryId, _msgSender());
    }

    function getPaymentMethod(uint256 countryId, uint256 paymentMethodId) public view returns (PaymentMethod memory){
        return _paymentMethods[countryId][paymentMethodId];
    }
}

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract DePOTokenDictionary is Ownable {
    using Counters for Counters.Counter;

    // Available Tokens
    struct Token {
        uint256 id;
        address contractAddress;
        string name;
        string tag;
        bool available;
    }

    Counters.Counter private _tokenCounter;
    mapping(uint256 => Token) private _tokens;

    event TokenAdded(uint256 id, address owner);
    event TokenDisabled(uint256 id, address owner);
    event TokenEnabled(uint256 id, address owner);

    // Tokens methods
    function addToken(address contractAddress, string memory name, string memory tag) public onlyOwner() returns (uint256){
        _tokenCounter.increment();
        uint256 tokenId = _tokenCounter.current();

        // Check that the address is ERC20 Token
        IERC20 tokenERC20 = IERC20(contractAddress);

        Token memory token = Token(tokenId, contractAddress, name, tag, true);
        _tokens[tokenId] = token;

        emit TokenAdded(tokenId, _msgSender());

        return tokenId;
    }

    function disableToken(uint256 tokenId) public onlyOwner() {
        _tokens[tokenId].available = false;

        emit TokenDisabled(tokenId, _msgSender());
    }

    function enableToken(uint256 tokenId) public onlyOwner() {
        _tokens[tokenId].available = true;

        emit TokenEnabled(tokenId, _msgSender());
    }

    function getToken(uint256 tokenId) public view returns (Token memory){
        return _tokens[tokenId];
    }
}

pragma solidity 0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract DePOFeeManage is Ownable{
    // Fee that takes from the order creator, 100_00 = 100%
    uint256 public merchantFee;
    // Fee that takes from the order resolver, 100_00 = 100%
    uint256 public takerFee;
    address public feeReceiver;

    uint256 maxPercent = 100_00; // 100_00 = 100%;

    event MerchantFeeChanged(uint256 oldValue, uint256 newValue, address owner);
    event TakerFeeChanged(uint256 oldValue, uint256 newValue, address owner);
    event FeeReceiverChanged(address oldValue, address newValue, address owner);

    constructor(
        uint256 initMerchantFee,
        uint256 initTakerFee,
        address initFeeReceiver
    ) {
        changeMerchantFee(initMerchantFee);
        changeTakerFee(initTakerFee);
        changeFeeReceiver(initFeeReceiver);
    }

    function changeMerchantFee(uint256 newFee) public onlyOwner() {
        require(newFee < maxPercent, "Fee can not be more than 100%");
        require(newFee+takerFee < maxPercent, "Total fee can not be more than 100%");

        emit MerchantFeeChanged(merchantFee, newFee, _msgSender());
        merchantFee = newFee;
    }

    function changeTakerFee(uint256 newFee) public onlyOwner() {
        require(newFee < maxPercent, "Fee can not be more than 100%");
        require(newFee+merchantFee < maxPercent, "Total fee can not be more than 100%");

        emit TakerFeeChanged(merchantFee, newFee, _msgSender());
        takerFee = newFee;
    }

    function changeFeeReceiver(address receiver) public onlyOwner() {
        require(receiver != address(0), "Zero address is not allowed");

        emit FeeReceiverChanged(feeReceiver, receiver, _msgSender());
        feeReceiver = receiver;
    }

    function _takeFeeFromMerchant(uint256 amount, address tokenAddress) internal returns(uint256) {
        IERC20 tokenERC20 = IERC20(tokenAddress);

        require(tokenERC20.balanceOf(address(this)) >= amount, "Balance is lower than required");

        uint256 takeAmount = _calculateFeeFromMerchant(amount);

        require(tokenERC20.transferFrom(address(this), feeReceiver, takeAmount), "ERC20 transferFrom error");

        return takeAmount;
    }

    function _takeFeeFromTaker(uint256 amount, address tokenAddress) internal returns(uint256) {
        IERC20 tokenERC20 = IERC20(tokenAddress);

        require(tokenERC20.balanceOf(address(this)) >= amount, "Balance is lower than required");

        uint256 takeAmount = _calculateFeeFromTaker(amount);

        require(tokenERC20.transferFrom(address(this), feeReceiver, takeAmount), "ERC20 transferFrom error");

        return takeAmount;
    }

    function _calculateFeeFromMerchant(uint256 amount) internal view returns(uint256) {
        return amount * merchantFee / maxPercent;
    }

    function _calculateFeeFromTaker(uint256 amount) internal view returns(uint256) {
        return amount * merchantFee / maxPercent;
    }
}

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Dictionary/DePODictionary.sol";

abstract contract DePOOfferManage is DePODictionary {
    using Counters for Counters.Counter;

    enum OfferType {SellCrypto, BuyCrypto}

    struct Offer {
        uint256 id;
        OfferType offerType;
        uint256 countryId;
        uint256 tokenId;
        uint256[] paymentMethodIds;
        uint256 currencyId;
        address owner;
        uint256 amount; // Amount of crypto to sell/buy
        uint256 rate; // how much fiat for 1 crypto
        uint256 limitBottom; // Bottom limit of crypto to sell/buy
        uint256 limitTop; // Top limit of crypto to sell/buy
        bool available;
    }

    Counters.Counter private offerCounter;
    mapping(uint256 => Offer) private _offers;

    event OfferCreated(uint256 offerId, address owner);
    event OfferChanged(uint256 offerId);
    event OfferClosed(uint256 offerId);

    function createSellOffer(
        uint256 countryId,
        uint256 tokenId,
        uint256[] memory paymentMethodIds,
        uint256 currencyId,
        uint256 amount,
        uint256 rate,
        uint256 limitBottom,
        uint256 limitTop
    ) public validateSellOffer(countryId, paymentMethodIds, currencyId) returns(Offer memory) {
        Token memory token = getToken(tokenId);
        require(token.available, "Token is not available");

        _makeDeposit(token.contractAddress, amount, _msgSender());

        // sell offer
        Offer memory offer = _createSellOffer(countryId, tokenId, paymentMethodIds, currencyId, _msgSender(), amount, rate, limitBottom, limitTop);

        _offers[offer.id] = offer;

        emit OfferCreated(offer.id, _msgSender());

        return offer;
    }

    function getOffer(uint256 offerId) public view returns (Offer memory) {
        return _offers[offerId];
    }

    function changeOfferRate(uint256 offerId, uint256 rate) public onlyOfferOwner(offerId) {
        _offers[offerId].rate = rate;

        emit OfferChanged(offerId);
    }

    function increaseOfferAmount(uint256 offerId, uint256 amount) public onlyOfferOwner(offerId) {
        Offer memory offer = getOffer(offerId);
        Token memory token = getToken(offer.tokenId);

        if(offer.offerType == OfferType.SellCrypto) {
            _makeDeposit(token.contractAddress, amount, _msgSender());
        }

        _changeOfferAmount(offer.id, offer.amount + amount);
    }

    function decreaseOfferAmount(uint256 offerId, uint256 amount) public onlyOfferOwner(offerId) {
        Offer memory offer = getOffer(offerId);
        Token memory token = getToken(offer.tokenId);

        require(offer.amount <= amount, "Insufficient offer balance");
        if(offer.offerType == OfferType.SellCrypto) {
            _withdrawDeposit(token.contractAddress, amount, _msgSender());
        }

        if(offer.amount == amount) {
            _closeOffer(offerId);
        }

        _changeOfferAmount(offer.id, offer.amount - amount);
    }

    function _createSellOffer(
        uint256 countryId,
        uint256 tokenId,
        uint256[] memory paymentMethodIds,
        uint256 currencyId,
        address owner,
        uint256 amount,
        uint256 rate,
        uint256 limitBottom,
        uint256 limitTop
    ) internal returns (Offer memory) {
        offerCounter.increment();
        uint256 offerId = offerCounter.current();
        return Offer(offerId, OfferType.SellCrypto, countryId, tokenId, paymentMethodIds, currencyId, owner, amount, rate, limitBottom, limitTop, true);
    }

    function _closeOffer(uint256 offerId) private {
        _offers[offerId].available = false;

        emit OfferClosed(offerId);
    }

    function _changeOfferAmount(uint256 offerId, uint256 amount) internal {
        require(amount >= 0, "amount must be higher than 0");
        _offers[offerId].amount = amount;

        emit OfferChanged(offerId);
    }

    function _makeDeposit(address contractAddress, uint256 amount, address from) private {
        IERC20 tokenERC20 = IERC20(contractAddress);

        require(tokenERC20.balanceOf(from) >= amount, "Balance is lower than required");

        require(tokenERC20.transferFrom(from, address(this), amount), "ERC20 transferFrom error");
    }

    function _withdrawDeposit(address contractAddress, uint256 amount, address to) private {
        IERC20 tokenERC20 = IERC20(contractAddress);

        require(tokenERC20.transfer(to, amount), "ERC20 transfer error");
    }

    modifier validateSellOffer(
        uint256 countryId,
        uint256[] memory paymentMethodIds,
        uint256 currencyId
    ) {
//        require(offerType == 0 || offerType == 1, "Offer type is not supported");
        require(getCountry(countryId).available, "Country is not available");
        for (uint256 i = 0; i < paymentMethodIds.length; i++) {
            require(getPaymentMethod(countryId, paymentMethodIds[i]).available, "PaymentMethod is not available");
        }
        require(getCurrency(countryId, currencyId).available, "Currency is not available");
        _;
    }

    modifier onlyOfferOwner(uint256 offerId) {
        require(getOffer(offerId).owner == _msgSender(), "Allowed only for offer owner");
        _;
    }
}