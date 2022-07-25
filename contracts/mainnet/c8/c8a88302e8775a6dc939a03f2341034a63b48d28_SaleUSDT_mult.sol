// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./IBEP20.sol";
import "./Ownable.sol";

contract SaleUSDT_mult is Ownable {

    address public USDT; //address of the token which creates the price of the security token
    address public SECURITIES; //address of the security token

    uint256 public basePrice; // price of the secutity token in USD*10
    address public manager;
    bool public status; // isActive

    struct Order {
        uint256 securities;
        uint256 USDT;
        address token; // address of the token with which security was bought
        string orderId;
        address payer;
    }

    Order[] public orders;
    uint256 public ordersCount;

    event BuyTokensEvent(address buyer, uint256 amountSecurities, address swapToken);

    constructor(address _USDT, address _securities) {
        USDT = _USDT;
        SECURITIES = _securities;
        manager = _msgSender();
        ordersCount = 0;
        basePrice = 8;
        status = true;
    }

    modifier onlyManager() {
        require(_msgSender() == manager, "Wrong sender");
        _;
    }

    modifier onlyActive() {
        require(status == true, "Sale: not active");
        _;
    }

    function changeManager(address newManager) public onlyOwner {
        manager = newManager;
    }

    function changeStatus(bool _status) public onlyOwner {
        status = _status;
    }

    
    /// @notice price of the secutity token in USD*10    
    function setPrice(uint256 priceInUSDT) public onlyManager {
        basePrice = priceInUSDT;
    }

    /// @notice swap of the token to security. 
    /// Security has 0 decimals. Formula round amount of securities to get to a whole number
    /// @dev make swap, create and write the order of the operation, emit BuyTokensEvent
    /// @param amountUSDT has 18 decimals
    /// @param swapToken has to be equal to the USDT in price, in other way formula doesn't work
    /// @return true if the operation done successfully
    function buyToken(uint256 amountUSDT, address swapToken, string memory orderId) public onlyActive returns(bool) {
        uint256 amountSecurities = (amountUSDT / basePrice) / (10**(IBEP20(swapToken).decimals()));
        Order memory order;
        IBEP20(swapToken).transferFrom(_msgSender(), address(this), amountUSDT);
        require(IBEP20(SECURITIES).transfer(_msgSender(), amountSecurities), "transfer: SEC error");

        order.USDT = amountUSDT;
        order.securities = amountSecurities;
        order.token = swapToken;
        order.orderId = orderId;
        order.payer = _msgSender();
        orders.push(order);
        ordersCount += 1;

        emit BuyTokensEvent(_msgSender(), amountSecurities, swapToken);
        return true;
    }

    /// @notice Owner of the contract has an opportunity to send any tokens from the contract to his/her wallet    
    /// @param amount amount of the tokens to send (18 decimals)
    /// @param token address of the tokens to send
    /// @return true if the operation done successfully
    function sendBack(uint256 amount, address token) public onlyOwner returns(bool) {
        require(IBEP20(token).transfer(_msgSender(), amount), "Transfer: error");
        return true;
    }

    /// @notice function count and return the amount of security to be gotten for the proper amount of tokens 
    /// Security has 0 decimals. Formula round amount of securities to get to a whole number    
    /// @param amountUSDT amount of token you want to spend (18 decimals)
    /// @return token , securities -  tuple of uintegers - (amount of token to spend, amount of securities to get)    
    function buyTokenView(uint256 amountUSDT) public view returns(uint256 token, uint256 securities) {
        uint256 amountSecurities = (amountUSDT / basePrice) / (10**(IBEP20(USDT).decimals()));
        return (
        amountUSDT, amountSecurities
         );
    }

}