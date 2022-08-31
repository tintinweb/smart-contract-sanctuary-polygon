pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;
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
    
    mapping (uint => address) public stakers;
    uint private stakerCounter;
    mapping (address => bool) public addressLogged;
    mapping (address => bool) public tokenLogged;
    uint public maticPaidOut;
    mapping (address => uint) public tokensPaidOut;
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

    struct PayOutInfo {
        address[] tokenAddresses;
        uint[] amount;
    }
    //address[] tokenContracts;
    //uint256[]  tokenAmounts;
    //mapping (address => PayOutInfo) public availableTokenPayout;
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
        //require (tokenList.length < 100, "Token list is full");
        tokenLogged[_token] = true;
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
            maticPaidOut += amount;
            calculatePayouts(amount);

        }
    function depositTokens(address tokenContract, uint256 amount) public onlyOwnerOrDev(){
        require(tokenLogged[tokenContract], "Token not registered");
        tokensPaidOut[tokenContract] += amount;
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

    
    
    function calculateTokenPayouts(address _tokenContract, uint256 _amount) internal {
        uint levelOnePayout = (stakerRates[0] * _amount / 10000) / stakerTracker.levelOneStakers;
        uint levelTwoPayout = (stakerRates[1] * _amount / 10000) / stakerTracker.levelTwoStakers;
        uint levelThreePayout = (stakerRates[2] * _amount / 10000) / stakerTracker.levelThreeStakers;
        uint levelFourPayout = (stakerRates[3] * _amount / 10000) / stakerTracker.levelFourStakers;
        uint levelFivePayout = (stakerRates[4] * _amount / 10000) / stakerTracker.levelFiveStakers;
        for (uint i = 0; i < stakerCounter; i++)
        {
            uint level = checkLevel(stakers[i]);
            if (level == 1)
            {
                availableTokenClaims[stakers[i]][_tokenContract] = levelOnePayout;
            }
            else if (level == 2)
            {
                availableTokenClaims[stakers[i]][_tokenContract] = levelTwoPayout;
            }
            else if (level == 3)
            {
                availableTokenClaims[stakers[i]][_tokenContract] = levelThreePayout;
            }
            else if (level == 4)
            {
                availableTokenClaims[stakers[i]][_tokenContract] = levelFourPayout;
            }
            else if (level == 5)
            {
                availableTokenClaims[stakers[i]][_tokenContract] = levelFivePayout;
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
        
           
    }

    function claimTokenPayout() public {
        for (uint i = 0; i < tokenList.length; i++)
        {
            address tokenContract = tokenList[i];
            uint256 amount = availableTokenClaims[msg.sender][tokenContract];
            if (amount > 0) {
            availableTokenClaims[msg.sender][tokenContract] = 0;
            IERC20(tokenContract).transfer(msg.sender, amount);
            }
            
        }
    }
    function claimIndividualToken(address tokenContract) public {
        uint256 amount = availableTokenClaims[msg.sender][tokenContract];
        if (amount > 0) {
            availableTokenClaims[msg.sender][tokenContract] = 0;
            IERC20(tokenContract).transfer(msg.sender, amount);
        }
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

    function resetPayOutForStaker(address stakerAddress) public onlyOwnerOrDev() {
        availableClaim[stakerAddress] = 0;
    }

    function checkAvailableClaim(address _address) public view returns (uint256) {
        return availableClaim[_address];
    }

    
    function checkTokenClaims(address staker) public view returns (PayOutInfo memory) {
        PayOutInfo memory _payoutInfo;
        address[] memory tokenContracts;
        uint[] memory tokenAmounts;
        //tokenContracts = new address[](1);
        uint eligibleTokens = 0;
        

        for (uint i = 0; i < tokenList.length; i++)
        {
            address tokenContract = tokenList[i];
            //check if staker has claimable tokens
            if (availableTokenClaims[staker][tokenContract] > 0)
            {
                eligibleTokens++;
            } 
            //_payoutInfo.tokenAddresses.push(availableTokenClaims[staker][tokenContract]);
        }

        tokenContracts = new address[](eligibleTokens);
        tokenAmounts = new uint[](eligibleTokens);
        
        for (uint i = 0; i < tokenList.length; i++)
        {
            address tokenContract = tokenList[i];
            //check if staker has claimable tokens
            if (availableTokenClaims[staker][tokenContract] > 0)
            {
                //add token contract to array
                tokenContracts[i] = tokenContract;
                //add amount to array
                tokenAmounts[i] = availableTokenClaims[staker][tokenContract];
            } 
            
        }
        _payoutInfo = PayOutInfo(tokenContracts, tokenAmounts);
        //reset tokencontracts and tokenamounts arrays  
       
        return _payoutInfo;
    }

    function canRecoverTokens(IERC20 token) internal override view returns (bool) 
    { 
        return address(token) != address(this); 
    }
    

     function recoverTokens(address tokenAddress, uint256 amount) public onlyOwnerOrDev() {
        IERC20(tokenAddress).safeTransfer(msg.sender, amount);
    } 
}