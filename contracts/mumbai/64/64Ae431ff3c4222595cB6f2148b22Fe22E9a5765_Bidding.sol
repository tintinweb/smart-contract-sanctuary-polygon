// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Bidding {
    struct Sponsor {
        address sponsorAddress;
        string videoUrl;
        uint budget;
        uint maxBid;
    }

    Sponsor[] public sponsors;
    address public receiverAddress;

    constructor(address _receiverAddress) {
        receiverAddress = _receiverAddress;
    }

    function registerSponsor(string memory _videoUrl, uint _maxBid) public payable {
        require(msg.value > 0, "You need to set a budget.");
        sponsors.push(Sponsor(msg.sender, _videoUrl, msg.value, _maxBid));
    }

    function getBestAd() public returns (string memory) {
        require(sponsors.length > 0, "No sponsors registered.");

        uint bestIndex = 0;
        uint highestBid = 0;

        for (uint i = 0; i < sponsors.length; i++) {
            if (sponsors[i].budget >= sponsors[i].maxBid && sponsors[i].maxBid > highestBid) {
                bestIndex = i;
                highestBid = sponsors[i].maxBid;
            }
        }

        require(sponsors[bestIndex].sponsorAddress != address(0), "No ads available.");

        sponsors[bestIndex].budget -= sponsors[bestIndex].maxBid;
        payable(receiverAddress).transfer(sponsors[bestIndex].maxBid);

        return sponsors[bestIndex].videoUrl;
    }
}