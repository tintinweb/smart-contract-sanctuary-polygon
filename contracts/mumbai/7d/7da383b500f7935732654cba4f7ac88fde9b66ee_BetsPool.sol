/**
 *Submitted for verification at polygonscan.com on 2022-11-18
*/

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

// File: contracts/contracts/interfaces/IBetsPool.sol

pragma solidity >0.8.16;

interface IBetsPool {
    struct PendingBet {
        address from;
        uint256 price;
        bool favour;
    }
    struct ActiveBet {
        address favourWallet;
        address againstWallet;
        uint256 price;
    }

    event BetInitiated(
        uint256 indexed _betId,
        uint8 indexed sportId,
        string indexed bestslug
    );

    event BetCreated(
        uint256 indexed _betId,
        uint8 indexed sportId,
        string indexed bestslug
    );

    event BetResolved(
        uint256 indexed _betId,
        uint8 indexed sportId,
        string indexed bestslug
    );

    function allActiveBets(
        string memory _sport,
        string memory _match,
        string memory _team,
        string memory _player,
        string memory _event,
        string memory _timeframe
    ) external view returns (ActiveBet[] memory);

    function addBet(
        string memory _sport,
        string memory _match,
        string memory _team,
        string memory _player,
        string memory _event,
        string memory _timeframe,
        address sender,
        uint256 _price,
        bool _favour
    ) external;

    function trigger(
        string memory _sport,
        string memory _match,
        string memory _team,
        string memory _player,
        string memory _event,
        string memory _timeframe
    ) external;
}

// File: contracts/contracts/BetsPool.sol

pragma solidity >0.8.16;




contract BetsPool is Context, IBetsPool {
    IERC20 token;
    address _aggregator;

    mapping(string => mapping(string => mapping(string => mapping(string => mapping(string => mapping(string => PendingBet[])))))) public pendingBets;
    mapping(string => mapping(string => mapping(string => mapping(string => mapping(string => mapping(string => ActiveBet[])))))) public activeBets;

    mapping(address => bool) admins;

    modifier onlyAdmins() {
        require(admins[msg.sender], "Sender not admin");
        _;
    }

    constructor(IERC20 _token) {
        token = _token;
        admins[msg.sender] = true;
    }

    function allActiveBets(
        string memory _sport,
        string memory _match,
        string memory _team,
        string memory _player,
        string memory _event,
        string memory _timeframe
    ) external view override returns (ActiveBet[] memory) {
        return activeBets[_sport][_match][_team][_player][_event][_timeframe];
    }

    function addBet(
        string memory _sport,
        string memory _match,
        string memory _team,
        string memory _player,
        string memory _event,
        string memory _timeframe,
        address sender,
        uint256 _price,
        bool _favour
    ) external override onlyAdmins {
        bool success = token.transferFrom(sender, address(this), _price);
        require(success, "Please approve the bet amount");

        token.approve(_aggregator, token.balanceOf(address(this)));

        PendingBet[] memory _pendingBets = pendingBets[_sport][_match][_team][_player][_event][_timeframe];

        if (_pendingBets.length == 0) {
            pendingBets[_sport][_match][_team][_player][_event][_timeframe].push(PendingBet({from: sender, price: _price, favour: _favour}));
        } else {
            uint256 i;
            for (i = 0; i < _pendingBets.length; i++) {
                if (_pendingBets[i].price == _price && _pendingBets[i].favour != _favour) {
                    require(_pendingBets[i].from != sender, "One user cannot place opposite bets");
                    activeBets[_sport][_match][_team][_player][_event][_timeframe].push(
                        ActiveBet({favourWallet: _favour ? sender : _pendingBets[i].from, againstWallet: _favour ? _pendingBets[i].from : sender, price: _price * 2})
                    );
                    break;
                }
            }
            if (i < _pendingBets.length) {
                pendingBets[_sport][_match][_team][_player][_event][_timeframe][i] = _pendingBets[_pendingBets.length - 1];
                pendingBets[_sport][_match][_team][_player][_event][_timeframe].pop();
            }
        }
    }

    function trigger(
        string memory _sport,
        string memory _match,
        string memory _team,
        string memory _player,
        string memory _event,
        string memory _timeframe
    ) external override onlyAdmins {
        delete activeBets[_sport][_match][_team][_player][_event][_timeframe];
    }

    function setAggregator(address aggregator) external onlyAdmins {
        _aggregator = aggregator;
    }

    function addAdmin(address admin) external onlyAdmins {
        admins[admin] = true;
    }

    function removeAdmin(address admin) external onlyAdmins {
        admins[admin] = false;
    }
}