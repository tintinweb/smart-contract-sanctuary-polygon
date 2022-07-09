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
        require(mgeController[msg.sender] || msg.sender == owner || msg.sender == devAddress, "Only controller or owner can do this");
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
    function setMGEController(address _controller, bool allow) public  isController()
    {
        mgeController[_controller] = allow;
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