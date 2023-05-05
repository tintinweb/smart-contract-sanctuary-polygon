/**
 *Submitted for verification at polygonscan.com on 2023-05-04
*/

// File: @openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// File: @openzeppelin/contracts-upgradeable/proxy/beacon/IBeaconUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// File: @openzeppelin/contracts-upgradeable/interfaces/draft-IERC1822Upgradeable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// File: contracts/interfaces/staking/INFTStake.sol


pragma solidity ^0.8.7;

/**
 *  note:
 *  - Reward token and staking token can't be changed after deployment.
 *
 *  - ERC721 tokens from only the specified contract can be staked.
 *
 *  - All token/NFT transfers require approval on their respective contracts.
 *
 *  - Team members must deposit reward tokens using the `depositRewardTokens` function only.
 *    Any direct transfers may cause unintended consequences, such as locking of tokens.
 *
 *  - Users must stake NFTs using the `stake` function only.
 *    Any direct transfers may cause unintended consequences, such as locking of NFTs.
 */

interface INFTStake {
  /// @dev Emitted when contract team member withdraws reward tokens.
  event RewardTokensWithdrawnByAdmin(uint256 _amount);

  /// @dev Emitted when contract team member deposits reward tokens.
  event RewardTokensDepositedByAdmin(uint256 _amount);

  /**
   *  @notice Lets a contract team member deposit reward-tokens.
   *
   *          note: Tokens should be approved on the reward-token contract before depositing.
   *
   *  @param _amount     Amount of tokens to deposit.
   */
  function depositRewardTokens(uint256 _amount) external payable;

  /**
   *  @notice Lets a contract team member withdraw reward-tokens.
   *          Useful for removing excess balance, thus preventing locking of tokens.
   *
   *  @param _amount     Amount of tokens to deposit.
   */
  function withdrawRewardTokens(uint256 _amount) external;
}

// File: contracts/utils/IStaking721.sol


pragma solidity ^0.8.7;

interface IStaking721 {
  /// @dev Emitted when a set of token-ids are staked.
  event TokensStaked(address indexed staker, uint256[] indexed tokenIds);

  /// @dev Emitted when a set of staked token-ids are unstaked.
  event TokensUnstaked(address indexed staker, uint256[] indexed tokenIds);

  /// @dev Emitted when a staker claims staking rewards.
  event RewardsClaimed(address indexed staker, uint256 rewardAmount);

  /// @dev Emitted when contract team member updates staking condition (timeUnit and rewardsPerUnitTime).
  event UpdatedStakingCondition(
    uint256 oldTimeUnit,
    uint256 newTimeUnit,
    uint256 oldRewardsPerUnitTime,
    uint256 newRewardsPerUnitTime
  );

  /**
   *  @notice Staker Info.
   *
   *  @param amountStaked             Total number of tokens staked by the staker.
   *
   *  @param timeOfLastUpdate         Last reward-update timestamp.
   *
   *  @param unclaimedRewards         Rewards accumulated but not claimed by user yet.
   *
   *  @param lastUpdateConditionId  Condition-Id when rewards were last updated for user.
   */
  struct Staker {
    uint256 amountStaked;
    uint256 timeOfLastUpdate;
    uint256 unclaimedRewards;
    uint256 lastUpdateConditionId;
  }

  /**
   *  @notice Staking Condition.
   *
   *  @param timeUnit           Unit of time specified in number of seconds. Can be set as 1 seconds, 1 days, 1 hours, etc.
   *
   *  @param rewardsPerUnitTime Rewards accumulated per unit of time.
   *
   *  @param startTimestamp     Condition start timestamp.
   *
   *  @param endTimestamp       Condition end timestamp.
   */
  struct StakingCondition {
    uint256 timeUnit;
    uint256 rewardsPerUnitTime;
    uint256 startTimestamp;
    uint256 endTimestamp;
  }

  /**
   *  @notice Stake ERC721 Tokens.
   *
   *  @param tokenIds    List of tokens to stake.
   */
  function stake(uint256[] calldata tokenIds) external;

  /**
   *  @notice Unstake staked tokens.
   *
   *  @param tokenIds    List of tokens to unstake.
   */
  function unstake(uint256[] calldata tokenIds) external;

  /**
   *  @notice Claim accumulated rewards.
   */
  function claimRewards() external;

  /**
   *  @notice View amount staked and total rewards for a user.
   *
   *  @param staker    Address for which to calculated rewards.
   */
  function getStakeInfo(address staker)
    external
    view
    returns (uint256[] memory _tokensStaked, uint256 _rewards);
}

