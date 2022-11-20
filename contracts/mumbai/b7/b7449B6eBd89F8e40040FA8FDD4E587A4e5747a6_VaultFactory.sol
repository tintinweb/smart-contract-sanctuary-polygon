//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import {VaultImplementation} from "./VaultImplementation.sol";
import {IVaultSortedList} from "./interface/IVaultSortedList.sol";
import {IPoolAddressProvider} from "./interface/IPoolAddressProvider.sol";
contract VaultFactory is Pausable, Ownable  {

    ///
    /// CONSTANT VARIABLES
    ///
    bytes32 constant VAULT_SORTED_LIST_MANAGER = 0x619a10e1d10da142c7a64557af737368a04c9a5658b05c381e703cf6a7a091e9; 
    IVaultSortedList public constant VAULT_SORTED_LIST = IVaultSortedList(0x86C6389cE6B243561144cD8356c94663934d127a);
    IPoolAddressProvider public constant POOL_ADDRESS_PROVIDER = IPoolAddressProvider(0x5343b5bA672Ae99d627A1C87866b8E53F47Db2E6);

    ///
    /// VARIABLES
    ///
    uint256 public latestVaultImplementationVersionId;
    VaultImplementationVersion[] public vaultImplementations;
    uint256 public vaultId = 0;
    Vault[] public deployedVaults;


    ///
    /// STRUCTS
    ///

    struct VaultImplementationVersion {
        uint256 id;
        address deployedAddress;
    }

    struct Vault {
        uint256 id;
        uint256 versionId;
        address creator;
        address renter;
        uint256 rentalPeriodEnd;
        uint256 deposit;
        address deployedAddress;
    }

    ///
    /// MODIFIERS
    ///

    modifier onlyAdmin() {
        require(msg.sender == owner(), "Caller is not the admin");
        _;
    }

    ///
    /// EVENTS
    ///

    event VaultCreated(uint256 vaultId, address vaultAddress, uint256 vaultImplementationVersion, address generalAdmin, address factoryAddress, address propertyOwner, address propertyRenter, uint256 rentalPeriodEnd, uint256 deposit);
    event FailedTransfer(address receiver, uint256 amount);

    constructor(
        address _vaultImplementation
    ) {
        vaultImplementations.push(
            VaultImplementationVersion({id: latestVaultImplementationVersionId, deployedAddress: _vaultImplementation})
        );
    }

    function createNewVault(
        uint256 deposit,
        address renter,
        uint256 rentalPeriodEnd
    )
        external
        whenNotPaused
        returns (address vault)
    {
        address latestVaultImplementationAddress = vaultImplementations[latestVaultImplementationVersionId]
            .deployedAddress;
        address payable newVaultAddress = payable(Clones.clone(latestVaultImplementationAddress));
        
        VaultImplementation(newVaultAddress).initialize(VaultImplementation.Initialization({
            _factoryOwner: owner(),
            _vaultImplementationVersion: latestVaultImplementationVersionId,
            _vaultId: vaultId,
            _propertyOwner: msg.sender,
            _propertyRenter: renter,
            _rentalPeriodEnd: rentalPeriodEnd,
            _deposit: deposit,
            _lendingPool: POOL_ADDRESS_PROVIDER.getPool()
        }));

        deployedVaults.push(
            Vault({
                id: vaultId,
                versionId: latestVaultImplementationVersionId,
                creator: msg.sender,
                renter: renter,
                rentalPeriodEnd: rentalPeriodEnd,
                deposit: deposit,
                deployedAddress: newVaultAddress
            })
        );

        VAULT_SORTED_LIST.grantRole(VAULT_SORTED_LIST_MANAGER, newVaultAddress);
        emit VaultCreated(vaultId, newVaultAddress, latestVaultImplementationVersionId, owner(), address(this), msg.sender, renter, rentalPeriodEnd, deposit);
        vaultId += 1;
        return newVaultAddress;
    }


    ///
    ///ADMIN FUNCTIONS
    ///

    function setAdmin(address _adminAddress) external onlyAdmin {
        transferOwnership(_adminAddress);
    }

    function withdrawFunds(address receiver) external onlyAdmin {
        _safeTransfer(receiver, address(this).balance);
    }

    function setNewVaultImplementation(address _vaultImplementation) external onlyAdmin {
        latestVaultImplementationVersionId += 1;
        vaultImplementations.push(
            VaultImplementationVersion({id: latestVaultImplementationVersionId, deployedAddress: _vaultImplementation})
        );
    }

    function pause() public onlyAdmin whenNotPaused {
        _pause();
    }

    function unpause() public onlyAdmin whenPaused {
        _unpause();
    }

    ///
    ///GETTER FUNCTIONS
    ///

    function getDeployedVaults() external view returns (Vault[] memory) {
        return deployedVaults;
    }

    ///
    ///INTERNAL FUNCTIONS
    ///

    function _safeTransfer(address receiver, uint256 amount) internal {
        uint256 balance = address(this).balance;
        if (balance < amount) require(false, "Not enough in contract balance");

        (bool success, ) = receiver.call{value: amount}("");

        if (!success) {
            emit FailedTransfer(receiver, amount);
            require(false, "Transfer failed.");
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IVaultSortedList} from "./interface/IVaultSortedList.sol";
import {IDeFiRouter} from "./interface/IDeFiRouter.sol";
import {IPool} from "./interface/IPool.sol";

contract VaultImplementation is Pausable{
    using Address for address;

    ///
    /// ERROR
    ///
    error rentalPeriodDoesNotPass(uint256 _rentalPeriodEnd,uint256 _currentTime);

    ///
    /// CONSTANT VARIABLES
    ///
    bytes32 constant VAULT_SORTED_LIST_MANAGER = 0x619a10e1d10da142c7a64557af737368a04c9a5658b05c381e703cf6a7a091e9; 
    address public constant DEFI_ROUTER_ADDRESS = 0x574ebEc067d94E4FcDbCA74DF035c562b7E816A7;  
    address public constant AAVE_MUMBAI_DAI_ADDRESS = 0x9A753f0F7886C9fbF63cF59D0D4423C5eFaCE95B; 
    address public constant ADMIN_FEE_COLLECTOR = 0xECAFBCCec8fc5a50e3D896bFfDeFde0fc0b336d3; 
    IVaultSortedList public constant VAULT_SORTED_LIST = IVaultSortedList(0x86C6389cE6B243561144cD8356c94663934d127a);
    IDeFiRouter public constant DEFI_ROUTER = IDeFiRouter(DEFI_ROUTER_ADDRESS );
    IERC20  public constant AAVE_MUMBAI_DAI = IERC20(AAVE_MUMBAI_DAI_ADDRESS);
    uint256 public constant MAX_UITNT_256 = ~uint256(0); 
    
    ///
    /// VARIABLES
    ///
    
    bool private isBase;
    address public generalAdmin;
    address public factory;
    address public aaveLendingPool;
    uint256 public vaultImplementationVersion;

    uint256 public vaultId;
    uint256 public rentalPeriodEnd;
    uint256 public deposit;
    address public propertyOwner;
    address public propertyRenter;
    uint256 public amountToReturn;
    bool public isDepositStored;
    bool public isAmountAccepted;
    bool public isRenterChunkReturned;
    bool public isOwnerChunkReturned;

    
    ///
    /// STRUCTS
    ///

    struct Initialization {
        address _factoryOwner;
        uint256 _vaultImplementationVersion;
        uint256 _vaultId;
        address _propertyOwner;
        address _propertyRenter;
        uint256 _rentalPeriodEnd;
        uint256 _deposit;
        address _lendingPool;
    }

    struct VaultDetails {
        uint256 vaultId;
        address propertyOwner;
        address propertyRenter;
        uint256 rentalPeriodEnd;
        uint256 deposit;
        address deployedAddress;
        uint256  amountToReturn;
        bool isDepositStored;
        bool isAmountAccepted;
        bool isRenterChunkReturned;
        bool isOwnerChunkReturned;
    }

    ///
    /// EVENTS
    ///

    event DepositStored(uint256 vaultId, address propertyOwner, address propertyRenter, uint256 deposit);
    event AmountToReturnUpdate(uint256 vaultId, address propertyOwner, address propertyRenter, uint256 initialDeposit, uint256 previousAmount, uint256 newAmount);
    event AmountToReturnRejected(uint256 vaultId, address propertyOwner, address propertyRenter, uint256 initialDeposit, uint256 rejectedAmount);
    event AmountToReturnAccepted(uint256 vaultId, address propertyOwner, address propertyRenter, uint256 initialDeposit, uint256 acceptedAmount);
    event RenterDepositChunkReturned(uint256 vaultId, address propertyOwner, address propertyRenter, uint256 initialDeposit, uint256 renterDepositChunk);
    event OwnerDepositChunkReturned(uint256 vaultId, address propertyOwner, address propertyRenter, uint256 initialDeposit, uint256 ownerDepositChunk);
    event FailedTransfer(address receiver, uint256 amount);
    event Received(address sender, uint256 amount);

    ///
    /// MODIFIERS
    ///

    // This makes sure we can't initialize the implementation contract.
    modifier onlyIfNotBase() {
        require(isBase == false, "The implementation contract can't be initialized");
        _;
    }

    // This makes sure we can't initialize a cloned contract twice.
    modifier onlyIfNotAlreadyInitialized() {
        require(propertyOwner == address(0), "Contract already initialized");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == generalAdmin, "Caller is not the admin");
        _;
    }

    modifier onlyIfPropertyRenterOrNotSet() {
        require(msg.sender == propertyRenter || propertyRenter == address(0), "The caller is not the property renter");
        _;
    }

    modifier onlyIfPropertyRenter() {
        require(msg.sender == propertyRenter || propertyRenter == address(0), "The caller is not the property renter");
        _;
    }

    modifier onlyIfPropertyOwner() {
        require(msg.sender == propertyOwner, "The caller is not the property owner");
        _;
    }

    modifier onlyIfDepositStored() {
        require(isDepositStored == true, "No deposit has been stored");
        _;
    }

    modifier onlyIfDepositNotStored() {
        require(isDepositStored == false, "The deposit is already stored");
        _;
    }

    modifier onlyIfEqualToDeposit() {
        require(msg.value == deposit, "Incorrect amount sent");
        _;
    }

    modifier onlyWithinDepositAmount(uint256 proposedAmount) {
        require(0 <= proposedAmount && proposedAmount <= deposit, "Incorrect proposed amount");
        _;
    }

    modifier onlyIfAmountNotAccepted() {
        require(isAmountAccepted == false, "An amount has already been accepted");
        _;
    }

    modifier onlyIfAmountAccepted() {
        require(isAmountAccepted == true, "No amount has been accepted");
        _;
    }

    modifier onlyIfAmountToReturnSet() {
        require(amountToReturn != 0 ether, "No amount to return has been proposed");
        _;
    }

    modifier onlyIfOwnerChunkNotClaimed() {
        require(isOwnerChunkReturned == false, "Owner already claimed his chunk");
        _;
    }

    modifier onlyIfRenterChunkNotClaimed() {
        require(isRenterChunkReturned == false, "Renter already claimed his chunk");
        _;
    }

    modifier onlyIfRentalPeriodEnded() {
        require(block.timestamp > rentalPeriodEnd, "Rental period not ended");
        _;
    }

    modifier onlyIfRenterAddress(address renterAddress) {
        require(renterAddress !=  address(0), "Renter address needed");
        _;
    }

    ///
    /// INITIALIZATION FUNCTIONS
    ///

    constructor() {
        isBase = true;
    }
    

    function initialize(Initialization calldata initialization) external onlyIfNotBase onlyIfNotAlreadyInitialized onlyIfRenterAddress(initialization._propertyRenter) whenNotPaused {
        generalAdmin = initialization._factoryOwner;
        factory = msg.sender;
        vaultImplementationVersion = initialization._vaultImplementationVersion;
        aaveLendingPool = initialization._lendingPool;
        vaultId = initialization._vaultId;
        propertyOwner = initialization._propertyOwner;
        propertyRenter = initialization._propertyRenter;
        rentalPeriodEnd = initialization._rentalPeriodEnd;
        deposit = initialization._deposit;
    }


    ///
    /// BUSINESS LOGIC FUNCTIONS
    ///

    function storeDeposit() external payable onlyIfPropertyRenterOrNotSet onlyIfDepositNotStored onlyIfEqualToDeposit whenNotPaused{
        isDepositStored = true;
        VAULT_SORTED_LIST.addEndOfDate(address(this), rentalPeriodEnd);
        DEFI_ROUTER.addDepositToAAVE{value:msg.value}();
        emit DepositStored(vaultId, propertyOwner, propertyRenter, deposit);
    }

    //Ukeeper will automatically call this function after the end of rental period.
    function removeDepositFromAAVE() external {
        if(rentalPeriodEnd > block.timestamp) {
            revert rentalPeriodDoesNotPass(rentalPeriodEnd,block.timestamp);
        }
        address currentValut = address(this);
        IPool(aaveLendingPool).withdraw(AAVE_MUMBAI_DAI_ADDRESS,MAX_UITNT_256,currentValut);
        uint256 daiBalanceOf = AAVE_MUMBAI_DAI.balanceOf(currentValut);
        AAVE_MUMBAI_DAI.approve(DEFI_ROUTER_ADDRESS, daiBalanceOf);
        uint256 maticReceived = DEFI_ROUTER.swapToMatic();
        uint256 profitsToAdmin = maticReceived > deposit ? maticReceived - deposit : 0;
        if(profitsToAdmin > 0){
            _safeTransfer(ADMIN_FEE_COLLECTOR,profitsToAdmin);
        }
        VAULT_SORTED_LIST.removeVault(currentValut);
        VAULT_SORTED_LIST.renounceRole(VAULT_SORTED_LIST_MANAGER,address(this));
    }

    function setAmountToReturn(uint256 proposedAmount) external onlyIfRentalPeriodEnded onlyIfPropertyOwner onlyIfDepositStored onlyIfAmountNotAccepted onlyWithinDepositAmount(proposedAmount) whenNotPaused{
        uint256 previousAmount = amountToReturn;
        amountToReturn = proposedAmount;

        emit AmountToReturnUpdate(vaultId, propertyOwner, propertyRenter, deposit, previousAmount, amountToReturn);
    }

    function rejectProposedAmount() external onlyIfPropertyRenter onlyIfAmountToReturnSet whenNotPaused{
        emit AmountToReturnRejected(vaultId, propertyOwner, propertyRenter, deposit, amountToReturn);
    }

    function acceptProposedAmount() external onlyIfPropertyRenter onlyIfAmountToReturnSet whenNotPaused {
        isAmountAccepted = true;
        emit AmountToReturnAccepted(vaultId, propertyOwner, propertyRenter, deposit, amountToReturn);
    }

    function claimRenterDeposit() external onlyIfPropertyRenter onlyIfDepositStored onlyIfAmountAccepted onlyIfRenterChunkNotClaimed whenNotPaused{
        isRenterChunkReturned = true;
        _safeTransfer(msg.sender, amountToReturn);
        emit RenterDepositChunkReturned(vaultId, propertyOwner, propertyRenter, deposit, amountToReturn);

        if (isOwnerChunkReturned == true) {
            _pause();
        }
    }

    function claimOwnerDeposit() external onlyIfPropertyOwner onlyIfDepositStored onlyIfAmountAccepted onlyIfOwnerChunkNotClaimed whenNotPaused {
        isOwnerChunkReturned = true;
        uint256 ownerChunk = deposit - amountToReturn;
        _safeTransfer(msg.sender, ownerChunk);
        emit OwnerDepositChunkReturned(vaultId, propertyOwner, propertyRenter, deposit, ownerChunk);

        if (isRenterChunkReturned == true) {
            _pause();
        }
    }

    ///
    ///GETTER FUNCTIONS
    ///

    function getVaultDetails() external view returns (VaultDetails memory)  {
        return VaultDetails({
            vaultId: vaultId,
            propertyOwner: propertyOwner,
            propertyRenter: propertyRenter,
            rentalPeriodEnd: rentalPeriodEnd,
            deposit: deposit,
            deployedAddress: address(this),
            amountToReturn: amountToReturn,
            isDepositStored: isDepositStored,
            isAmountAccepted: isAmountAccepted,
            isRenterChunkReturned: isRenterChunkReturned,
            isOwnerChunkReturned: isOwnerChunkReturned
        });
    }

    ///
    ///INTERNAL FUNCTIONS
    ///

    function _safeTransfer(address receiver, uint256 amount) internal {
        uint256 balance = address(this).balance;
        if (balance < amount) require(false, "Not enough in contract balance");

        (bool success, ) = receiver.call{value: amount}("");

        if (!success) {
            emit FailedTransfer(receiver, amount);
            require(false, "Transfer failed.");
        }
    }

    function pause() public onlyAdmin whenNotPaused {
        _pause();
    }

    function unpause() public onlyAdmin whenPaused {
        _unpause();
    }

    ///
    /// FALLBACK FUNCTIONS
    ///

    // Called for empty calldata (and any value)
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    // Called when no other function matches (not even the receive function).
    fallback() external payable {
        emit Received(msg.sender, msg.value);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
interface IVaultSortedList {
    function grantRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external ;
    function timeToWithdraw(address _vault) external returns(uint256);
    function addEndOfDate(address _vaultAddress, uint256 _epochTime) external;
    function getEarlistEndOfDate() external view returns(uint,address); 
    function removeVault(address _vaultAddress) external;
    function listSize() external view returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IPoolAddressProvider {
    function getPool() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
interface IDeFiRouter {
    function addDepositToAAVE() external payable;
   function swapToMatic() external returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IPool {
    function supply(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;
    
    function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
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
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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