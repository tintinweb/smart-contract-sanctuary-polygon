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

import {IRiskCarrierBaseStorage} from "../interfaces/IRiskCarrierBaseStorage.sol";

library RiskCarrierBaseStorage {
    struct Layout {
        //* poolId => RiskCarrierController //
        mapping(string => IRiskCarrierBaseStorage.RiskCarrierController[]) riskCarrierControllerListByPool;
        //* poolId => Address of RiskCarrierController => number of index //
        mapping(string => mapping(address => uint256)) riskCarrierControllerListIndexByPool;
        //* poolId => policyId => RiskCarrierController //
        mapping(string => mapping(string => IRiskCarrierBaseStorage.RiskCarrierController[])) riskCarrierControllerListByPolicy;
        //* poolId => address of RiskCarrierController //
        mapping(string => mapping(address => bool)) isExistByPoolId;
        //* poolId => Trusted Address fot RiskCarrierController //
        mapping(string => mapping(address => bool)) trustedCaller;
    }

    bytes32 internal constant SUPER_MANAGER_LEVEL =
        keccak256("SUPER_MANAGER_LEVEL");

    bytes32 internal constant GENERAL_MANAGER_LEVEL =
        keccak256("GENERAL_MANAGER_LEVEL");

    bytes32 private constant STORAGE_POSITION =
        keccak256("covest.contracts.riskCarrierurer.Storage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

interface IRiskCarrierBaseStorage {
    struct RiskCarrierController {
        address addr;
        string name;
    }

    struct RiskCarrierControllerWithRiskTransferRatio {
        address addr;
        string name;
        uint8 riskTransferRatio;
    }

    struct RiskTransferParams {
        string name;
        bytes params;
    }

    struct RiskCarrierControllerListForMultiGroup {
        RiskCarrierController[] riskCarrierControllerList;
    }

    function GENERAL_MANAGER_LEVEL() external view returns (bytes32);

    function SUPER_MANAGER_LEVEL() external view returns (bytes32);
}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

interface IRiskCarrierController {
    enum RiskCarrierPolicyStatus {
        Notinsured,
        Active,
        Expired,
        Redeemed,
        Claimed
    }

    function issuePolicy(string memory _policyId_, bytes memory _params_)
        external
        returns (bool);

    function claimPolicy(
        string memory _policyId_,
        address _caller_,
        uint256 _claimAmount_
    ) external returns (bool);

    function redeemPolicy(
        string memory _policyId_,
        address _caller_,
        uint256 _redeemAmount_
    ) external returns (bool);

    function decimals() external view returns (uint8);

    function riskTransferRatio() external view returns (uint8);

    function getPolicyIds(uint256 _page_, uint256 _limit_)
        external
        view
        returns (string[] memory policyIds, uint256 newPage);

    function getCountPolicyStatus(RiskCarrierPolicyStatus _status_)
        external
        view
        returns (uint256 amount);

    function getPoliciesStatus(string[] memory _policyId_)
        external
        view
        returns (RiskCarrierPolicyStatus[] memory status);

    function getPolicyIdByIndex(uint256 _index_)
        external
        view
        returns (string memory policyId);

    function getPolicyStatus(string memory _policyId_)
        external
        view
        returns (RiskCarrierPolicyStatus status);

    function getRiskCarrierNCP(bytes memory _ensuroParams)
        external
        view
        returns (
            string memory _name_,
            address _currency_,
            uint256 _premium_
        );
}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

import {IRiskCarrierBaseStorage} from "./IRiskCarrierBaseStorage.sol";
import {IRiskCarrierRouterInternal} from "./IRiskCarrierRouterInternal.sol";

interface IRiskCarrierRouter is IRiskCarrierRouterInternal {
    function claimRiskCarrierPolicy(
        string memory _poolId_,
        string memory _policyId_,
        uint256 _claimAmount_
    ) external returns (bool);

    function decimals() external pure returns (uint8);

    function issueRiskCarrierPolicy(
        string memory _poolId_,
        string memory _policyId_,
        IRiskCarrierBaseStorage.RiskTransferParams[] memory _params_
    ) external returns (bool);

    function redeemRiskCarrierPolicy(
        string memory _poolId_,
        string memory _policyId_,
        uint256 _redeemAmount_
    ) external returns (bool);
}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

interface IRiskCarrierRouterInternal {
    event ClaimRiskCarrierPolicy(
        string indexed poolId,
        string indexed policyId,
        uint256 claimAmount
    );
    event IssueRiskCarrierPolicy(
        string indexed poolId,
        string indexed policyId
    );
    event RedeemRiskCarrierPolicy(
        string indexed poolId,
        string indexed policyId,
        uint256 redeemAmount
    );
}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

import {RiskCarrierBaseStorage} from "../base/RiskCarrierBaseStorage.sol";
import {IRiskCarrierBaseStorage} from "../interfaces/IRiskCarrierBaseStorage.sol";
import {IRiskCarrierRouterInternal} from "../interfaces/IRiskCarrierRouterInternal.sol";
import {IRiskCarrierController} from "../interfaces/IRiskCarrierController.sol";
import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC20MetadataUpgradeable.sol";

abstract contract RiskCarrierRouterInternalFacet is IRiskCarrierRouterInternal {
    using RiskCarrierBaseStorage for RiskCarrierBaseStorage.Layout;

    modifier onlyTrustedCaller(string memory _poolId_, address _addr_) {
        require(
            RiskCarrierBaseStorage.layout().trustedCaller[_poolId_][_addr_],
            "notCaller"
        );
        _;
    }

    function _decimals() internal pure returns (uint8) {
        return 18;
    }

    function _issueRiskCarrierPolicy(
        string memory _poolId_,
        string memory _policyId_,
        IRiskCarrierBaseStorage.RiskTransferParams[] memory _rtp_
    ) internal {
        RiskCarrierBaseStorage.Layout storage _rbs_ = RiskCarrierBaseStorage
            .layout();

        require(
            _rbs_.riskCarrierControllerListByPool[_poolId_].length > 0,
            "Not found."
        );

        require(
            _rtp_.length ==
                _rbs_.riskCarrierControllerListByPool[_poolId_].length,
            "IP"
        );

        for (
            uint256 i = 0;
            i < _rbs_.riskCarrierControllerListByPool[_poolId_].length;
            i++
        ) {
            IRiskCarrierBaseStorage.RiskCarrierController
                memory _riskCarrierManagerListByPoolWithIndex_ = _rbs_
                    .riskCarrierControllerListByPool[_poolId_][i];

            IRiskCarrierController _RiskCarrierController_ = IRiskCarrierController(
                    _riskCarrierManagerListByPoolWithIndex_.addr
                );

            (
                string memory _name_,
                address _currencyAddress_,
                uint256 _riskCarrierPremium_
            ) = _RiskCarrierController_.getRiskCarrierNCP(_rtp_[i].params);

            require(
                keccak256(bytes(_rtp_[i].name)) == keccak256(bytes(_name_)),
                "NOTMATCH"
            );

            IERC20MetadataUpgradeable _currency_ = IERC20MetadataUpgradeable(
                _currencyAddress_
            );

            require(
                _currency_.balanceOf(address(this)) >= _riskCarrierPremium_,
                "IB"
            );

            require(
                _currency_.transfer(
                    _riskCarrierManagerListByPoolWithIndex_.addr,
                    _riskCarrierPremium_
                ),
                "CTTRM"
            );

            require(
                _RiskCarrierController_.issuePolicy(
                    _policyId_,
                    _rtp_[i].params
                ),
                string(
                    abi.encodePacked(
                        "IPFA: ",
                        _riskCarrierManagerListByPoolWithIndex_.name
                    )
                )
            );

            _rbs_.riskCarrierControllerListByPolicy[_poolId_][_policyId_].push(
                _riskCarrierManagerListByPoolWithIndex_
            );
        }

        emit IssueRiskCarrierPolicy(_poolId_, _policyId_);
    }

    function _claimRiskCarrierPolicy(
        string memory _poolId_,
        string memory _policyId_,
        uint256 _claimAmount_ //? decimals 18 ?//
    ) internal {
        RiskCarrierBaseStorage.Layout storage _rbs_ = RiskCarrierBaseStorage
            .layout();

        require(
            _rbs_
            .riskCarrierControllerListByPolicy[_poolId_][_policyId_].length > 0,
            "Not found."
        );

        for (
            uint256 i = 0;
            i <
            _rbs_
            .riskCarrierControllerListByPolicy[_poolId_][_policyId_].length;
            i++
        ) {
            IRiskCarrierBaseStorage.RiskCarrierController
                memory _riskCarrierManagerListByPolicyWithIndex_ = _rbs_
                    .riskCarrierControllerListByPolicy[_poolId_][_policyId_][i];

            IRiskCarrierController _RiskCarrierController_ = IRiskCarrierController(
                    _riskCarrierManagerListByPolicyWithIndex_.addr
                );

            require(
                _RiskCarrierController_.claimPolicy(
                    _policyId_,
                    msg.sender,
                    _claimAmount_ /
                        10**(_decimals() - _RiskCarrierController_.decimals())
                ),
                string(
                    abi.encodePacked(
                        "CPFA: ",
                        _riskCarrierManagerListByPolicyWithIndex_.name
                    )
                )
            );
        }
    }

    function _redeemRiskCarrierPolicy(
        string memory _poolId_,
        string memory _policyId_,
        uint256 _redeemAmount_ //? decimals 18 ?//
    ) internal {
        RiskCarrierBaseStorage.Layout storage _rbs_ = RiskCarrierBaseStorage
            .layout();

        require(
            _rbs_
            .riskCarrierControllerListByPolicy[_poolId_][_policyId_].length > 0,
            "Not found."
        );

        for (
            uint256 i = 0;
            i <
            _rbs_
            .riskCarrierControllerListByPolicy[_poolId_][_policyId_].length;
            i++
        ) {
            IRiskCarrierBaseStorage.RiskCarrierController
                memory _riskCarrierManagerListByPolicyWithIndex_ = _rbs_
                    .riskCarrierControllerListByPolicy[_poolId_][_policyId_][i];

            IRiskCarrierController _RiskCarrierController_ = IRiskCarrierController(
                    _riskCarrierManagerListByPolicyWithIndex_.addr
                );

            require(
                _RiskCarrierController_.redeemPolicy(
                    _policyId_,
                    msg.sender,
                    _redeemAmount_ /
                        10**(_decimals() - _RiskCarrierController_.decimals())
                ),
                string(
                    abi.encodePacked(
                        "RPFA: ",
                        _riskCarrierManagerListByPolicyWithIndex_.name
                    )
                )
            );
        }
    }
}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

import {RiskCarrierBaseStorage} from "./base/RiskCarrierBaseStorage.sol";
import {IRiskCarrierBaseStorage} from "./interfaces/IRiskCarrierBaseStorage.sol";
import {IRiskCarrierRouter} from "./interfaces/IRiskCarrierRouter.sol";
import {RiskCarrierRouterInternalFacet} from "./internal/RiskCarrierRouterInternalFacet.sol";
import {AccessControlInternal} from "@solidstate/contracts/access/access_control/AccessControl.sol";
import {ReentrancyGuard} from "@solidstate/contracts/utils/ReentrancyGuard.sol";
import {PausableInternal} from "@solidstate/contracts/security/PausableInternal.sol";

contract RiskCarrierRouterFacet is
    RiskCarrierRouterInternalFacet,
    AccessControlInternal,
    ReentrancyGuard,
    PausableInternal,
    IRiskCarrierRouter
{
    using RiskCarrierBaseStorage for RiskCarrierBaseStorage.Layout;

    function issueRiskCarrierPolicy(
        string memory _poolId_,
        string memory _policyId_,
        IRiskCarrierBaseStorage.RiskTransferParams[] memory _params_
    )
        public
        nonReentrant
        whenNotPaused
        onlyTrustedCaller(_poolId_, msg.sender)
        returns (bool)
    {
        _issueRiskCarrierPolicy(_poolId_, _policyId_, _params_);
        return true;
    }

    function claimRiskCarrierPolicy(
        string memory _poolId_,
        string memory _policyId_,
        uint256 _claimAmount_ //? decimals 18 ?//
    )
        public
        nonReentrant
        whenNotPaused
        onlyTrustedCaller(_poolId_, msg.sender)
        returns (bool)
    {
        _claimRiskCarrierPolicy(_poolId_, _policyId_, _claimAmount_);
        return true;
    }

    function redeemRiskCarrierPolicy(
        string memory _poolId_,
        string memory _policyId_,
        uint256 _redeemAmount_ //? decimals 18 ?//
    )
        public
        nonReentrant
        whenNotPaused
        onlyTrustedCaller(_poolId_, msg.sender)
        returns (bool)
    {
        _redeemRiskCarrierPolicy(_poolId_, _policyId_, _redeemAmount_);
        return true;
    }

    function decimals() public pure returns (uint8) {
        return _decimals();
    }
}