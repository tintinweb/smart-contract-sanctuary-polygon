// SPDX-License-Identifier: BUSL-1.1

/*
                  *                                                  █                              
                *****                                               ▓▓▓                             
                  *                                               ▓▓▓▓▓▓▓                         
                                   *            ///.           ▓▓▓▓▓▓▓▓▓▓▓▓▓                       
                                 *****        ////////            ▓▓▓▓▓▓▓                          
                                   *       /////////////            ▓▓▓                             
                     ▓▓                  //////////////////          █         ▓▓                   
                   ▓▓  ▓▓             ///////////////////////                ▓▓   ▓▓                
                ▓▓       ▓▓        ////////////////////////////           ▓▓        ▓▓              
              ▓▓            ▓▓    /////////▓▓▓///////▓▓▓/////////       ▓▓             ▓▓            
           ▓▓                 ,////////////////////////////////////// ▓▓                 ▓▓         
        ▓▓                  //////////////////////////////////////////                     ▓▓      
      ▓▓                  //////////////////////▓▓▓▓/////////////////////                          
                       ,////////////////////////////////////////////////////                        
                    .//////////////////////////////////////////////////////////                     
                     .//////////////////////////██.,//////////////////////////█                     
                       .//////////////////////████..,./////////////////////██                       
                        ...////////////////███████.....,.////////////////███                        
                          ,.,////////////████████ ........,///////////████                          
                            .,.,//////█████████      ,.......///////████                            
                               ,..//████████           ........./████                               
                                 ..,██████                .....,███                                 
                                    .██                     ,.,█                                    
                                                                                                    
                                                                                                    
                                                                                                    
               ▓▓            ▓▓▓▓▓▓▓▓▓▓       ▓▓▓▓▓▓▓▓▓▓        ▓▓               ▓▓▓▓▓▓▓▓▓▓          
             ▓▓▓▓▓▓          ▓▓▓    ▓▓▓       ▓▓▓               ▓▓               ▓▓   ▓▓▓▓         
           ▓▓▓    ▓▓▓        ▓▓▓    ▓▓▓       ▓▓▓    ▓▓▓        ▓▓               ▓▓▓▓▓             
          ▓▓▓        ▓▓      ▓▓▓    ▓▓▓       ▓▓▓▓▓▓▓▓▓▓        ▓▓▓▓▓▓▓▓▓▓       ▓▓▓▓▓▓▓▓▓▓          
*/

pragma solidity 0.8.17;

import "../interfaces/IMarketplace.sol";
import "./MarketplaceInteraction.sol";

