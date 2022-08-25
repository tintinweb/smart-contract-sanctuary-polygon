//SPDX-License-Identifier: GNU General Public License v2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Authority.sol";
import "./IPlatform.sol";
import "../structs/ExtensionDetail.sol";
import "../structs/RewardDetail.sol";
import "../structs/ProjectDetail.sol";
import "../structs/UserDetail.sol";
import "../extensions/IAgentExtension.sol";
import "./IPlatformToken.sol";
import "./IProject.sol";

contract Platform is
    Initializable,
    ContextUpgradeable,
    PausableUpgradeable,
    Authority,
    IPlatform
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    function initialize() external initializer {
        ContextUpgradeable.__Context_init();
        PausableUpgradeable.__Pausable_init();
        Authority.__Authority_init();
    }

    receive() external payable {}

    function _generateId() internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(_msgSender(), _msgData(), block.timestamp)
            );
    }

    // ===> PRIVATE METHODS
    mapping(bytes32 => ExtensionDetail) private _extensionDetails;

    event SetExtensionAddress(
        bytes32 indexed extension_,
        address indexed oldAddress_,
        address indexed newAddress_
    );
    event DefineExtension(bytes32 indexed extension_, address indexed address_);
    event UndefineExtension(bytes32 indexed extension_);

    function _defineExtension(bytes32 extension_, address address_) internal {
        _extensionDetails[extension_].existed = true;
        _setExtensionAddress(extension_, address_);
        emit DefineExtension(extension_, address_);
    }

    function _undefineExtension(bytes32 extension_) internal {
        delete _extensionDetails[extension_];
        emit UndefineExtension(extension_);
    }

    function _setExtensionAddress(bytes32 extension_, address address_)
        internal
    {
        address oldAddress = _extensionDetails[extension_].contractAddress;
        _extensionDetails[extension_].contractAddress = address_;
        emit SetExtensionAddress(extension_, oldAddress, address_);
    }

    function _extension(bytes32 extension_)
        internal
        view
        returns (ExtensionDetail storage)
    {
        return _extensionDetails[extension_];
    }

    address private _defaultToken;
    mapping(address => uint256) private _rewardRates;
    mapping(address => mapping(address => RewardDetail)) private _rewardDetails;

    event SetDefaultToken(address indexed oldToken_, address indexed newToken_);
    event SetRewardRate(address indexed token_, uint256 indexed percent_);
    event Mint(address indexed token_, uint256 amount_);
    event Burn(address indexed token_, uint256 amount_);
    event Transfer(
        address indexed token_,
        address[] receivers_,
        uint256[] amounts_
    );
    event IncreaseReward(
        address indexed token_,
        address indexed user_,
        uint256 amount_
    );
    event DecreaseReward(
        address indexed token_,
        address indexed user_,
        uint256 amount_
    );
    event ClaimReward(
        address indexed token_,
        address indexed user_,
        uint256 amount_
    );

    function _setDefaultToken(address token_) internal {
        require(
            token_ != _defaultToken,
            "the new token is must different from the old one"
        );
        address oldToken = _defaultToken;
        _defaultToken = token_;
        emit SetDefaultToken(oldToken, token_);
    }

    function _balanceOf(address token_) internal view returns (uint256) {
        if (token_ == address(0x0)) return address(this).balance;
        else return IERC20(token_).balanceOf(address(this));
    }

    function _mint(uint256 amount_) internal {
        require(_defaultToken != address(0x0), "0x0 can not be mint");
        IPlatformToken(_defaultToken).mint(address(this), amount_);
        emit Mint(_defaultToken, amount_);
    }

    function _burn(uint256 amount_) internal {
        require(_defaultToken != address(0x0), "0x0 can not be mint");
        IPlatformToken(_defaultToken).burn(address(this), amount_);
        emit Burn(_defaultToken, amount_);
    }

    function _transfer(
        address token_,
        address[] memory receivers_,
        uint256[] memory amounts_
    ) internal {
        require(
            receivers_.length == amounts_.length,
            "the length of users is different from the length of amounts"
        );
        for (uint256 i = 0; i < receivers_.length; i++) {
            if (token_ == address(0x0))
                payable(receivers_[i]).transfer(amounts_[i]);
            else IERC20(token_).transfer(receivers_[i], amounts_[i]);
        }
        emit Transfer(token_, receivers_, amounts_);
    }

    function _setRewardRate(address token_, uint256 percent_) internal {
        require(percent_ < 10000, "the value is must between 0 and 10000");
        _rewardRates[token_] = percent_;
        emit SetRewardRate(token_, percent_);
    }

    function _increaseReward(
        address token_,
        address user_,
        uint256 amount_
    ) internal {
        _rewardDetails[user_][token_].total += amount_;
        _rewardDetails[user_][token_].balance += amount_;
        emit IncreaseReward(token_, user_, amount_);
    }

    function _decreaseReward(
        address token_,
        address user_,
        uint256 amount_
    ) internal {
        require(
            _rewardOf(user_)[token_].balance >= amount_,
            "the reward balance is less then the amount"
        );
        _rewardDetails[user_][token_].total -= amount_;
        _rewardDetails[user_][token_].balance -= amount_;
        emit DecreaseReward(token_, user_, amount_);
    }

    function _claimReward(
        address token_,
        address user_,
        uint256 amount_
    ) internal {
        require(
            _rewardOf(user_)[token_].balance >= amount_,
            "the Reward balance is less then the amount"
        );
        _rewardDetails[user_][token_].balance -= amount_;
        emit ClaimReward(token_, user_, amount_);
    }

    function _rewardOf(address user_)
        internal
        view
        returns (mapping(address => RewardDetail) storage)
    {
        return _rewardDetails[user_];
    }

    mapping(address => ProjectDetail) private _projectDetails;

    event AddProject(address indexed project_);
    event RemoveProject(address indexed project_);
    event Pay(
        address indexed project_,
        bytes32 indexed id_,
        address token_,
        address indexed user_,
        uint256 amount_
    );
    event Distribute(
        address indexed project_,
        bytes32 indexed id_,
        address token_,
        address[] indexed users_,
        uint256[] amounts_
    );
    event Settle(
        address indexed project_,
        bytes32 indexed id_,
        address token_,
        address user_,
        uint256 amount_
    );

    function _projectExisted(address project_) internal view returns (bool) {
        return _projectDetails[project_].existed;
    }

    function _addProject(address project_, uint256 feeRate_) internal {
        _projectDetails[project_].existed = true;
        _setProjectFeeRate(project_, feeRate_);
        emit AddProject(project_);
    }

    function _removeProject(address project_) internal {
        delete _projectDetails[project_];
        emit RemoveProject(project_);
    }

    function _setProjectFeeRate(address project_, uint256 feeRate_) internal {
        require(
            feeRate_ < 10000,
            "the fee rate is must between from 0 and 10000"
        );
        _projectDetails[project_].feeRate = feeRate_;
    }

    function _project(address project_)
        internal
        view
        returns (IProject instance_, ProjectDetail storage detail_)
    {
        return (IProject(project_), _projectDetails[project_]);
    }

    function _realAmountByProjectFeeRate(address project_, uint256 amount_)
        internal
        view
        returns (uint256)
    {
        (, ProjectDetail storage detail) = _project(project_);
        return
            detail.feeRate == 0
                ? amount_
                : (amount_ * (10000 - detail.feeRate)) / 10000;
    }

    function _pay(
        address project_,
        bytes32 id_,
        address user_,
        uint256 amount_
    ) internal {
        (IProject instance, ) = _project(project_);
        address projectToken = instance.token();
        if (projectToken == address(0x0)) {
            require(
                msg.value == amount_,
                "the eth value is must equal to the amount"
            );
        } else IERC20(projectToken).transferFrom(user_, address(this), amount_);
        _projectDetails[project_].total[projectToken] += amount_;
        _projectDetails[project_].balance[projectToken] += amount_;
        IAgentExtension(
            _extension(keccak256("EXTENSION_AGENT")).contractAddress
        ).pay(projectToken, user_, amount_);
        emit Pay(project_, id_, projectToken, user_, amount_);
    }

    function _distribute(
        address project_,
        bytes32 id_,
        address[] memory users_,
        uint256[] memory amounts_
    ) internal {
        require(
            users_.length == amounts_.length,
            "the length of users is different from the length of amounts"
        );
        (IProject instance, ProjectDetail storage detail) = _project(project_);
        address projectToken = instance.token();
        uint256 total;
        uint256[] memory realAmounts = new uint256[](users_.length);
        for (uint256 i = 0; i < users_.length; i++) {
            detail.balance[projectToken] -= amounts_[i];
            realAmounts[i] = _realAmountByProjectFeeRate(project_, amounts_[i]);
            total += amounts_[i];
        }
        require(
            detail.balance[projectToken] >= total,
            "the balance is less then the total"
        );
        for (uint256 i = 0; i < users_.length; i++)
            _increaseReward(projectToken, users_[i], realAmounts[i]);
        emit Distribute(project_, id_, projectToken, users_, amounts_);
    }

    function _settle(
        address project_,
        bytes32 id_,
        address token_
    ) internal {
        (IProject instance, ProjectDetail storage detail) = _project(project_);
        address beneficiary = instance.beneficiary();
        require(detail.balance[token_] >= 0, "the balance is less then zero");
        uint256 realAmount = _realAmountByProjectFeeRate(
            project_,
            detail.balance[token_]
        );
        detail.balance[token_] = 0;
        _increaseReward(token_, beneficiary, realAmount);
        emit Settle(project_, id_, token_, beneficiary, detail.balance[token_]);
    }

    mapping(address => UserDetail) private _userDetails;

    event AddBlocklist(address indexed user_);
    event RemoveBlocklist(address indexed user_);

    function _addBlocklist(address user_) internal {
        _userDetails[user_].blocked = true;
        emit AddBlocklist(user_);
    }

    function _removeBlocklist(address user_) internal {
        _userDetails[user_].blocked = false;
        emit RemoveBlocklist(user_);
    }

    // <=== PRIVATE METHODS

    // ===> MODIFIER
    modifier onlyExtensionDefined(bytes32 extension_) {
        require(_extension(extension_).existed, "the extension is not defined");
        _;
    }

    modifier onlyExtensionNotDefined(bytes32 extension_) {
        require(
            !_extension(extension_).existed,
            "the extension is already defined"
        );
        _;
    }

    modifier onlyWellFunded(address token_, uint256 amount_) {
        require(
            _balanceOf(token_) >= amount_,
            "the fund of platform is not enough"
        );
        _;
    }

    modifier onlyProjectExist(address project_) {
        require(_projectExisted(project_), "the project is not existed");
        _;
    }

    modifier onlyProjectNotExist(address project_) {
        require(!_projectExisted(project_), "the project is already existed");
        _;
    }

    modifier onlyUserBlocked(address user_) {
        require(_userDetails[user_].blocked, "the user is not blocked");
        _;
    }

    modifier onlyUserNotBlocked(address user_) {
        require(!_userDetails[user_].blocked, "the user is already blocked");
        _;
    }

    // <=== MODIFIER

    // ===> PUBLIC METHODS
    function pause()
        external
        override
        onlyHasAuthority(AUTHORITY_SUPER, _msgSender())
    {
        PausableUpgradeable._pause();
    }

    function unpause()
        external
        override
        onlyHasAuthority(AUTHORITY_SUPER, _msgSender())
    {
        PausableUpgradeable._unpause();
    }

    function defineExtension(bytes32 extension_, address address_)
        external
        override
        onlyHasAuthority(AUTHORITY_SUPER, _msgSender())
        onlyExtensionNotDefined(extension_)
    {
        _defineExtension(extension_, address_);
    }

    function undefineExtension(bytes32 extension_)
        external
        override
        onlyHasAuthority(AUTHORITY_SUPER, _msgSender())
        onlyExtensionDefined(extension_)
    {
        _undefineExtension(extension_);
    }

    function setExtensionAddress(bytes32 extension_, address address_)
        external
        override
        onlyHasAuthority(AUTHORITY_SUPER, _msgSender())
        onlyExtensionDefined(extension_)
    {
        _setExtensionAddress(extension_, address_);
    }

    function transferExtensionOwnership(bytes32 extension_, address newOwner_)
        external
        override
        onlyHasAuthority(AUTHORITY_SUPER, _msgSender())
        onlyExtensionDefined(extension_)
    {
        Ownable(_extension(extension_).contractAddress).transferOwnership(
            newOwner_
        );
    }

    function extensionDefined(bytes32 extension_)
        external
        view
        override
        returns (bool)
    {
        return _extension(extension_).existed;
    }

    function extension(bytes32 extension_)
        external
        view
        override
        onlyExtensionDefined(extension_)
        returns (address)
    {
        return _extension(extension_).contractAddress;
    }

    function setDefaultToken(address token_)
        external
        override
        onlyHasAuthority(keccak256("MANAGE_FUND"), _msgSender())
    {
        _setDefaultToken(token_);
    }

    function transferDefaultTokenOwnership(address newOwner_)
        external
        override
        onlyHasAuthority(keccak256("MANAGE_FUND"), _msgSender())
    {
        Ownable(_defaultToken).transferOwnership(newOwner_);
    }

    function defaultToken() external view override returns (address) {
        return _defaultToken;
    }

    function balanceOf(address token_)
        external
        view
        override
        returns (uint256)
    {
        return _balanceOf(token_);
    }

    function mint(uint256 amount_)
        external
        override
        onlyHasAuthority(keccak256("MANAGE_FUND"), _msgSender())
    {
        _mint(amount_);
    }

    function burn(uint256 amount_)
        external
        override
        onlyHasAuthority(keccak256("MANAGE_FUND"), _msgSender())
    {
        _burn(amount_);
    }

    function transfer(
        address token_,
        address[] memory receivers_,
        uint256[] memory amounts_
    )
        external
        override
        onlyHasAuthority(keccak256("MANAGE_FUND"), _msgSender())
    {
        _transfer(token_, receivers_, amounts_);
    }

    function setRewardRate(address token_, uint256 percent_)
        external
        override
        onlyHasAuthority(keccak256("MANAGE_FUND"), _msgSender())
    {
        _setRewardRate(token_, percent_);
    }

    function rewardRate(address token_)
        external
        view
        override
        returns (uint256)
    {
        return _rewardRates[token_];
    }

    function increaseReward(
        address token_,
        address user_,
        uint256 amount_
    )
        external
        override
        onlyHasAuthority(keccak256("MANAGE_FUND"), _msgSender())
    {
        _increaseReward(token_, user_, amount_);
    }

    function decreaseReward(
        address token_,
        address user_,
        uint256 amount_
    )
        external
        override
        onlyHasAuthority(keccak256("MANAGE_FUND"), _msgSender())
    {
        _decreaseReward(token_, user_, amount_);
    }

    function claimReward(address token_, uint256 amount_)
        external
        override
        whenNotPaused
        onlyUserNotBlocked(_msgSender())
    {
        _claimReward(_msgSender(), token_, amount_);
        address[] memory tos = new address[](1);
        tos[0] = _msgSender();
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount_;
        _transfer(token_, tos, amounts);
    }

    function rewardOf(address token_, address user_)
        external
        view
        override
        returns (uint256 total_, uint256 balance_)
    {
        return (
            _rewardOf(user_)[token_].total,
            _rewardOf(user_)[token_].balance
        );
    }

    function addProject(address project_, uint256 feeRate_)
        external
        override
        onlyHasAuthority(keccak256("MANAGE_PROJECT"), _msgSender())
        onlyProjectNotExist(project_)
    {
        _addProject(project_, feeRate_);
    }

    function removeProject(address project_)
        external
        override
        onlyHasAuthority(keccak256("MANAGE_PROJECT"), _msgSender())
        onlyProjectExist(project_)
    {
        _removeProject(project_);
    }

    function setProjectFeeRate(address project_, uint256 feeRate_)
        external
        override
        onlyHasAuthority(keccak256("MANAGE_PROJECT"), _msgSender())
        onlyProjectExist(project_)
    {
        _setProjectFeeRate(project_, feeRate_);
    }

    function transferProjectOwnership(address project_, address newOwner_)
        external
        override
        onlyHasAuthority(keccak256("MANAGE_PROJECT"), _msgSender())
        onlyProjectExist(project_)
    {
        Ownable(project_).transferOwnership(newOwner_);
    }

    function projectExisted(address project_)
        external
        view
        override
        returns (bool)
    {
        return _projectExisted(project_);
    }

    function project(address project_)
        external
        view
        override
        onlyProjectExist(project_)
        returns (
            address beneficiary_,
            string memory downloadUrl_,
            uint256 feeRate_
        )
    {
        (IProject instance, ProjectDetail storage detail) = _project(project_);
        return (instance.beneficiary(), instance.downloadUrl(), detail.feeRate);
    }

    function projectFundOf(address project_, address token_)
        external
        view
        override
        onlyProjectExist(project_)
        returns (uint256 total_, uint256 balance_)
    {
        (, ProjectDetail storage detail) = _project(project_);
        return (detail.total[token_], detail.balance[token_]);
    }

    function pay(
        bytes32 id_,
        address user_,
        uint256 amount_
    ) external payable override onlyProjectExist(_msgSender()) {
        _pay(_msgSender(), id_, user_, amount_);
    }

    function distribute(
        bytes32 id_,
        address[] calldata users_,
        uint256[] calldata amounts_
    ) external override onlyProjectExist(_msgSender()) {
        _distribute(_msgSender(), id_, users_, amounts_);
    }

    function settle(bytes32 id_, address token_)
        external
        override
        onlyProjectExist(_msgSender())
    {
        _settle(_msgSender(), id_, token_);
    }

    function addBlocklist(address user_)
        external
        override
        onlyHasAuthority(keccak256("MANAGE_USER"), _msgSender())
        onlyUserNotBlocked(user_)
    {
        _addBlocklist(user_);
    }

    function removeBlocklist(address user_)
        external
        override
        onlyHasAuthority(keccak256("MANAGE_USER"), _msgSender())
        onlyUserBlocked(user_)
    {
        _removeBlocklist(user_);
    }

    function isBlocked(address user_) external view override returns (bool) {
        return _userDetails[user_].blocked;
    }

    function bind(address agent_)
        external
        override
        whenNotPaused
        onlyUserNotBlocked(_msgSender())
    {
        IAgentExtension(
            _extension(keccak256("EXTENSION_AGENT")).contractAddress
        ).bind(agent_, _msgSender());
    }

    function agent(address user_) external view override returns (address) {
        return
            IAgentExtension(
                _extension(keccak256("EXTENSION_AGENT")).contractAddress
            ).agent(user_);
    }

    function agentCount(address agent_)
        external
        view
        override
        returns (uint256)
    {
        return
            IAgentExtension(
                _extension(keccak256("EXTENSION_AGENT")).contractAddress
            ).agentCount(agent_);
    }

    function userFundFlow(address user_, address token_)
        external
        view
        override
        returns (uint256)
    {
        return
            IAgentExtension(
                _extension(keccak256("EXTENSION_AGENT")).contractAddress
            ).userFundFlow(user_, token_);
    }

    function agentFundFlow(address user_, address token_)
        external
        view
        override
        returns (uint256)
    {
        return
            IAgentExtension(
                _extension(keccak256("EXTENSION_AGENT")).contractAddress
            ).agentFundFlow(user_, token_);
    }

    // <=== PUBLIC METHODS
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableMap.sol)

