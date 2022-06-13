/**
 *Submitted for verification at polygonscan.com on 2022-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Let it burn!
interface IGASChip {
    function balanceOf(address owner_, uint256 id_) external view returns (uint256);
    function burnAsController(address from_, uint256 id_, uint256 amount_) external;
    function burnFromSingle(address[] calldata froms_, uint256 id_, uint256 amount_) 
        external;
}

abstract contract Ownable {
    address public owner; 
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Not Owner!"); _; }
    function transferOwnership(address new_) external onlyOwner { owner = new_; }
}

contract gasChipBurnHelperV2 is Ownable {

    // Interface with GASChip
    IGASChip public GASChip = IGASChip(0x2DB1F6e2BC9df2411fB816EFF5e15536c25674FF);
    function setGASChip(address address_) external onlyOwner {
        GASChip = IGASChip(address_);
    }
    
    function burnChips(address[] calldata addresses_, uint256[] calldata iterateIds_) 
    external onlyOwner {
        // For every address in the array
        for (uint256 i = 0; i < addresses_.length; i++) {
            // Iterate through all the iterateIds to find chips
            address _currentAddress = addresses_[i];
            for (uint256 j = 0; j < iterateIds_.length; j++) {
                // If theyir balance of this is higher than 0
                uint256 _currentId = iterateIds_[j];
                uint256 _currentBalance = 
                    GASChip.balanceOf(_currentAddress, _currentId);
                // Burn their chip if exists!
                if (_currentBalance > 0) {
                    address[] memory _currentAddressAsArray = new address[](1);
                    _currentAddressAsArray[0] = _currentAddress;

                    GASChip
                    .burnFromSingle(_currentAddressAsArray, _currentId, _currentBalance);
                }
            }
        }
    }
}