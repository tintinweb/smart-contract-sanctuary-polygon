// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
import './BokkyPooBahsDateTimeLibrary.sol';

interface IERC20 {
    /**
    * @dev Returns the amount of tokens in existence.
*/
    function totalSupply() external view returns(uint256);
    /**
    * @dev Returns the amount of tokens owned by `account`.
*/
    function balanceOf(address account) external view returns(uint256);
    /**
    * @dev Moves `amount` tokens from the caller's account to `recipient`.
*
* Returns a boolean value indicating whether the operation succeeded.
*
* Emits a {Transfer} event.
*/
    function transfer(address recipient, uint256 amount) external returns(bool);
    /**
    * @dev Returns the remaining number of tokens that `spender` will be
* allowed to spend on behalf of `owner` through {transferFrom}. This is
* zero by default.
*
* This value changes when {approve} or {transferFrom} are called.
*/
    function allowance(address owner, address spender) external view returns(uint256);
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
    function approve(address spender, uint256 amount) external returns(bool);
    /**
    * @dev Moves `amount` tokens from `sender` to `recipient` using the
* allowance mechanism. `amount` is then deducted from the caller's
* allowance.
*
* Returns a boolean value indicating whether the operation succeeded.
*
* Emits a {Transfer} event.
*/
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
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

//Multiple version, deposit queue (automatic). Lazy withdrawal queue is impossible, as amount would have to be held,
//which is impossible if there are any losses.
//Instead, one can use withdraw/collectOnBehalfOf and use a scheduled transaction system like a bot or Gelato.
contract TetradWallet
{
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
    * @dev Initializes the contract setting the deployer as the initial owner.
    */
    //    constructor() internal {
    //        address msgSender = msg.sender;
    //        _owner = msgSender;
    //        emit OwnershipTransferred(address(0), msgSender);
    //    }
    /**
    * @dev Returns the address of the current owner.
    */
    function owner() public view returns(address) {
        return _owner;
    }
    /**
    * @dev Throws if called by any account other than the owner.
*/
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    /**
    * @dev Transfers ownership of the contract to a new account (`newOwner`).
    * Can only be called by the current owner.
    */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    function getOwnerUnlockTime() public view returns(uint256) {
        return _lockTime;
    }
    //Locks the contract for owner for the amount of time provided
    function ownerLock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    //Unlocks the contract for owner when _lockTime is exceeds
    function ownerUnlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime, "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }

    uint256 public totalDeposited;
    uint256 public lastMonthChange; //Could save some data here by combining year and month
    uint256 public lastYearChange; //Could save some data here by combining year and month
    uint256 public withdrawFee;
    uint256 public unlockDayMin;
    uint256 public unlockDayMax;
    uint256 public nonce;
    mapping(uint256 => uint256) public pendingDeposited;
    mapping(address => uint256) public share;
    mapping(uint256 => mapping(address => uint256)) public pendingShare;
    mapping(address => mapping(address => uint256)) public allowance;
    IERC20 public asset;
    address public feeWallet;

    event Approval(address behalfOf, address spender, uint256 amount);
    event Deposit(uint256 nonce, address behalfOf, address spender, uint256 amount);
    event Withdraw(uint256 nonce, address behalfOf, address spender, uint256 amount, uint256 fee);
    event AdminDeposit(uint256 nonce, address who, uint256 amount);
    event AdminWithdraw(uint256 nonce, address who, uint256 amount);
    event NonceIncrease(uint256 to);

    constructor(IERC20 depositedAsset)
    {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);

        withdrawFee = 165;
        unlockDayMin = 25;
        unlockDayMax = 31;
        asset = depositedAsset;
        feeWallet = msgSender;
    }

    function isLocked() public view returns (bool) {
        uint256 today = BokkyPooBahsDateTimeLibrary.getDay(block.timestamp);
        return today < unlockDayMin || today > unlockDayMax;
    }

    function deposit(uint256 amount) external
    {
        depositOnBehalfOf(msg.sender, amount);
    }

