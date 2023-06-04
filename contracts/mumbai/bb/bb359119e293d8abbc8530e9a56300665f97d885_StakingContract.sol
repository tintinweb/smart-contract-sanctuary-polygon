/**
 *Submitted for verification at polygonscan.com on 2023-06-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StakingContract {
    mapping(address => bool) public Active;
    IERC20 public token;
    uint256 public decimals = 10 ** 6;
    address public owner = 0x6B851e5B220438396ac5ee74779DDe1a54f795A9;
    address public AWallet = 0x584C5ab8e595c0C2a1aA0cD23a1aEa56a35B9698;
    address public BWallet = 0x1F4de95BbE47FeE6DDA4ace073cc07eF858A2e94;
    address CWallet = 0xF4fC364851D03A7Fc567362967D555a4d843647d;
    address public DCTokenAddress = 0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8;
    mapping(address => UserStruct) public Users;
    struct DynamicStruct {
        uint256 reward;
        uint256 timeStamp;
    }
    struct StakeStruct {
        uint256 reward;
        uint256 staticClaimed;
        uint256 dynamicClaimed;
        uint256 timestamp;
    }
    struct UserStruct {
        StakeStruct[] stakes;
        address[6] upReferals;
        address[][] downReferrals;
        DynamicStruct[] dynamicPerDay;
        uint256 dynamicAvailable;
        uint8 rank;
        uint256 dynamicLimit;
        uint256 staticLimit;
    }

    constructor(address _token) {
        token = IERC20(_token);
    }

    modifier signedIn() {
        require(
            Active[msg.sender],
            "Please sign in before utilising functions"
        );
        _;
    }
    modifier onlyOwner() {
        require(
            (msg.sender == owner),
            "you are not allowed to utilise this function"
        );
        _;
    }

    bool private locked;
    modifier nonReentrant() {
        require(!locked, "ReentrancyGuard: reentrant call");
        locked = true;
        _;
        locked = false;
    }

    function signIn(address _friend) public nonReentrant {
        require(msg.sender != _friend);
        require(!Active[msg.sender], "Already signed in");
        require(
            ((Active[_friend]) || (_friend == address(0))),
            "Invalid referal id"
        );
        Active[msg.sender] = true;
        handleUpReferals(_friend);
        handleDownReferals();
        Users[msg.sender].dynamicLimit = 2 * decimals;
        Users[msg.sender].staticLimit = 1 * decimals;
    }

    function handleUpReferals(address _friend) internal {
        address[6] memory upReferals = Users[_friend].upReferals;
        for (uint8 i = 5; i > 0; i--) upReferals[i] = upReferals[i - 1];
        upReferals[0] = _friend;
        Users[msg.sender].upReferals = upReferals;
    }

    function handleDownReferals() internal {
        for (uint8 i = 0; i < 3; i++) Users[msg.sender].downReferrals.push();
        address friend;
        for (uint8 i = 0; i < 3; i++) {
            friend = Users[msg.sender].upReferals[i];
            if (friend == address(0)) break;
            Users[friend].downReferrals[i].push(msg.sender);
        }
    }

    function stake(uint256 _amount) public signedIn {
        require(
            Users[msg.sender].stakes.length < 5,
            "No of stakes exceeds the limit"
        );
        require(_amount >= 10 * decimals, "Min staking amount is 100USDT");
        _stake(_amount);
        distributeStakeMoney(_amount);
        handleDirectBonus(_amount);
    }

    function _stake(uint256 _amount) internal {
        StakeStruct memory newStake = StakeStruct(
            _amount * 2,
            0,
            0,
            block.timestamp
        );
        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "Please increase the allowance to the contract"
        );
        Users[msg.sender].stakes.push(newStake);
    }

    function distributeStakeMoney(uint256 _amount) internal {
        token.transfer(DCTokenAddress, (_amount * 5) / 100);
        token.transfer(AWallet, (_amount * 14) / 100);
        token.transfer(BWallet, (_amount * 14) / 100);
        token.transfer(CWallet, (_amount * 2) / 100);
    }

    function handleDirectBonus(uint256 _amount) internal {
        address _friend = Users[msg.sender].upReferals[0];
        Users[_friend].dynamicAvailable += (_amount * 20) / 100;
    }

    function handleRelationBonus(uint256 _amount) private {
        address[6] memory upRefererals = Users[msg.sender].upReferals;
        uint256 reward = (_amount * 5) / 10000;
        for (uint8 i = 0; i < 6; i++) {
            if (upRefererals[i] == address(0)) break;
            if (Users[upRefererals[i]].downReferrals[0].length > i)
                Users[upRefererals[i]].dynamicPerDay.push(
                    DynamicStruct(reward, block.timestamp)
                );
        }

        address[][] memory downReferrals = Users[msg.sender].downReferrals;
        for (uint8 i = 0; i < downReferrals.length; i++) {
            for (uint8 j = 0; j < downReferrals[i].length; j++) {
                address referer = downReferrals[i][j];
                if (referer == address(0)) break;
                else {
                    if (Users[referer].downReferrals[0].length > i)
                        Users[upRefererals[i]].dynamicPerDay.push(
                            DynamicStruct(reward, block.timestamp)
                        );
                }
            }
        }
    }

    function getTotalDynamicRewards(
        address _user
    ) public view returns (uint256) {
        uint256 total = 0;
        DynamicStruct[] memory list = Users[_user].dynamicPerDay;
        for (uint256 i = 0; i < list.length; i++) {
            uint256 timeDiff = block.timestamp - list[i].timeStamp;
            timeDiff = timeDiff / 60;
            total += timeDiff * list[i].reward;
        }
        total += Users[_user].dynamicAvailable;
        total +=
            (getTotalStaticRewards(_user) * calculateTeamBonus(_user)) /
            100;
        return total;
    }

    function getTotalStaticRewards(
        address _user
    ) public view returns (uint256) {
        StakeStruct[] memory stakes = Users[_user].stakes;
        uint256 total = 0;
        for (uint256 i = 0; i < stakes.length; i++) {
            uint256 timeDiff = block.timestamp - stakes[i].timestamp;
            timeDiff = timeDiff / 60;
            uint256 totalClaimable = (timeDiff * stakes[i].reward) / 200;
            totalClaimable = totalClaimable - stakes[i].staticClaimed;
            if (
                (totalClaimable +
                    stakes[i].dynamicClaimed +
                    stakes[i].staticClaimed) >= stakes[i].reward
            ) {
                totalClaimable =
                    stakes[i].reward -
                    (stakes[i].dynamicClaimed + stakes[i].staticClaimed);
            }
            total += totalClaimable;
        }
        return total;
    }

    function calculateTeamBonus(address _user) private view returns (uint256) {
        uint8 rank = Users[_user].rank;
        if (rank == 1) return 10;
        if (rank == 2) return 20;
        if (rank == 3) return 30;
        if (rank == 4) return 40;
        if (rank == 5) return 50;
        if (rank == 6) return 60;
        return 0;
    }

    function claimStaticReward(uint256 _amount) public nonReentrant {
        uint256 totalReward = getTotalStaticRewards(msg.sender);
        require(
            _amount <= totalReward,
            "The amount should be less than the totals rewards"
        );
        require(
            _amount >= Users[msg.sender].staticLimit,
            "The amount less than the allowed limit"
        );
        updateTotalStaticReward(_amount);
        token.transfer(msg.sender, _amount);
        Users[msg.sender].staticLimit = getNextLimit(false, msg.sender);
    }

    function updateTotalStaticReward(uint256 _amount) internal {
        StakeStruct[] memory stakes = Users[msg.sender].stakes;
        uint256 reward = _amount;
        for (uint256 i = 0; i < stakes.length; i++) {
            if (reward <= 0) break;
            uint256 timeDiff = block.timestamp - stakes[i].timestamp;
            timeDiff = timeDiff / 60;
            uint256 totalClaimable = (timeDiff * stakes[i].reward) / 200;
            totalClaimable = totalClaimable - stakes[i].staticClaimed;
            if (
                (totalClaimable +
                    stakes[i].dynamicClaimed +
                    stakes[i].staticClaimed) >= stakes[i].reward
            ) {
                totalClaimable =
                    stakes[i].reward -
                    (stakes[i].dynamicClaimed + stakes[i].staticClaimed);
            }
            if (totalClaimable > reward) totalClaimable = reward;
            reward -= totalClaimable;
            Users[msg.sender].stakes[i].staticClaimed += totalClaimable;
        }
    }

    function claimDynamicReward(uint256 _amount) public nonReentrant {
        uint256 totalReward = getTotalDynamicRewards(msg.sender);
        require(
            _amount <= totalReward,
            "The amount should be less than the totals rewards"
        );
        require(
            _amount >= Users[msg.sender].dynamicLimit,
            "The amount less than the allowed limit"
        );
        uint256 total = updateStakes(_amount);
        token.transfer(msg.sender, total);
        Users[msg.sender].staticLimit = getNextLimit(true, msg.sender);
    }

    function updateStakes(uint256 _amount) internal returns (uint256) {
        StakeStruct[] memory stakes = Users[msg.sender].stakes;
        uint256 reward = _amount;
        uint256 total = 0;
        for (uint256 i = 0; i < stakes.length; i++) {
            uint256 totalClaimable = stakes[i].reward -
                (stakes[i].dynamicClaimed + stakes[i].staticClaimed);
            if (reward <= totalClaimable) {
                total += reward;
                Users[msg.sender].stakes[i].dynamicClaimed += reward;
                return total;
            } else {
                reward -= totalClaimable;
                total += totalClaimable;
                Users[msg.sender].stakes[i].dynamicClaimed += totalClaimable;
            }
        }
        return total;
    }

    function getNextLimit(
        bool dynamic,
        address _user
    ) public view returns (uint256) {
        if (dynamic) {
            return Users[_user].dynamicLimit * 2;
        } else {
            return Users[_user].dynamicLimit * 2;
        }
    }

    function checkUpgradablity(address _user) public view returns (bool) {
        UserStruct memory user = Users[_user];
        if (user.rank == 0) {
            if (getTotalStakes(_user) >= 40 * decimals) return true;
            else return false;
        } else if (user.rank == 1) {
            if (getRefsWithRank(1, _user) >= 3) return true;
            else return false;
        } else if (user.rank == 2) {
            if (getRefsWithRank(2, _user) >= 3) return true;
            else return false;
        } else if (user.rank == 3) {
            if (getRefsWithRank(3, _user) >= 3) return true;
            else return false;
        } else if (user.rank == 4) {
            if (getRefsWithRank(4, _user) >= 3) return true;
            else return false;
        } else if (user.rank == 5) {
            if (getRefsWithRank(5, _user) >= 3) return true;
            else return false;
        } else {
            return false;
        }
    }

    function getTotalStakes(address _user) public view returns (uint256) {
        StakeStruct[] memory stakes = Users[_user].stakes;
        uint256 total = 0;
        for (uint256 i = 0; i < stakes.length; i++) total += stakes[i].reward;
        return total;
    }

    function getRefsWithRank(
        uint8 _rank,
        address _user
    ) public view returns (uint256) {
        address[] memory refs = Users[_user].downReferrals[0];
        uint256 total = 0;
        for (uint256 i = 0; i < refs.length; i++) {
            if (Users[refs[i]].rank == _rank) total++;
        }
        return total;
    }

    function upgradeLevel() public nonReentrant {
        require(
            checkUpgradablity(msg.sender),
            "You cant upgrade untill next goal is fulfilled"
        );
        Users[msg.sender].rank += 1;
    }

    // Admin Functions:- Only to be used in case of emergencies
    function withDrawTokens(
        address _token,
        address withdrawalAddress
    ) public onlyOwner {
        IERC20 _tokenContract = IERC20(_token);
        _tokenContract.transfer(
            withdrawalAddress,
            token.balanceOf(address(this))
        );
    }

    function changeDCTokenAddress(address newAddr) public onlyOwner {
        DCTokenAddress = newAddr;
    }

    function getStakes(
        address _user
    ) public view returns (StakeStruct[] memory) {
        return Users[_user].stakes;
    }

    function getUpReferals(
        address _user
    ) public view returns (address[6] memory) {
        return Users[_user].upReferals;
    }

    function getDownReferals(
        address _user
    ) public view returns (address[][] memory) {
        return Users[_user].downReferrals;
    }

    function getDownReferalsInLevel(
        address _user,
        uint8 index
    ) public view returns (address[] memory) {
        return Users[_user].downReferrals[index];
    }

    function getDynamicPerDay(
        address _user
    ) public view returns (DynamicStruct[] memory) {
        return Users[_user].dynamicPerDay;
    }

    // function DistributeDynamicAmount(
    //     uint256 TReward,
    //     address _user
    // ) internal returns (uint256) {
    //     StakeStruct[] memory stakes = Users[_user].stakes;
    //     for (uint256 i = 0; i < stakes.length; i++) {
    //         uint256 max = stakes[i].reward -
    //             stakes[i].dynamicClaimed +
    //             stakes[i].staticClaimed;
    //         if (max >= TReward) {
    //             Users[_user].stakes[i].dynamicReward += TReward;
    //             TReward -= max;
    //             break;
    //         } else {
    //             Users[_user].stakes[i].dynamicReward += max;
    //             TReward -= max;
    //         }
    //     }
    //     return TReward;
    // }
    // 0x0000000000000000000000000000000000000000
    // 0x17F6AD8Ef982297579C203069C1DbfFE4348c372
    // 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
    // 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
    // 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
    // stake - 0x9d83e140330758a8fFD07F8Bd73e86ebcA8a5692
    // token -0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8
    // 100000000
}