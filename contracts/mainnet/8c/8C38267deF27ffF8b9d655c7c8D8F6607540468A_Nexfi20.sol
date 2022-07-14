/**
 *Submitted for verification at polygonscan.com on 2022-07-14
*/

// File: contracts/libs/Context.sol

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() {}

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/libs/Ownable.sol

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/libs/SafeMath.sol

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/libs/Address.sol

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
        // solhint-disable-next-line no-inline-assembly
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// File: contracts/libs/IERC20.sol

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// File: contracts/libs/SafeERC20.sol

pragma solidity ^0.8.0;



/**
 * @title SafeERC20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: BEP20 operation did not succeed"
            );
        }
    }
}

// File: contracts/libs/ReentrancyGuard.sol

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

    constructor () {
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

// File: contracts/libs/IERC165.sol

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

// File: contracts/libs/IERC1155.sol

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// File: contracts/libs/IERC1155Receiver.sol

pragma solidity ^0.8.0;

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: contracts/nx20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;






contract Nexfi20 is Ownable, ReentrancyGuard, IERC1155Receiver {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // nexfi 1.5 contract
    INexfi15 private nexfi15Contract = INexfi15(0x6691b9ecE2F97cF1Ca6956FE728fA3125a217DD1);

    address public nftBoostContractAddress = address(0);

    // staked token
    IERC20 public stakedToken;

    // Total staking tokens
    uint256 public totalStakings;

    // Total reward tokens
    uint256 public totalRewards;

    // reward start time (unixtime)
    uint256 public rewardStartTime;

    // reward end time (unixtime)
    uint256 public rewardEndTime;

    // reward period (sec)
    uint256 public rewardPeriod;

    // stake limit per user
    uint256 public stakingLimitPerUser = 1000000000000000000000000;

    // fixed reward ratio, multiplied by 100. Default value 100%
    // based reward period
    uint256 public rewardPerPeriod = 10000;

    // reward token per staked token rate
    uint256 public exchangeRate = 200;
    uint256 public exchangeRateDenominator = 1;

    // precision factor
    uint256 public PRECISION_FACTOR = 10000000000;

    // initialized flag
    bool public isInitialized = false;

    // force suspend flag
    bool public suspended = false;
    
    address[] public userList;

    // Extra Boost
    mapping(address => mapping(uint256 => BoostInfo)) private extraBoosts;
    address[] public nftContractAddressList;
    mapping(address => uint256[]) public nftTokenIdList;


    // Info of each user that stakes tokens (stakedToken)
    mapping(address => UserInfo) public userInfo;

    uint maxSubNftLimit = 3;

    struct NftInfo {
        address nftAddress;
        uint256 nftTokenId;
    }

    struct UserInfo {
        uint256 amount; // How many staked tokens the user has provided
        uint256 lastRewardTime; // Last rewarded time
        bool registered; // it will add user in address list on first deposit
        address addr; //address of user
        uint256 rewardLockedUp; // Reward locked up.
        uint256 lastDepositedTime; // keeps track of deposited time for potential penalty
        address nftAddress;     // deposited main NFT item contract address
        uint256 nftTokenId;     // deposited main NFT item token ID
        NftInfo[] nftItems;     // deposited sub NFT item info
    }

    struct BoostInfo {
        uint256 boostPercent; // boost percentage in main item
        uint256 stakedAmount; // total staked token amount with this nft boosted
        address nftContractAddress;
        uint256 nftTokenId;
        string nftName;
        uint nftCategory;      // 0: main & sub, 1: sub only
        uint256 subBoostPercent;    // boost percentage in sub item
        uint setItemCategory;   // 0: none,
        uint setItemBonus;
    }
    uint public numSetCategory;    // number of set category
    mapping(uint => uint256) public setItemCategoryBonus;    // bonus of set category

    event Initialized();
    event Withdrawn(address indexed account, uint256 amount);
    event Deposited(address indexed account, uint256 amount);
    event RewardLocked(address indexed account, uint256 amount, uint256 timestamp);
    event AdminTokenRecovery(address token);
    event NftDeposited(address indexed account, address nftAddress, uint256 nftTokenId);
    event NftWithdrawn(address indexed account, address nftAddress, uint256 nftTokenId);

    function initialize(
        address _stakedToken,
        uint256 _rewardStartTime,
        uint256 _rewardEndTime,
        uint256 _exchangeRate,
        uint256 _exchangeRateDenominator,
        uint256 _rewardPerPeriod
    ) external onlyOwner {
        require(!isInitialized, "Already initialized");
        require(block.timestamp < _rewardStartTime, 
                "reward start time should be after now");
        require(_rewardEndTime > _rewardStartTime, 
                "reward end time should be after start time");
        require(_stakedToken != address(0), "invalid address");
        require(_exchangeRate > 0, "invalid exchange rate");
        require(_exchangeRateDenominator > 0, "invalic exchange rate denominator");

        stakedToken = IERC20(_stakedToken); 
        rewardStartTime = _rewardStartTime;
        rewardEndTime = _rewardEndTime;
        rewardPeriod = rewardEndTime.sub(rewardStartTime);

        exchangeRate = _exchangeRate;
        exchangeRateDenominator = _exchangeRateDenominator;

        rewardPerPeriod = _rewardPerPeriod;

        isInitialized = true;

        emit Initialized();
        
    }

    function setNftBoostContract(address _address) external onlyOwner {
        nftBoostContractAddress = _address;
    }

    function updateStekingLimitPerUser(uint256 _limit) external onlyOwner {
        require(_limit > stakingLimitPerUser, "new limit should be greater than old limit");
        stakingLimitPerUser = _limit;
    }

    function suspend(bool _suspended) external onlyOwner {
        suspended = _suspended;
    }

    function canDeposit() public view returns (bool available){
        available = !suspended 
                    && block.timestamp < rewardEndTime; 
    }

    function deposit(uint256 _amount) external nonReentrant {
        require(_msgSender() == tx.origin, "Invalid Access");
        require(canDeposit(), "not running now.");

        UserInfo storage user = userInfo[_msgSender()];
        require(user.amount.add(_amount) <= stakingLimitPerUser, "limit exceeded");
        
        if (user.amount == 0 && user.registered == false) {
            userList.push(_msgSender());
            user.registered = true;
            user.addr = address(_msgSender());
        }

        lockupPendingreward();


        // Every time when there is a new deposit, reset last withdrawn time
        user.lastDepositedTime = block.timestamp;

        uint256 balanceBefore = stakedToken.balanceOf(address(this));
        stakedToken.safeTransferFrom(
            address(_msgSender()),
            address(this),
            _amount
        );

        _amount = stakedToken.balanceOf(address(this)).sub(balanceBefore);

        user.amount = user.amount.add(_amount);
        totalStakings = totalStakings.add(_amount);

        emit Deposited(msg.sender, _amount);

    }

    function depositNft(
        address _nftAddress,
        uint256 _nftTokenId
    ) external nonReentrant {
        require(_msgSender() == tx.origin, "Invalid Access");
        require(canDeposit(), "not running now.");
        require(getExtraBoost(_nftAddress, _nftTokenId) > 0, "This NFT is not eligible");

        UserInfo storage user = userInfo[_msgSender()];

        require(user.nftAddress == address(0), "alredy deposited");

        lockupPendingreward();

        require(
            IERC1155(_nftAddress).isApprovedForAll(
                _msgSender(),
                address(this)
            ),
            "NFT not approved for the staking contract"
        );
        IERC1155(_nftAddress).safeTransferFrom(
            _msgSender(),
            address(this),
            _nftTokenId,
            1,
            ""
        );

        user.nftAddress = _nftAddress;
        user.nftTokenId = _nftTokenId;
        emit NftDeposited(_msgSender(), _nftAddress, _nftTokenId);
    }

    /**
     * @notice Deposit nft, then the staked token amount will be boosted
     */
    function depositSubNft(
        address _nftAddress,
        uint256 _nftTokenId
    ) external nonReentrant {
        require(canDeposit(), "not running now.");

        UserInfo storage user = userInfo[_msgSender()];
        require(
            user.nftAddress != address(0),
            "Main NFT is not staked"
        );
        require(
            extraBoosts[_nftAddress][_nftTokenId].subBoostPercent > 0,
            "This NFT is not eligible"
        );
        require(
            user.nftAddress != _nftAddress
            || user.nftTokenId != _nftTokenId,
            "it already staked same NFT"
        );

        uint256 currentStakedNftCount = 0;
        uint256 availableIndex = maxSubNftLimit;
        bool _alreadyStakedSameNft = false;
        NftInfo memory _info;
        for (uint i=0; i<user.nftItems.length; i++) {
            _info = user.nftItems[i];
            if (_info.nftAddress != address(0)) {
                currentStakedNftCount++;
                if (_info.nftAddress == _nftAddress && _info.nftTokenId == _nftTokenId) {
                    _alreadyStakedSameNft = true;
                    break;
                }
            } else {
                availableIndex = i;
            }
        }
        require(_alreadyStakedSameNft == false, "Already staked the same NFT");

        require(
            currentStakedNftCount < maxSubNftLimit,
            "Item staking limit has been exceeded"
        );

        lockupPendingreward();

        require(
            IERC1155(_nftAddress).isApprovedForAll(
                _msgSender(),
                address(this)
            ),
            "NFT not approved for the staking contract"
        );
        IERC1155(_nftAddress).safeTransferFrom(
            _msgSender(),
            address(this),
            _nftTokenId,
            1,
            ""
        );

        NftInfo memory _nftInfo;
        _nftInfo.nftAddress = _nftAddress;
        _nftInfo.nftTokenId = _nftTokenId;
        if (availableIndex == maxSubNftLimit) {
            user.nftItems.push(_nftInfo);
        } else {
            user.nftItems[availableIndex] = _nftInfo;
        }
        
        emit NftDeposited(_msgSender(), _nftAddress, _nftTokenId);
    }

    function withdraw() external nonReentrant {
        require(_msgSender() == tx.origin, "Invalid Access");
        require(canWithdraw(_msgSender()), "cannot withdraw now");
        
        UserInfo storage user = userInfo[_msgSender()];
        require(user.amount > 0, "you haven't staked");
        
        lockupPendingreward();

        stakedToken.safeTransfer(_msgSender(), user.amount);
        emit Withdrawn(_msgSender(), user.amount);
        user.amount = 0;

    }

    function withdrawNft() external nonReentrant {
        require(_msgSender() == tx.origin, "Invalid Access");

        UserInfo storage user = userInfo[_msgSender()];
        require(
            user.nftAddress != address(0),
            "No nft staked yet"
        );

        lockupPendingreward();

        IERC1155(user.nftAddress).safeTransferFrom(
            address(this),
            _msgSender(),
            user.nftTokenId,
            1,
            ""
        );

        emit NftWithdrawn(
            _msgSender(),
            user.nftAddress,
            user.nftTokenId
        );

        user.nftAddress = address(0);
        user.nftTokenId = 0;

    }

    function withdrawSubNftAll() public nonReentrant {
        require(_msgSender() == tx.origin, "Invalid Access");

        lockupPendingreward();
        UserInfo memory user = userInfo[_msgSender()];
        for (uint i=0; i<user.nftItems.length; i++) {
            _withdrawSubNft(i);
        }
    }

    function withdrawSubNft(uint _index) public nonReentrant {
        require(_msgSender() == tx.origin, "Invalid Access");

        lockupPendingreward();
        _withdrawSubNft(_index);
    }

    function _withdrawSubNft(uint _index) private {
        UserInfo storage user = userInfo[_msgSender()];
        if (_index < user.nftItems.length) {
            NftInfo memory info = user.nftItems[_index];
            if (info.nftAddress != address(0)) {
                IERC1155(info.nftAddress).safeTransferFrom(
                    address(this),
                    _msgSender(),
                    info.nftTokenId,
                    1,
                    ""
                );

                emit NftWithdrawn(
                    _msgSender(),
                    info.nftAddress,
                    info.nftTokenId
                );

                delete user.nftItems[_index];
            }
        }
    }

    function lockupPendingreward() internal {
        UserInfo storage user = userInfo[_msgSender()];
        uint256 pending = pendingReward(_msgSender());
        totalRewards = totalRewards.add(pending).sub(user.rewardLockedUp);
        user.rewardLockedUp = pending;
        user.lastRewardTime = block.timestamp;
        emit RewardLocked(_msgSender(), user.rewardLockedUp, block.timestamp);
    }

    function balanceOf(address account) public view returns (uint256 amount) {
        UserInfo memory user = userInfo[account];
        amount = user.amount;
    }

    function pendingReward(address account) public view returns (uint256 pending) {
        UserInfo memory user = userInfo[account];
        uint256 etmAmount = getUserEtmAmount(account);
        // reward formula
        {
            pending = getUserDuration(account).mul(etmAmount)
                        .mul(rewardPerPeriod)
                        .mul(exchangeRate).mul(PRECISION_FACTOR)
                        .div(exchangeRateDenominator);
        }
        {
            pending = pending.div(rewardPeriod).div(10000)
                        .div(PRECISION_FACTOR)
                        .add(user.rewardLockedUp);
        }
    }

    function getUserDuration(address account) public view returns (uint256 duration) {
        UserInfo memory user = userInfo[account];
        
        uint256 endTime = block.timestamp;
        if (endTime > rewardEndTime) {
            endTime = rewardEndTime;
        }
        uint256 startTime = rewardStartTime;
        if (startTime < user.lastRewardTime) {
            startTime = user.lastRewardTime;
        }
        if (startTime >= endTime) {
            duration = 0;
        } else {
            duration = endTime.sub(startTime);
        }
    }

    function getUserSubNftItems(address account) public view 
        returns (
            NftInfo[] memory nftItems
        )
    {
        UserInfo memory user = userInfo[account];
        nftItems = user.nftItems;
    }

    function canWithdraw(address account) public view returns (bool _canWithdraw) {
        _canWithdraw = block.timestamp > rewardEndTime && balanceOf(account) > 0 && !suspended;
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress)
        external
        onlyOwner
    {
        require(
            _tokenAddress != address(stakedToken),
            "Cannot withdraw staked token"
        );

        IERC20(_tokenAddress).safeTransfer(address(msg.sender), IERC20(_tokenAddress).balanceOf(address(this)));

        emit AdminTokenRecovery(_tokenAddress);
    }


    function _addUserInfo(address account, uint256 amount) internal {
        UserInfo storage user = userInfo[account];
        if (!user.registered) {
            user.registered = true;
            userList.push(account);
            user.addr = account;
        }
        totalStakings = totalStakings.add(amount).sub(user.amount);
        user.amount = amount;
    }

    // function addUserInfoBatch(address[] calldata accounts, uint256[] calldata amounts) public onlyOwner {
    //     uint256 accountLen = accounts.length;
    //     uint256 amountLen = amounts.length;
    //     require(accountLen == amountLen, "these length should be same");

    //     for (uint i=0; i<accountLen; i++) {
    //         _addUserInfo(accounts[i], amounts[i]);
    //     }
    // }

    function importUserInfo(uint256 _offset, uint256 _limit) external onlyOwner 
        returns (
            uint256 nextOffset,
            uint256 total
        )
    {
        require(block.timestamp < rewardStartTime, "cannot import user info after started");

        (INexfi15.UserInfo[] memory users, uint256 _next, uint256 _total) = nexfi15Contract.getUsersPaging(_offset, _limit);

        for (uint256 i=0; i<users.length; i++) {
            uint256 pending = nexfi15Contract.pendingReward(users[i].addr);
            _addUserInfo(users[i].addr, users[i].amount.add(pending));
        }

        nextOffset = _next;
        total = _total;
    }

    function getUsersReward(uint256 _offset, uint256 _limit)
        public
        view
        returns (
            address[] memory addresses,
            uint256[] memory rewards,
            uint256 nextOffset,
            uint256 total
        )
    {
        total = userList.length;
        if (_limit == 0) {
            _limit = 1;
        }

        if (_limit > total.sub(_offset)) {
            _limit = total.sub(_offset);
        }
        nextOffset = _offset.add(_limit);

        addresses = new address[](_limit);
        rewards = new uint256[](_limit);
        UserInfo memory user;
        for (uint256 i = 0; i < _limit; i++) {
            user = userInfo[userList[_offset.add(i)]];
            addresses[i] = user.addr;
            rewards[i] = pendingReward(user.addr);
        }
    }

    /**
     * @notice Update additional boost percentage for the specific nft and id
     * @dev Can only be called by the owner
     */
    function updateExtraBoost(
        address _nftAddress,
        uint256 _nftTokenId,
        uint256 _percent,
        string calldata _nftName,
        uint _nftCategory,
        uint256 _subBoostPercent,
        uint _setItemCategory,
        uint _setItemBonus
    ) external onlyOwner {

        extraBoosts[_nftAddress][_nftTokenId].boostPercent = _percent;
        extraBoosts[_nftAddress][_nftTokenId].nftContractAddress = _nftAddress;
        extraBoosts[_nftAddress][_nftTokenId].nftTokenId = _nftTokenId;
        extraBoosts[_nftAddress][_nftTokenId].nftName = _nftName;
        extraBoosts[_nftAddress][_nftTokenId].nftCategory = _nftCategory;
        extraBoosts[_nftAddress][_nftTokenId].subBoostPercent = _subBoostPercent;
        extraBoosts[_nftAddress][_nftTokenId].setItemCategory = _setItemCategory;
        extraBoosts[_nftAddress][_nftTokenId].setItemBonus = _setItemBonus;


        setItemCategoryBonus[_setItemCategory] = _setItemBonus;

        // update set item category count
        if (numSetCategory <= _setItemCategory) {
            numSetCategory = _setItemCategory + 1;
        }

        // add nftContractAddress array
        bool found = false;
        for (uint i=0; i<nftContractAddressList.length; i++) {
            if (_nftAddress == nftContractAddressList[i]) {
                found = true;
                break;
            }
        }
        if (found == false) {
            nftContractAddressList.push(_nftAddress);
        }
        uint256[] storage _nftTokenIdList = nftTokenIdList[_nftAddress];
        found = false;
        for (uint i=0; i<_nftTokenIdList.length; i++) {
            if (_nftTokenId == _nftTokenIdList[i]) {
                found = true;
                break;
            }
        }
        if (found == false) {
            _nftTokenIdList.push(_nftTokenId);
        }
    }

    /*
     * @notice View function to get users.
     * @param _offset: offset for paging
     * @param _limit: limit for paging
     * @return get users, next offset and total users
     */
    function getUsersPaging(uint256 _offset, uint256 _limit)
        public
        view
        returns (
            UserInfo[] memory users,
            uint256 nextOffset,
            uint256 total
        )
    {
        total = userList.length;
        if (_limit == 0) {
            _limit = 1;
        }

        if (_limit > total.sub(_offset)) {
            _limit = total.sub(_offset);
        }
        nextOffset = _offset.add(_limit);

        users = new UserInfo[](_limit);
        for (uint256 i = 0; i < _limit; i++) {
            users[i] = userInfo[userList[_offset.add(i)]];
        }
    }

    function getUserEtmAmount(address account) public view returns (uint256) {
        UserInfo memory user = userInfo[account];
        uint256 boost = getUserTotalBonus(account);
        return user.amount.add(user.amount.mul(boost).div(10000));
    }

    function getUserTotalBonus(address account) public view returns (uint256 boost) {
        if (nftBoostContractAddress == address(0)) {
            UserInfo memory user = userInfo[account];
            boost = getExtraBoost(user.nftAddress, user.nftTokenId);
            if (boost == 0) {
                return 0;
            }
            uint setCategory = extraBoosts[user.nftAddress][user.nftTokenId].setItemCategory;
            uint[] memory setCategories = new uint[](numSetCategory);
            setCategories[setCategory] += 1;

            for (uint i=0; i<user.nftItems.length; i++) {
                boost = boost.add(
                    extraBoosts[user.nftItems[i].nftAddress][user.nftItems[i].nftTokenId].subBoostPercent
                );
                setCategories[extraBoosts[user.nftItems[i].nftAddress][user.nftItems[i].nftTokenId].setItemCategory] += 1;
            }
            for (uint i=0; i<setCategories.length; i++) {
                if (setCategories[i] > 1) {
                    boost = boost.add(setItemCategoryBonus[i]);
                }
            }
        } else {
            boost = INftBoost(nftBoostContractAddress).getUserTotalBonus(account);
        }
    }

    /**
     * @notice Return Extra Boost .
     * @param _nftAddress: NFT Contract Address
     * @param _nftTokenId: NFT Token ID
     */
    function getExtraBoost(address _nftAddress, uint256 _nftTokenId) public view returns (uint256) {
        return extraBoosts[_nftAddress][_nftTokenId].boostPercent;
    }

    function getExtraBoostList() public view 
        returns (
            BoostInfo[] memory _boostInfoList
        )
    {
        uint _length = 0;    
        for (uint i=0; i<nftContractAddressList.length; i++) {
            _length += nftTokenIdList[nftContractAddressList[i]].length;
        }

        _boostInfoList = new BoostInfo[](_length);

        uint _index = 0;
        for (uint i=0; i<nftContractAddressList.length; i++) {
            uint256[] memory _tokenIdList = nftTokenIdList[nftContractAddressList[i]];
            for (uint j=0; j<_tokenIdList.length; j++) {
                _boostInfoList[_index] = extraBoosts[nftContractAddressList[i]][_tokenIdList[j]];
                _index++;
            }
        }
    }
    
    function onERC1155Received(
        address, /*operator*/
        address, /*from*/
        uint256, /*id*/
        uint256, /*value*/
        bytes calldata /*data*/
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address, /*operator*/
        address, /*from*/
        uint256[] calldata, /*ids*/
        uint256[] calldata, /*values*/
        bytes calldata /*data*/
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 /*interfaceId*/
    ) public view virtual override returns (bool) {
        return false;
    }

}

interface INexfi15 {
    enum NftStakeProperty {
        NO_STAKED, // No nft staked yet
        ERC721_STAKED, // ERC721 staked
        ERC1155_STAKED // ERC1155 staked
    }

    struct NftInfo {
        address nftAddress;
        uint256 nftTokenId;
        bool isERC721;
    }

    struct UserInfo {
        uint256 amount; // How many staked tokens the user has provided
        uint256 rewardDebt; // Reward debt.
        bool registered; // it will add user in address list on first deposit
        address addr; //address of user
        uint256 rewardLocked; // Reward locked up.
        uint256 lastHarvestedAt; // Last harvested time
        uint256 lastDepositedAt; // Last withdrawn time
        NftStakeProperty nftStakeStatus; // Nft staking will lead apr increase
        address nftAddress;
        uint256 nftTokenId;
        uint256 rewardReceived; // total received reward
        NftInfo[] nftItems;
    }

    function pendingReward(address _account) external view returns (uint256 rewardAmount);

    function getUsersPaging(uint256 _offset, uint256 _limit) external view
        returns (
            UserInfo[] memory users,
            uint256 nextOffset,
            uint256 total
        );

}

interface INftBoost {
    function getUserTotalBonus(address account) external view returns (uint256);
}