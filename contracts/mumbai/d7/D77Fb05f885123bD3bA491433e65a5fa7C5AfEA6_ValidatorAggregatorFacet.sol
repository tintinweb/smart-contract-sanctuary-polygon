// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

pragma solidity ^0.8.0;

import { IAccessControl } from './IAccessControl.sol';
import { AccessControlInternal } from './AccessControlInternal.sol';

/**
 * @title Role-based access control system
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
abstract contract AccessControl is IAccessControl, AccessControlInternal {
    /**
     * @inheritdoc IAccessControl
     */
    function grantRole(bytes32 role, address account)
        external
        onlyRole(_getRoleAdmin(role))
    {
        _grantRole(role, account);
    }

    /**
     * @inheritdoc IAccessControl
     */
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool)
    {
        return _hasRole(role, account);
    }

    /**
     * @inheritdoc IAccessControl
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32) {
        return _getRoleAdmin(role);
    }

    /**
     * @inheritdoc IAccessControl
     */
    function revokeRole(bytes32 role, address account)
        external
        onlyRole(_getRoleAdmin(role))
    {
        _revokeRole(role, account);
    }

    /**
     * @inheritdoc IAccessControl
     */
    function renounceRole(bytes32 role) external {
        _renounceRole(role);
    }
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

import { IAccessControlInternal } from './IAccessControlInternal.sol';

/**
 * @title AccessControl interface
 */
interface IAccessControl is IAccessControlInternal {
    /*
     * @notice query whether role is assigned to account
     * @param role role to query
     * @param account account to query
     * @return whether role is assigned to account
     */
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    /*
     * @notice query admin role for given role
     * @param role role to query
     * @return admin role
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /*
     * @notice assign role to given account
     * @param role role to assign
     * @param account recipient of role assignment
     */
    function grantRole(bytes32 role, address account) external;

