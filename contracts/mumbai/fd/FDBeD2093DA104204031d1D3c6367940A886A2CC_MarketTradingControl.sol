// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./TradingStorage.sol";
import "./TradingLogic.sol";
import "./AccessControl.sol";

contract MarketTradingControl {
    // contracts
    TradingStorage immutable tradingStorage;
    TradingLogic immutable tradingLogic;
    AccessControl immutable accessControl;

    constructor(
        TradingStorage _tradingStorage,
        TradingLogic _tradingLogic,
        AccessControl _accessControl
    ) {
        tradingStorage = _tradingStorage;
        tradingLogic = _tradingLogic;
        accessControl = _accessControl;
    }


    function openMarketOrder(
        address _trader,
        uint _pair,
        int _orderType,
        int _leverageAmount,  // 1e0 from frontend
        int _collateral,  // 1e18 from frontend
        int _takeProfit, // 1e8 from front end
        int _stopLoss // 1e8 from front end
    ) public returns(uint) {
        // check if the address is already a user

        int entry = tradingLogic.getPrice(_pair);

        int liquidationPrice = tradingLogic.calculateLiquidationPrice(
            entry,
            _leverageAmount,
            _collateral,
            _orderType
        );

        int takeProfit = _takeProfit <= 0
            ? tradingLogic.calculateTakeProfit(
                entry,
                _leverageAmount,
                _orderType
            )
            : _takeProfit;

        uint tradeId = tradingStorage.addTradeDetails(
            _trader,
            _pair,
            block.timestamp,
            uint(_orderType),
            _leverageAmount,
            _collateral,
            entry,
            takeProfit,
            _stopLoss,
            liquidationPrice
        );
        return tradeId;
    }

    function closeMarketOrder(uint _tradeId, address _trader) public returns(int) {   // need to do checking for the owner of the trade
        int profit;

        int openPrice = tradingStorage
            .getOpenTradeDetails(_tradeId, _trader)
            .entryPrice;

        int leverage = tradingStorage
            .getOpenTradeDetails(_tradeId, _trader)
            .leverageAmount;

        int collateral = tradingStorage
            .getOpenTradeDetails(_tradeId, _trader)
            .collateral;

        uint pair = tradingStorage
            .getOpenTradeDetails(_tradeId, _trader)
            .pair;

        int closePrice = tradingLogic.getPrice(pair);

        uint order = tradingStorage
            .getOpenTradeDetails(_tradeId, _trader)
            .orderType;

        profit = tradingLogic.calculatePnL(
            openPrice,
            closePrice,
            leverage,
            collateral,
            order
        );
        tradingStorage.updateTrade(_tradeId, _trader, closePrice, profit);


        return profit;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "./TradingLogic.sol";
import "./MarketTradingControl.sol";

contract TradingStorage is AutomationCompatibleInterface {


    using Counters for Counters.Counter;
    Counters.Counter private tradeIds;

    TradingLogic internal tradingLogic;
    MarketTradingControl internal marketTradingControl;



    // Trade struct that contains the information about the trade
    struct openTrade {
        address trader;
        uint tradeId;
        uint pair;
        uint openTimestamp; 
        uint orderType; //  0 - LIMIT_LONG /  1 - LIMIT_SHORT /  2 - MARKET_LONG /  3 - LIMIT_SHORT
        int leverageAmount;
        int collateral;
        int entryPrice;
        int takeProfit;
        int stopLoss;
        int liquidationPrice;
    }

    struct closedTrade {
        address trader;
        uint tradeId;
        uint pair;
        uint openTimestamp;
        uint closeTimestamp;
        uint orderType; //  0 - LIMIT_LONG /  1 - LIMIT_SHORT /  2 - MARKET_LONG /  3 - MARKET_SHORT
        int leverageAmount;
        int collateral;
        int entryPrice;
        int exitPrice;
        int pnl;
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

    address[] public allTraders;

    // Mapping of trades currently open by a user
    mapping(address => openTrade[]) public usersOpenTrades;
    //Mapping of all closed trades of user
    mapping(address => closedTrade[]) public usersClosedTrades;
    // Mapping of users pending limit orders
    mapping(address => pendingLimitOrder[]) public usersPendingLimitOrders;
    // Mapping of trades the user has closed



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

    function getAllClosedTrades(address _trader)
        public
        view
        returns (closedTrade[] memory)
    {
        return usersClosedTrades[_trader];
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
        int _exitPrice,
        int _pnl
    ) public returns(uint) {
        openTrade memory _trade = usersOpenTrades[_trader][_tradeIndex];
        // tradeIds.increment();
        closedTrade memory _closedTrade = closedTrade(
            _trade.trader,
            _tradeIndex,
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
        usersClosedTrades[_trader].push(_closedTrade);
        usersOpenTrades[_trader][_tradeIndex] = usersOpenTrades[_trader][usersOpenTrades[_trader].length - 1];
        usersOpenTrades[_trader].pop();

        return tradeIds.current();
    }

    //add trade details to the mapping from a exteranl contract
    function addTradeDetails(
        address _trader,
        uint _pair,
        uint _timestamp,
        uint _orderType,
        int _leverageAmount,
        int _collateral,
        int _entryPrice,
        int _takeProfit, // 1e8 from front end
        int _stopLoss, // 1e8 from front end
        int _liquidationPrice
    ) external returns (uint) {
        
        bool found = false;
        for(uint256 i = 0; i < allTraders.length; i++) {
        if(allTraders[i] == _trader) {
            found = true;
            break;
        }
       }
       if (!found) {
         allTraders.push(_trader);
        }

        uint tradeIndex = tradeIds.current();
        usersOpenTrades[_trader].push(
            openTrade(
                _trader,
                tradeIndex,
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
        
        return tradeIndex; // debugging purposes
    }

    function compareTakeProfits(address _trader, uint _tradeIndex) public view returns (bool) {
        openTrade memory _trade = usersOpenTrades[_trader][_tradeIndex];
        uint pair = _trade.pair;
        int takeProfit = _trade.takeProfit;

        int currentPrice = tradingLogic.getPrice(pair);

        int deviationPercent = takeProfit / 10000;

        int upperLimit = takeProfit + deviationPercent;
        int lowerLimit = takeProfit - deviationPercent;

        if(currentPrice >= lowerLimit && currentPrice <= upperLimit) {
            return true;
        }

        return false;

    }

    function compareStopLoss(address _trader, uint _tradeIndex) public view returns (bool) {
        openTrade memory _trade = usersOpenTrades[_trader][_tradeIndex];
        uint pair = _trade.pair;
        int stopLoss = _trade.stopLoss;

        int currentPrice = tradingLogic.getPrice(pair);

        int deviationPercent = stopLoss / 10000;

        int upperLimit = stopLoss + deviationPercent;
        int lowerLimit = stopLoss - deviationPercent;

        if(currentPrice >= lowerLimit && currentPrice <= upperLimit) {
            return true;
        }

        return false;

    }

    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory performData) {
         for(uint i = 0; i < allTraders.length; i++) {
              openTrade[] memory trades = getAllOpenTrades(allTraders[i]);
              for(uint j = 0; j < trades.length; j++) {
                  if(compareTakeProfits(allTraders[i], j)
                     || compareStopLoss(allTraders[i], j)                  
                  ) {
                    upkeepNeeded = true;
                    performData = abi.encode(allTraders[i], j);
                    return (upkeepNeeded, performData);
                  } 
              }
         }
    }

    function performUpkeep(bytes calldata performData) external override {
        (address _trader, uint index) = abi.decode(performData, (address, uint));
        marketTradingControl.closeMarketOrder(index, _trader);
    }

    function setTradingLogic(TradingLogic _tradingLogic) public {
        tradingLogic = _tradingLogic;
    }

    function setMarketControl(MarketTradingControl _tradingControl) public {
        marketTradingControl = _tradingControl;
    }
}

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

    int multiply = 1e8; // 8 decimals
    int liquidationLimit = 90; // loss of 90% of collateral. The rest will be saved for fees
    int maxTakeProfit = 900; // 900% of collateral.

    // Get the price of the given pair.
    function getPrice(uint _pair) public view returns (int) {
        address pair = pairStorage.getPair(_pair);
        Pricefeed pricefeed = Pricefeed(pair);

        return int(pricefeed.getPrice());
    }

    // this function will only be used if the trader does not choose
    // to set a take profit for the trade
    function calculateTakeProfit(
        int _entry,
        int _leverageAmount,
        int _orderType
    ) public view returns (int) {
        OrderType order = OrderType(_orderType);
        int takeProfitAmount = (_entry * maxTakeProfit) /
            _leverageAmount /
            100;

        int takeProfit = order == OrderType.MARKET_LONG ||
            order == OrderType.LIMIT_LONG
            ? _entry + takeProfitAmount
            : _entry - takeProfitAmount;

        return takeProfit;
    }

    function calculateLiquidationPrice(
        int _entry,  // 1e8 
        int _leverageAmount,
        int _collateral, // 1e18 from FE
        int _orderType
    ) public view returns (int) {
        OrderType order = OrderType(_orderType);

        int liquidationAmount = (_entry *
            ((_collateral * liquidationLimit) / 100)) /
            _collateral /
            _leverageAmount;

        int liquidationPrice = order == OrderType.MARKET_LONG ||
            order == OrderType.LIMIT_LONG
            ? _entry - liquidationAmount
            : _entry + liquidationAmount;

        return liquidationPrice;  // 1e8
    }

    function calculatePnL(   // need to check for max Profit
        int _entry,
        int _exit,
        int _leverageAmount,
        int _collateral,
        uint _orderType
    ) public  view returns (int) {
        OrderType order = OrderType(_orderType);
       // collateral - 1e18 // entry price and exit price - 1e8
        int size = (_collateral * _leverageAmount) / _entry;

        int pnl = order == OrderType.MARKET_LONG ||
            order == OrderType.LIMIT_LONG
            ? (_exit - _entry) * size
            : (_entry - _exit) * size;

        return pnl;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}