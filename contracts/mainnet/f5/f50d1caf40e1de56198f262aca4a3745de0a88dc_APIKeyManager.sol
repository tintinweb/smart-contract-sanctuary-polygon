// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";

contract APIKeyManager is Ownable, ReentrancyGuard {

  /****************************************
   * Structs
   ****************************************/
  struct KeyDef {
    uint256 startTime;  // seconds
    uint256 expiryTime; // seconds
    uint256 realizationTime; // seconds
    address owner;
    uint64 tierId;
  }

  struct Tier {
    uint256 price; // price per second
    bool active;
  }

  /****************************************
   * Events
   ****************************************/
  event ActivateKey(bytes32 indexed keyHash, address indexed owner, uint256 duration);
  event ExtendKey(bytes32 indexed keyHash, uint256 duration);
  event ReactivateKey(bytes32 indexed keyHash, uint256 duration);
  event DeactivateKey(bytes32 indexed keyHash);
  event AddTier(uint64 indexed tierId, uint256 price);
  event ArchiveTier(uint64 indexed tierId);
  event Withdraw(address indexed owner, uint256 balance);
  
  /****************************************
   * ERC20 Token
   ****************************************
   * @dev
   * This is the address for the token that 
   * will be accepted for key payment.
   ****************************************/
  IERC20 public erc20;

  /****************************************
   * Key Tiers
   ****************************************
   * Tier Definition mapping
   ****************************************/
  mapping(uint64 => Tier) private _tier;

  /****************************************
   * Current number of tiers
   ****************************************/
  uint64 private _numTiers = 0;

  /****************************************
   * Key Hash Map
   ****************************************
   * @dev
   * Maps the API key hashes to their key
   * definitions.
   ****************************************/
  mapping(bytes32 => KeyDef) private _keyDef;

  /****************************************
   * Key Id Map
   ****************************************
   * @dev
   * Maps the Key ID to the key hash.
   ****************************************/
  mapping(uint256 => bytes32) private _keyHash;

  /****************************************
   * Address to Key Hash Map
   ****************************************
   * @dev
   * Maps an address to the key hashes that
   * it controls.
   ****************************************/
  mapping(address => bytes32[]) private _addressKeyHashes;

  /****************************************
   * Current number of keys
   ****************************************/
  uint256 private _numKeys = 0;

  /****************************************
   * Realized Profit
   ****************************************
   * @dev
   * Profit that has been realized, but not
   * yet withdrawn.
   ****************************************/
  uint256 private _realizedProfit = 0;

  /****************************************
   * Constructor
   ****************************************/
  constructor(
    IERC20 _erc20
  ) Ownable() ReentrancyGuard() {
    erc20 = _erc20;
  }

  /****************************************
   * Modifiers
   ****************************************/
  modifier _keyExists(bytes32 keyHash) {
    require(keyExists(keyHash), "APIKM: key does not exist");
    _;
  }

  modifier _tierExists(uint64 tierId) {
    require(tierId < _numTiers, "APIKM: tier does not exist");
    _;
  }

  /****************************************
   * Internal Functions
   ****************************************/

  /**
    @dev Accepts an ERC20 payment for the given amount from
    the message sender if the allowance permits.
  */
  function acceptPayment(uint256 amount) internal {
    uint256 _allowance = IERC20(erc20).allowance(_msgSender(), address(this));
    require(_allowance >= amount, "APIKM: low token allowance");
    IERC20(erc20).transferFrom(_msgSender(), address(this), amount);
  }

  /****************************************
   * Public Functions
   ****************************************/

  /**
    @dev Checks if the given tier is active.
  */
  function isTierActive(uint64 tierId) public view _tierExists(tierId) returns(bool) {
    return _tier[tierId].active;
  }

  /**
    @dev Returns the price of a given tier.
  */
  function tierPrice(uint64 tierId) public view _tierExists(tierId) returns(uint256) {
    return _tier[tierId].price;
  }
  
  /**
    @dev Returns the current number of tiers.
    (active and archived)
  */
  function numTiers() public view returns(uint64) {
    return _numTiers;
  }

  /**
    @dev Returns the current number of keys created.
    (active and not active)
  */
  function numKeys() public view returns(uint256) {
    return _numKeys;
  }

  /**
    @dev Returns the realized profit that is
    waiting for withdrawal.
  */
  function realizedProfit() public view returns(uint256) {
    return _realizedProfit;
  }

  /**
    @dev Checks if the key with the given hash has been activated
    at any point.
  */
  function keyExists(bytes32 keyHash) public view returns(bool) {
    return _keyDef[keyHash].owner != address(0);
  }

  /**
    @dev Determines if the key with the given hash is active.
  */
  function isKeyActive(bytes32 keyHash) public view _keyExists(keyHash) returns(bool) {
    return _keyDef[keyHash].expiryTime > block.timestamp;
  }

  /**
    @dev Calculates the used balance for a given key.
  */
  function usedBalance(bytes32 keyHash) public view _keyExists(keyHash) returns(uint256) {
    uint256 realizationTime = _keyDef[keyHash].realizationTime;
    uint256 expiryTime = _keyDef[keyHash].expiryTime;
    uint256 timestamp = block.timestamp;

    // Only consider up to the expiry time of the key:
    if(expiryTime < timestamp) {
      timestamp = expiryTime;
    }

    // Return zero if timestamp is less or equal to last realization:
    if(timestamp <= realizationTime) {
      return 0;
    }

    // Calculate used balance:
    return ((timestamp - realizationTime) * tierPrice(_keyDef[keyHash].tierId));
  }

  /**
    @dev Calculates the remaining balance for the key with the
    given hash.
  */
  function remainingBalance(bytes32 keyHash) public view _keyExists(keyHash) returns(uint256) {
    if(!isKeyActive(keyHash)) {
      return 0;
    } else {
      uint256 _remainingTime = _keyDef[keyHash].expiryTime - block.timestamp;
      return _remainingTime * tierPrice(_keyDef[keyHash].tierId);
    }
  }

  /**
    @dev Realizes the used balance of the key as profit.
  */
  function realizeProfit(bytes32 keyHash) public _keyExists(keyHash) {
    uint256 realizedBalance = usedBalance(keyHash);
    _keyDef[keyHash].realizationTime = block.timestamp;
    _realizedProfit += realizedBalance;
  }

  /**
    @dev Returns the key info for the given hash.
  */
  function keyInfo(bytes32 keyHash) public view _keyExists(keyHash) returns(KeyDef memory) {
    return _keyDef[keyHash];
  }

  /**
    @dev Returns the key hash for the given key ID.
  */
  function keyHashOf(uint256 keyId) public view returns(bytes32) {
    require(keyId < _numKeys, "APIKM: nonexistent keyId");
    return _keyHash[keyId];
  }

  /****************************************
   * External Functions
   ****************************************/

  /**
    @dev Returns an array of key hashes controlled by the given address.
  */
  function keyHashesOf(address controller) external view returns(bytes32[] memory) {
    return _addressKeyHashes[controller];
  }

  /**
    @dev Activates a new key with the given hash. Accepts payment
    for the initial duration at the target tier price.
  */
  function activateKey(bytes32 keyHash, uint256 secDuration, uint64 tierId) external nonReentrant() {
    require(!keyExists(keyHash), "APIKM: key exists");
    require(isTierActive(tierId), "APIKM: inactive tier");

    // Get target tier price:
    uint256 _tierPrice = tierPrice(tierId);

    // Accept erc20 payment for _tierPrice * secDuration:
    uint256 _amount = _tierPrice * secDuration;
    if(_amount > 0) {
      acceptPayment(_amount);
    }

    // Initialize Key:
    _keyHash[_numKeys++] = keyHash;
    _keyDef[keyHash].expiryTime = block.timestamp + secDuration;
    _keyDef[keyHash].startTime = block.timestamp;
    _keyDef[keyHash].realizationTime = block.timestamp;
    _keyDef[keyHash].tierId = tierId;
    _keyDef[keyHash].owner = _msgSender();

    // Append key hash to address control list:
    _addressKeyHashes[_msgSender()].push(keyHash);

    // Emit activation event:
    emit ActivateKey(keyHash, _msgSender(), secDuration);
  }

  /**
    @dev Extends the lifetime of (or reactivates if expired) a key by
    accepting a new deposit to the key balance.
  */
  function extendKey(bytes32 keyHash, uint256 secDuration) external _keyExists(keyHash) nonReentrant() {
    require(_keyDef[keyHash].owner == _msgSender(), "APIKM: not owner");
    uint64 tierId = _keyDef[keyHash].tierId;
    require(isTierActive(tierId), "APIKM: inactive tier");

    // Get target tier price:
    uint256 _tierPrice = tierPrice(tierId);

    // Accept erc20 payment for _tierPrice * secDuration:
    uint256 _amount = _tierPrice * secDuration;
    if(_amount > 0) {
      acceptPayment(_amount);
    }

    // Realize the used balance of the key as profit:
    realizeProfit(keyHash);

    // Check the key's state:
    if(isKeyActive(keyHash)) {

      // Extend the key:
      _keyDef[keyHash].expiryTime += secDuration;

      // Emit extension event:
      emit ExtendKey(keyHash, secDuration);
    } else {

      // Reactivate the key:
      _keyDef[keyHash].startTime = block.timestamp;
      _keyDef[keyHash].expiryTime = block.timestamp + secDuration;

      // Emit reactivation event:
      emit ReactivateKey(keyHash, secDuration);
    }    
  }

  /**
    @dev Deactivates a key and returns the unused balance to 
    the key controller.
  */
  function deactivateKey(bytes32 keyHash) external _keyExists(keyHash) nonReentrant() {
    require(_keyDef[keyHash].owner == _msgSender(), "APIKM: not owner");
    require(isKeyActive(keyHash), "APIKM: key not active");

    // Calculate remaining balance:
    uint256 _remainingBalance = remainingBalance(keyHash);

    // Realize the used balance of the key as profit:
    realizeProfit(keyHash);

    // Expire key:
    _keyDef[keyHash].expiryTime = block.timestamp;

    // Send erc20 payment to controller:
    if(_remainingBalance > 0) {
      IERC20(erc20).transfer(_msgSender(), _remainingBalance);
    }

    // Emit deactivation event:
    emit DeactivateKey(keyHash);
  }

  /**
    @dev Appends a new tier with the given price per second.
  */
  function addTier(uint256 price) external onlyOwner {
    uint64 tierId = _numTiers++;
    _tier[tierId].price = price;
    _tier[tierId].active = true;
    emit AddTier(tierId, price);
  }

  /**
    @dev Archives the given tier. This tier will no longer be
    available for key creation or renewal.
  */
  function archiveTier(uint64 tierId) external onlyOwner _tierExists(tierId) {
    _tier[tierId].active = false;
    emit ArchiveTier(tierId);
  }

  /**
    @dev Calculates the total unrealized profit.
  */
  function unrealizedProfit() external view returns(uint256) {
    uint256 balance = 0;
    for(uint256 id = 0; id < _numKeys; id++) {
      balance += usedBalance(_keyHash[id]);
    }
    return balance;
  }

  /**
    @dev Finds an array of keyHashes and corresponding unrealized amounts
    that fit the given criteria.

    NOTE: If less hashes than `count` are found, then the remainder of
    the arrays will be filled with zero values.
  */
  function findUnrealizedAccounts(uint256 count, uint256 minAmount, bool expiredOnly) external view returns(bytes32[] memory, uint256[] memory) {
    bytes32[] memory keyHashes = new bytes32[](count);
    uint256[] memory amounts = new uint256[](count);
    uint256 found = 0;
    for(uint256 id = 0; id < _numKeys && found < count; id++) {
      if(!(expiredOnly && _keyDef[_keyHash[id]].expiryTime > block.timestamp) && _keyDef[_keyHash[id]].realizationTime < _keyDef[_keyHash[id]].expiryTime) {
        uint256 unrealizedAmount = usedBalance(_keyHash[id]);
        if(unrealizedAmount >= minAmount) {
          uint256 index = found++;
          keyHashes[index] = _keyHash[id];
          amounts[index] = unrealizedAmount;
        }
      }
    }
    return (keyHashes, amounts);
  }

  /**
    @dev Withdraws the realized profit.
  */
  function withdraw() external nonReentrant() onlyOwner {

    // Transfer realized profit:
    uint256 profit = _realizedProfit;
    require(profit > 0, "APIKM: no profit");
    _realizedProfit = 0;
    IERC20(erc20).transfer(owner(), profit);

    // Emit withdraw event:
    emit Withdraw(owner(), profit);
  }

}