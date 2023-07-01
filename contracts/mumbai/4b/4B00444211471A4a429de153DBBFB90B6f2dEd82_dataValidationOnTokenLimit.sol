/**
 *Submitted for verification at polygonscan.com on 2023-06-30
*/

pragma solidity ^0.4.24;

interface Stoken{
    function balanceOf(address account) external view returns (uint256);
}
contract dataValidationOnTokenLimit{
    address public securityToken;
        
    address public verifier;

    event balance(uint);
    function setToken(address _token) public {
        securityToken = _token;
    }

    function setVerifier(address _verifier) public{
        verifier = _verifier;
    }
    function returnSigner(bytes32 _ethSignedMessageHash , bytes32 r, bytes32 s, uint8 v) public pure returns(address){
        return ecrecover(_ethSignedMessageHash,v,r,s);
    } 

   	function splitSignature(bytes memory _sig) public pure returns(bytes32 r, bytes32 s, uint8 v){
		require(_sig.length == 65, "invalid signature length");
		assembly{
			r := mload(add(_sig,32))
			s := mload(add(_sig,64))
			v := byte(0, mload(add(_sig,96)))
		}
	}

    function decodeData(address _to,bytes memory encodedData) public  returns (bool) {
        require(encodedData.length == 160, "Invalid encoded data length");
        bytes32 _ethSignedMessageHash;
        bytes32 r;
        bytes32 s;
        uint8 v;
        address receiver;
        
         assembly {
            // Skip the first 32 bytes (offset to the second bytes32)
            encodedData := add(encodedData, 32)

            // Load the first bytes32 value
            _ethSignedMessageHash := mload(encodedData)

            // Move to the next 32 bytes (offset to the third bytes32)
            encodedData := add(encodedData, 32)

            // Load the second bytes32 value
            r := mload(encodedData)

            // Move to the next 32 bytes (offset to the fourth bytes32)
            encodedData := add(encodedData, 32)

            // Load the third bytes32 value
            s := mload(encodedData)

            // Move to the next 32 bytes (offset to the uint8)
            encodedData := add(encodedData, 32)

            // Load the uint8 value
            v := mload(encodedData)

            encodedData := add(encodedData,32)

            //Load the address
            receiver := mload(encodedData)
        }

        address signer = returnSigner(_ethSignedMessageHash, r, s, v);
        require(_to == receiver,"_to doesn't match with the original receiver");
        bool status = verifier == signer ? true:false;

        uint tokenBal = Stoken(securityToken).balanceOf(_to);
    emit balance(tokenBal);
        if(tokenBal < 2000 && status){
            return true;
        }
        else{
            return false;
        }
    }

    function encodeData(bytes32 value1, bytes32 value2, bytes32 value3, uint8 value4) public pure returns (bytes,uint) {
        // Encode the values using abi.encode()
        bytes memory encodedData = abi.encode(value1, value2, value3, value4);
        
        return (encodedData,encodedData.length);
    }

}