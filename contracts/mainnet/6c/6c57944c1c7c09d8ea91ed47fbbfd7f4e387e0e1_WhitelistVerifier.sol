// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "../interfaces/IVerifier.sol";
import "@solmate/auth/Owned.sol";

contract WhitelistVerifier is IVerifier, Owned {
 
    event WhitelistAdded(address);
    event WhitelistRemoved(address);

    error NotWhitelisted();
    error AlreadyWhitelisted();

    address[] public whitelist;
   
    constructor() Owned(msg.sender) {}

    function verify(address _address) external view returns (bool) {
        return isWhitelisted(_address);
    }

    function addWhitelist(address _address) external onlyOwner {
        if(isWhitelisted(_address)) revert AlreadyWhitelisted();
        whitelist.push(_address);
        emit WhitelistAdded(_address);
    }

    function removeWhitelist(address _address) external onlyOwner {
         if(!isWhitelisted(_address)) revert NotWhitelisted();

         unchecked {
            for(uint256 i = 0; i < whitelist.length; i++) {
                if(_address == whitelist[i]) {
                    delete whitelist[i];
                    break;
                }
            }
        }

        emit WhitelistRemoved(_address);
    }

    function isWhitelisted(address _address) public view returns(bool) {
        unchecked {
            for(uint256 i = 0; i < whitelist.length; i++) {
                if(_address == whitelist[i]) return true;
            }
            return false;
        }
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

interface IVerifier {
    function verify(address poster) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}