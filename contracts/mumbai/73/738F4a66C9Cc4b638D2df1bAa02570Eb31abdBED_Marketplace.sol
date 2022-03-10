/**
 *Submitted for verification at polygonscan.com on 2022-03-09
*/

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// File: marketplace.sol


pragma solidity ^0.8.0;






// only for debugging
// import "hardhat/console.sol";

/**
 * @title Marketplace contract for the NFT
 * @author Kartik Jain
 * @notice User can trade, swap and start the auction for NFT
 * @dev Auction is not yet done
 */
interface IMarketplace {

    enum SaleType { Trade, Swap, Auction }

    struct Sell {
        uint256 listId;          // ID for the marketplace listing
        uint256 tokenId;         // ID for the ERC721 token
        address tokenContract;   // Address for the ERC721 contract
        uint256 price;           // The price of the token
        address tokenOwner;      // The address that put the NFT on marketplace. It also receives the funds once the NFT is sold.
        bool usdt;               // The bool value to check the currency matic/usdt
    }

    struct Swap {
        uint256 listId;          // ID for the marketplace listing
        address owner;           // The address that put the NFT on marketplace. It also receives the funds and NFT after swap.
        address whitelist;       // address to be swapped from a certain user
        address tokenContract;   // Address for the ERC721 contract
        uint256 tokenId;         // ID for the ERC721 token
        uint expires;            // time limit for the swap
        string description;      // description of the NFT
    }

    struct Offers {
        uint256 swapId;           // ID of the swap for which the offer is made.
        address owner;            // The address that gives the offer
        address tokenContract;    // Address for the ERC721 contract
        uint256 tokenId;          // ID for the ERC721 token
        int exchangeValue;        // The amount user is willng to pay for swap
        bool usdt;                // The bool value to check the currency matic/usdt
    }

    struct CounterOffer {
        uint256 offerId;          // ID of the offer for which counter offer is made
        uint256 newAmount;        // The new Amount that user wants to swap the NFT
        address tokenContract;    // Address for the ERC721 contract
        uint256 tokenId;          // ID for the ERC721 token
        bool usdt;                // The bool value to check the currency matic/usdt
    }

    struct ListedToken {
        uint256 saleId;         // ID of the swap or trade
        SaleType saleType;      // enum to define if it is trade or swap
    }

    event saleCreated(uint256 indexed saleId, uint256 indexed listId, uint256 amount, bool currency);

    event listCreated(uint256 indexed listId, SaleType _type);

    event Claim(address indexed recepient, uint256 maticAmount, uint256 usdtAmount);

    event CancelTrade(uint256 indexed orderId);

    event SwapCreated(uint256 indexed swapId, uint256 tokenId, address tokenContract, uint256 time);

    event Unlist(uint256 indexed listId);

    event OfferMade(uint256 indexed offerId, uint256 indexed swapId, uint256 tokenId, address tokenContract, int exchangeValue, bool usdt);

    event BuyOrder(uint256 indexed orderId, uint256 price, address indexed buyer);

    event Swapped(uint256 swapId, address originalContract, uint256 originalId, uint256 offerId, address swapContract, uint256 swapTokenId);

    event CounterOffered(uint256 indexed offerId, address tokenContract, uint256 tokenId, uint exchangeValue);
}

