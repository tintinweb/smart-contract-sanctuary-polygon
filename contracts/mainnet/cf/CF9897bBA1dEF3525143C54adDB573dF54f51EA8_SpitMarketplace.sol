// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./EnumerableSet.sol";
import "./SpitToken.sol";

struct Reward {
    bool active;
    uint price;
    uint marketplaceId;

    uint128 totalSpots;
    uint128 availableSpots;

    string name;
    string description;
    string externalUrl;
}

library IterableMapping {

    struct RewardMap {
        uint[] ids;
        mapping(uint => Reward) values;
        mapping(uint => uint) indexOf;
        mapping(uint => bool) inserted;
    }

    function get(RewardMap storage map, uint key) public view returns (Reward memory) {
        return map.values[key];
    }

    function getKeyAtIndex(RewardMap storage map, uint index) public view returns (uint) {
        return map.ids[index];
    }

    function size(RewardMap storage map) public view returns (uint) {
        return map.ids.length;
    }

    function decrementAvailableSpots(RewardMap storage map, uint key) public {
        map.values[key].availableSpots--;
    }

    function activeSize(RewardMap storage map) public view returns (uint) {
        uint activeCounter = 0;
        for (uint256 i = 0; i < map.ids.length; i++) {
           if(map.values[map.ids[i]].active) activeCounter++; 
        }
        return activeCounter;
    }

    function set(
        RewardMap storage map,
        uint key,
        Reward memory val
    ) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.ids.length;
            map.ids.push(key);
        }
    }

    function remove(RewardMap storage map, uint key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.ids.length - 1;
        uint lastKey = map.ids[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.ids[index] = lastKey;
        map.ids.pop();
    }
}

error AlreadyInitialized();
error ExceedsTotalSupply();
error NotAuthorized();
error SoldOut();
error RewardInactive();
error AlreadyPurchased();

contract SpitMarketplace is Ownable {
    using IterableMapping for IterableMapping.RewardMap;
    using EnumerableSet for EnumerableSet.UintSet;

    SpitToken public spit;

    event UtilityPurchase(
        address indexed user,
        uint indexed rewardId
    );

    IterableMapping.RewardMap private rewardMap;
    mapping(address => EnumerableSet.UintSet) private userPurchases;
    mapping(uint => address[]) public rewardPurchases;

    mapping(address => mapping(bytes4 => bool)) private permissions;

    constructor(address _spit) {
        spit = SpitToken(_spit);
    }

    modifier authorized {
        if(msg.sender != _owner && !permissions[msg.sender][msg.sig]) revert NotAuthorized();
        _;
    }

    function setPermission(address user, bytes4 sig, bool allowed) public authorized {
        permissions[user][sig] = allowed;
    }
    
    function setPermissions(address user, bytes4[] calldata signatures, bool allowed) public authorized {
        for (uint256 i = 0; i < signatures.length; i++) {
            setPermission(user, signatures[i], allowed);
        }
    }

    function addReward(Reward memory reward) public authorized {
        uint id = uint(keccak256(abi.encodePacked(reward.name)));
        if(rewardMap.get(id).price != 0) revert AlreadyInitialized();
        rewardMap.set(id, reward);
    }

    function editReward(string memory oldName, Reward memory reward) public authorized {
        uint oldId = uint(keccak256(abi.encodePacked(oldName)));
        uint id = uint(keccak256(abi.encodePacked(reward.name)));
        if(oldId == id) {
            rewardMap.set(id, reward);
        } else {
            deleteReward(oldName);
            addReward(reward);
        }
    }

    /// @dev This function doesn't allow exceeding the totalCount of the reward, it allows for adding supply in time steps instead of all at once.
    function restock(string memory name, uint128 count) public authorized {
        uint id = uint(keccak256(abi.encodePacked(name)));
        Reward memory reward = rewardMap.get(id);
        if(rewardPurchases[id].length + reward.availableSpots + count > reward.totalSpots) revert ExceedsTotalSupply();
        reward.availableSpots += count;
        rewardMap.set(id, reward);
    }

    function deleteReward(string memory name) public authorized {
        rewardMap.remove(uint(keccak256(abi.encodePacked(name))));
    }

    function getPurchasers(uint id) public view authorized returns (address[] memory) {
        return rewardPurchases[id];
    }

    function getRewards(bool onlyActive) public view returns (Reward[] memory) {
        uint rewardCount = rewardMap.size();
        Reward[] memory rewards = new Reward[](onlyActive ? rewardMap.activeSize() : rewardCount);

        uint j = 0;
        for (uint256 i = 0; i < rewardCount; i++) { 
           Reward memory reward = rewardMap.get(rewardMap.getKeyAtIndex(i)); 
           if(!onlyActive || onlyActive && reward.active) {
               rewards[j] = reward;
               j++;
           }
        }

        return rewards;
    }

    function getReward(uint id) public view returns (Reward memory) {
        return rewardMap.get(id);
    }

    function getReward(string memory name) public view returns (Reward memory) {
        return rewardMap.get(uint(keccak256(abi.encodePacked(name))));
    }

    function buyReward(uint id, address user, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
        Reward memory reward = rewardMap.get(id);
        if(!reward.active) revert RewardInactive();
        if(reward.availableSpots == 0) revert SoldOut();
        if(userPurchases[user].contains(id)) revert AlreadyPurchased();
        if(!canPurchase(id, user)) revert NotAuthorized();

        rewardMap.decrementAvailableSpots(id);
        rewardPurchases[id].push(user);
        userPurchases[user].add(id);

        spit.purchaseUtility(user, reward.price, deadline, v, r, s);
    }

    function canPurchase(uint id, address user) internal view returns (bool) {
        uint marketplaceId = rewardMap.get(id).marketplaceId;
        if(marketplaceId == 0) {
            return true;
        } else if(marketplaceId == 1) {
            return spit.balances(user, 0) > 0;
        } else if(marketplaceId == 2) {
            return spit.balances(user, 1) > 0;
        } else if(marketplaceId == 3) {
            return spit.balances(user, 0) > 0 || spit.balances(user, 1) > 0;
        }
        return false;
    }
    
    function getUserPurchases() public view returns (uint[] memory) {
        return userPurchases[msg.sender].values();
    }
}