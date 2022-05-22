/**
 *Submitted for verification at polygonscan.com on 2022-05-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract MarksheetManager is Ownable {


    mapping(address => bool) private allowedTeachers;
    mapping(string => mapping(string => string)) private marksheets;
    mapping(string => mapping(string => bool)) private paid;

    event Marksheet(string);

    modifier onlyTeacher() {
        require(allowedTeachers[_msgSender()] == true, "MarksheetManager: This address is not registered as a teacher");
        _;
    }

    function registerTeacher(address _newTeacher) public onlyOwner returns(bool)
    {
        require(_newTeacher != address(0), "MarksheetManager: Invalid address");
        allowedTeachers[_newTeacher] = true;
        return true;
    }

    function removeTeacher(address _teacher) public onlyOwner returns(bool)
    {
        require(_teacher != address(0), "MarksheetManager: Invalid address");
        require(allowedTeachers[_teacher] == true, "MarksheetManager: This teacher is not regsitered yet");
        allowedTeachers[_teacher] = false;
        return true;
    }


    function uploadMarksheet(string[] memory _rollNumbers, string[] memory _marksheetLink, string memory _class) public 
    {
        require(_rollNumbers.length > 0 && _marksheetLink.length > 0, "MarksheetManager: Empty data sent");
        require(_rollNumbers.length == _marksheetLink.length, "MarksheetManager: Length doesn't match");

        for (uint i=0; i<_rollNumbers.length; i++)
        {
            marksheets[_class][_rollNumbers[i]] = _marksheetLink[i];
            
        }
    }

    function getMarksheet(string memory _class, string memory _rollNumber) public payable {
        require(msg.value == 0.0001 ether, "MarksheetManager: Less amount sent");
        // require()

        // paid[_class][_rollNumber] = true;

        emit Marksheet(marksheets[_class][_rollNumber]);
    }

    function getRevenue(address payable _address) public onlyOwner{
        payable(_address).transfer(address(this).balance);
    }

    // function marksheet(string memory _class, string memory _rollNumber) public  returns(string memory)
    // {
    //     require(paid[_class][_rollNumber] == true, "MarksheetManager: Please pay for marksheet first");
    //     paid[_class][_rollNumber] = false;
    //     return marksheets[_class][_rollNumber];
    // }
}