// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract StableOneRocketCrowdSale is ReentrancyGuard {
     constructor(address moderatorAddress, address ownerAddress, address tokenAddress){
        _moderator = moderatorAddress;
        _owner = ownerAddress;  
        _tokenAddress= tokenAddress;
    }

    modifier onlyModerator{
        require(msg.sender==_moderator||msg.sender==_owner,"Only moderator or owner is allowed for this operation");
        _;
    }

    modifier onlyOwner{
        require(msg.sender==_owner,"Only owner is allowed for this operation");
        _;
    }

    using SafeMath for uint256;

    enum State { NotRunning, PreSale, PublicSale }
    
    uint256 public transferLimit = 100000000000000000;

    address public _moderator;

    address public _owner;

    address public _tokenAddress;

    // Supply limit of public sale
    uint256 public publicSaleSupply = 40000* 10 ** 18;
    
    //Supply limit of presale
    uint256 public preSaleSupply = 25000* 10 ** 18;

    // Checking whether the presale is open or not
    bool public preSaleOpen  = false;

    // Checking whether the publicsale is open or not
    bool public publicSaleOpen = false; 
    
    //Token price during presale
    uint256 public preSalePrice = 75000000000000000000;

    //token price during publicsale
    uint256 public publicSalePrice = 100000000000000000000;

    //Total tokens sold during presale
    uint256 public preSaleTokensSold = 0;

    //Total tokens sold during publicsale
    uint256 public publicSaleTokensSold = 0;

    function _validatePurchase (address _beneficiary, uint256 weiAmount, State currentState ) internal returns (uint256){
        require(currentState != State.NotRunning,"There is no sale in progress");

        uint256 requiredAmount=0;
        if(currentState== State.PreSale){
            requiredAmount = weiAmount.mul(10 ** 18).div(preSalePrice);
            require(requiredAmount<=(preSaleSupply.sub(preSaleTokensSold)),"Cannot transfer more than supply for presale");
            preSaleTokensSold = preSaleTokensSold.add(requiredAmount);
        }
        else if(currentState == State.PublicSale){
            requiredAmount = weiAmount.mul(10 ** 18).div(publicSalePrice);
            require(requiredAmount<=(publicSaleSupply.sub(publicSaleTokensSold)),"Cannot transfer more than supply for publicsale");
            publicSaleTokensSold = publicSaleTokensSold.add(requiredAmount);            
        }
        require(requiredAmount>0,"Not enough matics");
        require(_beneficiary != address(0));

        return requiredAmount;
    }

    function buyToken() external payable nonReentrant{
        uint256 weiAmount = msg.value;
        uint256 tokensAmount = 0;
        State currentState = getCurrentState();
        tokensAmount = _validatePurchase(msg.sender, weiAmount, currentState);   
        IERC20(_tokenAddress).transfer(msg.sender, tokensAmount);
    }

    
    function getCurrentState() public view returns(State) {
        State currentState = State.NotRunning;

        if (preSaleOpen) {
            currentState = State.PreSale;
        }
        else if (publicSaleOpen) {
            currentState = State.PublicSale;
        }

        return currentState;
    }

    function setPreSale(bool _condition) external onlyModerator{
        require(_condition!=preSaleOpen);
        preSaleOpen = _condition;
    }

    function setPublicSale (bool _condition) external onlyModerator{
        require(_condition!=publicSaleOpen);
        publicSaleOpen = _condition;
        preSaleOpen = false;
        if(preSaleTokensSold<preSaleSupply){
            publicSaleSupply = publicSaleSupply.add(preSaleSupply.sub(preSaleTokensSold));
            preSaleSupply = 0;
        }
    }

    function withdrawFees() public onlyOwner {
        (bool os, ) = payable(_owner).call{value: address(this).balance}("");
        require(os);
    }

    function withdrawNotSoldTokens() public onlyModerator {
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
    
    function setPreSalePrice(uint256 _newprice) public onlyModerator{
        require(_newprice!=preSalePrice);
        preSalePrice = _newprice;
    }

    function setPublicSalePrice(uint256 _newprice) public onlyModerator{
        require(_newprice!=publicSalePrice);
        publicSalePrice = _newprice;
    }

    function changeModeratorAddress(address _newModerator) public onlyModerator{
        require(_newModerator!=address(0) && _newModerator != _moderator,"Invalid address for new moderator");
        _moderator = _newModerator;
    }

    function changeOwnerAddress(address _newOwner) public onlyOwner{
        require(_newOwner!=address(0) && _newOwner != _owner,"Invalid address for new owner");
        _owner = _newOwner;
    }
    
    function changeTransferLimit(uint256 _newLimit) public onlyModerator{
        require(_newLimit!=transferLimit,"New tranfer limit cannot be equal to old limit");
        transferLimit = _newLimit;
    }

    function changePreSaleTokenSold(uint256 _alreadySold) public onlyModerator{
        require(_alreadySold!=preSaleTokensSold,"Already sold token cannot be equal to old");
        preSaleTokensSold = _alreadySold;
    }

    function changeTokenAddress(address tokenAddress) public onlyModerator{
        require(_tokenAddress!=tokenAddress,"New address cannot be same as old");
        _tokenAddress = tokenAddress;
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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