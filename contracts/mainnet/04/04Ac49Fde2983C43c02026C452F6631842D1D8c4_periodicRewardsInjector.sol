// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "ConfirmedOwner.sol";
import "KeeperCompatibleInterface.sol";
import "Pausable.sol";
import "SafeERC20.sol";
import "IERC20.sol";
import "IChildChainStreamer.sol";


/**
 * @title The PeriodicRewardsInjector Contract
 * @author tritium.eth
 * @notice Modification of the Chainlink's EthBalanceMonitor to send ERC20s to a rewards streamer on a regular basis
 * @notice The contract includes the ability to withdraw eth and sweep all ERC20 tokens including the managed token to any address by the owner
 * see https://docs.chain.link/chainlink-automation/utility-contracts/
 */
contract periodicRewardsInjector is ConfirmedOwner, Pausable, KeeperCompatibleInterface {
    event gasTokenWithdrawn(uint256 amountWithdrawn, address recipient);
    event KeeperRegistryAddressUpdated(address oldAddress, address newAddress);
    event MinWaitPeriodUpdated(uint256 oldMinWaitPeriod, uint256 newMinWaitPeriod);
    event ERC20Swept(address indexed token, address recipient, uint256 amount);
    event injectionFailed(address gauge);
    event emissionsInjection(address gauge, uint256 amount);
    event forwardedCall(address targetContract);

    // events below here are debugging and should be removed
    event wrongCaller(address sender, address registry);
    event performedUpkeep(address[] needsFunding);

    error InvalidStreamerList();
    error OnlyKeeperRegistry(address sender);
    error DuplicateAddress(address duplicate);
    error ZeroAddress();

    struct Target {
        bool isActive;
        uint256 amountPerPeriod;
        uint8 maxPeriods;
        uint8 periodNumber;
        uint56 lastInjectionTimeStamp; // enough space for 2 trillion years
    }

    address private s_keeperRegistryAddress;
    uint256 private s_minWaitPeriodSeconds;
    address[] private s_streamerList;
    mapping(address => Target) internal s_targets;
    address private s_injectTokenAddress;

     /**
   * @param keeperRegistryAddress The address of the keeper registry contract
   * @param minWaitPeriodSeconds The minimum wait period for address between funding (for security)
   * @param injectTokenAddress The ERC20 token this contract should mange
   */
    constructor(address keeperRegistryAddress, uint256 minWaitPeriodSeconds, address injectTokenAddress)
    ConfirmedOwner(msg.sender) {
        setKeeperRegistryAddress(keeperRegistryAddress);
        setMinWaitPeriodSeconds(minWaitPeriodSeconds);
        setInjectTokenAddress(injectTokenAddress);
    }

    /**
     * @notice Sets the list of addresses to watch and their funding parameters
   * @param streamerAddresses the list of addresses to watch
   * @param amountsPerPeriod the minimum balances for each address
   * @param maxPeriods the amount to top up each address
   */
    function setRecipientList(
        address[] calldata streamerAddresses,
        uint256[] calldata amountsPerPeriod,
        uint8[] calldata maxPeriods
    ) external onlyOwner {
        if (streamerAddresses.length != amountsPerPeriod.length || streamerAddresses.length != maxPeriods.length) {
            revert InvalidStreamerList();
        }
        address[] memory oldstreamerList = s_streamerList;
        for (uint256 idx = 0; idx < oldstreamerList.length; idx++) {
            s_targets[oldstreamerList[idx]].isActive = false;
        }
        for (uint256 idx = 0; idx < streamerAddresses.length; idx++) {
            if (s_targets[streamerAddresses[idx]].isActive) {
                revert DuplicateAddress(streamerAddresses[idx]);
            }
            if (streamerAddresses[idx] == address(0)) {
                revert InvalidStreamerList();
            }
            if (amountsPerPeriod[idx] == 0) {
                revert InvalidStreamerList();
            }
            s_targets[streamerAddresses[idx]] = Target({
            isActive : true,
            amountPerPeriod : amountsPerPeriod[idx],
            maxPeriods : maxPeriods[idx],
            lastInjectionTimeStamp : 0,
            periodNumber : 0
            });
        }
        s_streamerList = streamerAddresses;
    }

    /**
     * @notice Gets a list of addresses that are ready to inject
   * @return list of addresses that are ready to inject
   */
    function getReadyStreamers() public view returns (address[] memory) {
        address[] memory streamerlist = s_streamerList;
        address[] memory ready = new address[](streamerlist.length);
        address tokenaddress = s_injectTokenAddress;
        uint256 count = 0;
        uint256 minWaitPeriod = s_minWaitPeriodSeconds;
        uint256 balance = IERC20(tokenaddress).balanceOf(address(this));
        Target memory target;
        for (uint256 idx = 0; idx < streamerlist.length; idx++) {
            target = s_targets[streamerlist[idx]];
            IChildChainStreamer streamer = IChildChainStreamer(streamerlist[idx]);
            if (
                target.lastInjectionTimeStamp + minWaitPeriod <= block.timestamp &&
                (streamer.reward_data(tokenaddress).period_finish <= block.timestamp)  &&
                balance >= target.amountPerPeriod &&
                target.periodNumber < target.maxPeriods
            ) {
                ready[count] = streamerlist[idx];
                count++;
                balance -= target.amountPerPeriod;
            }
        }
        if (count != streamerlist.length) {
            assembly {
                mstore(ready, count)
            }
        }
        return ready;
    }

    /**
     * @notice Injects funds into the streamers provided
   * @param ready the list of streamers to fund (addresses must be pre-approved)
   */
    function injectFunds(address[] memory ready) public whenNotPaused {
        uint256 minWaitPeriodSeconds = s_minWaitPeriodSeconds;
        address tokenaddress = s_injectTokenAddress;
        IERC20 token = IERC20(tokenaddress);
        address[] memory streamerlist = s_streamerList;
        uint256 balance = token.balanceOf(address(this));
        Target memory target;

        for (uint256 idx = 0; idx < ready.length; idx++) {
            target = s_targets[ready[idx]];
            IChildChainStreamer streamer = IChildChainStreamer(streamerlist[idx]);
            if (
                target.lastInjectionTimeStamp + s_minWaitPeriodSeconds <= block.timestamp &&
                streamer.reward_data(tokenaddress).period_finish <= block.timestamp  &&
                balance >= target.amountPerPeriod &&
                target.periodNumber < target.maxPeriods
            ) {
                try token.transfer(streamerlist[idx], target.amountPerPeriod) {
                    try streamer.notify_reward_amount(address(token)) {
                        s_targets[ready[idx]].lastInjectionTimeStamp = uint56(block.timestamp);
                        s_targets[ready[idx]].periodNumber += 1;
                        emit emissionsInjection(ready[idx], target.amountPerPeriod);
                    } catch {
                        emit injectionFailed(ready[idx]);
                        revert("Failed to call notify_reward_amount");
                    }
                    } catch {
                        emit injectionFailed(ready[idx]);
                        revert("Failed to transfer tokens");
                    }
                }
        }
    }

    /**
     * @notice Get list of addresses that are ready for new token injections and return keeper-compatible payload
   * @return upkeepNeeded signals if upkeep is needed, performData is an abi encoded list of addresses that need funds
   */
    function checkUpkeep(bytes calldata)
    external
    view
    override
    whenNotPaused
    returns (bool upkeepNeeded, bytes memory performData)
    {
        address[] memory ready = getReadyStreamers();
        upkeepNeeded = ready.length > 0;
        performData = abi.encode(ready);
        return (upkeepNeeded, performData);
    }

    /**
     * @notice Called by keeper to send funds to underfunded addresses
   * @param performData The abi encoded list of addresses to fund
   */
    function performUpkeep(bytes calldata performData) external override onlyKeeperRegistry whenNotPaused {
        address[] memory needsFunding = abi.decode(performData, (address[]));
        emit performedUpkeep(needsFunding);
        injectFunds(needsFunding);
    }

    /**
     * @notice Withdraws the contract balance
   * @param amount The amount of eth (in wei) to withdraw
   * @param recipient The address to pay
   */
    function withdrawGasToken(uint256 amount, address payable recipient) external onlyOwner {
        if (recipient == address(0)) {
            revert ZeroAddress();
        }
        emit gasTokenWithdrawn(amount, recipient);
        recipient.transfer(amount);
    }

    /**
     * @notice Sweep the full contract's balance for a given ERC-20 token
   * @param token The ERC-20 token which needs to be swept
   * @param recipient The address to pay
   */
    function sweep(address token, address recipient) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        emit ERC20Swept(token, recipient, balance);
        SafeERC20.safeTransfer(IERC20(token), recipient, balance);
    }

    /**
     * @notice Sets the keeper registry address
   */
    function setKeeperRegistryAddress(address keeperRegistryAddress) public onlyOwner {
        emit KeeperRegistryAddressUpdated(s_keeperRegistryAddress, keeperRegistryAddress);
        s_keeperRegistryAddress = keeperRegistryAddress;
    }

    /**
     * @notice Sets the minimum wait period (in seconds) for addresses between injections
   */
    function setMinWaitPeriodSeconds(uint256 period) public onlyOwner {
        emit MinWaitPeriodUpdated(s_minWaitPeriodSeconds, period);
        s_minWaitPeriodSeconds = period;
    }

    /**
     * @notice Gets the keeper registry address
   */
    function getKeeperRegistryAddress() external view returns (address keeperRegistryAddress) {
        return s_keeperRegistryAddress;
    }

    /**
     * @notice Gets the minimum wait period
   */
    function getMinWaitPeriodSeconds() external view returns (uint256) {
        return s_minWaitPeriodSeconds;
    }

    /**
     * @notice Gets the list of addresses on the in the current configuration.
   */
    function getWatchList() external view returns (address[] memory) {
        return s_streamerList;
    }

    /**
     * @notice Sets the address of the ERC20 token this contract should handle
   */
    function setInjectTokenAddress(address ERC20token) public onlyOwner {
        s_injectTokenAddress = ERC20token;
    }

    /**
     * @notice Gets configuration information for an address on the streamerlist
   */
    function getAccountInfo(address targetAddress)
    external
    view
    returns (
        bool isActive,
        uint256 amountPerPeriod,
        uint8 maxPeriods,
        uint8 periodNumber,
        uint56 lastInjectionTimeStamp
    )
    {
        Target memory target = s_targets[targetAddress];
        return (target.isActive, target.amountPerPeriod, target.maxPeriods, target.periodNumber, target.lastInjectionTimeStamp);
    }

    /**
     * @notice Pauses the contract, which prevents executing performUpkeep
   */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract
   */
    function unpause() external onlyOwner {
        _unpause();
    }

    modifier onlyKeeperRegistry() {
        if (msg.sender != s_keeperRegistryAddress) {
            emit wrongCaller(msg.sender, s_keeperRegistryAddress);
            revert OnlyKeeperRegistry(msg.sender);
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.6.6. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

interface IChildChainStreamer {
    event RewardDistributorUpdated(
        address indexed reward_token,
        address distributor
    );
    event RewardDurationUpdated(address indexed reward_token, uint256 duration);

    function add_reward(
        address _token,
        address _distributor,
        uint256 _duration
    ) external;

    function remove_reward(address _token, address _recipient) external;

    function get_reward() external;

    function notify_reward_amount(address _token) external;

    function set_reward_duration(address _token, uint256 _duration) external;

    function set_reward_distributor(
        address _token,
        address _distributor
    ) external;

    function initialize(address reward_receiver) external;

    function reward_receiver() external view returns (address);

    function reward_tokens(uint256 arg0) external view returns (address);

    function reward_count() external view returns (uint256);

    function reward_data(address arg0) external view returns (S_0 memory);

    function last_update_time() external view returns (uint256);
}

struct S_0 {
    address distributor;
    uint256 period_finish;
    uint256 rate;
    uint256 duration;
    uint256 received;
    uint256 paid;
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"name":"RewardDistributorUpdated","inputs":[{"name":"reward_token","type":"address","indexed":true},{"name":"distributor","type":"address","indexed":false}],"anonymous":false,"type":"event"},{"name":"RewardDurationUpdated","inputs":[{"name":"reward_token","type":"address","indexed":true},{"name":"duration","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"stateMutability":"nonpayable","type":"constructor","inputs":[{"name":"_bal_token","type":"address"},{"name":"_authorizerAdaptor","type":"address"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"add_reward","inputs":[{"name":"_token","type":"address"},{"name":"_distributor","type":"address"},{"name":"_duration","type":"uint256"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"remove_reward","inputs":[{"name":"_token","type":"address"},{"name":"_recipient","type":"address"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"get_reward","inputs":[],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"notify_reward_amount","inputs":[{"name":"_token","type":"address"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"set_reward_duration","inputs":[{"name":"_token","type":"address"},{"name":"_duration","type":"uint256"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"set_reward_distributor","inputs":[{"name":"_token","type":"address"},{"name":"_distributor","type":"address"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"initialize","inputs":[{"name":"reward_receiver","type":"address"}],"outputs":[]},{"stateMutability":"view","type":"function","name":"reward_receiver","inputs":[],"outputs":[{"name":"","type":"address"}]},{"stateMutability":"view","type":"function","name":"reward_tokens","inputs":[{"name":"arg0","type":"uint256"}],"outputs":[{"name":"","type":"address"}]},{"stateMutability":"view","type":"function","name":"reward_count","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"reward_data","inputs":[{"name":"arg0","type":"address"}],"outputs":[{"name":"","type":"tuple","components":[{"name":"distributor","type":"address"},{"name":"period_finish","type":"uint256"},{"name":"rate","type":"uint256"},{"name":"duration","type":"uint256"},{"name":"received","type":"uint256"},{"name":"paid","type":"uint256"}]}]},{"stateMutability":"view","type":"function","name":"last_update_time","inputs":[],"outputs":[{"name":"","type":"uint256"}]}]
*/