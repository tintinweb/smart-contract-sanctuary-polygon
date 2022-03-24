// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./utils/IBalanceVault.sol";
import "./utils/IItemVault.sol";

/**
 * @dev Smart Contract let user buy and sell their game items.
 * Has a function to initialize values in upgradable Smart Contract.
 * Has a function to set and get publication fee when user creates a order in marketpalce.
 * Has a function to set share owner will get when user successfully sell an item.
 * Has a function to create order to sell item on marketpalce.
 * Has a function to cancel order on marketplace.
 * Has a function to execute(buy) order in marketplace.
 * The purpose of this function is for user to able to buy or sell item in our platform.
 */
contract Marketplace is OwnableUpgradeable,ReentrancyGuardUpgradeable {


    /**
     * @dev use interface to set vault
     * IBalanceVault - set intetface for vaultBalance
     * IItemVault - set intetface for vaultItem
    */
    address public _Owner;
    IBalanceVault public vaultBalance;
    IItemVault public vaultItem;

    bool internal _paused;

    struct Order {
        bytes32 id;
        address seller;
        uint256 itemId;
        uint256 itemAmount;
        uint256 price;
    } 

    mapping (address => mapping(bytes32 => Order)) public orderByOrderId;
    uint256 public ownerCutPerMillion;
    uint256 public publicationFeeInWei;
  
    bytes32 public constant VAULT_ADMIN = keccak256("VAULT_ADMIN");
    
    /**
     * @dev Declare event for use emit `SetVaultBalanceAddress`, `SetVaultItemAddress`, `OrderCreated`, `OrderCancelled`, `OrderExecuted`, `OrderDetail`, `MarketplacePaused`, `MarketplaceUnpaused`, `ChangePublicationFee`, `ChangeOwnerCutPerMillion`.
     */
    event SetVaultBalanceAddress(address indexed vaultAddress);
    event SetVaultItemAddress(address indexed vaultAddress);
    event OrderCreated(bytes32 orderId, address indexed seller, uint256 itemId, uint256 itemAmount, uint256 nakaAmountToitem);
    event OrderCancelled(bytes32 orderId, address indexed seller, uint256 itemId, uint256 itemAmount);
    event OrderExecuted(bytes32 orderId, address indexed buyer, address indexed seller, uint256 itemId, uint256 itemAmount, uint256 buyItemAmount ,uint256 totalPriceNaka,uint256 ownerCutPerMillion);
    event OrderDetail(bytes32 orderId, address indexed seller, uint256 itemId, uint256 itemAmount, uint256 nakaAmount);
    event ChangePublicationFee(uint256 newPublicationFeeInWei);
    event ChangeOwnerCutPerMillion(uint256 newOwnerCutPerMillion);
   
  
    event MarketplacePaused();
    event MarketplaceUnpaused();

    /*
     * Network: Polygon Mainnet
     */
    /** 
    * @dev Sets the value of the `admin`, `tokenAddress`, `publicationFeeInWeiNFT` and `ownerCutPerMillionNFT`.
    * @param _vaultBalanceAddress - balance vault address.
    * @param _vaultItemAddress - item vault address.
    * @param _publicationFee - publication fee when create order.
    * @param _ownerCutPerMillion - share sent to owner when order successfully executed.
    * @param _owner - admin address.
    */
    function initialize(
         address _vaultBalanceAddress,
         address _vaultItemAddress,
         uint256 _publicationFee,
         uint256 _ownerCutPerMillion,
         address _owner
    ) public initializer {
        vaultBalance = IBalanceVault(_vaultBalanceAddress);
        // emit SetVaultBalanceAddress(address(vaultBalance));

        vaultItem = IItemVault(_vaultItemAddress);
        // emit SetVaultItemAddress(address(vaultItem));

        // _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _Owner = _owner;

        publicationFeeInWei = _publicationFee;
        // setOwnerCutPerMillion(publicationFeeInWei);
        
        ownerCutPerMillion = _ownerCutPerMillion;
        // setOwnerCutPerMillion(ownerCutPerMillion);

      ///@dev as there is no constructor, we need to initialise the OwnableUpgradeable explicitly
       __Ownable_init();
   }

    /**
    * @dev Modifier to only allow the function to be executed when it isn't paused.
    */
    modifier whenMarketplaceNotPaused() {
        require(!_paused, "[Marketplace.whenMarketplaceNotPaused] Not Paused");
        _;
    }

    /**
    * @dev Modifier to only allow the function to be executed when it is paused.
    */
    modifier whenMarketplacePaused() {
        require(_paused, "[Marketplace.whenMarketplacePaused] Paused");
        _;
    }
   
    /**
     * @dev Set publication fee that will be sent to admin when create order on marketplace
     * Emit value of publication fee.
     * Can only be called by owner.
     * @param _publicationFee - publication fee
     */
    function setPublicationFee(uint256 _publicationFee) external onlyOwner {
        publicationFeeInWei = _publicationFee;
        emit ChangePublicationFee(publicationFeeInWei);
    }

    /**
     * @dev Get publicationFeeInWei's value.
     */
    function getPublicationFee() external view returns (uint256) {
        return publicationFeeInWei;
    }
  
    /**
     * @dev Set share per million that will be sent to admin when an order is successfully executed.
     * Emit value of ownerCutPerMillionNFT.
     * Can only be called by owner.
     * @param _ownerCutPerMillion - share that will be cut per million
     */
    function setOwnerCutPerMillion(uint256 _ownerCutPerMillion) public onlyOwner {
        require(_ownerCutPerMillion < 1000000, "The owner cut should be between 0 and 999,999");

        ownerCutPerMillion = _ownerCutPerMillion;
        emit ChangeOwnerCutPerMillion(ownerCutPerMillion);
    }

    /**
     * @dev Get ownerCutPerMillion's value.
     */
    function getOwnerCutPerMillion() external view returns(uint256) {
        return ownerCutPerMillion;
    }

    /**
     * @dev Create order on marketplace for selling item.
     * Emit details of createded Order.
     * @param _itemId - item id of specific item.
     * @param _itemAmount - amount of item to sell.
     * @param _nakaAmount - Naka token amount of each items user want to sell.
     * @return order - creaded order
     */
    function createOrder (uint256 _itemId, uint256 _itemAmount, uint256 _nakaAmount) public whenMarketplaceNotPaused returns (Order memory) {
            bytes32 _orderId = keccak256(
                abi.encodePacked(
                block.timestamp,
                _itemId,
                msg.sender,
                _nakaAmount
            )
        );

        vaultItem.decreaseItem(msg.sender, _itemId, _itemAmount);

        if (publicationFeeInWei >= 0) {
            vaultBalance.decreaseBalance(msg.sender,publicationFeeInWei);
            vaultBalance.increaseBalance(_Owner,publicationFeeInWei);
        }

        Order memory order = orderByOrderId[msg.sender][_orderId] = Order({
            id: _orderId,
            seller: msg.sender,
            itemId: _itemId,
            itemAmount:_itemAmount,
            price: _nakaAmount
        });

        emit OrderCreated(_orderId, msg.sender, _itemId, _itemAmount, _nakaAmount);

        return order;
    }

    /**
     * @dev Cancel order on marketplace.
     * Emit details of canceled Order.
     * @param _sellerAccount - seller's address
     * @param _orderId - order id in marketpalce
     * @return order - cancelled order
     */
    function cancelOrder(address _sellerAccount ,bytes32 _orderId) public whenMarketplaceNotPaused returns (Order memory) {
        Order memory order = orderByOrderId[_sellerAccount][_orderId] ;

        require(order.id != 0, "Asset not published");
        require(order.seller == msg.sender, "Unauthorized user");

        vaultItem.increaseItem(order.seller, order.itemId, order.itemAmount);
        delete orderByOrderId[order.seller][_orderId];

        emit OrderCancelled(order.id, order.seller, order.itemId, order.itemAmount);

        return order;
    }
   
    /**
     * @dev Execute order on marketplace.
     * Emit details of executed Order.
     * @param _sellerAccount - seller's address
     * @param _orderId - order id in marketpalce
     * @param _itemAmount - itemAmount to buy
     * @return order - cancelled order
     */
    function executeOrder(address _sellerAccount, bytes32 _orderId , uint256 _itemAmount) public whenMarketplaceNotPaused returns (Order memory) {
        uint saleShareAmount = 0;
        
        Order memory order = orderByOrderId[_sellerAccount][_orderId];
        require(order.id != 0, "Asset not published");
        require (order.itemAmount >= _itemAmount, "Item in order not enough");
        order.itemAmount -= _itemAmount;
        orderByOrderId[_sellerAccount][_orderId] = Order({
            id: order.id,
            seller: order.seller,
            itemId: order.itemId,
            itemAmount: order.itemAmount,
            price: order.price
        });
        uint totalPrice  = order.price * _itemAmount;
        vaultBalance.decreaseBalance(msg.sender,totalPrice);
        vaultItem.increaseItem(msg.sender,order.itemId,_itemAmount);
        vaultBalance.increaseBalance(order.seller,totalPrice);
        
        
        if (ownerCutPerMillion >= 0) {
            saleShareAmount = (totalPrice *(ownerCutPerMillion))/(1000000);
            vaultBalance.decreaseBalance(order.seller,saleShareAmount);
            vaultBalance.increaseBalance(_Owner,saleShareAmount);
        }

        if(order.itemAmount == 0){
            delete orderByOrderId[_sellerAccount][_orderId];
        }

        emit OrderExecuted(order.id, msg.sender, order.seller, order.itemId, order.itemAmount, _itemAmount ,totalPrice, saleShareAmount);
        return order;
    }

    /**
     * @dev Get info of an order
     * Emit order detail
     * @param _sellerAccount - seller's address
     * @param _orderId - order id in marketpalce
     * @return order - cancelled order
     */
    function getOrderInfo(address _sellerAccount, bytes32 _orderId) external returns (Order memory) {
        Order memory order = orderByOrderId[_sellerAccount][_orderId];

        require(order.id != 0, "Asset not published");

        emit OrderDetail(order.id, order.seller, order.itemId, order.itemAmount, order.price);

        return order;
    }

    /**
    * @dev Function to pause functions in this contract.
    * can only be called by the creator of contract.
    */
    function pauseMarketplace() external onlyOwner whenMarketplaceNotPaused {
        _paused = true;
        emit MarketplacePaused();
    }

    /**
    * @dev Function to unpause functions in this contract.
    * can only be called by the creator of contract.
    */
    function unpauseMarketplace() external onlyOwner whenMarketplacePaused {
        _paused = false;
        emit MarketplaceUnpaused();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IBalanceVault{
    function depositNaka(uint256 _nakaAmount) external;

    function withdrawNaka(uint256 _nakaAmount) external;

    function increaseBalance(address _userAddress, uint256 _nakaAmount) external;

    function decreaseBalance(address _userAddress, uint256 _nakaAmount) external;

    function getBalance(address _address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IItemVault{
    function increaseItem(address _userAddress, uint256 _itemId, uint256 _itemAmount) external;

    function decreaseItem(address _userAddress, uint256 _itemId, uint256 _itemAmount) external;

    function getItemAmountbyId(address _userAddress, uint256 _itemId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}