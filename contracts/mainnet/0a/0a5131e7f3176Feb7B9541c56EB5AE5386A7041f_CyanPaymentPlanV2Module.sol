// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../CoreStorage.sol";
import "../Utils.sol";

interface ICyanPaymentPlanV2 {
    function pay(uint256, bool) external payable;

    function getCurrencyAddressByPlanId(uint256) external view returns (address);
}

/// @title Cyan Wallet's Cyan Payment Plan Module - A Cyan wallet's Cyan Payment Plan handling module.
/// @author Bulgantamir Gankhuyag - <[email protected]>
/// @author Naranbayar Uuganbayar - <[email protected]>
contract CyanPaymentPlanV2Module is CoreStorage, IModule {
    /// @inheritdoc IModule
    function handleTransaction(
        address to,
        uint256 value,
        bytes calldata data
    ) external payable override returns (bytes memory) {
        return Utils._execute(to, value, data);
    }

    function autoPay(uint256 planId, uint256 payAmount) external payable {
        ICyanPaymentPlanV2 paymentPlanContract = ICyanPaymentPlanV2(msg.sender);
        address currencyAddress = paymentPlanContract.getCurrencyAddressByPlanId(planId);
        if (currencyAddress == address(0x0)) {
            require(address(this).balance >= payAmount, "Not enough ETH in the wallet.");
            paymentPlanContract.pay{value: payAmount}(planId, false);
        } else {
            require(IERC20(currencyAddress).balanceOf(address(this)) >= payAmount, "Not enough balance in the wallet.");
            IERC20(currencyAddress).approve(msg.sender, payAmount);
            paymentPlanContract.pay(planId, false);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library Utils {
    /// @notice Executes a transaction to the given address.
    /// @param to Target address.
    /// @param value Native token value to be sent to the address.
    /// @param data Data to be sent to the address.
    /// @return Result of the transaciton.
    function _execute(
        address to,
        uint256 value,
        bytes memory data
    ) internal returns (bytes memory) {
        assembly {
            let success := call(gas(), to, value, add(data, 0x20), mload(data), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }

    /// @notice Recover signer address from signature.
    /// @param signedHash Arbitrary length data signed on the behalf of the wallet.
    /// @param signature Signature byte array associated with signedHash.
    /// @return Recovered signer address.
    function recoverSigner(bytes32 signedHash, bytes memory signature) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        // we jump 32 (0x20) as the first slot of bytes contains the length
        // we jump 65 (0x41) per signature
        // for v we load 32 bytes ending with v (the first 31 come from s) then apply a mask
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
        require(v == 27 || v == 28, "Bad v value in signature.");

        address recoveredAddress = ecrecover(signedHash, v, r, s);
        require(recoveredAddress != address(0), "ecrecover returned 0.");
        return recoveredAddress;
    }

    /// @notice Helper method to parse the function selector from data.
    /// @param data Any data to be parsed, mostly calldata of transaction.
    /// @return result Parsed function sighash.
    function parseFunctionSelector(bytes memory data) internal pure returns (bytes4 result) {
        require(data.length >= 4, "Invalid data.");
        assembly {
            result := mload(add(data, 0x20))
        }
    }

    /// @notice Parse uint256 from given data.
    /// @param data Any data to be parsed, mostly calldata of transaction.
    /// @param position Position in the data.
    /// @return result Uint256 parsed from given data.
    function getUint256At(bytes memory data, uint8 position) internal pure returns (uint256 result) {
        assembly {
            result := mload(add(data, add(position, 0x20)))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/StorageSlot.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./managers/DelegateCallManager.sol";
import "./managers/RoleManager.sol";
import "./managers/ModuleManager.sol";

/// @title Cyan Wallet Core Storage - A Cyan wallet's core storage.
/// @dev This contract must be the very first parent of the Module contracts.
/// @author Bulgantamir Gankhuyag - <[email protected]>
/// @author Naranbayar Uuganbayar - <[email protected]>
abstract contract CoreStorage is RoleManagerStorage, ModuleManagerStorage {

}

/// @title Cyan Wallet Core Storage - A Cyan wallet's core storage features.
/// @dev This contract must be the very first parent of the Core contract and Module contracts.
/// @author Bulgantamir Gankhuyag - <[email protected]>
/// @author Naranbayar Uuganbayar - <[email protected]>
abstract contract ICoreStorage is DelegateCallManager, IRoleManager, IModuleManager {
    constructor(address admin) IRoleManager(admin) {
        require(admin != address(0x0), "Invalid admin address.");
    }

    /// @inheritdoc IModuleManager
    function setModule(
        address target,
        bytes4 funcHash,
        address module
    ) external override noDelegateCall onlyAdmin {
        _modules[target][funcHash] = module;
        emit SetModule(target, funcHash, module);
    }

    /// @inheritdoc IModuleManager
    function setInternalModule(bytes4 funcHash, address module) external override noDelegateCall onlyAdmin {
        _internalModules[funcHash] = module;
        emit SetInternalModule(funcHash, module);
    }

    /// @inheritdoc IRoleManager
    function getOwner() external view override onlyDelegateCall returns (address) {
        return _owner;
    }

    /// @inheritdoc IRoleManager
    function setAdmin(address admin) external override noDelegateCall onlyAdmin {
        require(admin != address(0x0), "Invalid admin address.");
        _admin = admin;
        emit SetAdmin(admin);
    }

    /// @inheritdoc IRoleManager
    function getAdmin() external view override noDelegateCall returns (address) {
        return _admin;
    }

    /// @inheritdoc IRoleManager
    function setOperator(uint8 index, address operator) external override noDelegateCall onlyAdmin {
        require(index < 3, "Invalid operator index.");
        require(operator != address(0x0), "Invalid operator address.");
        _operators[index] = operator;
        emit SetOperator(index, operator);
    }

    /// @inheritdoc IRoleManager
    function getOperators() external view override noDelegateCall returns (address[3] memory) {
        return _operators;
    }

    /// @inheritdoc IRoleManager
    function _checkOnlyAdmin() internal view override {
        if (address(this) != _this) {
            require(ICoreStorage(_this).getAdmin() == msg.sender, "Caller is not an admin.");
        } else {
            require(_admin == msg.sender, "Caller is not an admin.");
        }
    }

    /// @inheritdoc IRoleManager
    function isOperator(address operator) external view override noDelegateCall returns (bool result) {
        assembly {
            result := or(
                or(eq(sload(_operators.slot), operator), eq(sload(add(_operators.slot, 0x1)), operator)),
                eq(sload(add(_operators.slot, 0x2)), operator)
            )
        }
    }

    /// @inheritdoc IRoleManager
    function _checkOnlyOperator() internal view override {
        require(ICoreStorage(_this).isOperator(msg.sender), "Caller is not an operator.");
    }

    /// @inheritdoc IRoleManager
    function _checkOnlyOwner() internal view override {
        require(_owner == msg.sender, "Caller is not an owner.");
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
pragma solidity 0.8.19;

/// @title Manage the delegatecall to a contract
/// @notice Base contract that provides a modifier for managing delegatecall to methods in a child contract
abstract contract DelegateCallManager {
    /// @dev The address of this contract
    address payable internal immutable _this;

    constructor() {
        // Immutables are computed in the init code of the contract, and then inlined into the deployed bytecode.
        // In other words, this variable won't change when it's checked at runtime.
        _this = payable(address(this));
    }

    /// @dev Private method is used instead of inlining into modifier because modifiers are copied into each method,
    ///     and the use of immutable means the address bytes are copied in every place the modifier is used.
    function _checkNotDelegateCall() private view {
        require(address(this) == _this, "Only direct calls allowed.");
    }

    /// @dev Private method is used instead of inlining into modifier because modifiers are copied into each method,
    ///     and the use of immutable means the address bytes are copied in every place the modifier is used.
    function _checkOnlyDelegateCall() private view {
        require(address(this) != _this, "Cannot be called directly.");
    }

    /// @notice Prevents delegatecall into the modified method
    modifier noDelegateCall() {
        _checkNotDelegateCall();
        _;
    }

    /// @notice Prevents non delegatecall into the modified method
    modifier onlyDelegateCall() {
        _checkOnlyDelegateCall();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title Cyan Wallet Role Manager - A Cyan wallet's role manager's storage.
/// @author Bulgantamir Gankhuyag - <[email protected]>
/// @author Naranbayar Uuganbayar - <[email protected]>
abstract contract RoleManagerStorage {
    address[3] internal _operators;
    address internal _admin;
    address internal _owner;
}

/// @title Cyan Wallet Role Manager - A Cyan wallet's role manager's functionalities.
/// @author Bulgantamir Gankhuyag - <[email protected]>
/// @author Naranbayar Uuganbayar - <[email protected]>
abstract contract IRoleManager is RoleManagerStorage {
    event SetOwner(address owner);
    event SetAdmin(address admin);
    event SetOperator(uint8 index, address operator);

    modifier onlyOperator() {
        _checkOnlyOperator();
        _;
    }

    modifier onlyAdmin() {
        _checkOnlyAdmin();
        _;
    }

    modifier onlyOwner() {
        _checkOnlyOwner();
        _;
    }

    constructor(address admin) {
        require(admin != address(0x0), "Invalid admin address.");
        _admin = admin;
    }

    /// @notice Returns current owner of the wallet.
    /// @return Address of the current owner.
    function getOwner() external view virtual returns (address);

    /// @notice Changes the current admin.
    /// @param admin New admin address.
    function setAdmin(address admin) external virtual;

    /// @notice Returns current admin of the core contract.
    /// @return Address of the current admin.
    function getAdmin() external view virtual returns (address);

    /// @notice Sets the operator in the given index.
    /// @param index Index of the operator.
    /// @param operator Operator address.
    function setOperator(uint8 index, address operator) external virtual;

    /// @notice Returns an array of operators.
    /// @return An array of the operator addresses.
    function getOperators() external view virtual returns (address[3] memory);

    /// @notice Checks whether the given address is an operator.
    /// @param operator Address that will be checked.
    /// @return result Boolean result.
    function isOperator(address operator) external view virtual returns (bool result);

    /// @notice Checks whether the message sender is an operator.
    function _checkOnlyOperator() internal view virtual;

    /// @notice Checks whether the message sender is an admin.
    function _checkOnlyAdmin() internal view virtual;

    /// @notice Checks whether the message sender is an owner.
    function _checkOnlyOwner() internal view virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../modules/IModule.sol";

/// @title Cyan Wallet Module Manager Storage - A Cyan wallet's module manager's storage.
/// @author Bulgantamir Gankhuyag - <[email protected]>
/// @author Naranbayar Uuganbayar - <[email protected]>
abstract contract ModuleManagerStorage {
    /// @notice Storing allowed contract methods.
    ///     Note: Target Contract Address => Sighash of method => Module address
    mapping(address => mapping(bytes4 => address)) internal _modules;

    /// @notice Storing internally allowed module methods.
    ///     Note: Sighash of module method => Module address
    mapping(bytes4 => address) internal _internalModules;
}

/// @title Cyan Wallet Module Manager - A Cyan wallet's module manager's functionalities.
/// @author Bulgantamir Gankhuyag - <[email protected]>
/// @author Naranbayar Uuganbayar - <[email protected]>
abstract contract IModuleManager is ModuleManagerStorage {
    event SetModule(address target, bytes4 funcHash, address module);
    event SetInternalModule(bytes4 funcHash, address module);

    /// @notice Sets the handler module of the target's function.
    /// @param target Address of the target contract.
    /// @param funcHash Sighash of the target contract's method.
    /// @param module Address of the handler module.
    function setModule(
        address target,
        bytes4 funcHash,
        address module
    ) external virtual;

    /// @notice Returns a handling module of the target function.
    /// @param target Address of the target contract.
    /// @param funcHash Sighash of the target contract's method.
    /// @return module Handler module.
    function getModule(address target, bytes4 funcHash) external view returns (address) {
        return _modules[target][funcHash];
    }

    /// @notice Sets the internal handler module of the function.
    /// @param funcHash Sighash of the module method.
    /// @param module Address of the handler module.
    function setInternalModule(bytes4 funcHash, address module) external virtual;

    /// @notice Returns an internal handling module of the given function.
    /// @param funcHash Sighash of the module's method.
    /// @return module Handler module.
    function getInternalModule(bytes4 funcHash) external view returns (address) {
        return _internalModules[funcHash];
    }

    /// @notice Used to call module functions on the wallet.
    ///     Usually used to call locking function of the module on the wallet.
    /// @param data Data payload of the transaction.
    /// @return Result of the execution.
    function executeModule(bytes memory data) external virtual returns (bytes memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
pragma solidity 0.8.19;

interface IModule {
    /// @notice Executes given transaction data to given address.
    /// @param to Target contract address.
    /// @param value Value of the given transaction.
    /// @param data Calldata of the transaction.
    /// @return Result of the execution.
    function handleTransaction(
        address to,
        uint256 value,
        bytes calldata data
    ) external payable returns (bytes memory);
}