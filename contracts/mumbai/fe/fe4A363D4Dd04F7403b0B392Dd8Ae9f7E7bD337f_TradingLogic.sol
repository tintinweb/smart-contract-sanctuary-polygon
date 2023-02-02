// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./PairStorage.sol";
import "./TradingStorage.sol";



interface Pricefeed {
    function getPrice() external view returns (uint);
}

contract TradingLogic {
    PairStorage immutable pairStorage;
    TradingStorage immutable tradingStorage;

    constructor(PairStorage _pairstorage, TradingStorage _tradingStorage) {
        pairStorage = _pairstorage;
        tradingStorage = _tradingStorage;
    }

    enum OrderType {
        LIMIT_LONG,
        LIMIT_SHORT,
        MARKET_LONG,
        MARKET_SHORT
    }

    uint multiply = 1e8; // 8 decimals
    uint liquidationLimit = 90; // loss of 90% of collateral. The rest will be saved for fees
    uint maxTakeProfit = 900; // 900% of collateral.

    // Get the price of the given pair.
    function getPrice(uint _pair) public view returns (uint) {
        address pair = pairStorage.getPair(_pair);
        Pricefeed pricefeed = Pricefeed(pair);

        return pricefeed.getPrice();
    }

    // this function will only be used if the trader does not choose
    // to set a take profit for the trade
    function calculateTakeProfit(
        uint _entry,
        uint _leverageAmount,
        uint _orderType
    ) public view returns (uint) {
        OrderType order = OrderType(_orderType);
        uint takeProfitAmount = (_entry * maxTakeProfit) /
            _leverageAmount /
            100;

        uint takeProfit = order == OrderType.MARKET_LONG ||
            order == OrderType.LIMIT_LONG
            ? _entry + takeProfitAmount
            : _entry - takeProfitAmount;

        return takeProfit;
    }

    function calculateLiquidationPrice(
        uint _entry,
        uint _leverageAmount,
        uint _collateral,
        uint _orderType
    ) public view returns (uint) {
        OrderType order = OrderType(_orderType);
        uint collateral = _collateral * multiply; // 1e8

        uint liquidationAmount = (_entry *
            ((collateral * liquidationLimit) / 100)) /
            collateral /
            _leverageAmount;

        uint liquidationPrice = order == OrderType.MARKET_LONG ||
            order == OrderType.LIMIT_LONG
            ? _entry - liquidationAmount
            : _entry + liquidationAmount;

        return liquidationPrice;
    }

    function calculatePnL(
        uint _entry,
        uint _exit,
        uint _leverageAmount,
        uint _collateral,
        uint _orderType
    ) public view returns (uint) {
        OrderType order = OrderType(_orderType);
        uint collateral = _collateral * multiply; // 1e8
        uint size = (collateral * _leverageAmount) / _entry;

        uint pnl = order == OrderType.MARKET_LONG ||
            order == OrderType.LIMIT_LONG
            ? (_exit - _entry) * size
            : (_entry - _exit) * size;

        return pnl;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Counters.sol";

contract TradingStorage {
    using Counters for Counters.Counter;
    Counters.Counter private tradeIds;

    // Trade struct that contains the information about the trade
    struct openTrade {
        address trader;
        uint pair;
        uint openTimestamp;
        uint orderType; //  0 - LIMIT_LONG /  1 - LIMIT_SHORT /  2 - MARKET_LONG /  3 - LIMIT_SHORT
        uint leverageAmount;
        uint collateral;
        uint entryPrice;
        uint takeProfit;
        uint stopLoss;
        uint liquidationPrice;
    }

    struct closedTrade {
        address trader;
        uint pair;
        uint openTimestamp;
        uint closeTimestamp;
        uint orderType; //  0 - LIMIT_LONG /  1 - LIMIT_SHORT /  2 - MARKET_LONG /  3 - MARKET_SHORT
        uint leverageAmount;
        uint collateral;
        uint entryPrice;
        uint exitPrice;
        uint pnl;
    }

    struct pendingLimitOrder {
        address trader;
        bytes32 pair;
        uint initializedTimestamp;
        uint orderType; // 0 LIMIT_LONG / 1 LIMIT_SHORT
        uint leverageAmount;
        uint collateral;
        uint limitPrice;
        uint takeProfit;
        uint stopLoss;
    }

    // Mapping of trades currently open by a user
    mapping(address => openTrade[]) public usersOpenTrades;
    // Mapping of users pending limit orders
    mapping(address => pendingLimitOrder[]) public usersPendingLimitOrders;
    // Mapping of trades the user has closed
    mapping(address => mapping(uint => closedTrade)) public usersClosedTrades;

    // cancel a pending limit order
    function cancelPendingLimitOrder(address _trader, uint _index) public {
        delete usersPendingLimitOrders[_trader][_index];
    }

    //return the number of trades a user has open
    function getNumberOfOpenTrades(address _user) public view returns (uint) {
        return usersOpenTrades[_user].length;
    }

    //return all the trade information of a specific open trade
    function getOpenTradeDetails(uint _tradeIndex, address _trader)
        public
        view
        returns (openTrade memory)
    {
        openTrade memory _trade = usersOpenTrades[_trader][_tradeIndex];
        return _trade;
    }

    function getAllOpenTrades(address _trader)
        public 
        view
        returns (openTrade[] memory)
    {
        return usersOpenTrades[_trader];
    }

    //return all the trade information of a specific closed trade
    function getClosedTradeDetails(uint _tradeId, address _trader)
        public
        view
        returns (closedTrade memory)
    {
        closedTrade memory _trade = usersClosedTrades[_trader][_tradeId];
        return _trade;
    }

    // a fucntion to return the pair name of a users open trade
    function getPair(uint _tradeId, address _trader)
        public
        view
        returns (uint)
    {
        openTrade memory _trade = usersOpenTrades[_trader][_tradeId];
        return _trade.pair;
    }

    //delete the trade from the openTrades array and add it to the closedTrades mapping
    function updateTrade(
        uint _tradeIndex,
        address _trader,
        uint _exitPrice,
        uint _pnl
    ) public {
        openTrade memory _trade = usersOpenTrades[_trader][_tradeIndex];
        closedTrade memory _closedTrade = closedTrade(
            _trade.trader,
            _trade.pair,
            _trade.openTimestamp,
            block.timestamp,
            _trade.orderType,
            _trade.leverageAmount,
            _trade.collateral,
            _trade.entryPrice,
            _exitPrice,
            _pnl
        );
        usersClosedTrades[_trader][tradeIds.current()] = _closedTrade;
        tradeIds.increment();
        delete usersOpenTrades[_trader][_tradeIndex];
    }

    //add trade details to the mapping from a exteranl contract
    function addTradeDetails(
        address _trader,
        uint _pair,
        uint _timestamp,
        uint _orderType,
        uint _leverageAmount,
        uint _collateral,
        uint _entryPrice,
        uint _takeProfit, // 1e8 from front end
        uint _stopLoss, // 1e8 from front end
        uint _liquidationPrice
    ) external returns (uint) {
        usersOpenTrades[_trader].push(
            openTrade(
                _trader,
                _pair,
                _timestamp,
                _orderType,
                _leverageAmount,
                _collateral,
                _entryPrice,
                _takeProfit,
                _stopLoss,
                _liquidationPrice
            )
        );

        tradeIds.increment();
        return tradeIds.current(); // debugging purposes
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./AccessControl.sol";

contract PairStorage {
    constructor(AccessControl _accessControl) {
        accessControl = _accessControl;
    }

    AccessControl immutable accessControl;

    mapping(uint => address) public pairs;

    function getPair(uint pair) public view returns (address) {
        return pairs[pair];
    }

    function addPair(uint pair, address pairAddress) public {
        require(
            accessControl.isAdmin(msg.sender),
            "PairStorage: must have admin role to add a pair"
        );
        pairs[pair] = pairAddress;
    }

    function deletePair(uint pair) public {
        require(
            accessControl.isAdmin(msg.sender),
            "PairStorage: must have admin role to delete a pair"
        );
        delete pairs[pair];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract AccessControl {
    // The constructor sets up the initial roles for the owner
    constructor() {
        _setupRole(OWNER, msg.sender);
    }

    // The available roles
    bytes32 public OWNER;
    bytes32 public ADMIN;
    bytes32 public USER;

    // Mapping of roles to addresses
    mapping(bytes32 => mapping(address => bool)) public roles;

    // Mapping of addresses to roles
    mapping(address => bytes32) public userRoles;

    // Mapping of addresses to whether they are blacklisted
    mapping(address => bool) public blacklist;

    // Modifier to restrict access to only owner account
    modifier onlyOwner() {
        require(
            _hasRole(OWNER, msg.sender),
            "AccessControl: must have owner role"
        );
        _;
    }

    // Modifier to restrict access to only admins
    modifier onlyAdmin() {
        require(
            _hasRole(ADMIN, msg.sender),
            "AccessControl: must have admin role"
        );
        _;
    }

    modifier notBlacklisted() {
        require(
            !isBlacklisted(msg.sender),
            "AccessControl: account is blacklisted"
        );
        _;
    }

    // Set up a role for an account
    function _setupRole(bytes32 role, address account) internal {
        roles[role][account] = true;
        userRoles[account] = role;
    }

    // Remove a role from an account
    function _removeRole(bytes32 role, address account) internal {
        roles[role][account] = false;
        userRoles[account] = bytes32(0);
    }

    // Check if an account has a specific role
    function _hasRole(
        bytes32 role,
        address account
    ) internal view returns (bool) {
        return roles[role][account];
    }

    // Add a user to the contract
    function addUser(address account) public notBlacklisted {
        _setupRole(USER, account);
    }

    // Remove a user from the contract
    function removeUser(address account) public onlyAdmin {
        blacklist[account] = true;
        _removeRole(USER, account);
    }

    // Adds an admin to the contract
    function addAdmin(address account) public onlyOwner {
        _setupRole(ADMIN, account);
    }

    // Removes an admin from the contract
    function removeAdmin(address account) public onlyOwner {
        _removeRole(ADMIN, account);
    }

    // Check if an account is a user
    function isUser(address account) public view returns (bool) {
        return _hasRole(USER, account);
    }

    // Check if an account is an admin
    function isAdmin(address account) public view returns (bool) {
        return _hasRole(ADMIN, account);
    }

    // check if an account is a owner
    function isOwner(address account) public view returns (bool) {
        return _hasRole(OWNER, account);
    }

    function isBlacklisted(address account) public view returns (bool) {
        return blacklist[account];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}