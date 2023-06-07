// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IMines.sol";

contract Mines is IMines {
    struct Game {
        address player;
        uint256 wager;
        uint8 revealedNum;
    }

    uint256 public nextGameId;
    mapping(uint256 => Game) public games;

    function startAndReveal(uint8 minesNum, uint8 selectionIndex, address tokenAddress) external payable {
        require(msg.value > 0, "Mines: wanna play - gotta pay!");
        uint256 gameId = nextGameId ++;
        games[gameId].player = msg.sender;
        games[gameId].wager = msg.value;
        bool success = nextGameId % 5 != 0;
        if (success) {
            games[gameId].revealedNum ++;
        }
        emit GameStarted(gameId);
        emit Revealed(gameId, selectionIndex, success);
    }

    function reveal(uint256 gameId, uint8 selectionIndex) external {
        require(msg.sender == games[gameId].player, "Mines: you can do this only in games you started!");
        bool success = nextGameId % 3 != 0;
        if (success) {
            games[gameId].revealedNum ++;
        }
        emit Revealed(gameId, selectionIndex, success);
    }

    function cashout(uint256 gameId) external {
        require(msg.sender == games[gameId].player, "Mines: you can do this only in games you started!");
        uint256 prize = games[gameId].wager * 100 * 25 / (25 - games[gameId].revealedNum) / 100;
        emit Cashout(gameId, prize);
    }

    function collapse() external {
        selfdestruct(payable(msg.sender));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMines {
    event GameStarted(uint256 indexed gameId);
    event Revealed(uint256 indexed gameId, uint8 selectionIndex, bool success);
    event Cashout(uint256 indexed gameId, uint256 amount);

    function startAndReveal(uint8 minesNum, uint8 selectionIndex, address tokenAddress) external payable;

    function reveal(uint256 gameId, uint8 selectionIndex) external;

    function cashout(uint256 gameId) external;
}