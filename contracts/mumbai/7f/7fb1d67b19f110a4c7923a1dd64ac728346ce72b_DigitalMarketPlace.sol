//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './PriceConverter.sol';
import './IUniswapV2Router02.sol';
import './IERC20.sol';
import './TransferHelper.sol';

contract DigitalMarketPlace {
    //Declared Variables
    using Converter for uint256;
    uint256 private purchaseId = 0;
    uint256 private productId = 0;
    address payable public owner;
    address swapRouter = 0x8954AfA98594b838bda56FE4C12a09D7739D179b;
    address stableCoin = 0x3813e82e6f7098b9583FC0F33a962D02018B6803;
    //address WETH = 0x5B67676a984807a212b1c59eBFc9B3568a474F0a;
    uint256 slippage = 5;

    //Mappings
    mapping(address => Merchant) private merchants;
    mapping(address => User) private users;
    Order[] private orders;
    Product[] private products;
    Merchant[] private allMerchants;
    User[] private allUsers;

    //Events
    event SucessfullySignedUp(string name);

    event SuccessfullyCreated(string userName, string email);

    event PurchaseSuccessful(
        uint256 purchaseId,
        address buyer,
        uint256 amount,
        uint256 productId
    );

    event ProductListed(uint256 productId, string url, uint256 price);

    event OrderCanceled(uint256 purchaseId);

    event Withdraw(address merchant, uint256 amount);

    //Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, 'Only owner can call this function');
        _;
    }

    modifier onlyMerchant() {
        require(
            bytes(merchants[msg.sender].name).length > 0,
            'Only merchants can call this function'
        );
        _;
    }

    modifier onlyUser() {
        require(
            bytes(users[msg.sender].name).length > 0,
            'Only registered users can call this function'
        );
        _;
    }

    //Structs
    struct Merchant {
        string name;
        address addr;
        uint256 balance;
        uint256[] products;
        uint256[] orders;
    }

    struct Product {
        uint256 productId;
        string url;
        uint256 price;
        address payable merchant;
        bool isBought;
    }

    struct Order {
        uint256 purchaseId;
        uint256 productId;
        address merchant;
        address buyer;
        bool isCompleted;
        bool isCancelled;
    }

    struct User {
        string name;
        string email;
        string deliveryAddress;
        uint256[] orders;
    }

    constructor() {}

    /*
     *   Registering as a Seller by Paying a fixed fee of 5 ETH for using this platform.
     *   @string memory _name => Input name used as a Merchant
     */
    function merchantSignUp(string memory _name) public payable {
        uint256 signUpAmount = 0.005 ether;
        require(
            bytes(merchants[msg.sender].name).length == 0,
            'You are Already Registered'
        );
        require(msg.value.getConversionRate() >= signUpAmount, 'You need 5 ETH Required to SignUp');

        merchants[msg.sender].name = _name;
        merchants[msg.sender].addr = msg.sender;
        allMerchants.push(merchants[msg.sender]);

        uint256 change = msg.value - signUpAmount;
        if (change > 0) {
            (bool success, ) = payable(msg.sender).call{value: change}('');
            require(success, 'Transfer failed!');
        }

        emit SucessfullySignedUp(_name);
    }

    /*
     *   Creating Account
     *   @string memory _name =>  name
     *   @uint256 _email =>  email address
     *   @string memory _deliveryAddress => deliveryAddress
     */
    function createAccount(string memory _name, string memory _email) public {
        users[msg.sender].name = _name;
        users[msg.sender].email = _email;
        allUsers.push(users[msg.sender]);

        emit SuccessfullyCreated(_name, _email);
    }

    /*
     *   Buying a Product
     *   @string memory _productId =>
     *   @token => address of the ERC20 token user wants to pay with, should be address 0 if paying with ether
     */
    function buyProduct(uint256 _productId, address _token)
        public
        payable
        onlyUser
    {
        uint256 _price = products[_productId].price;
        address _merchant = products[_productId].merchant;

        require(_price > 0, 'Invalid product');

        Order memory _order = Order(
            purchaseId,
            _productId,
            _merchant,
            msg.sender,
            false,
            false
        );
        users[msg.sender].orders.push(purchaseId);
        merchants[_merchant].orders.push(purchaseId);
        orders.push(_order);
        products[_productId].isBought = true;

        address[] memory _path;
        _path = new address[](2);
        _path[0] = _token;
        _path[1] = stableCoin;
        uint256 _tokenAmount;

        if (_token != stableCoin && _token != address(0)) {
            // Get the amount of token to swap
            _tokenAmount = _requiredTokenAmount(_price, _path);

            // Before swap balance
            uint256 beforeSwap = IERC20(_token).balanceOf(address(this));

            // Takes the tokens from buyer account

            TransferHelper.safeTransferFrom(
                _token,
                msg.sender,
                address(this),
                _tokenAmount + ((slippage * _tokenAmount) / 100)
            );

            // Swap to stableCoin
            _swap(_tokenAmount, _price, _path);
            // After swap balance
            uint256 afterSwap = IERC20(_token).balanceOf(address(this));

            // return excess to buyer
            uint256 excess = afterSwap - beforeSwap;
            TransferHelper.safeTransfer(_token, msg.sender, excess);
        } else if (_token == stableCoin) {
            TransferHelper.safeTransferFrom(
                _token,
                msg.sender,
                address(this),
                _price
            );
        } else {
            _path[0] = IUniswapV2Router02(swapRouter).WETH();
            _tokenAmount = _requiredTokenAmount(_price, _path);
            require(msg.value >= _tokenAmount, 'Insufficient amount!');
            IUniswapV2Router02(swapRouter).swapETHForExactTokens{
                value: _tokenAmount
            }(_price, _path, address(this), block.timestamp);
        }
        emit PurchaseSuccessful(
            purchaseId,
            msg.sender,
            products[_productId].price,
            _productId
        );
        purchaseId++;
    }

    /*
     *  Listing of Product with details
     *   @string memory _productId => specify the productId
     *   @string memory _productName => Name of Product
     *   @string memory _category => Category/Type of Product
     *   @uint _price => Price of Product in USD
     *   @string memory _description => What is the product for.
     */
    function listProduct(string memory _url, uint256 _price)
        public
        onlyMerchant
    {
        Product memory _product = Product(
            productId,
            _url,
            _price,
            payable(msg.sender),
            false
        );

        products.push(_product);
        merchants[msg.sender].products.push(productId);

        emit ProductListed(productId, _url, _price);
        productId++;
    }

    /*
     *  User cancelling an order
     *   @string memory _productId => product ID
     *   @ uint _purchaseId =>  purchase ID
     */
    function cancelOrder(uint256 _purchaseId) public payable {
        Order memory _order = orders[_purchaseId];
        _order.isCancelled = true;

        emit OrderCanceled(_purchaseId);
    }

    function withdraw(uint256 _amount) public onlyMerchant {
        uint256 balance = merchants[msg.sender].balance;
        require(balance >= _amount);
        merchants[msg.sender].balance -= _amount;
        TransferHelper.safeTransfer(stableCoin, msg.sender, _amount);

        emit Withdraw(msg.sender, _amount);
    }

    //View functions

    function getProducts(uint256 _from, uint256 _amount)
        public
        view
        returns (Product[] memory)
    {
        Product[] memory _products = new Product[](_amount);
        for (uint256 i = 0; i < _from + _amount; i++) {
            _products[i] = products[_from + i];
        }
        return _products;
    }

    function getProduct(uint256 _productId)
        public
        view
        returns (Product memory)
    {
        return products[_productId];
    }

    function getMerchants(uint256 _from, uint256 _amount)
        public
        view
        returns (Merchant[] memory)
    {
        Merchant[] memory _merchants = new Merchant[](_amount);
        for (uint256 i = 0; i < _from + _amount; i++) {
            _merchants[i] = allMerchants[_from + i];
        }
        return _merchants;
    }

    function getMerchant(address _merchant)
        public
        view
        returns (Merchant memory)
    {
        return merchants[_merchant];
    }

    function getUsers(uint256 _from, uint256 _amount)
        public
        view
        returns (User[] memory)
    {
        User[] memory _users = new User[](_amount);
        for (uint256 i = 0; i < _from + _amount; i++) {
            _users[i] = allUsers[_from + i];
        }
        return _users;
    }

    function getUser(address _user) public view returns (User memory) {
        return users[_user];
    }

    // Check merchant products
    function merchantProducts(
        address _merchant,
        uint256 _from,
        uint256 _amount
    ) public view returns (Product[] memory) {
        Product[] memory _products = new Product[](_amount);
        for (uint256 i = 0; i < _from + _amount; i++) {
            uint256 _purchaseId = merchants[_merchant].orders[i];
            _products[i] = products[_purchaseId];
        }
        return _products;
    }

    // Merchant check Orders made
    function merchantOrders(
        address _merchant,
        uint256 _from,
        uint256 _amount
    ) public view returns (Order[] memory) {
        Order[] memory _orders = new Order[](_amount);
        for (uint256 i = 0; i < _from + _amount; i++) {
            uint256 _purchaseId = merchants[_merchant].orders[i];
            _orders[i] = orders[_purchaseId];
        }
        return _orders;
    }

    // User check Orders made
    function userOrders(
        address _user,
        uint256 _from,
        uint256 _amount
    ) public view returns (Order[] memory) {
        Order[] memory _orders = new Order[](_amount);
        for (uint256 i = 0; i < _from + _amount; i++) {
            uint256 _purchaseId = users[_user].orders[i];
            _orders[i] = orders[_purchaseId];
        }
        return _orders;
    }

    // Internal functions
    // Get the require amount of token for a swap
    function _requiredTokenAmount(uint256 _amountInUSD, address[] memory _path)
        public
        view
        returns (uint256)
    {
        uint256[] memory _tokenAmount = IUniswapV2Router02(swapRouter)
            .getAmountsIn(_amountInUSD, _path);
        return _tokenAmount[0];
    }

    // Swap from tokens to a stablecoin
    function _swap(
        uint256 _tokenAmount,
        uint256 _amountInUSD,
        address[] memory _path
    ) internal returns (uint256[] memory amountOut) {
        // Approve the router to swap token.
        TransferHelper.safeApprove(
            _path[0],
            swapRouter,
            _tokenAmount + ((slippage * _tokenAmount) / 100)
        );

        amountOut = IUniswapV2Router02(swapRouter).swapTokensForExactTokens(
            _amountInUSD,
            _tokenAmount + ((slippage * _tokenAmount) / 100),
            _path,
            address(this),
            block.timestamp
        );

        return amountOut;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';

library Converter {
    //Matic/USD dataFeed
    AggregatorV3Interface constant priceFeed =
        AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada);

    function getPrice() internal view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 1e8);
    }

    function getConversionRate(uint256 usdAmount)
        internal
        view
        returns (uint256)
    {
        uint256 maticPrice = getPrice();
        uint256 usdAmountInMatic = (usdAmount * 1e18) / maticPrice;
        return usdAmountInMatic;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
     function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) 
    external payable returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later

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