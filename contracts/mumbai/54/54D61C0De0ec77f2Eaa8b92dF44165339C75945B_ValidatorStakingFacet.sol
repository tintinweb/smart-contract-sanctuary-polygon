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

import {IValidatorBaseStorage} from "./IValidatorBaseStorage.sol";
import {IValidatorStakingInternal} from "./IValidatorStakingInternal.sol";

interface IValidatorStaking is IValidatorStakingInternal {
    function decreaseValidatorOnHoldAmount(
        uint256 _claimId_,
        address _validator_
    ) external returns (bool);

    function getLastUpdateByValidator(address _validator_)
        external
        view
        returns (uint256);

    function getOnHoldAmountByValidator(address _validator_)
        external
        view
        returns (uint256);

    function getPenaltyAmountByValidator(address _validator_)
        external
        view
        returns (uint256);

    function getStakedAmountByValidator(address _validator_)
        external
        view
        returns (uint256);

    function getStakingRules()
        external
        view
        returns (IValidatorBaseStorage.StakingRules memory);

    function getTotalNetStakeAmount() external view returns (uint256);

    function getTotalOnHoldAmount() external view returns (uint256);

    function getTotalPenaltyStake() external view returns (uint256);

    function getTotalStakedAmount() external view returns (uint256);

    function getValidatorNetStakeAmount(address _validator_)
        external
        view
        returns (uint256);

    function getValidatorStake(address _validator_)
        external
        view
        returns (IValidatorBaseStorage.StakingBalance memory);

    function increaseValidatorOnHoldAmount(
        uint256 _claimId_,
        address _validator_,
        uint256 _amount_
    ) external returns (bool);

    function isValidatorWhitelisted(address _addr_)
        external
        view
        returns (bool);

    function miToken() external view returns (address);

    function payPenalty(uint256 _amount_) external returns (bool);

    function removeValidator(address _validator_) external returns (bool);

    function setMIToken(address _addr_) external;

    function setStakingRules(IValidatorBaseStorage.StakingRules memory _sr_)
        external;

    function setValidatorWhitelist(address _addr_, bool _status_) external;

    function stake(uint256 _amount_) external returns (bool);

    function unstake(uint256 _amount_) external returns (bool);
}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

import {IValidatorBaseStorage} from "./IValidatorBaseStorage.sol";

interface IValidatorStakingInternal {
    event MITokenChanged(address indexed miToken);
    event ValidatorWhitelistChanged(address indexed validator, bool status);
    event ValidatorChanged(address indexed validator, bool status);
    event StakingRulesChanged(IValidatorBaseStorage.StakingRules stakingRules);
    event ValidatorOnHoldAmountChanged(
        uint256 indexed claimId,
        address indexed validator,
        uint256 amount
    );
    event initializedPoint(address indexed validator, uint256 amount);
    event Staked(address indexed validator, uint256 amount);
    event Unstaked(address indexed validator, uint256 amount);
    event PenaltyPaid(address indexed validator, uint256 amount);
}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

import {ValidatorBaseStorage} from "../base/ValidatorBaseStorage.sol";
import {IValidatorBaseStorage} from "../interfaces/IValidatorBaseStorage.sol";
import {IValidatorStakingInternal} from "../interfaces/IValidatorStakingInternal.sol";
import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC20MetadataUpgradeable.sol";

