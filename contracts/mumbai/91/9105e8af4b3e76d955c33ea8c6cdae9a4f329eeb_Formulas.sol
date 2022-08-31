/**
 *Submitted for verification at polygonscan.com on 2022-08-31
*/

// SPDX-License-Identifier: MIT
// Specifies that the source code is for a version
// of Solidity greater than 0.8.16
pragma solidity ^0.8.16;
// A contract is a collection of functions and data (its state)
// that resides at a specific address on the Ethereum blockchain.
contract Formulas {
    
    struct AvailableFormula {
        string myFormula;
    }

    uint private _formulaID = 0;
    mapping(uint => AvailableFormula) private _availableFormulas;

    function pushFormula(string memory input) public {
        AvailableFormula memory availableFormulas = AvailableFormula(
            input
        );

        _availableFormulas[_formulaID] = availableFormulas;
        _formulaID ++;
    }
    function getFormula() public view returns (uint, AvailableFormula[] memory) {
        AvailableFormula[]    memory id = new AvailableFormula[](_formulaID);
        for (uint i = 0; i < _formulaID; i++) {
            AvailableFormula storage formulas = _availableFormulas[i];
            id[i] = formulas;
        }
       return (_formulaID, id);
    }

    // Math functions
    function add(int a, int b) public pure returns (int)
    {
        int Sum = a + b ;
         
        // Sum of two variables
        return Sum;
    }
    function sub(int a, int b) public pure returns (int)
    {
        int res = a - b ;
         
        // Sum of two variables
        return res;
    }
    function mul(int a, int b) public pure returns (int)
    {
        int res = a * b ;
         
        // Sum of two variables
        return res;
    }
    function div(int a, int b) public pure returns (int)
    {
        int res = a / b ;
         
        // Sum of two variables
        return res;
    }
    function pow(int a, uint b) public pure returns (int)
    {
        int res = a ** b ;
         
        // Sum of two variables
        return res;
    }

    // Text functions
    function len(string memory s) public pure returns (uint)
    {
         return bytes(s).length;
    }
    function toUpper(string memory str) public pure returns (string memory) {
		bytes memory bStr = bytes(str);
		bytes memory bUpper = new bytes(bStr.length);
		for (uint i = 0; i < bStr.length; i++) {
			// Uppercase character...
			if ((uint8(bStr[i]) >= 97) && (uint8(bStr[i]) <= 122)) {
				// So we add 32 to make it lowercase
				bUpper[i] = bytes1(uint8(bStr[i]) - 32);
			} else {
				bUpper[i] = bStr[i];
			}
		}
		return string(bUpper);
	}

    // Statistics functions
    function avg(int a, int b) public pure returns (int)
    {
         return (a + b) / 2;
    }
    function max(int a, int b) public pure returns (int)
    {
         return a > b ? a : b;
    }
    function min(int a, int b) public pure returns (int)
    {
         return a < b ? a : b;
    }


}