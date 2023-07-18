// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract ALPrivateFunds {
    struct FundPlacement {
        address fundManager;
        string fundName;
        string fundType;
        string investmentStrategy;
        uint256 irr;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] subscribers;
        uint256[] subscriptions;
    }

    mapping(uint256 => FundPlacement) public fundplacements;

    uint256 public numberOfFundPlacements = 0;

    function createCampaign(address _fundmanager, string memory _fundname, string memory _fundtype, string memory _investmentstrategy, uint256 _irr, uint256 _target, uint256 _deadline, string memory _image) public returns (uint256) {
        FundPlacement storage fundplacement = fundplacements[numberOfFundPlacements];

        require(fundplacement.deadline < block.timestamp, "The deadline should be a date in the future.");

        fundplacement.fundManager = _fundmanager;
        fundplacement.fundName = _fundname;
        fundplacement.fundType = _fundtype;
        fundplacement.investmentStrategy = _investmentstrategy;
        fundplacement.irr = _irr;
        fundplacement.target = _target;
        fundplacement.deadline = _deadline;
        fundplacement.amountCollected = 0;
        fundplacement.image = _image;

        numberOfFundPlacements++;

        return numberOfFundPlacements - 1;
    }

    function donateToCampaign(uint256 _id) public payable {
        uint256 amount = msg.value;

        FundPlacement storage fundplacement = fundplacements[_id];

        fundplacement.subscribers.push(msg.sender);
        fundplacement.subscriptions.push(amount);

        (bool sent,) = payable(fundplacement.fundManager).call{value: amount}("");

        if(sent) {
            fundplacement.amountCollected = fundplacement.amountCollected + amount;
        }
    }

    function getDonators(uint256 _id) view public returns (address[] memory, uint256[] memory) {
        return (fundplacements[_id].subscribers, fundplacements[_id].subscriptions);
    }

    function getFundPlacements() public view returns (FundPlacement[] memory) {
        FundPlacement[] memory allFundPlacements = new FundPlacement[](numberOfFundPlacements);

        for(uint i = 0; i < numberOfFundPlacements; i++) {
            FundPlacement storage item = fundplacements[i];

            allFundPlacements[i] = item;
        }

        return allFundPlacements;
    }
}