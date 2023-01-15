/**
 *Submitted for verification at polygonscan.com on 2023-01-15
*/

// Sources flattened with hardhat v2.12.6 https://hardhat.org

// File contracts/interfaces/IBBPosts.sol

pragma solidity ^0.8.0;

interface IBBPosts {
    function createPost(uint256 profileId, string calldata cid) external returns(uint256 postId);
    function editPost(uint256 profileId, uint256 postId, string calldata cid) external;
    
    function getPost(uint256 profileId, uint256 postId) external view returns (string memory cid);
    function profilesTotalPosts(uint256 profileId) external view returns (uint256 total);
}


// File contracts/interfaces/IBBProfiles.sol

pragma solidity ^0.8.0;

interface IBBProfiles {
    function createProfile(address owner, address receiver, string calldata cid) external returns(uint256 profileId);
    function editProfile(uint256 profileId, address owner, address receiver, string calldata cid) external; 

    function totalProfiles() external view returns (uint256 total);
    function getProfile(uint256 profileId) external view returns (address owner, address receiver, string memory cid);

    function getOwnersProfiles(address account) external view returns (uint256[] memory profileIds);
    function ownersTotalProfiles(address owner) external view returns (uint256 total);
}


// File contracts/interfaces/IBBSubscriptionsFactory.sol

pragma solidity ^0.8.0;

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


// File contracts/interfaces/IBBTiers.sol

pragma solidity ^0.8.0;

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


// File contracts/ReadHelper.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract ReadHelper {

    IBBSubscriptionsFactory subFactory = IBBSubscriptionsFactory(0x5D2A904E7374cc3FaA5658Ecd462e370aA4637a6);
    IBBProfiles profiles = IBBProfiles(0x096741579bAC68b4044Bbb4966D390E51081c7dC);
    IBBTiers tiers = IBBTiers(0xfFec1c5B14808D56a894916A52da300d8eE77941);
    IBBPosts posts = IBBPosts(0x35bb26163E8Ec8542863D270fd92927F562Af1C6);

    function getActiveSubscriptions(address addr) public view returns (bool[] memory) {

        uint256 totalProfiles = profiles.totalProfiles();
        bool[] memory active = new bool[](totalProfiles);

        for (uint256 i = 0; i < totalProfiles; i++) {
            if (!subFactory.isSubscriptionProfileCreated(i)) { active[i] = false; continue; }

            (uint256 tierSetId, ) = subFactory.getSubscriptionProfile(i);
            uint256 tierCount = tiers.totalTiers(i, tierSetId);

            for (uint256 j = 0; j < tierCount; j++) {
                if (subFactory.isSubscriptionActive(i, j, addr)) { 
                    active[i] = true;
                    break;
                }
            }
        }

        return active;
    }

    function getProfiles(uint256[] memory profileList) public view returns (address[] memory, address[] memory, string[] memory) {
        address[] memory owners = new address[](profileList.length);
        address[] memory receivers = new address[](profileList.length);
        string[] memory cids = new string[](profileList.length);

        for (uint256 i = 0; i < profileList.length; i++) {
            (address _o, address _r, string memory _c) = profiles.getProfile(i);
            owners[i] = _o;
            receivers[i] = _r;
            cids[i] = _c;
        }

        return (owners, receivers, cids);
    }

    function getProfilePosts(uint256 profile) public view returns (string[] memory) {
        
        uint256 postCount = posts.profilesTotalPosts(profile);
        string[] memory postCids = new string[](postCount);

        for (uint256 i = 0; i < postCount; i++) {
            postCids[i] = posts.getPost(profile, i);
        }

        return postCids;
    }
    
}