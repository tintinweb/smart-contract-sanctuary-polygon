/**
 *Submitted for verification at polygonscan.com on 2022-09-20
*/

// SPDX-License-Identifier: NONE
pragma solidity 0.8.7;

/**
 * @title UnifarmStorage
 * @author Himanshu Singh
 */
contract UnifarmStorage {

    uint256 walletCount;
    int totalSum;
    mapping(address => bool) private userExists;

    /**
     * @notice Stores and sums the values entered by a wallet address 
     * @param _value value to store
     */
    function store(int _value) public {
        require(_value != 0, "Number cannot be zero!");
        require(!isContract(msg.sender), "Only wallet can call this method!");
        if(!userExists[msg.sender]){
            userExists[msg.sender] = true;
            walletCount++;
        }
        totalSum += _value;
    }

    /**
     * @notice This method returns sum of all values entered by all users and also wallet count
     * @return int,uint256 total sum and total wallets count
     */
    function retriveDetails() public view returns (int, uint256){
        return (totalSum, walletCount);
    }

    /**
     * @notice This method returns true or false based on address is a contract or not
     * @return bool returns true if it is a contract else returns false
     * @param _addr address provided by the user
     */
    function isContract(address _addr) private view returns (bool) {
        uint size;
        assembly { size := extcodesize(_addr) }
        return size > 0;
    }

}