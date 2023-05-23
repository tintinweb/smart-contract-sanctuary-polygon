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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract PaymentProcesor {
    using SafeMath for uint256;

    bool public paused = false;
    address payable public owner;
    address payable public DAOaddress;
    mapping(address => bool) public allowedTokens; 
    uint256 public feePercentage = 1;

    uint256 lastId = 0;
    struct Product {
        uint256 id;
        address owner;
        address receiver;
        uint256 quantity;
        bool oneByOne;
        string uri;       
    }
    mapping(uint256 => Product) public products;

    struct Price {
        bool active;
        uint256 price;
    }
    mapping(uint256 => mapping(address => Price)) public prices;
    mapping(address => uint256[]) public ownerProducts;


    mapping(uint256 => mapping(address => uint256)) public balances;

    event ProductCreated(uint256 id);
    event ProductEvent(uint256 id);
    event ProductPriceEvent(uint256 id, address tokenAddress);
    event ProductPurchased(uint256 id, address buyer);

    constructor(){
        owner = payable(msg.sender); // Owner is the address that deployed the contract
        DAOaddress = payable(msg.sender);  // DAO is the address that collect the fees
        allowedTokens[address(0)] = true;

    }

    // Product
    function createProduct(address _receiver, uint256 _qty, bool _oneByOne, string memory _uri) external notPaused {
        lastId += 1;
        Product memory newProduct = Product({
            id: lastId,
            owner: msg.sender,
            receiver: _receiver,            
            quantity: _qty,
            oneByOne: _oneByOne,
            uri: _uri
        });
        products[lastId] = newProduct;
        ownerProducts[msg.sender].push(lastId);
        emit ProductCreated(lastId);
    }
    function changeProductQty(uint256 _id, uint256 _qty) external onlyProductOwner(_id) {
        products[_id].quantity = _qty;
        emit ProductEvent(_id);
    }
    function changeProductReceiver(uint256 _id, address _receiver) external onlyProductOwner(_id) {
        products[_id].receiver = _receiver;
        emit ProductEvent(_id);
    }
    function changeProductUri(uint256 _id, string memory _uri) external onlyProductOwner(_id) {
        products[_id].uri = _uri;
        emit ProductEvent(_id);
    }

    function addProductPrice(uint256 _id, address _tokenAddress, uint256 _price) external onlyProductOwner(_id) {
        require(allowedTokens[_tokenAddress] == true, " Token is not allowed");
        prices[_id][_tokenAddress] = Price(true, _price);
        emit ProductPriceEvent(_id, _tokenAddress);
    }
    function removeProductPrice(uint256 _id, address _tokenAddress) external onlyProductOwner(_id) {
        require(prices[_id][_tokenAddress].active == true, "404: Proce doesn't exist, Bye");
        prices[_id][_tokenAddress].active = false;
        emit ProductPriceEvent(_id, _tokenAddress);
    }
    function changeProductPrice(uint256 _id, address _tokenAddress, uint256 _price) external onlyProductOwner(_id) {
        require(prices[_id][_tokenAddress].active == true, "404: Proce doesn't exist, Bye");
        prices[_id][_tokenAddress].price = _price;
        emit ProductPriceEvent(_id, _tokenAddress);
    }


    function purchaseProduct(uint256 _id, uint256 _quantity, address token) external payable notPaused {
        Product memory product = products[_id];

        require(_quantity > 0, "Quantity should be greater than 0");
        require(product.quantity >= _quantity, "Not enough product available");
        require(allowedTokens[token], "Token not allowed");
        require(prices[_id][token].active == true, "Doesn't have a price");

        if(product.oneByOne) {
            require(_quantity == 1, "This product can only be purchased one at a time");
        }

        uint256 totalCost = getPrice(_id, token) * _quantity;

        uint256 ownerFee = totalCost.mul(feePercentage).div(100);  // fee in percentage 
        uint256 payment = totalCost.sub(ownerFee);  // Amount that goes to product receiver

        if (token == address(0)) { // Pay with Ether
            require(msg.value >= totalCost, "Not enough Ether provided");
            // Refund excess Ether sent
            if (msg.value > totalCost) {
                payable(msg.sender).transfer(msg.value - totalCost);
            }
            // Transfer payment to receiver
            payable(product.receiver).transfer(payment);
            // Transfer fee to owner
            DAOaddress.transfer(ownerFee);
        } else { // Pay with ERC20 token
            IERC20 erc20 = IERC20(token);
            require(erc20.balanceOf(msg.sender) >= totalCost, "Not enough tokens");
            require(erc20.transferFrom(msg.sender, product.receiver, payment), "Transfer to receiver failed");
            require(erc20.transferFrom(msg.sender, DAOaddress, ownerFee), "Transfer of fee to owner failed");
        }
        products[_id].quantity = products[_id].quantity.sub(_quantity);
        balances[_id][msg.sender] = balances[_id][msg.sender].add(_quantity);
        emit ProductPurchased(_id, msg.sender);
    }

    function getPrice(uint256 _id, address _token) internal view returns(uint256){
        return prices[_id][_token].price;
    }
    
    function getProductsByOwner(address _owner) public view returns (uint256[] memory) {
        return ownerProducts[_owner];
    }


    // Controls
    function addAllowedToken(address token) external onlyOwner {
        allowedTokens[token] = true;
    }
    function removeAllowedToken(address token) external onlyOwner {
        allowedTokens[token] = false;
    }
    function changeFeePercentage(uint256 _newFeePercentage) external onlyOwner {
        require(_newFeePercentage <= 100, "The fee percentage cannot be more than 100.");
        feePercentage = _newFeePercentage;
    }
    function changeOwner(address _address) external onlyOwner {
        owner = payable(_address);
    }
    function changeDAOaddress(address _address) external onlyOwner {
        DAOaddress = payable(_address);
    }
    function toggleCtrPause() external onlyOwner{
        paused = !paused;
    }
    function withdrawAll() external onlyOwner {
        require(address(this).balance > 0, "No funds to withdraw");
        DAOaddress.transfer(address(this).balance);
    }
    function withdrawERC20Tokens(IERC20 _token) external onlyOwner {
        uint256 balance = _token.balanceOf(address(this));
        require(balance > 0, "No token balance to withdraw");
        _token.transfer(owner, balance);
    }

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: You are not the owner, Bye.");
        _;
    }

    modifier notPaused(){
        require(paused == false, "Pausable: Contract is on PAUSE, no activity allowed.");
        _;
    }

    modifier onlyProductOwner(uint256 _id) {
        require(msg.sender == products[_id].owner, "Ownable: Only product onwer can access this method, Bye.");
        _;
    }
}