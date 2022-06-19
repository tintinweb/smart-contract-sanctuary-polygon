/**
 *Submitted for verification at polygonscan.com on 2022-06-19
*/

// SPDX-License-Identifier: GPL-3.0

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File: contracts/test1906.sol



// File: contracts/rate0304.sol

pragma solidity >=0.7.0 <0.9.0;

contract test{

	uint amount = 0;
	
	struct InfoUsers{
		string sex;       // male or female
		string birthDate; //DD.MM.YEAR
		string lastName;
		uint256 balance;
	}

	struct InfoRecords{
		address sender;
		uint256 time;
	}

	mapping(uint => InfoUsers) Users;
	mapping(uint => InfoRecords) Records;
 
	function SaveRecord(string memory _sex, string memory _birthDate, string memory _lastName) public returns (uint){
		uint id = amount + 1;
		Users[id].sex = _sex;
		Users[id].birthDate = _birthDate;  
		Users[id].lastName = _lastName;
		Users[id].balance = 0;
		Records[id].sender = msg.sender;
		Records[id].time = block.timestamp;
		return id;  
 	} 

	function ShowRecord(uint _id) public view returns (string memory){
		string memory greeting;
		string memory gender = Users[_id].sex;
		if(compareStrings(gender,"male")){
			greeting = "Mr "; 
		}
		else{
			greeting = "Mrs ";
		}
		string memory lastName = Users[_id].lastName;
		string memory birthDate = Users[_id].birthDate;
		string memory balance = Strings.toString(Users[_id].balance);
		string memory sender = Strings.toHexString(uint256(uint160(Records[_id].sender)), 20);
		string memory age = Strings.toString(getCurrentYear(block.timestamp)- getYear(birthDate));
		string memory sumDays = Strings.toString(getDay(block.timestamp) - getDay(Records[_id].time));
		string memory result = string(abi.encodePacked(greeting, ' ', lastName,'. Age: ', age,'. Balance: ', balance, '. Days: ', sumDays, '. Sender: ', sender));
		return result;
	} 

	function UpdateBalance(uint _id, uint _amount) public returns (uint){
		Users[_id].balance += _amount;
		return Users[_id].balance;
	}
	
	function getCurrentYear(uint _timestamp) internal pure returns (uint) {
        return _timestamp/(365 * 24 * 60 * 60) + 1970;
    }

	function getDay(uint _timestamp) internal pure returns (uint) {
        return _timestamp/(24 * 60 * 60);
    }

	
	function getYear(string memory a) internal pure returns (uint) {
		string memory result = string(abi.encodePacked(getSlice(6, 10, a)));
		return st2num(result);
	}

	function getSlice(uint startIndex, uint endIndex, string memory str) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }

	function st2num(string memory numString) internal pure returns(uint) {
        uint  val = 0;
        bytes   memory stringBytes = bytes(numString);
        for (uint  i =  0; i < stringBytes.length; i++) {
            uint exp = stringBytes.length - i;
            bytes1 ival = stringBytes[i];
            uint8 uval = uint8(ival);
           	uint jval = uval - uint(0x30);
        	val +=  (uint(jval) * (10**(exp-1))); 
        }
    	return val;
    }


	function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

}