pragma solidity ^0.8.0;

import "./EnumerableSet.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32`) since v4.6.0
 */
library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Bytes32ToBytes32Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        bytes32 value
    ) internal returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToBytes32Map storage map, bytes32 key) internal returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Bytes32ToBytes32Map storage map) internal view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToBytes32Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function get(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), errorMessage);
        return value;
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key), errorMessage))));
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        AddressToUintMap storage map,
        address key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        AddressToUintMap storage map,
        address key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key))), errorMessage));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

//SPDX-License-Identifier: GNU General Public License v2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./IAuthority.sol";
import "../structs/AuthorityDetail.sol";

abstract contract Authority is Initializable, ContextUpgradeable, IAuthority {
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant AUTHORITY_SUPER = keccak256("SUPER");
    mapping(bytes32 => AuthorityDetail) private _authorityDetails;

    event SetAdminAuthority(
        bytes32 indexed authority_,
        bytes32 indexed oldAdminAuthority_,
        bytes32 indexed newAdminAuthority_
    );
    event DefineAuthority(
        bytes32 indexed authority_,
        bytes32 indexed adminAuthority_
    );
    event UndefineAuthority(bytes32 indexed authority_);
    event AddAuthority(bytes32 indexed authority_, address indexed user_);
    event RemoveAuthority(bytes32 indexed authority_, address indexed user_);

    function __Authority_init() internal onlyInitializing {
        __Authority_init_unchained();
    }

    function __Authority_init_unchained() internal onlyInitializing {
        _defineAuthority(AUTHORITY_SUPER);
        _addAuthority(AUTHORITY_SUPER, _msgSender());
    }

    // ===> PRIVATE METHODS
    function _defineAuthority(bytes32 authority_) internal {
        _authorityDetails[authority_].existed = true;
        emit DefineAuthority(
            authority_,
            _authorityDetails[authority_].adminAuthority
        );
    }

    function _defineAuthority(bytes32 authority_, bytes32 adminAuthority_)
        internal
    {
        require(
            authority_ != adminAuthority_,
            "the authorities are must different"
        );
        _authorityDetails[authority_].existed = true;
        _setAdminAuthority(authority_, adminAuthority_);
        emit DefineAuthority(
            authority_,
            _authorityDetails[authority_].adminAuthority
        );
    }

    function _undefineAuthority(bytes32 authority_) internal {
        _authorityDetails[authority_].existed = false;
        address[] memory mumbers = _authorityDetails[authority_]
            .mumbers
            .values();
        for (uint256 i = 0; i < mumbers.length; i++) {
            _authorityDetails[authority_].mumbers.remove(mumbers[i]);
        }
        emit UndefineAuthority(authority_);
    }

    function _setAdminAuthority(bytes32 authority_, bytes32 adminAuthority_)
        internal
    {
        bytes32 oldAdminAuthority = _authorityDetails[authority_]
            .adminAuthority;
        require(
            oldAdminAuthority != adminAuthority_,
            "the authorities are must different"
        );
        _authorityDetails[authority_].adminAuthority = adminAuthority_;
        emit SetAdminAuthority(authority_, oldAdminAuthority, adminAuthority_);
    }

    function _authority(bytes32 authority_)
        internal
        view
        returns (AuthorityDetail storage)
    {
        return _authorityDetails[authority_];
    }

    function _addAuthority(bytes32 authority_, address user_) internal {
        _authorityDetails[authority_].mumbers.add(user_);
        emit AddAuthority(authority_, user_);
    }

    function _removeAuthority(bytes32 authority_, address user_) internal {
        _authorityDetails[authority_].mumbers.remove(user_);
        emit RemoveAuthority(authority_, user_);
    }

    function _hasAuthority(bytes32 authority_, address user_)
        internal
        view
        returns (bool)
    {
        if (!_authority(authority_).existed) return false;
        bool result = _authorityDetails[authority_].mumbers.contains(user_);
        if (
            !result &&
            _authorityDetails[authority_].adminAuthority != bytes32(0x0)
        ) {
            result = _hasAuthority(
                _authorityDetails[authority_].adminAuthority,
                user_
            );
        }
        return result;
    }

    // <=== PRIVATE METHODS

    // ===> MODIFIER
    modifier onlyAuthorityDefined(bytes32 authority_) {
        require(_authority(authority_).existed, "the authority is not defined");
        _;
    }

    modifier onlyAuthorityNotDefined(bytes32 authority_) {
        require(
            !_authority(authority_).existed,
            "the authority is already defined"
        );
        _;
    }

    modifier onlyHasAuthority(bytes32 authority_, address user_) {
        require(
            _hasAuthority(authority_, user_),
            "the user does not have the authority"
        );
        _;
    }

    modifier onlyHasNotAuthority(bytes32 authority_, address user_) {
        require(
            !_hasAuthority(authority_, user_),
            "the user already has the authority"
        );
        _;
    }

    // <=== MODIFIER

    // ===> PUBLIC METHODS
    function defineAuthority(bytes32 authority_)
        external
        override
        onlyHasAuthority(AUTHORITY_SUPER, _msgSender())
        onlyAuthorityNotDefined(authority_)
    {
        _defineAuthority(authority_, AUTHORITY_SUPER);
    }

    function defineAuthority(bytes32 authority_, bytes32 adminAuthority_)
        external
        override
        onlyHasAuthority(AUTHORITY_SUPER, _msgSender())
        onlyAuthorityNotDefined(authority_)
    {
        _defineAuthority(authority_, adminAuthority_);
    }

    function undefineAuthority(bytes32 authority_)
        external
        override
        onlyHasAuthority(AUTHORITY_SUPER, _msgSender())
        onlyAuthorityDefined(authority_)
    {
        _undefineAuthority(authority_);
    }

    function setAdminAuthority(bytes32 authority_, bytes32 adminAuthority_)
        external
        override
        onlyHasAuthority(AUTHORITY_SUPER, _msgSender())
        onlyAuthorityDefined(authority_)
    {
        _setAdminAuthority(authority_, adminAuthority_);
    }

    function authorityDefined(bytes32 authority_)
        external
        view
        override
        returns (bool)
    {
        return _authority(authority_).existed;
    }

    function authority(bytes32 authority_)
        external
        view
        override
        onlyAuthorityDefined(authority_)
        returns (bytes32 adminAuthority_, address[] memory mumbers)
    {
        return (
            _authority(authority_).adminAuthority,
            _authority(authority_).mumbers.values()
        );
    }

    function addAuthority(bytes32 authority_, address user_)
        external
        override
        onlyHasAuthority(AUTHORITY_SUPER, _msgSender())
        onlyAuthorityDefined(authority_)
        onlyHasNotAuthority(authority_, user_)
    {
        _addAuthority(authority_, user_);
    }

    function removeAuthority(bytes32 authority_, address user_)
        external
        override
        onlyHasAuthority(AUTHORITY_SUPER, _msgSender())
        onlyAuthorityDefined(authority_)
        onlyHasAuthority(authority_, user_)
    {
        _removeAuthority(authority_, user_);
    }

    function hasAuthority(bytes32 authority_, address user_)
        external
        view
        override
        returns (bool)
    {
        return _hasAuthority(authority_, user_);
    }
    // <=== PUBLIC METHODS
}

