// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract Vesting {
    address owner;
    mapping(address=>uint256) vestedAmount;
    mapping(address=>mapping(uint256=> uint256)) public withdrawableAmount;
    mapping(address => mapping(uint256=> VestingSchedule)) public vestingSchedules;

    event DepositTokens(address _from,address _to,uint256 totalTokens);
    event VestedTokens(address _benificiary,uint256 vestedTopkens);
    event WithdrawTokens(address _to,uint256 amount);

    mapping(address=>uint256) totalVesting;


    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner,"Only Owner can access");
        _;
    }

    struct VestingSchedule {
        IERC20 _token;
        uint256 _startTime;
        uint256 _cliff;
        uint256 _vestingPeriod;
        uint256 _slicePeriod;
        uint256 _totalTokens;
        uint256 _releasedTokens;
        uint256 _vestedTokens;
        uint256 _elaspTime;
        uint256 _vestingID;
    }
    
    function addVestingTokens(address token,address benificiary,uint256 totalTokens, uint256 startTime,uint256 cliff,uint256 vestingPeriod,uint256 slicePeriod) public {
        vestingSchedules[benificiary][totalVesting[benificiary]] = VestingSchedule({
        _token : IERC20(token),
        _startTime : startTime,
        _cliff : cliff ,
        _vestingPeriod : vestingPeriod,
        _slicePeriod : slicePeriod,
        _totalTokens : totalTokens,   
        _releasedTokens : 0,
        _vestedTokens : 0 ,
        _elaspTime : 0,
        _vestingID : totalVesting[benificiary]
        });
       
        require(totalTokens>0,"Add some tokens");
        vestingSchedules[benificiary][totalVesting[benificiary]]._token.transferFrom(benificiary,address(this),totalTokens);
        totalVesting[benificiary]++;
        emit DepositTokens(benificiary,address(this),totalTokens);

    } 

    function checkBalance(address token,address account) view public returns(uint256){
        return IERC20(token).balanceOf(account);
    }

    function releaseTokens(address benificiary,uint256 vestingID) public onlyOwner returns(uint256) {
        withdrawableAmount[benificiary][vestingID]+=calculateVestedAmount(benificiary,vestingID);
        return withdrawableAmount[benificiary][vestingID];
    }

    function calculateVestedAmount(address benificiary,uint256 vestingID) public returns(uint256) {
        VestingSchedule storage schedule = vestingSchedules[benificiary][vestingID];

        require(schedule._startTime+schedule._slicePeriod <= block.timestamp,"No Token vested yet");
        
        uint256 intervals = (schedule._vestingPeriod) / (schedule._slicePeriod);
        uint256 tokensInInterval = schedule._totalTokens /intervals;

        uint256 currentTime = block.timestamp;   
        if(currentTime >= (schedule._startTime)+(schedule._vestingPeriod)){
            currentTime = (schedule._startTime)+(schedule._vestingPeriod);
        }                 
        schedule._elaspTime = currentTime - schedule._startTime;
        uint256 intervalElasped = schedule._elaspTime/ schedule._slicePeriod;
        
        schedule._vestedTokens = (intervalElasped * tokensInInterval)-schedule._releasedTokens;
        schedule._releasedTokens += schedule._vestedTokens;
        
        if(intervalElasped>=intervals){
            schedule._vestedTokens += schedule._totalTokens - schedule._releasedTokens;
        }
        
        vestedAmount[benificiary]=schedule._vestedTokens;
        

        emit VestedTokens(benificiary,schedule._vestedTokens);
        return schedule._vestedTokens;
    }

    function withdraw(address benificiary,uint256 withdrawAmount,uint256 vestingID ) public {
        require(benificiary == msg.sender,"Only benificiar can withdraw");
        require(withdrawableAmount[benificiary][vestingID]>0,"No amount to be withdrawn");
        withdrawableAmount[benificiary][vestingID]-=withdrawAmount;        
        vestingSchedules[benificiary][vestingID]._token.transfer(benificiary,withdrawAmount);     
        emit WithdrawTokens(benificiary,withdrawAmount);
    }
}