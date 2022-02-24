/**
 *Submitted for verification at polygonscan.com on 2022-02-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

//import { ethers } from "ethers";

contract TierWrapper {

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    address public _tierContractAddress; //0x4e2c8E95008645651dd4dA64E2f998f99f06a1Ed

    constructor (address trierContractAddress){
        _tierContractAddress = trierContractAddress;
    }
    function getTierReport(address account) external view returns (uint256){
        ITier tierContract = ITier(_tierContractAddress);

        //TierContractInterface tierContract = TierContractInterface(_tierContractAddress)
        return tierContract.report(account);
    }

    function getTierHistory(address account) external view returns (string[8] memory) { //} (uint256){
        ITier tierContract = ITier(_tierContractAddress);

        //TierContractInterface tierContract = TierContractInterface(_tierContractAddress)
        uint256 report = tierContract.report(account);

        //uint256[8] memory parsedReport;
        uint totalLength = 8;
        string[8] memory arrStatus;
        string memory reportStr = toHexString(report); // toString(report);

        //uint[] memory arrStatus = new uint[](8);
       
        //arrStatus = [0, 1, 2, 3, 4, 5, 6, 7];

        for (uint i = 0; i < totalLength; i++) {

            arrStatus[totalLength - i] = substring(reportStr, i * 8 + 2, i * 8 + 10);

            //parsedReport[i] = (uint("0x" + reportStr));
        }

        //arrStatus = arrStatus.reverse();
        /*
        for (uint i = 0; i < arrStatus.length; i++) {
            parsedReport.push(uint("0x" + arrStatus[i]));
            //parsedReport.push(arrStatus[i]);
        }
        */

        return arrStatus;
    }
    
    function substring(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }

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
        
    function tiers() external view returns (uint256[8] memory tierValues_){
        ITier tierContract = ITier(_tierContractAddress);

        return tierContract.tierValues();
    }
}
interface ITier {
    /// @param account Account to get the report for.
    /// @return The report blocks encoded as a uint256.
    function report(address account) external view returns (uint256) ;
    function tierValues() external view returns (uint256[8] memory tierValues_);
}