/// @title Marketplace
/// @author Angle Labs, Inc.
/// @notice A permissionless contract for peer-to-peer token exchanges using Narrowed Dutch Auctions
/// @dev This contract is built for people that want to trade illiquid tokens on-chain at the best
/// possible price, and that need a price discovery mechanism for this
/// @dev It implements Dutch-auctions to allow people to buy or sell illiquid tokens from market makers
/// or other parties while minimizing slippage
/// @dev This contract is immutable and fully permissionless: there is no address with admin rights on it
/// @dev This contract works with markets of (`baseToken`, `quoteToken`) pairs where people can place orders to buy
/// or sell the `baseToken`. On a specific market, there can only be one type of order at a time, meaning a market is either
/// buying or selling
/// @dev It can handle an infinite amount of markets, and there can be several markets for the same
/// (`baseToken`, `quoteToken`) pair.
/// @dev This contract is not adapted to rebasing tokens and tokens for which fees can be taken during transfers
/// @dev Orders on a market are handled based on a first arrived first served principle, meaning the first orders created
/// on a market are the first ones that will be handled in the auction. Markets can have a privileged address that is always
/// served first when placing its orders even when other orders in the same direction were placed before
/// @dev An address on a market in this `Marketplace` contract can only have one order
/// @dev This contract complies with the ERC721Metadata interface: each order in this contract is handled as a NFT
/// @notice This file in particular contains the view functions to query the state of a specific market
contract Marketplace is IMarketplace, MarketplaceInteraction {
    // ============================= MARKETPLACE LOGIC =============================

    /// @notice Returns the quote token and base token addresses associated to a market with `marketId`
    function getMarketTokens(bytes32 marketId) external view returns (address quoteToken, address baseToken) {
        Market storage market = markets[marketId];
        return (address(market.quoteToken), address(market.baseToken));
    }

    /// @notice Returns the list of all the open orders of a market
    function getOpenOrders(bytes32 marketId) external view returns (Order[] memory) {
        Market storage market = markets[marketId];
        uint48 firstIndex = market.status.firstIndex;
        uint48 lastIndex = market.status.lastIndex;
        uint48 size;
        uint48[] memory indexes = new uint48[](lastIndex - firstIndex);
        uint48 index = firstIndex;
        while (index < lastIndex) {
            indexes[size] = index;
            index = _readNextOrder(orders[marketId][index].next, index);
            unchecked {
                ++size;
            }
        }

        Order[] memory openOrders = new Order[](size);

        for (uint48 i; i < size; ) {
            openOrders[i] = orders[marketId][indexes[i]];
            unchecked {
                ++i;
            }
        }
        return openOrders;
    }

    /// @notice Returns the mode at which a market is
    /// @return 1 if the if the market is buying, -1 if the market is selling and 0 if there are no open orders
    /// @dev This function returns 0 on non initialized markets
    function getMarketMode(bytes32 marketId) external view returns (int8) {
        Market storage market = markets[marketId];
        if (market.status.inversionTimestamp == 0) return 0;
        else if (orders[marketId][market.status.firstIndex].amount > 0) return 1;
        else return -1;
    }

    /// @notice Returns true if there is at least 1 open order for `marketId` and false otherwise
    function hasOpenOrders(bytes32 marketId) external view returns (bool) {
        Market storage market = markets[marketId];
        return market.status.firstIndex < market.status.lastIndex;
    }

    /// @notice Returns the order of an address on the market `marketId`
    /// @return openOrder Whether the address has an open order or not
    /// @return order Order of the address on the market (it's an empty struct if the address has no open order)
    /// @return buyOrSell Whether the market is buying or selling
    /// @dev An address can only have one order per market
    function getAddressOrder(bytes32 marketId, address owner)
        external
        view
        returns (
            bool openOrder,
            Order memory order,
            bool buyOrSell
        )
    {
        uint48 orderIndex = orderIndexes[marketId][owner];
        Market storage market = markets[marketId];
        buyOrSell = _marketMode(marketId, market);
        if (orderIndex > 1) {
            unchecked {
                return (true, orders[marketId][orderIndex], buyOrSell);
            }
        }
        return (false, Order(0, 0, address(0), 0), buyOrSell);
    }

    /// @notice Returns the sum of the pending orders placed before the order of `owner` in the market
    /// and an estimate of the value of the other token that would be needed to fill these orders
    /// @return amountBrought Sum of the amounts in the orders placed before the order of `owner`
    /// @return amountToBring Estimate of the value that would be needed to fill all the orders before the
    /// `owner` order
    /// @dev If `owner` has no open order or the market does not exist, this function returns 0
    function getPendingPrior(bytes32 marketId, address owner)
        external
        view
        returns (uint256 amountBrought, uint256 amountToBring)
    {
        uint48 orderIndex = orderIndexes[marketId][owner];
        Market storage market = markets[marketId];
        if (orderIndex > 1) {
            (amountBrought, amountToBring, ) = _getOrder(marketId, market, orderIndex, -1);
        }
    }

    /// @notice Gets the sum of the amounts of all the buy orders in the market
    /// @return amountBroughtToBuy Total amount of tokens brought to buy
    /// @return amountToSell Amount of tokens that can be sold given current market conditions if all orders are filled
    /// @dev Amounts returned will be 0 if there's no buy order in the market or if the market does not exist
    function getBuyOrderAmount(bytes32 marketId)
        external
        view
        returns (uint256 amountBroughtToBuy, uint256 amountToSell)
    {
        Market storage market = markets[marketId];
        (amountBroughtToBuy, amountToSell, ) = _getOrder(marketId, market, market.status.lastIndex, 1);
    }

    /// @notice Gets the sum of the amounts of all the sell orders in the market
    /// @return amountBroughtToSell Total amount of tokens to sell in the market
    /// @return amountToBuy Amount of tokens that can be bought given current market conditions if all orders are filled
    /// @dev Amounts returned will be 0 if there's no sell order in the market or if the market does not exist
    function getSellOrderAmount(bytes32 marketId)
        external
        view
        returns (uint256 amountBroughtToSell, uint256 amountToBuy)
    {
        Market storage market = markets[marketId];
        (amountBroughtToSell, amountToBuy, ) = _getOrder(marketId, market, market.status.lastIndex, 0);
    }

    /// @notice Gets the sum of all the orders in the market, what it would take to fill all the orders and
    /// if these pending orders are buy orders or sell orders
    /// @return outAmount Total amount of tokens to buy or sell in the market
    /// @return inAmount Amount of tokens that it'd take to fill all orders giving current market conditions
    /// @return mode Wether the market is currently in buy or sell mode
    function getOrdersAmount(bytes32 marketId)
        external
        view
        returns (
            uint256 outAmount,
            uint256 inAmount,
            bool mode
        )
    {
        Market storage market = markets[marketId];
        return _getOrder(marketId, market, market.status.lastIndex, -1);
    }

    /// @notice Computes the current price in the market `marketId`
    /// @dev This takes into account of the oracle value as well as the discount/premium on this price
    /// based on the imbalance between buy and sell orders
    /// @dev Returned value is zero if there are no open orders
    function computeMarketPrice(bytes32 marketId) external view returns (uint256) {
        Market storage market = markets[marketId];
        return _computeMarketPrice(market, _marketMode(marketId, market));
    }

    /// @notice Estimates how much of `quoteToken` you would get if a sell order of `amount` of `baseToken`
    /// was executed on `marketId`
    function estimateBaseToQuote(bytes32 marketId, uint256 amount) external view returns (uint256) {
        Market storage market = markets[marketId];
        return _estimateBaseToQuote(market, amount, _marketMode(marketId, market));
    }

    /// @notice Estimates how much of `baseToken` you would get if a buy order of `amount` of `quoteToken`
    /// was executed on `marketId`
    function estimateQuoteToBase(bytes32 marketId, uint256 amount) external view returns (uint256) {
        Market storage market = markets[marketId];
        return _estimateQuoteToBase(market, amount, _marketMode(marketId, market));
    }

    // ================================ ERC721 LOGIC ===============================

    /// @notice Returns the owner of a given NFT
    /// @param id Identifier containing `marketId` + `orderIndex` defining an order
    /// @dev The function reads from storage and provides no guarantee that the order is
    /// actually valid and used in the ongoing auction
    function ownerOf(uint256 id) external view returns (address owner) {
        (bytes32 marketId, uint48 orderIndex) = _getData(id);
        owner = orders[marketId][orderIndex].owner;
        if (owner == address(0)) revert NotAllowed();
    }

    /// @notice Disabled function for the ERC721 interface
    /// @dev Warning: this function isn't implemented as it'd require
    /// additional storage and shouldn't be useful
    function balanceOf(address) external pure returns (uint256) {
        return 0;
    }

    /// @notice ERC165 logic
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return
            interfaceId == type(IMarketplace).interfaceId ||
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /// @notice ERC721Metadata logic
    function name() external pure returns (string memory) {
        return "Angle ERC-20 Marketplace";
    }

    /// @notice ERC721Metadata logic
    function symbol() external pure returns (string memory) {
        return "ag-mktplace";
    }

    /// @notice ERC721Metadata logic
    function tokenURI(uint256 id) external view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "https://marketplace.angle.money/",
                    _uintToString(block.chainid),
                    "/",
                    _uintToString(id)
                )
            );
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title IMarketplace
/// @author Angle Labs, Inc.
interface IMarketplace {
    function getMarketTokens(bytes32 marketId) external view returns (address, address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IMarketplace.sol";

import "./MarketplaceHelpers.sol";

/// @title MarketplaceInteraction
/// @author Angle Labs, Inc.
/// @notice External functions needed to interact and manage a given market in the `Marketplace` contract
contract MarketplaceInteraction is MarketplaceHelpers, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Math for uint256;

    // ============================= MARKET INTERACTION ============================

    /// @notice Places on order on a market and either executes it by filling pending orders or places it at
    /// the last position of the order book (except if the order is for a privileged address)
    /// @param marketId Id of the market on which the order should be placed
    /// @param amount Amount of tokens to bring to acquire the desired token: for instance if the market is ETH/USDC
    /// and I place a buy order, then if `amount = 10**6`, I am bringing 1 USDC to buy ETH
    // > 0 means it is a buy order
    // < 0 means it is a sell order
    /// @param owner Address for which this order is placed: this is the address which will receive the tokens
    /// bought through this contract, and that will be able to reduce or remove the order.
    /// By default if `onBehalfOf` is not specified it will be `msg.sender`
    /// @param limitMarketPrice Maximum or minimum market price the taker is willing to accept
    /// Useful only when this function leads to orders being filled
    /// @return Whether the order was fully executed: if I bring 1 agEUR, but given current pending orders
    /// I can only buy ETH using 0.5 agEUR then it's considered that the order is not fully executed, and
    /// this value will be false
    /// @return Amount of tokens obtained from the order execution
    /// @return Id of the order in the contract if my order has not been fully executed and still pending in the contract
    /// @dev Due to rounding errors, this contract may accumulate dusty amounts of both tokens when orders are filled.
    /// While this is not problematic, for tokens with a big number of decimals, this may be less suited for tokens
    /// which have fewer decimals.
    function make(
        bytes32 marketId,
        int256 amount,
        address owner,
        uint256 limitMarketPrice
    )
        external
        nonReentrant
        returns (
            bool,
            uint256,
            uint48
        )
    {
        Market storage market = markets[marketId];
        OrderFillingParameters memory p;
        uint256 amountCasted = _abs(amount);

        if (amount > 0) {
            p.tokenIn = market.quoteToken;
            p.tokenOut = market.baseToken;
        } else {
            p.tokenIn = market.baseToken;
            p.tokenOut = market.quoteToken;
        }
        // By default the order owner is the `msg.sender`
        if (owner == address(0)) owner = msg.sender;

        // If the market is invalid, then the `tokenIn` address is null and this function should revert
        p.tokenIn.safeTransferFrom(msg.sender, address(this), amountCasted);

        // Handling the case with no open orders (when `market.status.inversionTimestamp = 0`)
        if (market.status.inversionTimestamp == 0) {
            uint48 orderIndex = _initiateMarket(marketId, market, amount, owner);
            return (false, 0, orderIndex);
        } else {
            // In this case there is at least one open order in the market
            bool marketMode = _marketMode(marketId, market);
            if (marketMode == (amount > 0)) {
                // Here, the order is placed in the same direction as the current state of the market
                uint48 orderIndex = orderIndexes[marketId][owner];
                if (orderIndex > 1) {
                    // If the address has an open order, we simply increase the order amount of this address
                    {
                        int256 orderAmount = orders[marketId][orderIndex].amount + amount;
                        orders[marketId][orderIndex].amount = orderAmount;
                        emit OrderUpdated(marketId, orderIndex, orderAmount);
                    }
                } else {
                    if (owner == market.status.privilegedAddress) {
                        // If the address is the privileged address (and has no prior order), we add it
                        // in the first position in the array
                        orderIndex = market.status.firstIndex - 1;
                        market.status.firstIndex = orderIndex;
                    } else {
                        // If the order is not for the privileged address, we add the order in the order array
                        // We also increment `market.status.lastIndex`
                        orderIndex = market.status.lastIndex++;
                    }
                    _addOrder(marketId, market, orderIndex, amount, owner, true);
                }
                return (false, 0, orderIndex);
            } else {
                // If the order is a taker order (placed in the other direction than the market's current orders), then
                // we fill the pending orders one by one till there's not enough left or no open order left
                if (marketMode) {
                    // If the market buys then `msg.sender` is selling
                    p.numerator = _computeMarketPrice(market, marketMode);
                    p.denominator = _BASE_ORACLE;
                    if (p.numerator < limitMarketPrice) revert MarketPriceNotInRange();
                } else {
                    // If the market sells then `msg.sender` is buying
                    p.numerator = _BASE_ORACLE;
                    p.denominator = _computeMarketPrice(market, marketMode);
                    if (p.denominator > limitMarketPrice) revert MarketPriceNotInRange();
                }

                // Converting `amount` in `tokenOut`
                uint256 amountInOut = amountCasted.mulDiv(
                    tokenBase[p.tokenOut] * p.numerator,
                    p.denominator * tokenBase[p.tokenIn],
                    Math.Rounding.Down
                );
                p.amountInOut = amountInOut;

                {
                    uint256 amountPaidIn = _fillOrder(marketId, market, marketMode, amountCasted, p);

                    if (p.amountInOut == 0) {
                        p.tokenOut.safeTransfer(owner, amountInOut);
                        return (true, amountInOut, 0);
                    }

                    // At this point, it means that we have finished processing all the orders and
                    // that an inversion took place

                    // This is the amount of the order we've filled
                    p.tokenOut.safeTransfer(owner, amountInOut - p.amountInOut);

                    // Computing the amount that needs to be left in the order
                    if (marketMode) {
                        // Market was buying: we reduce the size of the sell order
                        amount = amount + int256(amountPaidIn);
                    } else {
                        // Market was selling: we reduce the size of the buy order
                        amount = amount - int256(amountPaidIn);
                    }
                }
                return (false, amountInOut - p.amountInOut, _initiateMarket(marketId, market, amount, owner));
            }
        }
    }

    /// @notice Allows an address to take orders on a market: based on where the market is at the
    /// moment the transaction is passed, this function will either fill buy or sell orders.
    /// @param marketId Market of interest
    /// @param amount Amount of token the taker is willing to swap: if the ETH/agEUR market is currently buying ETH,
    /// then this amount should be an amount of ETH to sell
    /// @param onBehalfOf Address to which tokens obtained should be sent
    /// @param limitMarketPrice Maximum or minimum market price the taker is willing to accept:
    /// - If the market is buying and the taker is selling, then this is a minimum price
    /// - If the market is selling and the taker is buying, then this is a maximum price
    /// @return Amount of in-tokens finally sent by `msg.sender`
    /// @return Amount of out-tokens obtained by `onBehalfOf`
    /// @dev No order is created in this case if all orders are taken: the taker is just going to be refunded
    /// by a corresponding amount of in tokens. As such the amount of in-tokens finally sent may not necessarily
    /// be equal to `amount`. It may only be inferior or equal to this amount.
    function take(
        bytes32 marketId,
        uint256 amount,
        address onBehalfOf,
        uint256 limitMarketPrice
    ) external nonReentrant returns (uint256, uint256) {
        Market storage market = markets[marketId];
        OrderFillingParameters memory p;

        if (market.status.inversionTimestamp == 0) revert NoOpenOrder();
        bool marketMode = _marketMode(marketId, market);
        if (marketMode) {
            // If the market buys then `msg.sender` is selling
            p.tokenIn = market.baseToken;
            p.tokenOut = market.quoteToken;
            p.numerator = _computeMarketPrice(market, marketMode);
            p.denominator = _BASE_ORACLE;
            if (p.numerator < limitMarketPrice) revert MarketPriceNotInRange();
        } else {
            // If the market sells then `msg.sender` is buying
            p.tokenIn = market.quoteToken;
            p.tokenOut = market.baseToken;
            p.numerator = _BASE_ORACLE;
            p.denominator = _computeMarketPrice(market, marketMode);
            if (p.denominator > limitMarketPrice) revert MarketPriceNotInRange();
        }

        // Converting `amount` in `tokenOut`
        uint256 amountInOut = amount.mulDiv(
            tokenBase[p.tokenOut] * p.numerator,
            p.denominator * tokenBase[p.tokenIn],
            Math.Rounding.Down
        );
        p.amountInOut = amountInOut;

        // We first transfer the entire balance to the contract and then reimburse the surplus at the end
        p.tokenIn.safeTransferFrom(msg.sender, address(this), amount);

        uint256 amountPaidIn = _fillOrder(marketId, market, marketMode, amount, p);

        if (p.amountInOut != 0) {
            // In this case, as there isn't any open order left, reset the market
            market.status.inversionTimestamp = 0;
            market.status.firstIndex = 2;
            market.status.lastIndex = 2;
            // Reimburse the surplus
            p.tokenIn.safeTransfer(msg.sender, amount - amountPaidIn);

            // Update to account for the unfilled part
            amountInOut = amountInOut - p.amountInOut;
            p.tokenOut.safeTransfer(onBehalfOf, amountInOut);
            return (amountPaidIn, amountInOut);
        }

        p.tokenOut.safeTransfer(onBehalfOf, amountInOut);
        return (amount, amountInOut);
    }

    /// @notice Transfers an order from a given market to another address
    /// @param marketId Market on which the order needs to be transferred
    /// @param to Address to which the order should be transferred
    /// @dev The privileged address of a market cannot transfer its orders, and orders
    /// cannot be transferred to the privileged address
    /// @dev The function provides no guarantee that the transferred order is
    /// actually valid and used in the ongoing auction
    function transfer(bytes32 marketId, address to) external {
        uint48 orderIndex = _readUserOrderIndex(marketId, msg.sender);
        _transfer(marketId, orderIndex, msg.sender, to, _getId(marketId, orderIndex));
    }

    /// @notice Removes an order from `msg.sender` in a market with `marketId` and sends the corresponding
    /// funds to the `to` address
    /// @dev This function reverts if it is called too soon after the order is created
    function remove(bytes32 marketId, address to) external nonReentrant {
        uint48 orderIndex = _readUserOrderIndex(marketId, msg.sender);
        Market storage market = markets[marketId];
        _remove(marketId, market, to, orderIndex);
    }

    /// @notice Reduces the size of an order of `msg.sender` on `marketId` by `amount` and sends
    /// the associated funds to the `to` address
    /// @dev This function reverts if it makes the size of the order too small or if it flips the sign of the order
    /// amount, hence making the order shift from a buy order to a sell order or conversely
    function reduce(
        bytes32 marketId,
        address to,
        uint256 amount
    ) external nonReentrant {
        uint48 orderIndex = _readUserOrderIndex(marketId, msg.sender);
        Market storage market = markets[marketId];

        bool buyOrSell = _marketMode(marketId, market);
        Order storage order = orders[marketId][orderIndex];
        int256 orderAmount = order.amount - (buyOrSell ? int256(amount) : -int256(amount));
        (int256 minBuyOrder, int256 minSellOrder) = (msg.sender != market.status.privilegedAddress)
            ? (market.params.minBuyOrder, market.params.minSellOrder)
            : (int256(0), int256(0));

        if (((buyOrSell && (orderAmount < minBuyOrder)) || (!buyOrSell && (orderAmount > minSellOrder))))
            revert TooSmallOrder();
        else if (msg.sender == market.status.privilegedAddress && orderAmount == 0) {
            _remove(marketId, market, to, orderIndex);
        } else {
            order.amount = orderAmount;
            if (buyOrSell) market.quoteToken.safeTransfer(to, amount);
            else market.baseToken.safeTransfer(to, amount);

            emit OrderUpdated(marketId, orderIndex, orderAmount);
        }
    }

    // ============================= MARKET MANAGEMENT =============================

    /// @notice Creates a new market in the contract with parameters `params`
    /// @param quoteToken Quote token of the market
    /// @param baseToken Base token of the market
    /// @param params Parameters of the market: all these parameters are immutable
    /// @return marketId Id of the created market
    /// @dev All Ids are uniquely generated from the `msg.sender` address, the addresses of the quote
    /// and base token as well as from a nonce.
    /// @dev This contract works for tokens with immutable decimals, and if decimals are changed,
    /// then the contract will always keep working with the old decimal version
    function createMarket(
        address quoteToken,
        address baseToken,
        address privilegedAddress,
        MarketParams memory params
    ) external returns (bytes32 marketId) {
        if (
            quoteToken == address(0) ||
            baseToken == address(0) ||
            quoteToken == baseToken ||
            params.minBuyOrder <= 0 ||
            params.minSellOrder >= 0 ||
            params.maxDiscount >= _BASE_PARAMS
        ) revert InvalidParameters();
        uint256 senderNonce = nonces[msg.sender];

        // The market id is computed using the 208 first bits of a keccak256.
        // This enables the conversion `(marketId, orderIndex) <-> uint256` which is useful to get ERC721 ids for
        // each order. The risk of collision is minimal here
        marketId = bytes26(
            keccak256(abi.encodePacked(address(quoteToken), address(baseToken), msg.sender, senderNonce))
        );

        nonces[msg.sender] += 1;
        Market storage market = markets[marketId];
        market.quoteToken = IERC20(quoteToken);
        market.baseToken = IERC20(baseToken);
        market.params = params;
        market.status.privilegedAddress = privilegedAddress;
        market.status.firstIndex = 2;
        market.status.lastIndex = 2;

        if (tokenBase[IERC20(quoteToken)] == 0)
            tokenBase[IERC20(quoteToken)] = 10**(IERC20Metadata(quoteToken).decimals());
        if (tokenBase[IERC20(baseToken)] == 0)
            tokenBase[IERC20(baseToken)] = 10**(IERC20Metadata(baseToken).decimals());
        emit MarketCreated(quoteToken, baseToken, msg.sender, senderNonce, marketId);
    }

    /// @notice Resets the market price of the market `marketId` when either:
    /// 1: The current oracle value is too high with respect to the contract's market price
    /// and there are buy orders pending
    /// 2: The current oracle value is too small with respect to the contract's market price
    /// and there are sell orders pending
    function resetMarketPrice(bytes32 marketId) external returns (uint256 currentMarketPrice) {
        Market storage market = markets[marketId];
        bool marketMode = _marketMode(marketId, market);
        currentMarketPrice = _computeMarketPrice(market, marketMode);
        uint256 oracleValue = market.params.oracle.latestAnswer();
        if ((marketMode && oracleValue > currentMarketPrice) || (!marketMode && oracleValue < currentMarketPrice)) {
            _updateOracleValue(marketId, market, oracleValue);
            currentMarketPrice = oracleValue;
        }
    }

    /// @notice Allows an address with a privileged role on a market to transfer it to another `to` address
    /// @dev The privileged address and the destination cannot have open orders
    function transferMarketPrivilege(bytes32 marketId, address to) external {
        Market storage market = markets[marketId];
        address privilegedAddress = market.status.privilegedAddress;
        if (
            privilegedAddress != msg.sender ||
            orderIndexes[marketId][privilegedAddress] > 1 ||
            orderIndexes[marketId][to] > 1
        ) revert NotAllowed();
        market.status.privilegedAddress = to;
        emit PrivilegeTransferred(marketId, to);
    }

    // ============================== ERC721 FUNCTIONS =============================

    /// @notice Approves `spender` to use `id` following the ERC721 standard
    function approve(address spender, uint256 id) external {
        (bytes32 marketId, uint48 orderIndex) = _getData(id);
        address owner = orders[marketId][orderIndex].owner;

        if ((msg.sender != owner && !isApprovedForAll[owner][msg.sender]) || spender == owner) revert NotAllowed();
        _approve(owner, spender, id);
    }

    /// @notice Approves `operator` for all orders owned by `msg.sender`
    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice Transfers the order with `id` belonging to `from` to the `to` address
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public {
        (bytes32 marketId, uint48 orderIndex) = _getData(id);
        address owner = orders[marketId][orderIndex].owner;

        if (
            from != owner ||
            // order needs to be an open order
            orderIndexes[marketId][from] <= 1 ||
            (msg.sender != from && !isApprovedForAll[from][msg.sender] && msg.sender != getApproved[id])
        ) revert NotAllowed();

        _transfer(marketId, orderIndex, from, to, id);
    }

    /// @notice Same as above except that it reverts if the `to` address cannot handle NFTs
    /// @dev By default, it is not checked in the contract whether the owner of an order if it's a contract is able to
    /// interact with it. This `safeTransferFrom` function is the only place where such check is made
    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public {
        transferFrom(from, to, id);
        if (to.code.length != 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, id, "") returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) revert UnsafeRecipient();
            } catch {
                revert UnsafeRecipient();
            }
        }
    }

    /// @notice Specific `safeTransferFrom` implementation to comply with the ERC721 interface
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata
    ) external {
        safeTransferFrom(from, to, id);
    }
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "../interfaces/IOracle.sol";

