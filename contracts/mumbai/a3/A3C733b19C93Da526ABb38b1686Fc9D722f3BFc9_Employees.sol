/**
 *Submitted for verification at polygonscan.com on 2023-04-05
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IParent{

	function GetContractAddress(string calldata _name) external view returns(address);
    function Owner() external view returns(address);
}

interface IOracle{

    function GetMATICPrice() external view returns(uint256);
    function GetMATICDecimals() external view returns(uint8, bool);
}

interface IClerk{
    
    function EmployeesWithdraw(address _employee, uint256 _amount) external returns(bool);
}

contract Employees{

//-----------------------------------------------------------------------// v EVENTS

    event Payout(address indexed employee, uint256 _amount);
    //
    event EmployeeAddition(address indexed employee, uint256 dailyWage);
    event EmployeeUpdate(address indexed employee, uint256 dailyWage);
    event EmployeeRemoval(address indexed employee);

//-----------------------------------------------------------------------// v INTERFACES

    IParent constant private pt = IParent(parentAddress);

//-----------------------------------------------------------------------// v BOOLEANS

    bool private reentrantLocked = false;

//-----------------------------------------------------------------------// v ADDRESSES

    address constant private parentAddress = 0x70C01604d020dBE3ec7aA77BAc1f2c8A8386598D;

//-----------------------------------------------------------------------// v NUMBERS

//-----------------------------------------------------------------------// v BYTES

//-----------------------------------------------------------------------// v STRINGS

    string constant public Name = ".Corporation.Employees";

//-----------------------------------------------------------------------// v STRUCTS

    struct Employee{

        bool isEmployee;
        uint16 dailyWage;
        uint32 lastPayout;
        uint32 releasedAt; 
    }

//-----------------------------------------------------------------------// v ENUMS

//-----------------------------------------------------------------------// v MAPPINGS

    mapping(address => Employee) private employees;

//-----------------------------------------------------------------------// v MODIFIERS

    modifier ownerOnly{

        if(pt.Owner() != msg.sender)
            revert("Owner only");

        _;
    }

//-----------------------------------------------------------------------// v CONSTRUCTOR

//-----------------------------------------------------------------------// v PRIVATE FUNCTIONS

//-----------------------------------------------------------------------// v GET FUNCTIONS

    function GetEmployeeProfile(address _employee) public view returns(uint16 dailyWage, uint32 lastPayout, uint32 daysUnpaid, bool isEmployee){

        Employee memory employee = employees[_employee];

        dailyWage = employee.dailyWage;
        daysUnpaid = (uint32(block.timestamp) - employees[_employee].lastPayout) / (1 days);
        lastPayout = employee.lastPayout;
        isEmployee = employee.isEmployee;
    }

//-----------------------------------------------------------------------// v SET FUNTIONS

    function Payoff() public returns(bool){

        if(reentrantLocked == true)
            revert("Reentrance failed");

        reentrantLocked = true;

        address oracleAddress = pt.GetContractAddress(".Corporation.Oracle");
        IOracle oc = IOracle(oracleAddress);

        address clerkAddress = pt.GetContractAddress(".Corporation.Clerk");
        IClerk cl = IClerk(clerkAddress);

        Employee storage employee = employees[msg.sender];
        
        if(employee.lastPayout == 0)
            revert("Employee only");

        (uint8 decimals, bool success) = oc.GetMATICDecimals();

        if(success != true)
            revert("Oracle unreachable");

        uint256 price = oc.GetMATICPrice();

        if(price <= 0)
            revert("Unaccepted Oracle price");

        uint32 payUntil = (employee.isEmployee == true) ? uint32(block.timestamp) : employee.releasedAt;

        uint32 unpaidDays = uint32((payUntil - employee.lastPayout) / (1 days));
        uint32 moduloDays = uint32((payUntil - employee.lastPayout) % (1 days));
        uint256 amount = uint256(unpaidDays * employee.dailyWage * 10**(decimals + 18) / (price * 100));

        if(amount == 0)
            revert("Already paid");

        if(employee.isEmployee == true)
            employee.lastPayout = payUntil - moduloDays;
        else{

            delete employee.lastPayout;
            delete employee.dailyWage;
            delete employee.releasedAt;
        }

        try cl.EmployeesWithdraw(msg.sender, amount){}
        catch{ revert("Payoff failed"); }

        reentrantLocked = false;

        emit Payout(msg.sender, amount);
        return(true);
    }
    //
    function AddEmployee(address _employee, uint16 _dailyWage) public ownerOnly returns(bool){

        Employee storage employee = employees[_employee];

        if(employee.isEmployee == true)
            revert("Already employeed");

        if(employee.releasedAt > 0)
            revert("Payoff pending");

        uint32 size;
        assembly{size := extcodesize(_employee)}

        if(size != 0)
            revert("Employee is contract");

        if(_dailyWage == 0)
            revert("Zero wage");

        employee.dailyWage = _dailyWage;
        employee.lastPayout = uint32(block.timestamp);
        employee.isEmployee = true;

        emit EmployeeAddition(_employee,  _dailyWage);
        return(true);
    }

    function UpdateEmployee(address _employee, uint16 _dailyWage) public ownerOnly returns(bool){

        Employee storage employee = employees[_employee];

        if(employee.isEmployee != true)
            revert("Not an employee");

        if(_dailyWage == 0)
            revert("Zero wage");

        employee.dailyWage = _dailyWage;

        emit EmployeeUpdate(_employee, _dailyWage);
        return(true);
    }

    function RemoveEmployee(address _employee) public ownerOnly returns(bool){

        Employee storage employee = employees[_employee];

        if(employee.isEmployee != true)
            revert("Not an employee");

        employee.isEmployee = false;
        employee.releasedAt = uint32(block.timestamp);

        emit EmployeeRemoval( _employee);
        return(true);
    }

//-----------------------------------------------------------------------// v DEFAULTS

    receive() external payable{}
    fallback() external{}
}