//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

/**
 @title Registry
 @dev charon registry mapping address to publicKey
 */
contract Registry {
    // Events
    event Registered(address indexed _a, bytes _publicKey);

    // Storage
    mapping(address => bytes) public addressToPublicKey;

    // Functions
    /**
     * @dev register a public key to an address
     * @param _publicKey public key to register
     */
    function register(bytes memory _publicKey) external {
        addressToPublicKey[msg.sender] = _publicKey;
        emit Registered(msg.sender, _publicKey);
    }

    /**
     * @dev get public key of an address
     * @param _a address to get public key of
     */
    function getPublicKey(address _a) external view returns (bytes memory) {
        bytes memory _publicKey = addressToPublicKey[_a];
        return _publicKey;
    }
}