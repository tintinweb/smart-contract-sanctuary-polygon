// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./BBErrorsV01.sol";
import "./interfaces/IBBProfiles.sol";
import "./interfaces/IBBTiers.sol";

contract BBTiers is IBBTiers {   
    event NewTierSet (
        uint256 profileId,
        uint256 tierSetId
    );

    event EditTierSet (
        uint256 profileId,
        uint256 tierSetId
    );

    event SupportedCurrencyAdded(
        uint256 profileId,
        uint256 tierSetId,
        address currency,
        uint256 priceMultiplier
    );

    event SupportedCurrencyRemoved(
        uint256 profileId,
        uint256 tierSetId,
        address currency
    );
    
    struct TierSet {
        uint256[] prices;
        string[] cids;
        bool[] deprecated;
        mapping(address => uint256) supportedCurrencies;
    }

    // Profile ID -> Tier set ID -> Tier ID
    mapping(uint256 => mapping(uint256 => TierSet)) internal _tierSets;
    // Profile Id -> Total tier sets
    mapping(uint256 => uint256) internal _totalTierSets;

    IBBProfiles internal immutable _bbProfiles;

    constructor(address bbProfiles) {
        _bbProfiles = IBBProfiles(bbProfiles);
    }

    /*
        @dev Reverts if msg.sender is not profile IDs owner

        @param Profile ID
    */
    modifier onlyProfileOwner(uint256 profileId) {
        (address profileOwner,,) = _bbProfiles.getProfile(profileId);
        require(profileOwner == msg.sender, BBErrorCodesV01.NOT_OWNER);
        _;
    }

    /*
        @dev Reverts if profile ID does not exist

        @param Profile ID
    */
    modifier profileExists(uint256 profileId) {
        require(profileId < _bbProfiles.totalProfiles(), BBErrorCodesV01.PROFILE_NOT_EXIST);
        _;
    }

    /*
        @dev Reverts if tier set ID does not exist

        @param Profile ID
        @param Tier set ID
    */
    modifier tierSetExists(uint256 profileId, uint256 tierSetId) {
        require(profileId < _bbProfiles.totalProfiles(), BBErrorCodesV01.PROFILE_NOT_EXIST);
        require(tierSetId < _totalTierSets[profileId], BBErrorCodesV01.TIER_SET_NOT_EXIST);
        _;
    }

    /*
        @dev Reverts if tier ID does not exist

        @param Profile ID
        @param Tier set ID
        @param Tier ID
    */
    modifier tierExists(uint256 profileId, uint256 tierSetId, uint256 tierId) {
        require(profileId < _bbProfiles.totalProfiles(), BBErrorCodesV01.PROFILE_NOT_EXIST);
        require(tierSetId < _totalTierSets[profileId], BBErrorCodesV01.TIER_SET_NOT_EXIST);
        require(tierId < _tierSets[profileId][tierSetId].prices.length, BBErrorCodesV01.TIER_NOT_EXIST);
        _;
    }

    /*
        @notice Creates a new tier set

        @param Profile ID
        @param Tier set prices
        @param Tier set CIDs
        @param Deprecated tiers 
        @param Supported ERC20 tokens
        @param Supported tokens multipliers

        @return Instantiated tier set ID
    */
    function createTiers(uint256 profileId, uint256[] calldata prices, string[] calldata cids, bool[] memory deprecated, address[] calldata supportedCurrencies, uint256[] calldata priceMultipliers) external profileExists(profileId) onlyProfileOwner(profileId) returns(uint256 tierSetId) {
        tierSetId = _totalTierSets[profileId];

        // Increment profiles total tier sets
        _totalTierSets[profileId]++;
        
        _setTiers(profileId, tierSetId, prices, cids, deprecated);
        _setSupportedCurrencies(profileId, tierSetId, supportedCurrencies, priceMultipliers);
    
        emit NewTierSet(profileId, tierSetId);
    }

    /*
        @notice Set an existing tier sets variables

        @param Profile ID
        @param Tier set ID
        @param Tier set prices
        @param Tier set CIDs
        @param Deprecated tiers 
    */
    function editTiers(uint256 profileId, uint256 tierSetId, uint256[] calldata prices, string[] calldata cids, bool[] memory deprecated) external override tierSetExists(profileId, tierSetId) onlyProfileOwner(profileId) {
        _setTiers(profileId, tierSetId, prices, cids, deprecated);
        
        emit EditTierSet(profileId, tierSetId);
    }

    /*
        @dev Perform input checks then set existing tier set variables

        @param Profile ID
        @param Tier set ID
        @param Tier set prices
        @param Tier set CIDs
        @param Deprecated tiers 
    */
    function _setTiers(uint256 profileId, uint256 tierSetId, uint256[] memory prices, string[] memory cids, bool[] memory deprecated) internal {
        require(prices.length == cids.length && prices.length == deprecated.length, BBErrorCodesV01.INVALID_LENGTH);

        // Check tier prices are greater than zero
        for(uint256 i; i < prices.length; i++) {
            require(prices[i] > 0, BBErrorCodesV01.INVALID_PRICE);
        }

        _tierSets[profileId][tierSetId].prices = prices;
        _tierSets[profileId][tierSetId].cids = cids;
        _tierSets[profileId][tierSetId].deprecated = deprecated;
    }

    /*
        @notice Set supported ERC20 tokens for payments, a price multiplier greater than zero adds support for a token, and a price multiplier of zero removes it

        @param Profile ID
        @param Tier set ID
        @param Supported ERC20 tokens
        @param Supported tokens multipliers
    */
    function setSupportedCurrencies(uint256 profileId, uint256 tierSetId, address[] calldata supportedCurrencies, uint256[] calldata priceMultipliers) external override tierSetExists(profileId, tierSetId) onlyProfileOwner(profileId) {
        _setSupportedCurrencies(profileId, tierSetId, supportedCurrencies, priceMultipliers);
    }

    /*
        @dev Set supported ERC20 tokens for payments

        @param Profile ID
        @param Tier set ID
        @param Supported ERC20 tokens
        @param Supported tokens multipliers
    */
    function _setSupportedCurrencies(uint256 profileId, uint256 tierSetId, address[] memory supportedCurrencies, uint256[] memory priceMultipliers) internal {
        require(supportedCurrencies.length == priceMultipliers.length, BBErrorCodesV01.INVALID_LENGTH);

        for(uint256 i; i < priceMultipliers.length; i++) {
            // Set price multiplier, if zero, token is no longer Supported
            _tierSets[profileId][tierSetId].supportedCurrencies[supportedCurrencies[i]] = priceMultipliers[i];
            
            if(priceMultipliers[i] == 0) {
                emit SupportedCurrencyRemoved(profileId, tierSetId, supportedCurrencies[i]);
                continue;
            }

            emit SupportedCurrencyAdded(profileId, tierSetId, supportedCurrencies[i], priceMultipliers[i]);
        }
    }

    /*
        @notice Returns a tier

        @param Profile ID
        @param Tier set ID
        @param Tier ID
        @param ERC20 token

        @return Tier CID
        @return Tier price
        @return Tier deprecated
    */
    function getTier(uint256 profileId, uint256 tierSetId, uint256 tierId, address currency) external view override tierExists(profileId, tierSetId, tierId) returns (string memory, uint256, bool) {
        // Require ERC20 token is supported by tier set
        require(_tierSets[profileId][tierSetId].supportedCurrencies[currency] > 0, BBErrorCodesV01.UNSUPPORTED_CURRENCY);
        return (_tierSets[profileId][tierSetId].cids[tierId], _tierPrice(_tierSets[profileId][tierSetId].prices[tierId], _tierSets[profileId][tierSetId].supportedCurrencies[currency]), _tierSets[profileId][tierSetId].deprecated[tierId]);
    }

    /*
        @dev Returns the price of a tier relative to a ERC20 token

        @param Tiers base price
        @param ERC20 token multiplier

        @return Tier price
    */
    function _tierPrice(uint256 price, uint256 multiplier) internal pure returns (uint256) {
        return price * multiplier;
    }

    /*
        @notice Get tier prices and CIDs in a tier set

        @param Profile ID
        @param Tier set ID

        @return Tier set base prices
        @return Tier set CIDs
        @return Deprecated tiers
    */
    function getTierSet(uint256 profileId, uint256 tierSetId) external view override tierSetExists(profileId, tierSetId) returns (uint256[] memory, string[] memory, bool[] memory) {
        return(_tierSets[profileId][tierSetId].prices, _tierSets[profileId][tierSetId].cids, _tierSets[profileId][tierSetId].deprecated);
    }
    
    /*
        @notice Gets the total number of tiers in a tier set

        @param Profile ID
        @param Tier set ID

        @return Total tiers in a tier set
    */
    function totalTiers(uint256 profileId, uint256 tierSetId) external view override tierSetExists(profileId, tierSetId) returns (uint256) {
        return _tierSets[profileId][tierSetId].prices.length;
    }

    /*
        @notice Gets the toal number of tier sets in a profile

        @param Profile ID
    
        @return Total tier sets in a profile
    */
    function totalTierSets(uint256 profileId) external view override profileExists(profileId) returns (uint256) {
        return _totalTierSets[profileId];
    }
    
    /*
        @notice Get a ERC20 tokens price multiplier within a tier set 

        @param Profile ID
        @param Tier set ID
        @param ERC20 token

        @return Supported ERC20 token multiplier
    */
    function getCurrencyMultiplier(uint256 profileId, uint256 tierSetId, address currency) external view override tierSetExists(profileId, tierSetId) returns (uint256) {
        // Reverts if ERC20 token is not supported
        require(_tierSets[profileId][tierSetId].supportedCurrencies[currency] > 0, BBErrorCodesV01.UNSUPPORTED_CURRENCY);
        return _tierSets[profileId][tierSetId].supportedCurrencies[currency];
    }

    /*
        @notice Check if a ERC20 token is supported for payments within a tier set

        @param Profile ID
        @param Tier set ID
        @param ERC20 token

        @return True if an ERC20 token is supported for payments within a tier set, otherwise false
    */
    function isCurrencySupported(uint256 profileId, uint256 tierSetId, address currency) external view override tierSetExists(profileId, tierSetId) returns (bool) {
        return _tierSets[profileId][tierSetId].supportedCurrencies[currency] > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBBTiers {
    function createTiers(uint256 profileId, uint256[] calldata prices, string[] calldata cids, bool[] memory deprecated, address[] calldata supportedCurrencies, uint256[] calldata priceMultipliers) external returns(uint256 tierSetId);
    function editTiers(uint256 profileId, uint256 tierSetId, uint256[] calldata prices, string[] calldata cids, bool[] memory deprecated) external;
    function setSupportedCurrencies(uint256 profileId, uint256 tierSetId, address[] calldata supportedCurrencies, uint256[] calldata priceMultipliers) external;

    function getTier(uint256 profileId, uint256 tierSetId, uint256 tierId, address currency) external view returns (string memory, uint256, bool);
    function getTierSet(uint256 profileId, uint256 tierSetId) external view returns (uint256[] memory prices, string[] memory cids, bool[] memory deprecated);

    function totalTiers(uint256 profileId, uint256 tierSetId) external view returns (uint256 total);
    function totalTierSets(uint256 profileId) external view returns (uint256 total);

    function getCurrencyMultiplier(uint256 profileId, uint256 tierSetId, address currency) external view returns (uint256 multiplier);
    function isCurrencySupported(uint256 profileId, uint256 tierSetId, address currency) external view returns (bool supported);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBBProfiles {
    function createProfile(address owner, address receiver, string calldata cid) external returns(uint256 profileId);
    function editProfile(uint256 profileId, address owner, address receiver, string calldata cid) external; 

    function totalProfiles() external view returns (uint256 total);
    function getProfile(uint256 profileId) external view returns (address owner, address receiver, string memory cid);

    function getOwnersProfiles(address account) external view returns (uint256[] memory profileIds);
    function ownersTotalProfiles(address owner) external view returns (uint256 total);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library BBErrorCodesV01 {
    string public constant NOT_OWNER = "1";
    string public constant OUT_OF_BOUNDS = "2";
    string public constant NOT_SUBSCRIPTION_OWNER = "3";
    string public constant POST_NOT_EXIST = "4";
    string public constant PROFILE_NOT_EXIST = "5";
    string public constant TIER_SET_NOT_EXIST = "6";
    string public constant TIER_NOT_EXIST = "7";
    string public constant SUBSCRIPTION_NOT_EXIST = "8";
    string public constant ZERO_ADDRESS = "9";
    string public constant SUBSCRIPTION_NOT_EXPIRED = "10";
    string public constant SUBSCRIPTION_CANCELLED = "11";
    string public constant UPKEEP_FAIL = "12";
    string public constant INSUFFICIENT_PREPAID_GAS = "13";
    string public constant INSUFFICIENT_ALLOWANCE = "14";
    string public constant INSUFFICIENT_BALANCE = "15";
    string public constant SUBSCRIPTION_ACTIVE = "16";
    string public constant INVALID_LENGTH = "17";
    string public constant UNSUPPORTED_CURRENCY = "18";
    string public constant SUBSCRIPTION_PROFILE_ALREADY_EXISTS = "19";
    string public constant INVALID_PRICE = "20";
}