    function depositOnBehalfOf(address behalfOf, uint256 amount) public
    {
        totalDeposited += amount;
        share[behalfOf] += amount;
        pendingDeposited[nonce] += amount;
        pendingShare[nonce][behalfOf] += amount;
        emit Deposit(nonce, behalfOf, msg.sender, amount);
        asset.transferFrom(msg.sender, address(this), amount);
    }

    function balanceToCollect(address collector) public view returns (uint256)
    {
        if(totalDeposited == pendingDeposited[nonce]) return 0; //Division by zero.
        return (asset.balanceOf(address(this)) - pendingDeposited[nonce])
        * (share[collector] - pendingShare[nonce][collector])
        / (totalDeposited - pendingDeposited[nonce]);
        //Done this way so that if a pending does nothing, it will be counted the next nonce.
    }

    function fundsAvailableForAdmin() public view returns (uint256)
    {
        return asset.balanceOf(address(this)) - pendingDeposited[nonce];
    }

    //For the website and anyone who wishes to query this.
    function availableToWithdraw(address collector) public view returns (uint256)
    {
        //Pending balance can always be withdrawn, as it's guaranteed to be there and have no gains or losses attached.
        uint256 pendingBalance = pendingShare[nonce][collector];
        uint256 balance = isLocked() ? 0 : balanceToCollect(collector); //Don't add balance if locked.
        return pendingBalance + balance;
    }

    function availableToWithdrawWithFee(address collector) external view returns (uint256)
    {
        //Pending balance can always be withdrawn, as it's guaranteed to be there and have no gains or losses attached.
        uint256 pendingBalance = pendingShare[nonce][collector];
        uint256 balance = isLocked() ? 0 : balanceToCollect(collector); //Don't add balance if locked.
        uint256 fee = balance * withdrawFee / 10000;
        return pendingBalance + balance - fee;
    }

    function unavailableToWithdraw(address collector) public view returns (uint256)
    {
        //Pending balance can always be withdrawn, so it's not here.
        uint256 unavailableBalance = !isLocked() ? 0 : balanceToCollect(collector); //Don't add balance if locked.
        return unavailableBalance;
    }

    function unavailableToWithdrawWithFee(address collector) external view returns (uint256)
    {
        //Pending balance can always be withdrawn, so it's not here.
        uint256 unavailableBalance = !isLocked() ? 0 : balanceToCollect(collector); //Don't add balance if locked.
        uint256 fee = unavailableBalance * withdrawFee / 10000;
        return unavailableBalance - fee;
    }

    function currentPendingBalanceOf(address collector) external view returns (uint256)
    {
        return pendingShare[nonce][collector];
    }

    function currentTotalPending() external view returns (uint256)
    {
        return pendingDeposited[nonce];
    }

    function _approve(
    address behalfOf,
    address spender,
    uint256 amount
    ) internal {
    require(behalfOf != address(0), "TetradWallet: approve from the zero address");
    require(spender != address(0), "TetradWallet: approve to the zero address");

    allowance[behalfOf][spender] = amount;
    emit Approval(behalfOf, spender, amount);
    }

