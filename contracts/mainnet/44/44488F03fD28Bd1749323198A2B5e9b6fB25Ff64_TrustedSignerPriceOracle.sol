// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "Errors.sol";
import "IAssetRegistry.sol";
import "IUSDPriceOracle.sol";

contract TrustedSignerPriceOracle is IUSDPriceOracle {
    /// @notice prices posted should be scaled using `PRICE_DECIMALS` decimals
    uint8 public constant PRICE_DECIMALS = 6;

    /// @notice we throw an error if the price is older than `MAX_LAG` seconds
    uint256 public constant MAX_LAG = 3600;

    /// @notice this event is emitted when the price of `asset` is updated
    event PriceUpdated(address indexed asset, uint256 price, uint256 timestamp);

    struct SignedPrice {
        bytes message;
        bytes signature;
    }

    struct PriceData {
        uint64 timestamp;
        uint128 price;
    }

    /// @notice address of the trusted price signer
    /// This should be the Coinbase signing address in production deployments
    /// i.e. 0xfCEAdAFab14d46e20144F48824d0C09B1a03F2BC
    address public immutable trustedPriceSigner;

    /// @notice the asset registry used to find the mapping between
    /// a token address and its address
    IAssetRegistry public immutable assetRegistry;

    /// @dev asset to prices storage
    mapping(address => PriceData) internal prices;

    /// @notice if this is `true`, the oracle will revert if the price is stale
    bool public preventStalePrice;

    constructor(
        address _assetRegistry,
        address _priceSigner,
        bool _preventStalePrice
    ) {
        assetRegistry = IAssetRegistry(_assetRegistry);
        trustedPriceSigner = _priceSigner;
        preventStalePrice = _preventStalePrice;
    }

    /// @inheritdoc IUSDPriceOracle
    function getPriceUSD(address baseAsset) external view returns (uint256) {
        PriceData memory signedPrice = prices[baseAsset];
        require(signedPrice.timestamp > 0, Errors.ASSET_NOT_SUPPORTED);
        if (preventStalePrice) {
            require(signedPrice.timestamp + MAX_LAG >= block.timestamp, Errors.STALE_PRICE);
        }
        return signedPrice.price;
    }

    /// @notice returns the last update of `asset` or 0 if `asset` has never been updated
    function getLastUpdate(address asset) external view returns (uint256) {
        return prices[asset].timestamp;
    }

    /// @notice Updates prices using a list of signed prices received from a trusted signer (e.g. Coinbase)
    function postPrices(SignedPrice[] calldata signedPrices) external {
        for (uint256 i = 0; i < signedPrices.length; i++) {
            SignedPrice calldata signedPrice = signedPrices[i];
            _postPrice(signedPrice.message, signedPrice.signature);
        }
    }

    /// @notice Upates the price with a message containing the price information and its signature
    /// The message should have the following ABI-encoded format: (string kind, uint256 timestamp, string key, uint256 price)
    function postPrice(bytes memory message, bytes memory signature) external {
        _postPrice(message, signature);
    }

    function _postPrice(bytes memory message, bytes memory signature) internal {
        address signingAddress = verifyMessage(message, signature);
        require(signingAddress == trustedPriceSigner, Errors.INVALID_MESSAGE);

        (uint256 timestamp, string memory assetName, uint256 price) = decodeMessage(message);
        address assetAddress = assetRegistry.getAssetAddress(assetName);
        PriceData storage priceData = prices[assetAddress];
        require(
            timestamp > priceData.timestamp && timestamp + MAX_LAG >= block.timestamp,
            Errors.STALE_PRICE
        );

        uint256 scaledPrice = price * 10**(18 - PRICE_DECIMALS);

        priceData.timestamp = uint64(timestamp);
        priceData.price = uint128(scaledPrice);

        emit PriceUpdated(assetAddress, scaledPrice, timestamp);
    }

    function decodeMessage(bytes memory message)
        internal
        pure
        returns (
            uint256,
            string memory,
            uint256
        )
    {
        (string memory kind, uint256 timestamp, string memory key, uint256 value) = abi.decode(
            message,
            (string, uint256, string, uint256)
        );
        require(
            keccak256(abi.encodePacked(kind)) == keccak256(abi.encodePacked("prices")),
            Errors.INVALID_MESSAGE
        );
        return (timestamp, key, value);
    }

    function verifyMessage(bytes memory message, bytes memory signature)
        internal
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = abi.decode(signature, (bytes32, bytes32, uint8));
        bytes32 signedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(message))
        );
        return ecrecover(signedHash, v, r, s);
    }
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

