//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import { StringUtils } from "./stringUtils.sol";

contract Wallet {
    address payable public owner;
    //1 if associated, otherwise not associated
    mapping(address => uint) associatedAddresses;

    event received(string successMessage, uint256 amount, address sender);
    event withdrawn(string successMessage, uint256 amount, address recipient);
    event associatedAddressChange(string message, address changedAddress);

    function initialize( 
        address _owner) public {
        owner = payable(_owner);
    }

    receive() external payable{
      emit received('You have received funds', msg.value, msg.sender);
    }
    
    fallback() external payable {
      emit received('You have received funds', msg.value, msg.sender);
    }

    function addAssociatedAddress(address _newAddress) external onlyOwner {
      require(associatedAddresses[_newAddress] != 1);
      associatedAddresses[_newAddress] == 1;
      emit associatedAddressChange('You have added a new associated address', _newAddress);
    }

    function removeAssociatedAddress(address _removeAddress) external onlyOwner {
      require(associatedAddresses[_removeAddress] == 1);
      associatedAddresses[_removeAddress] == 0;
      emit associatedAddressChange('You have removed an associated address', _removeAddress);
    }
     
    function personalWithdraw(uint _amount) external onlyOwner {
      (bool sent, bytes memory data) = msg.sender.call{value: _amount}("");
      require(sent, "Failed to send Ether");
      emit withdrawn('You have withdrawn personal funds', _amount, msg.sender);
    }

    function externalWithdraw(uint _amount, address _wallet) external onlyOwner {
      (bool sent, bytes memory data) = _wallet.call{value: _amount}("");
      require(sent, "Failed to send Ether");
      emit withdrawn('You have withdrawn funds to an address not owned by you', _amount, _wallet);
    }

    function getBalance() external view returns (uint) {
      return address(this).balance;
    }

    modifier onlyOwner() {
        require(msg.sender == owner || associatedAddresses[msg.sender] == 1);
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

library StringUtils {
    /**
     * @dev Returns the length of a given string
     *
     * @param s The string to measure the length of
     * @return The length of the input string
     */
    function strlen(string memory s) internal pure returns (uint) {
        uint len;
        uint i = 0;
        uint bytelength = bytes(s).length;
        for(len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if(b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }
}