// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/*
    Copyright 2017-2019 Phillip A. Elsasser

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./MarketContractRegistryInterface.sol";

/// @title MarketContractRegistry
/// @author Phil Elsasser <[email protected]>
contract MarketContractRegistry is Ownable, MarketContractRegistryInterface {
    // whitelist accounting
    mapping(address => bool) public isWhiteListed;
    address[] public addressWhiteList; // record of currently deployed addresses;
    mapping(address => bool) public factoryAddressWhiteList; // record of authorized factories

    uint256 addressWhiteListLength;

    // events
    event AddressAddedToWhitelist(address indexed contractAddress);
    event AddressRemovedFromWhitelist(address indexed contractAddress);
    event FactoryAddressAdded(address indexed factoryAddress);
    event FactoryAddressRemoved(address indexed factoryAddress);

    /*
    // External Methods
    */

    /// @notice determines if an address is a valid MarketContract
    /// @return false if the address is not white listed.
    function isAddressWhiteListed(
        address contractAddress
    ) external view override  returns (bool) {
        return isWhiteListed[contractAddress];
    }

    /// @notice all currently whitelisted addresses
    /// returns array of addresses
    function getAddressWhiteList() external view returns (address[] memory) {
        return addressWhiteList;
    }

    /// @dev allows for the owner to remove a white listed contract, eventually ownership could transition to
    /// a decentralized smart contract of community members to vote
    /// @param contractAddress contract to removed from white list
    /// @param whiteListIndex of the contractAddress in the addressWhiteList to be removed.
    function removeContractFromWhiteList(
        address contractAddress,
        uint whiteListIndex
    ) external onlyOwner {
        require(
            isWhiteListed[contractAddress],
            "can only remove whitelisted addresses"
        );
        require(
            addressWhiteList[whiteListIndex] == contractAddress,
            "index does not match address"
        );
        addressWhiteListLength = addressWhiteList.length;
        isWhiteListed[contractAddress] = false;
         

        // push the last item in array to replace the address we are removing and then trim the array.
        addressWhiteList[whiteListIndex] = addressWhiteList[
            addressWhiteListLength - 1
        ];
        addressWhiteListLength -= 1;
        emit AddressRemovedFromWhitelist(contractAddress);
    }

    function isOwner() public view virtual returns (bool) {
        return msg.sender == owner();
    }

    /// @dev allows for the owner or factory to add a white listed contract, eventually ownership could transition to
    /// a decentralized smart contract of community members to vote
    /// @param contractAddress contract to removed from white list
   function addAddressToWhiteList(address contractAddress) external override {
        require(
            isOwner() || factoryAddressWhiteList[msg.sender],
            "Can only be added by factory or owner"
        );
        require(
            !isWhiteListed[contractAddress],
            "Address must not be whitelisted"
        );
        isWhiteListed[contractAddress] = true;
        addressWhiteList.push(contractAddress);
        emit AddressAddedToWhitelist(contractAddress);
    }

    /// @dev allows for the owner to add a new address of a factory responsible for creating new market contracts
    /// @param factoryAddress address of factory to be allowed to add contracts to whitelist
    function addFactoryAddress(address factoryAddress) external onlyOwner {
        require(
            !factoryAddressWhiteList[factoryAddress],
            "address already added"
        );
        factoryAddressWhiteList[factoryAddress] = true;
        emit FactoryAddressAdded(factoryAddress);
    }

    /// @dev allows for the owner to remove an address of a factory
    /// @param factoryAddress address of factory to be removed
    function removeFactoryAddress(address factoryAddress) external onlyOwner {
        require(
            factoryAddressWhiteList[factoryAddress],
            "factory address is not in the white list"
        );
        factoryAddressWhiteList[factoryAddress] = false;
        emit FactoryAddressRemoved(factoryAddress);
    }
}

/*
    Copyright 2017-2019 Phillip A. Elsasser

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


abstract contract MarketContractRegistryInterface {
    function addAddressToWhiteList(address contractAddress) virtual external;
    function isAddressWhiteListed(address contractAddress) virtual external view returns (bool);
}