// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import { BitMaps } from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {
    OwnableUpgradeable,
    Initializable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { IStorageRegistry } from "./Interfaces/IStorageRegistry.sol";

contract StorageRegistry is
    IStorageRegistry,
    Initializable,
    OwnableUpgradeable
{
    /// -----------------------------------------------------------------------
    /// Library usage
    /// -----------------------------------------------------------------------

    using BitMaps for BitMaps.BitMap;

    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    /// @notice whitelist contract address
    address public whitelistAddress;

    /// @notice vault contract address
    address public vaultAddress;

    /// @notice swap contract address
    address public swapAddress;

    /// @notice reserve contract address
    address public reserveAddress;

    /// @notice NF3Market contract address
    address public marketAddress;

    /// @notice NF3Loan contract address
    address public loanAddress;

    /// @notice airdropClaimImplementation contract address
    address public airdropClaimImplementation;

    /// @notice signing utility library's address
    address public signingUtilsAddress;

    /// @notice positionToken contract address
    address public positionTokenAddress;

    /// @notice Mapping of users and their nonce in form of bitmap
    mapping(address => BitMaps.BitMap) private nonce;

    /// @notice mapping from position tokenId to claim contract address
    mapping(uint256 => address) public claimContractAddresses;

    /// @notice mapping for whitelisted airdrop contracts that can be called by the user
    mapping(address => bool) public airdropWhitelist;

    /// -----------------------------------------------------------------------
    /// Modifiers
    /// -----------------------------------------------------------------------

    modifier onlyApproved() {
        _onlyApproved();
        _;
    }

    /* ===== INIT ===== */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @dev Initialize
    function initialize() public initializer {
        __Ownable_init();
    }

    /// -----------------------------------------------------------------------
    /// Nonce actions
    /// -----------------------------------------------------------------------

    /// @notice Inherit from IStorageRegistry
    function getNonce(address _owner, uint256 _nonce)
        external
        view
        override
        returns (bool)
    {
        return nonce[_owner].get(_nonce);
    }

    /// @notice Inherit from IStorageRegistry
    function checkNonce(address _owner, uint256 _nonce) external view {
        bool _status = nonce[_owner].get(_nonce);
        if (_status) {
            revert StorageRegistryError(
                StorageRegistryErrorCodes.INVALID_NONCE
            );
        }
    }

    /// @notice Inherit from IStorageRegistry
    function setNonce(address _owner, uint256 _nonce)
        external
        override
        onlyApproved
    {
        emit NonceSet(_owner, _nonce);

        nonce[_owner].set(_nonce);
    }

    /// -----------------------------------------------------------------------
    /// Owner actions
    /// -----------------------------------------------------------------------

    /// @notice Inherit from IStorageRegistry
    function setMarket(address _marketAddress) external override onlyOwner {
        if (_marketAddress == address(0)) {
            revert StorageRegistryError(
                StorageRegistryErrorCodes.INVALID_ADDRESS
            );
        }
        emit MarketSet(marketAddress, _marketAddress);

        marketAddress = _marketAddress;
    }

    /// @notice Inherit from IStorageRegistry
    function setVault(address _vaultAddress) external override onlyOwner {
        if (_vaultAddress == address(0)) {
            revert StorageRegistryError(
                StorageRegistryErrorCodes.INVALID_ADDRESS
            );
        }
        emit VaultSet(vaultAddress, _vaultAddress);

        vaultAddress = _vaultAddress;
    }

    /// @notice Inherit from IStorageRegistry
    function setReserve(address _reserveAddress) external override onlyOwner {
        if (_reserveAddress == address(0)) {
            revert StorageRegistryError(
                StorageRegistryErrorCodes.INVALID_ADDRESS
            );
        }
        emit ReserveSet(reserveAddress, _reserveAddress);

        reserveAddress = _reserveAddress;
    }

    /// @notice Inherit from IStorageRegistry
    function setWhitelist(address _whitelistAddress)
        external
        override
        onlyOwner
    {
        if (_whitelistAddress == address(0)) {
            revert StorageRegistryError(
                StorageRegistryErrorCodes.INVALID_ADDRESS
            );
        }
        emit WhitelistSet(whitelistAddress, _whitelistAddress);
        whitelistAddress = _whitelistAddress;
    }

    /// @notice Inherit from IStorageRegistry
    function setSwap(address _swapAddress) external override onlyOwner {
        if (_swapAddress == address(0)) {
            revert StorageRegistryError(
                StorageRegistryErrorCodes.INVALID_ADDRESS
            );
        }
        emit SwapSet(swapAddress, _swapAddress);

        swapAddress = _swapAddress;
    }

    /// @notice Inherit from IStorageRegistry
    function setLoan(address _loanAddress) external override onlyOwner {
        if (_loanAddress == address(0)) {
            revert StorageRegistryError(
                StorageRegistryErrorCodes.INVALID_ADDRESS
            );
        }
        emit LoanSet(loanAddress, _loanAddress);
        loanAddress = _loanAddress;
    }

    /// @notice Inherit from IStorageRegistry
    function setSigningUtil(address _signingUtilsAddress)
        external
        override
        onlyOwner
    {
        if (_signingUtilsAddress == address(0)) {
            revert StorageRegistryError(
                StorageRegistryErrorCodes.INVALID_ADDRESS
            );
        }
        emit SigningUtilSet(signingUtilsAddress, _signingUtilsAddress);

        signingUtilsAddress = _signingUtilsAddress;
    }

    /// @notice Inherit from IStorageRegistry
    function setAirdropClaimImplementation(address _airdropClaimImplementation)
        external
        override
        onlyOwner
    {
        if (_airdropClaimImplementation == address(0)) {
            revert StorageRegistryError(
                StorageRegistryErrorCodes.INVALID_ADDRESS
            );
        }
        emit AirdropClaimImplementationSet(
            airdropClaimImplementation,
            _airdropClaimImplementation
        );
        airdropClaimImplementation = _airdropClaimImplementation;
    }

    /// @notice Inherit from IStorageRegistry
    function setPositionToken(address _positionTokenAddress)
        external
        override
        onlyOwner
    {
        if (_positionTokenAddress == address(0)) {
            revert StorageRegistryError(
                StorageRegistryErrorCodes.INVALID_ADDRESS
            );
        }
        emit PositionTokenSet(positionTokenAddress, _positionTokenAddress);
        positionTokenAddress = _positionTokenAddress;
    }

    /// @notice Inherit from IStorageRegistry
    function setAirdropWhitelist(address _contract, bool _allow)
        external
        override
        onlyOwner
    {
        airdropWhitelist[_contract] = _allow;
    }

    /// @notice Inherit from IStorageRegistry
    function setClaimContractAddresses(uint256 _tokenId, address _claimContract)
        external
        override
        onlyApproved
    {
        claimContractAddresses[_tokenId] = _claimContract;
    }

    /// -----------------------------------------------------------------------
    /// Internal functions
    /// -----------------------------------------------------------------------

    function _onlyApproved() internal view {
        if (
            msg.sender != swapAddress &&
            msg.sender != reserveAddress &&
            msg.sender != loanAddress
        ) {
            revert StorageRegistryError(
                StorageRegistryErrorCodes.CALLER_NOT_APPROVED
            );
        }
    }

    /// @dev This empty reserved space is put in place to allow future versions to add new
    /// variables without shifting down storage in the inheritance chain.
    /// See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largelly inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

/// @title NF3 Storage Registry Interface
/// @author NF3 Exchange
/// @dev This interface defines all the functions related to storage for the protocol.

interface IStorageRegistry {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------
    enum StorageRegistryErrorCodes {
        INVALID_NONCE,
        CALLER_NOT_APPROVED,
        INVALID_ADDRESS
    }

    error StorageRegistryError(StorageRegistryErrorCodes code);

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /// @dev Emits when status has changed.
    /// @param owner user whose nonce is updated
    /// @param nonce value of updated nonce
    event NonceSet(address owner, uint256 nonce);

    /// @dev Emits when new market address has set.
    /// @param oldMarketAddress Previous market contract address
    /// @param newMarketAddress New market contract address
    event MarketSet(address oldMarketAddress, address newMarketAddress);

    /// @dev Emits when new reserve address has set.
    /// @param oldVaultAddress Previous vault contract address
    /// @param newVaultAddress New vault contract address
    event VaultSet(address oldVaultAddress, address newVaultAddress);

    /// @dev Emits when new reserve address has set.
    /// @param oldReserveAddress Previous reserve contract address
    /// @param newReserveAddress New reserve contract address
    event ReserveSet(address oldReserveAddress, address newReserveAddress);

    /// @dev Emits when new whitelist contract address has set
    /// @param oldWhitelistAddress Previous whitelist contract address
    /// @param newWhitelistAddress New whitelist contract address
    event WhitelistSet(
        address oldWhitelistAddress,
        address newWhitelistAddress
    );

    /// @dev Emits when new swap address has set.
    /// @param oldSwapAddress Previous swap contract address
    /// @param newSwapAddress New swap contract address
    event SwapSet(address oldSwapAddress, address newSwapAddress);

    /// @dev Emits when new loan contract address has set
    /// @param oldLoanAddress Previous loan contract address
    /// @param newLoanAddress New whitelist contract address
    event LoanSet(address oldLoanAddress, address newLoanAddress);

    /// @dev Emits when airdrop claim implementation address is set
    /// @param oldAirdropClaimImplementation Previous air drop claim implementation address
    /// @param newAirdropClaimImplementation New air drop claim implementation address
    event AirdropClaimImplementationSet(
        address oldAirdropClaimImplementation,
        address newAirdropClaimImplementation
    );

    /// @dev Emits when signing utils library address is set
    /// @param oldSigningUtilsAddress Previous air drop claim implementation address
    /// @param newSigningUtilsAddress New air drop claim implementation address
    event SigningUtilSet(
        address oldSigningUtilsAddress,
        address newSigningUtilsAddress
    );

    /// @dev Emits when new position token address has set.
    /// @param oldPositionTokenAddress Previous position token contract address
    /// @param newPositionTokenAddress New position token contract address
    event PositionTokenSet(
        address oldPositionTokenAddress,
        address newPositionTokenAddress
    );

    /// -----------------------------------------------------------------------
    /// Nonce actions
    /// -----------------------------------------------------------------------

    /// @dev Get the value of nonce without reverting.
    /// @param owner Owner address
    /// @param _nonce Nonce value
    function getNonce(address owner, uint256 _nonce)
        external
        view
        returns (bool);

    /// @dev Check if the nonce is in correct status.
    /// @param owner Owner address
    /// @param _nonce Nonce value
    function checkNonce(address owner, uint256 _nonce) external view;

    /// @dev Set the nonce value of a user. Can only be called by reserve contract.
    /// @param owner Address of the user
    /// @param _nonce Nonce value of the user
    function setNonce(address owner, uint256 _nonce) external;

    /// -----------------------------------------------------------------------
    /// Owner actions
    /// -----------------------------------------------------------------------

    /// @dev Set Market contract address.
    /// @param _marketAddress Market contract address
    function setMarket(address _marketAddress) external;

    /// @dev Set Vault contract address.
    /// @param _vaultAddress Vault contract address
    function setVault(address _vaultAddress) external;

    /// @dev Set Reserve contract address.
    /// @param _reserveAddress Reserve contract address
    function setReserve(address _reserveAddress) external;

    /// @dev Set Whitelist contract address.
    /// @param _whitelistAddress contract address
    function setWhitelist(address _whitelistAddress) external;

    /// @dev Set Swap contract address.
    /// @param _swapAddress Swap contract address
    function setSwap(address _swapAddress) external;

    /// @dev Set Loan contract address
    /// @param _loanAddress Whitelist contract address
    function setLoan(address _loanAddress) external;

    /// @dev Set Signing Utils library address
    /// @param _signingUtilsAddress signing utils contract address
    function setSigningUtil(address _signingUtilsAddress) external;

    /// @dev Set air drop claim contract implementation address
    /// @param _airdropClaimImplementation Airdrop claim contract address
    function setAirdropClaimImplementation(address _airdropClaimImplementation)
        external;

    /// @dev Set position token contract address
    /// @param _positionTokenAddress position token contract address
    function setPositionToken(address _positionTokenAddress) external;

    /// @dev Whitelist airdrop contract that can be called for the user
    /// @param _contract address of the airdrop contract
    /// @param _allow bool value for the whitelist
    function setAirdropWhitelist(address _contract, bool _allow) external;

    /// @notice Set claim contract address for position token
    /// @param _tokenId Token id for which the claim contract is deployed
    /// @param _claimContract address of the claim contract
    function setClaimContractAddresses(uint256 _tokenId, address _claimContract)
        external;

    /// -----------------------------------------------------------------------
    /// Public Getter Functions
    /// -----------------------------------------------------------------------

    /// @dev Get whitelist contract address
    function whitelistAddress() external view returns (address);

    /// @dev Get vault contract address
    function vaultAddress() external view returns (address);

    /// @dev Get swap contract address
    function swapAddress() external view returns (address);

    /// @dev Get reserve contract address
    function reserveAddress() external view returns (address);

    /// @dev Get market contract address
    function marketAddress() external view returns (address);

    /// @dev Get loan contract address
    function loanAddress() external view returns (address);

    /// @dev Get airdropClaim contract address
    function airdropClaimImplementation() external view returns (address);

    /// @dev Get signing utils contract address
    function signingUtilsAddress() external view returns (address);

    /// @dev Get position token contract address
    function positionTokenAddress() external view returns (address);

    /// @dev Get claim contract address
    function claimContractAddresses(uint256 _tokenId)
        external
        view
        returns (address);

    /// @dev Get whitelist of an airdrop contract
    function airdropWhitelist(address _contract) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
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
 * /// @custom:oz-upgrades-unsafe-allow constructor
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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}