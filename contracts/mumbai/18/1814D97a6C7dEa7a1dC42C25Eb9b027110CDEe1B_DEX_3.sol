// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;
import './IERC20.sol';

contract DEX_3 {

    // Token data type defined with a ticker and its address
    struct Token {
        bytes32 ticker;
        address token_address;
    }

    // Order data type defined with necessary elements
    struct Order {
        bytes32 ticker;
        uint id;
        Listing listing;
        address trader;
        uint price;
        uint amount;
        uint filled; 
        uint date;
    }

    // Enum defined for the direction of the listing/order
    enum Listing {
        BUY, 
        SELL
    }

    // Mappings and definitions
    mapping(bytes32 => Token) public tokens;
    bytes32[] public token_list;
    mapping(address => mapping(bytes32 => uint)) public trader_balance;
    mapping(bytes32 => mapping(uint => Order[])) public order_book;
    uint public next_order_id;
    uint public next_trade_id;
    address public owner;
    bytes32 constant DAI = bytes32("DAI");

    event NewTrade(
        uint trade_id,
        uint order_id,
        bytes32 indexed ticker,
        address indexed trader1,
        address indexed trader2,
        uint amount,
        uint price,
        uint date
    );

    constructor() {
        owner = msg.sender;
    }

    // Modifier for only giving the owner the ability to call a function
    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    // Modifier for stopping for submitting DAI orders (no use trading a stablecoin) 
    modifier tokenNotDai(bytes32 ticker){
    require(ticker != DAI, "Not allowed to trade DAI");
    _;
    }

    // Modifier for checking if the token exists when submitting an order
    modifier tokenExistance(bytes32 _ticker) {
        require(tokens[_ticker].token_address != address(0), "Such a token does not exist");
        _;
    }

    event Received(address sender, uint amount);

    receive() external payable {
    emit Received(msg.sender, msg.value);
    }

    function fetchOrders(
      bytes32 _ticker, 
      Listing listing) 
      external 
      view
      returns(Order[] memory) {
      return order_book[_ticker][uint(listing)];
    }

    function fetchTokens() 
      external 
      view 
      returns(Token[] memory) {
      Token[] memory _tokens = new Token[](token_list.length);
      for (uint i = 0; i < token_list.length; i++) {
        _tokens[i] = Token(
          tokens[token_list[i]].ticker,
          tokens[token_list[i]].token_address
        );
      }
      return _tokens;
    }

    function addToken(
        bytes32 _ticker,
        address _token_address
    ) onlyOwner external {
        tokens[_ticker] = Token(_ticker, _token_address);
        token_list.push(_ticker);
    }

    function deposit(
        uint _amount,
        bytes32 _ticker
    ) tokenExistance(_ticker) external {
        IERC20 token = IERC20(tokens[_ticker].token_address);
        token.transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        trader_balance[msg.sender][_ticker] += _amount;
    }

    function withdraw(
        uint _amount,
        bytes32 _ticker
    ) tokenExistance(_ticker) external {
        require(
            trader_balance[msg.sender][_ticker] >= _amount, "You are trying to withdraw more than you have"
            );
        IERC20 token = IERC20(tokens[_ticker].token_address);
        trader_balance[msg.sender][_ticker] -= _amount;
        token.transfer(
            msg.sender,
            _amount
        );
    }

    // Function that creates the limit order but does not execute it. It calls the execution function if rules pass.
    function createLimitOrder(
    bytes32 _ticker,
    uint _amount, 
    uint _price,
    Listing listing
    )
    tokenExistance(_ticker) 
    tokenNotDai(_ticker) 
    external {
        if (listing == Listing.SELL) {
            require(trader_balance[msg.sender][_ticker] >= _amount, "Trader balance too low");
        } else {
            require(trader_balance[msg.sender][DAI] >= _amount * _price, "DAI balance too low");
        }

        Order[] storage orders = order_book[_ticker][uint(listing)];

        orders.push(Order(
            _ticker,
            next_order_id,
            listing,
            msg.sender,
            _price,
            _amount,
            0,
            block.timestamp
        ));
    
    bubbleSort(_ticker, listing);
    next_order_id++;

    // Check if there is at least 1 order on the opposite side of the order book. No orders on the opposite side, means no execution necessary.
    Order[] storage check_orders = order_book[_ticker][uint(listing == Listing.SELL ? Listing.BUY : Listing.SELL)];
    uint i = check_orders.length;
    if (i < 1){
    return;
    } 

    // Find a the position of the order with a matching price in the opposite listing 
    uint opposite_listing = uint(listing == Listing.SELL ? Listing.BUY: Listing.SELL);

    // Fetch the positions and prices of the orders that match the price in BOTH listing (necessary for updating both sides when orders are partially/fully filled)
    (uint priceResult, uint position) = binarySearch(_ticker, opposite_listing, _price);
    (, uint position2) = binarySearch(_ticker, uint(listing), _price);

    // Execute ONLY if the priceResult is equivalent to the opposite listing. Binary search returns 0 for listings that don't match any price.
    if (priceResult == _price){
    executeLimitOrder(_ticker, _amount, _price, listing, position, position2);
    }
    }

    // Function that executes the limit order.
    function executeLimitOrder(
    bytes32 _ticker,
    uint _amount, 
    uint _price,
    Listing listing,
    uint position,
    uint position2
    ) 
    tokenExistance(_ticker) 
    tokenNotDai(_ticker)
    private {  

    Order[] storage orders = order_book[_ticker][uint(listing == Listing.SELL ? Listing.BUY : Listing.SELL)];
    Order[] storage orders_opposite = order_book[_ticker][uint(listing == Listing.SELL ? Listing.SELL : Listing.BUY)];  

    // Calculate if the order will be fully or partially filled. Get the matched variable to use for selling and buying operations.
    uint amount_available = orders[position].amount - orders[position].filled;
    uint matched = (_amount > amount_available) ? amount_available : _amount;

    // Update the filled section of the order for both sides
    orders[position].filled += matched;
    orders_opposite[position2].filled += matched;

    // emit event that a new trade is happening.
    emit NewTrade(
            next_trade_id,
            orders[position].id,
            _ticker,
            orders[position].trader,
            msg.sender,
            matched,
            orders[position].price,
            block.timestamp
            );

    if(listing == Listing.SELL) {
            
            // ERC20 asset deducted above, and supplement balance with DAI (performing SELL operation for msg.sender)
            trader_balance[msg.sender][_ticker] -= matched;
            trader_balance[msg.sender][DAI] += matched * orders[position].price;

            // Add ERC20 asset, and deduct balance with DAI (performing BUY operation for the other party)
            trader_balance[orders[position].trader][_ticker] += matched;
            trader_balance[orders[position].trader][DAI] -= matched * orders[position].price;
        
    } else {
            // Require that msg.sender has enough balance in DAI to buy the trade at the desired quantity.
            require(trader_balance[msg.sender][DAI] >= _amount * orders[position].price, "dai balance too low");
            
            // Add ERC20 asset, and deduct balance with DAI (performing BUY operation for msg.sender)
            trader_balance[msg.sender][DAI] -= matched * orders[position].price;
            trader_balance[msg.sender][_ticker] += matched;

            // Deduct ERC20 asset, and add balance with DAI (performing SELL operation for the other party)
            trader_balance[orders[position].trader][_ticker] -= matched;
            trader_balance[orders[position].trader][DAI] += matched * orders[position].price;
        }

    next_trade_id++;
    
    // Delete the order on EITHER the SELL / BUY side once it has been fulfilled fully.
    if (orders[position].filled == orders[position].amount){
        deleteLimitOrder(_price, _ticker, uint(listing == Listing.SELL ? Listing.BUY : Listing.SELL));
    }
    if (orders_opposite[position2].filled == orders_opposite[position2].amount){
        deleteLimitOrder(_price, _ticker, uint(listing == Listing.SELL ? Listing.SELL : Listing.BUY));
    }
}

    // A function to delete orders on SELL OR BUY sides once it has been fulfilled
    function deleteLimitOrder(
        uint _priceResult,
        bytes32 _ticker,
        uint listing
        ) private {
        Order[] storage order_deletion = order_book[_ticker][listing];
        (,uint position_delete) = binarySearch(_ticker, listing, _priceResult);
        delete order_deletion[position_delete];
    }

    // A function that performs binary search to find if the limit order price fits.
    function binarySearch(
        bytes32 _ticker,
        uint listing,
        uint _price
        ) private view returns (uint priceResult, uint position) {
        Order[] storage orders = order_book[_ticker][listing];
        uint _id_start = 0;
        uint _id_end = orders.length -1;

        while(_id_start <= _id_end) {
            uint _id_mid = _id_start + ((_id_end - _id_start)/2);

            if(orders[_id_mid].price == _price) {
                return (_price, _id_mid);
            } else if (orders[_id_mid].price < _price) {
                _id_start = _id_mid +1;
            } else {
                _id_end = _id_mid - 1;
            }
        }
        return (0, 0);
    }

    // Perform bubble sort operation to order the array.
    function bubbleSort(bytes32 _ticker, Listing listing) private {
        Order[] storage orders = order_book[_ticker][uint(listing)];        
        uint i = orders.length - 1;

        while(i > 0) {
        if(listing == Listing.BUY && orders[i - 1].price > orders[i].price){
            break;
        }
        if(listing == Listing.SELL && orders[i - 1].price < orders[i].price){
            break;
        }

        Order memory order = orders[i - 1];
        orders[i-1] = orders[i];
        orders[i] = order;
        i--;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}