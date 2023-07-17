/**
 *Submitted for verification at polygonscan.com on 2023-07-17
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        
        
        

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https:
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https:
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https:
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https:
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                
                
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        
        if (returndata.length > 0) {
            
            
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

pragma solidity ^0.8.2;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * 
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

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
 * https:
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    
    
    
    
    

    
    
    
    
    
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        
        
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https:
     */
    uint256[49] private __gap;
}

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
     * https:
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

pragma solidity >=0.4.22 <0.9.0;

struct LuckBuyItemTemplate {
  uint256 itemID ; 
  address tokenContract ; 
  uint256 totalAmount ; 
  uint256 price ; 
  bool restart ; 
  uint256 period ; 
  bool online ; 
}

struct LuckBuyItem {
  uint256 itemID ; 
  address tokenContract ; 
  uint256 totalAmount ; 
  uint256 price ; 
  bool restart ; 
  uint256 period ; 
  uint256 startTime ; 
  uint256 endTime ; 
  address[] buyers ; 
  address[] buyerSets ; 
  address[] rewardUserSets; 
  mapping (address=>uint256) buyQuantity; 
  mapping (address=>uint256) rewardAmount; 
}

struct LuckBuyItemData {
  uint256 itemID ; 
  address tokenContract ; 
  uint256 totalAmount ; 
  uint256 price ; 
  uint256 period ; 
  uint256 startTime ; 
  uint256 endTime ; 
  uint256 userCount ; 
  uint256 quantity ; 
  uint256 ownerQuantity; 
  bool timeout ; 
  bool finished ; 
}

pragma solidity >=0.4.22 <0.9.0;

