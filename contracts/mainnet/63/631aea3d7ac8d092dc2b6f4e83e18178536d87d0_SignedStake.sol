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
    address payable public excessRecoveryAddress;
    
    mapping (uint => address) public stakers;
    uint private stakerCounter;
    mapping (address => bool) public addressLogged;
    mapping (address => bool) public tokenLogged;
    uint public maticPaidOut;
    mapping (address => bool) public depositContract;
    mapping (address => uint) public tokensPaidOut;
    //uint[] public stakerRates = [4000, 3000, 1500, 1000, 500];
    uint[] public stakerRates = [500, 1000, 1500, 3000, 4000];
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
        require (msg.sender == deployerAddress || msg.sender == devAddress || msg.sender == owner || depositContract[msg.sender] == true, "Not a deployer or dev address");
        _;
    }

    function setDevAddress(address _devAddress) public
    {
        require (msg.sender == deployerAddress || msg.sender == devAddress, "Not a deployer or dev address");
        devAddress = _devAddress;
    }
    function setExcessRecovery(address payable _excessRecoveryAddress) public onlyOwnerOrDev()
    {
     
        excessRecoveryAddress = _excessRecoveryAddress;
    }
    function setStakingToken(StakingToken _stakingToken) public onlyOwnerOrDev()
    {
        stakingToken = _stakingToken;
    }
    function setDepositContract(address _depositContract) public onlyOwnerOrDev()
    {
        depositContract[_depositContract] = !depositContract[_depositContract];
    }
    //check registered addresses and update staker levels
    function updateStakerLevels() public
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
        require(tokenLogged[_token] == false, "Token already logged");
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
    function registerUser(address _user) public onlyOwnerOrDev() {
        if (addressLogged[_user] == false)
        {
            addressLogged[_user] = true;
            stakers[stakerCounter] = _user;
            stakerInfo[_user].staker = _user;
            stakerCounter++;
        }
    }

    function depositMatic() public payable override onlyOwnerOrDev() {
            updateStakerLevels();
            uint256 amount = msg.value;
            maticPaidOut += amount;
            calculateExcess(msg.value);
            calculatePayouts(amount);
            
        }
    function depositTokens(address tokenContract, uint256 amount) public onlyOwnerOrDev(){
        require(tokenLogged[tokenContract], "Token not registered");
        updateStakerLevels();
        checkZeroStakers();
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

    function calculateExcess(uint256 amount) internal {
        uint256 excess;
        //check for 0 stakers
        if (stakerTracker.levelOneStakers == 0)
        {
            excess += stakerRates[0] * amount / 10000;
            stakerTracker.levelOneStakers = 1;  
        }
        if (stakerTracker.levelTwoStakers == 0)
        {
            excess += stakerRates[1] * amount / 10000;
            stakerTracker.levelTwoStakers = 1;
        }
        if (stakerTracker.levelThreeStakers == 0)
        {
            excess += stakerRates[2] * amount / 10000;
            stakerTracker.levelThreeStakers = 1;
        }
        if (stakerTracker.levelFourStakers == 0)
        {
            excess += stakerRates[3] * amount / 10000;
            stakerTracker.levelFourStakers = 1;
        }
        if (stakerTracker.levelFiveStakers == 0)
        {
            excess += stakerRates[4] * amount / 10000;
            stakerTracker.levelFiveStakers = 1;
        }
        recoverExcess(excess);
    }
    function checkZeroStakers() internal {
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
    function calculateExcessView(uint256 amount) public view returns (uint256){
        uint256 excess;
        //check for 0 stakers
        if (stakerTracker.levelOneStakers == 0)
        {
            excess += stakerRates[0] * amount / 10000;
        }
        if (stakerTracker.levelTwoStakers == 0)
        {
            excess += stakerRates[1] * amount / 10000;
        }
        if (stakerTracker.levelThreeStakers == 0)
        {
            excess += stakerRates[2] * amount / 10000;
        }
        if (stakerTracker.levelFourStakers == 0)
        {
            excess += stakerRates[3] * amount / 10000;
        }
        if (stakerTracker.levelFiveStakers == 0)
        {
            excess += stakerRates[4] * amount / 10000;
        }
        return excess;
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
                availableTokenClaims[stakers[i]][_tokenContract] += levelOnePayout;
            }
            else if (level == 2)
            {
                availableTokenClaims[stakers[i]][_tokenContract] += levelTwoPayout;
            }
            else if (level == 3)
            {
                availableTokenClaims[stakers[i]][_tokenContract] += levelThreePayout;
            }
            else if (level == 4)
            {
                availableTokenClaims[stakers[i]][_tokenContract] += levelFourPayout;
            }
            else if (level == 5)
            {
                availableTokenClaims[stakers[i]][_tokenContract] += levelFivePayout;
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
            if (currentStakerBalance >= 40000000000000000000000 && currentStakerBalance < 50000000000000000000000) // bal >=  40k and bal < 50k
            {
                level = 4;
            }
            if (currentStakerBalance >= 20000000000000000000000 && currentStakerBalance < 40000000000000000000000) // bal >= 20k and bal < 40k
            {
                level = 3;
            }
            if (currentStakerBalance >= 10000000000000000000000 && currentStakerBalance < 20000000000000000000000) // bal >= 10k and < 20k
            {
                level = 2;
            }
            if (currentStakerBalance >= 5000000000000000000000 && currentStakerBalance < 10000000000000000000000) // bal >= 5k and bal < 10k 
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

    function recoverExcess(uint256 _excess) public onlyOwnerOrDev() {
        //transfer eth to excessrecovery
        (bool sent, bytes memory data) = excessRecoveryAddress.call{value: _excess}("");


    }
}