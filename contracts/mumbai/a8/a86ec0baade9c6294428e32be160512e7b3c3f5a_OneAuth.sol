// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Owned} from "solmate/auth/Owned.sol";
import {IOneAuth} from "./interfaces/IOneAuth.sol";
import {ISimpleAccount} from "./interfaces/ISimpleAccount.sol";

contract OneAuth is IOneAuth, Owned {
    // stores the address of each administator
    address[] internal admins;

    // stores the address of KYC participants
    address[] internal kycAccounts;

    // stores the address of each  administator
    mapping(address => bool) admin;

    // stores the address of KYC participants
    mapping(address => bool) kyc;

    /*//////////////////////////////-////////////////////////////////
                                CONSTRUCTOR
    ////////////////////////////////-//////////////////////////////*/

    // constructor
    constructor() Owned(msg.sender) {}

    /*//////////////////////////////-////////////////////////////////
                                 MODIFIERS
    ////////////////////////////////-//////////////////////////////*/

    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner || admin[msg.sender], "DiamondFactoryV1: Caller is not the owner or admin");
        _;
    }

    /*//////////////////////////////-////////////////////////////////
                                 SETTERS
    ////////////////////////////////-//////////////////////////////*/

    function addKyc(address[] calldata _addr) external onlyOwnerOrAdmin {
        for (uint256 i = 0; i < _addr.length; ) {
            kyc[_addr[i]] = true;
            kycAccounts.push(_addr[i]);
            emit AddKycAccount(msg.sender, _addr[i]);
            unchecked {
                i++;
            }
        }
    }

    function removeKyc(address[] calldata _addr) external onlyOwnerOrAdmin {
        for (uint256 i = 0; i < _addr.length; ) {
            kyc[_addr[i]] = false;

            for (uint256 j = 0; j < kycAccounts.length; j++) {
                if (kycAccounts[j] == _addr[i]) {
                    kycAccounts[j] = kycAccounts[kycAccounts.length - 1];
                    kycAccounts.pop();
                    break;
                }
                unchecked {
                    j++;
                }
            }
            emit RemoveKycAccount(msg.sender, _addr[i]);
            unchecked {
                i++;
            }
        }
    }

    // add admin
    function addAdmin(address[] calldata _addr) external onlyOwnerOrAdmin {
        for (uint256 i = 0; i < _addr.length; ) {
            admins.push(_addr[i]);
            admin[_addr[i]] = true;
            emit AddAdmin(msg.sender, _addr[i]);
            unchecked {
                i++;
            }
        }
    }

    function removeAdmin(address[] calldata _addr) external onlyOwnerOrAdmin {
        for (uint256 i = 0; i < _addr.length; ) {
            admin[_addr[i]] = false;

            for (uint256 j = 0; j < admins.length; ) {
                if (admins[j] == _addr[i]) {
                    admins[j] = admins[admins.length - 1];
                    admins.pop();
                    break;
                }
                unchecked {
                    j++;
                }
            }
            emit RemoveAdmin(msg.sender, _addr[i]);
            unchecked {
                i++;
            }
        }
    }

    /*//////////////////////////////-////////////////////////////////
                                 GETTERS
    ////////////////////////////////-//////////////////////////////*/

    function isAdmin(address _addr) external view returns (bool) {
        return admin[_addr];
    }

    function getAdmins() external view returns (address[] memory) {
        return admins;
    }

    function isKyc(address _addr) external returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        if (size == 0) {
            return kyc[_addr];
        } else {
            return kyc[ISimpleAccount(_addr).owner()];
        }
    }

    function getKycAccounts() external view returns (address[] memory) {
        return kycAccounts;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

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

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IOneAuth {
    event AddAdmin(address indexed calller, address addr);
    event RemoveAdmin(address indexed calller, address addr);
    event AddKycAccount(address indexed calller, address kycAccount);
    event RemoveKycAccount(address indexed calller, address kycAccount);

    function isAdmin(address _addr) external view returns (bool);

    function getAdmins() external view returns (address[] memory);

    function isKyc(address _addr) external returns (bool);

    function getKycAccounts() external view returns (address[] memory);

    function addKyc(address[] calldata _addr) external;

    function removeKyc(address[] calldata _addr) external;

    function addAdmin(address[] calldata _addr) external;

    function removeAdmin(address[] calldata _addr) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface ISimpleAccount {
    function owner() external returns (address);
}