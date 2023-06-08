// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IControllable {

  function isController(address _contract) external view returns (bool);

  function isGovernance(address _contract) external view returns (bool);

  function created() external view returns (uint256);

  function createdBlock() external view returns (uint256);

  function controller() external view returns (address);

  function increaseRevision(address oldLogic) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IController {

  // --- DEPENDENCY ADDRESSES
  function governance() external view returns (address);

  function voter() external view returns (address);

  function liquidator() external view returns (address);

  function forwarder() external view returns (address);

  function investFund() external view returns (address);

  function veDistributor() external view returns (address);

  function platformVoter() external view returns (address);

  // --- VAULTS

  function vaults(uint id) external view returns (address);

  function vaultsList() external view returns (address[] memory);

  function vaultsListLength() external view returns (uint);

  function isValidVault(address _vault) external view returns (bool);

  // --- restrictions

  function isOperator(address _adr) external view returns (bool);


}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

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

pragma solidity 0.8.17;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint);

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
  function approve(address spender, uint amount) external returns (bool);

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
    uint amount
  ) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity 0.8.17;

import "./IERC20.sol";

/**
 * https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/release-v4.6/contracts/token/ERC20/extensions/IERC20MetadataUpgradeable.sol
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity 0.8.17;

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

pragma solidity 0.8.17;

interface IForwarder {

  function tetu() external view returns (address);
  function tetuThreshold() external view returns (uint);

  function tokenPerDestinationLength(address destination) external view returns (uint);

  function tokenPerDestinationAt(address destination, uint i) external view returns (address);

  function amountPerDestination(address token, address destination) external view returns (uint amount);

  function registerIncome(
    address[] memory tokens,
    uint[] memory amounts,
    address vault,
    bool isDistribute
  ) external;

  function distributeAll(address destination) external;

  function distribute(address token) external;

  function setInvestFundRatio(uint value) external;

  function setGaugesRatio(uint value) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ISplitter {

  function init(address controller_, address _asset, address _vault) external;

  // *************** ACTIONS **************

  function withdrawAllToVault() external;

  function withdrawToVault(uint256 amount) external;

  function coverPossibleStrategyLoss(uint earned, uint lost) external;

  function doHardWork() external;

  function investAll() external;

  // **************** VIEWS ***************

  function asset() external view returns (address);

  function vault() external view returns (address);

  function totalAssets() external view returns (uint256);

  function isHardWorking() external view returns (bool);

  function strategies(uint i) external view returns (address);

  function strategiesLength() external view returns (uint);

  function HARDWORK_DELAY() external view returns (uint);

  function lastHardWorks(address strategy) external view returns (uint);

  function pausedStrategies(address strategy) external view returns (bool);

  function pauseInvesting(address strategy) external;

  function continueInvesting(address strategy, uint apr) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IStrategyV2 {

  function NAME() external view returns (string memory);

  function strategySpecificName() external view returns (string memory);

  function PLATFORM() external view returns (string memory);

  function STRATEGY_VERSION() external view returns (string memory);

  function asset() external view returns (address);

  function splitter() external view returns (address);

  function compoundRatio() external view returns (uint);

  function totalAssets() external view returns (uint);

  /// @dev Usually, indicate that claimable rewards have reasonable amount.
  function isReadyToHardWork() external view returns (bool);

  /// @return strategyLoss Loss should be covered from Insurance
  function withdrawAllToSplitter() external returns (uint strategyLoss);

  /// @return strategyLoss Loss should be covered from Insurance
  function withdrawToSplitter(uint amount) external returns (uint strategyLoss);

  /// @notice Stakes everything the strategy holds into the reward pool.
  /// @param amount_ Amount transferred to the strategy balance just before calling this function
  /// @param updateTotalAssetsBeforeInvest_ Recalculate total assets amount before depositing.
  ///                                       It can be false if we know exactly, that the amount is already actual.
  /// @return strategyLoss Loss should be covered from Insurance
  function investAll(
    uint amount_,
    bool updateTotalAssetsBeforeInvest_
  ) external returns (
    uint strategyLoss
  );

  function doHardWork() external returns (uint earned, uint lost);

  function setCompoundRatio(uint value) external;

  /// @notice Max amount that can be deposited to the strategy (its internal capacity), see SCB-593.
  ///         0 means no deposit is allowed at this moment
  function capacity() external view returns (uint);

  /// @notice {performanceFee}% of total profit is sent to the {performanceReceiver} before compounding
  function performanceReceiver() external view returns (address);

  /// @notice A percent of total profit that is sent to the {performanceReceiver} before compounding
  /// @dev use FEE_DENOMINATOR
  function performanceFee() external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface ITetuLiquidator {

  struct PoolData {
    address pool;
    address swapper;
    address tokenIn;
    address tokenOut;
  }

  function addLargestPools(PoolData[] memory _pools, bool rewrite) external;

  function addBlueChipsPools(PoolData[] memory _pools, bool rewrite) external;

  function getPrice(address tokenIn, address tokenOut, uint amount) external view returns (uint);

  function getPriceForRoute(PoolData[] memory route, uint amount) external view returns (uint);

  function isRouteExist(address tokenIn, address tokenOut) external view returns (bool);

  function buildRoute(
    address tokenIn,
    address tokenOut
  ) external view returns (PoolData[] memory route, string memory errorMessage);

  function liquidate(
    address tokenIn,
    address tokenOut,
    uint amount,
    uint slippage
  ) external;

  function liquidateWithRoute(
    PoolData[] memory route,
    uint amount,
    uint slippage
  ) external;


}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IVaultInsurance.sol";
import "./IERC20.sol";
import "./ISplitter.sol";

interface ITetuVaultV2 {

  function splitter() external view returns (ISplitter);

  function insurance() external view returns (IVaultInsurance);

  function depositFee() external view returns (uint);

  function withdrawFee() external view returns (uint);

  function init(
    address controller_,
    IERC20 _asset,
    string memory _name,
    string memory _symbol,
    address _gauge,
    uint _buffer
  ) external;

  function setSplitter(address _splitter) external;

  function coverLoss(uint amount) external;

  function initInsurance(IVaultInsurance _insurance) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IVaultInsurance {

  function init(address _vault, address _asset) external;

  function vault() external view returns (address);

  function asset() external view returns (address);

  function transferToVault(uint amount) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @title Library for interface IDs
/// @author bogdoslav
library InterfaceIds {

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant INTERFACE_IDS_LIB_VERSION = "1.0.0";

  /// default notation:
  /// bytes4 public constant I_VOTER = type(IVoter).interfaceId;

  /// As type({Interface}).interfaceId can be changed,
  /// when some functions changed at the interface,
  /// so used hardcoded interface identifiers

  bytes4 public constant I_VOTER = bytes4(keccak256("IVoter"));
  bytes4 public constant I_BRIBE = bytes4(keccak256("IBribe"));
  bytes4 public constant I_GAUGE = bytes4(keccak256("IGauge"));
  bytes4 public constant I_VE_TETU = bytes4(keccak256("IVeTetu"));
  bytes4 public constant I_SPLITTER = bytes4(keccak256("ISplitter"));
  bytes4 public constant I_FORWARDER = bytes4(keccak256("IForwarder"));
  bytes4 public constant I_MULTI_POOL = bytes4(keccak256("IMultiPool"));
  bytes4 public constant I_CONTROLLER = bytes4(keccak256("IController"));
  bytes4 public constant I_TETU_ERC165 = bytes4(keccak256("ITetuERC165"));
  bytes4 public constant I_STRATEGY_V2 = bytes4(keccak256("IStrategyV2"));
  bytes4 public constant I_CONTROLLABLE = bytes4(keccak256("IControllable"));
  bytes4 public constant I_TETU_VAULT_V2 = bytes4(keccak256("ITetuVaultV2"));
  bytes4 public constant I_PLATFORM_VOTER = bytes4(keccak256("IPlatformVoter"));
  bytes4 public constant I_VE_DISTRIBUTOR = bytes4(keccak256("IVeDistributor"));
  bytes4 public constant I_TETU_CONVERTER = bytes4(keccak256("ITetuConverter"));
  bytes4 public constant I_VAULT_INSURANCE = bytes4(keccak256("IVaultInsurance"));
  bytes4 public constant I_STRATEGY_STRICT = bytes4(keccak256("IStrategyStrict"));
  bytes4 public constant I_ERC4626 = bytes4(keccak256("IERC4626"));

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @title Library for setting / getting slot variables (used in upgradable proxy contracts)
/// @author bogdoslav
library SlotsLib {

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant SLOT_LIB_VERSION = "1.0.0";

  // ************* GETTERS *******************

  /// @dev Gets a slot as bytes32
  function getBytes32(bytes32 slot) internal view returns (bytes32 result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot as an address
  function getAddress(bytes32 slot) internal view returns (address result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot as uint256
  function getUint(bytes32 slot) internal view returns (uint result) {
    assembly {
      result := sload(slot)
    }
  }

  // ************* ARRAY GETTERS *******************

  /// @dev Gets an array length
  function arrayLength(bytes32 slot) internal view returns (uint result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot array by index as address
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function addressAt(bytes32 slot, uint index) internal view returns (address result) {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      result := sload(pointer)
    }
  }

  /// @dev Gets a slot array by index as uint
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function uintAt(bytes32 slot, uint index) internal view returns (uint result) {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      result := sload(pointer)
    }
  }

  // ************* SETTERS *******************

  /// @dev Sets a slot with bytes32
  /// @notice Check address for 0 at the setter
  function set(bytes32 slot, bytes32 value) internal {
    assembly {
      sstore(slot, value)
    }
  }

  /// @dev Sets a slot with address
  /// @notice Check address for 0 at the setter
  function set(bytes32 slot, address value) internal {
    assembly {
      sstore(slot, value)
    }
  }

  /// @dev Sets a slot with uint
  function set(bytes32 slot, uint value) internal {
    assembly {
      sstore(slot, value)
    }
  }

  // ************* ARRAY SETTERS *******************

  /// @dev Sets a slot array at index with address
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function setAt(bytes32 slot, uint index, address value) internal {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      sstore(pointer, value)
    }
  }

  /// @dev Sets a slot array at index with uint
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function setAt(bytes32 slot, uint index, uint value) internal {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      sstore(pointer, value)
    }
  }

  /// @dev Sets an array length
  function setLength(bytes32 slot, uint length) internal {
    assembly {
      sstore(slot, length)
    }
  }

  /// @dev Pushes an address to the array
  function push(bytes32 slot, address value) internal {
    uint length = arrayLength(slot);
    setAt(slot, length, value);
    setLength(slot, length + 1);
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity 0.8.17;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity 0.8.17;

import "../interfaces/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity 0.8.17;

import "./Address.sol";

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
  modifier initializer() {
    bool isTopLevelCall = !_initializing;
    require(
      (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
  function _disableInitializers() internal virtual {
    require(!_initializing, "Initializable: contract is initializing");
    if (_initialized != type(uint8).max) {
      _initialized = type(uint8).max;
      emit Initialized(type(uint8).max);
    }
  }

  /**
   * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
  function _getInitializedVersion() internal view returns (uint8) {
    return _initialized;
  }

  /**
   * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
  function _isInitializing() internal view returns (bool) {
    return _initializing;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity 0.8.17;

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
    return a > b ? a : b;
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
    require(denominator > prod1, "Math: mulDiv overflow");

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
   * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
  function sqrt(uint256 a) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
    //
    // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
    // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
    //
    // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
    // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
    // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
    //
    // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
    uint256 result = 1 << (log2(a) >> 1);

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
  unchecked {
    uint256 result = sqrt(a);
    return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
  }
  }

  /**
   * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
  function log2(uint256 value) internal pure returns (uint256) {
    uint256 result = 0;
  unchecked {
    if (value >> 128 > 0) {
      value >>= 128;
      result += 128;
    }
    if (value >> 64 > 0) {
      value >>= 64;
      result += 64;
    }
    if (value >> 32 > 0) {
      value >>= 32;
      result += 32;
    }
    if (value >> 16 > 0) {
      value >>= 16;
      result += 16;
    }
    if (value >> 8 > 0) {
      value >>= 8;
      result += 8;
    }
    if (value >> 4 > 0) {
      value >>= 4;
      result += 4;
    }
    if (value >> 2 > 0) {
      value >>= 2;
      result += 2;
    }
    if (value >> 1 > 0) {
      result += 1;
    }
  }
    return result;
  }

  /**
   * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
  function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
  unchecked {
    uint256 result = log2(value);
    return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
  }
  }

  /**
   * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
  function log10(uint256 value) internal pure returns (uint256) {
    uint256 result = 0;
  unchecked {
    if (value >= 10**64) {
      value /= 10**64;
      result += 64;
    }
    if (value >= 10**32) {
      value /= 10**32;
      result += 32;
    }
    if (value >= 10**16) {
      value /= 10**16;
      result += 16;
    }
    if (value >= 10**8) {
      value /= 10**8;
      result += 8;
    }
    if (value >= 10**4) {
      value /= 10**4;
      result += 4;
    }
    if (value >= 10**2) {
      value /= 10**2;
      result += 2;
    }
    if (value >= 10**1) {
      result += 1;
    }
  }
    return result;
  }

  /**
   * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
  function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
  unchecked {
    uint256 result = log10(value);
    return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
  }
  }

  /**
   * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
  function log256(uint256 value) internal pure returns (uint256) {
    uint256 result = 0;
  unchecked {
    if (value >> 128 > 0) {
      value >>= 128;
      result += 16;
    }
    if (value >> 64 > 0) {
      value >>= 64;
      result += 8;
    }
    if (value >> 32 > 0) {
      value >>= 32;
      result += 4;
    }
    if (value >> 16 > 0) {
      value >>= 16;
      result += 2;
    }
    if (value >> 8 > 0) {
      result += 1;
    }
  }
    return result;
  }

  /**
   * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
  function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
  unchecked {
    uint256 result = log256(value);
    return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
  }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity 0.8.17;

import "../interfaces/IERC20.sol";
import "../interfaces/IERC20Permit.sol";
import "./Address.sol";

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

pragma solidity 0.8.17;

import "../openzeppelin/Initializable.sol";
import "../tools/TetuERC165.sol";
import "../interfaces/IControllable.sol";
import "../interfaces/IController.sol";
import "../lib/SlotsLib.sol";
import "../lib/InterfaceIds.sol";

/// @title Implement basic functionality for any contract that require strict control
/// @dev Can be used with upgradeable pattern.
///      Require call __Controllable_init() in any case.
/// @author belbix
abstract contract ControllableV3 is Initializable, TetuERC165, IControllable {
  using SlotsLib for bytes32;

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant CONTROLLABLE_VERSION = "3.0.0";

  bytes32 internal constant _CONTROLLER_SLOT = bytes32(uint256(keccak256("eip1967.controllable.controller")) - 1);
  bytes32 internal constant _CREATED_SLOT = bytes32(uint256(keccak256("eip1967.controllable.created")) - 1);
  bytes32 internal constant _CREATED_BLOCK_SLOT = bytes32(uint256(keccak256("eip1967.controllable.created_block")) - 1);
  bytes32 internal constant _REVISION_SLOT = bytes32(uint256(keccak256("eip1967.controllable.revision")) - 1);
  bytes32 internal constant _PREVIOUS_LOGIC_SLOT = bytes32(uint256(keccak256("eip1967.controllable.prev_logic")) - 1);

  event ContractInitialized(address controller, uint ts, uint block);
  event RevisionIncreased(uint value, address oldLogic);

  /// @dev Prevent implementation init
  constructor() {
    _disableInitializers();
  }

  /// @notice Initialize contract after setup it as proxy implementation
  ///         Save block.timestamp in the "created" variable
  /// @dev Use it only once after first logic setup
  /// @param controller_ Controller address
  function __Controllable_init(address controller_) internal onlyInitializing {
    require(controller_ != address(0), "Zero controller");
    _requireInterface(controller_, InterfaceIds.I_CONTROLLER);
    require(IController(controller_).governance() != address(0), "Zero governance");
    _CONTROLLER_SLOT.set(controller_);
    _CREATED_SLOT.set(block.timestamp);
    _CREATED_BLOCK_SLOT.set(block.number);
    emit ContractInitialized(controller_, block.timestamp, block.number);
  }

  /// @dev Return true if given address is controller
  function isController(address _value) public override view returns (bool) {
    return _value == controller();
  }

  /// @notice Return true if given address is setup as governance in Controller
  function isGovernance(address _value) public override view returns (bool) {
    return IController(controller()).governance() == _value;
  }

  /// @dev Contract upgrade counter
  function revision() external view returns (uint){
    return _REVISION_SLOT.getUint();
  }

  /// @dev Previous logic implementation
  function previousImplementation() external view returns (address){
    return _PREVIOUS_LOGIC_SLOT.getAddress();
  }

  /// @dev See {IERC165-supportsInterface}.
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == InterfaceIds.I_CONTROLLABLE || super.supportsInterface(interfaceId);
  }

  // ************* SETTERS/GETTERS *******************

  /// @notice Return controller address saved in the contract slot
  function controller() public view override returns (address) {
    return _CONTROLLER_SLOT.getAddress();
  }

  /// @notice Return creation timestamp
  /// @return Creation timestamp
  function created() external view override returns (uint256) {
    return _CREATED_SLOT.getUint();
  }

  /// @notice Return creation block number
  /// @return Creation block number
  function createdBlock() external override view returns (uint256) {
    return _CREATED_BLOCK_SLOT.getUint();
  }

  /// @dev Revision should be increased on each contract upgrade
  function increaseRevision(address oldLogic) external override {
    require(msg.sender == address(this), "Increase revision forbidden");
    uint r = _REVISION_SLOT.getUint() + 1;
    _REVISION_SLOT.set(r);
    _PREVIOUS_LOGIC_SLOT.set(oldLogic);
    emit RevisionIncreased(r, oldLogic);
  }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IStrategyV2.sol";
import "../interfaces/ISplitter.sol";
import "../interfaces/IForwarder.sol";
import "../proxy/ControllableV3.sol";
import "./StrategyLib.sol";

/// @title Abstract contract for base strategy functionality
/// @author belbix
abstract contract StrategyBaseV2 is IStrategyV2, ControllableV3 {
  using SafeERC20 for IERC20;

  // *************************************************************
  //                        CONSTANTS
  // *************************************************************

  /// @dev Version of this contract. Adjust manually on each code modification.
  string public constant STRATEGY_BASE_VERSION = "2.3.0";
  /// @notice 10% of total profit is sent to {performanceReceiver} before compounding
  uint internal constant DEFAULT_PERFORMANCE_FEE = 10_000;
  address internal constant DEFAULT_PERF_FEE_RECEIVER = 0x9Cc199D4353b5FB3e6C8EEBC99f5139e0d8eA06b;

  // *************************************************************
  //                        VARIABLES
  //                Keep names and ordering!
  //                 Add only in the bottom.
  // *************************************************************

  /// @dev Underlying asset
  address public override asset;
  /// @dev Linked splitter
  address public override splitter;
  /// @dev Percent of profit for autocompound inside this strategy.
  uint public override compoundRatio;
  uint private __deprecatedSlot1;

  /// @notice {performanceFee}% of total profit is sent to {performanceReceiver} before compounding
  /// @dev governance by default
  address public override performanceReceiver;

  /// @notice A percent of total profit that is sent to the {performanceReceiver} before compounding
  /// @dev {DEFAULT_PERFORMANCE_FEE} by default, FEE_DENOMINATOR is used
  uint public override performanceFee;
  /// @dev Represent specific name for this strategy. Should include short strategy name and used assets. Uniq across the vault.
  string public override strategySpecificName;

  // *************************************************************
  //                        INIT
  // *************************************************************

  /// @notice Initialize contract after setup it as proxy implementation
  function __StrategyBase_init(
    address controller_,
    address _splitter
  ) internal onlyInitializing {
    _requireInterface(_splitter, InterfaceIds.I_SPLITTER);
    __Controllable_init(controller_);

    require(IControllable(_splitter).isController(controller_), StrategyLib.WRONG_VALUE);

    asset = ISplitter(_splitter).asset();
    splitter = _splitter;

    performanceReceiver = DEFAULT_PERF_FEE_RECEIVER;
    performanceFee = DEFAULT_PERFORMANCE_FEE;
  }

  // *************************************************************
  //                     PERFORMANCE FEE
  // *************************************************************
  /// @notice Set performance fee and receiver
  function setupPerformanceFee(uint fee_, address receiver_) external {
    StrategyLib._checkSetupPerformanceFee(controller(), fee_, receiver_);
    performanceFee = fee_;
    performanceReceiver = receiver_;
  }

  // *************************************************************
  //                        VIEWS
  // *************************************************************

  /// @dev Total amount of underlying assets under control of this strategy.
  function totalAssets() public view override returns (uint) {
    return IERC20(asset).balanceOf(address(this)) + investedAssets();
  }

  /// @dev See {IERC165-supportsInterface}.
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == InterfaceIds.I_STRATEGY_V2 || super.supportsInterface(interfaceId);
  }

  // *************************************************************
  //                   VOTER ACTIONS
  // *************************************************************

  /// @dev PlatformVoter can change compound ratio for some strategies.
  ///      A strategy can implement another logic for some uniq cases.
  function setCompoundRatio(uint value) external virtual override {
    StrategyLib._checkCompoundRatioChanged(controller(), compoundRatio, value);
    compoundRatio = value;
  }

  // *************************************************************
  //                   OPERATOR ACTIONS
  // *************************************************************

  /// @dev The name will be used for UI.
  function setStrategySpecificName(string calldata name) external {
    StrategyLib._checkStrategySpecificNameChanged(controller(), name);
    strategySpecificName = name;
  }

  /// @dev In case of any issue operator can withdraw all from pool.
  function emergencyExit() external {
    // check inside lib call

    _emergencyExitFromPool();
    StrategyLib.sendOnEmergencyExit(controller(), asset, splitter);
  }

  /// @dev Manual claim rewards.
  function claim() external {
    StrategyLib._checkManualClaim(controller());
    _claim();
  }

  // *************************************************************
  //                    DEPOSIT/WITHDRAW
  // *************************************************************

  /// @notice Stakes everything the strategy holds into the reward pool.
  /// amount_ Amount transferred to the strategy balance just before calling this function
  /// @param updateTotalAssetsBeforeInvest_ Recalculate total assets amount before depositing.
  ///                                       It can be false if we know exactly, that the amount is already actual.
  /// @return strategyLoss Loss should be covered from Insurance
  function investAll(
    uint /*amount_*/,
    bool updateTotalAssetsBeforeInvest_
  ) external override returns (
    uint strategyLoss
  ) {
    uint balance = StrategyLib._checkInvestAll(splitter, asset);

    if (balance > 0) {
      strategyLoss = _depositToPool(balance, updateTotalAssetsBeforeInvest_);
    }

    return strategyLoss;
  }

  /// @dev Withdraws all underlying assets to the vault
  /// @return strategyLoss Loss should be covered from Insurance
  function withdrawAllToSplitter() external override returns (uint strategyLoss) {
    address _splitter = splitter;
    address _asset = asset;

    uint balance = StrategyLib._checkSplitterSenderAndGetBalance(_splitter, _asset);

    (uint expectedWithdrewUSD, uint assetPrice, uint _strategyLoss) = _withdrawAllFromPool();

    StrategyLib._withdrawAllToSplitterPostActions(
      _asset,
      balance,
      expectedWithdrewUSD,
      assetPrice,
      _splitter
    );
    return _strategyLoss;
  }

  /// @dev Withdraws some assets to the splitter
  /// @return strategyLoss Loss should be covered from Insurance
  function withdrawToSplitter(uint amount) external override returns (uint strategyLoss) {
    address _splitter = splitter;
    address _asset = asset;

    uint balance = StrategyLib._checkSplitterSenderAndGetBalance(_splitter, _asset);

    if (amount > balance) {
      uint expectedWithdrewUSD;
      uint assetPrice;

      (expectedWithdrewUSD, assetPrice, strategyLoss) = _withdrawFromPool(amount - balance);
      balance = StrategyLib.checkWithdrawImpact(
        _asset,
        balance,
        expectedWithdrewUSD,
        assetPrice,
        _splitter
      );
    }

    StrategyLib._withdrawToSplitterPostActions(
      amount,
      balance,
      _asset,
      _splitter
    );
    return strategyLoss;
  }

  // *************************************************************
  //                       VIRTUAL
  // These functions must be implemented in the strategy contract
  // *************************************************************

  /// @dev Amount of underlying assets invested to the pool.
  function investedAssets() public view virtual returns (uint);

  /// @notice Deposit given amount to the pool.
  /// @param updateTotalAssetsBeforeInvest_ Recalculate total assets amount before depositing.
  ///                                       It can be false if we know exactly, that the amount is already actual.
  /// @return strategyLoss Loss should be covered from Insurance
  function _depositToPool(
    uint amount,
    bool updateTotalAssetsBeforeInvest_
  ) internal virtual returns (
    uint strategyLoss
  );

  /// @dev Withdraw given amount from the pool.
  /// @return expectedWithdrewUSD Sum of USD value of each asset in the pool that was withdrawn, decimals of {asset}.
  /// @return assetPrice Price of the strategy {asset}.
  /// @return strategyLoss Loss should be covered from Insurance
  function _withdrawFromPool(uint amount) internal virtual returns (
    uint expectedWithdrewUSD,
    uint assetPrice,
    uint strategyLoss
  );

  /// @dev Withdraw all from the pool.
  /// @return expectedWithdrewUSD Sum of USD value of each asset in the pool that was withdrawn, decimals of {asset}.
  /// @return assetPrice Price of the strategy {asset}.
  /// @return strategyLoss Loss should be covered from Insurance
  function _withdrawAllFromPool() internal virtual returns (
    uint expectedWithdrewUSD,
    uint assetPrice,
    uint strategyLoss
  );

  /// @dev If pool support emergency withdraw need to call it for emergencyExit()
  ///      Withdraw assets without impact checking.
  function _emergencyExitFromPool() internal virtual;

  /// @dev Claim all possible rewards.
  function _claim() internal virtual returns (address[] memory rewardTokens, uint[] memory amounts);

  /// @dev This empty reserved space is put in place to allow future versions to add new
  ///      variables without shifting down storage in the inheritance chain.
  ///      See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
  uint[43] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../openzeppelin/SafeERC20.sol";
import "../openzeppelin/Math.sol";
import "../interfaces/IController.sol";
import "../interfaces/ITetuVaultV2.sol";
import "../interfaces/ISplitter.sol";

