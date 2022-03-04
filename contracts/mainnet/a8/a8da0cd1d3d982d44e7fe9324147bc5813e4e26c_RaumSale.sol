/**
 *Submitted for verification at polygonscan.com on 2022-03-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


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


/** 
 * @dev for managing the Raum Public and Private Sale
 */
contract RaumSale {
   
    using SafeMath for uint256;

    struct vault {
        uint256 privateSalebalance;
        uint256 privateSaleWithdrawDate;
        uint256 publicSalebalance1;
        uint256 publicSaleWithdrawDate1;
        uint256 publicSalebalance2;
        uint256 publicSaleWithdrawDate2;
    }

    mapping(address => vault) public saleBalances;

    address payable admin;
    address RNTokens;
    uint256 rnTokenPerMatic;
    bool isPublicSale1 = false;
    bool isPublicSale2 = false;

    event print(uint256 amount);

    /**
     * @dev Sets the values for {admin}, {RNTokens}, {startSaleBlock} and {price}.
     *
     *
     */
    constructor(address _RNAddress,uint256 _rnTokenPerMatic) {
        admin = payable(msg.sender);
        RNTokens = _RNAddress;
        rnTokenPerMatic = _rnTokenPerMatic;
    }

    /**
     * @dev Function to return price per MATIC
     */
    function getPrice() view public returns(uint256) {
        return (rnTokenPerMatic);
    }

    /**
     * @dev Set the Updated price for public and private sale.
     */
    function setrnTokenPerMatic(uint256 _rnTokenPerMatic) public {
        require ( msg.sender == admin, "Only admin callable function");
        rnTokenPerMatic = _rnTokenPerMatic;
    }

    /**
     * @dev Set the close the public sale 1
     */
    function changePublicSale1(bool _start) public {
        require ( msg.sender == admin, "Only admin callable function");
        isPublicSale1 = _start;
    }

    /**
     * @dev Set the close the public sale 2
     */
    function changePublicSale2(bool _start) public {
        require ( msg.sender == admin, "Only admin callable function");
        isPublicSale2 = _start;
    }

    /**
     * @dev Allows account to Book Tokens and lock them for 12 months
     */
    function privateSale(uint256 rnTokens, address investor) public {
        require ( msg.sender == admin, "Only admin callable function");
        saleBalances[investor].privateSalebalance = saleBalances[msg.sender].privateSalebalance.add(rnTokens);
        saleBalances[investor].privateSaleWithdrawDate = block.timestamp + 360 days;
    }

    /**
     * @dev Allows account to Book Tokens and lock them for 8 months
     */
    function publicSale1() public payable {
        require( isPublicSale1==true, "Public Sale 1 is closed");
        require( msg.value>=50*(10**18) && msg.value<=7500*(10**18), "You can buy a minimum of tokens worth 50 Matic and maximum of 7500 Matic" );
        uint256 noOfTokens = rnTokenPerMatic*(msg.value);
        saleBalances[msg.sender].publicSalebalance1 = saleBalances[msg.sender].publicSalebalance1.add(noOfTokens);
        saleBalances[msg.sender].publicSaleWithdrawDate1 = block.timestamp + 240 days;
    }

    /**
     * @dev Allows account to Book Tokens and lock them for 6 months
     */
    function publicSale2() public payable {
        require( isPublicSale2==true, "Public Sale 2 is closed");
        require( msg.value>=50*(10**18) && msg.value<=7500*(10**18), "You can buy a minimum of tokens worth 50 Matic and maximum of 7500 Matic" );
        uint256 noOfTokens = rnTokenPerMatic*(msg.value);
        saleBalances[msg.sender].publicSalebalance2 = saleBalances[msg.sender].publicSalebalance2.add(noOfTokens);
        saleBalances[msg.sender].publicSaleWithdrawDate2 = block.timestamp + 180 days;
    }

    /**
     * @dev Allows account to withdraw the Public sale 1 tokens
     */
    function withdrawPublicSale1() public {
        require( block.timestamp >= saleBalances[msg.sender].publicSaleWithdrawDate1, "Yorn RN Tokens are still locked" );
        IERC20(RNTokens).transfer(msg.sender, saleBalances[msg.sender].publicSalebalance1);
        saleBalances[msg.sender].publicSalebalance1 = 0;
    }

    /**
     * @dev Allows account to withdraw the Public sale 2 tokens
     */
    function withdrawPublicSale2() public {
        require( block.timestamp >= saleBalances[msg.sender].publicSaleWithdrawDate2, "Yorn RN Tokens are still locked" );
        IERC20(RNTokens).transfer(msg.sender, saleBalances[msg.sender].publicSalebalance2);
        saleBalances[msg.sender].publicSalebalance2 = 0;
    }

    /**
     * @dev Allows account to withdraw the Private token sale
     */
    function withdrawPrivateSale() public {
        require( block.timestamp >= saleBalances[msg.sender].privateSaleWithdrawDate, "Yorn RN Tokens are still locked" );
        IERC20(RNTokens).transfer(msg.sender, saleBalances[msg.sender].privateSalebalance);
        saleBalances[msg.sender].privateSalebalance = 0;
    }

    /**
     * @dev Returnnumber of RN Tokens in this contract
     */
    function getRNBalance() public view returns (uint) {
        return IERC20(RNTokens).balanceOf(address(this));
    }

    /**
     * @dev Returnnumber of MATIC Tokens in this contract
     */
    function getMaticBalance() public view returns (uint) {
        return address(this).balance;
    }

    /**
     * @dev allows admin to withdraw MATIC Tokens.
     */
    function withdrawMatic() public {
        require ( msg.sender == admin, "Only admin callable function");
        admin.transfer(getMaticBalance());
    }

    /** 
     * @dev allows admin to withdraw RN Tokens.
     */
    function withdrawRN() public {
        require ( msg.sender == admin, "Only admin callable function");
        IERC20(RNTokens).transfer(admin, getRNBalance());
    }
    
}