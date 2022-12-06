/**
 *Submitted for verification at polygonscan.com on 2022-12-05
*/

/** 
 *  SourceUnit: /Users/michaels/BlockPlot/contracts/BlockPlot/InitialSale.sol
*/
            
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [////IMPORTANT]
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
     * ////IMPORTANT: because control is transferred to `recipient`, care must be
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




/** 
 *  SourceUnit: /Users/michaels/BlockPlot/contracts/BlockPlot/InitialSale.sol
*/
            

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
     * ////IMPORTANT: The same issues {IERC20-approve} has related to transaction
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




/** 
 *  SourceUnit: /Users/michaels/BlockPlot/contracts/BlockPlot/InitialSale.sol
*/
            

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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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




/** 
 *  SourceUnit: /Users/michaels/BlockPlot/contracts/BlockPlot/InitialSale.sol
*/
            

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




/** 
 *  SourceUnit: /Users/michaels/BlockPlot/contracts/BlockPlot/InitialSale.sol
*/
            

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

////import "../utils/Context.sol";

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
}




/** 
 *  SourceUnit: /Users/michaels/BlockPlot/contracts/BlockPlot/InitialSale.sol
*/
            

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




/** 
 *  SourceUnit: /Users/michaels/BlockPlot/contracts/BlockPlot/InitialSale.sol
*/
            

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

////import "../../utils/introspection/IERC165.sol";

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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




/** 
 *  SourceUnit: /Users/michaels/BlockPlot/contracts/BlockPlot/InitialSale.sol
*/
            

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

////import "./IERC165.sol";

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




/** 
 *  SourceUnit: /Users/michaels/BlockPlot/contracts/BlockPlot/InitialSale.sol
*/
            


pragma solidity ^0.8.7;

/// @author Michael Amadi
/// @title BlockPlot Identity Contract

////import "@openzeppelin/contracts/access/Ownable.sol";

contract Identity is Ownable {
    // Id counter, starts from 1 so that 0 can be the default value for any unmapped address. Similar to address(0)
    uint256 internal currentId = 1;

    struct reAssignWaitlistInfo {
        address oldAddress;
        uint256 timeOutEnd;
    }

    // mapping that returns the User Id of any address, returns 0 if not currently mapped yet.
    mapping(address => uint256) internal _resolveId;

    // mapping that returns the address that owns a user Id, returns adress(0) if not currently mapped. This doesn't necessarily serve any function except
    // for on chain verification by other contracts and off chain accesibility
    mapping(uint256 => address) internal _resolveAddress;

    // mapping that resolves if an address has been linked anytime in the past even if its access is currently revoked.
    mapping(address => bool) internal _isUsedAddress;

    // mapping that resolves if a user id has been revoked and is yet to be reAssigned, returns address(0) if false and the address it was revoked from if true.
    // once an address is mapped here it can't be unmapped.
    mapping(uint256 => reAssignWaitlistInfo) internal _reAssignWaitlist;

    event Verified(address indexed userAddress, uint256 indexed userId);

    event Revoked(address indexed userAddress, uint256 indexed userId);

    event ReAssigned(address indexed userAddress, uint256 indexed userId);

    /// @notice lets owner verify an address @param user and maps it to an ID.
    /// @param user: address of new user to be mapped
    /// @notice cannot map: a previously verified address (whether currently mapped or revoked)
    function verify(address user) public onlyOwner {
        require(user != address(0), "Cannot verify address 0");
        require(!_isUsedAddress[user], "Address has previously been linked");
        _isUsedAddress[user] = true;
        _resolveId[user] = currentId;
        _resolveAddress[currentId] = user;
        emit Verified(user, currentId);
        unchecked {
            currentId++;
        }
    }

    /// @notice lets owner verify an address @param users.
    /// @param users: address of new user to be mapped
    /// @notice cannot map: a previously verified address (whether currently mapped or revoked)
    function verifyBatch(address[] calldata users) external {
        for (uint256 i = 0; i < users.length; i++) {
            verify(users[i]);
        }
    }

    /// @notice lets owner revoke the ID an address @param user.
    /// @param user: address of user to be revoked
    /// @notice cannot revoke: an unmapped user
    function revoke(address user) public onlyOwner {
        uint256 userId = _resolveId[user];
        require(userId != 0, "Address is not mapped");
        require(
            _reAssignWaitlist[userId].oldAddress == address(0),
            "Id is on waitlist already"
        );
        _resolveId[user] = 0;
        _resolveAddress[userId] = address(0);
        _reAssignWaitlist[userId] = reAssignWaitlistInfo(
            user,
            block.timestamp + 3 days
        );
        emit Revoked(user, userId);
    }

    /// @notice lets owner revoke the ID an address @param users.
    /// @param users: address of user to be revoked
    /// @notice cannot revoke: an unmapped user
    function revokeBatch(address[] calldata users) external {
        for (uint256 i = 0; i < users.length; i++) {
            revoke(users[i]);
        }
    }

    /// @notice lets owner reassigns an Id @param userId to an address @param user.
    /// @param user: address of user to be revoked
    /// @param userId: ID to re assign @param user to
    /// @notice to enable re assignment to its last address it checks if the last
    ///      address is the same as the input @param user and remaps it to its old Id
    ///      else, it reverts if a previously mapped or/and revoked address is being mapped to another Id than its last (and only)

    function reAssign(uint256 userId, address user) public onlyOwner {
        require(user != address(0), "Cannot reAssign ID to address 0");
        reAssignWaitlistInfo memory _reAssignWaitlistInfo = _reAssignWaitlist[
            userId
        ];
        require(
            _reAssignWaitlistInfo.timeOutEnd <= block.timestamp,
            "cool down not elapsed"
        );
        require(
            _reAssignWaitlistInfo.oldAddress != address(0),
            "Id not on reassign waitlist"
        );
        if (user == _reAssignWaitlistInfo.oldAddress) {
            _reAssignWaitlist[userId].oldAddress = address(0);
            _resolveId[user] = userId;
            _resolveAddress[userId] = user;
        } else {
            require(!_isUsedAddress[user], "Address has been linked");
            _isUsedAddress[user] = true;
            _reAssignWaitlist[userId].oldAddress = address(0);
            _reAssignWaitlistInfo.timeOutEnd = 0;
            _resolveId[user] = userId;
            _resolveAddress[userId] = user;
        }
        emit ReAssigned(user, userId);
    }

    /// @notice lets owner reassigns an Id @param userIds to an address @param users.
    /// @param users: address of user to be revoked
    /// @param userIds: ID to re assign @param users to
    /// @notice to enable re assignment to its last address it checks if the last
    ///      address is the same as the input @param users and remaps it to its old Id
    ///      else, it reverts if a previously mapped or/and revoked address is being mapped to another Id than its last (and only)
    function reAssignBatch(
        uint256[] calldata userIds,
        address[] calldata users
    ) external {
        require(
            userIds.length == users.length,
            "UserID and User of different lengths"
        );
        for (uint256 i = 0; i < users.length; i++) {
            reAssign(userIds[i], users[i]);
        }
    }

    function resolveId(address user) external view returns (uint256 userId) {
        userId = _resolveId[user];
    }

    function resolveAddress(
        uint256 userId
    ) external view returns (address user) {
        user = _resolveAddress[userId];
    }

    function reAssignWaitlist(
        uint256 userId
    )
        external
        view
        returns (reAssignWaitlistInfo memory _reAssignWaitlistInfo)
    {
        _reAssignWaitlistInfo = _reAssignWaitlist[userId];
    }

    function isUsedAddress(address user) external view returns (bool isUsed) {
        isUsed = _isUsedAddress[user];
    }
}




