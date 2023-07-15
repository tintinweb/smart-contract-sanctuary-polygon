// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Crowd_Funding {
    address payable internal ownerApp;

    constructor() {
        ownerApp = payable(msg.sender);
    }

    struct Campaign {
        uint256 cId;
        address owner;
        string title;
        string category;
        string story;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string[] image;
        uint256 atcreate;
        uint256 status;
        address[] donators;
        uint256[] donations;
        uint256[] donation_date;
        address[] myTransactionHash;
        uint256[] myBlockNumber;
        string[] method;
        uint256[] myAmountTransaction;
        uint256[] myDateTransaction;
        uint256[] refunds;
        address[] donatorRefund;
        uint256[] refunded_date;
        uint256[] withdraws;
        bytes32 hash_campaign;
    }

    mapping(uint256 => Campaign) public campaigns;

    uint256 public numberOfCampaigns = 0;
    uint256 public numberOfTransactions = 0;

    function createCampaign(
        string memory _title,
        string memory _category,
        string memory _story,
        uint256 _target,
        uint256 _deadline,
        string[] memory _image,
        uint256 _atcreate
    ) external returns (uint256, uint256) {
        Campaign storage campaign = campaigns[numberOfCampaigns];

        require(
            campaign.deadline < block.timestamp,
            "The deadline should be a date in the future."
        );

        //bytes32  randomHash = keccak256(abi.encodePacked(block.timestamp, numberOfCampaigns));
        //string hash_camp = bytes32ToString(randomHash);
        //randomHash = randomHash.substring(0, 8);
        campaign.cId = numberOfCampaigns;
        campaign.hash_campaign = keccak256(
            abi.encodePacked(block.timestamp, numberOfCampaigns)
        );
        campaign.owner = msg.sender;
        campaign.title = _title;
        campaign.category = _category;
        campaign.story = _story;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;
        campaign.atcreate = _atcreate;
        campaign.status = 0;
        campaign.myTransactionHash.push(tx.origin);
        campaign.myBlockNumber.push(block.number);
        campaign.method.push("Create campaign");
        campaign.myAmountTransaction.push(0);
        campaign.myDateTransaction.push(block.timestamp);

        numberOfCampaigns++;
        numberOfTransactions++;

        return (numberOfCampaigns - 1, numberOfTransactions - 1);
    }

    function donateToCampaign(uint256 _id) external payable {
        uint256 amount = msg.value;

        Campaign storage campaign = campaigns[_id];

        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);
        campaign.donation_date.push(block.timestamp);

        campaign.myTransactionHash.push(tx.origin);
        campaign.myBlockNumber.push(block.number);
        campaign.method.push("Donate to campaign");
        campaign.myAmountTransaction.push(amount);
        campaign.myDateTransaction.push(block.timestamp);

        campaign.amountCollected = campaign.amountCollected + amount;
        campaign.status = 1;
    }

    function getDonators(
        uint256 _id
    )
        external
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory,
            address[] memory,
            uint256[] memory,
            string[] memory
        )
    {
        return (
            campaigns[_id].donators,
            campaigns[_id].donations,
            campaigns[_id].donation_date,
            campaigns[_id].myTransactionHash,
            campaigns[_id].myBlockNumber,
            campaigns[_id].method
        );
    }

    function getCampaigns() external view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        for (uint i = 0; i < numberOfCampaigns; i++) {
            Campaign storage item = campaigns[i];

            allCampaigns[i] = item;
        }

        return allCampaigns;
    }

    function withdraw(uint256 _id) external returns (string memory message) {
        message = "Operacion realizada";
        Campaign storage campaign = campaigns[_id];

        require(
            msg.sender == campaign.owner,
            "Only the owner can withdraw the campaign."
        );

        uint256 valor = campaign.amountCollected;
        uint256 comision;
        comision = (valor / 10000) * 500; //10000 = 100, 100 = 1%, 200 = 2%, 500 = 5%, 50 = 0.5%

        uint total = valor - comision;

        (bool sent_owner, ) = payable(campaign.owner).call{value: total}("");

        (bool sent_appOwner, ) = payable(ownerApp).call{value: comision}("");

        if (sent_owner) {
            campaign.amountCollected = campaign.amountCollected;
            campaign.status = 2;
            campaign.myTransactionHash.push(tx.origin);
            campaign.myBlockNumber.push(block.number);
            campaign.method.push("Withdraw");
            campaign.myAmountTransaction.push(valor);
            campaign.myDateTransaction.push(block.timestamp);
            campaign.withdraws.push(valor);
        }

        if (sent_appOwner) {
            return message;
        }
    }

    /*   function refund(uint256 _id) public {
        Campaign storage campaign = campaigns[_id];

        require(
            msg.sender == campaign.owner || msg.sender == ownerApp,
            "Only the owner can refund the campaign."
        );
        uint256 donation;

        for (uint256 i = 0; i < campaign.donators.length; i++) {
            address donator = campaign.donators[i];

            donation = campaign.donations[i];
            payable(donator).transfer(donation);
            campaign.status = 3;
            campaign.myTransactionHash.push(tx.origin);
            campaign.myBlockNumber.push(block.number);
            campaign.method.push("Refund");
            campaign.myAmountTransaction.push(donation);
           // campaign.myDateTransaction.push(block.timestamp);
        }

        campaign.donators = new address[](0);
        campaign.donations = new uint256[](0);
        campaign.amountCollected = 0;
    } */

    function refund2(uint256 _id) external {
        Campaign storage campaign = campaigns[_id];

        uint256 donation;
        for (uint256 i = 0; i < campaign.donators.length; i++) {
            address donator = campaign.donators[i];
            donation = campaign.donations[i];
            if (donator == msg.sender) {
                payable(donator).transfer(donation);
                campaign.status = 4;
                campaign.myTransactionHash.push(tx.origin);
                campaign.myBlockNumber.push(block.number);
                campaign.method.push("Refund");
                campaign.myAmountTransaction.push(donation);
                campaign.myDateTransaction.push(block.timestamp);
                campaign.refunds.push(donation);
                campaign.donatorRefund.push(donator);
                campaign.refunded_date.push(block.timestamp);

                // campaign.donators[i] = address(0);
                // campaign.donations[i] = 0;
                campaign.amountCollected -= donation;
            }

            if (campaign.amountCollected == 0) {
                campaign.status = 3;
            }
        }
    }

    function requestRefund(uint256 _id) external {
        Campaign storage campaign = campaigns[_id];

        uint256 amount;
        uint256 index;
        bool found = false;
        for (uint256 i = 0; i < campaign.donators.length; i++) {
            if (campaign.donators[i] == msg.sender) {
                found = true;
                index = i;
                amount = campaign.donations[i];
                break;
            }
        }

        require(found, "You did not donate to this campaign.");

        uint256 totalRefund = 0;
        uint256 refundIndex;
        bool refunded = false;
        for (uint256 i = 0; i < campaign.donatorRefund.length; i++) {
            if (campaign.donatorRefund[i] == msg.sender) {
                totalRefund += campaign.refunds[i];
                refundIndex = i;
                refunded = true;
            }
        }

        if (refunded) {
            if (totalRefund >= amount) {
                revert(
                    "You have already requested a full refund for this campaign."
                );
            } else {
                uint256 remainingAmount = amount - totalRefund;

                campaign.amountCollected -= remainingAmount;

                campaign.refunds[refundIndex] += remainingAmount;
                campaign.myTransactionHash.push(tx.origin);
                campaign.myBlockNumber.push(block.number);
                campaign.method.push("Refund");
                campaign.myAmountTransaction[refundIndex] += remainingAmount;
                campaign.myDateTransaction.push(block.timestamp);
                campaign.donatorRefund.push(msg.sender);
                campaign.refunded_date.push(block.timestamp);

                payable(msg.sender).transfer(remainingAmount);
            }
        } else {
            campaign.amountCollected -= amount;
            campaign.donatorRefund.push(msg.sender);
            campaign.refunds.push(amount);
            campaign.myTransactionHash.push(tx.origin);
            campaign.myBlockNumber.push(block.number);
            campaign.method.push("Refund");
            campaign.myAmountTransaction.push(amount);
            campaign.myDateTransaction.push(block.timestamp);
            campaign.refunded_date.push(block.timestamp);

            payable(msg.sender).transfer(amount);
        }
    }

    function requestRefund2(uint256 _id) external {
        Campaign storage campaign = campaigns[_id];

        uint256 amount;
        uint256 index;
        bool found = false;
        for (uint256 i = 0; i < campaign.donators.length; i++) {
            if (campaign.donators[i] == msg.sender) {
                found = true;
                index = i;
                amount = campaign.donations[i];
                break;
            }
        }

        require(found, "You did not donate to this campaign.");

        uint256 totalRefund = 0;
        uint256 refundIndex;
        bool refunded = false;
        for (uint256 i = 0; i < campaign.donatorRefund.length; i++) {
            if (campaign.donatorRefund[i] == msg.sender) {
                totalRefund += campaign.refunds[i];
                refundIndex = i;
                refunded = true;
            }
        }

        if (totalRefund >= amount) {
            revert(
                "You have already requested a full refund for this campaign."
            );
        } else {
            uint256 remainingAmount = amount - totalRefund;

            campaign.amountCollected -= remainingAmount;
            if (refunded) {
                campaign.refunds[refundIndex] += remainingAmount;
            } else {
                campaign.donatorRefund.push(msg.sender);
                campaign.refunds.push(remainingAmount);
                refundIndex = campaign.donatorRefund.length - 1;
            }
            campaign.myTransactionHash.push(tx.origin);
            campaign.myBlockNumber.push(block.number);
            campaign.method.push("Refund");
            campaign.myAmountTransaction[refundIndex] += remainingAmount;
            campaign.myDateTransaction.push(block.timestamp);
            campaign.refunded_date.push(block.timestamp);

            payable(msg.sender).transfer(remainingAmount);
        }
    }

    function requestRefund3(uint256 _id) external {
        Campaign storage campaign = campaigns[_id];

        uint256 amount;
        uint256 index;
        bool found = false;
        for (uint256 i = 0; i < campaign.donators.length; i++) {
            if (campaign.donators[i] == msg.sender) {
                found = true;
                index = i;
                amount = campaign.donations[i];
                break;
            }
        }

        require(found, "You did not donate to this campaign.");

        uint256 totalRefund = 0;
        uint256 refundIndex;
        bool refunded = false;
        for (uint256 i = 0; i < campaign.donatorRefund.length; i++) {
            if (campaign.donatorRefund[i] == msg.sender) {
                totalRefund += campaign.refunds[i];
                refundIndex = i;
                refunded = true;
            }
        }

        uint256 totalDonated = 0;
        for (uint256 i = 0; i < campaign.donators.length; i++) {
            if (campaign.donators[i] == msg.sender) {
                totalDonated += campaign.donations[i];
            }
        }

        if (totalRefund >= totalDonated) {
            revert(
                "You have already requested a full refund for this campaign."
            );
        } else if (totalRefund >= amount) {
            revert(
                "You have already requested a full refund for this donation."
            );
        } else {
            uint256 remainingAmount = amount - totalRefund;

            campaign.amountCollected -= remainingAmount;
            if (refunded) {
                campaign.refunds[refundIndex] += remainingAmount;
            } else {
                campaign.donatorRefund.push(msg.sender);
                campaign.refunds.push(remainingAmount);
                refundIndex = campaign.donatorRefund.length - 1;
            }
            campaign.myTransactionHash.push(tx.origin);
            campaign.myBlockNumber.push(block.number);
            campaign.method.push("Refund");
            campaign.myAmountTransaction[refundIndex] += remainingAmount;
            campaign.myDateTransaction.push(block.timestamp);
            campaign.refunded_date.push(block.timestamp);

            payable(msg.sender).transfer(remainingAmount);
        }
    }

    function verBalanceContrato() external view returns (uint256) {
        return (address(this).balance);
    }

    function verAddressContrato() external view returns (address) {
        return address(this);
    }
}