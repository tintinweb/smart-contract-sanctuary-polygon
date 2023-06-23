/**
 *Submitted for verification at polygonscan.com on 2023-06-23
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// File: contracts/CXXX.sol


pragma solidity ^0.8.6;



contract CXXX is Ownable {

    using SafeMath for uint256;

    address private systemWallet;
    address private defaultReferral;
    uint256 private startTime;
    uint256 private totalPlayers;

    address public nftContract;
    uint256 public nftPool;

    address public gameContract;
    uint256 public gamePool;

    address public charityContract;
    uint256 public charityPool;

    uint256 private constant minDeposit = 20 ether;
    uint256 private constant baseDeposit = 2000 ether;
    uint256 private constant maxDeposit = 2000 ether;
    uint256 private constant minTransfer = 50 ether;
    mapping(address => bool) public withdrawalLock;

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

    constructor (
        address _systemWallet,
        address _defaultReferral,
        uint256 _startTime
    ) {
        systemWallet = _systemWallet;
        defaultReferral = _defaultReferral;
        startTime = _startTime;
    }

    function register(address _referral) external {
        require(userInfo[_referral].maxDeposit > 0 || _referral == defaultReferral, "Invalid referral");
        UserInfo storage user = userInfo[msg.sender];
        require(user.referrer == address(0), "This wallet already have a referral.");
        user.referrer = _referral;
        emit Register(msg.sender, _referral);
    }

    function deposit(uint256 _amount) external payable {
        require(msg.value == _amount, "Transaction value not match with amount.");
        _deposit(msg.sender, _amount);
        emit Deposit(msg.sender, _amount);
        if (msg.value >= wlRequirement && whitelist[msg.sender] == false) {
            whitelist[msg.sender] = true;
        }
    }

    function withdraw() external {
        require(withdrawalLock[msg.sender] == false, "Withdrawal is locked for this wallet.");
        (uint256 withdrawable, uint256 split) = _calCurRewards(msg.sender);
        RewardInfo storage userRewards = rewardInfo[msg.sender];
        userRewards.statics = 0;
        userRewards.invited = 0;
        userRewards.level5Released = 0;
        userRewards.split += split;
        withdrawable += userRewards.capitals;
        userRewards.capitals = 0;
        (bool userWithdraw, ) = payable(msg.sender).call{value: withdrawable}("");
        require(userWithdraw, "Withdrawal Error");
        emit Withdraw(msg.sender, withdrawable);
    }

    function depositBySplit(uint256 _amount) external payable {
        require(userInfo[msg.sender].maxDeposit == 0, "Only new account can deposit from split balance.");
        require(rewardInfo[msg.sender].split >= _amount, "Insufficient split account balance.");
        rewardInfo[msg.sender].split -= _amount;
        _deposit(msg.sender, _amount);
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

    function _deposit(address _userAddr, uint256 _amount) private {
        require(_amount >= minDeposit, "Amount below minimum deposit.");
        require(_amount.mod(minDeposit) == 0, "Amount must be the increment of min deposit.");
        UserInfo storage user = userInfo[_userAddr];
        require(user.referrer != address(0), "This address is not registered.");
        require(_amount <= maxDeposit, "Amount exceeded maximum deposit.");
        require(user.maxDeposit == 0 || _amount >= user.maxDeposit, "Amount cannot be lower than previous deposits.");

        distributeShare(_amount);

        uint256 curCycle = getCurCycle();
        uint256 userCurMax = userCycleMax[_userAddr][curCycle];
        if (userCurMax == 0) {
            if (curCycle == 0 || user.maxDepositable == 0) {
                userCurMax = baseDeposit;
            } else {
                userCurMax = user.maxDepositable;
            }
            userCycleMax[_userAddr][curCycle] = userCurMax;
        }

        require(_amount <= userCurMax, "Amount exceeded user current maximum deposit.");

        if (_amount == userCurMax) {
            if (userCurMax >= maxDeposit) {
                userCycleMax[_userAddr][curCycle.add(1)] = maxDeposit;
            } else {
                userCycleMax[_userAddr][curCycle.add(1)] = userCurMax.add(baseDeposit);
            }
        } else {
            userCycleMax[_userAddr][curCycle.add(1)] = userCurMax;
        }
        user.maxDepositable = userCycleMax[_userAddr][curCycle.add(1)];

        uint256 dayNow = getCurDay();
        bool isNewbie;
        if (user.maxDeposit == 0) {
            isNewbie = true;
            user.maxDeposit = _amount;
            dayNewbies[dayNow]++;
            totalPlayers++;
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
        _unfreezeCapitalOrReward(_userAddr, _amount);
        _updateUplineReward(_userAddr, _amount);
        _updateTeamInfos(_userAddr, _amount, isNewbie);
        _updateLevel(_userAddr);

    }

    function distributeShare(uint256 _amount) private {
        uint256 masterComm = _amount.mul(2).div(100);
        (bool contributeCM, ) = payable(systemWallet).call{value: masterComm}("");
        require(contributeCM, "System fee failure.");
        uint256 gameFunding = _amount.mul(15).div(1000);
        gamePool += gameFunding;
        uint256 nftFund = _amount.mul(5).div(1000);
        nftPool += nftFund;
        uint256 charityFund = _amount.mul(20).div(100);
        charityPool += charityFund;
    }

    function _calCurRewards(address _userAddr) private view returns(uint256, uint256) {
        RewardInfo storage userRewards = rewardInfo[_userAddr];
        uint256 totalRewards = userRewards.statics.add(userRewards.invited).add(userRewards.level5Released);
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

        } else if (!user.unfreezedDynamic) {
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
                if(upline == defaultReferral) break;
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
                if (upline == defaultReferral) break;
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
                if (userInfo[upline].totalFreezed > userInfo[upline].totalRevenue) {
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
                if (upline == defaultReferral) break;
                upline = userInfo[upline].referrer;
            } else {
                break;
            }
        }
    }

    function setNFTContract(address nftContractAddress) external onlyOwner {
        nftContract = nftContractAddress;
    }

    function fundNFTContract(uint256 amount) external onlyOwner {
        require(nftPool >= amount);
        (bool transferNFTFund, ) = payable(nftContract).call{value: amount}("");
        require(transferNFTFund, "Transfer funds to NFT contract failed.");
        nftPool -= amount;
    }

    function setGameContract(address gameContractAddress) external onlyOwner {
        gameContract = gameContractAddress;
    }

    function fundGameContract(uint256 amount) external onlyOwner {
        require(gamePool >= amount);
        (bool transferGameFund, ) = payable(gameContract).call{value: amount}("");
        require(transferGameFund, "Transfer funds to game contract failed.");
        gamePool -= amount;
    }

    function setCharityContract(address charityContractAddress) external onlyOwner {
        charityContract = charityContractAddress;
    }

    function fundCharityContract(uint256 amount) external onlyOwner {
        (bool transferCharityFund, ) = payable(charityContract).call{value: amount}("");
        require(transferCharityFund, "Transfer funds to charity contract failed.");
        charityPool -= amount;
    }

    function withdraw(uint256 amount) external onlyOwner {
        (bool fundWithdrawal, ) = payable(charityContract).call{value: amount}("");
        require(fundWithdrawal, "Withdrawal transaction failed.");
    }

    function lockWithdrawal(address wallet) external onlyOwner {
        withdrawalLock[wallet] = true;
    }

    function unlockWithdrawal(address wallet) external onlyOwner {
        withdrawalLock[wallet] = false;
    }

    function setUpline(address wallet, address newUpline) external onlyOwner {
        UserInfo storage user = userInfo[wallet];
        user.referrer = newUpline;
    }

    function updateLvl(address wallet, uint256 lvl) external onlyOwner {
        UserInfo storage user = userInfo[wallet];
        user.level = lvl;
    }

    function depositSplit(address wallet, uint256 amount) external onlyOwner {
        _deposit(wallet, amount);
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

    function getTeamUsers(address _userAddr, uint256 _layer) external view returns(address[] memory) {
        return teamUsers[_userAddr][_layer];
    }

    function getUserCycleMax(address _userAddr, uint256 _cycle) external view returns(uint256) {
        return userCycleMax[_userAddr][_cycle];
    }

    function checkWL(address wallet) public view returns(bool) {
        return whitelist[wallet];
    }

    function getContractInfos() external view returns(address[4] memory, uint256[5] memory) {
        address[4] memory infos0;
        infos0[0] = systemWallet;
        infos0[1] = defaultReferral;
        infos0[2] = nftContract;
        infos0[3] = gameContract;

        uint256[5] memory infos1;
        infos1[0] = startTime;
        infos1[1] = totalPlayers;
        infos1[2] = gamePool;
        infos1[3] = nftPool;
        uint256 dayNow = getCurDay();
        infos1[4] = dayDeposit[dayNow];
        return (infos0, infos1);
    }

}