// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ICostManager.sol";
import "./interfaces/ICostManagerFactoryHelper.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract CostManagerBase is Initializable {
    using AddressUpgradeable for address;

    address public costManager;
    address public deployer;

    /** 
    * @dev sets the costmanager token
    * @param costManager_ new address of costmanager token, or 0
    */
    function overrideCostManager(address costManager_) external {
        // require factory owner or operator
        // otherwise needed deployer(!!not contract owner) in cases if was deployed manually
        require (
            (deployer.isContract()) 
                ?
                    ICostManagerFactoryHelper(deployer).canOverrideCostManager(_sender(), address(this))
                :
                    deployer == _sender()
            ,
            "cannot override"
        );
        
        _setCostManager(costManager_);
    }

    function __CostManagerHelper_init(address deployer_) internal onlyInitializing
    {
        deployer = deployer_;
    }

     /**
     * @dev Private function that tells contract to account for an operation
     * @param info uint256 The operation ID (first 8 bits). in other bits any else info
     * @param param1 uint256 Some more information, if any
     * @param param2 uint256 Some more information, if any
     */
    function _accountForOperation(uint256 info, uint256 param1, uint256 param2) internal {
        if (costManager != address(0)) {
            try ICostManager(costManager).accountForOperation(
                _sender(), info, param1, param2
            )
            returns (uint256 /*spent*/, uint256 /*remaining*/) {
                // if error is not thrown, we are fine
            } catch Error(string memory reason) {
                // This is executed in case revert() was called with a reason
                revert(reason);
            } catch {
                revert("unknown error");
            }
        }
    }
    
    function _setCostManager(address costManager_) internal {
        costManager = costManager_;
    }
    
    function _sender() internal virtual returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CostManagerBase.sol";
import "@artman325/trustedforwarder/contracts/TrustedForwarder.sol";

