/**
 *Submitted for verification at polygonscan.com on 2023-05-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/** @author DiGi Official credit to thirdweb
*
*     ██████╗░██╗░██████╗░██╗
*     ██╔══██╗██║██╔════╝░██║
*     ██║░░██║██║██║░░██╗░██║
*     ██║░░██║██║██║░░╚██╗██║
*     ██████╔╝██║╚██████╔╝██║
*     ╚═════╝░╚═╝░╚═════╝░╚═╝
*
*    ░█████╗░███████╗███████╗██╗░█████╗░██╗░█████╗░
*    ██╔══██╗██╔════╝██╔════╝██║██╔══██╗██║██╔══██╗
*    ██║░░██║█████╗░░█████╗░░██║██║░░╚═╝██║███████║
*    ██║░░██║██╔══╝░░██╔══╝░░██║██║░░██╗██║██╔══██║
*    ╚█████╔╝██║░░░░░██║░░░░░██║╚█████╔╝██║██║░░██║
*    ░╚════╝░╚═╝░░░░░╚═╝░░░░░╚═╝░╚════╝░╚═╝╚═╝░░╚═╝
*
* @author  digiofficial.xyz
 */

library TWAddress {
  
    function isContract(address account) internal view returns (bool) {
      
        return account.code.length > 0;
    }

   
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
  
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
 
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

 
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.8.0;

library SafeERC20 {
    using TWAddress for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
       
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 amount) external;

    function transfer(address to, uint256 value) external returns (bool);
}

pragma solidity ^0.8.0;

library CurrencyTransferLib {
    using SafeERC20 for IERC20;

    /// @dev The address interpreted as native token of the chain.
    address public constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev Transfers a given amount of currency.
    function transferCurrency(
        address _currency,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if (_amount == 0) {
            return;
        }

        if (_currency == NATIVE_TOKEN) {
            safeTransferNativeToken(_to, _amount);
        } else {
            safeTransferERC20(_currency, _from, _to, _amount);
        }
    }

    /// @dev Transfers a given amount of currency. (With native token wrapping)
    function transferCurrencyWithWrapper(
        address _currency,
        address _from,
        address _to,
        uint256 _amount,
        address _nativeTokenWrapper
    ) internal {
        if (_amount == 0) {
            return;
        }

        if (_currency == NATIVE_TOKEN) {
            if (_from == address(this)) {
                // withdraw from weth then transfer withdrawn native token to recipient
                IWETH(_nativeTokenWrapper).withdraw(_amount);
                safeTransferNativeTokenWithWrapper(_to, _amount, _nativeTokenWrapper);
            } else if (_to == address(this)) {
                // store native currency in weth
                require(_amount == msg.value, "msg.value != amount");
                IWETH(_nativeTokenWrapper).deposit{ value: _amount }();
            } else {
                safeTransferNativeTokenWithWrapper(_to, _amount, _nativeTokenWrapper);
            }
        } else {
            safeTransferERC20(_currency, _from, _to, _amount);
        }
    }

    /// @dev Transfer `amount` of ERC20 token from `from` to `to`.
    function safeTransferERC20(
        address _currency,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if (_from == _to) {
            return;
        }

        if (_from == address(this)) {
            IERC20(_currency).safeTransfer(_to, _amount);
        } else {
            IERC20(_currency).safeTransferFrom(_from, _to, _amount);
        }
    }

    /// @dev Transfers `amount` of native token to `to`.
    function safeTransferNativeToken(address to, uint256 value) internal {
        // solhint-disable avoid-low-level-calls
        // slither-disable-next-line low-level-calls
        (bool success, ) = to.call{ value: value }("");
        require(success, "native token transfer failed");
    }

    /// @dev Transfers `amount` of native token to `to`. (With native token wrapping)
    function safeTransferNativeTokenWithWrapper(
        address to,
        uint256 value,
        address _nativeTokenWrapper
    ) internal {
        // solhint-disable avoid-low-level-calls
        // slither-disable-next-line low-level-calls
        (bool success, ) = to.call{ value: value }("");
        if (!success) {
            IWETH(_nativeTokenWrapper).deposit{ value: value }();
            IERC20(_nativeTokenWrapper).safeTransfer(to, value);
        }
    }
}

// File: @thirdweb-dev/contracts/lib/TWStrings.sol


pragma solidity ^0.8.0;

library TWStrings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
       
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File: @thirdweb-dev/contracts/extension/plugin/PermissionsStorage.sol


pragma solidity ^0.8.0;

library PermissionsStorage {
    bytes32 public constant PERMISSIONS_STORAGE_POSITION = keccak256("permissions.storage");

    struct Data {
        /// @dev Map from keccak256 hash of a role => a map from address => whether address has role.
        mapping(bytes32 => mapping(address => bool)) _hasRole;
        /// @dev Map from keccak256 hash of a role to role admin. See {getRoleAdmin}.
        mapping(bytes32 => bytes32) _getRoleAdmin;
    }

    function permissionsStorage() internal pure returns (Data storage permissionsData) {
        bytes32 position = PERMISSIONS_STORAGE_POSITION;
        assembly {
            permissionsData.slot := position
        }
    }
}

// File: @thirdweb-dev/contracts/extension/interface/IPermissions.sol


pragma solidity ^0.8.0;

interface IPermissions {
   
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

pragma solidity ^0.8.0;

contract PermissionsLogic is IPermissions {
    /// @dev Default admin role for all roles. Only accounts with this role can grant/revoke other roles.
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /// @dev Modifier that checks if an account has the specified role; reverts otherwise.
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

   
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        PermissionsStorage.Data storage data = PermissionsStorage.permissionsStorage();
        return data._hasRole[role][account];
    }