//SPDX-License-Identifier: GNU General Public License v2.0
pragma solidity ^0.8.0;

interface IPlatform {
    function pause() external;

    function unpause() external;

    function defineExtension(bytes32 extension_, address address_) external;

    function undefineExtension(bytes32 extension_) external;

    function setExtensionAddress(bytes32 extension_, address address_) external;

    function transferExtensionOwnership(bytes32 extension_, address newOwner_)
        external;

    function extensionDefined(bytes32 extension_) external view returns (bool);

    function extension(bytes32 extension_) external view returns (address);

    function setDefaultToken(address token_) external;

    function transferDefaultTokenOwnership(address newOwner_) external;

    function defaultToken() external view returns (address);

    function balanceOf(address token_) external view returns (uint256);

    function mint(uint256 amount_) external;

    function burn(uint256 amount_) external;

    function transfer(
        address token_,
        address[] memory receivers_,
        uint256[] memory amounts_
    ) external;

    function setRewardRate(address token_, uint256 percent_) external;

    function rewardRate(address token_) external view returns (uint256);

    function increaseReward(
        address token_,
        address user_,
        uint256 amount_
    ) external;

    function decreaseReward(
        address token_,
        address user_,
        uint256 amount_
    ) external;

    function claimReward(address token_, uint256 amount_) external;

