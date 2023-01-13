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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import './mock/MultiSign.sol';

contract CrossContract {
    using SafeERC20 for IERC20;

    string private g_Name;
    address private g_Setter; //it should be gnosis addr
    address payable public g_FeeAddr;
    MultiSign private g_MultiSignContract;
    uint256 private g_iNonce = 0;

    constructor(
        string memory _name,
        address payable _addr,
        address _setter,
        address payable _feeaddr
    ) {
        require(bytes(_name).length > 0, 'init must has name');
        require(_addr != address(0), 'init _addr can not be zero');
        require(_setter != address(0), 'init _setter can not be zero');
        require(_feeaddr != address(0), 'init _feeaddr can not be zero');

        if (address(g_MultiSignContract) != address(0)) {
            require(msg.sender == g_Setter, 'init not setter calling');
        }

        g_Name = _name;
        g_MultiSignContract = MultiSign(_addr);
        g_Setter = _setter;
        g_FeeAddr = _feeaddr;
        emit event_init(_name, _addr, _setter, _feeaddr);
    }

    //events
    event event_init(string name, address addr, address setter, address feeaddr);
    event event_nonce(uint256 nonce);
    event event_RangersSpeedUp(
        address fromAsset,
        bytes hash,
        address sender,
        uint256 fee
    );

    event event_CrossErc20(
        uint256 fee,
        address from,
        string to,
        string tochain,
        address sender,
        string toaddr,
        uint256 amount
    );
    event event_CrossErc20_Failed(
        uint256 fee,
        address from,
        string to,
        string tochain,
        address sender,
        string toaddr,
        uint256 amount
    );
    event event_CrossErc721(
        uint256 fee,
        address from,
        string to,
        string tochain,
        address sender,
        string toaddr,
        uint256 nftid
    );
    event event_CrossErc721_Failed(
        uint256 fee,
        address from,
        string to,
        string tochain,
        address sender,
        string toaddr,
        uint256 nftid
    );

    event event_withdrawErc20(
        address from,
        string fromchain,
        string to,
        address user,
        uint256 amount
    );
    event event_withdrawErc20_Failed(
        address from,
        string fromchain,
        string to,
        address user,
        uint256 amount
    );
    event event_withdrawErc721(
        address from,
        string fromchain,
        string to,
        address user,
        uint256 nftid
    );
    event event_withdrawErc721_Failed(
        address from,
        string fromchain,
        string to,
        address user,
        uint256 nftid
    );

    // fallback
    fallback() external payable {
        require(msg.value > 0, 'fallback require msg.value > 0');
        g_FeeAddr.transfer(msg.value);

        bytes memory txHash;
        emit event_RangersSpeedUp(address(0), txHash, msg.sender, msg.value);
    }

    // recieve
    receive() external payable {
        require(msg.value > 0, 'fallback require msg.value > 0');
        g_FeeAddr.transfer(msg.value);

        bytes memory txHash;
        emit event_RangersSpeedUp(address(0), txHash, msg.sender, msg.value);
    }

    function init(
        string memory _name,
        address payable _addr,
        address _setter,
        address payable _feeaddr
    ) public {
        require(bytes(_name).length > 0, 'init must has name');
        require(_addr != address(0), 'init _addr can not be zero');
        require(_setter != address(0), 'init _setter can not be zero');
        require(_feeaddr != address(0), 'init _feeaddr can not be zero');

        if (address(g_MultiSignContract) != address(0)) {
            require(msg.sender == g_Setter, 'init not setter calling');
        }

        g_Name = _name;
        g_MultiSignContract = MultiSign(_addr);
        g_Setter = _setter;
        g_FeeAddr = _feeaddr;
        emit event_init(_name, _addr, _setter, _feeaddr);
    }

    function getnonce() public {
        emit event_nonce(g_iNonce);
    }

    function speedUp(
        address fromAsset,
        bytes calldata txHash,
        uint256 fee
    ) external payable {
        if (fromAsset == address(0)) {
            require(msg.value == fee, 'speedUp insufficient fee num');
            g_FeeAddr.transfer(msg.value);
        } else {
            IERC20(fromAsset).safeTransferFrom(msg.sender, g_FeeAddr, fee);
        }

        emit event_RangersSpeedUp(fromAsset, txHash, msg.sender, fee);
    }

    ///do cross////////////////////////////////////////////////////////////////////////////
    function DoCrossErc20(
        address _fromcontract,
        string calldata _tocontract,
        string calldata _toChain,
        address _fromaddr,
        string calldata _toaddr,
        uint256 amount
    ) external payable {
        require(
            _fromcontract != address(0),
            'DoCrossErc20 _addrcontract can not be zero'
        );
        require(bytes(_toChain).length != 0, 'DoCrossErc20 _toChain can not be null');
        require(_fromaddr != address(0), 'DoCrossErc20 _fromaddr can not be zero');
        require(amount > 0, 'DoCrossErc20 amount can not be zero');
        require(msg.value > 0, 'DoCrossErc20 must has fee');
        require(msg.sender == _fromaddr, 'DoCrossErc20 wrong _fromaddr');

        g_FeeAddr.transfer(msg.value);

        if (
            IERC20(_fromcontract).balanceOf(_fromaddr) >= amount &&
            IERC20(_fromcontract).allowance(_fromaddr, address(this)) >= amount
        ) {
            IERC20(_fromcontract).safeTransferFrom(_fromaddr, address(this), amount);
            emit event_CrossErc20(
                msg.value,
                _fromcontract,
                _tocontract,
                _toChain,
                _fromaddr,
                _toaddr,
                amount
            );
            return;
        }

        emit event_CrossErc20_Failed(
            msg.value,
            _fromcontract,
            _tocontract,
            _toChain,
            _fromaddr,
            _toaddr,
            amount
        );
        return;
    }

    function DoCrossErc721(
        address _fromcontract,
        string calldata _tocontract,
        string calldata _toChain,
        address _fromaddr,
        string calldata _toaddr,
        uint256 _nftid
    ) external payable {
        require(
            _fromcontract != address(0),
            'DoCrossErc721 _fromcontract can not be zero'
        );
        require(bytes(_toChain).length != 0, 'DoCrossErc721 _toChain can not be null');
        require(_fromaddr != address(0), 'DoCrossErc721 _fromaddr can not be zero');
        require(msg.value > 0, 'DoCrossErc721 must has fee');
        require(msg.sender == _fromaddr, 'DoCrossErc721 wrong _fromaddr');

        g_FeeAddr.transfer(msg.value);

        if (
            IERC721(_fromcontract).ownerOf(_nftid) == _fromaddr &&
            (IERC721(_fromcontract).getApproved(_nftid) == address(this) ||
                IERC721(_fromcontract).isApprovedForAll(_fromaddr, address(this)) == true)
        ) {
            IERC721(_fromcontract).transferFrom(_fromaddr, address(this), _nftid);
            emit event_CrossErc721(
                msg.value,
                _fromcontract,
                _tocontract,
                _toChain,
                _fromaddr,
                _toaddr,
                _nftid
            );
            return;
        }

        emit event_CrossErc721_Failed(
            msg.value,
            _fromcontract,
            _tocontract,
            _toChain,
            _fromaddr,
            _toaddr,
            _nftid
        );
        return;
    }

    ///withdraw action////////////////////////////////////////////////////////////////////////////
    function WithdrawErc20(
        uint256 nonce,
        address _fromcontract,
        string calldata _fromchain,
        string calldata _tocontract,
        address payable _addr,
        uint256 _amount,
        bytes calldata _signs
    ) external {
        require(g_iNonce + 1 == nonce, 'WithdrawErc20 nonce error');
        require(
            _fromcontract != address(0),
            'WithdrawErc20 _fromcontract can not be zero'
        );
        require(
            bytes(_fromchain).length != 0,
            'WithdrawErc20 _fromchain can not be null'
        );
        require(
            keccak256(bytes(_fromchain)) == keccak256(bytes(g_Name)),
            'WithdrawErc20 _fromchain error'
        );
        require(_addr != address(0), 'WithdrawErc20 _addr can not be zero');
        require(_signs.length == 65, 'WithdrawErc20 _signs length must be 65');

        bytes memory str = abi.encodePacked(
            nonce,
            _fromcontract,
            _fromchain,
            _tocontract,
            _addr,
            _amount
        );

        bytes32 hashmsg = keccak256(str);

        if (!g_MultiSignContract.CheckWitness(hashmsg, _signs)) {
            //revert("Withdraw CheckWitness failed");   //revert can make call failed ,but can't punish bad gays
            return;
        }
        g_iNonce++;
        emit event_nonce(g_iNonce);

        if (IERC20(_fromcontract).balanceOf(address(this)) >= _amount) {
            IERC20(_fromcontract).safeTransfer(_addr, _amount);
            emit event_withdrawErc20(
                _fromcontract,
                _fromchain,
                _tocontract,
                _addr,
                _amount
            );
            return;
        }

        emit event_withdrawErc20_Failed(
            _fromcontract,
            _fromchain,
            _tocontract,
            _addr,
            _amount
        );
        return;
    }

    function WithdrawErc721(
        uint256 nonce,
        address _fromcontract,
        string calldata _fromchain,
        string calldata _tocontract,
        address payable _addr,
        uint256 _nftid,
        bytes calldata signs
    ) external {
        require(g_iNonce + 1 == nonce, 'WithdrawErc721 nonce error');
        require(
            _fromcontract != address(0),
            'WithdrawErc721 _fromcontract can not be zero'
        );
        require(
            bytes(_fromchain).length != 0,
            'WithdrawErc721 _fromchain can not be null'
        );
        require(
            keccak256(bytes(_fromchain)) == keccak256(bytes(g_Name)),
            'WithdrawErc721 _fromchain error'
        );
        require(_addr != address(0), 'WithdrawErc721 _addr can not be zero');
        require(signs.length == 65, 'WithdrawErc721 signs length must be 65');

        bytes memory str = abi.encodePacked(
            nonce,
            _fromcontract,
            _fromchain,
            _tocontract,
            _addr,
            _nftid
        );
        bytes32 hashmsg = keccak256(str);

        if (!g_MultiSignContract.CheckWitness(hashmsg, signs)) {
            //revert("Withdraw CheckWitness failed");   //revert can make call failed ,but can't punish bad gays
            return;
        }

        g_iNonce++;
        emit event_nonce(g_iNonce);

        if (IERC721(_fromcontract).ownerOf(_nftid) == address(this)) {
            IERC721(_fromcontract).transferFrom(address(this), _addr, _nftid);
            emit event_withdrawErc721(
                _fromcontract,
                _fromchain,
                _tocontract,
                _addr,
                _nftid
            );
            return;
        }

        emit event_withdrawErc721_Failed(
            _fromcontract,
            _fromchain,
            _tocontract,
            _addr,
            _nftid
        );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';

contract MultiSign is Ownable {
    address g_CheckAddr;

    //events
    event event_updateAddr(address addr);

    constructor(address addr) {
        require(addr != address(0), 'constructor addr can not be zero');

        g_CheckAddr = addr;
        emit event_updateAddr(g_CheckAddr);
    }

    // fallback
    fallback() external payable {
        revert();
    }

    // receive
    receive() external payable {
        revert();
    }

    function getCheckAddr() public view returns (address) {
        return g_CheckAddr;
    }

    function updateCheckAddr(address addr) public onlyOwner {
        require(addr != address(0), 'updateCheckAddr addr can not be zero');

        g_CheckAddr = addr;
        emit event_updateAddr(g_CheckAddr);
    }

    function CheckWitness(bytes32 hashmsg, bytes memory signs)
        public
        view
        returns (bool)
    {
        require(signs.length == 65, 'signs must = 65');

        address tmp = decode(hashmsg, signs);
        if (tmp == g_CheckAddr) {
            return true;
        }
        return false;
    }

    function decode(bytes32 hashmsg, bytes memory signedString)
        private
        pure
        returns (address)
    {
        bytes32 r = bytesToBytes32(slice(signedString, 0, 32));
        bytes32 s = bytesToBytes32(slice(signedString, 32, 32));
        bytes1 v = slice(signedString, 64, 1)[0];
        return ecrecoverDecode(hashmsg, r, s, v);
    }

    function slice(
        bytes memory data,
        uint256 start,
        uint256 len
    ) private pure returns (bytes memory) {
        bytes memory b = new bytes(len);
        for (uint256 i = 0; i < len; i++) {
            b[i] = data[i + start];
        }

        return b;
    }

    //浣跨敤ecrecover鎭㈠鍦板潃
    function ecrecoverDecode(
        bytes32 hashmsg,
        bytes32 r,
        bytes32 s,
        bytes1 v1
    ) private pure returns (address addr) {
        uint8 v = uint8(v1);
        if (uint8(v1) == 0 || uint8(v1) == 1) {
            v = uint8(v1) + 27;
        }
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            return address(0);
        }
        addr = ecrecover(hashmsg, v, r, s);
    }

    //bytes杞崲涓篵ytes32
    function bytesToBytes32(bytes memory source) private pure returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }
}