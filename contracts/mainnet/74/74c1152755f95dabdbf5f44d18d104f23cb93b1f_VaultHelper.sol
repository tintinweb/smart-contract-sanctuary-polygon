/**
 *Submitted for verification at polygonscan.com on 2022-06-26
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.14;


contract VaultHelper {


    function checkIfContracts(address[]memory _addresses) external view returns (bytes memory contractArray) {
        uint len = _addresses.length;
        contractArray = new bytes(len);
        for ( uint i = 0; i < _addresses.length; i++ ){
            address addr = _addresses[i];
            uint size = addr.code.length;
            if ( size > 0) {
                contractArray[i] = 0x01;
            } else {
                contractArray[i] = 0x00;
            }    
        }
        return contractArray;   
    }

    function getTokenNames(address[] memory _addresses) external view returns (string[] memory) {
        bytes memory ERC20Bytes = _getIsERC20Bytes(_addresses);
        uint returnLength = ERC20Bytes.length;
        string[] memory NameArray = new string[](returnLength);
        for(uint i = 0; i < _addresses.length ; i++){
            address addr = _addresses[i];
            if(ERC20Bytes[i] == 0x01){
                (bool success, bytes memory token0addr) = addr.staticcall(abi.encodeWithSignature("token0()"));
                if(success){ //is lp
                    (,bytes memory token1addr) = addr.staticcall(abi.encodeWithSignature("token1()"));
                    (,bytes memory lpName) = addr.staticcall(abi.encodeWithSignature("symbol()"));
                    (,bytes memory token0name) = abi.decode(token0addr,(address)).staticcall(abi.encodeWithSignature("symbol()"));
                    (,bytes memory token1name) = abi.decode(token1addr,(address)).staticcall(abi.encodeWithSignature("symbol()"));
                        uint j = 0;
                        NameArray[j] = string.concat(string(token0name),"/",string(token1name),"-",string(lpName));
                        j++;
                    }
                if(!success){
                    bytes memory name;
                    (success, name) = addr.staticcall(abi.encodeWithSignature("symbol()"));
                    if(success){
                        uint j = 0;
                        NameArray[i] = string(name);
                        j++;
                    }   
                }
            }
        }
        return NameArray;  
    }

    function _getIsERC20Bytes(address[] memory _addresses) public view returns (bytes memory){
        uint len = _addresses.length;
        bytes memory isERC20Bytes = new bytes(len);
        for(uint i = 0; i < len; i++){
            address addr = _addresses[i];
            (bool success, bytes memory returnData) = addr.staticcall(abi.encodeWithSignature("totalSupply()"));
            uint numericalCallResult = uint(bytes32(returnData));
            if(success){ //is ERC20
                isERC20Bytes[i] = 0x01;
            }
            if(success && numericalCallResult == 0 ) { // if call succeeds but returns 0, lets just have a little check...
            /*
            assumption taken: I've looked at probably tens of thousands of ERC20s, and literally all had this function,
            but is not "required" in the EIP
            */
                (success,) = addr.staticcall(abi.encodeWithSignature("decimals()")); 
                    if(success){
                        isERC20Bytes[i] = 0x01;
                    }
            }
        }
        return isERC20Bytes;
    }
}