// File: contracts/registry/IRegistry.sol


pragma solidity ^0.8.7;

interface IRegistry {
  event Equipped(
    address indexed _721Address,
    uint256 indexed _721TokenId,
    address _1155Address,
    uint256[] _1155TokenIds,
    uint256[] _1155TokenQty
  );
  event Unequipped(
    address indexed _721Address,
    uint256 indexed _721TokenId,
    address _1155Address,
    uint256[] _1155TokenIds,
    uint256[] _1155TokenQtys
  );

  function getEquipmentsByToken(
    address contract721,
    uint256 tokenId,
    address contract1155
  ) external view returns (uint256[] memory);
}

// File: contracts/openzeppelin-presets/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, with an overflow flag.
   *
   * _Available since v3.4._
   */
  function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
      uint256 c = a + b;
      if (c < a) return (false, 0);
      return (true, c);
    }
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
   *
   * _Available since v3.4._
   */
  function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
      if (b > a) return (false, 0);
      return (true, a - b);
    }
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
   *
   * _Available since v3.4._
   */
  function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
      // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
      // benefit is lost if 'b' is also tested.
      // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
      if (a == 0) return (true, 0);
      uint256 c = a * b;
      if (c / a != b) return (false, 0);
      return (true, c);
    }
  }

  /**
   * @dev Returns the division of two unsigned integers, with a division by zero flag.
   *
   * _Available since v3.4._
   */
  function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
      if (b == 0) return (false, 0);
      return (true, a / b);
    }
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
   *
   * _Available since v3.4._
   */
  function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
      if (b == 0) return (false, 0);
      return (true, a % b);
    }
  }

  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   *
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    return a + b;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   *
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return a - b;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   *
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    return a * b;
  }

  /**
   * @dev Returns the integer division of two unsigned integers, reverting on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator.
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * reverting when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return a % b;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * CAUTION: This function is deprecated because it requires allocating memory for the error
   * message unnecessarily. For custom revert reasons use {trySub}.
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   *
   * - Subtraction cannot overflow.
   */
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    unchecked {
      require(b <= a, errorMessage);
      return a - b;
    }
  }

  /**
   * @dev Returns the integer division of two unsigned integers, reverting with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    unchecked {
      require(b > 0, errorMessage);
      return a / b;
    }
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * reverting with custom message when dividing by zero.
   *
   * CAUTION: This function is deprecated because it requires allocating memory for the error
   * message unnecessarily. For custom revert reasons use {tryMod}.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    unchecked {
      require(b > 0, errorMessage);
      return a % b;
    }
  }
}

// File: contracts/extension/interface/IContractMetadata.sol


pragma solidity ^0.8.0;

/**
 *  `ContractMetadata` is a contract extension for any base contracts. It lets you set a metadata URI
 *  for you contract.
 *
 *  Additionally, `ContractMetadata` is necessary for NFT contracts that want royalties to get distributed on OpenSea.
 */

interface IContractMetadata {
  /// @dev Returns the metadata URI of the contract.
  function contractURI() external view returns (string memory);

  /**
   *  @dev Sets contract URI for the storefront-level metadata of the contract.
   *       Only module team members can call this function.
   */
  function setContractURI(string calldata _uri) external;

  /// @dev Emitted when the contract URI is updated.
  event ContractURIUpdated(string prevURI, string newURI);
}

// File: contracts/extension/ContractMetadata.sol


pragma solidity ^0.8.0;


/**
 *  @title   Contract Metadata
 *  @notice  `ContractMetadata` is a contract extension for any base contracts. It lets you set a metadata URI
 *           for you contract.
 *           Additionally, `ContractMetadata` is necessary for NFT contracts that want royalties to get distributed on OpenSea.
 */

abstract contract ContractMetadata is IContractMetadata {
  /// @notice Returns the contract metadata URI.
  string public override contractURI;

  /**
   *  @notice         Lets a contract team member set the URI for contract-level metadata.
   *  @dev            Caller should be authorized to setup contractURI, e.g. contract team members.
   *                  See {_canManageContract}.
   *                  Emits {ContractURIUpdated Event}.
   *
   *  @param _uri     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
   */
  function setContractURI(string memory _uri) external override {
    if (!_canManageContract()) {
      revert("Not authorized");
    }

    _setContractURI(_uri);
  }

  /// @dev Lets a contract team member set the URI for contract-level metadata.
  function _setContractURI(string memory _uri) internal {
    string memory prevURI = contractURI;
    contractURI = _uri;

    emit ContractURIUpdated(prevURI, _uri);
  }

  /// @dev Returns whether contract metadata can be set in the given execution context.
  function _canManageContract() internal view virtual returns (bool);
}

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol


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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;




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

