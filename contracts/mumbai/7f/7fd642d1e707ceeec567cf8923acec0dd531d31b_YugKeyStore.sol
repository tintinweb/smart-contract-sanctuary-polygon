/**
 *Submitted for verification at polygonscan.com on 2023-02-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


interface IAdmin {
    function isValidAdmin(address adminAddress) external view returns (bool);
}

contract YugKeyStore {

    address _admin;

    mapping(address => string[]) private _user_public_keys;
    mapping(address => string[]) private _user_encrypted_private_keys;

    function initialize(address admin) public {
        require(_admin == address(0) || IAdmin(_admin).isValidAdmin(msg.sender), "Unauthorized");
        _admin = admin;
    }

    function saveUserKeys(address user, string memory public_key, string memory private_encrypted_key) public {
        require(IAdmin(_admin).isValidAdmin(msg.sender), "Unauthorized");
        _user_public_keys[user].push(public_key);
        _user_encrypted_private_keys[user].push(private_encrypted_key);
    }

    function saveMyKeys(string memory public_key, string memory private_encrypted_key) public {
        _user_public_keys[msg.sender].push(public_key);
        _user_encrypted_private_keys[msg.sender].push(private_encrypted_key);
    }

    function getPublicKey(address user) public view returns (string memory){
        return _user_public_keys[user][_user_public_keys[user].length - 1];
    }

    function getPrivateKey() public view returns (string memory){
        return _user_encrypted_private_keys[msg.sender][_user_encrypted_private_keys[msg.sender].length - 1];
    }

    function getAllPublicKeys(address user) public view returns (string[] memory){
        return _user_public_keys[user];
    }

    function getAllPrivateKeys() public view returns (string[] memory){
        return _user_encrypted_private_keys[msg.sender];
    }

}