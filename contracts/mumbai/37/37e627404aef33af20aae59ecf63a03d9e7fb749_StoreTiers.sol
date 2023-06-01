// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "../access/AdminControl.sol";

import "./interfaces/IStoreTiers.sol";

import { IStoreFactory } from "./interfaces/IStoreFactory.sol";
import { IContractRegistry } from "./interfaces/IContractRegistry.sol";

/// @title Shoply Store Tiers
contract StoreTiers is IStoreTiers, ReentrancyGuard, AdminControl {
    using SafeERC20 for IERC20;

    /// @notice The address used to specify the network's native currency
    address public constant NATIVE_CURRENCY = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    /// @notice The length of a payment interval (30 days)
    uint256 public constant INTERVAL_LENGTH = 30 days;

    /// @notice Mapping of store tiers to their monthly fees
    mapping (uint8 => uint256) public tierCost;
    /// @notice Mapping of active product limit by tier
    mapping (uint8 => uint256) public tierActiveProductLimit;
    /// @notice Mapping of stores to their store tiers
    mapping (address => uint8) public storeTiers;
    /// @notice Mapping of stores to their tier expiration times
    mapping (address => uint256) public storeExpiration;
    /// @notice Mapping of stores to their referral address
    /// @dev returns address(0) if no referral address is set
    mapping (address => address) public storeReferrals;
    /// @notice Mapping of accepted tokens to their USD price data feed
    mapping (address => address) public feeTokenOracle;
    /// @notice Mapping of free months granted by a discount code
    mapping (bytes32 => uint256) public hashedDiscountCodes;
    /// @notice Mapping of numnber of times a discount code can be used
    mapping (bytes32 => uint256) public hashedDiscountCodeAllowance;
    /// @notice Mapping of accepted features by store tier
    mapping (bytes32 => mapping (uint8 => bool)) public tierFeatures;


    IContractRegistry public contractRegistry;

    modifier onlyStore() {
        if (!IStoreFactory(contractRegistry.addressOf("StoreFactory")).isStore(msg.sender)) {
            revert InvalidStore();
        }
        _;
    }

    modifier onlyStoreFactory() {
        if (msg.sender != contractRegistry.addressOf("StoreFactory")) {
            revert InvalidStoreFactory();
        }
        _;
    }

    constructor() {
        _addAdmin(msg.sender);
    }

    /// @notice Sets the store tier
    /// @param _tier The new store tier
    function setStoreTier(uint8 _tier) external onlyStore {
        uint8 prevTier = storeTiers[msg.sender];
        uint256 newTimeLeft;
        if (storeExpiration[msg.sender] > block.timestamp) {
            uint256 prevTimeLeft = storeExpiration[msg.sender] - block.timestamp;
            uint256 storeCredit = prevTimeLeft * tierCost[prevTier];
            newTimeLeft = storeCredit / tierCost[_tier];
        }

        uint256 newStoreExpiration = block.timestamp + newTimeLeft;
        storeExpiration[msg.sender] = newStoreExpiration;
        storeTiers[msg.sender] = _tier;

        emit StoreTierSet(msg.sender, _tier, newStoreExpiration);
    }

    /// @notice Set the initial 30 free days
    function setInitialMonth(address _store) external onlyStoreFactory {
        uint256 newStoreExpiration = block.timestamp + 30 days;
        storeExpiration[_store] = newStoreExpiration;
    }

    /// @notice Sets the store referrer
    /// @dev Emits a StoreReferrerSet event
    /// @param _store The address of the store
    /// @param _referrer The address of the referrer
    function setStoreReferrer(address _store, address _referrer) external onlyStoreFactory {
        storeReferrals[_store] = _referrer;
        emit StoreReferrerSet(_store, _referrer);
    }

    /// @notice Extend the store's tier expiration by paying the platform fee
    /// @notice WARNING: Can be called by anyone, but does not give that person any rights to the store
    /// @dev Emits a StorePlatformFeePaid event
    /// @dev Emits a ReferralFeePaid event when a referral address is set
    /// @param _store The address of the store
    /// @param _intervals The number of (30 day) intervals to extend the store's tier expiration
    /// @param _feeToken The address of the fee token
    function payStorePlatformFees(address _store, uint256 _intervals, address _feeToken) external payable nonReentrant {
        if (feeTokenOracle[_feeToken] == address(0)) {
            revert InvalidFeeToken();
        }

        // get the current store tier
        uint256 tier = storeTiers[_store];

        uint256 paymentIntervals = _intervals;
        // pay for 11 months get a month free
        if (_intervals == 12) {
            paymentIntervals = 11;
        } else if (_intervals == 11) {
            _intervals = 12;
        }

        // extend the store expiration by the new _intervals
        storeExpiration[_store] += (_intervals * 30 days);

        // store can only be prepaid up to 12 intervals in advance
        if (storeExpiration[_store] > block.timestamp + (360 days)) {
            revert InvalidIntervals();
        }

        (, int256 price, , , ) = AggregatorV3Interface(feeTokenOracle[_feeToken]).latestRoundData();
        require(price > 0, "Invalid price");
        uint256 feeAmount = tierCost[storeTiers[_store]] * paymentIntervals / uint256(price);

        uint256 msgValue = msg.value;

        if (storeReferrals[_store] != address(0)) {
            uint256 referrerFee = feeAmount / 20; // Referrer gets 5%
            feeAmount -= referrerFee;

            if (_feeToken == NATIVE_CURRENCY) {
                require(msgValue == feeAmount + referrerFee);
                msgValue -= referrerFee;
                _transfer(payable(storeReferrals[_store]), referrerFee);
            } else {
                // using safeTransferFrom to handle non-compliant tokens (e.g. USDT)
                IERC20(_feeToken).safeTransferFrom(msg.sender, storeReferrals[_store], referrerFee);
                emit ReferralFeePaid(_store, msg.sender, referrerFee);
            }
        }

        if (_feeToken == NATIVE_CURRENCY) {
            require(msgValue == feeAmount);
            _transfer(payable(contractRegistry.feeAddress()), feeAmount);
        } else {
            // using safeTransferFrom to handle non-compliant tokens (e.g. USDT)
            IERC20(_feeToken).safeTransferFrom(msg.sender, contractRegistry.feeAddress(), feeAmount);
            emit StorePlatformFeePaid(_store, msg.sender, _intervals, tier);
        }
    }

    /// @notice Extend the store's tier expiration by paying the platform fee
    /// @dev Emits a StorePlatformFeePaid event
    /// @dev Emits a ReferralFeePaid event when a referral address is set
    /// @param _store The address of the store
    /// @param _intervals The number of (30 day) intervals to extend the store's tier expiration
    /// @param _feeToken The address of the fee token
    function payStorePlatformFees(address _store, uint256 _intervals, address _feeToken, bytes32 _code) external payable nonReentrant {
        if (feeTokenOracle[_feeToken] == address(0)) {
            revert InvalidFeeToken();
        }

        bytes32 hashedCode = keccak256(abi.encodePacked(_code));

        if (hashedDiscountCodeAllowance[hashedCode] == 0) {
            revert InvalidDiscountCode();
        }

        hashedDiscountCodeAllowance[hashedCode] -= 1;

        // get the current store tier
        uint256 tier = storeTiers[_store];

        uint256 paymentIntervals = _intervals;
        // pay for 11 months get a month free
        if (_intervals == 12) {
            paymentIntervals = 11;
        } else if (_intervals == 11) {
            _intervals = 12;
        }

        if (block.timestamp > storeExpiration[_store]) {
            storeExpiration[_store] = block.timestamp + (_intervals * 30 days);
        } else {
            // extend the store expiration by the new _intervals
            storeExpiration[_store] += (_intervals * 30 days);
        }


        paymentIntervals -= hashedDiscountCodes[hashedCode];

        (, int256 price, , , ) = AggregatorV3Interface(feeTokenOracle[_feeToken]).latestRoundData();
        require(price > 0, "Invalid price");
        uint256 feeAmount = tierCost[storeTiers[_store]] * paymentIntervals / uint256(price);

        if (storeReferrals[_store] != address(0)) {
            uint256 referrerFee = feeAmount / 20; // Referrer gets 5%
            feeAmount -= referrerFee;

            if (_feeToken == NATIVE_CURRENCY) {
                _transfer(payable(storeReferrals[_store]), referrerFee);
            } else {
                // using safeTransferFrom to handle non-compliant tokens (e.g. USDT)
                IERC20(_feeToken).safeTransferFrom(msg.sender, storeReferrals[_store], referrerFee);
                emit ReferralFeePaid(_store, msg.sender, referrerFee);
            }
        }

        if (_feeToken == NATIVE_CURRENCY) {
            require(msg.value == feeAmount);
            _transfer(payable(contractRegistry.feeAddress()), feeAmount);
        } else {
            // using safeTransferFrom to handle non-compliant tokens (e.g. USDT)
            IERC20(_feeToken).safeTransferFrom(msg.sender, contractRegistry.feeAddress(), feeAmount);
            emit StorePlatformFeePaid(_store, msg.sender, _intervals, tier);
        }
        
    }

    /// @notice Set the contract registry address
    /// @param _contractRegistry The address of the contract registry
    function setContractRegistry(address _contractRegistry) external onlyAdmin {
        contractRegistry = IContractRegistry(_contractRegistry);
        emit ContractRegistrySet(_contractRegistry);
    }

    /// @notice Sets a fee token
    /// @dev If _priceFeed is the zero address, the token is removed
    /// @param _feeToken The address of the fee token
    /// @param _priceFeed The address of the price feed
    function setFeeToken(address _feeToken, address _priceFeed) external onlyAdmin {
        feeTokenOracle[_feeToken] = _priceFeed;
        emit FeeTokenSet(_feeToken, _priceFeed);
    }

    /// @notice Sets an array of fee tokens
    /// @dev If _priceFeed is the zero address, the token is removed
    /// @param _feeTokens The addresses of the fee tokens
    /// @param _priceFeeds The addresses of the price feeds
    function setFeeTokens(address[] calldata _feeTokens, address[] calldata _priceFeeds) external onlyAdmin {
        if (_feeTokens.length != _priceFeeds.length) {
            revert InvalidArrayLengths();
        }

        for (uint256 i = 0; i < _feeTokens.length; i++) {
            feeTokenOracle[_feeTokens[i]] = _priceFeeds[i];
            emit FeeTokenSet(_feeTokens[i], _priceFeeds[i]);
        }
    }

    /// @notice Sets the cost of a store tier
    /// @dev Emits a TierCostSet event
    /// @param _tier The tier to set the cost of
    /// @param _cost The cost of the tier
    function setTierCost(uint8 _tier, uint256 _cost) external onlyAdmin {
        tierCost[_tier] = _cost;
        emit TierCostSet(_tier, _cost);
    }

    /// @notice Sets the active product limit for a store tier
    /// @param tier The store tier
    /// @param _activeProductLimit The active product limit for the store's in the tier
    function setTierActiveProductLimit(uint8 tier, uint256 _activeProductLimit) external onlyAdmin {
        tierActiveProductLimit[tier] = _activeProductLimit;
        emit TierActiveProductLimitSet(tier, _activeProductLimit);
    }

    /// @notice Add an array of hashed discount codes
    /// @dev Emits a HashedDiscountCodesAdded event
    /// @param hashedCodes An array of hashed discount codes
    /// @param discounts An array of discounts
    /// @param allowances An array of allowances
    function addHashedDiscountCodes(bytes32[] calldata hashedCodes, uint256[] calldata discounts, uint256[] calldata allowances) external onlyAdmin {
        if (hashedCodes.length != discounts.length || hashedCodes.length != allowances.length) {
            revert InvalidArrayLengths();
        }
        for (uint256 i = 0; i < hashedCodes.length; i++) {
            hashedDiscountCodes[hashedCodes[i]] = discounts[i];
            hashedDiscountCodeAllowance[hashedCodes[i]] = allowances[i];
        }
        emit HashedDiscountCodesAdded(hashedCodes, discounts);
    }

    /// @notice Add features to tiers
    /// @dev Emits a TierFeaturesAdded event
    /// @param tiers An array of tiers to add features to
    /// @param features An array of features to add to the tiers
    function addTierFeatures(uint8[] calldata tiers, bytes32[] calldata features) external onlyAdmin {
        if (tiers.length != features.length) {
            revert InvalidArrayLengths();
        }
        for (uint256 i = 0; i < tiers.length; i++) {
            tierFeatures[features[i]][tiers[i]] = true;
        }
        emit TierFeaturesAdded(tiers, features);
    }

    /// @notice Remove features from tiers
    /// @dev Emits a TierFeaturesRemoved event
    /// @param tiers An array of tiers to remove features from
    /// @param features An array of features to remove from the tiers
    function removeTierFeatures(uint8[] calldata tiers, bytes32[] calldata features) external onlyAdmin {
        if (tiers.length != features.length) {
            revert InvalidArrayLengths();
        }
        for (uint256 i = 0; i < tiers.length; i++) {
            tierFeatures[features[i]][tiers[i]] = false;
        }
        emit TierFeaturesRemoved(tiers, features);
    }

    /// @notice Admin function to increase store duration w/o payment
    /// @param _store The address of the store
    /// @param _intervals The number of intervals to add
    function increaseStoreDuration(address _store, uint256 _intervals) external onlyAdmin {

        uint256 timeIncrease = _intervals * INTERVAL_LENGTH;

        storeExpiration[_store] += timeIncrease;

        emit AdminStoreDurationIncreased(_store, _intervals);
    }

    /// @notice Returns whether a store has a feature
    /// @param _store The address of the store
    /// @param _feature The feature to check
    /// @return Whether the store has the feature
    function hasFeature(address _store, bytes32 _feature) external view returns (bool) {
        return tierFeatures[_feature][storeTiers[_store]];
    }

    /// @notice Returns the active product limit for a store
    /// @param _store The store address
    /// @return The store's active product limit
    function activeProductLimit(address _store) external view returns (uint256) {
        return tierActiveProductLimit[storeTiers[_store]];
    }

    /// @notice Function to transfer Ether from this contract to address from input
    /// @param _to address of transfer recipient
    /// @param _amount amount of ether to be transferred
    function _transfer(address payable _to, uint256 _amount) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = _to.call{value: _amount}("");
        if (!success) {
            revert EthTransferFailed();
        }
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Caller must be an admin
error OnlyAdmin();
/// @notice Caller cannot remove themselves as admin
error SelfRemoval();

/// @title Shoply Admin Control
contract AdminControl {

    mapping(address => bool) public isAdmin;

    /// @notice Emitted when an admin is added
    /// @param admin The address of the admin
    event AdminAdded(address indexed admin);
    /// @notice Emitted when an admin is removed
    /// @param admin The address of the admin
    event AdminRemoved(address indexed admin);

    modifier onlyAdmin() {
        if (!isAdmin[msg.sender]) {
            revert OnlyAdmin();
        }
        _;
    }

    /// @notice Adds an admin
    /// @dev Emits an AdminAdded event
    /// @param _admin The address of the admin
    function addAdmin(address _admin) external onlyAdmin {
        _addAdmin(_admin);
    }

    /// @notice Removes an admin
    /// @dev Emits an AdminRemoved event
    /// @param _admin The address of the admin to remove
    function removeAdmin(address _admin) external onlyAdmin {
        if (_admin == msg.sender) {
            revert SelfRemoval();
        }
        isAdmin[_admin] = false;
        emit AdminRemoved(_admin);
    }

    function _addAdmin(address _admin) internal {
        isAdmin[_admin] = true;
        emit AdminAdded(_admin);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @notice Not a valid store
error InvalidStore();
/// @notice The fee address cannot be the zero address
error InvalidFeeAddress();
/// @notice Store Factory cannot be the zero address
error InvalidStoreFactory();
/// @notice Intervals cannot be greater than 12
error InvalidIntervals();
/// @notice The fee token is not supported
error InvalidFeeToken();
/// @notice No allowance for the given discount code
error InvalidDiscountCode();
/// @notice Array lengths are not equal
error InvalidArrayLengths();
/// @notice Payment Failed
error PaymentFailed();
/// @notice Eth Transfer Failed
error EthTransferFailed();

/// @title The interface for the StoreTiers contract
interface IStoreTiers {

    /// @notice Emitted when the fee address is set
    /// @param feeAddress The address of the store platform fee recipient
    event FeeAddressSet(address feeAddress);

    /// @notice Emitted when a store platform fee is paid
    /// @param store The address of the store
    /// @param user The address of the user paying the fee
    /// @param intervals The number of 30 day intervals paid
    /// @param tier The tier of the store
    event StorePlatformFeePaid(address indexed store, address indexed user,uint256 intervals, uint256 tier);

    /// @notice Emitted when the story factory is set
    /// @param storeFactory The address of the store factory
    event StoreFactorySet(address storeFactory);

    /// @notice Emitted when a store tier is set
    /// @param store The address of the store
    /// @param tier The new store tier
    /// @param expiration The new store expiration
    event StoreTierSet(address indexed store, uint8 indexed tier, uint256 indexed expiration);

    /// @notice Emitted when a tier cost is set
    /// @param tier The tier
    /// @param cost The cost of the tier
    event TierCostSet(uint8 indexed tier, uint256 indexed cost);

    /// @notice Emitted when a store referrer is set
    /// @param store The address of the store
    /// @param referrer The address of the referrer
    event StoreReferrerSet(address indexed store, address indexed referrer);

    /// @notice Emitted when a referral fee is paid
    /// @param store The address of the store
    /// @param referrer The address of the referrer
    /// @param amount The amount of the referral fee
    event ReferralFeePaid(address indexed store, address indexed referrer, uint256 amount);

    /// @notice Emitted when a fee token is set
    /// @param feeToken The address of the fee token
    /// @param priceFeed The address of the price feed
    event FeeTokenSet(address indexed feeToken, address indexed priceFeed);

    /// @notice Emitted when the contract registry is set
    /// @param contractRegistry The address of the contract registry
    event ContractRegistrySet(address contractRegistry);

    /// @notice Emitted when a store duration is increased without platform fee payment
    /// @param store The address of the store
    /// @param intervals The number of intervals added
    event AdminStoreDurationIncreased(address indexed store, uint256 indexed intervals);

    /// @notice Emitted when discount codes are added
    /// @param hashedCodes The hashed codes
    /// @param discounts The discounts
    event HashedDiscountCodesAdded(bytes32[] hashedCodes, uint256[] discounts);

    /// @notice Emitted when a tier active product limit is set
    /// @param tier The tier
    /// @param activeProductLimit The active product limit for store's in the tier
    event TierActiveProductLimitSet(uint8 indexed tier, uint256 indexed activeProductLimit);

    /// @notice Emitted when new features are added for store tiers
    /// @param tiers An array of tiers
    /// @param features An array of features
    event TierFeaturesAdded(uint8[] tiers, bytes32[] features);

    /// @notice Emitted when features are removed from store tiers
    /// @param tiers An array of tiers
    /// @param features An array of features
    event TierFeaturesRemoved(uint8[] tiers, bytes32[] features);

    function setInitialMonth(address store) external;
    function setStoreReferrer(address store, address referrer) external;
    function setStoreTier(uint8 _tier) external;
    function hasFeature(address store, bytes32 feature) external view returns (bool);
    function storeTiers(address store) external view returns (uint8);
    function activeProductLimit(address store) external view returns (uint256);
    function storeExpiration(address store) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @notice Contract Registry cannot be the zero address
error InvalidAddress();

/// @notice Caller is not the domain owner
error NotDomainOwner();

/// @notice Accepted currency cannot be address zero
error InvalidCurrency();

/// @notice Referrer cannot be address zero or the store owner
error InvalidReferrer();

/// @notice Sender is not a valid store address
error NotStore();

/// @notice Store version is inactive
error VersionInactive();

/// @title Interface for the Shoply store factory
interface IStoreFactory {

    /// @notice Emitted when a store is created
    /// @param store The address of the store
    /// @param domain The domain of the store
    event StoreCreated(address indexed store, bytes32 indexed domain);

    /// @notice Emitted when the contract registry is set
    /// @param contractRegistry The contract registry address
    event ContractRegistrySet(address indexed contractRegistry);

    /// @notice Emitted when a role is granted
    /// @param store The store address
    /// @param role The role
    /// @param account The account
    /// @param hasRole The role status
    event RoleUpdated(address indexed store, bytes32 indexed role, address indexed account, bool hasRole);
    
    function updateRole(bytes32 role, address account, bool hasRole) external;
    function isStore(address store) external view returns (bool status);
    function hasRole(address store, bytes32 role, address user) external view returns (bool status);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error ZeroAddress();
error InvalidAddress();
error InvalidName();
/// @notice Input arrays must be the same length
error InvalidArrayLengths();

/// @dev Contract Registry interface
interface IContractRegistry {

    /// @notice Emitted when an address pointed to by a contract name is modified
    /// @param contractName The contract name
    /// @param contractAddress The contract address
    event AddressUpdate(bytes32 indexed contractName, address contractAddress);
    
    /// @notice Emitted when the fee address is set
    /// @param feeAddress The fee address
    event FeeAddressSet(address feeAddress);

    /// @notice Emitted when price data feeds are set
    /// @param tokens An array of tokens
    /// @param feeds An array of data feeds
    event PriceDataFeedsSet(address[] tokens, address[] feeds);

    /// @notice Emitted when the wrapped native address is set
    /// @param wrappedNative The wrapped native address (e.g. weth)
    event WrappedNativeSet(address wrappedNative);

    function addressOf(bytes32 contractName) external view returns (address);
    function feeAddress() external view returns (address);
    function priceDataFeed(address token) external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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