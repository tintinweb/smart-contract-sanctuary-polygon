// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract ShuffleDao {
    uint256 activePlayers;
    uint256 totalPlayers;
    struct Player {
        uint256 playerId;
        address sigAddress;
        address currentOpponent;
        uint256 buyinAmount;
        uint256 buyinTime;
        bool isActive;
    }
    mapping(address => Player) public players;

    receive() external payable {}

    function buyin(address _sigAddress, address _opponent) external payable {
        require(!players[msg.sender].isActive, "already active");
        Player memory player = Player(
            totalPlayers,
            _sigAddress,
            _opponent,
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

    function getFlopHashes()
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
        uint256 _arb_val = (totalPlayers * activePlayers * block.timestamp) / 2;
        bytes32 _hash1 = keccak256(abi.encodePacked(_time));
        bytes32 _hash2 = keccak256(abi.encodePacked(_time, _arb_val));
        bytes32 _hash3 = keccak256(abi.encodePacked(_arb_val, _time));
        return (_hash1, _hash2, _hash3);
    }

    function getTurnHashes() external view returns (bytes32 _hash) {
        uint256 _arb_value = block.timestamp * totalPlayers * 123456;
        _hash = keccak256(abi.encodePacked(block.timestamp, _arb_value));
    }

    function getRiverHashes() external view returns (bytes32 _hash) {
        uint256 _arb_value = block.timestamp * activePlayers * 654321;
        _hash = keccak256(abi.encodePacked(_arb_value, block.timestamp));
    }
}