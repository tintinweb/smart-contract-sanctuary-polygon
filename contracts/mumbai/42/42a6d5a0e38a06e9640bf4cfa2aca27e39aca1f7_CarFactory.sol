/**
 *Submitted for verification at polygonscan.com on 2022-05-09
*/

// SPDX-License-Identifier: MIT


pragma solidity   ^0.8.13 ;


contract Car {

    address public   owner  ;
    string public model  ;
    address public carAddr ;


    constructor ( string memory _model) payable {
        
        owner = msg.sender ;
        model = _model ;
        carAddr = address(this) ;

    }

}

contract CarFactory {

    // only owner 

    address private  _owner ;
    Car[] public cars ;

    event OwnershipTransferred(address indexed previousOwner , address  indexed newOwner ) ;

    modifier onlyOwner () {
        require (owner() == msg.sender   , "caller is not the owner ")  ;

        _ ; 
    }

    constructor() {
        _owner = msg.sender ;
        emit OwnershipTransferred(address(0)  , msg.sender )  ;
    }


    function owner () public view returns(address) {
        return _owner ;
    }



    function create ( string calldata _model)public onlyOwner {
        Car car = new Car(_model) ;
        cars.push(car) ;

    }

    function createAndSendAsset (string calldata _model) public onlyOwner payable{

        Car car = (new Car) {value : msg.value} (_model) ;
        cars.push(car) ;
    }




    function create2(string  calldata _model  , bytes32 _salt )public onlyOwner {

        Car car = (new Car ) {salt: _salt} (_model) ;
        cars.push(car) ;

    }


    function create2AndSendAsset (string calldata _model , bytes32 _salt )public payable {
        Car car = (new Car) {salt : _salt  , value : msg.value }(_model) ;

        cars.push (car) ;

    }

    function getCar (uint _index ) public view returns (address car_owner  , string memory model  , address carAddr , uint balance){

        Car car = cars[_index] ;
        return (car.owner() , car.model() , car.carAddr() , address(car).balance) ;

    }
}