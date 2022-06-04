// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "./IERC20.sol";
import "./RootedToken.sol";
import "./Owned.sol";
import "./EliteToken.sol";
import "./MarketGeneration.sol";
import "./MarketDistribution.sol";
import "./LazarusPit.sol";
import "./RootedTransferGate.sol";
import "./EliteFloorCalculator.sol";
import "./EliteFloorCalculatorV1.sol";
import "./FeeSplitter.sol";
import "./LiquidityController.sol";
import "./StakingToken.sol";
import "./RoyaltyPump.sol";
import "./TokenTimelock.sol";

contract TokenFactory is Owned {
address factory;
//WETH MATIC MAINNET
IERC20 wrappedToken = IERC20(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);

modifier onlyFactory {
    require(msg.sender == factory || msg.sender == owner);
    _;
}
function setFactory(address _factory) public ownerOnly() {
    factory = _factory;
}
function createRooted(string memory name, string memory ticker) public onlyFactory() returns(RootedToken) {
    return new RootedToken(name, ticker);
}

function createElite() public onlyFactory() returns(EliteToken) {
    return new EliteToken(wrappedToken);
}
 
    
}

// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

interface IERC20 
{
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address _account) external view returns (uint256);
    function transfer(address _recipient, uint256 _amount) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function approve(address _spender, uint256 _amount) external returns (bool);
    function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

/* ROOTKIT: upToken

An upToken is a token that gains in value
against whatever token it is paired with.

- Raise any token using the Market Generation
and Market Distribution contracts
- An equal amount of upToken will be minted
- combine with an ERC-31337 version of the 
raised token.
- Send LP tokens to the Liquidity Controller
for efficent access to market features

*/

import "./LiquidityLockedERC20.sol";

contract RootedToken is LiquidityLockedERC20
{
    constructor(
        string memory _name,
        string memory _symbol
    )
    LiquidityLockedERC20(_name, _symbol)
    {
    }
    address public minter;

    function setMinter(address _minter) public ownerOnly()
    {
        minter = _minter;
    }

    function mint(uint256 amount) public
    {
        require(msg.sender == minter, "Not a minter");
        require(this.totalSupply() == 0, "Already minted");
        _mint(msg.sender, amount);
    }
}

// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

/* ROOTKIT:
Provides ownerOnly() modifier
Allows for ownership transfer but requires the new
owner to claim (accept) ownership
Safer because no accidental transfers or renouncing
*/

import "./IOwned.sol";

abstract contract Owned is IOwned
{
    address public override owner = msg.sender;
    address internal pendingOwner;

    modifier ownerOnly()
    {
        require (msg.sender == owner, "Owner only");
        _;
    }

    function transferOwnership(address newOwner) public override ownerOnly()
    {
        pendingOwner = newOwner;
    }

    function claimOwnership() public override
    {
        require (pendingOwner == msg.sender);
        pendingOwner = address(0);
        emit OwnershipTransferred(owner, msg.sender);
        owner = msg.sender;
    }
}

// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

import "./ERC31337.sol";
import "./IERC20.sol";

