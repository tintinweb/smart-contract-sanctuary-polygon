// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract EarningCycle is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // address usdt = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;  //polygon
    address usdt = 0x029db60Fc3A780cA5D0B442115294c48279bE481;  //mumbai
    address public uplineAddr = 0x2F355033769f78645211B03a48773FCA20611985;
    address public distributeAddr = 0xd343e90b6190449AaBC8cDB855FCd879C85b2Cc7;
    address public devAddr = 0xafFc877EfC4Ea4E1908a43c390704F0065d0A963;

    uint256 public uplineRate = 1000;
    uint256 public distributeRate = 8800;
    uint256 public devRate = 200;

    struct Amount {
        uint256 depositAmt;
        uint256 upgradeAmt2;
        uint256 upgradeAmt3;
        uint256 upgradeAmt4;
        uint256 upgradeAmt5;
    }

    struct BonusRate {
        uint256 depositBonusRate;
        uint256 upgradeBonusRate2;
        uint256 upgradeBonusRate3;
        uint256 upgradeBonusRate4;
        uint256 upgradeBonusRate5;
    }

    struct WithdrawnNum {
        uint256 level1WithdrawnNum;
        uint256 level2WithdrawnNum;
        uint256 level3WithdrawnNum;
        uint256 level4WithdrawnNum;
        uint256 level5WithdrawnNum;
    }

    struct LevelStatus {
        bool deposited;
        bool upgraded2;
        bool upgraded3;
        bool upgraded4;
        bool upgraded5;
    }

    struct User {
        uint256 deposits;
        uint256 reward;
        uint256 lastTime;
        address referrer;
        uint256 referrerDeposits;
        uint256 bonus;
        WithdrawnNum withdrawnNum;
        LevelStatus levelStatus;
    }

    struct TotalInfo {
        uint256 totalDownlinks;
        uint256 totalUsers;
        uint256 totalDeposits;
        uint256 totalReferEarnings;
        uint256 totalWithdraws;
        uint256 totalDepositNum;
        uint256 totalUpgrade2Num;
        uint256 totalUpgrade3Num;
        uint256 totalUpgrade4Num;
        uint256 totalUpgrade5Num;
    }

    mapping (address => User) public users;

    Amount public amount;
    BonusRate public bonusRate;
    TotalInfo public totalInfo;

    address[] public depositAddrs;
    address[] public withdrawAddrs;

    bool public init;

    /// @dev Events of each function
    event fundDeposited(address _user, address _refAddr, uint256 _refBonus);
    event fundUpgraded2(address _user, address _refAddr, uint256 _refBonus);
    event fundUpgraded3(address _user, address _refAddr, uint256 _refBonus);
    event fundUpgraded4(address _user, address _refAddr, uint256 _refBonus);
    event fundUpgraded5(address _user, address _refAddr, uint256 _refBonus);

    event level5Withdrawn(address _user, uint256 _reward);
    event level4Withdrawn(address _user, uint256 _reward);
    event level3Withdrawn(address _user, uint256 _reward);
    event level2Withdrawn(address _user, uint256 _reward);
    event level1Withdrawn(address _user, uint256 _reward);

    event started(bool _init);

    constructor() {
        amount.depositAmt = 20 * 1e6;
        amount.upgradeAmt2 = 50 * 1e6;
        amount.upgradeAmt3 = 100 * 1e6;
        amount.upgradeAmt4 = 200 * 1e6;
        amount.upgradeAmt5 = 400 * 1e6;

        bonusRate.depositBonusRate = 500;
        bonusRate.upgradeBonusRate2 = 175;
        bonusRate.upgradeBonusRate3 = 150;
        bonusRate.upgradeBonusRate4 = 125;
        bonusRate.upgradeBonusRate5 = 50;
    }

    /**
     * deposit
     * @dev deposit usdt fund with referral address
     **/
    function deposit(address refAddr) public nonReentrant {
        require(init, "Err: Not started yet");
        require(!users[msg.sender].levelStatus.deposited, "You've already deposited");

        uint256 realUplineRate = uplineRate.sub(bonusRate.depositBonusRate);
        IERC20(usdt).transferFrom(address(msg.sender), uplineAddr, amount.depositAmt.mul(realUplineRate).div(10000));
        IERC20(usdt).transferFrom(address(msg.sender), distributeAddr, amount.depositAmt.mul(distributeRate).div(10000));
        IERC20(usdt).transferFrom(address(msg.sender), devAddr, amount.depositAmt.mul(devRate).div(10000));

        users[msg.sender].deposits = users[msg.sender].deposits.add(amount.depositAmt);
        users[msg.sender].lastTime = block.timestamp;
        users[msg.sender].levelStatus.deposited = true;

        if (refAddr != address(0) && refAddr != msg.sender) {
            users[msg.sender].referrer = refAddr;
            totalInfo.totalDownlinks = totalInfo.totalDownlinks.add(1);
        } else {
            users[msg.sender].referrer = devAddr;
        }
    
        uint256 referralBonus = amount.depositAmt.mul(bonusRate.depositBonusRate).div(10000);
        IERC20(usdt).transferFrom(address(msg.sender), users[msg.sender].referrer, referralBonus);
        users[users[msg.sender].referrer].bonus = users[users[msg.sender].referrer].bonus.add(referralBonus);
        users[users[msg.sender].referrer].referrerDeposits = users[users[msg.sender].referrer].referrerDeposits.add(amount.depositAmt);

        totalInfo.totalUsers = totalInfo.totalUsers.add(1);
        totalInfo.totalDeposits = totalInfo.totalDeposits.add(amount.depositAmt);
        totalInfo.totalReferEarnings = totalInfo.totalReferEarnings.add(referralBonus);
        totalInfo.totalDepositNum = totalInfo.totalDepositNum.add(1);

        depositAddrs.push(msg.sender);
        emit fundDeposited(msg.sender, users[msg.sender].referrer, referralBonus);
    }

    /**
     * upgrade
     * @dev upgrade level from 2 to 5
     **/
    function upgrade() public nonReentrant {
        require(init, "Err: Not started yet");
        require(users[msg.sender].levelStatus.deposited, "You've not deposited yet");
        require(!users[msg.sender].levelStatus.upgraded5, "All levels have been updated");

        if (!users[msg.sender].levelStatus.upgraded2) {
            upgrade2();
        } else if (!users[msg.sender].levelStatus.upgraded3) {
            upgrade3();
        } else if (!users[msg.sender].levelStatus.upgraded4) {
            upgrade4();
        } else if (!users[msg.sender].levelStatus.upgraded5) {
            upgrade5();
        }
    }

    function upgrade2() private {
        require(users[msg.sender].withdrawnNum.level1WithdrawnNum >= 1, "You're not able to upgrade to level2");

        uint256 realUplineRate = uplineRate.sub(bonusRate.upgradeBonusRate2);
        IERC20(usdt).transferFrom(address(msg.sender), uplineAddr, amount.upgradeAmt2.mul(realUplineRate).div(10000));
        IERC20(usdt).transferFrom(address(msg.sender), distributeAddr, amount.upgradeAmt2.mul(distributeRate).div(10000));
        IERC20(usdt).transferFrom(address(msg.sender), devAddr, amount.upgradeAmt2.mul(devRate).div(10000));

        users[msg.sender].deposits = users[msg.sender].deposits.add(amount.upgradeAmt2);
        users[msg.sender].lastTime = block.timestamp;
        users[msg.sender].levelStatus.upgraded2 = true;

        uint256 referralBonus = amount.upgradeAmt2.mul(bonusRate.upgradeBonusRate2).div(10000);
        IERC20(usdt).transferFrom(address(msg.sender), users[msg.sender].referrer, referralBonus);
        users[users[msg.sender].referrer].bonus = users[users[msg.sender].referrer].bonus.add(referralBonus);
        users[users[msg.sender].referrer].referrerDeposits = users[users[msg.sender].referrer].referrerDeposits.add(amount.upgradeAmt2);

        totalInfo.totalDeposits = totalInfo.totalDeposits.add(amount.upgradeAmt2);
        totalInfo.totalReferEarnings = totalInfo.totalReferEarnings.add(referralBonus);
        totalInfo.totalUpgrade2Num = totalInfo.totalUpgrade2Num.add(1);

        depositAddrs.push(msg.sender);
        emit fundUpgraded2(msg.sender, users[msg.sender].referrer, referralBonus);
    }

    function upgrade3() private {
        require(users[msg.sender].withdrawnNum.level2WithdrawnNum >= 2, "You're not able to upgrade to level3");

        uint256 realUplineRate = uplineRate.sub(bonusRate.upgradeBonusRate3);
        IERC20(usdt).transferFrom(address(msg.sender), uplineAddr, amount.upgradeAmt3.mul(realUplineRate).div(10000));
        IERC20(usdt).transferFrom(address(msg.sender), distributeAddr, amount.upgradeAmt3.mul(distributeRate).div(10000));
        IERC20(usdt).transferFrom(address(msg.sender), devAddr, amount.upgradeAmt3.mul(devRate).div(10000));

        users[msg.sender].deposits = users[msg.sender].deposits.add(amount.upgradeAmt3);
        users[msg.sender].lastTime = block.timestamp;
        users[msg.sender].levelStatus.upgraded3 = true;

        uint256 referralBonus = amount.upgradeAmt3.mul(bonusRate.upgradeBonusRate3).div(10000);
        IERC20(usdt).transferFrom(address(msg.sender), users[msg.sender].referrer, referralBonus);
        users[users[msg.sender].referrer].bonus = users[users[msg.sender].referrer].bonus.add(referralBonus);
        users[users[msg.sender].referrer].referrerDeposits = users[users[msg.sender].referrer].referrerDeposits.add(amount.upgradeAmt3);

        totalInfo.totalDeposits = totalInfo.totalDeposits.add(amount.upgradeAmt3);
        totalInfo.totalReferEarnings = totalInfo.totalReferEarnings.add(referralBonus);
        totalInfo.totalUpgrade3Num = totalInfo.totalUpgrade3Num.add(1);
        
        depositAddrs.push(msg.sender);
        emit fundUpgraded3(msg.sender, users[msg.sender].referrer, referralBonus);
    }

    function upgrade4() private {
        require(users[msg.sender].withdrawnNum.level3WithdrawnNum >= 4, "You're not able to upgrade to level4");

        uint256 realUplineRate = uplineRate.sub(bonusRate.upgradeBonusRate4);
        IERC20(usdt).transferFrom(address(msg.sender), uplineAddr, amount.upgradeAmt4.mul(realUplineRate).div(10000));
        IERC20(usdt).transferFrom(address(msg.sender), distributeAddr, amount.upgradeAmt4.mul(distributeRate).div(10000));
        IERC20(usdt).transferFrom(address(msg.sender), devAddr, amount.upgradeAmt4.mul(devRate).div(10000));

        users[msg.sender].deposits = users[msg.sender].deposits.add(amount.upgradeAmt4);
        users[msg.sender].lastTime = block.timestamp;
        users[msg.sender].levelStatus.upgraded4 = true;

        uint256 referralBonus = amount.upgradeAmt4.mul(bonusRate.upgradeBonusRate4).div(10000);
        IERC20(usdt).transferFrom(address(msg.sender), users[msg.sender].referrer, referralBonus);
        users[users[msg.sender].referrer].bonus = users[users[msg.sender].referrer].bonus.add(referralBonus);
        users[users[msg.sender].referrer].referrerDeposits = users[users[msg.sender].referrer].referrerDeposits.add(amount.upgradeAmt4);

        totalInfo.totalDeposits = totalInfo.totalDeposits.add(amount.upgradeAmt4);
        totalInfo.totalReferEarnings = totalInfo.totalReferEarnings.add(referralBonus);
        totalInfo.totalUpgrade4Num = totalInfo.totalUpgrade4Num.add(1);

        depositAddrs.push(msg.sender);
        emit fundUpgraded4(msg.sender, users[msg.sender].referrer, referralBonus);
    }

    function upgrade5() private {
        require(users[msg.sender].withdrawnNum.level4WithdrawnNum >= 8, "You're not able to upgrade to level5");

        uint256 realUplineRate = uplineRate.sub(bonusRate.upgradeBonusRate5);
        IERC20(usdt).transferFrom(address(msg.sender), uplineAddr, amount.upgradeAmt5.mul(realUplineRate).div(10000));
        IERC20(usdt).transferFrom(address(msg.sender), distributeAddr, amount.upgradeAmt5.mul(distributeRate).div(10000));
        IERC20(usdt).transferFrom(address(msg.sender), devAddr, amount.upgradeAmt5.mul(devRate).div(10000));

        users[msg.sender].deposits = users[msg.sender].deposits.add(amount.upgradeAmt5);
        users[msg.sender].lastTime = block.timestamp;
        users[msg.sender].levelStatus.upgraded5 = true;

        uint256 referralBonus = amount.upgradeAmt5.mul(bonusRate.upgradeBonusRate5).div(10000);
        IERC20(usdt).transferFrom(address(msg.sender), users[msg.sender].referrer, referralBonus);
        users[users[msg.sender].referrer].bonus = users[users[msg.sender].referrer].bonus.add(referralBonus);
        users[users[msg.sender].referrer].referrerDeposits = users[users[msg.sender].referrer].referrerDeposits.add(amount.upgradeAmt5);

        totalInfo.totalDeposits = totalInfo.totalDeposits.add(amount.upgradeAmt5);
        totalInfo.totalReferEarnings = totalInfo.totalReferEarnings.add(referralBonus);
        totalInfo.totalUpgrade5Num = totalInfo.totalUpgrade5Num.add(1);
        
        depositAddrs.push(msg.sender);
        emit fundUpgraded5(msg.sender, users[msg.sender].referrer, referralBonus);
    }


    /**
     * withdraw
     * @dev withdraw usdt as reward
     **/
    function withdraw() public nonReentrant {
        checkState();

        if (users[msg.sender].levelStatus.upgraded5) {
            level5Withdraw();
        } else if (users[msg.sender].levelStatus.upgraded4) {
            level4Withdraw();
        } else if (users[msg.sender].levelStatus.upgraded3) {
            level3Withdraw();
        } else if (users[msg.sender].levelStatus.upgraded2) {
            level2Withdraw();
        } else if (users[msg.sender].levelStatus.deposited) {
            level1Withdraw();
        }
    }

    function level5Withdraw() private {
        uint256 quantity = getRewardsSinceLastWithdraw(msg.sender, amount.upgradeAmt5);
        require(quantity > 0, "Err: zero amount");
        require(quantity < IERC20(usdt).balanceOf(distributeAddr), "Err: shouldn't greater than distribution wallet balance");

        users[msg.sender].reward = users[msg.sender].reward.add(quantity);
        IERC20(usdt).transferFrom(distributeAddr, msg.sender, quantity);
        users[msg.sender].lastTime = block.timestamp;
        users[msg.sender].withdrawnNum.level5WithdrawnNum = users[msg.sender].withdrawnNum.level5WithdrawnNum.add(1);

        totalInfo.totalWithdraws = totalInfo.totalWithdraws.add(quantity);
        withdrawAddrs.push(msg.sender);
        emit level5Withdrawn(msg.sender, quantity);
    }

    function level4Withdraw() private {
        uint256 quantity = getRewardsSinceLastWithdraw(msg.sender, amount.upgradeAmt4);
        require(quantity > 0, "Err: zero amount");
        require(quantity < IERC20(usdt).balanceOf(distributeAddr), "Err: shouldn't greater than distribution wallet balance");
        
        users[msg.sender].reward = users[msg.sender].reward.add(quantity);
        IERC20(usdt).transferFrom(distributeAddr, msg.sender, quantity);
        users[msg.sender].lastTime = block.timestamp;
        users[msg.sender].withdrawnNum.level4WithdrawnNum = users[msg.sender].withdrawnNum.level4WithdrawnNum.add(1);
        
        totalInfo.totalWithdraws = totalInfo.totalWithdraws.add(quantity);
        withdrawAddrs.push(msg.sender);
        emit level4Withdrawn(msg.sender, quantity);
    }

    function level3Withdraw() private {
        uint256 quantity = getRewardsSinceLastWithdraw(msg.sender, amount.upgradeAmt3);
        require(quantity > 0, "Err: zero amount");
        require(quantity < IERC20(usdt).balanceOf(distributeAddr), "Err: shouldn't greater than distribution wallet balance");
        
        users[msg.sender].reward = users[msg.sender].reward.add(quantity);
        IERC20(usdt).transferFrom(distributeAddr, msg.sender, quantity);
        users[msg.sender].lastTime = block.timestamp;
        users[msg.sender].withdrawnNum.level3WithdrawnNum = users[msg.sender].withdrawnNum.level3WithdrawnNum.add(1);
        
        totalInfo.totalWithdraws = totalInfo.totalWithdraws.add(quantity);
        withdrawAddrs.push(msg.sender);
        emit level3Withdrawn(msg.sender, quantity);
    }

    function level2Withdraw() private {
        uint256 quantity = getRewardsSinceLastWithdraw(msg.sender, amount.upgradeAmt2);
        require(quantity > 0, "Err: zero amount");
        require(quantity < IERC20(usdt).balanceOf(distributeAddr), "Err: shouldn't greater than distribution wallet balance");
        
        users[msg.sender].reward = users[msg.sender].reward.add(quantity);
        IERC20(usdt).transferFrom(distributeAddr, msg.sender, quantity);
        users[msg.sender].lastTime = block.timestamp;
        users[msg.sender].withdrawnNum.level2WithdrawnNum = users[msg.sender].withdrawnNum.level2WithdrawnNum.add(1);
        
        totalInfo.totalWithdraws = totalInfo.totalWithdraws.add(quantity);
        withdrawAddrs.push(msg.sender);
        emit level2Withdrawn(msg.sender, quantity);
    }
    
    function level1Withdraw() private {
        uint256 quantity = getRewardsSinceLastWithdraw(msg.sender, amount.depositAmt);
        require(quantity > 0, "Err: zero amount");
        require(quantity < IERC20(usdt).balanceOf(distributeAddr), "Err: shouldn't greater than distribution wallet balance");
        
        users[msg.sender].reward = users[msg.sender].reward.add(quantity);
        IERC20(usdt).transferFrom(distributeAddr, msg.sender, quantity);
        users[msg.sender].lastTime = block.timestamp;
        users[msg.sender].withdrawnNum.level1WithdrawnNum = users[msg.sender].withdrawnNum.level1WithdrawnNum.add(1);
        
        totalInfo.totalWithdraws = totalInfo.totalWithdraws.add(quantity);
        withdrawAddrs.push(msg.sender);
        emit level1Withdrawn(msg.sender, quantity);
    }


    /**
     * start
     * @dev start Enrol to Earn campaign
     **/
    function start() public onlyOwner {
        require(init == false, "Err: already started");
        init = true;
        
        emit started(init);
    }


    /**
    @notice function to limit user level.
    @dev only owner.
    */
    function limitLevels() public onlyOwner {
        for (uint i = 0; i < depositAddrs.length; i++) {
            if (users[depositAddrs[i]].levelStatus.upgraded4 && block.timestamp.sub(users[depositAddrs[i]].lastTime) >= 160 days) {
                users[depositAddrs[i]].levelStatus.upgraded4 = false;
            } else if (users[depositAddrs[i]].levelStatus.upgraded3 && block.timestamp.sub(users[depositAddrs[i]].lastTime) >= 120 days) {
                users[depositAddrs[i]].levelStatus.upgraded3 = false;
            } else if (users[depositAddrs[i]].levelStatus.upgraded2 && block.timestamp.sub(users[depositAddrs[i]].lastTime) >= 90 days) {
                users[depositAddrs[i]].levelStatus.upgraded2 = false;
            } else if (users[depositAddrs[i]].levelStatus.deposited && block.timestamp.sub(users[depositAddrs[i]].lastTime) >= 60 days) {
                users[depositAddrs[i]].levelStatus.deposited = false;
            }
        }
    }


    /**
    @notice function to set public variables.
    @dev only owner.
    */
    function setUplineAddr(address _uplineAddr) public onlyOwner {
        require(_uplineAddr != address(0), "Err: can't be null");
        uplineAddr = _uplineAddr;
    }

    function setDistributeAddr(address _distributeAddr) public onlyOwner {
        require(_distributeAddr != address(0), "Err: can't be null");
        distributeAddr = _distributeAddr;
    }

    function setDevAddr(address _devAddr) public onlyOwner {
        require(_devAddr != address(0), "Err: can't be null");
        devAddr = _devAddr;
    }


    function setUplineRate(uint256 _uplineRate) public onlyOwner {
        require(_uplineRate > 0, "Err: can't be zero");
        uplineRate = _uplineRate;
    }
    
    function setDistributeRate(uint256 _distributeRate) public onlyOwner {
        require(_distributeRate > 0, "Err: can't be zero");
        distributeRate = _distributeRate;
    }

    function setDevRate(uint256 _devRate) public onlyOwner {
        require(_devRate > 0, "Err: can't be zero");
        devRate = _devRate;
    }


    // view functions
    function checkState() internal view {
        require(init, "Err: Not started yet");
        require(users[msg.sender].lastTime > 0, "Err: no deposit");
        require(users[msg.sender].lastTime.add(7 days) < block.timestamp, "Err: not in time");
    }

    function getRewardsSinceLastWithdraw(address _addr, uint256 _amount) public view returns(uint256) {
        require(_addr != address(0), "Err: can't be null");
        uint256 secondsPassed = min(604800, block.timestamp.sub(users[_addr].lastTime));
        return secondsPassed.mul(_amount).div(5147234);  // 11.75% weekly reward
    }

    function getCurrentTime() public view returns(uint256) {
        return block.timestamp;
    }


    // pure functions
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? b : a;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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