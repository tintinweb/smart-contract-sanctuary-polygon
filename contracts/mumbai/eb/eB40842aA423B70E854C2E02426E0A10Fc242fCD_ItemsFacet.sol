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
 * @title Merkle tree verification utility
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library MerkleProof {
    /**
     * @notice verify whether given leaf is contained within Merkle tree defined by given root
     * @param proof proof that Merkle tree contains given leaf
     * @param root Merkle tree root
     * @param leaf element whose presence in Merkle tree to prove
     * @return whether leaf is proven to be contained within Merkle tree defined by root
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        unchecked {
            bytes32 computedHash = leaf;

            for (uint256 i = 0; i < proof.length; i++) {
                bytes32 proofElement = proof[i];

                if (computedHash <= proofElement) {
                    computedHash = keccak256(
                        abi.encodePacked(computedHash, proofElement)
                    );
                } else {
                    computedHash = keccak256(
                        abi.encodePacked(proofElement, computedHash)
                    );
                }
            }

            return computedHash == root;
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

import { IERC165 } from './IERC165.sol';

/**
 * @title ERC1155 transfer receiver interface
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @notice validate receipt of ERC1155 transfer
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param id token ID received
     * @param value quantity of tokens received
     * @param data data payload
     * @return function's own selector if transfer is accepted
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @notice validate receipt of ERC1155 batch transfer
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param ids token IDs received
     * @param values quantities of tokens received
     * @param data data payload
     * @return function's own selector if transfer is accepted
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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

import { IERC165Internal } from '../../../interfaces/IERC165Internal.sol';

interface IERC165BaseInternal is IERC165Internal {
    error ERC165Base__InvalidInterfaceId();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155 } from '../../../interfaces/IERC1155.sol';
import { IERC1155Receiver } from '../../../interfaces/IERC1155Receiver.sol';
import { IERC1155Base } from './IERC1155Base.sol';
import { ERC1155BaseInternal, ERC1155BaseStorage } from './ERC1155BaseInternal.sol';

/**
 * @title Base ERC1155 contract
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
abstract contract ERC1155Base is IERC1155Base, ERC1155BaseInternal {
    /**
     * @inheritdoc IERC1155
     */
    function balanceOf(
        address account,
        uint256 id
    ) public view virtual returns (uint256) {
        return _balanceOf(account, id);
    }

    /**
     * @inheritdoc IERC1155
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) public view virtual returns (uint256[] memory) {
        if (accounts.length != ids.length)
            revert ERC1155Base__ArrayLengthMismatch();

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        uint256[] memory batchBalances = new uint256[](accounts.length);

        unchecked {
            for (uint256 i; i < accounts.length; i++) {
                if (accounts[i] == address(0))
                    revert ERC1155Base__BalanceQueryZeroAddress();
                batchBalances[i] = balances[ids[i]][accounts[i]];
            }
        }

        return batchBalances;
    }

    /**
     * @inheritdoc IERC1155
     */
    function isApprovedForAll(
        address account,
        address operator
    ) public view virtual returns (bool) {
        return ERC1155BaseStorage.layout().operatorApprovals[account][operator];
    }

    /**
     * @inheritdoc IERC1155
     */
    function setApprovalForAll(address operator, bool status) public virtual {
        if (msg.sender == operator) revert ERC1155Base__SelfApproval();
        ERC1155BaseStorage.layout().operatorApprovals[msg.sender][
            operator
        ] = status;
        emit ApprovalForAll(msg.sender, operator, status);
    }

    /**
     * @inheritdoc IERC1155
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        if (from != msg.sender && !isApprovedForAll(from, msg.sender))
            revert ERC1155Base__NotOwnerOrApproved();
        _safeTransfer(msg.sender, from, to, id, amount, data);
    }

    /**
     * @inheritdoc IERC1155
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        if (from != msg.sender && !isApprovedForAll(from, msg.sender))
            revert ERC1155Base__NotOwnerOrApproved();
        _safeTransferBatch(msg.sender, from, to, ids, amounts, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155Receiver } from '../../../interfaces/IERC1155Receiver.sol';
import { AddressUtils } from '../../../utils/AddressUtils.sol';
import { IERC1155BaseInternal } from './IERC1155BaseInternal.sol';
import { ERC1155BaseStorage } from './ERC1155BaseStorage.sol';

/**
 * @title Base ERC1155 internal functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
abstract contract ERC1155BaseInternal is IERC1155BaseInternal {
    using AddressUtils for address;

    /**
     * @notice query the balance of given token held by given address
     * @param account address to query
     * @param id token to query
     * @return token balance
     */
    function _balanceOf(
        address account,
        uint256 id
    ) internal view virtual returns (uint256) {
        if (account == address(0))
            revert ERC1155Base__BalanceQueryZeroAddress();
        return ERC1155BaseStorage.layout().balances[id][account];
    }

    /**
     * @notice mint given quantity of tokens for given address
     * @dev ERC1155Receiver implementation is not checked
     * @param account beneficiary of minting
     * @param id token ID
     * @param amount quantity of tokens to mint
     * @param data data payload
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        if (account == address(0)) revert ERC1155Base__MintToZeroAddress();

        _beforeTokenTransfer(
            msg.sender,
            address(0),
            account,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        ERC1155BaseStorage.layout().balances[id][account] += amount;

        emit TransferSingle(msg.sender, address(0), account, id, amount);
    }

    /**
     * @notice mint given quantity of tokens for given address
     * @param account beneficiary of minting
     * @param id token ID
     * @param amount quantity of tokens to mint
     * @param data data payload
     */
    function _safeMint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        _mint(account, id, amount, data);

        _doSafeTransferAcceptanceCheck(
            msg.sender,
            address(0),
            account,
            id,
            amount,
            data
        );
    }

    /**
     * @notice mint batch of tokens for given address
     * @dev ERC1155Receiver implementation is not checked
     * @param account beneficiary of minting
     * @param ids list of token IDs
     * @param amounts list of quantities of tokens to mint
     * @param data data payload
     */
    function _mintBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        if (account == address(0)) revert ERC1155Base__MintToZeroAddress();
        if (ids.length != amounts.length)
            revert ERC1155Base__ArrayLengthMismatch();

        _beforeTokenTransfer(
            msg.sender,
            address(0),
            account,
            ids,
            amounts,
            data
        );

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        for (uint256 i; i < ids.length; ) {
            balances[ids[i]][account] += amounts[i];
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, address(0), account, ids, amounts);
    }

    /**
     * @notice mint batch of tokens for given address
     * @param account beneficiary of minting
     * @param ids list of token IDs
     * @param amounts list of quantities of tokens to mint
     * @param data data payload
     */
    function _safeMintBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        _mintBatch(account, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            msg.sender,
            address(0),
            account,
            ids,
            amounts,
            data
        );
    }

    /**
     * @notice burn given quantity of tokens held by given address
     * @param account holder of tokens to burn
     * @param id token ID
     * @param amount quantity of tokens to burn
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        if (account == address(0)) revert ERC1155Base__BurnFromZeroAddress();

        _beforeTokenTransfer(
            msg.sender,
            account,
            address(0),
            _asSingletonArray(id),
            _asSingletonArray(amount),
            ''
        );

        mapping(address => uint256) storage balances = ERC1155BaseStorage
            .layout()
            .balances[id];

        unchecked {
            if (amount > balances[account])
                revert ERC1155Base__BurnExceedsBalance();
            balances[account] -= amount;
        }

        emit TransferSingle(msg.sender, account, address(0), id, amount);
    }

    /**
     * @notice burn given batch of tokens held by given address
     * @param account holder of tokens to burn
     * @param ids token IDs
     * @param amounts quantities of tokens to burn
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        if (account == address(0)) revert ERC1155Base__BurnFromZeroAddress();
        if (ids.length != amounts.length)
            revert ERC1155Base__ArrayLengthMismatch();

        _beforeTokenTransfer(msg.sender, account, address(0), ids, amounts, '');

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        unchecked {
            for (uint256 i; i < ids.length; i++) {
                uint256 id = ids[i];
                if (amounts[i] > balances[id][account])
                    revert ERC1155Base__BurnExceedsBalance();
                balances[id][account] -= amounts[i];
            }
        }

        emit TransferBatch(msg.sender, account, address(0), ids, amounts);
    }

    /**
     * @notice transfer tokens between given addresses
     * @dev ERC1155Receiver implementation is not checked
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function _transfer(
        address operator,
        address sender,
        address recipient,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        if (recipient == address(0))
            revert ERC1155Base__TransferToZeroAddress();

        _beforeTokenTransfer(
            operator,
            sender,
            recipient,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        unchecked {
            uint256 senderBalance = balances[id][sender];
            if (amount > senderBalance)
                revert ERC1155Base__TransferExceedsBalance();
            balances[id][sender] = senderBalance - amount;
        }

        balances[id][recipient] += amount;

        emit TransferSingle(operator, sender, recipient, id, amount);
    }

    /**
     * @notice transfer tokens between given addresses
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function _safeTransfer(
        address operator,
        address sender,
        address recipient,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        _transfer(operator, sender, recipient, id, amount, data);

        _doSafeTransferAcceptanceCheck(
            operator,
            sender,
            recipient,
            id,
            amount,
            data
        );
    }

    /**
     * @notice transfer batch of tokens between given addresses
     * @dev ERC1155Receiver implementation is not checked
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
    function _transferBatch(
        address operator,
        address sender,
        address recipient,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        if (recipient == address(0))
            revert ERC1155Base__TransferToZeroAddress();
        if (ids.length != amounts.length)
            revert ERC1155Base__ArrayLengthMismatch();

        _beforeTokenTransfer(operator, sender, recipient, ids, amounts, data);

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        for (uint256 i; i < ids.length; ) {
            uint256 token = ids[i];
            uint256 amount = amounts[i];

            unchecked {
                uint256 senderBalance = balances[token][sender];

                if (amount > senderBalance)
                    revert ERC1155Base__TransferExceedsBalance();

                balances[token][sender] = senderBalance - amount;

                i++;
            }

            // balance increase cannot be unchecked because ERC1155Base neither tracks nor validates a totalSupply
            balances[token][recipient] += amount;
        }

        emit TransferBatch(operator, sender, recipient, ids, amounts);
    }

    /**
     * @notice transfer batch of tokens between given addresses
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
    function _safeTransferBatch(
        address operator,
        address sender,
        address recipient,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        _transferBatch(operator, sender, recipient, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            sender,
            recipient,
            ids,
            amounts,
            data
        );
    }

    /**
     * @notice wrap given element in array of length 1
     * @param element element to wrap
     * @return singleton array
     */
    function _asSingletonArray(
        uint256 element
    ) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;
        return array;
    }

    /**
     * @notice revert if applicable transfer recipient is not valid ERC1155Receiver
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector)
                    revert ERC1155Base__ERC1155ReceiverRejected();
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert ERC1155Base__ERC1155ReceiverNotImplemented();
            }
        }
    }

    /**
     * @notice revert if applicable transfer recipient is not valid ERC1155Receiver
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver.onERC1155BatchReceived.selector
                ) revert ERC1155Base__ERC1155ReceiverRejected();
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert ERC1155Base__ERC1155ReceiverNotImplemented();
            }
        }
    }

    /**
     * @notice ERC1155 hook, called before all transfers including mint and burn
     * @dev function should be overridden and new implementation must call super
     * @dev called for both single and batch transfers
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ERC1155BaseStorage {
    struct Layout {
        mapping(uint256 => mapping(address => uint256)) balances;
        mapping(address => mapping(address => bool)) operatorApprovals;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC1155Base');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155 } from '../../../interfaces/IERC1155.sol';
import { IERC1155BaseInternal } from './IERC1155BaseInternal.sol';

/**
 * @title ERC1155 base interface
 */