contract EliteToken is ERC31337
{
    using Address for address;
    using SafeMath for uint256;
    
    mapping (address => bool) public freeParticipantControllers;
    mapping (address => bool) public freeParticipants; 

    mapping (address => bool) public burnRateControllers;
    uint16 burnRate;   

    constructor (IERC20 _wrappedToken) ERC31337(_wrappedToken, "eToken", "eToke")
    {
    }    

    function setFreeParticipantController(address freeParticipantController, bool allow) public ownerOnly()
    {
        freeParticipantControllers[freeParticipantController] = allow;
    }

    function setFreeParticipant(address participant, bool free) public
    {
        require (msg.sender == owner || freeParticipantControllers[msg.sender], "Not an owner or free participant controller");
        freeParticipants[participant] = free;
    }

    function setBurnRateController(address burnRateController, bool allow) public ownerOnly()
    {
        burnRateControllers[burnRateController] = allow;
    }

    function setBurnRate(uint16 _burnRate) public // 10000 = 100%
    {
        require (msg.sender == owner || burnRateControllers[msg.sender], "Not an owner or burn rate controller");
        require (_burnRate <= 10000, "But rate must be less or equal to 100%");
       
        burnRate = _burnRate;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override 
    {
        require(sender != address(0), "EliteToken: transfer from the zero address");
        require(recipient != address(0), "EliteToken: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);
        uint256 remaining = amount;

        if (!freeParticipants[sender] && !freeParticipants[recipient] && burnRate > 0)
        {
            uint256 burn = amount * burnRate / 10000;
            amount = remaining = remaining.sub(burn, "Burn too much");
            _burn(sender, burn);
        }
        
        _balanceOf[sender] = _balanceOf[sender].sub(amount, "EliteToken: transfer amount exceeds balance");
        _balanceOf[recipient] = _balanceOf[recipient].add(remaining);
        
        emit Transfer(sender, recipient, remaining);
    }
}

// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

import "./IMarketDistribution.sol";
import "./IMarketGeneration.sol";
import "./TokensRecoverable.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./IWBNB.sol";

contract MarketGeneration is TokensRecoverable, IMarketGeneration
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    mapping (address => uint256) public override contribution;
    mapping (address => uint256) public override referralPoints;
    mapping (address => bool) public mgeController;
    uint256 public override totalReferralPoints;
    uint256 public override totalContribution;
    address public immutable devAddress;
    uint public startDate;
    uint public endDate;   
    bool public dateLimitActive; 

    bool public isActive;
    uint public hardCap;
    uint public softCap;
    IERC20 public baseToken;
    IMarketDistribution public marketDistribution;
    uint256 public refundsAllowedUntil;

    constructor(address _devAddress)
    {
        devAddress = _devAddress;
        mgeController[owner] = true;
    }

    modifier active()
    {
        require (isActive, "Distribution not active");
        _;
    }
    modifier isController(){
        require(mgeController[msg.sender] || msg.sender == owner, "Only controller or owner can do this");
        _;
    }

    function init(IERC20 _baseToken) public  isController()
    {
        require (!isActive && block.timestamp >= refundsAllowedUntil, "Already activated");
        baseToken = _baseToken;
    }
    function setHardCap(uint _hardCap) public  isController()
    {
        //require (!isActive, "Already activated");
        require(_hardCap > hardCap, "Hard cap must be greater than current hard cap");
        hardCap = _hardCap;
    }
    function setSoftCap(uint _softCap) public  isController()
    {
        softCap = _softCap;
    }
    function setMGEController(address _controller) public  isController()
    {
        mgeController[_controller] = !mgeController[_controller];
    }

    function activate(IMarketDistribution _marketDistribution, uint mgeLengthInSeconds) public  isController()
    {
        require (!isActive && block.timestamp >= refundsAllowedUntil, "Already activated");        
        require (address(_marketDistribution) != address(0));
        marketDistribution = _marketDistribution;
        startDate = block.timestamp;
        endDate = startDate + mgeLengthInSeconds;
        isActive = true;
    }
    function activateDeactivateDateLimit() public  isController()
    {
        dateLimitActive = !dateLimitActive;
    }
    function setMGELength(uint timeInSeconds) public  isController()
    {
        require (isActive);
        endDate = startDate + timeInSeconds;
    }

    function setMarketDistribution(IMarketDistribution _marketDistribution) public  isController() active()
    {
        require (address(_marketDistribution) != address(0), "Invalid market distribution");
        if (_marketDistribution == marketDistribution) { return; }
        marketDistribution = _marketDistribution;

        // Give everyone 1 day to claim refunds if they don't approve of the new distributor
        refundsAllowedUntil = block.timestamp + 86400;
    }

    function complete(
        uint16 _preBuyForReferralsPercent, 
        uint16 _preBuyForContributorsPercent, 
        uint16 _preBuyForMarketStabilizationPercent
    ) public  isController() active()
    {
        require (block.timestamp >= refundsAllowedUntil, "Refund period is still active");
        isActive = false;
        if (address(this).balance == 0) { return; }
        IWBNB(address(baseToken)).deposit{ value: address(this).balance }();
        baseToken.safeApprove(address(marketDistribution), uint256(-1));
        endDate = block.timestamp;
        marketDistribution.distribute(_preBuyForReferralsPercent, _preBuyForContributorsPercent, _preBuyForMarketStabilizationPercent);
    }

    function allowRefunds() public  isController() active()
    {
        isActive = false;
        refundsAllowedUntil = uint256(-1);
    }

    function refund(uint256 amount) private
    {
        (bool success,) = msg.sender.call{ value: amount }("");
        require (success, "Refund transfer failed");  
          
        totalContribution -= amount;
        contribution[msg.sender] = 0;

        uint256 refPoints = referralPoints[msg.sender];

        if (refPoints > 0)
        {
            totalReferralPoints -= refPoints;
            referralPoints[msg.sender] = 0;
        }
    }

    function claim() public 
    {
        uint256 amount = contribution[msg.sender];

        require (amount > 0, "Nothing to claim");
        
        if (refundsAllowedUntil > block.timestamp) 
        {
            refund(amount);
        }
        else 
        {
            marketDistribution.claim(msg.sender);
        }
    }

    function claimReferralRewards() public
    {
        require (referralPoints[msg.sender] > 0, "No rewards to claim");
        
        uint256 refShare = referralPoints[msg.sender];
        referralPoints[msg.sender] = 0;
        marketDistribution.claimReferralRewards(msg.sender, refShare);
    }

    function contribute(address referral) public payable active() 
    {
        //require contribution does not exceed hard cap
        require (totalContribution + msg.value <= hardCap, "Contribution exceeds hard cap");
        //require contribution to be before end date
        require (block.timestamp < endDate, "Contribution after end date");
        
        if (referral == address(0) || referral == msg.sender) 
        {
            referralPoints[devAddress] += msg.value;
            totalReferralPoints += msg.value;
        }
        else 
        {
            referralPoints[msg.sender] += msg.value;
            referralPoints[referral] += msg.value;
            totalReferralPoints +=(msg.value + msg.value);
        }

        contribution[msg.sender] += msg.value;
        totalContribution += msg.value;
    }

    receive() external payable active()
    {
        contribute(address(0));
    }
}

// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

import "./IMarketDistribution.sol";
import "./IMarketGeneration.sol";
import "./RootedToken.sol";
import "./RootedTransferGate.sol";
import "./TokensRecoverable.sol";
import "./SafeMath.sol";
import "./IERC31337.sol";
import "./IERC20.sol";
import "./IPancakeRouter02.sol";
import "./IPancakeFactory.sol";
import "./IPancakePair.sol";
import "./SafeERC20.sol";

/*
Introducing the Market Generation Event:

Allows full and permanent liquidity locking
of all raised funds with no commitment to LPs. 
Using ERC-31337 we get ALL the raised funds
back from liquidity if we lock all the raised
token with all the supply of the new token and
there is no ability to mint.

- Raise with any token
- All raised funds get locked forever
- ERC-31337 sweeps back all locked value
- Recovered value buys from the new market
- Any length vesting period
- Built in referral system

Phases:
    Initializing
        Call setupEliteRooted()
        Call setupBaseRooted() 
        Call completeSetup()
        
    Call distribute() to:
        Transfer all rootedToken to this contract
        Take all BaseToken + rootedToken and create a market
        Sweep the floor
        Buy rootedToken for the groups
        Move liquidity from elite pool to create standard pool
        Begin the vesting period with a linier unlock

    Complete
        Everyone can call claim() to receive their tokens (via the liquidity generation contract)
*/

contract MarketDistribution is TokensRecoverable, IMarketDistribution
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bool public override distributionComplete;

    address public lazarusPit;
    IMarketGeneration public marketGeneration;
    IPancakeRouter02 pancakeRouter;
    IPancakeFactory pancakeFactory;
    RootedToken public rootedToken;
    IERC31337 public eliteToken;
    IERC20 public baseToken;
    address public immutable devAddress;
    address public liquidityController;
    IPancakePair public rootedEliteLP;
    IPancakePair public rootedBaseLP;

    // uint256 public constant rootedTokenSupply = 1e25; // 10 million
    uint256 public constant rootedTokenSupply = 1e25 / 10;
    uint256 public totalBaseTokenCollected;
    uint256 public totalBoughtForContributors;
    mapping (address => uint256) public claimTime;
    mapping (address => uint256) public totalClaim;
    mapping (address => uint256) public remainingClaim;
    uint256 public totalBoughtForReferrals;
    
    uint256 public recoveryDate = block.timestamp + 2592000; // 1 Month
    
    uint16 public devCutPercent;
    uint16 public preBuyForReferralsPercent;
    uint16 public preBuyForContributorsPercent;
    uint16 public preBuyForMarketStabilizationPercent;
    uint256 public override vestingPeriodStartTime;
    uint256 public override vestingPeriodEndTime; 
    uint256 public vestingDuration;
    uint256 public rootedBottom;
    address signedTradeAddress = 0x4F0f5547Be4d3D58A35Dba7F6c0B36656a6F5f05;
    address cartierAddress = 0x5c18fb079fDB7f5D5e6377a73ca03Ad978b23E5C;
    uint256 musicianCut = 900;
    constructor(address _devAddress)
    {
        devAddress = _devAddress;
    }

    function init(
        RootedToken _rootedToken, 
        IERC31337 _eliteToken, 
        address _lazarusPit,
        address _liquidityController,
        IPancakeRouter02 _pancakeRouter, 
        IMarketGeneration _marketGeneration,
        uint256 _vestingDuration, 
        uint16 _devCutPercent/* ,
        uint16 _preBuyForReferralsPercent, 
        uint16 _preBuyForContributorsPercent, 
        uint16 _preBuyForMarketStabilizationPercent */
        ) public ownerOnly()
    {        
        rootedToken = _rootedToken;
        eliteToken = _eliteToken;
        lazarusPit = _lazarusPit;
        baseToken = _eliteToken.wrappedToken();
        liquidityController = _liquidityController;
        pancakeRouter = _pancakeRouter;
        pancakeFactory = IPancakeFactory(_pancakeRouter.factory());
        marketGeneration = _marketGeneration;
        vestingDuration = _vestingDuration;
        devCutPercent = _devCutPercent;
        
        
    }

    function setupEliteRooted() public
    {
        rootedEliteLP = IPancakePair(pancakeFactory.getPair(address(eliteToken), address(rootedToken)));
        if (address(rootedEliteLP) == address(0)) 
        {
            rootedEliteLP = IPancakePair(pancakeFactory.createPair(address(eliteToken), address(rootedToken)));
            require (address(rootedEliteLP) != address(0));
        }
    }

    function setupBaseRooted() public
    {
        rootedBaseLP = IPancakePair(pancakeFactory.getPair(address(baseToken), address(rootedToken)));
        if (address(rootedBaseLP) == address(0)) 
        {
            rootedBaseLP = IPancakePair(pancakeFactory.createPair(address(baseToken), address(rootedToken)));
            require (address(rootedBaseLP) != address(0));
        }
    }

    function completeSetup() public ownerOnly()
    {   
        require (address(rootedEliteLP) != address(0), "Rooted Elite pool is not created");
        require (address(rootedBaseLP) != address(0), "Rooted Base pool is not created");   

        eliteToken.approve(address(pancakeRouter), uint256(-1));
        rootedToken.approve(address(pancakeRouter), uint256(-1));
        baseToken.safeApprove(address(pancakeRouter), uint256(-1));
        baseToken.safeApprove(address(eliteToken), uint256(-1));
        rootedBaseLP.approve(address(pancakeRouter), uint256(-1));
        rootedEliteLP.approve(address(pancakeRouter), uint256(-1));
    }

    function distribute(uint16 _preBuyForReferralsPercent, 
        uint16 _preBuyForContributorsPercent, 
        uint16 _preBuyForMarketStabilizationPercent) public override
    {
        require (msg.sender == address(marketGeneration), "Unauthorized");
        require (!distributionComplete, "Distribution complete");
    preBuyForReferralsPercent = _preBuyForReferralsPercent;
        preBuyForContributorsPercent = _preBuyForContributorsPercent;
        preBuyForMarketStabilizationPercent = _preBuyForMarketStabilizationPercent;
        
   
        vestingPeriodStartTime = block.timestamp;
        vestingPeriodEndTime = block.timestamp + vestingDuration;
        distributionComplete = true;
        totalBaseTokenCollected = baseToken.balanceOf(address(marketGeneration));
        baseToken.safeTransferFrom(msg.sender, address(this), totalBaseTokenCollected);  

        RootedTransferGate gate = RootedTransferGate(address(rootedToken.transferGate()));

        gate.setUnrestricted(true);
        rootedToken.mint(rootedTokenSupply);

        // add 5% of supply to liquidity controller for burns
       rootedToken.transfer(liquidityController, rootedTokenSupply.mul(5).div(100));
    
        rootedToken.transfer(devAddress, rootedTokenSupply.mul(6).div(100)); 

        createRootedEliteLiquidity();

        eliteToken.sweepFloor(address(this));        
        eliteToken.depositTokens(baseToken.balanceOf(address(this)));
                
        buyTheBottom();        
        //preBuyForReferrals();
        preBuyForContributors();
        sellTheTop();        

        uint256 signedCut = totalBaseTokenCollected * devCutPercent / 10000;
        uint256 cartiCut = totalBaseTokenCollected * musicianCut / 10000;
        //baseToken.transfer(cartierAddress, cartiCut); transfer these balances from liquidity controller
        //baseToken.transfer(signedTradeAddress, signedCut); transfer these balances from liquidity controller
        baseToken.transfer(liquidityController, baseToken.balanceOf(address(this)));      

        createRootedBaseLiquidity();    

        gate.setUnrestricted(false);
    }   
   
    
    function createRootedEliteLiquidity() private
    {
        // Create Rooted/Elite LP 
        eliteToken.depositTokens(baseToken.balanceOf(address(this)));
        pancakeRouter.addLiquidity(address(eliteToken), address(rootedToken), eliteToken.balanceOf(address(this)), rootedToken.balanceOf(address(this)), 0, 0, address(this), block.timestamp);
    }

    function buyTheBottom() private
    {
        uint256 amount = totalBaseTokenCollected * preBuyForMarketStabilizationPercent / 10000;  
        uint256[] memory amounts = pancakeRouter.swapExactTokensForTokens(amount, 0, eliteRootedPath(), address(this), block.timestamp);        
        rootedBottom = amounts[1];
    }

    function sellTheTop() private
    {
        uint256[] memory amounts = pancakeRouter.swapExactTokensForTokens(rootedBottom, 0, rootedElitePath(), address(this), block.timestamp);
        uint256 eliteAmount = amounts[1];
        eliteToken.withdrawTokens(eliteAmount);
    }   
    
    function preBuyForReferrals() private 
    {
        uint256 amount = totalBaseTokenCollected * preBuyForReferralsPercent / 10000;
        uint256[] memory amounts = pancakeRouter.swapExactTokensForTokens(amount, 0, eliteRootedPath(), address(this), block.timestamp);
        totalBoughtForReferrals = amounts[1];
    }

    function preBuyForContributors() private 
    {
        uint256 preBuyAmount = totalBaseTokenCollected * preBuyForContributorsPercent / 10000;
        uint256 eliteBalance = eliteToken.balanceOf(address(this));
        uint256 amount = preBuyAmount > eliteBalance ? eliteBalance : preBuyAmount;
        uint256[] memory amounts = pancakeRouter.swapExactTokensForTokens(amount, 0, eliteRootedPath(), address(this), block.timestamp);
        totalBoughtForContributors = amounts[1];
    }

    function createRootedBaseLiquidity() private
    {
        uint256 elitePerLpToken = eliteToken.balanceOf(address(rootedEliteLP)).mul(1e18).div(rootedEliteLP.totalSupply());
        uint256 lpAmountToRemove = baseToken.balanceOf(address(eliteToken)).mul(1e18).div(elitePerLpToken);
        
        (uint256 eliteAmount, uint256 rootedAmount) = pancakeRouter.removeLiquidity(address(eliteToken), address(rootedToken), lpAmountToRemove, 0, 0, address(this), block.timestamp);
        
        uint256 baseInElite = baseToken.balanceOf(address(eliteToken));
        uint256 baseAmount = eliteAmount > baseInElite ? baseInElite : eliteAmount;       
        
        eliteToken.withdrawTokens(baseAmount);
        pancakeRouter.addLiquidity(address(baseToken), address(rootedToken), baseAmount, rootedAmount, 0, 0, liquidityController, block.timestamp);
        rootedEliteLP.transfer(liquidityController, rootedEliteLP.balanceOf(address(this)));
        eliteToken.transfer(liquidityController, eliteToken.balanceOf(address(this)));
    }

    function eliteRootedPath() private view returns (address[] memory)
    {
        address[] memory path = new address[](2);
        path[0] = address(eliteToken);
        path[1] = address(rootedToken);
        return path;
    }

    function rootedElitePath() private view returns (address[] memory)
    {
        address[] memory path = new address[](2);
        path[0] = address(rootedToken);
        path[1] = address(eliteToken);
        return path;
    }
    
    function getTotalClaim(address account) public view returns (uint256)
    {
        uint256 contribution = marketGeneration.contribution(account);
        return contribution == 0 ? 0 : contribution.mul(totalBoughtForContributors).div(marketGeneration.totalContribution());
    }

    function getReferralClaim(address account) public view returns (uint256)
    {
        uint256 referralShare = marketGeneration.referralPoints(account);
        return referralShare == 0 ? 0 : referralShare.mul(totalBoughtForReferrals).div(marketGeneration.totalReferralPoints());
    }

    function claim(address account) public override 
    {
        require (distributionComplete, "Distribution is not completed");
        require (msg.sender == address(marketGeneration), "Unauthorized");

        if (totalClaim[account] == 0)
        {
            totalClaim[account] = remainingClaim[account] = getTotalClaim(account);
        }

        uint256 share = totalClaim[account];
        uint256 endTime = vestingPeriodEndTime > block.timestamp ? block.timestamp : vestingPeriodEndTime;

        require (claimTime[account] < endTime, "Already claimed");

        uint256 claimStartTime = claimTime[account] == 0 ? vestingPeriodStartTime : claimTime[account];
        share = (endTime.sub(claimStartTime)).mul(share).div(vestingDuration);
        claimTime[account] = block.timestamp;
        remainingClaim[account] -= share;
        rootedToken.transfer(account, share);
    }

    function claimReferralRewards(address account, uint256 referralShare) public override 
    {
        require (distributionComplete, "Distribution is not completed");
        require (msg.sender == address(marketGeneration), "Unauthorized");

        uint256 share = referralShare.mul(totalBoughtForReferrals).div(marketGeneration.totalReferralPoints());
        rootedToken.transfer(account, share);
    }

    function canRecoverTokens(IERC20 token) internal override view returns (bool) 
    { 
        return block.timestamp > recoveryDate || token != rootedToken;
    }
}

