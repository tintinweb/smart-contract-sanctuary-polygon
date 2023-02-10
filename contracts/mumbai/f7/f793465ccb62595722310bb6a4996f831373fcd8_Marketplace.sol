/**
 *Submitted for verification at polygonscan.com on 2023-02-09
*/

// File: custom/Auth.sol


pragma solidity 0.8.17;

abstract contract Auth {
    address internal owner;
    mapping(address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED");
        _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

// File: interfaces/ICollection.sol


pragma solidity ^0.8.17;

interface ICollection {
    function owner() external view returns (address);

    function ownerOf(uint256 tokenId) external view returns (address owner);
}

// File: interfaces/IFeeManager.sol


pragma solidity ^0.8.17;

interface IFeeManager {
    function setCollectionFee(address collection, uint16 fee) external;

    function removeCollectionFee(address collection) external;

    function setDefaultFee(uint16 fee) external;

    function setFeeReceiver(address receiver) external;

    function getReceiver() external view returns (address);

    function getFee(address collection) external view returns (uint16);

    function getFeeAmount(address collection, uint256 amount)
        external
        view
        returns (uint256);
}

// File: interfaces/ICollectionManager.sol


pragma solidity ^0.8.17;

interface ICollectionManager {
    function add(address currency) external;

    function remove(address currency) external;

    function check(address currency) external view returns (bool);
}

// File: interfaces/ICurrencyManager.sol


pragma solidity ^0.8.17;

interface ICurrencyManager {
    function add(address currency) external;

    function remove(address currency) external;

    function check(address currency) external view returns (bool);

    function list(uint256 cursor, uint256 size)
        external
        view
        returns (address[] memory, uint256);

    function count() external view returns (uint256);
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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/interfaces/IERC2981.sol


// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// File: @openzeppelin/contracts/token/common/ERC2981.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;



/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


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

// File: @openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: Marketplace.sol


pragma solidity ^0.8.17;













contract Marketplace is Auth, ERC721Holder {
    using SafeMath for uint256;

    bytes4 private constant ERC721 = 0x80ac58cd;
    bytes4 private constant ERC1155 = 0xd9b67a26;
    uint256 public constant PERCENTS_DIVIDER = 10000;
    uint256 public constant MIN_BID_INCREMENT_PERCENT = 500; // 5%

    struct Pair {
        uint256 pair_id;
        address collection;
        uint256 token_id;
        address owner;
        address currency;
        uint256 price;
        bool bValid;
    }

    struct Bid {
        address from;
        uint256 bidPrice;
    }

    struct Auction {
        uint256 auction_id;
        address collection;
        uint256 token_id;
        uint256 startTime;
        uint256 endTime;
        uint256 startPrice;
        address owner;
        address currency;
        bool active;
    }

    struct Order {
        uint256 order_id;
        address collection;
        uint256 token_id;
        address orderer;
        address currency;
        uint256 price;
        bool bValid;
    }

    uint256 public pairIndex;
    uint256 public auctionIndex;
    uint256 public orderIndex;
    mapping(uint256 => Pair) public pairs;
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => Bid[]) public auctionBids;
    mapping(uint256 => Order) public orders;
    ICurrencyManager public currencyManager;
    ICollectionManager public collectionManager;
    IFeeManager public feeManager;

    event ItemListed(Pair pair);
    event ItemDelisted(uint256 id);
    event Swapped(address buyer, Pair pair);
    event BidSuccess(
        address _from,
        uint256 _auctionId,
        uint256 _amount,
        uint256 _bidIndex
    );
    event AuctionCreated(Auction auction);
    event AuctionCanceled(uint256 _auctionId);
    event AuctionFinalized(Bid bid, Auction auction);
    event OrderAdded(Order order);
    event OrderCanceled(uint256 order_id);
    event OrderSold(address seller, Order order);

    constructor(
        address _currencyManager,
        address _collectionManager,
        address _feeManager
    ) Auth(msg.sender) {
        currencyManager = ICurrencyManager(_currencyManager);
        collectionManager = ICollectionManager(_collectionManager);
        feeManager = IFeeManager(_feeManager);
    }

    /**
     * @dev Function list a NFT for a fixed price
     * @param _collection collection address
     * @param _token_id token id
     * @param _currency currency address
     * @param _price sell price
     */
    function list(
        address _collection,
        uint256 _token_id,
        address _currency,
        uint256 _price
    ) external onlyItemOwner(_collection, _token_id) {
        require(_price > 0, "Invalid price");
        require(currencyManager.check(_currency), "Currency not allowed");
        require(collectionManager.check(_collection), "Invalid collection");

        // Transfer NFT to marketplace
        _transferNFT(_collection, msg.sender, address(this), _token_id, 1);

        // Create new pair item
        pairIndex = pairIndex.add(1);
        Pair memory item;
        item.pair_id = pairIndex;
        item.collection = _collection;
        item.token_id = _token_id;
        item.owner = msg.sender;
        item.currency = _currency;
        item.price = _price;
        item.bValid = true;
        pairs[pairIndex] = item;

        emit ItemListed(item);
    }

    /**
     * @dev Function to remove a NFT from sale
     * @param _id pair id
     */
    function delist(uint256 _id) external {
        require(pairs[_id].bValid, "Invalid Pair id");
        require(
            pairs[_id].owner == msg.sender || isAuthorized(msg.sender),
            "Only owner can delist"
        );

        // Transer NFT to owner
        _transferNFT(
            pairs[_id].collection,
            address(this),
            msg.sender,
            pairs[_id].token_id,
            1
        );

        // Remove pair
        pairs[_id].bValid = false;
        pairs[_id].price = 0;

        emit ItemDelisted(_id);
    }

    /**
     * @dev Function to buy a NFT
     * @param _id pair id
     */
    function buy(uint256 _id) external payable {
        require(_id <= pairIndex && pairs[_id].bValid, "Invalid Pair Id");
        require(pairs[_id].owner != msg.sender, "Owner can't buy");

        Pair memory pair = pairs[_id];

        // 1 - Transfer value to contract
        if (isERC20(pair.currency)) {
            IERC20 token = IERC20(pair.currency);
            require(
                token.transferFrom(msg.sender, address(this), pair.price),
                "Insufficient token amount"
            );
        } else {
            require(msg.value >= pair.price, "Insufficient amount");
        }

        // 2 - Transfer platform fee, royalties and seller amount
        _transferFeesAndFunds(
            pair.collection,
            pair.token_id,
            pair.currency,
            pair.owner,
            pair.price,
            1
        );

        // 5 - Transfer NFT to buyer
        _transferNFT(
            pair.collection,
            address(this),
            msg.sender,
            pair.token_id,
            1
        );
        pairs[_id].bValid = false;

        emit Swapped(msg.sender, pair);
    }

    /**
     * @dev Function to create a new auction for a NFT
     * @param _collection collection address
     * @param _token_id token id
     * @param _currency currency address
     * @param _startPrice initial price for bids
     * @param _startTime auction start date
     * @param _endTime auction end date
     */
    function createAuction(
        address _collection,
        uint256 _token_id,
        address _currency,
        uint256 _startPrice,
        uint256 _startTime,
        uint256 _endTime
    ) public onlyItemOwner(_collection, _token_id) {
        require(block.timestamp < _endTime, "Invalid end time");
        require(collectionManager.check(_collection), "Collection not allowed");
        require(currencyManager.check(_currency), "Currency not allowed");

        // 1 - Transfer NFT to marketplace
        _transferNFT(_collection, msg.sender, address(this), _token_id, 1);

        auctionIndex = auctionIndex.add(1);
        Auction memory newAuction;
        newAuction.auction_id = auctionIndex;
        newAuction.collection = _collection;
        newAuction.token_id = _token_id;
        newAuction.startPrice = _startPrice;
        newAuction.startTime = _startTime;
        newAuction.endTime = _endTime;
        newAuction.owner = msg.sender;
        newAuction.currency = _currency;
        newAuction.active = true;
        auctions[auctionIndex] = newAuction;

        emit AuctionCreated(newAuction);
    }

    /**
     * @dev Function to send a bid to auction
     * @param _id auction id
     * @param amount bid price
     */
    function bidOnAuction(uint256 _id, uint256 amount) external payable {
        Auction memory auction = auctions[_id];

        require(_id <= auctionIndex && auction.active, "Invalid Auction");
        require(auction.owner != msg.sender, "Owner can't bid");
        require(auction.active, "Auction not exist");
        require(block.timestamp < auction.endTime, "Auction is over");
        require(block.timestamp >= auction.startTime, "Auction is not started");

        uint256 bidsLength = auctionBids[_id].length;
        uint256 tempAmount = auction.startPrice;

        // Verify if bid is greatter than last bids
        Bid memory lastBid;
        if (bidsLength > 0) {
            lastBid = auctionBids[_id][bidsLength - 1];
            tempAmount = lastBid
                .bidPrice
                .mul(PERCENTS_DIVIDER + MIN_BID_INCREMENT_PERCENT)
                .div(PERCENTS_DIVIDER);
        }
        require(amount >= tempAmount, "Too small amount");

        // If user is paying with ERC20 token
        if (isERC20(auction.currency)) {
            IERC20 token = IERC20(auction.currency);

            // 1 - Transfer the bid value to platform
            require(
                token.transferFrom(msg.sender, address(this), amount),
                "Insufficient token amount"
            );

            // 2 - Refund last bidder
            if (bidsLength > 0) {
                require(
                    token.transfer(lastBid.from, lastBid.bidPrice),
                    "Refund to last bidder failed"
                );
            }
        } else {
            // If user is paying with main coin (ETH, MATIC, BNB, ect)

            // 1 - Get bid value to platform
            require(msg.value >= amount, "Insufficient amount");

            // 2 - Refund last bidder
            if (bidsLength > 0) {
                (bool result, ) = payable(lastBid.from).call{
                    value: lastBid.bidPrice
                }("");
                require(result, "Refund to last bidder failed");
            }
        }

        Bid memory newBid;
        newBid.from = msg.sender;
        newBid.bidPrice = amount;
        auctionBids[_id].push(newBid);
        emit BidSuccess(msg.sender, _id, newBid.bidPrice, bidsLength);
    }

    /**
     * @dev Function to finalize an auction
     * @param _id auction id
     */
    function finalizeAuction(uint256 _id) public {
        Auction memory auction = auctions[_id];
        require(_id <= auctionIndex && auction.active, "Invalid Auction");
        require(
            msg.sender == auction.owner || isAuthorized(msg.sender),
            "Only auction owner can finalize"
        );

        uint256 bidsLength = getBidsLength(_id);

        // if there are no bids cancel
        if (bidsLength == 0) {
            _transferNFT(
                auction.collection,
                address(this),
                auction.owner,
                auction.token_id,
                1
            );
            auctions[_id].active = false;
            emit AuctionCanceled(_id);
        } else {
            // The money goes to the auction owner
            Bid memory lastBid = auctionBids[_id][bidsLength - 1];

            // 1 - Transfer platform fee, royalties and seller amount
            _transferFeesAndFunds(
                auction.collection,
                auction.token_id,
                auction.currency,
                auction.owner,
                lastBid.bidPrice,
                1
            );

            // 2 - Transfer NFT to buyer
            _transferNFT(
                auction.collection,
                address(this),
                lastBid.from,
                auction.token_id,
                1
            );

            auctions[_id].active = false;
            emit AuctionFinalized(lastBid, auction);
        }
    }

    /**
     * @dev Function to send a bid to any NFT
     * @param _collection collection address
     * @param _tokenId token id
     * @param _currency currency address
     * @param _price bid price
     */
    function freeBid(
        address _collection,
        uint256 _tokenId,
        address _currency,
        uint256 _price
    ) external {
        require(_price > 0, "Invalid price");
        require(collectionManager.check(_collection), "Collection not allowed");
        require(
            currencyManager.check(_currency) && _currency != address(0),
            "Currency not allowed"
        );

        ICollection nft = ICollection(_collection);
        require(nft.ownerOf(_tokenId) != msg.sender, "Owner can't bid");

        IERC20 payToken = IERC20(_currency);
        require(
            payToken.balanceOf(msg.sender) >= _price,
            "Insufficient balance"
        );
        require(
            payToken.allowance(msg.sender, address(this)) >= _price,
            "Check the token allowance"
        );

        orderIndex = orderIndex.add(1);
        orders[orderIndex].order_id = orderIndex;
        orders[orderIndex].collection = _collection;
        orders[orderIndex].token_id = _tokenId;
        orders[orderIndex].orderer = msg.sender;
        orders[orderIndex].currency = _currency;
        orders[orderIndex].price = _price;
        orders[orderIndex].bValid = true;

        emit OrderAdded(orders[orderIndex]);
    }

    /**
     * @dev Function to bidder cancel a free bid (order)
     * @param _id order id
     */
    function cancelOrder(uint256 _id) external {
        require(orders[_id].bValid, "Invalid Bid");
        require(orders[_id].orderer == msg.sender, "Only bidder can cancel");

        orders[_id].bValid = false;

        emit OrderCanceled(_id);
    }

    /**
     * @dev Function to NFT owner accept a free bid (order)
     * @param _id order id
     */
    function acceptBid(uint256 _id) external {
        require(orders[_id].bValid, "Invalid Bid");
        Order memory order = orders[_id];

        ICollection nft = ICollection(order.collection);
        require(
            nft.ownerOf(order.token_id) == msg.sender,
            "Only owner can sell item!"
        );

        // 1 - Transfer value to contract
        IERC20 token = IERC20(order.currency);
        require(
            token.transferFrom(order.orderer, address(this), order.price),
            "Insufficient balance"
        );

        // 2 - Transfer platform fee, royalties and seller amount
        _transferFeesAndFunds(
            order.collection,
            order.token_id,
            order.currency,
            msg.sender,
            order.price,
            1
        );

        // 3 - Transfer NFT token to bidder
        _transferNFT(
            order.collection,
            msg.sender,
            order.orderer,
            order.token_id,
            1
        );

        orders[_id].bValid = false;

        emit OrderSold(msg.sender, orders[_id]);
    }

    /**
     * @dev Get number of bids from an auction
     * @param _auction_id auction id
     */
    function getBidsLength(uint256 _auction_id) public view returns (uint256) {
        return auctionBids[_auction_id].length;
    }

    /**
     * @dev Get the last bid from an auction
     * @param _auction_id auction id
     */
    function getLastBid(uint256 _auction_id)
        public
        view
        returns (uint256, address)
    {
        uint256 bidsLength = auctionBids[_auction_id].length;

        if (bidsLength >= 0) {
            Bid memory lastBid = auctionBids[_auction_id][bidsLength - 1];
            return (lastBid.bidPrice, lastBid.from);
        }
        return (0, address(0));
    }

    /**
     * @dev Get the ERC-2981 token royalties
     * @param _collection collection address
     * @param _id token id
     * @param _price token price
     * @param _amount quantity (1 for ERC-721, +1 for ERC-1155)
     */
    function getRoyalty(
        address _collection,
        uint256 _id,
        uint256 _price,
        uint256 _amount
    ) internal view returns (address, uint256) {
        IERC2981 collection = IERC2981(_collection);
        try collection.royaltyInfo(_id, _price.mul(_amount)) returns (
            address receiver,
            uint256 amount
        ) {
            return (receiver, amount);
        } catch {
            return (address(0x0), 0);
        }
    }

    /**
     * @dev Retrieve the owner of ERC-721 or ERC-1155 collection
     * @param _collection address to get the owner
     */
    function getCollectionOwner(address _collection)
        internal
        view
        returns (address)
    {
        ICollection collection = ICollection(_collection);
        try collection.owner() returns (address owner) {
            return owner;
        } catch {
            return address(0x0);
        }
    }

    /**
     * @dev Check if address is a ERC-20 token
     * @param _token address to check
     */
    function isERC20(address _token) internal pure returns (bool) {
        return _token != address(0x0);
    }

    /**
     * @dev Transfer platform fee, royalty and seller amount
     * @param _collection address of the token collection
     * @param _token_id the token id
     * @param _to receiver address
     * @param _currency currency address
     * @param _price token price
     * @param _amount amount of tokens (1 for ERC721, 1+ for ERC1155)
     * @dev For ERC721, amount is not used
     */
    function _transferFeesAndFunds(
        address _collection,
        uint256 _token_id,
        address _currency,
        address _to,
        uint256 _price,
        uint256 _amount
    ) private {
        (address royaltyAddress, uint256 royaltyAmount) = getRoyalty(
            _collection,
            _token_id,
            _price,
            _amount
        );
        uint256 feeAmount = feeManager.getFeeAmount(_collection, _price);
        uint256 sellerAmount = _price.sub(feeAmount).sub(royaltyAmount);

        if (isERC20(_currency)) {
            IERC20 token = IERC20(_currency);
            // Retrieve the fee amount to platform
            require(token.transfer(feeManager.getReceiver(), feeAmount));

            // Pay royalty amount (if exists)
            if (royaltyAddress != address(0x0) && royaltyAmount > 0) {
                require(token.transfer(royaltyAddress, royaltyAmount));
            }

            // Pay value to the seller
            require(token.transfer(_to, sellerAmount));
        } else {
            // Retrieve the fee amount to platform
            (bool fs, ) = payable(feeManager.getReceiver()).call{
                value: feeAmount
            }("");
            require(fs, "Fail: Platform fee");

            // Pay royalty amount (if exists)
            if (royaltyAddress != address(0x0) && royaltyAmount > 0) {
                (bool hs, ) = payable(royaltyAddress).call{
                    value: royaltyAmount
                }("");
                require(hs, "Fail: Royalties");
            }

            // Pay value to the seller
            (bool os, ) = payable(_to).call{value: sellerAmount}("");
            require(os, "Fail: Seller amount");
        }
    }

    /**
     * @dev Transfer NFT (ERC-721 and ERC-1155)
     * @param collection address of the token collection
     * @param from address of the sender
     * @param to address of the recipient
     * @param tokenId tokenId
     * @param amount amount of tokens (1 for ERC721, 1+ for ERC1155)
     * @dev For ERC721, amount is not used
     */
    function _transferNFT(
        address collection,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal {
        if (IERC165(collection).supportsInterface(0x80ac58cd)) {
            // Transfer ERC-721 NFT
            IERC721(collection).safeTransferFrom(from, to, tokenId);
        } else if (IERC165(collection).supportsInterface(ERC1155)) {
            // Transfer ERC-1155 NFT
            IERC1155(collection).safeTransferFrom(
                from,
                to,
                tokenId,
                amount,
                ""
            );
        } else {
            revert("Invalid collection contract");
        }
    }

    /**
     * @dev Withdraw all contract balance
     * @dev Only owner or authorized addresses can call
     */
    function withdraw() external payable authorized {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    modifier onlyItemOwner(address _collection, uint256 _tokenId) {
        ICollection collectionContract = ICollection(_collection);
        require(collectionContract.ownerOf(_tokenId) == msg.sender);
        _;
    }
}