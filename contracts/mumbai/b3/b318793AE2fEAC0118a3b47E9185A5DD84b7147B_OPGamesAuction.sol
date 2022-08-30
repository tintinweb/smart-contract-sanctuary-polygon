// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT

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
        return _verifyCallResult(success, returndata, errorMessage);
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
import "../proxy/utils/Initializable.sol";

/*
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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./interfaces/IAddressRegistry.sol";
import "./interfaces/ITokenRegistry.sol";

contract OPGamesAuction is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  event AuctionCreated(address indexed nftAddress, uint256 indexed tokenId, address payToken);
  event BidPlaced(address indexed nftAddress, uint256 indexed tokenId, address indexed bidder, uint256 bid);
  event BidWithdrawn(address indexed nftAddress, uint256 indexed tokenId, address indexed bidder, uint256 bid);
  event BidRefunded(address indexed nftAddress, uint256 indexed tokenId, address indexed bidder, uint256 bid);
  event AuctionResulted(
    address oldOwner,
    address indexed nftAddress,
    uint256 indexed tokenId,
    address indexed winner,
    address payToken,
    uint256 winningBid
  );
  event AuctionCancelled(address indexed nftAddress, uint256 indexed tokenId);

  /// @notice Parameters of an auction
  struct Auction {
    address owner;
    address payToken;
    uint256 minBid;
    uint256 reservePrice;
    uint256 startTime;
    uint256 endTime;
    bool resulted;
  }

  /// @notice Information about the sender that placed a bit on an auction
  struct HighestBid {
    address bidder;
    uint256 bid;
    uint256 lastBidTime;
  }

  /// @notice ERC721 Address -> Token ID -> Auction Parameters
  mapping(address => mapping(uint256 => Auction)) public auctions;

  /// @notice ERC721 Address -> Token ID -> highest bidder info (if a bid has been received)
  mapping(address => mapping(uint256 => HighestBid)) public highestBids;

  /// @notice globally and across all auctions, the amount by which a bid has to increase
  uint256 public minBidIncrement = 1;

  /// @notice Platform fee recipient
  address payable public feeRecipient;

  /// @notice Platform fee
  uint256 public platformFee;

  /// @notice AddressRegistry
  IAddressRegistry public addressRegistry;

  receive() external payable {}

  function initialize(
    address _addressRegistry,
    address payable _feeRecipient,
    uint256 _platformFee
  ) external initializer {
    __Ownable_init();
    __ReentrancyGuard_init();
    __Pausable_init();

    require(_addressRegistry != address(0), "unexpected address registry");
    require(_feeRecipient != address(0), "unexpected fee recipient");
    require(_platformFee < 100_0, "platform fee exceeded");

    addressRegistry = IAddressRegistry(_addressRegistry);
    feeRecipient = _feeRecipient;
    platformFee = _platformFee;
  }

  /**
   * @notice Creates a new auction for a given item
   * @dev Only the owner of item can create an auction and must have approved the contract
   * @dev In addition to owning the item, the sender also has to have the MINTER role.
   * @dev End time for the auction must be in the future.
   * @param _nftAddress ERC 721 Address
   * @param _tokenId Token ID of the item being auctioned
   * @param _payToken Paying token
   * @param _reservePrice Item cannot be sold for less than this or minBidIncrement, whichever is higher
   * @param _startTimestamp Unix epoch in seconds for the auction start time
   * @param _minBidReserve Whether the reserve price should be applied or not
   * @param _endTimestamp Unix epoch in seconds for the auction end time.
   */
  function createAuction(
    address _nftAddress,
    uint256 _tokenId,
    address _payToken,
    uint256 _reservePrice,
    uint256 _startTimestamp,
    bool _minBidReserve,
    uint256 _endTimestamp
  ) external whenNotPaused {
    // Ensure this contract is approved to move the token
    require(
      IERC721Upgradeable(_nftAddress).ownerOf(_tokenId) == msg.sender &&
        IERC721Upgradeable(_nftAddress).isApprovedForAll(msg.sender, address(this)),
      "not owner and or contract not approved"
    );

    _validCollection(_nftAddress);
    _validPayToken(_payToken);

    _createAuction(_nftAddress, _tokenId, _payToken, _reservePrice, _startTimestamp, _minBidReserve, _endTimestamp);
  }

  /**
   * @notice Places a new bid, out bidding the existing bidder if found and criteria is reached
   * @dev Only callable when the auction is open
   * @dev Bids from smart contracts are prohibited to prevent griefing with always reverting receiver
   * @param _nftAddress ERC 721 Address
   * @param _tokenId Token ID of the item being auctioned
   * @param _bidAmount Bid amount
   */
  function placeBid(
    address _nftAddress,
    uint256 _tokenId,
    uint256 _bidAmount
  ) external payable nonReentrant whenNotPaused {
    require(msg.sender == tx.origin, "no contracts permitted");

    // Check the auction to see if this is a valid bid
    Auction memory auction = auctions[_nftAddress][_tokenId];

    // Ensure auction is in flight
    require(_getNow() >= auction.startTime && _getNow() <= auction.endTime, "bidding outside of the auction window");

    _placeBid(_nftAddress, _tokenId, _bidAmount);
  }

  function _placeBid(
    address _nftAddress,
    uint256 _tokenId,
    uint256 _bidAmount
  ) internal whenNotPaused {
    Auction storage auction = auctions[_nftAddress][_tokenId];

    if (auction.minBid == auction.reservePrice) {
      require(_bidAmount >= auction.reservePrice, "bid cannot be lower than reserve price");
    }

    // Ensure bid adheres to outbid increment and threshold
    HighestBid storage highestBid = highestBids[_nftAddress][_tokenId];
    uint256 minBidRequired = highestBid.bid + minBidIncrement;

    require(_bidAmount >= minBidRequired, "failed to outbid highest bidder");
    _tokenTransferFrom(msg.sender, address(this), auction.payToken, _bidAmount);

    // Refund existing top bidder if found
    if (highestBid.bidder != address(0)) {
      _refundHighestBidder(_nftAddress, _tokenId, highestBid.bidder, highestBid.bid);
    }

    // assign top bidder and bid time
    highestBid.bidder = msg.sender;
    highestBid.bid = _bidAmount;
    highestBid.lastBidTime = _getNow();

    emit BidPlaced(_nftAddress, _tokenId, msg.sender, _bidAmount);
  }

  /**
   * @notice Allows the hightest bidder to withdraw the bid (after 12 hours post auction's end)
   * @dev Only callable by the existing top bidder
   * @param _nftAddress ERC 721 Address
   * @param _tokenId Token ID of the item being auctioned
   */
  function withdrawBid(address _nftAddress, uint256 _tokenId) external nonReentrant {
    HighestBid storage highestBid = highestBids[_nftAddress][_tokenId];

    // Ensure highest bidder is the caller
    require(highestBid.bidder == msg.sender, "you are not the highest bidder");

    uint256 _endTime = auctions[_nftAddress][_tokenId].endTime;

    require(
      _getNow() > _endTime && (_getNow() - _endTime >= 43200),
      "can withdraw only after 12 hours (after auction ended)"
    );

    uint256 previousBid = highestBid.bid;

    // Clean up the existing top bid
    delete highestBids[_nftAddress][_tokenId];

    // Refund the top bidder
    _refundHighestBidder(_nftAddress, _tokenId, msg.sender, previousBid);

    emit BidWithdrawn(_nftAddress, _tokenId, msg.sender, previousBid);
  }

  /**
   * @notice Closes a finished auction and rewards the highest bidder
   * @dev Only admin or smart contract
   * @dev Auction can only be resulted if there has been a bidder and reserve met.
   * @dev If there have been no bids, the auction needs to be cancelled instead using `cancelAuction()`
   * @param _nftAddress ERC 721 Address
   * @param _tokenId Token ID of the item being auctioned
   */
  function resultAuction(address _nftAddress, uint256 _tokenId) external nonReentrant whenNotPaused {
    // Check the auction to see if it can be resulted
    Auction storage auction = auctions[_nftAddress][_tokenId];

    require(
      IERC721Upgradeable(_nftAddress).ownerOf(_tokenId) == msg.sender && msg.sender == auction.owner,
      "sender must be item owner"
    );

    // Check the auction real
    require(auction.endTime > 0, "no auction exists");

    // Check the auction has ended
    require(_getNow() > auction.endTime, "auction not ended");

    // Ensure auction not already resulted
    require(!auction.resulted, "auction already resulted");

    // Get info on who the highest bidder is
    HighestBid storage highestBid = highestBids[_nftAddress][_tokenId];
    address winner = highestBid.bidder;
    uint256 winningBid = highestBid.bid;

    // Ensure there is a winner
    require(winner != address(0), "no open bids");
    require(winningBid >= auction.reservePrice, "highest bid is below reservePrice");

    // Ensure this contract is approved to move the token
    require(IERC721Upgradeable(_nftAddress).isApprovedForAll(msg.sender, address(this)), "auction not approved");

    // Result the auction
    auction.resulted = true;

    // Clean up the highest bid
    delete highestBids[_nftAddress][_tokenId];

    uint256 feeAmount = (winningBid * platformFee) / 100_0;

    IERC20Upgradeable payToken = IERC20Upgradeable(auction.payToken);
    payToken.safeTransfer(feeRecipient, feeAmount);
    payToken.safeTransfer(auction.owner, winningBid - feeAmount);

    // Transfer the token to the winner
    IERC721Upgradeable(_nftAddress).safeTransferFrom(
      IERC721Upgradeable(_nftAddress).ownerOf(_tokenId),
      winner,
      _tokenId
    );

    // Remove auction
    delete auctions[_nftAddress][_tokenId];

    emit AuctionResulted(msg.sender, _nftAddress, _tokenId, winner, auction.payToken, winningBid);
  }

  /**
   * @notice Private method doing the heavy lifting of creating an auction
   * @param _nftAddress ERC 721 Address
   * @param _tokenId Token ID of the NFT being auctioned
   * @param _payToken Paying token
   * @param _reservePrice Item cannot be sold for less than this or minBidIncrement, whichever is higher
   * @param _startTimestamp Unix epoch in seconds for the auction start time
   * @param _endTimestamp Unix epoch in seconds for the auction end time.
   */
  function _createAuction(
    address _nftAddress,
    uint256 _tokenId,
    address _payToken,
    uint256 _reservePrice,
    uint256 _startTimestamp,
    bool minBidReserve,
    uint256 _endTimestamp
  ) private {
    // Ensure a token cannot be re-listed if previously successfully sold
    require(auctions[_nftAddress][_tokenId].endTime == 0, "auction already started");

    // Check end time not before start time and that end is in the future
    require(_endTimestamp >= _startTimestamp + 300, "end time must be greater than start (by 5 minutes)");

    require(_startTimestamp > _getNow(), "invalid start time");

    uint256 minimumBid = 0;

    if (minBidReserve) {
      minimumBid = _reservePrice;
    }

    // Setup the auction
    auctions[_nftAddress][_tokenId] = Auction({
      owner: msg.sender,
      payToken: _payToken,
      minBid: minimumBid,
      reservePrice: _reservePrice,
      startTime: _startTimestamp,
      endTime: _endTimestamp,
      resulted: false
    });

    emit AuctionCreated(_nftAddress, _tokenId, _payToken);
  }

  /**
   * @notice Cancels and inflight and un-resulted auctions, returning the funds to the top bidder if found
   * @dev Only item owner
   * @param _nftAddress ERC 721 Address
   * @param _tokenId Token ID of the NFT being auctioned
   */
  function cancelAuction(address _nftAddress, uint256 _tokenId) external nonReentrant {
    // Check valid and not resulted
    Auction memory auction = auctions[_nftAddress][_tokenId];

    require(
      IERC721Upgradeable(_nftAddress).ownerOf(_tokenId) == msg.sender && msg.sender == auction.owner,
      "sender must be owner"
    );

    // Check auction is real
    require(auction.endTime > 0, "no auction exists");

    // Check auction not already resulted
    require(!auction.resulted, "auction already resulted");

    _cancelAuction(_nftAddress, _tokenId);
  }

  function _cancelAuction(address _nftAddress, uint256 _tokenId) private {
    // refund existing top bidder if found
    HighestBid storage highestBid = highestBids[_nftAddress][_tokenId];
    if (highestBid.bidder != address(0)) {
      _refundHighestBidder(_nftAddress, _tokenId, highestBid.bidder, highestBid.bid);

      // Clear up highest bid
      delete highestBids[_nftAddress][_tokenId];
    }

    // Remove auction and top bidder
    delete auctions[_nftAddress][_tokenId];

    emit AuctionCancelled(_nftAddress, _tokenId);
  }

  /**
   * @notice Used for sending back escrowed funds from a previous bid
   * @param _currentHighestBidder Address of the last highest bidder
   * @param _currentHighestBid Ether or Mona amount in WEI that the bidder sent when placing their bid
   */
  function _refundHighestBidder(
    address _nftAddress,
    uint256 _tokenId,
    address _currentHighestBidder,
    uint256 _currentHighestBid
  ) private {
    Auction memory auction = auctions[_nftAddress][_tokenId];

    _tokenTransferFrom(address(this), _currentHighestBidder, auction.payToken, _currentHighestBid);

    emit BidRefunded(_nftAddress, _tokenId, _currentHighestBidder, _currentHighestBid);
  }

  /**
   * @notice Validate the payment token
   * @dev Zero address means the native token
   * @param _payToken Payment token address
   */
  function _validPayToken(address _payToken) internal view {
    require(
      _payToken == address(0) ||
        (addressRegistry.tokenRegistry() != address(0) &&
          ITokenRegistry(addressRegistry.tokenRegistry()).enabledPayToken(_payToken)),
      "invalid pay token"
    );
  }

  /**
   * @notice Validate the collection
   * @param _nftAddress Collection address
   */
  function _validCollection(address _nftAddress) internal view {
    require(
      (addressRegistry.tokenRegistry() != address(0) &&
        ITokenRegistry(addressRegistry.tokenRegistry()).enabledCollection(_nftAddress)),
      "invalid collection"
    );
  }

  /**
   * @notice Transfer tokens
   * @dev If the _payToken address is zero, it means the native token
   * @param _from Sender address
   * @param _to Receiver address
   * @param _payToken Payment token address
   * @param _amount Payment token amount
   */
  function _tokenTransferFrom(
    address _from,
    address _to,
    address _payToken,
    uint256 _amount
  ) private {
    if (_payToken == address(0)) {
      require(_from == address(this), "invalid Ether sender");

      (bool sent, ) = payable(_to).call{value: _amount}("");
      require(sent, "failed to send Ether");
    } else {
      IERC20Upgradeable(_payToken).safeTransferFrom(_from, _to, _amount);
    }
  }

  function _getNow() internal view virtual returns (uint256) {
    return block.timestamp;
  }

  /**
   * @notice Pause Auction
   * @dev Only owner
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * @notice Resume Auction
   * @dev Only owner
   */
  function unpause() external onlyOwner {
    _unpause();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IAddressRegistry {
  function tokenRegistry() external view returns (address);

  function marketplace() external view returns (address);

  function auction() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface ITokenRegistry {
  function enabledCollection(address _nftAddress) external view returns (bool);

  function enabledPayToken(address _token) external view returns (bool);
}