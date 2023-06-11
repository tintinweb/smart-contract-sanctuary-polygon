/**
 *Submitted for verification at polygonscan.com on 2023-06-11
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/interfaces/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;


// File: @openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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

// File: @openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
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

// File: @openzeppelin/contracts-upgradeable/interfaces/IERC721EnumerableUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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

// File: @openzeppelin/contracts/interfaces/IERC1155.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;


// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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

// File: @openzeppelin/contracts/interfaces/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;


// File: finaljelly.sol
    // SPDX-License-Identifier: MIT

    pragma solidity ^0.8.17;

    /// @title The Alpha Jelly staking contract
    /// @author Roland Strasser
    /// @notice No warranties or whatsoever are taken by the author.
    /// @notice Usage of this contract in a productive environment is on your own risk







    interface DropERC1155 {
        function nextTokenIdToMint() external view returns(uint256) ;
    }

    contract TheAlphaJellyStaking is Ownable, ReentrancyGuard {

        /// @notice base contracts
        address public nftA = 0x83b8D9070bFD74eed1b70eB0539b45668cA31724;
        address public nftB = 0x070f195b6aa5db85C9967B0f1A15d6Ca1dE2bdd1;
        address public nftC = 0xF1c78Da518b2D2bd3EDe24446260CA5D4E4a340A;
        address public token = 0xbb71538BB1db7c2C8C5bD78D1b443e440b697d66;

        /// @notice stake infos nftA
        struct StakesA {
            uint256 tokenId;
            address holder;
            uint256 nftStaked;
            uint256 claimed;
            bool staked;
        }
        mapping(uint256 => StakesA) public stakeDataA;
        mapping(address => uint256) public stakeApWallet;
        uint256 public totalAstaked = 0;
        uint256 public aCounter = 1;

        /// @notice stake infos nftB
        struct StakesB {
            uint256 tokenId;
            address holder;
            uint256 nftStaked;
            uint256 claimed;
            bool staked;
        }
        mapping(uint256 => StakesB) public stakeDataB;
        mapping(address => uint256) public stakeBpWallet;
        uint256 public totalBstaked = 0;
        uint256 public bCounter = 1;

        /// @notice stake infos nftC
        struct StakesC {
            uint256 tokenId;
            uint256 amount;
            address holder;
        }
        mapping(uint256 => StakesC) public stakeDataC;
        mapping(address => uint256) public stakeCCounter;
        uint256 public cCounter = 1;

        /// @notice staking params
        uint256 nftAReward = 5 ether; /// counts as daily rewards
        uint256 nftBReward = 2 ether; /// counts as daily rewards
        uint256 public totalRewards = 0;
        uint256 nftCBonus = 1; /// counts as percent per staked NFT C
        uint256 nftCMaxBonus = 50;
        uint256 rewardPeriod = 86400; /// used to calculate days form timestamp
        uint256 public rewardTime = 14; /// in days
        uint256 public batchStakeLimit = 20;

        /// @notice constructor
        constructor() {
            
        }

        /// @notice stake all my nfts
        function stakeAll() public nonReentrant {
            uint256 amount = IERC721(nftA).balanceOf(msg.sender);
            uint256 stakeLimit = batchStakeLimit;
            if(amount > 0) {
                for(uint256 i = 0; i < amount; i++) {
                    try IERC721EnumerableUpgradeable(nftA).tokenOfOwnerByIndex(msg.sender, i) returns(uint256 _tokenIdA) {
                        if(_tokenIdA == 9999) {
                            break;
                        }
                        stakeNFT(nftA, _tokenIdA);
                    } catch Error(string memory) {
                        continue;
                    }
                    stakeLimit--;
                    if(stakeLimit == 0) {
                        break;
                    }                
                }
            }
            
            amount = IERC721(nftB).balanceOf(msg.sender);
            if(amount > 0) {
                for(uint256 j = 0; j < amount; j++) {
                    try IERC721EnumerableUpgradeable(nftB).tokenOfOwnerByIndex(msg.sender, j) returns(uint256 _tokenIdB) {
                        if(_tokenIdB == 9999) {
                            break;
                        }
                        stakeNFT(nftB, _tokenIdB);
                    } catch Error(string memory) {
                        continue;
                    }    
                    stakeLimit--;
                    if(stakeLimit == 0) {
                        break;
                    }                         
                }
            }

            uint256 maxC = DropERC1155(nftC).nextTokenIdToMint();
            for(uint256 i = 0; i < maxC; i++) {
                amount = IERC1155(nftC).balanceOf(msg.sender, i);
                if(amount > 0) {
                    stakeCollectible(i, amount);
                }
                stakeLimit--;
                if(stakeLimit == 0) {
                    break;
                }       
            }
        }

        /// @notice stake all my nfts
        function unstakeAll() public nonReentrant {
            for(uint256 i = 1; i < aCounter; i++) {
                if(stakeDataA[i].holder == msg.sender && stakeDataA[i].staked) {
                    unstakeNFT(nftA, stakeDataA[i].tokenId);
                }
            }

            for(uint256 i = 1; i < bCounter; i++) {
                if(stakeDataB[i].holder == msg.sender && stakeDataB[i].staked) {
                    unstakeNFT(nftB, stakeDataB[i].tokenId);
                }
            }

            for(uint256 i = 1; i < cCounter; i++) {
                if(stakeDataC[i].holder == msg.sender) {
                    unstakeCollectible(stakeDataC[i].tokenId, stakeDataC[i].amount);
                }
            }
        }

        /// @notice claim all rewards
        function claimAll() public nonReentrant {
            for(uint256 i = 1; i < aCounter; i++) {
                if(stakeDataA[i].holder == msg.sender && stakeDataA[i].staked) {
                    claim(nftA, stakeDataA[i].tokenId);
                }
            }

            for(uint256 i = 1; i < bCounter; i++) {
                if(stakeDataB[i].holder == msg.sender && stakeDataB[i].staked) {
                    claim(nftB, stakeDataB[i].tokenId);
                }
            }
        }

        /// @notice stake nft
        /// @param _contract to be staked from
        /// @param _tokenId to be staked
        function stakeNFT(address _contract, uint256 _tokenId) public {
            require(_contract == nftA || _contract == nftB, "Token contract not valid for staking");
            IERC721 nft;
            uint256 index;
            if(_contract == nftA) {
                nft = IERC721(nftA);
                index = getAIndex(_tokenId);
                require(!stakeDataA[index].staked, "NFT already staked error");
                index = aCounter;
            } else if (_contract == nftB) {
                nft = IERC721(nftB);
                index = getAIndex(_tokenId);
                require(!stakeDataB[index].staked, "NFT already staked error");
                index = bCounter;
            }

            /// @notice check ofnwership and approval
            require(nft.ownerOf(_tokenId) == msg.sender, "You do not own this NFT");

            /// @notice save nft data for stake
            if(_contract == nftA) {
                stakeDataA[index].tokenId = _tokenId;
                stakeDataA[index].holder = msg.sender;
                stakeDataA[index].nftStaked = block.timestamp;
                stakeDataA[index].claimed = block.timestamp;
                stakeDataA[index].staked = true;
                stakeApWallet[msg.sender]++;
                totalAstaked++;
                aCounter++;
            } else if (_contract == nftB) {
                stakeDataB[index].tokenId = _tokenId;
                stakeDataB[index].holder = msg.sender;
                stakeDataB[index].nftStaked = block.timestamp;
                stakeDataB[index].claimed = block.timestamp;
                stakeDataB[index].staked = true;
                stakeBpWallet[msg.sender]++;
                totalBstaked++;
                bCounter++;
            }
            
            /// @notice transfer nft to contract
            nft.transferFrom(msg.sender, address(this), _tokenId);
        }

        /// @notice unstake nft
        /// @param _contract to be unstaked from
        /// @param _tokenId to be unsatkedstaked
        function unstakeNFT(address _contract, uint256 _tokenId) public {
            require(_contract == nftA || _contract == nftB, "Token contract not valid for staking");
            IERC721 nft;
            uint256 index = 0;
            if(_contract == nftA) {
                nft = IERC721(nftA);
                index = getAIndex(_tokenId);
                require(stakeDataA[index].holder == msg.sender, "You do not own this NFT");
            } else if (_contract == nftB) {
                nft = IERC721(nftB);
                index = getBIndex(_tokenId);
                require(stakeDataB[index].holder == msg.sender, "You do not own this NFT");
            }

            claim(_contract, _tokenId);

            /// @notice clear stake data
            if(_contract == nftA) {
                stakeDataA[index].tokenId = 0;
                stakeDataA[index].holder = address(0);
                stakeDataA[index].nftStaked = 0;
                stakeDataA[index].claimed = 0;
                stakeDataA[index].staked = false;
                stakeApWallet[msg.sender]--;
                totalAstaked--;
            } else if (_contract == nftB) {
                stakeDataB[index].tokenId = 0;
                stakeDataB[index].holder = address(0);
                stakeDataB[index].nftStaked = 0;
                stakeDataB[index].claimed = 0;
                stakeDataB[index].staked = false;
                stakeBpWallet[msg.sender]--;
                totalBstaked--;
            }

            /// @notice transfer nft to contract
            nft.transferFrom(address(this), msg.sender, _tokenId);
        }

        /// @notice stake nftC
        /// @param _tokenId to be staked
        /// @param _amount to be staked
        function stakeCollectible(uint256 _tokenId, uint256 _amount) public {
            require(IERC1155(nftC).balanceOf(msg.sender, _tokenId) >= _amount, "To less tokens in your ownership");
            uint256 counter = cCounter;
            for(uint256 i = 0; i <= cCounter; i++) {
                if(stakeDataC[i].tokenId == _tokenId && stakeDataC[i].holder == msg.sender) {
                    counter = i;
                    break;
                }
            }
            stakeDataC[counter].tokenId = _tokenId;
            stakeDataC[counter].amount += _amount;
            stakeDataC[counter].holder = msg.sender;
            
            IERC1155(nftC).safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "");

            if(counter == cCounter) {
                stakeCCounter[msg.sender]++;
                cCounter++;
            }
        }

        /// @notice unstake nftC
        /// @param _tokenId to be unstaked
        /// @param _amount to be unstaked
        function unstakeCollectible(uint256 _tokenId, uint256 _amount) public {
            uint256 counter = 0;
            bool found = false;
            for(uint256 i = 0; i <= cCounter; i++) {
                if(stakeDataC[i].tokenId == _tokenId && stakeDataC[i].holder == msg.sender) {
                    counter = i;
                    found = true;
                    break;
                }
            }
            require(found, "No stakes found!");
            require(stakeDataC[counter].amount >= _amount, "Unstake amount exceeds staked amount!");

            stakeDataC[counter].amount -= _amount;
            if(stakeDataC[counter].amount == 0) {
                stakeCCounter[msg.sender] -= _amount;
            }
            
            IERC1155(nftC).safeTransferFrom(address(this), msg.sender, _tokenId, _amount, "");
        }

        /// @notice claim rewards
        /// @param _contract to be claimed from
        /// @param _tokenId to be claimed from
        function claim(address _contract, uint256 _tokenId) public {
            require(_contract == nftA || _contract == nftB, "Token contract not valid for staking");
            uint256 index = 0;
            if(_contract == nftA) {
                index = getAIndex(_tokenId);
                require(stakeDataA[index].holder == msg.sender, "You do not own this NFT");
            } else if (_contract == nftB) {
                index = getBIndex(_tokenId);
                require(stakeDataB[index].holder == msg.sender, "You do not own this NFT");
            }

            uint256 reward = getRewards(_contract, _tokenId);
            if(IERC20(token).balanceOf(address(this)) >= reward) {
                if(_contract == nftA) {
                    stakeDataA[index].claimed = block.timestamp;
                } else if (_contract == nftB) {
                    stakeDataB[index].claimed = block.timestamp;
                }
                IERC20(token).transfer(msg.sender, reward);
            }

            totalRewards += reward;
        }

        /// @notice calculates rewards per nft
        /// @param _contract to be claimed from
        /// @param _tokenId to be claimed from
        function getRewards(address _contract, uint256 _tokenId) public view returns(uint256){
            uint256 compDays = 0;
            uint256 reward = 0;
            uint256 bonus = 0;
            uint256 index = 0;
            if(_contract == nftA) {
                index = getAIndex(_tokenId);
                if(stakeDataA[index].staked) {
                    compDays = (block.timestamp - stakeDataA[index].claimed) / rewardPeriod;
                    if(compDays >= rewardTime) {
                        compDays = rewardTime;
                    }
                    reward = compDays * nftAReward;
                }
            } else if (_contract == nftB) {
                index = getBIndex(_tokenId);
                if(stakeDataB[index].staked) {
                    compDays = (block.timestamp - stakeDataB[index].claimed) / rewardPeriod;
                    if(compDays >= rewardTime) {
                        compDays = rewardTime;
                    }
                    reward = compDays * nftBReward;
                }
            }

            /// @notice get bonus
            if(stakeCCounter[msg.sender] >= 0) {
                bonus = stakeCCounter[msg.sender] * nftCBonus;
                if(bonus > nftCMaxBonus) {
                    bonus = nftCMaxBonus;
                }
                reward = reward + reward * bonus / 100;
            }

            return reward;
        }

        /// @notice returns index of nftA
        /// @param _tokenId to be searched
        function getAIndex(uint256 _tokenId) public view returns(uint256) {
            uint256 index = 0;
            for(uint256 i = 1; i < aCounter; i++) {
                if(stakeDataA[i].tokenId == _tokenId && stakeDataA[i].staked) {
                    index = i;
                    break;
                }
            }
            return index;
        }

        /// @notice returns index of nftB
        /// @param _tokenId to be searched
        function getBIndex(uint256 _tokenId) public view returns(uint256) {
            uint256 index = 0;
            for(uint256 i = 1; i < bCounter; i++) {
                if(stakeDataB[i].tokenId == _tokenId && stakeDataB[i].staked) {
                    index = i;
                    break;
                }
            }
            return index;
        }

        /// @notice returns all indexes of nftA of address
        /// @param _wallet to be check
        function getNftAofWallet(address _wallet) public view returns(uint256[] memory) {
            uint256[] memory returner = new uint256[](stakeApWallet[_wallet]);
            uint256 j = 0;
            for(uint256 i = 1; i < aCounter; i++) {
                if(stakeDataA[i].holder == _wallet && stakeDataA[i].staked) {
                    returner[j] = i;
                    j++;
                }
            }
            return returner;
        }

        /// @notice returns all indexes of nftC of address
        /// @param _wallet to be check
        function getNftCofWallet(address _wallet) public view returns(uint256[] memory) {
            uint256[] memory returner = new uint256[](stakeCCounter[_wallet]);
            uint256 j = 0;
            for(uint256 i = 1; i < cCounter; i++) {
                if(stakeDataC[i].holder == _wallet && stakeDataC[i].amount > 0) {
                    returner[j] = i;
                    j++;
                }
            }
            return returner;
        }

        /// @notice returns all indexes of nftB of address
        /// @param _wallet to be check
        function getNftBofWallet(address _wallet) public view returns(uint256[] memory) {
            uint256[] memory returner = new uint256[](stakeBpWallet[_wallet]);
            uint256 j = 0;
            for(uint256 i = 1; i < bCounter; i++) {
                if(stakeDataB[i].holder == _wallet && stakeDataB[i].staked) {
                    returner[j] = i;
                    j++;
                }
            }
            return returner;
        }

        /// @notice onlyOwner functions

        /// @notice update nftA reward
        /// @param _newReward in ether WEI
        function updRewardA(uint256 _newReward) public onlyOwner {
            nftAReward = _newReward;
        }

        /// @notice update nftB reward
        /// @param _newReward in ether WEI
        function updRewardB(uint256 _newReward) public onlyOwner {
            nftBReward = _newReward;
        }

        /// @notice update nftC bonus
        /// @param _newBonus in 
        function updRewardC(uint256 _newBonus) public onlyOwner {
            nftCBonus = _newBonus;
        }

        /// @notice update nftC max bonus
        /// @param _newMax in 
        function updnftCMaxBonus(uint256 _newMax) public onlyOwner {
            nftCMaxBonus = _newMax;
        }

        /// @notice updates nftA
        /// @param _newToken as new token
        function updNftA(address _newToken) public onlyOwner {
            returnNFTs(nftA);
            nftA = _newToken;
        }

        /// @notice updates nftB
        /// @param _newToken as new token
        function updNftB(address _newToken) public onlyOwner {
            returnNFTs(nftB);
            nftB = _newToken;
        }

        /// @notice updates nftC
        /// @param _newToken as new token
        function updNftC(address _newToken) public onlyOwner {
            returnNFTs(nftC);
            nftC = _newToken;
        }
        

        /// @notice updates updrewardTime
        /// @param _newTime as new token
        function updrewardTime(uint256 _newTime) public onlyOwner {
            rewardTime = _newTime;
        }

        /// @notice updates batchStakeLimit
        /// @param _newLimit as new token
        function updBatchLimit(uint256 _newLimit) public onlyOwner {
            batchStakeLimit = _newLimit;
        }

        /// @notice returns all stakes
        /// @dev needed if contract number is updated, else they would be locked
        function returnNFTs(address _token) internal {
            if(_token == nftA) {
                for(uint256 i = 0; i < aCounter; i++) {
                    if(stakeDataA[i].staked) {
                        unstakeNFT(_token, stakeDataA[i].tokenId);
                    }
                }
            } else if(_token == nftB) {
                for(uint256 i = 0; i < bCounter; i++) {
                    if(stakeDataB[i].staked) {
                        unstakeNFT(_token, stakeDataB[i].tokenId);
                    }
                }
            } else if(_token == nftC) {
                for(uint256 i = 0; i < cCounter; i++) {
                    if(stakeDataC[i].amount > 0) {
                        unstakeCollectible(stakeDataC[i].tokenId, stakeDataC[i].amount);
                    }
                }
            }
        }

        /// @notice following three functions are for erc1155 awareness
        function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
            return this.onERC1155Received.selector;
        }

        function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
            return this.onERC1155BatchReceived.selector;
        }

        function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
            return this.onERC721Received.selector;
        }

        /// @notice updates token
        /// @param _newToken as new erc20 token
        function updToken(address _newToken) public onlyOwner {
            token = _newToken;
        }

        /// @notice withdraw accidentially sent ETH to contract
        function withdraw() public payable onlyOwner {
            require(payable(msg.sender).send(address(this).balance));
        }
    }