/** 
 *  SourceUnit: /Users/michaels/BlockPlot/contracts/BlockPlot/InitialSale.sol
*/
            

// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

////import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}




/** 
 *  SourceUnit: /Users/michaels/BlockPlot/contracts/BlockPlot/InitialSale.sol
*/
            

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

////import "../../utils/introspection/IERC165.sol";

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





/** 
 *  SourceUnit: /Users/michaels/BlockPlot/contracts/BlockPlot/InitialSale.sol
*/
            

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}




/** 
 *  SourceUnit: /Users/michaels/BlockPlot/contracts/BlockPlot/InitialSale.sol
*/
            

// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

////import "../utils/Context.sol";

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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




/** 
 *  SourceUnit: /Users/michaels/BlockPlot/contracts/BlockPlot/InitialSale.sol
*/
            


// Improvised version of OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol) for Identity.sol

/// @author Michael Amadi
/// @title BlockPlot Base ERC1155 modified Contract

pragma solidity ^0.8.7;
////import "hardhat/console.sol";
////import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
////import {IERC1155, IERC1155MetadataURI} from "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
////import {Address} from "@openzeppelin/contracts/utils/Address.sol";
////import {Context} from "@openzeppelin/contracts/utils/Context.sol";
////import {Identity} from "./Identity.sol";
////import {ERC165, IERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract ImprovisedERC1155 is Context, ERC165, IERC1155 {
    using Address for address;

    // address of the identity contract.
    address public identityAddress;

    uint256 public constant decimals = 18;

    struct AssetMetadata {
        string name;
        string symbol;
        uint256 totalSupply;
        uint256 vestingPeriod;
        uint256 initialSalePeriod;
        uint256 costToDollar;
        bool initialized; // set to true forever after asset is initialized
        uint256 assetId; // set to the currentAssetId value and never changeable
        address assetIssuer;
    }

    mapping(uint256 => AssetMetadata) public idToMetadata;

    // Mapping from asset id to userId's balance
    mapping(uint256 => mapping(uint256 => uint256)) balances;

    // Mapping from userId to operator approvals
    mapping(uint256 => mapping(uint256 => bool)) private _operatorApprovals;

    mapping(uint256 => bool) isExchange;

    constructor(address _identityAddress) {
        identityAddress = _identityAddress;
        isExchange[1] = true;
        isExchange[2] = true;
    }

    function _idToMetadata(
        uint256 assetId
    ) external view returns (AssetMetadata memory) {
        return idToMetadata[assetId];
    }

    // // change the identity contract's address, overriden to be called by onlyOwner in BlockPlotERC1155 contract.
    // function changeIdentityAddress(
    //     address newIdentityAddress
    // ) external virtual {
    //     require(newIdentityAddress != address(0), "cant set to address 0");
    //     identityAddress = newIdentityAddress;
    // }

    function initialSaleAddress() public view returns (address) {
        return Identity(identityAddress).resolveAddress(1);
    }

    function swapContractAddress() public view returns (address) {
        return Identity(identityAddress).resolveAddress(2);
    }

    // // sets/changes the vesting period for an asset
    // function changeVestingPeriod(
    //     uint256 assetId,
    //     uint256 vestingEnd
    // ) external virtual {
    //     idToMetadata[assetId].vestingPeriod = vestingEnd;
    // }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(
        address account,
        uint256 id
    ) public view virtual override returns (uint256) {
        uint256 userId = Identity(identityAddress).resolveId(account);
        require(userId != 0, "ERC1155: address is not a valid owner");
        return balances[id][userId];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) public view virtual override returns (uint256[] memory) {
        require(
            accounts.length == ids.length,
            "ERC1155: accounts and ids length mismatch"
        );
        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(
        address account,
        address operator
    ) public view virtual override returns (bool) {
        uint256 _account = Identity(identityAddress).resolveId(account);
        require(_account != 0, "ERC1155: account is not a valid owner");
        uint256 _operator = Identity(identityAddress).resolveId(operator);
        require(_operator != 0, "ERC1155: operator is not a valid owner");

        return _operatorApprovals[_account][_operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 _from = Identity(identityAddress).resolveId(from);
        require(_from != 0, "ERC1155: from is not a valid owner");
        require(
            _from == 1 || idToMetadata[id].initialSalePeriod < block.timestamp,
            "Initial Sale period still on"
        );
        require(
            _from == 1 || idToMetadata[id].vestingPeriod < block.timestamp,
            "Vesting period still on"
        );

        uint256 _to = Identity(identityAddress).resolveId(to);
        require(_to != 0, "ERC1155: to is not a valid owner");

        uint256 fromBalance = balances[id][_from];
        require(
            fromBalance >= amount,
            "ERC1155: insufficient balance for transfer"
        );

        if (!isExchange[_to]) {
            uint256 percentageHoldings = ((balances[id][_to] + amount) * 100) /
                (idToMetadata[id].totalSupply);

            require(percentageHoldings < 10, "Cant own >= 10% of total supply");
        }

        unchecked {
            balances[id][_from] = fromBalance - amount;
        }
        balances[id][_to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 _from = Identity(identityAddress).resolveId(from);
        require(_from != 0, "ERC1155: from is not a valid owner");
        uint256 _to = Identity(identityAddress).resolveId(to);
        require(_to != 0, "ERC1155: to is not a valid owner");

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            require(
                _from == 1 ||
                    idToMetadata[id].initialSalePeriod < block.timestamp,
                "Initial Sale period still on"
            );
            require(
                _from == 1 || idToMetadata[id].vestingPeriod < block.timestamp,
                "Vesting period still on"
            );
            uint256 amount = amounts[i];

            uint256 fromBalance = balances[id][_from];
            require(
                fromBalance >= amount,
                "ERC1155: insufficient balance for transfer"
            );

            if (!isExchange[_to]) {
                uint256 percentageHoldings = ((balances[id][_to] + amount) *
                    100) / (idToMetadata[id].totalSupply);
                require(
                    percentageHoldings < 10,
                    "Cant own >= 10% of total supply"
                );
            }
            unchecked {
                balances[id][_from] = fromBalance - amount;
            }
            balances[id][_to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        address to = initialSaleAddress();
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        uint256 _to = Identity(identityAddress).resolveId(to);
        require(_to != 0, "ERC1155: to is not a valid owner");

        balances[id][_to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            id,
            amount,
            data
        );
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        address to = initialSaleAddress();
        require(to != address(0), "ERC1155: mint to the zero address");
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        uint256 _to = Identity(identityAddress).resolveId(to);
        require(_to != 0, "ERC1155: to is not a valid owner");

        for (uint256 i = 0; i < ids.length; i++) {
            balances[ids[i]][_to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            ids,
            amounts,
            data
        );
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(uint256 id, uint256 amount) internal virtual {
        address from = initialSaleAddress();
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 _from = Identity(identityAddress).resolveId(from);
        require(_from != 0, "ERC1155: from is not a valid owner");

        uint256 fromBalance = balances[id][_from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            balances[id][_from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        address from = initialSaleAddress();
        require(from != address(0), "ERC1155: burn from the zero address");
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 _from = Identity(identityAddress).resolveId(from);
            require(_from != 0, "ERC1155: from is not a valid owner");

            uint256 fromBalance = balances[id][_from];
            require(
                fromBalance >= amount,
                "ERC1155: burn amount exceeds balance"
            );
            unchecked {
                balances[id][_from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");

        uint256 _owner = Identity(identityAddress).resolveId(owner);
        require(_owner != 0, "ERC1155: owner is not a valid owner");
        uint256 _operator = Identity(identityAddress).resolveId(operator);
        require(_operator != 0, "ERC1155: operator is not a valid owner");

        _operatorApprovals[_owner][_operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver.onERC1155BatchReceived.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(
        uint256 element
    ) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}




/** 
 *  SourceUnit: /Users/michaels/BlockPlot/contracts/BlockPlot/InitialSale.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: UNLICENSED
pragma solidity ^0.8.7;

/// @author Michael Amadi
/// @title BlockPlot Asset Contract

// ////import "hardhat/console.sol";
////import {ImprovisedERC1155} from "./ImprovisedERC1155.sol";
////import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
////import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
////import {Identity} from "./Identity.sol";
////import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract BlockPlotERC1155 is Ownable, Pausable, ImprovisedERC1155 {
    using Strings for uint256;

    uint256 public currentAssetId = 0;

    constructor(address _identityAddress) ImprovisedERC1155(_identityAddress) {}

    //_______________________________________________________Events___________________________________________________________

    event VestingPeriodChanged(uint256 assetId, uint256 vestingEnd);
    event InitialSalePeriodChanged(uint256 assetId, uint256 InitialSaleEnd);
    event AssetIsserChanged(uint256 assetId, address newAssetIssuer);
    event AssetInitialized(
        uint256 indexed assetId,
        string indexed name,
        string symbol,
        uint256 costToDollar,
        uint256 vestingPeriod,
        uint256 initialSalePeriod,
        address assetIssuer,
        uint256 minted
    );

    //___________________________________________________________________________________________________________________________

    function setExchange(uint256 id, bool _isExchange) external onlyOwner {
        isExchange[id] = _isExchange;
    }

    /// @notice pauses all interactions with functions with 'whenNotPaused' modifier
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice unpauses all interactions with functions with 'whenNotPaused' modifier
    function unPause() public onlyOwner {
        _unpause();
    }

    /// @notice stops approvals if contract is paused
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override {
        require(!paused(), "ERC1155Pausable: token transfer while paused");
        super.setApprovalForAll(operator, approved);
    }

    /// @notice checks to stop transfers if the contract is paused
    /// @notice prevents minting tokens for uninitialized assets
    /// @notice handles increase and decreasing of total supply of assets in each assets AssetMetadata struct
    function _beforeTokenTransfer(
        address,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory
    ) internal virtual override {
        require(!paused(), "ERC1155Pausable: token transfer while paused");

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                require(
                    idToMetadata[ids[i]].initialized,
                    "Asset uninitialized"
                );
                idToMetadata[ids[i]].totalSupply += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = idToMetadata[id].totalSupply;
                require(
                    supply >= amount,
                    "ERC1155: burn amount exceeds totalSupply"
                );
                unchecked {
                    idToMetadata[id].totalSupply = supply - amount;
                }
            }
        }
    }

    /// @notice changes the identity address to @param newIdentityAddress
    /// @param newIdentityAddress: identity address to change to.
    function changeIdentityAddress(
        address newIdentityAddress
    ) external onlyOwner {
        require(newIdentityAddress != address(0), "cant set to address 0");
        identityAddress = newIdentityAddress;
    }

    /// @notice changes the vesting period for an asset
    /// @param assetId: asset Id of asset to update
    /// @param vestingEnd: new end of vesting period
    function changeVestingPeriod(
        uint256 assetId,
        uint256 vestingEnd
    ) external onlyOwner {
        require(idToMetadata[assetId].initialized, "Asset not initialized");
        idToMetadata[assetId].vestingPeriod = vestingEnd;
        emit VestingPeriodChanged(assetId, vestingEnd);
    }

    /// @notice changes the initial sale period for an asset
    /// @param assetId: asset Id of asset to update
    /// @param initialSaleEnd: new end of initial sale period
    function changeInitialSalePeriod(
        uint256 assetId,
        uint256 initialSaleEnd
    ) external onlyOwner {
        require(idToMetadata[assetId].initialized, "Asset not initialized");
        idToMetadata[assetId].initialSalePeriod = initialSaleEnd;
        emit InitialSalePeriodChanged(assetId, initialSaleEnd);
    }

    /// @notice changes the asset issuer of an asset
    /// @param assetId: asset Id of asset to update
    /// @param newAssetIssuer: new address of the asset issuer
    function setAssetIssuerAddress(
        uint256 assetId,
        address newAssetIssuer
    ) external onlyOwner {
        require(idToMetadata[assetId].initialized, "Asset not initialized");
        idToMetadata[assetId].assetIssuer = newAssetIssuer;
        emit AssetIsserChanged(assetId, newAssetIssuer);
    }

    /// @notice Initializes an asset id
    /// @notice without being initialized, an asset cannot be minted. there's no way to uninitialize an asset
    /// @param _name: name of new asset to be initialized
    /// @param _symbol: symbol of new asset to be initialized
    /// @param _costToDollar: cost in dollars of one asset's token (taking the 18 decimal places into consideration)
    /// @param _vestingPeriod: end of vesting period which prevent user who bought the asset from selling it until the time elapses
    /// @param _initialSalePeriod: when the intial sale will end and users can purchase assets from DeXes and asset issuers can withdraw proceeds
    /// @param _assetIssuer: address of the asset issuer
    /// @param _mintAmount: amount of tokens to mint while initializing the asset, 0 if to be minted later
    function initializeAsset(
        string memory _name,
        string memory _symbol,
        uint256 _costToDollar,
        uint256 _vestingPeriod,
        uint256 _initialSalePeriod,
        address _assetIssuer,
        uint256 _mintAmount
    ) external onlyOwner {
        require(!paused(), "ERC1155Pausable: token transfer while paused");
        uint256 _currentAssetId = currentAssetId;
        require(
            !idToMetadata[_currentAssetId].initialized,
            "Asset initialized"
        );
        idToMetadata[_currentAssetId] = AssetMetadata(
            _name,
            _symbol,
            0,
            _vestingPeriod,
            _initialSalePeriod,
            _costToDollar,
            true,
            _currentAssetId,
            _assetIssuer
        );

        unchecked {
            currentAssetId++;
        }

        // if mint amount is greater than 0, mint the value to the initial sale contract.
        if (_mintAmount > 0) _mint(_currentAssetId, _mintAmount, "");

        emit AssetInitialized(
            _currentAssetId,
            _name,
            _symbol,
            _costToDollar,
            _vestingPeriod,
            _initialSalePeriod,
            _assetIssuer,
            _mintAmount
        );
    }

    /// @notice mints asset, should be minted only to the initial sale contract address and is hardcoded
    /// @param id: asset Id of token to mint
    /// @param amount: amount of tokens to be minted to the initial sale contract
    function mintAsset(uint256 id, uint256 amount) external onlyOwner {
        _mint(id, amount, "");
    }

    /// @notice burn asset, can burn assets on the initial sale contract
    /// @param id: asset id of token to burn
    /// @param amount: amount of tokens to be burned from the initial sale contract
    function burnAsset(uint256 id, uint256 amount) external onlyOwner {
        _burn(id, amount);
    }

    /// @notice batch-mints asset, should be minted only to the initial sale contract address and is hardcoded
    /// @param ids: asset Id of token to mint
    /// @param amounts: amounts of tokens to be minted to the initial sale contract
    /// @dev ids and amounts is ran respectively so should be arranged as so
    function mintBatchAsset(
        uint256[] memory ids,
        uint256[] memory amounts
    ) external onlyOwner {
        _mintBatch(ids, amounts, "0x");
    }

    /// @notice batch-burns asset, should be burned only from the initial sale contract address and is hardcoded
    /// @param ids: asset Id of token to burn
    /// @param amounts: amounts of tokens to be burned from the initial sale contract
    /// @dev ids and amounts is ran respectively so should be arranged as so
    function burnBatchAsset(
        uint256[] memory ids,
        uint256[] memory amounts
    ) external onlyOwner {
        _burnBatch(ids, amounts);
    }
}




/** 
 *  SourceUnit: /Users/michaels/BlockPlot/contracts/BlockPlot/InitialSale.sol
*/
            

pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}




/** 
 *  SourceUnit: /Users/michaels/BlockPlot/contracts/BlockPlot/InitialSale.sol
*/
            

// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

////import "../IERC1155Receiver.sol";
////import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}




/** 
 *  SourceUnit: /Users/michaels/BlockPlot/contracts/BlockPlot/InitialSale.sol
*/
            

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

////import "../IERC20.sol";

/**
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




/** 
 *  SourceUnit: /Users/michaels/BlockPlot/contracts/BlockPlot/InitialSale.sol
*/
            

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

////import "../IERC20.sol";
////import "../extensions/draft-IERC20Permit.sol";
////import "../../../utils/Address.sol";

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




/** 
 *  SourceUnit: /Users/michaels/BlockPlot/contracts/BlockPlot/InitialSale.sol
*/
            

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




/** 
 *  SourceUnit: /Users/michaels/BlockPlot/contracts/BlockPlot/InitialSale.sol
*/
            

pragma solidity ^0.8.7;

/// @author Michael Amadi
/// @title BlockPlot Chainlink Price Consumer V3 Library
////import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// ////import "hardhat/console.sol";
////import {BlockPlotERC1155} from "../BlockPlotERC1155.sol";

library PriceConsumerV3 {
    //gets the latest price of an asset from chainlink nodes
    //@params priceFeed: The price feed address of the token pair.
    function getLatestPrice(address priceFeed) internal view returns (uint) {
        (, int price /*uint80 answeredInRound*/, , , ) = AggregatorV3Interface(
            priceFeed
        ).latestRoundData();
        require(price > 0, "Price of token is/below zero!");
        return uint256(price);
    }

    /// @notice checks the amount in a "token" that will be paid for a particular amount of an asset
    /// @param amount: the amount of assets you want to buy/sell
    /// @param _costToDollar: the costToDollar of the asset to be bought fetched from the BlockPlotERC1155 contract
    /// @param _decimals: decimals of the "token" used for payment
    /// @param priceFeedAddress: The price feed address of the token pair.
    /// @param feePercentage: The fee to pay in respect to 10,000 as 100%
    function costToDollar(
        uint256 amount,
        uint256 _costToDollar,
        uint256 _decimals,
        address priceFeedAddress,
        uint256 feePercentage
    ) external view returns (uint256 cost, uint256 fee) {
        require(
            feePercentage >= 10000 || feePercentage == 0,
            "Fee percentage must be above 10000"
        );
        require(_costToDollar > 0, "Cost to dollar of asset not set");

        // FOR CALCULATING AMOUNT OF ASSET AND COST
        // decimals of assets
        // ((1 * 10 ** 18) / _costToDollar) = amount / x  ... cross multiply
        // ((_costToDollar * AggregatorV3Interface(priceFeedAddress).decimals()) * amount) / (1 * 10 ** 18 ) = x

        // FOR CALCULATING COST OF TOKEN TO PAY
        // totalCost = x (still unsolved)
        // find the total cost from dollars converted to the token
        // priceOfOneToken = getLatestPrice(token)
        // if (priceOfOneToken === 1 ** AggregatorV3Interface(priceFeedAddress).decimals()) return priceOfOneToken * amount
        // else
        // (priceOfOneToken / (1 * 10 ** tokenDecimals)) = (totalCost / y) ... cross multiply
        // (priceOfOneToken * y) = ((1 * 10 ** tokenDecimals) * totalCost)
        // y = ((1 * 10 ** tokenDecimals) * totalCost) / priceOfOneToken
        // finally
        // y = (((1 * 10 ** tokenDecimals) * _costToDollar * amount) / (1 * 10 ** 18 )) / priceOfOneToken
        // _costToDollar here is the amount in dollars to the power of the aggregator's decimals

        cost =
            (((10 ** _decimals) *
                (_costToDollar *
                    10 ** AggregatorV3Interface(priceFeedAddress).decimals()) *
                amount) / (1e18)) /
            getLatestPrice(priceFeedAddress);

        require(cost > 0, "amount below minimum safe buy");

        fee = feePercentage > 0 && feePercentage != 10000
            ? ((cost * feePercentage) / 10000) - cost
            : 0;
    }

    /// @notice checks the amount in a "token" that will be paid for a particular amount of an asset
    /// @param dollarValue: the amount of tokens you want to buy/sell
    /// @param _costToDollar: the costToDollar of the asset to be bought fetched from the BlockPlotERC1155 contract
    /// @param _decimals: decimals of the "token" used for payment
    /// @param priceFeedAddress: The price feed address of the token pair.
    /// @param feePercentage: The fee to pay in respect to 10,000 as 100%
    function tokenToAsset(
        uint256 dollarValue,
        uint256 _costToDollar,
        uint256 _decimals,
        address priceFeedAddress,
        uint256 feePercentage
    ) external view returns (uint256 cost, uint256 fee) {
        require(
            feePercentage >= 10000 || feePercentage == 0,
            "Fee percentage must be above 10000"
        );
        require(_costToDollar > 0, "Cost to dollar of asset not set");

        // FOR CALCULATING AMOUNT OF ASSET AND COST
        // decimals of assets
        // ((1 * 10 ** 18) / _costToDollar) = amount / x  ... cross multiply
        // ((_costToDollar * AggregatorV3Interface(priceFeedAddress).decimals()) * amount) / (1 * 10 ** 18 ) = x

        // FOR CALCULATING COST OF ASSET TO PAY
        // From costToDollar function we know that
        // y = (((1 * 10 ** tokenDecimals) * _costToDollar * amount) / (1 * 10 ** 18 )) / priceOfOneToken

        // lets derive a formula for when amount is the unknown
        // (((1 * 10 ** tokenDecimals) * _costToDollar * amount) / (1 * 10 ** 18 )) = priceOfOneToken * y
        // ((1 * 10 ** tokenDecimals) * _costToDollar * amount) = (priceOfOneToken * y * (1 * 10 ** 18 ))
        // amount = (priceOfOneToken * y * 1 * 10 ** 18 ) / (1 * 10 ** tokenDecimals) * _costToDollar)
        // _costToDollar here is the amount in dollars to the power of the aggregator's decimals

        cost =
            (getLatestPrice(priceFeedAddress) * dollarValue * 1e18) /
            ((10 ** _decimals) *
                _costToDollar *
                10 ** AggregatorV3Interface(priceFeedAddress).decimals());

        require(cost > 0, "amount below minimum safe buy");

        fee = feePercentage > 0 && feePercentage != 10000
            ? ((cost * feePercentage) / 10000) - cost
            : 0;
    }
}




/** 
 *  SourceUnit: /Users/michaels/BlockPlot/contracts/BlockPlot/InitialSale.sol
*/
            

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.7;

////import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * ////IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}




/** 
 *  SourceUnit: /Users/michaels/BlockPlot/contracts/BlockPlot/InitialSale.sol
*/
            

// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;

////import "../token/ERC20/extensions/IERC20Metadata.sol";


/** 
 *  SourceUnit: /Users/michaels/BlockPlot/contracts/BlockPlot/InitialSale.sol
*/



pragma solidity ^0.8.7;

/// @author Michael Amadi
/// @title BlockPlot Initial Sale Contract

////import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
////import {BlockPlotERC1155, Ownable} from "./BlockPlotERC1155.sol";
// ////import "@openzeppelin/contracts/access/Ownable.sol";
////import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
////import {PriceConsumerV3} from "./Libraries/PriceConsumerV3.sol";
////import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

////import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract InitialSale is ReentrancyGuard, Ownable, ERC1155Holder {
    using PriceConsumerV3 for uint256;
    using SafeERC20 for IERC20Metadata;

    //contract address of the BlockPlotERC1155 contract
    address immutable assetContract;

    //initial swap fee
    uint256 internal _swapFee = 10030;

    constructor(address _assetContract) {
        assetContract = _assetContract;
    }

    event SwapFeeChanged(uint256 indexed newSwapFee);
    event AssetBought(
        address indexed user,
        uint256 indexed assetId,
        address indexed tokenAddress,
        uint256 amount
    );
    event TokenOracleSet(
        address indexed tokenAddress,
        address indexed priceFeedAddress
    );

    // token to chainlink pricefeed
    mapping(address => address) internal _tokenOracle;

    // balance of a token pair
    mapping(address => mapping(uint256 => uint256)) internal _balanceOfPair;

    // balance of a fees from sales
    mapping(address => mapping(uint256 => uint256)) internal _feesFromPair;

    // fee of individual asset pair to stablecoins when buying
    // if non-zero, it'll be used ahead of swapFee
    mapping(address => mapping(uint256 => uint256)) internal _pairFee;

    function swapFee() public view returns (uint256) {
        return _swapFee;
    }

    function pairFee(
        uint256 assetId,
        address tokenAddress
    ) external view returns (uint256) {
        return _pairFee[tokenAddress][assetId];
    }

    function feesFromPair(
        uint256 assetId,
        address tokenAddress
    ) external view returns (uint256) {
        return _feesFromPair[tokenAddress][assetId];
    }

    function balanceOfPair(
        uint256 assetId,
        address tokenAddress
    ) external view returns (uint256) {
        return _balanceOfPair[tokenAddress][assetId];
    }

    function tokenOracle(address tokenAddress) external view returns (address) {
        return _tokenOracle[tokenAddress];
    }

    function getAssetContract() external view returns (address) {
        return assetContract;
    }

    /// @notice lets owner change the general fee for buying asset, to a @param newSwapFee
    /// @param newSwapFee: new fee to change to
    function changeSwapFee(uint256 newSwapFee) external onlyOwner {
        require(
            newSwapFee > 10000 || newSwapFee == 0,
            "Fee percentage must be above 10000"
        );
        _swapFee = newSwapFee;
        emit SwapFeeChanged(newSwapFee);
    }

    /// @notice lets owner change the fee of pair @param tokenAddress - @param assetId only, to a @param newPairFee
    /// @param tokenAddress: a supported token (token mapped to a non-zero chainlink pricefeed)
    /// @param assetId: asset id of BlockPlot asset to mint
    /// @param newPairFee: new fee to change to
    function changePairFee(
        address tokenAddress,
        uint256 assetId,
        uint256 newPairFee
    ) public onlyOwner {
        require(
            newPairFee > 10000 || newPairFee == 0,
            "Fee percentage must be above 10000"
        );
        _pairFee[tokenAddress][assetId] = newPairFee;
    }

    /// @notice lets owner change the fees of pair @param tokenAddresses - @param assetId only, to a @param newPairFees
    /// @param tokenAddresses: a supported token (token mapped to a non-zero chainlink pricefeed)
    /// @param assetId: asset id of BlockPlot asset to mint
    /// @param newPairFees: new fee to change to
    function changePairFeeBatch(
        address[] calldata tokenAddresses,
        uint256 assetId,
        uint256[] calldata newPairFees
    ) external {
        require(
            tokenAddresses.length == newPairFees.length,
            "arrays of varying lengths"
        );
        for (uint i = 0; i < tokenAddresses.length; i++) {
            changePairFee(tokenAddresses[i], assetId, newPairFees[i]);
        }
    }

    /// @notice maps a stablecoin @param tokenAddress to a chainlink pricefeed @param chainlinkPriceFeed or address (0)
    /// @param tokenAddress: token to map to a chainlink pricefeed
    /// @param chainlinkPriceFeed: a chainlink pricefeed or address(0) to make a tokenAddress unsupported
    function setTokenOracle(
        address tokenAddress,
        address chainlinkPriceFeed
    ) external virtual onlyOwner {
        _tokenOracle[tokenAddress] = chainlinkPriceFeed;
        emit TokenOracleSet(tokenAddress, chainlinkPriceFeed);
    }

    /// @notice allows users buy any amount @param amount of asset @param assetId using a supported token @param token
    /// @notice users can own a max amount of 10% of a particular asset.
    /// @param token: a supported token (token mapped to a non-zero chainlink pricefeed) supporting the IERC20Metadata interface
    /// @param assetId: asset id of BlockPlot asset to mint
    /// @param amount: amount of assets to buy
    function buyAsset(
        IERC20Metadata token,
        uint256 assetId,
        uint256 amount
    ) external nonReentrant {
        (, , , , , uint _costToDollar, , , ) = BlockPlotERC1155(assetContract)
            .idToMetadata(assetId);

        address tokenAddress = address(token);
        address _priceFeed = _tokenOracle[tokenAddress];
        require(_priceFeed != address(0), "Unsupported Token");

        uint256 assetFee = _pairFee[tokenAddress][assetId];

        uint256 feePercentage = assetFee > 0 ? assetFee : _swapFee;

        (uint256 cost, uint256 fee) = amount.costToDollar(
            _costToDollar,
            token.decimals(),
            _priceFeed,
            feePercentage
        );

        uint256 total = cost + fee;

        _balanceOfPair[tokenAddress][assetId] += cost;
        _feesFromPair[tokenAddress][assetId] += (total - cost);

        token.safeTransferFrom(msg.sender, address(this), total);
        emit AssetBought(msg.sender, assetId, tokenAddress, amount);
        BlockPlotERC1155(assetContract).safeTransferFrom(
            address(this),
            msg.sender,
            assetId,
            amount,
            ""
        );
    }

    /// @notice allows asset issuers withdraw proceeds gotten from sale of their asset @param assetId via supported tokens @param token
    /// @notice asset issuers must wait for the initial sale period to be over before withdrawing proceeds
    /// @param token: a supported token (token mapped to a non-zero chainlink pricefeed) supporting the IERC20Metadata interface
    /// @param assetId: asset id of BlockPlot asset to mint
    /// @param amount: amount of @param token to withdraw
    function withdraw(
        IERC20Metadata token,
        uint256 assetId,
        uint256 amount
    ) external nonReentrant {
        (
            ,
            ,
            ,
            ,
            uint initialSalePeriod,
            ,
            ,
            ,
            address trueAssetIssuer
        ) = BlockPlotERC1155(assetContract).idToMetadata(assetId);
        require(
            initialSalePeriod < block.timestamp,
            "Initial sale period is still on"
        );
        require(trueAssetIssuer == msg.sender, "Only asset owner");
        address tokenAddress = address(token);
        require(
            _balanceOfPair[tokenAddress][assetId] <= amount,
            "Insufficient balance"
        );
        token.safeTransfer(msg.sender, amount);
    }

    /// @notice allows the protocol to withdraw proceeds gotten fees from sale of asset @param assetId via supported tokens @param token
    /// @param token: a supported token (token mapped to a non-zero chainlink pricefeed) supporting the IERC20Metadata interface
    /// @param assetId: asset id of BlockPlot asset to mint
    /// @param amount: amount of @param token to withdraw
    function withdrawFees(
        IERC20Metadata token,
        uint256 assetId,
        uint256 amount
    ) external onlyOwner nonReentrant {
        require(
            _feesFromPair[address(token)][assetId] >= amount,
            "Insufficient balance"
        );
        token.safeTransfer(msg.sender, amount);
    }

    modifier onlyAddress0(address from) {
        require(from == address(0), "Can only receive assets via mint");
        _;
    }

    function onERC1155Received(
        address,
        address from,
        uint256,
        uint256,
        bytes memory
    ) public virtual override onlyAddress0(from) returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address from,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override onlyAddress0(from) returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}