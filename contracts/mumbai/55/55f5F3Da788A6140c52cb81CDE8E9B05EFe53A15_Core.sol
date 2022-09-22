//SPDX-License-Identifier: GNU General Public License v2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./Authorizable.sol";
import "../interfaces/IManagerUsage.sol";
import "../interfaces/IUserUsage.sol";
import "../interfaces/IProjectUsage.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../common/Enums.sol";
import "../interfaces/IOwnable.sol";
import "../interfaces/IToken.sol";
import "../structs/Module.sol";
import "../interfaces/IAccountModule.sol";
import "../interfaces/IFundModule.sol";
import "../interfaces/IProjectModule.sol";

contract Core is
    Initializable,
    PausableUpgradeable,
    Authorizable,
    IManagerUsage,
    IUserUsage,
    IProjectUsage
{
    using EnumerableSet for EnumerableSet.Bytes32Set;

    function initialize() external initializer {
        PausableUpgradeable.__Pausable_init();
        Authorizable.__Authorizable_init();
    }

    receive() external payable {}

    // PRIVATE FUNCTIONS
    function _caller(address caller_) internal view returns (address) {
        if (caller_.code.length <= 0) return caller_;
        else return caller_;
    }

    EnumerableSet.Bytes32Set private _moduleIds;
    mapping(bytes32 => Module) private _modules;

    event TransferOwnership(
        address indexed address_,
        address indexed newOwner_
    );
    event AddModule(
        bytes32 indexed moduleId_,
        address indexed address_,
        string description_
    );
    event RemoveModule(bytes32 indexed moduleId_);
    event SetModuleAddress(bytes32 indexed moduleId_, address indexed address_);

    function _transferOwnership(address address_, address newOwner_) internal {
        IOwnable(address_).transferOwnership(newOwner_);
        emit TransferOwnership(address_, newOwner_);
    }

    function _addModule(
        bytes32 moduleId_,
        address address_,
        string memory description_
    ) internal {
        require(!_moduleIds.contains(moduleId_), "the module is already exist");
        _moduleIds.add(moduleId_);
        _modules[moduleId_].address_ = address_;
        _modules[moduleId_].description = description_;
        emit AddModule(moduleId_, address_, description_);
    }

    function _removeModule(bytes32 moduleId_) internal {
        _module(moduleId_);
        _moduleIds.remove(moduleId_);
        delete _modules[moduleId_];
        emit RemoveModule(moduleId_);
    }

    function _setModuleAddress(bytes32 moduleId_, address address_) internal {
        require(address_ != address(0x0), "the address is must not 0x0");
        Module storage module_ = _module(moduleId_);
        module_.address_ = address_;
        emit SetModuleAddress(moduleId_, address_);
    }

    function _module(bytes32 moduleId_) internal view returns (Module storage) {
        require(_moduleIds.contains(moduleId_), "the module is not exist");
        return _modules[moduleId_];
    }

    function _moduleAddress(bytes32 moduleId_) internal view returns (address) {
        return _module(moduleId_).address_;
    }

    /* AccountModule */
    bytes32 public constant MODULE_ACCOUNT_ID = keccak256("ACCOUNT");

    event RegisterAccount(address indexed user_);
    event AddAccountBlocklist(address indexed user_);
    event RemoveAccountBlocklist(address indexed user_);
    event AddAccountFundFlows(
        address indexed user_,
        address indexed token_,
        uint256 amount_
    );
    event RemoveAccountFundFlows(
        address indexed user_,
        address indexed token_,
        uint256 amount_
    );

    function _registerAccount(address user_) internal {
        IAccountModule(_moduleAddress(MODULE_ACCOUNT_ID)).register(user_);
        emit RegisterAccount(user_);
    }

    function _addAccountBlocklist(address user_) internal {
        if (!_accountExisted(user_)) _registerAccount(user_);
        IAccountModule(_moduleAddress(MODULE_ACCOUNT_ID)).addBlocklist(user_);
        emit AddAccountBlocklist(user_);
    }

    function _removeAccountBlocklist(address user_) internal {
        if (!_accountExisted(user_)) _registerAccount(user_);
        IAccountModule(_moduleAddress(MODULE_ACCOUNT_ID)).removeBlocklist(
            user_
        );
        emit RemoveAccountBlocklist(user_);
    }

    function _addAccountFundFlows(
        address user_,
        address token_,
        uint256 amount_
    ) internal {
        if (!_accountExisted(user_)) _registerAccount(user_);
        IAccountModule(_moduleAddress(MODULE_ACCOUNT_ID)).addFundFlows(
            user_,
            token_,
            amount_
        );
        emit AddAccountFundFlows(user_, token_, amount_);
    }

    function _removeAccountFundFlows(
        address user_,
        address token_,
        uint256 amount_
    ) internal {
        if (!_accountExisted(user_)) _registerAccount(user_);
        IAccountModule(_moduleAddress(MODULE_ACCOUNT_ID)).removeFundFlows(
            user_,
            token_,
            amount_
        );
        emit RemoveAccountFundFlows(user_, token_, amount_);
    }

    function _accountExisted(address user_) internal view returns (bool) {
        return
            IAccountModule(_moduleAddress(MODULE_ACCOUNT_ID)).accountExisted(
                user_
            );
    }

    /* FundModule */
    bytes32 public constant MODULE_FUND_ID = keccak256("FUND");
    address private _defaultToken;

    event SetDefaultToken(address indexed oldToken_, address indexed newToken_);
    event Mint(address indexed token_, uint256 amount_);
    event Burn(address indexed token_, uint256 amount_);
    event Transfer(
        address indexed payer_,
        address[] receivers_,
        address indexed token_,
        uint256[] amounts_,
        PayType fromPayayType_,
        PayType toPayayType_
    );
    event Freeze(
        address indexed user_,
        address indexed token_,
        uint256 amount_
    );
    event Unfreeze(
        address indexed user_,
        address indexed token_,
        uint256 amount_
    );

    function _setDefaultToken(address token_) internal {
        require(
            token_ != _defaultToken,
            "the new token is must different from the old token"
        );
        address oldToken = _defaultToken;
        _defaultToken = token_;
        emit SetDefaultToken(oldToken, token_);
    }

    function _mint(uint256 amount_)
        internal
        returns (address[] memory receivers_, uint256[] memory amounts_)
    {
        require(_defaultToken != address(0x0), "0x0 can not be mint");
        Module storage module_ = _module(MODULE_FUND_ID);
        receivers_ = new address[](1);
        receivers_[0] = module_.address_;
        amounts_ = new uint256[](1);
        amounts_[0] = amount_;
        IToken(_defaultToken).mint(module_.address_, amount_);
        emit Mint(_defaultToken, amount_);
        return (receivers_, amounts_);
    }

    function _burn(uint256 amount_)
        internal
        returns (address[] memory receivers_, uint256[] memory amounts_)
    {
        require(_defaultToken != address(0x0), "0x0 can not be burn");
        receivers_ = new address[](1);
        receivers_[0] = address(0x0);
        amounts_ = new uint256[](1);
        amounts_[0] = amount_;
        IToken(_defaultToken).burn(_moduleAddress(MODULE_FUND_ID), amount_);
        emit Burn(_defaultToken, amount_);
        return (receivers_, amounts_);
    }

    function _transfer(
        address payer_,
        address[] memory receivers_,
        address token_,
        uint256[] memory amounts_,
        PayType fromPayType_,
        PayType toPayType_
    ) internal {
        IFundModule(_moduleAddress(MODULE_FUND_ID)).transfer{value: msg.value}(
            payer_,
            receivers_,
            token_,
            amounts_,
            fromPayType_,
            toPayType_
        );
        emit Transfer(
            payer_,
            receivers_,
            token_,
            amounts_,
            fromPayType_,
            toPayType_
        );
    }

    function _freeze(
        address user_,
        address token_,
        uint256 amount_
    ) internal {
        IFundModule(_moduleAddress(MODULE_FUND_ID)).freeze(
            user_,
            token_,
            amount_
        );
        emit Freeze(user_, token_, amount_);
    }

    function _unfreeze(
        address user_,
        address token_,
        uint256 amount_
    ) internal {
        IFundModule(_moduleAddress(MODULE_FUND_ID)).unfreeze(
            user_,
            token_,
            amount_
        );
        emit Unfreeze(user_, token_, amount_);
    }

    /* ProjectModule */
    bytes32 public constant MODULE_PROJECT_ID = keccak256("PROJECT");

    event SetRegisterProjectThreshold(uint256 registerThreshold_);
    event SetProjectDefaultFeeRate(uint256 feeRate_);
    event RegisterProject(
        address indexed owner_,
        address indexed project_,
        uint256 feeRate_
    );
    event UnregisterProject(address indexed project_);
    event SetProjectBlocklistStatus(
        address indexed project_,
        bool blocklisted_
    );
    event SetProjectFeeRate(
        address indexed project_,
        uint256 oldFeeRate_,
        uint256 newFeeRate_
    );
    event CreateOrder(
        address indexed project_,
        bytes32 indexed orderId_,
        OrderType indexed orderType_,
        uint256 expireTime_,
        bytes data_
    );
    event PayOrder(
        address indexed project_,
        bytes32 indexed orderId_,
        PayType indexed PayType_
    );
    event CancelOrder(address indexed project_, bytes32 indexed orderId_);
    event Settle(
        address indexed project_,
        address indexed token_,
        uint256 indexed amount_
    );

    function _setRegisterThreshold(uint256 registerThreshold_) internal {
        IProjectModule(_moduleAddress(MODULE_PROJECT_ID)).setRegisterThreshold(
            registerThreshold_
        );
        emit SetRegisterProjectThreshold(registerThreshold_);
    }

    function _setProjectDefaultFeeRate(uint256 feeRate_) internal {
        IProjectModule(_moduleAddress(MODULE_PROJECT_ID)).setDefaultFeeRate(
            feeRate_
        );
        emit SetProjectDefaultFeeRate(feeRate_);
    }

    function _registerProject(address core_, address owner_)
        internal
        returns (address)
    {
        Module storage module_ = _module(MODULE_PROJECT_ID);
        address project_ = IProjectModule(module_.address_).register(
            core_,
            owner_
        );
        emit RegisterProject(
            owner_,
            project_,
            IProjectModule(module_.address_).defaultFeeRate()
        );
        return project_;
    }

    function _unregisterProject(address project_)
        internal
        returns (address owner_, uint256 frozen_)
    {
        Module storage module_ = _module(MODULE_PROJECT_ID);
        (, owner_, frozen_, , , , ) = IProjectModule(module_.address_).project(
            project_
        );
        IProjectModule(module_.address_).unregister(project_);
        emit UnregisterProject(project_);
        return (owner_, frozen_);
    }

    function _setProjectBlocklistStatus(address project_, bool blocklisted_)
        internal
    {
        IProjectModule(_moduleAddress(MODULE_PROJECT_ID)).setBlocklistStatus(
            project_,
            blocklisted_
        );
        emit SetProjectBlocklistStatus(project_, blocklisted_);
    }

    function _setProjectFeeRate(address project_, uint256 feeRate_) internal {
        Module storage module_ = _module(MODULE_PROJECT_ID);
        (, , , uint256 feeRate, , , ) = IProjectModule(module_.address_)
            .project(project_);
        IProjectModule(module_.address_).setFeeRate(project_, feeRate_);
        emit SetProjectFeeRate(project_, feeRate, feeRate_);
    }

    function _createOrder(
        address project_,
        bytes32 orderId_,
        address creator_,
        OrderType orderType_,
        uint256 expireTime_,
        bytes memory data_
    ) internal {
        IProjectModule(_moduleAddress(MODULE_PROJECT_ID)).createOrder(
            project_,
            orderId_,
            creator_,
            orderType_,
            expireTime_,
            data_
        );
        emit CreateOrder(project_, orderId_, orderType_, expireTime_, data_);
    }

    function _payOrder(
        address project_,
        bytes32 orderId_,
        bytes memory signature_,
        PayType payType_
    )
        internal
        returns (
            address payer_,
            address[] memory receivers_,
            address token_,
            uint256[] memory amounts_
        )
    {
        (
            address creator,
            address payer,
            OrderType orderType,
            bytes memory data
        ) = IProjectModule(_moduleAddress(MODULE_PROJECT_ID)).payOrder(
                project_,
                orderId_,
                signature_,
                payType_
            );
        payer_ = payer;
        if (orderType == OrderType.Pay) {
            (, address token, uint256 amount) = abi.decode(
                data,
                (address, address, uint256)
            );
            receivers_ = new address[](1);
            receivers_[0] = project_;
            token_ = token;
            amounts_ = new uint256[](1);
            amounts_[0] = amount;
            _addAccountFundFlows(creator, token, amount);
        } else revert("the order type is not supported");
        emit PayOrder(project_, orderId_, payType_);
        return (payer_, receivers_, token_, amounts_);
    }

    function _cancelOrder(address project_, bytes32 orderId_)
        internal
        returns (
            address[] memory receivers_,
            address token_,
            uint256[] memory amounts_,
            PayType payType_
        )
    {
        (
            address creator,
            OrderType orderType,
            OrderStatus orderStatus,
            bytes memory data,
            PayType payType
        ) = IProjectModule(_moduleAddress(MODULE_PROJECT_ID)).cancelOrder(
                project_,
                orderId_
            );
        payType_ = payType;
        if (orderType == OrderType.Pay) {
            (address payer, address token, uint256 amount) = abi.decode(
                data,
                (address, address, uint256)
            );
            if (orderStatus == OrderStatus.Paid) {
                receivers_ = new address[](1);
                receivers_[0] = payer;
                amounts_ = new uint256[](1);
                amounts_[0] = amount;
                _removeAccountFundFlows(creator, token, amount);
            }
        } else revert("the order type is not supported");
        emit CancelOrder(project_, orderId_);
        return (receivers_, token_, amounts_, payType_);
    }

    function _settle(
        address project_,
        address token_,
        uint256 amount_
    )
        internal
        returns (address[] memory receivers_, uint256[] memory amounts_)
    {
        uint256 realAmount = IProjectModule(_moduleAddress(MODULE_PROJECT_ID))
            .settle(project_, token_, amount_);
        receivers_ = new address[](1);
        receivers_[0] = _moduleAddress(MODULE_FUND_ID);
        amounts_ = new uint256[](1);
        amounts_[0] = amount_ - realAmount;
        emit Settle(project_, token_, amount_);
        return (receivers_, amounts_);
    }

    // MODIFIER
    modifier onlyNotBlocklistedProject(address project_) {
        (bool blocklisted, , , , , , ) = IProjectModule(
            _moduleAddress(MODULE_PROJECT_ID)
        ).project(project_);
        require(!blocklisted, "the project is blocklisted");
        _;
    }

    modifier onlyProjectOwnerOrHasAuthority(
        address project_,
        bytes32 authority
    ) {
        (, address owner, , , , , ) = IProjectModule(
            _moduleAddress(MODULE_PROJECT_ID)
        ).project(project_);
        address caller = _caller(_msgSender());
        require(
            Authorizable._hasAuthority(
                Authorizable.AUTHORITY_SUPER_ID,
                caller
            ) || owner == caller,
            "the caller is must super or owner"
        );
        _;
    }

    // PUBLIC FUNCTIONS
    function pause()
        external
        override
        onlyHasAuthority(Authorizable.AUTHORITY_SUPER_ID, _msgSender())
    {
        PausableUpgradeable._pause();
    }

    function unpause()
        external
        override
        onlyHasAuthority(Authorizable.AUTHORITY_SUPER_ID, _msgSender())
    {
        PausableUpgradeable._unpause();
    }

    function addModule(
        bytes32 moduleId_,
        address address_,
        string calldata description_
    )
        external
        override
        onlyHasAuthority(Authorizable.AUTHORITY_SUPER_ID, _msgSender())
    {
        _addModule(moduleId_, address_, description_);
    }

    function removeModule(bytes32 moduleId_)
        external
        override
        onlyHasAuthority(Authorizable.AUTHORITY_SUPER_ID, _msgSender())
    {
        _removeModule(moduleId_);
    }

    function setModuleAddress(bytes32 moduleId_, address address_)
        external
        override
        onlyHasAuthority(Authorizable.AUTHORITY_SUPER_ID, _msgSender())
    {
        _setModuleAddress(moduleId_, address_);
    }

    function moduleExisted(bytes32 moduleId_)
        external
        view
        override
        returns (bool)
    {
        return _moduleIds.contains(moduleId_);
    }

    function module(bytes32 moduleId_)
        external
        view
        override
        returns (address address_, string memory description_)
    {
        Module storage module_ = _module(moduleId_);
        return (module_.address_, module_.description);
    }

    /* AccountModule */
    function addAccountBlocklist(address user_)
        external
        override
        onlyHasAuthority(Authorizable.AUTHORITY_SUPER_ID, _msgSender())
    {
        _addAccountBlocklist(user_);
    }

    function removeAccountBlocklist(address user_)
        external
        override
        onlyHasAuthority(Authorizable.AUTHORITY_SUPER_ID, _msgSender())
    {
        _removeAccountBlocklist(user_);
    }

    function accountAddress(bytes32 id_)
        external
        view
        override
        returns (address)
    {
        return
            IAccountModule(_moduleAddress(MODULE_ACCOUNT_ID)).accountAddress(
                id_
            );
    }

    function account(address user_)
        external
        view
        override
        returns (
            bool blocklisted_,
            bytes32 id_,
            address[] memory tokens_,
            uint256[] memory fundFlows_
        )
    {
        return IAccountModule(_moduleAddress(MODULE_ACCOUNT_ID)).account(user_);
    }

    /* FundModule */
    function setDefaultToken(address token_)
        external
        override
        onlyHasAuthority(Authorizable.AUTHORITY_SUPER_ID, _msgSender())
    {
        _setDefaultToken(token_);
    }

    function mint(uint256 amount_)
        external
        override
        onlyHasAuthority(Authorizable.AUTHORITY_SUPER_ID, _msgSender())
    {
        (address[] memory receivers, uint256[] memory amounts) = _mint(amount_);
        _transfer(
            address(0x0),
            receivers,
            _defaultToken,
            amounts,
            PayType.Mint,
            PayType.Balance
        );
    }

    function burn(uint256 amount_)
        external
        override
        onlyHasAuthority(Authorizable.AUTHORITY_SUPER_ID, _msgSender())
    {
        (address[] memory receivers_, uint256[] memory amounts_) = _burn(
            amount_
        );
        _transfer(
            _moduleAddress(MODULE_FUND_ID),
            receivers_,
            _defaultToken,
            amounts_,
            PayType.Balance,
            PayType.Burn
        );
    }

    function transfer(
        address[] memory receivers_,
        address token_,
        uint256[] memory amounts_,
        PayType payType_
    )
        external
        override
        onlyHasAuthority(Authorizable.AUTHORITY_SUPER_ID, _msgSender())
    {
        _transfer(
            _moduleAddress(MODULE_FUND_ID),
            receivers_,
            token_,
            amounts_,
            PayType.Balance,
            payType_
        );
    }

    function transfer(
        address[] memory receivers_,
        address token_,
        uint256[] memory amounts_,
        PayType fromPayType_,
        PayType toPayType_
    ) external payable override whenNotPaused {
        address payer = _caller(_msgSender());
        if (_msgSender() != payer) {}
        _transfer(
            payer,
            receivers_,
            token_,
            amounts_,
            fromPayType_,
            toPayType_
        );
    }

    function defaultToken() external view override returns (address) {
        return _defaultToken;
    }

    function approveAddress() external view override returns (address) {
        return _moduleAddress(MODULE_FUND_ID);
    }

    function approveValue(address token_)
        external
        view
        override
        returns (uint256)
    {
        address owner = _caller(_msgSender());
        if (_msgSender() != owner) {}
        return IERC20(token_).allowance(owner, _moduleAddress(MODULE_FUND_ID));
    }

    function balance(address user_, address token_)
        external
        view
        override
        returns (uint256)
    {
        return
            IFundModule(_moduleAddress(MODULE_FUND_ID)).balance(user_, token_);
    }

    function frozenBalance(address user_, address token_)
        external
        view
        override
        returns (uint256)
    {
        return
            IFundModule(_moduleAddress(MODULE_FUND_ID)).frozenBalance(
                user_,
                token_
            );
    }

    /* ProjectModule */
    function registerProject() external override returns (address) {
        address owner = _caller(_msgSender());
        if (_msgSender() != owner) {}
        _freeze(
            owner,
            _defaultToken,
            IProjectModule(_moduleAddress(MODULE_PROJECT_ID))
                .registerThreshold()
        );
        return _registerProject(address(this), owner);
    }

    function unregisterProject(address project_)
        external
        override
        onlyProjectOwnerOrHasAuthority(
            project_,
            Authorizable.AUTHORITY_SUPER_ID
        )
    {
        (address owner, uint256 frozen) = _unregisterProject(project_);
        _unfreeze(owner, _defaultToken, frozen);
    }

    function setProjectDefaultFeeRate(uint256 feeRate_) external override {
        _setProjectDefaultFeeRate(feeRate_);
    }

    function addProjectBlocklist(address project_)
        external
        override
        onlyHasAuthority(Authorizable.AUTHORITY_SUPER_ID, _msgSender())
    {
        _setProjectBlocklistStatus(project_, true);
    }

    function removeProjectBlocklist(address project_)
        external
        override
        onlyHasAuthority(Authorizable.AUTHORITY_SUPER_ID, _msgSender())
    {
        _setProjectBlocklistStatus(project_, false);
    }

    function setProjectRegisterThreshold(uint256 registerThreshold_)
        external
        override
        onlyHasAuthority(Authorizable.AUTHORITY_SUPER_ID, _msgSender())
    {
        _setRegisterThreshold(registerThreshold_);
    }

    function setProjectFeeRate(address project_, uint256 feeRate_)
        external
        override
        onlyHasAuthority(Authorizable.AUTHORITY_SUPER_ID, _msgSender())
    {
        _setProjectFeeRate(project_, feeRate_);
    }

    function createOrder(
        bytes32 orderId_,
        address creator_,
        OrderType orderType_,
        uint256 expireTime,
        bytes calldata data_
    ) external override whenNotPaused onlyNotBlocklistedProject(_msgSender()) {
        _createOrder(
            _msgSender(),
            orderId_,
            creator_,
            orderType_,
            expireTime,
            data_
        );
    }

    function payOrder(
        bytes32 orderId_,
        bytes calldata signature_,
        PayType payType_
    )
        external
        payable
        override
        whenNotPaused
        onlyNotBlocklistedProject(_msgSender())
    {
        (
            address payer,
            address[] memory receivers,
            address token,
            uint256[] memory amounts
        ) = _payOrder(_msgSender(), orderId_, signature_, payType_);
        _transfer(payer, receivers, token, amounts, payType_, PayType.Balance);
        uint256 total;
        for (uint256 i; i < amounts.length; i++) total += amounts[i];
        _freeze(_msgSender(), token, total);
    }

    function cancelOrder(bytes32 orderId_)
        external
        override
        whenNotPaused
        onlyNotBlocklistedProject(_msgSender())
    {
        (
            address[] memory receivers,
            address token,
            uint256[] memory amounts,
            PayType payType
        ) = _cancelOrder(_msgSender(), orderId_);
        uint256 total;
        for (uint256 i; i < amounts.length; i++) total += amounts[i];
        _unfreeze(_msgSender(), token, total);
        _transfer(
            _moduleAddress(MODULE_FUND_ID),
            receivers,
            token,
            amounts,
            PayType.Balance,
            payType
        );
    }

    function settle(address token_, uint256 amount_)
        external
        override
        whenNotPaused
        onlyNotBlocklistedProject(_msgSender())
    {
        (address[] memory receivers, uint256[] memory amounts) = _settle(
            _msgSender(),
            token_,
            amount_
        );
        _unfreeze(_msgSender(), token_, amount_);
        _transfer(
            _msgSender(),
            receivers,
            token_,
            amounts,
            PayType.Balance,
            PayType.Balance
        );
    }

    function registerThreshold() external view override returns (uint256) {
        return
            IProjectModule(_moduleAddress(MODULE_PROJECT_ID))
                .registerThreshold();
    }

    function defaultFeeRate() external view override returns (uint256) {
        return
            IProjectModule(_moduleAddress(MODULE_PROJECT_ID)).defaultFeeRate();
    }

    function ownProjects(address owner_)
        external
        view
        override
        returns (address[] memory)
    {
        return
            IProjectModule(_moduleAddress(MODULE_PROJECT_ID)).ownProjects(
                owner_
            );
    }

    function project(address project_)
        external
        view
        override
        returns (
            bool blocklisted_,
            address owner_,
            uint256 registerFrozen_,
            uint256 feeRate_,
            address[] memory tokens_,
            uint256[] memory fundFlows_,
            uint256[] memory pendingSettlements_
        )
    {
        return
            IProjectModule(_moduleAddress(MODULE_PROJECT_ID)).project(project_);
    }

    function order(address project_, bytes32 orderId_)
        external
        view
        override
        returns (
            OrderType type_,
            uint256 expireTime_,
            address creator_,
            bytes memory data_,
            OrderStatus status_
        )
    {
        return
            IProjectModule(_moduleAddress(MODULE_PROJECT_ID)).order(
                project_,
                orderId_
            );
    }
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

//SPDX-License-Identifier: GNU General Public License v2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../interfaces/IAuthorizable.sol";
import "../structs/Authority.sol";

abstract contract Authorizable is
    Initializable,
    ContextUpgradeable,
    IAuthorizable
{
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant AUTHORITY_SUPER_ID = keccak256("SUPER");
    EnumerableSet.Bytes32Set private _authorityIds;
    mapping(bytes32 => Authority) private _authorities;

    event DefineAuthority(
        bytes32 indexed authorityId_,
        bytes32 indexed adminAuthorityId_
    );
    event UndefineAuthority(bytes32 indexed authorityId_);
    event SetAdminAuthority(
        bytes32 indexed authorityId_,
        bytes32 indexed oldAdminAuthorityId_,
        bytes32 indexed newAdminAuthorityId_
    );
    event AddAuthority(bytes32 indexed authorityId_, address indexed user_);
    event RemoveAuthority(bytes32 indexed authorityId_, address indexed user_);

    function __Authorizable_init() internal onlyInitializing {
        __Authorizable_init_unchained();
    }

    function __Authorizable_init_unchained() internal onlyInitializing {
        __Context_init_unchained();

        _defineAuthority(AUTHORITY_SUPER_ID, bytes32(0x0));
        _addAuthority(AUTHORITY_SUPER_ID, _msgSender());
    }

    // PRIVATE FUNCTIONS
    function _defineAuthority(bytes32 authorityId_, bytes32 adminAuthorityId_)
        internal
    {
        require(
            authorityId_ != adminAuthorityId_,
            "the authorities are must different"
        );
        require(
            !_authorityIds.contains(authorityId_),
            "the authority is already exist"
        );
        _authorityIds.add(authorityId_);
        _authorities[authorityId_].adminAuthorityId = adminAuthorityId_;
        emit DefineAuthority(authorityId_, adminAuthorityId_);
    }

    function _undefineAuthority(bytes32 authorityId_) internal {
        Authority storage authority_ = _authority(authorityId_);
        _authorityIds.remove(authorityId_);
        for (uint256 i = 0; i < authority_.mumbers.length(); i++) {
            authority_.mumbers.remove(authority_.mumbers.at(i));
        }
        delete _authorities[authorityId_];
        emit UndefineAuthority(authorityId_);
    }

    function _setAdminAuthority(bytes32 authorityId_, bytes32 adminAuthorityId_)
        internal
    {
        require(
            authorityId_ != adminAuthorityId_,
            "the authorities are must different"
        );
        Authority storage authority_ = _authority(authorityId_);
        bytes32 oldAdminAuthorityId = authority_.adminAuthorityId;
        require(
            oldAdminAuthorityId != adminAuthorityId_,
            "the authorities are must different"
        );
        authority_.adminAuthorityId = adminAuthorityId_;
        emit SetAdminAuthority(
            authorityId_,
            oldAdminAuthorityId,
            adminAuthorityId_
        );
    }

    function _addAuthority(bytes32 authorityId_, address user_) internal {
        Authority storage authority_ = _authority(authorityId_);
        authority_.mumbers.add(user_);
        emit AddAuthority(authorityId_, user_);
    }

    function _removeAuthority(bytes32 authorityId_, address user_) internal {
        Authority storage authority_ = _authority(authorityId_);
        authority_.mumbers.remove(user_);
        emit RemoveAuthority(authorityId_, user_);
    }

    function _authority(bytes32 authorityId_)
        internal
        view
        returns (Authority storage)
    {
        require(
            _authorityIds.contains(authorityId_),
            "the authority is not exist"
        );
        return _authorities[authorityId_];
    }

    function _hasAuthority(bytes32 authorityId_, address user_)
        internal
        view
        returns (bool)
    {
        if (!_authorityIds.contains(authorityId_)) return false;
        return _authorities[authorityId_].mumbers.contains(user_);
    }

    // MODIFIER
    modifier onlyHasAuthority(bytes32 authorityId_, address user_) {
        require(
            _hasAuthority(authorityId_, user_),
            "the user does not have the authority"
        );
        _;
    }

    // PUBLIC FUNCTIONS
    function defineAuthority(bytes32 authorityId_, bytes32 adminAuthorityId_)
        external
        override
        onlyHasAuthority(AUTHORITY_SUPER_ID, _msgSender())
    {
        _defineAuthority(authorityId_, adminAuthorityId_);
    }

    function defineAuthority(bytes32 authorityId_)
        external
        override
        onlyHasAuthority(AUTHORITY_SUPER_ID, _msgSender())
    {
        _defineAuthority(authorityId_, AUTHORITY_SUPER_ID);
    }

    function undefineAuthority(bytes32 authorityId_)
        external
        override
        onlyHasAuthority(AUTHORITY_SUPER_ID, _msgSender())
    {
        _undefineAuthority(authorityId_);
    }

    function setAdminAuthority(bytes32 authorityId_, bytes32 adminAuthorityId_)
        external
        override
        onlyHasAuthority(AUTHORITY_SUPER_ID, _msgSender())
    {
        _setAdminAuthority(authorityId_, adminAuthorityId_);
    }

    function addAuthority(bytes32 authorityId_, address user_)
        external
        override
        onlyHasAuthority(AUTHORITY_SUPER_ID, _msgSender())
    {
        _addAuthority(authorityId_, user_);
    }

    function removeAuthority(bytes32 authorityId_, address user_)
        external
        override
        onlyHasAuthority(AUTHORITY_SUPER_ID, _msgSender())
    {
        _removeAuthority(authorityId_, user_);
    }

    function authorityDefined(bytes32 authorityId_)
        external
        view
        override
        returns (bool)
    {
        return _authorityIds.contains(authorityId_);
    }

    function authority(bytes32 authorityId_)
        external
        view
        override
        returns (bytes32 adminAuthorityId_, address[] memory mumbers)
    {
        Authority storage authority_ = _authority(authorityId_);
        return (authority_.adminAuthorityId, authority_.mumbers.values());
    }

    function hasAuthority(bytes32 authorityId_, address user_)
        external
        view
        override
        returns (bool)
    {
        return _hasAuthority(authorityId_, user_);
    }
}

//SPDX-License-Identifier: GNU General Public License v2.0
pragma solidity ^0.8.0;

import "../common/Enums.sol";

interface IManagerUsage {
    function pause() external;

    function unpause() external;

    function addModule(
        bytes32 moduleId_,
        address address_,
        string calldata description_
    ) external;

    function removeModule(bytes32 moduleId_) external;

    function setModuleAddress(bytes32 moduleId_, address address_) external;

    function moduleExisted(bytes32 moduleId_) external view returns (bool);

    function module(bytes32 moduleId_)
        external
        view
        returns (address address_, string memory description_);

    /* AccountModule */
    function addAccountBlocklist(address user_) external;

    function removeAccountBlocklist(address user_) external;

    /* FundModule */
    function setDefaultToken(address token_) external;

    function mint(uint256 amount_) external;

    function burn(uint256 amount_) external;

    function transfer(
        address[] memory receivers_,
        address token_,
        uint256[] memory amounts_,
        PayType payType_
    ) external;

    /* ProjectModule */
    function setProjectRegisterThreshold(uint256 registerThreshold_) external;

    function setProjectDefaultFeeRate(uint256 feeRate_) external;

    function addProjectBlocklist(address project_) external;

    function removeProjectBlocklist(address project_) external;

    function setProjectFeeRate(address project_, uint256 feeRate_) external;
}

//SPDX-License-Identifier: GNU General Public License v2.0
pragma solidity ^0.8.0;

import "../common/Enums.sol";

interface IUserUsage {
    /* AccountModule */
    function accountAddress(bytes32 id_) external view returns (address);

    function account(address user_)
        external
        view
        returns (
            bool blocklisted_,
            bytes32 id_,
            address[] memory tokens_,
            uint256[] memory fundFlows_
        );

    /* FundModule */
    function transfer(
        address[] memory receivers_,
        address token_,
        uint256[] memory amounts_,
        PayType fromPayType_,
        PayType toPayType_
    ) external payable;

    function defaultToken() external view returns (address);

    function approveAddress() external view returns (address);

    function approveValue(address token_) external view returns (uint256);

    function balance(address user_, address token_)
        external
        view
        returns (uint256);

    function frozenBalance(address user_, address token_)
        external
        view
        returns (uint256);

    /* ProjectModule */
    function registerProject() external returns (address);

    function unregisterProject(address project_) external;

    function registerThreshold() external view returns (uint256);

    function defaultFeeRate() external view returns (uint256);

    function ownProjects(address owner_)
        external
        view
        returns (address[] memory);

    function project(address project_)
        external
        view
        returns (
            bool blocklisted_,
            address owner_,
            uint256 registerFrozen_,
            uint256 feeRate_,
            address[] memory tokens_,
            uint256[] memory fundFlows_,
            uint256[] memory pendingSettlements_
        );

    function order(address project_, bytes32 orderId_)
        external
        view
        returns (
            OrderType type_,
            uint256 expireTime_,
            address creator_,
            bytes memory data_,
            OrderStatus status_
        );
}

//SPDX-License-Identifier: GNU General Public License v2.0
pragma solidity ^0.8.0;

import "../common/Enums.sol";

interface IProjectUsage {
    function createOrder(
        bytes32 orderId_,
        address creator_,
        OrderType orderType_,
        uint256 expireTime_,
        bytes calldata data_
    ) external;

    function payOrder(
        bytes32 orderId_,
        bytes calldata signature_,
        PayType payType_
    ) external payable;

    function cancelOrder(bytes32 orderId_) external;

    function settle(address token_, uint256 amount_) external;
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

enum OrderType {
    Unknow,
    Pay
}

enum OrderStatus {
    Unknow,
    Unpaid,
    Cancelled,
    Paid
}

enum PayType {
    Unknow,
    Mint,
    Burn,
    Balance,
    Wallet
}

//SPDX-License-Identifier: GNU General Public License v2.0
pragma solidity ^0.8.0;

interface IOwnable {
    function owner() external view returns (address);

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;
}

//SPDX-License-Identifier: GNU General Public License v2.0
pragma solidity ^0.8.0;

interface IToken {
    function mint(address account_, uint256 amount_) external;

    function burn(address account_, uint256 amount_) external;
}

//SPDX-License-Identifier: GNU General Public License v2.0
pragma solidity ^0.8.0;

struct Module {
    address address_;
    string description;
}

//SPDX-License-Identifier: GNU General Public License v2.0
pragma solidity ^0.8.0;

interface IAccountModule {
    function register(address user_) external;

    function addBlocklist(address user_) external;

    function removeBlocklist(address user_) external;

    function addFundFlows(
        address user_,
        address token_,
        uint256 amount_
    ) external;

    function removeFundFlows(
        address user_,
        address token_,
        uint256 amount_
    ) external;

    function accountExisted(address user_) external view returns (bool);

    function accountAddress(bytes32 id_) external view returns (address);

    function account(address user_)
        external
        view
        returns (
            bool blocklisted,
            bytes32 id_,
            address[] memory tokens_,
            uint256[] memory fundFlows_
        );
}

//SPDX-License-Identifier: GNU General Public License v2.0
pragma solidity ^0.8.0;

import "../common/Enums.sol";

interface IFundModule {
    function transfer(
        address payer_,
        address[] memory receivers_,
        address token_,
        uint256[] memory amounts_,
        PayType fromPayType_,
        PayType toPayType_
    ) external payable;

    function freeze(
        address user_,
        address token_,
        uint256 amount_
    ) external;

    function unfreeze(
        address user_,
        address token_,
        uint256 amount_
    ) external;

    function balance(address user_, address token_)
        external
        view
        returns (uint256);

    function frozenBalance(address user_, address token_)
        external
        view
        returns (uint256);
}

//SPDX-License-Identifier: GNU General Public License v2.0
pragma solidity ^0.8.0;

import "../structs/Order.sol";

interface IProjectModule {
    function setRegisterThreshold(uint256 registerThreshold_) external;

    function setDefaultFeeRate(uint256 feeRate_) external;

    function register(address core_, address owner_) external returns (address);

    function unregister(address project_) external;

    function setBlocklistStatus(address project_, bool blocklisted_) external;

    function setFeeRate(address project_, uint256 feeRate_) external;

    function createOrder(
        address project_,
        bytes32 orderId_,
        address creator_,
        OrderType orderType_,
        uint256 expireTime_,
        bytes calldata data_
    ) external;

    function payOrder(
        address project_,
        bytes32 orderId_,
        bytes calldata signature_,
        PayType payType_
    )
        external
        returns (
            address creator,
            address payer_,
            OrderType orderType_,
            bytes memory data_
        );

    function cancelOrder(address project_, bytes32 orderId_)
        external
        returns (
            address creator,
            OrderType orderType_,
            OrderStatus orderStatus_,
            bytes memory data_,
            PayType payType_
        );

    function settle(
        address project_,
        address token_,
        uint256 amount_
    ) external returns (uint256);

    function registerThreshold() external view returns (uint256);

    function defaultFeeRate() external view returns (uint256);

    function projectExisted(address project_) external view returns (bool);

    function ownProjects(address owner_)
        external
        view
        returns (address[] memory);

    function project(address project_)
        external
        view
        returns (
            bool blocklisted_,
            address owner_,
            uint256 registerFrozen_,
            uint256 feeRate_,
            address[] memory tokens_,
            uint256[] memory fundFlows_,
            uint256[] memory pendingSettlements_
        );

    function order(address project_, bytes32 orderId_)
        external
        view
        returns (
            OrderType type_,
            uint256 expireTime_,
            address creator_,
            bytes memory data_,
            OrderStatus status_
        );
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

//SPDX-License-Identifier: GNU General Public License v2.0
pragma solidity ^0.8.0;

interface IAuthorizable {
    function defineAuthority(bytes32 authorityId_, bytes32 adminAuthorityId_)
        external;

    function defineAuthority(bytes32 authorityId_) external;

    function undefineAuthority(bytes32 authorityId_) external;

    function setAdminAuthority(bytes32 authorityId_, bytes32 adminAuthorityId_)
        external;

    function addAuthority(bytes32 authorityId_, address user_) external;

    function removeAuthority(bytes32 authorityId_, address user_) external;

    function authorityDefined(bytes32 authorityId_)
        external
        view
        returns (bool);

    function authority(bytes32 authorityId_)
        external
        view
        returns (bytes32 adminAuthorityId_, address[] memory mumbers);

    function hasAuthority(bytes32 authorityId_, address user_)
        external
        view
        returns (bool);
}

//SPDX-License-Identifier: GNU General Public License v2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

struct Authority {
    bytes32 adminAuthorityId;
    EnumerableSet.AddressSet mumbers;
}

//SPDX-License-Identifier: GNU General Public License v2.0
pragma solidity ^0.8.0;

import "../common/Enums.sol";

struct Order {
    address creator;
    OrderType orderType;
    uint256 expireTime;
    OrderStatus status;
    bytes data;
    PayType payType;
}