// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./IERC20.sol";
import "./Owner.sol";
import "./ReentrancyGuard.sol";

contract ICOContract is Owner, ReentrancyGuard {
    uint256 public mulDec_tokenForSale;
    address public tokenForSale;
    address public exchangeToken;
    uint256 public salePrice; // set salePrice with 6 decimals (USDT TOKEN)
    uint256 public totalOrders;
    bool public lockNewOrders;

    struct Order {
        address buyer;
        uint256 amount;
        uint256 paidAmount;
        bool closed; // true=tokens sent to buyer; false=tokens not yet sent to the buyer 
    }

    mapping(uint256 => Order) public orders;

    event SetTokensContract(
        address tokenForSale,
        address exchangeToken
    );

    event SetSalePrice(
        uint256 salePrice
    );

    event Buy(
        uint256 orderId,
        address buyer,
        uint256 amount,
        uint256 paidAmount
    );

    event ExecuteOrder(
        uint256 orderId,
        address buyer,
        uint256 amount,
        uint256 paidAmount
    );

    event SetMulDec_tokenForSale(
        uint256 muldec
    );

    event SetLockNewOrders(
        bool newValue
    );

    constructor(address _tokenForSaleAddress, address _exchangeTokenAddress, uint256 _salePrice) {
        setTokenContract(_tokenForSaleAddress, _exchangeTokenAddress);
        setSalePrice(_salePrice);
        uint256 muldec = 10**18;
        set_mulDec_tokenForSale(muldec);
    }

    function setTokenContract(address _tokenForSaleAddress, address _exchangeTokenAddress) public isOwner {
        tokenForSale = _tokenForSaleAddress;
        exchangeToken = _exchangeTokenAddress;
        emit SetTokensContract(_tokenForSaleAddress, _exchangeTokenAddress);
    }

    function setSalePrice(uint256 _salePrice) public isOwner {
        salePrice = _salePrice;
        emit SetSalePrice(_salePrice);
    }

    function set_mulDec_tokenForSale(uint256 _muldec) public isOwner {
        mulDec_tokenForSale = _muldec;
        emit SetMulDec_tokenForSale(_muldec);
    }

    function setLockNewOrders(bool _newValue) external isOwner{
        lockNewOrders = _newValue;
        emit SetLockNewOrders(_newValue);
    }

    function buy(uint256 _amount) external nonReentrant{
        require(!lockNewOrders, "cannot currently create new buy orders");
        require(_amount>=1, "amount to buy must be greater or equal than 1");
        uint256 amountToPay = _amount*salePrice;
        IERC20(exchangeToken).transferFrom(msg.sender, getOwner(), amountToPay);
        uint256 newOrderId = totalOrders+1;
        orders[newOrderId] = Order(msg.sender, _amount, amountToPay, false);
        totalOrders = totalOrders+1;
        emit Buy(newOrderId, msg.sender, _amount, amountToPay);
    }

    function executeBuyOrders(uint256 _fromOrder, uint256 _toOrder) external isOwner{
        require(_toOrder<=totalOrders, "toOrder must be less than or equal to totalOrders");
        require(_fromOrder<=_toOrder, "fromOrder must be less than toOrder");
        for (uint256 i=_fromOrder; i<(_toOrder+1); i++) {
            if(orders[i].buyer!=address(0) && !orders[i].closed){
                orders[i].closed = true;
                IERC20(tokenForSale).transferFrom(getOwner(), orders[i].buyer, orders[i].amount*mulDec_tokenForSale);
                emit ExecuteOrder(i, orders[i].buyer, orders[i].amount, orders[i].paidAmount);
            }
        }
    }

}