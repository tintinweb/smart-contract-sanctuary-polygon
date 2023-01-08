// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from "../utils/Initializable.sol";

// ------------- storage

bytes32 constant DIAMOND_STORAGE_ACCESS_CONTROL = keccak256("diamond.storage.access.control");

function s() pure returns (AccessControlDS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_ACCESS_CONTROL;
    assembly { diamondStorage.slot := slot } // prettier-ignore
}

struct AccessControlDS {
    mapping(bytes32 => RoleData) roles;
}

struct RoleData {
    bytes32 adminRole;
    mapping(address => bool) members;
}

// ------------- errors

error NotAuthorized();
error RenounceForCallerOnly();

/// @title AccessControl (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts)
/// @dev Requires `__AccessControl_init` to be called in proxy
abstract contract AccessControlUDS is Initializable {
    AccessControlDS private __storageLayout; // storage layout for upgrade compatibility checks

    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /* ------------- init ------------- */

    function __AccessControl_init() internal initializer {
        s().roles[DEFAULT_ADMIN_ROLE].members[msg.sender] = true;

        emit RoleGranted(DEFAULT_ADMIN_ROLE, msg.sender, msg.sender);
    }

    /* ------------- view ------------- */

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x7965db0b; // ERC165 Interface ID for AccessControl
    }

    function hasRole(bytes32 role, address account) public view virtual returns (bool) {
        return s().roles[role].members[account];
    }

    function getRoleAdmin(bytes32 role) public view virtual returns (bytes32) {
        return s().roles[role].adminRole;
    }

    /* ------------- public ------------- */

    function grantRole(bytes32 role, address account) public virtual {
        if (!hasRole(getRoleAdmin(role), msg.sender)) revert NotAuthorized();

        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public virtual {
        if (!hasRole(getRoleAdmin(role), msg.sender)) revert NotAuthorized();

        _revokeRole(role, account);
    }

    function setRoleAdmin(bytes32 role, bytes32 adminRole) public virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);

        if (!hasRole(previousAdminRole, msg.sender)) revert NotAuthorized();

        _setRoleAdmin(role, adminRole);
    }

    function renounceRole(bytes32 role) public virtual {
        s().roles[role].members[msg.sender] = false;

        emit RoleRevoked(role, msg.sender, msg.sender);
    }

    /* ------------- internal ------------- */

    function _grantRole(bytes32 role, address account) internal virtual {
        s().roles[role].members[account] = true;

        emit RoleGranted(role, account, msg.sender);
    }

    function _revokeRole(bytes32 role, address account) internal virtual {
        s().roles[role].members[account] = false;

        emit RoleRevoked(role, account, msg.sender);
    }

    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        s().roles[role].adminRole = adminRole;

        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
    }

    /* ------------- modifier ------------- */

    modifier onlyRole(bytes32 role) {
        if (!hasRole(role, msg.sender)) revert NotAuthorized();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ------------- storage

bytes32 constant DIAMOND_STORAGE_EIP_712_PERMIT = keccak256("diamond.storage.eip.712.permit");

function s() pure returns (EIP2612DS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_EIP_712_PERMIT;
    assembly { diamondStorage.slot := slot } // prettier-ignore
}

struct EIP2612DS {
    mapping(address => uint256) nonces;
}

// ------------- errors

error InvalidSigner();
error DeadlineExpired();

/// @title EIP712Permit (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate)
/// @dev `DOMAIN_SEPARATOR` needs to be re-computed every time
/// @dev for use with a proxy due to `address(this)`
abstract contract EIP712PermitUDS {
    EIP2612DS private __storageLayout; // storage layout for upgrade compatibility checks

    /* ------------- public ------------- */

    function nonces(address owner) public view returns (uint256) {
        return s().nonces[owner];
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256("EIP712"),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /* ------------- internal ------------- */

    function _usePermit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) internal virtual {
        if (deadline < block.timestamp) revert DeadlineExpired();

        unchecked {
            uint256 nonce = s().nonces[owner]++;

            address recovered = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonce,
                                deadline
                            )
                        )
                    )
                ),
                v_,
                r_,
                s_
            );

            if (recovered == address(0) || recovered != owner) revert InvalidSigner();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from "../utils/Initializable.sol";

