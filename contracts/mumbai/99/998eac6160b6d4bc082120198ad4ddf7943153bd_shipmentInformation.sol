/**
 *Submitted for verification at polygonscan.com on 2022-06-12
*/

pragma solidity ^0.8.4;

contract shipmentInformation{

    struct shipmentdetails{
        uint shipmentnumber;
        uint ordernumber;
        address orderby;
        string timestamp; 
    }

    mapping(uint => shipmentdetails) public ShipmentInformation;

    function saveShipmentInformation(uint _shipmentnumber, uint _ordernumber, address _orderby, string memory _timestamp) external{
            shipmentdetails memory newshipmentInformation;
            newshipmentInformation.shipmentnumber = _shipmentnumber;
            newshipmentInformation.ordernumber = _ordernumber;
            newshipmentInformation.orderby = _orderby;
            newshipmentInformation.timestamp = _timestamp;

            ShipmentInformation[_shipmentnumber] =  newshipmentInformation;
    }

    function getShipmentdetailbynumber(uint _shipmentnumber) public view returns (shipmentdetails memory){
        return ShipmentInformation[_shipmentnumber];
    }

}