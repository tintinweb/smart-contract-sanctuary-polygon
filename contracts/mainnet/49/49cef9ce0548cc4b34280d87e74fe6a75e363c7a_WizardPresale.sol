// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";

contract WizardPresale is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // The number of unclaimed WIZARD tokens the user has
    mapping(address => uint256) public wizardUnclaimed;
    // Last time user claimed WIZARD
    mapping(address => uint256) public lastWizardclaimed;

    // WIZARD token
    IBEP20 public WIZARD;
    // Buy token
    IBEP20 public BuyToken;
    // Sale active
    bool public isPresaleActive;
    // Claim active
    bool public isClaimActive;
    // Starting timestamp
    uint256 public startingPresaleTimestamp;
    
    // Max Min timestamp 10 days
    uint256 public constant MaxMinstartingPresaleTimestamp = 864000;
    
    // Total WIZARD sold
    uint256 public totalWizardSold = 0;

    // Price of presale WIZARD: 0.10 USD
    uint256 public constant USDPerWIZARDPresale = 10;

    // Time per percent
    uint256 public timePerPercent = 600; // 10 minutes

    // Max Buy Per User
    uint256 public maxBuyPerUser = 500000*(1e6); // decimal 6

    uint256 public firstHarvestTimestamp;

    address payable owner;

    uint256 public constant WIZARD_HARDCAP = 2000000*(1e6);

    modifier onlyOwner() {
        require(msg.sender == owner, "You're not the owner");
        _;
    }

    event TokenBuy(address user, uint256 tokens);
    event TokenClaim(address user, uint256 tokens);
    event MaxBuyPerUserUpdated(address user, uint256 previousRate, uint256 newRate);

    constructor(
        address _WIZARD,
        uint256 _startingTimestamp,
        address _BuyTokenAddress
    ) public {
        WIZARD = IBEP20(_WIZARD);
        BuyToken = IBEP20(_BuyTokenAddress);
        isPresaleActive = true;
        isClaimActive = false;
        owner = msg.sender;
        startingPresaleTimestamp = _startingTimestamp;
    }

    function setSaleActive(bool _isPresaleActive) external onlyOwner {
        isPresaleActive = _isPresaleActive;
    }

    function setClaimActive(bool _isClaimActive) external onlyOwner {
        isClaimActive = _isClaimActive;
        if (firstHarvestTimestamp == 0 && _isClaimActive) {
            firstHarvestTimestamp = block.timestamp;
        }
    }

    function buy(uint256 _amount, address _buyer) public nonReentrant {
        require(isPresaleActive, "Presale has not started");
        require(
            block.timestamp >= startingPresaleTimestamp,
            "Presale has not started"
        );

        address buyer = _buyer;
        uint256 tokens = _amount.div(USDPerWIZARDPresale).mul(100);

        require(
            totalWizardSold + tokens <= WIZARD_HARDCAP,
            "Wizard presale hardcap reached"
        );

        require(
            wizardUnclaimed[buyer] + tokens <= maxBuyPerUser,
            "Your amount exceeds the max buy number"
        );

        BuyToken.safeTransferFrom(buyer, address(this), _amount);

        wizardUnclaimed[buyer] = wizardUnclaimed[buyer].add(tokens);
        totalWizardSold = totalWizardSold.add(tokens);
        emit TokenBuy(buyer, tokens);
    }

    function claim() external {
        require(isClaimActive, "Claim is not allowed yet");
        require(
            wizardUnclaimed[msg.sender] > 0,
            "User should have unclaimed WIZARD tokens"
        );
        require(
            WIZARD.balanceOf(address(this)) >= wizardUnclaimed[msg.sender],
            "There are not enough WIZARD tokens to transfer."
        );

        if (lastWizardclaimed[msg.sender] == 0) {
            lastWizardclaimed[msg.sender] = firstHarvestTimestamp;
        }

        uint256 allowedPercentToClaim = block
        .timestamp
        .sub(lastWizardclaimed[msg.sender])
        .div(timePerPercent);

        require(
            allowedPercentToClaim > 0,
            "User cannot claim WIZARD tokens when Percent is 0%"
        );

        if (allowedPercentToClaim > 100) {
            allowedPercentToClaim = 100;
            // ensure they cannot claim more than they have.
        }

        lastWizardclaimed[msg.sender] = block.timestamp;

        uint256 wizardToClaim = wizardUnclaimed[msg.sender]
        .mul(allowedPercentToClaim)
        .div(100);
        wizardUnclaimed[msg.sender] = wizardUnclaimed[msg.sender].sub(wizardToClaim);

        wizardToClaim = wizardToClaim.mul(1e12);
        WIZARD.safeTransfer(msg.sender, wizardToClaim);
        emit TokenClaim(msg.sender, wizardToClaim);
    }


    function withdrawFunds() external onlyOwner {
        BuyToken.safeTransfer(msg.sender, BuyToken.balanceOf(address(this)));
    }

    function withdrawUnsoldWIZARD() external onlyOwner {
        uint256 amount = WIZARD.balanceOf(address(this)) - totalWizardSold.mul(1e12);
        WIZARD.safeTransfer(msg.sender, amount);
    }

    function emergencyWithdraw() external onlyOwner {
        WIZARD.safeTransfer(msg.sender, WIZARD.balanceOf(address(this)));
    }

    function updateMaxBuyPerUser(uint256 _maxBuyPerUser) external onlyOwner {
        require(_maxBuyPerUser <= WIZARD_HARDCAP, "WIZARD::updateMaxBuyPerUser: maxBuyPerUser must not exceed the hardcap.");
        emit MaxBuyPerUserUpdated(msg.sender, maxBuyPerUser, _maxBuyPerUser);
        maxBuyPerUser = _maxBuyPerUser;
    }

    function updaartingTimeStamp(uint256 _startingPresaleTimestamp) external onlyOwner {
        require(_startingPresaleTimestamp <= (startingPresaleTimestamp+MaxMinstartingPresaleTimestamp), "WIZARD::updaartingTimeStamp: updaartingTimeStamp must not exceed the MaxstartingPresaleTimestamp.");
        require(_startingPresaleTimestamp >= (startingPresaleTimestamp-MaxMinstartingPresaleTimestamp), "WIZARD::updaartingTimeStamp: updaartingTimeStamp must not exceed the MinstartingPresaleTimestamp.");
        startingPresaleTimestamp = _startingPresaleTimestamp;
    }

}