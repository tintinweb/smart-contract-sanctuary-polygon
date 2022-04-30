/**
 *Submitted for verification at polygonscan.com on 2022-04-30
*/

/*

* @dev This is the Axia Protocol Staking pool  contract, 
* a part of the protocol where stakers are rewarded in AXIA tokens 
* when they make stakes of liquidity tokens from the community pool.

* stakers reward come from the daily emission from the total supply into circulation,
* this happens daily and upon the reach of a new epoch each made of 180 days, 
* halvings are experienced on the emitting amount of tokens.

* on the 11th epoch all the tokens would have been completed emitted into circulation,
* from here on, the stakers will still be earning from daily emissions
* which would now be coming from the accumulated basis points over the epochs.

* stakers are not charged any fee for unstaking.

*/
pragma solidity 0.6.4;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function userDataA(address _user) external view returns (uint256 a, uint256 b, uint256 c, uint256 d, uint256 e);
    function userDataB(address _user) external view returns (uint256 a, uint256 b, uint256 c, uint256 d, uint256 e);
    function userDataC(address _user) external view returns (uint256 a, uint256 b, uint256 c, uint256 d, uint256 e);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
 
    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}



contract CommunityPoolTS{
    
    using SafeMath for uint256;
    
//======================================EVENTS=========================================//
    event StakeEvent(address indexed staker, address indexed pool, uint amount);
    event UnstakeEvent(address indexed unstaker, address indexed pool, uint amount);
    event RewardEvent(address indexed staker, address indexed pool, uint amount);
    
    
    
//======================================STAKING POOLS=========================================//
    address public Axiatoken;
    address public IndexFunds;
    address public Distributor;
    
    address public administrator;
    
    bool public stakingEnabled;
    
    uint256 constant private FLOAT_SCALAR = 2**64;
    uint256 public MINIMUM_STAKE = 1000000000000000000; // 1 minimum
	uint256  public MIN_DIVIDENDS_DUR = 18 hours;
    uint private decimal = 10**18;
	
	uint public infocheck;
	uint public totalRewarded;
    bool public enableChecks;
    uint public poolGeneralAccess; 

    mapping(address=>bool) public _Whitelisted;

    mapping(uint=>uint) public cardTypeEntryTime;
    mapping(address=>uint) public EntryTimeByAdmin;

    bool public ActivationCheck = true;
    
    struct User {
		uint256 balance;
		uint256 frozen;
		int256 scaledPayout;
		uint256 staketime;
	}

	struct Info {
		uint256 totalSupply;
		uint256 totalFrozen;
		mapping(address => User) users;
		uint256 scaledPayoutPerToken;
		address admin;
	}
	
	Info private info;
    
	
	
	constructor() public {
	    
        info.admin = msg.sender;
        stakingEnabled = false;
	}

//======================================ADMINSTRATION=========================================//

	modifier onlyCreator() {
        require(msg.sender == info.admin, "Ownable: caller is not the administrator");
        _;
    }
    
    modifier onlyDistributor() {
        require(msg.sender == Distributor, "Authorization: only distributor contract can call");
        _;
    }
    
    
	 function tokenconfigs(address _axiatoken, address _indexfund) public onlyCreator returns (bool success) {
	    require(_axiatoken != _indexfund, "Insertion of same address is not supported");
	    require(_axiatoken != address(0) && _indexfund != address(0), "Insertion of address(0) is not supported");
        Axiatoken = _axiatoken;
        IndexFunds = _indexfund;
        return true;
    }
    
    function Distributorconfigs(address _distributor) public onlyCreator returns (bool success) {
	    require(_distributor != address(0), "Insertion of address(0) is not supported");
        Distributor = _distributor;
        return true;
    }
	
	function _minStakeAmount(uint256 _number) onlyCreator public {
		
		MINIMUM_STAKE = _number*decimal;
		
	}
	

    function ActivationCheckStatus(bool _status) onlyCreator public {
		
		ActivationCheck = _status;
		
	}

    function whitelistandEntryTimeByAdmin(address _user, bool _status, uint _entrytime) onlyCreator public {

        _Whitelisted[_user] = _status;
        EntryTimeByAdmin[_user] = _entrytime;
    }


    function cardTypeEntryTimeGeneral(uint _entrytimeKey, uint _entrytimeValue) onlyCreator public {
        cardTypeEntryTime[_entrytimeKey] = _entrytimeValue;
    }

	function stakingStatus(bool _status) public onlyCreator {
	require(Axiatoken != address(0) && IndexFunds != address(0), "Pool addresses are not yet setup");
	stakingEnabled = _status;
    }
    
    function MIN_DIVIDENDS_DUR_TIME(uint256 _minDuration) public onlyCreator {
        
	MIN_DIVIDENDS_DUR = _minDuration;
	
    }

    function poolGeneralAccessSetup(uint256 _generalAccessTime) public onlyCreator {
        
	poolGeneralAccess = _generalAccessTime;
	
    }
//======================================USER WRITE=========================================//

	function StakeTokens(uint256 _tokens) external {
        
       if(ActivationCheck){

           if(block.timestamp >= poolGeneralAccess){

           _stake(_tokens); 
           

           }else{

                if(_Whitelisted[msg.sender]){
                require(block.timestamp >= EntryTimeByAdmin[msg.sender], "you have been whitelisted for entry at a time yet to be fullfilled"); 
                _stake(_tokens);

                }else{
                
                require(block.timestamp >= ActivationCheckandEntryTime(msg.sender), "You cannot access this pool yet, wait for you card category entry time");
                _stake(_tokens); 
              
            }

           }
           
        }else{ _stake(_tokens);}
		
	}

    
    function ActivationCheckandEntryTime(address _user) public view returns(uint){
       
        (, uint diamondcard, , , ) = IERC20(Axiatoken).userDataA(_user);
        (, uint platinumcard, , , ) = IERC20(Axiatoken).userDataB(_user);
        (, uint goldcard, , , ) = IERC20(Axiatoken).userDataC(_user);
        
        if(diamondcard >= 1*decimal){ //diamondcard
            return(cardTypeEntryTime[1]);
        }else if(platinumcard >= 1*decimal){ //platinum
            return(cardTypeEntryTime[2]);
        }else if(goldcard >= 1*decimal){ //gold
            return(cardTypeEntryTime[3]);
        }else{
            return(cardTypeEntryTime[0]); 
            
        }
    }

	
	function UnstakeTokens(uint256 _tokens) external {
		_unstake(_tokens);
	}
    

//======================================USER READ=========================================//

	function totalFrozen() public view returns (uint256) {
		return info.totalFrozen;
	}
	
    function frozenOf(address _user) public view returns (uint256) {
		return info.users[_user].frozen;
	}

	function dividendsOf(address _user) public view returns (uint256) {
	    
	    uint Timedifference = now - info.users[_user].staketime;
	    
	    if(Timedifference <  MIN_DIVIDENDS_DUR){
	        return 0;
	    }else{
	        return uint256(int256(info.scaledPayoutPerToken * info.users[_user].frozen) - info.users[_user].scaledPayout) / FLOAT_SCALAR;   
	    }
	}
	

	function userData(address _user) public view 
	returns (uint256 totalTokensFrozen, uint256 userFrozen, 
	uint256 userDividends, uint256 userStaketime, int256 scaledPayout) {
	    
		return (totalFrozen(), frozenOf(_user), dividendsOf(_user), info.users[_user].staketime, info.users[_user].scaledPayout);
	}
	
    
    

//======================================ACTION CALLS=========================================//	
	
	function _stake(uint256 _amount) internal {
	    
	    require(stakingEnabled, "Staking not yet initialized");
	    
		require(IERC20(IndexFunds).balanceOf(msg.sender) >= _amount, "Insufficient AFT token balance");
		require(frozenOf(msg.sender) + _amount >= MINIMUM_STAKE, "Your amount is lower than the minimum amount allowed to stake");
		require(IERC20(IndexFunds).allowance(msg.sender, address(this)) >= _amount, "Not enough allowance given to contract yet to spend by user");
		
		info.users[msg.sender].staketime = now;
		info.totalFrozen += _amount;
		info.users[msg.sender].frozen += _amount;
		
		info.users[msg.sender].scaledPayout += int256(_amount * info.scaledPayoutPerToken); 
		IERC20(IndexFunds).transferFrom(msg.sender, address(this), _amount);      
		
        emit StakeEvent(msg.sender, address(this), _amount);
	}
	
 
	function _unstake(uint256 _amount) internal {
	    
	    TakeDividends();
		require(frozenOf(msg.sender) >= _amount, "You currently do not have up to that amount staked");
		
		info.totalFrozen -= _amount;
		info.users[msg.sender].frozen -= _amount;
		info.users[msg.sender].scaledPayout -= int256(_amount * info.scaledPayoutPerToken);
		
		require(IERC20(IndexFunds).transfer(msg.sender, _amount), "Transaction failed");
        emit UnstakeEvent(address(this), msg.sender, _amount);
        
        
		
	}
	
		
	function TakeDividends() public returns (uint256) {
		    
		uint256 _dividends = dividendsOf(msg.sender);
		require(_dividends > 0, "you do not have any dividend yet");
		info.users[msg.sender].scaledPayout += int256(_dividends * FLOAT_SCALAR);
		
		require(IERC20(Axiatoken).transfer(msg.sender, _dividends), "Transaction Failed");    // Transfer dividends to msg.sender
		emit RewardEvent(msg.sender, address(this), _dividends);
		return _dividends;
	    
		    
	}
	
 
    function scaledToken(uint _amount) external onlyDistributor returns(bool){
            totalRewarded += _amount;
    		info.scaledPayoutPerToken += _amount * FLOAT_SCALAR / info.totalFrozen;
    		infocheck = info.scaledPayoutPerToken;
    		return true;
            
    }
    
    
    function scaledReward(uint _amount) external onlyDistributor returns(bool){
            totalRewarded -= _amount;
    		return true;
            
    }
 
        
    function mulDiv (uint x, uint y, uint z) public pure returns (uint) {
          (uint l, uint h) = fullMul (x, y);
          assert (h < z);
          uint mm = mulmod (x, y, z);
          if (mm > l) h -= 1;
          l -= mm;
          uint pow2 = z & -z;
          z /= pow2;
          l /= pow2;
          l += h * ((-pow2) / pow2 + 1);
          uint r = 1;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          return l * r;
    }
    
     function fullMul (uint x, uint y) private pure returns (uint l, uint h) {
          uint mm = mulmod (x, y, uint (-1));
          l = x * y;
          h = mm - l;
          if (mm < l) h -= 1;
    }
 
    
}