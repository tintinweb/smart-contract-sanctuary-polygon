/**
 *Submitted for verification at polygonscan.com on 2023-02-09
*/

/**
 *Submitted for verification at hecoinfo.com on 2022-03-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

struct Dish {
    uint256 price;
    uint256 number;
}

enum OrderType { Buy, Sell }
enum OrderStatus { None, Waiting, Finished, Cancelled }

struct Order {
    uint256 orderId;
    uint256 price;
    uint256 tokenTotal;
    uint256 tokenSurplus;
    uint256 tokenFee;
    uint256 usdtSurplus;
    uint256 usdtFee;
    uint256 createnTime;
    uint256 endTime;
    OrderType orderType;
    OrderStatus status;
    address sender;
}

struct Match {
    uint256 matchId;
    uint256 buyOrderId;
    uint256 sellOrderId;
    uint256 price;
    uint256 tokenDeal;
    uint256 usdtDeal;
    uint256 tokenFee;
    uint256 usdtFee;
    uint256 time;
}

interface TDEX {

    function getOrder(address _tokenContract, uint256 _orderId) external view returns (
        uint256 price,
        uint256 tokenTotal,
        uint256 tokenSurplus,
        uint256 tokenFee,
        uint256 usdtSurplus,
        uint256 usdtFee,
        uint256 createnTime,
        uint256 endTime,
        uint8 orderType,
        uint8 status,
        address sender
    );

    function getMatch(address _tokenContract, uint256 _matchId) external view returns (
        uint256 matchId,
        uint256 buyOrderId,
        uint256 sellOrderId,
        uint256 price,
        uint256 tokenDeal,
        uint256 usdtDeal,
        uint256 tokenFee,
        uint256 usdtFee,
        uint256 time
    );

    function getBuyOrderPriceListLength(address _tokenContract) external view returns (uint length);

    function getBuyOrderPriceList(address _tokenContract, uint256 start, uint256 end) external view returns (uint256[] memory list);

    function getBuyOrderPriceTokenNumber(address _tokenContract, uint256 _price) external view returns (uint256 number);

    function getBuyOrderPriceListPublished(address _tokenContract, uint count) external view returns (uint256[] memory list);

    function getBuyOrderPublished(address _tokenContract, uint count) external view returns (Dish[] memory list);

    function getBuyOrderPriceOrderIdList(address _tokenContract, uint256 _price) external view returns (uint256[] memory list);

    function getSellOrderPriceListLength(address _tokenContract) external view returns (uint length);

    function getSellOrderPriceList(address _tokenContract, uint256 start, uint256 end) external view returns (uint256[] memory list);

    function getSellOrderPriceTokenNumber(address _tokenContract, uint256 _price) external view returns (uint256 number);

    function getSellOrderPriceListPublished(address _tokenContract, uint count) external view returns (uint256[] memory list);

    function getSellOrderPublished(address _tokenContract, uint count) external view returns (Dish[] memory list);

    function getSellOrderPriceOrderIdList(address _tokenContract, uint256 _price) external view returns (uint256[] memory list);

    function getOrderMatching(address _tokenContract, uint256 _orderId) external view returns (uint256[] memory matchingList);

    function getOrderUnmatchedListLength(address _tokenContract, address _sender) external view returns (uint length);

    function getOrderFinishedListLength(address _tokenContract, address _sender) external view returns (uint length);

    function getOrderUnmatchedList(address _tokenContract, address _sender, uint256 start, uint256 end) external view returns (uint256[] memory list);

    function getOrderFinishedList(address _tokenContract, address _sender, uint256 start, uint256 end) external view returns (uint256[] memory list);
}

contract Helper {

    address private _owner;

    constructor () {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function getOrder(address _dex, address _tokenContract, uint256 _orderId) internal view returns (Order memory)
    {
        (
                uint256 price,
                uint256 tokenTotal,
                uint256 tokenSurplus,
                uint256 tokenFee,
                uint256 usdtSurplus,
                uint256 usdtFee,
                uint256 createnTime,
                uint256 endTime,
                uint8 orderType,
                uint8 status,
                address sender
            ) = TDEX(_dex).getOrder(_tokenContract, _orderId);
            Order memory order;
            order.orderId = _orderId;
            order.price = price;
            order.tokenTotal = tokenTotal;
            order.tokenSurplus = tokenSurplus;
            order.tokenFee = tokenFee;
            order.usdtSurplus = usdtSurplus;
            order.usdtFee = usdtFee;
            order.createnTime = createnTime;
            order.endTime = endTime;
            order.orderType = OrderType(orderType);
            order.status = OrderStatus(status);
            order.sender = sender;
            return order;
    }

    function getOrderUnmatchedList(address _dex, address _tokenContract, address _sender, uint256 start, uint256 end) external view returns (Order[] memory)
    {
        TDEX dex = TDEX(_dex);
        uint256[] memory orders = dex.getOrderUnmatchedList(_tokenContract, _sender, start, end);
        Order[] memory list = new Order[](orders.length);
        for (uint i=0; i<orders.length; i++)
        {
            list[i] = getOrder(_dex, _tokenContract, orders[i]);
        }
        return list;
    }

    function getOrderFinishedList(address _dex, address _tokenContract, address _sender, uint256 start, uint256 end) external view returns (Order[] memory)
    {
        TDEX dex = TDEX(_dex);
        uint256[] memory orders = dex.getOrderFinishedList(_tokenContract, _sender, start, end);
        Order[] memory list = new Order[](orders.length);
        for (uint i=0; i<orders.length; i++)
        {
            list[i] = getOrder(_dex, _tokenContract, orders[i]);
        }
        return list;
    }
}