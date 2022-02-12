/**
 *Submitted for verification at polygonscan.com on 2022-02-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract Mlm is ReentrancyGuard {
    address payable public admin;

    uint256 public incTime;

    uint256 public totalInvested;
    uint256 public totalReinvested;
    uint256 public totalWithdrawals;
    uint256 public totalReferralBonus;

    uint256 constant DEPOSIT_DAYS = 40 * 1 days;
    uint256 constant DELAY_DAYS = 10 * 1 days;

    //uint256 constant MIN_DEPOSIT = 5 ether; //test
    //uint256 constant MIN_REINVEST = 0.05 ether; //test
    uint256 constant MIN_DEPOSIT = 0.01 ether; //test
    uint256 constant MIN_REINVEST = 0.005 ether; //test

    uint256 constant DAILY_PROFIT_PERCENT = 7;
    uint256 constant REINVEST_FEE_PERCENT = 6;
    uint256 constant REINVEST_OF_PROFIT_PERCENT = 24;
    uint256 constant REINVEST_WITHDRAW_PERCENT = 70;
    uint256 constant ADMIN_FEE_PERCENT = 10;

    uint256 private constant REF_LEVEL_1 = 70;
    uint256 private constant REF_LEVEL_2 = 20;
    uint256 private constant REF_LEVEL_3 = 10;
    uint256 private constant REF_LEVEL_4 = 5;
    uint256 private constant REF_LEVEL_5 = 5;
    uint256 private constant REF_LEVEL_6 = 3;
    uint256 private constant REF_LEVEL_7 = 2;

    event Deposit(address indexed investor, uint256 amount);
    event ReturnDeposit(address indexed investor, uint256 amount);
    event Reinvest(address indexed investor, uint256 amountWithdrawned, uint256 amountReinvested);
    event RefBonus(address indexed investor, address indexed referrer, uint256 amount);
    event SendTo(address indexed investor, uint256 amount);

    struct Investment {
        uint256 deposited;
        uint256 reinvested;
        uint256 withdrawals;
        uint256 lastUpdate;
        uint256 deadline;
    }

    mapping(address => Investment[10]) public invests;
    mapping(address => address[7]) public refs;
    mapping(address => uint256[7]) public refsAmount;

    modifier checkDate(uint256 index) {
       require(invests[msg.sender][index].deadline != 0,
               "newDeposit function must be called first"
        );
        _;
    }

    modifier checkIndex(uint256 index) {
       require(index < 10,
               "Unappropriate index"
        );
        _;
    }

    constructor(address payable _admin) {
        require(_admin != address(0), "Admin address can't be null");
        admin = _admin;
    }

    function newDeposit(address referrer) external payable {
        uint256 amount = msg.value;

        require(amount >= MIN_DEPOSIT, "Minimum deposit is 5 Matic");
        require(msg.sender != referrer,"The caller and ref address must be different");

        uint256 indexCap = 11;
        for (uint256 i = 0; i < 10; i++) {
            if (invests[msg.sender][i].deadline == 0) {
                indexCap = i;
                break;
            }
        }
        
        if (indexCap == 11) {
            if (!checkIfFundsWithrawned())
                revert("All deposits should be withdrawned before new investment");
            indexCap = 0;
            delete invests[msg.sender];
        }
        
        Investment storage invest = invests[msg.sender][indexCap];

        if (referrer != address(0) && refs[msg.sender][0] == address(0)) {
            refs[msg.sender][0] = referrer;
            sendRefBonus(payable(referrer), 0, amount);
            addReferrers(msg.sender, referrer, amount);
        }
        uint256 time = currentTime();
        invest.lastUpdate = time;
        invest.deadline = time + DEPOSIT_DAYS;
        invest.deposited = amount;

        emit Deposit(msg.sender, amount);

        sendTo(admin, amount * ADMIN_FEE_PERCENT / 100);

        totalInvested += amount;
    }

    function reinvestAll() external nonReentrant {        
        for (uint256 i = 0; i < 10; i++) {
            if(invests[msg.sender][i].deadline != 0) 
                _reinvest(i);   
            else 
                break;
        }
    }

    function reinvest(uint256 index) external checkIndex(index) checkDate(index)
        nonReentrant 
    {
        _reinvest(index);
    }

     function getAllDeposits(address investor) public view returns(Investment[10] memory) {
        return invests[investor];
    }

    function getCertainDeposit(address investor, uint256 index) public view checkIndex(index) returns(Investment memory) {
        return invests[investor][index];
    }

    function getRefsWallet(address wallet) public view returns(address[7] memory) {
        return refs[wallet];
    }

    function getRefsAmount(address wallet) public view returns(uint256[7] memory) {
        return refsAmount[wallet];
    }

    function calculateReward(address wallet) public view returns(uint256 totalReward) {
        for (uint256 i = 0; i < 10; i++) {
            if(invests[wallet][i].deadline != 0) {
                (uint256 reward,) = calculateRewardByIndex(wallet, i);
                totalReward += reward;
            }
            else {
                break;
            }
                
        }
    }

    function currentTime() public view returns(uint256) {
	    return block.timestamp + incTime;
    }

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function incrementShiftTime(uint256 shiftTime) public {
        incTime += shiftTime;
    }

    function _reinvest(uint256 index) private {
        Investment storage invest = invests[msg.sender][index];
        (uint256 reward, uint256 daysCount) = calculateRewardByIndex(msg.sender, index);
        if (reward >= MIN_REINVEST) {
            invests[msg.sender][index].lastUpdate += daysCount * 1 days;

            uint256 reinvested;
            uint256 send = reward * REINVEST_WITHDRAW_PERCENT / 100;
            sendTo(msg.sender, send);
            invest.withdrawals += send;
            totalWithdrawals += send;

            reinvested = reward * REINVEST_OF_PROFIT_PERCENT / 100;
            emit Reinvest(msg.sender, send, reinvested);
            totalReinvested += reinvested;
            invest.reinvested += reinvested;

            sendTo(admin, reward * REINVEST_FEE_PERCENT / 100);
        }

        if (invest.deposited > 0 && invest.lastUpdate >= invest.deadline) {
            returnDeposit(msg.sender, index);
        }
    }

    function checkIfFundsWithrawned() private view returns(bool) {
        Investment[10] storage invest = invests[msg.sender];
        for (uint256 i = 0; i < 10; i++) {
            if (invest[i].deposited == 0)
                continue;
            else
                return false;
        }
        return true;
    }

    function calculateRewardByIndex(address wallet, uint256 index) private view returns(uint256 reward, uint256 daysCount) {
        uint256 amount = invests[wallet][index].deposited + invests[wallet][index].reinvested;
        daysCount = checkDaysWithoutReward(wallet, index);
        reward = amount  * daysCount * DAILY_PROFIT_PERCENT / 100;
    }

    function checkDaysWithoutReward(address wallet, uint256 index) public view checkIndex(index) returns(uint256 _days) {
        uint256 deadline = invests[wallet][index].deadline;
        uint256 lastUpdate = invests[wallet][index].lastUpdate;
        uint256 nowTime = currentTime();

        if (deadline + DELAY_DAYS >= nowTime) {
            if (lastUpdate + DELAY_DAYS <= nowTime) {
                _days =  (nowTime - (lastUpdate + DELAY_DAYS)) / (1 days);
            }
        } else {
            _days =  (deadline - lastUpdate) / (1 days);
        }
    }

    function addReferrers(address investor, address _ref, uint256 amount) private {
        address[7] memory referrers = refs[_ref];
        for (uint256 i = 0; i < 6; i++) {
            if (referrers[i] != address(0)) {
                refs[investor][i+1] = referrers[i];
                sendRefBonus(payable(referrers[i]), i+1, amount);
            } else break;
        }
    }

    function sendRefBonus(address to, uint256 level, uint256 amount) private {
        uint256 bonus;
        if (level == 0)
            bonus = REF_LEVEL_1 * amount / 1000;
        else if (level == 1)
            bonus = REF_LEVEL_2 * amount / 1000;
        else if (level == 2)
            bonus = REF_LEVEL_3 * amount / 1000;
        else if (level == 3)
            bonus = REF_LEVEL_4 * amount / 1000;
        else if (level == 4)
            bonus = REF_LEVEL_5 * amount / 1000;
        else if (level == 5)
            bonus = REF_LEVEL_6 * amount / 1000;
        else if (level == 6)
            bonus = REF_LEVEL_7 * amount / 1000;

        sendTo(to, bonus);
        emit RefBonus(msg.sender, to, bonus);
        refsAmount[to][level] += bonus;
        totalReferralBonus += bonus;
    }

    function returnDeposit(address wallet, uint256 index) private {
        uint256 amount = invests[wallet][index].deposited + invests[wallet][index].reinvested;

        invests[wallet][index].deposited = 0;
        invests[wallet][index].reinvested = 0;
        invests[wallet][index].withdrawals += amount;

        totalWithdrawals += amount;

        sendTo(wallet, amount);
        emit ReturnDeposit(msg.sender, amount);
    }

    function sendTo(address to, uint256 amount) private {
        (bool transferSuccess, ) = payable(to).call{
                value: amount
            }("");
        require(transferSuccess, "Transfer failed");
        emit SendTo(to, amount);
    }
}