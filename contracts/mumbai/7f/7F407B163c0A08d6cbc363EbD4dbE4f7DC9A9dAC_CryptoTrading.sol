// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "../contracts_token/token/ERC20/ERC20.sol";

contract CryptoTrading {
    uint counter;

    // Struct to define a Token data type 
    struct Token {
        bytes32 ticker;
        address token_address;
    }

    // Struct to define an Order data type 
    struct OrderRecorded {
        bytes32 ticker;
        uint id;
        Listing listing;
        address trader;
        uint price;
        uint amount;
        uint filled; 
        uint date;
    }

    struct Order {
        address maker;
        address makeAsset;
        uint makeAmount;
        address taker;
        address takeAsset;
        uint takeAmount;
        uint salt;
        uint startBlock;
        uint endBlock;
    }

    // Struct to define an Unfilled Market Order (MO = Market Order) data type
    struct Unfilled_MO {
        bytes32 ticker;
        uint id;
        Listing listing;
        address trader;
        uint amount;
        uint filled; 
        uint date;
    }

    // Enum that defines the direction of the listing (can only be BUY or SELL)
    enum Listing {
        BUY, 
        SELL
    }

    // Mappings and arrays
    mapping(bytes32 => Token) public tokens;
    bytes32[] public token_list;
    mapping(address => mapping(bytes32 => uint)) public trader_balance;
    mapping(bytes32 => mapping(uint => OrderRecorded[])) public order_recorded;
    mapping(uint => Order[]) public order_book;
    mapping(bytes32 => mapping(uint => Unfilled_MO[])) public unfilled_market_order;

    // Definitions
    uint public next_order_id;
    uint public next_trade_id;
    address public owner;
    bytes32 constant JAT = bytes32("JAT");

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

    event CancelLimitOrder(
        bytes32 _ticker, 
        uint date,
        Listing listing
    );

    constructor() {
        owner = msg.sender;
    }

    // Modifier for only giving the owner the ability to call a function
    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    // Modifier for stopping Token1 trades (no use trading a stablecoin) 
    modifier tokenNotJAT(bytes32 ticker){
    require(ticker != JAT, "Not allowed to trade JAT");
    _;
    }

    // Modifier for checking if the token exists when submitting an order
    modifier tokenExistance(bytes32 _ticker) {
        require(tokens[_ticker].token_address != address(0), "Such a token does not exist");
        _;
    }

    // Return open orders
    function getOpenBuyOrders(
      bytes32 _ticker) 
      external 
      view
      returns(OrderRecorded[] memory) {
      return order_recorded[_ticker][0];
    }

    function getOpenSellOrders(
      bytes32 _ticker) 
      external 
      view
      returns(OrderRecorded[] memory) {
      return order_recorded[_ticker][1];
    }

    // Return all the tokens on the exchange
    function getTokens() 
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
    ) external onlyOwner {
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

    // Creates the limit order
    function createLimitOrder(
    bytes32 _ticker,
    uint _amount, 
    uint _price,
    Listing listing
    )
    tokenExistance(_ticker) 
    tokenNotJAT(_ticker) 
    public {
        if (listing == Listing.SELL) {
            require(trader_balance[msg.sender][_ticker] >= _amount, "Trader balance too low");
        } else {
            require(trader_balance[msg.sender][JAT] >= _amount * _price, "JAT balance too low");
        }

    OrderRecorded[] storage orders = order_recorded[_ticker][uint(listing)];

        orders.push(OrderRecorded(
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

    // Check if there is at least 1 order on the opposite side of the order book. If there aren't any orders on the opposite side, it means no execution is necessary.
    uint opposite_listing = uint(listing == Listing.SELL ? Listing.BUY: Listing.SELL);
    OrderRecorded[] storage check_orders = order_recorded[_ticker][opposite_listing];
    Unfilled_MO[] storage unfilled_MO = unfilled_market_order[_ticker][opposite_listing];

    if (check_orders.length < 1 && unfilled_MO.length < 0){
        return;
    }

    // Fetch the positions and prices of the orders that match the price in BOTH listings (necessary for updating both sides when orders are partially or fully filled)
    (bool found, uint position) = linearSearch(_ticker, opposite_listing, _price);
    (, uint position2) = linearSearch(_ticker, uint(listing), _price);

    // Execute ONLY if the priceResult is equivalent to the opposite listing. Binary search returns false for listings that don't match any price.
    if (found == true){
    executeLimitOrder(_ticker, _amount, _price, listing, position, position2);
    }

    // Check if any orders are in the unfulfilled market order array.
    if (unfilled_MO.length > 0) {
        fillUpMarketOrder(_ticker, _amount, _price, opposite_listing, position, listing);
    }
    }

    // Cancels the limit order
    function cancelLimitOrder(
    bytes32 _ticker,
    uint date,
    Listing listing
    )
    tokenExistance(_ticker) 
    tokenNotJAT(_ticker) 
    public {
        OrderRecorded[] memory orders = order_recorded[_ticker][uint(listing)];
        delete orders[date];
        emit CancelLimitOrder(_ticker, date, listing);
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
    tokenNotJAT(_ticker)
    private { 

    OrderRecorded[] storage orders = order_recorded[_ticker][
        uint(listing == Listing.SELL ? Listing.BUY : Listing.SELL)];
    OrderRecorded[] storage orders_opposite = order_recorded[_ticker][uint(listing == Listing.SELL ? Listing.SELL : Listing.BUY)];  

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

    // Execute the order via orderExchange function
    orderExchange(_ticker, _amount, orders[position].price, matched, position, listing);
    next_trade_id++;
    
    // Delete the order on the SELL / BUY side if they were fully filled.
    if (orders[position].filled == orders[position].amount){
        deleteLimitOrder(_price, _ticker, uint(listing == Listing.SELL ? Listing.BUY : Listing.SELL));
    }
    if (orders_opposite[position2].filled == orders_opposite[position2].amount){
        deleteLimitOrder(_price, _ticker, uint(listing == Listing.SELL ? Listing.SELL : Listing.BUY));
    }
    
}

    // A function that allows to create a market order.
    function createMarketOrder(
        bytes32 _ticker,
        uint _amount,
        Listing listing
    ) 
    tokenExistance(_ticker) 
    tokenNotJAT(_ticker) 
    external {
    if (listing == Listing.SELL) {
            require(trader_balance[msg.sender][_ticker] >= _amount, "Trader balance too low");
        }

    // Check if there is at least 1 order on the opposite side of the order book. No orders on the opposite side, means no execution necessary.
    uint opposite_listing = uint(listing == Listing.SELL ? Listing.BUY : Listing.SELL);
    OrderRecorded[] storage orders = order_recorded[_ticker][opposite_listing];

    if (orders.length < 1){
    return;
    } 

    // The loop will fulfill the match order fully from the available limit orders on the opposite side of the listing. Hence, if a BUY market order is created, it will go through the SELL limit orders until either the SELL array is empty or the market order is fully filled.
    uint j = 0;
    uint remainder_to_fill = _amount;

    while(orders.length > 0 && remainder_to_fill > 0) {
        uint amount_available = orders[0].amount - orders[0].filled;
        uint matched = (remainder_to_fill > amount_available) ? amount_available : remainder_to_fill;
        remainder_to_fill -= matched;
        orders[0].filled += matched;
        emit NewTrade(
            next_trade_id,
            orders[0].id,
            _ticker,
            orders[0].trader,
            msg.sender,
            matched,
            orders[0].price,
            block.timestamp    
        );

        // Call the order exchange function that will swap the assets between both parties.
        orderExchange(_ticker, _amount, orders[0].price, matched, 0, listing);

        // Delete the limit orders if they have been fully filled.
        if (orders[0].filled == orders[0].amount){
        deleteLimitOrder(orders[0].price, _ticker, uint(listing == Listing.SELL ? Listing.BUY : Listing.SELL));
        }
        next_trade_id++;
        j++;
        }

    // In case the market order has not been fully filled (hence, the array of the opposite listing is empty), push the remainder into a separate array called unfilled_MO. This will be filled once a limit order is created.
    if (remainder_to_fill > 0) {
        Unfilled_MO[] storage unfilled_MO = unfilled_market_order[_ticker][uint(listing)];

        unfilled_MO.push(Unfilled_MO(
            _ticker,
            next_order_id,
            listing,
            msg.sender,
            remainder_to_fill,
            0,
            block.timestamp
        ));
    } 
    }

    // Function that fills up the unfilled market orders.
    function fillUpMarketOrder(
    bytes32 _ticker,
    uint _amount, 
    uint _price,
    uint opposite_listing,
    uint position,
    Listing listing
    ) private {
    
    OrderRecorded[] storage orders = order_recorded[_ticker][uint(listing)];

    Unfilled_MO[] storage unfilled_MO = unfilled_market_order[_ticker][opposite_listing];

    uint remainder_to_fill = _amount;
    uint i = 0;
    
    // Equivalent function of the one in create market order with a few different details.
    while(unfilled_MO.length > 0 && remainder_to_fill > 0){
        uint amount_available = unfilled_MO[i].amount - unfilled_MO[i].filled;
        uint matched = (remainder_to_fill > amount_available) ? amount_available : remainder_to_fill;

        // Fills up the orders on both the limit array and the unfilled market order array
        remainder_to_fill -= matched;
        orders[position].filled += matched;
        unfilled_MO[i].filled += matched;
        
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

        // Delete the unfilled market order if the total amount matches the filled amount 
        if (unfilled_MO[i].amount == unfilled_MO[i].filled){
        deleteUnfilledMarketOrders(_ticker, opposite_listing);
            }
        i++;
        next_trade_id++;
    }
    
    // Delete the order once it has been fulfilled fully.
    if (orders[position].filled == orders[position].amount){
        deleteLimitOrder(_price, _ticker, opposite_listing);
    }

    // If the limit order (the one used to fill up the market order) is not fully filled, call the create limit order function to push it into the appropriate array.
    if(remainder_to_fill > 0) {
        createLimitOrder(_ticker, remainder_to_fill, _price, listing);
    }
    }

// Swap the assets depending on the passed listing parameter.
    function orderExchange(
        bytes32 _ticker,
        uint _amount,
        uint price,
        uint matched,
        uint position,
        Listing listing
    ) public {
    OrderRecorded[] storage orders = order_recorded[_ticker][uint(listing == Listing.SELL ? Listing.BUY : Listing.SELL)];

    if(listing == Listing.SELL) {
            
            // ERC20 asset deducted, supplement balance with JAT (performing SELL operation for msg.sender)
            trader_balance[msg.sender][_ticker] -= matched;
            trader_balance[msg.sender][JAT] += matched * price;

            // Add ERC20 asset, and deduct balance with JAT (performing BUY operation for the other party)
            trader_balance[orders[position].trader][_ticker] += matched;
            trader_balance[orders[position].trader][JAT] -= matched * price;
        } else {

            // Require that msg.sender has enough balance in JAT to buy the trade at the desired quantity.
            require(trader_balance[msg.sender][JAT] >= _amount * price, "JAT balance too low");

            // Add ERC20 asset, and deduct balance with JAT (performing BUY operation for msg.sender)
            trader_balance[msg.sender][JAT] -= matched * price;
            trader_balance[msg.sender][_ticker] += matched;

            // Deduct ERC20 asset, and add balance with JAT (performing SELL operation for the other party)
            trader_balance[orders[position].trader][_ticker] -= matched;
            trader_balance[orders[position].trader][JAT] += matched * price;
        }

        Order[] storage orderBook = order_book[counter];
        orderBook.push(Order(
            msg.sender,
            tokens[_ticker].token_address,
            matched,
            orders[position].trader,
            tokens[_ticker].token_address,
            matched * price,
            uint(keccak256(toBytes(block.timestamp + counter))),
            counter,
            block.number
        ));
        counter++;
    }

    function toBytes(uint256 x) public pure returns (bytes memory b) {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x) }
    }

    // Delete limit orders
    function deleteLimitOrder(
        uint _priceResult,
        bytes32 _ticker,
        uint listing
        ) private {
        OrderRecorded[] storage order_deletion = order_recorded[_ticker][listing];

        (,uint position_delete) = linearSearch(_ticker, listing, _priceResult);

        order_deletion[position_delete] = order_deletion[order_deletion.length - 1];
        order_deletion.pop();
    }


    // Delete market orders
    function deleteMarketOrders(
        bytes32 _ticker,
        uint listing
    ) private {
        OrderRecorded[] storage orders = order_recorded[_ticker][listing];
        uint j = 0;
        while(j < orders.length){
            if (orders[j].filled == orders[j].amount){
                orders[j] = orders[orders.length - 1];
                orders.pop();
            }
            j++;
        }
    }

    // Delete unfilled market orders
    function deleteUnfilledMarketOrders(
        bytes32 _ticker,
        uint listing
    ) private {
        Unfilled_MO[] storage unfilled_MO = unfilled_market_order[_ticker][listing];
        uint j = 0;
        while(j < unfilled_MO.length){
            if (unfilled_MO[j].filled == unfilled_MO[j].amount) {
            unfilled_MO[j] = unfilled_MO[unfilled_MO.length - 1];
            unfilled_MO.pop();
            }
            j++;
        }
    }

    // Linear search to find if the limit order price fits.
    function linearSearch(
        bytes32 _ticker,
        uint listing,
        uint _price
        ) public view returns (bool found, uint position) {
        OrderRecorded[] storage orders = order_recorded[_ticker][listing];
        uint i;
        for (i = 0; i < orders.length; i++) {
            if (orders[i].price == _price) {
            return(true, i);
            }
        }
        return(false, 0);
    }

    // Bubble sort operation to order the array.
    function bubbleSort(bytes32 _ticker, Listing listing) private {
        OrderRecorded[] storage orders = order_recorded[_ticker][uint(listing)];        
        uint i = orders.length - 1;

        while(i > 0) {
        if(listing == Listing.BUY && orders[i - 1].price > orders[i].price){
            break;
        }
        if(listing == Listing.SELL && orders[i - 1].price < orders[i].price){
            break;
        }

        OrderRecorded memory order = orders[i - 1];
        orders[i-1] = orders[i];
        orders[i] = order;
        i--;
        }
    }
  }

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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