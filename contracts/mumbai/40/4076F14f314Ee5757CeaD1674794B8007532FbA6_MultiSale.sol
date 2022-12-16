// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MultiSale is Ownable {
    address public lootBoxAddress;

    address public assetAddress;

    address public bullToken;

    address public masterAddress;

    mapping(address => uint256) public minted;

    uint256 public assetSaleStartTime;

    uint256 public assetSaleEndTime;

    uint256 public lootBoxSaleStartTime;

    uint256 public lootBoxSaleEndTime;

    uint256 public LOOTBOX_MAX_PURCHASE = 50;

    uint256 public MAX_ASSET_PURCHASE = 50;

    bool public ASSET_LIMIT_STATUS = false;

    bool public LOOTBOX_LIMIT_STATUS = false;

    uint256 public saleAssetTokenId;

    uint256 public saleLootBoxTokenId;

    uint256 public ASSET_PRICE = 1000000 * 10 ** 18;

    uint256 public LOOTBOX_PRICE = 1000000 * 10 ** 18;

    // mapping address => collectionId => amount
    mapping(address => mapping(uint256 => uint256)) public mintedAssest;

    // mapping address => collectionId => amount
    mapping(address => mapping(uint256 => uint256)) public mintedLootBox;

    constructor(address _lootBoxAddress, address _assetAddress) {
        lootBoxAddress = _lootBoxAddress;
        assetAddress = _assetAddress;
    }

    function setAssetSaleTime(
        uint256 newStartTime,
        uint256 newEndTime
    ) public onlyOwner {
        assetSaleStartTime = newStartTime;
        assetSaleEndTime = newEndTime;
    }

    function setLootBoxSaleTime(
        uint256 newStartTime,
        uint256 newEndTime
    ) public onlyOwner {
        lootBoxSaleStartTime = newStartTime;
        lootBoxSaleEndTime = newEndTime;
    }

    function changeBuyToken(address newERC20Token) external onlyOwner {
        bullToken = newERC20Token;
    }

    function changeMasterAddress(address newMasterAddress) external onlyOwner {
        masterAddress = newMasterAddress;
    }

    function changeAssetAddress(
        address _assetAddress,
        uint256 _saleAssetTokenId
    ) external onlyOwner {
        assetAddress = _assetAddress;
        saleAssetTokenId = _saleAssetTokenId;
    }

    function changeLootBoxAddress(
        address _lootBoxAddress,
        uint256 _saleLootBoxTokenId
    ) external onlyOwner {
        lootBoxAddress = _lootBoxAddress;
        saleLootBoxTokenId = _saleLootBoxTokenId;
    }

    function changeAssetMaxPurchase(uint256 _maxPurchase) external onlyOwner {
        MAX_ASSET_PURCHASE = _maxPurchase;
    }

    function changeLootBoxMaxPurchase(uint256 _maxPurchase) external onlyOwner {
        LOOTBOX_MAX_PURCHASE = _maxPurchase;
    }

    function changeAssetSaleLimitStatus() external onlyOwner {
        ASSET_LIMIT_STATUS = !ASSET_LIMIT_STATUS;
    }

    function changeLootBoxSaleLimitStatus() external onlyOwner {
        LOOTBOX_LIMIT_STATUS = !LOOTBOX_LIMIT_STATUS;
    }

    function changeLootBoxPrice(uint256 newPrice) external onlyOwner {
        LOOTBOX_PRICE = newPrice;
    }

    function changeAssetPrice(uint256 newPrice) external onlyOwner {
        ASSET_PRICE = newPrice;
    }

    function buyAsset(uint256 amount) external {
        require(amount > 0, "You Cannot Buy 0");
        uint256 currentTimeStamp = block.timestamp;
        require(
            currentTimeStamp > assetSaleStartTime &&
                currentTimeStamp < assetSaleEndTime,
            "Sale HasNot Started Or Ended"
        );
        if (ASSET_LIMIT_STATUS) {
            require(
                mintedAssest[msg.sender][saleAssetTokenId] + amount <=
                    MAX_ASSET_PURCHASE,
                "Exceeds Minting Limit"
            );
        }
        IERC20(bullToken).transferFrom(
            msg.sender,
            masterAddress,
            amount * ASSET_PRICE
        );
        IERC1155(assetAddress).safeTransferFrom(
            masterAddress,
            msg.sender,
            saleAssetTokenId,
            amount,
            ""
        );
        mintedAssest[msg.sender][saleAssetTokenId] += amount;
    }

    function buyLootBox(uint256 amount) external {
        require(amount > 0, "You Cannot Buy 0");
        uint256 currentTimeStamp = block.timestamp;
        require(
            currentTimeStamp > lootBoxSaleStartTime &&
                currentTimeStamp < lootBoxSaleEndTime,
            "Sale HasNot Started Or Ended"
        );
        if (LOOTBOX_LIMIT_STATUS) {
            require(
                mintedLootBox[msg.sender][saleLootBoxTokenId] + amount <=
                    LOOTBOX_MAX_PURCHASE,
                "Exceeds Minting Limit"
            );
        }
        IERC20(bullToken).transferFrom(
            msg.sender,
            masterAddress,
            amount * LOOTBOX_PRICE
        );
        IERC1155(lootBoxAddress).safeTransferFrom(
            masterAddress,
            msg.sender,
            saleLootBoxTokenId,
            amount,
            ""
        );
        mintedLootBox[msg.sender][saleLootBoxTokenId] += amount;
    }
}

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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