    function rewardOf(address token_, address user_)
        external
        view
        returns (uint256 total_, uint256 balance_);

    function addProject(address project_, uint256 feeRate_) external;

    function removeProject(address project_) external;

    function setProjectFeeRate(address project_, uint256 feeRate_) external;

    function transferProjectOwnership(address project_, address newOwner_)
        external;

    function projectExisted(address project_) external view returns (bool);

    function project(address project_)
        external
        view
        returns (
            address beneficiary_,
            string calldata downloadUrl_,
            uint256 feeRate_
        );

    function projectFundOf(address project_, address token_)
        external
        view
        returns (uint256 total_, uint256 balance_);

    function pay(
        bytes32 id_,
        address user_,
        uint256 amount_
    ) external payable;

    function distribute(
        bytes32 id_,
        address[] calldata users_,
        uint256[] calldata amounts_
    ) external;

    function settle(bytes32 id_, address token_) external;

    function addBlocklist(address user_) external;

    function removeBlocklist(address user_) external;

    function isBlocked(address user_) external view returns (bool);

    function bind(address inviter_) external;

    function agent(address user_) external view returns (address);

    function agentCount(address inviter_) external view returns (uint256);

    function userFundFlow(address token_, address user_)
        external
        view
        returns (uint256);

    function agentFundFlow(address agent_, address token_)
        external
        view
        returns (uint256);
}

