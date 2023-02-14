// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Counters.sol";

contract TradingStorage {
    using Counters for Counters.Counter;
    Counters.Counter private tradeIds;


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

    openTrade[] public allOpenTrades;

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