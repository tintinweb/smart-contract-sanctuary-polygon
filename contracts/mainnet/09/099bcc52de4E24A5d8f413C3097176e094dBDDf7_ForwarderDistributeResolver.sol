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

  function doHardWork() external;

  function investAll() external;

  // **************** VIEWS ***************

  function asset() external view returns (address);

  function vault() external view returns (address);

  function totalAssets() external view returns (uint256);

  function isHardWorking() external view returns (bool);

  function strategies(uint i) external view returns (address);

  function strategiesLength() external view returns (uint);

  function HARDWORK_DELAY() external view returns(uint);

  function lastHardWorks(address strategy) external view returns(uint);

  function pausedStrategies(address strategy) external view returns(bool);

  function pauseInvesting(address strategy) external;

  function continueInvesting(address strategy, uint apr) external;

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

pragma solidity 0.8.17;


library StringLib {

  /// @dev Inspired by OraclizeAPI's implementation - MIT license
  ///      https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
  function toString(uint value) external pure returns (string memory) {
    return _toString(value);
  }

  function _toString(uint value) internal pure returns (string memory) {
    if (value == 0) {
      return "0";
    }
    uint temp = value;
    uint digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }

  function toAsciiString(address x) external pure returns (string memory) {
    return _toAsciiString(x);
  }

  function _toAsciiString(address x) internal pure returns (string memory) {
    bytes memory s = new bytes(40);
    for (uint i = 0; i < 20; i++) {
      bytes1 b = bytes1(uint8(uint(uint160(x)) / (2 ** (8 * (19 - i)))));
      bytes1 hi = bytes1(uint8(b) / 16);
      bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
      s[2 * i] = _char(hi);
      s[2 * i + 1] = _char(lo);
    }
    return string(s);
  }

  function char(bytes1 b) external pure returns (bytes1 c) {
    return _char(b);
  }

  function _char(bytes1 b) internal pure returns (bytes1 c) {
    if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
    else return bytes1(uint8(b) + 0x57);
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

import "../interfaces/ITetuVaultV2.sol";
import "../interfaces/IForwarder.sol";
import "../interfaces/IController.sol";
import "../interfaces/ITetuLiquidator.sol";
import "../proxy/ControllableV3.sol";
import "./../lib/StringLib.sol";

/// @title Gelato resolver for distribute pending tokens in ForwarderV3
/// @author belbix
contract ForwarderDistributeResolver is ControllableV3 {
  // --- CONSTANTS ---

  string public constant VERSION = "1.0.2";
  uint public constant DELAY_RATE_DENOMINATOR = 100_000;

  // --- VARIABLES ---

  address public owner;
  address public pendingOwner;
  uint public delay;
  uint public maxGas;
  uint public maxCallsPerCall;

  mapping(address => uint) public delayRate;
  mapping(address => uint) public lastCallPerVault;
  mapping(address => bool) public operators;
  mapping(address => bool) public excludedVaults;
  uint public lastCall;
  IForwarder public forwarder;
  ITetuLiquidator public liquidator;
  address public tetuToken;

  // --- INIT ---

  function init(address controller_) external initializer {
    ControllableV3.__Controllable_init(controller_);

    owner = msg.sender;
    delay = 1 days;
    maxGas = 200 gwei;
    maxCallsPerCall = 5;
    forwarder = IForwarder(IController(controller_).forwarder());
    liquidator = ITetuLiquidator(IController(controller_).liquidator());
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "!owner");
    _;
  }

  // --- OWNER FUNCTIONS ---

  function offerOwnership(address value) external onlyOwner {
    pendingOwner = value;
  }

  function acceptOwnership() external {
    require(msg.sender == pendingOwner, "!pendingOwner");
    owner = pendingOwner;
    pendingOwner = address(0);
  }

  function setDelay(uint value) external onlyOwner {
    delay = value;
  }

  function setMaxGas(uint value) external onlyOwner {
    maxGas = value;
  }

  function setMaxCallsPerCall(uint value) external onlyOwner {
    maxCallsPerCall = value;
  }

  function setDelayRate(address[] memory _vaults, uint value) external onlyOwner {
    for (uint i; i < _vaults.length; ++i) {
      delayRate[_vaults[i]] = value;
    }
  }

  function changeOperatorStatus(address operator, bool status) external onlyOwner {
    operators[operator] = status;
  }

  function changeVaultExcludeStatus(address[] memory _vaults, bool status) external onlyOwner {
    for (uint i; i < _vaults.length; ++i) {
      excludedVaults[_vaults[i]] = status;
    }
  }

  // --- MAIN LOGIC ---

  function getLastCall(address vault) public view returns (uint lastCallTimestamp) {
    return lastCallPerVault[vault];
  }

  function isReadyToDistribute(address vault, IForwarder _forwarder, ITetuLiquidator _liquidator, address tetu, uint threshold) public view returns (bool) {
    uint rtLength = _forwarder.tokenPerDestinationLength(vault);
    for (uint i; i < rtLength; ++i) {
      address rt = _forwarder.tokenPerDestinationAt(vault, i);
      uint rtAmount = _forwarder.amountPerDestination(rt, vault);
      if (_liquidator.getPrice(rt, tetu, rtAmount) > threshold) {
        return true;
      }
    }
    return false;
  }

  function call(address[] memory _vaults) external returns (uint amountOfCalls) {
    require(operators[msg.sender], "!operator");

    uint _maxHwPerCall = maxCallsPerCall;
    uint vaultsLength = _vaults.length;
    uint counter;
    IForwarder _forwarder = forwarder;
    for (uint i; i < vaultsLength; ++i) {
      address vault = _vaults[i];

      try _forwarder.distributeAll(vault) {
        lastCallPerVault[vault] = block.timestamp;
      } catch Error(string memory _err) {
        revert(string(abi.encodePacked("Vault error: 0x", StringLib._toAsciiString(vault), " ", _err)));
      } catch (bytes memory _err) {
        revert(string(abi.encodePacked("Vault low-level error: 0x", StringLib._toAsciiString(vault), " ", string(_err))));
      }
      counter++;
      if (counter >= _maxHwPerCall) {
        break;
      }
    }

    lastCall = block.timestamp;
    return counter;
  }

  function maxGasAdjusted() public view returns (uint) {
    uint _maxGas = maxGas;

    uint diff = block.timestamp - lastCall;
    uint multiplier = diff * 100 / 1 days;
    return _maxGas + _maxGas * multiplier / 100;
  }

  function checker() external view returns (bool canExec, bytes memory execPayload) {
    if (tx.gasprice > maxGasAdjusted()) {
      return (false, abi.encodePacked("Too high gas: ", StringLib._toString(tx.gasprice / 1e9)));
    }

    IController _controller = IController(controller());
    uint _delay = delay;
    uint vaultsLength = _controller.vaultsListLength();
    address[] memory _vaults = new address[](vaultsLength);
    IForwarder _forwarder = forwarder;
    ITetuLiquidator _liquidator = liquidator;
    address tetu = _forwarder.tetu();
    // use double threshold for not so frequent calls, assume distribution should be called by hard works
    uint threshold = _forwarder.tetuThreshold() * 2;
    uint counter;
    for (uint i; i < vaultsLength; ++i) {
      address vault = _controller.vaults(i);
      if (!excludedVaults[vault] && isReadyToDistribute(vault, _forwarder, _liquidator, tetu, threshold)) {
        uint delayAdjusted = _delay;
        uint _delayRate = delayRate[vault];
        if (_delayRate != 0) {
          delayAdjusted = _delay * _delayRate / DELAY_RATE_DENOMINATOR;
        }

        if (getLastCall(vault) + delayAdjusted < block.timestamp) {
          _vaults[i] = vault;
          counter++;
        }
      }
    }
    if (counter == 0) {
      return (false, bytes("No ready vaults"));
    } else {
      address[] memory vaultsResult = new address[](counter);
      uint j;
      for (uint i; i < vaultsLength; ++i) {
        if (_vaults[i] != address(0)) {
          vaultsResult[j] = _vaults[i];
          ++j;
        }
      }
      return (true, abi.encodeWithSelector(ForwarderDistributeResolver.call.selector, vaultsResult));
    }
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