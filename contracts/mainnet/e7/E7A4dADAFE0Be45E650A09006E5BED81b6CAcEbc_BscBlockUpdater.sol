// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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

pragma solidity ^0.8.14;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./BscVerifier.sol";
import "./BscLubanVerifier.sol";
import "../interface/IBlockUpdater.sol";

contract BscBlockUpdater is IBlockUpdater, BscVerifier, Initializable, OwnableUpgradeable, BscLubanVerifier {
    event ImportValidator(uint256 indexed epoch, uint256 indexed blockNumber, bytes32 blockHash, bytes32 receiptHash);
    event ModBlockConfirmation(uint256 oldBlockConfirmation, uint256 newBlockConfirmation);

    struct ParsedInput {
        uint256 blockNumber;
        uint256 epochValidatorCount;
        uint256 blockConfirmation;
        bytes32 blockHash;
        bytes32 receiptHash;
        bytes32 signingValidatorSetHash;
        bytes32 epochValidatorSetHash;
    }

    struct ZkProof {
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
        uint256[11] inputs;
    }

    uint256 public currentEpoch;

    uint256 public minBlockConfirmation;

    uint256 public  regularValidatorCount;

    // epoch=>validatorHash
    mapping(uint256 => bytes32) public validatorHashes;

    // epoch=>validatorCount
    mapping(uint256 => uint256) private validatorCounts;

    // blockHash=>receiptsRoot =>BlockConfirmation
    mapping(bytes32 => mapping(bytes32 => uint256)) public blockInfos;

    IBlockUpdater public oldBlockUpdater;

    uint256 public  lubanBlockNumber;

    function initialize(
        uint256 _epoch,
        uint256 _validatorCount,
        uint256 _preValidatorCount,
        bytes32 _epochValidatorSetHash,
        bytes32 _preEpochValidatorSetHash,
        bytes32 _blockHash,
        bytes32 _receiptHash,
        uint256 _minBlockConfirmation,
        uint256 _regularValidatorCount) public initializer {
        __Ownable_init();
        currentEpoch = _epoch;
        validatorHashes[_epoch] = _epochValidatorSetHash;
        validatorHashes[_epoch - 1] = _preEpochValidatorSetHash;
        validatorCounts[_epoch] = _validatorCount;
        _setValidatorCount(_epoch, _validatorCount);
        _setValidatorCount(_epoch - 1, _preValidatorCount);
        blockInfos[_blockHash][_receiptHash] = _minBlockConfirmation;
        minBlockConfirmation = _minBlockConfirmation;
        regularValidatorCount = _regularValidatorCount;
    }

    function importNextValidatorSet(bytes calldata _proof) external {
        _importNextValidatorSet(_proof);
    }

    function BatchImportNextValidatorSet(bytes[] calldata _proof) external {
        for (uint256 i = 0; i < _proof.length; i++) {
            _importNextValidatorSet(_proof[i]);
        }
    }

    function importBlock(bytes calldata _proof) external {
        _importBlock(_proof);
    }

    function BatchImportBlock(bytes[] calldata _proof) external {
        for (uint256 i = 0; i < _proof.length; i++) {
            _importBlock(_proof[i]);
        }
    }

    function checkBlock(bytes32 _blockHash, bytes32 _receiptHash) external view returns (bool) {
        (bool exist,) = _checkBlock(_blockHash, _receiptHash);
        if (!exist && address(oldBlockUpdater) != address(0)) {
            exist = oldBlockUpdater.checkBlock(_blockHash, _receiptHash);
        }
        return exist;
    }

    function checkBlockConfirmation(bytes32 _blockHash, bytes32 _receiptHash) external view returns (bool, uint256) {
        (bool exist,uint256 blockConfirmation) = _checkBlock(_blockHash, _receiptHash);
        if (!exist && address(oldBlockUpdater) != address(0)) {
            exist = oldBlockUpdater.checkBlock(_blockHash, _receiptHash);
            blockConfirmation = minBlockConfirmation;
        }
        return (exist, blockConfirmation);
    }

    function _checkBlock(bytes32 _blockHash, bytes32 _receiptHash) internal view returns (bool, uint256) {
        uint256 blockConfirmation = blockInfos[_blockHash][_receiptHash];
        if (blockConfirmation > 0) {
            return (true, blockConfirmation);
        }
        return (false, blockConfirmation);
    }

    function _setValidatorCount(uint256 _epoch, uint256 _validatorCount) internal {
        if (_validatorCount != regularValidatorCount) {
            validatorCounts[_epoch] = _validatorCount;
        }
    }

    function getValidatorCount(uint256 _epoch) public view returns (uint256) {
        if (validatorCounts[_epoch] != 0) {
            return validatorCounts[_epoch];
        }
        return regularValidatorCount;
    }

    function _importNextValidatorSet(bytes memory _proof) internal {
        ZkProof memory proofData;
        (proofData.a, proofData.b, proofData.c, proofData.inputs) = abi.decode(_proof, (uint256[2], uint256[2][2], uint256[2], uint256[11]));
        ParsedInput memory parsedInput = _parseInput(proofData.inputs);
        uint256 epoch = _computeEpoch(parsedInput.blockNumber);
        uint256 preEpoch = epoch - 1;
        require(parsedInput.epochValidatorSetHash != bytes32(0), "invalid epochValidatorSetHash");
        require(parsedInput.signingValidatorSetHash != bytes32(0), "invalid signingValidatorSetHash");
        require(parsedInput.blockConfirmation >= minBlockConfirmation, "Not enough block confirmations");
        require(validatorHashes[epoch] == bytes32(0), "epoch already exist");
        if (parsedInput.blockNumber % 200 <= getValidatorCount(preEpoch) / 2) {
            require(parsedInput.signingValidatorSetHash == validatorHashes[preEpoch], "invalid preEpochValidatorSetHash");
        } else {
            require(parsedInput.signingValidatorSetHash == parsedInput.epochValidatorSetHash, "invalid epochValidatorSetHash");
        }
        uint256[1] memory compressInput;
        compressInput[0] = _hashInput(proofData.inputs);
        if (lubanBlockNumber != 0 && block.number >= lubanBlockNumber) {
            require(verifyLubanProof(proofData.a, proofData.b, proofData.c, compressInput), "invalid proof");
        } else {
            require(verifyProof(proofData.a, proofData.b, proofData.c, compressInput), "invalid proof");
        }
        validatorHashes[epoch] = parsedInput.epochValidatorSetHash;
        _setValidatorCount(epoch, parsedInput.epochValidatorCount);
        currentEpoch = epoch;
        blockInfos[parsedInput.blockHash][parsedInput.receiptHash] = parsedInput.blockConfirmation;
        emit ImportValidator(epoch, parsedInput.blockNumber, parsedInput.blockHash, parsedInput.receiptHash);
    }

    function _importBlock(bytes memory _proof) internal {
        ZkProof memory proofData;
        (proofData.a, proofData.b, proofData.c, proofData.inputs) = abi.decode(_proof, (uint256[2], uint256[2][2], uint256[2], uint256[11]));
        ParsedInput memory parsedInput = _parseInput(proofData.inputs);

        require(parsedInput.blockConfirmation >= minBlockConfirmation, "Not enough block confirmations");
        (bool exist,uint256 blockConfirmation) = _checkBlock(parsedInput.blockHash, parsedInput.receiptHash);
        if (exist && parsedInput.blockConfirmation <= blockConfirmation) {
            revert("already exist");
        }
        uint256 epoch = _computeEpoch(parsedInput.blockNumber);
        uint256 preEpoch = epoch - 1;
        require(validatorHashes[epoch] != bytes32(0), "epoch no upload");

        if (parsedInput.blockNumber % 200 <= getValidatorCount(preEpoch) / 2) {
            require(parsedInput.signingValidatorSetHash == validatorHashes[preEpoch], "invalid preEpochValidatorSetHash");
        } else {
            require(parsedInput.signingValidatorSetHash == validatorHashes[epoch], "invalid epochValidatorSetHash");
        }

        uint256[1] memory compressInput;
        compressInput[0] = _hashInput(proofData.inputs);
        if (lubanBlockNumber != 0 && block.number >= lubanBlockNumber) {
            require(verifyLubanProof(proofData.a, proofData.b, proofData.c, compressInput), "invalid proof");
        } else {
            require(verifyProof(proofData.a, proofData.b, proofData.c, compressInput), "invalid proof");
        }
        blockInfos[parsedInput.blockHash][parsedInput.receiptHash] = parsedInput.blockConfirmation;
        emit ImportBlock(parsedInput.blockNumber, parsedInput.blockHash, parsedInput.receiptHash);
    }

    function _parseInput(uint256[11] memory _inputs) internal pure returns (ParsedInput memory)    {
        ParsedInput memory result;
        result.blockNumber = _inputs[0];
        result.blockHash = bytes32((_inputs[2] << 128) | _inputs[1]);
        result.receiptHash = bytes32((_inputs[4] << 128) | _inputs[3]);
        result.signingValidatorSetHash = bytes32((_inputs[6] << 128) | _inputs[5]);
        result.epochValidatorSetHash = bytes32((_inputs[8] << 128) | _inputs[7]);
        result.epochValidatorCount = _inputs[9];
        result.blockConfirmation = _inputs[10];
        return result;
    }

    function _hashInput(uint256[11] memory _inputs) internal pure returns (uint256) {
        uint256 computedHash = uint256(keccak256(abi.encodePacked(_inputs[0], _inputs[1], _inputs[2],
            _inputs[3], _inputs[4], _inputs[5], _inputs[6], _inputs[7], _inputs[8], _inputs[9], _inputs[10])));
        return computedHash / 256;
    }

    function _computeEpoch(uint256 blockNumber) internal pure returns (uint256) {
        return blockNumber / 200;
    }

    //----------------------------------------------------------------------------------
    // onlyOwner
    function setBlockConfirmation(uint256 _minBlockConfirmation) external onlyOwner {
        emit ModBlockConfirmation(minBlockConfirmation, _minBlockConfirmation);
        minBlockConfirmation = _minBlockConfirmation;
    }

    function setOldBlockUpdater(address _oldBlockUpdater) external onlyOwner {
        oldBlockUpdater = IBlockUpdater(_oldBlockUpdater);
    }

    function setLubanBlockNumber(uint256 _lubanBlockNumber) external onlyOwner {
        lubanBlockNumber = _lubanBlockNumber;
    }

}

