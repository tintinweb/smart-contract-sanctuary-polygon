// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./libraries/SafeMathUpgradeable.sol";
import "./contracts/ContextUpgradeable.sol";
import "./contracts/OwnableUpgradeable.sol";
import "./contracts/Initializable.sol";
import "./interfaces/ICharityFactory.sol";
import "./Organization.sol";

contract CharityFactory is Initializable, ContextUpgradeable, ICharityFactory, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    IERC20 public charityToken;

    address[] public allOrganizations;
    mapping(address => address) public getOrganization;
    mapping(address => uint256) public organizationEthBalance;
    mapping(address => uint256) public organizationTokenBalance;

    uint256 public totalEthDonations;
    uint256 public totalTokenDonations;

    modifier validateSymbol(string calldata _symbol) {
        require(
            keccak256(abi.encodePacked(_symbol)) == keccak256(abi.encodePacked(charityToken.symbol())),
            "CharityFactory: Only CharityToken is allowed for ERC20 transacitons"
        );
        _;
    }

    modifier validateEthAmount() {
        require(msg.value > 0, "CharityFactory: Transfer amount has to be greater than 0.");
        _;
    }

    modifier validateAmount(uint256 _amount) {
        require(_amount > 0, "CharityFactory: Transfer amount has to be greater than 0.");
        _;
    }

    modifier validateOrganization(address _organizationOwner) {
        require(getOrganization[_organizationOwner] != address(0), "CharityFactory: Organization not found.");
        _;
    }

    function initialize(IERC20 _charityToken) public initializer {
        __Ownable_init();
        charityToken = _charityToken;
    }

    function createOrganization(
        address payable _orgOwner,
        string calldata _orgName,
        string calldata _orgDesc
    ) external onlyOwner returns (address) {
        require(getOrganization[_orgOwner] == address(0), "CharityFactory: ORGANIZATION_EXISTS");

        Organization organization = new Organization(charityToken, _orgOwner, _orgName, _orgDesc);

        getOrganization[_orgOwner] = address(organization);
        organizationEthBalance[address(organization)] = 0;
        organizationTokenBalance[address(organization)] = 0;
        allOrganizations.push(address(organization));

        emit OrganizationCreated(_orgOwner, address(organization), allOrganizations.length);

        return address(organization);
    }

    function allOrganizationsLength() external view returns (uint256) {
        return allOrganizations.length;
    }

    receive() external payable validateEthAmount {
        totalEthDonations += msg.value;
        _updateEthBalances(msg.value);
        emit Donation(msg.sender, msg.value, "MATIC", address(this));
    }

    function donateTokens(string calldata _symbol, uint256 _amount)
        external
        payable
        validateSymbol(_symbol)
        validateAmount(_amount)
    {
        charityToken.transferFrom(msg.sender, address(this), _amount);
        totalTokenDonations += _amount;
        _updateTokenBalances(_amount);
        emit Donation(msg.sender, _amount, charityToken.symbol(), address(this));
    }

    function _updateEthBalances(uint256 _amount) internal {
        uint256 _organizationAmount = _amount.div(allOrganizations.length);
        for (uint256 i = 0; i < allOrganizations.length; i++) {
            organizationEthBalance[allOrganizations[i]] += _organizationAmount;
        }
    }

    function _updateTokenBalances(uint256 _amount) internal {
        uint256 _organizationAmount = _amount.div(allOrganizations.length);
        for (uint256 i = 0; i < allOrganizations.length; i++) {
            organizationTokenBalance[allOrganizations[i]] += _organizationAmount;
        }
    }

    function ethBalance() external view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function tokenBalance(string calldata _symbol) external view onlyOwner validateSymbol(_symbol) returns (uint256) {
        return charityToken.balanceOf(address(this));
    }

    function withdrawEth(uint256 _amount) external payable validateOrganization(_msgSender()) validateAmount(_amount) {
        require(address(this).balance >= _amount);

        uint256 balance = organizationEthBalance[getOrganization[_msgSender()]];
        require(balance >= _amount);

        organizationEthBalance[getOrganization[_msgSender()]] -= _amount;
        payable(_msgSender()).transfer(_amount);
        emit Withdraw(_msgSender(), _amount, "MATIC", address(this));
    }

    function withdrawTokens(string calldata _symbol, uint256 _amount)
        external
        payable
        validateOrganization(_msgSender())
        validateSymbol(_symbol)
        validateAmount(_amount)
    {
        require(charityToken.balanceOf(address(this)) >= _amount);

        uint256 balance = organizationTokenBalance[getOrganization[_msgSender()]];
        require(balance >= _amount);

        organizationTokenBalance[getOrganization[_msgSender()]] -= _amount;
        charityToken.transfer(_msgSender(), _amount);
        emit Withdraw(_msgSender(), _amount, charityToken.symbol(), address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.12;

library SafeMathUpgradeable {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.12;

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.12;

library AddressUpgradeable {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
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

        (bool success, bytes memory returndata) = target.call{value: value}(data);
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

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./IERC20.sol";

interface IOrganization {
    event Donation(address indexed _from, uint256 _value, string _currency, address indexed _to);
    event Withdraw(address indexed _to, uint256 _value, string _currency, address indexed _from);

    function charityToken() external view returns (IERC20);

    function factory() external view returns (address);

    function name() external view returns (string memory);

    function description() external view returns (string memory);

    function totalEthDonations() external view returns (uint256);

    function totalTokenDonations() external view returns (uint256);

    // function initialize(
    //     address payable owner,
    //     string calldata name,
    //     string calldata desc
    // ) external;

    //function destroy() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./IERC20.sol";

interface ICharityFactory {
    event OrganizationCreated(address indexed organizationOwner, address organization, uint256 count);
    event Donation(address indexed _from, uint256 _value, string _currency, address indexed _to);
    event Withdraw(address indexed _to, uint256 _value, string _currency, address indexed _from);

    function charityToken() external view returns (IERC20);

    function getOrganization(address) external view returns (address);

    function organizationEthBalance(address) external view returns (uint256);

    function organizationTokenBalance(address) external view returns (uint256);

    function allOrganizations(uint256) external view returns (address);

    function allOrganizationsLength() external view returns (uint256);

    function totalEthDonations() external view returns (uint256);

    function totalTokenDonations() external view returns (uint256);

    function createOrganization(
        address payable owner,
        string calldata name,
        string calldata desc
    ) external returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.12;

import "./ContextUpgradeable.sol";
import "./Initializable.sol";

abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.12;

import "./Context.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.12;

import "../libraries/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) ||
                (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.12;

import "./Initializable.sol";

abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {}

    function __Context_init_unchained() internal onlyInitializing {}

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./libraries/SafeMath.sol";
import "./contracts/Context.sol";
import "./contracts/Ownable.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IOrganization.sol";

contract Organization is Context, IOrganization, Ownable {
    IERC20 public charityToken;

    address public factory;

    string public name;
    string public description;

    uint256 public totalEthDonations;
    uint256 public totalTokenDonations;

    modifier validateSymbol(string calldata _symbol) {
        require(
            keccak256(abi.encodePacked(_symbol)) == keccak256(abi.encodePacked(charityToken.symbol())),
            "Organization: Only CharityToken is allowed for ERC20 transacitons"
        );
        _;
    }

    modifier validateEthAmount() {
        require(msg.value > 0, "Organization: Transfer amount has to be greater than 0.");
        _;
    }

    modifier validateAmount(uint256 _amount) {
        require(_amount > 0, "Organization: Transfer amount has to be greater than 0.");
        _;
    }

    constructor(
        IERC20 _charityToken,
        address payable _owner,
        string memory _name,
        string memory _desc
    ) {
        transferOwnership(_owner);

        factory = _msgSender();
        charityToken = _charityToken;

        name = _name;
        description = _desc;
        totalEthDonations = 0;
        totalTokenDonations = 0;
    }

    receive() external payable validateEthAmount {
        totalEthDonations += msg.value;
        emit Donation(msg.sender, msg.value, "MATIC", address(this));
    }

    function donateTokens(string calldata _symbol, uint256 _amount)
        external
        validateSymbol(_symbol)
        validateAmount(_amount)
    {
        charityToken.transferFrom(msg.sender, address(this), _amount);

        totalTokenDonations += _amount;
        emit Donation(msg.sender, _amount, charityToken.symbol(), address(this));
    }

    function withdrawEth(uint256 _amount) external payable onlyOwner validateAmount(_amount) {
        payable(owner()).transfer(_amount);
        emit Withdraw(msg.sender, _amount, "MATIC", address(this));
    }

    function withdrawTokens(string calldata _symbol, uint256 _amount)
        external
        payable
        onlyOwner
        validateSymbol(_symbol)
        validateAmount(_amount)
    {
        charityToken.transfer(owner(), _amount);
        emit Withdraw(msg.sender, _amount, charityToken.symbol(), address(this));
    }

    function ethBalance() external view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function tokensBalance(string calldata _symbol) external view onlyOwner validateSymbol(_symbol) returns (uint256) {
        return charityToken.balanceOf(address(this));
    }
}