//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../../interfaces/INFT.sol";
import "../../libraries/NodesStorage.sol";
import "../../libraries/nodes/ManufacturerStorage.sol";

import {DEFAULT_ADMIN_ROLE} from "../../shared/Roles.sol";
import {AttributeInfoPair} from "../../shared/Types.sol";

import "@solidstate/contracts/access/access_control/AccessControlInternal.sol";

/// @title Manufacturer
/// @notice Contract that represents the Manufacturer node
contract Manufacturer is AccessControlInternal {
    event ManufacturerIdProxySet(address indexed proxy);
    event ManufacturerAttributeAdded(string attribute);
    event ManufacturerAttributeSet(
        uint256 tokenId,
        string attribute,
        string info
    );
    event ControllerSet(address indexed controller);
    event ManufacturerNodeMinted(uint256 tokenId, address indexed owner);

    modifier onlyNftProxy() {
        require(
            msg.sender == ManufacturerStorage.getStorage().idProxyAddress,
            "Only NFT Proxy"
        );
        _;
    }

    // ***** Admin management ***** //

    /// @notice Sets the NFT proxy associated with the Manufacturer node
    /// @dev Only an admin can set the address
    /// @param addr The address of the proxy
    function setManufacturerIdProxyAddress(address addr)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(addr != address(0), "Non zero address");
        ManufacturerStorage.getStorage().idProxyAddress = addr;

        emit ManufacturerIdProxySet(addr);
    }

    /// @notice Adds an attribute to the whitelist
    /// @dev Only an admin can add a new attribute
    /// @param attribute The attribute to be added
    function addManufacturerAttribute(string calldata attribute)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            AttributeSet.add(
                ManufacturerStorage.getStorage().whitelistedAttributes,
                attribute
            ),
            "Attribute already exists"
        );

        emit ManufacturerAttributeAdded(attribute);
    }

    /// @notice Sets a address controller
    /// @dev Only an admin can set new controllers
    /// @param _controller The address of the controller
    function setController(address _controller)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        ManufacturerStorage.Storage storage s = ManufacturerStorage
            .getStorage();
        require(_controller != address(0), "Non zero address");
        require(
            !s.controllers[_controller].isController,
            "Already a controller"
        );

        s.controllers[_controller].isController = true;

        emit ControllerSet(_controller);
    }

    // ***** Interaction with nodes ***** //

    /// @notice Mints manufacturers in batch
    /// @dev Caller must be an admin
    /// @dev It is assumed the 'Name' attribute is whitelisted in advance
    /// @param owner The address of the new owner
    /// @param names List of manufacturer names
    function mintManufacturerBatch(address owner, string[] calldata names)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_hasRole(DEFAULT_ADMIN_ROLE, owner), "Owner must be an admin");

        ManufacturerStorage.Storage storage s = ManufacturerStorage
            .getStorage();

        uint256 newTokenId;
        string memory name;
        for (uint256 i = 0; i < names.length; i++) {
            name = names[i];

            require(
                s.manufacturerNameToNodeId[name] == 0,
                "Manufacturer name already registered"
            );

            newTokenId = INFT(s.idProxyAddress).safeMint(owner);

            s.manufacturerNameToNodeId[name] = newTokenId;
            s.nodeIdToManufacturerName[newTokenId] = name;

            emit ManufacturerNodeMinted(newTokenId, owner);
        }
    }

    /// @notice Mints a manufacturer
    /// @dev Caller must be an admin
    /// @param owner The address of the new owner
    /// @param name Name of the manufacturer
    /// @param attrInfoPairList List of attribute-info pairs to be added
    function mintManufacturer(
        address owner,
        string calldata name,
        AttributeInfoPair[] calldata attrInfoPairList
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        ManufacturerStorage.Storage storage s = ManufacturerStorage
            .getStorage();
        require(!s.controllers[owner].manufacturerMinted, "Invalid request");
        require(
            s.manufacturerNameToNodeId[name] == 0,
            "Manufacturer name already registered"
        );

        address idProxyAddress = s.idProxyAddress;

        s.controllers[owner].isController = true;
        s.controllers[owner].manufacturerMinted = true;

        uint256 newTokenId = INFT(idProxyAddress).safeMint(owner);

        s.manufacturerNameToNodeId[name] = newTokenId;
        s.nodeIdToManufacturerName[newTokenId] = name;

        _setInfos(newTokenId, attrInfoPairList);

        emit ManufacturerNodeMinted(newTokenId, msg.sender);
    }

    /// @notice Add infos to node
    /// @dev attributes must be whitelisted
    /// @param tokenId Node id where the info will be added
    /// @param attrInfoList List of attribute-info pairs to be added
    function setManufacturerInfo(
        uint256 tokenId,
        AttributeInfoPair[] calldata attrInfoList
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            INFT(ManufacturerStorage.getStorage().idProxyAddress).exists(
                tokenId
            ),
            "Invalid manufacturer node"
        );
        _setInfos(tokenId, attrInfoList);
    }

    /**
     * @notice Verify if an address is allowed to own an manufacturer node and set as minted
     * The former owner of the node is set as not minted, as it will not be the owner of a node after the transfer
     * @dev Can only be called by the ManufacturerId Proxy
     * @dev The address must be a controller and not yet minted a node
     * @param from the address to be verified and set
     * @param to the address to be verified
     */
    function updateManufacturerMinted(address from, address to)
        external
        onlyNftProxy
    {
        ManufacturerStorage.Storage storage s = ManufacturerStorage
            .getStorage();
        require(
            s.controllers[to].isController &&
                !s.controllers[to].manufacturerMinted,
            "Address is not allowed to own a new token"
        );

        s.controllers[from].manufacturerMinted = false;
        s.controllers[to].manufacturerMinted = true;
    }

    /// @notice Verify if an address is a controller
    /// @param addr the address to be verified
    function isController(address addr)
        external
        view
        returns (bool _isController)
    {
        _isController = ManufacturerStorage
            .getStorage()
            .controllers[addr]
            .isController;
    }

    /// @notice Verify if an address has minted a manufacturer
    /// @param addr the address to be verified
    function isManufacturerMinted(address addr)
        external
        view
        returns (bool _isManufacturerMinted)
    {
        _isManufacturerMinted = ManufacturerStorage
            .getStorage()
            .controllers[addr]
            .manufacturerMinted;
    }

    /// @notice Verify if an address is allowed to own a manufacturer node
    /// @dev The address must be a controller and not yet minted a node
    /// @param addr the address to be verified
    function isAllowedToOwnManufacturerNode(address addr)
        external
        view
        returns (bool _isAllowed)
    {
        ManufacturerStorage.Storage storage ms = ManufacturerStorage
            .getStorage();
        _isAllowed =
            ms.controllers[addr].isController &&
            !ms.controllers[addr].manufacturerMinted;
    }

    /// @notice Gets the Manufacturer Id by name
    /// @dev If the manufacturer is not minted it will return 0
    /// @param name Name associated with the manufacturer
    function getManufacturerIdByName(string calldata name)
        external
        view
        returns (uint256 nodeId)
    {
        nodeId = ManufacturerStorage.getStorage().manufacturerNameToNodeId[
            name
        ];
    }

    /// @notice Gets the Manufacturer name by id
    /// @dev If the manufacturer is not minted it will return an empty string
    /// @param tokenId Token id to get the associated name
    function getManufacturerNameById(uint256 tokenId)
        external
        view
        returns (string memory name)
    {
        name = ManufacturerStorage.getStorage().nodeIdToManufacturerName[
            tokenId
        ];
    }

    // ***** PRIVATE FUNCTIONS ***** //

    /// @dev Internal function to add infos to node
    /// @dev attributes must be whitelisted
    /// @param tokenId Node id where the info will be added
    /// @param attrInfoPairList List of attribute-info pairs to be added
    function _setInfos(
        uint256 tokenId,
        AttributeInfoPair[] calldata attrInfoPairList
    ) private {
        NodesStorage.Storage storage ns = NodesStorage.getStorage();
        ManufacturerStorage.Storage storage s = ManufacturerStorage
            .getStorage();
        address idProxyAddress = s.idProxyAddress;

        for (uint256 i = 0; i < attrInfoPairList.length; i++) {
            require(
                AttributeSet.exists(
                    s.whitelistedAttributes,
                    attrInfoPairList[i].attribute
                ),
                "Not whitelisted"
            );
            ns.nodes[idProxyAddress][tokenId].info[
                attrInfoPairList[i].attribute
            ] = attrInfoPairList[i].info;

            emit ManufacturerAttributeSet(
                tokenId,
                attrInfoPairList[i].attribute,
                attrInfoPairList[i].info
            );
        }
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

/// @title INFT
/// @notice Interface of a generic NFT
interface INFT {
    function safeMint(address to) external returns (uint256);

    function safeTransferByRegistry(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function exists(uint256 tokenId) external view returns (bool);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

/// @title NodesStorage
/// @notice Storage of the Nodes contract
library NodesStorage {
    bytes32 internal constant NODES_STORAGE_SLOT =
        keccak256("DIMORegistry.nodes.storage");

    struct Node {
        uint256 parentNode;
        mapping(string => string) info;
    }

    struct Storage {
        mapping(address => mapping(uint256 => Node)) nodes;
    }

    /* solhint-disable no-inline-assembly */
    function getStorage() internal pure returns (Storage storage s) {
        bytes32 slot = NODES_STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }
    /* solhint-enable no-inline-assembly */
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../AttributeSet.sol";

/// @title ManufacturerStorage
/// @notice Storage of the Manufacturer contract
library ManufacturerStorage {
    using AttributeSet for AttributeSet.Set;

    bytes32 private constant MANUFACTURER_STORAGE_SLOT =
        keccak256("DIMORegistry.Manufacturer.storage");

    struct Controller {
        bool isController;
        bool manufacturerMinted;
    }

    struct Storage {
        address idProxyAddress;
        // [Controller address] => is controller, has minted manufacturer
        mapping(address => Controller) controllers;
        // Allowed node attribute
        AttributeSet.Set whitelistedAttributes;
        // Manufacturer name => Manufacturer Id
        mapping(string => uint256) manufacturerNameToNodeId;
        // Manufacturer Id => Manufacturer name
        mapping(uint256 => string) nodeIdToManufacturerName;
    }

    /* solhint-disable no-inline-assembly */
    function getStorage() internal pure returns (Storage storage s) {
        bytes32 slot = MANUFACTURER_STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }
    /* solhint-enable no-inline-assembly */
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;
bytes32 constant MINTER_ROLE = keccak256("Minter");

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

/// @notice File to store shared structs

struct AttributeInfoPair {
    string attribute;
    string info;
}

struct AftermarketDeviceInfos {
    address addr;
    AttributeInfoPair[] attrInfoPairs;
}

struct AftermarketDeviceOwnerPair {
    uint256 aftermarketDeviceNodeId;
    address owner;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { EnumerableSet } from '../../data/EnumerableSet.sol';
import { AddressUtils } from '../../utils/AddressUtils.sol';
import { UintUtils } from '../../utils/UintUtils.sol';
import { IAccessControlInternal } from './IAccessControlInternal.sol';
import { AccessControlStorage } from './AccessControlStorage.sol';

/**
 * @title Role-based access control system
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
abstract contract AccessControlInternal is IAccessControlInternal {
    using AddressUtils for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    using UintUtils for uint256;

    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /*
     * @notice query whether role is assigned to account
     * @param role role to query
     * @param account account to query
     * @return whether role is assigned to account
     */
    function _hasRole(bytes32 role, address account)
        internal
        view
        virtual
        returns (bool)
    {
        return
            AccessControlStorage.layout().roles[role].members.contains(account);
    }

    /**
     * @notice revert if sender does not have given role
     * @param role role to query
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, msg.sender);
    }

    /**
     * @notice revert if given account does not have given role
     * @param role role to query
     * @param account to query
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!_hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        'AccessControl: account ',
                        account.toString(),
                        ' is missing role ',
                        uint256(role).toHexString(32)
                    )
                )
            );
        }
    }

    /*
     * @notice query admin role for given role
     * @param role role to query
     * @return admin role
     */
    function _getRoleAdmin(bytes32 role)
        internal
        view
        virtual
        returns (bytes32)
    {
        return AccessControlStorage.layout().roles[role].adminRole;
    }

    /**
     * @notice set role as admin role
     * @param role role to set
     * @param adminRole admin role to set
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = _getRoleAdmin(role);
        AccessControlStorage.layout().roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /*
     * @notice assign role to given account
     * @param role role to assign
     * @param account recipient of role assignment
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        AccessControlStorage.layout().roles[role].members.add(account);
        emit RoleGranted(role, account, msg.sender);
    }

    /*
     * @notice unassign role from given account
     * @param role role to unassign
     * @parm account
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        AccessControlStorage.layout().roles[role].members.remove(account);
        emit RoleRevoked(role, account, msg.sender);
    }

    /**
     * @notice relinquish role
     * @param role role to relinquish
     */
    function _renounceRole(bytes32 role) internal virtual {
        _revokeRole(role, msg.sender);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

/// @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)

library AttributeSet {
    struct Set {
        string[] _values;
        mapping(string => uint256) _indexes;
    }

    function add(Set storage set, string calldata key) internal returns (bool) {
        if (!exists(set, key)) {
            set._values.push(key);
            set._indexes[key] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function remove(Set storage set, string calldata key)
        internal
        returns (bool)
    {
        uint256 valueIndex = set._indexes[key];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                string memory lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    function count(Set storage set) internal view returns (uint256) {
        return (set._values.length);
    }

    function exists(Set storage set, string calldata key)
        internal
        view
        returns (bool)
    {
        return set._indexes[key] != 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Set implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableSet {
    error EnumerableSet__IndexOutOfBounds();

    struct Set {
        bytes32[] _values;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct Bytes32Set {
        Set _inner;
    }

    struct AddressSet {
        Set _inner;
    }

    struct UintSet {
        Set _inner;
    }

    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }

    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    function indexOf(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, value);
    }

    function indexOf(AddressSet storage set, address value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(uint256(uint160(value))));
    }

    function indexOf(UintSet storage set, uint256 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(value));
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    function toArray(Bytes32Set storage set)
        internal
        view
        returns (bytes32[] memory)
    {
        uint256 len = _length(set._inner);
        bytes32[] memory arr = new bytes32[](len);

        unchecked {
            for (uint256 index; index < len; ++index) {
                arr[index] = at(set, index);
            }
        }

        return arr;
    }

    function toArray(AddressSet storage set)
        internal
        view
        returns (address[] memory)
    {
        uint256 len = _length(set._inner);
        address[] memory arr = new address[](len);

        unchecked {
            for (uint256 index; index < len; ++index) {
                arr[index] = at(set, index);
            }
        }

        return arr;
    }

    function toArray(UintSet storage set)
        internal
        view
        returns (uint256[] memory)
    {
        uint256 len = _length(set._inner);
        uint256[] memory arr = new uint256[](len);

        unchecked {
            for (uint256 index; index < len; ++index) {
                arr[index] = at(set, index);
            }
        }

        return arr;
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        if (index >= set._values.length)
            revert EnumerableSet__IndexOutOfBounds();
        return set._values[index];
    }

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _indexOf(Set storage set, bytes32 value)
        private
        view
        returns (uint256)
    {
        unchecked {
            return set._indexes[value] - 1;
        }
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            unchecked {
                bytes32 last = set._values[set._values.length - 1];

                // move last value to now-vacant index

                set._values[valueIndex - 1] = last;
                set._indexes[last] = valueIndex;
            }
            // clear last index

            set._values.pop();
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { UintUtils } from './UintUtils.sol';

library AddressUtils {
    using UintUtils for uint256;

    error AddressUtils__InsufficientBalance();
    error AddressUtils__NotContract();
    error AddressUtils__SendValueFailed();

    function toString(address account) internal pure returns (string memory) {
        return uint256(uint160(account)).toHexString(20);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{ value: amount }('');
        if (!success) revert AddressUtils__SendValueFailed();
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCall(target, data, 'AddressUtils: failed low-level call');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, error);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                'AddressUtils: failed low-level call with value'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory) {
        if (value > address(this).balance)
            revert AddressUtils__InsufficientBalance();
        return _functionCallWithValue(target, data, value, error);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        if (!isContract(target)) revert AddressUtils__NotContract();

        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );

        if (success) {
            return returnData;
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title utility functions for uint256 operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library UintUtils {
    error UintUtils__InsufficientHexLength();

    bytes16 private constant HEX_SYMBOLS = '0123456789abcdef';

    function add(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? sub(a, -b) : a + uint256(b);
    }

    function sub(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? add(a, -b) : a - uint256(b);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0';
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

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0x00';
        }

        uint256 length = 0;

        for (uint256 temp = value; temp != 0; temp >>= 8) {
            unchecked {
                length++;
            }
        }

        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';

        unchecked {
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = HEX_SYMBOLS[value & 0xf];
                value >>= 4;
            }
        }

        if (value != 0) revert UintUtils__InsufficientHexLength();

        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial AccessControl interface needed by internal functions
 */
interface IAccessControlInternal {
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { EnumerableSet } from '../../data/EnumerableSet.sol';

library AccessControlStorage {
    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    struct Layout {
        mapping(bytes32 => RoleData) roles;
    }

    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.AccessControl');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}