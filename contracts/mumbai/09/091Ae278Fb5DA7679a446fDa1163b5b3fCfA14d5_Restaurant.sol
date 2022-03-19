/**
 *Submitted for verification at polygonscan.com on 2022-03-19
*/

pragma solidity ^0.8.4;
// dev : Solii.sol // 

contract Restaurant
{   

    address admin ;

    event SetMenu (uint indexed num, string food);
    event BuyFood (uint FoodNum, string food, address indexed costomer);

    mapping (uint => string) MENU;
    mapping (uint => string) public orders;
    mapping (uint => StatusOrder) public StatusOrders;
    mapping (uint => address) costomerOrder;

    enum StatusOrder {nothing, Pending , Complete, Canceling}

    StatusOrder OrderStatus;

    modifier OnlyAdmin()
    {
        require (msg.sender == admin);
        _;
    }

    modifier OnlyChefs()
    {
        for (uint i; i==Chefs.length;i++)
        require (msg.sender == Chefs[i]);
        _;
    }

    modifier OnlyCostomer (uint OrderNumber)
    {
        address Cost = costomerOrder[OrderNumber];
        require (msg.sender == Cost);
        _;
    }

    constructor () 
    {
        OrderStatus = StatusOrder.nothing;
        admin = msg.sender;
    }

    uint public orderNum;
    uint public LengthFoods;

    string [] Foods;
    address [] costomer_;
    address [] Chefs;

    function setMenu ( string memory food ) 
    public OnlyAdmin
    {
        require (LengthFoods == Foods.length, "@Dev : not match foods length and counts");

        LengthFoods ++;

        MENU [LengthFoods] = food;

        Foods.push (food);

        emit SetMenu (LengthFoods , food);
    }

    function menu (uint FoodNumber) public view returns(string memory)
    {
        require ( LengthFoods >= FoodNumber, "@Dev : please check the LengthFoods ( not match food length and food number)");

        return MENU [FoodNumber] ;
    }

    function myMenu (uint FoodNumber) public returns(uint orderNumber, StatusOrder statusOrder)
    {
        require ( LengthFoods >= FoodNumber, "@Dev : please check the LengthFoods ( not match food length and food number)");

        string memory food = MENU [FoodNumber];

        orderNum++;

        orders [orderNum] = food;

        costomer_.push(msg.sender);

        costomerOrder[orderNum] = msg.sender;

        emit BuyFood (orderNum, food, msg.sender);

        StatusOrders [orderNum] = StatusOrder.Pending;

        return (orderNum, OrderStatus );
    }

    function setChef (address Chef_) public OnlyAdmin
    {
        Chefs.push(Chef_);
    }

    function StatusComplete (uint orderNumber) public OnlyChefs OnlyAdmin
    {
        StatusOrders [orderNumber] = StatusOrder.Complete;
    }

    function Cancels (uint orderNumber) public OnlyCostomer(orderNumber)
    {
        StatusOrders [orderNumber] = StatusOrder.Canceling;
    }
}