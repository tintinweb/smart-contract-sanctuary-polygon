//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import { StringUtils } from "./stringUtils.sol";

contract Wallet {
    address payable public owner;
    //1 if associated, otherwise not associated
    mapping(address => uint) associatedAddresses;
    address[] public ownerAddresses;
    uint256 private alreadyInitialized;

    event received(string successMessage, uint256 amount, address sender);
    event withdrawn(string successMessage, uint256 amount, address recipient);
    event associatedAddressChange(string message, address changedAddress);

    function initialize( 
        address _owner) public {
        require(alreadyInitialized != 1);
        alreadyInitialized = 1;
        owner = payable(_owner);
        ownerAddresses.push(owner);
    }

    receive() external payable{
      emit received('You have received funds', msg.value, msg.sender);
    }

    fallback() external payable {
      emit received('You have received funds', msg.value, msg.sender);
    }

    function viewAssociatedAddresses() public view returns (address[] memory) {
      address[] memory _returnAddresses = new address[](ownerAddresses.length);
      for(uint i = 0; i < ownerAddresses.length; i++){
        if(associatedAddresses[ownerAddresses[i]] == 1){
          _returnAddresses[i] = (ownerAddresses[i]);
        }
      }
      return _returnAddresses;
    }

    function addAssociatedAddress(address _newAddress) external onlyOwner {
      require(associatedAddresses[_newAddress] != 1);
      associatedAddresses[_newAddress] == 1;

      //isIncluded == 1 means it's on the list
      uint isIncluded;
      for(uint i = 0; i < ownerAddresses.length; i++){
        if(ownerAddresses[i] == _newAddress){
          isIncluded = 1;
        }
      }

      if(isIncluded != 1){
        ownerAddresses.push(_newAddress);
      }

      emit associatedAddressChange('You have added a new associated address', _newAddress);
    }

    function removeAssociatedAddress(address _removeAddress) external onlyOwner {
      require(associatedAddresses[_removeAddress] == 1);
      associatedAddresses[_removeAddress] == 0;
      emit associatedAddressChange('You have removed an associated address', _removeAddress);
    }
     
    function personalWithdraw(uint _amount) external onlyOwner {
      (bool sent, bytes memory data) = msg.sender.call{value: _amount}("");
      require(sent, "Failed to withdraw Ether");
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