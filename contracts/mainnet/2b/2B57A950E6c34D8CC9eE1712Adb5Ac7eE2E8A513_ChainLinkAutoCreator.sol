// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice config of the registry
 * @dev only used in params and return values
 * @member paymentPremiumPPB payment premium rate oracles receive on top of
 * being reimbursed for gas, measured in parts per billion
 * @member flatFeeMicroLink flat fee paid to oracles for performing upkeeps,
 * priced in MicroLink; can be used in conjunction with or independently of
 * paymentPremiumPPB
 * @member blockCountPerTurn number of blocks each oracle has during their turn to
 * perform upkeep before it will be the next keeper's turn to submit
 * @member checkGasLimit gas limit when checking for upkeep
 * @member stalenessSeconds number of seconds that is allowed for feed data to
 * be stale before switching to the fallback pricing
 * @member gasCeilingMultiplier multiplier to apply to the fast gas feed price
 * when calculating the payment ceiling for keepers
 * @member minUpkeepSpend minimum LINK that an upkeep must spend before cancelling
 * @member maxPerformGas max executeGas allowed for an upkeep on this registry
 * @member fallbackGasPrice gas price used if the gas price feed is stale
 * @member fallbackLinkPrice LINK price used if the LINK price feed is stale
 * @member transcoder address of the transcoder contract
 * @member registrar address of the registrar contract
 */
struct Config {
  uint32 paymentPremiumPPB;
  uint32 flatFeeMicroLink; // min 0.000001 LINK, max 4294 LINK
  uint24 blockCountPerTurn;
  uint32 checkGasLimit;
  uint24 stalenessSeconds;
  uint16 gasCeilingMultiplier;
  uint96 minUpkeepSpend;
  uint32 maxPerformGas;
  uint256 fallbackGasPrice;
  uint256 fallbackLinkPrice;
  address transcoder;
  address registrar;
}

/**
 * @notice config of the registry
 * @dev only used in params and return values
 * @member nonce used for ID generation
 * @ownerLinkBalance withdrawable balance of LINK by contract owner
 * @numUpkeeps total number of upkeeps on the registry
 */
struct State {
  uint32 nonce;
  uint96 ownerLinkBalance;
  uint256 expectedLinkBalance;
  uint256 numUpkeeps;
}

interface KeeperRegistryBaseInterface {
  function registerUpkeep(
    address target,
    uint32 gasLimit,
    address admin,
    bytes calldata checkData
  ) external returns (uint256 id);

  function performUpkeep(uint256 id, bytes calldata performData) external returns (bool success);

  function cancelUpkeep(uint256 id) external;
  
  function withdrawFunds(uint256 id, address to) external;

  function addFunds(uint256 id, uint96 amount) external;

  function setUpkeepGasLimit(uint256 id, uint32 gasLimit) external;

  function getMinBalanceForUpkeep(uint256 id) external view returns (uint96 minBalance);

  function getUpkeep(uint256 id)
    external
    view
    returns (
      address target,
      uint32 executeGas,
      bytes memory checkData,
      uint96 balance,
      address lastKeeper,
      address admin,
      uint64 maxValidBlocknumber,
      uint96 amountSpent
    );

  function getActiveUpkeepIDs(uint256 startIndex, uint256 maxCount) external view returns (uint256[] memory);

  function getKeeperInfo(address query)
    external
    view
    returns (
      address payee,
      bool active,
      uint96 balance
    );

  function getState()
    external
    view
    returns (
      State memory,
      Config memory,
      address[] memory
    );
}

/**
 * @dev The view methods are not actually marked as view in the implementation
 * but we want them to be easily queried off-chain. Solidity will not compile
 * if we actually inherit from this interface, so we document it here.
 */
interface KeeperRegistryInterface is KeeperRegistryBaseInterface {
  function checkUpkeep(uint256 upkeepId, address from)
    external
    view
    returns (
      bytes memory performData,
      uint256 maxLinkPayment,
      uint256 gasLimit,
      int256 gasWei,
      int256 linkEth
    );
}