// SPDX-License-Identifier: AML
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

// 2019 OKIMS

pragma solidity ^0.8.0;

library PairingLuban {

    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct G1Point {
        uint256 X;
        uint256 Y;
    }

    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint256[2] X;
        uint256[2] Y;
    }

    /*
     * @return The negation of p, i.e. p.plus(p.negate()) should be zero.
     */
    function negate(G1Point memory p) internal pure returns (G1Point memory) {

        // The prime q in the base field F_q for G1
        if (p.X == 0 && p.Y == 0) {
            return G1Point(0, 0);
        } else {
            return G1Point(p.X, PRIME_Q - (p.Y % PRIME_Q));
        }
    }

    /*
     * @return The sum of two points of G1
     */
    function plus(
        G1Point memory p1,
        G1Point memory p2
    ) internal view returns (G1Point memory r) {

        uint256[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
        // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success,"PairingLuban-add-failed");
    }

    /*
     * @return The product of a point on G1 and a scalar, i.e.
     *         p == p.scalar_mul(1) and p.plus(p) == p.scalar_mul(2) for all
     *         points p.
     */
    function scalar_mul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {

        uint256[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
        // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"PairingLuban-mul-failed");
    }

    /* @return The result of computing the PairingLuban check
     *         e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
     *         For example,
     *         PairingLuban([P1(), P1().negate()], [P2(), P2()]) should return true.
     */
    function pairing(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2,
        G1Point memory d1,
        G2Point memory d2
    ) internal view returns (bool) {

        G1Point[4] memory p1 = [a1, b1, c1, d1];
        G2Point[4] memory p2 = [a2, b2, c2, d2];
        uint256 inputSize = 24;
        uint256[] memory input = new uint256[](inputSize);

        for (uint256 i = 0; i < 4; i++) {
            uint256 j = i * 6;
            input[j + 0] = p1[i].X;
            input[j + 1] = p1[i].Y;
            input[j + 2] = p2[i].X[0];
            input[j + 3] = p2[i].X[1];
            input[j + 4] = p2[i].Y[0];
            input[j + 5] = p2[i].Y[1];
        }

        uint256[1] memory out;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
        // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success,"PairingLuban-opcode-failed");

        return out[0] != 0;
    }
}

contract BscLubanVerifier {

    using PairingLuban for *;

    uint256 constant SNARK_SCALAR_FIELD_LUBAN = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant PRIME_Q_LUBAN = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct VerifyingKeyLuban {
        PairingLuban.G1Point alfa1;
        PairingLuban.G2Point beta2;
        PairingLuban.G2Point gamma2;
        PairingLuban.G2Point delta2;
        PairingLuban.G1Point[2] IC;
    }

    struct ProofLuban {
        PairingLuban.G1Point A;
        PairingLuban.G2Point B;
        PairingLuban.G1Point C;
    }

    function verifyingKeyLuban() internal pure returns (VerifyingKeyLuban memory vk) {
        vk.alfa1 = PairingLuban.G1Point(uint256(17685106213625577742663369943236934971038649073253824992827638686029587615874), uint256(8858866647892753184148496235000516382899497285136046826950513216843092563321));
        vk.beta2 = PairingLuban.G2Point([uint256(16740498536473939219816968164452554391451440598388889201860666380115238077237), uint256(7616491348526044966641476133488373679136253171927978602069008517977005639743)], [uint256(17308182621579232221114932382743344512379666091316330540508421284193966453377), uint256(10885778611932397053258351718171024608063915677013300361864811144627082876966)]);
        vk.gamma2 = PairingLuban.G2Point([uint256(580596402957681467900540214169271809322852151890561000428498369602586344265), uint256(21513392033120806478171728627134982274420466006092249323140033982613057071777)], [uint256(7328349204615740314032531514519231275831301107039480013908732215300143253964), uint256(14029404061453593795958248491830829322403911408035540361310434226854347648771)]);
        vk.delta2 = PairingLuban.G2Point([uint256(4949433996774079530373154374616299595714814969285486129858714203618848426319), uint256(13070616175813843205942044253048103797334517665153540457320946095505365953530)], [uint256(20229556974603034117098049776467358535927435613239603234187797194868292364996), uint256(13296032033842993941749389707276276808545336339681839116052942243323904766536)]);
        vk.IC[0] = PairingLuban.G1Point(uint256(21425754293664827890213665797188265332281814586044668617625971839993979667074), uint256(11538253125688615282190085997316711465023270255085217986071182837939267661129));
        vk.IC[1] = PairingLuban.G1Point(uint256(4709983372464247780589338646604853333260871820147977473683414869692778711322), uint256(462265395021126141353364012292076850166922340161367346517048630541265262199));
    }

    /*
     * @returns Whether the proof is valid given the hardcoded verifying key
     *          above and the public inputs
     */
    function verifyLubanProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[1] memory input
    ) public view returns (bool r) {

        ProofLuban memory proof;
        proof.A = PairingLuban.G1Point(a[0], a[1]);
        proof.B = PairingLuban.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = PairingLuban.G1Point(c[0], c[1]);

        VerifyingKeyLuban memory vk = verifyingKeyLuban();

        // Compute the linear combination vk_x
        PairingLuban.G1Point memory vk_x = PairingLuban.G1Point(0, 0);

        // Make sure that proof.A, B, and C are each less than the prime q
        require(proof.A.X < PRIME_Q_LUBAN, "verifier-aX-gte-prime-q");
        require(proof.A.Y < PRIME_Q_LUBAN, "verifier-aY-gte-prime-q");

        require(proof.B.X[0] < PRIME_Q_LUBAN, "verifier-bX0-gte-prime-q");
        require(proof.B.Y[0] < PRIME_Q_LUBAN, "verifier-bY0-gte-prime-q");

        require(proof.B.X[1] < PRIME_Q_LUBAN, "verifier-bX1-gte-prime-q");
        require(proof.B.Y[1] < PRIME_Q_LUBAN, "verifier-bY1-gte-prime-q");

        require(proof.C.X < PRIME_Q_LUBAN, "verifier-cX-gte-prime-q");
        require(proof.C.Y < PRIME_Q_LUBAN, "verifier-cY-gte-prime-q");

        // Make sure that every input is less than the snark scalar field
        for (uint256 i = 0; i < input.length; i++) {
            require(input[i] < SNARK_SCALAR_FIELD_LUBAN,"verifier-gte-snark-scalar-field");
            vk_x = PairingLuban.plus(vk_x, PairingLuban.scalar_mul(vk.IC[i + 1], input[i]));
        }

        vk_x = PairingLuban.plus(vk_x, vk.IC[0]);

        return PairingLuban.pairing(
            PairingLuban.negate(proof.A),
            proof.B,
            vk.alfa1,
            vk.beta2,
            vk_x,
            vk.gamma2,
            proof.C,
            vk.delta2
        );
    }
}