contract Marketplace is ReentrancyGuard, IMarketplace, Ownable {

    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    /// @notice stores the claimable account of the address
    struct BalanceInfo {
        uint256 matic;
        uint256 usdt;
    }

    // The minimum percentage difference between the last bid amount and the current bid.
    // uint8 public minBidIncrement;

    /// @notice Owner's fees percentage
    uint8 public curatorFeePercentage;

    /// mapping to store the claimable balance address => BalanceInfo(struct)
    mapping(address => BalanceInfo) public balance;

    /// @notice stores all the ID's of the NFT which are listed on the marketplace
    uint256[] public listedTokens;
    mapping(uint256 => uint256) private listedTokensIndex; // stores the index of listedTokens ID's

    /// @notice stores all the ID's of the NFT which are listed on the marketplace for trading only
    uint256[] public tradeTokens;
    mapping(uint256 => uint256) private tradeTokensIndex;

    /// @notice stores all the ID's of the NFT which are listed on the marketplace for swapping only
    uint256[] public swapTokens;
    mapping(uint256 => uint256) private swapTokensIndex;

    /// @notice stores all the ID's of the offer mapping(swappingId => offers[])
    mapping(uint => uint256[]) public offers;
    // mapping(uint => uint) private offerIndex;

    /// @notice mapping for the counterOffers made to the user's offer mapping(offerId => counterOfferId)
    mapping(uint=>uint) public counterOffers;

    /// @notice mapping if the user offer is accepted by the swap owner mapping(offer => bool)
    mapping(uint=>bool) public offerAccepted;

    /// A mapping of all of the order currently running.
    mapping(uint256 => ListedToken) public list;
    mapping(uint256 => Sell) public sellOrder;
    mapping(uint256 => Swap) public swapOrder;
    mapping(uint256 => Offers) public offer;
    mapping(uint256 => CounterOffer) public counterOffer;

    bytes4 private constant INTERFACE_ID = 0x80ac58cd; // 721 interface id

    /// @dev keeps tracks of Id's
    Counters.Counter private _listOrderTracker;
    Counters.Counter private _saleOrderTracker;
    Counters.Counter private _swapOrderTracker;

    /// @notice address of the treasurer where fees will be stored after trading NFT
    address public curator;

    /// @notice USDT address on polygon mainnet
    address public constant USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;

    /**
     * @notice Require that the specified ID exists
     */
    modifier tradeExists(uint256 tradeId) {
        require(_exists(tradeId, 0), "Trade doesn't exist");
        _;
    }

    /**
     * @notice Require that the specified ID exists
     */
    modifier swapExist(uint256 swapId) {
        require(_exists(swapId, 1), "Swap doesn't exist");
        _;
    }

    /**
    * @param _curator address of the treasurer
    * @param _curatorFee percentage of price that will goes to curator
    */
    constructor(address _curator, uint8 _curatorFee) {
        require(_curator != address(0), "Invalid address");

        // TODO: Will be added during auction
        // minBidIncrement = _minBidIncrementPercentage;

        curator = _curator;
        curatorFeePercentage = _curatorFee;
    }

    /// Fallback functions to accept matic
    receive() external payable {}
    fallback() external payable {}

    // function updateMinBid(uint8 _value) public onlyOwner {
    //     minBidIncrement = _value;
    // }

    /// @notice updates the address of curator
    /// @dev onlyOwner function
    function updateCurator(address _curator) public onlyOwner {
        require(_curator != address(0), "Invalid address");
        curator = _curator;
    }

    /// @notice updates curator fees
    function updateCuratorFee(uint8 _value) public onlyOwner {
        require(_value > 0, "Fee can't be 0");
        curatorFeePercentage = _value;
    }

    /**
     * @notice Create a Sale order.
     * @param tokenId Id of the NFT that user wants to trade
     * @param tokenContract address of the contract of the NFT
     * @param price price of the NFT for which user wants to sell
     * @param usdt true if the user wants payment in usdt else matic
     *
     * @return orderId Id of the order created
     * @return listId Id of the list created on the marketplace
     */
    function saleOrder(
        uint256 tokenId,
        address tokenContract,
        uint256 price,
        bool usdt
    ) public nonReentrant returns (uint256 orderId, uint256 listId) {

        require(tokenContract != address(0), "Zero Address");
        require(tokenId >= 0, "Invalid Id");
        require(price > 0, "Invalid Price");
        require(
            IERC165(tokenContract).supportsInterface(INTERFACE_ID),
            "ERC721 interface not supported"
        );
        address tokenOwner = IERC721(tokenContract).ownerOf(tokenId);
        require(msg.sender == tokenOwner, "Not owner");
        _saleOrderTracker.increment();
        orderId = _saleOrderTracker.current();

        listId = _listing(orderId, SaleType.Trade);

        sellOrder[orderId] = Sell({
            listId: listId,
            tokenId: tokenId,
            tokenContract: tokenContract,
            price: price,
            tokenOwner: tokenOwner,
            usdt: usdt
        });

        tradeTokens.push(orderId);
        tradeTokensIndex[orderId] = tradeTokens.length;

        IERC721(tokenContract).transferFrom(tokenOwner, address(this), tokenId);

        emit saleCreated(orderId, listId, price, usdt);
    }

    /**
    * @notice list nft in the marketplace
    * @param orderId Id for swap, trade or auction
    * @param _type type of the order if it is swap, trade or auction
    *
    * @return listId Id of the listed NFT
    *
    * @dev internal function, will be called when user put NFT for trade and swap,
    * used to list NFT on marketplace
    */
    function _listing(uint256 orderId, 
                      SaleType _type
                    ) internal returns(uint256) 
        {

        _listOrderTracker.increment();
        uint256 listId = _listOrderTracker.current();
        list[listId] = ListedToken ({
            saleId: orderId,
            saleType: _type
        });

        listedTokens.push(listId);
        listedTokensIndex[listId] = listedTokens.length;

        emit listCreated(listId, _type);

        return listId;
    }

    /**
    * @notice unlist the nft in the marketplace
    *
    * @param listId Id of the listed NFT
    *
    * @return bool true if NFT got unlisted from marketplace
    *
    * @dev internal function, will be called when user cancel trade or swap,
    * used to unlist NFT on marketplace
    */
    function _unlisting(uint listId) internal returns(bool) {

        uint listIndex = listedTokensIndex[listId];
        uint lastIndex = listedTokens.length - 1;

        if (listIndex > 0) {
            listedTokens[listIndex - 1] = listedTokens[lastIndex];
            listedTokensIndex[listedTokens[lastIndex]] = listIndex;
            listedTokensIndex[listId] = 0;
            listedTokens.pop();

            delete list[listId];
        }

        emit Unlist(listId);
        return true;
    }

    /**
    * @notice cancels the trade and send NFT back to the owner
    * @param orderId Id of the trade that the owner wants to cancel
    *
    * @custom:note orderId is different from listId
    */
    function cancelSell(uint256 orderId) public tradeExists(orderId) {
        Sell storage sell = sellOrder[orderId];
        address owner = sell.tokenOwner;
        require(msg.sender == owner, "Invalid sender");

        // unlisting nft from marketplace
        _unlisting(sell.listId);

        // transferring nft back to token Owner
        IERC721(sell.tokenContract).transferFrom(address(this), owner, sell.tokenId);

        uint listIndex = tradeTokensIndex[orderId];
        uint lastIndex = tradeTokens.length - 1;

        if (listIndex > 0) {
            tradeTokens[listIndex - 1] = tradeTokens[lastIndex];
            tradeTokensIndex[tradeTokens[lastIndex]] = listIndex;
            tradeTokensIndex[orderId] = 0;
            tradeTokens.pop();

            delete sellOrder[orderId];
        }

        emit CancelTrade(orderId);
    }

    /**
    * @notice cancels the swap and send NFT back to the owner
    * @param swapId Id of the swap that the owner wants to cancel
    *
    * @custom:note swapId is different from listId
    */
    function cancelSwap(uint256 swapId) public {

        Swap storage sp = swapOrder[swapId];
        require(msg.sender == sp.owner, "Invalid sender");

        // unlisting nft from marketplace
        _unlisting(swapOrder[swapId].listId);

        uint listIndex = swapTokensIndex[swapId];
        uint lastIndex = swapTokens.length - 1;

        if (listIndex > 0) {
            swapTokens[listIndex - 1] = swapTokens[lastIndex];
            swapTokensIndex[swapTokens[lastIndex]] = listIndex;
            swapTokensIndex[swapId] = 0;
            swapTokens.pop();

            // transferring nft back to token Owner
            IERC721(sp.tokenContract).transferFrom(address(this), msg.sender, sp.tokenId);

            delete swapOrder[swapId];
        }

        emit CancelTrade(swapId);
    }

    /**
    * @notice Nft owner can initialize their swap by swapToken,
    * their Nft will be transferred to this contract and will
    * be available for other users to swap
    *
    * @param tokenId Id of the Nft that owner wants to swap
    * @param tokenContract contract address of the nft
    * @param whitelist if the owners wants to swap tokens only from a certain address
    * @param time user wont be able to swap tokens after certain time, and user will have to cancel swap 
    * @param description description of the nft
    *
    * @return swapId swap Id created for swapping
    * @return listId list Id created for listing on marketplace
    *
    * @dev owner needs to approve the nft to this contract before swapping
    */
    function swapToken(uint256 tokenId,
                       address tokenContract,
                       address whitelist,
                       uint time,
                       string memory description
                       ) public returns(uint256 swapId, uint256 listId) {

        require(tokenContract != address(0), "Zero Address");
        require(tokenId >= 0, "Invalid Id");
        require(time >= 60, "Minimum 1 Minute");
        require(
            IERC165(tokenContract).supportsInterface(INTERFACE_ID),
            "ERC721 interface not supported"
        );
        address tokenOwner = IERC721(tokenContract).ownerOf(tokenId);
        require(msg.sender == tokenOwner, "Not owner");

        _swapOrderTracker.increment();
        swapId = _swapOrderTracker.current();

        // list nft on the marketplace
        listId = _listing(swapId, SaleType.Swap);

        swapOrder[swapId] = Swap({
            listId: listId,
            owner:tokenOwner,
            whitelist: whitelist,
            tokenContract: tokenContract,
            tokenId: tokenId,
            expires: block.timestamp + time,
            description: description
        });

        swapTokens.push(swapId);
        swapTokensIndex[swapId] = swapTokens.length;

        // transfer the nft to this contract
        IERC721(tokenContract).transferFrom(tokenOwner, address(this), tokenId);

        emit SwapCreated(swapId, tokenId, tokenContract, time);
    }

    /**
    * @notice user can make different offers for the swap
    * @param swapId swapId for the token for against which user makes the offer
    * @param tokenContract contract address against which user wants to swap
    * @param tokenId Id of the nft for the swapping
    * @param exchangeValue amount of usdt/matic user is willing to pay along 
    *                      with the nft for swap, incase swapping to a rare nft
    * @param usdt true if the amount is in usdt else matic
    *
    * @custom:note user can make 1 offer for one swap,
    * if the user make another offer it will be overwrtitten
    */
    function makeOffer(uint256 swapId,
                       address tokenContract,
                       uint256 tokenId,
                       int exchangeValue,
                       bool usdt) public swapExist(swapId) returns(uint256 offerId) {

        address tokenOwner = IERC721(tokenContract).ownerOf(tokenId);
        require(msg.sender == tokenOwner, "Not owner");
        require(swapOrder[swapId].whitelist == address(0) ||
                swapOrder[swapId].whitelist == msg.sender, "Not Whitelisted");
        require(swapOrder[swapId].expires > block.timestamp, "Swap Expired");

        // A user can't make two different for the same swapId
        offerId = uint256(keccak256(abi.encodePacked(msg.sender, swapId)));

        offer[offerId] = Offers({
            swapId: swapId,
            owner:tokenOwner,
            tokenContract: tokenContract,
            tokenId: tokenId,
            exchangeValue: exchangeValue,
            usdt: usdt
        });

        offers[swapId].push(offerId);

        emit OfferMade(offerId, swapId, tokenId, tokenContract, exchangeValue, usdt);
    }

    /**
    * @notice the owner can make a counter offer to the offer that a user has made
    * @param offerId offer Id against which counter offer is to be made
    * @param tokenContract contract of the nft that the owner wants
    * @param tokenId Id of the nft that the owner wants
    * @param exchangeValue some extra amount of usdt/matic that the owner wants
    * @param usdt if the amount is in usdt or matic
    *
    * @return counterOfferId counter offer Id
    */
    function makeCounterOffer(uint256 offerId,
                              address tokenContract,
                              uint256 tokenId,
                              uint exchangeValue,
                              bool usdt) public returns(uint256 counterOfferId) 
    {

        uint256 swapId = offer[offerId].swapId;
        require(msg.sender == swapOrder[swapId].owner, "Not owner");
        require(swapOrder[swapId].expires > block.timestamp, "Swap Expired");

        counterOfferId = uint256(keccak256(abi.encodePacked(msg.sender, offerId)));

        counterOffer[counterOfferId] = CounterOffer({
            offerId: offerId,
            newAmount: exchangeValue,
            tokenContract: tokenContract,
            tokenId: tokenId,
            usdt: usdt 
        });

        counterOffers[offerId] = counterOfferId;

        emit CounterOffered(offerId, tokenContract, tokenId, exchangeValue);
    }

    /**
    * @notice swap owner can accept the offer from which they can swap their nft
    * @custom:note a user can't swap the tokens unless the offer is accepted
    
    * @param offerId Id of the offer that the owner wants to accept
    *
    * @return bool true if the offer is accepted
    */
    function acceptOffer(uint256 offerId) public returns(bool) {

        uint256 swapId = offer[offerId].swapId;

        require(msg.sender == swapOrder[swapId].owner, "Not Swap Owner");
        require(swapOrder[swapId].expires > block.timestamp, "Swap Expired");

        offerAccepted[offerId] = true;

        return true;
    }

    /**
    * @notice A user can swap the nft once their offer is accepted by the owner
    * @param offerId Id of their offer that the owner has accepted to trade with
    *
    * @dev user needs to approve the nft or usdt to this contract before swapping
    */
    function swap(uint256 offerId) external payable swapExist(offer[offerId].swapId) nonReentrant {

        Offers storage swapOffer = offer[offerId];

        require(swapOffer.tokenContract != address(0), "Invalid NFT");
        address tokenOwner = IERC721(swapOffer.tokenContract).ownerOf(swapOffer.tokenId);

        require(swapOrder[swapOffer.swapId].expires > block.timestamp, "Swap Expired");
        require(swapOrder[swapOffer.swapId].whitelist == address(0) ||
                swapOrder[swapOffer.swapId].whitelist == msg.sender, "Not Whitelisted");
        require(offer[offerId].owner == msg.sender, "Invalid Owner");
        require(tokenOwner == msg.sender, "Not Owner");
        require(offerAccepted[offerId], "Not Accepted");

        Swap storage swapOriginal = swapOrder[swapOffer.swapId];

        if (swapOffer.exchangeValue > 0) {
            // transfers the matic/usdt into this contratc
            _handleIncomingBid(uint256(swapOffer.exchangeValue), swapOffer.usdt);

            // updates the balance of the owner and curator for them to claim later on
            if (swapOffer.usdt) {
                balance[swapOriginal.owner] = BalanceInfo({
                    matic: balance[swapOriginal.owner].matic,
                    usdt: (balance[swapOriginal.owner].usdt + uint256(swapOffer.exchangeValue))
                });
            } else {
                balance[swapOriginal.owner] = BalanceInfo({
                    matic: (balance[swapOriginal.owner].matic + uint256(swapOffer.exchangeValue)),
                    usdt: balance[swapOriginal.owner].usdt
                });
            }
        }

        // transfers the nft from the user to the swap owner
        IERC721(swapOffer.tokenContract).transferFrom(msg.sender, swapOriginal.owner, swapOffer.tokenId);

        // transfers the nft from this contract to the user
        IERC721(swapOriginal.tokenContract).transferFrom(address(this), swapOffer.owner, swapOriginal.tokenId);

        // after swapping unlist the nft from marketplace
        _unlisting(swapOriginal.listId);

        uint listIndex = swapTokensIndex[swapOffer.swapId];
        uint lastIndex = swapTokens.length - 1;

        if (listIndex > 0) {
            swapTokens[listIndex - 1] = swapTokens[lastIndex];
            swapTokensIndex[swapTokens[lastIndex]] = listIndex;
            swapTokensIndex[swapOffer.swapId] = 0;
            swapTokens.pop();

            delete swapOrder[swapOffer.swapId];
        }

        counterOffers[offerId] = 0;

        // deletes the offerId
        delete offers[offerId];

        emit Swapped(swapOffer.swapId, swapOffer.tokenContract, swapOffer.tokenId, offerId, swapOriginal.tokenContract, swapOriginal.tokenId);
    }

    /**
     * @notice buy order that owner has put to trade.
     * @param orderId orderId against which user wants to buy the nft
     *
     * @dev user needs to approve usdt to this contract before trading
     */
    function buyOrder(uint256 orderId) external payable tradeExists(orderId) nonReentrant {
        require(curator != address(0), "Invalid Curator");

        Sell storage sell = sellOrder[orderId];
        uint256 price = sell.price;
        uint256 curatorCut = (price * curatorFeePercentage) / 100;

        // transfers the matic/usdt into this contract
        _handleIncomingBid(price, sell.usdt);
        
        // transfers the nft to the msg.sender
        IERC721(sell.tokenContract).safeTransferFrom(address(this), msg.sender, sell.tokenId);

        // updates the balance of curator and seller to be claimed later
        if (sell.usdt) {
            balance[curator] = BalanceInfo({
                matic: balance[curator].matic,
                usdt: (balance[curator].usdt + curatorCut)
            });

            balance[sell.tokenOwner] = BalanceInfo({
                matic: balance[sell.tokenOwner].matic,
                usdt: (balance[sell.tokenOwner].usdt + (price - curatorCut))
            });
        } else {
            balance[curator] = BalanceInfo({
                matic: (balance[curator].matic + curatorCut),
                usdt: balance[curator].usdt
            });

            balance[sell.tokenOwner] = BalanceInfo({
                matic: (balance[sell.tokenOwner].matic + price - curatorCut),
                usdt: balance[sell.tokenOwner].usdt
            });
        }
        
        // If the buyer sends more amount than the price,
        // the extra amount is transferred back to the buyer
        if (!sell.usdt && (msg.value - price) > 0)
        _handleOutgoingBid(msg.sender, msg.value - price, sell.usdt);

        // unlist the nft from marketplace
        _unlisting(sell.listId);

        uint listIndex = tradeTokensIndex[orderId];
        uint lastIndex = tradeTokens.length - 1;

        if (listIndex > 0) {
            tradeTokens[listIndex - 1] = tradeTokens[lastIndex];
            tradeTokensIndex[tradeTokens[lastIndex]] = listIndex;
            tradeTokensIndex[orderId] = 0;
            tradeTokens.pop();
        }

        delete sellOrder[orderId];

        emit BuyOrder(orderId, price, msg.sender);
    }

    /**
    * @notice owner and curator can claim amount after trading
    */
    function claim() external {

        BalanceInfo storage bal = balance[msg.sender];

        uint256 maticAmount = bal.matic;
        uint256 usdtAmount = bal.usdt;

        if(maticAmount > 0) _handleOutgoingBid(msg.sender, maticAmount, false);
        if(usdtAmount > 0) _handleOutgoingBid(msg.sender, usdtAmount, true);

        bal.matic = 0;
        bal.usdt = 0;

        emit Claim(msg.sender, maticAmount, usdtAmount);
    }

    /// used in the modifier to check if the Id's are valid
    function _exists(uint256 id, uint8 saleType) internal view returns(bool) {
        if(saleType == 0){
            return sellOrder[id].tokenOwner != address(0);
        }
        else if (saleType == 1) {
            return swapOrder[id].owner != address(0);
        }
        return false;
    }

    function listTokens() public view returns(uint[] memory) {
        return listedTokens;
    }

    function tradedTokens() public view returns(uint[] memory) {
       return tradeTokens;
    }

    function swappingTokens() public view returns(uint[] memory) {
        return swapTokens;
    }

    function swapOffers(uint256 swapID) public view returns(uint[] memory) {
        return offers[swapID];
    }

    /**
     * @dev Given an amount and a currency, transfer the currency to this contract.
     */
    function _handleIncomingBid(uint256 amount, bool currency) internal returns(bool) {
        
        require(amount > 0, "Invalid Amount");
        if(!currency) {
            require(msg.value >= amount, "not enough amount");
            return true;
        } else {
            // We must check the balance that was actually transferred to the trade,
            // as some tokens impose a transfer fee and would not actually transfer the
            // full amount to the market, resulting in potentally locked funds
            IERC20 token = IERC20(USDT);
            uint256 beforeBalance = token.balanceOf(address(this));

            token.safeTransferFrom(msg.sender, address(this), amount);

            uint256 afterBalance = token.balanceOf(address(this));
            require((beforeBalance + amount) >= afterBalance, "unexpected amount Transferred");
            return true;
        }
    }

    /// @dev internal function to handle outgoing amount
    function _handleOutgoingBid(address to, uint256 amount, bool currency) internal returns(bool) {
        
        if(!currency) {

            uint256 bal = address(this).balance;
            
            require(bal >= amount, "Insufficient Fund");
            // (bool status, ) = to.call{value: amount}("");
            payable(to).transfer(amount);
            // require(status, "Failed to send Ether");
            return (address(this).balance == bal - amount);
        } else {
            IERC20(USDT).safeTransfer(to, amount);
            return true;
        }
    }
}