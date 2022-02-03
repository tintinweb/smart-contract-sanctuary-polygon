/**
 *Submitted for verification at polygonscan.com on 2022-02-03
*/

// Forge Rewards Contract
// Recieves 25% or 10,500,000 Forge Tokens from the ForgeMining Contract over 100+ years.
// Also recieve 33% of the 0xBitcoin Tokens from the ForgeMining Contract over forever.


// What we are staking:  Forge/0xBitcoin Liquidity Pool Tokens
//What is it?  It is the pool traders use to buy and sell the coin
//The larger the pool, the larger the order the token can handle

//
//Rewards: Forge, 0xBitcoin, and Polygon currently.
// Funds gathered will be dispered over 21 days. 21 Day reward period
//Room to Expand to three other cryptocurrencies(Only admin function in all three contracts is to add up to three more cryptocurrencies!)

pragma solidity ^0.8.11;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
 
contract Ownable2 {
    address public owner;
    address [] public moderators;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
    modifier OnlyModerators() {
    bool isModerator = false;
    for(uint x=0; x< moderators.length; x++){
    	if(moderators[x] == msg.sender){
		isModerator = true;
		}
		}
        require(msg.sender == owner || isModerator, "Ownable: caller is not the owner/mod");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */

    function Z_addMod(address newModerator, uint spot) public onlyOwner {
    if(spot >= moderators.length){
    	moderators.push(newModerator);
	}else{
	moderators[spot] = newModerator;
	}
    }
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function Z_transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StakedTokenWrapper {
    uint256 public totalSupply;

    mapping(address => uint256) private _balances;
    IERC20 public stakedToken;
    
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    string constant _transferErrorMessage = "staked token transfer failed";
    
    function stakeFor(address forWhom, uint128 amount) public payable virtual {
        IERC20 st = stakedToken;
        if(st == IERC20(address(0))) { //eth
            unchecked {
                totalSupply += msg.value;
                _balances[forWhom] += msg.value;
            }
        }
        else {
            require(msg.value == 0, "non-zero eth");
            require(amount > 0, "Cannot stake 0");
            require(st.transferFrom(msg.sender, address(this), amount), _transferErrorMessage);
            unchecked { 
                totalSupply += amount;
                _balances[forWhom] += amount;
            }
        }
        emit Staked(forWhom, amount);
    }

    function withdraw(uint128 amount) public virtual {
        require(amount <= _balances[msg.sender], "withdraw: balance is lower");
        unchecked {
            _balances[msg.sender] -= amount;
            totalSupply = totalSupply-amount;
        }
        IERC20 st = stakedToken;
        if(st == IERC20(address(0))) { //eth
            (bool success, ) = msg.sender.call{value: amount}("");
            require(success, "eth transfer failure");
        }
        else {
            require(stakedToken.transfer(msg.sender, amount), _transferErrorMessage);
        }
        emit Withdrawn(msg.sender, amount);
    }
}

contract ForgeRewards is StakedTokenWrapper, Ownable2 {
    bool activated6 = false;
    bool activated5 = false;
    bool activated4 = false;
    uint256 public decimalsExtra=18;
    uint256 public decimalsExtraExtra=18;
    uint256 public decimalsExtraExtra2=18;
    uint64 public poolLength = 5; //7 Day reward periods
    uint256 public totalRewarded;
    uint256 public totalRewarded2;
    uint256 public totalRewarded3;
    uint256 public totalRewardedExtra;
    uint256 public totalRewardedExtraExtra;
    uint256 public totalRewardedExtraExtra2;
    address[] public AddressesEntered;
    IERC20 public rewardTokenExtraExtra2;
    IERC20 public rewardTokenExtraExtra;
    IERC20 public rewardTokenExtra;
    IERC20 public rewardToken2;
    IERC20 public rewardToken;
    uint256 public rewardRate;
    uint256 public rewardRate2;
    uint256 public rewardRate3;
    uint256 public rewardRateExtra;
    uint256 public rewardRateExtraExtra;
    uint256 public rewardRateExtraExtra2;
    uint64 public periodFinish;
    uint64 public periodFinish2;
    uint64 public periodFinish3;
    uint64 public periodFinishExtra;
    uint64 public periodFinishExtraExtra;
    uint64 public periodFinishExtraExtra2;
    uint64 public lastUpdateTime;
    uint64 public lastUpdateTime2;
    uint64 public lastUpdateTime3;
    uint64 public lastUpdateTimeExtra;
    uint64 public lastUpdateTimeExtraExtra;
    uint64 public lastUpdateTimeExtraExtra2;

    uint128 public rewardPerTokenStored;
    uint128 public rewardPerTokenStored2;
    uint128 public rewardPerTokenStored3;
    uint128 public rewardPerTokenStoredExtra;
    uint128 public rewardPerTokenStoredExtraExtra;
    uint128 public rewardPerTokenStoredExtraExtra2;
	
    struct UserRewards {
        uint128 userRewardPerTokenPaid;
        uint128 rewards;
    }
	
    struct UserRewards2 {
        uint128 userRewardPerTokenPaid2;
        uint128 rewards2;
    }
	
    struct UserRewards3 {
        uint128 userRewardPerTokenPaid3;
        uint128 rewards3;
    }
	
    struct UserRewardsExtra {
        uint128 userRewardPerTokenPaidExtra;
        uint128 rewardsExtra;
    }
    
    struct UserRewardsExtraExtra {
        uint128 userRewardPerTokenPaidExtraExtra;
        uint128 rewardsExtraExtra;
    }
	
    struct UserRewardsExtraExtra2 {
        uint128 userRewardPerTokenPaidExtraExtra2;
        uint128 rewardsExtraExtra2;
    }
	
    mapping(address => UserRewards) public userRewards;
    mapping(address => UserRewards2) public userRewards2;
    mapping(address => UserRewards3) public userRewards3;
    mapping(address => UserRewardsExtra) public userRewardsExtra;
    mapping(address => UserRewardsExtraExtra) public userRewardsExtraExtra;
    mapping(address => UserRewardsExtraExtra2) public userRewardsExtraExtra2;

    event RewardPaid(address indexed user, uint256 reward, uint256 rewards2, uint256 rewards3, uint256 rewardsExtra, uint256 rewardsExtraExtra, uint256 rewardsExtraExtra2);

    event RewardAdded(uint256 reward);
    event RewardAdded2(uint256 rewards2);
    event RewardPaidBasic(address indexed user, uint256 reward1, uint256 rewards2);

    event RewardAdded3(uint256 rewards3);
    event RewardPaid3(address indexed user, uint256 rewards3);

    
    event RewardAdded4(uint256 rewards4);
    event RewardPaidExtra(address indexed user, uint256 rewardsExtra);

    event RewardAdded5(uint256 rewards5);
    event RewardPaidExtraExtra(address indexed user, uint256 rewardsExtraExtra);

    event RewardAdded6(uint256 rewards6);
    event RewardPaidExtraExtra2(address indexed userExtraExtra, uint256 rewardsExtraExtra);

    constructor(IERC20 _rewardForge, IERC20 _LP, IERC20 _reward0xBTC) {
        rewardToken = _rewardForge;
        stakedToken = _LP;
        rewardToken2 = _reward0xBTC;
    }


    function Z_NewRewardTime( uint64 _rewardT) external OnlyModerators returns (bool success){
    	require( _rewardT >= 60*60*24*7 && _rewardT <= 60*60*24*62, "Reward must stay within boundaries");
	    poolLength = _rewardT;
	}


    function Z_addNewToken(IERC20 tokenExtra, uint _decimalsExtra) external OnlyModerators returns (bool success){
    	require(tokenExtra != rewardToken && tokenExtra != stakedToken && tokenExtra != rewardToken2 && tokenExtra != rewardTokenExtraExtra && tokenExtra != rewardTokenExtra && tokenExtra != rewardTokenExtraExtra2, "no same token");
	require(!activated4, "Only allowed to add one token");
        decimalsExtra = _decimalsExtra;
        rewardRateExtra = 0;
        rewardTokenExtra = tokenExtra;
        activated4 = true;

        return true;
    }
	

    function Z_addNewToken2(IERC20 tokenTWOExtra, uint _decimalsExtraExtra) external OnlyModerators returns (bool success){
	require(tokenTWOExtra != rewardToken && tokenTWOExtra != stakedToken && tokenTWOExtra != rewardToken2 && tokenTWOExtra != rewardTokenExtra && tokenTWOExtra != rewardTokenExtraExtra && tokenTWOExtra != rewardTokenExtraExtra2, "no same token");
	require(!activated5, "Only allowed to add one token");
        decimalsExtraExtra = _decimalsExtraExtra;
        rewardRateExtraExtra = 0;
        rewardTokenExtraExtra = tokenTWOExtra;
        activated5 = true;
	
        return true;
    }
        
    function Z_addNewToken3(IERC20 tokenTWOExtra2, uint _decimalsExtraExtra2) external OnlyModerators returns (bool success){
	require(tokenTWOExtra2 != rewardToken && tokenTWOExtra2 != stakedToken && tokenTWOExtra2 != rewardToken2 && tokenTWOExtra2 != rewardTokenExtra && tokenTWOExtra2 != rewardTokenExtraExtra && tokenTWOExtra2 != rewardTokenExtraExtra2, "no same token");
	require(!activated6, "Only allowed to add one token");
        decimalsExtraExtra2 = _decimalsExtraExtra2;
        rewardRateExtraExtra2 = 0;
        rewardTokenExtraExtra2 = tokenTWOExtra2;
        activated6 = true;
	
        return true;
    }
        

    modifier updateReward(address account) {
        uint128 _rewardPerTokenStored = rewardPerToken();
        uint128 _rewardPerTokenStored2 = rewardPerToken2(); 
        uint128 _rewardPerTokenStored3 = rewardPerToken3(); 
        uint128 _rewardPerTokenStoredExtra = rewardPerTokenExtra(); 
        uint128 _rewardPerTokenStoredExtraExtra = rewardPerTokenExtraExtra(); 
        uint128 _rewardPerTokenStoredExtraExtra2 = rewardPerTokenExtraExtra2(); 

        lastUpdateTime = lastTimeRewardApplicable();
        lastUpdateTime2 = lastTimeRewardApplicable2();
        lastUpdateTime3 = lastTimeRewardApplicable3();
        lastUpdateTimeExtra = lastTimeRewardApplicableExtra();
        lastUpdateTimeExtraExtra = lastTimeRewardApplicableExtraExtra();
        lastUpdateTimeExtraExtra2 = lastTimeRewardApplicableExtraExtra2();
	
        rewardPerTokenStored = _rewardPerTokenStored;
        rewardPerTokenStored2 = _rewardPerTokenStored2;
        rewardPerTokenStored3 = _rewardPerTokenStored3;
        rewardPerTokenStoredExtra = _rewardPerTokenStoredExtra;
        rewardPerTokenStoredExtraExtra = _rewardPerTokenStoredExtraExtra;
        rewardPerTokenStoredExtraExtra2 = _rewardPerTokenStoredExtraExtra2;
	
        userRewards[account].rewards = earned(account);
        userRewards2[account].rewards2 = earned2(account);
        userRewards3[account].rewards3 = earned3(account);
        userRewardsExtra[account].rewardsExtra = earnedExtra(account);
        userRewardsExtraExtra[account].rewardsExtraExtra = earnedExtraExtra(account);
        userRewardsExtraExtra2[account].rewardsExtraExtra2 = earnedExtraExtra2(account);
	
        userRewards[account].userRewardPerTokenPaid = _rewardPerTokenStored;
        userRewards2[account].userRewardPerTokenPaid2 = _rewardPerTokenStored2;
        userRewards3[account].userRewardPerTokenPaid3 = _rewardPerTokenStored3;
        userRewardsExtra[account].userRewardPerTokenPaidExtra = _rewardPerTokenStoredExtra;
        userRewardsExtraExtra[account].userRewardPerTokenPaidExtraExtra = _rewardPerTokenStoredExtraExtra;
        userRewardsExtraExtra2[account].userRewardPerTokenPaidExtraExtra2 = _rewardPerTokenStoredExtraExtra2;
        _;
    }


	//admin set up a new token
    function lastTimeRewardApplicable() public view returns (uint64) {
        uint64 blockTimestamp = uint64(block.timestamp);
        return blockTimestamp < periodFinish ? blockTimestamp : periodFinish;
    }


    function lastTimeRewardApplicable2() public view returns (uint64) {
        uint64 blockTimestamp = uint64(block.timestamp);
        return blockTimestamp < periodFinish2 ? blockTimestamp : periodFinish2;
    }


    function lastTimeRewardApplicable3() public view returns (uint64) {
        uint64 blockTimestamp = uint64(block.timestamp);
        return blockTimestamp < periodFinish3 ? blockTimestamp : periodFinish3;
    }


    function lastTimeRewardApplicableExtra() public view returns (uint64) {
        uint64 blockTimestamp = uint64(block.timestamp);
        return blockTimestamp < periodFinishExtra ? blockTimestamp : periodFinishExtra;
    }


    function lastTimeRewardApplicableExtraExtra() public view returns (uint64) {
        uint64 blockTimestamp = uint64(block.timestamp);
        return blockTimestamp < periodFinishExtraExtra ? blockTimestamp : periodFinishExtraExtra;
    }
	

    function lastTimeRewardApplicableExtraExtra2() public view returns (uint64) {
        uint64 blockTimestamp = uint64(block.timestamp);
        return blockTimestamp < periodFinishExtraExtra2 ? blockTimestamp : periodFinishExtraExtra2;
    }
	
	
    function rewardPerToken() public view returns (uint128) {
        uint256 totalStakedSupply = totalSupply;
        if (totalStakedSupply == 0) {
            return rewardPerTokenStored;
        }
        unchecked {
            uint256 rewardDuration = lastTimeRewardApplicable()-lastUpdateTime;
            return uint128(rewardPerTokenStored + rewardDuration*rewardRate*(1e18)/totalStakedSupply);
        }
    }


    function rewardPerToken2() public view returns (uint128) {
        uint256 totalStakedSupply = totalSupply;
        if (totalStakedSupply == 0) {
            return rewardPerTokenStored2;
        }
        unchecked {
            uint256 rewardDuration2 = lastTimeRewardApplicable2()-lastUpdateTime2;
            return uint128(rewardPerTokenStored2 + rewardDuration2*rewardRate2*1e18/totalStakedSupply);
        }
    }


    function rewardPerToken3() public view returns (uint128) {
        uint256 totalStakedSupply = totalSupply;
        if (totalStakedSupply == 0) {
            return rewardPerTokenStored3;
        }
        unchecked {
            uint256 rewardDuration3 = lastTimeRewardApplicable3()-lastUpdateTime3;
            return uint128(rewardPerTokenStored3 + rewardDuration3*rewardRate3*1e18/totalStakedSupply);
        }
    }


    function rewardPerTokenExtra() public view returns (uint128) {
        uint256 totalStakedSupply = totalSupply;
        if (totalStakedSupply == 0) {
            return rewardPerTokenStoredExtra;
        }
        unchecked {
            uint256 rewardDurationExtra = lastTimeRewardApplicableExtra()-lastUpdateTimeExtra;
            return uint128(rewardPerTokenStoredExtra + rewardDurationExtra*rewardRateExtra*(10**uint(decimalsExtra))/totalStakedSupply);
        }
    }
	
	
    function rewardPerTokenExtraExtra() public view returns (uint128) {
        uint256 totalStakedSupply = totalSupply;
        if (totalStakedSupply == 0) {
            return rewardPerTokenStoredExtraExtra;
        }
        unchecked {
            uint256 rewardDurationExtraExtra = lastTimeRewardApplicableExtraExtra()-lastUpdateTimeExtraExtra;
            return uint128(rewardPerTokenStoredExtraExtra + rewardDurationExtraExtra*rewardRateExtraExtra*(10**uint(decimalsExtraExtra))/totalStakedSupply);
        }
    }

    function rewardPerTokenExtraExtra2() public view returns (uint128) {
        uint256 totalStakedSupply = totalSupply;
        if (totalStakedSupply == 0) {
            return rewardPerTokenStoredExtraExtra2;
        }
        unchecked {
            uint256 rewardDurationExtraExtra2 = lastTimeRewardApplicableExtraExtra2()-lastUpdateTimeExtraExtra2;
            return uint128(rewardPerTokenStoredExtraExtra2 + rewardDurationExtraExtra2*rewardRateExtraExtra2*(10**uint(decimalsExtraExtra2))/totalStakedSupply);
        }
    }


    function earned(address account) public view returns (uint128) {
        unchecked { 
            return uint128(balanceOf(account)*(rewardPerToken()-userRewards[account].userRewardPerTokenPaid)/1e18 + userRewards[account].rewards);
        }
    }


    function earned2(address account) public view returns (uint128) {
        unchecked { 
            return uint128(balanceOf(account)*(rewardPerToken2()-userRewards2[account].userRewardPerTokenPaid2)/1e18 + userRewards2[account].rewards2);
        }
    }


    function earned3(address account) public view returns (uint128) {
        unchecked { 
            return uint128(balanceOf(account)*(rewardPerToken3()-userRewards3[account].userRewardPerTokenPaid3)/1e18 + userRewards3[account].rewards3);
        }
    }
	
	
    function earnedExtra(address account) public view returns (uint128) {
        unchecked { 
            return uint128(balanceOf(account)*(rewardPerTokenExtra()-userRewardsExtra[account].userRewardPerTokenPaidExtra)/(10 **(decimalsExtra)) + userRewardsExtra[account].rewardsExtra);
        }
    }
	
	
    function earnedExtraExtra(address account) public view returns (uint128) {
        unchecked { 
            return uint128(balanceOf(account)*(rewardPerTokenExtraExtra()-userRewardsExtraExtra[account].userRewardPerTokenPaidExtraExtra)/(10 **(decimalsExtraExtra)) + userRewardsExtraExtra[account].rewardsExtraExtra);
        }
    }
	

    function earnedExtraExtra2(address account) public view returns (uint128) {
        unchecked { 
            return uint128(balanceOf(account)*(rewardPerTokenExtraExtra2()-userRewardsExtraExtra2[account].userRewardPerTokenPaidExtraExtra2)/(10 **(decimalsExtraExtra2)) + userRewardsExtraExtra2[account].rewardsExtraExtra2);
        }
    }
	

    function stake(uint128 amount) external payable {
        stakeFor(msg.sender, amount);
    }


    function stakeFor(address forWhom, uint128 amount) public payable override updateReward(forWhom) {
        super.stakeFor(forWhom, amount);
    }
	

    function withdraw(uint128 amount) public override updateReward(msg.sender) {
        super.withdraw(amount);
    }
	

    function exit() external {
        getReward();
        withdraw(uint128(balanceOf(msg.sender)));
		
    }



//0 = Reward1 and Reward2, 1 = Reward1, 2 = Reward2, 3 = Reward3, 4 = RewardExtra, 5 = RewardExtraExtra
function getRewardBasicBasic(uint choice) public updateReward(msg.sender) {
        //Reward & Reward2 aka 1 and 2
        if(choice == 0){
	    uint256 reward = earned(msg.sender);
            uint256 reward2 = earned2(msg.sender);
            if (reward > 0) {
            	userRewards[msg.sender].rewards = 0;
           	 require(rewardToken.transfer(msg.sender, reward), "reward transfer failed");
            	totalRewarded = totalRewarded - reward;
            }
            if(reward2 > 0){
                userRewards2[msg.sender].rewards2 = 0;
                require(rewardToken2.transfer(msg.sender, reward2), "reward token 2 transfer failed");
                totalRewarded2 = totalRewarded2 - reward2;
            }
           emit RewardPaidBasic(msg.sender, reward, reward2);
		   
        }else if(choice == 2){
            uint256 reward2 = earned2(msg.sender);
            if(reward2 > 0){
               userRewards2[msg.sender].rewards2 = 0;
              require(rewardToken2.transfer(msg.sender, reward2), "reward token 2 transfer failed");
               totalRewarded2 = totalRewarded2 - reward2;
           }
           emit RewardPaidBasic(msg.sender, 0, reward2);
		   
        }else if(choice == 1){
	    uint256 reward = earned(msg.sender);
            if (reward > 0){
               userRewards[msg.sender].rewards = 0;
               require(rewardToken.transfer(msg.sender, reward), "reward transfer failed");
               totalRewarded = totalRewarded - reward;
            }
	    emit RewardPaidBasic(msg.sender, reward, 0);
			
        }else if(choice == 3){
	    uint256 reward3= earned3(msg.sender);
	    if(reward3 > 0){
		userRewards3[msg.sender].rewards3 = 0;
		address payable receiver = payable(msg.sender);
		require(receiver.send(reward3), "Eth transfer failed");
		totalRewarded3 = totalRewarded3 - reward3;
	    }
	    emit RewardPaid3(msg.sender, reward3);

        }else if(choice == 4){
            uint256 rewardExtra = earnedExtra(msg.sender);
            if (rewardExtra > 0){
                userRewardsExtra[msg.sender].rewardsExtra = 0;
                require(rewardTokenExtra.transfer(msg.sender, rewardExtra), "reward transfer failed");
               totalRewardedExtra = totalRewardedExtra - rewardExtra;
       	    }
            emit RewardPaidExtra(msg.sender, rewardExtra);
			
        }else if(choice == 5){
            uint256 rewardExtraExtra = earnedExtraExtra(msg.sender);
            if(rewardExtraExtra > 0)
            {
            	userRewardsExtraExtra[msg.sender].rewardsExtraExtra = 0;
                require(rewardTokenExtraExtra.transfer(msg.sender, rewardExtraExtra), "reward token 2 transfer failed");
                totalRewardedExtraExtra = totalRewardedExtraExtra - rewardExtraExtra;
            }
            emit RewardPaidExtraExtra(msg.sender, rewardExtraExtra);
	    
        }else if(choice == 6){
            uint256 rewardExtraExtra2 = earnedExtraExtra2(msg.sender);
            if(rewardExtraExtra2 > 0)
            {
            	userRewardsExtraExtra2[msg.sender].rewardsExtraExtra2 = 0;
                require(rewardTokenExtraExtra2.transfer(msg.sender, rewardExtraExtra2), "reward token 2 transfer failed");
                totalRewardedExtraExtra2 = totalRewardedExtraExtra2 - rewardExtraExtra2;
            }
            emit RewardPaidExtraExtra2(msg.sender, rewardExtraExtra2);
			
        }
    }

 
    function getReward() public updateReward(msg.sender) {
        uint256 reward = earned(msg.sender);
        uint256 reward2 = earned2(msg.sender);
        uint256 reward3= earned3(msg.sender);
        if (reward > 0) {
            userRewards[msg.sender].rewards = 0;
            if(reward3 > 0){
                userRewards3[msg.sender].rewards3 = 0;
                address payable receiver = payable(msg.sender);
	            require(receiver.send(reward3), "Eth transfer failed");
                totalRewarded3 = totalRewarded3 - reward3;
            }
            require(rewardToken.transfer(msg.sender, reward), "reward transfer failed");
            totalRewarded = totalRewarded - reward;
        }
        if(reward2 > 0)
        {
            
            userRewards2[msg.sender].rewards2 = 0;
            require(rewardToken2.transfer(msg.sender, reward2), "reward token 2 transfer failed");
            totalRewarded2 = totalRewarded2 - reward2;
        }
        uint256 rewardExtra = earnedExtra(msg.sender);
        if (rewardExtra > 0) {
            userRewardsExtra[msg.sender].rewardsExtra = 0;
            require(rewardTokenExtra.transfer(msg.sender, rewardExtra), "reward transfer failed");
            totalRewardedExtra = totalRewardedExtra - rewardExtra;
	    
        }
        uint256 rewardExtraExtra = earnedExtraExtra(msg.sender);
        if(rewardExtraExtra > 0)
        {
            
            userRewardsExtraExtra[msg.sender].rewardsExtraExtra = 0;
            require(rewardTokenExtraExtra.transfer(msg.sender, rewardExtraExtra), "reward token 2 transfer failed");
            totalRewardedExtraExtra = totalRewardedExtraExtra - rewardExtraExtra;
        }
	
        uint256 rewardExtraExtra2 = earnedExtraExtra2(msg.sender);
        if(rewardExtraExtra2 > 0)
        {
            
            userRewardsExtraExtra2[msg.sender].rewardsExtraExtra2 = 0;
            require(rewardTokenExtraExtra2.transfer(msg.sender, rewardExtraExtra2), "reward token 2 transfer failed");
            totalRewardedExtraExtra2 = totalRewardedExtraExtra2 - rewardExtraExtra2;
        }
        
            emit RewardPaid(msg.sender, reward, reward2, reward3, rewardExtra, rewardExtraExtra, rewardExtraExtra2);
			
    }
 
 
    function Z_setRewardParamsExtraExtra2(uint256 reward, uint64 duration) external {
        unchecked {
            require(reward > 0);
            duration = poolLength;  
            rewardPerTokenStoredExtraExtra2 = rewardPerTokenExtraExtra2();
            uint64 blockTimestamp = uint64(block.timestamp);
            require(blockTimestamp > periodFinishExtraExtra2, "MUST BE AFTER Previous Distribution ");
	    
            uint256 maxRewardSupply = rewardTokenExtraExtra2.balanceOf(address(this)) - totalRewardedExtraExtra2;
            
            if(rewardTokenExtraExtra2 == stakedToken){
                maxRewardSupply -= totalSupply;
	    }
            if(maxRewardSupply > duration)
            {
                rewardRateExtraExtra2 = ((maxRewardSupply*4)/10)/duration;
            }
            else{
                rewardRateExtraExtra2 = 0;
            }
            reward = (maxRewardSupply*4)/10;

            lastUpdateTimeExtraExtra2 = blockTimestamp;
            periodFinishExtraExtra2 = blockTimestamp+duration;
            totalRewardedExtraExtra2 = reward + totalRewardedExtraExtra2;
			
            emit RewardAdded6(reward);
			
        }
    }

 
    function Z_setRewardParamsExtraExtra(uint256 reward, uint64 duration) external {
        unchecked {
            require(reward > 0);
            duration = poolLength;  
            rewardPerTokenStoredExtraExtra = rewardPerTokenExtraExtra();
            uint64 blockTimestamp = uint64(block.timestamp);
            require(blockTimestamp > periodFinishExtraExtra, "MUST BE AFTER Previous Distribution ");
            uint256 maxRewardSupply = rewardTokenExtraExtra.balanceOf(address(this)) - totalRewardedExtraExtra;
            
            if(rewardTokenExtraExtra == stakedToken){
                maxRewardSupply -= totalSupply;
	    }
            if(maxRewardSupply > duration)
            {
                rewardRateExtraExtra = ((maxRewardSupply*4)/10)/duration;
            }
            else{
                rewardRateExtraExtra = 0;
            }
            reward = (maxRewardSupply*4)/10;

            lastUpdateTimeExtraExtra = blockTimestamp;
            periodFinishExtraExtra = blockTimestamp+duration;
            totalRewardedExtraExtra = reward + totalRewardedExtraExtra;
			
            emit RewardAdded5(reward);
			
        }
    }



    function Z_setRewardParamsExtra(uint256 reward, uint64 duration) external {
        unchecked {
            require(reward > 0);
            duration = poolLength; 
            rewardPerTokenStoredExtra = rewardPerTokenExtra();
            uint64 blockTimestamp = uint64(block.timestamp);
            require(blockTimestamp > periodFinishExtra, "MUST BE AFTER Previous Distribution ");
            uint256 maxRewardSupply = rewardTokenExtra.balanceOf(address(this)) - totalRewardedExtra;
            
            if(rewardTokenExtra == stakedToken){
                maxRewardSupply -= totalSupply;
	    }
            if(maxRewardSupply > duration)
            {
                rewardRateExtra = ((maxRewardSupply*4)/10)/duration;
            }
            else{
                rewardRateExtra = 0;
            }
            reward = (maxRewardSupply*4)/10;
            lastUpdateTimeExtra = blockTimestamp;
            periodFinishExtra = blockTimestamp+duration;
            totalRewardedExtra = reward + totalRewardedExtra;
			
            emit RewardAdded4(reward);
			
        }
    }





    function setRewardParamsALL(uint choice) external {
        this.Z_setRewardParamsForge(2, 22);
        this.Z_setRewardParams0xBTC(2, 22);
        this.Z_setRewardParamsETH(2, 22);
        if(choice == 1)
        {
            this.Z_setRewardParamsExtra(3, 33);
        }
        if(choice == 2){
            this.Z_setRewardParamsExtraExtra(3, 33);
            this.Z_setRewardParamsExtra(3, 33);
        }
	    if(choice == 3){
            this.Z_setRewardParamsExtraExtra2(3, 33);
            this.Z_setRewardParamsExtraExtra(3, 33);
            this.Z_setRewardParamsExtra(3, 33);
	    }
    }


    function Z_setRewardParamsForge(uint256 reward, uint64 duration) external {
        unchecked {
            require(reward > 0);
            duration = poolLength; 
            rewardPerTokenStored = rewardPerToken();
            uint64 blockTimestamp = uint64(block.timestamp);
            require(blockTimestamp > periodFinish, "MUST BE AFTER Previous Distribution ");
            uint256 maxRewardSupply = rewardToken.balanceOf(address(this)) - totalRewarded;
            
            if(rewardToken == stakedToken){
                maxRewardSupply -= totalSupply;
	    }
            if(maxRewardSupply > duration)
            {
                rewardRate = ((maxRewardSupply*4)/10)/duration;
            }
            else{
                rewardRate = 0;
            }
            
            reward = (maxRewardSupply*4)/10;
            lastUpdateTime = blockTimestamp;
            periodFinish = blockTimestamp+duration;
            totalRewarded = reward + totalRewarded;
            emit RewardAdded(reward);
        }
    }
	

    function Z_setRewardParams0xBTC(uint256 reward, uint64 duration) external {
        unchecked {
            require(reward > 0);
            duration = poolLength;  
            rewardPerTokenStored2 = rewardPerToken2();
            uint64 blockTimestamp = uint64(block.timestamp);
            require(blockTimestamp > periodFinish2, "MUST BE AFTER Previous Rewards");
            
            uint256 maxRewardSupply2 = rewardToken2.balanceOf(address(this)) - totalRewarded2;
            if(rewardToken2 == stakedToken){
                maxRewardSupply2 -= totalSupply;
	    }
            if(maxRewardSupply2 > reward)
            {
                rewardRate2 = ((maxRewardSupply2*4)/10)/duration;
            }
            else{
                rewardRate2 = 0;
            }
            reward = (maxRewardSupply2*4)/10;
            lastUpdateTime2 = blockTimestamp;
            periodFinish2 = blockTimestamp+duration;
            totalRewarded2 = reward + totalRewarded2;
            emit RewardAdded2(reward);
        }
    }


    function Z_setRewardParamsETH(uint256 reward, uint64 duration) external {
        unchecked {
            require(reward > 0);
            duration = poolLength;  
            rewardPerTokenStored3 = rewardPerToken3();
            uint64 blockTimestamp = uint64(block.timestamp);
            require(blockTimestamp > periodFinish3, "MUST BE AFTER Previous Rewards");
            uint256 maxRewardSupply3 = address(this).balance - totalRewarded3;

            if(maxRewardSupply3 > duration)
            {
                rewardRate3 = ((maxRewardSupply3*4)/10)/duration;
            }
            else{
                rewardRate3 = 0;
            }            
            reward = (maxRewardSupply3*4)/10;
            lastUpdateTime3 = blockTimestamp;
            periodFinish3 = blockTimestamp+duration;
            totalRewarded3 = reward + totalRewarded3;
            emit RewardAdded3(reward);
        }
    }
}

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/
* Synthetix: YFIRewards.sol
*
* Docs: https://docs.synthetix.io/
*
*
* MIT License
* ===========
*
* Copyright (c) 2020 Synthetix
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.   
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/