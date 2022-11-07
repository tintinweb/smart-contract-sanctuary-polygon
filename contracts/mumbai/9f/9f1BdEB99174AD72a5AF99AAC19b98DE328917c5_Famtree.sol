pragma solidity^ 0.8.0;

contract Famtree{
    struct person{
        string fatherName;
        string maleName;
        string femaleName;
        string dob;
        uint recordDate;
        uint totalWealth;
        uint genNo;
    }
mapping (address => person[]) PeopleOfFamily;
address [] public headOfFamily; // Array that stores the creator of the tree addresses
function createPerson(string memory _name,string memory _femaleName,uint gen,string memory _dob,uint _wealth,string memory _fatherName) public{
   
    PeopleOfFamily[msg.sender].push(person({
        fatherName : _fatherName,
        maleName : _name,
        femaleName : _femaleName,
        dob : _dob,
        recordDate: block.timestamp,
        totalWealth : _wealth,
        genNo : gen
    })
    );
    headOfFamily.push(msg.sender);// Push node creating address into the array
}



function getData(uint genNo) public view returns(string memory){
    return(PeopleOfFamily[msg.sender][genNo].maleName); // Retrive the generation by the generation Number
}
}