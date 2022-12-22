// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
pragma solidity ^0.8.14;

/*///////////////////////////////////////
─────────────────────────────────────────
──┌───┐───────────────────┌───┬───┬───┐──
──│┌─┐│───────────────────└┐┌┐│┌─┐│┌─┐│──
──│└─┘├──┬─┬──┬──┬──┬─┐┌──┐│││││─│││─││──
──│┌──┤┌┐│┌┤┌┐│┌┐│┌┐│┌┐┤──┤││││└─┘││─││──
──││──│┌┐│││┌┐│└┘│└┘│││├──├┘└┘│┌─┐│└─┘│──
──└┘──└┘└┴┘└┘└┴─┐├──┴┘└┴──┴───┴┘─└┴───┘──
──────────────┌─┘│───────────────────────
──────────────└──┘───────────────────────
─────────────────────────────────────────
///////////////////////////////////////*/

interface IAddressRegistry {
    function uriGenerator() external view returns (address);

    function treasury() external view returns (address);

    function pdp() external view returns (address);

    function pxp() external view returns (address);

    function pdt() external view returns (address);

    function pdtOracle() external view returns (address);

    function playerMgmt() external view returns (address);

    function poolMgmt() external view returns (address);

    function svgGenerator() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

/*///////////////////////////////////////
─────────────────────────────────────────
──┌───┐───────────────────┌───┬───┬───┐──
──│┌─┐│───────────────────└┐┌┐│┌─┐│┌─┐│──
──│└─┘├──┬─┬──┬──┬──┬─┐┌──┐│││││─│││─││──
──│┌──┤┌┐│┌┤┌┐│┌┐│┌┐│┌┐┤──┤││││└─┘││─││──
──││──│┌┐│││┌┐│└┘│└┘│││├──├┘└┘│┌─┐│└─┘│──
──└┘──└┘└┴┘└┘└┴─┐├──┴┘└┴──┴───┴┘─└┴───┘──
──────────────┌─┘│───────────────────────
──────────────└──┘───────────────────────
─────────────────────────────────────────
///////////////////////////////////////*/

interface IAssetPool {
    struct UserAssetInfo {
        address asset;
        uint256 tokenId;
        uint256 amount;
    }

    function setPid(uint256 _pid) external;

    function isActivatedAsset(address _asset) external returns (bool);

    function liquidityByAsset(address _asset) external returns (uint256);

    function borrowsByAsset(address _asset) external returns (uint256);

