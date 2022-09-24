pragma solidity ^0.8.9;

contract AadharRegistry {

    struct Aadhar {
        string name;
        string _address;
        string dob;
    }

    mapping(address => Aadhar) public _aadhar;


    function createAadhar(
        address _user,
        string memory _name,
        string memory _address,
        string memory _dob
    ) public {

        Aadhar storage aadhar = _aadhar[_user];

        aadhar.name = _name;
        aadhar._address = _address;
        aadhar.dob = _dob;
    }

    function getAadhar(address _user) public view returns(Aadhar memory)
    {
        return _aadhar[_user];
    }

}