// SPDX-License-Identifier: AML
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

// 2019 OKIMS

pragma solidity ^0.8.0;

library Pairing {

    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct G1Point {
        uint256 X;
        uint256 Y;
    }

    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint256[2] X;
        uint256[2] Y;
    }

    /*
     * @return The negation of p, i.e. p.plus(p.negate()) should be zero.
     */
    function negate(G1Point memory p) internal pure returns (G1Point memory) {

        // The prime q in the base field F_q for G1
        if (p.X == 0 && p.Y == 0) {
            return G1Point(0, 0);
        } else {
            return G1Point(p.X, PRIME_Q - (p.Y % PRIME_Q));
        }
    }

    /*
     * @return The sum of two points of G1
     */
    function plus(
        G1Point memory p1,
        G1Point memory p2
    ) internal view returns (G1Point memory r) {

        uint256[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
        // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success,"pairing-add-failed");
    }

    /*
     * @return The product of a point on G1 and a scalar, i.e.
     *         p == p.scalar_mul(1) and p.plus(p) == p.scalar_mul(2) for all
     *         points p.
     */
    function scalar_mul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {

        uint256[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
        // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"pairing-mul-failed");
    }

    /* @return The result of computing the pairing check
     *         e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
     *         For example,
     *         pairing([P1(), P1().negate()], [P2(), P2()]) should return true.
     */
    function pairing(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2,
        G1Point memory d1,
        G2Point memory d2
    ) internal view returns (bool) {

        G1Point[4] memory p1 = [a1, b1, c1, d1];
        G2Point[4] memory p2 = [a2, b2, c2, d2];
        uint256 inputSize = 24;
        uint256[] memory input = new uint256[](inputSize);

        for (uint256 i = 0; i < 4; i++) {
            uint256 j = i * 6;
            input[j + 0] = p1[i].X;
            input[j + 1] = p1[i].Y;
            input[j + 2] = p2[i].X[0];
            input[j + 3] = p2[i].X[1];
            input[j + 4] = p2[i].Y[0];
            input[j + 5] = p2[i].Y[1];
        }

        uint256[1] memory out;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
        // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success,"pairing-opcode-failed");

        return out[0] != 0;
    }
}

contract BscVerifier {

    using Pairing for *;

    uint256 constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[2] IC;
    }

    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }

    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(uint256(15386280964909293549543580114300687380387134322486892793005010018775909349522), uint256(5224627123709432703899278589870654908109616596901308298070912486748008390684));
        vk.beta2 = Pairing.G2Point([uint256(20197092222513397334967695987893349464262123242703778831499974229879677949340), uint256(9535630844984453248229438347778321174122276214990396865791206459646309912698)], [uint256(2222710970859525163301820647075141384588896570230424713501308882210358317614), uint256(3442110103579425700543700638317311502652246077342222901209550699286678420073)]);
        vk.gamma2 = Pairing.G2Point([uint256(6371433908097100257198716724654991635024703915523196289242238068279759541873), uint256(6744866678139215885036237564688979346365880632502466734213049444387808035799)], [uint256(8724792965072698548979483477917856500578128017781249920514951913789276567908), uint256(5887622452851979925017497334375233359170704243537272980589333929764787855505)]);
        vk.delta2 = Pairing.G2Point([uint256(13716209222931846996265200607502342862360236329306209551742708001102668058637), uint256(21126722617470047576758416841293214558031294314325749749118882846468303409234)], [uint256(5748560724378029066856860360297183950861011555485264817423859750519495735147), uint256(5218097891213868351451641840596370746322498964076638476955961190696845142096)]);
        vk.IC[0] = Pairing.G1Point(uint256(15937582811916819834341534665097878102209122534384239238532054152632073584450), uint256(456518938111387689117971671211007397671159466619451871128892238270653320853));
        vk.IC[1] = Pairing.G1Point(uint256(9799889853371565013179868234211600548434432305460435244291810560530639114466), uint256(5623956361073954996523754276859436475155172569053202848417393353733457526411));
    }

    /*
     * @returns Whether the proof is valid given the hardcoded verifying key
     *          above and the public inputs
     */
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[1] memory input
    ) public view returns (bool r) {

        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);

        VerifyingKey memory vk = verifyingKey();

        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);

        // Make sure that proof.A, B, and C are each less than the prime q
        require(proof.A.X < PRIME_Q, "verifier-aX-gte-prime-q");
        require(proof.A.Y < PRIME_Q, "verifier-aY-gte-prime-q");

        require(proof.B.X[0] < PRIME_Q, "verifier-bX0-gte-prime-q");
        require(proof.B.Y[0] < PRIME_Q, "verifier-bY0-gte-prime-q");

        require(proof.B.X[1] < PRIME_Q, "verifier-bX1-gte-prime-q");
        require(proof.B.Y[1] < PRIME_Q, "verifier-bY1-gte-prime-q");

        require(proof.C.X < PRIME_Q, "verifier-cX-gte-prime-q");
        require(proof.C.Y < PRIME_Q, "verifier-cY-gte-prime-q");

        // Make sure that every input is less than the snark scalar field
        for (uint256 i = 0; i < input.length; i++) {
            require(input[i] < SNARK_SCALAR_FIELD,"verifier-gte-snark-scalar-field");
            vk_x = Pairing.plus(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }

        vk_x = Pairing.plus(vk_x, vk.IC[0]);

        return Pairing.pairing(
            Pairing.negate(proof.A),
            proof.B,
            vk.alfa1,
            vk.beta2,
            vk_x,
            vk.gamma2,
            proof.C,
            vk.delta2
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBlockUpdater {
    event ImportBlock(uint256 identifier, bytes32 blockHash, bytes32 receiptHash);

    function importBlock(bytes calldata _proof) external;

    function checkBlock(bytes32 _blockHash, bytes32 _receiptsRoot) external view returns (bool);

    function checkBlockConfirmation(bytes32 _blockHash, bytes32 _receiptsRoot) external view returns (bool, uint256);
}