library StrategyLib {
  using SafeERC20 for IERC20;

  // *************************************************************
  //                        CONSTANTS
  // *************************************************************

  /// @dev Denominator for fee calculation.
  uint internal constant FEE_DENOMINATOR = 100_000;

  // *************************************************************
  //                        EVENTS
  // *************************************************************

  event CompoundRatioChanged(uint oldValue, uint newValue);
  event StrategySpecificNameChanged(string name);
  event EmergencyExit(address sender, uint amount);
  event ManualClaim(address sender);
  event InvestAll(uint balance);
  event WithdrawAllToSplitter(uint amount);
  event WithdrawToSplitter(uint amount, uint sent, uint balance);

  // *************************************************************
  //                        ERRORS
  // *************************************************************

  string internal constant DENIED = "SB: Denied";
  string internal constant TOO_HIGH = "SB: Too high";
  string internal constant WRONG_VALUE = "SB: Wrong value";
  /// @dev Denominator for compound ratio
  uint internal constant COMPOUND_DENOMINATOR = 100_000;

  // *************************************************************
  //                        CHECKS AND EMITS
  // *************************************************************

  function _checkCompoundRatioChanged(address controller, uint oldValue, uint newValue) external {
    onlyPlatformVoter(controller);
    require(newValue <= COMPOUND_DENOMINATOR, TOO_HIGH);
    emit CompoundRatioChanged(oldValue, newValue);
  }

  function _checkStrategySpecificNameChanged(address controller, string calldata newName) external {
    onlyOperators(controller);
    emit StrategySpecificNameChanged(newName);
  }

  function _checkManualClaim(address controller) external {
    onlyOperators(controller);
    emit ManualClaim(msg.sender);
  }

  function _checkInvestAll(address splitter, address asset) external returns (uint assetBalance) {
    onlySplitter(splitter);
    assetBalance = IERC20(asset).balanceOf(address(this));
    emit InvestAll(assetBalance);
  }

  // *************************************************************
  //                     RESTRICTIONS
  // *************************************************************

  /// @dev Restrict access only for operators
  function onlyOperators(address controller) public view {
    require(IController(controller).isOperator(msg.sender), DENIED);
  }

  /// @dev Restrict access only for governance
  function onlyGovernance(address controller) public view {
    require(IController(controller).governance() == msg.sender, DENIED);
  }

  /// @dev Restrict access only for platform voter
  function onlyPlatformVoter(address controller) public view {
    require(IController(controller).platformVoter() == msg.sender, DENIED);
  }

  /// @dev Restrict access only for splitter
  function onlySplitter(address splitter) public view {
    require(splitter == msg.sender, DENIED);
  }

  function _checkSetupPerformanceFee(address controller, uint fee_, address receiver_) external view {
    onlyGovernance(controller);
    require(fee_ <= 100_000, TOO_HIGH);
    require(receiver_ != address(0), WRONG_VALUE);
  }

  // *************************************************************
  //                       HELPERS
  // *************************************************************

  /// @notice Calculate withdrawn amount in USD using the {assetPrice}.
  ///         Revert if the amount is different from expected too much (high price impact)
  /// @param balanceBefore Asset balance of the strategy before withdrawing
  /// @param expectedWithdrewUSD Expected amount in USD, decimals are same to {_asset}
  /// @param assetPrice Price of the asset, decimals 18
  /// @return balance Current asset balance of the strategy
  function checkWithdrawImpact(
    address _asset,
    uint balanceBefore,
    uint expectedWithdrewUSD,
    uint assetPrice,
    address _splitter
  ) public view returns (uint balance) {
    balance = IERC20(_asset).balanceOf(address(this));
    if (assetPrice != 0 && expectedWithdrewUSD != 0) {

      uint withdrew = balance > balanceBefore ? balance - balanceBefore : 0;
      uint withdrewUSD = withdrew * assetPrice / 1e18;
      uint priceChangeTolerance = ITetuVaultV2(ISplitter(_splitter).vault()).withdrawFee();
      uint difference = expectedWithdrewUSD > withdrewUSD ? expectedWithdrewUSD - withdrewUSD : 0;
      require(difference * FEE_DENOMINATOR / expectedWithdrewUSD <= priceChangeTolerance, TOO_HIGH);
    }
  }

  function sendOnEmergencyExit(address controller, address asset, address splitter) external {
    onlyOperators(controller);

    uint balance = IERC20(asset).balanceOf(address(this));
    IERC20(asset).safeTransfer(splitter, balance);
    emit EmergencyExit(msg.sender, balance);
  }

  function _checkSplitterSenderAndGetBalance(address splitter, address asset) external view returns (uint balance) {
    onlySplitter(splitter);
    return IERC20(asset).balanceOf(address(this));
  }

  function _withdrawAllToSplitterPostActions(
    address _asset,
    uint balanceBefore,
    uint expectedWithdrewUSD,
    uint assetPrice,
    address _splitter
  ) external {
    uint balance = checkWithdrawImpact(
      _asset,
      balanceBefore,
      expectedWithdrewUSD,
      assetPrice,
      _splitter
    );

    if (balance != 0) {
      IERC20(_asset).safeTransfer(_splitter, balance);
    }
    emit WithdrawAllToSplitter(balance);
  }

  function _withdrawToSplitterPostActions(
    uint amount,
    uint balance,
    address _asset,
    address _splitter
  ) external {
    uint amountAdjusted = Math.min(amount, balance);
    if (amountAdjusted != 0) {
      IERC20(_asset).safeTransfer(_splitter, amountAdjusted);
    }
    emit WithdrawToSplitter(amount, amountAdjusted, balance);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../openzeppelin/ERC165.sol";
import "../interfaces/IERC20.sol";
import "../lib/InterfaceIds.sol";

/// @dev Tetu Implementation of the {IERC165} interface extended with helper functions.
/// @author bogdoslav
abstract contract TetuERC165 is ERC165 {

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == InterfaceIds.I_TETU_ERC165 || super.supportsInterface(interfaceId);
  }

  // *************************************************************
  //                        HELPER FUNCTIONS
  // *************************************************************
  /// @author bogdoslav

  /// @dev Checks what interface with id is supported by contract.
  /// @return bool. Do not throws
  function _isInterfaceSupported(address contractAddress, bytes4 interfaceId) internal view returns (bool) {
    require(contractAddress != address(0), "Zero address");
    // check what address is contract
    uint codeSize;
    assembly {
      codeSize := extcodesize(contractAddress)
    }
    if (codeSize == 0) return false;

    try IERC165(contractAddress).supportsInterface(interfaceId) returns (bool isSupported) {
      return isSupported;
    } catch {
    }
    return false;
  }

  /// @dev Checks what interface with id is supported by contract and reverts otherwise
  function _requireInterface(address contractAddress, bytes4 interfaceId) internal view {
    require(_isInterfaceSupported(contractAddress, interfaceId), "Interface is not supported");
  }

  /// @dev Checks what address is ERC20.
  /// @return bool. Do not throws
  function _isERC20(address contractAddress) internal view returns (bool) {
    require(contractAddress != address(0), "Zero address");
    // check what address is contract
    uint codeSize;
    assembly {
      codeSize := extcodesize(contractAddress)
    }
    if (codeSize == 0) return false;

    bool totalSupplySupported;
    try IERC20(contractAddress).totalSupply() returns (uint) {
      totalSupplySupported = true;
    } catch {
    }

    bool balanceSupported;
    try IERC20(contractAddress).balanceOf(address(this)) returns (uint) {
      balanceSupported = true;
    } catch {
    }

    return totalSupplySupported && balanceSupported;
  }


  /// @dev Checks what interface with id is supported by contract and reverts otherwise
  function _requireERC20(address contractAddress) internal view {
    require(_isERC20(contractAddress), "Not ERC20");
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @notice Keep and provide addresses of all application contracts
interface IConverterController {
  function governance() external view returns (address);

  // ********************* Health factor explanation  ****************
  // For example, a landing platform has: liquidity threshold = 0.85, LTV=0.8, LTV / LT = 1.0625
  // For collateral $100 we can borrow $80. A liquidation happens if the cost of collateral will reduce below $85.
  // We set min-health-factor = 1.1, target-health-factor = 1.3
  // For collateral 100 we will borrow 100/1.3 = 76.92
  //
  // Collateral value   100        77            assume that collateral value is decreased at 100/77=1.3 times
  // Collateral * LT    85         65.45
  // Borrow value       65.38      65.38         but borrow value is the same as before
  // Health factor      1.3        1.001         liquidation almost happens here (!)
  //
  /// So, if we have target factor 1.3, it means, that if collateral amount will decreases at 1.3 times
  // and the borrow value won't change at the same time, the liquidation happens at that point.
  // Min health factor marks the point at which a rebalancing must be made asap.
  // *****************************************************************

  /// @notice min allowed health factor with decimals 2, must be >= 1e2
  function minHealthFactor2() external view returns (uint16);
  function setMinHealthFactor2(uint16 value_) external;

  /// @notice target health factor with decimals 2
  /// @dev If the health factor is below/above min/max threshold, we need to make repay
  ///      or additional borrow and restore the health factor to the given target value
  function targetHealthFactor2() external view returns (uint16);
  function setTargetHealthFactor2(uint16 value_) external;

  /// @notice max allowed health factor with decimals 2
  /// @dev For future versions, currently max health factor is not used
  function maxHealthFactor2() external view returns (uint16);
  /// @dev For future versions, currently max health factor is not used
  function setMaxHealthFactor2(uint16 value_) external;

  /// @notice get current value of blocks per day. The value is set manually at first and can be auto-updated later
  function blocksPerDay() external view returns (uint);
  /// @notice set value of blocks per day manually and enable/disable auto update of this value
  function setBlocksPerDay(uint blocksPerDay_, bool enableAutoUpdate_) external;
  /// @notice Check if it's time to call updateBlocksPerDay()
  /// @param periodInSeconds_ Period of auto-update in seconds
  function isBlocksPerDayAutoUpdateRequired(uint periodInSeconds_) external view returns (bool);
  /// @notice Recalculate blocksPerDay value
  /// @param periodInSeconds_ Period of auto-update in seconds
  function updateBlocksPerDay(uint periodInSeconds_) external;

  /// @notice 0 - new borrows are allowed, 1 - any new borrows are forbidden
  function paused() external view returns (bool);

  /// @notice the given user is whitelisted and is allowed to make borrow/swap using TetuConverter
  function isWhitelisted(address user_) external view returns (bool);

  /// @notice The size of the gap by which the debt should be increased upon repayment
  ///         Such gaps are required by AAVE pool adapters to workaround dust tokens problem
  ///         and be able to make full repayment.
  /// @dev Debt gap is applied as following: toPay = debt * (DEBT_GAP_DENOMINATOR + debtGap) / DEBT_GAP_DENOMINATOR
  function debtGap() external view returns (uint);

  //-----------------------------------------------------
  //        Core application contracts
  //-----------------------------------------------------

  function tetuConverter() external view returns (address);
  function borrowManager() external view returns (address);
  function debtMonitor() external view returns (address);
  function tetuLiquidator() external view returns (address);
  function swapManager() external view returns (address);
  function priceOracle() external view returns (address);

  //-----------------------------------------------------
  //        External contracts
  //-----------------------------------------------------
  /// @notice A keeper to control health and efficiency of the borrows
  function keeper() external view returns (address);
  /// @notice Controller of tetu-contracts-v2, that is allowed to update proxy contracts
  function proxyUpdater() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IConverterControllerProvider {
  function controller() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IPriceOracle {
  /// @notice Return asset price in USD, decimals 18
  function getAssetPrice(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IConverterControllerProvider.sol";

/// @notice Main contract of the TetuConverter application
/// @dev Borrower (strategy) makes all operations via this contract only.
interface ITetuConverter is IConverterControllerProvider {

  /// @notice Find possible borrow strategies and provide "cost of money" as interest for the period for each strategy
  ///         Result arrays of the strategy are ordered in ascending order of APR.
  /// @param entryData_ Encoded entry kind and additional params if necessary (set of params depends on the kind)
  ///                   See EntryKinds.sol\ENTRY_KIND_XXX constants for possible entry kinds
  ///                   0 is used by default
  /// @param amountIn_  The meaning depends on entryData
  ///                   For entryKind=0 it's max available amount of collateral
  /// @param periodInBlocks_ Estimated period to keep target amount. It's required to compute APR
  /// @return converters Array of available converters ordered in ascending order of APR.
  ///                    Each item contains a result contract that should be used for conversion; it supports IConverter
  ///                    This address should be passed to borrow-function during conversion.
  ///                    The length of array is always equal to the count of available lending platforms.
  ///                    Last items in array can contain zero addresses (it means they are not used)
  /// @return collateralAmountsOut Amounts that should be provided as a collateral
  /// @return amountToBorrowsOut Amounts that should be borrowed
  ///                            This amount is not zero if corresponded converter is not zero.
  /// @return aprs18 Interests on the use of {amountIn_} during the given period, decimals 18
  function findBorrowStrategies(
    bytes memory entryData_,
    address sourceToken_,
    uint amountIn_,
    address targetToken_,
    uint periodInBlocks_
  ) external view returns (
    address[] memory converters,
    uint[] memory collateralAmountsOut,
    uint[] memory amountToBorrowsOut,
    int[] memory aprs18
  );

  /// @notice Find best swap strategy and provide "cost of money" as interest for the period
  /// @dev This is writable function with read-only behavior.
  ///      It should be writable to be able to simulate real swap and get a real APR.
  /// @param entryData_ Encoded entry kind and additional params if necessary (set of params depends on the kind)
  ///                   See EntryKinds.sol\ENTRY_KIND_XXX constants for possible entry kinds
  ///                   0 is used by default
  /// @param amountIn_  The meaning depends on entryData
  ///                   For entryKind=0 it's max available amount of collateral
  ///                   This amount must be approved to TetuConverter before the call.
  ///                   For entryKind=2 we don't know amount of collateral before the call,
  ///                   so it's necessary to approve large enough amount (or make infinity approve)
  /// @return converter Result contract that should be used for conversion to be passed to borrow()
  /// @return sourceAmountOut Amount of {sourceToken_} that should be swapped to get {targetToken_}
  ///                         It can be different from the {sourceAmount_} for some entry kinds.
  /// @return targetAmountOut Result amount of {targetToken_} after swap
  /// @return apr18 Interest on the use of {outMaxTargetAmount} during the given period, decimals 18
  function findSwapStrategy(
    bytes memory entryData_,
    address sourceToken_,
    uint amountIn_,
    address targetToken_
  ) external returns (
    address converter,
    uint sourceAmountOut,
    uint targetAmountOut,
    int apr18
  );

  /// @notice Find best conversion strategy (swap or borrow) and provide "cost of money" as interest for the period.
  ///         It calls both findBorrowStrategy and findSwapStrategy and selects a best strategy.
  /// @dev This is writable function with read-only behavior.
  ///      It should be writable to be able to simulate real swap and get a real APR for swapping.
  /// @param entryData_ Encoded entry kind and additional params if necessary (set of params depends on the kind)
  ///                   See EntryKinds.sol\ENTRY_KIND_XXX constants for possible entry kinds
  ///                   0 is used by default
  /// @param amountIn_  The meaning depends on entryData
  ///                   For entryKind=0 it's max available amount of collateral
  ///                   This amount must be approved to TetuConverter before the call.
  ///                   For entryKind=2 we don't know amount of collateral before the call,
  ///                   so it's necessary to approve large enough amount (or make infinity approve)
  /// @param periodInBlocks_ Estimated period to keep target amount. It's required to compute APR
  /// @return converter Result contract that should be used for conversion to be passed to borrow().
  /// @return collateralAmountOut Amount of {sourceToken_} that should be swapped to get {targetToken_}
  ///                             It can be different from the {sourceAmount_} for some entry kinds.
  /// @return amountToBorrowOut Result amount of {targetToken_} after conversion
  /// @return apr18 Interest on the use of {outMaxTargetAmount} during the given period, decimals 18
  function findConversionStrategy(
    bytes memory entryData_,
    address sourceToken_,
    uint amountIn_,
    address targetToken_,
    uint periodInBlocks_
  ) external returns (
    address converter,
    uint collateralAmountOut,
    uint amountToBorrowOut,
    int apr18
  );

  /// @notice Convert {collateralAmount_} to {amountToBorrow_} using {converter_}
  ///         Target amount will be transferred to {receiver_}. No re-balancing here.
  /// @dev Transferring of {collateralAmount_} by TetuConverter-contract must be approved by the caller before the call
  ///      Only whitelisted users are allowed to make borrows
  /// @param converter_ A converter received from findBestConversionStrategy.
  /// @param collateralAmount_ Amount of {collateralAsset_} to be converted.
  ///                          This amount must be approved to TetuConverter before the call.
  /// @param amountToBorrow_ Amount of {borrowAsset_} to be borrowed and sent to {receiver_}
  /// @param receiver_ A receiver of borrowed amount
  /// @return borrowedAmountOut Exact borrowed amount transferred to {receiver_}
  function borrow(
    address converter_,
    address collateralAsset_,
    uint collateralAmount_,
    address borrowAsset_,
    uint amountToBorrow_,
    address receiver_
  ) external returns (
    uint borrowedAmountOut
  );

  /// @notice Full or partial repay of the borrow
  /// @dev A user should transfer {amountToRepay_} to TetuConverter before calling repay()
  /// @param amountToRepay_ Amount of borrowed asset to repay.
  ///        You can know exact total amount of debt using {getStatusCurrent}.
  ///        if the amount exceed total amount of the debt:
  ///           - the debt will be fully repaid
  ///           - remain amount will be swapped from {borrowAsset_} to {collateralAsset_}
  ///        This amount should be calculated with taking into account possible debt gap,
  ///        You should call getDebtAmountCurrent(debtGap = true) to get this amount.
  /// @param receiver_ A receiver of the collateral that will be withdrawn after the repay
  ///                  The remained amount of borrow asset will be returned to the {receiver_} too
  /// @return collateralAmountOut Exact collateral amount transferred to {collateralReceiver_}
  ///         If TetuConverter is not able to make the swap, it reverts
  /// @return returnedBorrowAmountOut A part of amount-to-repay that wasn't converted to collateral asset
  ///                                 because of any reasons (i.e. there is no available conversion strategy)
  ///                                 This amount is returned back to the collateralReceiver_
  /// @return swappedLeftoverCollateralOut A part of collateral received through the swapping
  /// @return swappedLeftoverBorrowOut A part of amountToRepay_ that was swapped
  function repay(
    address collateralAsset_,
    address borrowAsset_,
    uint amountToRepay_,
    address receiver_
  ) external returns (
    uint collateralAmountOut,
    uint returnedBorrowAmountOut,
    uint swappedLeftoverCollateralOut,
    uint swappedLeftoverBorrowOut
  );

  /// @notice Estimate result amount after making full or partial repay
  /// @dev It works in exactly same way as repay() but don't make actual repay
  ///      Anyway, the function is write, not read-only, because it makes updateStatus()
  /// @param user_ user whose amount-to-repay will be calculated
  /// @param amountToRepay_ Amount of borrowed asset to repay.
  ///        This amount should be calculated without possible debt gap.
  ///        In this way it's differ from {repay}
  /// @return collateralAmountOut Total collateral amount to be returned after repay in exchange of {amountToRepay_}
  /// @return swappedAmountOut A part of {collateralAmountOut} that were received by direct swap
  function quoteRepay(
    address user_,
    address collateralAsset_,
    address borrowAsset_,
    uint amountToRepay_
  ) external returns (
    uint collateralAmountOut,
    uint swappedAmountOut
  );

  /// @notice Update status in all opened positions
  ///         After this call getDebtAmount will be able to return exact amount to repay
  /// @param user_ user whose debts will be returned
  /// @param useDebtGap_ Calculate exact value of the debt (false) or amount to pay (true)
  ///        Exact value of the debt can be a bit different from amount to pay, i.e. AAVE has dust tokens problem.
  ///        Exact amount of debt should be used to calculate shared price, amount to pay - for repayment
  /// @return totalDebtAmountOut Borrowed amount that should be repaid to pay off the loan in full
  /// @return totalCollateralAmountOut Amount of collateral that should be received after paying off the loan
  function getDebtAmountCurrent(
    address user_,
    address collateralAsset_,
    address borrowAsset_,
    bool useDebtGap_
  ) external returns (
    uint totalDebtAmountOut,
    uint totalCollateralAmountOut
  );

  /// @notice Total amount of borrow tokens that should be repaid to close the borrow completely.
  /// @param user_ user whose debts will be returned
  /// @param useDebtGap_ Calculate exact value of the debt (false) or amount to pay (true)
  ///        Exact value of the debt can be a bit different from amount to pay, i.e. AAVE has dust tokens problem.
  ///        Exact amount of debt should be used to calculate shared price, amount to pay - for repayment
  /// @return totalDebtAmountOut Borrowed amount that should be repaid to pay off the loan in full
  /// @return totalCollateralAmountOut Amount of collateral that should be received after paying off the loan
  function getDebtAmountStored(
    address user_,
    address collateralAsset_,
    address borrowAsset_,
    bool useDebtGap_
  ) external view returns (
    uint totalDebtAmountOut,
    uint totalCollateralAmountOut
  );

  /// @notice User needs to redeem some collateral amount. Calculate an amount of borrow token that should be repaid
  /// @param user_ user whose debts will be returned
  /// @param collateralAmountRequired_ Amount of collateral required by the user
  /// @return borrowAssetAmount Borrowed amount that should be repaid to receive back following amount of collateral:
  ///                           amountToReceive = collateralAmountRequired_ - unobtainableCollateralAssetAmount
  /// @return unobtainableCollateralAssetAmount A part of collateral that cannot be obtained in any case
  ///                                           even if all borrowed amount will be returned.
  ///                                           If this amount is not 0, you ask to get too much collateral.
  function estimateRepay(
    address user_,
    address collateralAsset_,
    uint collateralAmountRequired_,
    address borrowAsset_
  ) external view returns (
    uint borrowAssetAmount,
    uint unobtainableCollateralAssetAmount
  );

  /// @notice Transfer all reward tokens to {receiver_}
  /// @return rewardTokensOut What tokens were transferred. Same reward token can appear in the array several times
  /// @return amountsOut Amounts of transferred rewards, the array is synced with {rewardTokens}
  function claimRewards(address receiver_) external returns (
    address[] memory rewardTokensOut,
    uint[] memory amountsOut
  );

  /// @notice Swap {amountIn_} of {assetIn_} to {assetOut_} and send result amount to {receiver_}
  ///         The swapping is made using TetuLiquidator with checking price impact using embedded price oracle.
  /// @param amountIn_ Amount of {assetIn_} to be swapped.
  ///                      It should be transferred on balance of the TetuConverter before the function call
  /// @param receiver_ Result amount will be sent to this address
  /// @param priceImpactToleranceSource_ Price impact tolerance for liquidate-call, decimals = 100_000
  /// @param priceImpactToleranceTarget_ Price impact tolerance for price-oracle-check, decimals = 100_000
  /// @return amountOut The amount of {assetOut_} that has been sent to the receiver
  function safeLiquidate(
    address assetIn_,
    uint amountIn_,
    address assetOut_,
    address receiver_,
    uint priceImpactToleranceSource_,
    uint priceImpactToleranceTarget_
  ) external returns (
    uint amountOut
  );

  /// @notice Check if {amountOut_} is too different from the value calculated directly using price oracle prices
  /// @return Price difference is ok for the given {priceImpactTolerance_}
  function isConversionValid(
    address assetIn_,
    uint amountIn_,
    address assetOut_,
    uint amountOut_,
    uint priceImpactTolerance_
  ) external view returns (bool);

  /// @notice Close given borrow and return collateral back to the user, governance only
  /// @dev The pool adapter asks required amount-to-repay from the user internally
  /// @param poolAdapter_ The pool adapter that represents the borrow
  /// @param closePosition Close position after repay
  ///        Usually it should be true, because the function always tries to repay all debt
  ///        false can be used if user doesn't have enough amount to pay full debt
  ///              and we are trying to pay "as much as possible"
  /// @return collateralAmountOut Amount of collateral returned to the user
  /// @return repaidAmountOut Amount of borrow asset paid to the lending platform
  function repayTheBorrow(address poolAdapter_, bool closePosition) external returns (
    uint collateralAmountOut,
    uint repaidAmountOut
  );

  /// @notice Get active borrows of the user with given collateral/borrowToken
  /// @dev Simple access to IDebtMonitor.getPositions
  /// @return poolAdaptersOut The instances of IPoolAdapter
  function getPositions(address user_, address collateralToken_, address borrowedToken_) external view returns (
    address[] memory poolAdaptersOut
  );

  /// @notice Save token from TC-balance to {receiver}
  /// @dev Normally TetuConverter doesn't have any tokens on balance, they can appear there accidentally only
  function salvage(address receiver, address token, uint amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice TetuConverter sends callback notifications to its user via this interface
interface ITetuConverterCallback {
  /// @notice Converters calls this function if user should return some amount back.
  ///         f.e. when the health factor is unhealthy and the converter needs more tokens to fix it.
  ///         or when the full repay is required and converter needs to get full amount-to-repay.
  /// @param asset_ Required asset (either collateral or borrow)
  /// @param amount_ Required amount of the {asset_}
  /// @return amountOut Exact amount that borrower has sent to balance of TetuConverter
  function requirePayAmountBack(address asset_, uint amount_) external returns (uint amountOut);

  /// @notice TetuConverter calls this function when it sends any amount to user's balance
  /// @param assets_ Any asset sent to the balance, i.e. inside repayTheBorrow
  /// @param amounts_ Amount of {asset_} that has been sent to the user's balance
  function onTransferAmounts(address[] memory assets_, uint[] memory amounts_) external;
}

// SPDX-License-Identifier: ISC
pragma solidity 0.8.17;

interface IBalancerGauge {
  function decimals() external view returns (uint256);

  function version() external view returns (string memory);

  function last_claim() external view returns (uint256);

  function claimed_reward(address _addr, address _token) external view returns (uint256);

  function claimable_reward(address _addr, address _token) external view returns (uint256);

  function claimable_reward_write(address _addr, address _token) external returns (uint256);

  function reward_contract() external view returns (address);

  function reward_data(address _token) external view returns (
    address token,
    address distributor,
    uint256 period_finish,
    uint256 rate,
    uint256 last_update,
    uint256 integral
  );

  function reward_tokens(uint256 arg0) external view returns (address);

  function reward_balances(address arg0) external view returns (uint256);

  function rewards_receiver(address arg0) external view returns (address);

  function reward_integral(address arg0) external view returns (uint256);

  function reward_integral_for(address arg0, address arg1) external view returns (uint256);

  function set_rewards_receiver(address _receiver) external;

  function set_rewards(
    address _reward_contract,
    bytes32 _claim_sig,
    address[8] memory _reward_tokens
  ) external;

  function claim_rewards() external;

  function claim_rewards(address _addr) external;

  function claim_rewards(address _addr, address _receiver) external;

  function deposit(uint256 _value) external;

  function deposit(uint256 _value, address _addr) external;

  function deposit(uint256 _value, address _addr, bool _claim_rewards) external;

  function withdraw(uint256 _value) external;

  function withdraw(uint256 _value, bool _claim_rewards) external;

  function transfer(address _to, uint256 _value) external returns (bool);

  function transferFrom(address _from, address _to, uint256 _value) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address _spender, uint256 _value) external returns (bool);

  function permit(
    address _owner,
    address _spender,
    uint256 _value,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external returns (bool);

  function increaseAllowance(address _spender, uint256 _added_value) external returns (bool);

  function decreaseAllowance(address _spender, uint256 _subtracted_value) external returns (bool);

  function initialize(
    address _lp_token,
    address _reward_contract,
    bytes32 _claim_sig
  ) external;

  function lp_token() external view returns (address);

  function balanceOf(address arg0) external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function nonces(address arg0) external view returns (uint256);

  function claim_sig() external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IBVault.sol";

interface IBalancerHelper {
  function queryExit(
    bytes32 poolId,
    address sender,
    address recipient,
    IBVault.ExitPoolRequest memory request
  ) external returns (uint256 bptIn, uint256[] memory amountsOut);

  function queryJoin(
    bytes32 poolId,
    address sender,
    address recipient,
    IBVault.JoinPoolRequest memory request
  ) external returns (uint256 bptOut, uint256[] memory amountsIn);

  function vault() external view returns (address);
}

// SPDX-License-Identifier: ISC
pragma solidity 0.8.17;

import "@tetu_io/tetu-contracts-v2/contracts/interfaces/IERC20.sol";

interface IAsset {
}

interface IBVault {
  // Internal Balance
  //
  // Users can deposit tokens into the Vault, where they are allocated to their Internal Balance, and later
  // transferred or withdrawn. It can also be used as a source of tokens when joining Pools, as a destination
  // when exiting them, and as either when performing swaps. This usage of Internal Balance results in greatly reduced
  // gas costs when compared to relying on plain ERC20 transfers, leading to large savings for frequent users.
  //
  // Internal Balance management features batching, which means a single contract call can be used to perform multiple
  // operations of different kinds, with different senders and recipients, at once.

  /**
   * @dev Returns `user`'s Internal Balance for a set of tokens.
     */
  function getInternalBalance(address user, IERC20[] calldata tokens) external view returns (uint256[] memory);

  /**
   * @dev Performs a set of user balance operations, which involve Internal Balance (deposit, withdraw or transfer)
     * and plain ERC20 transfers using the Vault's allowance. This last feature is particularly useful for relayers, as
     * it lets integrators reuse a user's Vault allowance.
     *
     * For each operation, if the caller is not `sender`, it must be an authorized relayer for them.
     */
  function manageUserBalance(UserBalanceOp[] calldata ops) external payable;

  /**
   * @dev Data for `manageUserBalance` operations, which include the possibility for ETH to be sent and received
     without manual WETH wrapping or unwrapping.
     */
  struct UserBalanceOp {
    UserBalanceOpKind kind;
    IAsset asset;
    uint256 amount;
    address sender;
    address payable recipient;
  }

  // There are four possible operations in `manageUserBalance`:
  //
  // - DEPOSIT_INTERNAL
  // Increases the Internal Balance of the `recipient` account by transferring tokens from the corresponding
  // `sender`. The sender must have allowed the Vault to use their tokens via `IERC20.approve()`.
  //
  // ETH can be used by passing the ETH sentinel value as the asset and forwarding ETH in the call: it will be wrapped
  // and deposited as WETH. Any ETH amount remaining will be sent back to the caller (not the sender, which is
  // relevant for relayers).
  //
  // Emits an `InternalBalanceChanged` event.
  //
  //
  // - WITHDRAW_INTERNAL
  // Decreases the Internal Balance of the `sender` account by transferring tokens to the `recipient`.
  //
  // ETH can be used by passing the ETH sentinel value as the asset. This will deduct WETH instead, unwrap it and send
  // it to the recipient as ETH.
  //
  // Emits an `InternalBalanceChanged` event.
  //
  //
  // - TRANSFER_INTERNAL
  // Transfers tokens from the Internal Balance of the `sender` account to the Internal Balance of `recipient`.
  //
  // Reverts if the ETH sentinel value is passed.
  //
  // Emits an `InternalBalanceChanged` event.
  //
  //
  // - TRANSFER_EXTERNAL
  // Transfers tokens from `sender` to `recipient`, using the Vault's ERC20 allowance. This is typically used by
  // relayers, as it lets them reuse a user's Vault allowance.
  //
  // Reverts if the ETH sentinel value is passed.
  //
  // Emits an `ExternalBalanceTransfer` event.

  enum UserBalanceOpKind {DEPOSIT_INTERNAL, WITHDRAW_INTERNAL, TRANSFER_INTERNAL, TRANSFER_EXTERNAL}

  /**
   * @dev Emitted when a user's Internal Balance changes, either from calls to `manageUserBalance`, or through
     * interacting with Pools using Internal Balance.
     *
     * Because Internal Balance works exclusively with ERC20 tokens, ETH deposits and withdrawals will use the WETH
     * address.
     */
  event InternalBalanceChanged(address indexed user, IERC20 indexed token, int256 delta);

  /**
   * @dev Emitted when a user's Vault ERC20 allowance is used by the Vault to transfer tokens to an external account.
     */
  event ExternalBalanceTransfer(IERC20 indexed token, address indexed sender, address recipient, uint256 amount);

  // Pools
  //
  // There are three specialization settings for Pools, which allow for cheaper swaps at the cost of reduced
  // functionality:
  //
  //  - General: no specialization, suited for all Pools. IGeneralPool is used for swap request callbacks, passing the
  // balance of all tokens in the Pool. These Pools have the largest swap costs (because of the extra storage reads),
  // which increase with the number of registered tokens.
  //
  //  - Minimal Swap Info: IMinimalSwapInfoPool is used instead of IGeneralPool, which saves gas by only passing the
  // balance of the two tokens involved in the swap. This is suitable for some pricing algorithms, like the weighted
  // constant product one popularized by Balancer V1. Swap costs are smaller compared to general Pools, and are
  // independent of the number of registered tokens.
  //
  //  - Two Token: only allows two tokens to be registered. This achieves the lowest possible swap gas cost. Like
  // minimal swap info Pools, these are called via IMinimalSwapInfoPool.

  enum PoolSpecialization {GENERAL, MINIMAL_SWAP_INFO, TWO_TOKEN}

  /**
   * @dev Registers the caller account as a Pool with a given specialization setting. Returns the Pool's ID, which
     * is used in all Pool-related functions. Pools cannot be deregistered, nor can the Pool's specialization be
     * changed.
     *
     * The caller is expected to be a smart contract that implements either `IGeneralPool` or `IMinimalSwapInfoPool`,
     * depending on the chosen specialization setting. This contract is known as the Pool's contract.
     *
     * Note that the same contract may register itself as multiple Pools with unique Pool IDs, or in other words,
     * multiple Pools may share the same contract.
     *
     * Emits a `PoolRegistered` event.
     */
  function registerPool(PoolSpecialization specialization) external returns (bytes32);

  /**
   * @dev Emitted when a Pool is registered by calling `registerPool`.
     */
  event PoolRegistered(bytes32 indexed poolId, address indexed poolAddress, PoolSpecialization specialization);

  /**
   * @dev Returns a Pool's contract address and specialization setting.
     */
  function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);

  /**
   * @dev Registers `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
     *
     * Pools can only interact with tokens they have registered. Users join a Pool by transferring registered tokens,
     * exit by receiving registered tokens, and can only swap registered tokens.
     *
     * Each token can only be registered once. For Pools with the Two Token specialization, `tokens` must have a length
     * of two, that is, both tokens must be registered in the same `registerTokens` call, and they must be sorted in
     * ascending order.
     *
     * The `tokens` and `assetManagers` arrays must have the same length, and each entry in these indicates the Asset
     * Manager for the corresponding token. Asset Managers can manage a Pool's tokens via `managePoolBalance`,
     * depositing and withdrawing them directly, and can even set their balance to arbitrary amounts. They are therefore
     * expected to be highly secured smart contracts with sound design principles, and the decision to register an
     * Asset Manager should not be made lightly.
     *
     * Pools can choose not to assign an Asset Manager to a given token by passing in the zero address. Once an Asset
     * Manager is set, it cannot be changed except by deregistering the associated token and registering again with a
     * different Asset Manager.
     *
     * Emits a `TokensRegistered` event.
     */
  function registerTokens(
    bytes32 poolId,
    IERC20[] calldata tokens,
    address[] calldata assetManagers
  ) external;

  /**
   * @dev Emitted when a Pool registers tokens by calling `registerTokens`.
     */
  event TokensRegistered(bytes32 indexed poolId, IERC20[] tokens, address[] assetManagers);

  /**
   * @dev Deregisters `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
     *
     * Only registered tokens (via `registerTokens`) can be deregistered. Additionally, they must have zero total
     * balance. For Pools with the Two Token specialization, `tokens` must have a length of two, that is, both tokens
     * must be deregistered in the same `deregisterTokens` call.
     *
     * A deregistered token can be re-registered later on, possibly with a different Asset Manager.
     *
     * Emits a `TokensDeregistered` event.
     */
  function deregisterTokens(bytes32 poolId, IERC20[] calldata tokens) external;

  /**
   * @dev Emitted when a Pool deregisters tokens by calling `deregisterTokens`.
     */
  event TokensDeregistered(bytes32 indexed poolId, IERC20[] tokens);

  /**
   * @dev Returns detailed information for a Pool's registered token.
     *
     * `cash` is the number of tokens the Vault currently holds for the Pool. `managed` is the number of tokens
     * withdrawn and held outside the Vault by the Pool's token Asset Manager. The Pool's total balance for `token`
     * equals the sum of `cash` and `managed`.
     *
     * Internally, `cash` and `managed` are stored using 112 bits. No action can ever cause a Pool's token `cash`,
     * `managed` or `total` balance to be greater than 2^112 - 1.
     *
     * `lastChangeBlock` is the number of the block in which `token`'s total balance was last modified (via either a
     * join, exit, swap, or Asset Manager update). This value is useful to avoid so-called 'sandwich attacks', for
     * example when developing price oracles. A change of zero (e.g. caused by a swap with amount zero) is considered a
     * change for this purpose, and will update `lastChangeBlock`.
     *
     * `assetManager` is the Pool's token Asset Manager.
     */
  function getPoolTokenInfo(bytes32 poolId, IERC20 token)
  external
  view
  returns (
    uint256 cash,
    uint256 managed,
    uint256 lastChangeBlock,
    address assetManager
  );

  /**
   * @dev Returns a Pool's registered tokens, the total balance for each, and the latest block when *any* of
     * the tokens' `balances` changed.
     *
     * The order of the `tokens` array is the same order that will be used in `joinPool`, `exitPool`, as well as in all
     * Pool hooks (where applicable). Calls to `registerTokens` and `deregisterTokens` may change this order.
     *
     * If a Pool only registers tokens once, and these are sorted in ascending order, they will be stored in the same
     * order as passed to `registerTokens`.
     *
     * Total balances include both tokens held by the Vault and those withdrawn by the Pool's Asset Managers. These are
     * the amounts used by joins, exits and swaps. For a detailed breakdown of token balances, use `getPoolTokenInfo`
     * instead.
     */
  function getPoolTokens(bytes32 poolId)
  external
  view
  returns (
    IERC20[] memory tokens,
    uint256[] memory balances,
    uint256 lastChangeBlock
  );

  /**
   * @dev Called by users to join a Pool, which transfers tokens from `sender` into the Pool's balance. This will
     * trigger custom Pool behavior, which will typically grant something in return to `recipient` - often tokenized
     * Pool shares.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `assets` and `maxAmountsIn` arrays must have the same length, and each entry indicates the maximum amount
     * to send for each asset. The amounts to send are decided by the Pool and not the Vault: it just enforces
     * these maximums.
     *
     * If joining a Pool that holds WETH, it is possible to send ETH directly: the Vault will do the wrapping. To enable
     * this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead of the
     * WETH address. Note that it is not possible to combine ETH and WETH in the same join. Any excess ETH will be sent
     * back to the caller (not the sender, which is important for relayers).
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If sending ETH however, the array must be
     * sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the final
     * `assets` array might not be sorted. Pools with no registered tokens cannot be joined.
     *
     * If `fromInternalBalance` is true, the caller's Internal Balance will be preferred: ERC20 transfers will only
     * be made for the difference between the requested amount and Internal Balance (if any). Note that ETH cannot be
     * withdrawn from Internal Balance: attempting to do so will trigger a revert.
     *
     * This causes the Vault to call the `IBasePool.onJoinPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares). This can be encoded in the `userData` argument, which is ignored by the Vault and passed
     * directly to the Pool's contract, as is `recipient`.
     *
     * Emits a `PoolBalanceChanged` event.
     *
     * See https://dev.balancer.fi/resources/joins-and-exits/pool-joins
     */
  function joinPool(
    bytes32 poolId,
    address sender,
    address recipient,
    JoinPoolRequest calldata request
  ) external payable;

  enum JoinKind {INIT, EXACT_TOKENS_IN_FOR_BPT_OUT, TOKEN_IN_FOR_EXACT_BPT_OUT}

  /// @notice WeightedPool ExitKinds
  enum ExitKind {EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, EXACT_BPT_IN_FOR_TOKENS_OUT, BPT_IN_FOR_EXACT_TOKENS_OUT}
  /// @notice Composable Stable V2 ExitKinds
  enum ExitKindComposableStable {EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, BPT_IN_FOR_EXACT_TOKENS_OUT, EXACT_BPT_IN_FOR_ALL_TOKENS_OUT}


  struct JoinPoolRequest {
    IAsset[] assets;
    uint256[] maxAmountsIn;
    bytes userData;
    bool fromInternalBalance;
  }

  /**
   * @dev Called by users to exit a Pool, which transfers tokens from the Pool's balance to `recipient`. This will
     * trigger custom Pool behavior, which will typically ask for something in return from `sender` - often tokenized
     * Pool shares. The amount of tokens that can be withdrawn is limited by the Pool's `cash` balance (see
     * `getPoolTokenInfo`).
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `tokens` and `minAmountsOut` arrays must have the same length, and each entry in these indicates the minimum
     * token amount to receive for each token contract. The amounts to send are decided by the Pool and not the Vault:
     * it just enforces these minimums.
     *
     * If exiting a Pool that holds WETH, it is possible to receive ETH directly: the Vault will do the unwrapping. To
     * enable this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead
     * of the WETH address. Note that it is not possible to combine ETH and WETH in the same exit.
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If receiving ETH however, the array must
     * be sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the
     * final `assets` array might not be sorted. Pools with no registered tokens cannot be exited.
     *
     * If `toInternalBalance` is true, the tokens will be deposited to `recipient`'s Internal Balance. Otherwise,
     * an ERC20 transfer will be performed. Note that ETH cannot be deposited to Internal Balance: attempting to
     * do so will trigger a revert.
     *
     * `minAmountsOut` is the minimum amount of tokens the user expects to get out of the Pool, for each token in the
     * `tokens` array. This array must match the Pool's registered tokens.
     *
     * This causes the Vault to call the `IBasePool.onExitPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares to return). This can be encoded in the `userData` argument, which is ignored by the Vault and
     * passed directly to the Pool's contract.
     *
     * Emits a `PoolBalanceChanged` event.
     */
  function exitPool(
    bytes32 poolId,
    address sender,
    address payable recipient,
    ExitPoolRequest calldata request
  ) external;

  struct ExitPoolRequest {
    IAsset[] assets;
    uint256[] minAmountsOut;
    bytes userData;
    bool toInternalBalance;
  }

  /**
   * @dev Emitted when a user joins or exits a Pool by calling `joinPool` or `exitPool`, respectively.
     */
  event PoolBalanceChanged(
    bytes32 indexed poolId,
    address indexed liquidityProvider,
    IERC20[] tokens,
    int256[] deltas,
    uint256[] protocolFeeAmounts
  );

  enum PoolBalanceChangeKind {JOIN, EXIT}

  // Swaps
  //
  // Users can swap tokens with Pools by calling the `swap` and `batchSwap` functions. To do this,
  // they need not trust Pool contracts in any way: all security checks are made by the Vault. They must however be
  // aware of the Pools' pricing algorithms in order to estimate the prices Pools will quote.
  //
  // The `swap` function executes a single swap, while `batchSwap` can perform multiple swaps in sequence.
  // In each individual swap, tokens of one kind are sent from the sender to the Pool (this is the 'token in'),
  // and tokens of another kind are sent from the Pool to the recipient in exchange (this is the 'token out').
  // More complex swaps, such as one token in to multiple tokens out can be achieved by batching together
  // individual swaps.
  //
  // There are two swap kinds:
  //  - 'given in' swaps, where the amount of tokens in (sent to the Pool) is known, and the Pool determines (via the
  // `onSwap` hook) the amount of tokens out (to send to the recipient).
  //  - 'given out' swaps, where the amount of tokens out (received from the Pool) is known, and the Pool determines
  // (via the `onSwap` hook) the amount of tokens in (to receive from the sender).
  //
  // Additionally, it is possible to chain swaps using a placeholder input amount, which the Vault replaces with
  // the calculated output of the previous swap. If the previous swap was 'given in', this will be the calculated
  // tokenOut amount. If the previous swap was 'given out', it will use the calculated tokenIn amount. These extended
  // swaps are known as 'multihop' swaps, since they 'hop' through a number of intermediate tokens before arriving at
  // the final intended token.
  //
  // In all cases, tokens are only transferred in and out of the Vault (or withdrawn from and deposited into Internal
  // Balance) after all individual swaps have been completed, and the net token balance change computed. This makes
  // certain swap patterns, such as multihops, or swaps that interact with the same token pair in multiple Pools, cost
  // much less gas than they would otherwise.
  //
  // It also means that under certain conditions it is possible to perform arbitrage by swapping with multiple
  // Pools in a way that results in net token movement out of the Vault (profit), with no tokens being sent in (only
  // updating the Pool's internal accounting).
  //
  // To protect users from front-running or the market changing rapidly, they supply a list of 'limits' for each token
  // involved in the swap, where either the maximum number of tokens to send (by passing a positive value) or the
  // minimum amount of tokens to receive (by passing a negative value) is specified.
  //
  // Additionally, a 'deadline' timestamp can also be provided, forcing the swap to fail if it occurs after
  // this point in time (e.g. if the transaction failed to be included in a block promptly).
  //
  // If interacting with Pools that hold WETH, it is possible to both send and receive ETH directly: the Vault will do
  // the wrapping and unwrapping. To enable this mechanism, the IAsset sentinel value (the zero address) must be
  // passed in the `assets` array instead of the WETH address. Note that it is possible to combine ETH and WETH in the
  // same swap. Any excess ETH will be sent back to the caller (not the sender, which is relevant for relayers).
  //
  // Finally, Internal Balance can be used when either sending or receiving tokens.

  enum SwapKind {GIVEN_IN, GIVEN_OUT}

  /**
   * @dev Performs a swap with a single Pool.
     *
     * If the swap is 'given in' (the number of tokens to send to the Pool is known), it returns the amount of tokens
     * taken from the Pool, which must be greater than or equal to `limit`.
     *
     * If the swap is 'given out' (the number of tokens to take from the Pool is known), it returns the amount of tokens
     * sent to the Pool, which must be less than or equal to `limit`.
     *
     * Internal Balance usage and the recipient are determined by the `funds` struct.
     *
     * Emits a `Swap` event.
     */
  function swap(
    SingleSwap calldata singleSwap,
    FundManagement calldata funds,
    uint256 limit,
    uint256 deadline
  ) external payable returns (uint256);

  /**
   * @dev Data for a single swap executed by `swap`. `amount` is either `amountIn` or `amountOut` depending on
     * the `kind` value.
     *
     * `assetIn` and `assetOut` are either token addresses, or the IAsset sentinel value for ETH (the zero address).
     * Note that Pools never interact with ETH directly: it will be wrapped to or unwrapped from WETH by the Vault.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
  struct SingleSwap {
    bytes32 poolId;
    SwapKind kind;
    IAsset assetIn;
    IAsset assetOut;
    uint256 amount;
    bytes userData;
  }

  /**
   * @dev Performs a series of swaps with one or multiple Pools. In each individual swap, the caller determines either
     * the amount of tokens sent to or received from the Pool, depending on the `kind` value.
     *
     * Returns an array with the net Vault asset balance deltas. Positive amounts represent tokens (or ETH) sent to the
     * Vault, and negative amounts represent tokens (or ETH) sent by the Vault. Each delta corresponds to the asset at
     * the same index in the `assets` array.
     *
     * Swaps are executed sequentially, in the order specified by the `swaps` array. Each array element describes a
     * Pool, the token to be sent to this Pool, the token to receive from it, and an amount that is either `amountIn` or
     * `amountOut` depending on the swap kind.
     *
     * Multihop swaps can be executed by passing an `amount` value of zero for a swap. This will cause the amount in/out
     * of the previous swap to be used as the amount in for the current one. In a 'given in' swap, 'tokenIn' must equal
     * the previous swap's `tokenOut`. For a 'given out' swap, `tokenOut` must equal the previous swap's `tokenIn`.
     *
     * The `assets` array contains the addresses of all assets involved in the swaps. These are either token addresses,
     * or the IAsset sentinel value for ETH (the zero address). Each entry in the `swaps` array specifies tokens in and
     * out by referencing an index in `assets`. Note that Pools never interact with ETH directly: it will be wrapped to
     * or unwrapped from WETH by the Vault.
     *
     * Internal Balance usage, sender, and recipient are determined by the `funds` struct. The `limits` array specifies
     * the minimum or maximum amount of each token the vault is allowed to transfer.
     *
     * `batchSwap` can be used to make a single swap, like `swap` does, but doing so requires more gas than the
     * equivalent `swap` call.
     *
     * Emits `Swap` events.
     */
  function batchSwap(
    SwapKind kind,
    BatchSwapStep[] calldata swaps,
    IAsset[] calldata assets,
    FundManagement calldata funds,
    int256[] calldata limits,
    uint256 deadline
  ) external payable returns (int256[] memory);

  /**
   * @dev Data for each individual swap executed by `batchSwap`. The asset in and out fields are indexes into the
     * `assets` array passed to that function, and ETH assets are converted to WETH.
     *
     * If `amount` is zero, the multihop mechanism is used to determine the actual amount based on the amount in/out
     * from the previous swap, depending on the swap kind.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
  struct BatchSwapStep {
    bytes32 poolId;
    uint256 assetInIndex;
    uint256 assetOutIndex;
    uint256 amount;
    bytes userData;
  }

  /**
   * @dev Emitted for each individual swap performed by `swap` or `batchSwap`.
     */
  event Swap(
    bytes32 indexed poolId,
    IERC20 indexed tokenIn,
    IERC20 indexed tokenOut,
    uint256 amountIn,
    uint256 amountOut
  );

  /**
   * @dev All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
     * `recipient` account.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
     * transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
     * must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
     * `joinPool`.
     *
     * If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
     * transferred. This matches the behavior of `exitPool`.
     *
     * Note that ETH cannot be deposited to or withdrawn from Internal Balance: attempting to do so will trigger a
     * revert.
     */
  struct FundManagement {
    address sender;
    bool fromInternalBalance;
    address payable recipient;
    bool toInternalBalance;
  }

  /**
   * @dev Simulates a call to `batchSwap`, returning an array of Vault asset deltas. Calls to `swap` cannot be
     * simulated directly, but an equivalent `batchSwap` call can and will yield the exact same result.
     *
     * Each element in the array corresponds to the asset at the same index, and indicates the number of tokens (or ETH)
     * the Vault would take from the sender (if positive) or send to the recipient (if negative). The arguments it
     * receives are the same that an equivalent `batchSwap` call would receive.
     *
     * Unlike `batchSwap`, this function performs no checks on the sender or recipient field in the `funds` struct.
     * This makes it suitable to be called by off-chain applications via eth_call without needing to hold tokens,
     * approve them for the Vault, or even know a user's address.
     *
     * Note that this function is not 'view' (due to implementation details): the client code must explicitly execute
     * eth_call instead of eth_sendTransaction.
     */
  function queryBatchSwap(
    SwapKind kind,
    BatchSwapStep[] calldata swaps,
    IAsset[] calldata assets,
    FundManagement calldata funds
  ) external returns (int256[] memory assetDeltas);

  // BasePool.sol

  /**
* @dev Returns the amount of BPT that would be burned from `sender` if the `onExitPool` hook were called by the
     * Vault with the same arguments, along with the number of tokens `recipient` would receive.
     *
     * This function is not meant to be called directly, but rather from a helper contract that fetches current Vault
     * data, such as the protocol swap fee percentage and Pool balances.
     *
     * Like `IVault.queryBatchSwap`, this function is not view due to internal implementation details: the caller must
     * explicitly use eth_call instead of eth_sendTransaction.
     */
  function queryExit(
    bytes32 poolId,
    address sender,
    address recipient,
    uint256[] memory balances,
    uint256 lastChangeBlock,
    uint256 protocolSwapFeePercentage,
    bytes memory userData
  ) external returns (uint256 bptIn, uint256[] memory amountsOut);


}

// SPDX-License-Identifier: ISC
pragma solidity 0.8.17;

/// @notice ChildChainLiquidityGaugeFactory, restored for 0x3b8cA519122CdD8efb272b0D3085453404B25bD0
/// @dev See https://dev.balancer.fi/resources/vebal-and-gauges/gauges
interface IChildChainLiquidityGaugeFactory {
  event RewardsOnlyGaugeCreated(
    address indexed gauge,
    address indexed pool,
    address streamer
  );

  function create(address pool) external returns (address);

  function getChildChainStreamerImplementation() external view returns (address);

  function getGaugeImplementation() external view returns (address);

  function getGaugePool(address gauge) external view returns (address);

  function getGaugeStreamer(address gauge) external view returns (address);

  function getPoolGauge(address pool) external view returns (address);

  function getPoolStreamer(address pool) external view returns (address);

  function isGaugeFromFactory(address gauge) external view returns (bool);

  function isStreamerFromFactory(address streamer) external view returns (bool);
}

// SPDX-License-Identifier: ISC
pragma solidity 0.8.17;

interface IComposableStablePool {
  function balanceOf(address account) external view returns (uint256);
  function getActualSupply() external view returns (uint256);
  function getPoolId() external view returns (bytes32);
  function getBptIndex() external view returns (uint256);
  function updateTokenRateCache(address token) external;
}

// SPDX-License-Identifier: ISC
pragma solidity 0.8.17;

interface ILinearPool {
  function getPoolId() external view returns (bytes32);

  function getMainIndex() external view returns (uint);

  function getMainToken() external view returns (address);

  function getWrappedIndex() external view returns (uint);

  function getWrappedToken() external view returns (address);

  function getWrappedTokenRate() external view returns (uint);

  function getRate() external view returns (uint);

  function getBptIndex() external pure returns (uint);

  function getVirtualSupply() external view returns (uint);

  function getSwapFeePercentage() external view returns (uint);

  function getTargets() external view returns (uint lowerTarget, uint upperTarget);

  function totalSupply() external view returns (uint);

  function getScalingFactors() external view returns (uint[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice List of all errors generated by the application
///         Each error should have unique code TS-XXX and descriptive comment
library AppErrors {
  /// @notice Provided address should be not zero
  string public constant ZERO_ADDRESS = "TS-1 zero address";

  /// @notice A pair of the tokens cannot be found in the factory of uniswap pairs
  string public constant UNISWAP_PAIR_NOT_FOUND = "TS-2 pair not found";

  /// @notice Lengths not matched
  string public constant WRONG_LENGTHS = "TS-4 wrong lengths";

  /// @notice Unexpected zero balance
  string public constant ZERO_BALANCE = "TS-5 zero balance";

  string public constant ITEM_NOT_FOUND = "TS-6 not found";

  string public constant NOT_ENOUGH_BALANCE = "TS-7 not enough balance";

  /// @notice Price oracle returns zero price
  string public constant ZERO_PRICE = "TS-8 zero price";

  string public constant WRONG_VALUE = "TS-9 wrong value";

  /// @notice TetuConvertor wasn't able to make borrow, i.e. borrow-strategy wasn't found
  string public constant ZERO_AMOUNT_BORROWED = "TS-10 zero borrowed amount";

  string public constant WITHDRAW_TOO_MUCH = "TS-11 try to withdraw too much";

  string public constant UNKNOWN_ENTRY_KIND = "TS-12 unknown entry kind";

  string public constant ONLY_TETU_CONVERTER = "TS-13 only TetuConverter";

  string public constant WRONG_ASSET = "TS-14 wrong asset";

  string public constant NO_LIQUIDATION_ROUTE = "TS-15 No liquidation route";

  string public constant PRICE_IMPACT = "TS-16 price impact";

  /// @notice tetuConverter_.repay makes swap internally. It's not efficient and not allowed
  string public constant REPAY_MAKES_SWAP = "TS-17 can not convert back";

  string public constant NO_INVESTMENTS = "TS-18 no investments";

  string public constant INCORRECT_LENGTHS = "TS-19 lengths";

  /// @notice We expect increasing of the balance, but it was decreased
  string public constant BALANCE_DECREASE = "TS-20 balance decrease";

  /// @notice Prices changed and invested assets amount was increased on S, value of S is too high
  string public constant EARNED_AMOUNT_TOO_HIGH = "TS-21 earned too high";
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@tetu_io/tetu-contracts-v2/contracts/interfaces/IERC20.sol";
import "@tetu_io/tetu-contracts-v2/contracts/interfaces/IERC20Metadata.sol";
import "@tetu_io/tetu-contracts-v2/contracts/openzeppelin/SafeERC20.sol";

/// @notice Common internal utils
library AppLib {
  using SafeERC20 for IERC20;

  /// @notice Unchecked increment for for-cycles
  function uncheckedInc(uint i) internal pure returns (uint) {
    unchecked {
      return i + 1;
    }
  }

  /// @notice Make infinite approve of {token} to {spender} if the approved amount is less than {amount}
  /// @dev Should NOT be used for third-party pools
  function approveIfNeeded(address token, uint amount, address spender) internal {
    if (IERC20(token).allowance(address(this), spender) < amount) {
      IERC20(token).safeApprove(spender, 0);
      // infinite approve, 2*255 is more gas efficient then type(uint).max
      IERC20(token).safeApprove(spender, 2 ** 255);
    }
  }

  function balance(address token) internal view returns (uint) {
    return IERC20(token).balanceOf(address(this));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library AppPlatforms {
  string public constant UNIV3 = "UniswapV3";
  string public constant BALANCER = "Balancer";
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice Utils and constants related to entryKind param of ITetuConverter.findBorrowStrategy
library ConverterEntryKinds {
  /// @notice Amount of collateral is fixed. Amount of borrow should be max possible.
  uint constant public ENTRY_KIND_EXACT_COLLATERAL_IN_FOR_MAX_BORROW_OUT_0 = 0;

  /// @notice Split provided source amount S on two parts: C1 and C2 (C1 + C2 = S)
  ///         C2 should be used as collateral to make a borrow B.
  ///         Results amounts of C1 and B (both in terms of USD) must be in the given proportion
  uint constant public ENTRY_KIND_EXACT_PROPORTION_1 = 1;

  /// @notice Borrow given amount using min possible collateral
  uint constant public ENTRY_KIND_EXACT_BORROW_OUT_FOR_MIN_COLLATERAL_IN_2 = 2;

  /// @notice Decode entryData, extract first uint - entry kind
  ///         Valid values of entry kinds are given by ENTRY_KIND_XXX constants above
  function getEntryKind(bytes memory entryData_) internal pure returns (uint) {
    if (entryData_.length == 0) {
      return ENTRY_KIND_EXACT_COLLATERAL_IN_FOR_MAX_BORROW_OUT_0;
    }
    return abi.decode(entryData_, (uint));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./AppErrors.sol";

/// @title Library for clearing / joining token addresses & amounts arrays
/// @author bogdoslav
library TokenAmountsLib {
  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string internal constant TOKEN_AMOUNTS_LIB_VERSION = "1.0.1";

  function uncheckedInc(uint i) internal pure returns (uint) {
    unchecked {
      return i + 1;
    }
  }

  function filterZeroAmounts(
    address[] memory tokens,
    uint[] memory amounts
  ) internal pure returns (
    address[] memory t,
    uint[] memory a
  ) {
    require(tokens.length == amounts.length, AppErrors.INCORRECT_LENGTHS);
    uint len2 = 0;
    uint len = tokens.length;
    for (uint i = 0; i < len; i++) {
      if (amounts[i] != 0) len2++;
    }

    t = new address[](len2);
    a = new uint[](len2);

    uint j = 0;
    for (uint i = 0; i < len; i++) {
      uint amount = amounts[i];
      if (amount != 0) {
        t[j] = tokens[i];
        a[j] = amount;
        j++;
      }
    }
  }

  /// @notice unites three arrays to single array without duplicates, amounts are sum, zero amounts are allowed
  function combineArrays(
    address[] memory tokens0,
    uint[] memory amounts0,
    address[] memory tokens1,
    uint[] memory amounts1,
    address[] memory tokens2,
    uint[] memory amounts2
  ) internal pure returns (
    address[] memory allTokens,
    uint[] memory allAmounts
  ) {
    uint[] memory lens = new uint[](3);
    lens[0] = tokens0.length;
    lens[1] = tokens1.length;
    lens[2] = tokens2.length;

    require(
      lens[0] == amounts0.length && lens[1] == amounts1.length && lens[2] == amounts2.length,
      AppErrors.INCORRECT_LENGTHS
    );

    uint maxLength = lens[0] + lens[1] + lens[2];
    address[] memory tokensOut = new address[](maxLength);
    uint[] memory amountsOut = new uint[](maxLength);
    uint unitedLength;

    for (uint step; step < 3; ++step) {
      uint[] memory amounts = step == 0
        ? amounts0
        : (step == 1
          ? amounts1
          : amounts2);
      address[] memory tokens = step == 0
        ? tokens0
        : (step == 1
          ? tokens1
          : tokens2);
      for (uint i1 = 0; i1 < lens[step]; i1++) {
        uint amount1 = amounts[i1];
        address token1 = tokens[i1];
        bool united = false;

        for (uint i = 0; i < unitedLength; i++) {
          if (token1 == tokensOut[i]) {
            amountsOut[i] += amount1;
            united = true;
            break;
          }
        }

        if (!united) {
          tokensOut[unitedLength] = token1;
          amountsOut[unitedLength] = amount1;
          unitedLength++;
        }
      }
    }

    // copy united tokens to result array
    allTokens = new address[](unitedLength);
    allAmounts = new uint[](unitedLength);
    for (uint i; i < unitedLength; i++) {
      allTokens[i] = tokensOut[i];
      allAmounts[i] = amountsOut[i];
    }

  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@tetu_io/tetu-contracts-v2/contracts/openzeppelin/Initializable.sol";
import "@tetu_io/tetu-contracts-v2/contracts/interfaces/IERC20.sol";
import "../DepositorBase.sol";
import "./BalancerLogicLib.sol";
import "../../integrations/balancer/IBVault.sol";
import "../../integrations/balancer/IBalancerHelper.sol";
import "../../integrations/balancer/IComposableStablePool.sol";
import "../../integrations/balancer/IChildChainLiquidityGaugeFactory.sol";
import "../../integrations/balancer/IBalancerGauge.sol";


/// @title Depositor for Composable Stable Pool with several embedded linear pools like "Balancer Boosted Tetu USD"
/// @dev See https://app.balancer.fi/polygon#/polygon/pool/0xb3d658d5b95bf04e2932370dd1ff976fe18dd66a000000000000000000000ace
///            bb-t-DAI (DAI + tDAI) + bb-t-USDC (USDC + tUSDC) + bb-t-USDT (USDT + tUSDT)
///      See https://docs.balancer.fi/products/balancer-pools/boosted-pools for explanation of Boosted Pools on BalanceR.
///      Terms
///         bb-t-USD = pool bpt
///         bb-t-DAI, bb-t-USDC, bb-t-USDT = underlying bpt
abstract contract BalancerBoostedDepositor is DepositorBase, Initializable {
  using SafeERC20 for IERC20;

  /////////////////////////////////////////////////////////////////////
  ///region Constants
  /////////////////////////////////////////////////////////////////////

  /// @dev Version of this contract. Adjust manually on each code modification.
  string public constant BALANCER_BOOSTED_DEPOSITOR_VERSION = "1.0.0";

  /// @dev https://dev.balancer.fi/references/contracts/deployment-addresses
  IBVault internal constant BALANCER_VAULT = IBVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
  address internal constant BALANCER_HELPER = 0x239e55F427D44C3cc793f49bFB507ebe76638a2b;
  /// @notice ChildChainLiquidityGaugeFactory allows to get gauge address by pool id
  /// @dev see https://dev.balancer.fi/resources/vebal-and-gauges/gauges
  /// todo Update to new gauges, new ChildChainGauge is 0xc9b36096f5201ea332Db35d6D195774ea0D5988f
  address internal constant CHILD_CHAIN_LIQUIDITY_GAUGE_FACTORY = 0x3b8cA519122CdD8efb272b0D3085453404B25bD0;

  /////////////////////////////////////////////////////////////////////
  ///endregion Constants
  /////////////////////////////////////////////////////////////////////

  /////////////////////////////////////////////////////////////////////
  //region Variables
  //                Keep names and ordering!
  // Add only in the bottom and don't forget to decrease gap variable
  /////////////////////////////////////////////////////////////////////

  /// @notice i.e. for "Balancer Boosted Aave USD": 0x48e6b98ef6329f8f0a30ebb8c7c960330d64808500000000000000000000075b
  /// @notice i.e. for "Balancer Boosted Tetu USD": 0xb3d658d5b95bf04e2932370dd1ff976fe18dd66a000000000000000000000ace
  bytes32 public poolId;
  IBalancerGauge public gauge;
  /////////////////////////////////////////////////////////////////////
  ///endregion Variables
  /////////////////////////////////////////////////////////////////////


  /////////////////////////////////////////////////////////////////////
  ///                   Initialization
  /////////////////////////////////////////////////////////////////////

  function __BalancerBoostedDepositor_init(address pool_) internal onlyInitializing {
    poolId = IComposableStablePool(pool_).getPoolId();

    gauge = IBalancerGauge(
      IChildChainLiquidityGaugeFactory(
        CHILD_CHAIN_LIQUIDITY_GAUGE_FACTORY
      ).getPoolGauge(pool_)
    );
    // infinite approve of pool-BPT to the gauge todo is it safe for the external gauge?
    IERC20(pool_).safeApprove(address(gauge), type(uint).max);
  }

  /////////////////////////////////////////////////////////////////////
  ///                       View
  /////////////////////////////////////////////////////////////////////

  /// @notice Returns pool assets, same as getPoolTokens but without pool-bpt
  function _depositorPoolAssets() override internal virtual view returns (address[] memory poolAssets) {
    return BalancerLogicLib.depositorPoolAssets(BALANCER_VAULT, poolId);
  }

  /// @notice Returns pool weights
  /// @return weights Array with weights, length = getPoolTokens.tokens - 1 (all assets except BPT)
  /// @return totalWeight Total sum of all items of {weights}
  function _depositorPoolWeights() override internal virtual view returns (uint[] memory weights, uint totalWeight) {
    return BalancerLogicLib.depositorPoolWeights(BALANCER_VAULT, poolId);
  }

  /// @notice Total amounts of the main assets under control of the pool, i.e amounts of DAI, USDC, USDT
  /// @return reservesOut Total amounts of embedded assets, i.e. for "Balancer Boosted Aave USD" we return:
  ///                     0: balance DAI + (balance amDAI recalculated to DAI)
  ///                     1: balance USDC + (amUSDC recalculated to USDC)
  ///                     2: balance USDT + (amUSDT recalculated to USDT)
  function _depositorPoolReserves() override internal virtual view returns (uint[] memory reservesOut) {
    reservesOut = BalancerLogicLib.depositorPoolReserves(BALANCER_VAULT, poolId);
  }

  /// @notice Returns depositor's pool shares / lp token amount
  function _depositorLiquidity() override internal virtual view returns (uint liquidityOut) {
    liquidityOut = gauge.balanceOf(address(this))
    + IComposableStablePool(BalancerLogicLib.getPoolAddress(poolId)).balanceOf(address(this));
  }

  //// @notice Total amount of liquidity (LP tokens) in the depositor
  function _depositorTotalSupply() override internal view returns (uint totalSupplyOut) {
    totalSupplyOut = IComposableStablePool(BalancerLogicLib.getPoolAddress(poolId)).getActualSupply();
  }

  /////////////////////////////////////////////////////////////////////
  ///             Enter, exit
  /////////////////////////////////////////////////////////////////////

  /// @notice Deposit given amount to the pool.
  /// @param amountsDesired_ Amounts of assets on the balance of the depositor
  ///         The order of assets is the same as in getPoolTokens, but there is no pool-bpt
  ///         i.e. for "Balancer Boosted Aave USD" we have DAI, USDC, USDT
  /// @return amountsConsumedOut Amounts of assets deposited to balanceR pool
  ///         The order of assets is the same as in getPoolTokens, but there is no pool-bpt
  /// @return liquidityOut Total amount of liquidity added to balanceR pool in terms of pool-bpt tokens
  function _depositorEnter(uint[] memory amountsDesired_) override internal virtual returns (
    uint[] memory amountsConsumedOut,
    uint liquidityOut
  ) {
    bytes32 _poolId = poolId;
    IComposableStablePool pool = IComposableStablePool(BalancerLogicLib.getPoolAddress(_poolId));

    // join to the pool, receive pool-BPTs
    (amountsConsumedOut, liquidityOut) = BalancerLogicLib.depositorEnter(BALANCER_VAULT, _poolId, amountsDesired_);

    // stake all available pool-BPTs to the gauge
    // we can have pool-BPTs on depositor's balance after previous exit, stake them too
    gauge.deposit(pool.balanceOf(address(this)));
  }

  /// @notice Withdraw given amount of LP-tokens from the pool.
  /// @dev if requested liquidityAmount >= invested, then should make full exit
  /// @param liquidityAmount_ Max amount to withdraw in bpt. Actual withdrawn amount will be less,
  ///                         so it worth to add a gap to this amount, i.e. 1%
  /// @return amountsOut Result amounts of underlying (DAI, USDC..) that will be received from BalanceR
  ///         The order of assets is the same as in getPoolTokens, but there is no pool-bpt
  function _depositorExit(uint liquidityAmount_) override internal virtual returns (
    uint[] memory amountsOut
  ) {
    bytes32 _poolId = poolId;
    IBalancerGauge __gauge = gauge;
    IComposableStablePool pool = IComposableStablePool(BalancerLogicLib.getPoolAddress(_poolId));

    // we need to withdraw pool-BPTs from the _gauge
    // at first, let's try to use exist pool-BPTs on the depositor balance, probably it's enough
    // we can have pool-BPTs on depositor's balance after previous exit, see BalancerLogicLib.depositorExit
    uint depositorBalance = pool.balanceOf(address(this));
    uint gaugeBalance = __gauge.balanceOf(address(this));

    uint liquidityToWithdraw = liquidityAmount_ > depositorBalance
    ? liquidityAmount_ - depositorBalance
    : 0;

    // calculate how much pool-BPTs we should withdraw from the gauge
    if (liquidityToWithdraw > 0) {
      if (liquidityToWithdraw > gaugeBalance) {
        liquidityToWithdraw = gaugeBalance;
      }
    }

    // un-stake required pool-BPTs from the gauge
    if (liquidityToWithdraw > 0) {
      __gauge.withdraw(liquidityToWithdraw);
    }

    // withdraw the liquidity from the pool
    amountsOut = (liquidityAmount_ >= depositorBalance + gaugeBalance)
    ? BalancerLogicLib.depositorExitFull(BALANCER_VAULT, _poolId)
    : BalancerLogicLib.depositorExit(BALANCER_VAULT, _poolId, liquidityToWithdraw);
  }

  /// @notice Quotes output for given amount of LP-tokens from the pool.
  /// @dev if requested liquidityAmount >= invested, then full exit is required
  ///      we emulate is at normal exit + conversion of remain BPT directly to the main asset
  /// @return amountsOut Result amounts of underlying (DAI, USDC..) that will be received from BalanceR
  ///         The order of assets is the same as in getPoolTokens, but there is no pool-bpt
  function _depositorQuoteExit(uint liquidityAmount_) override internal virtual returns (uint[] memory amountsOut) {
    uint liquidity = _depositorLiquidity();
    if (liquidity == 0) {
      // there is no liquidity, output is zero
      return new uint[](_depositorPoolAssets().length);
    } else {
      // BalancerLogicLib.depositorQuoteExit takes into account the cost of unused BPT
      // so we don't need a special logic here for the full exit
      return BalancerLogicLib.depositorQuoteExit(
        BALANCER_VAULT,
        IBalancerHelper(BALANCER_HELPER),
        poolId,
        liquidityAmount_
      );
    }
  }

  /////////////////////////////////////////////////////////////////////
  ///             Claim rewards
  /////////////////////////////////////////////////////////////////////

  /// @dev Claim all possible rewards.
  function _depositorClaimRewards() override internal virtual returns (
    address[] memory tokensOut,
    uint[] memory amountsOut,
    uint[] memory depositorBalancesBefore
  ) {
    return BalancerLogicLib.depositorClaimRewards(gauge, _depositorPoolAssets(), rewardTokens());
  }

  /// @dev Returns reward token addresses array.
  function rewardTokens() public view returns (address[] memory tokens) {
    uint total;
    for (; total < 8; ++total) {
      if (gauge.reward_tokens(total) == address(0)) {
        break;
      }
    }
    tokens = new address[](total);
    for (uint i; i < total; ++i) {
      tokens[i] = gauge.reward_tokens(i);
    }
  }

  /// @dev This empty reserved space is put in place to allow future versions to add new
  /// variables without shifting down storage in the inheritance chain.
  /// See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
  uint[50-2] private __gap; // 50 - count of variables
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../ConverterStrategyBase.sol";
import "./BalancerBoostedDepositor.sol";
import "../../libs/AppPlatforms.sol";

/// @title Delta-neutral converter strategy for Balancer boosted pools
/// @author a17, dvpublic
contract BalancerBoostedStrategy is ConverterStrategyBase, BalancerBoostedDepositor {
  string public constant override NAME = "Balancer Boosted Strategy";
  string public constant override PLATFORM = AppPlatforms.BALANCER;
  string public constant override STRATEGY_VERSION = "1.0.1";

  function init(
    address controller_,
    address splitter_,
    address converter_,
    address pool_
  ) external initializer {
    __BalancerBoostedDepositor_init(pool_);
    __ConverterStrategyBase_init(controller_, splitter_, converter_);

    // setup specific name for UI
    strategySpecificName = BalancerLogicLib.createSpecificName(pool_);
    emit StrategyLib.StrategySpecificNameChanged(strategySpecificName); // todo: change to _checkStrategySpecificNameChanged
  }

  function _handleRewards() internal virtual override returns (uint earned, uint lost, uint assetBalanceAfterClaim) {
    uint assetBalanceBefore = AppLib.balance(asset);
    (address[] memory rewardTokens, uint[] memory amounts) = _claim();
    _rewardsLiquidation(rewardTokens, amounts);
    assetBalanceAfterClaim = AppLib.balance(asset);
    (uint earned2, uint lost2) = ConverterStrategyBaseLib.registerIncome(assetBalanceBefore, assetBalanceAfterClaim);
    return (earned + earned2, lost + lost2, assetBalanceAfterClaim);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@tetu_io/tetu-contracts-v2/contracts/interfaces/IERC20.sol";
import "@tetu_io/tetu-contracts-v2/contracts/interfaces/IERC20Metadata.sol";
import "@tetu_io/tetu-contracts-v2/contracts/openzeppelin/SafeERC20.sol";
import "../../libs/AppErrors.sol";
import "../../libs/AppLib.sol";
import "../../libs/TokenAmountsLib.sol";
import "../../integrations/balancer/IComposableStablePool.sol";
import "../../integrations/balancer/ILinearPool.sol";
import "../../integrations/balancer/IBVault.sol";
import "../../integrations/balancer/IBalancerHelper.sol";
import "../../integrations/balancer/IBalancerGauge.sol";

/// @notice Functions of BalancerBoostedDepositor
/// @dev Many of functions are declared as external to reduce contract size
library BalancerLogicLib {
  using SafeERC20 for IERC20;

  /////////////////////////////////////////////////////////////////////
  ///             Types
  /////////////////////////////////////////////////////////////////////

  /// @dev local vars in getAmountsToDeposit to avoid stack too deep
  struct LocalGetAmountsToDeposit {
    /// @notice Decimals of {tokens_}, 0 for BPT
    uint[] decimals;
    /// @notice Length of {tokens_} array
    uint len;
    /// @notice amountBPT / underlyingAmount, decimals 18, 0 for BPT
    uint[] rates;
  }

  /// @notice Local variables required inside _depositorEnter/Exit/QuoteExit, avoid stack too deep
  struct DepositorLocal {
    uint bptIndex;
    uint len;
    IERC20[] tokens;
    uint[] balances;
  }

  /// @notice Used in linear pool quote swap math logic
  struct LinearPoolParams {
    uint fee;
    uint lowerTarget;
    uint upperTarget;
  }

  /////////////////////////////////////////////////////////////////////
  ///             Asset related utils
  /////////////////////////////////////////////////////////////////////

  /// @notice Calculate amounts of {tokens} to be deposited to POOL_ID in proportions according to the {balances}
  /// @param amountsDesired_ Desired amounts of tokens. The order of the tokens is exactly the same as in {tokens}.
  ///                        But the array has length 3, not 4, because there is no amount for bb-am-USD here.
  /// @param tokens_ All bb-am-* tokens (including bb-am-USD) received through getPoolTokens
  ///                           The order of the tokens is exactly the same as in getPoolTokens-results
  /// @param balances_ Balances of bb-am-* pools in terms of bb-am-USD tokens (received through getPoolTokens)
  ///                           The order of the tokens is exactly the same as in {tokens}
  /// @param totalUnderlying_ Total amounts of underlying assets (DAI, USDC, etc) in embedded linear pools.
  ///                         The array should have same order of tokens as {tokens_}, value for BPT token is not used
  /// @param indexBpt_ Index of BPT token inside {balances_}, {tokens_} and {totalUnderlying_} arrays
  /// @return amountsOut Desired amounts in proper proportions for depositing.
  ///         The order of the tokens is exactly the same as in results of getPoolTokens, 0 for BPT
  ///         i.e. DAI, BB-AM-USD, USDC, USDT
  function getAmountsToDeposit(
    uint[] memory amountsDesired_,
    IERC20[] memory tokens_,
    uint[] memory balances_,
    uint[] memory totalUnderlying_,
    uint indexBpt_
  ) internal view returns (
    uint[] memory amountsOut
  ) {
    LocalGetAmountsToDeposit memory p;
    // check not zero balances, cache index of bbAmUSD, save 10**decimals to array
    p.len = tokens_.length;
    require(p.len == balances_.length, AppErrors.WRONG_LENGTHS);
    require(p.len == amountsDesired_.length || p.len - 1 == amountsDesired_.length, AppErrors.WRONG_LENGTHS);

    p.decimals = new uint[](p.len);
    p.rates = new uint[](p.len);
    for (uint i = 0; i < p.len; i = AppLib.uncheckedInc(i)) {
      if (i != indexBpt_) {
        require(balances_[i] != 0, AppErrors.ZERO_BALANCE);
        p.decimals[i] = 10 ** IERC20Metadata(address(tokens_[i])).decimals();

        // Let's calculate a rate: amountBPT / underlyingAmount, decimals 18
        p.rates[i] = balances_[i] * 1e18 / totalUnderlying_[i];
      }
    }

    amountsOut = new uint[](p.len - 1);

    // The balances set proportions of underlying-bpt, i.e. bb-am-DAI : bb-am-USDC : bb-am-USDT
    // Our task is find amounts of DAI : USDC : USDT that won't change that proportions after deposit.
    // We have arbitrary desired amounts, i.e. DAI = X, USDC = Y, USDT = Z
    // For each token: assume that it can be used in full.
    // If so, what amounts will have other tokens in this case according to the given proportions?
    // i.e. DAI = X = 100.0 => USDC = 200.0, USDT = 400.0. We need: Y >= 200, Z >= 400
    // or   USDC = Y = 100.0 => DAI = 50.0, USDT = 200.0. We need: X >= 50, Z >= 200
    // If any amount is less then expected, the token cannot be used in full.
    // A token with min amount can be used in full, let's try to find its index.
    // [0 : len - 1]
    uint i3;
    for (uint i; i < p.len; i = AppLib.uncheckedInc(i)) {
      if (indexBpt_ == i) continue;

      uint amountInBpt18 = amountsDesired_[i3] * p.rates[i];

      // [0 : len]
      uint j;
      // [0 : len - 1]
      uint j3;
      for (; j < p.len; j = AppLib.uncheckedInc(j)) {
        if (indexBpt_ == j) continue;

        // alpha = balancesDAI / balancesUSDC * decimalsDAI / decimalsUSDC
        // amountDAI = amountUSDC * alpha * rateUSDC / rateDAI
        amountsOut[j3] = amountInBpt18 * balances_[j] / p.rates[j] * p.decimals[j] / balances_[i] / p.decimals[i];
        if (amountsOut[j3] > amountsDesired_[j3]) break;
        j3++;
      }

      if (j == p.len) break;
      i3++;
    }
  }


  /// @notice Calculate total amount of underlying asset for each token except BPT
  /// @dev Amount is calculated as MainTokenAmount + WrappedTokenAmount * WrappedTokenRate, see AaveLinearPool src
  function getTotalAssetAmounts(IBVault vault_, IERC20[] memory tokens_, uint indexBpt_) internal view returns (
    uint[] memory amountsOut
  ) {
    uint len = tokens_.length;
    amountsOut = new uint[](len);
    for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
      if (i != indexBpt_) {
        ILinearPool linearPool = ILinearPool(address(tokens_[i]));
        (, uint[] memory balances,) = vault_.getPoolTokens(linearPool.getPoolId());

        amountsOut[i] =
        balances[linearPool.getMainIndex()]
        + balances[linearPool.getWrappedIndex()] * linearPool.getWrappedTokenRate() / 1e18;
      }
    }
  }

  /// @notice Split {liquidityAmount_} by assets according to proportions of their total balances
  /// @param liquidityAmount_ Amount to withdraw in bpt
  /// @param balances_ Balances received from getPoolTokens
  /// @param bptIndex_ Index of pool-pbt inside {balances_}
  /// @return bptAmountsOut Amounts of underlying-BPT. The array doesn't include an amount for pool-bpt
  ///         Total amount of {bptAmountsOut}-items is equal to {liquidityAmount_}
  function getBtpAmountsOut(
    uint liquidityAmount_,
    uint[] memory balances_,
    uint bptIndex_
  ) internal pure returns (uint[] memory bptAmountsOut) {
    // we assume here, that len >= 2
    // we don't check it because StableMath.sol in balancer has _MIN_TOKENS = 2;
    uint len = balances_.length;
    bptAmountsOut = new uint[](len - 1);

    // compute total balance, skip pool-bpt
    uint totalBalances;
    uint k;
    for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
      if (i == bptIndex_) continue;
      totalBalances += balances_[i];
      // temporary save incomplete amounts to bptAmountsOut
      bptAmountsOut[k] = liquidityAmount_ * balances_[i];
      ++k;
    }

    // finalize computation of bptAmountsOut using known totalBalances
    uint total;
    for (k = 0; k < len - 1; k = AppLib.uncheckedInc(k)) {
      if (k == len - 2) {
        // leftovers => last item
        bptAmountsOut[k] = total > liquidityAmount_
        ? 0
        : liquidityAmount_ - total;
      } else {
        bptAmountsOut[k] /= totalBalances;
        total += bptAmountsOut[k];
      }
    }
  }

  /////////////////////////////////////////////////////////////////////
  ///             Depositor view logic
  /////////////////////////////////////////////////////////////////////
  /// @notice Total amounts of the main assets under control of the pool, i.e amounts of USDT, USDC, DAI
  /// @return reservesOut Total amounts of embedded assets, i.e. for "Balancer Boosted Tetu USD" we return:
  ///                     0: balance USDT + (tUSDT recalculated to USDT)
  ///                     1: balance USDC + (tUSDC recalculated to USDC)
  ///                     2: balance DAI + (balance tDAI recalculated to DAI)
  function depositorPoolReserves(IBVault vault_, bytes32 poolId_) external view returns (uint[] memory reservesOut) {
    (IERC20[] memory tokens,,) = vault_.getPoolTokens(poolId_);
    uint bptIndex = IComposableStablePool(getPoolAddress(poolId_)).getBptIndex();
    uint len = tokens.length;
    // exclude pool-BPT
    reservesOut = new uint[](len - 1);

    uint k;
    for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
      if (i == bptIndex) continue;
      ILinearPool linearPool = ILinearPool(address(tokens[i]));

      // Each bb-t-* returns (main-token, wrapped-token, bb-t-itself), the order of tokens is arbitrary
      // i.e. (DAI + tDAI + bb-t-DAI) or (bb-t-USDC, tUSDC, USDC)

      // get balances of all tokens of bb-am-XXX token, i.e. balances of (DAI, amDAI, bb-am-DAI)
      (, uint[] memory balances,) = vault_.getPoolTokens(linearPool.getPoolId());
      // DAI
      uint mainIndex = linearPool.getMainIndex();
      // tDAI
      uint wrappedIndex = linearPool.getWrappedIndex();

      reservesOut[k] = balances[mainIndex] + balances[wrappedIndex] * linearPool.getWrappedTokenRate() / 1e18;
      ++k;
    }
  }

  /// @notice Returns pool assets, same as getPoolTokens but without pool-bpt
  function depositorPoolAssets(IBVault vault_, bytes32 poolId_) external view returns (address[] memory poolAssets) {
    (IERC20[] memory tokens,,) = vault_.getPoolTokens(poolId_);
    uint bptIndex = IComposableStablePool(getPoolAddress(poolId_)).getBptIndex();
    uint len = tokens.length;

    poolAssets = new address[](len - 1);
    uint k;
    for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
      if (i == bptIndex) continue;

      poolAssets[k] = ILinearPool(address(tokens[i])).getMainToken();
      ++k;
    }
  }

  /// @notice Returns pool weights
  /// @return weights Array with weights, length = getPoolTokens.tokens - 1 (all assets except BPT)
  /// @return totalWeight Total sum of all items of {weights}
  function depositorPoolWeights(IBVault vault_, bytes32 poolId_) external view returns (
    uint[] memory weights,
    uint totalWeight
  ) {
    (IERC20[] memory tokens,uint[] memory balances,) = vault_.getPoolTokens(poolId_);
    uint len = tokens.length;
    uint bptIndex = IComposableStablePool(getPoolAddress(poolId_)).getBptIndex();
    weights = new uint[](len - 1);
    uint j;
    for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
      if (i != bptIndex) {
        totalWeight += balances[i];
        weights[j] = balances[i];
        j = AppLib.uncheckedInc(j);
      }
    }
  }

  /////////////////////////////////////////////////////////////////////
  ///             Depositor enter, exit logic
  /////////////////////////////////////////////////////////////////////
  /// @notice Deposit given amount to the pool.
  /// @param amountsDesired_ Amounts of assets on the balance of the depositor
  ///         The order of assets is the same as in getPoolTokens, but there is no pool-bpt
  ///         i.e. for "Balancer Boosted Aave USD" we have DAI, USDC, USDT
  /// @return amountsConsumedOut Amounts of assets deposited to balanceR pool
  ///         The order of assets is the same as in getPoolTokens, but there is no pool-bpt
  /// @return liquidityOut Total amount of liquidity added to balanceR pool in terms of pool-bpt tokens
  function depositorEnter(IBVault vault_, bytes32 poolId_, uint[] memory amountsDesired_) external returns (
    uint[] memory amountsConsumedOut,
    uint liquidityOut
  ) {
    DepositorLocal memory p;

    // The implementation below assumes, that getPoolTokens returns the assets in following order:
    //    bb-am-dai, bb-am-usd, bb-am-usdc, bb-am-usdt
    (p.tokens, p.balances,) = vault_.getPoolTokens(poolId_);
    p.len = p.tokens.length;
    p.bptIndex = IComposableStablePool(getPoolAddress(poolId_)).getBptIndex();

    // temporary save current liquidity
    liquidityOut = IComposableStablePool(address(p.tokens[p.bptIndex])).balanceOf(address(this));

    // Original amounts can have any values.
    // But we need amounts in such proportions that won't move the current balances
    {
      uint[] memory underlying = BalancerLogicLib.getTotalAssetAmounts(vault_, p.tokens, p.bptIndex);
      amountsConsumedOut = BalancerLogicLib.getAmountsToDeposit(amountsDesired_, p.tokens, p.balances, underlying, p.bptIndex);
    }

    // we can create funds_ once and use it several times
    IBVault.FundManagement memory funds = IBVault.FundManagement({
      sender : address(this),
      fromInternalBalance : false,
      recipient : payable(address(this)),
      toInternalBalance : false
    });

    // swap all tokens XX => bb-am-XX
    // we need two arrays with same amounts: amountsToDeposit (with 0 for BB-AM-USD) and userDataAmounts (no BB-AM-USD)
    uint[] memory amountsToDeposit = new uint[](p.len);
    // no bpt
    uint[] memory userDataAmounts = new uint[](p.len - 1);
    uint k;
    for (uint i; i < p.len; i = AppLib.uncheckedInc(i)) {
      if (i == p.bptIndex) continue;
      amountsToDeposit[i] = BalancerLogicLib.swap(
        vault_,
        ILinearPool(address(p.tokens[i])).getPoolId(),
        ILinearPool(address(p.tokens[i])).getMainToken(),
        address(p.tokens[i]),
        amountsConsumedOut[k],
        funds
      );
      userDataAmounts[k] = amountsToDeposit[i];
      AppLib.approveIfNeeded(address(p.tokens[i]), amountsToDeposit[i], address(vault_));
      ++k;
    }

    // add liquidity to balancer
    vault_.joinPool(
      poolId_,
      address(this),
      address(this),
      IBVault.JoinPoolRequest({
        assets : asIAsset(p.tokens), // must have the same length and order as the array returned by `getPoolTokens`
        maxAmountsIn : amountsToDeposit,
        userData : abi.encode(IBVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, userDataAmounts, 0),
        fromInternalBalance : false
      })
    );

    uint liquidityAfter = IERC20(address(p.tokens[p.bptIndex])).balanceOf(address(this));

    liquidityOut = liquidityAfter > liquidityOut
    ? liquidityAfter - liquidityOut
    : 0;
  }

  /// @notice Withdraw given amount of LP-tokens from the pool.
  /// @param liquidityAmount_ Amount to withdraw in bpt
  /// @return amountsOut Result amounts of underlying (DAI, USDC..) that will be received from BalanceR
  ///         The order of assets is the same as in getPoolTokens, but there is no pool-bpt
  function depositorExit(IBVault vault_, bytes32 poolId_, uint liquidityAmount_) external returns (
    uint[] memory amountsOut
  ) {
    DepositorLocal memory p;

    p.bptIndex = IComposableStablePool(getPoolAddress(poolId_)).getBptIndex();
    (p.tokens, p.balances,) = vault_.getPoolTokens(poolId_);
    p.len = p.tokens.length;

    require(liquidityAmount_ <= p.tokens[p.bptIndex].balanceOf(address(this)), AppErrors.NOT_ENOUGH_BALANCE);

    // BalancerR can spend a bit less amount of liquidity than {liquidityAmount_}
    // i.e. we if liquidityAmount_ = 2875841, we can have leftovers = 494 after exit
    vault_.exitPool(
      poolId_,
      address(this),
      payable(address(this)),
      IBVault.ExitPoolRequest({
        assets : asIAsset(p.tokens), // must have the same length and order as the array returned by `getPoolTokens`
        minAmountsOut : new uint[](p.len), // no limits
        userData : abi.encode(IBVault.ExitKindComposableStable.EXACT_BPT_IN_FOR_ALL_TOKENS_OUT, liquidityAmount_),
        toInternalBalance : false
      })
    );

    // now we have amBbXXX tokens; swap them to XXX assets

    // we can create funds_ once and use it several times
    IBVault.FundManagement memory funds = IBVault.FundManagement({
    sender : address(this),
    fromInternalBalance : false,
    recipient : payable(address(this)),
    toInternalBalance : false
    });

    amountsOut = new uint[](p.len - 1);
    uint k;
    for (uint i; i < p.len; i = AppLib.uncheckedInc(i)) {
      if (i == p.bptIndex) continue;
      uint amountIn = p.tokens[i].balanceOf(address(this));
      if (amountIn != 0) {
        amountsOut[k] = swap(
          vault_,
          ILinearPool(address(p.tokens[i])).getPoolId(),
          address(p.tokens[i]),
          ILinearPool(address(p.tokens[i])).getMainToken(),
          amountIn,
          funds
        );
      }
      ++k;
    }
  }

  /// @notice Withdraw all available amount of LP-tokens from the pool
  ///         BalanceR doesn't allow to withdraw exact amount, so it's allowed to leave dust amount on the balance
  /// @dev We make at most N attempts to withdraw (not more, each attempt takes a lot of gas).
  ///      Each attempt reduces available balance at ~1e4 times.
  /// @return amountsOut Result amounts of underlying (DAI, USDC..) that will be received from BalanceR
  ///                    The order of assets is the same as in getPoolTokens, but there is no pool-bpt
  function depositorExitFull(IBVault vault_, bytes32 poolId_) external returns (
    uint[] memory amountsOut
  ) {
    DepositorLocal memory p;

    p.bptIndex = IComposableStablePool(getPoolAddress(poolId_)).getBptIndex();
    (p.tokens, p.balances,) = vault_.getPoolTokens(poolId_);
    p.len = p.tokens.length;
    amountsOut = new uint[](p.len - 1);

    // we can create funds_ once and use it several times
    IBVault.FundManagement memory funds = IBVault.FundManagement({
      sender : address(this),
      fromInternalBalance : false,
      recipient : payable(address(this)),
      toInternalBalance : false
    });

    uint liquidityAmount = p.tokens[p.bptIndex].balanceOf(address(this));
    if (liquidityAmount > 0) {
      uint liquidityThreshold = 10 ** IERC20Metadata(address(p.tokens[p.bptIndex])).decimals() / 100;

      // we can make at most N attempts to withdraw amounts from the balanceR pool
      for (uint i = 0; i < 2; ++i) {
        vault_.exitPool(
          poolId_,
          address(this),
          payable(address(this)),
          IBVault.ExitPoolRequest({
            assets : asIAsset(p.tokens),
            minAmountsOut : new uint[](p.len), // no limits
            userData : abi.encode(IBVault.ExitKindComposableStable.EXACT_BPT_IN_FOR_ALL_TOKENS_OUT, liquidityAmount),
            toInternalBalance : false
          })
        );
        liquidityAmount = p.tokens[p.bptIndex].balanceOf(address(this));
        if (liquidityAmount < liquidityThreshold || i == 1) {
          break;
        }
        (, p.balances,) = vault_.getPoolTokens(poolId_);
      }

      // now we have amBbXXX tokens; swap them to XXX assets
      uint k;
      for (uint i; i < p.len; i = AppLib.uncheckedInc(i)) {
        if (i == p.bptIndex) continue;

        uint amountIn = p.tokens[i].balanceOf(address(this));
        if (amountIn != 0) {
          amountsOut[k] = swap(
            vault_,
            ILinearPool(address(p.tokens[i])).getPoolId(),
            address(p.tokens[i]),
            ILinearPool(address(p.tokens[i])).getMainToken(),
            amountIn,
            funds
          );
        }
        ++k;
      }
    }

    uint depositorBalance = p.tokens[p.bptIndex].balanceOf(address(this));
    if (depositorBalance > 0) {
      uint k = 0;
      for (uint i; i < p.len; i = AppLib.uncheckedInc(i)) {
        if (i == p.bptIndex) continue;

        // we assume here, that the depositorBalance is small
        // so we can directly swap it to any single asset without changing of pool resources proportions
        amountsOut[k] += _convertSmallBptRemainder(vault_, poolId_, p, funds, depositorBalance, i);
        break;
      }
    }

    return amountsOut;
  }

  /// @notice convert remained SMALL amount of bpt => am-bpt => main token of the am-bpt
  /// @return amountOut Received amount of am-bpt's main token
  function _convertSmallBptRemainder(
    IBVault vault_,
    bytes32 poolId_,
    DepositorLocal memory p,
    IBVault.FundManagement memory funds,
    uint bptAmountIn_,
    uint indexTargetAmBpt_
  ) internal returns (uint amountOut) {
    uint amountAmBpt = BalancerLogicLib.swap(
      vault_,
      poolId_,
      address(p.tokens[p.bptIndex]),
      address(p.tokens[indexTargetAmBpt_]),
      bptAmountIn_,
      funds
    );
    amountOut = swap(
      vault_,
      ILinearPool(address(p.tokens[indexTargetAmBpt_])).getPoolId(),
      address(p.tokens[indexTargetAmBpt_]),
      ILinearPool(address(p.tokens[indexTargetAmBpt_])).getMainToken(),
      amountAmBpt,
      funds
    );
  }

  /// @notice Quotes output for given amount of LP-tokens from the pool.
  /// @return amountsOut Result amounts of underlying (DAI, USDC..) that will be received from BalanceR
  ///         The order of assets is the same as in getPoolTokens, but there is no pool-bpt
  function depositorQuoteExit(
    IBVault vault_,
    IBalancerHelper helper_,
    bytes32 poolId_,
    uint liquidityAmount_
  ) external returns (
    uint[] memory amountsOut
  ) {
    DepositorLocal memory p;

    p.bptIndex = IComposableStablePool(getPoolAddress(poolId_)).getBptIndex();
    (p.tokens, p.balances,) = vault_.getPoolTokens(poolId_);
    p.len = p.tokens.length;

    (, uint[] memory amountsBpt) = helper_.queryExit(
      poolId_,
      address(this),
      payable(address(this)),
      IBVault.ExitPoolRequest({
        assets : asIAsset(p.tokens),
        minAmountsOut : new uint[](p.len), // no limits
        userData : abi.encode(
          IBVault.ExitKindComposableStable.EXACT_BPT_IN_FOR_ALL_TOKENS_OUT,
          liquidityAmount_
        ),
        toInternalBalance : false
      })
    );

    uint k;
    amountsOut = new uint[](p.len - 1);
    for (uint i = 0; i < p.len; i = AppLib.uncheckedInc(i)) {
      if (i == p.bptIndex) continue;
      ILinearPool linearPool = ILinearPool(address(p.tokens[i]));
      amountsOut[k] = _calcLinearMainOutPerBptIn(vault_, linearPool, amountsBpt[i]);
      ++k;
    }
  }

  /// @notice Swap given {amountIn_} of {assetIn_} to {assetOut_} using the given BalanceR pool
  function swap(
    IBVault vault_,
    bytes32 poolId_,
    address assetIn_,
    address assetOut_,
    uint amountIn_,
    IBVault.FundManagement memory funds_
  ) internal returns (uint amountOut) {
    uint balanceBefore = IERC20(assetOut_).balanceOf(address(this));

    IERC20(assetIn_).approve(address(vault_), amountIn_);
    vault_.swap(
      IBVault.SingleSwap({
    poolId : poolId_,
    kind : IBVault.SwapKind.GIVEN_IN,
    assetIn : IAsset(assetIn_),
    assetOut : IAsset(assetOut_),
    amount : amountIn_,
    userData : bytes("")
    }),
      funds_,
      1,
      block.timestamp
    );

    // we assume here, that the balance cannot be decreased
    amountOut = IERC20(assetOut_).balanceOf(address(this)) - balanceBefore;
  }

  /////////////////////////////////////////////////////////////////////
  ///             Rewards
  /////////////////////////////////////////////////////////////////////

  function depositorClaimRewards(IBalancerGauge gauge_, address[] memory tokens_, address[] memory rewardTokens_) external returns (
    address[] memory tokensOut,
    uint[] memory amountsOut,
    uint[] memory depositorBalancesBefore
  ) {
    uint tokensLen = tokens_.length;
    uint rewardTokensLen = rewardTokens_.length;

    tokensOut = new address[](rewardTokensLen);
    amountsOut = new uint[](rewardTokensLen);
    depositorBalancesBefore = new uint[](tokensLen);

    for (uint i; i < tokensLen; i = AppLib.uncheckedInc(i)) {
      depositorBalancesBefore[i] = IERC20(tokens_[i]).balanceOf(address(this));
    }

    for (uint i; i < rewardTokensLen; i = AppLib.uncheckedInc(i)) {
      tokensOut[i] = rewardTokens_[i];

      // temporary store current reward balance
      amountsOut[i] = IERC20(rewardTokens_[i]).balanceOf(address(this));
    }

    gauge_.claim_rewards();

    for (uint i; i < rewardTokensLen; i = AppLib.uncheckedInc(i)) {
      amountsOut[i] = IERC20(rewardTokens_[i]).balanceOf(address(this)) - amountsOut[i];
    }

    (tokensOut, amountsOut) = TokenAmountsLib.filterZeroAmounts(tokensOut, amountsOut);
  }

  /////////////////////////////////////////////////////////////////////
  ///             Utils
  /////////////////////////////////////////////////////////////////////

  function createSpecificName(address pool_) external view returns (string memory) {
    return string(abi.encodePacked("Balancer ", IERC20Metadata(pool_).symbol()));
  }

  /// @dev Returns the address of a Pool's contract.
  ///      Due to how Pool IDs are created, this is done with no storage accesses and costs little gas.
  function getPoolAddress(bytes32 id) internal pure returns (address) {
    // 12 byte logical shift left to remove the nonce and specialization setting. We don't need to mask,
    // since the logical shift already sets the upper bits to zero.
    return address(uint160(uint(id) >> (12 * 8)));
  }

  /// @dev see balancer-labs, ERC20Helpers.sol
  function asIAsset(IERC20[] memory tokens) internal pure returns (IAsset[] memory assets) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      assets := tokens
    }
  }

  /////////////////////////////////////////////////////////////////////
  ///             Linear pool quote swap math logic
  /////////////////////////////////////////////////////////////////////

  /// @dev This logic is needed for hardworks in conditions of lack of funds in linear pools.
  ///      The lack of funds in linear pools is a typical situation caused by pool rebalancing after deposits from the strategy.
  ///      Main tokens are leaving linear pools to mint wrapped tokens.
  function _calcLinearMainOutPerBptIn(IBVault vault, ILinearPool pool, uint amount) internal view returns (uint) {
    (uint lowerTarget, uint upperTarget) = pool.getTargets();
    LinearPoolParams memory params = LinearPoolParams(pool.getSwapFeePercentage(), lowerTarget, upperTarget);
    (,uint[] memory balances,) = vault.getPoolTokens(pool.getPoolId());
    uint[] memory scalingFactors = pool.getScalingFactors();
    _upscaleArray(balances, scalingFactors);
    amount *= scalingFactors[0] / 1e18;
    uint mainIndex = pool.getMainIndex();
    uint mainBalance = balances[mainIndex];
    uint bptSupply = pool.totalSupply() - balances[0];
    uint previousNominalMain = _toNominal(mainBalance, params);
    uint invariant = previousNominalMain + balances[pool.getWrappedIndex()];
    uint deltaNominalMain = invariant * amount / bptSupply;
    uint afterNominalMain = previousNominalMain > deltaNominalMain ? previousNominalMain - deltaNominalMain : 0;
    uint newMainBalance = _fromNominal(afterNominalMain, params);
    return (mainBalance - newMainBalance) * 1e18 / scalingFactors[mainIndex];
  }

  function _toNominal(uint real, LinearPoolParams memory params) internal pure returns (uint) {
    if (real < params.lowerTarget) {
      uint fees = (params.lowerTarget - real) * params.fee / 1e18;
      return real - fees;
    } else if (real <= params.upperTarget) {
      return real;
    } else {
      uint fees = (real - params.upperTarget) * params.fee / 1e18;
      return real - fees;
    }
  }

  function _fromNominal(uint nominal, LinearPoolParams memory params) internal pure returns (uint) {
    if (nominal < params.lowerTarget) {
      return (nominal + (params.fee * params.lowerTarget / 1e18)) * 1e18 / (1e18 + params.fee);
    } else if (nominal <= params.upperTarget) {
      return nominal;
    } else {
      return (nominal - (params.fee * params.upperTarget / 1e18)) * 1e18/ (1e18 - params.fee);
    }
  }

  function _upscaleArray(uint[] memory amounts, uint[] memory scalingFactors) internal pure {
    uint length = amounts.length;
    for (uint i; i < length; ++i) {
      amounts[i] = amounts[i] * scalingFactors[i] / 1e18;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@tetu_io/tetu-contracts-v2/contracts/strategy/StrategyBaseV2.sol";
import "@tetu_io/tetu-converter/contracts/interfaces/ITetuConverterCallback.sol";
import "./ConverterStrategyBaseLib.sol";
import "./ConverterStrategyBaseLib2.sol";
import "./DepositorBase.sol";
/////////////////////////////////////////////////////////////////////
///                        TERMS
///  Main asset == underlying: the asset deposited to the vault by users
///  Secondary assets: all assets deposited to the internal pool except the main asset
/////////////////////////////////////////////////////////////////////

/// @title Abstract contract for base Converter strategy functionality
/// @notice All depositor assets must be correlated (ie USDC/USDT/DAI)
/// @author bogdoslav, dvpublic
abstract contract ConverterStrategyBase is ITetuConverterCallback, DepositorBase, StrategyBaseV2 {
  using SafeERC20 for IERC20;

  /////////////////////////////////////////////////////////////////////
  //region DATA TYPES
  /////////////////////////////////////////////////////////////////////

  struct WithdrawUniversalLocal {
    bool all;
    uint[] reservesBeforeWithdraw;
    uint totalSupplyBeforeWithdraw;
    uint depositorLiquidity;
    uint liquidityAmountToWithdraw;
    uint assetPrice;
    uint[] amountsToConvert;
    uint expectedTotalMainAssetAmount;
    uint[] expectedMainAssetAmounts;
    uint investedAssetsAfterWithdraw;
    uint balanceAfterWithdraw;
    address[] tokens;
    address asset;
    uint indexAsset;
    uint balanceBefore;
    uint[] withdrawnAmounts;
    ITetuConverter converter;
  }
  //endregion DATA TYPES

  /////////////////////////////////////////////////////////////////////
  //region CONSTANTS
  /////////////////////////////////////////////////////////////////////

  /// @dev Version of this contract. Adjust manually on each code modification.
  string public constant CONVERTER_STRATEGY_BASE_VERSION = "1.2.0";

  /// @notice 1% gap to cover possible liquidation inefficiency
  /// @dev We assume that: conversion-result-calculated-by-prices - liquidation-result <= the-gap
  uint internal constant GAP_CONVERSION = 1_000;
  uint internal constant DENOMINATOR = 100_000;
  //endregion CONSTANTS

  /////////////////////////////////////////////////////////////////////
  //region VARIABLES
  //                Keep names and ordering!
  // Add only in the bottom and don't forget to decrease gap variable
  /////////////////////////////////////////////////////////////////////

  /// @dev Amount of underlying assets invested to the pool.
  uint internal _investedAssets;

  /// @dev Linked Tetu Converter
  ITetuConverter public converter;

  /// @notice Minimum token amounts that can be liquidated
  mapping(address => uint) public liquidationThresholds;

  /// @notice Percent of asset amount that can be not invested, it's allowed to just keep it on balance
  ///         decimals = {DENOMINATOR}
  /// @dev We need this threshold to avoid numerous conversions of small amounts
  uint public reinvestThresholdPercent;

  /// @notice Ratio to split performance fee on toPerf + toInsurance, [0..100_000]
  ///         100_000 - send full amount toPerf, 0 - send full amount toInsurance.
  uint public performanceFeeRatio;
  //endregion VARIABLES

  /////////////////////////////////////////////////////////////////////
  //region Events
  /////////////////////////////////////////////////////////////////////
  event OnDepositorEnter(uint[] amounts, uint[] consumedAmounts);
  event OnDepositorExit(uint liquidityAmount, uint[] withdrawnAmounts);
  event OnDepositorEmergencyExit(uint[] withdrawnAmounts);
  event OnHardWorkEarnedLost(
    uint investedAssetsNewPrices,
    uint earnedByPrices,
    uint earnedHandleRewards,
    uint lostHandleRewards,
    uint earnedDeposit,
    uint lostDeposit
  );

  /// @notice Recycle was made
  /// @param rewardTokens Full list of reward tokens received from tetuConverter and depositor
  /// @param amountsToForward Amounts to be sent to forwarder
  event Recycle(
    address[] rewardTokens,
    uint[] amountsToForward,
    uint toPerf,
    uint toInsurance
  );
  //endregion Events

  /////////////////////////////////////////////////////////////////////
  //region Initialization and configuration
  /////////////////////////////////////////////////////////////////////

  /// @notice Initialize contract after setup it as proxy implementation
  function __ConverterStrategyBase_init(
    address controller_,
    address splitter_,
    address converter_
  ) internal onlyInitializing {
    __StrategyBase_init(controller_, splitter_);
    converter = ITetuConverter(converter_);

    // 1% by default
    reinvestThresholdPercent = DENOMINATOR / 100;
    emit ConverterStrategyBaseLib2.ReinvestThresholdPercentChanged(DENOMINATOR / 100);
  }

  function setLiquidationThreshold(address token, uint amount) external {
    ConverterStrategyBaseLib2.checkLiquidationThresholdChanged(controller(), token, amount);
    liquidationThresholds[token] = amount;
  }

  /// @param percent_ New value of the percent, decimals = {REINVEST_THRESHOLD_PERCENT_DENOMINATOR}
  function setReinvestThresholdPercent(uint percent_) external {
    ConverterStrategyBaseLib2.checkReinvestThresholdPercentChanged(controller(), percent_);
    reinvestThresholdPercent = percent_;
  }

  /// @notice [0..100_000], 100_000 - send full amount toPerf, 0 - send full amount toInsurance.
  function setPerformanceFeeRatio(uint ratio_) external {
    ConverterStrategyBaseLib2.checkPerformanceFeeRatioChanged(controller(), ratio_);
    performanceFeeRatio = ratio_;
  }
  //endregion Initialization and configuration

  /////////////////////////////////////////////////////////////////////
  //region Deposit to the pool
  /////////////////////////////////////////////////////////////////////

  /// @notice Amount of underlying assets converted to pool assets and invested to the pool.
  function investedAssets() override public view virtual returns (uint) {
    return _investedAssets;
  }

  /// @notice Deposit given amount to the pool.
  function _depositToPool(uint amount_, bool updateTotalAssetsBeforeInvest_) override internal virtual returns (
    uint strategyLoss
  ){
    (uint updatedInvestedAssets, uint earnedByPrices) = _fixPriceChanges(updateTotalAssetsBeforeInvest_);
    (strategyLoss,) = _depositToPoolUniversal(amount_, earnedByPrices, updatedInvestedAssets);
  }

  /// @notice Deposit {amount_} to the pool, send {earnedByPrices_} to insurance.
  ///         totalAsset will decrease on earnedByPrices_ and sharePrice won't change after all recalculations.
  /// @dev We need to deposit {amount_} and withdraw {earnedByPrices_} here
  /// @param amount_ Amount of underlying to be deposited
  /// @param earnedByPrices_ Profit received because of price changing
  /// @param investedAssets_ Invested assets value calculated with updated prices
  /// @return strategyLoss Loss happened on the depositing. It doesn't include any price-changing losses
  /// @return amountSentToInsurance Price-changing-profit that was sent to the insurance
  function _depositToPoolUniversal(uint amount_, uint earnedByPrices_, uint investedAssets_) internal virtual returns (
    uint strategyLoss,
    uint amountSentToInsurance
  ){
    address _asset = asset;

    uint amountToDeposit = amount_ > earnedByPrices_
      ? amount_ - earnedByPrices_
      : 0;

    // skip deposit for small amounts
    if (amountToDeposit > reinvestThresholdPercent * investedAssets_ / DENOMINATOR) {
      if (earnedByPrices_ != 0) {
        amountSentToInsurance = ConverterStrategyBaseLib2.sendToInsurance(
          _asset,
          earnedByPrices_,
          splitter,
          investedAssets_ + AppLib.balance(_asset)
        );
      }
      uint balanceBefore = AppLib.balance(_asset);

      (address[] memory tokens, uint indexAsset) = _getTokens(asset);

      // prepare array of amounts ready to deposit, borrow missed amounts
      uint[] memory amounts = _beforeDeposit(converter, amountToDeposit, tokens, indexAsset);

      // make deposit, actually consumed amounts can be different from the desired amounts
      (uint[] memory consumedAmounts,) = _depositorEnter(amounts);
      emit OnDepositorEnter(amounts, consumedAmounts);

      // update _investedAssets with new deposited amount
      uint updatedInvestedAssetsAfterDeposit = _updateInvestedAssets();
      // after deposit some asset can exist
      uint balanceAfter = AppLib.balance(_asset);
      // we need to compensate difference if during deposit we lost some assets
      if ((updatedInvestedAssetsAfterDeposit + balanceAfter) < (investedAssets_ + balanceBefore)) {
        strategyLoss = (investedAssets_ + balanceBefore) - (updatedInvestedAssetsAfterDeposit + balanceAfter);
      }
    } else if (earnedByPrices_ != 0) {
      // we just skip check of expectedWithdrewUSD here
      uint balance = AppLib.balance(_asset);
      if (balance < earnedByPrices_) {
        (/* expectedWithdrewUSD */,, strategyLoss, amountSentToInsurance) = _withdrawUniversal(0, earnedByPrices_, investedAssets_);
      } else {
        amountSentToInsurance = ConverterStrategyBaseLib2.sendToInsurance(
          _asset,
          earnedByPrices_,
          splitter,
          investedAssets_ + balance
        );
      }
    }

    return (strategyLoss, amountSentToInsurance);
  }
  //endregion Deposit to the pool

  /////////////////////////////////////////////////////////////////////
  //region Convert amounts before deposit
  /////////////////////////////////////////////////////////////////////

  /// @notice Prepare {tokenAmounts} to be passed to depositorEnter
  /// @dev Override this function to customize entry kind
  /// @param amount_ The amount of main asset that should be invested
  /// @param tokens_ Results of _depositorPoolAssets() call (list of depositor's asset in proper order)
  /// @param indexAsset_ Index of main {asset} in {tokens}
  /// @return tokenAmounts Amounts of depositor's assets ready to invest (this array can be passed to depositorEnter)
  function _beforeDeposit(
    ITetuConverter tetuConverter_,
    uint amount_,
    address[] memory tokens_,
    uint indexAsset_
  ) internal virtual returns (
    uint[] memory tokenAmounts
  ) {
    // calculate required collaterals for each token and temporary save them to tokenAmounts
    (uint[] memory weights, uint totalWeight) = _depositorPoolWeights();
    // temporary save collateral to tokensAmounts
    tokenAmounts = ConverterStrategyBaseLib2.getCollaterals(
      amount_,
      tokens_,
      weights,
      totalWeight,
      indexAsset_,
      IPriceOracle(IConverterController(tetuConverter_.controller()).priceOracle())
    );

    // make borrow and save amounts of tokens available for deposit to tokenAmounts, zero result amounts are possible
    tokenAmounts = ConverterStrategyBaseLib.getTokenAmounts(
      tetuConverter_,
      tokens_,
      indexAsset_,
      tokenAmounts,
      liquidationThresholds[tokens_[indexAsset_]]
    );
  }
  //endregion Convert amounts before deposit

  /////////////////////////////////////////////////////////////////////
  //region Withdraw from the pool
  /////////////////////////////////////////////////////////////////////

  function _beforeWithdraw(uint /*amount*/) internal virtual {
    // do nothing
  }

  /// @notice Withdraw given amount from the pool.
  /// @param amount Amount to be withdrawn in terms of the asset in addition to the exist balance.
  /// @return expectedWithdrewUSD The value that we should receive after withdrawing (in USD, decimals of the {asset})
  /// @return assetPrice Price of the {asset} from the price oracle
  /// @return strategyLoss Loss should be covered from Insurance
  function _withdrawFromPool(uint amount) override internal virtual returns (
    uint expectedWithdrewUSD,
    uint assetPrice,
    uint strategyLoss
  ) {
    // calculate profit/loss because of price changes, try to compensate the loss from the insurance
    (uint investedAssetsNewPrices, uint earnedByPrices) = _fixPriceChanges(true);
    (expectedWithdrewUSD, assetPrice, strategyLoss,) = _withdrawUniversal(amount, earnedByPrices, investedAssetsNewPrices);
  }

  /// @notice Withdraw all from the pool.
  /// @return expectedWithdrewUSD The value that we should receive after withdrawing
  /// @return assetPrice Price of the {asset} taken from the price oracle
  /// @return strategyLoss Loss should be covered from Insurance
  function _withdrawAllFromPool() override internal virtual returns (
    uint expectedWithdrewUSD,
    uint assetPrice,
    uint strategyLoss
  ) {
    return _withdrawFromPool(type(uint).max);
  }

  /// @param amount Amount to be trying to withdrawn. Max uint means attempt to withdraw all possible invested assets.
  /// @param earnedByPrices_ Additional amount that should be withdrawn and send to the insurance
  /// @param investedAssets_ Value of invested assets recalculated using current prices
  /// @return expectedWithdrewUSD The value that we should receive after withdrawing in terms of USD value of each asset in the pool
  /// @return __assetPrice Price of the {asset} taken from the price oracle
  /// @return strategyLoss Loss before withdrawing: [new-investedAssets - old-investedAssets]
  /// @return amountSentToInsurance Actual amount of underlying sent to the insurance
  function _withdrawUniversal(uint amount, uint earnedByPrices_, uint investedAssets_) internal returns (
    uint expectedWithdrewUSD,
    uint __assetPrice,
    uint strategyLoss,
    uint amountSentToInsurance
  ) {
    _beforeWithdraw(amount);

    WithdrawUniversalLocal memory v;
    v.all = amount == type(uint).max;
    strategyLoss = 0;

    if ((v.all || amount + earnedByPrices_ != 0) && investedAssets_ != 0) {

      // --- init variables ---
      v.tokens = _depositorPoolAssets();
      v.asset = asset;
      v.converter = converter;
      v.indexAsset = ConverterStrategyBaseLib.getAssetIndex(v.tokens, v.asset);
      v.balanceBefore = AppLib.balance(v.asset);

      v.reservesBeforeWithdraw = _depositorPoolReserves();
      v.totalSupplyBeforeWithdraw = _depositorTotalSupply();
      v.depositorLiquidity = _depositorLiquidity();
      v.assetPrice = ConverterStrategyBaseLib.getAssetPriceFromConverter(v.converter, v.asset);
      // -----------------------

      // calculate how much liquidity we need to withdraw for getting the requested amount
      (v.liquidityAmountToWithdraw, v.amountsToConvert) = ConverterStrategyBaseLib2.getLiquidityAmount(
        v.all ? 0 : amount + earnedByPrices_,
        address(this),
        v.tokens,
        v.indexAsset,
        v.converter,
        investedAssets_,
        v.depositorLiquidity
      );

      if (v.liquidityAmountToWithdraw != 0) {

        // =============== WITHDRAW =====================
        // make withdraw
        v.withdrawnAmounts = _depositorExit(v.liquidityAmountToWithdraw);
        // the depositor is able to use less liquidity than it was asked, i.e. Balancer-depositor leaves some BPT unused
        // use what exactly was withdrew instead of the expectation
        // assume that liquidity cannot increase in _depositorExit
        v.liquidityAmountToWithdraw = v.depositorLiquidity - _depositorLiquidity();
        emit OnDepositorExit(v.liquidityAmountToWithdraw, v.withdrawnAmounts);
        // ==============================================

        // we need to call expectation after withdraw for calculate it based on the real liquidity amount that was withdrew
        // it should be called BEFORE the converter will touch our positions coz we need to call quote the estimations
        // amountsToConvert should contains amounts was withdrawn from the pool and amounts received from the converter
        (v.expectedMainAssetAmounts, v.amountsToConvert) = ConverterStrategyBaseLib.postWithdrawActions(
          v.converter,
          v.tokens,
          v.indexAsset,
          v.reservesBeforeWithdraw,
          v.liquidityAmountToWithdraw,
          v.totalSupplyBeforeWithdraw,
          v.amountsToConvert,
          v.withdrawnAmounts
        );
      } else {
        // we don't need to withdraw any amounts from the pool, available converted amounts are enough for us
        v.expectedMainAssetAmounts = ConverterStrategyBaseLib.postWithdrawActionsEmpty(
          v.converter,
          v.tokens,
          v.indexAsset,
          v.amountsToConvert
        );
      }

      // convert amounts to main asset
      // it is safe to use amountsToConvert from expectation - we will try to repay only necessary amounts
      v.expectedTotalMainAssetAmount += ConverterStrategyBaseLib.makeRequestedAmount(
        v.tokens,
        v.indexAsset,
        v.amountsToConvert,
        v.converter,
        _getLiquidator(controller()),
        v.all ? amount : amount + earnedByPrices_,
        v.expectedMainAssetAmounts,
        liquidationThresholds
      );

      if (earnedByPrices_ != 0) {
        amountSentToInsurance = ConverterStrategyBaseLib2.sendToInsurance(
          v.asset,
          earnedByPrices_,
          splitter,
          investedAssets_ + v.balanceBefore
        );
      }

      v.investedAssetsAfterWithdraw = _updateInvestedAssets();
      v.balanceAfterWithdraw = AppLib.balance(v.asset);

      // we need to compensate difference if during withdraw we lost some assets
      if ((v.investedAssetsAfterWithdraw + v.balanceAfterWithdraw + earnedByPrices_) < (investedAssets_ + v.balanceBefore)) {
        strategyLoss += (investedAssets_ + v.balanceBefore) - (v.investedAssetsAfterWithdraw + v.balanceAfterWithdraw + earnedByPrices_);
      }

      return (
        v.expectedTotalMainAssetAmount * v.assetPrice / 1e18,
        v.assetPrice,
        strategyLoss,
        amountSentToInsurance
      );
    }
    return (0, 0, 0, 0);
  }

  /// @notice If pool supports emergency withdraw need to call it for emergencyExit()
  function _emergencyExitFromPool() override internal virtual {
    uint[] memory withdrawnAmounts = _depositorEmergencyExit();
    emit OnDepositorEmergencyExit(withdrawnAmounts);

    // convert amounts to main asset
    (address[] memory tokens, uint indexAsset) = _getTokens(asset);
    ConverterStrategyBaseLib.closePositionsToGetAmount(
      converter,
      _getLiquidator(controller()),
      indexAsset,
      liquidationThresholds,
      type(uint).max,
      tokens
    );

    // adjust _investedAssets
    _updateInvestedAssets();
  }
  //endregion Withdraw from the pool

  /////////////////////////////////////////////////////////////////////
  //region Claim rewards
  /////////////////////////////////////////////////////////////////////

  /// @notice Claim all possible rewards.
  function _claim() override internal virtual returns (address[] memory rewardTokensOut, uint[] memory amountsOut) {
    // get rewards from the Depositor
    (address[] memory rewardTokens, uint[] memory rewardAmounts, uint[] memory balancesBefore) = _depositorClaimRewards();

    (rewardTokensOut, amountsOut) = ConverterStrategyBaseLib2.claimConverterRewards(
      converter,
      _depositorPoolAssets(),
      rewardTokens,
      rewardAmounts,
      balancesBefore
    );
  }

  /// @dev Call recycle process and send tokens to forwarder.
  ///      Need to be separated from the claim process - the claim can be called by operator for other purposes.
  function _rewardsLiquidation(address[] memory rewardTokens, uint[] memory amounts) internal {
    uint len = rewardTokens.length;
    if (len > 0) {
      uint[] memory amountsToForward = _recycle(rewardTokens, amounts);

      // send forwarder-part of the rewards to the forwarder
      ConverterStrategyBaseLib2.sendTokensToForwarder(controller(), splitter, rewardTokens, amountsToForward);
    }
  }

  /// @notice Recycle the amounts: liquidate a part of each amount, send the other part to the forwarder.
  /// We have two kinds of rewards:
  /// 1) rewards in depositor's assets (the assets returned by _depositorPoolAssets)
  /// 2) any other rewards
  /// All received rewards divided on three parts: to performance receiver+insurance, to forwarder, to compound
  ///   Compound-part of Rewards-2 can be liquidated
  ///   Compound part of Rewards-1 should be just left on the balance
  ///   Performance amounts should be liquidate, result underlying should be sent to performance receiver and insurance.
  ///   All forwarder-parts are returned in amountsToForward and should be transferred to the forwarder outside.
  /// @dev {_recycle} is implemented as separate (inline) function to simplify unit testing
  /// @param rewardTokens_ Full list of reward tokens received from tetuConverter and depositor
  /// @param rewardAmounts_ Amounts of {rewardTokens_}; we assume, there are no zero amounts here
  /// @return amountsToForward Amounts to be sent to forwarder
  function _recycle(address[] memory rewardTokens_, uint[] memory rewardAmounts_) internal returns (
    uint[] memory amountsToForward
  ) {
    address _asset = asset; // save gas

    uint amountPerf; // total amount for the performance receiver and insurance
    (amountsToForward, amountPerf) = ConverterStrategyBaseLib.recycle(
      converter,
      _asset,
      compoundRatio,
      _depositorPoolAssets(),
      _getLiquidator(controller()),
      liquidationThresholds,
      rewardTokens_,
      rewardAmounts_,
      performanceFee
    );

    // send performance-part of the underlying to the performance receiver and insurance
    (uint toPerf, uint toInsurance) = ConverterStrategyBaseLib2.sendPerformanceFee(
      _asset,
      amountPerf,
      splitter,
      performanceReceiver,
      performanceFeeRatio
    );

    emit Recycle(rewardTokens_, amountsToForward, toPerf, toInsurance);
  }
  //endregion Claim rewards

  /////////////////////////////////////////////////////////////////////
  //region Hardwork
  /////////////////////////////////////////////////////////////////////

  /// @notice A virtual handler to make any action before hardwork
  function _preHardWork(bool reInvest) internal virtual {}

  /// @notice A virtual handler to make any action after hardwork
  function _postHardWork() internal virtual {}

  /// @notice Is strategy ready to hard work
  function isReadyToHardWork() override external virtual view returns (bool) {
    // check claimable amounts and compare with thresholds
    return true;
  }

  /// @notice Do hard work with reinvesting
  /// @return earned Earned amount in terms of {asset}
  /// @return lost Lost amount in terms of {asset}
  function doHardWork() override public returns (uint earned, uint lost) {
    require(msg.sender == splitter, StrategyLib.DENIED);
    return _doHardWork(true);
  }

  /// @notice Claim rewards, do _processClaims() after claiming, calculate earned and lost amounts
  function _handleRewards() internal virtual returns (uint earned, uint lost, uint assetBalanceAfterClaim);

  /// @param reInvest Deposit to pool all available amount if it's greater than the threshold
  /// @return earned Earned amount in terms of {asset}
  /// @return lost Lost amount in terms of {asset}
  function _doHardWork(bool reInvest) internal returns (uint earned, uint lost) {
    // ATTENTION! splitter will not cover the loss if it is lower than profit
    (uint investedAssetsNewPrices, uint earnedByPrices) = _fixPriceChanges(true);

    _preHardWork(reInvest);

    // claim rewards and get current asset balance
    uint assetBalance;
    (earned, lost, assetBalance) = _handleRewards();

    // re-invest income
    (, uint amountSentToInsurance) = _depositToPoolUniversal(
      reInvest && assetBalance > reinvestThresholdPercent * investedAssetsNewPrices / DENOMINATOR
        ? assetBalance
        : 0,
      earnedByPrices,
      investedAssetsNewPrices
    );
    (uint earned2, uint lost2) = ConverterStrategyBaseLib.registerIncome(
      investedAssetsNewPrices + assetBalance, // assets in use before deposit
      _investedAssets + AppLib.balance(asset) + amountSentToInsurance // assets in use after deposit
    );

    _postHardWork();

    emit OnHardWorkEarnedLost(investedAssetsNewPrices, earnedByPrices, earned, lost, earned2, lost2);
    return (earned + earned2, lost + lost2);
  }
  //endregion Hardwork

  /////////////////////////////////////////////////////////////////////
  //region InvestedAssets Calculations
  /////////////////////////////////////////////////////////////////////

  /// @notice Updates cached _investedAssets to actual value
  /// @dev Should be called after deposit / withdraw / claim; virtual - for ut
  function _updateInvestedAssets() internal returns (uint investedAssetsOut) {
    investedAssetsOut = _calcInvestedAssets();
    _investedAssets = investedAssetsOut;
  }

  /// @notice Calculate amount we will receive when we withdraw all from pool
  /// @dev This is writable function because we need to update current balances in the internal protocols.
  /// @return Invested asset amount under control (in terms of {asset})
  function _calcInvestedAssets() internal returns (uint) {
    (address[] memory tokens, uint indexAsset) = _getTokens(asset);
    return ConverterStrategyBaseLib.calcInvestedAssets(
      tokens,
      // quote exit should check zero liquidity
      _depositorQuoteExit(_depositorLiquidity()),
      indexAsset,
      converter
    );
  }

  function calcInvestedAssets() external returns (uint) {
    StrategyLib.onlyOperators(controller());
    return _calcInvestedAssets();
  }

  /// @notice Calculate profit/loss happened because of price changing. Try to cover the loss, send the profit to the insurance
  /// @param updateInvestedAssetsAmount_ If false - just return current value of invested assets
  /// @return investedAssetsOut Updated value of {_investedAssets}
  /// @return earnedOut Profit that was received because of price changes. It should be sent back to insurance.
  ///                   It's to dangerous to get this to try to get this amount here because of the problem "borrow-repay is not allowed in a single block"
  ///                   So, we need to handle it in the caller code.
  function _fixPriceChanges(bool updateInvestedAssetsAmount_) internal returns (uint investedAssetsOut, uint earnedOut) {
    if (updateInvestedAssetsAmount_) {
      uint investedAssetsBefore = _investedAssets;
      investedAssetsOut = _updateInvestedAssets();
      earnedOut = ConverterStrategyBaseLib.coverPossibleStrategyLoss(investedAssetsBefore, investedAssetsOut, splitter);
    } else {
      investedAssetsOut = _investedAssets;
      earnedOut = 0;
    }
  }
  //endregion InvestedAssets Calculations

  /////////////////////////////////////////////////////////////////////
  //region ITetuConverterCallback
  /////////////////////////////////////////////////////////////////////

  /// @notice Converters asks to send some amount back.
  /// @param theAsset_ Required asset (either collateral or borrow)
  /// @param amount_ Required amount of the {theAsset_}
  /// @return amountOut Amount sent to balance of TetuConverter, amountOut <= amount_
  function requirePayAmountBack(address theAsset_, uint amount_) external override returns (uint amountOut) {
    address __converter = address(converter);
    require(msg.sender == __converter, StrategyLib.DENIED);

    // detect index of the target asset
    (address[] memory tokens, uint indexTheAsset) = _getTokens(theAsset_);
    // get amount of target asset available to be sent
    uint balance = AppLib.balance(theAsset_);

    // withdraw from the pool if not enough
    if (balance < amount_) {
      // the strategy doesn't have enough target asset on balance
      // withdraw all from the pool but don't convert assets to underlying
      uint liquidity = _depositorLiquidity();
      if (liquidity != 0) {
        uint[] memory withdrawnAmounts = _depositorExit(liquidity);
        emit OnDepositorExit(liquidity, withdrawnAmounts);
      }
    }

    amountOut = ConverterStrategyBaseLib.swapToGivenAmountAndSendToConverter(
      amount_,
      indexTheAsset,
      tokens,
      __converter,
      controller(),
      asset,
      liquidationThresholds
    );

    // update invested assets anyway, even if we suppose it will be called in other places
    _updateInvestedAssets();
  }

  /// @notice TetuConverter calls this function when it sends any amount to user's balance
  /// @param assets_ Any asset sent to the balance, i.e. inside repayTheBorrow
  /// @param amounts_ Amount of {asset_} that has been sent to the user's balance
  function onTransferAmounts(address[] memory assets_, uint[] memory amounts_) external override {
    require(msg.sender == address(converter), StrategyLib.DENIED);

    uint len = assets_.length;
    require(len == amounts_.length, AppErrors.INCORRECT_LENGTHS);

    // TetuConverter is able two call this function in two cases:
    // 1) rebalancing (the health factor of some borrow is too low)
    // 2) forcible closing of the borrow
    // In both cases we update invested assets value here
    // and avoid fixing any related losses in hardwork
    _updateInvestedAssets();
  }
  //endregion ITetuConverterCallback

  /////////////////////////////////////////////////////////////////////
  //region Others
  /////////////////////////////////////////////////////////////////////

  /// @notice Unlimited capacity by default
  function capacity() external virtual view returns (uint) {
    return 2 ** 255;
    // almost same as type(uint).max but more gas efficient
  }

  function _getTokens(address asset_) internal view returns (address[] memory tokens, uint indexAsset) {
    tokens = _depositorPoolAssets();
    indexAsset = ConverterStrategyBaseLib.getAssetIndex(tokens, asset_);
    require(indexAsset != type(uint).max, StrategyLib.WRONG_VALUE);
  }

  function _getLiquidator(address controller_) internal view returns (ITetuLiquidator) {
    return ITetuLiquidator(IController(controller_).liquidator());
  }
  //endregion Others


  /// @dev This empty reserved space is put in place to allow future versions to add new
  /// variables without shifting down storage in the inheritance chain.
  /// See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
  uint[50 - 5] private __gap; // 50 - count of variables

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@tetu_io/tetu-contracts-v2/contracts/interfaces/ITetuLiquidator.sol";
import "@tetu_io/tetu-contracts-v2/contracts/interfaces/IForwarder.sol";
import "@tetu_io/tetu-contracts-v2/contracts/interfaces/ITetuVaultV2.sol";
import "@tetu_io/tetu-contracts-v2/contracts/interfaces/ISplitter.sol";
import "@tetu_io/tetu-contracts-v2/contracts/strategy/StrategyLib.sol";
import "@tetu_io/tetu-contracts-v2/contracts/openzeppelin/Math.sol";
import "@tetu_io/tetu-converter/contracts/interfaces/IConverterController.sol";
import "@tetu_io/tetu-converter/contracts/interfaces/IPriceOracle.sol";
import "@tetu_io/tetu-converter/contracts/interfaces/ITetuConverter.sol";
import "../libs/AppErrors.sol";
import "../libs/AppLib.sol";
import "../libs/TokenAmountsLib.sol";
import "../libs/ConverterEntryKinds.sol";

library ConverterStrategyBaseLib {
  using SafeERC20 for IERC20;

  /////////////////////////////////////////////////////////////////////
  //region Data types
  /////////////////////////////////////////////////////////////////////
  /// @notice Local vars for {_recycle}, workaround for stack too deep
  struct RecycleLocalParams {
    /// @notice Compound amount + Performance amount
    uint amountCP;
    /// @notice Amount to compound
    uint amountC;
    /// @notice Amount to send to performance and insurance
    uint amountP;
    /// @notice Amount to forwarder + amount to compound
    uint amountFC;
    address rewardToken;
    uint liquidationThresholdAsset;
    uint len;
    uint receivedAmountOut;
  }

  struct OpenPositionLocal {
    uint entryKind;
    address[] converters;
    uint[] collateralsRequired;
    uint[] amountsToBorrow;
    uint collateral;
    uint amountToBorrow;
  }

  struct OpenPositionEntryKind1Local {
    address[] converters;
    uint[] collateralsRequired;
    uint[] amountsToBorrow;
    uint collateral;
    uint amountToBorrow;
    uint c1;
    uint c3;
    uint ratio;
    uint alpha;
  }

  struct CalcInvestedAssetsLocal {
    uint len;
    uint[] prices;
    uint[] decs;
    uint[] debts;
  }

  struct ConvertAfterWithdrawLocal {
    address asset;
    uint collateral;
    uint spent;
    uint received;
    uint balance;
    uint balanceBefore;
    uint len;
  }

  struct SwapToGivenAmountInputParams {
    uint targetAmount;
    address[] tokens;
    uint indexTargetAsset;
    address underlying;
    uint[] amounts;
    ITetuConverter converter;
    ITetuLiquidator liquidator;
    uint liquidationThresholdForTargetAsset;
    /// @notice Allow to swap more then required (i.e. 1_000 => +1%)
    ///         to avoid additional swap if the swap return amount a bit less than we expected
    uint overswap;
  }

  struct SwapToGivenAmountLocal {
    uint len;
    uint[] availableAmounts;
    uint i;
  }

  struct CloseDebtsForRequiredAmountLocal {
    uint len;
    address asset;
    uint collateral;
    uint spentAmountIn;
    uint receivedAmount;
    uint balance;
    uint[] tokensBalancesBefore;

    uint totalDebt;
    uint totalCollateral;

    /// @notice Cost of $1 in terms of the assets, decimals 18
    uint[] prices;
    /// @notice 10**decimal for the assets
    uint[] decs;

    uint newBalance;
  }
  //endregion Data types

  /////////////////////////////////////////////////////////////////////
  //region Constants
  /////////////////////////////////////////////////////////////////////

  /// @notice approx one month for average block time 2 sec
  uint internal constant _LOAN_PERIOD_IN_BLOCKS = 30 days / 2;
  uint internal constant _REWARD_LIQUIDATION_SLIPPAGE = 5_000; // 5%
  uint internal constant COMPOUND_DENOMINATOR = 100_000;
  uint internal constant DENOMINATOR = 100_000;
  uint internal constant _ASSET_LIQUIDATION_SLIPPAGE = 300;
  uint internal constant PRICE_IMPACT_TOLERANCE = 300;
  /// @notice borrow/collateral amount cannot be less than given number of tokens
  uint internal constant DEFAULT_OPEN_POSITION_AMOUNT_IN_THRESHOLD = 10;
  /// @notice Allow to swap more then required (i.e. 1_000 => +1%) inside {swapToGivenAmount}
  ///         to avoid additional swap if the swap will return amount a bit less than we expected
  uint internal constant OVERSWAP = PRICE_IMPACT_TOLERANCE + _ASSET_LIQUIDATION_SLIPPAGE;
  /// @dev Absolute value for any token
  uint internal constant DEFAULT_LIQUIDATION_THRESHOLD = 100_000;
  /// @notice 1% gap to cover possible liquidation inefficiency
  /// @dev We assume that: conversion-result-calculated-by-prices - liquidation-result <= the-gap
  uint internal constant GAP_CONVERSION = 1_000;
  //endregion Constants

  /////////////////////////////////////////////////////////////////////
  //region Events
  /////////////////////////////////////////////////////////////////////
  /// @notice A borrow was made
  event OpenPosition(
    address converter,
    address collateralAsset,
    uint collateralAmount,
    address borrowAsset,
    uint borrowedAmount,
    address recepient
  );

  /// @notice Some borrow(s) was/were repaid
  event ClosePosition(
    address collateralAsset,
    address borrowAsset,
    uint amountRepay,
    address recepient,
    uint returnedAssetAmountOut,
    uint returnedBorrowAmountOut
  );

  /// @notice A liquidation was made
  event Liquidation(
    address tokenIn,
    address tokenOut,
    uint amountIn,
    uint spentAmountIn,
    uint receivedAmountOut
  );

  event ReturnAssetToConverter(address asset, uint amount);

  event FixPriceChanges(uint investedAssetsBefore, uint investedAssetsOut);
  //endregion Events

  /////////////////////////////////////////////////////////////////////
  //region View functions
  /////////////////////////////////////////////////////////////////////

  /// @notice Get amount of assets that we expect to receive after withdrawing
  ///         ratio = amount-LP-tokens-to-withdraw / total-amount-LP-tokens-in-pool
  /// @param reserves_ Reserves of the {poolAssets_}, same order, same length (we don't check it)
  ///                  The order of tokens should be same as in {_depositorPoolAssets()},
  ///                  one of assets must be {asset_}
  /// @param liquidityAmount_ Amount of LP tokens that we are going to withdraw
  /// @param totalSupply_ Total amount of LP tokens in the depositor
  /// @return withdrawnAmountsOut Expected withdrawn amounts (decimals == decimals of the tokens)
  function getExpectedWithdrawnAmounts(
    uint[] memory reserves_,
    uint liquidityAmount_,
    uint totalSupply_
  ) internal pure returns (
    uint[] memory withdrawnAmountsOut
  ) {
    uint ratio = totalSupply_ == 0
      ? 0
      : (liquidityAmount_ >= totalSupply_
        ? 1e18
        : 1e18 * liquidityAmount_ / totalSupply_
      );

    uint len = reserves_.length;
    withdrawnAmountsOut = new uint[](len);

    if (ratio != 0) {
      for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
        withdrawnAmountsOut[i] = reserves_[i] * ratio / 1e18;
      }
    }
  }

  /// @return prices Asset prices in USD, decimals 18
  /// @return decs 10**decimals
  function _getPricesAndDecs(IPriceOracle priceOracle, address[] memory tokens_, uint len) internal view returns (
    uint[] memory prices,
    uint[] memory decs
  ) {
    prices = new uint[](len);
    decs = new uint[](len);
    {
      for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
        decs[i] = 10 ** IERC20Metadata(tokens_[i]).decimals();
        prices[i] = priceOracle.getAssetPrice(tokens_[i]);
      }
    }
  }

  /// @notice Find index of the given {asset_} in array {tokens_}, return type(uint).max if not found
  function getAssetIndex(address[] memory tokens_, address asset_) internal pure returns (uint) {
    uint len = tokens_.length;
    for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
      if (tokens_[i] == asset_) {
        return i;
      }
    }
    return type(uint).max;
  }
  //endregion View functions

  /////////////////////////////////////////////////////////////////////
  //region Borrow and close positions
  /////////////////////////////////////////////////////////////////////

  /// @notice Make one or several borrow necessary to supply/borrow required {amountIn_} according to {entryData_}
  ///         Max possible collateral should be approved before calling of this function.
  /// @param entryData_ Encoded entry kind and additional params if necessary (set of params depends on the kind)
  ///                   See TetuConverter\EntryKinds.sol\ENTRY_KIND_XXX constants for possible entry kinds
  ///                   0 or empty: Amount of collateral {amountIn_} is fixed, amount of borrow should be max possible.
  /// @param amountIn_ Meaning depends on {entryData_}.
  function openPosition(
    ITetuConverter tetuConverter_,
    bytes memory entryData_,
    address collateralAsset_,
    address borrowAsset_,
    uint amountIn_,
    uint thresholdAmountIn_
  ) external returns (
    uint collateralAmountOut,
    uint borrowedAmountOut
  ) {
    return _openPosition(tetuConverter_, entryData_, collateralAsset_, borrowAsset_, amountIn_, thresholdAmountIn_);
  }

  /// @notice Make one or several borrow necessary to supply/borrow required {amountIn_} according to {entryData_}
  ///         Max possible collateral should be approved before calling of this function.
  /// @param entryData_ Encoded entry kind and additional params if necessary (set of params depends on the kind)
  ///                   See TetuConverter\EntryKinds.sol\ENTRY_KIND_XXX constants for possible entry kinds
  ///                   0 or empty: Amount of collateral {amountIn_} is fixed, amount of borrow should be max possible.
  /// @param amountIn_ Meaning depends on {entryData_}.
  /// @param thresholdAmountIn_ Min value of amountIn allowed for the second and subsequent conversions.
  ///        0 - use default min value
  ///        If amountIn becomes too low, no additional borrows are possible, so
  ///        the rest amountIn is just added to collateral/borrow amount of previous conversion.
  function _openPosition(
    ITetuConverter tetuConverter_,
    bytes memory entryData_,
    address collateralAsset_,
    address borrowAsset_,
    uint amountIn_,
    uint thresholdAmountIn_
  ) internal returns (
    uint collateralAmountOut,
    uint borrowedAmountOut
  ) {
    if (thresholdAmountIn_ == 0) {
      // zero threshold is not allowed because round-issues are possible, see openPosition.dust test
      // we assume here, that it's useless to borrow amount using collateral/borrow amount
      // less than given number of tokens (event for BTC)
      thresholdAmountIn_ = DEFAULT_OPEN_POSITION_AMOUNT_IN_THRESHOLD;
    }
    if (amountIn_ <= thresholdAmountIn_) {
      return (0, 0);
    }

    OpenPositionLocal memory vars;
    // we assume here, that max possible collateral amount is already approved (as it's required by TetuConverter)
    vars.entryKind = ConverterEntryKinds.getEntryKind(entryData_);
    if (vars.entryKind == ConverterEntryKinds.ENTRY_KIND_EXACT_PROPORTION_1) {
      return openPositionEntryKind1(
        tetuConverter_,
        entryData_,
        collateralAsset_,
        borrowAsset_,
        amountIn_,
        thresholdAmountIn_
      );
    } else {
      (vars.converters, vars.collateralsRequired, vars.amountsToBorrow,) = tetuConverter_.findBorrowStrategies(
        entryData_,
        collateralAsset_,
        amountIn_,
        borrowAsset_,
        _LOAN_PERIOD_IN_BLOCKS
      );

      uint len = vars.converters.length;
      if (len > 0) {
        for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
          // we need to approve collateralAmount before the borrow-call but it's already approved, see above comments
          vars.collateral;
          vars.amountToBorrow;
          if (vars.entryKind == ConverterEntryKinds.ENTRY_KIND_EXACT_COLLATERAL_IN_FOR_MAX_BORROW_OUT_0) {
            // we have exact amount of total collateral amount
            // Case ENTRY_KIND_EXACT_PROPORTION_1 is here too because we consider first platform only
            vars.collateral = amountIn_ < vars.collateralsRequired[i]
              ? amountIn_
              : vars.collateralsRequired[i];
            vars.amountToBorrow = amountIn_ < vars.collateralsRequired[i]
              ? vars.amountsToBorrow[i] * amountIn_ / vars.collateralsRequired[i]
              : vars.amountsToBorrow[i];
            amountIn_ -= vars.collateral;
          } else {
            // assume here that entryKind == EntryKinds.ENTRY_KIND_EXACT_BORROW_OUT_FOR_MIN_COLLATERAL_IN_2
            // we have exact amount of total amount-to-borrow
            vars.amountToBorrow = amountIn_ < vars.amountsToBorrow[i]
              ? amountIn_
              : vars.amountsToBorrow[i];
            vars.collateral = amountIn_ < vars.amountsToBorrow[i]
              ? vars.collateralsRequired[i] * amountIn_ / vars.amountsToBorrow[i]
              : vars.collateralsRequired[i];
            amountIn_ -= vars.amountToBorrow;
          }

          if (amountIn_ < thresholdAmountIn_ && amountIn_ != 0) {
            // dust amount is left, just leave it unused
            // we cannot add it to collateral/borrow amounts - there is a risk to exceed max allowed amounts
            amountIn_ = 0;
          }

          if (vars.amountToBorrow != 0) {
            borrowedAmountOut += tetuConverter_.borrow(
              vars.converters[i],
              collateralAsset_,
              vars.collateral,
              borrowAsset_,
              vars.amountToBorrow,
              address(this)
            );
            collateralAmountOut += vars.collateral;
            emit OpenPosition(
              vars.converters[i],
              collateralAsset_,
              vars.collateral,
              borrowAsset_,
              vars.amountToBorrow,
              address(this)
            );
          }

          if (amountIn_ == 0) break;
        }
      }

      return (collateralAmountOut, borrowedAmountOut);
    }
  }

  /// @notice Open position using entry kind 1 - split provided amount on two parts according provided proportions
  /// @param amountIn_ Amount of collateral to be divided on parts. We assume {amountIn_} > 0
  /// @param collateralThreshold_ Min allowed collateral amount to be used for new borrow, > 0
  /// @return collateralAmountOut Total collateral used to borrow {borrowedAmountOut}
  /// @return borrowedAmountOut Total borrowed amount
  function openPositionEntryKind1(
    ITetuConverter tetuConverter_,
    bytes memory entryData_,
    address collateralAsset_,
    address borrowAsset_,
    uint amountIn_,
    uint collateralThreshold_
  ) internal returns (
    uint collateralAmountOut,
    uint borrowedAmountOut
  ) {
    OpenPositionEntryKind1Local memory vars;
    (vars.converters, vars.collateralsRequired, vars.amountsToBorrow,) = tetuConverter_.findBorrowStrategies(
      entryData_,
      collateralAsset_,
      amountIn_,
      borrowAsset_,
      _LOAN_PERIOD_IN_BLOCKS
    );

    uint len = vars.converters.length;
    if (len > 0) {
      // we should split amountIn on two amounts with proportions x:y
      (, uint x, uint y) = abi.decode(entryData_, (uint, uint, uint));
      // calculate prices conversion ratio using price oracle, decimals 18
      // i.e. alpha = 1e18 * 75e6 usdc / 25e18 matic = 3e6 usdc/matic
      vars.alpha = _getCollateralToBorrowRatio(tetuConverter_, collateralAsset_, borrowAsset_);

      for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
        // the lending platform allows to convert {collateralsRequired[i]} to {amountsToBorrow[i]}
        // and give us required proportions in result
        // C = C1 + C2, C2 => B2, B2 * alpha = C3, C1/C3 must be equal to x/y
        // C1 is collateral amount left untouched (x)
        // C2 is collateral amount converted to B2 (y)
        // but if lending platform doesn't have enough liquidity
        // it reduces {collateralsRequired[i]} and {amountsToBorrow[i]} proportionally to fit the limits
        // as result, remaining C1 will be too big after conversion and we need to make another borrow
        vars.c3 = vars.alpha * vars.amountsToBorrow[i] / 1e18;
        vars.c1 = x * vars.c3 / y;
        vars.ratio = (vars.collateralsRequired[i] + vars.c1) > amountIn_
          ? 1e18 * amountIn_ / (vars.collateralsRequired[i] + vars.c1)
          : 1e18;

        vars.collateral = vars.collateralsRequired[i] * vars.ratio / 1e18;
        vars.amountToBorrow = vars.amountsToBorrow[i] * vars.ratio / 1e18;

        // skip any attempts to borrow zero amount or use too little collateral
        if (vars.collateral < collateralThreshold_ || vars.amountToBorrow == 0) {
          if (vars.collateralsRequired[i] + vars.c1 + collateralThreshold_ > amountIn_) {
            // The lending platform has enough resources to make the borrow but amount of the borrow is too low
            // Skip the borrow, leave leftover of collateral untouched
            break;
          } else {
            // The lending platform doesn't have enough resources to make the borrow.
            // We should try to make borrow on the next platform (if any)
            continue;
          }
        }

        require(
          tetuConverter_.borrow(
            vars.converters[i],
            collateralAsset_,
            vars.collateral,
            borrowAsset_,
            vars.amountToBorrow,
            address(this)
          ) == vars.amountToBorrow,
          StrategyLib.WRONG_VALUE
        );
        emit OpenPosition(
          vars.converters[i],
          collateralAsset_,
          vars.collateral,
          borrowAsset_,
          vars.amountToBorrow,
          address(this)
        );

        borrowedAmountOut += vars.amountToBorrow;
        collateralAmountOut += vars.collateral;

        // calculate amount to be borrowed in the next converter
        vars.c3 = vars.alpha * vars.amountToBorrow / 1e18;
        vars.c1 = x * vars.c3 / y;
        amountIn_ = (amountIn_ > vars.c1 + vars.collateral)
          ? amountIn_ - (vars.c1 + vars.collateral)
          : 0;

        // protection against dust amounts, see "openPosition.dust", just leave dust amount unused
        // we CAN NOT add it to collateral/borrow amounts - there is a risk to exceed max allowed amounts
        // we assume here, that collateralThreshold_ != 0, so check amountIn_ != 0 is not required
        if (amountIn_ < collateralThreshold_) break;
      }
    }

    return (collateralAmountOut, borrowedAmountOut);
  }

  /// @notice Get ratio18 = collateral / borrow
  function _getCollateralToBorrowRatio(
    ITetuConverter tetuConverter_,
    address collateralAsset_,
    address borrowAsset_
  ) internal view returns (uint){
    IPriceOracle priceOracle = IPriceOracle(IConverterController(tetuConverter_.controller()).priceOracle());
    uint priceCollateral = priceOracle.getAssetPrice(collateralAsset_);
    uint priceBorrow = priceOracle.getAssetPrice(borrowAsset_);
    return 1e18 * priceBorrow * 10 ** IERC20Metadata(collateralAsset_).decimals()
    / priceCollateral / 10 ** IERC20Metadata(borrowAsset_).decimals();
  }

  /// @notice Close the given position, pay {amountToRepay}, return collateral amount in result
  ///         It doesn't repay more than the actual amount of the debt, so it can use less amount than {amountToRepay}
  /// @param amountToRepay Amount to repay in terms of {borrowAsset}
  /// @return returnedAssetAmountOut Amount of collateral received back after repaying
  /// @return repaidAmountOut Amount that was actually repaid
  function _closePosition(
    ITetuConverter converter_,
    address collateralAsset,
    address borrowAsset,
    uint amountToRepay
  ) internal returns (
    uint returnedAssetAmountOut,
    uint repaidAmountOut
  ) {

    uint balanceBefore = IERC20(borrowAsset).balanceOf(address(this));

    // We shouldn't try to pay more than we actually need to repay
    // The leftover will be swapped inside TetuConverter, it's inefficient.
    // Let's limit amountToRepay by needToRepay-amount
    (uint needToRepay,) = converter_.getDebtAmountCurrent(address(this), collateralAsset, borrowAsset, true);
    uint amountRepay = Math.min(amountToRepay < needToRepay ? amountToRepay : needToRepay, balanceBefore);

    return _closePositionExact(converter_, collateralAsset, borrowAsset, amountRepay, balanceBefore);
  }

  /// @notice Close the given position, pay {amountRepay} exactly and ensure that all amount was accepted,
  /// @param amountRepay Amount to repay in terms of {borrowAsset}
  /// @param balanceBorrowAsset Current balance of the borrow asset
  /// @return collateralOut Amount of collateral received back after repaying
  /// @return repaidAmountOut Amount that was actually repaid
  function _closePositionExact(
    ITetuConverter converter_,
    address collateralAsset,
    address borrowAsset,
    uint amountRepay,
    uint balanceBorrowAsset
  ) internal returns (
    uint collateralOut,
    uint repaidAmountOut
  ) {
    // Make full/partial repayment
    IERC20(borrowAsset).safeTransfer(address(converter_), amountRepay);

    uint notUsedAmount;
    (collateralOut, notUsedAmount,,) = converter_.repay(collateralAsset, borrowAsset, amountRepay, address(this));

    emit ClosePosition(collateralAsset, borrowAsset, amountRepay, address(this), collateralOut, notUsedAmount);
    uint balanceAfter = IERC20(borrowAsset).balanceOf(address(this));

    // we cannot use amountRepay here because AAVE pool adapter is able to send tiny amount back (debt-gap)
    repaidAmountOut = balanceBorrowAsset > balanceAfter
      ? balanceBorrowAsset - balanceAfter
      : 0;

    require(notUsedAmount == 0, StrategyLib.WRONG_VALUE);
  }

  /// @notice Close the given position, pay {amountToRepay}, return collateral amount in result
  /// @param amountToRepay Amount to repay in terms of {borrowAsset}
  /// @return returnedAssetAmountOut Amount of collateral received back after repaying
  /// @return repaidAmountOut Amount that was actually repaid
  function closePosition(
    ITetuConverter tetuConverter_,
    address collateralAsset,
    address borrowAsset,
    uint amountToRepay
  ) external returns (
    uint returnedAssetAmountOut,
    uint repaidAmountOut
  ) {
    return _closePosition(tetuConverter_, collateralAsset, borrowAsset, amountToRepay);
  }
  //endregion Borrow and close positions

  /////////////////////////////////////////////////////////////////////
  //region Liquidation
  /////////////////////////////////////////////////////////////////////

  /// @notice Make liquidation if estimated amountOut exceeds the given threshold
  /// @param spentAmountIn Amount of {tokenIn} has been consumed by the liquidator
  /// @param receivedAmountOut Amount of {tokenOut_} has been returned by the liquidator
  /// @param skipValidation Don't check correctness of conversion using TetuConverter's oracle (i.e. for reward tokens)
  function liquidate(
    ITetuConverter converter,
    ITetuLiquidator liquidator_,
    address tokenIn_,
    address tokenOut_,
    uint amountIn_,
    uint slippage_,
    uint liquidationThresholdTokenOut_,
    bool skipValidation
  ) external returns (
    uint spentAmountIn,
    uint receivedAmountOut
  ) {
    return _liquidate(converter, liquidator_, tokenIn_, tokenOut_, amountIn_, slippage_, liquidationThresholdTokenOut_, skipValidation);
  }

  /// @notice Make liquidation if estimated amountOut exceeds the given threshold
  /// @param spentAmountIn Amount of {tokenIn} has been consumed by the liquidator (== 0 | amountIn_)
  /// @param receivedAmountOut Amount of {tokenOut_} has been returned by the liquidator
  /// @param skipValidation Don't check correctness of conversion using TetuConverter's oracle (i.e. for reward tokens)
  function _liquidate(
    ITetuConverter converter_,
    ITetuLiquidator liquidator_,
    address tokenIn_,
    address tokenOut_,
    uint amountIn_,
    uint slippage_,
    uint liquidationThresholdForTokenOut_,
    bool skipValidation
  ) internal returns (
    uint spentAmountIn,
    uint receivedAmountOut
  ) {
    (ITetuLiquidator.PoolData[] memory route,) = liquidator_.buildRoute(tokenIn_, tokenOut_);

    require(route.length != 0, AppErrors.NO_LIQUIDATION_ROUTE);

    // calculate balance in out value for check threshold
    uint amountOut = liquidator_.getPriceForRoute(route, amountIn_);

    // if the expected value is higher than threshold distribute to destinations
    return amountOut > liquidationThresholdForTokenOut_
      ? (amountIn_, _liquidateWithRoute(converter_, route, liquidator_, tokenIn_, tokenOut_, amountIn_, slippage_, skipValidation))
      : (0, 0);
  }

  /// @notice Make liquidation using given route and check correctness using TetuConverter's price oracle
  /// @param skipValidation Don't check correctness of conversion using TetuConverter's oracle (i.e. for reward tokens)
  function _liquidateWithRoute(
    ITetuConverter converter_,
    ITetuLiquidator.PoolData[] memory route,
    ITetuLiquidator liquidator_,
    address tokenIn_,
    address tokenOut_,
    uint amountIn_,
    uint slippage_,
    bool skipValidation
  ) internal returns (
    uint receivedAmountOut
  ) {
    // we need to approve each time, liquidator address can be changed in controller
    AppLib.approveIfNeeded(tokenIn_, amountIn_, address(liquidator_));

    uint balanceBefore = IERC20(tokenOut_).balanceOf(address(this));
    liquidator_.liquidateWithRoute(route, amountIn_, slippage_);
    uint balanceAfter = IERC20(tokenOut_).balanceOf(address(this));

    require(balanceAfter > balanceBefore, AppErrors.BALANCE_DECREASE);
    receivedAmountOut = balanceAfter - balanceBefore;

    // Oracle in TetuConverter "knows" only limited number of the assets
    // It may not know prices for reward assets, so for rewards this validation should be skipped to avoid TC-4 error
    require(skipValidation || converter_.isConversionValid(tokenIn_, amountIn_, tokenOut_, receivedAmountOut, slippage_), AppErrors.PRICE_IMPACT);
    emit Liquidation(tokenIn_, tokenOut_, amountIn_, amountIn_, receivedAmountOut);
  }
  //endregion Liquidation

  /////////////////////////////////////////////////////////////////////
  //region requirePayAmountBack
  /////////////////////////////////////////////////////////////////////

  /// @param amount_ Amount of the main asset requested by converter
  /// @param indexTheAsset Index of the asset required by converter in the {tokens}
  /// @param asset Main asset or underlying (it can be different from tokens[indexTheAsset])
  /// @return amountOut Amount of the main asset sent to converter
  function swapToGivenAmountAndSendToConverter(
    uint amount_,
    uint indexTheAsset,
    address[] memory tokens,
    address converter,
    address controller,
    address asset,
    mapping(address => uint) storage liquidationThresholds
  ) external returns (
    uint amountOut
  ) {
    // msg.sender == converter; we assume here that it was checked before the call of this function
    address theAsset = tokens[indexTheAsset];

    amountOut = IERC20(theAsset).balanceOf(address(this));

    // convert withdrawn assets to the target asset if not enough
    if (amountOut < amount_) {
      ConverterStrategyBaseLib.swapToGivenAmount(
        amount_ - amountOut,
        tokens,
        indexTheAsset,
        asset, // underlying === main asset
        ITetuConverter(converter),
        ITetuLiquidator(IController(controller).liquidator()),
        liquidationThresholds[theAsset],
        OVERSWAP
      );
      amountOut = IERC20(theAsset).balanceOf(address(this));
    }

    // we should send the asset as is even if it is lower than requested
    // but shouldn't sent more amount than requested
    amountOut = Math.min(amount_, amountOut);
    if (amountOut != 0) {
      IERC20(theAsset).safeTransfer(converter, amountOut);
    }

    // There are two cases of calling requirePayAmountBack by converter:
    // 1) close a borrow: we will receive collateral back and amount of investedAssets almost won't change
    // 2) rebalancing: we have real loss, it will be taken into account at next hard work
    emit ReturnAssetToConverter(theAsset, amountOut);

    // let's leave any leftovers un-invested, they will be reinvested at next hardwork
  }

  /// @notice Swap available amounts of {tokens_} to receive {targetAmount_} of {tokens[indexTheAsset_]}
  /// @param targetAmount_ Required amount of tokens[indexTheAsset_] that should be received by swap(s)
  /// @param tokens_ tokens received from {_depositorPoolAssets}
  /// @param indexTargetAsset_ Index of target asset in tokens_ array
  /// @param underlying_ Index of underlying
  /// @param liquidationThresholdForTargetAsset_ Liquidation thresholds for the target asset
  /// @param overswap_ Allow to swap more then required (i.e. 1_000 => +1%)
  ///                  to avoid additional swap if the swap return amount a bit less than we expected
  /// @return spentAmounts Any amounts spent during the swaps
  function swapToGivenAmount(
    uint targetAmount_,
    address[] memory tokens_,
    uint indexTargetAsset_,
    address underlying_,
    ITetuConverter converter_,
    ITetuLiquidator liquidator_,
    uint liquidationThresholdForTargetAsset_,
    uint overswap_
  ) internal returns (
    uint[] memory spentAmounts,
    uint[] memory receivedAmounts
  ) {
    SwapToGivenAmountLocal memory v;
    v.len = tokens_.length;

    v.availableAmounts = new uint[](v.len);
    for (; v.i < v.len; v.i = AppLib.uncheckedInc(v.i)) {
      v.availableAmounts[v.i] = IERC20(tokens_[v.i]).balanceOf(address(this));
    }

    (spentAmounts, receivedAmounts) = _swapToGivenAmount(
      SwapToGivenAmountInputParams({
        targetAmount: targetAmount_,
        tokens: tokens_,
        indexTargetAsset: indexTargetAsset_,
        underlying: underlying_,
        amounts: v.availableAmounts,
        converter: converter_,
        liquidator: liquidator_,
        liquidationThresholdForTargetAsset: Math.max(liquidationThresholdForTargetAsset_, DEFAULT_LIQUIDATION_THRESHOLD),
        overswap: overswap_
      })
    );
  }

  /// @notice Swap available {amounts_} of {tokens_} to receive {targetAmount_} of {tokens[indexTheAsset_]}
  /// @return spentAmounts Any amounts spent during the swaps
  /// @return receivedAmounts Any amounts received during the swaps
  function _swapToGivenAmount(SwapToGivenAmountInputParams memory p) internal returns (
    uint[] memory spentAmounts,
    uint[] memory receivedAmounts
  ) {
    CalcInvestedAssetsLocal memory v;
    v.len = p.tokens.length;
    receivedAmounts = new uint[](v.len);
    spentAmounts = new uint[](v.len);

    // calculate prices, decimals
    (v.prices, v.decs) = _getPricesAndDecs(
      IPriceOracle(IConverterController(p.converter.controller()).priceOracle()),
      p.tokens,
      v.len
    );

    // we need to swap other assets to the asset
    // at first we should swap NOT underlying.
    // if it would be not enough, we can swap underlying too.

    // swap NOT underlying, initialize {indexUnderlying}
    uint indexUnderlying;
    for (uint i; i < v.len; i = AppLib.uncheckedInc(i)) {
      if (p.underlying == p.tokens[i]) {
        indexUnderlying = i;
        continue;
      }
      if (p.indexTargetAsset == i) continue;

      (uint spent, uint received) = _swapToGetAmount(receivedAmounts[p.indexTargetAsset], p, v, i);
      spentAmounts[i] += spent;
      receivedAmounts[p.indexTargetAsset] += received;

      if (receivedAmounts[p.indexTargetAsset] >= p.targetAmount) break;
    }

    // swap underlying
    if (receivedAmounts[p.indexTargetAsset] < p.targetAmount && p.indexTargetAsset != indexUnderlying) {
      (uint spent, uint received) = _swapToGetAmount(receivedAmounts[p.indexTargetAsset], p, v, indexUnderlying);
      spentAmounts[indexUnderlying] += spent;
      receivedAmounts[p.indexTargetAsset] += received;
    }
  }

  /// @notice Swap a part of amount of asset {tokens[indexTokenIn]} to {targetAsset} to get {targetAmount} in result
  /// @param receivedTargetAmount Already received amount of {targetAsset} in previous swaps
  /// @param indexTokenIn Index of the tokenIn in p.tokens
  function _swapToGetAmount(
    uint receivedTargetAmount,
    SwapToGivenAmountInputParams memory p,
    CalcInvestedAssetsLocal memory v,
    uint indexTokenIn
  ) internal returns (
    uint amountSpent,
    uint amountReceived
  ) {
    if (p.amounts[indexTokenIn] != 0) {
      // we assume here, that p.targetAmount > receivedTargetAmount, see _swapToGivenAmount implementation

      // calculate amount that should be swapped
      // {overswap} allows to swap a bit more
      // to avoid additional swaps if the swap will give us a bit less amount than expected
      uint amountIn = (
        (p.targetAmount - receivedTargetAmount)
        * v.prices[p.indexTargetAsset] * v.decs[indexTokenIn]
        / v.prices[indexTokenIn] / v.decs[p.indexTargetAsset]
      ) * (p.overswap + DENOMINATOR) / DENOMINATOR;

      (amountSpent, amountReceived) = _liquidate(
        p.converter,
        p.liquidator,
        p.tokens[indexTokenIn],
        p.tokens[p.indexTargetAsset],
        Math.min(amountIn, p.amounts[indexTokenIn]),
        _ASSET_LIQUIDATION_SLIPPAGE,
        p.liquidationThresholdForTargetAsset,
        false
      );
    }

    return (amountSpent, amountReceived);
  }
  //endregion requirePayAmountBack

  /////////////////////////////////////////////////////////////////////
  //region Recycle rewards
  /////////////////////////////////////////////////////////////////////

  /// @notice Recycle the amounts: split each amount on tree parts: performance+insurance (P), forwarder (F), compound (C)
  ///         Liquidate P+C, send F to the forwarder.
  /// We have two kinds of rewards:
  /// 1) rewards in depositor's assets (the assets returned by _depositorPoolAssets)
  /// 2) any other rewards
  /// All received rewards divided on three parts: to performance receiver+insurance, to forwarder, to compound
  ///   Compound-part of Rewards-2 can be liquidated
  ///   Compound part of Rewards-1 should be just left on the balance
  ///   All forwarder-parts are returned in amountsToForward and should be transferred to the forwarder outside.
  ///   Performance amounts are liquidated, result amount of underlying is returned in {amountToPerformanceAndInsurance}
  /// @param asset Underlying asset
  /// @param compoundRatio Compound ration in the range [0...COMPOUND_DENOMINATOR]
  /// @param tokens tokens received from {_depositorPoolAssets}
  /// @param rewardTokens Full list of reward tokens received from tetuConverter and depositor
  /// @param rewardAmounts Amounts of {rewardTokens_}; we assume, there are no zero amounts here
  /// @param liquidationThresholds Liquidation thresholds for rewards tokens
  /// @param performanceFee Performance fee in the range [0...FEE_DENOMINATOR]
  /// @return amountsToForward Amounts of {rewardTokens} to be sent to forwarder, zero amounts are allowed here
  /// @return amountToPerformanceAndInsurance Amount of underlying to be sent to performance receiver and insurance
  function recycle(
    ITetuConverter converter_,
    address asset,
    uint compoundRatio,
    address[] memory tokens,
    ITetuLiquidator liquidator,
    mapping(address => uint) storage liquidationThresholds,
    address[] memory rewardTokens,
    uint[] memory rewardAmounts,
    uint performanceFee
  ) external returns (
    uint[] memory amountsToForward,
    uint amountToPerformanceAndInsurance
  ) {
    RecycleLocalParams memory p;

    p.len = rewardTokens.length;
    require(p.len == rewardAmounts.length, AppErrors.WRONG_LENGTHS);

    p.liquidationThresholdAsset = Math.max(liquidationThresholds[asset], DEFAULT_LIQUIDATION_THRESHOLD);

    amountsToForward = new uint[](p.len);

    // rewardAmounts => P + F + C, where P - performance + insurance, F - forwarder, C - compound
    for (uint i; i < p.len; i = AppLib.uncheckedInc(i)) {
      p.amountFC = rewardAmounts[i] * (COMPOUND_DENOMINATOR - performanceFee) / COMPOUND_DENOMINATOR;
      p.amountC = p.amountFC * compoundRatio / COMPOUND_DENOMINATOR;
      p.amountP = rewardAmounts[i] - p.amountFC;
      p.rewardToken = rewardTokens[i];
      p.amountCP = p.amountC + p.amountP;

      if (p.amountCP > 0) {
        if (ConverterStrategyBaseLib.getAssetIndex(tokens, p.rewardToken) != type(uint).max) {
          if (p.rewardToken == asset) {
            // This is underlying, liquidation of compound part is not allowed; just keep on the balance, should be handled later
            amountToPerformanceAndInsurance += p.amountP;
          } else {
            // This is secondary asset, Liquidation of compound part is not allowed, we should liquidate performance part only
            if (p.amountP < Math.max(liquidationThresholds[p.rewardToken], DEFAULT_LIQUIDATION_THRESHOLD)) {
              // performance amount is too small, liquidation is not allowed, we just keep that dust tokens on balance forever
            } else {
              (, p.receivedAmountOut) = _liquidate(
                converter_,
                liquidator,
                p.rewardToken,
                asset,
                p.amountP,
                _REWARD_LIQUIDATION_SLIPPAGE,
                p.liquidationThresholdAsset,
                false // use conversion validation for these rewards
              );
              amountToPerformanceAndInsurance += p.receivedAmountOut;
            }
          }
        } else {
          if (p.amountCP < Math.max(liquidationThresholds[p.rewardToken], DEFAULT_LIQUIDATION_THRESHOLD)) {
            // amount is too small, liquidation is not allowed, we just keep that dust tokens on balance forever
          } else {
            // The asset is not in the list of depositor's assets, its amount is big enough and should be liquidated
            // We assume here, that {token} cannot be equal to {_asset}
            // because the {_asset} is always included to the list of depositor's assets
            (, p.receivedAmountOut) = _liquidate(
              converter_,
              liquidator,
              p.rewardToken,
              asset,
              p.amountCP,
              _REWARD_LIQUIDATION_SLIPPAGE,
              p.liquidationThresholdAsset,
              true // skip conversion validation for rewards becase we can have arbitrary assets here
            );

            amountToPerformanceAndInsurance += p.receivedAmountOut * (rewardAmounts[i] - p.amountFC) / p.amountCP;
          }
        }
      }
      amountsToForward[i] = p.amountFC - p.amountC;
    }
    return (amountsToForward, amountToPerformanceAndInsurance);
  }
  //endregion Recycle rewards

  /////////////////////////////////////////////////////////////////////
  //region calcInvestedAssets
  /////////////////////////////////////////////////////////////////////

  /// @notice Calculate amount we will receive when we withdraw all from pool
  /// @dev This is writable function because we need to update current balances in the internal protocols.
  /// @return amountOut Invested asset amount under control (in terms of {asset})
  function calcInvestedAssets(
    address[] memory tokens,
    uint[] memory depositorQuoteExitAmountsOut,
    uint indexAsset,
    ITetuConverter converter_
  ) external returns (
    uint amountOut
  ) {
    CalcInvestedAssetsLocal memory v;
    v.len = tokens.length;

    // calculate prices, decimals
    (v.prices, v.decs) = _getPricesAndDecs(
      IPriceOracle(IConverterController(converter_.controller()).priceOracle()),
      tokens,
      v.len
    );
    // A debt is registered below if we have X amount of asset, need to pay Y amount of the asset and X < Y
    // In this case: debt = Y - X, the order of tokens is the same as in {tokens} array
    for (uint i; i < v.len; i = AppLib.uncheckedInc(i)) {
      if (i == indexAsset) {
        // Current strategy balance of main asset is not taken into account here because it's add by splitter
        amountOut += depositorQuoteExitAmountsOut[i];
      } else {
        // available amount to repay
        uint toRepay = IERC20(tokens[i]).balanceOf(address(this)) + depositorQuoteExitAmountsOut[i];

        (uint toPay, uint collateral) = converter_.getDebtAmountCurrent(
          address(this),
          tokens[indexAsset],
          tokens[i],
          // investedAssets is calculated using exact debts, debt-gaps are not taken into account
          false
        );
        amountOut += collateral;

        if (toRepay >= toPay) {
          amountOut += (toRepay - toPay) * v.prices[i] * v.decs[indexAsset] / v.prices[indexAsset] / v.decs[i];
        } else {
          // there is not enough amount to pay the debt
          // let's register a debt and try to resolve it later below
          if (v.debts.length == 0) {
            // lazy initialization
            v.debts = new uint[](v.len);
          }

          // to pay the following amount we need to swap some other asset at first
          v.debts[i] = toPay - toRepay;
        }
      }
    }
    if (v.debts.length == v.len) {
      // we assume here, that it would be always profitable to save collateral
      // f.e. if there is not enough amount of USDT on our balance and we have a debt in USDT,
      // it's profitable to change any available asset to USDT, pay the debt and return the collateral back
      for (uint i; i < v.len; i = AppLib.uncheckedInc(i)) {
        if (v.debts[i] == 0) continue;

        // estimatedAssets should be reduced on the debt-value
        // this estimation is approx and do not count price impact on the liquidation
        // we will able to count the real output only after withdraw process
        uint debtInAsset = v.debts[i] * v.prices[i] * v.decs[indexAsset] / v.prices[indexAsset] / v.decs[i];
        if (debtInAsset > amountOut) {
          // The debt is greater than we can pay. We shouldn't try to pay the debt in this case
          amountOut = 0;
        } else {
          amountOut -= debtInAsset;
        }
      }
    }

    return amountOut;
  }
  //endregion calcInvestedAssets

  /////////////////////////////////////////////////////////////////////
  //region getExpectedAmountMainAsset
  /////////////////////////////////////////////////////////////////////

  /// @notice Calculate expected amount of the main asset after withdrawing
  /// @param withdrawnAmounts_ Expected amounts to be withdrawn from the pool
  /// @param amountsToConvert_ Amounts on balance initially available for the conversion
  /// @return amountsOut Expected amounts of the main asset received after conversion withdrawnAmounts+amountsToConvert
  function getExpectedAmountMainAsset(
    address[] memory tokens,
    uint indexAsset,
    ITetuConverter converter,
    uint[] memory withdrawnAmounts_,
    uint[] memory amountsToConvert_
  ) internal returns (
    uint[] memory amountsOut
  ) {
    uint len = tokens.length;
    amountsOut = new uint[](len);
    for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
      if (i == indexAsset) {
        amountsOut[i] = withdrawnAmounts_[i];
      } else {
        uint amount = withdrawnAmounts_[i] + amountsToConvert_[i];
        if (amount != 0) {
          (amountsOut[i],) = converter.quoteRepay(address(this), tokens[indexAsset], tokens[i], amount);
        }
      }
    }

    return amountsOut;
  }
  //endregion getExpectedAmountMainAsset

  /////////////////////////////////////////////////////////////////////
  //region Reduce size of ConverterStrategyBase
  /////////////////////////////////////////////////////////////////////

  /// @notice Make borrow and save amounts of tokens available for deposit to tokenAmounts
  /// @param thresholdMainAsset_ Min allowed value of collateral in terms of main asset, 0 - use default min value
  /// @param tokens_ Tokens received from {_depositorPoolAssets}
  /// @param collaterals_ Amounts of main asset that can be used as collateral to borrow {tokens_}
  /// @param thresholdMainAsset_ Value of liquidation threshold for the main (collateral) asset
  /// @return tokenAmountsOut Amounts available for deposit
  function getTokenAmounts(
    ITetuConverter tetuConverter_,
    address[] memory tokens_,
    uint indexAsset_,
    uint[] memory collaterals_,
    uint thresholdMainAsset_
  ) external returns (
    uint[] memory tokenAmountsOut
  ) {
    // content of tokenAmounts will be modified in place
    uint len = tokens_.length;
    tokenAmountsOut = new uint[](len);

    for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
      if (i != indexAsset_) {
        if (collaterals_[i] != 0) {
          AppLib.approveIfNeeded(tokens_[indexAsset_], collaterals_[i], address(tetuConverter_));
          _openPosition(
            tetuConverter_,
            "", // entry kind = 0: fixed collateral amount, max possible borrow amount
            tokens_[indexAsset_],
            tokens_[i],
            collaterals_[i],
            Math.max(thresholdMainAsset_, DEFAULT_LIQUIDATION_THRESHOLD)
          );

          // zero borrowed amount is possible here (conversion is not available)
          // if it's not suitable for depositor, the depositor should check zero amount in other places
        }
        tokenAmountsOut[i] = IERC20(tokens_[i]).balanceOf(address(this));
      }
    }

    tokenAmountsOut[indexAsset_] = Math.min(
      collaterals_[indexAsset_],
      IERC20(tokens_[indexAsset_]).balanceOf(address(this))
    );
  }

  /// @notice Convert {amountsToConvert_} to the main {asset}
  ///         Swap leftovers (if any) to the main asset.
  ///         If result amount is less than expected, try to close any other available debts (1 repay per block only)
  /// @param tokens_ Results of _depositorPoolAssets() call (list of depositor's asset in proper order)
  /// @param indexAsset_ Index of main {asset} in {tokens}
  /// @param requestedAmount Amount to be withdrawn in terms of the asset in addition to the exist balance.
  ///        Max uint means attempt to withdraw all possible invested assets.
  /// @param amountsToConvert_ Amounts available for conversion after withdrawing from the pool
  /// @param expectedMainAssetAmounts Amounts of main asset that we expect to receive after conversion amountsToConvert_
  /// @return expectedAmount Expected total amount of main asset after all conversions, swaps and repays
  function makeRequestedAmount(
    address[] memory tokens_,
    uint indexAsset_,
    uint[] memory amountsToConvert_,
    ITetuConverter converter_,
    ITetuLiquidator liquidator_,
    uint requestedAmount,
    uint[] memory expectedMainAssetAmounts,
    mapping(address => uint) storage liquidationThresholds
  ) external returns (uint expectedAmount) {
    // get the total expected amount
    for (uint i; i < tokens_.length; i = AppLib.uncheckedInc(i)) {
      expectedAmount += expectedMainAssetAmounts[i];
    }

    // we cannot repay a debt twice
    // suppose, we have usdt = 1 and we need to convert it to usdc, then get additional usdt=10 and make second repay
    // But: we cannot make repay(1) and than repay(10). We MUST make single repay(11)

    if (requestedAmount != type(uint).max
      && expectedAmount > requestedAmount * (GAP_CONVERSION + DENOMINATOR) / DENOMINATOR
    ) {
      // amountsToConvert_ are enough to get requestedAmount
      _convertAfterWithdraw(
        converter_,
        liquidator_,
        indexAsset_,
        liquidationThresholds[tokens_[indexAsset_]],
        tokens_,
        amountsToConvert_
      );
    } else {
      // amountsToConvert_ are NOT enough to get requestedAmount
      // We are allowed to make only one repay per block, so, we shouldn't try to convert amountsToConvert_
      // We should try to close the exist debts instead:
      //    convert a part of main assets to get amount of secondary assets required to repay the debts
      // and only then make conversion.
      expectedAmount = _closePositionsToGetAmount(
        converter_,
        liquidator_,
        indexAsset_,
        liquidationThresholds,
        requestedAmount,
        tokens_
      ) + expectedMainAssetAmounts[indexAsset_];
    }

    return expectedAmount;
  }
  //endregion Reduce size of ConverterStrategyBase

  /////////////////////////////////////////////////////////////////////
  //region Withdraw helpers
  /////////////////////////////////////////////////////////////////////

  /// @notice Add {withdrawnAmounts} to {amountsToConvert}, calculate {expectedAmountMainAsset}
  /// @param amountsToConvert Amounts of {tokens} to be converted, they are located on the balance before withdraw
  /// @param withdrawnAmounts Amounts of {tokens} that were withdrew from the pool
  function postWithdrawActions(
    ITetuConverter converter,
    address[] memory tokens,
    uint indexAsset,

    uint[] memory reservesBeforeWithdraw,
    uint liquidityAmountWithdrew,
    uint totalSupplyBeforeWithdraw,

    uint[] memory amountsToConvert,
    uint[] memory withdrawnAmounts
  ) external returns (
    uint[] memory expectedMainAssetAmounts,
    uint[] memory _amountsToConvert
  ) {
    // estimate expected amount of assets to be withdrawn
    uint[] memory expectedWithdrawAmounts = getExpectedWithdrawnAmounts(
      reservesBeforeWithdraw,
      liquidityAmountWithdrew,
      totalSupplyBeforeWithdraw
    );

    // from received amounts after withdraw calculate how much we receive from converter for them in terms of the underlying asset
    expectedMainAssetAmounts = getExpectedAmountMainAsset(
      tokens,
      indexAsset,
      converter,
      expectedWithdrawAmounts,
      amountsToConvert
    );

    uint len = tokens.length;
    for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
      amountsToConvert[i] += withdrawnAmounts[i];
    }

    return (expectedMainAssetAmounts, amountsToConvert);
  }

  /// @notice return {withdrawnAmounts} with zero values and expected amount calculated using {amountsToConvert_}
  function postWithdrawActionsEmpty(
    ITetuConverter converter,
    address[] memory tokens,
    uint indexAsset,
    uint[] memory amountsToConvert_
  ) external returns (
    uint[] memory expectedAmountsMainAsset
  ) {
    expectedAmountsMainAsset = getExpectedAmountMainAsset(
      tokens,
      indexAsset,
      converter,
      // there are no withdrawn amounts
      new uint[](tokens.length), // array with all zero values
      amountsToConvert_
    );
  }

  //endregion Withdraw helpers

  /////////////////////////////////////////////////////////////////////
  //region convertAfterWithdraw
  /////////////////////////////////////////////////////////////////////

  /// @notice Convert {amountsToConvert_} (available on balance) to the main asset
  ///         Swap leftovers if any.
  ///         Result amount can be less than requested one, we don't try to close any other debts here
  /// @param indexAsset Index of the main asset in {tokens}
  /// @param liquidationThreshold Min allowed amount of main asset to be liquidated in {liquidator}
  /// @param tokens Tokens received from {_depositorPoolAssets}
  /// @param amountsToConvert Amounts to convert, the order of asset is same as in {tokens}
  /// @return collateralOut Total amount of main asset returned after closing positions
  /// @return repaidAmountsOut What amounts were spent in exchange of the {collateralOut}
  function _convertAfterWithdraw(
    ITetuConverter tetuConverter,
    ITetuLiquidator liquidator,
    uint indexAsset,
    uint liquidationThreshold,
    address[] memory tokens,
    uint[] memory amountsToConvert
  ) internal returns (
    uint collateralOut,
    uint[] memory repaidAmountsOut
  ) {
    ConvertAfterWithdrawLocal memory v;
    v.asset = tokens[indexAsset];
    v.balanceBefore = IERC20(v.asset).balanceOf(address(this));
    v.len = tokens.length;

    // Close positions to convert all required amountsToConvert
    repaidAmountsOut = new uint[](tokens.length);
    for (uint i; i < v.len; i = AppLib.uncheckedInc(i)) {
      if (i == indexAsset || amountsToConvert[i] == 0) continue;
      (, repaidAmountsOut[i]) = _closePosition(tetuConverter, v.asset, tokens[i], amountsToConvert[i]);
    }

    // Manually swap remain leftovers
    for (uint i; i < v.len; i = AppLib.uncheckedInc(i)) {
      if (i == indexAsset || amountsToConvert[i] == 0) continue;
      if (amountsToConvert[i] > repaidAmountsOut[i]) {
        (v.spent, v.received) = _liquidate(
          tetuConverter,
          liquidator,
          tokens[i],
          v.asset,
          amountsToConvert[i] - repaidAmountsOut[i],
          _ASSET_LIQUIDATION_SLIPPAGE,
          liquidationThreshold,
          false
        );
        collateralOut += v.received;
        repaidAmountsOut[i] += v.spent;
      }
    }

    // Calculate amount of received collateral
    v.balance = IERC20(v.asset).balanceOf(address(this));
    collateralOut = v.balance > v.balanceBefore
      ? v.balance - v.balanceBefore
      : 0;

    return (collateralOut, repaidAmountsOut);
  }

  /// @notice Close debts (if it's allowed) in converter until we don't have {requestedAmount} on balance
  /// @dev We assume here that this function is called before closing any positions in the current block
  /// @param liquidationThresholds Min allowed amounts-out for liquidations
  /// @param requestedAmount Requested amount of main asset that should be added to the current balance
  /// @return expectedAmount Main asset amount expected to be received on balance after all conversions and swaps
  function closePositionsToGetAmount(
    ITetuConverter converter_,
    ITetuLiquidator liquidator,
    uint indexAsset,
    mapping(address => uint) storage liquidationThresholds,
    uint requestedAmount,
    address[] memory tokens
  ) external returns (
    uint expectedAmount
  ) {
    return _closePositionsToGetAmount(
      converter_,
      liquidator,
      indexAsset,
      liquidationThresholds,
      requestedAmount,
      tokens
    );
  }

  function _closePositionsToGetAmount(
    ITetuConverter converter_,
    ITetuLiquidator liquidator,
    uint indexAsset,
    mapping(address => uint) storage liquidationThresholds,
    uint requestedAmount,
    address[] memory tokens
  ) internal returns (
    uint expectedAmount
  ) {
    if (requestedAmount != 0) {
      CloseDebtsForRequiredAmountLocal memory v;
      v.asset = tokens[indexAsset];
      v.len = tokens.length;
      v.balance = IERC20(v.asset).balanceOf(address(this));

      for (uint i; i < v.len; i = AppLib.uncheckedInc(i)) {
        if (i == indexAsset) continue;

        // we need to increase balance on the following amount: requestedAmount - v.balance;
        // we have following borrow: amount-to-pay and corresponded collateral
        (v.totalDebt, v.totalCollateral) = converter_.getDebtAmountCurrent(address(this), v.asset, tokens[i], true);

        uint tokenBalance = IERC20(tokens[i]).balanceOf(address(this));

        if (v.totalDebt != 0 || tokenBalance != 0) {
          //lazy initialization of the prices and decs
          if (v.prices.length == 0) {
            (v.prices, v.decs) = _getPricesAndDecs(
              IPriceOracle(IConverterController(converter_.controller()).priceOracle()),
              tokens,
              v.len
            );
          }

          // repay the debt if any
          if (v.totalDebt != 0) {
            // what amount of main asset we should sell to pay the debt
            uint toSell = _getAmountToSell(
              requestedAmount,
              v.totalDebt,
              v.totalCollateral,
              v.prices,
              v.decs,
              indexAsset,
              i,
              tokenBalance
            );

            // convert {toSell} amount of main asset to tokens[i]
            if (toSell != 0 && v.balance != 0) {
              toSell = Math.min(toSell, v.balance);
              (toSell, ) = _liquidate(
                converter_,
                liquidator,
                v.asset,
                tokens[i],
                toSell,
                _ASSET_LIQUIDATION_SLIPPAGE,
                liquidationThresholds[tokens[i]],
                false
              );
              tokenBalance = IERC20(tokens[i]).balanceOf(address(this));
            }

            // sell {toSell}, repay the debt, return collateral back; we should receive amount > toSell
            expectedAmount += _repayDebt(converter_, v.asset, tokens[i], tokenBalance) - toSell;

            // we can have some leftovers after closing the debt
            tokenBalance = IERC20(tokens[i]).balanceOf(address(this));
          }

          // directly swap leftovers
          if (tokenBalance != 0) {
            (uint spentAmountIn,) = _liquidate(
              converter_,
              liquidator,
              tokens[i],
              v.asset,
              tokenBalance,
              _ASSET_LIQUIDATION_SLIPPAGE,
              liquidationThresholds[v.asset],
              false
            );
            if (spentAmountIn != 0) {
              // spentAmountIn can be zero if token balance is less than liquidationThreshold
              expectedAmount += spentAmountIn * v.prices[i] * v.decs[indexAsset] / v.prices[indexAsset] / v.decs[i];
            }
          }

          // reduce of requestedAmount on the balance increment
          v.newBalance = IERC20(v.asset).balanceOf(address(this));
          require(v.newBalance >= v.balance, AppErrors.BALANCE_DECREASE);

          if (requestedAmount > v.newBalance - v.balance) {
            requestedAmount -= (v.newBalance - v.balance);
            v.balance = v.newBalance;
          } else {
            // we get requestedAmount on the balance and don't need to make any other conversions
            break;
          }
        }
      }
    }

    return expectedAmount;
  }

  /// @notice What amount of collateral should be sold to pay the debt and receive {requestedAmount}
  /// @dev It doesn't allow to sell more than the amount of total debt in the borrow
  /// @param requestedAmount We need to increase balance (of collateral asset) on this amount
  /// @param totalDebt Total debt of the borrow in terms of borrow asset
  /// @param totalCollateral Total collateral of the borrow in terms of collateral asset
  /// @param prices Cost of $1 in terms of the asset, decimals 18
  /// @param decs 10**decimals for each asset
  /// @param indexCollateral Index of the collateral asset in {prices} and {decs}
  /// @param indexBorrowAsset Index of the borrow asset in {prices} and {decs}
  /// @param balanceBorrowAsset Available balance of the borrow asset, it will be used to cover the debt
  function _getAmountToSell(
    uint requestedAmount,
    uint totalDebt,
    uint totalCollateral,
    uint[] memory prices,
    uint[] memory decs,
    uint indexCollateral,
    uint indexBorrowAsset,
    uint balanceBorrowAsset
  ) internal pure returns (
    uint amountOut
  ) {
    if (totalDebt != 0) {
      if (balanceBorrowAsset != 0) {
        // there is some borrow asset on balance
        // it will be used to cover the debt
        // let's reduce the size of totalDebt/Collateral to exclude balanceBorrowAsset
        uint sub = Math.min(balanceBorrowAsset, totalDebt);
        totalCollateral -= totalCollateral * sub / totalDebt;
        totalDebt -= sub;
      }

      // for definiteness: usdc - collateral asset, dai - borrow asset
      // Pc = price of the USDC, Pb = price of the DAI, alpha = Pc / Pb [DAI / USDC]
      // S [USDC] - amount to sell, R [DAI] = alpha * S - amount to repay
      // After repaying R we get: alpha * S * C / R
      // Balance should be increased on: requestedAmount = alpha * S * C / R - S
      // So, we should sell: S = requestedAmount / (alpha * C / R - 1))
      // We can lost some amount on liquidation of S => R, so we need to use some gap = {GAP_AMOUNT_TO_SELL}
      // Same formula: S * h = S + requestedAmount, where h = health factor => s = requestedAmount / (h - 1)
      // h = alpha * C / R
      uint alpha18 = prices[indexCollateral] * decs[indexBorrowAsset] * 1e18
      / prices[indexBorrowAsset] / decs[indexCollateral];

      // if totalCollateral is zero (liquidation happens) we will have zero amount (the debt shouldn't be paid)
      amountOut = totalDebt != 0 && alpha18 * totalCollateral / totalDebt > 1e18
        ? Math.min(requestedAmount, totalCollateral) * 1e18 / (alpha18 * totalCollateral / totalDebt - 1e18)
        : 0;

      if (amountOut != 0) {
        // we shouldn't try to sell amount greater than amount of totalDebt in terms of collateral asset
        // but we always asks +1% because liquidation results can be different a bit from expected
        amountOut = (GAP_CONVERSION + DENOMINATOR) * Math.min(amountOut, totalDebt * 1e18 / alpha18) / DENOMINATOR;
      }
    }

    return amountOut;
  }

  /// @notice Repay {amountIn} and get collateral in return, calculate expected amount
  ///         Take into account possible debt-gap and the fact that the amount of debt may be less than {amountIn}
  /// @param amountToRepay Max available amount of borrow asset that we can repay
  /// @return expectedAmountOut Estimated amount of main asset that should be added to balance = collateral - {toSell}
  function _repayDebt(
    ITetuConverter converter,
    address collateralAsset,
    address borrowAsset,
    uint amountToRepay
  ) internal returns (
    uint expectedAmountOut
  ) {
    uint balanceBefore = IERC20(borrowAsset).balanceOf(address(this));

    // get amount of debt with debt-gap
    (uint needToRepay,) = converter.getDebtAmountCurrent(address(this), collateralAsset, borrowAsset, true);
    uint amountRepay = Math.min(amountToRepay < needToRepay ? amountToRepay : needToRepay, balanceBefore);

    // get expected amount without debt-gap
    uint swappedAmountOut;
    (expectedAmountOut, swappedAmountOut) = converter.quoteRepay(address(this), collateralAsset, borrowAsset, amountRepay);

    if (expectedAmountOut > swappedAmountOut) {
      // Following situation is possible
      //    needToRepay = 100, needToRepayExact = 90 (debt gap is 10)
      //    1) amountRepay = 80
      //       expectedAmountOut is calculated for 80, no problems
      //    2) amountRepay = 99,
      //       expectedAmountOut is calculated for 90 + 9 (90 - repay, 9 - direct swap)
      //       expectedAmountOut must be reduced on 9 here (!)
      expectedAmountOut -= swappedAmountOut;
    }

    // close the debt
    _closePositionExact(converter, collateralAsset, borrowAsset, amountRepay, balanceBefore);

    return expectedAmountOut;
  }
  //endregion convertAfterWithdraw

  /////////////////////////////////////////////////////////////////////
  //region Other helpers
  /////////////////////////////////////////////////////////////////////

  function getAssetPriceFromConverter(ITetuConverter converter, address token) external view returns (uint) {
    return IPriceOracle(IConverterController(converter.controller()).priceOracle()).getAssetPrice(token);
  }

  function registerIncome(uint assetBefore, uint assetAfter) internal pure returns (uint earned, uint lost) {
    if (assetAfter > assetBefore) {
      earned = assetAfter - assetBefore;
    } else {
      lost = assetBefore - assetAfter;
    }
    return (earned, lost);
  }

  /// @notice Register income and cover possible loss
  function coverPossibleStrategyLoss(uint assetBefore, uint assetAfter, address splitter) external returns (uint earned) {
    uint lost;
    (earned, lost) = ConverterStrategyBaseLib.registerIncome(assetBefore, assetAfter);
    if (lost != 0) {
      ISplitter(splitter).coverPossibleStrategyLoss(earned, lost);
    }
    emit FixPriceChanges(assetBefore, assetAfter);
  }

  //endregion Other helpers
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@tetu_io/tetu-contracts-v2/contracts/interfaces/IForwarder.sol";
import "@tetu_io/tetu-contracts-v2/contracts/interfaces/ITetuVaultV2.sol";
import "@tetu_io/tetu-contracts-v2/contracts/interfaces/ISplitter.sol";
import "@tetu_io/tetu-contracts-v2/contracts/strategy/StrategyLib.sol";
import "@tetu_io/tetu-converter/contracts/interfaces/IPriceOracle.sol";
import "@tetu_io/tetu-converter/contracts/interfaces/ITetuConverter.sol";
import "@tetu_io/tetu-contracts-v2/contracts/openzeppelin/Math.sol";
import "@tetu_io/tetu-contracts-v2/contracts/interfaces/ITetuLiquidator.sol";
import "../libs/AppErrors.sol";
import "../libs/AppLib.sol";
import "../libs/TokenAmountsLib.sol";
import "../libs/ConverterEntryKinds.sol";

/// @notice Continuation of ConverterStrategyBaseLib (workaround for size limits)
library ConverterStrategyBaseLib2 {
  using SafeERC20 for IERC20;

  /////////////////////////////////////////////////////////////////////
  ///                        DATA TYPES
  /////////////////////////////////////////////////////////////////////

  /////////////////////////////////////////////////////////////////////
  ///                        CONSTANTS
  /////////////////////////////////////////////////////////////////////

  uint internal constant DENOMINATOR = 100_000;

  /// @dev 0.5% of max profit for strategy TVL
  /// @notice Limit max amount of profit that can be send to insurance after price changing
  uint public constant PRICE_CHANGE_PROFIT_TOLERANCE = 500;

  /////////////////////////////////////////////////////////////////////
  ///                        EVENTS
  /////////////////////////////////////////////////////////////////////

  event OnChangePerformanceFeeRatio(uint newRatio);
  event LiquidationThresholdChanged(address token, uint amount);
  event ReinvestThresholdPercentChanged(uint amount);

  /////////////////////////////////////////////////////////////////////
  ///                        MAIN LOGIC
  /////////////////////////////////////////////////////////////////////

  /// @notice Get balances of the {tokens_} except balance of the token at {indexAsset} position
  function getAvailableBalances(
    address[] memory tokens_,
    uint indexAsset
  ) external view returns (uint[] memory) {
    uint len = tokens_.length;
    uint[] memory amountsToConvert = new uint[](len);
    for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
      if (i == indexAsset) continue;
      amountsToConvert[i] = IERC20(tokens_[i]).balanceOf(address(this));
    }
    return amountsToConvert;
  }

  /// @notice Send {amount_} of {asset_} to {receiver_} and insurance
  /// @param asset_ Underlying asset
  /// @param amount_ Amount of underlying asset to be sent to
  /// @param receiver_ Performance receiver
  /// @param ratio [0..100_000], 100_000 - send full amount to perf, 0 - send full amount to the insurance.
  function sendPerformanceFee(address asset_, uint amount_, address splitter, address receiver_, uint ratio) external returns (
    uint toPerf,
    uint toInsurance
  ) {
    // read inside lib for reduce contract space in the main contract
    address insurance = address(ITetuVaultV2(ISplitter(splitter).vault()).insurance());

    toPerf = amount_ * ratio / DENOMINATOR;
    toInsurance = amount_ - toPerf;

    if (toPerf != 0) {
      IERC20(asset_).safeTransfer(receiver_, toPerf);
    }
    if (toInsurance != 0) {
      IERC20(asset_).safeTransfer(insurance, toInsurance);
    }
  }

  function sendTokensToForwarder(
    address controller_,
    address splitter_,
    address[] memory tokens_,
    uint[] memory amounts_
  ) external {
    uint len = tokens_.length;
    IForwarder forwarder = IForwarder(IController(controller_).forwarder());
    for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
      AppLib.approveIfNeeded(tokens_[i], amounts_[i], address(forwarder));
    }

    (tokens_, amounts_) = TokenAmountsLib.filterZeroAmounts(tokens_, amounts_);
    forwarder.registerIncome(tokens_, amounts_, ISplitter(splitter_).vault(), true);
  }

  /// @notice For each {token_} calculate a part of {amount_} to be used as collateral according to the weights.
  ///         I.e. we have 300 USDC, we need to split it on 100 USDC, 100 USDT, 100 DAI
  ///         USDC is main asset, USDT and DAI should be borrowed. We check amounts of USDT and DAI on the balance
  ///         and return collaterals reduced on that amounts. For main asset, we return full amount always (100 USDC).
  function getCollaterals(
    uint amount_,
    address[] memory tokens_,
    uint[] memory weights_,
    uint totalWeight_,
    uint indexAsset_,
    IPriceOracle priceOracle
  ) external view returns (
    uint[] memory tokenAmountsOut
  ) {
    uint len = tokens_.length;
    tokenAmountsOut = new uint[](len);

    // get token prices and decimals
    uint[] memory prices = new uint[](len);
    uint[] memory decs = new uint[](len);
    for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
      decs[i] = 10 ** IERC20Metadata(tokens_[i]).decimals();
      prices[i] = priceOracle.getAssetPrice(tokens_[i]);
    }

    // split the amount on tokens proportionally to the weights
    for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
      uint amountAssetForToken = amount_ * weights_[i] / totalWeight_;

      if (i == indexAsset_) {
        tokenAmountsOut[i] = amountAssetForToken;
      } else {
        // if we have some tokens on balance then we need to use only a part of the collateral
        uint tokenAmountToBeBorrowed = amountAssetForToken
          * prices[indexAsset_]
          * decs[i]
          / prices[i]
          / decs[indexAsset_];

        uint tokenBalance = IERC20(tokens_[i]).balanceOf(address(this));
        if (tokenBalance < tokenAmountToBeBorrowed) {
          tokenAmountsOut[i] = amountAssetForToken * (tokenAmountToBeBorrowed - tokenBalance) / tokenAmountToBeBorrowed;
        }
      }
    }
  }

  /// @notice Calculate amount of liquidity that should be withdrawn from the pool to get {targetAmount_}
  ///               liquidityAmount = _depositorLiquidity() * {liquidityRatioOut} / 1e18
  ///         User needs to withdraw {targetAmount_} in main asset.
  ///         There are two kinds of available liquidity:
  ///         1) liquidity in the pool - {depositorLiquidity_}
  ///         2) Converted amounts on balance of the strategy - {baseAmounts_}
  ///         To withdraw {targetAmount_} we need
  ///         1) Reconvert converted amounts back to main asset
  ///         2) IF result amount is not necessary - withdraw some liquidity from the pool
  ///            and also convert it to the main asset.
  /// @dev This is a writable function with read-only behavior (because of the quote-call)
  /// @param targetAmount_ Required amount of main asset to be withdrawn from the strategy; 0 - withdraw all
  /// @param strategy_ Address of the strategy
  /// @return resultAmount Amount of liquidity that should be withdrawn from the pool, cannot exceed depositorLiquidity
  /// @return amountsToConvertOut Amounts of {tokens} that should be converted to the main asset
  function getLiquidityAmount(
    uint targetAmount_,
    address strategy_,
    address[] memory tokens,
    uint indexAsset,
    ITetuConverter converter,
    uint investedAssets,
    uint depositorLiquidity
  ) external returns (
    uint resultAmount,
    uint[] memory amountsToConvertOut
  ) {
    bool all = targetAmount_ == 0;

    uint len = tokens.length;
    amountsToConvertOut = new uint[](len);
    for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
      if (i == indexAsset) continue;

      uint balance = IERC20(tokens[i]).balanceOf(address(this));
      if (balance != 0) {
        // let's estimate collateral that we received back after repaying balance-amount
        (uint expectedCollateral,) = converter.quoteRepay(strategy_, tokens[indexAsset], tokens[i], balance);

        if (all || targetAmount_ != 0) {
          // We always repay WHOLE available balance-amount even if it gives us much more amount then we need.
          // We cannot repay a part of it because converter doesn't allow to know
          // what amount should be repaid to get given amount of collateral.
          // And it's too dangerous to assume that we can calculate this amount
          // by reducing balance-amount proportionally to expectedCollateral/targetAmount_
          amountsToConvertOut[i] = balance;
        }

        targetAmount_ = targetAmount_ > expectedCollateral
          ? targetAmount_ - expectedCollateral
          : 0;

        investedAssets = investedAssets > expectedCollateral
          ? investedAssets - expectedCollateral
          : 0;
      }
    }

    uint liquidityRatioOut = all || investedAssets == 0
      ? 1e18
      : ((targetAmount_ == 0)
        ? 0
        : 1e18
        * 101 // add 1% on top...
        * targetAmount_ / investedAssets // a part of amount that we are going to withdraw
        / 100 // .. add 1% on top
      );

    resultAmount = liquidityRatioOut != 0
      ? Math.min(liquidityRatioOut * depositorLiquidity / 1e18, depositorLiquidity)
      : 0;
  }

  /// @notice Claim rewards from tetuConverter, generate result list of all available rewards and airdrops
  /// @dev The post-processing is rewards conversion to the main asset
  /// @param tokens_ tokens received from {_depositorPoolAssets}
  /// @param rewardTokens_ List of rewards claimed from the internal pool
  /// @param rewardTokens_ Amounts of rewards claimed from the internal pool
  /// @param tokensOut List of available rewards - not zero amounts, reward tokens don't repeat
  /// @param amountsOut Amounts of available rewards
  function claimConverterRewards(
    ITetuConverter converter_,
    address[] memory tokens_,
    address[] memory rewardTokens_,
    uint[] memory rewardAmounts_,
    uint[] memory balancesBefore
  ) external returns (
    address[] memory tokensOut,
    uint[] memory amountsOut
  ) {
    // Rewards from TetuConverter
    (address[] memory tokensTC, uint[] memory amountsTC) = converter_.claimRewards(address(this));

    // Join arrays and recycle tokens
    (tokensOut, amountsOut) = TokenAmountsLib.combineArrays(
      rewardTokens_, rewardAmounts_,
      tokensTC, amountsTC,
      // by default, depositor assets have zero amounts here
      tokens_, new uint[](tokens_.length)
    );

    // set fresh balances for depositor tokens
    uint len = tokensOut.length;
    for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
      for (uint j; j < tokens_.length; j = AppLib.uncheckedInc(j)) {
        if (tokensOut[i] == tokens_[j]) {
          amountsOut[i] = IERC20(tokens_[j]).balanceOf(address(this)) - balancesBefore[j];
        }
      }
    }

    // filter zero amounts out
    (tokensOut, amountsOut) = TokenAmountsLib.filterZeroAmounts(tokensOut, amountsOut);
  }

  /// @notice Send given amount of underlying to the insurance
  /// @param strategyBalance Total strategy balance = balance of underlying + current invested assets amount
  /// @return Amount of underlying sent to the insurance
  function sendToInsurance(address asset, uint amount, address splitter, uint strategyBalance) external returns (uint) {
    uint amountToSend = Math.min(amount, IERC20(asset).balanceOf(address(this)));
    if (amountToSend != 0) {
      // max amount that can be send to insurance is limited by PRICE_CHANGE_PROFIT_TOLERANCE

      // Amount limitation should be implemented in the same way as in StrategySplitterV2._coverLoss
      // Revert or cutting amount in both cases

      // amountToSend = Math.min(amountToSend, PRICE_CHANGE_PROFIT_TOLERANCE * strategyBalance / 100_000);
      require(strategyBalance != 0, AppErrors.ZERO_BALANCE);
      require(amountToSend <= PRICE_CHANGE_PROFIT_TOLERANCE * strategyBalance / 100_000, AppErrors.EARNED_AMOUNT_TOO_HIGH);
      IERC20(asset).safeTransfer(address(ITetuVaultV2(ISplitter(splitter).vault()).insurance()), amountToSend);
    }
    return amountToSend;
  }

  //region ---------------------------------------- Setters
  function checkPerformanceFeeRatioChanged(address controller, uint ratio_) external {
    StrategyLib.onlyOperators(controller);
    require(ratio_ <= DENOMINATOR, StrategyLib.WRONG_VALUE);
    emit OnChangePerformanceFeeRatio(ratio_);
  }

  function checkReinvestThresholdPercentChanged(address controller, uint percent_) external {
    StrategyLib.onlyOperators(controller);
    require(percent_ <= DENOMINATOR, StrategyLib.WRONG_VALUE);
    emit ReinvestThresholdPercentChanged(percent_);
  }

  function checkLiquidationThresholdChanged(address controller, address token, uint amount) external {
    StrategyLib.onlyOperators(controller);
    emit LiquidationThresholdChanged(token, amount);
  }
  //endregion ---------------------------------------- Setters

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Abstract base Depositor contract.
/// @notice Converter strategies should inherit xDepositor.
/// @notice All communication with external pools should be done at inherited contract
/// @author bogdoslav
abstract contract DepositorBase {

  /// @notice Returns pool assets
  function _depositorPoolAssets() internal virtual view returns (address[] memory assets);

  /// @notice Returns pool token proportions
  function _depositorPoolWeights() internal virtual view returns (uint[] memory weights, uint total);

  /// @notice Returns pool token reserves
  function _depositorPoolReserves() internal virtual view returns (uint[] memory reserves);

  /// @notice Returns depositor's pool shares / lp token amount
  function _depositorLiquidity() internal virtual view returns (uint);

  //// @notice Total amount of LP tokens in the depositor
  function _depositorTotalSupply() internal view virtual returns (uint);

  /// @notice Deposit given amount to the pool.
  /// @dev Depositor must care about tokens approval by itself.
  function _depositorEnter(uint[] memory amountsDesired_) internal virtual returns (
    uint[] memory amountsConsumed,
    uint liquidityOut
  );

  /// @notice Withdraw given lp amount from the pool.
  /// @param liquidityAmount Amount of liquidity to be converted
  ///                        If requested liquidityAmount >= invested, then should make full exit.
  /// @return amountsOut The order of amounts is the same as in {_depositorPoolAssets}
  function _depositorExit(uint liquidityAmount) internal virtual returns (uint[] memory amountsOut);

  /// @notice Quotes output for given lp amount from the pool.
  /// @dev Write function with read-only behavior. BalanceR's depositor requires not-view.
  /// @param liquidityAmount Amount of liquidity to be converted
  ///                        If requested liquidityAmount >= invested, then should make full exit.
  /// @return amountsOut The order of amounts is the same as in {_depositorPoolAssets}
  function _depositorQuoteExit(uint liquidityAmount) internal virtual returns (uint[] memory amountsOut);

  /// @dev If pool supports emergency withdraw need to call it for emergencyExit()
  /// @return amountsOut The order of amounts is the same as in {_depositorPoolAssets}
  function _depositorEmergencyExit() internal virtual returns (uint[] memory amountsOut) {
    return _depositorExit(_depositorLiquidity());
  }

  /// @notice Claim all possible rewards.
  /// @return rewardTokens Claimed token addresses
  /// @return rewardAmounts Claimed token amounts
  /// @return depositorBalancesBefore Must have the same length as _depositorPoolAssets and represent balances before claim in the same order
  function _depositorClaimRewards() internal virtual returns (
    address[] memory rewardTokens,
    uint[] memory rewardAmounts,
    uint[] memory depositorBalancesBefore
  );
}