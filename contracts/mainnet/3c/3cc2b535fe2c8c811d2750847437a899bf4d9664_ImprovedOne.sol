/**
 *Submitted for verification at polygonscan.com on 2022-02-23
*/

// Join Us On
//Website: https://ShopkeeperContract.com
//Telegram: https://t.me/ShopkeeperContract
//Twitter: https://twitter.com/Shopkeeper_Ctrt
//Earn 7% Yeild Daily
//Compound Your Principal by 21% Every 5 days (if No withdraw within time period)
//Refer to earn upto 9.5% on each referal down till 3 levels

//Improved roiContract, optimized the gas guzzling logic 
// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

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


contract ImprovedOne is ReentrancyGuard {
    using SafeMath for uint256;
    address public owner;
    uint256 private constant PRIMARY_BENIFICIARY_INVESTMENT_PERC = 100;

    uint256 private constant TIME_STEP_DRAW = 1 days;
    uint256 private constant DAILY_INTEREST_RATE = 70;
    uint256 private constant COMPOUND_ON_NO_WITHDRAW = 21; //Compound
    uint256 private constant ON_WITHDRAW_AUTO_REINTEREST_RATE = 250;
    uint256 private constant MIN_WITHDRAW = 0.02 ether;
    uint256 private constant MIN_INVESTMENT = 0.05 ether; 

    bool private depositStarted = false;
    uint256 private constant REFERENCE_LEVEL1_RATE = 50;
    uint256 private constant REFERENCE_LEVEL2_RATE = 30;
    uint256 private constant REFERENCE_LEVEL3_RATE = 15;
    address payable public primaryBenificiary;
    uint256 public totalInvested;
    uint256 public activeInvested;
    uint256 public totalWithdrawal;
    uint256 public totalReinvested;
    uint256 public totalReferralReward;

    struct Investor {
        address addr;
        address ref;    //reffeeral address
        uint256[3] refs;
        uint256 totalDeposit;
        uint256 totalWithdraw;
        uint256 totalReinvest; //totalCompound
        uint256 lastDepositDate;        
        uint256 principle;              
        uint256 lastWithdrawalDate;
        uint256 withdrawable;
    }

    //plan_term = infinte 

    mapping(address => Investor) public investors;
    event OnInvest(address investor, uint256 amount);
    event OnReinvest(address investor, uint256 amount);
    constructor(
        address payable _primaryAddress
    ) {
        require(
            _primaryAddress != address(0),
            "Primary or Secondary address cannot be null"
        );
        primaryBenificiary = _primaryAddress;
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(
            owner == msg.sender,
            "Only owner is authorized for this option"
        );
        _;
    }

    function changePrimaryBenificiary(address payable newAddress)
        external
        onlyOwner
    {
        require(newAddress != address(0), "Address cannot be null");
        primaryBenificiary = newAddress;
    }

    function invest(address _ref) external payable {
        require(depositStarted,"Deposit not started");
        emit OnInvest(msg.sender, msg.value);
        _invest(msg.sender, _ref, msg.value);
    }
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function _invest(
        address _addr,
        address _ref,
        uint256 _amount
    ) private {
        require(msg.value >= MIN_INVESTMENT, "Minimum investment is 0.05 Matic");
        require(_ref != _addr, "Ref address cannot be same with caller");
        if (investors[_addr].addr == address(0)) {
            _addInvestor(_addr, _ref);
            investors[_addr].lastWithdrawalDate = block.timestamp;
        } else {
            // calculate old earned and transfer to details.withdrawble
            uint256 additional = getDividends(_addr);
            investors[_addr].lastDepositDate = block.timestamp;
            investors[_addr].withdrawable += additional;
            // return on deposit till date is in withdrawable
        }
        
        //increase totalDeposit and principle
        investors[_addr].totalDeposit = investors[_addr].totalDeposit.add(
            _amount
        );
        investors[_addr].principle = investors[_addr].principle.add(
            _amount
            );
        totalInvested = totalInvested.add(_amount);
        activeInvested = activeInvested.add(_amount);
        // Adding Refferal to all on each deposit
        address refAddr = investors[_addr].ref;
        for (uint256 i = 0; i < 3; i++) {
            if (investors[refAddr].addr != address(0)) {
                investors[refAddr].refs[i] = investors[refAddr].refs[i].add(1);
                _sendReferralReward(payable(refAddr), (i + 1), _amount);
            } else break;
            refAddr = investors[refAddr].ref;
        }        
        _sendRewardOnInvestment(_amount);
    }
    function _sendReferralReward(
        address payable _ref,
        uint256 level,
        uint256 _amount
    ) private {
        uint256 reward =0;
        if (level == 1) {
            reward = _amount.mul(REFERENCE_LEVEL1_RATE).div(1000);
        } else if (level == 2) {
            reward = _amount.mul(REFERENCE_LEVEL2_RATE).div(1000);
        } else if (level == 3) {
            reward = _amount.mul(REFERENCE_LEVEL3_RATE).div(1000);
        }
        totalReferralReward = totalReferralReward.add(reward);
        _ref.transfer(reward);
    }

    
    function _reinvest(address _addr, uint256 _amount,bool isWithdraw) private returns (bool) {     //Compound principle
        if(!isWithdraw){
        require(investors[_addr].lastWithdrawalDate <= (block.timestamp - 5 days), "Compound possible only after 5 days of no withdrwal");
        }

        // can be put in a function     updatePrinciple()
        investors[_addr].withdrawable += getDividends(_addr);
        investors[_addr].lastWithdrawalDate = block.timestamp;
        investors[_addr].lastDepositDate = block.timestamp;
        investors[_addr].principle = investors[_addr].principle.add(_amount);
        investors[_addr].totalReinvest = investors[_addr].totalReinvest.add(
            _amount
        );
        totalReinvested = totalReinvested.add(_amount);
        return true;
    }

    function _addInvestor(
        address _addr,
        address _ref
    ) private {
        investors[_addr].addr = _addr;
        investors[_addr].ref = _ref;
        investors[_addr].lastDepositDate = block.timestamp;
    }
    function _sendRewardOnInvestment(uint256 _amount) private {
        require(_amount > 0, "Amount must be greater than 0");
        uint256 rewardForPrimaryBenificiary = _amount
            .mul(PRIMARY_BENIFICIARY_INVESTMENT_PERC)
            .div(1000);
        primaryBenificiary.transfer(rewardForPrimaryBenificiary);
    }
    function getInvestorRefs(address addr)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        Investor storage investor = investors[addr];
        return (
            investor.refs[0],
            investor.refs[1],
            investor.refs[2]
        );
    }
    function getDividends(address _addr) public view returns (uint256) { // readonly getWithdrawable balance
        return (
            ((investors[_addr].principle * DAILY_INTEREST_RATE) * (block.timestamp - investors[_addr].lastDepositDate))/(TIME_STEP_DRAW*1000)
        );
    }

    function getWithdrawable(address _addr) external view returns (uint256){
        return (
            (getDividends(_addr) + investors[_addr].withdrawable)
        );
    }

    function calculateDividendsAndautoReinvest() external { //compound principle
            address addr = msg.sender;
            uint256 amountToReinvest = (investors[addr].principle * COMPOUND_ON_NO_WITHDRAW)/100;
            if (_reinvest(addr, amountToReinvest,false)) {
                emit OnInvest(addr, amountToReinvest);
            }
    }

    function withdraw() external nonReentrant {
        require(block.timestamp > investors[msg.sender].lastWithdrawalDate + 1 hours);
        uint256 dividends = getDividends(msg.sender) + investors[msg.sender].withdrawable;
        require(
            dividends >= MIN_WITHDRAW,
            "Cannot withdraw less than 0.02 Matic"
        );
        uint256 reinvestAmount = dividends
            .mul(ON_WITHDRAW_AUTO_REINTEREST_RATE)
            .div(1000);
        _reinvest(msg.sender, reinvestAmount, true);
        uint256 remainingAmount = dividends.subz(reinvestAmount);
        // Withdrawal date save
        investors[msg.sender].lastWithdrawalDate = block.timestamp;
        totalWithdrawal = totalWithdrawal.add(remainingAmount);
        investors[msg.sender].totalWithdraw = remainingAmount;
        investors[msg.sender].withdrawable = 0;
        payable(msg.sender).transfer(remainingAmount);
    }
    function getContractInformation()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 contractBalance = getBalance();
        return (
            contractBalance,
            totalInvested,
            activeInvested,
            totalWithdrawal,
            totalReinvested,
            totalReferralReward
        );
    }
    function toggleDeposit() external onlyOwner {
        depositStarted = !depositStarted;
    }
}


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function subz(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b >= a) {
            return 0;
        }
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}