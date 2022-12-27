/**
 *Submitted for verification at polygonscan.com on 2022-12-27
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

// File: contracts/p2pMainnet-Test.sol



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

    address public feeReceiver;

    IERC20 ISLAMI = IERC20(0x9c891326Fd8b1a713974f73bb604677E1E63396D);
    IERC20 USDT = IERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
    IERC20 USDC = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);

    error notOk(string);

    uint256 public orN; //represents order number created
    uint256 public sellOrders;
    uint256 public buyOrders;
    uint256 public totalOrders;
    uint256 public maxOrders = 30;
    uint256 public canceledOrders;
    uint256 public ISLAMIinOrder;
    uint256 public USDinOrder;
    uint256 constant private ISLAMIdcml = 10**7;
    uint256 constant private USDdcml = 10**6;

    uint256 public activationFee = 1000*10**7;
    uint256 public p2pFee = 1;
    uint256 public feeFactor = 1000;

    uint256 _at = 1234;
    uint256 _cr = 32;

    struct orderDetails{
        //uint256 orderIndex;
        uint256 orderType; // 1 = sell , 2 = buy
        uint256 orderNumber;
        address sB; //seller or buyer
        IERC20 orderCurrency;
        uint256 orderFalseAmount;
        uint256 remainAmount;
        uint256 orderPrice;
        uint256 currencyFalseAmount;
        uint256 remainCurrency;
        uint256 orderLife;
        bool orderStatus; // represents if order is completed or not
    }

    event orderCreated(uint256 Order, uint256 Type, uint256 Amount, uint256 Price, IERC20 Currency);
    event orderCancelled(uint256 OrderNumber, uint256 OrderIndex, address User);

    mapping(address => orderDetails) public p2p;
    mapping(address => uint256) public monopoly;
    mapping(address => bool) public canCreateOrder;
    mapping(address => uint256) private isActivated;

    orderDetails[] public OrderDetails;
    /*
    @dev: prevent reentrancy when function is executed
*/
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    constructor(){
        feeReceiver = msg.sender;
        orN = 0;
    }
    function changeFee(uint256 _activationFee, uint256 _p2pFee, uint256 _feeFactor) external {
        require(msg.sender == feeReceiver, "Not authorized to change fee");
        require(_p2pFee >= 1 && _feeFactor >= 100,"Fee can't be zero");
        activationFee = _activationFee.mul(ISLAMIdcml);
        p2pFee = _p2pFee;
        feeFactor = _feeFactor;
    }
    function activateP2P() external nonReentrant{
        require(isActivated[msg.sender] != 1, "User P2P is already activated!");
        //require approve from ISLAMI smart contract
        ISLAMI.transferFrom(msg.sender, feeReceiver, activationFee);
        canCreateOrder[msg.sender] = true;
        isActivated[msg.sender] = 1;
    }
    function sampleOrder() external{
        _at += 536;
        _cr += 3;
        createOrder(1, _at, _cr, USDT);
    }
    function createOrder(
        uint256 _type, 
        uint256 _islamiAmount, 
        uint256 _currencyAmount, 
        IERC20 _currency
        ) 
        public 
        nonReentrant 
        returns(uint256 Order, uint256 Type)
        {
        /*if(totalOrders == maxOrders){
            superCancel();
        }*/
        require(monopoly[msg.sender] < block.timestamp, "Monopoly not allowed");
        require(canCreateOrder[msg.sender] == true, "User have an active order");
        require(_type == 1 || _type == 2, "Type not found (Buy or Sell)");
        totalOrders++;
        orN++;
        uint256 _price;
        uint256 _p2pFee;
        p2p[msg.sender].orderLife = block.timestamp.add(380);//(3 days);
        monopoly[msg.sender] = block.timestamp.add(440);//(4 days);
        p2p[msg.sender].orderNumber = orN;
        p2p[msg.sender].sB = msg.sender;
        p2p[msg.sender].orderType = _type;

        p2p[msg.sender].orderFalseAmount = _islamiAmount;
        p2p[msg.sender].orderCurrency = _currency;
        p2p[msg.sender].currencyFalseAmount = _currencyAmount;
        uint256 currencyAmount = _currencyAmount.mul(USDdcml);
        _price = currencyAmount.div(_islamiAmount);
        p2p[msg.sender].orderPrice = _price;
        if(_type == 1){ //sell ISLAMI
            p2p[msg.sender].remainAmount = _islamiAmount.mul(ISLAMIdcml);
            _p2pFee = _islamiAmount.mul(ISLAMIdcml).mul(p2pFee).div(feeFactor);
            //require approve from ISLAMICOIN contract
            ISLAMI.transferFrom(msg.sender, address(this), _islamiAmount.mul(ISLAMIdcml));
            ISLAMI.transferFrom(msg.sender, feeReceiver, _p2pFee);
            ISLAMIinOrder += _islamiAmount.mul(ISLAMIdcml);
            sellOrders++;
        }
        else if(_type == 2){ //buy ISLAMI
            p2p[msg.sender].remainCurrency = _currencyAmount.mul(USDdcml);
            _p2pFee = _currencyAmount.mul(USDdcml).mul(p2pFee).div(feeFactor);
            _currency.transferFrom(msg.sender, address(this), _currencyAmount.mul(USDdcml));
            _currency.transferFrom(msg.sender, feeReceiver, _p2pFee);
            USDinOrder += _currencyAmount.mul(USDdcml);
            buyOrders++;
        }
        OrderDetails.push(orderDetails
        (
                _type,
                orN, 
                msg.sender,
                _currency, 
                _islamiAmount.mul(ISLAMIdcml), 
                _islamiAmount.mul(ISLAMIdcml),
                _price,
                _currencyAmount.mul(USDdcml),
                _currencyAmount.mul(USDdcml),
                p2p[msg.sender].orderLife,
                false
                )
                );
        canCreateOrder[msg.sender] = false;
        emit orderCreated(orN, _type, _islamiAmount, _price, _currency);
        return (orN, _type);
    }
    function getOrders() public view returns (orderDetails[] memory){
        return OrderDetails;
    }
    function superCancel() public nonReentrant{
        uint256 _orderCancelled = 0;
        for(uint i = 0; i < OrderDetails.length; i++){
            if(OrderDetails[i].orderLife < block.timestamp){
                fixOrders(i);
                deleteOrder(OrderDetails[i].sB);
                canceledOrders++;
                _orderCancelled = 1;
            }
        }
        if(_orderCancelled != 1){
            revert notOk("Orders life is normal");
        }
    }
    function cancelOrder() external nonReentrant{
        uint256 _orderCancelled = 0;
        for(uint i = 0; i < OrderDetails.length; i++){
            if(OrderDetails[i].sB == msg.sender){
                fixOrders(i);
                deleteOrder(msg.sender);
                _orderCancelled = 1;
                //if(block.timestamp < p2p[msg.sender].orderLife.sub(410)){ // (45 hours){
                    monopoly[msg.sender] = block.timestamp.add(60);//(1 hours);
                //}
                break;
            }
        }
        if(_orderCancelled != 1){
            revert notOk("No user order found");
        }
        else{
            canceledOrders++;
        }
    }
    //user can cancel order and retrive remaining amounts
    function deleteOrder(address _orderOwner) internal{
        if(p2p[_orderOwner].orderType == 1){
            uint256 amount = p2p[_orderOwner].remainAmount;
            ISLAMI.transfer(_orderOwner, amount);
            sellOrders--;
        }
        else if(p2p[_orderOwner].orderType == 2){
            uint256 amount = p2p[_orderOwner].remainCurrency;
            IERC20 currency = p2p[_orderOwner].orderCurrency;
            currency.transfer(_orderOwner, amount);
            buyOrders--;
        }
        delete p2p[_orderOwner];
        canCreateOrder[_orderOwner] = true;
        //emit orderCancelled(_orderNumber, _orderIndex, msg.sender);
    }
    function fixOrders(uint256 _orderIndex) internal {
        OrderDetails[_orderIndex] = OrderDetails[OrderDetails.length - 1];
        OrderDetails.pop();
        totalOrders--;
    }
    function orderFilled() internal{
        for(uint i = 0; i < OrderDetails.length - 1; i++){
            if(OrderDetails[i].orderStatus == true){
                fixOrders(i);
            }
        }
    }
    //user can take full order or partial
    function takeOrder(address _orderOwner, uint256 _amount) external nonReentrant{
        IERC20 _currency = p2p[_orderOwner].orderCurrency;
        address seller = p2p[_orderOwner].sB;
        uint256 priceUSD = p2p[_orderOwner].orderPrice;
        uint256 toPay = _amount.mul(priceUSD);//.mul(ISLAMIdcml);
        uint256 amountUSD = _amount.mul(USDdcml);
        uint256 amountISLAMI = _amount.mul(ISLAMIdcml);
        uint256 toReceive = amountUSD.div(priceUSD).mul(ISLAMIdcml);
        uint256 _p2pFee;
        require(_currency.balanceOf(msg.sender) >= toPay, "Not enought USD");
        require(p2p[_orderOwner].orderStatus != true, "Order was completed");
        if(p2p[_orderOwner].orderType == 1){//Take sell
        require(amountISLAMI <= p2p[_orderOwner].remainAmount, "Seller has less ISLAMI than order");
        _p2pFee = amountISLAMI.mul(p2pFee).div(feeFactor);
        ISLAMI.transfer(feeReceiver, _p2pFee);
        ISLAMIinOrder -= amountISLAMI;
        p2p[_orderOwner].remainAmount -= amountISLAMI;
        //require approve from currency(USDT, USDC) contract
        _currency.transferFrom(msg.sender, seller, toPay);
        ISLAMI.transfer(msg.sender, amountISLAMI.sub(_p2pFee));
          if(amountISLAMI == p2p[_orderOwner].remainAmount){
                p2p[_orderOwner].orderStatus = true;
                canCreateOrder[p2p[_orderOwner].sB] = true;
                orderFilled();
                sellOrders--;
            }
        }
        else if(p2p[_orderOwner].orderType == 2){//Take buy
        require(amountUSD <= p2p[_orderOwner].remainCurrency, "Seller has less USD than order");
        _p2pFee = amountUSD.mul(p2pFee).div(feeFactor);
        _currency.transfer(feeReceiver, _p2pFee);
        USDinOrder -= amountUSD;
        p2p[_orderOwner].remainCurrency -= amountUSD;
        //require approve from ISLAMICOIN contract
        ISLAMI.transferFrom(msg.sender, seller, toReceive);
        _currency.transfer(msg.sender, amountUSD.sub(_p2pFee));
          if(amountUSD == p2p[_orderOwner].remainCurrency){
                p2p[_orderOwner].orderStatus = true;
                canCreateOrder[p2p[_orderOwner].sB] = true;
                orderFilled();
                buyOrders--;
            }
        }
    }
}