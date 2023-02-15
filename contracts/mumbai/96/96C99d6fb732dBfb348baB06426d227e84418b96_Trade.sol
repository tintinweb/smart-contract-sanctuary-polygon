// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
pragma solidity >=0.8.7 <0.9.0;

//-----------------------------------------------------------------------
// ITrade
//-----------------------------------------------------------------------
interface ITrade {
    //----------------------------------------
    // Events
    //----------------------------------------
    event MaxPriceModified(uint256 maxPrice);
    event MinPriceModified(uint256 minPrice);

    event MaxPeriodModified(uint256 maxPrice);
    event MinPeriodModified(uint256 minPrice);

    event OnlyNoLimitPeriodModified(bool);
    event AcceptNoLimiPeriodModified(bool);

    //----------------------------------------
    // Functions
    //----------------------------------------
    function maxPrice() external view returns (uint256);

    function minPrice() external view returns (uint256);

    function setMaxPrice(uint256 price) external;

    function setMinPrice(uint256 price) external;

    function maxPeriod() external view returns (uint256);

    function minPeriod() external view returns (uint256);

    function setMaxPeriod(uint256 period) external;

    function setMinPeriod(uint256 period) external;

    function onlyNoLimitPeriod() external view returns (bool);

    function acceptNoLimitPeriod() external view returns (bool);

    function setOnlyNoLimitPeriod(bool flag) external;

    function setAcceptNoLimitPeriod(bool flag) external;

    //----------------------------------------------
    // Token transfer information
    //----------------------------------------------
    // The breakdown of uint256 [4] is as follows
    // ・ [0]: Token contract (cast to ERC721 and use)
    // ・ [1]: Token ID
    // ・ [2]: Donor side (cast to address and use)
    // ・ [3]: Recipient (cast to address and use)
    //----------------------------------------------
    function transferInfo(
        uint256 tradeId
    ) external view returns (uint256[4] memory);

    // ----------------------------------------------
    // Get payment information
    // ----------------------------------------------
    // The breakdown of uint256 [2] is as follows
    // ・ [0]: Payment destination (cast to payable address)
    // ・ [1]: Contract address (cast to ERC721 and used)
    // ・ [2]: Payment amount
    // ----------------------------------------------
    function payInfo(uint256 tradeId) external view returns (uint256[3] memory);

