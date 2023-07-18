// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * by making the `nonReentrant` function external, and make it call a
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

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

import "./TypedMemView.sol";
import "../types/ScriptTypesEnum.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

library BitcoinHelper {

    using SafeCast for uint96;
    using SafeCast for uint256;

    using TypedMemView for bytes;
    using TypedMemView for bytes29;

    // The target at minimum Difficulty. Also the target of the genesis block
    uint256 internal constant DIFF1_TARGET = 0xffff0000000000000000000000000000000000000000000000000000;

    uint256 internal constant RETARGET_PERIOD = 2 * 7 * 24 * 60 * 60;  // 2 weeks in seconds
    uint256 internal constant RETARGET_PERIOD_BLOCKS = 2016;  // 2 weeks in blocks

    enum BTCTypes {
        Unknown,            // 0x0
        CompactInt,         // 0x1
        ScriptSig,          // 0x2 - with length prefix
        Outpoint,           // 0x3
        TxIn,               // 0x4
        IntermediateTxIns,  // 0x5 - used in vin parsing
        Vin,                // 0x6
        ScriptPubkey,       // 0x7 - with length prefix
        PKH,                // 0x8 - the 20-byte payload digest
        WPKH,               // 0x9 - the 20-byte payload digest
        WSH,                // 0xa - the 32-byte payload digest
        SH,                 // 0xb - the 20-byte payload digest
        OpReturnPayload,    // 0xc
        TxOut,              // 0xd
        IntermediateTxOuts, // 0xe - used in vout parsing
        Vout,               // 0xf
        Header,             // 0x10
        HeaderArray,        // 0x11
        MerkleNode,         // 0x12
        MerkleStep,         // 0x13
        MerkleArray         // 0x14
    }

    /// @notice             requires `memView` to be of a specified type
    /// @dev                passes if it is the correct type, errors if not
    /// @param memView      a 29-byte view with a 5-byte type
    /// @param t            the expected type (e.g. BTCTypes.Outpoint, BTCTypes.TxIn, etc)
    modifier typeAssert(bytes29 memView, BTCTypes t) {
        memView.assertType(uint40(t));
        _;
    }

    // Revert with an error message re: non-minimal VarInts
    function revertNonMinimal(bytes29 ref) private pure returns (string memory) {
        (, uint256 g) = TypedMemView.encodeHex(ref.indexUint(0, ref.len().toUint8()));
        string memory err = string(
            abi.encodePacked(
                "Non-minimal var int. Got 0x",
                uint144(g)
            )
        );
        revert(err);
    }

    /// @notice             reads a compact int from the view at the specified index
    /// @param memView      a 29-byte view with a 5-byte type
    /// @param _index       the index
    /// @return number      returns the compact int at the specified index
    function indexCompactInt(bytes29 memView, uint256 _index) internal pure returns (uint64 number) {
        uint256 flag = memView.indexUint(_index, 1);
        if (flag <= 0xfc) {
            return flag.toUint64();
        } else if (flag == 0xfd) {
            number = memView.indexLEUint(_index + 1, 2).toUint64();
            if (compactIntLength(number) != 3) {revertNonMinimal(memView.slice(_index, 3, 0));}
        } else if (flag == 0xfe) {
            number = memView.indexLEUint(_index + 1, 4).toUint64();
            if (compactIntLength(number) != 5) {revertNonMinimal(memView.slice(_index, 5, 0));}
        } else if (flag == 0xff) {
            number = memView.indexLEUint(_index + 1, 8).toUint64();
            if (compactIntLength(number) != 9) {revertNonMinimal(memView.slice(_index, 9, 0));}
        }
    }

    /// @notice         gives the total length (in bytes) of a CompactInt-encoded number
    /// @param number   the number as uint64
    /// @return         the compact integer length as uint8
    function compactIntLength(uint64 number) private pure returns (uint8) {
        if (number <= 0xfc) {
            return 1;
        } else if (number <= 0xffff) {
            return 3;
        } else if (number <= 0xffffffff) {
            return 5;
        } else {
            return 9;
        }
    }

    /// @notice             extracts the LE txid from an outpoint
    /// @param _outpoint    the outpoint
    /// @return             the LE txid
    function txidLE(bytes29 _outpoint) internal pure typeAssert(_outpoint, BTCTypes.Outpoint) returns (bytes32) {
        return _outpoint.index(0, 32);
    }

    /// @notice                      Calculates the required transaction Id from the transaction details
    /// @dev                         Calculates the hash of transaction details two consecutive times
    /// @param _version              Version of the transaction
    /// @param _vin                  Inputs of the transaction
    /// @param _vout                 Outputs of the transaction
    /// @param _locktime             Lock time of the transaction
    /// @return                      Transaction Id of the transaction (in LE form)
    function calculateTxId(
        bytes4 _version,
        bytes memory _vin,
        bytes memory _vout,
        bytes4 _locktime
    ) internal pure returns (bytes32) {
        bytes32 inputHash1 = sha256(abi.encodePacked(_version, _vin, _vout, _locktime));
        bytes32 inputHash2 = sha256(abi.encodePacked(inputHash1));
        return inputHash2;
    }

    /// @notice                      Reverts a Bytes32 input
    /// @param _input                Bytes32 input that we want to revert
    /// @return                      Reverted bytes32
    function reverseBytes32(bytes32 _input) private pure returns (bytes32) {
        bytes memory temp;
        bytes32 result;
        for (uint i = 0; i < 32; i++) {
            temp = abi.encodePacked(temp, _input[31-i]);
        }
        assembly {
            result := mload(add(temp, 32))
        }
        return result;
    }

    /// @notice                           Parses outpoint info from an input
    /// @dev                              Reverts if vin is null
    /// @param _vin                       The vin of a Bitcoin transaction
    /// @param _index                     Index of the input that we are looking at
    /// @return _txId                     Output tx id
    /// @return _outputIndex              Output tx index
    function extractOutpoint(
        bytes memory _vin, 
        uint _index
    ) internal pure returns (bytes32 _txId, uint _outputIndex) {
        bytes29 vin = tryAsVin(_vin.ref(uint40(BTCTypes.Unknown)));
        require(!vin.isNull(), "BitcoinHelper: vin is null");
        bytes29 input = indexVin(vin, _index);
        bytes29 _outpoint = outpoint(input);
        _txId = txidLE(_outpoint);
        _outputIndex = outpointIdx(_outpoint);
    }

    /// @notice             extracts the index as an integer from the outpoint
    /// @param _outpoint    the outpoint
    /// @return             the index
    function outpointIdx(bytes29 _outpoint) internal pure typeAssert(_outpoint, BTCTypes.Outpoint) returns (uint32) {
        return _outpoint.indexLEUint(32, 4).toUint32();
    }

    /// @notice          extracts the outpoint from an input
    /// @param _input    the input
    /// @return          the outpoint as a typed memory
    function outpoint(bytes29 _input) internal pure typeAssert(_input, BTCTypes.TxIn) returns (bytes29) {
        return _input.slice(0, 36, uint40(BTCTypes.Outpoint));
    }

    /// @notice           extracts the script sig from an input
    /// @param _input     the input
    /// @return           the script sig as a typed memory
    function scriptSig(bytes29 _input) internal pure typeAssert(_input, BTCTypes.TxIn) returns (bytes29) {
        uint64 scriptLength = indexCompactInt(_input, 36);
        return _input.slice(36, compactIntLength(scriptLength) + scriptLength, uint40(BTCTypes.ScriptSig));
    }

    /// @notice         determines the length of the first input in an array of inputs
    /// @param _inputs  the vin without its length prefix
    /// @return         the input length
    function inputLength(bytes29 _inputs) private pure typeAssert(_inputs, BTCTypes.IntermediateTxIns) returns (uint256) {
        uint64 scriptLength = indexCompactInt(_inputs, 36);
        return uint256(compactIntLength(scriptLength)) + uint256(scriptLength) + 36 + 4;
    }

    /// @notice         extracts the input at a specified index
    /// @param _vin     the vin
    /// @param _index   the index of the desired input
    /// @return         the desired input
    function indexVin(bytes29 _vin, uint256 _index) internal pure typeAssert(_vin, BTCTypes.Vin) returns (bytes29) {
        uint256 _nIns = uint256(indexCompactInt(_vin, 0));
        uint256 _viewLen = _vin.len();
        require(_index < _nIns, "Vin read overrun");

        uint256 _offset = uint256(compactIntLength(uint64(_nIns)));
        bytes29 _remaining;
        for (uint256 _i = 0; _i < _index; _i += 1) {
            _remaining = _vin.postfix(_viewLen - _offset, uint40(BTCTypes.IntermediateTxIns));
            _offset += inputLength(_remaining);
        }

        _remaining = _vin.postfix(_viewLen - _offset, uint40(BTCTypes.IntermediateTxIns));
        uint256 _len = inputLength(_remaining);
        return _vin.slice(_offset, _len, uint40(BTCTypes.TxIn));
    }

    /// @notice         extracts the value from an output
    /// @param _output  the output
    /// @return         the value
    function value(bytes29 _output) internal pure typeAssert(_output, BTCTypes.TxOut) returns (uint64) {
        return _output.indexLEUint(0, 8).toUint64();
    }

    /// @notice                   Finds the value of a specific output
    /// @dev                      Reverts if vout is null
    /// @param _vout              The vout of a Bitcoin transaction
    /// @param _index             Index of output
    /// @return _value            Value of the specified output
    function parseOutputValue(bytes memory _vout, uint _index) internal pure returns (uint64 _value) {
        bytes29 voutView = tryAsVout(_vout.ref(uint40(BTCTypes.Unknown)));
        require(!voutView.isNull(), "BitcoinHelper: vout is null");
        bytes29 output;
        output = indexVout(voutView, _index);
        _value = value(output);
    }

    /// @notice                   Finds total outputs value
    /// @dev                      Reverts if vout is null
    /// @param _vout              The vout of a Bitcoin transaction
    /// @return _totalValue       Total vout value
    function parseOutputsTotalValue(bytes memory _vout) internal pure returns (uint64 _totalValue) {
        bytes29 voutView = tryAsVout(_vout.ref(uint40(BTCTypes.Unknown)));
        require(!voutView.isNull(), "BitcoinHelper: vout is null");
        bytes29 output;

        // Finds total number of outputs
        uint _numberOfOutputs = uint256(indexCompactInt(voutView, 0));

        for (uint index = 0; index < _numberOfOutputs; index++) {
            output = indexVout(voutView, index);
            _totalValue = _totalValue + value(output);
        }
    }

    /// @notice                           Parses the BTC amount that has been sent to 
    ///                                   a specific script in a specific output
    /// @param _vout                      The vout of a Bitcoin transaction
    /// @param _voutIndex                 Index of the output that we are looking at
    /// @param _script                    Desired recipient script
    /// @param _scriptType                Type of the script (e.g. P2PK)
    /// @return bitcoinAmount             Amount of BTC have been sent to the _script
    function parseValueFromSpecificOutputHavingScript(
        bytes memory _vout,
        uint _voutIndex,
        bytes memory _script,
        ScriptTypes _scriptType
    ) internal pure returns (uint64 bitcoinAmount) {

        bytes29 voutView = tryAsVout(_vout.ref(uint40(BTCTypes.Unknown)));
        require(!voutView.isNull(), "BitcoinHelper: vout is null");
        bytes29 output = indexVout(voutView, _voutIndex);
        bytes29 _scriptPubkey = scriptPubkey(output);
        
        if (_scriptType == ScriptTypes.P2TR) {
            // note: first two bytes are OP_1 and Pushdata Bytelength. 
            // note: script hash length is 32.           
            bitcoinAmount = keccak256(_script) == keccak256(abi.encodePacked(_scriptPubkey.index(2, 32))) ? value(output) : 0;
        } else if (_scriptType == ScriptTypes.P2PK) {
            // note: first byte is Pushdata Bytelength. 
            // note: public key length is 32.           
            bitcoinAmount = keccak256(_script) == keccak256(abi.encodePacked(_scriptPubkey.index(1, 32))) ? value(output) : 0;
        } else if (_scriptType == ScriptTypes.P2PKH) { 
            // note: first three bytes are OP_DUP, OP_HASH160, Pushdata Bytelength. 
            // note: public key hash length is 20.         
            bitcoinAmount = keccak256(_script) == keccak256(abi.encodePacked(_scriptPubkey.indexAddress(3))) ? value(output) : 0;
        } else if (_scriptType == ScriptTypes.P2SH) {
            // note: first two bytes are OP_HASH160, Pushdata Bytelength
            // note: script hash length is 20.                      
            bitcoinAmount = keccak256(_script) == keccak256(abi.encodePacked(_scriptPubkey.indexAddress(2))) ? value(output) : 0;
        } else if (_scriptType == ScriptTypes.P2WPKH) {               
            // note: first two bytes are OP_0, Pushdata Bytelength
            // note: segwit public key hash length is 20. 
            bitcoinAmount = keccak256(_script) == keccak256(abi.encodePacked(_scriptPubkey.indexAddress(2))) ? value(output) : 0;
        } else if (_scriptType == ScriptTypes.P2WSH) {
            // note: first two bytes are OP_0, Pushdata Bytelength 
            // note: segwit script hash length is 32.           
            bitcoinAmount = keccak256(_script) == keccak256(abi.encodePacked(_scriptPubkey.index(2, 32))) ? value(output) : 0;
        }
        
    }

    /// @notice                           Parses the BTC amount of a transaction
    /// @dev                              Finds the BTC amount that has been sent to the locking script
    ///                                   Returns zero if no matching locking scrip is found
    /// @param _vout                      The vout of a Bitcoin transaction
    /// @param _lockingScript             Desired locking script
    /// @return bitcoinAmount             Amount of BTC have been sent to the _lockingScript
    function parseValueHavingLockingScript(
        bytes memory _vout,
        bytes memory _lockingScript
    ) internal view returns (uint64 bitcoinAmount) {
        // Checks that vout is not null
        bytes29 voutView = tryAsVout(_vout.ref(uint40(BTCTypes.Unknown)));
        require(!voutView.isNull(), "BitcoinHelper: vout is null");

        bytes29 output;
        bytes29 _scriptPubkey;
        
        // Finds total number of outputs
        uint _numberOfOutputs = uint256(indexCompactInt(voutView, 0));

        for (uint index = 0; index < _numberOfOutputs; index++) {
            output = indexVout(voutView, index);
            _scriptPubkey = scriptPubkey(output);

            if (
                keccak256(abi.encodePacked(_scriptPubkey.clone())) == keccak256(abi.encodePacked(_lockingScript))
            ) {
                bitcoinAmount = value(output);
                // Stops searching after finding the desired locking script
                break;
            }
        }
    }

    /// @notice                           Parses the BTC amount and the op_return of a transaction
    /// @dev                              Finds the BTC amount that has been sent to the locking script
    ///                                   Assumes that payload size is less than 76 bytes
    /// @param _vout                      The vout of a Bitcoin transaction
    /// @param _lockingScript             Desired locking script
    /// @return bitcoinAmount             Amount of BTC have been sent to the _lockingScript
    /// @return arbitraryData             Opreturn  data of the transaction
    function parseValueAndDataHavingLockingScriptSmallPayload(
        bytes memory _vout,
        bytes memory _lockingScript
    ) internal view returns (uint64 bitcoinAmount, bytes memory arbitraryData) {
        // Checks that vout is not null
        bytes29 voutView = tryAsVout(_vout.ref(uint40(BTCTypes.Unknown)));
        require(!voutView.isNull(), "BitcoinHelper: vout is null");

        bytes29 output;
        bytes29 _scriptPubkey;
        bytes29 _scriptPubkeyWithLength;
        bytes29 _arbitraryData;

        // Finds total number of outputs
        uint _numberOfOutputs = uint256(indexCompactInt(voutView, 0));

        for (uint index = 0; index < _numberOfOutputs; index++) {
            output = indexVout(voutView, index);
            _scriptPubkey = scriptPubkey(output);
            _scriptPubkeyWithLength = scriptPubkeyWithLength(output);
            _arbitraryData = opReturnPayloadSmall(_scriptPubkeyWithLength);

            // Checks whether the output is an arbitarary data or not
            if(_arbitraryData == TypedMemView.NULL) {
                // Output is not an arbitrary data
                if (
                    keccak256(abi.encodePacked(_scriptPubkey.clone())) == keccak256(abi.encodePacked(_lockingScript))
                ) {
                    bitcoinAmount = value(output);
                }
            } else {
                // Returns the whole bytes array
                arbitraryData = _arbitraryData.clone();
            }
        }
    }

    /// @notice                           Parses the BTC amount and the op_return of a transaction
    /// @dev                              Finds the BTC amount that has been sent to the locking script
    ///                                   Assumes that payload size is greater than 75 bytes
    /// @param _vout                      The vout of a Bitcoin transaction
    /// @param _lockingScript             Desired locking script
    /// @return bitcoinAmount             Amount of BTC have been sent to the _lockingScript
    /// @return arbitraryData             Opreturn  data of the transaction
    function parseValueAndDataHavingLockingScriptBigPayload(
        bytes memory _vout,
        bytes memory _lockingScript
    ) internal view returns (uint64 bitcoinAmount, bytes memory arbitraryData) {
        // Checks that vout is not null
        bytes29 voutView = tryAsVout(_vout.ref(uint40(BTCTypes.Unknown)));
        require(!voutView.isNull(), "BitcoinHelper: vout is null");

        bytes29 output;
        bytes29 _scriptPubkey;
        bytes29 _scriptPubkeyWithLength;
        bytes29 _arbitraryData;

        // Finds total number of outputs
        uint _numberOfOutputs = uint256(indexCompactInt(voutView, 0));

        for (uint index = 0; index < _numberOfOutputs; index++) {
            output = indexVout(voutView, index);
            _scriptPubkey = scriptPubkey(output);
            _scriptPubkeyWithLength = scriptPubkeyWithLength(output);
            _arbitraryData = opReturnPayloadBig(_scriptPubkeyWithLength);

            // Checks whether the output is an arbitarary data or not
            if(_arbitraryData == 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) {
                // Output is not an arbitrary data
                if (
                    keccak256(abi.encodePacked(_scriptPubkey.clone())) == keccak256(abi.encodePacked(_lockingScript))
                ) {
                    bitcoinAmount = value(output);
                }
            } else {
                // Returns the whole bytes array
                arbitraryData = _arbitraryData.clone();
            }
        }
    }

    /// @notice             extracts the scriptPubkey from an output
    /// @param _output      the output
    /// @return             the scriptPubkey
    function scriptPubkey(bytes29 _output) internal pure typeAssert(_output, BTCTypes.TxOut) returns (bytes29) {
        uint64 scriptLength = indexCompactInt(_output, 8);
        return _output.slice(8 + compactIntLength(scriptLength), scriptLength, uint40(BTCTypes.ScriptPubkey));
    }

    /// @notice             extracts the scriptPubkey from an output
    /// @param _output      the output
    /// @return             the scriptPubkey
    function scriptPubkeyWithLength(bytes29 _output) internal pure typeAssert(_output, BTCTypes.TxOut) returns (bytes29) {
        uint64 scriptLength = indexCompactInt(_output, 8);
        return _output.slice(8, compactIntLength(scriptLength) + scriptLength, uint40(BTCTypes.ScriptPubkey));
    }

    /// @notice                           Parses locking script from an output
    /// @dev                              Reverts if vout is null
    /// @param _vout                      The vout of a Bitcoin transaction
    /// @param _index                     Index of the output that we are looking at
    /// @return _lockingScript            Parsed locking script
    function getLockingScript(
        bytes memory _vout, 
        uint _index
    ) internal view returns (bytes memory _lockingScript) {
        bytes29 vout = tryAsVout(_vout.ref(uint40(BTCTypes.Unknown)));
        require(!vout.isNull(), "BitcoinHelper: vout is null");
        bytes29 output = indexVout(vout, _index);
        bytes29 _lockingScriptBytes29 = scriptPubkey(output);
        _lockingScript = _lockingScriptBytes29.clone();
    }

    /// @notice                   Returns number of outputs in a vout
    /// @param _vout              The vout of a Bitcoin transaction           
    function numberOfOutputs(bytes memory _vout) internal pure returns (uint _numberOfOutputs) {
        bytes29 voutView = tryAsVout(_vout.ref(uint40(BTCTypes.Unknown)));
        _numberOfOutputs = uint256(indexCompactInt(voutView, 0));
    }

    /// @notice             determines the length of the first output in an array of outputs
    /// @param _outputs     the vout without its length prefix
    /// @return             the output length
    function outputLength(bytes29 _outputs) private pure typeAssert(_outputs, BTCTypes.IntermediateTxOuts) returns (uint256) {
        uint64 scriptLength = indexCompactInt(_outputs, 8);
        return uint256(compactIntLength(scriptLength)) + uint256(scriptLength) + 8;
    }

    /// @notice         extracts the output at a specified index
    /// @param _vout    the vout
    /// @param _index   the index of the desired output
    /// @return         the desired output
    function indexVout(bytes29 _vout, uint256 _index) internal pure typeAssert(_vout, BTCTypes.Vout) returns (bytes29) {
        uint256 _nOuts = uint256(indexCompactInt(_vout, 0));
        uint256 _viewLen = _vout.len();
        require(_index < _nOuts, "Vout read overrun");

        uint256 _offset = uint256(compactIntLength(uint64(_nOuts)));
        bytes29 _remaining;
        for (uint256 _i = 0; _i < _index; _i += 1) {
            _remaining = _vout.postfix(_viewLen - _offset, uint40(BTCTypes.IntermediateTxOuts));
            _offset += outputLength(_remaining);
        }

        _remaining = _vout.postfix(_viewLen - _offset, uint40(BTCTypes.IntermediateTxOuts));
        uint256 _len = outputLength(_remaining);
        return _vout.slice(_offset, _len, uint40(BTCTypes.TxOut));
    }

    /// @notice         extracts the Op Return Payload
    /// @dev            structure of the input is: 1 byte op return + 2 bytes indicating the length of payload + max length for op return payload is 80 bytes
    /// @param _spk     the scriptPubkey
    /// @return         the Op Return Payload (or null if not a valid Op Return output)
    function opReturnPayloadBig(bytes29 _spk) internal pure typeAssert(_spk, BTCTypes.ScriptPubkey) returns (bytes29) {
        uint64 _bodyLength = indexCompactInt(_spk, 0);
        uint64 _payloadLen = _spk.indexUint(3, 1).toUint64();
        if (_bodyLength > 83 || _bodyLength < 4 || _spk.indexUint(1, 1) != 0x6a || _spk.indexUint(3, 1) != _bodyLength - 3) {
            return TypedMemView.nullView();
        }
        return _spk.slice(4, _payloadLen, uint40(BTCTypes.OpReturnPayload));
    }

    /// @notice         extracts the Op Return Payload
    /// @dev            structure of the input is: 1 byte op return + 1 bytes indicating the length of payload + max length for op return payload is 75 bytes
    /// @param _spk     the scriptPubkey
    /// @return         the Op Return Payload (or null if not a valid Op Return output)
    function opReturnPayloadSmall(bytes29 _spk) internal pure typeAssert(_spk, BTCTypes.ScriptPubkey) returns (bytes29) {
        uint64 _bodyLength = indexCompactInt(_spk, 0);
        uint64 _payloadLen = _spk.indexUint(2, 1).toUint64();
        if (_bodyLength > 77 || _bodyLength < 4 || _spk.indexUint(1, 1) != 0x6a || _spk.indexUint(2, 1) != _bodyLength - 2) {
            return TypedMemView.nullView();
        }
        return _spk.slice(3, _payloadLen, uint40(BTCTypes.OpReturnPayload));
    }

    /// @notice     verifies the vin and converts to a typed memory
    /// @dev        will return null in error cases
    /// @param _vin the vin
    /// @return     the typed vin (or null if error)
    function tryAsVin(bytes29 _vin) internal pure typeAssert(_vin, BTCTypes.Unknown) returns (bytes29) {
        if (_vin.len() == 0) {
            return TypedMemView.nullView();
        }
        uint64 _nIns = indexCompactInt(_vin, 0);
        uint256 _viewLen = _vin.len();
        if (_nIns == 0) {
            return TypedMemView.nullView();
        }

        uint256 _offset = uint256(compactIntLength(_nIns));
        for (uint256 i = 0; i < _nIns; i++) {
            if (_offset >= _viewLen) {
                // We've reached the end, but are still trying to read more
                return TypedMemView.nullView();
            }
            bytes29 _remaining = _vin.postfix(_viewLen - _offset, uint40(BTCTypes.IntermediateTxIns));
            _offset += inputLength(_remaining);
        }
        if (_offset != _viewLen) {
            return TypedMemView.nullView();
        }
        return _vin.castTo(uint40(BTCTypes.Vin));
    }

    /// @notice         verifies the vout and converts to a typed memory
    /// @dev            will return null in error cases
    /// @param _vout    the vout
    /// @return         the typed vout (or null if error)
    function tryAsVout(bytes29 _vout) internal pure typeAssert(_vout, BTCTypes.Unknown) returns (bytes29) {
        if (_vout.len() == 0) {
            return TypedMemView.nullView();
        }
        uint64 _nOuts = indexCompactInt(_vout, 0);

        uint256 _viewLen = _vout.len();
        if (_nOuts == 0) {
            return TypedMemView.nullView();
        }

        uint256 _offset = uint256(compactIntLength(_nOuts));
        for (uint256 i = 0; i < _nOuts; i++) {
            if (_offset >= _viewLen) {
                // We've reached the end, but are still trying to read more
                return TypedMemView.nullView();
            }
            bytes29 _remaining = _vout.postfix(_viewLen - _offset, uint40(BTCTypes.IntermediateTxOuts));
            _offset += outputLength(_remaining);
        }
        if (_offset != _viewLen) {
            return TypedMemView.nullView();
        }
        return _vout.castTo(uint40(BTCTypes.Vout));
    }

    /// @notice         verifies the header and converts to a typed memory
    /// @dev            will return null in error cases
    /// @param _header  the header
    /// @return         the typed header (or null if error)
    function tryAsHeader(bytes29 _header) internal pure typeAssert(_header, BTCTypes.Unknown) returns (bytes29) {
        if (_header.len() != 80) {
            return TypedMemView.nullView();
        }
        return _header.castTo(uint40(BTCTypes.Header));
    }


    /// @notice         Index a header array.
    /// @dev            Errors on overruns
    /// @param _arr     The header array
    /// @param index    The 0-indexed location of the header to get
    /// @return         the typed header at `index`
    function indexHeaderArray(bytes29 _arr, uint256 index) internal pure typeAssert(_arr, BTCTypes.HeaderArray) returns (bytes29) {
        uint256 _start = index * 80;
        return _arr.slice(_start, 80, uint40(BTCTypes.Header));
    }


    /// @notice     verifies the header array and converts to a typed memory
    /// @dev        will return null in error cases
    /// @param _arr the header array
    /// @return     the typed header array (or null if error)
    function tryAsHeaderArray(bytes29 _arr) internal pure typeAssert(_arr, BTCTypes.Unknown) returns (bytes29) {
        if (_arr.len() % 80 != 0) {
            return TypedMemView.nullView();
        }
        return _arr.castTo(uint40(BTCTypes.HeaderArray));
    }

    /// @notice     verifies the merkle array and converts to a typed memory
    /// @dev        will return null in error cases
    /// @param _arr the merkle array
    /// @return     the typed merkle array (or null if error)
    function tryAsMerkleArray(bytes29 _arr) internal pure typeAssert(_arr, BTCTypes.Unknown) returns (bytes29) {
        if (_arr.len() % 32 != 0) {
            return TypedMemView.nullView();
        }
        return _arr.castTo(uint40(BTCTypes.MerkleArray));
    }

    /// @notice         extracts the merkle root from the header
    /// @param _header  the header
    /// @return         the merkle root
    function merkleRoot(bytes29 _header) internal pure typeAssert(_header, BTCTypes.Header) returns (bytes32) {
        return _header.index(36, 32);
    }

    /// @notice         extracts the target from the header
    /// @param _header  the header
    /// @return         the target
    function target(bytes29  _header) internal pure typeAssert(_header, BTCTypes.Header) returns (uint256) {
        uint256 _mantissa = _header.indexLEUint(72, 3);
        require(_header.indexUint(75, 1) > 2, "ViewBTC: invalid target difficulty");
        uint256 _exponent = _header.indexUint(75, 1) - 3;
        return _mantissa * (256 ** _exponent);
    }

    /// @notice         calculates the difficulty from a target
    /// @param _target  the target
    /// @return         the difficulty
    function toDiff(uint256  _target) private pure returns (uint256) {
        return DIFF1_TARGET / (_target);
    }

    /// @notice         extracts the difficulty from the header
    /// @param _header  the header
    /// @return         the difficulty
    function diff(bytes29  _header) internal pure typeAssert(_header, BTCTypes.Header) returns (uint256) {
        return toDiff(target(_header));
    }

    /// @notice         extracts the timestamp from the header
    /// @param _header  the header
    /// @return         the timestamp
    function time(bytes29  _header) internal pure typeAssert(_header, BTCTypes.Header) returns (uint32) {
        return uint32(_header.indexLEUint(68, 4));
    }

    /// @notice         extracts the parent hash from the header
    /// @param _header  the header
    /// @return         the parent hash
    function parent(bytes29 _header) internal pure typeAssert(_header, BTCTypes.Header) returns (bytes32) {
        return _header.index(4, 32);
    }

    /// @notice                     Checks validity of header chain
    /// @dev                        Compares current header parent to previous header's digest
    /// @param _header              The raw bytes header
    /// @param _prevHeaderDigest    The previous header's digest
    /// @return                     true if the connect is valid, false otherwise
    function checkParent(bytes29 _header, bytes32 _prevHeaderDigest) internal pure typeAssert(_header, BTCTypes.Header) returns (bool) {
        return parent(_header) == _prevHeaderDigest;
    }

    /// @notice                     Validates a tx inclusion in the block
    /// @dev                        `index` is not a reliable indicator of location within a block
    /// @param _txid                The txid (LE)
    /// @param _merkleRoot          The merkle root
    /// @param _intermediateNodes   The proof's intermediate nodes (digests between leaf and root)
    /// @param _index               The leaf's index in the tree (0-indexed)
    /// @return                     true if fully valid, false otherwise
    function prove( 
        bytes32 _txid,
        bytes32 _merkleRoot,
        bytes29 _intermediateNodes,
        uint _index
    ) internal view typeAssert(_intermediateNodes, BTCTypes.MerkleArray) returns (bool) {
        // Shortcut the empty-block case
        if (
            _txid == _merkleRoot &&
                _index == 0 &&
                    _intermediateNodes.len() == 0
        ) {
            return true;
        }

        return checkMerkle(_txid, _intermediateNodes, _merkleRoot, _index);
    }

    /// @notice         verifies a merkle proof
    /// @dev            leaf, proof, and root are in LE format
    /// @param _leaf    the leaf
    /// @param _proof   the proof nodes
    /// @param _root    the merkle root
    /// @param _index   the index
    /// @return         true if valid, false if otherwise
    function checkMerkle(
        bytes32 _leaf,
        bytes29 _proof,
        bytes32 _root,
        uint256 _index
    ) private view typeAssert(_proof, BTCTypes.MerkleArray) returns (bool) {
        uint256 nodes = _proof.len() / 32;
        if (nodes == 0) {
            return _leaf == _root;
        }

        uint256 _idx = _index;
        bytes32 _current = _leaf;

        for (uint i = 0; i < nodes; i++) {
            bytes32 _next = _proof.index(i * 32, 32);
            if (_idx % 2 == 1) {
                _current = merkleStep(_next, _current);
            } else {
                _current = merkleStep(_current, _next);
            }
            _idx >>= 1;
        }

        return _current == _root;
    }

    /// @notice          Concatenates and hashes two inputs for merkle proving
    /// @dev             Not recommended to call directly.
    /// @param _a        The first hash
    /// @param _b        The second hash
    /// @return digest   The double-sha256 of the concatenated hashes
    function merkleStep(bytes32 _a, bytes32 _b) private view returns (bytes32 digest) {
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            let ptr := mload(0x40)
            mstore(ptr, _a)
            mstore(add(ptr, 0x20), _b)
            pop(staticcall(gas(), 2, ptr, 0x40, ptr, 0x20)) // sha256 #1
            pop(staticcall(gas(), 2, ptr, 0x20, ptr, 0x20)) // sha256 #2
            digest := mload(ptr)
        }
    }

    /// @notice                 performs the bitcoin difficulty retarget
    /// @dev                    implements the Bitcoin algorithm precisely
    /// @param _previousTarget  the target of the previous period
    /// @param _firstTimestamp  the timestamp of the first block in the difficulty period
    /// @param _secondTimestamp the timestamp of the last block in the difficulty period
    /// @return                 the new period's target threshold
    function retargetAlgorithm(
        uint256 _previousTarget,
        uint256 _firstTimestamp,
        uint256 _secondTimestamp
    ) internal pure returns (uint256) {
        uint256 _elapsedTime = _secondTimestamp - _firstTimestamp;

        // Normalize ratio to factor of 4 if very long or very short
        if (_elapsedTime < RETARGET_PERIOD / 4) {
            _elapsedTime = RETARGET_PERIOD / 4;
        }
        if (_elapsedTime > RETARGET_PERIOD * 4) {
            _elapsedTime = RETARGET_PERIOD * 4;
        }

        /*
            NB: high targets e.g. ffff0020 can cause overflows here
                so we divide it by 256**2, then multiply by 256**2 later
                we know the target is evenly divisible by 256**2, so this isn't an issue
        */
        uint256 _adjusted = _previousTarget / 65536 * _elapsedTime;
        return _adjusted / RETARGET_PERIOD * 65536;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

/** @author Summa (https://summa.one) */

/*
    Original version: https://github.com/summa-tx/memview-sol/blob/main/contracts/TypedMemView.sol
    We made few changes to the original version:
    1. Use solidity version 8 compiler
    2. Remove SafeMath library
    3. Add unchecked in line 522
*/

library TypedMemView {

    // Why does this exist?
    // the solidity `bytes memory` type has a few weaknesses.
    // 1. You can't index ranges effectively
    // 2. You can't slice without copying
    // 3. The underlying data may represent any type
    // 4. Solidity never deallocates memory, and memory costs grow
    //    superlinearly

    // By using a memory view instead of a `bytes memory` we get the following
    // advantages:
    // 1. Slices are done on the stack, by manipulating the pointer
    // 2. We can index arbitrary ranges and quickly convert them to stack types
    // 3. We can insert type info into the pointer, and typecheck at runtime

    // This makes `TypedMemView` a useful tool for efficient zero-copy
    // algorithms.

    // Why bytes29?
    // We want to avoid confusion between views, digests, and other common
    // types so we chose a large and uncommonly used odd number of bytes
    //
    // Note that while bytes are left-aligned in a word, integers and addresses
    // are right-aligned. This means when working in assembly we have to
    // account for the 3 unused bytes on the righthand side
    //
    // First 5 bytes are a type flag.
    // - ff_ffff_fffe is reserved for unknown type.
    // - ff_ffff_ffff is reserved for invalid types/errors.
    // next 12 are memory address
    // next 12 are len
    // bottom 3 bytes are empty

    // Assumptions:
    // - non-modification of memory.
    // - No Solidity updates
    // - - wrt free mem point
    // - - wrt bytes representation in memory
    // - - wrt memory addressing in general

    // Usage:
    // - create type constants
    // - use `assertType` for runtime type assertions
    // - - unfortunately we can't do this at compile time yet :(
    // - recommended: implement modifiers that perform type checking
    // - - e.g.
    // - - `uint40 constant MY_TYPE = 3;`
    // - - ` modifer onlyMyType(bytes29 myView) { myView.assertType(MY_TYPE); }`
    // - instantiate a typed view from a bytearray using `ref`
    // - use `index` to inspect the contents of the view
    // - use `slice` to create smaller views into the same memory
    // - - `slice` can increase the offset
    // - - `slice can decrease the length`
    // - - must specify the output type of `slice`
    // - - `slice` will return a null view if you try to overrun
    // - - make sure to explicitly check for this with `notNull` or `assertType`
    // - use `equal` for typed comparisons.


    // The null view
    bytes29 internal constant NULL = hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
    uint256 constant LOW_12_MASK = 0xffffffffffffffffffffffff;
    uint8 constant TWELVE_BYTES = 96;

    /**
     * @notice      Returns the encoded hex character that represents the lower 4 bits of the argument.
     * @param _b    The byte
     * @return      char - The encoded hex character
     */
    function nibbleHex(uint8 _b) internal pure returns (uint8 char) {
        // This can probably be done more efficiently, but it's only in error
        // paths, so we don't really care :)
        uint8 _nibble = _b | 0xf0; // set top 4, keep bottom 4
        if (_nibble == 0xf0) {return 0x30;} // 0
        if (_nibble == 0xf1) {return 0x31;} // 1
        if (_nibble == 0xf2) {return 0x32;} // 2
        if (_nibble == 0xf3) {return 0x33;} // 3
        if (_nibble == 0xf4) {return 0x34;} // 4
        if (_nibble == 0xf5) {return 0x35;} // 5
        if (_nibble == 0xf6) {return 0x36;} // 6
        if (_nibble == 0xf7) {return 0x37;} // 7
        if (_nibble == 0xf8) {return 0x38;} // 8
        if (_nibble == 0xf9) {return 0x39;} // 9
        if (_nibble == 0xfa) {return 0x61;} // a
        if (_nibble == 0xfb) {return 0x62;} // b
        if (_nibble == 0xfc) {return 0x63;} // c
        if (_nibble == 0xfd) {return 0x64;} // d
        if (_nibble == 0xfe) {return 0x65;} // e
        if (_nibble == 0xff) {return 0x66;} // f
    }

    /**
     * @notice      Returns a uint16 containing the hex-encoded byte.
     *              `the first 8 bits of encoded is the nibbleHex of top 4 bits of _b`
     *              `the second 8 bits of encoded is the nibbleHex of lower 4 bits of _b`
     * @param _b    The byte
     * @return      encoded - The hex-encoded byte
     */
    function byteHex(uint8 _b) internal pure returns (uint16 encoded) {
        encoded |= nibbleHex(_b >> 4); // top 4 bits
        encoded <<= 8;
        encoded |= nibbleHex(_b); // lower 4 bits
    }

    /**
     * @notice      Encodes the uint256 to hex. `first` contains the encoded top 16 bytes.
     *              `second` contains the encoded lower 16 bytes.
     *
     * @param _b    The 32 bytes as uint256
     * @return      first - The top 16 bytes
     * @return      second - The bottom 16 bytes
     */
    function encodeHex(uint256 _b) internal pure returns (uint256 first, uint256 second) {
        for (uint8 i = 31; i > 15; i -= 1) {
            uint8 _byte = uint8(_b >> (i * 8));
            first |= byteHex(_byte);
            if (i != 16) {
                first <<= 16;
            }
        }

        unchecked {
            // abusing underflow here =_=
            for (uint8 i = 15; i < 255 ; i -= 1) {
                uint8 _byte = uint8(_b >> (i * 8));
                second |= byteHex(_byte);
                if (i != 0) {
                    second <<= 16;
                }
            }
        }
        
    }

    /**
     * @notice          Changes the endianness of a uint256.
     * @dev             https://graphics.stanford.edu/~seander/bithacks.html#ReverseParallel
     * @param _b        The unsigned integer to reverse
     * @return          v - The reversed value
     */
    function reverseUint256(uint256 _b) internal pure returns (uint256 v) {
        v = _b;

        // swap bytes
        v = ((v >> 8) & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) |
        ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) << 8);
        // swap 2-byte long pairs
        v = ((v >> 16) & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) |
        ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) << 16);
        // swap 4-byte long pairs
        v = ((v >> 32) & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) |
        ((v & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32);
        // swap 8-byte long pairs
        v = ((v >> 64) & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) |
        ((v & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64);
        // swap 16-byte long pairs
        v = (v >> 128) | (v << 128);
    }

    /**
     * @notice      Create a mask with the highest `_len` bits set.
     * @param _len  The length
     * @return      mask - The mask
     */
    function leftMask(uint8 _len) private pure returns (uint256 mask) {
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            mask := sar(
            sub(_len, 1),
            0x8000000000000000000000000000000000000000000000000000000000000000
            )
        }
    }

    /**
     * @notice      Return the null view.
     * @return      bytes29 - The null view
     */
    function nullView() internal pure returns (bytes29) {
        return NULL;
    }

    /**
     * @notice      Check if the view is null.
     * @return      bool - True if the view is null
     */
    function isNull(bytes29 memView) internal pure returns (bool) {
        return memView == NULL;
    }

    /**
     * @notice      Check if the view is not null.
     * @return      bool - True if the view is not null
     */
    function notNull(bytes29 memView) internal pure returns (bool) {
        return !isNull(memView);
    }

    /**
     * @notice          Check if the view is of a valid type and points to a valid location
     *                  in memory.
     * @dev             We perform this check by examining solidity's unallocated memory
     *                  pointer and ensuring that the view's upper bound is less than that.
     * @param memView   The view
     * @return          ret - True if the view is valid
     */
    function isValid(bytes29 memView) internal pure returns (bool ret) {
        if (typeOf(memView) == 0xffffffffff) {return false;}
        uint256 _end = end(memView);
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            ret := not(gt(_end, mload(0x40)))
        }
    }

    /**
     * @notice          Require that a typed memory view be valid.
     * @dev             Returns the view for easy chaining.
     * @param memView   The view
     * @return          bytes29 - The validated view
     */
    function assertValid(bytes29 memView) internal pure returns (bytes29) {
        require(isValid(memView), "Validity assertion failed");
        return memView;
    }

    /**
     * @notice          Return true if the memview is of the expected type. Otherwise false.
     * @param memView   The view
     * @param _expected The expected type
     * @return          bool - True if the memview is of the expected type
     */
    function isType(bytes29 memView, uint40 _expected) internal pure returns (bool) {
        return typeOf(memView) == _expected;
    }

    /**
     * @notice          Require that a typed memory view has a specific type.
     * @dev             Returns the view for easy chaining.
     * @param memView   The view
     * @param _expected The expected type
     * @return          bytes29 - The view with validated type
     */
    function assertType(bytes29 memView, uint40 _expected) internal pure returns (bytes29) {
        if (!isType(memView, _expected)) {
            (, uint256 g) = encodeHex(uint256(typeOf(memView)));
            (, uint256 e) = encodeHex(uint256(_expected));
            string memory err = string(
                abi.encodePacked(
                    "Type assertion failed. Got 0x",
                    uint80(g),
                    ". Expected 0x",
                    uint80(e)
                )
            );
            revert(err);
        }
        return memView;
    }

    /**
     * @notice          Return an identical view with a different type.
     * @param memView   The view
     * @param _newType  The new type
     * @return          newView - The new view with the specified type
     */
    function castTo(bytes29 memView, uint40 _newType) internal pure returns (bytes29 newView) {
        // then | in the new type
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
        // shift off the top 5 bytes
            newView := or(newView, shr(40, shl(40, memView)))
            newView := or(newView, shl(216, _newType))
        }
    }

    /**
     * @notice          Unsafe raw pointer construction. This should generally not be called
     *                  directly. Prefer `ref` wherever possible.
     * @dev             Unsafe raw pointer construction. This should generally not be called
     *                  directly. Prefer `ref` wherever possible.
     * @param _type     The type
     * @param _loc      The memory address
     * @param _len      The length
     * @return          newView - The new view with the specified type, location and length
     */
    function unsafeBuildUnchecked(uint256 _type, uint256 _loc, uint256 _len) private pure returns (bytes29 newView) {
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            newView := shl(96, or(newView, _type)) // insert type
            newView := shl(96, or(newView, _loc))  // insert loc
            newView := shl(24, or(newView, _len))  // empty bottom 3 bytes
        }
    }

    /**
     * @notice          Instantiate a new memory view. This should generally not be called
     *                  directly. Prefer `ref` wherever possible.
     * @dev             Instantiate a new memory view. This should generally not be called
     *                  directly. Prefer `ref` wherever possible.
     * @param _type     The type
     * @param _loc      The memory address
     * @param _len      The length
     * @return          newView - The new view with the specified type, location and length
     */
    function build(uint256 _type, uint256 _loc, uint256 _len) internal pure returns (bytes29 newView) {
        uint256 _end = _loc + _len;
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            if gt(_end, mload(0x40)) {
                _end := 0
            }
        }
        if (_end == 0) {
            return NULL;
        }
        newView = unsafeBuildUnchecked(_type, _loc, _len);
    }

    /**
     * @notice          Instantiate a memory view from a byte array.
     * @dev             Note that due to Solidity memory representation, it is not possible to
     *                  implement a deref, as the `bytes` type stores its len in memory.
     * @param arr       The byte array
     * @param newType   The type
     * @return          bytes29 - The memory view
     */
    function ref(bytes memory arr, uint40 newType) internal pure returns (bytes29) {
        uint256 _len = arr.length;

        uint256 _loc;
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            _loc := add(arr, 0x20)  // our view is of the data, not the struct
        }

        return build(newType, _loc, _len);
    }

    /**
     * @notice          Return the associated type information.
     * @param memView   The memory view
     * @return          _type - The type associated with the view
     */
    function typeOf(bytes29 memView) internal pure returns (uint40 _type) {
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
        // 216 == 256 - 40
            _type := shr(216, memView) // shift out lower (12 + 12 + 3) bytes
        }
    }

    /**
     * @notice          Optimized type comparison. Checks that the 5-byte type flag is equal.
     * @param left      The first view
     * @param right     The second view
     * @return          bool - True if the 5-byte type flag is equal
     */
    function sameType(bytes29 left, bytes29 right) internal pure returns (bool) {
        // XOR the inputs to check their difference
        return (left ^ right) >> (2 * TWELVE_BYTES) == 0;
    }

    /**
     * @notice          Return the memory address of the underlying bytes.
     * @param memView   The view
     * @return          _loc - The memory address
     */
    function loc(bytes29 memView) internal pure returns (uint96 _loc) {
        uint256 _mask = LOW_12_MASK;  // assembly can't use globals
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
        // 120 bits = 12 bytes (the encoded loc) + 3 bytes (empty low space)
            _loc := and(shr(120, memView), _mask)
        }
    }

    /**
     * @notice          The number of memory words this memory view occupies, rounded up.
     * @param memView   The view
     * @return          uint256 - The number of memory words
     */
    function words(bytes29 memView) internal pure returns (uint256) {
        return (uint256(len(memView)) + 32) / 32;
    }

    /**
     * @notice          The in-memory footprint of a fresh copy of the view.
     * @param memView   The view
     * @return          uint256 - The in-memory footprint of a fresh copy of the view.
     */
    function footprint(bytes29 memView) internal pure returns (uint256) {
        return words(memView) * 32;
    }

    /**
     * @notice          The number of bytes of the view.
     * @param memView   The view
     * @return          _len - The length of the view
     */
    function len(bytes29 memView) internal pure returns (uint96 _len) {
        uint256 _mask = LOW_12_MASK;  // assembly can't use globals
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            _len := and(shr(24, memView), _mask)
        }
    }

    /**
     * @notice          Returns the endpoint of `memView`.
     * @param memView   The view
     * @return          uint256 - The endpoint of `memView`
     */
    function end(bytes29 memView) internal pure returns (uint256) {
        return loc(memView) + len(memView);
    }

    /**
     * @notice          Safe slicing without memory modification.
     * @param memView   The view
     * @param _index    The start index
     * @param _len      The length
     * @param newType   The new type
     * @return          bytes29 - The new view
     */
    function slice(bytes29 memView, uint256 _index, uint256 _len, uint40 newType) internal pure returns (bytes29) {
        uint256 _loc = loc(memView);

        // Ensure it doesn't overrun the view
        if (_loc + _index + _len > end(memView)) {
            return NULL;
        }

        _loc = _loc + _index;
        return build(newType, _loc, _len);
    }

    /**
     * @notice          Shortcut to `slice`. Gets a view representing the first `_len` bytes.
     * @param memView   The view
     * @param _len      The length
     * @param newType   The new type
     * @return          bytes29 - The new view
     */
    function prefix(bytes29 memView, uint256 _len, uint40 newType) internal pure returns (bytes29) {
        return slice(memView, 0, _len, newType);
    }

    /**
     * @notice          Shortcut to `slice`. Gets a view representing the last `_len` bytes.
     * @param memView   The view
     * @param _len      The length
     * @param newType   The new type
     * @return          bytes29 - The new view
     */
    function postfix(bytes29 memView, uint256 _len, uint40 newType) internal pure returns (bytes29) {
        return slice(memView, uint256(len(memView)) - _len, _len, newType);
    }

    /**
     * @notice          Construct an error message for an indexing overrun.
     * @param _loc      The memory address
     * @param _len      The length
     * @param _index    The index
     * @param _slice    The slice where the overrun occurred
     * @return          err - The err
     */
    function indexErrOverrun(
        uint256 _loc,
        uint256 _len,
        uint256 _index,
        uint256 _slice
    ) internal pure returns (string memory err) {
        (, uint256 a) = encodeHex(_loc);
        (, uint256 b) = encodeHex(_len);
        (, uint256 c) = encodeHex(_index);
        (, uint256 d) = encodeHex(_slice);
        err = string(
            abi.encodePacked(
                "TypedMemView/index - Overran the view. Slice is at 0x",
                uint48(a),
                " with length 0x",
                uint48(b),
                ". Attempted to index at offset 0x",
                uint48(c),
                " with length 0x",
                uint48(d),
                "."
            )
        );
    }

    /**
     * @notice          Load up to 32 bytes from the view onto the stack.
     * @dev             Returns a bytes32 with only the `_bytes` highest bytes set.
     *                  This can be immediately cast to a smaller fixed-length byte array.
     *                  To automatically cast to an integer, use `indexUint`.
     * @param memView   The view
     * @param _index    The index
     * @param _bytes    The bytes length
     * @return          result - The 32 byte result
     */
    function index(bytes29 memView, uint256 _index, uint8 _bytes) internal pure returns (bytes32 result) {
        if (_bytes == 0) {return bytes32(0);}
        if (_index + _bytes > len(memView)) {
            revert(indexErrOverrun(loc(memView), len(memView), _index, uint256(_bytes)));
        }
        require(_bytes <= 32, "TypedMemView/index - Attempted to index more than 32 bytes");

        unchecked {
            uint8 bitLength = _bytes * 8;
            uint256 _loc = loc(memView);
            uint256 _mask = leftMask(bitLength);
            assembly {
                // solium-disable-previous-line security/no-inline-assembly
                result := and(mload(add(_loc, _index)), _mask)
            }   
        }

    }

    /**
     * @notice          Parse an unsigned integer from the view at `_index`.
     * @dev             Requires that the view has >= `_bytes` bytes following that index.
     * @param memView   The view
     * @param _index    The index
     * @param _bytes    The bytes length
     * @return          result - The unsigned integer
     */
    function indexUint(bytes29 memView, uint256 _index, uint8 _bytes) internal pure returns (uint256 result) {
        return uint256(index(memView, _index, _bytes)) >> ((32 - _bytes) * 8);
    }

    /**
     * @notice          Parse an unsigned integer from LE bytes.
     * @param memView   The view
     * @param _index    The index
     * @param _bytes    The bytes length
     * @return          result - The unsigned integer
     */
    function indexLEUint(bytes29 memView, uint256 _index, uint8 _bytes) internal pure returns (uint256 result) {
        return reverseUint256(uint256(index(memView, _index, _bytes)));
    }

    /**
     * @notice          Parse an address from the view at `_index`. Requires that the view have >= 20 bytes
     *                  following that index.
     * @param memView   The view
     * @param _index    The index
     * @return          address - The address
     */
    function indexAddress(bytes29 memView, uint256 _index) internal pure returns (address) {
        return address(uint160(indexUint(memView, _index, 20)));
    }

    /**
     * @notice          Return the keccak256 hash of the underlying memory
     * @param memView   The view
     * @return          digest - The keccak256 hash of the underlying memory
     */
    function keccak(bytes29 memView) internal pure returns (bytes32 digest) {
        uint256 _loc = loc(memView);
        uint256 _len = len(memView);
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            digest := keccak256(_loc, _len)
        }
    }

    /**
     * @notice          Return the sha2 digest of the underlying memory.
     * @dev             We explicitly deallocate memory afterwards.
     * @param memView   The view
     * @return          digest - The sha2 hash of the underlying memory
     */
    function sha2(bytes29 memView) internal view returns (bytes32 digest) {
        uint256 _loc = loc(memView);
        uint256 _len = len(memView);
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            let ptr := mload(0x40)
            pop(staticcall(gas(), 2, _loc, _len, ptr, 0x20)) // sha2 #1
            digest := mload(ptr)
        }
    }

    /**
     * @notice          Implements bitcoin's hash160 (rmd160(sha2()))
     * @param memView   The pre-image
     * @return          digest - the Digest
     */
    function hash160(bytes29 memView) internal view returns (bytes20 digest) {
        uint256 _loc = loc(memView);
        uint256 _len = len(memView);
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            let ptr := mload(0x40)
            pop(staticcall(gas(), 2, _loc, _len, ptr, 0x20)) // sha2
            pop(staticcall(gas(), 3, ptr, 0x20, ptr, 0x20)) // rmd160
            digest := mload(add(ptr, 0xc)) // return value is 0-prefixed.
        }
    }

    /**
     * @notice          Implements bitcoin's hash256 (double sha2)
     * @param memView   A view of the preimage
     * @return          digest - the Digest
     */
    function hash256(bytes29 memView) internal view returns (bytes32 digest) {
        uint256 _loc = loc(memView);
        uint256 _len = len(memView);
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            let ptr := mload(0x40)
            pop(staticcall(gas(), 2, _loc, _len, ptr, 0x20)) // sha2 #1
            pop(staticcall(gas(), 2, ptr, 0x20, ptr, 0x20)) // sha2 #2
            digest := mload(ptr)
        }
    }

    /**
     * @notice          Return true if the underlying memory is equal. Else false.
     * @param left      The first view
     * @param right     The second view
     * @return          bool - True if the underlying memory is equal
     */
    function untypedEqual(bytes29 left, bytes29 right) internal pure returns (bool) {
        return (loc(left) == loc(right) && len(left) == len(right)) || keccak(left) == keccak(right);
    }

    /**
     * @notice          Return false if the underlying memory is equal. Else true.
     * @param left      The first view
     * @param right     The second view
     * @return          bool - False if the underlying memory is equal
     */
    function untypedNotEqual(bytes29 left, bytes29 right) internal pure returns (bool) {
        return !untypedEqual(left, right);
    }

    /**
     * @notice          Compares type equality.
     * @dev             Shortcuts if the pointers are identical, otherwise compares type and digest.
     * @param left      The first view
     * @param right     The second view
     * @return          bool - True if the types are the same
     */
    function equal(bytes29 left, bytes29 right) internal pure returns (bool) {
        return left == right || (typeOf(left) == typeOf(right) && keccak(left) == keccak(right));
    }

    /**
     * @notice          Compares type inequality.
     * @dev             Shortcuts if the pointers are identical, otherwise compares type and digest.
     * @param left      The first view
     * @param right     The second view
     * @return          bool - True if the types are not the same
     */
    function notEqual(bytes29 left, bytes29 right) internal pure returns (bool) {
        return !equal(left, right);
    }

    /**
     * @notice          Copy the view to a location, return an unsafe memory reference
     * @dev             Super Dangerous direct memory access.
     *
     *                  This reference can be overwritten if anything else modifies memory (!!!).
     *                  As such it MUST be consumed IMMEDIATELY.
     *                  This function is private to prevent unsafe usage by callers.
     * @param memView   The view
     * @param _newLoc   The new location
     * @return          written - the unsafe memory reference
     */
    function unsafeCopyTo(bytes29 memView, uint256 _newLoc) private view returns (bytes29 written) {
        require(notNull(memView), "TypedMemView/copyTo - Null pointer deref");
        require(isValid(memView), "TypedMemView/copyTo - Invalid pointer deref");
        uint256 _len = len(memView);
        uint256 _oldLoc = loc(memView);

        uint256 ptr;
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            ptr := mload(0x40)
        // revert if we're writing in occupied memory
            if gt(ptr, _newLoc) {
                revert(0x60, 0x20) // empty revert message
            }

        // use the identity precompile to copy
        // guaranteed not to fail, so pop the success
            pop(staticcall(gas(), 4, _oldLoc, _len, _newLoc, _len))
        }

        written = unsafeBuildUnchecked(typeOf(memView), _newLoc, _len);
    }

    /**
     * @notice          Copies the referenced memory to a new loc in memory, returning a `bytes` pointing to
     *                  the new memory
     * @dev             Shortcuts if the pointers are identical, otherwise compares type and digest.
     * @param memView   The view
     * @return          ret - The view pointing to the new memory
     */
    function clone(bytes29 memView) internal view returns (bytes memory ret) {
        uint256 ptr;
        uint256 _len = len(memView);
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            ptr := mload(0x40) // load unused memory pointer
            ret := ptr
        }
        unsafeCopyTo(memView, ptr + 0x20);
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            mstore(0x40, add(add(ptr, _len), 0x20)) // write new unused pointer
            mstore(ptr, _len) // write len of new array (in bytes)
        }
    }

    /**
     * @notice          Join the views in memory, return an unsafe reference to the memory.
     * @dev             Super Dangerous direct memory access.
     *
     *                  This reference can be overwritten if anything else modifies memory (!!!).
     *                  As such it MUST be consumed IMMEDIATELY.
     *                  This function is private to prevent unsafe usage by callers.
     * @param memViews  The views
     * @return          unsafeView - The conjoined view pointing to the new memory
     */
    function unsafeJoin(bytes29[] memory memViews, uint256 _location) private view returns (bytes29 unsafeView) {
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            let ptr := mload(0x40)
        // revert if we're writing in occupied memory
            if gt(ptr, _location) {
                revert(0x60, 0x20) // empty revert message
            }
        }

        uint256 _offset = 0;
        for (uint256 i = 0; i < memViews.length; i ++) {
            bytes29 memView = memViews[i];
            unsafeCopyTo(memView, _location + _offset);
            _offset += len(memView);
        }
        unsafeView = unsafeBuildUnchecked(0, _location, _offset);
    }

    /**
     * @notice          Produce the keccak256 digest of the concatenated contents of multiple views.
     * @param memViews  The views
     * @return          bytes32 - The keccak256 digest
     */
    function joinKeccak(bytes29[] memory memViews) internal view returns (bytes32) {
        uint256 ptr;
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            ptr := mload(0x40) // load unused memory pointer
        }
        return keccak(unsafeJoin(memViews, ptr));
    }

    /**
     * @notice          Produce the sha256 digest of the concatenated contents of multiple views.
     * @param memViews  The views
     * @return          bytes32 - The sha256 digest
     */
    function joinSha2(bytes29[] memory memViews) internal view returns (bytes32) {
        uint256 ptr;
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            ptr := mload(0x40) // load unused memory pointer
        }
        return sha2(unsafeJoin(memViews, ptr));
    }

    /**
     * @notice          copies all views, joins them into a new bytearray.
     * @param memViews  The views
     * @return          ret - The new byte array
     */
    function join(bytes29[] memory memViews) internal view returns (bytes memory ret) {
        uint256 ptr;
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            ptr := mload(0x40) // load unused memory pointer
        }

        bytes29 _newView = unsafeJoin(memViews, ptr + 0x20);
        uint256 _written = len(_newView);
        uint256 _footprint = footprint(_newView);

        assembly {
        // solium-disable-previous-line security/no-inline-assembly
        // store the legnth
            mstore(ptr, _written)
        // new pointer is old + 0x20 + the footprint of the body
            mstore(0x40, add(add(ptr, _footprint), 0x20))
            ret := ptr
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

interface IBitcoinRelay {
    // Structures

    /// @notice Structure for recording block header
    /// @param selfHash Hash of block header
    /// @param parentHash Hash of parent header
    /// @param merkleRoot Merkle root of transactions in the header
    /// @param relayer Address of Relayer who submitted the block header
    /// @param gasPrice Gas price of block header submission transaction
    struct blockHeader {
        bytes32 selfHash;
        bytes32 parentHash;
        bytes32 merkleRoot;
        address relayer;
        uint gasPrice;
    }

    // Events

    /// @notice Emits when a block header is added
    /// @param height of submitted header
    /// @param selfHash Hash of submitted header
    /// @param parentHash of submitted header
    /// @param relayer Address of Relayer who submitted the block header
    event BlockAdded(
        uint indexed height,
        bytes32 selfHash,
        bytes32 indexed parentHash,
        address indexed relayer
    );

    /// @notice Emits when a block header gets finalized
    /// @param height of the header
    /// @param selfHash Hash of the header
    /// @param parentHash of the header
    /// @param relayer Address of Relayer who submitted the block header
    /// @param rewardAmountTNT Amount of reward that the Relayer receives in target blockchain native token
    /// @param rewardAmountTDT Amount of reward that the Relayer receives in TeleportDAO token
    event BlockFinalized(
        uint indexed height,
        bytes32 selfHash,
        bytes32 parentHash,
        address indexed relayer,
        uint rewardAmountTNT,
        uint rewardAmountTDT
    );

    /// @notice Emits when inclusion of a tx is queried
    /// @param txId of queried transaction
    /// @param blockHeight of the block that includes the tx
    /// @param paidFee Amount of fee that user paid to Relay
    event NewQuery(
        bytes32 txId,
        uint blockHeight,
        uint paidFee
    );
         
    event NewRewardAmountInTDT (
        uint oldRewardAmountInTDT, 
        uint newRewardAmountInTDT
    );

    event NewFinalizationParameter (
        uint oldFinalizationParameter, 
        uint newFinalizationParameter
    );

    event NewRelayerPercentageFee (
        uint oldRelayerPercentageFee, 
        uint newRelayerPercentageFee
    );

    event NewTeleportDAOToken(
        address oldTeleportDAOToken, 
        address newTeleportDAOToken
    );

    event NewEpochLength(
        uint oldEpochLength, 
        uint newEpochLength
    );

    event NewBaseQueries(
        uint oldBaseQueries, 
        uint newBaseQueries
    );

    event NewSubmissionGasUsed(
        uint oldSubmissionGasUsed, 
        uint newSubmissionGasUsed
    );

    // Read-only functions

    function relayGenesisHash() external view returns (bytes32);

    function initialHeight() external view returns(uint);

    function lastSubmittedHeight() external view returns(uint);

    function finalizationParameter() external view returns(uint);

    function TeleportDAOToken() external view returns(address);

    function relayerPercentageFee() external view returns(uint);

    function epochLength() external view returns(uint);

    function lastEpochQueries() external view returns(uint);

    function currentEpochQueries() external view returns(uint);

    function baseQueries() external view returns(uint);

    function submissionGasUsed() external view returns(uint);

    function getBlockHeaderHash(uint height, uint index) external view returns(bytes32);

    function getBlockHeaderFee(uint _height, uint _index) external view returns(uint);

    function getNumberOfSubmittedHeaders(uint height) external view returns (uint);

    function availableTDT() external view returns(uint);

    function availableTNT() external view returns(uint);

    function findHeight(bytes32 _hash) external view returns (uint256);

    function rewardAmountInTDT() external view returns (uint);

    // State-changing functions

    function pauseRelay() external;

    function unpauseRelay() external;

    function setRewardAmountInTDT(uint _rewardAmountInTDT) external;

    function setFinalizationParameter(uint _finalizationParameter) external;

    function setRelayerPercentageFee(uint _relayerPercentageFee) external;

    function setTeleportDAOToken(address _TeleportDAOToken) external;

    function setEpochLength(uint _epochLength) external;

    function setBaseQueries(uint _baseQueries) external;

    function setSubmissionGasUsed(uint _submissionGasUsed) external;

    function checkTxProof(
        bytes32 txid,
        uint blockHeight,
        bytes calldata intermediateNodes,
        uint index
    ) external payable returns (bool);

    function getBlockHeaderHashContract(uint _height, uint _index) external payable returns (bytes32);

    function addHeaders(bytes calldata _anchor, bytes calldata _headers) external returns (bool);

    function addHeadersWithRetarget(
        bytes calldata _oldPeriodStartHeader,
        bytes calldata _oldPeriodEndHeader,
        bytes calldata _headers
    ) external returns (bool);

    function ownerAddHeaders(bytes calldata _anchor, bytes calldata _headers) external returns (bool);

    function ownerAddHeadersWithRetarget(
        bytes calldata _oldPeriodStartHeader,
        bytes calldata _oldPeriodEndHeader,
        bytes calldata _headers
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

    enum ScriptTypes {
        P2PK, // 32 bytes
        P2PKH, // 20 bytes        
        P2SH, // 20 bytes          
        P2WPKH, // 20 bytes          
        P2WSH, // 32 bytes
        P2TR // 32 bytes               
    }

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

import "@teleportdao/btc-evm-bridge/contracts/types/ScriptTypesEnum.sol";

interface ICCBurnRouter {

	// Structures

    /// @notice Structure for recording cc burn requests
    /// @param amount of tokens that user wants to burn
    /// @param burntAmount that user will receive (after reducing fees from amount)
    /// @param sender Address of user who requests burning
    /// @param userScript Script hash of the user on Bitcoin
    /// @param deadline of locker for executing the request
    /// @param isTransferred True if the request has been processed
    /// @param scriptType The script type of the user
    /// @param requestIdOfLocker The index of the request for a specific locker
	struct burnRequest {
		uint amount;
		uint burntAmount;
		address sender;
		bytes userScript;
		uint deadline;
		bool isTransferred;
		ScriptTypes scriptType;
		uint requestIdOfLocker;
  	}

  	// Events

	/// @notice Emits when a burn request gets submitted
    /// @param userTargetAddress Address of the user
    /// @param userScript Script of user on Bitcoin
    /// @param scriptType Script type of the user (for bitcoin address)
    /// @param inputAmount Amount of input token (0 if input token is teleBTC)
    /// @param inputToken Address of token that will be exchanged for teleBTC (address(0) if input token is teleBTC)
	/// @param teleBTCAmount amount of teleBTC that user sent OR Amount of teleBTC after exchanging
    /// @param burntAmount that user will receive (after reducing fees)
	/// @param lockerTargetAddress Address of Locker
	/// @param requestIdOfLocker Index of request between Locker's burn requests
	/// @param deadline of Locker for executing the request (in terms of Bitcoin blocks)
  	event CCBurn(
		address indexed userTargetAddress,
		bytes userScript,
		ScriptTypes scriptType,
		uint inputAmount,
		address inputToken,
		uint teleBTCAmount, 
		uint burntAmount,
		address lockerTargetAddress,
		uint requestIdOfLocker,
		uint indexed deadline
	);

	/// @notice Emits when a burn proof is provided
    /// @param lockerTargetAddress Address of Locker
    /// @param requestIdOfLocker Index of paid request of among Locker's requests
    /// @param bitcoinTxId The hash of tx that paid a burn request
	/// @param bitcoinTxOutputIndex The output index in tx
	event PaidCCBurn(
		address indexed lockerTargetAddress,
		uint requestIdOfLocker,
		bytes32 bitcoinTxId,
		uint bitcoinTxOutputIndex
	);

	/// @notice  Emits when a locker gets slashed for withdrawing BTC without proper reason
	/// @param _lockerTargetAddress	Locker's address on the target chain
	/// @param _blockNumber	Block number of the malicious tx
	/// @param txId	Transaction ID of the malicious tx
	/// @param amount Slashed amount
	event LockerDispute(
        address _lockerTargetAddress,
		bytes lockerLockingScript,
    	uint _blockNumber,
        bytes32 txId,
		uint amount
    );

	event BurnDispute(
		address indexed userTargetAddress,
		address indexed _lockerTargetAddress,
		bytes lockerLockingScript,
		uint requestIdOfLocker
	);

	/// @notice Emits when relay address is updated
    event NewRelay(
        address oldRelay, 
        address newRelay
    );

	/// @notice Emits when treasury address is updated
    event NewTreasury(
        address oldTreasury, 
        address newTreasury
    );

	/// @notice Emits when lockers address is updated
    event NewLockers(
        address oldLockers, 
        address newLockers
    );

	/// @notice Emits when TeleBTC address is updated
    event NewTeleBTC(
        address oldTeleBTC, 
        address newTeleBTC
    );

	/// @notice Emits when transfer deadline is updated
    event NewTransferDeadline(
        uint oldTransferDeadline, 
        uint newTransferDeadline
    );

	/// @notice Emits when percentage fee is updated
    event NewProtocolPercentageFee(
        uint oldProtocolPercentageFee, 
        uint newProtocolPercentageFee
    );

	/// @notice Emits when slasher percentage fee is updated
    event NewSlasherPercentageFee(
        uint oldSlasherPercentageFee, 
        uint newSlasherPercentageFee
    );

	/// @notice Emits when bitcoin fee is updated
    event NewBitcoinFee(
        uint oldBitcoinFee, 
        uint newBitcoinFee
    );

	// Read-only functions

    function startingBlockNumber() external view returns (uint);
	
	function relay() external view returns (address);

	function lockers() external view returns (address);

	function teleBTC() external view returns (address);

	function treasury() external view returns (address);

	function transferDeadline() external view returns (uint);

	function protocolPercentageFee() external view returns (uint);

	function slasherPercentageReward() external view returns (uint);

	function bitcoinFee() external view returns (uint); // Bitcoin transaction fee

	function isTransferred(address _lockerTargetAddress, uint _index) external view returns (bool);

	function isUsedAsBurnProof(bytes32 _txId) external view returns (bool);

	// State-changing functions

	function setRelay(address _relay) external;

	function setLockers(address _lockers) external;

	function setTeleBTC(address _teleBTC) external;

	function setTreasury(address _treasury) external;

	function setTransferDeadline(uint _transferDeadline) external;

	function setProtocolPercentageFee(uint _protocolPercentageFee) external;

	function setSlasherPercentageReward(uint _slasherPercentageReward) external;

	function setBitcoinFee(uint _bitcoinFee) external;

	function ccBurn(
		uint _amount, 
		bytes calldata _userScript,
		ScriptTypes _scriptType,
		bytes calldata _lockerLockingScript
	) external returns (uint);

    function ccExchangeAndBurn(
        address _exchangeConnector,
        uint[] calldata _amounts,
        bool _isFixedToken,
        address[] calldata _path,
        uint256 _deadline, 
        bytes memory _userScript,
        ScriptTypes _scriptType,
        bytes calldata _lockerLockingScript
	) external returns (uint);

	function burnProof(
		bytes4 _version,
		bytes memory _vin,
		bytes memory _vout,
		bytes4 _locktime,
		uint256 _blockNumber,
		bytes memory _intermediateNodes,
		uint _index,
		bytes memory _lockerLockingScript,
        uint[] memory _burnReqIndexes,
        uint[] memory _voutIndexes
	) external payable returns (bool);

	function disputeBurn(
		bytes calldata _lockerLockingScript,
		uint[] memory _indices
	) external;

    function disputeLocker(
        bytes memory _lockerLockingScript,
        bytes4[] memory _versions, // [inputTxVersion, outputTxVersion]
        bytes memory _inputVin,
        bytes memory _inputVout,
        bytes memory _outputVin,
        bytes memory _outputVout,
        bytes4[] memory _locktimes, // [inputTxLocktime, outputTxLocktime]
        bytes memory _inputIntermediateNodes,
        uint[] memory _indexesAndBlockNumbers 
		// ^ [inputIndex, inputTxIndex, outputTxIndex, inputTxBlockNumber, outputTxBlockNumber]
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

import "@teleportdao/btc-evm-bridge/contracts/types/ScriptTypesEnum.sol";
import "../TeleOrdinalLib.sol";

interface ITeleOrdinal {

	// Structures

    /// @notice Structure for passing Bitcoin tx to functions
    /// @param version Versions of tx
    /// @param vin Inputs of tx
    /// @param vout Outputs of tx
    /// @param locktime Locktimes of tx
	struct Tx {
        bytes4 version;
		bytes vin;
		bytes vout;
		bytes4 locktime;
  	}

    /// @notice Structure for passing signature
    /// @param r Part of signature (or `e` = schnorr sig challenge)
    /// @param s Part of signature
    /// @param v is needed for recovering the public key (it can be 27 or 28)
	struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
  	}

    /// @notice Structure for storing Ordinal data
    /// @param outputIdx Index of output that includes Ordinal
    /// @param satoshiIdx Index of the inscribed satoshi in the output satoshis
    /// @param isSold True if the Ordinal is sold
    /// @param hasAccepted True if the seller accepted one of the bids
    /// @param bids List of all bids for the Ordinal
    /// @param sellerScript Script hash of seller on Bitcoin
    /// @param scriptType Type of seller's script (e.g. P2PKH)
	struct Ordinal {
        uint outputIdx;
        uint satoshiIdx;
        bool isSold;
        bool hasAccepted;
        bool isListed;
        bytes sellerScript;
        ScriptTypes scriptType;
  	}

    /// @notice Structure for recording buyers bids
    /// @param buyerBTCScript Seller will send the Ordinal to the provided script
    /// @param buyerETHAddress Buyer can withdraw ETH to this address
    /// @param bidAmount Amount of buyre's bid
    /// @param deadline Buyer cannot withdraw funds before deadline (it is based on the bitcoin block number)    		
    /// @param isAccepted True if the bid is accepted by seller
    /// @param paymentToken Address of token that buyer uses for payment
	struct Bid {
		bytes buyerBTCScript;
        ScriptTypes buyerScriptType;
		address buyerETHAddress;
		uint bidAmount;
        uint deadline;
        bool isAccepted;
        address paymentToken;
  	}

  	// Events

    event OrdinalListed(
        bytes32 txId, 
        uint outputIdx, 
        uint satoshiIdx, 
        address seller,
        bytes sellerScript,
        ScriptTypes scriptType,
        string inscriptionId
    );

    event OrdinalDelisted(
        bytes32 txId, 
        address seller
    );

    event NewBid(
        bytes32 txId, 
        uint outputIdx, 
        uint satoshiIdx, 
        address seller, 
        address buyer,
        bytes buyerBTCScript,
        ScriptTypes buyerScriptType,
        uint bidAmount,
        address paymentToken,
        uint bidIdx
    );

    event BidUpdated(
        bytes32 txId, 
        address seller, 
        uint bidIdx,
        uint newAmount
    );

    event BidAccepted(
        bytes32 txId,
        address seller, 
        uint bidIdx,
        uint deadline
    );

    event BidRevoked(
        bytes32 txId,
        address seller, 
        uint bidIdx
    );

    event OrdinalSold(
        bytes32 txId,
        address seller, 
        uint bidIdx,
        bytes32 newTxId,
        uint newOutputIdx,
        uint newSatoshiIdx,
        uint fee
    );

	// Read-only functions

    function transferDeadline() external view returns (uint);
	
	function relay() external view returns (address);

    function teleBTC() external view returns (address);

    function ccBurnRouter() external view returns (address);

    function protocolFee() external view returns (uint);

    function treasury() external view returns (address);

    function isSignRequired() external view returns (bool);

	// State-changing functions

    function setRelay(address _relay) external;

    function setTeleBTC(address _teleBTC) external;

    function setCCBurnRouter(address _ccBurnRouter) external;
    
    function setTransferDeadline(uint _transferDeadline) external;

    function setProtocolFee(uint _protocolFee) external;

    function setTreasury(address _treasury) external;

    function setIsSignRequired(bool _isSignRequired) external;

    function pause() external;

    function unpause() external;

	function listOrdinal(
        ScriptTypes _scriptType,
        TeleOrdinalLib.Signature calldata _signature,
        Tx calldata _tx,
        uint _outputIdx,
		uint _satoshiIdx,
        string calldata inscriptionId
	) external returns (bool);

    function delistOrdinal(bytes32 _txId) external returns (bool);

    function putBid(
        bytes32 _txId,
        address _seller, 
        bytes memory _buyerBTCScript,
        ScriptTypes _scriptType,
        uint _amount,
        address _paymentToken
    ) external payable returns (bool);

    function increaseBid(
        bytes32 _txId,
        address _seller,
        uint _bidIdx,
        uint _newAmount
    ) external payable returns (bool);

    function revokeBid(
        bytes32 _txId, 
        address _seller,
        uint _bidIdx
    ) external returns (bool);

    function acceptBid(bytes32 _txId, uint _bidIdx) external returns (bool);

    function sellOrdinal(
        bytes32 _txId,
        address _seller,
        uint _bidIdx,
        Tx memory _transferTx,
        uint _outputOrdinalIdx,
    	uint256 _blockNumber,
		bytes memory _intermediateNodes,
		uint _index,
        Tx[] memory _inputTxs,
        bytes memory _lockerLockingScript
    ) external payable returns (bool);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

import "./interfaces/ITeleOrdinal.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 
import "@teleportdao/teleswap-contracts/contracts/routers/interfaces/ICCBurnRouter.sol";
import "@teleportdao/btc-evm-bridge/contracts/libraries/BitcoinHelper.sol";
import "@teleportdao/btc-evm-bridge/contracts/relay/interfaces/IBitcoinRelay.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract TeleOrdinal is ITeleOrdinal, Ownable, ReentrancyGuard, Pausable {

    address constant NATIVE_TOKEN = address(1);

    modifier nonZeroAddress(address _address) {
        require(_address != address(0), "TeleOrdinal: address is zero");
        _;
    }

    constructor(
        address _relay, 
        address _teleBTC, 
        address _ccBurnRouter, 
        uint _transferDeadline, 
        uint _protocolFee,
        address _treasury,
        bool _isSignRequired
    ) {
        setRelay(_relay);
        setTeleBTC(_teleBTC);
        setCCBurnRouter(_ccBurnRouter);
        setTransferDeadline(_transferDeadline);
        setProtocolFee(_protocolFee);
        setTreasury(_treasury);
        setIsSignRequired(_isSignRequired);
    }

    address public override relay;
    address public override teleBTC;
    address public override ccBurnRouter;
    bool public override isSignRequired;
    uint public override transferDeadline;
    uint public override protocolFee;
    address public override treasury;
    uint constant public MAX_PROTOCOL_FEE = 10000; // 10000 = %100
    
    mapping(bytes32 => mapping(address => Ordinal)) public ordinals; // mapping from [txId][seller] to listed Ordinal
    mapping(bytes32 => mapping(address => Bid[])) public bids; 
    // ^ mapping from [txId][seller] to listed Ordinal (note: it wasn't possible to define Bid[] in Ordinal)

    receive() external payable {}
    
    /// @notice Setter for Relay contract
    function setRelay(address _relay) public override nonZeroAddress(_relay) onlyOwner {
        relay = _relay;
    }

    /// @notice Setter for teleBTC token
    function setTeleBTC(address _teleBTC) public override onlyOwner {
        teleBTC = _teleBTC;
    }

    /// @notice Setter for CCBurnRouter contract
    function setCCBurnRouter(address _ccBurnRouter) public override onlyOwner {
        ccBurnRouter = _ccBurnRouter;
    }

    /// @notice Setter for treasury address
    function setTreasury(address _treasury) public override nonZeroAddress(_treasury) onlyOwner {
        treasury = _treasury;
    }

    /// @notice Setter for deadline of sending Ordinal
    /// @dev Deadline should be greater than relay finalization parameter
    function setTransferDeadline(uint _transferDeadline) public override onlyOwner {
        uint _finalizationParameter = IBitcoinRelay(relay).finalizationParameter();
        // gives seller enough time to send ordinal
        require(_transferDeadline > _finalizationParameter * 2, "TeleOrdinal: low deadline");
        transferDeadline = _transferDeadline;
    }

    /// @notice Setter for protocol fee
    function setProtocolFee(uint _protocolFee) public override onlyOwner {
        require(MAX_PROTOCOL_FEE >= _protocolFee, "TeleOrdinal: invalid fee");
        protocolFee = _protocolFee;
    }

    /// @notice Setter for signing requirements
    function setIsSignRequired(bool _isSignRequired) public override onlyOwner {
        isSignRequired = _isSignRequired;
    }

    /// @notice Pause the contract so only the functions can be called which are whenPaused
    /// @dev Only owner can pause 
    function pause() external override onlyOwner {
        _pause();
    }

    /// @notice Unpause the contract so only the functions can be called which are whenNotPaused
    /// @dev Only owner can pause
    function unpause() external override onlyOwner {
        _unpause();
    }

    function renounceOwnership() public virtual override onlyOwner {}
    
    /// @notice Lists Ordinal of a user
    /// @dev User should sign the txId of the Ordinal with 
    ///      the same private key that holds the Ordinal if isSignRequired is true
    /// @param _scriptType Type of the account that holds the Ordinal
    /// @param _signature of _txId by _bitcoinPubKey
    /// @param _tx Transaction that includes the Ordinal
    /// @param _outputIdx Index of the output that includes Ordinal
    /// @param _satoshiIdx Index of the inscribed satoshi in the output satoshis
    /// @param _inscriptionId Ordinal's inscription id (genesis tx id + i + output index)
    function listOrdinal(
        ScriptTypes _scriptType,
        TeleOrdinalLib.Signature calldata _signature,
        Tx calldata _tx,
        uint _outputIdx,
		uint _satoshiIdx,
        string calldata _inscriptionId
	) external override whenNotPaused returns (bool) {
        bytes32 txId = BitcoinHelper.calculateTxId(_tx.version, _tx.vin, _tx.vout, _tx.locktime);
        require(!ordinals[txId][_msgSender()].isListed, "TeleOrdinal: already listed");
        
        // Extracts script hash of seller from the output that includes the Ordinal
        bytes memory scriptHash = TeleOrdinalLib.findScriptHash(
            _scriptType, 
            BitcoinHelper.getLockingScript(_tx.vout, _outputIdx) // lockingScript
        );

        // If isSignRequired, seller should provide a valid signature to list Ordinal 
        // (with the same public key that holds the Ordinal)
        if (isSignRequired) {
            TeleOrdinalLib.checkSignature(_scriptType, scriptHash, txId, _signature);
        }

        // Saves listed Ordinal
        Ordinal memory _ordinal;
        _ordinal.outputIdx = _outputIdx;
        _ordinal.satoshiIdx = _satoshiIdx;
        _ordinal.isListed = true;
        _ordinal.sellerScript = scriptHash;
        _ordinal.scriptType = _scriptType;
        ordinals[txId][_msgSender()] = _ordinal;

        emit OrdinalListed(
            txId, 
            _outputIdx, 
            _satoshiIdx, 
            _msgSender(), 
            scriptHash, 
            _ordinal.scriptType,
            _inscriptionId
        );

        return true;
    }

    /// @notice Delists an Ordinal
    /// @dev Revokes all the existing bids
    ///      Reverts if the seller has accepted a bid or sold it
    /// @param _txId of the Ordinal
    function delistOrdinal(bytes32 _txId) external nonReentrant whenNotPaused override returns (bool) {
        address seller = _msgSender();
        require(ordinals[_txId][seller].isListed, "TeleOrdinal: no ordinal");
        require(!ordinals[_txId][seller].isSold, "TeleOrdinal: already sold");
        require(!ordinals[_txId][seller].hasAccepted, "TeleOrdinal: already accepted");

        // Revokes all bids
        for (uint i = 0; i < bids[_txId][seller].length; i++) {
            _revokeBid(_txId, seller,bids[_txId][seller][i].buyerETHAddress, i);
        }

        delete ordinals[_txId][seller];
        emit OrdinalDelisted(
            _txId, 
            seller
        );

        return true;
    }

    /// @notice Puts bid for buyying an Ordinal
    /// @dev User sends the bid amount along with the request
    /// @param _txId of the Ordinal
    /// @param _seller Address of the seller
    /// @param _buyerBTCScript Seller will send the Ordinal to the provided script (it doesn't include op_codes)
    /// @param _scriptType Type of the script
    /// @param _amount of buyer's bid
    /// @param _paymentToken Address of token that buyer uses for payment
    function putBid(
        bytes32 _txId,
        address _seller, 
        bytes memory _buyerBTCScript,
        ScriptTypes _scriptType,
        uint _amount,
        address _paymentToken
    ) external payable whenNotPaused nonZeroAddress(_paymentToken) override returns (bool) {
        _canBid(_txId, _seller);

        // check that the script is valid 
        _checkScriptType(_buyerBTCScript, _scriptType);

        // store bid
        Bid memory _bid;
        _bid.buyerBTCScript =  _buyerBTCScript;
        _bid.buyerScriptType =  _scriptType;
        _bid.buyerETHAddress = _msgSender();
        if (_paymentToken == NATIVE_TOKEN) {
            require(msg.value == _amount, "TeleOrdinal: wrong value");
        } else {
            IERC20(_paymentToken).transferFrom(_msgSender(), address(this), _amount);
        }
        _bid.bidAmount = _amount;
        _bid.paymentToken = _paymentToken;
        bids[_txId][_seller].push(_bid);
        uint bidIdx = bids[_txId][_seller].length - 1;

        emit NewBid(
            _txId, 
            ordinals[_txId][_seller].outputIdx,
            ordinals[_txId][_seller].satoshiIdx,
            _seller, 
            _msgSender(),
            _buyerBTCScript,
            _scriptType,
            _amount,
            _paymentToken,
            bidIdx
        );

        return true;
    }

    /// @notice Increases the existing bid amount
    /// @dev Reverts if the new amount is lower than the previous amount
    ///      User sends the bid difference
    /// @param _txId of the Ordinal
    /// @param _seller Address of the seller
    /// @param _bidIdx od the buyer
    /// @param _newAmount of bid
    function increaseBid(
        bytes32 _txId,
        address _seller,
        uint _bidIdx,
        uint _newAmount
    ) external payable whenNotPaused override returns (bool) {
        _canBid(_txId, _seller);
        require(bids[_txId][_seller][_bidIdx].buyerETHAddress == _msgSender(), "TeleOrdinal: not owner");
        require(_newAmount > bids[_txId][_seller][_bidIdx].bidAmount, "TeleOrdinal: low amount");

        uint bidDifference = _newAmount - bids[_txId][_seller][_bidIdx].bidAmount;
        address paymentToken = bids[_txId][_seller][_bidIdx].paymentToken;

        if (paymentToken == NATIVE_TOKEN) {
            require(msg.value == bidDifference, "TeleOrdinal: wrong value");
        } else {
            IERC20(paymentToken).transferFrom(_msgSender(), address(this), bidDifference);
        }
        
        bids[_txId][_seller][_bidIdx].bidAmount = _newAmount;

        emit BidUpdated(
            _txId, 
            _seller, 
            _bidIdx,
            _newAmount
        );

        return true;
    }

    /// @notice Removes buyer's bid
    /// @dev Buyers can withdraw their funds after deadline 
    ///      (deadline is 0 for a non-accepted bid, so they can withdaw at any time)
    /// @dev Only bid owner can call this function
    /// @param _txId of the Ordinal
    /// @param _seller Address of the seller
    /// @param _bidIdx Index of the bid in bids list
    function revokeBid(
        bytes32 _txId, 
        address _seller,
        uint _bidIdx
    ) external nonReentrant override returns (bool) {
        require(
            bids[_txId][_seller][_bidIdx].buyerETHAddress == _msgSender(),
            "TeleOrdinal: not owner"
        );

        // handle the case where the seller accepted a bid but didn't transfer Ordinal to the buyer before the deadline
        if (bids[_txId][_seller][_bidIdx].isAccepted) {
            // check that deadline is passed but ordinal hasn't been transferred
            require(!ordinals[_txId][_seller].isSold, "TeleOrdinal: ordinal sold");
            require(
                IBitcoinRelay(relay).lastSubmittedHeight() > bids[_txId][_seller][_bidIdx].deadline,
                "TeleOrdinal: deadline not passed"
            );
            // change the status of the Ordinal (so seller can accept a new bid)
            ordinals[_txId][_seller].hasAccepted = false;
        }

        _revokeBid(_txId, _seller, _msgSender(), _bidIdx);

        return true;
    }

    /// @notice Accepts one of the existing bids
    /// @dev Will be reverted if the seller has already accepted a bid
    /// @param _txId of the Ordinal
    /// @param _bidIdx Index of the bid in bids list
    function acceptBid(bytes32 _txId, uint _bidIdx) external nonReentrant whenNotPaused override returns (bool) {
        require(!ordinals[_txId][_msgSender()].hasAccepted, "TeleOrdinal: already accepted");
        require(bids[_txId][_msgSender()].length > _bidIdx, "TeleOrdinal: invalid idx");  

        // seller has a limited time to send the Ordinal and provide a proof for it to get it
        ordinals[_txId][_msgSender()].hasAccepted = true;
        bids[_txId][_msgSender()][_bidIdx].isAccepted = true;
        bids[_txId][_msgSender()][_bidIdx].deadline = IBitcoinRelay(relay).lastSubmittedHeight() + transferDeadline;

        emit BidAccepted(
            _txId, 
            _msgSender(),
            _bidIdx, 
            bids[_txId][_msgSender()][_bidIdx].deadline
        );

        return true;
    }

    /// @notice Sends ETH to seller after checking the proof of transfer
    /// @param _txId of the Ordinal
    /// @param _seller Address of the seller
    /// @param _bidIdx Index of the accepted bid in bids list
    /// @param _transferTx transaction that transffred Ordinal from seller to buyer
    /// @param _ordinalOutputIdx Index of output that includes Ordinal
    /// @param _blockNumber Height of the block containing _transferTx
    /// @param _intermediateNodes Merkle inclusion proof for _transferTx
    /// @param _index Index of _transferTx in the block
    /// @param _inputTxs List of all transactions that were spent by _transferTx before the input that spent the Ordinal
    /// @param _lockerLockingScript Locker's locking script (it will be passed if the payment token is teleBTC)
    function sellOrdinal(
        bytes32 _txId,
        address _seller,
        uint _bidIdx,
        Tx memory _transferTx,
        uint _ordinalOutputIdx,
    	uint256 _blockNumber,
		bytes memory _intermediateNodes,
		uint _index,
        Tx[] memory _inputTxs,
        bytes memory _lockerLockingScript
    ) external payable nonReentrant whenNotPaused override returns (bool) {
        // checks that Ordinal hasn't been sold before
        require(!ordinals[_txId][_seller].isSold, "TeleOrdinal: sold ordinal");
        require(bids[_txId][_seller][_bidIdx].isAccepted, "TeleOrdinal: not accepted");

        // check inclusion of transfer tx
        bytes32 transferTxId = BitcoinHelper.calculateTxId(
            _transferTx.version, 
            _transferTx.vin, 
            _transferTx.vout, 
            _transferTx.locktime
        );
        require(
            _isConfirmed(
                transferTxId,
                _blockNumber,
                _intermediateNodes,
                _index
            ),
            "TeleOrdinal: not finalized"
        );

        // find the index of Ordinal satoshi
        uint ordinalIdx;
        ordinalIdx = _ordinalIdx(_txId, _seller,  _transferTx.vin, _inputTxs);

        // check that weather the Ordinal is transferred to the expected buyer or not and send funds
        _checkOrdinalTransfer(
            _txId, 
            _seller, 
            _bidIdx, 
            _transferTx.vout, 
            _ordinalOutputIdx, 
            ordinalIdx
        );

        uint fee = _sendTokens(_txId, _seller, _bidIdx, _lockerLockingScript);
 
        emit OrdinalSold(
            _txId, 
            _seller, 
            _bidIdx, 
            transferTxId, 
            _ordinalOutputIdx, 
            ordinalIdx, 
            fee
        );

        return true;
    }

    /// @notice Checks the bidding conditions
    /// @dev Conditions for bidding: Ordinals exists, no offer accepted, not sold
    function _canBid(
        bytes32 _txId, 
        address _seller
    ) private view {
        require(ordinals[_txId][_seller].isListed, "TeleOrdinal: not listed");
        require(!ordinals[_txId][_seller].hasAccepted, "TeleOrdinal: already accepted");
        require(!ordinals[_txId][_seller].isSold, "TeleOrdinal: sold ordinal");
    }

    /// @notice Revokes a bid
    function _revokeBid(
        bytes32 _txId, 
        address _seller, 
        address _buyer, 
        uint _bidIdx
    ) private {
        if (bids[_txId][_seller][_bidIdx].paymentToken == NATIVE_TOKEN) {
            // Sends ETH to buyer
            Address.sendValue(payable(_buyer), bids[_txId][_seller][_bidIdx].bidAmount);
        } else {
            IERC20(bids[_txId][_seller][_bidIdx].paymentToken).transfer(
                _buyer,
                bids[_txId][_seller][_bidIdx].bidAmount
            );
        }

        // Deletes the bid
        delete bids[_txId][_seller][_bidIdx];
        emit BidRevoked(_txId, _seller, _bidIdx);
    }

    /// @notice Checks that the bitcoin script provided by buyer is valid (so seller can send the btc to it)
    /// @param _script seller locking script (without op codes)
    /// @param _scriptType type of locking script (e.g. P2PKH, P2TR)
    function _checkScriptType(bytes memory _script, ScriptTypes _scriptType) private pure {
        if (_scriptType == ScriptTypes.P2PK || _scriptType == ScriptTypes.P2WSH || _scriptType == ScriptTypes.P2TR) {
            require(_script.length == 32, "TeleOrdinal: invalid script");
        } else {
            require(_script.length == 20, "TeleOrdinal: invalid script");
        }
    }

    /// @notice Finds the index of Ordinal in the input of transfer tx
    /// @param _txId of the Ordinal
    /// @param _seller Address of the seller
    /// @param _vin inputs of transaction that transffred Ordinal from seller to buyer
    /// @param _inputTxs List of all transactions that were spent by _transferTx before the input that spent the Ordinal
    function _ordinalIdx(
        bytes32 _txId,
        address _seller,
        bytes memory _vin,
        Tx[] memory _inputTxs
    ) internal view returns (uint _idx) {
        bytes32 _outpointId;
        uint _outpointIndex;

        // calculate sum of all the provided inputs in transferTx (before input that spent Ordinal)
        for (uint i = 0; i < _inputTxs.length; i++) {
            (_outpointId, _outpointIndex) = BitcoinHelper.extractOutpoint(
                _vin,
                i
            );

            // check that "outpoint tx id == input tx id"
            // make sure that the provided input txs are valid
            require(
                _outpointId == BitcoinHelper.calculateTxId(
                    _inputTxs[i].version, 
                    _inputTxs[i].vin, 
                    _inputTxs[i].vout, 
                    _inputTxs[i].locktime
                ),
                "TeleOrdinal: outpoint != input tx"
            );

            // sum of all inputs of transfer tx before the input that spent Ordinal
            _idx += BitcoinHelper.parseOutputValue(_inputTxs[i].vout, _outpointIndex);
        }

        (_outpointId, _outpointIndex) = BitcoinHelper.extractOutpoint(
            _vin,
            _inputTxs.length // this is the input that spent the Ordinal
        );

        // Checks that "outpoint tx id == _txId"
        require(
            (_outpointId == _txId) && (_outpointIndex == ordinals[_txId][_seller].outputIdx),
            "TeleOrdinal: outpoint not match with _txId"
        );

        // find the positon of Ordinal satoshi in input of transfer tx
        _idx += ordinals[_txId][_seller].satoshiIdx;
    }

    /// @notice Checks that weather the Ordinal is transferred to buyer or not
    /// @param _txId of the Ordinal
    /// @param _seller Address of the seller
    /// @param _bidIdx Index of the accepted bid in bids list
    /// @param _vout output of transaction that transffred Ordinal from seller to buyer
    /// @param _ordinalOutputIdx Index of output that includes Ordinal
    /// @param _ordinalInputIdx Index of satoshi Ordinal in input of tx
    function _checkOrdinalTransfer(
        bytes32 _txId,
        address _seller,
        uint _bidIdx,
        bytes memory _vout,
        uint _ordinalOutputIdx,
        uint _ordinalInputIdx
    ) internal {
        // find number of satoshis before the output that includes the Ordinal
        uint outputValue;
        for (uint i = 0; i < _ordinalOutputIdx; i++) {
            outputValue += BitcoinHelper.parseOutputValue(_vout, i);
        }

        if (_ordinalOutputIdx != 0) {
            require(
                _ordinalInputIdx > outputValue,
                "TeleOrdinal: not transferred"
            );
        }

        require(
            _ordinalInputIdx <= outputValue + BitcoinHelper.parseValueFromSpecificOutputHavingScript(
                _vout,
                _ordinalOutputIdx,
                bids[_txId][_seller][_bidIdx].buyerBTCScript,
                bids[_txId][_seller][_bidIdx].buyerScriptType
            ),
            "TeleOrdinal: not transferred"
        );

        ordinals[_txId][_seller].isSold = true;

    }

    /// @notice Sends tokens to seller and treasury
    /// @dev Burns teleBTC for seller (if the payment token is teleBTC)
    function _sendTokens(
        bytes32 _txId,
        address _seller,
        uint _bidIdx,
        bytes memory _lockerLockingScript
    ) internal returns (uint _fee) {

        address paymentToken = bids[_txId][_seller][_bidIdx].paymentToken;
        uint bidAmount = bids[_txId][_seller][_bidIdx].bidAmount;
        _fee = protocolFee * bidAmount / MAX_PROTOCOL_FEE;
        
        if (paymentToken == NATIVE_TOKEN) {
            Address.sendValue(payable(_seller), bidAmount - _fee);
            if (_fee > 0) {
                Address.sendValue(payable(treasury), _fee);
            }
        } else if (paymentToken == teleBTC) {
            // Burns teleBTC for seller
            IERC20(teleBTC).approve(ccBurnRouter, bidAmount - _fee);
            ICCBurnRouter(ccBurnRouter).ccBurn(
                bidAmount - _fee,
                ordinals[_txId][_seller].sellerScript,
                ordinals[_txId][_seller].scriptType,
                _lockerLockingScript
            );
            if (_fee > 0) {
                IERC20(bids[_txId][_seller][_bidIdx].paymentToken).transfer(
                    treasury,
                    _fee
                );
            }
        } else { 
            IERC20(paymentToken).transfer(
                _seller,
                bidAmount - _fee
            );
            if (_fee > 0) {
                IERC20(paymentToken).transfer(
                    treasury,
                    _fee
                );
            }
        }
    }

    /// @notice Checks inclusion of the transaction in the specified block
    /// @dev Calls the relay contract to check Merkle inclusion proof
    /// @param _txId Id of the transaction
    /// @param _blockNumber Height of the block containing the transaction
    /// @param _intermediateNodes Merkle inclusion proof for the transaction
    /// @param _index Index of transaction in the block
    /// @return True if the transaction was included in the block
    function _isConfirmed(
        bytes32 _txId,
        uint256 _blockNumber,
        bytes memory _intermediateNodes,
        uint _index
    ) private returns (bool) {
        // Finds fee amount
        uint feeAmount = IBitcoinRelay(relay).getBlockHeaderFee(_blockNumber, 0);
        require(msg.value >= feeAmount, "TeleOrdinal: relay fee is not sufficient");

        // Calls relay contract
        bytes memory data = Address.functionCallWithValue(
            relay,
            abi.encodeWithSignature(
                "checkTxProof(bytes32,uint256,bytes,uint256)",
                _txId,
                _blockNumber,
                _intermediateNodes,
                _index
            ),
            feeAmount
        );

        // Sends extra ETH back to _msgSender()
        Address.sendValue(payable(_msgSender()), msg.value - feeAmount);

        return abi.decode(data, (bool));
    }

    // /// @notice Returns a sliced bytes
    // /// @param _data Data that is sliced
    // /// @param _start Start index of slicing
    // /// @param _end End index of slicing
    // /// @return _result The result of slicing
    // function _sliceBytes(
    //     bytes memory _data,
    //     uint _start,
    //     uint _end
    // ) internal pure returns (bytes memory _result) {
    //     bytes1 temp;
    //     for (uint i = _start; i <= _end; i++) {
    //         temp = _data[i];
    //         _result = abi.encodePacked(_result, temp);
    //     }
    // }

    // /// @notice Calculates bitcoin double hash function
    // function _doubleHash(bytes memory _input) internal pure returns(bytes memory) {
    //     bytes32 inputHash1 = sha256(_input);
    //     bytes20 inputHash2 = ripemd160(abi.encodePacked(inputHash1));
    //     return abi.encodePacked(inputHash2);
    // }

    // /// @notice Compare two bytes string
    // function _compareBytes(bytes memory _a, bytes memory _b) internal pure returns (bool) {
    //     return keccak256(_a) == keccak256(_b);
    // }

    // /// @notice Convert bytes with length 20 to address
    // function _bytesToAddress(bytes memory _data) public pure returns (address) {
    //     require(_data.length == 20, "TeleOrdinal: Invalid len");
    //     address addr;
    //     assembly {
    //         addr := mload(add(_data, 20))
    //     }
    //     return addr;
    // }

    // /// @notice Convert bytes with length 32 to bytes32
    // function _convertToBytes32(bytes memory _data) public pure returns (bytes32) {
    //     require(_data.length == 32, "TeleOrdinal: Invalid len");
    //     bytes32 result;
    //     assembly {
    //         result := mload(add(_data, 32))
    //     }
    //     return result;
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

import "@teleportdao/btc-evm-bridge/contracts/types/ScriptTypesEnum.sol";

library TeleOrdinalLib {

    /// @notice Structure for passing signature
    /// @param bitcoinPubKey Bitcoin PubKey of the Ordinal holder (without starting '04'). 
    ///                       Don't need to be passed in the case of Taproot
    /// @param r Part of signature (or `e` = schnorr sig challenge)
    /// @param s Part of signature
    /// @param v is needed for recovering the public key (it can be 27 or 28)
	struct Signature {
        bytes bitcoinPubKey;
        bytes32 r;
        bytes32 s;
        uint8 v;
  	}

    bytes1 constant public FOUR = 0x04;    
    uint256 constant public Q = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141; 
    // ^ secp256k1 group order

    function findScriptHash(
        ScriptTypes _scriptType,
        bytes memory lockingScript
    ) external pure returns (bytes memory scriptHash) {
        if (_scriptType == ScriptTypes.P2TR) { 
            // locking script = OP_1 (1 byte) 20 (1 byte) PUB_KEY (32 bytes)
            scriptHash = _sliceBytes(lockingScript, 2, 33);
        } else if (_scriptType == ScriptTypes.P2WPKH) { 
            // locking script = ZERO (1 byte) PUB_KEY_HASH (20 bytes)
            scriptHash = _sliceBytes(lockingScript, 1, 20);
        } else if (_scriptType == ScriptTypes.P2PKH) { 
            // locking script = OP_DUP (1 byte) OP_HASH160 (2 bytes) PUB_KEY_HASH (20 bytes)  OP_EQUALVERIFY OP_CHECKSIG
            scriptHash = _sliceBytes(lockingScript, 3, 22);
        } else if (_scriptType == ScriptTypes.P2PK) { 
            // locking script = PUB_KEY (65 bytes) OP_CHECKSIG
            scriptHash = _sliceBytes(lockingScript, 0, 64);
        } else {
            revert("TeleOrdinal: invalid type");
        }
    }

    function checkSignature(
        ScriptTypes _scriptType,
        bytes memory _scriptHash,
        bytes32 _txId,
        Signature memory _signature
    ) external pure {
        require(_signature.bitcoinPubKey.length == 64 || _signature.bitcoinPubKey.length == 0, "invalid pub key");
        // ^ 0 for taproot, 64 for other cases

        if (_scriptType == ScriptTypes.P2TR) {
            require(
                _verifySchnorr(_convertToBytes32(_scriptHash), _txId, _signature),
                "TeleOrdinal: not ordinal owner"
            );
        } else {
            require(
                _compareBytes(
                    _scriptHash, _doubleHash(abi.encodePacked(FOUR, _signature.bitcoinPubKey))
                ),
                "TeleOrdinal: wrong pub key"
            );

            // check that the signature for txId is valid
            // etherum address = last 20 bytes of hash(pubkey)
            require(
                _bytesToAddress(
                    _sliceBytes(
                        abi.encodePacked(keccak256(_signature.bitcoinPubKey)), 
                        12, 
                        31
                    )
                ) == ecrecover(_txId, _signature.v, _signature.r, _signature.s),
                "TeleOrdinal: not ordinal owner"
            );
        }
    }


    /// @notice Checks the validity of schnorr signature
    /// @param _pubKeyX public key x-coordinate
    /// @param _msg msg hash that user signed
    /// @param _signature of the msg
    function _verifySchnorr(
        bytes32 _pubKeyX,
        bytes32 _msg,
        Signature memory _signature
    ) private pure returns (bool) {
        bytes32 sp = bytes32(Q - mulmod(uint256(_signature.s), uint256(_pubKeyX), Q));
        bytes32 ep = bytes32(Q - mulmod(uint256(_signature.r), uint256(_pubKeyX), Q));
        require(sp != 0, "TeleOrdinal: wrong sig");
        address R = ecrecover(sp, _signature.v, _pubKeyX, ep);
        require(R != address(0), "TeleOrdinal: ecrecover failed");
        return _signature.r == keccak256(
            abi.encodePacked(R, uint8(_signature.v), _pubKeyX, _msg)
        );
    }

    /// @notice Returns a sliced bytes
    /// @param _data Data that is sliced
    /// @param _start Start index of slicing
    /// @param _end End index of slicing
    /// @return _result The result of slicing
    function _sliceBytes(
        bytes memory _data,
        uint _start,
        uint _end
    ) private pure returns (bytes memory _result) {
        bytes1 temp;
        for (uint i = _start; i <= _end; i++) {
            temp = _data[i];
            _result = abi.encodePacked(_result, temp);
        }
    }

    /// @notice Calculates bitcoin double hash function
    function _doubleHash(bytes memory _input) private pure returns(bytes memory) {
        bytes32 inputHash1 = sha256(_input);
        bytes20 inputHash2 = ripemd160(abi.encodePacked(inputHash1));
        return abi.encodePacked(inputHash2);
    }

    /// @notice Compare two bytes string
    function _compareBytes(bytes memory _a, bytes memory _b) private pure returns (bool) {
        return keccak256(_a) == keccak256(_b);
    }

    /// @notice Convert bytes with length 20 to address
    function _bytesToAddress(bytes memory _data) private pure returns (address) {
        require(_data.length == 20, "TeleOrdinal: Invalid len");
        address addr;
        assembly {
            addr := mload(add(_data, 20))
        }
        return addr;
    }

    /// @notice Convert bytes with length 32 to bytes32
    function _convertToBytes32(bytes memory _data) private pure returns (bytes32) {
        require(_data.length == 32, "TeleOrdinal: Invalid len");
        bytes32 result;
        assembly {
            result := mload(add(_data, 32))
        }
        return result;
    }
}