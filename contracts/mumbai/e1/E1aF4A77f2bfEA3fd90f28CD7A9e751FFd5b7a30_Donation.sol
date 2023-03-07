// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Donation {
    uint256 public numberOfOrganizations = 0;
    
    struct Organization {
        uint256 id;
        address owner;
        string name;
        uint256 target;
        uint256 amountCollected;
        string image;
    }

    Organization[] public organizations;

    function createOrganization(
        // address owner,
        string memory _name,
        uint256 _target,
        string memory _image
    ) public returns (uint256) {
        uint256 currentId = numberOfOrganizations;
        Organization memory organization;

        organization.id = currentId;
        organization.owner = msg.sender;
        // organization.owner = owner;
        organization.name = _name;
        organization.target = _target;
        organization.amountCollected = 0;
        organization.image = _image;
        
        organizations.push(organization);

        numberOfOrganizations++ ;

        return currentId;
    }


    function getOrganizations() public view returns (Organization[] memory) {
        Organization[] memory allOrganizations = new Organization[](numberOfOrganizations);

        for (uint256 i = 0; i < numberOfOrganizations; i++) {
            Organization storage item = organizations[i];

            allOrganizations[i] = item;
        }

        return allOrganizations;
    }

    function donateToOrganization(uint256 _id) public payable {
        uint256 amount = msg.value;

        Organization storage organization = organizations[_id];

        (bool sent, ) = payable(organization.owner).call{value: amount}("");

        if (sent) {
            organization.amountCollected = organization.amountCollected + amount;
        }
    }
}