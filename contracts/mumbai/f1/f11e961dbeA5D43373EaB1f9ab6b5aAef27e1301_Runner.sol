//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "LibJobBoard.sol";
import "LibRunnerRegistry.sol";
import "LibRunnerDetail.sol";
import "LibRunner.sol";
import "LibRequester.sol";
import "LibRequesterDetail.sol";
import "LibHolding.sol";
import "LibExchange.sol";

import "LibPenalty.sol";

import "IHubLibraryEvents.sol";

contract Runner is IHubLibraryEvents {
    event RequestAccepted(address indexed sender, bytes32 indexed jobId);

    function acceptRequest(
        bytes32 _keyLocal,
        bytes32 _keyTransact,
        bytes32 _jobId
    ) external {
        LibRunnerRegistry._requireIsRunner();

        LibRunnerDetail.StorageRunnerDetail storage s2 = LibRunnerDetail
            ._storageRunnerDetail();

        LibPenalty._requireNotBanned(s2.runnerToRunnerDetail[msg.sender].hive); // TODO: test possible for hives to ban their own runner
        LibExchange._requireAddedXPerYPriceFeedSupported(
            _keyLocal,
            _keyTransact
        );

        LibJobBoard.StorageJobBoard storage s1 = LibJobBoard._storageJobBoard();

        require(
            s1.jobIdToJobDetail[_jobId].requester != address(0),
            "Runner: job not exists"
        );

        require(
            s1.jobIdToJobDetail[_jobId].state == LibJobBoard.JobState.Pending,
            "Runner: job state not pending"
        );

        require(
            s1.jobIdToJobDetail[_jobId].keyLocal == _keyLocal,
            "Runner: local currency key not match"
        );
        require(
            s1.jobIdToJobDetail[_jobId].keyTransact == _keyTransact,
            "Runner: transact currency key not match"
        );

        require(
            s1.jobIdToJobDetail[_jobId].metres <=
                s2.runnerToRunnerDetail[msg.sender].maxMetresPerTrip,
            "Runner: exceed max metres"
        );

        LibHolding._requireSufficientHolding(
            _keyTransact,
            s1.jobIdToJobDetail[_jobId].value +
                s1.jobIdToJobDetail[_jobId].cancellationFee
        );
        LibHolding._lockFunds(
            _keyTransact,
            s1.jobIdToJobDetail[_jobId].value +
                s1.jobIdToJobDetail[_jobId].cancellationFee
        );

        s1.jobIdToJobDetail[_jobId].runner = msg.sender;
        s1.jobIdToJobDetail[_jobId].state = LibJobBoard.JobState.Accepted;

        s1.userToJobIdCount[msg.sender] += 1;

        emit RequestAccepted(msg.sender, _jobId);
    }

    event PackageCollected(address indexed sender, bytes32 indexed jobId);

    function collectPackage(bytes32 _jobId, address _package) external {
        LibRunner._requireMatchJobIdRunner(_jobId);

        LibJobBoard.StorageJobBoard storage s1 = LibJobBoard._storageJobBoard();

        require(
            s1.jobIdToJobDetail[_jobId].state == LibJobBoard.JobState.Accepted,
            "Runner: job state not accepted"
        );

        LibJobBoard._setJobDisputeExpiry(_jobId);

        verify(_jobId, _package);

        if (s1.jobIdToJobDetail[_jobId].packageVerified) {
            // runner & requester incentivised to get verified to get stats
            // TODO: re-study this logic where if verified only can gain stats
            LibRunner._recordCollectStats(_jobId);
            // LibRunnerDetail
            //     ._storageRunnerDetail()
            //     .runnerToRunnerDetail[msg.sender]
            //     .countStart += 1;
            // LibRequesterDetail
            //     ._storageRequesterDetail()
            //     .requesterToRequesterDetail[
            //         s1.jobIdToJobDetail[_jobId].requester
            //     ]
            //     .countStart += 1;
            // s1.jobIdToJobDetail[_jobId].collectStatsRecorded = true;
        }

        s1.jobIdToJobDetail[_jobId].state = LibJobBoard.JobState.Collected;

        emit PackageCollected(msg.sender, _jobId);
    }

    event PackageDelivered(address indexed sender, bytes32 indexed jobId);

    function deliverPackage(bytes32 _jobId) external {
        LibRunner._requireMatchJobIdRunner(_jobId);

        LibJobBoard.StorageJobBoard storage s1 = LibJobBoard._storageJobBoard();

        require(
            s1.jobIdToJobDetail[_jobId].state == LibJobBoard.JobState.Collected,
            "Runner: job state not collected"
        );

        LibJobBoard._requireDisputePeriodExpired(_jobId);
        require(
            !s1.jobIdToJobDetail[_jobId].dispute,
            "Runner: requester dispute"
        );

        LibJobBoard._setJobDisputeExpiry(_jobId);

        s1.jobIdToJobDetail[_jobId].state = LibJobBoard.JobState.Delivered;

        emit PackageDelivered(msg.sender, _jobId);
    }

    event JobCompleted(address indexed sender, bytes32 indexed jobId);

    function completeJob(bytes32 _jobId, bool _accept) external {
        LibRunner._requireMatchJobIdRunner(_jobId);

        LibJobBoard.StorageJobBoard storage s1 = LibJobBoard._storageJobBoard();

        require(
            s1.jobIdToJobDetail[_jobId].state == LibJobBoard.JobState.Delivered,
            "Runner: job state not delivered"
        );

        LibJobBoard._requireDisputePeriodExpired(_jobId);

        require(_accept, "Runner: not accept"); // accept whether disputed or not

        LibRunnerDetail.StorageRunnerDetail storage s2 = LibRunnerDetail
            ._storageRunnerDetail();

        if (s1.jobIdToJobDetail[_jobId].dispute) {
            LibHolding._sortFundsUnlocking(_jobId, false, true);
        } else {
            LibHolding._sortFundsUnlocking(_jobId, true, true);

            if (s1.jobIdToJobDetail[_jobId].packageVerified) {
                if (!s1.jobIdToJobDetail[_jobId].collectStatsRecorded) {
                    LibRunner._recordCollectStats(_jobId);
                }

                // TODO: re-study this logic where if verified only can gain stats
                s2.runnerToRunnerDetail[msg.sender].metresTravelled += s1
                    .jobIdToJobDetail[_jobId]
                    .metres;
                s2.runnerToRunnerDetail[msg.sender].countEnd += 1;

                LibRequesterDetail
                    ._storageRequesterDetail()
                    .requesterToRequesterDetail[
                        s1.jobIdToJobDetail[_jobId].requester
                    ]
                    .countEnd += 1;
            }
        }

        s1.userToJobIdCount[msg.sender] -= 1;

        s1.jobIdToJobDetail[_jobId].state = LibJobBoard.JobState.Completed; // note: not used as job cleared before this point

        emit JobCompleted(msg.sender, _jobId);
    }

    event RunnerCancelled(address indexed sender, bytes32 indexed jobId);

    function cancelFromRunner(bytes32 _jobId) external {
        LibRunner._requireMatchJobIdRunner(_jobId);

        LibJobBoard.StorageJobBoard storage s1 = LibJobBoard._storageJobBoard();

        require(
            s1.jobIdToJobDetail[_jobId].state ==
                LibJobBoard.JobState.Accepted ||
                s1.jobIdToJobDetail[_jobId].state ==
                LibJobBoard.JobState.Collected,
            "Runner: job state not accepted or collected"
        );

        if (
            s1.jobIdToJobDetail[_jobId].state == LibJobBoard.JobState.Accepted
        ) {
            LibHolding._sortFundsUnlocking(_jobId, false, false);
        } else if (
            s1.jobIdToJobDetail[_jobId].state == LibJobBoard.JobState.Collected
        ) {
            // runner need pay value to prevent steal
            LibHolding._sortFundsUnlocking(_jobId, true, false);
        }

        s1.userToJobIdCount[msg.sender] -= 1;

        s1.jobIdToJobDetail[_jobId].state = LibJobBoard.JobState.Cancelled; // note: not used as job cleared before this point

        emit RunnerCancelled(msg.sender, _jobId);
    }

    event PackageVerified(address indexed sender, bytes32 indexed jobId);

    function verify(bytes32 _jobId, address _package) public {
        LibJobBoard.StorageJobBoard storage s1 = LibJobBoard._storageJobBoard();

        if (_package == s1.jobIdToJobDetail[_jobId].package) {
            s1.jobIdToJobDetail[_jobId].packageVerified = true;

            emit PackageVerified(msg.sender, _jobId);
        }
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
        address requester;
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

        address requester = s1.jobIdToJobDetail[_jobId].requester;
        address runner = s1.jobIdToJobDetail[_jobId].runner;
        bytes32 keyTransact = s1.jobIdToJobDetail[_jobId].keyTransact;
        uint256 value = s1.jobIdToJobDetail[_jobId].value;
        uint256 cancellationFee = s1.jobIdToJobDetail[_jobId].cancellationFee;

        return (requester, runner, keyTransact, value, cancellationFee);
    }

    function _sortFundsUnlocking(
        bytes32 _jobId,
        bool _valueIsTransferred,
        bool _payerIsRequester
    ) internal {
        (
            address requester,
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

        if (_payerIsRequester) {
            payer = requester;
            payee = runner;
        } else {
            payer = runner;
            payee = requester;
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
import "LibRequester.sol";
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
        LibRequester._requireMatchJobIdRequester(msg.sender, _jobId);

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

import "LibJobBoard.sol";

library LibRequester {
    function _requireMatchJobIdRequester(address _requester, bytes32 _jobId)
        internal
        view
    {
        require(
            _requester ==
                LibJobBoard
                    ._storageJobBoard()
                    .jobIdToJobDetail[_jobId]
                    .requester,
            "LibRequester: caller not match job requester"
        );
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "Counters.sol";
import "LibRunnerDetail.sol";

library LibRunnerRegistry {
    using Counters for Counters.Counter;

    bytes32 constant STORAGE_POSITION_RUNNERREGISTRY =
        keccak256("ds.runnerregistry");

    struct StorageRunnerRegistry {
        Counters.Counter _runnerIdCounter;
    }

    function _storageRunnerRegistry()
        internal
        pure
        returns (StorageRunnerRegistry storage s)
    {
        bytes32 position = STORAGE_POSITION_RUNNERREGISTRY;
        assembly {
            s.slot := position
        }
    }

    function _requireIsRunner() internal view {
        require(
            LibRunnerDetail
                ._storageRunnerDetail()
                .runnerToRunnerDetail[msg.sender]
                .id != 0,
            "LibRunnerRegistry: caller not runner"
        );
    }

    function _requireNotRunner() internal view {
        require(
            LibRunnerDetail
                ._storageRunnerDetail()
                .runnerToRunnerDetail[msg.sender]
                .id == 0,
            "LibRunnerRegistry: caller is runner"
        );
    }

    /**
     * _mint a runner ID
     *
     * @return runner ID
     */
    function _mint() internal returns (uint256) {
        StorageRunnerRegistry storage s1 = _storageRunnerRegistry();
        uint256 id = s1._runnerIdCounter.current();
        s1._runnerIdCounter.increment();
        return id;
    }

    /**
     * _burnFirstRunnerId burns runner ID 0
     * can only be called at Hub deployment
     *
     * TODO: call at init ONLY
     */
    function _burnFirstRunnerId() internal {
        StorageRunnerRegistry storage s1 = _storageRunnerRegistry();
        require(
            s1._runnerIdCounter.current() == 0,
            "LibRunnerRegistry: Must be zero"
        );
        s1._runnerIdCounter.increment();
    }

    event ApplicantApproved(address indexed sender, address applicant);

    function _approveApplicant(
        address _runner,
        string memory _uri,
        address _hiveTimelock
    ) internal {
        LibRunnerDetail.StorageRunnerDetail storage s1 = LibRunnerDetail
            ._storageRunnerDetail();

        require(
            s1.runnerToRunnerDetail[_runner].hive == address(0),
            "LibRunnerRegistry: hive exist for applicant"
        );
        s1.runnerToRunnerDetail[_runner].uri = _uri; // note: possible to override URI when joining new hive
        s1.runnerToRunnerDetail[_runner].hive = _hiveTimelock;
        // s1.hiveToRunners[_hiveTimelock].push(_runner); // note: depends on RunnerDetail.calculateCollectiveScore

        emit ApplicantApproved(msg.sender, _runner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "LibJobBoard.sol";

import "LibRequesterDetail.sol";
import "LibRunnerDetail.sol";

library LibRunner {
    function _requireMatchJobIdRunner(bytes32 _jobId) internal view {
        require(
            msg.sender ==
                LibJobBoard._storageJobBoard().jobIdToJobDetail[_jobId].runner,
            "LibRunner: caller not match job id runner"
        );
    }

    function _recordCollectStats(bytes32 _jobId) internal {
        LibJobBoard.StorageJobBoard storage s1 = LibJobBoard._storageJobBoard();

        LibRunnerDetail
            ._storageRunnerDetail()
            .runnerToRunnerDetail[msg.sender]
            .countStart += 1;

        LibRequesterDetail
            ._storageRequesterDetail()
            .requesterToRequesterDetail[s1.jobIdToJobDetail[_jobId].requester]
            .countStart += 1;

        s1.jobIdToJobDetail[_jobId].collectStatsRecorded = true;
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "LibRater.sol";
import "LibAccessControl.sol";

library LibRequesterDetail {
    bytes32 constant STORAGE_POSITION_REQUESTORDETAIL =
        keccak256("ds.requesterdetail");

    /**
     * lifetime cumulative values of Requesters
     */
    struct RequesterDetail {
        uint256 countStart;
        uint256 countEnd;
    }

    struct StorageRequesterDetail {
        mapping(address => RequesterDetail) requesterToRequesterDetail;
    }

    function _storageRequesterDetail()
        internal
        pure
        returns (StorageRequesterDetail storage s)
    {
        bytes32 position = STORAGE_POSITION_REQUESTORDETAIL;
        assembly {
            s.slot := position
        }
    }

    /**
     * _calculateScore calculates score from requester's reputation detail (see params of function)
     *
     *
     * @return Requester's score | unitless integer
     *
     * Derive Requester's Score Formula:-
     *
     */
    function _calculateRequesterScore(address _requester)
        internal
        view
        returns (uint256)
    {
        StorageRequesterDetail storage s1 = _storageRequesterDetail();

        uint256 countStart = s1
            .requesterToRequesterDetail[_requester]
            .countStart;
        uint256 countEnd = s1.requesterToRequesterDetail[_requester].countEnd;

        if (countStart == 0) {
            return 0;
        } else {
            return countEnd / countStart;
        }
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "LibAccessControl.sol";
import "LibCurrencyRegistry.sol";

import "AggregatorV3Interface.sol";

library LibExchange {
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
        // xToYToBaseKeyCount useful for removal
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
            "LibExchange: Price feed not supported"
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
            "LibExchange: Derived price feed not supported"
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
        LibAccessControl._requireOnlyRole(LibAccessControl.STRATEGIST_ROLE);
        LibCurrencyRegistry._requireCurrencySupported(_keyX);
        LibCurrencyRegistry._requireCurrencySupported(_keyY);

        require(
            _priceFeed != address(0),
            "LibExchange: Zero price feed address"
        );
        StorageExchange storage s1 = _storageExchange();
        require(
            s1.xToYToXAddedPerYPriceFeed[_keyX][_keyY] == address(0),
            "LibExchange: Price feed already supported"
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
        LibAccessControl._requireOnlyRole(LibAccessControl.STRATEGIST_ROLE);
        require(
            _keyX != _keyY,
            "LibExchange: Underlying currency key cannot be identical"
        );
        _requireAddedXPerYPriceFeedSupported(_keyX, _keyShared);
        _requireAddedXPerYPriceFeedSupported(_keyY, _keyShared);

        StorageExchange storage s1 = _storageExchange();
        require(
            s1.xToYToXPerYDerivedPriceFeedDetails[_keyX][_keyY].numerator ==
                address(0),
            "LibExchange: Derived price feed already supported"
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
        LibAccessControl._requireOnlyRole(LibAccessControl.STRATEGIST_ROLE);
        _requireAddedXPerYPriceFeedSupported(_keyX, _keyY);

        StorageExchange storage s1 = _storageExchange();

        require(
            s1.xToYToBaseKeyCount[_keyX][_keyY] == 0,
            "LibExchange: Base key being used"
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
        LibAccessControl._requireOnlyRole(LibAccessControl.STRATEGIST_ROLE);
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

    // _amountX in wei /** _keyY == target to convert amount into */
    function _convertCurrency(
        bytes32 _keyX,
        bytes32 _keyY,
        uint256 _amountX
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
                "LibExchange: This revert should not ever be run - something seriously wrong with code"
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

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "LibAccessControl.sol";

library LibPenalty {
    bytes32 constant STORAGE_POSITION_PENALTY = keccak256("ds.penalty");

    struct StoragePenalty {
        mapping(address => mapping(address => uint256)) userToHiveToBanEndTimestamp;
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

    function _requireNotBanned(address _hive) internal view {
        require(
            block.timestamp >=
                _storagePenalty().userToHiveToBanEndTimestamp[msg.sender][
                    _hive
                ],
            "LibPenalty: still banned"
        );
    }

    event UserBanned(address indexed sender, address user, uint256 banDuration);

    function _setUserToHiveToBanEndTimestamp(address _user, uint256 _duration)
        internal
    {
        LibAccessControl._requireOnlyRole(LibAccessControl.HIVE_ROLE);

        _storagePenalty().userToHiveToBanEndTimestamp[_user][msg.sender] =
            block.timestamp +
            _duration;

        emit UserBanned(msg.sender, _user, _duration);
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