// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./Interfaces/ISleep.sol";
import "./Interfaces/IHealth.sol";
import "./Interfaces/IBedroomNft.sol";
import "./Interfaces/IUpgradeNft.sol";

/// @title GetSleepn Decentralized Exchange Contract
/// @author Sleepn
/// @notice This contract can be use to mint and upgrade a Bedroom NFT
contract Dex is Initializable, OwnableUpgradeable {
    /// @notice Sleep Token Contract
    ISleep public sleepTokenInstance;

    /// @notice Health Token Contract
    IHealth public healthTokenInstance;

    /// @notice Bedroom NFT Contract
    IBedroomNft public bedroomNftInstance;

    /// @notice UpgradeNFT Contract
    IUpgradeNft public upgradeNftInstance;

    /// @notice Dex Contract address
    address public teamWallet;

    /// @dev Dev Wallet
    address private devWallet;

    /// @notice Payment Token
    IERC20 public paymentToken;

    /// @notice Purchase cost and Upgrade cost
    uint256 public purchaseCost;

    /// @notice Upgrade costs
    struct Upgrade {
        uint256 designId; // Design Id
        uint256 data; // NFT Data
    }

    /// @notice Upgrade costs depending on the id of the Upgrade Nft
    mapping(uint256 => Upgrade) private upgradeCosts;
    
    /// @notice Packs costs
    struct Pack {
        uint256 designId; // Design Id
        uint256 price; // Price
        uint256[10] upgradeIds; // UpgradeIds
    }

    /// @notice Pack costs depending on the Pack ID
    mapping(uint256 => Pack) private packCosts;

    /// @notice Buy Bedroom NFT Event
    event BuyBedroomNft(
        address indexed owner,
        uint256 price,
        uint256 tokenId
    );

    /// @notice Buy Upgrade NFT Event
    event BuyUpgradeNft(
        address indexed owner,
        uint256 upgradeNftId,
        uint256 price,
        uint256 tokenId
    );

    /// @notice Withdraw Money Event
    event WithdrawMoney(address indexed receiver, uint256 price);

    /// @dev Constructor
    /// @param _teamWallet Team Wallet address
    function initialize(
        address _teamWallet
    ) public initializer {
        __Ownable_init();
        teamWallet = _teamWallet;
    }

    /// @notice Settles contracts addresses
    /// @param _sleepToken Address of the Sleep Token contract
    /// @param _healthToken Address of the Health Token contract
    /// @param _bedroomNft Address of the Bedroom NFT contract
    /// @param _upgradeNft Address of the Upgrade NFT contract
    /// @param _teamWallet New Team Wallet address
    /// @param _devWallet New Dev Wallet address
    /// @param _tokenAddress New Payment Token contract address
    /// @dev This function can only be called by the owner of the contract
    function setAddresses(
        ISleep _sleepToken,
        IHealth _healthToken,
        IBedroomNft _bedroomNft,
        IUpgradeNft _upgradeNft,
        address _teamWallet,
        address _devWallet,
        IERC20 _tokenAddress
    ) external onlyOwner {
        sleepTokenInstance = _sleepToken;
        bedroomNftInstance = _bedroomNft;
        upgradeNftInstance = _upgradeNft;
        teamWallet = _teamWallet;
        devWallet = _devWallet;
        paymentToken = _tokenAddress;
        healthTokenInstance = _healthToken;
    }

    /// @notice Settles NFTs purchase price
    /// @param _price Purchase price of the NFT
    /// @dev This function can only be called by the owner of the contract
    function setBuyingPrice(uint256 _price)
        external
        onlyOwner
    {
        purchaseCost = _price;
    }

    /// @notice Settles Packs data
    /// @param _upgradeIds Ids of the Upgrade Nfts
    /// @param _designId Bedroom NFT Design Id
    /// @param _price Purchase price of the Pack
    /// @param _packId Pack ID
    /// @dev This function can only be called by the owner of the contract
    function setPackPrice(
        uint256[10] memory _upgradeIds, 
        uint256 _designId,
        uint256 _price,
        uint256 _packId
    )
        external
    {
        require(msg.sender == owner() || msg.sender == devWallet, "Wrong sender");
        packCosts[_packId] = Pack(
            _designId,
            _price,
            _upgradeIds
        );
    }

    /// @notice Settles NFTs Upgrade data
    /// @param _price Purchase price of the Upgrade NFT
    /// @param _upgradeId Id of the upgrade
    /// @param _amount Amount of tokens to add to the Upgrade Nft
    /// @param _designId Upgrade Nft URI 
    /// @param _level Level to add to the Bedroom Nft
    /// @param _levelMin Bedroom Nft Level min required
    /// @param _attributeIndex Score involved (optionnal)
    /// @param _valueToAdd Value to add to the score (optionnal)
    /// @param _typeNft NFT Type 
    /// @param _data Additionnal data (optionnal)
    /// @dev This function can only be called by the owner of the contract
    function setUpgradeData(
        uint256 _price,
        uint256 _upgradeId,
        uint256 _amount,
        uint256 _designId,
        uint256 _level,
        uint256 _levelMin,
        uint256 _attributeIndex,
        uint256 _valueToAdd,
        uint256 _typeNft,
        uint256 _data
    ) external {
        require(msg.sender == owner() || msg.sender == devWallet, "Wrong sender");
        upgradeCosts[_upgradeId] = Upgrade(
            _designId,
            _level + (_levelMin << 16) + (_data << 32) + (_attributeIndex << 48) + (_valueToAdd << 64) + (_typeNft << 80) + (_price << 96) + (_amount << 112)
        );
    }

    /// @notice Settles NFTs Upgrade data - Batch transaction
    /// @param _price Purchase price of the Upgrade NFT
    /// @param _upgradeId Id of the upgrade
    /// @param _amount Amount of tokens to add to the Upgrade Nft
    /// @param _designId Upgrade Nft URI 
    /// @param _level Level to add to the Bedroom Nft
    /// @param _levelMin Bedroom Nft Level min required
    /// @param _attributeIndex Score involved (optionnal)
    /// @param _valueToAdd Value to add to the score (optionnal)
    /// @param _typeNft NFT Type 
    /// @param _data Additionnal data (optionnal)
    /// @dev This function can only be called by the owner or the dev Wallet
    function setUpgradeDataBatch(
        uint256[] memory _price,
        uint256[] memory _upgradeId,
        uint256[] memory _amount,
        uint256[] memory _designId,
        uint256[] memory _level,
        uint256[] memory _levelMin,
        uint256[] memory _attributeIndex,
        uint256[] memory _valueToAdd,
        uint256[] memory _typeNft,
        uint256[] memory _data
    ) external {
        require(
            msg.sender == owner() || msg.sender == devWallet,
            "Access Forbidden"
        );
        for(uint256 i = 0; i < _upgradeId.length; i++) {
            upgradeCosts[_upgradeId[i]] = Upgrade(
                _designId[i],
                _level[i] + (_levelMin[i] << 16) + (_data[i] << 32) + (_attributeIndex[i] << 48) + (_valueToAdd[i] << 64) + (_typeNft[i] << 80) + (_price[i] << 96) + (_amount[i] << 112)
            );
        }
    }

    /// @notice Returns the data of a Pack
    /// @param _packId Id of the Pack
    /// @return _designId Upgrade Nft URI 
    /// @return _price Purchase price of the Upgrade NFT
    /// @return _upgradeIds Upgrade Nfts ID
    function getPackData(uint256 _packId) 
        external 
        view 
        returns (
            uint256 _designId, // Design Id
            uint256 _price, // Price
            uint256[10] memory _upgradeIds // UpgradeIds
    ) {
        Pack memory spec = packCosts[_packId];
        _designId = spec.designId;
        _price = spec.price;
        _upgradeIds = spec.upgradeIds;
    }

    /// @notice Returns the data of an Upgrade Nft
    /// @param _upgradeId Id of the upgrade
    /// @return designId Upgrade Nft URI 
    /// @return price Purchase price of the Upgrade NFT
    /// @return amount Amount of tokens to add to the Upgrade Nft
    /// @return level Level to add to the Bedroom Nft
    /// @return levelMin Bedroom Nft Level min required
    /// @return attributeIndex Score involved (optionnal)
    /// @return valueToAdd Value to add to the score (optionnal)
    /// @return typeNft NFT Type 
    /// @return data Additionnal data (optionnal)
    function getUpgradeData(uint256 _upgradeId) 
        external 
        view 
        returns (
            uint256 designId,
            uint16 price,
            uint16 amount,
            uint16 level,
            uint16 levelMin,
            uint16 attributeIndex,
            uint16 valueToAdd,
            uint16 typeNft,
            uint16 data
    ) {
        Upgrade memory spec = upgradeCosts[_upgradeId];
        designId = spec.designId;
        level =  uint16(spec.data);
        levelMin = uint16(spec.data >> 16); 
        data = uint16(spec.data >> 32);
        attributeIndex = uint16(spec.data >> 48); 
        valueToAdd = uint16(spec.data >> 64);
        typeNft = uint16(spec.data >> 80);
        price = uint16(spec.data >> 96);
        amount = uint16(spec.data >> 112);
    }

    /// @notice Withdraws the money from the contract
    /// @dev This function can only be called by the owner or the dev Wallet
    function withdrawMoney() external {
        require(
            msg.sender == owner() || msg.sender == devWallet,
            "Access Forbidden"
        );
        uint256 balance = paymentToken.balanceOf(address(this));
        paymentToken.transfer(teamWallet, balance);
        emit WithdrawMoney(teamWallet, balance);
    }

    /// @notice Launches the mint procedure of a Bedroom NFT
    function buyBedroomNft()
        external
    {
        // Token Transfer
        paymentToken.transferFrom(msg.sender, address(this), purchaseCost);

        // NFT Minting
        uint256 tokenId = bedroomNftInstance.mintBedroomNft(
            msg.sender
        );

        emit BuyBedroomNft(
            msg.sender,
            purchaseCost,
            tokenId
        );
    }

    /// @notice Buy an Upgrade Nft
    /// @param _upgradeId Id of the Upgrade 
    function buyUpgradeNft(
        uint256 _upgradeId
    ) external {
        // Gets Upgrade data
        Upgrade memory spec = upgradeCosts[_upgradeId];

        // Burns tokens
        sleepTokenInstance.burnFrom(msg.sender, uint16(spec.data >> 96) * 1 ether);

        // Mints Upgrade NFT
        uint256 tokenId = upgradeNftInstance.mint(
            uint16(spec.data >> 112),
            spec.designId,
            msg.sender, 
            uint16(spec.data),
            uint16(spec.data >> 16),
            uint16(spec.data >> 48),
            uint16(spec.data >> 64),
            uint16(spec.data >> 80),
            uint16(spec.data >> 32)
        );

        emit BuyUpgradeNft(
            msg.sender,
            _upgradeId,
            uint16(spec.data >> 96),
            tokenId
        );
    }

    /// @notice Buy a Pack
    /// @param _packId Id of the Pack
    function buyPack(
        uint256 _packId
    ) external {
        // Gets Pack data
        Pack memory spec = packCosts[_packId];

        // Token Transfer
        paymentToken.transferFrom(msg.sender, address(this), spec.price);

        // NFT Minting
        uint256 bedroomNftId = bedroomNftInstance.mintBedroomNft(
            msg.sender
        );

        emit BuyBedroomNft(
            msg.sender,
            purchaseCost,
            bedroomNftId
        );

        for (uint256 i = 0; i < spec.upgradeIds.length; ++i) {
            // Gets Upgrade data
            Upgrade memory upgradeSpec = upgradeCosts[spec.upgradeIds[i]];

            // Mints Upgrade NFT
            uint256 upgradeNftId = upgradeNftInstance.mint(
                uint16(upgradeSpec.data >> 112),
                upgradeSpec.designId,
                msg.sender, 
                uint16(upgradeSpec.data),
                uint16(upgradeSpec.data >> 16),
                uint16(upgradeSpec.data >> 48),
                uint16(upgradeSpec.data >> 64),
                uint16(upgradeSpec.data >> 80),
                uint16(upgradeSpec.data >> 32)
            );

            emit BuyUpgradeNft(
                msg.sender,
                upgradeSpec.designId,
                uint16(upgradeSpec.data >> 96),
                upgradeNftId
            );

            upgradeNftInstance.linkUpgradeNft(
                upgradeNftId,
                bedroomNftId,
                spec.designId,
                msg.sender
            );
        }
    }

    /// @notice Links an Upgrade Nft
    /// @param _upgradeNftId Id of the Upgrade NFT
    /// @param _bedroomNftId Id of the Bedroom NFT
    /// @param _newDesignId New Design Id of the Bedroom NFT
    function linkUpgradeNft(
        uint256 _upgradeNftId, 
        uint256 _bedroomNftId, 
        uint256 _newDesignId
    ) external {
        upgradeNftInstance.linkUpgradeNft(
            _upgradeNftId,
            _bedroomNftId,
            _newDesignId,
            msg.sender
        );
    }

    /// @notice Links an Upgrade Nft - Batch transaction
    /// @param _upgradeNftIds IDs of the Upgrade NFTs
    /// @param _bedroomNftId Id of the Bedroom NFT
    /// @param _newDesignId New Design Id of the Bedroom NFT
    function linkUpgradeNftBatch(
        uint256[] memory _upgradeNftIds, 
        uint256 _bedroomNftId, 
        uint256 _newDesignId
    ) external {
        for (uint256 i = 0; i < _upgradeNftIds.length; ++i) {
            upgradeNftInstance.linkUpgradeNft(
                _upgradeNftIds[i],
                _bedroomNftId,
                _newDesignId,
                msg.sender
            );   
        }
    }

    /// @notice Unlinks an Upgrade Nft
    /// @param _upgradeNftId Id of the Upgrade NFT
    /// @param _newDesignId New Design Id of the Bedroom NFT
    function unlinkUpgradeNft(
        uint256 _upgradeNftId, 
        uint256 _newDesignId
    ) external {
        upgradeNftInstance.unlinkUpgradeNft(
            _upgradeNftId,
            msg.sender,
            _newDesignId
        );
    }

    /// @notice Airdrops some Bedroom NFTs
    /// @param _addresses Addresses of the receivers 
    /// @dev This function can only be called by the owner of the contract
    function airdropBedroomNFT(
        address[] memory _addresses
    ) external onlyOwner {
        for(uint256 i=0; i<_addresses.length; i++) {
            bedroomNftInstance.mintBedroomNft(
                _addresses[i]
            );
        }
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface of $Sleep Contract
/// @author Sleepn
/// @notice $Sleep is the official token of Sleepn
interface ISleep is IERC20 {
    /// @notice Stops the contract
    /// @dev This function can only be called by the owner of the contract
    function pause() external;

    /// @notice Starts the contract
    /// @dev This function can only be called by the owner of the contract
    function unpause() external;

    /// @notice Mints tokens 
    /// @param _amount Amount of tokens to mint
    /// @dev This function can only be called by the owner 
    function mint(uint256 _amount) external;

    /// @notice Burns tokens 
    /// @param _account Tokens owner address 
    /// @param _amount Tokens amount to burn
    function burnFrom(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface of $Health Contract
/// @author Sleepn
/// @notice $Health is the governance token of Sleepn
interface IHealth is IERC20 {
    /// @notice Stops the contract
    /// @dev This function can only be called by the owner of the contract
    function pause() external;

    /// @notice Starts the contract
    /// @dev This function can only be called by the owner of the contract
    function unpause() external;

    /// @notice Mints tokens 
    /// @param _to Tokens receiver address
    /// @param _amount Amount of tokens to mint
    /// @dev This function can only be called by the owner 
    function mint(address _to, uint256 _amount) external;

    /// @notice Burns tokens 
    /// @param _account Tokens owner address 
    /// @param _amount Tokens amount to burn
    function burnFrom(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "./IUpgradeNft.sol";

/// @title Interface of the Bedroom NFT Contract
/// @author Sleepn
/// @notice Bedroom NFT is the main NFT of GetSleepn app
interface IBedroomNft is IERC1155 {
    /// @notice Scores of a Bedroom NFT
    struct NftSpecifications {
        address owner;
        uint64 scores; 
        uint256 level;
    }

    /// @notice Emits an event when a Bedroom NFT is minted
    event BedroomNftMinting(
        address indexed owner,
        uint256 tokenId,
        uint16 ambiance, 
        uint16 quality, 
        uint16 luck, 
        uint16 confortability
    );

    /// @notice Emits an event when a Bedroom NFT Score is upgraded
    event BedroomNftScoreUpgrading(
        address indexed owner,
        uint256 tokenId,
        uint256 newDesignId,
        uint256 amount, 
        uint256 level,
        uint16 ambiance, 
        uint16 quality, 
        uint16 luck, 
        uint16 confortability
    );

    /// @notice Emits an event when a Bedroom NFT Score is downgraded
    event BedroomNftScoreDowngrading(
        address indexed owner,
        uint256 tokenId,
        uint256 newDesignId,
        uint256 amount, 
        uint256 level,
        uint16 ambiance, 
        uint16 quality, 
        uint16 luck, 
        uint16 confortability
    );

    /// @notice Emits an event when a Bedroom NFT Level is upgraded
    event BedroomNftLevelUpgrading(
        address indexed owner,
        uint256 tokenId,
        uint256 level
    );

    /// @notice Emits an event when a Bedroom NFT Level is downgraded
    event BedroomNftLevelDowngrading(
        address indexed owner,
        uint256 tokenId,
        uint256 level
    );

    /// @notice Emits an event when a Bedroom NFT Design is upgraded
    event BedroomNftDesignUpgrading(
        address indexed owner,
        uint256 tokenId,
        uint256 newDesignId,
        uint256 amount, 
        uint256 level
    );

    /// @notice Emits an event when a Bedroom NFT Design is downgraded
    event BedroomNftDesignDowngrading(
        address indexed owner,
        uint256 tokenId,
        uint256 newDesignId,
        uint256 amount, 
        uint256 level
    );

    /// @notice Returned Random Numbers Event
    event ReturnedRandomness(uint256[] randomWords);

    /// @notice Returns the data of a NFT 
    /// @param _tokenId The id of the NFT
    /// @return _ambiance Score 1
    /// @return _quality Score 2
    /// @return _luck Score 3
    /// @return _confortability Score 4
    /// @return _owner NFT Owner
    /// @return _level NFT Level
    function getScores(
        uint256 _tokenId
    ) external view returns(
        uint16 _ambiance, 
        uint16 _quality, 
        uint16 _luck, 
        uint16 _confortability,
        address _owner,
        uint256 _level
    );

    /// @notice Updates chainlink variables
    /// @param _callbackGasLimit Callback Gas Limit
    /// @param _subscriptionId Chainlink subscription Id
    /// @param _keyHash Chainlink Key Hash
    /// @param _requestConfirmations Number of request confirmations
    /// @dev This function can only be called by the owner of the contract
    function updateChainlink(
        uint32 _callbackGasLimit,
        uint64 _subscriptionId,
        bytes32 _keyHash,
        uint16 _requestConfirmations
    ) external;

    /// @notice Settles File format
    /// @param _format New file format
    /// @dev This function can only be called by the owner of the contract
    function setFileFormat(string memory _format) external;

    /// @notice Launches the procedure to create an NFT
    /// @param _owner Owner of the NFT
    /// @return _tokenId NFT ID
    /// @dev This function can only be called by Dex Contract
    function mintBedroomNft(
        address _owner
    ) external returns (uint256 _tokenId);

    /// Gets the name of a Nft
    /// @param _tokenId Id of the NFT
    /// @return _name Name of thr NFT
    function getName(uint256 _tokenId)
        external
        view
        returns (string memory _name);

    /// @notice Returns the owner of a NFT
    /// @param _tokenId The id of the NFT
    /// @return _owner NFT owner address
    function getNftsOwner(uint256 _tokenId) external view returns(address _owner);

    /// @notice Returns the level of a NFT
    /// @param _tokenId The id of the NFT
    /// @return _level NFT level
    function getNftsLevel(uint256 _tokenId) external view returns(uint256 _level);

    /// @notice Launches the procedure to update the scores of a NFT
    /// @param _tokenId Id of the NFT
    /// @param _attributeIndex Index of the attribute to upgrade
    /// @param _newDesignId New design Id of the NFT
    /// @param _amount Price of the upgrade
    /// @param _level Level to add to the Nft
    /// @param _value Value to add to the attribute score
    /// @param _action Action to do
    /// @dev This function can only be called by Dex Contract
    function updateScores(
        uint256 _tokenId,
        uint256 _attributeIndex,
        uint256 _newDesignId,
        uint256 _amount, 
        uint256 _level,
        uint16 _value,
        bool _action   
    ) external;

    /// @notice Launches the procedure to update the level of a NFT
    /// @param _tokenId Id of the NFT
    /// @param _level Level to add to the Nft
    /// @param _action Action to do
    /// @dev This function can only be called by Dex Contract
    function updateLevel(
        uint256 _tokenId, 
        uint256 _level,
        bool _action   
    ) external;

    /// @notice Launches the procedure to update the level of a NFT
    /// @param _tokenId Id of the NFT
    /// @param _newDesignId New design Id of the NFT
    /// @param _amount Price of the upgrade
    /// @param _level Level to add to the Nft
    /// @param _action Action to do
    /// @dev This function can only be called by Dex Contract
    function updateDesign(
        uint256 _tokenId, 
        uint256 _newDesignId,
        uint256 _amount,
        uint256 _level,
        bool _action
    ) external;

    /// @notice Settles Token URL
    /// @dev This function can only be called by the owner of the contract
    function setTokenURI(uint256 _tokenId, string memory _tokenURI) external;

    /// @notice Settles Base URL
    /// @dev This function can only be called by the owner of the contract
    function setBaseURI(string memory _baseURI) external;

    /// @notice Returns the number of Nfts owned by an address
    /// @param _owner Owner address
    /// @return _number NFTs number
    function getNftsNumber(address _owner) 
        external
        view
        returns (uint256);

    /// @notice TransferOwnership
    /// @param _newOwner New Owner address
    function transferOwnership(address _newOwner) external;

     /// @notice Returns the balance of a NFT
    /// @param _tokenId The id of the NFT
    /// @return _balance NFT balance
    function getNftsBalance(uint256 _tokenId) external view returns(uint256 _balance);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "./IBedroomNft.sol";

/// @title Interface of the Upgrade Nft Contract
/// @author Sleepn
/// @notice An update NFT is used to upgrade a Bedroom NFT
interface IUpgradeNft is IERC1155 {
    /// @notice Upgrade Specifications
    struct UpgradeSpecifications {
        uint256 bedroomNftId;
        uint64 data;
        bool isUsed;
        address owner;
    }

    /// @notice Upgrade NFT Minting Event
    event UpgradeNftMinting(
        address indexed owner,
        uint256 tokenId,
        uint256 designId,
        uint16 level, 
        uint16 levelMin, 
        uint16 data,
        uint8 attributeIndex, 
        uint8 valueToAdd,
        uint8 typeNft
    );

    /// @notice Upgrade Nft linked
    event UpgradeNftLinked(
        address indexed owner,
        uint256 upgradeNftId,
        uint256 bedroomNftId
    );

    /// @notice Upgrade Nft unlinked
    event UpgradeNftUnlinked(
        address indexed owner,
        uint256 upgradeNftId,
        uint256 bedroomNftId
    );

    /// @notice Returns the  data of a NFT
    /// @param _tokenId NFT ID
    /// @return _bedroomNftId NFT ID
    /// @return _level NFT level
    /// @return _levelMin NFT level min required
    /// @return _data NFT additionnal data
    /// @return _attributeIndex Score attribute index
    /// @return _valueToAdd Value to add to the score
    /// @return _typeNft NFT Type 
    /// @return _isUsed Is linked to a Bedroom NFT
    /// @return _owner NFT Owner
    function getNftData(uint256 _tokenId) 
        external 
        view 
        returns (
            uint256 _bedroomNftId,
            uint16 _level, 
            uint16 _levelMin, 
            uint16 _data,
            uint8 _attributeIndex, 
            uint8 _valueToAdd,
            uint8 _typeNft,
            bool _isUsed,
            address _owner
    );

    /// @notice Links an upgrade Nft to a bedroom Nft
    /// @param _upgradeNftId Id of the Upgrade NFT
    /// @param _bedroomNftId Id of the Bedroom NFT
    /// @param _newDesignId New Design Id of the Bedroom NFT
    /// @param _owner Owner of the NFT
    /// @dev This function can only be called by Dex Contract or Owner
    function linkUpgradeNft(
        uint256 _upgradeNftId,
        uint256 _bedroomNftId,
        uint256 _newDesignId,
        address _owner
    ) external;

    /// @notice Unlinks an upgrade Nft to a bedroom Nft
    /// @param _upgradeNftId Id of the Upgrade NFT
    /// @param _owner Owner of the NFT
    /// @param _newDesignId New Design Id of the Bedroom NFT
    /// @dev This function can only be called by Dex Contract
    function unlinkUpgradeNft(
        uint256 _upgradeNftId,
        address _owner,
        uint256 _newDesignId
    ) external;

    /// @notice Settles File format
    /// @param _format New file format
    /// @dev This function can only be called by the owner of the contract
    function setFileFormat(string memory _format) external;

    /// @notice Gets the name of an NFT
    /// @param _tokenId Id of the NFT
    function getName(uint256 _tokenId) external pure returns (string memory);

    /// @notice Settles Token URL
    /// @dev This function can only be called by the owner of the contract
    function setTokenURI(uint256 _tokenId, string memory _tokenURI) external;

    /// @notice Settles Base URL
    /// @dev This function can only be called by the owner of the contract
    function setBaseURI(string memory _baseURI) external;

    /// @notice Mints an Upgrade Nft
    /// @param _amount Amount of tokens to add to the Upgrade Nft
    /// @param _designId Upgrade Nft URI 
    /// @param _account Upgrade Nft Owner
    /// @param _level Level to add to the Bedroom Nft
    /// @param _levelMin Bedroom Nft Level min required
    /// @param _attributeIndex Score involved (optionnal)
    /// @param _valueToAdd Value to add to the score (optionnal)
    /// @param _typeNft NFT Type 
    /// @param _data Additionnal data (optionnal)
    /// @return _tokenId NFT ID
    /// @dev This function can only be called by the owner or the dev Wallet
    function mint(
        uint256 _amount,
        uint256 _designId,
        address _account, 
        uint64 _level,
        uint64 _levelMin,
        uint64 _attributeIndex,
        uint64 _valueToAdd,
        uint64 _typeNft,
        uint64 _data
    )
        external returns (uint256 _tokenId);

    /// @notice Mints Upgrade Nfts per batch
    /// @param _amount Amount of tokens to add to the Upgrade Nft
    /// @param _designId Upgrade Nft URI 
    /// @param _accounts Upgrade Nft Owner
    /// @param _level Level to add to the Bedroom Nft
    /// @param _levelMin Bedroom Nft Level min required
    /// @param _attributeIndex Score involved (optionnal)
    /// @param _valueToAdd Value to add to the score (optionnal)
    /// @param _typeNft NFT Type 
    /// @param _data Additionnal data (optionnal)
    /// @return _tokenIds NFTs ID
    /// @dev This function can only be called by the owner or the dev Wallet
    function mintBatch(
        uint256 _amount,
        uint256 _designId,
        address[] memory _accounts, 
        uint64 _level,
        uint64 _levelMin,
        uint64 _attributeIndex,
        uint64 _valueToAdd,
        uint64 _typeNft,
        uint64 _data
    )
        external returns (uint256[] memory _tokenIds);
    
    /// @notice Transfers an Upgrade Nft
    /// @param _tokenId Id of the NFT
    /// @param _newOwner Receiver address 
    function transferUpgradeNft(uint256 _tokenId, address _newOwner) external;

    /// @notice TransferOwnership
    /// @param _newOwner New Owner address
    function transferOwnership(address _newOwner) external;

    /// @notice Returns the balance of a NFT
    /// @param _tokenId The id of the NFT
    /// @return _balance NFT balance
    function getNftsBalance(uint256 _tokenId) external view returns(uint256 _balance);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}