//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "RideLibExchange.sol";

contract RideExchange {
    function addXPerYPriceFeed(
        bytes32 _keyX,
        bytes32 _keyY,
        address _priceFeed
    ) external {
        RideLibExchange._addXPerYPriceFeed(_keyX, _keyY, _priceFeed);
    }

    function deriveXPerYPriceFeed(
        bytes32 _keyX,
        bytes32 _keyY,
        bytes32 _keyShared
    ) external {
        RideLibExchange._deriveXPerYPriceFeed(_keyX, _keyY, _keyShared);
    }

    function removeAddedXPerYPriceFeed(bytes32 _keyX, bytes32 _keyY) external {
        RideLibExchange._removeAddedXPerYPriceFeed(_keyX, _keyY);
    }

    function removeDerivedXPerYPriceFeed(bytes32 _keyX, bytes32 _keyY)
        external
    {
        RideLibExchange._removeDerivedXPerYPriceFeed(_keyX, _keyY);
    }

    function getAddedXPerYPriceFeed(bytes32 _keyX, bytes32 _keyY)
        external
        view
        returns (address)
    {
        RideLibExchange._requireAddedXPerYPriceFeedSupported(_keyX, _keyY);
        return
            RideLibExchange._storageExchange().xToYToXAddedPerYPriceFeed[_keyX][
                _keyY
            ];
    }

    function getAddedXPerYPriceFeedValue(bytes32 _keyX, bytes32 _keyY)
        external
        view
        returns (uint256)
    {
        RideLibExchange._requireAddedXPerYPriceFeedSupported(_keyX, _keyY);
        return RideLibExchange._getAddedXPerYInWei(_keyX, _keyY);
    }

    function getDerivedXPerYPriceFeedDetails(bytes32 _keyX, bytes32 _keyY)
        external
        view
        returns (RideLibExchange.DerivedPriceFeedDetails memory)
    {
        RideLibExchange._requireDerivedXPerYPriceFeedSupported(_keyX, _keyY);
        return
            RideLibExchange
                ._storageExchange()
                .xToYToXPerYDerivedPriceFeedDetails[_keyX][_keyY];
    }

    function getDerivedXPerYPriceFeedValue(bytes32 _keyX, bytes32 _keyY)
        external
        view
        returns (uint256)
    {
        RideLibExchange._requireDerivedXPerYPriceFeedSupported(_keyX, _keyY);
        return RideLibExchange._getDerivedXPerYInWei(_keyX, _keyY);
    }

    function convertCurrency(
        bytes32 _keyX,
        bytes32 _keyY,
        uint256 _amountX
    ) external view returns (uint256) {
        return RideLibExchange._convertCurrency(_keyX, _keyY, _amountX);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "RideLibAccessControl.sol";
import "RideLibCurrencyRegistry.sol";

import "AggregatorV3Interface.sol";

library RideLibExchange {
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
        // useful for removal
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
            "RideLibExchange: Price feed not supported"
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
            "RideLibExchange: Derived price feed not supported"
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
        RideLibAccessControl._requireOnlyRole(
            RideLibAccessControl.STRATEGIST_ROLE
        );
        RideLibCurrencyRegistry._requireCurrencySupported(_keyX);
        RideLibCurrencyRegistry._requireCurrencySupported(_keyY);

        require(
            _priceFeed != address(0),
            "RideLibExchange: Zero price feed address"
        );
        StorageExchange storage s1 = _storageExchange();
        require(
            s1.xToYToXAddedPerYPriceFeed[_keyX][_keyY] == address(0),
            "RideLibExchange: Price feed already supported"
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
        RideLibAccessControl._requireOnlyRole(
            RideLibAccessControl.STRATEGIST_ROLE
        );
        require(
            _keyX != _keyY,
            "RideLibExchange: Underlying currency key cannot be identical"
        );
        _requireAddedXPerYPriceFeedSupported(_keyX, _keyShared);
        _requireAddedXPerYPriceFeedSupported(_keyY, _keyShared);

        StorageExchange storage s1 = _storageExchange();
        require(
            s1.xToYToXPerYDerivedPriceFeedDetails[_keyX][_keyY].numerator ==
                address(0),
            "RideLibExchange: Derived price feed already supported"
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
        RideLibAccessControl._requireOnlyRole(
            RideLibAccessControl.STRATEGIST_ROLE
        );
        _requireAddedXPerYPriceFeedSupported(_keyX, _keyY);

        StorageExchange storage s1 = _storageExchange();

        require(
            s1.xToYToBaseKeyCount[_keyX][_keyY] == 0,
            "RideLibExchange: Base key being used"
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
        RideLibAccessControl._requireOnlyRole(
            RideLibAccessControl.STRATEGIST_ROLE
        );
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
                "RideLibExchange: This revert should not ever be run - something seriously wrong with code"
            );
        }

        return xPerYWei;
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "Strings.sol";

library RideLibAccessControl {
    bytes32 constant STORAGE_POSITION_ACCESSCONTROL =
        keccak256("ds.accesscontrol");

    bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 constant MAINTAINER_ROLE = keccak256(abi.encode("MAINTAINER_ROLE"));
    bytes32 constant STRATEGIST_ROLE = keccak256(abi.encode("STRATEGIST_ROLE"));
    bytes32 constant GOVERNOR_ROLE = keccak256(abi.encode("GOVERNOR_ROLE"));
    bytes32 constant REVIEWER_ROLE = keccak256(abi.encode("REVIEWER_ROLE"));

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

import "RideLibAccessControl.sol";

// @Note CurrencyRegistry is separated from Exchange mainly to ease checks for Holding and Fee, and to separately register fiat and crypto easily
library RideLibCurrencyRegistry {
    bytes32 constant STORAGE_POSITION_CURRENCYREGISTRY =
        keccak256("ds.currencyregistry");

    struct StorageCurrencyRegistry {
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
            "RideLibCurrencyRegistry: Currency not supported"
        );
    }

    // _requireIsCrypto does NOT check if is ERC20
    function _requireIsCrypto(bytes32 _key) internal view {
        require(
            _storageCurrencyRegistry().currencyKeyToCrypto[_key],
            "RideLibCurrencyRegistry: Not crypto"
        );
    }

    // code must follow: ISO-4217 Currency Code Standard: https://www.iso.org/iso-4217-currency-codes.html
    function _registerFiat(string memory _code) internal returns (bytes32) {
        require(
            bytes(_code).length != 0,
            "RideLibCurrencyRegistry: Empty code string"
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
            "RideLibCurrencyRegistry: Zero token address"
        );
        bytes32 key = _encode_token(_token); //bytes32(uint256(uint160(_token)) << 96);
        _register(key);
        _storageCurrencyRegistry().currencyKeyToCrypto[key] = true;
        return key;
    }

    function _encode_token(address _token) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_token)) << 96);
    }

    event CurrencyRegistered(address indexed sender, bytes32 key);

    function _register(bytes32 _key) internal {
        RideLibAccessControl._requireOnlyRole(
            RideLibAccessControl.STRATEGIST_ROLE
        );
        _storageCurrencyRegistry().currencyKeyToSupported[_key] = true;

        emit CurrencyRegistered(msg.sender, _key);
    }

    event CurrencyRemoved(address indexed sender, bytes32 key);

    function _removeCurrency(bytes32 _key) internal {
        RideLibAccessControl._requireOnlyRole(
            RideLibAccessControl.STRATEGIST_ROLE
        );
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