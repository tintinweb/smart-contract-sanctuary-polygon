// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./Owner.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

interface Referrals{
    function addReward1(address _referredAccount, uint256 _amount) external returns(uint256);
    function addReward2(address _referredAccount, uint256 _amount) external returns(uint256);
}

/**
 * @dev Contract for Staking ERC-20 Tokens and pay interest on real time
 */
contract StakeContract is Owner, ReentrancyGuard {
    
    // the token to be used for staking
    address public token;

    // referrals contract address 
    address public referrals;

    // Annual Percentage Yield
    uint256 public APY;

    // minimum stake time in seconds, if the user withdraws before this time a penalty will be charged
    uint256 public minimumStakeTime;

    // minimum withdraw time in seconds for next allow claim rewards
    uint256 public minimumWithdrawTime;

    // the Stake
    struct Stake {
        // opening timestamp
        uint256 startDate;
        // amount staked
    	uint256 amount;
        // last withdraw date of only rewards
        uint256 lastWithdrawDate;
        // is active or not
    	bool active;
    }

    // stakes that the owner have    
    mapping(address => Stake[50]) public stakesOf;

    event Set_TokenContracts(
        address token,
        address referrals
    );

    event Set_APY(
        uint256 APY
    );

    event Set_MST(
        uint256 MST
    );

    event Set_MWT(
        uint256 MWT
    );

    event AddedStake(
        uint256 startDate,
        uint256 amount,
        address indexed ownerStake
    );

    event WithdrawStake(
        uint256 withdrawType,
        uint256 startDate,
        uint256 withdrawDate,
        uint256 interest,
        uint256 amount,
        address indexed ownerStake
    );
    
    // @_token: the ERC20 token to be used
    // @param _apy: Annual Percentage Yield
    // @param _mst: minimum stake time in seconds
    // @param _mwt: minimum withdraw time in seconds for next allow claim rewards
    constructor(address _token, address _referrals, uint256 _apy, uint256 _mst, uint256 _mwt) {
        setTokenContracts(_token, _referrals);
        modifyAnnualInterestRatePercentage(_apy);
        modifyMinimumStakeTime(_mst);
        modifyMinimumWithdrawTime(_mwt);
    }
    
    function setTokenContracts(address _token, address _referrals) public isOwner {
        token = _token;
        referrals = _referrals;
        emit Set_TokenContracts(_token, _referrals);
    }
    function modifyAnnualInterestRatePercentage(uint256 _newVal) public isOwner {
        APY = _newVal;
        emit Set_APY(_newVal);
    }
    function modifyMinimumStakeTime(uint256 _newVal) public isOwner {
        minimumStakeTime = _newVal;
        emit Set_MST(_newVal);
    }
    function modifyMinimumWithdrawTime(uint256 _newVal) public isOwner {
        minimumWithdrawTime = _newVal;
        emit Set_MWT(_newVal);
    }

    function calculateInterest(address _ownerAccount, uint256 i) private view returns (uint256) {

        // APY per year = amount * APY / 100 / seconds of the year
        uint256 interest_per_year = (stakesOf[_ownerAccount][i].amount*APY)/100;

        // number of seconds since opening date
        uint256 num_seconds = block.timestamp-stakesOf[_ownerAccount][i].lastWithdrawDate;

        // calculate interest by a rule of three
        //  seconds of the year: 31536000 = 365*24*60*60
        //  interest_per_year   -   31536000
        //  interest            -   num_seconds
        //  interest = num_seconds * interest_per_year / 31536000
        return (num_seconds*interest_per_year)/31536000;
    }

    function getIndexToCreateStake(address _account) private view returns (uint256) {
        uint256 index = 50;
        for(uint256 i=0; i<stakesOf[_account].length; i++){
            if(!stakesOf[_account][i].active){
                index = i;
            }
        }
        // if (index < 50)  = limit not reached
        // if (index == 50) = limit reached
        return index; 
    }
    
    // anyone can create a stake
    function createStake(uint256 amount) external {
        uint256 index = getIndexToCreateStake(msg.sender);
        require(index < 50, "stakes limit reached");
        // store the tokens of the user in the contract
        // requires approve
		IERC20(token).transferFrom(msg.sender, address(this), amount);
        // create the stake
        stakesOf[msg.sender][index] = Stake(block.timestamp, amount, block.timestamp, true);

        emit AddedStake(block.timestamp, amount, msg.sender);
    }

    // _arrayIndex: is the id of the stake to be finalized
    function withdrawStake(uint256 _arrayIndex, uint256 _withdrawType) external nonReentrant { // _withdrawType (1=normal withdraw, 2=withdraw only rewards)
        require(_withdrawType>=1 && _withdrawType<=2, "invalid _withdrawType");
        // Stake should exists and opened
        require(_arrayIndex < stakesOf[msg.sender].length, "Stake does not exist");
        Stake memory stk = stakesOf[msg.sender][_arrayIndex];
        require(stk.active, "This stake is not active");

        // get interest
        uint256 interest = calculateInterest(msg.sender, _arrayIndex);
        
        if(_withdrawType == 1){
            require((block.timestamp - stk.startDate) >= minimumStakeTime, "the minimum stake time has not been completed yet");
            IERC20(token).transfer(msg.sender, stk.amount);
            // stake closing
            delete stakesOf[msg.sender][_arrayIndex];
        }else{
            require((block.timestamp - stk.lastWithdrawDate) >= minimumWithdrawTime, "the minimum withdraw time has not been completed yet");
            // record the transaction
            stakesOf[msg.sender][_arrayIndex].lastWithdrawDate = block.timestamp;
        }
        
        // pay interest and rewards
        interest = interest - Referrals(referrals).addReward2(msg.sender, interest);
        IERC20(token).transferFrom(getOwner(), msg.sender, interest);
        
        emit WithdrawStake(_withdrawType, stk.startDate, block.timestamp, interest, stk.amount, msg.sender);
    }

    function getStakesOf(address _account) external view returns(uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, bool[] memory){
        uint256 stakesLength = stakesOf[_account].length;
        uint256[] memory startDateList = new uint256[](stakesLength);
        uint256[] memory amountList = new uint256[](stakesLength);
        uint256[] memory interestList = new uint256[](stakesLength);
        uint256[] memory minimumWithdrawDateList = new uint256[](stakesLength);
        bool[] memory activeList = new bool[](stakesLength);

        for(uint256 i=0; i<stakesLength; i++){
            Stake memory stk = stakesOf[_account][i];
            startDateList[i] = stk.startDate;
            amountList[i] = stk.amount;
            interestList[i] = calculateInterest(_account, i);
            minimumWithdrawDateList[i] = stk.lastWithdrawDate + minimumWithdrawTime;
            activeList[i] = stk.active;
        }

        return (startDateList, amountList, interestList, minimumWithdrawDateList, activeList);
    }
    
}