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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract  polyDEX {

    uint256 orderId;
    uint256 listId;

    struct payment {
        string appName;
        string userId;
    }

    struct Seller{
        address payable seller;
        string name;
        string email;
    }

    struct buyRequest{
        address payable buyer;
        address payable seller;
        address tokenAddress;
        bool matic;
        bool fulfilled;
        bool paid;
        bool cancelled;
        bool report;
        uint256 amount;
        uint256 price;
        uint256 orderId;
        string buyerName;
    }

    struct SellerList {
        address payable seller;
        address tokenAddress;
        string tokenName;
        bool matic;
        uint256 listId;
        uint256 amount;
        uint256 locked;
        uint256 price;
        uint256 time;
    }

    mapping (address => Seller) public sellers;
    mapping (address => mapping (address => SellerList)) public tokenSellerList;
    mapping (address => SellerList) public sellerList;
    mapping (address => payment[]) public paymentsOfSeller;
    mapping (address => buyRequest[]) public buyRequests;
    mapping (uint256 => buyRequest) public orders;
    mapping (address => buyRequest[]) public userRequests;
    
    event request(address indexed seller,string buyerName,string tokenName, uint256 amount, uint256 price, uint256 orderId);
    
    SellerList[] public listings;

    AggregatorV3Interface internal priceFeed;

    constructor(){
        priceFeed = AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada);
    }
    
    function register(string memory _name, string memory _email,payment[] memory _payments) public {
        require (sellers[msg.sender].seller == address(0), "You are already registered");
        sellers[msg.sender] = Seller(payable(msg.sender),_name,_email);
        for(uint8 i = 0; i < _payments.length; i++){
            paymentsOfSeller[msg.sender].push(_payments[i]);
        }
    }

    function sellMatic(uint256 amount,uint256 price) public payable {
        require(msg.value == amount, "You must send the exact amount");
        if(sellerList[msg.sender].seller != msg.sender){
            sellerList[msg.sender] = SellerList(payable(msg.sender), address(0),"MATIC",true,listId, amount,0, price, block.timestamp);
            listings.push(sellerList[msg.sender]);
            listId++;
        }
        else{
            sellerList[msg.sender].amount += amount;
            sellerList[msg.sender].price = price;
            sellerList[msg.sender].time = block.timestamp;
            listings[sellerList[msg.sender].listId] = sellerList[msg.sender];
        }
    }

    function sellToken(address tokenAddress,string memory tokenName, uint256 amount,uint256 price) public {
        IERC20 token = IERC20(tokenAddress);
        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed");
        if(tokenSellerList[msg.sender][tokenAddress].seller != msg.sender){
            tokenSellerList[msg.sender][tokenAddress] = SellerList(payable(msg.sender), tokenAddress,tokenName,false,listId, amount,0, price, block.timestamp);
            listings.push(tokenSellerList[msg.sender][tokenAddress]);
            listId++;
        }
        else{
            tokenSellerList[msg.sender][tokenAddress].amount += amount;
            tokenSellerList[msg.sender][tokenAddress].price = price;
            tokenSellerList[msg.sender][tokenAddress].time = block.timestamp;
            listings[tokenSellerList[msg.sender][tokenAddress].listId] = tokenSellerList[msg.sender][tokenAddress];
        }
    }

    function buyMaticRequest(uint256 id,uint256 amount,string memory _name) public payable {
        require(listings[id].amount >= amount, "Not enough tokens");
        address payable seller = listings[id].seller;
        require(seller != address(0), "Seller not found");
        buyRequests[seller].push(buyRequest(payable(msg.sender),seller,address(0),true,false,true,false,false,amount,listings[id].price,orderId,_name));
        orders[orderId] = buyRequests[seller][buyRequests[seller].length-1];
        userRequests[msg.sender].push(buyRequests[listings[id].seller][buyRequests[listings[id].seller].length - 1]);
        sellerList[listings[id].seller].amount -= amount;
        sellerList[listings[id].seller].locked += amount;
        listings[id] = sellerList[listings[id].seller];
        emit request(seller,_name,"MATIC",amount,listings[id].price,orderId);
        orderId++;
    }

    function buyTokenRequest(uint256 id,uint256 amount,string memory _name) public {
        require(listings[id].amount >= amount, "Not enough tokens");
        SellerList memory listing = tokenSellerList[listings[id].seller][listings[id].tokenAddress];
        require(listing.seller != address(0), "Seller not found");
        buyRequests[listing.seller].push(buyRequest(payable(msg.sender),listings[id].seller,listings[id].tokenAddress,false,false,true,false,false,amount,listing.price,orderId,_name));
        orders[orderId] = buyRequests[listing.seller][buyRequests[listing.seller].length - 1];
        userRequests[msg.sender].push(buyRequests[listing.seller][buyRequests[listing.seller].length - 1]);
        tokenSellerList[listings[id].seller][listings[id].tokenAddress].amount -= amount;
        tokenSellerList[listings[id].seller][listings[id].tokenAddress].locked += amount;
        listings[id] = tokenSellerList[listings[id].seller][listings[id].tokenAddress];
        emit request(listing.seller,_name,listing.tokenName,amount,listing.price,orderId);
        orderId++;
    }

    function release(uint256 id) public {
        require(orders[id].seller == msg.sender, "You are not the seller");
        require(orders[id].fulfilled == false, "Order fulfilled");
        if(orders[id].matic == true){
            orders[id].buyer.transfer(orders[id].amount);
            sellerList[orders[id].seller].locked -= orders[id].amount;
            listings[sellerList[orders[id].seller].listId] = sellerList[orders[id].seller];
            buyRequests[orders[id].seller][sellerList[orders[id].seller].listId].fulfilled = true;
        }
        else{
            IERC20 token = IERC20(orders[id].tokenAddress);
            require(token.transfer(orders[id].buyer, orders[id].amount), "Token transfer failed");
            tokenSellerList[orders[id].seller][orders[id].tokenAddress].locked -= orders[id].amount;
            listings[tokenSellerList[orders[id].seller][orders[id].tokenAddress].listId] = tokenSellerList[orders[id].seller][orders[id].tokenAddress];
            buyRequests[orders[id].seller][tokenSellerList[orders[id].seller][orders[id].tokenAddress].listId].fulfilled = true;
        }
        orders[id].fulfilled = true;
    }
    
    function sellerPayments(address seller) public view returns (payment[] memory){
        return paymentsOfSeller[seller];
    }

    function allListings() public view returns (SellerList[] memory){
        return listings;
    }

    function getRequests(address seller) public view returns (buyRequest[] memory){
        return buyRequests[seller];
    }

    function getLatestPrice() public view returns (int) {
        (,int price,,,) = priceFeed.latestRoundData();
        return price;
    }

    receive() external payable {}
}