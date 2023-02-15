/**
 *Submitted for verification at polygonscan.com on 2023-02-15
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

// File: witnet-solidity-bridge\contracts\interfaces\IWitnetPriceFeed.sol
/// @title The Witnet Price Feed basic interface.
/// @dev Guides implementation of active price feed polling contracts.
/// @author The Witnet Foundation.

interface IWitnetPriceFeed {

    /// Signals that a new price update request is being posted to the Witnet Request Board
    event PriceFeeding(address indexed from, uint256 queryId, uint256 extraFee);

    /// Estimates minimum fee amount in native currency to be paid when 
    /// requesting a new price update.
    /// @dev Actual fee depends on the gas price of the `requestUpdate()` transaction.
    /// @param _gasPrice Gas price expected to be paid when calling `requestUpdate()`
    function estimateUpdateFee(uint256 _gasPrice) external view returns (uint256);

    /// Returns result of the last valid price update request successfully solved by the Witnet oracle.
    function lastPrice() external view returns (int256);

    /// Returns the EVM-timestamp when last valid price was reported back from the Witnet oracle.
    function lastTimestamp() external view returns (uint256);    

    /// Returns tuple containing last valid price and timestamp, as well as status code of latest update
    /// request that got posted to the Witnet Request Board.
    /// @return _lastPrice Last valid price reported back from the Witnet oracle.
    /// @return _lastTimestamp EVM-timestamp of the last valid price.
    /// @return _lastDrTxHash Hash of the Witnet Data Request that solved the last valid price.
    /// @return _latestUpdateStatus Status code of the latest update request.
    function lastValue() external view returns (
        int _lastPrice,
        uint _lastTimestamp,
        bytes32 _lastDrTxHash,
        uint _latestUpdateStatus
    );

    /// Returns identifier of the latest update request posted to the Witnet Request Board.
    function latestQueryId() external view returns (uint256);

    /// Returns hash of the Witnet Data Request that solved the latest update request.
    /// @dev Returning 0 while the latest update request remains unsolved.
    function latestUpdateDrTxHash() external view returns (bytes32);

    /// Returns error message of latest update request posted to the Witnet Request Board.
    /// @dev Returning empty string if the latest update request remains unsolved, or
    /// @dev if it was succesfully solved with no errors.
    function latestUpdateErrorMessage() external view returns (string memory);

    /// Returns status code of latest update request posted to the Witnet Request Board:
    /// @dev Status codes:
    /// @dev   - 200: update request was succesfully solved with no errors
    /// @dev   - 400: update request was solved with errors
    /// @dev   - 404: update request was not solved yet 
    function latestUpdateStatus() external view returns (uint256);

    /// Returns `true` if latest update request posted to the Witnet Request Board 
    /// has not been solved yet by the Witnet oracle.
    function pendingUpdate() external view returns (bool);

    /// Posts a new price update request to the Witnet Request Board. Requires payment of a fee
    /// that depends on the value of `tx.gasprice`. See `estimateUpdateFee(uint256)`.
    /// @dev If previous update request was not solved yet, calling this method again allows
    /// @dev upgrading the update fee if called with a higher `tx.gasprice` value.
    function requestUpdate() external payable;

    /// Tells whether this contract implements the interface defined by `interfaceId`. 
    /// @dev See the corresponding https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
    /// @dev to learn more about how these ids are created.
    function supportsInterface(bytes4) external view returns (bool);
}
// File: ado-contracts\contracts\interfaces\IERC2362.sol
/**
* @dev EIP2362 Interface for pull oracles
* https://github.com/adoracles/EIPs/blob/erc-2362/EIPS/eip-2362.md
*/
interface IERC2362
{
	/**
	 * @dev Exposed function pertaining to EIP standards
	 * @param _id bytes32 ID of the query
	 * @return int,uint,uint returns the value, timestamp, and status code of query
	 */
	function valueFor(bytes32 _id) external view returns(int256,uint256,uint256);
}
// File: node_modules\witnet-solidity-bridge\contracts\interfaces\IERC165.sol
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
// File: witnet-solidity-bridge\contracts\interfaces\IWitnetPriceRouter.sol
/// @title The Witnet Price Router basic interface.
/// @dev Guides implementation of price feeds aggregation contracts.
/// @author The Witnet Foundation.
abstract contract IWitnetPriceRouter
    is
        IERC2362 
{
    /// Emitted everytime a currency pair is attached to a new price feed contract
    /// @dev See https://github.com/adoracles/ADOIPs/blob/main/adoip-0010.md 
    /// @dev to learn how these ids are created.
    event CurrencyPairSet(bytes32 indexed erc2362ID, IERC165 pricefeed);

    /// Helper pure function: returns hash of the provided ERC2362-compliant currency pair caption (aka ID).
    function currencyPairId(string memory) external pure virtual returns (bytes32);

    /// Returns the ERC-165-compliant price feed contract currently serving 
    /// updates on the given currency pair.
    function getPriceFeed(bytes32 _erc2362id) external view virtual returns (IERC165);

    /// Returns human-readable ERC2362-based caption of the currency pair being
    /// served by the given price feed contract address. 
    /// @dev Should fail if the given price feed contract address is not currently
    /// @dev registered in the router.
    function getPriceFeedCaption(IERC165) external view virtual returns (string memory);

    /// Returns human-readable caption of the ERC2362-based currency pair identifier, if known.
    function lookupERC2362ID(bytes32 _erc2362id) external view virtual returns (string memory);

    /// Register a price feed contract that will serve updates for the given currency pair.
    /// @dev Setting zero address to a currency pair implies that it will not be served any longer.
    /// @dev Otherwise, should fail if the price feed contract does not support the `IWitnetPriceFeed` interface,
    /// @dev or if given price feed is already serving another currency pair (within this WitnetPriceRouter instance).
    function setPriceFeed(
            IERC165 _pricefeed,
            uint256 _decimals,
            string calldata _base,
            string calldata _quote
        )
        external virtual;

    /// Returns list of known currency pairs IDs.
    function supportedCurrencyPairs() external view virtual returns (bytes32[] memory);

    /// Returns `true` if given pair is currently being served by a compliant price feed contract.
    function supportsCurrencyPair(bytes32 _erc2362id) external view virtual returns (bool);

    /// Returns `true` if given price feed contract is currently serving updates to any known currency pair. 
    function supportsPriceFeed(IERC165 _priceFeed) external view virtual returns (bool);
}
// File: contracts\WitnetPriceFeedRouted.sol
abstract contract WitnetPriceFeedRouted
    is
        IWitnetPriceFeed
{
    /// Immutable IWitnetPriceRouter instance that will be used for price calculation.
    IWitnetPriceRouter immutable public router;

    /// List of currency pairs from which the price of this price feed will be calculated.
    bytes32[] public pairs;
   
    /// Constructor.
    /// @param _witnetPriceRouter Address of the WitnetPriceRouter instance supporting given pairs
    constructor (IWitnetPriceRouter _witnetPriceRouter) {
        assert(address(_witnetPriceRouter) != address(0));
        router = _witnetPriceRouter;
    }

    /// @dev Routed price feeds require no fee.
    function estimateUpdateFee(uint256)
        external pure
        virtual override
        returns (uint256)
    {
        return 0;
    }

    /// Returns number of pairs from which this price feed will be calculated.
    function getPairsCount()
        external view
        returns (uint256)
    {
        return pairs.length;
    }

    /// Returns on-the-fly calculated price, based on last valid values of referred currency pairs.
    function lastPrice()
        external view
        virtual override
        returns (int256 _lastPrice)
    {
        int256[] memory _prices = new int256[](pairs.length);
        for (uint _i = 0; _i < _prices.length; _i ++) {
            _prices[_i] = _getPriceFeed(_i).lastPrice();
        }
        return _calculate(_prices);
    }

    /// Returns timestamp of the latest valid update on any of the referred currency pairs.
    function lastTimestamp()
        external view
        virtual override
        returns (uint256 _lastTimestamp)
    {
        for (uint _i = 0; _i < pairs.length; _i ++) {
            uint256 _ts = _getPriceFeed(_i).lastTimestamp();
            if (_ts > _lastTimestamp) {
                _lastTimestamp = _ts;
            }
        }
    }

    /// Returns tuple containing last valid price and timestamp, as well as status code of latest update
    /// request that got posted to the Witnet Request Board from any of the referred currency pairs.
    /// @return _lastPrice Last valid price reported back from the Witnet oracle.
    /// @return _lastTimestamp EVM-timestamp of the last valid price.
    /// @return _lastDrTxHash Hash of the Witnet Data Request that solved the last valid price.
    /// @return _latestUpdateStatus Status code of the latest update request.
    function lastValue()
        external view
        virtual override
        returns (
            int _lastPrice,
            uint _lastTimestamp,
            bytes32 _lastDrTxHash,
            uint _latestUpdateStatus
        )
    {
        _latestUpdateStatus = 200;
        int256[] memory _prices = new int256[](pairs.length);        
        for (uint _i = 0; _i < _prices.length; _i ++) {
            uint _ts; uint _lus; bytes32 _hash;
            IWitnetPriceFeed _pf = _getPriceFeed(_i);
            (_prices[_i], _ts, _hash, _lus) = _pf.lastValue();
            if (_ts > _lastTimestamp) {
                _lastTimestamp = _ts;
                _lastDrTxHash = _hash;
            }
            if (_lus > _latestUpdateStatus) {
                _latestUpdateStatus = _lus;
            }
        }
        _lastPrice = _calculate(_prices);
    }

    /// Returns the ID of the last price update posted to the Witnet Request Board,
    /// from any of the referred currency pairs.
    function latestQueryId()
        external view
        virtual override
        returns (uint256 _latest)
    {
        for (uint _i = 0; _i < pairs.length; _i ++) {
            uint256 _queryId = _getPriceFeed(_i).latestQueryId();
            if (_queryId > _latest) {
                _latest = _queryId;
            }
        }
    }

    /// Returns identifier of the latest update request posted to the Witnet Request Board,
    /// from any of the referred currency pairs.
    /// @dev Returning 0 while the latest update request remains unsolved.
    function latestUpdateDrTxHash()
        external view
        virtual override
        returns (bytes32)
    {
        (uint _index, ) = _latestUpdateStatusIndex();
        return _getPriceFeed(_index).latestUpdateDrTxHash();
    }

    /// Returns error message of latest update request posted to the Witnet Request Board,
    /// from any of the referred currency pairs.
    /// @dev Returning empty string if the latest update request remains unsolved, or
    /// @dev if it was succesfully solved with no errors.
    function latestUpdateErrorMessage()
        external view
        virtual override
        returns (string memory _errorMessage)
    {
        (uint _index, ) = _latestUpdateStatusIndex();
        return _getPriceFeed(_index).latestUpdateErrorMessage();
    }

    /// Returns status code of latest update request posted to the Witnet Request Board,
    /// from any of the referred currency pairs.
    /// @dev Status codes:
    /// @dev   - 200: update request was succesfully solved with no errors
    /// @dev   - 400: update request was solved with errors
    /// @dev   - 404: update request was not solved yet 
    function latestUpdateStatus()
        public view
        virtual override
        returns (uint256 _latestUpdateStatus)
    {
        (, _latestUpdateStatus) = _latestUpdateStatusIndex();
    }

    /// Returns `true` if any of the referred currency pairs awaits for an update.
    function pendingUpdate()
        public view
        virtual override
        returns (bool)
    {
        for (uint _i = 0; _i < pairs.length; _i ++) {
            if (_getPriceFeed(_i).pendingUpdate()) {
                return true;
            }
        }
        return false;
    }

    /// @dev This method will always revert on a WitnetPriceFeedRouted instance.
    function requestUpdate()
        external payable
        virtual override
    {
        revert("WitnetPriceFeedRouted: not supported");
    }

    /// Tells whether this contract implements the interface defined by `interfaceId`. 
    /// @dev See the corresponding https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
    /// @dev to learn more about how these ids are created.
    function supportsInterface(bytes4 _interfaceId)
        public view 
        virtual override
        returns (bool)
    {
        return (
            _interfaceId == type(IERC165).interfaceId
                || _interfaceId == type(IWitnetPriceFeed).interfaceId
                || _interfaceId == type(WitnetPriceFeedRouted).interfaceId
        );
    }

    // ========================================================================
    // --- INTERNAL METHODS ---------------------------------------------------

    /// @dev Asks immutable router to provide latest known address of the IWitnetPriceFeed contract
    /// @dev serving the currency pair that was provided at the 'index'-th position on construction.
    function _getPriceFeed(uint _index)
        internal view
        returns (IWitnetPriceFeed _pf)
    {
        _pf = IWitnetPriceFeed(address(router.getPriceFeed(pairs[_index])));
        require(
            address(_pf) != address(0),
            "WitnetPriceFeedRouted: deprecated currency pair"
        );
    }

    /// @dev Returns highest of all latest update status codes of the currency pairs that compose this price feed,
    /// @dev and index of the currency pair that currently states the highest value. In case of repetition, will
    /// @dev return the one with the lowest index.
    function _latestUpdateStatusIndex()
        internal view
        returns (uint _index, uint _latestUpdateStatus)
    {
        _latestUpdateStatus = 200;
        for (uint _i = 0; _i < pairs.length; _i ++) {
            uint _lus = _getPriceFeed(_i).latestUpdateStatus();
            if (_lus > _latestUpdateStatus) {
                _index = _i;
                _latestUpdateStatus = _lus;
                if (_lus == 404) {
                    break;
                }
            }
        }
    }

    /// @dev Derive price from given sources.
    /// @param _prices Array of last prices for each one of the currency pairs specified on constructor, 
    /// in the same order as they were specified.
    function _calculate(int256[] memory _prices) internal pure virtual returns (int256);
}
// File: contracts\routed\QuickUsdPriceFeed.sol
contract QuickUsdPriceFeed
    is
        WitnetPriceFeedRouted
{    
    constructor (IWitnetPriceRouter _witnetPriceRouter)
        WitnetPriceFeedRouted(_witnetPriceRouter)
    {
        require(router.supportsCurrencyPair(bytes4(0x0e62d8ae)), "QuickUsdPriceFeed: router supports no QUICK/USDC-6");
        require(router.supportsCurrencyPair(bytes4(0x4c80cf2e)), "QuickUsdPriceFeed: router supports no USDC/USD-6");
        pairs = new bytes32[](2);
        pairs[0] = 0x0e62d8ae815597a145b33afe529040e13547b66321679408b7af666a068ef83b;
        pairs[1] = 0x4c80cf2e5b3d17b98f6f24fc78f661982b8ef656c3b75a038f7bfc6f93c1b20e;
    }

    /// @dev Derive price from given sources.
    /// @param _prices Array of last prices for each one of the currency pairs specified on constructor, 
    /// in the same order as they were specified.
    function _calculate(int256[] memory _prices)
        internal pure
        override
        returns (int256)
    {
        return (_prices[0] * _prices[1]) / 10 ** 6;
    }
}