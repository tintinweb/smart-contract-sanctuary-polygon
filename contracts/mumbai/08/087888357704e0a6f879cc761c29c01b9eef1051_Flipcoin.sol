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

// File: contracts/Betting.sol


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
    mapping(uint256 => MiniLobby) private _miniLobbies;
    mapping(uint256 => mapping(address => bytes)) private _lobbySignatures; // Подписи для закрытия лобби

    event BetPlaced(address indexed player, uint256 betAmount, uint256 lobbyId);
    event BetClosed(address indexed winner, uint256 winningAmount, uint256 lobbyId);
    event FundsWithdrawn(address indexed recipient, uint256 amount);

    struct MiniLobby {
        address creator;
        mapping(address => uint256) bets;
        uint256 totalPot;
        bool isClosed;
    }

    constructor() {
        _owner = msg.sender;
        _amberToken = IERC20(0xf32d5D5FA5d2545071570c0EEf6E2C65A4c7e5c5); // Замените на адрес AMBER токена на Mumbai сети
        _tokenDecimals = 18; // Установите правильное количество десятичных знаков для токена AMBER
    }

    function createEmptyLobby() external gasLimit(50000) {
        require(_miniLobbies[_lobbyCounter].creator == address(0), "Lobby already exists");
        _miniLobbies[_lobbyCounter].creator = msg.sender;
        emit BetPlaced(msg.sender, 0, _lobbyCounter);
        _lobbyCounter++;
    }

    function placeBet(uint256 lobbyId, uint256 betAmount) external gasLimit(200000) {
        require(lobbyId < _lobbyCounter, "Invalid lobby ID");
        require(!_miniLobbies[lobbyId].isClosed, "Lobby is closed");
        require(betAmount >= _minBetAmount && betAmount <= _maxBetAmount, "Invalid bet amount");
        require(_amberToken.balanceOf(msg.sender) >= betAmount * (10**_tokenDecimals), "Insufficient AMBER token balance");

        MiniLobby storage miniLobby = _miniLobbies[lobbyId];
        require(miniLobby.bets[msg.sender] == 0, "Already placed a bet");

        uint256 tokenAmount = betAmount * (10**_tokenDecimals);
        uint256 feeAmount = (betAmount * 10) / 100; // 10% fee

        require(_amberToken.transferFrom(msg.sender, address(this), tokenAmount), "Failed to transfer AMBER tokens");

        miniLobby.bets[msg.sender] = tokenAmount - feeAmount;
        miniLobby.totalPot = miniLobby.totalPot.add(tokenAmount - feeAmount);

        emit BetPlaced(msg.sender, betAmount, lobbyId);

        checkLobbyClosure(lobbyId);
    }

    function closeLobby(uint256 lobbyId, bytes memory signature) external gasLimit(50000) {
        require(lobbyId < _lobbyCounter, "Invalid lobby ID");
        require(_miniLobbies[lobbyId].creator == msg.sender, "Only lobby creator can close it");
        require(!_miniLobbies[lobbyId].isClosed, "Lobby is already closed");

        bytes32 messageHash = keccak256(abi.encodePacked(lobbyId, msg.sender));
        bytes32 signedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));

        require(recoverSigner(signedMessageHash, signature) == msg.sender, "Invalid signature");

        MiniLobby storage miniLobby = _miniLobbies[lobbyId];
        require(miniLobby.bets[msg.sender] != 0, "No bets placed in this lobby");

        miniLobby.isClosed = true;

        _lobbySignatures[lobbyId][msg.sender] = signature;

        emit BetClosed(msg.sender, 0, lobbyId);

        distributeWinnings(lobbyId);
    }

    function distributeWinnings(uint256 lobbyId) internal {
        MiniLobby storage miniLobby = _miniLobbies[lobbyId];
        require(miniLobby.isClosed, "Lobby is not closed yet");

        uint256 totalBets = miniLobby.totalPot;
        uint256 winningAmount = (totalBets * 80) / 100;
        address winner = address(0);

        for (uint256 i = 0; i < _lobbyCounter; i++) {
            address player = _miniLobbies[i].creator;
            if (_miniLobbies[i].isClosed && player != address(0) && miniLobby.bets[player] > miniLobby.bets[winner]) {
                winner = player;
            }
        }

        require(winner != address(0), "No winner found");

        require(_amberToken.transfer(winner, winningAmount), "Failed to transfer AMBER tokens to the winner");

        _totalPot = _totalPot.sub(winningAmount);

        emit BetClosed(winner, winningAmount / (10**_tokenDecimals), lobbyId);

        delete _miniLobbies[lobbyId];
    }

    function checkLobbyClosure(uint256 lobbyId) internal {
        MiniLobby storage miniLobby = _miniLobbies[lobbyId];
        if (miniLobby.isClosed) {
            distributeWinnings(lobbyId);
        } else {
            address creator = miniLobby.creator;
            if (creator != address(0) && miniLobby.bets[creator] != 0) {
                miniLobby.isClosed = true;
                emit BetClosed(creator, 0, lobbyId);
                distributeWinnings(lobbyId);
            }
        }
    }

    function withdrawFunds() external onlyOwner gasLimit(50000) {
        require(_amberToken.transfer(_owner, _amberToken.balanceOf(address(this))), "Failed to withdraw AMBER tokens");
        emit FundsWithdrawn(_owner, _amberToken.balanceOf(address(this)));
    }

    function getLobbyCount() external view returns (uint256) {
        return _lobbyCounter;
    }

    function getLobbyBet(uint256 lobbyId, address player) external view returns (uint256) {
        return _miniLobbies[lobbyId].bets[player];
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

    function recoverSigner(bytes32 messageHash, bytes memory signature) internal pure returns (address) {
        require(signature.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "Invalid signature recovery");

        return ecrecover(messageHash, v, r, s);
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