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
import {IRiskCarrierRegistryInternal} from "./IRiskCarrierRegistryInternal.sol";

interface IRiskCarrierRegistry is IRiskCarrierRegistryInternal {
    function delistRiskCarrierController(string memory _poolId_, address _addr_)
        external;

    function getRiskCarrierControllerListByPolicy(
        string memory _poolId_,
        string memory _policyId_,
        uint256 _page_,
        uint256 _size_
    )
        external
        view
        returns (
            IRiskCarrierBaseStorage.RiskCarrierControllerWithRiskTransferRatio[]
                memory riskCarrierControllerList,
            uint256 newPage
        );

    function getRiskCarrierControllerListByPool(
        string memory _poolId_,
        uint256 _page_,
        uint256 _size_
    )
        external
        view
        returns (
            IRiskCarrierBaseStorage.RiskCarrierControllerWithRiskTransferRatio[]
                memory riskCarrierControllerList,
            uint256 newPage
        );

    function registerRiskCarrierController(
        string memory _poolId_,
        string memory _name_,
        address _addr_
    ) external;
}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

interface IRiskCarrierRegistryInternal {
    event DelistRiskCarrierController(
        string indexed poolId,
        address indexed addr
    );
    event RegisterRiskCarrierController(
        string indexed poolId,
        string indexed name,
        address indexed addr
    );
}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

import {RiskCarrierBaseStorage} from "../base/RiskCarrierBaseStorage.sol";
import {IRiskCarrierController} from "../interfaces/IRiskCarrierController.sol";
import {IRiskCarrierBaseStorage} from "../interfaces/IRiskCarrierBaseStorage.sol";
import {IRiskCarrierRegistryInternal} from "../interfaces/IRiskCarrierRegistryInternal.sol";

abstract contract RiskCarrierRegistryInternalFacet is
    IRiskCarrierRegistryInternal
{
    using RiskCarrierBaseStorage for RiskCarrierBaseStorage.Layout;

    function _registerRiskCarrierController(
        string memory _poolId_,
        string memory _name_,
        address _addr_
    ) internal {
        RiskCarrierBaseStorage.Layout storage _rbs_ = RiskCarrierBaseStorage
            .layout();

        require(_rbs_.isExistByPoolId[_poolId_][_addr_] == false, "EICIDWPID");

        IRiskCarrierBaseStorage.RiskCarrierController
            memory riskCarrierurerController = IRiskCarrierBaseStorage
                .RiskCarrierController(_addr_, _name_);

        _rbs_.isExistByPoolId[_poolId_][_addr_] = true;

        _rbs_.riskCarrierControllerListByPool[_poolId_].push(
            riskCarrierurerController
        );

        _rbs_.riskCarrierControllerListIndexByPool[_poolId_][_addr_] =
            _rbs_.riskCarrierControllerListByPool[_poolId_].length -
            1;

        emit RegisterRiskCarrierController(_poolId_, _name_, _addr_);
    }

    function _delistRiskCarrierController(
        string memory _poolId_,
        address _addr_
    ) internal {
        RiskCarrierBaseStorage.Layout storage _rbs_ = RiskCarrierBaseStorage
            .layout();

        require(_rbs_.isExistByPoolId[_poolId_][_addr_] == true, "CIDINEWPID");

        delete _rbs_.isExistByPoolId[_poolId_][_addr_];

        IRiskCarrierBaseStorage.RiskCarrierController[]
            storage listOfRiskCarrierController = _rbs_
                .riskCarrierControllerListByPool[_poolId_];

        listOfRiskCarrierController[
            _rbs_.riskCarrierControllerListIndexByPool[_poolId_][_addr_]
        ] = listOfRiskCarrierController[listOfRiskCarrierController.length - 1];
        listOfRiskCarrierController.pop();

        delete _rbs_.riskCarrierControllerListIndexByPool[_poolId_][_addr_];

        emit DelistRiskCarrierController(_poolId_, _addr_);
    }

    function _getRiskCarrierControllerListByPool(
        string memory _poolId_,
        uint256 _page_,
        uint256 _size_
    )
        internal
        view
        returns (
            IRiskCarrierBaseStorage.RiskCarrierControllerWithRiskTransferRatio[]
                memory riskCarrierControllerList,
            uint256 newPage
        )
    {
        RiskCarrierBaseStorage.Layout storage _rbs_ = RiskCarrierBaseStorage
            .layout();

        uint256 length = _size_;
        if (
            length >
            _rbs_.riskCarrierControllerListByPool[_poolId_].length - _page_
        ) {
            length =
                _rbs_.riskCarrierControllerListByPool[_poolId_].length -
                _page_;
        }

        riskCarrierControllerList = new IRiskCarrierBaseStorage.RiskCarrierControllerWithRiskTransferRatio[](
            length
        );

        for (uint256 i = 0; i < length; i++) {
            IRiskCarrierBaseStorage.RiskCarrierController
                memory _riskCarrierControllerListByPool_ = _rbs_
                    .riskCarrierControllerListByPool[_poolId_][_page_ + i];

            riskCarrierControllerList[i] = IRiskCarrierBaseStorage
                .RiskCarrierControllerWithRiskTransferRatio(
                    _riskCarrierControllerListByPool_.addr,
                    _riskCarrierControllerListByPool_.name,
                    IRiskCarrierController(
                        _riskCarrierControllerListByPool_.addr
                    ).riskTransferRatio()
                );
        }

        return (riskCarrierControllerList, _page_ + length);
    }

    function _getRiskCarrierControllerListByPolicy(
        string memory _poolId_,
        string memory _policyId_,
        uint256 _page_,
        uint256 _size_
    )
        internal
        view
        returns (
            IRiskCarrierBaseStorage.RiskCarrierControllerWithRiskTransferRatio[]
                memory riskCarrierControllerList,
            uint256 newPage
        )
    {
        RiskCarrierBaseStorage.Layout storage _rbs_ = RiskCarrierBaseStorage
            .layout();

        uint256 length = _size_;
        if (
            length >
            _rbs_
            .riskCarrierControllerListByPolicy[_poolId_][_policyId_].length -
                _page_
        ) {
            length =
                _rbs_
                .riskCarrierControllerListByPolicy[_poolId_][_policyId_]
                    .length -
                _page_;
        }

        riskCarrierControllerList = new IRiskCarrierBaseStorage.RiskCarrierControllerWithRiskTransferRatio[](
            length
        );

        for (uint256 i = 0; i < length; i++) {
            IRiskCarrierBaseStorage.RiskCarrierController
                memory _riskCarrierControllerListByPolicy_ = _rbs_
                    .riskCarrierControllerListByPolicy[_poolId_][_policyId_][
                        _page_ + i
                    ];

            riskCarrierControllerList[i] = IRiskCarrierBaseStorage
                .RiskCarrierControllerWithRiskTransferRatio(
                    _riskCarrierControllerListByPolicy_.addr,
                    _riskCarrierControllerListByPolicy_.name,
                    IRiskCarrierController(
                        _riskCarrierControllerListByPolicy_.addr
                    ).riskTransferRatio()
                );
        }

        return (riskCarrierControllerList, _page_ + length);
    }
}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

