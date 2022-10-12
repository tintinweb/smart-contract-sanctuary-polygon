// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@rmrk-team/evm-contracts/contracts/implementations/RMRKBaseStorageImpl.sol";

contract SimpleBase is RMRKBaseStorageImpl {
    constructor(
        string memory symbol,
        string memory type_
    ) RMRKBaseStorageImpl(symbol, type_) {}
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.15;

import "../RMRK/base/RMRKBaseStorage.sol";
import "../RMRK/access/OwnableLock.sol";

/**
 * @dev Contract for storing 'base' elements of NFTs to be accessed
 * by instances of RMRKResource implementing contracts. This default
 * implementation includes an OwnableLock dependency, which allows
 * the deployer to freeze the state of the base contract.
 *
 * In addition, this implementation treats the base registry as an
 * append-only ledger, so
 */

contract RMRKBaseStorageImpl is OwnableLock, RMRKBaseStorage {
    constructor(string memory symbol_, string memory type__)
        RMRKBaseStorage(symbol_, type__)
    {}

    function addPart(IntakeStruct calldata intakeStruct)
        external
        onlyOwner
        notLocked
    {
        _addPart(intakeStruct);
    }

    function addPartList(IntakeStruct[] calldata intakeStructs)
        external
        onlyOwner
        notLocked
    {
        _addPartList(intakeStructs);
    }

    function addEquippableAddresses(
        uint64 partId,
        address[] memory equippableAddresses
    ) external onlyOwner {
        _addEquippableAddresses(partId, equippableAddresses);
    }

    function setEquippableAddresses(
        uint64 partId,
        address[] memory equippableAddresses
    ) external onlyOwner {
        _setEquippableAddresses(partId, equippableAddresses);
    }

    function setEquippableToAll(uint64 partId) external onlyOwner {
        _setEquippableToAll(partId);
    }

    function resetEquippableAddresses(uint64 partId) external onlyOwner {
        _resetEquippableAddresses(partId);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.15;

import "./IRMRKBaseStorage.sol";
import "@openzeppelin/contracts/utils/Address.sol";
// import "hardhat/console.sol";

error RMRKPartAlreadyExists();
error RMRKPartDoesNotExist();
error RMRKPartIsNotSlot();
error RMRKZeroLengthIdsPassed();
error RMRKBadConfig();

/**
 * @dev Base storage contract for RMRK equippable module.
 */
contract RMRKBaseStorage is IRMRKBaseStorage {
    using Address for address;

    /**
     * @dev Mapping of uint64 partId to IRMRKBaseStorage Part struct
     */
    mapping(uint64 => Part) private _parts;

    /**
     * @dev Mapping of uint64 partId to flag to set partd to be equippable by any
     */
    mapping(uint64 => bool) private _isEquippableToAll;

    uint64[] private _partIds;

    string private _symbol;
    string private _type;

    //TODO: Move to interface
    //TODO: Doc this struct, put JSON intake format in comments here
    struct IntakeStruct {
        uint64 partId;
        Part part;
    }

    constructor(string memory symbol_, string memory type__) {
        _symbol = symbol_;
        _type = type__;
    }

    /**
     * @dev Throws if the partId is uninitailized or is Fixed.
     */
    modifier onlySlot(uint64 partId) {
        _onlySlot(partId);
        _;
    }

    function _onlySlot(uint64 partId) internal view {
        ItemType itemType = _parts[partId].itemType;
        if (itemType == ItemType.None) revert RMRKPartDoesNotExist();
        if (itemType == ItemType.Fixed) revert RMRKPartIsNotSlot();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        returns (bool)
    {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IRMRKBaseStorage).interfaceId;
    }

    /**
     * @dev Returns symbol of associated collection
     * @return string base contract symbol
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns type of data of associated base
     * @return string data type
     */
    function type_() public view returns (string memory) {
        return _type;
    }

    /**
     * @dev Private helper function which writes n base item entries to storage.
     * Delegates to { _addPart } below.
     * @param partIntake array of structs of type IntakeStruct, which consists of partId and a nested part struct.
     */
    function _addPartList(IntakeStruct[] calldata partIntake) internal {
        uint256 len = partIntake.length;
        for (uint256 i; i < len; ) {
            _addPart(partIntake[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Private function which writes a single base item entry to storage.
     * @param partIntake struct of type IntakeStruct, which consists of partId and a nested part struct.
     *
     */
    function _addPart(IntakeStruct calldata partIntake) internal {
        uint64 partId = partIntake.partId;
        Part memory part = partIntake.part;

        if (_parts[partId].itemType != ItemType.None)
            revert RMRKPartAlreadyExists();
        if (part.itemType == ItemType.None) revert RMRKBadConfig();
        if (part.itemType == ItemType.Fixed && part.equippable.length != 0)
            revert RMRKBadConfig();

        _parts[partId] = part;
        _partIds.push(partId);

        emit AddedPart(
            partId,
            part.itemType,
            part.z,
            part.equippable,
            part.metadataURI
        );
    }

    /**
     * @dev Function which adds a number of equippableAddresses to a single base entry.
     */
    function _addEquippableAddresses(
        uint64 partId,
        address[] memory equippableAddresses
    ) internal onlySlot(partId) {
        if (equippableAddresses.length <= 0) revert RMRKZeroLengthIdsPassed();

        uint256 len = equippableAddresses.length;
        for (uint256 i; i < len; ) {
            _parts[partId].equippable.push(equippableAddresses[i]);
            unchecked {
                ++i;
            }
        }
        delete _isEquippableToAll[partId];

        emit AddedEquippables(partId, equippableAddresses);
    }

    /**
     * @dev Public function which sets a number of equippableAddresses, overwrites existing addresses.
     *
     */
    function _setEquippableAddresses(
        uint64 partId,
        address[] memory equippableAddresses
    ) internal onlySlot(partId) {
        if (equippableAddresses.length <= 0) revert RMRKZeroLengthIdsPassed();
        _parts[partId].equippable = equippableAddresses;
        delete _isEquippableToAll[partId];

        emit SetEquippables(partId, equippableAddresses);
    }

    /**
     * @dev Public function which removes all equippableAddresses for a partId.
     *
     */
    function _resetEquippableAddresses(uint64 partId)
        internal
        onlySlot(partId)
    {
        delete _parts[partId].equippable;
        delete _isEquippableToAll[partId];

        emit SetEquippables(partId, new address[](0));
    }

    /**
     * @dev Sets the isEquippableToAll flag to true, meaning that any collection may equip this partId.
     */
    function _setEquippableToAll(uint64 partId) internal onlySlot(partId) {
        _isEquippableToAll[partId] = true;
        emit SetEquippableToAll(partId);
    }

    /**
     * @dev Returns true if part is equippable to all.
     */
    function checkIsEquippableToAll(uint64 partId) public view returns (bool) {
        return _isEquippableToAll[partId];
    }

    /**
     * @dev Returns true if a collection may equip resource with partId.
     */
    function checkIsEquippable(uint64 partId, address targetAddress)
        public
        view
        returns (bool isEquippable)
    {
        // If this is equippable to all, we're good
        isEquippable = _isEquippableToAll[partId];

        // Otherwise, must check against each of the equippable for the part
        if (!isEquippable && _parts[partId].itemType == ItemType.Slot) {
            address[] memory equippable = _parts[partId].equippable;
            uint256 len = equippable.length;
            for (uint256 i; i < len; ) {
                if (targetAddress == equippable[i]) {
                    isEquippable = true;
                    break;
                }
                unchecked {
                    ++i;
                }
            }
        }
    }

    /**
    @dev Getter for a single base part.
    */
    function getPart(uint64 partId) public view returns (Part memory) {
        return (_parts[partId]);
    }

    /**
    @dev Getter for multiple base item entries.
    */
    function getParts(uint64[] calldata partIds)
        public
        view
        returns (Part[] memory)
    {
        uint256 numParts = partIds.length;
        Part[] memory parts = new Part[](numParts);

        for (uint256 i; i < numParts; ) {
            uint64 partId = partIds[i];
            parts[i] = _parts[partId];
            unchecked {
                ++i;
            }
        }

        return parts;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

/*
Minimal ownable lock, based on "openzeppelin's access/Ownable.sol";
*/
error RMRKLocked();
error RMRKNotOwner();
error RMRKNewOwnerIsZeroAddress();

contract OwnableLock is Context {
    bool private _lock;
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /**
     * @dev Throws if the lock flag is set to true.
     */
    modifier notLocked() {
        _onlyNotLocked();
        _;
    }

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
     * @dev Sets the lock -- once locked functions marked notLocked cannot be accessed.
     */
    function setLock() external onlyOwner {
        _lock = true;
    }

    /**
     * @dev Returns lock status.
     */
    function getLock() public view returns (bool) {
        return _lock;
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
        if (owner() == address(0)) revert RMRKNewOwnerIsZeroAddress();
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

    function _onlyOwner() private view {
        if (owner() != _msgSender()) revert RMRKNotOwner();
    }

    function _onlyNotLocked() private view {
        if (getLock()) revert RMRKLocked();
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

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IRMRKBaseStorage is IERC165 {
    /**
     * @dev emitted when one or more addresses are added for equippable status for partId.
     */
    event AddedPart(
        uint64 indexed partId,
        ItemType indexed itemType,
        uint8 zIndex,
        address[] equippableAddresses,
        string metadataURI
    );

    /**
     * @dev emitted when one or more addresses are added for equippable status for partId.
     */
    event AddedEquippables(
        uint64 indexed partId,
        address[] equippableAddresses
    );

    /**
     * @dev emitted when one or more addresses are whitelisted for equippable status for partId.
     * Overwrites previous equippable addresses.
     */
    event SetEquippables(uint64 indexed partId, address[] equippableAddresses);

    /**
     * @dev emitted when a partId is flagged as equippable by any.
     */
    event SetEquippableToAll(uint64 indexed partId);

    /**
     * @dev Item type enum for fixed and slot parts.
     */
    enum ItemType {
        None,
        Slot,
        Fixed
    }

    /**
    @dev Base struct for a standard RMRK base item. Requires a minimum of 3 storage slots per base item,
    * equivalent to roughly 60,000 gas as of Berlin hard fork (April 14, 2021), though 5-7 storage slots
    * is more realistic, given the standard length of an IPFS URI. This will result in between 25,000,000
    * and 35,000,000 gas per 250 resources--the maximum block size of ETH mainnet is 30M at peak usage.
    */
    struct Part {
        ItemType itemType; //1 byte
        uint8 z; //1 byte
        address[] equippable; //n Collections that can be equipped into this slot
        string metadataURI; //n bytes 32+
    }

    /**
     * @dev Returns true if the part at partId is equippable by targetAddress.
     *
     * Requirements: None
     */
    function checkIsEquippable(uint64 partId, address targetAddress)
        external
        view
        returns (bool);

    /**
     * @dev Returns true if the part at partId is equippable by all addresses.
     *
     * Requirements: None
     */
    function checkIsEquippableToAll(uint64 partId) external view returns (bool);

    /**
     * @dev Returns the part object at reference partId.
     *
     * Requirements: None
     */
    function getPart(uint64 partId) external view returns (Part memory);

    /**
     * @dev Returns the part objects at reference partIds.
     *
     * Requirements: None
     */
    function getParts(uint64[] calldata partIds)
        external
        view
        returns (Part[] memory);
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