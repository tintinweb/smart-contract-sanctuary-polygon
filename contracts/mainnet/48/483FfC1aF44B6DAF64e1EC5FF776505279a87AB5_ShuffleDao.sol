// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract ShuffleDao {
    uint256 activePlayers;
    uint256 totalPlayers;
    struct Player {
        uint256 playerId;
        address sigAddress;
        address currentOpponent;
        string keyword;
        uint256 buyinAmount;
        uint256 buyinTime;
        bool isActive;
    }
    mapping(address => Player) public players;

    receive() external payable {}

    function buyin(
        address _sigAddress,
        address _opponent,
        string memory _keyword
    ) external payable {
        require(!players[msg.sender].isActive, "already active");
        Player memory player = Player(
            totalPlayers,
            _sigAddress,
            _opponent,
            _keyword,
            msg.value,
            block.timestamp,
            true
        );
        players[msg.sender] = player;
        totalPlayers++;
        activePlayers++;
    }

    function getSigKey(address _userAddress)
        external
        view
        returns (address _sigAddress)
    {
        require(players[msg.sender].isActive);
        _sigAddress = players[_userAddress].sigAddress;
    }

    function getCardHashes(uint256 _street)
        external
        view
        returns (
            bytes32,
            bytes32,
            bytes32
        )
    {
        require(players[msg.sender].isActive);
        uint256 _time = block.timestamp;
        address _opponent = players[msg.sender].currentOpponent;
        bytes32 _hash1 = keccak256(
            abi.encodePacked(msg.sender, _opponent, _time)
        );
        if (_street == 1) {
            return (_hash1, 0, 0);
        } else {
            bytes32 _hash2 = keccak256(
                abi.encodePacked(
                    msg.sender,
                    _opponent,
                    _time,
                    players[msg.sender].playerId
                )
            );
            bytes32 _hash3 = keccak256(
                abi.encodePacked(
                    msg.sender,
                    _opponent,
                    _time,
                    players[_opponent].playerId
                )
            );
            return (_hash1, _hash2, _hash3);
        }
    }
}