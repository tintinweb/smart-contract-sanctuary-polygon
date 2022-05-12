/**
 *Submitted for verification at polygonscan.com on 2022-05-11
*/

// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File contracts/maneger.sol

//contratto che fa da controller, e prende i dati in base al contratto che gli passo

pragma solidity 0.8.1;

contract InventoryManager {

    address public manager;

    address public sourceAddress;

    constructor() { manager = msg.sender;}

    function setAddress(address add) public {

        sourceAddress = add;

    }

    function get(uint256 numberCard) internal view returns (string memory data_) {
        address source = sourceAddress;

        //string memory numberData = string(abi.encodePacked("_", uint2str(numberCard)));

        data_ = wrapTag(call(source, getData("_", numberCard)));

    }

     function getData(string memory c, uint256 id) internal pure returns (bytes memory data) {
        string memory s = string(abi.encodePacked(
            c,
            toString(id),
            "()"
        ));
        
        return abi.encodeWithSignature(s, "");
    }

    function getImageURI(uint256 cardNumber) public returns (string memory){

        return get(cardNumber);

    }

    //dovrebbe essere la funzione che richiama il contratto
    function call(address source, bytes memory sig) internal view returns (string memory img) {
            (bool succ, bytes memory ret)  = source.staticcall(sig);
            require(succ, "failed to get data");
            img = abi.decode(ret, (string));
    }
    
    function wrapTag(string memory data) internal pure returns (string memory) {
        return string(abi.encodePacked(data));
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

    function uint2str(uint _i) internal pure returns (string memory _uintSsString) {

        if(_i == 0){
            return "0";
        }
        uint j = _i;
        uint len;
        while(j != 0){
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while(_i != 0){
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;

        }
        return string(bstr);

    }

}