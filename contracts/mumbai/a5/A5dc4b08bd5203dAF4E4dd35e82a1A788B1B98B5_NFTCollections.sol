//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTCollections is Ownable {
  using Counters for Counters.Counter;
  Counters.Counter private _collectionIds;

  // Status of a collection (0: created, 1: published, 2: cancelled, 3: requestPlanUpgrade)

  struct CollectionData {
    CollectionInfo collectionInfo;
    MintingInfo mintingInfo;
    ContactData contactData;
    MarketplaceInfo marketplaceInfo;
    PaymentInfo paymentInfo;
    string[] tags;
    uint256 status;
  }

  struct CollectionInfo {
    address owner;
    uint256 id;
    string name;
    string description;
    string imageURI;
    string blockchain;
    uint256 totalSupply;
  }

  struct MintingInfo {
    uint256 mintDate;
    uint256 price;
  }

  struct ContactData {
    string websiteURL;
    string twitter;
    string discord;
    string email;
  }

  struct PaymentInfo {
    string paymentPlan;
    bool isVariablePaymentPlan;
  }

  struct MarketplaceInfo {
    string openseaURL;
  }

  struct PaymentPlanHistory {
    uint256 startDate;
    string paymentPlan;
    string paymentTxHash;
  }

  mapping(uint256 => CollectionData) collections;
  mapping(address => bool) hasCollection;
  mapping(uint256 => PaymentPlanHistory[]) paymentPlanHistory;

  event PaymentPlanHistoryAdded(
    uint256 collectionId, 
    uint256 startDate, 
    string paymentPlan,
    string paymentTxHash
  );

  event CollectionCreated(
    address owner,
    uint256 id,
    string name,
    string description,
    string imageURI,
    string blockchain,
    uint256 totalSupply,
    uint256 mintDate,
    uint256 price
  );

  event CollectionContactCreated(
    uint256 id,
    string websiteURL,
    string twitter,
    string discord,
    string email,
    string openseaURL,
    string[] tags,
    string paymentPlan,
    bool isVariablePaymentPlan,
    uint256 status
  );

  event CollectionUpdated(
    uint256 id,
    string name, 
    string description, 
    string imageURI,
    string blockchain,
    uint256 totalSupply, 
    uint256 mintDate, 
    uint256 price,
    string[] contactData,
    string[] marketplaceData,
    string[] tags
  );

  event CollectionPublished(
    uint256 id,
    string paymentPlan,
    uint256 status
  );

  event CollectionCancelled(
    uint256 id,
    uint256 status
  );

  event CollectionRequestPlanUpgrade(
    uint256 id, 
    string paymentPlan,
    uint256 status
  );

  event StartVariablePaymentPlan(
    uint256 id,
    bool isVariablePaymentPlan
  );

  event EndVariablePaymentPlan(
    uint256 id,
    bool isVariablePaymentPlan
  );

  modifier onlyOneCollectionByWallet() {
    require(hasCollection[msg.sender] == false, "Only one collection can be created per wallet");
    _;
  }

  modifier onlyOwnerOfCollection(uint256 _collectionId) {
    require(collections[_collectionId].collectionInfo.owner == msg.sender, "Only the owner of the collection can perform this action");
    _;
  }

  function createCollection(
    string memory _name, 
    string memory _description, 
    string memory _imageURI,
    string memory _blockchain,
    uint256 _totalSupply, 
    uint256 _mintDate, 
    uint256 _price,
    string[] memory _contactData,
    string[] memory _marketplaceData,
    string[] memory _tags,
    string[] memory _paymentInfo
  ) public onlyOneCollectionByWallet {
    _collectionIds.increment();

    CollectionData memory collectionData = CollectionData(
      CollectionInfo(
        msg.sender,
        _collectionIds.current(),
        _name,
        _description,
        _imageURI,
        _blockchain,
        _totalSupply
      ),
      MintingInfo(
        _mintDate,
        _price
      ),
      ContactData(
        _contactData[0],
        _contactData[1],
        _contactData[2],
        _contactData[3]
      ),
      MarketplaceInfo(
        _marketplaceData[0]
      ),
      PaymentInfo(
        _paymentInfo[0],
        false
      ),
      _tags,
      0
    );

    collections[_collectionIds.current()] = collectionData;
    hasCollection[msg.sender] = true;

    PaymentPlanHistory memory _paymentPlanHistory = PaymentPlanHistory(
      0,
      _paymentInfo[0],
      _paymentInfo[1]
    );
    paymentPlanHistory[_collectionIds.current()].push(_paymentPlanHistory);

    emit PaymentPlanHistoryAdded(_collectionIds.current(), 0, _paymentInfo[0], _paymentInfo[1]);

    emit CollectionCreated(
      msg.sender,
      _collectionIds.current(),
      _name,
      _description,
      _imageURI,
      _blockchain,
      _totalSupply,
      _mintDate,
      _price
    );

    emit CollectionContactCreated(
      _collectionIds.current(),
      _contactData[0],
      _contactData[1],
      _contactData[2],
      _contactData[3],
      _marketplaceData[0],
      _tags,
      _paymentInfo[0],
      false,
      0
    );
  }

  function editCollection(
    uint256 _collectionId,
    string memory _name, 
    string memory _description, 
    string memory _imageURI,
    string memory _blockchain,
    uint256 _totalSupply, 
    uint256 _mintDate, 
    uint256 _price,
    string[] memory _contactData,
    string[] memory _marketplaceData,
    string[] memory _tags
  ) public onlyOwnerOfCollection(_collectionId) {
    CollectionData memory collectionData = collections[_collectionId];
    collectionData.collectionInfo.name = _name;
    collectionData.collectionInfo.description = _description;
    collectionData.collectionInfo.imageURI = _imageURI;
    collectionData.collectionInfo.blockchain = _blockchain;
    collectionData.collectionInfo.totalSupply = _totalSupply;
    collectionData.mintingInfo.mintDate = _mintDate;
    collectionData.mintingInfo.price = _price;
    collectionData.contactData.websiteURL = _contactData[0];
    collectionData.contactData.twitter = _contactData[1];
    collectionData.contactData.discord = _contactData[2];
    collectionData.contactData.email = _contactData[3];
    collectionData.marketplaceInfo.openseaURL = _marketplaceData[0];
    collectionData.tags = _tags;
    collections[_collectionId] = collectionData;

    emit CollectionUpdated(
      _collectionId,
      _name,
      _description,
      _imageURI,
      _blockchain,
      _totalSupply,
      _mintDate,
      _price,
      _contactData,
      _marketplaceData,
      _tags
    );
  }

  function upgradePlan(uint256 _collectionId, string memory _paymentPlan, string memory _paymentTxHash) public onlyOwnerOfCollection(_collectionId) {
    CollectionData memory collectionData = collections[_collectionId];
    PaymentPlanHistory memory _paymentPlanHistory = PaymentPlanHistory(
      0,
      _paymentPlan,
      _paymentTxHash
    );
    paymentPlanHistory[_collectionId].push(_paymentPlanHistory);
    collectionData.status = 3;
    collections[_collectionId] = collectionData;

    emit PaymentPlanHistoryAdded(_collectionId, 0, _paymentPlan, _paymentTxHash);

    emit CollectionRequestPlanUpgrade(
      _collectionId,
      _paymentPlan,
      3
    );
  }

  function publishCollection(uint256 _collectionId) public onlyOwner {
    CollectionData memory collectionData = collections[_collectionId];
    paymentPlanHistory[_collectionId][paymentPlanHistory[_collectionId].length - 1].startDate = block.timestamp;
    if (!collectionData.paymentInfo.isVariablePaymentPlan) {
      collectionData.paymentInfo.paymentPlan = paymentPlanHistory[_collectionId][paymentPlanHistory[_collectionId].length - 1].paymentPlan;
    }
    collectionData.status = 1;
    collections[_collectionId] = collectionData;

    emit PaymentPlanHistoryAdded(
      _collectionId, 
      block.timestamp, 
      paymentPlanHistory[_collectionId][paymentPlanHistory[_collectionId].length - 1].paymentPlan,
      paymentPlanHistory[_collectionId][paymentPlanHistory[_collectionId].length - 1].paymentTxHash
    );

    emit CollectionPublished(
      _collectionId,
      collectionData.paymentInfo.paymentPlan,
      1
    );
  }

  function cancelCollection(uint256 _collectionId) public onlyOwner {
    CollectionData memory collectionData = collections[_collectionId];
    collectionData.status = 2;
    collections[_collectionId] = collectionData;

    emit CollectionCancelled(
      _collectionId,
      2
    );
  }

  function startVariablePaymentPlan(uint256 _collectionId) public onlyOwner {
    CollectionData memory collectionData = collections[_collectionId];
    collectionData.paymentInfo.isVariablePaymentPlan = true;
    collections[_collectionId] = collectionData;

    emit StartVariablePaymentPlan(
      _collectionId,
      true
    );
  }

  function endVariablePaymentPlan(uint256 _collectionId) public onlyOwner {
    CollectionData memory collectionData = collections[_collectionId];
    collectionData.paymentInfo.isVariablePaymentPlan = false;
    collections[_collectionId] = collectionData;

    emit EndVariablePaymentPlan(
      _collectionId,
      false
    );
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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