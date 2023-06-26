pragma solidity ^0.8.9;

interface IRace {
    function getGameBaseinfo(
        address _gameAddr
    ) external view returns (address owner, string memory title, address bundleAddr);
}

pragma solidity ^0.8.9;

import "./interface/IRace.sol";

// TODO: Access Control
contract Registry {
    struct GameReg {
        address addr;
        string title;
        address bundleAddr;
        uint256 regTime;
    }

    struct RegistryState {
        bool isPrivate;
        uint16 size;
        address owner;
        GameReg[] games;
    }

    mapping(address => RegistryState) public registries;

    address race;

    event RegisterGame(address registryAddress, address gameAddress);

    event UnRegisterGame(address registryAddress, address gameAddress);

    constructor(address _race) {
        race = _race;
    }

    function setRace(address _raceContract) external {
        race = _raceContract;
    }

    function createRegistry(
        address _registryAddr,
        bool _isPrivate,
        uint16 _size
    ) external {
        RegistryState storage state = registries[_registryAddr];
        require(state.owner == address(0), "already init");
        state.isPrivate = _isPrivate;
        state.owner = msg.sender;
        state.size = _size;
    }

    function registerGame(
        address _registryAddr,
        address _gameAddr
    ) external checkRegistry(_registryAddr) {
        RegistryState storage state = registries[_registryAddr];

        (address gameOwner, string memory title, address bundleAddr) = IRace(
            race
        ).getGameBaseinfo(_gameAddr);

        require(
            state.games.length < state.size,
            "registration center is already full"
        );
        require(gameOwner == msg.sender, "invalid owner of this account");
        if (state.isPrivate && msg.sender != state.owner) {
            revert("invalid owner of this account");
        }

        for (uint256 i = 0; i < state.games.length; i++) {
            require(
                state.games[i].addr != _gameAddr,
                "game already registered"
            );
        }
        state.games.push(
            GameReg({
                title: title,
                addr: _gameAddr,
                bundleAddr: bundleAddr,
                regTime: block.timestamp
            })
        );
        emit RegisterGame(_registryAddr, _gameAddr);
    }

    function getRegistry(
        address _registryAddr
    ) external view returns (RegistryState memory) {
        RegistryState storage state = registries[_registryAddr];
        return state;
    }

    function getGameList(
        address _registryAddr
    ) external view checkRegistry(_registryAddr) returns (GameReg[] memory) {
        RegistryState storage state = registries[_registryAddr];
        return state.games;
    }

    function unregisterGame(
        address _registryAddr,
        address _gameAddr
    ) external checkRegistry(_registryAddr) {
        RegistryState storage state = registries[_registryAddr];
        if (state.isPrivate && msg.sender != state.owner) {
            revert("invalid owner of this account");
        }
        (address gameOwner, , ) = IRace(race).getGameBaseinfo(_gameAddr);
        require(gameOwner == msg.sender, "invalid owner of this account");

        uint256 idx = 0;
        bool exists = false;
        for (uint256 i = 0; i < state.games.length; i++) {
            if (state.games[i].addr == _gameAddr) {
                idx = i;
                exists = true;
                break;
            }
        }
        if (!exists) {
            revert(
                "Can't unregister the game as it has not been registered yet"
            );
        }
        // remove game
        for (uint256 i = idx + 1; i < state.games.length - 1; i++) {
            state.games[i] = state.games[i + 1];
        }
        state.games.pop();

        emit UnRegisterGame(_registryAddr, _gameAddr);
    }

    modifier checkRegistry(address _registryAddr) {
        RegistryState storage state = registries[_registryAddr];
        require(state.owner != address(0), "uninitialized");
        _;
    }
}