//SPDX-License-Identifier: GNU General Public License v2.0
pragma solidity ^0.8.0;

struct ExtensionDetail {
    bool existed;
    address contractAddress;
}

//SPDX-License-Identifier: GNU General Public License v2.0
pragma solidity ^0.8.0;

struct RewardDetail {
    uint256 total;
    uint256 balance;
}

//SPDX-License-Identifier: GNU General Public License v2.0
pragma solidity ^0.8.0;

struct ProjectDetail {
    bool existed;
    uint256 feeRate;
    mapping(address => uint256) total;
    mapping(address => uint256) balance;
}

//SPDX-License-Identifier: GNU General Public License v2.0
pragma solidity ^0.8.0;

struct UserDetail {
    bool blocked;
}

//SPDX-License-Identifier: GNU General Public License v2.0
pragma solidity ^0.8.0;

interface IAgentExtension {
    function bind(address user_, address agent_) external;

    function agent(address user_) external view returns (address);

    function agentCount(address agent_) external view returns (uint256);

    function pay(
        address user_,
        address token_,
        uint256 amount_
    ) external;

    function userFundFlow(address user_, address token_)
        external
        view
        returns (uint256);

    function agentFundFlow(address agent_, address token_)
        external
        view
        returns (uint256);
}

//SPDX-License-Identifier: GNU General Public License v2.0
pragma solidity ^0.8.0;