import "./MarketStruct.sol";

/// @title MarketplaceHelpers
/// @author Angle Labs, Inc.
/// @notice A permissionless contract for peer-to-peer token exchanges using gradual Dutch auctions
/// @dev This file contains the variables and helper functions used to manage the markets
/// of the Marketplace contract
contract MarketplaceHelpers {
    using SafeERC20 for IERC20;
    using Math for uint256;

    // ================================= CONSTANTS =================================

    uint256 internal constant _BASE_PARAMS = 10**9;
    uint256 internal constant _BASE_ORACLE = 10**18;

    // ================================== MAPPINGS =================================

    /// @notice Maps a `marketId` to its associated parameters and data
    mapping(bytes32 => Market) public markets;

    /// @notice Maps a `marketId` to a mapping `orderIndex` => `order`
    /// @dev It corresponds to a double linked list
    mapping(bytes32 => mapping(uint48 => Order)) public orders;

    /// @notice Maps (`marketId`, `address`) to the index of the user's open order
    /// @dev If the `orderIndexes` of a user for a (`marketId`, `address`) pair is 0 or 1, then
    /// this means that the address has no open order for this market
    mapping(bytes32 => mapping(address => uint48)) public orderIndexes;

    /// @notice Nonces for the different market creators: this is way to make sure that a market cannot be
    /// created twice
    mapping(address => uint256) public nonces;

    /// @notice Maps a token to `10**(token decimals)`: this is a way to avoid calling token contracts
    /// everytime the `Marketplace` interacts with a token
    mapping(IERC20 => uint256) public tokenBase;

    // ================================ ERC721 LOGIC ===============================

    /// @notice Maps an `id` to the potentially approved operator for it
    mapping(uint256 => address) public getApproved;

    /// @notice Checks whether an address is approved by another address for all its orders on the contract
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    // =================================== ERRORS ==================================

    error InvalidOracle();
    error InvalidParameters();
    error MarketPriceNotInRange();
    error NoOpenOrder();
    error NotAllowed();
    error TooSmallOrder();
    error UnsafeRecipient();

    // =================================== EVENTS ==================================

    event MarketCreated(
        address indexed quoteToken,
        address indexed baseToken,
        address indexed sender,
        uint256 senderNonce,
        bytes32 marketId
    );
    event OracleValueUpdated(bytes32 marketId, uint256 oracleValue);
    event OrderAdded(bytes32 marketId, uint48 orderIndex, address indexed owner, int256 amount);
    event OrderRemoved(bytes32 marketId, uint48 orderIndex);
    event OrderUpdated(bytes32 marketId, uint48 orderIndex, int256 newOrderAmount);
    event OrderFilled(
        bytes32 marketId,
        uint48 orderIndex,
        int256 newOrderAmount,
        uint256 tokensReceived,
        address indexed filler
    );
    event PrivilegeTransferred(bytes32 marketId, address indexed privilegedAddress);
    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // ============================= UTILITY FUNCTIONS =============================

    /// @notice Gets the ERC721 id from `marketId` and `orderIndex`
    /// @dev The ERC721 id is such that: `id = marketId << 48 + orderIndex`
    function _getId(bytes32 marketId, uint48 orderIndex) internal pure returns (uint256) {
        uint256 id;
        // To cast a bytes26 as a uint208, we start by the left byte in position 200 and iterate
        for (uint256 i; i < 26; ) {
            id = id + uint256(uint8(marketId[i])) * (2**(208 - 8 * (i + 1)));
            unchecked {
                ++i;
            }
        }
        return uint256(id << 48) + orderIndex;
    }

    /// @notice Gets `marketId` and `orderIndex` from the ERC721 id
    function _getData(uint256 id) internal pure returns (bytes32 marketId, uint48 orderIndex) {
        orderIndex = uint48(id % 2**48);
        marketId = bytes32(abi.encodePacked(id >> 48)) << 48;
    }

    /// @notice Gets the index of the order following `orderIndex`
    function _readNextOrder(uint48 storedNext, uint48 orderIndex) internal pure returns (uint48) {
        if (storedNext <= 1) {
            unchecked {
                return orderIndex + 1;
            }
        } else {
            return storedNext;
        }
    }

    /// @notice Gets the index of the order before `orderIndex`
    function _readPreviousOrder(uint48 storedPrevious, uint48 orderIndex) internal pure returns (uint48) {
        if (storedPrevious <= 1) {
            // `orderIndex` should always be > 1
            unchecked {
                return orderIndex - 1;
            }
        } else {
            return storedPrevious;
        }
    }

    /// @notice Casts `amount` to uint256
    function _abs(int256 amount) internal pure returns (uint256 castedAmount) {
        castedAmount = uint256(amount > 0 ? amount : -amount);
    }

    /// @notice Casts a uint256 to a string
    /// @dev Forked from: https://stackoverflow.com/questions/47129173/how-to-convert-uint-to-string-in-solidity
    function _uintToString(uint256 i) internal pure returns (string memory) {
        if (i == 0) return "0";
        uint256 j = i;
        uint256 length;
        while (j != 0) {
            ++length;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        j = i;
        while (j != 0) {
            bstr[--length] = bytes1(uint8(48 + (j % 10)));
            j /= 10;
        }
        return string(bstr);
    }

    // =============================== MARKET HELPERS ==============================

    /// @notice Gets the index of `user` current order if there is one, otherwise reverts
    /// @dev It is critical that this function returns 0 or 1 if the user has no active order
    function _readUserOrderIndex(bytes32 marketId, address user) internal view returns (uint48 orderIndex) {
        orderIndex = orderIndexes[marketId][user];
        if (orderIndex <= 1) revert NoOpenOrder();
    }

    /// @notice Returns true if the market is currently buying and false if the market is selling (or not buying)
    function _marketMode(bytes32 marketId, Market storage market) internal view returns (bool buyOrSell) {
        buyOrSell = orders[marketId][market.status.firstIndex].amount > 0;
    }

    /// @notice Internal version of the `estimateBaseToQuote` function
    function _estimateBaseToQuote(
        Market storage market,
        uint256 amount,
        bool marketMode
    ) internal view returns (uint256) {
        uint256 marketPrice = _computeMarketPrice(market, marketMode);
        if (marketPrice == 0) return 0;
        return
            amount.mulDiv(
                tokenBase[market.quoteToken] * marketPrice,
                _BASE_ORACLE * tokenBase[market.baseToken],
                Math.Rounding.Down
            );
    }

    /// @notice Internal version of the `estimateQuoteToBase` function
    function _estimateQuoteToBase(
        Market storage market,
        uint256 amount,
        bool marketMode
    ) internal view returns (uint256) {
        uint256 marketPrice = _computeMarketPrice(market, marketMode);
        if (marketPrice == 0) return 0;
        else
            return
                amount.mulDiv(
                    tokenBase[market.baseToken] * _BASE_ORACLE,
                    marketPrice * tokenBase[market.quoteToken],
                    Math.Rounding.Down
                );
    }

    /// @notice Gets the sum of all open orders on a market
    function _getOrdersAmount(
        bytes32 marketId,
        Market storage market,
        uint256 lastIndex
    ) internal view returns (int256 amount) {
        uint48 index = market.status.firstIndex;
        while (index < lastIndex) {
            Order storage order = orders[marketId][index];
            unchecked {
                amount += order.amount;
            }
            index = _readNextOrder(order.next, index);
        }
    }

    /// @notice Returns the sum of the pending orders placed before the `lastIndex` in the market
    /// and an estimate of the value of the other token that would be needed to fill these orders
    /// @param marketId Id of the market to query
    /// @param market Market to query
    /// @param lastIndex Last index order to take into account
    /// @param buy Whether we are only interested on one side of the order book, if `==-1` both modes are accepted
    /// @return amountBrought Sum of the amounts in the orders placed before the order of `owner`
    /// @return amountToBring Estimate of the value that would be needed to fill all the orders before the
    /// `owner` order
    /// @dev This will return a null triplet if the market is on the other mode than what is specified
    function _getOrder(
        bytes32 marketId,
        Market storage market,
        uint64 lastIndex,
        int8 buy
    )
        internal
        view
        returns (
            uint256 amountBrought,
            uint256 amountToBring,
            bool marketMode
        )
    {
        marketMode = _marketMode(marketId, market);
        if (marketMode && buy != 0) {
            amountBrought = uint256(_getOrdersAmount(marketId, market, lastIndex));
            amountToBring = _estimateQuoteToBase(market, amountBrought, marketMode);
        } else if (!marketMode && 1 - buy != 0) {
            amountBrought = uint256(-_getOrdersAmount(marketId, market, lastIndex));
            amountToBring = _estimateBaseToQuote(market, amountBrought, marketMode);
        }
    }

    /// @notice Computes the current price in a market `market` based on the oracle value stored, the
    /// market's last inversion timestamp and the discount/premium increase rates
    function _computeMarketPrice(Market storage market, bool marketMode) internal view returns (uint256 marketPrice) {
        uint256 elapsed = block.timestamp - market.status.inversionTimestamp;
        marketPrice = market.status.oracleValue;
        if (marketMode) {
            uint256 premium = elapsed * market.params.premiumIncreaseRate;
            premium = premium > market.params.maxPremium ? market.params.maxPremium : premium;
            marketPrice = (marketPrice * (_BASE_PARAMS + premium)) / _BASE_PARAMS;
        } else {
            uint256 discount = elapsed * market.params.discountIncreaseRate;
            discount = discount > market.params.maxDiscount ? market.params.maxDiscount : discount;
            marketPrice = (marketPrice * (_BASE_PARAMS - discount)) / _BASE_PARAMS;
        }
    }

    // ============================== ORDER MANAGEMENT =============================

    /// @notice Transfers an order from a given market to another address
    /// @param marketId Market on which the order needs to be transferred
    /// @param orderIndex Index of the order in `orders[marketId]`
    /// @param from Owner or approved operator for the order
    /// @param to Address to which the order should be transferred
    /// @param id ID of the NFT corresponding to the order transferred (for the event)
    /// @dev The privileged address of a market cannot transfer its orders, and orders
    /// cannot be transferred to the privileged address
    /// @dev Only open orders can be transferred, and when entering this function, it has already been checked
    /// prior whether the `orderIndex` was an open order or not
    function _transfer(
        bytes32 marketId,
        uint48 orderIndex,
        address from,
        address to,
        uint256 id
    ) internal {
        Market storage market = markets[marketId];
        address privilegedAddress = market.status.privilegedAddress;
        if (orderIndexes[marketId][to] > 1 || from == privilegedAddress || to == privilegedAddress) revert NotAllowed();
        // Clear approval from the previous owner
        _approve(from, address(0), id);

        orderIndexes[marketId][from] = 1;
        orderIndexes[marketId][to] = orderIndex;
        orders[marketId][orderIndex].owner = to;

        emit Transfer(from, to, id);
    }

    /// @notice Sets an approval for `owner` to `spender` for order `id`
    function _approve(
        address owner,
        address spender,
        uint256 id
    ) internal {
        getApproved[id] = spender;
        emit Approval(owner, spender, id);
    }

    /// @notice Adds an order in the market `market`
    function _addOrder(
        bytes32 marketId,
        Market storage market,
        uint48 orderIndex,
        int256 amount,
        address owner,
        bool orderSizeCheck
    ) internal {
        if (
            orderSizeCheck &&
            owner != market.status.privilegedAddress &&
            ((amount > 0 && amount < market.params.minBuyOrder) || (amount < 0 && amount > market.params.minSellOrder))
        ) revert TooSmallOrder();
        // Orders cannot be null
        else if (amount == 0) revert NotAllowed();

        orders[marketId][orderIndex] = Order(1, 1, owner, amount);
        orderIndexes[marketId][owner] = orderIndex;
        emit OrderAdded(marketId, orderIndex, owner, amount);
    }

    /// @notice Fills a list of pending orders
    /// @param marketId Identifier of the market
    /// @param market Reference to the `Market` struct
    /// @param marketMode Whether the market is currently in buy or sell mode
    /// @param amountIn Amount of `tokenIn` sent to pay and that will be used to fill orders
    /// @param p Context data such as `tokenIn` and `tokenOut`
    /// @return amountPaidIn Amount of `amountIn` actually used to fill orders
    /// @dev When an order is completely filled, there's no need to update the values associated to it
    /// in the `orders` array: just the `firstIndex` or the `lastIndex` of the market should be updated
    function _fillOrder(
        bytes32 marketId,
        Market storage market,
        bool marketMode,
        uint256 amountIn,
        OrderFillingParameters memory p
    ) internal returns (uint256 amountPaidIn) {
        // Used to track the value in `inToken` of the orders that are filled
        uint256 orderAmountIn;
        uint48 index = market.status.firstIndex;
        while (index < market.status.lastIndex) {
            Order storage lastOrder = orders[marketId][index];

            // Casted current order amount in `tokenOut`
            uint256 orderAmountOut = _abs(lastOrder.amount);

            // If the current order is big enough to fill the order being placed
            if (orderAmountOut >= p.amountInOut) {
                int256 newOrderAmount;
                if (orderAmountOut == p.amountInOut) {
                    // If the `orderAmount` matches exactly the pending order
                    if (index + 1 == market.status.lastIndex) {
                        // Either it's the last order in the market and market is reset
                        market.status.inversionTimestamp = 0;
                        market.status.firstIndex = 2;
                        market.status.lastIndex = 2;
                    } else {
                        // Or we just go to the next order
                        market.status.firstIndex = _readNextOrder(lastOrder.next, index);
                    }
                    orderIndexes[marketId][lastOrder.owner] = 1;
                } else {
                    if (marketMode) {
                        newOrderAmount = lastOrder.amount - int256(p.amountInOut);
                    } else {
                        newOrderAmount = lastOrder.amount + int256(p.amountInOut);
                    }
                    market.status.firstIndex = index;
                }

                orderAmountIn = p.amountInOut.mulDiv(
                    tokenBase[p.tokenIn] * p.denominator,
                    p.numerator * tokenBase[p.tokenOut],
                    Math.Rounding.Down
                );

                p.amountInOut = 0;
                lastOrder.amount = newOrderAmount;
                p.tokenIn.safeTransfer(lastOrder.owner, orderAmountIn);
                emit OrderFilled(marketId, index, newOrderAmount, orderAmountIn, msg.sender);
                return amountIn;
            }
            orderAmountIn = orderAmountOut.mulDiv(
                tokenBase[p.tokenIn] * p.denominator,
                p.numerator * tokenBase[p.tokenOut],
                Math.Rounding.Down
            );

            unchecked {
                p.amountInOut -= orderAmountOut;
                amountPaidIn += orderAmountIn;
            }

            orderIndexes[marketId][lastOrder.owner] = 1;

            p.tokenIn.safeTransfer(lastOrder.owner, orderAmountIn);
            emit OrderFilled(marketId, index, 0, orderAmountIn, msg.sender);

            index = _readNextOrder(lastOrder.next, index);
        }
        return amountPaidIn;
    }

    /// @notice Internal version of the `remove` function
    function _remove(
        bytes32 marketId,
        Market storage market,
        address to,
        uint48 orderIndex
    ) internal {
        uint48 firstIndex = market.status.firstIndex;
        uint48 lastIndex = market.status.lastIndex;
        int256 amountRemoved = orders[marketId][orderIndex].amount;

        if (lastIndex - firstIndex == 1) {
            // If removing an order leaves the market empty, we reset the market
            market.status.inversionTimestamp = 0;
            market.status.firstIndex = 2;
            market.status.lastIndex = 2;
        } else if (msg.sender == market.status.privilegedAddress) {
            market.status.firstIndex = _readNextOrder(orders[marketId][firstIndex].next, orderIndex);
        } else {
            mapping(uint48 => Order) storage marketOrders = orders[marketId];

            // There are at least 2 orders in the list
            if (orderIndex == firstIndex) {
                market.status.firstIndex = _readNextOrder(marketOrders[orderIndex].next, orderIndex);
            } else if (orderIndex + 1 == lastIndex) {
                market.status.lastIndex = _readPreviousOrder(marketOrders[orderIndex].previous, orderIndex) + 1;
            } else {
                uint48 previous = _readPreviousOrder(marketOrders[orderIndex].previous, orderIndex);
                uint48 next = _readNextOrder(marketOrders[orderIndex].next, orderIndex);
                marketOrders[previous].next = next;
                marketOrders[next].previous = previous;
            }
        }

        orderIndexes[marketId][msg.sender] = 1;
        if (amountRemoved > 0) market.quoteToken.safeTransfer(to, uint256(amountRemoved));
        else market.baseToken.safeTransfer(to, uint256(-amountRemoved));
        emit OrderRemoved(marketId, orderIndex);
    }

    /// @notice Initializes a market that has no order with a first order
    /// @dev The size of the first order in a market is not checked as a user could create an order and
    /// fill it to bypass the requirement atomically
    /// @dev It is however still checked whether the `amount` of the new order is not null
    function _initiateMarket(
        bytes32 marketId,
        Market storage market,
        int256 amount,
        address owner
    ) internal returns (uint48 orderIndex) {
        if (owner == market.status.privilegedAddress) orderIndex = 2;
        else orderIndex = 3;
        market.status.firstIndex = orderIndex;
        unchecked {
            market.status.lastIndex = orderIndex + 1;
        }
        _updateOracleValue(marketId, market, 0);
        _addOrder(marketId, market, orderIndex, amount, owner, false);
    }

    /// @notice Updates the oracle value of the market `market`
    function _updateOracleValue(
        bytes32 marketId,
        Market storage market,
        uint256 oracleValue
    ) internal {
        if (oracleValue == 0) oracleValue = market.params.oracle.latestAnswer();
        if (oracleValue == 0) revert InvalidOracle();
        market.status.oracleValue = oracleValue;
        market.status.inversionTimestamp = uint64(block.timestamp);
        emit OracleValueUpdated(marketId, oracleValue);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

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
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

/// @title IOracle
/// @author Angle Labs, Inc.
interface IOracle {
    /// @notice Returns the value of a base token in quote token in base 18
    function latestAnswer() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IOracle.sol";

/// @notice Struct to track the status of a caller filling some pending orders
/// in the marketplace contract
struct OrderFillingParameters {
    // Address of the ERC20 token sent by the function caller
    IERC20 tokenIn;
    // Address of the ERC20 token received by the function caller
    IERC20 tokenOut;
    // Numerator when converting from `tokenIn` to `tokenOut`
    uint256 numerator;
    // Denominator when converting from `tokenIn` to `tokenOut`
    uint256 denominator;
    // Amount sent converted in `tokenOut`
    uint256 amountInOut;
}

/// @notice Order data
/// @dev Orders for a market are stored in a double-linked list, this struct
/// contains on top of the specific order information data about the place of the order in the list
struct Order {
    // Previous element index in the double-linked list for orders of the market
    // If this amount is 1, then the previous order is the `orderIndex` of the corresponding order minus 1
    uint48 previous;
    // Next element index in the double-linked list for orders of the market
    // If this amount is 1, then the next order is the `orderIndex` of the corresponding order plus 1
    uint48 next;
    // Owner of the order which can amend it or remove it
    address owner;
    // Amount of tokens brought for the order
    // > 0 means it is a buy order
    // < 0 means it is a sell order
    int256 amount;
}

/// @notice Immutable parameters of a given market
struct MarketParams {
    // Oracle contract used to price the base tokens in value of quote tokens: if 1 ETH = 2000 EUR, then
    // oracle = 2000 * BASE_ORACLE
    // This should be an external trusted contract and if this oracle came to fail, then the whole
    // associated market could fail, as such it's important to place the right safeguards in the
    // corresponding oracle contract when deploying a market
    IOracle oracle;
    // Per second increase of the discount if there are more sell orders than buy orders
    uint64 discountIncreaseRate;
    // Per second increase of the premium if there are more sell orders than buy orders
    uint64 premiumIncreaseRate;
    // Maximum discount that can be given on the market price when there are more sell orders than buy orders
    uint64 maxDiscount;
    // Maximum premium that can be given on the market price when there are more sell orders than buy orders
    uint64 maxPremium;
    // Minimum size of a buy / sell order: should be in decimals of the quote token.
    // This parameter and the `minSellOrder` parameter are intended to be anti-spam filters as they make
    // spamming capital-intensive.
    // The minimum size requirements do not apply in the following cases:
    //      - the order is the first created in the market
    //      - the order is partially filled
    //      - the order is created by the privileged address
    // There can thus be up to 2 smaller orders than the requirements per market
    int256 minBuyOrder;
    // Minimum size of a sell order: should be in decimals of the base token and should be a negative amount
    int256 minSellOrder;
}

/// @notice Current market status indicators
struct MarketStatus {
    // Index in the `orderIndexes` mapping of the first valid order
    uint48 firstIndex;
    // Orders with an index in the `orderIndexes` mapping greater or equal than this amount are not
    // valid orders
    uint48 lastIndex;
    // Privileged address of the market able to be matched first and to bypass minimum order requirements
    address privilegedAddress;
    // Current oracle value: this value is then going to be potentially discounted or increased with a premium
    uint256 oracleValue;
    // Timestamp at which the market switched from buy to sell mode (or conversely)
    // A non zero `inversionTimestamp` means there is an ongoing auction, hence some open orders
    uint64 inversionTimestamp;
}

/// @notice All the data about a market
struct Market {
    // In a ETH/agEUR pair, quote token is agEUR
    IERC20 quoteToken;
    // In a ETH/agEUR pair, base token is ETH
    IERC20 baseToken;
    // Market parameters
    MarketParams params;
    // Market status indicators
    MarketStatus status;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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