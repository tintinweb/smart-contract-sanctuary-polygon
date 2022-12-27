// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/// @title A contract that serves as an order book for binary options
/// @author Arthur Gonçalves Breguez
/// @notice Place orders on an book and match equivalent orders already placed

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

interface Wallet {
    function viewUserBalance(address _account) external view returns(uint256 balance);
    function subtractBalanceForOrder(uint256 _amount, address _userAddress) external returns(bool success);
    function addBalanceForOrder(uint256 _amount, address _userAddreess) external returns(bool success);
}

interface Oracle {
    function getLatestPrice(address _active, uint8 _decimals) external view returns (int);
}

interface DateTime {
    function timestampToDateTime(uint timestamp) external pure returns (uint year, uint month, uint day, uint hour, uint minute);
    function timestampFromDateTime(uint year, uint month, uint day, uint hour) external pure returns (uint timestamp);
}

contract OrderBook is Ownable {

    struct OrderStruct {
        uint256 price;
        uint256 value;
        uint256 time;
        address sender;
        bool call_put;
    }

    struct MatchedOrder {
        uint256 price;
        uint256 total_value;
        uint256 time;
        address call;
        address put;
    }

    constructor(address _walletContract, address _active, uint8 _decimals, address _oracleContract, address _dateContract) {
        walletContract = _walletContract;
        active = _active;
        decimals = _decimals;
        oracleContract = _oracleContract;
        dateContract = _dateContract;
    }

/// @notice Arrays of pending orders and matched orders
    OrderStruct[] public buyOrderBook;
    OrderStruct[] public sellOrderBook;
    MatchedOrder[] public currentOrders;
    address internal walletContract;
    address internal oracleContract;
    address internal dateContract;
    address internal active;
    uint8 internal decimals;
    bool internal isLocked;
    uint256 public count;
    uint256 internal timestamp_lock_winner;
    uint public hour_winner;

/// @notice Emit a Log when an order ir placed, matched or removed from the book
    event LogNewOrder(address indexed sender, uint256 amount, uint256 price, bool call_put, uint256 time);
    event LogMatchOrders(address indexed call, address indexed put, uint256 total, uint256 time);
    event LogOrderRemoved(address indexed sender, uint256 price, uint256 value, bool call_put, uint256 time);
    event LogNewWinner(address indexed winner, uint256 price, uint256 value, bool call_put);
    event LogNewTie(address indexed wallet_call, address indexed wallet_put, uint256 price, uint256 value);

/// @notice Verify if the time setted by the order is valid
/// @param time Order expiration time
    modifier expirationChecker(uint256 time) {
        require(time >= block.timestamp, "You cannot place an order for a past expiration!");
        require(time <= block.timestamp + 604800 , "You cannot place and order for this expiration!");
        DateTime date_time = DateTime(dateContract);
        (uint year, uint month, uint day, uint hour, uint minute) = date_time.timestampToDateTime(block.timestamp);
        uint formated_timestamp = date_time.timestampFromDateTime(year, month, day, hour);
        if(time == formated_timestamp) {
            require(minute < 45, "You cannot place the order for this expiration!");
            _;
        }else {
            _;
        }
     
    }

/// @notice Get the contract maintenance status
/// @return isLocked equals true if contract is on maintenance, if is false the contract can be used to place orders
    function getLockStatus() external view returns(bool) {
        return isLocked;
    }

/// @notice Lock the contract for maintenance
/// @return true if contract has been locked
    function lockAndUnlockContract() external onlyOwner returns(bool){
        if(isLocked == false) {
            isLocked = true;
        }else {
            isLocked = false;
        }
        return true;
    }

    function formatTimestamp(uint256 _time) internal view returns (uint256) {
        DateTime date_time = DateTime(dateContract);
        (uint year, uint month, uint day, uint hour, ) = date_time.timestampToDateTime(_time);
        uint time = date_time.timestampFromDateTime(year, month, day, hour);
        return time;
    }

    function placeOrder(uint256 _price, uint256 _value, uint256 _time, bool call_put) external expirationChecker(_time) {
        require(isLocked == false, "Contract is Locked");
        require(_value >= 10, "Order Below minimun!");
        Wallet user_balance = Wallet(walletContract);
        address user_address = msg.sender;
        require(user_balance.viewUserBalance(user_address) >= _value, "No enough balance");
        user_balance.subtractBalanceForOrder(_value, user_address);
        uint256 time = formatTimestamp(_time);
        if(call_put == true) {
            putOrderBuy(_price, _value, time);
            quick(buyOrderBook);
        }else if(call_put == false) {
            putOrderSell(_price, _value, time);
            quick(sellOrderBook);
        }
    }

/// @notice Get the buyer order on the book by index in array
/// @param _id Index of the array
/// @return Buyer order details
    function getBuyOrder(uint _id) public view returns(OrderStruct memory) {
        return(buyOrderBook[_id]);
    }
/// @notice Get the Seller order on the book by index in array
/// @param _id Index of the array
/// @return Selles order details
    function getSellOrder(uint _id) public view returns(OrderStruct memory) {
        return(sellOrderBook[_id]);
    }
/// @notice Get the matched order on times and trades by index in array
/// @param _id Index of the array
/// @return Details of the matched order
    function getMatchedOrder(uint _id) public view returns(MatchedOrder memory) {
        return(currentOrders[_id]);
    }

/// @notice Place an buy order on the buyOrderBook or match one equivalent of sellOrderBook
/// @param _price The price of the active the user want to bet
/// @param _value The amount of cash the user wants to bet
/// @return success If order has been placed or matched
    function putOrderBuy(uint256 _price, uint256 _value, uint256 time) internal returns(bool success){
        uint256 final_lenght = 0;
        uint sell_book_lenght = sellOrderBook.length;
        if(sell_book_lenght == 0){
            buyOrderBook.push(OrderStruct(
            _price,
            _value,
            time,
            msg.sender,
            true));
            emit LogNewOrder(
                msg.sender,
                _value,
                _price,
                true,
                time
            );
            return true;
        }else if(sell_book_lenght != 0) {
            for(uint i = 0; i <= (sell_book_lenght-1); i++) {
                if(sellOrderBook[i].price == _price &&  sellOrderBook[i].time == time){
                    matchOrders(i, _price, _value, time, true);
                    return true;
                }
            }
            final_lenght = (sell_book_lenght-1);   
            if(final_lenght == (sell_book_lenght-1)) {
                buyOrderBook.push(OrderStruct(
                _price,
                _value,
                time,
                msg.sender,
                true)); 
                emit LogNewOrder(
                        msg.sender,
                        _value,
                        _price,
                        true,
                        time
                );
                return true;
            }
        }
    }
/// @notice Place an sell order on the buyOrderBook or match one equivalent of sellOrderBook
/// @param _price The price of the active the user want to bet
/// @param _value The amount of cash the user wants to bet
/// @return success If order has been placed or matched
    function putOrderSell(uint256 _price, uint256 _value, uint256 time) internal returns(bool success){
        uint256 buy_book_lenght = buyOrderBook.length;
        uint256 final_lenght = 0;
        if(buy_book_lenght == 0){
            sellOrderBook.push(OrderStruct(
            _price,
            _value,
            time,
            msg.sender,
            false));
            emit LogNewOrder(
                msg.sender,
                _value,
                _price,
                false,
                time
            );
            return true;
        }else if (buy_book_lenght != 0){
            for(uint i = 0; i <= (buy_book_lenght-1); i++) {
                if(buyOrderBook[i].price == _price && buyOrderBook[i].time == time){
                    matchOrders(i, _price, _value, time, false);
                    return true;
                }  
            }
            final_lenght = (buy_book_lenght-1);
            if(final_lenght == (buy_book_lenght-1)) {
                sellOrderBook.push(OrderStruct(
                    _price,
                    _value,
                    time,
                    msg.sender,
                    false));
                emit LogNewOrder(
                    msg.sender,
                    _value,
                    _price,
                    false,
                    time
                    );
                return true;
            }
        }
    }
///@dev Match equivalent orders
///@param i The index from the array of the first equivalent order found
///@param _price The price of the active of the matched order
///@param _value The amount of money user placed on the bet
///@param put_call The caller of the function (true if is a buyer, false if is a seller)
///@return success If success
    function matchOrders(uint256 i, uint256 _price, uint256 _value, uint256 time, bool put_call) internal returns(bool success) {
        if(put_call == true){
            if(_value == sellOrderBook[i].value) {
                uint256 total_order = _value;
                address seller_address = sellOrderBook[i].sender;
                total_order += sellOrderBook[i].value;
                for (uint index = i; index < sellOrderBook.length - 1; index++) {
                    sellOrderBook[index] = sellOrderBook[index+1];
                }
                sellOrderBook.pop();
                currentOrders.push(MatchedOrder(
                    _price,
                    total_order,
                    time,
                    msg.sender,
                    seller_address
                ));
                emit LogMatchOrders(
                    msg.sender,
                    seller_address,
                    total_order,
                    time
                );
                return true;
            }else if(_value > sellOrderBook[i].value) {
                uint256 new_value = _value - sellOrderBook[i].value;
                uint256 total_order = sellOrderBook[i].value * 2;
                address seller_address = sellOrderBook[i].sender;
                for (uint index = i; index < sellOrderBook.length - 1; index++) {
                    sellOrderBook[index] = sellOrderBook[index+1];
                }
                sellOrderBook.pop();
                currentOrders.push(MatchedOrder(
                    _price,
                    total_order,
                    time,
                    msg.sender,
                    seller_address
                ));
                emit LogMatchOrders(
                    msg.sender,
                    seller_address,
                    total_order,
                    time
                );
                putOrderBuy( _price , new_value, time);
                return true;
            }else {
                uint256 total_order = _value;
                address seller_address = sellOrderBook[i].sender;
                total_order += (sellOrderBook[i].value - _value);
                sellOrderBook[i].value = (sellOrderBook[i].value - _value);
                currentOrders.push(MatchedOrder(
                    _price,
                    total_order,
                    time,
                    msg.sender,
                    seller_address
                ));
                emit LogMatchOrders(
                    msg.sender,
                    seller_address,
                    total_order,
                    time
                );
                return true;
            }
        }
        if(put_call == false) {
            if(_value == buyOrderBook[i].value) {
                uint256 total_order = _value;
                address buyer_address = buyOrderBook[i].sender;
                total_order += buyOrderBook[i].value;
                for (uint index = i; index < buyOrderBook.length - 1; index++) {
                    buyOrderBook[index] = buyOrderBook[index+1];
                }
                buyOrderBook.pop();
                currentOrders.push(MatchedOrder(
                    _price,
                    total_order,
                    time,
                    buyer_address,
                    msg.sender
                ));
                emit LogMatchOrders(
                    buyer_address,
                    msg.sender,
                    total_order,
                    time
                );
                return true;
            }else if(_value > buyOrderBook[i].value) {
                uint256 new_value = _value - buyOrderBook[i].value;
                uint256 total_order = buyOrderBook[i].value * 2;
                address buyer_address = buyOrderBook[i].sender;
                for (uint index = i; index < buyOrderBook.length - 1; index++) {
                    buyOrderBook[index] = buyOrderBook[index+1];
                }
                buyOrderBook.pop();
                currentOrders.push(MatchedOrder(
                    _price,
                    total_order,
                    time,
                    buyer_address,
                    msg.sender
                ));
                emit LogMatchOrders(
                    msg.sender,
                    buyer_address,
                    total_order,
                    time
                );
                putOrderSell( _price , new_value, time);
            }else {
                uint256 total_order = _value;
                address buyer_address = buyOrderBook[i].sender;
                total_order += (buyOrderBook[i].value - _value);
                buyOrderBook[i].value = (buyOrderBook[i].value - _value);
                currentOrders.push(MatchedOrder(
                    _price,
                    total_order,
                    time,
                    buyer_address,
                    msg.sender
                ));
                emit LogMatchOrders(
                    buyer_address,
                    msg.sender,
                    total_order,
                    time
                );
                return true;
            }
        }
    }
///@notice Remove the first order found on the book with the params
///@param price The price of the active that the user wants to remove the bet
///@param call_put True if user wants to remove an order from buyerbook, False if user wants to remove an order from sellerbook
///@return success If success
    function removeOrder(uint256 price, uint256 time, bool call_put) external returns (bool success) {
        require(isLocked == false, "Contract is Locked");
        require(price !=0, "No zero!");
        require(time !=0, "No zero!");
        Wallet user_balance = Wallet(walletContract);
        address user_address = msg.sender;
        if(call_put == true) {
            for(uint256 i=0;i<buyOrderBook.length;i++) {
                if(buyOrderBook[i].sender == msg.sender && buyOrderBook[i].price == price && buyOrderBook[i].time == time) {
                    uint256 order_value = buyOrderBook[i].value;
                    uint256 order_time = buyOrderBook[i].time;
                    buyOrderBook[i] = buyOrderBook[buyOrderBook.length-1];
                    buyOrderBook.pop();
                    user_balance.addBalanceForOrder(order_value, user_address);
                    emit LogOrderRemoved(
                        msg.sender,
                        price,
                        order_value,
                        call_put,
                        order_time
                    );
                    quick(buyOrderBook);
                    return true;
                }
            }
        }else{
            for(uint256 i=0;i<sellOrderBook.length;i++) {
                if(sellOrderBook[i].sender == msg.sender && sellOrderBook[i].price == price) {
                    uint256 order_value = sellOrderBook[i].value;
                    uint256 order_time = sellOrderBook[i].time;
                    sellOrderBook[i] = sellOrderBook[sellOrderBook.length-1];
                    sellOrderBook.pop();
                    user_balance.addBalanceForOrder(order_value, user_address);
                    emit LogOrderRemoved(
                        msg.sender,
                        price,
                        order_value,
                        call_put,
                        order_time
                    );
                    quick(sellOrderBook);
                    return true;
                }
            }
        }
    }

/// @notice Get the winners from current timestamp
/// @dev Function must be called only by de "schedual" contract, implement a modifier when the schedual is enabled
/// @return success If success
    function pickWinner() public returns(bool success){
        require(isLocked == false, "Contract is Locked");
        count += 1; 
        // uint formated_timestamp = formatTimestamp(block.timestamp);
        // require(block.timestamp-timestamp_lock_winner >= 3600, "Pick winner is locked");
        // timestamp_lock_winner = block.timestamp;

        DateTime date_time = DateTime(dateContract);
        (uint _year, uint _month, uint _day, uint _hour, ) = date_time.timestampToDateTime(block.timestamp);
        uint formated_timestamp = date_time.timestampFromDateTime(_year, _month, _day, _hour);
        require(hour_winner != _hour, "Hour must be different!");
        hour_winner = _hour;

        if(currentOrders.length > 0) {
            address owner = Ownable.owner();
            Oracle oracle_instance = Oracle(oracleContract);
            int _latestPrice = oracle_instance.getLatestPrice(active, decimals);
            for(uint i=0 ;i<currentOrders.length;i++){
                if(currentOrders[i].price < uint(_latestPrice) && currentOrders[i].time == formated_timestamp){
                    uint256 total_value = currentOrders[i].total_value;
                    uint prize = (total_value * 95/100);
                    uint price = currentOrders[i].price;
                    address winner = currentOrders[i].call;
                    Wallet winner_wallet = Wallet(walletContract);
                    currentOrders[i].total_value = 0;
                    (bool send) = winner_wallet.addBalanceForOrder((prize),winner);
                    require(send, "Failed winner!");
                    (bool send2) = winner_wallet.addBalanceForOrder((total_value - prize), owner);
                    require(send2, "Failed owner!");
                    emit LogNewWinner(
                        winner,
                        price,
                        prize,
                        true
                    );
                }else if(currentOrders[i].price > uint(_latestPrice) && currentOrders[i].time == formated_timestamp) {
                    uint256 total_value = currentOrders[i].total_value;
                    uint prize = (total_value * 95/100);
                    uint price = currentOrders[i].price;
                    address winner = currentOrders[i].put;
                    Wallet winner_wallet = Wallet(walletContract);
                    currentOrders[i].total_value = 0;
                    (bool send) = winner_wallet.addBalanceForOrder((prize),winner);
                    require(send, "Failed winner!");
                    (bool send2) = winner_wallet.addBalanceForOrder((total_value - prize), owner);
                    require(send2, "Failed owner!");
                    emit LogNewWinner(
                        winner,
                        price,
                        prize,
                        false
                    );
                }else if(currentOrders[i].price == uint(_latestPrice) && currentOrders[i].time == formated_timestamp){
                    uint256 total_value = currentOrders[i].total_value;
                    uint prize = (total_value * 998/1000);
                    uint price = currentOrders[i].price;
                    address wallet_call = currentOrders[i].call;
                    address wallet_put = currentOrders[i].put;
                    Wallet winner_wallet = Wallet(walletContract);
                    currentOrders[i].total_value = 0;
                    (bool send_call) = winner_wallet.addBalanceForOrder(prize * 1/2, wallet_call);
                    (bool send_put) = winner_wallet.addBalanceForOrder(prize * 1/2, wallet_put);
                    (bool send2) = winner_wallet.addBalanceForOrder((total_value - prize), owner);
                    require(send2, "Failed owner!");
                    require(send_call, "Failed transfer call !");
                    require(send_put, "Failed transfer put !");
                    emit LogNewTie(
                        wallet_call,
                        wallet_put,
                        price,
                        prize
                    );
                }
            }
            sortCurrentOrders();
            removeZeroOrders();
        }
        if(buyOrderBook.length > 0) {
            sortOrderBook(buyOrderBook);
            removeUnmachtedOrders(formated_timestamp, buyOrderBook);
            quick(buyOrderBook);
        }
        if(sellOrderBook.length > 0) {
            sortOrderBook(sellOrderBook);
            removeUnmachtedOrders(formated_timestamp, sellOrderBook);
            quick(sellOrderBook);
        }
        return true;
    }

/// @notice Remove from order book the orders that have expired and did not had a match and return the money to the user account
/// @param formated_timestamp The formated timestamp from the exact hour when the function is called
/// @param _book The order book that will be cleaned from the unmatched orders
/// @return success If success 
    function removeUnmachtedOrders(uint formated_timestamp, OrderStruct [] storage _book) internal returns(bool success) {
        Wallet user_balance = Wallet(walletContract);
        for(uint i=_book.length-1; i>0;i--) {
            if(_book[i].time == formated_timestamp) {
                address user_address = _book[i].sender;
                uint value = _book[i].value;
                _book.pop();
                user_balance.addBalanceForOrder(value, user_address);
            }else if(_book[i].time != formated_timestamp){
                break;
            }
        }
        if(_book.length == 1 && _book[0].time == formated_timestamp){
            address user_address = _book[0].sender;
            uint value = _book[0].value;
            _book.pop();
            user_balance.addBalanceForOrder(value, user_address);
        }
        return true;
    } 

/// @notice Sort the currentOrders (times and trade) to clean the array from the expired orders
/// @param pos Index of the currentOrders array
/// @return true If success
    function sort_current_orders(uint pos) internal returns (bool) {
        uint w_min = pos;
        for(uint i = pos; i < currentOrders.length; i++) {
            if(currentOrders[i].total_value > currentOrders[w_min].total_value) {
                w_min = i;
            }
        }
        if(w_min == pos) return false;
        MatchedOrder memory tmp = currentOrders[pos];
        currentOrders[pos] = currentOrders[w_min];
        currentOrders[w_min] = tmp;
        return true;
    }
/// @notice Callable function that sort the array before it cleans
    function sortCurrentOrders() internal {
        for(uint i = 0;i < currentOrders.length-1;i++) {
            sort_current_orders(i);
        }
    }
/// @notice Callable function that sort the array before it cleans
/// @param _book The book that will be sorted to clean  
    function sortOrderBook(OrderStruct[] storage _book) internal {
        for(uint i = 0;i < _book.length-1;i++) {
            sort_order_book(i, _book);
        }   
    }
/// @notice Sort the order book to clean the array from the unmatched orders
/// @param pos Index of the currentOrders array
/// @param _book The book that will be sorted to clean  
    function sort_order_book(uint pos, OrderStruct[] storage _book) internal returns (bool) {
        uint w_min = pos;
        for(uint i = pos; i < _book.length; i++) {
            if(_book[i].time > _book[w_min].time) {
                w_min = i;
            }
        }
        if(w_min == pos) return false;
        OrderStruct memory tmp = _book[pos];
        _book[pos] = _book[w_min];
        _book[w_min] = tmp;
        return true;
    }
/// @notice Remove the orders with value setted to zero from the currentOrders, cleaning the book from the expired orders
    function removeZeroOrders() internal {
        for(uint i = currentOrders.length - 1;i>0;i--) {
            if(currentOrders[i].total_value == 0){
                currentOrders.pop();
            }else if(currentOrders[i].total_value != 0) {
                break;
            }
        }
        if(currentOrders.length == 1 && currentOrders[0].total_value == 0){
            currentOrders.pop();
        }
    }

/// @notice Call the quicksort function
/// @param _book The book that will be sorted
    function quick(OrderStruct[] storage _book) internal {
    uint _book_lenght = _book.length;
    if (_book_lenght > 1) {
        quickPart(_book, 0, _book_lenght - 1);
        }
    }

/// @notice Quicksort the order book to order the list
/// @param _book The book that will be sorted
/// @param low The 0 index
/// @param high The last index of the list
    function quickPart(OrderStruct[] storage _book, uint low, uint high) internal {
    if (low < high) {
        OrderStruct memory pivotVal = _book[(low + high) / 2];
        uint low1 = low;
        uint high1 = high;
        for (;;) {
            while (_book[low1].time < pivotVal.time) low1++;
            while (_book[high1].time > pivotVal.time) high1--;
            if (low1 >= high1) break;
            OrderStruct memory tmp = _book[low1];
            _book[low1] = _book[high1];
            _book[high1] = tmp;
            low1++;
            high1--;
        }
        if (low < high1) quickPart(_book, low, high1);
        high1++;
        if (high1 < high) quickPart(_book, high1, high);
        }
    }
}