interface IPlatformToken {
    function mint(address account_, uint256 amount_) external;

    function burn(address account_, uint256 amount_) external;
}

//SPDX-License-Identifier: GNU General Public License v2.0
pragma solidity ^0.8.0;

interface IProject {
    function platform() external view returns (address);

    function token() external view returns (address);

    function beneficiary() external view returns (address);

    function downloadUrl() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
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

//SPDX-License-Identifier: GNU General Public License v2.0
pragma solidity ^0.8.0;

interface IAuthority {
    function defineAuthority(bytes32 authority_, bytes32 adminAuthority_)
        external;

    function defineAuthority(bytes32 authority_) external;

    function undefineAuthority(bytes32 authority_) external;

    function setAdminAuthority(bytes32 authority_, bytes32 adminAuthority_)
        external;

    function authorityDefined(bytes32 authority_) external view returns (bool);

    function authority(bytes32 authority_)
        external
        view
        returns (bytes32 adminAuthority_, address[] memory mumbers);

    function addAuthority(bytes32 authority_, address user_) external;

    function removeAuthority(bytes32 authority_, address user_) external;

    function hasAuthority(bytes32 authority_, address user_)
        external
        view
        returns (bool);
}

//SPDX-License-Identifier: GNU General Public License v2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

struct AuthorityDetail {
    bool existed;
    bytes32 adminAuthority;
    EnumerableSet.AddressSet mumbers;
}