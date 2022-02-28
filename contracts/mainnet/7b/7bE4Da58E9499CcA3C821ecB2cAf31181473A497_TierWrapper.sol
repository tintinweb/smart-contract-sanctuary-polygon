/**
 *Submitted for verification at polygonscan.com on 2022-02-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

contract TierWrapper {

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint64 MAX_BLOCK_NUMBER = 4294967295;

    address public _tierContractAddress;

    constructor (address trierContractAddress){
        _tierContractAddress = trierContractAddress;
    }
    
    function tiers() external view returns (uint256[8] memory tierValues_){
        ITier tierContract = ITier(_tierContractAddress);
        return tierContract.tierValues();
    }

    function getTierReport(address account) external view returns (uint256){
        ITier tierContract = ITier(_tierContractAddress);
        return tierContract.report(account);
    }

    function getTierIndexAndReport(address account) internal view returns (uint, uint64[8] memory) {
        ITier tierContract = ITier(_tierContractAddress);
        uint256 report = tierContract.report(account);

        uint tiersLength = 8;
        uint64[8] memory parsedReport;
        uint64 currentTierBlock = 0;
        uint memberTierIndex = 0;
        string memory reportStr = toHexString(report);

        for (uint i = 0; i < tiersLength; i++) {
            parsedReport[i] = hexStringToInt64(substring(reportStr, i * 8 + 2, i * 8 + 10));

            if(parsedReport[i] > currentTierBlock && parsedReport[i] < MAX_BLOCK_NUMBER){
                currentTierBlock = parsedReport[i];
                memberTierIndex = (tiersLength - 1 - i);
            }
        }

        return (memberTierIndex, parsedReport);
    }

    function balanceOf(address account) external view returns (uint256) {
  
        uint64[8] memory parsedReport;
        uint memberTierIndex = 0;
        
        (memberTierIndex, parsedReport) = getTierIndexAndReport(account);

        ITier tierContract = ITier(_tierContractAddress);
        uint256[8] memory tierValues_ = tierContract.tierValues();

        return tierValues_[memberTierIndex];
    }

    function getTier(address account) external view returns (uint) {
  
        uint64[8] memory parsedReport;
        uint memberTierIndex = 0;
        
        (memberTierIndex, parsedReport) = getTierIndexAndReport(account);

        return memberTierIndex;
    }

    function getTierHistory(address account) external view returns (uint64[8] memory) { 
        uint64[8] memory parsedReport;
        uint memberTierIndex = 0;
        
        (memberTierIndex, parsedReport) = getTierIndexAndReport(account);

        return parsedReport;
    }
    
    function substring(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
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

    function hexBytesToInt(bytes memory ss) internal pure returns (uint64){
        uint64 val = 0;
        uint8 a = uint8(97); // a
        uint8 zero = uint8(48); //0
        uint8 nine = uint8(57); //9
        uint8 A = uint8(65); //A
        uint8 F = uint8(70); //F
        uint8 f = uint8(102); //f
        for (uint i=0; i<ss.length; ++i) {
            uint8 byt = uint8(ss[i]);
            if (byt >= zero && byt <= nine) byt = byt - zero;
            else if (byt >= a && byt <= f) byt = byt - a + 10;
            else if (byt >= A && byt <= F) byt = byt - A + 10;
            val = (val << 4) | (byt & 0xF);
        }
        return val;
    }

    function hexStringToInt64(string memory s) internal pure returns (uint64) {
        bytes memory ss = bytes(s);
        uint64 val = hexBytesToInt(ss);
        return val;
    }
}

interface ITier {
    /// @param account Account to get the report for.
    /// @return The report blocks encoded as a uint256.
    function report(address account) external view returns (uint256) ;
    function tierValues() external view returns (uint256[8] memory tierValues_);
}