// File: contracts/interfaces/IWETH.sol


pragma solidity ^0.8.0;

interface IWETH {
  function deposit() external payable;

  function withdraw(uint256 amount) external;

  function transfer(address to, uint256 value) external returns (bool);
}

// File: contracts/lib/CurrencyTransferLib.sol


pragma solidity ^0.8.0;

// Helper interfaces



library CurrencyTransferLib {
  using SafeERC20 for IERC20;

  /// @dev The address interpreted as native token of the chain.
  address public constant NATIVE_TOKEN =
    0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  /// @dev Transfers a given amount of currency.
  function transferCurrency(
    address _currency,
    address _from,
    address _to,
    uint256 _amount
  ) internal {
    if (_amount == 0) {
      return;
    }

    if (_currency == NATIVE_TOKEN) {
      safeTransferNativeToken(_to, _amount);
    } else {
      safeTransferERC20(_currency, _from, _to, _amount);
    }
  }

  /// @dev Transfers a given amount of currency. (With native token wrapping)
  function transferCurrencyWithWrapper(
    address _currency,
    address _from,
    address _to,
    uint256 _amount,
    address _nativeTokenWrapper
  ) internal {
    if (_amount == 0) {
      return;
    }

    if (_currency == NATIVE_TOKEN) {
      if (_from == address(this)) {
        // withdraw from weth then transfer withdrawn native token to recipient
        IWETH(_nativeTokenWrapper).withdraw(_amount);
        safeTransferNativeTokenWithWrapper(_to, _amount, _nativeTokenWrapper);
      } else if (_to == address(this)) {
        // store native currency in weth
        require(_amount == msg.value, "msg.value != amount");
        IWETH(_nativeTokenWrapper).deposit{value: _amount}();
      } else {
        safeTransferNativeTokenWithWrapper(_to, _amount, _nativeTokenWrapper);
      }
    } else {
      safeTransferERC20(_currency, _from, _to, _amount);
    }
  }

  /// @dev Transfer `amount` of ERC20 token from `from` to `to`.
  function safeTransferERC20(
    address _currency,
    address _from,
    address _to,
    uint256 _amount
  ) internal {
    if (_from == _to) {
      return;
    }

    if (_from == address(this)) {
      IERC20(_currency).safeTransfer(_to, _amount);
    } else {
      IERC20(_currency).safeTransferFrom(_from, _to, _amount);
    }
  }

  /// @dev Transfers `amount` of native token to `to`.
  function safeTransferNativeToken(address to, uint256 value) internal {
    // solhint-disable avoid-low-level-calls
    // slither-disable-next-line low-level-calls
    (bool success, ) = to.call{value: value}("");
    require(success, "native token transfer failed");
  }

  /// @dev Transfers `amount` of native token to `to`. (With native token wrapping)
  function safeTransferNativeTokenWithWrapper(
    address to,
    uint256 value,
    address _nativeTokenWrapper
  ) internal {
    // solhint-disable avoid-low-level-calls
    // slither-disable-next-line low-level-calls
    (bool success, ) = to.call{value: value}("");
    if (!success) {
      IWETH(_nativeTokenWrapper).deposit{value: value}();
      IERC20(_nativeTokenWrapper).safeTransfer(to, value);
    }
  }
}

// File: @openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// File: @openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;






/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;




/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol


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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol


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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// File: contracts/utils/abstracts/TeamMembersUpgradeable.sol


pragma solidity ^0.8.7;


abstract contract TeamMembersUpgradeable is OwnableUpgradeable {
  mapping(address => bool) private members;

  function addTeamMember(address _address) public onlyOwner {
    require(_address != address(0));
    members[_address] = true;
  }

  function removeTeamMember(address _address) public onlyOwner {
    require(_address != address(0));

    delete members[_address];
  }

  function isTeamMember(address _address) public view returns (bool) {
    return members[_address] == true;
  }

  modifier onlyTeamOrOwner() {
    require(owner() == _msgSender() || isTeamMember(_msgSender()));
    _;
  }
}

// File: contracts/openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol


// OpenZeppelin Contracts v4.4.0 (metatx/ERC2771Context.sol)

pragma solidity ^0.8.7;