// ------------- storage

bytes32 constant DIAMOND_STORAGE_OWNABLE = keccak256("diamond.storage.ownable");

function s() pure returns (OwnableDS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_OWNABLE;
    assembly { diamondStorage.slot := slot } // prettier-ignore
}

struct OwnableDS {
    address owner;
}

// ------------- errors

error CallerNotOwner();

/// @title Ownable (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @dev Requires `__Ownable_init` to be called in proxy
abstract contract OwnableUDS is Initializable {
    OwnableDS private __storageLayout; // storage layout for upgrade compatibility checks

    event OwnerChanged(address oldOwner, address newOwner);

    function __Ownable_init() internal initializer {
        s().owner = msg.sender;
    }

    /* ------------- external ------------- */

    function owner() public view returns (address) {
        return s().owner;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        s().owner = newOwner;

        emit OwnerChanged(msg.sender, newOwner);
    }

    /* ------------- modifier ------------- */

    modifier onlyOwner() {
        if (msg.sender != s().owner) revert CallerNotOwner();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ------------- storage

// keccak256("eip1967.proxy.implementation") - 1
bytes32 constant ERC1967_PROXY_STORAGE_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

function s() pure returns (ERC1967UpgradeDS storage diamondStorage) {
    assembly { diamondStorage.slot := ERC1967_PROXY_STORAGE_SLOT } // prettier-ignore
}

struct ERC1967UpgradeDS {
    address implementation;
}

// ------------- errors

error InvalidUUID();
error NotAContract();

/// @title ERC1967
/// @author phaze (https://github.com/0xPhaze/UDS)
abstract contract ERC1967 {
    event Upgraded(address indexed implementation);

    function _upgradeToAndCall(address logic, bytes memory data) internal {
        if (logic.code.length == 0) revert NotAContract();

        if (ERC1822(logic).proxiableUUID() != ERC1967_PROXY_STORAGE_SLOT) revert InvalidUUID();

        if (data.length != 0) {
            (bool success, ) = logic.delegatecall(data);

            if (!success) {
                assembly {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        }

        s().implementation = logic;

        emit Upgraded(logic);
    }
}

/// @title Minimal ERC1967Proxy
/// @author phaze (https://github.com/0xPhaze/UDS)
contract ERC1967Proxy is ERC1967 {
    constructor(address logic, bytes memory data) payable {
        _upgradeToAndCall(logic, data);
    }

    fallback() external payable {
        assembly {
            calldatacopy(0, 0, calldatasize())

            let success := delegatecall(gas(), sload(ERC1967_PROXY_STORAGE_SLOT), 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            if success {
                return(0, returndatasize())
            }

            revert(0, returndatasize())
        }
    }
}

/// @title ERC1822
/// @author phaze (https://github.com/0xPhaze/UDS)
abstract contract ERC1822 {
    function proxiableUUID() external view virtual returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC1967, ERC1967_PROXY_STORAGE_SLOT} from "./ERC1967Proxy.sol";

// ------------- errors

error OnlyProxyCallAllowed();
error DelegateCallNotAllowed();

/// @title Minimal UUPSUpgrade
/// @author phaze (https://github.com/0xPhaze/UDS)
abstract contract UUPSUpgrade is ERC1967 {
    address private immutable __implementation = address(this);

    /* ------------- external ------------- */

    function upgradeToAndCall(address logic, bytes calldata data) external virtual {
        _authorizeUpgrade(logic);
        _upgradeToAndCall(logic, data);
    }

    /* ------------- view ------------- */

    function proxiableUUID() external view virtual returns (bytes32) {
        if (address(this) != __implementation) revert DelegateCallNotAllowed();

        return ERC1967_PROXY_STORAGE_SLOT;
    }

    /* ------------- virtual ------------- */

    function _authorizeUpgrade(address logic) internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from "../utils/Initializable.sol";
import {EIP712PermitUDS} from "../auth/EIP712PermitUDS.sol";

// ------------- storage

bytes32 constant DIAMOND_STORAGE_ERC20 = keccak256("diamond.storage.erc20");

function s() pure returns (ERC20DS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_ERC20;
    assembly { diamondStorage.slot := slot } // prettier-ignore
}

struct ERC20DS {
    string name;
    string symbol;
    uint8 decimals;
    uint256 totalSupply;
    mapping(address => uint256) balanceOf;
    mapping(address => mapping(address => uint256)) allowance;
}

/// @title ERC20 (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate)
abstract contract ERC20UDS is Initializable, EIP712PermitUDS {
    ERC20DS private __storageLayout; // storage layout for upgrade compatibility checks

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed operator, uint256 amount);

    /* ------------- init ------------- */

    function __ERC20_init(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) internal virtual initializer {
        s().name = _name;
        s().symbol = _symbol;
        s().decimals = _decimals;
    }

    /* ------------- view ------------- */

    function name() external view virtual returns (string memory) {
        return s().name;
    }

    function symbol() external view virtual returns (string memory) {
        return s().symbol;
    }

    function decimals() external view virtual returns (uint8) {
        return s().decimals;
    }

    function totalSupply() external view virtual returns (uint256) {
        return s().totalSupply;
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        return s().balanceOf[owner];
    }

    function allowance(address owner, address operator) public view virtual returns (uint256) {
        return s().allowance[owner][operator];
    }

    /* ------------- public ------------- */

    function approve(address operator, uint256 amount) public virtual returns (bool) {
        s().allowance[msg.sender][operator] = amount;

        emit Approval(msg.sender, operator, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        s().balanceOf[msg.sender] -= amount;

        unchecked {
            s().balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = s().allowance[from][msg.sender];

        if (allowed != type(uint256).max) s().allowance[from][msg.sender] = allowed - amount;

        s().balanceOf[from] -= amount;

        unchecked {
            s().balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    // EIP-2612 permit
    function permit(
        address owner,
        address operator,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s_
    ) public virtual {
        _usePermit(owner, operator, value, deadline, v, r, s_);

        s().allowance[owner][operator] = value;

        emit Approval(owner, operator, value);
    }

    /* ------------- internal ------------- */

    function _mint(address to, uint256 amount) internal virtual {
        s().totalSupply += amount;

        unchecked {
            s().balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        s().balanceOf[from] -= amount;

        unchecked {
            s().totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20UDS, s as erc20ds} from "../ERC20UDS.sol";

/// @title ERC20Burnable (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @notice Allows for burning ERC20 tokens
abstract contract ERC20BurnableUDS is ERC20UDS {
    /* ------------- public ------------- */

    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);
    }

    function burnFrom(address from, uint256 amount) public virtual {
        if (msg.sender != from) {
            uint256 allowed = erc20ds().allowance[from][msg.sender];

            if (allowed != type(uint256).max) erc20ds().allowance[from][msg.sender] = allowed - amount;
        }

        _burn(from, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {s as erc1967ds} from "../proxy/ERC1967Proxy.sol";

// ------------- errors

error ProxyCallRequired();
error AlreadyInitialized();

/// @title Initializable
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @dev functions using the `initializer` modifier are only callable during proxy deployment
/// @dev functions using the `reinitializer` modifier are only callable through a proxy
/// @dev and only before a proxy upgrade migration has completed
/// @dev (only when `upgradeToAndCall`'s `initCalldata` is being executed)
/// @dev allows re-initialization during upgrades
abstract contract Initializable {
    address private immutable __implementation = address(this);

    /* ------------- modifier ------------- */

    modifier initializer() {
        if (address(this).code.length != 0) revert AlreadyInitialized();
        _;
    }

    modifier reinitializer() {
        if (address(this) == __implementation) revert ProxyCallRequired();
        if (erc1967ds().implementation == __implementation) revert AlreadyInitialized();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {GangToken} from "./tokens/GangToken.sol";
import {UUPSUpgrade} from "UDS/proxy/UUPSUpgrade.sol";
import {AccessControlUDS} from "UDS/auth/AccessControlUDS.sol";

// ------------- storage

bytes32 constant DIAMOND_STORAGE_GANG_VAULT = keccak256("diamond.storage.gang.vault");
// @note flexible storage, can be changed to reset accumulated yields
bytes32 constant DIAMOND_STORAGE_GANG_VAULT_FX = keccak256("diamond.storage.gang.vault.season.3");

struct GangVaultDS {
    uint40 seasonStart;
    uint40 seasonEnd;
    uint40[3] totalShares;
    uint40[3] lastUpdateTime;
    uint80[3][3] yield;
    mapping(address => uint40[3]) userShares;
    mapping(address => uint80[3]) userBalance;
    mapping(address => uint80[3]) accruedBalances;
}

struct GangVaultFlexibleDS {
    uint80[3][3] accruedYieldPerShare;
    mapping(address => uint80[3][3]) lastUserYieldPerShare;
}

function s() pure returns (GangVaultDS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_GANG_VAULT;
    assembly {
        diamondStorage.slot := slot
    }
}

function fx() pure returns (GangVaultFlexibleDS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_GANG_VAULT_FX;
    assembly {
        diamondStorage.slot := slot
    }
}

/// @title Gangsta Mice City Gang Vault Rewards
/// @author phaze (https://github.com/0xPhaze)
contract GangVault is UUPSUpgrade, AccessControlUDS {
    GangVaultDS private __storageLayoutPersistent;

    event Burn(uint256 indexed gang, uint256 indexed token, uint256 amount);
    event SharesAdded(address indexed user, uint256 indexed gang, uint256 shares);
    event SharesRemoved(address indexed user, uint256 indexed gang, uint256 shares);

    GangToken immutable token0;
    GangToken immutable token1;
    GangToken immutable token2;

    uint256 public immutable gangVaultFeePercent;
    bytes32 constant CONTROLLER = keccak256("GANG.VAULT.CONTROLLER");

    constructor(address[3] memory gangTokens, uint256 gangVaultFee) {
        gangVaultFeePercent = gangVaultFee;

        require(gangVaultFee < 100);

        token0 = GangToken(gangTokens[0]);
        token1 = GangToken(gangTokens[1]);
        token2 = GangToken(gangTokens[2]);
    }

    function init() external initializer {
        __AccessControl_init();
    }

    /* ------------- external ------------- */

    function claimUserBalance() external {
        _updateUserBalance(0, msg.sender);
        _updateUserBalance(1, msg.sender);
        _updateUserBalance(2, msg.sender);

        uint256 balance_0 = uint256(s().userBalance[msg.sender][0]) * 1e10;
        uint256 balance_1 = uint256(s().userBalance[msg.sender][1]) * 1e10;
        uint256 balance_2 = uint256(s().userBalance[msg.sender][2]) * 1e10;

        token0.mint(msg.sender, balance_0);
        token1.mint(msg.sender, balance_1);
        token2.mint(msg.sender, balance_2);

        s().userBalance[msg.sender][0] = 0;
        s().userBalance[msg.sender][1] = 0;
        s().userBalance[msg.sender][2] = 0;
    }

    /* ------------- view ------------- */

    function seasonStart() external view returns (uint256) {
        return s().seasonStart;
    }

    function seasonEnd() external view returns (uint256) {
        return s().seasonEnd;
    }

    function getYield() external view returns (uint256[3][3] memory out) {
        uint80[3][3] memory yield = s().yield;
        assembly {
            out := yield
        }
    }

    function getUserShares(address account) external view returns (uint256[3] memory out) {
        uint40[3] memory shares = s().userShares[account];
        assembly {
            out := shares
        }
    }

    function getClaimableUserBalance(address account) public view returns (uint256[3] memory out) {
        uint256[3] memory unclaimed = _getUnclaimedUserBalance(account);

        out[0] = uint256(s().userBalance[account][0]) * 1e10 + unclaimed[0];
        out[1] = uint256(s().userBalance[account][1]) * 1e10 + unclaimed[1];
        out[2] = uint256(s().userBalance[account][2]) * 1e10 + unclaimed[2];
    }

    function getAccruedBalance(address account) external view returns (uint256[3] memory out) {
        uint256[3] memory unclaimed = _getUnclaimedUserBalance(account);

        out[0] = uint256(s().accruedBalances[account][0]) * 1e10 + unclaimed[0];
        out[1] = uint256(s().accruedBalances[account][1]) * 1e10 + unclaimed[1];
        out[2] = uint256(s().accruedBalances[account][2]) * 1e10 + unclaimed[2];
    }

    function getGangVaultBalance(uint256 gang) external view returns (uint256[3] memory out) {
        address gangAccount = _getGangAccount(gang);
        uint256[3] memory unclaimed = _getUnclaimedGangBalance(gang);

        out[0] = uint256(s().userBalance[gangAccount][0]) * 1e10 + unclaimed[0];
        out[1] = uint256(s().userBalance[gangAccount][1]) * 1e10 + unclaimed[1];
        out[2] = uint256(s().userBalance[gangAccount][2]) * 1e10 + unclaimed[2];
    }

    function getAccruedGangVaultBalances(uint256 gang) external view returns (uint256[3] memory out) {
        address gangAccount = _getGangAccount(gang);
        uint256[3] memory unclaimed = _getUnclaimedGangBalance(gang);

        out[0] = uint256(s().accruedBalances[gangAccount][0]) * 1e10 + unclaimed[0];
        out[1] = uint256(s().accruedBalances[gangAccount][1]) * 1e10 + unclaimed[1];
        out[2] = uint256(s().accruedBalances[gangAccount][2]) * 1e10 + unclaimed[2];
    }

    /* ------------- controller ------------- */

    function setSeason(uint40 start, uint40 end) external onlyRole(CONTROLLER) {
        require(start <= end);

        s().seasonStart = start;
        s().seasonEnd = end;
    }

    function resetGangVaultBalances() external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 gang; gang < 3; gang++) {
            address gangAccount = _getGangAccount(gang);

            s().userBalance[gangAccount] = [0, 0, 0];
            s().accruedBalances[gangAccount] = [0, 0, 0];
        }
    }

    function softResetGangVaultBalances() external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 gang; gang < 3; gang++) {
            address gangAccount = _getGangAccount(gang);

            _updateUserBalance(gang, gangAccount);

            s().userBalance[gangAccount] = [0, 0, 0];
        }
    }

    function setYield(uint256 gang, uint256[3] calldata yield) external onlyRole(CONTROLLER) {
        _updateYieldPerShare(gang);

        // implicit 1e18 decimals
        require(yield[0] <= 1e12);
        require(yield[1] <= 1e12);
        require(yield[2] <= 1e12);

        s().yield[gang][0] = uint80(yield[0]);
        s().yield[gang][1] = uint80(yield[1]);
        s().yield[gang][2] = uint80(yield[2]);
    }

    function addShares(address account, uint256 gang, uint40 amount) external onlyRole(CONTROLLER) {
        _updateYieldPerShare(gang);
        _updateUserBalance(gang, account);

        s().totalShares[gang] += amount;
        s().userShares[account][gang] += amount;

        emit SharesAdded(account, gang, amount);
    }

    function removeShares(address account, uint256 gang, uint40 amount) external onlyRole(CONTROLLER) {
        _updateYieldPerShare(gang);
        _updateUserBalance(gang, account);

        s().totalShares[gang] -= amount;
        s().userShares[account][gang] -= amount;

        emit SharesRemoved(account, gang, amount);
    }

    function transferShares(address from, address to, uint256 gang, uint40 amount) external onlyRole(CONTROLLER) {
        _updateYieldPerShare(gang);
        _updateUserBalance(gang, from);
        _updateUserBalance(gang, to);

        s().userShares[from][gang] -= amount;
        s().userShares[to][gang] += amount;

        emit SharesRemoved(from, gang, amount);
        emit SharesAdded(to, gang, amount);
    }

    function resetShares(address account, uint40[3] memory shares) external onlyRole(CONTROLLER) {
        for (uint256 i; i < 3; ++i) {
            _updateYieldPerShare(i);
            _updateUserBalance(i, account);

            s().totalShares[i] -= s().userShares[account][i];
            s().totalShares[i] += shares[i];
            s().userShares[account][i] = shares[i];
        }
    }

    function transferYield(uint256 gangFrom, uint256 gangTo, uint256 token, uint256 yield)
        external
        onlyRole(CONTROLLER)
    {
        _updateYieldPerShare(gangFrom);
        _updateYieldPerShare(gangTo);

        s().yield[gangFrom][token] -= uint80(yield);
        s().yield[gangTo][token] += uint80(yield);
    }

    function spendGangVaultBalance(uint256 gang, uint256 amount_0, uint256 amount_1, uint256 amount_2, bool strict)
        external
        onlyRole(CONTROLLER)
    {
        address gangAccount = _getGangAccount(gang);
        uint256 totalShares = s().totalShares[gang];
        uint256 numSharesTimes100 = max(totalShares, 1) * gangVaultFeePercent;

        _updateUserBalance(gang, gangAccount, numSharesTimes100);

        uint256 balance_0 = uint256(s().userBalance[gangAccount][0]) * 1e10;
        uint256 balance_1 = uint256(s().userBalance[gangAccount][1]) * 1e10;
        uint256 balance_2 = uint256(s().userBalance[gangAccount][2]) * 1e10;

        if (!strict) {
            amount_0 = balance_0 > amount_0 ? amount_0 : balance_0;
            amount_1 = balance_1 > amount_1 ? amount_1 : balance_1;
            amount_2 = balance_2 > amount_2 ? amount_2 : balance_2;
        }

        s().userBalance[gangAccount][0] = uint80((balance_0 - amount_0) / 1e10);
        s().userBalance[gangAccount][1] = uint80((balance_1 - amount_1) / 1e10);
        s().userBalance[gangAccount][2] = uint80((balance_2 - amount_2) / 1e10);

        if (amount_0 > 0) emit Burn(gang, 0, amount_0);
        if (amount_1 > 0) emit Burn(gang, 1, amount_1);
        if (amount_2 > 0) emit Burn(gang, 2, amount_2);
    }

    /* ------------- private ------------- */

    /// @dev gang vault balances are stuck in user balances under accounts 13370, 13371, 13372.
    function _getGangAccount(uint256 gang) private pure returns (address) {
        return address(uint160(13370 + gang));
    }

    function _updateYieldPerShare(uint256 gang) private {
        (uint256 yps_0, uint256 yps_1, uint256 yps_2) = _accruedYieldPerShare(gang);

        fx().accruedYieldPerShare[gang][0] = uint80(yps_0);
        fx().accruedYieldPerShare[gang][1] = uint80(yps_1);
        fx().accruedYieldPerShare[gang][2] = uint80(yps_2);

        s().lastUpdateTime[gang] = uint40(block.timestamp);
    }

    function _accruedYieldPerShare(uint256 gang) private view returns (uint256 yps_0, uint256 yps_1, uint256 yps_2) {
        yps_0 = fx().accruedYieldPerShare[gang][0];
        yps_1 = fx().accruedYieldPerShare[gang][1];
        yps_2 = fx().accruedYieldPerShare[gang][2];

        // setting to 1 allows gangs to earn if there are no stakers
        // though this is a degenerate case
        uint256 totalShares = max(s().totalShares[gang], 1);

        // needs to be in the correct range
        // yield is daily yield with implicit 1e18 decimals
        // this number thus needs to be multiplied by 1e18
        // multiply by 1e8 first to ensure valid range (1e18 would overflow in 2^80)
        // multiply by 1e10 when claiming

        // overflow assumptions (for 1e4 days / 30 years of staking):
        // s().yield[gang][token] < 1e12 (closer to 1e8)
        // timeScaled < (1e4 days) * 1e8 = 1e12 days
        // => numerator < 1e24 days
        // => divisor > 1 days
        // => max_yps < 1e24 < 2^80
        uint256 divisor = totalShares * 1 days;
        uint256 lastUpdateTime = s().lastUpdateTime[gang];

        uint256 startTime = s().seasonStart;
        uint256 endTime = s().seasonEnd;

        // `lastUpdateTime` can become 0 when resetting to a new season.
        if (lastUpdateTime < startTime) lastUpdateTime = startTime;

        uint256 timestamp = block.timestamp > endTime ? endTime : block.timestamp;
        uint256 timeScaled = (timestamp > lastUpdateTime) ? (timestamp - lastUpdateTime) * 1e8 : 0;

        yps_0 += (timeScaled * s().yield[gang][0]) / divisor;
        yps_1 += (timeScaled * s().yield[gang][1]) / divisor;
        yps_2 += (timeScaled * s().yield[gang][2]) / divisor;
    }

    function _updateUserBalance(uint256 gang, address account) private {
        uint256 numSharesTimes100 = s().userShares[account][gang] * (100 - gangVaultFeePercent);

        _updateUserBalance(gang, account, numSharesTimes100);
    }

    function _updateUserBalance(uint256 gang, address account, uint256 numSharesTimes100) private {
        (uint256 yps_0, uint256 yps_1, uint256 yps_2) = _accruedYieldPerShare(gang);

        // userBalance <= max_yps < 1e24 < 2^80
        uint80 addBalance_0 = uint80((numSharesTimes100 * (yps_0 - fx().lastUserYieldPerShare[account][gang][0])) / 100);// forgefmt: disable-line
        uint80 addBalance_1 = uint80((numSharesTimes100 * (yps_1 - fx().lastUserYieldPerShare[account][gang][1])) / 100);// forgefmt: disable-line
        uint80 addBalance_2 = uint80((numSharesTimes100 * (yps_2 - fx().lastUserYieldPerShare[account][gang][2])) / 100);// forgefmt: disable-line

        s().userBalance[account][0] += addBalance_0;
        s().userBalance[account][1] += addBalance_1;
        s().userBalance[account][2] += addBalance_2;

        s().accruedBalances[account][0] += addBalance_0;
        s().accruedBalances[account][1] += addBalance_1;
        s().accruedBalances[account][2] += addBalance_2;

        fx().lastUserYieldPerShare[account][gang][0] = uint80(yps_0);
        fx().lastUserYieldPerShare[account][gang][1] = uint80(yps_1);
        fx().lastUserYieldPerShare[account][gang][2] = uint80(yps_2);
    }

    function _getUnclaimedUserBalance(address account) private view returns (uint256[3] memory out) {
        uint256 sharesFactor = 100 - gangVaultFeePercent;

        uint256 numSharesTimes100_0 = uint256(s().userShares[account][0]) * sharesFactor;
        uint256 numSharesTimes100_1 = uint256(s().userShares[account][1]) * sharesFactor;
        uint256 numSharesTimes100_2 = uint256(s().userShares[account][2]) * sharesFactor;

        uint256[3] memory balances_0 = _getUnclaimedUserBalance(0, account, numSharesTimes100_0);
        uint256[3] memory balances_1 = _getUnclaimedUserBalance(1, account, numSharesTimes100_1);
        uint256[3] memory balances_2 = _getUnclaimedUserBalance(2, account, numSharesTimes100_2);

        out[0] = balances_0[0] + balances_1[0] + balances_2[0];
        out[1] = balances_0[1] + balances_1[1] + balances_2[1];
        out[2] = balances_0[2] + balances_1[2] + balances_2[2];
    }

    function _getUnclaimedUserBalance(uint256 gang, address account, uint256 numSharesTimes100)
        private
        view
        returns (uint256[3] memory balances)
    {
        (uint256 yps_0, uint256 yps_1, uint256 yps_2) = _accruedYieldPerShare(gang);

        balances[0] = numSharesTimes100 * (yps_0 - fx().lastUserYieldPerShare[account][gang][0]) * 1e10 / 100;// forgefmt: disable-line
        balances[1] = numSharesTimes100 * (yps_1 - fx().lastUserYieldPerShare[account][gang][1]) * 1e10 / 100;// forgefmt: disable-line
        balances[2] = numSharesTimes100 * (yps_2 - fx().lastUserYieldPerShare[account][gang][2]) * 1e10 / 100;// forgefmt: disable-line
    }

    function _getUnclaimedGangBalance(uint256 gang) private view returns (uint256[3] memory balances) {
        address gangAccount = _getGangAccount(gang);
        uint256 totalShares = s().totalShares[gang];
        uint256 numSharesTimes100 = max(totalShares, 1) * gangVaultFeePercent;

        balances = _getUnclaimedUserBalance(gang, gangAccount, numSharesTimes100);
    }

    /* ------------- upgrade ------------- */

    function _authorizeUpgrade(address) internal view override onlyRole(DEFAULT_ADMIN_ROLE) {}
}

function max(uint256 a, uint256 b) pure returns (uint256) {
    return a < b ? b : a;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OwnableUDS} from "UDS/auth/OwnableUDS.sol";
import {UUPSUpgrade} from "UDS/proxy/UUPSUpgrade.sol";
import {ERC20BurnableUDS} from "UDS/tokens/extensions/ERC20BurnableUDS.sol";
import {AccessControlUDS} from "UDS/auth/AccessControlUDS.sol";

/// @title Gang Token
/// @author phaze (https://github.com/0xPhaze)
contract GangToken is UUPSUpgrade, OwnableUDS, ERC20BurnableUDS, AccessControlUDS {
    uint8 public constant override decimals = 18;

    bytes32 constant AUTHORITY = keccak256("AUTHORITY");

    function init(string calldata name_, string calldata symbol_) external initializer {
        __Ownable_init();
        __AccessControl_init();
        __ERC20_init(name_, symbol_, 18);
    }

    /* ------------- external ------------- */

    function mint(address user, uint256 amount) external onlyRole(AUTHORITY) {
        _mint(user, amount);
    }

    /* ------------- ERC20Burnable ------------- */

    function burnFrom(address from, uint256 amount) public override {
        if (msg.sender == from || hasRole(AUTHORITY, msg.sender)) _burn(from, amount);
        else super.burnFrom(from, amount);
    }

    /* ------------- owner ------------- */

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function airdrop(address[] calldata tos, uint256 amount) external onlyOwner {
        unchecked {
            for (uint256 i; i < tos.length; ++i) {
                _mint(tos[i], amount);
            }
        }
    }

    function airdrop(address[] calldata tos, uint256[] memory amounts) external onlyOwner {
        unchecked {
            for (uint256 i; i < tos.length; ++i) {
                _mint(tos[i], amounts[i]);
            }
        }
    }
}