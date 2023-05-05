// SPDX-License-Identifier: SHELL
pragma solidity ^0.8.0;


contract ContractRegistry {

    struct AddressSlot {
        address value;
    }

    /**
    * Returns an `AddressSlot` with member value located at `slot`
    */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot:= slot
        }
    }

    /**
    * Returns `contractAddress`
     */
    function getContractAddress(bytes32 slot) internal view returns (address) {
        return getAddressSlot(slot).value;
    }


    /**
    *  Returns true for contract address
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
    * Stores a new address in the slot
     */
    function setContractAddress(bytes32 slot, address contractAddress) internal {
        require(isContract(contractAddress), "ContractRegistry: contractAddress is not a contract");
        getAddressSlot(slot).value = contractAddress;
    }

}