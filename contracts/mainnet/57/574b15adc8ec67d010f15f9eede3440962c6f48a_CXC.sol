/**
 *Submitted for verification at polygonscan.com on 2023-02-04
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/math/SafeMath.sol


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

// File: contracts/CXC.sol


pragma solidity ^0.8.6;


contract CXC {

    using SafeMath for uint256;

    address private cyberMaster;
    address private robotZero;
    uint256 private startTime;
    uint256 private lastDistribute;
    uint256 private totalPlayers;

    address public stakingContract;
    uint256 public stakingPool;

    address public gameContract;
    uint256 public gamePool;

    uint256 public luckPool;
    mapping(uint256=>address[]) private dailyLuckyWinner;
    mapping(uint256=>uint256[]) private dailyLuckyWinnerDeposit;
    mapping(uint256=>address[]) private finalWinners;
    mapping(uint256=>uint256[]) private finalRewards;

    uint256 private constant minDeposit = 20 ether;
    uint256 private constant baseDeposit = 2000 ether;
    uint256 private constant maxDeposit = 2000 ether;
    uint256 private constant minTransfer = 50 ether;

    uint256 private whitelistSupply = 1600;
    uint256 private wlRequirement = 1000 ether;
    mapping(address => bool) public whitelist;

    uint256 private constant timeStep = 1 days;
    uint256 private constant dayPerCycle = 15 days; 
    uint256 private constant maxAddFreeze = 45 days;

    uint256 private constant maxSearchDepth = 3000;
    uint256 private constant referDepth = 15;
    uint256[15] private referralComm = [500, 100, 200, 300, 100, 100, 100, 100, 100, 100, 50, 50, 50, 50, 50];
    uint256[5] private levelDeposit = [20 ether, 500 ether, 1000 ether, 1000 ether, 2000 ether];
    uint256[5] private levelInvite = [0, 0, 0, 10000 ether, 50000 ether];
    uint256[5] private levelTeam = [0, 0, 0, 50, 200];

    uint256[3] private balReached = [100e4 ether, 500e4 ether, 1000e4 ether];
    uint256[3] private balFreezeStatic = [70e4 ether, 300e4 ether, 500e4 ether];
    uint256[3] private balFreezeDynamic = [40e4 ether, 150e4 ether, 200e4 ether];
    uint256[3] private balRecover = [150e4 ether, 500e4 ether, 1000e4 ether];
    mapping(uint256=>bool) private balStatus;
    bool private freezeStaticReward;
    bool private freezeDynamicReward;

    struct UserInfo {
        address referrer;
        uint256 level;
        uint256 maxDeposit;
        uint256 maxDepositable;
        uint256 teamNum;
        uint256 teamTotalDeposit;
        uint256 totalFreezed;
        uint256 extraFreezeDay;
        uint256 totalRevenue;
        uint256 unfreezeIndex;
        bool unfreezedDynamic;
    }

    struct RewardInfo {
        uint256 capitals;
        uint256 statics;
        uint256 invited;
        uint256 level5Freezed;
        uint256 level5Released;
        uint256 luckWin;
        uint256 split;
    }

    struct OrderInfo {
        uint256 amount;
        uint256 start;
        uint256 unfreeze; 
        bool isUnfreezed;
    }

    mapping(address=>UserInfo) private userInfo;
    mapping(address=>RewardInfo) private rewardInfo;
    mapping(address=>OrderInfo[]) private orderInfos;
    mapping(uint256=>uint256) private dayNewbies;
    mapping(uint256=>uint256) private dayDeposit;
    mapping(address=>mapping(uint256=>uint256)) private userCycleMax;
    mapping(address=>mapping(uint256=>address[])) private teamUsers;

    event Register(address user, address referral);
    event Deposit(address user, uint256 amount);
    event DepositBySplit(address user, uint256 amount);
    event TransferBySplit(address user, address receiver, uint256 amount);
    event Withdraw(address user, uint256 withdrawable);
    event DistributePoolRewards(uint256 day, uint256 time);
    event Funds(address from, uint256 amount, uint256 timestamp);

    constructor (
        address _cyberMaster,
        address _robotZero,
        address _stakingContract,
        uint256 _startTime
    ) {
        cyberMaster = _cyberMaster;
        robotZero = _robotZero;
        stakingContract = _stakingContract;
        startTime = _startTime;
        lastDistribute = _startTime;
    }

    function fundCXC() external payable {
        emit Funds(msg.sender, msg.value, block.timestamp);
    }

    function register(address _referral) external {
        require(userInfo[_referral].maxDeposit > 0 || _referral == robotZero, "Referral is invalid.");
        UserInfo storage user = userInfo[msg.sender];
        require(user.referrer == address(0), "This wallet already have a referral.");
        user.referrer = _referral;
        emit Register(msg.sender, _referral);
    }

    function deposit(uint256 _amount, bool _state) external payable {
        require(msg.value == _amount, "Transaction value not match with amount.");
        _deposit(msg.sender, _amount, _state);
        emit Deposit(msg.sender, _amount);
        if (whitelistSupply > 0 && msg.value >= wlRequirement && whitelist[msg.sender] == false) {
            whitelist[msg.sender] = true;
            whitelistSupply--;
        }
    }

    function withdraw() external {
        (uint256 withdrawable, uint256 split) = _calCurRewards(msg.sender);
        RewardInfo storage userRewards = rewardInfo[msg.sender];
        userRewards.statics = 0;
        userRewards.invited = 0;
        userRewards.level5Released = 0;
        userRewards.luckWin = 0;
        userRewards.split += split;
        withdrawable += userRewards.capitals;
        userRewards.capitals = 0;
        (bool withdrawal, ) = payable(msg.sender).call{value: withdrawable}("");
        require(withdrawal, "Withdrawal Error");
        uint256 bal = getBalance();
        _setFreezeReward(bal);
        emit Withdraw(msg.sender, withdrawable);
    }

    function depositBySplit(uint256 _amount) external payable {
        require(userInfo[msg.sender].maxDeposit == 0, "Only new account can deposit from split balance.");
        require(rewardInfo[msg.sender].split >= _amount, "Insufficient split account balance.");
        rewardInfo[msg.sender].split -= _amount;
        _deposit(msg.sender, _amount, false);
        emit DepositBySplit(msg.sender, _amount);
    }

    function transferBySplit(address _receiver, uint256 _amount) external payable {
        require(_amount >= minTransfer, "Amount below minimum deposit.");
        require(_amount.mod(minTransfer) == 0, "Amount must be the increment of 50.");
        require(rewardInfo[msg.sender].split >= _amount, "Insufficient split account balance.");
        rewardInfo[msg.sender].split -= _amount;
        rewardInfo[_receiver].split += _amount;
        emit TransferBySplit(msg.sender, _receiver, _amount);
    }

    function _deposit(address _userAddr, uint256 _amount, bool _isLuckable) private {
        require(block.timestamp >= startTime, "Not launched yet.");
        require(_amount >= minDeposit, "Amount below minimum deposit.");
        require(_amount.mod(minDeposit) == 0, "Amount must be the increment of min deposit.");
        UserInfo storage user = userInfo[_userAddr];
        require(user.referrer != address(0), "This address is not registered.");
        require(_amount <= maxDeposit, "Amount exceeded maximum deposit.");
        require(user.maxDeposit == 0 || _amount >= user.maxDeposit, "Amount cannot be lower than previous deposits.");

        cyberContribution(_amount);

        uint256 curCycle = getCurCycle();
        uint256 userCurMax = userCycleMax[msg.sender][curCycle];
        if (userCurMax == 0) {
            if (curCycle == 0 || user.maxDepositable == 0) {
                userCurMax = baseDeposit;
            } else {
                userCurMax = user.maxDepositable;
            }
            userCycleMax[msg.sender][curCycle] = userCurMax;
        }

        require(_amount <= userCurMax, "Amount exceeded user current maximum deposit.");

        if (_amount == userCurMax) {
            if (userCurMax >= maxDeposit) {
                userCycleMax[msg.sender][curCycle.add(1)] = maxDeposit;
            } else {
                userCycleMax[msg.sender][curCycle.add(1)] = userCurMax.add(baseDeposit);
            }
        } else {
            userCycleMax[msg.sender][curCycle.add(1)] = userCurMax;
        }
        user.maxDepositable = userCycleMax[msg.sender][curCycle.add(1)];

        uint256 dayNow = getCurDay();
        bool isNewbie;
        if (user.maxDeposit == 0) {
            isNewbie = true;
            user.maxDeposit = _amount;
            dayNewbies[dayNow]++;
            totalPlayers++;
            if (_isLuckable && _amount >= minDeposit) {
                dailyLuckyWinner[dayNow].push(_userAddr);
                dailyLuckyWinnerDeposit[dayNow].push(_amount);
            }
        } else if (_amount > user.maxDeposit) {
            user.maxDeposit = _amount;
        }
        user.totalFreezed = user.totalFreezed.add(_amount);
        if (orderInfos[_userAddr].length <= 0) {
            user.extraFreezeDay = 0;
        } else if (orderInfos[_userAddr].length.mod(2) == 0) {
            user.extraFreezeDay++;
        }
        uint256 addFreeze = (user.extraFreezeDay).mul(timeStep);
        if (addFreeze >= maxAddFreeze) {
            addFreeze = maxAddFreeze;
        }
        uint256 unfreezeTime = block.timestamp.add(dayPerCycle).add(addFreeze);
        orderInfos[_userAddr].push(OrderInfo(_amount, block.timestamp, unfreezeTime, false));
        dayDeposit[dayNow] += _amount;
        _unfreezeCapitalOrReward(msg.sender, _amount);
        _updateUplineReward(msg.sender, _amount);
        _updateTeamInfos(msg.sender, _amount, isNewbie);
        _updateLevel(msg.sender);

        uint256 bal = getBalance();
        _balActived(bal);
        if (freezeStaticReward || freezeDynamicReward) {
            _setFreezeReward(bal);
        } else if(user.unfreezedDynamic) {
            user.unfreezedDynamic = false;
        }

    }

    function cyberContribution(uint256 _amount) private {
        uint256 masterComm = _amount.mul(2).div(100);
        (bool contributeCM, ) = payable(cyberMaster).call{value: masterComm}("");
        require(contributeCM, "CyberMaster contribution failed.");
        uint256 gameFunding = _amount.mul(1).div(100);
        gamePool += gameFunding;
        uint256 luckyDrawFunding = _amount.mul(5).div(1000);
        luckPool += luckyDrawFunding;
        uint256 stakingFund = _amount.mul(5).div(1000);
        stakingPool += stakingFund;
    }

    function _calCurRewards(address _userAddr) private view returns(uint256, uint256) {
        RewardInfo storage userRewards = rewardInfo[_userAddr];
        uint256 totalRewards = userRewards.statics.add(userRewards.invited).add(userRewards.level5Released).add(userRewards.luckWin);
        uint256 splitAmt = totalRewards.mul(30).div(100);
        uint256 withdrawable = totalRewards.sub(splitAmt);
        return(withdrawable, splitAmt);
    }

    function _updateLevel(address _userAddr) private {
        UserInfo storage user = userInfo[_userAddr];
        for (uint256 i = user.level; i < levelDeposit.length; i++) {
            if (user.maxDeposit >= levelDeposit[i]) {
                (uint256 maxTeam, uint256 otherTeam, ) = getTeamDeposit(_userAddr);
                if (maxTeam >= levelInvite[i] && otherTeam >= levelInvite[i] && user.teamNum >= levelTeam[i]) {
                    user.level = i + 1;
                }
            }
        }
    }

    function _unfreezeCapitalOrReward(address _userAddr, uint256 _amount) private {
        UserInfo storage user = userInfo[_userAddr];
        RewardInfo storage userRewards = rewardInfo[_userAddr];
        OrderInfo storage order = orderInfos[_userAddr][user.unfreezeIndex];

        if(order.isUnfreezed == false && block.timestamp >= order.unfreeze && _amount >= order.amount){
            order.isUnfreezed = true;
            user.unfreezeIndex++;
            _removeInvalidDeposit(_userAddr, order.amount);
            uint256 staticReward = order.amount.mul(15).mul(dayPerCycle).div(timeStep).div(1000);

            if (freezeStaticReward) {
                if (user.totalFreezed > user.totalRevenue) {
                    uint256 leftCapital = user.totalFreezed.sub(user.totalRevenue);
                    if (staticReward > leftCapital) {
                        staticReward = leftCapital;
                    }
                } else {
                    staticReward = 0;
                }
            }

            userRewards.capitals = userRewards.capitals.add(order.amount);
            userRewards.statics = userRewards.statics.add(staticReward);
            user.totalRevenue = user.totalRevenue.add(staticReward);

        } else if (userRewards.level5Freezed > 0) {
            
            uint256 release = _amount;
            if (_amount >= userRewards.level5Freezed) {
                release = userRewards.level5Freezed;
            }
            userRewards.level5Freezed -= release;
            userRewards.level5Released += release;
            user.totalRevenue += release;

        } else if (freezeStaticReward && !user.unfreezedDynamic) {
            user.unfreezedDynamic = true;
        }
    }

    function _removeInvalidDeposit(address _userAddr, uint256 _amount) private {
        uint256 totalFreezed = userInfo[_userAddr].totalFreezed;
        userInfo[_userAddr].totalFreezed = totalFreezed > _amount ? totalFreezed.sub(_amount) : 0;
        address upline = userInfo[_userAddr].referrer;
        for(uint256 i = 0; i < referDepth; i++){
            if (upline != address(0)) {
                userInfo[upline].teamTotalDeposit = userInfo[upline].teamTotalDeposit > _amount ? userInfo[upline].teamTotalDeposit.sub(_amount) : 0;
                if(upline == robotZero) break;
                upline = userInfo[upline].referrer;
            } else {
                break;
            }
        }
    }

    function _updateTeamInfos(address _userAddr, uint256 _amount, bool _isNewbie) private {
        address upline = userInfo[_userAddr].referrer;
        for (uint256 i = 0; i < referDepth; i++) {
            if (upline != address(0)) {
                if (_isNewbie && _userAddr != upline) {
                    userInfo[upline].teamNum = userInfo[upline].teamNum.add(1);
                    teamUsers[upline][i].push(_userAddr);
                }
                userInfo[upline].teamTotalDeposit = userInfo[upline].teamTotalDeposit.add(_amount);
                if (upline == robotZero) break;
                upline = userInfo[upline].referrer;
            } else {
                break;
            }
        }
    }

    function _updateUplineReward(address _userAddr, uint256 _amount) private {
        address upline = userInfo[_userAddr].referrer;
        for (uint256 i = 0; i < referDepth; i++) {
            if (upline != address(0)) {
                if (!freezeStaticReward || userInfo[upline].totalFreezed > userInfo[upline].totalRevenue || (userInfo[upline].unfreezedDynamic && !freezeDynamicReward)) {
                    uint256 newAmount;
                    if (orderInfos[upline].length > 0) {
                        OrderInfo storage latestUpOrder = orderInfos[upline][orderInfos[upline].length-1];
                        uint256 maxFreezing = latestUpOrder.unfreeze > block.timestamp ? latestUpOrder.amount : 0;
                        if (maxFreezing < _amount) {
                            newAmount = maxFreezing;
                        } else {
                            newAmount = _amount;
                        }
                    }
                    if (newAmount > 0) {
                        RewardInfo storage upRewards = rewardInfo[upline];
                        if (userInfo[upline].level <= 3) {
                            uint256 reward = newAmount.mul(referralComm[i]).div(10000);
                            if (i < 1) {
                                upRewards.invited += reward;
                                userInfo[upline].totalRevenue += reward;
                            }
                        } else if (userInfo[upline].level >= i || userInfo[upline].level == 5) {
                            uint256 reward = newAmount.mul(referralComm[i]).div(10000);
                            if (i < 5) {
                                upRewards.invited += reward;
                                userInfo[upline].totalRevenue += reward;
                            } else {
                                upRewards.level5Freezed += reward;
                            }
                        }
                    }

                }
                if (upline == robotZero) break;
                upline = userInfo[upline].referrer;
            } else {
                break;
            }
        }
    }

    function _balActived(uint256 _bal) private {
        for(uint256 i = balReached.length; i > 0; i--){
            if(_bal >= balReached[i - 1]){
                balStatus[balReached[i - 1]] = true;
                break;
            }
        }
    }

    function _setFreezeReward(uint256 _bal) private {
        for (uint256 i = balReached.length; i > 0; i--) {
            if (balStatus[balReached[i - 1]]) {
                if (_bal < balFreezeStatic[i - 1]) {
                    freezeStaticReward = true;
                    if (_bal < balFreezeDynamic[i - 1]) {
                        freezeDynamicReward = true;
                    }
                } else {
                    if ((freezeStaticReward || freezeDynamicReward) && _bal >= balRecover[i - 1]) {
                        freezeStaticReward = false;
                        freezeDynamicReward = false;
                    }
                }
                break;
            }
        }
    }

    function distributePoolRewards() external {
        if (block.timestamp >= lastDistribute.add(timeStep)) {
            uint256 dayNow = getCurDay();
            distributeLuckPool(dayNow-1);
            fundStakingContract();
            if (gameContract != address(0)) {
                fundGameContract();
            }
            lastDistribute = startTime.add(dayNow.mul(timeStep));
            emit DistributePoolRewards(dayNow, lastDistribute);
        }
    }

    function distributeLuckPool(uint256 _lastDay) private {
        uint256 luckTotalDeposits;
        uint256 depositCount = 1;
        for(uint256 i = dailyLuckyWinner[_lastDay].length; i > 0; i--) {
            luckTotalDeposits = luckTotalDeposits.add(dailyLuckyWinnerDeposit[_lastDay][i-1]);
            depositCount++;
            if (depositCount == 10) {
                break;
            }
        }
        uint256 totalReward;
        uint256 maxShare = luckPool.div(10);
        uint256 maxRatio = luckPool.div(luckTotalDeposits).add(1);
        if (maxRatio > 3) {
            maxRatio = 3;
        }
        for(uint256 i = dailyLuckyWinner[_lastDay].length; i > 0; i--) {
            uint256 reward = (dailyLuckyWinnerDeposit[_lastDay][i-1]).mul(maxRatio);
            if (reward >= maxShare) {
                reward = maxShare;
            }
            totalReward = totalReward.add(reward);
            rewardInfo[dailyLuckyWinner[_lastDay][i-1]].luckWin = rewardInfo[dailyLuckyWinner[_lastDay][i-1]].luckWin.add(reward);
            userInfo[dailyLuckyWinner[_lastDay][i-1]].totalRevenue = userInfo[dailyLuckyWinner[_lastDay][i-1]].totalRevenue.add(reward);
            finalWinners[_lastDay].push(dailyLuckyWinner[_lastDay][i-1]);
            finalRewards[_lastDay].push(reward);
            luckPool = luckPool.sub(reward);
            if (finalWinners[_lastDay].length == 10) {
                break;
            }
        }
    }

    function getFinalWinners(uint256 _day) external view returns(address[] memory, uint256[] memory) {
        return (finalWinners[_day], finalRewards[_day]);
    }

    function getLuckyData(uint256 _day) external view returns(address[] memory, uint256[] memory) {
        return(dailyLuckyWinner[_day], dailyLuckyWinnerDeposit[_day]);
    }

    function fundStakingContract() private {
        require(stakingPool > 0, "No balance in NFT pool.");
        (bool transferNFTFund, ) = payable(stakingContract).call{value: stakingPool}("");
        require(transferNFTFund, "Transfer funds to NFT contract failed.");
        stakingPool = 0;
    }

    function setGameContract(address gameContractAddress) external {
        require(msg.sender == robotZero, "Only Robot Zero.");
        gameContract = gameContractAddress;
    }

    function fundGameContract() private {
        require(gamePool > 0, "No balance in Game pool.");
        (bool transferGameFund, ) = payable(gameContract).call{value: gamePool}("");
        require(transferGameFund, "Transfer funds to game contract failed.");
        gamePool = 0;
    }

    function getTeamDeposit(address _userAddr) public view returns(uint256, uint256, uint256) {
        uint256 totalTeam;
        uint256 maxTeam;
        uint256 otherTeam;
        for(uint256 i = 0; i < teamUsers[_userAddr][0].length; i++){
            uint256 userTotalTeam = userInfo[teamUsers[_userAddr][0][i]].teamTotalDeposit.add(userInfo[teamUsers[_userAddr][0][i]].totalFreezed);
            totalTeam = totalTeam.add(userTotalTeam);
            if (userTotalTeam > maxTeam) {
                maxTeam = userTotalTeam;
            }
            if (i >= maxSearchDepth) break;
        }
        otherTeam = totalTeam.sub(maxTeam);
        return(maxTeam, otherTeam, totalTeam);
    }

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function getUserLevel(address wallet) public view returns(uint256) {
        return userInfo[wallet].level;
    }

    function checkWL(address wallet) public view returns(bool) {
        return whitelist[wallet];
    }

    function getNFTSupply() public view returns(uint256) {
        return whitelistSupply;
    }

    function getCurDay() public view returns(uint256) {
        return (block.timestamp.sub(startTime)).div(timeStep);
    }

    function getCurCycle() public view returns(uint256) {
        uint256 curCycle = (block.timestamp.sub(startTime)).div(dayPerCycle);
        return curCycle;
    }

    function getDayInfos(uint256 _day) external view returns(uint256, uint256) {
        return (dayNewbies[_day], dayDeposit[_day]);
    }

    function getUserInfos(address _userAddr) external view returns(UserInfo memory, RewardInfo memory, OrderInfo[] memory) {
        return (userInfo[_userAddr], rewardInfo[_userAddr], orderInfos[_userAddr]);
    }

    function getBalanceData(uint256 _bal) external view returns(bool, bool, bool) {
        return(balStatus[_bal], freezeStaticReward, freezeDynamicReward);
    }

    function getTeamUsers(address _userAddr, uint256 _layer) external view returns(address[] memory) {
        return teamUsers[_userAddr][_layer];
    }

    function getUserCycleMax(address _userAddr, uint256 _cycle) external view returns(uint256) {
        return userCycleMax[_userAddr][_cycle];
    }

    function getContractInfos() external view returns(address[4] memory, uint256[7] memory) {
        address[4] memory infos0;
        infos0[0] = cyberMaster;
        infos0[1] = robotZero;
        infos0[2] = stakingContract;
        infos0[3] = gameContract;

        uint256[7] memory infos1;
        infos1[0] = startTime;
        infos1[1] = lastDistribute;
        infos1[2] = totalPlayers;
        infos1[3] = luckPool;
        infos1[4] = gamePool;
        infos1[5] = stakingPool;
        uint256 dayNow = getCurDay();
        infos1[6] = dayDeposit[dayNow];
        return (infos0, infos1);
    }

}