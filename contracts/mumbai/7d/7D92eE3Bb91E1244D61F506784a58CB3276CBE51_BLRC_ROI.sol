// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BLRC_ROI {
    using SafeMath for uint256;

    uint256[] public REFERRAL_PERCENTS = [0, 10, 10, 5, 5, 5, 5, 5, 5, 5];
    uint256[] public TOP_REFERRAL_PERCENTS = [50, 20, 10, 10, 10];
    uint256 public constant PERCENTS_DIVIDER = 1000;

    uint256 public constant TIME_STEP = 1 days;
    uint256 public minInvestment = 0.03 ether;
    uint256 public maxInvestment = 100 ether;
    uint256 public maturityPercentage = 200;
    uint256 public BASE_PERCENT = 100;
    uint256 public percentDivider = 10000;
    uint256 public accumulatRoundID = 1;
    uint256 public nextResultIn = block.timestamp.add(24 hours);
    uint256 public TIME_STEP_FOR_TOP_REFERRER = 24 hours;

    uint256 public TVLROI = 0;
    uint256 public currentRange = 0;
    NftMintInterface public BLRC_NFT;

    uint256 public totalUsers;
    uint256 public totalInvested;
    uint256 public totalWithdrawn;
    uint256 public totalDeposits;

    address payable ownerAddress;
    address payable marketingAddress;
    uint256 public TOP_REFERRAL_BONUS;

    struct Deposit {
        uint256 amount;
        uint256 withdrawn;
        uint256 start;
        uint256 checkpoint;
    }

    struct User {
        Deposit[] deposits;
        uint256 staked;
        address payable referrer;
        uint256 bonus;
        uint256 refEarning;
        uint256 refEarningOnDividend;
        bool isExist;
        uint256 referredUsers;
        mapping(uint256 => uint256) refEarningsLevel;
        mapping(uint256 => uint256) refCount;
        uint256 totalAmount;
        uint256 withdrawn;
        uint256 last_withdrawn;
        uint256 referralInvested;
    }

    struct UserTeams{
    uint256 totalBusiness;
    uint256 totalTeam;
}

    struct EarningInfo{
        uint256 refEarningOnDividend;
        uint256 topRefBonus;
    }

    struct PlayerDailyRounds {
        uint256 referrers; // total referrals user has in a particular rounds
        uint256 totalReferralInsecondNft;
    }

    mapping(address => User) internal users;
    mapping(address => EarningInfo) internal earningInfo;
    mapping(uint256 => mapping(uint256 => address)) public round;
    mapping(address => mapping(uint256 => PlayerDailyRounds)) public plyrRnds_;
    mapping(address => mapping(uint8 => bool)) public isMinted;
    mapping(address=>UserTeams) public userTeams;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RefBonus(
        address indexed referrer,
        address indexed referral,
        uint256 indexed level,
        uint256 amount
    );
    event ReferralDetails(address user, address referrer, uint256 roundId);

    constructor(address payable marketingAddr,address nftAddress) {
        require(!isContract(marketingAddr));
        ownerAddress = marketingAddr;
        users[ownerAddress].referrer = ownerAddress;
        users[ownerAddress].isExist = true;
        BLRC_NFT = NftMintInterface(nftAddress);
    }

    function refPayout(address _user, uint256 _amount, bool isNew) internal {
        User storage user = users[_user];
        if (user.referrer != address(0)) {
            address upline = user.referrer;
            for (uint256 i = 1; i < REFERRAL_PERCENTS.length; i++) {
                if (upline != address(0)) {
                    userTeams[upline].totalBusiness+=_amount;
                    uint256 amount = _amount.mul(REFERRAL_PERCENTS[i]).div(
                        PERCENTS_DIVIDER
                    );
                    users[upline].bonus = users[upline].bonus.add(amount);
                    if (isNew) {
                        users[upline].refCount[i] = users[upline]
                            .refCount[i]
                            .add(1);
                            userTeams[upline].totalTeam++;
                    }
                    users[upline].refEarningsLevel[i] = users[upline]
                        .refEarningsLevel[i]
                        .add(amount);
                    emit RefBonus(upline, _user, i, amount);
                    upline = users[upline].referrer;
                } else break;
            }
        }
    }

    function invest(address payable referrer) public payable {
        require(
            msg.value >= minInvestment && msg.value <= maxInvestment,
            "Invalid amount"
        );
        require(users[referrer].isExist, "Invalid referrer");
        collect(msg.sender);
        uint256 _amount = msg.value;

        User storage user = users[msg.sender];
        users[msg.sender].isExist = true;
        bool isNew;
        if (user.referrer == address(0) && referrer != msg.sender) {
            user.referrer = referrer;
            isNew = true;
        }
        // refPayout(user.referrer, _amount, isNew);
        totalUsers = totalUsers.add(1);
        user.referredUsers++;
        emit Newbie(msg.sender);

        users[user.referrer].referralInvested +=_amount;

        user.deposits.push(
            Deposit(_amount, 0, block.timestamp, block.timestamp)
        );
        user.staked = user.staked.add(_amount);
        totalInvested = totalInvested.add(_amount);
        totalDeposits = totalDeposits.add(1);

        ownerAddress.transfer(_amount.mul(9).div(100));
        marketingAddress.transfer(_amount.mul(3).div(100));

        TOP_REFERRAL_BONUS = TOP_REFERRAL_BONUS.mul(3).div(100);
        if (isNew && user.referrer != address(0)) {
            plyrRnds_[user.referrer][accumulatRoundID].referrers++;
            emit ReferralDetails(msg.sender, user.referrer, accumulatRoundID);
            _highestReferrer(user.referrer);
        }
        sendAccumulatedAmount();
        setTVLPercent();
        emit NewDeposit(msg.sender, _amount);
    }

    function _highestReferrer(address _referrer) private {
        address upline = _referrer;

        if (upline == address(0)) return;

        for (uint8 i = 0; i < 5; i++) {
            if (round[accumulatRoundID][i] == upline) break;

            if (round[accumulatRoundID][i] == address(0)) {
                round[accumulatRoundID][i] = upline;
                break;
            }

            if (
                plyrRnds_[_referrer][accumulatRoundID].referrers >
                plyrRnds_[round[accumulatRoundID][i]][accumulatRoundID]
                    .referrers
            ) {
                for (uint256 j = i + 1; j < 5; j++) {
                    if (round[accumulatRoundID][j] == upline) {
                        for (uint256 k = j; k <= 5; k++) {
                            round[accumulatRoundID][k] = round[
                                accumulatRoundID
                            ][k + 1];
                        }
                        break;
                    }
                }

                for (uint8 l = uint8(5 - 1); l > i; l--) {
                    round[accumulatRoundID][l] = round[accumulatRoundID][l - 1];
                }

                round[accumulatRoundID][i] = upline;

                break;
            }
        }
    }

    function sendAccumulatedAmount() internal {
        if (block.timestamp >= nextResultIn) {
            uint256 distributeAmount = TOP_REFERRAL_BONUS.div(10);
            for (uint256 i = 0; i < 5; i++) {
                if (round[accumulatRoundID][i] != address(0)) {
                    users[round[accumulatRoundID][i]].bonus += distributeAmount.mul(TOP_REFERRAL_PERCENTS[i]).div(100);
                    earningInfo[round[accumulatRoundID][i]].topRefBonus +=  distributeAmount.mul(TOP_REFERRAL_PERCENTS[i]).div(100);
                }
            }
            accumulatRoundID++;
            TOP_REFERRAL_BONUS = TOP_REFERRAL_BONUS.mul(90).div(100);
            nextResultIn = block.timestamp.add(TIME_STEP_FOR_TOP_REFERRER);
        }
    }

    function withdraw() public {
        User storage user = users[msg.sender];
        collect(msg.sender);
        uint256 earnings = user.totalAmount;
        require(earnings > 0, "User has no dividends");
        payable(msg.sender).transfer(earnings);
        user.totalAmount = 0;
        user.withdrawn = user.withdrawn.add(earnings);
        totalWithdrawn = totalWithdrawn.add(earnings);
        user.last_withdrawn = block.timestamp;
        setTVLPercent();
        emit Withdrawn(msg.sender, earnings);
    }

    function claimNft(uint8 _type) external {
        require(_type> 0 && _type<4 ," Invalid nft");
        require(isMinted[msg.sender][_type],"Allready claimed");
        if(checkNftClaimaible(msg.sender,_type)){
        BLRC_NFT.mint(msg.sender,_type,1);
        isMinted[msg.sender][_type] = true;
        }
    }

    function checkNftClaimaible(address user,uint8 _type) public view returns(bool) {
        bool flag = false;
        if(_type==1 && userTeams[user].totalTeam > 10 && users[user].refCount[0]>1)
        {
            flag = true;
        }
        if(_type==2 && userTeams[user].totalTeam > 30 && users[user].refCount[0]>3)
        {
            flag = true;
        }
        if(_type==3 && userTeams[user].totalTeam > 60 && users[user].refCount[0]>6)
        {
            flag = true;
        }
        return flag;
    }

    function setTVLPercent() internal {
        uint256 balance = address(this).balance;
        if(balance/100 ether > currentRange)
        {
            TVLROI += 100;
        }
        else if(balance/100 ether < currentRange){
            TVLROI = 0;
        }
    }

    function getRefRoi(address _user
    ) public view returns (uint256 _per) {
        User storage user = users[_user];
        uint256 refRoiMultiplier = (user.referralInvested.div(user.staked))*25;
        if(refRoiMultiplier>100)
        {
            refRoiMultiplier = 100;
        }
        return refRoiMultiplier;

    }

    function getHoldBonus(address _user) public view returns(uint256 _per){
        User storage user = users[_user];
        uint256 timeMultiplier = (block.timestamp.sub(user.last_withdrawn)).div(TIME_STEP).mul(10);
        if(timeMultiplier>100){
            timeMultiplier = 100;
        }
        return timeMultiplier;
    }

    function getRoiPercentage(
        address _user
    ) public view returns (uint256 _per) {
        uint256 timeMultiplier = getHoldBonus(_user);
        return BASE_PERCENT.add(timeMultiplier).add(TVLROI).add(getRefRoi(_user));
        
    }

    


    function collect(address _user) private {
        User storage user = users[_user];
        uint256 dividends;
        uint256 _per = getRoiPercentage(_user);
        User storage _upline = users[users[msg.sender].referrer];
        EarningInfo storage _uplineE = earningInfo[users[msg.sender].referrer];
        for (uint256 i = 0; i < user.deposits.length; i++) {
            Deposit storage dep = user.deposits[i];
            uint256 profit = dep.amount.mul(maturityPercentage).div(100);
            if (dep.withdrawn < profit) {
                uint256 from = dep.checkpoint > dep.start
                    ? dep.checkpoint
                    : dep.start;
                uint256 to = block.timestamp;

                dividends = (dep.amount.mul(_per).div(percentDivider))
                    .mul(to.sub(from))
                    .div(TIME_STEP);
                if (dep.withdrawn.add(dividends) > profit) {
                    dividends = profit.sub(dep.withdrawn);
                }
                uint256 upShare = dep.amount.mul(5).div(percentDivider);
                _uplineE.refEarningOnDividend = _uplineE.refEarningOnDividend.add(
                    upShare
                );
                _upline.bonus = _upline.bonus.add(upShare);

                uint256 pendingProfit = profit.sub(
                    dep.withdrawn.add(dividends)
                );
                if (user.bonus > pendingProfit) {
                    dividends = dividends.add(pendingProfit);
                    user.bonus = user.bonus.sub(pendingProfit);
                } else {
                    dividends = dividends.add(user.bonus);
                    user.bonus = 0;
                }

                dep.withdrawn = dep.withdrawn.add(dividends); /// changing of storage data
                user.totalAmount = user.totalAmount.add(dividends);
                dep.checkpoint = block.timestamp;
            }
        }
        user.bonus = 0;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getUserDividends(address _user) public view returns (uint256) {
        User storage user = users[_user];
        uint256 dividends;
        uint256 totalAmount = 0;
        uint256 bonus = user.bonus;
        uint256 _per = getRoiPercentage(_user);
        for (uint256 i = 0; i < user.deposits.length; i++) {
            Deposit storage dep = user.deposits[i];
            uint256 profit = dep.amount.mul(maturityPercentage).div(100);
            if (dep.withdrawn < profit) {
                uint256 from = dep.checkpoint > dep.start
                    ? dep.checkpoint
                    : dep.start;
                uint256 to = block.timestamp;

                dividends = (dep.amount.mul(_per).div(percentDivider))
                    .mul(to.sub(from))
                    .div(TIME_STEP);
                if (dep.withdrawn.add(dividends) > profit) {
                    dividends = profit.sub(dep.withdrawn);
                }

                uint256 pendingProfit = profit.sub(
                    dep.withdrawn.add(dividends)
                );
                if (bonus > pendingProfit) {
                    dividends = dividends.add(pendingProfit);
                    bonus = bonus.sub(pendingProfit);
                } else {
                    dividends = dividends.add(user.bonus);
                    bonus = 0;
                }

                totalAmount = totalAmount.add(dividends);
            }
        }
        return totalAmount;
    }

    function getContractInfo() external view returns(uint256 _championBalance,uint256 _nextResultIn) {
        return (TOP_REFERRAL_BONUS,nextResultIn);
    }

    function getUserInfo(
        address userAddress
    )
        external
        view
        returns (
            uint256 invested,
            uint256 withdrawn,
            uint256 refWithdrawable,
            uint256 refEarning,
            address upline,
            uint256 refEarningOnDividend,
            uint256 dividend
        )
    {
        User storage user = users[userAddress];
        return (
            user.staked,
            user.withdrawn,
            user.bonus,
            user.refEarning,
            user.referrer,
            user.refEarningOnDividend,
            getUserDividends(userAddress)
        );
    }

    function getPercentageDetails(address _user) external view returns(uint256 _tvlROI,uint256 _holdBonus,uint256 _directRoi)
    {
        return (TVLROI,getHoldBonus(_user),getRefRoi(_user));
    }

    function getDeposits(
        address _user
    ) external view returns (Deposit[] memory deposits) {
        return users[_user].deposits;
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function getReferralIncome(
        address userAddress
    )
        public
        view
        returns (
            uint256[] memory referrals,
            uint256[] memory referralEarnings,
            uint256[] memory ref_percents
        )
    {
        uint256[] memory _referrals = new uint256[](REFERRAL_PERCENTS.length);
        uint256[] memory _referralearnings = new uint256[](
            REFERRAL_PERCENTS.length
        );

        for (uint256 i = 0; i < REFERRAL_PERCENTS.length; i++) {
            _referrals[i] = users[userAddress].refEarningsLevel[i];
            _referralearnings[i] = users[userAddress].refCount[i];
        }
        return (_referrals, _referralearnings, REFERRAL_PERCENTS);
    }

     function getHighestReferrer(uint256 roundId)
        external
        view
        returns (address[] memory _players, uint256[] memory counts)
    {
        _players = new address[](5);
        counts = new uint256[](5);

        for (uint8 i = 0; i < 5; i++) {
            _players[i] = round[roundId][i];
            counts[i] = plyrRnds_[_players[i]][roundId].referrers;
        }
        return (_players, counts);
    }

    function setAffiliate(uint256 percent, uint level) external {
        require(msg.sender == ownerAddress, "Invalid user");
        REFERRAL_PERCENTS[level - 1] = percent;
    }
}

// contract interface
interface NftMintInterface {
    // function definition of the method we want to interact with
    function mint(address to, uint256 tokenId,uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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