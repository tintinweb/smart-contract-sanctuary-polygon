/**
 *Submitted for verification at polygonscan.com on 2023-05-20
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: contracts/Coinflip.sol


pragma solidity ^0.8.4;


interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract Flipcoin {
    using SafeMath for uint256;

    address private _owner;
    uint256 private _minBetAmount = 1000; // Минимальная сумма ставки
    uint256 private _maxBetAmount = 100000; // Максимальная сумма ставки
    uint8 private _tokenDecimals; // Количество десятичных знаков токена AMBER
    IERC20 private _amberToken;
    mapping(uint256 => mapping(address => uint256)) private _bets; // Ячейки ставок
    uint256 private _totalPot;
    uint256 private _lobbyCounter;
    address private _player1;
    address private _player2;

    event BetPlaced(address indexed player, uint256 betAmount, uint256 lobbyId);
    event BetClosed(address indexed winner, uint256 winningAmount, uint256 lobbyId);
    event FundsWithdrawn(address indexed recipient, uint256 amount);

    constructor() {
        _owner = msg.sender;
        _amberToken = IERC20(0xf32d5D5FA5d2545071570c0EEf6E2C65A4c7e5c5); // Замените на адрес AMBER токена на Mumbai сети
        _tokenDecimals = 18; // Установите правильное количество десятичных знаков для токена AMBER
    }

    function createLobby(uint256 betAmount) external gasLimit(200000) {
        require(betAmount >= _minBetAmount && betAmount <= _maxBetAmount, "Invalid bet amount");
        require(_amberToken.balanceOf(msg.sender) >= betAmount * (10**_tokenDecimals), "Insufficient AMBER token balance");

        uint256 tokenAmount = betAmount * (10**_tokenDecimals);
        uint256 feeAmount = (betAmount * 10) / 100; // 10% fee

        require(_amberToken.transferFrom(msg.sender, address(this), tokenAmount), "Failed to transfer AMBER tokens");

        _player1 = msg.sender;
        _bets[_lobbyCounter][_player1] = tokenAmount - feeAmount;
        _totalPot = _totalPot.add(tokenAmount - feeAmount);

        emit BetPlaced(msg.sender, betAmount, _lobbyCounter);

        _lobbyCounter++;
    }

    function joinLobby(uint256 lobbyId, uint256 betAmount) external gasLimit(200000) {
        require(_bets[lobbyId][_player2] == 0, "The lobby is already full");
        require(_amberToken.balanceOf(msg.sender) >= betAmount * (10**_tokenDecimals), "Insufficient AMBER token balance");
        require(betAmount >= _minBetAmount, "Bet amount must be greater than or equal to the minimum bet");
        require(msg.sender != _player1, "You cannot join your own lobby");

        uint256 tokenAmount = betAmount * (10**_tokenDecimals);
        uint256 feeAmount = (betAmount * 10) / 100; // 10% fee

        require(_amberToken.transferFrom(msg.sender, address(this), tokenAmount), "Failed to transfer AMBER tokens");

        _bets[lobbyId][_player2] = tokenAmount - feeAmount;
        _totalPot = _totalPot.add(tokenAmount - feeAmount);
        _player2 = msg.sender;

        emit BetPlaced(msg.sender, betAmount, lobbyId);

        endLobby(lobbyId);
    }

    function endLobby(uint256 lobbyId) internal {
        require(_player1 != address(0) && _player2 != address(0), "No players in the lobby");

        address winner = (_bets[lobbyId][_player1] > _bets[lobbyId][_player2]) ? _player1 : _player2;
        uint256 winningAmount = (_totalPot * 80) / 100;

        require(_amberToken.transfer(winner, winningAmount), "Failed to transfer AMBER tokens to the winner");
        _totalPot = _totalPot.sub(winningAmount);

        emit BetClosed(winner, winningAmount / (10**_tokenDecimals), lobbyId);

        _clearLobby(lobbyId);
    }

    function _clearLobby(uint256 lobbyId) internal {
        delete _bets[lobbyId][_player1];
        delete _bets[lobbyId][_player2];
        _player1 = address(0);
        _player2 = address(0);
    }

    function withdrawFunds() external onlyOwner gasLimit(50000) {
        require(_amberToken.transfer(_owner, _amberToken.balanceOf(address(this))), "Failed to withdraw AMBER tokens");
        emit FundsWithdrawn(_owner, _amberToken.balanceOf(address(this)));
    }

    function getLobbyCount() external view returns (uint256) {
        return _lobbyCounter;
    }

    function getLobbyBet(uint256 lobbyId) external view returns (uint256) {
        return _bets[lobbyId][_player1];
    }

    function getMinBetAmount() external view returns (uint256) {
        return _minBetAmount;
    }

    function getMaxBetAmount() external view returns (uint256) {
        return _maxBetAmount;
    }

    function getContractOwner() external view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only the contract owner can call this function");
        _;
    }

    modifier gasLimit(uint256 gasAmount) {
        require(gasleft() >= gasAmount, "Insufficient gas");
        _;
    }
}