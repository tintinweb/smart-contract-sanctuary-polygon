// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

contract AdministratorContract  {

    mapping (uint256 => Administrator) private administrators;
    address[] private addsAdministrators;

    struct Administrator {
        uint256 idAdministrator;
        address administratorAddress;
        uint256 taxId;
        string name;
        State stateOf;
    }

    enum State { Inactive, Active }

    event AdminAdded(address indexed from_, 
                     address indexed address_, 
                     string name_, 
                     uint256 taxId_, 
                     uint256 timestamp_);

    event AdminUpdated(address indexed from_, 
                       address indexed oldAddress_, 
                       address indexed newAddress_, 
                       string name_, 
                       uint256 taxId_, 
                       State state_,
                       uint256 timestamp_);

    constructor(uint256 _taxId, string memory _name) {
        addsAdministrators.push(msg.sender);
        administrators[0] = Administrator(0, msg.sender, _taxId, _name, State.Active);
    }

    modifier onlyAdmin {
        require(checkIfAdministratorExists(msg.sender), "Sender must be administrator.");
        _;
    }

    modifier adminNotAddedYet(address _address) {
        require(!checkIfAdministratorExists(_address), "Administrator already exists.");
        _;
    }

    modifier adminAddedYet(address _address) {
        require(checkIfAdministratorExists(_address), "Administrator not exists.");
        _;
    }

    modifier adminIsActive(address _address) {
        require(checkIfAdministratorIsActive(_address), "Administrator is not active.");
        _;
    }

    function addAdministrator (address _address, string memory _name, uint256 _taxId) 
             public 
             onlyAdmin() 
             adminIsActive(msg.sender)
             adminNotAddedYet(_address) {

        administrators[addsAdministrators.length] =
                Administrator(addsAdministrators.length, _address, _taxId, _name, State.Active);
        addsAdministrators.push(_address);

        emit AdminAdded(msg.sender, _address, _name, _taxId, block.timestamp);
    }

    function updateAdministrator (address _addressKey, 
                                  address _address, 
                                  uint256 _taxId, 
                                  string memory _name, 
                                  State _state) 
             public 
             onlyAdmin()
             adminIsActive(msg.sender)
             adminAddedYet(_addressKey) {

        require(_address != address(0), "Address not given.");
        require(_taxId != 0, "TaxId not given.");
        require(keccak256(abi.encodePacked(_name)) != keccak256(abi.encodePacked("")), "Name not given.");

        bool difAdd;
        address add;
        uint256 _id;

        for (uint256 i = 0; i < addsAdministrators.length; i++) {
            if (addsAdministrators[i] ==  _addressKey) {
                _id = i;
                break;
            }
        }

        if (administrators[_id].administratorAddress != _address) {
            difAdd = true;
            add = administrators[_id].administratorAddress;
        }

        administrators[_id] = Administrator(_id, _address, _taxId, _name, _state);

        if (difAdd) {
            for (uint256 i = 0; i < addsAdministrators.length; i++) {
                if (addsAdministrators[i] == add) {
                    addsAdministrators[i] = _address;
                    break;
                }
            }
        }

        emit AdminUpdated(msg.sender, _addressKey, _address, _name, _taxId, _state, block.timestamp);
    }

    function getAdministrator (uint256 _id) 
             public view 
             onlyAdmin()
             adminIsActive(msg.sender)
             returns(Administrator memory) {

        return administrators[_id];
    }

    function getAllAdministrators () 
             public view 
             onlyAdmin()
             adminIsActive(msg.sender)
             returns (Administrator[] memory) {

        Administrator[] memory result = new Administrator[](addsAdministrators.length);
        for (uint i = 0; i < addsAdministrators.length; i++) {
            result[i] = administrators[i];
        }
        return result;
    }

    function checkIfAdministratorExists (address _address) 
             public view 
             returns (bool){
        for (uint i = 0; i < addsAdministrators.length; i++)
            if(addsAdministrators[i] == _address)
                return true;

        return false;
    }

    function checkIfAdministratorIsActive (address _address)
             public view
             returns (bool)  {
                   
        for (uint i = 0; i < addsAdministrators.length; i++) {
            if(addsAdministrators[i] == _address && 
                administrators[i].stateOf == State.Active) 
                    return true;      
        }

        return false;    
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "./AdministratorContract.sol";
import "./EmployerContract.sol";
import "./UtilContract.sol";

contract EmployeeContract {

    AdministratorContract private admin;
    EmployerContract private employer;
    UtilContract private util;
    mapping (uint256 => Employee) private employees;
    address[] private addsEmployees;

    struct Employee {
        uint256 idEmployee;
        address employeeAddress;
        uint256 taxId;
        string name;
        uint256 begginingWorkDay;
        uint256 endWorkDay;
        State stateOf;
        address employerAddress;
    }

    enum State { Inactive, Active }
    
    event EmployeeAdded(address indexed from_, 
                        address indexed address_, 
                        string name_, 
                        uint256 taxId_, 
                        uint256 begginingWorkDay_,
                        uint256 endWorkDay_,
                        address employerAddress_,
                        uint256 timestamp_);

    event EmployeeUpdated(address indexed from_, 
                          address indexed oldAddress_, 
                          address indexed newAddress_, 
                          uint256 begginingWorkDay_,
                          uint256 endWorkDay_,
                          address employerAddress_,
                          State state_,
                          uint256 timestamp_);

    constructor(address _adm, address _employer, address _util) {
        admin = AdministratorContract(_adm);
        employer = EmployerContract(_employer);
        util = UtilContract(_util);
    }

    modifier onlyAdmin() {
        require(admin.checkIfAdministratorExists(msg.sender), "Sender must be administrator.");
        _;
    }

    modifier adminIsActive() {
        require(admin.checkIfAdministratorIsActive(msg.sender), "Administrator is not active.");
        _;
    }

    modifier employeeNotAddedYet(address _address) {
        require(!checkIfEmployeeExists(_address), "Employee already exists.");
        _;
    }

    modifier employeeAddedYet(address _address) {
        require(checkIfEmployeeExists(_address), "Employee not exists.");
        _;
    }

    modifier employerAddedYet(address _address) {
        require(employer.checkIfEmployerExists(_address), "Employer not exists.");
        _;
    }

    modifier validWorkday(uint256 _beggining, uint256 _end) {
        require(util.validateTime(_beggining), "Not valid beggining work day.");
        require(util.validateTime(_end), "Not valid end work day.");
        require(_beggining < _end, "Beggining Work Day must be less than End Work Day.");
        _;
    }

    function addEmployee (address _address, 
                          string memory _name, 
                          uint256 _taxId, 
                          uint256 _begginingWorkDay, 
                          uint256 _endWorkDay, 
                          address _employerAddress) 
             public 
             onlyAdmin() 
             adminIsActive()
             employerAddedYet(_employerAddress)
             employeeNotAddedYet(_address) 
             validWorkday(_begginingWorkDay, _endWorkDay) {

        require(_address != address(0), "Address not given.");
        require(_taxId != 0, "TaxId not given.");
        require(keccak256(abi.encodePacked(_name)) != keccak256(abi.encodePacked("")), "Name not given.");
        require(_employerAddress != address(0), "Employer address not given.");

        employees[addsEmployees.length] = Employee(addsEmployees.length, 
                                                   _address, 
                                                   _taxId, 
                                                   _name, 
                                                   _begginingWorkDay,
                                                   _endWorkDay,
                                                   State.Active, 
                                                   _employerAddress);
        addsEmployees.push(_address);

        emit EmployeeAdded(msg.sender, _address, _name, _taxId, _begginingWorkDay, _endWorkDay, _employerAddress, block.timestamp);
    }

    function updateEmployee (address _addressKey, 
                             address _address, 
                             uint256 _taxId, 
                             string memory _name, 
                             uint256 _begginingWorkDay, 
                             uint256 _endWorkDay, 
                             State _state, 
                             address _employerAddress) 
             public 
             onlyAdmin() 
             adminIsActive()
             employerAddedYet(_employerAddress)
             employeeAddedYet(_addressKey) 
             validWorkday(_begginingWorkDay, _endWorkDay) {

        require(_address != address(0), "Address not given.");
        require(_taxId != 0, "TaxId not given.");
        require(keccak256(abi.encodePacked(_name)) != keccak256(abi.encodePacked("")), "Name not given.");
        require(_employerAddress != address(0), "Employer address not given.");

        bool difAdd;
        address add;
        uint256 _id;

        for (uint256 i = 0; i < addsEmployees.length; i++) {
            if (addsEmployees[i] ==  _addressKey) {
                _id = i;
                break;
            }
        }

        if (employees[_id].employeeAddress != _address) {
            difAdd = true;
            add = employees[_id].employeeAddress;
        }

        employees[_id] = Employee(_id, 
                                  _address, 
                                  _taxId, 
                                  _name, 
                                  _begginingWorkDay,
                                  _endWorkDay,
                                  _state, 
                                  _employerAddress);

        if (difAdd) {
            for (uint256 i = 0; i < addsEmployees.length; i++) {
                if (addsEmployees[i] == add) {
                    addsEmployees[i] = _address;
                    break;
                }
            }
        }

         emit EmployeeUpdated(msg.sender, _addressKey, _address, _begginingWorkDay, _endWorkDay, _employerAddress, _state,  block.timestamp);
    }

    function getEmployeeById
             (uint256 _id) 
             public view 
             onlyAdmin()
             adminIsActive()
             returns(Employee memory) {

        return employees[_id];
    }

    function getEmployeeByAddress
             (address _address) 
             public view 
             onlyAdmin()
             adminIsActive()
             returns (Employee memory) {

        Employee memory e;
        for (uint256 i = 0; i < addsEmployees.length; i++) {
            if (addsEmployees[i] == _address) {
                e = employees[i];
                break;
            }
        }
        return e;
    }
    
    function getAllEmployees() 
             public view 
             onlyAdmin()
             adminIsActive()
             returns (Employee[] memory) {

        Employee[] memory result = new Employee[](addsEmployees.length);
        for (uint i = 0; i < addsEmployees.length; i++) {
            result[i] = employees[i];
        }
        return result;
    }
    
    function checkIfEmployeeExists
             (address _address) 
             public view 
             onlyAdmin()
             adminIsActive()
             returns (bool){

        for (uint i = 0; i < addsEmployees.length; i++)
            if(addsEmployees[i] == _address)
                return true;

        return false;
    }

    function getEmployerContract() 
             public view 
             onlyAdmin()
             adminIsActive()
             returns (address _empContract) {

        return address(employer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "./AdministratorContract.sol";

contract EmployerContract {

    AdministratorContract private admin;
    mapping (uint256 => Employer) private employers;
    address[] private addsEmployers;

    struct Employer {
        uint256 idEmployer;
        address employerAddress;
        uint256 taxId;
        string name;
        string legalAddress;
    }

    event EmployerAdded(address indexed from_, 
                        address indexed address_, 
                        string name_, 
                        uint256 taxId_, 
                        string legalAddress_,
                        uint256 timestamp_);

    event EmployerUpdated(address indexed from_, 
                          address indexed oldAddress_, 
                          address indexed newAddress_, 
                          string name_, 
                          uint256 taxId_, 
                          string legaAddress_,
                          uint256 timestamp_);

    constructor(address _adm) {
        admin = AdministratorContract(_adm);
    }

    modifier onlyAdmin {
        require(admin.checkIfAdministratorExists(msg.sender), "Sender must be administrator.");
        _;
    }

    modifier adminIsActive() {
        require(admin.checkIfAdministratorIsActive(msg.sender), "Administrator is not active.");
        _;
    }

    modifier employerNotAddedYet(address _address) {
        require(!checkIfEmployerExists(_address), "Employer already exists.");
        _;
    }

    modifier employerAddedYet(address _address) {
        require(checkIfEmployerExists(_address), "Employer not exists.");
        _;
    }

    function addEmployer (address _address, 
                          uint256 _taxId, 
                          string memory _name, 
                          string memory _legalAddress) 
             public 
             onlyAdmin()
             adminIsActive()
             employerNotAddedYet(_address) {

        require(_taxId != 0, "TaxId not given.");
        require(keccak256(abi.encodePacked(_name)) != keccak256(abi.encodePacked("")), "Name not given.");
        require(keccak256(abi.encodePacked(_legalAddress)) != keccak256(abi.encodePacked("")), "Legal address not given.");
        require(_address != address(0), "Address not given.");

        employers[addsEmployers.length] = Employer(addsEmployers.length, _address, _taxId, _name, _legalAddress);
        addsEmployers.push(_address);

        emit EmployerAdded(msg.sender, _address, _name, _taxId, _legalAddress, block.timestamp);
    }

    function updateEmployer (address _addressKey, 
                             address _address, 
                             uint256 _taxId, 
                             string memory _name, 
                             string memory _legalAddress) 
             public 
             onlyAdmin()
             adminIsActive()
             employerAddedYet(_addressKey) {

        require(_address != address(0), "Address not given.");
        require(_taxId != 0, "TaxId not given.");
        require(keccak256(abi.encodePacked(_name)) != keccak256(abi.encodePacked("")), "Name not given.");
        require(keccak256(abi.encodePacked(_legalAddress)) != keccak256(abi.encodePacked("")), "Legal address not given.");

        bool difAdd;
        address add;
        uint256 _id;

        for (uint256 i = 0; i < addsEmployers.length; i++) {
            if (addsEmployers[i] ==  _addressKey) {
                _id = i;
                break;
            }
        }

        if (employers[_id].employerAddress != _address) {
            difAdd = true;
            add = employers[_id].employerAddress;
        }

        employers[_id] = Employer(_id, _address, _taxId, _name, _legalAddress);

        if (difAdd) {
            for (uint256 i = 0; i < addsEmployers.length; i++) {
                if (addsEmployers[i] == add) {
                    addsEmployers[i] = _address;
                    break;
                }
            }
        }

        emit EmployerUpdated(msg.sender, _addressKey, _address, _name, _taxId, _legalAddress, block.timestamp);
    }

    function getEmployerById (uint256 _id) 
             public view 
             onlyAdmin()
             adminIsActive()
             returns (Employer memory) {

        return employers[_id];
    }

    function getEmployerByAddress (address _address) 
             public view 
             onlyAdmin()
             adminIsActive()
             returns (Employer memory) {
        
        Employer memory e;
        for (uint256 i = 0; i < addsEmployers.length; i++) {
            if (addsEmployers[i] == _address) {
                e = employers[i];
                break;
            }
        }
        return e;
    }
    
    function getAllEmployers() 
             public view 
             onlyAdmin()
             adminIsActive()
             returns (Employer[] memory) {

        Employer[] memory result = new Employer[](addsEmployers.length);
        for (uint i = 0; i < addsEmployers.length; i++) {
            result[i] = employers[i];
        }
        return result;
    }
    
    function checkIfEmployerExists (address _address) 
             public view 
             onlyAdmin()
             adminIsActive()
             returns (bool){

        for (uint i = 0; i < addsEmployers.length; i++)
            if(addsEmployers[i] == _address)
                return true;

        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

contract UtilContract {

    function getDate(uint timestamp) 
        public pure 
        returns (uint yearMonthDay) {

        require(timestamp > 0, "Timestamp should be more than zero.");
        uint year;
        uint month;
        uint day;
        uint secondsInADay = 60 * 60 * 24; //86400
        uint daysSinceEpoch = timestamp / secondsInADay;
        uint yearSinceEpoch = daysSinceEpoch / 365;
        year = 1970 + yearSinceEpoch;
        uint daysSinceYearStart = daysSinceEpoch - (yearSinceEpoch * 365);

        for (uint i = 1970; i < year; i++) {
            if (i % 4 == 0 && (i % 100 != 0 || i % 400 == 0)) {
                daysSinceYearStart -= 1;
            }
        }

        uint8[12] memory daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

        if (daysSinceYearStart >= 59) { // Handle leap year
            if (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) {
                daysInMonth[1] = 29;
            }
        }

        for (uint i = 0; i < 12; i++) {
            if (daysSinceYearStart < daysInMonth[i]) {
                month = i + 1;
                day = daysSinceYearStart + 1;
                break;
            }
            daysSinceYearStart -= daysInMonth[i];
        }

        yearMonthDay = year * 10000;
        yearMonthDay += (month * 100);
        yearMonthDay += day;
    }

    function validateTime(uint256 _time) 
        public pure 
        returns(bool) {
            
        uint256 hour;
        uint256 minute;
        hour = _time / 100;
        minute = _time % 100;
        if ((hour >= 0 && hour <= 23) && (minute >= 0 && minute <= 59)) {
            return true;
        } else {
            return false;
        }
    }
}