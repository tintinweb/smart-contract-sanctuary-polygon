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

    function VerifyMessage(
        bytes32 _hashedMessage,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public pure returns (address _signer) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(
            abi.encodePacked(prefix, _hashedMessage)
        );
        _signer = ecrecover(prefixedHashMessage, _v, _r, _s);
    }
}