interface KeeperRegistryExecutableInterface is KeeperRegistryBaseInterface {
  function checkUpkeep(uint256 upkeepId, address from)
    external
    returns (
      bytes memory performData,
      uint256 maxLinkPayment,
      uint256 gasLimit,
      uint256 adjustedGasWei,
      uint256 linkEth
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../../../interfaces/ISiloManager.sol";
import "../../../interfaces/ISiloManagerFactory.sol";
import {ManagerInfo} from "./interfaces/IAutoCreator.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract BaseAutoCreator is Ownable {
    uint256 public autoType = 1;
    address public managerFactory;

    constructor(uint256 _autoType, address _factory) {
        autoType = _autoType;
        managerFactory = _factory;
    }

    function createAutoManager(
        bytes memory inputData
    ) public payable virtual returns (address) {}

    function addFund(bytes memory inputData) public payable virtual {}

    function cancelAuto(bytes memory inputData) public virtual returns (bool) {}

    function withdrawFund(
        bytes memory inputData
    ) public virtual returns (bool) {}

    function getTotalManagerInfo(
        address manager
    ) external view virtual returns (ManagerInfo memory) {}

    function managerApproved(
        address _user
    ) external view virtual returns (bool) {}

    function getAutoManagerHighBalance(
        address _manager
    ) external view virtual returns (uint256) {}

    function getAutoManagerBalance(
        address _manager
    ) external view virtual returns (uint256) {}

    function getAutoMinThreshold(
        address _manager
    ) external view virtual returns (uint256) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import "../../../interfaces/IPegSwap.sol";
import {KeeperRegistryInterface, State, Config} from "../../../chainlink/interfaces/KeeperRegistryInterface.sol";
import "../../../chainlink/interfaces/LinkTokenInterface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import "./BaseAutoCreator.sol";

contract ChainLinkAutoCreator is BaseAutoCreator {
    address public constant ERC20_LINK_ADDRESS =
        0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39;
    address public constant ERC677_LINK_ADDRESS =
        0xb0897686c545045aFc77CF20eC7A532E3120E0F1;
    address public constant PEGSWAP_ADDRESS =
        0xAA1DC356dc4B18f30C347798FD5379F3D77ABC5b;

    address public REGISTRAR_ADDRESS =
        0xDb8e8e2ccb5C033938736aa89Fe4fa1eDfD15a1d;

    IERC20 ERC20Link = IERC20(ERC20_LINK_ADDRESS);

    LinkTokenInterface ERC677Link = LinkTokenInterface(ERC677_LINK_ADDRESS);
    IPegSwap PegSwap = IPegSwap(PEGSWAP_ADDRESS);

    address public keeperRegistry;
    KeeperRegistryInterface Registry;
    address public managerImplementation;

    uint256 public minFundingAmount = 5000000000000000000; //5 Link

    uint64 private constant UINT64_MAX = 2 ** 64 - 1;
    address public self;

    constructor(
        address _keeperRegistry,
        address _managerImplementation,
        address factory
    ) BaseAutoCreator(1, factory) {
        keeperRegistry = _keeperRegistry;
        Registry = KeeperRegistryInterface(_keeperRegistry);
        (, Config memory _config, ) = Registry.getState();
        REGISTRAR_ADDRESS = _config.registrar;

        managerImplementation = _managerImplementation;
        self = address(this);

        ERC20Link = IERC20(ERC20_LINK_ADDRESS);

        ERC677Link = LinkTokenInterface(ERC677_LINK_ADDRESS);
        PegSwap = IPegSwap(PEGSWAP_ADDRESS);
    }

    function udpateManager(address _manager) external onlyOwner {
        managerImplementation = _manager;
    }

    function adjustMinFundingAmount(uint256 _amount) external onlyOwner {
        minFundingAmount = _amount;
    }

    function updateCurrentKeepersRegistry(
        address _registry
    ) external onlyOwner {
        keeperRegistry = _registry;
        Registry = KeeperRegistryInterface(_registry);
        (, Config memory _config, ) = Registry.getState();
        REGISTRAR_ADDRESS = _config.registrar;
    }

    function createAutoManager(
        bytes memory inputData
    ) public payable override returns (address) {
        require(msg.sender == managerFactory, "not factory");

        (uint256 _amount, address owner) = abi.decode(
            inputData,
            (uint256, address)
        );

        uint256 count = ISiloManagerFactory(managerFactory).managerCount(
            autoType
        );

        require(_amount >= minFundingAmount, "Amount too small");
        address manager = Clones.clone(managerImplementation);

        ISiloManager(manager).initialize(managerFactory, self, owner);

        uint256 beforeBalance = ERC677Link.balanceOf(address(this));

        //swap ERC20 Link if need be
        if (ERC677Link.balanceOf(owner) < _amount) {
            //if caller does not own enough ERC677 Link, then swap ERC20 Link for ERC677 Link
            SafeERC20.safeTransferFrom(
                ERC20Link,
                owner,
                address(this),
                _amount
            );
            ERC20Link.approve(PEGSWAP_ADDRESS, _amount);
            PegSwap.swap(_amount, ERC20_LINK_ADDRESS, ERC677_LINK_ADDRESS);
        } else {
            SafeERC20.safeTransferFrom(
                IERC20(ERC677_LINK_ADDRESS),
                owner,
                address(this),
                _amount
            );
        }

        //create upkeep
        string memory name = string(
            abi.encodePacked("Silo Manager: ", Strings.toString(count))
        );
        uint96 amount = uint96(
            ERC677Link.balanceOf(address(this)) - beforeBalance
        );

        bytes memory data = abi.encodeWithSelector(
            bytes4(
                keccak256(
                    "register(string,bytes,address,uint32,address,bytes,uint96,uint8,address)"
                )
            ),
            name,
            hex"",
            manager,
            5000000,
            address(this),
            hex"",
            amount,
            144,
            address(this)
        );

        (State memory state, , ) = Registry.getState();
        uint256 numUpkeeps = state.numUpkeeps;

        ERC677Link.transferAndCall(REGISTRAR_ADDRESS, amount, data);
        (state, , ) = Registry.getState();

        if (state.numUpkeeps > numUpkeeps) {
            uint256[] memory ids = Registry.getActiveUpkeepIDs(numUpkeeps, 0);
            uint256 maxCount = ids.length;

            for (uint256 idx; idx < maxCount; ) {
                uint256 id = ids[maxCount - idx - 1];
                (address target, , , , , , , ) = Registry.getUpkeep(id);
                if (target == manager) {
                    ISiloManager(manager).setUpkeepId(id);
                    return manager;
                }
                unchecked {
                    idx++;
                }
            }
        }
        return address(0);
    }

    function addFund(bytes memory inputData) public payable override {
        require(msg.sender == managerFactory, "not factory");

        (address manager, uint256 _amount) = abi.decode(
            inputData,
            (address, uint256)
        );

        address owner = ISiloManager(manager).owner();

        uint256 id = ISiloManager(manager).upkeepId();

        require(id != 0, "Manager not approved");

        //swap ERC20 Link if need be
        if (ERC677Link.balanceOf(owner) < _amount) {
            //if caller does not own enough ERC677 Link, then swap ERC20 Link for ERC677 Link
            SafeERC20.safeTransferFrom(
                ERC20Link,
                owner,
                address(this),
                _amount
            );
            ERC20Link.approve(PEGSWAP_ADDRESS, _amount);
            PegSwap.swap(_amount, ERC20_LINK_ADDRESS, ERC677_LINK_ADDRESS);
        } else {
            SafeERC20.safeTransferFrom(
                IERC20(ERC677_LINK_ADDRESS),
                owner,
                address(this),
                _amount
            );
        }
        ERC677Link.approve(keeperRegistry, _amount);
        Registry.addFunds(id, uint96(_amount));
    }

    function cancelAuto(bytes memory inputData) public override returns (bool) {
        require(msg.sender == managerFactory, "not factory");

        address manager = abi.decode(inputData, (address));

        uint256 id = ISiloManager(manager).upkeepId();
        (, , , , , , uint256 maxValidBlock, ) = Registry.getUpkeep(id);
        require(maxValidBlock == UINT64_MAX, "Gravity: Upkeep cancelled");

        Registry.cancelUpkeep(id);

        return false;
    }

    //have it swap ERC677 Link to ERC20
    function withdrawFund(
        bytes memory inputData
    ) public override returns (bool) {
        require(msg.sender == managerFactory, "not factory");

        (address manager, bool _linkType) = abi.decode(
            inputData,
            (address, bool)
        );

        require(manager != address(0), "Gravity : wrong manger");

        address owner = ISiloManager(manager).owner();

        uint256 id = ISiloManager(manager).upkeepId();
        (, , , uint96 balance, , , uint256 maxValidBlock, ) = Registry
            .getUpkeep(id);
        require(
            block.number > maxValidBlock,
            "Gravity: Valid Block not reached"
        );

        if (_linkType) {
            //user wants erc677 link
            Registry.withdrawFunds(id, owner);
        } else {
            //user wants erc20 link
            uint256 beforeBalance = ERC677Link.balanceOf(address(this));
            Registry.withdrawFunds(id, address(this));
            uint256 currentBalance = ERC677Link.balanceOf(address(this));
            ERC677Link.approve(PEGSWAP_ADDRESS, uint256(balance));
            PegSwap.swap(
                currentBalance - beforeBalance,
                ERC677_LINK_ADDRESS,
                ERC20_LINK_ADDRESS
            );
            SafeERC20.safeTransfer(
                ERC20Link,
                owner,
                currentBalance - beforeBalance
            );
        }

        return true;
    }

    function getUpkeep(
        uint256 _id
    )
        external
        view
        returns (
            address target,
            uint32 executeGas,
            bytes memory checkData,
            uint96 balance,
            address lastKeeper,
            address admin,
            uint64 maxValidBlocknumber,
            uint96 amountSpent
        )
    {
        (
            target,
            executeGas,
            checkData,
            balance,
            lastKeeper,
            admin,
            maxValidBlocknumber,
            amountSpent
        ) = Registry.getUpkeep(_id);
    }

    function fundsWithdrawable(address _user) external view returns (bool) {
        address manager = ISiloManagerFactory(managerFactory).userToManager(
            _user,
            autoType
        );
        if (manager == address(0)) {
            return false;
        }

        uint256 id = ISiloManager(manager).upkeepId();
        if (id == 0) {
            return false;
        }

        (, , , , , , uint256 maxValidBlock, ) = Registry.getUpkeep(id);
        return block.number > maxValidBlock;
    }

    function getUsersUpkeepId(address _user) public view returns (uint256 id) {
        address manager = ISiloManagerFactory(managerFactory).userToManager(
            _user,
            autoType
        );
        if (manager != address(0)) {
            id = ISiloManager(manager).upkeepId();
        }
    }

    function checkRegistryState()
        external
        view
        returns (
            State memory state,
            Config memory config,
            address[] memory keepers
        )
    {
        (state, config, keepers) = Registry.getState();
    }

    function getKeeperRegistry() public view returns (address) {
        return keeperRegistry;
    }

    function getTarget(uint256 _id) public view returns (address target) {
        (target, , , , , , , ) = Registry.getUpkeep(_id);
    }

    function getBalance(uint256 _id) public view returns (uint96 balance) {
        (, , , balance, , , , ) = Registry.getUpkeep(_id);
    }

    function getAutoManagerBalance(
        address manager
    ) public view override returns (uint256) {
        if (manager == address(0)) {
            //_user doesn't have a manager
            return 0;
        }
        uint256 id = ISiloManager(manager).upkeepId();
        (address target, , , uint96 balance, , , , ) = Registry.getUpkeep(id);
        if (target != address(manager)) {
            //upkeep is not approved
            return 0;
        }
        return balance;
    }

    function getMinBalance(uint256 _id) public view returns (uint96 balance) {
        balance = Registry.getMinBalanceForUpkeep(_id);
    }

    function getAutoMinThreshold(
        address manager
    ) public view override returns (uint256 balance) {
        if (manager == address(0)) {
            return 0;
        }
        uint256 id = ISiloManager(manager).upkeepId();
        balance = Registry.getMinBalanceForUpkeep(id);
    }

    function getAutoManagerHighBalance(
        address manager
    ) public view override returns (uint256 balance) {
        if (manager != address(0)) {
            ISiloManager Manager = ISiloManager(manager);
            uint256 id = Manager.upkeepId();
            if (id != 0) {
                balance =
                    (Registry.getMinBalanceForUpkeep(id) *
                        Manager.getRiskBuffer()) /
                    uint96(10000);
            }
        }
    }

    function managerApproved(
        address _user
    ) external view override returns (bool) {
        address manager = ISiloManagerFactory(managerFactory).userToManager(
            _user,
            autoType
        );
        if (manager == address(0)) {
            return false;
        }
        uint256 id = ISiloManager(manager).upkeepId();
        (address target, , , , , , uint64 maxValidBlocknumber, ) = Registry
            .getUpkeep(id);
        bool isAcitve = maxValidBlocknumber == UINT64_MAX;
        return target == manager && isAcitve;
    }

    function managerCanceled(address _user) public view returns (bool) {
        address manager = ISiloManagerFactory(managerFactory).userToManager(
            _user,
            autoType
        );

        if (manager == address(0)) {
            return false;
        }

        uint256 id = ISiloManager(manager).upkeepId();
        (, , , , , , uint64 maxValidBlocknumber, ) = Registry.getUpkeep(id);
        bool canceled = maxValidBlocknumber != UINT64_MAX &&
            maxValidBlocknumber != 0;
        return canceled;
    }

    function getTotalManagerInfo(
        address manager
    ) external view override returns (ManagerInfo memory info) {
        if (manager != address(0)) {
            ISiloManager Manager = ISiloManager(manager);
            uint256 id = Manager.upkeepId();
            if (id != 0) {
                uint256 minimumBalance = getMinBalance(id);

                (uint96 minRisk, uint96 minRejoin) = Manager.getMinBuffers();

                (, , , uint96 balance, , , uint256 maxValidBlock, ) = Registry
                    .getUpkeep(id);

                bool withdrawable = block.number > maxValidBlock;

                bool canceled = maxValidBlock != UINT64_MAX &&
                    maxValidBlock != 0;
                uint96 riskBuffer = Manager.getRiskBuffer();

                info = ManagerInfo({
                    upkeepId: id,
                    manager: manager,
                    currentBalance: balance,
                    minimumBalance: minimumBalance,
                    riskAdjustedBalance: (minimumBalance * riskBuffer) /
                        uint96(10000),
                    riskBuffer: riskBuffer,
                    rejoinBuffer: Manager.getRejoinBuffer(),
                    minRisk: minRisk,
                    minRejoin: minRejoin,
                    autoTopup: Manager.autoTopup(),
                    topupThreshold: Manager.addFundsThreshold(),
                    fundsWithdrawable: withdrawable,
                    managerCanceled: canceled
                });
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct ManagerInfo {
    address manager;
    uint256 upkeepId;
    uint256 currentBalance;
    uint256 minimumBalance;
    uint256 riskAdjustedBalance;
    uint96 riskBuffer;
    uint96 rejoinBuffer;
    uint96 minRisk;
    uint96 minRejoin;
    bool autoTopup;
    uint256 topupThreshold;
    bool fundsWithdrawable;
    bool managerCanceled;
}

interface IAutoCreator {
    function getAutoManagerHighBalance(
        address _manager
    ) external view returns (uint256);

    function getAutoManagerBalance(
        address _manager
    ) external view returns (uint256);

    function getAutoMinThreshold(
        address _manager
    ) external view returns (uint256);

    function managerApproved(address _user) external view returns (bool);

    function getTotalManagerInfo(
        address _manager
    ) external view returns (ManagerInfo memory info);

    function autoType() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPegSwap{
    function swap(uint256 amount, address source, address target) external;
    function getSwappableAmount(address source, address target) external view returns(uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

enum AutoStatus {
    NOT,
    APPROVED,
    MANUAL,
    NORMAL,
    HIGH
}

interface ISiloManager {
    function createUpkeep(address _owner, uint _amount) external;

    function setUpkeepId(uint id) external;

    function owner() external view returns (address);

    function upkeepId() external view returns (uint);

    function initialize(
        address _mangerFactory,
        address _creator,
        address _owner
    ) external;

    function getRiskBuffer() external view returns (uint96);

    function checkUpkeep(
        bytes calldata checkData
    ) external returns (bool, bytes memory);

    function setCustomRiskBuffer(uint96 _buffer) external;

    function setCustomRejoinBuffer(uint96 _buffer) external;

    function getRejoinBuffer() external view returns (uint96);

    function getMinBuffers()
        external
        view
        returns (uint96 minRisk, uint96 minRejoin);

    function autoTopup() external view returns (bool);

    function addFundsThreshold() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AutoStatus} from "./ISiloManager.sol";

interface ISiloManagerFactory {
    function checkManager(
        address _owner,
        address _manager,
        uint256 _autoType
    ) external view returns (bool);

    function userToManager(
        address _user,
        uint256 _autoType
    ) external view returns (address);

    function managerCount(uint256 _autoType) external view returns (uint256);

    function siloFactory() external view returns (address);

    function riskBuffer() external view returns (uint96);

    function rejoinBuffer() external view returns (uint96);

    function bufferPerSilo() external view returns (uint96);

    function getAutoCreator(uint256 _autoType) external view returns (address);

    function getAutoTypesSize() external view returns (uint256);

    function getAutoTypeAt(
        uint256 index
    ) external view returns (uint256 autoType, address creator);

    function getAutoStatus(
        address _user,
        uint256 _autoType
    ) external view returns (AutoStatus);
}