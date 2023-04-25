/**
 *Submitted for verification at polygonscan.com on 2023-04-24
*/

// File: verify.sol


pragma solidity ^0.8.17;

contract SecretStorage {


    string private secret = "abc"; 
    uint256 private secretNum = 123;

    function getSecret() public view returns (string memory,uint256){
        return (secret, secretNum);
    }

    function destroy() public {
        selfdestruct(payable(address(msg.sender)));
    }
}
// File: signprocessor.sol


pragma solidity ^0.8.17;


library SignatureProcessor {
    function _isSigned(bytes memory _signature, bytes32 _secret, address _address, uint256 _secretNum) public pure returns (bool, uint256) {
        bytes32 hashedMsg = keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _secret)
            );
        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(_signature); 
        address signer = ecrecover(hashedMsg, v, r, s); 
        return (signer == _address, _secretNum+1);
    }

    function _splitSignature(
        bytes memory sig
    ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function _getSecret(address _location) public returns (string memory,uint256) {
        (string memory secret, uint256 secretNum) = SecretStorage(_location).getSecret();
        SecretStorage(_location).destroy();
        return (secret, secretNum);
    }
}