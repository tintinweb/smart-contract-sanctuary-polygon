/**
 *Submitted for verification at polygonscan.com on 2022-09-20
*/

// File: contracts-launchpad/AffiliateRewardSystem.sol

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

contract AffiliateRewardSystem
{ 
    mapping(string => address) private _codeOwners;
    mapping(address => string) private _promoCodes;


    //-------------------------PUBLIC FUNTIONS --------------------

    function createAffiliateCode() external
    {
        //  require(tx.origin == tx.origin, "Only EOA");
         require(bytes(_promoCodes[tx.origin]).length == 0, "You already created an affiliate code");
        string memory code;
        string memory _code;
        for(uint i=0;i<15;i++){
            _code = getBytesSlice(3, 8 + i, toString(tx.origin) ); 
            if(_codeOwners[_code] == address(0)) { 
                code = _code;
                i = 15;
            }
        }
        _codeOwners[code] = tx.origin;   
        _promoCodes[tx.origin] = code;    
    }

    function getAffiliateCode() external view returns (string memory) {
        //  require(tx.origin == tx.origin, "Only EOA");
        string memory code = _promoCodes[tx.origin];
         require(_codeOwners[code] != address(0), "You have not created an affiliate code yet");
         require(_codeOwners[code] == tx.origin, "You are not owner of this affiliate code");
        return code;     
    }

    function getAffiliatePayableAddress(string memory inputCode) external view returns (address affiliate)
    {
         require(_codeOwners[inputCode] != address(0), "Affiliate code does not exist");
        return _codeOwners[inputCode]; 
    }

    function getAffiliateCodeForAddr(address affiliateAddr) public view returns (string memory) 
    {
        string memory code = _promoCodes[affiliateAddr];
         require(_codeOwners[code] != address(0), "You have not created an affiliate code yet");
         require(_codeOwners[code] == affiliateAddr, "Issue: address is not owner of its affiliate code");
        return code; 
    }




    //-------------------------PRIVATE FUNTIONS--------------------

    function getBytesSlice(uint256 begin, uint256 end, string memory text) private pure returns (string memory) {
        bytes memory a = new bytes(end-begin+1);
        for(uint i=0;i<=end-begin;i++){
            a[i] = bytes(text)[i+begin-1];
        }
        return string(a);  //return a;
    }
    function toString(address account) private pure returns(string memory) { return toString(abi.encodePacked(account)); }
    function toString(uint256 value) private pure returns(string memory) { return toString(abi.encodePacked(value)); }
    function toString(bytes32 value) private pure returns(string memory) { return toString(abi.encodePacked(value)); }
    function toString(bytes memory data) private pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(data.length * 2); // bytes memory str = new bytes(2 + data.length * 2); str[0] = "0"; str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[i*2] = alphabet[uint(uint8(data[i] >> 4))]; //str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[1+i*2] = alphabet[uint(uint8(data[i] & 0x0f))]; //str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

}