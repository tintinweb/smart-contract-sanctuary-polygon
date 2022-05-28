// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IRoles.sol";

contract Whitelisting {


    mapping(address => bool) whitelistedAddresses;
    address[] whitelistedAddressesArray; 
    uint256 nonZeroCount;
    address public rolesContractAddress;
    IRoles private roles;

    event UserAdded(address _address, string _msg);
    event UserRemoved(address _address, string _msg);

    constructor(address _rolesContractAddress) {
        rolesContractAddress = _rolesContractAddress;
        roles = IRoles(rolesContractAddress);
    }

    modifier _onlyRole(bytes32 _role) {
        require(roles.hasRole(_role, msg.sender), "Account does not have sufficient permissions");
        _;
    }

    function addUsers(address[] memory _addressToWhitelist) public _onlyRole(roles.WEB_ADMIN_ROLE()){
      for(uint i=0;i < _addressToWhitelist.length; i++){
       if (! whitelistedAddresses[_addressToWhitelist[i]]){
            whitelistedAddresses[_addressToWhitelist[i]] = true;
            whitelistedAddressesArray.push(_addressToWhitelist[i]);
            nonZeroCount++;
            emit UserAdded(_addressToWhitelist[i], "User has been added to whitelist");
       }
      }
    }

    function removeUsers(address[] memory _addressToWhitelist) public _onlyRole(roles.WEB_ADMIN_ROLE()){
        for(uint i=0;i < _addressToWhitelist.length; i++){
            if (whitelistedAddresses[_addressToWhitelist[i]]){
                whitelistedAddresses[_addressToWhitelist[i]] = false;
                for(uint j=0;j<whitelistedAddressesArray.length;j++){
                    if(whitelistedAddressesArray[j] == _addressToWhitelist[i]){
                        delete whitelistedAddressesArray[j];
                        nonZeroCount--;
                    }
                }
            emit UserRemoved(_addressToWhitelist[i], "User has been removed from whitelist");
            }
        }
    }
    

    function verifyUser(address _whitelistedAddress) public view returns(bool) {
      bool userIsWhitelisted = whitelistedAddresses[_whitelistedAddress];
      return userIsWhitelisted;
    }

    function getWhitelistedArray()  public view returns(address[] memory){
		address[] memory _whiteListedArray = new address[](nonZeroCount);
        uint count = 0;
        for(uint i=0;i<whitelistedAddressesArray.length;i++){
            if(whitelistedAddressesArray[i] != address(0)){
                _whiteListedArray[count] = whitelistedAddressesArray[i];
                count++;
            }
        }
        return _whiteListedArray;
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/IAccessControl.sol";

interface IRoles is IAccessControl {
    
    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    function WEB_ADMIN_ROLE() external view returns (bytes32);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}