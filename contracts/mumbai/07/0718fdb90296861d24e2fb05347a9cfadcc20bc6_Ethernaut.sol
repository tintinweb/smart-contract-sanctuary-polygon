/**
 *Submitted for verification at polygonscan.com on 2023-05-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILevel {
    function createInstance(address _player) external payable returns (address);

    function validateInstance(
        address payable _instance,
        address _player
    ) external returns (bool);
}

interface IStatistics {
    function saveNewLevel(address level) external;

    function createNewInstance(
        address instance,
        address level,
        address player
    ) external;

    function submitFailure(
        address instance,
        address level,
        address player
    ) external;

    function submitSuccess(
        address instance,
        address level,
        address player
    ) external;
}

contract Ethernaut {
    IStatistics public statistics;

    // ----------------------------------
    // Owner interaction
    // ----------------------------------

    mapping(address => bool) public registeredLevels;
    mapping(address => string) public playersName;
    mapping(address => string) public playersTG;

    // Only registered levels will be allowed to generate and validate level instances.
    function registerLevel(address _level) public {
        registeredLevels[_level] = true;
        statistics.saveNewLevel(_level);
    }

    function setStatistics(address _statProxy) external {
        statistics = IStatistics(_statProxy);
    }

    // ----------------------------------
    // Get/submit level instances
    // ----------------------------------

    struct EmittedInstanceData {
        address player;
        ILevel level;
        bool completed;
    }

    mapping(address => EmittedInstanceData) public emittedInstances;

    event LevelInstanceCreatedLog(
        address indexed player,
        address instance,
        string nickname
    );
    event LevelCompletedLog(
        address indexed player,
        ILevel level,
        string nickname
    );

    function register(
        string memory _nickname,
        string memory _tg
    ) public returns (bool) {
        if (
            bytes(_nickname).length > 0 &&
            bytes(playersName[msg.sender]).length == 0
        ) {
            playersName[msg.sender] = _nickname;
            playersTG[msg.sender] = _tg;
            return true;
        }
        return false;
    }

    function createLevelInstance(ILevel _level) public payable {
        // Ensure level is registered.
        require(registeredLevels[address(_level)], "This level doesn't exists");

        // Get level factory to create an instance.
        address instance = _level.createInstance{value: msg.value}(msg.sender);

        // Store emitted instance relationship with player and level.
        emittedInstances[instance] = EmittedInstanceData(
            msg.sender,
            _level,
            false
        );

        statistics.createNewInstance(instance, address(_level), msg.sender);

        // Retrieve created instance via logs.
        emit LevelInstanceCreatedLog(
            msg.sender,
            instance,
            playersName[msg.sender]
        );
    }

    function submitLevelInstance(address payable _instance) public {
        // Get player and level.
        EmittedInstanceData storage data = emittedInstances[_instance];
        require(
            data.player == msg.sender,
            "This instance doesn't belong to the current user"
        ); // instance was emitted for this player
        require(data.completed == false, "Level has been completed already"); // not already submitted

        // Have the level check the instance.
        if (data.level.validateInstance(_instance, msg.sender)) {
            // Register instance as completed.
            data.completed = true;

            statistics.submitSuccess(
                _instance,
                address(data.level),
                msg.sender
            );
            // Notify success via logs.
            emit LevelCompletedLog(
                msg.sender,
                data.level,
                playersName[msg.sender]
            );
        } else {
            statistics.submitFailure(
                _instance,
                address(data.level),
                msg.sender
            );
        }
    }
}