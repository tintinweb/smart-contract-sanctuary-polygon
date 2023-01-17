// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@backedby/v1-contracts/contracts/interfaces/IBBProfiles.sol";
import "@backedby/v1-contracts/contracts/interfaces/IBBTiers.sol";
import "@backedby/v1-contracts/contracts/interfaces/IBBSubscriptionsFactory.sol";

contract ProfileSetup {
    IBBProfiles public immutable BBProfiles;
    IBBTiers public immutable BBTiers;
    IBBSubscriptionsFactory public immutable BBSubscriptionsFactory;

    constructor(address profiles, address tiers, address subscriptionsFactory) {
        BBProfiles = IBBProfiles(profiles);
        BBTiers = IBBTiers(tiers);
        BBSubscriptionsFactory = IBBSubscriptionsFactory(subscriptionsFactory);
    }

    function setup(
        address owner, 
        address receiver, 
        string memory profileCid, 
        uint256[] memory tierPrices, 
        string[] memory tierCids, 
        bool[] memory tierDeprecations, 
        address[] memory tierCurrencies, 
        uint256[] memory tierMultipliers, 
        uint256 subscriptionContribution
    ) external {
        uint256 profileId = BBProfiles.createProfile(address(this), address(this), "");
        uint256 tierSetId = BBTiers.createTiers(profileId, tierPrices, tierCids, tierDeprecations, tierCurrencies, tierMultipliers);    
        BBSubscriptionsFactory.createSubscriptionProfile(profileId, tierSetId, subscriptionContribution);
        BBProfiles.editProfile(profileId, owner, receiver, profileCid);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBBSubscriptionsFactory {
    function deploySubscriptions(address currency) external returns(address subscriptions);
    function isSubscriptionsDeployed(address currency) external view returns (bool deployed);
    function getDeployedSubscriptions(address currency) external view returns (address subscriptions);

    function setTreasuryOwner(address account) external;
    function setGasOracleOwner(address account) external;
    function setSubscriptionFeeOwner(address account) external;

    function getTreasuryOwner() external view returns (address treasury);
    function getGasOracleOwner() external view returns (address gasPriceOwner);
    function getSubscriptionFeeOwner() external view returns (address subscriptionFeeOwner);

    function setTreasury(address account) external;
    function setGasOracle(address account) external;
    function setSubscriptionFee(address currency, uint256 amount) external;

    function getTreasury() external view returns (address treasury);
    function getGasOracle() external view returns (address oracle);
    function getSubscriptionFee(address currency) external view returns (uint256 fee);

    function getGracePeriod() external pure returns (uint256 gracePeriod);
    function getContributionBounds() external pure returns (uint256 lower, uint256 upper);

    function setSubscriptionCurrency(uint256 profileId, uint256 tierId, address account, address currency) external;
    function getSubscriptionCurrency(uint256 profileId, uint256 tierId, address account) external view returns (address currency);

    function createSubscriptionProfile(uint256 profileId, uint256 tierSetId, uint256 contribution) external;
    function setContribution(uint256 profileId, uint256 contribution) external;

    function getSubscriptionProfile(uint256 profileId) external view returns (uint256 tierSetId, uint256 contribution);
    function isSubscriptionProfileCreated(uint256 profileId) external view returns (bool created);

    function isSubscriptionActive(uint256 profileId, uint256 tierId, address account) external view returns (bool active);
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