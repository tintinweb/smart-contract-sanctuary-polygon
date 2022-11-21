// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "./ERC20Crowdsale.sol";

abstract contract ERC20CappedCrowdsale is ERC20Crowdsale {

    using Math for uint256;

    uint256 private immutable _capInQuotingToken;
    uint256 private immutable _acceptableDelta;

    constructor (uint256 capInQuotingToken_, uint256 acceptableDelta_) {
        require(capInQuotingToken_ > 0, "ERC20CappedCrowdsale: cap is 0");

        _capInQuotingToken = capInQuotingToken_;
        _acceptableDelta = acceptableDelta_;
    }

    function cap() public view returns (uint256) {
        return _capInQuotingToken;
    }

    function delta() public view returns (uint256) {
        return _acceptableDelta;
    }

    function capWithDelta() public view returns (uint256) {
        return _acceptableDelta + _capInQuotingToken;
    }

    function capReached() public view returns (bool) {
        uint256 nativeToQuotingTokenRate = priceFeedClient().getLatestPrice();
        return _capReached(nativeToQuotingTokenRate);
    }

    function _capReached(uint256 nativeToQuotingTokenRate) public view returns (bool) {
        uint256 tokensRaised = weiRaised() * nativeToQuotingTokenRate;

        return tokensRaised >= _capInQuotingToken * 1 ether;
    }

    function quotingTokensRemaining() public view returns (uint256) {
        uint256 currentPrice = priceFeedClient().getLatestPrice();
        return _quotingTokensRemaining(currentPrice);
    }

    function _quotingTokensRemaining(uint256 nativeToQuotingTokenRate) public view returns (uint256) {
        uint256 quotingTokensRaised = _getWeiRaisedInQuotingTokens(weiRaised(), nativeToQuotingTokenRate);

        return _capInQuotingToken > quotingTokensRaised ? _capInQuotingToken - quotingTokensRaised : 0;
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount, uint256 nativeToQuotingTokenRate) internal virtual override view {
        require(weiAmount != 1 && !_capReached( nativeToQuotingTokenRate), "ERC20CappedCrowdsale: cap reached");
        super._preValidatePurchase(beneficiary, weiAmount, nativeToQuotingTokenRate);
    }

    function _postValidatePurchase(address beneficiary, uint256 weiAmount, uint256 nativeToQuotingTokenRate) internal virtual override view {
        uint256 convertedTokensDenorm = weiRaised() * nativeToQuotingTokenRate;
        require(convertedTokensDenorm <= capWithDelta() * 1 ether, "ERC20CappedCrowdsale: cap reached");

        super._postValidatePurchase(beneficiary, weiAmount, nativeToQuotingTokenRate);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "../price/PriceFeedClient.sol";

/**
 * @title ERC20Crowdsale
 * 
 * @dev THIS CLASS IS TAKEN ALMOST FULLY FROM @openzeppelin/[email protected]
 * 
 * @dev ERC20Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with native token, but quote the raised tokens in given 
 * ERC20 token. This contract implements such functionality in its most fundamental form and
 * can be extended to provide additional functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conforms
 * the base architecture for crowdsales. It is *not* intended to be modified / overridden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropriate to concatenate
 * behavior.
 */
contract ERC20Crowdsale is Context, ReentrancyGuard, Ownable {

    using SafeERC20 for IERC20Metadata;
    using Math for uint256;

    // The token being sold
    IERC20Metadata private immutable _token;
    
    // The convertor between native token and quoting token
    PriceFeedClient private _priceFeedClient;

    // Funds recipient
    address payable private _wallet;

    // How many token units a buyer gets per ERC20 token
    uint256 private _tokenRate;

    // Amount of wei raised
    uint256 private _weiRaised;

    /**
     * Event for token purchase logging
     * @param buyer who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokensPurchased(address indexed buyer, address indexed beneficiary, uint256 value, uint256 nativeToQuotingTokenRate, uint256 amount);

    constructor (uint256 tokenRate_, address payable wallet_, IERC20Metadata token_, PriceFeedClient priceFeedClient_) {
        require(tokenRate_ > 0, "ERC20Crowdsale: rate is 0");
        require(wallet_ != address(0), "ERC20Crowdsale: wallet is the zero address");
        require(address(token_) != address(0), "ERC20Crowdsale: token is the zero address");
        require(address(priceFeedClient_) != address(0), "ERC20Crowdsale: price feed client is the zero address");

        _tokenRate = tokenRate_;
        _wallet = wallet_;
        _token = token_;
        _priceFeedClient = priceFeedClient_;
    }

    receive() external payable {
        buyTokens(_msgSender());
    }

    /**
     * @dev return the token being sold
     */
    function token() public view returns (IERC20Metadata) {
        return _token;
    }

    /**
     * @dev return the funds recipient
     */
    function wallet() public view returns (address payable) {
        return _wallet;
    }

    /**
     * @dev return the number of token units a buyer gets per quoting token
     */
    function tokenRate() public view returns (uint256) {
        return _tokenRate;
    }

    /**
     * @dev return the price feed address to quote raised wei in tokens
     */
    function priceFeedClient() public view returns (PriceFeedClient) {
        return _priceFeedClient;
    }

    /**
     * @dev the amount of wei raised
     */
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }


    function setPriceFeedClient(PriceFeedClient priceFeedClient_) public onlyOwner {
        require(address(priceFeedClient_) != address(0), "ERC20Crowdsale: price feed client is the zero address");

        _priceFeedClient = priceFeedClient_;
    }

    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param beneficiary Recipient of the token purchase
     */
    function buyTokens(address beneficiary) public nonReentrant payable {
        uint256 weiAmount = msg.value;

        uint256 nativeToQuotingTokenRate = _priceFeedClient.getLatestPrice();

        _preValidatePurchase(beneficiary, weiAmount, nativeToQuotingTokenRate);

        uint256 tokens = _getTokenAmount(weiAmount, nativeToQuotingTokenRate);

        _weiRaised += weiAmount;

        _processPurchase(beneficiary, tokens);
        emit TokensPurchased(_msgSender(), beneficiary, weiAmount, nativeToQuotingTokenRate, tokens);

        _updatePurchasingState(beneficiary, weiAmount, nativeToQuotingTokenRate);

        _forwardFunds();
        _postValidatePurchase(beneficiary, weiAmount, nativeToQuotingTokenRate);
    }

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met.
     * Use `super` in contracts that inherit from Crowdsale to extend their validations.
     * Example from CappedCrowdsale.sol's _preValidatePurchase method:
     *     super._preValidatePurchase(beneficiary, weiAmount);
     *     require(weiRaised().add(weiAmount) <= cap);
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     * @param nativeToQuotingTokenRate Value in quoting token wei to convert native to quoting token
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount, uint256 nativeToQuotingTokenRate) internal virtual view {
        require(beneficiary != address(0), "ERC20Crowdsale: beneficiary is the zero address");
        require(weiAmount != 0, "ERC20Crowdsale: weiAmount is 0");
        require(nativeToQuotingTokenRate != 0, "ERC20Crowdsale: nativeToQuotingTokenRate is 0");

        // slither-disable-next-line redundant-statements
        this;
    }

    /**
     * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid
     * conditions are not met.
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     * @param nativeToQuotingTokenRate Value in quoting token wei to convert native to quoting token
     */
    function _postValidatePurchase(address beneficiary, uint256 weiAmount, uint256 nativeToQuotingTokenRate) internal virtual view {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param weiAmount Value in wei to be converted into tokens
     * @param nativeToQuotingTokenRate Native to quoting token rate, for example, MATIC / USDC
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 weiAmount, uint256 nativeToQuotingTokenRate) internal virtual view returns (uint256) {
        return weiAmount.mulDiv(nativeToQuotingTokenRate, _tokenRate * 1 ether);
    }

    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends
     * its tokens.
     * @param beneficiary Address performing the token purchase
     * @param tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal virtual {
        _token.safeTransfer(beneficiary, tokenAmount);
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
     * tokens.
     * @param beneficiary Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal virtual {
        _deliverTokens(beneficiary, tokenAmount);
    }

    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions,
     * etc.)
     * @param beneficiary Address receiving the tokens
     * @param weiAmount Value in wei involved in the purchase
     */
    function _updatePurchasingState(address beneficiary, uint256 weiAmount, uint256 nativeToQuotingTokenRate) internal virtual {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Determines how native token is stored/forwarded on purchases.
     */
    function _forwardFunds() internal virtual {
        _wallet.transfer(msg.value);
    }

    function _getWeiRaisedInQuotingTokens(uint256 weiAmount, uint256 nativeToQuotingTokenRate) internal view returns (uint256) {
        // slither-disable-next-line redundant-statements
        this;
        
        return weiAmount.mulDiv(nativeToQuotingTokenRate, 1 ether);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import "./ERC20Crowdsale.sol";

abstract contract ERC20MinimumThresholdCrowdsale is ERC20Crowdsale {

    uint256 private immutable _minimumThreshold;

    constructor(uint256 minimumThreshold_) {
        require(minimumThreshold_ > 0, "ERC20MinimumThresholdCrowdsale: threshold must be positive");

        _minimumThreshold = minimumThreshold_;
    }

    function minimumThreshold() public view returns (uint256) {
        return _minimumThreshold;
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount, uint256 nativeToQuotingTokenRate) internal virtual override view {
        uint256 weiInTokens = _getWeiRaisedInQuotingTokens(weiAmount, nativeToQuotingTokenRate);
        require(weiInTokens >= _minimumThreshold, "ERC20MinimumThresholdCrowdsale: payment is below threshold");

        super._preValidatePurchase(beneficiary, weiAmount, nativeToQuotingTokenRate);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import "./ERC20Crowdsale.sol";

/**
 * @title TimedERC20Crowdsale
 * @dev ERC20Crowdsale accepting contributions only within a time frame.
 */
abstract contract TimedERC20Crowdsale is ERC20Crowdsale {

    uint256 private _openingTime;
    uint256 private _closingTime;

    /**
     * @dev Reverts if not in crowdsale time range.
     */
    modifier onlyWhileOpen {
        require(isOpen(), "TimedERC20Crowdsale: not open");
        _;
    }

    /**
     * @dev Constructor, takes crowdsale opening and closing times.
     * @param openingTime_ Crowdsale opening time
     * @param closingTime_ Crowdsale closing time
     */
    constructor (uint256 openingTime_, uint256 closingTime_) {
        require(openingTime_ > block.timestamp, "TimedERC20Crowdsale: opening time must be in future");
        require(openingTime_ < closingTime_, "TimedERC20Crowdsale: closing time must be after opening time");

        _openingTime = openingTime_;
        _closingTime = closingTime_;
    }

    /**
     * @return the crowdsale opening time
     */
    function openingTime() public view returns (uint256) {
        return _openingTime;
    }

    /**
     * @return the crowdsale closing time
     */
    function closingTime() public view returns (uint256) {
        return _closingTime;
    }

    /**
     * @return true if the crowdsale is open, false otherwise.
     */
    function isOpen() public view returns (bool) {
        return block.timestamp >= _openingTime && block.timestamp <= _closingTime;
    }

    /**
     * @dev Extend parent behavior requiring to be within contributing period.
     * @param beneficiary Token purchaser
     * @param weiAmount Amount of wei contributed
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount, uint256 nativeToQuotingTokenRate) internal 
        onlyWhileOpen virtual override view {
        super._preValidatePurchase(beneficiary, weiAmount, nativeToQuotingTokenRate);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface PriceFeedClient {
    function getLatestPrice() external view returns (uint256);
    function getDecimals() external view returns (uint8);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import "@opengtl/crowdsale/contracts/price/PriceFeedClient.sol";
import "@opengtl/crowdsale/contracts/ERC20/TimedERC20Crowdsale.sol";
import "@opengtl/crowdsale/contracts/ERC20/ERC20CappedCrowdsale.sol";
import "@opengtl/crowdsale/contracts/ERC20/ERC20MinimumThresholdCrowdsale.sol";
import "../token/ERC20Mintable.sol";
import "../vault/MultiVestingVault.sol";

contract PrimeGamesTokenCrowdsale is TimedERC20Crowdsale, ERC20CappedCrowdsale, ERC20MinimumThresholdCrowdsale {

    MultiVestingVault private immutable _vault;
    address private _deployer;
    bool private _finished = false;

    modifier crowdsaleNotFinished() {
        require(!_finished, "PrimeGamesTokenCrowdsale: crowdsale finished");
        _;
    }

    event CrowdsaleFinished(uint256 timestamp, address indexed finisher);

    constructor(uint256 rate, address payable wallet, ERC20Mintable token_, PriceFeedClient priceFeedClient,
                MultiVestingVault vault_, uint256 openingTime, uint256 cap, uint256 delta, uint256 minimumThreshold_) 
                TimedERC20Crowdsale(openingTime, type(uint256).max) ERC20Crowdsale(rate, wallet, token_, priceFeedClient)
                ERC20CappedCrowdsale(cap, delta) ERC20MinimumThresholdCrowdsale(minimumThreshold_) {
        _vault = vault_;
        _deployer = msg.sender;
    }

    function finished() public view returns (bool) {
        return _finished;
    }

    function vault() public view returns (MultiVestingVault) {
        return _vault;
    }

    function finish() public onlyOwner crowdsaleNotFinished {
        require(capReached(), "PrimeGamesTokenCrowdsale: crowdsale finish conditions are not met");

        _finished = true;
        ERC20Mintable(address(token())).renounceMinter();
        _vault.transferOwnership(_deployer);

        emit CrowdsaleFinished(block.timestamp, msg.sender);
    }

    function _getTokenAmount(uint256 weiAmount, uint256 nativeToQuotingTokenRate) internal view virtual override returns (uint256) {
        return super._getTokenAmount(weiAmount, nativeToQuotingTokenRate) * 10 ** priceFeedClient().getDecimals();
    }

    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal virtual override {
        uint256 tokensForUser = tokenAmount * 5 / 100;

        ERC20Mintable(address(token())).mint(beneficiary, tokensForUser);
        _vault.addVesting(beneficiary, tokenAmount - tokensForUser);
    }

    // Overrides required by solidity

    function _preValidatePurchase(address beneficiary, uint256 weiAmount, uint256 nativeToQuotingTokenRate)
        internal virtual override(TimedERC20Crowdsale, ERC20CappedCrowdsale, ERC20MinimumThresholdCrowdsale) crowdsaleNotFinished view {
        super._preValidatePurchase(beneficiary, weiAmount, nativeToQuotingTokenRate);
    }

    function _postValidatePurchase(address beneficiary, uint256 weiAmount, uint256 nativeToQuotingTokenRate)
        internal virtual override(ERC20CappedCrowdsale, ERC20Crowdsale) view {
        super._postValidatePurchase(beneficiary, weiAmount, nativeToQuotingTokenRate);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface ERC20Mintable is IERC20Metadata {
    function mint(address beneficiary, uint256 value) external;
    function addMinter(address newMinter) external;
    function addMinter(address newMinter, uint256 mintingCap) external;
    function isMinter(address minter) external view returns (bool);
    function renounceMinter() external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../token/ERC20Mintable.sol";

contract MultiVestingVault is Ownable {

    using Address for address;
    using SafeERC20 for ERC20Mintable;

    struct Vesting {
        uint256 tokensVested;
        uint256 tokensReleased;
        uint256 lastReleasingTime;
    }

    event TokensAdded(address indexed beneficiary, uint256 amount);
    event TokensReleased(address indexed beneficiary, uint256 amount);

    ERC20Mintable private immutable _token;
    uint256 private immutable _releaseTime;
    uint256 private immutable _duration;
    uint256 private immutable _periods;

    mapping (address => Vesting) private _balances;

    uint256 private _totalTokensBalance;
    uint256 private _totalReleasedTokens;

    constructor(ERC20Mintable token_, uint256 releaseTime_, uint256 duration_, uint256 periods_) {
        require(address(token_) != address(0), "MultiVestingVault: token has zero address");
        require(releaseTime_ > block.timestamp, "MultiVestingVault: release time must be in future");
        require(duration_ > 0, "MultiVestingVault: duration must be positive");
        require(periods_ > 0, "MultiVestingVault: periods must be positive");

        _token = token_;
        _releaseTime = releaseTime_;
        _duration = duration_;
        _periods = periods_;
    }

    function token() public view returns (ERC20Mintable) {
        return _token;
    }

    function releaseTime() public view returns (uint256) {
        return _releaseTime;
    }

    function duration() public view returns (uint256) {
        return _duration;
    }

    function periods() public view returns (uint256) {
        return _periods;
    }

    function totalTokensBalance() public view returns (uint256) {
        return _totalTokensBalance;
    }

    function totalReleasedTokens() public view returns (uint256) {
        return _totalReleasedTokens;
    }

    function vestingBalance(address beneficiary) public view returns (Vesting memory) {
        return _balances[beneficiary];
    }

    function addVesting(address beneficiary, uint256 tokens) public onlyOwner {
        require(beneficiary != address(0), "MultiVestingVault: trying to vest for zero address");
        require(tokens > 0, "MultiVestingVault: trying to vest zero tokens");

        _balances[beneficiary].tokensVested += tokens;
        _totalTokensBalance += tokens;

        _token.mint(address(this), tokens);

        emit TokensAdded(beneficiary, tokens);
    }

    function release() public {
        require(block.timestamp >= _releaseTime, "MultiVestingVault: release time has not come");

        uint256 availableTokensForUser = availableTokens(msg.sender);

        require(availableTokensForUser > 0, "MultiVestingVault: no tokens available for release");

        _balances[msg.sender].tokensReleased += availableTokensForUser;
        _totalReleasedTokens += availableTokensForUser;

        _token.safeTransfer(msg.sender, availableTokensForUser);
        emit TokensReleased(msg.sender, availableTokensForUser);
    }

    function availableTokens(address beneficiary) public view returns (uint256) {
        if (block.timestamp < _releaseTime) {
            return 0;
        }

        Vesting memory info = _balances[beneficiary];

        uint256 periodsElapsed = ((block.timestamp - _releaseTime) / _duration) + 1;

        if (periodsElapsed >= _periods) {
            return info.tokensVested - info.tokensReleased;
        }

        uint256 paymentPerPeriod = info.tokensVested / _periods;
        return paymentPerPeriod * periodsElapsed - info.tokensReleased;
    }
}