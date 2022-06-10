/**
 *Submitted for verification at polygonscan.com on 2022-06-10
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: diceUsdc.sol


pragma solidity ^0.8.7;




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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

interface IVAULT {
    function receiveETH() external payable returns (bool);

    function transfer(
        address _token,
        address _to,
        uint256 _amount
    ) external returns (bool);
}

interface IRAND {
    function getRandomNumber(address gameAddress)
        external
        returns (bytes32 requestId);
}

interface IMEMBER {
    function addScore(uint256 score, address account)
        external
        returns (uint256);
}

abstract contract Ownable is Context {
    address private _owner;
    uint256 private _certifieds;

    mapping(address => bool) private _isCertified;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event CertifiedAdded(address indexed added);
    event CertifiedRemoved(address indexed removed);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Return True if address is Certified.
     */
    function isCertified(address who) public view returns (bool) {
        return _isCertified[who];
    }

    /**
     * @dev Return total number of Certified.
     */
    function certifieds() public view returns (uint256) {
        return _certifieds;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Throws if called by any account other than the certified.
     */
    modifier onlyCertified() {
        require(
            _isCertified[_msgSender()] || owner() == _msgSender(),
            "Ownable: caller is not certified"
        );
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev Add a new account (`user`) as a certified.
     * Can only be called by the current owner.
     */
    function addCertified(address user) public onlyOwner {
        require(user != address(0), "Ownable: new user is the zero address");
        require(!_isCertified[user], "Ownable: this address is certified");
        emit CertifiedAdded(user);
        _isCertified[user] = true;
        _certifieds += 1;
    }

    /**
     * @dev Remove a certified (`user`).
     * Can only be called by the current owner.
     */
    function removeCertified(address user) public onlyOwner {
        require(_isCertified[user], "Ownable: this address is not certified");
        emit CertifiedRemoved(user);
        _isCertified[user] = false;
        _certifieds -= 1;
    }
}

contract GameBase is Ownable {
    using SafeMath for uint256;

    struct User {
        uint256 bets;
        uint256 wager;
        uint256 bonus;
        uint256 invested;
        uint256 profit;
    }

    struct Bet {
        uint256 target;
        uint256 result;
        uint256 wager;
        uint256 bonus;
        uint168 blockNum;
        address player;
        bool isHigher;
        bool isSettled;
    }

    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;

    uint256 internal _minBetAmount = 10**6;
    uint256 internal _maxBetAmount = 9999 * 10**6;
    uint256 internal _houseEdge = 100;
    uint256 internal _rakeRate = 50;
    uint256 internal _scoreRate = 2000;

    uint256 internal _totalSupply;
    uint256 internal _totalInvested;
    uint256 internal _totalDivested;

    bool internal _gameIsLive = false;

    IVAULT internal _vault;
    IRAND internal _rand;
    IMEMBER internal _member;
    IERC20 internal _usdc;

    mapping(bytes32 => uint256) internal _betMap;
    mapping(address => uint256) internal _balances;
    mapping(address => User) internal _users;

    Bet[] internal bets;

    // Events
    event BetPlaced(
        uint256 indexed betId,
        address indexed player,
        uint256 target,
        bool isHigher,
        uint256 wager
    );

    event BetSettled(
        uint256 indexed betId,
        address indexed player,
        uint256 target,
        bool isHigher,
        uint256 result,
        uint256 wager,
        uint256 bonus
    );

    event BetRefunded(
        uint256 indexed betId,
        address indexed player,
        uint256 amount
    );

    event Invest(address indexed user, uint256 fund, uint256 liquidity);

    event Divest(address indexed user, uint256 liquidity, uint256 fund);

    event Transfer(
        address indexed sender,
        address indexed recipient,
        uint256 amount
    );

    modifier onlyRand() {
        require(
            address(_rand) == _msgSender(),
            "ERR: caller is not the rand contract"
        );
        _;
    }

    modifier onlyLive() {
        require(_gameIsLive, "ERR: game is not live");
        _;
    }

    // View
    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function totalInvested() external view returns (uint256) {
        return _totalInvested;
    }

    function totalDivested() external view returns (uint256) {
        return _totalDivested;
    }

    function totalBets() public view returns (uint256) {
        return bets.length;
    }

    function gameInfo() public view returns (uint256[5] memory) {
        return [
            bets.length,
            _totalSupply,
            _totalInvested,
            _totalDivested,
            _usdc.balanceOf(address(_vault))
        ];
    }

    function betDetail(uint256 _betId) public view returns (Bet memory) {
        return bets[_betId];
    }

    function userDetail(address _user) public view returns (User memory) {
        return _users[_user];
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    // Setter

    function setMinBetAmount(uint256 _min) external onlyOwner {
        _minBetAmount = _min;
    }

    function setMaxBetAmount(uint256 _max) external onlyOwner {
        _maxBetAmount = _max;
    }

    function setHouseEdgeBP(uint256 _value) external onlyOwner {
        _houseEdge = _value;
    }

    function setRakeBP(uint256 _value) external onlyOwner {
        _rakeRate = _value;
    }

    function setScoreRate(uint256 _value) external onlyOwner {
        _scoreRate = _value;
    }

    function toggleGameIsLive() external onlyOwner {
        _gameIsLive = !_gameIsLive;
    }

    function setGameVault(address _contract) external onlyOwner {
        _vault = IVAULT(_contract);
    }

    function setRandomNumber(address _contract) external onlyOwner {
        _rand = IRAND(_contract);
    }

    function setMembership(address _contract) external onlyOwner {
        _member = IMEMBER(_contract);
    }

    function setUSDC(address _contract) external onlyOwner {
        _usdc = IERC20(_contract);
    }

    // Converters
    function betRake(uint256 _wager) internal view returns (uint256 rake) {
        uint256 profit = (_wager.mul(_houseEdge)).div(10000);
        rake = (profit.mul(_rakeRate)).div(100);
        return rake;
    }

    function betBonus(uint256 _wager, uint256 _target)
        internal
        view
        returns (uint256 bonus)
    {
        uint256 amount = (_wager.mul(uint256(10000).sub(_houseEdge))).div(
            10000
        );
        bonus = (amount.mul(1000000)).div(_target);
        return bonus;
    }

    function betScore(uint256 _wager) internal view returns (uint256 score) {
        score = (_wager.mul(_scoreRate)).div(1e18);
        return score;
    }

    function fundToLiquidity(uint256 _fund)
        internal
        view
        returns (uint256 liquidity)
    {
        uint256 balance = _usdc.balanceOf(address(_vault));
        liquidity = (_fund.mul(_totalSupply)).div(balance);
        return liquidity;
    }

    function liquidityToFund(uint256 _liquidity)
        internal
        view
        returns (uint256 fund)
    {
        uint256 balance = _usdc.balanceOf(address(_vault));
        fund = (_liquidity.mul(balance)).div(_totalSupply);
        return fund;
    }

    function _mint(address account, uint256 amount) internal {
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        _balances[account] = _balances[account].sub(
            amount,
            "ERROR: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
}

contract Game is ReentrancyGuard, GameBase {
    constructor(
        address vault,
        address rand,
        address member
    ) {
        _name = "USDC DICE - Crystal.Network";
        _symbol = "LP";
        _decimals = 18;
        _totalSupply = 0;
        _vault = IVAULT(vault);
        _rand = IRAND(rand);
        _member = IMEMBER(member);
        _usdc = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    }

    function initialze(uint256 _fund) external onlyOwner {
        require(_totalSupply == uint256(0), "Can not initialze");

        _totalInvested += uint256(_fund);
        _receiveToken(_msgSender(), uint256(_fund));
        _addUserInvested(_msgSender(), _fund);
        _mint(address(this), uint256(1));
        _mint(_msgSender(), _fund);
        emit Invest(_msgSender(), _fund, _fund);

        _gameIsLive = true;
    }

    function clear(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        if (_token == address(0)) {
            require(_transferEth(_to, _amount));
        } else {
            require(_transferToken(_token, _to, _amount));
        }
        return true;
    }

    function placeBet(
        uint256 _target,
        bool _higher,
        uint256 _wager
    ) public onlyLive nonReentrant {
        require(
            _usdc.transferFrom(_msgSender(), address(this), _wager),
            "Token transfer failed"
        );

        require(
            _wager >= _minBetAmount && _wager <= _maxBetAmount,
            "Bet wager not within range"
        );
        require(_target > 0 && _target < 999999, "Bet mask not in range");

        bytes32 requestId = _rand.getRandomNumber(address(this));
        _betMap[requestId] = bets.length;

        bets.push(
            Bet({
                target: uint256(_target),
                result: uint256(0),
                wager: uint256(_wager),
                bonus: uint256(0),
                blockNum: uint168(block.number),
                player: _msgSender(),
                isHigher: _higher,
                isSettled: false
            })
        );

        emit BetPlaced(
            _betMap[requestId],
            _msgSender(),
            _target,
            _higher,
            _wager
        );

        _updateUserBet(_msgSender(), _wager);
        _addScore(_msgSender(), betScore(_wager));
    }

    function settleRand(bytes32 requestId, uint256 randomness)
        public
        nonReentrant
        onlyRand
    {
        uint256 betId = _betMap[requestId];
        Bet storage bet = bets[betId];
        uint256 wager = bet.wager;
        require(wager > 0, "Bet does not exist");
        require(bet.isSettled == false, "Bet is settled already");
        require(
            block.number < bet.blockNum + 50000,
            "Bet has expired, please request refund"
        );

        uint256 target = bet.target;
        bool isHigher = bet.isHigher;
        address player = bet.player;

        bet.isSettled = true;

        uint256 result = 999999 - (randomness % 1000000);
        uint256 bonus = uint256(0);

        if (!isHigher && result < target) {
            bonus = betBonus(wager, target);
        } else if (isHigher && result > target) {
            bonus = betBonus(wager, 999999 - target);
        }

        uint256 balance = _usdc.balanceOf(address(_vault));
        if (bonus > balance / 2) {
            result = isHigher
                ? result % target
                : (result % (999999 - target)) + target;
            bonus = uint256(0);
        }

        bet.result = result;
        bet.bonus = bonus;

        emit BetSettled(
            betId,
            player,
            target,
            isHigher,
            bet.result,
            wager,
            bet.bonus
        );

        _usdc.transfer(address(_vault), wager);
        _updateUserBonus(player, bonus);
        _sendToken(player, bonus);
        _sendToken(owner(), betRake(wager));
    }

    function refundBet(uint256 betId) external onlyLive nonReentrant {
        Bet storage bet = bets[betId];
        uint256 wager = bet.wager;

        require(wager > 0, "Bet does not exist");
        require(!bet.isSettled, "Bet is settled already");
        require(
            block.number > bet.blockNum + 50000,
            "Bet has not expired, please wait"
        );

        bet.isSettled = true;
        bet.bonus = wager;

        _usdc.transfer(address(_vault), wager);
        _sendToken(bet.player, bet.bonus);
        emit BetRefunded(betId, bet.player, wager);
    }

    function invest(uint256 _fund) public payable onlyLive nonReentrant {
        uint256 _liquidity = fundToLiquidity(_fund);
        _receiveToken(_msgSender(), _fund);
        _totalInvested += _fund;
        _addUserInvested(_msgSender(), _fund);
        _mint(_msgSender(), _liquidity);

        emit Invest(_msgSender(), _fund, _liquidity);
    }

    function divest(uint256 _liquidity) public onlyLive nonReentrant {
        require(_liquidity > 0, "Need positive liquidity amount");
        uint256 _fund = liquidityToFund(_liquidity);
        uint256 _invested = _subUserInvested(_msgSender(), _liquidity);
        _totalDivested += _fund;
        if (_fund > _invested) {
            _updateUserProfit(_msgSender(), _fund - _invested);
        }
        _burn(_msgSender(), _liquidity);
        _sendToken(_msgSender(), _fund);
        emit Divest(_msgSender(), _liquidity, _fund);
    }

    function _transferEth(address _to, uint256 _amount)
        internal
        returns (bool)
    {
        payable(_to).transfer(_amount);
        return true;
    }

    function _transferToken(
        address _token,
        address _to,
        uint256 _amount
    ) internal returns (bool) {
        IERC20 token = IERC20(_token);
        return token.transfer(_to, _amount);
    }

    function _updateUserBet(address _user, uint256 _wager) internal {
        User storage user = _users[_user];
        user.bets += 1;
        user.wager += _wager;
    }

    function _updateUserBonus(address _user, uint256 _bonus) internal {
        User storage user = _users[_user];
        user.bonus += _bonus;
    }

    function _updateUserProfit(address _user, uint256 _profit) internal {
        User storage user = _users[_user];
        user.profit += _profit;
    }

    function _addUserInvested(address _user, uint256 _invested) internal {
        User storage user = _users[_user];
        user.invested += _invested;
    }

    function _subUserInvested(address _user, uint256 _liquidity)
        internal
        returns (uint256)
    {
        User storage user = _users[_user];
        require(
            _balances[_user] > 0 && _balances[_user] >= _liquidity,
            "Invalid liquidity amount"
        );
        uint256 _invested = (user.invested * _liquidity) / _balances[_user];
        user.invested -= _invested;
        return _invested;
    }

    function _addScore(address _user, uint256 _value) internal {
        _member.addScore(_value, _user);
    }

    function _receiveToken(address _user, uint256 _value) internal {
        require(
            _usdc.transferFrom(_user, address(_vault), _value),
            "Receive Token Error"
        );
    }

    function _sendToken(address _user, uint256 _value) internal {
        if (_value > uint256(0)) {
            require(
                _vault.transfer(address(_usdc), _user, _value),
                "Send Token Error"
            );
        }
    }
}