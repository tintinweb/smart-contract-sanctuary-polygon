// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.1;

import "./USDCInterface.sol";

contract Payroll {

    address public companyManager;

    uint8 public employeeCount;

    uint256 public totalRegisteredEmploye;

    bool intialState;

    USDCInterface public usdcContractAddress;

    uint256 tokenBalance;

    uint256 public constant numberofDays = 25 days; //pay days

    enum Status{
        pending,
        approved
    }

    // enum Role{
    //     Teacher,
    //     Engineer,
    //     Developer
    // }

    enum EmployeeLevel{
        Junior,
        Intermediate,
        Senior
    }

    struct EmployeeInfo{
        string name;
        address employeeAddress;
        string post;
        EmployeeLevel level;
        uint timeFilled;
        bool registered;
        Status status;
        bool approved;
        bool pendingReview;
        uint timeOfPendingReview;
        uint256 timeOfApproval;
    }

    EmployeeInfo[] _employeeInfo;
    address[] EmployeeAddress;
    address[] approvedEmployeeAddress;
    mapping(address => EmployeeInfo) info;

    struct SalaryInvoice{
        string name;
        address employeeAddress;
        string post;
        EmployeeLevel level;
        uint time;
        uint amountTobepaid;
        uint ratePerDay;
        string description;
        uint extraWorkFee;
        bool approved;
        bool set;
     
    }

    mapping(address => SalaryInvoice) _salaryInvoice;


    /////////////EVENTS////////////////
    event Registered(address indexed caller, uint256 time);
    event Deposit(address indexed depositor, uint256 indexed amount);
    event Withdrawal(address indexed employee, uint256 indexed amount);
    event ManagerUpdated( address indexed oldCompanyManager, address indexed companyManager, uint256 time);


    ///////////ERROR MESSAGE///////////
    error NotVerified();

    error  TimeNotReached();

    error ZeroAmount();

    error InsufficientFunds();

    error NotManager();

    error AddressZero();

    error AlreadyInitialized();

    error AlreadyRegistered();

    error NotApproved();

    error salaryAmountError();

    constructor(address _companyManager,USDCInterface _contractAddr) {
        companyManager = _companyManager;
        usdcContractAddress = _contractAddr;
    }

     ///////////////FUNCTIONS///////////////


    // /// @dev initialise function serves as the contract constructor
    // function initialise(address _companyManager, bytes32 _rootHash) external{
    //     if(intialState == true){
    //         revert AlreadyInitialized();
    //     }
    //     companyManager = _companyManager;
    //     intialState = true;
    //     rootHash = _rootHash; 
    // }

    /// @notice function for employee to register on the platform
    function registerInfo(string memory _name, address _employeeAddress, string memory _post, EmployeeLevel _level) external returns(string memory){
        if(_employeeAddress == address(0)){
            revert AddressZero();
        }
        EmployeeInfo storage EI = info[_employeeAddress];
        if(EI.registered == true){
            revert AlreadyRegistered();
        }
        EI.name = _name;
        EI.employeeAddress = _employeeAddress;
        EI.post = _post;
        EI.level = _level; //0  1  2
        EI.timeFilled = block.timestamp;
        EI.registered = true;
        totalRegisteredEmploye = totalRegisteredEmploye + 1;
        EmployeeAddress.push(_employeeAddress);

        emit Registered(_employeeAddress, block.timestamp);
        return "Registration successful, Reviewing....";
    }

    /// @notice function for employee to see thier registration status
    function showMyRegistrationStatus(address _employeeAddress) external view returns(string memory){
        EmployeeInfo storage EI = info[_employeeAddress];
        if(msg.sender != _employeeAddress || msg.sender != companyManager){
            return("you don't have access to this, contact admin");
        }
        require(EI.registered == true, "You need to Register");
        if(EI.pendingReview == true){
            return ("Your registration is under review, check back in two days");
        }else if(EI.approved == true){
            return ("Congratulation, Your Registration is approved");
        }else{
            return ("Error with Registration, Contact Admin");
        }
    }


    // review employee registration
    function reviewInProgress(address _employeeAddress) external {
        if(msg.sender != companyManager){
            revert NotManager();
        }

        EmployeeInfo storage EI = info[_employeeAddress];
        //check
        EI.pendingReview = true;
        EI.timeOfPendingReview = block.timestamp;
    }

    // employee registration approval
    function reviewApproved(address _employeeAddress) external returns(address[] memory){
        if(msg.sender != companyManager){
            revert NotManager();
        }
        //check to see if the person is registered
        EmployeeInfo storage EI = info[_employeeAddress];
        //check
        EI.approved = true;
        EI.pendingReview = false;
        EI.timeOfApproval = block.timestamp;
        employeeCount = employeeCount + 1;
        approvedEmployeeAddress.push(_employeeAddress);
    }


    /// this button/function is only displayed during the checkin time of the organisation
    /// between 8 - 9am
    // function checkIn(address _employeeAddress) external{
    //     EmployeeInfo storage EI = info[_employeeAddress];
    //     require(EI.timeIN + block)
    //     uint timeIN = block.timestamp;
    //     El.checkIn 
    // }

    // employee fill salary invoice after salary has b
    function fillSalaryInvoice(string memory _name, string memory _post, EmployeeLevel _level, uint256 amount, string memory _description, uint256 rate) external returns(string memory) {
        EmployeeInfo memory EI = info[msg.sender];
        require(EI.registered == true, "You are not a member of this organisation, kindly register");
        if( EI.approved == false ){
            revert NotVerified();
        }
        uint timeStarted = EI.timeOfApproval ;
        uint payDay = timeStarted + block.timestamp;

         if(payDay < numberofDays){
            revert TimeNotReached();
        }

        SalaryInvoice storage invoice = _salaryInvoice[msg.sender];
        require(invoice.set == true, "salary not set, contact admin");
        if(invoice.amountTobepaid < amount){
            revert salaryAmountError();
        }
        invoice.name = _name;
        invoice.employeeAddress = msg.sender;
        invoice.post = _post;
        invoice.level = _level; //0  1  2
        invoice.description = _description;

        return "Salary Invoice filled Successfully";

    }

    // review user salary invoice by the manager
    function reviewSalaryInvoice(address _employeeAddress) external {
         if (msg.sender != companyManager) {
            revert NotManager();
        } 
         SalaryInvoice storage invoice = _salaryInvoice[_employeeAddress];
         require(invoice.amountTobepaid != 0, "error, salary is yet to be set");
        //approves if all information entered by the employee is valid
        invoice.approved = true;

    }

    /// @dev A function set the employee salary by the admin
    /// @param _employeeAddress: the address of the employee
    /// @param amount: amount to be given to the employer as salary
    /// @notice _rate will be used for the v2 of the app
    /// @param _rate: the rate
    /// @param extrafee: Tip for the month
    function setEmployeeSalary(address _employeeAddress, uint256 amount, uint256 _rate, uint256 extrafee) external {
         if (msg.sender != companyManager) {
            revert NotManager();
        } 
        //only approved employees
         EmployeeInfo memory EI = info[_employeeAddress];
        if( EI.approved == false ){
            revert NotApproved();
        }
        SalaryInvoice storage invoice = _salaryInvoice[_employeeAddress];
        if(extrafee != 0){
            invoice.amountTobepaid = amount + extrafee;
        }else{
            invoice.amountTobepaid = amount;
        }
        
        invoice.time = block.timestamp;
        invoice.ratePerDay = _rate;
        invoice.extraWorkFee = extrafee;
        invoice.set = true;
    }

    ///@dev function changes the former companymanager, only callable by the previous manager
    /// @param _companyManager: the new manager address
      function changeCompanyManager(address _companyManager) external{
        if (msg.sender != companyManager) {
            revert NotManager();
        } 
        address oldCompanyManager = companyManager;
        companyManager = _companyManager;

        emit ManagerUpdated(oldCompanyManager, companyManager, block.timestamp);
    }


    function withdraw(address _employeeAddress) external {
        EmployeeInfo memory EI = info[msg.sender];
        require(EI.registered == true, "You are not a member of this organisation, kindly register");

        require(USDCInterface(usdcContractAddress).balanceOf(address(this)) > 0, "Contract Not funded");
        SalaryInvoice storage invoice = _salaryInvoice[_employeeAddress];
        require(invoice.approved == true, "Salary invoice yet to be approved, contact admin");
        invoice.approved = false;
        uint amount = invoice.amountTobepaid;
        invoice.amountTobepaid = 0;
        EI.timeOfApproval = 0;

        USDCInterface(usdcContractAddress).transfer(_employeeAddress, amount);
        emit Withdrawal(_employeeAddress, amount);
    }

    /// @notice function returns the level of an employee
    function getEmployeeStatus(address _employeeAddress) external view returns(EmployeeLevel){
        EmployeeInfo memory EI = info[_employeeAddress];
        if( EI.approved == false ){
            revert NotVerified();
        }
        return EI.level;
    }

    /* @dev Gets the total number of employees registered in the payroll */
    function getEmployeeCount() external view returns(uint){
        return employeeCount;
    }     

   /// @dev function to get an employee details
    function getEmployeeDetails(address _employeeAddress) external view returns(EmployeeInfo memory EI){
        return info[_employeeAddress];
    }

    function getTotalRegisteredEmployee() external view returns(uint256){

    }
    
   /// @notice function to deposit USDC tokens
   /// @param amount represent amount of tokens to be deposited
    function deposit(uint256 amount) external{
        if(amount <= 0){
            revert ZeroAmount();
        }
        bool success = usdcContractAddress.transferFrom(msg.sender, address(this), amount);
        require(success, "Not successful");
        tokenBalance += amount;

        emit Deposit(msg.sender, amount);
    }

    //function to withdraw
    function withdrawContractBal(address to, uint amount) public payable {
         if (msg.sender != companyManager) {
            revert NotManager();
            }
        if(address(this).balance < amount){
            revert InsufficientFunds();
        } else{
            uint256 amountTosend = address(this).balance - amount;
            payable(to).transfer(amountTosend);
        }
    }

    receive() external payable{}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
interface USDCInterface {
   
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

   
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}