// SPDX-License-Identifier: MIT

//                                                 ______   __                                                   
//                                                /      \ /  |                                                  
//   _______   ______    ______   _______        /$$$$$$  |$$/  _______    ______   _______    _______   ______  
//  /       | /      \  /      \ /       \       $$ |_ $$/ /  |/       \  /      \ /       \  /       | /      \ 
// /$$$$$$$/ /$$$$$$  |/$$$$$$  |$$$$$$$  |      $$   |    $$ |$$$$$$$  | $$$$$$  |$$$$$$$  |/$$$$$$$/ /$$$$$$  |
// $$ |      $$ |  $$ |$$ |  $$/ $$ |  $$ |      $$$$/     $$ |$$ |  $$ | /    $$ |$$ |  $$ |$$ |      $$    $$ |
// $$ \_____ $$ \__$$ |$$ |      $$ |  $$ |      $$ |      $$ |$$ |  $$ |/$$$$$$$ |$$ |  $$ |$$ \_____ $$$$$$$$/ 
// $$       |$$    $$/ $$ |      $$ |  $$ |      $$ |      $$ |$$ |  $$ |$$    $$ |$$ |  $$ |$$       |$$       |
//  $$$$$$$/  $$$$$$/  $$/       $$/   $$/       $$/       $$/ $$/   $$/  $$$$$$$/ $$/   $$/  $$$$$$$/  $$$$$$$/
//                         .-.
//         .-""`""-.    |(@ @)
//      _/`oOoOoOoOo`\_ \ \-/
//     '.-=-=-=-=-=-=-.' \/ \
//       `-=.=-.-=.=-'    \ /\
//          ^  ^  ^       _H_ \

pragma solidity 0.8.13;

import "./VaultBase.sol";


pragma experimental ABIEncoderV2;

/**
* @title Corn Finance Limit Order Vault
* @author C.W.B.
*/
contract LimitOrderVault is VaultBase {
    constructor(
        address _controller, 
        string memory _URI
    ) VaultBase(
        _controller, 
        type(uint256).max, 
        "Corn Finance Limit Order Strategy", 
        "CFNFT", 
        _URI
    ) {}

    /**
    * @dev This contract is owned by the Controller. Call 'createTrade' from the Controller
    * to use this function.
    * @notice The number of sell prices determines how many orders to create. The amount 
    * in for the sell orders is the total amount deposited divided by the number of sell 
    * prices. Each sell order will have the same amount in.
    * Example:
    *     - amount in: 100 USDC
    *     - to token: WMATIC
    *     - sell price 1: 0.9 WMATIC / 1 USDC
    *     - sell price 2: 0.7 WMATIC / 1 USDC
    *     - sell price 3: 0.5 WMATIC / 1 USDC
    *     - sell price 4: 0.4 WMATIC / 1 USDC
    *
    *     * amount out = amount in / sell price *
    *
    *     Sell order 1: 25 USDC --> 27.77 WMATIC
    *     Sell order 2: 25 USDC --> 35.71 WMATIC
    *     Sell order 3: 25 USDC --> 50 WMATIC
    *     Sell order 4: 25 USDC --> 62.5 WMATIC
    * @param _from: Controller contract will forward 'msg.sender'
    * @param _tokens:
    *   [0] = from token 
    *   [1] = to token
    * @param _amounts: 
    *   [0] = {required} starting amount
    *   [1] = {required} sell price (1) (token[0] / token[1]) * PRICE_MULTIPLIER()
    *   [2] = {optional} sell price (2) (token[0] / token[1]) * PRICE_MULTIPLIER()
    *   [3] = {optional} sell price (3) (token[0] / token[1]) * PRICE_MULTIPLIER()
    *   [4] = {optional} sell price (4) (token[0] / token[1]) * PRICE_MULTIPLIER()
    * @param _times:
    *   [0] = Expiration time in Unix. Orders will not be filled after this time.
    * @return Order IDs of the created orders. Limit Order vault creates all orders
    * at the time of creating the trade. Number of order IDs returned is the
    * number of sell prices inputted.
    */
    function createTrade(
        address _from, 
        address[] memory _tokens, 
        uint256[] memory _amounts, 
        uint[] memory _times
    ) external onlyOwner returns (uint256[] memory) {
        // Only one expiration time allowed
        require(_times.length == 1);

        // Trade consists of only two tokens
        require(_tokens.length == 2);

        // Limit limit orders to 4. Deposit amount occupies the first element
        require(
            _amounts.length >= 2 && _amounts.length <= 5, 
            "CornFi Limit Order Vault: Invalid Amounts Length"
        );

        // Create the trade
        uint256 amountInWithFee = _createTrade(_from, _tokens, _amounts, _times);

        // Calculate the amount in for the orders
        uint256 orderAmountIn = amountInWithFee / (_amounts.length - 1);

        // Order IDs of the created orders
        uint256[] memory orderIds = new uint256[](_amounts.length - 1);

        // Avoid stack too deep error
        uint256[] memory amounts = _amounts;
        address[] memory tokens = _tokens;

        // Create all of the limit orders
        for(uint i = 1; i < amounts.length; i++) {
            orderIds[i-1] = _createOrder(
                // Token counter is incremented in '_createTrade()'. Need to subtract
                // '1' to get the correct token ID.
                tokenCounter - 1,

                // Trade ID is '0' since this is the first trade
                0, 

                // ['from' token, 'to' token]
                [
                    tokens[0], 
                    tokens[1]
                ], 

                // [amount in, amount out needed, (Not used in this vault. Enter '0')]
                [
                    orderAmountIn, 
                    _getAmountOut(tokens[0], tokens[1], orderAmountIn, amounts[i]), 
                    0
                ], 

                // Expiration time for this order
                _times
            );
        }
        
        // Return the order IDs of the created orders
        return orderIds;
    }

    // --------------------------------------------------------------------------------

    /**
    * @dev This contract is owned by the Controller. Call 'fillOrder' from the Controller
    * to use this function.
    * @param _orderId: Order to fill
    * @param _router: Router used to perform the swap (i.e. fill the order)
    * @param _path: Path used to perform the swap
    * @return Since Limit Order vault does not create any new orders after filling orders,
    * '[]' is returned.
    */
    function fillOrder(
        uint256 _orderId, 
        IUniswapV2Router02 _router, 
        address[] memory _path
    ) external onlyOwner returns (Order[] memory, uint256[] memory) {
        Order memory order_ = order(_orderId);

        Order[] memory _orders;
        uint256[] memory filledOrders = new uint256[](1);
        filledOrders[0] = order_.orderId;

        // Fill order
        (uint256 minAmountOut, ) = _swap(order_, _router, _path);

        // Revert if swap amount out is too low
        require(
            minAmountOut >= order_.amounts[1], 
            "CornFi Limit Order Vault: Insufficent Output Amount"
        );

        return (_orders, filledOrders);
    }
    
    // --------------------------------------------------------------------------------

    /**
    * @dev This contract is owned by the Controller. Call 'withdraw' from the Controller
    * to use this function.
    * @notice After calling this function, all orders associated with '_tokenId' are
    * closed and their tokens are returned to the token owner. The token is then
    * burnt and cannot be used again.
    * @param _from: Controller contract will forward 'msg.sender'
    * @param _tokenId: Vault token to withdraw
    */
    function withdraw(address _from, uint256 _tokenId) external onlyOwner {
        _withdraw(_from, _tokenId);
    }

}

