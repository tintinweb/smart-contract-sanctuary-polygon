// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../../IToken.sol";

contract AncientOmegaMarketplaceV1 is Ownable {
    //CONSTANT
    uint8 constant public MAX_MINTABLE = 5;
    uint256 constant public BASE_CURRENCY = 1 ether;

    //PRICES
    //Here can see the price for an offer
    mapping(uint256 => uint256) public prices; 

    //map erc20's address to aggregator (ERC20 / USD)
    mapping(address => address) public priceFeeds;

    //Here we can check if an offer is active(USELESS an offer with price 0 is not available, i can use directly prices)
    mapping(uint256 => bool) public offerStatus;

    //Here we can see if a currency is available
    mapping(address => bool) public currencyStatus;

    //Here we can track of an ERC20's index inside currencies array;
    mapping(address => uint256) public ercPosition;
    
    //MANAGERS
    mapping(address => bool) public managers;
    
    //Here we can track of all currencies available to buy
    address[] public currencies;
    
    //totalOffers ever created
    uint256 public totalOffers;  

    //INDEX PURCHASE TO FILTER
    uint256 public indexPurchase;

    //FOUNDER WALLET
    address public foundersWallet;

    //MATIC AGGREGATOR FEED'S ADDRESS
    address public priceFeedMatic;

    //MARKET OPENER
    bool public isMarketOpen;

    //Here we track the amount of deviation allowed of an offer price
    uint16 public deviationPercentage;


    event Purchase(address indexed buyer, uint256 indexed indexPurchase, uint256 indexed offer, uint8 quantity);


    constructor(){
        managers[msg.sender] = true;
        foundersWallet = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
        priceFeedMatic = 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0;
        deviationPercentage = 200;
        isMarketOpen = true;
    }

    modifier onlyManager(address sender){
        require(managers[sender] == true, "not a manager");
        _;
    }

    function addOffers(uint256[] calldata indexes, uint256[] calldata pricesUSD) external onlyManager(msg.sender){

        for(uint256 i = 0; i < indexes.length; i++){
            uint256 index = indexes[i];
            uint256 price = pricesUSD[i];

            require(offerStatus[index] == false, "offer already active");
            require(index == totalOffers, "Not right index");

            prices[index] = price;
            offerStatus[index] = true;
            totalOffers++;
        }
    }

    function addCurrency(address currencyAddress, address aggregator) external onlyManager(msg.sender) {
        require(currencyStatus[currencyAddress] == false, "currency already added");

        ercPosition[currencyAddress]    = currencies.length;
        priceFeeds[currencyAddress]     = aggregator;
        currencyStatus[currencyAddress] = true;
        
        currencies.push(currencyAddress);
        
    }
    
    function changeOfferPrices(uint256[] calldata indexes, uint256[] calldata newPrices) external onlyManager(msg.sender){
        require(indexes.length == newPrices.length, "arrays have different lengths");

        for(uint256 i = 0; i < indexes.length; i ++){
            uint256 index = indexes[i];

            require(index < totalOffers, "offer not exist");

            prices[index] = newPrices[i];
        }
    }

    function changeOfferStatus(uint256 index, bool status) external onlyManager(msg.sender){
        require(index < totalOffers, "offer not exist");
        offerStatus[index] = status;
    }

    function deleteCurrency(address currencyAddress) external onlyManager(msg.sender){
        require(currencyStatus[currencyAddress] == true, "currency not active");

        uint256 index = ercPosition[currencyAddress];
        uint256 lastPosition = currencies.length - 1;

        currencyStatus[currencyAddress] = false;
        ercPosition[currencyAddress]    = 0;
        currencies[index]          = currencies[lastPosition];

        currencies.pop();

    }

    function purchase(uint256 index, uint8 quantity) external payable{
        require(isMarketOpen, "market is closed");

        require(index < totalOffers, "idx out of range");
        require(offerStatus[index] == true, "offer is closed");
        require(quantity > 0 && quantity < MAX_MINTABLE, "quantity must be greater than 0 and less than MAX_MINTABLE");

        uint256 priceUSD = getLatestPrice(priceFeedMatic);
        uint256 currencyAmount = conversionCurrency(priceUSD, prices[index]);
        uint256 epsilon = (currencyAmount * deviationPercentage) / 10000;

        require(msg.value >= (currencyAmount - epsilon) * quantity, "not enough balance");

        emit Purchase(msg.sender, indexPurchase++, index, quantity);
        
    }

    function purchaseCurrency(address currency, uint256 index, uint8 quantity) external{
        require(isMarketOpen, "market is closed");

        require(index < totalOffers, "idx out of range");
        require(offerStatus[index] == true, "offer is closed");
        require(quantity > 0 && quantity < MAX_MINTABLE, "quantity must be greater than 0 and less than MAX_MINTABLE");

        uint256 priceUSD = getLatestPrice(priceFeeds[currency]);
        uint256 currencyAmount = conversionCurrency(priceUSD, prices[index]);
        uint256 epsilon = (currencyAmount * deviationPercentage) / 10000;

        require((currencyAmount - epsilon) * quantity <= IToken(currency).balanceOf(msg.sender), "Low WCURRENCY blc");
        require((currencyAmount - epsilon) * quantity <= IToken(currency).allowance(msg.sender, address(this)), "Low WCURRENCY alw");

        IToken(currency).transferFrom(msg.sender, foundersWallet, currencyAmount * quantity);

        emit Purchase(msg.sender, indexPurchase++, index, quantity);
        
    }

    function getLatestPrice(address aggregator) public view returns (uint256) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = AggregatorV3Interface(aggregator).latestRoundData();
        return uint256(price);
    }
    
    function conversionCurrency(uint256 priceUSD, uint256 quantityUSD) public pure returns(uint256){
        return ((quantityUSD * BASE_CURRENCY) * uint256(10 ** 8))  / (priceUSD);
    }
    
    function setFoundersWallet(address newFoundersWallet) external onlyOwner{
        foundersWallet = newFoundersWallet;
    }

    function setManagerStatus(address manager, bool status) external onlyOwner {
        managers[manager] = status;
    }

    function setMarketStatus(bool status) external onlyManager(msg.sender) {
        isMarketOpen = status;
    }

    function setMaticFeed(address feed_) external onlyManager(msg.sender) {
        priceFeedMatic = feed_;
    }

    function setDeviation(uint16 deviation_) external onlyManager(msg.sender) {
        deviationPercentage = deviation_;
    }

    function withdraw() external onlyManager(msg.sender) {
        uint256 _balance = address(this).balance;
        payable(foundersWallet).transfer(_balance);
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IToken {
    function balanceOf(address owner) external view returns(uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address, address, uint256) external;
    function allowance(address owner, address spender) external view returns(uint256);
    function approve(address spender, uint256 amount) external returns(bool);
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