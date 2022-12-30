/**
 *Submitted for verification at polygonscan.com on 2022-12-30
*/

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/utils/introspection/ERC165Checker.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;


/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

// File: RewardStrategy.sol


pragma solidity ^0.8.0;


interface RewardStrategy is IERC165 {
    function updateWeight(address _investor, uint oldWeight, uint oldTotalWeight, uint newWeight) external;
}
// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: Staking.sol


pragma solidity ^0.8.0;







contract Staking is Ownable, Pausable {
    using ERC165Checker for address;

    struct User {
        uint128 staked;
        uint128 weight;
        uint32 lockedUntil;
        uint32 boost; // 50% = 5000
        bool locked;
    }

    mapping(address => User) public users;
    mapping(address => bool) public authorizedBridges;

    uint128 public totalStaked; // Used for GUI
    uint128 public totalWeight; // Used by reward pools

    uint256 public stakingLimitPerWallet;

    uint16 public lockDurationInDays;
    uint8 public lockBoostFactor;
    IERC20 public stakedToken;

    RewardStrategy[] private rewards;

    event Stacked(address indexed to, uint amount, bool locked);
    event Unstacked(address indexed to, uint amount);
    event Compound(address indexed to, uint amount, address indexed contractAddress);

    event RewardContractAdded(address reward);
    event RewardContractRemoved(address reward);

    event BridgeAdded(address bridge);
    event BridgeRemoved(address bridge);

    event UpdatedWalletBoost(address indexed to, uint32 newBoost);
    event UpdatedStakingLimit(uint256 newLimit);
    event UpdatedLockBoostFactor(uint8 boostFactor);
    event UpdatedLockDurationInDays(uint16 lockDurationInDays);

    constructor(address tokenAddr, address owner) {
      stakedToken = IERC20(payable(tokenAddr));
      _transferOwnership(owner);
      lockBoostFactor = 3;
      lockDurationInDays = 30;
      stakingLimitPerWallet = 10_000_000 ether;
    }

    function stake(uint128 amount, bool locked) external whenNotPaused {
      User storage user = users[msg.sender];

      require(user.staked + amount <= stakingLimitPerWallet, "Wallet limit");

      // Update staked
      user.staked += amount;
      totalStaked += amount;

      // Apply locking rules
      if (locked) {
        user.lockedUntil = uint32(block.timestamp + (lockDurationInDays * 1 days));
      } else {
        require(user.lockedUntil < block.timestamp, "Cannot stake unlocked");
      }

      // Calculate new weight
      uint128 newWeight = calculateWeight(user.staked, user.boost, locked);

      // Notify all registered pools
      for(uint i; i < rewards.length; i++) {
        rewards[i].updateWeight(msg.sender, user.weight, totalWeight, newWeight);
      }

      // update state
      totalWeight = totalWeight - user.weight + newWeight;
      user.weight = newWeight;
      user.locked = locked;

      // Transfer stake
      stakedToken.transferFrom(msg.sender, address(this), amount);
      emit Stacked(msg.sender, amount, locked);
    }

    function unstake(uint128 amount) external whenNotPaused {
      User storage user = users[msg.sender];

      // Checks
      require(user.lockedUntil < block.timestamp, "Still locked");

      // Update staked
      // No need to check amount since it will fail if greater than staked
      user.staked -= amount;
      totalStaked -= amount;

      uint128 newWeight = calculateWeight(user.staked, user.boost, false);

      // Notify all registered pools
      for(uint i; i < rewards.length; i++) {
        rewards[i].updateWeight(msg.sender, user.weight, totalWeight, newWeight);
      }

      // Set new weight
      totalWeight = totalWeight - user.weight + newWeight;
      user.weight = newWeight;
      user.locked = false;

      // Redeem staked tokens
      stakedToken.transfer(msg.sender, amount);
      emit Unstacked(msg.sender, amount);
    }

    function updateBoost(address userAddress, uint32 newBoost) external {
      require(newBoost <= 5000, "Boost limit");
      require(authorizedBridges[msg.sender], "Only Bridge");

      User storage user = users[userAddress];

      // Calculate new weight
      uint128 newWeight = calculateWeight(user.staked, newBoost, user.locked);

      // Notify all registered pools
      for(uint i; i < rewards.length; i++) {
        rewards[i].updateWeight(msg.sender, user.weight, totalWeight, newWeight);
      }

      totalWeight = totalWeight - user.weight + newWeight;
      user.weight = newWeight;
      user.boost = newBoost;

      emit UpdatedWalletBoost(userAddress, newBoost);
    }

    function calculateWeight(uint staked, uint boost, bool locked) private view returns (uint128) {
      if (locked) {
        return uint128((lockBoostFactor * staked * (10000 + boost)) / 10000);
      } else {
        return uint128((staked * (10000 + boost)) / 10000);
      }
    }

    function compound(address userAddress, uint128 amount) external {
      // Check only contract can call it
      bool allowed = false;
      for(uint i; i < rewards.length; i++) {
        if (address(rewards[i]) == msg.sender) {
          allowed = true;
          break;
        }
      }
      require(allowed, "Only reward");

      User storage user = users[userAddress];

      // Update staked
      user.staked += amount;
      totalStaked += amount;

      // Calculate new weight
      uint128 newWeight = calculateWeight(user.staked, user.boost, user.locked);

      // Notify all registered pools
      for(uint i; i < rewards.length; i++) {
        rewards[i].updateWeight(userAddress, user.weight, totalWeight, newWeight);
      }

      // update state
      totalWeight = totalWeight - user.weight + newWeight;
      user.weight = newWeight;

      // Transfer stake
      stakedToken.transferFrom(msg.sender, address(this), amount);
      emit Compound(userAddress, amount, msg.sender);
    }

    function balanceOf(address account) external view returns (uint256) {
      return users[account].staked;
    }

    function weight(address _investor) external view returns (uint) {
      return users[_investor].weight;
    }

    // Admin features

    function addBridge(address bridge) external onlyOwner {
      authorizedBridges[bridge] = true;
      emit BridgeAdded(bridge);
    }

    function removeBridge(address bridge) external onlyOwner {
      authorizedBridges[bridge] = false;
      emit BridgeRemoved(bridge);
    }

    function addRewardContract(address _reward) external onlyOwner {
      require(_reward.supportsInterface(type(RewardStrategy).interfaceId), "Reward interface not supported");
      for (uint i; i < rewards.length; i++) {
        if (address(rewards[i]) == _reward) {
            revert("Already added");
        }
      }
      rewards.push(RewardStrategy(_reward));
      emit RewardContractAdded(_reward);
    }

    function isRewardContractConnected(address _reward) external view returns (bool) {
      for (uint i; i < rewards.length; i++) {
        if (address(rewards[i]) == _reward) {
            return true;
        }
      }
      return false;
    }

    function removeRewardContract(address _reward) external onlyOwner {
      for (uint i; i < rewards.length; i++) {
        if (address(rewards[i]) == _reward) {
            rewards[i] = rewards[rewards.length-1];
            rewards.pop();
            emit RewardContractRemoved(_reward);
        }
      }
    }

    function updatestakingLimitPerWallet(uint256 newLimit) external onlyOwner {
      stakingLimitPerWallet = newLimit;
      emit UpdatedStakingLimit(newLimit);
    }

    function updateLockBoostFactor(uint8 _boostFactor) external onlyOwner {
      lockBoostFactor = _boostFactor;
      emit UpdatedLockBoostFactor(_boostFactor);
    }

    function updateLockDurationInDays(uint16 _boostLockInDays) external onlyOwner {
      lockDurationInDays = _boostLockInDays;
      emit UpdatedLockDurationInDays(_boostLockInDays);
    }

    // Circuit breaker
    // Can pause the contract
    function pause() external onlyOwner {
      _pause();
    }

    function unpause() external onlyOwner {
      _unpause();
    }

    // Can rescue the funds if needed
    function rescueFunds() external onlyOwner {
      stakedToken.transfer(owner(), stakedToken.balanceOf(address(this)));
    }
}
// File: BaseReward.sol


