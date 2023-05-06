/**
 *Submitted for verification at polygonscan.com on 2023-05-06
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.8;

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

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.8;

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

// File: wavyescorwcontract.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;



/// @title WAVY P2P
/// @author Evarist Emmanuel

contract WAVYEscrow {
    using Counters for Counters.Counter;
    Counters.Counter public orderId;

    IERC20 private token;
    address feewalet = 0x2186030a127D970fa7B17E53F3fD8550D17394A5;
    address payable fee = payable(feewalet);

    uint256 public orderExpiry = 60 * 60 * 24; //Every order will get expired after 1 day

    // EVENTS
    event OrderPlaced(
        OrderTypes orderType,
        uint256 orderId,
        address indexed user,
        uint256 numberOfTokens,
        uint256 price,
        uint256 timestamp,
        uint256 deadline
    );

    event BidPlaced(
        uint256 orderId,
        address indexed bidder,
        uint256 price,
        uint256 timestamp
    );

    event TradeExecuted(
        uint256 orderId,
        address indexed user,
        address indexed bidder
    );

    // MODIFIERS
    modifier orderIdExists(uint256 _orderId) {
        uint256 currentOrderId = orderId.current();
        require(
            _orderId > 0 && _orderId <= currentOrderId,
            "Order Id does not exist"
        );
        _;
    }

    modifier sanityCheck(uint256 _numberOfTokens, uint256 _price) {
        require(_price > 0, "Price must be greater than zero");
        require(
            _numberOfTokens > 0,
            "Number of tokens should be greater than zero"
        );
        _;
    }

    // To avoid an address to create Order and Bid at the same time
    modifier bidExists(address _address) {
        require(
            biddersMapping[msg.sender].price == 0,
            "Bid already created from this address"
        );
        _;
    }

    // To avoid an address to create Order and Bid at the same time
    modifier orderExists(address _address) {
        require(
            usersMapping[msg.sender].price == 0,
            "Order is already created from this address"
        );
        _;
    }

    modifier isDeadlinePassed(uint256 _orderId) {
        require(
            orderIdtoOrder[_orderId].deadline > block.timestamp &&
                block.timestamp > orderIdtoOrder[_orderId].timestamp,
            "Deadline has passed"
        );
        _;
    }

    // STRUCTS
    struct Order {
        OrderTypes orderType;
        uint256 orderId;
        address user;
        uint256 numberOfTokens;
        uint256 price;
        uint256 amount;
        uint256 timestamp;
        uint256 deadline;
    }

    struct Bid {
        uint256 orderId;
        address bidder;
        uint256 price;
        uint256 timestamp;
    }

    // ENUMS
    enum OrderTypes {
        buyOrder,
        sellOrder
    }

    // MAPPINGS

    mapping(address => Order) public usersMapping; // Every Buy or Sell order is mapped to the user's address
    mapping(address => Bid) public biddersMapping; // Every Bid order is mapped to the bidder's address

    mapping(uint256 => Order) public orderIdtoOrder;
    mapping(uint256 => Bid[]) public orderIdToBidArray;

    constructor(address _token) {
        token = IERC20(_token);
    }

    // HELPER FUNCTIONS
    // Buy 10,000 tokens at 1000 tokensPerEther
    // Price = 10 token per ether
    function calculatePrice(uint256 _numberOfTokens, uint256 _tokensPerEther)
        public
        pure
        returns (uint256 _price)
    {
        _price = (1 ether / _tokensPerEther) * _numberOfTokens;
    }

    // Buy 10,000 tokens at 10 tokens per eth
    // Amount = 1000 ether
    function calculateAmount(uint256 _numberOfTokens, uint256 _price)
        public
        pure
        returns (uint256 _amount)
    {
        _amount = _numberOfTokens / _price;
    }

    // MAIN FUNCTIONS

    // CREATION OF AN ORDER
    function createOrder(
        OrderTypes _orderType,
        uint256 _numberOfTokens,
        uint256 _price
    )
        external
        sanityCheck(_numberOfTokens, _price)
        orderExists(msg.sender)
        bidExists(msg.sender)
    {
        orderId.increment();
        uint256 _orderId = orderId.current();

        uint256 _amount = calculateAmount(_numberOfTokens, _price);

        if (_orderType == OrderTypes.buyOrder) {
            payable(address(this)).transfer(_amount);
        } else {
            token.transferFrom(msg.sender, address(this), _numberOfTokens);
        }
        uint _deadline = block.timestamp + orderExpiry;

        orderIdtoOrder[_orderId] = Order(
            _orderType,
            _orderId,
            msg.sender,
            _numberOfTokens,
            _price,
            _amount,
            block.timestamp,
            _deadline
        );

        emit OrderPlaced(
            _orderType,
            _orderId,
            msg.sender,
            _numberOfTokens,
            _price,
            block.timestamp,
            _deadline
        );
    }

    // CREATION OF A BID
    function bid(
        uint256 _orderId,
        uint256 _numberOfTokens,
        uint256 _price
    )
        external
        orderIdExists(_orderId)
        sanityCheck(_numberOfTokens, _price)
        orderExists(msg.sender)
        bidExists(msg.sender)
        isDeadlinePassed(_orderId)
    {
        require(
            orderIdtoOrder[_orderId].numberOfTokens == _numberOfTokens,
            "You can bid for the same amount of Tokens"
        );

        OrderTypes _orderType = orderIdtoOrder[_orderId].orderType;

        if (_orderType == OrderTypes.buyOrder) {
            token.transferFrom(msg.sender, address(this), _numberOfTokens);
        } else {
            uint256 _amount = calculateAmount(_numberOfTokens, _price);
            payable(address(this)).transfer(_amount);
        }

        orderIdToBidArray[_orderId].push();
        _sortBidArray(_orderId);

        emit BidPlaced(_orderId, msg.sender, _price, block.timestamp);
    }

    // TRADE EXECUTION
    function executeTrade(uint256 _orderId, uint256 _index)
        external
        orderIdExists(_orderId)
        isDeadlinePassed(_orderId)
    {
        require(
            usersMapping[msg.sender].user == msg.sender,
            "You haven't created this order"
        );

        OrderTypes _orderType = orderIdtoOrder[_orderId].orderType;

        Bid[] memory bidArr = orderIdToBidArray[_orderId];
        address bidder = bidArr[_index].bidder;

        if (_orderType == OrderTypes.buyOrder) {
            token.transferFrom(
                address(this),
                msg.sender,
                orderIdtoOrder[_orderId].numberOfTokens
            );
            payable(bidder).transfer(orderIdtoOrder[_orderId].amount);
        } else {
            token.transferFrom(
                address(this),
                bidder,
                orderIdtoOrder[_orderId].numberOfTokens
            );
            payable(msg.sender).transfer(orderIdtoOrder[_orderId].amount);
        }

        emit TradeExecuted(_orderId, msg.sender, bidder);
    }

    // Sort bids in decending order
    function _sortBidArray(uint256 _orderId) internal {
        Bid[] storage bidArr = orderIdToBidArray[_orderId];

        uint256 l = bidArr.length;

        for (uint256 i = 0; i < l; i++) {
            for (uint256 j = i + 1; j < l; j++) {
                if (bidArr[i].price < bidArr[j].price) {
                    Bid memory x = bidArr[i];
                    bidArr[i] = bidArr[j];
                    bidArr[j] = x;
                }
            }
        }
    }
}