    function _spendAllowance(
        address behalfOf,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = allowance[behalfOf][spender];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "TetradWallet: insufficient allowance");
        unchecked {
            _approve(behalfOf, spender, currentAllowance - amount);
        }
        }
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    //TODO: Create Tests (Friday)
    //TODO: Try Tests (Friday)

    function withdrawOnBehalfOf(address behalfOf, uint256 amount) public
    {
        address spender = msg.sender;
        //Just in case there's a hidden bug that can be exploited at 0 allowance. Safety first.
        require(behalfOf == spender || allowance[behalfOf][spender] > 0, "Not authorized.");
        require(amount > 0, "Amount must be > 0");
        bool locked = isLocked();
        uint256 pendingBalance = pendingShare[nonce][behalfOf];
        uint256 balance = locked ? 0 : balanceToCollect(behalfOf); //Don't add balance if locked.
        uint256 totalBalance = pendingBalance + balance;
        require(totalBalance > 0 && amount <= totalBalance, "Insufficient total balance.");

        uint256 amountFromPending = amount > pendingBalance ? pendingBalance : amount;
        uint256 amountFromBalance = amount - amountFromPending;
        //assert(amountFromPending + amountFromBalance == amount); //Comment out this line after testing to save gas.

        //Handle pendingDeposited
        if(amountFromPending > 0)
        {
            //Simple and easy, as it is always 1 to 1 with pending balance.
            pendingDeposited[nonce] -= amountFromPending;
            pendingShare[nonce][behalfOf] -= amountFromPending;
            totalDeposited -= amountFromPending;
            share[behalfOf] -= amountFromPending;

            //Give pending to user without fee
            if(behalfOf != spender) _spendAllowance(behalfOf, spender, amountFromPending);
            asset.transfer(behalfOf, amountFromPending);
        }

        if(amountFromBalance > 0)
        {
            //Update so that share matches balance.
            totalDeposited = totalDeposited - share[behalfOf] + balance;
            share[behalfOf] = balance;

            //Now we can subtract normally as our proportions are now 1 to 1 with balance.
            totalDeposited -= amountFromBalance;
            share[behalfOf] -= amountFromBalance;

            //Give fee
            uint256 fee = amountFromBalance * withdrawFee / 10000;
            if(fee > 0) asset.transfer(feeWallet, fee);

            //Give rest to user
            if(behalfOf != spender) _spendAllowance(behalfOf, spender, amountFromBalance);
            asset.transfer(behalfOf, amountFromBalance - fee);
            emit Withdraw(nonce, behalfOf, spender, amount, fee);
        }
        else //So we don't have to define fee outside of this
        {
            emit Withdraw(nonce, behalfOf, spender, amount, 0);
        }
    }

    function collectOnBehalfOf(address behalfOf) public
    {
        withdrawOnBehalfOf(behalfOf, availableToWithdraw(behalfOf));
    }

    function withdrawIgnoreLossesOnBehalfOf(address behalfOf, uint256 amount) public
    {
        uint256 available = availableToWithdraw(behalfOf);
        if(amount >= available) collectOnBehalfOf(behalfOf);
        else withdrawOnBehalfOf(behalfOf, amount);
    }

    //Withdraw only profit.
    function takeProfitOnBehalfOf(address behalfOf) public
    {
        require(!isLocked(), "Cannot take profit if locked."); //Since profits only exist on balance and not pending.
        uint256 balance = balanceToCollect(behalfOf);
        require(balance > share[behalfOf], "Can't take profit on losses/delta neutral/pending only.");
        withdrawOnBehalfOf(behalfOf, balance - share[behalfOf]);
    }

    //Withdraw only initial
    function withdrawInitialMinusFeeOnBehalfOf(address behalfOf) public
    {
        uint256 available = availableToWithdraw(behalfOf);
        if(share[behalfOf] < available) withdrawOnBehalfOf(behalfOf, share[behalfOf]); //Profit: Get the amount we last put in. Amount we have left in is now considered our initial.
        else collectOnBehalfOf(behalfOf); //Losses/Delta Neutral: Get as much as we can.
    }

    function withdraw(uint256 amount) external
    {
        withdrawOnBehalfOf(msg.sender, amount);
    }

    function collect() external
    {
        collectOnBehalfOf(msg.sender);
    }

    function withdrawIgnoreLosses(uint256 amount) external
    {
        withdrawIgnoreLossesOnBehalfOf(msg.sender, amount);
    }

    //Withdraw only profit.
    function takeProfit() external
    {
        takeProfitOnBehalfOf(msg.sender);
    }

    //Withdraw only initial
    function withdrawInitialMinusFee() external
    {
        withdrawInitialMinusFeeOnBehalfOf(msg.sender);
    }

    //If no funds are moved at all, then the nonce will not increase and nothing will count.
    //If someone comes in and transfers money without using this or user deposit, it will go directly to the users,
    //but will not increase the nonce. This is fine, it just means that people will randomly be able to withdraw more
    //tokens in the middle of the epoch, open or closed.
    function adminDeposit(uint256 amount) external onlyOwner
    {
        //This also marks the start of the next nonce.
        require(isLocked(), "Can only move funds when locked.");
        (uint256 year, uint256 month,) = BokkyPooBahsDateTimeLibrary.timestampToDate(block.timestamp);
        //Only increase nonce if it is the first time this month.
        if(lastYearChange != year || lastMonthChange != month)
        {
            lastYearChange = year;
            lastMonthChange = month;
            nonce += 1;
            emit NonceIncrease(nonce);
        }
        emit AdminDeposit(nonce, msg.sender, amount);
        asset.transferFrom(msg.sender, address(this), amount);
    }

    function adminWithdraw(uint256 amount) external onlyOwner
    {
        //This also marks the start of the next nonce.
        require(isLocked(), "Can only move funds when locked.");
        (uint256 year, uint256 month,) = BokkyPooBahsDateTimeLibrary.timestampToDate(block.timestamp);
        //Only increase nonce if it is the first time this month.
        if(lastYearChange != year || lastMonthChange != month) //All funds become available when the nonce changes.
        {
            lastYearChange = year;
            lastMonthChange = month;
            nonce += 1;
            emit NonceIncrease(nonce);
        }
        else
        {
            require(amount <= fundsAvailableForAdmin(), "Not enough funds available.");
        }
        emit AdminWithdraw(nonce, msg.sender, amount);
        asset.transfer(msg.sender, amount);
    }

    function adminSettings(uint256 fee, uint256 unlockMin, uint256 unlockMax) external onlyOwner
    {
        require(fee <= 600, "Withdraw fee must be lower than or equal to 6%.");
        require(unlockMax >= unlockMin, "Unlock day max must be greater than or equal to unlock day min.");
        require(unlockMin >= 1 && unlockMin <= 28, "Unlock day min must be at a time that all months have.");
        //Unlock day max can be whenever as long as the unlock day STARTS before a time where all months do not have.
        //This is so that people have at least a single day to withdraw at all times.
        withdrawFee = fee;
        unlockDayMin = unlockMin;
        unlockDayMax = unlockMax;
    }

    function adminChangeFeeWallet(address wallet) external onlyOwner
    {
        feeWallet = wallet;
    }
}

