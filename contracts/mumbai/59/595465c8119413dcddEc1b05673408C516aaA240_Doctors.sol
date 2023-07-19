// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/Counters.sol";

contract Doctors {

    using Counters for Counters.Counter;
    Counters.Counter private _doctorIds;

    //Defining an event that is emitted when a new doctor is registered
    event DoctorRegistered(
        address indexed _address,
        string name
    );

    //Defining an event that is emitted when a doctor consults a patient
    event Consulted(
        address indexed docAddress,
        address patientAddress,
        uint256 state
    );

    //Doctor data structure
    struct Doctor{
        address doctorAddress;
        uint256 id;
        string name;
        string dob;
        string url;
        uint256 fees;
        string speciality;
        string email;
        string phoneNumber;
        string hosAddress;
        string qualifications;
        uint64 gender;
    }

    //Treatment data structure
    struct Treatment{
        string remarks;
        string name;
        uint256 frequency;
        uint256 state;
    }

    //array that stores all the doctors that are registered
    Doctor[] private registeredDoctors;
    //Different mappings for storing and fetching data
    mapping(address=>Doctor) private doctorInfo;
    mapping(address=>bool) private doctorPresent;
    mapping(address=>mapping(address=>Treatment[])) private treatments;

    //Function for checking the owner of doctor's records
    function onlyDoctorOwnerAccess(address _address) private view returns(bool){
        return (msg.sender == doctorInfo[_address].doctorAddress);
    }

    //This function checks whether a doctor exists in our records or not
    function checkDoctorExists(address _addr) public view returns(bool){
        require(_addr!=address(0),"Invalid address");
        return doctorPresent[_addr];
    }

    //Function to get list of all registered doctors
    function getDoctors() public view returns(Doctor[] memory){
        return registeredDoctors;
    }
    
     //Function to add a new doctor
    function addDoctor(string calldata _name, string memory _dob, string memory _url, uint256 _fees, string memory _speciality, 
    string memory _email, string memory _phone, string memory _hosAddress, string memory _qualifications, uint64 _gender) external{
        uint256 _id = _doctorIds.current();
        Doctor memory doctor = Doctor(msg.sender,_id,_name,_dob,_url, _fees,_speciality,_email,_phone,_hosAddress,_qualifications,_gender);
        doctorInfo[msg.sender] = doctor;
        doctorPresent[msg.sender] = true;
        registeredDoctors.push(doctor);
        _doctorIds.increment();
        emit DoctorRegistered(msg.sender, _name);
    }

     //Function to view a doctor's information
    function viewDoctorInfo(address _address) external view returns(Doctor memory){
        require(doctorPresent[_address],"No records found");
        return doctorInfo[_address];
    }

     //Below update function is used for updating doctor's basic info
    function updateDoctorInfo(address _address, string calldata _name, string memory _url, uint256 _fees, string memory _email,  string memory _hosAddress,  string memory _qualification
    , string memory _speciality,string memory _phone) external{
        require(onlyDoctorOwnerAccess(_address),"Access denied");
        doctorInfo[_address].name = _name;    
        doctorInfo[_address].url = _url;   
        doctorInfo[_address].fees = _fees;
        doctorInfo[_address].email = _email;     
        doctorInfo[_address].hosAddress = _hosAddress;
        doctorInfo[_address].qualifications = _qualification; 
        doctorInfo[_address].speciality = _speciality;  
        doctorInfo[_address].phoneNumber = _phone; 
        registeredDoctors[doctorInfo[_address].id] = doctorInfo[_address];

    }

    //Function for consulting a patient
    function consultPatient(address _address, string calldata _medicine, uint256 _frequency, string calldata _remarks, uint256 _state) external{
        require(checkDoctorExists(msg.sender),"Not allowed");
        treatments[_address][msg.sender].push(Treatment(_remarks,_medicine, _frequency, _state));
        emit Consulted(msg.sender, _address, _state);
    }
}