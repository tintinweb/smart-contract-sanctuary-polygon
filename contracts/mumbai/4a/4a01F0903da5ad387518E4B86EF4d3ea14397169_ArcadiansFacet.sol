// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
    function _hasRole(
        bytes32 role,
        address account
    ) internal view virtual returns (bool) {
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
    function _getRoleAdmin(
        bytes32 role
    ) internal view virtual returns (bytes32) {
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

pragma solidity ^0.8.8;

/**
 * @title Map implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableMap {
    error EnumerableMap__IndexOutOfBounds();
    error EnumerableMap__NonExistentKey();

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        MapEntry[] _entries;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct AddressToAddressMap {
        Map _inner;
    }

    struct UintToAddressMap {
        Map _inner;
    }

    function at(
        AddressToAddressMap storage map,
        uint256 index
    ) internal view returns (address, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);

        return (
            address(uint160(uint256(key))),
            address(uint160(uint256(value)))
        );
    }

    function at(
        UintToAddressMap storage map,
        uint256 index
    ) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    function contains(
        AddressToAddressMap storage map,
        address key
    ) internal view returns (bool) {
        return _contains(map._inner, bytes32(uint256(uint160(key))));
    }

    function contains(
        UintToAddressMap storage map,
        uint256 key
    ) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    function length(
        AddressToAddressMap storage map
    ) internal view returns (uint256) {
        return _length(map._inner);
    }

    function length(
        UintToAddressMap storage map
    ) internal view returns (uint256) {
        return _length(map._inner);
    }

    function get(
        AddressToAddressMap storage map,
        address key
    ) internal view returns (address) {
        return
            address(
                uint160(
                    uint256(_get(map._inner, bytes32(uint256(uint160(key)))))
                )
            );
    }

    function get(
        UintToAddressMap storage map,
        uint256 key
    ) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    function set(
        AddressToAddressMap storage map,
        address key,
        address value
    ) internal returns (bool) {
        return
            _set(
                map._inner,
                bytes32(uint256(uint160(key))),
                bytes32(uint256(uint160(value)))
            );
    }

    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    function remove(
        AddressToAddressMap storage map,
        address key
    ) internal returns (bool) {
        return _remove(map._inner, bytes32(uint256(uint160(key))));
    }

    function remove(
        UintToAddressMap storage map,
        uint256 key
    ) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    function toArray(
        AddressToAddressMap storage map
    )
        internal
        view
        returns (address[] memory keysOut, address[] memory valuesOut)
    {
        uint256 len = map._inner._entries.length;

        keysOut = new address[](len);
        valuesOut = new address[](len);

        unchecked {
            for (uint256 i; i < len; ++i) {
                keysOut[i] = address(
                    uint160(uint256(map._inner._entries[i]._key))
                );
                valuesOut[i] = address(
                    uint160(uint256(map._inner._entries[i]._value))
                );
            }
        }
    }

    function toArray(
        UintToAddressMap storage map
    )
        internal
        view
        returns (uint256[] memory keysOut, address[] memory valuesOut)
    {
        uint256 len = map._inner._entries.length;

        keysOut = new uint256[](len);
        valuesOut = new address[](len);

        unchecked {
            for (uint256 i; i < len; ++i) {
                keysOut[i] = uint256(map._inner._entries[i]._key);
                valuesOut[i] = address(
                    uint160(uint256(map._inner._entries[i]._value))
                );
            }
        }
    }

    function keys(
        AddressToAddressMap storage map
    ) internal view returns (address[] memory keysOut) {
        uint256 len = map._inner._entries.length;

        keysOut = new address[](len);

        unchecked {
            for (uint256 i; i < len; ++i) {
                keysOut[i] = address(
                    uint160(uint256(map._inner._entries[i]._key))
                );
            }
        }
    }

    function keys(
        UintToAddressMap storage map
    ) internal view returns (uint256[] memory keysOut) {
        uint256 len = map._inner._entries.length;

        keysOut = new uint256[](len);

        unchecked {
            for (uint256 i; i < len; ++i) {
                keysOut[i] = uint256(map._inner._entries[i]._key);
            }
        }
    }

    function values(
        AddressToAddressMap storage map
    ) internal view returns (address[] memory valuesOut) {
        uint256 len = map._inner._entries.length;

        valuesOut = new address[](len);

        unchecked {
            for (uint256 i; i < len; ++i) {
                valuesOut[i] = address(
                    uint160(uint256(map._inner._entries[i]._value))
                );
            }
        }
    }

    function values(
        UintToAddressMap storage map
    ) internal view returns (address[] memory valuesOut) {
        uint256 len = map._inner._entries.length;

        valuesOut = new address[](len);

        unchecked {
            for (uint256 i; i < len; ++i) {
                valuesOut[i] = address(
                    uint160(uint256(map._inner._entries[i]._value))
                );
            }
        }
    }

    function _at(
        Map storage map,
        uint256 index
    ) private view returns (bytes32, bytes32) {
        if (index >= map._entries.length)
            revert EnumerableMap__IndexOutOfBounds();

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    function _contains(
        Map storage map,
        bytes32 key
    ) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) revert EnumerableMap__NonExistentKey();
        unchecked {
            return map._entries[keyIndex - 1]._value;
        }
    }

    function _set(
        Map storage map,
        bytes32 key,
        bytes32 value
    ) private returns (bool) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) {
            map._entries.push(MapEntry({ _key: key, _value: value }));
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            unchecked {
                map._entries[keyIndex - 1]._value = value;
            }
            return false;
        }
    }

    function _remove(Map storage map, bytes32 key) private returns (bool) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) {
            unchecked {
                MapEntry storage last = map._entries[map._entries.length - 1];

                // move last entry to now-vacant index
                map._entries[keyIndex - 1] = last;
                map._indexes[last._key] = keyIndex;
            }

            // clear last index
            map._entries.pop();
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
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

    function at(
        Bytes32Set storage set,
        uint256 index
    ) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    function at(
        AddressSet storage set,
        uint256 index
    ) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function at(
        UintSet storage set,
        uint256 index
    ) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    function contains(
        Bytes32Set storage set,
        bytes32 value
    ) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function contains(
        AddressSet storage set,
        address value
    ) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(
        UintSet storage set,
        uint256 value
    ) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function indexOf(
        Bytes32Set storage set,
        bytes32 value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, value);
    }

    function indexOf(
        AddressSet storage set,
        address value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, bytes32(uint256(uint160(value))));
    }

    function indexOf(
        UintSet storage set,
        uint256 value
    ) internal view returns (uint256) {
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

    function add(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _add(set._inner, value);
    }

    function add(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function remove(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(
        UintSet storage set,
        uint256 value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function toArray(
        Bytes32Set storage set
    ) internal view returns (bytes32[] memory) {
        return set._inner._values;
    }

    function toArray(
        AddressSet storage set
    ) internal view returns (address[] memory) {
        bytes32[] storage values = set._inner._values;
        address[] storage array;

        assembly {
            array.slot := values.slot
        }

        return array;
    }

    function toArray(
        UintSet storage set
    ) internal view returns (uint256[] memory) {
        bytes32[] storage values = set._inner._values;
        uint256[] storage array;

        assembly {
            array.slot := values.slot
        }

        return array;
    }

    function _at(
        Set storage set,
        uint256 index
    ) private view returns (bytes32) {
        if (index >= set._values.length)
            revert EnumerableSet__IndexOutOfBounds();
        return set._values[index];
    }

    function _contains(
        Set storage set,
        bytes32 value
    ) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _indexOf(
        Set storage set,
        bytes32 value
    ) private view returns (uint256) {
        unchecked {
            return set._indexes[value] - 1;
        }
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _add(
        Set storage set,
        bytes32 value
    ) private returns (bool status) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            status = true;
        }
    }

    function _remove(
        Set storage set,
        bytes32 value
    ) private returns (bool status) {
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

            status = true;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165 } from './IERC165.sol';
import { IERC1155Internal } from './IERC1155Internal.sol';

/**
 * @title ERC1155 interface
 * @dev see https://github.com/ethereum/EIPs/issues/1155
 */
interface IERC1155 is IERC1155Internal, IERC165 {
    /**
     * @notice query the balance of given token held by given address
     * @param account address to query
     * @param id token to query
     * @return token balance
     */
    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

    /**
     * @notice query the balances of given tokens held by given addresses
     * @param accounts addresss to query
     * @param ids tokens to query
     * @return token balances
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @notice query approval status of given operator with respect to given address
     * @param account address to query for approval granted
     * @param operator address to query for approval received
     * @return whether operator is approved to spend tokens held by account
     */
    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool);

    /**
     * @notice grant approval to or revoke approval from given operator to spend held tokens
     * @param operator address whose approval status to update
     * @param status whether operator should be considered approved
     */
    function setApprovalForAll(address operator, bool status) external;

    /**
     * @notice transfer tokens between given addresses, checking for ERC1155Receiver implementation if applicable
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @notice transfer batch of tokens between given addresses, checking for ERC1155Receiver implementation if applicable
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param ids list of token IDs
     * @param amounts list of quantities of tokens to transfer
     * @param data data payload
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC1155 interface needed by internal functions
 */
interface IERC1155Internal {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165Internal } from './IERC165Internal.sol';

/**
 * @title ERC165 interface registration interface
 * @dev see https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 is IERC165Internal {
    /**
     * @notice query whether contract has registered support for given interface
     * @param interfaceId interface id
     * @return bool whether interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165Internal } from './IERC165Internal.sol';

/**
 * @title ERC165 interface registration interface
 */
interface IERC165Internal {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165 } from './IERC165.sol';
import { IERC721Internal } from './IERC721Internal.sol';

/**
 * @title ERC721 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721 is IERC721Internal, IERC165 {
    /**
     * @notice query the balance of given address
     * @return balance quantity of tokens held
     */
    function balanceOf(address account) external view returns (uint256 balance);

    /**
     * @notice query the owner of given token
     * @param tokenId token to query
     * @return owner token owner
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     * @param data data payload
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @notice transfer token between given addresses, without checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @notice grant approval to given account to spend token
     * @param operator address to be approved
     * @param tokenId token to approve
     */
    function approve(address operator, uint256 tokenId) external payable;

    /**
     * @notice get approval status for given token
     * @param tokenId token to query
     * @return operator address approved to spend token
     */
    function getApproved(
        uint256 tokenId
    ) external view returns (address operator);

    /**
     * @notice grant approval to or revoke approval from given account to spend all tokens held by sender
     * @param operator address to be approved
     * @param status approval status
     */
    function setApprovalForAll(address operator, bool status) external;

    /**
     * @notice query approval status of given operator with respect to given address
     * @param account address to query for approval granted
     * @param operator address to query for approval received
     * @return status whether operator is approved to spend tokens held by account
     */
    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool status);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC721 interface needed by internal functions
 */
interface IERC721Internal {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed operator,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165 } from '../../../interfaces/IERC165.sol';
import { IERC165Base } from './IERC165Base.sol';
import { ERC165BaseInternal } from './ERC165BaseInternal.sol';
import { ERC165BaseStorage } from './ERC165BaseStorage.sol';

/**
 * @title ERC165 implementation
 */
abstract contract ERC165Base is IERC165Base, ERC165BaseInternal {
    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return _supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165BaseInternal } from './IERC165BaseInternal.sol';
import { ERC165BaseStorage } from './ERC165BaseStorage.sol';

/**
 * @title ERC165 implementation
 */
abstract contract ERC165BaseInternal is IERC165BaseInternal {
    /**
     * @notice indicates whether an interface is already supported based on the interfaceId
     * @param interfaceId id of interface to check
     * @return bool indicating whether interface is supported
     */
    function _supportsInterface(
        bytes4 interfaceId
    ) internal view returns (bool) {
        return ERC165BaseStorage.layout().supportedInterfaces[interfaceId];
    }

    /**
     * @notice sets status of interface support
     * @param interfaceId id of interface to set status for
     * @param status boolean indicating whether interface will be set as supported
     */
    function _setSupportsInterface(bytes4 interfaceId, bool status) internal {
        if (interfaceId == 0xffffffff) revert ERC165Base__InvalidInterfaceId();
        ERC165BaseStorage.layout().supportedInterfaces[interfaceId] = status;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ERC165BaseStorage {
    struct Layout {
        mapping(bytes4 => bool) supportedInterfaces;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC165Base');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC165 } from '../../../interfaces/IERC165.sol';
import { IERC165BaseInternal } from './IERC165BaseInternal.sol';

interface IERC165Base is IERC165, IERC165BaseInternal {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC165Internal } from '../../../interfaces/IERC165Internal.sol';

interface IERC165BaseInternal is IERC165Internal {
    error ERC165Base__InvalidInterfaceId();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721 } from '../../../interfaces/IERC721.sol';
import { IERC721Base } from './IERC721Base.sol';
import { ERC721BaseInternal } from './ERC721BaseInternal.sol';

/**
 * @title Base ERC721 implementation, excluding optional extensions
 */
abstract contract ERC721Base is IERC721Base, ERC721BaseInternal {
    /**
     * @inheritdoc IERC721
     */
    function balanceOf(address account) external view returns (uint256) {
        return _balanceOf(account);
    }

    /**
     * @inheritdoc IERC721
     */
    function ownerOf(uint256 tokenId) external view returns (address) {
        return _ownerOf(tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function getApproved(uint256 tokenId) external view returns (address) {
        return _getApproved(tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool) {
        return _isApprovedForAll(account, operator);
    }

    /**
     * @inheritdoc IERC721
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable {
        _transferFrom(from, to, tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable {
        _safeTransferFrom(from, to, tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external payable {
        _safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @inheritdoc IERC721
     */
    function approve(address operator, uint256 tokenId) external payable {
        _approve(operator, tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function setApprovalForAll(address operator, bool status) external {
        _setApprovalForAll(operator, status);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721Receiver } from '../../../interfaces/IERC721Receiver.sol';
import { EnumerableMap } from '../../../data/EnumerableMap.sol';
import { EnumerableSet } from '../../../data/EnumerableSet.sol';
import { AddressUtils } from '../../../utils/AddressUtils.sol';
import { IERC721BaseInternal } from './IERC721BaseInternal.sol';
import { ERC721BaseStorage } from './ERC721BaseStorage.sol';

/**
 * @title Base ERC721 internal functions
 */
abstract contract ERC721BaseInternal is IERC721BaseInternal {
    using AddressUtils for address;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using EnumerableSet for EnumerableSet.UintSet;

    function _balanceOf(
        address account
    ) internal view virtual returns (uint256) {
        if (account == address(0)) revert ERC721Base__BalanceQueryZeroAddress();
        return ERC721BaseStorage.layout().holderTokens[account].length();
    }

    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        address owner = ERC721BaseStorage.layout().tokenOwners.get(tokenId);
        if (owner == address(0)) revert ERC721Base__InvalidOwner();
        return owner;
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return ERC721BaseStorage.layout().tokenOwners.contains(tokenId);
    }

    function _getApproved(
        uint256 tokenId
    ) internal view virtual returns (address) {
        if (!_exists(tokenId)) revert ERC721Base__NonExistentToken();

        return ERC721BaseStorage.layout().tokenApprovals[tokenId];
    }

    function _isApprovedForAll(
        address account,
        address operator
    ) internal view virtual returns (bool) {
        return ERC721BaseStorage.layout().operatorApprovals[account][operator];
    }

    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view virtual returns (bool) {
        if (!_exists(tokenId)) revert ERC721Base__NonExistentToken();

        address owner = _ownerOf(tokenId);

        return (spender == owner ||
            _getApproved(tokenId) == spender ||
            _isApprovedForAll(owner, spender));
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        if (to == address(0)) revert ERC721Base__MintToZeroAddress();
        if (_exists(tokenId)) revert ERC721Base__TokenAlreadyMinted();

        _beforeTokenTransfer(address(0), to, tokenId);

        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();

        l.holderTokens[to].add(tokenId);
        l.tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, '');
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        if (!_checkOnERC721Received(address(0), to, tokenId, data))
            revert ERC721Base__ERC721ReceiverNotImplemented();
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = _ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();

        l.holderTokens[owner].remove(tokenId);
        l.tokenOwners.remove(tokenId);

        l.tokenApprovals[tokenId] = address(0);

        emit Approval(owner, address(0), tokenId);
        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        address owner = _ownerOf(tokenId);

        if (owner != from) revert ERC721Base__NotTokenOwner();
        if (to == address(0)) revert ERC721Base__TransferToZeroAddress();

        _beforeTokenTransfer(from, to, tokenId);

        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();

        l.holderTokens[from].remove(tokenId);
        l.holderTokens[to].add(tokenId);
        l.tokenOwners.set(tokenId, to);
        l.tokenApprovals[tokenId] = address(0);

        emit Approval(owner, address(0), tokenId);
        emit Transfer(from, to, tokenId);
    }

    function _transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        _handleTransferMessageValue(from, to, tokenId, msg.value);
        if (!_isApprovedOrOwner(msg.sender, tokenId))
            revert ERC721Base__NotOwnerOrApproved();
        _transfer(from, to, tokenId);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, data))
            revert ERC721Base__ERC721ReceiverNotImplemented();
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        _safeTransferFrom(from, to, tokenId, '');
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _handleTransferMessageValue(from, to, tokenId, msg.value);
        if (!_isApprovedOrOwner(msg.sender, tokenId))
            revert ERC721Base__NotOwnerOrApproved();
        _safeTransfer(from, to, tokenId, data);
    }

    function _approve(address operator, uint256 tokenId) internal virtual {
        _handleApproveMessageValue(operator, tokenId, msg.value);

        address owner = _ownerOf(tokenId);

        if (operator == owner) revert ERC721Base__SelfApproval();
        if (msg.sender != owner && !_isApprovedForAll(owner, msg.sender))
            revert ERC721Base__NotOwnerOrApproved();

        ERC721BaseStorage.layout().tokenApprovals[tokenId] = operator;
        emit Approval(owner, operator, tokenId);
    }

    function _setApprovalForAll(
        address operator,
        bool status
    ) internal virtual {
        if (operator == msg.sender) revert ERC721Base__SelfApproval();
        ERC721BaseStorage.layout().operatorApprovals[msg.sender][
            operator
        ] = status;
        emit ApprovalForAll(msg.sender, operator, status);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual returns (bool) {
        if (!to.isContract()) {
            return true;
        }

        bytes memory returnData = to.functionCall(
            abi.encodeWithSelector(
                IERC721Receiver(to).onERC721Received.selector,
                msg.sender,
                from,
                tokenId,
                data
            ),
            'ERC721: transfer to non ERC721Receiver implementer'
        );

        bytes4 returnValue = abi.decode(returnData, (bytes4));
        return returnValue == type(IERC721Receiver).interfaceId;
    }

    /**
     * @notice ERC721 hook, called before externally called approvals for processing of included message value
     * @param operator beneficiary of approval
     * @param tokenId id of transferred token
     * @param value message value
     */
    function _handleApproveMessageValue(
        address operator,
        uint256 tokenId,
        uint256 value
    ) internal virtual {}

    /**
     * @notice ERC721 hook, called before externally called transfers for processing of included message value
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId id of transferred token
     * @param value message value
     */
    function _handleTransferMessageValue(
        address from,
        address to,
        uint256 tokenId,
        uint256 value
    ) internal virtual {}

    /**
     * @notice ERC721 hook, called before all transfers including mint and burn
     * @dev function should be overridden and new implementation must call super
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId id of transferred token
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { EnumerableMap } from '../../../data/EnumerableMap.sol';
import { EnumerableSet } from '../../../data/EnumerableSet.sol';

library ERC721BaseStorage {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC721Base');

    struct Layout {
        EnumerableMap.UintToAddressMap tokenOwners;
        mapping(address => EnumerableSet.UintSet) holderTokens;
        mapping(uint256 => address) tokenApprovals;
        mapping(address => mapping(address => bool)) operatorApprovals;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721 } from '../../../interfaces/IERC721.sol';
import { IERC721BaseInternal } from './IERC721BaseInternal.sol';

/**
 * @title ERC721 base interface
 */
interface IERC721Base is IERC721BaseInternal, IERC721 {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721Internal } from '../../../interfaces/IERC721Internal.sol';

/**
 * @title ERC721 base interface
 */
interface IERC721BaseInternal is IERC721Internal {
    error ERC721Base__NotOwnerOrApproved();
    error ERC721Base__SelfApproval();
    error ERC721Base__BalanceQueryZeroAddress();
    error ERC721Base__ERC721ReceiverNotImplemented();
    error ERC721Base__InvalidOwner();
    error ERC721Base__MintToZeroAddress();
    error ERC721Base__NonExistentToken();
    error ERC721Base__NotTokenOwner();
    error ERC721Base__TokenAlreadyMinted();
    error ERC721Base__TransferToZeroAddress();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { EnumerableMap } from '../../../data/EnumerableMap.sol';
import { EnumerableSet } from '../../../data/EnumerableSet.sol';
import { ERC721BaseStorage } from '../base/ERC721BaseStorage.sol';
import { IERC721Enumerable } from './IERC721Enumerable.sol';
import { ERC721EnumerableInternal } from './ERC721EnumerableInternal.sol';

abstract contract ERC721Enumerable is
    IERC721Enumerable,
    ERC721EnumerableInternal
{
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @inheritdoc IERC721Enumerable
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply();
    }

    /**
     * @inheritdoc IERC721Enumerable
     */
    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) public view returns (uint256) {
        return _tokenOfOwnerByIndex(owner, index);
    }

    /**
     * @inheritdoc IERC721Enumerable
     */
    function tokenByIndex(uint256 index) public view returns (uint256) {
        return _tokenByIndex(index);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { EnumerableMap } from '../../../data/EnumerableMap.sol';
import { EnumerableSet } from '../../../data/EnumerableSet.sol';
import { ERC721BaseStorage } from '../base/ERC721BaseStorage.sol';

abstract contract ERC721EnumerableInternal {
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @notice TODO
     */
    function _totalSupply() internal view returns (uint256) {
        return ERC721BaseStorage.layout().tokenOwners.length();
    }

    /**
     * @notice TODO
     */
    function _tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) internal view returns (uint256) {
        return ERC721BaseStorage.layout().holderTokens[owner].at(index);
    }

    /**
     * @notice TODO
     */
    function _tokenByIndex(
        uint256 index
    ) internal view returns (uint256 tokenId) {
        (tokenId, ) = ERC721BaseStorage.layout().tokenOwners.at(index);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

interface IERC721Enumerable {
    /**
     * @notice get total token supply
     * @return total supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice get token of given owner at given internal storage index
     * @param owner token holder to query
     * @param index position in owner's token list to query
     * @return tokenId id of retrieved token
     */
    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) external view returns (uint256 tokenId);

    /**
     * @notice get token at given internal storage index
     * @param index position in global token list to query
     * @return tokenId id of retrieved token
     */
    function tokenByIndex(
        uint256 index
    ) external view returns (uint256 tokenId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721Base } from './base/IERC721Base.sol';
import { IERC721Enumerable } from './enumerable/IERC721Enumerable.sol';
import { IERC721Metadata } from './metadata/IERC721Metadata.sol';

interface ISolidStateERC721 is IERC721Base, IERC721Enumerable, IERC721Metadata {
    error SolidStateERC721__PayableApproveNotSupported();
    error SolidStateERC721__PayableTransferNotSupported();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { ERC721MetadataInternal } from './ERC721MetadataInternal.sol';
import { IERC721Metadata } from './IERC721Metadata.sol';

/**
 * @title ERC721 metadata extensions
 */
abstract contract ERC721Metadata is IERC721Metadata, ERC721MetadataInternal {
    /**
     * @notice inheritdoc IERC721Metadata
     */
    function name() external view virtual returns (string memory) {
        return _name();
    }

    /**
     * @notice inheritdoc IERC721Metadata
     */
    function symbol() external view virtual returns (string memory) {
        return _symbol();
    }

    /**
     * @notice inheritdoc IERC721Metadata
     */
    function tokenURI(
        uint256 tokenId
    ) external view virtual returns (string memory) {
        return _tokenURI(tokenId);
    }

    /**
     * @inheritdoc ERC721MetadataInternal
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { UintUtils } from '../../../utils/UintUtils.sol';
import { ERC721BaseStorage } from '../base/ERC721BaseStorage.sol';
import { ERC721BaseInternal } from '../base/ERC721Base.sol';
import { IERC721MetadataInternal } from './IERC721MetadataInternal.sol';
import { ERC721MetadataStorage } from './ERC721MetadataStorage.sol';
import { ERC721MetadataInternal } from './ERC721MetadataInternal.sol';

/**
 * @title ERC721Metadata internal functions
 */
abstract contract ERC721MetadataInternal is
    IERC721MetadataInternal,
    ERC721BaseInternal
{
    using UintUtils for uint256;

    /**
     * @notice get token name
     * @return token name
     */
    function _name() internal view virtual returns (string memory) {
        return ERC721MetadataStorage.layout().name;
    }

    /**
     * @notice get token symbol
     * @return token symbol
     */
    function _symbol() internal view virtual returns (string memory) {
        return ERC721MetadataStorage.layout().symbol;
    }

    /**
     * @notice get generated URI for given token
     * @return token URI
     */
    function _tokenURI(
        uint256 tokenId
    ) internal view virtual returns (string memory) {
        if (!_exists(tokenId)) revert ERC721Metadata__NonExistentToken();

        ERC721MetadataStorage.Layout storage l = ERC721MetadataStorage.layout();

        string memory tokenIdURI = l.tokenURIs[tokenId];
        string memory baseURI = l.baseURI;

        if (bytes(baseURI).length == 0) {
            return tokenIdURI;
        } else if (bytes(tokenIdURI).length > 0) {
            return string(abi.encodePacked(baseURI, tokenIdURI));
        } else {
            return string(abi.encodePacked(baseURI, tokenId.toString()));
        }
    }

    /**
     * @notice ERC721 hook: clear per-token URI data on burn
     * @inheritdoc ERC721BaseInternal
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (to == address(0)) {
            delete ERC721MetadataStorage.layout().tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ERC721MetadataStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC721Metadata');

    struct Layout {
        string name;
        string symbol;
        string baseURI;
        mapping(uint256 => string) tokenURIs;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721MetadataInternal } from './IERC721MetadataInternal.sol';

/**
 * @title ERC721Metadata interface
 */
interface IERC721Metadata is IERC721MetadataInternal {
    /**
     * @notice get token name
     * @return token name
     */
    function name() external view returns (string memory);

    /**
     * @notice get token symbol
     * @return token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @notice get generated URI for given token
     * @return token URI
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721BaseInternal } from '../base/IERC721BaseInternal.sol';

/**
 * @title ERC721Metadata internal interface
 */
interface IERC721MetadataInternal is IERC721BaseInternal {
    error ERC721Metadata__NonExistentToken();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { ERC165Base } from '../../introspection/ERC165/base/ERC165Base.sol';
import { ERC721Base, ERC721BaseInternal } from './base/ERC721Base.sol';
import { ERC721Enumerable } from './enumerable/ERC721Enumerable.sol';
import { ERC721Metadata } from './metadata/ERC721Metadata.sol';
import { ISolidStateERC721 } from './ISolidStateERC721.sol';

/**
 * @title SolidState ERC721 implementation, including recommended extensions
 */
abstract contract SolidStateERC721 is
    ISolidStateERC721,
    ERC721Base,
    ERC721Enumerable,
    ERC721Metadata,
    ERC165Base
{
    /**
     * @notice ERC721 hook: revert if value is included in external approve function call
     * @inheritdoc ERC721BaseInternal
     */
    function _handleApproveMessageValue(
        address operator,
        uint256 tokenId,
        uint256 value
    ) internal virtual override {
        if (value > 0) revert SolidStateERC721__PayableApproveNotSupported();
        super._handleApproveMessageValue(operator, tokenId, value);
    }

    /**
     * @notice ERC721 hook: revert if value is included in external transfer function call
     * @inheritdoc ERC721BaseInternal
     */
    function _handleTransferMessageValue(
        address from,
        address to,
        uint256 tokenId,
        uint256 value
    ) internal virtual override {
        if (value > 0) revert SolidStateERC721__PayableTransferNotSupported();
        super._handleTransferMessageValue(from, to, tokenId, value);
    }

    /**
     * @inheritdoc ERC721BaseInternal
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721BaseInternal, ERC721Metadata) {
        super._beforeTokenTransfer(from, to, tokenId);
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

    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
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

    /**
     * @notice execute arbitrary external call with limited gas usage and amount of copied return data
     * @dev derived from https://github.com/nomad-xyz/ExcessivelySafeCall (MIT License)
     * @param target recipient of call
     * @param gasAmount gas allowance for call
     * @param value native token value to include in call
     * @param maxCopy maximum number of bytes to copy from return data
     * @param data encoded call data
     * @return success whether call is successful
     * @return returnData copied return data
     */
    function excessivelySafeCall(
        address target,
        uint256 gasAmount,
        uint256 value,
        uint16 maxCopy,
        bytes memory data
    ) internal returns (bool success, bytes memory returnData) {
        returnData = new bytes(maxCopy);

        assembly {
            // execute external call via assembly to avoid automatic copying of return data
            success := call(
                gasAmount,
                target,
                value,
                add(data, 0x20),
                mload(data),
                0,
                0
            )

            // determine whether to limit amount of data to copy
            let toCopy := returndatasize()

            if gt(toCopy, maxCopy) {
                toCopy := maxCopy
            }

            // store the length of the copied bytes
            mstore(returnData, toCopy)

            // copy the bytes from returndata[0:toCopy]
            returndatacopy(add(returnData, 0x20), 0, toCopy)
        }
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

library ArrayUtils {
    /**
     * @notice get minimum value in given array
     * @param array array to search
     * @return minimum value
     */
    function min(bytes32[] memory array) internal pure returns (bytes32) {
        bytes32 minValue = bytes32(type(uint256).max);

        unchecked {
            for (uint256 i; i < array.length; i++) {
                if (array[i] < minValue) {
                    minValue = array[i];
                }
            }
        }

        return minValue;
    }

    /**
     * @notice get minimum value in given array
     * @param array array to search
     * @return minimum value
     */
    function min(address[] memory array) internal pure returns (address) {
        address minValue = address(type(uint160).max);

        unchecked {
            for (uint256 i; i < array.length; i++) {
                if (array[i] < minValue) {
                    minValue = array[i];
                }
            }
        }

        return minValue;
    }

    /**
     * @notice get minimum value in given array
     * @param array array to search
     * @return minimum value
     */
    function min(uint256[] memory array) internal pure returns (uint256) {
        uint256 minValue = type(uint256).max;

        unchecked {
            for (uint256 i; i < array.length; i++) {
                if (array[i] < minValue) {
                    minValue = array[i];
                }
            }
        }

        return minValue;
    }

    /**
     * @notice get maximum value in given array
     * @param array array to search
     * @return maximum value
     */
    function max(bytes32[] memory array) internal pure returns (bytes32) {
        bytes32 maxValue = bytes32(0);

        unchecked {
            for (uint256 i; i < array.length; i++) {
                if (array[i] > maxValue) {
                    maxValue = array[i];
                }
            }
        }

        return maxValue;
    }

    /**
     * @notice get maximum value in given array
     * @param array array to search
     * @return maximum value
     */
    function max(address[] memory array) internal pure returns (address) {
        address maxValue = address(0);

        unchecked {
            for (uint256 i; i < array.length; i++) {
                if (array[i] > maxValue) {
                    maxValue = array[i];
                }
            }
        }

        return maxValue;
    }

    /**
     * @notice get maximum value in given array
     * @param array array to search
     * @return maximum value
     */
    function max(uint256[] memory array) internal pure returns (uint256) {
        uint256 maxValue = 0;

        unchecked {
            for (uint256 i; i < array.length; i++) {
                if (array[i] > maxValue) {
                    maxValue = array[i];
                }
            }
        }

        return maxValue;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Interface for the Multicall utility contract
 */
interface IMulticall {
    /**
     * @notice batch function calls to the contract and return the results of each
     * @param data array of function call data payloads
     * @return results array of function call results
     */
    function multicall(
        bytes[] calldata data
    ) external returns (bytes[] memory results);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IMulticall } from './IMulticall.sol';

/**
 * @title Utility contract for supporting processing of multiple function calls in a single transaction
 */
abstract contract Multicall is IMulticall {
    /**
     * @inheritdoc IMulticall
     */
    function multicall(
        bytes[] calldata data
    ) external returns (bytes[] memory results) {
        results = new bytes[](data.length);

        unchecked {
            for (uint256 i; i < data.length; i++) {
                (bool success, bytes memory returndata) = address(this)
                    .delegatecall(data[i]);

                if (success) {
                    results[i] = returndata;
                } else {
                    assembly {
                        returndatacopy(0, 0, returndatasize())
                        revert(0, returndatasize())
                    }
                }
            }
        }

        return results;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { ReentrancyGuardStorage } from './ReentrancyGuardStorage.sol';

/**
 * @title Utility contract for preventing reentrancy attacks
 */
abstract contract ReentrancyGuard {
    error ReentrancyGuard__ReentrantCall();

    modifier nonReentrant() {
        ReentrancyGuardStorage.Layout storage l = ReentrancyGuardStorage
            .layout();
        if (l.status == 2) revert ReentrancyGuard__ReentrantCall();
        l.status = 2;
        _;
        l.status = 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ReentrancyGuardStorage {
    struct Layout {
        uint256 status;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ReentrancyGuard');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
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

    function toHexString(
        uint256 value,
        uint256 length
    ) internal pure returns (string memory) {
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

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.19;

import { ERC721BaseInternal } from "@solidstate/contracts/token/ERC721/base/ERC721BaseInternal.sol";
import { ERC721Metadata } from "@solidstate/contracts/token/ERC721/metadata/ERC721Metadata.sol";
import { ISolidStateERC721 } from "@solidstate/contracts/token/ERC721/ISolidStateERC721.sol";
import { SolidStateERC721 } from "@solidstate/contracts/token/ERC721/SolidStateERC721.sol";
import { ERC721Base } from "@solidstate/contracts/token/ERC721/base/ERC721Base.sol";
import { IERC721 } from '@solidstate/contracts/interfaces/IERC721.sol';
import { IERC721Metadata } from "@solidstate/contracts/token/ERC721/metadata/IERC721Metadata.sol";
import { ArcadiansInternal } from "./ArcadiansInternal.sol";
import { ArcadiansStorage } from "./ArcadiansStorage.sol";
import { EnumerableMap } from '@solidstate/contracts/data/EnumerableMap.sol';
import { Multicall } from "@solidstate/contracts/utils/Multicall.sol";
import { InventoryStorage } from "../inventory/InventoryStorage.sol";
import { WhitelistStorage } from "../whitelist/WhitelistStorage.sol";

/**
 * @title ArcadiansFacet
 * @notice This contract is an ERC721 responsible for minting and claiming Arcadian tokens.
 * @dev ReentrancyGuard and Multicall contracts are used for security and gas efficiency.
 */
contract ArcadiansFacet is SolidStateERC721, ArcadiansInternal, Multicall {
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    WhitelistStorage.PoolId constant GuaranteedPool = WhitelistStorage.PoolId.Guaranteed;
    WhitelistStorage.PoolId constant RestrictedPool = WhitelistStorage.PoolId.Restricted;

    /**
     * @notice Returns the URI for a given arcadian
     * @param tokenId ID of the token to query
     * @return The URI for the given token ID
     */
    function tokenURI(
        uint tokenId
    ) external view override (ERC721Metadata, IERC721Metadata) returns (string memory) {
        return _tokenURI(tokenId);
    }

    function _mint() internal returns (uint tokenId) {
        ArcadiansStorage.Layout storage arcadiansSL = ArcadiansStorage.layout();

        tokenId = nextArcadianId();

        if (tokenId > arcadiansSL.arcadiansMaxSupply)
            revert Arcadians_MaximumArcadiansSupplyReached();

        uint nonGuaranteedMintedAmount = _claimedWhitelist(RestrictedPool, msg.sender) + _claimedMintPass(msg.sender) + arcadiansSL.userPublicMints[msg.sender];

        if (_isWhitelistClaimActive(GuaranteedPool) && _elegibleWhitelist(GuaranteedPool, msg.sender) > 0) {
            // OG mint flow
            _consumeWhitelist(GuaranteedPool, msg.sender, 1);
        } else if (nonGuaranteedMintedAmount < arcadiansSL.maxMintPerUser) {

            if (_isMintPassClaimActive() && _elegibleMintPass(msg.sender) > 0) {
                // Magic Eden mint flow
                _consumeMintPass(msg.sender);
            } else if (_isWhitelistClaimActive(RestrictedPool) && _elegibleWhitelist(RestrictedPool, msg.sender) > 0) { 
                // Whitelist mint flow
                _consumeWhitelist(RestrictedPool, msg.sender, 1);

            } else if (arcadiansSL.isPublicMintOpen) {
                if (msg.value != arcadiansSL.mintPrice)
                    revert Arcadians_InvalidPayAmount();
                arcadiansSL.userPublicMints[msg.sender]++;
            } else {
                revert Arcadians_NotElegibleToMint();
            }
        } else {
            revert Arcadians_NotElegibleToMint();
        }

        _safeMint(msg.sender, tokenId);
    }

    /**
     * @notice Returns the amount of arcadians that can be minted by an account
     * @param account account to query
     * @return balance amount of arcadians that can be minted
     */
    function availableMints(address account) external view returns (uint balance) {
        ArcadiansStorage.Layout storage arcadiansSL = ArcadiansStorage.layout();

        uint totalSupply = totalSupply();
        uint arcadiansMaxSupply = arcadiansSL.arcadiansMaxSupply;
        if (totalSupply >= arcadiansMaxSupply) {
            return 0;
        }

        uint mintPerUserMax = arcadiansSL.maxMintPerUser;
        uint nonGuaranteedAvailableMints;
        if (_isWhitelistClaimActive(RestrictedPool)) {
            nonGuaranteedAvailableMints += _elegibleWhitelist(RestrictedPool, account);
        } 
        if (_isMintPassClaimActive()) {
            nonGuaranteedAvailableMints += _elegibleMintPass(account);
        }
        if (arcadiansSL.isPublicMintOpen) {
            nonGuaranteedAvailableMints += mintPerUserMax - arcadiansSL.userPublicMints[account];
        }
        uint nonGuaranteedMintedAmount = _claimedWhitelist(RestrictedPool, account) + _claimedMintPass(account) + arcadiansSL.userPublicMints[account];

        if (nonGuaranteedMintedAmount >= mintPerUserMax) {
            nonGuaranteedAvailableMints = 0;
        } else  {
            uint ceil = mintPerUserMax - nonGuaranteedMintedAmount;
            nonGuaranteedAvailableMints = nonGuaranteedAvailableMints > ceil ? ceil : nonGuaranteedAvailableMints;
        }

        uint guaranteedAvailableMints;
        if (_isWhitelistClaimActive(GuaranteedPool)) {
            guaranteedAvailableMints += _elegibleWhitelist(GuaranteedPool, account);
        }

        uint availableAmount = guaranteedAvailableMints + nonGuaranteedAvailableMints;

        if (totalSupply + availableAmount > arcadiansMaxSupply) {
            return arcadiansMaxSupply - totalSupply;
        }

        return availableAmount;
    }

    /**
     * @notice Returns the total amount of arcadians minted
     * @return uint total amount of arcadians minted
     */
    function totalMinted() external view returns (uint) {
        return _totalSupply();
    }

   /**
     * @notice Mint a token and equip it with the given items
     * @param itemsToEquip array of items to equip in the correspondent slot
     */
    function mintAndEquip(
        InventoryStorage.Item[] calldata itemsToEquip
    )
        external payable nonReentrant
    {
        uint tokenId = _mint();
        _equip(tokenId, itemsToEquip, true);
    }

    /**
     * @notice This function sets the public mint as open/closed
     */
    function setPublicMintOpen(bool isOpen) external onlyManager {
        ArcadiansStorage.Layout storage arcadiansSL = ArcadiansStorage.layout();
        arcadiansSL.isPublicMintOpen = isOpen;
    }
    /**
     * @notice Returns true if the public mint is open, false otherwise
     */
    function publicMintOpen() external view returns (bool) {
        return ArcadiansStorage.layout().isPublicMintOpen;
    }

    /**
     * @notice This function updates the price to mint an arcadian
     * @param newMintPrice The new mint price to be set
     */
    function setMintPrice(uint newMintPrice) external onlyManager {
        _setMintPrice(newMintPrice);
    }

    /**
     * @notice This function gets the current price to mint an arcadian
     * @return The current mint price
     */
    function mintPrice() external view returns (uint) {
        return _mintPrice();
    }

    /**
     * @notice This function sets the new maximum number of arcadians that a user can mint
     * @param newMaxMintPerUser The new maximum number of arcadians that a user can mint
     */
    function setMaxMintPerUser(uint newMaxMintPerUser) external onlyManager {
        _setMaxMintPerUser(newMaxMintPerUser);
    }

    /**
     * @dev This function gets the current maximum number of arcadians that a user can mint
     * @return The current maximum number of arcadians that a user can mint
     */
    function maxMintPerUser() external view returns (uint) {
        return _maxMintPerUser();
    }

    /**
     * @dev This function returns the maximum supply of arcadians
     * @return The current maximum supply of arcadians
     */
    function maxSupply() external view returns (uint) {
        return ArcadiansStorage.layout().arcadiansMaxSupply;
    }

    /**
     * @notice Sets the max arcadians supply
     * @param maxArcadiansSupply The max supply of arcadians that can be minted
     */
    function setMaxSupply(uint maxArcadiansSupply) external onlyManager {
        _setMaxSupply(maxArcadiansSupply);
    }

    /**
     * @notice Set the base URI for all Arcadians metadata
     * @notice Only the manager role can call this function
     * @param newBaseURI The new base URI for all token metadata
     */
    function setBaseURI(string memory newBaseURI) external onlyManager {
        _setBaseURI(newBaseURI);
    }

    /**
     * @dev This function returns the base URI
     * @return The base URI
     */
    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    function nextArcadianId() internal view returns (uint arcadianId) {
        arcadianId = _totalSupply() + 1;
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.19;

import { RolesInternal } from "../roles/RolesInternal.sol";
import { ArcadiansInternal } from "./ArcadiansInternal.sol";
import { IERC721 } from '@solidstate/contracts/interfaces/IERC721.sol';
import { ERC165BaseInternal } from '@solidstate/contracts/introspection/ERC165/base/ERC165BaseInternal.sol';

contract ArcadiansInit is RolesInternal, ArcadiansInternal, ERC165BaseInternal {
    function init(
        string calldata baseUri, 
        uint maxMintPerUser, 
        uint mintPrice, 
        address mintPassAddress, 
        uint arcadiansMaxSupply
    ) external {

        _setSupportsInterface(type(IERC721).interfaceId, true);

        // Roles facet
        _initRoles();

        // Arcadians facet
        _setBaseURI(baseUri);
        _setMaxMintPerUser(maxMintPerUser);
        _setMintPrice(mintPrice);
        _setMaxSupply(arcadiansMaxSupply);

        // Mint pass
        _setMintPassContractAddress(mintPassAddress);
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.19;

import { ERC721MetadataStorage } from "@solidstate/contracts/token/ERC721/metadata/ERC721MetadataStorage.sol";
import { UintUtils } from '@solidstate/contracts/utils/UintUtils.sol';
import { ArcadiansStorage } from "./ArcadiansStorage.sol";
import { RolesInternal } from "../roles/RolesInternal.sol";
import { WhitelistInternal } from "../whitelist/WhitelistInternal.sol";
import { WhitelistStorage } from "../whitelist/WhitelistStorage.sol";
import { InventoryInternal } from "../inventory/InventoryInternal.sol";
import { MintPassInternal } from "../mintPass/MintPassInternal.sol";

contract ArcadiansInternal is RolesInternal, WhitelistInternal, InventoryInternal, MintPassInternal {

    error Arcadians_InvalidPayAmount();
    error Arcadians_MaximumArcadiansSupplyReached();
    error Arcadians_NotElegibleToMint();

    event MaxMintPerUserChanged(address indexed by, uint oldMaxMintPerUser, uint newMaxMintPerUser);
    event MintPriceChanged(address indexed by, uint oldMintPrice, uint newMintPrice);
    event BaseURIChanged(address indexed by, string oldBaseURI, string newBaseURI);

    using UintUtils for uint;

    function _setBaseURI(string memory newBaseURI) internal {
        ERC721MetadataStorage.Layout storage ERC721SL = ERC721MetadataStorage.layout();
        emit BaseURIChanged(msg.sender, ERC721SL.baseURI, newBaseURI);
        ERC721SL.baseURI = newBaseURI;
    }

    function _baseURI() internal view returns (string memory) {
        return ERC721MetadataStorage.layout().baseURI;
    }

    function _mintPrice() internal view returns (uint) {
        return ArcadiansStorage.layout().mintPrice;
    }

    function _setMintPrice(uint newMintPrice) internal {
        ArcadiansStorage.Layout storage arcadiansSL = ArcadiansStorage.layout();
        emit MintPriceChanged(msg.sender, arcadiansSL.mintPrice, newMintPrice);
        arcadiansSL.mintPrice = newMintPrice;
    }

    function _setMaxMintPerUser(uint newMaxMintPerUser) internal {
        ArcadiansStorage.Layout storage arcadiansSL = ArcadiansStorage.layout();
        emit MaxMintPerUserChanged(msg.sender, arcadiansSL.maxMintPerUser, newMaxMintPerUser);
        arcadiansSL.maxMintPerUser = newMaxMintPerUser;
    }

    function _maxMintPerUser() internal view returns (uint) {
        return ArcadiansStorage.layout().maxMintPerUser;
    }

    function _setMaxSupply(uint arcadiansMaxSupply) internal {
        ArcadiansStorage.Layout storage arcadiansSL = ArcadiansStorage.layout();
        
        arcadiansSL.arcadiansMaxSupply = arcadiansMaxSupply;
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.19;

library ArcadiansStorage {

    bytes32 constant ARCADIANS_STORAGE_POSITION =
        keccak256("equippable.storage.position");

    struct Layout {
        uint maxMintPerUser;
        uint mintPrice;
        bool isPublicMintOpen;
        // account => amount minted with public mint
        mapping(address => uint) userPublicMints;
        uint arcadiansMaxSupply;
    }

    function layout()
        internal
        pure
        returns (Layout storage es)
    {
        bytes32 position = ARCADIANS_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.19;

import { ReentrancyGuard } from "@solidstate/contracts/utils/ReentrancyGuard.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { AddressUtils } from "@solidstate/contracts/utils/AddressUtils.sol";
import { ArrayUtils } from "@solidstate/contracts/utils/ArrayUtils.sol";
import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";
import { RolesInternal } from "../roles/RolesInternal.sol";
import { InventoryStorage } from "./InventoryStorage.sol";
import { IERC1155 } from "@solidstate/contracts/interfaces/IERC1155.sol";

contract InventoryInternal is
    ReentrancyGuard,
    RolesInternal
{
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using AddressUtils for address;

    error Inventory_InvalidERC1155Contract();
    error Inventory_UnequippingPermanentSlot();
    error Inventory_InvalidSlotId();
    error Inventory_ItemDoesNotHaveSlotAssigned();
    error Inventory_InsufficientItemBalance();
    error Inventory_UnequippingEmptySlot();
    error Inventory_UnequippingBaseSlot();
    error Inventory_NotArcadianOwner();
    error Inventory_ArcadianNotUnique();
    error Inventory_NotAllBaseSlotsEquipped();
    error Inventory_InputDataMismatch();
    error Inventory_ItemAlreadyEquippedInSlot();
    error Inventory_CouponNeededToModifyBaseSlots();
    error Inventory_NonBaseSlot();

    event ItemsAllowedInSlotUpdated(
        address indexed by,
        InventoryStorage.Item[] items
    );

    event ItemsEquipped(
        address indexed by,
        uint indexed arcadianId,
        uint8[] slots
    );

    event ItemsUnequipped(
        address indexed by,
        uint indexed arcadianId,
        uint8[] slotsIds
    );

    event SlotCreated(
        address indexed by,
        uint8 indexed slotId,
        bool permanent,
        bool isBase
    );

    event BaseModifierCouponAdded(
        address indexed by,
        address indexed to,
        uint8[] slotsIds,
        uint[] amounts
    );

    event BaseModifierCouponConsumed(
        address indexed account,
        uint indexed arcadianId,
        uint8[] slotsIds
    );

    // Helper structs only used in view functions to ease data reading from web3
    struct ItemInSlot {
        uint8 slotId;
        address erc1155Contract;
        uint itemId;
    }
    struct BaseModifierCoupon {
        uint8 slotId;
        uint amount;
    }

    modifier onlyValidSlot(uint8 slotId) {
        if (slotId == 0 || slotId > InventoryStorage.layout().numSlots) revert Inventory_InvalidSlotId();
        _;
    }

    modifier onlyArcadianOwner(uint arcadianId) {
        IERC721 arcadiansContract = IERC721(address(this));
        if (msg.sender != arcadiansContract.ownerOf(arcadianId)) revert Inventory_NotArcadianOwner();
        _;
    }

    function _numSlots() internal view returns (uint) {
        return InventoryStorage.layout().numSlots;
    }

    function _equip(
        uint arcadianId,
        InventoryStorage.Item[] calldata items,
        bool freeBaseModifier
    ) internal onlyArcadianOwner(arcadianId) {

        if (items.length == 0) 
            return;

        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();
        uint8 numBaseSlotsModified;
        uint8[] memory slotsIds = new uint8[](items.length);
        for (uint i = 0; i < items.length; i++) {
            uint8 slotId = inventorySL.itemSlot[items[i].erc1155Contract][items[i].id];
            slotsIds[i] = slotId;

            InventoryStorage.Item storage existingItem = inventorySL.equippedItems[arcadianId][slotId];
            if (existingItem.erc1155Contract == items[i].erc1155Contract && existingItem.id == items[i].id) {
                continue;
            }

            _equipSingleSlot(arcadianId, items[i], freeBaseModifier);
            if (inventorySL.slots[slotId].isBase) {
                numBaseSlotsModified++;
            }
        }

        if (!_baseAndPermanentSlotsEquipped(arcadianId)) 
            revert Inventory_NotAllBaseSlotsEquipped();

        if (numBaseSlotsModified > 0) {
            if (!_hashBaseItemsUnchecked(arcadianId))
                revert Inventory_ArcadianNotUnique();

            if (!freeBaseModifier) {
                uint8[] memory baseSlotsModified = new uint8[](numBaseSlotsModified);
                uint counter;
                for (uint i = 0; i < items.length; i++) {
                    uint8 slotId = inventorySL.itemSlot[items[i].erc1155Contract][items[i].id];
                    if (inventorySL.slots[slotId].isBase) {
                        baseSlotsModified[counter] = slotId;
                        counter++;
                    }
                }
                emit BaseModifierCouponConsumed(msg.sender, arcadianId, baseSlotsModified);
            }
        }

        emit ItemsEquipped(msg.sender, arcadianId, slotsIds);
    }

    function _equipSingleSlot(
        uint arcadianId,
        InventoryStorage.Item calldata item,
        bool freeBaseModifier
    ) internal returns (uint8 slotId) {

        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();
        slotId = inventorySL.itemSlot[item.erc1155Contract][item.id];
        
        if (slotId == 0 || slotId > InventoryStorage.layout().numSlots) 
            revert Inventory_ItemDoesNotHaveSlotAssigned();
        
        if (!freeBaseModifier && inventorySL.slots[slotId].isBase) {
            if (inventorySL.baseModifierCoupon[msg.sender][slotId] == 0)
                revert Inventory_CouponNeededToModifyBaseSlots();

            inventorySL.baseModifierCoupon[msg.sender][slotId]--;
        }

        InventoryStorage.Item storage existingItem = inventorySL.equippedItems[arcadianId][slotId];
        if (inventorySL.slots[slotId].permanent && existingItem.erc1155Contract != address(0)) 
            revert Inventory_UnequippingPermanentSlot();

        if (inventorySL.equippedItems[arcadianId][slotId].erc1155Contract != address(0))
            _unequipUnchecked(arcadianId, slotId);

        bool requiresTransfer = inventorySL.requiresTransfer[item.erc1155Contract][item.id];
        if (requiresTransfer) {
            IERC1155 erc1155Contract = IERC1155(item.erc1155Contract);
            if (erc1155Contract.balanceOf(msg.sender, item.id) < 1)
                revert Inventory_InsufficientItemBalance();

            erc1155Contract.safeTransferFrom(
                msg.sender,
                address(this),
                item.id,
                1,
                ''
            );
        }

        inventorySL.equippedItems[arcadianId][slotId] = item;
    }

    function _baseAndPermanentSlotsEquipped(uint arcadianId) internal view returns (bool) {
        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();
        uint8 numSlots = inventorySL.numSlots;
        for (uint8 i = 0; i < numSlots; i++) {
            uint8 slotId = i + 1;
            InventoryStorage.Slot storage slot = inventorySL.slots[slotId];
            if (!slot.isBase && !slot.permanent)
                continue;
            if (inventorySL.equippedItems[arcadianId][slotId].erc1155Contract == address(0)) {
                return false;
            }
        }
        return true;
    }

    function _unequipUnchecked(
        uint arcadianId,
        uint8 slotId
    ) internal {
        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();
        InventoryStorage.Item storage existingItem = inventorySL.equippedItems[arcadianId][slotId];

        bool requiresTransfer = inventorySL.requiresTransfer[existingItem.erc1155Contract][existingItem.id];
        if (requiresTransfer) {
            IERC1155 erc1155Contract = IERC1155(existingItem.erc1155Contract);
            erc1155Contract.safeTransferFrom(
                address(this),
                msg.sender,
                existingItem.id,
                1,
                ''
            );
        }
        delete inventorySL.equippedItems[arcadianId][slotId];
    }

    function _unequip(
        uint arcadianId,
        uint8[] calldata slotsIds
    ) internal onlyArcadianOwner(arcadianId) {
        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();

        if (slotsIds.length == 0) 
            return;

        for (uint i = 0; i < slotsIds.length; i++) {
            if (inventorySL.slots[slotsIds[i]].permanent) 
                revert Inventory_UnequippingPermanentSlot();

            if (inventorySL.equippedItems[arcadianId][slotsIds[i]].erc1155Contract == address(0)) 
                revert Inventory_UnequippingEmptySlot();
            
            if (inventorySL.slots[slotsIds[i]].isBase)
                revert Inventory_UnequippingBaseSlot();

            _unequipUnchecked(arcadianId, slotsIds[i]);
        }

        _hashBaseItemsUnchecked(arcadianId);

        emit ItemsUnequipped(
            msg.sender,
            arcadianId,
            slotsIds
        );
    }

    function _equipped(
        uint arcadianId,
        uint8 slotId
    ) internal view returns (ItemInSlot memory) {
        InventoryStorage.Item storage item = InventoryStorage.layout().equippedItems[arcadianId][slotId];
        return ItemInSlot(slotId, item.erc1155Contract, item.id);
    }

    function _equippedBatch(
        uint arcadianId,
        uint8[] calldata slotsIds
    ) internal view returns (ItemInSlot[] memory equippedSlots) {
        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();
        equippedSlots = new ItemInSlot[](slotsIds.length);
        for (uint i = 0; i < slotsIds.length; i++) {
            InventoryStorage.Item storage equippedItem = inventorySL.equippedItems[arcadianId][slotsIds[i]];
            equippedSlots[i] = ItemInSlot(slotsIds[i], equippedItem.erc1155Contract, equippedItem.id);
        }
    }

    function _equippedAll(
        uint arcadianId
    ) internal view returns (ItemInSlot[] memory equippedSlots) {
        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();
        uint8 numSlots = inventorySL.numSlots;
        equippedSlots = new ItemInSlot[](numSlots);
        for (uint8 i = 0; i < numSlots; i++) {
            uint8 slotId = i + 1;
            InventoryStorage.Item storage equippedItem = inventorySL.equippedItems[arcadianId][slotId];
            equippedSlots[i] = ItemInSlot(slotId, equippedItem.erc1155Contract, equippedItem.id);
        }
    }

    function _isArcadianUnique(
        uint arcadianId,
        InventoryStorage.Item[] calldata items
    ) internal view returns (bool) {

        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();

        bytes memory encodedItems;
        uint numBaseSlots = inventorySL.baseSlotsIds.length;

        for (uint8 i = 0; i < numBaseSlots; i++) {
            uint8 slotId = inventorySL.baseSlotsIds[i];

            InventoryStorage.Item memory item;
            for (uint j = 0; j < items.length; j++) {
                if (_allowedSlot(items[j]) == slotId) {
                    item = items[j];
                    break;
                }
            }
            if (item.erc1155Contract == address(0)) {
                if (inventorySL.equippedItems[arcadianId][slotId].erc1155Contract != address(0)) {
                    item = inventorySL.equippedItems[arcadianId][slotId];
                } else {
                    revert Inventory_NotAllBaseSlotsEquipped();
                }
            }
            
            encodedItems = abi.encodePacked(encodedItems, slotId, item.erc1155Contract, item.id);
        }

        return inventorySL.arcadianToBaseItemHash[arcadianId] == keccak256(encodedItems) || !inventorySL.baseItemsHashes.contains(keccak256(encodedItems));
    }

    function _hashBaseItemsUnchecked(
        uint arcadianId
    ) internal returns (bool isUnique) {
        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();
        bytes memory encodedItems;
        uint numBaseSlots = inventorySL.baseSlotsIds.length;

        for (uint8 i = 0; i < numBaseSlots; i++) {
            uint8 slotId = inventorySL.baseSlotsIds[i];
            
            InventoryStorage.Item storage equippedItem = inventorySL.equippedItems[arcadianId][slotId];
            encodedItems = abi.encodePacked(encodedItems, slotId, equippedItem.erc1155Contract, equippedItem.id);
        }

        bytes32 baseItemsHash = keccak256(encodedItems);

        isUnique = inventorySL.arcadianToBaseItemHash[arcadianId] == baseItemsHash || !inventorySL.baseItemsHashes.contains(baseItemsHash);
        inventorySL.baseItemsHashes.remove(inventorySL.arcadianToBaseItemHash[arcadianId]);
        inventorySL.baseItemsHashes.add(baseItemsHash);
        inventorySL.arcadianToBaseItemHash[arcadianId] = baseItemsHash;
    }

    function _createSlot(
        bool permanent,
        bool isBase,
        InventoryStorage.Item[] calldata allowedItems
    ) internal {
        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();

        // slots are 1-index
        inventorySL.numSlots += 1;
        uint8 newSlotId = inventorySL.numSlots;
        inventorySL.slots[newSlotId].permanent = permanent;
        inventorySL.slots[newSlotId].isBase = isBase;
        inventorySL.slots[newSlotId].id = newSlotId;

        _setSlotBase(newSlotId, isBase);

        if (allowedItems.length > 0) {
            _allowItemsInSlot(newSlotId, allowedItems);
        }

        emit SlotCreated(msg.sender, newSlotId, permanent, isBase);
    }

    function _setSlotBase(
        uint8 slotId,
        bool isBase
    ) internal onlyValidSlot(slotId) {
        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();

        uint8[] storage baseSlotsIds = inventorySL.baseSlotsIds;
        uint numBaseSlots = baseSlotsIds.length;

        if (isBase) {
            bool alreadyInBaseList;
            for (uint i = 0; i < numBaseSlots; i++) {
                if (baseSlotsIds[i] == slotId) {
                    alreadyInBaseList = true;
                    break;
                }
            }
            if (!alreadyInBaseList) {
                baseSlotsIds.push(slotId);
            }
        } else {
            for (uint i = 0; i < numBaseSlots; i++) {
                if (baseSlotsIds[i] == slotId) {
                    baseSlotsIds[i] = baseSlotsIds[numBaseSlots - 1];
                    baseSlotsIds.pop();
                    break;
                }
            }
        }

        inventorySL.slots[slotId].isBase = isBase;
    }

    function _setSlotPermanent(
        uint8 slotId,
        bool permanent
    ) internal onlyValidSlot(slotId) {
        InventoryStorage.layout().slots[slotId].permanent = permanent;
    }

    function _addBaseModifierCoupons(
        address account,
        uint8[] calldata slotsIds,
        uint[] calldata amounts
    ) internal {
        if (slotsIds.length != amounts.length)
            revert Inventory_InputDataMismatch();

        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();
        uint8 numSlots = inventorySL.numSlots;

        for (uint i = 0; i < slotsIds.length; i++) {
            if (slotsIds[i] == 0 && slotsIds[i] > numSlots) 
                revert Inventory_InvalidSlotId();
            if (!inventorySL.slots[slotsIds[i]].isBase) {
                revert Inventory_NonBaseSlot();
            }
            InventoryStorage.layout().baseModifierCoupon[account][slotsIds[i]] += amounts[i];
        }

        emit BaseModifierCouponAdded(msg.sender, account, slotsIds, amounts);
    }

    function _getbaseModifierCoupon(address account, uint8 slotId) internal view onlyValidSlot(slotId) returns (uint) {
        if (!InventoryStorage.layout().slots[slotId].isBase) {
            revert Inventory_NonBaseSlot();
        }
        return InventoryStorage.layout().baseModifierCoupon[account][slotId];
    }

    function _getBaseModifierCouponAll(address account) internal view returns (BaseModifierCoupon[] memory) {
        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();

        uint numBaseSlots = inventorySL.baseSlotsIds.length;

        BaseModifierCoupon[] memory coupons = new BaseModifierCoupon[](numBaseSlots);
        uint counter;
        for (uint8 i = 0; i < numBaseSlots; i++) {
            uint8 slotId = uint8(inventorySL.baseSlotsIds[i]);

            coupons[counter].slotId = slotId;
            coupons[counter].amount = inventorySL.baseModifierCoupon[account][slotId];
            counter++;
        }
        return coupons;
    }

    function _getBaseSlotsIds() internal view returns (uint8[] memory) {
        return InventoryStorage.layout().baseSlotsIds;
    }

    function _setItemsTransferRequired(
        InventoryStorage.Item[] calldata items,
        bool[] calldata requiresTransfer
    ) internal {
        if (items.length != requiresTransfer.length)
            revert Inventory_InputDataMismatch();
        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();
        for (uint i = 0; i < items.length; i++) {
            inventorySL.requiresTransfer[items[i].erc1155Contract][items[i].id] = requiresTransfer[i];
        }
    }
    
    function _allowItemsInSlot(
        uint8 slotId,
        InventoryStorage.Item[] calldata items
    ) internal virtual onlyValidSlot(slotId) {
        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();

        for (uint i = 0; i < items.length; i++) {
            if (!items[i].erc1155Contract.isContract()) 
                revert Inventory_InvalidERC1155Contract();

            inventorySL.itemSlot[items[i].erc1155Contract][items[i].id] = slotId;
        }

        emit ItemsAllowedInSlotUpdated(msg.sender, items);
    }

    function _disallowItems(
        InventoryStorage.Item[] calldata items
    ) internal virtual {
        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();
        for (uint i = 0; i < items.length; i++) {
            delete inventorySL.itemSlot[items[i].erc1155Contract][items[i].id];
        }

        emit ItemsAllowedInSlotUpdated(msg.sender, items);
    }

    function _allowedSlot(InventoryStorage.Item calldata item) internal view returns (uint) {
        return InventoryStorage.layout().itemSlot[item.erc1155Contract][item.id];
    }

    function _slot(uint8 slotId) internal view returns (InventoryStorage.Slot storage slot) {
        return InventoryStorage.layout().slots[slotId];
    }

    function _slotsAll() internal view returns (InventoryStorage.Slot[] memory slotsAll) {
        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();
        
        uint8 numSlots = inventorySL.numSlots;
        slotsAll = new InventoryStorage.Slot[](numSlots);

        for (uint8 i = 0; i < numSlots; i++) {
            uint8 slotId = i + 1;
            slotsAll[i] = inventorySL.slots[slotId];
        }
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.19;

import {ReentrancyGuard} from "@solidstate/contracts/utils/ReentrancyGuard.sol";
import { RolesInternal } from "../roles/RolesInternal.sol";
import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";

/**
LibInventory defines the storage structure used by the Inventory contract as a facet for an EIP-2535 Diamond
proxy.
 */
library InventoryStorage {
    bytes32 constant INVENTORY_STORAGE_POSITION =
        keccak256("inventory.storage.position");

    // Holds the information needed to identify an ERC1155 item
    struct Item {
        address erc1155Contract;
        uint id;
    }

    // Holds the general information about a slot
    struct Slot {
        uint8 id;
        bool permanent;
        bool isBase;
    }

    struct Layout {
        uint8 numSlots;

        // Slot id => Slot
        mapping(uint8 => Slot) slots;

        // arcadian id => slot id => Items equipped
        mapping(uint => mapping(uint8 => Item)) equippedItems;

        // item address => item id => allowed slot id
        mapping(address => mapping(uint => uint8)) itemSlot;
        
        // item address => item id => equip items requires transfer
        mapping(address => mapping(uint => bool)) requiresTransfer;

        // List of all the existent hashes
        EnumerableSet.Bytes32Set baseItemsHashes;
        // arcadian id => base items hash
        mapping(uint => bytes32) arcadianToBaseItemHash;

        // account => slotId => number of coupons to modify the base traits
        mapping(address => mapping(uint => uint)) baseModifierCoupon;

        // List of all the base slots ids
        uint8[] baseSlotsIds;
    }

    function layout()
        internal
        pure
        returns (Layout storage istore)
    {
        bytes32 position = INVENTORY_STORAGE_POSITION;
        assembly {
            istore.slot := position
        }
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.19;

interface IERC721A {
    struct TokenOwnership {
        address addr;
        uint64 startTimestamp;
        bool burned;
        uint24 extraData;
    }

    struct MintStageInfo {
        uint80 price;
        uint32 walletLimit;
        bytes32 merkleRoot;
        uint24 maxStageSupply;
        uint64 startTimeUnixSeconds;
        uint64 endTimeUnixSeconds;
    }

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event ConsecutiveTransfer(uint256 fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PermanentBaseURI(string baseURI);
    event SetActiveStage(uint256 activeStage);
    event SetBaseURI(string baseURI);
    event SetCosigner(address cosigner);
    event SetCrossmintAddress(address crossmintAddress);
    event SetGlobalWalletLimit(uint256 globalWalletLimit);
    event SetMaxMintableSupply(uint256 maxMintableSupply);
    event SetMintable(bool mintable);
    event SetTimestampExpirySeconds(uint64 expiry);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event UpdateStage(
        uint256 stage,
        uint80 price,
        uint32 walletLimit,
        bytes32 merkleRoot,
        uint24 maxStageSupply,
        uint64 startTimeUnixSeconds,
        uint64 endTimeUnixSeconds
    );
    event Withdraw(uint256 value);

    function approve(address to, uint256 tokenId) external payable;
    function assertValidCosign(address minter, uint32 qty, uint64 timestamp, bytes calldata signature) external view;
    function balanceOf(address owner) external view returns (uint256);
    function crossmint(uint32 qty, address to, bytes32[] calldata proof, uint64 timestamp, bytes calldata signature) external payable;
    function explicitOwnershipOf(uint256 tokenId) external view returns (TokenOwnership memory);
    function explicitOwnershipsOf(uint256[] calldata tokenIds) external view returns (TokenOwnership[] memory);
    function getActiveStageFromTimestamp(uint64 timestamp) external view returns (uint256);
    function getApproved(uint256 tokenId) external view returns (address);
    function getCosignDigest(address minter, uint32 qty, uint64 timestamp) external view returns (bytes32);
    function getCosignNonce(address minter) external view returns (uint256);
    function getCosigner() external view returns (address);
    function getCrossmintAddress() external view returns (address);
    function getGlobalWalletLimit() external view returns (uint256);
    function getMaxMintableSupply() external view returns (uint256);
    function getMintable() external view returns (bool);
    function getNumberStages() external view returns (uint256);
    function getStageInfo(uint256 index)
        external
        view
        returns (
            MintStageInfo memory,
            uint32,
            uint256
        );
    function getTimestampExpirySeconds() external view returns (uint64);
    function getTokenURISuffix() external view returns (string memory);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function mint(address minter, uint32 qty, uint64 timestamp) external payable;
    function name() external view returns (string memory);
    function owner() external view returns (address);
    function ownerMint(uint32 qty, address to) external;
        function ownerOf(uint256 tokenId) external view returns (address);
    function permanentBaseURI() external view returns (string memory);
    function safeTransferFrom(address from, address to, uint256 tokenId) external payable;
    function setApprovalForAll(address operator, bool approved) external;
    function setActiveStage(uint256 stage) external;
    function setBaseURI(string calldata baseURI) external;
    function setCosigner(address cosigner) external;
    function setCrossmintAddress(address crossmintAddress) external;
    function setGlobalWalletLimit(uint256 globalWalletLimit) external;
    function setMaxMintableSupply(uint256 maxMintableSupply) external;
    function setMintable(bool mintable) external;
    function setTimestampExpirySeconds(uint64 expiry) external;
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function symbol() external view returns (string memory);
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
    function tokensOfOwnerIn(address owner, uint256 indexStart, uint256 indexStop) external view returns (uint256[] memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function transferFrom(address from, address to, uint256 tokenId) external payable;
    function updateStage(
        uint256 stage,
        uint80 price,
        uint32 walletLimit,
        bytes32 merkleRoot,
        uint24 maxStageSupply,
        uint64 startTimeUnixSeconds,
        uint64 endTimeUnixSeconds
    ) external;
    function withdraw(uint256 value) external;
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.19;

import { MintPassStorage } from "./MintPassStorage.sol";
import { IERC721A } from "./IERC721A.sol";

contract MintPassInternal {

    error MintPass_ClaimInactive();

    event MintPassConsumed(address indexed account, uint tokenId);

    function _totalClaimedMintPass() internal view returns (uint) {
        return MintPassStorage.layout().totalClaimed;
    }

    function _claimedMintPass(address account) internal view returns (uint) {
        return MintPassStorage.layout().claimedAmount[account];
    }

    function _elegibleMintPass(address account) internal view returns (uint elegibleAmount) {
        MintPassStorage.Layout storage mintPassSL = MintPassStorage.layout();

        IERC721A passContract = IERC721A(mintPassSL.passContractAddress);

        uint[] memory tokensOfOwner = passContract.tokensOfOwner(account);
        for (uint i = 0; i < tokensOfOwner.length; i++) {
            if (!mintPassSL.isTokenClaimed[tokensOfOwner[i]]) {
                elegibleAmount++;
            }
        }
    }

    function _consumeMintPass(address account) internal returns (bool consumed) {
        MintPassStorage.Layout storage mintPassSL = MintPassStorage.layout();

        IERC721A passContract = IERC721A(mintPassSL.passContractAddress);

        if (!MintPassStorage.layout().claimActive)
            revert MintPass_ClaimInactive();

        uint[] memory tokensOfOwner = passContract.tokensOfOwner(account);

        for (uint i = 0; i < tokensOfOwner.length; i++) {
            uint tokenId = tokensOfOwner[i];
            if (!mintPassSL.isTokenClaimed[tokenId]) {
                mintPassSL.claimedAmount[account]++;
                mintPassSL.totalClaimed++;
                mintPassSL.isTokenClaimed[tokenId] = true;
                consumed = true;

                emit MintPassConsumed(account, 1);
                break;
            }
        }
    }

    function _isMintPassClaimActive() view internal returns (bool) {
        return MintPassStorage.layout().claimActive;
    }

    function _setClaimActiveMintPass(bool active) internal {
        MintPassStorage.layout().claimActive = active;
    }

    function _setMintPassContractAddress(address passContractAddress) internal {
        MintPassStorage.layout().passContractAddress = passContractAddress;
    }

    function _mintPassContractAddress() internal view returns (address) {
        return MintPassStorage.layout().passContractAddress;
    }

    function _isTokenClaimed(uint tokenId) internal view returns (bool) {
        return MintPassStorage.layout().isTokenClaimed[tokenId];
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.19;

library MintPassStorage {

    bytes32 constant MINT_PASS_STORAGE_POSITION =
        keccak256("mintPass.storage.position");
    
    struct Layout {
        mapping(uint => bool) isTokenClaimed;
        mapping(address => uint) claimedAmount;
        uint totalClaimed;
        uint maxSupply;
        bool claimActive;
        address passContractAddress;
    }

    function layout()
        internal
        pure
        returns (Layout storage es)
    {
        bytes32 position = MINT_PASS_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.19;

import { AccessControlInternal } from "@solidstate/contracts/access/access_control/AccessControlInternal.sol";
import { AccessControlStorage } from "@solidstate/contracts/access/access_control/AccessControlStorage.sol";
import { RolesStorage } from './RolesStorage.sol';

contract RolesInternal is AccessControlInternal {

    error Roles_MissingAdminRole();
    error Roles_MissingManagerRole();
    error Roles_MissingAutomationRole();

    modifier onlyDefaultAdmin() {
        if (!_hasRole(_defaultAdminRole(), msg.sender))
            revert Roles_MissingAdminRole();
        _;
    }

    modifier onlyManager() {
        if (!_hasRole(_managerRole(), msg.sender))
            revert Roles_MissingManagerRole();
        _;
    }

    modifier onlyAutomation() {
        if (!_hasRole(_managerRole(), msg.sender) && !_hasRole(_automationRole(), msg.sender))
            revert Roles_MissingAutomationRole();
        _;
    }

    function _defaultAdminRole() internal pure returns (bytes32) {
        return AccessControlStorage.DEFAULT_ADMIN_ROLE;
    }

    function _managerRole() internal view returns (bytes32) {
        return RolesStorage.layout().managerRole;
    }

    function _automationRole() internal view returns (bytes32) {
        return RolesStorage.layout().automationRole;
    }

    function _initRoles() internal {
        RolesStorage.Layout storage rolesSL = RolesStorage.layout();
        rolesSL.managerRole = keccak256("manager.role");
        rolesSL.automationRole = keccak256("automation.role");

        _grantRole(_defaultAdminRole(), msg.sender);
        _grantRole(_managerRole(), msg.sender);
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.19;

library RolesStorage {

    bytes32 constant ROLES_STORAGE_POSITION =
        keccak256("roles.storage.position");

    struct Layout {
        bytes32 managerRole;
        bytes32 automationRole;
    }

    function layout()
        internal
        pure
        returns (Layout storage es)
    {
        bytes32 position = ROLES_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.19;

import { WhitelistStorage } from "./WhitelistStorage.sol";
import { RolesInternal } from "./../roles/RolesInternal.sol";
contract WhitelistInternal is RolesInternal {

    error Whitelist_ExceedsElegibleAmount();
    error Whitelist_InputDataMismatch();
    error Whitelist_ClaimStateAlreadyUpdated();
    error Whitelist_ClaimInactive();

    event WhitelistBalanceChanged(address indexed account, WhitelistStorage.PoolId poolId, uint totalElegibleAmount, uint totalClaimedAmount);

    function _totalClaimedWhitelist(WhitelistStorage.PoolId poolId) internal view returns (uint) {
        return WhitelistStorage.layout().pools[poolId].totalClaimed;
    }

    function _totalElegibleWhitelist(WhitelistStorage.PoolId poolId) internal view returns (uint) {
        return WhitelistStorage.layout().pools[poolId].totalElegible;
    }

    function _claimedWhitelist(WhitelistStorage.PoolId poolId, address account) internal view returns (uint) {
        return WhitelistStorage.layout().pools[poolId].claimed[account];
    }

    function _elegibleWhitelist(WhitelistStorage.PoolId poolId, address account) internal view returns (uint) {
        return WhitelistStorage.layout().pools[poolId].elegible[account];
    }

    function _consumeWhitelist(WhitelistStorage.PoolId poolId, address account, uint amount) internal {
        WhitelistStorage.Layout storage whitelistSL = WhitelistStorage.layout();
        WhitelistStorage.Pool storage pool = whitelistSL.pools[poolId];

        if (!pool.claimActive)
            revert Whitelist_ClaimInactive();

        if (pool.elegible[account] < amount) 
            revert Whitelist_ExceedsElegibleAmount();

        pool.elegible[account] -= amount;
        pool.claimed[account] += amount;
        pool.totalClaimed += amount;
        pool.totalElegible -= amount;

        emit WhitelistBalanceChanged(account, poolId, pool.elegible[account], pool.claimed[account]);
    }

    function _increaseWhitelistElegible(WhitelistStorage.PoolId poolId, address account, uint amount) internal {
        WhitelistStorage.Layout storage whitelistSL = WhitelistStorage.layout();
        WhitelistStorage.Pool storage pool = whitelistSL.pools[poolId];
        pool.elegible[account] += amount;
        pool.totalElegible += amount;
        
        emit WhitelistBalanceChanged(account, poolId, pool.elegible[account], pool.claimed[account]);
    }

    function _increaseWhitelistElegibleBatch(WhitelistStorage.PoolId poolId, address[] calldata accounts, uint[] calldata amounts) internal {
        if (accounts.length != amounts.length) revert Whitelist_InputDataMismatch();

        WhitelistStorage.Layout storage whitelistSL = WhitelistStorage.layout();
        WhitelistStorage.Pool storage pool = whitelistSL.pools[poolId];

        for (uint i = 0; i < accounts.length; i++) {
            pool.elegible[accounts[i]] += amounts[i];
            pool.totalElegible += amounts[i];
            emit WhitelistBalanceChanged(accounts[i], poolId, pool.elegible[accounts[i]], pool.claimed[accounts[i]]);
        }
    }

    function _setWhitelistElegible(WhitelistStorage.PoolId poolId, address account, uint amount) internal {
        WhitelistStorage.Layout storage whitelistSL = WhitelistStorage.layout();
        WhitelistStorage.Pool storage pool = whitelistSL.pools[poolId];

        pool.totalElegible += amount - pool.elegible[account];
        pool.elegible[account] += amount;
        emit WhitelistBalanceChanged(account, poolId, pool.elegible[account], pool.claimed[account]);
    }

    function _setWhitelistElegibleBatch(WhitelistStorage.PoolId poolId, address[] calldata accounts, uint[] calldata amounts) internal {
        if (accounts.length != amounts.length) revert Whitelist_InputDataMismatch();

        WhitelistStorage.Layout storage whitelistSL = WhitelistStorage.layout();
        WhitelistStorage.Pool storage pool = whitelistSL.pools[poolId];

        for (uint i = 0; i < accounts.length; i++) {
            pool.totalElegible += amounts[i] - pool.elegible[accounts[i]];
            pool.elegible[accounts[i]] = amounts[i];
            emit WhitelistBalanceChanged(accounts[i], poolId, pool.elegible[accounts[i]], pool.claimed[accounts[i]]);
        }
    }

    function _isWhitelistClaimActive(WhitelistStorage.PoolId poolId) view internal returns (bool) {
        return WhitelistStorage.layout().pools[poolId].claimActive;
    }

    function _setWhitelistClaimActive(WhitelistStorage.PoolId poolId, bool active) internal {
        WhitelistStorage.Layout storage whitelistSL = WhitelistStorage.layout();
        WhitelistStorage.Pool storage pool = whitelistSL.pools[poolId];
        
        pool.claimActive = active;
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.19;

library WhitelistStorage {

    bytes32 constant WHITELIST_STORAGE_POSITION =
        keccak256("whitelist.storage.position");

    enum PoolId { Guaranteed, Restricted }
    
    struct Pool {
        mapping(address => uint) claimed;
        mapping(address => uint) elegible;
        uint totalClaimed;
        uint totalElegible;
        bool claimActive;
    }

    struct Layout {
        // pool id => tokens pool
        mapping(PoolId => Pool) pools;
    }

    function layout()
        internal
        pure
        returns (Layout storage es)
    {
        bytes32 position = WHITELIST_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}