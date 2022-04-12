/**
 *Submitted for verification at polygonscan.com on 2022-04-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Algoz {
    mapping(address => uint256) public captcha_count;
    mapping(address => bool) public authority_wallet;
    bytes32[] public captcha_hash_store;

    constructor() { 
        authority_wallet[msg.sender] = true;
    }

    function check_captcha(string memory guess) public {
        assert(get_current_hash(tx.origin) == get_hash(guess));
        captcha_count[tx.origin] += 1;
    }

    function skip_captcha() public {
        captcha_count[msg.sender] += 1;
    }

    function add_hash(bytes32 hash) public {
        assert(authority_wallet[msg.sender]);
        captcha_hash_store.push(hash);
    }

    function add_hash_list(bytes32[] calldata hash_list) public {
        assert(authority_wallet[msg.sender]);
        for(uint256 i=0; i<hash_list.length; i++) {
            captcha_hash_store.push(hash_list[i]);
        }
    }

    function update_hash(uint256 index, bytes32 hash) public {
        assert(authority_wallet[msg.sender] && index<get_length());
        captcha_hash_store[index] = hash;
    }

    function add_authority(address new_authority_wallet) public {
        assert(authority_wallet[msg.sender]);
        authority_wallet[new_authority_wallet] = true;
    }

    function remove_authority() public {
        assert(authority_wallet[msg.sender]);
        authority_wallet[msg.sender] = false;
    }

    function get_length() public view returns(uint256) {
        return captcha_hash_store.length;
    }

    function get_current(address wallet) public view returns(uint256) {
        return uint256(uint256(uint160(wallet))+captcha_count[wallet])%get_length();
    }

    function get_current_hash(address wallet) public view returns(bytes32) {
        return captcha_hash_store[get_current(wallet)];
    }

    function get_hash(string memory guess) public pure returns(bytes32) {
        return sha256(bytes(guess));
    }
}