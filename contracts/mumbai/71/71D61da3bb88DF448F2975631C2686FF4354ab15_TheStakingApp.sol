/**
 *Submitted for verification at polygonscan.com on 2022-04-11
*/

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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: ponzi_erc20.sol

//SPDX-License-Identifier: Proprietary

pragma solidity ^0.8.13;




interface IERC20 {

    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

}



contract TheStakingApp is Ownable {

    address constant internal DEV_ADDRESS_O = address(0x26ef08C12b37b8C14f7bCe8A492474A0902Dd2E0);

    address constant internal DEV_ADDRESS_1 = address(0x26ef08C12b37b8C14f7bCe8A492474A0902Dd2E0);

    uint256 constant internal DEV_FEE = 50; // 5% of deposit and withdraw total fee 10%

    uint256 constant internal DEV_FEE_O = 700; // 70% fee for organisation wallet

    uint256 constant internal DEV_FEE_1 = 300; // 30% fee for dev



    uint256 constant internal PERCENT_DIVIDER = 1000;

    uint256 constant internal PERCENT_INCREASE = 7;

    uint256 constant internal L1_REFERRAL_FEE = 30;

    uint256 constant internal L2_REFERRAL_FEE = 10;

    uint256 constant internal L3_REFERRAL_FEE = 3;

    uint256 constant internal DAYBLOCKS = 1;



    struct Plan {

        uint256 interestPercent;

        IERC20 token;

        uint256 startBlock;

        uint256 minimumBlocks;

        uint256 minimumAmount;

        uint256 maximumAmount;

        uint256 amount;

    }



    struct Deposit {

        uint16 plan;

        uint256 interest;

        uint256 amount;

        uint256 start;

        uint256 finish;

        uint256 lastWithdraw;

    }



    struct User {

        Deposit[] deposits;

        address wallet;

        address referred_by;

        mapping(address => uint256) bonus;

    }



    Plan[] public plans;

    mapping(address => User) public users;

    mapping(address => uint256) public deposited;

    uint256 internal lastInterestHike;



    constructor() {

        lastInterestHike = block.number;

    }



    /**

     * @dev Add a new plan to the contract.

     * @param minimumDays The minimum amount of days to invest in this plan.

     * @param interestPercent The interest percentage of this plan.

     * @param tokenAddress The address of the token to invest in this plan.

     * @param minimumAmount The minimum amount of tokens to invest in this plan.

     * @param maximumAmount The maximum amount of tokens to invest in this plan.

     */

    function addPlan(uint8 minimumDays, uint16 interestPercent, address tokenAddress, uint256 minimumAmount, uint256 maximumAmount, uint256 startBlock) public onlyOwner {

        require(tokenAddress != address(0));

        require(minimumAmount > 0, "min");

        require(maximumAmount > minimumAmount, "amount");

        require(minimumDays >= 1, "days");



        plans.push(Plan({

        interestPercent: interestPercent,

        token: IERC20(tokenAddress),

        startBlock: startBlock,

        minimumBlocks: minimumDays * DAYBLOCKS,

        minimumAmount: minimumAmount,

        maximumAmount: maximumAmount,

        amount: 0

        }));



        deposited[tokenAddress] = 0;

    }



    /**

     * @dev Delete a plan from the contract.

     * @param index The index of the plan to delete.

     */

    function deletePlan(uint16 index) public onlyOwner {

        require(plans[index].amount == 0);

        delete plans[index];

    }



    /**

     * @dev Calculate the dev fee for a given amount.

     * @param amount The amount to calculate the fee for.

     * @return The fee for the given amount.

     */

    function calcDevFee(uint256 amount) internal pure returns (uint256) {

        return calcFee(amount, DEV_FEE);

    }



    function calcFee(uint256 amount, uint256 percent) internal pure returns (uint256) {

        return (amount / PERCENT_DIVIDER) * percent;

    }



    function payDevFees(uint256 fee, IERC20 token) internal {

        uint256 devFee0 = calcFee(fee, DEV_FEE_O);

        uint256 devFee1 = calcFee(fee, DEV_FEE_1);

        require(token.transfer(DEV_ADDRESS_O, devFee0), "F");

        require(token.transfer(DEV_ADDRESS_1, devFee1), "F");

    }



    /**

     * @dev Check if the user has enough funds to invest.

     * @param amount The amount to invest.

     * @param index the index of their deposit.

     */

    function invest(uint16 index, uint256 amount, address referrer) public {

        increaseInterest();

        require(index < plans.length);



        Plan storage plan = plans[index];

        require(amount >= plan.minimumAmount, "<min");

        require(amount <= plan.maximumAmount, ">max");



        plan.token.transferFrom(msg.sender, address(this), amount);

        deposited[address(plan.token)] += amount;



        User storage user = users[msg.sender];

        user.referred_by = referrer;

        user.wallet = msg.sender;



        address i = address(plan.token);



        if(referrer != address(0)) {

            User storage l1Referrer = users[referrer];

            l1Referrer.bonus[i] += calcFee(amount, L1_REFERRAL_FEE);

            referrer = l1Referrer.referred_by;

        }



        if(referrer != address(0)) {

            User storage l2Referrer = users[referrer];

            l2Referrer.bonus[i] += calcFee(amount, L2_REFERRAL_FEE);

            referrer = l2Referrer.referred_by;

        }



        if(referrer != address(0)) {

            User storage l3Referrer = users[referrer];

            l3Referrer.bonus[i] += calcFee(amount, L3_REFERRAL_FEE);

        }



        uint256 fee = calcDevFee(amount);

        payDevFees(fee, plan.token);

        amount -= fee;





        uint256 start = (plan.startBlock > block.number) ? plan.startBlock : block.number;

        user.deposits.push(Deposit({

        plan: index,

        amount: amount,

        start: start,

        finish: start + plan.minimumBlocks,

        interest: plan.interestPercent,

        lastWithdraw: 0

        }));



        plans[index].amount += amount;

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



        uint256 profit = calculateProfit(msg.sender, index);

        uint256 amount = deposit.amount + profit;



        uint256 fee = calcDevFee(amount);

        payDevFees(fee, plans[deposit.plan].token);

        amount -= fee;



        delete user.deposits[index];

        user.deposits.push(Deposit({

        plan: deposit.plan,

        amount: amount,

        start: block.number,

        finish: (block.number + plans[deposit.plan].minimumBlocks),

        interest: plans[deposit.plan].interestPercent,

        lastWithdraw: 0

        }));

    }

    /**

     * @dev Withdraw the user's deposit relinquishing all profits from the investment.

     * @param index The index of the deposit to withdraw.

     */

    function emergencyWithdraw(uint16 index) public {

        increaseInterest();



        User storage user = users[msg.sender];

        require(user.deposits.length > 0 && index < user.deposits.length);



        Deposit storage deposit = user.deposits[index];

        uint256 transferAmount = deposit.amount;

        Plan storage plan = plans[deposit.plan];



        if(plan.token.balanceOf(address(this)) < transferAmount) {

            transferAmount = plan.token.balanceOf(address(this));

        }



        uint256 fee = calcDevFee(transferAmount);

        transferAmount -= fee;



        payDevFees(fee, plan.token);



        plan.token.transfer(msg.sender, transferAmount);

        delete user.deposits[index];

    }



    /**

     * @dev Withdraw the user's profits and deposit if full withdraw is true

     * @param index The index of the deposit to withdraw.

     * @param fullWithdraw True if the user wants to withdraw profits and deposit.

     */

    function withdraw(uint16 index, bool fullWithdraw) public {

        increaseInterest();



        User storage user = users[msg.sender];

        require(user.deposits.length > 0 && index < user.deposits.length);



        Deposit storage deposit = user.deposits[index];

        require(block.number > deposit.finish);

        Plan storage plan = plans[deposit.plan];



        uint256 transferAmount = calculateProfit(msg.sender, index);

        if (fullWithdraw) {

            transferAmount += deposit.amount;

        }



        if(plan.token.balanceOf(address(this)) < transferAmount) {

            transferAmount = plan.token.balanceOf(address(this));

        }

        require(transferAmount > 0, "0");



        uint256 fee = calcDevFee(transferAmount);

        transferAmount -= fee;

        payDevFees(fee, plan.token);



        plan.token.transfer(user.wallet, transferAmount);

        deposit.lastWithdraw = block.number;



        if (fullWithdraw) {

            delete user.deposits[index];

        }

    }



    function withdrawBonus(address index) public {

        increaseInterest();

        User storage user = users[msg.sender];

        uint256 bonus = user.bonus[index];

        IERC20 token = IERC20(index);



        if(token.balanceOf(address(this)) < bonus) {

            bonus = token.balanceOf(address(this));

        }

        require(bonus > 0, "0");



        uint256 fee = calcDevFee(bonus);

        bonus -= fee;



        payDevFees(fee, token);

        token.transfer(user.wallet, bonus);



        user.bonus[index] = 0;

    }



    // calcuate the profit for a single users deposit

    function calculateProfit(address addr, uint16 index) public view returns (uint256) {

        Deposit storage deposit = users[addr].deposits[index];

        uint256 totalDays = ((block.number - deposit.start) - deposit.lastWithdraw) / DAYBLOCKS;

        if (totalDays < 1) return 0;

        return (deposit.amount / PERCENT_DIVIDER) * (deposit.interest * totalDays);

    }



    /**

     * @dev Increase the interest for all plans.

     */

    function increaseInterest() internal {

        if (block.number - lastInterestHike < DAYBLOCKS) return;



        for (uint16 i = 0; i < plans.length; i++) {

            Plan storage plan = plans[i];

            if ((plan.startBlock + DAYBLOCKS) < block.number) {

                continue;

            }



            plan.interestPercent += ((block.number - plan.startBlock) / DAYBLOCKS) * PERCENT_INCREASE;

        }

    }



    /**

     * @dev returns a users deposit details

     * @param addr the user address

     * @param index the index of the deposit to return

     * @return the deposit details

     */

    function getUserDeposit(address addr, uint16 index) public view returns (Deposit memory) {

        return users[addr].deposits[index];

    }



    /**

     * @dev When the next interest hike will happen

     * @return return the block when the interest will be increased

     */

    function getNextInterestHikeDate() public view returns (uint256) {

        return lastInterestHike + DAYBLOCKS;

    }



    /**

     * @dev Destroy the contract once all balances are empty

     */

    function endOfLife() public onlyOwner {

        bool ALLOW = true;



        for(uint256 i = 0; i < plans.length; i++) {

            if(plans[i].token.balanceOf(address(this)) > 0) {

                ALLOW = false;

            }

        }



        if(ALLOW == true) {

            selfdestruct(payable(address(this)));

        }

    }

}