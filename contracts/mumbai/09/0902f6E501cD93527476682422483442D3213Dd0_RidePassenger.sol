//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "RideLibPassenger.sol";
import "RideLibFee.sol";
import "RideLibRater.sol";
import "RideLibBadge.sol";
import "RideLibDriver.sol";
import "RideLibTicket.sol";
import "RideLibPenalty.sol";
import "RideLibHolding.sol";
import "RideLibExchange.sol";

contract RidePassenger {
    event RequestTicket(
        address indexed sender,
        bytes32 indexed tixId,
        uint256 fare
    );
    event RequestCancelled(address indexed sender, bytes32 indexed tixId);
    event TripStarted(
        address indexed passenger,
        bytes32 indexed tixId,
        address driver
    );
    event TripEndedPax(address indexed sender, bytes32 indexed tixId);
    event ForceEndPax(address indexed sender, bytes32 indexed tixId);

    /**
     * requestTicket allows passenger to request for ride
     *
     * @param _badge badge rank requested
     * @param _strict whether driver must meet requested badge rank exactly (true) or default - any badge rank equal or greater than (false)
     * @param _minutes estimated time taken from origin to destination as determined by Maps API
     * @param _metres estimated distance from origin to destination as determined by Maps API
     *
     * @custom:event RequestTicket
     */
    function requestTicket(
        bytes32 _keyLocal,
        bytes32 _keyPay,
        uint256 _badge,
        bool _strict,
        uint256 _minutes,
        uint256 _metres
    ) external {
        RideLibDriver._requireNotDriver();
        RideLibTicket._requireNotActive();
        RideLibPenalty._requireNotBanned();
        // RideLibExchange._requireXPerYPriceFeedSupported(_keyLocal, _keyPay); // note: double check on currency supported (check is already done indirectly by _getCancellationFee & _getFare, directly by currency conversion)
        /**
         * Note: if frontend implement correctly, removing this line
         *       RideLibExchange._requireXPerYPriceFeedSupported(_keyLocal, _keyPay);
         *       would NOT be a problem
         */

        RideLibTicket.StorageTicket storage s2 = RideLibTicket._storageTicket();

        uint256 cancellationFeeLocal = RideLibFee._getCancellationFee(
            _keyLocal
        );
        uint256 fareLocal = RideLibFee._getFare(
            _keyLocal,
            _badge,
            _minutes,
            _metres
        );
        uint256 cancellationFeePay;
        uint256 farePay;
        if (_keyLocal == _keyPay) {
            // when local is in crypto token
            cancellationFeePay = cancellationFeeLocal;
            farePay = fareLocal;
        } else {
            cancellationFeePay = RideLibExchange._convertCurrency(
                _keyLocal,
                _keyPay,
                cancellationFeeLocal
            );
            farePay = RideLibExchange._convertCurrency(
                _keyLocal,
                _keyPay,
                fareLocal
            );
        }
        uint256 holdingAmount = RideLibHolding
            ._storageHolding()
            .userToCurrencyKeyToHolding[msg.sender][_keyPay];
        require(
            (holdingAmount > cancellationFeePay) && (holdingAmount > farePay),
            "RidePassenger: Passenger's holding < cancellationFee or fare"
        );

        bytes32 tixId = keccak256(abi.encode(msg.sender, block.timestamp)); // encode gas seems less? but diff very small

        s2.tixIdToTicket[tixId].passenger = msg.sender;
        s2.tixIdToTicket[tixId].badge = _badge;
        s2.tixIdToTicket[tixId].strict = _strict;
        s2.tixIdToTicket[tixId].metres = _metres;
        s2.tixIdToTicket[tixId].keyLocal = _keyLocal;
        s2.tixIdToTicket[tixId].keyPay = _keyPay;
        s2.tixIdToTicket[tixId].cancellationFee = cancellationFeePay;
        s2.tixIdToTicket[tixId].fare = farePay;

        s2.userToTixId[msg.sender] = tixId;

        emit RequestTicket(msg.sender, tixId, farePay);
    }

    /**
     * cancelRequest cancels ticket, can only be called before startTrip
     *
     * @custom:event RequestCancelled
     */
    function cancelRequest() external {
        RideLibPassenger._requirePaxMatchTixPax();
        RideLibPassenger._requireTripNotStart();

        RideLibTicket.StorageTicket storage s2 = RideLibTicket._storageTicket();

        bytes32 tixId = s2.userToTixId[msg.sender];
        address driver = s2.tixIdToTicket[tixId].driver;
        if (driver != address(0)) {
            // case when cancel inbetween driver accepted, but haven't reach passenger
            // give warning at frontend to passenger
            RideLibHolding._transferCurrency(
                tixId,
                s2.tixIdToTicket[tixId].keyPay,
                s2.tixIdToTicket[tixId].cancellationFee,
                msg.sender,
                driver
            );
        }

        RideLibTicket._cleanUp(tixId, msg.sender, driver);

        emit RequestCancelled(msg.sender, tixId); // --> update frontend request pool
    }

    /**
     * startTrip starts the trip, can only be called once driver reached passenger
     *
     * @param _driver driver's address - get via QR scan?
     *
     * @custom:event TripStarted
     */
    function startTrip(address _driver) external {
        RideLibPassenger._requirePaxMatchTixPax();
        RideLibDriver._requireDrvMatchTixDrv(_driver);
        RideLibPassenger._requireTripNotStart();

        RideLibTicket.StorageTicket storage s2 = RideLibTicket._storageTicket();

        bytes32 tixId = s2.userToTixId[msg.sender];
        RideLibBadge
            ._storageBadge()
            .driverToDriverReputation[_driver]
            .countStart += 1;
        s2.tixIdToTicket[tixId].tripStart = true;
        s2.tixIdToTicket[tixId].forceEndTimestamp =
            block.timestamp +
            s2.forceEndDelay;

        emit TripStarted(msg.sender, tixId, _driver); // update frontend
    }

    /**
     * endTripPax ends the trip, can only be called once driver has called either endTripDrv
     *
     * @param _agree agreement from passenger that either destination has been reached or not
     * @param _rating refer _giveRating
     *
     * @custom:event TripEndedPax
     *
     * Driver would select destination reached or not, and event will emit to passenger's UI
     * then passenger would agree if this is true or false (via frontend UI), followed by a rating.
     * No matter what, passenger needs to pay fare, so incentive to passenger to be kind so driver
     * get passenger to destination. This prevents passenger abuse.
     */
    function endTripPax(bool _agree, uint256 _rating) external {
        RideLibPassenger._requirePaxMatchTixPax();
        RideLibPassenger._requireTripInProgress();

        RideLibBadge.StorageBadge storage s1 = RideLibBadge._storageBadge();
        RideLibTicket.StorageTicket storage s2 = RideLibTicket._storageTicket();

        bytes32 tixId = s2.userToTixId[msg.sender];
        address driver = s2.tixIdToDriverEnd[tixId].driver;
        require(driver != address(0), "RidePassenger: Driver must end trip");
        require(
            _agree,
            "RidePassenger: Passenger must agree destination reached or not - indicated by driver"
        );

        RideLibHolding._transferCurrency(
            tixId,
            s2.tixIdToTicket[tixId].keyPay,
            s2.tixIdToTicket[tixId].fare,
            msg.sender,
            driver
        );
        if (s2.tixIdToDriverEnd[tixId].reached) {
            s1.driverToDriverReputation[driver].metresTravelled += s2
                .tixIdToTicket[tixId]
                .metres;
            s1.driverToDriverReputation[driver].countEnd += 1;
        }

        RideLibRater._giveRating(driver, _rating);

        RideLibTicket._cleanUp(tixId, msg.sender, driver);

        emit TripEndedPax(msg.sender, tixId);
    }

    /**
     * forceEndPax can be called after tixIdToTicket[tixId].forceEndTimestamp duration
     * and if driver has NOT called endTripDrv
     *
     * @custom:event ForceEndPax
     *
     * no fare is paid, but driver is temporarily banned for banDuration
     */
    function forceEndPax() external {
        RideLibPassenger._requirePaxMatchTixPax();
        RideLibPassenger._requireTripInProgress(); /** means both parties still active */
        RideLibPassenger._requireForceEndAllowed();

        RideLibTicket.StorageTicket storage s1 = RideLibTicket._storageTicket();

        bytes32 tixId = s1.userToTixId[msg.sender];
        require(
            s1.tixIdToDriverEnd[tixId].driver == address(0),
            "RidePassenger: Driver ended trip"
        ); // TODO: test
        address driver = s1.tixIdToTicket[tixId].driver;

        RideLibPenalty._temporaryBan(driver);
        RideLibRater._giveRating(driver, 1);
        RideLibTicket._cleanUp(tixId, msg.sender, driver);

        emit ForceEndPax(msg.sender, tixId);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "RideLibTicket.sol";

library RideLibPassenger {
    function _requirePaxMatchTixPax() internal view {
        RideLibTicket.StorageTicket storage s1 = RideLibTicket._storageTicket();
        require(
            msg.sender ==
                s1.tixIdToTicket[s1.userToTixId[msg.sender]].passenger,
            "RideLibPassenger: Passenger not match tix passenger"
        );
    }

    function _requireTripNotStart() internal view {
        RideLibTicket.StorageTicket storage s1 = RideLibTicket._storageTicket();
        require(
            !s1.tixIdToTicket[s1.userToTixId[msg.sender]].tripStart,
            "RideLibPassenger: Trip already started"
        );
    }

    function _requireTripInProgress() internal view {
        RideLibTicket.StorageTicket storage s1 = RideLibTicket._storageTicket();
        require(
            s1.tixIdToTicket[s1.userToTixId[msg.sender]].tripStart,
            "RideLibPassenger: Trip not started"
        );
    }

    function _requireForceEndAllowed() internal view {
        RideLibTicket.StorageTicket storage s1 = RideLibTicket._storageTicket();
        require(
            block.timestamp >
                s1.tixIdToTicket[s1.userToTixId[msg.sender]].forceEndTimestamp,
            "RideLibPassenger: Too early"
        );
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

library RideLibTicket {
    bytes32 constant STORAGE_POSITION_TICKET = keccak256("ds.ticket");

    /**
     * @dev if a ticket exists (details not 0) in tixIdToTicket, then it is considered active
     *
     */
    struct Ticket {
        address passenger;
        address driver;
        uint256 badge;
        bool strict;
        uint256 metres;
        bytes32 keyLocal;
        bytes32 keyPay;
        uint256 cancellationFee;
        uint256 fare;
        bool tripStart;
        uint256 forceEndTimestamp;
    }
    // TODO: add location

    /**
     * *Required to confirm if driver did initiate destination reached or not
     */
    struct DriverEnd {
        address driver;
        bool reached;
    }

    struct StorageTicket {
        mapping(address => bytes32) userToTixId;
        mapping(bytes32 => Ticket) tixIdToTicket;
        mapping(bytes32 => DriverEnd) tixIdToDriverEnd;
        uint256 forceEndDelay; // seconds
    }

    function _storageTicket() internal pure returns (StorageTicket storage s) {
        bytes32 position = STORAGE_POSITION_TICKET;
        assembly {
            s.slot := position
        }
    }

    function _requireNotActive() internal view {
        require(
            _storageTicket().userToTixId[msg.sender] == 0,
            "RideLibTicket: Caller is active"
        );
    }

    event ForceEndDelaySet(address indexed sender, uint256 newDelayPeriod);

    function _setForceEndDelay(uint256 _delayPeriod) internal {
        _storageTicket().forceEndDelay = _delayPeriod;

        emit ForceEndDelaySet(msg.sender, _delayPeriod);
    }

    event TicketCleared(address indexed sender, bytes32 indexed tixId);

    /**
     * _cleanUp clears ticket information and set active status of users to false
     *
     * @param _tixId Ticket ID
     * @param _passenger passenger's address
     * @param _driver driver's address
     *
     * @custom:event TicketCleared
     */
    function _cleanUp(
        bytes32 _tixId,
        address _passenger,
        address _driver
    ) internal {
        StorageTicket storage s1 = _storageTicket();
        delete s1.tixIdToTicket[_tixId];
        delete s1.tixIdToDriverEnd[_tixId];
        delete s1.userToTixId[_passenger];
        delete s1.userToTixId[_driver];

        emit TicketCleared(msg.sender, _tixId);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "RideLibBadge.sol";
import "RideLibAccessControl.sol";
import "RideLibCurrencyRegistry.sol";

library RideLibFee {
    bytes32 constant STORAGE_POSITION_FEE = keccak256("ds.fee");

    struct StorageFee {
        mapping(bytes32 => uint256) currencyKeyToCancellationFee;
        mapping(bytes32 => uint256) currencyKeyToBaseFee;
        mapping(bytes32 => uint256) currencyKeyToCostPerMinute;
        mapping(bytes32 => mapping(uint256 => uint256)) currencyKeyToBadgeToCostPerMetre;
    }

    function _storageFee() internal pure returns (StorageFee storage s) {
        bytes32 position = STORAGE_POSITION_FEE;
        assembly {
            s.slot := position
        }
    }

    event FeeSetCancellation(address indexed sender, uint256 fee);

    /**
     * _setCancellationFee sets cancellation fee
     *
     * @param _key        | currency key
     * @param _cancellationFee | unit in Wei
     */
    function _setCancellationFee(bytes32 _key, uint256 _cancellationFee)
        internal
    {
        RideLibAccessControl._requireOnlyRole(
            RideLibAccessControl.STRATEGIST_ROLE
        );
        RideLibCurrencyRegistry._requireCurrencySupported(_key);
        _storageFee().currencyKeyToCancellationFee[_key] = _cancellationFee; // input format: token in Wei

        emit FeeSetCancellation(msg.sender, _cancellationFee);
    }

    event FeeSetBase(address indexed sender, uint256 fee);

    /**
     * _setBaseFee sets base fee
     *
     * @param _key     | currency key
     * @param _baseFee | unit in Wei
     */
    function _setBaseFee(bytes32 _key, uint256 _baseFee) internal {
        RideLibAccessControl._requireOnlyRole(
            RideLibAccessControl.STRATEGIST_ROLE
        );
        RideLibCurrencyRegistry._requireCurrencySupported(_key);
        _storageFee().currencyKeyToBaseFee[_key] = _baseFee; // input format: token in Wei

        emit FeeSetBase(msg.sender, _baseFee);
    }

    event FeeSetCostPerMinute(address indexed sender, uint256 fee);

    /**
     * _setCostPerMinute sets cost per minute
     *
     * @param _key           | currency key
     * @param _costPerMinute | unit in Wei
     */
    function _setCostPerMinute(bytes32 _key, uint256 _costPerMinute) internal {
        RideLibAccessControl._requireOnlyRole(
            RideLibAccessControl.STRATEGIST_ROLE
        );
        RideLibCurrencyRegistry._requireCurrencySupported(_key);
        _storageFee().currencyKeyToCostPerMinute[_key] = _costPerMinute; // input format: token in Wei

        emit FeeSetCostPerMinute(msg.sender, _costPerMinute);
    }

    event FeeSetCostPerMetre(address indexed sender, uint256[] fee);

    /**
     * _setCostPerMetre sets cost per metre
     *
     * @param _key          | currency key
     * @param _costPerMetre | unit in Wei
     */
    function _setCostPerMetre(bytes32 _key, uint256[] memory _costPerMetre)
        internal
    {
        RideLibAccessControl._requireOnlyRole(
            RideLibAccessControl.STRATEGIST_ROLE
        );
        RideLibCurrencyRegistry._requireCurrencySupported(_key);
        require(
            _costPerMetre.length == RideLibBadge._getBadgesCount(),
            "RideLibFee: Input length must be equal RideBadge.Badges"
        );
        for (uint256 i = 0; i < _costPerMetre.length; i++) {
            _storageFee().currencyKeyToBadgeToCostPerMetre[_key][
                    i
                ] = _costPerMetre[i]; // input format: token in Wei // rounded down
        }

        emit FeeSetCostPerMetre(msg.sender, _costPerMetre);
    }

    /**
     * _getFare calculates the fare of a trip.
     *
     * @param _key             | currency key
     * @param _badge           | badge
     * @param _metresTravelled | unit in metre
     * @param _minutesTaken    | unit in minute
     *
     * @return Fare | unit in Wei
     *
     * _metresTravelled and _minutesTaken are rounded down,
     * for example, if _minutesTaken is 1.5 minutes (90 seconds) then round to 1 minute
     * if _minutesTaken is 0.5 minutes (30 seconds) then round to 0 minute
     */
    function _getFare(
        bytes32 _key,
        uint256 _badge,
        uint256 _minutesTaken,
        uint256 _metresTravelled
    ) internal view returns (uint256) {
        RideLibCurrencyRegistry._requireCurrencySupported(_key);
        StorageFee storage s1 = _storageFee();

        uint256 baseFee = s1.currencyKeyToBaseFee[_key]; // not much diff in terms of gas to assign temporary variable vs using directly (below)
        uint256 costPerMinute = s1.currencyKeyToCostPerMinute[_key];
        uint256 costPerMetre = s1.currencyKeyToBadgeToCostPerMetre[_key][
            _badge
        ];

        return (baseFee +
            (costPerMinute * _minutesTaken) +
            (costPerMetre * _metresTravelled));
    }

    function _getCancellationFee(bytes32 _key) internal view returns (uint256) {
        RideLibCurrencyRegistry._requireCurrencySupported(_key);
        return _storageFee().currencyKeyToCancellationFee[_key];
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

import "Strings.sol";

library RideLibAccessControl {
    bytes32 constant STORAGE_POSITION_ACCESSCONTROL =
        keccak256("ds.accesscontrol");

    bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 constant MAINTAINER_ROLE = keccak256("MAINTAINER_ROLE");
    bytes32 constant STRATEGIST_ROLE = keccak256("STRATEGIST_ROLE");
    bytes32 constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    bytes32 constant REVIEWER_ROLE = keccak256("REVIEWER_ROLE");

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

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "RideLibAccessControl.sol";

// @Note CurrencyRegistry is separated from Exchange mainly to ease checks for Holding and Fee, and to separately register fiat and crypto easily
library RideLibCurrencyRegistry {
    bytes32 constant STORAGE_POSITION_CURRENCYREGISTRY =
        keccak256("ds.currencyregistry");

    struct StorageCurrencyRegistry {
        mapping(bytes32 => bool) currencyKeyToSupported;
        mapping(bytes32 => bool) currencyKeyToCrypto;
    }

    function _storageCurrencyRegistry()
        internal
        pure
        returns (StorageCurrencyRegistry storage s)
    {
        bytes32 position = STORAGE_POSITION_CURRENCYREGISTRY;
        assembly {
            s.slot := position
        }
    }

    function _requireCurrencySupported(bytes32 _key) internal view {
        require(
            _storageCurrencyRegistry().currencyKeyToSupported[_key],
            "RideLibCurrencyRegistry: Currency not supported"
        );
    }

    // _requireIsCrypto does NOT check if is ERC20
    function _requireIsCrypto(bytes32 _key) internal view {
        require(
            _storageCurrencyRegistry().currencyKeyToCrypto[_key],
            "RideLibCurrencyRegistry: Not crypto"
        );
    }

    // code must follow: ISO-4217 Currency Code Standard: https://www.iso.org/iso-4217-currency-codes.html
    function _registerFiat(string memory _code) internal returns (bytes32) {
        require(
            bytes(_code).length != 0,
            "RideLibCurrencyRegistry: Empty code string"
        );
        bytes32 key = _encode_code(_code); //keccak256(abi.encode(_code));
        _register(key);
        return key;
    }

    function _encode_code(string memory _code) internal pure returns (bytes32) {
        return keccak256(abi.encode(_code));
    }

    function _registerCrypto(address _token) internal returns (bytes32) {
        require(
            _token != address(0),
            "RideLibCurrencyRegistry: Zero token address"
        );
        bytes32 key = _encode_token(_token); //bytes32(uint256(uint160(_token)) << 96);
        _register(key);
        _storageCurrencyRegistry().currencyKeyToCrypto[key] = true;
        return key;
    }

    function _encode_token(address _token) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_token)) << 96);
    }

    event CurrencyRegistered(address indexed sender, bytes32 key);

    function _register(bytes32 _key) internal {
        RideLibAccessControl._requireOnlyRole(
            RideLibAccessControl.STRATEGIST_ROLE
        );
        _storageCurrencyRegistry().currencyKeyToSupported[_key] = true;

        emit CurrencyRegistered(msg.sender, _key);
    }

    event CurrencyRemoved(address indexed sender, bytes32 key);

    function _removeCurrency(bytes32 _key) internal {
        RideLibAccessControl._requireOnlyRole(
            RideLibAccessControl.STRATEGIST_ROLE
        );
        _requireCurrencySupported(_key);
        StorageCurrencyRegistry storage s1 = _storageCurrencyRegistry();
        delete s1.currencyKeyToSupported[_key]; // delete cheaper than set false

        if (s1.currencyKeyToCrypto[_key]) {
            delete s1.currencyKeyToCrypto[_key];
        }

        emit CurrencyRemoved(msg.sender, _key);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "RideLibBadge.sol";
import "RideLibTicket.sol";

library RideLibDriver {
    function _requireDrvMatchTixDrv(address _driver) internal view {
        RideLibTicket.StorageTicket storage s1 = RideLibTicket._storageTicket();
        require(
            _driver == s1.tixIdToTicket[s1.userToTixId[msg.sender]].driver,
            "RideLibDriver: Driver not match ticket driver"
        );
    }

    function _requireIsDriver() internal view {
        require(
            RideLibBadge
                ._storageBadge()
                .driverToDriverReputation[msg.sender]
                .id != 0,
            "RideLibDriver: Caller not driver"
        );
    }

    function _requireNotDriver() internal view {
        require(
            RideLibBadge
                ._storageBadge()
                .driverToDriverReputation[msg.sender]
                .id == 0,
            "RideLibDriver: Caller is driver"
        );
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

import "RideLibCurrencyRegistry.sol";

library RideLibHolding {
    bytes32 constant STORAGE_POSITION_HOLDING = keccak256("ds.holding");

    struct StorageHolding {
        mapping(address => mapping(bytes32 => uint256)) userToCurrencyKeyToHolding;
    }

    function _storageHolding()
        internal
        pure
        returns (StorageHolding storage s)
    {
        bytes32 position = STORAGE_POSITION_HOLDING;
        assembly {
            s.slot := position
        }
    }

    event CurrencyTransferred(
        address indexed decrease,
        bytes32 indexed tixId,
        address increase,
        bytes32 key,
        uint256 amount
    );

    /**
     * _transfer rebalances _amount tokens from one address to another
     *
     * @param _tixId Ticket ID
     * @param _key currency key
     * @param _amount | unit in token
     * @param _decrease address to decrease tokens by
     * @param _increase address to increase tokens by
     *
     * @custom:event CurrencyTransferred
     *
     * not use msg.sender instead of _decrease param? in case admin is required to sort things out
     */
    function _transferCurrency(
        bytes32 _tixId,
        bytes32 _key,
        uint256 _amount,
        address _decrease,
        address _increase
    ) internal {
        StorageHolding storage s1 = _storageHolding();

        s1.userToCurrencyKeyToHolding[_decrease][_key] -= _amount;
        s1.userToCurrencyKeyToHolding[_increase][_key] += _amount;

        emit CurrencyTransferred(_decrease, _tixId, _increase, _key, _amount); // note decrease is sender
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "RideLibAccessControl.sol";
import "RideLibCurrencyRegistry.sol";

import "AggregatorV3Interface.sol";

library RideLibExchange {
    bytes32 constant STORAGE_POSITION_EXCHANGE = keccak256("ds.exchange");

    struct DerivedPriceFeedDetails {
        bytes32 keyShared;
        address numerator;
        address denominator;
        bool numeratorInverse;
        bool denominatorInverse;
    }

    struct StorageExchange {
        mapping(bytes32 => mapping(bytes32 => address)) xToYToXAddedPerYPriceFeed;
        mapping(bytes32 => mapping(bytes32 => bool)) xToYToXPerYInverse;
        mapping(bytes32 => mapping(bytes32 => DerivedPriceFeedDetails)) xToYToXPerYDerivedPriceFeedDetails;
        mapping(bytes32 => mapping(bytes32 => bool)) xToYToXPerYInverseDerived; // note: don't share with original inverse mapping as in future if added as base case, it would override derived case
        // useful for removal
        mapping(bytes32 => mapping(bytes32 => uint256)) xToYToBaseKeyCount; // example: X => Shared => count
    }

    function _storageExchange()
        internal
        pure
        returns (StorageExchange storage s)
    {
        bytes32 position = STORAGE_POSITION_EXCHANGE;
        assembly {
            s.slot := position
        }
    }

    function _requireAddedXPerYPriceFeedSupported(bytes32 _keyX, bytes32 _keyY)
        internal
        view
    {
        require(
            _storageExchange().xToYToXAddedPerYPriceFeed[_keyX][_keyY] !=
                address(0),
            "RideLibExchange: Price feed not supported"
        );
    }

    function _requireDerivedXPerYPriceFeedSupported(
        bytes32 _keyX,
        bytes32 _keyY
    ) internal view {
        require(
            _storageExchange()
            .xToYToXPerYDerivedPriceFeedDetails[_keyX][_keyY].numerator !=
                address(0),
            "RideLibExchange: Derived price feed not supported"
        ); // one check enough
    }

    event PriceFeedAdded(
        address indexed sender,
        bytes32 keyX,
        bytes32 keyY,
        address priceFeed
    );

    /**
     * NOTE: to add ETH/USD = $3,000 price feed (displayed on chainlink) --> read as USD per ETH (X per Y)
     * do: x = USD, y = ETH
     */
    function _addXPerYPriceFeed(
        bytes32 _keyX,
        bytes32 _keyY,
        address _priceFeed
    ) internal {
        RideLibAccessControl._requireOnlyRole(
            RideLibAccessControl.STRATEGIST_ROLE
        );
        RideLibCurrencyRegistry._requireCurrencySupported(_keyX);
        RideLibCurrencyRegistry._requireCurrencySupported(_keyY);

        require(
            _priceFeed != address(0),
            "RideLibExchange: Zero price feed address"
        );
        StorageExchange storage s1 = _storageExchange();
        require(
            s1.xToYToXAddedPerYPriceFeed[_keyX][_keyY] == address(0),
            "RideLibExchange: Price feed already supported"
        );
        s1.xToYToXAddedPerYPriceFeed[_keyX][_keyY] = _priceFeed;
        s1.xToYToXAddedPerYPriceFeed[_keyY][_keyX] = _priceFeed; // reverse pairing
        s1.xToYToXPerYInverse[_keyY][_keyX] = true;

        emit PriceFeedAdded(msg.sender, _keyX, _keyY, _priceFeed);
    }

    event PriceFeedDerived(
        address indexed sender,
        bytes32 keyX,
        bytes32 keyY,
        bytes32 keyShared
    );

    /**
     * NOTE: to derive ETH/EUR = €2,823 (chainlink equivalent) --> read as EUR per ETH (X per Y), from
     * ETH/USD = $3,000 price feed (displayed on chainlink) --> read as USD per ETH
     * EUR/USD = $1.14 price feed (displayed on chainlink) --> read as USD per EUR
     * do: x = EUR, y = ETH, shared = USD
     */
    function _deriveXPerYPriceFeed(
        bytes32 _keyX,
        bytes32 _keyY,
        bytes32 _keyShared
    ) internal {
        RideLibAccessControl._requireOnlyRole(
            RideLibAccessControl.STRATEGIST_ROLE
        );
        require(
            _keyX != _keyY,
            "RideLibExchange: Underlying currency key cannot be identical"
        );
        _requireAddedXPerYPriceFeedSupported(_keyX, _keyShared);
        _requireAddedXPerYPriceFeedSupported(_keyY, _keyShared);

        StorageExchange storage s1 = _storageExchange();
        require(
            s1.xToYToXPerYDerivedPriceFeedDetails[_keyX][_keyY].numerator ==
                address(0),
            "RideLibExchange: Derived price feed already supported"
        );

        s1.xToYToXPerYDerivedPriceFeedDetails[_keyX][_keyY].numerator = s1
            .xToYToXAddedPerYPriceFeed[_keyX][_keyShared];
        s1.xToYToXPerYDerivedPriceFeedDetails[_keyX][_keyY].denominator = s1
            .xToYToXAddedPerYPriceFeed[_keyY][_keyShared];
        s1
        .xToYToXPerYDerivedPriceFeedDetails[_keyX][_keyY]
            .keyShared = _keyShared;

        // set inverse
        s1.xToYToXPerYDerivedPriceFeedDetails[_keyY][_keyX].numerator = s1
            .xToYToXAddedPerYPriceFeed[_keyX][_keyShared];
        s1.xToYToXPerYDerivedPriceFeedDetails[_keyY][_keyX].denominator = s1
            .xToYToXAddedPerYPriceFeed[_keyY][_keyShared];
        s1
        .xToYToXPerYDerivedPriceFeedDetails[_keyY][_keyX]
            .keyShared = _keyShared;

        s1.xToYToXPerYInverseDerived[_keyY][_keyX] = true;

        // set underlying inverse state
        if (s1.xToYToXPerYInverse[_keyX][_keyShared]) {
            s1
            .xToYToXPerYDerivedPriceFeedDetails[_keyX][_keyY]
                .numeratorInverse = true;
            s1
            .xToYToXPerYDerivedPriceFeedDetails[_keyY][_keyX]
                .numeratorInverse = true;
        }
        if (s1.xToYToXPerYInverse[_keyY][_keyShared]) {
            s1
            .xToYToXPerYDerivedPriceFeedDetails[_keyX][_keyY]
                .denominatorInverse = true;
            s1
            .xToYToXPerYDerivedPriceFeedDetails[_keyY][_keyX]
                .denominatorInverse = true;
        }

        s1.xToYToBaseKeyCount[_keyX][_keyShared] += 1;
        s1.xToYToBaseKeyCount[_keyY][_keyShared] += 1;

        emit PriceFeedDerived(msg.sender, _keyX, _keyY, _keyShared);
    }

    event AddedPriceFeedRemoved(address indexed sender, address priceFeed);

    function _removeAddedXPerYPriceFeed(bytes32 _keyX, bytes32 _keyY) internal {
        RideLibAccessControl._requireOnlyRole(
            RideLibAccessControl.STRATEGIST_ROLE
        );
        _requireAddedXPerYPriceFeedSupported(_keyX, _keyY);

        StorageExchange storage s1 = _storageExchange();

        require(
            s1.xToYToBaseKeyCount[_keyX][_keyY] == 0,
            "RideLibExchange: Base key being used"
        );

        address priceFeed = s1.xToYToXAddedPerYPriceFeed[_keyX][_keyY];

        delete s1.xToYToXAddedPerYPriceFeed[_keyX][_keyY];
        delete s1.xToYToXAddedPerYPriceFeed[_keyY][_keyX]; // reverse pairing
        delete s1.xToYToXPerYInverse[_keyX][_keyY];
        delete s1.xToYToXPerYInverse[_keyY][_keyX];

        // require(
        //     s1.xToYToXAddedPerYPriceFeed[_keyX][_keyY] == address(0),
        //     "price feed not removed 1"
        // );
        // require(
        //     s1.xToYToXAddedPerYPriceFeed[_keyY][_keyX] == address(0),
        //     "price feed not removed 2"
        // ); // reverse pairing
        // require(!s1.xToYToXPerYInverse[_keyY][_keyX], "reverse not removed");

        emit AddedPriceFeedRemoved(msg.sender, priceFeed);

        // TODO: remove price feed derived !!!! expand this fn or new fn ?????
    }

    event DerivedPriceFeedRemoved(
        address indexed sender,
        bytes32 keyX,
        bytes32 keyY
    );

    function _removeDerivedXPerYPriceFeed(bytes32 _keyX, bytes32 _keyY)
        internal
    {
        RideLibAccessControl._requireOnlyRole(
            RideLibAccessControl.STRATEGIST_ROLE
        );
        _requireDerivedXPerYPriceFeedSupported(_keyX, _keyY);

        StorageExchange storage s1 = _storageExchange();

        bytes32 baseKeyShared = s1
        .xToYToXPerYDerivedPriceFeedDetails[_keyX][_keyY].keyShared;

        s1.xToYToBaseKeyCount[_keyX][baseKeyShared] -= 1;
        s1.xToYToBaseKeyCount[_keyY][baseKeyShared] -= 1;

        delete s1.xToYToXPerYDerivedPriceFeedDetails[_keyX][_keyY];
        delete s1.xToYToXPerYDerivedPriceFeedDetails[_keyY][_keyX]; // reverse pairing
        delete s1.xToYToXPerYInverseDerived[_keyX][_keyY];
        delete s1.xToYToXPerYInverseDerived[_keyY][_keyX];

        emit DerivedPriceFeedRemoved(msg.sender, _keyX, _keyY);
    }

    function _convertCurrency(
        bytes32 _keyX,
        bytes32 _keyY, /** target to convert amount into */
        uint256 _amountX /** in wei */
    ) internal view returns (uint256) {
        StorageExchange storage s1 = _storageExchange();

        uint256 xPerYWei;

        if (s1.xToYToXAddedPerYPriceFeed[_keyX][_keyY] != address(0)) {
            xPerYWei = _getAddedXPerYInWei(_keyX, _keyY);
        } else {
            xPerYWei = _getDerivedXPerYInWei(_keyX, _keyY);
        }

        if (
            s1.xToYToXPerYInverse[_keyX][_keyY] ||
            s1.xToYToXPerYInverseDerived[_keyX][_keyY]
        ) {
            return _convertInverse(xPerYWei, _amountX);
        } else {
            return _convertDirect(xPerYWei, _amountX);
        }
    }

    function _convertDirect(uint256 _xPerYWei, uint256 _amountX)
        internal
        pure
        returns (uint256)
    {
        return ((_amountX * 10**18) / _xPerYWei); // note: no rounding occurs as value is converted into wei
    }

    function _convertInverse(uint256 _xPerYWei, uint256 _amountX)
        internal
        pure
        returns (uint256)
    {
        return (_amountX * _xPerYWei) / 10**18; // note: no rounding occurs as value is converted into wei
    }

    function _getAddedXPerYInWei(bytes32 _keyX, bytes32 _keyY)
        internal
        view
        returns (uint256)
    {
        _requireAddedXPerYPriceFeedSupported(_keyX, _keyY);
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            _storageExchange().xToYToXAddedPerYPriceFeed[_keyX][_keyY]
        );
        (, int256 xPerY, , , ) = priceFeed.latestRoundData();
        uint256 decimals = priceFeed.decimals();
        return uint256(uint256(xPerY) * 10**(18 - decimals)); // convert to wei
    }

    function _getDerivedXPerYInWei(bytes32 _keyX, bytes32 _keyY)
        internal
        view
        returns (uint256)
    {
        _requireDerivedXPerYPriceFeedSupported(_keyX, _keyY);

        StorageExchange storage s1 = _storageExchange();

        // numerator
        AggregatorV3Interface priceFeedNumerator = AggregatorV3Interface(
            s1.xToYToXPerYDerivedPriceFeedDetails[_keyX][_keyY].numerator
        );
        (, int256 xPerYNumerator, , , ) = priceFeedNumerator.latestRoundData();
        uint256 decimalsNumerator = priceFeedNumerator.decimals();
        uint256 priceFeedNumeratorWei = uint256(
            uint256(xPerYNumerator) * 10**(18 - decimalsNumerator)
        ); // convert to wei
        bool isNumeratorInversed = s1
        .xToYToXPerYDerivedPriceFeedDetails[_keyX][_keyY].numeratorInverse;

        // denominator
        AggregatorV3Interface priceFeedDenominator = AggregatorV3Interface(
            s1.xToYToXPerYDerivedPriceFeedDetails[_keyX][_keyY].denominator
        );
        (, int256 xPerYDenominator, , , ) = priceFeedDenominator
            .latestRoundData();
        uint256 decimalsDenominator = priceFeedDenominator.decimals();
        uint256 priceFeedDenominatorWei = uint256(
            uint256(xPerYDenominator) * 10**(18 - decimalsDenominator)
        ); // convert to wei
        bool isDenominatorInversed = s1
        .xToYToXPerYDerivedPriceFeedDetails[_keyX][_keyY].denominatorInverse;

        uint256 xPerYWei;

        if (!isNumeratorInversed && !isDenominatorInversed) {
            xPerYWei =
                (priceFeedNumeratorWei * (10**18)) /
                priceFeedDenominatorWei;
        } else if (!isNumeratorInversed && isDenominatorInversed) {
            xPerYWei =
                (priceFeedNumeratorWei * (10**18)) /
                ((((10**18) * (10**18)) / priceFeedDenominatorWei));
        } else if (isNumeratorInversed && !isDenominatorInversed) {
            xPerYWei =
                ((((10**18) * (10**18)) / priceFeedNumeratorWei) * (10**18)) /
                priceFeedDenominatorWei;
        } else if (isNumeratorInversed && isDenominatorInversed) {
            xPerYWei =
                ((10**18) * (10**18)) /
                ((priceFeedNumeratorWei * (10**18)) / priceFeedDenominatorWei);
        } else {
            revert(
                "RideLibExchange: This revert should not ever be run - something seriously wrong with code"
            );
        }

        return xPerYWei;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}