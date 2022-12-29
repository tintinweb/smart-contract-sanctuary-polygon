// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import { IUnlockV11 } from "@unlock-protocol/contracts/dist/Unlock/IUnlockV11.sol";
import { IPublicLockV12 } from "@unlock-protocol/contracts/dist/PublicLock/IPublicLockV12.sol";

import { IERC20 } from "../interfaces/IERC20.sol";

// TODO: This could be removed if the IUnlockV11 ABI if fixed:
// https://github.com/unlock-protocol/unlock/issues/9877#issuecomment-1366758727
interface IUnlockV11Impl {
    function publicLockImpls(uint16 _version) external view returns (address _impl);
}

/// @title UnlockFactory
/// @author Coinvise
contract UnlockFactory {
    struct Lock {
        string _lockName;
        string _lockSymbol;
        string _baseTokenURI;
        address _lockCreator;
    }

    address public unlockAddress;
    address public coinviseFeeReferrer;
    uint16 public feeBPS;

    event LockDeployed(address indexed implementation, address lock, address indexed deployer);

    constructor(
        address _unlockAddress,
        address _coinviseFeeReferrer,
        uint16 _feeBPS
    ) {
        unlockAddress = _unlockAddress;
        coinviseFeeReferrer = _coinviseFeeReferrer;
        feeBPS = _feeBPS;
    }

    function deployLock(
        uint16 version,
        bytes calldata data,
        Lock calldata _lock
    ) external returns (address) {
        IUnlockV11 unlock = IUnlockV11(unlockAddress);

        IPublicLockV12 lock = IPublicLockV12(unlock.createUpgradeableLockAtVersion(data, version));

        lock.setReferrerFee(coinviseFeeReferrer, feeBPS);
        lock.setLockMetadata(_lock._lockName, _lock._lockSymbol, _lock._baseTokenURI);
        lock.setOwner(_lock._lockCreator);
        lock.addLockManager(_lock._lockCreator);
        lock.addKeyGranter(_lock._lockCreator);
        lock.revokeKeyGranter(address(this));
        lock.renounceLockManager();

        emit LockDeployed(IUnlockV11Impl(unlockAddress).publicLockImpls(version), address(lock), msg.sender);

        return address(lock);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <0.9.0;


/**
 * @title The Unlock Interface
**/

interface IUnlockV11
{
  // Use initialize instead of a constructor to support proxies(for upgradeability via zos).
  function initialize(address _unlockOwner) external;

  /**
  * @dev deploy a ProxyAdmin contract used to upgrade locks
  */
  function initializeProxyAdmin() external;

  // store contract proxy admin address
  function proxyAdminAddress() external view;

  /**
  * @notice Create lock (legacy)
  * This deploys a lock for a creator. It also keeps track of the deployed lock.
  * @param _expirationDuration the duration of the lock (pass 0 for unlimited duration)
  * @param _tokenAddress set to the ERC20 token address, or 0 for ETH.
  * @param _keyPrice the price of each key
  * @param _maxNumberOfKeys the maximum nimbers of keys to be edited
  * @param _lockName the name of the lock
  * param _salt [deprec] -- kept only for backwards copatibility
  * This may be implemented as a sequence ID or with RNG. It's used with `create2`
  * to know the lock's address before the transaction is mined.
  * @dev internally call `createUpgradeableLock`
  */
  function createLock(
    uint _expirationDuration,
    address _tokenAddress,
    uint _keyPrice,
    uint _maxNumberOfKeys,
    string calldata _lockName,
    bytes12 // _salt
  ) external returns(address);

  /**
  * @notice Create lock (default)
  * This deploys a lock for a creator. It also keeps track of the deployed lock.
  * @param data bytes containing the call to initialize the lock template
  * @dev this call is passed as encoded function - for instance:
  *  bytes memory data = abi.encodeWithSignature(
  *    'initialize(address,uint256,address,uint256,uint256,string)',
  *    msg.sender,
  *    _expirationDuration,
  *    _tokenAddress,
  *    _keyPrice,
  *    _maxNumberOfKeys,
  *    _lockName
  *  );
  * @return address of the create lock
  */
  function createUpgradeableLock(
    bytes memory data
  ) external returns(address);

  /**
   * Create an upgradeable lock using a specific PublicLock version
   * @param data bytes containing the call to initialize the lock template
   * (refer to createUpgradeableLock for more details)
   * @param _lockVersion the version of the lock to use
  */
  function createUpgradeableLockAtVersion(
    bytes memory data,
    uint16 _lockVersion
  ) external returns (address);

  /**
  * @notice Upgrade a lock to a specific version
  * @dev only available for publicLockVersion > 10 (proxyAdmin /required)
  * @param lockAddress the existing lock address
  * @param version the version number you are targeting
  * Likely implemented with OpenZeppelin TransparentProxy contract
  */
  function upgradeLock(
    address payable lockAddress, 
    uint16 version
  ) external returns(address);

    /**
   * This function keeps track of the added GDP, as well as grants of discount tokens
   * to the referrer, if applicable.
   * The number of discount tokens granted is based on the value of the referal,
   * the current growth rate and the lock's discount token distribution rate
   * This function is invoked by a previously deployed lock only.
   */
  function recordKeyPurchase(
    uint _value,
    address _referrer // solhint-disable-line no-unused-vars
  )
    external;

    /**
   * @notice [DEPRECATED] Call to this function has been removed from PublicLock > v9.
   * @dev [DEPRECATED] Kept for backwards compatibility
   * This function will keep track of consumed discounts by a given user.
   * It will also grant discount tokens to the creator who is granting the discount based on the
   * amount of discount and compensation rate.
   * This function is invoked by a previously deployed lock only.
   */
  function recordConsumedDiscount(
    uint _discount,
    uint _tokens // solhint-disable-line no-unused-vars
  )
    external;

    /**
   * @notice [DEPRECATED] Call to this function has been removed from PublicLock > v9.
   * @dev [DEPRECATED] Kept for backwards compatibility
   * This function returns the discount available for a user, when purchasing a
   * a key from a lock.
   * This does not modify the state. It returns both the discount and the number of tokens
   * consumed to grant that discount.
   */
  function computeAvailableDiscountFor(
    address _purchaser, // solhint-disable-line no-unused-vars
    uint _keyPrice // solhint-disable-line no-unused-vars
  )
    external
    view
    returns(uint discount, uint tokens);

  // Function to read the globalTokenURI field.
  function globalBaseTokenURI()
    external
    view
    returns(string memory);

  /**
   * @dev Redundant with globalBaseTokenURI() for backwards compatibility with v3 & v4 locks.
   */
  function getGlobalBaseTokenURI()
    external
    view
    returns (string memory);

  // Function to read the globalTokenSymbol field.
  function globalTokenSymbol()
    external
    view
    returns(string memory);

  // Function to read the chainId field.
  function chainId()
    external
    view
    returns(uint);

  /**
   * @dev Redundant with globalTokenSymbol() for backwards compatibility with v3 & v4 locks.
   */
  function getGlobalTokenSymbol()
    external
    view
    returns (string memory);

  /**
   * @notice Allows the owner to update configuration variables
   */
  function configUnlock(
    address _udt,
    address _weth,
    uint _estimatedGasForPurchase,
    string calldata _symbol,
    string calldata _URI,
    uint _chainId
  )
    external;

  /**
   * @notice Add a PublicLock template to be used for future calls to `createLock`.
   * @dev This is used to upgrade conytract per version number
   */
  function addLockTemplate(address impl, uint16 version) external;

  // match lock templates addresses with version numbers
  function publicLockImpls(uint16 _version) external view;
  
  // match version numbers with lock templates addresses 
  function publicLockVersions(address _impl) external view;

  // the latest existing lock template version
  function publicLockLatestVersion() external view;

  /**
   * @notice Upgrade the PublicLock template used for future calls to `createLock`.
   * @dev This will initialize the template and revokeOwnership.
   */
  function setLockTemplate(
    address payable _publicLockAddress
  ) external;

  // Allows the owner to change the value tracking variables as needed.
  function resetTrackedValue(
    uint _grossNetworkProduct,
    uint _totalDiscountGranted
  ) external;

  function grossNetworkProduct() external view returns(uint);

  function totalDiscountGranted() external view returns(uint);

  function locks(address) external view returns(bool deployed, uint totalSales, uint yieldedDiscountTokens);

  // The address of the public lock template, used when `createLock` is called
  function publicLockAddress() external view returns(address);

  // Map token address to exchange contract address if the token is supported
  // Used for GDP calculations
  function uniswapOracles(address) external view returns(address);

  // The WETH token address, used for value calculations
  function weth() external view returns(address);

  // The UDT token address, used to mint tokens on referral
  function udt() external view returns(address);

  // The approx amount of gas required to purchase a key
  function estimatedGasForPurchase() external view returns(uint);

  /**
   * Helper to get the network mining basefee as introduced in EIP-1559
   * @dev this helper can be wrapped in try/catch statement to avoid 
   * revert in networks where EIP-1559 is not implemented
   */
  function networkBaseFee() external view returns (uint);

  // The version number of the current Unlock implementation on this network
  function unlockVersion() external pure returns(uint16);

  /**
   * @notice allows the owner to set the oracle address to use for value conversions
   * setting the _oracleAddress to address(0) removes support for the token
   * @dev This will also call update to ensure at least one datapoint has been recorded.
   */
  function setOracle(
    address _tokenAddress,
    address _oracleAddress
  ) external;

  /**
   * Initialize the Ownable contract, granting contract ownership to the specified sender 
   */ 
  function __initializeOwnable(address sender) external;

  /**
   * @dev Returns true if the caller is the current owner.
   * @return bool True of the caller is the owner
   */
  function isOwner() external view returns(bool);

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() external view returns(address);

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() external;

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <0.9.0;
pragma experimental ABIEncoderV2;

/**
* @title The PublicLock Interface
*/


interface IPublicLockV12
{

  /// Functions
  function initialize(
    address _lockCreator,
    uint _expirationDuration,
    address _tokenAddress,
    uint _keyPrice,
    uint _maxNumberOfKeys,
    string calldata _lockName
  ) external;


  // roles
  function DEFAULT_ADMIN_ROLE() external view returns (bytes32 role);
  function KEY_GRANTER_ROLE() external view returns (bytes32 role);
  function LOCK_MANAGER_ROLE() external view returns (bytes32 role);

  /**
  * @notice The version number of the current implementation on this network.
  * @return The current version number.
  */
  function publicLockVersion() external pure returns (uint16);

  /**
   * @dev Called by lock manager to withdraw all funds from the lock
   * @param _tokenAddress specifies the token address to withdraw or 0 for ETH. This is usually
   * the same as `tokenAddress` in MixinFunds.
   * @param _recipient specifies the address that will receive the tokens
   * @param _amount specifies the max amount to withdraw, which may be reduced when
   * considering the available balance. Set to 0 or MAX_UINT to withdraw everything. 
   * -- however be wary of draining funds as it breaks the `cancelAndRefund` and `expireAndRefundFor` use cases.
   */
  function withdraw(
    address _tokenAddress,
    address payable _recipient,
    uint _amount
  ) external;

  /**
   * A function which lets a Lock manager of the lock to change the price for future purchases.
   * @dev Throws if called by other than a Lock manager
   * @dev Throws if lock has been disabled
   * @dev Throws if _tokenAddress is not a valid token
   * @param _keyPrice The new price to set for keys
   * @param _tokenAddress The address of the erc20 token to use for pricing the keys,
   * or 0 to use ETH
   */
  function updateKeyPricing( uint _keyPrice, address _tokenAddress ) external;

  /**
   * Update the main key properties for the entire lock: 
   * 
   * - default duration of each key
   * - the maximum number of keys the lock can edit
   * - the maximum number of keys a single address can hold
   *
   * @notice keys previously bought are unaffected by this changes in expiration duration (i.e.
   * existing keys timestamps are not recalculated/updated)
   * @param _newExpirationDuration the new amount of time for each key purchased or type(uint).max for a non-expiring key
   * @param _maxKeysPerAcccount the maximum amount of key a single user can own
   * @param _maxNumberOfKeys uint the maximum number of keys
   * @dev _maxNumberOfKeys Can't be smaller than the existing supply 
   */
   function updateLockConfig(
    uint _newExpirationDuration,
    uint _maxNumberOfKeys,
    uint _maxKeysPerAcccount
  ) external;

  /**
   * Checks if the user has a non-expired key.
   * @param _user The address of the key owner
   */
  function getHasValidKey(
    address _user
  ) external view returns (bool);

  /**
  * @dev Returns the key's ExpirationTimestamp field for a given owner.
  * @param _tokenId the id of the key
  * @dev Returns 0 if the owner has never owned a key for this lock
  */
  function keyExpirationTimestampFor(
    uint _tokenId
  ) external view returns (uint timestamp);
  
  /**
   * Public function which returns the total number of unique owners (both expired
   * and valid).  This may be larger than totalSupply.
   */
  function numberOfOwners() external view returns (uint);

  /**
   * Allows the Lock owner to assign 
   * @param _lockName a descriptive name for this Lock.
   * @param _lockSymbol a Symbol for this Lock (default to KEY).
   * @param _baseTokenURI the baseTokenURI for this Lock
   */
  function setLockMetadata(
    string calldata _lockName,
    string calldata _lockSymbol,
    string calldata _baseTokenURI
  ) external;

  /**
   * @dev Gets the token symbol
   * @return string representing the token symbol
   */
  function symbol() external view returns(string memory);


  /**  @notice A distinct Uniform Resource Identifier (URI) for a given asset.
   * @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
   *  3986. The URI may point to a JSON file that conforms to the "ERC721
   *  Metadata JSON Schema".
   * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
   * @param _tokenId The tokenID we're inquiring about
   * @return String representing the URI for the requested token
   */
  function tokenURI(
    uint256 _tokenId
  ) external view returns(string memory);

  /**
   * Allows a Lock manager to add or remove an event hook
   * @param _onKeyPurchaseHook Hook called when the `purchase` function is called
   * @param _onKeyCancelHook Hook called when the internal `_cancelAndRefund` function is called
   * @param _onValidKeyHook Hook called to determine if the contract should overide the status for a given address
   * @param _onTokenURIHook Hook called to generate a data URI used for NFT metadata
   * @param _onKeyTransferHook Hook called when a key is transfered
   * @param _onKeyExtendHook Hook called when a key is extended or renewed
   * @param _onKeyGrantHook Hook called when a key is granted
   */
  function setEventHooks(
    address _onKeyPurchaseHook,
    address _onKeyCancelHook,
    address _onValidKeyHook,
    address _onTokenURIHook,
    address _onKeyTransferHook,
    address _onKeyExtendHook,
    address _onKeyGrantHook
  ) external;

  /**
   * Allows a Lock manager to give a collection of users a key with no charge.
   * Each key may be assigned a different expiration date.
   * @dev Throws if called by other than a Lock manager
   * @param _recipients An array of receiving addresses
   * @param _expirationTimestamps An array of expiration Timestamps for the keys being granted
   * @return the ids of the granted tokens
   */
  function grantKeys(
    address[] calldata _recipients,
    uint[] calldata _expirationTimestamps,
    address[] calldata _keyManagers
  ) external returns (uint256[] memory);

  /**
   * Allows the Lock owner to extend an existing keys with no charge.
   * @param _tokenId The id of the token to extend
   * @param _duration The duration in secondes to add ot the key
   * @dev set `_duration` to 0 to use the default duration of the lock
   */
  function grantKeyExtension(uint _tokenId, uint _duration) external;

  /**
  * @dev Purchase function
  * @param _values array of tokens amount to pay for this purchase >= the current keyPrice - any applicable discount
  * (_values is ignored when using ETH)
  * @param _recipients array of addresses of the recipients of the purchased key
  * @param _referrers array of addresses of the users making the referral
  * @param _keyManagers optional array of addresses to grant managing rights to a specific address on creation
  * @param _data array of arbitrary data populated by the front-end which initiated the sale
  * @notice when called for an existing and non-expired key, the `_keyManager` param will be ignored 
  * @dev Setting _value to keyPrice exactly doubles as a security feature. That way if the lock owner increases the
  * price while my transaction is pending I can't be charged more than I expected (only applicable to ERC-20 when more
  * than keyPrice is approved for spending).
  * @return tokenIds the ids of the created tokens 
  */
  function purchase(
    uint256[] calldata _values,
    address[] calldata _recipients,
    address[] calldata _referrers,
    address[] calldata _keyManagers,
    bytes[] calldata _data
  ) external payable returns (uint256[] memory tokenIds);
  
  /**
  * @dev Extend function
  * @param _value the number of tokens to pay for this purchase >= the current keyPrice - any applicable discount
  * (_value is ignored when using ETH)
  * @param _tokenId the id of the key to extend
  * @param _referrer address of the user making the referral
  * @param _data arbitrary data populated by the front-end which initiated the sale
  * @dev Throws if lock is disabled or key does not exist for _recipient. Throws if _recipient == address(0).
  */
  function extend(
    uint _value,
    uint _tokenId,
    address _referrer,
    bytes calldata _data
  ) external payable;


  /**
  * Returns the percentage of the keyPrice to be sent to the referrer (in basis points)
  * @param _referrer the address of the referrer
  * @return referrerFee the percentage of the keyPrice to be sent to the referrer (in basis points)
  */
  function referrerFees(address _referrer) external view returns (uint referrerFee);
  
  /**
  * Set a specific percentage of the keyPrice to be sent to the referrer while purchasing, 
  * extending or renewing a key. 
  * @param _referrer the address of the referrer
  * @param _feeBasisPoint the percentage of the price to be used for this 
  * specific referrer (in basis points)
  * @dev To send a fixed percentage of the key price to all referrers, sett a percentage to `address(0)`
  */
  function setReferrerFee(address _referrer, uint _feeBasisPoint) external;

  /**
   * Merge existing keys
   * @param _tokenIdFrom the id of the token to substract time from
   * @param _tokenIdTo the id of the destination token  to add time
   * @param _amount the amount of time to transfer (in seconds)
   */
  function mergeKeys(uint _tokenIdFrom, uint _tokenIdTo, uint _amount) external;

  /**
   * Deactivate an existing key
   * @param _tokenId the id of token to burn
   * @notice the key will be expired and ownership records will be destroyed
   */
  function burn(uint _tokenId) external;

  /**
  * @param _gasRefundValue price in wei or token in smallest price unit
  * @dev Set the value to be refunded to the sender on purchase
  */
  function setGasRefundValue(uint256 _gasRefundValue) external;
  
  /**
  * _gasRefundValue price in wei or token in smallest price unit
  * @dev Returns the value/rpice to be refunded to the sender on purchase
  */
  function gasRefundValue() external view returns (uint256 _gasRefundValue);

  /**
   * @notice returns the minimum price paid for a purchase with these params.
   * @dev this considers any discount from Unlock or the OnKeyPurchase hook.
   */
  function purchasePriceFor(
    address _recipient,
    address _referrer,
    bytes calldata _data
  ) external view
    returns (uint);

  /**
   * Allow a Lock manager to change the transfer fee.
   * @dev Throws if called by other than a Lock manager
   * @param _transferFeeBasisPoints The new transfer fee in basis-points(bps).
   * Ex: 200 bps = 2%
   */
  function updateTransferFee(
    uint _transferFeeBasisPoints
  ) external;

  /**
   * Determines how much of a fee would need to be paid in order to
   * transfer to another account.  This is pro-rated so the fee goes 
   * down overtime.
   * @dev Throws if _tokenId does not have a valid key
   * @param _tokenId The id of the key check the transfer fee for.
   * @param _time The amount of time to calculate the fee for.
   * @return The transfer fee in seconds.
   */
  function getTransferFee(
    uint _tokenId,
    uint _time
  ) external view returns (uint);

  /**
   * @dev Invoked by a Lock manager to expire the user's key 
   * and perform a refund and cancellation of the key
   * @param _tokenId The key id we wish to refund to
   * @param _amount The amount to refund to the key-owner
   * @dev Throws if called by other than a Lock manager
   * @dev Throws if _keyOwner does not have a valid key
   */
  function expireAndRefundFor(
    uint _tokenId,
    uint _amount
  ) external;

   /**
   * @dev allows the key manager to expire a given tokenId
   * and send a refund to the keyOwner based on the amount of time remaining.
   * @param _tokenId The id of the key to cancel.
   */
  function cancelAndRefund(uint _tokenId) external;

  /**
   * Allow a Lock manager to change the refund penalty.
   * @dev Throws if called by other than a Lock manager
   * @param _freeTrialLength The new duration of free trials for this lock
   * @param _refundPenaltyBasisPoints The new refund penaly in basis-points(bps)
   */
  function updateRefundPenalty(
    uint _freeTrialLength,
    uint _refundPenaltyBasisPoints
  ) external;

  /**
   * @dev Determines how much of a refund a key owner would receive if they issued
   * @param _tokenId the id of the token to get the refund value for.
   * @notice Due to the time required to mine a tx, the actual refund amount will be lower
   * than what the user reads from this call.
   * @return refund the amount of tokens refunded
   */
  function getCancelAndRefundValue(
    uint _tokenId
  ) external view returns (uint refund);

  function addKeyGranter(address account) external;

  function addLockManager(address account) external;

  function isKeyGranter(address account) external view returns (bool);

  function isLockManager(address account) external view returns (bool);

  
 /**
   * Returns the address of the `onKeyPurchaseHook` hook.
   * @return hookAddress address of the hook
   */  
  function onKeyPurchaseHook() external view returns(address hookAddress);

  /**
   * Returns the address of the `onKeyCancelHook` hook.
   * @return hookAddress address of the hook
   */  
  function onKeyCancelHook() external view returns(address hookAddress);

  /**
   * Returns the address of the `onValidKeyHook` hook.
   * @return hookAddress address of the hook
   */  
  function onValidKeyHook() external view returns(address hookAddress);

  /**
   * Returns the address of the `onTokenURIHook` hook.
   * @return hookAddress address of the hook
   */
  function onTokenURIHook() external view returns(address hookAddress);
  
  /**
   * Returns the address of the `onKeyTransferHook` hook.
   * @return hookAddress address of the hook
   */
  function onKeyTransferHook() external view returns(address hookAddress);
  
  /**
   * Returns the address of the `onKeyExtendHook` hook.
  * @return hookAddress the address ok the hook
  */
  function onKeyExtendHook() external view returns(address hookAddress);

  /**
  * Returns the address of the `onKeyGrantHook` hook.
  * @return hookAddress the address ok the hook
  */
  function onKeyGrantHook() external view returns(address hookAddress);

  function revokeKeyGranter(address _granter) external;

  function renounceLockManager() external;

  /**
   * @return the maximum number of key allowed for a single address
   */
  function maxKeysPerAddress() external view returns (uint);

  function expirationDuration() external view returns (uint256 );

  function freeTrialLength() external view returns (uint256 );

  function keyPrice() external view returns (uint256 );

  function maxNumberOfKeys() external view returns (uint256 );

  function refundPenaltyBasisPoints() external view returns (uint256 );

  function tokenAddress() external view returns (address );

  function transferFeeBasisPoints() external view returns (uint256 );

  function unlockProtocol() external view returns (address );

  function keyManagerOf(uint) external view returns (address );

  ///===================================================================

  /**
  * @notice Allows the key owner to safely share their key (parent key) by
  * transferring a portion of the remaining time to a new key (child key).
  * @dev Throws if key is not valid.
  * @dev Throws if `_to` is the zero address
  * @param _to The recipient of the shared key
  * @param _tokenId the key to share
  * @param _timeShared The amount of time shared
  * checks if `_to` is a smart contract (code size > 0). If so, it calls
  * `onERC721Received` on `_to` and throws if the return value is not
  * `bytes4(keccak256('onERC721Received(address,address,uint,bytes)'))`.
  * @dev Emit Transfer event
  */
  function shareKey(
    address _to,
    uint _tokenId,
    uint _timeShared
  ) external;

  /**
  * @notice Update transfer and cancel rights for a given key
  * @param _tokenId The id of the key to assign rights for
  * @param _keyManager The address to assign the rights to for the given key
  */
  function setKeyManagerOf(
    uint _tokenId,
    address _keyManager
  ) external;
  
  /**
  * Check if a certain key is valid
  * @param _tokenId the id of the key to check validity
  * @notice this makes use of the onValidKeyHook if it is set
  */
  function isValidKey(
    uint _tokenId
  )
    external
    view
    returns (bool);
  
  /**
   * Returns the number of keys owned by `_keyOwner` (expired or not)
   * @param _keyOwner address for which we are retrieving the total number of keys
   * @return numberOfKeys total number of keys owned by the address
   */
  function totalKeys(address _keyOwner) external view returns (uint numberOfKeys);
  
  /// @notice A descriptive name for a collection of NFTs in this contract
  function name() external view returns (string memory _name);
  ///===================================================================

  /// From ERC165.sol
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
  ///===================================================================

  /// From ERC-721
  /**
   * In the specific case of a Lock, `balanceOf` returns only the tokens with a valid expiration timerange
   * @return balance The number of valid keys owned by `_keyOwner`
  */
  function balanceOf(address _owner) external view returns (uint256 balance);

  /**
    * @dev Returns the owner of the NFT specified by `tokenId`.
    */
  function ownerOf(uint256 tokenId) external view returns (address _owner);

  /**
    * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
    * another (`to`).
    *
    * Requirements:
    * - `from`, `to` cannot be zero.
    * - `tokenId` must be owned by `from`.
    * - If the caller is not `from`, it must be have been allowed to move this
    * NFT by either {approve} or {setApprovalForAll}.
    */
  function safeTransferFrom(address from, address to, uint256 tokenId) external;
  
  /** 
  * an ERC721-like function to transfer a token from one account to another. 
  * @param from the owner of token to transfer
  * @param to the address that will receive the token
  * @param tokenId the id of the token
  * @dev Requirements: if the caller is not `from`, it must be approved to move this token by
  * either {approve} or {setApprovalForAll}. 
  * The key manager will be reset to address zero after the transfer
  */
  function transferFrom(address from, address to, uint256 tokenId) external;

  /** 
  * Lending a key allows you to transfer the token while retaining the
  * ownerships right by setting yourself as a key manager first. 
  * @param from the owner of token to transfer
  * @param to the address that will receive the token
  * @param tokenId the id of the token
  * @notice This function can only be called by 1) the key owner when no key manager is set or 2) the key manager.
  * After calling the function, the `_recipent` will be the new owner, and the sender of the tx
  * will become the key manager.
  */
  function lendKey(address from, address to, uint tokenId) external;

  /** 
  * Unlend is called when you have lent a key and want to claim its full ownership back. 
  * @param _recipient the address that will receive the token ownership
  * @param _tokenId the id of the token
  * @dev Only the key manager of the token can call this function
  */
  function unlendKey(address _recipient, uint _tokenId) external;

  function approve(address to, uint256 tokenId) external;

  /**
  * @notice Get the approved address for a single NFT
  * @dev Throws if `_tokenId` is not a valid NFT.
  * @param _tokenId The NFT to find the approved address for
  * @return operator The approved address for this NFT, or the zero address if there is none
  */
  function getApproved(uint256 _tokenId) external view returns (address operator);

   /**
   * @dev Sets or unsets the approval of a given operator
   * An operator is allowed to transfer all tokens of the sender on their behalf
   * @param _operator operator address to set the approval
   * @param _approved representing the status of the approval to be set
   * @notice disabled when transfers are disabled
   */
  function setApprovalForAll(address _operator, bool _approved) external;

   /**
   * @dev Tells whether an operator is approved by a given keyManager
   * @param _owner owner address which you want to query the approval of
   * @param _operator operator address which you want to query the approval of
   * @return bool whether the given operator is approved by the given owner
   */
  function isApprovedForAll(address _owner, address _operator) external view returns (bool);

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

  function totalSupply() external view returns (uint256);
  function tokenOfOwnerByIndex(address _owner, uint256 index) external view returns (uint256 tokenId);

  function tokenByIndex(uint256 index) external view returns (uint256);

  /**
    * Innherited from Open Zeppelin AccessControl.sol
    */
  function getRoleAdmin(bytes32 role) external view returns (bytes32);
  function grantRole(bytes32 role, address account) external;
  function revokeRole(bytes32 role, address account) external;
  function renounceRole(bytes32 role, address account) external;
  function hasRole(bytes32 role, address account) external view returns (bool);

  /**
    * @param _tokenId the id of the token to transfer time from
    * @param _to the recipient of the new token with time
    * @param _value sends a token with _value * expirationDuration (the amount of time remaining on a standard purchase).
    * @dev The typical use case would be to call this with _value 1, which is on par with calling `transferFrom`. If the user
    * has more than `expirationDuration` time remaining this may use the `shareKey` function to send some but not all of the token.
    * @return success the result of the transfer operation
    */
  function transfer(
    uint _tokenId,
    address _to,
    uint _value
  ) external
    returns (bool success);

  /** `owner()` is provided as an helper to mimick the `Ownable` contract ABI.
    * The `Ownable` logic is used by many 3rd party services to determine
    * contract ownership - e.g. who is allowed to edit metadata on Opensea.
    * 
    * @notice This logic is NOT used internally by the Unlock Protocol and is made 
    * available only as a convenience helper.
    */
  function owner() external view returns (address owner);
  function setOwner(address account) external;
  function isOwner(address account) view external returns (bool isOwner);

  /**
  * Migrate data from the previous single owner => key mapping to 
  * the new data structure w multiple tokens.
  * @param _calldata an ABI-encoded representation of the params (v10: the number of records to migrate as `uint`)
  * @dev when all record schemas are sucessfully upgraded, this function will update the `schemaVersion`
  * variable to the latest/current lock version
  */
  function migrate(bytes calldata _calldata) external;

  /**
  * Returns the version number of the data schema currently used by the lock
  * @notice if this is different from `publicLockVersion`, then the ability to purchase, grant
  * or extend keys is disabled.
  * @dev will return 0 if no ;igration has ever been run
  */
  function schemaVersion() external view returns (uint);

  /**
   * Set the schema version to the latest
   * @notice only lock manager call call this
   */
  function updateSchemaVersion() external;

    /**
  * Renew a given token
  * @notice only works for non-free, expiring, ERC20 locks
  * @param _tokenId the ID fo the token to renew
  * @param _referrer the address of the person to be granted UDT
  */
  function renewMembershipFor(
    uint _tokenId,
    address _referrer
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IERC20 {
    /// @param _owner The address from which the balance will be retrieved
    /// @return balance the balance
    function balanceOf(address _owner) external view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) external returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return success Whether the approval was successful or not
    function approve(address _spender, uint256 _value) external returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return remaining Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}