pragma solidity ^0.7.4;
//The graveyard is a step above a simple burn address 
//It will serve the community by collecting a redistributing fees
//Oscillatig between 50-51%
import "./ERC20.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./Address.sol";

contract LazarusPit is Context, Ownable {
    using SafeMath for uint256;
    using Address for address;

    uint256 public lastRebalance;
    uint256 public immutable upperboundPercentage = 51;


    IERC20 public immutable token;

    event Rebalance(
        uint256 tokens
    );

    constructor (ERC20 _token) public {

        //get a handle on the token
        token = IERC20(_token);

        //a rebalance isn't necessary at launch
        lastRebalance =  block.timestamp;

    }

    function rebalance() external {   
            
        //we should rebalance when we get more than target percentage of the supply in the graveyard
        uint256 upperbound = token.totalSupply().mul(upperboundPercentage).div(100);
        uint256 target =  token.totalSupply().mul(50).div(100);
        uint256 balance = token.balanceOf(address(this));

        //airdrop the difference by sending back to the token contract which will 
        //split rewards and locked liquidity 
        if (balance > upperbound){
            uint256 airdrop = balance.sub(target);

            //send airdrop to token where it will be added to liquidity 
            token.transfer(address(token), airdrop);

            lastRebalance = block.timestamp;

            emit Rebalance(airdrop);
        }

            
    }

    function ready() external view returns (bool) {
            
        //we should rebalance when we get more than 55% of the supply in the graveyard
        uint256 upperbound = token.totalSupply().mul(upperboundPercentage).div(100);
        uint256 balance = token.balanceOf(address(this));

        //airdrop the difference by sending back to the token contract which will 
        //split rewards and locked liquidity 
        if (balance > upperbound){
            return true;
        }
        

        return false;
    }
}

// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

/* ROOTKIT:
A transfer gate (GatedERC20) for use with upTokens

It:
    Allows customization of tax and burn rates
    Allows transfer to/from approved pools
    Disallows transfer to/from non-approved pools
    Allows transfer to/from anywhere else
    Allows for free transfers if permission granted
    Allows for unrestricted transfers if permission granted
    Allows for a pool to have an extra tax
    Allows for a temporary declining tax
*/

import "./Address.sol";
import "./IPancakeFactory.sol";
import "./IERC20.sol";
import "./IPancakePair.sol";
import "./ILiquidityLockedERC20.sol";
import "./IPancakeRouter02.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./TokensRecoverable.sol";
import "./ITransferGate.sol";