    function updateBorrows(address _asset, uint256 _amount, bool _isIncrease) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./IAssetPool.sol";

/*///////////////////////////////////////
─────────────────────────────────────────
──┌───┐───────────────────┌───┬───┬───┐──
──│┌─┐│───────────────────└┐┌┐│┌─┐│┌─┐│──
──│└─┘├──┬─┬──┬──┬──┬─┐┌──┐│││││─│││─││──
──│┌──┤┌┐│┌┤┌┐│┌┐│┌┐│┌┐┤──┤││││└─┘││─││──
──││──│┌┐│││┌┐│└┘│└┘│││├──├┘└┘│┌─┐│└─┘│──
──└┘──└┘└┴┘└┘└┴─┐├──┴┘└┴──┴───┴┘─└┴───┘──
──────────────┌─┘│───────────────────────
──────────────└──┘───────────────────────
─────────────────────────────────────────
///////////////////////////////////////*/

interface IAssetPool1155 is IAssetPool {

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./IAssetPool.sol";

/*///////////////////////////////////////
─────────────────────────────────────────
──┌───┐───────────────────┌───┬───┬───┐──
──│┌─┐│───────────────────└┐┌┐│┌─┐│┌─┐│──
──│└─┘├──┬─┬──┬──┬──┬─┐┌──┐│││││─│││─││──
──│┌──┤┌┐│┌┤┌┐│┌┐│┌┐│┌┐┤──┤││││└─┘││─││──
──││──│┌┐│││┌┐│└┘│└┘│││├──├┘└┘│┌─┐│└─┘│──
──└┘──└┘└┴┘└┘└┴─┐├──┴┘└┴──┴───┴┘─└┴───┘──
──────────────┌─┘│───────────────────────
──────────────└──┘───────────────────────
─────────────────────────────────────────
///////////////////////////////////////*/

interface IAssetPool721 is IAssetPool {

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

/*///////////////////////////////////////
─────────────────────────────────────────
──┌───┐───────────────────┌───┬───┬───┐──
──│┌─┐│───────────────────└┐┌┐│┌─┐│┌─┐│──
──│└─┘├──┬─┬──┬──┬──┬─┐┌──┐│││││─│││─││──
──│┌──┤┌┐│┌┤┌┐│┌┐│┌┐│┌┐┤──┤││││└─┘││─││──
──││──│┌┐│││┌┐│└┘│└┘│││├──├┘└┘│┌─┐│└─┘│──
──└┘──└┘└┴┘└┘└┴─┐├──┴┘└┴──┴───┴┘─└┴───┘──
──────────────┌─┘│───────────────────────
──────────────└──┘───────────────────────
─────────────────────────────────────────
///////////////////////////////////////*/

interface IPXP {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

/*///////////////////////////////////////
─────────────────────────────────────────
──┌───┐───────────────────┌───┬───┬───┐──
──│┌─┐│───────────────────└┐┌┐│┌─┐│┌─┐│──
──│└─┘├──┬─┬──┬──┬──┬─┐┌──┐│││││─│││─││──
──│┌──┤┌┐│┌┤┌┐│┌┐│┌┐│┌┐┤──┤││││└─┘││─││──
──││──│┌┐│││┌┐│└┘│└┘│││├──├┘└┘│┌─┐│└─┘│──
──└┘──└┘└┴┘└┘└┴─┐├──┴┘└┴──┴───┴┘─└┴───┘──
──────────────┌─┘│───────────────────────
──────────────└──┘───────────────────────
─────────────────────────────────────────
///////////////////////////////////////*/

interface IPlayerRental {
    struct OrderInfo {
        /// @dev order index, starts from 0
        uint32 orderId;
        /// @dev order expiration timestamp
        uint64 expireAt;
        /// @dev borrower address
        address user;
        /// @dev asset address
        address asset;
        /// @dev asset token Id
        uint256 tokenId;
        /// @dev asset amount
        uint256 amount;
    }

    struct RefToOrdersByUser {
        /// @dev user address in ordersByUser
        address user;
        /// @dev index of the order list in ordersByUser
        uint256 index;
    }

    function setPid(uint256 _pid) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

/*///////////////////////////////////////
─────────────────────────────────────────
──┌───┐───────────────────┌───┬───┬───┐──
──│┌─┐│───────────────────└┐┌┐│┌─┐│┌─┐│──
──│└─┘├──┬─┬──┬──┬──┬─┐┌──┐│││││─│││─││──
──│┌──┤┌┐│┌┤┌┐│┌┐│┌┐│┌┐┤──┤││││└─┘││─││──
──││──│┌┐│││┌┐│└┘│└┘│││├──├┘└┘│┌─┐│└─┘│──
──└┘──└┘└┴┘└┘└┴─┐├──┴┘└┴──┴───┴┘─└┴───┘──
──────────────┌─┘│───────────────────────
──────────────└──┘───────────────────────
─────────────────────────────────────────
///////////////////////////////////////*/

interface IPoolManagement {
    struct PoolInfo {
        string poolName;
        address assetPool721;
        address assetPool1155;
        address playerRental;
        address riskStrategy;
    }

    function isActivatedPool(uint256 _pid) external view returns (bool);

    function getPoolInfo(uint256 _pid) external view returns (string memory, address, address, address, address);

    function poolCount() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

/*///////////////////////////////////////
─────────────────────────────────────────
──┌───┐───────────────────┌───┬───┬───┐──
──│┌─┐│───────────────────└┐┌┐│┌─┐│┌─┐│──
──│└─┘├──┬─┬──┬──┬──┬─┐┌──┐│││││─│││─││──
──│┌──┤┌┐│┌┤┌┐│┌┐│┌┐│┌┐┤──┤││││└─┘││─││──
──││──│┌┐│││┌┐│└┘│└┘│││├──├┘└┘│┌─┐│└─┘│──
──└┘──└┘└┴┘└┘└┴─┐├──┴┘└┴──┴───┴┘─└┴───┘──
──────────────┌─┘│───────────────────────
──────────────└──┘───────────────────────
─────────────────────────────────────────
///////////////////////////////////////*/

interface IRiskStrategy {
    function setPid(uint256 _pid) external;