    //----------------------------------------------
    // Get refund information
    // ----------------------------------------------
    // The breakdown of uint256 [2] is as follows
    // ・ [0]: Refund destination (cast to payable address)
    // ・ [1]: Refund amount
    //----------------------------------------------
    function refundInfo(
        uint256 tradeId
    ) external view returns (uint256[2] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./ITrade.sol";

//-----------------------------------------
// Trade
//-----------------------------------------
contract Trade is Ownable, ITrade {
    //-----------------------------------------
    // Setting
    //-----------------------------------------
    address private _market; // Implemented in Trade (not published to ITrade & no event required = no need to monitor on the server side)

    uint256 private _max_price;
    uint256 private _min_price;

    uint256 private _max_period;
    uint256 private _min_period;

    bool private _only_no_limit_period;
    bool private _accept_no_limit_period;

    //-----------------------------------------
    // [public] market
    //-----------------------------------------
    function market() public view returns (address) {
        return (_market);
    }

    //-----------------------------------------
    // [external/onlyOwner] Market setting
    //-----------------------------------------
    function setMarket(address contractAddress) external onlyOwner {
        _market = contractAddress;
    }

    //-----------------------------------------
    // [modifier] Can only be called from the market
    //-----------------------------------------
    modifier onlyMarket() {
        require(market() == _msgSender(), "caller is not the market");
        _;
    }

    //-----------------------------------------
    // Constructor
    //-----------------------------------------
    constructor() Ownable() {
        // Price limit
        _max_price = 1000000000000000000000000000; // 1,000,000,000.000000 MATIC
        _min_price = 1000000000000; //             0.000001 MATIC

        emit MaxPriceModified(_max_price);
        emit MinPriceModified(_min_price);

        // Time limit
        _max_period = 30 * 24 * 60 * 60; // 30 days
        _min_period = 1 * 24 * 60 * 60; // 1 day

        emit MaxPeriodModified(_max_period);
        emit MinPeriodModified(_min_period);

        // Indefinite setting
        _only_no_limit_period = false;
        _accept_no_limit_period = false;

        emit OnlyNoLimitPeriodModified(_only_no_limit_period);
        emit AcceptNoLimiPeriodModified(_accept_no_limit_period);
    }

    //-----------------------------------------
    // [external] Confirmation
    //-----------------------------------------
    function maxPrice() external view virtual override returns (uint256) {
        return (_max_price);
    }

    function minPrice() external view virtual override returns (uint256) {
        return (_min_price);
    }

    function maxPeriod() external view virtual override returns (uint256) {
        return (_max_period);
    }

    function minPeriod() external view virtual override returns (uint256) {
        return (_min_period);
    }

    function onlyNoLimitPeriod() external view virtual override returns (bool) {
        return (_only_no_limit_period);
    }

    function acceptNoLimitPeriod()
        external
        view
        virtual
        override
        returns (bool)
    {
        return (_accept_no_limit_period);
    }

    //-----------------------------------------
    // [external/onlyOwner] Setting
    //-----------------------------------------
    function setMaxPrice(uint256 price) external virtual override onlyOwner {
        _max_price = price;

        emit MaxPriceModified(price);
    }

    function setMinPrice(uint256 price) external virtual override onlyOwner {
        _min_price = price;

        emit MinPriceModified(price);
    }

    function setMaxPeriod(uint256 period) external virtual override onlyOwner {
        _max_period = period;

        emit MaxPeriodModified(period);
    }

    function setMinPeriod(uint256 period) external virtual override onlyOwner {
        _min_period = period;

        emit MinPeriodModified(period);
    }

    function setOnlyNoLimitPeriod(
        bool flag
    ) external virtual override onlyOwner {
        _only_no_limit_period = flag;

        emit OnlyNoLimitPeriodModified(flag);
    }

    function setAcceptNoLimitPeriod(
        bool flag
    ) external virtual override onlyOwner {
        _accept_no_limit_period = flag;

        emit AcceptNoLimiPeriodModified(flag);
    }

    //-----------------------------------------
    // [internal] Price effectiveness
    //-----------------------------------------
    function _checkPrice(uint256 price) internal view virtual returns (bool) {
        if (price > _max_price) {
            return (false);
        }

        if (price < _min_price) {
            return (false);
        }

        return (true);
    }

    //-----------------------------------------
    // [internal] Validity of period
    //-----------------------------------------
    function _checkPeriod(uint256 period) internal view virtual returns (bool) {
        // When accepting only unlimited
        if (_only_no_limit_period) {
            return (period == 0);
        }

        // When accepting unlimited
        if (_accept_no_limit_period) {
            if (period == 0) {
                return (true);
            }
        }

        if (period > _max_period) {
            return (false);
        }

        if (period < _min_period) {
            return (false);
        }

        return (true);
    }

    //-----------------------------------------
    // [external] Token transfer information
    //-----------------------------------------
    function transferInfo(
        uint256 /*tradeId*/
    ) external view virtual override returns (uint256[4] memory) {
        uint256[4] memory words;
        return (words);
    }

    //-----------------------------------------
    // [external] Get payment information
    //-----------------------------------------
    function payInfo(
        uint256 /*tradeId*/
    ) external view virtual override returns (uint256[3] memory) {
        uint256[3] memory words;
        return (words);
    }

    //-----------------------------------------
    // [external] Get refund information
    //-----------------------------------------
    function refundInfo(
        uint256 /*tradeId*/
    ) external view virtual override returns (uint256[2] memory) {
        uint256[2] memory words;
        return (words);
    }
}