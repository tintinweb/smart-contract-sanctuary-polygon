/**
 *Submitted for verification at polygonscan.com on 2022-02-06
*/

/*
SPDX-License-Identifier: MIT

─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
─██████████████─██████████████─██████████████─████████████████───██████████████─██████████████─██████████████─████████████───
─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░░░░░██───██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░████─
─██░░██████████─██████░░██████─██░░██████░░██─██░░████████░░██───██░░██████████─██░░██████████─██░░██████████─██░░████░░░░██─
─██░░██─────────────██░░██─────██░░██──██░░██─██░░██────██░░██───██░░██─────────██░░██─────────██░░██─────────██░░██──██░░██─
─██░░██████████─────██░░██─────██░░██████░░██─██░░████████░░██───██░░██████████─██░░██████████─██░░██████████─██░░██──██░░██─
─██░░░░░░░░░░██─────██░░██─────██░░░░░░░░░░██─██░░░░░░░░░░░░██───██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░██──██░░██─
─██████████░░██─────██░░██─────██░░██████░░██─██░░██████░░████───██████████░░██─██░░██████████─██░░██████████─██░░██──██░░██─
─────────██░░██─────██░░██─────██░░██──██░░██─██░░██──██░░██─────────────██░░██─██░░██─────────██░░██─────────██░░██──██░░██─
─██████████░░██─────██░░██─────██░░██──██░░██─██░░██──██░░██████─██████████░░██─██░░██████████─██░░██████████─██░░████░░░░██─
─██░░░░░░░░░░██─────██░░██─────██░░██──██░░██─██░░██──██░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░████─
─██████████████─────██████─────██████──██████─██████──██████████─██████████████─██████████████─██████████████─████████████───
─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

                                        Copyright (c) 2021 Kyle Marshall
*/

pragma solidity ^0.8.9;

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


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity 0.8.9;

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


// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

pragma solidity 0.8.9;

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




contract starSeed is Ownable{
    using SafeMath for uint256;

    uint256 public depositFee = 5; // the current deposit fee
    uint256 public prevDepositFee = 0; // the previous deposit fee
    uint256 public collectedFees = 0; // the previous deposit fee
    uint256 public withdrawLimit = 5000; //max wihtdraw wihtout approval
    address public starAddress = 0x7Ba798157147e37Dc4c54bDFa2aF013BAf3C02c2;
    address public prevStarAddress = 0x0000000000000000000000000000000000000000;
    IERC20 private star;

    //map variables for tracking users deposits.
    mapping (address => uint256) public starAllowance; // user Star allowance
    mapping (address => uint256) public pendingWithdraw; // user pending withdraw

    //events emited to the blockchain
    event depositFeeChange(uint256 oldFee, uint256 newFee); //emit a event if the deposit fees for the contract are changed.
    event starContractChange(address oldAddress, address newAddress); //emit a event if the Star token address is changed.
    
    constructor() {
        star = IERC20(starAddress);
        }

    //Set the contract address for Star Token
    function setStarContractAddress(address _address) external onlyOwner {
        address oldAddress = prevStarAddress;
        prevStarAddress = starAddress;
        starAddress = _address;
        star = IERC20(_address);
        emit starContractChange(oldAddress,_address);
    }

    //allow users to deposit Star Tokens to the Game account to increase their allowance.
    function depositStar(uint256 _amount) public returns(uint256,uint256){
        bool success;
        require (star.balanceOf(msg.sender) >= _amount, "Deposit amount is greater then your balance."); //check the user has atleast the amount of Star they are trying to deposit.
        (success) = star.transferFrom(msg.sender, address(this), _amount); //transfer the funds from the user to the game.
        require(success, "Transfer failed."); //ensure transfer completed successfully 

        uint256 fee = _amount.mul(depositFee).div(100); //calculate the value of the transfer fee
        uint256 newAllowance = _amount - fee; //calcualte the value remaining after the deposit fee.
        starAllowance[msg.sender] = starAllowance[msg.sender].add(newAllowance); //add the transfered amount to the users starAllowance

        return(newAllowance,starAllowance[msg.sender]);// return the amoutn added and the total allowance of the user.
    }
    //allow users to withdraw Star Tokens from the Game account to decrease their allowance.
    function withdrawStar(uint256 _amount) public returns(uint256){
        bool success;
        if(_amount > withdrawLimit){
            pendingWithdraw[msg.sender] = _amount;
            return(pendingWithdraw[msg.sender]);
        }
        require (starAllowance[msg.sender] >= _amount, "Withdraw amount is greater then your current Star Allowance"); //check the user has atleast the amount of Star allowance they are trying to withdraw.
        (success) = star.transferFrom(address(this),msg.sender,_amount); //transfer the funds from the game to the user.
        require(success, "Transfer failed."); //ensure transfer completed successfully 

        starAllowance[msg.sender] = starAllowance[msg.sender].sub(_amount); //remoce the transfered amount from the users starAllowance

        return(starAllowance[msg.sender]);//return the users remaining balance
    }

    function increaseAllowance(address _user, uint256 _amount) external onlyOwner returns(uint256){
         starAllowance[_user] = starAllowance[_user].add(_amount);
         return(starAllowance[_user]);
    }

    //allow owner to update the deposit fee
    function setDepositFee(uint256 _newFee) external onlyOwner returns(uint256,uint256) {
        prevDepositFee = depositFee; // set the previouse deposit fee equal to the current fee.
        depositFee = _newFee; // updatre teh deposit fee with the new value.

        emit depositFeeChange(prevDepositFee,depositFee); //emit an event with the old and new fees.
        return(prevDepositFee,depositFee);// return the old and new fees.
    }

    function setwithdrawLimit(uint256 _amount) external onlyOwner {
        withdrawLimit = _amount;
    }

    // get a users star allowance.
    function getAllowance(address user) external view onlyOwner returns(uint256){
        return (starAllowance[user]);
    }

    // users check thier current allowance
    function userGetAllowance() external view returns(uint256){
        return (starAllowance[msg.sender]);
    }

    function approveWithdraw(address user) external onlyOwner returns(uint256){
        bool success;
        require (starAllowance[user] >= pendingWithdraw[user], "Withdraw amount is greater then your current Star Allowance"); //check the user has atleast the amount of Star allowance they are trying to withdraw.
        (success) = star.transferFrom(address(this),user,pendingWithdraw[user]); //transfer the funds from the game to the user.
        require(success, "Transfer failed."); //ensure transfer completed successfully 

        starAllowance[user] = starAllowance[user].sub(pendingWithdraw[user]); //remoce the transfered amount from the users starAllowance
        pendingWithdraw[user] = 0;

        return(starAllowance[user]);//return the users remaining balance
    }

    function denyWithdraw(address user) external onlyOwner returns (uint256){
        pendingWithdraw[user] = 0;

        return(starAllowance[user]);
    }
}