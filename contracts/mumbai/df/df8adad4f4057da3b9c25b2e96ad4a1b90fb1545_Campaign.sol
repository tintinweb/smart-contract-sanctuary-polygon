/**
 *Submitted for verification at polygonscan.com on 2023-05-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


/**
 * @title Campaign
 * @author levertz <[email protected]>
 * @notice This is a contract for funding different kinds of initiatives
 * @notice This contract was built by project <Turtleneck> at ethDublin 2023.
 */
contract Campaign {
    struct Funder {
        uint256 donatedAmount;
        uint256 percentage;
    }

    struct CampaignInfo {
        uint256 fundingGoal;
        uint256 sharedReturnPercentage;
        string campaignName;
        uint256 startTime;
        uint256 fundingPeriodEndTime;
        uint256 campaignEndTime;
        string nftMetadataIPFSHash;
        bool distributionLocked;
        bool nftMinted;
    }

    address public admin;
    CampaignInfo public campaign;
    mapping(address => Funder) public funders;
    address[] public fundersIndex;
    uint256 public fundersCount;
    uint256 public totalFundedAmount;

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only the admin can perform this action.");
        _;
    }

    /**
     * @notice Set up the campaign with specified parameters
     * @param _fundingGoal The funding goal for the campaign
     * @param _sharedReturnPercentage The percentage of the shared return for the campaign
     * @param _campaignName The name of the campaign
     * @param _fundingPeriodInDays The duration of the funding period in days
     * @param _campaignDurationInDays The total duration of the campaign in days
     */
    function setupCampaign(
        uint256 _fundingGoal,
        uint256 _sharedReturnPercentage,
        string memory _campaignName,
        uint256 _fundingPeriodInDays,
        uint256 _campaignDurationInDays,
        string memory _nftMetadataIPFSHash
    ) public onlyAdmin {
        require(_fundingGoal > 0, "Funding goal must be greater than zero.");
        require(
            _sharedReturnPercentage > 0 && _sharedReturnPercentage <= 100,
            "Shared return percentage must be between 1 and 100."
        );
        require(_fundingPeriodInDays > 0, "Funding period must be greater than zero.");
        require(_campaignDurationInDays > _fundingPeriodInDays, "Campaign duration must be greater than the funding period.");

        campaign = CampaignInfo({
            fundingGoal: _fundingGoal,
            sharedReturnPercentage: _sharedReturnPercentage,
            campaignName: _campaignName,
            startTime: block.timestamp,
            fundingPeriodEndTime: block.timestamp + (_fundingPeriodInDays * 86400),
            campaignEndTime: block.timestamp + (_campaignDurationInDays * 86400),
            nftMetadataIPFSHash: _nftMetadataIPFSHash,
            distributionLocked: false,
            nftMinted: false
        });
    }

    /**
     * @notice Fund the campaign by sending native currency
     * @notice fundingPercentage is set in units of %
     * @notice sharedReturn is set in units of %
     */
    function fund() public payable {
        require(msg.value > 0, "Funding amount must be greater than zero.");
        require(block.timestamp >= campaign.startTime && block.timestamp <= campaign.fundingPeriodEndTime, "Funding period has ended.");
        require(!campaign.distributionLocked, "Campaign distribution is locked. Cannot accept new funds.");

        uint256 currentDonationAmount = funders[msg.sender].donatedAmount;
        uint256 newDonationAmount = currentDonationAmount + msg.value;
        totalFundedAmount += msg.value;

        if (newDonationAmount > campaign.fundingGoal) {
            uint256 exceedingAmount = campaign.fundingGoal + msg.value - totalFundedAmount;
            newDonationAmount = newDonationAmount - exceedingAmount;
            totalFundedAmount -= exceedingAmount;
            (bool sent, ) = payable(msg.sender).call{value: exceedingAmount}("");
            require(sent, "Failed to send exceeding amount.");
        }

        uint256 fundingPercentage = (newDonationAmount * 100) / campaign.fundingGoal;

        funders[msg.sender].donatedAmount = newDonationAmount;
        funders[msg.sender].percentage = fundingPercentage;

        if (totalFundedAmount >= campaign.fundingGoal) {
            campaign.distributionLocked = true;
        }

        addFunder(msg.sender);

    }


    /**
     * @notice Function to add a new funder address to fundersIndex
     */
    function addFunder(address funderAddress) internal {
        if (funders[funderAddress].donatedAmount == 0) {
            fundersIndex.push(funderAddress);
            fundersCount++;
        }
    }


    /**
     * @notice Distribute the funds to the funders based on their percentages
     */
    function distribute() public {
        require(
            (!campaign.distributionLocked && block.timestamp > campaign.fundingPeriodEndTime) || block.timestamp > campaign.campaignEndTime,
            "Distribution is not yet available."
        );

        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "Contract balance is zero.");

        if (!campaign.distributionLocked) {
            // Funding goal not reached, revert funded amounts
            for (uint256 i = 0; i < fundersCount; i++) {
                address funderAddress = fundersIndex[i];
                Funder storage funder = funders[funderAddress];
                (bool sent, ) = payable(funderAddress).call{value: funder.donatedAmount}("");
                require(sent, "Failed to send donated amount.");
                funder.donatedAmount = 0;
                funder.percentage = 0;
            }
        } else {
            if (campaign.sharedReturnPercentage != 0) {
                // Funding goal reached, distribute funds based on percentages
                for (uint256 i = 0; i < fundersCount; i++) {
                    address funderAddress = fundersIndex[i];
                    Funder storage funder = funders[funderAddress];
                    uint256 funderShare = (contractBalance * campaign.sharedReturnPercentage * funder.percentage) / 10000;
                    (bool sent, ) = payable(funderAddress).call{value: funderShare}("");
                    require(sent, "Failed to send funder share.");
                    funder.percentage = 0;
                    funder.donatedAmount = 0;
                }
            }
            (bool sentAdmin, ) = payable(admin).call{value: address(this).balance}("");
            require(sentAdmin, "Failed to send admin share.");
        }
    }

    /**
     * @notice Admin can claim the total funded amount
     */
    function claim() public onlyAdmin {
        require(campaign.distributionLocked && block.timestamp > campaign.fundingPeriodEndTime, "Funding goal has not been reached yet.");

        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "Contract balance is zero.");

        (bool sent, ) = payable(msg.sender).call{value: contractBalance}("");
        require(sent, "Failed to send total funded amount.");
    }
}