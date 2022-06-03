/**
 *Submitted for verification at polygonscan.com on 2022-06-02
*/

// File: contracts/iNRT.sol



pragma solidity ^0.8.0;



interface iNRT {

    event Issued(address account, uint256 amount);

    event Redeemed(address account, uint256 amount);



    function issue(address account, uint256 amount) external;



    function redeem(address account, uint256 amount) external;



    function balanceOf(address account) external view returns (uint256);



    function symbol() external view returns (string memory);



    function decimals() external view returns (uint256);



    function issuedSupply() external view returns (uint256);



    function outstandingSupply() external view returns (uint256);

}
// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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

// File: contracts/OwnableMulti.sol



pragma solidity ^0.8.0;



abstract contract OwnableMulti {

    mapping(address => bool) private _owners;



    /**

     * @dev Initializes the contract setting the deployer as the initial owner.

     */

    constructor() {

        _owners[msg.sender] = true;

    }



    /**

     * @dev Returns the address of the current owner.

     */

    function isOwner(address _address) public view virtual returns (bool) {

        return _owners[_address];

    }



    /**

     * @dev Throws if called by any account other than the owner.

     */

    modifier onlyOwner() {

        require(_owners[msg.sender], "Ownable: caller is not an owner");

        _;

    }



    function addOwner(address _newOwner) public onlyOwner {

        require(_newOwner != address(0));

        _owners[_newOwner] = true;

    }

}
// File: contracts/aGNX.sol



pragma solidity ^0.8.0;






//NRT is like a private stock

//can only be traded with the issuer who remains in control of the market

//until he opens the redemption window

contract aGNX is OwnableMulti, iNRT {

    uint256 private _issuedSupply;

    uint256 private _outstandingSupply;

    uint256 private _decimals;

    string private _symbol;



    using SafeMath for uint256;



    mapping(address => uint256) private _balances;





    constructor(string memory __symbol, uint256 __decimals) {

        _symbol = __symbol;

        _decimals = __decimals;

        _issuedSupply = 0;

        _outstandingSupply = 0;

    }



    // Creates amount NRT and assigns them to account

    function issue(address account, uint256 amount) public override onlyOwner {

        require(account != address(0), "zero address");



        _issuedSupply = _issuedSupply.add(amount);

        _outstandingSupply = _outstandingSupply.add(amount);

        _balances[account] = _balances[account].add(amount);



        emit Issued(account, amount);

    }



    //redeem, caller handles transfer of created value

    function redeem(address account, uint256 amount) public override onlyOwner {

        require(account != address(0), "zero address");

        require(_balances[account] >= amount, "Insufficent balance");



        _balances[account] = _balances[account].sub(amount);

        _outstandingSupply = _outstandingSupply.sub(amount);



        emit Redeemed(account, amount);

    }



    function balanceOf(address account) public override view returns (uint256) {

        return _balances[account];

    }



    function symbol() public override view returns (string memory) {

        return _symbol;

    }



    function decimals() public override view returns (uint256) {

        return _decimals;

    }



    function issuedSupply() public override view returns (uint256) {

        return _issuedSupply;

    }



    function outstandingSupply() public override view returns (uint256) {

        return _outstandingSupply;

    }

}