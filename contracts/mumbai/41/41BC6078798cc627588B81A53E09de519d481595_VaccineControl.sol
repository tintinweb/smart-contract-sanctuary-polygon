// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract VaccineControl {

    event statusEvent(uint indexed statusCode);

    struct Person {
        address personAddress;
        string fullName;
        string passportId;
        uint dataofbrith;
        bool created;
        mapping(uint => Vaccine) vaccines;
    }

    struct Vaccine {
        uint dose;
        string batch;
        string place;
    }

    mapping (address => Person) private persons;

    function addPerson(string memory _fullName, string memory _passportId, uint _dataofbrith) public returns (bool) {

        address _address = msg.sender;

        Person storage person = persons[_address];
        person.fullName = _fullName;
        person.passportId = _passportId;
        person.dataofbrith = _dataofbrith;
        person.created = true;

        emit statusEvent(100);

        return true;
    }

    function getPerson() public view returns (string memory , string memory, uint) {
        address _address = msg.sender;
        return (persons[_address].fullName, persons[_address].passportId, persons[_address].dataofbrith);
    }

    function getVaccine(uint _vaccineId) public view returns (uint, string memory, string memory) {
        address _address = msg.sender;
        return (persons[_address].vaccines[_vaccineId].dose,
        persons[_address].vaccines[_vaccineId].batch, persons[_address].vaccines[_vaccineId].place);
    }

    function getAllOne(uint _vaccineId) public view returns (string memory , string memory, uint,uint, string memory, string memory) {
             address _address = msg.sender;
             return (persons[_address].fullName, persons[_address].passportId, persons[_address].dataofbrith,
             persons[_address].vaccines[_vaccineId].dose, persons[_address].vaccines[_vaccineId].batch,
             persons[_address].vaccines[_vaccineId].place);
    }

    function addVaccine(uint _vaccineId, uint _dose, string memory _batch, string memory _place) public
            returns(bool)
    {
        address _address = msg.sender;

        require(
            _dose > 0,
            "Dose is invalid."
        );

        require(
            bytes(_batch).length > 0,
            "Batch is invalid."
        );

        require(
            bytes(_place).length > 0,
            "Place of vaccine is invalid."
        );

        if (persons[_address].created) {
            Vaccine storage vaccine = persons[_address].vaccines[_vaccineId];
            vaccine.dose = _dose;
            vaccine.batch = _batch;
            vaccine.place = _place;
            persons[_address].vaccines[_vaccineId] = vaccine;

            emit statusEvent(101);
        }
        else
        {
            emit statusEvent(400);
        }
        return true;
    }

}