contract RootedTransferGate is TokensRecoverable, ITransferGate
{   
    using Address for address;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IPancakeRouter02 immutable internal pancakeRouter;
    IPancakeFactory immutable internal pancakeFactory;
    ILiquidityLockedERC20 immutable internal rootedToken;

    bool public unrestricted;
    mapping (address => bool) public unrestrictedControllers;
    mapping (address => bool) public feeControllers;
    mapping (address => bool) public freeParticipantControllers;
    mapping (address => bool) public freeParticipant;
    mapping (address => uint16) public poolsTaxRates;

    address public override feeSplitter;
    uint16 public feesRate;
    IPancakePair public mainPool;
   
    uint16 public dumpTaxStartRate; 
    uint256 public dumpTaxDurationInSeconds;
    uint256 public dumpTaxEndTimestamp;

    constructor(ILiquidityLockedERC20 _rootedToken, IPancakeRouter02 _pancakeRouter)
    {
        rootedToken = _rootedToken;
        pancakeRouter = _pancakeRouter;
        pancakeFactory = IPancakeFactory(_pancakeRouter.factory());
    }

    function setUnrestrictedController(address unrestrictedController, bool allow) public ownerOnly()
    {
        unrestrictedControllers[unrestrictedController] = allow;
    }

    function setFreeParticipantController(address freeParticipantController, bool allow) public ownerOnly()
    {
        freeParticipantControllers[freeParticipantController] = allow;
    }

    function setFeeControllers(address feeController, bool allow) public ownerOnly()
    {
        feeControllers[feeController] = allow;
    }

    function setFeeSplitter(address _feeSplitter) public ownerOnly()
    {
        feeSplitter = _feeSplitter;
    }

    function setFreeParticipant(address participant, bool free) public
    {
        require (msg.sender == owner || freeParticipantControllers[msg.sender], "Not an owner or free participant controller");
        freeParticipant[participant] = free;
    }

    function setUnrestricted(bool _unrestricted) public
    {
        require (unrestrictedControllers[msg.sender], "Not an unrestricted controller");
        unrestricted = _unrestricted;
        rootedToken.setLiquidityLock(mainPool, !_unrestricted);
    }    

    function setMainPool(IPancakePair _mainPool) public ownerOnly()
    {
        mainPool = _mainPool;
    }

     function setPoolTaxRate(address pool, uint16 taxRate) public ownerOnly()
    {
        require (taxRate <= 10000, "Fee rate must be less than or equal to 100%");
        poolsTaxRates[pool] = taxRate;        
    }

    function setDumpTax(uint16 startTaxRate, uint256 durationInSeconds) public
    {
        require (feeControllers[msg.sender] || msg.sender == owner, "Not an owner or fee controller");
        require (startTaxRate <= 10000, "Dump tax rate must be less than or equal to 100%");

        dumpTaxStartRate = startTaxRate;
        dumpTaxDurationInSeconds = durationInSeconds;
        dumpTaxEndTimestamp = block.timestamp + durationInSeconds;
    }

    function getDumpTax() public view returns (uint256)
    {
        if (block.timestamp >= dumpTaxEndTimestamp) 
        {
            return 0;
        }       
        
        return dumpTaxStartRate*(dumpTaxEndTimestamp - block.timestamp)*1e18/dumpTaxDurationInSeconds/1e18;
    }

    function setFees(uint16 _feesRate) public
    {
        require (feeControllers[msg.sender] || msg.sender == owner, "Not an owner or fee controller");
        require (_feesRate <= 10000, "Fee rate must be less than or equal to 100%");
        feesRate = _feesRate;
    }

    function handleTransfer(address, address from, address to, uint256 amount) public virtual override returns (uint256)
    {
        if (unrestricted || freeParticipant[from] || freeParticipant[to]) 
        {
            return 0;
        }

        uint16 poolTaxRate = poolsTaxRates[to];

        if (poolTaxRate > feesRate) 
        {
            uint256 totalTax = getDumpTax() + poolTaxRate;
            return totalTax >= 10000 ? amount : amount * totalTax / 10000;
        }

        return amount * feesRate / 10000;
    }   
}

// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

/* ROOTKIT:
A floor calculator to use with ERC31337 AMM pairs
Ensures 100% of accessible funds are backed at all times
*/

import "./IFloorCalculator.sol";
import "./SafeMath.sol";
import "./IPancakeRouter02.sol";
import "./IPancakeFactory.sol";
import "./TokensRecoverable.sol";
import "./EnumerableSet.sol";

contract EliteFloorCalculator is IFloorCalculator, TokensRecoverable
{
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    IERC20 immutable rootedToken;
    address immutable rootedElitePair;
    address immutable rootedBasePair;
    IPancakeRouter02 immutable internal pancakeRouter;
    IPancakeFactory immutable internal pancakeFactory;
    EnumerableSet.AddressSet ignoredAddresses;

    constructor(IERC20 _rootedToken, IERC20 _eliteToken, IERC20 _baseToken, IPancakeFactory _pancakeFactory, IPancakeRouter02 _pancakeRouter)
    {
        rootedToken = _rootedToken;
        pancakeFactory = _pancakeFactory;
        pancakeRouter = _pancakeRouter;

        rootedElitePair = _pancakeFactory.getPair(address(_eliteToken), address(_rootedToken));
        rootedBasePair = _pancakeFactory.getPair(address(_baseToken), address(_rootedToken));
    }    


    function setIgnoreAddresses(address ignoredAddress, bool add) public ownerOnly()
    {
        if (add) 
        { 
            ignoredAddresses.add(ignoredAddress); 
        } 
        else 
        { 
            ignoredAddresses.remove(ignoredAddress); 
        }
    }

    function isIgnoredAddress(address ignoredAddress) public view returns (bool)
    {
        return ignoredAddresses.contains(ignoredAddress);
    }

    function ignoredAddressCount() public view returns (uint256)
    {
        return ignoredAddresses.length();
    }

    function ignoredAddressAt(uint256 index) public view returns (address)
    {
        return ignoredAddresses.at(index);
    }

    function ignoredAddressesTotalBalance() public view returns (uint256)
    {
        uint256 total = 0;
        for (uint i = 0; i < ignoredAddresses.length(); i++) 
        {
            total = total.add(rootedToken.balanceOf(ignoredAddresses.at(i)));
        }

        return total;
    }

    function calculateSubFloor(IERC20 baseToken, IERC20 eliteToken) public override view returns (uint256)
    {
        uint256 totalRootedInPairs = rootedToken.balanceOf(rootedElitePair).add(rootedToken.balanceOf(rootedBasePair));
        uint256 totalBaseAndEliteInPairs = eliteToken.balanceOf(rootedElitePair).add(baseToken.balanceOf(rootedBasePair));
        uint256 rootedCirculatingSupply = rootedToken.totalSupply().sub(totalRootedInPairs).sub(ignoredAddressesTotalBalance());
        uint256 amountUntilFloor = pancakeRouter.getAmountOut(rootedCirculatingSupply, totalRootedInPairs, totalBaseAndEliteInPairs);

        uint256 totalExcessInPools = totalBaseAndEliteInPairs.sub(amountUntilFloor);
        uint256 previouslySwept = eliteToken.totalSupply().sub(baseToken.balanceOf(address(eliteToken)));
        
        if (previouslySwept >= totalExcessInPools) { return 0; }

        return totalExcessInPools.sub(previouslySwept);
    }
}

// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

/* ROOTKIT:
A floor calculator to use with ERC31337 AMM pairs
Ensures 100% of accessible funds are backed at all times
*/

import "./IFloorCalculator.sol";
import "./SafeMath.sol";
import "./PancakeLibrary.sol";
import "./IPancakeFactory.sol";
import "./TokensRecoverable.sol";
import "./EnumerableSet.sol";

contract EliteFloorCalculatorV1 is IFloorCalculator, TokensRecoverable
{
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    IERC20 immutable rootedToken;
    IPancakeFactory immutable pancakeFactory;
    EnumerableSet.AddressSet ignoredAddresses;

    constructor(IERC20 _rootedToken, IPancakeFactory _pancakeFactory)
    {
        rootedToken = _rootedToken;
        pancakeFactory = _pancakeFactory;
    }    

    function setIgnoreAddresses(address ignoredAddress, bool add) public ownerOnly()
    {
        if (add) 
        { 
            ignoredAddresses.add(ignoredAddress); 
        } 
        else 
        { 
            ignoredAddresses.remove(ignoredAddress); 
        }
    }

    function isIgnoredAddress(address ignoredAddress) public view returns (bool)
    {
        return ignoredAddresses.contains(ignoredAddress);
    }

    function ignoredAddressCount() public view returns (uint256)
    {
        return ignoredAddresses.length();
    }

    function ignoredAddressAt(uint256 index) public view returns (address)
    {
        return ignoredAddresses.at(index);
    }

    function ignoredAddressesTotalBalance() public view returns (uint256)
    {
        uint256 total = 0;
        for (uint i = 0; i < ignoredAddresses.length(); i++) 
        {
            total = total.add(rootedToken.balanceOf(ignoredAddresses.at(i)));
        }

        return total;
    }

    function calculateExcessInPool(IERC20 token, address pair, uint256 liquidityShare, uint256 rootedTokenTotalSupply, uint256 rootedTokenPoolsLiquidity) internal view returns (uint256)
    {
        uint256 freeRootedToken = (rootedTokenTotalSupply.sub(rootedTokenPoolsLiquidity)).mul(liquidityShare).div(1e12);

        uint256 sellAllProceeds = 0;
        if (freeRootedToken > 0) 
        {
            address[] memory path = new address[](2);
            path[0] = address(rootedToken);
            path[1] = address(token);
            uint256[] memory amountsOut = PancakeLibrary.getAmountsOut(address(pancakeFactory), freeRootedToken, path);
            sellAllProceeds = amountsOut[1];
        }

        uint256 backingInPool = token.balanceOf(pair);
        if (backingInPool <= sellAllProceeds) { return 0; }
        uint256 excessInPool = backingInPool - sellAllProceeds;

        return excessInPool;
    }

    function calculateExcessInPools(IERC20 baseToken, IERC20 eliteToken) public view returns (uint256)
    {
        address rootedElitePair = PancakeLibrary.pairFor(address(pancakeFactory), address(rootedToken), address(eliteToken));
        address rootedBasePair = PancakeLibrary.pairFor(address(pancakeFactory), address(rootedToken), address(baseToken));   
        
        uint256 rootedTokenTotalSupply = rootedToken.totalSupply().sub(ignoredAddressesTotalBalance());
        uint256 rootedTokenPoolsLiquidity = rootedToken.balanceOf(rootedElitePair).add(rootedToken.balanceOf(rootedBasePair));
        uint256 baseTokenPoolsLiquidity = eliteToken.balanceOf(rootedElitePair).add(baseToken.balanceOf(rootedBasePair));

        uint256 rootedLiquidityShareInElitePair = rootedToken.balanceOf(rootedElitePair).mul(1e12).div(rootedTokenPoolsLiquidity);
        uint256 eliteLiquidityShareInElitePair = eliteToken.balanceOf(rootedElitePair).mul(1e12).div(baseTokenPoolsLiquidity);
        uint256 avgLiquidityShareInElitePair = (rootedLiquidityShareInElitePair.add(eliteLiquidityShareInElitePair)).div(2);
        uint256 one = 1e12;

        uint256 excessInElitePool = calculateExcessInPool(eliteToken, rootedElitePair, avgLiquidityShareInElitePair, rootedTokenTotalSupply, rootedTokenPoolsLiquidity);
        uint256 excessInBasePool = calculateExcessInPool(baseToken, rootedBasePair, (one).sub(avgLiquidityShareInElitePair), rootedTokenTotalSupply, rootedTokenPoolsLiquidity);
        return excessInElitePool.add(excessInBasePool);
    }

    function calculateSubFloor(IERC20 baseToken, IERC20 eliteToken) public override view returns (uint256)
    {        
        uint256 excessInPools = calculateExcessInPools(baseToken, eliteToken);

        uint256 requiredBacking = eliteToken.totalSupply().sub(excessInPools);
        uint256 currentBacking = baseToken.balanceOf(address(eliteToken));
        if (requiredBacking >= currentBacking) { return 0; }
        return currentBacking - requiredBacking;
    }
}

// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

import "./IERC20.sol";
import "./IGatedERC20.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./TokensRecoverable.sol";
import './IPancakeRouter02.sol';

contract FeeSplitter is TokensRecoverable
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
    
    address public devAddress;  
    mapping (address => bool) public royaltyCollector;
    
    address public immutable deployerAddress;
    IPancakeRouter02 public immutable router;
    IERC20 public immutable chainToken;
   
    mapping (IGatedERC20 => uint256) public burnRates;
    mapping (IGatedERC20 => uint256) public sellRates;
    mapping (IGatedERC20 => uint256) public keepRates;

    mapping (IGatedERC20 => address[]) public chainTokenFeeCollectors;
    mapping (IGatedERC20 => uint256[]) public chainTokenFeeRates;

    mapping (IGatedERC20 => address[]) public rootedTokenFeeCollectors;
    mapping (IGatedERC20 => uint256[]) public rootedTokenFeeRates;
    mapping (address => uint256) public totalRoyaltiesCollected; //map royalties by token address

    constructor(address _devAddress, IPancakeRouter02 _router)
    {
        deployerAddress = msg.sender;
        devAddress = _devAddress;
        royaltyCollector[msg.sender] = true;
        router = _router;
        chainToken = IERC20(_router.WETH());   
    }
    modifier onlyRoyaltyCollector()
    {
        require(royaltyCollector[msg.sender] || msg.sender == devAddress);
        _;
    }
    function setDevAddress(address _devAddress) public
    {
        require (msg.sender == deployerAddress || msg.sender == devAddress, "Not a deployer or dev address");
        devAddress = _devAddress;
    }
    function setRoyaltyCollector(address _royaltyCollector) public
    {
        require (msg.sender == deployerAddress || msg.sender == devAddress, "Not a deployer or dev address");
        royaltyCollector[_royaltyCollector] = true;
    }

    function setFees(IGatedERC20 token, uint256 burnRate, uint256 sellRate, uint256 keepRate) public ownerOnly() // 100% = 10000
    {
        require (burnRate + sellRate + keepRate == 10000, "Total fee rate must be 100%");
        
        burnRates[token] = burnRate;
        sellRates[token] = sellRate;
        keepRates[token] = keepRate;
        
        token.approve(address(router), uint256(-1));
    }
    //todo update below
    function setChainTokenFeeCollectors(IGatedERC20 token, address[5] memory collectors, uint16[5] memory rates) public ownerOnly() // 100% = 10000
    {
        require (collectors.length == rates.length, "Fee Collectors and Rates must be the same size");
        require (collectors[0] == devAddress, "First address must be dev address");
        
        uint256 totalRate = 0;
        for (uint256 i = 0; i < rates.length; i++)
        {
            totalRate = totalRate + rates[i];
        }
        
        require (totalRate == 10000, "Total fee rate must be 100%");

        chainTokenFeeCollectors[token] = collectors;
        chainTokenFeeRates[token] = rates;
    }

    function setRootedTokenFeeCollectors(IGatedERC20 token, address[5] memory collectors, uint16[5] memory rates) public ownerOnly() // 100% = 10000
    {
        require (collectors.length == rates.length, "Fee Collectors and Rates must be the same size");
        
        uint256 totalRate = 0;
        for (uint256 i = 0; i < rates.length; i++)
        {
            totalRate = totalRate + rates[i];
        }

        require (totalRate == 10000, "Total fee rate must be 100%");

        rootedTokenFeeCollectors[token] = collectors;
        rootedTokenFeeRates[token] = rates;
    }

    function payFees(IGatedERC20 token) public
    {
        uint256 balance = token.balanceOf(address(this));
        require (balance > 0, "Nothing to pay");

        if (burnRates[token] > 0)
        {
            uint256 burnAmount = burnRates[token] * balance / 10000;
            token.burn(burnAmount);
        }

        if (sellRates[token] > 0)
        {
            uint256 sellAmount = sellRates[token] * balance / 10000;
            
            address[] memory path = new address[](2);
            path[0] = address(token);
            path[1] = address(chainToken);
            uint256[] memory amounts = router.swapExactTokensForTokens(sellAmount, 0, path, address(this), block.timestamp);

            address[] memory collectors = chainTokenFeeCollectors[token];
            uint256[] memory rates = chainTokenFeeRates[token];
            distribute(chainToken, amounts[1], collectors, rates);
        }

        if (keepRates[token] > 0)
        {
            uint256 keepAmount = keepRates[token] * balance / 10000;
            address[] memory collectors = rootedTokenFeeCollectors[token];
            uint256[] memory rates = rootedTokenFeeRates[token];
            distribute(token, keepAmount, collectors, rates);
        }
    }
    
    function distribute(IERC20 token, uint256 amount, address[] memory collectors, uint256[] memory rates) private
    {
        for (uint256 i = 0; i < collectors.length; i++)
        {
            address collector = collectors[i];
            uint256 rate = rates[i];

            if (rate > 0)
            {
                uint256 feeAmount = rate * amount / 10000;
                token.transfer(collector, feeAmount);
            }
        }
    }
}

// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

import "./TokensRecoverable.sol";
import "./IERC31337.sol";
import "./IPancakeRouter02.sol";
import "./IERC20.sol";
import "./RootedTransferGate.sol";
import "./IPancakeFactory.sol";
import "./SafeMath.sol";
import "./ILiquidityController.sol";
import "./IFloorCalculator.sol";

