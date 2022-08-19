//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IDigiMartProduct.sol";
import "./IUniswapV2Router02.sol";
import "./IERC20.sol";
import "./TransferHelper.sol";

contract DigitalMarketPlace {
    //Declared Variables
    uint256 signUpAmount = 0.005 ether;
    uint256 private purchaseId = 0;
    uint256 private productId = 0;
    address public owner;
    address DigiMartProduct;
    address swapRouter = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506; //Quickswap
    address stableCoin = 0x28668a708c9a884ac7030033e4Be9cD0a5d2F1BC; //DUSD
    //address WETH = 0x5B67676a984807a212b1c59eBFc9B3568a474F0a; //WMATIC
    uint256 slippage = 5;

    //Mappings
    mapping(address => Merchant) private merchants;
    mapping(address => User) private users;
    mapping(uint256 => Order) private singleOrder;
    Order[] private orders;
    Product[] private products;
    Merchant[] private allMerchants;
    User[] private allUsers;

    //Events
    event SucessfullySignedUp(string name);

    event SuccessfullyCreated(string userName, string email);

    event PurchaseSuccessful(
        uint256 _purchaseId,
        address _buyer,
        uint256 _amount,
        uint256[] _productIds
    );

    event ProductListed(uint256 _productId, string _url, uint256 _price);

    event UpdateLocation(uint _purchaseId, string _location);

    event OrderCanceled(uint256 _purchaseId);
    
    event OrderCompleted(uint256 _purchaseId);

    event Withdraw(address _merchant, uint256 _amount);

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
        address merchant;
        bool isBought;
    }

    struct Order {
        uint256 purchaseId;
        uint256 productId;
        address merchant;
        address buyer;
        uint price;
        string deliveryAddress;
        string location;
        bool isCompleted;
        bool isCancelled;
    }

    struct User {
        string name;
        string email;
        uint256[] orders;
    }

    constructor() {
        owner = msg.sender;
    }

    /*
     *   Registering as a Seller by Paying a fixed fee of 5 ETH for using this platform.
     *   @string memory _name => Input name used as a Merchant
     */
    function merchantSignUp(string memory _name) public payable {
        
        require(
            bytes(merchants[msg.sender].name).length == 0,
            'You are Already Registered'
        );

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
    function buyProduct(uint256[] memory _productIds, address _token, string memory _deliveryAddress)
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

            require(_price > 0, 'Invalid product');
            require(products[_productId].isBought == false, "Product already bought");

            Order memory _order = Order(
                purchaseId,
                _productId,
                _merchant,
                msg.sender,
                _price,
                _deliveryAddress,
                "",
                false,
                false
            );
            singleOrder[purchaseId] = _order;

            users[msg.sender].orders.push(purchaseId);
            merchants[_merchant].orders.push(purchaseId);
            orders.push(_order);
            products[_productId].isBought = true;

            if (DigiMartProduct != address(0)) {
                IDigiMartProduct(DigiMartProduct).safeMint(msg.sender, purchaseId, products[_productId].url);
            }

            purchaseId++;
        }

        address[] memory _path;
        _path = new address[](2);
        _path[0] = _token;
        _path[1] = stableCoin;
        uint256 _tokenAmount;

        if (_token != stableCoin && _token != address(0)) {
            // Get the amount of token to swap
            _tokenAmount = _requiredTokenAmount(_totalPrice, _path);

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
            _swap(_tokenAmount, _totalPrice, _path);
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
                _totalPrice
            );
        } else {
            _path[0] = IUniswapV2Router02(swapRouter).WETH();
            _tokenAmount = _requiredTokenAmount(_totalPrice, _path);
            require(msg.value >= _tokenAmount, 'Insufficient amount!');
            IUniswapV2Router02(swapRouter).swapETHForExactTokens{
                value: _tokenAmount
            }(_totalPrice, _path, address(this), block.timestamp);
        }
        emit PurchaseSuccessful(
            purchaseId,
            msg.sender,
            _totalPrice,
            _productIds
        );
    }

    /*
     *  Listing of Product with details
     *   @string memory _productId => specify the productId
     *   @string memory _productName => Name of Product
     *   @string memory _category => Category/Type of Product
     *   @uint _price => Price of Product
     *   @string memory _description => What is the product for.
     */
    function listProduct(string memory _url, uint256 _price) public onlyMerchant {
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
    function cancelOrder(uint256 _purchaseId) public onlyUser {
        uint256 _amount = orders[_purchaseId].price;
        address _buyer = orders[_purchaseId].buyer;
        require(!(orders[_purchaseId].isCompleted && orders[_purchaseId].isCancelled) , "Order already completed");
        require(_buyer == msg.sender, "Order not made by you");

        orders[_purchaseId].isCancelled = true;
        
        if (DigiMartProduct != address(0)) {
            IDigiMartProduct(DigiMartProduct).burn(_purchaseId);
        }
        
        (bool success,) = payable(_buyer).call{value: _amount}("");
        require(success, "Transfer of ether failed");
        
        emit OrderCanceled(_purchaseId);
    }

    function delivered(uint256 _purchaseId) public onlyUser {
        uint256 _amount = orders[_purchaseId].price;
        address _merchant = orders[_purchaseId].merchant;
        address _buyer = orders[_purchaseId].buyer;
        require(_buyer == msg.sender, "Order not made by you");
        require(!(orders[_purchaseId].isCompleted || orders[_purchaseId].isCancelled) , "Order already completed");

        (bool success,) = payable(_merchant).call{value: _amount}("");
        require(success, "Transfer of ether failed");

        emit OrderCompleted(_purchaseId);
    }

    function setDigiMartProduct(address _address) public onlyOwner {
        require(_address != address(0), "Invalid address");
        DigiMartProduct = _address;
    } 

    function updateLocation(uint256 _purchaseId, string memory _location) public {
        orders[_purchaseId].location = _location;
        emit UpdateLocation(_purchaseId, _location);
    }

    function getLocation(uint256 _purchaseId) public view returns(string memory location) {
        return orders[_purchaseId].location;
    }

    //View functions

    function getProducts() public view returns (Product[] memory) {
        return products;
    }

    function getProduct(uint256 _productId) public view returns (Product memory) {
        return products[_productId];
    }

    function getMerchants() public view returns (Merchant[] memory) {
        return allMerchants;
    }

    function getMerchant(address _merchant) public view returns (Merchant memory) {
        return merchants[_merchant];
    }

    function getUsers() public view returns (User[] memory) {
        return allUsers;
    }

    function getUser(address _user) public view returns (User memory) {
        return users[_user];
    }

    // Check merchant products
    function merchantProducts(address _merchant) public view returns (Product[] memory) {
        uint256 _totalProducts = merchants[_merchant].products.length;
        Product[] memory _products = new Product[](_totalProducts);
        for (uint256 i = 0; i < _totalProducts; i++) {
            uint256 _purchaseId = merchants[_merchant].products[i];
            _products[i] = products[_purchaseId];
        }
        return _products;
    }

    // Merchant check Orders made
    function merchantOrders(address _merchant) public view returns (Order[] memory) {
        uint256 _totalOrders = merchants[_merchant].orders.length;
        Order[] memory _orders = new Order[](_totalOrders);
        for (uint256 i = 0; i < _totalOrders; i++) {
            uint256 _purchaseId = merchants[_merchant].orders[i];
            _orders[i] = orders[_purchaseId];
        }
        return _orders;
    }

    // User check Orders made
    function userOrders(address _user) public view returns (Order[] memory) {
        uint256 _totalOrders = users[_user].orders.length;
        Order[] memory _orders = new Order[](_totalOrders);
        for (uint256 i = 0; i < _totalOrders; i++) {
            uint256 _purchaseId = users[_user].orders[i];
            _orders[i] = orders[_purchaseId];
        }
        return _orders;
    }
    //GET SINGLE ORDER DETAILS (_PURCHASEid)
    function getOrder(uint256 _purchaseId) public view returns(        
        uint256, 
        uint256, 
        address, 
        address, 
        uint, 
        string memory, 
        string memory, 
        bool,
        bool)
        
        {
            Order memory order = singleOrder[_purchaseId];
            return(order.purchaseId,order.productId,order.merchant,order.buyer,
            order.price,order.deliveryAddress,order.location,order.isCompleted,order.isCancelled);

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
pragma solidity ^0.8.0;

interface IDigiMartProduct {
    function safeMint(
        address to,
        uint256 tokenId,
        string memory uri
    ) external;

    function burn(uint256 tokenId) external;
    
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
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
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
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