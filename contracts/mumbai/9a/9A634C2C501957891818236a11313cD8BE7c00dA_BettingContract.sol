/**
 *Submitted for verification at polygonscan.com on 2023-05-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract BettingContract {
    address private _owner;
    uint256 private _lobbyCount;
    mapping(uint256 => Lobby) private _lobbies;
    mapping(uint256 => bool) private _closedLobbies;

    struct Lobby {
        uint256 lobbyId;
        uint256 betAmount;
        address player1;
        address player2;
        bool closed;
    }

    constructor() {
        _owner = msg.sender;
        _lobbyCount = 0;
    }

    function createLobby() external payable {
        require(msg.value > 0, "Invalid bet amount");
        _lobbyCount++;
        _lobbies[_lobbyCount] = Lobby(_lobbyCount, msg.value, msg.sender, address(0), false);
    }

    function placeBet(uint256 lobbyId) external payable {
        require(lobbyId <= _lobbyCount, "Invalid lobby ID");
        require(!_closedLobbies[lobbyId], "Lobby is closed");
        require(msg.value > 0, "Invalid bet amount");
        require(_lobbies[lobbyId].player1 != address(0), "Lobby does not exist or is closed");
        require(_lobbies[lobbyId].player2 == address(0), "Lobby is already full");

        _lobbies[lobbyId].player2 = msg.sender;
        _lobbies[lobbyId].closed = true;
    }

    function closeLobby(uint256 lobbyId) external {
        require(lobbyId <= _lobbyCount, "Invalid lobby ID");
        require(!_closedLobbies[lobbyId], "Lobby is already closed");
        require(_lobbies[lobbyId].player1 != address(0), "Lobby does not exist or is closed");

        if (_lobbies[lobbyId].player2 == address(0)) {
            // No second player, return bet to the first player
            payable(_lobbies[lobbyId].player1).transfer(_lobbies[lobbyId].betAmount);
        } else {
            // Calculate winner and distribute funds
            uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 100;
            address winner;
            uint256 winnerAmount;
            uint256 contractBalance = address(this).balance;

            if (randomNumber >= 2 && randomNumber <= 48) {
                winner = _lobbies[lobbyId].player1;
                winnerAmount = (contractBalance * 80) / 100;
            } else if (randomNumber >= 49 && randomNumber <= 95) {
                winner = _lobbies[lobbyId].player2;
                winnerAmount = (contractBalance * 80) / 100;
            } else {
                winner = _owner;
                winnerAmount = (contractBalance * 90) / 100;
            }

            _closedLobbies[lobbyId] = true;

            payable(winner).transfer(winnerAmount);
            payable(address(0)).transfer((contractBalance * 15) / 100);
            payable(_owner).transfer((contractBalance * 5) / 100);
        }
    }

    function getLobby(uint256 lobbyId) external view returns (uint256, uint256, address, address, bool) {
        require(lobbyId <= _lobbyCount, "Invalid lobby ID");

        Lobby memory lobby = _lobbies[lobbyId];
        return (lobby.lobbyId, lobby.betAmount, lobby.player1, lobby.player2, lobby.closed);
    }

    function getClosedLobbies(uint256 lobbyId) external view returns (bool) {
        return _closedLobbies[lobbyId];
    }

    function withdrawTokens() external {
        require(msg.sender == _owner, "Only contract owner can withdraw tokens");

        IERC20 amberToken = IERC20(0xf32d5D5FA5d2545071570c0EEf6E2C65A4c7e5c5);
        uint256 contractBalance = amberToken.balanceOf(address(this));

        require(contractBalance > 0, "Contract balance is zero");

        amberToken.transfer(_owner, contractBalance);
    }
}