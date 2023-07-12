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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;
import "./PriceConverter.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// errors
error NotOwner();
error NotEmployee();
error NotCollaborators();

contract Company {
    using PriceConverter for uint256;

    struct EmployeeData {
        uint256 salary;
        uint256 lockedBalance;
        uint joinDate;
        uint lastWithdrawal;
    }

    address public _CompanyAddress;
    address public _CompanyOwner;
    string public _CompanyIdentifier;
    uint256 public _CompanyBalance = 0;
    address public _CaliToken = 0xe42A18Fd805a41BD27cA465Cf4240E5A0db7BDD4;
    
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
        revert("Please use the deposit method.");
    }

     function deposit(address token, uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");

        // Check if the token is allowed
        require(token == _CaliToken, "Invalid token");

        _CompanyBalance += amount;
        emit DepositReceived(_CompanyAddress, msg.sender, amount);
    }


    // Add new Employee to the company.
    function addEmployee(address _employeeAddress ,uint256 _salary) public onlyOwner {
        _employees[_employeeAddress].salary = _salary;
        _employees[_employeeAddress].lockedBalance = 0;
        _employees[_employeeAddress].joinDate = block.timestamp;
        _employees[_employeeAddress].lastWithdrawal = block.timestamp;
        emit EmployeeAdded(_CompanyAddress, _employeeAddress, _salary);
    }

    function withdrawToken() public onlyCollaborators {
    uint256 amount = calculateAllowedWithdrawal(msg.sender);

    require(_CompanyBalance >= amount, "Insufficient contract balance");

    // Call the employee's address with the specified amount in WEI (Transfer / Withdraw).
    IERC20 tokenContract = IERC20(_CaliToken);
    tokenContract.transfer(msg.sender, amount);

    _CompanyBalance = _CompanyBalance - amount;

    uint256 employeeSalary = _employees[msg.sender].salary;
    _employees[msg.sender].lastWithdrawal = block.timestamp;
    emit EmployeeWithdrawal(_CompanyAddress, msg.sender, employeeSalary, amount);
}


    // Calculate how mutch the employee can withdraw.
    function calculateAllowedWithdrawal(address _employeeAddress) private view returns (uint256)  {
        uint256 annualSalary = _employees[_employeeAddress].salary * 12;
        uint256 secondsInAYear = 3156 * 10e4;
        uint256 secondPrice = annualSalary * 1e18 / secondsInAYear;

       return ((block.timestamp * 1000 - _employees[_employeeAddress].lastWithdrawal  * 1000) * secondPrice) / 1e18;
    }

    // // Calculate how mutch the employee can withdraw.
    // function calculateAllowedWithdrawalDolar(address _employeeAddress) private view returns (uint256)  {
    //     uint256 annualSalary = _employees[_employeeAddress].salary * 12;
    //     uint256 secondsInAYear = 3156 * 10e4;
    //     uint256 secondPrice = annualSalary * 1e18 / secondsInAYear;

    //     return ((block.timestamp  * 1000 - _employees[_employeeAddress].lastWithdrawal * 1000) * secondPrice) / 1e18;
    // }

    function getSingleBalance(address _employeeAddress) public view returns (uint256) {
        return calculateAllowedWithdrawal(_employeeAddress);
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
        uint256 allowedWithdraw = getSingleBalance(_employeeAddress);
        _employees[_employeeAddress].lockedBalance = allowedWithdraw;
        _employees[_employeeAddress].salary = _newSalary;
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
pragma solidity 0.8.8;

import "./Company.sol";

contract CompanyFactory {
    string public name = "CompanyFactory";
    Company[] public companyContracts;
    address public _OwnerAddress;

     modifier onlyFactoryOwner {
        if (msg.sender != _OwnerAddress) revert NotOwner();
        _;
    }

      constructor(){
        _OwnerAddress = msg.sender;
    }


    event CompanyCreated(address _companyAddress, string _companyIdentifier);

    function createNewCompany(string memory _companyIdentifier) public returns(address) {
        Company newCompany = new Company(msg.sender, _companyIdentifier);
        companyContracts.push(newCompany);

        emit CompanyCreated(address(newCompany), _companyIdentifier);

        return address(newCompany);
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