interface IERC1155Base is IERC1155BaseInternal, IERC1155 {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155Internal } from '../../../interfaces/IERC1155Internal.sol';

/**
 * @title ERC1155 base interface
 */
interface IERC1155BaseInternal is IERC1155Internal {
    error ERC1155Base__ArrayLengthMismatch();
    error ERC1155Base__BalanceQueryZeroAddress();
    error ERC1155Base__NotOwnerOrApproved();
    error ERC1155Base__SelfApproval();
    error ERC1155Base__BurnExceedsBalance();
    error ERC1155Base__BurnFromZeroAddress();
    error ERC1155Base__ERC1155ReceiverRejected();
    error ERC1155Base__ERC1155ReceiverNotImplemented();
    error ERC1155Base__MintToZeroAddress();
    error ERC1155Base__TransferExceedsBalance();
    error ERC1155Base__TransferToZeroAddress();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { EnumerableSet } from '../../../data/EnumerableSet.sol';
import { ERC1155BaseInternal } from '../base/ERC1155BaseInternal.sol';
import { IERC1155Enumerable } from './IERC1155Enumerable.sol';
import { ERC1155EnumerableInternal, ERC1155EnumerableStorage } from './ERC1155EnumerableInternal.sol';

/**
 * @title ERC1155 implementation including enumerable and aggregate functions
 */
abstract contract ERC1155Enumerable is
    IERC1155Enumerable,
    ERC1155EnumerableInternal
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @inheritdoc IERC1155Enumerable
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply(id);
    }

    /**
     * @inheritdoc IERC1155Enumerable
     */
    function totalHolders(uint256 id) public view virtual returns (uint256) {
        return _totalHolders(id);
    }

    /**
     * @inheritdoc IERC1155Enumerable
     */
    function accountsByToken(
        uint256 id
    ) public view virtual returns (address[] memory) {
        return _accountsByToken(id);
    }

    /**
     * @inheritdoc IERC1155Enumerable
     */
    function tokensByAccount(
        address account
    ) public view virtual returns (uint256[] memory) {
        return _tokensByAccount(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { EnumerableSet } from '../../../data/EnumerableSet.sol';
import { ERC1155BaseInternal, ERC1155BaseStorage } from '../base/ERC1155BaseInternal.sol';
import { ERC1155EnumerableStorage } from './ERC1155EnumerableStorage.sol';

/**
 * @title ERC1155Enumerable internal functions
 */
abstract contract ERC1155EnumerableInternal is ERC1155BaseInternal {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @notice query total minted supply of given token
     * @param id token id to query
     * @return token supply
     */
    function _totalSupply(uint256 id) internal view virtual returns (uint256) {
        return ERC1155EnumerableStorage.layout().totalSupply[id];
    }

    /**
     * @notice query total number of holders for given token
     * @param id token id to query
     * @return quantity of holders
     */
    function _totalHolders(uint256 id) internal view virtual returns (uint256) {
        return ERC1155EnumerableStorage.layout().accountsByToken[id].length();
    }

    /**
     * @notice query holders of given token
     * @param id token id to query
     * @return list of holder addresses
     */
    function _accountsByToken(
        uint256 id
    ) internal view virtual returns (address[] memory) {
        EnumerableSet.AddressSet storage accounts = ERC1155EnumerableStorage
            .layout()
            .accountsByToken[id];

        address[] memory addresses = new address[](accounts.length());

        unchecked {
            for (uint256 i; i < accounts.length(); i++) {
                addresses[i] = accounts.at(i);
            }
        }

        return addresses;
    }

    /**
     * @notice query tokens held by given address
     * @param account address to query
     * @return list of token ids
     */
    function _tokensByAccount(
        address account
    ) internal view virtual returns (uint256[] memory) {
        EnumerableSet.UintSet storage tokens = ERC1155EnumerableStorage
            .layout()
            .tokensByAccount[account];

        uint256[] memory ids = new uint256[](tokens.length());

        unchecked {
            for (uint256 i; i < tokens.length(); i++) {
                ids[i] = tokens.at(i);
            }
        }

        return ids;
    }

    /**
     * @notice ERC1155 hook: update aggregate values
     * @inheritdoc ERC1155BaseInternal
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from != to) {
            ERC1155EnumerableStorage.Layout storage l = ERC1155EnumerableStorage
                .layout();
            mapping(uint256 => EnumerableSet.AddressSet)
                storage tokenAccounts = l.accountsByToken;
            EnumerableSet.UintSet storage fromTokens = l.tokensByAccount[from];
            EnumerableSet.UintSet storage toTokens = l.tokensByAccount[to];

            for (uint256 i; i < ids.length; ) {
                uint256 amount = amounts[i];

                if (amount > 0) {
                    uint256 id = ids[i];

                    if (from == address(0)) {
                        l.totalSupply[id] += amount;
                    } else if (_balanceOf(from, id) == amount) {
                        tokenAccounts[id].remove(from);
                        fromTokens.remove(id);
                    }

                    if (to == address(0)) {
                        l.totalSupply[id] -= amount;
                    } else if (_balanceOf(to, id) == 0) {
                        tokenAccounts[id].add(to);
                        toTokens.add(id);
                    }
                }

                unchecked {
                    i++;
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { EnumerableSet } from '../../../data/EnumerableSet.sol';

library ERC1155EnumerableStorage {
    struct Layout {
        mapping(uint256 => uint256) totalSupply;
        mapping(uint256 => EnumerableSet.AddressSet) accountsByToken;
        mapping(address => EnumerableSet.UintSet) tokensByAccount;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC1155Enumerable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155BaseInternal } from '../base/IERC1155BaseInternal.sol';

/**
 * @title ERC1155 enumerable and aggregate function interface
 */
interface IERC1155Enumerable is IERC1155BaseInternal {
    /**
     * @notice query total minted supply of given token
     * @param id token id to query
     * @return token supply
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @notice query total number of holders for given token
     * @param id token id to query
     * @return quantity of holders
     */
    function totalHolders(uint256 id) external view returns (uint256);

    /**
     * @notice query holders of given token
     * @param id token id to query
     * @return list of holder addresses
     */
    function accountsByToken(
        uint256 id
    ) external view returns (address[] memory);

    /**
     * @notice query tokens held by given address
     * @param account address to query
     * @return list of token ids
     */
    function tokensByAccount(
        address account
    ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { UintUtils } from '../../../utils/UintUtils.sol';
import { IERC1155Metadata } from './IERC1155Metadata.sol';
import { ERC1155MetadataInternal } from './ERC1155MetadataInternal.sol';
import { ERC1155MetadataStorage } from './ERC1155MetadataStorage.sol';

/**
 * @title ERC1155 metadata extensions
 */
abstract contract ERC1155Metadata is IERC1155Metadata, ERC1155MetadataInternal {
    using UintUtils for uint256;

    /**
     * @notice inheritdoc IERC1155Metadata
     */
    function uri(uint256 tokenId) public view virtual returns (string memory) {
        ERC1155MetadataStorage.Layout storage l = ERC1155MetadataStorage
            .layout();

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155MetadataInternal } from './IERC1155MetadataInternal.sol';
import { ERC1155MetadataStorage } from './ERC1155MetadataStorage.sol';

/**
 * @title ERC1155Metadata internal functions
 */
abstract contract ERC1155MetadataInternal is IERC1155MetadataInternal {
    /**
     * @notice set base metadata URI
     * @dev base URI is a non-standard feature adapted from the ERC721 specification
     * @param baseURI base URI
     */
    function _setBaseURI(string memory baseURI) internal {
        ERC1155MetadataStorage.layout().baseURI = baseURI;
    }

    /**
     * @notice set per-token metadata URI
     * @param tokenId token whose metadata URI to set
     * @param tokenURI per-token URI
     */
    function _setTokenURI(uint256 tokenId, string memory tokenURI) internal {
        ERC1155MetadataStorage.layout().tokenURIs[tokenId] = tokenURI;
        emit URI(tokenURI, tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title ERC1155 metadata extensions
 */
library ERC1155MetadataStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC1155Metadata');

    struct Layout {
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

import { IERC1155MetadataInternal } from './IERC1155MetadataInternal.sol';

/**
 * @title ERC1155Metadata interface
 */
interface IERC1155Metadata is IERC1155MetadataInternal {
    /**
     * @notice get generated URI for given token
     * @return token URI
     */
    function uri(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC1155Metadata interface needed by internal functions
 */
interface IERC1155MetadataInternal {
    event URI(string value, uint256 indexed tokenId);
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

// SPDX-License-Identifier: UNLICENSED
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
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using AddressUtils for address;

    error Inventory_InvalidERC1155Contract();
    error Inventory_UnequippingPermanentSlot();
    error Inventory_InvalidSlotId();
    error Inventory_ItemDoesNotHaveSlotAssigned();
    error Inventory_InsufficientItemBalance();
    error Inventory_UnequippingEmptySlot();
    error Inventory_UnequippingBaseSlot();
    error Inventory_SlotNotSpecified();
    error Inventory_ItemNotSpecified();
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
        uint[] slots
    );

    event ItemsUnequipped(
        address indexed by,
        uint indexed arcadianId,
        uint[] slots
    );

    event SlotCreated(
        address indexed by,
        uint slotId,
        bool permanent,
        bool isBase
    );

    event BaseModifierCouponAdded(
        address indexed by,
        address indexed to,
        uint[] slotsIds,
        uint[] amounts
    );

    event BaseModifierCouponConsumed(
        address indexed account,
        uint[] slotsIds
    );

    // Helper structs only used in view functions to ease data reading from web3
    struct ItemInSlot {
        uint slotId;
        address erc721Contract;
        uint itemId;
    }
    struct BaseModifierCoupon {
        uint slotId;
        uint amount;
    }

    modifier onlyValidSlot(uint slotId) {
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

    function _transferRequired(InventoryStorage.Slot storage slot) internal view returns (bool required) {
        required = !slot.isBase && !slot.permanent;
    }

    function _equip(
        uint arcadianId,
        InventoryStorage.Item[] calldata items,
        bool freeBaseModifier
    ) internal onlyArcadianOwner(arcadianId) {

        if (items.length == 0) 
            revert Inventory_ItemNotSpecified();

        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();
        uint numBaseSlotsModified;
        uint[] memory slotsIds = new uint[](items.length);
        for (uint i = 0; i < items.length; i++) {
            uint slotId = _equipSingleSlot(arcadianId, items[i], freeBaseModifier);
            if (inventorySL.slots[slotId].isBase) {
                numBaseSlotsModified++;
            }
            slotsIds[i] = slotId;
        }

        if (!_baseSlotsEquipped(arcadianId)) 
            revert Inventory_NotAllBaseSlotsEquipped();

        if (numBaseSlotsModified > 0) {
            if (!_hashBaseItemsUnchecked(arcadianId))
                revert Inventory_ArcadianNotUnique();
            
            if (!freeBaseModifier) {
                uint[] memory baseSlotsModified = new uint[](numBaseSlotsModified);
                uint counter;
                for (uint i = 0; i < items.length; i++) {
                    uint slotId = inventorySL.itemSlot[items[i].erc721Contract][items[i].id];
                    if (inventorySL.slots[slotId].isBase) {
                        baseSlotsModified[counter] = slotId;
                        counter++;
                    }
                }
                emit BaseModifierCouponConsumed(msg.sender, baseSlotsModified);
            }
        }

        emit ItemsEquipped(msg.sender, arcadianId, slotsIds);
    }

    function _equipSingleSlot(
        uint arcadianId,
        InventoryStorage.Item calldata item,
        bool freeBaseModifier
    ) internal returns (uint slotId) {

        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();
        slotId = inventorySL.itemSlot[item.erc721Contract][item.id];
        
        if (slotId == 0 || slotId > InventoryStorage.layout().numSlots) 
            revert Inventory_ItemDoesNotHaveSlotAssigned();
        
        if (!freeBaseModifier && inventorySL.slots[slotId].isBase) {
            if (inventorySL.baseModifierCoupon[msg.sender][slotId] < 1)
                revert Inventory_CouponNeededToModifyBaseSlots();

            inventorySL.baseModifierCoupon[msg.sender][slotId]--;
        }

        InventoryStorage.Item storage existingItem = inventorySL.equippedItems[arcadianId][slotId];
        if (inventorySL.slots[slotId].permanent && existingItem.erc721Contract != address(0)) 
            revert Inventory_UnequippingPermanentSlot();
        if (existingItem.erc721Contract == item.erc721Contract && existingItem.id == item.id)
            revert Inventory_ItemAlreadyEquippedInSlot();

        if (inventorySL.equippedItems[arcadianId][slotId].erc721Contract != address(0))
            _unequipUnchecked(arcadianId, slotId);

        bool requiresTransfer = inventorySL.requiresTransfer[item.erc721Contract][item.id];
        if (requiresTransfer) {
            IERC1155 erc1155Contract = IERC1155(item.erc721Contract);
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

    function _baseSlotsEquipped(uint arcadianId) internal view returns (bool) {
        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();
        uint numSlots = inventorySL.numSlots;
        for (uint i = 0; i < numSlots; i++) {
            uint slotId = i + 1;
            if (!inventorySL.slots[slotId].isBase)
                continue;
            if (inventorySL.slots[slotId].isBase && inventorySL.equippedItems[arcadianId][slotId].erc721Contract == address(0)) {
                return false;
            }
        }
        return true;
    }

    function _unequipUnchecked(
        uint arcadianId,
        uint slotId
    ) internal {
        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();
        InventoryStorage.Item storage existingItem = inventorySL.equippedItems[arcadianId][slotId];

        bool requiresTransfer = inventorySL.requiresTransfer[existingItem.erc721Contract][existingItem.id];
        if (requiresTransfer) {
            IERC1155 erc1155Contract = IERC1155(existingItem.erc721Contract);
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
        uint[] calldata slotIds
    ) internal onlyArcadianOwner(arcadianId) {
        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();

        if (slotIds.length == 0) 
            revert Inventory_SlotNotSpecified();

        for (uint i = 0; i < slotIds.length; i++) {
            if (inventorySL.slots[slotIds[i]].permanent) 
                revert Inventory_UnequippingPermanentSlot();

            if (inventorySL.equippedItems[arcadianId][slotIds[i]].erc721Contract == address(0)) 
                revert Inventory_UnequippingEmptySlot();
            
            if (inventorySL.slots[slotIds[i]].isBase)
                revert Inventory_UnequippingBaseSlot();

            _unequipUnchecked(arcadianId, slotIds[i]);
        }

        _hashBaseItemsUnchecked(arcadianId);

        emit ItemsUnequipped(
            msg.sender,
            arcadianId,
            slotIds
        );
    }

    function _equipped(
        uint arcadianId,
        uint slotId
    ) internal view returns (ItemInSlot memory) {
        InventoryStorage.Item storage item = InventoryStorage.layout().equippedItems[arcadianId][slotId];
        return ItemInSlot(slotId, item.erc721Contract, item.id);
    }

    function _equippedBatch(
        uint arcadianId,
        uint[] calldata slotIds
    ) internal view returns (ItemInSlot[] memory equippedSlots) {
        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();
        equippedSlots = new ItemInSlot[](slotIds.length);
        for (uint i = 0; i < slotIds.length; i++) {
            InventoryStorage.Item storage equippedItem = inventorySL.equippedItems[arcadianId][slotIds[i]];
            equippedSlots[i] = ItemInSlot(slotIds[i], equippedItem.erc721Contract, equippedItem.id);
        }
    }

    function _equippedAll(
        uint arcadianId
    ) internal view returns (ItemInSlot[] memory equippedSlots) {
        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();
        uint numSlots = inventorySL.numSlots;
        equippedSlots = new ItemInSlot[](numSlots);
        for (uint i = 0; i < numSlots; i++) {
            uint slot = i + 1;
            InventoryStorage.Item storage equippedItem = inventorySL.equippedItems[arcadianId][slot];
            equippedSlots[i] = ItemInSlot(slot, equippedItem.erc721Contract, equippedItem.id);
        }
    }

    function _isArcadianUnique(
        uint arcadianId,
        InventoryStorage.Item[] calldata items
    ) internal view returns (bool) {

        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();
        uint numSlots = inventorySL.numSlots;

        bytes memory encodedItems;
        for (uint i = 0; i < numSlots; i++) {
            uint slotId = i + 1;
            if (!inventorySL.slots[slotId].isBase)
                continue;

            InventoryStorage.Item memory item;
            for (uint j = 0; j < items.length; j++) {
                if (_allowedSlot(items[j]) == slotId) {
                    item = items[j];
                    break;
                }
            }
            if (item.erc721Contract == address(0)) {
                if (inventorySL.equippedItems[arcadianId][slotId].erc721Contract != address(0)) {
                    item = inventorySL.equippedItems[arcadianId][slotId];
                } else {
                    revert Inventory_NotAllBaseSlotsEquipped();
                }
            }
            
            encodedItems = abi.encodePacked(encodedItems, slotId, item.erc721Contract, item.id);
        }

        return !inventorySL.baseItemsHashes.contains(keccak256(encodedItems));
    }

    function _hashBaseItemsUnchecked(
        uint arcadianId
    ) internal returns (bool isUnique) {
        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();
        bytes memory encodedItems;
        uint numSlots = inventorySL.numSlots;

        for (uint i = 0; i < numSlots; i++) {
            uint slotId = i + 1;
            if (!inventorySL.slots[slotId].isBase)
                continue;
            InventoryStorage.Item storage equippedItem = inventorySL.equippedItems[arcadianId][slotId];
            encodedItems = abi.encodePacked(encodedItems, slotId, equippedItem.erc721Contract, equippedItem.id);
        }

        bytes32 baseItemsHash = keccak256(encodedItems);
        isUnique = !inventorySL.baseItemsHashes.contains(baseItemsHash);
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
        uint newSlot = inventorySL.numSlots;
        inventorySL.slots[newSlot].permanent = permanent;
        inventorySL.slots[newSlot].isBase = isBase;
        inventorySL.slots[newSlot].id = newSlot;

        if (allowedItems.length > 0) {
            _allowItemsInSlot(newSlot, allowedItems);
        }

        emit SlotCreated(msg.sender, newSlot, permanent, isBase);
    }

    function _setSlotBase(
        uint slotId,
        bool isBase
    ) internal onlyValidSlot(slotId) {
        InventoryStorage.layout().slots[slotId].isBase = isBase;
    }

    function _setSlotPermanent(
        uint slotId,
        bool permanent
    ) internal onlyValidSlot(slotId) {
        InventoryStorage.layout().slots[slotId].permanent = permanent;
    }

    function _addBaseModifierCoupons(
        address account,
        uint[] calldata slotIds,
        uint[] calldata amounts
    ) internal {
        if (slotIds.length != amounts.length)
            revert Inventory_InputDataMismatch();

        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();
        uint numSlots = inventorySL.numSlots;

        for (uint i = 0; i < slotIds.length; i++) {
            if (slotIds[i] == 0 && slotIds[i] > numSlots) 
                revert Inventory_InvalidSlotId();
            if (!inventorySL.slots[slotIds[i]].isBase) {
                revert Inventory_NonBaseSlot();
            }
            InventoryStorage.layout().baseModifierCoupon[account][slotIds[i]] += amounts[i];
        }

        emit BaseModifierCouponAdded(msg.sender, account, slotIds, amounts);
    }

    function _getbaseModifierCoupon(address account, uint slotId) internal view onlyValidSlot(slotId) returns (uint) {
        if (!InventoryStorage.layout().slots[slotId].isBase) {
            revert Inventory_NonBaseSlot();
        }
        return InventoryStorage.layout().baseModifierCoupon[account][slotId];
    }

    function _getBaseModifierCouponAll(address account) internal view returns (BaseModifierCoupon[] memory) {
        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();

        uint numSlots = inventorySL.numSlots;

        uint baseCounter;
        for (uint i = 0; i < numSlots; i++) {
            uint slotId = i + 1;
            if (inventorySL.slots[slotId].isBase) {
                baseCounter++;
            }
        }

        BaseModifierCoupon[] memory coupons = new BaseModifierCoupon[](baseCounter);
        uint counter;
        for (uint i = 0; i < numSlots; i++) {
            uint slotId = i + 1;
            if (!inventorySL.slots[slotId].isBase)
                continue;
            coupons[counter].slotId = slotId;
            coupons[counter].amount = inventorySL.baseModifierCoupon[account][slotId];
            counter++;
        }
        return coupons;
    }

    function _setItemsTransferRequired(
        InventoryStorage.Item[] calldata items,
        bool[] calldata requiresTransfer
    ) internal {
        if (items.length != requiresTransfer.length)
            revert Inventory_InputDataMismatch();
        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();
        for (uint i = 0; i < items.length; i++) {
            inventorySL.requiresTransfer[items[i].erc721Contract][items[i].id] = requiresTransfer[i];
        }
    }
    
    function _allowItemsInSlot(
        uint slotId,
        InventoryStorage.Item[] calldata items
    ) internal virtual onlyValidSlot(slotId) {
        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();

        for (uint i = 0; i < items.length; i++) {
            if (!items[i].erc721Contract.isContract()) 
                revert Inventory_InvalidERC1155Contract();

            inventorySL.itemSlot[items[i].erc721Contract][items[i].id] = slotId;
        }

        emit ItemsAllowedInSlotUpdated(msg.sender, items);
    }

    function _disallowItems(
        InventoryStorage.Item[] calldata items
    ) internal virtual {
        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();
        for (uint i = 0; i < items.length; i++) {
            delete inventorySL.itemSlot[items[i].erc721Contract][items[i].id];
        }

        emit ItemsAllowedInSlotUpdated(msg.sender, items);
    }

    function _allowedSlot(InventoryStorage.Item calldata item) internal view returns (uint) {
        return InventoryStorage.layout().itemSlot[item.erc721Contract][item.id];
    }

    function _slot(uint slotId) internal view returns (InventoryStorage.Slot storage slot) {
        return InventoryStorage.layout().slots[slotId];
    }

    function _slotsAll() internal view returns (InventoryStorage.Slot[] memory slotsAll) {
        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();
        
        uint numSlots = inventorySL.numSlots;
        slotsAll = new InventoryStorage.Slot[](numSlots);

        for (uint i = 0; i < numSlots; i++) {
            uint slotId = i + 1;
            slotsAll[i] = inventorySL.slots[slotId];
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
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

    uint constant ERC721_ITEM_TYPE = 721;
    uint constant ERC1155_ITEM_TYPE = 1155;

    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // Holds the information needed to identify an ERC1155 item
    struct Item {
        address erc721Contract;
        uint id;
    }

    // Holds the general information about a slot
    struct Slot {
        uint id;
        bool permanent;
        bool isBase;
    }

    struct Layout {
        uint numSlots;

        // Slot id => Slot
        mapping(uint => Slot) slots;

        // arcadian id => slot id => Items equipped
        mapping(uint => mapping(uint => Item)) equippedItems;

        // item address => item id => allowed slot id
        mapping(address => mapping(uint => uint)) itemSlot;
        
        // item address => item id => equip items requires transfer
        mapping(address => mapping(uint => bool)) requiresTransfer;

        // List of all the existent hashes
        EnumerableSet.Bytes32Set baseItemsHashes;
        // arcadian id => base items hash
        mapping(uint => bytes32) arcadianToBaseItemHash;

        // account => slotId => number of coupons to modify the base traits
        mapping(address => mapping(uint => uint)) baseModifierCoupon;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { ERC1155Base } from "@solidstate/contracts/token/ERC1155/base/ERC1155Base.sol";
import { ERC1155BaseInternal } from "@solidstate/contracts/token/ERC1155/base/ERC1155BaseInternal.sol";
import { ERC1155Enumerable } from "@solidstate/contracts/token/ERC1155/enumerable/ERC1155Enumerable.sol";
import { ERC1155EnumerableInternal } from "@solidstate/contracts/token/ERC1155/enumerable/ERC1155EnumerableInternal.sol";
import { ERC1155Metadata } from "@solidstate/contracts/token/ERC1155/metadata/ERC1155Metadata.sol";
import { ReentrancyGuard } from "@solidstate/contracts/utils/ReentrancyGuard.sol";
import { ItemsInternal } from "./ItemsInternal.sol";
import { ItemsStorage } from "./ItemsStorage.sol";
import { Multicall } from "@solidstate/contracts/utils/Multicall.sol";
import { IERC1155 } from '@solidstate/contracts/interfaces/IERC1155.sol';

/**
 * @title ItemsFacet
 * @dev This contract handles the creation and management of items
 * It uses ERC1155 tokens to represent items and provides methods to mint new items,
 * claim items via Merkle tree or a whitelist, and set the base and URIs for
 * the items. It also uses the ReentrancyGuard and Multicall contracts for security
 * and gas efficiency.
 */
contract ItemsFacet is ERC1155Base, ERC1155Enumerable, ERC1155Metadata, ReentrancyGuard, ItemsInternal, Multicall {
    
    /**
     * @notice Claims an item if present in the Merkle tree
     * @param itemId The ID of the item to claim
     * @param amount The amount of the item to claim
     * @param proof The Merkle proof for the item
     */
    function claimMerkle(uint itemId, uint amount, bytes32[] calldata proof)
        public nonReentrant
    {
        _claimMerkle(msg.sender, itemId, amount, proof);
    }

    /**
     * @notice Claims items if present in the Merkle tree
     * @param itemsIds The IDs of the items to claim
     * @param amounts The amounts of the items to claim
     * @param proofs The Merkle proofs for the items
     */
    function claimMerkleBatch(uint256[] calldata itemsIds, uint[] calldata amounts, bytes32[][] calldata proofs) external nonReentrant {
        _claimMerkleBatch(msg.sender, itemsIds, amounts, proofs);
    }

    /**
     * @notice Claims items from a whitelist
     * @param itemIds The IDs of the items to claim
     * @param amounts The amounts of the items to claim
     */
    function claimWhitelist(uint[] calldata itemIds, uint[] calldata amounts) external {
        _claimWhitelist(itemIds, amounts);
    }

    /**
     * @notice Amount claimed by an address of a specific item
     * @param account the account to query
     * @param itemId the item id to query
     * @return amount returns the claimed amount given an account and an item id
     */
    function claimedAmount(address account, uint itemId) external view returns (uint amount) {
        return _claimedAmount(account, itemId);
    }

    /**
     * @notice Mints a new item. Only minter role account can mint
     * @param to The address to mint the item to
     * @param itemId The ID of the item to mint
     * @param amount The item amount to be minted
     */
    function mint(address to, uint256 itemId, uint256 amount)
        public onlyManager
    {
        _mint(to, itemId, amount);
    }

    /**
     * @notice Mint a batch of items to a specific address. Only minter role account can mint
     * @param to The address to receive the minted items
     * @param itemIds An array of items IDs to be minted
     * @param amounts The items amounts to be minted
     */
    function mintBatch(address to, uint256[] calldata itemIds, uint256[] calldata amounts)
        public onlyManager
    {
        _mintBatch(to, itemIds, amounts);
    }

    /**
     * @notice Set the base URI for all items metadata
     * @dev Only the manager role can call this function
     * @param baseURI The new base URI
     */
    function setBaseURI(string calldata baseURI) external onlyManager {
        _setBaseURI(baseURI);
    }

    /**
     * @notice Set the base URI for all items metadata
     * @dev Only the manager role can call this function
     * @param newBaseURI The new base URI
     * @param migrate Should migrate to IPFS
     */
    function migrateToIPFS(string calldata newBaseURI, bool migrate) external onlyManager {
        _migrateToIPFS(newBaseURI, migrate);
    }

    /**
     * @dev Returns the current inventory address
     * @return The address of the inventory contract
     */
    function getInventoryAddress() external view returns (address) {
        return _getInventoryAddress();
    }

    /**
     * @dev Sets the inventory address
     * @param inventoryAddress The new address of the inventory contract
     */
    function setInventoryAddress(address inventoryAddress) external onlyManager {
        _setInventoryAddress(inventoryAddress);
    }

    /**
     * @notice Override ERC1155Metadata
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        if (ItemsStorage.layout().isMigratedToIPFS) {
            return string.concat(super.uri(tokenId), ".json");
        } else {
            return super.uri(tokenId);
        }
    }

    /**
     * @notice Set the URI for a specific item ID
     * @dev Only the manager role can call this function
     * @param tokenId The ID of the item to set the URI for
     * @param tokenURI The new item URI
     */
    function setTokenURI(uint tokenId, string calldata tokenURI) external onlyManager {
        _setTokenURI(tokenId, tokenURI);
    }


    // overrides
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override (ERC1155Base) {
        // Add red carpet logic for the inventory
        if (from != msg.sender && !isApprovedForAll(from, msg.sender) && _getInventoryAddress() != msg.sender )
            revert ERC1155Base__NotOwnerOrApproved();
        _safeTransfer(msg.sender, from, to, id, amount, data);
    }

    function supportsInterface(bytes4 _interface) external pure returns (bool) {
        return type(IERC1155).interfaceId == _interface;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        virtual
        override (ERC1155BaseInternal, ERC1155EnumerableInternal, ItemsInternal)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { ERC1155BaseInternal } from "@solidstate/contracts/token/ERC1155/base/ERC1155BaseInternal.sol";
import { RolesInternal } from "../roles/RolesInternal.sol";
import { ItemsInternal } from "./ItemsInternal.sol";
import { InventoryInternal } from "../inventory/InventoryInternal.sol";
import { ERC165BaseInternal } from '@solidstate/contracts/introspection/ERC165/base/ERC165BaseInternal.sol';
import { IERC1155 } from '@solidstate/contracts/interfaces/IERC1155.sol';

contract ItemsInit is RolesInternal, ItemsInternal, InventoryInternal, ERC165BaseInternal {    
    function init(bytes32 merkleRoot, string calldata baseUri, address inventoryAddress) external {

        _setSupportsInterface(type(IERC1155).interfaceId, true);

        _updateMerkleRoot(merkleRoot);

        _initRoles();

        _setBaseURI(baseUri);
        _setInventoryAddress(inventoryAddress);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { ERC1155BaseInternal } from "@solidstate/contracts/token/ERC1155/base/ERC1155BaseInternal.sol";
import { ERC1155EnumerableInternal } from "@solidstate/contracts/token/ERC1155/enumerable/ERC1155EnumerableInternal.sol";
import { ERC1155MetadataInternal } from "@solidstate/contracts/token/ERC1155/metadata/ERC1155MetadataInternal.sol";
import { ItemsStorage } from "./ItemsStorage.sol";
import { MerkleInternal } from "../merkle/MerkleInternal.sol";
import { WhitelistInternal } from "../whitelist/WhitelistInternal.sol";
import { ArrayUtils } from "@solidstate/contracts/utils/ArrayUtils.sol";
import { WhitelistStorage } from "../whitelist/WhitelistStorage.sol";

contract ItemsInternal is MerkleInternal, WhitelistInternal, ERC1155BaseInternal, ERC1155EnumerableInternal, ERC1155MetadataInternal {

    error Items_InputsLengthMistatch();
    error Items_InvalidItemId();
    error Items_ItemsBasicStatusAlreadyUpdated();
    error Items_MintingNonBasicItem();
    error Items_MaximumItemMintsExceeded();

    event ItemClaimedMerkle(address indexed to, uint256 indexed itemId, uint amount);

    using ArrayUtils for uint[];

    function _claimMerkle(address to, uint itemId, uint amount, bytes32[] memory proof)
        internal
    {
        if (itemId < 1) revert Items_InvalidItemId();

        ItemsStorage.Layout storage itemsSL = ItemsStorage.layout();

        bytes memory leaf = abi.encode(to, itemId, amount);
        _consumeLeaf(proof, leaf);

        ERC1155BaseInternal._mint(to, itemId, amount, "");

        itemsSL.amountClaimed[to][itemId] += amount;
        emit ItemClaimedMerkle(to, itemId, amount);
    }

    function _claimMerkleBatch(address to, uint256[] calldata itemIds, uint[] calldata amounts, bytes32[][] calldata proofs) 
        internal
    {
        if (itemIds.length != amounts.length) 
            revert Items_InputsLengthMistatch();
        
        for (uint256 i = 0; i < itemIds.length; i++) {
            _claimMerkle(to, itemIds[i], amounts[i], proofs[i]);
        }
    }
    
    function _claimWhitelist(uint[] calldata itemIds, uint[] calldata amounts) internal {
        if (itemIds.length != amounts.length) 
            revert Items_InputsLengthMistatch();


        uint totalAmount = 0;
        for (uint i = 0; i < itemIds.length; i++) {
            if (itemIds[i] < 1) 
                revert Items_InvalidItemId();

            ERC1155BaseInternal._mint(msg.sender, itemIds[i], amounts[i], "");
            totalAmount += amounts[i];
        }
        _consumeWhitelist(WhitelistStorage.PoolId.Guaranteed, msg.sender, totalAmount);
    }

    function _claimedAmount(address account, uint itemId) internal view returns (uint) {
        return ItemsStorage.layout().amountClaimed[account][itemId];
    }

    function _mint(address to, uint256 itemId, uint256 amount)
        internal
    {
        if (itemId < 1) revert Items_InvalidItemId();

        ERC1155BaseInternal._mint(to, itemId, amount, "");
    }

    function _mintBatch(address to, uint256[] calldata itemsIds, uint256[] calldata amounts)
        internal
    {
        if (itemsIds.min() < 1) revert Items_InvalidItemId();

        ERC1155BaseInternal._mintBatch(to, itemsIds, amounts, "");
    }

    function _migrateToIPFS(string calldata newBaseURI, bool migrate) internal {
        _setBaseURI(newBaseURI);
        ItemsStorage.layout().isMigratedToIPFS = migrate;
    }

    function _getInventoryAddress() internal view returns (address) {
        return ItemsStorage.layout().inventoryAddress;
    }

    function _setInventoryAddress(address inventoryAddress) internal {
        ItemsStorage.layout().inventoryAddress = inventoryAddress;
    }

    // overrides
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        virtual
        override (ERC1155BaseInternal, ERC1155EnumerableInternal)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

library ItemsStorage {

    bytes32 constant ITEMS_STORAGE_POSITION =
        keccak256("items.storage.position");

    struct Layout {
        // wallet address => token id => is claimed 
        mapping(address => mapping(uint => uint)) amountClaimed;
        bool isMigratedToIPFS;

        // token id => is basic item
        mapping(uint => bool) isBasicItem;
        uint[] basicItemsIds;
        address inventoryAddress;
    }

    function layout()
        internal
        pure
        returns (Layout storage es)
    {
        bytes32 position = ITEMS_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { MerkleProof } from "@solidstate/contracts/cryptography/MerkleProof.sol";
import { MerkleStorage } from "./MerkleStorage.sol";
import { RolesInternal } from "./../roles/RolesInternal.sol";

contract MerkleInternal is RolesInternal {

    error Merkle_AlreadyClaimed();
    error Merkle_InvalidClaimAmount();
    error Merkle_NotIncludedInMerkleTree();
    error Merkle_ClaimInactive();
    error Merkle_ClaimStateAlreadyUpdated();

    function _merkleRoot() internal view returns (bytes32) {
        return MerkleStorage.layout().merkleRoot;
    }

    function _updateMerkleRoot(bytes32 newMerkleRoot) internal {
        MerkleStorage.layout().merkleRoot = newMerkleRoot;
    }

    function _isMerkleClaimActive() view internal returns (bool) {
        return !MerkleStorage.layout().claimInactive;
    }

    function _setMerkleClaimActive() internal {
        MerkleStorage.Layout storage merkleSL = MerkleStorage.layout();

        if (!merkleSL.claimInactive) revert Merkle_ClaimStateAlreadyUpdated();
        
        merkleSL.claimInactive = false;
    }

    function _setMerkleClaimInactive() internal {
        MerkleStorage.Layout storage merkleSL = MerkleStorage.layout();

        if (merkleSL.claimInactive) revert Merkle_ClaimStateAlreadyUpdated();
        
        merkleSL.claimInactive = true;
    }

    // To create 'leaf' use abi.encode(leafProp1, leafProp2, ...)
    function _consumeLeaf(bytes32[] memory proof, bytes memory _leaf) internal {
        MerkleStorage.Layout storage merkleSL = MerkleStorage.layout();

        if (merkleSL.claimInactive) revert Merkle_ClaimInactive();

        // TODO: IMPORTANT: ON PRODUCTION REVERT CHANGED ON ITEMS MERKLE CLAIM, TO AVOID INFINITE CLAIM
        bytes32 proofHash = keccak256(abi.encodePacked(proof));
        // if (merkleSL.claimedProof[proofHash]) revert Merkle_AlreadyClaimed();

        bytes32 leaf = keccak256(bytes.concat(keccak256(_leaf)));
        bool isValid = MerkleProof.verify(proof, merkleSL.merkleRoot, leaf);
        
        if (!isValid) revert Merkle_NotIncludedInMerkleTree();
        
        merkleSL.claimedProof[proofHash] = true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

library MerkleStorage {

    bytes32 constant MERKLE_STORAGE_POSITION =
        keccak256("merkle.storage.position");

    struct Layout {
        bytes32 merkleRoot;
        bool claimInactive;
        mapping(bytes32 => bool) claimedProof;
        mapping(address => uint) amountClaimed;
    }

    function layout()
        internal
        pure
        returns (Layout storage es)
    {
        bytes32 position = MERKLE_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
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

// SPDX-License-Identifier: UNLICENSED
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { WhitelistStorage } from "./WhitelistStorage.sol";
import { RolesInternal } from "./../roles/RolesInternal.sol";

contract WhitelistInternal is RolesInternal {

    error Whitelist_ExceedsElegibleAmount();
    error Whitelist_InputDataMismatch();
    error Whitelist_ClaimStateAlreadyUpdated();
    error Whitelist_ClaimInactive();

    event WhitelistBalanceChanged(address account, WhitelistStorage.PoolId poolId, uint totalElegibleAmount, uint totalClaimedAmount);

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

        if (!whitelistSL.pools[poolId].claimActive)
            revert Whitelist_ClaimInactive();

        if (whitelistSL.pools[poolId].elegible[account] < amount) 
            revert Whitelist_ExceedsElegibleAmount();

        whitelistSL.pools[poolId].elegible[account] -= amount;
        whitelistSL.pools[poolId].claimed[account] += amount;
        whitelistSL.pools[poolId].totalClaimed += amount;
        whitelistSL.pools[poolId].totalElegible -= amount;

        emit WhitelistBalanceChanged(account, poolId, whitelistSL.pools[poolId].elegible[account], whitelistSL.pools[poolId].claimed[account]);
    }

    function _increaseWhitelistElegible(WhitelistStorage.PoolId poolId, address account, uint amount) internal {
        WhitelistStorage.Layout storage whitelistSL = WhitelistStorage.layout();
        whitelistSL.pools[poolId].elegible[account] += amount;
        whitelistSL.pools[poolId].totalElegible += amount;
        
        emit WhitelistBalanceChanged(account, poolId, whitelistSL.pools[poolId].elegible[account], whitelistSL.pools[poolId].claimed[account]);
    }

    function _increaseWhitelistElegibleBatch(WhitelistStorage.PoolId poolId, address[] calldata accounts, uint[] calldata amounts) internal {
        if (accounts.length != amounts.length) revert Whitelist_InputDataMismatch();

        WhitelistStorage.Layout storage whitelistSL = WhitelistStorage.layout();

        for (uint i = 0; i < accounts.length; i++) {
            whitelistSL.pools[poolId].elegible[accounts[i]] += amounts[i];
            whitelistSL.pools[poolId].totalElegible += amounts[i];
            emit WhitelistBalanceChanged(accounts[i], poolId, whitelistSL.pools[poolId].elegible[accounts[i]], whitelistSL.pools[poolId].claimed[accounts[i]]);
        }
    }

    function _setWhitelistElegible(WhitelistStorage.PoolId poolId, address account, uint amount) internal {
        WhitelistStorage.Layout storage whitelistSL = WhitelistStorage.layout();
        whitelistSL.pools[poolId].totalElegible += amount - whitelistSL.pools[poolId].elegible[account];
        whitelistSL.pools[poolId].elegible[account] += amount;
        emit WhitelistBalanceChanged(account, poolId, whitelistSL.pools[poolId].elegible[account], whitelistSL.pools[poolId].claimed[account]);
    }

    function _setWhitelistElegibleBatch(WhitelistStorage.PoolId poolId, address[] calldata accounts, uint[] calldata amounts) internal {
        if (accounts.length != amounts.length) revert Whitelist_InputDataMismatch();

        WhitelistStorage.Layout storage whitelistSL = WhitelistStorage.layout();

        for (uint i = 0; i < accounts.length; i++) {
            whitelistSL.pools[poolId].totalElegible += amounts[i] - whitelistSL.pools[poolId].elegible[accounts[i]];
            whitelistSL.pools[poolId].elegible[accounts[i]] = amounts[i];
            emit WhitelistBalanceChanged(accounts[i], poolId, whitelistSL.pools[poolId].elegible[accounts[i]], whitelistSL.pools[poolId].claimed[accounts[i]]);
        }
    }

    function _isWhitelistClaimActive(WhitelistStorage.PoolId poolId) view internal returns (bool) {
        return WhitelistStorage.layout().pools[poolId].claimActive;
    }

    function _setWhitelistClaimActive(WhitelistStorage.PoolId poolId, bool active) internal {
        WhitelistStorage.Layout storage whitelistSL = WhitelistStorage.layout();

        if (active == whitelistSL.pools[poolId].claimActive) 
            revert Whitelist_ClaimStateAlreadyUpdated();
        
        whitelistSL.pools[poolId].claimActive = active;
    }
}

// SPDX-License-Identifier: UNLICENSED
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