    function hasRoleWithSwitch(bytes32 role, address account) public view returns (bool) {
        PermissionsStorage.Data storage data = PermissionsStorage.permissionsStorage();
        if (!data._hasRole[role][address(0)]) {
            return data._hasRole[role][account];
        }

        return true;
    }

    function getRoleAdmin(bytes32 role) external view override returns (bytes32) {
        PermissionsStorage.Data storage data = PermissionsStorage.permissionsStorage();
        return data._getRoleAdmin[role];
    }

    function grantRole(bytes32 role, address account) public virtual override {
        PermissionsStorage.Data storage data = PermissionsStorage.permissionsStorage();
        _checkRole(data._getRoleAdmin[role], _msgSender());
        if (data._hasRole[role][account]) {
            revert("Can only grant to non holders");
        }
        _setupRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public virtual override {
        PermissionsStorage.Data storage data = PermissionsStorage.permissionsStorage();
        _checkRole(data._getRoleAdmin[role], _msgSender());
        _revokeRole(role, account);
    }

    function renounceRole(bytes32 role, address account) public virtual override {
        if (_msgSender() != account) {
            revert("Can only renounce for self");
        }
        _revokeRole(role, account);
    }

    /// @dev Sets `adminRole` as `role`'s admin role.
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        PermissionsStorage.Data storage data = PermissionsStorage.permissionsStorage();
        bytes32 previousAdminRole = data._getRoleAdmin[role];
        data._getRoleAdmin[role] = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /// @dev Sets up `role` for `account`
    function _setupRole(bytes32 role, address account) internal virtual {
        PermissionsStorage.Data storage data = PermissionsStorage.permissionsStorage();
        data._hasRole[role][account] = true;
        emit RoleGranted(role, account, _msgSender());
    }

    /// @dev Revokes `role` from `account`
    function _revokeRole(bytes32 role, address account) internal virtual {
        PermissionsStorage.Data storage data = PermissionsStorage.permissionsStorage();
        _checkRole(role, account);
        delete data._hasRole[role][account];
        emit RoleRevoked(role, account, _msgSender());
    }

    /// @dev Checks `role` for `account`. Reverts with a message including the required role.
    function _checkRole(bytes32 role, address account) internal view virtual {
        PermissionsStorage.Data storage data = PermissionsStorage.permissionsStorage();
        if (!data._hasRole[role][account]) {
            revert(
                string(
                    abi.encodePacked(
                        "Permissions: account ",
                        TWStrings.toHexString(uint160(account), 20),
                        " is missing role ",
                        TWStrings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /// @dev Checks `role` for `account`. Reverts with a message including the required role.
    function _checkRoleWithSwitch(bytes32 role, address account) internal view virtual {
        if (!hasRoleWithSwitch(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "Permissions: account ",
                        TWStrings.toHexString(uint160(account), 20),
                        " is missing role ",
                        TWStrings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    function _msgSender() internal view virtual returns (address sender) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @thirdweb-dev/contracts/extension/interface/IPermissionsEnumerable.sol


pragma solidity ^0.8.0;

interface IPermissionsEnumerable is IPermissions {

    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

pragma solidity ^0.8.0;

library PermissionsEnumerableStorage {
    bytes32 public constant PERMISSIONS_ENUMERABLE_STORAGE_POSITION = keccak256("permissions.enumerable.storage");

    struct RoleMembers {
        uint256 index;
        mapping(uint256 => address) members;
        mapping(address => uint256) indexOf;
    }

    struct Data {
        /// @dev map from keccak256 hash of a role to its members' data. See {RoleMembers}.
        mapping(bytes32 => RoleMembers) roleMembers;
    }

    function permissionsEnumerableStorage() internal pure returns (Data storage permissionsEnumerableData) {
        bytes32 position = PERMISSIONS_ENUMERABLE_STORAGE_POSITION;
        assembly {
            permissionsEnumerableData.slot := position
        }
    }
}

pragma solidity ^0.8.0;

contract PermissionsEnumerableLogic is IPermissionsEnumerable, PermissionsLogic {
   
    function getRoleMember(bytes32 role, uint256 index) external view override returns (address member) {
        PermissionsEnumerableStorage.Data storage data = PermissionsEnumerableStorage.permissionsEnumerableStorage();
        uint256 currentIndex = data.roleMembers[role].index;
        uint256 check;

        for (uint256 i = 0; i < currentIndex; i += 1) {
            if (data.roleMembers[role].members[i] != address(0)) {
                if (check == index) {
                    member = data.roleMembers[role].members[i];
                    return member;
                }
                check += 1;
            } else if (hasRole(role, address(0)) && i == data.roleMembers[role].indexOf[address(0)]) {
                check += 1;
            }
        }
    }

    function getRoleMemberCount(bytes32 role) external view override returns (uint256 count) {
        PermissionsEnumerableStorage.Data storage data = PermissionsEnumerableStorage.permissionsEnumerableStorage();
        uint256 currentIndex = data.roleMembers[role].index;

        for (uint256 i = 0; i < currentIndex; i += 1) {
            if (data.roleMembers[role].members[i] != address(0)) {
                count += 1;
            }
        }
        if (hasRole(role, address(0))) {
            count += 1;
        }
    }

    /// @dev Revokes `role` from `account`, and removes `account` from {roleMembers}
    ///      See {_removeMember}
    function _revokeRole(bytes32 role, address account) internal override {
        super._revokeRole(role, account);
        _removeMember(role, account);
    }

    /// @dev Grants `role` to `account`, and adds `account` to {roleMembers}
    ///      See {_addMember}
    function _setupRole(bytes32 role, address account) internal override {
        super._setupRole(role, account);
        _addMember(role, account);
    }

    /// @dev adds `account` to {roleMembers}, for `role`
    function _addMember(bytes32 role, address account) internal {
        PermissionsEnumerableStorage.Data storage data = PermissionsEnumerableStorage.permissionsEnumerableStorage();
        uint256 idx = data.roleMembers[role].index;
        data.roleMembers[role].index += 1;

        data.roleMembers[role].members[idx] = account;
        data.roleMembers[role].indexOf[account] = idx;
    }

    /// @dev removes `account` from {roleMembers}, for `role`
    function _removeMember(bytes32 role, address account) internal {
        PermissionsEnumerableStorage.Data storage data = PermissionsEnumerableStorage.permissionsEnumerableStorage();
        uint256 idx = data.roleMembers[role].indexOf[account];

        delete data.roleMembers[role].members[idx];
        delete data.roleMembers[role].indexOf[account];
    }
}

pragma solidity ^0.8.0;

library ReentrancyGuardStorage {
    bytes32 public constant REENTRANCY_GUARD_STORAGE_POSITION = keccak256("reentrancy.guard.storage");

    struct Data {
        uint256 _status;
    }

    function reentrancyGuardStorage() internal pure returns (Data storage reentrancyGuardData) {
        bytes32 position = REENTRANCY_GUARD_STORAGE_POSITION;
        assembly {
            reentrancyGuardData.slot := position
        }
    }
}

pragma solidity ^0.8.0;

abstract contract ReentrancyGuardLogic {
   
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    function __ReentrancyGuard_init() internal {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal {
        ReentrancyGuardStorage.Data storage data = ReentrancyGuardStorage.reentrancyGuardStorage();
        data._status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        ReentrancyGuardStorage.Data storage data = ReentrancyGuardStorage.reentrancyGuardStorage();
        // On the first call to nonReentrant, _notEntered will be true
        require(data._status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        data._status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        data._status = _NOT_ENTERED;
    }
}

pragma solidity ^0.8.0;


interface IPlatformFee {
    /// @dev Fee type variants: percentage fee and flat fee
    enum PlatformFeeType {
        Bps,
        Flat
    }

    /// @dev Returns the platform fee bps and recipient.
    function getPlatformFeeInfo() external view returns (address, uint16);

    /// @dev Lets a module admin update the fees on primary sales.
    function setPlatformFeeInfo(address _platformFeeRecipient, uint256 _platformFeeBps) external;

    /// @dev Emitted when fee on primary sales is updated.
    event PlatformFeeInfoUpdated(address indexed platformFeeRecipient, uint256 platformFeeBps);

    /// @dev Emitted when the flat platform fee is updated.
    event FlatPlatformFeeUpdated(address platformFeeRecipient, uint256 flatFee);

    /// @dev Emitted when the platform fee type is updated.
    event PlatformFeeTypeUpdated(PlatformFeeType feeType);
}

// File: @thirdweb-dev/contracts/extension/plugin/ERC2771ContextStorage.sol


pragma solidity ^0.8.0;

/// @author thirdweb

library ERC2771ContextStorage {
    bytes32 public constant ERC2771_CONTEXT_STORAGE_POSITION = keccak256("erc2771.context.storage");

    struct Data {
        mapping(address => bool) _trustedForwarder;
    }

    function erc2771ContextStorage() internal pure returns (Data storage erc2771ContextData) {
        bytes32 position = ERC2771_CONTEXT_STORAGE_POSITION;
        assembly {
            erc2771ContextData.slot := position
        }
    }
}

pragma solidity ^0.8.0;

abstract contract ERC2771ContextLogic {
    constructor(address[] memory trustedForwarder) {
        ERC2771ContextStorage.Data storage data = ERC2771ContextStorage.erc2771ContextStorage();

        for (uint256 i = 0; i < trustedForwarder.length; i++) {
            data._trustedForwarder[trustedForwarder[i]] = true;
        }
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        ERC2771ContextStorage.Data storage data = ERC2771ContextStorage.erc2771ContextStorage();
        return data._trustedForwarder[forwarder];
    }

    function _msgSender() internal view virtual returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}

pragma solidity ^0.8.0;

/// @author thirdweb


interface IERC2771Context {
    function isTrustedForwarder(address forwarder) external view returns (bool);
}

abstract contract ERC2771ContextConsumer {
    function _msgSender() public view virtual returns (address sender) {
        if (IERC2771Context(address(this)).isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function _msgData() public view virtual returns (bytes calldata) {
        if (IERC2771Context(address(this)).isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}

pragma solidity ^0.8.0;

interface IERC165 {
    
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.8.0;

interface IERC2981 is IERC165 {
  
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

pragma solidity ^0.8.0;

interface IERC721 is IERC165 {
   
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

pragma solidity ^0.8.0;

interface IERC1155 is IERC165 {
    
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

   
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.11;

interface IDirectListings {
    enum TokenType {
        ERC721,
        ERC1155
    }

    enum Status {
        UNSET,
        CREATED,
        COMPLETED,
        CANCELLED
    }

    struct ListingParameters {
        address assetContract;
        uint256 tokenId;
        uint256 quantity;
        address currency;
        uint256 pricePerToken;
        uint128 startTimestamp;
        uint128 endTimestamp;
        bool reserved;
    }

    struct Listing {
        uint256 listingId;
        address listingCreator;
        address assetContract;
        uint256 tokenId;
        uint256 quantity;
        address currency;
        uint256 pricePerToken;
        uint128 startTimestamp;
        uint128 endTimestamp;
        bool reserved;
        TokenType tokenType;
        Status status;
    }

    /// @notice Emitted when a new listing is created.
    event NewListing(
        address indexed listingCreator,
        uint256 indexed listingId,
        address indexed assetContract,
        Listing listing
    );

    /// @notice Emitted when a listing is updated.
    event UpdatedListing(
        address indexed listingCreator,
        uint256 indexed listingId,
        address indexed assetContract,
        Listing listing
    );

    /// @notice Emitted when a listing is cancelled.
    event CancelledListing(address indexed listingCreator, uint256 indexed listingId);

    /// @notice Emitted when a buyer is approved to buy from a reserved listing.
    event BuyerApprovedForListing(uint256 indexed listingId, address indexed buyer, bool approved);

    /// @notice Emitted when a currency is approved as a form of payment for the listing.
    event CurrencyApprovedForListing(uint256 indexed listingId, address indexed currency, uint256 pricePerToken);

    /// @notice Emitted when NFTs are bought from a listing.
    event NewSale(
        address indexed listingCreator,
        uint256 indexed listingId,
        address indexed assetContract,
        uint256 tokenId,
        address buyer,
        uint256 quantityBought,
        uint256 totalPricePaid
    );

    function createListing(ListingParameters memory _params) external returns (uint256 listingId);

    function updateListing(uint256 _listingId, ListingParameters memory _params) external;

    function cancelListing(uint256 _listingId) external;

    function approveBuyerForListing(
        uint256 _listingId,
        address _buyer,
        bool _toApprove
    ) external;

    function approveCurrencyForListing(
        uint256 _listingId,
        address _currency,
        uint256 _pricePerTokenInCurrency
    ) external;

    function buyFromListing(
        uint256 _listingId,
        address _buyFor,
        uint256 _quantity,
        address _currency,
        uint256 _expectedTotalPrice
    ) external payable;

    function totalListings() external view returns (uint256);

    function getAllListings(uint256 _startId, uint256 _endId) external view returns (Listing[] memory listings);

  
    function getAllValidListings(uint256 _startId, uint256 _endId) external view returns (Listing[] memory listings);

    function getListing(uint256 _listingId) external view returns (Listing memory listing);
}

interface IEnglishAuctions {
    enum TokenType {
        ERC721,
        ERC1155
    }

    enum Status {
        UNSET,
        CREATED,
        COMPLETED,
        CANCELLED
    }

    struct AuctionParameters {
        address assetContract;
        uint256 tokenId;
        uint256 quantity;
        address currency;
        uint256 minimumBidAmount;
        uint256 buyoutBidAmount;
        uint64 timeBufferInSeconds;
        uint64 bidBufferBps;
        uint64 startTimestamp;
        uint64 endTimestamp;
    }

    struct Auction {
        uint256 auctionId;
        address auctionCreator;
        address assetContract;
        uint256 tokenId;
        uint256 quantity;
        address currency;
        uint256 minimumBidAmount;
        uint256 buyoutBidAmount;
        uint64 timeBufferInSeconds;
        uint64 bidBufferBps;
        uint64 startTimestamp;
        uint64 endTimestamp;
        TokenType tokenType;
        Status status;
    }

    struct Bid {
        uint256 auctionId;
        address bidder;
        uint256 bidAmount;
    }

    struct AuctionPayoutStatus {
        bool paidOutAuctionTokens;
        bool paidOutBidAmount;
    }

    /// @dev Emitted when a new auction is created.
    event NewAuction(
        address indexed auctionCreator,
        uint256 indexed auctionId,
        address indexed assetContract,
        Auction auction
    );

    /// @dev Emitted when a new bid is made in an auction.
    event NewBid(
        uint256 indexed auctionId,
        address indexed bidder,
        address indexed assetContract,
        uint256 bidAmount,
        Auction auction
    );

    /// @notice Emitted when a auction is cancelled.
    event CancelledAuction(address indexed auctionCreator, uint256 indexed auctionId);

    /// @dev Emitted when an auction is closed.
    event AuctionClosed(
        uint256 indexed auctionId,
        address indexed assetContract,
        address indexed closer,
        uint256 tokenId,
        address auctionCreator,
        address winningBidder
    );

    function createAuction(AuctionParameters memory _params) external returns (uint256 auctionId);

    function cancelAuction(uint256 _auctionId) external;

    function collectAuctionPayout(uint256 _auctionId) external;

    function collectAuctionTokens(uint256 _auctionId) external;

    function bidInAuction(uint256 _auctionId, uint256 _bidAmount) external payable;

    function isNewWinningBid(uint256 _auctionId, uint256 _bidAmount) external view returns (bool);

    /// @notice Returns the auction of the provided auction ID.
    function getAuction(uint256 _auctionId) external view returns (Auction memory auction);

    /// @notice Returns all non-cancelled auctions.
    function getAllAuctions(uint256 _startId, uint256 _endId) external view returns (Auction[] memory auctions);

    /// @notice Returns all active auctions.
    function getAllValidAuctions(uint256 _startId, uint256 _endId) external view returns (Auction[] memory auctions);

    /// @notice Returns the winning bid of an active auction.
    function getWinningBid(uint256 _auctionId)
        external
        view
        returns (
            address bidder,
            address currency,
            uint256 bidAmount
        );

    /// @notice Returns whether an auction is active.
    function isAuctionExpired(uint256 _auctionId) external view returns (bool);
}

interface IOffers {
    enum TokenType {
        ERC721,
        ERC1155,
        ERC20
    }

    enum Status {
        UNSET,
        CREATED,
        COMPLETED,
        CANCELLED
    }

    struct OfferParams {
        address assetContract;
        uint256 tokenId;
        uint256 quantity;
        address currency;
        uint256 totalPrice;
        uint256 expirationTimestamp;
    }

    struct Offer {
        uint256 offerId;
        address offeror;
        address assetContract;
        uint256 tokenId;
        uint256 quantity;
        address currency;
        uint256 totalPrice;
        uint256 expirationTimestamp;
        TokenType tokenType;
        Status status;
    }

    /// @dev Emitted when a new offer is created.
    event NewOffer(address indexed offeror, uint256 indexed offerId, address indexed assetContract, Offer offer);

    /// @dev Emitted when an offer is cancelled.
    event CancelledOffer(address indexed offeror, uint256 indexed offerId);

    /// @dev Emitted when an offer is accepted.
    event AcceptedOffer(
        address indexed offeror,
        uint256 indexed offerId,
        address indexed assetContract,
        uint256 tokenId,
        address seller,
        uint256 quantityBought,
        uint256 totalPricePaid
    );

    function makeOffer(OfferParams memory _params) external returns (uint256 offerId);

    function cancelOffer(uint256 _offerId) external;

    function acceptOffer(uint256 _offerId) external;

    /// @notice Returns an offer for the given offer ID.
    function getOffer(uint256 _offerId) external view returns (Offer memory offer);

    /// @notice Returns all active (i.e. non-expired or cancelled) offers.
    function getAllOffers(uint256 _startId, uint256 _endId) external view returns (Offer[] memory offers);

    /// @notice Returns all valid offers. An offer is valid if the offeror owns and has approved Marketplace to transfer the offer amount of currency.
    function getAllValidOffers(uint256 _startId, uint256 _endId) external view returns (Offer[] memory offers);
}

pragma solidity ^0.8.11;

library EnglishAuctionsStorage {
    bytes32 public constant ENGLISH_AUCTIONS_STORAGE_POSITION = keccak256("english.auctions.storage");

    struct Data {
        uint256 totalAuctions;
        mapping(uint256 => IEnglishAuctions.Auction) auctions;
        mapping(uint256 => IEnglishAuctions.Bid) winningBid;
        mapping(uint256 => IEnglishAuctions.AuctionPayoutStatus) payoutStatus;
    }

    function englishAuctionsStorage() internal pure returns (Data storage englishAuctionsData) {
        bytes32 position = ENGLISH_AUCTIONS_STORAGE_POSITION;
        assembly {
            englishAuctionsData.slot := position
        }
    }
}

pragma solidity ^0.8.11;

/// @author DiGi Official credit to thirdweb
/**
 * @author  digiofficial.xyz
 */
contract EnglishAuctionsLogic is IEnglishAuctions, ReentrancyGuardLogic, ERC2771ContextConsumer {
    /*///////////////////////////////////////////////////////////////
                        Constants / Immutables
    //////////////////////////////////////////////////////////////*/

    /// @dev Only lister role holders can create auctions, when auctions are restricted by lister address.
    bytes32 private constant LISTER_ROLE = keccak256("LISTER_ROLE");
    /// @dev Only assets from NFT contracts with asset role can be auctioned, when auctions are restricted by asset address.
    bytes32 private constant ASSET_ROLE = keccak256("ASSET_ROLE");

    /// @dev The max bps of the contract. So, 10_000 == 100 %
    uint64 private constant MAX_BPS = 10_000;

    /// @dev The address of the native token wrapper contract.
    address private immutable nativeTokenWrapper;

    /*///////////////////////////////////////////////////////////////
                              Modifiers
    //////////////////////////////////////////////////////////////*/

    modifier onlyListerRole() {
        require(PermissionsLogic(address(this)).hasRoleWithSwitch(LISTER_ROLE, _msgSender()), "!LISTER_ROLE");
        _;
    }

    modifier onlyAssetRole(address _asset) {
        require(PermissionsLogic(address(this)).hasRoleWithSwitch(ASSET_ROLE, _asset), "!ASSET_ROLE");
        _;
    }

    /// @dev Checks whether caller is a auction creator.
    modifier onlyAuctionCreator(uint256 _auctionId) {
        EnglishAuctionsStorage.Data storage data = EnglishAuctionsStorage.englishAuctionsStorage();

        require(data.auctions[_auctionId].auctionCreator == _msgSender(), "Marketplace: not auction creator.");
        _;
    }

    /// @dev Checks whether an auction exists.
    modifier onlyExistingAuction(uint256 _auctionId) {
        EnglishAuctionsStorage.Data storage data = EnglishAuctionsStorage.englishAuctionsStorage();
        require(data.auctions[_auctionId].status == IEnglishAuctions.Status.CREATED, "Marketplace: invalid auction.");
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            Constructor logic
    //////////////////////////////////////////////////////////////*/

    constructor(address _nativeTokenWrapper) {
        nativeTokenWrapper = _nativeTokenWrapper;
    }

    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Auction ERC721 or ERC1155 NFTs.
    function createAuction(AuctionParameters calldata _params)
        external
        onlyListerRole
        onlyAssetRole(_params.assetContract)
        returns (uint256 auctionId)
    {
        auctionId = _getNextAuctionId();
        address auctionCreator = _msgSender();
        TokenType tokenType = _getTokenType(_params.assetContract);

        _validateNewAuction(_params, tokenType);

        Auction memory auction = Auction({
            auctionId: auctionId,
            auctionCreator: auctionCreator,
            assetContract: _params.assetContract,
            tokenId: _params.tokenId,
            quantity: _params.quantity,
            currency: _params.currency,
            minimumBidAmount: _params.minimumBidAmount,
            buyoutBidAmount: _params.buyoutBidAmount,
            timeBufferInSeconds: _params.timeBufferInSeconds,
            bidBufferBps: _params.bidBufferBps,
            startTimestamp: _params.startTimestamp,
            endTimestamp: _params.endTimestamp,
            tokenType: tokenType,
            status: IEnglishAuctions.Status.CREATED
        });

        EnglishAuctionsStorage.Data storage data = EnglishAuctionsStorage.englishAuctionsStorage();
        data.auctions[auctionId] = auction;

        _transferAuctionTokens(auctionCreator, address(this), auction);

        emit NewAuction(auctionCreator, auctionId, _params.assetContract, auction);
    }

    function bidInAuction(uint256 _auctionId, uint256 _bidAmount)
        external
        payable
        nonReentrant
        onlyExistingAuction(_auctionId)
    {
        EnglishAuctionsStorage.Data storage data = EnglishAuctionsStorage.englishAuctionsStorage();
        Auction memory _targetAuction = data.auctions[_auctionId];

        require(
            _targetAuction.endTimestamp > block.timestamp && _targetAuction.startTimestamp <= block.timestamp,
            "Marketplace: inactive auction."
        );
        require(_bidAmount != 0, "Marketplace: Bidding with zero amount.");

        Bid memory newBid = Bid({ auctionId: _auctionId, bidder: _msgSender(), bidAmount: _bidAmount });

        _handleBid(_targetAuction, newBid);
    }

    function collectAuctionPayout(uint256 _auctionId) external nonReentrant onlyAuctionCreator(_auctionId) {
        EnglishAuctionsStorage.Data storage data = EnglishAuctionsStorage.englishAuctionsStorage();

        require(!data.payoutStatus[_auctionId].paidOutBidAmount, "Marketplace: payout already completed.");
        data.payoutStatus[_auctionId].paidOutBidAmount = true;

        Auction memory _targetAuction = data.auctions[_auctionId];
        Bid memory _winningBid = data.winningBid[_auctionId];

        require(_targetAuction.status != IEnglishAuctions.Status.CANCELLED, "Marketplace: invalid auction.");
        require(_targetAuction.endTimestamp <= block.timestamp, "Marketplace: auction still active.");
        require(_winningBid.bidder != address(0), "Marketplace: no bids were made.");

        _closeAuctionForAuctionCreator(_targetAuction, _winningBid);

        if (_targetAuction.status != IEnglishAuctions.Status.COMPLETED) {
            data.auctions[_auctionId].status = IEnglishAuctions.Status.COMPLETED;
        }
    }

    function collectAuctionTokens(uint256 _auctionId) external nonReentrant {
        EnglishAuctionsStorage.Data storage data = EnglishAuctionsStorage.englishAuctionsStorage();
        Auction memory _targetAuction = data.auctions[_auctionId];
        Bid memory _winningBid = data.winningBid[_auctionId];

        require(_targetAuction.status != IEnglishAuctions.Status.CANCELLED, "Marketplace: invalid auction.");
        require(_targetAuction.endTimestamp <= block.timestamp, "Marketplace: auction still active.");
        require(_winningBid.bidder != address(0), "Marketplace: no bids were made.");

        _closeAuctionForBidder(_targetAuction, _winningBid);

        if (_targetAuction.status != IEnglishAuctions.Status.COMPLETED) {
            data.auctions[_auctionId].status = IEnglishAuctions.Status.COMPLETED;
        }
    }

    /// @dev Cancels an auction.
    function cancelAuction(uint256 _auctionId) external onlyExistingAuction(_auctionId) onlyAuctionCreator(_auctionId) {
        EnglishAuctionsStorage.Data storage data = EnglishAuctionsStorage.englishAuctionsStorage();
        Auction memory _targetAuction = data.auctions[_auctionId];
        Bid memory _winningBid = data.winningBid[_auctionId];

        require(_winningBid.bidder == address(0), "Marketplace: bids already made.");

        data.auctions[_auctionId].status = IEnglishAuctions.Status.CANCELLED;

        _transferAuctionTokens(address(this), _targetAuction.auctionCreator, _targetAuction);

        emit CancelledAuction(_targetAuction.auctionCreator, _auctionId);
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    function isNewWinningBid(uint256 _auctionId, uint256 _bidAmount)
        external
        view
        onlyExistingAuction(_auctionId)
        returns (bool)
    {
        EnglishAuctionsStorage.Data storage data = EnglishAuctionsStorage.englishAuctionsStorage();
        Auction memory _targetAuction = data.auctions[_auctionId];
        Bid memory _currentWinningBid = data.winningBid[_auctionId];

        return
            _isNewWinningBid(
                _targetAuction.minimumBidAmount,
                _currentWinningBid.bidAmount,
                _bidAmount,
                _targetAuction.bidBufferBps
            );
    }

    function totalAuctions() external view returns (uint256) {
        EnglishAuctionsStorage.Data storage data = EnglishAuctionsStorage.englishAuctionsStorage();
        return data.totalAuctions;
    }

    function getAuction(uint256 _auctionId) external view returns (Auction memory _auction) {
        EnglishAuctionsStorage.Data storage data = EnglishAuctionsStorage.englishAuctionsStorage();
        _auction = data.auctions[_auctionId];
    }

    function getAllAuctions(uint256 _startId, uint256 _endId) external view returns (Auction[] memory _allAuctions) {
        EnglishAuctionsStorage.Data storage data = EnglishAuctionsStorage.englishAuctionsStorage();
        require(_startId <= _endId && _endId < data.totalAuctions, "invalid range");

        _allAuctions = new Auction[](_endId - _startId + 1);

        for (uint256 i = _startId; i <= _endId; i += 1) {
            _allAuctions[i - _startId] = data.auctions[i];
        }
    }

    function getAllValidAuctions(uint256 _startId, uint256 _endId)
        external
        view
        returns (Auction[] memory _validAuctions)
    {
        EnglishAuctionsStorage.Data storage data = EnglishAuctionsStorage.englishAuctionsStorage();
        require(_startId <= _endId && _endId < data.totalAuctions, "invalid range");

        Auction[] memory _auctions = new Auction[](_endId - _startId + 1);
        uint256 _auctionCount;

        for (uint256 i = _startId; i <= _endId; i += 1) {
            uint256 j = i - _startId;
            _auctions[j] = data.auctions[i];
            if (
                _auctions[j].startTimestamp <= block.timestamp &&
                _auctions[j].endTimestamp > block.timestamp &&
                _auctions[j].status == IEnglishAuctions.Status.CREATED &&
                _auctions[j].assetContract != address(0)
            ) {
                _auctionCount += 1;
            }
        }

        _validAuctions = new Auction[](_auctionCount);
        uint256 index = 0;
        uint256 count = _auctions.length;
        for (uint256 i = 0; i < count; i += 1) {
            if (
                _auctions[i].startTimestamp <= block.timestamp &&
                _auctions[i].endTimestamp > block.timestamp &&
                _auctions[i].status == IEnglishAuctions.Status.CREATED &&
                _auctions[i].assetContract != address(0)
            ) {
                _validAuctions[index++] = _auctions[i];
            }
        }
    }

    function getWinningBid(uint256 _auctionId)
        external
        view
        onlyExistingAuction(_auctionId)
        returns (
            address _bidder,
            address _currency,
            uint256 _bidAmount
        )
    {
        EnglishAuctionsStorage.Data storage data = EnglishAuctionsStorage.englishAuctionsStorage();
        Auction memory _targetAuction = data.auctions[_auctionId];
        Bid memory _currentWinningBid = data.winningBid[_auctionId];

        _bidder = _currentWinningBid.bidder;
        _currency = _targetAuction.currency;
        _bidAmount = _currentWinningBid.bidAmount;
    }

    function isAuctionExpired(uint256 _auctionId) external view onlyExistingAuction(_auctionId) returns (bool) {
        EnglishAuctionsStorage.Data storage data = EnglishAuctionsStorage.englishAuctionsStorage();
        return data.auctions[_auctionId].endTimestamp >= block.timestamp;
    }

    /*///////////////////////////////////////////////////////////////
                            Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the next auction Id.
    function _getNextAuctionId() internal returns (uint256 id) {
        EnglishAuctionsStorage.Data storage data = EnglishAuctionsStorage.englishAuctionsStorage();
        id = data.totalAuctions;
        data.totalAuctions += 1;
    }

    /// @dev Returns the interface supported by a contract.
    function _getTokenType(address _assetContract) internal view returns (TokenType tokenType) {
        if (IERC165(_assetContract).supportsInterface(type(IERC1155).interfaceId)) {
            tokenType = TokenType.ERC1155;
        } else if (IERC165(_assetContract).supportsInterface(type(IERC721).interfaceId)) {
            tokenType = TokenType.ERC721;
        } else {
            revert("Marketplace: auctioned token must be ERC1155 or ERC721.");
        }
    }

    /// @dev Checks whether the auction creator owns and has approved marketplace to transfer auctioned tokens.
    function _validateNewAuction(AuctionParameters memory _params, TokenType _tokenType) internal view {
        require(_params.quantity > 0, "Marketplace: auctioning zero quantity.");
        require(_params.quantity == 1 || _tokenType == TokenType.ERC1155, "Marketplace: auctioning invalid quantity.");
        require(_params.timeBufferInSeconds > 0, "Marketplace: no time-buffer.");
        require(_params.bidBufferBps > 0, "Marketplace: no bid-buffer.");
        require(
            _params.startTimestamp + 60 minutes >= block.timestamp && _params.startTimestamp < _params.endTimestamp,
            "Marketplace: invalid timestamps."
        );
        require(
            _params.buyoutBidAmount == 0 || _params.buyoutBidAmount >= _params.minimumBidAmount,
            "Marketplace: invalid bid amounts."
        );
    }

    /// @dev Processes an incoming bid in an auction.
    function _handleBid(Auction memory _targetAuction, Bid memory _incomingBid) internal {
        EnglishAuctionsStorage.Data storage data = EnglishAuctionsStorage.englishAuctionsStorage();
        Bid memory currentWinningBid = data.winningBid[_targetAuction.auctionId];
        uint256 currentBidAmount = currentWinningBid.bidAmount;
        uint256 incomingBidAmount = _incomingBid.bidAmount;
        address _nativeTokenWrapper = nativeTokenWrapper;

        // Close auction and execute sale if there's a buyout price and incoming bid amount is buyout price.
        if (_targetAuction.buyoutBidAmount > 0 && incomingBidAmount >= _targetAuction.buyoutBidAmount) {
            incomingBidAmount = _targetAuction.buyoutBidAmount;

            _closeAuctionForBidder(_targetAuction, _incomingBid);
        } else {
            /**
             *      If there's an exisitng winning bid, incoming bid amount must be bid buffer % greater.
             *      Else, bid amount must be at least as great as minimum bid amount
             */
            require(
                _isNewWinningBid(
                    _targetAuction.minimumBidAmount,
                    currentBidAmount,
                    incomingBidAmount,
                    _targetAuction.bidBufferBps
                ),
                "Marketplace: not winning bid."
            );

            // Update the winning bid and auction's end time before external contract calls.
            data.winningBid[_targetAuction.auctionId] = _incomingBid;

            if (_targetAuction.endTimestamp - block.timestamp <= _targetAuction.timeBufferInSeconds) {
                _targetAuction.endTimestamp += _targetAuction.timeBufferInSeconds;
                data.auctions[_targetAuction.auctionId] = _targetAuction;
            }
        }

        // Payout previous highest bid.
        if (currentWinningBid.bidder != address(0) && currentBidAmount > 0) {
            CurrencyTransferLib.transferCurrencyWithWrapper(
                _targetAuction.currency,
                address(this),
                currentWinningBid.bidder,
                currentBidAmount,
                _nativeTokenWrapper
            );
        }

        // Collect incoming bid
        CurrencyTransferLib.transferCurrencyWithWrapper(
            _targetAuction.currency,
            _incomingBid.bidder,
            address(this),
            incomingBidAmount,
            _nativeTokenWrapper
        );

        emit NewBid(
            _targetAuction.auctionId,
            _incomingBid.bidder,
            _targetAuction.assetContract,
            _incomingBid.bidAmount,
            _targetAuction
        );
    }

    /// @dev Checks whether an incoming bid is the new current highest bid.
    function _isNewWinningBid(
        uint256 _minimumBidAmount,
        uint256 _currentWinningBidAmount,
        uint256 _incomingBidAmount,
        uint256 _bidBufferBps
    ) internal pure returns (bool isValidNewBid) {
        if (_currentWinningBidAmount == 0) {
            isValidNewBid = _incomingBidAmount >= _minimumBidAmount;
        } else {
            isValidNewBid = (_incomingBidAmount > _currentWinningBidAmount &&
                ((_incomingBidAmount - _currentWinningBidAmount) * MAX_BPS) / _currentWinningBidAmount >=
                _bidBufferBps);
        }
    }

    /// @dev Closes an auction for the winning bidder; distributes auction items to the winning bidder.
    function _closeAuctionForBidder(Auction memory _targetAuction, Bid memory _winningBid) internal {
        EnglishAuctionsStorage.Data storage data = EnglishAuctionsStorage.englishAuctionsStorage();

        require(
            !data.payoutStatus[_targetAuction.auctionId].paidOutAuctionTokens,
            "Marketplace: payout already completed."
        );
        data.payoutStatus[_targetAuction.auctionId].paidOutAuctionTokens = true;

        _targetAuction.endTimestamp = uint64(block.timestamp);

        data.winningBid[_targetAuction.auctionId] = _winningBid;
        data.auctions[_targetAuction.auctionId] = _targetAuction;

        _transferAuctionTokens(address(this), _winningBid.bidder, _targetAuction);

        emit AuctionClosed(
            _targetAuction.auctionId,
            _targetAuction.assetContract,
            _msgSender(),
            _targetAuction.tokenId,
            _targetAuction.auctionCreator,
            _winningBid.bidder
        );
    }

    /// @dev Closes an auction for an auction creator; distributes winning bid amount to auction creator.
    function _closeAuctionForAuctionCreator(Auction memory _targetAuction, Bid memory _winningBid) internal {
        uint256 payoutAmount = _winningBid.bidAmount;
        _payout(address(this), _targetAuction.auctionCreator, _targetAuction.currency, payoutAmount, _targetAuction);

        emit AuctionClosed(
            _targetAuction.auctionId,
            _msgSender(),
            _targetAuction.assetContract,
            _targetAuction.tokenId,
            _targetAuction.auctionCreator,
            _winningBid.bidder
        );
    }

    /// @dev Transfers tokens for auction.
    function _transferAuctionTokens(
        address _from,
        address _to,
        Auction memory _auction
    ) internal {
        if (_auction.tokenType == TokenType.ERC1155) {
            IERC1155(_auction.assetContract).safeTransferFrom(_from, _to, _auction.tokenId, _auction.quantity, "");
        } else if (_auction.tokenType == TokenType.ERC721) {
            IERC721(_auction.assetContract).safeTransferFrom(_from, _to, _auction.tokenId, "");
        }
    }

    /// @dev Pays out stakeholders in auction.
    function _payout(
        address _payer,
        address _payee,
        address _currencyToUse,
        uint256 _totalPayoutAmount,
        Auction memory _targetAuction
    ) internal {
        (address platformFeeRecipient, uint16 platformFeeBps) = IPlatformFee(address(this)).getPlatformFeeInfo();
        uint256 platformFeeCut = (_totalPayoutAmount * platformFeeBps) / MAX_BPS;

        uint256 royaltyCut;
        address royaltyRecipient;

        // Distribute royalties. See Sushiswap's https://github.com/sushiswap/shoyu/blob/master/contracts/base/BaseExchange.sol#L296
        try IERC2981(_targetAuction.assetContract).royaltyInfo(_targetAuction.tokenId, _totalPayoutAmount) returns (
            address royaltyFeeRecipient,
            uint256 royaltyFeeAmount
        ) {
            if (royaltyFeeRecipient != address(0) && royaltyFeeAmount > 0) {
                require(royaltyFeeAmount + platformFeeCut <= _totalPayoutAmount, "fees exceed the price");
                royaltyRecipient = royaltyFeeRecipient;
                royaltyCut = royaltyFeeAmount;
            }
        } catch {}

        // Distribute price to token owner
        address _nativeTokenWrapper = nativeTokenWrapper;

        CurrencyTransferLib.transferCurrencyWithWrapper(
            _currencyToUse,
            _payer,
            platformFeeRecipient,
            platformFeeCut,
            _nativeTokenWrapper
        );
        CurrencyTransferLib.transferCurrencyWithWrapper(
            _currencyToUse,
            _payer,
            royaltyRecipient,
            royaltyCut,
            _nativeTokenWrapper
        );
        CurrencyTransferLib.transferCurrencyWithWrapper(
            _currencyToUse,
            _payer,
            _payee,
            _totalPayoutAmount - (platformFeeCut + royaltyCut),
            _nativeTokenWrapper
        );
    }
}