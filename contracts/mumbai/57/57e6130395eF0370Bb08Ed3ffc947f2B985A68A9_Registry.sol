pragma solidity ^0.8.9;

interface IRace {
    function getGameBaseinfo(
        bytes32 _gameID
    ) external view returns (address owner, string memory title, address bundleAddr);
}

pragma solidity ^0.8.9;

import "./interface/IRace.sol";

// TODO: Access Control
contract Registry {
    struct GameRegistration {
        bytes32 addr;
        string title;
        address bundleAddr;
        uint256 regTime;
    }

    struct RegistryState {
        bool isPrivate;
        uint16 size;
        address owner;
        GameRegistration[] games;
    }

    mapping(address => RegistryState) public registries;

    address public race;

    event CreateRegistry(address registryAddr, address owner);

    event RegisterGame(address registryAddr, bytes32 gameID);

    event UnRegisterGame(address registryAddr, bytes32 gameID);

    constructor(address _race) {
        race = _race;
    }

    function setRace(address _raceContract) external {
        race = _raceContract;
    }

    function createRegistry(bool _isPrivate, uint16 _size) external {
        RegistryState storage state = registries[msg.sender];
        require(state.owner == address(0), "already init");
        state.isPrivate = _isPrivate;
        state.owner = msg.sender;
        state.size = _size;

        emit CreateRegistry(msg.sender, msg.sender);
    }

    function registerGame(
        address _registryAddr,
        bytes32 _gameID
    ) external checkRegistry(_registryAddr) {
        RegistryState storage state = registries[_registryAddr];

        (address gameOwner, string memory title, address bundleAddr) = IRace(
            race
        ).getGameBaseinfo(_gameID);

        require(
            state.games.length < state.size,
            "registration center is already full"
        );
        require(gameOwner == msg.sender, "invalid owner of this account");
        if (state.isPrivate && msg.sender != state.owner) {
            revert("invalid owner of this account");
        }

        for (uint256 i = 0; i < state.games.length; i++) {
            require(state.games[i].addr != _gameID, "game already registered");
        }
        state.games.push(
            GameRegistration({
                title: title,
                addr: _gameID,
                bundleAddr: bundleAddr,
                regTime: block.timestamp
            })
        );
        emit RegisterGame(_registryAddr, _gameID);
    }

    function getRegistry(
        address _registryAddr
    ) external view returns (RegistryState memory) {
        RegistryState storage state = registries[_registryAddr];
        return state;
    }

    function getGameList(
        address _registryAddr
    )
        external
        view
        checkRegistry(_registryAddr)
        returns (GameRegistration[] memory)
    {
        RegistryState storage state = registries[_registryAddr];
        return state.games;
    }

    function unregisterGame(
        address _registryAddr,
        bytes32 _gameID
    ) external checkRegistry(_registryAddr) {
        RegistryState storage state = registries[_registryAddr];
        if (state.isPrivate && msg.sender != state.owner) {
            revert("invalid owner of this account");
        }
        (address gameOwner, , ) = IRace(race).getGameBaseinfo(_gameID);
        require(gameOwner == msg.sender, "invalid owner of this account");

        uint256 idx;
        bool exists;
        for (uint256 i = 0; i < state.games.length; i++) {
            if (state.games[i].addr == _gameID) {
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

        emit UnRegisterGame(_registryAddr, _gameID);
    }

    modifier checkRegistry(address _registryAddr) {
        RegistryState storage state = registries[_registryAddr];
        require(state.owner != address(0), "uninitialized");
        _;
    }
}