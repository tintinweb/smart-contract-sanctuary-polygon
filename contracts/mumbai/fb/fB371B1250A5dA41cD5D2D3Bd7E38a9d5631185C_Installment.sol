// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./utils/IBalanceVault.sol";
import "./utils/ILandNFT.sol";

contract Installment is Ownable, AccessControl, ReentrancyGuard{

    /**
     * @dev use interface to set vault
     * IBalanceVault - set intetface for vaultBalance
     * ILandNFT - set intetface for landNFT
    */

    IBalanceVault public vaultBalance;
    ILandNFT public landNFT;
    address public admin;

    bool internal _paused;

    bytes32 public constant VAULT_ADMIN = keccak256("VAULT_ADMIN");

    event SetVaultBalanceAddress(address indexed vaultAddress);
    event SetLandNFTAddress(address indexed landNFT);
    event OrderCreated(bytes32 orderId, address indexed seller, address nftAddress ,uint256 tokenID ,uint256 price);
    event OrderCancelled(bytes32 orderId, address indexed seller, address nftAddress , uint256 tokenID, uint256 price);
    
    event OrderPruchase(
    bytes32 billId, 
    address indexed buyer, 
    address indexed seller,
    address nftAddress,
    uint256 price ,
    uint256 period,
    uint256 periodBalance,
    uint256 pledge,
    uint256 totalBill,
    uint256 billBalance,
    uint256 billAmout
    );

    event PayBill(
    bytes32 billId, 
    address indexed buyer, 
    address indexed seller, 
    uint256 periodBalance,
    uint256 billBalance,
    uint256 nakaAmount
    );
    
    event BillCancelled(
    bytes32 billId, 
    address indexed buyer, 
    address indexed seller,
    address nftAddress,
    uint256 tokenID,
    uint256 price ,
    uint256 period,
    uint256 periodBalance,
    uint256 pledge,
    uint256 totalBill,
    uint256 billBalance,
    uint256 billAmout
    );

    event BillBlacklist (
    bytes32 billId, 
    address indexed buyer, 
    address indexed seller,
    address nftAddress,
    uint256 tokenID, 
    uint256 price ,
    uint256 period,
    uint256 periodBalance,
    uint256 pledge,
    uint256 totalBill,
    uint256 billBalance,
    uint256 billAmout
    );

    event InstallmentPaused();
    event InstallmentUnpaused();

    uint256 interestRate = 20 ; //APY 20%
    
    struct Order {
        bytes32 id;
        address nftAddress;
        uint256 tokenId;
        address seller;
        uint256 price;
    }
    mapping (address => mapping(bytes32 => Order)) public orderByOrderId;
    
    struct Bill {
        bytes32 billId;
        address buyer;
        address seller;
        address nftAddress;
        uint256 tokenId;
        uint256 price;
        uint256 period;
        uint256 periodBalance;
        uint256 pledge;
        uint256 totalBill;
        uint256 billBalance;
        uint256 billAmout;
    } 
    mapping (address => mapping(bytes32 => Bill)) public billByBillId;

    constructor(
        address _vaultBalanceAddress,
        address _landNFTAddress,
        address _admin
    ){
        vaultBalance = IBalanceVault(_vaultBalanceAddress);
        emit SetVaultBalanceAddress(address(vaultBalance));

        landNFT = ILandNFT(_landNFTAddress);
        emit SetLandNFTAddress(address(landNFT));
        admin = _admin;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
    * @dev Modifier to only allow the function to be executed when it isn't paused.
    */
    modifier whenInstallmentNotPaused() {
        require(!_paused, "[Shop.whenInstallmentNotPaused] Not Paused");
        _;
    }

    /**
    * @dev Modifier to only allow the function to be executed when it is paused.
    */
    modifier whenInstallmentPaused() {
        require(_paused, "[Shop.whenInstallmentPaused] Paused");
        _;
    }
    /**
     * @dev Create order for selling nftLand installment.
     * Emit details of createded Order.
     * @param _nftAddress - NFT address for selling.
     * @param _tokenId - id land for selling.
     * @param _price - Naka token amount of each items user want to sell.
     */
    function createOrder (address _nftAddress,uint256 _tokenId, uint256 _price) public returns (Order memory) {
            bytes32 _orderId = keccak256(
                abi.encodePacked(
                block.timestamp,
                msg.sender,
                _nftAddress,
                _tokenId,
                _price
            )
        );
        Order memory order = orderByOrderId[msg.sender][_orderId] = Order({
            id: _orderId,
            seller: msg.sender,
            nftAddress: _nftAddress,
            tokenId : _tokenId,
            price: _price
        });

        landNFT.transferFrom(msg.sender, admin, _tokenId);
        emit OrderCreated(_orderId, msg.sender, _nftAddress, _tokenId, _price);

        return order;
    }
     /**
     * @dev pruchase landNFT for buyer to want to buy landNFT installment payment.
     * Emit details of pruchase.
     * @param _sellerAccount - seller's address.
     * @param _orderId - order id of order.
     * @param _period - period of installment payment.
     */
    function pruchase(address _sellerAccount, bytes32 _orderId , uint256 _period) public  {
        uint periods = _period - 3;
        Order memory order = orderByOrderId[_sellerAccount][_orderId];
        uint totalInterest = order.price * interestRate/100;
        uint totalbillbalance = order.price + totalInterest;
        uint totalBillAmout  = totalbillbalance / _period;
        uint totalPledge = totalBillAmout * 3;
        uint billbalances = totalbillbalance - totalPledge;
        vaultBalance.decreaseBalance(msg.sender, totalPledge);
         if (periods == 0){
            vaultBalance.increaseBalance(_sellerAccount, totalPledge);
            periods -= periods;
        }
        bytes32 _billId = keccak256(
                abi.encodePacked(
                block.timestamp,
                 msg.sender,
                order.nftAddress,
                 order.tokenId,
                 order.price
            )
        );
        billByBillId[msg.sender][_billId] = Bill({
            billId : _billId,
            buyer : msg.sender,
            seller : _sellerAccount,
            nftAddress : order.nftAddress,
            tokenId: order.tokenId,
            price :order.price,
            period : _period,
            periodBalance:periods,
            pledge: totalPledge,
            totalBill:totalbillbalance,
            billBalance: billbalances,
            billAmout : totalBillAmout
            
        });
        delete orderByOrderId[order.seller][_orderId];
        emit OrderPruchase(_billId,msg.sender, _sellerAccount,order.nftAddress,order.price,
        _period,periods, totalPledge, totalbillbalance, billbalances,totalBillAmout);
    }
    /**
     * @dev pruchase landNFT for buyer to want to buy landNFT installment payment.
     * Emit details of pruchase.
     * @param _buyerAccount - buyer's address.
     * @param _billId - bill id of buyer for paybill.
     * @param _period - period of installment payment.
     * @param _nakaAmount - Naka Amout for payment billbalances.
     */
    function payBill(address _buyerAccount, bytes32 _billId , uint256 _period,uint256 _nakaAmount ) external onlyRole(VAULT_ADMIN) {
        Bill memory bill = billByBillId[_buyerAccount][_billId];
        require(bill.billId != 0, "Bill not found");
        vaultBalance.decreaseBalance(_buyerAccount, _nakaAmount);
        vaultBalance.increaseBalance(bill.seller, _nakaAmount);
        bill.billBalance -= _nakaAmount;
        bill.periodBalance -= _period;
        
        if (bill.periodBalance == 0){
            vaultBalance.increaseBalance(bill.seller,bill.pledge);
            bill.pledge -= bill.pledge;
            landNFT.transferFrom(admin,bill.buyer,bill.tokenId);
        }
        billByBillId[_buyerAccount][_billId] = Bill({
            billId : bill.billId,
            buyer : bill.buyer,
            seller : bill.seller,
            nftAddress : bill.nftAddress,
            tokenId:bill.tokenId,
            price :bill.price,
            period :bill.period,
            periodBalance:bill.periodBalance,
            pledge: bill.pledge,
            totalBill: bill.totalBill,
            billBalance: bill.billBalance,
            billAmout : bill.billAmout
        });
      emit PayBill(_billId, _buyerAccount ,bill.seller,bill.periodBalance,bill.billBalance,_nakaAmount);
    }
    function updateBill(address _buyerAccount, bytes32 _billId) internal {
        Bill memory bill = billByBillId[_buyerAccount][_billId];
        bill.pledge -= bill.pledge;
        billByBillId[_buyerAccount][_billId] = Bill({
            billId : bill.billId,
            buyer : bill.buyer,
            seller : bill.seller,
            nftAddress : bill.nftAddress,
            tokenId:bill.tokenId,
            price :bill.price,
            period :bill.period,
            periodBalance:bill.periodBalance,
            pledge: bill.pledge,
            totalBill: bill.totalBill,
            billBalance: bill.billBalance,
            billAmout : bill.billAmout
        });
    }
     /**
     * @dev Cancel order for seller want to cancel order.
     * Emit details of canceled Order.
     * @param _sellerAccount - seller's address.
     * @param _orderId - order id of order.
     */
    function cancelOrder(address _sellerAccount ,bytes32 _orderId) external {
        Order memory order = orderByOrderId[_sellerAccount][_orderId];
        require(order.id != 0, "Asset not published");
        require(order.seller == msg.sender, "Unauthorized user");
        landNFT.approve(order.seller, order.tokenId);
        landNFT.transferFrom(admin ,_sellerAccount, order.tokenId);
        delete orderByOrderId[order.seller][_orderId];
        emit OrderCancelled(order.id, order.seller, order.nftAddress,order.tokenId, order.price);
    }
      /**
     * @dev Cancel bill for seller or buyer want to cancel bill.
     * Emit details of canceled bill.
     * @param _buyerAccount - buyer's address.
     * @param _billId - bill id of buyer for paybill.
     */
    function cancelBill(address _buyerAccount ,bytes32 _billId) external onlyRole(VAULT_ADMIN)  {
        Bill memory bill = billByBillId[_buyerAccount][_billId];
        require(bill.billId != 0, "Bill not found");
        vaultBalance.increaseBalance(bill.buyer,bill.pledge);
        updateBill(_buyerAccount, _billId);
        landNFT.transferFrom(admin ,bill.seller, bill.tokenId);
        delete billByBillId[_buyerAccount][_billId];
        emit BillCancelled(bill.billId,bill.buyer, bill.seller, bill.nftAddress,bill.tokenId,
        bill.price,bill.period,bill.periodBalance,bill.pledge,bill.totalBill,bill.billBalance,bill.billAmout);
    }
    /**
     * @dev blackList for buyer long overdue .
     * Emit details of blackList.
     * @param _buyerAccount - buyer's address.
     * @param _billId - bill id of buyer for paybill.
     */
    function blackList(address _buyerAccount ,bytes32 _billId) external onlyRole(VAULT_ADMIN) {
        Bill memory bill = billByBillId[_buyerAccount][_billId];
        require(bill.billId != 0, "Bill not found");
        vaultBalance.increaseBalance(bill.seller,bill.pledge);
        updateBill(_buyerAccount, _billId);
        landNFT.transferFrom(admin ,bill.seller, bill.tokenId);
         delete billByBillId[_buyerAccount][_billId];
         emit BillBlacklist(bill.billId,bill.buyer, bill.seller, bill.nftAddress,bill.tokenId,
         bill.price,bill.period,bill.periodBalance,bill.pledge,bill.totalBill,bill.billBalance,bill.billAmout);
        
    }
    /**
     * @dev setInterestRate  set interest for use to calculate payment.
     * @param _interestRate - amount interest to want.
     */

    function setInterestRate (uint256 _interestRate) external onlyOwner {
            interestRate = _interestRate ;
    }
    function getInterestRate () public view returns (uint256){
            return interestRate ;
    }
    function ownerOf(uint256 tokenId) public view  returns (address) { 
       return landNFT.ownerOf(tokenId);
    }
    function transferLand(address from, address to, uint256 tokenId) external  { 
       landNFT.transferFrom(from, to, tokenId);
    }
    function approve(address to, uint256 tokenId) external {
        landNFT.approve(to, tokenId);
    }
    function balanceOf(address owner) external view returns (uint256){
        return landNFT.balanceOf(owner);
    }
    function getApproved(uint256 tokenId) external view returns (address){
        return landNFT.getApproved(tokenId);
    }
    /**
    * @dev Function to pause functions in this contract.
    * can only be called by the creator of contract.
    */
    function pauseInstallment() external onlyOwner whenInstallmentNotPaused {
        _paused = true;
        emit InstallmentPaused();
    }

    /**
    * @dev Function to unpause functions in this contract.
    * can only be called by the creator of contract.
    */
    function unpauseInstallment() external onlyOwner whenInstallmentPaused {
        _paused = false;
        emit InstallmentUnpaused();
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
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

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
        _checkRole(role, _msgSender());
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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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

interface ILandNFT {
    function _baseURI() external view returns (string memory);

    function addLandtoOwner(address owner, uint256 landId) external;

    function removeLandfromOwner(address owner, uint256 landId) external;

    function mintWithPrice(address _minter, uint256 _landId, uint256 _price) external;

    function _burn(uint256 _tokenId) external ;

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function transferFrom( address from, address to, uint256 tokenId ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);
     
    function balanceOf(address owner) external view returns (uint256 balance);

    function allowance(address owner, address spender) external view returns (uint256);






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