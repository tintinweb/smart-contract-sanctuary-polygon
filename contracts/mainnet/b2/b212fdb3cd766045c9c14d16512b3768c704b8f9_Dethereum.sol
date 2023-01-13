// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "src/Resource.sol";

contract Build is Resource {
    function _costRatio(uint256 costMultiplier) internal pure returns (uint256) {
        return (11 * costMultiplier) / 10;
    }

    function _upgradeMetal(DataStructures.Player storage player) internal {
        _claimResources(player);
        DataStructures.Resources storage resources = player.playerResources;
        DataStructures.Resource storage metal = resources.metal;
        uint256 costMultiplier = _costRatio(metal.costMultiplier);
        metal.costMultiplier = costMultiplier;
        metal.level++;

        uint256 metalCost = 60 * costMultiplier;
        uint256 crystalCost = 15 * costMultiplier;
        uint256 energyPerSecond = 11 * costMultiplier;

        _pay(resources.metal, metalCost);
        _pay(resources.crystal, crystalCost);
        _unStream(resources.energy, energyPerSecond);

        _stream(resources.metal, costMultiplier);
        player.nextBuildingTime = block.timestamp + costMultiplier;
    }

    function _upgradeCrystal(DataStructures.Player storage player) internal {
        _claimResources(player);
        DataStructures.Resources storage resources = player.playerResources;
        DataStructures.Resource storage crystal = resources.crystal;
        uint256 costMultiplier = _costRatio(crystal.costMultiplier);
        crystal.costMultiplier = costMultiplier;
        crystal.level++;

        uint256 metalCost = 48 * costMultiplier;
        uint256 crystalCost = 24 * costMultiplier;
        uint256 energyPerSecond = 11 * costMultiplier;

        _pay(resources.metal, metalCost);
        _pay(resources.crystal, crystalCost);
        _unStream(resources.energy, energyPerSecond);

        _stream(resources.crystal, costMultiplier);
        player.nextBuildingTime = block.timestamp + costMultiplier;
    }

    function _pay(DataStructures.Resource storage resource, uint256 cost) internal {
        resource.resource -= cost;
    }

    function _unStream(DataStructures.Resource storage resource, uint256 stream) internal {
        resource.resourceStream -= stream;
    }

    function _stream(DataStructures.Resource storage resource, uint256 stream) internal {
        resource.resourceStream += stream;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

contract DataStructures {
    struct Resource {
        uint256 resource; // current resource the user has
        uint256 resourceStream; // resource per second the user is gaining
        uint256 resourceCapacity; // max resource the user can have
        uint256 level; // current level of the resource
        uint256 costMultiplier; // cost multiplier of the next mine
        uint256 lastUpdateTime; // The last time this resource was claimed
    }

    struct Resources {
        Resource metal;
        Resource crystal;
        Resource energy;
    }

    struct Player {
        Resources playerResources; // the resources of the player
        uint256 nextBuildingTime; // the next time after which the user will be able to build
        bool playing; // if the user has created an account
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "src/Build.sol";

contract Dethereum is Build {
    mapping(address => DataStructures.Player) players;

    uint256 public constant STARTING_METAL = 1e8;
    uint256 public constant STARTING_CRYSTAL = 1e8;
    uint256 public constant STARTING_ENERGY = 1e8;
    uint256 public constant STARTING_COST_MULTIPLIER = 100;
    uint256 public constant STARTING_CAPACITY_MULTIPLIER = 50;

    function createAccount() public {
        DataStructures.Player storage player = players[msg.sender];
        player.playing = true;
        DataStructures.Resources storage resources = player.playerResources;
        _initializeResource(resources.metal, STARTING_METAL);
        _initializeResource(resources.crystal, STARTING_CRYSTAL);
        _initializeEnergy(resources.energy, STARTING_ENERGY);
    }

    function _initializeResource(DataStructures.Resource storage resource, uint256 _startingValue) internal {
        resource.resource = _startingValue;
        resource.resourceCapacity = STARTING_CAPACITY_MULTIPLIER * _startingValue;
        resource.costMultiplier = STARTING_COST_MULTIPLIER;
        resource.lastUpdateTime = block.timestamp;
    }

    function _initializeEnergy(DataStructures.Resource storage resource, uint256 _startingValue) internal {
        resource.resourceStream = _startingValue;
        resource.resourceCapacity = type(uint256).max;
        resource.lastUpdateTime = block.timestamp;
    }

    function upgradeMetal() public {
        DataStructures.Player storage player = players[msg.sender];
        require(player.playing);
        require(block.timestamp >= player.nextBuildingTime);
        _upgradeMetal(player);
    }

    function upgradeCrystal() public {
        DataStructures.Player storage player = players[msg.sender];
        require(player.playing);
        require(block.timestamp >= player.nextBuildingTime);
        _upgradeCrystal(player);
    }

    function claimResources() public {
        DataStructures.Player storage player = players[msg.sender];
        require(player.playing);
        _claimResources(player);
    }

    function getMetal()
        public
        view
        returns (
            uint256 resourceAmount,
            uint256 resourceStream,
            uint256 resourceCapacity,
            uint256 level,
            uint256 costMultiplier,
            uint256 lastUpdateTime
        )
    {
        return _showResource(players[msg.sender].playerResources.metal);
    }

    function getCrystal()
        public
        view
        returns (
            uint256 resourceAmount,
            uint256 resourceStream,
            uint256 resourceCapacity,
            uint256 level,
            uint256 costMultiplier,
            uint256 lastUpdateTime
        )
    {
        return _showResource(players[msg.sender].playerResources.crystal);
    }

    function getPlaying(address player) public view returns (bool) {
        return players[player].playing;
    }

    function getNextBuildingTime(address player) public view returns (uint256) {
        return players[player].nextBuildingTime;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? b : a;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "src/DataStructures.sol";
import "src/Math.sol";

contract Resource {
    function _claimResources(DataStructures.Player storage player) internal {
        _claimResource(player.playerResources.metal);
        _claimResource(player.playerResources.crystal);
        _claimResource(player.playerResources.energy);
    }

    function _claimResource(DataStructures.Resource storage resource) internal {
        uint256 deltaTime = block.timestamp - resource.lastUpdateTime;
        uint256 resourceAmount = resource.resource;
        uint256 newResourceAmount = resourceAmount + resource.resourceStream * deltaTime;

        resource.resource = Math.min(resource.resourceCapacity, newResourceAmount);

        resource.lastUpdateTime = block.timestamp;
    }

    function _showResource(DataStructures.Resource storage resource)
        internal
        view
        returns (
            uint256 resourceAmount,
            uint256 resourceStream,
            uint256 resourceCapacity,
            uint256 level,
            uint256 costMultiplier,
            uint256 lastUpdateTime
        )
    {
        resourceAmount = resource.resource;
        resourceStream = resource.resourceStream;
        resourceCapacity = resource.resourceCapacity;
        level = resource.level;
        costMultiplier = resource.costMultiplier;
        lastUpdateTime = resource.lastUpdateTime;
    }
}