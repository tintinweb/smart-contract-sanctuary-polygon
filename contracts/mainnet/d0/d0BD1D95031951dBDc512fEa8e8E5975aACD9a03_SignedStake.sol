pragma solidity ^0.7.4;

//import "./INFTFeeClaim.sol";
import "./ISignedStake.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./TokensRecoverable.sol";
import "./StakingToken.sol";
import "./ERC20.sol";
//import "./IERC721.sol";
//import "./IHobbsNFT.sol";

contract SignedStake is ISignedStake, TokensRecoverable
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
    
     
    address public devAddress;
    address public immutable deployerAddress;
    address public paymentToken;
    mapping (uint => address) public stakers;
    uint private stakerCounter;
    mapping (address => bool) public addressLogged;
    uint public maticPaidOut;
    uint public tokensPaidOut;
    uint[] public stakerRates = [4000, 3000, 1500, 1000, 500];
    struct StakerTracker {
        uint levelOneStakers;
        uint levelTwoStakers;
        uint levelThreeStakers;
        uint levelFourStakers;
        uint levelFiveStakers;
    }
    struct StakerInfo {
        address staker;
        uint stakerLevel;
    }
    StakerTracker public stakerTracker;
    mapping (address => StakerInfo) public stakerInfo;

    StakingToken public stakingToken;//SIGNED STAKING

    //pass in nft address, then nft id, spits out availableClaim
    mapping(address => uint256) public availableClaim;

    //mapping  of a mapping
    mapping(address => mapping(address => uint256)) public availableTokenClaims;
    address[] public tokenList;
    

    constructor(address _devAddress, StakingToken _stakingToken)
    
    {
        deployerAddress = msg.sender;
        devAddress = _devAddress;
        stakingToken = _stakingToken;


        //rootFeederAddress = _rootFeederAddress;
    }
    //owner or dev address only modifier
    modifier onlyOwnerOrDev() {
        require (msg.sender == deployerAddress || msg.sender == devAddress || msg.sender == owner, "Not a deployer or dev address");
        _;
    }

    function setDevAddress(address _devAddress) public
    {
        require (msg.sender == deployerAddress || msg.sender == devAddress, "Not a deployer or dev address");
        devAddress = _devAddress;
    }
    function setStakingToken(StakingToken _stakingToken) public onlyOwnerOrDev()
    {
        stakingToken = _stakingToken;
    }
    //check registered addresses and update staker levels
    function updateStakerLevels() public onlyOwnerOrDev()
    {
        resetTrackers();

        for (uint i = 0; i < stakerCounter; i++)
        {
            uint level = checkLevel(stakers[i]);
            stakerInfo[stakers[i]].stakerLevel = level;
            if (level == 1)
            {
                stakerTracker.levelOneStakers++;
            }
            else if (level == 2)
            {
                stakerTracker.levelTwoStakers++;
            }
            else if (level == 3)
            {
                stakerTracker.levelThreeStakers++;
            }
            else if (level == 4)
            {
                stakerTracker.levelFourStakers++;
            }
            else if (level == 5)
            {
                stakerTracker.levelFiveStakers++;
            }
        }
        //check for 0 stakers
        if (stakerTracker.levelOneStakers == 0)
        {
            stakerTracker.levelOneStakers = 1;
        }
        if (stakerTracker.levelTwoStakers == 0)
        {
            stakerTracker.levelTwoStakers = 1;
        }
        if (stakerTracker.levelThreeStakers == 0)
        {
            stakerTracker.levelThreeStakers = 1;
        }
        if (stakerTracker.levelFourStakers == 0)
        {
            stakerTracker.levelFourStakers = 1;
        }
        if (stakerTracker.levelFiveStakers == 0)
        {
            stakerTracker.levelFiveStakers = 1;
        }
    }    
    function resetTrackers() internal {
        stakerTracker.levelOneStakers = 0;
        stakerTracker.levelTwoStakers = 0;
        stakerTracker.levelThreeStakers = 0;
        stakerTracker.levelFourStakers = 0;
        stakerTracker.levelFiveStakers = 0;
    }

    function updateStakerRates(uint[] memory rates) public onlyOwnerOrDev(){
        stakerRates = rates;
    }
    
    //add addresses to tokenlist
    function addToken(address _token) public onlyOwnerOrDev()
    {
        require (tokenList.length < 100, "Token list is full");
        tokenList.push(_token);
    }

    function register() public 
    {
        if (addressLogged[msg.sender] == false)
        {
            addressLogged[msg.sender] = true;
            stakers[stakerCounter] = msg.sender;
            stakerInfo[msg.sender].staker = msg.sender;
            stakerCounter++;
        }
    }

    function depositMatic() public payable override onlyOwnerOrDev() {
            uint256 amount = msg.value;
            calculatePayouts(amount);

        }
    function depositTokens(address tokenContract, uint256 amount) public onlyOwnerOrDev(){

        calculateTokenPayouts(tokenContract, amount);
        IERC20(tokenContract).transferFrom(msg.sender, address(this), amount);
    }
    
    function calculatePayouts(uint256 amount) internal {
        
        uint levelOnePayout = (stakerRates[0] * amount / 10000) / stakerTracker.levelOneStakers;
        uint levelTwoPayout = (stakerRates[1] * amount / 10000) / stakerTracker.levelTwoStakers;
        uint levelThreePayout = (stakerRates[2] * amount / 10000) / stakerTracker.levelThreeStakers;
        uint levelFourPayout = (stakerRates[3] * amount / 10000) / stakerTracker.levelFourStakers; 
        uint levelFivePayout = (stakerRates[4] * amount / 10000) / stakerTracker.levelFiveStakers;

        for (uint i = 0; i < stakerCounter; i++){
            uint level = checkLevel(stakers[i]); 
            if (level == 1){
                availableClaim[stakers[i]] = levelOnePayout;
            }
            else if (level == 2){
                availableClaim[stakers[i]] = levelTwoPayout;
            }
            else if (level == 3){
                availableClaim[stakers[i]] = levelThreePayout;
            }
            else if (level == 4){
                availableClaim[stakers[i]] = levelFourPayout;
            }
            else if (level == 5){
                availableClaim[stakers[i]] = levelFivePayout;
            }
            
        }
    }

    
    /* function calculatePayouts(uint256 amount) internal {
        uint totalStakingTokens = stakingToken.totalSupply();
        //calculate matic payout based on how many tokens each staker has staked
        for (uint i = 0; i < stakerCounter; i++)
        {
            address currentStaker = stakers[i];
            //uint currentStakerBalance = stakingToken.balanceOf(currentStaker);
            
            if (stakingToken.balanceOf(currentStaker) > 500000000000000000)
            {
                //get share of staker's staked tokens
            uint currentStakerShare = stakingToken.balanceOf(currentStaker).div(totalStakingTokens);
            //calculate how many tokens each staker should get based on their share of staked tokens
            uint currentStakerPayout = currentStakerShare.mul(amount);
            //update availableClaim for staker
            availableClaim[currentStaker] += currentStakerPayout;
            }
            
        }

    } */
    
    function calculateTokenPayouts(address _tokenContract, uint256 _amount) internal {
        uint totalStakingTokens = stakingToken.totalSupply();

        for  (uint i = 0; i  < stakerCounter; i++){
            //address currentStaker = stakers[i];
            
            
            if (stakingToken.balanceOf(stakers[i]) > 500000000000000000)
            {
                //get share of staker's staked tokens
            uint currentStakerShare = stakingToken.balanceOf(stakers[i]) / totalStakingTokens;
            //calculate how many tokens each staker should get based on their share of staked tokens
            uint currentStakerPayout = currentStakerShare * _amount;
            //update availableClaim for staker
            availableTokenClaims[stakers[i]][_tokenContract] += currentStakerPayout;     
            }
            
        }
 
    }
    

    function claimPayout() public
    {
        address payable to = msg.sender;
        uint256 amount = availableClaim[msg.sender];

        require (availableClaim[msg.sender] > 0, "No payout available");        
        availableClaim[msg.sender] = 0;    
        //transfer ether to caller
        to.transfer(amount);
        
        //IERC20(paymentToken).transfer(msg.sender, amount);        
    }

    function claimTokenPayout(address _tokenContract) public {
        address to = msg.sender;
        uint256 amount =  availableTokenClaims[msg.sender][_tokenContract];

        require (availableTokenClaims[msg.sender][_tokenContract] > 0, "No payout available");
        availableTokenClaims[msg.sender][_tokenContract] = 0;
        IERC20(_tokenContract).transfer(to, amount);
    }
    
    function checkEligibility(address stakerAddress) public view returns (bool) {
        uint currentStakerBalance = stakingToken.balanceOf(stakerAddress);
            
            if (currentStakerBalance > 500000000000000000)
            {
                return true;
            }
            return false;
        
    }
    function checkLevel(address stakerAddress) public view returns (uint) {
        uint currentStakerBalance = stakingToken.balanceOf(stakerAddress);
        uint level;
            if (currentStakerBalance >= 50000000000000000000000)
            {
                level = 5;
            }
            if (currentStakerBalance >= 40000000000000000000000 && currentStakerBalance < 50000000000000000000000)
            {
                level = 4;
            }
            {
                level = 4;
            }
            if (currentStakerBalance >= 20000000000000000000000 && currentStakerBalance < 40000000000000000000000)
            {
                level = 3;
            }
            {
                level = 3;
            }
            if (currentStakerBalance >= 1000000000000000000000 && currentStakerBalance < 20000000000000000000000)
            {
                level = 2;
            }
            {
                level = 2;
            }
            if (currentStakerBalance >= 5000000000000000000000 && currentStakerBalance < 1000000000000000000000)
            {
                level = 1;
            }
            return level;
    }

    function checkAvailableClaim(address _address) public view returns (uint256) {
        return availableClaim[_address];
    }

    function canRecoverTokens(IERC20 token) internal override view returns (bool) 
    { 
        return address(token) != address(this); 
    }
}