pragma solidity ^0.8.9;

contract PlayerProfile {
    struct PlayerState {
        string nick;
        // TODO: 是否需要
        string pfp;
    }

    uint8 constant NAME_LEN = 16;

    mapping(address => PlayerState) players;

    function createProfile(string memory _nick, string memory _pfp) external {
        _createProfile(msg.sender, _nick, _pfp);
    }

    function getProfile(
        address _player
    ) external view returns (PlayerState memory) {
        PlayerState storage state = players[_player];
        return state;
    }

    function _createProfile(
        address _player,
        string memory _nick,
        string memory _pfp
    ) internal {
        require(bytes(_nick).length <= NAME_LEN, "Player nick name exceeds 16 chars");
        
        PlayerState storage state = players[_player];
        state.nick = _nick;
        state.pfp = _pfp;
    }
}