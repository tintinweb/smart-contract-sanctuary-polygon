/**
 *Submitted for verification at polygonscan.com on 2023-05-21
*/

pragma solidity ^0.8.7;

contract User {
    
    struct Details {
        string privateKey;
        string password;
        string phoneNumber;
        string vehicle;
        string vehicleNo;
        string name;
        string category;
    }
    
    struct Rides {
        string driver;
    }
    
    mapping (string => Details) detailsMap;
    mapping (string => Rides[]) finalBid;
    
    function get(string memory username) public view returns (string memory, string memory, string memory, string memory, string memory, string memory, string memory) {
        Details memory currentUser = detailsMap[username];
        return (
            currentUser.privateKey,
            currentUser.phoneNumber,
            currentUser.vehicle,
            currentUser.vehicleNo,
            currentUser.category,
            currentUser.name,
            currentUser.password
        );
    }
    
    function set(string memory name, string memory username, string memory phoneNumber, string memory vehicle, string memory vehicleNo, string memory category, string memory password, string memory key) public {
        detailsMap[username] = Details(
            key,
            password,
            phoneNumber,
            vehicle,
            vehicleNo,
            name,
            category
        );
    }
    
    function setFinalBid(string memory driver, string memory rider) public {
        finalBid[rider].push(Rides(driver));
    }
    
    function getFinalBid(string memory rider) public view returns (uint) {
        return finalBid[rider].length;
    }
}