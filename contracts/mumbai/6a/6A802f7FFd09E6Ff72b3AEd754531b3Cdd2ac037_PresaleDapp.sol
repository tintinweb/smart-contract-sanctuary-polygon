// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
//pragma experimental ABIEncoderV2;
//import "https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol";



/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    function decimals() external view returns(uint8);


    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns(uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns(uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns(bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns(uint256);

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
    function approve(address spender, uint256 amount) external returns(bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);

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
}


interface ERC20 {

    function name() external pure returns(string memory);

    function symbol() external pure returns(string memory);

    function transfer(address to, uint256 value) external returns(bool);

    function approve(address spender, uint256 value) external returns(bool);

    function transferFrom(address from, address to, uint256 value) external returns(bool);

    function totalSupply() external view returns(uint256);

    function balanceOf(address who) external view returns(uint256);

    function allowance(address owner, address spender) external view returns(uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    //address public voter;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

/*
    modifier onlyVoter() {
        require(msg.sender == voter);
        _;
    }
    */
    /**
     * @dev Allows the current owner to relinquish control of the contract.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


interface LPToken {

    function sync() external;

}
// pragma solidity >=0.5.0;

interface UniswapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);


    function getPair(address tokenA, address tokenB) external view returns(address pair);


    function createPair(address tokenA, address tokenB) external returns(address pair);


}


// pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns(string memory);

    function symbol() external pure returns(string memory);

    function decimals() external pure returns(uint8);

    function totalSupply() external view returns(uint);

    function balanceOf(address owner) external view returns(uint);

    function allowance(address owner, address spender) external view returns(uint);

    function approve(address spender, uint value) external returns(bool);

    function transfer(address to, uint value) external returns(bool);

    function transferFrom(address from, address to, uint value) external returns(bool);


}

// pragma solidity >=0.6.2;

interface UniswapRouter02 {
    function factory() external pure returns(address);

    function WETH() external pure returns(address);
    function WBNB() external pure returns(address);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns(uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns(uint amountToken, uint amountETH, uint liquidity);

    function addLiquidityBNB(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns(uint amountToken, uint amountETH, uint liquidity);



    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns(uint[] memory amounts);
    function swapExactBNBForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns(uint[] memory amounts);




   // function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns(uint amountOut);

   // function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns(uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns(uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns(uint[] memory amounts);
}









interface lpLockDeployerInterface {

    function createLPLocker(address _lockingToken, uint256 _lockerEndTimeStamp, string memory _logo, uint256 _lockingAmount) external payable returns (address);


}



contract Consts {
   // uint constant TOKEN_DECIMALS = 18;
   // uint8 constant TOKEN_DECIMALS_UINT8 = 18;
   // uint constant TOKEN_DECIMAL_MULTIPLIER = 10 ** TOKEN_DECIMALS;
   // bool constant CONTINUE_MINTING = false;
   // uint256 constant minPlatTokenReq = 1000 * TOKEN_DECIMAL_MULTIPLIER;
   // uint256 constant airdropTokenPercentage = 2;
}

contract DefiCrowdsale is Consts, Ownable

    

{
    event TokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );
    event Closed();
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 weiAmount);
    event claimedBack(address indexed beneficiary, uint256 weiAmount);
    event Finalized();
    event Initialized();
    event TimesChanged(uint startTime, uint endTime, uint oldStartTime, uint oldEndTime);

    string public presaleType = "IDO";

    mapping(address => uint256) public contributors;
    mapping(address => uint256) public contributorsTracker;
    mapping(address => uint256) public contributorsClaim;
    mapping(address => uint256) public contributorsRefundAnytime;
    mapping(address => uint256) public contributorsPayoutNumber;    
    mapping(uint256 => address) public contributorsAddressTracker;
    mapping(address => bool) public contributed;
    mapping(address => bool) public anytimeRefunded;
    mapping(address => bool) public whitelist;
    mapping(uint256 => address) public AddWhitelistTracker;
    //mapping(uint256 => address) public RemoveWhitelistTracker;

    uint256 public contributorCount;
    uint256 public AddWhitelistNumber;
    uint256 public RemoveWhitelistNumber;
    uint256 public presaleGoalReachedTime = 0;
    uint256 public buyRate;
    uint256[2] __min_max_eth;
    uint256 public soft_cap;
    uint256 public hard_cap;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public weiRaised;
    uint256 public whitelistCoolOff = 600;
    uint256 public finalizeTimeout = 600; //604800;  //time for presale owner to finalize
    uint256 public disabledWhitelistTime;
    uint public teamFeePer = 2; // team fees percentage

    bool public initialized = false;
    bool public Preaslefinalized = false;
    bool public whitelistEnabled;
    bool public whitelistDisabledInitiated;
    bool public isFinalized;
    bool public finalizeValid;
    bool public vestingEnabled;
    bool public refundEnabled;
    bool public alternateFee;

    uint256 public MaxAllowedContribution;
    uint256 public numberOfVest;
    uint256 public finalizedTime;
    uint256 public vestingPeriod;
    uint256 public uniswapPercentage;
    uint256 public uniswapRate;
    uint256 public extraAmountPerVal;
    uint256 public nativeMultiplier = 20;
    uint256 public burnLockPeriod = 1209600;
    uint256 public totalTokenRequired;

   // address[] public AddWhitelistTrackerArray;
   // address[] public RemoveWhitelistTrackerArray;
    address public token;
    address public presaleCreator;
    address public feeContract;
    address public referrerAddr;
    address[3] public altAssets;
   // address public uniswapDapAddress;
    

    
    // address[] teamAddresses;
    // uint256[] teamAmounts;
    // uint256[] teamFreezeTimes;
    //uint256 totalTeamTokensMinted;

    constructor(address _token, uint256 _rate, uint256[2] memory start_end_time, address[2] memory targetWallets, uint256[2] memory soft_hard_cap, uint256[2] memory _min_max_eth, uint256[2] memory _UniRatePercentage, uint _teamFeePer, uint256[2] memory _extraAmountPer_lockTime, uint256 _nativeMul, address[5] memory _lpLockDepAndRouter_AltAssets)
    


    //Crowdsale(_rate, targetWallets[0], ERC20(token), _min_max_eth[1])
    //TimedCrowdsale(start_end_time[0] > now ? start_end_time[0] : now, start_end_time[1])
    //CappedCrowdsale(soft_hard_cap[1] * TOKEN_DECIMAL_MULTIPLIER)

    //RefundableCrowdsale(soft_hard_cap[0] * TOKEN_DECIMAL_MULTIPLIER, teamFees, _UniPercentage, targetWallets[1])

    {
        //  require((_govUniPercentage[0] >= 0) && (_govUniPercentage[0] <= 100), "Governance amount is outside of governance limits");
        
        __min_max_eth = _min_max_eth;
        soft_cap = soft_hard_cap[0];
        hard_cap = soft_hard_cap[1];
        startTime = start_end_time[0];
        endTime = start_end_time[1];
        token = _token;
        MaxAllowedContribution = _min_max_eth[1];
        presaleCreator = targetWallets[0];
        feeContract = targetWallets[1];
        teamFeePer = _teamFeePer;
        uniswapPercentage = _UniRatePercentage[1];
        //uniswapRate = _UniRatePercentage[0] * 10**IERC20(token).decimals();
        uniswapRate = _UniRatePercentage[0];
        //buyRate = _rate * 10**IERC20(token).decimals();
        buyRate = _rate;
        extraAmountPerVal = _extraAmountPer_lockTime[0] + 100;
        nativeMultiplier = _nativeMul;
        lpLockDeployer = _lpLockDepAndRouter_AltAssets[0];
        ROUTER_ADDRESS = _lpLockDepAndRouter_AltAssets[1];
        locktime = _extraAmountPer_lockTime[1];
        totalTokenRequired = ((buyRate*hard_cap + uniswapRate*((hard_cap*uniswapPercentage)/100))/(10 ** 18)) * (teamFeePer+100) / 100;
        altAssets[0] = _lpLockDepAndRouter_AltAssets[2];
        altAssets[1] = _lpLockDepAndRouter_AltAssets[3];
        altAssets[2] = _lpLockDepAndRouter_AltAssets[4];


            validPairPartner[altAssets[0]] = true;
            validPairPartner[altAssets[1]] = true;
            validPairPartner[altAssets[2]] = true;
  

    }



    function checkContributorValidity(address contributor_addr) public view returns(uint256) {

        return contributors[contributor_addr];

    }

    function checkRate() public view returns(uint256) {

        return buyRate;

    }

    function minEthContribution() public view returns(uint256) {

        return __min_max_eth[0];

    }

    function maxEthContribution() public view returns(uint256) {

        return __min_max_eth[1];

    }



    function presaleStartTime() public view returns(uint256) {

        return startTime;

    }

    function presaleEndTime() public view returns(uint256) {

        return endTime;

    }

    function mintForPlatform(address _platform, address _referrer, uint256 _refPer, bool tokenFeeToRef) public onlyOwner returns(bool) {
        if(!alternateFee){
            require(_platform != address(0), "platform addr cant be zero");
            uint256 platFee = (weiRaised*buyRate*teamFeePer)/(100 ether);
            uint256 refFee;
            if(tokenFeeToRef){
                refFee = platFee*_refPer/100;
                ERC20(token).transfer(_platform, platFee - (refFee));
                ERC20(token).transfer(_referrer, refFee);
            }
            else{

                ERC20(token).transfer(_platform, platFee);

            }
        }
        return true;
    }

/*
    function mintForUniswap(address uniswapDep) public onlyOwner {
        uint256 tokenFee = (weiRaised*uniswapRate*uniswapPercentage*extraAmountPerVal)/(10000 ether);
        require(uniswapDep != address(0x0),"uniswapDep addr cannot be zero");
        require(ERC20(token).transfer(uniswapDep, tokenFee),"unable to mint for uniDep from presale");
    }
*/


    //   function resetUserEthAmount(address contributor_addr) onlyOwner public {

    //    contributors[contributor_addr] = 0;


    //}




    /**
     * @dev override hasClosed to add minimal value logic
     * @return true if remained to achieve less than minimal
     */
    function hasClosed() public view returns(bool) {
        bool remainValue = (hard_cap - weiRaised) < __min_max_eth[0];
        return (block.timestamp > endTime) || remainValue;
    }



    function CheckSoftCap() public view returns(uint256) {

        return soft_cap;
    }

    function CheckHardCap() public view returns(uint256) {

        return hard_cap;
    }


    function CheckTotalEthRaised() public view returns(uint256) {

        return weiRaised;
    }




    /*
     * @dev override purchase validation to add extra value logic.
     * @return true if sended more than minimal value
     */
    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount
    )
    internal {

        require(msg.value >= __min_max_eth[0]);
        // require(msg.value >= 0);

        require(msg.value <= (__min_max_eth[1])); // it should be 10% in mainnet launch ***********************
        // require(msg.value <= 1000000000000000000);
        require((weiRaised + _weiAmount) <= hard_cap,"contribution reaching over hcap");
        require(_beneficiary != address(0));
        require(_weiAmount != 0);

    }



    function addToWhitelist(address WhitelistAddress) public onlyOwner {

    //    require(!whitelist[WhitelistAddress], "already whitelisted");
        whitelist[WhitelistAddress] = true;
        AddWhitelistTracker[AddWhitelistNumber] = WhitelistAddress;
        AddWhitelistNumber++;


    }


    function removeFromWhitelist(address WhitelistAddress) public onlyOwner {

        require(whitelist[WhitelistAddress], "not in whitelist!");
        whitelist[WhitelistAddress] = false;
        //RemoveWhitelistTracker[RemoveWhitelistNumber] = WhitelistAddress;
        //RemoveWhitelistNumber++;

    }


    function enableWhitelist() public onlyOwner {

        require(!whitelistEnabled, "whitelist already enabled");
        whitelistEnabled = true;


    }


    function disableWhitelist() public onlyOwner {

        require(whitelistEnabled, "whitelist already disabled");
        whitelistEnabled = false;
        disabledWhitelistTime = block.timestamp + whitelistCoolOff;
        whitelistDisabledInitiated = true;
    }


    function getAddlist() public view returns(address[] memory){

        address[] memory AddList = new address[](AddWhitelistNumber);  
        for (uint256 i = 0; i < AddWhitelistNumber; i++) {

            if(whitelist[AddWhitelistTracker[i]]){
                AddList[i] = AddWhitelistTracker[i];
            }
            else {

                AddList[i] = address(0x0);                
            }

        }

    return AddList;

    }

/*
    function getRemovelist() public view returns(address[] memory) {

        address[] memory RemoveList = new address[](RemoveWhitelistNumber); 
        for (uint256 i = 0; i < RemoveWhitelistNumber; i++) {

            RemoveList[i] = RemoveWhitelistTracker[i];


        }

    return RemoveList;
    

    }
    */
/*
    function getPresaleDataAddr() view returns(address[] memory, uint256[7] memory) {

        address[] memory PresaleDataAddr = new address[](AddWhitelistNumber); 
        for (uint256 i = 0; i < AddWhitelistNumber; i++) {

            PresaleDataAddr[i] = AddWhitelistTracker[i];  //******************************************** NEED UPDATE TO ADD CORRECT ADDRESS DATA***************************************************


        }

    return (PresaleDataAddr,getPresaleDataUint());
    

    }
*/    


    /**
     * @dev fallback function ***DO NOT OVERRIDE***
     */
    receive() external payable {

        require(block.timestamp > disabledWhitelistTime, "In whitelist disabled cool Off");
        require(!anytimeRefunded[msg.sender], "User used anytime refund!"); //checking if user refunded from this presale at anytime

        if (whitelistEnabled) {

            require(whitelist[msg.sender], "user not whitelisted");

        }
        require(contributors[msg.sender] <= (MaxAllowedContribution - msg.value),"contribution over max allowed");
        buyTokens(msg.sender);
        contributors[msg.sender] += msg.value;
        contributorsTracker[msg.sender] += msg.value;
        if(!contributed[msg.sender]){
            contributorsAddressTracker[contributorCount] = msg.sender;
            contributed[msg.sender] = true;
            contributorCount++;
        }
    }


    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * @param _beneficiary Address performing the token purchase
     */
    function buyTokens(address _beneficiary) internal {
        require(msg.sender == tx.origin,"can't contribute via contracts");
        require(block.timestamp > disabledWhitelistTime, "In whitelist disabled cool Off internal");
        require (block.timestamp >= startTime && block.timestamp < endTime,"IDO not active");
        require(!anytimeRefunded[msg.sender], "User used anytime refund!"); //checking if user refunded from this presale at anytime
        if (whitelistEnabled) {

            require(whitelist[msg.sender], "user not whitelisted");

        }
        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        // update state
        weiRaised += weiAmount;

        //_processPurchase(_beneficiary, tokens);
        emit TokenPurchase(
            msg.sender,
            _beneficiary,
            weiAmount,
            tokens
        );

       // _updatePurchasingState(_beneficiary, weiAmount);

        //_forwardFunds();
        //_postValidatePurchase(_beneficiary, weiAmount);



    }

    function _getTokenAmount(uint256 _weiAmount)
    internal view returns(uint256) {
        return _weiAmount*buyRate/(1 ether);
        // return _weiAmount.mul(rate);
    }


    function claimTokens() public {
        require(!refundEnabled,"presale was refunded");
        require(!vestingEnabled,"please use vesting method to claim");
        require(isFinalized, "Not Finalized yet!");
        require(finalizeValid, "presale Failed!"); //checking if presale succeeded or not
        require(!(contributors[msg.sender] == 0), "user has no more tokens to claim!");
        uint256 tokenValue = (uint256(contributors[msg.sender]) * (uint256(buyRate))) / (1 ether);
        // uint256 tokenValueDecimalOptimized = (tokenValue.mul(10 ** uint256(seeDecimals(token)))).div(1 ether);
        contributors[msg.sender] = 0;
        ERC20(token).transfer(msg.sender, tokenValue);
        contributorsClaim[msg.sender] = tokenValue;

    }

    function vestToken() public {
        // require(!tokenDropFlag,"can't vest when token drop enabled!");
        require(!refundEnabled,"presale was refunded");       
        require(vestingEnabled,"vesting not enabled");
        require(isFinalized, "Not Finalized yet!");
        require(finalizeValid, "presale Failed!"); //checking if presale succeeded or not
        require(!(contributors[msg.sender] == 0), "user has no more tokens to claim!");       
        require(contributorsPayoutNumber[msg.sender] < numberOfVest,"all tokens vested");
        uint256 CurrentPayoutRounds = (((block.timestamp) - (finalizedTime)) / (vestingPeriod)) + (1);  // need to add 1 to allow partial token vest right away after presale
         if (CurrentPayoutRounds >= numberOfVest){
            CurrentPayoutRounds = numberOfVest;
        }
      
        uint256 userPayoutRounds = CurrentPayoutRounds - (contributorsPayoutNumber[msg.sender]);
        require(userPayoutRounds > 0 && userPayoutRounds <= numberOfVest,"not in user claim window");

        contributorsPayoutNumber[msg.sender] = CurrentPayoutRounds;
        
        uint256 tokenValue = (((uint256(contributorsTracker[msg.sender]) * (uint256(buyRate))) / (1 ether)) * (userPayoutRounds)) / (numberOfVest);
        // uint256 tokenValueDecimalOptimized = (tokenValue.mul(10 ** uint256(seeDecimals(token)))).div(1 ether);
        uint256 totalTokensLeftForUser = (uint256(contributors[msg.sender]) * (uint256(buyRate))) / (1 ether);
        require(tokenValue <= totalTokensLeftForUser,"can't claim more than allowed");
        uint256 contributionsClaiming = contributorsTracker[msg.sender] * (userPayoutRounds) / (numberOfVest);
        if(contributionsClaiming >= contributors[msg.sender]){
            contributors[msg.sender] = 0;
        }
        else{
            contributors[msg.sender] = contributors[msg.sender] - (contributionsClaiming);
        }
        ERC20(token).transfer(msg.sender, tokenValue);
        contributorsClaim[msg.sender] = contributorsClaim[msg.sender] + (tokenValue);       

    }

    function enableVesting(uint256 _numOfVest, uint256 _vestingPeriod) public{
        require(_numOfVest > 1,"num of vest has to be grtr than 1");
        require(_vestingPeriod > 0,"vesting period invalid");   
        require(block.timestamp < startTime - (600),"can't enable vest after presale start");    
        require(!vestingEnabled,"vesting already enabled");
        //require(!tokenDropFlag, "can't enable vest when airdrop is on");    
        require(msg.sender == presaleCreator);  // checking for presale owner address

        vestingEnabled = true;
        numberOfVest = _numOfVest;
        vestingPeriod = _vestingPeriod;
    }

    function disableVesting() public {
        require(msg.sender == presaleCreator); 
        require(vestingEnabled,"vesting already disabled");
        require(!isFinalized,"presale already finalized");
        vestingEnabled = false;

    }   
    
    function claimRefund() public {
        require(isFinalized, "not finalized");
        require(!(goalReached()) || !finalizeValid, "goal reached or presale succeeded");

        refund(msg.sender);
    }



    function claimRefundAnytime() public {
        require(!anytimeRefunded[msg.sender], "already refunded!");
        uint256 userContributed = contributors[msg.sender];
        require(userContributed > 0, "nothing to claim");
        require(!isFinalized, "already finalized!");
        require(!finalizeValid, "already succesfully finalized");
        require(block.timestamp < endTime - (finalizeTimeout), "withdrawal window expired!");
        // require(!goalReached() || !finalizeValid,"goal reached");
        contributorsRefundAnytime[msg.sender] = userContributed; // added for V3 -- need to check
        weiRaised = weiRaised - (userContributed); // Subtract from total eth raised


        anytimeRefunded[msg.sender] = true;
        refundAnytime(msg.sender,userContributed);

    }
    function refund(address investor) internal { //have to see if onlyOwner works
        require(refundEnabled,"refund not enabled");
        uint256 depositedValue = contributors[investor];
        require(depositedValue > 0, "User has no investment to claim");
        contributors[investor] = 0;
        payable(investor).call{value:depositedValue}("");
        emit Refunded(investor, depositedValue);
    }

    function refundAnytime(address investor, uint256 _contributed) internal { // have to see if onlyOwner works
        //require(state == State.Refunding);
        //uint256 depositedValue = contributors[investor];
        //require(depositedValue > 0, "User has no investment to claim");
        uint256 penalty = _contributed*(20)/(100);
        uint256 refundValue = _contributed - (penalty);

        contributors[investor] = 0; // added for V3 -- need to check
        contributorsTracker[investor] = 0; // added for V3 -- need to check
        payable(address(feeContract)).call{value:penalty}("");
        payable(investor).call{value:refundValue}("");
        emit claimedBack(investor, _contributed);
    }

    function finalize(address[2] memory __finalizeInfo, uint256 refPer, bool validFinalize) onlyOwner public returns(bool) {
        require(!isFinalized,"already finalized");
        require(hasClosed(),"not closed");
        referrerAddr = __finalizeInfo[0];
        presaleCreator = __finalizeInfo[1];
       // uniswapDapAddress = __finalizeInfo[2];
        finalizeValid = validFinalize;
        if (goalReached() && finalizeValid) {
            close(presaleCreator, referrerAddr, refPer);

        } else {
            enableRefunds();
        }

        finalizedTime = block.timestamp;

        emit Finalized();

        isFinalized = true;
        /*
        if(tokenDropFlag && finalizeValid){
            tokenDrop();
        }
        */
        return true;


    }

    function finalizeAnytime(address[2] memory __finalizeInfo, bool validFinalize) onlyOwner public returns(bool) {
        require(!isFinalized, "presale already finalized");
        //   require(hasClosed());
        referrerAddr = __finalizeInfo[0];
        presaleCreator = __finalizeInfo[1];
       // uniswapDapAddress = __finalizeInfo[2];
        finalizeValid = validFinalize;
        enableRefunds();
        emit Finalized();

        isFinalized = true;



        return true;


    }

    function enableRefunds() internal {

        refundEnabled = true;
        emit RefundsEnabled();
    }


    function getBackTokens() public {

       // require(block.timestamp > closingTime.add(burnDeltaTime), "cannot withdraw yet");
        require(msg.sender == presaleCreator, "initiator is not presale owner!");
       // require(hasClosed(), "presale not closed!");
        require(isFinalized, "presale not finalized!");
        require(!finalizeValid, "finalize was valid");

        require(IERC20(token).transfer(presaleCreator, IERC20(token).balanceOf(address(this))),"cannot transfer token back");

    }

        function burnUnsoldTokens() public {

       // require(block.timestamp > closingTime.add(burnDeltaTime), "cannot withdraw yet");
        require(msg.sender == presaleCreator, "initiator is not presale owner!");
        require(block.timestamp > (finalizedTime + burnLockPeriod));
       // require(hasClosed(), "presale not closed!");
        require(isFinalized, "presale not finalized!");
        require(finalizeValid, "finalize was valid");
        uint256 tokenUnsold = (((hard_cap-weiRaised)*uniswapRate*uniswapPercentage*extraAmountPerVal)/(10000 ether)) + ((hard_cap-weiRaised)*buyRate);
        require(IERC20(token).transfer(dead, tokenUnsold),"cannot transfer token to dead");

    }

    function selectNativeOnlyFee() public {

        require(msg.sender == presaleCreator, "initiator is not presale owner!");
        require(!isFinalized, "presale already finalized!");
        alternateFee = true;
        teamFeePer = (teamFeePer * nativeMultiplier)/10;

    }
    function close(address __Creator, address _referrerAddr, uint256 _refPer) internal {
        require(!isFinalized,"presale already finalized");
        emit Closed();

        uint256 feesAmount = (address(this).balance * teamFeePer) / (100);
        if(_refPer > 0){
            uint256 refAmount = (feesAmount * _refPer) / (100);
            payable(address(_referrerAddr)).call{value:refAmount}("");
            payable(address(feeContract)).call{value:(feesAmount - refAmount)}("");
        }
        else{

            payable(address(feeContract)).call{value:feesAmount}("");

        }
        

        uint256 uniswapAmount = (address(this).balance * uniswapPercentage) / (100);
        // uint256 GoverningAmount = address(this).balance.mul(gov).div(100);

        require(address(this).balance >= uniswapAmount, "Not Enough Fund to Transfer");
        //  require(address(this).balance > GoverningAmount, "Not Enough Fund to Transfer");

        //payable(__uniswapDep).transfer(uniswapAmount);
        AddLiquidity((weiRaised*uniswapRate*uniswapPercentage*extraAmountPerVal)/(10000 ether),uniswapAmount);
        // __GovContract.transfer(GoverningAmount);
        if(address(this).balance != 0){
            payable(address(__Creator)).call{value:address(this).balance}("");
        }

    }

    function goalReached() public view returns(bool) {

        return weiRaised >= soft_cap;

    }
    function presaleEnded() public view returns(bool) {

        return block.timestamp > endTime;

    }

// DATA functions for UI to fetch and read

        function getPresaleData() public view returns(uint256[10] memory,bool[4] memory, string memory) {


            uint256[10] memory PresaleDataUint;
            bool[4] memory presaleDataBool;
            PresaleDataUint = [soft_cap,hard_cap,__min_max_eth[0],__min_max_eth[1],startTime,endTime,weiRaised,buyRate,uniswapRate,uniswapPercentage];
            presaleDataBool = [isFinalized,finalizeValid,vestingEnabled,refundEnabled];


        return (PresaleDataUint,presaleDataBool,presaleType);
    

        }

/*
        function getContributorData() public view returns(address[] memory,uint256[] memory) {

           // address[] memory WalletList = new address[](KYCsverifiedNumber);  
            address[] memory contributorAddresses = new address[](contributorCount);
            uint256[] memory contributedValues = new uint256[](contributorCount);
            for (uint256 i = 0; i < contributorCount;i++){

                contributorAddresses[i] = contributorsAddressTracker[i];
                contributedValues[i] = contributors[contributorsAddressTracker[i]];

            }



            return (contributorAddresses,contributedValues);
    

        }

*/


    mapping(address => bool) public validPairPartner;
    //mapping(uint256 => address) public altList;
   // mapping(address => bool) public swapRouterMap;
   // mapping(uint256 => string) public altListName;
    //address public pairPartner;

   // uint256 public hundred = 100;
   // uint256 public extraAmountPerVal;
  //  address public tokenAddress;
  //  address public creatorAddress;
    uint256 public locktime;
    address public ROUTER_ADDRESS;
   // address public swapRouter_Address;
   // address public factoryAddress;
    address public dead = 0x000000000000000000000000000000000000dEaD;
	
   //address[] public altRouter;
   // string[] public altRouterNames;
	address public storedLPAddress;
	address public lockerAddress;
   // bool public blocked = false;
    bool public addLiquidityComplete;
    address public alternativeCurrency;
    bool public useAlternativeCurrency;
    uint256 public returnVal;
    address public lpLockDeployer;
    string public logo = "default";

    function Approve(address _token) internal returns (bool) {
        uint256 amountIn = 100000000000000000000000000000000000000000000000000000000000000000000000000000;
        ERC20(_token).approve(ROUTER_ADDRESS, amountIn);
        return true;
    }
    function ApproveLock(address _lp, address _lockDeployer) internal returns (bool) {
        uint256 amountIn = 100000000000000000000000000000000000000000000000000000000000000000000000000000;
        ERC20(_lp).approve(_lockDeployer, amountIn);
        return true;
    }

    function getWrapAddr() public view returns (address){

            return UniswapRouter02(ROUTER_ADDRESS).WETH();

    }
  /*  function getWrapAddrRouterSpecific(address _router) public view returns (address){

            return UniswapRouter02(_router).WETH();

    }
    */
    function getpair(address _token1, address _token2) internal returns (address) {
        if (UniswapFactory(UniswapRouter02(ROUTER_ADDRESS).factory()).getPair(_token1, _token2) != address(0)) {
            return UniswapFactory(UniswapRouter02(ROUTER_ADDRESS).factory()).getPair(_token1, _token2);
        } else {
            return UniswapFactory(UniswapRouter02(ROUTER_ADDRESS).factory()).createPair(_token1, _token2);
        }
    }

    function setAlternateCurrency(address _newCurrency) public {
        require(_newCurrency != address(0),"currency cannot be Zero addr");
       // require(swapRouterMap[_swapRouter],"invalid router");
        require(validPairPartner[_newCurrency],"invalid asset selected");
        require(!addLiquidityComplete,"Liquidity is added already");
        require(msg.sender == presaleCreator,"not the presale creator");
       // swapRouter_Address = _swapRouter;
        alternativeCurrency = _newCurrency;
        useAlternativeCurrency = true;
    }

     function revertToNative() public{ 
        require(!addLiquidityComplete,"Liquidity is added already");
        require(msg.sender == presaleCreator,"not the presale creator");
        useAlternativeCurrency = false;
    }   
    function getAmountsMinToken(address _tokenAddress, uint256 _ethIN) public view returns(uint256) {

      //  UniswapRouter02 pancakeRouter = UniswapRouter02(_router);
        // generate the pair path of token -> weth
        uint256[] memory amountMinArr;
        uint256 AmountMin;
        address[] memory path = new address[](2);
        path[0] = getWrapAddr();
        path[1] = address(_tokenAddress);

        amountMinArr = UniswapRouter02(ROUTER_ADDRESS).getAmountsOut(_ethIN, path);
        AmountMin = uint256(amountMinArr[1]);

        return AmountMin;


    }

/*
       function getAmountsMinETH(address _tokenAddress, uint256 _tokenIN) public view returns(uint256) {

      //  UniswapRouter02 pancakeRouter = UniswapRouter02(_router);
        // generate the pair path of token -> weth
        uint256[] memory amountMinArr;
        uint256 AmountMin;
        address[] memory path = new address[](2);
        path[0] = address(_tokenAddress);
        path[1] = getWrapAddr();

        amountMinArr = UniswapRouter02(swapRouter_Address).getAmountsOut(_tokenIN, path);
        AmountMin = uint256(amountMinArr[1]);

        return AmountMin;


    }
    */
    function swapETHForTokens(uint256 _nativeForDex) private {
        require(useAlternativeCurrency,"alt currency not selected");
        address[] memory path = new address[](2);

        //path[0] = address(this);
        path[0] = getWrapAddr();
        path[1] = alternativeCurrency;

        Approve(alternativeCurrency);

        // make the swap
         UniswapRouter02(ROUTER_ADDRESS).swapExactETHForTokens{value:_nativeForDex}(
            getAmountsMinToken(alternativeCurrency,_nativeForDex),
            path,
            address(this),
            block.timestamp + (300)
            );
                
                returnVal = ERC20(alternativeCurrency).balanceOf(address(this));
                

            
            

    }

    function AddLiquidity(uint256 amountTokenDesired, uint256 nativeForDex) internal {
     //   require(validPairPartner[_pairAlternative], "This is not a valid pair partner");

        uint256 amountETH = nativeForDex;
        uint256 amountETHMin = (amountETH * 90)/100;
        uint256 amountTokenToAddLiq = (amountTokenDesired * 100) / (extraAmountPerVal);
        uint256 amountTokenMin = (amountTokenToAddLiq * 90)/100;
        uint256 LP_WBNB_exp_balance;
        uint256 LP_token_balance;
        uint256 tokenToSend;
        if (useAlternativeCurrency) {

            swapETHForTokens(nativeForDex);

			storedLPAddress = getpair(token, alternativeCurrency);
            LP_WBNB_exp_balance = ERC20(alternativeCurrency).balanceOf(storedLPAddress);
            LP_token_balance = ERC20(token).balanceOf(storedLPAddress);
        }

        else{

            storedLPAddress =  getpair(token, getWrapAddr());
            LP_WBNB_exp_balance = ERC20(getWrapAddr()).balanceOf(storedLPAddress);
            LP_token_balance = ERC20(token).balanceOf(storedLPAddress);
        }

            if (storedLPAddress != address(0x0) && (LP_WBNB_exp_balance > 0 && LP_token_balance <= 0)) {
                tokenToSend = (amountTokenToAddLiq * LP_WBNB_exp_balance) / amountETH;

                ERC20(token).transfer(storedLPAddress, tokenToSend);

                LPToken(storedLPAddress).sync();
                // sync after adding token
            }
            Approve(token);

        if (useAlternativeCurrency) {
            UniswapRouter02(ROUTER_ADDRESS).addLiquidity(token, alternativeCurrency,amountTokenDesired,ERC20(alternativeCurrency).balanceOf(address(this)),amountTokenDesired,ERC20(alternativeCurrency).balanceOf(address(this)),address(this), block.timestamp + (300));
        }
        else{
            
            UniswapRouter02(ROUTER_ADDRESS).addLiquidityETH{value:amountETH}(token, amountTokenToAddLiq, amountTokenMin, amountETHMin, address(this), block.timestamp + (300));
        

        }

           // if (ERC20(token).balanceOf(address(this)) != 0) {
           //     ERC20(token).transfer(dead, ERC20(token).balanceOf(address(this)));
                //Burn remaining tokens
           // }


      /*  } else {
			storedLPAddress =  getpair(token, getWrapAddr());
            LP_WBNB_exp_balance = ERC20(getWrapAddr()).balanceOf(storedLPAddress);
            LP_token_balance = ERC20(token).balanceOf(storedLPAddress);
        
            if (storedLPAddress != address(0x0) && (LP_WBNB_exp_balance > 0 && LP_token_balance <= 0)) {
                tokenToSend = amountTokenToAddLiq.mul(LP_WBNB_exp_balance).div(amountETH);

                ERC20(token).transfer(storedLPAddress, tokenToSend);

                LPToken(storedLPAddress).sync();
                // sync after adding token
            }
            
            Approve(token);
           
           UniswapRouter02(ROUTER_ADDRESS).addLiquidityETH{value:address(this).balance}(token, amountTokenToAddLiq, amountTokenMin, amountETHMin, address(this), block.timestamp.add(300));
        

            if (ERC20(token).balanceOf(address(this)) != 0) {
                ERC20(token).transfer(dead, ERC20(token).balanceOf(address(this)));
                //Burn remaining tokens
            }
    */

        

        addLiquidityComplete = true;

        ApproveLock(storedLPAddress,lpLockDeployer);
        lockerAddress = lpLockDeployerInterface(lpLockDeployer).createLPLocker(storedLPAddress,locktime,logo,ERC20(storedLPAddress).balanceOf(address(this)));
        
    }




/*
    function getAltAssetData() public view returns(address[] memory){

        address[] memory altAssetData = new address[](altAssets.length);
       // string[] memory  altListName = new string[](altAssets.length);
       // string[] memory  altListSym = new string[](altAssets.length);
        for(uint256 i=0;i<altAssets.length;i++){

            altAssetData[i] = altAssets[i];
           // altListName[i] = ERC20(altAssets[i]).name();
           // altListSym[i] = ERC20(altAssets[i]).symbol();
        }    
        return(altAssetData);
    }
    */
    /*
    function getAltRouterData() public view returns(address[] memory, string[] memory){

        address[] memory altRouterData = new address[](altRouter.length);
        string[] memory  altRouterName = new string[](altRouterNames.length);
        for(uint256 i=0;i<altRouter.length;i++){

            altRouterData[i] = altRouter[i];
            altRouterName[i] = altRouterNames[i];
        }    
        return(altRouterData,altRouterName);
    }
    */
       
}




contract PresaleDapp is Consts, Ownable {



   // address public lpLockDeployer;
   // address public feeContract;
    address[5] public feeContract_lplockDep_altAssets;
    uint256 public teamFee = 2;
    uint256 public nativeMultiplier = 20;
    constructor(address[5] memory _feeContract_lplockDep_altAssets) {

        feeContract_lplockDep_altAssets = _feeContract_lplockDep_altAssets;


    }

    function CreatePresaleRegular(address[4] memory presaleAddressInput_router, uint256[2] memory start_end_time, uint256[5] memory soft_hard_cap_rate_min_max_eth, uint256[2] memory uniRatePercentage, uint256[2] memory extraAmountPer_lockTime) public returns(address) {


        //require(uniRatePercentage[1] <= 100, "total percentages > 100!"); // This is to make sure that more eth is not requested than available

        //uint256[2] memory min_max_eth = [soft_hard_cap_rate_min_max_eth_GOV[3], soft_hard_cap_rate_min_max_eth_GOV[4]];
        //address _mainDapp = presaleAddressInput[0];
        //address creator = presaleAddressInput[1];
        //address tokenAddr = presaleAddressInput[2];
        //uint256[2] memory _soft_hard_cap = [soft_hard_cap_rate_min_max_eth_GOV[0], soft_hard_cap_rate_min_max_eth_GOV[1]];
        //uint256 UniPercentage = uniPercentage;
        address[2] memory targetWallets = [presaleAddressInput_router[1], feeContract_lplockDep_altAssets[0]];

        address router = presaleAddressInput_router[3];


        DefiCrowdsale PresaleContract = new DefiCrowdsale(presaleAddressInput_router[2], soft_hard_cap_rate_min_max_eth[2], start_end_time, targetWallets, [soft_hard_cap_rate_min_max_eth[0], soft_hard_cap_rate_min_max_eth[1]], [soft_hard_cap_rate_min_max_eth[3], soft_hard_cap_rate_min_max_eth[4]], uniRatePercentage,teamFee,extraAmountPer_lockTime,nativeMultiplier,[feeContract_lplockDep_altAssets[1],router,feeContract_lplockDep_altAssets[2],feeContract_lplockDep_altAssets[3],feeContract_lplockDep_altAssets[4]]);


        PresaleContract.transferOwnership(presaleAddressInput_router[0]);



        return address(PresaleContract);
    }




    function updateTeamFee(uint256 _newTeamFee) public onlyOwner {


        teamFee = _newTeamFee;




    }

    function updateNativeMultiplier(uint256 _newMultiplier) public onlyOwner {


        nativeMultiplier = _newMultiplier;




    }



    function updateFeeContract(address _newFeeContract) public onlyOwner {


        feeContract_lplockDep_altAssets[0] = _newFeeContract;




    }

    function updateAltAssets(uint index, address _newAltAssets) public onlyOwner {

        require(index > 1,"cannot update fee or lpdep contract");
        feeContract_lplockDep_altAssets[index] = _newAltAssets;

    }

}