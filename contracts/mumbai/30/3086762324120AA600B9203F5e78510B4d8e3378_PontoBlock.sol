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
        require(checkIfAdministratorExists(msg.sender), "Sender must be administrator and be active.");
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

    function addAdministrator (address _address, string memory _name, uint256 _taxId) 
             public 
             onlyAdmin() 
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
             returns(Administrator memory) {

        return administrators[_id];
    }

    function getAllAdministrators () 
             public view 
             onlyAdmin()
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
        
            if(addsAdministrators[i] == _address && 
                    checkIfAdministratorIsActive(_address) )
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
        require(admin.checkIfAdministratorExists(msg.sender), "Sender must be administrator and be active.");
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
             returns(Employee memory) {

        return employees[_id];
    }

    function getEmployeeByAddress
             (address _address) 
             public view 
             onlyAdmin()
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
             returns (bool){

        for (uint i = 0; i < addsEmployees.length; i++)
            if(addsEmployees[i] == _address)
                return true;

        return false;
    }

    function getEmployerContract() 
             public view 
             onlyAdmin()
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
        require(admin.checkIfAdministratorExists(msg.sender), "Sender must be administrator and be active.");
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
             returns (Employer memory) {

        return employers[_id];
    }

    function getEmployerByAddress (address _address) 
             public view 
             onlyAdmin()
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
             returns (bool){

        for (uint i = 0; i < addsEmployers.length; i++)
            if(addsEmployers[i] == _address)
                return true;

        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "./EmployeeContract.sol";
import "./UtilContract.sol";
import "./AdministratorContract.sol";

contract PontoBlock {
    
    EmployeeContract private employee;
    UtilContract private util;
    AdministratorContract private admin;

    int private timeZone;
    int private oneHour = 3600;
    address private owner;
    uint private creationDate;
    mapping(address => mapping(uint256 => EmployeeRecord)) private employeeRecords;

    struct EmployeeRecord {
        uint256 startWork;
        uint256 endWork;
        uint256 breakStartTime;
        uint256 breakEndTime;
    }

    event StartWorkRegistered(address indexed address_, uint256 indexed startWork_, uint256 timestamp_);
    event EndWorkRegistered(address indexed address_, uint256 indexed endWork_, uint256 timestamp_);
    event BreakStartWorkRegistered(address indexed address_, uint256 indexed breakStartWork_, uint256 timestamp_);
    event BreakEndWorkRegistered(address indexed address_, uint256 indexed breakEndtWork_, uint256 timestamp_);

    constructor(address _emp, address _util, address _adm, int _timeZone) {
        employee = EmployeeContract(_emp);
        util = UtilContract(_util);
        admin = AdministratorContract(_adm);
        owner = msg.sender;
        creationDate = util.getDate(getMoment());
        timeZone = _timeZone;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    modifier onlyAdmin() {
        require(admin.checkIfAdministratorExists(msg.sender), "Sender must be administrator and be active.");
        _;
    }

    modifier employeeAddedYet(address _address) {
        require(employee.checkIfEmployeeExists(_address), "Employee not registered.");
        _;
    }

    modifier activeEmployee() {
        require(employee.getEmployeeByAddress(msg.sender).stateOf == EmployeeContract.State.Active, "Employee is inactive.");
        _;
    }

    function startWork() 
        public 
        employeeAddedYet(msg.sender) 
        activeEmployee() {
        
        require(employeeRecords[msg.sender][util.getDate(getMoment())].startWork == 0, "Start of work already registered.");
        employeeRecords[msg.sender][util.getDate(getMoment())].startWork = getMoment();

        emit StartWorkRegistered(msg.sender, employeeRecords[msg.sender][util.getDate(getMoment())].startWork, block.timestamp);
    }

    function endWork() 
        public
        employeeAddedYet(msg.sender) 
        activeEmployee() {

        require(employeeRecords[msg.sender][util.getDate(getMoment())].endWork == 0, "End of work already registered.");
        require(employeeRecords[msg.sender][util.getDate(getMoment())].startWork != 0, "Start of work not registered.");

        uint256 one_hour = 3600;
        if (employeeRecords[msg.sender][util.getDate(getMoment())].breakStartTime != 0 &&
            employeeRecords[msg.sender][util.getDate(getMoment())].breakEndTime == 0)
        {
                if ((getMoment() - employeeRecords[msg.sender][util.getDate(getMoment())].breakStartTime)
                        > one_hour)
                {
                    employeeRecords[msg.sender][util.getDate(getMoment())].breakEndTime =
                        employeeRecords[msg.sender][util.getDate(getMoment())].breakStartTime + one_hour;
                }
                else
                {
                    employeeRecords[msg.sender][util.getDate(getMoment())].breakEndTime = getMoment();
                }
        }

        employeeRecords[msg.sender][util.getDate(getMoment())].endWork = getMoment();

        emit EndWorkRegistered(msg.sender, employeeRecords[msg.sender][util.getDate(getMoment())].endWork, block.timestamp);
    }

    function breakStartTime() 
        public
        employeeAddedYet(msg.sender) 
        activeEmployee() {

        require(employeeRecords[msg.sender][util.getDate(getMoment())].breakStartTime == 0, "Start of break already registered.");
        require(employeeRecords[msg.sender][util.getDate(getMoment())].startWork != 0, "Start of work not registered.");
        require(employeeRecords[msg.sender][util.getDate(getMoment())].endWork == 0, "End of work already registered.");

        employeeRecords[msg.sender][util.getDate(getMoment())].breakStartTime = getMoment();

        emit BreakStartWorkRegistered(msg.sender, employeeRecords[msg.sender][util.getDate(getMoment())].breakStartTime, block.timestamp);
    }

    function breakEndTime() 
        public
        employeeAddedYet(msg.sender) 
        activeEmployee() {

        require(employeeRecords[msg.sender][util.getDate(getMoment())].breakEndTime == 0, "End of break already registered.");
        require(employeeRecords[msg.sender][util.getDate(getMoment())].breakStartTime != 0, "Start of break not registered.");

        employeeRecords[msg.sender][util.getDate(getMoment())].breakEndTime = getMoment();

        emit BreakEndWorkRegistered(msg.sender, employeeRecords[msg.sender][util.getDate(getMoment())].breakEndTime, block.timestamp);
    }

    function getCreationDateContract() 
        public view 
        onlyAdmin()
        returns(uint) {

        return creationDate;
    }

    function getEmployeeRecords (address _address, uint256 _date) 
        public view 
        onlyAdmin()
        employeeAddedYet(_address)
        returns (EmployeeRecord memory) {

        return employeeRecords[_address][_date];
    }

    function getMoment() 
        public view 
        returns(uint256) {

        int adjust = timeZone * oneHour;
        uint256 moment;
        if (adjust < 0) {
            adjust = adjust * -1;
            moment = block.timestamp - uint256(adjust);
        } else {
            moment = block.timestamp + uint256(adjust);
        }
        return moment;
    }

    function changeOwner(address _newOwner) 
        public 
        onlyOwner() {
        owner = _newOwner;
    }

    function getOwner() 
        public view 
        onlyAdmin()
        returns (address) {

        return owner;
    }

    function getTimeZone() 
        public view 
        returns (int) {

        return timeZone;
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