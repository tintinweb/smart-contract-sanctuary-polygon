// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IFACTORYSELLER.sol";
import "./Seller.sol";

contract FactorySeller is IFACTORYSELLER, Ownable { 
    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Public functions
    ////////////////////////////////////////////////////////////////////////////////////////////////// 

    // => Set functions 

    function setManager(address p_manager) public onlyOwner override {         
        _transferOwnership(p_manager); 
    }

    function create(address p_stableCoin, address p_beneficiary, address p_aggregatorStableCoinDollar) public onlyOwner override returns(address) { 
        return address(new Seller(msg.sender, p_beneficiary, p_stableCoin, p_aggregatorStableCoinDollar));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISELLER {
    // EVENTS

    event Sale(address indexed e_client, uint256 e_amount);
    event toSell(uint256 e_tokenAmount, uint256 e_price);
    
    // PUBLIC FUNCTIONS

        // View functions
        function getMaxTime() external view returns(uint256);
        function priceAmountToken(uint256 p_amountToken) external view returns(uint256, uint256);
        function minAmountToBuy() external view returns(uint256);
        function tokenAmountSold() external view returns(uint256);
        function balanceSeller() external view returns(uint256);
        function stableCoin() external view returns(address, string memory, string memory);
        function holdingsAddress() external view returns(address);
        function beneficiary() external view returns(address);
        function canTransferHoldings() external view returns(bool);
        function status(address p_holder) external view returns(bool);
        function throughCompany() external view returns(uint256);
        function addressesThroughCompany() external view returns(address[] memory);
        function balanceAddress(address p_address) external view returns(uint256);
        function canRevertPayments() external view returns(bool);

        // Set functions

        function setHoldingsAddress(address p_erc20) external;
        function buy(uint256 p_amountToken, address p_buyer) external returns(bool);
        function buyThroughCompany(uint256 p_amountToken, address p_buyer) external returns(bool);
        function setThroughCompany(uint256 p_amountToken, bool p_inOut) external returns(bool);
        function sell(uint256 p_price, uint256 p_maxTime, uint256 p_minTokensBuy) external;
        function setPrice(uint256 p_price) external;
        function setMaxTime(uint256 p_maxTime) external;
        function setMinTokensBuy(uint256 p_minTokensBuy) external;
        function activeRevertPayments(uint256 p_amountStableCoin, address p_origin) external returns(bool);
        function revertPayments() external returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFACTORYSELLER {
    // PUBLIC FUNCTIONS

        // View functions

        // Set functions

        function setManager(address p_manager) external;
        function create(address p_stableCoin, address p_beneficiary, address p_aggregatorStableCoinDollar) external returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "../interfaces/ISELLER.sol";

contract Seller is ISELLER, Ownable {
    //////////////////////////////////////////////////////////////////////////////////////////////////
    // State
    //////////////////////////////////////////////////////////////////////////////////////////////////

    address private s_contractHoldings; 
    address private s_contractStableCoin;
    address private s_beneficiaryPaymets;

    uint256 private s_priceTokenEUROS;
    uint256 private s_tokenAmountSold;
    uint256 private s_maxTime;
    uint256 private s_minTokensBuy;

    bool private s_activeRevertPayments;

    mapping(address => bool) private s_statusAddress; 
    address[] private s_addressesThroughCompany;
    uint256 private s_amountThroughCompany;

    AggregatorV3Interface internal S_PRICE_FEED_STABLECOIN_USD;
    AggregatorV3Interface internal S_PRICE_FEED_EUR_USD;

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Constructor
    //////////////////////////////////////////////////////////////////////////////////////////////////

    constructor(address p_manager, address p_beneficiary, address p_stableCoin, address p_aggregatorStableCoinDollar) {
        s_contractStableCoin = p_stableCoin;
        s_beneficiaryPaymets = p_beneficiary;
        _transferOwnership(p_manager);

        // STABLE COIN / USD
        S_PRICE_FEED_STABLECOIN_USD = AggregatorV3Interface(p_aggregatorStableCoinDollar); 
        // EURO / USD
        S_PRICE_FEED_EUR_USD = AggregatorV3Interface(0x7d7356bF6Ee5CDeC22B216581E48eCC700D0497A);
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Public functions
    ////////////////////////////////////////////////////////////////////////////////////////////////// 

    // => View functions
    function getMaxTime() public view override returns(uint256) { 
        return (s_maxTime);
    }

    function priceAmountToken(uint256 p_amountToken) public view override returns(uint256, uint256) { 
        if (s_priceTokenEUROS == 0) { return (0, 0); }

        uint256 amountStableCoinOneToken = (s_priceTokenEUROS * uint256(getPriceOneEuroStableCoin())) / 100;
        uint256 amountStableCoinPay = ((amountStableCoinOneToken / 10000000000) * p_amountToken) / (1 ether / 10000000000);
        uint256 amountEurPay = (s_priceTokenEUROS * p_amountToken) / 1 ether;

        return (amountEurPay, amountStableCoinPay);
    }

    function minAmountToBuy() public view override returns(uint256) { 
        uint256 balance = IERC20(s_contractHoldings).balanceOf(address(this));

        if (balance < s_minTokensBuy) {
            return balance;
        }

        return s_minTokensBuy;
    }

    function tokenAmountSold() public view override returns(uint256) {
        return s_tokenAmountSold;
    }

    function balanceSeller() public view override returns(uint256) { 
        return IERC20(s_contractHoldings).balanceOf(address(this));
    }

    function stableCoin() public view override returns(address, string memory, string memory) {
        return (
            s_contractStableCoin,
            IERC20Metadata(s_contractStableCoin).name(),
            IERC20Metadata(s_contractStableCoin).symbol()
        ); 
    }

    function holdingsAddress() public view override returns(address) {
        return s_contractHoldings;
    }

    function beneficiary() public view override returns(address) { 
        return s_beneficiaryPaymets; 
    }

    function canTransferHoldings() public view override returns(bool) { 
        if (
                s_maxTime < block.timestamp &&
                IERC20(s_contractHoldings).balanceOf(address(this)) > 0
        ) { 
            return false; 
        }

        return true;
    }

    function status(address p_holder) public view override returns(bool) { 
        return s_statusAddress[p_holder];
    }

    function throughCompany() public view override returns(uint256) { 
        return s_amountThroughCompany; 
    }

    function addressesThroughCompany() public view override returns(address[] memory) { 
        return s_addressesThroughCompany;
    }

    function balanceAddress(address p_address) public view override returns(uint256) { 
        return IERC20(s_contractHoldings).balanceOf(p_address);
    }

    function canRevertPayments() public view override returns(bool) {
        return s_activeRevertPayments; 
    }

    // => Set functions

    function setHoldingsAddress(address p_address) public override onlyOwner {
        require(s_contractHoldings == address(0), "Already has value");

        s_contractHoldings = p_address;
    }
    
    function buy(uint256 p_amountToken, address p_buyer) public override returns(bool) {
        uint256 balance = IERC20(s_contractHoldings).balanceOf(address(this));

        require(s_maxTime >= block.timestamp, "Sales reverted or closed");
        require(s_priceTokenEUROS > 0, "Error price");
        require(p_amountToken <= balance && balance > 0, "Contract has insufficient balance to sell");
        require(p_amountToken >= minAmountToBuy(), "Buy below the minimum");
        require(!s_statusAddress[p_buyer], "Incompatible address");

        uint256 priceOneTokenStableCoin = (s_priceTokenEUROS * uint256(getPriceOneEuroStableCoin())) / 100;
        uint256 amountStableCoin = ((priceOneTokenStableCoin / 10000000000) * p_amountToken) / (1 ether / 10000000000);

        s_tokenAmountSold += p_amountToken;

        require(IERC20(s_contractStableCoin).transferFrom(p_buyer, s_beneficiaryPaymets, amountStableCoin), "Error transfer STABLE COIN");
        require(IERC20(s_contractHoldings).transfer(p_buyer, p_amountToken), "Error transfer tokens");

        emit Sale(p_buyer, p_amountToken);

        return true;
    }

    function buyThroughCompany(uint256 p_amountToken, address p_buyer) public override onlyOwner returns(bool) { 
        uint256 balance = IERC20(s_contractHoldings).balanceOf(address(this));

        require(s_maxTime >= block.timestamp, "Sales reverted or closed");
        require(s_priceTokenEUROS > 0, "Error price");
        require(p_amountToken <= balance && balance > 0, "Contract has insufficient balance to sell");
        require(p_amountToken >= minAmountToBuy(), "Buy below the minimum");
        
        if (!s_statusAddress[p_buyer]) {
            uint256 balanceBuyer = IERC20(s_contractHoldings).balanceOf(p_buyer);
            require(balanceBuyer == 0, "Incompatible address");
        }

        s_tokenAmountSold += p_amountToken;

        s_statusAddress[p_buyer] = true;
        s_addressesThroughCompany.push(p_buyer);
        s_amountThroughCompany += p_amountToken; 

        require(IERC20(s_contractHoldings).transfer(p_buyer, p_amountToken), "Error transfer tokens");

        emit Sale(p_buyer, p_amountToken);

        return true;
    } 

    function setThroughCompany(uint256 p_amountToken, bool p_inOut) public override returns(bool) {
        require(msg.sender == s_contractHoldings, "Error origin");

        if (p_inOut) {
            s_amountThroughCompany += p_amountToken; 
        } else {
            s_amountThroughCompany -= p_amountToken;
        }

        return true;
    }

    // price EUR => 2 DECIMALES; EJM: 23,04 = 2304; EJM: 0.05 = 0005
    function sell(uint256 p_priceEUROS, uint256 p_maxTimeHours, uint256 p_minTokensBuy) public onlyOwner override { 
        uint256 balance = IERC20(s_contractHoldings).balanceOf(address(this));

        require(s_tokenAmountSold == 0, "There are already sales");
        require(p_priceEUROS > 0, "Insufficient price");
        require(p_maxTimeHours >= 1, "Insufficient time");
        require(p_minTokensBuy <= balance && balance > 0, "Error amount tokens");

        s_priceTokenEUROS = p_priceEUROS;
        s_minTokensBuy = p_minTokensBuy; 
        s_maxTime = block.timestamp + (p_maxTimeHours * 1 hours);         

        emit toSell(balance, p_priceEUROS);
    }

    function setPrice(uint256 p_priceEUROS) public onlyOwner override { 
        require(s_tokenAmountSold == 0, "Not ollowed");
        require(p_priceEUROS > 0, "Insufficient price");
        
        s_priceTokenEUROS = p_priceEUROS;
    }

    function setMaxTime(uint256 p_maxTimeHours) public onlyOwner override {
        require(s_tokenAmountSold == 0, "Not ollowed");
        require(p_maxTimeHours >= 1, "Insufficient time");
        
        s_maxTime = block.timestamp + (p_maxTimeHours * 1 hours);   
    }

    function setMinTokensBuy(uint256 p_minTokensBuy) public onlyOwner override {
        require(s_tokenAmountSold == 0, "Not ollowed");

        uint256 balance = IERC20(s_contractHoldings).balanceOf(address(this));
        require(p_minTokensBuy <= balance && balance > 0, "Error amount tokens");
        
        s_minTokensBuy = p_minTokensBuy;
    }

    function activeRevertPayments(uint256 p_amountStableCoin, address p_origin) public override onlyOwner returns(bool) { 
        require(!canTransferHoldings(), "On sale"); 

        s_activeRevertPayments = true;
        require(IERC20(s_contractStableCoin).transferFrom(p_origin, address(this), p_amountStableCoin), "Error transfer STABLE COIN");

        return true;
    }

    function revertPayments() public override returns(bool) {
        require(!canTransferHoldings(), "On sale");

        uint256 amountTokens = IERC20(s_contractHoldings).balanceOf(msg.sender);
        require(amountTokens > 0, "Not tokens");

        uint256 balanceStableCoinContract = IERC20(s_contractStableCoin).balanceOf(address(this));
        require(s_activeRevertPayments && balanceStableCoinContract > s_tokenAmountSold, "Not Stable Coin");

        uint256 stableCoinReturn = (balanceStableCoinContract / s_tokenAmountSold) * amountTokens;

        s_tokenAmountSold -= amountTokens;

        require(
            IERC20(s_contractHoldings).transferFrom(msg.sender, address(this), amountTokens),
            "Error transfer tokens"
        );

        require(
            IERC20(s_contractStableCoin).transfer(msg.sender, stableCoinReturn), 
            "Error transfer Stable Coin"
        );

        return true;
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Internal functions
    //////////////////////////////////////////////////////////////////////////////////////////////////

    function getPriceOneEuroStableCoin() internal view returns(int256) {
        int256 decimals = int256(10 ** uint256(18));

        // EUR-USD
        ( , int256 basePrice, , , ) = S_PRICE_FEED_EUR_USD.latestRoundData();
        uint8 baseDecimals = S_PRICE_FEED_EUR_USD.decimals();
        basePrice = scalePrice(basePrice, baseDecimals, uint8(18));

        // STABLE_COIN-USD
        ( , int256 quotePrice, , , ) = S_PRICE_FEED_STABLECOIN_USD.latestRoundData();
        uint8 quoteDecimals = S_PRICE_FEED_STABLECOIN_USD.decimals();
        quotePrice = scalePrice(quotePrice, quoteDecimals, uint8(18));

        // STABLE_COIN-EUR => How many Stable Coins for one Euro
        return basePrice * decimals / quotePrice;
    }


    function scalePrice(int256 _price, uint8 _priceDecimals, uint8 _decimals) internal pure returns(int256) {
        if (_priceDecimals < _decimals) {
            return _price * int256(10 ** uint256(_decimals - _priceDecimals));
        } else if (_priceDecimals > _decimals) {
            return _price / int256(10 ** uint256(_priceDecimals - _decimals));
        }
        return _price;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
pragma solidity ^0.8.0;

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