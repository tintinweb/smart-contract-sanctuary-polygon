// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/**
 * @title Proxy
 * @notice Proxy is a transparent proxy that passes through the call if the caller is the owner or
 *         if the caller is address(0), meaning that the call originated from an off-chain
 *         simulation.
 */
contract Proxy {
    /**
     * @notice The storage slot that holds the address of the implementation.
     *         bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
     */
    bytes32 internal constant IMPLEMENTATION_KEY =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @notice The storage slot that holds the address of the owner.
     *         bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1)
     */
    bytes32 internal constant OWNER_KEY =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @notice An event that is emitted each time the implementation is changed. This event is part
     *         of the EIP-1967 specification.
     *
     * @param implementation The address of the implementation contract
     */
    event Upgraded(address indexed implementation);

    /**
     * @notice An event that is emitted each time the owner is upgraded. This event is part of the
     *         EIP-1967 specification.
     *
     * @param previousAdmin The previous owner of the contract
     * @param newAdmin      The new owner of the contract
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @notice A modifier that reverts if not called by the owner or by address(0) to allow
     *         eth_call to interact with this proxy without needing to use low-level storage
     *         inspection. We assume that nobody is able to trigger calls from address(0) during
     *         normal EVM execution.
     */
    modifier proxyCallIfNotAdmin() {
        if (msg.sender == _getAdmin() || msg.sender == address(0)) {
            _;
        } else {
            // This WILL halt the call frame on completion.
            _doProxyCall();
        }
    }

    /**
     * @notice Sets the initial admin during contract deployment. Admin address is stored at the
     *         EIP-1967 admin storage slot so that accidental storage collision with the
     *         implementation is not possible.
     *
     * @param _admin Address of the initial contract admin. Admin as the ability to access the
     *               transparent proxy interface.
     */
    constructor(address _admin) {
        _changeAdmin(_admin);
    }

    // slither-disable-next-line locked-ether
    receive() external payable {
        // Proxy call by default.
        _doProxyCall();
    }

    // slither-disable-next-line locked-ether
    fallback() external payable {
        // Proxy call by default.
        _doProxyCall();
    }

    /**
     * @notice Set the implementation contract address. The code at the given address will execute
     *         when this contract is called.
     *
     * @param _implementation Address of the implementation contract.
     */
    function upgradeTo(address _implementation) public virtual proxyCallIfNotAdmin {
        _setImplementation(_implementation);
    }

    /**
     * @notice Set the implementation and call a function in a single transaction. Useful to ensure
     *         atomic execution of initialization-based upgrades.
     *
     * @param _implementation Address of the implementation contract.
     * @param _data           Calldata to delegatecall the new implementation with.
     */
    function upgradeToAndCall(address _implementation, bytes calldata _data)
        public
        payable
        virtual
        proxyCallIfNotAdmin
        returns (bytes memory)
    {
        _setImplementation(_implementation);
        (bool success, bytes memory returndata) = _implementation.delegatecall(_data);
        require(success, "Proxy: delegatecall to new implementation contract failed");
        return returndata;
    }

    /**
     * @notice Changes the owner of the proxy contract. Only callable by the owner.
     *
     * @param _admin New owner of the proxy contract.
     */
    function changeAdmin(address _admin) public virtual proxyCallIfNotAdmin {
        _changeAdmin(_admin);
    }

    /**
     * @notice Gets the owner of the proxy contract.
     *
     * @return Owner address.
     */
    function admin() public virtual proxyCallIfNotAdmin returns (address) {
        return _getAdmin();
    }

    /**
     * @notice Queries the implementation address.
     *
     * @return Implementation address.
     */
    function implementation() public virtual proxyCallIfNotAdmin returns (address) {
        return _getImplementation();
    }

    /**
     * @notice Sets the implementation address.
     *
     * @param _implementation New implementation address.
     */
    function _setImplementation(address _implementation) internal {
        assembly {
            sstore(IMPLEMENTATION_KEY, _implementation)
        }
        emit Upgraded(_implementation);
    }

    /**
     * @notice Changes the owner of the proxy contract.
     *
     * @param _admin New owner of the proxy contract.
     */
    function _changeAdmin(address _admin) internal {
        address previous = _getAdmin();
        assembly {
            sstore(OWNER_KEY, _admin)
        }
        emit AdminChanged(previous, _admin);
    }

    /**
     * @notice Performs the proxy call via a delegatecall.
     */
    function _doProxyCall() internal {
        address impl = _getImplementation();
        require(impl != address(0), "Proxy: implementation not initialized");

        assembly {
            // Copy calldata into memory at 0x0....calldatasize.
            calldatacopy(0x0, 0x0, calldatasize())

            // Perform the delegatecall, make sure to pass all available gas.
            let success := delegatecall(gas(), impl, 0x0, calldatasize(), 0x0, 0x0)

            // Copy returndata into memory at 0x0....returndatasize. Note that this *will*
            // overwrite the calldata that we just copied into memory but that doesn't really
            // matter because we'll be returning in a second anyway.
            returndatacopy(0x0, 0x0, returndatasize())

            // Success == 0 means a revert. We'll revert too and pass the data up.
            if iszero(success) {
                revert(0x0, returndatasize())
            }

            // Otherwise we'll just return and pass the data up.
            return(0x0, returndatasize())
        }
    }

    /**
     * @notice Queries the implementation address.
     *
     * @return Implementation address.
     */
    function _getImplementation() internal view returns (address) {
        address impl;
        assembly {
            impl := sload(IMPLEMENTATION_KEY)
        }
        return impl;
    }

    /**
     * @notice Queries the owner of the proxy contract.
     *
     * @return Owner address.
     */
    function _getAdmin() internal view returns (address) {
        address owner;
        assembly {
            owner := sload(OWNER_KEY)
        }
        return owner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title Lib_MerkleTree
 * @author River Keefer
 */
library Lib_MerkleTree {
    /**********************
     * Internal Functions *
     **********************/

    /**
     * Calculates a merkle root for a list of 32-byte leaf hashes.  WARNING: If the number
     * of leaves passed in is not a power of two, it pads out the tree with zero hashes.
     * If you do not know the original length of elements for the tree you are verifying, then
     * this may allow empty leaves past _elements.length to pass a verification check down the line.
     * Note that the _elements argument is modified, therefore it must not be used again afterwards
     * @param _elements Array of hashes from which to generate a merkle root.
     * @return Merkle root of the leaves, with zero hashes for non-powers-of-two (see above).
     */
    function getMerkleRoot(bytes32[] memory _elements) internal pure returns (bytes32) {
        require(_elements.length > 0, "Lib_MerkleTree: Must provide at least one leaf hash.");

        if (_elements.length == 1) {
            return _elements[0];
        }

        uint256[16] memory defaults = [
            0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563,
            0x633dc4d7da7256660a892f8f1604a44b5432649cc8ec5cb3ced4c4e6ac94dd1d,
            0x890740a8eb06ce9be422cb8da5cdafc2b58c0a5e24036c578de2a433c828ff7d,
            0x3b8ec09e026fdc305365dfc94e189a81b38c7597b3d941c279f042e8206e0bd8,
            0xecd50eee38e386bd62be9bedb990706951b65fe053bd9d8a521af753d139e2da,
            0xdefff6d330bb5403f63b14f33b578274160de3a50df4efecf0e0db73bcdd3da5,
            0x617bdd11f7c0a11f49db22f629387a12da7596f9d1704d7465177c63d88ec7d7,
            0x292c23a9aa1d8bea7e2435e555a4a60e379a5a35f3f452bae60121073fb6eead,
            0xe1cea92ed99acdcb045a6726b2f87107e8a61620a232cf4d7d5b5766b3952e10,
            0x7ad66c0a68c72cb89e4fb4303841966e4062a76ab97451e3b9fb526a5ceb7f82,
            0xe026cc5a4aed3c22a58cbd3d2ac754c9352c5436f638042dca99034e83636516,
            0x3d04cffd8b46a874edf5cfae63077de85f849a660426697b06a829c70dd1409c,
            0xad676aa337a485e4728a0b240d92b3ef7b3c372d06d189322bfd5f61f1e7203e,
            0xa2fca4a49658f9fab7aa63289c91b7c7b6c832a6d0e69334ff5b0a3483d09dab,
            0x4ebfd9cd7bca2505f7bef59cc1c12ecc708fff26ae4af19abe852afe9e20c862,
            0x2def10d13dd169f550f578bda343d9717a138562e0093b380a1120789d53cf10
        ];

        // Reserve memory space for our hashes.
        bytes memory buf = new bytes(64);

        // We'll need to keep track of left and right siblings.
        bytes32 leftSibling;
        bytes32 rightSibling;

        // Number of non-empty nodes at the current depth.
        uint256 rowSize = _elements.length;

        // Current depth, counting from 0 at the leaves
        uint256 depth = 0;

        // Common sub-expressions
        uint256 halfRowSize; // rowSize / 2
        bool rowSizeIsOdd; // rowSize % 2 == 1

        while (rowSize > 1) {
            halfRowSize = rowSize / 2;
            rowSizeIsOdd = rowSize % 2 == 1;

            for (uint256 i = 0; i < halfRowSize; i++) {
                leftSibling = _elements[(2 * i)];
                rightSibling = _elements[(2 * i) + 1];
                assembly {
                    mstore(add(buf, 32), leftSibling)
                    mstore(add(buf, 64), rightSibling)
                }

                _elements[i] = keccak256(buf);
            }

            if (rowSizeIsOdd) {
                leftSibling = _elements[rowSize - 1];
                rightSibling = bytes32(defaults[depth]);
                assembly {
                    mstore(add(buf, 32), leftSibling)
                    mstore(add(buf, 64), rightSibling)
                }

                _elements[halfRowSize] = keccak256(buf);
            }

            rowSize = halfRowSize + (rowSizeIsOdd ? 1 : 0);
            depth++;
        }

        return _elements[0];
    }

    /**
     * Verifies a merkle branch for the given leaf hash.  Assumes the original length
     * of leaves generated is a known, correct input, and does not return true for indices
     * extending past that index (even if _siblings would be otherwise valid.)
     * @param _root The Merkle root to verify against.
     * @param _leaf The leaf hash to verify inclusion of.
     * @param _index The index in the tree of this leaf.
     * @param _siblings Array of sibline nodes in the inclusion proof, starting from depth 0
     * (bottom of the tree).
     * @param _totalLeaves The total number of leaves originally passed into.
     * @return Whether or not the merkle branch and leaf passes verification.
     */
    function verify(
        bytes32 _root,
        bytes32 _leaf,
        uint256 _index,
        bytes32[] memory _siblings,
        uint256 _totalLeaves
    ) internal pure returns (bool) {
        require(_totalLeaves > 0, "Lib_MerkleTree: Total leaves must be greater than zero.");

        require(_index < _totalLeaves, "Lib_MerkleTree: Index out of bounds.");

        require(
            _siblings.length == _ceilLog2(_totalLeaves),
            "Lib_MerkleTree: Total siblings does not correctly correspond to total leaves."
        );

        bytes32 computedRoot = _leaf;

        for (uint256 i = 0; i < _siblings.length; i++) {
            if ((_index & 1) == 1) {
                computedRoot = keccak256(abi.encodePacked(_siblings[i], computedRoot));
            } else {
                computedRoot = keccak256(abi.encodePacked(computedRoot, _siblings[i]));
            }

            _index >>= 1;
        }

        return _root == computedRoot;
    }

    /*********************
     * Private Functions *
     *********************/

    /**
     * Calculates the integer ceiling of the log base 2 of an input.
     * @param _in Unsigned input to calculate the log.
     * @return ceil(log_base_2(_in))
     */
    function _ceilLog2(uint256 _in) private pure returns (uint256) {
        require(_in > 0, "Lib_MerkleTree: Cannot compute ceil(log_2) of 0.");

        if (_in == 1) {
            return 0;
        }

        // Find the highest set bit (will be floor(log_2)).
        // Borrowed with <3 from https://github.com/ethereum/solidity-examples
        uint256 val = _in;
        uint256 highest = 0;
        for (uint256 i = 128; i >= 1; i >>= 1) {
            if (val & (((uint256(1) << i) - 1) << i) != 0) {
                highest += i;
                val >>= i;
            }
        }

        // Increment by one if this is not a perfect logarithm.
        if ((uint256(1) << highest) != _in) {
            highest += 1;
        }

        return highest;
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
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
pragma solidity ^0.8.15;

/**
 * @notice Struct representing the state of a ChugSplash deployment.
 */
struct DeploymentState {
    DeploymentStatus status;
    bool[] actions;
    uint256 targets;
    bytes32 actionRoot;
    bytes32 targetRoot;
    uint256 actionsExecuted;
    uint256 timeClaimed;
    address selectedExecutor;
    bool remoteExecution;
}

/**
 * @notice Struct representing a ChugSplash action.
 */
struct ChugSplashAction {
    ChugSplashActionType actionType;
    bytes data;
    address payable addr;
    bytes32 contractKindHash;
    string referenceName;
}

/**
 * @notice Struct representing a ChugSplash target.
 */
struct ChugSplashTarget {
    string projectName;
    string referenceName;
    address payable addr;
    address implementation;
    bytes32 contractKindHash;
}

/**
 * @notice Enum representing possible ChugSplash action types.
 */
enum ChugSplashActionType {
    SET_STORAGE,
    DEPLOY_CONTRACT
}

/**
 * @notice Enum representing the status of a given ChugSplash action.
 */
enum DeploymentStatus {
    EMPTY,
    PROPOSED,
    APPROVED,
    INITIATED,
    COMPLETED,
    CANCELLED
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {
    DeploymentState,
    ChugSplashAction,
    ChugSplashTarget,
    ChugSplashActionType,
    DeploymentStatus
} from "./ChugSplashDataTypes.sol";
import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Proxy } from "@eth-optimism/contracts-bedrock/contracts/universal/Proxy.sol";
import { ChugSplashRegistry } from "./ChugSplashRegistry.sol";
import { IChugSplashManager } from "./interfaces/IChugSplashManager.sol";
import { IProxyAdapter } from "./interfaces/IProxyAdapter.sol";
import {
    Lib_MerkleTree as MerkleTree
} from "@eth-optimism/contracts/libraries/utils/Lib_MerkleTree.sol";
import {
    ReentrancyGuardUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { ICreate2 } from "./interfaces/ICreate2.sol";
import { Semver, Version } from "./Semver.sol";
import { IGasPriceCalculator } from "./interfaces/IGasPriceCalculator.sol";

/**
 * @title ChugSplashManager
 */

contract ChugSplashManager is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    Semver,
    IChugSplashManager
{
    bytes32 internal constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");

    bytes32 internal constant PROTOCOL_PAYMENT_RECIPIENT_ROLE =
        keccak256("PROTOCOL_PAYMENT_RECIPIENT_ROLE");

    bytes32 internal constant MANAGED_PROPOSER_ROLE = keccak256("MANAGED_PROPOSER_ROLE");

    bytes32 internal constant NO_PROXY_CONTRACT_KIND_HASH = keccak256("no-proxy");

    /**
     * @notice Address of the ChugSplashRegistry.
     */
    ChugSplashRegistry public immutable registry;

    ICreate2 public immutable create2;

    IGasPriceCalculator public immutable gasPriceCalculator;

    IAccessControl public immutable managedService;

    /**
     * @notice Amount that must be deposited in this contract in order to execute a deployment. The
     *         project owner can withdraw this amount whenever a deployment is not active. This bond
     *         will be forfeited if the project owner cancels a deployment that is in progress,
               which is
     *         necessary to prevent owners from trolling the executor by immediately cancelling and
     *         withdrawing funds.
     */
    uint256 public immutable ownerBondAmount;

    /**
     * @notice Amount of time for an executor to finish executing a deployment once they have
       claimed
     *         it. If the owner cancels an active deployment within this time period, their bond is
     *         forfeited to the executor. This prevents users from trolling executors by immediately
     *         cancelling active deployments.
     */
    uint256 public immutable executionLockTime;

    /**
     * @notice Amount that the executor is paid, denominated as a percentage of the cost of
     *         execution. For example: if a deployment costs 1 gwei to execute and the
     *         executorPaymentPercentage is 10, then the executor will profit 0.1 gwei.
     */
    uint256 public immutable executorPaymentPercentage;

    uint256 public immutable protocolPaymentPercentage;

    /**
     * @notice Mapping of executor addresses to the ETH amount stored in this contract that is
     *         owed to them.
     */
    mapping(address => uint256) public executorDebt;

    /**
     * @notice Maps an address to a boolean indicating if the address is allowed to propose
       deployments.
     */
    mapping(address => bool) public proposers;

    /**
     * @notice Mapping of deployment IDs to deployment state.
     */
    mapping(bytes32 => DeploymentState) internal _deployments;

    /**
     * @notice ID of the organization this contract is managing.
     */
    bytes32 public organizationID;

    /**
     * @notice ID of the currently active deployment.
     */
    bytes32 public activeDeploymentId;

    /**
     * @notice ETH amount that is owed to the executor.
     */
    uint256 public totalExecutorDebt;

    uint256 public totalProtocolDebt;

    bool public allowManagedProposals;

    /**
     * @notice Emitted when a ChugSplash deployment is proposed.
     *
     * @param deploymentId   ID of the deployment being proposed.
     * @param actionRoot Root of the proposed deployment's merkle tree.
     * @param numActions Number of steps in the proposed deployment.
     * @param configUri  URI of the config file that can be used to re-generate the deployment.
     */
    event ChugSplashDeploymentProposed(
        bytes32 indexed deploymentId,
        bytes32 actionRoot,
        bytes32 targetRoot,
        uint256 numActions,
        uint256 numTargets,
        string configUri,
        bool remoteExecution,
        address proposer
    );

    /**
     * @notice Emitted when a ChugSplash deployment is approved.
     *
     * @param deploymentId ID of the deployment being approved.
     */
    event ChugSplashDeploymentApproved(bytes32 indexed deploymentId);

    /**
     * @notice Emitted when a ChugSplash action is executed.
     *
     * @param deploymentId    Unique ID for the deployment.
     * @param proxy       Address of the proxy on which the event was executed.
     * @param executor    Address of the executor that executed the action.
     * @param actionIndex Index within the deployment hash of the action that was executed.
     */
    event ChugSplashActionExecuted(
        bytes32 indexed deploymentId,
        address indexed proxy,
        address indexed executor,
        uint256 actionIndex
    );

    /**
     * @notice Emitted when a ChugSplash deployment is initiated.
     *
     * @param deploymentId        Unique ID for the deployment.
     * @param executor        Address of the executor that initiated the deployment.
     */
    event ChugSplashDeploymentInitiated(bytes32 indexed deploymentId, address indexed executor);

    /**
     * @notice Emitted when a ChugSplash deployment is completed.
     *
     * @param deploymentId        Unique ID for the deployment.
     * @param executor        Address of the executor that completed the deployment.
     * @param actionsExecuted Total number of completed actions.
     */
    event ChugSplashDeploymentCompleted(
        bytes32 indexed deploymentId,
        address indexed executor,
        uint256 actionsExecuted
    );

    /**
     * @notice Emitted when an active ChugSplash deployment is cancelled.
     *
     * @param deploymentId        Deployment ID that was cancelled.
     * @param owner           Owner of the ChugSplashManager.
     * @param actionsExecuted Total number of completed actions before cancellation.
     */
    event ChugSplashDeploymentCancelled(
        bytes32 indexed deploymentId,
        address indexed owner,
        uint256 actionsExecuted
    );

    /**
     * @notice Emitted when ownership of a proxy is transferred from the ProxyAdmin to the project
     *         owner.
     *
     * @param proxy            Address of the proxy that is the subject of the ownership transfer.
     * @param contractKindHash The contract kind. I.e transparent, UUPS, or no proxy.
     * @param newOwner         Address of the project owner that is receiving ownership of the
     *                         proxy.
     */
    event ProxyOwnershipTransferred(
        address indexed proxy,
        bytes32 indexed contractKindHash,
        address newOwner
    );

    /**
     * @notice Emitted when a deployment is claimed by an executor.
     *
     * @param deploymentId ID of the deployment that was claimed.
     * @param executor Address of the executor that claimed the deployment ID for the project.
     */
    event ChugSplashDeploymentClaimed(bytes32 indexed deploymentId, address indexed executor);

    /**
     * @notice Emitted when an executor claims a payment.
     *
     * @param executor The executor being paid.
     */
    event ExecutorPaymentClaimed(address indexed executor, uint256 withdrawn, uint256 remaining);

    event ProtocolPaymentClaimed(address indexed recipient, uint256 amount);

    /**
     * @notice Emitted when the owner withdraws ETH from this contract.
     *
     * @param owner  Address that initiated the withdrawal.
     * @param amount ETH amount withdrawn.
     */
    event OwnerWithdrewETH(address indexed owner, uint256 amount);

    /**
     * @notice Emitted when the owner of this contract adds or removes a new proposer.
     *
     * @param proposer Address of the proposer that was added.
     * @param proposer Address of the owner.
     */
    event ProposerSet(address indexed proposer, bool indexed isProposer, address indexed owner);

    event ToggledManagedProposals(bool isManaged, address indexed owner);

    /**
     * @notice Emitted when ETH is deposited in this contract
     */
    event ETHDeposited(address indexed from, uint256 indexed amount);

    /**
     * @notice Emitted when a default proxy is deployed by this contract.
     *
     * @param proxy             Address of the deployed proxy.
     * @param deploymentId          ID of the deployment in which the proxy was deployed.
     * @param referenceName     String reference name.
     */
    event DefaultProxyDeployed(
        bytes32 indexed salt,
        address indexed proxy,
        bytes32 indexed deploymentId,
        string projectName,
        string referenceName
    );

    /**
     * @notice Emitted when a contract is deployed.
     *
     * @param referenceNameHash Hash of the reference name.
     * @param contractAddress   Address of the deployed contract.
     * @param deploymentId          ID of the deployment in which the contract was deployed.
     * @param referenceName     String reference name.
     */
    event ContractDeployed(
        string indexed referenceNameHash,
        address indexed contractAddress,
        bytes32 indexed deploymentId,
        string referenceName
    );

    event ContractDeploymentSkipped(
        string indexed referenceNameHash,
        address indexed contractAddress,
        bytes32 indexed deploymentId,
        string referenceName
    );

    /**
     * @notice Modifier that restricts access to the executor.
     */
    modifier onlyExecutor() {
        require(
            managedService.hasRole(EXECUTOR_ROLE, msg.sender),
            "ChugSplashManager: caller is not executor"
        );
        _;
    }

    /**
     * @param _registry                  Address of the ChugSplashRegistry.
     * @param _executionLockTime         Amount of time for an executor to completely execute a
     *                                   deployment after claiming it.
     * @param _ownerBondAmount           Amount that must be deposited in this contract in order to
     *                                   execute a deployment.
     * @param _executorPaymentPercentage Amount that an executor will earn from completing a
       deployment,
     *                                   denominated as a percentage.
     */
    constructor(
        ChugSplashRegistry _registry,
        ICreate2 _create2,
        IGasPriceCalculator _gasPriceCalculator,
        IAccessControl _managedService,
        uint256 _executionLockTime,
        uint256 _ownerBondAmount,
        uint256 _executorPaymentPercentage,
        uint256 _protocolPaymentPercentage,
        Version memory _version
    ) Semver(_version.major, _version.minor, _version.patch) {
        registry = _registry;
        create2 = _create2;
        gasPriceCalculator = _gasPriceCalculator;
        managedService = _managedService;
        executionLockTime = _executionLockTime;
        ownerBondAmount = _ownerBondAmount;
        executorPaymentPercentage = _executorPaymentPercentage;
        protocolPaymentPercentage = _protocolPaymentPercentage;
    }

    /**
     * @notice Allows anyone to send ETH to this contract.
     */
    receive() external payable {
        emit ETHDeposited(msg.sender, msg.value);
        registry.announce("ETHDeposited");
    }

    /**
     * @param _data Arbitrary initialization data, allows for future manager versions to use the
     *               same interface.
     *              In this version, we expect the following data:
     *              - address _owner: Address of the owner of this contract.
     *              - bytes32 _organizationID: ID of the organization this contract is managing.
     *              - bool _allowManagedProposals: Whether or not to allow upgrade proposals from
     *                the ChugSplash managed service.
     */
    function initialize(bytes memory _data) external initializer returns (bytes memory) {
        (address _owner, bytes32 _organizationID, bool _allowManagedProposals) = abi.decode(
            _data,
            (address, bytes32, bool)
        );

        organizationID = _organizationID;
        allowManagedProposals = _allowManagedProposals;

        __ReentrancyGuard_init();
        __Ownable_init();
        _transferOwnership(_owner);

        return "";
    }

    /**
     * @notice Propose a new ChugSplash deployment to be approved. Only callable by the owner of
       this
     *         contract or a proposer. These permissions are required to prevent spam.
     *
     * @param _actionRoot Root of the deployment's merkle tree.
     * @param _numActions Number of elements in the deployment's tree.
     * @param _configUri  URI pointing to the config file for the deployment.
     */
    function proposeChugSplashDeployment(
        bytes32 _actionRoot,
        bytes32 _targetRoot,
        uint256 _numActions,
        uint256 _numTargets,
        string memory _configUri,
        bool _remoteExecution
    ) external {
        require(isProposer(msg.sender), "ChugSplashManager: caller must be proposer");

        // Compute the deployment ID.
        bytes32 deploymentId = keccak256(
            abi.encode(_actionRoot, _targetRoot, _numActions, _numTargets, _configUri)
        );

        DeploymentState storage deployment = _deployments[deploymentId];

        DeploymentStatus status = deployment.status;
        require(
            status == DeploymentStatus.EMPTY ||
                status == DeploymentStatus.COMPLETED ||
                status == DeploymentStatus.CANCELLED,
            "ChugSplashManager: deployment cannot be proposed"
        );

        deployment.status = DeploymentStatus.PROPOSED;
        deployment.actionRoot = _actionRoot;
        deployment.targetRoot = _targetRoot;
        deployment.actions = new bool[](_numActions);
        deployment.targets = _numTargets;
        deployment.remoteExecution = _remoteExecution;

        emit ChugSplashDeploymentProposed(
            deploymentId,
            _actionRoot,
            _targetRoot,
            _numActions,
            _numTargets,
            _configUri,
            _remoteExecution,
            msg.sender
        );
        registry.announceWithData("ChugSplashDeploymentProposed", abi.encodePacked(msg.sender));
    }

    /**
     * @notice Allows the owner to approve a deployment to be executed. There must be at least
     *         `ownerBondAmount` deposited in this contract in order for a deployment to be
               approved.
     *         The owner can send the bond to this contract via a call to `depositETH` or `receive`.
     *         This bond will be forfeited if the project owner cancels an approved deployment. Also
     *         note that the deployment can be executed as soon as it is approved.
     *
     * @param _deploymentId ID of the deployment to approve
     */
    function approveChugSplashDeployment(bytes32 _deploymentId) external onlyOwner {
        DeploymentState storage deployment = _deployments[_deploymentId];

        if (deployment.remoteExecution) {
            require(
                address(this).balance - totalDebt() >= ownerBondAmount,
                "ChugSplashManager: insufficient balance in manager"
            );
        }

        require(
            deployment.status == DeploymentStatus.PROPOSED,
            "ChugSplashManager: deployment must be proposed"
        );

        require(
            activeDeploymentId == bytes32(0),
            "ChugSplashManager: another deployment is active"
        );

        activeDeploymentId = _deploymentId;
        deployment.status = DeploymentStatus.APPROVED;

        emit ChugSplashDeploymentApproved(_deploymentId);
        registry.announce("ChugSplashDeploymentApproved");
    }

    function executeEntireDeployment(
        ChugSplashTarget[] memory _targets,
        bytes32[][] memory _targetProofs,
        ChugSplashAction[] memory _actions,
        uint256[] memory _actionIndexes,
        bytes32[][] memory _actionProofs
    ) external {
        initiateExecution(_targets, _targetProofs);
        executeActions(_actions, _actionIndexes, _actionProofs);
        completeExecution(_targets, _targetProofs);
    }

    /**
     * @notice **WARNING**: Cancellation is a potentially dangerous action and should not be
     *         executed unless in an emergency.
     *
     *         Cancels an active ChugSplash deployment. If an executor has not claimed the
               deployment,
     *         the owner is simply allowed to withdraw their bond via a subsequent call to
     *         `withdrawOwnerETH`. Otherwise, cancelling a deployment will cause the project owner
               to
     *         forfeit their bond to the executor, and will also allow the executor to refund their
     *         own bond.
     */
    function cancelActiveChugSplashDeployment() external onlyOwner {
        require(activeDeploymentId != bytes32(0), "ChugSplashManager: no active deployment");

        DeploymentState storage deployment = _deployments[activeDeploymentId];

        if (
            deployment.remoteExecution &&
            deployment.timeClaimed + executionLockTime >= block.timestamp
        ) {
            // Give the owner's bond to the executor if the deployment is cancelled within the
            // `executionLockTime` window.
            totalExecutorDebt += ownerBondAmount;
        }

        bytes32 cancelledDeploymentId = activeDeploymentId;
        activeDeploymentId = bytes32(0);
        deployment.status = DeploymentStatus.CANCELLED;

        emit ChugSplashDeploymentCancelled(
            cancelledDeploymentId,
            msg.sender,
            deployment.actionsExecuted
        );
        registry.announce("ChugSplashDeploymentCancelled");
    }

    /**
     * @notice Allows an executor to post a bond of `executorBondAmount` to claim the sole right to
     *         execute actions for a deployment over a period of `executionLockTime`. Only the first
     *         executor to post a bond gains this right. Executors must finish executing the
               deployment
     *         within `executionLockTime` or else another executor may claim the deployment. Note
               that
     *         this strategy creates a PGA for the transaction to claim the deployment but removes
               PGAs
     *         during the execution process.
     */
    function claimDeployment() external onlyExecutor {
        require(activeDeploymentId != bytes32(0), "ChugSplashManager: no deployment is active");

        DeploymentState storage deployment = _deployments[activeDeploymentId];

        require(deployment.remoteExecution, "ChugSplashManager: local execution only");

        require(
            block.timestamp > deployment.timeClaimed + executionLockTime,
            "ChugSplashManager: deployment already claimed"
        );

        deployment.timeClaimed = block.timestamp;
        deployment.selectedExecutor = msg.sender;

        emit ChugSplashDeploymentClaimed(activeDeploymentId, msg.sender);
        registry.announce("ChugSplashDeploymentClaimed");
    }

    /**
     * @notice Allows executors to claim their ETH payments. Executors may only withdraw an amount
     *         less than or equal to the amount of ETH owed to them by this contract. We allow the
     *         executor to withdraw less than the amount owed to them because it's possible that the
     *         executor's debt exceeds the amount of ETH stored in this contract. This situation can
     *         occur when the executor completes an underfunded deployment.
     */
    function claimExecutorPayment(uint256 _amount) external onlyExecutor {
        require(_amount > 0, "ChugSplashManager: amount cannot be 0");
        require(
            executorDebt[msg.sender] >= _amount,
            "ChugSplashManager: insufficient executor debt"
        );

        executorDebt[msg.sender] -= _amount;
        totalExecutorDebt -= _amount;

        emit ExecutorPaymentClaimed(msg.sender, _amount, executorDebt[msg.sender]);

        (bool success, ) = payable(msg.sender).call{ value: _amount }(new bytes(0));
        require(success, "ChugSplashManager: failed to withdraw");

        registry.announce("ExecutorPaymentClaimed");
    }

    function claimProtocolPayment() external {
        require(
            managedService.hasRole(PROTOCOL_PAYMENT_RECIPIENT_ROLE, msg.sender),
            "ChugSplashManager: caller is not payment recipient"
        );

        uint256 amount = totalProtocolDebt;
        totalProtocolDebt = 0;

        emit ProtocolPaymentClaimed(msg.sender, amount);

        // slither-disable-next-line arbitrary-send-eth
        (bool success, ) = payable(msg.sender).call{ value: amount }(new bytes(0));
        require(success, "ChugSplashManager: failed to withdraw funds");

        registry.announce("ProtocolPaymentClaimed");
    }

    /**
     * @notice Transfers ownership of a proxy from this contract to a given address. Note that this
     *         function allows project owners to send ownership of their proxy to address(0), which
     *         would make their proxy non-upgradeable.
     *
     * @param _newOwner  Address of the project owner that is receiving ownership of the proxy.
     */
    function exportProxy(
        address payable _proxy,
        bytes32 _contractKindHash,
        address _newOwner
    ) external onlyOwner {
        require(_proxy.code.length > 0, "ChugSplashManager: invalid proxy");
        require(activeDeploymentId == bytes32(0), "ChugSplashManager: deployment is active");

        // Get the adapter that corresponds to this contract type.
        address adapter = registry.adapters(_contractKindHash);
        require(adapter != address(0), "ChugSplashManager: invalid contract kind");

        emit ProxyOwnershipTransferred(_proxy, _contractKindHash, _newOwner);

        // Delegatecall the adapter to change ownership of the proxy. slither-disable-next-line
        // controlled-delegatecall
        (bool success, ) = adapter.delegatecall(
            abi.encodeCall(IProxyAdapter.changeProxyAdmin, (_proxy, _newOwner))
        );
        require(success, "ChugSplashManager: proxy admin change failed");

        registry.announce("ProxyOwnershipTransferred");
    }

    /**
     * @notice Allows the project owner to withdraw all funds in this contract minus the debt
     *         owed to the executor. Cannot be called when there is an active deployment.
     */
    function withdrawOwnerETH() external onlyOwner {
        require(
            activeDeploymentId == bytes32(0),
            "ChugSplashManager: cannot withdraw during active deployment"
        );

        uint256 amount = address(this).balance - totalDebt();

        emit OwnerWithdrewETH(msg.sender, amount);

        (bool success, ) = payable(msg.sender).call{ value: amount }(new bytes(0));
        require(success, "ChugSplashManager: call to withdraw owner funds failed");

        registry.announce("OwnerWithdrewETH");
    }

    /**
     * @notice Allows the owner of this contract to add or remove a proposer.
     *
     * @param _proposer Address of the proposer to add or remove.
     */
    function setProposer(address _proposer, bool _isProposer) external onlyOwner {
        proposers[_proposer] = _isProposer;

        emit ProposerSet(_proposer, _isProposer, msg.sender);
        registry.announceWithData("ProposerSet", abi.encodePacked(_isProposer));
    }

    function toggleAllowManagedProposals() external onlyOwner {
        allowManagedProposals = !allowManagedProposals;

        emit ToggledManagedProposals(allowManagedProposals, msg.sender);
        registry.announceWithData(
            "ToggledManagedProposals",
            abi.encodePacked(allowManagedProposals)
        );
    }

    /**
     * @notice Gets the DeploymentState struct for a given deployment ID. Note that we explicitly
     *         define this function because the getter auto-generated by Solidity doesn't return
     *         array members of structs: https://github.com/ethereum/solidity/issues/12792. Without
     *         this function, we wouldn't be able to return `DeploymentState.actions`.
     *
     * @param _deploymentId Deployment ID.
     *
     * @return DeploymentState struct.
     */
    function deployments(bytes32 _deploymentId) external view returns (DeploymentState memory) {
        return _deployments[_deploymentId];
    }

    /**
     * @notice Returns whether or not a deployment is currently being executed.
     *         Used to determine if the manager implementation can safely be upgraded.
     */
    function isExecuting() external view returns (bool) {
        return activeDeploymentId != bytes32(0);
    }

    /**
     * @notice Initiate the execution of a deployment. Note that non-proxied contracts are not
     *         included in the target deployment.
     *
     * @param _targets Array of ChugSplashTarget objects.
     * @param _proofs  Array of Merkle proofs.
     */
    function initiateExecution(
        ChugSplashTarget[] memory _targets,
        bytes32[][] memory _proofs
    ) public nonReentrant {
        uint256 initialGasLeft = gasleft();

        DeploymentState storage deployment = _deployments[activeDeploymentId];

        _assertCallerIsOwnerOrSelectedExecutor(deployment.remoteExecution);

        require(
            deployment.status == DeploymentStatus.APPROVED,
            "ChugSplashManager: deployment status is not approved"
        );

        uint256 numTargets = _targets.length;
        require(numTargets == deployment.targets, "ChugSplashManager: incorrect number of targets");

        ChugSplashTarget memory target;
        bytes32[] memory proof;
        for (uint256 i = 0; i < numTargets; i++) {
            target = _targets[i];
            proof = _proofs[i];

            require(
                target.contractKindHash != NO_PROXY_CONTRACT_KIND_HASH,
                "ChugSplashManager: only proxies allowed in target deployment"
            );

            require(
                MerkleTree.verify(
                    deployment.targetRoot,
                    keccak256(
                        abi.encode(
                            target.projectName,
                            target.referenceName,
                            target.addr,
                            target.implementation,
                            target.contractKindHash
                        )
                    ),
                    i,
                    proof,
                    deployment.targets
                ),
                "ChugSplashManager: invalid deployment target proof"
            );

            if (target.contractKindHash == bytes32(0) && target.addr.code.length == 0) {
                bytes32 salt = keccak256(abi.encode(target.projectName, target.referenceName));
                Proxy created = new Proxy{ salt: salt }(address(this));

                // Could happen if insufficient gas is supplied to this transaction, should not
                // happen otherwise. If there's a situation in which this could happen other than a
                // standard OOG, then this would halt the entire execution process.
                require(
                    address(created) == target.addr,
                    "ChugSplashManager: Proxy was not created correctly"
                );

                emit DefaultProxyDeployed(
                    salt,
                    target.addr,
                    activeDeploymentId,
                    target.projectName,
                    target.referenceName
                );
                registry.announceWithData("DefaultProxyDeployed", abi.encodePacked(target.addr));
            }

            address adapter = registry.adapters(target.contractKindHash);
            require(adapter != address(0), "ChugSplashManager: invalid contract kind");

            // Set the proxy's implementation to be a ProxyUpdater. Updaters ensure that only the
            // ChugSplashManager can interact with a proxy that is in the process of being updated.
            // Note that we use the Updater contract to provide a generic interface for updating a
            // variety of proxy types. Note no adapter is necessary for non-proxied contracts as
            // they are not upgradable and cannot have state. slither-disable-next-line
            // controlled-delegatecall
            (bool success, ) = adapter.delegatecall(
                abi.encodeCall(IProxyAdapter.initiateExecution, (target.addr))
            );
            require(success, "ChugSplashManager: failed to set implementation to an updater");
        }

        // Mark the deployment as initiated.
        deployment.status = DeploymentStatus.INITIATED;

        emit ChugSplashDeploymentInitiated(activeDeploymentId, msg.sender);
        registry.announce("ChugSplashDeploymentInitiated");

        _payExecutorAndProtocol(initialGasLeft, deployment.remoteExecution);
    }

    /**
     * @notice Executes multiple ChugSplash actions within the current active deployment for a
       project.
     *         Actions can only be executed once. A re-entrancy guard is added to prevent a
     *         contract's constructor from calling another contract which in turn
     *         calls back into this function. Only callable by the executor.
     *
     * @param _actions       Array of SetStorage/DeployContract actions to execute.
     * @param _actionIndexes Array of action indexes.
     * @param _proofs        Array of Merkle proofs for each action.
     */
    function executeActions(
        ChugSplashAction[] memory _actions,
        uint256[] memory _actionIndexes,
        bytes32[][] memory _proofs
    ) public nonReentrant {
        uint256 initialGasLeft = gasleft();

        DeploymentState storage deployment = _deployments[activeDeploymentId];

        require(
            deployment.status == DeploymentStatus.INITIATED,
            "ChugSplashManager: deployment status must be initiated"
        );

        _assertCallerIsOwnerOrSelectedExecutor(deployment.remoteExecution);

        uint256 numActions = _actions.length;
        ChugSplashAction memory action;
        uint256 actionIndex;
        bytes32[] memory proof;
        for (uint256 i = 0; i < numActions; i++) {
            action = _actions[i];
            actionIndex = _actionIndexes[i];
            proof = _proofs[i];

            require(
                !deployment.actions[actionIndex],
                "ChugSplashManager: action has already been executed"
            );

            require(
                MerkleTree.verify(
                    deployment.actionRoot,
                    keccak256(
                        abi.encode(
                            action.referenceName,
                            action.addr,
                            action.actionType,
                            action.contractKindHash,
                            action.data
                        )
                    ),
                    actionIndex,
                    proof,
                    deployment.actions.length
                ),
                "ChugSplashManager: invalid deployment action proof"
            );

            // Get the adapter for this reference name.
            address adapter = registry.adapters(action.contractKindHash);

            action.contractKindHash == NO_PROXY_CONTRACT_KIND_HASH
                ? require(
                    action.actionType == ChugSplashActionType.DEPLOY_CONTRACT,
                    "ChugSplashManager: invalid action type for non-proxy contract"
                )
                : require(adapter != address(0), "ChugSplashManager: proxy type has no adapter");

            // Mark the action as executed and update the total number of executed actions.
            deployment.actionsExecuted++;
            deployment.actions[actionIndex] = true;

            // Next, we execute the ChugSplash action by calling deployContract/setStorage.
            if (action.actionType == ChugSplashActionType.DEPLOY_CONTRACT) {
                _deployContract(action.referenceName, action.data);
            } else if (action.actionType == ChugSplashActionType.SET_STORAGE) {
                (bytes32 key, uint8 offset, bytes memory val) = abi.decode(
                    action.data,
                    (bytes32, uint8, bytes)
                );
                _setProxyStorage(action.addr, adapter, key, offset, val);
            } else {
                revert("ChugSplashManager: unknown action type");
            }

            emit ChugSplashActionExecuted(activeDeploymentId, action.addr, msg.sender, actionIndex);
            registry.announceWithData("ChugSplashActionExecuted", abi.encodePacked(action.addr));
        }

        _payExecutorAndProtocol(initialGasLeft, deployment.remoteExecution);
    }

    /**
     * @notice Completes the deployment by upgrading all proxies to their new implementations. This
     *         occurs in a single transaction to ensure that all proxies are initialized at the same
     *         time. Note that this function will revert if it is called before all of the SetCode
     *         and DeployContract actions have been executed in `executeChugSplashAction`.
     *         Only callable by the executor.
     *
     * @param _targets Array of ChugSplashTarget objects.
     * @param _proofs  Array of Merkle proofs.
     */
    function completeExecution(
        ChugSplashTarget[] memory _targets,
        bytes32[][] memory _proofs
    ) public nonReentrant {
        uint256 initialGasLeft = gasleft();

        DeploymentState storage deployment = _deployments[activeDeploymentId];

        _assertCallerIsOwnerOrSelectedExecutor(deployment.remoteExecution);

        require(
            activeDeploymentId != bytes32(0),
            "ChugSplashManager: no deployment has been approved for execution"
        );

        require(
            deployment.actionsExecuted == deployment.actions.length,
            "ChugSplashManager: deployment was not executed completely"
        );

        uint256 numTargets = _targets.length;
        require(numTargets == deployment.targets, "ChugSplashManager: incorrect number of targets");

        ChugSplashTarget memory target;
        bytes32[] memory proof;
        for (uint256 i = 0; i < numTargets; i++) {
            target = _targets[i];
            proof = _proofs[i];

            require(
                target.contractKindHash != NO_PROXY_CONTRACT_KIND_HASH,
                "ChugSplashManager: only proxies allowed in target deployment"
            );

            require(
                MerkleTree.verify(
                    deployment.targetRoot,
                    keccak256(
                        abi.encode(
                            target.projectName,
                            target.referenceName,
                            target.addr,
                            target.implementation,
                            target.contractKindHash
                        )
                    ),
                    i,
                    proof,
                    deployment.targets
                ),
                "ChugSplashManager: invalid deployment target proof"
            );

            // Get the proxy type and adapter for this reference name.
            address adapter = registry.adapters(target.contractKindHash);
            require(adapter != address(0), "ChugSplashManager: invalid contract kind");

            // Upgrade the proxy's implementation contract.
            (bool success, ) = adapter.delegatecall(
                abi.encodeCall(
                    IProxyAdapter.completeExecution,
                    (target.addr, target.implementation)
                )
            );
            require(success, "ChugSplashManger: failed to complete execution");
        }

        // Mark the deployment as completed and reset the active deployment hash so that a new
        // deployment can be executed.
        deployment.status = DeploymentStatus.COMPLETED;
        bytes32 completedDeploymentId = activeDeploymentId;
        activeDeploymentId = bytes32(0);

        emit ChugSplashDeploymentCompleted(
            completedDeploymentId,
            msg.sender,
            deployment.actionsExecuted
        );
        registry.announce("ChugSplashDeploymentCompleted");

        _payExecutorAndProtocol(initialGasLeft, deployment.remoteExecution);
    }

    function isProposer(address _addr) public view returns (bool) {
        return
            (allowManagedProposals && managedService.hasRole(MANAGED_PROPOSER_ROLE, _addr)) ||
            proposers[_addr] ||
            _addr == owner();
    }

    function totalDebt() public view returns (uint256) {
        return totalExecutorDebt + totalProtocolDebt;
    }

    /**
     * @notice Queries the selected executor for a given project/deployment.
     *
     * @param _deploymentId ID of the deployment currently being executed.
     *
     * @return Address of the selected executor.
     */
    function getSelectedExecutor(bytes32 _deploymentId) public view returns (address) {
        DeploymentState storage deployment = _deployments[_deploymentId];
        return deployment.selectedExecutor;
    }

    function _payExecutorAndProtocol(uint256 _initialGasLeft, bool _remoteExecution) internal {
        if (!_remoteExecution) {
            return;
        }

        uint256 gasPrice = gasPriceCalculator.getGasPrice();

        // Estimate the gas used by the calldata. Note that, in general, 16 gas is used per non-zero
        // byte of calldata and 4 gas is used per zero-byte of calldata. We use 16 for simplicity
        // and because we must overestimate the executor's payment to ensure that it doesn't lose
        // money.
        uint256 calldataGasUsed = msg.data.length * 16;

        // Estimate the total gas used in this transaction. We calculate this by adding the gas used
        // by the calldata with the net estimated gas used by this function so far (i.e.
        // `_initialGasLeft - gasleft()`). We add 100k to account for the intrinsic gas cost (21k)
        // and the operations that occur after we assign a value to `estGasUsed`. Note that it's
        // crucial for this estimate to be greater than the actual gas used by this transaction so
        // that the executor doesn't lose money`.
        uint256 estGasUsed = 100_000 + calldataGasUsed + _initialGasLeft - gasleft();

        uint256 executorPayment = (gasPrice * estGasUsed * (100 + executorPaymentPercentage)) / 100;
        uint256 protocolPayment = (gasPrice * estGasUsed * (protocolPaymentPercentage)) / 100;

        // Add the executor's payment to the executor debt.
        totalExecutorDebt += executorPayment;
        executorDebt[msg.sender] += executorPayment;

        // Add the protocol's payment to the protocol debt.
        totalProtocolDebt += protocolPayment;
    }

    /**
     * @notice Deploys a contract using the CREATE2 opcode.
     *
     *         If the user is deploying a proxied contract, then we deploy the implementation
     *         contract first and later set the proxy's implementation address to the implementation
     *         contract's address.
     *
     *         Note that we wait to set the proxy's implementation address until
     *         the very last call of the deployment to avoid a situation where end-users are
               interacting
     *         with a proxy whose storage has not been fully initialized.
     *
     * @param _referenceName Reference name that corresponds to the contract.
     * @param _code          Creation bytecode of the contract.
     */
    function _deployContract(string memory _referenceName, bytes memory _code) internal {
        // Get the expected address of the contract.
        address expectedAddress = create2.computeAddress(
            bytes32(0),
            keccak256(_code),
            address(this)
        );

        // Check if the contract has already been deployed.
        if (expectedAddress.code.length > 0) {
            // Skip deploying the contract if it already exists. Execution would halt if we attempt
            // to deploy a contract that has already been deployed at the same address.
            emit ContractDeploymentSkipped(
                _referenceName,
                expectedAddress,
                activeDeploymentId,
                _referenceName
            );
            registry.announce("ContractDeploymentSkipped");
        } else {
            address actualAddress;
            assembly {
                actualAddress := create2(0x0, add(_code, 0x20), mload(_code), 0x0)
            }

            // Could happen if insufficient gas is supplied to this transaction or if the creation
            // bytecode has logic that causes the call to fail (e.g. a constructor that reverts). We
            // check that the latter situation cannot occur using off-chain logic. If there's
            // another situation that could cause an address mismatch, this would halt the entire
            // execution process.
            require(
                expectedAddress == actualAddress,
                "ChugSplashManager: contract incorrectly deployed"
            );

            emit ContractDeployed(
                _referenceName,
                actualAddress,
                activeDeploymentId,
                _referenceName
            );
            registry.announce("ContractDeployed");
        }
    }

    /**
     * @notice Modifies a storage slot within the proxy contract.
     *
     * @param _proxy   Address of the proxy.
     * @param _adapter Address of the adapter for this proxy.
     * @param _key     Storage key to modify.
     * @param _value   New value for the storage key.
     */
    function _setProxyStorage(
        address payable _proxy,
        address _adapter,
        bytes32 _key,
        uint8 _offset,
        bytes memory _value
    ) internal {
        // Delegatecall the adapter to call `setStorage` on the proxy. slither-disable-next-line
        // controlled-delegatecall
        (bool success, ) = _adapter.delegatecall(
            abi.encodeCall(IProxyAdapter.setStorage, (_proxy, _key, _offset, _value))
        );
        require(success, "ChugSplashManager: set storage failed");
    }

    function _assertCallerIsOwnerOrSelectedExecutor(bool _remoteExecution) internal view {
        _remoteExecution
            ? require(
                getSelectedExecutor(activeDeploymentId) == msg.sender,
                "ChugSplashManager: caller is not approved executor"
            )
            : require(owner() == msg.sender, "ChugSplashManager: caller is not owner");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { Proxy } from "@eth-optimism/contracts-bedrock/contracts/universal/Proxy.sol";
import { ChugSplashRegistry } from "./ChugSplashRegistry.sol";
import { IChugSplashManager } from "./interfaces/IChugSplashManager.sol";

/**
 * @title ChugSplashManagerProxy
 * @notice Designed to be upgradable only by the end user and to allow upgrades only to
 *         new manager versions that whitelisted by the ChugSplashRegistry.
 */
contract ChugSplashManagerProxy is Proxy {
    /**
     * @notice Address of the ChugSplashRegistry.
     */
    ChugSplashRegistry public immutable registry;

    modifier isNotExecuting() {
        address impl = _getImplementation();
        require(
            impl == address(0) || !IChugSplashManager(impl).isExecuting(),
            "ChugSplashManagerProxy: execution in progress"
        );
        _;
    }

    modifier isApprovedImplementation(address _implementation) {
        require(
            registry.managerImplementations(_implementation),
            "ChugSplashManagerProxy: unapproved manager"
        );
        _;
    }

    /**
     * @param _registry              The ChugSplashRegistry's address.
     * @param _admin                 Owner of this contract.
     */
    constructor(ChugSplashRegistry _registry, address _admin) payable Proxy(_admin) {
        registry = _registry;
    }

    /**
     * @inheritdoc Proxy
     */
    function upgradeTo(
        address _implementation
    ) public override proxyCallIfNotAdmin isNotExecuting isApprovedImplementation(_implementation) {
        super.upgradeTo(_implementation);
    }

    /**
     * @inheritdoc Proxy
     */
    function upgradeToAndCall(
        address _implementation,
        bytes calldata _data
    )
        public
        payable
        override
        proxyCallIfNotAdmin
        isNotExecuting
        isApprovedImplementation(_implementation)
        returns (bytes memory)
    {
        return super.upgradeToAndCall(_implementation, _data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { ChugSplashManagerProxy } from "./ChugSplashManagerProxy.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { IChugSplashManager } from "./interfaces/IChugSplashManager.sol";
import { Semver, Version } from "./Semver.sol";

/**
 * @title ChugSplashRegistry
 * @notice The ChugSplashRegistry is the root contract for the ChugSplash deployment system. This
 *         contract allows callers to register new projects. Also, every event emitted in the
 *         ChugSplash system is announced through this contract. This makes it easy for clients to
 *         find and index events that occur throughout the deployment process. Lastly, the owner of
 *         this contract is able to add support for new contract kinds (e.g. OpenZeppelin's
           Transparent proxy). The owner can also new versions of the ChugSplashManager
           implementation.
 *
 */
contract ChugSplashRegistry is Ownable, Initializable {
    /**
     * @notice Mapping of claimers to organization IDs to ChugSplashManagerProxy addresses.
     */
    mapping(address => mapping(bytes32 => address payable)) public projects;

    /**
     * @notice Mapping of ChugSplashManagerProxy addresses to a boolean indicating whether or not
     *         it was deployed by this contract.
     */
    mapping(address => bool) public managerProxies;

    /**
     * @notice Mapping of contract kind hashes to adapter contract addresses.
     */
    mapping(bytes32 => address) public adapters;

    /**
     * @notice Mapping of ChugSplashManager implementations to a boolean indicating whether or not
     *         it's a valid implementation.
     */
    mapping(address => bool) public managerImplementations;

    /**
     * @notice Mapping of (major, minor, patch) versions to ChugSplashManager implementation
     *         address.
     */
    mapping(uint => mapping(uint => mapping(uint => address))) public versions;

    /**
     * @notice Emitted whenever a new project is claimed.
     *
     * @param organizationID Organization ID that was claimed.
     * @param claimer        Address of the claimer of the project. This is equivalent to the
     *                       `msg.sender`.
     * @param managerImpl    Address of the initial ChugSplashManager implementation for this
     *                       project.
     * @param owner          Address of the initial owner of the project.
     * @param retdata        Return data from the ChugSplashManager initializer.
     */
    event ChugSplashProjectClaimed(
        bytes32 indexed organizationID,
        address indexed claimer,
        address indexed managerImpl,
        address owner,
        bytes retdata
    );

    /**
     * @notice Emitted whenever a ChugSplashManager contract announces an event on the registry. We
     *         use this to avoid needing a complex indexing system when we're trying to find events
     *         emitted by the various manager contracts.
     *
     * @param eventNameHash Hash of the name of the event being announced.
     * @param manager       Address of the ChugSplashManagerProxy announcing an event.
     * @param eventName     Name of the event being announced.
     */
    event EventAnnounced(string indexed eventNameHash, address indexed manager, string eventName);

    /**
     * @notice Emitted whenever a ChugSplashManager contract wishes to announce an event on the
     *         registry, including a field for arbitrary data. We use this to avoid needing a
     *         complex indexing system when we're trying to find events emitted by the various
     *         manager contracts.
     *
     * @param eventNameHash Hash of the name of the event being announced.
     * @param manager       Address of the ChugSplashManagerProxy announcing an event.
     * @param dataHash      Hash of the extra data sent by the ChugSplashManager.
     * @param eventName     Name of the event being announced.
     * @param data          The extra data.
     */
    event EventAnnouncedWithData(
        string indexed eventNameHash,
        address indexed manager,
        bytes indexed dataHash,
        string eventName,
        bytes data
    );

    /**
     * @notice Emitted whenever a new contract kind is added.
     *
     * @param contractKindHash Hash representing the contract kind.
     * @param adapter          Address of the adapter for the contract kind.
     */
    event ContractKindAdded(bytes32 contractKindHash, address adapter);

    /**
     * @notice Emitted whenever a new ChugSplashManager implementation is added.
     *
     * @param major  Major version of the ChugSplashManager.
     * @param minor     Minor version of the ChugSplashManager.
     * @param patch    Patch version of the ChugSplashManager.
     * @param manager Address of the ChugSplashManager implementation.
     */
    event VersionAdded(
        uint256 indexed major,
        uint256 indexed minor,
        uint256 indexed patch,
        address manager
    );

    /**
     * @param _owner Address of the owner of the registry.
     */
    constructor(address _owner) {
        _transferOwnership(_owner);
    }

    /**
     * @notice Claims a new project by deploying a new ChugSplashManagerProxy
     * contract and setting the provided owner as the initial owner of the new project. It also
       checks that the
     * organization ID being claimed has not already been claimed by the caller, and that the
       specified version
     * of the ChugSplashManager is a valid implementation.
     *
     * @param _organizationID Organization ID to claim.
     * @param _owner        Initial owner for the new project.
     * @param _version   Version of the ChugSplashManager implementation.
     * @param _data      Any data to pass to the ChugSplashManager initializer.
     */
    function claim(
        bytes32 _organizationID,
        address _owner,
        Version memory _version,
        bytes memory _data
    ) external {
        require(
            address(projects[msg.sender][_organizationID]) == address(0),
            "ChugSplashRegistry: org ID already claimed by caller"
        );

        address managerImpl = versions[_version.major][_version.minor][_version.patch];
        require(managerImplementations[managerImpl], "ChugSplashRegistry: invalid manager version");

        bytes32 salt = keccak256(abi.encode(msg.sender, _organizationID));

        ChugSplashManagerProxy managerProxy = new ChugSplashManagerProxy{ salt: salt }(
            this,
            address(this)
        );

        require(
            address(managerProxy) != address(0),
            "ChugSplashRegistry: failed to deploy manager proxy"
        );

        projects[msg.sender][_organizationID] = payable(address(managerProxy));
        managerProxies[address(managerProxy)] = true;

        bytes memory retdata = managerProxy.upgradeToAndCall(
            managerImpl,
            abi.encodeCall(IChugSplashManager.initialize, _data)
        );

        // Change manager proxy admin to the Org owner
        managerProxy.changeAdmin(_owner);

        emit ChugSplashProjectClaimed(_organizationID, msg.sender, managerImpl, _owner, retdata);
    }

    /**
     * @notice Allows ChugSplashManager contracts to announce events. Only callable by
       ChugSplashManagerProxy contracts.
     *
     * @param _event Name of the event to announce.
     */
    function announce(string memory _event) external {
        require(
            managerProxies[msg.sender],
            "ChugSplashRegistry: events can only be announced by managers"
        );

        emit EventAnnounced(_event, msg.sender, _event);
    }

    /**
     * @notice Allows ChugSplashManager contracts to announce events, including a field for
     *         arbitrary data.  Only callable by ChugSplashManagerProxy contracts.
     *
     * @param _event Name of the event to announce.
     * @param _data  Arbitrary data to include in the announced event.
     */
    function announceWithData(string memory _event, bytes memory _data) external {
        require(
            managerProxies[msg.sender],
            "ChugSplashRegistry: events can only be announced by managers"
        );

        emit EventAnnouncedWithData(_event, msg.sender, _data, _event, _data);
    }

    /**
     * @notice Adds a new contract kind with a corresponding adapter. Only callable by the owner of
       the ChugSplashRegistry.
     *
     * @param _contractKindHash Hash representing the contract kind.
     * @param _adapter   Address of the adapter for this contract kind.
     */
    function addContractKind(bytes32 _contractKindHash, address _adapter) external onlyOwner {
        require(
            adapters[_contractKindHash] == address(0),
            "ChugSplashRegistry: contract kind has an existing adapter"
        );

        adapters[_contractKindHash] = _adapter;

        emit ContractKindAdded(_contractKindHash, _adapter);
    }

    /**
     * @notice Adds a new version of the ChugSplashManager implementation. Only callable by the
       owner of the ChugSplashRegistry.
     *  The version is specified by the `Semver` contract
     *      attached to the implementation. Throws an error if the version
     *      has already been set.
     *
     * @param _manager Address of the ChugSplashManager implementation to add.
     */
    function addVersion(address _manager) external onlyOwner {
        Version memory version = Semver(_manager).version();
        uint256 major = version.major;
        uint256 minor = version.minor;
        uint256 patch = version.patch;

        require(
            versions[major][minor][patch] == address(0),
            "ChugSplashRegistry: version already set"
        );

        managerImplementations[_manager] = true;
        versions[major][minor][patch] = _manager;

        emit VersionAdded(major, minor, patch, _manager);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

struct Version {
    uint256 major;
    uint256 minor;
    uint256 patch;
}

/**
 * @title Semver
 * @notice Semver is a simple contract for managing contract versions.
 */
contract Semver {
    /**
     * @notice Contract version number (major).
     */
    uint256 private immutable MAJOR_VERSION;

    /**
     * @notice Contract version number (minor).
     */
    uint256 private immutable MINOR_VERSION;

    /**
     * @notice Contract version number (patch).
     */
    uint256 private immutable PATCH_VERSION;

    /**
     * @param _major Version number (major).
     * @param _minor Version number (minor).
     * @param _patch Version number (patch).
     */
    constructor(uint256 _major, uint256 _minor, uint256 _patch) {
        MAJOR_VERSION = _major;
        MINOR_VERSION = _minor;
        PATCH_VERSION = _patch;
    }

    /**
     * @notice Returns the full semver contract version.
     *
     * @return Semver contract version as a tuple.
     */
    function version() public view returns (Version memory) {
        return Version(MAJOR_VERSION, MINOR_VERSION, PATCH_VERSION);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { ChugSplashRegistry } from "../ChugSplashRegistry.sol";
import { Version } from "../Semver.sol";

/**
 * @title ChugSplashManager
 * @notice Interface that must be inherited the ChugSplash manager.
 */
interface IChugSplashManager {
    function initialize(bytes memory) external returns (bytes memory);

    function isExecuting() external view returns (bool);

    function registry() external view returns (ChugSplashRegistry);

    function organizationID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * @title ICreate2
 * @notice Interface for a Create2 contract. Normally, this functionality would in a library.
   Instead, we put it in a contract so that other contracts can use non-standard CREATE2 formulas in
   a modular way. If we opted for a library to implement this functionality, we would need separate
   copies of each contract that uses it, each with a different implementation of the CREATE2
   formula.
 */
interface ICreate2 {
    /**
     * @notice Computes the address of a contract using the CREATE2 opcode.
     *
     * @param _salt        Arbitrary salt.
     * @param _bytecodeHash Hash of the creation bytecode appended with ABI-encoded constructor
            arguments.
     * @param _deployer   Address of the deployer.

     * @return Address of the computed contract.
     */
    function computeAddress(
        bytes32 _salt,
        bytes32 _bytecodeHash,
        address _deployer
    ) external pure returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * @title IGasPriceCalculator
 */
interface IGasPriceCalculator {
    function getGasPrice() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * @title IProxyAdapter
 * @notice Interface that must be inherited by each adapter.
 */
interface IProxyAdapter {
    /**
     * @notice Update the proxy to be in a state where it can be upgraded by ChugSplash.
     *
     * @param _proxy Address of the proxy.
     */
    function initiateExecution(address payable _proxy) external;

    /**
     * @notice Upgrade the implementation of the proxy.
     *
     * @param _proxy          Address of the proxy.
     * @param _implementation Address of the final implementation.
     */
    function completeExecution(address payable _proxy, address _implementation) external;

    /**
     * @notice Replaces a segment of a proxy's storage slot value at a given key and offset. The
     *         storage value outside of this segment remains the same.
     *
     * @param _proxy   Address of the proxy to modify.
     * @param _key     Storage key to modify.
     * @param _offset  Bytes offset of the new segment from the right side of the storage slot.
     * @param _segment New value for the segment of the storage slot.
     */
    function setStorage(
        address payable _proxy,
        bytes32 _key,
        uint8 _offset,
        bytes memory _segment
    ) external;

    /**
     * @notice Changes the admin of the proxy.
     *
     * @param _proxy    Address of the proxy.
     * @param _newAdmin Address of the new admin.
     */
    function changeProxyAdmin(address payable _proxy, address _newAdmin) external;
}