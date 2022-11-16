// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/// @author Georgi Karagyozov
/// @notice Interface of the TechnoLime Store - TechnoLimeStore contract.
interface ITechnoLimeStore {
  enum PurchaseStatus {
    Accepted,
    Returned
  }

  struct Product {
    uint256 id;
    string name;
    uint256 quantity;
  }

  struct Purchase {
    uint256 id;
    uint256 productId;
    uint256 quantity;
    uint256 blockNumber;
    bool isPurchased;
    PurchaseStatus status;
    address clientAddress;
  }

  function addNewProduct(string calldata name, uint256 quantity) external;

  function updateProductQuantityById(
    uint256 productId,
    uint256 quantity
  ) external;

  function buyProductById(uint256 productId, uint256 quantity) external;

  function returnProductById(uint256 productId) external;

  function getPurchaseInfo(
    address client,
    uint256 productId
  ) external view returns (Purchase memory);

  function getAllProducts() external view returns (Product[] memory);

  function getAllClients() external view returns (address[] memory);

  function getProductCount() external view returns (uint256);

  function getPurchaseCount() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/// @author Georgi Karagyozov
/// @notice Ownable contract used to manage the TechnoLime Store - TechnoLimeStore contract.
abstract contract Ownable {
  address private _owner;

  address public pendingOwner;
  uint256 public timeLimitClaimOwnership;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /// @notice Initializes the contract setting the deployer as the initial owner.
  constructor() {
    _transferOwnership(msg.sender);
  }

  /// @notice Throws if called by any account other than the owner.
  modifier onlyOwner() {
    require(owner() == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  /// @notice Returns the address of the current owner.
  function owner() public view returns (address) {
    return _owner;
  }

  /// @notice Leaves the contract without owner. It will not be possible to call `onlyOwner` modifier anymore.
  /// @param isRenounce: Boolean parameter with which you confirm renunciation of ownership
  function renounceOwnership(bool isRenounce) public onlyOwner {
    if (isRenounce) _transferOwnership(address(0));
  }

  /// @notice Transfers ownership of the contract to a new account.
  /// @param newOwner: The address of the new owner of the contract
  /// @param direct: Boolean parameter that will be used to change the owner of the contract directly
  function transferOwnership(address newOwner, bool direct) external onlyOwner {
    if (direct) {
      require(newOwner != address(0), "Ownable: zero address");
      require(
        newOwner != _owner,
        "Ownable: newOwner must be a different address than the current owner"
      );

      _transferOwnership(newOwner);
      pendingOwner = address(0);
    } else {
      pendingOwner = newOwner;
      timeLimitClaimOwnership = block.timestamp;
    }
  }

  /// @notice The `pendingOwner` have only 30 seconds to confirm, if he wants to be the new owner of the contract.
  function claimOwnership() external {
    require(msg.sender == pendingOwner, "Ownable: caller != pending owner");
    require(
      block.timestamp < timeLimitClaimOwnership + 30 seconds,
      "Ownable: pendingOwner have only 30 seconds to claim ownership"
    );

    _transferOwnership(pendingOwner);
    pendingOwner = address(0);
  }

  /// @notice Transfers ownership of the contract to a new account.
  /// @param newOwner: The address of the new owner of the contract
  function _transferOwnership(address newOwner) internal {
    _owner = newOwner;
    emit OwnershipTransferred(_owner, newOwner);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./interfaces/ITechnoLimeStore.sol";
import "./Ownable.sol";

error InvalidInput();
error ProductQuantityMustBeAboveZero();
error NoSuchProductIdExists();
error TheProductHasAlreadyBeenAdded();
error TheOwnerCannotBuyProduct();
error ProductQuantityNotAvailable();
error CannotBuyTheSameProductMoreThanOneTime();
error NoSuchPurchaseExists();
error TheProductReturned();
error BlockNumber100Exceeded();

/// @author Georgi Karagyozov
/// @notice Main store smart contract. Allows adding, updating, purchasing and returning products.
contract TechnoLimeStore is ITechnoLimeStore, Ownable {
  uint8 public constant PERIOD_RETURN_PRODUCT_BLOCK_NUMBER = 100;

  uint256 private _productCount = 0;
  uint256 private _purchaseCount = 0;

  Product[] private _products;
  address[] private _allClients;

  mapping(string => bool) private _productNameCreates;
  mapping(address => bool) private _clientPurchasedProduct;
  mapping(address => mapping(uint256 => Purchase))
    private _clientProductIdPurchases;

  event NewProductCreated(
    uint256 indexed productId,
    string name,
    uint256 quantity
  );
  event ProductQuantityUpdated(
    uint256 indexed productId,
    uint256 productQuantity
  );
  event ProductBought(
    address indexed client,
    uint256 indexed purchaseId,
    uint256 indexed productId,
    uint256 productQuantity
  );
  event ProductReturned(
    address indexed client,
    uint256 indexed productId,
    uint256 productQuantity
  );

  modifier onlyPossibleAddedProduct(uint256 productId) {
    if (productId >= _products.length) revert NoSuchProductIdExists();
    _;
  }

  modifier onlyPossibleQuantityAboveZero(uint256 quantity) {
    if (quantity == 0) revert ProductQuantityMustBeAboveZero();
    _;
  }

  /// @notice Allows the administrator (owner) to add new products and the quantity of them.
  /// @param name: The name of the new product to be added
  /// @param quantity: The quantity of the new product to be added
  function addNewProduct(
    string calldata name,
    uint256 quantity
  ) external onlyOwner onlyPossibleQuantityAboveZero(quantity) {
    if (bytes(name).length == 0) revert InvalidInput();
    if (_productNameCreates[name]) revert TheProductHasAlreadyBeenAdded();

    _products.push(Product(_productCount, name, quantity));
    _productNameCreates[name] = true;
    ++_productCount;

    emit NewProductCreated(_productCount, name, quantity);
  }

  /// @notice Allows the administrator (owner) to update the quantity of a product.
  /// @param productId: The ID of the product whose quantity will be updated
  /// @param quantity: The quantity that will be added to an already created product
  function updateProductQuantityById(
    uint256 productId,
    uint256 quantity
  )
    external
    onlyOwner
    onlyPossibleAddedProduct(productId)
    onlyPossibleQuantityAboveZero(quantity)
  {
    _products[productId].quantity += quantity;

    emit ProductQuantityUpdated(productId, quantity);
  }

  /// @notice Allows clients to buy products after they are added by the administrator (owner).
  /// @param productId: ID of the product to be purchased
  /// @param quantity: Quantity of the product to be purchased
  function buyProductById(
    uint256 productId,
    uint256 quantity
  )
    external
    onlyPossibleAddedProduct(productId)
    onlyPossibleQuantityAboveZero(quantity)
  {
    if (msg.sender == owner()) revert TheOwnerCannotBuyProduct();

    Product storage product = _products[productId];

    if (product.quantity < quantity) revert ProductQuantityNotAvailable();
    if (
      _clientProductIdPurchases[msg.sender][productId].isPurchased &&
      _clientProductIdPurchases[msg.sender][productId].status ==
      PurchaseStatus.Accepted
    ) revert CannotBuyTheSameProductMoreThanOneTime();

    product.quantity -= quantity;
    _clientProductIdPurchases[msg.sender][productId] = Purchase(
      _purchaseCount,
      productId,
      quantity,
      block.number,
      true,
      PurchaseStatus.Accepted,
      msg.sender
    );
    ++_purchaseCount;

    if (!_clientPurchasedProduct[msg.sender]) {
      _allClients.push(msg.sender);
      _clientPurchasedProduct[msg.sender] = true;
    }

    emit ProductBought(msg.sender, productId, productId, quantity);
  }

  /// @notice Allows clients to return products if they are not satisfied (within a certain period in blocktime: 100 blocks).
  /// @param productId: The ID of the product to be returned
  function returnProductById(
    uint256 productId
  ) external onlyPossibleAddedProduct(productId) {
    Purchase memory returnPurchase = _clientProductIdPurchases[msg.sender][
      productId
    ];

    if (!returnPurchase.isPurchased) revert NoSuchPurchaseExists();
    if (returnPurchase.status == PurchaseStatus.Returned)
      revert TheProductReturned();
    if (
      block.number - returnPurchase.blockNumber >
      PERIOD_RETURN_PRODUCT_BLOCK_NUMBER
    ) revert BlockNumber100Exceeded();

    _products[productId].quantity += returnPurchase.quantity;
    _clientProductIdPurchases[msg.sender][productId].status = PurchaseStatus
      .Returned;

    emit ProductReturned(msg.sender, productId, returnPurchase.quantity);
  }

  /// @notice Allows the administrator (owner) to view information about а purchase.
  /// @param client: The address of the client who placed the purchase
  /// @param productId: The product ID of the purchase
  function getPurchaseInfo(
    address client,
    uint256 productId
  )
    external
    view
    onlyOwner
    onlyPossibleAddedProduct(productId)
    returns (Purchase memory)
  {
    return _clientProductIdPurchases[client][productId];
  }

  /// @notice Allows users to see all products
  function getAllProducts() external view returns (Product[] memory) {
    return _products;
  }

  /// @notice Allows the users see the addresses of all clients that have ever bought a given product.
  function getAllClients() external view returns (address[] memory) {
    return _allClients;
  }

  /// @notice Allows the administrator (owner) to see the total number of products.
  function getProductCount() external view onlyOwner returns (uint256) {
    return _productCount;
  }

  /// @notice Allows the administrator (owner) to see the total number of purchase.
  function getPurchaseCount() external view onlyOwner returns (uint256) {
    return _purchaseCount;
  }
}