abstract contract ValidatorStakingInternalFacet is IValidatorStakingInternal {
    using ValidatorBaseStorage for ValidatorBaseStorage.Layout;

    modifier onlyValidatorWhiteListed() {
        require(
            ValidatorBaseStorage.layout().isValidatorWhitelist[msg.sender],
            "notWhitelisted"
        );
        _;
    }

    modifier onlyValidator() {
        require(
            ValidatorBaseStorage.layout().isValidator[msg.sender],
            "notValidator"
        );
        _;
    }

    function _setMIToken(address _addr_) internal {
        ValidatorBaseStorage.layout().miToken = _addr_;

        emit MITokenChanged(_addr_);
    }

    function _miToken() internal view returns (address) {
        return ValidatorBaseStorage.layout().miToken;
    }

    function _setValidatorWhitelist(address _addr_, bool _status_) internal {
        ValidatorBaseStorage.Layout storage _vbs_ = ValidatorBaseStorage
            .layout();

        require(_vbs_.isValidatorWhitelist[_addr_] != _status_, "ALREADY");

        _vbs_.isValidatorWhitelist[_addr_] = _status_;

        emit ValidatorWhitelistChanged(_addr_, _status_);
    }

    function _setValidator(address _validator_, bool _status_) internal {
        ValidatorBaseStorage.Layout storage _vbs_ = ValidatorBaseStorage
            .layout();

        require(_vbs_.isValidator[_validator_] != _status_, "ALREADY");

        _vbs_.isValidator[_validator_] = _status_;

        if (_status_ == true) {
            _vbs_.validators.push(_validator_);
            _vbs_.validatorIndex[_validator_] = _vbs_.validators.length - 1;
        } else {
            require(
                _vbs_.validatorIndex[msg.sender] <= _vbs_.validators.length
            );
            _vbs_.validators[_vbs_.validatorIndex[msg.sender]] = _vbs_
                .validators[_vbs_.validators.length - 1];
            _vbs_.validators.pop();
        }

        emit ValidatorChanged(_validator_, _status_);

        if (
            _status_ == true &&
            _vbs_.isCurrentAndFormerValidator[_validator_] == false
        ) {
            _vbs_.isCurrentAndFormerValidator[_validator_] = true;
            _vbs_.totalPoint += _vbs_.validatorRules.initialPoint;

            _vbs_.validatorPoints[_validator_].point = _vbs_
                .validatorRules
                .initialPoint;

            emit initializedPoint(
                _validator_,
                _vbs_.validatorRules.initialPoint
            );
        }
    }

    function _isValidatorWhitelisted(address _addr_)
        internal
        view
        returns (bool)
    {
        return ValidatorBaseStorage.layout().isValidatorWhitelist[_addr_];
    }

    function _increaseValidatorOnHoldAmount(
        uint256 _claimId_,
        address _validator_,
        uint256 _amount_
    ) internal {
        ValidatorBaseStorage.Layout storage _vbs_ = ValidatorBaseStorage
            .layout();

        require(_vbs_.isValidator[_validator_], "notValidator");

        IValidatorBaseStorage.StakingBalance memory _sb_ = _vbs_
            .validatorStakingBalance[_validator_];

        require(
            _sb_.staked - _sb_.penalty - _sb_.onHold >= _amount_,
            "notEnough"
        );

        _vbs_.ClaimCaseVotingVouchers[_claimId_].validatorOnHold = _amount_;

        _vbs_.validatorStakingBalance[_validator_].onHold += _amount_;
        _vbs_.totalOnHold += _amount_;
        _vbs_.validatorStakingBalance[_validator_].lastUpdate = uint40(
            block.timestamp
        );

        emit ValidatorOnHoldAmountChanged(
            _claimId_,
            _validator_,
            _vbs_.validatorStakingBalance[_validator_].onHold
        );
    }

    function _decreaseValidatorOnHoldAmount(
        uint256 _claimId_,
        address _validator_
    ) internal {
        ValidatorBaseStorage.Layout storage _vbs_ = ValidatorBaseStorage
            .layout();

        require(_vbs_.isValidator[_validator_], "notValidator");

        IValidatorBaseStorage.StakingBalance memory _sb_ = _vbs_
            .validatorStakingBalance[_validator_];

        uint256 _amount_ = _vbs_
            .ClaimCaseVotingVouchers[_claimId_]
            .validatorOnHold;

        require(_sb_.onHold >= _amount_, "notEnough");

        _vbs_.validatorStakingBalance[_validator_].onHold -= _amount_;
        _vbs_.totalOnHold -= _amount_;
        _vbs_.validatorStakingBalance[_validator_].lastUpdate = uint40(
            block.timestamp
        );

        emit ValidatorOnHoldAmountChanged(
            _claimId_,
            _validator_,
            _vbs_.validatorStakingBalance[_validator_].onHold
        );
    }

    function _getStakingRules()
        internal
        view
        returns (IValidatorBaseStorage.StakingRules memory)
    {
        return ValidatorBaseStorage.layout().stakingRules;
    }

    function _setStakingRules(IValidatorBaseStorage.StakingRules memory _sr_)
        internal
    {
        ValidatorBaseStorage.Layout storage _vbs_ = ValidatorBaseStorage
            .layout();

        _vbs_.stakingRules = _sr_;

        emit StakingRulesChanged(_sr_);
    }

    function _stake(uint256 _amount_) internal {
        ValidatorBaseStorage.Layout storage _vbs_ = ValidatorBaseStorage
            .layout();

        require(_amount_ > 0, "ISA");
        require(
            _vbs_.validatorStakingBalance[msg.sender].onHold == 0,
            "ONHOLD"
        );
        require(
            _vbs_.stakingRules.minStake <=
                _vbs_.validatorStakingBalance[msg.sender].staked + _amount_,
            "MINSA"
        );
        require(_vbs_.stakingRules.maxStake >= _amount_, "MAXSA");
        require(
            _vbs_.stakingRules.maxStake >=
                _vbs_.validatorStakingBalance[msg.sender].staked + _amount_,
            "MAXUSA"
        );

        IERC20MetadataUpgradeable _miToken_ = IERC20MetadataUpgradeable(
            _vbs_.miToken
        );

        require(
            _miToken_.allowance(msg.sender, address(this)) >= _amount_,
            "IAA"
        );
        require(_miToken_.balanceOf(msg.sender) >= _amount_, "IB");

        require(
            _miToken_.transferFrom(msg.sender, address(this), _amount_),
            "ECT"
        );

        _vbs_.totalStaked += _amount_;

        _vbs_.validatorStakingBalance[msg.sender].staked += _amount_;

        _vbs_.validatorStakingBalance[msg.sender].lastUpdate = uint40(
            block.timestamp
        );

        emit Staked(msg.sender, _amount_);
    }

    /* 

        decimals in this is 18 (same as miToken)

        staked:100
        unstakeAmountRequest = 50
        penalty: 10
        onHold: 0

        -> after payPenaltyByStakedBalance
        staked: 90
        penalty: 0
        onHold: 0

        -> after unstake
        staked: 40
        penalty: 0
        onHold: 0

    */
    function _unstake(uint256 _amount_) internal {
        ValidatorBaseStorage.Layout storage _vbs_ = ValidatorBaseStorage
            .layout();

        require(_amount_ > 0, "ISA");

        require(
            _vbs_.validatorStakingBalance[msg.sender].onHold == 0,
            "ONHOLD"
        );

        require(
            _vbs_.validatorStakingBalance[msg.sender].lastUpdate + 14 days <
                block.timestamp,
            "14D"
        );

        require(
            _vbs_.validatorStakingBalance[msg.sender].staked -
                _vbs_.validatorStakingBalance[msg.sender].penalty >=
                _amount_,
            "NSA"
        );

        if (_vbs_.validatorStakingBalance[msg.sender].penalty > 0) {
            _payPenaltyByStakedBalance(
                _vbs_.validatorStakingBalance[msg.sender].penalty
            );
        }

        _vbs_.totalStaked -= _amount_;
        _vbs_.validatorStakingBalance[msg.sender].staked -= _amount_;
        _vbs_.validatorStakingBalance[msg.sender].lastUpdate = uint40(
            block.timestamp
        );

        IERC20MetadataUpgradeable(_vbs_.miToken).transfer(msg.sender, _amount_);

        emit Unstaked(msg.sender, _amount_);
    }

    function _payPenalty(uint256 _amount_) internal {
        ValidatorBaseStorage.Layout storage _vbs_ = ValidatorBaseStorage
            .layout();

        require(_amount_ > 0, "ISA");

        require(
            _vbs_.validatorStakingBalance[msg.sender].staked -
                _vbs_.validatorStakingBalance[msg.sender].penalty >=
                _amount_,
            "NSA"
        );

        IERC20MetadataUpgradeable _miToken_ = IERC20MetadataUpgradeable(
            _vbs_.miToken
        );

        require(
            _miToken_.allowance(msg.sender, address(this)) >= _amount_,
            "IAA"
        );
        require(_miToken_.balanceOf(msg.sender) >= _amount_, "IB");

        require(
            _miToken_.transferFrom(msg.sender, address(this), _amount_),
            "ECT"
        );

        _vbs_.validatorStakingBalance[msg.sender].penalty -= _amount_;
        _vbs_.totalPenaltyStake -= _amount_;
        _vbs_.validatorStakingBalance[msg.sender].lastUpdate = uint40(
            block.timestamp
        );

        emit PenaltyPaid(msg.sender, _amount_);
    }

    function _payPenaltyByStakedBalance(uint256 _amount_) internal {
        ValidatorBaseStorage.Layout storage _vbs_ = ValidatorBaseStorage
            .layout();

        require(_amount_ > 0, "ISA");
        require(
            _vbs_.validatorStakingBalance[msg.sender].penalty >= _amount_,
            "NSA"
        );

        require(
            _vbs_.validatorStakingBalance[msg.sender].staked >=
                _vbs_.validatorStakingBalance[msg.sender].penalty,
            "PP"
        );

        _vbs_.validatorStakingBalance[msg.sender].staked -= _amount_;
        _vbs_.validatorStakingBalance[msg.sender].penalty -= _amount_;
        _vbs_.totalPenaltyStake -= _amount_;

        emit PenaltyPaid(msg.sender, _amount_);
    }

    function _getValidatorNetStakeAmount(address _validator_)
        internal
        view
        returns (uint256)
    {
        ValidatorBaseStorage.Layout storage _vbs_ = ValidatorBaseStorage
            .layout();
        return
            _vbs_.validatorStakingBalance[_validator_].staked -
            _vbs_.validatorStakingBalance[_validator_].onHold -
            _vbs_.validatorStakingBalance[_validator_].penalty;
    }

    function _getTotalNetStakeAmount() internal view returns (uint256) {
        ValidatorBaseStorage.Layout storage _vbs_ = ValidatorBaseStorage
            .layout();
        return _vbs_.totalStaked - _vbs_.totalOnHold - _vbs_.totalPenaltyStake;
    }

    function _getTotalStakedAmount() internal view returns (uint256) {
        return ValidatorBaseStorage.layout().totalStaked;
    }

    function _getTotalPenaltyStake() internal view returns (uint256) {
        return ValidatorBaseStorage.layout().totalPenaltyStake;
    }

    function _getTotalOnHoldAmount() internal view returns (uint256) {
        return ValidatorBaseStorage.layout().totalOnHold;
    }

    function _getStakedAmountByValidator(address _validator_)
        internal
        view
        returns (uint256)
    {
        return
            ValidatorBaseStorage
                .layout()
                .validatorStakingBalance[_validator_]
                .staked;
    }

    function _getPenaltyAmountByValidator(address _validator_)
        internal
        view
        returns (uint256)
    {
        return
            ValidatorBaseStorage
                .layout()
                .validatorStakingBalance[_validator_]
                .penalty;
    }

    function _getOnHoldAmountByValidator(address _validator_)
        internal
        view
        returns (uint256)
    {
        return
            ValidatorBaseStorage
                .layout()
                .validatorStakingBalance[_validator_]
                .onHold;
    }

    function _getLastUpdateByValidator(address _validator_)
        internal
        view
        returns (uint256)
    {
        return
            ValidatorBaseStorage
                .layout()
                .validatorStakingBalance[_validator_]
                .lastUpdate;
    }

    function _getValidatorStake(address _validator_)
        internal
        view
        returns (IValidatorBaseStorage.StakingBalance memory)
    {
        ValidatorBaseStorage.Layout storage _vbs_ = ValidatorBaseStorage
            .layout();

        return _vbs_.validatorStakingBalance[_validator_];
    }
}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

