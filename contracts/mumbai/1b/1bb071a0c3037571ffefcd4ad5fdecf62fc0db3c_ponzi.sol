/**
 *Submitted for verification at polygonscan.com on 2022-04-03
*/

// SPDX-License-Identifier: OML
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


interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract ponzi is Ownable {
    address payable internal feeWallet;
    uint256 constant internal DEV_FEE = 100;
    uint256 constant internal DAY = 43200;
    uint256 constant internal PERCENT_DIVIDER = 1000;
    uint256 constant internal PERCENT_INCREASE = 15;

    struct Plan {
        uint256 minimumBlocks;
        uint8 interestPercent;
        IERC20 token;
        uint256 minimumAmount;
        uint256 maximumAmount;
        uint256 amount;
    }

    Plan[] plans;

    struct Deposit {
        uint8 plan;
        uint256 amount;
        uint256 profit;
        uint256 start;
        uint256 finish;
        uint8 interest;
        uint8 daysInvested;
    }

    struct User {
        Deposit[] deposits;
        address referrer;
        uint256[3] levels;
        uint256 bonus;
    }

    mapping (address => User) internal users;
    mapping (uint256 => address) internal addresses;
    uint256 internal totalInvested;

    address selfAddress = address(this);

    // create a function which adds a plan with the passed parameters
    function addPlan(uint8 minimumDays, uint8 interestPercent, address tokenAddress, uint256 minimumAmount, uint256 maximumAmount) public onlyOwner {
        require(minimumDays > 0, "Minimum blocks must be greater than 0");
        require(interestPercent > 0, "Interest percent must be greater than 0");
        plans.push(
            Plan({
        minimumBlocks: minimumDays * DAY,
        interestPercent: interestPercent,
        token: IERC20(tokenAddress),
        minimumAmount: minimumAmount,
        maximumAmount: maximumAmount,
        amount: 0
        })
        );
    }

    function calcDevFee(uint256 amount) internal pure returns (uint256) {
        return amount / PERCENT_DIVIDER * DEV_FEE;
    }

    // create a function which returns the plan at the passed index
    function getPlan(uint256 index) public view returns (Plan memory) {
        require(index < plans.length, "Index out of bounds");
        return plans[index];
    }

    // create a function named calcualeProfits
    // which calculates the profits for all users[addresses[i]]
    // and update profit for each deposit per user
    function calculateProfits() internal {
        for (uint256 i = 0; i < totalInvested; i++) {
            User memory user = users[addresses[i]];
            for (uint256 j = 0; j < user.deposits.length; j++) {
                Deposit memory deposit = user.deposits[j];
                uint8 totalDays = (uint8)((block.number - deposit.start) / DAY);
                if (totalDays < 1 && deposit.daysInvested == totalDays) {
                    continue;
                }

                deposit.profit = (deposit.amount / PERCENT_DIVIDER) * (deposit.interest * totalDays);
                deposit.daysInvested = totalDays;

                users[addresses[i]].deposits[j] = deposit;
            }
        }
    }

    // create a function which increases all plans' interest by the PERCENT_INCREASE percentage
    function increaseInterest() internal {
        for (uint256 i = 0; i < plans.length; i++) {
            uint256 interestPercent = plans[i].interestPercent;
            plans[i].interestPercent = (uint8)((interestPercent / PERCENT_DIVIDER) * PERCENT_INCREASE);
        }
    }

    // create a function which lets a user invest in a plan
    function invest(uint8 index, uint256 amount) public payable {
        calculateProfits();
        require(index < plans.length, "Index out of bounds");
        Plan memory plan = plans[index];
        require(msg.value >= plans[index].minimumAmount, "Amount must be greater than the minimum amount");
        require(plan.token.balanceOf(msg.sender) >= amount, "You don't have enough tokens");
        require(plan.token.balanceOf(selfAddress) >= amount, "The contract doesn't have enough tokens");
        require(plan.token.allowance(msg.sender, selfAddress) >= amount, "You need to approve the contract to spend tokens");
        require(plan.token.transferFrom(msg.sender, selfAddress, amount), "Failed to transfer tokens");

        uint256 fee = calcDevFee(amount);
        plan.token.transfer(feeWallet, fee);
        amount -= fee;

        uint256 start = block.number;
        Deposit memory deposit = Deposit({
        plan: index,
        amount: amount,
        profit: 0,
        start: start,
        finish: (start + plans[index].minimumBlocks),
        interest: plan.interestPercent,
        daysInvested: 0
        });

        users[msg.sender].deposits.push(deposit);
        plans[index].amount += amount;
        totalInvested++;
    }

    //create a reinvest function which lets a user reinvest their investment
    function reinvest(uint256 index) public {
        calculateProfits();
        require(index < plans.length, "Index out of bounds");
        require(users[msg.sender].deposits.length > 0, "You don't have any deposits");
        Deposit memory deposit = users[msg.sender].deposits[index];

        require(block.number >= deposit.start + plans[deposit.plan].minimumBlocks * DAY, "You can't reinvest before the minimum days");
        require(deposit.finish < block.number, "You can't reinvest this deposit");
        require(deposit.profit > 0, "You can't reinvest this deposit");

        uint256 amount = deposit.amount + deposit.profit;
        uint256 fee = calcDevFee(amount);
        plans[deposit.plan].token.transfer(feeWallet, fee);
        amount -= fee;

        Deposit memory deposit2 = Deposit({
        plan: deposit.plan,
        amount: amount,
        profit: 0,
        start: block.number,
        finish: (block.number + plans[deposit.plan].minimumBlocks),
        interest: plans[deposit.plan].interestPercent,
        daysInvested: 0
        });

        users[msg.sender].deposits[index] = deposit2;
    }

    // Calculate the possible profits from the deposit
    function getDepositProfit(address user, uint256 index) public view returns (uint256) {
        require(users[user].deposits.length > 0, "User has no deposits");
        require(index < users[user].deposits.length, "Index out of bounds");
        Deposit memory deposit = users[user].deposits[index];

        if (deposit.start + DAY < block.number) {
            return 0;
        }

        uint256 daysPast = block.number - deposit.start / DAY;
        return (deposit.amount / PERCENT_DIVIDER) * (daysPast * plans[deposit.plan].minimumBlocks);
    }

    // Allow the user to withdraw his deposit relinquishing all there profits.
    function emergencyWithdraw(address user, uint256 index) public {
        require(users[user].deposits.length > 0, "User has no deposits");
        require(index < users[user].deposits.length, "Index out of bounds");
        Deposit memory deposit = users[user].deposits[index];
        require(plans[deposit.plan].token.balanceOf(selfAddress) >= deposit.amount, "The contract doesn't have enough tokens");

        require(plans[deposit.plan].token.transferFrom(user, selfAddress, deposit.amount), "Failed to transfer tokens");
        plans[deposit.plan].amount -= users[user].deposits[index].amount;
        delete users[user].deposits[index];
        totalInvested--;
    }

    // Allow the user to withdraw there profits, with the option to fully withdraw there original deposit as well.
    function withdraw(address user, uint256 index, bool fullWithdraw) public {
        calculateProfits();
        require(users[user].deposits.length > 0, "User has no deposits");
        require(index < users[user].deposits.length, "Index out of bounds");

        Deposit memory deposit = users[user].deposits[index];
        require(deposit.finish > block.number , "The contract doesn't have enough tokens");
        require(deposit.profit > 0, "Deposit has no profit");
        uint256 transferAmount;

        if(fullWithdraw) {
            transferAmount = deposit.profit + deposit.amount;
        } else {
            transferAmount = deposit.profit;
        }

        uint256 fee = calcDevFee(transferAmount);
        transferAmount -= fee;

        require(plans[deposit.plan].token.balanceOf(selfAddress) >= fee, "The contract doesn't have eno ugh tokens");
        require(plans[deposit.plan].token.transferFrom(feeWallet, selfAddress, fee), "Failed to transfer tokens");

        require(plans[deposit.plan].token.balanceOf(selfAddress) >= deposit.profit, "The contract doesn't have enough tokens");
        require(plans[deposit.plan].token.transferFrom(user, selfAddress, deposit.profit), "Failed to transfer tokens");

        if(fullWithdraw) {
            plans[index].amount -= deposit.profit + deposit.amount;
            delete users[user].deposits[index];
            if (users[user].deposits.length == 0) {
                delete users[user];
            }
        } else {
            plans[index].amount -= deposit.profit;
            users[user].deposits[index].profit = 0;
        }
        totalInvested--;
    }
}