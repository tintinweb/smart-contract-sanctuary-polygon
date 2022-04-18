//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "LibExchange.sol";

import "IHubLibraryEvents.sol";

contract Exchange is IHubLibraryEvents {
    function addXPerYPriceFeed(
        bytes32 _keyX,
        bytes32 _keyY,
        address _priceFeed
    ) external {
        LibExchange._addXPerYPriceFeed(_keyX, _keyY, _priceFeed);
    }

    function deriveXPerYPriceFeed(
        bytes32 _keyX,
        bytes32 _keyY,
        bytes32 _keyShared
    ) external {
        LibExchange._deriveXPerYPriceFeed(_keyX, _keyY, _keyShared);
    }

    function removeAddedXPerYPriceFeed(bytes32 _keyX, bytes32 _keyY) external {
        LibExchange._removeAddedXPerYPriceFeed(_keyX, _keyY);
    }

    function removeDerivedXPerYPriceFeed(bytes32 _keyX, bytes32 _keyY)
        external
    {
        LibExchange._removeDerivedXPerYPriceFeed(_keyX, _keyY);
    }

    function getAddedXPerYPriceFeed(bytes32 _keyX, bytes32 _keyY)
        external
        view
        returns (address)
    {
        LibExchange._requireAddedXPerYPriceFeedSupported(_keyX, _keyY);
        return
            LibExchange._storageExchange().xToYToXAddedPerYPriceFeed[_keyX][
                _keyY
            ];
    }

    function getAddedXPerYPriceFeedValue(bytes32 _keyX, bytes32 _keyY)
        external
        view
        returns (uint256)
    {
        LibExchange._requireAddedXPerYPriceFeedSupported(_keyX, _keyY);
        return LibExchange._getAddedXPerYInWei(_keyX, _keyY);
    }

    function getDerivedXPerYPriceFeedDetails(bytes32 _keyX, bytes32 _keyY)
        external
        view
        returns (LibExchange.DerivedPriceFeedDetails memory)
    {
        LibExchange._requireDerivedXPerYPriceFeedSupported(_keyX, _keyY);
        return
            LibExchange._storageExchange().xToYToXPerYDerivedPriceFeedDetails[
                _keyX
            ][_keyY];
    }

    function getDerivedXPerYPriceFeedValue(bytes32 _keyX, bytes32 _keyY)
        external
        view
        returns (uint256)
    {
        LibExchange._requireDerivedXPerYPriceFeedSupported(_keyX, _keyY);
        return LibExchange._getDerivedXPerYInWei(_keyX, _keyY);
    }

    function convertCurrency(
        bytes32 _keyX,
        bytes32 _keyY,
        uint256 _amountX
    ) external view returns (uint256) {
        return LibExchange._convertCurrency(_keyX, _keyY, _amountX);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "LibAccessControl.sol";
import "LibCurrencyRegistry.sol";

import "AggregatorV3Interface.sol";

library LibExchange {
    bytes32 constant STORAGE_POSITION_EXCHANGE = keccak256("ds.exchange");

    struct DerivedPriceFeedDetails {
        bytes32 keyShared;
        address numerator;
        address denominator;
        bool numeratorInverse;
        bool denominatorInverse;
    }

    struct StorageExchange {
        mapping(bytes32 => mapping(bytes32 => address)) xToYToXAddedPerYPriceFeed;
        mapping(bytes32 => mapping(bytes32 => bool)) xToYToXPerYInverse;
        mapping(bytes32 => mapping(bytes32 => DerivedPriceFeedDetails)) xToYToXPerYDerivedPriceFeedDetails;
        mapping(bytes32 => mapping(bytes32 => bool)) xToYToXPerYInverseDerived; // note: don't share with original inverse mapping as in future if added as base case, it would override derived case
        // xToYToBaseKeyCount useful for removal
        mapping(bytes32 => mapping(bytes32 => uint256)) xToYToBaseKeyCount; // example: X => Shared => count
    }

    function _storageExchange()
        internal
        pure
        returns (StorageExchange storage s)
    {
        bytes32 position = STORAGE_POSITION_EXCHANGE;
        assembly {
            s.slot := position
        }
    }

    function _requireAddedXPerYPriceFeedSupported(bytes32 _keyX, bytes32 _keyY)
        internal
        view
    {
        require(
            _storageExchange().xToYToXAddedPerYPriceFeed[_keyX][_keyY] !=
                address(0),
            "LibExchange: Price feed not supported"
        );
    }

    function _requireDerivedXPerYPriceFeedSupported(
        bytes32 _keyX,
        bytes32 _keyY
    ) internal view {
        require(
            _storageExchange()
            .xToYToXPerYDerivedPriceFeedDetails[_keyX][_keyY].numerator !=
                address(0),
            "LibExchange: Derived price feed not supported"
        ); // one check enough
    }

    event PriceFeedAdded(
        address indexed sender,
        bytes32 keyX,
        bytes32 keyY,
        address priceFeed
    );

    /**
     * NOTE: to add ETH/USD = $3,000 price feed (displayed on chainlink) --> read as USD per ETH (X per Y)
     * do: x = USD, y = ETH
     */
    function _addXPerYPriceFeed(
        bytes32 _keyX,
        bytes32 _keyY,
        address _priceFeed
    ) internal {
        LibAccessControl._requireOnlyRole(LibAccessControl.STRATEGIST_ROLE);
        LibCurrencyRegistry._requireCurrencySupported(_keyX);
        LibCurrencyRegistry._requireCurrencySupported(_keyY);

        require(
            _priceFeed != address(0),
            "LibExchange: Zero price feed address"
        );
        StorageExchange storage s1 = _storageExchange();
        require(
            s1.xToYToXAddedPerYPriceFeed[_keyX][_keyY] == address(0),
            "LibExchange: Price feed already supported"
        );
        s1.xToYToXAddedPerYPriceFeed[_keyX][_keyY] = _priceFeed;
        s1.xToYToXAddedPerYPriceFeed[_keyY][_keyX] = _priceFeed; // reverse pairing
        s1.xToYToXPerYInverse[_keyY][_keyX] = true;

        emit PriceFeedAdded(msg.sender, _keyX, _keyY, _priceFeed);
    }

    event PriceFeedDerived(
        address indexed sender,
        bytes32 keyX,
        bytes32 keyY,
        bytes32 keyShared
    );

    /**
     * NOTE: to derive ETH/EUR = €2,823 (chainlink equivalent) --> read as EUR per ETH (X per Y), from
     * ETH/USD = $3,000 price feed (displayed on chainlink) --> read as USD per ETH
     * EUR/USD = $1.14 price feed (displayed on chainlink) --> read as USD per EUR
     * do: x = EUR, y = ETH, shared = USD
     */
    function _deriveXPerYPriceFeed(
        bytes32 _keyX,
        bytes32 _keyY,
        bytes32 _keyShared
    ) internal {
        LibAccessControl._requireOnlyRole(LibAccessControl.STRATEGIST_ROLE);
        require(
            _keyX != _keyY,
            "LibExchange: Underlying currency key cannot be identical"
        );
        _requireAddedXPerYPriceFeedSupported(_keyX, _keyShared);
        _requireAddedXPerYPriceFeedSupported(_keyY, _keyShared);

        StorageExchange storage s1 = _storageExchange();
        require(
            s1.xToYToXPerYDerivedPriceFeedDetails[_keyX][_keyY].numerator ==
                address(0),
            "LibExchange: Derived price feed already supported"
        );

        s1.xToYToXPerYDerivedPriceFeedDetails[_keyX][_keyY].numerator = s1
            .xToYToXAddedPerYPriceFeed[_keyX][_keyShared];
        s1.xToYToXPerYDerivedPriceFeedDetails[_keyX][_keyY].denominator = s1
            .xToYToXAddedPerYPriceFeed[_keyY][_keyShared];
        s1
        .xToYToXPerYDerivedPriceFeedDetails[_keyX][_keyY]
            .keyShared = _keyShared;

        // set inverse
        s1.xToYToXPerYDerivedPriceFeedDetails[_keyY][_keyX].numerator = s1
            .xToYToXAddedPerYPriceFeed[_keyX][_keyShared];
        s1.xToYToXPerYDerivedPriceFeedDetails[_keyY][_keyX].denominator = s1
            .xToYToXAddedPerYPriceFeed[_keyY][_keyShared];
        s1
        .xToYToXPerYDerivedPriceFeedDetails[_keyY][_keyX]
            .keyShared = _keyShared;

        s1.xToYToXPerYInverseDerived[_keyY][_keyX] = true;

        // set underlying inverse state
        if (s1.xToYToXPerYInverse[_keyX][_keyShared]) {
            s1
            .xToYToXPerYDerivedPriceFeedDetails[_keyX][_keyY]
                .numeratorInverse = true;
            s1
            .xToYToXPerYDerivedPriceFeedDetails[_keyY][_keyX]
                .numeratorInverse = true;
        }
        if (s1.xToYToXPerYInverse[_keyY][_keyShared]) {
            s1
            .xToYToXPerYDerivedPriceFeedDetails[_keyX][_keyY]
                .denominatorInverse = true;
            s1
            .xToYToXPerYDerivedPriceFeedDetails[_keyY][_keyX]
                .denominatorInverse = true;
        }

        s1.xToYToBaseKeyCount[_keyX][_keyShared] += 1;
        s1.xToYToBaseKeyCount[_keyY][_keyShared] += 1;

        emit PriceFeedDerived(msg.sender, _keyX, _keyY, _keyShared);
    }

    event AddedPriceFeedRemoved(address indexed sender, address priceFeed);

    function _removeAddedXPerYPriceFeed(bytes32 _keyX, bytes32 _keyY) internal {
        LibAccessControl._requireOnlyRole(LibAccessControl.STRATEGIST_ROLE);
        _requireAddedXPerYPriceFeedSupported(_keyX, _keyY);

        StorageExchange storage s1 = _storageExchange();

        require(
            s1.xToYToBaseKeyCount[_keyX][_keyY] == 0,
            "LibExchange: Base key being used"
        );

        address priceFeed = s1.xToYToXAddedPerYPriceFeed[_keyX][_keyY];

        delete s1.xToYToXAddedPerYPriceFeed[_keyX][_keyY];
        delete s1.xToYToXAddedPerYPriceFeed[_keyY][_keyX]; // reverse pairing
        delete s1.xToYToXPerYInverse[_keyX][_keyY];
        delete s1.xToYToXPerYInverse[_keyY][_keyX];

        // require(
        //     s1.xToYToXAddedPerYPriceFeed[_keyX][_keyY] == address(0),
        //     "price feed not removed 1"
        // );
        // require(
        //     s1.xToYToXAddedPerYPriceFeed[_keyY][_keyX] == address(0),
        //     "price feed not removed 2"
        // ); // reverse pairing
        // require(!s1.xToYToXPerYInverse[_keyY][_keyX], "reverse not removed");

        emit AddedPriceFeedRemoved(msg.sender, priceFeed);

        // TODO: remove price feed derived !!!! expand this fn or new fn ?????
    }

    event DerivedPriceFeedRemoved(
        address indexed sender,
        bytes32 keyX,
        bytes32 keyY
    );

    function _removeDerivedXPerYPriceFeed(bytes32 _keyX, bytes32 _keyY)
        internal
    {
        LibAccessControl._requireOnlyRole(LibAccessControl.STRATEGIST_ROLE);
        _requireDerivedXPerYPriceFeedSupported(_keyX, _keyY);

        StorageExchange storage s1 = _storageExchange();

        bytes32 baseKeyShared = s1
        .xToYToXPerYDerivedPriceFeedDetails[_keyX][_keyY].keyShared;

        s1.xToYToBaseKeyCount[_keyX][baseKeyShared] -= 1;
        s1.xToYToBaseKeyCount[_keyY][baseKeyShared] -= 1;

        delete s1.xToYToXPerYDerivedPriceFeedDetails[_keyX][_keyY];
        delete s1.xToYToXPerYDerivedPriceFeedDetails[_keyY][_keyX]; // reverse pairing
        delete s1.xToYToXPerYInverseDerived[_keyX][_keyY];
        delete s1.xToYToXPerYInverseDerived[_keyY][_keyX];

        emit DerivedPriceFeedRemoved(msg.sender, _keyX, _keyY);
    }

    // _amountX in wei /** _keyY == target to convert amount into */
    function _convertCurrency(
        bytes32 _keyX,
        bytes32 _keyY,
        uint256 _amountX
    ) internal view returns (uint256) {
        StorageExchange storage s1 = _storageExchange();

        uint256 xPerYWei;

        if (s1.xToYToXAddedPerYPriceFeed[_keyX][_keyY] != address(0)) {
            xPerYWei = _getAddedXPerYInWei(_keyX, _keyY);
        } else {
            xPerYWei = _getDerivedXPerYInWei(_keyX, _keyY);
        }

        if (
            s1.xToYToXPerYInverse[_keyX][_keyY] ||
            s1.xToYToXPerYInverseDerived[_keyX][_keyY]
        ) {
            return _convertInverse(xPerYWei, _amountX);
        } else {
            return _convertDirect(xPerYWei, _amountX);
        }
    }

    function _convertDirect(uint256 _xPerYWei, uint256 _amountX)
        internal
        pure
        returns (uint256)
    {
        return ((_amountX * 10**18) / _xPerYWei); // note: no rounding occurs as value is converted into wei
    }

    function _convertInverse(uint256 _xPerYWei, uint256 _amountX)
        internal
        pure
        returns (uint256)
    {
        return (_amountX * _xPerYWei) / 10**18; // note: no rounding occurs as value is converted into wei
    }

    function _getAddedXPerYInWei(bytes32 _keyX, bytes32 _keyY)
        internal
        view
        returns (uint256)
    {
        _requireAddedXPerYPriceFeedSupported(_keyX, _keyY);
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            _storageExchange().xToYToXAddedPerYPriceFeed[_keyX][_keyY]
        );
        (, int256 xPerY, , , ) = priceFeed.latestRoundData();
        uint256 decimals = priceFeed.decimals();
        return uint256(uint256(xPerY) * 10**(18 - decimals)); // convert to wei
    }

    function _getDerivedXPerYInWei(bytes32 _keyX, bytes32 _keyY)
        internal
        view
        returns (uint256)
    {
        _requireDerivedXPerYPriceFeedSupported(_keyX, _keyY);

        StorageExchange storage s1 = _storageExchange();

        // numerator
        AggregatorV3Interface priceFeedNumerator = AggregatorV3Interface(
            s1.xToYToXPerYDerivedPriceFeedDetails[_keyX][_keyY].numerator
        );
        (, int256 xPerYNumerator, , , ) = priceFeedNumerator.latestRoundData();
        uint256 decimalsNumerator = priceFeedNumerator.decimals();
        uint256 priceFeedNumeratorWei = uint256(
            uint256(xPerYNumerator) * 10**(18 - decimalsNumerator)
        ); // convert to wei
        bool isNumeratorInversed = s1
        .xToYToXPerYDerivedPriceFeedDetails[_keyX][_keyY].numeratorInverse;

        // denominator
        AggregatorV3Interface priceFeedDenominator = AggregatorV3Interface(
            s1.xToYToXPerYDerivedPriceFeedDetails[_keyX][_keyY].denominator
        );
        (, int256 xPerYDenominator, , , ) = priceFeedDenominator
            .latestRoundData();
        uint256 decimalsDenominator = priceFeedDenominator.decimals();
        uint256 priceFeedDenominatorWei = uint256(
            uint256(xPerYDenominator) * 10**(18 - decimalsDenominator)
        ); // convert to wei
        bool isDenominatorInversed = s1
        .xToYToXPerYDerivedPriceFeedDetails[_keyX][_keyY].denominatorInverse;

        uint256 xPerYWei;

        if (!isNumeratorInversed && !isDenominatorInversed) {
            xPerYWei =
                (priceFeedNumeratorWei * (10**18)) /
                priceFeedDenominatorWei;
        } else if (!isNumeratorInversed && isDenominatorInversed) {
            xPerYWei =
                (priceFeedNumeratorWei * (10**18)) /
                ((((10**18) * (10**18)) / priceFeedDenominatorWei));
        } else if (isNumeratorInversed && !isDenominatorInversed) {
            xPerYWei =
                ((((10**18) * (10**18)) / priceFeedNumeratorWei) * (10**18)) /
                priceFeedDenominatorWei;
        } else if (isNumeratorInversed && isDenominatorInversed) {
            xPerYWei =
                ((10**18) * (10**18)) /
                ((priceFeedNumeratorWei * (10**18)) / priceFeedDenominatorWei);
        } else {
            revert(
                "LibExchange: This revert should not ever be run - something seriously wrong with code"
            );
        }

        return xPerYWei;
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "Strings.sol";

library LibAccessControl {
    bytes32 constant STORAGE_POSITION_ACCESSCONTROL =
        keccak256("ds.accesscontrol");

    bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 constant MAINTAINER_ROLE = keccak256(abi.encode("MAINTAINER_ROLE"));
    bytes32 constant STRATEGIST_ROLE = keccak256(abi.encode("STRATEGIST_ROLE"));
    bytes32 constant HIVE_ROLE = keccak256(abi.encode("HIVE_ROLE"));
    // bytes32 constant GOVERNOR_ROLE = keccak256(abi.encode("GOVERNOR_ROLE"));

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    struct StorageAccessControl {
        mapping(bytes32 => RoleData) roles;
    }

    function _storageAccessControl()
        internal
        pure
        returns (StorageAccessControl storage s)
    {
        bytes32 position = STORAGE_POSITION_ACCESSCONTROL;
        assembly {
            s.slot := position
        }
    }

    function _requireOnlyRole(bytes32 _role) internal view {
        _checkRole(_role);
    }

    function _hasRole(bytes32 _role, address _account)
        internal
        view
        returns (bool)
    {
        return _storageAccessControl().roles[_role].members[_account];
    }

    function _checkRole(bytes32 _role) internal view {
        _checkRole(_role, msg.sender);
    }

    function _checkRole(bytes32 _role, address _account) internal view {
        if (!_hasRole(_role, _account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(_account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(_role), 32)
                    )
                )
            );
        }
    }

    function _getRoleAdmin(bytes32 _role) internal view returns (bytes32) {
        return _storageAccessControl().roles[_role].adminRole;
    }

    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    function _setRoleAdmin(bytes32 _role, bytes32 _adminRole) internal {
        bytes32 previousAdminRole = _getRoleAdmin(_role);
        _storageAccessControl().roles[_role].adminRole = _adminRole;
        emit RoleAdminChanged(_role, previousAdminRole, _adminRole);
    }

    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    function _grantRole(bytes32 _role, address _account) internal {
        if (!_hasRole(_role, _account)) {
            _storageAccessControl().roles[_role].members[_account] = true;
            emit RoleGranted(_role, _account, msg.sender);
        }
    }

    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    function _revokeRole(bytes32 _role, address _account) internal {
        if (_hasRole(_role, _account)) {
            _storageAccessControl().roles[_role].members[_account] = false;
            emit RoleRevoked(_role, _account, msg.sender);
        }
    }

    function _setupRole(bytes32 _role, address _account) internal {
        _grantRole(_role, _account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
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

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "LibAccessControl.sol";

// @Note CurrencyRegistry is separated from Exchange mainly to ease checks for Holding and Fee, and to separately register fiat and crypto easily
library LibCurrencyRegistry {
    bytes32 constant STORAGE_POSITION_CURRENCYREGISTRY =
        keccak256("ds.currencyregistry");

    struct StorageCurrencyRegistry {
        address nativeToken;
        mapping(bytes32 => bool) currencyKeyToSupported;
        mapping(bytes32 => bool) currencyKeyToCrypto;
    }

    function _storageCurrencyRegistry()
        internal
        pure
        returns (StorageCurrencyRegistry storage s)
    {
        bytes32 position = STORAGE_POSITION_CURRENCYREGISTRY;
        assembly {
            s.slot := position
        }
    }

    function _requireCurrencySupported(bytes32 _key) internal view {
        require(
            _storageCurrencyRegistry().currencyKeyToSupported[_key],
            "LibCurrencyRegistry: Currency not supported"
        );
    }

    // _requireIsCrypto does NOT check if is ERC20
    function _requireIsCrypto(bytes32 _key) internal view {
        require(
            _storageCurrencyRegistry().currencyKeyToCrypto[_key],
            "LibCurrencyRegistry: Not crypto"
        );
    }

    event NativeTokenSet(address indexed sender, address token);

    function _setNativeToken(address _token) internal {
        LibAccessControl._requireOnlyRole(LibAccessControl.DEFAULT_ADMIN_ROLE);

        _storageCurrencyRegistry().nativeToken = _token;

        emit NativeTokenSet(msg.sender, _token);
    }

    // code must follow: ISO-4217 Currency Code Standard: https://www.iso.org/iso-4217-currency-codes.html
    function _registerFiat(string memory _code) internal returns (bytes32) {
        require(
            bytes(_code).length != 0,
            "LibCurrencyRegistry: Empty code string"
        );
        bytes32 key = _encode_code(_code); //keccak256(abi.encode(_code));
        _register(key);
        return key;
    }

    function _encode_code(string memory _code) internal pure returns (bytes32) {
        return keccak256(abi.encode(_code));
    }

    function _registerCrypto(address _token) internal returns (bytes32) {
        require(
            _token != address(0),
            "LibCurrencyRegistry: Zero token address"
        );
        bytes32 key = _encode_token(_token); //bytes32(uint256(uint160(_token)) << 96);
        _register(key);
        _storageCurrencyRegistry().currencyKeyToCrypto[key] = true;
        return key;
    }

    function _encode_token(address _token) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_token)) << 96); // cannot be decoded
        // encode address: bytes32(uint256(uint160(_address)))
        // decode address: address(uint160(uint256(encoding)))
    }

    event CurrencyRegistered(address indexed sender, bytes32 key);

    function _register(bytes32 _key) internal {
        LibAccessControl._requireOnlyRole(LibAccessControl.STRATEGIST_ROLE);
        _storageCurrencyRegistry().currencyKeyToSupported[_key] = true;

        emit CurrencyRegistered(msg.sender, _key);
    }

    event CurrencyRemoved(address indexed sender, bytes32 key);

    function _removeCurrency(bytes32 _key) internal {
        LibAccessControl._requireOnlyRole(LibAccessControl.STRATEGIST_ROLE);
        _requireCurrencySupported(_key);
        StorageCurrencyRegistry storage s1 = _storageCurrencyRegistry();
        delete s1.currencyKeyToSupported[_key]; // delete cheaper than set false

        if (s1.currencyKeyToCrypto[_key]) {
            delete s1.currencyKeyToCrypto[_key];
        }

        emit CurrencyRemoved(msg.sender, _key);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "Cut.sol";

interface IHubLibraryEvents {
    event DiamondCut(Cut.FacetCut[] _cut, address _init, bytes _calldata);
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event NativeTokenSet(address indexed sender, address token);
    event CurrencyRegistered(address indexed sender, bytes32 key);
    event CurrencyRemoved(address indexed sender, bytes32 key);
    event PriceFeedAdded(
        address indexed sender,
        bytes32 keyX,
        bytes32 keyY,
        address priceFeed
    );
    event PriceFeedDerived(
        address indexed sender,
        bytes32 keyX,
        bytes32 keyY,
        bytes32 keyShared
    );
    event AddedPriceFeedRemoved(address indexed sender, address priceFeed);
    event DerivedPriceFeedRemoved(
        address indexed sender,
        bytes32 keyX,
        bytes32 keyY
    );
    event FeeSetCancellation(address indexed sender, uint256 fee);
    event FeeSetBase(address indexed sender, uint256 fee);
    event FeeSetCostPerMinute(address indexed sender, uint256 fee);
    event FeeSetCostPerMetre(address indexed sender, uint256 fee);
    event HiveCreationCountSet(address indexed sender, uint256 count);
    event FundsLocked(address indexed sender, bytes32 key, uint256 amount);
    event FundsUnlocked(
        address indexed sender,
        address decrease,
        address increase,
        bytes32 key,
        uint256 amount
    );
    event JobLifespanSet(address indexed sender, uint256 duration);
    event MinDisputeDurationSet(address indexed sender, uint256 duration);
    event HiveDisputeDurationSet(address indexed sender, uint256 duration);
    event JobCleared(address indexed sender, bytes32 indexed jobId);
    event UserBanned(address indexed sender, address user, uint256 banDuration);
    event SetRatingBounds(address indexed sender, uint256 min, uint256 max);
    event RatingGiven(address indexed sender, uint256 rating);
    event ApplicantApproved(address indexed sender, address applicant);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "LibCutAndLoupe.sol";
import "LibAccessControl.sol";

contract Cut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    } // just a data structure, not storing anything

    event DiamondCut(FacetCut[] _cut, address _init, bytes _calldata);

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _cut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function cut(
        FacetCut[] calldata _cut,
        address _init,
        bytes calldata _calldata
    ) external {
        LibAccessControl._requireOnlyRole(LibAccessControl.MAINTAINER_ROLE);

        LibCutAndLoupe.StorageCutAndLoupe storage ds = LibCutAndLoupe
            ._storageCutAndLoupe();
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        // Check if last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // get last selectorSlot
            // "selectorCount >> 3" is a gas efficient division by 8 "selectorCount / 8"
            selectorSlot = ds.selectorSlots[selectorCount >> 3];
        }
        // loop through diamond cut
        for (uint256 facetIndex; facetIndex < _cut.length; facetIndex++) {
            (selectorCount, selectorSlot) = LibCutAndLoupe
                ._addReplaceRemoveFacetSelectors(
                    selectorCount,
                    selectorSlot,
                    _cut[facetIndex].facetAddress,
                    _cut[facetIndex].action,
                    _cut[facetIndex].functionSelectors
                );
        }
        if (selectorCount != originalSelectorCount) {
            ds.selectorCount = uint16(selectorCount);
        }
        // If last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // "selectorCount >> 3" is a gas efficient division by 8 "selectorCount / 8"
            ds.selectorSlots[selectorCount >> 3] = selectorSlot;
        }
        emit DiamondCut(_cut, _init, _calldata);
        LibCutAndLoupe._initializeCut(_init, _calldata);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "Cut.sol";
import "LibAccessControl.sol";

library LibCutAndLoupe {
    // TODO
    // there is a bug where if import "LibAccessControl.sol"; is excluded from LibCutAndLoupe.sol,
    // but LibCutAndLoupe.sol uses its functions, both brownie and hardhat compilers would NOT detect this error
    // and verification would fail

    bytes32 constant STORAGE_POSITION_CUTANDLOUPE = keccak256("ds.cutandloupe");

    struct StorageCutAndLoupe {
        // maps function selectors to the facets that execute the functions.
        // and maps the selectors to their position in the selectorSlots array.
        // func selector => address facet, selector position
        mapping(bytes4 => bytes32) facets;
        // array of slots of function selectors.
        // each slot holds 8 function selectors.
        mapping(uint256 => bytes32) selectorSlots;
        // The number of function selectors in selectorSlots
        uint16 selectorCount;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        // mapping(bytes4 => bool) supportedInterfaces;
    }

    function _storageCutAndLoupe()
        internal
        pure
        returns (StorageCutAndLoupe storage s)
    {
        bytes32 position = STORAGE_POSITION_CUTANDLOUPE;
        assembly {
            s.slot := position
        }
    }

    event DiamondCut(Cut.FacetCut[] _cut, address _init, bytes _calldata);

    bytes32 constant CLEAR_ADDRESS_MASK =
        bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

    // Internal function version of cut
    // This code is almost the same as the external cut,
    // except it is using 'Facet[] memory _cut' instead of
    // 'Facet[] calldata _cut'.
    // The code is duplicated to prevent copying calldata to memory which
    // causes an error for a two dimensional array.
    function cut(
        Cut.FacetCut[] memory _cut,
        address _init,
        bytes memory _calldata
    ) internal {
        LibAccessControl._requireOnlyRole(LibAccessControl.MAINTAINER_ROLE);

        StorageCutAndLoupe storage s1 = _storageCutAndLoupe();
        uint256 originalSelectorCount = s1.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        // Check if last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // get last selectorSlot
            // "selectorSlot >> 3" is a gas efficient division by 8 "selectorSlot / 8"
            selectorSlot = s1.selectorSlots[selectorCount >> 3];
        }
        // loop through diamond cut
        for (uint256 facetIndex; facetIndex < _cut.length; facetIndex++) {
            (selectorCount, selectorSlot) = _addReplaceRemoveFacetSelectors(
                selectorCount,
                selectorSlot,
                _cut[facetIndex].facetAddress,
                _cut[facetIndex].action,
                _cut[facetIndex].functionSelectors
            );
        }
        if (selectorCount != originalSelectorCount) {
            s1.selectorCount = uint16(selectorCount);
        }
        // If last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // "selectorSlot >> 3" is a gas efficient division by 8 "selectorSlot / 8"
            s1.selectorSlots[selectorCount >> 3] = selectorSlot;
        }
        emit DiamondCut(_cut, _init, _calldata);
        _initializeCut(_init, _calldata);
    }

    function _addReplaceRemoveFacetSelectors(
        uint256 _selectorCount,
        bytes32 _selectorSlot,
        address _newFacetAddress,
        Cut.FacetCutAction _action,
        bytes4[] memory _selectors
    ) internal returns (uint256, bytes32) {
        StorageCutAndLoupe storage s1 = _storageCutAndLoupe();
        require(
            _selectors.length > 0,
            "LibCutAndLoupe: No selectors in facet to cut"
        );
        if (_action == Cut.FacetCutAction.Add) {
            _requireHasContractCode(
                _newFacetAddress,
                "LibCutAndLoupe: Add facet has no code"
            );
            for (
                uint256 selectorIndex;
                selectorIndex < _selectors.length;
                selectorIndex++
            ) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = s1.facets[selector];
                require(
                    address(bytes20(oldFacet)) == address(0),
                    "LibCutAndLoupe: Can't add function that already exists"
                );
                // add facet for selector
                s1.facets[selector] =
                    bytes20(_newFacetAddress) |
                    bytes32(_selectorCount);
                // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8"
                uint256 selectorInSlotPosition = (_selectorCount & 7) << 5;
                // clear selector position in slot and add selector
                _selectorSlot =
                    (_selectorSlot &
                        ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) |
                    (bytes32(selector) >> selectorInSlotPosition);
                // if slot is full then write it to storage
                if (selectorInSlotPosition == 224) {
                    // "_selectorSlot >> 3" is a gas efficient division by 8 "_selectorSlot / 8"
                    s1.selectorSlots[_selectorCount >> 3] = _selectorSlot;
                    _selectorSlot = 0;
                }
                _selectorCount++;
            }
        } else if (_action == Cut.FacetCutAction.Replace) {
            _requireHasContractCode(
                _newFacetAddress,
                "LibCutAndLoupe: Replace facet has no code"
            );
            for (
                uint256 selectorIndex;
                selectorIndex < _selectors.length;
                selectorIndex++
            ) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = s1.facets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));
                // only useful if immutable functions exist
                require(
                    oldFacetAddress != address(this),
                    "LibCutAndLoupe: Can't replace immutable function"
                );
                require(
                    oldFacetAddress != _newFacetAddress,
                    "LibCutAndLoupe: Can't replace function with same function"
                );
                require(
                    oldFacetAddress != address(0),
                    "LibCutAndLoupe: Can't replace function that doesn't exist"
                );
                // replace old facet address
                s1.facets[selector] =
                    (oldFacet & CLEAR_ADDRESS_MASK) |
                    bytes20(_newFacetAddress);
            }
        } else if (_action == Cut.FacetCutAction.Remove) {
            require(
                _newFacetAddress == address(0),
                "LibCutAndLoupe: Remove facet address must be address(0)"
            );
            // "_selectorCount >> 3" is a gas efficient division by 8 "_selectorCount / 8"
            uint256 selectorSlotCount = _selectorCount >> 3;
            // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8"
            uint256 selectorInSlotIndex = _selectorCount & 7;
            for (
                uint256 selectorIndex;
                selectorIndex < _selectors.length;
                selectorIndex++
            ) {
                if (_selectorSlot == 0) {
                    // get last selectorSlot
                    selectorSlotCount--;
                    _selectorSlot = s1.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                } else {
                    selectorInSlotIndex--;
                }
                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;
                // adding a block here prevents stack too deep error
                {
                    bytes4 selector = _selectors[selectorIndex];
                    bytes32 oldFacet = s1.facets[selector];
                    require(
                        address(bytes20(oldFacet)) != address(0),
                        "LibCutAndLoupe: Can't remove function that doesn't exist"
                    );
                    // only useful if immutable functions exist
                    require(
                        address(bytes20(oldFacet)) != address(this),
                        "LibCutAndLoupe: Can't remove immutable function"
                    );
                    // replace selector with last selector in s1.facets
                    // gets the last selector
                    lastSelector = bytes4(
                        _selectorSlot << (selectorInSlotIndex << 5)
                    );
                    if (lastSelector != selector) {
                        // update last selector slot position info
                        s1.facets[lastSelector] =
                            (oldFacet & CLEAR_ADDRESS_MASK) |
                            bytes20(s1.facets[lastSelector]);
                    }
                    delete s1.facets[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    // "oldSelectorCount >> 3" is a gas efficient division by 8 "oldSelectorCount / 8"
                    oldSelectorsSlotCount = oldSelectorCount >> 3;
                    // "oldSelectorCount & 7" is a gas efficient modulo by eight "oldSelectorCount % 8"
                    oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
                }
                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = s1.selectorSlots[
                        oldSelectorsSlotCount
                    ];
                    // clears the selector we are deleting and puts the last selector in its place.
                    oldSelectorSlot =
                        (oldSelectorSlot &
                            ~(CLEAR_SELECTOR_MASK >>
                                oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                    // update storage with the modified slot
                    s1.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    // clears the selector we are deleting and puts the last selector in its place.
                    _selectorSlot =
                        (_selectorSlot &
                            ~(CLEAR_SELECTOR_MASK >>
                                oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }
                if (selectorInSlotIndex == 0) {
                    delete s1.selectorSlots[selectorSlotCount];
                    _selectorSlot = 0;
                }
            }
            _selectorCount = selectorSlotCount * 8 + selectorInSlotIndex;
        } else {
            revert("LibCutAndLoupe: Incorrect FacetCutAction");
        }
        return (_selectorCount, _selectorSlot);
    }

    function _initializeCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(
                _calldata.length == 0,
                "LibCutAndLoupe: _init is address(0) but_calldata is not empty"
            );
        } else {
            require(
                _calldata.length > 0,
                "LibCutAndLoupe: _calldata is empty but _init is not address(0)"
            );
            if (_init != address(this)) {
                _requireHasContractCode(
                    _init,
                    "LibCutAndLoupe: _init address has no code"
                );
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibCutAndLoupe: _init function reverted");
                }
            }
        }
    }

    function _requireHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}