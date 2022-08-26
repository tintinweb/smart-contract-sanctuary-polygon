//Resource.sol
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10; // Solidity files have to start with this pragma.
contract ResourceShare {
    struct Resource {
        uint8 id;
        address creator;
        string title;
        string url;
        string description;
        uint8 total_votes;
    }
    mapping(uint256 => Resource) public resources;
    event savingsEvent(uint256 indexed _resourceId);
    uint8 public numResource;
    constructor() {
        numResource = 0;
        addResource(
            "freecodecamp",
            "https://www.freecodecamp.org/",
            "Learn to code"
        );
    }
    function addResource(
        string memory title,
        string memory url,
        string memory description
    ) public {
        Resource storage resource = resources[numResource];
        resource.creator = msg.sender;
        resource.total_votes = 0;
        resources[numResource] = Resource(
            numResource,
            resource.creator,
            title,
            url,
            description,
            resource.total_votes
        );
        numResource++;
    }
    //return a particular resource
    function getResource(uint256 resourceId)
        public
        view
        returns (Resource memory)
    {
        return resources[resourceId];
    }
    //return the array of resources
    function getResources() public view returns (Resource[] memory) {
        Resource[] memory id = new Resource[](numResource);
        for (uint256 i = 0; i < numResource; i++) {
            Resource storage resource = resources[i];
            id[i] = resource;
        }
        return id;
    }
    // Vote a resource
    function voteResource(uint256 resourceId) public {
        Resource storage resource = resources[resourceId];
        resource.total_votes++;
    }
}