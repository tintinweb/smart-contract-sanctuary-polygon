//SPDX-License-Identifier: GNU General Public License v2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./structs/AuthorityDetail.sol";
import "./structs/ExtensionDetail.sol";
import "./structs/UserDetail.sol";
import "./structs/RewardDetail.sol";
import "./extensions/IAgentExtension.sol";
import "./extensions/IProjectExtension.sol";
import "./IPlatform.sol";
import "./IColony3Token.sol";

contract Platform is
    Initializable,
    ContextUpgradeable,
    PausableUpgradeable,
    IPlatform
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    function initialize(address superUser_) external initializer {
        ContextUpgradeable.__Context_init();
        PausableUpgradeable.__Pausable_init();

        _defineAuthority(AUTHORITY_SUPER, bytes32(0x0));
        _addAuthority(AUTHORITY_SUPER, superUser_);
    }

    receive() external payable {}

    // ===> PRIVATE METHODS
    // COMMON
    function _generateId() internal view returns (bytes32) {
        return keccak256(abi.encode(_msgSender(), _msgData(), block.timestamp));
    }

    // AUTHORITY
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

    function _authorityDefined(bytes32 authority_)
        internal
        view
        returns (bool)
    {
        return _authorityDetails[authority_].existed;
    }

    modifier onlyAuthorityDefined(bytes32 authority_) {
        require(_authorityDefined(authority_), "the authority is not defined");
        _;
    }

    modifier onlyAuthorityNotDefined(bytes32 authority_) {
        require(
            !_authorityDefined(authority_),
            "the authority is already defined"
        );
        _;
    }

    function _setAdminAuthority(bytes32 authority_, bytes32 adminAuthority_)
        internal
        onlyAuthorityDefined(authority_)
    {
        bytes32 oldAdminAuthority = _authorityDetails[authority_]
            .adminAuthority;
        _authorityDetails[authority_].adminAuthority = adminAuthority_;
        emit SetAdminAuthority(authority_, oldAdminAuthority, adminAuthority_);
    }

    function _defineAuthority(bytes32 authority_, bytes32 adminAuthority_)
        internal
        onlyAuthorityNotDefined(authority_)
    {
        require(
            authority_ != adminAuthority_,
            "the authorities are must different"
        );
        _authorityDetails[authority_].existed = true;
        _setAdminAuthority(authority_, adminAuthority_);
        emit DefineAuthority(authority_, adminAuthority_);
    }

    function _undefineAuthority(bytes32 authority_)
        internal
        onlyAuthorityDefined(authority_)
    {
        _authorityDetails[authority_].existed = false;
        address[] memory mumbers = _authorityDetails[authority_]
            .mumbers
            .values();
        for (uint256 i = 0; i < mumbers.length; i++) {
            _authorityDetails[authority_].mumbers.remove(mumbers[i]);
        }
        emit UndefineAuthority(authority_);
    }

    function _hasAuthority(bytes32 authority_, address user_)
        internal
        view
        returns (bool)
    {
        if (!_authorityDefined(authority_)) return false;
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

    function _addAuthority(bytes32 authority_, address user_)
        internal
        onlyAuthorityDefined(authority_)
        onlyHasNotAuthority(authority_, user_)
    {
        _authorityDetails[authority_].mumbers.add(user_);
        emit AddAuthority(authority_, user_);
    }

    function _removeAuthority(bytes32 authority_, address user_)
        internal
        onlyAuthorityDefined(authority_)
        onlyHasAuthority(authority_, user_)
    {
        _authorityDetails[authority_].mumbers.remove(user_);
        emit RemoveAuthority(authority_, user_);
    }

    // EXTENSION
    mapping(bytes32 => ExtensionDetail) _extensionDetails;

    event SetExtensionContractAddress(
        bytes32 indexed extension_,
        address indexed oldContractAddress_,
        address indexed newContractAddress_
    );

    event DefineExtension(
        bytes32 indexed extension_,
        address indexed contractAddress_
    );

    event UndefineExtension(bytes32 indexed extension_);

    function _extensionDefined(bytes32 extension_)
        internal
        view
        returns (bool)
    {
        return _extensionDetails[extension_].existed;
    }

    modifier onlyExtensionDefined(bytes32 extension_) {
        require(_extensionDefined(extension_), "the extension is not defined");
        _;
    }

    modifier onlyExtensionNotDefined(bytes32 extension_) {
        require(
            !_extensionDefined(extension_),
            "the extension is already defined"
        );
        _;
    }

    function _setExtensionContractAddress(
        bytes32 extension_,
        address contractAddress_
    ) internal onlyExtensionDefined(extension_) {
        address oldContractAddress = _extensionDetails[extension_]
            .contractAddress;
        _extensionDetails[extension_].contractAddress = contractAddress_;
        emit SetExtensionContractAddress(
            extension_,
            oldContractAddress,
            contractAddress_
        );
    }

    function _defineExtension(bytes32 extension_, address contractAddress_)
        internal
        onlyExtensionNotDefined(extension_)
    {
        _extensionDetails[extension_].existed = true;
        _setExtensionContractAddress(extension_, contractAddress_);
        emit DefineExtension(extension_, contractAddress_);
    }

    function _undefineExtension(bytes32 extension_)
        internal
        onlyExtensionDefined(extension_)
    {
        delete _extensionDetails[extension_];
        emit UndefineExtension(extension_);
    }

    function _getExtension(bytes32 extension_)
        internal
        view
        onlyExtensionDefined(extension_)
        returns (ExtensionDetail storage)
    {
        return _extensionDetails[extension_];
    }

    // USER
    mapping(address => UserDetail) _userDetails;

    event Register(address indexed user_);
    event AddBlocklist(address indexed user_);
    event RemoveBlocklist(address indexed user_);

    function _userRegistered(address user_) internal view returns (bool) {
        return _userDetails[user_].existed;
    }

    modifier onlyUserRegistered(address user_) {
        require(_userRegistered(user_), "the user is not registered");
        _;
    }

    modifier onlyUserNotRegistered(address user_) {
        require(!_userRegistered(user_), "the user is already registered");
        _;
    }

    function _register()
        internal
        whenNotPaused
        onlyUserNotRegistered(_msgSender())
    {
        address user = _msgSender();
        _userDetails[user].existed = true;
        emit Register(user);
    }

    function _userBlocked(address user_)
        internal
        view
        onlyUserRegistered(_msgSender())
        returns (bool)
    {
        return _userDetails[user_].blocked;
    }

    modifier onlyUserBlocked(address user_) {
        require(_userBlocked(user_), "the user is not blocked");
        _;
    }

    modifier onlyUserNotBlocked(address user_) {
        require(!_userBlocked(user_), "the user is already blocked");
        _;
    }

    function _addBlocklist(address user_)
        internal
        onlyUserRegistered(user_)
        onlyUserNotBlocked(user_)
    {
        _userDetails[user_].blocked = true;
        emit AddBlocklist(user_);
    }

    function _removeBlocklist(address user_)
        internal
        onlyUserRegistered(user_)
        onlyUserBlocked(user_)
    {
        _userDetails[user_].blocked = false;
        emit RemoveBlocklist(user_);
    }

    function _getUser(address user_)
        internal
        view
        onlyUserRegistered(user_)
        returns (UserDetail storage)
    {
        return _userDetails[user_];
    }

    // FUND
    address private _defaultToken;
    mapping(address => uint256) private _rewardRates;
    mapping(address => mapping(address => RewardDetail)) _rewardDetails;

    event SetDefaultToken(address indexed oldToken_, address indexed newToken_);
    event Transfer(
        address indexed to_,
        address indexed token_,
        uint256 amount_
    );
    event SetRewardRate(address indexed token_, uint256 indexed percent_);
    event IncreaseReward(
        address indexed user_,
        address indexed token_,
        uint256 amount_
    );
    event DecreaseReward(
        address indexed user_,
        address indexed token_,
        uint256 amount_
    );
    event ClaimReward(
        address indexed user_,
        address indexed token_,
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

    modifier onlyWellFunded(address token_, uint256 amount_) {
        require(
            _balanceOf(token_) >= amount_,
            "the fund of platform is not enough"
        );
        _;
    }

    function _transfer(
        address to_,
        address token_,
        uint256 amount_
    ) internal onlyWellFunded(token_, amount_) {
        if (token_ == address(0x0)) payable(to_).transfer(amount_);
        else IERC20(token_).transfer(to_, amount_);
        emit Transfer(to_, token_, amount_);
    }

    function _setRewardRate(address token_, uint256 percent_) internal {
        require(percent_ > 100, "the value is must between 0 and 100");
        _rewardRates[token_] = percent_;
        emit SetRewardRate(token_, percent_);
    }

    function _getRewardRate(address token_) internal view returns (uint256) {
        return _rewardRates[token_];
    }

    function _increaseReward(
        address user_,
        address token_,
        uint256 amount_
    ) internal onlyUserRegistered(user_) onlyUserNotBlocked(user_) {
        _rewardDetails[user_][token_].total += amount_;
        _rewardDetails[user_][token_].balance += amount_;
        emit IncreaseReward(user_, token_, amount_);
    }

    function _decreaseReward(
        address user_,
        address token_,
        uint256 amount_
    ) internal onlyUserRegistered(user_) onlyUserNotBlocked(user_) {
        require(
            _queryRewards(user_)[token_].balance >= amount_,
            "the Reward balance is less then the amount"
        );
        _rewardDetails[user_][token_].total -= amount_;
        _rewardDetails[user_][token_].balance -= amount_;
        emit DecreaseReward(user_, token_, amount_);
    }

    function _queryRewards(address user_)
        internal
        view
        onlyUserRegistered(user_)
        returns (mapping(address => RewardDetail) storage)
    {
        return _rewardDetails[user_];
    }

    function _claimReward(
        address user_,
        address token_,
        uint256 amount_
    )
        internal
        whenNotPaused
        onlyUserRegistered(user_)
        onlyUserNotBlocked(user_)
        onlyWellFunded(token_, amount_)
    {
        require(
            _queryRewards(user_)[token_].balance >= amount_,
            "the Reward balance is less then the amount"
        );
        _rewardDetails[user_][token_].balance -= amount_;
        emit ClaimReward(user_, token_, amount_);
    }

    function _allowance(address token_) internal view returns (uint256) {
        if (token_ == address(0x0)) return 0;
        else return IERC20(token_).allowance(_msgSender(), address(this));
    }

    // <=== PRIVATE METHODS

    // ===> PUBLIC METHODS
    // COMMON
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

    // AUTHORITY
    function setAdminAuthority(bytes32 authority_, bytes32 adminAuthority_)
        external
        override
        onlyHasAuthority(AUTHORITY_SUPER, _msgSender())
    {
        _setAdminAuthority(authority_, adminAuthority_);
    }

    function defineAuthority(bytes32 authority_)
        external
        override
        onlyHasAuthority(AUTHORITY_SUPER, _msgSender())
    {
        _defineAuthority(authority_, AUTHORITY_SUPER);
    }

    function defineAuthority(bytes32 authority_, bytes32 adminAuthority_)
        external
        override
        onlyHasAuthority(AUTHORITY_SUPER, _msgSender())
    {
        _defineAuthority(authority_, adminAuthority_);
    }

    function undefineAuthority(bytes32 authority_)
        external
        override
        onlyHasAuthority(AUTHORITY_SUPER, _msgSender())
    {
        _undefineAuthority(authority_);
    }

    function addAuthority(bytes32 authority_, address user_)
        external
        override
        onlyHasAuthority(AUTHORITY_SUPER, _msgSender())
    {
        _addAuthority(authority_, user_);
    }

    function removeAuthority(bytes32 authority_, address user_)
        external
        override
        onlyHasAuthority(AUTHORITY_SUPER, _msgSender())
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

    // EXTENSION
    function setExtensionContractAddress(
        bytes32 extension_,
        address contractAddress_
    ) external override onlyHasAuthority(AUTHORITY_SUPER, _msgSender()) {
        _setExtensionContractAddress(extension_, contractAddress_);
    }

    function defineExtension(bytes32 extension_, address contractAddress_)
        external
        override
        onlyHasAuthority(AUTHORITY_SUPER, _msgSender())
    {
        _defineExtension(extension_, contractAddress_);
    }

    function undefineExtension(bytes32 extension_)
        external
        override
        onlyHasAuthority(AUTHORITY_SUPER, _msgSender())
    {
        _undefineExtension(extension_);
    }

    function getExtensionContractAddress(bytes32 extension_)
        external
        view
        override
        returns (address)
    {
        return _getExtension(extension_).contractAddress;
    }

    // USER
    function isRegistered(address user_) external view override returns (bool) {
        return _userRegistered(user_);
    }

    function register() external override {
        _register();
    }

    function isBlocked(address user_) external view override returns (bool) {
        return _userBlocked(user_);
    }

    function addBlocklist(address user_)
        external
        override
        onlyHasAuthority(keccak256("MANAGE_USER"), _msgSender())
    {
        _addBlocklist(user_);
    }

    function removeBlocklist(address user_)
        external
        override
        onlyHasAuthority(keccak256("MANAGE_USER"), _msgSender())
    {
        _removeBlocklist(user_);
    }

    // FUND
    function setDefaultToken(address token_)
        external
        override
        onlyHasAuthority(keccak256("MANAGE_FUND"), _msgSender())
    {
        _setDefaultToken(token_);
    }

    function defaultToken() external view override returns (address) {
        return _defaultToken;
    }

    function mint(uint256 amount_)
        external
        override
        onlyHasAuthority(keccak256("MANAGE_FUND"), _msgSender())
    {
        require(_defaultToken != address(0x0), "ETH can not be mint");
        IColony3Token(_defaultToken).mint(address(this), amount_);
    }

    function burn(uint256 amount_)
        external
        override
        onlyHasAuthority(keccak256("MANAGE_FUND"), _msgSender())
    {
        require(_defaultToken != address(0x0), "ETH can not be burn");
        IColony3Token(_defaultToken).burn(address(this), amount_);
    }

    function setRewardRate(address token_, uint256 percent_)
        external
        override
        onlyHasAuthority(keccak256("MANAGE_FUND"), _msgSender())
    {
        _setRewardRate(token_, percent_);
    }

    function getRewardRate(address token_)
        external
        view
        override
        returns (uint256)
    {
        return _getRewardRate(token_);
    }

    function transfer(
        address to_,
        address token_,
        uint256 amount_
    )
        external
        override
        onlyHasAuthority(keccak256("MANAGE_FUND"), _msgSender())
    {
        _transfer(to_, token_, amount_);
    }

    function increaseReward(
        address user_,
        address token_,
        uint256 amount_
    )
        external
        override
        onlyHasAuthority(keccak256("MANAGE_FUND"), _msgSender())
    {
        _increaseReward(user_, token_, amount_);
    }

    function decreaseReward(
        address user_,
        address token_,
        uint256 amount_
    )
        external
        override
        onlyHasAuthority(keccak256("MANAGE_FUND"), _msgSender())
    {
        _decreaseReward(user_, token_, amount_);
    }

    function queryReward(address user_, address token_)
        external
        view
        override
        returns (uint256, uint256)
    {
        return (
            _queryRewards(user_)[token_].total,
            _queryRewards(user_)[token_].balance
        );
    }

    function claimReward(address token_, uint256 amount_) external override {
        _claimReward(_msgSender(), token_, amount_);
        _transfer(_msgSender(), token_, amount_);
    }

    function allowance(address token_)
        external
        view
        override
        returns (uint256)
    {
        return _allowance(token_);
    }

    // AGENT_EXTENSION
    function inviteRegister(address inviter_) external override {
        _register();
        IAgentExtension(
            _getExtension(keccak256("EXTENSION_AGENT")).contractAddress
        ).bind(inviter_, _msgSender());
    }

    function queryInviter(address user_)
        external
        view
        override
        returns (address)
    {
        return
            IAgentExtension(
                _getExtension(keccak256("EXTENSION_AGENT")).contractAddress
            ).queryInvister(user_);
    }

    function queryInvisteCount(address inviter_)
        external
        view
        override
        returns (uint256)
    {
        return
            IAgentExtension(
                _getExtension(keccak256("EXTENSION_AGENT")).contractAddress
            ).queryInvisteCount(inviter_);
    }

    // PROJECT_EXTENSION
    function projectExisted(address project_)
        external
        view
        override
        returns (bool)
    {
        return
            IProjectExtension(
                _getExtension(keccak256("EXTENSION_PROJECT")).contractAddress
            ).projectExisted(project_);
    }

    function addProject(
        address project_,
        address beneficiary_,
        string calldata downloadUrl_
    )
        external
        override
        onlyHasAuthority(keccak256("MANAGE_PROJECT"), _msgSender())
    {
        IProjectExtension(
            _getExtension(keccak256("EXTENSION_PROJECT")).contractAddress
        ).addProject(project_, beneficiary_, downloadUrl_);
    }

    function removeProject(address project_)
        external
        override
        onlyHasAuthority(keccak256("MANAGE_PROJECT"), _msgSender())
    {
        IProjectExtension(
            _getExtension(keccak256("EXTENSION_PROJECT")).contractAddress
        ).removeProject(project_);
    }

    function setBeneficiary(address project_, address beneficiary_)
        external
        override
        onlyHasAuthority(keccak256("MANAGE_PROJECT"), _msgSender())
    {
        IProjectExtension(
            _getExtension(keccak256("EXTENSION_PROJECT")).contractAddress
        ).setBeneficiary(project_, beneficiary_);
    }

    function beneficiaryOf(address project_)
        external
        view
        override
        returns (address)
    {
        return
            IProjectExtension(
                _getExtension(keccak256("EXTENSION_PROJECT")).contractAddress
            ).beneficiaryOf(project_);
    }

    function setDownloadUrl(address project_, string calldata url_)
        external
        override
    {
        IProjectExtension(
            _getExtension(keccak256("EXTENSION_PROJECT")).contractAddress
        ).setDownloadUrl(project_, url_);
    }

    function downloadUrlOf(address project_)
        external
        view
        override
        returns (string memory)
    {
        return
            IProjectExtension(
                _getExtension(keccak256("EXTENSION_PROJECT")).contractAddress
            ).downloadUrlOf(project_);
    }

    function feeRateOf(address project_)
        external
        view
        override
        returns (uint256)
    {
        return
            IProjectExtension(
                _getExtension(keccak256("EXTENSION_PROJECT")).contractAddress
            ).feeRateOf(project_);
    }

    function setFeeRate(address project_, uint256 feeRate_)
        external
        override
        onlyHasAuthority(keccak256("MANAGE_PROJECT"), _msgSender())
    {
        return
            IProjectExtension(
                _getExtension(keccak256("EXTENSION_PROJECT")).contractAddress
            ).setFeeRate(project_, feeRate_);
    }

    function balanceOf(address project_, address token_)
        external
        view
        override
        returns (uint256)
    {
        return
            IProjectExtension(
                _getExtension(keccak256("EXTENSION_PROJECT")).contractAddress
            ).balanceOf(project_, token_);
    }

    function pay(
        bytes32 id_,
        address user_,
        address token_,
        uint256 amount_
    ) external payable override {
        if (token_ == address(0x0)) {
            require(
                msg.value == amount_,
                "the eth value is must equal to the amount"
            );
        } else IERC20(token_).transferFrom(user_, address(this), amount_);
        IProjectExtension extension = IProjectExtension(
            _getExtension(keccak256("EXTENSION_PROJECT")).contractAddress
        );
        extension.pay(_msgSender(), id_, user_, token_, amount_);
        IAgentExtension(
            _getExtension(keccak256("EXTENSION_AGENT")).contractAddress
        ).addFundFlow(user_, token_, amount_);
        // _increaseReward(extension.beneficiaryOf(_msgSender()), token_, amount_);
    }

    function deosit(
        bytes32 id_,
        address user_,
        address token_,
        uint256 amount_
    ) external payable override {
        if (token_ == address(0x0)) {
            require(
                msg.value == amount_,
                "the eth value is must equal to the amount"
            );
        } else IERC20(token_).transferFrom(user_, address(this), amount_);
        IProjectExtension(
            _getExtension(keccak256("EXTENSION_PROJECT")).contractAddress
        ).deosit(_msgSender(), id_, user_, token_, amount_);
        IAgentExtension(
            _getExtension(keccak256("EXTENSION_AGENT")).contractAddress
        ).addFundFlow(user_, token_, amount_);
    }

    function withdraw(
        bytes32 id_,
        address user_,
        address token_,
        uint256 amount_
    ) external override {
        IProjectExtension extension = IProjectExtension(
            _getExtension(keccak256("EXTENSION_PROJECT")).contractAddress
        );
        uint256 value = extension.feeRateOf(_msgSender()) == 0
            ? amount_
            : (amount_ * 100) / extension.feeRateOf(_msgSender());
        extension.withdraw(_msgSender(), id_, user_, token_, amount_);
        _increaseReward(user_, token_, value);
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

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

struct AuthorityDetail {
    bool existed;
    bytes32 adminAuthority;
    EnumerableSet.AddressSet mumbers;
}

//SPDX-License-Identifier: GNU General Public License v2.0
pragma solidity ^0.8.0;

struct ExtensionDetail {
    bool existed;
    address contractAddress;
}

//SPDX-License-Identifier: GNU General Public License v2.0
pragma solidity ^0.8.0;

struct UserDetail {
    bool existed;
    bool blocked;
}

//SPDX-License-Identifier: GNU General Public License v2.0
pragma solidity ^0.8.0;

struct RewardDetail {
    bool existed;
    uint256 total;
    uint256 balance;
}

//SPDX-License-Identifier: GNU General Public License v2.0
pragma solidity ^0.8.0;

interface IAgentExtension {
    function bind(address inviter_, address user_) external;

    function queryInvister(address user_) external view returns (address);

    function queryInvisteCount(address inviter_)
        external
        view
        returns (uint256);

    function addFundFlow(
        address user_,
        address token_,
        uint256 amount_
    ) external;

    function queryFundFlow(address user_, address token_)
        external
        view
        returns (uint256);
}

//SPDX-License-Identifier: GNU General Public License v2.0
pragma solidity ^0.8.0;

interface IProjectExtension {
    function projectExisted(address project_) external view returns (bool);

    function addProject(
        address project_,
        address beneficiary_,
        string calldata downloadUrl_
    ) external;

    function removeProject(address project_) external;

    function setBeneficiary(address project_, address beneficiary_) external;

    function beneficiaryOf(address project_) external view returns (address);

    function setDownloadUrl(address project_, string calldata url_) external;

    function downloadUrlOf(address project_)
        external
        view
        returns (string memory);

    function feeRateOf(address project_) external view returns (uint256);

    function setFeeRate(address project_, uint256 feeRate_) external;

    function balanceOf(address project_, address token_)
        external
        view
        returns (uint256);

    function pay(
        address project_,
        bytes32 id_,
        address user_,
        address token_,
        uint256 amount_
    ) external;

    function deosit(
        address project_,
        bytes32 id_,
        address user_,
        address token_,
        uint256 amount_
    ) external;

    function withdraw(
        address project_,
        bytes32 id_,
        address user_,
        address token_,
        uint256 amount_
    ) external;
}

//SPDX-License-Identifier: GNU General Public License v2.0
pragma solidity ^0.8.0;

interface IPlatform {
    // COMMON
    function pause() external;

    function unpause() external;

    // AUTHORITY
    function setAdminAuthority(bytes32 authority_, bytes32 adminAuthority_)
        external;

    function defineAuthority(bytes32 authority_) external;

    function defineAuthority(bytes32 authority_, bytes32 adminAuthority_)
        external;

    function undefineAuthority(bytes32 authority_) external;

    function addAuthority(bytes32 authority_, address user_) external;

    function removeAuthority(bytes32 authority_, address user_) external;

    function hasAuthority(bytes32 authority_, address user_)
        external
        view
        returns (bool);

    // EXTENSION
    function setExtensionContractAddress(
        bytes32 extension_,
        address contractAddress_
    ) external;

    function defineExtension(bytes32 extension_, address contractAddress_)
        external;

    function undefineExtension(bytes32 extension_) external;

    function getExtensionContractAddress(bytes32 extension_)
        external
        view
        returns (address);

    // USER
    function isRegistered(address user_) external view returns (bool);

    function register() external;

    function isBlocked(address user_) external view returns (bool);

    function addBlocklist(address user_) external;

    function removeBlocklist(address user_) external;

    // FUND
    function setDefaultToken(address token_) external;

    function defaultToken() external view returns (address);

    function mint(uint256 amount_) external;

    function burn(uint256 amount_) external;

    function setRewardRate(address token_, uint256 percent_) external;

    function getRewardRate(address token_) external view returns (uint256);

    function transfer(
        address to_,
        address token_,
        uint256 amount_
    ) external;

    function increaseReward(
        address user_,
        address token_,
        uint256 amount_
    ) external;

    function decreaseReward(
        address user_,
        address token_,
        uint256 amount_
    ) external;

    function queryReward(address user_, address token_)
        external
        view
        returns (uint256 reward_, uint256 rewardBalance_);

    function claimReward(address token_, uint256 amount_) external;

    function allowance(address token_) external view returns (uint256);

    // AGENT_EXTENSION
    function inviteRegister(address inviter_) external;

    function queryInviter(address user_) external view returns (address);

    function queryInvisteCount(address inviter_)
        external
        view
        returns (uint256);

    // PROJECT_EXTENSION
    function projectExisted(address project_) external view returns (bool);

    function addProject(
        address project_,
        address beneficiary_,
        string calldata downloadUrl_
    ) external;

    function removeProject(address project_) external;

    function setBeneficiary(address project_, address beneficiary_) external;

    function beneficiaryOf(address project_) external view returns (address);

    function setDownloadUrl(address project_, string calldata url_) external;

    function downloadUrlOf(address project_)
        external
        view
        returns (string memory);

    function feeRateOf(address project_) external view returns (uint256);

    function setFeeRate(address project_, uint256 feeRate_) external;

    function balanceOf(address project_, address token_)
        external
        view
        returns (uint256);

    function pay(
        bytes32 id_,
        address user_,
        address token_,
        uint256 amount_
    ) external payable;

    function deosit(
        bytes32 id_,
        address user_,
        address token_,
        uint256 amount_
    ) external payable;

    function withdraw(
        bytes32 id_,
        address user_,
        address token_,
        uint256 amount_
    ) external;
}

//SPDX-License-Identifier: GNU General Public License v2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IColony3Token {
    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}