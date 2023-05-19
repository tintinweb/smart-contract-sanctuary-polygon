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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";
//import "@openzeppelin/contracts/interfaces/IERC2771.sol";



/**
 * @dev Context variant with ERC2771 support.
 */
contract ERC2771ContextLocal is Context{
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./ERC2771ContextLocal.sol";

contract LicensAccountContract is ERC2771ContextLocal {
    
    mapping(address => string) public creatorCID;
    event CreatorUpdated(
        address creator,
        string creatorCID
    );
    constructor(address trustedForwarder) ERC2771ContextLocal(trustedForwarder) {
    }

    function updateCreator(address _creator, string memory _creatorCID) external {
        require(_creator == _msgSender(), "msgSender is not the same as the passed address");
        creatorCID[_msgSender()] = _creatorCID;
        emit CreatorUpdated(_msgSender(), _creatorCID);
    }
    
    function isRegistered(address _address) external view returns(bool){
        return bytes(creatorCID[_address]).length != 0;
    }
}