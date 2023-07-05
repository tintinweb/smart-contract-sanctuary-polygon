/**
 *Submitted for verification at polygonscan.com on 2023-07-04
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: new.sol


pragma solidity ^0.8.7;


contract MustasheRPSGame {
    struct Game {
        address creator;
        address opponent;
        uint256 betAmount;
        mapping(address => uint256) wins;
        mapping(address => bytes32) choices;
        uint256 round;
        bool gameEnded;
        bool forcedEnd;
    }

    mapping(uint256 => Game) public games;
    uint256 public gameId;

    IERC20 public token;

    event ChoicesRevealed(
        uint256 indexed gameId,
        address indexed creator,
        address indexed opponent,
        bytes32 choice1,
        bytes32 choice2
    );

    constructor(IERC20 _token) {
        token = _token;
        gameId = 0;
    }

    function createGame(uint256 _betAmount) external {
        require(_betAmount > 0, "Invalid bet amount");
        gameId++;
        Game storage game = games[gameId];
        game.creator = msg.sender;
        game.betAmount = _betAmount * 10**18;
        token.transferFrom(msg.sender, address(this), game.betAmount);
    }

    function joinGame(uint256 _gameId) external {
        Game storage game = games[_gameId];
        require(game.creator != address(0), "Game does not exist");
        require(game.opponent == address(0), "Game is already full!");

        if (game.creator != msg.sender) {
            require(
                token.balanceOf(msg.sender) >= game.betAmount,
                "Insufficient balance"
            );
            token.transferFrom(msg.sender, address(this), game.betAmount);
        }

        game.opponent = msg.sender;
    }

    function play(uint256 _gameId, bytes32 _choiceHash) external {
        Game storage game = games[_gameId];
        require(!game.gameEnded, "Game has already ended");
        require(
            game.creator == msg.sender || game.opponent == msg.sender,
            "You are not part of the game"
        );
        require(
            game.choices[msg.sender] == bytes32(0),
            "You have already played"
        );

        game.choices[msg.sender] = _choiceHash;

        if (
            game.choices[game.creator] != bytes32(0) &&
            game.choices[game.opponent] != bytes32(0)
        ) {
            emit ChoicesRevealed(
                _gameId,
                game.creator,
                game.opponent,
                game.choices[game.creator],
                game.choices[game.opponent]
            );
            revealChoices(_gameId);
        }
    }

    function revealChoices(uint256 _gameId) private {
        Game storage game = games[_gameId];
        game.round++;
        address creator = game.creator;
        address opponent = game.opponent;
        bytes32 choice1 = game.choices[creator];
        bytes32 choice2 = game.choices[opponent];
        game.choices[creator] = bytes32(0);
        game.choices[opponent] = bytes32(0);

        if (choice1 == choice2) {
            // It's a tie, play another round
            if (game.round >= 3) {
                endGameWithTie(_gameId);
            }
        } else {
            // Calculate the winner
            if (
                (choice1 == bytes32(uint256(keccak256(bytes("rock")))) &&
                    choice2 == bytes32(uint256(keccak256(bytes("scissors"))))) ||
                (choice1 == bytes32(uint256(keccak256(bytes("scissors")))) &&
                    choice2 == bytes32(uint256(keccak256(bytes("paper"))))) ||
                (choice1 == bytes32(uint256(keccak256(bytes("paper")))) &&
                    choice2 == bytes32(uint256(keccak256(bytes("rock")))))
            ) {
                game.wins[creator]++;
            } else {
                game.wins[opponent]++;
            }

            if (game.wins[creator] == 3 || game.wins[opponent] == 3) {
                endGame(_gameId);
            }
        }
    }

    function endGameWithTie(uint256 _gameId) private {
        Game storage game = games[_gameId];
        game.choices[game.creator] = bytes32(0);
        game.choices[game.opponent] = bytes32(0);
        game.round = 0;
    }

    function endGame(uint256 _gameId) private {
        Game storage game = games[_gameId];
        game.gameEnded = true;
        uint256 totalAmount = game.betAmount * 2;
        uint256 reward = (totalAmount * 95) / 100;
        uint256 fee = totalAmount - reward;
        address winner;
        address loser;

        if (game.wins[game.creator] > game.wins[game.opponent]) {
            winner = game.creator;
            loser = game.opponent;
        } else {
            winner = game.opponent;
            loser = game.creator;
        }

        token.transfer(winner, reward * 10**18);
        token.transfer(address(this), fee * 10**18);
    }

    function forceEndGame(uint256 _gameId) external {
        Game storage game = games[_gameId];
        require(
            game.creator == msg.sender,
            "Only the creator can force end the game"
        );
        require(!game.gameEnded && !game.forcedEnd, "Game has already ended");

        game.gameEnded = true;
    }

    function getGameStatus(uint256 _gameId)
        external
        view
        returns (
            address,
            address,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        Game storage game = games[_gameId];
        return (
            game.creator,
            game.opponent,
            game.betAmount / 10**18,
            game.wins[game.creator],
            game.wins[game.opponent],
            game.round
        );
    }

    function getActiveGames()
        external
        view
        returns (
            uint256[] memory,
            address[] memory,
            address[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        uint256 activeGamesCount = 0;

        for (uint256 i = 1; i <= gameId; i++) {
            Game storage game = games[i];
            if (
                (game.opponent != address(0) || game.creator != address(0)) &&
                !game.gameEnded &&
                !game.forcedEnd
            ) {
                activeGamesCount++;
            }
        }

        uint256[] memory gameIds = new uint256[](activeGamesCount);
        address[] memory creators = new address[](activeGamesCount);
        address[] memory opponents = new address[](activeGamesCount);
        uint256[] memory betAmounts = new uint256[](activeGamesCount);
        uint256[] memory wins1 = new uint256[](activeGamesCount);
        uint256[] memory wins2 = new uint256[](activeGamesCount);

        activeGamesCount = 0;

        for (uint256 i = 1; i <= gameId; i++) {
            Game storage game = games[i];
            if (
                (game.opponent != address(0) || game.creator != address(0)) &&
                !game.gameEnded &&
                !game.forcedEnd
            ) {
                gameIds[activeGamesCount] = i;
                creators[activeGamesCount] = game.creator;
                opponents[activeGamesCount] = game.opponent;
                betAmounts[activeGamesCount] = game.betAmount / 10**18;
                wins1[activeGamesCount] = game.wins[game.creator];
                wins2[activeGamesCount] = game.wins[game.opponent];
                activeGamesCount++;
            }
        }

        return (
            gameIds,
            creators,
            opponents,
            betAmounts,
            wins1,
            wins2
        );
    }

    function getEndedGames()
        external
        view
        returns (
            uint256[] memory,
            address[] memory,
            address[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        uint256 endedGamesCount = 0;

        for (uint256 i = 1; i <= gameId; i++) {
            Game storage game = games[i];
            if (game.gameEnded || game.forcedEnd) {
                endedGamesCount++;
            }
        }

        uint256[] memory gameIds = new uint256[](endedGamesCount);
        address[] memory creators = new address[](endedGamesCount);
        address[] memory opponents = new address[](endedGamesCount);
        uint256[] memory betAmounts = new uint256[](endedGamesCount);
        uint256[] memory wins1 = new uint256[](endedGamesCount);
        uint256[] memory wins2 = new uint256[](endedGamesCount);

        endedGamesCount = 0;

        for (uint256 i = 1; i <= gameId; i++) {
            Game storage game = games[i];
            if (game.gameEnded || game.forcedEnd) {
                gameIds[endedGamesCount] = i;
                creators[endedGamesCount] = game.creator;
                opponents[endedGamesCount] = game.opponent;
                betAmounts[endedGamesCount] = game.betAmount / 10**18;
                wins1[endedGamesCount] = game.wins[game.creator];
                wins2[endedGamesCount] = game.wins[game.opponent];
                endedGamesCount++;
            }
        }

        return (
            gameIds,
            creators,
            opponents,
            betAmounts,
            wins1,
            wins2
        );
    }

    function withdrawTokens(uint256 _amount) external {
        require(
            _amount > 0,
            "Invalid amount"
        );
        require(
            token.balanceOf(address(this)) >= _amount * 10**18,
            "Insufficient contract balance"
        );
        token.transfer(msg.sender, _amount * 10**18);
    }
}