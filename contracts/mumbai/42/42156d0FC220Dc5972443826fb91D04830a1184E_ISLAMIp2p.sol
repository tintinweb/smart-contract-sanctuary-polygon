/**
 *Submitted for verification at polygonscan.com on 2022-12-15
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.17;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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

// File: contracts/ISLAMIp2pTest.sol



/*
@dev: P2P smart contract ISLAMI
*/



pragma solidity = 0.8.17;
   using SafeMath for uint256;
 
contract ISLAMIp2p {

/*
@dev: Private values
*/  
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;


    IERC20 ISLAMI;
    IERC20 USDT;
    IERC20 USDC;

    error notOk();

    uint256 public orN; //represents order number created
    uint256 public ISLAMIinOrder;
    uint256 public USDinOrder;
    uint256 constant private ISLAMIdcml = 10**7;
    uint256 constant private USDdcml = 10**6;

    struct orderDetails{
        uint256 orderNumber;
        address sB; //seller or buyer
        uint256 orderType; // 1 = sell , 2 = buy
        IERC20 orderCurrency;
        uint256 orderFalseAmount;
        uint256 remainAmount;
        uint256 orderPrice;
        uint256 currencyFalseAmount;
        uint256 remainCurrency;
        bool orderStatus; // represents if order is completed or not
    }

    event orderCreated(uint256 Order, uint256 Type, uint256 Amount, uint256 Price, IERC20 Currency);


    //mapping(address => orderDetails) public orders;
    //mapping(uint256 => mapping(address => orderDetails)) public p2pI;
    mapping(uint256 => orderDetails) public p2p;
    mapping(address => uint256) public userOrder;
    mapping(address => bool) public canCreateOrder;
    mapping(address => uint256) private isActivated;
    /*
    @dev: prevent reentrancy when function is executed
*/
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    constructor(IERC20 _ISLAMI, IERC20 _USDT, IERC20 _USDC){
        ISLAMI = _ISLAMI;
        USDT = _USDT;
        USDC = _USDC;
        orN = 0;
    }
    function activateP2P() external nonReentrant{
        require(isActivated[msg.sender] != 1, "User P2P is already activated!");
        canCreateOrder[msg.sender] = true;
        isActivated[msg.sender] = 1;
    }
    function createOrder(
        uint256 _type, 
        uint256 _amount, 
        uint256 _currencyAmount, 
        IERC20 _currency
        ) 
        external 
        nonReentrant 
        returns(uint256 Order, uint256 Type)
        {
        require(canCreateOrder[msg.sender] == true, "User have an active order");
        require(_type == 1 || _type == 2, "Type not found (Buy or Sell)");
        orN++;
        uint256 _price;

        userOrder[msg.sender] = orN;
        p2p[orN].orderNumber = orN;
        p2p[orN].sB = msg.sender;
        p2p[orN].orderType = _type;

        p2p[orN].orderFalseAmount = _amount;
        p2p[orN].remainAmount = _amount.mul(ISLAMIdcml);
        p2p[orN].orderCurrency = _currency;
        p2p[orN].currencyFalseAmount = _currencyAmount;
        uint256 currencyAmount = _currencyAmount.mul(USDdcml);
        //uint256 amount = _amount.mul()
        if(_type == 1){ //sell ISLAMI
            _price = currencyAmount.div(_amount);
            
            p2p[orN].orderPrice = _price;
            //require approve from ISLAMICOIN contract
            ISLAMI.transferFrom(msg.sender, address(this), _amount.mul(ISLAMIdcml));
            ISLAMIinOrder += _amount.mul(ISLAMIdcml);
        }
        else if(_type == 2){ //buy ISLAMI
            _price = _currencyAmount;//.mul(_amount).mul(ISLAMIdcml);
            p2p[orN].orderPrice = _price;
            //require approve from currency(USDT, USDC) contract
            _currency.transferFrom(msg.sender, address(this), _currencyAmount.mul(USDdcml));
            USDinOrder += _currencyAmount.mul(USDdcml);
        }
        canCreateOrder[msg.sender] = false;
        emit orderCreated(orN, _type, _amount, _price, _currency);
        return (orN, _type);
    }
    //user can cancel order and retrive remaining amounts
    function cancleOrder() external nonReentrant{
        uint256 _orderNumber = userOrder[msg.sender];
        if(p2p[_orderNumber].orderType == 1){
            uint256 amount = p2p[_orderNumber].remainAmount;
            ISLAMI.transfer(msg.sender, amount);
        }
        else if(p2p[_orderNumber].orderType == 2){
            uint256 amount = p2p[_orderNumber].remainCurrency;
            IERC20 currency = p2p[_orderNumber].orderCurrency;
            currency.transfer(msg.sender, amount);
        }
        delete p2p[_orderNumber];
        canCreateOrder[msg.sender] = true;
    }
    //user can take full order or partial
    function takeOrder(uint256 _orN, uint256 _amount) external nonReentrant{
        IERC20 _currency = p2p[_orN].orderCurrency;
        address seller = p2p[_orN].sB;
        uint256 priceUSD = p2p[_orN].orderPrice;
        uint256 toPay = _amount.mul(priceUSD);//.mul(ISLAMIdcml);
        //uint256 amount = p2p[_orN].orderFalseAmount.mul(ISLAMIdcml);
        uint256 toReceive = _amount.div(priceUSD).mul(ISLAMIdcml);
        require(_currency.balanceOf(msg.sender) >= toPay, "Not enought USD");
        require(p2p[_orN].orderStatus != true, "Order was completed");
        if(p2p[_orN].orderType == 1){//Take sell
        require(_amount.mul(ISLAMIdcml) <= p2p[_orN].remainAmount, "Seller has less ISLAMI than order");
            if(_amount.mul(ISLAMIdcml) < p2p[_orN].remainAmount){
                p2p[_orN].remainAmount -= _amount.mul(ISLAMIdcml);
                //require approve from currency(USDT, USDC) contract
                _currency.transferFrom(msg.sender, seller, toPay);
                ISLAMI.transfer(msg.sender, _amount.mul(ISLAMIdcml));
                ISLAMIinOrder -= _amount.mul(ISLAMIdcml);
            }
            else if(_amount.mul(ISLAMIdcml) == p2p[_orN].remainAmount){
                p2p[_orN].remainAmount = 0;
                //require approve from currency(USDT, USDC) contract
                _currency.transferFrom(msg.sender, seller, toPay);
                ISLAMI.transfer(msg.sender, _amount.mul(ISLAMIdcml));
                ISLAMIinOrder -= _amount.mul(ISLAMIdcml);
                p2p[_orN].orderStatus = true;
                canCreateOrder[p2p[_orN].sB] = true;
            }
            else{
                revert notOk();
            }
        }
        else if(p2p[_orN].orderType == 2){//Take buy
        require(_amount.mul(USDdcml) <= p2p[_orN].remainCurrency, "Seller has less USD than order");
            if(_amount.mul(USDdcml) < p2p[_orN].remainCurrency){
                p2p[_orN].remainCurrency -= _amount.mul(USDdcml);
                //require approve from ISLAMICOIN contract
                ISLAMI.transferFrom(msg.sender, seller, toReceive);
                _currency.transfer(seller, _amount.mul(USDdcml));
                USDinOrder -= _amount.mul(USDdcml);
            }
            else if(_amount.mul(USDdcml) == p2p[_orN].remainCurrency){
                p2p[_orN].remainCurrency -= _amount.mul(USDdcml);
                //require approve from ISLAMICOIN contract
                ISLAMI.transferFrom(msg.sender, seller, toReceive);
                _currency.transfer(seller, _amount.mul(USDdcml));
                USDinOrder -= _amount.mul(USDdcml);
                p2p[_orN].orderStatus = true;
                canCreateOrder[p2p[_orN].sB] = true;
            }
            /*else{
                return();
            }*/
        }
        /*else{
            return();
        }*/
    }

}