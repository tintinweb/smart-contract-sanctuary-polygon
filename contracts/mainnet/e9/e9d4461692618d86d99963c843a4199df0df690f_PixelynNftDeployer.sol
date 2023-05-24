// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface IERC20 {
  /*///////////////////////////////////////////////////////////////
                              EVENTS
  //////////////////////////////////////////////////////////////*/
  event Transfer(address indexed from, address indexed to, uint256 amount);
  event Approval(address indexed owner, address indexed spender, uint256 amount);

  /*///////////////////////////////////////////////////////////////
                              VARIABLES
  //////////////////////////////////////////////////////////////*/
  function name() external view returns (string memory _name);

  function symbol() external view returns (string memory _symbol);

  function decimals() external view returns (uint8 _decimals);

  function totalSupply() external view returns (uint256 _totalSupply);

  function balanceOf(address _account) external view returns (uint256);

  function allowance(address _owner, address _spender) external view returns (uint256);

  function nonces(address _account) external view returns (uint256);

  /*///////////////////////////////////////////////////////////////
                                LOGIC
  //////////////////////////////////////////////////////////////*/
  function approve(address spender, uint256 amount) external returns (bool);

  function transfer(address to, uint256 amount) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external returns (bool);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

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
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
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
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
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
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt
    ) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OperatorFilterer} from "./OperatorFilterer.sol";
import {CANONICAL_CORI_SUBSCRIPTION} from "./lib/Constants.sol";
/**
 * @title  DefaultOperatorFilterer
 * @notice Inherits from OperatorFilterer and automatically subscribes to the default OpenSea subscription.
 * @dev    Please note that if your token contract does not provide an owner with EIP-173, it must provide
 *         administration methods on the contract itself to interact with the registry otherwise the subscription
 *         will be locked to the options set during construction.
 */

abstract contract DefaultOperatorFilterer is OperatorFilterer {
    /// @dev The constructor that is called when the contract is being deployed.
    constructor() OperatorFilterer(CANONICAL_CORI_SUBSCRIPTION, true) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    /**
     * @notice Returns true if operator is not filtered for a given token, either by address or codeHash. Also returns
     *         true if supplied registrant address is not registered.
     */
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);

    /**
     * @notice Registers an address with the registry. May be called by address itself or by EIP-173 owner.
     */
    function register(address registrant) external;

    /**
     * @notice Registers an address with the registry and "subscribes" to another address's filtered operators and codeHashes.
     */
    function registerAndSubscribe(address registrant, address subscription) external;

    /**
     * @notice Registers an address with the registry and copies the filtered operators and codeHashes from another
     *         address without subscribing.
     */
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;

    /**
     * @notice Unregisters an address with the registry and removes its subscription. May be called by address itself or by EIP-173 owner.
     *         Note that this does not remove any filtered addresses or codeHashes.
     *         Also note that any subscriptions to this registrant will still be active and follow the existing filtered addresses and codehashes.
     */
    function unregister(address addr) external;

    /**
     * @notice Update an operator address for a registered address - when filtered is true, the operator is filtered.
     */
    function updateOperator(address registrant, address operator, bool filtered) external;

    /**
     * @notice Update multiple operators for a registered address - when filtered is true, the operators will be filtered. Reverts on duplicates.
     */
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;

    /**
     * @notice Update a codeHash for a registered address - when filtered is true, the codeHash is filtered.
     */
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;

    /**
     * @notice Update multiple codeHashes for a registered address - when filtered is true, the codeHashes will be filtered. Reverts on duplicates.
     */
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;

    /**
     * @notice Subscribe an address to another registrant's filtered operators and codeHashes. Will remove previous
     *         subscription if present.
     *         Note that accounts with subscriptions may go on to subscribe to other accounts - in this case,
     *         subscriptions will not be forwarded. Instead the former subscription's existing entries will still be
     *         used.
     */
    function subscribe(address registrant, address registrantToSubscribe) external;

    /**
     * @notice Unsubscribe an address from its current subscribed registrant, and optionally copy its filtered operators and codeHashes.
     */
    function unsubscribe(address registrant, bool copyExistingEntries) external;

    /**
     * @notice Get the subscription address of a given registrant, if any.
     */
    function subscriptionOf(address addr) external returns (address registrant);

    /**
     * @notice Get the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscribers(address registrant) external returns (address[] memory);

    /**
     * @notice Get the subscriber at a given index in the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscriberAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Copy filtered operators and codeHashes from a different registrantToCopy to addr.
     */
    function copyEntriesOf(address registrant, address registrantToCopy) external;

    /**
     * @notice Returns true if operator is filtered by a given address or its subscription.
     */
    function isOperatorFiltered(address registrant, address operator) external returns (bool);

    /**
     * @notice Returns true if the hash of an address's code is filtered by a given address or its subscription.
     */
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);

    /**
     * @notice Returns true if a codeHash is filtered by a given address or its subscription.
     */
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);

    /**
     * @notice Returns a list of filtered operators for a given address or its subscription.
     */
    function filteredOperators(address addr) external returns (address[] memory);

    /**
     * @notice Returns the set of filtered codeHashes for a given address or its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);

    /**
     * @notice Returns the filtered operator at the given index of the set of filtered operators for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Returns the filtered codeHash at the given index of the list of filtered codeHashes for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);

    /**
     * @notice Returns true if an address has registered
     */
    function isRegistered(address addr) external returns (bool);

    /**
     * @dev Convenience method to compute the code hash of an arbitrary contract
     */
    function codeHashOf(address addr) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";