/**
* used for instances that have created(cloned) by factory with ERC2771 supports
*/
abstract contract CostManagerHelperERC2771Support is CostManagerBase, TrustedForwarder {
    function _sender() internal override view returns(address){
        return _msgSender();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

interface ICostManager/* is IERC165Upgradeable*/ {
    function accountForOperation(
        address sender, 
        uint256 info, 
        uint256 param1, 
        uint256 param2
    ) 
        external 
        returns(uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICostManagerFactoryHelper {
    
    function canOverrideCostManager(address account, address instance) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract TrustedForwarder is Initializable {

    address private _trustedForwarder;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __TrustedForwarder_init() internal onlyInitializing {
        _trustedForwarder = address(0);
    }


    /**
    * @dev setup trusted forwarder address
    * @param forwarder trustedforwarder's address to set
    * @custom:shortd setup trusted forwarder
    * @custom:calledby owner
    */
    function _setTrustedForwarder(
        address forwarder
    ) 
        internal 
      //  onlyOwner 
        //excludeTrustedForwarder 
    {
        //require(owner() != forwarder, "FORWARDER_CAN_NOT_BE_OWNER");
        _trustedForwarder = forwarder;
    }
    function setTrustedForwarder(address forwarder) public virtual;
    /**
    * @dev checking if forwarder is trusted
    * @param forwarder trustedforwarder's address to check
    * @custom:shortd checking if forwarder is trusted
    */
    function isTrustedForwarder(
        address forwarder
    ) 
        external
        view 
        returns(bool) 
    {
        return _isTrustedForwarder(forwarder);
    }

    /**
    * @dev implemented EIP-2771
    */
    function _msgSender(
    ) 
        internal 
        view 
        virtual
        returns (address signer) 
    {
        signer = msg.sender;
        if (msg.data.length>=20 && _isTrustedForwarder(signer)) {
            assembly {
                signer := shr(96,calldataload(sub(calldatasize(),20)))
            }
        }    
    }

    // function transferOwnership(
    //     address newOwner
    // ) public 
    //     virtual 
    //     override 
    //     onlyOwner 
    // {
    //     require(msg.sender != _trustedForwarder, "DENIED_FOR_FORWARDER");
    //     if (newOwner == _trustedForwarder) {
    //         _trustedForwarder = address(0);
    //     }
    //     super.transferOwnership(newOwner);
        
    // }

    function _isTrustedForwarder(
        address forwarder
    ) 
        internal
        view 
        returns(bool) 
    {
        return forwarder == _trustedForwarder;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
        if (_initialized < type(uint8).max) {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "@artman325/trustedforwarder/contracts/TrustedForwarder.sol";
import "@artman325/releasemanager/contracts/CostManagerHelperERC2771Support.sol";

//import "./lib/ECDSAExt.sol";
import "./lib/StringUtils.sol";
import "./lib/PackedSet.sol";

import "./interfaces/ICommunityHook.sol";
import "./interfaces/ICommunity.sol";
import "./interfaces/ICommunityInvite.sol";

/**
*****************
TEMPLATE CONTRACT
*****************

Although this code is available for viewing on GitHub and here, the general public is NOT given a license to freely deploy smart contracts based on this code, on any blockchains.

To prevent confusion and increase trust in the audited code bases of smart contracts we produce, we intend for there to be only ONE official Factory address on the blockchain producing the corresponding smart contracts, and we are going to point a blockchain domain name at it.

Copyright (c) Intercoin Inc. All rights reserved.

ALLOWED USAGE.

Provided they agree to all the conditions of this Agreement listed below, anyone is welcome to interact with the official Factory Contract at the this address to produce smart contract instances, or to interact with instances produced in this manner by others.

Any user of software powered by this code MUST agree to the following, in order to use it. If you do not agree, refrain from using the software:

DISCLAIMERS AND DISCLOSURES.

Customer expressly recognizes that nearly any software may contain unforeseen bugs or other defects, due to the nature of software development. Moreover, because of the immutable nature of smart contracts, any such defects will persist in the software once it is deployed onto the blockchain. Customer therefore expressly acknowledges that any responsibility to obtain outside audits and analysis of any software produced by Developer rests solely with Customer.

Customer understands and acknowledges that the Software is being delivered as-is, and may contain potential defects. While Developer and its staff and partners have exercised care and best efforts in an attempt to produce solid, working software products, Developer EXPRESSLY DISCLAIMS MAKING ANY GUARANTEES, REPRESENTATIONS OR WARRANTIES, EXPRESS OR IMPLIED, ABOUT THE FITNESS OF THE SOFTWARE, INCLUDING LACK OF DEFECTS, MERCHANTABILITY OR SUITABILITY FOR A PARTICULAR PURPOSE.

Customer agrees that neither Developer nor any other party has made any representations or warranties, nor has the Customer relied on any representations or warranties, express or implied, including any implied warranty of merchantability or fitness for any particular purpose with respect to the Software. Customer acknowledges that no affirmation of fact or statement (whether written or oral) made by Developer, its representatives, or any other party outside of this Agreement with respect to the Software shall be deemed to create any express or implied warranty on the part of Developer or its representatives.

INDEMNIFICATION.

Customer agrees to indemnify, defend and hold Developer and its officers, directors, employees, agents and contractors harmless from any loss, cost, expense (including attorney’s fees and expenses), associated with or related to any demand, claim, liability, damages or cause of action of any kind or character (collectively referred to as “claim”), in any manner arising out of or relating to any third party demand, dispute, mediation, arbitration, litigation, or any violation or breach of any provision of this Agreement by Customer.

NO WARRANTY.

THE SOFTWARE IS PROVIDED “AS IS” WITHOUT WARRANTY. DEVELOPER SHALL NOT BE LIABLE FOR ANY DIRECT, INDIRECT, SPECIAL, INCIDENTAL, CONSEQUENTIAL, OR EXEMPLARY DAMAGES FOR BREACH OF THE LIMITED WARRANTY. TO THE MAXIMUM EXTENT PERMITTED BY LAW, DEVELOPER EXPRESSLY DISCLAIMS, AND CUSTOMER EXPRESSLY WAIVES, ALL OTHER WARRANTIES, WHETHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING WITHOUT LIMITATION ALL IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE OR USE, OR ANY WARRANTY ARISING OUT OF ANY PROPOSAL, SPECIFICATION, OR SAMPLE, AS WELL AS ANY WARRANTIES THAT THE SOFTWARE (OR ANY ELEMENTS THEREOF) WILL ACHIEVE A PARTICULAR RESULT, OR WILL BE UNINTERRUPTED OR ERROR-FREE. THE TERM OF ANY IMPLIED WARRANTIES THAT CANNOT BE DISCLAIMED UNDER APPLICABLE LAW SHALL BE LIMITED TO THE DURATION OF THE FOREGOING EXPRESS WARRANTY PERIOD. SOME STATES DO NOT ALLOW THE EXCLUSION OF IMPLIED WARRANTIES AND/OR DO NOT ALLOW LIMITATIONS ON THE AMOUNT OF TIME AN IMPLIED WARRANTY LASTS, SO THE ABOVE LIMITATIONS MAY NOT APPLY TO CUSTOMER. THIS LIMITED WARRANTY GIVES CUSTOMER SPECIFIC LEGAL RIGHTS. CUSTOMER MAY HAVE OTHER RIGHTS WHICH VARY FROM STATE TO STATE. 

LIMITATION OF LIABILITY. 

TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, IN NO EVENT SHALL DEVELOPER BE LIABLE UNDER ANY THEORY OF LIABILITY FOR ANY CONSEQUENTIAL, INDIRECT, INCIDENTAL, SPECIAL, PUNITIVE OR EXEMPLARY DAMAGES OF ANY KIND, INCLUDING, WITHOUT LIMITATION, DAMAGES ARISING FROM LOSS OF PROFITS, REVENUE, DATA OR USE, OR FROM INTERRUPTED COMMUNICATIONS OR DAMAGED DATA, OR FROM ANY DEFECT OR ERROR OR IN CONNECTION WITH CUSTOMER'S ACQUISITION OF SUBSTITUTE GOODS OR SERVICES OR MALFUNCTION OF THE SOFTWARE, OR ANY SUCH DAMAGES ARISING FROM BREACH OF CONTRACT OR WARRANTY OR FROM NEGLIGENCE OR STRICT LIABILITY, EVEN IF DEVELOPER OR ANY OTHER PERSON HAS BEEN ADVISED OR SHOULD KNOW OF THE POSSIBILITY OF SUCH DAMAGES, AND NOTWITHSTANDING THE FAILURE OF ANY REMEDY TO ACHIEVE ITS INTENDED PURPOSE. WITHOUT LIMITING THE FOREGOING OR ANY OTHER LIMITATION OF LIABILITY HEREIN, REGARDLESS OF THE FORM OF ACTION, WHETHER FOR BREACH OF CONTRACT, WARRANTY, NEGLIGENCE, STRICT LIABILITY IN TORT OR OTHERWISE, CUSTOMER'S EXCLUSIVE REMEDY AND THE TOTAL LIABILITY OF DEVELOPER OR ANY SUPPLIER OF SERVICES TO DEVELOPER FOR ANY CLAIMS ARISING IN ANY WAY IN CONNECTION WITH OR RELATED TO THIS AGREEMENT, THE SOFTWARE, FOR ANY CAUSE WHATSOEVER, SHALL NOT EXCEED 1,000 USD.

TRADEMARKS.

This Agreement does not grant you any right in any trademark or logo of Developer or its affiliates.

LINK REQUIREMENTS.

Operators of any Websites and Apps which make use of smart contracts based on this code must conspicuously include the following phrase in their website, featuring a clickable link that takes users to intercoin.app:

"Visit https://intercoin.app to launch your own NFTs, DAOs and other Web3 solutions."

STAKING OR SPENDING REQUIREMENTS.

In the future, Developer may begin requiring staking or spending of Intercoin tokens in order to take further actions (such as producing series and minting tokens). Any staking or spending requirements will first be announced on Developer's website (intercoin.org) four weeks in advance. Staking requirements will not apply to any actions already taken before they are put in place.

CUSTOM ARRANGEMENTS.

Reach out to us at intercoin.org if you are looking to obtain Intercoin tokens in bulk, remove link requirements forever, remove staking requirements forever, or get custom work done with your Web3 projects.

ENTIRE AGREEMENT

This Agreement contains the entire agreement and understanding among the parties hereto with respect to the subject matter hereof, and supersedes all prior and contemporaneous agreements, understandings, inducements and conditions, express or implied, oral or written, of any nature whatsoever with respect to the subject matter hereof. The express terms hereof control and supersede any course of performance and/or usage of the trade inconsistent with any of the terms hereof. Provisions from previous Agreements executed between Customer and Developer., which are not expressly dealt with in this Agreement, will remain in effect.

SUCCESSORS AND ASSIGNS

This Agreement shall continue to apply to any successors or assigns of either party, or any corporation or other entity acquiring all or substantially all the assets and business of either party whether by operation of law or otherwise.

ARBITRATION

All disputes related to this agreement shall be governed by and interpreted in accordance with the laws of New York, without regard to principles of conflict of laws. The parties to this agreement will submit all disputes arising under this agreement to arbitration in New York City, New York before a single arbitrator of the American Arbitration Association (“AAA”). The arbitrator shall be selected by application of the rules of the AAA, or by mutual agreement of the parties, except that such arbitrator shall be an attorney admitted to practice law New York. No party to this agreement will challenge the jurisdiction or venue provisions as provided in this section. No party to this agreement will challenge the jurisdiction or venue provisions as provided in this section.
**/
contract Community is
    Initializable,
    ReentrancyGuardUpgradeable,
    TrustedForwarder,
    CostManagerHelperERC2771Support,
    IERC721Upgradeable,
    IERC721MetadataUpgradeable,
    OwnableUpgradeable,
    ICommunity
{
    using PackedSet for PackedSet.Set;

    using StringUtils for *;

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    ////////////////////////////////
    ///////// structs //////////////
    ////////////////////////////////

    struct GrantSettings {
        uint8 requireRole; //=0,
        uint256 maxAddresses; //=0,
        uint64 duration; //=0
        uint64 lastIntervalIndex;
        uint256 grantedAddressesCounter;
    }

    struct Role {
        bytes32 name;
        string roleURI;
        mapping(address => string) extraURI;
        //EnumerableSetUpgradeable.UintSet canManageRoles;
        EnumerableSetUpgradeable.UintSet canGrantRoles;
        EnumerableSetUpgradeable.UintSet canRevokeRoles;
        mapping(uint8 => GrantSettings) grantSettings;
        EnumerableSetUpgradeable.AddressSet members;
    }

    // Please make grantedBy(uint160 recipient => struct ActionInfo) mapping, and save it when user grants role. (Difference with invitedBy is that invitedBy the user has to ACCEPT the invite while grantedBy doesn’t require recipient to accept).
    // And also make revokedBy same way.
    // Please refactor invited and invitedBy and to return struct ActionInfo also. Here is struct ActionInfo, it fits in ONE slot:
    struct ActionInfo {
        address actor;
        uint64 timestamp;
        uint32 extra; // used for any other info, eg up to four role ids can be stored here !!!
    }

    /////////////////////////////
    ///////// vars //////////////
    /////////////////////////////

    /**
     * @notice getting name
     * @custom:shortd ERC721'name
     * @return name
     */
    string public name;

    /**
     * @notice getting symbol
     * @custom:shortd ERC721's symbol
     * @return symbol
     */
    string public symbol;
    /**
     * @notice uri that represent more information about thic community
     * @custom:shortd contract URI
     * @return URI
     */
    string public contractURI;

    uint8 internal rolesCount;
    address public hook;
    address internal _invitedHook;

    uint256 addressesCounter;

    /**
     * @custom:shortd role name "owners" in bytes32
     * @notice constant role name "owners" in bytes32
     */
    bytes32 public constant DEFAULT_OWNERS_ROLE =
        0x6f776e6572730000000000000000000000000000000000000000000000000000;

    /**
     * @custom:shortd role name "admins" in bytes32
     * @notice constant role name "admins" in bytes32
     */
    bytes32 public constant DEFAULT_ADMINS_ROLE =
        0x61646d696e730000000000000000000000000000000000000000000000000000;

    /**
     * @custom:shortd role name "members" in bytes32
     * @notice constant role name "members" in bytes32
     */
    bytes32 public constant DEFAULT_MEMBERS_ROLE =
        0x6d656d6265727300000000000000000000000000000000000000000000000000;

    /**
     * @custom:shortd role name "alumni" in bytes32
     * @notice constant role name "alumni" in bytes32
     */
    bytes32 public constant DEFAULT_ALUMNI_ROLE =
        0x616c756d6e690000000000000000000000000000000000000000000000000000;

    /**
     * @custom:shortd role name "visitors" in bytes32
     * @notice constant role name "visitors" in bytes32
     */
    bytes32 public constant DEFAULT_VISITORS_ROLE =
        0x76697369746f7273000000000000000000000000000000000000000000000000;

    uint8 internal constant OPERATION_SHIFT_BITS = 240; // 256 - 16
    // Constants representing operations
    uint8 internal constant OPERATION_INITIALIZE = 0x0;
    uint8 internal constant OPERATION_GRANT_ROLES = 0x1;
    uint8 internal constant OPERATION_REVOKE_ROLES = 0x2;
    uint8 internal constant OPERATION_CREATE_ROLE = 0x3;
    uint8 internal constant OPERATION_MANAGE_ROLE = 0x4;
    uint8 internal constant OPERATION_SET_TRUSTED_FORWARDER = 0x5;
    uint8 internal constant OPERATION_INVITE_PREPARE = 0x6;
    uint8 internal constant OPERATION_INVITE_ACCEPT = 0x7;
    uint8 internal constant OPERATION_SET_ROLE_URI = 0x8;
    uint8 internal constant OPERATION_SET_EXTRA_URI = 0x9;
    uint8 internal constant OPERATION_TRANSFEROWNERSHIP = 0xa;
    uint8 internal constant OPERATION_RENOUNCEOWNERSHIP = 0xb;
    uint8 internal constant OPERATION_SET_CONTRACT_URI = 0xc;

    uint8 internal constant NONE_ROLE_INDEX = 0;

    address public defaultAuthorizedInviteManager;

    // enum used in method when need to mark what need to do when error happens
    enum FlagFork {
        NONE,
        EMIT,
        REVERT
    }

    ////////////////////////////////
    ///////// mapping //////////////
    ////////////////////////////////

    mapping(bytes32 => uint8) internal _roles;
    mapping(address => PackedSet.Set) internal _rolesByAddress;
    mapping(uint8 => Role) internal _rolesByIndex;
    /**
     * @notice map users granted by
     * @custom:shortd map users granted by
     */
    mapping(address => ActionInfo[]) public grantedBy;
    /**
     * @notice map users revoked by
     * @custom:shortd map users revoked by
     */
    mapping(address => ActionInfo[]) public revokedBy;
    /**
     * @notice history of users granted
     * @custom:shortd history of users granted
     */
    mapping(address => ActionInfo[]) public granted;
    /**
     * @notice history of users revoked
     * @custom:shortd history of users revoked
     */
    mapping(address => ActionInfo[]) public revoked;

    ////////////////////////////////
    ///////// events ///////////////
    ////////////////////////////////
    event RoleCreated(bytes32 indexed role, address indexed sender);
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event RoleManaged(
        uint8 indexed sourceRole,
        uint8 indexed targetRole,
        bool canGrantRole,
        bool canRevokeRole,
        uint8 requireRole,
        uint256 maxAddresses,
        uint64 duration,
        address indexed sender
    );
    event RoleAddedErrorMessage(address indexed sender, string msg);
    event RenounceOwnership();

    ////////////////////////////////
    ///////// errors ///////////////
    ////////////////////////////////
    error AuthorizedInviteManagerOnly();
    error NOT_SUPPORTED();

    ///////////////////////////////////////////////////////////
    /// modifiers  section
    ///////////////////////////////////////////////////////////

    receive() external payable {
        revert NOT_SUPPORTED();
    }

    ///////////////////////////////////////////////////
    // common to use
    //////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////
    /// external
    ///////////////////////////////////////////////////////////
    /**
     * @param hook_ address of contract implemented ICommunityHook interface. Can be address(0)
     * @param authorizedInviteManager_ address of contract implemented invite mechanism
     * @param name_ erc721 name
     * @param symbol_ erc721 symbol
     */
    function initialize(
        address hook_,
        address invitedHook_,
        address costManager_,
        address authorizedInviteManager_,
        string memory name_,
        string memory symbol_,
        string memory contractURI_
    ) external override initializer {
        __CostManagerHelper_init(_msgSender());
        _setCostManager(costManager_);
        __TrustedForwarder_init();
        __ReentrancyGuard_init();
        _setContractURI(contractURI_);

        _invitedHook = invitedHook_;
        name = name_;
        symbol = symbol_;

        rolesCount = 1;

        _createRole(DEFAULT_OWNERS_ROLE);
        _createRole(DEFAULT_ADMINS_ROLE);
        _createRole(DEFAULT_MEMBERS_ROLE);
        _createRole(DEFAULT_ALUMNI_ROLE);
        _createRole(DEFAULT_VISITORS_ROLE);

        //_grantRole(_msgSender(), _roles[DEFAULT_OWNERS_ROLE]);
        _grantRole(
            _roles[DEFAULT_OWNERS_ROLE],
            _msgSender(),
            _roles[DEFAULT_OWNERS_ROLE],
            _msgSender()
        );

        // initial rules. owners can manage any roles. to save storage we will hardcode in any validate
        // admins can manage members, alumni and visitors
        // any other rules can be added later by owners

        _manageRole(
            _roles[DEFAULT_ADMINS_ROLE],
            _roles[DEFAULT_MEMBERS_ROLE],
            true,
            true,
            0,
            0,
            0
        );
        _manageRole(
            _roles[DEFAULT_ADMINS_ROLE],
            _roles[DEFAULT_ALUMNI_ROLE],
            true,
            true,
            0,
            0,
            0
        );
        _manageRole(
            _roles[DEFAULT_ADMINS_ROLE],
            _roles[DEFAULT_VISITORS_ROLE],
            true,
            true,
            0,
            0,
            0
        );

        // avoiding hook's trigger for built-in roles
        // so define hook address in the end
        hook = hook_;

        defaultAuthorizedInviteManager = authorizedInviteManager_;

        _accountForOperation(
            OPERATION_INITIALIZE << OPERATION_SHIFT_BITS,
            uint256(uint160(hook_)),
            uint256(uint160(costManager_))
        );
    }

    ///////////////////////////////////////////////////////////
    /// public  section
    ///////////////////////////////////////////////////////////

    /**
     * @notice Added new Roles for each account
     * @custom:shortd Added new Roles for each account
     * @param accounts participant's addresses
     * @param roleIndexes Role indexes
     */
    function grantRoles(
        address[] memory accounts,
        uint8[] memory roleIndexes
    ) public {
        _grantRoles(_msgSender(), accounts, roleIndexes);

        _accountForOperation(
            OPERATION_GRANT_ROLES << OPERATION_SHIFT_BITS,
            0,
            0
        );
    }

    /**
     * @notice Removed Roles from each member
     * @custom:shortd Removed Roles from each member
     * @param accounts participant's addresses
     * @param roleIndexes Role indexes
     */
    function revokeRoles(
        address[] memory accounts,
        uint8[] memory roleIndexes
    ) public {
        _revokeRoles(_msgSender(), accounts, roleIndexes);

        _accountForOperation(
            OPERATION_REVOKE_ROLES << OPERATION_SHIFT_BITS,
            0,
            0
        );
    }

    function grantRolesExternal(
        address accountWhichWillGrant,
        address[] memory accounts,
        uint8[] memory roleIndexes
    ) public {
        requireAuthorizedManager();
        _grantRoles(accountWhichWillGrant, accounts, roleIndexes);

        _accountForOperation(
            OPERATION_GRANT_ROLES << OPERATION_SHIFT_BITS,
            0,
            0
        );
    }

    function revokeRolesExternal(
        address accountWhichWillRevoke,
        address[] memory accounts,
        uint8[] memory roleIndexes
    ) public {
        requireAuthorizedManager();
        _revokeRoles(accountWhichWillRevoke, accounts, roleIndexes);

        _accountForOperation(
            OPERATION_REVOKE_ROLES << OPERATION_SHIFT_BITS,
            0,
            0
        );
    }

    /**
     * @notice creating new role. Can be called by owners role only
     * @custom:shortd creating new role. Can be called by owners role only
     * @param role role name
     */
    function createRole(string memory role) public {
        requireInRole(_msgSender(), _roles[DEFAULT_OWNERS_ROLE]);

        // require(_roles[role.stringToBytes32()] == 0, "Such role is already exists");
        // // prevent creating role in CamelCases with admins and owners (Admins,ADMINS,ADminS)
        // require(_roles[role._toLower().stringToBytes32()] == 0, "Such role is already exists");
        require(
            (_roles[role.stringToBytes32()] == 0) &&
                (_roles[role._toLower().stringToBytes32()] == 0),
            "Such role is already exists"
        );

        require(
            rolesCount < type(uint8).max - 1,
            "Max amount of roles exceeded"
        );

        _createRole(role.stringToBytes32());

        _accountForOperation(
            OPERATION_CREATE_ROLE << OPERATION_SHIFT_BITS,
            0,
            0
        );
    }

    /**
     * Set rules on how members with `sourceRole` can grant and revoke roles
     * @param byRole source role index
     * @param ofRole target role index
     * @param canGrantRole whether addresses with byRole can grant ofRole to other addresses
     * @param canRevokeRole whether addresses with byRole can revoke ofRole from other addresses
     * @param requireRole whether addresses with byRole can grant ofRole to other addresses
     * @param maxAddresses the maximum number of addresses that users with byRole can grant to ofRole in duration
     * @param duration duration
     *          if duration == 0 then no limit by time: `maxAddresses` will be max accounts on this role
     *          if maxAddresses == 0 then no limit max accounts on this role
     */
    function manageRole(
        uint8 byRole,
        uint8 ofRole,
        bool canGrantRole,
        bool canRevokeRole,
        uint8 requireRole,
        uint256 maxAddresses,
        uint64 duration
    ) public {
        requireInRole(_msgSender(), _roles[DEFAULT_OWNERS_ROLE]);

        require(
            ofRole != _roles[DEFAULT_OWNERS_ROLE],
            string(
                abi.encodePacked(
                    "ofRole can not be '",
                    _rolesByIndex[ofRole].name.bytes32ToString(),
                    "'"
                )
            )
        );

        _manageRole(
            byRole,
            ofRole,
            canGrantRole,
            canRevokeRole,
            requireRole,
            maxAddresses,
            duration
        );

        _accountForOperation(
            OPERATION_MANAGE_ROLE << OPERATION_SHIFT_BITS,
            0,
            0
        );
    }

    function setTrustedForwarder(address forwarder) public override {
        requireInRole(_msgSender(), _roles[DEFAULT_OWNERS_ROLE]);

        require(
            !_isInRole(forwarder, _roles[DEFAULT_OWNERS_ROLE]),
            "FORWARDER_CAN_NOT_BE_OWNER"
        );
        _setTrustedForwarder(forwarder);

        _accountForOperation(
            OPERATION_SET_TRUSTED_FORWARDER << OPERATION_SHIFT_BITS,
            0,
            0
        );
    }

    /**
     * @notice setting tokenURI for role
     * @param roleIndex role index
     * @param roleURI token URI
     * @custom:shortd setting tokenURI for role
     * @custom:calledby any who can manage this role
     */
    function setRoleURI(uint8 roleIndex, string memory roleURI) public {
        requireInRole(_msgSender(), _roles[DEFAULT_OWNERS_ROLE]);
        _rolesByIndex[roleIndex].roleURI = roleURI;

        _accountForOperation(
            OPERATION_SET_ROLE_URI << OPERATION_SHIFT_BITS,
            0,
            0
        );
    }

    /**
     * @notice setting contract URI
     * @param uri contract URI
     * @custom:shortd setting contract URI.
     * @custom:calledby owners
     */
    function setContractURI(string memory uri) public {
        requireInRole(_msgSender(), _roles[DEFAULT_OWNERS_ROLE]);

        _setContractURI(uri);

        _accountForOperation(
            OPERATION_SET_CONTRACT_URI << OPERATION_SHIFT_BITS,
            0,
            0
        );
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        _transferOwnership(newOwner);

        _accountForOperation(
            OPERATION_TRANSFEROWNERSHIP << OPERATION_SHIFT_BITS,
            uint160(_msgSender()),
            uint160(newOwner)
        );
    }

    function renounceOwnership() public override onlyOwner {
        super.renounceOwnership();
        // _functionDelegateCall(
        //     address(implCommunityState),
        //     msg.data
        // );

        _accountForOperation(
            OPERATION_RENOUNCEOWNERSHIP << OPERATION_SHIFT_BITS,
            uint160(_msgSender()),
            0
        );
    }

    ///////////////////////////////////////////////////////////
    /// public (view)section
    ///////////////////////////////////////////////////////////

    function invitedHook() public view returns (address) {
        return _invitedHook;
    }

    /**
     * @dev Returns the first address in getAddresses(OWNERS_ROLE). usually(if not transferownership/renounceownership) it's always will be deployer.
     * @return address first address on owners role list.
     */
    function owner() public view override returns (address) {
        return _rolesByIndex[_roles[DEFAULT_OWNERS_ROLE]].members.at(0);
    }

    /**
     * @dev Returns true if account is belong to DEFAULT_OWNERS_ROLE
     * @param account account address
     * @return bool
     */
    function isOwner(address account) public view returns (bool) {
        //hasRole(address, OWNERS_ROLE)
        return _isInRole(account, _roles[DEFAULT_OWNERS_ROLE]);
    }

    /**
     * @dev can be duplicate items in output. see https://github.com/Intercoin/CommunityContract/issues/4#issuecomment-1049797389
     * @notice Returns all addresses across all roles
     * @custom:shortd all addresses across all roles
     * @return two-dimensional array of addresses
     */
    function getAddresses() public view returns (address[][] memory) {
        address[][] memory l;

        l = new address[][](rolesCount - 1);

        uint256 tmplen;
        for (uint8 j = 0; j < rolesCount - 1; j++) {
            tmplen = _rolesByIndex[j].members.length();
            l[j] = new address[](tmplen);
            for (uint256 i = 0; i < tmplen; i++) {
                l[j][i] = address(_rolesByIndex[j].members.at(i));
            }
        }
        return l;
    }

    /**
     * @dev can be duplicate items in output. see https://github.com/Intercoin/CommunityContract/issues/4#issuecomment-1049797389
     * @notice Returns all addresses belong to Role
     * @custom:shortd all addresses belong to Role
     * @param roleIndexes array of role's indexes
     * @return two-dimensional array of addresses
     */
    function getAddresses(
        uint8[] calldata roleIndexes
    ) public view returns (address[][] memory) {
        address[][] memory l;

        l = new address[][](roleIndexes.length);
        if (roleIndexes.length != 0) {
            uint256 tmplen;
            for (uint256 j = 0; j < roleIndexes.length; j++) {
                tmplen = _rolesByIndex[roleIndexes[j]].members.length();
                l[j] = new address[](tmplen);
                for (uint256 i = 0; i < tmplen; i++) {
                    l[j][i] = address(
                        _rolesByIndex[roleIndexes[j]].members.at(i)
                    );
                }
            }
        }
        return l;
    }

    function getAddressesByRole(
        uint8 roleIndex,
        uint256 offset,
        uint256 limit
    ) public view returns (address[][] memory) {
        address[][] memory l;

        l = new address[][](1);
        uint256 j = 0;
        uint256 tmplen = _rolesByIndex[roleIndex].members.length();

        uint256 count = offset > tmplen
            ? 0
            : (limit > (tmplen - offset) ? (tmplen - offset) : limit);

        l[j] = new address[](count);
        uint256 k = 0;
        for (uint256 i = offset; i < offset + count; i++) {
            l[j][k] = address(_rolesByIndex[roleIndex].members.at(i));
            k++;
        }

        return l;

        /*
        if (page == 0 || count == 0) {
            revert IncorrectInputParameters();
        }

        uint256 len = specialPurchasesList.length();
        uint256 ifrom = page*count-count;

        if (
            len == 0 || 
            ifrom >= len
        ) {
            ret = new address[](0);
        } else {

            count = ifrom+count > len ? len-ifrom : count ;
            ret = new address[](count);

            for (uint256 i = ifrom; i<ifrom+count; i++) {
                ret[i-ifrom] = specialPurchasesList.at(i);
                
            }
        }
        */
    }

    /**
     * @dev can be duplicate items in output. see https://github.com/Intercoin/CommunityContract/issues/4#issuecomment-1049797389
     * @notice Returns all roles which member belong to
     * @custom:shortd member's roles
     * @param accounts member's addresses
     * @return l two-dimensional array of roles
     */
    function getRoles(
        address[] memory accounts
    ) public view returns (uint8[][] memory) {
        uint8[][] memory l;

        l = new uint8[][](accounts.length);
        if (accounts.length != 0) {
            uint256 tmplen;
            for (uint256 j = 0; j < accounts.length; j++) {
                tmplen = _rolesByAddress[accounts[j]].length();
                l[j] = new uint8[](tmplen);
                for (uint256 i = 0; i < tmplen; i++) {
                    l[j][i] = _rolesByAddress[accounts[j]].get(i);
                }
            }
        }
        return l;
    }

    /**
     * @dev can be duplicate items in output. see https://github.com/Intercoin/CommunityContract/issues/4#issuecomment-1049797389
     * @notice if call without params then returns all existing roles
     * @custom:shortd all roles
     * @return arrays of (indexes, names, roleURIs)
     */
    function getRoles()
        public
        view
        returns (uint8[] memory, string[] memory, string[] memory)
    {
        uint8[] memory indexes = new uint8[](rolesCount - 1);
        string[] memory names = new string[](rolesCount - 1);
        string[] memory roleURIs = new string[](rolesCount - 1);
        // rolesCount start from 1
        for (uint8 i = 1; i < rolesCount; i++) {
            indexes[i - 1] = i;
            names[i - 1] = _rolesByIndex[i].name.bytes32ToString();
            roleURIs[i - 1] = _rolesByIndex[i].roleURI;
        }
        return (indexes, names, roleURIs);
    }

    /**
     * @notice count of members for that role
     * @custom:shortd count of members for role
     * @param roleIndex role index
     * @return count of members for that role
     */
    function addressesCount(uint8 roleIndex) public view returns (uint256) {
        return _rolesByIndex[roleIndex].members.length();
    }

    /**
     * @notice if call without params then returns count of all users which have at least one role
     * @custom:shortd all members count
     * @return count of members
     */
    function addressesCount() public view returns (uint256) {
        return addressesCounter;
    }

    /**
     * @notice is member has role
     * @custom:shortd checking is member belong to role
     * @param account user address
     * @param roleIndex role index
     * @return bool
     */
    function hasRole(
        address account,
        uint8 roleIndex
    ) public view returns (bool) {
        //require(_roles[rolename.stringToBytes32()] != 0, "Such role does not exists");
        return _rolesByAddress[account].contains(roleIndex);
    }

    /**
     * @notice return role index by name
     * @custom:shortd return role index by name
     * @param rolename role name in string
     * @return role index
     */
    function getRoleIndex(string memory rolename) public view returns (uint8) {
        return _roles[rolename.stringToBytes32()];
    }

    /**
     * @notice getting balance of owner address
     * @param account user's address
     * @custom:shortd part of ERC721
     */
    function balanceOf(
        address account
    ) public view override returns (uint256 balance) {
        for (uint8 i = 1; i < rolesCount; i++) {
            if (_isInRole(account, i)) {
                balance += 1;
            }
        }
    }

    /**
     * @notice getting owner of tokenId
     * @param tokenId tokenId
     * @custom:shortd part of ERC721
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        uint8 roleId = uint8(tokenId >> 160);
        address w = address(uint160(tokenId - (roleId << 160)));

        return (_isInRole(w, roleId)) ? w : address(0);
    }

    /**
     * @notice getting tokenURI(part of ERC721)
     * @custom:shortd getting tokenURI
     * @param tokenId token ID
     * @return tokenuri
     */
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        //_rolesByIndex[_roles[role.stringToBytes32()]].roleURI = roleURI;
        uint8 roleId = uint8(tokenId >> 160);
        address w = address(uint160(tokenId - (roleId << 160)));

        bytes memory bytesExtraURI = bytes(_rolesByIndex[roleId].extraURI[w]);

        if (bytesExtraURI.length != 0) {
            return _rolesByIndex[roleId].extraURI[w];
        } else {
            return _rolesByIndex[roleId].roleURI;
        }
    }

    /**
    * @dev output rolesindexes array only for that account will grant. 
    * for example: 
    roles array is ['role1','role2','role3','role4','some none exist role']. 
    Output can be like this [0,0,55,0,0]
    Means that account can grant only 'role3'
    */
    function getRolesWhichAccountCanGrant(
        address accountWhichWillGrant,
        //uint8 roleIndex
        string[] memory roleNames
    ) public view returns (uint8[] memory ret) {
        uint256 len = roleNames.length;
        ret = new uint8[](len);

        uint8 roleIndex;
        uint8[] memory rolesIndexesWhichWillGrant;
        uint8 roleIndexWhichCanGrant;
        for (uint256 i = 0; i < len; i++) {
            roleIndex = _roles[roleNames[i].stringToBytes32()];
            if (roleIndex != 0) {
                rolesIndexesWhichWillGrant = __rolesWhichCanGrant(
                    accountWhichWillGrant,
                    roleIndex
                );
                if (rolesIndexesWhichWillGrant.length != 0) {
                    (roleIndexWhichCanGrant, , ) = _getRoleWhichCanGrant(
                        rolesIndexesWhichWillGrant,
                        roleIndex
                    );
                    if (roleIndexWhichCanGrant != NONE_ROLE_INDEX) {
                        ret[i] = roleIndex;
                    }
                }
            }
        }
    }

    function getAuthorizedInviteManager() public view returns (address) {
        return defaultAuthorizedInviteManager;
    }

    ///////////////////////////////////////////////////////////
    /// internal section
    ///////////////////////////////////////////////////////////

    /**
     * @notice setting contractURI for this contract
     * @param uri uri
     * @custom:shortd setting tokenURI for role
     * @custom:calledby owners only
     */
    function _setContractURI(string memory uri) internal {
        contractURI = uri;
    }

    function _grantRoles(
        address accountWhichWillGrant,
        address[] memory accounts,
        uint8[] memory roleIndexes
    ) internal {
        // uint256 lengthAccounts = accounts.length;
        // uint256 lenRoles = roleIndexes.length;
        uint8[] memory rolesIndexWhichWillGrant;
        uint8 roleIndexWhichWillGrant;

        for (uint256 i = 0; i < roleIndexes.length; i++) {
            _isRoleValid(roleIndexes[i]);

            rolesIndexWhichWillGrant = _rolesWhichCanGrant(
                accountWhichWillGrant,
                roleIndexes[i],
                FlagFork.NONE
            );

            require(
                rolesIndexWhichWillGrant.length != 0,
                string(
                    abi.encodePacked(
                        "Sender can not grant role '",
                        _rolesByIndex[roleIndexes[i]].name.bytes32ToString(),
                        "'"
                    )
                )
            );

            roleIndexWhichWillGrant = validateGrantSettings(
                rolesIndexWhichWillGrant,
                roleIndexes[i],
                FlagFork.REVERT
            );

            for (uint256 j = 0; j < accounts.length; j++) {
                _grantRole(
                    roleIndexWhichWillGrant,
                    accountWhichWillGrant,
                    roleIndexes[i],
                    accounts[j]
                );
            }
        }
    }

    function _revokeRoles(
        address accountWhichWillRevoke,
        address[] memory accounts,
        uint8[] memory roleIndexes
    ) internal {
        uint8 roleWhichWillRevoke;

        for (uint256 i = 0; i < roleIndexes.length; i++) {
            _isRoleValid(roleIndexes[i]);

            roleWhichWillRevoke = NONE_ROLE_INDEX;
            if (
                _isInRole(accountWhichWillRevoke, _roles[DEFAULT_OWNERS_ROLE])
            ) {
                // owner can do anything. so no need to calculate or loop
                roleWhichWillRevoke = _roles[DEFAULT_OWNERS_ROLE];
            } else {
                for (
                    uint256 j = 0;
                    j < _rolesByAddress[accountWhichWillRevoke].length();
                    j++
                ) {
                    if (
                        _rolesByIndex[
                            uint8(
                                _rolesByAddress[accountWhichWillRevoke].get(j)
                            )
                        ].canRevokeRoles.contains(roleIndexes[i]) == true
                    ) {
                        roleWhichWillRevoke = _rolesByAddress[
                            accountWhichWillRevoke
                        ].get(j);
                        break;
                    }
                }
            }
            require(
                roleWhichWillRevoke != NONE_ROLE_INDEX,
                string(
                    abi.encodePacked(
                        "Sender can not revoke role '",
                        _rolesByIndex[roleIndexes[i]].name.bytes32ToString(),
                        "'"
                    )
                )
            );
            for (uint256 k = 0; k < accounts.length; k++) {
                _revokeRole(
                    /*roleWhichWillRevoke, */ accountWhichWillRevoke,
                    roleIndexes[i],
                    accounts[k]
                );
            }
        }
    }

    ///////////////////////////////////
    // ownable implementation with diff semantic
    /**
     * @dev will grantRoles([address], OWNERS_ROLE) and then revokeRoles(msg.caller, OWNERS_ROLE).
     * There is no need to have transferRole() function because normally no one can transfer their own roles unilaterally, except owners.
     * Instead they manage roles under them.
     */
    // The function renounceOwnership() will simply revokeRoles(getAddresses(OWNERS_ROLE), OWNERS_ROLE) from everyone who has it, including the caller.
    // This function is irreversible. The contract will be ownerless. The trackers should see the appropriate events/logs as from any Ownable interface.
    function _transferOwnership(address newOwner) internal override {
        address sender = _msgSender();
        if (newOwner == address(0)) {
            // if newOwner == address(0) it's just renounceOwnership()
            // we will simply revokeRoles(getAddresses(OWNERS_ROLE), OWNERS_ROLE) from everyone who has it, including the caller.
            EnumerableSetUpgradeable.AddressSet
                storage ownersList = _rolesByIndex[_roles[DEFAULT_OWNERS_ROLE]]
                    .members;
            uint256 len = ownersList.length();
            // loop through stack, due to reducing members in role, we just get address from zero position `len` times
            for (uint256 i = 0; i < len; i++) {
                _revokeRole(
                    sender,
                    _roles[DEFAULT_OWNERS_ROLE],
                    ownersList.at(0)
                );
            }
            emit RenounceOwnership();
        } else {
            _grantRole(
                _roles[DEFAULT_OWNERS_ROLE],
                sender,
                _roles[DEFAULT_OWNERS_ROLE],
                newOwner
            );
            _revokeRole(sender, _roles[DEFAULT_OWNERS_ROLE], sender);
            emit OwnershipTransferred(sender, newOwner);
        }
    }

    ///////////////////////////////////
    /**
     * @dev find which role can grant `roleIndex` to account
     * @param rolesWhichCanGrant array of role indexes which want to grant `roleIndex` to account
     * @param roleIndex target role index
     * @param flag flag which indicated what is need to do when error happens.
     *   if FlagFork.REVERT - when transaction will reverts,
     *   if FlagFork.EMIT - emit event `RoleAddedErrorMessage`
     *   otherwise - do nothing
     * @return uint8 role index which can grant `roleIndex` to account without error
     */
    function validateGrantSettings(
        uint8[] memory rolesWhichCanGrant,
        uint8 roleIndex,
        FlagFork flag
    ) internal returns (uint8) {
        uint8 roleWhichCanGrant;
        bool increaseCounter;
        uint64 newInterval;

        (
            roleWhichCanGrant,
            increaseCounter,
            newInterval
        ) = _getRoleWhichCanGrant(rolesWhichCanGrant, roleIndex);

        if (roleWhichCanGrant == NONE_ROLE_INDEX) {
            if (flag == FlagFork.REVERT) {
                revert("Max amount addresses exceeded");
            } else if (flag == FlagFork.EMIT) {
                emit RoleAddedErrorMessage(
                    _msgSender(),
                    "Max amount addresses exceeded"
                );
            }
        } else {
            if (increaseCounter) {
                _rolesByIndex[roleWhichCanGrant]
                    .grantSettings[roleIndex]
                    .grantedAddressesCounter += 1;
            }
            if (newInterval != 0) {
                _rolesByIndex[roleWhichCanGrant]
                    .grantSettings[roleIndex]
                    .lastIntervalIndex = newInterval;
                _rolesByIndex[roleWhichCanGrant]
                    .grantSettings[roleIndex]
                    .grantedAddressesCounter = 0;
            }
        }

        return roleWhichCanGrant;
    }

    /**
     * @notice is role can be granted by sender's roles?
     * @param sender sender
     * @param targetRoleIndex role index
     */
    function requireCanGrant(address sender, uint8 targetRoleIndex) internal {
        _rolesWhichCanGrant(sender, targetRoleIndex, FlagFork.REVERT);
    }

    /**
     * @param role role name
     */
    function _createRole(bytes32 role) internal {
        _roles[role] = rolesCount;
        _rolesByIndex[rolesCount].name = role;
        rolesCount += 1;

        if (hook != address(0)) {
            try
                ICommunityHook(hook).supportsInterface(
                    type(ICommunityHook).interfaceId
                )
            returns (bool) {
                ICommunityHook(hook).roleCreated(role, rolesCount);
            } catch {
                revert("wrong interface");
            }
        }
        emit RoleCreated(role, _msgSender());
    }

    /**
     * Set rules on how members with `sourceRole` can grant and revoke roles
     * @param byRole source role index
     * @param ofRole target role index
     * @param canGrantRole whether addresses with byRole can grant ofRole to other addresses
     * @param canRevokeRole whether addresses with byRole can revoke ofRole from other addresses
     * @param requireRole whether addresses with byRole can grant ofRole to other addresses
     * @param maxAddresses the maximum number of addresses that users with byRole can grant to ofRole in duration
     * @param duration duration
     *          if duration == 0 then no limit by time: `maxAddresses` will be max accounts on this role
     *          if maxAddresses == 0 then no limit max accounts on this role
     */
    function _manageRole(
        uint8 byRole,
        uint8 ofRole,
        bool canGrantRole,
        bool canRevokeRole,
        uint8 requireRole,
        uint256 maxAddresses,
        uint64 duration
    ) internal {
        _isRoleValid(byRole);
        _isRoleValid(ofRole);

        if (canGrantRole) {
            _rolesByIndex[byRole].canGrantRoles.add(ofRole);
        } else {
            _rolesByIndex[byRole].canGrantRoles.remove(ofRole);
        }

        if (canRevokeRole) {
            _rolesByIndex[byRole].canRevokeRoles.add(ofRole);
        } else {
            _rolesByIndex[byRole].canRevokeRoles.remove(ofRole);
        }

        _rolesByIndex[byRole].grantSettings[ofRole].requireRole = requireRole;
        _rolesByIndex[byRole].grantSettings[ofRole].maxAddresses = maxAddresses;
        _rolesByIndex[byRole].grantSettings[ofRole].duration = duration;

        emit RoleManaged(
            byRole,
            ofRole,
            canGrantRole,
            canRevokeRole,
            requireRole,
            maxAddresses,
            duration,
            _msgSender()
        );
    }

    /**
     * adding role to member
     * @param sourceRoleIndex sender role index
     * @param sourceAccount sender account's address
     * @param targetRoleIndex target role index
     * @param targetAccount target account's address
     */
    function _grantRole(
        uint8 sourceRoleIndex,
        address sourceAccount,
        uint8 targetRoleIndex,
        address targetAccount
    ) internal {
        if (_rolesByAddress[targetAccount].length() == 0) {
            addressesCounter++;
        }

        _rolesByAddress[targetAccount].add(targetRoleIndex);
        _rolesByIndex[targetRoleIndex].members.add(targetAccount);

        grantedBy[targetAccount].push(
            ActionInfo({
                actor: sourceAccount,
                timestamp: uint64(block.timestamp),
                extra: uint32(targetRoleIndex)
            })
        );
        granted[sourceAccount].push(
            ActionInfo({
                actor: targetAccount,
                timestamp: uint64(block.timestamp),
                extra: uint32(targetRoleIndex)
            })
        );

        _rolesByIndex[sourceRoleIndex]
            .grantSettings[targetRoleIndex]
            .grantedAddressesCounter += 1;

        if (hook != address(0)) {
            try
                ICommunityHook(hook).supportsInterface(
                    type(ICommunityHook).interfaceId
                )
            returns (bool) {
                ICommunityHook(hook).roleGranted(
                    _rolesByIndex[targetRoleIndex].name,
                    targetRoleIndex,
                    targetAccount
                );
            } catch {
                revert("wrong interface");
            }
        }
        emit RoleGranted(
            _rolesByIndex[targetRoleIndex].name,
            targetAccount,
            sourceAccount
        );
    }

    /**
     * removing role from member
     * param sourceRoleIndex sender role index *deprecated*
     * @param sourceAccount sender account's address
     * @param targetRoleIndex target role index
     * @param targetAccount target account's address
     */
    function _revokeRole(
        //uint8 sourceRoleIndex,
        address sourceAccount,
        uint8 targetRoleIndex,
        address targetAccount //address account, bytes32 targetRole
    ) internal {
        _rolesByAddress[targetAccount].remove(targetRoleIndex);
        _rolesByIndex[targetRoleIndex].members.remove(targetAccount);

        if (
            _rolesByAddress[targetAccount].length() == 0 &&
            addressesCounter != 0
        ) {
            addressesCounter--;
        }

        revokedBy[targetAccount].push(
            ActionInfo({
                actor: sourceAccount,
                timestamp: uint64(block.timestamp),
                extra: uint32(targetRoleIndex)
            })
        );
        revoked[sourceAccount].push(
            ActionInfo({
                actor: targetAccount,
                timestamp: uint64(block.timestamp),
                extra: uint32(targetRoleIndex)
            })
        );

        if (hook != address(0)) {
            try
                ICommunityHook(hook).supportsInterface(
                    type(ICommunityHook).interfaceId
                )
            returns (bool) {
                ICommunityHook(hook).roleRevoked(
                    _rolesByIndex[targetRoleIndex].name,
                    targetRoleIndex,
                    targetAccount
                );
            } catch {
                revert("wrong interface");
            }
        }
        emit RoleRevoked(
            _rolesByIndex[targetRoleIndex].name,
            targetAccount,
            sourceAccount
        );
    }

    function _rolesWhichCanGrant(
        address sender,
        uint8 targetRoleIndex,
        FlagFork flag
    ) internal returns (uint8[] memory rolesWhichCan) {
        rolesWhichCan = __rolesWhichCanGrant(sender, targetRoleIndex);

        if (rolesWhichCan.length == 0) {
            string memory errMsg = string(
                abi.encodePacked(
                    "Sender can not grant account with role '",
                    _rolesByIndex[targetRoleIndex].name.bytes32ToString(),
                    "'"
                )
            );
            if (flag == FlagFork.REVERT) {
                revert(errMsg);
            } else if (flag == FlagFork.EMIT) {
                emit RoleAddedErrorMessage(sender, errMsg);
            }
        }
    }

    ///////////////////////////////////////////////////////////
    /// internal section that are view
    ///////////////////////////////////////////////////////////

    function _isInRole(
        address target,
        uint8 targetRoleIndex
    ) internal view returns (bool) {
        return _rolesByAddress[target].contains(targetRoleIndex);
    }

    /**
     * @dev Throws if the sender is not in the DEFAULT_OWNERS_ROLE.
     */
    function _checkOwner() internal view override {
        require(
            _isInRole(_msgSender(), _roles[DEFAULT_OWNERS_ROLE]),
            "Ownable: caller is not the owner"
        );
    }

    function _msgSender()
        internal
        view
        override(ContextUpgradeable, TrustedForwarder)
        returns (address)
    {
        return TrustedForwarder._msgSender();
    }

    function _getRoleWhichCanGrant(
        uint8[] memory rolesWhichCanGrant,
        uint8 roleIndex
    )
        internal
        view
        returns (
            uint8 roleWhichCanGrant,
            bool increaseCounter,
            uint64 newInterval
        )
    {
        roleWhichCanGrant = NONE_ROLE_INDEX;

        for (uint256 i = 0; i < rolesWhichCanGrant.length; i++) {
            if (
                (_rolesByIndex[rolesWhichCanGrant[i]]
                    .grantSettings[roleIndex]
                    .maxAddresses == 0)
            ) {
                roleWhichCanGrant = rolesWhichCanGrant[i];
            } else {
                if (
                    _rolesByIndex[rolesWhichCanGrant[i]]
                        .grantSettings[roleIndex]
                        .duration == 0
                ) {
                    if (
                        _rolesByIndex[rolesWhichCanGrant[i]]
                            .grantSettings[roleIndex]
                            .grantedAddressesCounter +
                            1 <=
                        _rolesByIndex[rolesWhichCanGrant[i]]
                            .grantSettings[roleIndex]
                            .maxAddresses
                    ) {
                        roleWhichCanGrant = rolesWhichCanGrant[i];
                    }
                } else {
                    // get current interval index
                    uint64 interval = (uint64(block.timestamp) /
                        (
                            _rolesByIndex[rolesWhichCanGrant[i]]
                                .grantSettings[roleIndex]
                                .duration
                        )) *
                        (
                            _rolesByIndex[rolesWhichCanGrant[i]]
                                .grantSettings[roleIndex]
                                .duration
                        );
                    if (
                        interval ==
                        _rolesByIndex[rolesWhichCanGrant[i]]
                            .grantSettings[roleIndex]
                            .lastIntervalIndex
                    ) {
                        if (
                            _rolesByIndex[rolesWhichCanGrant[i]]
                                .grantSettings[roleIndex]
                                .grantedAddressesCounter +
                                1 <=
                            _rolesByIndex[rolesWhichCanGrant[i]]
                                .grantSettings[roleIndex]
                                .maxAddresses
                        ) {
                            roleWhichCanGrant = rolesWhichCanGrant[i];
                        }
                    } else {
                        roleWhichCanGrant = rolesWhichCanGrant[i];
                        //_rolesByIndex[roleWhichCanGrant].grantSettings[roleIndex].lastIntervalIndex = interval;
                        //_rolesByIndex[roleWhichCanGrant].grantSettings[roleIndex].grantedAddressesCounter = 0;
                        newInterval = interval;
                    }
                }
            }

            if (roleWhichCanGrant != NONE_ROLE_INDEX) {
                //_rolesByIndex[rolesWhichCanGrant[i]].grantSettings[roleIndex].grantedAddressesCounter += 1;
                increaseCounter = true;
                break;
            }
        }

        return (roleWhichCanGrant, increaseCounter, newInterval);
    }

    function __rolesWhichCanGrant(
        address sender,
        uint8 targetRoleIndex
    ) internal view returns (uint8[] memory) {
        //uint256 targetRoleID = uint256(targetRoleIndex);

        uint256 iLen;
        uint8[] memory rolesWhichCan;

        if (_isInRole(sender, _roles[DEFAULT_OWNERS_ROLE])) {
            // owner can do anything. so no need to calculate or loop
            rolesWhichCan = new uint8[](1);
            rolesWhichCan[0] = _roles[DEFAULT_OWNERS_ROLE];
        } else {
            iLen = 0;
            for (uint256 i = 0; i < _rolesByAddress[sender].length(); i++) {
                if (
                    _rolesByIndex[uint8(_rolesByAddress[sender].get(i))]
                        .canGrantRoles
                        .contains(targetRoleIndex) == true
                ) {
                    iLen++;
                }
            }

            rolesWhichCan = new uint8[](iLen);

            iLen = 0;
            for (uint256 i = 0; i < _rolesByAddress[sender].length(); i++) {
                if (
                    _rolesByIndex[uint8(_rolesByAddress[sender].get(i))]
                        .canGrantRoles
                        .contains(targetRoleIndex) == true
                ) {
                    rolesWhichCan[iLen] = _rolesByAddress[sender].get(i);
                    iLen++;
                }
            }
        }

        return rolesWhichCan;
    }

    /**
     * @notice does address belong to role
     * @param target address
     * @param targetRoleIndex role index
     */
    function requireInRole(
        address target,
        uint8 targetRoleIndex
    ) internal view {
        require(
            _isInRole(target, targetRoleIndex),
            string(
                abi.encodePacked(
                    "Missing role '",
                    _rolesByIndex[targetRoleIndex].name.bytes32ToString(),
                    "'"
                )
            )
        );
    }

    function _isRoleValid(uint8 index) internal view {
        require((rolesCount > index), "invalid role");
    }

    function requireAuthorizedManager() internal view {
        if (_msgSender() != defaultAuthorizedInviteManager) {
            revert AuthorizedInviteManagerOnly();
        }
    }

    //////////////////////////////////////
    /**
     * @notice
     * @custom:shortd
     */
    function operationReverted() internal pure {
        revert("CommunityContract: NOT_AUTHORIZED");
    }

    /**
     * @notice getting part of ERC721
     * @custom:shortd part of ERC721
     */
    function safeTransferFrom(
        address /*from*/,
        address /*to*/,
        uint256 /*tokenId*/
    ) external pure override {
        operationReverted();
    }

    /**
     * @notice getting part of ERC721
     * @custom:shortd part of ERC721
     */
    function transferFrom(
        address /*from*/,
        address /*to*/,
        uint256 /*tokenId*/
    ) external pure override {
        operationReverted();
    }

    /**
     * @notice getting part of ERC721
     * @custom:shortd part of ERC721
     */
    function approve(
        address /*to*/,
        uint256 /*tokenId*/
    ) external pure override {
        operationReverted();
    }

    /**
     * @notice getting part of ERC721
     * @custom:shortd part of ERC721
     */
    function getApproved(
        uint256 /* tokenId*/
    ) external pure override returns (address /* operator*/) {
        operationReverted();
    }

    /**
     * @notice getting part of ERC721
     * @custom:shortd part of ERC721
     */
    function setApprovalForAll(
        address /*operator*/,
        bool /*_approved*/
    ) external pure override {
        operationReverted();
    }

    /**
     * @notice getting part of ERC721
     * @custom:shortd part of ERC721
     */
    function isApprovedForAll(
        address /*owner*/,
        address /*operator*/
    ) external pure override returns (bool) {
        operationReverted();
    }

    /**
     * @notice getting part of ERC721
     * @custom:shortd part of ERC721
     */
    function safeTransferFrom(
        address /*from*/,
        address /*to*/,
        uint256 /*tokenId*/,
        bytes calldata /*data*/
    ) external pure override {
        operationReverted();
    }

    /**
     * @notice getting part of ERC721
     * @custom:shortd part of ERC721
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    ////////////////////////////////////////////
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface ICommunity {
    function initialize(
        address hook,
        address invitedHook,
        address costManager,
        address authorizedInviteManager,
        string memory name,
        string memory symbol,
        string memory contractUri
    ) external;

    function addressesCount(uint8 roleIndex) external view returns (uint256);

    function getRoles(
        address[] calldata accounts
    ) external view returns (uint8[][] memory);

    function getAddresses(
        uint8[] calldata rolesIndexes
    ) external view returns (address[][] memory);

    function getRolesWhichAccountCanGrant(
        address accountWhichWillGrant,
        string[] memory roleNames
    ) external view returns (uint8[] memory);

    function hasRole(
        address account,
        uint8 roleIndex
    ) external view returns (bool);

    function grantRoles(
        address[] memory accounts,
        uint8[] memory roleIndexes
    ) external;

    function revokeRoles(
        address[] memory accounts,
        uint8[] memory roleIndexes
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title interface represents hook contract that can be called every time when role created/granted/revoked
 */
interface ICommunityHook is IERC165 {
    function roleGranted(
        bytes32 role,
        uint8 roleIndex,
        address account
    ) external;

    function roleRevoked(
        bytes32 role,
        uint8 roleIndex,
        address account
    ) external;

    function roleCreated(bytes32 role, uint8 roleIndex) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface ICommunityInvite {
    function invitedHook() external view returns (address);

    function getAuthorizedInviteManager() external view returns (address);

    function grantRolesExternal(
        address accountWhichWillGrant,
        address[] memory accounts,
        uint8[] memory roleIndexes
    ) external;

    function revokeRolesExternal(
        address accountWhichWillRevoke,
        address[] memory accounts,
        uint8[] memory roleIndexes
    ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

//import "hardhat/console.sol";
/**
 * 
 */
library PackedSet {
    // pow                                                                                                      
    // 6 - means 2**6 = 64. 64 times in uint256 fill completely by max value 0xf                ((2**4)-1)  and MAX SLOTS AND mapping index key = ((2**4)-1)/64 = 0+1 = 1
    // 5 - means 2**5 = 32. 32 times in uint256 fill completely by max value 0xff               ((2**8)-1)  and MAX SLOTS AND mapping index key = ((2**8)-1)/32 = 7+1 = 8
    // 4 - means 2**4 = 16. 16 times in uint256 fill completely by max value 0xffff             ((2**16)-1) and MAX SLOTS AND mapping index key = ((2**16)-1)/16 = 0+1 = 4095
    // 3 - 2**3=8.           8 times in uint256 fill completely by max value 0xffffffff         ((2**32)-1) and MAX SLOTS AND mapping index key = ((2**32)-1)/4 = 0+1 = 1073741823
    // 2 - 2**2=4.           4 times in uint256 fill completely by max value 0xffffffffffffffff ((2**64)-1) and MAX SLOTS AND mapping index key = ((2**64)-1)/2 = 0+1 = 9223372036854775807
    // 1 - 2**1=2.           2 times in uint256 fill completely by max value                    ((2**128)-1)
    // summary 
    // best to use 6.5.4  because have a low iteration in indexes to find already exist item

    uint256 private constant pow = 5;
    uint256 private constant powMaxVal = 256/(2**pow);
    struct Set {
        // mapKey - key in mapping
        // key - position in mapping value 
        // value value at position key in mapping value
        // for example
        // if store [0=>65535 1=>4369 2=>13107]
        // in packed mapping we will store 
        // in mapkey = 0 value "ffff111133330000000000000000000000000000000000000000000000000000"
        // where 0xffff, 0x1111, 0x3333 it's 65535,4369,13107 respectively,  with indexes 0,1,2
        mapping(uint256 => uint256) list;

        uint256 size;

    }
  
    function _push(Set storage _set, uint256 value) private returns (bool ret) {
        (,ret) = _contains(_set, value);
        if (!ret) {
            _update(_set, _set.size, value);
            _set.size += 1;
            ret = !ret;
        }
        return ret;
    }

    function _pop(Set storage _set, uint256 value) private returns (bool) {
        //uint256 key;
        (uint256 key, bool ret) = _contains(_set, value);
        if (ret) {
            uint256 lastKey = _set.size-1;
            uint256 lastVal = _get(_set, lastKey);

            _update(_set, key, lastVal);

            _update(_set, lastKey, 0);
            _set.size -= 1;
            
            return true;
        } else {
            return false;
        }
    }

    function _get(Set storage _set, uint256 key) private view returns (uint256 ret) {

        uint256 mapId = key >> pow;
        uint256 mapVal = _set.list[mapId];
        uint256 mapValueIndex = uint256((key) - ((key>>pow)<<pow)) + 1;
        uint256 bitOffset = (256-mapValueIndex*powMaxVal);

        uint256 maxPowVal = (2**(powMaxVal)-1);

        ret = uint16( (mapVal & (maxPowVal<<bitOffset))>>bitOffset);
    }

     /**
     * @dev Returns true if the value is in the set. O(size + maxSizeInUint256).
     */
    function _contains(Set storage _set, uint256 value) private view returns (uint256, bool) {
        uint256 maxSizeInUint256 = 2**pow;
        uint256 bitOffset;

        for (uint256 i=0; i < _set.size; i++) {
            for (uint256 j=0; j < maxSizeInUint256; j++) {
                bitOffset = (256-(uint256(j)*powMaxVal));
                if (value == uint256( (_set.list[i] & (( ((2**(256/(2**pow)))-1) )<<bitOffset))>>bitOffset)) {
                    return (i*(maxSizeInUint256)+j-1,true);
                }
            }
        }
        return (0,false);
    }


    function _update(Set storage _set, uint256 key, uint256 value) private {
        
        uint256 mapId = key >> pow;
        uint256 mapVal = _set.list[mapId];
        uint256 mapValueIndex = uint256((key) - ((key>>pow)<<pow)) + 1;
        uint256 bitOffset = (256-mapValueIndex*powMaxVal);

        uint256 maxPowVal = (2**(powMaxVal)-1);
        uint256 zeroMask = (type(uint256).max)^( maxPowVal <<(bitOffset));
        uint256 valueMask = uint256(value)<<bitOffset;

        _set.list[mapId] = (mapVal & zeroMask | valueMask);

    }

    function get(Set storage _set, uint256 key) internal view returns (uint8 ret) {
        ret = uint8(_get(_set, key));
    }

    function add(Set storage _set, uint8 value) internal {
        _push(_set, uint256(value));
    }

    function remove(Set storage _set, uint8 value) internal {
        _pop(_set, uint256(value));
    }

    function contains(Set storage _set, uint256 value) internal view returns (bool ret) {
        (, ret) = _contains(_set, value);
    }

    function length(Set storage _set) internal view returns (uint256) {
        return _set.size;
    }
    
    // function getZeroSlot(Set storage _set) internal view returns(uint256) {
    //     return _set.list[0];
    // }
    
/*
    function getBatch(Map storage map, uint256[] memory keys) internal view returns (uint16[] memory values) {
        values = new uint16[](keys.length);
        for(uint256 i = 0; i< keys.length; i++) {
            values[i] = _get(map, keys[i]);
        }
    }

    function setBatch(Map storage map, uint256[] memory keys, uint16[] memory values) internal {
        for(uint256 i = 0; i< keys.length; i++) {
            _set(map, keys[i], values[i]);
        }
        
    }
*/
}

// SPDX-License-Identifier: MIT
/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <[email protected]>
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a 'slice'. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first '.',
 *      modifying s to only contain the remainder of the string after the '.'.
 *      In situations where you do not want to modify the original slice, you
 *      can make a copy first with `.copy()`, for example:
 *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 *      Solidity has no memory management, it will result in allocating many
 *      short-lived slices that are later discarded.
 *
 *      Functions that return two slices come in two versions: a non-allocating
 *      version that takes the second slice as an argument, modifying it in
 *      place, and an allocating version that allocates and returns the second
 *      slice; see `nextRune` for example.
 *
 *      Functions that have to copy string data will return strings rather than
 *      slices; these can be cast back to slices for further processing if
 *      required.
 *
 *      For convenience, some functions are provided with non-modifying
 *      variants that create a new slice and return both; for instance,
 *      `s.splitNew('.')` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 */

pragma solidity ^0.8.0;

library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint _dest, uint _src, uint _len) private pure {
        // Copy word-length chunks while possible
        for(; _len >= 32; _len -= 32) {
            assembly {
                mstore(_dest, mload(_src))
            }
            _dest += 32;
            _src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - _len) - 1;
        assembly {
            let srcpart := and(mload(_src), not(mask))
            let destpart := and(mload(_dest), mask)
            mstore(_dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Returns the length of a null-terminated bytes32 string.
     * @param self The value to find the length of.
     * @return The length of the string, from 0 to 32.
     */
    function len(bytes32 self) internal pure returns (uint) {
        uint ret;
        if (self == 0)
            return 0;
        if (uint(self) & 0xffffffffffffffffffffffffffffffff == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (uint(self) & 0xffffffffffffffff == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (uint(self) & 0xffffffff == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (uint(self) & 0xffff == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (uint(self) & 0xff == 0) {
            ret += 1;
        }
        return 32 - ret;
    }

    /*
     * @dev Returns a slice containing the entire bytes32, interpreted as a
     *      null-terminated utf-8 string.
     * @param self The bytes32 value to convert to a slice.
     * @return A new slice containing the value of the input argument up to the
     *         first null.
     */
    function toSliceB32(bytes32 self) internal pure returns (slice memory ret) {
        // Allocate space for `self` in memory, copy it there, and point ret at it
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }

    /*
     * @dev Returns a new slice containing the same data as the current slice.
     * @param self The slice to copy.
     * @return A new slice containing the same data as `self`.
     */
    function copy(slice memory self) internal pure returns (slice memory) {
        return slice(self._len, self._ptr);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice's text.
     */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    /*
     * @dev Returns the length in runes of the slice. Note that this operation
     *      takes time proportional to the length of the slice; avoid using it
     *      in loops, and call `slice.empty()` if you only need to know whether
     *      the slice is empty or not.
     * @param self The slice to operate on.
     * @return The length of the slice in runes.
     */
    function len(slice memory self) internal pure returns (uint l) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        uint ptr = self._ptr - 31;
        uint end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly { b := and(mload(ptr), 0xFF) }
            if (b < 0x80) {
                ptr += 1;
            } else if(b < 0xE0) {
                ptr += 2;
            } else if(b < 0xF0) {
                ptr += 3;
            } else if(b < 0xF8) {
                ptr += 4;
            } else if(b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }

    /*
     * @dev Returns true if the slice is empty (has a length of 0).
     * @param self The slice to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function empty(slice memory self) internal pure returns (bool) {
        return self._len == 0;
    }

    /*
     * @dev Returns a positive number if `other` comes lexicographically after
     *      `self`, a negative number if it comes before, or zero if the
     *      contents of the two slices are equal. Comparison is done per-rune,
     *      on unicode codepoints.
     * @param self The first slice to compare.
     * @param other The second slice to compare.
     * @return The result of the comparison.
     */
    function compare(slice memory self, slice memory other) internal pure returns (int) {
        uint shortest = self._len;
        if (other._len < self._len)
            shortest = other._len;

        uint selfptr = self._ptr;
        uint otherptr = other._ptr;
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                // uint256 mask = uint256(-1); // 0xffff...
                uint256 mask = type(uint256).max; // 0xffff...
                if(shortest < 32) {
                  mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                }
                uint256 diff = (a & mask) - (b & mask);
                if (diff != 0)
                    return int(diff);
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }

    /*
     * @dev Returns true if the two slices contain the same text.
     * @param self The first slice to compare.
     * @param self The second slice to compare.
     * @return True if the slices are equal, false otherwise.
     */
    function equals(slice memory self, slice memory other) internal pure returns (bool) {
        return compare(self, other) == 0;
    }

    /*
     * @dev Extracts the first rune in the slice into `rune`, advancing the
     *      slice to point to the next rune and returning `self`.
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextRune(slice memory self, slice memory rune) internal pure returns (slice memory) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint l;
        uint b;
        // Load the first byte of the rune into the LSBs of b
        assembly { b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF) }
        if (b < 0x80) {
            l = 1;
        } else if(b < 0xE0) {
            l = 2;
        } else if(b < 0xF0) {
            l = 3;
        } else {
            l = 4;
        }

        // Check for truncated codepoints
        if (l > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += l;
        self._len -= l;
        rune._len = l;
        return rune;
    }

    /*
     * @dev Returns the first rune in the slice, advancing the slice to point
     *      to the next rune.
     * @param self The slice to operate on.
     * @return A slice containing only the first rune from `self`.
     */
    function nextRune(slice memory self) internal pure returns (slice memory ret) {
        nextRune(self, ret);
    }

    /*
     * @dev Returns the number of the first codepoint in the slice.
     * @param self The slice to operate on.
     * @return The number of the first codepoint in the slice.
     */
    function ord(slice memory self) internal pure returns (uint ret) {
        if (self._len == 0) {
            return 0;
        }

        uint word;
        uint length;
        uint divisor = 2 ** 248;

        // Load the rune into the MSBs of b
        assembly { word:= mload(mload(add(self, 32))) }
        uint b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if(b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if(b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }

        // Check for truncated codepoints
        if (length > self._len) {
            return 0;
        }

        for (uint i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) {
                // Invalid UTF-8 sequence
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

    /*
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return The hash of the slice.
     */
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

    /*
     * @dev Returns true if `self` starts with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function startsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }
        return equal;
    }

    /*
     * @dev If `self` starts with `needle`, `needle` is removed from the
     *      beginning of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function beyond(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

    /*
     * @dev Returns true if the slice ends with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function endsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        uint selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }

        return equal;
    }

    /*
     * @dev If `self` ends with `needle`, `needle` is removed from the
     *      end of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function until(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        uint selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr >= end)
                        return selfptr + selflen;
                    ptr++;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    // Returns the memory address of the first byte after the last occurrence of
    // `needle` in `self`, or the address of `self` if not found.
    function rfindPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr <= selfptr)
                        return selfptr;
                    ptr--;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr + needlelen;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

    /*
     * @dev Modifies `self` to contain everything from the first occurrence of
     *      `needle` to the end of the slice. `self` is set to the empty slice
     *      if `needle` is not found.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function find(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

    /*
     * @dev Modifies `self` to contain the part of the string from the start of
     *      `self` to the end of the first occurrence of `needle`. If `needle`
     *      is not found, `self` is set to the empty slice.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function rfind(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        split(self, needle, token);
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and `token` to everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function rsplit(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and returning everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` after the last occurrence of `delim`.
     */
    function rsplit(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        rsplit(self, needle, token);
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(slice memory self, slice memory needle) internal pure returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }

    /*
     * @dev Returns True if `self` contains `needle`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return True if `needle` is found in `self`, false otherwise.
     */
    function contains(slice memory self, slice memory needle) internal pure returns (bool) {
        return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(slice memory self, slice memory other) internal pure returns (string memory) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

    /*
     * @dev Joins an array of slices, using `self` as a delimiter, returning a
     *      newly allocated string.
     * @param self The delimiter to use.
     * @param parts A list of slices to join.
     * @return A newly allocated string containing all the slices in `parts`,
     *         joined with `self`.
     */
    function join(slice memory self, slice[] memory parts) internal pure returns (string memory) {
        if (parts.length == 0)
            return "";

        uint length = self._len * (parts.length - 1);
        for(uint i = 0; i < parts.length; i++)
            length += parts[i]._len;

        string memory ret = new string(length);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        for(uint256 i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "./strings.sol";

library StringUtils {
    
    using strings for string;
    using strings for strings.slice;
    /**
     * convert string to bytes32
     * @param source string variable
     */
    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
    
    /**
     * convert bytes32 to string
     * @param _bytes32 bytes32 variable
     */
    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
    
    /**
     * convert string to lowercase
     */
    function _toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                // So we add 32 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
    
    // Convert an hexadecimal character to their value
    function fromHexChar(uint8 c) internal pure returns (uint8 r) {
        if (bytes1(c) >= bytes1('0') && bytes1(c) <= bytes1('9')) {
            r = c - uint8(bytes1('0'));
            return r;
        }
        if (bytes1(c) >= bytes1('a') && bytes1(c) <= bytes1('f')) {
            r = 10 + c - uint8(bytes1('a'));
            return r;
        }
        if (bytes1(c) >= bytes1('A') && bytes1(c) <= bytes1('F')) {
            r = 10 + c - uint8(bytes1('A'));
            return r;
        }
    }
    
    // Convert an hexadecimal string to raw bytes
    function fromHex(string memory s) internal pure returns (bytes memory) {
        bytes memory ss = bytes(s);
        require(ss.length%2 == 0); // length must be even
        bytes memory r = new bytes(ss.length/2);
        for (uint i=0; i<ss.length/2; ++i) {
            r[i] = bytes1(fromHexChar(uint8(ss[2*i])) * 16 +
                        fromHexChar(uint8(ss[2*i+1])));
        }
        return r;
    }
    
    function slice(string memory _s, string memory _delim) internal pure returns(string[] memory) {                                               
        strings.slice memory s = _s.toSlice();                
        strings.slice memory delim = _delim.toSlice();                            
        string[] memory parts = new string[](s.count(delim)+1);                  
        for (uint i = 0; i < parts.length; i++) {                              
           parts[i] = s.split(delim).toString();                               
        }   
        
        return parts;
    }  
    
    function parseAddr(string memory _a) internal pure returns (address _parsedAddress) {
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i = 2; i < 2 + 2 * 20; i += 2) {
            iaddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i + 1]));
            if ((b1 >= 97) && (b1 <= 102)) {
                b1 -= 87;
            } else if ((b1 >= 65) && (b1 <= 70)) {
                b1 -= 55;
            } else if ((b1 >= 48) && (b1 <= 57)) {
                b1 -= 48;
            }
            if ((b2 >= 97) && (b2 <= 102)) {
                b2 -= 87;
            } else if ((b2 >= 65) && (b2 <= 70)) {
                b2 -= 55;
            } else if ((b2 >= 48) && (b2 <= 57)) {
                b2 -= 48;
            }
            iaddr += (b1 * 16 + b2);
        }
        return address(iaddr);
    }
    
}