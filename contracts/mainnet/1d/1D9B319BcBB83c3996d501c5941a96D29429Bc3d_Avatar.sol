// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Bucket.sol";

contract Avatar is ReentrancyGuard, Bucket {
    using SafeMath for *;
    uint256 public constant PRINCIPAL_RATIO = 600000; // 60%
    uint256 public constant INVEST_RATIO = 390000; // 39%
    uint256 public constant PLATFORM_RATIO = 10000; // 1%
    uint256 public constant REFERRER_RATIO = 60000; // 6%
    uint256 public constant INCENTIVE_RATIO = 10000; // 1%
    uint256 public constant PRICE_PRECISION = 1e6; // 100%

    uint256 public constant MIN_INVEST = 5e19; // 50
    uint256 public constant MAX_INVEST = 5e20; // 500

    uint256 public constant TIME_UNIT = 1 days;

    uint256 public constant MAX_SEARCH_DEPTH = 50;
    uint256 public constant RANKED_INCENTIVE = 60;

    address public platformAddress; // will be payment splitter contract address

    uint256 public currentEpochs;

    // round epoch => address => position index => position info
    mapping(uint256 => mapping(address => PositionInfo[])) public roundLedgers;
    //
    mapping(uint256 => RoundInfo) public roundInfos;
    //
    mapping(address => UserRoundInfo[]) public userRoundsInfos;

    mapping(address => UserGlobalInfo) public userGlobalInfos;

    mapping(address => address[]) public children; // used for easily retrieve the referrer tree structure from front-end

    // temp admin
    address public tempAdmin;
    address public operator;
    bool public gamePaused;

    struct FundTarget {
        uint256 lastCheckTime;
        uint256 amount;
        uint256 achievedAmount;
    }

    struct UserGlobalInfo {
        // referrer chain to record the referrer relationship
        address referrer;
        // referrer rearward vault
        uint256 totalReferrerReward;
        uint256 referrerRewardClaimed;
        // boost credit
        uint256 boostCredit;
        // sales record
        uint256 maxChildrenSales;
        uint256 sales;
        uint256 totalPositionAmount;
        uint256 reportedSales;
        uint8 salesLevel;
    }

    struct PositionInfo {
        uint256 amount;
        uint256 openTime;
        uint256 expiryTime;
        uint256 investReturnRate;
        uint256 withdrawnAmount;
        uint256 incentiveAmount;
        uint256 investReturnAmount;
        uint256 index;
        bool incentiveClaimable;
    }

    struct LinkedPosition {
        address user;
        uint256 userPositionIndex;
    }

    struct RoundInfo {
        FundTarget fundTarget;
        uint256 totalPositionAmount; // total amount of all positions
        uint256 currentPrincipalAmount; // current principal amount
        uint256 currentInvestAmount; // current invest amount
        uint256 totalPositionCount; // total count of all positions
        uint256 currentPositionCount; // total count of all open positions
        uint256 currentIncentiveAmount; // current incentive amount
        uint256 incentiveSnapshot; // check total position of last N positions
        uint256 head; // head of linked position for last N positions
        mapping(uint256 => LinkedPosition) linkedPositions; // used for incentive track
        mapping(address => uint256) ledgerRoundToUserRoundIndex; // this round index in userRoundsInfos
        bool stopLoss; // default false means the round is running
    }

    struct UserRoundInfo {
        uint256 epoch;
        uint256 totalPositionAmount;
        uint256 currentPrincipalAmount;
        uint256 totalWithdrawnAmount;
        uint256 totalIncentiveClaimedAmount;
        uint256 totalClosedPositionCount;
        uint256 returnRateBoostedAmount;
    }

    struct ReferrerSearch {
        uint256 currentUserSales;
        uint256 currentReferrerSales;
        address currentReferrer;
        uint256 currentReferrerAmount;
        uint256 levelDiffAmount;
        uint256 leftLevelDiffAmount;
        uint256 levelDiffAmountPerLevel;
        uint256 levelSearchAmount;
        uint256 leftLevelSearchAmount;
        uint256 levelSearchAmountPerReferrer;
        uint256 levelSearchSales;
        uint256 currentReferrerMaxChildSales;
        uint256 currentUserTotalPosAmount;
        uint256 currentUserReportedSales;
        address currentUser;
        uint8 depth;
        uint8 levelSearchStep;
        uint8 currentLevelDiff;
        uint8 numLevelSearchCandidate;
        uint8 baseSalesLevel;
        uint8 currentReferrerLevel;
        bool levelDiffDone;
        bool levelSearchDone;
        bool levelSalesDone;
    }

    struct OpenPositionParams {
        uint256 principalAmount;
        uint256 investAmount;
        uint256 referrerAmount;
        uint256 incentiveAmount;
        uint256 investReturnRate;
    }

    event PositionOpened(
        address indexed user,
        uint256 indexed epoch,
        uint256 positionIndex,
        uint256 amount
    );

    event PositionClosed(
        address indexed user,
        uint256 indexed epoch,
        uint256 positionIndex,
        uint256 amount
    );

    event NewReferrer(address indexed user, address indexed referrer);
    event NewRound(uint256 indexed epoch);
    event ReferrerRewardAdded(address indexed user, uint256 amount, uint256 indexed rewardType);
    event ReferrerRewardClaimed(address indexed user, uint256 amount);
    event SalesLevelUpdated(address indexed user, uint8 level);
    event IncentiveClaimed(address indexed user, uint256 amount);

    modifier notContract() {
        require(msg.sender == tx.origin, "Contract not allowed");
        _;
    }

    /**
     * @param _platformAddress The address of the platform
     * @param _tempAdmin The address of the temp admin
     * @param _operator The address of the operator
     */
    constructor(
        address _platformAddress,
        address _tempAdmin,
        address _operator
    ) {
        require(
            _platformAddress != address(0) && _tempAdmin != address(0) && _operator != address(0),
            "Invalid address provided"
        );
        emit NewRound(0);

        tempAdmin = _tempAdmin;
        operator = _operator;
        platformAddress = _platformAddress;
        gamePaused = true;
    }

    /**
     * @notice Set the game paused status
     * @param _paused: The game paused status
     */
    function setPause(bool _paused) external {
        require(msg.sender == operator, "Only operator");
        // make sure the admin has dropped when game is unpaused
        if (!_paused) {
            require(tempAdmin == address(0), "Temp admin not dropped");
        }
        gamePaused = _paused;
    }

    /**
     * @notice Transfer operator
     */
    function transferOperator(address _operator) external {
        require(msg.sender == operator, "Only operator");
        require(_operator != address(0), "Invalid address");
        operator = _operator;
    }

    /**
     * @notice Drop the temp admin privilege
     */
    function dropTempAdmin() external {
        require(msg.sender == tempAdmin, "Only admin");
        tempAdmin = address(0);
    }

    /**
     * @notice Batch set referrer information for users
     * @param users: The users to set
     * @param referrers: The referrers to set
     * @param salesLevels: The sales levels to set
     */
    function batchSetReferrerInfo(
        address[] calldata users,
        address[] calldata referrers,
        uint8[] calldata salesLevels
    ) external {
        require(msg.sender == tempAdmin, "Only admin");
        require(users.length == referrers.length && users.length == salesLevels.length, "Invalid input");
        UserGlobalInfo storage userGlobalInfo;
        uint256 userLength = users.length;
        for (uint256 i = 0; i < userLength; ++i) {
            require(users[i] != address(0), "Invalid address provided");
            userGlobalInfo = userGlobalInfos[users[i]];
            require(userGlobalInfo.referrer == address(0), "Referrer already set");
            userGlobalInfo.referrer = referrers[i];
            userGlobalInfo.salesLevel = salesLevels[i];
            children[referrers[i]].push(users[i]);
        }
    }

    /**
     * @notice Open a new position
     * @param targetEpoch: The target epoch to open
     * @param referrer: The expected referrer
     */
    function openPosition(
        uint256 targetEpoch,
        address referrer
    ) external payable notContract nonReentrant {
        require(targetEpoch == currentEpochs, "Invalid epoch");
        require(msg.value >= MIN_INVEST, "Too small");
        require(msg.value <= MAX_INVEST, "Too large");
        require(!gamePaused, "Paused");

        // load user global info
        UserGlobalInfo storage userGlobalInfo = userGlobalInfos[msg.sender];
        // load global round info
        RoundInfo storage roundInfo = roundInfos[targetEpoch];
        // placeholder for user round info
        UserRoundInfo storage userRoundInfo;

        // determine referrer
        {
            address _referrer = userGlobalInfo.referrer;
            // if referrer is already set or msg.sender is the root user whose referrer is address(0)
            if (_referrer == address(0) && children[msg.sender].length == 0) {
                // if referrer is not set, set it and make sure it is a valid referrer
                require(referrer != address(0) && referrer != msg.sender, "Invalid referrer");
                // make sure referrer is registered already
                require(
                    userGlobalInfos[referrer].referrer != address(0) || children[referrer].length > 0,
                    "Invalid referrer1"
                );

                // update storage
                userGlobalInfo.referrer = referrer;
                children[referrer].push(msg.sender);
                emit NewReferrer(msg.sender, referrer);
            }
        }

        // calculate each part of the amount
        OpenPositionParams memory params = OpenPositionParams({
            principalAmount: (msg.value * PRINCIPAL_RATIO) / PRICE_PRECISION,
            investAmount: (msg.value * INVEST_RATIO) / PRICE_PRECISION,
            referrerAmount: (msg.value * REFERRER_RATIO) / PRICE_PRECISION,
            incentiveAmount: (msg.value * INCENTIVE_RATIO) / PRICE_PRECISION,
            investReturnRate: _getReturnRate(currentEpochs)
        });

        // update user's current ledger and current round info
        uint256 userRoundInfoLength = userRoundsInfos[msg.sender].length;
        if (
            userRoundInfoLength == 0 ||
            userRoundsInfos[msg.sender][userRoundInfoLength - 1].epoch < targetEpoch
        ) {
            // this is users first position in this round of this ledger type
            UserRoundInfo memory _userRoundInfo;
            _userRoundInfo = UserRoundInfo({
                epoch: targetEpoch,
                totalPositionAmount: 0,
                currentPrincipalAmount: 0,
                totalWithdrawnAmount: 0,
                totalIncentiveClaimedAmount: 0,
                totalClosedPositionCount: 0,
                returnRateBoostedAmount: 0
            });
            // push roundInfo to storage
            userRoundsInfos[msg.sender].push(_userRoundInfo);
            roundInfo.ledgerRoundToUserRoundIndex[msg.sender] = userRoundInfoLength;
            userRoundInfoLength += 1;
        }

        // fetch back the roundInfo from storage for further direct modification
        userRoundInfo = userRoundsInfos[msg.sender][userRoundInfoLength - 1];
        userRoundInfo.totalPositionAmount += msg.value;
        userRoundInfo.currentPrincipalAmount += params.principalAmount;

        // default use boost
        {
            uint256 boostCredit = userGlobalInfo.boostCredit;
            if (boostCredit >= msg.value) {
                params.investReturnRate = params.investReturnRate * 2;
                userGlobalInfo.boostCredit -= msg.value;
            }
        }

        // update ledger round info
        roundInfo.totalPositionAmount += msg.value;
        roundInfo.currentPrincipalAmount += params.principalAmount;
        roundInfo.currentInvestAmount += params.investAmount;
        roundInfo.currentPositionCount += 1;
        roundInfo.currentIncentiveAmount += params.incentiveAmount;
        roundInfo.incentiveSnapshot += msg.value;
        roundInfo.totalPositionCount += 1;

        uint256 userTotalPositionCount = roundLedgers[targetEpoch][msg.sender].length;
        // construct position info
        {
            uint location = pickLocation(targetEpoch);
            uint256 expiryTime = block.timestamp;
            expiryTime += (location + 1) * TIME_UNIT;
            PositionInfo memory positionInfo = PositionInfo({
                amount: msg.value,
                openTime: block.timestamp,
                expiryTime: expiryTime,
                investReturnRate: params.investReturnRate,
                withdrawnAmount: 0,
                incentiveAmount: 0,
                investReturnAmount: 0,
                index: userTotalPositionCount,
                incentiveClaimable: true
            });

            // do bucket stock
            {
                BucketStock storage bucketStock = ledgerBucketStock;
                uint hour = DateTime.getHour(block.timestamp);
                uint timestamp = DateTime.getTodayTimestamp(block.timestamp);
                bucketStock.hourTradeVolume[currentEpochs][timestamp][hour] += msg.value;
                bucketStock.currentTotalVolume += msg.value;
                bucketStock.epochDaysVolume[currentEpochs][location] += msg.value;
            }

            // push position info to round ledgers
            roundLedgers[targetEpoch][msg.sender].push(positionInfo);
        }

        // distribute referrer funds
        _distributeReferrerReward(msg.sender, params.referrerAmount);
        {
            // ranked incentive track
            mapping(uint256 => LinkedPosition) storage linkedPositions = roundInfo.linkedPositions;

            // update the latest position (which is the current position) node
            LinkedPosition storage linkedPosition = linkedPositions[roundInfo.totalPositionCount - 1];
            linkedPosition.user = msg.sender;
            linkedPosition.userPositionIndex = userTotalPositionCount;

            // adjust head in order to keep track last N positions
            if (roundInfo.totalPositionCount - roundInfo.head > RANKED_INCENTIVE) {
                // fetch current head node
                LinkedPosition storage headLinkedPosition = linkedPositions[roundInfo.head];
                PositionInfo storage headPositionInfo = roundLedgers[targetEpoch][headLinkedPosition.user][
                headLinkedPosition.userPositionIndex
                ];
                // previous head position now is not eligible for incentive
                headPositionInfo.incentiveClaimable = false;
                // subtract head position amount, because we only keep the last RANKED_INCENTIVE positions
                roundInfo.incentiveSnapshot -= headPositionInfo.amount;
                // shift head to next global position to keep track the last N positions
                roundInfo.head += 1;

            }
        }

        // do transfer to platform
        {
            (bool success,) = platformAddress.call{
                    value: msg.value.mul(PLATFORM_RATIO).div(PRICE_PRECISION)
                }("");
            require(success, "Transfer failed.");
        }
        // emit event
        emit PositionOpened(msg.sender, targetEpoch, userTotalPositionCount, msg.value);
    }

    /**
     * @notice Close position
     * @param epoch: Epoch of the ledger
     * @param positionIndex: Position index of the user
     */
    function closePosition(
        uint256 epoch,
        uint256 positionIndex
    ) external notContract nonReentrant {
        require(epoch <= currentEpochs, "Invalid epoch");

        // check index is valid
        PositionInfo[] storage positionInfos = roundLedgers[epoch][msg.sender];
        require(positionIndex < positionInfos.length, "Invalid position index");

        // get position Info
        PositionInfo storage positionInfo = positionInfos[positionIndex];

        // get roundIno
        RoundInfo storage roundInfo = roundInfos[epoch];

        // user global info
        UserGlobalInfo storage userGlobalInfo = userGlobalInfos[msg.sender];

        _safeClosePosition(epoch, positionIndex, positionInfo, roundInfo, userGlobalInfo);
    }

    /**
     * @notice Close a batch of positions
     * @param epoch: Epoch of the ledger
     * @param positionIndexes: Position indexes of the user
     */
    function batchClosePositions(
        uint256 epoch,
        uint256[] calldata positionIndexes
    ) external nonReentrant {
        require(epoch <= currentEpochs, "Invalid epoch");
        require(positionIndexes.length > 0, "Invalid position indexes");

        // check index is valid
        PositionInfo[] storage positionInfos = roundLedgers[epoch][msg.sender];

        // get roundIno
        RoundInfo storage roundInfo = roundInfos[epoch];

        // position info placeholder
        PositionInfo storage positionInfo;

        // user global info
        UserGlobalInfo storage userGlobalInfo = userGlobalInfos[msg.sender];

        uint256 positionIndexesLength = positionIndexes.length;
        uint256 positionInfosLength = positionInfos.length;
        for (uint256 i = 0; i < positionIndexesLength; ++i) {
            require(positionIndexes[i] < positionInfosLength, "Invalid position index");
            // get position Info
            positionInfo = positionInfos[positionIndexes[i]];
            _safeClosePosition(epoch, positionIndexes[i], positionInfo, roundInfo, userGlobalInfo);
        }
    }

    /**
     * @notice Claim a batch of incentive claimable positions
     * @param epoch: Epoch of the ledger
     * @param positionIndexes: Position indexes of the user
     */
    function batchClaimPositionIncentiveReward(
        uint256 epoch,
        uint256[] calldata positionIndexes
    ) external notContract nonReentrant {
        require(epoch < currentEpochs, "Epoch not finished");

        // get position infos
        PositionInfo[] storage positionInfos = roundLedgers[epoch][msg.sender];

        // get roundInfo
        RoundInfo storage roundInfo = roundInfos[epoch];

        // get user round info
        uint256 userRoundIndex = roundInfo.ledgerRoundToUserRoundIndex[msg.sender];
        UserRoundInfo storage userRoundInfo = userRoundsInfos[msg.sender][userRoundIndex];

        // position info placeholder
        PositionInfo storage positionInfo;

        // collect payout
        uint256 payoutAmount;
        uint256 positionIndex;
        uint256 positionIndexesLength = positionIndexes.length;
        uint256 positionInfosLength = positionInfos.length;
        for (uint256 i = 0; i < positionIndexesLength; ++i) {
            positionIndex = positionIndexes[i];
            require(positionIndex < positionInfosLength, "Invalid position index");
            // get position Info
            positionInfo = positionInfos[positionIndex];
            require(positionInfo.incentiveClaimable, "Position not eligible");
            // update positionInfo
            payoutAmount += _safeProcessIncentiveAmount(positionInfo, roundInfo);
        }

        // transfer
        {
            (bool success,) = msg.sender.call{value: payoutAmount}("");
            require(success, "Transfer failed.");
        }

        // update userRoundInfo
        userRoundInfo.totalIncentiveClaimedAmount += payoutAmount;
        emit IncentiveClaimed(msg.sender, payoutAmount);
    }

    /**
     * @notice Report a batch users' sales
     * @param users: list of users
     */
    function batchReportSales(address[] calldata users) external {
        uint256 usersLength = users.length;
        for (uint256 i = 0; i < usersLength; ++i) {
            _safeReportSales(users[i]);
        }
    }

    /**
     * @notice Claim referrer reward
     * @param referrer: referrer address
     */
    function claimReferrerReward(address referrer) external notContract nonReentrant {
        require(referrer != address(0), "Invalid referrer address");

        // get user global info
        UserGlobalInfo storage userGlobalInfo = userGlobalInfos[referrer];

        // get claimable amount
        uint256 claimableAmount = userGlobalInfo.totalReferrerReward - userGlobalInfo.referrerRewardClaimed;

        require(claimableAmount > 0, "No claimable amount");

        // update state
        userGlobalInfo.referrerRewardClaimed += claimableAmount;

        // do transfer
        {
            (bool success,) = referrer.call{value: claimableAmount}("");
            require(success, "Transfer failed.");
        }

        // emit event
        emit ReferrerRewardClaimed(referrer, claimableAmount);
    }

    function getLinkedPositionInfo(
        uint256 epoch,
        uint256 cursor,
        uint256 size
    ) external view returns (LinkedPosition[] memory, uint256) {
        uint256 length = size;
        uint256 positionCount = roundInfos[epoch].totalPositionCount;
        if (cursor + length > positionCount) {
            length = positionCount - cursor;
        }
        LinkedPosition[] memory linkedPositions = new LinkedPosition[](length);
        RoundInfo storage roundInfo = roundInfos[epoch];
        for (uint256 i = 0; i < length; ++i) {
            linkedPositions[i] = roundInfo.linkedPositions[cursor + i];
        }
        return (linkedPositions, cursor + length);
    }

    function getUserRounds(
        address user,
        uint256 cursor,
        uint256 size
    ) external view returns (UserRoundInfo[] memory, uint256) {
        uint256 length = size;
        uint256 roundCount = userRoundsInfos[user].length;
        if (cursor + length > roundCount) {
            length = roundCount - cursor;
        }

        UserRoundInfo[] memory userRoundInfos = new UserRoundInfo[](length);
        for (uint256 i = 0; i < length; ++i) {
            userRoundInfos[i] = userRoundsInfos[user][cursor + i];
        }

        return (userRoundInfos, cursor + length);
    }

    function getUserRoundsLength(address user) external view returns (uint256) {
        return userRoundsInfos[user].length;
    }

    function getUserRoundLedgers(
        uint256 epoch,
        address user,
        uint256 cursor,
        uint256 size
    ) external view returns (PositionInfo[] memory, uint256) {
        uint256 length = size;
        uint256 positionCount = roundLedgers[epoch][user].length;
        if (cursor + length > positionCount) {
            length = positionCount - cursor;
        }

        PositionInfo[] memory positionInfos = new PositionInfo[](length);
        for (uint256 i = 0; i < length; ++i) {
            positionInfos[i] = roundLedgers[epoch][user][cursor + i];
        }

        return (positionInfos, cursor + length);
    }

    function getUserRoundLedgersLength(
        uint256 epoch,
        address user
    ) external view returns (uint256) {
        return roundLedgers[epoch][user].length;
    }

    function getChildren(
        address user,
        uint256 cursor,
        uint256 size
    ) external view returns (address[] memory, uint256) {
        uint256 length = size;
        uint256 childrenCount = children[user].length;
        if (cursor + length > childrenCount) {
            length = childrenCount - cursor;
        }

        address[] memory _children = new address[](length);
        for (uint256 i = 0; i < length; ++i) {
            _children[i] = children[user][cursor + i];
        }

        return (_children, cursor + length);
    }

    function getLedgerRoundToUserRoundIndex(
        uint256 epoch,
        address user
    ) external view returns (uint256) {
        return roundInfos[epoch].ledgerRoundToUserRoundIndex[user];
    }

    function getChildrenLength(address user) external view returns (uint256) {
        return children[user].length;
    }

    function getUserDepartSalesAndLevel(address user) external view returns (uint256, uint8) {
        UserGlobalInfo storage userGlobalInfo = userGlobalInfos[user];
        return (userGlobalInfo.sales - userGlobalInfo.maxChildrenSales, userGlobalInfo.salesLevel);
    }

    /**
     * @notice close a given position
     * @param epoch: epoch of the ledger
     * @param positionIndex: position index of the user
     * @param positionInfo: storage of the position info
     * @param roundInfo: storage of the round info
     */
    function _safeClosePosition(
        uint256 epoch,
        uint256 positionIndex,
        PositionInfo storage positionInfo,
        RoundInfo storage roundInfo,
        UserGlobalInfo storage userGlobalInfo
    ) internal {
        require(positionInfo.withdrawnAmount == 0, "Position already claimed");
        require(positionInfo.expiryTime <= block.timestamp || roundInfo.stopLoss, "Position not expired");

        // get user round info from storage
        uint256 targetRoundInfoIndex = roundInfo.ledgerRoundToUserRoundIndex[msg.sender];
        UserRoundInfo storage userRoundInfo = userRoundsInfos[msg.sender][targetRoundInfoIndex];

        // calculate the amount to withdraw
        uint256 payoutAmount;
        uint256 principalAmount = (positionInfo.amount * PRINCIPAL_RATIO) / PRICE_PRECISION;

        // get back the principal amount
        payoutAmount += principalAmount;

        // update roundInfo
        roundInfo.currentPositionCount -= 1;
        roundInfo.currentPrincipalAmount -= principalAmount;

        if (!roundInfo.stopLoss) {
            // calculate expected invest return amount
            // how many days passed
            uint256 daysPassed = (positionInfo.expiryTime - positionInfo.openTime);

            uint256 expectedInvestReturnAmount = (positionInfo.amount * positionInfo.investReturnRate * daysPassed) /
            PRICE_PRECISION /
            TIME_UNIT;

            // calculate the amount should be paid back from invest pool
            // 39% to total amount + expected return amount
            uint256 investReturnAmount = positionInfo.amount - principalAmount + expectedInvestReturnAmount;

            // compare if current invest pool has enough amount
            if (roundInfo.currentInvestAmount < investReturnAmount) {
                // not enough, then just pay back the current invest pool amount
                investReturnAmount = roundInfo.currentInvestAmount;
                roundInfo.currentInvestAmount = 0;
            } else {
                // update round info
            unchecked {
                roundInfo.currentInvestAmount -= investReturnAmount;
            }
            }

            // check round is stop loss
            if (roundInfo.currentInvestAmount == 0) {
                roundInfo.stopLoss = true;
                currentEpochs += 1;
                emit NewRound(currentEpochs);
            }

            // update payout amount
            payoutAmount += investReturnAmount;

            // update positionInfo
            positionInfo.investReturnAmount = investReturnAmount;
        }

        uint256 incentiveAmount = 0;
        // calculate incentive amount if eligible
        if (roundInfo.stopLoss && positionInfo.incentiveClaimable) {
            incentiveAmount = _safeProcessIncentiveAmount(positionInfo, roundInfo);

            // update payout amount
            payoutAmount += incentiveAmount;

            // update incentive info to storage
            userRoundInfo.totalIncentiveClaimedAmount += incentiveAmount;

            emit IncentiveClaimed(msg.sender, incentiveAmount);
        }

        // update user round info
        userRoundInfo.totalWithdrawnAmount += payoutAmount;
        userRoundInfo.currentPrincipalAmount -= principalAmount;

        // update positionInfo
        positionInfo.withdrawnAmount = payoutAmount;

        // accumulate user's boost credit
        if (payoutAmount - incentiveAmount < positionInfo.amount) {
            userGlobalInfo.boostCredit += positionInfo.amount - (positionInfo.amount * PRINCIPAL_RATIO / PRICE_PRECISION);
        }

        if (payoutAmount > address(this).balance) {
            payoutAmount = address(this).balance;
        }
        // do transfer
        {
            (bool success,) = msg.sender.call{value: payoutAmount}("");
            require(success, "Transfer failed.");
        }

        // emit event
        emit PositionClosed(msg.sender, epoch, positionIndex, payoutAmount);
    }

    /**
     * @notice process positionInfo and return incentive amount
     * @param positionInfo: storage of the position info
     * @param roundInfo: storage of the round info
     */
    function _safeProcessIncentiveAmount(PositionInfo storage positionInfo, RoundInfo storage roundInfo)
    internal
    returns (uint256)
    {
        // calculate incentive amount
        uint256 incentiveAmount = (positionInfo.amount * roundInfo.totalPositionAmount * INCENTIVE_RATIO) /
        roundInfo.incentiveSnapshot /
        PRICE_PRECISION;

        // with PRICE_PRECISION is due to the precision of division may result in a few wei left over
        if (roundInfo.currentIncentiveAmount < incentiveAmount + PRICE_PRECISION) {
            // clean up incentive amount
            incentiveAmount = roundInfo.currentIncentiveAmount;
            roundInfo.currentIncentiveAmount = 0;
        } else {
            roundInfo.currentIncentiveAmount -= incentiveAmount;
        }

        // this position is no longer eligible for incentive
        positionInfo.incentiveClaimable = false;

        // update positionInfo
        positionInfo.incentiveAmount = incentiveAmount;

        return incentiveAmount;
    }

    /**
     * @notice process user's level info and return the current level
     * @param currentLevel: user current level
     * @param user: user address
     * @param currentSales: user current sales
     * @param userGlobalInfo: storage of the user global info
     */
    function _safeProcessSalesLevel(
        uint8 currentLevel,
        address user,
        uint256 currentSales,
        UserGlobalInfo storage userGlobalInfo
    ) internal returns (uint8) {
        uint8 newLevel = _getSalesToLevel(currentSales);
        if (newLevel > currentLevel) {
            userGlobalInfo.salesLevel = newLevel;
            emit SalesLevelUpdated(user, newLevel);
        } else {
            newLevel = currentLevel;
        }
        return newLevel;
    }

    /**
     * @notice report user's sales and update its referrer sales level
     * @param user: user address
     */
    function _safeReportSales(address user) internal {
        UserGlobalInfo storage userGlobalInfo = userGlobalInfos[user];
        address referrer = userGlobalInfo.referrer;
        uint256 userSales = userGlobalInfo.sales;
        uint256 userReportedSales = userGlobalInfo.reportedSales;

        // get user's un-reported sales
        uint256 unreportedSales = userSales - userReportedSales;

        if (unreportedSales > 0) {
            // get referrer global info from storage
            UserGlobalInfo storage referrerGlobalInfo = userGlobalInfos[referrer];
            // fill up the sales to the referrer
            referrerGlobalInfo.sales += unreportedSales;
            // update user's reported sales
            userGlobalInfo.reportedSales = userSales;

            // all reported sales + user's own contributed position will be current user's final sales
            userSales += userGlobalInfo.totalPositionAmount;
            // current referrer's max children sales
            uint256 maxChildrenSales = referrerGlobalInfo.maxChildrenSales;
            // update max children sales if needed
            if (userSales > maxChildrenSales) {
                // referrer's max children sales is updated
                referrerGlobalInfo.maxChildrenSales = userSales;
                // update cache of max children sales
                maxChildrenSales = userSales;
            }
            // process referrer's sales level
            _safeProcessSalesLevel(
                referrerGlobalInfo.salesLevel,
                referrer,
                referrerGlobalInfo.sales - maxChildrenSales, // sales for level calculation is sales - max children sales
                referrerGlobalInfo
            );
        }
    }

    /**
     * @notice distribute referrer reward
     * @param user: user address
     * @param referrerAmount: total amount of referrer reward
     */
    function _distributeReferrerReward(address user, uint256 referrerAmount) internal virtual {
        UserGlobalInfo storage userGlobalInfo = userGlobalInfos[user];
        UserGlobalInfo storage referrerGlobalInfo;
        uint256 positionAmount = msg.value;

        // init all local variables as a search struct
        ReferrerSearch memory search;
        search.baseSalesLevel = 0;
        search.currentReferrer = userGlobalInfo.referrer;
        search.levelDiffAmount = (referrerAmount * 50) / 100;
        search.leftLevelDiffAmount = search.levelDiffAmount;
        search.levelDiffAmountPerLevel = search.levelDiffAmount / 6;
        search.levelSearchAmount = referrerAmount - search.levelDiffAmount;
        search.leftLevelSearchAmount = search.levelSearchAmount;
        search.levelSearchAmountPerReferrer = search.levelSearchAmount / 10;

        search.currentUserTotalPosAmount = userGlobalInfo.totalPositionAmount + positionAmount;
        userGlobalInfo.totalPositionAmount = search.currentUserTotalPosAmount;
        search.currentUser = user;

        while (search.depth < MAX_SEARCH_DEPTH) {
            // stop if current referrer is the root
            if (search.currentReferrer == address(0)) {
                break;
            }

            // this position does not counted as reported sales for first user himself
            if (search.depth > 0) userGlobalInfo.reportedSales += positionAmount;

            // cache current user information
            search.currentUserSales = userGlobalInfo.sales;
            search.currentUserReportedSales = userGlobalInfo.reportedSales;

            // cache current referrer information
            referrerGlobalInfo = userGlobalInfos[search.currentReferrer];

            // update referrer sales
            {
                search.currentReferrerSales = referrerGlobalInfo.sales;
                // add current sales to current referrer
                search.currentReferrerSales += positionAmount;
                // check unreported sales
                if (search.currentUserReportedSales < search.currentUserSales) {
                    // update referrerSales to include unreported sales
                    search.currentReferrerSales += search.currentUserSales - search.currentUserReportedSales;
                    // update current node storage for reported sales
                    userGlobalInfo.reportedSales = search.currentUserSales;
                }
                // update sales for current referrer
                referrerGlobalInfo.sales = search.currentReferrerSales;
            }

            // update referrer max children sales
            {
                // add current user's total position amount to current user's sales
                search.currentUserSales += search.currentUserTotalPosAmount;
                // check referrer's max child sales
                search.currentReferrerMaxChildSales = referrerGlobalInfo.maxChildrenSales;
                if (search.currentReferrerMaxChildSales < search.currentUserSales) {
                    // update max child sales
                    referrerGlobalInfo.maxChildrenSales = search.currentUserSales;
                    search.currentReferrerMaxChildSales = search.currentUserSales;
                }
            }

            // process referrer's sales level
            // @notice: current referrer sales level should ignore its max child sales
            search.currentReferrerLevel = _safeProcessSalesLevel(
                referrerGlobalInfo.salesLevel,
                search.currentReferrer,
                search.currentReferrerSales - search.currentReferrerMaxChildSales,
                referrerGlobalInfo
            );

            // start level diff calculation
            if (!search.levelDiffDone) {
                // compare the current referrer's level with the base sales level
                if (search.currentReferrerLevel > search.baseSalesLevel) {
                    // level diff
                    search.currentLevelDiff = search.currentReferrerLevel - search.baseSalesLevel;

                    // update base level
                    search.baseSalesLevel = search.currentReferrerLevel;

                    // calculate the referrer amount
                    search.currentReferrerAmount = search.currentLevelDiff * search.levelDiffAmountPerLevel;

                    // check left referrer amount
                    if (search.currentReferrerAmount + PRICE_PRECISION > search.leftLevelDiffAmount) {
                        search.currentReferrerAmount = search.leftLevelDiffAmount;
                    }

                    // update referrer's referrer amount
                    referrerGlobalInfo.totalReferrerReward += search.currentReferrerAmount;
                    emit ReferrerRewardAdded(search.currentReferrer, search.currentReferrerAmount, 0);

                unchecked {
                    search.leftLevelDiffAmount -= search.currentReferrerAmount;
                }

                    if (search.leftLevelDiffAmount == 0) {
                        search.levelDiffDone = true;
                    }
                }
            }
            if (!search.levelSearchDone) {
                // level search use referrer's real level
                search.levelSearchStep = _getLevelToLevelSearchStep(
                    _getSalesToLevel(search.currentReferrerSales - search.currentReferrerMaxChildSales)
                );
                if (search.numLevelSearchCandidate + 1 <= search.levelSearchStep) {
                    search.numLevelSearchCandidate += 1;

                    // check left referrer amount
                    if (search.levelSearchAmountPerReferrer + PRICE_PRECISION > search.leftLevelSearchAmount) {
                        search.levelSearchAmountPerReferrer = search.leftLevelSearchAmount;
                    }

                    // update referrer's referrer amount
                    referrerGlobalInfo.totalReferrerReward += search.levelSearchAmountPerReferrer;
                    emit ReferrerRewardAdded(search.currentReferrer, search.levelSearchAmountPerReferrer, 1);
                unchecked {
                    search.leftLevelSearchAmount -= search.levelSearchAmountPerReferrer;
                }

                    if (search.leftLevelSearchAmount == 0) {
                        search.levelSearchDone = true;
                    }
                }
            }

            search.currentUser = search.currentReferrer;
            search.currentReferrer = referrerGlobalInfo.referrer;

            userGlobalInfo = referrerGlobalInfo;
            search.currentUserTotalPosAmount = userGlobalInfo.totalPositionAmount;

        unchecked {
            search.depth += 1;
        }
        }
    }

    /**
     * @notice get sales level from sales amount
     * @param amount: sales amount
     */
    function _getSalesToLevel(uint256 amount) internal pure virtual returns (uint8) {
        /* istanbul ignore else  */
        if (amount < 10000 ether) {
            return 0;
        } else if (amount < 100000 ether) {
            return 1;
        } else if (amount < 500000 ether) {
            return 2;
        } else if (amount < 2000000 ether) {
            return 3;
        } else if (amount < 5000000 ether) {
            return 4;
        } else if (amount < 10000000 ether) {
            return 5;
        }
        return 6;
    }

    /**
     * @notice level search step from level
     * @param level: sales level (0-10)
     */
    function _getLevelToLevelSearchStep(uint8 level) internal pure returns (uint8) {
    unchecked {
        if (level < 5) return level * 2;
    }
        return 10;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./DateTime.sol";

contract Bucket {
    using SafeMath for *;
    using DateTime for uint256;
    struct BucketStock {
        mapping(uint => uint256) dailyTradeVolume;
        mapping(uint => mapping(uint => uint256[24])) hourTradeVolume;
        uint256 currentTotalVolume;
        mapping(uint => uint256[45]) epochDaysVolume;
        uint256 maxReturnRateOrderNum;
        uint256 minReturnRateOrderNum;
    }

    uint256 public constant MAX_RETURN_RATE = 10000; // 1%
    uint256 public constant MIN_RETURN_RATE = 6180; // 0.618%
    uint256 public constant DAILY_GROWTH = 20000; // 2%
    uint256 public constant MAX_VOLUME = 72e22; // 72W

    uint256 public contractCreateTime;

    BucketStock  ledgerBucketStock;

    constructor(){
        // initialize contract params
        contractCreateTime = block.timestamp;
        uint yesterdayTimestamp = DateTime.getYesterdayTimestamp(block.timestamp);
        BucketStock storage bucketStock = ledgerBucketStock;
        bucketStock.dailyTradeVolume[yesterdayTimestamp] = 12e22;
    }

    function _pickLocation(uint epoch, uint start, uint end) internal returns (uint){
        BucketStock storage bucketStock = ledgerBucketStock;
        uint minValueIndex = start;
        for(uint i = start + 1; i < end; i++){
            if(bucketStock.epochDaysVolume[epoch][i] < bucketStock.epochDaysVolume[epoch][minValueIndex]){
                minValueIndex = i;
            }
        }
        return minValueIndex;
    }

    function pickLocation(uint epoch) internal returns (uint){
        BucketStock storage bucketStock = ledgerBucketStock;
        uint256 rate = _getReturnRate(epoch);
        uint start = 0;
        uint end = 44;
        if (rate == MAX_RETURN_RATE){
            // 1. 0-14 50% 2. 15-29 40% 3. 30-44 10%
            if (bucketStock.maxReturnRateOrderNum % 10 < 5){
                start = 0;
                end = 14;
            }else if (bucketStock.maxReturnRateOrderNum % 10 < 9){
                start = 15;
                end = 29;
            }else{
                start = 30;
                end = 44;
            }
            bucketStock.maxReturnRateOrderNum += 1;
        } else {
            // 1. 0-14 30% 2. 15-29 40% 3. 30-44 30%
            if (bucketStock.minReturnRateOrderNum % 10 < 3){
                start = 0;
                end = 14;
            }else if (bucketStock.minReturnRateOrderNum % 10 < 7){
                start = 15;
                end = 29;
            }else{
                start = 30;
                end = 44;
            }
            bucketStock.minReturnRateOrderNum += 1;
        }
        return _pickLocation(epoch, start, end);
    }

    /**
    *
    */
    function getReturnRate(uint epoch) external view returns (uint256 rate) {
        (rate) = _getReturnRate(epoch);
    }

    function _getReturnRate(uint epoch) internal view returns (uint256) {
        BucketStock storage bucketStock = ledgerBucketStock;
        if (bucketStock.currentTotalVolume >= MAX_VOLUME) {
            return MIN_RETURN_RATE;
        }
        uint yesterdayTimestamp = DateTime.getYesterdayTimestamp(block.timestamp);
        uint256 todayTarget = bucketStock.dailyTradeVolume[yesterdayTimestamp].mul(DAILY_GROWTH).div(1000000);
        uint256 hourTarget = todayTarget.div(24);
        uint hour = DateTime.getHour(block.timestamp);
        uint timestamp = DateTime.getTodayTimestamp(block.timestamp);
        uint256 currentSales = bucketStock.hourTradeVolume[epoch][timestamp][hour];
        if (currentSales >= hourTarget) {
            return MIN_RETURN_RATE;
        } else {
            return MAX_RETURN_RATE;
        }
    }
}

// SPDX-License-Identifier: nv3ob61
pragma solidity ^0.8.14;

library DateTime {
    /*
     *  Date and Time utilities for ethereum contracts
     *
     */
    struct _DateTime {
        uint16 year;
        uint8 month;
        uint8 day;
        uint8 hour;
        uint8 minute;
        uint8 second;
        uint8 weekday;
    }

    uint constant DAY_IN_SECONDS = 86400;
    uint constant YEAR_IN_SECONDS = 31536000;
    uint constant LEAP_YEAR_IN_SECONDS = 31622400;

    uint constant MAX_TIMESTAMP = 5175273600;  // years, months, days
    uint constant MIN_TIMESTAMP = 0; // Epoch

    uint constant HOUR_IN_SECONDS = 3600;
    uint constant MINUTE_IN_SECONDS = 60;

    uint16 constant ORIGIN_YEAR = 1970;

    uint16 constant nonce = 0;

    function isLeapYear(uint16 year) public pure returns (bool) {
        if (year % 4 != 0) {
            return false;
        }
        if (year % 100 != 0) {
            return true;
        }
        if (year % 400 != 0) {
            return false;
        }
        return true;
    }

    function isDateInRange(uint timestamp) public pure returns (bool){
        if (timestamp >= MIN_TIMESTAMP && timestamp <= MAX_TIMESTAMP) {
            return true;
        } else {
            return false;
        }
    }

    function random() public view returns (uint) {
        uint randomNumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % MAX_TIMESTAMP;
        randomNumber = randomNumber + 100;
        return randomNumber;
    }

    function leapYearsBefore(uint year) public pure returns (uint) {
        year -= 1;
        return year / 4 - year / 100 + year / 400;
    }

    function getDaysInMonth(uint8 month, uint16 year) public pure returns (uint8) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            return 31;
        }
        else if (month == 4 || month == 6 || month == 9 || month == 11) {
            return 30;
        }
        else if (isLeapYear(year)) {
            return 29;
        }
        else {
            return 28;
        }
    }

    function parseTimestamp(uint timestamp) internal pure returns (_DateTime memory dt) {
        uint secondsAccountedFor = 0;
        uint buf;
        uint8 i;

        // Year
        dt.year = getYear(timestamp);
        buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
        secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

        // Month
        uint secondsInMonth;
        for (i = 1; i <= 12; i++) {
            secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
            if (secondsInMonth + secondsAccountedFor > timestamp) {
                dt.month = i;
                break;
            }
            secondsAccountedFor += secondsInMonth;
        }

        // Day
        for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
            if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                dt.day = i;
                break;
            }
            secondsAccountedFor += DAY_IN_SECONDS;
        }

        // Hour
        dt.hour = getHour(timestamp);

        // Minute
        dt.minute = getMinute(timestamp);

        // Second
        dt.second = getSecond(timestamp);

        // Day of week.
        dt.weekday = getWeekday(timestamp);
    }

    function getYear(uint timestamp) public pure returns (uint16) {
        uint secondsAccountedFor = 0;
        uint16 year;
        uint numLeapYears;

        // Year
        year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
        numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
        secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

        while (secondsAccountedFor > timestamp) {
            if (isLeapYear(uint16(year - 1))) {
                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
            }
            else {
                secondsAccountedFor -= YEAR_IN_SECONDS;
            }
            year -= 1;
        }
        return year;
    }

    function getMonth(uint timestamp) public pure returns (uint8) {
        return parseTimestamp(timestamp).month;
    }

    function getDay(uint timestamp) public pure returns (uint8) {
        return parseTimestamp(timestamp).day;
    }

    function getTodayTimestamp(uint timestamp) public pure returns (uint){
        _DateTime memory dt = parseTimestamp(timestamp);
        return toTimestamp(dt.year, dt.month, dt.day);
    }

    function getYesterdayTimestamp(uint timestamp) public pure returns (uint){
        _DateTime memory dt = parseTimestamp(timestamp-86400);
        return toTimestamp(dt.year, dt.month, dt.day);
    }

    /**
    * get day 12 periods 0-2 -> 1, 2-4 -> 2, 4-6 -> 3
    */
    function getDay12Periods(uint timestamp) public pure returns (uint){
        uint hour = parseTimestamp(timestamp).hour;
        if (hour == 0) return 1;
        if (hour % 2 == 0) {
            return hour / 2;
        }
        return uint8(hour / 2) + 1;
    }

    function getHour(uint timestamp) public pure returns (uint8) {
        return uint8((timestamp / 60 / 60) % 24);
    }

    function getMinute(uint timestamp) public pure returns (uint8) {
        return uint8((timestamp / 60) % 60);
    }

    function getSecond(uint timestamp) public pure returns (uint8) {
        return uint8(timestamp % 60);
    }

    function getWeekday(uint timestamp) public pure returns (uint8) {
        return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day) public pure returns (uint timestamp) {
        return toTimestamp(year, month, day, 0, 0, 0);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) public pure returns (uint timestamp) {
        return toTimestamp(year, month, day, hour, 0, 0);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) public pure returns (uint timestamp) {
        return toTimestamp(year, month, day, hour, minute, 0);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) public pure returns (uint timestamp) {
        uint16 i;

        // Year
        for (i = ORIGIN_YEAR; i < year; i++) {
            if (isLeapYear(i)) {
                timestamp += LEAP_YEAR_IN_SECONDS;
            }
            else {
                timestamp += YEAR_IN_SECONDS;
            }
        }

        // Month
        uint8[12] memory monthDayCounts;
        monthDayCounts[0] = 31;
        if (isLeapYear(year)) {
            monthDayCounts[1] = 29;
        }
        else {
            monthDayCounts[1] = 28;
        }
        monthDayCounts[2] = 31;
        monthDayCounts[3] = 30;
        monthDayCounts[4] = 31;
        monthDayCounts[5] = 30;
        monthDayCounts[6] = 31;
        monthDayCounts[7] = 31;
        monthDayCounts[8] = 30;
        monthDayCounts[9] = 31;
        monthDayCounts[10] = 30;
        monthDayCounts[11] = 31;

        for (i = 1; i < month; i++) {
            timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
        }

        // Day
        timestamp += DAY_IN_SECONDS * (day - 1);

        // Hour
        timestamp += HOUR_IN_SECONDS * (hour);

        // Minute
        timestamp += MINUTE_IN_SECONDS * (minute);

        // Second
        timestamp += second;

        return timestamp;
    }
}