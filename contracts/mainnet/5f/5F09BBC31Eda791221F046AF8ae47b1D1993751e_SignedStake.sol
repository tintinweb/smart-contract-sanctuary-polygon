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

    StakingToken public stakingToken;//SIGNED STAKING

    //pass in nft address, then nft id, spits out availableClaim
    mapping(address => uint256) public availableClaim;
    //mapping  of a mapping
    mapping(address => mapping(address => uint256)) public availableTokenClaims;
    /* mapping (IERC20 => address[]) public feeCollectors;
    mapping (IERC20 => uint256[]) public feeRates;
    mapping (IERC20 => uint256) public burnRates; */

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

    function register() public 
    {
        if (addressLogged[msg.sender] == false)
        {
            addressLogged[msg.sender] = true;
            stakers[stakerCounter] = msg.sender;
            stakerCounter++;
        }
    }

     /* function depositFees(address _nftContract, uint256 _amount) override public 
    {
        calculatePayouts(_nftContract, _amount);
        IERC20(paymentToken).transferFrom(msg.sender, address(this), _amount);
    } */

    function depositMatic() public payable override onlyOwnerOrDev() {
            uint256 amount = msg.value;
            calculatePayouts(amount);

        }
    function depositTokens(address tokenContract, uint256 amount) public onlyOwnerOrDev(){

        calculateTokenPayouts(tokenContract, amount);
        IERC20(tokenContract).transferFrom(msg.sender, address(this), amount);
    }
    
    function calculatePayouts(uint256 amount) internal {
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

    }
    function calculatePayoutsTEST(uint256 amount) public view returns (uint256 currentStakerPayout) {
        uint totalStakingTokens = stakingToken.totalSupply();

        for (uint i = 0; i < stakerCounter; i++)
        {
            address currentStaker = stakers[i];
            uint256 currentStakerBalance = stakingToken.balanceOf(currentStaker);
            
            if (currentStakerBalance > 500000000000000000)
            {
                    //get share of staker's staked tokens
            uint256 currentStakerShare = currentStakerBalance.div(totalStakingTokens);
            //calculate how many tokens each staker should get based on their share of staked tokens
            currentStakerPayout = currentStakerShare.mul(amount);

            //update availableClaim for staker
            //availableClaim[currentStaker] += currentStakerPayout;
            return currentStakerPayout; 
            
            } 
            
        }
        

    }
    function calculatePayoutsTEST2(uint256 amount) public view returns (uint currentStakerPayout) {
        uint totalStakingTokens = stakingToken.totalSupply();

        for (uint i = 0; i < stakerCounter; i++)
        {
            address currentStaker = stakers[i];
            //uint currentStakerBalance = stakingToken.balanceOf(currentStaker);
            
            if (stakingToken.balanceOf(currentStaker) > 500000000000000000)
            {
                    //get share of staker's staked tokens
            currentStakerPayout = stakingToken.balanceOf(currentStaker).div(stakingToken.totalSupply()).mul(amount);
            //calculate how many tokens each staker should get based on their share of staked tokens
            //currentStakerPayout = currentStakerShare * amount;

            //update availableClaim for staker
            //availableClaim[currentStaker] += currentStakerPayout;
            return currentStakerPayout; 
            
            } 
            
        }
        

    }
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

    function checkAvailableClaim(address _address) public view returns (uint256) {
        return availableClaim[_address];
    }

    function canRecoverTokens(IERC20 token) internal override view returns (bool) 
    { 
        return address(token) != address(this); 
    }
}