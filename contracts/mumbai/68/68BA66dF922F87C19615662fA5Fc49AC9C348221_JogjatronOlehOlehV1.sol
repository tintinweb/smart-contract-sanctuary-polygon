// SPDX-License-Identifier: MIT
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

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Jogjatron oleh-oleh smart contract
 * @dev record data merchandize in and out
 */


contract JogjatronOlehOlehV1 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    uint256 public _profitRate;
    uint256 public _divider;
    address private owner;
    address private profit_address;
    address private JAGO_Token;

    enum shippingStatus { 
        Bought,        //0
        Shipped,     //1
        Completed     //2
    }

    struct Merch {
        string ipfs_metadata;
        bool selling_status;
        uint256 price;
        uint256 discount;
        uint256 stock_left;
    }

    mapping(uint256 => Merch) public merchandizeCollection;

    struct Transaction{
        string ipfs_shipping_metadata;
        uint256 item_id;
        uint256 total_amount;
        uint256 total_price;
        uint256 epoch_time;
        shippingStatus status;
    }
    mapping (uint => mapping(address => Transaction[])) public transactionMapping;

    event sell_from_admin(
        string indexed ipfs_metadata, 
        uint256 id,
        uint256 price, 
        uint256 initial_stock
    ); 

    event get_merch(
        string indexed ipfs_item_metadata,
        uint256 indexed quantity,
        uint256 price_after_discount,
        uint256 base_amount,
        uint256 profit_amount,
        uint256 timestamp
    );

    event update_status_shipping(
        uint256 indexed id,
        uint256 order_buy,
        address indexed buyer,
        shippingStatus status
    );

    event update_status_merch(
        uint256 indexed id,
        bool status
    );

    event add_stock(
        uint256 indexed id, 
        uint256 last_stock,
        uint256 additional_stock
    );

    constructor(address JAGO_address_, address profit_address_) {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        profit_address = profit_address_;
        JAGO_Token = JAGO_address_;

        _profitRate = 20;
        _divider = 100;
        
    }

    function addMerchandize(
        string memory ipfs_metadata_, 
        uint256 price_, 
        uint256 discount_,
        uint256 initial_stock_ ) public returns (uint256) {

        require(msg.sender != address(0), "JogjatronOleh2: selling from the zero address");
        require(msg.sender == owner, "Caller is not owner");
        require(discount_ <= 100, "Discount need to be less than or equal 100");
        uint256 id = _tokenIdCounter.current();

        _tokenIdCounter.increment();
        merchandizeCollection[id].ipfs_metadata = ipfs_metadata_;
        merchandizeCollection[id].selling_status = true;
        merchandizeCollection[id].price = price_;
        merchandizeCollection[id].discount = discount_;
        merchandizeCollection[id].stock_left = initial_stock_;

        emit sell_from_admin(ipfs_metadata_, id,  price_, initial_stock_);
        return id;
    }

    function getMerch(uint256 id_, uint256 amountToBuy, uint256 total_price_, string memory ipfs_shipping_metadata_) public {
        require(msg.sender != address(0), "JogjatronOleh2: buying from the zero address");
        require(total_price_ > 0, "JogjatronOleh2: Invalid Price");
        require(amountToBuy > 0, "JogjatronOleh2: Invalid amount to buy");
        
        Merch memory product = merchandizeCollection[id_];

        require(product.selling_status, "JogjatronOleh2: item is not available to sell");
        require(product.price * amountToBuy == total_price_, "JogjatronOleh2: Price mismatch");
        require(product.stock_left >= amountToBuy, "JogjatronOleh2: not enough stock");
        require(product.stock_left > 0, "JogjatronOleh2: no stock available");

        uint256 baseAmount;
        uint256 profitAmount;
        uint256 priceAfterDiscount;
        //calculate discount 
        if(product.discount > 0) {
            priceAfterDiscount = (100 - product.discount) * total_price_ / _divider;
        }
        //calculate profit
        if(_profitRate > 0) {                                                       
            profitAmount = (_profitRate * priceAfterDiscount) / _divider;
        }
        baseAmount = priceAfterDiscount - profitAmount;
        
        //transfer to this owner smart contract
        IERC20(JAGO_Token).transferFrom(msg.sender, owner, baseAmount);
        //transfer to profit address 
        IERC20(JAGO_Token).transferFrom(msg.sender, profit_address, profitAmount);
        
        transactionMapping[id_][msg.sender].push(Transaction(ipfs_shipping_metadata_, id_, amountToBuy, total_price_, block.timestamp, shippingStatus.Bought));
        
        merchandizeCollection[id_].stock_left = product.stock_left - amountToBuy;

        emit get_merch(product.ipfs_metadata, amountToBuy, priceAfterDiscount, baseAmount, profitAmount, block.timestamp);

    }

    function updateMerchStatus(uint256 id_, bool new_status_) public {
        require(msg.sender == owner, "Caller is not owner");
        merchandizeCollection[id_].selling_status = new_status_;

        emit update_status_merch(id_, new_status_);
    }

    function updateDiscount(uint256 id_, uint256 new_discount_) public {
        require(msg.sender == owner, "Caller is not owner");
        require(new_discount_ <= 100, "New discount need to be less than or equal 100");
        merchandizeCollection[id_].discount = new_discount_;
    }
    
    function updateStockLeft(uint256 id_, uint256 additional_stock_) public {
        require(msg.sender == owner, "Caller is not owner");
        require(additional_stock_ > 0, "JogjatronOleh2: Invalid additional stock");

        Merch memory product = merchandizeCollection[id_];
        merchandizeCollection[id_].stock_left = product.stock_left + additional_stock_;

        emit add_stock(id_, merchandizeCollection[id_].stock_left, additional_stock_);
    }

    function updateShippingStatus(uint256 id_, address buyer_, uint256 order_buy_, shippingStatus status_) public {
        require(msg.sender == owner, "Caller is not owner");
        transactionMapping[id_][buyer_][order_buy_].status = status_;

        emit update_status_shipping(id_, order_buy_, buyer_, status_);
    }
    
    function checkStockLeft(uint256 id_) public view returns (uint256) {
        uint256 stock_left = merchandizeCollection[id_].stock_left;
        return (stock_left);
    }

    function setProfitRate(uint256 profitRate_) public  {
        require(msg.sender == owner, "Caller is not owner");
        _profitRate = profitRate_;
    }

    function getProfitRate() public view virtual returns (uint256){
        return _profitRate;
    }
}