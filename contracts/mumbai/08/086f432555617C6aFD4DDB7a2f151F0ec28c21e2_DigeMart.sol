/**
 *Submitted for verification at polygonscan.com on 2022-11-18
*/

//SPDX-License-Identifier: MIT

// File: contracts/TransferHelper.sol
pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


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

// File: contracts/library/PriceConverter.sol

pragma solidity ^0.8.9;


contract Converter {
    function getPrice(AggregatorV3Interface priceFeed)
        public
        view
        returns (uint256)
    {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    function getConversionRate(
        uint256 usdAmount,
        AggregatorV3Interface priceFeed
    ) public view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 usdAmountInEth = (usdAmount * 1e18) / ethPrice;
        return usdAmountInEth;
    }
}

// File: contracts/interfaces/IDigemartProduct.sol

pragma solidity ^0.8.0;

interface IDigemartProduct {
    function safeMint(
        address to,
        uint256 tokenId,
        string memory uri
    ) external;

    function burn(uint256 tokenId) external;
    
}
// File: contracts/interfaces/IPaymentContract.sol

pragma solidity ^0.8.0;

interface IPaymentContract {
    event PaymentSuccessful(uint amount, address token, address receiver);
    event SlippageUpdated(uint previousSlippage, uint newSlippage);
    event RouterUpdated(address previousRouter, address newRouter);
    event stableCoinUpdated(address previousStableCoin, address newStableCoin);

    function slippage() external view returns (uint);
    function router() external view returns (address);
    function stableCoin() external view returns (address);
    function makePayment(uint _amount, address _token, address _receiver, address _payer) payable external;
    function requiredTokenAmount(uint _amount, address _token) external view returns(uint _tokenAmount);
    function updateStableCoin(address _stableCoin) external;
    function updateRouter(address _router) external;
    function updateSlippage(uint _slippage) external;
}
// File: contracts/DigeMart.sol

pragma solidity ^0.8.0;



/** 
    TODO:
    - Documnent functions
    - Implement cancelling of order
    - Implement rating and review of products and merchant
    - Mint NFT receipt
    - Write unit test for payment and digemart contract
 */

