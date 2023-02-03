// 2a8eaf68ac21df3941127c669e34999f03871082
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "AclPriceFeedAggregatorBASE.sol";



contract AclPriceFeedAggregatorPolygon is AclPriceFeedAggregatorBASE {
    
    address public constant MATIC = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    constructor() {
        tokenMap[MATIC] = WMATIC;   //nativeToken to wrappedToken
        tokenMap[address(0)] = WMATIC;

        priceFeedAggregator[address(0)] = 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0;
        priceFeedAggregator[MATIC] = 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0;// MATIC
        priceFeedAggregator[0x0000000000000000000000000000000000001010] = 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0;// MATIC
        priceFeedAggregator[WMATIC] = 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0;// WMATIC
        priceFeedAggregator[0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619] = 0xF9680D99D6C9589e2a93a78A04A279e509205945;// WETH
        priceFeedAggregator[0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6] = 0xDE31F8bFBD8c84b5360CFACCa3539B938dd78ae6;// WBTC
        priceFeedAggregator[0xb33EaAd8d922B1083446DC23f610c2567fB5180f] = 0xdf0Fb4e4F928d2dCB76f438575fDD8682386e13C;// UNI
        priceFeedAggregator[0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39] = 0xd9FFdb71EbE7496cC440152d43986Aae0AB76665;// LINK
        priceFeedAggregator[0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174] = 0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7;// USDC
        priceFeedAggregator[0xc2132D05D31c914a87C6611C10748AEb04B58e8F] = 0x0A6513e40db6EB1b165753AD52E80663aeA50545;// USDT
        priceFeedAggregator[0x45c32fA6DF82ead1e2EF74d17b76547EDdFaFF89] = 0x00DBeB1e45485d53DF7C2F0dF1Aa0b6Dc30311d3;// FRAX
        priceFeedAggregator[0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063] = 0x4746DeC9e833A82EC7C2C1356372CcF2cfcD2F3D;// DAI
        priceFeedAggregator[0x172370d5Cd63279eFa6d502DAB29171933a610AF] = 0x336584C8E6Dc19637A5b36206B1c79923111b405;// CRV
        priceFeedAggregator[0xC3C7d422809852031b44ab29EEC9F1EfF2A58756] = address(0);// LDO
        priceFeedAggregator[0x2F6F07CDcf3588944Bf4C42aC74ff24bF56e7590] = address(0);// STG
        priceFeedAggregator[0xE5417Af564e4bFDA1c483642db72007871397896] = address(0);// GNS
        priceFeedAggregator[0xa3Fa99A148fA48D14Ed51d610c367C61876997F1] = address(0);// MAI
        priceFeedAggregator[0x3A58a54C066FdC0f2D55FC9C89F0415C92eBf3C4] = 0x97371dF4492605486e23Da797fA68e55Fc38a13f;// stMATIC        
    }
}

// 2a8eaf68ac21df3941127c669e34999f03871082
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "Ownable.sol";

interface AggregatorV3Interface {
    function latestRoundData() external view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function decimals() external view returns (uint8);
}

interface IERC20 {
    function decimals() external view returns (uint8);
}


contract AclPriceFeedAggregatorBASE is TransferOwnable{
    
    uint256 public constant DECIMALS_BASE = 18;
    mapping(address => address) public priceFeedAggregator;
    mapping(address => address) public tokenMap;

    struct PriceFeedAggregator {
        address token; 
        address priceFeed; 
    }

    event PriceFeedUpdated(address indexed token, address indexed priceFeed);
    event TokenMap(address indexed nativeToken, address indexed wrappedToken);

    function getUSDPrice(address _token) public view returns (uint256,uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAggregator[_token]);
        require(address(priceFeed) != address(0), "priceFeed not found");
        (uint80 roundId, int256 price, , uint256 updatedAt, uint80 answeredInRound) = priceFeed.latestRoundData();
        require(price > 0, "Chainlink: price <= 0");
        require(answeredInRound >= roundId, "Chainlink: answeredInRound <= roundId");
        require(updatedAt > 0, "Chainlink: updatedAt <= 0");
        return (uint256(price) , uint256(priceFeed.decimals()));
    }

    function getUSDValue(address _token , uint256 _amount) public view returns (uint256) {
        if (tokenMap[_token] != address(0)) {
            _token = tokenMap[_token];
        } 
        (uint256 price, uint256 priceFeedDecimals) = getUSDPrice(_token);
        uint256 usdValue = (_amount * uint256(price) * (10 ** DECIMALS_BASE)) / ((10 ** IERC20(_token).decimals()) * (10 ** priceFeedDecimals));
        return usdValue;
    }

    function setPriceFeed(address _token, address _priceFeed) public onlyOwner {    
        require(_priceFeed != address(0), "_priceFeed not allowed");
        require(priceFeedAggregator[_token] != _priceFeed, "_token _priceFeed existed");
        priceFeedAggregator[_token] = _priceFeed;
        emit PriceFeedUpdated(_token,_priceFeed);
    }

    function setPriceFeeds(PriceFeedAggregator[] calldata _priceFeedAggregator) public onlyOwner {    
        for (uint i=0; i < _priceFeedAggregator.length; i++) { 
            priceFeedAggregator[_priceFeedAggregator[i].token] = _priceFeedAggregator[i].priceFeed;
        }
    }

    function setTokenMap(address _nativeToken, address _wrappedToken) public onlyOwner {    
        require(_wrappedToken != address(0), "_wrappedToken not allowed");
        require(tokenMap[_nativeToken] != _wrappedToken, "_nativeToken _wrappedToken existed");
        tokenMap[_nativeToken] = _wrappedToken;
        emit TokenMap(_nativeToken,_wrappedToken);
    }


    fallback() external {
        revert("Unauthorized access");
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "Context.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function _transferOwnership(address newOwner) internal virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract TransferOwnable is Ownable {
    function transferOwnership(address newOwner) public virtual onlyOwner {
        _transferOwnership(newOwner);
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