import {RiskCarrierBaseStorage} from "./base/RiskCarrierBaseStorage.sol";
import {IRiskCarrierBaseStorage} from "./interfaces/IRiskCarrierBaseStorage.sol";
import {IRiskCarrierRegistry} from "./interfaces/IRiskCarrierRegistry.sol";
import {RiskCarrierRegistryInternalFacet} from "./internal/RiskCarrierRegistryInternalFacet.sol";
import {AccessControlInternal} from "@solidstate/contracts/access/access_control/AccessControl.sol";

contract RiskCarrierRegistryFacet is
    RiskCarrierRegistryInternalFacet,
    AccessControlInternal,
    IRiskCarrierRegistry
{
    using RiskCarrierBaseStorage for RiskCarrierBaseStorage.Layout;

    function registerRiskCarrierController(
        string memory _poolId_,
        string memory _name_,
        address _addr_
    ) public onlyRole(RiskCarrierBaseStorage.SUPER_MANAGER_LEVEL) {
        _registerRiskCarrierController(_poolId_, _name_, _addr_);
    }

    function delistRiskCarrierController(string memory _poolId_, address _addr_)
        public
        onlyRole(RiskCarrierBaseStorage.SUPER_MANAGER_LEVEL)
    {
        _delistRiskCarrierController(_poolId_, _addr_);
    }

    function getRiskCarrierControllerListByPool(
        string memory _poolId_,
        uint256 _page_,
        uint256 _size_
    )
        public
        view
        returns (
            IRiskCarrierBaseStorage.RiskCarrierControllerWithRiskTransferRatio[]
                memory riskCarrierControllerList,
            uint256 newPage
        )
    {
        return _getRiskCarrierControllerListByPool(_poolId_, _page_, _size_);
    }

    function getRiskCarrierControllerListByPolicy(
        string memory _poolId_,
        string memory _policyId_,
        uint256 _page_,
        uint256 _size_
    )
        public
        view
        returns (
            IRiskCarrierBaseStorage.RiskCarrierControllerWithRiskTransferRatio[]
                memory riskCarrierControllerList,
            uint256 newPage
        )
    {
        return
            _getRiskCarrierControllerListByPolicy(
                _poolId_,
                _policyId_,
                _page_,
                _size_
            );
    }
}