/// @notice Defines different errors emitted by Gyroscope contracts
library Errors {
    string public constant TOKEN_AND_AMOUNTS_LENGTH_DIFFER = "1";
    string public constant TOO_MUCH_SLIPPAGE = "2";
    string public constant EXCHANGER_NOT_FOUND = "3";
    string public constant POOL_IDS_NOT_FOUND = "4";
    string public constant WOULD_UNBALANCE_GYROSCOPE = "5";
    string public constant VAULT_ALREADY_EXISTS = "6";
    string public constant VAULT_NOT_FOUND = "7";

    string public constant X_OUT_OF_BOUNDS = "20";
    string public constant Y_OUT_OF_BOUNDS = "21";
    string public constant PRODUCT_OUT_OF_BOUNDS = "22";
    string public constant INVALID_EXPONENT = "23";
    string public constant OUT_OF_BOUNDS = "24";
    string public constant ZERO_DIVISION = "25";
    string public constant ADD_OVERFLOW = "26";
    string public constant SUB_OVERFLOW = "27";
    string public constant MUL_OVERFLOW = "28";
    string public constant DIV_INTERNAL = "29";

    // User errors
    string public constant NOT_AUTHORIZED = "30";
    string public constant INVALID_ARGUMENT = "31";
    string public constant KEY_NOT_FOUND = "32";
    string public constant KEY_FROZEN = "33";
    string public constant INSUFFICIENT_BALANCE = "34";
    string public constant INVALID_ASSET = "35";

    // Oracle related errors
    string public constant ASSET_NOT_SUPPORTED = "40";
    string public constant STALE_PRICE = "41";
    string public constant NEGATIVE_PRICE = "42";
    string public constant INVALID_MESSAGE = "43";
    string public constant TOO_MUCH_VOLATILITY = "44";
    string public constant WETH_ADDRESS_NOT_FIRST = "44";
    string public constant ROOT_PRICE_NOT_GROUNDED = "45";
    string public constant NOT_ENOUGH_TWAPS = "46";
    string public constant ZERO_PRICE_TWAP = "47";
    string public constant INVALID_NUMBER_WEIGHTS = "48";

    //Vault safety check related errors
    string public constant A_VAULT_HAS_ALL_STABLECOINS_OFF_PEG = "51";
    string public constant NOT_SAFE_TO_MINT = "52";
    string public constant NOT_SAFE_TO_REDEEM = "53";
    string public constant AMOUNT_AND_PRICE_LENGTH_DIFFER = "54";
    string public constant TOKEN_PRICES_TOO_SMALL = "55";
    string public constant TRYING_TO_REDEEM_MORE_THAN_VAULT_CONTAINS = "56";
    string public constant CALLER_NOT_MOTHERBOARD = "57";
    string public constant CALLER_NOT_RESERVE_MANAGER = "58";

    string public constant VAULT_FLOW_TOO_HIGH = "60";
    string public constant OPERATION_SUCCEEDS_BUT_SAFETY_MODE_ACTIVATED = "61";
    string public constant ORACLE_GUARDIAN_TIME_LIMIT = "62";
    string public constant NOT_ENOUGH_FLOW_DATA = "63";
    string public constant SUPPLY_CAP_EXCEEDED = "64";
    string public constant SAFETY_MODE_ACTIVATED = "65";

    // misc errors
    string public constant REDEEM_AMOUNT_BUG = "100";
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

interface IAssetRegistry {
    /// @notice Emitted when an asset address is updated
    /// If `previousAddress` was 0, it means that the asset was added to the registry
    event AssetAddressUpdated(
        string indexed assetName,
        address indexed previousAddress,
        address indexed newAddress
    );

    /// @notice Emitted when an asset is set as being stable
    event StableAssetAdded(address indexed asset);

    /// @notice Emitted when an asset is unset as being stable
    event StableAssetRemoved(address indexed asset);

    /// @notice Returns the address associated with the given asset name
    /// e.g. "DAI" -> 0x6B175474E89094C44Da98b954EedeAC495271d0F
    function getAssetAddress(string calldata assetName) external view returns (address);

    /// @notice Returns a list of names for the registered assets
    /// The asset are encoded as bytes32 (big endian) rather than string
    function getRegisteredAssetNames() external view returns (bytes32[] memory);

    /// @notice Returns a list of addresses for the registered assets
    function getRegisteredAssetAddresses() external view returns (address[] memory);

    /// @notice Returns a list of addresses contaning the stable assets
    function getStableAssets() external view returns (address[] memory);

    /// @return true if the asset name is registered
    function isAssetNameRegistered(string calldata assetName) external view returns (bool);

    /// @return true if the asset address is registered
    function isAssetAddressRegistered(address assetAddress) external view returns (bool);

    /// @return true if the asset name is stable
    function isAssetStable(address assetAddress) external view returns (bool);

    /// @notice Adds a stable asset to the registry
    /// The asset must already be registered in the registry
    function addStableAsset(address assetAddress) external;

    /// @notice Removes a stable asset to the registry
    /// The asset must already be a stable asset
    function removeStableAsset(address asset) external;

    /// @notice Set the `assetName` to the given `assetAddress`
    function setAssetAddress(string memory assetName, address assetAddress) external;

    /// @notice Removes `assetName` from the registry
    function removeAsset(string memory assetName) external;
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

interface IUSDPriceOracle {
    /// @notice Quotes the USD price of `tokenAddress`
    /// The quoted price is always scaled with 18 decimals regardless of the
    /// source used for the oracle.
    /// @param tokenAddress the asset of which the price is to be quoted
    /// @return the USD price of the asset
    function getPriceUSD(address tokenAddress) external view returns (uint256);
}