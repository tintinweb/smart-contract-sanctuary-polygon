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

// File: contracts/Betting.sol


pragma solidity 0.8.4;



contract BettingContract {
    using SafeMath for uint256;

    address private _owner;
    IERC20 private _amberToken;
    uint256 private _tokenDecimals;
    mapping(uint256 => uint256) private _lobbies;
    uint256 private _currentLobby;
    uint256 private _feePercentage;
    uint256 private _creatorPercentage;
    uint256 private _deadAddressPercentage;
    uint256 private _winnerPercentage;

    event LobbyCreated(uint256 lobbyNumber, uint256 pool);
    event BetPlaced(uint256 lobbyNumber, address player, uint256 amount);
    event LobbyClosed(uint256 lobbyNumber, uint256 winningNumber, address winner);

    constructor() {
        _owner = msg.sender;
        _amberToken = IERC20(0xf32d5D5FA5d2545071570c0EEf6E2C65A4c7e5c5); // Замените на адрес AMBER токена на Mumbai сети
        _tokenDecimals = 18;
        _currentLobby = 0;
        _feePercentage = 2;
        _creatorPercentage = 5;
        _deadAddressPercentage = 15;
        _winnerPercentage = 80;
    }

    function createLobby(uint256 pool) external {
        require(_lobbies[_currentLobby] == 0, "Previous lobby is still active");

        _lobbies[_currentLobby] = pool;
        emit LobbyCreated(_currentLobby, pool);
        _currentLobby++;
    }

    function placeBet(uint256 lobbyNumber, uint256 amount) external {
        require(_lobbies[lobbyNumber] > 0, "Invalid lobby");
        require(amount > 0, "Invalid amount");

        uint256 feeAmount = amount.mul(_feePercentage).div(100);
        uint256 betAmount = amount.sub(feeAmount);

        require(_amberToken.balanceOf(msg.sender) >= amount, "Insufficient balance");
        require(_amberToken.allowance(msg.sender, address(this)) >= amount, "Insufficient allowance");

        _amberToken.transferFrom(msg.sender, address(this), amount);
        _amberToken.transferFrom(msg.sender, _owner, feeAmount);

        _lobbies[lobbyNumber] = _lobbies[lobbyNumber].add(betAmount);

        emit BetPlaced(lobbyNumber, msg.sender, amount);
    }

    function closeLobby(uint256 lobbyNumber) external {
        require(_lobbies[lobbyNumber] > 0, "Invalid lobby");
        require(_lobbies[lobbyNumber] < type(uint256).max, "Invalid lobby pool");

        uint256 winningNumber = generateRandomNumber(lobbyNumber);

        address winner;

        if (winningNumber == 0 || winningNumber == 100) {
            // Contract wins
            uint256 contractFee = _lobbies[lobbyNumber].mul(_winnerPercentage).div(100);
            uint256 creatorFee = _lobbies[lobbyNumber].mul(_creatorPercentage).div(100);

            _amberToken.transfer(address(0), contractFee);
            _amberToken.transfer(_owner, creatorFee);

            emit LobbyClosed(lobbyNumber, winningNumber, address(0));
        } else {
            // Player wins
            uint256 winnerFee = _lobbies[lobbyNumber].mul(_winnerPercentage).div(100);
            uint256 deadAddressFee = _lobbies[lobbyNumber].mul(_deadAddressPercentage).div(100);
            uint256 creatorFee = _lobbies[lobbyNumber].mul(_creatorPercentage).div(100);

            _amberToken.transfer(msg.sender, winnerFee);
            _amberToken.transfer(address(0), deadAddressFee);
            _amberToken.transfer(_owner, creatorFee);

            winner = msg.sender;

            emit LobbyClosed(lobbyNumber, winningNumber, winner);
        }

        _lobbies[lobbyNumber] = 0;
    }

    function generateRandomNumber(uint256 seed) private view returns (uint256) {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, seed)));
        return randomNumber % 101;
    }

    function withdrawTokens() external {
        require(msg.sender == _owner, "Only contract owner can withdraw tokens");

        uint256 contractBalance = _amberToken.balanceOf(address(this));
        _amberToken.transfer(_owner, contractBalance);
    }

    function getLobbyPool(uint256 lobbyNumber) external view returns (uint256) {
        return _lobbies[lobbyNumber];
    }

    function getCurrentLobby() external view returns (uint256) {
        return _currentLobby;
    }
}