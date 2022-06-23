// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interface/ICOW721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../interface/IPlanet.sol";
import "../interface/ICattle1155.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interface/ITec.sol";
import "../interface/Ibadge.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";

contract MilkFactory is OwnableUpgradeable, ERC721HolderUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    ICOW public cattle;
    IStable public stable;
    IPlanet public planet;
    IERC20Upgradeable public BVT;
    ICattle1155 public cattleItem;
    uint public daliyOut;
    uint public rate;
    uint public totalPower;
    uint public debt;
    uint public lastTime;
    uint public cowsAmount;
    uint public timePerEnergy;
    uint constant acc = 1e10;
    uint public technologyId;


    struct UserInfo {
        uint totalPower;
        uint[] cattleList;
        uint cliamed;
    }

    struct StakeInfo {
        bool status;
        uint milkPower;
        uint tokenId;
        uint endTime;
        uint starrtTime;
        uint claimTime;
        uint debt;

    }

    mapping(address => UserInfo) public userInfo;
    mapping(uint => StakeInfo) public stakeInfo;

    uint public totalClaimed;
    ITec public tec;
    IBadge public badge;

    struct UserBadge {
        uint tokenID;
        uint badgeID;
        uint power;
    }

    mapping(address => UserBadge) public userBadge;
    uint randomSeed;
    mapping(uint => uint) public compoundRate;
    mapping(uint => uint) public compoundRew;

    event ClaimMilk(address indexed player, uint indexed amount);
    event RenewTime(address indexed player, uint indexed tokenId, uint indexed newEndTIme);
    event Stake(address indexed player, uint indexed tokenId);
    event UnStake(address indexed player, uint indexed tokenId);
    event Reward(address indexed player, uint indexed reward,uint indexed amount);

    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();

        daliyOut = 100000e18;
        rate = daliyOut / 86400;
        timePerEnergy = 60;
        technologyId = 1;
        compoundRate[40001] = 500;
        compoundRate[40002] = 300;
        compoundRate[40003] = 100;
        compoundRew[40001] = 2;
        compoundRew[40002] = 6;
        compoundRew[40003] = 18;
    }

    function rand(uint256 _length) internal returns (uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, randomSeed)));
        randomSeed ++;
        return random % _length + 1;
    }

    function setCattle(address cattle_) external onlyOwner {
        cattle = ICOW(cattle_);
    }

    function setTec(address addr) external onlyOwner {
        tec = ITec(addr);
    }

    function setBadge(address addr) external onlyOwner {
        badge = IBadge(addr);
    }

    function setItem(address item_) external onlyOwner {
        cattleItem = ICattle1155(item_);
    }

    function setStable(address stable_) external onlyOwner {
        stable = IStable(stable_);
    }

    function setDaily(uint amount )external onlyOwner{
        daliyOut = amount;
        rate = daliyOut / 86400;
    }

    function setPlanet(address planet_) external onlyOwner {
        planet = IPlanet(planet_);
    }

    function setBVT(address BVT_) external onlyOwner {
        BVT = IERC20Upgradeable(BVT_);
    }

    function checkUserStakeList(address addr_) public view returns (uint[] memory){
        return userInfo[addr_].cattleList;
    }

    function coutingDebt() public view returns (uint _debt){
        _debt = totalPower > 0 ? rate * (block.timestamp - lastTime) * acc / totalPower + debt : 0 + debt;
    }

    function coutingPower(address addr_, uint tokenId) public view returns (uint){
        uint milk = cattle.getMilk(tokenId) * tec.checkUserTecEffet(addr_, 1001) / 100;
        uint milkRate = cattle.getMilkRate(tokenId) * tec.checkUserTecEffet(addr_, 1002) / 100;
        uint power_ = (milkRate + milk) / 2;
        uint level = stable.getStableLevel(addr_);
        uint rates = stable.rewardRate(level);
        uint finalPower = power_ * rates / 100;
        return finalPower;
    }

    function caculeteCow(uint tokenId) public view returns (uint){
        StakeInfo storage info = stakeInfo[tokenId];
        if (!info.status) {
            return 0;
        }

        uint rew;
        uint tempDebt;
        if (info.claimTime < info.endTime && info.endTime < block.timestamp) {
            tempDebt = rate * (info.endTime - info.claimTime) * acc / totalPower;
            rew = info.milkPower * tempDebt / acc;
        } else {
            tempDebt = coutingDebt();
            rew = info.milkPower * (tempDebt - info.debt) / acc;
        }


        return rew;
    }

    function caculeteAllCow(address addr_) public view returns (uint){
        uint[] memory list = checkUserStakeList(addr_);
        uint rew;
        for (uint i = 0; i < list.length; i++) {
            rew += caculeteCow(list[i]);
        }
        if (userBadge[addr_].tokenID != 0) {
            uint id = uint256(keccak256(abi.encodePacked(msg.sender, userBadge[addr_].tokenID)));
            rew += caculeteCow(id);
        }
        return rew;
    }

    function userItem(uint tokenId, uint itemId, uint amount) public {
        require(stakeInfo[tokenId].status, 'not staking');
        require(stable.CattleOwner(tokenId) == msg.sender, "not cattle's owner");
        uint[3]memory effect = cattleItem.checkItemEffect(itemId);
        require(effect[0] > 0, 'wrong item');
        uint energyLimit = cattle.getEnergy(tokenId);
        uint value;
        if (amount * effect[0] >= energyLimit) {
            value = energyLimit;
        } else {
            value = amount * effect[0];
        }
        stakeInfo[tokenId].endTime += value * timePerEnergy;
        stable.addStableExp(msg.sender, cattleItem.itemExp(itemId) * amount);
        cattleItem.burn(msg.sender, itemId, amount);
        emit RenewTime(msg.sender, tokenId, stakeInfo[tokenId].endTime);
    }


    function claimAllMilk() public {
        uint[] memory list = checkUserStakeList(msg.sender);
        uint rew;
        for (uint i = 0; i < list.length; i++) {
            rew += caculeteCow(list[i]);
            if (block.timestamp >= stakeInfo[list[i]].endTime) {
                debt = coutingDebt();
                totalPower -= stakeInfo[list[i]].milkPower;
                userInfo[msg.sender].totalPower -=stakeInfo[list[i]].milkPower;
                lastTime = block.timestamp;
                delete stakeInfo[list[i]];
                stable.changeUsing(list[i], false);
                cowsAmount --;
                for (uint k = 0; k < userInfo[msg.sender].cattleList.length; k ++) {
                    if (userInfo[msg.sender].cattleList[k] == list[i]) {
                        userInfo[msg.sender].cattleList[k] = userInfo[msg.sender].cattleList[userInfo[msg.sender].cattleList.length - 1];
                        userInfo[msg.sender].cattleList.pop();
                    }
                }
            } else {
                stakeInfo[list[i]].claimTime = block.timestamp;
                stakeInfo[list[i]].debt = coutingDebt();
            }
        }
        if (userBadge[msg.sender].tokenID != 0) {
            uint id = uint256(keccak256(abi.encodePacked(msg.sender, userBadge[msg.sender].tokenID)));
            rew += caculeteCow(id);
        }
        uint tax = planet.findTax(msg.sender);
        uint taxAmuont = rew * tax / 100;
        totalClaimed += rew;
        planet.addTaxAmount(msg.sender, taxAmuont);
        BVT.transfer(msg.sender, rew - taxAmuont);
        BVT.transfer(address(planet), taxAmuont);
        userInfo[msg.sender].cliamed += rew - taxAmuont;
        emit ClaimMilk(msg.sender, rew);
    }

    function removeList(address addr, uint index) public onlyOwner {
        uint length = userInfo[addr].cattleList.length;
        userInfo[addr].cattleList[index] = userInfo[addr].cattleList[length - 1];
        userInfo[addr].cattleList.pop();
    }

    function coutingEnergyCost(address addr, uint amount) public view returns (uint){
        uint rates = 100 - tec.checkUserTecEffet(addr, 1003);
        return (amount * rates / 100);
    }


    function stake(uint tokenId, uint energyCost) public {
        require(!stable.isUsing(tokenId), 'the cattle is using');
        require(stable.isStable(tokenId), 'not in the stable');
        require(stable.CattleOwner(tokenId) == msg.sender, "not cattle's owner");
        require(cattle.getAdult(tokenId), 'must bu adult');
        stable.changeUsing(tokenId, true);
        uint tempDebt = coutingDebt();
        if (userInfo[msg.sender].cattleList.length == 0 && userBadge[msg.sender].tokenID != 0) {
            debt = tempDebt;
            totalPower += userBadge[msg.sender].power;
            lastTime = block.timestamp;
            userInfo[msg.sender].totalPower += userBadge[msg.sender].power;
            uint id = uint256(keccak256(abi.encodePacked(msg.sender, userBadge[msg.sender].tokenID)));
            stakeInfo[id] = StakeInfo({
            status : true,
            milkPower : userBadge[msg.sender].power,
            tokenId : id,
            endTime : block.timestamp + 86400000,
            starrtTime : block.timestamp,
            claimTime : block.timestamp,
            debt : tempDebt
            });
        }
        userInfo[msg.sender].cattleList.push(tokenId);
        uint power = coutingPower(msg.sender, tokenId);
        require(power > 0, 'only cow can stake');
        totalPower += power;
        lastTime = block.timestamp;
        debt = tempDebt;
        userInfo[msg.sender].totalPower += power;
        stakeInfo[tokenId] = StakeInfo({
        status : true,
        milkPower : power,
        tokenId : tokenId,
        endTime : findEndTime(tokenId, energyCost),
        starrtTime : block.timestamp,
        claimTime : block.timestamp,
        debt : tempDebt
        });
        stable.costEnergy(tokenId, coutingEnergyCost(msg.sender, energyCost));
        cowsAmount ++;
        emit Stake(msg.sender, tokenId);
    }

    function unStake(uint tokenId) public {
        require(stakeInfo[tokenId].status, 'not staking');
        require(stable.CattleOwner(tokenId) == msg.sender, "not cattle's owner");
        uint rew = caculeteCow(tokenId);
        uint tempDebt = coutingDebt();
        if (rew != 0) {
            uint tax = planet.findTax(msg.sender);
            uint taxAmuont = rew * tax / 100;
            planet.addTaxAmount(msg.sender, taxAmuont);
            BVT.transfer(msg.sender, rew - taxAmuont);
            BVT.transfer(address(planet), taxAmuont);
            userInfo[msg.sender].cliamed += rew - taxAmuont;
            totalClaimed += rew;
        }
        debt = tempDebt;
        totalPower -= stakeInfo[tokenId].milkPower;
        userInfo[msg.sender].totalPower -= stakeInfo[tokenId].milkPower;
        lastTime = block.timestamp;
        delete stakeInfo[tokenId];
        stable.changeUsing(tokenId, false);
        for (uint i = 0; i < userInfo[msg.sender].cattleList.length; i ++) {
            if (userInfo[msg.sender].cattleList[i] == tokenId) {
                userInfo[msg.sender].cattleList[i] = userInfo[msg.sender].cattleList[userInfo[msg.sender].cattleList.length - 1];
                userInfo[msg.sender].cattleList.pop();
            }
        }
        if (userInfo[msg.sender].cattleList.length == 0 && userBadge[msg.sender].tokenID != 0) {
            uint id = uint256(keccak256(abi.encodePacked(msg.sender, userBadge[msg.sender].tokenID)));
            rew = caculeteCow(id);
            if (rew != 0) {
                uint tax = planet.findTax(msg.sender);
                uint taxAmuont = rew * tax / 100;
                planet.addTaxAmount(msg.sender, taxAmuont);
                BVT.transfer(msg.sender, rew - taxAmuont);
                BVT.transfer(address(planet), taxAmuont);
                userInfo[msg.sender].cliamed += rew - taxAmuont;
                totalClaimed += rew;
            }
            userInfo[msg.sender].totalPower -= stakeInfo[id].milkPower;
            totalPower -= stakeInfo[id].milkPower;
            lastTime = block.timestamp;
        }
        cowsAmount--;
        emit UnStake(msg.sender, tokenId);
    }

    function setDaliyOut(uint out_) external onlyOwner {
        daliyOut = out_;
        rate = daliyOut / 86400;
    }

    function addBadge(uint tokenID) external {
        require(userBadge[msg.sender].tokenID == 0, 'had badge');
        badge.safeTransferFrom(msg.sender, address(this), tokenID);
        userBadge[msg.sender].tokenID = tokenID;
        userBadge[msg.sender].badgeID = badge.badgeIdMap(tokenID);
        userBadge[msg.sender].power = badge.checkBadgeEffect(userBadge[msg.sender].badgeID);
        if (userInfo[msg.sender].cattleList.length > 0) {
            uint tempDebt = coutingDebt();
            debt = tempDebt;
            totalPower += userBadge[msg.sender].power;
            userInfo[msg.sender].totalPower += userBadge[msg.sender].power;
            lastTime = block.timestamp;
            uint id = uint256(keccak256(abi.encodePacked(msg.sender, tokenID)));
            stakeInfo[id] = StakeInfo({
            status : true,
            milkPower : userBadge[msg.sender].power,
            tokenId : id,
            endTime : block.timestamp + 86400000,
            starrtTime : block.timestamp,
            claimTime : block.timestamp,
            debt : tempDebt
            });
        }

    }

    function pullOutBadge() external {
        require(userBadge[msg.sender].tokenID != 0, 'have no badge');
        badge.safeTransferFrom(address(this), msg.sender, userBadge[msg.sender].tokenID);

        if(userInfo[msg.sender].cattleList.length > 0){
            uint id = uint256(keccak256(abi.encodePacked(msg.sender, userBadge[msg.sender].tokenID)));
            uint rew = caculeteCow(id);
            if (rew != 0) {
                uint tax = planet.findTax(msg.sender);
                uint taxAmuont = rew * tax / 100;
                planet.addTaxAmount(msg.sender, taxAmuont);
                BVT.transfer(msg.sender, rew - taxAmuont);
                BVT.transfer(address(planet), taxAmuont);
                userInfo[msg.sender].cliamed += rew - taxAmuont;
                totalClaimed += rew;

            }
            userInfo[msg.sender].totalPower -= stakeInfo[id].milkPower;
            debt = coutingDebt();
            totalPower -= stakeInfo[id].milkPower;
            lastTime = block.timestamp;
            delete stakeInfo[id];
        }


        delete userBadge[msg.sender];
    }

    function renewTime(uint tokenId, uint energyCost) public {
        require(stakeInfo[tokenId].status, 'not staking');
        require(stable.CattleOwner(tokenId) == msg.sender, "not cattle's owner");
        stable.costEnergy(tokenId, energyCost);
        stakeInfo[tokenId].endTime += energyCost * timePerEnergy;
        emit RenewTime(msg.sender, tokenId, stakeInfo[tokenId].endTime);
    }

    function setCompoundRate(uint badgeID, uint rates) external onlyOwner {
        compoundRate[badgeID] = rates;
    }

    function setCompoundRew(uint badgeId,uint rews) external onlyOwner{
        compoundRew[badgeId] = rews;
    }

    function findEndTime(uint tokenId, uint energyCost) public view returns (uint){
        uint energyTime = block.timestamp + energyCost * timePerEnergy;
        uint deadTime = cattle.deadTime(tokenId);
        if (energyTime <= deadTime) {
            return energyTime;
        } else {
            return deadTime;
        }
    }

    function compoundBadge(uint[3] memory tokenIDs) external {
        uint badgeID = badge.badgeIdMap(tokenIDs[0]);
        require(badgeID >= 40001 && badgeID <= 40003, 'wrong badge ID');
        require(badgeID == badge.badgeIdMap(tokenIDs[1]) && badge.badgeIdMap(tokenIDs[1]) == badge.badgeIdMap(tokenIDs[2]), 'wrong badgeID');
        badge.burn(tokenIDs[0]);
        badge.burn(tokenIDs[1]);
        badge.burn(tokenIDs[2]);
        uint _rate = compoundRate[badgeID];
        uint out = rand(1000);
        if (out <= _rate) {
            badge.mint(msg.sender, badgeID + 1);
            emit Reward(msg.sender,badgeID + 1,1);
        } else {
            cattleItem.mint(msg.sender,20004,compoundRew[badgeID]);
            emit Reward(msg.sender,20004,compoundRew[badgeID]);
        }
    }

    function compoundBadgeShred() external {
        cattleItem.burn(msg.sender,20004,3);
        uint out = rand(100);
        if(out <= 700){
            badge.mint(msg.sender, 40001);
            emit Reward(msg.sender,40001,1);
        }else{
            emit Reward(msg.sender,0,0);
        }
    }

    function setDebt(uint debt_) external onlyOwner{
        debt = debt_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICOW {
    function getGender(uint tokenId_) external view returns (uint);

    function getEnergy(uint tokenId_) external view returns (uint);

    function getAdult(uint tokenId_) external view returns (bool);

    function getAttack(uint tokenId_) external view returns (uint);

    function getStamina(uint tokenId_) external view returns (uint);

    function getDefense(uint tokenId_) external view returns (uint);

    function getPower(uint tokenId_) external view returns (uint);

    function getLife(uint tokenId_) external view returns (uint);

    function getBronTime(uint tokenId_) external view returns (uint);

    function getGrowth(uint tokenId_) external view returns (uint);

    function getMilk(uint tokenId_) external view returns (uint);

    function getMilkRate(uint tokenId_) external view returns (uint);
    
    function getCowParents(uint tokenId_) external view returns(uint[2] memory);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function mintNormall(address player, uint[2] memory parents) external;

    function mint(address player) external;

    function setApprovalForAll(address operator, bool approved) external;

    function growUp(uint tokenId_) external;

    function isCreation(uint tokenId_) external view returns (bool);

    function burn(uint tokenId_) external returns (bool);

    function deadTime(uint tokenId_) external view returns (uint);

    function addDeadTime(uint tokenId, uint time_) external;

    function checkUserCowListType(address player,bool creation_) external view returns (uint[] memory);
    
    function checkUserCowList(address player) external view returns(uint[] memory);
    
    function getStar(uint tokenId_) external view returns(uint);
    
    function mintNormallWithParents(address player) external;
    
    function currentId() external view returns(uint);
    
    function upGradeStar(uint tokenId) external;
    
    function starLimit(uint stars) external view returns(uint);
    
    function creationIndex(uint tokenId) external view returns(uint);
    
    
}

interface IBOX {
    function mint(address player, uint[2] memory parents_) external;

    function burn(uint tokenId_) external returns (bool);

    function checkParents(uint tokenId_) external view returns (uint[2] memory);

    function checkGrow(uint tokenId_) external view returns (uint[2] memory);

    function checkLife(uint tokenId_) external view returns (uint[2] memory);
    
    function checkEnergy(uint tokenId_) external view returns (uint[2] memory);
}

interface IStable {
    function isStable(uint tokenId) external view returns (bool);
    
    function rewardRate(uint level) external view returns(uint);

    function isUsing(uint tokenId) external view returns (bool);

    function changeUsing(uint tokenId, bool com_) external;

    function CattleOwner(uint tokenId) external view returns (address);

    function getStableLevel(address addr_) external view returns (uint);

    function energy(uint tokenId) external view returns (uint);

    function grow(uint tokenId) external view returns (uint);

    function costEnergy(uint tokenId, uint amount) external;
    
    function addStableExp(address addr, uint amount) external;
    
    function userInfo(address addr) external view returns(uint,uint);
    
    function checkUserCows(address addr_) external view returns (uint[] memory);
    
    function growAmount(uint time_, uint tokenId) external view returns(uint);
    
    function refreshTime() external view returns(uint);
    
    function feeding(uint tokenId) external view returns(uint);
    
    function levelLimit(uint index) external view returns(uint);
    
    function compoundCattle(uint tokenId) external;

}

interface IMilk{
    function userInfo(address addr) external view returns(uint,uint);
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface IPlanet{
    
    function isBonding(address addr_) external view returns(bool);
    
    function addTaxAmount(address addr,uint amount) external;
    
    function getUserPlanet(address addr_) external view returns(uint);
    
    function findTax(address addr_) external view returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICattle1155 {
    function mintBatch(address to_, uint256[] memory ids_, uint256[] memory amounts_) external returns (bool);

    function mint(address to_, uint cardId_, uint amount_) external returns (bool);

    function safeTransferFrom(address from, address to, uint256 cardId, uint256 amount, bytes memory data_) external;

    function safeBatchTransferFrom(address from_, address to_, uint256[] memory ids_, uint256[] memory amounts_, bytes memory data_) external;

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function balanceOf(address account, uint256 tokenId) external view returns (uint);

    function burned(uint) external view returns (uint);

    function burn(address account, uint256 id, uint256 value) external;

    function checkItemEffect(uint id_) external view returns (uint[3] memory);
    
    function itemLevel(uint id_) external view returns (uint);
    
    function itemExp(uint id_) external view returns(uint);
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface ITec{
    
    function getUserTecLevelBatch(address addr,uint[] memory list) external view returns(uint[] memory out);
    
    function getUserTecLevel(address addr,uint ID) external view returns(uint out);
    
    function checkUserExpBatch(address addr,uint[] memory list) external view returns(uint[] memory out);
    
    function checkUserTecEffet(address addr, uint ID) external view returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBadge{
    function mint(address player,uint skinId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function checkUserBadgeList(address player) external view returns (uint[] memory);
    function badgeIdMap(uint tokenID) external view returns(uint);
    function checkUserBadge(address player,uint ID) external view returns(uint[] memory);
    function checkBadgeEffect(uint badgeID) external view returns(uint);
    function checkUserBadgeIDList(address player) external view returns (uint[] memory);
    function burn(uint tokenId_) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
//    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}