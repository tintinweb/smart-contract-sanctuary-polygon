/**
 *Submitted for verification at polygonscan.com on 2023-05-20
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: contracts/BettingContract.sol


pragma solidity 0.8.4;



contract BettingContract {
    using SafeMath for uint256;

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

    IERC20 private _amberToken;
    address private _amberTokenAddress = 0xf32d5D5FA5d2545071570c0EEf6E2C65A4c7e5c5;

    constructor() {
        _owner = msg.sender;
        _lobbyCount = 0;
        _amberToken = IERC20(_amberTokenAddress);
    }

    function createLobby() external payable {
        require(msg.value > 0, "Invalid bet amount");
        _lobbyCount++;
        _lobbies[_lobbyCount] = Lobby(_lobbyCount, msg.value, msg.sender, address(0), false);
    }

    function placeBet(uint256 lobbyId, uint256 amount) external {
        require(lobbyId <= _lobbyCount, "Invalid lobby ID");
        require(!_closedLobbies[lobbyId], "Lobby is closed");
        require(amount > 0, "Invalid bet amount");
        require(_lobbies[lobbyId].player1 != address(0), "Lobby does not exist or is closed");

        _amberToken.transferFrom(msg.sender, address(this), amount);
        _lobbies[lobbyId].betAmount = _lobbies[lobbyId].betAmount.add(amount);

        if (_lobbies[lobbyId].player2 == address(0)) {
            _lobbies[lobbyId].player2 = msg.sender;
            _lobbies[lobbyId].closed = true;
        }
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
            uint256 contractBalance = _amberToken.balanceOf(address(this));

            if (randomNumber >= 2 && randomNumber <= 48) {
                winner = _lobbies[lobbyId].player1;
                winnerAmount = _lobbies[lobbyId].betAmount.mul(80).div(100);
            } else if (randomNumber >= 49 && randomNumber <= 95) {
                winner = _lobbies[lobbyId].player2;
                winnerAmount = _lobbies[lobbyId].betAmount.mul(80).div(100);
            } else {
                winner = _owner;
                winnerAmount = contractBalance.mul(90).div(100);
                _amberToken.transfer(address(0), contractBalance.sub(winnerAmount));
            }

            uint256 creatorAmount = contractBalance.sub(winnerAmount);
            _closedLobbies[lobbyId] = true;

            if (winner != _owner) {
                _amberToken.transfer(winner, winnerAmount);
            }

            if (creatorAmount > 0) {
                _amberToken.transfer(_owner, creatorAmount);
            }
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

        uint256 contractBalance = _amberToken.balanceOf(address(this));
        require(contractBalance > 0, "Contract balance is zero");

        _amberToken.transfer(_owner, contractBalance);
    }
}