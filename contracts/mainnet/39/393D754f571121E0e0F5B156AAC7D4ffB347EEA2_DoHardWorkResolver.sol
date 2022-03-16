// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IResolver.sol";
import "./interfaces/IController.sol";
import "./interfaces/AggregatorV3Interface.sol";
import "./upgradeability/BaseUpgradeableResolver.sol";

contract DoHardWorkResolver is Initializable, GovernableInit, BaseUpgradeableResolver, IResolver {
    using SafeERC20 for IERC20;

    constructor() {}

    function initialize(address _storage, 
        address _controller,
        address _profitSharingTarget,
        address _profitSharingToken,
        address _profitSharingTokenToNativePriceFeed,
        address _pokeMe
    ) public initializer {
        BaseUpgradeableResolver.initialize(_storage,
            _controller,
            _profitSharingTarget,
            _profitSharingToken,
            _profitSharingTokenToNativePriceFeed,
            _pokeMe,
            6, // great deal ratio
            12 hours // implementation change delay
        );
    }

    /**
    * Checks the profitability of a doHardWork by comparing gasCost
    * to profitSharing earnings times a greatDealRatio
    * Called by Gelato as trigger-check for tasks (trigger doHardWork on a given vault)
    */
    function checker(address vault)
        external
        override
        onlyNotPausedTriggering
        returns (bool canExec, bytes memory execPayload)
    {
       (uint256 profitSharingGains, uint256 gasCost) = checkDoHardWorkCostVsGain(vault);

        // check profitability and return false if gains threshold is not surpassed
        if(profitSharingGains > gasCost * greatDealRatio()) {
            canExec = true;
        } else {
            canExec = false;
        }

        execPayload = abi.encodeWithSelector(
            DoHardWorkResolver.doHardWork.selector,
            vault
        );
    }

    /**
    * Gelato nodes call back here so the Controller doesn't have to whitelist PokeMe.sol as a hardWorker
    * but rather just this resolver (which anyway has to be done to perform the check)
    */
    function doHardWork(bytes calldata performData) 
        external 
        onlyPokeMe
        onlyNotPausedTriggering
    {
        (address vault) = abi.decode(performData, (address));
        IController(controller()).doHardWork(vault);
    }

    /**
    * Sets the gas fee premium that Gelato charges on top of gas fee costs for execution of tasks
    * this has to be included in cost vs profit calculation
    * with added decimals (e.g. 20% -> 200; 100% -> 1000)
    */
    function setGasFeePremium(uint256 gasFeePremium) public onlyGovernance {
        _setGasFeePremium(gasFeePremium);
    }

    /**
    * Sets the ratio that defines the margin for when to trigger a doHardWork on vaults
    */
    function setGreatDealRatio(uint8 greatDealRatio) public onlyGovernance {
        _setGreatDealRatio(greatDealRatio);
    }

    /**
    * Sets the profit sharing token (e.g. WETH on Polygon)
    */
    function setProfitSharingToken(address profitSharingToken) public onlyGovernance {
        _setProfitSharingToken(profitSharingToken);
    }

    /**
    * Sets the controller that triggers doHardWorks on vaults
    */
    function setController(address controller) public onlyGovernance {
        _setController(controller);
    }

    /**
    * Sets the pokeMe whitelisted task execution checker address from gelato
    */
    function setPokeMe(address pokeMe) public onlyGovernance {
        _setPokeMe(pokeMe);
    }

    /**
    * Sets the profit sharing target address
    */
    function setProfitSharingTarget(address profitSharingTarget) public onlyGovernance {
        _setProfitSharingTarget(profitSharingTarget);
    }

    /**
    * Sets the profit sharing token to native token chainlink pricefeed
    * can be found here: https://docs.chain.link/docs/reference-contracts/
    */
    function setProfitSharingTokenToNativePriceFeed(address priceFeed) public onlyGovernance {
        _setProfitSharingTokenToNativePriceFeed(priceFeed);
    }

    /**
    * governance can pause all triggers in an emergency situation
    */
    function setPausedTriggering(bool pausedTriggering) public onlyGovernance {
        _setPausedTriggering(pausedTriggering);
    }

    /**
     * Returns the latest price of the native token / reward token pair
     */
    function getLatestPrice() internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(profitSharingTokenToNativePriceFeed());
        (,int256 price,,,) = priceFeed.latestRoundData();
        return uint256(price);
    }

    /** 
     * Gets the balance of the profitSharingToken at the profitSharingTarget
     */
    function getProfitSharingTargetBalance() internal view returns(uint256) {
        return IERC20(profitSharingToken()).balanceOf(profitSharingTarget());
    }

    /** 
     * Executes a doHardWork on the given vault and returns profitSharingGains and gasCost
     */
    function checkDoHardWorkCostVsGain(address vault) internal returns(uint256 profitSharingGains, uint256 gasCost){
         // get farmBalance before
        uint256 profitSharingBalanceBefore = getProfitSharingTargetBalance();
        // get amount of gas left before
        uint256 gasLeftBefore = gasleft();

        // run doHardWork for vault
        IController(controller()).doHardWork(vault);

        // approximate tx cost
        // use amount of gas left after to get gas amount which the doHardWork used
        uint256 gasUsed = gasLeftBefore - gasleft();
        gasCost = gasUsed * tx.gasprice;
        // add gas fee premium (with denominator of 1000 because 100% -> 1000)
        gasCost = gasCost * gasFeePremium() / 1000 + gasCost;

        // approximate profit sharing gains
        // get farmBalance after
        uint256 profitSharingBalanceAfter = getProfitSharingTargetBalance();
        uint256 profitSharingGainsInRewardToken = profitSharingBalanceAfter - profitSharingBalanceBefore;

        // profitSharing is in reward token, gasCost is in chain native token.
        // we need to compare the two. we use the chainlink oracle price feeds to get the price
        // for RewardToken / NativeToken
        uint256 priceOneNativeInRewardToken = getLatestPrice();
        // gas cost is already in native token, let's get the reward token to native token
        // profitSharingGainsInRewardToken has 18 decimals, priceOneNativeInRewardToken has 18 decimals
        profitSharingGains = profitSharingGainsInRewardToken * 1e18 / priceOneNativeInRewardToken;
    }

    function finalizeUpgrade() external onlyGovernance {
        _finalizeUpgrade();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

interface IResolver {
    function checker(address vault)
        external
        returns (bool canExec, bytes memory execPayload);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IController {

    event SharePriceChangeLog(
      address indexed vault,
      address indexed strategy,
      uint256 oldSharePrice,
      uint256 newSharePrice,
      uint256 timestamp
    );

    // [Grey list]
    // An EOA can safely interact with the system no matter what.
    // If you're using Metamask, you're using an EOA.
    // Only smart contracts may be affected by this grey list.
    //
    // This contract will not be able to ban any EOA from the system
    // even if an EOA is being added to the greyList, he/she will still be able
    // to interact with the whole system as if nothing happened.
    // Only smart contracts will be affected by being added to the greyList.
    // This grey list is only used in Vault.sol, see the code there for reference
    function greyList(address _target) external view returns(bool);

    function addVaultAndStrategy(address _vault, address _strategy) external;
    function doHardWork(address _vault) external;

    function salvage(address _token, uint256 amount) external;
    function salvageStrategy(address _strategy, address _token, uint256 amount) external;

    function notifyFee(address _underlying, uint256 fee) external;
    function profitSharingNumerator() external view returns (uint256);
    function profitSharingDenominator() external view returns (uint256);

    function feeRewardForwarder() external view returns(address);
    function setFeeRewardForwarder(address _value) external;

    function addHardWorker(address _worker) external;
    function addToWhitelist(address _target) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./BaseUpgradeableResolverStorage.sol";
import "../base/GovernableInit.sol";

contract BaseUpgradeableResolver is Initializable, GovernableInit, BaseUpgradeableResolverStorage {

  modifier onlyNotPausedTriggering() {
    require(!pausedTriggering(), "Action blocked as the resolver is in emergency state");
    _;
  }

  modifier onlyPokeMe() {
    require(msg.sender == pokeMe(), "Only PokeMe is allowed to call");
    _;
  }

  constructor() BaseUpgradeableResolverStorage() {
  }

  function initialize(
    address _storage,
    address _controller,
    address _profitSharingTarget,
    address _profitSharingToken,
    address _profitSharingTokenToNativePriceFeed,
    address _pokeMe,
    uint8 _greatDealRatio,
    uint256 _implementationChangeDelay
  ) internal {
     GovernableInit.initialize(_storage);

    _setPokeMe(_pokeMe);
    _setController(_controller);
    _setProfitSharingTarget(_profitSharingTarget);
    _setProfitSharingToken(_profitSharingToken);
    _setProfitSharingTokenToNativePriceFeed(_profitSharingTokenToNativePriceFeed);
    _setGreatDealRatio(_greatDealRatio);
    _setNextImplementationDelay(_implementationChangeDelay);
    _setPausedTriggering(false);
    _setGasFeePremium(0);
  }

  /**
  * Schedules an upgrade for this resolver's proxy.
  */
  function scheduleUpgrade(address impl) public onlyGovernance {
    _setNextImplementation(impl);
    _setNextImplementationTimestamp(block.timestamp + nextImplementationDelay());
  }

  function _finalizeUpgrade() internal {
    _setNextImplementation(address(0));
    _setNextImplementationTimestamp(0);
  }

  function shouldUpgrade() external view returns (bool, address) {
    return (
      nextImplementationTimestamp() != 0
        && block.timestamp > nextImplementationTimestamp()
        && nextImplementation() != address(0),
      nextImplementation()
    );
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract BaseUpgradeableResolverStorage {
  bytes32 internal constant _PAUSED_TRIGGERING_SLOT = 0xb39eacfef30dce8bf4d2a1c5e2b0c13a57748f43c411d367f32a3c0b373a0fd2;
  bytes32 internal constant _PROFIT_SHARING_TARGET_SLOT = 0x7efd8c16bc3c6e12a0af8e8d60f363ad4fbfb76959198a3b4fa2451c8b61360f;
  bytes32 internal constant _PROFIT_SHARING_TOKEN_TO_NATIVE_PRICEFEED_SLOT = 0x80b975bc5e76d9ae26fa73d022ca45acd59dc15f92020385bd6d5fd467284b08;
  bytes32 internal constant _GREAT_DEAL_RATIO_SLOT = 0xcfb514bf2c31d5828d2d3bff1fbebd93582c481a1cd796583ad6daeb51cedf36;
  bytes32 internal constant _PROFIT_SHARING_TOKEN_SLOT = 0x406c2950ca74957cee4ebed9a6daac5c5b97fceb405fa1eae4ebc01cbd61e099;
  bytes32 internal constant _CONTROLLER_SLOT = 0x70b3e8d18368bad384385907a3d89cfeecfe7c949e3ad705957a29512e260ec2;
  bytes32 internal constant _POKE_ME_SLOT = 0xc8e8ea5944ac445d6a6d8a4f7bcdd582856398bbc65a75356981628f30c6324d;
  bytes32 internal constant _GAS_FEE_PREMIUM_SLOT = 0xefe8fc35a91b0afe7baad82b4baf0c7e1279ea58ed2599ac12fe856e41826a2f;

  bytes32 internal constant _NEXT_IMPLEMENTATION_SLOT = 0xcfe905b661403e0f26512769ffd220899a7e83e70902b0e494ce2c2d8f6a6563;
  bytes32 internal constant _NEXT_IMPLEMENTATION_TIMESTAMP_SLOT = 0x03ac3c2f69082456ae0db3f2a1e5928d18e44938556e9d71462c4b83c57356c4;
  bytes32 internal constant _NEXT_IMPLEMENTATION_DELAY_SLOT = 0xf410e535ca71b322566106e38b02191b5c44412157ef838524bd18c56b5adb8b;

  constructor() {
    assert(_PAUSED_TRIGGERING_SLOT == bytes32(uint256(keccak256("eip1967.resolverStorage.pausedTriggering")) - 1));
    assert(_PROFIT_SHARING_TARGET_SLOT == bytes32(uint256(keccak256("eip1967.resolverStorage.profitSharingTarget")) - 1));
    assert(_PROFIT_SHARING_TOKEN_TO_NATIVE_PRICEFEED_SLOT == bytes32(uint256(keccak256("eip1967.resolverStorage.profitToNativeTokenPricefeed")) - 1));
    assert(_GREAT_DEAL_RATIO_SLOT == bytes32(uint256(keccak256("eip1967.resolverStorage.greatDealRatio")) - 1));
    assert(_PROFIT_SHARING_TOKEN_SLOT == bytes32(uint256(keccak256("eip1967.resolverStorage.profitSharingToken")) - 1));
    assert(_CONTROLLER_SLOT == bytes32(uint256(keccak256("eip1967.resolverStorage.controller")) - 1));
    assert(_POKE_ME_SLOT == bytes32(uint256(keccak256("eip1967.resolverStorage.pokeMe")) - 1));
    assert(_GAS_FEE_PREMIUM_SLOT == bytes32(uint256(keccak256("eip1967.resolverStorage.gasFeePremium")) - 1));

    assert(_NEXT_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.resolverStorage.nextImplementation")) - 1));
    assert(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT == bytes32(uint256(keccak256("eip1967.resolverStorage.nextImplementationTimestamp")) - 1));
    assert(_NEXT_IMPLEMENTATION_DELAY_SLOT == bytes32(uint256(keccak256("eip1967.resolverStorage.nextImplementationDelay")) - 1));
  }

  function _setController(address _address) internal {
    setAddress(_CONTROLLER_SLOT, _address);
  }

  function controller() public view returns (address) {
    return getAddress(_CONTROLLER_SLOT);
  }

  function _setPokeMe(address _address) internal {
    setAddress(_POKE_ME_SLOT, _address);
  }

  function pokeMe() public view returns (address) {
    return getAddress(_POKE_ME_SLOT);
  }

  function _setProfitSharingTokenToNativePriceFeed(address _address) internal {
    setAddress(_PROFIT_SHARING_TOKEN_TO_NATIVE_PRICEFEED_SLOT, _address);
  }

  function profitSharingTokenToNativePriceFeed() public virtual view returns (address) {
    return getAddress(_PROFIT_SHARING_TOKEN_TO_NATIVE_PRICEFEED_SLOT);
  }

  function _setProfitSharingTarget(address _address) internal {
    setAddress(_PROFIT_SHARING_TARGET_SLOT, _address);
  }

  function profitSharingTarget() public view returns (address) {
    return getAddress(_PROFIT_SHARING_TARGET_SLOT);
  }

  function _setProfitSharingToken(address _address) internal {
    setAddress(_PROFIT_SHARING_TOKEN_SLOT, _address);
  }

  function profitSharingToken() public view returns (address) {
    return getAddress(_PROFIT_SHARING_TOKEN_SLOT);
  }

  function _setGreatDealRatio(uint256 _value) internal {
    setUint256(_GREAT_DEAL_RATIO_SLOT, _value);
  }

  function greatDealRatio() public view returns (uint256) {
    return getUint256(_GREAT_DEAL_RATIO_SLOT);
  }

  function _setGasFeePremium(uint256 _value) internal {
    setUint256(_GAS_FEE_PREMIUM_SLOT, _value);
  }

  function gasFeePremium() public view returns (uint256) {
    return getUint256(_GAS_FEE_PREMIUM_SLOT);
  }

  // a flag for disabling any triggers for emergencies
  function _setPausedTriggering(bool _value) internal {
    setBoolean(_PAUSED_TRIGGERING_SLOT, _value);
  }

  function pausedTriggering() public view returns (bool) {
    return getBoolean(_PAUSED_TRIGGERING_SLOT);
  }

  // upgradeability
  function _setNextImplementation(address _address) internal {
    setAddress(_NEXT_IMPLEMENTATION_SLOT, _address);
  }

  function nextImplementation() public view returns (address) {
    return getAddress(_NEXT_IMPLEMENTATION_SLOT);
  }

  function _setNextImplementationTimestamp(uint256 _value) internal {
    setUint256(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT, _value);
  }

  function nextImplementationTimestamp() public view returns (uint256) {
    return getUint256(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT);
  }

  function _setNextImplementationDelay(uint256 _value) internal {
    setUint256(_NEXT_IMPLEMENTATION_DELAY_SLOT, _value);
  }

  function nextImplementationDelay() public view returns (uint256) {
    return getUint256(_NEXT_IMPLEMENTATION_DELAY_SLOT);
  }

  // generic slots
  function setBoolean(bytes32 slot, bool _value) internal {
    setUint256(slot, _value ? 1 : 0);
  }

  function getBoolean(bytes32 slot) internal view returns (bool) {
    return (getUint256(slot) == 1);
  }

  function setAddress(bytes32 slot, address _address) internal {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, _address)
    }
  }

  function setUint256(bytes32 slot, uint256 _value) internal {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, _value)
    }
  }

  function getAddress(bytes32 slot) internal view returns (address str) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  function getUint256(bytes32 slot) internal view returns (uint256 str) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./Storage.sol";

contract GovernableInit is Initializable {

  bytes32 internal constant _STORAGE_SLOT = 0xa7ec62784904ff31cbcc32d09932a58e7f1e4476e1d041995b37c917990b16dc;

  modifier onlyGovernance() {
    require(Storage(_storage()).isGovernance(msg.sender), "Not governance");
    _;
  }

  constructor() {
    assert(_STORAGE_SLOT == bytes32(uint256(keccak256("eip1967.governableInit.storage")) - 1));
  }

  function initialize(address _store) internal {
    _setStorage(_store);
  }

  function _setStorage(address newStorage) private {
    bytes32 slot = _STORAGE_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, newStorage)
    }
  }

  function setStorage(address _store) public onlyGovernance {
    require(_store != address(0), "new storage shouldn't be empty");
    _setStorage(_store);
  }

  function _storage() internal view returns (address str) {
    bytes32 slot = _STORAGE_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  function governance() public view returns (address) {
    return Storage(_storage()).governance();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Storage {
  address public governance;

  constructor() {
    governance = msg.sender;
  }

  modifier onlyGovernance() {
    require(isGovernance(msg.sender), "Not governance");
    _;
  }

  function setGovernance(address _governance) public onlyGovernance {
    require(_governance != address(0), "new governance shouldn't be empty");
    governance = _governance;
  }

  function isGovernance(address account) public view returns (bool) {
    return account == governance;
  }
}