// SPDX-License-Identifier: MIT

//                                                 ______   __                                                   
//                                                /      \ /  |                                                  
//   _______   ______    ______   _______        /$$$$$$  |$$/  _______    ______   _______    _______   ______  
//  /       | /      \  /      \ /       \       $$ |_ $$/ /  |/       \  /      \ /       \  /       | /      \ 
// /$$$$$$$/ /$$$$$$  |/$$$$$$  |$$$$$$$  |      $$   |    $$ |$$$$$$$  | $$$$$$  |$$$$$$$  |/$$$$$$$/ /$$$$$$  |
// $$ |      $$ |  $$ |$$ |  $$/ $$ |  $$ |      $$$$/     $$ |$$ |  $$ | /    $$ |$$ |  $$ |$$ |      $$    $$ |
// $$ \_____ $$ \__$$ |$$ |      $$ |  $$ |      $$ |      $$ |$$ |  $$ |/$$$$$$$ |$$ |  $$ |$$ \_____ $$$$$$$$/ 
// $$       |$$    $$/ $$ |      $$ |  $$ |      $$ |      $$ |$$ |  $$ |$$    $$ |$$ |  $$ |$$       |$$       |
//  $$$$$$$/  $$$$$$/  $$/       $$/   $$/       $$/       $$/ $$/   $$/  $$$$$$$/ $$/   $$/  $$$$$$$/  $$$$$$$/
//                         .-.
//         .-""`""-.    |(@ @)
//      _/`oOoOoOoOo`\_ \ \-/
//     '.-=-=-=-=-=-=-.' \/ \
//       `-=.=-.-=.=-'    \ /\
//          ^  ^  ^       _H_ \

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/IERC20Meta.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IController.sol";
import "../interfaces/IUniswapV2Router02.sol";


pragma experimental ABIEncoderV2;

