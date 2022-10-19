/**
 *Submitted for verification at polygonscan.com on 2022-10-18
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

// pragma solidity ^0.8.0;
// pragma solidity >=0.8.0 <0.9.0;
 contract SimpleStorage{
    uint256 favoriteNumber;
    uint256 constant MINIMUM_FEE_STORE = 1000000000; // 1 Gwei
    mapping(address => uint256) public addressToFavoriteNumber;

    // monetizing this function to store favrouite number
    function store(uint256 _favoriteNumber) public payable {
        require(msg.value >= MINIMUM_FEE_STORE, "Didnt send enough!");
        favoriteNumber = _favoriteNumber;
    }

     function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }


    function saveMembersFavNumber(address _userAddress, uint256 _favoriteNumber)
    external
    {
        addressToFavoriteNumber[_userAddress] = _favoriteNumber;
    }

    function deleteMembersFavNumber(address _userAddress)  external{
        delete addressToFavoriteNumber[_userAddress];
    }

    receive() external payable {

    }

}