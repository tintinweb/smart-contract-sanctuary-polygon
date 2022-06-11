// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../interfaces/IFactory.sol";
import "./DID.sol";
import "./DIDProxy.sol";


contract Factory is IFactory {

    mapping(address => address) public getDIDContact;
    address[] public didList;
    
    function createDID(address didOwner, uint256 salt, address[] memory alternativeOwners) public returns (address did) {
        require(didOwner != address(0), "Err: Invalid DID owner");
        require(getDIDContact[didOwner] == address(0), "Err: One owner, one DID");
         
        bytes memory bytecode = type(DID).creationCode;
        bytes32 saltHash = keccak256(abi.encodePacked(didOwner, salt));
        assembly {
            did := create2(0, add(bytecode, 32), mload(bytecode), saltHash)
        }
        IDID(did).initialize(didOwner, alternativeOwners);

        DIDProxy _proxy = new DIDProxy(did, didOwner);
        getDIDContact[didOwner] = address(_proxy);
        didList.push(address(_proxy)); 

        emit CreateDID(didOwner, alternativeOwners, IDID(did).getVersion(), did);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IFactory {

    event CreateDID(address indexed didOwner, address[] indexed alternativeOwners, uint8 version, address indexed did);

    function createDID(address primaryOwner, uint256 salt, address[] memory alternativeOwners) external returns (address);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./DIDOwnership.sol";

contract DID is IDID, DIDOwnership {

    address public factory;

    constructor() {
        factory = msg.sender;
    }

    function initialize(address didOwner_, address[] memory alternativeOwners_) public override {
        require(msg.sender == factory, "Err: FORBIDDEN"); // sufficient check
        primaryOwner = didOwner_;
        alternativeOwners = alternativeOwners_;
    }

    function execute(address to, uint256 value, bytes calldata data) external override returns (bool) {
        address sender = msg.sender;


        emit Execute(to, sender, 0, value);
        
        selfExecuting();
    }

    function proxyExecute(address to, uint256 value, bytes calldata data, uint256 nonce, bytes memory signatures) external override returns (bool) {

    }

    function encodeTransactionData(address to, uint256 value, bytes calldata data, uint256 nonce) external {

    }

    function getTransactionHash(
        address to,
        uint256 value,
        bytes calldata data,
        uint256 nonce
        ) external {

        }

    function checkSignature(
        bytes32 messageHash,
        bytes memory data,
        uint256 nonce,
        bytes memory signatures,
        uint256 requiredSignatures
        ) external returns (bool) {

        }

    function getVersion() external pure returns (uint8) {
        return 1;
    }

    function getChainId() external view returns (uint256) {
        return block.chainid;
    }

    function domainSeparator() external view returns (bytes32) {

    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";
import "@openzeppelin/contracts/utils/Address.sol";


contract DIDProxy is Proxy {

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.did.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0xb2db9feb911d199d1df38acfcda5d309604185f0ea8295167c9069e5702dbce7;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address logic_, address admin_) payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.did.proxy.implementation")) - 1));
        _setImplementation(logic_);
        _setAdmin(admin_);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Returns the current implementation address.
     */
    function getImplementation() external view returns (address) {
        return _implementation();
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "DIDProxy: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) public ifAdmin {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }


    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.did.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xa76c8e3f9b8a79f32cf49b168697ea45af962b5a9909900c4de62dc0e281ec64;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     */
    function getAdmin() public view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "DIDProxy: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function changeAdmin(address newAdmin) public ifAdmin {
        emit AdminChanged(getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../interfaces/IDID.sol";


contract DIDOwnership {

    address public primaryOwner;
    address[] public alternativeOwners;

    function getAlternativeOwners() public view returns (address[] memory) {
        return alternativeOwners;
    }

    modifier isPrimaryOwner() {
        require(primaryOwner == msg.sender, "DID: call limited to the primary owner.");
        _;
    }

    modifier isOwner() {
        require(primaryOwner == msg.sender || isDIDAlternativeOwner(msg.sender), "DID: call limited to the owner.");
        _;
    }

    function isDIDAlternativeOwner(address addr) public view returns (bool) {
        bool _isOwner = false;
        for (uint256 i = 0; i < alternativeOwners.length; i++) {
            if (alternativeOwners[i] == addr) {
                _isOwner = true;
                break;
            }
        }
        return _isOwner;
    }


    
    event AddAlternativeOwner(address sender, address indexed theOwner);
    event DeleteAlternativeOwner(address sender, address indexed theOwner);

    function addAlternativeOwner(address newOwner) external emptyAddress(newOwner) returns (bool) {
        require (!isDIDAlternativeOwner(newOwner), "DIDOwnership: the owner exists");

        alternativeOwners.push(newOwner);
        emit AddAlternativeOwner(msg.sender, newOwner);
        
        selfExecuting();
        return true;
    }

    function deleteAlternativeOwner(address theOwner) external isPrimaryOwner emptyAddress(theOwner) returns (bool) {
        bool _isOwner = false;
        for (uint256 i = 0; i < alternativeOwners.length; i++) {
            if (alternativeOwners[i] == theOwner) {
                _isOwner = true;
                delete alternativeOwners[i];
                break;
            }
        } 

        require (_isOwner, "DIDOwnership: the owner not exists");
        emit DeleteAlternativeOwner(msg.sender, theOwner);
        
        selfExecuting();
        return true;
    }


    struct OwnershipTransaction {
        address initiator;
        address newOwner;
        uint256 startTime;
        uint256 durationTime;
    }

    mapping(address => OwnershipTransaction) _ownershipTransaction;

    event SubmitOwnershipTransfer(address sender, address indexed newOwner, uint256 startTime, uint256 indexed durationTime);
    event TerminateOwnershipTransfer(address sender, address indexed newOwner, uint256 startTime, uint256 indexed durationTime, uint256 terminatedTime);
    event ConfirmOwnershipTransfer(address sender, address indexed oldOwner, address indexed newOwner, uint256 startTime, uint256 indexed durationTime, uint256 confirmedTime);

    /***  紧急联系人: 同时只能有一个新owner可以被转移  ***/

    // 1.发起owner身份转移到新地址，允许发起覆盖操作
    function submitOwnershipTransfer(address newOwner, uint256 durationTime) external isOwner emptyAddress(newOwner) returns (bool) {
        uint256 currentTime = block.timestamp;
        _ownershipTransaction[address(this)] = OwnershipTransaction(msg.sender, newOwner, currentTime, durationTime);
        emit SubmitOwnershipTransfer(msg.sender, newOwner, currentTime, durationTime);
        return true;
    }

    // 2.终止owner身份转移
    function terminateOwnershipTransfer() external isOwner returns (bool) {
        OwnershipTransaction memory _tx = _ownershipTransaction[address(this)];
        delete _ownershipTransaction[address(this)];
        emit TerminateOwnershipTransfer(msg.sender, _tx.newOwner, _tx.startTime, _tx.durationTime, block.timestamp);
        return true;
    }

    // 3.新owner身份确认转移
    function confirmOwnershipTransfer() public isOwner returns (bool) {
        OwnershipTransaction memory _tx = _ownershipTransaction[address(this)];

        bool isDue = _tx.startTime + _tx.durationTime > block.timestamp;
        if (_tx.durationTime == 0 || isDue) {
            if (isDue) {
                delete _ownershipTransaction[address(this)];
            }
            return false;
        }
        
        address oldAddr = primaryOwner;
        primaryOwner = _tx.newOwner;
        delete _ownershipTransaction[address(this)];
        emit ConfirmOwnershipTransfer(msg.sender, oldAddr, _tx.newOwner, _tx.startTime, _tx.durationTime, block.timestamp);

        return true;
    }

    // 4.获取当前新owner身份转移的状态
    function getOwnershipTransferringStatus() external view returns (OwnershipTransaction memory) {
        return _ownershipTransaction[address(this)];
    }


    function selfExecuting() internal {
        confirmOwnershipTransfer();
    }

    modifier emptyAddress(address addr_) {
        require(addr_ != address(0), "DID: Empty address");
        _;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;


interface IDID {

    event Execute(address indexed to, address indexed sender, uint256 indexed nonce, uint256 value);


    function initialize(address didOwner, address[] memory alternativeOwners) external;

    function execute(address to, uint256 value, bytes calldata data) external returns (bool);

    function proxyExecute(address to, uint256 value, bytes calldata data, uint256 nonce, bytes memory signatures) external returns (bool);

    function getVersion() external pure returns (uint8);
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

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
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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