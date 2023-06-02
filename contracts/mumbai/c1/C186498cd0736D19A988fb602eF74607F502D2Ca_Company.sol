// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;
import "./PriceConverter.sol";

// errors
error NotOwner();
error NotEmployee();
error NotCollaborators();

contract Company {
    using PriceConverter for uint256;

    struct EmployeeData {
        uint256 salary;
        uint256 balance;
        uint joinDate;
        uint lastWithdrawal;
    }

    address public _CompanyAddress;
    address public _CompanyOwner;
    string public _CompanyIdentifier;
    uint256 public _CompanyBalance = 0;
    uint256 public _SandardTokenPrice = 0;
    
    mapping(address => EmployeeData) public _employees;


    // events
    event CompanyCreated(address companyAddress, string companyIdentifier, address ownerAddress);
    event EmployeeAdded(address companyAddress, address employeeAddress, uint256 employeeSalary);
    event EmployeeSalaryUpdated(address companyAddress, address employeeAddress, uint256 newSalary);
    event EmployeeWithdrawal(address companyAddress, address employeeAddress, uint256 employeeSalary, uint256 withdrawalAmount);
    event DepositReceived(address companyAddress, address depositAddress, uint256 depositAmount);


    // This will have "onlyCaliFactory" modifier
    constructor(address _ownerAddress, string memory _companyIdentifier){
        _CompanyOwner = _ownerAddress;
        _CompanyIdentifier = _companyIdentifier;
        _CompanyAddress = address(this);
        emit CompanyCreated(_CompanyAddress, _companyIdentifier, _CompanyOwner);
    }

    // Deposit method.
    receive() payable external {
        _CompanyBalance += msg.value;
        emit DepositReceived(_CompanyAddress, msg.sender, msg.value);
    }


    // Add new Employee to the company.
    function addEmployee(address _employeeAddress ,uint256 _salary) public onlyOwner {
        _employees[_employeeAddress].salary = _salary;
        _employees[_employeeAddress].balance = 0;
        _employees[_employeeAddress].joinDate = block.timestamp;
        _employees[_employeeAddress].lastWithdrawal = block.timestamp;
        emit EmployeeAdded(_CompanyAddress, _employeeAddress, _salary);
    }

    function withdrawToken() public onlyCollaborators  {
      uint256 amount = getSingleBalance(msg.sender);
        _SandardTokenPrice = PriceConverter.getStandardTokenPrice();
        _CompanyBalance = _CompanyBalance - amount; 

        // Call the employee's address with the specified amount in WEI (Transer / Withdraw).
        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdraw Failed");

        uint256 employeeSalary = _employees[msg.sender].salary;
        emit EmployeeWithdrawal(_CompanyAddress, msg.sender, employeeSalary, amount);
    }

    // Calculate how mutch the employee can withdraw.
    function calculateAllowedWithdrawal(address _employeeAddress) private view returns (uint256)  {
        uint256 annualSalary = _employees[_employeeAddress].salary * 12;
        uint256 secondsInAYear = 3156 * 10e4;
        uint256 secondPrice = annualSalary * 1e18 / secondsInAYear;

        uint256 amountPrice = ((block.timestamp * 1000 - _employees[_employeeAddress].lastWithdrawal  * 1000) * secondPrice) / 1e18;
        return amountPrice.getDolarInWei();
    }

    // Calculate how mutch the employee can withdraw.
    function calculateAllowedWithdrawalDolar(address _employeeAddress) private view returns (uint256)  {
        uint256 annualSalary = _employees[_employeeAddress].salary * 12;
        uint256 secondsInAYear = 3156 * 10e4;
        uint256 secondPrice = annualSalary * 1e18 / secondsInAYear;

        uint256 amountPrice = ((block.timestamp  * 1000 - _employees[_employeeAddress].lastWithdrawal * 1000) * secondPrice) / 1e18;
        return amountPrice;
    }

    function getSingleBalance(address _employeeAddress) public view returns (uint256) {
        return calculateAllowedWithdrawalDolar(_employeeAddress);
    }

     function getBulkBalance(address[] memory _employeeAddresses) public view returns (uint256[] memory) {
        uint256[] memory employeeBalances = new uint256[](_employeeAddresses.length);
        for (uint256 i = 0; i < _employeeAddresses.length; i++){
            employeeBalances[i] = getSingleBalance(_employeeAddresses[i]);
        }
        return employeeBalances;
    }

    // Update the Employee salary.
    function updateEmployeeSalary(address _employeeAddress ,uint256 _newSalary) public onlyOwner {
        _employees[_employeeAddress].salary = _newSalary;
        _employees[_employeeAddress].balance = 0;
        emit EmployeeSalaryUpdated(_CompanyAddress, _employeeAddress, _newSalary);
    }


    // Modifier -> Only contract owner can dispatch the function.
    modifier onlyOwner {
        if (msg.sender != _CompanyOwner) revert NotOwner();
        _;
    }

    // Modifier -> Only employeers can dispatch the function.
    modifier onlyCollaborators {
        if (msg.sender != _CompanyOwner || _employees[msg.sender].salary < 0) revert NotCollaborators();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice() internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada);
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer);
    }

    function getConversionRate(uint256 tokenAmount) internal view returns (uint256) {
        uint256 ethPrice = getPrice();
        return (ethPrice * tokenAmount) / 1e18;
    }

    function getDolarInWei(uint256 dollars) internal view returns (uint256) {
        uint256 ethPrice = getPrice();
        return (dollars * 1e18) / ethPrice;
    }

    function getStandardTokenPrice() internal view returns (uint256) {
        return getPrice();
    }
}