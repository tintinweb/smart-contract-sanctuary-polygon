//SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

import "./PeriodicOracle.sol";
import "./IAggregatedOracle.sol";

contract AggregatedOracle is IAggregatedOracle, PeriodicOracle {
    /*
     * Structs
     */

    struct TokenSpecificOracle {
        address token;
        address oracle;
    }

    struct OracleConfig {
        address oracle;
        uint8 quoteTokenDecimals;
    }

    /*
     * Internal variables
     */

    OracleConfig[] internal oracles;
    mapping(address => OracleConfig[]) internal tokenSpecificOracles;

    string internal _quoteTokenName;
    string internal _quoteTokenSymbol;
    address internal immutable _quoteTokenAddress;
    uint8 internal immutable _quoteTokenDecimals;

    /*
     * Private variables
     */

    mapping(address => bool) private oracleExists;
    mapping(address => mapping(address => bool)) private oracleForExists;

    /*
     * Constructors
     */

    constructor(
        string memory quoteTokenName_,
        address quoteTokenAddress_,
        string memory quoteTokenSymbol_,
        uint8 quoteTokenDecimals_,
        address[] memory oracles_,
        TokenSpecificOracle[] memory tokenSpecificOracles_,
        uint256 period_
    ) PeriodicOracle(address(0), period_) {
        require(oracles_.length > 0 || tokenSpecificOracles_.length > 0, "AggregatedOracle: MISSING_ORACLES");

        // Setup general oracles
        for (uint256 i = 0; i < oracles_.length; ++i) {
            require(!oracleExists[oracles_[i]], "AggregatedOracle: DUPLICATE_ORACLE");

            oracleExists[oracles_[i]] = true;

            oracles.push(
                OracleConfig({oracle: oracles_[i], quoteTokenDecimals: IOracle(oracles_[i]).quoteTokenDecimals()})
            );
        }

        // Setup token-specific oracles
        for (uint256 i = 0; i < tokenSpecificOracles_.length; ++i) {
            TokenSpecificOracle memory oracle = tokenSpecificOracles_[i];

            require(!oracleExists[oracle.oracle], "AggregatedOracle: DUPLICATE_ORACLE");
            require(!oracleForExists[oracle.token][oracle.oracle], "AggregatedOracle: DUPLICATE_ORACLE");

            oracleForExists[oracle.token][oracle.oracle] = true;

            tokenSpecificOracles[oracle.token].push(
                OracleConfig({oracle: oracle.oracle, quoteTokenDecimals: IOracle(oracle.oracle).quoteTokenDecimals()})
            );
        }

        // We store quote token information like this just-in-case the underlying oracles use different quote tokens.
        // Note: All underlying quote tokens must be loosly equal (i.e. equal in value).
        _quoteTokenName = quoteTokenName_;
        _quoteTokenAddress = quoteTokenAddress_;
        _quoteTokenSymbol = quoteTokenSymbol_;
        _quoteTokenDecimals = quoteTokenDecimals_;
    }

    /*
     * External functions
     */

    function getOracles() external view virtual override returns (address[] memory) {
        OracleConfig[] memory _oracles = oracles;

        address[] memory allOracles = new address[](_oracles.length);

        // Add the general oracles
        for (uint256 i = 0; i < _oracles.length; ++i) allOracles[i] = _oracles[i].oracle;

        return allOracles;
    }

    function getOraclesFor(address token) external view virtual override returns (address[] memory) {
        OracleConfig[] memory _tokenSpecificOracles = tokenSpecificOracles[token];
        OracleConfig[] memory _oracles = oracles;

        address[] memory allOracles = new address[](_oracles.length + _tokenSpecificOracles.length);

        // Add the general oracles
        for (uint256 i = 0; i < _oracles.length; ++i) allOracles[i] = _oracles[i].oracle;

        // Add the token specific oracles
        for (uint256 i = 0; i < _tokenSpecificOracles.length; ++i)
            allOracles[_oracles.length + i] = _tokenSpecificOracles[i].oracle;

        return allOracles;
    }

    /*
     * Public functions
     */

    function quoteTokenName() public view virtual override(IQuoteToken, AbstractOracle) returns (string memory) {
        return _quoteTokenName;
    }

    function quoteTokenAddress() public view virtual override(IQuoteToken, AbstractOracle) returns (address) {
        return _quoteTokenAddress;
    }

    function quoteTokenSymbol() public view virtual override(IQuoteToken, AbstractOracle) returns (string memory) {
        return _quoteTokenSymbol;
    }

    function quoteTokenDecimals() public view virtual override(IQuoteToken, AbstractOracle) returns (uint8) {
        return _quoteTokenDecimals;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAggregatedOracle).interfaceId || super.supportsInterface(interfaceId);
    }

    /*
     * Internal functions
     */

    function _update(address token) internal override returns (bool) {
        bool underlyingUpdated;

        // Ensure all underlying oracles are up-to-date
        for (uint256 j = 0; j < 2; ++j) {
            OracleConfig[] memory _oracles;

            if (j == 0) _oracles = oracles;
            else _oracles = tokenSpecificOracles[token];

            for (uint256 i = 0; i < _oracles.length; ++i) {
                // We don't want any problematic underlying oracles to prevent this oracle from updating
                // so we put update in a try-catch block
                try IOracle(_oracles[i].oracle).update(token) returns (bool updated) {
                    underlyingUpdated = underlyingUpdated || updated;
                } catch Error(string memory reason) {
                    emit UpdateErrorWithReason(_oracles[i].oracle, token, reason);
                } catch (bytes memory err) {
                    emit UpdateError(_oracles[i].oracle, token, err);
                }
            }
        }

        uint256 price;
        uint256 tokenLiquidity;
        uint256 quoteTokenLiquidity;
        uint256 validResponses;

        (price, tokenLiquidity, quoteTokenLiquidity, validResponses) = consultFresh(token);

        if (validResponses >= 1) {
            ObservationLibrary.Observation storage observation = observations[token];

            observation.price = price;
            observation.tokenLiquidity = tokenLiquidity;
            observation.quoteTokenLiquidity = quoteTokenLiquidity;
            observation.timestamp = block.timestamp;

            emit Updated(token, _quoteTokenAddress, block.timestamp, price, tokenLiquidity, quoteTokenLiquidity);

            return true;
        } else emit UpdateErrorWithReason(address(this), token, "AggregatedOracle: INVALID_NUM_CONSULTATIONS");

        return underlyingUpdated;
    }

    function consultFresh(address token)
        internal
        returns (
            uint256 price,
            uint256 tokenLiquidity,
            uint256 quoteTokenLiquidity,
            uint256 validResponses
        )
    {
        uint256 qtDecimals = quoteTokenDecimals();

        // We use period * 2 as the max age just in-case the update of the particular underlying oracle failed.
        // We don't want to use old data.
        uint256 maxAge = period * 2;

        uint256 denominator; // sum of oracleQuoteTokenLiquidity divided by oraclePrice

        for (uint256 j = 0; j < 2; ++j) {
            OracleConfig[] memory _oracles;

            if (j == 0) _oracles = oracles;
            else _oracles = tokenSpecificOracles[token];

            for (uint256 i = 0; i < _oracles.length; ++i) {
                // We don't want problematic underlying oracles to prevent us from calculating the aggregated
                // results from the other working oracles, so we use a try-catch block.
                try IOracle(_oracles[i].oracle).consult(token, maxAge) returns (
                    uint256 oraclePrice,
                    uint256 oracleTokenLiquidity,
                    uint256 oracleQuoteTokenLiquidity
                ) {
                    uint256 decimals = _oracles[i].quoteTokenDecimals;

                    // Fix differing quote token decimal places
                    if (decimals < qtDecimals) {
                        // Scale up
                        uint256 scalar = 10**(qtDecimals - decimals);

                        oraclePrice *= scalar;
                        oracleQuoteTokenLiquidity *= scalar;
                    } else if (decimals > qtDecimals) {
                        // Scale down
                        uint256 scalar = 10**(decimals - qtDecimals);

                        oraclePrice /= scalar;
                        oracleQuoteTokenLiquidity /= scalar;
                    }

                    if (oraclePrice != 0 && oracleQuoteTokenLiquidity != 0) {
                        ++validResponses;

                        denominator += oracleQuoteTokenLiquidity / oraclePrice;

                        // These should never overflow: supply of an asset cannot be greater than uint256.max
                        tokenLiquidity += oracleTokenLiquidity;
                        quoteTokenLiquidity += oracleQuoteTokenLiquidity;
                    }
                } catch Error(string memory reason) {
                    emit ConsultErrorWithReason(oracles[i].oracle, token, reason);
                } catch (bytes memory err) {
                    emit ConsultError(oracles[i].oracle, token, err);
                }
            }
        }

        price = denominator == 0 ? 0 : quoteTokenLiquidity / denominator;
    }
}