/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771ContextUpgradeable is
  Initializable,
  ContextUpgradeable
{
  mapping(address => bool) private _trustedForwarder;

  function __ERC2771Context_init(address[] memory trustedForwarder)
    internal
    onlyInitializing
  {
    __Context_init_unchained();
    __ERC2771Context_init_unchained(trustedForwarder);
  }

  function __ERC2771Context_init_unchained(address[] memory trustedForwarder)
    internal
    onlyInitializing
  {
    for (uint256 i = 0; i < trustedForwarder.length; i++) {
      _trustedForwarder[trustedForwarder[i]] = true;
    }
  }

  function isTrustedForwarder(address forwarder)
    public
    view
    virtual
    returns (bool)
  {
    return _trustedForwarder[forwarder];
  }

  function _msgSender()
    internal
    view
    virtual
    override
    returns (address sender)
  {
    if (isTrustedForwarder(msg.sender)) {
      // The assembly code is more direct than the Solidity version using `abi.decode`.
      assembly {
        sender := shr(96, calldataload(sub(calldatasize(), 20)))
      }
    } else {
      return super._msgSender();
    }
  }

  function _msgData() internal view virtual override returns (bytes calldata) {
    if (isTrustedForwarder(msg.sender)) {
      return msg.data[:msg.data.length - 20];
    } else {
      return super._msgData();
    }
  }

  uint256[49] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol


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
interface IERC165Upgradeable {
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

// File: @openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol


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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: contracts/utils/abstracts/Staking721Upgradeable.sol


pragma solidity ^0.8.7;






abstract contract Staking721Upgradeable is
  ReentrancyGuardUpgradeable,
  IStaking721
{
  uint256 private constant BASIS_POINTS = 10000;

  /*///////////////////////////////////////////////////////////////
                            State variables / Mappings
    //////////////////////////////////////////////////////////////*/

  ///@dev Address of ERC721 NFT contract -- staked tokens belong to this contract.
  address public stakingToken;

  ///@dev List of token-ids ever staked.
  uint256[] public indexedTokens;

  /// @dev List of accounts that have staked their NFTs.
  address[] public stakersArray;

  /// @dev Flag to check direct transfers of staking tokens.
  uint8 internal isStaking = 1;

  ///@dev Next staking condition Id. Tracks number of conditon updates so far.
  uint256 private nextConditionId;

  ///@dev Mapping from token-id to whether it is indexed or not.
  mapping(uint256 => bool) public isIndexed;

  ///@dev Mapping from staker address to Staker struct. See {struct IStaking721.Staker}.
  mapping(address => Staker) public stakers;

  /// @dev Mapping from staked token-id to staker address.
  mapping(uint256 => address) public tokenStakers;

  ///@dev Mapping from condition Id to staking condition. See {struct IStaking721.StakingCondition}
  mapping(uint256 => StakingCondition) private stakingConditions;

  ///@dev Address of registry contract where ERC1155 traits are stored.
  address public registry;

  ///@dev Address of ERC1155 contract for OneMint marketplace traits.
  address public traits;

  ///@dev Mapping from ERC1155 token-id to multiplier (basis points) for rewards calculation.
  mapping(uint256 => uint256) public traitsMultiplier;

  function __Staking721_init(address _stakingToken) internal onlyInitializing {
    __ReentrancyGuard_init();

    require(address(_stakingToken) != address(0), "collection address 0");
    stakingToken = _stakingToken;
  }

  /*///////////////////////////////////////////////////////////////
                        External/Public Functions
    //////////////////////////////////////////////////////////////*/

  /**
   *  @notice    Stake ERC721 Tokens.
   *
   *  @dev       See {_stake}. Override that to implement custom logic.
   *
   *  @param _tokenIds    List of tokens to stake.
   */
  function stake(uint256[] calldata _tokenIds) external override nonReentrant {
    _stake(_tokenIds);
  }

  /**
   *  @notice    Unstake staked tokens.
   *
   *  @dev       See {_stake}. Override that to implement custom logic.
   *
   *  @param _tokenIds    List of tokens to unstake.
   */
  function unstake(uint256[] calldata _tokenIds)
    external
    override
    nonReentrant
  {
    _unstake(_tokenIds);
  }

  /**
   *  @notice    Claim accumulated rewards.
   *
   *  @dev       See {_claimRewards}. Override that to implement custom logic.
   *             See {_calculateRewards} for reward-calculation logic.
   */
  function claimRewards() external override nonReentrant {
    _claimRewards();
  }

  /**
   *  @notice  Set time unit and rewards per unit of time.
   *           Interpreted as x rewards per second/per day/etc based on time-unit.
   *
   *  @dev     Only contract team member can call it.
   *
   *
   *  @param _timeUnit             New time unit.
   *  @param _rewardsPerUnitTime   New rewards per unit time.
   */
  function setStakingCondition(uint256 _timeUnit, uint256 _rewardsPerUnitTime)
    external
    virtual
  {
    if (!_canManageContract()) {
      revert("Not authorized");
    }

    StakingCondition memory condition = stakingConditions[nextConditionId - 1];
    require(
      _timeUnit != condition.timeUnit ||
        _rewardsPerUnitTime != condition.rewardsPerUnitTime,
      "Condition unchanged."
    );

    _setStakingCondition(_timeUnit, _rewardsPerUnitTime);

    emit UpdatedStakingCondition(
      condition.timeUnit,
      _timeUnit,
      condition.rewardsPerUnitTime,
      _rewardsPerUnitTime
    );
  }

  /**
   *  @notice View amount staked and total rewards for a user.
   *
   *  @param _staker          Address for which to calculated rewards.
   *  @return _tokensStaked   List of token-ids staked by staker.
   *  @return _rewards        Available reward amount.
   */
  function getStakeInfo(address _staker)
    public
    view
    virtual
    override
    returns (uint256[] memory _tokensStaked, uint256 _rewards)
  {
    _tokensStaked = _getStakedTokens(_staker);
    _rewards = _availableRewards(_staker);
  }

  function getTimeUnit() public view returns (uint256 _timeUnit) {
    _timeUnit = stakingConditions[nextConditionId - 1].timeUnit;
  }

  function getRewardsPerUnitTime()
    public
    view
    returns (uint256 _rewardsPerUnitTime)
  {
    _rewardsPerUnitTime = stakingConditions[nextConditionId - 1]
      .rewardsPerUnitTime;
  }

  function getStakersArray() public view returns (address[] memory _stakers) {
    _stakers = stakersArray;
  }

  function setRegistryTraits(address _registry, address _traits)
    external
    virtual
  {
    if (!_canManageContract()) {
      revert("Not authorized");
    }
    require(_registry != address(0) && _traits != address(0), "address 0");
    registry = _registry;
    traits = _traits;
  }

  function setTraitsMultiplier(
    uint256[] calldata _tokenIds,
    uint256[] calldata _multipliers
  ) external virtual {
    if (!_canManageContract()) {
      revert("Not authorized");
    }
    require(_tokenIds.length == _multipliers.length, "length mismatch");
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      traitsMultiplier[_tokenIds[i]] = _multipliers[i];
    }
  }

  /*///////////////////////////////////////////////////////////////
                            Internal Functions
    //////////////////////////////////////////////////////////////*/

  /// @dev Get list of token-ids currently staked by a user.
  function _getStakedTokens(address _staker)
    internal
    view
    virtual
    returns (uint256[] memory _tokensStaked)
  {
    uint256[] memory _indexedTokens = indexedTokens;
    bool[] memory _isStakerToken = new bool[](_indexedTokens.length);
    uint256 indexedTokenCount = _indexedTokens.length;
    uint256 stakerTokenCount = 0;

    for (uint256 i = 0; i < indexedTokenCount; i++) {
      _isStakerToken[i] = tokenStakers[_indexedTokens[i]] == _staker;
      if (_isStakerToken[i]) stakerTokenCount += 1;
    }

    _tokensStaked = new uint256[](stakerTokenCount);
    uint256 count = 0;
    for (uint256 i = 0; i < indexedTokenCount; i++) {
      if (_isStakerToken[i]) {
        _tokensStaked[count] = _indexedTokens[i];
        count += 1;
      }
    }
  }

  /// @dev Staking logic. Override to add custom logic.
  function _stake(uint256[] calldata _tokenIds) internal virtual {
    uint256 len = _tokenIds.length;
    require(len != 0, "0 tokens");

    address _stakingToken = stakingToken;

    if (stakers[_stakeMsgSender()].amountStaked > 0) {
      _updateUnclaimedRewardsForStaker(_stakeMsgSender());
    } else {
      stakersArray.push(_stakeMsgSender());
      stakers[_stakeMsgSender()].timeOfLastUpdate = block.timestamp;
      stakers[_stakeMsgSender()].lastUpdateConditionId = nextConditionId - 1;
    }
    for (uint256 i = 0; i < len; ++i) {
      require(
        IERC721(_stakingToken).ownerOf(_tokenIds[i]) == _stakeMsgSender() &&
          (IERC721(_stakingToken).getApproved(_tokenIds[i]) == address(this) ||
            IERC721(_stakingToken).isApprovedForAll(
              _stakeMsgSender(),
              address(this)
            )),
        "Not owned or approved"
      );

      isStaking = 2;
      IERC721(_stakingToken).safeTransferFrom(
        _stakeMsgSender(),
        address(this),
        _tokenIds[i]
      );
      isStaking = 1;

      tokenStakers[_tokenIds[i]] = _stakeMsgSender();

      if (!isIndexed[_tokenIds[i]]) {
        isIndexed[_tokenIds[i]] = true;
        indexedTokens.push(_tokenIds[i]);
      }
    }
    stakers[_stakeMsgSender()].amountStaked += len;

    emit TokensStaked(_stakeMsgSender(), _tokenIds);
  }

  /// @dev Unstake logic. Override to add custom logic.
  function _unstake(uint256[] calldata _tokenIds) internal virtual {
    uint256 _amountStaked = stakers[_stakeMsgSender()].amountStaked;
    uint256 len = _tokenIds.length;
    require(len != 0, "Unstaking 0 tokens");
    require(_amountStaked >= len, "Unstaking more than staked");

    address _stakingToken = stakingToken;

    _updateUnclaimedRewardsForStaker(_stakeMsgSender());

    if (_amountStaked == len) {
      address[] memory _stakersArray = stakersArray;
      for (uint256 i = 0; i < _stakersArray.length; ++i) {
        if (_stakersArray[i] == _stakeMsgSender()) {
          stakersArray[i] = _stakersArray[_stakersArray.length - 1];
          stakersArray.pop();
          break;
        }
      }
    }
    stakers[_stakeMsgSender()].amountStaked -= len;

    for (uint256 i = 0; i < len; ++i) {
      require(tokenStakers[_tokenIds[i]] == _stakeMsgSender(), "Not staker");
      tokenStakers[_tokenIds[i]] = address(0);
      IERC721(_stakingToken).safeTransferFrom(
        address(this),
        _stakeMsgSender(),
        _tokenIds[i]
      );
    }

    emit TokensUnstaked(_stakeMsgSender(), _tokenIds);
  }

  /// @dev Logic for claiming rewards. Override to add custom logic.
  function _claimRewards() internal virtual {
    uint256 rewards = stakers[_stakeMsgSender()].unclaimedRewards +
      _calculateRewards(_stakeMsgSender());

    require(rewards != 0, "No rewards");

    stakers[_stakeMsgSender()].timeOfLastUpdate = block.timestamp;
    stakers[_stakeMsgSender()].unclaimedRewards = 0;
    stakers[_stakeMsgSender()].lastUpdateConditionId = nextConditionId - 1;

    _mintRewards(_stakeMsgSender(), rewards);

    emit RewardsClaimed(_stakeMsgSender(), rewards);
  }

  /// @dev View available rewards for a user.
  function _availableRewards(address _user)
    internal
    view
    virtual
    returns (uint256 _rewards)
  {
    if (stakers[_user].amountStaked == 0) {
      _rewards = stakers[_user].unclaimedRewards;
    } else {
      _rewards = stakers[_user].unclaimedRewards + _calculateRewards(_user);
    }
  }

  /// @dev Update unclaimed rewards for a users. Called for every state change for a user.
  function _updateUnclaimedRewardsForStaker(address _staker) internal virtual {
    uint256 rewards = _calculateRewards(_staker);
    stakers[_staker].unclaimedRewards += rewards;
    stakers[_staker].timeOfLastUpdate = block.timestamp;
    stakers[_staker].lastUpdateConditionId = nextConditionId - 1;
  }

  /// @dev Set staking conditions.
  function _setStakingCondition(uint256 _timeUnit, uint256 _rewardsPerUnitTime)
    internal
    virtual
  {
    require(_timeUnit != 0, "time-unit can't be 0");
    uint256 conditionId = nextConditionId;
    nextConditionId += 1;

    stakingConditions[conditionId] = StakingCondition({
      timeUnit: _timeUnit,
      rewardsPerUnitTime: _rewardsPerUnitTime,
      startTimestamp: block.timestamp,
      endTimestamp: 0
    });

    if (conditionId > 0) {
      stakingConditions[conditionId - 1].endTimestamp = block.timestamp;
    }
  }

  /// @dev Calculate rewards for a staker.
  function _calculateRewards(address _staker)
    internal
    view
    virtual
    returns (uint256 _rewards)
  {
    Staker memory staker = stakers[_staker];

    uint256 _stakerConditionId = staker.lastUpdateConditionId;
    uint256 _nextConditionId = nextConditionId;

    uint256 totalBasisPoints;
    if (registry != address(0) && traits != address(0)) {
      uint256[] memory stakedTokens = _getStakedTokens(_staker);
      for (uint256 i = 0; i < stakedTokens.length; ++i) {
        uint256[] memory equippedTokens = IRegistry(registry)
          .getEquipmentsByToken(stakingToken, stakedTokens[i], traits);
        for (uint256 j = 0; j < equippedTokens.length; ++j) {
          totalBasisPoints += traitsMultiplier[equippedTokens[j]];
        }
      }
    }

    for (uint256 i = _stakerConditionId; i < _nextConditionId; i += 1) {
      StakingCondition memory condition = stakingConditions[i];

      uint256 startTime = i != _stakerConditionId
        ? condition.startTimestamp
        : staker.timeOfLastUpdate;
      uint256 endTime = condition.endTimestamp != 0
        ? condition.endTimestamp
        : block.timestamp;
      (bool noOverflowProduct, uint256 rewardsProduct) = SafeMath.tryMul(
        (endTime - startTime) * staker.amountStaked,
        condition.rewardsPerUnitTime
      );
      (bool noOverflowSum, uint256 rewardsSum) = SafeMath.tryAdd(
        _rewards,
        rewardsProduct / condition.timeUnit
      );

      _rewards = noOverflowProduct && noOverflowSum ? rewardsSum : _rewards;
    }

    if (totalBasisPoints > 0) {
      (bool noOverflowMultiplier, uint256 multiplierProduct) = SafeMath.tryMul(
        _rewards,
        totalBasisPoints
      );
      (bool noOverflow, uint256 rewardsWithMultiplier) = SafeMath.tryAdd(
        _rewards,
        multiplierProduct / BASIS_POINTS
      );
      _rewards = noOverflow && noOverflowMultiplier
        ? rewardsWithMultiplier
        : _rewards;
    }
  }

  /*////////////////////////////////////////////////////////////////////
        Optional hooks that can be implemented in the derived contract
    ///////////////////////////////////////////////////////////////////*/

  /// @dev Exposes the ability to override the msg sender -- support ERC2771.
  function _stakeMsgSender() internal virtual returns (address) {
    return msg.sender;
  }

  /*///////////////////////////////////////////////////////////////
        Virtual functions to be implemented in derived contract
    //////////////////////////////////////////////////////////////*/

  /**
   *  @notice View total rewards available in the staking contract.
   *
   */
  function getRewardTokenBalance()
    external
    view
    virtual
    returns (uint256 _rewardsAvailableInContract);

  /**
   *  @dev    Mint/Transfer ERC20 rewards to the staker. Must override.
   *
   *  @param _staker    Address for which to calculated rewards.
   *  @param _rewards   Amount of tokens to be given out as reward.
   *
   *  For example, override as below to mint ERC20 rewards:
   *
   * ```
   *  function _mintRewards(address _staker, uint256 _rewards) internal override {
   *
   *      TokenERC20(rewardTokenAddress).mintTo(_staker, _rewards);
   *
   *  }
   * ```
   */
  function _mintRewards(address _staker, uint256 _rewards) internal virtual;

  /**
   *  @dev    Returns whether staking restrictions can be set in given execution context.
   *          Must override.
   */
  function _canManageContract() internal view virtual returns (bool);
}

// File: contracts/NFTArtGenStaking.sol



pragma solidity ^0.8.7;
// Token




// Meta transactions


// Utils


//  ==========  Features    ==========






contract NFTArtGenStaking is
  Initializable,
  TeamMembersUpgradeable,
  ContractMetadata,
  ERC2771ContextUpgradeable,
  Staking721Upgradeable,
  ERC165Upgradeable,
  IERC721ReceiverUpgradeable,
  INFTStake
{
  uint256 private constant VERSION = 1;

  /// @dev The address of the native token wrapper contract.
  address internal nativeTokenWrapper;

  /// @dev ERC20 Reward Token address. See {_mintRewards} below.
  address public rewardToken;

  /// @dev Total amount of reward tokens in the contract.
  uint256 private rewardTokenBalance;

  /// @dev Initiliazes the contract, like a constructor.
  function __NFTArtGenStaking_init(
    address _nativeTokenWrapper,
    string memory _contractURI,
    address[] memory _trustedForwarders,
    address _rewardToken,
    address _stakingToken,
    uint256 _timeUnit,
    uint256 _rewardsPerUnitTime
  ) internal onlyInitializing {
    nativeTokenWrapper = _nativeTokenWrapper;
    __Ownable_init();
    __ERC2771Context_init_unchained(_trustedForwarders);

    rewardToken = _rewardToken;
    __Staking721_init(_stakingToken);
    _setStakingCondition(_timeUnit, _rewardsPerUnitTime);

    _setContractURI(_contractURI);
  }

  /// @dev Returns the version of the contract.
  function contractVersion() external pure virtual returns (uint8) {
    return uint8(VERSION);
  }

  /// @dev Lets the contract receive ether to unwrap native tokens.
  receive() external payable {
    require(
      msg.sender == nativeTokenWrapper,
      "caller not native token wrapper."
    );
  }

  /// @dev Team member deposits reward tokens.
  function depositRewardTokens(uint256 _amount)
    external
    payable
    override
    nonReentrant
  {
    require(_canManageContract(), "Not authorized");

    address _rewardToken = rewardToken == CurrencyTransferLib.NATIVE_TOKEN
      ? nativeTokenWrapper
      : rewardToken;

    uint256 balanceBefore = IERC20(_rewardToken).balanceOf(address(this));
    CurrencyTransferLib.transferCurrencyWithWrapper(
      rewardToken,
      _msgSender(),
      address(this),
      _amount,
      nativeTokenWrapper
    );
    uint256 actualAmount = IERC20(_rewardToken).balanceOf(address(this)) -
      balanceBefore;

    rewardTokenBalance += actualAmount;

    emit RewardTokensDepositedByAdmin(actualAmount);
  }

  /// @dev Team members can withdraw excess reward tokens.
  function withdrawRewardTokens(uint256 _amount) external override {
    require(_canManageContract(), "Not authorized");

    // to prevent locking of direct-transferred tokens
    rewardTokenBalance = _amount > rewardTokenBalance
      ? 0
      : rewardTokenBalance - _amount;

    CurrencyTransferLib.transferCurrencyWithWrapper(
      rewardToken,
      address(this),
      _msgSender(),
      _amount,
      nativeTokenWrapper
    );

    emit RewardTokensWithdrawnByAdmin(_amount);
  }

  /// @notice View total rewards available in the staking contract.
  function getRewardTokenBalance() external view override returns (uint256) {
    return rewardTokenBalance;
  }

  /*///////////////////////////////////////////////////////////////
                        ERC 165 / 721 logic
    //////////////////////////////////////////////////////////////*/

  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external view override returns (bytes4) {
    require(isStaking == 2, "Direct transfer");
    return this.onERC721Received.selector;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override
    returns (bool)
  {
    return
      interfaceId == type(IERC721ReceiverUpgradeable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /*///////////////////////////////////////////////////////////////
                        Transfer Staking Rewards
    //////////////////////////////////////////////////////////////*/

  /// @dev Mint/Transfer ERC20 rewards to the staker.
  function _mintRewards(address _staker, uint256 _rewards) internal override {
    require(_rewards <= rewardTokenBalance, "Not enough reward tokens");
    rewardTokenBalance -= _rewards;
    CurrencyTransferLib.transferCurrencyWithWrapper(
      rewardToken,
      address(this),
      _staker,
      _rewards,
      nativeTokenWrapper
    );
  }

  /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

  /// @dev Checks whether contract can be managed in the given execution context.
  function _canManageContract()
    internal
    view
    override(ContractMetadata, Staking721Upgradeable)
    returns (bool)
  {
    return owner() == _msgSender() || isTeamMember(_msgSender());
  }

  /*///////////////////////////////////////////////////////////////
                            Miscellaneous
    //////////////////////////////////////////////////////////////*/

  function _stakeMsgSender() internal view virtual override returns (address) {
    return _msgSender();
  }

  function _msgSender()
    internal
    view
    virtual
    override(ContextUpgradeable, ERC2771ContextUpgradeable)
    returns (address sender)
  {
    return ERC2771ContextUpgradeable._msgSender();
  }

  function _msgData()
    internal
    view
    virtual
    override(ContextUpgradeable, ERC2771ContextUpgradeable)
    returns (bytes calldata)
  {
    return ERC2771ContextUpgradeable._msgData();
  }
}

// File: contracts/NFTArtGenStakingImpl.sol




contract NFTArtGenStakingImpl is NFTArtGenStaking, UUPSUpgradeable {
  function initialize(
    address _nativeTokenWrapper,
    string memory _contractURI,
    address[] memory _trustedForwarders,
    address _rewardToken,
    address _stakingToken,
    uint256 _timeUnit,
    uint256 _rewardsPerUnitTime
  ) public initializer {
    __NFTArtGenStaking_init(
      _nativeTokenWrapper,
      _contractURI,
      _trustedForwarders,
      _rewardToken,
      _stakingToken,
      _timeUnit,
      _rewardsPerUnitTime
    );
  }

  function _authorizeUpgrade(address) internal override onlyOwner {}
}