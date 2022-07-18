/**
 *Submitted for verification at polygonscan.com on 2022-07-18
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.14;


contract VaultHelper  {

    function checkIfContracts(address[]memory _addresses) public view returns (bytes memory contractArray) {
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

    function getTokenName(address _address) public view returns (string memory) {
        address[] memory arrayifiedAddr = new address[](1);
        arrayifiedAddr[0] = _address;
        bytes memory ERC20Bytes = _getIsERC20Bytes(arrayifiedAddr);
        bytes memory isContract = checkIfContracts(arrayifiedAddr);
        if (bytes1(isContract) == 0x01){
        string memory Name;
            if(bytes1(ERC20Bytes) == 0x01){
                (bool success, bytes memory token0addr) = _address.staticcall(abi.encodeWithSignature("token0()"));
                if(success){ //is lp
                    (,bytes memory token1addr) = _address.staticcall(abi.encodeWithSignature("token1()"));
                    (,bytes memory lpName) = _address.staticcall(abi.encodeWithSignature("symbol()"));
                    (,bytes memory token0name) = abi.decode(token0addr,(address)).staticcall(abi.encodeWithSignature("symbol()"));
                    (,bytes memory token1name) = abi.decode(token1addr,(address)).staticcall(abi.encodeWithSignature("symbol()"));
                        Name = string.concat(string(token0name),"/",string(token1name),"-",string(lpName));
                    }
                if(!success){
                    bytes memory name;
                    (success, name) = _address.staticcall(abi.encodeWithSignature("symbol()"));
                    if(success){
                        uint j = 0;
                        Name = string(name);
                        j++;
                    }   
                }
            }
            return Name;
        }
        else{ return "!contract";}
    }

    function _getIsERC20Bytes(address[] memory _addresses) public view returns (bytes memory){
        uint len = _addresses.length;
        bytes memory isERC20Bytes = new bytes(len);
        for(uint i = 0; i < len; i++){
            address addr = _addresses[i];
            if( addr.code.length != 0){
            (bool success, bytes memory returnData) = addr.staticcall(abi.encodeWithSignature("totalSupply()"));
            (success,) = addr.staticcall(abi.encodeWithSignature("decimals()")); 
            uint numericalCallResult = uint(bytes32(returnData));
            if(success){ //is ERC20
                isERC20Bytes[i] = 0x01;
            }else{
                isERC20Bytes[i] = 0x00;
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
            }else{
                isERC20Bytes[i] = 0x00;
            }
        }
        return isERC20Bytes;
    }
}