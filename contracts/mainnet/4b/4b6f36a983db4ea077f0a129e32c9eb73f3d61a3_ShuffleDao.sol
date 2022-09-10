// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract ShuffleDao {
    uint256 activePlayers;
    struct Player {
        address sigAddress;
        uint256 buyinAmount;
        uint256 buyinTime;
        bool isActive;
    }
    mapping(address => Player) public players;

    receive() external payable {}

    function buyin(address _sigAddress) external payable {
        require(!players[msg.sender].isActive, "already active");
        Player memory player = Player(
            _sigAddress,
            msg.value,
            block.timestamp,
            true
        );
        players[msg.sender] = player;
    }

    function getSigKey(address _userAddress)
        external
        view
        returns (address _sigAddress)
    {
        require(players[msg.sender].isActive);
        _sigAddress = players[_userAddress].sigAddress;
    }
}