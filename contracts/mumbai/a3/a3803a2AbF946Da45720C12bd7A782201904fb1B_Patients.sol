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

contract Patients {

    using Counters for Counters.Counter;
    Counters.Counter private _patientIds;
    Counters.Counter private _appointmentId;

    //Defining an event that is emitted when a new patient is registered
    event PatientRegistered(
        address indexed _address,
        string name
    );

    //Defining an event that is emitted when a patient makes an appointment
    event AppointmentScheduled(
        address indexed docAddress,
        string date,
        string time
    );

    //Patient data structure
    struct Patient{
        address patientAddress;
        uint256 id;
        string name;
        string dob;
        string url;
        string email;
        uint phoneNumber;
        string resAddress;
        uint gender;
    } 

    //Appointment data structure
    struct Appointment{
        address payable docAddress;
        address patientAddress;
        uint256 id; 
        string date;
        string time;
        uint256 fee;
        bool online;
    }

    //Ratings data structure
    struct Ratings{
        uint256 rating;
        string feedback;
        address patientId;
    }

    //Different mappings for storing and fetching data
    mapping(address=>Patient) private patientInfo;
    mapping(address=>Appointment[])private patientAppointments;
    mapping(address=>bool) private patientPresent;
    mapping(address=>mapping(uint256=>string[])) private medicalRecords;
    mapping(address=>Appointment[]) private docAppointments;
    mapping(address=>address[]) private docPatients;
    mapping(address=>Ratings[]) docRating;

    //Function for checking the owner of patient's records
    function onlyOwnerAccess(address _address) private view returns(bool){
        return (msg.sender == patientInfo[_address].patientAddress);
    }

    //This function checks whether a patient exists in our records or not
    function checkPatientExists(address _addr) public view returns(bool){
        require(_addr!=address(0),"Invalid address");
        return patientPresent[_addr];
    }

    //Function to add a new patient
    function addPatient(string calldata _name, string calldata _dob, string calldata _email, uint _phone, string memory _url,
    string memory _resAddress, uint _gender) external{

        uint256 _id = _patientIds.current();
        patientInfo[msg.sender] = Patient(msg.sender, _id, _name, _dob, _url, _email, _phone, _resAddress, _gender);
        patientPresent[msg.sender] = true;
        _patientIds.increment();
        emit PatientRegistered(msg.sender,_name);
    }

    //Function to view a patient's information
    function viewPatientInfo(address _address) external view returns(Patient memory){
        require(checkPatientExists(_address),"No records found");
        return patientInfo[_address];
    }

    //Below update function is used for updating patient's basic info
    function updateInfo(address _address, string calldata _name, uint _phone, string calldata _email,
    string memory _url, string memory _resAddress) external{
        require(onlyOwnerAccess(_address),"Access denied");
        patientInfo[_address].name = _name;
        patientInfo[_address].phoneNumber = _phone;
        patientInfo[_address].email = _email;
        patientInfo[_address].url = _url;
        patientInfo[_address].resAddress = _resAddress;
    }
    
    //Payable Function by which patient creates an appointment
    function makeAppointment(address payable _docAddress, string calldata _date, string calldata _time, uint _fee, bool _online)
     payable external returns(bool){
        require(_docAddress!=address(0),"Invalid address");
        require(msg.value==_fee,"Invalid amount");
        require(onlyOwnerAccess(msg.sender),"Access denied");
        uint256 _id = _appointmentId.current();
        Appointment memory appointment = Appointment(_docAddress, msg.sender,_id,_date, _time, _fee, _online);
        patientAppointments[msg.sender].push(appointment);
        docAppointments[_docAddress].push(appointment);
        docPatients[_docAddress].push(msg.sender);
        _appointmentId.increment();
        //amount is transferred to doctor's address
        (bool sent,) = _docAddress.call{value:msg.value}("");
        emit AppointmentScheduled(_docAddress,_date,_time);
        return sent;
    }

    //Function through which patients can view their appointments
    function viewMyAppointments(address _address) external view returns(Appointment[] memory){
        require(onlyOwnerAccess(_address),"Access denied");
        return patientAppointments[_address];
    }

    //Functions for updating scheduled appointment details
    function updateAppointmentDetails(address _address, uint _id, string calldata _date, string calldata _time) external{
        require(onlyOwnerAccess(_address),"Access denied");
        require(_id>=0 && _id<=patientAppointments[msg.sender].length,"Invalid appointment id");
        patientAppointments[_address][_id].date = _date;
        patientAppointments[_address][_id].time = _time;
        address _docAddress =  patientAppointments[_address][_id].docAddress;
        docAppointments[_docAddress][_id].date = _date;
        docAppointments[_docAddress][_id].time = _time;
    }

    //Function to view a patient's medical records
    function viewMedicalRecords(address _address, uint _index) external view returns(string[] memory){
        return medicalRecords[_address][_index];
    }

    //Function for updating a patient's medical records
    function updateMedicalRecords(address _address, uint _index, string memory _record) external {
        medicalRecords[ _address][_index].push(_record);
    }

    //Function through which doctors can view their appointments
    function viewDocAppointments() external view returns(Appointment[] memory){
        return docAppointments[msg.sender];
    }

    //Function to check whether a patient is treated by a particular doctor or not
    function checkIfDocPatient(address _address) private view returns(bool){
        for(uint256 i=0;i<docPatients[_address].length;i++){
            if(msg.sender==docPatients[_address][i]){
                return true;
            }
        }
        return false;
    }
    //Function through which patients can give ratings to their doctors
    function rateDoctor(address _address, uint256 _rating, string calldata _feedback) external{
        require(checkIfDocPatient(_address),"Not allowed");
        docRating[_address].push(Ratings(_rating,_feedback,msg.sender));
    }

    //Doctors can view ratings given to them thorugh this function
    function viewDoctorRatings(address _address) external view returns(Ratings[] memory){
        return docRating[_address];
    }
}