contract LiquidityController is TokensRecoverable, ILiquidityController
{
    using SafeMath for uint256;

    IPancakeRouter02 immutable pancakeRouter;
    IPancakeFactory immutable pancakeFactory;
    IERC20 immutable rooted;
    IERC20 immutable base;
    IERC31337 immutable elite;
    IERC20 immutable rootedEliteLP;
    IERC20 immutable rootedBaseLP;
    IFloorCalculator public calculator;
    RootedTransferGate public gate;
    mapping(address => bool) public liquidityControllers;

    constructor(IPancakeRouter02 _pancakeRouter, IERC20 _base, IERC20 _rooted, IERC31337 _elite, IFloorCalculator _calculator, RootedTransferGate _gate) 
    {
        pancakeRouter = _pancakeRouter;
        base = _base;
        elite = _elite;
        rooted = _rooted;
        calculator = _calculator;
        gate = _gate;

        IPancakeFactory _pancakeFactory = IPancakeFactory(_pancakeRouter.factory());
        pancakeFactory = _pancakeFactory;        
        
        _base.approve(address(_elite), uint256(-1));
        _base.approve(address(_pancakeRouter), uint256(-1));
        _rooted.approve(address(_pancakeRouter), uint256(-1));
        IERC20 _rootedBaseLP = IERC20(_pancakeFactory.getPair(address(_base), address(_rooted)));
        _rootedBaseLP.approve(address(_pancakeRouter), uint256(-1));
        rootedBaseLP = _rootedBaseLP;
        _elite.approve(address(_pancakeRouter), uint256(-1));
        IERC20 _rootedEliteLP = IERC20(_pancakeFactory.getPair(address(_elite), address(_rooted)));
        _rootedEliteLP.approve(address(_pancakeRouter), uint256(-1));
        rootedEliteLP = _rootedEliteLP;
    }

    modifier liquidityControllerOnly()
    {
        require(liquidityControllers[msg.sender], "Not a Liquidity Controller");
        _;
    }

    // Owner function to enable other contracts or addresses to use the Liquidity Controller
    function setLiquidityController(address controlAddress, bool controller) public ownerOnly()
    {
        liquidityControllers[controlAddress] = controller;
    }

    function setCalculatorAndGate(IFloorCalculator _calculator, RootedTransferGate _gate) public ownerOnly()
    {
        calculator = _calculator;
        gate = _gate;
    }

    // Removes liquidity, buys from either pool, sets a temporary dump tax
    function removeBuyAndTax(uint256 amount, address token, uint16 tax, uint256 time) public override liquidityControllerOnly()
    {
        gate.setUnrestricted(true);
        amount = removeLiq(token, amount);
        buyRootedToken(token, amount);
        gate.setDumpTax(tax, time);
        gate.setUnrestricted(false);
    }

    // Use Base tokens held by this contract to buy from the Base Pool and sell in the Elite Pool
    function balancePriceBase(uint256 amount) public override liquidityControllerOnly()
    {
        amount = buyRootedToken(address(base), amount);
        amount = sellRootedToken(address(elite), amount);
        elite.withdrawTokens(amount);
    }

    // Use Base tokens held by this contract to buy from the Elite Pool and sell in the Base Pool
    function balancePriceElite(uint256 amount) public override liquidityControllerOnly()
    {        
        elite.depositTokens(amount);
        amount = buyRootedToken(address(elite), amount);
        amount = sellRootedToken(address(base), amount);
    }

    // Uses value in the controller to buy
    function buyAndTax(address token, uint256 amountToSpend, uint16 tax, uint256 time) public override liquidityControllerOnly()
    {
        buyRootedToken(token, amountToSpend);
        gate.setDumpTax(tax, time);
    }

    // Sweeps the Base token under the floor to this address
    function sweepFloor() public override liquidityControllerOnly()
    {
        elite.sweepFloor(address(this));
    }

    // Move liquidity from Elite pool --->> Base pool
    function zapEliteToBase(uint256 liquidity) public override liquidityControllerOnly() 
    {       
        gate.setUnrestricted(true);
        liquidity = removeLiq(address(elite), liquidity);
        elite.withdrawTokens(liquidity);
        addLiq(address(base), liquidity);
        gate.setUnrestricted(false);
    }

    // Move liquidity from Base pool --->> Elite pool
    function zapBaseToElite(uint256 liquidity) public override liquidityControllerOnly() 
    {
        gate.setUnrestricted(true);
        liquidity = removeLiq(address(base), liquidity);
        elite.depositTokens(liquidity);
        addLiq(address(elite), liquidity);
        gate.setUnrestricted(false);
    }

    function wrapToElite(uint256 baseAmount) public override liquidityControllerOnly() 
    {
        elite.depositTokens(baseAmount);
    }

    function unwrapElite(uint256 eliteAmount) public override liquidityControllerOnly() 
    {
        elite.withdrawTokens(eliteAmount);
    }

    function addLiquidity(address eliteOrBase, uint256 baseAmount) public override liquidityControllerOnly() 
    {
        gate.setUnrestricted(true);
        addLiq(eliteOrBase, baseAmount);
        gate.setUnrestricted(false);
    }

    function removeLiquidity(address eliteOrBase, uint256 tokens) public override liquidityControllerOnly()
    {
        gate.setUnrestricted(true);
        removeLiq(eliteOrBase, tokens);
        gate.setUnrestricted(false);
    }

    function buyRooted(address token, uint256 amountToSpend) public override liquidityControllerOnly()
    {
        buyRootedToken(token, amountToSpend);
    }

    function sellRooted(address token, uint256 amountToSpend) public override liquidityControllerOnly()
    {
        sellRootedToken(token, amountToSpend);
    }

    function addLiq(address eliteOrBase, uint256 baseAmount) internal 
    {
        pancakeRouter.addLiquidity(address(eliteOrBase), address(rooted), baseAmount, rooted.balanceOf(address(this)), 0, 0, address(this), block.timestamp);
    }

    function removeLiq(address eliteOrBase, uint256 tokens) internal returns (uint256)
    {
        (tokens, ) = pancakeRouter.removeLiquidity(address(eliteOrBase), address(rooted), tokens, 0, 0, address(this), block.timestamp);
        return tokens;
    }

    function buyRootedToken(address token, uint256 amountToSpend) internal returns (uint256)
    {
        uint256[] memory amounts = pancakeRouter.swapExactTokensForTokens(amountToSpend, 0, buyPath(token), address(this), block.timestamp);
        amountToSpend = amounts[1];
        return amountToSpend;
    }

    function sellRootedToken(address token, uint256 amountToSpend) internal returns (uint256)
    {
        uint256[] memory amounts = pancakeRouter.swapExactTokensForTokens(amountToSpend, 0, sellPath(token), address(this), block.timestamp);
        amountToSpend = amounts[1];
        return amountToSpend;
    }

    function buyPath(address token) internal view returns (address[] memory) 
    {
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(rooted);
        return path;
    }

    function sellPath(address token) internal view returns (address[] memory) 
    {
        address[] memory path = new address[](2);
        path[0] = address(rooted);
        path[1] = address(token);
        return path;
    }
}

// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./TokensRecoverable.sol";

contract StakingToken is ERC20, TokensRecoverable
{
    
    using SafeMath for uint256;
    IERC20 public immutable rooted;

    constructor(IERC20 _rooted, string memory _name, string memory _symbol)
    ERC20(_name, _symbol)
    {
        rooted = _rooted;
    }

    // Stake rooted, get staking shares
    function stake(uint256 amount) public 
    {
        uint256 totalRooted = rooted.balanceOf(address(this));
        uint256 totalShares = this.totalSupply();

        if (totalShares == 0 || totalRooted == 0) 
        {
            _mint(msg.sender, amount);
        } 
        else 
        {
            uint256 mintAmount = amount.mul(totalShares).div(totalRooted);
            _mint(msg.sender, mintAmount);
        }

        rooted.transferFrom(msg.sender, address(this), amount);
    }

    // Unstake shares, claim back rooted
    function unstake(uint256 share) public 
    {
        uint256 totalShares = this.totalSupply();
        uint256 unstakeAmount = share.mul(rooted.balanceOf(address(this))).div(totalShares);

        _burn(msg.sender, share);
        rooted.transfer(msg.sender, unstakeAmount);
    }

    function canRecoverTokens(IERC20 token) internal override view returns (bool) 
    { 
        return address(token) != address(this) && address(token) != address(rooted); 
    }
}

// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

import "./IERC20.sol";
import "./IWrappedERC20.sol";
import "./IGatedERC20.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./TokensRecoverable.sol";
import './IPancakeRouter02.sol';
import './IPancakeFactory.sol';
import "./IWBNB.sol";
import "./RootedTransferGate.sol";

contract RoyaltyPump is TokensRecoverable
{


    //money comes in as matic
    //49% of incoming matic goes to liquidity for musician token
    //1% goes to liquidity controller for signed token
    //50% goes to musician staking
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
    
    address public devAddress;  
    mapping (address => bool) public royaltyCollector;
    
    address public immutable deployerAddress;
    IPancakeRouter02 public immutable router;
    IPancakeFactory public immutable factory;
    IWrappedERC20 public immutable chainToken;
    address public signedLiquidityController;
    address public artistToken;
    address public stakingContract;
    IERC20 public artistLP;
    RootedTransferGate gate;

    mapping (IGatedERC20 => uint256) public burnRates;
    mapping (IGatedERC20 => uint256) public sellRates;
    mapping (IGatedERC20 => uint256) public keepRates;

    mapping (IGatedERC20 => address[]) public chainTokenFeeCollectors;
    mapping (IGatedERC20 => uint256[]) public chainTokenFeeRates;

    mapping (IGatedERC20 => address[]) public rootedTokenFeeCollectors;
    mapping (IGatedERC20 => uint256[]) public rootedTokenFeeRates;
    uint256 public totalRoyaltiesCollected;

    constructor(address _devAddress, IPancakeRouter02 _router, address _signedLiquidityController, address _stakingContract, address _artistToken, RootedTransferGate _gate)
    {
        deployerAddress = msg.sender;
        devAddress = _devAddress;
        royaltyCollector[msg.sender] = true;
        router = _router;
        chainToken = IWrappedERC20(_router.WETH());   
        signedLiquidityController = _signedLiquidityController;
        stakingContract = _stakingContract;
        artistToken = _artistToken;
        IPancakeFactory _factory = IPancakeFactory(_router.factory());
        factory = _factory;
        artistLP = IERC20(_factory.getPair(_router.WETH(), address(artistToken)));
        gate = _gate;
        

        artistLP.approve(address(_router), (uint256(-1)));
        IERC20(_artistToken).approve((address(_router)), uint256(-1));
        IWrappedERC20(_router.WETH()).approve((address(_router)), uint256(-1));

    }
    modifier onlyRoyaltyCollector()
    {
        require(royaltyCollector[msg.sender] || msg.sender == devAddress);
        _;
    }
    function setDevAddress(address _devAddress) public
    {
        require (msg.sender == deployerAddress || msg.sender == devAddress, "Not a deployer or dev address");
        devAddress = _devAddress;
    }
    function setRoyaltyCollector(address _royaltyCollector) public
    {
        require (msg.sender == deployerAddress || msg.sender == devAddress, "Not a deployer or dev address");
        royaltyCollector[_royaltyCollector] = true;
    }
   
    //rates out of 10,000
    function depositRoyalties() public payable onlyRoyaltyCollector() 
    {
        require (msg.value > 0, "Must deposit some amount");
        totalRoyaltiesCollected = totalRoyaltiesCollected + msg.value;
        uint256 stakingRate = 5000;
        uint256 signedRate = 100;
        uint256 liquidityRate = 4900;

        uint256 stakingAmount = msg.value * stakingRate / 10000;
        uint256 signedAmount = msg.value * signedRate / 10000;
        uint256 liquidityAmount = msg.value * liquidityRate / 10000;

        IWBNB(address(chainToken)).deposit{ value: address(this).balance}();

        chainToken.transfer(stakingContract, stakingAmount);
        chainToken.transfer(signedLiquidityController, signedAmount);

        uint256 amountToSpend = liquidityAmount.div(2);
        buyArtistToken(amountToSpend);
        gate.setUnrestricted(true);
        addLiq(chainToken.balanceOf(address(this)));
        gate.setUnrestricted(false);
    }
    //rates out of 10,000

//todo make below private
    function buyArtistToken(uint256 amountToSpend) private returns (uint256)
    {
        uint256[] memory amounts = router.swapExactTokensForTokens(amountToSpend, 0, buyPath(), address(this), block.timestamp);
        amountToSpend = amounts[1];
        return amountToSpend;
    }
    function addLiq(uint256 chainTokenAmount) private
    {
        router.addLiquidity(address(chainToken), address(artistToken), chainTokenAmount, IERC20(artistToken).balanceOf(address(this)), 0, 0, address(this), block.timestamp);
    }

    function buyPath() private view returns (address[] memory) 
    {
        address[] memory path = new address[](2);
        path[0] = address(chainToken);
        path[1] = address(artistToken);
        return path;
    }
}

