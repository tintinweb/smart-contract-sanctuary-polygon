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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProofUpgradeable {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @title DgenClaim contract for DGEN token claim. The contract is based on the Merkle tree.
 *
 * @dev This contract includes the following functionality:
 * - Claim DGEN tokens.
 * - Update Merkle tree root.
 * - Update claim period.
 * - Update DGEN token address.
 * - Withdraw remaining DGEN tokens.
 * - Set additional claim value. Used when needed to add additional users or change values without changing the Merkle tree/root.
 * - Set isClaimed value. Aimed to be used to block users.
 */
contract DgenClaim is OwnableUpgradeable {
    // _______________ Storage _______________

    /// @dev Merkle tree root.
    bytes32 public root;

    /// @dev Claim start timestamp.
    uint256 public startTimestamp;

    /// @dev Claim end timestamp.
    uint256 public endTimestamp;

    /// @dev DGEN token address.
    IERC20Upgradeable public dgen;

    /// @dev Users who have already claimed their tokens.
    mapping(address => bool) public isClaimed;

    /// @dev Additional mapping with claim values. Used when needed to add additional users or change values without changing the Merkle tree/root.
    mapping(address => uint256) public additionalClaimAmounts;

    // _______________ Errors _______________

    /// @dev Revert is zero address is passed.
    error ZeroAddress();

    /// @dev Revert when the claim is not active.
    error ClaimNotActive(uint256 start, uint256 end, uint256 current);

    /// @dev Revert if claim is not over.
    error ClaimNotOver(uint256 end, uint256 current);

    /// @dev Revert if user has already claimed.
    error AlreadyClaimed(address user);

    /// @dev Revert when validation of the merkle proof fails.
    error ProofFailed(address user, uint256 amount, bytes32[] proof);

    /// @dev Revert when trying to rescue DGEN tokens.
    error DgenRescue(IERC20Upgradeable dgenToken);

    /// @dev Revert if arrays lengths are not equal.
    error ArraysLengthMismatch(uint256 length1, uint256 length2);

    // _______________ Events _______________

    /**
     * @dev Emitted when the claim is successful.
     *
     * @param _user   Address of the user.
     * @param _amount   Amount of the claim.
     */
    event Claim(address indexed _user, uint256 indexed _amount);

    /**
     * @dev Emitted when the root is updated.
     */
    event RootUpdated(bytes32 indexed _root);

    /**
     * @dev Emitted when the claim period is updated.
     */
    event ClaimPeriodUpdated(uint256 indexed _startTimestamp, uint256 indexed _endTimestamp);

    /**
     * @dev Emitted when the DGEN token address is updated.
     */
    event DgenUpdated(address indexed _dgen);

    /**
     * @dev Emitted when remaining tokens are withdrawn.
     */
    event RemainingDgenWithdrawal(address indexed _to, uint256 indexed _amount);

    /**
     * @dev Emitted when additional claim value is set.
     */
    event AdditionalClaimValueUpdated(address indexed _user, uint256 indexed _amount);

    /**
     * @dev Emitted when isClaimed value is set.
     */
    event IsClaimedUpdated(address indexed _user, bool indexed _isClaimed);

    /**
     * @dev Emitted when ERC20 tokens are rescued.
     */
    event ERC20Rescued(address indexed _token, address indexed _to, uint256 indexed _amount);

    // _______________ Modifiers _______________

    /**
     * @dev Zero address check.
     */
    modifier notZeroAddress(address _address) {
        if (_address == address(0)) {
            revert ZeroAddress();
        }
        _;
    }

    /**
     * @dev Check if the claim is active.
     */
    modifier whenClaimActive() {
        if (!isClaimActive()) {
            revert ClaimNotActive(startTimestamp, endTimestamp, block.timestamp);
        }
        _;
    }

    /**
     * @dev Check if action happens after the claim is over.
     */
    modifier whenClaimEnded() {
        if (endTimestamp > block.timestamp) {
            revert ClaimNotOver(endTimestamp, block.timestamp);
        }
        _;
    }

    // _______________ Initializer ______________

    /**
     * @dev Initialize the contract.
     *
     * @param _root Merkle tree root.
     */
    function initialize(
        bytes32 _root,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        IERC20Upgradeable _dgen
    ) public initializer notZeroAddress(address(_dgen)) {
        __Ownable_init();
        // TODO: make internal setters
        _setRoot(_root);
        _setStartTimestamp(_startTimestamp);
        _setEndTimestamp(_endTimestamp);
        _setDgen(_dgen);
    }

    // _______________ External functions _______________

    /**
     * @dev Claim DGEN tokens.
     * Requirements:
     * - Claim must be active. (startTimestamp <= block.timestamp <= endTimestamp)
     * - User must not have claimed yet. (isClaimed(msg.sender) == false)
     * - Contract must have enough DGEN tokens to transfer. (dgen.balanceOf(dgenClaimAddress) >= _amount)
     * - User must be in the claim list. We have two options, either:
     *      * User must pass the merkle proof OR
     *      * Additional claim value must be set (additionalClaimAmounts(msg.sender) > 0.
     *        If user has additional claim value set, we will use that value instead of the one passed in the function.
     *        Also proof will be ignored too in this case.
     * @param _amount Amount to claim. (ignored if additional claim value is set)
     * @param _proof Merkle proof. (ignored if additional claim value is set)
     */
    function claim(uint256 _amount, bytes32[] calldata _proof) external whenClaimActive {
        if (isClaimed[msg.sender]) {
            revert AlreadyClaimed(msg.sender);
        }
        if (additionalClaimAmounts[msg.sender] > 0) {
            _amount = additionalClaimAmounts[msg.sender];
        } else {
            if (!checkClaimProof(msg.sender, _amount, _proof)) {
                revert ProofFailed(msg.sender, _amount, _proof);
            }
        }
        _setIsClaimed(msg.sender, true);
        dgen.transfer(msg.sender, _amount);
        emit Claim(msg.sender, _amount);
    }

    // Getters

    /**
     * @dev Function to get all the information about the user and his claim.
     * This function is used by the frontend to get all the information in one request.
     * @param _user Address of the user.
     * @return isClaimed_ True if user has claimed.
     * @return additionalClaimAmount_ Additional claim amount.
     * @return startTimestamp_ Start timestamp of the claim.
     * @return endTimestamp_ End timestamp of the claim.
     * @return isClaimActive_ True if claim is active.
     * @return dgenTokenAddress_ Address of the DGEN token.
     * @return claimContractBalance_ Balance of the DGEN token in the contract.
     */
    function getUserClaimInfo(
        address _user
    )
        external
        view
        returns (
            bool isClaimed_,
            uint256 additionalClaimAmount_,
            uint256 startTimestamp_,
            uint256 endTimestamp_,
            bool isClaimActive_,
            address dgenTokenAddress_,
            uint256 claimContractBalance_
        )
    {
        isClaimed_ = isClaimed[_user];
        additionalClaimAmount_ = additionalClaimAmounts[_user];
        startTimestamp_ = startTimestamp;
        endTimestamp_ = endTimestamp;
        isClaimActive_ = isClaimActive();
        dgenTokenAddress_ = address(dgen);
        claimContractBalance_ = dgen.balanceOf(address(this));
    }

    // Admin functions

    /**
     * @dev Add additional claim value for the user. Can be used to add additional users or change values without changing the Merkle tree/root.
     * Requirements:
     * - User must not be zero address.
     * @param _user Address of the user.
     * @param _amount Amount to claim.
     */
    function setClaimAmount(address _user, uint256 _amount) external onlyOwner {
        _setClaimAmount(_user, _amount);
    }

    /**
     * @dev Add additional claim values for many users. Can be used to add additional users or change values without changing the Merkle tree/root.
     * Requirements:
     * - Users and amounts arrays must have the same length.
     * - Users array must not contain zero addresses.
     * @param _users Array of addresses of the users.
     * @param _amounts Array of amounts to claim.
     */
    function setClaimAmountForMany(address[] calldata _users, uint256[] calldata _amounts) external onlyOwner {
        if (_users.length != _amounts.length) {
            revert ArraysLengthMismatch(_users.length, _amounts.length);
        }
        for (uint256 i = 0; i < _users.length; i++) {
            _setClaimAmount(_users[i], _amounts[i]);
        }
    }

    /**
     * @dev Set if user is already claimed. Aimed to be used to blacklist users.
     * Requirements:
     * - User must not be zero address.
     * @param _user Address of the user.
     * @param _isClaimed True if user is banned from claiming.
     */
    function setIsClaimed(address _user, bool _isClaimed) external onlyOwner {
        _setIsClaimed(_user, _isClaimed);
    }

    /**
     * @dev Set if users are already claimed. Aimed to be used to blacklist users.
     * Requirements:
     * - Users and isClaimed arrays must have the same length.
     * - Users array must not contain zero addresses.
     * @param _users Array of addresses of the users.
     * @param _isClaimed Array of booleans if user is banned from claiming.
     */
    function setIsClaimedForMany(address[] calldata _users, bool[] calldata _isClaimed) external onlyOwner {
        if (_users.length != _isClaimed.length) {
            revert ArraysLengthMismatch(_users.length, _isClaimed.length);
        }
        for (uint256 i = 0; i < _users.length; i++) {
            _setIsClaimed(_users[i], _isClaimed[i]);
        }
    }

    /**
     * @dev Withdraw remaining DGEN tokens to specified address. Can be called only after the claim is over.
     *
     * @param _to Address to withdraw DGEN tokens to.
     */
    function withdrawDgen(address _to) external onlyOwner whenClaimEnded notZeroAddress(_to) {
        emit RemainingDgenWithdrawal(_to, dgen.balanceOf(address(this)));
        dgen.transfer(_to, dgen.balanceOf(address(this)));
    }

    /**
     * @dev Set the Merkle tree root.
     *
     * @param _root Merkle tree root.
     */
    function setRoot(bytes32 _root) external onlyOwner {
        _setRoot(_root);
    }

    /**
     * @dev Set the claim start timestamp.
     *
     * @param _startTimestamp Claim start timestamp.
     */
    function setStartTimestamp(uint256 _startTimestamp) external onlyOwner {
        _setStartTimestamp(_startTimestamp);
    }

    /**
     * @dev Set the claim end timestamp.
     *
     * @param _endTimestamp Claim end timestamp.
     */
    function setEndTimestamp(uint256 _endTimestamp) external onlyOwner {
        _setEndTimestamp(_endTimestamp);
    }

    /**
     * @dev Set the DGEN token address.
     * Requirements:
     * - DGEN token address must not be zero address.
     * @param _dgen DGEN token address.
     */
    function setDgen(IERC20Upgradeable _dgen) external onlyOwner {
        _setDgen(_dgen);
    }

    /**
     * @dev Rescue ERC20 tokens from the contract. Token must be not DGEN.
     * @param _token Address of the token to rescue.
     * @param _to Address to send tokens to.
     */
    function rescueERC20(
        IERC20Upgradeable _token,
        address _to
    ) external onlyOwner notZeroAddress(address(_token)) notZeroAddress(_to) {
        if (dgen == _token) {
            revert DgenRescue(dgen);
        }
        emit ERC20Rescued(address(_token), _to, _token.balanceOf(address(this)));
        _token.transfer(_to, _token.balanceOf(address(this)));
    }

    // _______________ Public functions _______________

    /**
     * @dev Returns true is claim is active.
     */
    function isClaimActive() public view returns (bool) {
        return startTimestamp < block.timestamp && block.timestamp < endTimestamp;
    }

    /**
     * @dev Returns true if user and amount are in the merkle tree (if provided proof is valid).
     *
     * @param _user Address of the user.
     * @param _amount Amount to claim.
     * @param _proof Merkle proof.
     * @return True if user and amount are in the merkle tree.
     */
    function checkClaimProof(address _user, uint256 _amount, bytes32[] memory _proof) public view returns (bool) {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_user, _amount))));
        return MerkleProofUpgradeable.verify(_proof, root, leaf);
    }

    // _______________ Internal functions _______________

    /**
     * @dev Add additional claim value for the user. Can be used to add additional users or change values without changing the Merkle tree/root.
     * Requirements:
     * - User must not be zero address.
     * @param _user Address of the user.
     * @param _amount Amount to claim.
     */
    function _setClaimAmount(address _user, uint256 _amount) internal notZeroAddress(_user) {
        additionalClaimAmounts[_user] = _amount;
        emit AdditionalClaimValueUpdated(_user, _amount);
    }

    /**
     * @dev Set if user is already claimed. Aimed to be used to blacklist users.
     * Requirements:
     * - User must not be zero address.
     * @param _user Address of the user.
     * @param _isClaimed True if user is banned from claiming.
     */
    function _setIsClaimed(address _user, bool _isClaimed) internal notZeroAddress(_user) {
        isClaimed[_user] = _isClaimed;
        emit IsClaimedUpdated(_user, _isClaimed);
    }

    /**
     * @dev Set the Merkle tree root.
     *
     * @param _root Merkle tree root.
     */
    function _setRoot(bytes32 _root) internal {
        root = _root;
        emit RootUpdated(_root);
    }

    /**
     * @dev Set the claim start timestamp.
     *
     * @param _startTimestamp Claim start timestamp.
     */
    function _setStartTimestamp(uint256 _startTimestamp) internal {
        startTimestamp = _startTimestamp;
        emit ClaimPeriodUpdated(_startTimestamp, endTimestamp);
    }

    /**
     * @dev Set the claim end timestamp.
     *
     * @param _endTimestamp Claim end timestamp.
     */
    function _setEndTimestamp(uint256 _endTimestamp) internal {
        endTimestamp = _endTimestamp;
        emit ClaimPeriodUpdated(startTimestamp, _endTimestamp);
    }

    /**
     * @dev Set the DGEN token address.
     * Requirements:
     * - DGEN token address must not be zero address.
     * @param _dgen DGEN token address.
     */
    function _setDgen(IERC20Upgradeable _dgen) internal notZeroAddress(address(_dgen)) {
        dgen = _dgen;
        emit DgenUpdated(address(_dgen));
    }
}