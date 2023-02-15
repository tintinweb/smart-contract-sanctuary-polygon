/**
 *Submitted for verification at polygonscan.com on 2023-02-14
*/

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.17;

contract Proxiable {
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"
    uint256 constant PROXY_MEM_SLOT = 0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;

    event CodeAddressUpdated(address newAddress);

    function _updateCodeAddress(address newAddress) internal {
        require(
            bytes32(PROXY_MEM_SLOT) == Proxiable(newAddress).proxiableUUID(),
            "Not compatible"
        );
        assembly {
            // solium-disable-line
            sstore(PROXY_MEM_SLOT, newAddress)
        }

        emit CodeAddressUpdated(newAddress);
    }

    function getLogicAddress() public view returns (address logicAddress) {
        assembly {
            // solium-disable-line
            logicAddress := sload(PROXY_MEM_SLOT)
        }
    }

    function proxiableUUID() public pure returns (bytes32) {
        return bytes32(PROXY_MEM_SLOT);
    }
}

contract MyContract is Proxiable {
    address public owner;
    uint256 public count;
    bool public initialized;


    function initialize() public {
        require(owner == address(0)," Already initialize");
        require(!initialized, "Already initialize");
        owner = msg.sender;
        initialized = true;
    }

    modifier onlyOwner {
        require(msg.sender == owner," only owner call");
        _;
    }

    function increament() public {
        count++;
    }

    function updateCode(address newAddress) public onlyOwner {
        _updateCodeAddress(newAddress);

    }
}