// SPDX-License-Identifier: lol
pragma solidity ^0.7.4;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./TokensRecoverable.sol";
import "./Owned.sol";

contract TokenTimelock is Owned, TokensRecoverable {

    using SafeMath for uint256;

    struct Timelock {
        address tokenOwner;
        uint256 amount;
        uint256 lockedTimestamp;
        uint256 claims;
        uint256 timeLocked;
    }

    //uint256 sixMonthsInSeconds = 15552000;
    uint256 sixMonthsInSeconds = 15552000; //set to 10 minutes for testing
    
    
    mapping (address => Timelock) tokenTimelock;

    function claimAvailable(address _token) public view returns (uint256) {
        uint unlockTime = tokenTimelock[_token].lockedTimestamp + tokenTimelock[_token].timeLocked;
        //if the full timelocked amount is up, transfer full balance of tokens to artist
        if (unlockTime <= block.timestamp) {
            return tokenTimelock[_token].amount;
        }

        //if 3 months is up, transfer half the amount to artist only if they havent already claimed
        else if (tokenTimelock[_token].lockedTimestamp + (tokenTimelock[_token].timeLocked.div(2)) <= block.timestamp && block.timestamp < unlockTime) {
            if (tokenTimelock[_token].claims < 1) {
                uint256 halfAmount = tokenTimelock[_token].amount.div(2);
                return halfAmount;
            }
        }
        
    }

    function lockTokens(address _token, address _artist, uint256 _amount) public ownerOnly() {
        require(_amount > 0, 'Amount must be greater than 0');
        require(tokenTimelock[_token].amount == 0, 'Token is already locked');
        tokenTimelock[_token] = Timelock(_artist, _amount, block.timestamp, 0, sixMonthsInSeconds);
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
    }

    function claimTokens(address _token) public {
        require(msg.sender == tokenTimelock[_token].tokenOwner, 'Only token owner can claim tokens');
        require(tokenTimelock[_token].lockedTimestamp + (tokenTimelock[_token].timeLocked.div(2)) <= block.timestamp, 'Token is still locked');
        require(tokenTimelock[_token].amount > 0, 'Token is already claimed');
        
        uint unlockTime = tokenTimelock[_token].lockedTimestamp + tokenTimelock[_token].timeLocked;
        //if the full timelocked amount is up, transfer full balance of tokens to artist
        if (unlockTime <= block.timestamp) {
            
            IERC20(_token).transfer(msg.sender, tokenTimelock[_token].amount);
            //tokenTimelock[_token].amount = 0;
        }

        //if 3 months is up, transfer half the amount to artist only if they havent already claimed
        else if (tokenTimelock[_token].lockedTimestamp + (tokenTimelock[_token].timeLocked.div(2)) <= block.timestamp && block.timestamp < unlockTime) {
            if (tokenTimelock[_token].claims < 1) {
                uint256 halfAmount = tokenTimelock[_token].amount.div(2);
                tokenTimelock[_token] = Timelock(tokenTimelock[_token].tokenOwner, halfAmount, tokenTimelock[_token].lockedTimestamp, 1, tokenTimelock[_token].timeLocked);
                IERC20(_token).transfer(msg.sender, halfAmount);
            }
        }
    }
  
    //Emergency function to unlock tokens
    function canRecoverTokens(IERC20 token) internal override view returns (bool) 
    { 
        return msg.sender == owner; 
    }
}

// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

import "./ERC20.sol";
import "./Owned.sol";
import "./IPancakePair.sol";
import "./GatedERC20.sol";
import "./ILiquidityLockedERC20.sol";