    /*
     * @notice unassign role from given account
     * @param role role to unassign
     * @parm account
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @notice relinquish role
     * @param role role to relinquish
     */
    function renounceRole(bytes32 role) external;
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

import { PausableStorage } from './PausableStorage.sol';

/**
 * @title Internal functions for Pausable security control module.
 */
abstract contract PausableInternal {
    using PausableStorage for PausableStorage.Layout;

    error Pausable__Paused();
    error Pausable__NotPaused();

    event Paused(address account);
    event Unpaused(address account);

    modifier whenNotPaused() {
        if (_paused()) revert Pausable__Paused();
        _;
    }

    modifier whenPaused() {
        if (!_paused()) revert Pausable__NotPaused();
        _;
    }

    /**
     * @notice query the contracts paused state.
     * @return true if paused, false if unpaused.
     */
    function _paused() internal view virtual returns (bool) {
        return PausableStorage.layout().paused;
    }

    /**
     * @notice Triggers paused state, when contract is unpaused.
     */
    function _pause() internal virtual whenNotPaused {
        PausableStorage.layout().paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @notice Triggers unpaused state, when contract is paused.
     */
    function _unpause() internal virtual whenPaused {
        PausableStorage.layout().paused = false;
        emit Unpaused(msg.sender);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library PausableStorage {
    struct Layout {
        bool paused;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Pausable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
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

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

import {IUpfrontManager} from "../upfront/interfaces/IUpfrontManager.sol";

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

import {IUpfrontBaseStorage} from "./IUpfrontBaseStorage.sol";
import {IUpfrontAssetAllocatorInternal} from "./IUpfrontAssetAllocatorInternal.sol";

interface IUpfrontAssetAllocator is IUpfrontAssetAllocatorInternal {
    function getAllocationWeight(IUpfrontBaseStorage.RoleTitle _role_)
        external
        view
        returns (uint8);

    function getRole(address _user_)
        external
        view
        returns (IUpfrontBaseStorage.RoleTitle);

    function getRoleHistory(address _user_)
        external
        view
        returns (IUpfrontBaseStorage.RoleHistory memory);

    function getRoleTitle(uint256 _index_)
        external
        pure
        returns (IUpfrontBaseStorage.RoleTitle);

    function getRolesBalance(IUpfrontBaseStorage.RoleTitle _role_)
        external
        view
        returns (uint256);

    function getRolesCount(IUpfrontBaseStorage.RoleTitle _role_)
        external
        view
        returns (uint256);

    function getSumAllocationWeight() external view returns (uint8);

    function payoutClaimAssessor(
        address _validator_,
        address _currency_,
        uint256 _amount_
    ) external returns (bool, uint256 amountByCurrency);

    function setAllocationWeight(
        IUpfrontBaseStorage.RoleTitle _role_,
        uint8 _allocationWeight_
    ) external;

    function setBatchAllocationWeight(
        IUpfrontBaseStorage.RoleTitle[] memory _role_,
        uint8[] memory _allocationWeight_
    ) external;

    function setRole(address _user_, IUpfrontBaseStorage.RoleTitle _role_)
        external;

    function updateBalance(uint256 _receivedBalance_) external returns (bool);
}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

import {IUpfrontBaseStorage} from "./IUpfrontBaseStorage.sol";

interface IUpfrontAssetAllocatorInternal {
    event AllocationWeightChanged(
        IUpfrontBaseStorage.RoleTitle role,
        uint8 allocationWeight
    );
    event BalanceChanged(
        uint256 receivedBalance,
        uint256 withdrawnBalance,
        uint256 distributorBalance,
        uint256 riskAssessorBalance,
        uint256 claimAssessorBalance,
        uint256 governanceBoardBalance
    );
    event RoleChanged(
        address user,
        IUpfrontBaseStorage.RoleTitle previousRole,
        IUpfrontBaseStorage.RoleTitle currentRole
    );
}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

interface IUpfrontBaseStorage {
    enum RoleTitle {
        None,
        Distributor,
        RiskAssessor,
        ClaimAssessor,
        GovernanceBoard
    }

    struct RoleHistory {
        RoleTitle currentRole;
        RoleTitle previousRole;
    }

    function GENERAL_MANAGER_LEVEL() external view returns (bytes32);

    function INSURANCE_MANAGER_LEVEL() external view returns (bytes32);

    function SUPER_MANAGER_LEVEL() external view returns (bytes32);

    function VALIDATOR_MANAGER_LEVEL() external view returns (bytes32);
}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

import {IUpfrontAssetAllocator} from "./IUpfrontAssetAllocator.sol";

interface IUpfrontManager is IUpfrontAssetAllocator {}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

import {IValidatorBaseStorage} from "../interfaces/IValidatorBaseStorage.sol";

library ValidatorBaseStorage {
    struct Layout {
        address miToken;
        address upfrontManager;
        address[] validators;
        uint256 totalReward;
        uint256 totalStaked; //* Finished *//
        uint256 totalPenaltyStake; //! Waiting for claim challenge !//
        uint256 totalPoint; //! Waiting for claim assessment !//
        uint256 totalPenaltyPoint; //! Waiting for claim challenge !//
        uint256 totalOnHold; //* Finished *//
        IValidatorBaseStorage.ValidatorRules validatorRules;
        IValidatorBaseStorage.ValidatorCalculationRules validatorCalculationRules;
        IValidatorBaseStorage.StakingRules stakingRules;
        //* is the validator has a whitelist to stake or not => true or false *//
        mapping(address => bool) isValidatorWhitelist;
        mapping(address => bool) isCurrentAndFormerValidator;
        mapping(uint256 => bool) isVotingVoucherExist;
        /* claimId => VotingVoucher struct */
        mapping(uint256 => IValidatorBaseStorage.VotingVoucher) ClaimCaseVotingVouchers;
        mapping(uint256 => mapping(address => IValidatorBaseStorage.ClaimValidatorVote)) ValidatorVoteByVotingVouchers;
        mapping(address => IValidatorBaseStorage.SlashVoucher[]) ValidatorSlashVouchers;
        /**
         * The isValidator mapping is being used to store whether a given address has staked the minimum amount required to become a validator.
         * If an address is a validator, the corresponding value in the mapping will be true,
         * and if it is not a validator, the value will be false.
         */
        mapping(address => bool) isValidator;
        //* validator take leave or not => true or false *//
        mapping(address => bool) isValidatorPausedWork;
        //* validator & voter => validator's reward(decimals 18) *//
        mapping(address => uint256) validatorRewards;
        //* validator & voter => currency => validator's reward(deciamls of currency) *//
        mapping(address => mapping(address => uint256)) validatorRewardsByCurrency;
        //* validator =>  validatorPoint that will increase when claim Assessment is finished *//
        mapping(address => IValidatorBaseStorage.ValidatorPoint) validatorPoints;
        //* validator => index of validator in validators array *//
        mapping(address => uint256) validatorIndex;
        //* validator => staking balance of validator *//
        mapping(address => IValidatorBaseStorage.StakingBalance) validatorStakingBalance;
    }

    bytes32 internal constant SUPER_MANAGER_LEVEL =
        keccak256("SUPER_MANAGER_LEVEL");

    bytes32 internal constant GENERAL_MANAGER_LEVEL =
        keccak256("GENERAL_MANAGER_LEVEL");

    bytes32 internal constant GOVERANACE_BOARD_LEVEL =
        keccak256("GOVERANACE_BOARD_LEVEL");

    bytes32 internal constant INSURANCE_MANAGER_LEVEL =
        keccak256("INSURANCE_MANAGER_LEVEL");

    bytes32 internal constant STORAGE_SLOT =
        keccak256("covest.contracts.upfront.storage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 position = STORAGE_SLOT;
        assembly {
            l.slot := position
        }
    }
}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

import {IValidatorBaseStorage} from "./IValidatorBaseStorage.sol";
import {IValidatorAggregatorInternal} from "./IValidatorAggregatorInternal.sol";

interface IValidatorAggregator is IValidatorAggregatorInternal {
    function createVotingVoucher(uint256 _claimId_) external returns (bool);

    function getTotalPenaltyPoint() external view returns (uint256);

    function getTotalPoint() external view returns (uint256);

    function getValidatorCalculationRules()
        external
        view
        returns (IValidatorBaseStorage.ValidatorCalculationRules memory);

    function getValidatorCount() external view returns (uint256);

    function getValidatorPoint(address _validator_)
        external
        view
        returns (IValidatorBaseStorage.ValidatorPoint memory);

    function getValidatorVote(uint256 _claimId_, address _validator_)
        external
        view
        returns (IValidatorBaseStorage.ClaimValidatorVote memory);

    function getValidatorVoteList(
        uint256 _claimId_,
        uint256 _page_,
        uint256 _size_
    )
        external
        view
        returns (
            IValidatorBaseStorage.ClaimValidatorVote[] memory _votes_,
            uint256 newPage
        );

    function getValidators(uint256 _page_, uint256 _size_)
        external
        view
        returns (address[] memory _validators_, uint256 newPage);

    function getVotingVoucher(uint256 _claimId_)
        external
        view
        returns (IValidatorBaseStorage.VotingVoucher memory);

    function increasePoint(address _validator_, uint256 _point_)
        external
        returns (bool);

    function increaseReward(
        address _validator_,
        address _currency_,
        uint256 _reward_
    ) external returns (bool);

    function payoutValidatorReward(address _currency_, uint256 _reward_)
        external
        returns (bool);

    function selectValidator(uint256 _claimAmount_)
        external
        view
        returns (address);

    function setUpfrontManager(address _addr_) external;

    function setValidatorCalculationRules(
        IValidatorBaseStorage.ValidatorCalculationRules memory _vcr_
    ) external;

    function setValidatorRules(IValidatorBaseStorage.ValidatorRules memory _vr_)
        external;

    function slash(
        address _validator_,
        IValidatorBaseStorage.SlashVoucher memory _vsv_
    ) external returns (bool);

    function validatorPauseWork(bool _isPause_) external;

    function voteVoucher(
        uint256 _claimId_,
        address _validator_,
        bool _isAccepted_
    ) external returns (bool);

    function workStatus(address _validator_) external view returns (bool);
}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

import {IValidatorBaseStorage} from "./IValidatorBaseStorage.sol";

interface IValidatorAggregatorInternal {
    event Slashed(
        address indexed validator,
        IValidatorBaseStorage.SlashVoucher slashVoucher
    );

    event ValidatorPausedWork(address indexed validator, bool isPause);

    event ValidatorCalcuationRulesChanged(
        IValidatorBaseStorage.ValidatorCalculationRules validatorCalculationRules
    );

    event ValidatorRulesChanged(
        IValidatorBaseStorage.ValidatorRules validatorRules
    );

    event PointChanged(address indexed validator, uint256 amount);

    event RewardChanged(
        address indexed validator,
        address indexed currency,
        uint256 amount
    );

    event VotingVoucherCreated(
        uint256 indexed claimId,
        uint256 totalPower,
        uint256 totalValidatorCount
    );

    event VotingVoucherUpdated(
        uint256 indexed claimId,
        address indexed validator,
        bool isAccepted
    );

    event ValidatorRewardPaid(
        address indexed validator,
        address indexed currency,
        uint256 reward,
        uint256 rewardByCurrency
    );

    event UpfrontManagerChanged(address indexed upfrontManager);
}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

interface IValidatorBaseStorage {
    struct ValidatorPoint {
        uint256 point;
        uint256 penalty; // penalty of the point that will calculate to select the validator for the claim //
    }

    struct ValidatorSelection {
        address validator;
        uint256 score;
    }

    struct ValidatorRules {
        uint256 initialPoint;
    }

    struct ValidatorCalculationRules {
        uint8 weightCapacity;
        uint8 weightReputation;
        uint8 weightRandomness;
    }

    struct StakingRules {
        uint256 minStake;
        uint256 maxStake;
    }

    struct StakingBalance {
        uint256 staked; // amount //
        uint256 onHold; // amount //
        uint256 penalty; // amount //
        uint40 lastUpdate;
    }

    struct ClaimValidatorVote {
        bool isVoted;
        bool isAccepted;
        bool isVoter;
        uint256 power;
    }

    struct VotingVoucher {
        uint256 totalPower;
        uint256 totalCount;
        uint256 validatorOnHold;
        uint256 totalAcceptedPower;
        uint256 totalAcceptedCount;
        uint256 totalRejectedPower;
        uint256 totalRejectedCount;
        address[] validators;
    }

    struct SlashVoucher {
        uint256 penaltyStake;
        uint256 penaltyPoint;
        string reason;
        string validatedData;
    }

    function GENERAL_MANAGER_LEVEL() external view returns (bytes32);

    function INSURANCE_MANAGER_LEVEL() external view returns (bytes32);

    function SUPER_MANAGER_LEVEL() external view returns (bytes32);

    function VALIDATOR_MANAGER_LEVEL() external view returns (bytes32);
}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

import {ValidatorBaseStorage} from "../base/ValidatorBaseStorage.sol";
import {IUpfrontManager} from "../../interfaces/IUpfrontManager.sol";
import {IValidatorBaseStorage} from "../interfaces/IValidatorBaseStorage.sol";
import {IValidatorAggregatorInternal} from "../interfaces/IValidatorAggregatorInternal.sol";
import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC20MetadataUpgradeable.sol";

abstract contract ValidatorAggregatorInternalFacet is
    IValidatorAggregatorInternal
{
    using ValidatorBaseStorage for ValidatorBaseStorage.Layout;

    modifier onlyValidatorWhiteListed() {
        require(
            ValidatorBaseStorage.layout().isValidatorWhitelist[msg.sender],
            "notWhitelisted"
        );
        _;
    }

    modifier onlyValidator() {
        ValidatorBaseStorage.Layout storage _vbs_ = ValidatorBaseStorage
            .layout();

        IValidatorBaseStorage.StakingBalance memory _sb_ = _vbs_
            .validatorStakingBalance[msg.sender];

        require(
            ValidatorBaseStorage.layout().isValidator[msg.sender],
            "notValidator"
        );

        require(_sb_.staked - _sb_.penalty - _sb_.onHold > 0, "payPenalty");
        _;
    }

    function _setValidatorCalculationRules(
        IValidatorBaseStorage.ValidatorCalculationRules memory _vcr_
    ) internal {
        require(
            _vcr_.weightCapacity +
                _vcr_.weightReputation +
                _vcr_.weightRandomness ==
                100,
            "IVCR"
        );

        ValidatorBaseStorage.layout().validatorCalculationRules = _vcr_;

        emit ValidatorCalcuationRulesChanged(
            IValidatorBaseStorage.ValidatorCalculationRules(
                _vcr_.weightCapacity,
                _vcr_.weightReputation,
                _vcr_.weightRandomness
            )
        );
    }

    function _increaseReward(
        address _validator_,
        address _currency_,
        uint256 _reward_
    ) internal {
        ValidatorBaseStorage.Layout storage _vbs_ = ValidatorBaseStorage
            .layout();

        _vbs_.totalReward += _reward_;
        _vbs_.validatorRewards[_validator_] += _reward_;

        _vbs_.validatorRewardsByCurrency[_validator_][_currency_] += _reward_;

        emit RewardChanged(_validator_, _currency_, _reward_);
    }

    /*
     * @parameter _currency_ address of currency
     * @parameter _reward_ reward amount(decimals 18)
     */
    function _payoutValidatorReward(address _currency_, uint256 _reward_)
        internal
    {
        ValidatorBaseStorage.Layout storage _vbs_ = ValidatorBaseStorage
            .layout();

        require(_vbs_.validatorRewards[msg.sender] >= _reward_, "IR");

        require(
            _vbs_.validatorRewardsByCurrency[msg.sender][_currency_] >=
                _reward_,
            "IRBC"
        );

        _vbs_.validatorRewards[msg.sender] -= _reward_;
        _vbs_.validatorRewardsByCurrency[msg.sender][_currency_] -= _reward_;
        _vbs_.totalReward -= _reward_;

        (bool _success_, uint256 _rewardByCurrency_) = IUpfrontManager(
            _vbs_.upfrontManager
        ).payoutClaimAssessor(msg.sender, _currency_, _reward_);

        require(_success_, "PayoutFailed");

        emit ValidatorRewardPaid(
            msg.sender,
            _currency_,
            _reward_,
            _rewardByCurrency_
        );
    }

    function _setValidatorRules(
        IValidatorBaseStorage.ValidatorRules memory _vr_
    ) internal {
        ValidatorBaseStorage.layout().validatorRules = _vr_;
        emit ValidatorRulesChanged(_vr_);
    }

    function _getValidatorCalculationRules()
        internal
        view
        returns (IValidatorBaseStorage.ValidatorCalculationRules memory)
    {
        return ValidatorBaseStorage.layout().validatorCalculationRules;
    }

    function _increasePoint(address _validator_, uint256 _point_) internal {
        ValidatorBaseStorage.Layout storage _vbs_ = ValidatorBaseStorage
            .layout();

        _vbs_.totalPoint += _point_;
        _vbs_.validatorPoints[_validator_].point += _point_;

        emit PointChanged(_validator_, _point_);
    }

    function _validatorPauseWork(bool _isPause_) internal {
        ValidatorBaseStorage.layout().isValidatorPausedWork[
            msg.sender
        ] = _isPause_;

        emit ValidatorPausedWork(msg.sender, _isPause_);
    }

    function _workStatus(address _validator_)
        internal
        view
        returns (bool _isPause_)
    {
        return ValidatorBaseStorage.layout().isValidatorPausedWork[_validator_];
    }

    function _setUpfrontManager(address _upfrontManager_) internal {
        ValidatorBaseStorage.layout().upfrontManager = _upfrontManager_;
        emit UpfrontManagerChanged(_upfrontManager_);
    }

    function _selectValidator(uint256 _claimAmount_)
        internal
        view
        returns (address)
    {
        ValidatorBaseStorage.Layout storage _vbs_ = ValidatorBaseStorage
            .layout();

        if (_vbs_.validators.length == 0) {
            return address(0);
        }

        IValidatorBaseStorage.ValidatorSelection memory _vs_;

        for (uint256 i = 0; i < _vbs_.validators.length; i++) {
            if (_vbs_.isValidatorPausedWork[_vbs_.validators[i]] == true) {
                continue;
            }

            IValidatorBaseStorage.StakingBalance memory _sb_ = _vbs_
                .validatorStakingBalance[_vbs_.validators[i]];

            if (_sb_.staked - _sb_.penalty - _sb_.onHold < _claimAmount_) {
                continue;
            }

            IValidatorBaseStorage.ValidatorPoint memory _vp_ = _vbs_
                .validatorPoints[_vbs_.validators[i]];

            int256 _capacity_ = int256(
                (_sb_.staked - _sb_.penalty - _sb_.onHold) / _vbs_.totalStaked
            );

            int256 _reputation_ = int256(
                (_vp_.point - _vp_.penalty) / _vbs_.totalPoint
            );

            uint256 _randomness_ = (
                uint256(
                    keccak256(
                        abi.encodePacked(
                            _capacity_,
                            _reputation_,
                            block.timestamp,
                            block.difficulty,
                            block.number,
                            block.coinbase,
                            block.gaslimit,
                            block.timestamp,
                            block.chainid
                        )
                    )
                )
            ) % 2;

            uint256 _score_ = uint256(
                (_capacity_ *
                    int8(_vbs_.validatorCalculationRules.weightCapacity)) +
                    (_reputation_ *
                        int8(
                            _vbs_.validatorCalculationRules.weightReputation
                        )) +
                    (int256(_randomness_) *
                        int8(_vbs_.validatorCalculationRules.weightRandomness))
            );

            if (_score_ > _vs_.score) {
                _vs_ = IValidatorBaseStorage.ValidatorSelection({
                    score: _score_,
                    validator: _vbs_.validators[i]
                });
            } else if (_score_ == _vs_.score) {
                if (
                    _vbs_.validatorIndex[_vbs_.validators[i]] >
                    _vbs_.validatorIndex[_vs_.validator]
                ) {
                    _vs_ = IValidatorBaseStorage.ValidatorSelection({
                        score: _score_,
                        validator: _vbs_.validators[i]
                    });
                }
            }
        }

        //! Warning : If there is no validator or all the validator pause their work, it will return the address(0) value.
        return _vs_.validator;
    }

    function _slash(
        address _validator_,
        IValidatorBaseStorage.SlashVoucher memory _vsv_
    ) internal {
        ValidatorBaseStorage.Layout storage _vbs_ = ValidatorBaseStorage
            .layout();

        //* Penalty Of Staking Balance *//
        _vbs_.validatorStakingBalance[_validator_].penalty += _vsv_
            .penaltyStake;

        //* Penalty Of Point *//
        _vbs_.validatorPoints[_validator_].penalty += _vsv_.penaltyPoint;

        _vbs_.ValidatorSlashVouchers[_validator_].push(_vsv_);

        emit Slashed(_validator_, _vsv_);
    }

    function _createVotingVoucher(uint256 _claimId_) internal {
        ValidatorBaseStorage.Layout storage _vbs_ = ValidatorBaseStorage
            .layout();

        require(_vbs_.isVotingVoucherExist[_claimId_] == false, "VVIE");

        IValidatorBaseStorage.VotingVoucher storage _vv_ = _vbs_
            .ClaimCaseVotingVouchers[_claimId_];

        _vbs_.isVotingVoucherExist[_claimId_] = true;

        _vv_.totalPower =
            _vbs_.totalStaked -
            _vbs_.totalOnHold -
            _vbs_.totalPenaltyStake;

        _vv_.totalCount = _vbs_.validators.length;

        for (uint256 i = 0; i < _vbs_.validators.length; i++) {
            uint256 _validatorPower_ = _vbs_
                .validatorStakingBalance[_vbs_.validators[i]]
                .staked -
                _vbs_.validatorStakingBalance[_vbs_.validators[i]].onHold -
                _vbs_.validatorStakingBalance[_vbs_.validators[i]].penalty;

            if (_vbs_.isValidatorPausedWork[_vbs_.validators[i]] == true) {
                _vv_.totalPower -= _validatorPower_;
                _vv_.totalCount -= 1;
            } else {
                _vv_.validators.push(_vbs_.validators[i]);
                _vbs_.ValidatorVoteByVotingVouchers[_claimId_][
                        _vbs_.validators[i]
                    ] = IValidatorBaseStorage.ClaimValidatorVote(
                    false,
                    false,
                    true,
                    _validatorPower_
                );
            }
        }

        emit VotingVoucherCreated(_claimId_, _vv_.totalPower, _vv_.totalCount);
    }

    function _voteVoucher(
        uint256 _claimId_,
        address _validator_,
        bool _isAccepted_
    ) internal {
        ValidatorBaseStorage.Layout storage _vbs_ = ValidatorBaseStorage
            .layout();

        IValidatorBaseStorage.ClaimValidatorVote storage _cvv_ = _vbs_
            .ValidatorVoteByVotingVouchers[_claimId_][_validator_];

        IValidatorBaseStorage.VotingVoucher storage _vv_ = _vbs_
            .ClaimCaseVotingVouchers[_claimId_];

        require(_vbs_.isVotingVoucherExist[_claimId_] == true, "NFVV");
        require(_cvv_.isVoted == false, "VOTED");

        if (_isAccepted_ == true) {
            _vv_.totalAcceptedPower += _cvv_.power;
            _vv_.totalAcceptedCount++;
        } else {
            _vv_.totalRejectedPower += _cvv_.power;
            _vv_.totalRejectedCount++;
        }

        _cvv_.isVoted = true;
        _cvv_.isAccepted = _isAccepted_;

        emit VotingVoucherUpdated(_claimId_, _validator_, _isAccepted_);
    }

    function _getVotingVoucher(uint256 _claimId_)
        internal
        view
        returns (IValidatorBaseStorage.VotingVoucher memory)
    {
        return ValidatorBaseStorage.layout().ClaimCaseVotingVouchers[_claimId_];
    }

    function _getValidatorVote(uint256 _claimId_, address _validator_)
        internal
        view
        returns (IValidatorBaseStorage.ClaimValidatorVote memory)
    {
        ValidatorBaseStorage.Layout storage _vbs_ = ValidatorBaseStorage
            .layout();

        return _vbs_.ValidatorVoteByVotingVouchers[_claimId_][_validator_];
    }

    function _getValidatorVoteList(
        uint256 _claimId_,
        uint256 _page_,
        uint256 _size_
    )
        internal
        view
        returns (
            IValidatorBaseStorage.ClaimValidatorVote[] memory _votes_,
            uint256 newPage
        )
    {
        ValidatorBaseStorage.Layout storage _vbs_ = ValidatorBaseStorage
            .layout();

        IValidatorBaseStorage.VotingVoucher memory _vv_ = _vbs_
            .ClaimCaseVotingVouchers[_claimId_];

        uint256 length = _size_;
        if (length > _vv_.totalCount - _page_) {
            length = _vv_.totalCount - _page_;
        }

        _votes_ = new IValidatorBaseStorage.ClaimValidatorVote[](length);

        for (uint256 i = 0; i < length; i++) {
            _votes_[i] = _vbs_.ValidatorVoteByVotingVouchers[_claimId_][
                _vv_.validators[_page_ + i]
            ];
        }

        return (_votes_, _page_ + length);
    }

    function _getValidators(uint256 _page_, uint256 _size_)
        internal
        view
        returns (address[] memory _validators_, uint256 newPage)
    {
        ValidatorBaseStorage.Layout storage _vbs_ = ValidatorBaseStorage
            .layout();

        uint256 length = _size_;
        if (length > _vbs_.validators.length - _page_) {
            length = _vbs_.validators.length - _page_;
        }

        _validators_ = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            _validators_[i] = _vbs_.validators[_page_ + i];
        }

        return (_validators_, _page_ + length);
    }

    function _getValidatorPoint(address _validator_)
        internal
        view
        returns (IValidatorBaseStorage.ValidatorPoint memory)
    {
        ValidatorBaseStorage.Layout storage _vbs_ = ValidatorBaseStorage
            .layout();

        return _vbs_.validatorPoints[_validator_];
    }

    function _getValidatorCount() internal view returns (uint256) {
        return (ValidatorBaseStorage.layout().validators.length);
    }

    function _getTotalPoint() internal view returns (uint256) {
        return ValidatorBaseStorage.layout().totalPoint;
    }

    function _getTotalPenaltyPoint() internal view returns (uint256) {
        return ValidatorBaseStorage.layout().totalPenaltyPoint;
    }
}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

import {ValidatorBaseStorage} from "./base/ValidatorBaseStorage.sol";
import {IValidatorBaseStorage} from "./interfaces/IValidatorBaseStorage.sol";
import {IValidatorAggregator} from "./interfaces/IValidatorAggregator.sol";
import {ValidatorAggregatorInternalFacet} from "./internal/ValidatorAggregatorInternalFacet.sol";
import {AccessControlInternal} from "@solidstate/contracts/access/access_control/AccessControl.sol";
import {ReentrancyGuard} from "@solidstate/contracts/utils/ReentrancyGuard.sol";
import {PausableInternal} from "@solidstate/contracts/security/PausableInternal.sol";

contract ValidatorAggregatorFacet is
    ValidatorAggregatorInternalFacet,
    AccessControlInternal,
    ReentrancyGuard,
    PausableInternal,
    IValidatorAggregator
{
    using ValidatorBaseStorage for ValidatorBaseStorage.Layout;

    function setValidatorCalculationRules(
        IValidatorBaseStorage.ValidatorCalculationRules memory _vcr_
    ) public onlyRole(ValidatorBaseStorage.SUPER_MANAGER_LEVEL) {
        _setValidatorCalculationRules(_vcr_);
    }

    function setValidatorRules(IValidatorBaseStorage.ValidatorRules memory _vr_)
        public
        onlyRole(ValidatorBaseStorage.SUPER_MANAGER_LEVEL)
    {
        _setValidatorRules(_vr_);
    }

    function getValidatorCalculationRules()
        public
        view
        returns (IValidatorBaseStorage.ValidatorCalculationRules memory)
    {
        return _getValidatorCalculationRules();
    }

    function increasePoint(address _validator_, uint256 _point_)
        public
        nonReentrant
        whenNotPaused
        onlyRole(ValidatorBaseStorage.INSURANCE_MANAGER_LEVEL)
        returns (bool)
    {
        _increasePoint(_validator_, _point_);
        return true;
    }

    function increaseReward(
        address _validator_,
        address _currency_,
        uint256 _reward_
    )
        public
        nonReentrant
        whenNotPaused
        onlyRole(ValidatorBaseStorage.INSURANCE_MANAGER_LEVEL)
        returns (bool)
    {
        _increaseReward(_validator_, _currency_, _reward_);
        return true;
    }

    function selectValidator(uint256 _claimAmount_)
        public
        view
        returns (address)
    {
        return _selectValidator(_claimAmount_);
    }

    function setUpfrontManager(address _addr_)
        public
        onlyRole(ValidatorBaseStorage.SUPER_MANAGER_LEVEL)
    {
        _setUpfrontManager(_addr_);
    }

    function payoutValidatorReward(address _currency_, uint256 _reward_)
        public
        nonReentrant
        whenNotPaused
        onlyValidator
        returns (bool)
    {
        _payoutValidatorReward(_currency_, _reward_);
        return true;
    }

    function validatorPauseWork(bool _isPause_)
        public
        nonReentrant
        whenNotPaused
        onlyValidator
    {
        _validatorPauseWork(_isPause_);
    }

    function workStatus(address _validator_) public view returns (bool) {
        return _workStatus(_validator_);
    }

    function getValidatorCount() public view returns (uint256) {
        return _getValidatorCount();
    }

    function getTotalPoint() public view returns (uint256) {
        return _getTotalPoint();
    }

    function getTotalPenaltyPoint() public view returns (uint256) {
        return _getTotalPenaltyPoint();
    }

    function slash(
        address _validator_,
        IValidatorBaseStorage.SlashVoucher memory _vsv_
    )
        public
        nonReentrant
        whenNotPaused
        onlyRole(ValidatorBaseStorage.GOVERANACE_BOARD_LEVEL)
        returns (bool)
    {
        _slash(_validator_, _vsv_);
        return true;
    }

    function getValidators(uint256 _page_, uint256 _size_)
        public
        view
        returns (address[] memory _validators_, uint256 newPage)
    {
        return _getValidators(_page_, _size_);
    }

    function getValidatorPoint(address _validator_)
        public
        view
        returns (IValidatorBaseStorage.ValidatorPoint memory)
    {
        return _getValidatorPoint(_validator_);
    }

    function getVotingVoucher(uint256 _claimId_)
        public
        view
        returns (IValidatorBaseStorage.VotingVoucher memory)
    {
        return _getVotingVoucher(_claimId_);
    }

    function createVotingVoucher(uint256 _claimId_)
        public
        nonReentrant
        whenNotPaused
        onlyRole(ValidatorBaseStorage.INSURANCE_MANAGER_LEVEL)
        returns (bool)
    {
        _createVotingVoucher(_claimId_);
        return true;
    }

    function voteVoucher(
        uint256 _claimId_,
        address _validator_,
        bool _isAccepted_
    )
        public
        nonReentrant
        whenNotPaused
        onlyRole(ValidatorBaseStorage.INSURANCE_MANAGER_LEVEL)
        returns (bool)
    {
        _voteVoucher(_claimId_, _validator_, _isAccepted_);
        return true;
    }

    function getValidatorVote(uint256 _claimId_, address _validator_)
        public
        view
        returns (IValidatorBaseStorage.ClaimValidatorVote memory)
    {
        return _getValidatorVote(_claimId_, _validator_);
    }

    function getValidatorVoteList(
        uint256 _claimId_,
        uint256 _page_,
        uint256 _size_
    )
        public
        view
        returns (
            IValidatorBaseStorage.ClaimValidatorVote[] memory _votes_,
            uint256 newPage
        )
    {
        return _getValidatorVoteList(_claimId_, _page_, _size_);
    }
}