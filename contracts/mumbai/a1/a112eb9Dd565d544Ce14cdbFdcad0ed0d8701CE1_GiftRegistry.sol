// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IGiftRegistry.sol";

// @title Gift Registry
contract GiftRegistry is IGiftRegistry, Ownable {

  event GiftRegistered(address giftBox, address recipient);

  mapping(address => bool) internal allowedGiftBoxFactories; // List of Supported Gift Box Factories

  mapping(address => address[]) internal register; // Recipients -> GiftBoxes
  mapping(address => address[]) internal conservators; // Registered Conservators -> GiftBox addresses
  mapping(address => address[]) internal watched; // Users -> Boxes Gifted/Watched

  // @name Register a new GiftBoxFactory
  function registerAllowedGiftBoxFactory(address _factory) external onlyOwner {
    allowedGiftBoxFactories[_factory] = true;
  }

  // @name Deregister a deprecated GiftBoxFactory
  function deregisterAllowedGiftBoxFactory(address _factory) external onlyOwner {
    allowedGiftBoxFactories[_factory] = false;
  }

  // @name Register GiftBox
  function registerGiftBox(address _recipient, address _giftBox) public {
    require(allowedGiftBoxFactories[msg.sender], "Caller not an allowed GiftBoxFactory");
    register[_recipient].push(_giftBox);
    emit GiftRegistered(_giftBox, _recipient);
  }

  // @name Register Conservator
  // @dev Used when first setting up the box
  function registerConservator(address _giftBox, address _conservator) public {
    require(allowedGiftBoxFactories[msg.sender], "Caller not an allowed GiftBoxFactory");
    conservators[_conservator].push(_giftBox);
  }

  // @name Register New Conservator
  // @dev Used when a conservator adds another conservator
  function registerNewConservator(address _conservator) public {
    conservators[_conservator].push(msg.sender);
  }

  // @name Register Watcher
  // @notice Watch a created box
  // @dev Used by factory when creating the box
  function registerWatcher(address _giftBox, address _watcher) public {
    require(allowedGiftBoxFactories[msg.sender], "Caller not an allowed GiftBoxFactory");
    watched[_watcher].push(_giftBox);
  }

  // @name Watch Gift Box
  // @notice Watch an already created box
  function watchGiftBox(address _giftBox) public {
    //TODO: dont allow duplicates?
    watched[msg.sender].push(_giftBox);
  }

  // @name Deregister Gift Box
  // @notice The GiftBox must call this method
  // @dev O(n) where n is number of gift boxes registered
  function deregisterGiftBox(address _recipient) external {
    // Remove from registry
    address[] storage boxes = register[_recipient];
    // Remove if found (first one, no need to iterate)
    if(boxes[0] == msg.sender){
      boxes[0] = boxes[boxes.length - 1];
      boxes.pop();
      return;
    }
    uint256 index;
    for(uint256 i = 1; i < boxes.length; i++){
      if(boxes[i] == msg.sender){
        index = i;
        break;
      }
    }
    // Remove if found, err if not
    if(index == 0 && msg.sender != boxes[0]){
      revert("GiftBox not registered");
    }
    boxes[index] = boxes[boxes.length - 1];
    boxes.pop();
  }

  // @name Deregister Conservator
  // @notice The GiftBox must call this method
  // @dev O(n) where n is number of gift boxes managed by the conservator
  function deregisterConservator(address _conservator) external {
    address[] storage managedGiftBoxes = conservators[_conservator];
    // Remove if found (first one, no need to iterate)
    if(managedGiftBoxes[0] == msg.sender){
      managedGiftBoxes[0] = managedGiftBoxes[managedGiftBoxes.length - 1];
      managedGiftBoxes.pop();
      return;
    }
    uint256 index = 0;
    for(uint256 i = 1; i < managedGiftBoxes.length; i++){
      if(managedGiftBoxes[i] == msg.sender){
        index = i;
        break;
      }
    }
    // Remove if found
    if(index == 0){
      revert("Conservator not managing this GiftBox");
    }
    managedGiftBoxes[index] = managedGiftBoxes[managedGiftBoxes.length - 1];
    managedGiftBoxes.pop();
  }

  // @name Lookup Gift Boxes
  function lookupGiftBoxes() external view returns (address[] memory){
    return register[msg.sender];
  }

  // @name Lookup Conservator Boxes
  function lookupConservatorBoxes() external view returns (address[] memory){
    return conservators[msg.sender];
  }

  // @name Lookup Watched Gift Boxes
  function lookupWatchedGiftBoxes() external view returns (address[] memory){
    return watched[msg.sender];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IGiftRegistry {

  function registerGiftBox(address _recipient, address _giftBox) external;
  function registerConservator(address _giftBox, address _conservator) external;
  function registerNewConservator(address _conservator) external;
  function registerWatcher(address _giftBox, address _watcher) external;
  function watchGiftBox(address _giftBox) external;

  function deregisterGiftBox(address _recipient) external;
  function deregisterConservator(address _conservator) external;
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