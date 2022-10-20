// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./utils/IBalanceVault.sol";
import "./utils/IMaterialVault.sol";

/**
 * @dev Smart Contract let user buy and sell their mateirals.
 * Has a function to initialize values in upgradable Smart Contract.
 * Has a function to set and get publication fee when user creates a order in marketpalce.
 * Has a function to set share owner will get when user successfully sell an material.
 * Has a function to create order to sell material on marketpalce.
 * Has a function to cancel order on marketplace.
 * Has a function to execute(buy) order in marketplace.
 * The purpose of this function is for user to able to buy or sell material in our platform.
 */
contract MarketplaceMaterial is Ownable, AccessControl, ReentrancyGuard {

    /**
     * @dev use interface to set vault
     * IBalanceVault - set intetface for vaultBalance
     * IMaterialVault - set intetface for vaultMaterial
    */
    address public _Owner;
    IBalanceVault public vaultBalance;
    IMaterialVault public vaultMaterial;

    bool internal _paused;

    struct Order {
        bytes32 id;
        address seller;
        uint256 materialId;
        uint256 materialAmount;
        uint256 price;
    } 

    mapping (address => mapping(bytes32 => Order)) public orderByOrderId;
    uint256 public ownerCutPerMillion;
    uint256 public publicationFeeInWei;
  
    bytes32 public constant VAULT_ADMIN = keccak256("VAULT_ADMIN");
    
    /**
     * @dev Declare event for use emit `SetVaultBalanceAddressMaterial`, `SetVaultMaterialAddressMaterial`, `OrderCreatedMaterial`, `OrderCancelledMaterial`, `OrderExecutedMaterial`, `OrderDetailMaterial`, `MarketplacePaused`, `MarketplaceUnpaused`, `ChangePublicationFeeMaterial`, `ChangeOwnerCutPerMillionMaterial`.
     */
    event SetVaultBalanceAddressMaterial(address indexed vaultAddress);
    event SetVaultMaterialAddressMaterial(address indexed vaultAddress);
    event OrderCreatedMaterial(bytes32 orderId, address indexed seller, uint256 materialId, uint256 materialAmount, uint256 nakaAmountTomaterial);
    event OrderCancelledMaterial(bytes32 orderId, address indexed seller, uint256 materialId, uint256 materialAmount);
    event OrderExecutedMaterial(bytes32 orderId, address indexed buyer, address indexed seller, uint256 materialId, uint256 materialAmount, uint256 buyItemAmount ,uint256 totalPriceNaka,uint256 ownerCutPerMillion);
    event OrderDetailMaterial(bytes32 orderId, address indexed seller, uint256 materialId, uint256 materialAmount, uint256 nakaAmount);
    event ChangePublicationFeeMaterial(uint256 newPublicationFeeInWei);
    event ChangeOwnerCutPerMillionMaterial(uint256 newOwnerCutPerMillion);
   
  
    event MarketplaceMaterialPaused();
    event MarketplaceMaterialUnpaused();

    /*
     * Network: Polygon Mainnet
     */
    /** 
    * @dev Sets the value of the `admin`, `tokenAddress`, `publicationFeeInWeiNFT` and `ownerCutPerMillionNFT`.
    * @param _vaultBalanceAddress - balance vault address.
    * @param _vaultMaterialAddress - material vault address.
    * @param _publicationFee - publication fee when create order.
    * @param _ownerCutPerMillion - share sent to owner when order successfully executed.
    * @param _owner - admin address.
    */
    constructor(
         address _vaultBalanceAddress,
         address _vaultMaterialAddress,
         uint256 _publicationFee,
         uint256 _ownerCutPerMillion,
         address _owner
    ) {
        vaultBalance = IBalanceVault(_vaultBalanceAddress);
        emit SetVaultBalanceAddressMaterial(address(vaultBalance));

        vaultMaterial = IMaterialVault(_vaultMaterialAddress);
        emit SetVaultMaterialAddressMaterial(address(vaultMaterial));

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _Owner = _owner;

        publicationFeeInWei = _publicationFee;
        setOwnerCutPerMillion(publicationFeeInWei);
        
        ownerCutPerMillion = _ownerCutPerMillion;
        setOwnerCutPerMillion(ownerCutPerMillion);
   }

    /**
    * @dev Modifier to only allow the function to be executed when it isn't paused.
    */
    modifier whenMarketplaceMaterialNotPaused() {
        require(!_paused, "[Marketplace.whenMarketplaceMaterialNotPaused] Not Paused");
        _;
    }

    /**
    * @dev Modifier to only allow the function to be executed when it is paused.
    */
    modifier whenMarketplaceMaterialPaused() {
        require(_paused, "[Marketplace.whenMarketplaceMaterialPaused] Paused");
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
        emit ChangePublicationFeeMaterial(publicationFeeInWei);
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
        emit ChangeOwnerCutPerMillionMaterial(ownerCutPerMillion);
    }

    /**
     * @dev Get ownerCutPerMillion's value.
     */
    function getOwnerCutPerMillion() external view returns(uint256) {
        return ownerCutPerMillion;
    }

    /**
     * @dev Create order on marketplace for selling material.
     * Emit details of createded Order.
     * @param _materialId - material id of specific material.
     * @param _materialAmount - amount of material to sell.
     * @param _nakaAmount - Naka token amount of each materials user want to sell.
     * @return order - creaded order
     */
    function createOrderMaterial (uint256 _materialId, uint256 _materialAmount, uint256 _nakaAmount) public whenMarketplaceMaterialNotPaused returns (Order memory) {
            bytes32 _orderId = keccak256(
                abi.encodePacked(
                block.timestamp,
                _materialId,
                msg.sender,
                _nakaAmount
            )
        );

        vaultMaterial.decreaseMaterialUserSingle(_materialId, _materialAmount);

        if (publicationFeeInWei >= 0) {
            vaultBalance.decreaseBalance(msg.sender,publicationFeeInWei);
            vaultBalance.increaseBalance(_Owner,publicationFeeInWei);
        }

        Order memory order = orderByOrderId[msg.sender][_orderId] = Order({
            id: _orderId,
            seller: msg.sender,
            materialId: _materialId,
            materialAmount:_materialAmount,
            price: _nakaAmount
        });

        emit OrderCreatedMaterial(_orderId, msg.sender, _materialId, _materialAmount, _nakaAmount);

        return order;
    }

    /**
     * @dev Cancel order on marketplace.
     * Emit details of canceled Order.
     * @param _sellerAccount - seller's address
     * @param _orderId - order id in marketpalce
     * @return order - cancelled order
     */
    function cancelOrderMaterial(address _sellerAccount ,bytes32 _orderId) public whenMarketplaceMaterialNotPaused returns (Order memory) {
        Order memory order = orderByOrderId[_sellerAccount][_orderId] ;

        require(order.id != 0, "Asset not published");
        require(order.seller == msg.sender, "Unauthorized user");

        vaultMaterial.increaseMaterialUserSingle(order.seller, order.materialId, order.materialAmount);
        delete orderByOrderId[order.seller][_orderId];

        emit OrderCancelledMaterial(order.id, order.seller, order.materialId, order.materialAmount);

        return order;
    }
   
    /**
     * @dev Execute order on marketplace.
     * Emit details of executed Order.
     * @param _sellerAccount - seller's address
     * @param _orderId - order id in marketpalce
     * @param _materialAmount - materialAmount to buy
     * @return order - cancelled order
     */
    function executeOrderMaterial(address _sellerAccount, bytes32 _orderId , uint256 _materialAmount) public whenMarketplaceMaterialNotPaused returns (Order memory) {
        uint saleShareAmount = 0;
        
        Order memory order = orderByOrderId[_sellerAccount][_orderId];
        require(order.id != 0, "Asset not published");
        require (order.materialAmount >= _materialAmount, "Item in order not enough");
        order.materialAmount -= _materialAmount;
        orderByOrderId[_sellerAccount][_orderId] = Order({
            id: order.id,
            seller: order.seller,
            materialId: order.materialId,
            materialAmount: order.materialAmount,
            price: order.price
        });
        uint totalPrice  = order.price * _materialAmount;
        vaultBalance.decreaseBalance(msg.sender,totalPrice);
        vaultMaterial.increaseMaterialUserSingle(msg.sender,order.materialId,_materialAmount);
        vaultBalance.increaseBalance(order.seller,totalPrice);
        
        
        if (ownerCutPerMillion >= 0) {
            saleShareAmount = (totalPrice *(ownerCutPerMillion))/(1000000);
            vaultBalance.decreaseBalance(order.seller,saleShareAmount);
            vaultBalance.increaseBalance(_Owner,saleShareAmount);
        }

        if(order.materialAmount == 0){
            delete orderByOrderId[_sellerAccount][_orderId];
        }

        emit OrderExecutedMaterial(order.id, msg.sender, order.seller, order.materialId, order.materialAmount, _materialAmount ,totalPrice, saleShareAmount);
        return order;
    }

    /**
     * @dev Get info of an order
     * Emit order detail
     * @param _sellerAccount - seller's address
     * @param _orderId - order id in marketpalce
     * @return order - cancelled order
     */
    function getOrderInfoMaterial(address _sellerAccount, bytes32 _orderId) external returns (Order memory) {
        Order memory order = orderByOrderId[_sellerAccount][_orderId];

        require(order.id != 0, "Asset not published");

        emit OrderDetailMaterial(order.id, order.seller, order.materialId, order.materialAmount, order.price);

        return order;
    }

    /**
    * @dev Function to pause functions in this contract.
    * can only be called by the creator of contract.
    */
    function pauseMarketplace() external onlyOwner whenMarketplaceMaterialNotPaused {
        _paused = true;
        emit MarketplaceMaterialPaused();
    }

    /**
    * @dev Function to unpause functions in this contract.
    * can only be called by the creator of contract.
    */
    function unpauseMarketplace() external onlyOwner whenMarketplaceMaterialPaused {
        _paused = false;
        emit MarketplaceMaterialUnpaused();
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
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
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

interface IMaterialVault{
    function increaseMaterialUserSingle(address _addressUser, uint256 _materialId, uint256 _materialAmount) external;

    function increaseMaterialUser(address _addressUser, uint256[] memory _materialIds, uint256[] memory  _materialAmounts) external;

    function decreaseMaterialUserSingle(uint256 _materialId, uint256 _materialAmount) external;

    function decreaseMaterialUser(uint256[] memory _materialIds, uint256[] memory _materialAmounts) external;

    function transferMaterialUserSingle(address _addressUserSender, address _addressUserReceiver, uint256 _materialId, uint256 _materialAmount) external;

    function transferMaterialUser(address _addressUserSender, address _addressUserReceiver, uint256[] memory _materialIds, uint256[] memory _materialAmounts) external;

    function getMaterialAmountbyUser(address _addressUser, uint256 _materialId) external view returns (uint256);

    function getAllMaterialAmountbyUser(address _addressUser) external view returns (uint256[] memory);
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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