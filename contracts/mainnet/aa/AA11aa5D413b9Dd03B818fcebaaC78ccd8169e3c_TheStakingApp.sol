/**
 *Submitted for verification at polygonscan.com on 2022-09-04
*/

//SPDX-License-Identifier: Proprietary
pragma solidity 0.8.16;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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


interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
}

contract TheStakingApp is Ownable {
    uint8 constant internal DEV_FEE = 50;
    uint8 constant internal L1_REFERRAL_FEE = 30;
    uint8 constant internal L2_REFERRAL_FEE = 10;
    uint8 constant internal L3_REFERRAL_FEE = 3;
    uint16 constant internal PERCENT_DIVIDER = 1000;
    uint32 constant internal DAY = 1 days; 
    address constant internal DEV_ADDRESS = address(0x0000b2BE7DCF872A4662E33B4C09e7FCE2D50000);

    struct Plan {
        uint32 interestPercent;
        IERC20 token;
        uint256 startTime;
        uint256 amount;
        uint256 lastInterestHike;
        uint256 minimumDays;
    }

    struct Deposit {
        uint8 plan;
        uint32 interest;
        uint256 amount;
        uint256 start;
        uint256 finish;
        uint256 lastWithdraw;
    }

    struct User {
        Deposit[] deposits;
        address referred_by;
        mapping(IERC20 => uint256) bonus;
    }

    Plan[] public plans;
    mapping(address => User) public users;
    mapping(IERC20 => uint256) public deposited;

    constructor() {
        users[DEV_ADDRESS].referred_by = DEV_ADDRESS;
    }

    /**
     * @dev Add a new plan to the contract.
     * @param minimumDays The minimum amount of days to invest in this plan.
     * @param interestPercent The interest percentage of this plan.
     * @param token The address of the token to invest in this plan.
     */
    function addPlan(uint32 minimumDays, uint16 interestPercent, IERC20 token, uint256 startTime) public onlyOwner {
        plans.push(Plan({
            lastInterestHike: startTime,
            interestPercent: interestPercent,
            token: token,
            startTime: block.timestamp > startTime ? block.timestamp : startTime,
            minimumDays: minimumDays * DAY,
            amount: 0
        }));
    }

    /**
     * @dev Delete a plan from the contract.
     * @param index The index of the plan to delete.
     */
    function deletePlan(uint8 index) public onlyOwner {
        require(index < plans.length);
        require(plans[index].token.balanceOf(address(this)) == 0);
        for (; index < plans.length - 1; index++) plans[index] = plans[index + 1];
        plans.pop();
    }

    function deleteDeposit(uint16 index) internal {
        User storage user = users[msg.sender];
        for (; index < user.deposits.length - 1; index++) user.deposits[index] = user.deposits[index + 1];
        user.deposits.pop();
    }

    /**
     * @dev Calculate the dev fee for a given amount.
     * @param amount The amount to calculate the fee for.
     * @return The fee for the given amount.
     */
    function calcFee(uint256 amount, uint8 percent) internal pure returns (uint256) {
        return (amount / PERCENT_DIVIDER) * percent;
    }

    function payDevFees(uint256 fee, IERC20 token) internal {
        token.transfer(DEV_ADDRESS, fee);
    }

    /**
     * @dev Check if the user has enough funds to invest.
     * @param amount The amount to invest.
     * @param index the index of their deposit.
     */
    function invest(uint8 index, uint256 amount, address referrer) public {
        require(index < plans.length);

        Plan storage plan = plans[index];
        IERC20 token = plan.token;
        require(token.transferFrom(msg.sender, address(this), amount), "failed transfer");

        deposited[token] += amount;
        User storage user = users[msg.sender];
        user.referred_by = referrer;
        users[referrer].bonus[token] += calcFee(amount, L1_REFERRAL_FEE);
        users[referrer=users[referrer].referred_by].bonus[token] += calcFee(amount, L2_REFERRAL_FEE);
        users[referrer=users[referrer].referred_by].bonus[token] += calcFee(amount, L3_REFERRAL_FEE);

        uint256 fee = calcFee(amount, DEV_FEE);
        payDevFees(fee, token);

        uint256 start = plan.startTime > block.timestamp ? plan.startTime : block.timestamp;
        user.deposits.push(Deposit({
            plan: index,
            amount: amount,
            start: start,
            finish: start + plan.minimumDays,
            interest: plan.interestPercent,
            lastWithdraw: 0
        }));

        plan.amount += amount;
    }

    /**
     * @dev Check if the user has enough profit to reinvest and their previous investment finished.
     * @param index the index of their deposit.
     */
    function reinvest(uint16 index) public {
        User storage user = users[msg.sender];
        require(user.deposits.length > 0 && index < user.deposits.length);

        Deposit storage deposit = user.deposits[index];
        require(deposit.finish < block.number, "wait");
        Plan storage plan = plans[deposit.plan];
        IERC20 token = plan.token;

        uint256 profit = calculateProfit(msg.sender, index);
        uint256 amount = deposit.amount + profit;

        uint256 fee = calcFee(amount, DEV_FEE);
        payDevFees(fee, token);

        deleteDeposit(index);
            user.deposits.push(Deposit({
            plan: deposit.plan,
            amount: amount,
            start: block.timestamp,
            finish: block.timestamp + plan.minimumDays,
            interest: plan.interestPercent,
            lastWithdraw: 0
        }));
    }
    /**
     * @dev Withdraw the user's deposit relinquishing all profits from the investment.
     * @param index The index of the deposit to withdraw.
     */
    function emergencyWithdraw(uint16 index) public {
        User storage user = users[msg.sender];
        require(user.deposits.length > 0 && index < user.deposits.length);

        Deposit storage deposit = user.deposits[index];
        uint256 transferAmount = deposit.amount;
        IERC20 token = plans[deposit.plan].token;

        uint256 balance = token.balanceOf(address(this));
        if(balance < transferAmount) {
            transferAmount = balance;
        }
        require(transferAmount > 0, "0");
        uint256 fee = calcFee(transferAmount, DEV_FEE);
        payDevFees(fee, token);

        deleteDeposit(index);
        token.transfer(msg.sender, transferAmount);
    }

    /**
     * @dev Withdraw the user's profits and deposit if full withdraw is true
     * @param index The index of the deposit to withdraw.
     * @param fullWithdraw True if the user wants to withdraw profits and deposit.
     */
    function withdraw(uint16 index, bool fullWithdraw) public {
        User storage user = users[msg.sender];
        require(user.deposits.length > 0 && index < user.deposits.length);

        Deposit storage deposit = user.deposits[index];
        require(block.timestamp > deposit.finish);
        IERC20 token = plans[deposit.plan].token;

        uint256 transferAmount = calculateProfit(msg.sender, index);
        if (fullWithdraw) {
            transferAmount += deposit.amount;
        }

        uint256 balance = token.balanceOf(address(this));
        if(balance < transferAmount) {
            transferAmount = balance;
        }

        require(transferAmount > 0, "0");
        uint256 fee = calcFee(transferAmount, DEV_FEE);
        transferAmount -= fee;
        payDevFees(fee, token);

        if (fullWithdraw) {
            deleteDeposit(index);
        } else {
            deposit.lastWithdraw = block.timestamp;
        }
        token.transfer(msg.sender, transferAmount);
    }

    function withdrawBonus(IERC20 token) public {
        User storage user = users[msg.sender];
        uint256 bonus = user.bonus[token];

        uint256 balance = token.balanceOf(address(this));
        if(balance < bonus) {
            bonus = balance;
        }

        require(bonus > 0, "0");
        uint256 fee = calcFee(bonus, DEV_FEE);
        payDevFees(fee, token);
        user.bonus[token] = 0;

        token.transfer(msg.sender, bonus);
    }

    // calcuate the profit for a single users deposit
    function calculateProfit(address addr, uint16 index) public view returns (uint256) {
        Deposit storage deposit = users[addr].deposits[index];

        if(deposit.start > block.timestamp) return 0;
        
        uint256 totalDays = ((block.timestamp - deposit.start) - deposit.lastWithdraw) / DAY;
        return (deposit.amount / PERCENT_DIVIDER) * (deposit.interest * totalDays);
    }

    /**
     * @dev returns a users deposit details
     * @param addr the user address
     * @return the deposit details
     */
    function getUserDeposits(address addr) public view returns (Deposit[] memory) {
        return users[addr].deposits;
    }

    function getPlans() public view returns (Plan[] memory) {
        return plans;
    }

    /**
     * @dev When the next interest hike will happen
     * @return return the block when the interest will be increased
     */
    function getNextInterestHikeDate(uint16 index) public view returns (uint256) {
        return plans[index].lastInterestHike + DAY;
    }

    function getUserBonuses(address wallet, IERC20 token) public view returns (uint256){
        return users[wallet].bonus[token];
    }

    receive() payable external{}
}