pragma solidity ^0.8.0;






abstract contract BaseReward is RewardStrategy, Ownable, Pausable, ERC165 {

  Staking public stakingContract;

  constructor(address _stakingContract, address owner) {
    stakingContract = Staking(_stakingContract);
    _transferOwnership(owner);
  }

  modifier onlyStaking() {
    require(msg.sender == address(stakingContract), "Only staking");
    _;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
      //bytes4(keccak256('updateWeight(address,uint,uint,uint)'));
      return super.supportsInterface(interfaceId) ||
              interfaceId == type(RewardStrategy).interfaceId;
  }

  function rescueToken(address token) public onlyOwner {
    IERC20(token).transfer(owner(), IERC20(token).balanceOf(address(this)));
  }

  // Circuit breaker
  // Can pause the contract
  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }
}
// File: ERC20PoolReward.sol


pragma solidity ^0.8.0;



contract ERC20PoolReward is BaseReward {

    struct User {
        uint debt;
        uint accReward;
        uint claimed;
    }
    string public constant rewardStrategy = "ER20PoolReward";

    IERC20 public token;
    uint public totalAmount;
    uint public startDate;
    uint public endDate;

    mapping(address => User) private users;
    uint private accPerShare;
    uint private lastUpdate;
    uint private tokenPerSecond;

    event Claimed(address indexed to, uint amount);
    event Distribute(address _token, uint _amount, uint _startDate, uint _endDate);

    constructor(address _stakingContract, address owner)
      BaseReward(_stakingContract, owner) {
    }

    function distribute(address _token, uint _amount, uint _startDate, uint _endDate) external onlyOwner {
      require(totalAmount == 0, "Only once");
      require(_amount > 0, "Invalid amount");
      require(_endDate > _startDate, "End < Start");
      require(block.timestamp <= _startDate, "Now > Start");
      require(stakingContract.isRewardContractConnected(address(this)), 'Not connected');

      token = IERC20(_token);
      totalAmount = _amount;
      startDate = _startDate;
      endDate = _endDate;
      tokenPerSecond = totalAmount * 10**18 / (endDate - startDate);

      token.transferFrom(msg.sender, address(this), _amount);
      emit Distribute(_token, _amount, _startDate, _endDate);
    }

    function claimable(address _investor) public view returns (uint _amount) {
      User memory user = users[_investor];
      return _reward(stakingContract.weight(_investor)) - user.debt + user.accReward - user.claimed;
    }

    function claim() external whenNotPaused {
      uint _claimable = claimable(msg.sender) ;
      if (_claimable > 0){
        token.transfer(msg.sender, _claimable);
        users[msg.sender].claimed += _claimable;
      }
      emit Claimed(msg.sender, _claimable);
    }

    function compound() external whenNotPaused {
      uint _claimable = claimable(msg.sender) ;
      if (_claimable > 0){
        require(address(token) == address(stakingContract.stakedToken()), "Same tokens");
        token.approve(address(stakingContract), _claimable);
        stakingContract.compound(msg.sender, uint128(_claimable));
        users[msg.sender].claimed += _claimable;
      }
    }

    function updateWeight(address _investor, uint oldWeight, uint oldTotalWeight, uint newWeight)
      external override onlyStaking {

      if (startDate == 0) return;

      uint _now = block.timestamp;
      if (_now < startDate) return;

      User storage user = users[_investor];

      // Store pending rewards
      uint pending = _reward(oldWeight) - user.debt;
      if (pending > 0) {
        user.accReward += pending;
      }

      // Update accumulator
      uint _lastUpdate = lastUpdate == 0 ? startDate : lastUpdate;
      lastUpdate = _now;
      uint _end = _now > endDate ? endDate : _now;
      if (_lastUpdate < _end && oldTotalWeight > 0) {
        accPerShare += tokenPerSecond * (_end - _lastUpdate) / oldTotalWeight;
      }

      // Update users debt
      user.debt = _reward(newWeight);
    }

    function _reward(uint weight) internal view returns (uint _amount) {
      uint _now = block.timestamp;
      if (_now < startDate || startDate == 0) return 0;
      uint _end = _now > endDate ? endDate : _now;
      uint _lastUpdate = lastUpdate == 0 ? startDate : lastUpdate;

      uint _accPerShare = accPerShare;
      if (_lastUpdate < _end) {
        uint _weight = stakingContract.totalWeight();
        if (_weight > 0) _accPerShare += tokenPerSecond * (_end - _lastUpdate) / _weight;
      }

      return _accPerShare * weight / 10**18;
    }

    // Can rescue the funds if needed
    function rescueFunds() external onlyOwner {
      super.rescueToken(address(token));
    }
}