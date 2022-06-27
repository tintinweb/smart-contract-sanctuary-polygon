/**
 *Submitted for verification at polygonscan.com on 2022-06-26
*/

// File: contracts/Ownable.sol


pragma solidity ^0.8.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    address public pendingOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "onlyOwner");
        _;
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    function claimOwnership() public {
        require(msg.sender == pendingOwner, "onlyPendingOwner");
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/utils/math/Math.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
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

// File: @chainlink/contracts/src/v0.4/interfaces/AggregatorV3Interface.sol

pragma solidity >=0.4.24;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// File: contracts/digitalMarketPlace.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;






interface IMarketplace1 {
    enum ProductState {
        NotDeployed, // don't exist or removed
        Deployed // created or redeployed
    }

    enum Currency {
        DMT, // "token wei" (10^-18 GMT)
        USD // dollars (10^-18 USD)
    }

    function getProduct(uint256 id)
        external
        view
        returns (
            string memory name,
            address owner,
            address beneficiary,
            uint pricePerSecond,
            Currency currency,
            ProductState state
        );
}

contract Marketplace is Ownable, IMarketplace1 {
    using SafeMath for uint256;
    // Product registry
    struct Product {
        uint256 id;
        string name;
        string description;
        address payable seller;
        uint price;
        address beneficiary; // account where revenue is directed to
        bool purchased;
        Currency priceCurrency;
        ProductState state;
        address newOwnerCandidate;
    }

    bool public halted = false;
    IERC20 digimart;
    IMarketplace1 marketplace;
    AggregatorV3Interface internal priceFeed;
    address payable public _beneficiary;
    address public admin;
    //uint public dmtPerUsd = 100000000000000000; //Exchange rates is formatted as 10^18, like ether = 0.1 DMT/USD.

    uint8 constant INTERNAL_PRICE_DECIMALS = 2;

    mapping(uint256 => Product) public products;
    mapping(uint256 => address) productBalance;

    /// events
    event Halted();
    event Resumed();

    // product events
    event ProductCreated(
        address indexed owner,
        uint256 indexed id,
        string name,
        uint price,
        Currency currency
    );
    event ProductUpdated(
        address indexed owner,
        uint256 indexed id,
        string name,
        uint price,
        Currency currency
    );
    event ProductDeleted(
        address indexed owner,
        uint256 indexed id,
        string name,
        address beneficiary,
        Currency currency
    );
    event ProductImported(
        address indexed owner,
        uint256 indexed id,
        string name,
        address beneficiary,
        Currency currency
    );
    event ProductRedeployed(
        address indexed owner,
        uint256 indexed id,
        string name,
        address beneficiary,
        Currency currency
    );
    event ProductOwnershipOffered(
        address indexed owner,
        uint256 indexed id,
        address indexed to
    );
    event ProductOwnershipChanged(
        address indexed newOwner,
        uint256 indexed id,
        address indexed oldOwner
    );
    event PurchaseSuccessful(
        address buyer,
        uint amount,
        uint productId,
        uint date
    );
    event Withdraw(uint256 amount);

    event PaymentRequiredUSD(uint256 paymentusd);
    event UsdToDmt(uint256 usd_wei);
    event Dmt(uint256 dmt_cost);

    // modifiers
    modifier whenNotHalted() {
        require(!halted || owner == msg.sender, "error_halted");
        _;
    }

    modifier onlyProductOwner(uint256 productId) {
        address _owner = products[productId].seller;
        // (,address _owner,,,,) = getProduct(productId);
        require(_owner != address(0), "error_notFound");
        require(
            _owner == msg.sender || owner == msg.sender,
            "error_productOwnersOnly"
        );
        _;
    }

    constructor(address adminAddress, address digimartAddress)
        public
        Ownable()
    {
        admin = adminAddress;
        digimart = IERC20(digimartAddress);
        // Chainlink ETH/USD Kovan Address = 0x9326BFA02ADD2366b30bacB125260Af641031331
        priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
    }

    /**
     * get product details
     */
    function getProduct(uint256 id)
        public
        view
        override
        returns (
            string memory name,
            address owner,
            address beneficiary,
            uint pricePerSecond,
            Currency currency,
            ProductState state
        )
    {
        if (owner != address(0) || address(marketplace) == address(0))
            return (name, owner, beneficiary, pricePerSecond, currency, state);
        (
            name,
            owner,
            beneficiary,
            pricePerSecond,
            currency,
            state
        ) = marketplace.getProduct(id);
        return (name, owner, beneficiary, pricePerSecond, currency, state);
    }

    function _getProductDetails(uint256 productId)
        internal
        returns (bool imported)
    {
        if (address(marketplace) == address(0)) {
            return false;
        }
        Product storage p = products[productId];
        if (p.id != 0x0) {
            return false;
        }
        (
            string memory _name,
            address _owner,
            address _beneficial,
            uint _pricePerSecond,
            IMarketplace1.Currency _priceCurrency,
            IMarketplace1.ProductState _state
        ) = marketplace.getProduct(productId);
        if (_owner == address(0)) {
            return false;
        }
        p.id = productId;
        p.name = _name;
        p.seller = payable(_owner);
        p.beneficiary = _beneficial;
        p.purchased = false;
        p.priceCurrency = _priceCurrency;
        p.state = _state;
        emit ProductImported(
            p.seller,
            p.id,
            p.name,
            p.beneficiary,
            p.priceCurrency
        );
        return true;
    }

    /**
     * createProductProfile for listing
     */
    function registerProduct(
        uint256 id,
        string memory name,
        string memory description,
        uint price,
        Currency currency
    ) public whenNotHalted {
        _registerProduct(id, name, description, price, currency);
    }

    function _registerProduct(
        uint256 id,
        string memory name,
        string memory description,
        uint _price,
        Currency currency
    ) internal {
        (, address _owner, , , , ) = getProduct(id);
        require(_owner == address(0), "error_alreadyExists");
        products[id] = Product({
            id: id,
            name: name,
            description: description,
            seller: payable(msg.sender),
            price: _price * 10**18,
            beneficiary: _beneficiary,
            purchased: false,
            priceCurrency: currency,
            state: ProductState.Deployed,
            newOwnerCandidate: address(0)
        });
        emit ProductCreated(msg.sender, id, name, _price, currency);
    }

    /**
     * Stop offering the product
     */
    function removeProduct(uint256 productId)
        public
        onlyProductOwner(productId)
    {
        // _getProductDetails(productId);
        Product storage p = products[productId];
        require(p.state == ProductState.Deployed, "error_notDeployed");
        p.state = ProductState.NotDeployed;
        emit ProductDeleted(
            p.seller,
            productId,
            p.name,
            p.beneficiary,
            p.priceCurrency
        );
    }

    /**
     * Return product to market
     */
    function redeployProduct(uint256 productId)
        public
        onlyProductOwner(productId)
    {
        // _getProductDetails(productId);
        Product storage p = products[productId];
        require(p.state == ProductState.NotDeployed, "error_mustBeNotDeployed");
        p.state = ProductState.Deployed;
        emit ProductRedeployed(
            p.seller,
            productId,
            p.name,
            p.beneficiary,
            p.priceCurrency
        );
    }

    /**
     * update product status
     */
    function updateProduct(
        uint256 productId,
        string memory name,
        uint price,
        Currency currency,
        bool redeploy
    ) public onlyProductOwner(productId) {
        // _getProductDetails(productId);
        Product storage p = products[productId];
        p.name = name;
        p.price = price;
        p.priceCurrency = currency;
        emit ProductUpdated(p.seller, p.id, name, price, currency);
        if (redeploy) {
            redeployProduct(productId);
        }
    }

    /**
     * Changes ownership of the product.
     */
    function offerProductOwnership(uint256 productId, address newOwnerCandidate)
        public
        onlyProductOwner(productId)
    {
        // _getProductDetails(productId);
        products[productId].newOwnerCandidate = newOwnerCandidate;
        emit ProductOwnershipOffered(
            products[productId].seller,
            productId,
            newOwnerCandidate
        );
    }

    /**
     * Changes ownership of the product.
     */
    function transferProductOwnership(uint256 productId) public whenNotHalted {
        // _getProductDetails(productId);
        Product storage p = products[productId];
        require(msg.sender == p.newOwnerCandidate, "error_notPermitted");
        emit ProductOwnershipChanged(msg.sender, productId, p.seller);
        p.seller = payable(msg.sender);
        p.newOwnerCandidate = address(0);
    }

    function halt() public onlyOwner {
        halted = true;
        emit Halted();
    }

    function resume() public onlyOwner {
        halted = false;
        emit Resumed();
    }

    function purchase(uint[] calldata _productIds, uint amount) public payable {
        // compute total cost
        uint totalCost = 0;
        for (uint id = 0; id < _productIds.length; id++) {
            totalCost += products[_productIds[id]].price;
        }

        require(totalCost <= msg.value, "Pay at least the price!");

        for (uint id = 0; id < _productIds.length; id++) {
            uint _productId = _productIds[id];
            require(
                products[_productId].state == ProductState.Deployed,
                "product is not deployed"
            );
            // require(products[_productId].seller!=msg.sender,"Seller cannot be the buyer");
            products[_productId].beneficiary = address(msg.sender);
            // digimart.transferFrom(msg.sender, admin, amount);
            emit PurchaseSuccessful(
                msg.sender,
                amount,
                _productId,
                block.timestamp
            );
        }
    }

    function usdToDmtExchangeRate() internal view returns (uint256) {
        (, int256 usdToEthRate, , , ) = priceFeed.latestRoundData();
        uint8 rateDecimals = priceFeed.decimals();
        require(usdToEthRate > 0, "Cannot buy when rate is 0 or less.");
        uint256 usdToDmt = uint256(10**(rateDecimals - INTERNAL_PRICE_DECIMALS))
            .mul(1 ether)
            .div(uint256(usdToEthRate));
        return usdToDmt;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(owner).transfer(balance);
        emit Withdraw(balance);
    }
}