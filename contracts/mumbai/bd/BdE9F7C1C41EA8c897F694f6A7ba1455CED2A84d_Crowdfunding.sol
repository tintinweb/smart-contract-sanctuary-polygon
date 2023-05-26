// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

error IncorrectDeadlineError(uint256 deadline);
error FillAllFields();
error NoCampaignFound();
error CanNotDonateToOwnCampaign();
error DeadlineNotEnd();
error TransferError();
error AccessDenied();
error NotEnoughFunds();
error CampaignAlreadyClosed();

contract Crowdfunding {
    uint256 constant MIN_DONATE = 0.01 ether;
    address immutable public i_owner;
    uint256 private s_campaignCount = 0;

    struct Donation {
        address donator;
        uint256 donated;
    }

    struct Campaign {
        uint256 id;
        address owner;
        string title;
        string description;
        string image;
        uint256 deadline;
        uint256 amountCollected;
        bool closed;
        Donation[] donations;
    }

    mapping(uint256 => Campaign) campaigns;

    event CampaignGot(Campaign campaign);
    event ManyCampaignsGot(Campaign[] campaign);
    event CampaignCreated(Campaign campaign);
    event CampaignClosed(Campaign campaign);
    event CampaignDonated(uint256 donated);
    

    constructor() {
        i_owner = msg.sender;
    }

    function getNextCampaignId() public view returns (uint256) {
        return s_campaignCount;
    } 

    function createCampaign(string memory _title, string memory _description, string memory _image, uint256 _deadline) external returns (Campaign memory){
        if (_deadline < block.timestamp) {
            revert IncorrectDeadlineError(_deadline);
        }

        if (bytes(_title).length == 0 || bytes(_description).length == 0 || bytes(_image).length == 0) {
            revert FillAllFields();
        }

        Campaign storage campaign = campaigns[s_campaignCount];
        campaign.id = s_campaignCount;
        campaign.owner = msg.sender;
        campaign.title = _title;
        campaign.description = _description;
        campaign.image = _image;
        campaign.deadline = _deadline;
        campaign.closed = false;

        campaigns[s_campaignCount] = campaign;

        s_campaignCount++;

        emit CampaignCreated(campaign);

        return campaign;
    }

    function findDonationIndex(Donation[] memory donations, address donator) internal pure returns (int256) {
        for (uint256 i = 0; i < donations.length; i++) {
            if (donations[i].donator == donator) {
                return int256(i);
            }
        }

        return -1;
    }

    function donateCampaign(uint256 _campaignId) external payable {
        Campaign storage campaign = campaigns[_campaignId];

        if (campaign.closed) {
            revert CampaignAlreadyClosed();
        }

        if (campaign.owner == address(0)) {
            revert NoCampaignFound(); 
        }

        if (campaign.owner == msg.sender) {
            revert CanNotDonateToOwnCampaign();
        }

        if (msg.value < MIN_DONATE) {
            revert NotEnoughFunds(); 
        }

        campaign.amountCollected += msg.value;

        Donation[] storage donations = campaign.donations;

        int256 donationIndex = findDonationIndex(donations, msg.sender);

        if (donationIndex == -1) {
            Donation memory newDonation = Donation(msg.sender, msg.value);

            donations.push(newDonation);
        } else {
            donations[uint256(donationIndex)].donated += msg.value;
        }

        emit CampaignDonated(msg.value);
    }

    function closeCampaign(uint256 _campaignId) external payable returns (Campaign memory) {
        Campaign storage campaign = campaigns[_campaignId];

        if (campaign.closed) {
            revert CampaignAlreadyClosed();
        }

        if (msg.sender != i_owner) {
            if (campaign.owner == address(0)) {
                revert NoCampaignFound(); 
            }

            if (msg.sender != campaign.owner) {
                revert AccessDenied();
            }

            if (campaign.deadline > block.timestamp) {
                revert DeadlineNotEnd();
            }
        }        

        bool sent = payable(campaign.owner).send(campaign.amountCollected);

        if (!sent) {
            revert TransferError(); 
        }

        campaign.closed = true;

        emit CampaignClosed(campaign);

        return campaign;
    }

    function getMyCampaigns() external view returns (Campaign[] memory) {
        uint256 myCampaignsCount = 0;

        for (uint256 i = 0; i < s_campaignCount; i++) {
            Campaign memory campaign = campaigns[i];

            if (campaign.owner == msg.sender) {
                myCampaignsCount++;
            }
        }

        Campaign[] memory myCampaigns = new Campaign[](myCampaignsCount);

        uint256 campaignIndex = 0;

        for (uint256 i = 0; i < myCampaignsCount; i++) {
            Campaign memory campaign = campaigns[i];

            if (campaign.owner == msg.sender) {
                myCampaigns[campaignIndex] = campaign;
                campaignIndex++;
            }
        }

        return myCampaigns;
    }

    function getAllCampaigns() external view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](s_campaignCount);

        for (uint i = 0; i < s_campaignCount; i++) {
            Campaign memory campaign = campaigns[i];

            allCampaigns[i] = campaign; 
        }

        return allCampaigns;
    }

    struct PaginateCampaignsReturns {
        uint256 page;
        uint256 limit;
        uint256 total;
        Campaign[] campaigns;
    }

    function paginateCampaigns(uint256 _page, uint256 _limit) external view returns (PaginateCampaignsReturns memory) {
        uint256 start = (_page - 1) * _limit;
        uint256 end =  start +  _limit; 

        if (start >= s_campaignCount) {
        return PaginateCampaignsReturns(_page, _limit, s_campaignCount, new Campaign[](0));
        }

        if (end > s_campaignCount) {
            end = s_campaignCount;
        }

        Campaign[] memory selectedCampaigns = new Campaign[](end - start);

        for (uint256 i = start; i < end; i++) {
            selectedCampaigns[i - start] = campaigns[i];
        }

        return PaginateCampaignsReturns(_page, _limit, s_campaignCount, selectedCampaigns);
    }

    function getCampaign(uint256 campaignId) external view returns (Campaign memory) {
        return campaigns[campaignId];
    }

    // function getTopDonators() external view returns (Donation[] memory) {
    //     Donation[] memory allDonators;

    //     for (uint256 i = 0; i < s_campaignCount; i++) {
    //         Campaign storage campaign = campaigns[i];

    //         Donation[] memory campaignDonations = campaign.donations;

    //         for (uint256 j = 0; j < campaignDonations.length; j++) {
    //             Donation memory campaignDonator = campaignDonations[j];

    //             int256 donationIndex = findDonationIndex(allDonators, campaignDonator.donator);

    //             if (donationIndex == -1) {
    //                 allDonators[allDonators.length] = campaignDonator;
    //             } else {
    //                 allDonators[uint256(donationIndex)].donated = campaignDonator.donated;
    //             }
    //         }
    //     }

    //     for (uint256 i = 0; i < allDonators.length - 1; i++) {
    //         for (uint256 j = i + 1; j < allDonators.length; j++) {
    //             if (allDonators[j].donated > allDonators[i].donated) {

    //                 Donation memory tempDonator = allDonators[i];
    //                 allDonators[i] = allDonators[j];
    //                 allDonators[j] = tempDonator;
    //             }
    //         }
    //     }

    //     uint256 donatorsLength = allDonators.length < 10 ? allDonators.length : 10;

    //     Donation[] memory topDonators = new Donation[](donatorsLength); 

    //     for (uint256 i = 0; i < donatorsLength; i++) {
    //         topDonators[i] = allDonators[i];
    //     }

    //     return topDonators;
    // }

    function getTopDonators() external view returns (Donation[] memory) {
        Donation[] memory allDonators;

        for (uint256 i = 0; i < s_campaignCount; i++) {
            Donation[] memory campaignDonations = campaigns[i].donations;

            for (uint256 j = 0; j < campaignDonations.length; j++) {
                Donation memory campaignDonator = campaignDonations[j];

                int256 donationIndex = findDonationIndex(allDonators, campaignDonator.donator);

                if (donationIndex == -1) {
                    allDonators = expandDonatorsArray(allDonators);
                    donationIndex = int256(allDonators.length) - 1;
                    allDonators[uint256(donationIndex)] = campaignDonator;
                } else {
                    allDonators[uint256(donationIndex)].donated += campaignDonator.donated;
                }
            }
        }

        sortDonators(allDonators);

        uint256 donatorsLength = allDonators.length < 10 ? allDonators.length : 10;

        Donation[] memory topDonators = new Donation[](donatorsLength);

        for (uint256 i = 0; i < donatorsLength; i++) {
            topDonators[i] = allDonators[i];
        }

        return topDonators;
    }

    function expandDonatorsArray(Donation[] memory _donators) private pure returns (Donation[] memory) {
        Donation[] memory newDonators = new Donation[](_donators.length + 1);
        for (uint256 i = 0; i < _donators.length; i++) {
            newDonators[i] = _donators[i];
        }
        return newDonators;
    }

    function sortDonators(Donation[] memory _donators) private pure {
        for (uint256 i = 0; i < _donators.length - 1; i++) {
            for (uint256 j = i + 1; j < _donators.length; j++) {
                if (_donators[j].donated > _donators[i].donated) {
                    Donation memory tempDonator = _donators[i];
                    _donators[i] = _donators[j];
                    _donators[j] = tempDonator;
                }
            }
        }
    }
}