pragma solidity ^0.8.9;

contract PlayerProfile {
    struct PlayerState {
        bool isInitialized;
        string nick;
        string pfp;
    }

    uint8 constant NAME_LEN = 16;

    mapping(address => PlayerState) players;

    function createProfile(string memory nick, string memory pfp) external {
        _createProfile(msg.sender, nick, pfp);
    }

    function getProfile(
        address player
    ) external view returns (PlayerState memory) {
        PlayerState storage state = players[player];
        return state;
    }

    function _createProfile(
        address player,
        string memory nick,
        string memory pfp
    ) internal {
        require(bytes(nick).length <= NAME_LEN, "nick length too long");
        
        PlayerState storage state = players[player];
        state.isInitialized = true;
        state.nick = nick;
        state.pfp = pfp;
    }
}