abstract contract LiquidityLockedERC20 is GatedERC20, ILiquidityLockedERC20
{
    mapping (IPancakePair => bool) public liquidityPairLocked;
    mapping (address => bool) public liquidityController;

    struct CallRecord
    {
        address origin;
        uint32 blockNumber;
        bool transferFrom;
    }

    CallRecord balanceAllowed;

    constructor(string memory _name, string memory _symbol)
        GatedERC20(_name, _symbol)
    {
    }

    function setLiquidityLock(IPancakePair _liquidityPair, bool _locked) public override
    {
        require (liquidityController[msg.sender], "Liquidity controller only");
        require (_liquidityPair.token0() == address(this) || _liquidityPair.token1() == address(this), "Unrelated pair");
        liquidityPairLocked[_liquidityPair] = _locked;
    }

    function setLiquidityController(address _liquidityController, bool _canControl) public ownerOnly()
    {
        liquidityController[_liquidityController] = _canControl;
    }

    function balanceOf(address account) public override view returns (uint256) 
    {
        IPancakePair pair = IPancakePair(address(msg.sender));
        if (liquidityPairLocked[pair]) {
            CallRecord memory last = balanceAllowed;
            require (last.origin == tx.origin && last.blockNumber == block.number, "Liquidity is locked");
            if (last.transferFrom) {
                (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
                IERC20 token0 = IERC20(pair.token0());
                if (address(token0) == address(this)) {
                    require (IERC20(pair.token1()).balanceOf(address(pair)) < reserve1, "Liquidity is locked");
                }
                else {
                    require (token0.balanceOf(address(pair)) < reserve0, "Liquidity is locked");
                }
            }
        }
        return super.balanceOf(account);
    }

    function allowBalance(bool _transferFrom) private
    {
        CallRecord memory last = balanceAllowed;
        CallRecord memory allow = CallRecord({ 
            origin: tx.origin,
            blockNumber: uint32(block.number),
            transferFrom: _transferFrom
        });
        require (last.origin != allow.origin || last.blockNumber != allow.blockNumber || last.transferFrom != allow.transferFrom, "Liquidity is locked (Please try again next block)");
        balanceAllowed = allow;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) 
    {        
        if (liquidityPairLocked[IPancakePair(address(msg.sender))]) {
            allowBalance(false);
        }
        else {
            balanceAllowed = CallRecord({ origin: address(0), blockNumber: 0, transferFrom: false });
        }
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) 
    {
        if (liquidityPairLocked[IPancakePair(recipient)]) {
            allowBalance(true);
        }
        else {
            balanceAllowed = CallRecord({ origin: address(0), blockNumber: 0, transferFrom: false });
        }
        return super.transferFrom(sender, recipient, amount);
    }
}

// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

/* ROOTKIT:
Simplified thanks to higher solidity version
But same functionality
*/

import "./IERC20.sol";
import "./SafeMath.sol";


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
abstract contract ERC20 is IERC20 
{
    using SafeMath for uint256;

    mapping (address => uint256) internal _balanceOf;
    mapping (address => mapping (address => uint256)) public override allowance;

    uint256 public override totalSupply;

    string public override name;
    string public override symbol;
    uint8 public override decimals = 18;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory _name, string memory _symbol) 
    {
        name = _name;
        symbol = _symbol;
    }

    function balanceOf(address a) public virtual override view returns (uint256) { return _balanceOf[a]; }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 oldAllowance = allowance[sender][msg.sender];
        if (oldAllowance != uint256(-1)) {
            _approve(sender, msg.sender, oldAllowance.sub(amount, "ERC20: transfer amount exceeds allowance"));
        }
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowance[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowance[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balanceOf[sender] = _balanceOf[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balanceOf[recipient] = _balanceOf[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        totalSupply = totalSupply.add(amount);
        _balanceOf[account] = _balanceOf[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balanceOf[account] = _balanceOf[account].sub(amount, "ERC20: burn amount exceeds balance");
        totalSupply = totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 _decimals) internal {
        decimals = _decimals;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

/* ROOTKIT:
A standard ERC20 with an extra hook: An installable transfer
gate allowing for token tax and burn on transfer
*/

import "./ERC20.sol";
import "./ITransferGate.sol";
import "./SafeMath.sol";
import "./TokensRecoverable.sol";
import "./IGatedERC20.sol";

abstract contract GatedERC20 is ERC20, TokensRecoverable, IGatedERC20
{
    using SafeMath for uint256;

    ITransferGate public override transferGate;
    address [] public tokenHolder;
    uint256 public numberOfTokenHolders = 0;
    mapping(address => bool) public exist;

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol)
    {
    }

    function setTransferGate(ITransferGate _transferGate) public override ownerOnly()
    {
        transferGate = _transferGate;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override 
    {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);
        if(!exist[recipient]){
            tokenHolder.push(recipient);
            numberOfTokenHolders++;
            exist[recipient] = true;
        }
        ITransferGate _transferGate = transferGate;
        uint256 remaining = amount;
        if (address(_transferGate) != address(0)) 
        {
            address splitter = _transferGate.feeSplitter();
            uint256 fees = _transferGate.handleTransfer(msg.sender, sender, recipient, amount);
            if (fees > 0)
            {
               _balanceOf[splitter] = _balanceOf[splitter].add(fees);
                emit Transfer(sender, splitter, fees);
                remaining = remaining.sub(fees);
            }           
        }
        _balanceOf[sender] = _balanceOf[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balanceOf[recipient] = _balanceOf[recipient].add(remaining);
        emit Transfer(sender, recipient, remaining);
    }

    function burn(uint256 amount) public override
    {
        _burn(msg.sender, amount);
    }
}

// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

import "./IPancakePair.sol";

interface ILiquidityLockedERC20
{
    function setLiquidityLock(IPancakePair _liquidityPair, bool _locked) external;
}

// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

library SafeMath 
{
    function add(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) 
        {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

interface IOwned
{
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;
    function claimOwnership() external;
}

// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

interface ITransferGate
{
    function feeSplitter() external view returns (address);
    function handleTransfer(address msgSender, address from, address to, uint256 amount) external returns (uint256);
}

// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

/* ROOTKIT:
Allows recovery of unexpected tokens (airdrops, etc)
Inheriters can customize logic by overriding canRecoverTokens
*/

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Owned.sol";
import "./ITokensRecoverable.sol";

abstract contract TokensRecoverable is Owned, ITokensRecoverable
{
    using SafeERC20 for IERC20;

    function recoverTokens(IERC20 token) public override ownerOnly() 
    {
        require (canRecoverTokens(token));
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }

    function canRecoverTokens(IERC20 token) internal virtual view returns (bool) 
    { 
        return address(token) != address(this); 
    }
}

// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

import "./IERC20.sol";
import "./ITransferGate.sol";

interface IGatedERC20 is IERC20
{
    function transferGate() external view returns (ITransferGate);

    function setTransferGate(ITransferGate _transferGate) external;
    function burn( uint256 amount) external;
}

// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

/* ROOTKIT:
Modified to remove some junk
Also modified to remove silly restrictions (traps!) within safeApprove
*/

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {        
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

import "./IERC20.sol";

interface ITokensRecoverable
{
    function recoverTokens(IERC20 token) external;
}

// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

/* ROOTKIT:
A wrapped token, where the underlying token can be swept
and used for other purposes
Governed by an installable floor calculator contract
Sweepable by designated sweeper addresses
*/

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IFloorCalculator.sol";
import "./WrappedERC20.sol";
import "./IERC31337.sol";

contract ERC31337 is WrappedERC20, IERC31337
{
    using SafeERC20 for IERC20;

    IFloorCalculator public override floorCalculator;
    
    mapping (address => bool) public override sweepers;

    constructor(IERC20 _wrappedToken, string memory _name, string memory _symbol)
        WrappedERC20(_wrappedToken, _name, _symbol)
    {
    }

    function setFloorCalculator(IFloorCalculator _floorCalculator) public override ownerOnly()
    {
        floorCalculator = _floorCalculator;
    }

    function setSweeper(address sweeper, bool allow) public override ownerOnly()
    {
        sweepers[sweeper] = allow;
    }

    function sweepFloor(address to) public override returns (uint256 amountSwept)
    {
        require (to != address(0),  " transfer to the zero address");
        require (sweepers[msg.sender], "Sweepers only");
        amountSwept = floorCalculator.calculateSubFloor(wrappedToken, this);
        if (amountSwept > 0) {
            wrappedToken.safeTransfer(to, amountSwept);
        }
    }
}

// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

import "./IERC20.sol";

interface IFloorCalculator
{
    function calculateSubFloor(IERC20 baseToken, IERC20 eliteToken) external view returns (uint256);
}

// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

/* ROOTKIT:
Wraps any ERC20
Similar to WETH except for ERC20 tokens instead of ETH
depositTokens/withdrawTokens are like deposit/withdraw in WETH
Inheriters can hook into depositTokens and withdrawTokens
by overriding _beforeDepositTokens and _beforeWithdrawTokens
*/

import "./IERC20.sol";
import "./ERC20.sol";
import "./IWrappedERC20.sol";
import "./TokensRecoverable.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

contract WrappedERC20 is ERC20, IWrappedERC20, TokensRecoverable
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 public immutable override wrappedToken;

    constructor (IERC20 _wrappedToken, string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {        
        if (_wrappedToken.decimals() != 18) {
            _setupDecimals(_wrappedToken.decimals());
        }
        wrappedToken = _wrappedToken;
    }

    function depositTokens(uint256 _amount) public override
    {
        _beforeDepositTokens(_amount);
        uint256 myBalance = wrappedToken.balanceOf(address(this));
        wrappedToken.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 received = wrappedToken.balanceOf(address(this)).sub(myBalance);
        _mint(msg.sender, received);
        emit Deposit(msg.sender, _amount);
    }

    function withdrawTokens(uint256 _amount) public override
    {
        _beforeWithdrawTokens(_amount);
        _burn(msg.sender, _amount);
        uint256 myBalance = wrappedToken.balanceOf(address(this));
        wrappedToken.safeTransfer(msg.sender, _amount);
        require (wrappedToken.balanceOf(address(this)) == myBalance.sub(_amount), "Transfer not exact");
        emit Withdrawal(msg.sender, _amount);
    }

    function canRecoverTokens(IERC20 token) internal virtual override view returns (bool) 
    {
        return token != this && token != wrappedToken;
    }

    function _beforeDepositTokens(uint256 _amount) internal virtual view { }
    function _beforeWithdrawTokens(uint256 _amount) internal virtual view { }
}

// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

import "./IWrappedERC20.sol";
import "./IFloorCalculator.sol";

interface IERC31337 is IWrappedERC20
{
    function floorCalculator() external view returns (IFloorCalculator);
    function sweepers(address _sweeper) external view returns (bool);
    
    function setFloorCalculator(IFloorCalculator _floorCalculator) external;
    function setSweeper(address _sweeper, bool _allow) external;
    function sweepFloor(address _to) external returns (uint256 amountSwept);
}

// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

import "./IERC20.sol";
import "./IWrappedERC20Events.sol";

interface IWrappedERC20 is IERC20, IWrappedERC20Events
{
    function wrappedToken() external view returns (IERC20);
    function depositTokens(uint256 _amount) external;
    function withdrawTokens(uint256 _amount) external;
}

// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

interface IWrappedERC20Events
{
    event Deposit(address indexed from, uint256 amount);
    event Withdrawal(address indexed to, uint256 amount);
}

// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

interface IMarketDistribution
{
    function distributionComplete() external view returns (bool);
    function vestingPeriodStartTime() external view returns (uint256); 
    function vestingPeriodEndTime() external view returns (uint256);
    
    function distribute(uint16 _preBuyForReferralsPercent, 
        uint16 _preBuyForContributorsPercent, 
        uint16 _preBuyForMarketStabilizationPercent) external;        
    function claim(address account) external;
    function claimReferralRewards(address account, uint256 referralShare) external;
}

// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

interface IMarketGeneration
{
    function contribution(address) external view returns (uint256);
    function referralPoints(address) external view returns (uint256);    
    function totalContribution() external view returns (uint256);
    function totalReferralPoints() external view returns (uint256);
}

// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;

interface IWBNB
{    
    function deposit() external payable;
}

// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

import './IPancakeRouter01.sol';

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity ^0.7.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.7.4;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
 import "./Context.sol";
 
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

     /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

pragma solidity >=0.5.0;

import './IPancakePair.sol';

import "./SafeMath.sol";

library PancakeLibrary {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'PancakeLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'PancakeLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        pairFor(factory, tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IPancakePair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'PancakeLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'PancakeLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(998);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'PancakeLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(998);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PancakeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PancakeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

interface ILiquidityController
{
    function balancePriceBase(uint256 amount) external;
    function balancePriceElite(uint256 amount) external;
    function removeBuyAndTax(uint256 amount, address token, uint16 tax, uint256 time) external;
    function buyAndTax(address token, uint256 amountToSpend, uint16 tax, uint256 time) external;
    function sweepFloor() external;
    function zapEliteToBase(uint256 liquidity) external;
    function zapBaseToElite(uint256 liquidity) external;
    function wrapToElite(uint256 baseAmount) external;
    function unwrapElite(uint256 eliteAmount) external;
    function addLiquidity(address eliteOrBase, uint256 baseAmount) external;
    function removeLiquidity(address eliteOrBase, uint256 tokens) external;    
    function buyRooted(address token, uint256 amountToSpend) external;
    function sellRooted(address token, uint256 amountToSpend) external;   
}