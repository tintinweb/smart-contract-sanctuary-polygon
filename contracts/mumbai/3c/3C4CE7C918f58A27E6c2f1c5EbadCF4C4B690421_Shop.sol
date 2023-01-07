//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICollection.sol";
import "./IOwnershipManagement.sol";

contract Shop is ReentrancyGuard, Ownable {
  struct ProductOrder {
    uint256 productId;
    uint256 amount;
  }

  event Purchase(address indexed buyer);
  event ExternalPurchase(string indexed hash);
  event CollectionStatusChanged(address collection, bool open);

  mapping(address => bool) public collectionSaleOpen;

  uint256 public immutable GENESIS_BLOCK;

  constructor() {
    GENESIS_BLOCK = block.number;
  }

  function setSaleOpen(
    address collectionAddress,
    bool open
  ) external onlyOwner {
    collectionSaleOpen[collectionAddress] = open;
    emit CollectionStatusChanged(collectionAddress, open);
  }

  IOwnershipManagement public ownershipManagement;

  modifier collectionOpen(address collectionAddress) {
    require(collectionSaleOpen[collectionAddress], "COLLECTION_NOT_FOR_SALE");
    _;
  }

  function setOwnershipManagement(address addr) external {
    ownershipManagement = IOwnershipManagement(addr);
  }

  function purchase(
    address collectionAddress,
    ProductOrder[] memory productOrders
  ) external payable nonReentrant collectionOpen(collectionAddress) {
    ICollection collection = ICollection(collectionAddress);
    uint256 total = calculateTotal(collection, productOrders);
    require(msg.value == total, "ERROR_INCORRECT_PAYMENT");

    for (uint256 i = 0; i < productOrders.length; i++) {
      ProductOrder memory productOrder = productOrders[i];
      collection.mint(msg.sender, productOrder.productId, productOrder.amount);
    }

    emit Purchase(msg.sender);
  }

  function externallyPaidOrder(
    address collectionAddress,
    ProductOrder[] memory productOrders,
    string memory ownerHash
  ) external onlyOwner nonReentrant collectionOpen(collectionAddress) {
    ICollection collection = ICollection(collectionAddress);

    for (uint256 i = 0; i < productOrders.length; i++) {
      ProductOrder memory productOrder = productOrders[i];

      uint256[] memory itemIds = collection.mint(
        address(ownershipManagement),
        productOrder.productId,
        productOrder.amount
      );

      ownershipManagement.assignOwnership(
        collectionAddress,
        itemIds,
        ownerHash
      );
    }

    emit ExternalPurchase(ownerHash);
  }

  function calculateTotal(
    ICollection collection,
    ProductOrder[] memory productOrders
  ) public view returns (uint256 totalPrice) {
    for (uint256 i = 0; i < productOrders.length; i++) {
      ProductOrder memory productOrder = productOrders[i];
      totalPrice +=
        collection.products(productOrder.productId).price *
        productOrder.amount;
    }
    return totalPrice;
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IOwnershipManagement {
  function assignOwnership(
    address collectionAddress,
    uint256[] memory itemIds,
    string memory ownerHash
  ) external;

  function claimAll(address to, string memory hash) external;

  function claim(
    address collectionAddress,
    address to,
    string memory hash
  ) external;

  function hasClaimableItems(string memory hash) external view returns (bool);

  function validateOwner(
    address collectionAddress,
    uint256 tokenId,
    string memory hash
  ) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Product.sol";
import "./Item.sol";

interface ICollection {
  function itemsCreated() external view returns (uint256);

  function getAllProducts() external view returns (Product[] memory);

  function products(uint256 productId) external view returns (Product memory);

  function getProducts(uint256 startProductId, uint256 endProductId)
    external
    view
    returns (Product[] memory);

  function items(uint256 itemId) external view returns (Item memory);

  function newProduct(
    uint256 stock,
    uint256 price,
    string memory URI
  ) external returns (uint256 productId);

  function mint(
    address to,
    uint256 productId,
    uint256 amount
  ) external returns (uint256[] memory mintedItems);

  function mintWithItemMetadata(
    address to,
    uint256 productId,
    uint256 amount,
    string memory URI
  ) external returns (uint256[] memory mintedItems);

  function addProductMetadata(uint256 productId, string memory URI) external;

  function addItemMetadata(uint256 itemId, string memory URI) external;

  function updateCustomMetadata(uint256 itemId, string memory URI) external;

  function getCustomMetadata(address creator, uint256 itemId)
    external
    view
    returns (string memory);

  function setStock(uint256 productId, uint256 stock) external;

  function productsCreated() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

struct Item {
  uint256 id;
  string URI;
  bool frozen;
  uint256 productId;
  string[] additionalURIs;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

struct Product {
  uint256 id;
  string URI;
  bool frozen;
  uint256 stockLimit;
  uint256 mintedItems;
  uint256 price;
  string[] additionalURIs;
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