    function getActualUtilizationRate(uint256 _totalLiquidity, uint256 _totalBorrows) external view returns (uint256);

    function getPXPCost(uint256 uActual) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "../interfaces/IAddressRegistry.sol";
import "../interfaces/IPoolManagement.sol";
import "../interfaces/IPlayerRental.sol";
import "../interfaces/IRiskStrategy.sol";
import "../interfaces/IPXP.sol";
import "../interfaces/IAssetPool721.sol";
import "../interfaces/IAssetPool1155.sol";

/*///////////////////////////////////////
─────────────────────────────────────────
──┌───┐───────────────────┌───┬───┬───┐──
──│┌─┐│───────────────────└┐┌┐│┌─┐│┌─┐│──
──│└─┘├──┬─┬──┬──┬──┬─┐┌──┐│││││─│││─││──
──│┌──┤┌┐│┌┤┌┐│┌┐│┌┐│┌┐┤──┤││││└─┘││─││──
──││──│┌┐│││┌┐│└┘│└┘│││├──├┘└┘│┌─┐│└─┘│──
──└┘──└┘└┴┘└┘└┴─┐├──┴┘└┴──┴───┴┘─└┴───┘──
──────────────┌─┘│───────────────────────
──────────────└──┘───────────────────────
─────────────────────────────────────────
///////////////////////////////////////*/

contract PlayerRental is IPlayerRental {
    /// @dev Pool Id
    uint256 public pid;

    /// @dev Total valid order list
    OrderInfo[] public orders;

    /// @dev User -> Order Id list
    mapping(address => uint256[]) public ordersByUser;

    /// @dev User -> Index of the order list in OrdersByUser -> Bool
    mapping(address => mapping(uint256 => bool)) public isExpiredUserOrder;

    /// @dev Asset -> Token Id -> Index of the order list in OrdersByUser
    mapping(address => mapping(uint256 => RefToOrdersByUser[])) public validOrdersByAsset;

    /// @notice RiskStrategy address
    IRiskStrategy public riskStrategy;

    /// @notice PXP token address
    IPXP public pxp;

    /// @notice AddressRegstry contract
    IAddressRegistry public addressRegistry;

    /// @notice PoolManagement contract
    IPoolManagement public poolManagement;

    error ZeroAddress();
    error OnlyPoolManagement(address by);
    error AlreadyRented(uint256 tokenId);
    error RentingDisabled();
    error InvalidRentalContract();
    error DeactivatedPoolRental();
    error InvalidAsset(address asset);
    error InvalidTokenAmount(uint256 amount);
    error ExceededRentingAmount(uint256 assetLiquidity, uint256 assetBorrows, uint256 rentingAmount);

    event OrderAdded(
        address indexed user,
        address indexed asset,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 duration,
        uint64 expireAt
    );

    constructor(address _addressRegistry, address _riskStrategy, address _pxp) {
        if (_addressRegistry == address(0)) revert ZeroAddress();
        if (_riskStrategy == address(0)) revert ZeroAddress();
        if (_pxp == address(0)) revert ZeroAddress();

        addressRegistry = IAddressRegistry(_addressRegistry);
        poolManagement = IPoolManagement(addressRegistry.poolMgmt());
        riskStrategy = IRiskStrategy(_riskStrategy);
        pxp = IPXP(_pxp);
    }

    function setPid(uint256 _pid) external {
        if (msg.sender != address(poolManagement)) revert OnlyPoolManagement(msg.sender);
        pid = _pid;
    }

    // TODO: Split into 2 functions - checkRentability (view) returns (bool), rent
    /// @notice Rent the asset
    /// @param _tokenId NFT token Id
    /// @param _duration Rental duration
    function rentAsset(address _asset, uint256 _tokenId, uint256 _amount, uint256 _duration, bool _isERC721) external {
        // check if this is the valid PlayerRental contract
        (address assetPool721, address assetPool1155) = _checkPlayerRental();

        // check if the asset is valid
        _checkAsset(_asset, _tokenId, _amount, _isERC721, assetPool721, assetPool1155);

        // update borrows
        _updateBorrows(_asset, _tokenId, _isERC721, assetPool721, assetPool1155);

        (uint256 totalLiquidity, uint256 totalBorrows) = _checkAmount(
            _asset,
            _amount,
            _isERC721,
            assetPool721,
            assetPool1155
        );

        // pay the rental
        _payRental(msg.sender, _amount, _duration, totalLiquidity, totalBorrows);

        // add the order
        _addOrder(_asset, _tokenId, _amount, _duration, _isERC721);

        // increase the borrows of the pool
        _updateBorrowsOfAssetPool(_asset, _amount, true, _isERC721, assetPool721, assetPool1155);
    }

    function _checkPlayerRental() internal view returns (address assetPool721, address assetPool1155) {
        address playerRental;

        // check if the pool for this contract is activated
        if (!poolManagement.isActivatedPool(pid)) revert DeactivatedPoolRental();

        // check if this contract is the correct PlayerRental of the pool
        (, assetPool721, assetPool1155, playerRental, ) = poolManagement.getPoolInfo(pid);
        if (playerRental != address(this)) revert InvalidRentalContract();
    }

    function _checkAsset(
        address _asset,
        uint256 _tokenId,
        uint256 _amount,
        bool _isERC721,
        address _assetPool721,
        address _assetPool1155
    ) internal {
        // check if the asset exists in the corresponding asset pools
        bool isValidAsset;
        if (_isERC721) {
            if (_amount != 1) revert InvalidTokenAmount(_amount);
            isValidAsset = _assetPool721 != address(0) && IERC721(_asset).ownerOf(_tokenId) == _assetPool721;
            isValidAsset = isValidAsset && IAssetPool721(_assetPool721).isActivatedAsset(_asset);
        } else {
            if (_amount == 0) revert InvalidTokenAmount(_amount);
            isValidAsset =
                _assetPool1155 != address(0) &&
                IERC1155(_asset).balanceOf(_assetPool1155, _tokenId) >= _amount;
            isValidAsset = isValidAsset && IAssetPool1155(_assetPool1155).isActivatedAsset(_asset);
        }
        if (!isValidAsset) revert InvalidAsset(_asset);
    }

    function _updateBorrows(
        address _asset,
        uint256 _tokenId,
        bool _isERC721,
        address _assetPool721,
        address _assetPool1155
    ) internal {
        uint256 expiredAmount;

        // get the valid orders by the asset.
        // in the case of ERC721 asset, orderCount = 0 | 1
        // in the case of ERC1155 asset, orderCount >= 0
        RefToOrdersByUser[] memory refList = validOrdersByAsset[_asset][_tokenId];
        uint256 refCount = refList.length;

        if (_isERC721) {
            // set the safeguard for ERC721
            require(refCount <= 1, "RefCount Check Error");

            for (uint256 i; i < refCount; i++) {
                RefToOrdersByUser memory ref = refList[i];
                uint256 orderId = ordersByUser[ref.user][ref.index];
                OrderInfo memory order = orders[orderId];

                if (uint256(order.expireAt) < block.timestamp) {
                    // remove the expired order from the validOrderByAsset
                    RefToOrdersByUser memory lastRef = refList[refCount - 1];
                    validOrdersByAsset[_asset][_tokenId][i] = lastRef;
                    validOrdersByAsset[_asset][_tokenId].pop();

                    // mark the expired order
                    require(!isExpiredUserOrder[ref.user][ref.index], "Order Already Expired");
                    isExpiredUserOrder[ref.user][ref.index] = true;

                    // since refCount is 1, for ERC721, skip the re-checking the replaced ref
                }
            }

            // calculate the expired asset amount
            expiredAmount = 1;
        } else {
            for (uint256 i; i < refCount; i++) {
                RefToOrdersByUser memory ref = refList[i];
                uint256 orderId = ordersByUser[ref.user][ref.index];
                OrderInfo memory order = orders[orderId];

                if (uint256(order.expireAt) < block.timestamp) {
                    // remove the expired order from validOrderByAsset
                    RefToOrdersByUser memory lastRef = refList[refCount - 1];
                    validOrdersByAsset[_asset][_tokenId][i] = lastRef;
                    validOrdersByAsset[_asset][_tokenId].pop();

                    // mark the expired order
                    require(!isExpiredUserOrder[ref.user][ref.index], "Order Already Expired");
                    isExpiredUserOrder[ref.user][ref.index] = true;

                    // calculate the expired asset amount
                    expiredAmount += order.amount;

                    // since the current ref was replaced with the last one, re-check the replaced ref
                    --refCount;
                    --i;
                }
            }
        }

        // decrease the borrows of the pool
        _updateBorrowsOfAssetPool(_asset, expiredAmount, false, _isERC721, _assetPool721, _assetPool1155);
    }

    function _checkAmount(
        address _asset,
        uint256 _amount,
        bool _isERC721,
        address _assetPool721,
        address _assetPool1155
    ) internal returns (uint256 totalLiquidity, uint256 totalBorrows) {
        uint256 assetPool721Liquidity;
        uint256 assetPool721Borrows;
        uint256 assetPool1155Liquidity;
        uint256 assetPool1155Borrows;

        if (_assetPool721 != address(0)) {
            assetPool721Liquidity = IAssetPool721(_assetPool721).liquidityByAsset(_asset);
            assetPool721Borrows = IAssetPool721(_assetPool721).borrowsByAsset(_asset);
        }
        if (_assetPool1155 != address(0)) {
            assetPool1155Liquidity = IAssetPool1155(_assetPool1155).liquidityByAsset(_asset);
            assetPool1155Borrows = IAssetPool1155(_assetPool1155).borrowsByAsset(_asset);
        }
        if (_isERC721) {
            if (assetPool721Liquidity - assetPool721Borrows < _amount)
                revert ExceededRentingAmount(assetPool721Liquidity, assetPool721Borrows, _amount);
        } else {
            if (assetPool1155Liquidity - assetPool1155Borrows < _amount)
                revert ExceededRentingAmount(assetPool1155Liquidity, assetPool1155Borrows, _amount);
        }

        totalLiquidity = assetPool721Liquidity + assetPool1155Liquidity;
        totalBorrows = assetPool721Borrows + assetPool1155Borrows;
    }

    function _payRental(
        address _user,
        uint256 _amount,
        uint256 _duration,
        uint256 _totalLiquidity,
        uint256 _totalBorrows
    ) private {
        uint256 actualUtilizationRate = riskStrategy.getActualUtilizationRate(_totalLiquidity, _totalBorrows);
        uint256 dueAmount = riskStrategy.getPXPCost(actualUtilizationRate) * _amount * _duration;
        pxp.burn(_user, dueAmount);
    }

    function _addOrder(address _asset, uint256 _tokenId, uint256 _amount, uint256 _duration, bool _isERC721) internal {
        uint256 totalOrderCount = orders.length;
        uint64 expireAt = uint64(block.timestamp + (_duration * 3600));
        orders.push(
            OrderInfo({
                orderId: uint32(totalOrderCount),
                expireAt: expireAt,
                user: msg.sender,
                asset: _asset,
                tokenId: _tokenId,
                amount: _amount
            })
        );

        uint256 userOrderCount = ordersByUser[msg.sender].length;
        if (_isERC721) {
            // set the safeguard for ERC721
            // in the case of ERC721, the asset rented can not be rented again before it's expired
            require(userOrderCount == 0, "Ref Add Error");
        }
        ordersByUser[msg.sender].push(totalOrderCount);
        validOrdersByAsset[_asset][_tokenId].push(RefToOrdersByUser({user: msg.sender, index: userOrderCount}));

        emit OrderAdded(msg.sender, _asset, _tokenId, _amount, _duration, expireAt);
    }

    function _updateBorrowsOfAssetPool(
        address _asset,
        uint256 _amount,
        bool _isIncrease,
        bool _isERC721,
        address _assetPool721,
        address _assetPool1155
    ) internal {
        if (_isERC721) {
            IAssetPool721(_assetPool721).updateBorrows(_asset, _amount, _isIncrease);
        } else {
            IAssetPool1155(_assetPool1155).updateBorrows(_asset, _amount, _isIncrease);
        }
    }
}