/**
 *Submitted for verification at polygonscan.com on 2022-12-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract RPSHomework {
    address[] public users;

    enum GameState {
        Commit,
        Reveal,
        Complete
    }

    enum GameChoice {
        None,
        Rock,
        Paper,
        Scissors
    }

    struct Game {
        GameState state;
        address winner;
        address[2] players; // maybe multiplayer support? :)
        bytes32[2] commitHashes;
        GameChoice[2] choices;
    }

    Game[] public games;

    event PlayerPerformedCommit (
        uint256 indexed gameIndex,
        address indexed player
    );

    event PlayerPerformedReveal (
        uint256 indexed gameIndex,
        address indexed player,
        GameChoice choice
    );

    event GameStarted (
        uint256 indexed gameIndex,
        address indexed initiator,
        address indexed challenger
    );

    event GameFinished (
        uint256 indexed gameIndex,
        address indexed winner
    );

    modifier validGameIndex(uint256 _gameIndex) {
        require(_gameIndex >= 0);
        require(_gameIndex < games.length);
        _;
    }

    modifier updateState(uint256 _gameIndex) {
        _;

        Game storage game = games[_gameIndex];

        for (uint256 i = 0; i < game.players.length; i++) {
            if (game.commitHashes[i] == bytes32(0)) {
                // at least one person did not commit => state = commit
                game.state = GameState.Commit;
                return;
            }

            if (game.choices[i] == GameChoice.None) {
                // at least one person did not make a choice => state = reveal
                game.state = GameState.Reveal;
                return;
            }
        }
        
        // all have their commits and choices => finish

        address winner;

        if(game.choices[0] == game.choices[1]) {
            winner = address(0x0);
        }
        else if(game.choices[0] == GameChoice.Rock) {
            if(game.choices[1] == GameChoice.Paper) {
                winner = game.players[1];
            }
            else if(game.choices[1] == GameChoice.Scissors) {
                winner = game.players[0];
            } else revert("invalid choice");
        }
        else if(game.choices[0] == GameChoice.Paper) {
            if(game.choices[1] == GameChoice.Rock) {
                winner = game.players[0];
            }
            else if(game.choices[1] == GameChoice.Scissors) {
                winner = game.players[1];
            } else revert("invalid choice");
        }
        else if(game.choices[0] == GameChoice.Scissors) {
            if(game.choices[1] == GameChoice.Rock) {
                winner = game.players[1];
            }
            else if(game.choices[1] == GameChoice.Paper) {
                winner = game.players[0];
            } else revert("invalid choice");
        }
        else revert("invalid choice");

        game.state = GameState.Complete;
        game.winner = winner;

        emit GameFinished(_gameIndex, winner);
    }

    function start(
        address _anotherPlayer
    ) public {
        require(_anotherPlayer != address(0x0));
        require(_anotherPlayer != msg.sender);

        Game memory game;

        game.state = GameState.Commit;
        game.players[0] = msg.sender;
        game.players[1] = _anotherPlayer;

        games.push(
            game
        );

        emit GameStarted(
            games.length - 1,
            msg.sender,
            _anotherPlayer
        );
    }

    function commit(
        uint256 _gameIndex,
        bytes32 _hash
    ) public validGameIndex(_gameIndex) {
        require(_hash.length > 1);

        Game storage game = games[_gameIndex];

        require(game.state == GameState.Commit);

        for (uint256 i = 0; i < game.players.length; i++) {
            if (game.players[i] == msg.sender) {
                game.commitHashes[i] = _hash;

                emit PlayerPerformedCommit(
                    _gameIndex,
                    msg.sender
                );

                return;
            }
        }

        revert("user is not a player");
    }

    function reveal(
        uint256 _gameIndex,
        GameChoice _choice,
        bytes32 _salt
    ) public validGameIndex(_gameIndex) updateState(_gameIndex) {
        require(_salt.length > 1);
        require(_choice == GameChoice.Rock 
            || _choice == GameChoice.Paper 
            || _choice == GameChoice.Scissors);

        Game storage game = games[_gameIndex];

        require(game.state == GameState.Reveal);

        for (uint256 i = 0; i < game.players.length; i++) {
            if (game.players[i] == msg.sender) {
                require(keccak256(abi.encodePacked(
                    msg.sender,
                    _gameIndex,
                    uint(_choice),
                    _salt
                )) == game.commitHashes[i]);

                game.choices[i] = _choice;

                emit PlayerPerformedReveal(
                    _gameIndex,
                    msg.sender,
                    _choice
                );

                return;
            }
        }

        revert("user is not a player");
    }
}