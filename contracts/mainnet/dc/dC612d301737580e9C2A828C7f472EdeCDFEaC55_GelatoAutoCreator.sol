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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Types.sol";

/**
 * @dev Inherit this contract to allow your smart contract to
 * - Make synchronous fee payments.
 * - Have call restrictions for functions to be automated.
 */
// solhint-disable private-vars-leading-underscore
abstract contract AutomateReady {
    IAutomate public immutable automate;
    address public immutable dedicatedMsgSender;
    address private immutable _gelato;
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant OPS_PROXY_FACTORY =
        0xC815dB16D4be6ddf2685C201937905aBf338F5D7;

    /**
     * @dev
     * Only tasks created by _taskCreator defined in constructor can call
     * the functions with this modifier.
     */
    modifier onlyDedicatedMsgSender() {
        require(msg.sender == dedicatedMsgSender, "Only dedicated msg.sender");
        _;
    }

    /**
     * @dev
     * _taskCreator is the address which will create tasks for this contract.
     */
    constructor(address _automate, address _taskCreator) {
        automate = IAutomate(_automate);
        _gelato = IAutomate(_automate).gelato();
        (dedicatedMsgSender, ) = IOpsProxyFactory(OPS_PROXY_FACTORY).getProxyOf(
            _taskCreator
        );
    }

    /**
     * @dev
     * Transfers fee to gelato for synchronous fee payments.
     *
     * _fee & _feeToken should be queried from IAutomate.getFeeDetails()
     */
    function _transfer(uint256 _fee, address _feeToken) internal {
        if (_feeToken == ETH) {
            (bool success, ) = _gelato.call{value: _fee}("");
            require(success, "_transfer: ETH transfer failed");
        } else {
            SafeERC20.safeTransfer(IERC20(_feeToken), _gelato, _fee);
        }
    }

    function _getFeeDetails()
        internal
        view
        returns (uint256 fee, address feeToken)
    {
        (fee, feeToken) = automate.getFeeDetails();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "./AutomateReady.sol";

/**
 * @dev Inherit this contract to allow your smart contract
 * to be a task creator and create tasks.
 */
abstract contract AutomateTaskCreator is AutomateReady {
    using SafeERC20 for IERC20;

    address public immutable fundsOwner;
    ITaskTreasuryUpgradable public immutable taskTreasury;

    constructor(address _automate, address _fundsOwner)
        AutomateReady(_automate, address(this))
    {
        fundsOwner = _fundsOwner;
        taskTreasury = automate.taskTreasury();
    }

    /**
     * @dev
     * Withdraw funds from this contract's Gelato balance to fundsOwner.
     */
    function withdrawFunds(uint256 _amount, address _token) external {
        require(
            msg.sender == fundsOwner,
            "Only funds owner can withdraw funds"
        );

        taskTreasury.withdrawFunds(payable(fundsOwner), _token, _amount);
    }

    function _depositFunds(uint256 _amount, address _token) internal {
        uint256 ethValue = _token == ETH ? _amount : 0;
        taskTreasury.depositFunds{value: ethValue}(
            address(this),
            _token,
            _amount
        );
    }

    function _createTask(
        address _execAddress,
        bytes memory _execDataOrSelector,
        ModuleData memory _moduleData,
        address _feeToken
    ) internal returns (bytes32) {
        return
            automate.createTask(
                _execAddress,
                _execDataOrSelector,
                _moduleData,
                _feeToken
            );
    }

    function _cancelTask(bytes32 _taskId) internal {
        automate.cancelTask(_taskId);
    }

    function _resolverModuleArg(
        address _resolverAddress,
        bytes memory _resolverData
    ) internal pure returns (bytes memory) {
        return abi.encode(_resolverAddress, _resolverData);
    }

    function _timeModuleArg(uint256 _startTime, uint256 _interval)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode(uint128(_startTime), uint128(_interval));
    }

    function _proxyModuleArg() internal pure returns (bytes memory) {
        return bytes("");
    }

    function _singleExecModuleArg() internal pure returns (bytes memory) {
        return bytes("");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

enum Module {
    RESOLVER,
    TIME,
    PROXY,
    SINGLE_EXEC
}

struct ModuleData {
    Module[] modules;
    bytes[] args;
}

interface IAutomate {
    function createTask(
        address execAddress,
        bytes calldata execDataOrSelector,
        ModuleData calldata moduleData,
        address feeToken
    ) external returns (bytes32 taskId);

    function cancelTask(bytes32 taskId) external;

    function getFeeDetails() external view returns (uint256, address);

    function gelato() external view returns (address payable);

    function taskTreasury() external view returns (ITaskTreasuryUpgradable);
}

interface ITaskTreasuryUpgradable {
    function depositFunds(
        address receiver,
        address token,
        uint256 amount
    ) external payable;

    function withdrawFunds(
        address payable receiver,
        address token,
        uint256 amount
    ) external;

    function userTokenBalance(
        address user,
        address token
    ) external view returns (uint256);
}

interface IOpsProxyFactory {
    function getProxyOf(address account) external view returns (address, bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./SiloManagerV2.sol";
import "./BaseAutoCreator.sol";

contract GelatoAutoCreator is BaseAutoCreator {
    address public gelatoAutomate = 0x527a819db1eb0e34426297b03bae11F2f8B3A19E;

    uint256 minBalance = 20 ether;

    constructor(address _factory) BaseAutoCreator(2, _factory) {}

    function udpateMinBalance(uint256 _min) external onlyOwner {
        minBalance = _min;
    }

    function udpateGelatoAutomate(address _gelatoAutomate) external onlyOwner {
        gelatoAutomate = _gelatoAutomate;
    }

    function managerApproved(address) external pure override returns (bool) {
        return true;
    }

    function createAutoManager(
        bytes memory inputData
    ) public payable override returns (address) {
        require(msg.sender == managerFactory, "not factory");

        (, address owner) = abi.decode(inputData, (uint256, address));

        SiloManagerV2 manager = new SiloManagerV2(
            managerFactory,
            owner,
            gelatoAutomate
        );

        manager.depositManager{value: msg.value}();
        manager.createTask();

        return address(manager);
    }

    function addFund(bytes memory inputData) public payable override {
        require(msg.sender == managerFactory, "not factory");
        (address _manager, ) = abi.decode(inputData, (address, uint256));
        SiloManagerV2 manager = SiloManagerV2(_manager);
        manager.depositManager{value: msg.value}();
    }

    function cancelAuto(bytes memory inputData) public override returns (bool) {
        require(msg.sender == managerFactory, "not factory");
        address _manager = abi.decode(inputData, (address));

        SiloManagerV2 manager = SiloManagerV2(_manager);

        manager.cancelAutomate();
        manager.withdrawManager();
        return true;
    }

    function withdrawFund(
        bytes memory inputData
    ) public override returns (bool) {
        require(msg.sender == managerFactory, "not factory");

        (address _manager, ) = abi.decode(inputData, (address, bool));

        SiloManagerV2 manager = SiloManagerV2(_manager);

        manager.withdrawManager();
        return false;
    }

    function getAutoMinThreshold(
        address
    ) external view override returns (uint256) {
        return minBalance;
    }

    function getAutoManagerHighBalance(
        address manager
    ) public view override returns (uint256 balance) {
        if (manager != address(0)) {
            SiloManagerV2 v2Manager = SiloManagerV2(manager);
            balance = (minBalance * v2Manager.getRiskBuffer()) / uint96(10000);
        }
    }

    function getAutoManagerBalance(
        address manager
    ) external view override returns (uint256 balance) {
        if (manager != address(0)) {
            SiloManagerV2 v2Manager = SiloManagerV2(manager);
            balance = v2Manager.getBalance();
        }
    }

    function getTotalManagerInfo(
        address manager
    ) external view override returns (ManagerInfo memory info) {
        if (manager != address(0)) {
            SiloManagerV2 v2Manager = SiloManagerV2(manager);
            // uint256 id = v2Manager.taskId();

            uint256 balance = v2Manager.getBalance();
            uint256 minimumBalance = minBalance;
            uint96 riskBuffer = v2Manager.getRiskBuffer();
            (uint96 minRisk, uint96 minRejoin) = v2Manager.getMinBuffers();
            info = ManagerInfo({
                upkeepId: 0,
                manager: manager,
                currentBalance: balance,
                minimumBalance: minimumBalance,
                riskAdjustedBalance: (minimumBalance * riskBuffer) /
                    uint96(10000),
                riskBuffer: riskBuffer,
                rejoinBuffer: v2Manager.getRejoinBuffer(),
                minRisk: minRisk,
                minRejoin: minRejoin,
                autoTopup: v2Manager.autoTopup(),
                topupThreshold: 0,
                fundsWithdrawable: true,
                managerCanceled: false
            });
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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../../interfaces/ISiloManagerFactory.sol";
import "../../../interfaces/ISiloFactory.sol";
import "../../../interfaces/ISiloSubFactory.sol";
import "../../../interfaces/ISilo.sol";

import "./gelato/AutomateTaskCreator.sol";

contract SiloManagerV2 is AutomateTaskCreator {
    bytes32 public taskId;
    uint256 public autoType = 2;

    address public owner;
    address public managerFactory;
    ISiloManagerFactory ManagerFactory;

    uint256 public addFundsThreshold;

    uint256 public minManagerBalance = 20 ether;

    uint96 public riskBuffer; //based off a number 10000 -> ∞
    uint96 public rejoinBuffer;
    uint96 public bufferPerSilo;

    bool public autoTopup;

    mapping(address => bool) public whitelisted;

    address private lastSilo;
    uint256 private lastUpkeep;
    uint256 public fastGap;
    mapping(address => bool) public detected;
    bool public enableBurnCheck;

    event FastBurn(address silo, uint256 time);
    event SiloTaskCreated(bytes32 taskId);

    modifier onlyWhitelisted() {
        require(
            whitelisted[msg.sender] || msg.sender == dedicatedMsgSender,
            "Only whitelisted"
        );
        _;
    }

    modifier onlyAdmin() {
        require(
            msg.sender == managerFactory ||
                msg.sender == owner ||
                tx.origin == owner,
            "Caller is not the admin"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    constructor(
        address _mangerFactory,
        address _owner,
        address _automate
    ) AutomateTaskCreator(_automate, _owner) {
        managerFactory = _mangerFactory;
        ManagerFactory = ISiloManagerFactory(managerFactory);
        owner = _owner;

        addFundsThreshold = 500000000000000000;
        riskBuffer = 10000;
        rejoinBuffer = 10000;
        bufferPerSilo = ManagerFactory.bufferPerSilo();
        autoTopup = true;
        fastGap = 20;
    }

    function depositManager() external payable {
        _depositFunds(msg.value, ETH);
    }

    function setEnableBurnCheck(bool _flag) external onlyOwner {
        enableBurnCheck = _flag;
    }

    function initDetected(address _silo) external onlyOwner {
        detected[_silo] = false;
    }

    function initFastBurn() external onlyOwner {
        lastSilo = address(0);
        lastUpkeep = 0;
    }

    function setFastGap(uint256 _gap) external onlyOwner {
        require(_gap > 0, "wrong duration");
        fastGap = _gap;
    }

    function createTask() external {
        require(taskId == bytes32(""), "Already started task");

        ModuleData memory moduleData = ModuleData({
            modules: new Module[](2),
            args: new bytes[](2)
        });

        moduleData.modules[0] = Module.RESOLVER;
        moduleData.modules[1] = Module.PROXY;

        moduleData.args[0] = _resolverModuleArg(
            address(this),
            abi.encodeCall(this.checker, ())
        );

        moduleData.args[1] = _proxyModuleArg();

        bytes32 id = _createTask(
            address(this),
            abi.encode(this.performUpkeep.selector),
            moduleData,
            address(0)
        );

        taskId = id;
        emit SiloTaskCreated(id);
    }

    function checker()
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        ISiloFactory SiloFactory = ISiloFactory(ManagerFactory.siloFactory());
        ISiloSubFactory subFactory = ISiloSubFactory(SiloFactory.subFactory());
        uint256 siloID;
        bytes memory siloPerformData;

        ISilo Silo;
        for (uint256 i; i < SiloFactory.balanceOf(owner); ) {
            siloID = SiloFactory.tokenOfOwnerByIndex(owner, i);
            Silo = ISilo(SiloFactory.siloMap(siloID));
            if (
                Silo.getStatus() == Statuses.PAUSED ||
                Silo.autoType() != autoType ||
                detected[address(Silo)]
            ) {
                unchecked {
                    i++;
                }
                continue; //skip this silo
            }
            if (Silo.highRiskAction()) {
                //need to check if balance is above the min required  by some percent

                uint256 balance = taskTreasury.userTokenBalance(
                    address(this),
                    ETH
                );

                uint256 minBalance = (getRiskBuffer() * minManagerBalance) /
                    10000;
                if (balance < minBalance) {
                    if (
                        Silo.getStatus() == Statuses.MANAGED && Silo.deposited()
                    ) {
                        //high risk silo is currently managed, and manager is underfunded
                        canExec = true;

                        execPayload = abi.encodeCall(
                            this.performUpkeep,
                            (address(Silo), true, 3)
                        );
                        return (canExec, execPayload); //this will change the status of the silo to dormant
                    } else {
                        //silo has already been exitted out of high risk strategy
                        unchecked {
                            i++;
                        }
                        continue; //advance to check next silo
                    }
                } else if (Silo.getStatus() == Statuses.DORMANT) {
                    //check if balance has returned to a healthy level
                    // uint96 minRejoinBalance = getRejoinBuffer() * ManagerFactory.getMinBalance(upkeepId) / uint96(10000);
                    if (balance > minBalance && Silo.possibleReinvestSilo()) {
                        //silo balance has returned to a healthy level and silo is dormant so re enter the strategy
                        canExec = true;

                        execPayload = abi.encodeCall(
                            this.performUpkeep,
                            (address(Silo), false, 4)
                        );
                        return (canExec, execPayload);
                    } else {
                        unchecked {
                            i++;
                        }
                        continue;
                    }
                }
            }
            //check to see if any actions in the strategy have been deprecated logically or by the team, and if so have manager make silo exit strategy
            if (
                !canExec &&
                (!subFactory.skipActionValidTeamCheck(owner) ||
                    !subFactory.skipActionValidLogicCheck(owner))
            ) {
                (bool team, bool logic) = Silo.showActionStackValidity();
                if (
                    (!subFactory.skipActionValidTeamCheck(owner) && !team) ||
                    (!subFactory.skipActionValidLogicCheck(owner) && !logic)
                ) {
                    if (Silo.getStatus() == Statuses.MANAGED) {
                        canExec = true;

                        execPayload = abi.encodeCall(
                            this.performUpkeep,
                            (address(Silo), true, 5)
                        );

                        return (canExec, execPayload);
                    } else {
                        unchecked {
                            i++;
                        }
                        continue;
                    }
                }
            }

            if (!canExec) {
                (canExec, siloPerformData) = Silo.checkUpkeep("0x");

                if (canExec) {
                    (bool act, uint256 task) = abi.decode(
                        siloPerformData,
                        (bool, uint256)
                    );

                    execPayload = abi.encodeCall(
                        this.performUpkeep,
                        (address(Silo), act, task)
                    );

                    return (canExec, execPayload);
                }
            }
            unchecked {
                i++;
            }
        }

        return (false, bytes("No silo to call"));
    }

    function setAutoTopup(bool _flag) external onlyOwner {
        autoTopup = _flag;
    }

    function getBalance() public view returns (uint256 balance) {
        balance = taskTreasury.userTokenBalance(address(this), ETH);
    }

    function withdrawManager() external onlyAdmin {
        uint256 balance = taskTreasury.userTokenBalance(address(this), ETH);
        if (balance > 0) {
            taskTreasury.withdrawFunds(payable(owner), ETH, balance);
        }
    }

    function cancelAutomate() external onlyAdmin {
        _cancelTask(taskId);
    }

    function withdrawSelf() external onlyOwner {
        uint256 maticBalance = address(this).balance;
        if (maticBalance > 0) {
            (bool success, ) = payable(msg.sender).call{value: maticBalance}(
                ""
            );
            require(success, "issue withdraw self");
        }
    }

    function adjustThreshold(uint256 _newThreshold) external onlyOwner {
        require(_newThreshold > 0, "zero threshold");
        addFundsThreshold = _newThreshold;
    }

    function adjustWhitelist(address caller, bool flag) external onlyOwner {
        whitelisted[caller] = flag;
    }

    uint256 public autoCalledBlock;
    uint256 public autoCallTask;
    bool public autoCallType;
    address public autoCallActor;
    uint public callCount;

    function performUpkeep(
        address actor,
        bool act,
        uint256 task
    ) external onlyWhitelisted {
        if (actor != address(this)) {
            autoCallTask = task;
            autoCalledBlock = block.number;
            autoCallType = act;
            autoCallActor = actor;
            callCount += 1;

            if (enableBurnCheck) {
                if (
                    lastSilo == actor && lastUpkeep + fastGap > block.timestamp
                ) {
                    detected[actor] = true;
                    emit FastBurn(actor, block.timestamp);
                } else {
                    bytes memory siloPerformData = abi.encode(act, task);
                    ISilo(actor).performUpkeep(siloPerformData);
                }
                lastSilo = actor;
                lastUpkeep = block.timestamp;
            } else {
                bytes memory siloPerformData = abi.encode(act, task);
                ISilo(actor).performUpkeep(siloPerformData);
            }
        }
    }

    function ownerWithdraw(address _token, uint256 _amount) external {
        require(msg.sender == owner, "Only owner can withdraw ERC20s");
        SafeERC20.safeTransfer(IERC20(_token), msg.sender, _amount);
    }

    /**
     * @dev setting riskBuffer to 10000 means the factories risk buffer will be used
     * @dev setting riskBuffer to more than 10000 means that the users risk buffer will be used
     */
    function setCustomRiskBuffer(uint96 _buffer) external onlyAdmin {
        ISiloFactory SiloFactory = ISiloFactory(ManagerFactory.siloFactory());
        uint256 siloBalance = SiloFactory.balanceOf(owner);

        uint96 risk = uint96(10000) + uint96(siloBalance * bufferPerSilo);

        require(_buffer >= risk, "Risk Buffer not valid");

        riskBuffer = _buffer;
    }

    function setCustomRejoinBuffer(uint96 _buffer) external onlyAdmin {
        ISiloFactory SiloFactory = ISiloFactory(ManagerFactory.siloFactory());
        uint256 siloBalance = SiloFactory.balanceOf(owner);

        uint96 risk = uint96(10000) + uint96(siloBalance * bufferPerSilo);

        uint96 rejoin = (risk * 150) / 100;

        require(_buffer >= rejoin, "Risk Buffer not valid");

        rejoinBuffer = _buffer;
    }

    function getRiskBuffer() public view returns (uint96) {
        ISiloFactory SiloFactory = ISiloFactory(ManagerFactory.siloFactory());
        uint256 siloBalance = SiloFactory.balanceOf(owner);

        uint96 risk = uint96(10000) + uint96(siloBalance * bufferPerSilo);

        if (risk > riskBuffer) {
            return risk;
        } else {
            return riskBuffer;
        }
    }

    function getRejoinBuffer() public view returns (uint96) {
        ISiloFactory SiloFactory = ISiloFactory(ManagerFactory.siloFactory());
        uint256 siloBalance = SiloFactory.balanceOf(owner);

        uint96 risk = uint96(10000) + uint96(siloBalance * bufferPerSilo);

        uint96 rejoin = (risk * 150) / 100;

        if (rejoin > rejoinBuffer) {
            return rejoin;
        } else {
            return rejoinBuffer;
        }
    }

    function getMinBuffers()
        public
        view
        returns (uint96 minRisk, uint96 minRejoin)
    {
        ISiloFactory SiloFactory = ISiloFactory(ManagerFactory.siloFactory());
        uint256 siloBalance = SiloFactory.balanceOf(owner);

        minRisk = uint96(10000) + uint96(siloBalance * bufferPerSilo);
        minRejoin = (minRisk * 150) / 100;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct PriceOracle {
    address oracle;
    uint256 actionPrice;
}

enum Statuses {
    PAUSED,
    DORMANT,
    MANAGED,
    UNWIND
}

interface ISilo {
    function initialize(
        uint256 siloID,
        uint256 main,
        address factory,
        uint256 autoType
    ) external;

    function autoType() external view returns (uint256);

    function deposit() external;

    function withdraw(uint256 _requestedOut) external;

    function maintain() external;

    function exitSilo(address caller) external;

    function adminCall(address target, bytes memory data) external;

    function setStrategy(
        address[5] memory input,
        bytes[] memory _configurationData,
        address[] memory _implementations
    ) external;

    function getConfig() external view returns (bytes memory config);

    function withdrawToken(address token, address recipient) external;

    function adjustSiloDelay(uint256 _newDelay) external;

    function checkUpkeep(
        bytes calldata checkData
    ) external view returns (bool upkeepNeeded, bytes memory performData);

    function performUpkeep(bytes calldata performData) external;

    function siloDelay() external view returns (uint256);

    function name() external view returns (string memory);

    function lastTimeMaintained() external view returns (uint256);

    function setName(string memory name) external;

    function deposited() external view returns (bool);

    function isNew() external view returns (bool);

    function status() external view returns (Statuses);

    function setStrategyName(string memory _strategyName) external;

    function setStrategyCategory(uint256 _strategyCategory) external;

    function strategyName() external view returns (string memory);

    function tokenMinimum(address token) external view returns (uint256);

    function strategyCategory() external view returns (uint256);

    function main() external view returns (uint256);

    function lastPid() external view returns (uint256);

    function adjustStrategy(
        uint256 _index,
        bytes memory _configurationData,
        address _implementation
    ) external;

    function viewStrategy()
        external
        view
        returns (address[] memory actions, bytes[] memory configData);

    function highRiskAction() external view returns (bool);

    function showActionStackValidity() external view returns (bool, bool);

    function getInputTokens() external view returns (address[5] memory);

    function getStatus() external view returns (Statuses);

    function pause() external;

    function unpause() external;

    function setActive() external;

    function possibleReinvestSilo() external view returns (bool possible);

    function getExtraSiloInfo()
        external
        view
        returns (
            uint256 strategyType,
            uint256 currentBalance,
            uint256 possibleWithdraw,
            uint256 availableBlock,
            uint256 pendingReward,
            uint256 lastPid
        );

    function getReferralInfo()
        external
        view
        returns (uint256 fee, address recipient);

    function setReferralInfo(bytes32 _code) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface ISiloFactory is IERC721Enumerable{
    function tokenMinimum(address _token) external view returns(uint _minimum);
    function balanceOf(address _owner) external view returns(uint);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function managerFactory() external view returns(address);
    function siloMap(uint _id) external view returns(address);
    function tierManager() external view returns(address);
    function ownerOf(uint _id) external view returns(address);
    function siloToId(address silo) external view returns(uint);
    // function createSilo(address recipient) external returns(uint);
    function setActionStack(uint siloID, address[5] memory input, address[] memory _implementations, bytes[] memory _configurationData) external;
    // function withdraw(uint siloID) external;
    function getFeeInfo(address _action) external view returns(uint fee, address recipient);
    function strategyMaxGas() external view returns(uint);
    function strategyName(string memory _name) external view returns(uint);
    
    function getCatalogue(uint _type) external view returns(string[] memory);
    function getStrategyInputs(uint _id) external view returns(address[5] memory inputs);
    function getStrategyActions(uint _id) external view returns(address[] memory actions);
    function getStrategyConfigurationData(uint _id) external view returns(bytes[] memory configurationData);
    function useCustom(address _action) external view returns(bool);
    // function getFeeList(address _action) external view returns(uint[4] memory);
    function feeRecipient(address _action) external view returns(address);
    function defaultFeeList() external view returns(uint[4] memory);
    function defaultRecipient() external view returns(address);
    // function getTier(address _silo) external view returns(uint);

    function getFeeInfoNoTier(address _action) external view returns(uint[4] memory);
    function highRiskActions(address _action) external view returns(bool);
    function actionValid(address _action) external view returns(bool);
    function skipActionValidTeamCheck(address _user) external view returns(bool);
    function skipActionValidLogicCheck(address _user) external view returns(bool);
    function isSilo(address _silo) external view returns(bool);

    function isSiloManager(address _silo,address _manager) external view returns(bool);

    function currentStrategyId() external view returns(uint);
    function minBalance() external view returns(uint);

    function mainActoins(string memory strategyName) external view returns(uint);
    
    function subFactory() external view returns(address);
    function referral() external view returns(address);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISiloSubFactory {
    function acceptTransfersFrom(address to, address from)
        external
        view
        returns (bool);

    function skipActionValidTeamCheck(address user)
        external
        view
        returns (bool);

    function skipActionValidLogicCheck(address user)
        external
        view
        returns (bool);

    function checkActionsLogicValid(
        address user,
        address[] memory _actions,
        bytes[] memory _configurationData
    ) external view returns (bool);

    function checkActionLogicValid(
        address user,
        address _implementation,
        bytes memory _configurationData
    ) external view returns(bool);
}