/**
* @title Corn Finance Vault Base
* @author C.W.B.
*/
abstract contract VaultBase is ERC721, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;


    struct Order {
        uint256 tokenId;
        uint256 tradeId;
        uint256 orderId;
        uint timestamp;
        address[2] tokens;
        uint256[3] amounts;
        uint[] times;
    }

    struct Strategy {
        address[] tokens;
        uint256[] amounts;
        uint[] times;
    }

    struct Token {
        address token;
        uint256 amount;
    }


    // Number of minted vault tokens
    uint256 public tokenCounter;

    // Max number of vault tokens that can be minted
    uint256 public maxTokens;

    // Controller contract
    IController public controller;

    // All token orders
    // orders[orderId] --> Order
    Order[] internal orders;

    // All open order IDs
    uint256[] internal openOrderIds;

    // All open order IDs for a given token
    // tokenOpenOrderIds[tokenId][index] --> Order ID
    uint256[][] internal tokenOpenOrderIds;

    // tradeLength[tokenId][tradeId] --> Number of orders in the trade
    mapping(uint256 => mapping(uint256 => uint256)) internal tradeLength;

    // trades[tokenId][tradeId] --> Array of the order IDs in a given trade
    mapping(uint256 => mapping(uint256 => uint256[])) internal trades;

    // _tokenTradeLength[tokenId] --> Number of trades in a given token
    mapping(uint256 => uint256) public _tokenTradeLength;

    // strategies[tokenId] --> Strategy details
    Strategy[] internal strategies;

    // tokenAmounts[tokenId][ERC20] --> Amount of an ERC20 token that belongs to 'tokenId'
    mapping(uint256 => mapping(address => uint256)) internal tokenAmounts;

    // openOrderIndex[orderId] --> Index of 'orderId' within 'openOrderIds'
    mapping(uint256 => uint256) internal openOrderIndex;

    // Tokens approved for use within the vault
    address[] public tokens;

    // activeTokens[ERC20] --> true: Token is active; false: Token is inactive 
    mapping(address => bool) public activeTokens;

    // _tokenStrategies[ERC20] --> Token holding strategy
    mapping(address => IStrategy) internal _tokenStrategies;

    // minimumDeposit[ERC20] --> Minimum amount of an ERC20 token that can be deposited for a trade
    mapping(address => uint256) public minimumDeposit;

    // Multiply price input into 'createTrade()' by this value to handle decimals
    uint256 public constant PRICE_MULTIPLIER = 1e18;

    string public BASE_URI;


    // --------------------------------------------------------------------------------
    // --------------------------------------------------------------------------------
    // --------------------------------------------------------------------------------

    /**
    * @dev Vaults are owned by the Controller contract. The Controller is immutable.
    * @param _controller: Controller contract that will call all 'onlyOwner' functions
    * @param _maxTokens: Max number of vault tokens that can be minted
    * @param _name: Vault name
    * @param _symbol: Vault symbol
    * @param baseURI_: Vault URI
    */
    constructor(
        address _controller, 
        uint256 _maxTokens, 
        string memory _name, 
        string memory _symbol, 
        string memory baseURI_
    ) ERC721(_name, _symbol) {
        // Set Controller contract
        controller = IController(_controller);

        // Vault URI
        BASE_URI = baseURI_;

        // Set max tokens that can be minted
        require(_maxTokens > 1, "CornFi Vault Base: Max Tokens Cannot be Less Than 1");
        maxTokens = _maxTokens;

        // Mint a blank strategy to this contract.
        orders.push();
        strategies.push();
        _safeMint(address(this), tokenCounter++);
        tokenOpenOrderIds.push();

        // Set Controller contract as the owner
        transferOwnership(_controller);
    }


    // --------------------------------------------------------------------------------
    // //////////////////////// Contract Settings - Only Owner ////////////////////////
    // --------------------------------------------------------------------------------

    /**
    * @dev This contract is owned by the Controller. Call 'setBaseURI' from the Controller
    * to use this function. Sets URI for all vault tokens.
    * @param baseURI_: Vault URI
    */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        BASE_URI = baseURI_;
    }

    // --------------------------------------------------------------------------------

    /**
    * @dev This contract is owned by the Controller. Call 'setStrategy' from the Controller
    * to use this function. Maps an ERC20 to a holding strategy. Once an ERC20 token is
    * mapped to a holding strategy, the mapping is immutable.
    * @param _token: ERC20 token address
    * @param _strategy: Holding strategy contract
    * @param _minDeposit: Minimum amount of '_token' that can be deposited when creating a trade
    */
    function setStrategy(address _token, address _strategy, uint256 _minDeposit) external onlyOwner {
        // Only unmapped ERC20 tokens
        require(address(_tokenStrategies[_token]) == address(0), "CornFi Vaut Base: Token Already Mapped");

        require(_strategy != address(0), "CornFi Vault Base: Strategy is address(0)");

        // Map the ERC20 token to a holding strategy
        _tokenStrategies[_token] = IStrategy(_strategy);

        // Set the minimum deposit for the ERC20 token
        minimumDeposit[_token] = _minDeposit;

        // Add ERC20 token to 'tokens'
        tokens.push(_token);

        // Allow trading of the ERC20 token
        activeTokens[_token] = true;
    }

    // --------------------------------------------------------------------------------

    /**
    * @dev This contract is owned by the Controller. Call 'changeMinimumDeposit' from the 
    * Controller to use this function. Owner can change the minimum amount of '_token'
    * that can be deposited when creating a trade.
    * @param _token: ERC20 token address
    * @param _minDeposit: Minimum amount of '_token' that can be deposited when creating a trade
    */
    function changeMinimumDeposit(address _token, uint256 _minDeposit) public onlyOwner {
        // Only active ERC20 tokens
        require(activeTokens[_token], "CornFi Vault Base: Invalid Token");

        // Set the minimum deposit for the ERC20 token
        minimumDeposit[_token] = _minDeposit;
    }

    // --------------------------------------------------------------------------------

    /**
    * @dev This contract is owned by the Controller. Call 'deactivateToken' from the 
    * Controller to use this function. Deactivating a token will restrict future users 
    * from creating trades with the deactivated token. Once a token is deactivated, it 
    * cannot be reactivated.
    * @param _token: ERC20 token to deactivate
    */
    function deactivateToken(address _token) public onlyOwner {
        activeTokens[_token] = false;
    }


    // --------------------------------------------------------------------------------
    // ///////////////////////////// Read-Only Functions //////////////////////////////
    // --------------------------------------------------------------------------------

    /**
    * @return Length of all tokens added to this vault. Includes tokens that have been
    * deactivated.
    */
    function tokensLength() public view returns (uint256) {
        return tokens.length;
    }

    // --------------------------------------------------------------------------------

    /**
    * @param _token: ERC20 token address
    * @return Holding strategy contract mapped to '_token'
    */
    function strategy(address _token) public view returns (IStrategy) {
        return _tokenStrategies[_token];
    }

    // --------------------------------------------------------------------------------

    /**
    * @dev Only used for informational purposes. Use to get all of the orders within a
    * given trade. After the order IDs are returned, use 'order()' to view the actual
    * order.
    * @param _tokenId: Vault token
    * @param _tradeId: Trade owned by '_tokenId'
    * @return IDs of the orders within the trade
    */
    function trade(uint256 _tokenId, uint256 _tradeId) public view returns (uint256[] memory) {
        return trades[_tokenId][_tradeId];
    }

    // --------------------------------------------------------------------------------

    /**
    * @dev Use to view any order that has been created within this vault
    * @param _orderId: Order to view
    * @return Order details of a given order
    */
    function order(uint256 _orderId) public view returns (Order memory) {
        return orders[_orderId];
    }
    
    // --------------------------------------------------------------------------------

    /**
    * @return Number of all orders created within this vault
    */
    function ordersLength() public view returns (uint256) {
        return orders.length;
    }

    // --------------------------------------------------------------------------------

    /**
    * @return Number of all open orders within this vault
    */
    function openOrdersLength() public view returns (uint256) {
        return openOrderIds.length;
    }

    // --------------------------------------------------------------------------------

    /**
    * @param _tokenId: Vault token
    * @return Number of open orders for a given vault token
    */
    function tokenOpenOrdersLength(uint256 _tokenId) public view returns (uint256) {
        return tokenOpenOrderIds[_tokenId].length;
    }

    // --------------------------------------------------------------------------------

    /**
    * @param _index: Element of 'openOrderIds'
    * @return Order ID at the given index 
    */
    function openOrderId(uint256 _index) public view returns (uint256) {
        return openOrderIds[_index];
    }

    // --------------------------------------------------------------------------------

    /**
    * @dev After the order IDs are returned, use 'order()' to view the actual order.
    * @param _tokenId: Vault token
    * @param _index: Element of an open order IDs array for a given vault token
    * @return Order ID at the given index of open order IDs for a vault token
    */
    function tokenOpenOrderId(uint256 _tokenId, uint256 _index) public view returns (uint256) {
        return tokenOpenOrderIds[_tokenId][_index];
    }

    // --------------------------------------------------------------------------------

    /**
    * @param _tokenId: Vault token
    * @return Array of ERC20 tokens and the respective amount owned by a given vault token
    */
    function viewTokenAmounts(uint256 _tokenId) public view returns (Token[] memory) {
        // Number of tokens included in the vault token strategy
        uint256 _tokensLength = strategies[_tokenId].tokens.length;
        Token[] memory _tokenAmounts = new Token[](_tokensLength);

        // Get amount of ERC20 tokens owned by the vault token 
        for(uint i = 0; i < strategies[_tokenId].tokens.length; i++) {
            _tokenAmounts[i] = Token(
                strategies[_tokenId].tokens[i], 
                tokenAmounts[_tokenId][strategies[_tokenId].tokens[i]]
            );
        }

        // Return ERC20 token amounts
        return _tokenAmounts;
    }

    // --------------------------------------------------------------------------------

    /**
    * @param _tokenId: Vault token
    * @return Trade details specific to a given vault token
    */
    function viewStrategy(uint256 _tokenId) public view returns (Strategy memory) {
        return strategies[_tokenId];
    }

    // --------------------------------------------------------------------------------
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return BASE_URI;
    }
    

    // --------------------------------------------------------------------------------
    // ////////////////////////////// Internal Functions //////////////////////////////
    // --------------------------------------------------------------------------------

    /**
    * @dev Use to create an order. This function will add the created order to the list
    * of open order IDs as well as configuring trade data. The format of '_tokens',
    * '_amounts', and '_times' are specific to the vault that inherits this contract.
    * @param _tokenId: Vault token
    * @param _tradeId: Trade owned by the vault token that will include the created order
    * @param _tokens:
    *   [0] = from token
    *   [1] = to token
    * @param _amounts: !!! SPECIFIC TO THE VAULT THAT INHERITS THIS CONTRACT !!!
    * @param _times: Expiration times
    * @return Order ID of the created order
    */
    function _createOrder(
        uint256 _tokenId, 
        uint256 _tradeId, 
        address[2] memory _tokens, 
        uint256[3] memory _amounts, 
        uint[] memory _times
    ) internal returns (uint256) {
        // Tokens must be unique
        require(
            _tokens[0] != _tokens[1], 
            "CornFi Vault Base: Identical Tokens"
        );

        // Trades can only be created with active tokens
        require(
            activeTokens[_tokens[0]] && activeTokens[_tokens[1]], 
            "CornFi Vault Base: Invalid Tokens"
        );

        // Reverse mapping for the index within 'openOrderIds' of the order being created
        openOrderIndex[orders.length] = openOrderIds.length;

        // Add the order ID of the created order to 'openOrderIds'
        openOrderIds.push(orders.length);

        // First order for a vault token
        if(_tokenId == tokenOpenOrderIds.length) {
            tokenOpenOrderIds.push([orders.length]);
        }
        // Vault token does not currently have any open orders
        else if(tokenOpenOrderIds[_tokenId].length == 0) {
            tokenOpenOrderIds[_tokenId] = [orders.length];
        }
        // Vault token currently has open orders
        else {
            // Create a new array of open order IDs with one extra element for the order
            // being created.
            uint256[] memory _prevIds = new uint256[](tokenOpenOrderIds[_tokenId].length.add(1));

            // Add all of the current open order IDs
            for(uint i = 0; i < tokenOpenOrderIds[_tokenId].length; i++) {
                _prevIds[i] = tokenOpenOrderIds[_tokenId][i];
            }

            // Add the new open order ID
            _prevIds[tokenOpenOrderIds[_tokenId].length] = orders.length;
            tokenOpenOrderIds[_tokenId] = _prevIds;
        }

        // Create a new trade and add the created order to it
        if(_tradeId == _tokenTradeLength[_tokenId]) {
            trades[_tokenId][_tradeId] = [orders.length];
            _tokenTradeLength[_tokenId]++;
        }
        // The created order is part of the current trade
        else {
            // Create a new array of order IDs with one extra element for the order
            // being created.
            uint256[] memory _prevTradeOrderIds = new uint256[](trades[_tokenId][_tradeId].length.add(1));

            // Add all of the current order IDs within the trade
            for(uint i = 0; i < trades[_tokenId][_tradeId].length; i++) {
                _prevTradeOrderIds[i] = trades[_tokenId][_tradeId][i];
            }

            // Add the new order ID to the trade
            _prevTradeOrderIds[trades[_tokenId][_tradeId].length] = orders.length;
            trades[_tokenId][_tradeId] = _prevTradeOrderIds;
        }

        // Increment the number of orders within the trade
        tradeLength[_tokenId][_tradeId]++;

        // Ensure the order was added to the correct trade
        require(
            tradeLength[_tokenId][_tradeId] <= strategies[_tokenId].amounts.length.sub(1), 
            "CornFi Vault Base: Trade Length Error"
        );

        // Create the order and add it to 'orders'
        orders.push(Order(_tokenId, _tradeId, orders.length, 0, _tokens, _amounts, _times));

        // Return the order ID of the created order
        return orders.length.sub(1);
    }

    // --------------------------------------------------------------------------------

    /**
    * @dev Closes an open order
    * @param _orderId: Open order to close
    */
    function _removeOrder(uint256 _orderId) internal {
        Order memory _order = order(_orderId);//orders[_orderId];

        // Remove open order from all open orders list
        _removeOpenOrder(_orderId);

        // Remove open order from vault token open orders list
        _removeTokenOpenOrder(_order.tokenId, _orderId);
    }
    
    // --------------------------------------------------------------------------------

    /**
    * @dev Removes an open order from 'openOrderIds' and 'openOrderIndex'. Do not call
    * this function directly. Use '_removeOrder()'.
    * @param _orderId: Open order to remove
    */
    function _removeOpenOrder(uint256 _orderId) internal {
        openOrderIds[openOrderIndex[_orderId]] = openOrderIds[openOrderIds.length.sub(1)];
        openOrderIndex[openOrderIds[openOrderIds.length.sub(1)]] = openOrderIndex[_orderId];
        openOrderIds.pop();
        delete openOrderIndex[_orderId];
    }

    // --------------------------------------------------------------------------------

    /**
    * @dev Removes an open order from 'tokenOpenOrderIds'. Do not call this function
    * directly. Use '_removeOrder()'.
    * @param _tokenId: Vault token
    * @param _orderId: Open order to remove
    */
    function _removeTokenOpenOrder(uint256 _tokenId, uint256 _orderId) internal {
        uint256[] memory _tokenOpenOrderIds = new uint256[](tokenOpenOrderIds[_tokenId].length.sub(1));
        uint j = 0;
        for(uint i = 0; i < tokenOpenOrderIds[_tokenId].length; i++) {
            if(tokenOpenOrderIds[_tokenId][i] != _orderId) {
                _tokenOpenOrderIds[j++] = tokenOpenOrderIds[_tokenId][i];
            }
        }
        tokenOpenOrderIds[_tokenId] = _tokenOpenOrderIds;
    }

    // --------------------------------------------------------------------------------

    /**
    * @dev Set the strategy (trade details) when a user creates a trade. Once a strategy
    * is set for a vault token, the data is immutable. 
    * 
    *           !!! STRATEGY DATA FORMAT WILL DIFFER ACCROSS ALL VAULTS !!!
    *
    * Refer to a specific vault that inherits this contract to determine what the strategy
    * data means.
    * @param _tokens: ERC20 tokens used in the trade
    * @param _amounts: Amount in of an ERC20 token, buy/sell prices, etc.
    * @param _times: Expiration times
    */
    function _setStrategy(
        address[] memory _tokens, 
        uint256[] memory _amounts, 
        uint[] memory _times
    ) internal {
        strategies.push(Strategy(_tokens, _amounts, _times));
    }

    // --------------------------------------------------------------------------------

    /**
    * @dev Use to calculate the amount out of a swap when the decimals of the tokens being
    * swapped are different. Be aware that 'from amount' is multiplied by 1e8 because 
    * '_price' = (price * 1e8). This allows users to place trades at rates below '1'.
    * @param _fromToken: ERC20 token to swap
    * @param _toToken: ERC20 token received from swap
    * @param _fromAmount: Amount of '_fromToken' going into the swap
    * @param _price: Rate of ('_fromToken' / '_toToken') * 1e8
    */
    function _getAmountOut(
        address _fromToken, 
        address _toToken, 
        uint256 _fromAmount, 
        uint256 _price
    ) internal view returns (uint256) {
        uint8 decimalDiff;
        bool pos;

        uint8 fromDecimals = IERC20Meta(_fromToken).decimals();
        uint8 toDecimals = IERC20Meta(_toToken).decimals();

        // 'To token' has either more or an equivalent number of decimals than 'from token'
        if(toDecimals >= fromDecimals) {
            // Calculate the difference in decimals between the two tokens
            decimalDiff = toDecimals - fromDecimals;
            pos = true;
        }
        // 'To token' has fewer decimals than 'from token'
        else {
            // Calculate the difference in decimals between the two tokens
            decimalDiff = fromDecimals - toDecimals;
            pos = false;
        }

        // If 'to token' has more or an equivalent number of decimals than 'from token', 
        // calculate 'to amount' and multiply by the difference in decimals.
        // If 'to token' has fewer decimals than 'from token', calculate 'to amount' and 
        // divide by the difference in decimals.
        uint256 toAmount = _fromAmount.mul(PRICE_MULTIPLIER).div(_price);
        return pos ? toAmount.mul(10 ** uint256(decimalDiff)) : toAmount.div(10 ** uint256(decimalDiff));
    }

    // --------------------------------------------------------------------------------

    /**
    * @dev Use only to create the initial trade. For creating orders use '_createOrder'.
    * This function will set the unique strategy for the user, transfer the starting 
    * amount from the user, and mint a vault token.
    * @param _from: Address of the caller
    * @param _tokens:
    *   [0] = from token
    *   [1] = to token
    * @param _amounts: 
    *   [0] = from amount
    *   !!! REMAINING ELEMENTS ARE SPECIFIC TO THE VAULT THAT INHERITS THIS CONTRACT !!!
    * @param _times: 
    *   [0] = Expiration time
    */
    function _createTrade(
        address _from, 
        address[] memory _tokens, 
        uint256[] memory _amounts, 
        uint[] memory _times
    ) internal returns (uint256) {
        // Restrict the number of vault tokens that can be minted
        require(tokenCounter < maxTokens, "CornFi Vault Base: Max Tokens Reached");

        // Revert if deposit amount is less than the minimum deposit
        require(
            _amounts[0] >= minimumDeposit[_tokens[0]], 
            "CornFi Vault Base: Minimum Deposit Not Met"
        );

        // Create the strategy
        _setStrategy(_tokens, _amounts, _times);

        IERC20 depositToken = IERC20(_tokens[0]);

        // For a security check after transfer
        uint256 balanceBefore = depositToken.balanceOf(address(this));

        // Transfer deposit amount from user
        depositToken.safeTransferFrom(_from, address(this), _amounts[0]);

        // Ensure full amount is transferred
        require(
            depositToken.balanceOf(address(this)).sub(balanceBefore) == _amounts[0], 
            "CornFi Vault Base: Deposit Error"
        );

        IStrategy strat = _tokenStrategies[_tokens[0]];

        // Deposit fee
        uint256 depositFee = strat.depositFee(_amounts[0]);

        if(depositFee > 0) {
            IERC20(_tokens[0]).safeTransfer(controller.DepositFees(), depositFee);
        }

        // Adjust token amount to include fee
        uint256 amountInWithFee = _amounts[0].sub(depositFee);
        tokenAmounts[tokenCounter][_tokens[0]] = amountInWithFee;

        // Deposit ERC20 token into holding strategy
        IERC20(_tokens[0]).approve(address(strat), amountInWithFee);
        strat.deposit(address(this), _tokens[0], amountInWithFee);  

        // Mint a vault token to the caller
        _safeMint(_from, tokenCounter++);

        return amountInWithFee;
    }

    // --------------------------------------------------------------------------------

    /**
    * @dev After calling this function, all orders associated with '_tokenId' will be
    * closed and their tokens will be returned to the token owner. The token is then
    * burnt and cannot be used again. Callers can only withdraw from vault tokens that
    * they own.
    * @param _from: Address of the caller
    * @param _tokenId: Vault token to be withdrawn
    */
    function _withdraw(address _from, uint256 _tokenId) internal {
        // Caller can only withdraw from vault tokens they own
        require(
            ownerOf(_tokenId) == _from, 
            "CornFi Vault Base: Caller is Not the Token Owner"
        );

        // Withdraw all tokens associated with a vault token and send tokens to the owner
        Strategy memory strat = strategies[_tokenId];
        for(uint i = 0; i < strat.tokens.length; i++) {
            // Withdraw tokens with amounts over zero
            if(tokenAmounts[_tokenId][strat.tokens[i]] > 0) {
                // Withdraw the token and send to vault token owner
                _tokenStrategies[strat.tokens[i]].withdraw(
                    _from, 
                    strat.tokens[i], 
                    tokenAmounts[_tokenId][strat.tokens[i]]
                );
                tokenAmounts[_tokenId][strat.tokens[i]] = 0;
            }
        }

        // Get all open orders associated with '_tokenId'
        uint256[] memory orderIds = tokenOpenOrderIds[_tokenId];

        // Close the open orders
        for(uint j = 0; j < orderIds.length; j++) {
            _removeOpenOrder(orderIds[j]);
            // Orders that are closed but not filled will have a timestamp of '1' vs. '0'
            // when active and not filled or the timestamp of when the order was filled.
            orders[orderIds[j]].timestamp = 1;
        }

        // Remove all vault token open orders
        delete tokenOpenOrderIds[_tokenId];

        // Burn the vault token
        _burn(_tokenId);
    }

    // --------------------------------------------------------------------------------

    /**
    * @dev Use when filling orders. Adjusts token amounts associated with the owning
    * vault token and closes the open order.
    *
    * !!!  CALL THIS FUNCTION ONLY AFTER COMPLETING THE SWAP, ACCOUNTING FOR FEES,  !!!
    * !!!  AND SETTING 'amounts[1]' OF THE ORDER TO THE ACTUAL AMOUNT THE USER      !!!
    * !!!  WILL RECEIVE.                                                            !!!
    *
    * @param _orderId: Order to close
    */
    function _closeOrderHelper(uint256 _orderId) internal {
        Order memory _order = order(_orderId);

        // Adjust 'to token' amounts to reflect the amount received from the swap
        tokenAmounts[_order.tokenId][_order.tokens[1]] = tokenAmounts[_order.tokenId][_order.tokens[1]].add(_order.amounts[1]);
        
        // Adjust 'from token' amounts to reflect the amount used for the swap
        tokenAmounts[_order.tokenId][_order.tokens[0]] = tokenAmounts[_order.tokenId][_order.tokens[0]].sub(_order.amounts[0]);
        
        // Close trade
        orders[_orderId].timestamp = block.timestamp;

        // Remove open order
        _removeOrder(_orderId);
    }

    // --------------------------------------------------------------------------------

    /**
    * @dev Use to fill orders. Ensures that the order is active and fills the order when
    * trade conditions are met.
    * @param _order: Order to fill
    * @param _router: Router used to fill the order
    * @param _path: Path used to fill the order
    * @return (minimumAmountOut, amountOut) Returns the amount out including slippage and
    * the actual amount out from the swap.
    */
    function _swap(
        Order memory _order, 
        IUniswapV2Router02 _router, 
        address[] memory _path
    ) internal returns (uint256, uint256) {
        // Check for an expiration time. Orders with '0' as the expiration time will not
        // expire.
        if(_order.times[0] > 0) {
            // Revert if expiration time has passed
            require(block.timestamp < _order.times[0], "CornFi Vault Base: Expired Order");
        }

        // Only fill active orders
        require(_order.timestamp == 0, "CornFi Vault Base: Order is Inactive");

        // Withdraw tokens from holding strategy
        strategy(_order.tokens[0]).withdraw(address(this), _order.tokens[0], _order.amounts[0]);

        uint256 lastElement = _path.length.sub(1);

        // Path must start with the 'from token' and end with the 'to token' 
        require(
            _path[0] == _order.tokens[0] &&
            _path[lastElement] == _order.tokens[1], 
            "CornFi Vault Base: Invalid Path"
        );

        // Check if tokens were deactivated since order was created
        require(
            activeTokens[_path[0]] && activeTokens[_path[lastElement]], 
            "CornFi Vault Base: Invalid Tokens"
        );

        // Get current amount out from the swap and account for slippage
        uint256 amountOut = _router.getAmountsOut(_order.amounts[0], _path)[lastElement];
        uint256 minAmountOut = controller.slippage(amountOut); 
        
        // Swap tokens
        IERC20(_order.tokens[0]).approve(address(_router), _order.amounts[0]);
        uint256 swapAmountOut = _router.swapExactTokensForTokens(
            _order.amounts[0], 
            minAmountOut, 
            _path, 
            address(this), 
            block.timestamp.add(60)
        )[lastElement];

        IStrategy strat = strategy(_order.tokens[1]);

        // Set target amount
        if(_order.amounts[2] == 0) {
            orders[_order.orderId].amounts[2] = _order.amounts[1];
        }

        // Transaction fees
        uint256 txFee = strategy(_order.tokens[0]).txFee(amountOut);

        if(txFee > 0) {
            IERC20(_order.tokens[1]).safeTransfer(controller.Fees(), txFee);

            // Adjust user balance
            orders[_order.orderId].amounts[1] = amountOut.sub(txFee);
        }
        else {
            orders[_order.orderId].amounts[1] = amountOut;
        }

        // Deposit swapped tokens into respective holding strategy
        IERC20(_order.tokens[1]).approve(address(strat), orders[_order.orderId].amounts[1]);
        strat.deposit(address(this), _order.tokens[1], orders[_order.orderId].amounts[1]);

        // Close order, remove from open orders list
        _closeOrderHelper(_order.orderId);
        return (minAmountOut, swapAmountOut);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

pragma solidity >=0.5.0;

interface IERC20Meta {
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;


pragma experimental ABIEncoderV2;

interface IStrategy {
    struct Tokens {
        address token;
        address amToken;
    }

    event Deposit(address indexed vault, address indexed token, uint256 amount);
    event Withdraw(address indexed vault, address indexed token, uint256 amount);
    event TokenAdded(address token, address amToken);


    function depositFee(uint256 _amountIn) external view returns (uint256);
    function txFee(uint256 _amountIn) external view returns (uint256);
    function fillerFee(uint256 _amountIn) external view returns (uint256);
    function deposit(address _from, address _token, uint256 _amount) external;
    function withdraw(address _from, address _token, uint256 _amount) external;
    function vaultDeposits(address _vault, address _token) external view returns (uint256);

    function DEPOSIT_FEE_POINTS() external view returns (uint256);
    function DEPOSIT_FEE_BASE_POINTS() external view returns (uint256);
    function TX_FEE_POINTS() external view returns (uint256);
    function TX_FEE_BASE_POINTS() external view returns (uint256);
    function rebalanceToken(address _token) external;
    function claim() external;
    function balanceRatio(address _token) external view returns (uint256, uint256);
    function rebalancePoints() external view returns (uint256);
    function rebalanceBasePoints() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IVaultBase.sol";
import "./IUniswapV2Router02.sol";
import "./IPokeMe.sol";
import "./IResolver.sol";
import "./IStrategy.sol";
import "./IGasTank.sol";


pragma experimental ABIEncoderV2;

interface IController {
    
    struct UserTokens {
        address vault;
        uint256 tokenId;
    }

    // --------------------------------------------------------------------------------
    // ///////////////////////////// Only Owner Functions /////////////////////////////
    // --------------------------------------------------------------------------------

    function pause() external;
    function unpause() external;
    function setVaultURI(uint256 _vaultId, string memory _URI) external;
    function deactivateRouter(IUniswapV2Router02 _router) external;
    function addVault(address _vault) external;
    function deactivateVault(address _vault) external;
    function setSlippage(uint256 _slippagePoints, uint256 _slippageBasePoints) external;
    function gelatoSettings(IPokeMe _pokeMe, IResolver _resolver, bool _gelato) external;
    function deactivateToken(uint256 _vaultId, address _token) external;
    function setTokenStrategy(uint256 _vaultId, address _token, address _strategy, uint256 _minDeposit) external;
    function changeTokenMinimumDeposit(uint256 _vaultId, address _token, uint256 _minDeposit) external;

    // --------------------------------------------------------------------------------
    // ///////////////////////////// Read-Only Functions //////////////////////////////
    // --------------------------------------------------------------------------------

    function NOT_A_VAULT() external view returns (uint8);
    function ACTIVE_VAULT() external view returns (uint8);
    function DEACTIVATED_VAULT() external view returns (uint8);
    function gelato() external view returns (address);
    function ETH() external view returns (address);
    function PokeMe() external view returns (IPokeMe);
    function Resolver() external view returns (IResolver);
    function GasToken() external view returns (address);
    function Gelato() external view returns (bool);
    function taskIds(uint256 _vaultId, uint256 _orderId) external view returns (bytes32);
    function tokenMaxGas(uint256 _vaultId, uint256 _tokenId) external view returns (uint256);
    function GasTank() external view returns (IGasTank);

    function routers(uint256 _index) external view returns (IUniswapV2Router02);
    function activeRouters(IUniswapV2Router02 _router) external view returns (bool);
    function vaults(uint256 _index) external view returns (IVaultBase);
    function Fees() external view returns (address);
    function DepositFees() external view returns (address);
    function SLIPPAGE_POINTS() external view returns (uint256);
    function SLIPPAGE_BASE_POINTS() external view returns (uint256);
    function holdingStrategies(uint256 _index) external view returns (address);
    function priceMultiplier(uint256 _vaultId) external view returns (uint256);
    
    function tokenStrategy(uint256 _vaultId, address _token) external view returns (IStrategy);
    function tokenMinimumDeposit(uint256 _vaultId, address _token) external view returns (uint256);
    function tokens(uint256 _vaultId, uint256 _index) external view returns (address);
    function activeTokens(uint256 _vaultId, address _token) external view returns (bool);
    function tokensLength(uint256 _vaultId) external view returns (uint256);
    function slippage(uint256 _amountIn) external view returns (uint256);
    function vaultURI(uint256 _vaultId) external view returns (string memory);
    function vault(address _vault) external view returns (uint8);
    function vaultId(address _vault) external view returns (uint256);
    function vaultsLength() external view returns (uint256);
    
    function viewTrades(
        uint256 _vaultId, 
        uint256 _tokenId, 
        uint256[] memory _tradeIds
    ) external view returns (IVaultBase.Order[][] memory);
    
    function viewOrder(
        uint256 _vaultId, 
        uint256 _orderId
    ) external view returns (IVaultBase.Order memory);
    
    function viewOrders(
        uint256 _vaultId, 
        uint256[] memory _orderIds
    ) external view returns (IVaultBase.Order[] memory);
    
    function viewOpenOrdersByToken(
        uint256 _vaultId, 
        uint256 _tokenId
    ) external view returns (IVaultBase.Order[] memory);
    
    function viewOpenOrdersInRange(
        uint256 _vaultId, 
        uint256 _start, 
        uint256 _end
    ) external view returns (IVaultBase.Order[] memory);
    
    function ordersLength(uint256 _vaultId) external view returns (uint256);
    function openOrdersLength(uint256 _vaultId) external view returns (uint256);
    
    function tokenOpenOrdersLength(
        uint256 _vaultId, 
        uint256 _tokenId
    ) external view returns (uint256);
    
    function tokenLength(uint256 _vaultId) external view returns (uint256);

    function tokenTradeLength(
        uint256 _vaultId, 
        uint256 _tokenId
    ) external view returns (uint256);

    function vaultTokensByOwner(address _owner) external view returns (UserTokens[] memory);


    // --------------------------------------------------------------------------------
    // /////////////////////////////// Vault Functions ////////////////////////////////
    // --------------------------------------------------------------------------------

    function createTrade(
        uint256 _vaultId, 
        address[] memory _tokens, 
        uint256[] memory _amounts, 
        uint[] memory _times, 
        uint256 _maxGas
    ) external;

    function fillOrderGelato(
        uint256 _vaultId, 
        uint256 _orderId, 
        IUniswapV2Router02 _router, 
        address[] memory _path
    ) external;

    function withdraw(uint256 _vaultId, uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IUniswapV2Router02.sol";
import "./IStrategy.sol";

pragma experimental ABIEncoderV2;

interface IVaultBase {
    struct Order {
        uint256 tokenId;
        uint256 tradeId;
        uint256 orderId;
        uint timestamp;
        address[2] tokens;
        uint256[3] amounts;
        uint[] times;
    }

    struct Strategy {
        address[] tokens;
        uint256[] amounts;
        uint[] times;
    }

    struct Token {
        address token;
        uint256 amount;
    }

    function tokenCounter() external view returns (uint256);
    function maxTokens() external view returns (uint256);
    function owner() external view returns (address);
    function _tokenTradeLength(uint256 _tokenId) external view returns (uint256);
    function setStrategy(address _token, address _strategy, uint256 _minDeposit) external;
    function changeMinimumDeposit(address _token, uint256 _minDeposit) external;
    function strategy(address _token) external view returns (IStrategy);
    function minimumDeposit(address _token) external view returns (uint256);

    function trade(uint256 _tokenId, uint256 _tradeId) external view returns (uint256[] memory);
    function order(uint256 _orderId) external view returns (Order memory);
    function ordersLength() external view returns (uint256);
    function openOrdersLength() external view returns (uint256);
    function openOrderId(uint256 _index) external view returns (uint256);
    function tokenOpenOrdersLength(uint256 _tokenId) external view returns (uint256);
    function tokenOpenOrderId(uint256 _tokenId, uint256 _index) external view returns (uint256);
    function viewTokenAmounts(uint256 _tokenId) external view returns (Token[] memory);
    function viewStrategy(uint256 _tokenId) external view returns (Strategy memory);
    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function createTrade(address _from, address[] memory _tokens, uint256[] memory _amounts, uint[] memory _times) external returns (uint256[] memory);
    function fillOrder(uint256 _orderId, IUniswapV2Router02 _router, address[] memory _path) external returns (Order[] memory, uint256[] memory);
    function withdraw(address _from, uint256 _tokenId) external;

    function balanceOf(address _owner) external view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);

    function tokens(uint256 _index) external view returns (address);
    function tokensLength() external view returns (uint256);
    function deactivateToken(address _token) external;
    function activeTokens(address _token) external view returns (bool);

    function setBaseURI(string memory) external;
    function BASE_URI() external view returns (string memory);
    function PRICE_MULTIPLIER() external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;


interface IPokeMe {
    function gelato() external view returns (address payable);
    
    function createTimedTask(
        uint128 _startTime,
        uint128 _interval,
        address _execAddress,
        bytes4 _execSelector,
        address _resolverAddress,
        bytes calldata _resolverData,
        address _feeToken,
        bool _useTreasury
    ) external returns (bytes32 task);

    function createTaskNoPrepayment(
        address _execAddress,
        bytes4 _execSelector,
        address _resolverAddress,
        bytes calldata _resolverData,
        address _feeToken
    ) external returns (bytes32 task);

    function createTask(
        address _execAddress,
        bytes4 _execSelector,
        address _resolverAddress,
        bytes calldata _resolverData
    ) external returns (bytes32 task);

    function cancelTask(bytes32 _taskId) external;

    function exec(
        uint256 _txFee,
        address _feeToken,
        address _taskCreator,
        bool _useTaskTreasuryFunds,
        bytes32 _resolverHash,
        address _execAddress,
        bytes calldata _execData
    ) external ;

    function getTaskId(
        address _taskCreator,
        address _execAddress,
        bytes4 _selector,
        bool _useTaskTreasuryFunds,
        address _feeToken,
        bytes32 _resolverHash
    ) external pure returns (bytes32);

    function getSelector(string calldata _func) external pure returns (bytes4);
    
    function getResolverHash(
        address _resolverAddress,
        bytes memory _resolverData
    ) external pure returns (bytes32);

    function getTaskIdsByUser(address _taskCreator)
        external
        view
        returns (bytes32[] memory);

    function getFeeDetails() external view returns (uint256, address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IUniswapV2Router02.sol";


interface IResolver {
    function checker(
        uint256 _vaultId, 
        uint256 _orderId, 
        address _fromToken, 
        address _toToken, 
        uint256 _fromAmount
    ) external view returns (bool, bytes memory);

    function findBestPathExactIn(
        address _fromToken, 
        address _toToken, 
        uint256 _amountIn
    ) external view returns (address, address[] memory, uint256);

    function findBestPathExactOut(
        address _fromToken, 
        address _toToken, 
        uint256 _amountOut
    ) external view returns (address, address[] memory, uint256);

    function getAmountOut(
        IUniswapV2Router02 _router, 
        uint256 _amountIn, 
        address _fromToken, 
        address _connectorToken, 
        address _toToken
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IGasTank {
    event DepositGas(address indexed user, uint256 amount);
    event WithdrawGas(address indexed user, uint256 amount);
    event Pay(address indexed payer, address indexed payee, uint256 amount);
    event Approved(address indexed payer, address indexed payee, bool approved);

    // View
    function userGasAmounts(address _user) external view returns (uint256);
    function approvedPayees(uint256 _index) external view returns (address);
    function _approvedPayees(address _payee) external view returns (bool);
    function userPayeeApprovals(address _payer, address _payee) external view returns (bool);
    function txFee() external view returns (uint256);
    function feeAddress() external view returns (address);
    
    // Users
    function depositGas(address _receiver) external payable;
    function withdrawGas(uint256 _amount) external;
    function approve(address _payee, bool _approve) external;
    
    // Approved payees
    function pay(address _payer, address _payee, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
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