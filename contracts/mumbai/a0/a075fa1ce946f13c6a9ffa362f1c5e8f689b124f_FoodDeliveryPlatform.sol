/**
 *Submitted for verification at polygonscan.com on 2023-04-10
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// 1. Customer place order
// 2. Restaurant accept order
// 3. Delivery person accept order
// 4. Restaurant has the order ready to be delivered
// 5. Delivery person confirms the pickup of the order, fee given to restaurant
// 6. Delivery person indicates the delivery of the order
// 7. Customer confirms the delivery of the order, fee given to delivery person
// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract FoodDeliveryPlatform {
    address payable owner;
    constructor() {
        owner = payable(msg.sender);
    }
    struct Customer {
        string name;
        uint id;
        string addr;
        uint phone;
        address wallet;
        uint balance;
        bool hasRegistered;
    }

    struct Order {
        uint orderId;
        bool activeOrder;
        address restaurant;
        address customer;
        uint amount;
        bool acceptedRestaurant;
        bool readyForDeli;
        bool acceptedDelivery;
        bool pickedUpDelivery;
        bool completedDeli;
        address delivery_person;
        uint deli_fee;
    }

    struct Restaurant {
        string name;
        uint id;
        string addr;
        string cuisine;
        uint minPayment;
        address wallet;
        bool hasRegistered;
    }

    struct Delivery_Person{
        string name;
        uint id;
        uint phone;
        address wallet;
        bool hasRegistered;
        bool hasActiveOrder;
    }

    uint public orderCount;
// Registered customers, restaurants and delivery people
    mapping (uint => Order) public orders;
    mapping (address => Customer) public customers;
    mapping (address => Restaurant) public restaurants;
    mapping (address => Delivery_Person) public delivery_people;
// Register requests from customers, restaurants and delivery people
    Customer[] public request_customers;
    Restaurant[] public request_restaurants;
    Delivery_Person[] public request_delivery_people;


    event OrderPlaced(
        uint orderId, 
        address restaurant, 
        address customer, 
        uint amount);
    
    event OrderAccepted(
        uint orderId, 
        address restaurant, 
        address customer, 
        uint amount);

    event OrderAcceptedDelivery(
        uint orderId,
        address restaurant,
        address customer,
        address delivery,
        uint amount);
        
    event OrderReady(
        uint orderId, 
        address restaurant, 
        address customer, 
        uint amount);
    
    event OrderPickedup(
        uint orderId,
        address delivery_person,
        address customer,
        uint amount);

    event OrderCompleteDelivery(
        uint orderId,
        address restaurant,
        address customer,
        address delivery,
        uint amount);

    event OrderComplete(
        uint orderId,
        address restaurant,
        address customer,
        address delivery,
        uint amount);
    
// 1. Function for customer to place an order
    function placeOrder(address restaurantAddr) public payable {
        require(customers[msg.sender].hasRegistered == true, "You are not registered yet! Please register first.");
        require(restaurants[restaurantAddr].hasRegistered == true, "Invalid restaurant.");
        require(msg.value >= restaurants[restaurantAddr].minPayment, "Insufficient payment.");
        orderCount++;
        orders[orderCount] = Order(orderCount, true, restaurantAddr, msg.sender, msg.value*7/10, false, false, false, false, false, address(0),msg.value/10);

        emit OrderPlaced(orderCount, restaurantAddr, msg.sender, msg.value);
    }
// 2. Function for the restaurant to accpet the order
    function acceptOrderRestaurant(uint _orderId) public {
        require(orders[_orderId].activeOrder, "Inactive order.");
        require(restaurants[msg.sender].hasRegistered == true, "You are not registered yet! Please register first.");
        require(orders[_orderId].restaurant == msg.sender, "You cannot accept this order.");
        require(!orders[_orderId].acceptedRestaurant, "Order already accepted.");

        orders[_orderId].acceptedRestaurant = true;

        emit OrderAccepted(_orderId, msg.sender, orders[_orderId].customer, orders[_orderId].amount);
    }

// 3. Function for delivery person to accept the order
    function acceptOrderDelivery(uint _orderId) public{
        require(delivery_people[msg.sender].hasRegistered, "You are not registered yet! Please register first.");
        require(!delivery_people[msg.sender].hasActiveOrder, "You have an active order right now, please check In first before next attempt.");
        require(orders[_orderId].activeOrder, "Inactive order.");
        require(!orders[_orderId].acceptedDelivery, "Order already accepted.");
        require(orders[_orderId].acceptedRestaurant, "Order not yet accepted by the restaurant");

        delivery_people[msg.sender].hasActiveOrder=true;
        orders[_orderId].acceptedDelivery = true;
        orders[_orderId].delivery_person = msg.sender;

        emit OrderAcceptedDelivery(_orderId, orders[_orderId].restaurant, orders[_orderId].customer, msg.sender, orders[_orderId].amount);
    }

// 4. Function for the restaurant to indicate the order is ready
    function orderReady(uint _orderId) public {
        require(orders[_orderId].activeOrder, "Inactive order.");
        require(restaurants[msg.sender].hasRegistered == true, "You are not registered yet! Please register first.");
        require(orders[_orderId].restaurant == msg.sender, "You cannot complete this order.");
        require(orders[_orderId].acceptedRestaurant, "Order not accepted yet.");
        require(!orders[_orderId].readyForDeli, "Order already ready.");

        orders[_orderId].readyForDeli = true;

        emit OrderReady(_orderId, msg.sender, orders[_orderId].customer, orders[_orderId].amount);
    }
// 5. Function for the delivery person to confirm his pickup of the order
    function pickedUpOrder(uint _orderId) public {
        require(orders[_orderId].activeOrder, "Inactive order.");
        require(delivery_people[msg.sender].hasRegistered == true,"You are not registered yet! Please register first.");
        require(orders[_orderId].delivery_person == msg.sender, "This is not your order.");
        require(orders[_orderId].acceptedRestaurant, "Order not accepted yet.");
        require(orders[_orderId].readyForDeli == true, "Order is not yet ready");
        
        payable(orders[_orderId].restaurant).transfer(orders[_orderId].amount);
        orders[_orderId].pickedUpDelivery = true;
        
        emit OrderPickedup(_orderId, msg.sender, orders[_orderId].customer, orders[_orderId].amount);
    }
// 6. Function for delivery person to confirm his delivery of the order
    function completeOrderDelivery(uint _orderId) public {
        require(orders[_orderId].activeOrder, "Inactive order.");
        require(delivery_people[msg.sender].hasRegistered == true, "You are not registered yet! Please register first.");
        require(orders[_orderId].delivery_person == msg.sender, "You cannot complete this order.");
        require(!orders[_orderId].completedDeli, "Order already completed.");
        require(orders[_orderId].pickedUpDelivery == true, "Order not yet picked up");

        delivery_people[msg.sender].hasActiveOrder=false;
        orders[_orderId].completedDeli = true;

        emit OrderCompleteDelivery(_orderId, orders[_orderId].restaurant, orders[_orderId].customer, msg.sender, orders[_orderId].amount);
    }
// 7. Function for customers to confirm his receipt of the order
    function confirmDelivery(uint _orderId) public {
        require(customers[msg.sender].hasRegistered == true, "You are not registered yet! Please register first.");
        require(orders[_orderId].customer == msg.sender, "This is not your order.");
        // require(orders[_orderId].acceptedDelivery, "Order not accepted by the delivery person yet.");
        require(orders[_orderId].completedDeli, "Order already completed.");
        payable(orders[_orderId].delivery_person).transfer(orders[_orderId].deli_fee);
        orders[_orderId].activeOrder = false;

        emit OrderComplete(_orderId, orders[_orderId].restaurant, orders[_orderId].customer, msg.sender, orders[_orderId].amount);
    }
// Functions for users to request to be customer, restaurant holder, or delivery person
    function requestRegisterCustomer(string memory _name, uint _id, string memory _address, uint _phone) public{
        request_customers.push(Customer(_name, _id, _address, _phone, msg.sender, 0, true));
    }
    function requestRegisterRestaurant(string memory _name, uint _id, string memory _addr, string memory _cuisine, uint _minPayment) public {
        request_restaurants.push(Restaurant(_name, _id, _addr, _cuisine, _minPayment, msg.sender, true));
    }
    function requestRegisterDeliveryPerson(string memory _name, uint _id, uint _phone) public{
        request_delivery_people.push(Delivery_Person(_name, _id, _phone, msg.sender, true, false));
    }

// Functions for Admin to approve the register requests
    function registerCustomer(uint customerIndex) public {
        require(payable(msg.sender) == owner, "Only the Admin Can complete your register");
        customers[request_customers[customerIndex].wallet] = request_customers[customerIndex];
        customers[request_customers[customerIndex].wallet].hasRegistered = true;
        // request_customers[customerIndex]=request_customers[request_customers.length-1];
        // request_customers.pop();
    }
    function registerRestaurant(uint restaurantIndex) public {
        require(payable(msg.sender) == owner, "Only the Admin Can complete your register");
        restaurants[request_restaurants[restaurantIndex].wallet] = request_restaurants[restaurantIndex];
        restaurants[request_restaurants[restaurantIndex].wallet].hasRegistered = true;
        // request_restaurants[restaurantIndex]=request_restaurants[request_restaurants.length-1];
        // request_restaurants.pop();
    }
    function registerDeliveryPerson(uint deliveryPersonId) public{
        require(payable(msg.sender) == owner, "Only the Admin Can complete your register");
        delivery_people[request_delivery_people[deliveryPersonId].wallet] = request_delivery_people[deliveryPersonId];
        delivery_people[request_delivery_people[deliveryPersonId].wallet].hasRegistered = true;
        // request_delivery_people[deliveryPersonId] = request_delivery_people[request_delivery_people.length-1];
        // request_delivery_people.pop();
    }
    function rejectCustomer(uint customerIndex) public {
        require(payable(msg.sender) == owner, "Only the Admin Can complete your register");
        request_customers[customerIndex]=request_customers[request_customers.length-1];
        request_customers.pop();
    }
    function rejectRestaurant(uint restaurantIndex) public {
        require(payable(msg.sender) == owner, "Only the Admin Can complete your register");
        request_restaurants[restaurantIndex]=request_restaurants[request_restaurants.length-1];
        request_restaurants.pop();
    }
    function rejectDeliveryPerson(uint deliveryPersonId) public{
        require(payable(msg.sender) == owner, "Only the Admin Can complete your register");
        request_delivery_people[deliveryPersonId] = request_delivery_people[request_delivery_people.length-1];
        request_delivery_people.pop();
    }
    function getRestaurantMinPayment(address _restaurantAddr) public view returns (uint) {
        return restaurants[_restaurantAddr].minPayment;
    }

    function getCustomerBalance() public view returns (uint) {
        return customers[msg.sender].balance;
    }
// Function for customer to cancel the order
    function cancel(uint _orderId) public {
        require(!orders[_orderId].acceptedRestaurant, "Cannot cancel order, restaurant already accepted the order.");
        uint amount = customers[msg.sender].balance;
        customers[msg.sender].balance = 0;
        orders[_orderId].activeOrder = false;
        payable(msg.sender).transfer(amount);
    }
// Function for the Admin to withdraw earnings from the contract
    function withdrawMoneyAdmin() public{
        owner.transfer(address(this).balance);
    }


    //possible idea: delivery person bid for delivery fee

}