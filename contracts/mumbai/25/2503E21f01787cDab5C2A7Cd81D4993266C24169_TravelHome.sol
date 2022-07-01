// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract TravelHome{
    address public owner;
    uint256 private counter;
    mapping(address=> uint256) public  balanceOf;


    mapping(uint256 => RoomInfo) public Rooms;
    mapping(address => RoomInfo[]) public  RoomsOwned;
    uint256[] public roomIds;

    event withdraw(
        address from,
        address to,
        uint256 amount
    );

    event addRooms(
        string name,
        string description,
        string location,
        string[] img,
        string[] latlong,
        uint256[] bedbath,
        uint256 price,
        uint256 maxNumOfPeople,
        string[] placeType,
        string[] features,
        address renter,
        uint256 id
    );


    event bookedRoom(
        string name,
        address booker,
        uint256 id,
        string[] datesBooked,
        string[] img
    );


    event RemoveRoom(
        address from,
        address by,
        uint256 id
    );

    struct RoomInfo{
        string name;
        string description;
        string location;
        string[] img;
        string[] latlong;
        uint256[] bedbath;
        uint256 price;
        uint256 maxNumOfPeople;
        string[] datesBooked;
        string[] placeType;
        string[] features;
        bool removed;
        address renter;
        uint256 id;
    }






    constructor(){
        owner = msg.sender;
        counter = 0;
    }



    function addRoom(
        string memory name,
        string memory description,
        string memory location,
        string[] memory img,
        string[] memory latlong,
        uint256[] memory bedbath,
        string[] memory placeType,
        uint256 price,
        uint256 maxNumOfPeople,
        string[] memory features
        ) public {

            RoomInfo storage newBooking = Rooms[counter];
            newBooking.name = name;
            newBooking.description = description;
            newBooking.location = location;
            newBooking.img = img;
            newBooking.latlong = latlong;
            newBooking.bedbath = bedbath;
            newBooking.price = price;
            newBooking.maxNumOfPeople = maxNumOfPeople;
            newBooking.placeType = placeType;
            newBooking.features = features;
            newBooking.removed = false;
            newBooking.renter = msg.sender;
            newBooking.id = counter;

            RoomsOwned[msg.sender].push(newBooking);

            roomIds.push(counter);

            emit addRooms(
                name,
                description,
                location,
                img,
                latlong,
                bedbath,
                price,
                maxNumOfPeople,
                placeType,
                features,
                msg.sender,
                counter
            );
            counter++;
        }

        function _checkBooking(uint256 id, string[] memory newDates) private view returns (bool){
            for (uint i=0; i< newDates.length; i++){
                for(uint j=0; j<Rooms[id].datesBooked.length; j++){
                    if(keccak256(abi.encodePacked(Rooms[id].datesBooked[j])) == keccak256(abi.encodePacked(newDates[i]))){
                        return false;
                    }
                }
            }
            return true;
        }

        function bookRoom(uint256 id, string[] memory newDate) public payable {
            require(id < counter, "Wrong Room");
            require(_checkBooking(id, newDate), "Room is Already Booked Check Another Room");
            require(Rooms[id].removed == false, "Room is REMOVED");
            require(msg.value == _roomPrice(id, newDate), "Please Pay The Correct Amount" );



            for (uint i=0; i< newDate.length; i++ ){
                Rooms[id].datesBooked.push(newDate[i]);
            }

            balanceOf[owner] += _transactionFee(id, newDate);
            balanceOf[Rooms[id].renter] += Rooms[id].price;

            emit bookedRoom(
             Rooms[id].name ,
             msg.sender ,
             id ,
             newDate ,
             Rooms[id].img
            );


        }

        function _roomPrice(uint256 id,string[] memory newDate) private view returns(uint){
            uint tPrice = _transactionFee(id, newDate) + Rooms[id].price * newDate.length;
            return tPrice;
        } 

        function _transactionFee(uint256 id,string[] memory newDate) private view returns (uint){
            if (msg.sender == owner){
                return 0;
            }
            uint fee = Rooms[id].price * 15 / 100 * newDate.length;
            return fee;
        }

        function withdrawBalance(uint256 amount) public{
            require(amount<= balanceOf[msg.sender], "Not Enough Balance");
            if (msg.sender != owner){
            uint256 fee = amount * 10 /100;
            balanceOf[owner]+= amount * 10 /100;
            amount = amount - fee;
            }
            payable(msg.sender).transfer(amount);

            emit withdraw(
                address(this),
                msg.sender,
                amount
            );
        }

        function OwnedRooms() public view returns (uint) {
            return RoomsOwned[msg.sender].length;
        }

        function removeRoom(uint id) public{
            require(Rooms[id].renter == msg.sender, "You are NOT the OWNER");
            Rooms[id].removed = true;
            emit RemoveRoom(address(this), msg.sender, id);

        }
        

}