// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IStakingLockAgent, IRefTreeStorage, ITicketsCounter, ILockableStaking} from './Interfaces.sol';
import {LockableStaking} from './LockableStaking.sol';
import {RefProgramBase} from './RefProgramBase.sol';
import {SafeERC20, IERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {IERC20Metadata} from '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

abstract contract RefProgram is RefProgramBase {
    using SafeERC20 for IERC20;
    struct RefUserInfo {
        uint256[3] refCumulativeRewards;
        uint256[3] refCumulativeParticipants;
    }

    ITicketsCounter public ticketsCounter;
    uint256[3] public refererShares = [10, 5, 3];
    mapping(address => RefUserInfo) _refUserInfo;

    event RefRewardDistributed(
        address indexed referer,
        address indexed staker,
        uint8 indexed level,
        uint256 amount,
        uint256 timestamp
    );

    constructor(IRefTreeStorage refTreeStorage_, ITicketsCounter ticketsCounter_) RefProgramBase(refTreeStorage_) {
        setTicketsCounter(ticketsCounter_);
    }

    // SETTERS

    function setTicketsCounter(ITicketsCounter ticketsCounter_) public onlyOwner {
        ticketsCounter = ticketsCounter_;
    }

    function setRefShares(uint256[3] calldata shares) public onlyOwner {
        refererShares = shares;
    }

    // INTERNAL OPERATIONS

    function _refDistributeParticipants(address staker) internal {
        address referer = staker;
        for (uint8 i = 0; i < 3; i++) {
            referer = refTreeStorage.refererOf(referer);
            if (referer == address(0)) {
                break;
            }
            _refUserInfo[referer].refCumulativeParticipants[i]++;
        }
    }

    function _refDistributeRewards(
        IERC20 rewardToken,
        uint256 amount,
        address staker
    ) internal {
        address referer = staker;
        for (uint8 i = 0; i < 3; i++) {
            referer = refTreeStorage.refererOf(referer);
            if (referer == address(0)) {
                break;
            }
            uint256 refReward = (amount * refererShares[i]) / 100;
            rewardToken.safeTransfer(referer, refReward);
            emit RefRewardDistributed(referer, staker, i, refReward, block.timestamp);
            _refUserInfo[referer].refCumulativeRewards[i] += refReward;
        }
    }

    // EXTERNAL GETTERS

    function refUserInfo(address user)
        external
        view
        returns (
            RefUserInfo memory info,
            address referer,
            address[] memory referrals
        )
    {
        info = _refUserInfo[user];
        referer = refTreeStorage.refererOf(user);
        referrals = refTreeStorage.referralsOf(user);
    }
}

contract BetaIDO is RefProgram, IStakingLockAgent {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    IERC20 public BUSD;

    struct VestingParams {
        uint32[] startPeriods;
        uint256[] startAmounts;
        uint32 mainPeriod;
        uint32 mainStepTime;
        uint256 mainAmount;
        uint32[] finalPeriods;
        uint256[] finalAmounts;
    }

    struct ProgramParams {
        uint16 places;
        uint256 busdAmount;
        uint256 tokenAmount;
        IERC20 token;
        uint32 registrationStart;
        uint32 registrationEnd;
        uint32 draw;
    }

    struct Program {
        VestingParams vesting; // unchangeable
        ProgramParams params; // unchangeable
        bool drawn; // To prevent double draw
        uint256 claimed; // To count how much tokens users have claimed
        bool refProgramActive; // Distribute referral program rewards or not
        bool cancelled; // Admin can cancel and let every user get all their busd back (unless user claimed tokens already)
        uint256 nextDrawIndex; // To split draw() in several tx's when necessary
        uint32 _filledDate; // calculated during adding
    }

    struct UserInfo {
        uint256 tickets;
        bool winner;
        uint256 claimed;
    }

    /**
     * Just to track tokens that are involved in (not cancelled) IDO's
     * @notice SHALL USE ONLY add(), remove(), contains() - NOT RELY ON INDEXES
     */
    EnumerableSet.AddressSet _tokensInvolved;
    /// @notice SHALL NEVER REMOVE USERS FROM THIS - userIndexes MUST STAY UNMODIFIED
    mapping(uint256 => EnumerableSet.AddressSet) _participantsOf;
    mapping(uint256 => uint16[]) _ticketsAt; // Values here are userIndexes
    Program[] _programs;
    mapping(uint256 => mapping(address => UserInfo)) _userInfos;

    event ProgramAdded(uint256 indexed index, IERC20 indexed token);
    event ProgramCancelled(uint256 indexed index, string reason);
    event RefProgramStatusSet(uint256 indexed index, bool value);
    event Draw(uint256 indexed index, bool indexed finished);
    event UserRegistered(uint256 indexed index, address indexed user, uint256 tickets);
    event UserClaimed(uint256 indexed index, address indexed user, uint256 amount, bool finished);
    event UserWon(uint256 indexed index, address indexed user);
    event TokensTaken(IERC20 indexed token, uint256 amount);

    constructor(
        IERC20 BUSD_,
        IRefTreeStorage refTreeStorage_,
        ITicketsCounter ticketsCounter_
    ) RefProgram(refTreeStorage_, ticketsCounter_) {
        BUSD = BUSD_;
    }

    // USER ACTIONS

    function register(uint256 index) public returns (uint16 userIndex) {
        Program storage program = _programs[index];
        require(block.timestamp >= program.params.registrationStart, 'too early');
        require(block.timestamp < program.params.registrationEnd, 'too late');
        require(!_participantsOf[index].contains(msg.sender), 'registered');
        // Tickets counter is independent so that admins can modify tickets distribution
        // Also, it is called only during registration - tickets amount is saved to storage
        (uint256 tickets, ILockableStaking[] memory lockableStakings, uint256[] memory lockableAmounts) = ticketsCounter
            .countTickets(msg.sender, program.params.draw);
        require(tickets > 0, 'no tickets');
        for (uint256 i = 0; i < lockableStakings.length; i++) {
            lockableStakings[i].lockByAgent(msg.sender, program.params.draw, lockableAmounts[i], bytes32(index));
        }
        uint256 participantsLength = _participantsOf[index].length();
        // Practically impossible to reach 2^16 participants but it would cause catastrophe if anyone did
        require(participantsLength < type(uint16).max, 'limit');

        BUSD.safeTransferFrom(msg.sender, address(this), program.params.busdAmount);

        userIndex = uint16(participantsLength);
        _participantsOf[index].add(msg.sender);
        _userInfos[index][msg.sender] = UserInfo({tickets: tickets, winner: false, claimed: 0});
        for (uint256 i = 0; i < tickets; i++) {
            _ticketsAt[index].push(userIndex);
        }
        _refDistributeParticipants(msg.sender);
        emit UserRegistered(index, msg.sender, tickets);
    }

    function claim(uint256 index) external {
        require(_participantsOf[index].contains(msg.sender), 'not registered');
        if (_programs[index].cancelled) {
            _retrieveBusd(index, msg.sender);
            return;
        }
        require(_programs[index].drawn, 'too early');
        UserInfo storage info = _userInfos[index][msg.sender];
        ProgramParams storage params = _programs[index].params;
        if (_isWinner(index, msg.sender)) {
            uint256 claimable = getClaimable(index, msg.sender);
            require(claimable > 0, 'nothing to claim');
            params.token.safeTransfer(msg.sender, claimable);
            if (info.claimed == 0 && _programs[index].refProgramActive) {
                _refDistributeRewards(BUSD, params.busdAmount, msg.sender);
            }
            info.claimed += claimable;
            _programs[index].claimed += claimable;
            emit UserClaimed(index, msg.sender, claimable, info.claimed == params.tokenAmount);
        } else {
            _retrieveBusd(index, msg.sender);
        }
    }

    function _retrieveBusd(uint256 index, address user) internal {
        UserInfo storage info = _userInfos[index][user];
        require(info.claimed == 0, 'already retrieved');
        BUSD.safeTransfer(user, _programs[index].params.busdAmount);
        info.claimed = type(uint256).max; // Unique value to distinct users that has claimed their BUSD back
        emit UserClaimed(index, user, 0, true);
    }

    // OWNER ACTIONS

    function addProgram(
        VestingParams memory vesting,
        ProgramParams memory params,
        bool refProgramActive
    ) external onlyOwner returns (uint256 index) {
        uint32 _filledDate = _validateParams(vesting, params);
        index = _programs.length;
        _programs.push(
            Program({
                vesting: vesting,
                params: params,
                drawn: false,
                claimed: 0,
                refProgramActive: refProgramActive,
                cancelled: false,
                nextDrawIndex: 0,
                _filledDate: _filledDate
            })
        );
        _tokensInvolved.add(address(params.token));
        emit ProgramAdded(index, params.token);
    }

    function cancelProgram(uint256 index, string memory reason) external onlyOwner {
        require(!_programs[index].cancelled);
        _programs[index].cancelled = true;
        _tokensInvolved.remove(address(_programs[index].params.token));
        emit ProgramCancelled(index, reason);
    }

    function setRefProgramActive(uint256 index, bool value) external onlyOwner {
        require(_programs[index].refProgramActive != value);
        _programs[index].refProgramActive = value;
        emit RefProgramStatusSet(index, value);
    }

    function draw(uint256 index, uint256 gasLimit) external onlyOwner returns (bool finished) {
        Program storage program = _programs[index];
        require(block.timestamp >= program.params.draw, 'too early');
        require(!program.drawn, 'draw already done');

        if (_participantsOf[index].length() > program.params.places) {
            uint256 minGasThreshold = gasleft() - gasLimit;
            uint16 places = program.params.places;
            uint16[] storage tickets = _ticketsAt[index];
            for (uint256 i = program.nextDrawIndex; i < places; i++) {
                if (gasleft() < minGasThreshold) {
                    program.nextDrawIndex = i;
                    emit Draw(index, false);
                    return false;
                }
                uint16 winnerIndex = tickets[_generateRandom(tickets.length, i)];
                address winner = _participantsOf[index].at(winnerIndex);
                emit UserWon(index, winner);
                _userInfos[index][winner].winner = true;
                _removeTickets(index, winnerIndex, _userInfos[index][winner].tickets);
            }
        }
        program.drawn = true;
        delete _ticketsAt[index];
        emit Draw(index, true);
        return true;
    }

    function takeByAddress(IERC20 token, uint256 amount) public onlyOwner {
        require(!_tokensInvolved.contains(address(token)), 'involved');
        if (amount == 0) amount = token.balanceOf(address(this));
        token.safeTransfer(msg.sender, amount);
        emit TokensTaken(token, amount);
    }

    function takeByIndex(uint256 index, uint256 amount) public onlyOwner {
        Program storage program = _programs[index];
        require(block.timestamp > program._filledDate || program.cancelled, 'forbidden');
        if (amount == 0) amount = program.params.token.balanceOf(address(this));
        program.params.token.safeTransfer(msg.sender, amount);
        emit TokensTaken(program.params.token, amount);
    }

    /**
     * @dev Unlock possible for anyone if program was cancelled
     */
    function exceptionalUnlockPossible(address user, bytes32 payload) external view override returns (bool) {
        return _programs[uint256(payload)].cancelled;
    }

    function getClaimable(uint256 index, address user) public view returns (uint256 amount) {
        if (!_isWinner(index, user)) return 0;
        return _getCumulativeClaimable(index) - _userInfos[index][user].claimed;
    }

    function infoBundle(uint256 index, address user)
        external
        view
        returns (
            Program memory p,
            UserInfo memory u,
            uint256 busd_bal,
            uint256 busd_all,
            TokenMetadata memory token,
            bool isWinner,
            uint256 ticketsCounted
        )
    {
        p = _programs[index];
        u = _userInfos[index][user];
        busd_bal = BUSD.balanceOf(user);
        busd_all = BUSD.allowance(user, address(this));
        token = infoBundleToken(IERC20Metadata(address(p.params.token)));
        isWinner = _isWinner(index, user);
        (ticketsCounted, , ) = ticketsCounter.countTickets(user, p.params.draw);
    }

    struct TokenMetadata {
        uint8 decimals;
        string name;
        string symbol;
        uint256 totalSupply;
    }

    function infoBundleToken(IERC20Metadata token) public view returns (TokenMetadata memory) {
        return
            TokenMetadata({
                decimals: token.decimals(),
                name: token.name(),
                symbol: token.symbol(),
                totalSupply: token.totalSupply()
            });
    }

    function programs(uint256 from, uint256 to) public view returns (Program[] memory p) {
        uint256 length = to - from + 1;
        p = new Program[](length);
        for (uint256 i = 0; i < length; i++) {
            p[i] = _programs[i + from];
        }
    }

    function programs(uint256 last) external view returns (Program[] memory p, uint256 from) {
        uint256 pl = _programs.length;
        if (last > pl) last = pl;
        from = pl - last;
        p = programs(from, pl - 1);
    }

    function programs() external view returns (Program[] memory) {
        return _programs;
    }

    function participantsOf(uint256 index) external view returns (address[] memory) {
        return _participantsOf[index].values();
    }

    function participantsOf(uint256 index, address user) external view returns (bool) {
        return _participantsOf[index].contains(user);
    }

    // INTERNAL

    /// @return value that fits in [0, range)
    function _generateRandom(uint256 range, uint256 salt) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, salt))) % range;
    }

    function _validateParams(VestingParams memory vesting, ProgramParams memory params)
        internal
        view
        returns (uint32 filledDate)
    {
        require(!_tokensInvolved.contains(address(params.token)), '!REPEAT');
        // Amount consistency check
        uint256 totalAmount;
        filledDate = params.draw;
        for (uint256 i = 0; i < vesting.startPeriods.length; i++) {
            filledDate += vesting.startPeriods[i];
            totalAmount += vesting.startAmounts[i];
        }
        filledDate += vesting.mainPeriod;
        totalAmount += vesting.mainAmount;
        for (uint256 i = 0; i < vesting.finalPeriods.length; i++) {
            filledDate += vesting.finalPeriods[i];
            totalAmount += vesting.finalAmounts[i];
        }
        require(totalAmount == params.tokenAmount, '!AMOUNT');
        require(
            params.draw > params.registrationEnd &&
                params.registrationEnd > params.registrationStart &&
                params.registrationStart > (block.timestamp + 30 minutes),
            '!DATES'
        );
        require(
            params.busdAmount > 0 && params.tokenAmount > 0 && params.places > 0 && address(params.token) != address(0),
            '!ZERO'
        );
    }

    function _getCumulativeClaimable(uint256 index) internal view returns (uint256 amount) {
        ProgramParams storage params = _programs[index].params;
        VestingParams storage vesting = _programs[index].vesting;
        // If whole period passed already then return total
        uint256 _now = block.timestamp;
        if (_now >= _programs[index]._filledDate) return params.tokenAmount;
        uint256 _then = params.draw;
        // Periods before main (if any)
        for (uint256 i = 0; i < vesting.startPeriods.length; i++) {
            if (_now < _then) return amount;
            amount += vesting.startAmounts[i];
            _then += vesting.startPeriods[i];
        }
        // Main period
        if (_now < _then) return amount;
        uint256 timePassed = _now - _then;
        if (timePassed >= vesting.mainPeriod) {
            amount += vesting.mainAmount;
        } else {
            timePassed = (timePassed / vesting.mainStepTime) * vesting.mainStepTime;
            amount += (timePassed * vesting.mainAmount) / vesting.mainPeriod;
            return amount;
        }
        _then += vesting.mainPeriod;
        // Periods before main (if any)
        for (uint256 i = 0; i < vesting.finalPeriods.length; i++) {
            if (_now < _then) return amount;
            amount += vesting.finalAmounts[i];
            _then += vesting.finalPeriods[i];
        }
    }

    function _isWinner(uint256 index, address user) internal view returns (bool winner) {
        Program storage program = _programs[index];
        // Dismiss if draw not happened OR user hasn't even registered
        if (!program.drawn || _userInfos[index][user].tickets == 0) return false;
        // User is considered winner either:
        // A. If user's ticket was chosen during draw
        // B. Or if everyone won because participants count is not higher that winner quota
        bool A = _userInfos[index][user].winner;
        bool B = _participantsOf[index].length() <= program.params.places;
        return A || B;
    }

    /**
     * Most cost-efficient way is to go backwards in "for" and check i
     * at the end of each iteration
     * @param index program index
     * @param userIndex perticipant's index in _participantsOf[index] set
     * @param ticketCount how many tickets user has. (needed to reduce gas costs)
     */
    function _removeTickets(
        uint256 index,
        uint16 userIndex,
        uint256 ticketCount
    ) internal {
        uint16[] storage tickets = _ticketsAt[index];
        for (uint256 i = tickets.length - 1; ticketCount > 0; i--) {
            if (tickets[i] == userIndex) {
                tickets[i] = tickets[tickets.length - 1];
                tickets.pop();
                ticketCount--;
            }
            if (i == 0) break;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITicketsCounter {
    function countTickets(address who, uint256 drawDate)
        external
        view
        returns (
            uint256 tickets,
            ILockableStaking[] memory lockableStakings,
            uint256[] memory lockableAmounts
        );
}

interface IUniswapV2Pair {
    function totalSupply() external view returns (uint256);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

interface IRefTreeStorage {
    function refererOf(address user) external view returns (address);
    function referralsOf(address referer) external view returns (address[] memory);
    function setReferer(address user, address referer) external;
}

interface IStakingLockAgent {
    function exceptionalUnlockPossible(address user, bytes32 payload) external view returns (bool);
}

interface ILockableStaking {
    struct LockInfo {
        uint256 until; // Date until which lock holds
        uint256 amount; // Minimum unwithdrawable amount. (MAX_UINT256 to fully lock)
        IStakingLockAgent agent;
        bytes32 payload;
    }
    function lockByAgent(
        address staker,
        uint256 until,
        uint256 amount,
        bytes32 payload
    ) external;
    function lockInfo(address user) external view returns (LockInfo memory);

    event LockAgentSet(address indexed agent, bool indexed value);
    event LockedByAgent(address indexed agent, address indexed staker, uint256 until, uint256 amount, bytes32 payload);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IStakingLockAgent, ILockableStaking} from './Interfaces.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

abstract contract LockableStaking is Ownable, ILockableStaking {
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet _lockAgents;
    mapping(address => LockInfo) _lockInfo;

    // AGENT OPERATIONS

    function lockByAgent(
        address staker,
        uint256 until,
        uint256 amount,
        bytes32 payload
    ) external override {
        require(_lockAgents.contains(msg.sender), 'LOCK: RESTRICTED');
        _lockInfo[staker] = LockInfo({
            until: until,
            amount: amount,
            agent: IStakingLockAgent(msg.sender),
            payload: payload
        });
        emit LockedByAgent(msg.sender, staker, until, amount, payload);
    }

    // SETTERS

    function setLockAgent(address trustedAgent, bool authorized) external onlyOwner {
        require(_lockAgents.contains(trustedAgent) != authorized);
        if (authorized) _lockAgents.add(trustedAgent);
        else _lockAgents.remove(trustedAgent);
        emit LockAgentSet(trustedAgent, authorized);
    }

    // GETTERS

    function isLockAgent(address who) external view returns (bool) {
        return _lockAgents.contains(who);
    }

    function lockInfo(address user) external view override returns (LockInfo memory) {
        return _lockInfo[user];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IRefTreeStorage} from './Interfaces.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

abstract contract RefProgramBase is Ownable {
    IRefTreeStorage public refTreeStorage;

    constructor(IRefTreeStorage refTreeStorage_) {
        setRefTreeStorage(refTreeStorage_);
    }

    // SETTERS

    function setRefTreeStorage(IRefTreeStorage refTreeStorage_) public onlyOwner {
        refTreeStorage = refTreeStorage_;
    }

    // INTERNAL OPERATIONS

    function _trySetReferer(address user, address referer) internal {
        refTreeStorage.setReferer(user, referer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}