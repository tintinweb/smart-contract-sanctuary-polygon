// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";

import "./interfaces/ILand.sol";
import "./interfaces/ILandMinter.sol";
import "./interfaces/ILandAcquirableWithToken.sol";

/**
 * @title LandMinter Contract
 */
contract LandMinter is
    Initializable,
    ILandMinter,
    ILandAcquirableWithToken,
    OwnableUpgradeable
{
    // ---------------
    // State variables
    // ---------------

    uint256 public constant FEE_PRECISION = 1000;
    uint256 public constant PRICE_PRECISION = 100;

    bool public mintingEnabled;
    bool public onlyWhitelisted;

    ILand public land;

    uint256 public fee;
    uint256 public renameFee;
    uint256 public premiumBasePrice;
    uint256 public regularBasePrice; // non-premium

    address public spaceWallet;
    address public feeRecipient;

    mapping(uint256 => bool) public renamed;
    mapping(uint256 => Size) public idToSize;
    mapping(address => bool) public whitelisted;
    mapping(Size => uint256[]) public availableNonPremiumIds;

    mapping(Size => uint256) private _landSizes; // size to number of parcels that the size consists of (S => 1, M => 4 and so on)
    mapping(Size => uint256) private _sizePremiums;
    mapping(uint256 => bool) private _mintablePremiumIds;

    /// @dev the list of all configured tokens for the token discount mechanic
    IERC721[] private _configuredTokens;
    /// @dev a shorthand way to check if a token is configured
    mapping(IERC721 => bool) _tokenConfigured;
    /// @dev a mapping per configured token to indicate whether a specific token of that token contract has been used as
    /// a discount token already or not. It goes as follows: `_tokenIdsUsed[address][version][tokenId]`
    mapping(IERC721 => mapping(uint256 => mapping(uint256 => bool))) _tokenIdsUsed;
    /// @dev a mapping per configured token to its tokenIdsUsed version, needed for resets.
    mapping(IERC721 => uint256) _tokensUsedVersion;
    /// @dev a mapping per configured token to its used number.
    mapping(IERC721 => uint256) _tokensUsedNumber;
    /// @dev the configurations (price, active state) of a token discount
    mapping(IERC721 => TokenDiscountConfig) _tokenConfigurations;

    // ---------
    // Modifiers
    // ---------

    modifier checkSize(Size _size) {
        require(_size <= Size.D, "invalid size");

        _;
    }

    modifier checkAddress(address _address) {
        require(_address != address(0), "address 0");

        _;
    }

    modifier checkWhitelistStatus(address _sender) {
        if (onlyWhitelisted) require(whitelisted[_sender], "unauthorized");

        _;
    }

    // ---------------------
    // Initializing function
    // ---------------------

    /**
     * @dev Initializes the contract, can only be called once
     *
     * @param _landToken        Smart contract address of the Land NFT
     * @param _feeRecipient     Wallet address of the feeRecipient
     * @param _fee              Minting fee
     * @param _renameFee        Rename fee
     * @param _basePremiumPrice Base price for a premium Land NFT
     * @param _baseRegularPrice Base price for a regular Land NFT
     * @param landSizes_        Number of parcels a Land of given size is composed of, have to be in order [S, M, L, Z, D]
     * @param sizePremiums_     Premiums that increase the price, dependent on size, have to be in order [S, M, L, Z, D]
     */
    function initialize(
        address _landToken,
        address _feeRecipient,
        uint256 _fee,
        uint256 _renameFee,
        uint256 _basePremiumPrice,
        uint256 _baseRegularPrice,
        uint256[] memory landSizes_,
        uint256[] memory sizePremiums_
    ) external initializer {
        require(_fee > 0, "invalid fee");
        require(_basePremiumPrice > 0, "invalid premium price");
        require(_baseRegularPrice > 0, "invalid regular price");
        require(_landToken != address(0), "invalid fee recipient");
        require(_feeRecipient != address(0), "invalid fee recipient");
        require(
            sizePremiums_.length == landSizes_.length,
            "array lengths mismatch"
        );

        __Ownable_init();

        land = ILand(_landToken);
        feeRecipient = _feeRecipient;

        fee = _fee;
        renameFee = _renameFee;
        premiumBasePrice = _basePremiumPrice;
        regularBasePrice = _baseRegularPrice;

        mintingEnabled = true;

        for (uint256 i = 0; i < sizePremiums_.length; i++) {
            _landSizes[Size(i)] = landSizes_[i];
            _sizePremiums[Size(i)] = sizePremiums_[i];
        }
    }

    // ----------------
    // Public functions
    // ----------------

    /**
     * @notice Mints a premium Land NFT to the user.
     *
     * @param _tokenId  Token id
     */
    function mintPremium(uint256 _tokenId)
        external
        payable
        checkWhitelistStatus(msg.sender)
    {
        require(mintingEnabled, "minting is disabled");
        require(_mintablePremiumIds[_tokenId], "token id is unavailable");

        _transferFee(calculatePrice(idToSize[_tokenId], premiumBasePrice));

        _mintablePremiumIds[_tokenId] = false;

        land.mint(msg.sender, _tokenId);
    }

    /**
     * @notice Mints a non-premium Land NFT to the user.
     *
     * @param _size Land size => enumerated S, M or LH, L
     */

    function mintNonPremium(Size _size)
        external
        payable
        checkSize(_size)
        checkWhitelistStatus(msg.sender)
    {
        require(mintingEnabled, "minting is disabled");
        require(availableNonPremiumIds[_size].length > 0, "no tokens left");

        uint256 tokenId = _getRandomId(_size, msg.sender);

        if (land.exists(tokenId)) revert("token already exists");

        _transferFee(calculatePrice(_size, regularBasePrice));

        land.mint(msg.sender, tokenId);
    }

    /**
     * @dev Emits an event which is used to rename the Land token, free only the first time
     *
     * @param _tokenId   Id of the token whose name needs to be changed
     * @param _tokenName The name to which the token will be renamed
     */
    function renameLand(uint256 _tokenId, string memory _tokenName)
        external
        payable
    {
        require(land.exists(_tokenId), "query for nonexistent token");

        if (renamed[_tokenId]) {
            require(msg.value >= renameFee, "value sent is less than the fee");

            _transferFee(msg.value);
        }

        renamed[_tokenId] = true;

        emit TokenRenamed(msg.sender, _tokenId, _tokenName);
    }

    /**
     * @dev Calculates the price based on `_basePrice`, parcel `_size`, price premium and size multiplier
     *
     * @param _size      Size of the Land token to be minted
     * @param _basePrice Can be either `premiumBasePrice` or `regularBasePrice`
     */
    function calculatePrice(Size _size, uint256 _basePrice)
        public
        view
        returns (uint256 price)
    {
        uint256 premium = _sizePremiums[_size];
        uint256 sizeMultiplier = _landSizes[_size];

        price = ((_basePrice * premium) / PRICE_PRECISION) * sizeMultiplier;
    }

    /**
     * @dev Checks availability of regular / non-premium Land
     *
     * @param _size Size of Land for which to check availabilty
     */
    function checkRegularLandAvailability(Size _size)
        public
        view
        returns (uint256[] memory)
    {
        return availableNonPremiumIds[_size];
    }

    // ---------------
    // Owner functions
    // ---------------

    /**
     * @dev Airdrop function callable by LAND_MANAGERs
     *
     * @param _accounts Array of wallet addresses to which the tokens with _ids will be minted to
     * @param _ids      Array of tokenIds which will be minted
     */
    function airdrop(address[] memory _accounts, uint256[] memory _ids)
        external
        onlyOwner
    {
        require(_accounts.length == _ids.length, "array lengths mismatch");

        for (uint256 i = 0; i < _accounts.length; i++) {
            if (!_mintablePremiumIds[_ids[i]]) continue;

            _mintablePremiumIds[_ids[i]] = false;

            land.mint(_accounts[i], _ids[i]);
        }
    }

    /**
     * @dev Sets the fee amount
     *
     * @param _fee New fee amount
     */
    function setFee(uint256 _fee) external onlyOwner {
        require(_fee >= 0, "invalid fee amount");

        fee = _fee;

        emit SetFee(_fee);
    }

    /**
     * @dev Sets the rename fee amount
     *
     * @param _renameFee New rename fee amount
     */
    function setRenameFee(uint256 _renameFee) external onlyOwner {
        require(_renameFee >= 0, "invalid rename fee amount");

        renameFee = _renameFee;

        emit SetRenameFee(_renameFee);
    }

    /**
     * @dev Sets the address of the feeRecipient (the address that receives fees)
     *
     * @param _feeRecipient New fee recipient
     */
    function setFeeRecipient(address _feeRecipient)
        external
        onlyOwner
        checkAddress(_feeRecipient)
    {
        feeRecipient = _feeRecipient;

        emit SetFeeRecipient(_feeRecipient);
    }

    /**
     * @dev Sets the address for the Space wallet
     *
     * @param _spaceWallet Address of the Space wallet
     */
    function setSpaceAddress(address _spaceWallet)
        external
        onlyOwner
        checkAddress(_spaceWallet)
    {
        spaceWallet = _spaceWallet;
    }

    /**
     * @notice Setter function for the base price of the premium parcel
     *
     * @param _premiumBasePrice Base price for the premium parcel
     */
    function setPremiumBasePrice(uint256 _premiumBasePrice) external onlyOwner {
        premiumBasePrice = _premiumBasePrice;

        emit PremiumBasePriceChanged(_premiumBasePrice);
    }

    /**
     * @notice Setter function for the base price of the regular parcel
     *
     * @param _regularBasePrice Base price for the regular/non-premium parcel
     */
    function setRegularBasePrice(uint256 _regularBasePrice) external onlyOwner {
        regularBasePrice = _regularBasePrice;

        emit RegularBasePriceChanged(_regularBasePrice);
    }

    /**
     * @notice Setter function for the `_sizePremiums` mapping, relevant to the `calculatePrice` function
     *
     * @param _size    Size which needs its premium changed
     * @param _premium New price premium of the parcels with `_size`
     */
    function setSizePremium(Size _size, uint256 _premium)
        external
        onlyOwner
        checkSize(_size)
    {
        require(_size <= Size.D, "invalid size");

        _sizePremiums[_size] = _premium;

        emit SizePremiumChanged(_size, _premium);
    }

    /**
     * @notice Setter function for the `_landSizes` mapping, relevant to the `calculatePrice` function
     *
     * @param _size                      Size which is going to be changed
     * @param _numberOfParcelsConsisting Number of parcels that Land of `_size` consists of
     */
    function setLandSize(Size _size, uint256 _numberOfParcelsConsisting)
        external
        onlyOwner
        checkSize(_size)
    {
        _landSizes[_size] = _numberOfParcelsConsisting;

        emit LandSizeChanged(_size, _numberOfParcelsConsisting);
    }

    /**
     * @dev Sets the whitelist status of _address
     *
     * @param _targets  Array of addresses which status will be updated
     * @param _statuses Array of boolean variables indicating status for each address
     */
    function setWhitelistStatus(
        address[] memory _targets,
        bool[] memory _statuses
    ) external onlyOwner {
        require(_targets.length == _statuses.length, "arrays length mismatch");

        for (uint256 i = 0; i < _targets.length; i++) {
            whitelisted[_targets[i]] = _statuses[i];
        }
    }

    /**
     * @dev Toggles `mintingEnabled` boolean
     *
     * @notice If mintingEnabled is false, the minting functions are disabled (vice versa)
     */
    function toggleMinting() external onlyOwner {
        mintingEnabled = !mintingEnabled;

        emit ToggleMinting(mintingEnabled);
    }

    /**
     * @dev Toggles `onlyWhitelisted` boolean which controls if only the whitelisted addresses are able to mint
     */
    function toggleOnlyWhitelisted() external onlyOwner {
        onlyWhitelisted = !onlyWhitelisted;

        emit ToggleOnlyWhitelisted(onlyWhitelisted);
    }

    /**
     * @notice The `_ids` that are added cannot already be mitned / cannot already exist
     *
     * @dev Adds more tokenIds to the `_mintablePremiumIds` mapping and maps the id to size in the `idToSize` mapping
     *
     * @param _size Parcel size to which the `_ids` belong
     * @param _ids  TokenIds that will become available for minting once this function is called
     */
    function addPremiumIds(Size _size, uint256[] memory _ids)
        external
        onlyOwner
        checkSize(_size)
    {
        for (uint256 i = 0; i < _ids.length; i++) {
            if (land.exists(_ids[i])) continue;

            _mintablePremiumIds[_ids[i]] = true;
            idToSize[_ids[i]] = _size;
        }
    }

    /**
     * @notice The `_ids` that are added cannot already be mint-ed / cannot already exist
     *
     * @dev Adds more tokenIds to the `availableNonPremiumIds` mapping
     *
     * @param _size Parcel size to which the `_ids` belong
     * @param _ids  TokenIds that will become available for minting once this function is called
     */
    function addNonPremiumIds(Size _size, uint256[] memory _ids)
        external
        onlyOwner
        checkSize(_size)
    {
        for (uint256 i = 0; i < _ids.length; i++) {
            if (land.exists(_ids[i])) continue;

            availableNonPremiumIds[_size].push(_ids[i]);
        }
    }

    /**
     * @dev Transfers the share amount of tokens to each of the shareholders
     *
     * @param _amount Amount of tokens to be withdrawn (can't be more than the contract's balance)
     */
    function withdraw(uint256 _amount) external onlyOwner {
        require(address(this).balance >= _amount, "invalid amount");

        uint256 share = _amount / 2;

        payable(spaceWallet).transfer(share);
        payable(feeRecipient).transfer(share);

        emit Withdraw([spaceWallet, feeRecipient], _amount);
    }

    // -----------------
    // Private functions
    // -----------------

    /**
     * @notice Calculates fee based on `_amount` and `fee` and transfers it to
     *         `feeRecipient`.
     */
    function _transferFee(uint256 _amount) private {
        require(msg.value >= _amount, "underpriced");

        uint256 feeAmount = (_amount * fee) / FEE_PRECISION;
        uint256 extraAmount = msg.value - _amount;

        payable(feeRecipient).transfer(feeAmount + extraAmount);
    }

    /**
     * @notice Gets a random id from `availableNonPremiumIds` mapping based on the
     *        `_size` and `randIndex` generated from address `_sender` and `block.timestamp`
     */
    function _getRandomId(Size _size, address _sender)
        private
        returns (uint256)
    {
        uint256 randIndex = uint256(
            keccak256(abi.encodePacked(block.timestamp, _sender))
        ) % availableNonPremiumIds[_size].length;

        uint256 tokenId = availableNonPremiumIds[_size][randIndex];

        availableNonPremiumIds[_size][randIndex] = availableNonPremiumIds[
            _size
        ][availableNonPremiumIds[_size].length - 1];
        availableNonPremiumIds[_size].pop();

        return tokenId;
    }

    // ---------------
    // Token Whitelist
    // ---------------

    // TODO Make it size dependent
    /// @inheritdoc ILandAcquirableWithToken
    function acquireWithToken(
        IERC721 token,
        uint256 _ownedTokenId,
        uint256 _tokenIdToMint
    ) external payable override {
        require(mintingEnabled, "minting is disabled");
        require(_mintablePremiumIds[_tokenIdToMint], "token id is unavailable");

        _revertIfTokenNotActive(token);
        uint256 price_ = _getTokenDiscountInfo(token).price;

        _checkTokenElegibility(msg.sender, token, _ownedTokenId);
        _setTokensUsedForDiscount(token, _ownedTokenId);

        /// @dev If `price_` is 0 that means that `token` owners can mint only for gas fee
        if (price_ == 0) {
            _mintablePremiumIds[_tokenIdToMint] = false;

            land.mint(msg.sender, _tokenIdToMint);
        } else {
            _transferFee(calculatePrice(idToSize[_tokenIdToMint], price_));

            _mintablePremiumIds[_tokenIdToMint] = false;

            land.mint(msg.sender, _tokenIdToMint);
        }
    }

    /// @inheritdoc ILandAcquirableWithToken
    function tokenDiscounts()
        external
        view
        override
        returns (TokenDiscountOutput[] memory)
    {
        uint256 len = _configuredTokens.length;
        IERC721[] memory localCopy = _configuredTokens;
        TokenDiscountOutput[] memory td = new TokenDiscountOutput[](len);
        for (uint256 i = 0; i < len; i++) {
            address addr = address(localCopy[i]);
            td[i] = TokenDiscountOutput(
                IERC721(addr),
                _getRemoteNameOrEmpty(address(addr)),
                _getRemoteSymbolOrEmpty(address(addr)),
                _tokensUsedNumber[localCopy[i]],
                _tokenConfigurations[localCopy[i]]
            );
        }
        return td;
    }

    /// @inheritdoc ILandAcquirableWithToken
    function addTokenDiscount(
        IERC721 tokenAddress,
        TokenDiscountConfig memory config
    ) public onlyOwner {
        _addTokenDiscount(tokenAddress, config);
    }

    /// @inheritdoc ILandAcquirableWithToken
    function setTokenDiscountActive(IERC721 tokenAddress, bool active)
        external
        onlyOwner
    {
        _revertIfTokenNotConfigured(tokenAddress);
        if (_tokenConfigurations[tokenAddress].active != active) {
            _tokenConfigurations[tokenAddress].active = active;
            emit TokenDiscountUpdated(
                tokenAddress,
                _tokenConfigurations[tokenAddress]
            );
        }
    }

    function _getRemoteNameOrEmpty(address remote)
        internal
        view
        returns (string memory)
    {
        try IERC721MetadataUpgradeable(remote).name() returns (
            string memory name_
        ) {
            return name_;
        } catch {
            return "";
        }
    }

    function _getRemoteSymbolOrEmpty(address remote)
        internal
        view
        returns (string memory)
    {
        try IERC721MetadataUpgradeable(remote).symbol() returns (
            string memory symbol_
        ) {
            return symbol_;
        } catch {
            return "";
        }
    }

    /// @inheritdoc ILandAcquirableWithToken
    function tokensUsedForDiscount(IERC721 tokenAddress, uint256 tokenId)
        external
        view
        virtual
        override
        returns (bool used)
    {
        _revertIfTokenNotConfigured(tokenAddress);

        return
            used = _tokenIdsUsed[tokenAddress][
                _tokensUsedVersion[tokenAddress]
            ][tokenId];
    }

    /// @inheritdoc ILandAcquirableWithToken
    function removeTokenDiscount(IERC721 tokenAddress) external onlyOwner {
        _revertIfTokenNotConfigured(tokenAddress);
        uint256 length = _configuredTokens.length;
        for (uint256 i = 0; i < length; i++) {
            if (_configuredTokens[i] == tokenAddress) {
                _tokenConfigured[tokenAddress] = false;
                _popTokenConfigAt(i);
                emit TokenDiscountRemoved(tokenAddress);
                return;
            }
        }
        revert TokenNotConfigured(tokenAddress);
    }

    /// @inheritdoc ILandAcquirableWithToken
    function tokenDiscountInfo(IERC721 tokenAddress)
        external
        view
        returns (TokenDiscountOutput memory)
    {
        _revertIfTokenNotConfigured(tokenAddress);
        return
            TokenDiscountOutput(
                tokenAddress,
                _getRemoteNameOrEmpty(address(tokenAddress)),
                _getRemoteSymbolOrEmpty(address(tokenAddress)),
                _tokensUsedNumber[tokenAddress],
                _getTokenDiscountInfo(tokenAddress)
            );
    }

    function _getTokenDiscountInfo(IERC721 tokenAddress)
        internal
        view
        returns (TokenDiscountConfig memory)
    {
        return _tokenConfigurations[tokenAddress];
    }

    /// @inheritdoc ILandAcquirableWithToken
    function updateTokenDiscount(
        IERC721 tokenAddress,
        TokenDiscountConfig memory config
    ) external override onlyOwner {
        _revertIfTokenNotConfigured(tokenAddress);
        _tokenConfigurations[tokenAddress] = config;
        emit TokenDiscountUpdated(tokenAddress, config);
    }

    /// @inheritdoc ILandAcquirableWithToken
    function resetTokenDiscountUsed(IERC721 tokenAddress)
        external
        override
        onlyOwner
    {
        _revertIfTokenNotConfigured(tokenAddress);
        _tokensUsedVersion[tokenAddress]++;
        _tokensUsedNumber[tokenAddress] = 0;
        emit TokenDiscountReset(tokenAddress);
    }

    function _checkTokenElegibility(
        address account,
        IERC721 tokenAddress,
        uint256 tokenId
    ) internal view {
        if (
            _tokensUsedNumber[tokenAddress] + 1 >
            _tokenConfigurations[tokenAddress].supply
        )
            revert TokenSupplyExceeded(
                tokenAddress,
                _tokenConfigurations[tokenAddress].supply
            );
        // try catch for reverts in ownerOf
        try tokenAddress.ownerOf(tokenId) returns (address owner) {
            if (owner != account) revert TokenNotOwned(tokenAddress, tokenId);
        } catch {
            revert TokenNotOwned(tokenAddress, tokenId);
        }
        if (
            _tokenIdsUsed[tokenAddress][_tokensUsedVersion[tokenAddress]][
                tokenId
            ]
        ) revert TokenAlreadyUsed(tokenAddress, tokenId);
    }

    function _popTokenConfigAt(uint256 index) private {
        uint256 length = _configuredTokens.length;
        if (index >= length) return;
        for (uint256 i = index; i < length - 1; i++) {
            _configuredTokens[i] = _configuredTokens[i + 1];
        }
        _configuredTokens.pop();
    }

    // no checks
    function _setTokensUsedForDiscount(IERC721 token, uint256 tokenId)
        internal
    {
        _tokenIdsUsed[token][_tokensUsedVersion[token]][tokenId] = true;
        emit TokenUsedForDiscount(msg.sender, token, tokenId);

        _tokensUsedNumber[token]++;
    }

    function _addTokenDiscount(
        IERC721 tokenAddress,
        TokenDiscountConfig memory config
    ) internal {
        if (address(tokenAddress) == address(0)) revert NullAddress();
        if (_tokenConfigured[tokenAddress])
            revert TokenAlreadyConfigured(tokenAddress);
        _tokenConfigured[tokenAddress] = true;
        _tokensUsedVersion[tokenAddress]++;
        _tokenConfigurations[tokenAddress] = config;
        _configuredTokens.push(tokenAddress);
        emit TokenDiscountAdded(tokenAddress, config);
    }

    function _revertIfTokenNotConfigured(IERC721 tokenAddress) internal view {
        if (address(tokenAddress) == address(0)) revert NullAddress();
        if (!_tokenConfigured[tokenAddress])
            revert TokenNotConfigured(tokenAddress);
    }

    function _revertIfTokenNotActive(IERC721 tokenAddress) internal view {
        if (!_tokenConfigured[tokenAddress])
            revert TokenNotConfigured(tokenAddress);
        if (!_tokenConfigurations[tokenAddress].active)
            revert TokenNotActive(tokenAddress);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ILand {
    event SetBaseUri(string baseURI);
    event SetUnrevealedUri(string unrevealedURI);
    event ToggleRevealed(bool revealed);

    function burn(uint256 _id) external;

    function exists(uint256 _tokenId) external view returns (bool);

    function mint(address _to, uint256 _id) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ILandMinter {
    /**
     * S  1x1
     * M  2x2
     * L  4x2, 2x4
     * Z  5x5
     * D  25x25
     */
    enum Size {
        S,
        M,
        L,
        Z,
        D
    }

    event SetFee(uint256 fee);
    event SetRenameFee(uint256 renameFee);
    event SetFeeRecipient(address feeRecipient);
    event ToggleRevealed(bool revealed);
    event ToggleMinting(bool mintingEnabled);
    event ToggleOnlyWhitelisted(bool status);
    event Withdraw(address[2] shareholders, uint256 amount);
    event LandSizeChanged(Size size, uint256 value);
    event SizePremiumChanged(Size size, uint256 value);
    event RegularBasePriceChanged(uint256 baseRegularPrice);
    event PremiumBasePriceChanged(uint256 basePremiumPrice);
    event TokenRenamed(
        address indexed owner,
        uint256 tokenId,
        string tokenName
    );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../def/TokenDiscount.sol";

/// @title ILandAcquirableWithToken
/// @author NotAMeme aka nxlogixnick
/// @notice This interface serves for the extended minting functionality of the Land Artist Contracts.
/// The general functionality is that special prices can be configured for users to mint if they hold other
/// NFTs. Each NFT can only be used once to receive this discount, unless specifically reset.
interface ILandAcquirableWithToken {
    error NullAddress();
    error TokenNotOwned(IERC721 token, uint256 tokenIds);
    error TokenAlreadyUsed(IERC721 token, uint256 tokenId);
    error TokenNotConfigured(IERC721 token);
    error TokenNotActive(IERC721 token);
    error TokenAlreadyConfigured(IERC721 token);
    error TokenSupplyExceeded(IERC721 token, uint256 supplyCap);

    /// @notice Triggers when a token discount is added.
    /// @param tokenAddress the addres of the added NFT contract for discounts
    /// @param config a tuple [uint256 price, uint256 limit, bool active] that represents the configuration for
    /// the discount
    event TokenDiscountAdded(
        IERC721 indexed tokenAddress,
        TokenDiscountConfig config
    );
    /// @notice Triggers when a token discount is updated.
    /// @param tokenAddress the addres of the added NFT contract for discounts
    /// @param config a tuple [uint256 price, uint256 limit, bool active] that represents the new configuration for
    /// the discount
    event TokenDiscountUpdated(
        IERC721 indexed tokenAddress,
        TokenDiscountConfig config
    );
    /// @notice Triggers when a token discount is removed.
    /// @param tokenAddress the addres of the NFT contract
    event TokenDiscountRemoved(IERC721 indexed tokenAddress);
    /// @notice Triggers when a token discount is reset - meaning all token usage data is reset and all tokens
    /// are marked as unused again.
    /// @param tokenAddress the addres of the NFT contract
    event TokenDiscountReset(IERC721 indexed tokenAddress);
    /// @notice Triggers when a token discount is used for a discount and then marked as used
    /// @param sender the user who used the token
    /// @param tokenAddress the addres of the NFT contract
    /// @param tokenId the id of the NFT used for the discount
    event TokenUsedForDiscount(
        address indexed sender,
        IERC721 indexed tokenAddress,
        uint256 indexed tokenId
    );

    /// @notice Adds an NFT contract and thus all of it's tokens to the discount list.
    /// Emits a {TokenDiscountAdded} event and fails if `tokenAddress` is the zero address
    /// or is already configured.
    /// @param tokenAddress the address of the NFT contract
    /// @param config the initial configuration as [uint256 price, uint256 limit, bool active]
    function addTokenDiscount(
        IERC721 tokenAddress,
        TokenDiscountConfig memory config
    ) external;

    /// @notice Removes an NFT contract from the discount list.
    /// Emits a {TokenDiscountRemoved} event and fails if `tokenAddress` is the zero address
    /// or is not already configured.
    /// @param tokenAddress the address of the NFT contract
    function removeTokenDiscount(IERC721 tokenAddress) external;

    /// @notice Updates an NFT contracts configuration of the discount.
    /// Emits a {TokenDiscountUpdated} event and fails if `tokenAddress` is the zero address
    /// or is not already configured.
    /// @param tokenAddress the address of the NFT contract
    /// @param config the new configuration as [uint256 price, uint256 limit, bool active]
    function updateTokenDiscount(
        IERC721 tokenAddress,
        TokenDiscountConfig memory config
    ) external;

    /// @notice Resets the usage state of all NFTs of the contract at `tokenAddress`. This allows all token ids
    /// to be used again.
    /// Emits a {TokenDiscountReset} event and fails if `tokenAddress` is the zero address
    /// or is not already configured.
    /// @param tokenAddress the address of the NFT contract
    function resetTokenDiscountUsed(IERC721 tokenAddress) external;

    /// @notice Returns the current configuration of the token discount of `tokenAddress`
    /// @return config the configuration as [uint256 price, uint256 limit, bool active]
    function tokenDiscountInfo(IERC721 tokenAddress)
        external
        view
        returns (TokenDiscountOutput memory config);

    /// @notice Returns a list of all current tokens configured for discounts and their configurations.
    /// @return discounts the configuration as [IERC721 tokenAddress, [uint256 price, uint256 limit, bool active]]
    function tokenDiscounts()
        external
        view
        returns (TokenDiscountOutput[] memory discounts);

    /// @notice Acquires an NFT of this contract by proving ownership of the token in `tokenId` belonging to
    /// a contract `tokenAddress` that has a configured discount. This way cheaper prices can be achieved for LAND holders
    /// and potentially other partners. Emits {TokenUsedForDiscount} and requires the user to send the correct amount of
    /// eth as well as to own the tokens within `tokenIds` from `tokenAddress`, and for `tokenAddress` to be a configured token for discounts.
    /// @param tokenAddress the address of the contract which is the reference for `tokenIds`
    /// @param _ownedTokenId the token id which is to be used to get the discount
    /// @param _tokenIdToMint the token id which is going to be minted 
    function acquireWithToken(
        IERC721 tokenAddress,
        uint256 _ownedTokenId,
        uint256 _tokenIdToMint
    ) external payable;

    /// @notice Sets the active status of the token discount of `tokenAddress`.
    /// Fails if `tokenAddress` is the zero address or is not already configured.
    /// @param tokenAddress the configured token address
    /// @param active the new desired activity state
    function setTokenDiscountActive(IERC721 tokenAddress, bool active) external;

    /// @notice Returns whether the token `tokenId` of `tokenAddress` has already been used for a discount.
    /// Fails if `tokenAddress` is the zero address or is not already configured.
    /// @param tokenAddress the address of the token contract
    /// @param tokenId the id to check
    /// @return used if the token has already been used
    function tokensUsedForDiscount(IERC721 tokenAddress, uint256 tokenId)
        external
        view
        returns (bool used);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

struct TokenDiscountConfig {
    uint256 price;
    uint256 supply;
    bool active;
}
struct TokenDiscountInput {
    IERC721 tokenAddress;
    TokenDiscountConfig config;
}
struct TokenDiscountOutput {
    IERC721 tokenAddress;
    string name;
    string symbol;
    uint256 usedAmount;
    TokenDiscountConfig config;
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