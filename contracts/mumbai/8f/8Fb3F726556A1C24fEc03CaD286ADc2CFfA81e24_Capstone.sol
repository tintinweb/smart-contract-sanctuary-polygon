/**
 *Submitted for verification at polygonscan.com on 2022-11-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Capstone {

    address private owner;

    struct LAND {
        uint256 id;
        string uri;
        uint256 price;
        mapping(address => uint256) holders;
        address max_holder;
        uint256 max_amount;
        uint256 remain;

        bool listed_rent;
        bool rented;
        address renter;
        uint256 rent_price;
        uint256 rent_start_date;
        uint256 rent_end_date;
        mapping(address => bool) rewards;
    }
    
    mapping(uint256 => LAND) public lands;
    uint256 land_count;

    uint256[] landList;
    uint256[] rentList;

    address public dead = 0x000000000000000000000000000000000000dEaD;

    constructor() {
        owner = msg.sender;
        land_count = 0;
    }

    modifier onlyOwner {
        require(owner == msg.sender, "This function can be called by only owner");
        _;
    }

    function addLand ( string memory uri_, uint256 price_ ) onlyOwner public {
        lands[land_count].id = land_count;
        lands[land_count].uri = uri_;
        lands[land_count].price = price_;
        lands[land_count].max_holder = dead;
        lands[land_count].max_amount = 0;
        lands[land_count].remain = price_;
        lands[land_count].rented = false;
        lands[land_count].renter = dead;

        landList.push(land_count);
        land_count ++;
    }

    function buyLand ( uint256 id ) public payable {
        require(lands[id].remain >= msg.value, "This land is not enough.");
        uint256 land_price = lands[id].holders[msg.sender];
        if(lands[id].max_amount < land_price + msg.value) {
            lands[id].max_amount = land_price + msg.value;
            lands[id].max_holder = msg.sender;
        }
        lands[id].remain = lands[id].remain - msg.value;
        lands[id].holders[msg.sender] += msg.value;
        if(lands[id].remain == 0) {
            for(uint256 i = 0 ; i < landList.length ; i ++) {
                if(landList[i] == id) {
                    for(uint256 j = i ; j < landList.length - 1 ; j++) {
                        landList[j] = landList[j + 1];
                    }
                    landList.pop();
                    break;
                }
            }
        }
    }

    function listRent ( uint256 id, uint256 price ) public {
        require(lands[id].remain == 0, "This land can not be list to rent. Because the property did not sell 100% yet");
        require(lands[id].max_holder == msg.sender, "You are not allowed to rent");
        require(lands[id].listed_rent == false, "This land is already listed");
        rentList.push(id);
        lands[id].listed_rent = true;
        lands[id].rent_price = price;
    }

    function stopRent ( uint256 id ) public {
        require(lands[id].max_holder == msg.sender, "You are not allowed to do this action");
        for(uint256 i = 0 ; i < rentList.length ; i ++) {
            if(rentList[i] == id) {
                lands[id].listed_rent = false;
                lands[id].rent_price = 0;
                for(uint256 j = i ; j < rentList.length - 1; j ++) {
                    rentList[j] = rentList[j + 1];
                }
                rentList.pop();
                break;
            }
        }
    }

    function rentLand ( uint256 id, uint256 start_date, uint256 end_date ) public payable {
        require(lands[id].listed_rent == true, "This land is not allowed to rent");
        require(lands[id].rented == false, "This land is already rented");
        uint256 period = (end_date - start_date) / 60 / 60 / 24;
        require(lands[id].rent_price * period / 30 <= msg.value, "Insufficient money");
        lands[id].renter = msg.sender;
        lands[id].rented = true;
        lands[id].rent_start_date = start_date;
        lands[id].rent_end_date = end_date;
    }

    function delayRent (uint256 id, uint256 to_date) public payable {
        require(lands[id].renter == msg.sender, "You can not delay to rent for this land.");
        uint256 period = (to_date - lands[id].rent_end_date) / 60 / 60 / 24;
        require(lands[id].rent_price * period / 30 <= msg.value, "Insufficient money");
        lands[id].rent_end_date = to_date;
    }

    function getLandListByUser (address user) public view returns (uint256[] memory) {
        uint256 len = 0;
        uint256 i;
        uint256 j;
        for(i = 0 ; i < landList.length ; i ++) {
            j = landList[i];
            if(lands[j].holders[user] != 0) {
                len ++;
            }
        }
        uint256[] memory result = new uint256 [] (len);
        uint256 k = 0;
        for(i = 0 ; i < landList.length ; i ++) {
            j = landList[i];
            if(lands[j].holders[user] != 0) {
                result[k ++] = j;
            }
        }

        return result;
    }

    function getRentListByUser (address user) public view returns (uint256[] memory) {
        uint256 len = 0;
        uint256 i;
        uint256 j;
        for(i = 0 ; i < rentList.length ; i ++) {
            j = rentList[i];
            if(lands[j].renter == user) {
                len ++;
            }
        }
        uint256[] memory result = new uint256 [] (len);
        uint256 k = 0;
        for(i = 0 ; i < rentList.length ; i ++) {
            j = rentList[i];
            if(lands[j].renter == user) {
                result[k ++] = j;
            }
        }

        return result;
    }

    function getLandList () public view returns (uint256[] memory) {
        return landList;
    }

    function getRentList () public view returns (uint256[] memory) {
        return rentList;
    }

    function getLandInfo (uint256 id) public view returns (string memory , uint256, uint256) {
        LAND storage current = lands[id];
        return (current.uri, current.price, current.remain);
    }

    function getRentInfo (uint256 id) public view returns (address, uint256, uint256, uint256) {
        LAND storage current = lands[id];
        return (current.renter, current.rent_price, current.rent_start_date, current.rent_end_date);
    }

    function calcReward (uint256 id, address user) public view returns (uint256 ) {
        LAND storage current = lands[id];
        if(current.rented == false || current.rewards[user] == true) {
            return 0;
        }
        uint256 period = (current.rent_end_date - current.rent_start_date) / 60 / 60 / 24;
        uint256 total_amount = current.rent_price * period / 30;
        uint256 result = total_amount * current.holders[user] / current.price;
        return result;
    }

    function withdrawReward (uint256 id) public payable {
        require(lands[id].rewards[msg.sender] == false, "You already withdraw reward");
        address receiver = msg.sender;
        uint256 reward = calcReward(id, receiver);
        require(reward > 0, "No rewards");
        payable(receiver).transfer(reward);
        lands[id].rewards[msg.sender] = true;
    }
}