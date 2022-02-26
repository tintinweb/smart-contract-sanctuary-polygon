//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "RideLibRater.sol";

contract RideRater {
    /**
     * setRatingBounds sets bounds for rating
     *
     * @param _min | unitless integer
     * @param _max | unitless integer
     */
    function setRatingBounds(uint256 _min, uint256 _max) external {
        RideLibRater._setRatingBounds(_min, _max);
    }

    //////////////////////////////////////////////////////////////////////////////////
    ///// ---------------------------------------------------------------------- /////
    ///// -------------------------- getter functions -------------------------- /////
    ///// ---------------------------------------------------------------------- /////
    //////////////////////////////////////////////////////////////////////////////////

    function getRatingMin() external view returns (uint256) {
        return RideLibRater._storageRater().ratingMin;
    }

    function getRatingMax() external view returns (uint256) {
        return RideLibRater._storageRater().ratingMax;
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "RideLibBadge.sol";
import "RideLibAccessControl.sol";

library RideLibRater {
    bytes32 constant STORAGE_POSITION_RATER = keccak256("ds.rater");

    struct StorageRater {
        uint256 ratingMin;
        uint256 ratingMax;
    }

    function _storageRater() internal pure returns (StorageRater storage s) {
        bytes32 position = STORAGE_POSITION_RATER;
        assembly {
            s.slot := position
        }
    }

    event SetRatingBounds(address indexed sender, uint256 min, uint256 max);

    /**
     * setRatingBounds sets bounds for rating
     *
     * @param _min | unitless integer
     * @param _max | unitless integer
     */
    function _setRatingBounds(uint256 _min, uint256 _max) internal {
        RideLibAccessControl._requireOnlyRole(
            RideLibAccessControl.STRATEGIST_ROLE
        );
        require(_min > 0, "RideLibRater: Cannot have zero rating bound");
        require(
            _max > _min,
            "RideLibRater: Maximum rating must be more than minimum rating"
        );
        StorageRater storage s1 = _storageRater();
        s1.ratingMin = _min;
        s1.ratingMax = _max;

        emit SetRatingBounds(msg.sender, _min, _max);
    }

    /**
     * _giveRating
     *
     * @param _driver driver's address
     * @param _rating unitless integer between RATING_MIN and RATING_MAX
     *
     */
    function _giveRating(address _driver, uint256 _rating) internal {
        RideLibBadge.StorageBadge storage s1 = RideLibBadge._storageBadge();
        StorageRater storage s2 = _storageRater();

        // require(s2.ratingMax > 0, "maximum rating must be more than zero");
        // require(s2.ratingMin > 0, "minimum rating must be more than zero");
        // since remove greater than 0 check, makes pax call more gas efficient,
        // but make sure _setRatingBounds called at init
        require(
            _rating >= s2.ratingMin && _rating <= s2.ratingMax,
            "RideLibRater: Rating must be within min and max ratings (inclusive)"
        );

        s1.driverToDriverReputation[_driver].totalRating += _rating;
        s1.driverToDriverReputation[_driver].countRating += 1;
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "RideBadge.sol";
import "RideLibRater.sol";
import "RideLibAccessControl.sol";

library RideLibBadge {
    bytes32 constant STORAGE_POSITION_BADGE = keccak256("ds.badge");

    /**
     * lifetime cumulative values of drivers
     */
    struct DriverReputation {
        uint256 id;
        string uri;
        uint256 maxMetresPerTrip; // TODO: necessary? when ticket showed to driver, he can see destination and metres and choose to accept or not!!
        uint256 metresTravelled;
        uint256 countStart;
        uint256 countEnd;
        uint256 totalRating;
        uint256 countRating;
    }

    struct StorageBadge {
        mapping(uint256 => uint256) badgeToBadgeMaxScore;
        mapping(uint256 => bool) _insertedMaxScore;
        uint256[] _badges;
        mapping(address => DriverReputation) driverToDriverReputation;
    }

    function _storageBadge() internal pure returns (StorageBadge storage s) {
        bytes32 position = STORAGE_POSITION_BADGE;
        assembly {
            s.slot := position
        }
    }

    event SetBadgesMaxScores(address indexed sender, uint256[] scores);

    /**
     * TODO:
     * Check if setBadgesMaxScores is used in other contracts after
     * diamond pattern finalized. if no use then change visibility
     * to external
     */
    /**
     * setBadgesMaxScores maps score to badge
     *
     * @param _badgesMaxScores Score that defines a specific badge rank
     */
    function _setBadgesMaxScores(uint256[] memory _badgesMaxScores) internal {
        RideLibAccessControl._requireOnlyRole(
            RideLibAccessControl.STRATEGIST_ROLE
        );
        require(
            _badgesMaxScores.length == _getBadgesCount() - 1,
            "RideLibBadge: Input array length must be one less than RideBadge.Badges"
        );
        StorageBadge storage s1 = _storageBadge();
        for (uint256 i = 0; i < _badgesMaxScores.length; i++) {
            s1.badgeToBadgeMaxScore[i] = _badgesMaxScores[i];

            if (!s1._insertedMaxScore[i]) {
                s1._insertedMaxScore[i] = true;
                s1._badges.push(i);
            }
        }

        emit SetBadgesMaxScores(msg.sender, _badgesMaxScores);
    }

    /**
     * _getBadgesCount returns number of recognized badges
     *
     * @return badges count
     */
    function _getBadgesCount() internal pure returns (uint256) {
        return uint256(RideBadge.Badges.Veteran) + 1;
    }

    /**
     * _getBadge returns the badge rank for given score
     *
     * @param _score | unitless integer
     *
     * @return badge rank
     */
    function _getBadge(uint256 _score) internal view returns (uint256) {
        StorageBadge storage s1 = _storageBadge();

        for (uint256 i = 0; i < s1._badges.length; i++) {
            require(
                s1.badgeToBadgeMaxScore[s1._badges[i]] > 0,
                "zero badge score bounds"
            );
        } // TODO: if max score corrently set using _setBadgesMaxScores, dont need this revert fn

        if (_score <= s1.badgeToBadgeMaxScore[0]) {
            return uint256(RideBadge.Badges.Newbie);
        } else if (
            _score > s1.badgeToBadgeMaxScore[0] &&
            _score <= s1.badgeToBadgeMaxScore[1]
        ) {
            return uint256(RideBadge.Badges.Bronze);
        } else if (
            _score > s1.badgeToBadgeMaxScore[1] &&
            _score <= s1.badgeToBadgeMaxScore[2]
        ) {
            return uint256(RideBadge.Badges.Silver);
        } else if (
            _score > s1.badgeToBadgeMaxScore[2] &&
            _score <= s1.badgeToBadgeMaxScore[3]
        ) {
            return uint256(RideBadge.Badges.Gold);
        } else if (
            _score > s1.badgeToBadgeMaxScore[3] &&
            _score <= s1.badgeToBadgeMaxScore[4]
        ) {
            return uint256(RideBadge.Badges.Platinum);
        } else {
            return uint256(RideBadge.Badges.Veteran);
        }
    }

    /**
     * _calculateScore calculates score from driver's reputation details (see params of function)
     *
     *
     * @return Driver's score to determine badge rank | unitless integer
     *
     * Derive Driver's Score Formula:-
     *
     * Score is fundamentally determined based on distance travelled, where the more trips a driver makes,
     * the higher the score. Thus, the base score is directly proportional to:
     *
     * _metresTravelled
     *
     * where _metresTravelled is the total cumulative distance covered by the driver over all trips made.
     *
     * To encourage the completion of trips, the base score would be penalized by the amount of incomplete
     * trips, using:
     *
     *  _countEnd / _countStart
     *
     * which is the ratio of number of trips complete to the number of trips started. This gives:
     *
     * _metresTravelled * (_countEnd / _countStart)
     *
     * Driver score should also be influenced by passenger's rating of the overall trip, thus, the base
     * score is further penalized by the average driver rating over all trips, given by:
     *
     * _totalRating / _countRating
     *
     * where _totalRating is the cumulative rating value by passengers over all trips and _countRating is
     * the total number of rates by those passengers. The rating penalization is also divided by the max
     * possible rating score to make the penalization a ratio:
     *
     * (_totalRating / _countRating) / _maxRating
     *
     * The score formula is given by:
     *
     * _metresTravelled * (_countEnd / _countStart) * ((_totalRating / _countRating) / _maxRating)
     *
     * which simplifies to:
     *
     * (_metresTravelled * _countEnd * _totalRating) / (_countStart * _countRating * _maxRating)
     *
     * note: Solidity rounds down return value to the nearest whole number.
     *
     * note: Score is used to determine badge rank. To determine which score corresponds to which rank,
     *       can just determine from _metresTravelled, as other variables are just penalization factors.
     */
    function _calculateScore() internal view returns (uint256) {
        StorageBadge storage s1 = _storageBadge();

        uint256 metresTravelled = s1
            .driverToDriverReputation[msg.sender]
            .metresTravelled;
        uint256 countStart = s1.driverToDriverReputation[msg.sender].countStart;
        uint256 countEnd = s1.driverToDriverReputation[msg.sender].countEnd;
        uint256 totalRating = s1
            .driverToDriverReputation[msg.sender]
            .totalRating;
        uint256 countRating = s1
            .driverToDriverReputation[msg.sender]
            .countRating;
        uint256 maxRating = RideLibRater._storageRater().ratingMax;

        if (countStart == 0) {
            return 0;
        } else {
            return
                (metresTravelled * countEnd * totalRating) /
                (countStart * countRating * maxRating);
        }
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "RideLibBadge.sol";

/// @title Badge rank for drivers
contract RideBadge {
    enum Badges {
        Newbie,
        Bronze,
        Silver,
        Gold,
        Platinum,
        Veteran
    } // note: if we edit last badge, rmb edit RideLibBadge._getBadgesCount fn as well

    /**
     * TODO:
     * Check if setBadgesMaxScores is used in other contracts after
     * diamond pattern finalized. if no use then change visibility
     * to external
     */
    /**
     * setBadgesMaxScores maps score to badge
     *
     * @param _badgesMaxScores Score that defines a specific badge rank
     */
    function setBadgesMaxScores(uint256[] memory _badgesMaxScores) external {
        RideLibBadge._setBadgesMaxScores(_badgesMaxScores);
    }

    //////////////////////////////////////////////////////////////////////////////////
    ///// ---------------------------------------------------------------------- /////
    ///// -------------------------- getter functions -------------------------- /////
    ///// ---------------------------------------------------------------------- /////
    //////////////////////////////////////////////////////////////////////////////////

    function getBadgeToBadgeMaxScore(uint256 _badge)
        external
        view
        returns (uint256)
    {
        return RideLibBadge._storageBadge().badgeToBadgeMaxScore[_badge];
    }

    function getDriverToDriverReputation(address _driver)
        external
        view
        returns (RideLibBadge.DriverReputation memory)
    {
        return RideLibBadge._storageBadge().driverToDriverReputation[_driver];
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