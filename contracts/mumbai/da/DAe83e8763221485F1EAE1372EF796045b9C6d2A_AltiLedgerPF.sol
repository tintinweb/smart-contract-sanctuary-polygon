// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

// Main contract for AltiLedger Private Fund (PF) Distribution
contract AltiLedgerPF {
    // Struct for Fund Details
    struct FundDetails {
        string title;
        string description;
        string fundStructureType;
        string fundAssetType;
        string investmentStrategy;
        string regulatoryStatus;
        string investorEligibility;
        string riskFactors;
        uint256 feesAndExpensesManFee;
        uint256 feesAndExpensesSubFee;
        uint256 feesAndExpensesOtherFee;
        uint256 subscriptionStart;
        uint256 subscriptionEnd;
        uint256 targetSize;
        string image;
        string logo;
    }

    // Struct for each PF Distribution
    struct PFDistribution {
        address payable fundManager;
        FundDetails fundDetails;
        uint256 amountSubscribed;
        address[] subscribers;
        uint256[] subscriptions;
    }

    // Mapping to store all PF Distributions
    mapping (uint256 => PFDistribution ) public pfdistributions;

    // Counter for the number of PF Distributions
    uint256 public numberOfPFDistributions = 0;

    // Function to create a new PF Distribution
    function createPFDistribution (
        address payable _fundManager,
        FundDetails memory _fundDetails
    ) public returns (uint256) {
        PFDistribution storage pfdistribution = pfdistributions[numberOfPFDistributions];

        require(pfdistribution.fundDetails.subscriptionEnd < block.timestamp,"Error: The Subscription End Date should be a date in the future.");

        // Set the properties of the PF Distribution
        pfdistribution.fundManager = _fundManager;
        pfdistribution.fundDetails = _fundDetails;
        pfdistribution.amountSubscribed = 0;

        // Increment the counter for the number of PF Distributions
        numberOfPFDistributions++;

        // Return the ID of the new PF Distribution
        return numberOfPFDistributions - 1;
    }

    // Function to invest in a PF Distribution
    function investInPFDistribution (uint256 _id) public payable {
        // Get the amount of the investment
        uint256 amount = msg.value;

        // Get the PF Distribution
        PFDistribution storage pfdistribution = pfdistributions[_id];

        // Add the investor to the subscribers list and the amount to the subscriptions list
        pfdistribution.subscribers.push(msg.sender);
        pfdistribution.subscriptions.push(amount);

        // Transfer the investment to the Fund Manager
        (bool sent,) = payable(pfdistribution.fundManager).call{value: amount}("");

        // If the transfer was successful, update the amount subscribed
        if(sent) {
            pfdistribution.amountSubscribed += amount;
        }
    }

    // Function to get the subscribers of a PF Distribution
    function getSubscribers (uint256 _id) view public returns (address[] memory, uint256[] memory) {
        return (pfdistributions[_id].subscribers, pfdistributions[_id].subscriptions);
    }

    // Function to get all PF Distributions
    function getPFDistribution () public view returns (PFDistribution[] memory) {
        PFDistribution[] memory allPFDistributions = new PFDistribution[](numberOfPFDistributions);

        for(uint i = 0; i < numberOfPFDistributions; i++) {
            PFDistribution storage item = pfdistributions[i];
            allPFDistributions[i] = item;
        }

        return allPFDistributions;
    }
}