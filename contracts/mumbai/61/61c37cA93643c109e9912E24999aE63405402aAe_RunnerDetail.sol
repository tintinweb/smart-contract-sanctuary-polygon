//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "LibRunnerDetail.sol";

import "IHubLibraryEvents.sol";

contract RunnerDetail is IHubLibraryEvents {
    function getRunnerToRunnerDetail(address _runner)
        external
        view
        returns (LibRunnerDetail.RunnerDetail memory)
    {
        return
            LibRunnerDetail._storageRunnerDetail().runnerToRunnerDetail[
                _runner
            ];
    }

    function calculateRunnerScore(address _runner)
        external
        view
        returns (uint256)
    {
        return LibRunnerDetail._calculateRunnerScore(_runner);
    }

    // note: calculate externally
    // function calculateCollectiveScore(address _hive)
    //     external
    //     view
    //     returns (uint256)
    // {
    //     address[] memory runners = LibRunnerDetail
    //         ._storageRunnerDetail()
    //         .hiveToRunners[_hive];
    //     uint256 metresTravelled;
    //     uint256 countStart;
    //     uint256 countEnd;
    //     uint256 totalRating;
    //     uint256 countRating;
    //     uint256 maxRating;
    //     for (uint256 i = 0; i < runners.length; i++) {
    //         (
    //             uint256 _metresTravelled,
    //             uint256 _countStart,
    //             uint256 _countEnd,
    //             uint256 _totalRating,
    //             uint256 _countRating,
    //             uint256 _maxRating
    //         ) = LibRunnerDetail._getRunnerScoreDetail(runners[i]);
    //         metresTravelled += _metresTravelled;
    //         countStart += _countStart;
    //         countEnd += _countEnd;
    //         totalRating += _totalRating;
    //         countRating += _countRating;
    //         maxRating += _maxRating;
    //     }
    //     if (countStart == 0) {
    //         return 0;
    //     } else {
    //         return
    //             (metresTravelled * countEnd * totalRating) /
    //             (countStart * countRating * maxRating);
    //     }
    // }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "LibRater.sol";
import "LibAccessControl.sol";

library LibRunnerDetail {
    bytes32 constant STORAGE_POSITION_RUNNERDETAIL =
        keccak256("ds.runnerdetail");

    /**
     * lifetime cumulative values of Runners
     */
    struct RunnerDetail {
        uint256 id;
        string uri;
        address hive;
        uint256 maxMetresPerTrip; // TODO: necessary? when ticket showed to runner, he can see destination and metres and choose to accept or not!!
        uint256 metresTravelled;
        uint256 countStart;
        uint256 countEnd;
        uint256 totalRating;
        uint256 countRating;
    }

    struct StorageRunnerDetail {
        mapping(address => RunnerDetail) runnerToRunnerDetail;
        // NOTE: on hiveToRunners
        // any state change operation is to be strictly "push" type
        // otherwise any read / loop strictly used in external functions
        // for example RunnerDetail.calculateCollectiveScore
        // mapping(address => address[]) hiveToRunners;
    }

    function _storageRunnerDetail()
        internal
        pure
        returns (StorageRunnerDetail storage s)
    {
        bytes32 position = STORAGE_POSITION_RUNNERDETAIL;
        assembly {
            s.slot := position
        }
    }

    /**
     * _calculateScore calculates score from runner's reputation detail (see params of function)
     *
     *
     * @return Runner's score | unitless integer
     *
     * Derive Runner's Score Formula:-
     *
     * Score is fundamentally determined based on distance travelled, where the more trips a runner makes,
     * the higher the score. Thus, the base score is directly proportional to:
     *
     * _metresTravelled
     *
     * where _metresTravelled is the total cumulative distance covered by the runner over all trips made.
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
     * Runner score should also be influenced by passenger's rating of the overall trip, thus, the base
     * score is further penalized by the average runner rating over all trips, given by:
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
     * note: To determine which score corresponds to which rank,
     *       can just determine from _metresTravelled, as other variables are just penalization factors.
     */
    function _calculateRunnerScore(address _runner)
        internal
        view
        returns (uint256)
    {
        StorageRunnerDetail storage s1 = _storageRunnerDetail();

        (
            uint256 metresTravelled,
            uint256 countStart,
            uint256 countEnd,
            uint256 totalRating,
            uint256 countRating,
            uint256 maxRating
        ) = _getRunnerScoreDetail(_runner);

        if (countStart == 0) {
            return 0;
        } else {
            return
                (metresTravelled * countEnd * totalRating) /
                (countStart * countRating * maxRating);
        }
    }

    function _getRunnerScoreDetail(address _runner)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        StorageRunnerDetail storage s1 = _storageRunnerDetail();

        uint256 metresTravelled = s1
            .runnerToRunnerDetail[_runner]
            .metresTravelled;
        uint256 countStart = s1.runnerToRunnerDetail[_runner].countStart;
        uint256 countEnd = s1.runnerToRunnerDetail[_runner].countEnd;
        uint256 totalRating = s1.runnerToRunnerDetail[_runner].totalRating;
        uint256 countRating = s1.runnerToRunnerDetail[_runner].countRating;
        uint256 maxRating = LibRater._storageRater().ratingMax;

        return (
            metresTravelled,
            countStart,
            countEnd,
            totalRating,
            countRating,
            maxRating
        );
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "LibJobBoard.sol";
import "LibRunnerDetail.sol";
import "LibRequestor.sol";
import "LibAccessControl.sol";

library LibRater {
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
        LibAccessControl._requireOnlyRole(LibAccessControl.STRATEGIST_ROLE);
        require(_min > 0, "LibRater: cannot have zero rating bound");
        require(
            _max > _min,
            "LibRater: maximum rating must be more than minimum rating"
        );
        StorageRater storage s1 = _storageRater();
        s1.ratingMin = _min;
        s1.ratingMax = _max;

        emit SetRatingBounds(msg.sender, _min, _max);
    }

    event RatingGiven(address indexed sender, uint256 rating);

    function _giveRating(bytes32 _jobId, uint256 _rating) internal {
        LibRequestor._requireMatchJobIdRequestor(msg.sender, _jobId);

        LibJobBoard.StorageJobBoard storage s3 = LibJobBoard._storageJobBoard();

        require(
            !s3.jobIdToJobDetail[_jobId].rated,
            "LibRater: job already rated"
        );

        require(
            s3.jobIdToJobDetail[_jobId].state ==
                LibJobBoard.JobState.Completed ||
                s3.jobIdToJobDetail[_jobId].state ==
                LibJobBoard.JobState.Cancelled,
            "LibRater: job state not completed or cancelled"
        );

        LibRunnerDetail.StorageRunnerDetail storage s1 = LibRunnerDetail
            ._storageRunnerDetail();
        StorageRater storage s2 = _storageRater();

        // require(s2.ratingMax > 0, "maximum rating must be more than zero");
        // require(s2.ratingMin > 0, "minimum rating must be more than zero");
        // since remove greater than 0 check, makes pax call more gas efficient,
        // but make sure _setRatingBounds called at init
        require(
            _rating >= s2.ratingMin && _rating <= s2.ratingMax,
            "LibRater: rating must be within min and max ratings (inclusive)"
        );

        address runner = s3.jobIdToJobDetail[_jobId].runner;

        s1.runnerToRunnerDetail[runner].totalRating += _rating;
        s1.runnerToRunnerDetail[runner].countRating += 1;

        s3.jobIdToJobDetail[_jobId].rated = true;

        emit RatingGiven(msg.sender, _rating);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "LibHolding.sol";
import "LibRunnerDetail.sol";
import "LibAccessControl.sol";

library LibJobBoard {
    bytes32 constant STORAGE_POSITION_JOBBOARD = keccak256("ds.jobboard");

    enum JobState {
        Pending,
        Accepted,
        Cancelled,
        Collected,
        Delivered,
        Completed
    }

    struct JobDetail {
        JobState state;
        address requestor;
        address runner;
        address package; // set by requester
        bytes32 locationPackage;
        bytes32 locationDestination;
        bytes32 keyLocal;
        bytes32 keyTransact;
        uint256 metres;
        uint256 value;
        uint256 cancellationFee;
        uint256 disputeExpiryTimestamp;
        bool packageVerified;
        bool dispute;
        bool rated;
        bool collectStatsRecorded;
    }

    struct StorageJobBoard {
        mapping(bytes32 => JobDetail) jobIdToJobDetail;
        mapping(address => uint256) userToJobIdCount;
        uint256 jobLifespan;
        uint256 minDisputeDuration;
        mapping(address => uint256) hiveToDisputeDuration;
    }

    function _storageJobBoard()
        internal
        pure
        returns (StorageJobBoard storage s)
    {
        bytes32 position = STORAGE_POSITION_JOBBOARD;
        assembly {
            s.slot := position
        }
    }

    function _requireNotActive() internal view {
        require(
            _storageJobBoard().userToJobIdCount[msg.sender] == 0,
            "LibJobBoard: caller is active"
        );
    }

    function _requireDisputePeriodExpired(bytes32 _jobId) internal view {
        require(
            block.timestamp >
                _storageJobBoard()
                    .jobIdToJobDetail[_jobId]
                    .disputeExpiryTimestamp,
            "LibJobBoard: dispute period not expired"
        );
    }

    event JobLifespanSet(address indexed sender, uint256 duration);

    function _setJobLifespan(uint256 _duration) internal {
        LibAccessControl._requireOnlyRole(LibAccessControl.STRATEGIST_ROLE);

        _storageJobBoard().jobLifespan = _duration;

        emit JobLifespanSet(msg.sender, _duration);
    }

    event MinDisputeDurationSet(address indexed sender, uint256 duration);

    function _setMinDisputeDuration(uint256 _duration) internal {
        LibAccessControl._requireOnlyRole(LibAccessControl.STRATEGIST_ROLE);

        _storageJobBoard().minDisputeDuration = _duration;

        emit MinDisputeDurationSet(msg.sender, _duration);
    }

    event HiveDisputeDurationSet(address indexed sender, uint256 duration);

    function _setHiveToDisputeDuration(uint256 _duration) internal {
        LibAccessControl._requireOnlyRole(LibAccessControl.HIVE_ROLE);

        StorageJobBoard storage s1 = _storageJobBoard();

        require(
            _duration >= s1.minDisputeDuration,
            "LibJobBoard: duration less than minimum duration"
        );

        s1.hiveToDisputeDuration[msg.sender] = _duration;

        emit HiveDisputeDurationSet(msg.sender, _duration);
    }

    function _setJobDisputeExpiry(bytes32 _jobId) internal {
        StorageJobBoard storage s1 = _storageJobBoard();

        uint256 disputeDuration = s1.hiveToDisputeDuration[
            LibRunnerDetail
                ._storageRunnerDetail()
                .runnerToRunnerDetail[msg.sender]
                .hive
        ];

        if (disputeDuration < s1.minDisputeDuration) {
            disputeDuration = s1.minDisputeDuration;
        }

        s1.jobIdToJobDetail[_jobId].disputeExpiryTimestamp =
            block.timestamp +
            disputeDuration;
    }

    event JobCleared(address indexed sender, bytes32 indexed jobId);

    function _clearJob(bytes32 _jobId) internal {
        StorageJobBoard storage s1 = _storageJobBoard();

        delete s1.jobIdToJobDetail[_jobId];

        emit JobCleared(msg.sender, _jobId);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "LibCurrencyRegistry.sol";
import "LibJobBoard.sol";

library LibHolding {
    bytes32 constant STORAGE_POSITION_HOLDING = keccak256("ds.holding");

    struct StorageHolding {
        mapping(address => mapping(bytes32 => uint256)) userToCurrencyKeyToHolding;
        mapping(address => mapping(bytes32 => uint256)) userToCurrencyKeyToVault;
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

    function _requireSufficientHolding(bytes32 _key, uint256 _amount)
        internal
        view
    {
        require(
            _amount <=
                _storageHolding().userToCurrencyKeyToHolding[msg.sender][_key],
            "LibHolding: insufficient holding"
        );
    }

    event FundsLocked(address indexed sender, bytes32 key, uint256 amount);

    function _lockFunds(bytes32 _key, uint256 _amount) internal {
        StorageHolding storage s1 = _storageHolding();

        s1.userToCurrencyKeyToHolding[msg.sender][_key] -= _amount;
        s1.userToCurrencyKeyToVault[msg.sender][_key] += _amount;

        emit FundsLocked(msg.sender, _key, _amount);
    }

    event FundsUnlocked(
        address indexed sender,
        address decrease,
        address increase,
        bytes32 key,
        uint256 amount
    );

    function _unlockFunds(
        bytes32 _key,
        uint256 _amount,
        address _decrease,
        address _increase
    ) internal {
        StorageHolding storage s1 = _storageHolding();

        s1.userToCurrencyKeyToVault[_decrease][_key] -= _amount;
        s1.userToCurrencyKeyToHolding[_increase][_key] += _amount;

        emit FundsUnlocked(msg.sender, _decrease, _increase, _key, _amount);
    }

    function _getFundsLockingDetail(bytes32 _jobId)
        internal
        view
        returns (
            address,
            address,
            bytes32,
            uint256,
            uint256
        )
    {
        LibJobBoard.StorageJobBoard storage s1 = LibJobBoard._storageJobBoard();

        address requestor = s1.jobIdToJobDetail[_jobId].requestor;
        address runner = s1.jobIdToJobDetail[_jobId].runner;
        bytes32 keyTransact = s1.jobIdToJobDetail[_jobId].keyTransact;
        uint256 value = s1.jobIdToJobDetail[_jobId].value;
        uint256 cancellationFee = s1.jobIdToJobDetail[_jobId].cancellationFee;

        return (requestor, runner, keyTransact, value, cancellationFee);
    }

    function _sortFundsUnlocking(
        bytes32 _jobId,
        bool _valueIsTransferred,
        bool _payerIsRequestor
    ) internal {
        (
            address requestor,
            address runner,
            bytes32 keyTransact,
            uint256 value,
            uint256 cancellationFee
        ) = _getFundsLockingDetail(_jobId);

        uint256 transferredAmount;
        uint256 payerRefundAmount;
        uint256 payeeRefundAmount;
        address payer;
        address payee;

        if (_valueIsTransferred) {
            transferredAmount = value;
            payerRefundAmount = cancellationFee;
        } else {
            transferredAmount = cancellationFee;
            payerRefundAmount = value;
        }
        payeeRefundAmount = value + cancellationFee;

        if (_payerIsRequestor) {
            payer = requestor;
            payee = runner;
        } else {
            payer = runner;
            payee = requestor;
        }

        _unlockFunds(keyTransact, transferredAmount, payer, payee);
        _unlockFunds(keyTransact, payerRefundAmount, payer, payer);
        _unlockFunds(keyTransact, payeeRefundAmount, payee, payee);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "LibAccessControl.sol";

// @Note CurrencyRegistry is separated from Exchange mainly to ease checks for Holding and Fee, and to separately register fiat and crypto easily
library LibCurrencyRegistry {
    bytes32 constant STORAGE_POSITION_CURRENCYREGISTRY =
        keccak256("ds.currencyregistry");

    struct StorageCurrencyRegistry {
        address nativeToken;
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
            "LibCurrencyRegistry: Currency not supported"
        );
    }

    // _requireIsCrypto does NOT check if is ERC20
    function _requireIsCrypto(bytes32 _key) internal view {
        require(
            _storageCurrencyRegistry().currencyKeyToCrypto[_key],
            "LibCurrencyRegistry: Not crypto"
        );
    }

    event NativeTokenSet(address indexed sender, address token);

    function _setNativeToken(address _token) internal {
        LibAccessControl._requireOnlyRole(LibAccessControl.DEFAULT_ADMIN_ROLE);

        _storageCurrencyRegistry().nativeToken = _token;

        emit NativeTokenSet(msg.sender, _token);
    }

    // code must follow: ISO-4217 Currency Code Standard: https://www.iso.org/iso-4217-currency-codes.html
    function _registerFiat(string memory _code) internal returns (bytes32) {
        require(
            bytes(_code).length != 0,
            "LibCurrencyRegistry: Empty code string"
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
            "LibCurrencyRegistry: Zero token address"
        );
        bytes32 key = _encode_token(_token); //bytes32(uint256(uint160(_token)) << 96);
        _register(key);
        _storageCurrencyRegistry().currencyKeyToCrypto[key] = true;
        return key;
    }

    function _encode_token(address _token) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_token)) << 96); // cannot be decoded
        // encode address: bytes32(uint256(uint160(_address)))
        // decode address: address(uint160(uint256(encoding)))
    }

    event CurrencyRegistered(address indexed sender, bytes32 key);

    function _register(bytes32 _key) internal {
        LibAccessControl._requireOnlyRole(LibAccessControl.STRATEGIST_ROLE);
        _storageCurrencyRegistry().currencyKeyToSupported[_key] = true;

        emit CurrencyRegistered(msg.sender, _key);
    }

    event CurrencyRemoved(address indexed sender, bytes32 key);

    function _removeCurrency(bytes32 _key) internal {
        LibAccessControl._requireOnlyRole(LibAccessControl.STRATEGIST_ROLE);
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

import "Strings.sol";

library LibAccessControl {
    bytes32 constant STORAGE_POSITION_ACCESSCONTROL =
        keccak256("ds.accesscontrol");

    bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 constant MAINTAINER_ROLE = keccak256(abi.encode("MAINTAINER_ROLE"));
    bytes32 constant STRATEGIST_ROLE = keccak256(abi.encode("STRATEGIST_ROLE"));
    bytes32 constant HIVE_ROLE = keccak256(abi.encode("HIVE_ROLE"));
    // bytes32 constant GOVERNOR_ROLE = keccak256(abi.encode("GOVERNOR_ROLE"));

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

import "LibJobBoard.sol";

library LibRequestor {
    function _requireMatchJobIdRequestor(address _requestor, bytes32 _jobId)
        internal
        view
    {
        require(
            _requestor ==
                LibJobBoard
                    ._storageJobBoard()
                    .jobIdToJobDetail[_jobId]
                    .requestor,
            "LibRequestor: caller not match job requestor"
        );
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "Cut.sol";

interface IHubLibraryEvents {
    event DiamondCut(Cut.FacetCut[] _cut, address _init, bytes _calldata);
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
    event NativeTokenSet(address indexed sender, address token);
    event CurrencyRegistered(address indexed sender, bytes32 key);
    event CurrencyRemoved(address indexed sender, bytes32 key);
    event PriceFeedAdded(
        address indexed sender,
        bytes32 keyX,
        bytes32 keyY,
        address priceFeed
    );
    event PriceFeedDerived(
        address indexed sender,
        bytes32 keyX,
        bytes32 keyY,
        bytes32 keyShared
    );
    event AddedPriceFeedRemoved(address indexed sender, address priceFeed);
    event DerivedPriceFeedRemoved(
        address indexed sender,
        bytes32 keyX,
        bytes32 keyY
    );
    event FeeSetCancellation(address indexed sender, uint256 fee);
    event FeeSetBase(address indexed sender, uint256 fee);
    event FeeSetCostPerMinute(address indexed sender, uint256 fee);
    event FeeSetCostPerMetre(address indexed sender, uint256 fee);
    event HiveCreationCountSet(address indexed sender, uint256 count);
    event FundsLocked(address indexed sender, bytes32 key, uint256 amount);
    event FundsUnlocked(
        address indexed sender,
        address decrease,
        address increase,
        bytes32 key,
        uint256 amount
    );
    event JobLifespanSet(address indexed sender, uint256 duration);
    event MinDisputeDurationSet(address indexed sender, uint256 duration);
    event HiveDisputeDurationSet(address indexed sender, uint256 duration);
    event JobCleared(address indexed sender, bytes32 indexed jobId);
    event UserBanned(address indexed sender, address user, uint256 banDuration);
    event SetRatingBounds(address indexed sender, uint256 min, uint256 max);
    event RatingGiven(address indexed sender, uint256 rating);
    event ApplicantApproved(address indexed sender, address applicant);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "LibCutAndLoupe.sol";
import "LibAccessControl.sol";

contract Cut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    } // just a data structure, not storing anything

    event DiamondCut(FacetCut[] _cut, address _init, bytes _calldata);

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _cut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function cut(
        FacetCut[] calldata _cut,
        address _init,
        bytes calldata _calldata
    ) external {
        LibAccessControl._requireOnlyRole(LibAccessControl.MAINTAINER_ROLE);

        LibCutAndLoupe.StorageCutAndLoupe storage ds = LibCutAndLoupe
            ._storageCutAndLoupe();
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        // Check if last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // get last selectorSlot
            // "selectorCount >> 3" is a gas efficient division by 8 "selectorCount / 8"
            selectorSlot = ds.selectorSlots[selectorCount >> 3];
        }
        // loop through diamond cut
        for (uint256 facetIndex; facetIndex < _cut.length; facetIndex++) {
            (selectorCount, selectorSlot) = LibCutAndLoupe
                ._addReplaceRemoveFacetSelectors(
                    selectorCount,
                    selectorSlot,
                    _cut[facetIndex].facetAddress,
                    _cut[facetIndex].action,
                    _cut[facetIndex].functionSelectors
                );
        }
        if (selectorCount != originalSelectorCount) {
            ds.selectorCount = uint16(selectorCount);
        }
        // If last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // "selectorCount >> 3" is a gas efficient division by 8 "selectorCount / 8"
            ds.selectorSlots[selectorCount >> 3] = selectorSlot;
        }
        emit DiamondCut(_cut, _init, _calldata);
        LibCutAndLoupe._initializeCut(_init, _calldata);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "Cut.sol";
import "LibAccessControl.sol";

library LibCutAndLoupe {
    // TODO
    // there is a bug where if import "LibAccessControl.sol"; is excluded from LibCutAndLoupe.sol,
    // but LibCutAndLoupe.sol uses its functions, both brownie and hardhat compilers would NOT detect this error
    // and verification would fail

    bytes32 constant STORAGE_POSITION_CUTANDLOUPE = keccak256("ds.cutandloupe");

    struct StorageCutAndLoupe {
        // maps function selectors to the facets that execute the functions.
        // and maps the selectors to their position in the selectorSlots array.
        // func selector => address facet, selector position
        mapping(bytes4 => bytes32) facets;
        // array of slots of function selectors.
        // each slot holds 8 function selectors.
        mapping(uint256 => bytes32) selectorSlots;
        // The number of function selectors in selectorSlots
        uint16 selectorCount;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        // mapping(bytes4 => bool) supportedInterfaces;
    }

    function _storageCutAndLoupe()
        internal
        pure
        returns (StorageCutAndLoupe storage s)
    {
        bytes32 position = STORAGE_POSITION_CUTANDLOUPE;
        assembly {
            s.slot := position
        }
    }

    event DiamondCut(Cut.FacetCut[] _cut, address _init, bytes _calldata);

    bytes32 constant CLEAR_ADDRESS_MASK =
        bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

    // Internal function version of cut
    // This code is almost the same as the external cut,
    // except it is using 'Facet[] memory _cut' instead of
    // 'Facet[] calldata _cut'.
    // The code is duplicated to prevent copying calldata to memory which
    // causes an error for a two dimensional array.
    function cut(
        Cut.FacetCut[] memory _cut,
        address _init,
        bytes memory _calldata
    ) internal {
        LibAccessControl._requireOnlyRole(LibAccessControl.MAINTAINER_ROLE);

        StorageCutAndLoupe storage s1 = _storageCutAndLoupe();
        uint256 originalSelectorCount = s1.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        // Check if last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // get last selectorSlot
            // "selectorSlot >> 3" is a gas efficient division by 8 "selectorSlot / 8"
            selectorSlot = s1.selectorSlots[selectorCount >> 3];
        }
        // loop through diamond cut
        for (uint256 facetIndex; facetIndex < _cut.length; facetIndex++) {
            (selectorCount, selectorSlot) = _addReplaceRemoveFacetSelectors(
                selectorCount,
                selectorSlot,
                _cut[facetIndex].facetAddress,
                _cut[facetIndex].action,
                _cut[facetIndex].functionSelectors
            );
        }
        if (selectorCount != originalSelectorCount) {
            s1.selectorCount = uint16(selectorCount);
        }
        // If last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // "selectorSlot >> 3" is a gas efficient division by 8 "selectorSlot / 8"
            s1.selectorSlots[selectorCount >> 3] = selectorSlot;
        }
        emit DiamondCut(_cut, _init, _calldata);
        _initializeCut(_init, _calldata);
    }

    function _addReplaceRemoveFacetSelectors(
        uint256 _selectorCount,
        bytes32 _selectorSlot,
        address _newFacetAddress,
        Cut.FacetCutAction _action,
        bytes4[] memory _selectors
    ) internal returns (uint256, bytes32) {
        StorageCutAndLoupe storage s1 = _storageCutAndLoupe();
        require(
            _selectors.length > 0,
            "LibCutAndLoupe: No selectors in facet to cut"
        );
        if (_action == Cut.FacetCutAction.Add) {
            _requireHasContractCode(
                _newFacetAddress,
                "LibCutAndLoupe: Add facet has no code"
            );
            for (
                uint256 selectorIndex;
                selectorIndex < _selectors.length;
                selectorIndex++
            ) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = s1.facets[selector];
                require(
                    address(bytes20(oldFacet)) == address(0),
                    "LibCutAndLoupe: Can't add function that already exists"
                );
                // add facet for selector
                s1.facets[selector] =
                    bytes20(_newFacetAddress) |
                    bytes32(_selectorCount);
                // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8"
                uint256 selectorInSlotPosition = (_selectorCount & 7) << 5;
                // clear selector position in slot and add selector
                _selectorSlot =
                    (_selectorSlot &
                        ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) |
                    (bytes32(selector) >> selectorInSlotPosition);
                // if slot is full then write it to storage
                if (selectorInSlotPosition == 224) {
                    // "_selectorSlot >> 3" is a gas efficient division by 8 "_selectorSlot / 8"
                    s1.selectorSlots[_selectorCount >> 3] = _selectorSlot;
                    _selectorSlot = 0;
                }
                _selectorCount++;
            }
        } else if (_action == Cut.FacetCutAction.Replace) {
            _requireHasContractCode(
                _newFacetAddress,
                "LibCutAndLoupe: Replace facet has no code"
            );
            for (
                uint256 selectorIndex;
                selectorIndex < _selectors.length;
                selectorIndex++
            ) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = s1.facets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));
                // only useful if immutable functions exist
                require(
                    oldFacetAddress != address(this),
                    "LibCutAndLoupe: Can't replace immutable function"
                );
                require(
                    oldFacetAddress != _newFacetAddress,
                    "LibCutAndLoupe: Can't replace function with same function"
                );
                require(
                    oldFacetAddress != address(0),
                    "LibCutAndLoupe: Can't replace function that doesn't exist"
                );
                // replace old facet address
                s1.facets[selector] =
                    (oldFacet & CLEAR_ADDRESS_MASK) |
                    bytes20(_newFacetAddress);
            }
        } else if (_action == Cut.FacetCutAction.Remove) {
            require(
                _newFacetAddress == address(0),
                "LibCutAndLoupe: Remove facet address must be address(0)"
            );
            // "_selectorCount >> 3" is a gas efficient division by 8 "_selectorCount / 8"
            uint256 selectorSlotCount = _selectorCount >> 3;
            // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8"
            uint256 selectorInSlotIndex = _selectorCount & 7;
            for (
                uint256 selectorIndex;
                selectorIndex < _selectors.length;
                selectorIndex++
            ) {
                if (_selectorSlot == 0) {
                    // get last selectorSlot
                    selectorSlotCount--;
                    _selectorSlot = s1.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                } else {
                    selectorInSlotIndex--;
                }
                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;
                // adding a block here prevents stack too deep error
                {
                    bytes4 selector = _selectors[selectorIndex];
                    bytes32 oldFacet = s1.facets[selector];
                    require(
                        address(bytes20(oldFacet)) != address(0),
                        "LibCutAndLoupe: Can't remove function that doesn't exist"
                    );
                    // only useful if immutable functions exist
                    require(
                        address(bytes20(oldFacet)) != address(this),
                        "LibCutAndLoupe: Can't remove immutable function"
                    );
                    // replace selector with last selector in s1.facets
                    // gets the last selector
                    lastSelector = bytes4(
                        _selectorSlot << (selectorInSlotIndex << 5)
                    );
                    if (lastSelector != selector) {
                        // update last selector slot position info
                        s1.facets[lastSelector] =
                            (oldFacet & CLEAR_ADDRESS_MASK) |
                            bytes20(s1.facets[lastSelector]);
                    }
                    delete s1.facets[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    // "oldSelectorCount >> 3" is a gas efficient division by 8 "oldSelectorCount / 8"
                    oldSelectorsSlotCount = oldSelectorCount >> 3;
                    // "oldSelectorCount & 7" is a gas efficient modulo by eight "oldSelectorCount % 8"
                    oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
                }
                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = s1.selectorSlots[
                        oldSelectorsSlotCount
                    ];
                    // clears the selector we are deleting and puts the last selector in its place.
                    oldSelectorSlot =
                        (oldSelectorSlot &
                            ~(CLEAR_SELECTOR_MASK >>
                                oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                    // update storage with the modified slot
                    s1.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    // clears the selector we are deleting and puts the last selector in its place.
                    _selectorSlot =
                        (_selectorSlot &
                            ~(CLEAR_SELECTOR_MASK >>
                                oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }
                if (selectorInSlotIndex == 0) {
                    delete s1.selectorSlots[selectorSlotCount];
                    _selectorSlot = 0;
                }
            }
            _selectorCount = selectorSlotCount * 8 + selectorInSlotIndex;
        } else {
            revert("LibCutAndLoupe: Incorrect FacetCutAction");
        }
        return (_selectorCount, _selectorSlot);
    }

    function _initializeCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(
                _calldata.length == 0,
                "LibCutAndLoupe: _init is address(0) but_calldata is not empty"
            );
        } else {
            require(
                _calldata.length > 0,
                "LibCutAndLoupe: _calldata is empty but _init is not address(0)"
            );
            if (_init != address(this)) {
                _requireHasContractCode(
                    _init,
                    "LibCutAndLoupe: _init address has no code"
                );
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibCutAndLoupe: _init function reverted");
                }
            }
        }
    }

    function _requireHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}