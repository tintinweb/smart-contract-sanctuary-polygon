// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract AssetTracker {
    struct Asset {
        string name;
        string description;
        uint256 cost;
        uint256 quantity;
        string manufacturer;
        string customer;
        string addressFrom;
        string addressTo;
        bool initialized;
        bool arrived;
        uint256 distributorId;
    }

    struct Person {
        //struct for distributor
        uint256 id;
        string name;
        string add;
        string email;
        string phone;
    }

    mapping(uint256 => Person) private distributorStruct;
    uint256 public distributorCount = 0;
    uint256 public assetCount = 0;

    event RejectDistributor(
        string name,
        string add,
        string email,
        string phone
    );

    function insertDistributor(
        string memory name,
        string memory add,
        string memory email,
        string memory phone
    ) public returns (bool) {
        for (uint256 i = 0; i < distributorCount; i++) {
            require(
                keccak256(abi.encodePacked((distributorStruct[i].email))) !=
                    keccak256(abi.encodePacked(("[email protected]"))),
                "Distributor already exists"
            );
        }
        distributorStruct[distributorCount] = Person(
            distributorCount,
            name,
            add,
            email,
            phone
        );
        distributorCount++;
        return true;
    }

    function getDistributorbyId(
        uint256 id
    )
        public
        view
        returns (string memory, string memory, string memory, string memory)
    {
        return (
            distributorStruct[id].name,
            distributorStruct[id].add,
            distributorStruct[id].email,
            distributorStruct[id].phone
        );
    }

    function getAlldistributors() public view returns (Person[] memory) {
        Person[] memory id = new Person[](distributorCount);
        for (uint256 i = 0; i < distributorCount; i++) {
            Person storage member = distributorStruct[i];
            id[i] = member;
        }
        return id;
    }

    function balance(uint256 _amount) public pure returns (bool) {
        require(_amount < 20, "Balance need to be greater than 20");
        return true;
    }

    //end of distributor

    mapping(uint256 => Asset) private assetStore;

    mapping(address => mapping(uint256 => bool)) private walletStore;

    function createAsset(
        string memory name,
        string memory description,
        uint256 distributorId,
        uint256 cost,
        uint256 quantity,
        string memory manufacturer,
        string memory customer,
        string memory addressFrom,
        string memory addressTo
    ) public {
        assetStore[assetCount] = Asset(
            name,
            description,
            cost,
            quantity,
            manufacturer,
            customer,
            addressFrom,
            addressTo,
            true,
            false,
            distributorId
        );
        walletStore[msg.sender][assetCount] = true;
        assetCount++;
    }

    function transferAsset(address to, uint256 i) public {
        require(
            assetStore[assetCount].initialized == true,
            "No asset with this UUID exists"
        );

        require(
            walletStore[msg.sender][i] == true,
            "Sender does not own this asset."
        );

        walletStore[msg.sender][i] = false;
        walletStore[to][i] = true;
    }

    function getItemByUUID(
        uint256 i
    ) public view returns (uint256 cost, uint256 quantity) {
        require(i <= assetCount, "Asset does not exists");
        return (assetStore[i].cost, assetStore[i].quantity);
    }

    function isOwnerOf(address owner, uint256 i) public view returns (bool) {
        if (walletStore[owner][i]) {
            return true;
        }
        return false;
    }

    function getAllAssets() public view returns (Asset[] memory) {
        Asset[] memory x = new Asset[](assetCount);
        for (uint256 i = 0; i < assetCount; i++) {
            Asset storage member = assetStore[i];
            x[i] = member;
        }
        return x;
    }

    //consumer end

    function Arrived(uint256 i) public {
        assetStore[i].arrived = true;
    }

    constructor() {}
}