//Single version, no queue
//contract TetradWallet
//{
//
//    address private _owner;
//    address private _previousOwner;
//    uint256 private _lockTime;
//    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
//    /**
//    * @dev Initializes the contract setting the deployer as the initial owner.
//    */
//    //    constructor() internal {
//    //        address msgSender = msg.sender;
//    //        _owner = msgSender;
//    //        emit OwnershipTransferred(address(0), msgSender);
//    //    }
//    /**
//    * @dev Returns the address of the current owner.
//    */
//    function owner() public view returns(address) {
//        return _owner;
//    }
//    /**
//    * @dev Throws if called by any account other than the owner.
//*/
//    modifier onlyOwner() {
//        require(_owner == msg.sender, "Ownable: caller is not the owner");
//        _;
//    }
//    /**
//    * @dev Leaves the contract without owner. It will not be possible to call
//    * `onlyOwner` functions anymore. Can only be called by the current owner.
//    *
//    * NOTE: Renouncing ownership will leave the contract without an owner,
//    * thereby removing any functionality that is only available to the owner.
//    */
//    function renounceOwnership() public virtual onlyOwner {
//        emit OwnershipTransferred(_owner, address(0));
//        _owner = address(0);
//    }
//    /**
//    * @dev Transfers ownership of the contract to a new account (`newOwner`).
//    * Can only be called by the current owner.
//    */
//    function transferOwnership(address newOwner) public virtual onlyOwner {
//        require(newOwner != address(0), "Ownable: new owner is the zero address");
//        emit OwnershipTransferred(_owner, newOwner);
//        _owner = newOwner;
//    }
//    function getUnlockTime() public view returns(uint256) {
//        return _lockTime;
//    }
//    //Locks the contract for owner for the amount of time provided
//    function lock(uint256 time) public virtual onlyOwner {
//        _previousOwner = _owner;
//        _owner = address(0);
//        _lockTime = block.timestamp + time;
//        emit OwnershipTransferred(_owner, address(0));
//    }
//    //Unlocks the contract for owner when _lockTime is exceeds
//    function unlock() public virtual {
//        require(_previousOwner == msg.sender, "You don't have permission to unlock");
//        require(block.timestamp > _lockTime, "Contract is locked until 7 days");
//        emit OwnershipTransferred(_owner, _previousOwner);
//        _owner = _previousOwner;
//    }
//
//    uint256 public totalDeposited;
//    mapping(address => uint256) public share;
//    IERC20 public asset;
//    bool public lockedMode;
//
//    constructor(IERC20 depositedAsset)
//    {
//        address msgSender = msg.sender;
//        _owner = msgSender;
//        emit OwnershipTransferred(address(0), msgSender);
//
//        asset = depositedAsset;
//    }
//
//    function isLocked() public view returns (bool) {
//        uint256 today = BokkyPooBahsDateTimeLibrary.getDay(block.timestamp);
//        return today > 5;
//    }
//
//    //
//    function deposit(uint256 amount) external
//    {
//        require(!isLocked(), "Locked.");
//        totalDeposited += amount;
//        share[msg.sender] += amount;
//        asset.transferFrom(msg.sender, address(this), amount);
//    }
//
//    function balanceToCollect(address collector) public view returns (uint256)
//    {
//        return asset.balanceOf(address(this)) * share[collector] / totalDeposited;
//    }
//
//    //Collects the entire balance of an individual, including profits and losses. To make math simpler and avoid
//    //security issues, we do not allow partial collection. Instead, we collect and then redeposit.
//    function collect() external
//    {
//        require(!isLocked(), "Locked.");
//        uint256 balance = balanceToCollect(msg.sender);
//        require(balance > 0, "Insufficient balance.");
//        totalDeposited -= share[msg.sender];
//        share[msg.sender] = 0;
//        asset.transfer(msg.sender, balance);
//    }
//
//    function withdraw(uint256 amount) external
//    {
//        //Collect all
//        require(!isLocked(), "Locked.");
//        uint256 balance = balanceToCollect(msg.sender);
//        require(balance > 0 && amount <= balance, "Insufficient balance.");
//        totalDeposited -= share[msg.sender];
//        share[msg.sender] = 0;
//
//        //Redeposit amount not wanted
//        var amountToDeposit = balance - amount;
//        if(amountToDeposit > 0)
//        {
//            totalDeposited += amountToDeposit;
//            share[msg.sender] += amountToDeposit;
//        }
//
//        //Give back the rest to the user
//        asset.transfer(msg.sender, amount);
//    }
//
//    //Withdraw only profit.
//    function takeProfit() external
//    {
//        uint256 balance = balanceToCollect(msg.sender);
//        require(balance > share[msg.sender], "Can't take profit on losses/delta neutral.");
//        withdraw(balance - share[msg.sender]);
//    }
//
//    //Withdraw only initial
//    function withdrawInitial() external
//    {
//        uint256 balance = balanceToCollect(msg.sender);
//        if(share[msg.sender] < balance) withdraw(share[msg.sender]); //Profit: Get the amount we last put in. Amount we have left in is now considered our initial.
//        else collect(); //Losses/Delta Neutral: Get as much as we can.
//    }
//
//    function adminDeposit(uint256 amount) external onlyOwner
//    {
//        require(isLocked(), "Can only move funds when locked.");
//        asset.transferFrom(msg.sender, address(this), amount);
//    }
//
//    function adminWithdraw(uint256 amount) external onlyOwner
//    {
//        require(isLocked(), "Can only move funds when locked.");
//        asset.transfer(msg.sender, amount);
//    }
//}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library BokkyPooBahsDateTimeLibrary {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   https://aa.usno.navy.mil/faq/JD_formula.html
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
        - 32075
        + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
        + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
        - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
        - OFFSET19700101;

        _days = uint(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }
    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }
    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        (uint year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }
    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }
    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }
    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        (uint year, uint month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }
    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }
    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = (_days + 3) % 7 + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        (,month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        (,,day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }
    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }
    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = yearMonth % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }
    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }
    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear, uint fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear, uint toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}