contract LuckBuyStorage {

  address private logicContract; 
  uint256[] private itemIDs; 
  mapping (uint256=>LuckBuyItem) private items; 

  constructor(address _logic) {
    logicContract = _logic;
  }

  
  modifier onlyLogicContract() {
    
    _;
  }

  function getItemIDs() public view returns (uint256[] memory) {
    uint256[] memory itemArray = new uint256[](itemIDs.length);
    for(uint256 i = 0; i < itemIDs.length; i++) {
      itemArray[i] = itemIDs[i];
    }
    return itemArray;
  }

  
  function getItemList(address player) public view returns (LuckBuyItemData[] memory) {
    LuckBuyItemData[] memory itemArray = new LuckBuyItemData[](itemIDs.length);
    for(uint i = 0; i < itemIDs.length; i++) {
      LuckBuyItem storage item = items[itemIDs[i]];
      itemArray[i] = LuckBuyItemData(
        item.itemID, 
        item.tokenContract,
        item.totalAmount, 
        item.price, 
        item.period, 
        item.startTime,
        item.endTime,
        item.buyerSets.length,
        item.buyers.length,
        item.buyQuantity[player],
        checkTimeout(item.itemID),
        checkFinished(item.itemID)
      );
    }
    return itemArray;
  }

  
  function getItem(address player, uint256 itemID) public view returns (LuckBuyItemData memory item) {
    LuckBuyItem storage _item = items[itemID];
    return LuckBuyItemData(
      _item.itemID, 
      _item.tokenContract,
      _item.totalAmount, 
      _item.price, 
      _item.period, 
      _item.startTime,
      _item.endTime,
      _item.buyerSets.length,
      _item.buyers.length,
      _item.buyQuantity[player],
      checkTimeout(itemID),
      checkFinished(itemID)
      );
  }

  
  function checkItemExist(uint256 itemID) public view returns (bool) {
    return items[itemID].itemID != 0;
  }

  
  function checkFinished(uint256 itemID) public view returns (bool) {
    if(items[itemID].itemID == 0) return false; 
    return items[itemID].buyers.length >= (items[itemID].totalAmount / items[itemID].price);
  }

  
  function checkTimeout(uint256 itemID) public view returns (bool) {
    if(items[itemID].itemID == 0) return false; 
    if(items[itemID].buyers.length >= (items[itemID].totalAmount / items[itemID].price)) return false; 
    return block.timestamp >= items[itemID].endTime;
  }

  
  function addItem(uint256 itemID, address tokenContract, uint256 totalAmount, uint256 price, uint256 period) public onlyLogicContract returns (bool) {
    require(items[itemID].itemID == 0, "item already exist");
    items[itemID].itemID = itemID;
    items[itemID].tokenContract = tokenContract;
    items[itemID].totalAmount = totalAmount;
    items[itemID].price = price;
    items[itemID].restart = true;  
    items[itemID].period = period;
    items[itemID].startTime = block.timestamp;
    items[itemID].endTime = block.timestamp + period;
    itemIDs.push(itemID);
    return true;
  }

  
  function delItem(uint256 itemID) public onlyLogicContract returns (bool) {
    require(items[itemID].itemID != 0, "item not exist");
    items[itemID].restart = false; 
    return true;
  }

  
  function cleanItem(uint256 itemID) public onlyLogicContract returns (bool){
    require(items[itemID].itemID != 0, "item not exist"); 
    if (items[itemID].restart) { 
      address tokenContract = items[itemID].tokenContract;
      uint256 totalAmount = items[itemID].totalAmount;
      uint256 price = items[itemID].price;
      bool restart = items[itemID].restart;
      uint256 period = items[itemID].period;
      
      delete items[itemID];
      
      items[itemID].itemID = itemID;
      items[itemID].tokenContract = tokenContract;
      items[itemID].totalAmount = totalAmount;
      items[itemID].price = price;
      items[itemID].restart = restart;
      items[itemID].period = period;
      items[itemID].startTime = block.timestamp;
      items[itemID].endTime = block.timestamp + period;

    } else { 
      delete items[itemID];
      for (uint256 i = 0; i < itemIDs.length; i++) {
        if (itemIDs[i] == itemID) {
          delete itemIDs[i];
          break;
        }
      }
    }
    return true;
  }
  
  
  function buyItem(uint256 itemID, address buyer, uint256 quantity) public onlyLogicContract returns (bool){
    require(items[itemID].itemID != 0, "item not exist"); 
    require(items[itemID].startTime <= block.timestamp, "item not start"); 
    require(items[itemID].endTime >= block.timestamp, "item already end"); 
    require(items[itemID].buyers.length + quantity <= (items[itemID].totalAmount / items[itemID].price), "item not enough"); 
    items[itemID].buyers.push(buyer);
    if (items[itemID].buyQuantity[buyer] == 0) { 
      items[itemID].buyerSets.push(buyer);  
    }
    items[itemID].buyQuantity[buyer] += quantity;
    return true;
  }

  
  function addRewardUser(uint256 itemID, address user, uint256 amount) public onlyLogicContract returns (bool){
    require(items[itemID].itemID != 0, "item not exist"); 
    require(items[itemID].buyQuantity[user] > 0, "item not buy"); 
    if (items[itemID].rewardAmount[user] == 0) { 
      items[itemID].rewardUserSets.push(user);  
    }
    items[itemID].rewardAmount[user] += amount;
    return true;
  }

  
  function transfer(address tokenContract, address to, uint256 amount) public onlyLogicContract returns (bool){
    if (tokenContract == address(0)) { 
      payable(to).transfer(amount);
    } else { 
      IERC20(tokenContract).transfer(to, amount);
    }
    return true;
  }

  
  function refundItem(uint256 itemID) public onlyLogicContract returns (bool) {
    require(items[itemID].itemID != 0, "item not exist"); 
    require(items[itemID].startTime <= block.timestamp, "item not start"); 
    require(items[itemID].endTime <= block.timestamp, "item not end"); 
    require(items[itemID].buyers.length < (items[itemID].totalAmount / items[itemID].price), "item already enough"); 
    for (uint256 i = 0; i < items[itemID].buyerSets.length; i++) {
      address buyer = items[itemID].buyerSets[i];
      uint256 quantity = items[itemID].buyQuantity[buyer];
      uint256 amount = quantity * items[itemID].price;
      transfer(items[itemID].tokenContract, buyer, amount); 
    }
    cleanItem(itemID); 
    return true;
  }

  function rewardItem(uint256 itemID,uint256 winnerIndex, uint256 bonusRate, address platform) public onlyLogicContract returns (bool, address, uint256) {
    require(items[itemID].itemID != 0, "item not exist"); 
    require(items[itemID].startTime <= block.timestamp, "item not start"); 
    require(items[itemID].buyers.length >= (items[itemID].totalAmount / items[itemID].price), "item not enough"); 
    uint256 balance = items[itemID].totalAmount;
    uint256 bonus = items[itemID].totalAmount * bonusRate / 100;
    address winner = items[itemID].buyers[winnerIndex];
    transfer(items[itemID].tokenContract, winner, bonus); 
    balance -= bonus;
    for (uint256 i = 0; i < items[itemID].rewardUserSets.length; i++) {
      address user = items[itemID].rewardUserSets[i];
      uint256 amount = items[itemID].rewardAmount[user];
      transfer(items[itemID].tokenContract, user, amount); 
      balance -= amount;
    }
    cleanItem(itemID); 
    
    transfer(items[itemID].tokenContract, platform, balance);
    return (true, winner, bonus);
  }

  receive() external payable {
    
  }

}

pragma solidity >=0.4.22 <0.9.0;

