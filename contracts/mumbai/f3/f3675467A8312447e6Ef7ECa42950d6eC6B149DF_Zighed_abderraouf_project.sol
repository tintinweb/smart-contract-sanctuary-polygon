// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Zighed_abderraouf_project is Ownable {
    enum State {
        Manufactured,
        AtManufacturer,
        AtDistributor,
        AtRetailer,
        SoldOut
    }

    struct CosmeticItem {
        bytes32 itemId;
        bytes32 batchId;
        bool sold;
        address consumer;
    }

    struct CosmeticBatch {
        bytes32 batchId;
        string brand;
        string item;
        address manufacturer;
        address distributor;
        address retailer;
        State state;
        mapping(uint => CosmeticItem) items;
        uint itemCount;
        bool hasOwnerApproval;
    }

    mapping(bytes32 => CosmeticBatch) private batchIdToCosmeticBatch;

    // events
    event CosmeticsAdded(
        bytes32 indexed batchId,
        string brand,
        string item,
        uint itemCount,
        address manufacturer
    );
    event ManufacturerAssigned(
        bytes32 indexed batchId,
        address indexed manufacturer
    );
    event DistributorAssigned(
        bytes32 indexed batchId,
        address indexed distributor
    );
    event RetailerAssigned(bytes32 indexed batchId, address indexed retailer);
    event GotOwnerApproval(bytes32 indexed batchId);
    event MarkedReadyToPurchase(bytes32 indexed batchId);
    event ItemSold(bytes32 batchId, uint itemId);

    // modifiers
    modifier OnlyManufacturer(bytes32 _batchId) {
        CosmeticBatch storage batch = batchIdToCosmeticBatch[_batchId];
        require(
            batch.manufacturer == msg.sender,
            "Caller is not the Manufacturer"
        );
        _;
    }

    modifier OnlyDistributor(bytes32 _batchId) {
        CosmeticBatch storage batch = batchIdToCosmeticBatch[_batchId];
        require(
            batch.distributor == msg.sender,
            "Caller is not the Distributor"
        );
        _;
    }

    modifier OnlyRetailer(bytes32 _batchId) {
        CosmeticBatch storage batch = batchIdToCosmeticBatch[_batchId];
        require(batch.retailer == msg.sender, "Caller is not the Retailer");
        _;
    }

    // functions

    function addCosmetics(
        string memory brand,
        string memory item,
        uint itemCount
    ) external {
        bytes32 batchId = keccak256(
            abi.encodePacked(
                msg.sender,
                block.timestamp,
                brand,
                item,
                itemCount
            )
        );

        CosmeticBatch storage cosmeticBatch = batchIdToCosmeticBatch[batchId];
        cosmeticBatch.batchId = batchId;
        cosmeticBatch.brand = brand;
        cosmeticBatch.item = item;
        cosmeticBatch.manufacturer = msg.sender;
        cosmeticBatch.state = State.Manufactured;
        cosmeticBatch.itemCount = itemCount;

        for (uint i = 0; i < itemCount; i++) {
            bytes32 itemId = keccak256(abi.encodePacked(batchId, i));
            cosmeticBatch.items[i] = CosmeticItem(
                itemId,
                batchId,
                false,
                address(0)
            );
        }

        emit CosmeticsAdded(batchId, brand, item, itemCount, msg.sender);
    }

    function giveApprovalToBatch(bytes32 _batchId) external onlyOwner {
        CosmeticBatch storage batch = batchIdToCosmeticBatch[_batchId];
        require(batch.batchId == _batchId, "Invalid cosmetics batchId");
        batch.hasOwnerApproval = true;
        emit GotOwnerApproval(_batchId);
    }

    function assignDistributor(
        address _distributor,
        bytes32 _batchId
    ) external OnlyManufacturer(_batchId) {
        CosmeticBatch storage batch = batchIdToCosmeticBatch[_batchId];
        require(batch.batchId == _batchId, "Invalid cosmetics batchId");
        require(batch.hasOwnerApproval, "Has no owner approval");

        batch.distributor = _distributor;
        batch.state = State.AtManufacturer;
        emit DistributorAssigned(_batchId, _distributor);
    }

    function assignRetailer(
        address _retailer,
        bytes32 _batchId
    ) external OnlyDistributor(_batchId) {
        CosmeticBatch storage batch = batchIdToCosmeticBatch[_batchId];
        require(batch.batchId == _batchId, "Invalid cosmetics batchId");
        require(batch.hasOwnerApproval, "Has no owner approval");

        batch.retailer = _retailer;
        batch.state = State.AtDistributor;
        emit RetailerAssigned(_batchId, _retailer);
    }

    function markReadyToPurchase(
        bytes32 _batchId
    ) public OnlyRetailer(_batchId) {
        CosmeticBatch storage batch = batchIdToCosmeticBatch[_batchId];
        require(batch.batchId == _batchId, "Invalid cosmetics batchId");
        require(batch.hasOwnerApproval, "Has no owner approval");

        batch.state = State.AtRetailer;

        emit MarkedReadyToPurchase(_batchId);
    }

    function sellItem(
        bytes32 _batchId,
        uint _itemId,
        address consumer
    ) external OnlyRetailer(_batchId) {
        CosmeticBatch storage batch = batchIdToCosmeticBatch[_batchId];
        require(batch.batchId == _batchId, "Invalid cosmetics batchId");
        require(batch.hasOwnerApproval, "Has no owner approval");

        CosmeticItem storage item = batch.items[_itemId];
        require(!item.sold, "Item already sold");

        item.sold = true;
        item.consumer = consumer;

        bool allItemsSold = true;
        for (uint i = 0; i < batch.itemCount; i++) {
            if (!batch.items[i].sold) {
                allItemsSold = false;
                break;
            }
        }

        if (allItemsSold) {
            batch.state = State.SoldOut;
        }

        emit ItemSold(_batchId, _itemId);
    }

    function getCosmetics(
        bytes32 _batchId
    )
        public
        view
        returns (
            string memory,
            string memory,
            address,
            address,
            address,
            uint8,
            uint,
            bool
        )
    {
        CosmeticBatch storage batch = batchIdToCosmeticBatch[_batchId];

        require(batch.batchId == _batchId, "Invalid cosmetics batchId");

        return (
            batch.brand,
            batch.item,
            batch.manufacturer,
            batch.distributor,
            batch.retailer,
            uint8(batch.state),
            batch.itemCount,
            batch.hasOwnerApproval
        );
    }

    function getCosmeticItemDetails(
        bytes32 _batchId,
        uint _itemId
    ) public view returns (bytes32, bytes32, bool, address) {
        CosmeticBatch storage batch = batchIdToCosmeticBatch[_batchId];
        CosmeticItem storage item = batch.items[_itemId];

        require(batch.batchId == _batchId, "Invalid cosmetics batchId");

        return (item.itemId, item.batchId, item.sold, item.consumer);
    }
}