/**
 *Submitted for verification at polygonscan.com on 2023-02-13
*/

/**
 *Submitted for verification at polygonscan.com on 2023-02-08
*/

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

contract petAdoption {

uint256 public totalAdopted;


struct Pets{
    uint256 id;
    uint256 createdAt;
    address createdBy;
    uint256 adoptedAt;
    address currentOwner;
    string name;
    string species;
    uint256 age;
    bool vaccinated;
    bool adopted;
}

struct Stats {
    uint256 hasAdopted;
    uint256 petsAdded;
}


mapping (address=>Stats) public userStats;

Pets [] public pets;
uint256 public id=0;
function putForAdoption(string memory _name, string memory _species,uint256 _age,bool _vaccinated) public {
    require(keccak256(abi.encodePacked("cat"))==keccak256(abi.encodePacked(_species))  ||
    keccak256(abi.encodePacked("dog"))==keccak256(abi.encodePacked(_species)) ||
    keccak256(abi.encodePacked("other"))==keccak256(abi.encodePacked(_species)),"Incorrect species !");
    require(userStats[msg.sender].petsAdded<5,"You can't put more than 5 pets for adoption");
    pets.push(Pets(id,block.timestamp,msg.sender,0,msg.sender,_name,_species,_age,_vaccinated,false));
    userStats[msg.sender].petsAdded++;
    id++;
}  


function adoptPet(uint256 _id) public {
    require(pets[_id].currentOwner!=msg.sender,"You can't adopt your own pet!");
    require(pets[_id].adopted==false,"That pet is already adopted");
    pets[_id].adoptedAt=block.timestamp;
    pets[_id].currentOwner=msg.sender;
    pets[_id].adopted=true;
    userStats[msg.sender].hasAdopted++;
    totalAdopted++;
}

function getPetsOwner(uint256 _id) public view returns (address){
    return pets[_id].currentOwner;
}

function totalPets() public view returns(uint256){
return pets.length;
}

function availablePets() public view returns (uint256) {
    return totalPets()-totalAdopted;
}

}