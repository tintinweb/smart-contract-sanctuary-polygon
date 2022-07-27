//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "../wallet/factory/IWalletFactory.sol";
import "../wallet/IHolderWallet.sol";
import "../token/factory/IwNFTFactory.sol";
import "../token/IwNFT.sol";
import "../utils/TokenSupportChecker.sol";

import "./IRenfterErrors.sol";
import "./IRenfterEvents.sol";
import "./IRenfter.sol";

contract Renfter is
    Initializable,
    OwnableUpgradeable,
    IRenfter,
    IRenfterErrors,
    IRenfterEvents
{
    using TokenSupportChecker for address;
    using AddressUpgradeable for address;

    uint256 private constant MIN_RENT_DURATION = 1 days;

    /// @dev Address of `wNFTFactory` contract
    address private _wNFTFactory;
    /// @dev Address of `WalletFactory` contract
    address private _walletFactory;
    /// @dev Origin contract to wContract address
    mapping(address => address) private _wNFTs;
    /// @dev wContract origin contract address
    mapping(address => address) private _originContracts;
    /// @dev wContract to token ID to wallet with original token
    mapping(address => mapping(uint256 => address)) private _wallets;
    /// @dev wContract to token ID to Rental condition
    mapping(address => mapping(uint256 => RentConditions)) private _conditions;
    /// @dev wContract to token ID to expirationTs
    mapping(address => mapping(uint256 => uint256)) private _expirationTs;
    /// @dev wContract to token ID to original owner address
    mapping(address => mapping(uint256 => address)) private _originOwners;

    modifier nonZeroAddress(address addr) {
        if (addr == address(0)) {
            revert ZeroAddressPassed(msg.sig);
        }
        _;
    }

    modifier onlyWNFT() {
        address sender = _msgSender();
        if (_originContracts[sender] == address(0))
            revert SenderNotWNFT(sender);
        _;
    }

    modifier notRented(address wContract, uint256 tokenId) {
        if (!_checkRentalExpired(wContract, tokenId))
            revert TokenRentInProgress(wContract, tokenId);
        _;
    }

    modifier wrapperExists(address wContract) {
        if (_originContracts[wContract] == address(0))
            revert WrapperNotExisting(wContract);
        _;
    }

    modifier senderOTokenOwner(address wContract, uint256 tokenId) {
        if (_originOwners[wContract][tokenId] != _msgSender())
            revert SenderNotOriginTokenOwner(wContract, tokenId);
        _;
    }

    modifier tokenOfferedForRent(address wContract, uint256 tokenId) {
        if (_conditions[wContract][tokenId].pricePerDay == 0)
            revert TokenNotOfferedForRenting(wContract, tokenId);
        _;
    }

    /// @dev Initializer method
    /// @param wNFTFactory `wNFT` factory contract address
    /// @param walletFactory `HolderWallet` contract address
    function initialize(address wNFTFactory, address walletFactory)
        external
        initializer
    {
        __Ownable_init();
        _setWNFTFactory(wNFTFactory);
        _setWalletFactory(walletFactory);
    }

    /// @dev Sets address of `wNFTFactory` contract
    /// @param  wNFTFactory `wNFTFactory` contract address
    function setWNFTFactory(address wNFTFactory) external onlyOwner {
        _setWNFTFactory(wNFTFactory);
    }

    /// @dev Sets address of `WalletFactory` contract
    /// @param  walletFactory `WalletFactory` contract address
    function setWalletFactory(address walletFactory) external onlyOwner {
        _setWalletFactory(walletFactory);
    }

    /// @dev Creates wrapper contract for collection
    /// @param originContract Address of contract being wrapped
    function wrapCollection(address originContract) external {
        (bool supports721, bool supports1155) = originContract.getSupportsErc();

        if (!(supports721 || supports1155))
            revert Not721or1155Compatible(originContract);

        address wNFT = _wNFTs[originContract];
        if (wNFT != address(0)) {
            revert CollectionAlreadyWrapped(originContract, wNFT);
        }

        address newToken = IwNFTFactory(_wNFTFactory).createToken(
            originContract,
            address(this),
            owner()
        );

        _originContracts[newToken] = originContract;
        _wNFTs[originContract] = newToken;
    }

    /// @dev Creates a wrapper token of origin contract with same token identifier.
    /// It locks origin token in `HolderWallet` and mints wrapper token to origin token owner
    /// @param originContract Address of contract which token is being wrapped
    /// @param tokenId Token identifier
    function wrapToken(address originContract, uint256 tokenId) external {
        address wNFT = _wNFTs[originContract];

        if (wNFT == address(0)) revert CollectionNotWrapped(originContract);

        if (IwNFT(wNFT).exists(tokenId))
            revert TokenAlreadyWrapped(originContract, tokenId);

        (bool supports721, ) = originContract.getSupportsErc();

        address holderWallet = _getOrCreateWallet(wNFT, tokenId);
        address renfter = address(this);
        address sender = _msgSender();

        if (supports721) {
            if (IERC721(originContract).ownerOf(tokenId) != sender)
                revert NotOriginTokenOwner();

            if (IERC721(originContract).getApproved(tokenId) != renfter)
                revert RenfterNotApproved();

            IERC721(originContract).safeTransferFrom(
                sender,
                holderWallet,
                tokenId,
                ""
            );
        } else {
            if (IERC1155(originContract).balanceOf(sender, tokenId) == 0)
                revert NotEnoughTokenBalance();

            if (!IERC1155(originContract).isApprovedForAll(sender, renfter))
                revert RenfterNotApproved();

            IERC1155(originContract).safeTransferFrom(
                sender,
                holderWallet,
                tokenId,
                1,
                ""
            );
        }

        _originOwners[wNFT][tokenId] = sender;
        IwNFT(wNFT).mint(sender, tokenId);
        emit TokenWrapped(originContract, wNFT, tokenId);
    }

    /// @dev Unwraps previously wrapped token and returns origin token to initial owner
    /// @param wContract Address of wrapper contract
    /// @param tokenId Token identifier
    function unwrapToken(address wContract, uint256 tokenId)
        external
        wrapperExists(wContract)
        senderOTokenOwner(wContract, tokenId)
        notRented(wContract, tokenId)
    {
        address sender = _msgSender();
        IwNFT(wContract).burn(tokenId);

        address originContract = _originContracts[wContract];
        address holderWallet = _getOrCreateWallet(wContract, tokenId);
        (bool supports721, ) = originContract.getSupportsErc();

        bytes memory encodedCall;
        if (supports721) {
            encodedCall = abi.encodeWithSelector(
                IERC721.transferFrom.selector,
                holderWallet,
                sender,
                tokenId
            );
        } else {
            encodedCall = abi.encodeWithSelector(
                IERC1155.safeTransferFrom.selector,
                holderWallet,
                sender,
                tokenId,
                1,
                ""
            );
        }

        IHolderWallet(holderWallet).execute(originContract, 0, encodedCall);
        emit TokenUnwrapped(wContract, tokenId);
    }

    /// @dev Sets wrapped token as ready for renting by setting rent conditions
    /// @param wContract Address of wrapper contract
    /// @param tokenId Token identifier
    /// @param conditions Rent conditions that needs to be met by renters
    function offerForRent(
        address wContract,
        uint256 tokenId,
        RentConditions calldata conditions
    )
        external
        wrapperExists(wContract)
        senderOTokenOwner(wContract, tokenId)
        notRented(wContract, tokenId)
    {
        if (conditions.pricePerDay == 0)
            revert InvalidPriceValue(conditions.pricePerDay);

        if (conditions.maxRentDuration <= MIN_RENT_DURATION)
            revert InvalidMaxDuration(conditions.maxRentDuration);

        _conditions[wContract][tokenId] = conditions;

        emit TokenOfferedForRent(
            wContract,
            tokenId,
            conditions.pricePerDay,
            conditions.maxRentDuration,
            uint8(conditions.rewardRule)
        );
    }

    /// @dev Sets previously listed token as unavailable for renting
    /// @param wContract Address of wrapper contract
    /// @param tokenId Token identifier
    function removeRentalOffer(address wContract, uint256 tokenId)
        external
        wrapperExists(wContract)
        senderOTokenOwner(wContract, tokenId)
        tokenOfferedForRent(wContract, tokenId)
        notRented(wContract, tokenId)
    {
        _conditions[wContract][tokenId].pricePerDay = 0;

        emit RentalOfferRemoved(wContract, tokenId);
    }

    /// @dev Rents wrapper token that was previously listed for renting
    /// @param wContract Address of wrapper contract
    /// @param tokenId Token identifier
    /// @param duration Rent duration (in seconds)
    function rentToken(
        address wContract,
        uint256 tokenId,
        uint256 duration
    )
        external
        payable
        wrapperExists(wContract)
        tokenOfferedForRent(wContract, tokenId)
        notRented(wContract, tokenId)
    {
        RentConditions storage conditions = _conditions[wContract][tokenId];

        if (
            duration < MIN_RENT_DURATION ||
            duration > conditions.maxRentDuration
        )
            revert InvalidRentalDuration(
                duration,
                MIN_RENT_DURATION,
                conditions.maxRentDuration
            );

        if (msg.value < (duration / 1 days) * conditions.pricePerDay)
            revert NotEnoughFundsSendForRent(msg.value);

        address originOwner = _originOwners[wContract][tokenId];

        _expirationTs[wContract][tokenId] = block.timestamp + duration;

        IERC721(wContract).transferFrom(originOwner, _msgSender(), tokenId);
        AddressUpgradeable.sendValue(payable(originOwner), msg.value);

        emit TokenRented(
            wContract,
            tokenId,
            duration,
            _expirationTs[wContract][tokenId]
        );
    }

    /// @dev Transfers rewards/drops received by `HolderWallet` if rent conditions are meet
    /// @param wContract Address of wrapper contract
    /// @param wTokenId Address of wrapper contract token
    /// @param rewardContracts Addreses of token contracts rewards/drops are given
    /// @param tokenIds Token identifiers that were given/dropped
    function collectRewards(
        address wContract,
        uint256 wTokenId,
        address[] calldata rewardContracts,
        uint256[] calldata tokenIds
    ) external {
        bool allowCollect;
        address sender = _msgSender();
        bool rentInProgress = _expirationTs[wContract][wTokenId] > 0;
        RewardRule rewardRule = _conditions[wContract][wTokenId].rewardRule;

        if (sender == _originOwners[wContract][wTokenId]) {
            if (rentInProgress) {
                allowCollect = (rewardRule == RewardRule.ALL_RENTEE);
            } else {
                allowCollect = true;
            }
        } else if (
            sender == IERC721(_originContracts[wContract]).ownerOf(wTokenId)
        ) {
            allowCollect =
                rentInProgress &&
                (rewardRule == RewardRule.ALL_RENTER);
        }

        if (allowCollect) {
            _pullRewards(
                _wallets[wContract][wTokenId],
                sender,
                rewardContracts,
                tokenIds
            );
        } else {
            revert RewardsCollectNotAllowed(sender, wContract, wTokenId);
        }
    }

    /// @dev Transfers rewards/drops from `HolderWallet`
    /// @param wallet Address of `HolderWallet` contract
    /// @param recipient Address of recipient
    /// @param rewardContracts Addreses of token contracts rewards/drops are given
    /// @param tokenIds Token identifiers that were given/dropped
    function _pullRewards(
        address wallet,
        address recipient,
        address[] memory rewardContracts,
        uint256[] memory tokenIds
    ) internal {
        for (uint256 i = 0; i < rewardContracts.length; i++) {
            address rewardContract = rewardContracts[i];
            uint256 tokenId = tokenIds[i];
            (bool supports721, bool supports1155) = rewardContract
                .getSupportsErc();

            bytes memory encodedCall;
            if (supports721) {
                encodedCall = abi.encodeWithSelector(
                    IERC721.transferFrom.selector,
                    wallet,
                    recipient,
                    tokenId
                );
            } else if (supports1155) {
                uint256 balance = IERC1155(rewardContract).balanceOf(
                    wallet,
                    tokenId
                );
                encodedCall = abi.encodeWithSelector(
                    IERC1155.safeTransferFrom.selector,
                    wallet,
                    recipient,
                    tokenId,
                    balance,
                    ""
                );
            } else {
                uint256 walletBalance;
                try IERC20(rewardContract).balanceOf(wallet) returns (
                    uint256 balance
                ) {
                    walletBalance = balance;
                } catch {
                    revert RevertedReadingBalance(rewardContract);
                }

                if (walletBalance > 0) {
                    encodedCall = abi.encodeWithSelector(
                        IERC20.transferFrom.selector,
                        wallet,
                        recipient,
                        walletBalance
                    );
                }
            }

            try
                IHolderWallet(wallet).execute(rewardContract, 0, encodedCall)
            {} catch Error(string memory reason) {
                revert WalletExecuteCallReverted(reason);
            }
        }
    }

    /// @inheritdoc IRenfter
    function checkRentalExpired(address wContract, uint256 tokenId)
        external
        returns (bool)
    {
        return _checkRentalExpired(wContract, tokenId);
    }

    /// @dev Retrieves `WalletFactory` address
    /// @return `WalletFactory` contract address
    function getWalletFactory() external view returns (address) {
        return _walletFactory;
    }

    /// @dev Retrieves `wNFTFactory` address
    /// @return `wNFTFactory` contract address
    function getWNFTFactory() external view returns (address) {
        return _wNFTFactory;
    }

    /// @dev Returns origin token data based on wrapped token
    /// @param wContract Address of wrapper contract
    /// @param tokenId Token identifier
    /// @return originAddress Address of origin contract
    /// @return originTokenOwner Owner of origin token
    /// @return wTokenOwner Owner of wrapper token
    function getOriginTokenData(address wContract, uint256 tokenId)
        external
        view
        returns (
            address originAddress,
            address originTokenOwner,
            address wTokenOwner
        )
    {
        originAddress = _originContracts[wContract];
        originTokenOwner = _originOwners[wContract][tokenId];
        wTokenOwner = IERC721(wContract).ownerOf(tokenId);
    }

    /// @dev Returns wrapper token data based on origin token
    /// @param originContract Address of origin contract
    /// @param tokenId Token identifier
    /// @return wContract Address of wrapper contract
    /// @return wTokenOwner Owner of wrapper token
    function getWrapperTokenData(address originContract, uint256 tokenId)
        external
        view
        returns (address wContract, address wTokenOwner)
    {
        wContract = _wNFTs[originContract];
        if (IwNFT(wContract).exists(tokenId))
            wTokenOwner = IERC721(wContract).ownerOf(tokenId);
    }

    /// @dev Returns `HolderWallet` contract address based on wrapper token
    /// @param wContract Address of wrapper contract
    /// @param tokenId Token identifier
    function getHolderWallet(address wContract, uint256 tokenId)
        external
        view
        returns (address)
    {
        return _wallets[wContract][tokenId];
    }

    /// @inheritdoc IRenfter
    function getOriginContract(address wContract)
        external
        view
        returns (address)
    {
        return _originContracts[wContract];
    }

    /// @dev Returns rent conditions for wrapper token
    /// @param wContract Address of wrapper contract
    /// @param tokenId Token identifier
    function getRentConditions(address wContract, uint256 tokenId)
        external
        view
        returns (RentConditions memory)
    {
        return _conditions[wContract][tokenId];
    }

    /// @dev Returns expiration timestamp for wrapper token
    /// @param wContract Address of wrapper contract
    /// @param tokenId Token identifier
    function getExpirationTs(address wContract, uint256 tokenId)
        external
        view
        returns (uint256)
    {
        return _expirationTs[wContract][tokenId];
    }

    /// @dev Sets address of `wNFTFactory` contract
    /// @param wNFTFactory `wNFTFactory` contract address
    function _setWNFTFactory(address wNFTFactory)
        private
        nonZeroAddress(wNFTFactory)
    {
        address prevValue = _wNFTFactory;
        _wNFTFactory = wNFTFactory;
        emit TokenFactoryChanged(prevValue, wNFTFactory);
    }

    /// @dev Sets address of `WalletFactory` contract
    /// @param  walletFactory `WalletFactory` contract address
    function _setWalletFactory(address walletFactory)
        private
        nonZeroAddress(walletFactory)
    {
        address prevValue = _walletFactory;
        _walletFactory = walletFactory;
        emit WalletFactoryChanged(prevValue, walletFactory);
    }

    /// @dev Retrieves if exists or creates new wallet
    /// @param wContract Address of wrapper contract
    /// @param tokenId Token identifier
    /// @return wallet Address of wallet
    function _getOrCreateWallet(address wContract, uint256 tokenId)
        private
        returns (address wallet)
    {
        wallet = _wallets[wContract][tokenId];
        if (wallet == address(0)) {
            address newWallet = IWalletFactory(_walletFactory).createWallet(
                wContract,
                tokenId,
                address(this)
            );

            _wallets[wContract][tokenId] = newWallet;
            wallet = newWallet;
        }
    }

    /// @dev Checks if rental period expired for wrapper token and returns it to owner if it does
    /// @param wContract Address of wrapper contract
    /// @param tokenId Token identifier
    /// @return expired Boolean determinating if rental period has expired
    function _checkRentalExpired(address wContract, uint256 tokenId)
        private
        returns (bool expired)
    {
        uint256 expirationTs = _expirationTs[wContract][tokenId];

        if (expirationTs == 0) {
            expired = true;
        } else if (expirationTs < block.timestamp) {
            address currentOwner = IERC721(wContract).ownerOf(tokenId);
            IERC721(wContract).transferFrom(
                currentOwner,
                _originOwners[wContract][tokenId],
                tokenId
            );

            delete _expirationTs[wContract][tokenId];

            emit TokenRentalExpired(wContract, tokenId);
            expired = true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
pragma solidity 0.8.15;

/// @title IWalletFactory
/// @dev Interface for creating wallet instances
interface IWalletFactory {
    /// @dev Creates a new contract wallet
    /// @param wNFT Address of wrapper contract wallet is holding original token for
    /// @param tokenId ID of the wrapped contract token
    /// @param _owner Address for owner
    /// @return Created wallet address
    function createWallet(
        address wNFT,
        uint256 tokenId,
        address _owner
    ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/// @title IHolderWallet
/// @dev Interface for creating escrow wallet instances for wrapped NFTs
interface IHolderWallet {
    /// @notice Executes `call` defined by passed parameters
    /// @param to Target smart contract
    /// @param value Value send via call
    /// @param data Calldata send via call (function + data)
    /// @return Data returned by `call` function
    function execute(
        address to,
        uint256 value,
        bytes calldata data
    ) external payable returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/// @title IwNFTFactory
/// @dev Interface for creating wrapper NFT instances
interface IwNFTFactory {
    /// @dev Creates a new wrapper NFT contract
    /// @param originContract Address of origin contract
    /// @param renfter `Renfter` contract address
    /// @param _owner Owner of token
    /// @return Created token address
    function createToken(
        address originContract,
        address renfter,
        address _owner
    ) external returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/// @title IwNFT interface
interface IwNFT {
    /// @dev Mints token with id `tokenID` to address defined with `to`
    /// @param to Recipient address
    /// @param tokenId Token identifier
    function mint(address to, uint256 tokenId) external;

    /// @dev Burns token with passed ID
    /// @param tokenId Token identifier
    function burn(uint256 tokenId) external;

    /// @dev Checks if token with passed ID exists
    /// @return Boolean determinating if token exists
    function exists(uint256 tokenId) external view returns (bool);

    /// @dev Returns `Renfter` address associated to token
    /// @return `Renfter` address
    function getRenfter() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

library TokenSupportChecker {
    /**
     * @dev Checks if contract address is implementing IERC721 or IERC1155
     * @param addr Address being checked
     * @return supports721 Boolean if contract supports ERC-721
     * @return supports1155 Boolean if contract supports ERC-1155
     *
     */
    function getSupportsErc(address addr)
        internal
        view
        returns (bool supports721, bool supports1155)
    {
        supports721 = ERC165Checker.supportsInterface(
            addr,
            type(IERC721).interfaceId
        );

        if (!supports721) {
            supports1155 = ERC165Checker.supportsInterface(
                addr,
                type(IERC1155).interfaceId
            );
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IRenfterErrors {
    error CollectionAlreadyWrapped(address originContract, address wContract);
    error SenderNotWNFT(address sender);
    error TokenAlreadyWrapped(address originContract, uint256 tokenId);
    error Not721or1155Compatible(address originContract);
    error NotOriginTokenOwner();
    error RenfterNotApproved();
    error NotEnoughTokenBalance();

    error ZeroAddressPassed(bytes4 methodSig);
    error InvalidPriceValue(uint256 pricePerDay);
    error InvalidMaxDuration(uint256 maxDuration);
    error WrapperNotExisting(address wContract);
    error CollectionNotWrapped(address originContract);
    error SenderNotOriginTokenOwner(address wContract, uint256 tokenId);
    error TokenRentInProgress(address wContract, uint256 tokenId);

    error TokenNotOfferedForRenting(address wContract, uint256 tokenId);
    error InvalidRentalDuration(
        uint256 duration,
        uint256 minDuration,
        uint256 maxDuration
    );
    error NotEnoughFundsSendForRent(uint256 value);
    error RewardsCollectNotAllowed(
        address user,
        address wContract,
        uint256 tokenId
    );

    error RevertedReadingBalance(address contractAddress);
    error WalletExecuteCallReverted(string reason);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IRenfterEvents {
    event TokenFactoryChanged(address prevValue, address newValue);
    event WalletFactoryChanged(address prevValue, address newValue);
    event TokenWrapped(
        address originContract,
        address wContract,
        uint256 tokenId
    );
    event TokenUnwrapped(address wContract, uint256 tokenId);
    event TokenOfferedForRent(
        address contractAddress,
        uint256 id,
        uint256 pricePerDay,
        uint248 maxRentDuration,
        uint8 rewardRule
    );
    event RentalOfferRemoved(address contractAddress, uint256 tokenId);
    event TokenRented(
        address wContract,
        uint256 tokenId,
        uint256 duration,
        uint256 expirationTs
    );
    event TokenRentalExpired(address contractAddress, uint256 tokenId);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/// @title IRenfter
/// @dev Interface for `Renfter` contract
interface IRenfter {
    enum RewardRule {
        ALL_RENTEE,
        ALL_RENTER
    }

    /// @dev Structure representing rental conditions
    struct RentConditions {
        uint256 pricePerDay;
        uint248 maxRentDuration;
        RewardRule rewardRule;
    }

    function getOriginContract(address wContract)
        external
        view
        returns (address);

    function checkRentalExpired(address wContract, uint256 tokenId)
        external
        returns (bool);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}