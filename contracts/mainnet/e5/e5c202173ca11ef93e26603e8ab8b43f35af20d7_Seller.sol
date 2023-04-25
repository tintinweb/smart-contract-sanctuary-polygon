/**
 *Submitted for verification at polygonscan.com on 2023-04-25
*/

// File: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol



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

// File: interfaces/ISELLER.sol


pragma solidity ^0.8.17;

interface ISELLER {
    // EVENTS

    event newSale(address indexed e_client, uint256 e_amount);
    event newSaleFiat(address indexed e_client, uint256 e_amount);
    event newReinvestment(address indexed e_buyer, uint256 e_amountToken);
    event toSell(uint256 e_tokenAmount, uint256 e_price);
    
    // PUBLIC FUNCTIONS

        // View functions

        function getMaxTime() external view returns(uint256);
        function priceAmountToken(uint256 p_amountToken) external view returns(uint256, uint256);
        function amountTokenStableCoin(uint256 p_amountStableCoin) external view returns(uint256);
        function minAmountToBuy() external view returns(uint256);
        function tokenAmountSold() external view returns(uint256);
        function balanceSeller() external view returns(uint256);
        function stableCoin() external view returns(address, string memory, string memory);
        function holdingsAddress() external view returns(address);
        function beneficiary() external view returns(address);
        function canTransferHoldings() external view returns(bool);
        function canRevertPayment() external view returns(bool);
        function amountToActiveRevertPayments() external view returns(uint256);

        // Set functions

        function setHoldingsAddress(address p_erc20) external;
        function buy(uint256 p_amountToken, address p_buyer) external;
        function buyWithoutPay(uint256 p_amountToken, address p_buyer) external;
        function buyWithFiat(uint256 p_amountToken, address p_buyer) external;
        function reinvest(uint256 p_amountStableCoin, address p_buyer) external returns(bool);
        function sell(uint256 p_price, uint256 p_maxTime, uint256 p_minTokensBuy) external;
        function setPrice(uint256 p_price) external;
        function setMaxTime(uint256 p_maxTime) external;
        function setMinTokensBuy(uint256 p_minTokensBuy) external;
        function activeRevertPayments(address p_origin) external ;
        function revertPayment() external;
}

// File: interfaces/IDIVIDENDS.sol


pragma solidity ^0.8.17;

interface IDIVIDENDS {
    // EVENTS 

    event AddDividends(
        address indexed e_contractHoldings, 
        uint256 e_amount,
        uint256 e_totalAmount
    ); 
    event ClaimDividends(address indexed e_holder, uint256 e_amount);
    event Reinvest(address indexed e_holder, address indexed e_seller, uint256 e_amount);

    // PUBLIC FUNCTIONS

        // View functions

        function amountSnapshots(address p_contractHoldings, uint256 p_idSnapshot) external view returns(uint256);
        function totalAmountSnapshots(address p_contractHoldings) external view returns(uint256);
        function amountSnapshotsAccount(address p_contractHoldings, address p_account, uint256 p_idSnapshot) external view returns(uint256, bool);

        // Set functions

        function setPause(bool p_pause) external; 
        function addDividends(address p_origin, address p_contractHoldings, uint256 p_amount, uint256 p_year, bool p_retention) external;
        function claimTotalDividends(address p_contractHoldings, uint256[] memory p_idsSnapshot) external;
        function claimDividends(
            address p_contractHoldings, 
            address p_contractSeller, 
            uint256 p_amountReinvest,
            uint256 p_idSnapshot
        ) external;
}

// File: interfaces/ITOKENHOLDINGS.sol


pragma solidity ^0.8.17;

interface ITOKENHOLDINGS {
    // STRUCTS
    
    struct SnapshotInfo {
        uint256 id;
        bool withholding;
    }

    // EVENTS

    event ForcedTransferStocks(address e_from, address e_to); 

    // PUBLIC FUNCTIONS

        // View functions

        function seller() external view returns(address);
        function getCurrentSnapshotId() external view returns(uint256);
        function snapshotsYear(uint256 p_year) external view returns(SnapshotInfo[] memory);
        function yearsWithSnapshots() external view returns(uint256[] memory);
        function amountBuyWithFiat() external view returns(uint256);
        function amountBuyWithFiatUser(address p_buyer) external view returns(uint256);
        function snapshotUsed(address p_account, uint256 p_snapshotId) external view returns(bool);

        // Set functions

        function setPause(bool p_pause) external;
        function snapshotUse(address p_account, uint256 p_snapshotId) external returns(bool);
        function snapshot(uint256 p_year, bool p_withholding) external returns(uint256);
        function incrementAmountBuyWithFiat(uint256 p_amount, address p_buyer) external returns(bool);
        function forcedTransferStocks(address p_from, address p_to) external returns(bool);
}

// File: contracts/Seller.sol

