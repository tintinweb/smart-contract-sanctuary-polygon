//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "RideLibPenalty.sol";

contract RidePenalty {
    /**
     * setBanDuration sets user ban duration
     *
     * @param _banDuration | unit in unix timestamp | https://docs.soliditylang.org/en/v0.8.10/units-and-global-variables.html#time-units
     */
    function setBanDuration(uint256 _banDuration) external {
        RideLibPenalty._setBanDuration(_banDuration);
    }

    //////////////////////////////////////////////////////////////////////////////////
    ///// ---------------------------------------------------------------------- /////
    ///// -------------------------- getter functions -------------------------- /////
    ///// ---------------------------------------------------------------------- /////
    //////////////////////////////////////////////////////////////////////////////////

    function getBanDuration() external view returns (uint256) {
        return RideLibPenalty._storagePenalty().banDuration;
    }

    function getUserToBanEndTimestamp(address _user)
        external
        view
        returns (uint256)
    {
        return RideLibPenalty._storagePenalty().userToBanEndTimestamp[_user];
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "RideLibAccessControl.sol";

library RideLibPenalty {
    bytes32 constant STORAGE_POSITION_PENALTY = keccak256("ds.penalty");

    struct StoragePenalty {
        uint256 banDuration;
        mapping(address => uint256) userToBanEndTimestamp;
    }

    function _storagePenalty()
        internal
        pure
        returns (StoragePenalty storage s)
    {
        bytes32 position = STORAGE_POSITION_PENALTY;
        assembly {
            s.slot := position
        }
    }

    function _requireNotBanned() internal view {
        require(
            block.timestamp >=
                _storagePenalty().userToBanEndTimestamp[msg.sender],
            "RideLibPenalty: Still banned"
        );
    }

    event SetBanDuration(address indexed sender, uint256 banDuration);

    /**
     * setBanDuration sets user ban duration
     *
     * @param _banDuration | unit in unix timestamp | https://docs.soliditylang.org/en/v0.8.10/units-and-global-variables.html#time-units
     */
    function _setBanDuration(uint256 _banDuration) internal {
        RideLibAccessControl._requireOnlyRole(
            RideLibAccessControl.STRATEGIST_ROLE
        );
        _storagePenalty().banDuration = _banDuration;

        emit SetBanDuration(msg.sender, _banDuration);
    }

    event UserBanned(address indexed user, uint256 from, uint256 to);

    /**
     * _temporaryBan user
     *
     * @param _user address to be banned
     *
     * @custom:event UserBanned
     */
    function _temporaryBan(address _user) internal {
        StoragePenalty storage s1 = _storagePenalty();
        uint256 banUntil = block.timestamp + s1.banDuration;
        s1.userToBanEndTimestamp[_user] = banUntil;

        emit UserBanned(_user, block.timestamp, banUntil);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "Strings.sol";

library RideLibAccessControl {
    bytes32 constant STORAGE_POSITION_ACCESSCONTROL =
        keccak256("ds.accesscontrol");

    bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 constant MAINTAINER_ROLE = keccak256(abi.encode("MAINTAINER_ROLE"));
    bytes32 constant STRATEGIST_ROLE = keccak256(abi.encode("STRATEGIST_ROLE"));
    bytes32 constant GOVERNOR_ROLE = keccak256(abi.encode("GOVERNOR_ROLE"));
    bytes32 constant REVIEWER_ROLE = keccak256(abi.encode("REVIEWER_ROLE"));
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    struct StorageAccessControl {
        mapping(bytes32 => RoleData) roles;
    }

    function _storageAccessControl()
        internal
        pure
        returns (StorageAccessControl storage s)
    {
        bytes32 position = STORAGE_POSITION_ACCESSCONTROL;
        assembly {
            s.slot := position
        }
    }

    function _requireOnlyRole(bytes32 _role) internal view {
        _checkRole(_role);
    }

    function _hasRole(bytes32 _role, address _account)
        internal
        view
        returns (bool)
    {
        return _storageAccessControl().roles[_role].members[_account];
    }

    function _checkRole(bytes32 _role) internal view {
        _checkRole(_role, msg.sender);
    }

    function _checkRole(bytes32 _role, address _account) internal view {
        if (!_hasRole(_role, _account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(_account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(_role), 32)
                    )
                )
            );
        }
    }

    function _getRoleAdmin(bytes32 _role) internal view returns (bytes32) {
        return _storageAccessControl().roles[_role].adminRole;
    }

    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    function _setRoleAdmin(bytes32 _role, bytes32 _adminRole) internal {
        bytes32 previousAdminRole = _getRoleAdmin(_role);
        _storageAccessControl().roles[_role].adminRole = _adminRole;
        emit RoleAdminChanged(_role, previousAdminRole, _adminRole);
    }

    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    function _grantRole(bytes32 _role, address _account) internal {
        if (!_hasRole(_role, _account)) {
            _storageAccessControl().roles[_role].members[_account] = true;
            emit RoleGranted(_role, _account, msg.sender);
        }
    }

    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    function _revokeRole(bytes32 _role, address _account) internal {
        if (_hasRole(_role, _account)) {
            _storageAccessControl().roles[_role].members[_account] = false;
            emit RoleRevoked(_role, _account, msg.sender);
        }
    }

    function _setupRole(bytes32 _role, address _account) internal {
        _grantRole(_role, _account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}