contract DigeMart is Converter{

    //using Converter for uint256;

    //STATE VARIABLES
    uint public signUpFee;
    uint private purchaseId;
    uint private productId;
    address public DigemartProduct;
    address public owner;
    address public paymentContract;
    AggregatorV3Interface public priceFeed;

    //MAPPING
    mapping(address => Merchant) private merchants;
    mapping(address => User) private users;

    Order[] private orders;
    Product[] private products;
    Merchant[] private allMerchants;
    User[] private allUsers;

    //EVENTS
    event newMerchant(string name, address wallet);
    event newUser(string name, address wallet);
    event newOrder(
        uint purchaseId,
        address buyer,
        uint amount,
        uint[] productIds
    );
    event newProduct(uint productId, string url, uint price);
    event newSignUpFee(uint signUpFee);
    event newOwner(address owner);
    event newDigemartProduct(address DigemartProduct);
    event cancelledOrder(uint purchaseId);
    event completedOrder(uint purchaseId);
    event Withdraw(address merchant, uint amount);

    //MODIFIERS
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyMerchant() {
        require(
            bytes(merchants[msg.sender].name).length > 0,
            "Only merchants can call this function"
        );
        _;
    }

    modifier onlyUser() {
        require(
            bytes(users[msg.sender].name).length > 0,
            "Only registered users can call this function"
        );
        _;
    }

    modifier notEmptyString(string memory _string) {
        require(bytes(_string).length != 0, "Function params cannot be empty");
        _;
    }

    modifier notAddressZero(address _address) {
        require(_address != address(0), "Address cannot be address 0");
        _;
    }

    modifier isAvailable(Product memory _product) {
        require(_product.isBought == false, "This product has been bought");
        _;
    }

    modifier orderNotCompleted(uint _purchaseId) {
        require(
            !(orders[_purchaseId].isCompleted &&
                orders[_purchaseId].isCancelled),
            "Order already completed"
        );
        _;
    }

    //STRUCTS
    struct Merchant {
        string name;
        address wallet;
        uint[] products;
        uint[] orders;
    }

    struct Product {
        uint256 productId;
        string url;
        uint256 price;
        address merchant;
        string category;
        string description;
        bool isBought;
    }

    struct Order {
        uint256 purchaseId;
        uint256 productId;
        address merchant;
        address buyer;
        uint price;
        bool isCompleted;
        bool isCancelled;
    }

    struct User {
        string name;
        address wallet;
        uint256[] orders;
    }

    //CONSTRUCTOR
    constructor(address _paymentContract, address priceFeedAddress) {
        owner = msg.sender;
        paymentContract = _paymentContract;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    //FUNCTIONS

    /*
     *   Registering as a Seller by Paying a fixed fee of 5 ETH for using this platform.
     *   @string memory _name => Input name used as a Merchant
     */
    function registerMerchant(string memory _name)
        public
        payable
        notEmptyString(_name)
    {
        require(
            bytes(merchants[msg.sender].name).length == 0,
            "You are Already Registered"
        );
        require(
            getConversionRate(msg.value, priceFeed) >= signUpFee,
            "Insufficent funds to pay signUp fee"
        );

        (bool success, ) = payable(owner).call{
            value: getConversionRate(msg.value, priceFeed)
        }("");
        require(success, "Transfer failed");

        merchants[msg.sender].name = _name;
        merchants[msg.sender].wallet = msg.sender;
        allMerchants.push(merchants[msg.sender]);

        emit newMerchant(_name, msg.sender);
    }

    /*
     *   Register User Account
     *   @string memory _name =>  name
     */
    function registerUser(string memory _name) public notEmptyString(_name) {
        users[msg.sender].name = _name;
        users[msg.sender].wallet = msg.sender;
        allUsers.push(users[msg.sender]);

        emit newUser(_name, msg.sender);
    }

    /*
     *  Listing of Product with details
     *   @string memory _url => specify the productId
     *   @string memory _category => Category/Type of Product
     *   @string memory _description => What is the product for.
     *   @uint _price => Price of Product
     */
    function listProduct(
        string memory _url,
        string memory _category,
        string memory _description,
        uint256 _price
    )
        public
        onlyMerchant
        notEmptyString(_url)
        notEmptyString(_category)
        notEmptyString(_description)
    {
        Product memory _product = Product(
            productId,
            _url,
            _price,
            msg.sender,
            _category,
            _description,
            false
        );

        products.push(_product);
        merchants[msg.sender].products.push(productId);

        emit newProduct(productId, _url, _price);
        productId++;
    }

    /*
     *   Buying a Product
     *   @string memory _productIds => specify productId
     *   @address _token => address of the ERC20 token user wants to pay with, should be address 0 if paying with ether
     */
    function buyProduct(uint256[] memory _productIds, address _token)
        public
        payable
        onlyUser
    {
        uint256 _totalPrice;
        for (uint256 i = 0; i < _productIds.length; i++) {
            uint256 _productId = _productIds[i];
            uint256 _price = products[_productId].price;
            _totalPrice += _price;
            address _merchant = products[_productId].merchant;

            require(getConversionRate(_price, priceFeed) > 0, "Invalid product");
            require(
                products[_productId].isBought == false,
                "Product already bought"
            );

            Order memory _order = Order(
                purchaseId,
                _productId,
                _merchant,
                msg.sender,
                _price,
                false,
                false
            );

            users[msg.sender].orders.push(purchaseId);
            merchants[_merchant].orders.push(purchaseId);
            orders.push(_order);
            products[_productId].isBought = true;

            if (address (IDigemartProduct(DigemartProduct)) != address(0)) {
                IDigemartProduct(DigemartProduct).safeMint(
                    msg.sender,
                    purchaseId,
                    products[_productId].url
                );
            }

            purchaseId++;
        }

        // User needs to allow the payment contract to spend their token

        IPaymentContract(paymentContract).makePayment(
            _totalPrice,
            _token,
            address(this),
            msg.sender
        );

        emit newOrder(purchaseId, msg.sender, _totalPrice, _productIds);
    }

    /*
     *   Product Delivered
     *   @uint _purchaseId => specify _purchaseId
     */
    function delivered(uint _purchaseId)
        public
        onlyUser
        orderNotCompleted(_purchaseId)
    {
        uint _price = orders[_purchaseId].price;
        address _merchant = orders[_purchaseId].merchant;
        address _buyer = orders[_purchaseId].buyer;
        require(_buyer == msg.sender, "Order not made by you");
        // Pay merchant
        address _stableCoin = IPaymentContract(paymentContract).stableCoin();
        TransferHelper.safeTransfer(_stableCoin, _merchant, _price);

        emit completedOrder(_purchaseId);
    }

    //SETTERS

    /*
     *   Set Digemart Product address
     *   @address _digemartProduct =>  address
     */
    function setDigemartProduct(address _digemartProduct)
        public
        onlyOwner
        notAddressZero(_digemartProduct)
    {
        DigemartProduct = _digemartProduct;
        emit newDigemartProduct(_digemartProduct);
    }

    /*
     *   SetMerchant Signup fee
     *   @uint _signUpFee => uint
     */
    function setSignUpFee(uint _signUpFee) public onlyOwner {
        signUpFee = _signUpFee;
        emit newSignUpFee(_signUpFee);
    }

    /*
     *   Setting Merchant Signup fee
     *   @uint _signUpFee => uint
     */
    function setOwner(address _owner) public onlyOwner notAddressZero(_owner) {
        owner = _owner;
        emit newOwner(_owner);
    }

    // GETTERS

    function getProducts() public view returns (Product[] memory) {
        return products;
    }

    function getProduct(uint256 _productId)
        public
        view
        returns (Product memory)
    {
        return products[_productId];
    }

    function getMerchants() public view returns (Merchant[] memory) {
        return allMerchants;
    }

    function getMerchant(address _merchant)
        public
        view
        returns (Merchant memory)
    {
        return merchants[_merchant];
    }

    function getUsers() public view returns (User[] memory) {
        return allUsers;
    }

    function getUser(address _user) public view returns (User memory) {
        return users[_user];
    }

    function getMerchantProducts(address _merchant)
        public
        view
        returns (Product[] memory)
    {
        uint256 _totalProducts = merchants[_merchant].products.length;
        Product[] memory _products = new Product[](_totalProducts);
        for (uint256 i = 0; i < _totalProducts; i++) {
            uint256 _purchaseId = merchants[_merchant].products[i];
            _products[i] = products[_purchaseId];
        }
        return _products;
    }

    function getMerchantOrders(address _merchant)
        public
        view
        returns (Order[] memory)
    {
        uint256 _totalOrders = merchants[_merchant].orders.length;
        Order[] memory _merchantOrders = new Order[](_totalOrders);
        for (uint256 i = 0; i < _totalOrders; i++) {
            uint256 _purchaseId = merchants[_merchant].orders[i];
            _merchantOrders[i] = orders[_purchaseId];
        }
        return _merchantOrders;
    }

    function getUserOrders(address _user) public view returns (Order[] memory) {
        uint256 _totalOrders = users[_user].orders.length;
        Order[] memory _userOrders = new Order[](_totalOrders);
        for (uint i = 0; i < _totalOrders; i++) {
            uint _purchaseId = users[_user].orders[i];
            _userOrders[i] = orders[_purchaseId];
        }
        return _userOrders;
    }

    function getOrder(uint _purchaseId) public view returns (Order memory) {
        return orders[_purchaseId];
    }
}