/**
 *Submitted for verification at polygonscan.com on 2022-03-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

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
     *
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    *
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

contract TestOne is Ownable {
    using SafeMath for uint256;

//    uint256 private constant PRIMARY_BENIFICIARY_INVESTMENT_PERC = 100;
//    uint256 private constant PRIMARY_BENIFICIARY_REINVESTMENT_PERC = 60;

    uint256 private constant MIN_WITHDRAW = 0.02 ether;
    uint256 private constant MIN_INVESTMENT = 1 ether;
    uint256 private constant TIME_STEP = 1 days;
	uint256 private constant PERCENTS_DIVIDER = 1000;
	uint256 private REFERENCE_RATE = 80;
	uint256[] private LOCK_DAYS = [7, 14, 28];
    uint256[] private YIELDS = [35, 50, 65];

    address payable private primaryBenificiary;

    struct Investor {
        address addr;
        address ref;
//        uint256[5] refs;
        uint256 totalDeposit;
        Investment[] investments;
        Referral[] referrals;
    }
    struct Investment {
        uint256 investmentDate;
        uint256 investment;
        uint256 lockPeriod;
        uint256 dividendCalculatedDate;
        uint256 dividend;
    }
    struct Referral {
        address refAddr ;
        uint256 rewardAmount;
        uint256 rewardDate;
    }

    mapping(address => Investor) public investors;

    event OnInvest(address investor, uint256 amount);
    event OnReinvest(address investor, uint256 amount);
	event OnWithdraw(address investor, uint256 amount); 

    constructor( address payable _primaryAddress ) {
        require( _primaryAddress != address(0), "Primary address cannot be null" );
        primaryBenificiary = _primaryAddress;
    }

    function changePrimaryBenificiary(address payable newAddress)
        public
        onlyOwner
    {
        require(newAddress != address(0), "Address cannot be null");
        primaryBenificiary = newAddress;
    }

    function invest(address payable _ref, uint256 _period) public payable {
        if (_invest(msg.sender, _ref, msg.value, _period)) {
            emit OnInvest(msg.sender, msg.value);
        }
    }

    function _invest(
        address _addr,
        address payable _ref,
        uint256 _amount,
        uint256 _period
    ) private returns (bool) {
        require(msg.value >= MIN_INVESTMENT, "Minimum investment is 1 Matic");
        require(_ref != _addr, "Ref address cannot be same with caller");
        uint256 _dividend;
        if (investors[_addr].addr == address(0)) {
        _addInvestor(_addr, _ref);
        }
        investors[_addr].totalDeposit = investors[_addr].totalDeposit.add(
            _amount
        );
        if (_period == 7) {
                   _dividend = _amount.mul(YIELDS[1]).mul(_period).div(1000);
               }
        if (_period == 14) {
                   _dividend = _amount.mul(YIELDS[2]).mul(_period).div(1000);
               }
        if (_period == 28) {
                   _dividend = _amount.mul(YIELDS[3]).mul(_period).div(1000);
               }
        investors[_addr].investments.push(
            Investment({
                investmentDate: block.timestamp,
                investment: _amount,
                lockPeriod: _period,
                dividendCalculatedDate: block.timestamp.add(_period),
                dividend: _dividend

            })
        );
        if (investors[_ref].addr == address(0)) {
        _addInvestor(_ref, _ref);
        } 

                investors[_ref].referrals.push(
            Referral({
                refAddr: _addr,
                rewardAmount: _amount.mul(REFERENCE_RATE).div(1000),
                rewardDate: block.timestamp

            })
        );

        _sendReferralReward(_ref, _amount);
        return true;
    }
  
    
    function _sendReferralReward(
        address payable _ref,
        uint256 _amount
    ) private {
        uint256 reward;
        reward = _amount.mul(REFERENCE_RATE).div(1000);        
        _ref.transfer(reward);
    }

    function _addInvestor(
        address _addr,
        address _ref
    ) private {
        investors[_addr].addr = _addr;
        investors[_addr].ref = _ref;
    }
// drip
    function sendReward(uint256 _rewardamount) public onlyOwner{
        require(_rewardamount > 0, "Amount must be greater than 0");
        primaryBenificiary.transfer(_rewardamount);
    }
/* 
    function withdraw() public {
		require(investors[msg.sender].lastWithdrawDate.add(TIME_STEP) <= block.timestamp,"Withdrawal limit is 1 withdrawal in 24 hours");
        uint256 _amountToReinvest=0;
		uint256 _reinvestAmount=0;
		uint256 totalToReinvest=0;
        uint256 max_payout = investors[msg.sender].totalDeposit.mul(TOTAL_RETURN).div(PERCENTS_DIVIDER);
        uint256 dividendAmount = getDividends(msg.sender);

        if(investors[msg.sender].totalWithdraw.add(dividendAmount) > max_payout) {
                dividendAmount = max_payout.subz(investors[msg.sender].totalWithdraw);
        }

        require(dividendAmount >= MIN_WITHDRAW, "min withdraw amount is 0.02 matic");

        //21% daily reinvestment
        _amountToReinvest = dividendAmount
                .mul(DAILY_AUTO_REINTEREST_RATE)
                .div(1000);

        //25% reinvest on withdraw
        _reinvestAmount = dividendAmount
            .mul(ON_WITHDRAW_AUTO_REINTEREST_RATE)
            .div(1000);

        totalToReinvest = _amountToReinvest.add(_reinvestAmount);

        _reinvest(msg.sender, totalToReinvest);

        uint256 remainingAmount = dividendAmount.subz(_reinvestAmount);
        
        totalWithdrawal = totalWithdrawal.add(remainingAmount);

        if(remainingAmount > getBalance()){
            remainingAmount = getBalance();
        }

        investors[msg.sender].totalWithdraw = investors[msg.sender].totalWithdraw.add(dividendAmount);
		investors[msg.sender].lastWithdrawDate = block.timestamp;
		investors[msg.sender].depositTime = block.timestamp;
		investors[msg.sender].dividends = 0;

        payable(msg.sender).transfer(remainingAmount);
		emit OnWithdraw(msg.sender, remainingAmount);
    }
*/
    function getInvestments(address addr)
        public
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        Investor storage investor = investors[addr];
        uint256[] memory investmentDates = new uint256[](
            investor.investments.length
        );
        uint256[] memory investments = new uint256[](
            investor.investments.length
        );
        uint256[] memory lockPeriods = new uint256[](
            investor.investments.length
        );
        uint256[] memory dividendCalculatedDates = new uint256[](
            investor.investments.length
        );
        uint256[] memory dividends = new uint256[](
            investor.investments.length
        );
        for (uint256 i; i < investor.investments.length; i++) {
            require(
                investor.investments[i].investmentDate != 0,
                "wrong investment date"
            );
            investmentDates[i] = investor.investments[i].investmentDate;
            investments[i] = investor.investments[i].investment;
            lockPeriods[i] = investor.investments[i].lockPeriod;
            dividendCalculatedDates[i] = investor.investments[i].dividendCalculatedDate;
            dividends[i] = investor.investments[i].dividend;
        }
        return (investmentDates, investments, lockPeriods, dividendCalculatedDates, dividends);
    }

    function getInvestorRefs(address addr)
        public
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        Investor storage investor = investors[addr];
        address[] memory refAddrs = new address[](
            investor.referrals.length
        );
        uint256[] memory rewardAmounts = new uint256[](
            investor.referrals.length
        );
        uint256[] memory rewardDates = new uint256[](
            investor.referrals.length
        );
        for (uint256 i; i < investor.referrals.length; i++) {
            require(
                investor.referrals[i].rewardDate != 0,
                "wrong investment date"
            );
            refAddrs[i] = investor.referrals[i].refAddr;
            rewardAmounts[i] = investor.referrals[i].rewardAmount;
            rewardDates[i] = investor.referrals[i].rewardDate;
        }
        return (refAddrs, rewardAmounts, rewardDates);
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