import {ValidatorBaseStorage} from "./base/ValidatorBaseStorage.sol";
import {IValidatorBaseStorage} from "./interfaces/IValidatorBaseStorage.sol";
import {IValidatorStaking} from "./interfaces/IValidatorStaking.sol";
import {ValidatorStakingInternalFacet} from "./internal/ValidatorStakingInternalFacet.sol";
import {AccessControlInternal} from "@solidstate/contracts/access/access_control/AccessControl.sol";
import {ReentrancyGuard} from "@solidstate/contracts/utils/ReentrancyGuard.sol";
import {PausableInternal} from "@solidstate/contracts/security/PausableInternal.sol";

contract ValidatorStakingFacet is
    ValidatorStakingInternalFacet,
    AccessControlInternal,
    ReentrancyGuard,
    PausableInternal,
    IValidatorStaking
{
    using ValidatorBaseStorage for ValidatorBaseStorage.Layout;

    function stake(uint256 _amount_)
        public
        nonReentrant
        whenNotPaused
        onlyValidatorWhiteListed
        returns (bool)
    {
        _stake(_amount_);

        ValidatorBaseStorage.Layout storage _vbs_ = ValidatorBaseStorage
            .layout();

        if (
            _vbs_.isValidator[msg.sender] == false &&
            _vbs_.validatorStakingBalance[msg.sender].staked -
                _vbs_.validatorStakingBalance[msg.sender].penalty >=
            _vbs_.stakingRules.minStake
        ) {
            _setValidator(msg.sender, true);
        }

        return true;
    }

    function unstake(uint256 _amount_)
        public
        nonReentrant
        whenNotPaused
        onlyValidatorWhiteListed
        returns (bool)
    {
        _unstake(_amount_);

        ValidatorBaseStorage.Layout storage _vbs_ = ValidatorBaseStorage
            .layout();

        if (
            _vbs_.isValidator[msg.sender] == true &&
            _vbs_.validatorStakingBalance[msg.sender].staked -
                _vbs_.validatorStakingBalance[msg.sender].penalty <=
            _vbs_.stakingRules.minStake
        ) {
            _setValidator(msg.sender, false);
        }

        return true;
    }

    function payPenalty(uint256 _amount_)
        public
        nonReentrant
        whenNotPaused
        onlyValidatorWhiteListed
        returns (bool)
    {
        _payPenalty(_amount_);

        return true;
    }

    function increaseValidatorOnHoldAmount(
        uint256 _claimId_,
        address _validator_,
        uint256 _amount_
    )
        public
        nonReentrant
        whenNotPaused
        onlyRole(ValidatorBaseStorage.INSURANCE_MANAGER_LEVEL)
        returns (bool)
    {
        _increaseValidatorOnHoldAmount(_claimId_, _validator_, _amount_);

        return true;
    }

    function decreaseValidatorOnHoldAmount(
        uint256 _claimId_,
        address _validator_
    )
        public
        nonReentrant
        whenNotPaused
        onlyRole(ValidatorBaseStorage.INSURANCE_MANAGER_LEVEL)
        returns (bool)
    {
        _decreaseValidatorOnHoldAmount(_claimId_, _validator_);

        return true;
    }

    function getTotalPenaltyStake() public view returns (uint256) {
        return _getTotalPenaltyStake();
    }

    function getTotalOnHoldAmount() public view returns (uint256) {
        return _getTotalOnHoldAmount();
    }

    function removeValidator(address _validator_)
        public
        onlyRole(ValidatorBaseStorage.SUPER_MANAGER_LEVEL)
        returns (bool)
    {
        _setValidator(_validator_, false);

        return true;
    }

    function setMIToken(address _addr_)
        public
        onlyRole(ValidatorBaseStorage.SUPER_MANAGER_LEVEL)
    {
        _setMIToken(_addr_);
    }

    function miToken() public view returns (address) {
        return _miToken();
    }

    function setValidatorWhitelist(address _addr_, bool _status_)
        public
        onlyRole(ValidatorBaseStorage.SUPER_MANAGER_LEVEL)
    {
        _setValidatorWhitelist(_addr_, _status_);
    }

    function isValidatorWhitelisted(address _addr_) public view returns (bool) {
        return _isValidatorWhitelisted(_addr_);
    }

    function getValidatorNetStakeAmount(address _validator_)
        public
        view
        returns (uint256)
    {
        return _getValidatorNetStakeAmount(_validator_);
    }

    function getTotalNetStakeAmount() public view returns (uint256) {
        return _getTotalNetStakeAmount();
    }

    function getTotalStakedAmount() public view returns (uint256) {
        return _getTotalStakedAmount();
    }

    function getStakedAmountByValidator(address _validator_)
        public
        view
        returns (uint256)
    {
        return _getStakedAmountByValidator(_validator_);
    }

    function getPenaltyAmountByValidator(address _validator_)
        public
        view
        returns (uint256)
    {
        return _getPenaltyAmountByValidator(_validator_);
    }

    function getOnHoldAmountByValidator(address _validator_)
        public
        view
        returns (uint256)
    {
        return _getOnHoldAmountByValidator(_validator_);
    }

    function getLastUpdateByValidator(address _validator_)
        public
        view
        returns (uint256)
    {
        return _getLastUpdateByValidator(_validator_);
    }

    function getValidatorStake(address _validator_)
        public
        view
        returns (IValidatorBaseStorage.StakingBalance memory)
    {
        return _getValidatorStake(_validator_);
    }

    function setStakingRules(IValidatorBaseStorage.StakingRules memory _sr_)
        public
        onlyRole(ValidatorBaseStorage.SUPER_MANAGER_LEVEL)
    {
        _setStakingRules(_sr_);
    }

    function getStakingRules()
        public
        view
        returns (IValidatorBaseStorage.StakingRules memory)
    {
        return _getStakingRules();
    }
}