import {CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS} from "./lib/Constants.sol";
/**
 * @title  OperatorFilterer
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 *         Please note that if your token contract does not provide an owner with EIP-173, it must provide
 *         administration methods on the contract itself to interact with the registry otherwise the subscription
 *         will be locked to the options set during construction.
 */

abstract contract OperatorFilterer {
    /// @dev Emitted when an operator is not allowed.
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry public constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS);

    /// @dev The constructor that is called when the contract is being deployed.
    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (subscribe) {
                OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    OPERATOR_FILTER_REGISTRY.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    OPERATOR_FILTER_REGISTRY.register(address(this));
                }
            }
        }
    }

    /**
     * @dev A helper function to check if an operator is allowed.
     */
    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    /**
     * @dev A helper function to check if an operator approval is allowed.
     */
    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    /**
     * @dev A helper function to check if an operator is allowed.
     */
    function _checkFilterOperator(address operator) internal view virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            // under normal circumstances, this function will revert rather than return false, but inheriting contracts
            // may specify their own OperatorFilterRegistry implementations, which may behave differently
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

address constant CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS = 0x000000000000AAeB6D7670E522A718067333cd4E;
address constant CANONICAL_CORI_SUBSCRIPTION = 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

abstract contract ContextMixin {
    function msgSender() internal view returns (address payable sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {SharedStructs} from '../shared-structs/SharedStructs.sol';
import {IPixelynNftDeployer} from 'interfaces/IPixelynNftDeployer.sol';
import {IERC2981} from 'interfaces/IERC2981.sol';
import {ContextMixin} from './ContextMixin.sol';
import 'operator-filter-registry/DefaultOperatorFilterer.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

contract PixelynNft is
    DefaultOperatorFilterer,
    ReentrancyGuard,
    ContextMixin,
    Ownable,
    IERC165,
    IERC721,
    IERC721Metadata,
    IERC2981
{
    using Address for address;
    using Strings for uint256;

    uint256 constant MAX_BPS = 10_000;

    // the address of the PixelynNftDeployer contract
    address private _pixelynNftDeployer;

    // Token name
    string private _name;
    // Token symbol
    string private _symbol;
    // price to mint
    uint256 private _price;
    // base URI
    string private _baseURI;
    // when the mint starts
    uint256 private _mintStartTimestamp;
    // the max supply of tokens
    uint256 _maxSupply;
    // beneficiaries
    SharedStructs.Beneficiary[] private _beneficiaries;

    // the royality recipient
    address private _royaltyRecipient;
    // the percent of the royalty
    uint256 private _royaltyPercentage;
    // the token id to royalty recipient mapping if a custom royalty recipient is set
    mapping(uint256 => address) private _tokenRoyaltyRecipients;
    // the token id to royalty percentage
    mapping(uint256 => uint256) private _tokenRoyaltyPercentages;

    // kill switch
    bool private _killSwitch;

    // not minted tokens
    mapping(uint256 => uint256) private _unusedTokens;
    // the number of unused tokens left
    uint256 private _unusedTokensLeft;
    // the number of minted tokens
    uint256 private _mintedTokensTotal;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;
    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // allowlist
    mapping(address => uint256) private _allowlist;
    uint256 private _allowlistStartTimestamp;

    /**
     * @dev Constructor function for the PixelynNft contract.
     * Initializes various contract state variables such as name, symbol, price, maxSupply, beneficiaries, royalties, etc.
     * @param __pixelynNftDeployer The address of the contract deployer.
     * @param collectionInitialize A struct containing various collection initialization parameters such as name, symbol, price, maxSupply, beneficiaries, royalties, etc.
     */
    constructor(address __pixelynNftDeployer, SharedStructs.NewCollectionInitialize memory collectionInitialize) {
        _name = collectionInitialize.name;
        _symbol = collectionInitialize.symbol;
        _pixelynNftDeployer = __pixelynNftDeployer;
        _mintStartTimestamp = collectionInitialize.mintStartTimestamp;
        _allowlistStartTimestamp = collectionInitialize.allowlistStartTimestamp;
        _baseURI = collectionInitialize.baseURI;
        _price = collectionInitialize.price;
        _maxSupply = collectionInitialize.maxSupply;
        _unusedTokensLeft = collectionInitialize.maxSupply;

        _setBeneficiaries(collectionInitialize.beneficiaries);

        // royalties can be not set
        if (collectionInitialize.royalties.percentage > 0) {
            _setGlobalRoyalties(collectionInitialize.royalties.to, collectionInitialize.royalties.percentage);
        }

        _transferOwnership(IPixelynNftDeployer(_pixelynNftDeployer).getSuperAdmin());
    }

    /**
     * @dev Throws if called by a account which does not have permission to perform this action
     */
    modifier isPixelynSuperAdmin() {
        require(IPixelynNftDeployer(_pixelynNftDeployer).getSuperAdmin() == _msgSender(), 'not a super admin');
        _;
    }

    /**
     * @dev Throws if called by a account which does not have permission to perform this action
     */
    modifier isPixelynAdmin() {
        require(IPixelynNftDeployer(_pixelynNftDeployer).getAdminState(_msgSender()), 'not a admin');
        _;
    }

    /**
     * @dev Throws if called by a account which does not have permission to perform this action
     */
    modifier isAirdropper() {
        require(IPixelynNftDeployer(_pixelynNftDeployer).getAirdropperState(_msgSender()), 'not a airdropper');
        _;
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }

    /**
     * @dev Sets the kill switch to stop minting
     */
    function setKillSwitch(bool state) external isPixelynAdmin {
        _killSwitch = state;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    /**
     * @dev See {IERC721:-balanceOf}.
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), 'address zero');
        return _balances[owner];
    }

    /**
     * @dev See {IERC721:-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), 'invalid token ID');
        return owner;
    }

    /**
     * @dev See {IERC721:Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Set the name of the collection
     */
    function setName(string memory newName) external isPixelynAdmin {
        _name = newName;
    }

    /**
     * @dev See {IERC721:Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Set the symbol of the collection
     */
    function setSymbol(string memory newSymbol) external isPixelynAdmin {
        _symbol = newSymbol;
    }

    /**
     * @dev Get the pixelyn nft deployer contract address
     */
    function pixelynNftDeployer() public view returns (address) {
        return _pixelynNftDeployer;
    }

    /**
     * @dev Set the pixelyn nft deployer contract address
     */
    function setPixelynNftDeployer(address newPixelynNftDeployer) external isPixelynSuperAdmin {
        _pixelynNftDeployer = newPixelynNftDeployer;
    }

    /**
     * @dev The mint price for the collection
     */
    function mintPrice() public view returns (uint256) {
        return _price;
    }

    /**
     * @dev Set the mint price for the collection
     */
    function setMintPrice(uint256 newMintPrice) external isPixelynAdmin {
        _price = newMintPrice;
    }

    /**
     * @dev Set the mint max supply for the collection
     * please note you can only update this if the mint has not started and
     * nothing has been minted in the collection. This is due to the fact that
     * the token ids are generated based on the max supply and are random.
     * so it is not safe to do so.
     */
    function setMintMaxSupply(uint256 newMintMaxSupply) external isPixelynAdmin {
        require(
            block.timestamp < _mintStartTimestamp && newMintMaxSupply > 0 && totalSupply() == 0
                && newMintMaxSupply >= totalSupply(),
            'Can not set mint max supply'
        );

        _maxSupply = newMintMaxSupply;
        _unusedTokensLeft = newMintMaxSupply;
    }

    /**
     * @dev The max supply of the collection
     */
    function maxMintSupply() public view returns (uint256) {
        return _maxSupply;
    }

    /**
     * @dev The amount of tokens remaining to be minted
     */
    function tokensRemaining() public view returns (uint256) {
        return _unusedTokensLeft;
    }

    /**
     * @dev The mint start timestamp for the collection
     */
    function mintStartTimestamp() public view returns (uint256) {
        return _mintStartTimestamp;
    }

    /**
     * @dev Set the mint start timestamp for the collection
     */
    function setMintStartTimestamp(uint256 newMintStartTimestamp) external isPixelynAdmin {
        _mintStartTimestamp = newMintStartTimestamp;
    }

    /**
     * @dev See {IERC721:Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = this.getBaseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    /**
     * @dev Get the base URI for the collection
     */
    function getBaseURI() external view returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev Set the base URI for the collection
     */
    function setBaseURI(string memory newBaseURI) external isPixelynAdmin {
        _baseURI = newBaseURI;
    }

    /**
     * @dev Get the total supply of the collection
     */
    function totalSupply() public view returns (uint256) {
        return _mintedTokensTotal;
    }

    /**
     * @dev See {IERC721:-approve}.
     */
    function approve(address operator, uint256 tokenId) public virtual override onlyAllowedOperatorApproval(operator) {
        address owner = PixelynNft.ownerOf(tokenId);
        require(operator != owner, 'approval to current owner');

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            'approve caller is not token owner or approved for all'
        );

        _approve(operator, tokenId);
    }

    /**
     * @dev See {IERC721:-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721:-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
        onlyAllowedOperatorApproval(operator)
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721:-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (operator == address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE)) return true;

        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721:-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId)
        public
        virtual
        override
        onlyAllowedOperator(from)
    {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), 'caller is not token owner or approved');

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721:-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        virtual
        override
        onlyAllowedOperator(from)
    {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721:-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        virtual
        override
        onlyAllowedOperator(from)
    {
        require(_isApprovedOrOwner(_msgSender(), tokenId), 'caller is not token owner or approved');
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IPixelynNft:Receiver-onPixelynNft:Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), 'transfer to non ERC721Receiver implementer');
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted
     * and stop existing when they are burned
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = PixelynNft.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev The allowlist start timestamp for the collection
     */
    function allowlistStartTimestamp() public view returns (uint256) {
        return _allowlistStartTimestamp;
    }

    /**
     * @dev Set the allowlist start timestamp
     */
    function setAllowlistStartTimestamp(uint256 _timestamp) external isPixelynAdmin {
        require(_timestamp <= _mintStartTimestamp, 'timestamp higher than mint timestamp');
        _allowlistStartTimestamp = _timestamp;
    }

    /**
     * @dev Add addresses to the allowlist
     */
    function addToAllowlist(SharedStructs.AllowList[] memory allowList) external isAirdropper {
        for (uint256 i = 0; i < allowList.length; i++) {
            SharedStructs.AllowList memory item = allowList[i];
            _allowlist[item.account] = item.allowance;
        }
    }

    /**
     * @dev Remove addresses from the allowlist
     */
    function removeFromAllowlist(address[] memory _addresses) external isAirdropper {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _allowlist[_addresses[i]] = 0;
        }
    }

    /**
     * @dev This internal function returns a random and unused token ID for minting.
     * It uses keccak256 hash function with some arbitrary parameters to generate a random index.
     * The generated index is then used to retrieve the corresponding token ID from the list of unused tokens.
     * @param to The address of the recipient of the minted token.
     * @param unusedTokensLeft The number of unused tokens left for minting.
     * @return The random and unused token ID for minting.
     */
    function _getRandomMintingTokenId(address to, uint256 unusedTokensLeft) internal returns (uint256) {
        return _getUnusedTokenAtIndex(
            uint256(
                keccak256(
                    // good enough randomness for this use case!
                    abi.encode(
                        to,
                        tx.gasprice,
                        address(this),
                        unusedTokensLeft,
                        blockhash(block.number - 1),
                        block.timestamp,
                        block.number,
                        block.coinbase
                    )
                )
            ) % unusedTokensLeft,
            unusedTokensLeft
        );
    }

    /**
     * @dev This internal function retrieves the token ID at the specified index from the list of unused tokens.
     * If the value at the specified index is zero, the function returns the index itself as the token ID.
     * The function also updates the list of unused tokens by swapping the value at the specified index with the last unused token.
     * @param indexToUse The index of the token ID to retrieve from the list of unused tokens.
     * @param unusedTokensLeft The number of unused tokens left for minting.
     * @return The token ID at the specified index or the index itself if the value at the specified index is zero.
     */
    function _getUnusedTokenAtIndex(uint256 indexToUse, uint256 unusedTokensLeft) internal returns (uint256) {
        // Retrieve the value at the index in the _unusedTokens mapping
        uint256 valAtIndex = _unusedTokens[indexToUse];
        // If the value at the index is zero, use the index itself as the token ID, otherwise use the value at the index
        uint256 result = valAtIndex == 0 ? indexToUse : valAtIndex;

        // Calculate the index of the last unused token
        uint256 lastIndex = unusedTokensLeft - 1;
        // Retrieve the value of the last unused token in the _unusedTokens mapping
        uint256 lastValInArray = _unusedTokens[lastIndex];

        // If the index to use is not the last index, update the value at the index with the last unused token value or the lastIndex itself if the last unused token value is zero
        if (indexToUse != lastIndex) _unusedTokens[indexToUse] = lastValInArray == 0 ? lastIndex : lastValInArray;

        // If the last unused token value is not zero, delete the value at the lastIndex in the _unusedTokens mapping
        if (lastValInArray != 0) delete _unusedTokens[lastIndex];

        return result;
    }

    /**
     * @dev reserves `index` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `index` the token index to reserve
     *
     * @param to The address to mint the token to.
     * @param index The token index to reserve.
     */
    function reserve(address to, uint256 index) public isPixelynAdmin {
        require(to != address(0) && _unusedTokensLeft > 0, 'Invalid address or no tokens left for minting');

        uint256 tokenId = _getUnusedTokenAtIndex(index, _unusedTokensLeft);
        --_unusedTokensLeft;

        _mint(to, tokenId);
        _balances[to]++;
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` must not exist.
     */
    function _mint(address to, uint256 tokenId) private {
        ++_mintedTokensTotal;

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Split the payment between the beneficiaries
     */
    function _splitPayments() private {
        SharedStructs.Beneficiary[] memory beneficiaries = _beneficiaries;
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            SharedStructs.Beneficiary memory beneficiary = beneficiaries[i];
            uint256 amount = (msg.value * beneficiary.percentage) / 10_000;
            payable(beneficiary.to).transfer(amount);
        }
    }

    /**
     * @dev Public mint started
     */
    function publicMintStarted() public view returns (bool) {
        return block.timestamp >= _mintStartTimestamp;
    }

    /**
     * @dev Allowlist mint started
     */
    function allowlistMintStarted() public view returns (bool) {
        return _allowlistStartTimestamp > 0 && block.timestamp >= _allowlistStartTimestamp;
    }

    /**
     * @dev In allowlist period
     */
    function inAllowlistPeriod() public view returns (bool) {
        return _allowlistStartTimestamp > 0 && block.timestamp >= _allowlistStartTimestamp
            && block.timestamp < _mintStartTimestamp;
    }

    /**
     * @dev In mintable period
     */
    function inMintablePeriod() public view returns (bool) {
        return allowlistMintStarted() || publicMintStarted();
    }

    /**
     * @dev Used for paper integration
     */
    function checkClaimEligibility(address to, uint256 numToMint) external view returns (string memory) {
        if (
            !inMintablePeriod() || _killSwitch || to == address(0) || numToMint <= 0 || _unusedTokensLeft < numToMint
                || (inAllowlistPeriod() && _allowlist[to] < numToMint)
        ) return 'Can not mint';

        return '';
    }

    /**
     * @dev mint random token to `to`.
     *
     * Requirements:
     *
     * - `to` must exist.
     * - `numToMint` must be greater than 0.
     *
     */
    function mintRandom(address to, uint256 numToMint) public payable nonReentrant {
        require(inMintablePeriod(), 'mint has not started yet');
        require(!_killSwitch, 'minting is paused');
        require(to != address(0), 'mint to the zero address');
        require(numToMint > 0, 'need to mint at least one token');
        require(_unusedTokensLeft >= numToMint, 'minting more tokens than supply');
        require(msg.value == _price * numToMint, 'Did not send correct amount of funds');

        if (inAllowlistPeriod()) {
            require(_allowlist[to] >= numToMint, 'sender cannot mint more than allowed');
            _allowlist[to] -= numToMint;
        }

        // Split the payments
        _splitPayments();

        // Mint the tokens
        _mintRandom(to, numToMint);
    }

    /**
     * @dev Mint `numToMint` random tokens and assign them to `to`.
     * @param to The address to assign the minted tokens to.
     * @param numToMint The number of tokens to mint.
     */
    function _mintRandom(address to, uint256 numToMint) private {
        uint256 unusedTokensLeft = _unusedTokensLeft;
        for (uint256 i; i < numToMint; ++i) {
            uint256 tokenId = _getRandomMintingTokenId(to, unusedTokensLeft);

            _mint(to, tokenId);

            --unusedTokensLeft;
        }

        _unusedTokensLeft = unusedTokensLeft;
        _balances[to] += numToMint;
    }

    /**
     * @dev airdrops NFTs to addresses.
     * This still uses mint random to keep it fair.
     *
     * Requirements:
     *
     * - `recipients` must exist.
     *
     */
    function airdrop(address[] calldata recipients) public isAirdropper {
        require(
            recipients.length > 0 && _unusedTokensLeft >= recipients.length,
            'Empty recipient list or minting more tokens than supply'
        );

        for (uint256 i; i < recipients.length; ++i) {
            _mintRandom(recipients[i], 1);
        }
    }

    /**
     * @dev Set the beneficiaries for the NFT minting payout.
     * @param beneficiaries An array of `SharedStructs.Beneficiary` structs representing the new beneficiaries.
     */
    function _setBeneficiaries(SharedStructs.Beneficiary[] memory beneficiaries) internal {
        // Ensure that the number of beneficiaries is valid
        require(beneficiaries.length > 0 && beneficiaries.length < 4, 'invalid number of beneficiaries');

        // Clear the existing beneficiaries
        while (_beneficiaries.length > 0) _beneficiaries.pop();

        // Add the new beneficiaries and validate their percentages
        uint256 totalPercentage;
        for (uint256 i; i < beneficiaries.length; i++) {
            SharedStructs.Beneficiary memory beneficiary = beneficiaries[i];
            require(beneficiary.percentage <= MAX_BPS, 'beneficiary percentage is too high');
            _beneficiaries.push(beneficiary);
            totalPercentage += beneficiary.percentage;
        }

        // Ensure that the total percentage adds up to 100
        require(totalPercentage == MAX_BPS, 'total percentage must be 100');
    }

    /**
     * @dev Set the beneficiaries for the NFT minting payout.
     * @param beneficiaries An array of `SharedStructs.Beneficiary` structs representing the new beneficiaries.
     */
    function setBeneficiaries(SharedStructs.Beneficiary[] memory beneficiaries) external isPixelynAdmin {
        _setBeneficiaries(beneficiaries);
    }

    /**
     * @dev Sets the global royalties for the contract, meaning if no token id is overriden
     * this will be the default royalty.
     */
    function _setGlobalRoyalties(address newRecipient, uint256 newPercentage) internal {
        require(newRecipient != address(0), 'royalties recipient is the zero address');
        require(
            newPercentage <= MAX_BPS && newPercentage > 0,
            'royalty must be less than or equal to 100% and greater than 0%'
        );
        _royaltyRecipient = newRecipient;
        _royaltyPercentage = newPercentage;
    }

    /**
     * @dev Sets the global royalties for the contract, meaning if no token id is overriden
     * this will be the default royalty.
     */
    function setGlobalRoyalties(address newRecipient, uint256 percent) external isPixelynAdmin {
        _setGlobalRoyalties(newRecipient, percent);
    }

    /**
     * @dev Sets the royalties for a specific token id.
     */
    function setTokenRoyalty(uint256 tokenId, address receiver, uint256 royaltyPercentage) external isPixelynAdmin {
        require(receiver != address(0), 'royalties new recipient is the zero address');
        require(royaltyPercentage <= MAX_BPS, 'token royalty must be higher then 100%');
        _tokenRoyaltyRecipients[tokenId] = receiver;
        _tokenRoyaltyPercentages[tokenId] = royaltyPercentage;
    }

    /**
     * @dev EIP2981 royalties implementation.
     * For now this will always return to the defined royalty recipient.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), 'ERC2981Royalties: Token does not exist');

        uint256 royaltyPercentage = _royaltyPercentage;
        address royaltyRecipient = _royaltyRecipient;

        // Check if the token has a royalty override
        if (_tokenRoyaltyPercentages[tokenId] > 0) {
            royaltyPercentage = _tokenRoyaltyPercentages[tokenId];
            royaltyRecipient = _tokenRoyaltyRecipients[tokenId];
        }

        if (royaltyPercentage > 0) {
            royaltyAmount = (salePrice * royaltyPercentage) / MAX_BPS;
            receiver = royaltyRecipient;
        } else {
            royaltyAmount = 0;
            receiver = address(0);
        }
        return (receiver, royaltyAmount);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(PixelynNft.ownerOf(tokenId) == from, 'transfer from incorrect owner');
        require(to != address(0), 'transfer to the zero address');

        require(PixelynNft.ownerOf(tokenId) == from, 'transfer from incorrect owner');

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(PixelynNft.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, 'approve to caller');
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), 'invalid token ID');
    }

    /**
     * @dev Internal function to invoke {IPixelynNft:Receiver-onPixelynNft:Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data)
        private
        returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert('transfer to non ERC721Receiver implementer');
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {Clones} from '@openzeppelin/contracts/proxy/Clones.sol';
import {Context} from '@openzeppelin/contracts/utils/Context.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {IPixelynNftDeployer} from 'interfaces/IPixelynNftDeployer.sol';
import {SharedStructs} from '../shared-structs/SharedStructs.sol';
import {PixelynNft} from './PixelynNft.sol';

contract PixelynNftDeployer is IPixelynNftDeployer, Context, Ownable {
    mapping(address => bool) private _allAirdroppers;
    mapping(address => bool) private _admins;

    address[] private _allDeployedContracts;

    /**
     * @dev Throws if called by a account which is not an allowed airdroper
     */
    modifier isAirdropper() {
        require(_allAirdroppers[_msgSender()], 'not an airdropper');
        _;
    }

    /**
     * @dev Throws if called by a account which is not an allowed admin
     */
    modifier isAdmin() {
        require(_admins[_msgSender()], 'not an admin');
        _;
    }

    /**
     * @dev Throws if called by a account which is not an allowed admin or airdropper
     */
    modifier isAdminOrSuperAdmin() {
        require(_admins[_msgSender()] || this.owner() == _msgSender(), 'not a admin or super admin');
        _;
    }

    /// @inheritdoc IPixelynNftDeployer
    function getSuperAdmin() external view returns (address) {
        return this.owner();
    }

    /// @inheritdoc IPixelynNftDeployer
    function deployNewCollection(SharedStructs.NewCollectionInitialize memory collectionInitialize)
        external
        isAdmin
        returns (address)
    {
        PixelynNft collect = new PixelynNft(address(this), collectionInitialize);
        address collectionNft = address(collect);

        _allDeployedContracts.push(collectionNft);

        emit NewCollectionDeployed(collectionNft, collectionInitialize.name, _msgSender());

        return collectionNft;
    }

    /// @inheritdoc IPixelynNftDeployer
    function allDeployedCollections() external view returns (address[] memory) {
        return _allDeployedContracts;
    }

    /// @inheritdoc IPixelynNftDeployer
    function setAirdropperState(address airdropper, bool allowed) external isAdminOrSuperAdmin {
        _allAirdroppers[airdropper] = allowed;

        emit AirdropperStateChanged(airdropper, allowed);
    }

    /// @inheritdoc IPixelynNftDeployer
    function getAirdropperState(address airdropper) public view returns (bool) {
        return _allAirdroppers[airdropper];
    }

    /// @inheritdoc IPixelynNftDeployer
    function addAdmin(address admin) external isAdminOrSuperAdmin {
        _admins[admin] = true;

        emit AdminStateChanged(admin, true);
    }

    /// @inheritdoc IPixelynNftDeployer
    function removeAdmin(address admin) external onlyOwner {
        _admins[admin] = false;

        emit AdminStateChanged(admin, false);
    }

    /// @inheritdoc IPixelynNftDeployer
    function getAdminState(address admin) public view returns (bool) {
        return _admins[admin];
    }

    /// @inheritdoc IPixelynNftDeployer
    function getRoles(address[] memory addresses) external view returns (SharedStructs.Roles[] memory) {
        SharedStructs.Roles[] memory roles = new SharedStructs.Roles[](addresses.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            address _address = addresses[i];
            SharedStructs.Roles memory hasRole = SharedStructs.Roles({
                user: _address,
                isSuperAdmin: this.owner() == _address,
                isAirdropper: getAirdropperState(_address),
                isAdmin: getAdminState(_address)
            });
            roles[i] = hasRole;
        }

        return roles;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

interface IERC2981 is IERC165 {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    /// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
    /// bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    /// _registerInterface(_INTERFACE_ID_ERC2981);

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {IERC20} from 'isolmate/interfaces/tokens/IERC20.sol';
import {SharedStructs} from '../shared-structs/SharedStructs.sol';

/**
 * @title Pixelyn Nft Deployer Contract
 * @notice This is the contract that deploys the nft contracts
 */
interface IPixelynNftDeployer {
    ///////////////////////////////////////////////////////// EVENTS
    /**
     * @notice The airdrop state has changed
     * @param _airdropper The airdropper address
     * @param _allowed  Whether the deployer is allowed to deploy
     */
    event AirdropperStateChanged(address indexed _airdropper, bool _allowed);

    /**
     * @notice The admin state has changed
     * @param _admin The admin address
     * @param _status  Whether the admin is an admin or not
     */
    event AdminStateChanged(address indexed _admin, bool _status);

    /**
     * @notice The admin state has changed
     * @param _collectionNft The NFT address of the collection
     * @param _collectionName The name of the collection
     * @param _deployer Who deployed it
     */
    event NewCollectionDeployed(address indexed _collectionNft, string _collectionName, address indexed _deployer);

    ///////////////////////////////////////////////////////// ERRORS

    ////////////////////////////////////////////////////// LOGIC
    /**
     * Deploy the nft contract
     */
    function deployNewCollection(SharedStructs.NewCollectionInitialize memory collectionInitialize)
        external
        returns (address);

    /**
     * Returns all deployed collections
     */
    function allDeployedCollections() external view returns (address[] memory);

    /**
     * Set the airdropper state for an address
     */
    function setAirdropperState(address airdropper, bool allowed) external;

    /**
     * Get the airdropper state
     */
    function getAirdropperState(address airdropper) external view returns (bool);

    /**
     * Get the super admin
     */
    function getSuperAdmin() external view returns (address);

    /**
     * Add a new admin
     */
    function addAdmin(address admin) external;

    /**
     * Remove an admin
     */
    function removeAdmin(address admin) external;

    /**
     * Get the admin state
     */
    function getAdminState(address deployer) external view returns (bool);

    /**
     * Get the admin state
     */
    function getRoles(address[] memory addresses) external view returns (SharedStructs.Roles[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

/**
 * @title SharedStructs
 *
 * @notice A standard library of shared structs used throughout the codebase.
 */
library SharedStructs {
    struct Royality {
        address to;
        // * by 1e2 aka 10.05 = 1005
        uint256 percentage;
    }

    struct Beneficiary {
        address to;
        // * by 1e2 aka 10.05 = 1005
        uint256 percentage;
    }

    struct NewCollectionInitialize {
        string name;
        string symbol;
        string baseURI;
        uint256 price;
        uint256 maxSupply;
        uint256 mintStartTimestamp;
        uint256 allowlistStartTimestamp;
        SharedStructs.Beneficiary[] beneficiaries;
        SharedStructs.Royality royalties;
    }

    struct Part {
        address payable account;
        uint96 value;
    }

    struct Roles {
        address user;
        bool isSuperAdmin;
        bool isAirdropper;
        bool isAdmin;
    }

    struct AllowList {
        address account;
        uint256 allowance;
    }
}