pragma solidity ^0.8.17;






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

    AggregatorV3Interface internal S_PRICE_FEED_STABLECOIN_USD;
    AggregatorV3Interface internal S_PRICE_FEED_EUR_USD;

    address private s_dividends;

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Constructor
    //////////////////////////////////////////////////////////////////////////////////////////////////

    constructor(address p_manager, address p_beneficiary, address p_stableCoin, address p_aggregatorStableCoinDollar, address p_dividends) {
        s_contractStableCoin = p_stableCoin;
        s_beneficiaryPaymets = p_beneficiary;
        _transferOwnership(p_manager);

        // STABLE COIN / USD
        S_PRICE_FEED_STABLECOIN_USD = AggregatorV3Interface(p_aggregatorStableCoinDollar); 
        // EURO / USD
        S_PRICE_FEED_EUR_USD = AggregatorV3Interface(0x73366Fe0AA0Ded304479862808e02506FE556a98);

        s_dividends = p_dividends;
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

        uint256 amountStableCoinOneToken = (s_priceTokenEUROS * uint256(_getPriceOneEuroStableCoin())) / 100;
        uint256 amountStableCoinPay = ((amountStableCoinOneToken / 10000000000) * p_amountToken) / (1 ether / 10000000000);
        uint256 amountEurPay = (s_priceTokenEUROS * p_amountToken) / 1 ether;

        return (amountEurPay, amountStableCoinPay);
    }

    function amountTokenStableCoin(uint256 p_amountStableCoin) public view override returns(uint256) {
        uint256 priceOneTokenStableCoin = (s_priceTokenEUROS * uint256(_getPriceOneEuroStableCoin())) / 100;
        require(p_amountStableCoin >= priceOneTokenStableCoin / 10000000, "Insufficient to buy");
        return ((p_amountStableCoin / (priceOneTokenStableCoin / 10000000)) * 1 ether) / 10000000;
    } 

    function minAmountToBuy() public view override returns(uint256) { 
        return _minAmountToBuy();
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
        if (IERC20(s_contractHoldings).balanceOf(address(this)) == 0) { 
            return true; 
        }

        return false;
    }

    function canRevertPayment() public view override returns(bool) { 
        return s_activeRevertPayments; 
    }

    function amountToActiveRevertPayments() public view override returns(uint256) { 
        uint256 priceOneTokenStableCoin = (s_priceTokenEUROS * uint256(_getPriceOneEuroStableCoin())) / 100;
        return ((priceOneTokenStableCoin / 10000000000) * s_tokenAmountSold) / (1 ether / 10000000000);
    }

    // => Set functions

    function setHoldingsAddress(address p_address) public override onlyOwner {
        require(s_contractHoldings == address(0), "Already has value");

        s_contractHoldings = p_address;
    }
    
    function buy(uint256 p_amountToken, address p_buyer) public override {
        _requerimentsBuyChecking(p_amountToken);

        uint256 priceOneTokenStableCoin = (s_priceTokenEUROS * uint256(_getPriceOneEuroStableCoin())) / 100;
        uint256 amountStableCoin = ((priceOneTokenStableCoin / 10000000000) * p_amountToken) / (1 ether / 10000000000);

        s_tokenAmountSold += p_amountToken;

        require(IERC20(s_contractStableCoin).transferFrom(p_buyer, s_beneficiaryPaymets, amountStableCoin), "Error transfer STABLE COIN");
        require(IERC20(s_contractHoldings).transfer(p_buyer, p_amountToken), "Error transfer tokens");

        emit newSale(p_buyer, p_amountToken);
    }

    function buyWithoutPay(uint256 p_amountToken, address p_buyer) public override onlyOwner {
        _requerimentsBuyChecking(p_amountToken);

        s_tokenAmountSold += p_amountToken;

        require(IERC20(s_contractHoldings).transfer(p_buyer, p_amountToken), "Error transfer tokens");

        emit newSale(p_buyer, p_amountToken);
    } 

    function buyWithFiat(uint256 p_amountToken, address p_buyer) public override onlyOwner { 
        _reinvestOrCompany(p_amountToken, p_buyer);

        require(ITOKENHOLDINGS(s_contractHoldings).incrementAmountBuyWithFiat(p_amountToken, p_buyer), "Error increment");

        emit newSaleFiat(p_buyer, p_amountToken); 
    } 

    function reinvest(uint256 p_amountStableCoin, address p_buyer) public override returns(bool) {
        require(msg.sender == s_dividends, "Error origin");
        require(p_amountStableCoin > 0, "Error amount stable coin");

        uint256 priceOneTokenStableCoin = (s_priceTokenEUROS * uint256(_getPriceOneEuroStableCoin())) / 100;
        uint256 amountToken = ((p_amountStableCoin / (priceOneTokenStableCoin / 10000000000)) * 1 ether) / 10000000000;

        _reinvestOrCompany(amountToken, p_buyer);

        emit newReinvestment(p_buyer, amountToken);

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
        require(s_tokenAmountSold == 0, "There are already sales");
        require(p_priceEUROS > 0, "Insufficient price");
        
        s_priceTokenEUROS = p_priceEUROS;
    }

    function setMaxTime(uint256 p_maxTimeHours) public onlyOwner override {
        require(s_tokenAmountSold == 0, "There are already sales");
        require(p_maxTimeHours >= 1, "Insufficient time");
        
        s_maxTime = block.timestamp + (p_maxTimeHours * 1 hours);   
    }

    function setMinTokensBuy(uint256 p_minTokensBuy) public onlyOwner override {
        require(s_tokenAmountSold == 0, "There are already sales");

        uint256 balance = IERC20(s_contractHoldings).balanceOf(address(this));
        require(p_minTokensBuy <= balance && balance > 0, "Error amount tokens");
        
        s_minTokensBuy = p_minTokensBuy;
    }

    function activeRevertPayments(address p_origin) public onlyOwner override { 
        require(!canTransferHoldings() && s_maxTime < block.timestamp, "On sale"); 

        s_activeRevertPayments = true;

        uint256 priceOneTokenStableCoin = (s_priceTokenEUROS * uint256(_getPriceOneEuroStableCoin())) / 100;
        uint256 totalSupply = s_tokenAmountSold - ITOKENHOLDINGS(s_contractHoldings).amountBuyWithFiat();
        uint256 stableCoinReturn = ((priceOneTokenStableCoin / 10000000000) * totalSupply) / (1 ether / 10000000000);

        require(IERC20(s_contractStableCoin).transferFrom(p_origin, address(this), stableCoinReturn), "Error transfer STABLE COIN");
    }

    function revertPayment() public override {
        require(s_activeRevertPayments, "On sale");

        uint256 amountTokens = IERC20(s_contractHoldings).balanceOf(msg.sender);
        require(amountTokens > 0, "Not tokens");

        require(
            IERC20(s_contractHoldings).transferFrom(msg.sender, address(this), amountTokens),
            "Error transfer tokens"
        );

        require(s_tokenAmountSold > ITOKENHOLDINGS(s_contractHoldings).amountBuyWithFiat(), "Error amounts");
        uint256 totalSupply = s_tokenAmountSold - ITOKENHOLDINGS(s_contractHoldings).amountBuyWithFiat(); 
        uint256 stableCoinReturn = ((amountTokens * 1 ether) / totalSupply) * IERC20(s_contractStableCoin).balanceOf(address(this));
        stableCoinReturn = stableCoinReturn / 1 ether;

        s_tokenAmountSold -= amountTokens;

        require(
            IERC20(s_contractStableCoin).transfer(msg.sender, stableCoinReturn), 
            "Error transfer Stable Coin"
        );
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Internal functions
    //////////////////////////////////////////////////////////////////////////////////////////////////

    function _minAmountToBuy() internal view returns(uint256) { 
        uint256 balance = IERC20(s_contractHoldings).balanceOf(address(this));

        if (balance < s_minTokensBuy) {
            return balance;
        }

        return s_minTokensBuy;
    }

    function _requerimentsBuyChecking(uint256 p_amountToken) internal view {
        uint256 balance = IERC20(s_contractHoldings).balanceOf(address(this));

        require(s_maxTime >= block.timestamp, "Sales reverted or closed");
        require(s_priceTokenEUROS > 0, "Error price");
        require(p_amountToken <= balance && balance > 0, "Contract has insufficient balance to sell");
        require(p_amountToken >= _minAmountToBuy(), "Buy below the minimum");
    }

    function _reinvestOrCompany(uint256 p_amountToken, address p_buyer) internal { 
        _requerimentsBuyChecking(p_amountToken);

        s_tokenAmountSold += p_amountToken;

        require(IERC20(s_contractHoldings).transfer(p_buyer, p_amountToken), "Error transfer tokens");
    } 

    function _getPriceOneEuroStableCoin() internal view returns(int256) {
        int256 decimals = int256(10 ** uint256(18));

        // EUR-USD
        ( , int256 basePrice, , , ) = S_PRICE_FEED_EUR_USD.latestRoundData();
        uint8 baseDecimals = S_PRICE_FEED_EUR_USD.decimals();
        basePrice = _scalePrice(basePrice, baseDecimals, uint8(18));

        // STABLE_COIN-USD
        ( , int256 quotePrice, , , ) = S_PRICE_FEED_STABLECOIN_USD.latestRoundData();
        uint8 quoteDecimals = S_PRICE_FEED_STABLECOIN_USD.decimals();
        quotePrice = _scalePrice(quotePrice, quoteDecimals, uint8(18));

        // STABLE_COIN-EUR => How many Stable Coins for one Euro
        return basePrice * decimals / quotePrice;
    }

    function _scalePrice(int256 _price, uint8 _priceDecimals, uint8 _decimals) internal pure returns(int256) {
        if (_priceDecimals < _decimals) {
            return _price * int256(10 ** uint256(_decimals - _priceDecimals));
        } else if (_priceDecimals > _decimals) {
            return _price / int256(10 ** uint256(_priceDecimals - _decimals));
        }
        return _price;
    }
}