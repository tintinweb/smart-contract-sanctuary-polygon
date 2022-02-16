// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MaticToKmMarket is Ownable{

    event swapEvent(address owner_address, address from, uint256 from_amount, address to, uint256 to_amount, address share);
    event outEvent(address owner_address, address token, address to, uint256 amount);
    event liquidityCreate(address owner_address, address from, uint256 from_amount, address to, uint256 to_amount);
    event liquidityIn(address owner_address, address from, uint256 from_amount, address to, uint256 to_amount);
    event liquidityOut(address owner_address, address from, uint256 from_amount, address to, uint256 to_amount);
    event liquidityExecute(address owner_address, address from, uint256 from_amount, address to, uint256 to_amount, uint256 fee_reward);
    event liquidityUpdate(address from, uint256 from_amount, address to, uint256 to_amount);
    event feeUpdate(uint256 amount);

    address za = address(0);
    address ca = address(this);

    address public pairFrom = address(0);
    address public pairTo   = address(0);

    address public teamAddress = address(0);
    address public destroyAddress = address(0);

    uint256 public buyPercent = 7;
    uint256 public sellPercent = 7;
    uint256 public teamPercent = 25;
    uint256 public destroyPercent = 5;

    uint256 public feeTotal = 0;
    uint256 public teamFeeTotal = 0;
    uint256 public destroyFeeTotal = 0;

    constructor(){

    }

    function setAddress(address _pairFrom, address _pairTo, address _teamAddress, address _destroyAddress) external onlyOwner {
        pairFrom = _pairFrom;
        pairTo = _pairTo;
        teamAddress = _teamAddress;
        destroyAddress = _destroyAddress;
    }

    function setPercent(uint256 _buyPercent, uint256 _sellPercent, uint256 _teamPercent, uint256 _destroyPercent) external onlyOwner {
        buyPercent = _buyPercent;
        sellPercent = _sellPercent;
        teamPercent = _teamPercent;
        destroyPercent = _destroyPercent;
    }

    function swap(address from, address to, uint256 amount, address share) payable public{

        require((from == pairFrom || from == pairTo), "Token not specified");
        require((to == pairFrom || to == pairTo), "Token not specified");
        require((from != to), "Token not specified");

        //A池金额
        uint256 leftTotal = ca.balance;

        //B池金额
        uint256 rightTotal = IERC20(pairTo).balanceOf(ca);

        //B池减去手续费总额
        rightTotal = rightTotal - feeTotal;

        //兑换金额
        uint256 swapAmount;
        if(from == pairFrom){
            require(msg.value > 0, "You need to send some matic");
            swapAmount = msg.value;
        }else{
            swapAmount = amount;

            //扣除From金额
            uint256 allowance = IERC20(from).allowance(msg.sender, ca);
            require(allowance >= swapAmount, "Check the token allowance");
            IERC20(from).transferFrom(msg.sender, ca, swapAmount);
        }

        //减去本次收到金额
        if(from == pairFrom){
            leftTotal = leftTotal - swapAmount;
        }else{
            rightTotal = rightTotal - swapAmount;
        }

        //计算可获得总额
        uint256 swapNumber;

        //买入
        uint256 fee = 0;
        if(from == pairFrom){
            unchecked{
                swapNumber = (leftTotal * rightTotal) / (leftTotal + (swapAmount));
                swapNumber = rightTotal - swapNumber;

                //买入手续费是扣除B池支出
                if(buyPercent > 0){
                    fee = swapNumber * buyPercent / 100;
                }
                if(fee > 0){
                    swapNumber = swapNumber - fee;
                }
            }
        }
        //卖出
        else{
            unchecked{

                //卖出手续费是减少B池投入
                if(sellPercent > 0){
                    fee = swapAmount * sellPercent / 100;
                }

                swapNumber = (leftTotal * rightTotal) / (rightTotal + (swapAmount - fee));
                swapNumber = leftTotal - swapNumber;
            }
        }

        //发放兑换数量
        if(to == za){
            payable(msg.sender).transfer(swapNumber);
        }else{
            IERC20(to).transfer(msg.sender, swapNumber);
        }

        //分发手续费
        if(fee > 0){
            uint256 teamFee = 0;
            uint256 destroyFee = 0;
            unchecked{
                teamFee = fee * teamPercent / 100;
            }
            if(teamFee > 0 && teamAddress != za){
                IERC20(pairTo).transfer(teamAddress, teamFee);
            }
            unchecked{
                destroyFee = fee * destroyPercent / 100;
            }
            if(destroyFee > 0){
                IERC20(pairTo).transfer(destroyAddress, destroyFee);
            }
            feeTotal = feeTotal + (fee - teamFee - destroyFee);
            teamFeeTotal = teamFeeTotal + teamFee;
            destroyFeeTotal = destroyFeeTotal + destroyFee;
            emit feeUpdate((fee - teamFee - destroyFee));
        }

        emit swapEvent(msg.sender, from, swapAmount, to, swapNumber, share);
        setUpdate();
    }

    function swapOut(address token, address to, uint256 amount) external onlyOwner {

        if(address(0) == token){
            payable(to).transfer(amount);
        }else{
            IERC20(token).transfer(to, amount);
        }

        setUpdate();
    }

    function createLiquidity(address from, uint256 from_amount, address to, uint256 to_amount) payable external onlyOwner {

        require((from == pairFrom && to == pairTo), "Token not specified");

        if(from == za){
            from_amount = msg.value;
        }else{
            uint256 allowance = IERC20(from).allowance(msg.sender, ca);
            require(allowance >= from_amount, "Check the token allowance");
            IERC20(from).transferFrom(msg.sender, ca, from_amount);
        }

        if(to == za){
            to_amount = msg.value;
        }else{
            uint256 allowance = IERC20(to).allowance(msg.sender, ca);
            require(allowance >= to_amount, "Check the token allowance");
            IERC20(to).transferFrom(msg.sender, ca, to_amount);
        }

        emit liquidityCreate(msg.sender, from, from_amount, to, to_amount);
        setUpdate();
    }

    function addLiquidity(address from, address to) payable public {

        require((from == pairFrom && to == pairTo), "Token not specified");

        //验证A池收款
        require(msg.value > 0, "You need to send some matic");

        //A池总额
        uint256 lq = ca.balance - msg.value;

        //A池投入金额
        uint256 la = msg.value;

        //B池
        uint256 rq = IERC20(pairTo).balanceOf(ca);

        //B池减去手续费总额
        rq = rq - feeTotal;

        //B池投入金额
        uint256 ra;

        unchecked {
            ra = la * rq / lq;
        }

        //验证A池收款
        require(ra > 0, "You need to send some matic");

        //验证和扣除B池
        uint256 allowance = IERC20(pairTo).allowance(msg.sender, ca);
        require(allowance >= ra, "Check the token allowance");
        IERC20(pairTo).transferFrom(msg.sender, ca, ra);

        emit liquidityIn(msg.sender, from, la, to, ra);
        setUpdate();
    }

    function removeLiquidity(address from, address to) public {

        require((from == pairFrom && to == pairTo), "Token not specified");

        emit liquidityOut(msg.sender, from, ca.balance, to, IERC20(pairTo).balanceOf(ca) - feeTotal);

    }

    function removeLiquidityExecute(address from, uint256 from_amount, address to, uint256 to_amount, uint256 fee_reward, address owner_address) external onlyOwner {

        require((from == pairFrom && to == pairTo), "Token not specified");

        if(from == za){
            payable(owner_address).transfer(from_amount);
        }else{
            IERC20(from).transfer(owner_address, from_amount);
        }

        if(to == za){
            payable(owner_address).transfer(to_amount);
        }else{
            IERC20(to).transfer(owner_address, (to_amount + fee_reward));
        }

        if(fee_reward > 0){
            feeTotal = feeTotal - fee_reward;
        }

        emit liquidityExecute(owner_address, from, from_amount, to, to_amount, fee_reward);
        setUpdate();
    }

    function setUpdate() private{
        uint256 lq = ca.balance;
        uint256 rq = IERC20(pairTo).balanceOf(ca);
        rq = rq - feeTotal;
        emit liquidityUpdate(pairFrom, lq, pairTo, rq);
    }

    function getFromLiquidity() public view returns (uint256){
        uint256 lq = ca.balance;
        return lq;
    }

    function getToLiquidity() public view returns (uint256){
        uint256 rq = IERC20(pairTo).balanceOf(ca);
        rq = rq - feeTotal;
        return rq;
    }

    function getFeeTotal() public view returns (uint256){
        return feeTotal;
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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