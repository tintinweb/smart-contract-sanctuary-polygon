// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title A contract for LeskoDEX.
 * NOTE: The contract of DEX with a decentralized orderbook and a custom ERC-20 token.
 */
contract LESKOdex {
    struct Order {
        uint256 id;
        address user;
        address tokenGet;
        uint256 amountGet;
        address tokenGive;
        uint256 amountGive;
        uint256 timestamp;
    }

    address public constant ETHER = address(0); //allows as to store Ether in tokens mapping with blank address
    address private _feeAccount; // the acccount that receives exchange fees
    uint256 private _feePercent; // the fee percentage
    uint256 private _orderCount;

    // Mapping from token address to mapping from user address to amount of tokens.
    mapping(address => mapping(address => uint256)) private _tokens;
    // Mapping from order Id to Order object.
    mapping(uint256 => Order) private _orders;
    // Mapping from order Id to bool ( whether the order was canceled ).
    mapping(uint256 => bool) private _orderCancelled;
    // Mapping from order Id to bool ( whether the order was filled ).
    mapping(uint256 => bool) private _orderFilled;

    /**
     * @dev Emitted when the user deposits the tokens to the exchange.
     * @param token address of the deposited token.
     * @param user address of the user that deposited tokens.
     * @param amount amount of deposited tokens.
     * @param balance the exchange balance of these user tokens after deposit.
     */
    event Deposit(address token, address user, uint256 amount, uint256 balance);
    /**
     * @dev Emitted when the user withdraws the tokens from the exchange.
     * @param token the address of the token to be withdrawn.
     * @param user address of the user to whom funds are withdrawn.
     * @param amount amount of withdrawn tokens.
     * @param balance the exchange balance of these user tokens after withdrawn.
     */
    event Withdraw(address token, address user, uint256 amount, uint256 balance);
    /**
     * @dev Emitted when the user create an order.
     * @param id order count id.
     * @param user address of the user that create this order.
     * @param tokenGet the address of the token that the user wants to get.
     * @param amountGet the amount of `tokenGet` token user wants to get.
     * @param tokenGive the address of the token that the user wants to give.
     * @param amountGive the amount of `tokenGive` token user wants to give.
     * @param timestamp time of order creation.
     */
    event OrderCreated(
        uint256 id,
        address user,
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        uint256 timestamp
    );
    /**
     * @dev Emitted when the user cancel an order.
     * @param id id of the cancelled order.
     * @param user address of the user that cancelled this order.
     * @param tokenGet the address of the token that the user wanted to get previously.
     * @param amountGet the amount of `tokenGet` token user wanted to get previously.
     * @param tokenGive the address of the token that the user wanted to give previously.
     * @param amountGive the amount of `tokenGive` token user wanted to give previously.
     * @param timestamp time of order cancelling.
     */
    event OrderCancelled(
        uint256 id,
        address user,
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        uint256 timestamp
    );
    /**
     * @dev Emitted when the trade happened.
     * @param id id of the filled order.
     * @param user address of the user that create this order.
     * @param tokenGet the address of the token that user received.
     * @param amountGet the amount of `tokenGet` token user received.
     * @param tokenGive the address of the token that the user gived.
     * @param amountGive the amount of `tokenGive` token user gived.
     * @param userFill address of the user that maked this deal with `user`.
     * @param timestamp time of the transaction.
     */
    event OrderFilled(
        uint256 id,
        address user,
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        address userFill,
        uint256 timestamp
    );

    /**
     * @dev Sets up the `_feeAccount` and `_feePercent`.
     * @param feeAccount_ the address to which all fees will be transferred.
     * @param feePercent_ percentage of fees from each transaction to be charged.
     */
    constructor(address feeAccount_, uint256 feePercent_) {
        require(feeAccount_ != address(0), "Fee account cannot be address zero");
        require(feePercent_ != 0, "Fee percent canot be zero");
        _feeAccount = feeAccount_;
        _feePercent = feePercent_;
    }

    /// @dev Fallback: reverts if Ether is sent to this smart contract by mistake
    fallback() external payable {
        depositEther();
    }

    receive() external payable {
        depositEther();
    }

    /**
     * @dev The function allows users to deposit Ether to exchange.
     *
     * Requirements:
     *
     * - `msg.value` cannot be zero.
     *
     * Emits a {Deposit} event.
     */
    function depositEther() public payable {
        require(msg.value != 0, "Value cannot be zero");
        _tokens[ETHER][msg.sender] = _tokens[ETHER][msg.sender] + (msg.value);
        emit Deposit(ETHER, msg.sender, msg.value, _tokens[ETHER][msg.sender]);
    }

    /**
     * @dev The function allows users to withdraw Ether from exchange.
     *
     * Requirements:
     *
     * - `amount_` cannot be zero.
     * - user must have enough `amount_` of `ETHER` in `_tokens` mapping.
     *
     * @param amount_ the amount of ETH to be withdrawn.
     *
     * Emits a {Withdraw} event.
     */
    function withdrawEther(uint256 amount_) public {
        require(amount_ != 0, "Value cannot be zero");
        require(_tokens[ETHER][msg.sender] >= amount_);
        _tokens[ETHER][msg.sender] = _tokens[ETHER][msg.sender] - (amount_);
        payable(msg.sender).transfer(amount_);
        emit Withdraw(ETHER, msg.sender, amount_, _tokens[ETHER][msg.sender]);
    }

    /**
     * @dev The function allows users to deposit erc-20 tokens to exchange.
     *
     * Requirements:
     *
     * - `token_` address cannot be `ETHER` ( or address(0) ) address.
     * - `msg.sender` required to approve amount of `token_` to be deposited to this contract.
     *
     * @param token_ address of the token to be deposited.
     * @param amount_ the amount of `token_` to be deposited.
     *
     * Emits a {Deposit} event.
     */
    function depositToken(address token_, uint256 amount_) public {
        //Don't allow ETHER deposits
        require(token_ != ETHER, "ERC20 cannot be address zero");
        // Send tokens to this contract
        IERC20(token_).transferFrom(msg.sender, address(this), amount_);
        // Manage deposit - update balance
        _tokens[token_][msg.sender] = _tokens[token_][msg.sender] + (amount_);
        // Emit event
        emit Deposit(token_, msg.sender, amount_, _tokens[token_][msg.sender]);
    }

    /**
     * @dev The function allows users to withdraw erc-20 tokens from exchange.
     *
     * Requirements:
     *
     * - `token_` address cannot be `ETHER` ( or address(0) ) address.
     * - user must have enough `amount_` of `token_` in `_tokens` mapping.
     *
     * @param token_ erc-20 token address for withdrawal.
     * @param amount_ the amount of `token_` to be withdrawn.
     *
     * Emits a {Withdraw} event.
     */
    function withdrawToken(address token_, uint256 amount_) public {
        require(token_ != ETHER, "ERC20 cannot be address zero");
        require(_tokens[token_][msg.sender] >= amount_);
        _tokens[token_][msg.sender] = _tokens[token_][msg.sender] - (amount_);
        IERC20(token_).transfer(msg.sender, amount_);
        emit Withdraw(token_, msg.sender, amount_, _tokens[token_][msg.sender]);
    }

    /**
     * @dev Returns the balance of an individual token of an individual user.
     * @param token_ address of token or Ether internal address to be explored.
     * @param user_ user's address to check the amount of `token_` they has on the exchange.
     */
    function balanceOf(address token_, address user_) public view returns (uint256) {
        return _tokens[token_][user_];
    }

    /**
     * @dev The function allows users to create and add orders to orderbook.
     *
     * Requirements:
     *
     * - `amountGet_` cannot be zero.
     * - `amountGive_` cannot be zero.
     *
     * @param tokenGet_ the address of the token that the user wants to get.
     * @param amountGet_ the amount of `tokenGet` token user wants to get.
     * @param tokenGive_ the address of the token that the user wants to give.
     * @param amountGive_ the amount of `tokenGive` token user wants to give.
     *
     * Emits a {OrderCreated} event.
     */
    function makeOrder(
        address tokenGet_,
        uint256 amountGet_,
        address tokenGive_,
        uint256 amountGive_
    ) public {
        require(amountGet_ != 0, "Getting amount cannot be zero");
        require(amountGive_ != 0, "Giving amount cannot be zero");
        _orderCount = _orderCount + 1;
        _orders[_orderCount] = Order(
            _orderCount,
            msg.sender,
            tokenGet_,
            amountGet_,
            tokenGive_,
            amountGive_,
            block.timestamp
        );
        emit OrderCreated(_orderCount, msg.sender, tokenGet_, amountGet_, tokenGive_, amountGive_, block.timestamp);
    }

    /**
     * @dev The function allows users to cancel and remove their own orders from orderbook.
     *
     * Requirements:
     *
     * - `msg.sender` must be the creator of `id_` order.
     * - the order must exist.
     *
     * @param id_ id of the order to be removed from orderbook.
     *
     * Emits a {OrderCancelled} event.
     */
    function cancelOrder(uint256 id_) public {
        Order storage order = _orders[id_];
        require(address(order.user) == msg.sender);
        require(order.id == id_);
        _orderCancelled[id_] = true;
        emit OrderCancelled(
            order.id,
            msg.sender,
            order.tokenGet,
            order.amountGet,
            order.tokenGive,
            order.amountGive,
            block.timestamp
        );
    }

    /**
     * @dev The function allows users to filled orders and make trades.
     *
     * Requirements:
     *
     * - the order must exist and `id_` of order cannot be higher than `_orderCount`.
     * - order cannot be filled already.
     * - order cannot be cancelled already.
     *
     * @param id_ id of the order to be filled.
     *
     * Emits a {OrderFilled} event.
     */
    function fillOrder(uint256 id_) public {
        require(id_ > 0 && id_ <= _orderCount, "The order must exist");
        require(!_orderFilled[id_], "The order cannot be filled already");
        require(!_orderCancelled[id_], "The order cannot be cancelled already");
        Order storage order = _orders[id_];
        _trade(order.id, order.user, order.tokenGet, order.amountGet, order.tokenGive, order.amountGive);
        _orderFilled[order.id] = true;
    }

    /**
     * @dev The trade function with charging fees from users.
     *
     * Requirements:
     *
     * - Fee paid by the user that fills the order, so `msg.sender` must have enough tokens to cover exchange fees.
     *
     * @param id_ id of the order to be filled.
     * @param user_ the address of the creator of the order.
     * @param tokenGet_ the address of the token that the `user_` wants to get and `msg.sender` wants to give.
     * @param amountGet_ the amount of `tokenGet` token `user_` wants to get and `msg.sender` wants to give.
     * @param tokenGive_ the address of the token that the `user_` wants to give and `msg.sender` wants to get.
     * @param amountGive_ the amount of `tokenGive` token `user_` wants to give and `msg.sender` wants to get.
     *
     * Emits a {OrderFilled} event.
     */
    function _trade(
        uint256 id_,
        address user_,
        address tokenGet_,
        uint256 amountGet_,
        address tokenGive_,
        uint256 amountGive_
    ) internal {
        uint256 _feeAmount = (amountGet_ * (_feePercent)) / (100);
        require(_tokens[tokenGet_][msg.sender] >= amountGet_ + _feeAmount, "Not enough tokens to cover exchange fees");
        _tokens[tokenGet_][msg.sender] = _tokens[tokenGet_][msg.sender] - (amountGet_ + (_feeAmount));
        _tokens[tokenGet_][user_] = _tokens[tokenGet_][user_] + (amountGet_);
        _tokens[tokenGet_][_feeAccount] = _tokens[tokenGet_][_feeAccount] + (_feeAmount);
        _tokens[tokenGive_][user_] = _tokens[tokenGive_][user_] - (amountGive_);
        _tokens[tokenGive_][msg.sender] = _tokens[tokenGive_][msg.sender] + (amountGive_);
        emit OrderFilled(id_, user_, tokenGet_, amountGet_, tokenGive_, amountGive_, msg.sender, block.timestamp);
    }
}

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