contract LuckBuyLogic is ReentrancyGuardUpgradeable {

  
  event BuyItem(address indexed user, uint256 indexed itemID, uint256 quantity);

  
  function storageAddress() internal pure returns (address) {
    return 0x55EB85969FC2C7E00F2816C610A98850893911aE;
  }

  
  function storageContract() internal pure returns (LuckBuyStorage) {
    return LuckBuyStorage(payable(storageAddress()));
  }

  function getKingAddress() internal pure returns (address) {
    return 0x0fc81F797E98e1A97243eD35CBfb59Db021338c2;
  }

   
  function getBaseDecimals() public pure returns (uint256) {
    return 4; 
  }

  
  function getInviteRate() public pure returns (uint256) {
    return 10**2; 
  }

  
  function getBaseRate() public pure returns (uint256) {
    return 10**getBaseDecimals();
  }

  
  function getItemTemplates() public pure returns (LuckBuyItemTemplate[] memory) {
    LuckBuyItemTemplate[] memory items = new LuckBuyItemTemplate[](10);
    items[0] = LuckBuyItemTemplate(1, address(0x0), 5 ether, 1 ether, true, 1 days, true);
    items[1] = LuckBuyItemTemplate(2, address(0x0), 10 ether, 1 ether, true, 20 seconds, true);
    items[2] = LuckBuyItemTemplate(3, address(0x0), 20 ether, 1 ether, true, 1 days, true);
    items[3] = LuckBuyItemTemplate(4, address(0x0), 50 ether, 1 ether, true, 1 days, true);
    items[4] = LuckBuyItemTemplate(5, address(0x0), 100 ether, 1 ether, true, 1 days, true);
    items[5] = LuckBuyItemTemplate(6, address(0x0), 200 ether, 1 ether, true, 1 days, true);
    items[6] = LuckBuyItemTemplate(7, address(0x0), 500 ether, 1 ether, true, 1 days, true);
    items[7] = LuckBuyItemTemplate(8, address(0x0), 1000 ether, 1 ether, true, 1 days, true);
    items[8] = LuckBuyItemTemplate(9, address(0x0), 2000 ether, 1 ether, true, 1 days, true);
    items[9] = LuckBuyItemTemplate(10, address(0x0), 5000 ether, 1 ether, true, 1 days, true);
    
    return items;
  }

  
  function initItems() public {
    LuckBuyItemTemplate[] memory itemArray = getItemTemplates();
    for (uint256 i = 0; i < itemArray.length; i++) {
      LuckBuyItemTemplate memory item = itemArray[i];
      if(! storageContract().checkItemExist(item.itemID) && item.online) { 
        assert(storageContract().addItem(item.itemID, item.tokenContract, item.totalAmount, item.price, item.period));
      } else if (!item.online) { 
        assert(storageContract().delItem(item.itemID));
      }
    }
  }

  
  function getItemList(address player) public view returns (LuckBuyItemData[] memory itemArray) {
    return storageContract().getItemList(player);
  }

  
  function buyItem(uint256 itemID, uint256 quantity, address inviter) public payable {
    address buyer = msg.sender;
    LuckBuyItemData memory item = storageContract().getItem(buyer, itemID);
    uint256 amount = item.price * quantity;
    require(item.itemID > 0, "Item not exist"); 
    require(!item.finished, "Item is finished"); 
    require(!item.timeout, "Item is timeout"); 
    if(item.tokenContract == address(0)) { 
      require(msg.value == amount, "amount error"); 
      
      payable(storageAddress()).transfer(msg.value);
    } else {
      IERC20 token = IERC20(item.tokenContract);
      require(token.balanceOf(buyer) >= amount, "Token balance error"); 
      require(token.allowance(buyer, address(this)) >= amount, "Token allowance error"); 
      
      token.transferFrom(buyer, storageAddress(), item.price * quantity);
    }
    assert(storageContract().buyItem(itemID, buyer, quantity)); 
    if (inviter != address(0)) { 
      assert(storageContract().addRewardUser(itemID, buyer, amount * getInviteRate() / getBaseRate()));
    }
    emit BuyItem(buyer, itemID, quantity);
  }

  
  function checkItemsSettle() public view returns (bool) {
    LuckBuyItemData[] memory itemArray = storageContract().getItemList(address(0));
    for (uint256 i = 0; i < itemArray.length; i++) {
      LuckBuyItemData memory item = itemArray[i];
      if(item.finished || item.timeout) {
        return true;
      }
    }
    return false;
  }

  
  function settleItems() public nonReentrant {
    LuckBuyItemData[] memory itemArray = storageContract().getItemList(address(0));
    for (uint256 i = 0; i < itemArray.length; i++) {
      LuckBuyItemData memory item = itemArray[i];

      if(item.finished) {
        bool result;
        address winnerAddress;
        uint256 bonus;
        uint256 winnerIndex = uint(keccak256(abi.encodePacked(
        block.timestamp, block.prevrandao, 
        blockhash(block.number), msg.sender, item.itemID
      ))) % item.quantity;
        (result, winnerAddress, bonus) = storageContract().rewardItem(item.itemID, winnerIndex, 95, getKingAddress());
        assert(result);
      } else if(item.timeout) {
        assert(storageContract().refundItem(item.itemID));
      }
    }
  }

}