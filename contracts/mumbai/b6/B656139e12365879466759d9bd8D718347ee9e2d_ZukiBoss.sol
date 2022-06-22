// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.0;
pragma abicoder v2;

import "./Context.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./INFTCore.sol";
import "./IERC721.sol";

contract ZukiBoss is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    uint256 public CLAIM_FEE_ADV = 0.001 ether;
    uint256 public CLAIM_FEE_NOR = 50 ether;
    address public REWARD_TOKEN = 0xa5ca9Eaa17Baa1e5DF302DA0A9f566cE008fBF25;
    address public FEE_TOKEN = 0xD7023b58e27F2aEa2e43BBd77d47C4f20fb83d84;
    address payable public SALE_WALLET =
        0x8E8FCc1680a6A642521a5F9BE37eC2f26940E38A;
    uint256 public ATTACK = 1000;
    uint256 public ATTACK_MISSION = 5;
    uint256 public FEE_ATTACK = 0;
    INFTCore public nftCore =
        INFTCore(0xb88438B4fe0fa67958c07365eB41DD2729BAc584);
    IERC721 public nft = IERC721(0xb88438B4fe0fa67958c07365eB41DD2729BAc584);
    uint256 public REWARD_NOT_DIE = 50; //50%

    struct UserInfo {
        uint256 damage;
        bool claimed;
    }

    struct Boss {
        uint256 id;
        uint256 typeBoss;
        uint256 blood;
        uint256 startTime;
        uint256 endTime;
        uint256 minHero;
        uint256 maxHero;
        uint256 minGun;
        bool died;
        uint256 currentDamage;
        uint256 totalReward;
    }

    event FeeClaim(address indexed userAddress, uint256 amount, uint256 fee);
    event Attack(
        address indexed userAddress,
        uint256 damage,
        uint256 typeBoss,
        uint256 bossId
    );

    mapping(uint256 => mapping(address => UserInfo)) public userInfos;
    mapping(address => bool) public whiteList;
    mapping(uint256 => Boss) bosses;
    mapping(address => uint256) public attackCounts;


    modifier onlySafe() {
        require(whiteList[msg.sender], "require Safe Address.");
        _;
    }

    constructor() {
        whiteList[_msgSender()] = true;
    }

    function setClaimFeeAdv(uint256 _fee) external onlyOwner {
        CLAIM_FEE_ADV = _fee;
    }

    function setClaimFeeNor(uint256 _fee) external onlyOwner {
        CLAIM_FEE_NOR = _fee;
    }

    function setRewardToken(address _address) external onlyOwner {
        REWARD_TOKEN = _address;
    }

    function setFeeToken(address _address) external onlyOwner {
        FEE_TOKEN = _address;
    }

    function setSaleWallet(address payable _address) external onlyOwner {
        SALE_WALLET = _address;
    }

    function setAttack(uint256 attack) external onlyOwner {
        ATTACK = attack;
    }

    function setFeeAttack(uint256 _fee) external onlyOwner {
        FEE_ATTACK = _fee;
    }

    function setAttackMission(uint256 mission) external onlyOwner {
        ATTACK_MISSION = mission;
    }

    function setRewardNoDie(uint256 reward) external onlyOwner {
        REWARD_NOT_DIE = reward;
    }

    function modifyWhiteList(
        address[] memory newAddr,
        address[] memory removedAddr
    ) public onlyOwner {
        for (uint256 index; index < newAddr.length; index++) {
            whiteList[newAddr[index]] = true;
        }
        for (uint256 index; index < removedAddr.length; index++) {
            whiteList[removedAddr[index]] = false;
        }
    }

    function modifyBoss(Boss[] memory bossArr)
        public
        onlySafe
    {
        for (uint256 index; index < bossArr.length; index++) {
            bosses[bossArr[index].id] = bossArr[index];
        }
    }

    function claimReward(uint256 bossId)
        public
        payable
        nonReentrant
        whenNotPaused
    {
        UserInfo storage userInfo = userInfos[bossId][_msgSender()];
        Boss storage boss = bosses[bossId];
        require(!userInfo.claimed, "already claimed");
        require(boss.endTime < block.timestamp, "attack boss not end");
        uint256 reward = boss.totalReward.mul(userInfo.damage).div(boss.blood);
        if(!boss.died) {
            reward = reward.mul(REWARD_NOT_DIE).div(100);
        }
        if (boss.typeBoss == 1) {
            require(
                IERC20(FEE_TOKEN).allowance(_msgSender(), address(this)) >=
                    CLAIM_FEE_NOR,
                "Token allowance too low"
            );
            IERC20(FEE_TOKEN).transferFrom(
                _msgSender(),
                address(this),
                CLAIM_FEE_NOR
            );
            IERC20(REWARD_TOKEN).transfer(_msgSender(), reward);
            emit FeeClaim(_msgSender(), reward, CLAIM_FEE_NOR);
            userInfo.claimed = true;
            attackCounts[_msgSender()] = attackCounts[_msgSender()].add(1);
        }
        if (boss.typeBoss == 2) {
            require(msg.value == CLAIM_FEE_ADV, "fee bnb not enough");
            SALE_WALLET.transfer(msg.value);
            IERC20(REWARD_TOKEN).transfer(_msgSender(), reward);
            emit FeeClaim(_msgSender(), reward, CLAIM_FEE_ADV);
            userInfo.claimed = true;
            attackCounts[_msgSender()] = attackCounts[_msgSender()].add(1);
        }
    }

    function attackBoss(
        uint256 bossId,
        uint256[] memory heros,
        uint256[] memory guns
    ) public nonReentrant whenNotPaused {
        Boss storage boss = bosses[bossId];
        UserInfo storage userInfo = userInfos[bossId][_msgSender()];
        uint256 attack = attackCounts[_msgSender()];
        require(
            IERC20(FEE_TOKEN).allowance(_msgSender(), address(this)) >= FEE_ATTACK,
            "Token allowance too low"
        );
        if (FEE_ATTACK > 0) {
            IERC20(FEE_TOKEN).transferFrom(
                _msgSender(),
                SALE_WALLET,
                FEE_ATTACK
            );
        }
        require(heros.length >= boss.minHero, "not enough hero");
        require(heros.length <= boss.maxHero, "too much hero");
        require(guns.length <= boss.minGun, "not enough gun");
        require(boss.startTime <= block.timestamp, "boss not start");
        require(boss.endTime >= block.timestamp, "boss already ended");
        require(
            userInfo.damage == 0,
            "only attack one time for once boss"
        );
        require(!boss.died, "boss already died");
        if (boss.typeBoss == 2) {
            require(
                attack >= ATTACK_MISSION,
                "not complete mission"
            );
            if(attack > 0) {
                attackCounts[_msgSender()] = attack.sub(ATTACK_MISSION);
            } else {
                attackCounts[_msgSender()] = 0;
            }
        }
        uint256 attackDamage;

        for (uint256 index = 0; index < heros.length; index++) {
            require(nft.ownerOf(heros[index]) == _msgSender(), "not owner");
            require(
                keccak256(
                    abi.encodePacked(nftCore.getNFT(heros[index]).class)
                ) == keccak256(abi.encodePacked("Zuki Hero")),
                "not a hero"
            );
            uint256 attackN = ATTACK.mul(2**nftCore.getNFT(heros[index]).rare);
            attackDamage = attackDamage.add(attackN);
        }
        for (uint256 index = 0; index < guns.length; index++) {
            require(nft.ownerOf(guns[index]) == _msgSender(), "not owner");
            require(
                keccak256(
                    abi.encodePacked(nftCore.getNFT(guns[index]).class)
                ) == keccak256(abi.encodePacked("Zuki Gun")),
                "not a gun"
            );
            uint256 attackN = ATTACK.mul(2**nftCore.getNFT(guns[index]).rare);
            attackDamage = attackDamage.add(attackN);
        }
        if(boss.currentDamage.add(attackDamage) > boss.blood) {
            attackDamage = boss.blood - boss.currentDamage;
        }
        boss.currentDamage = boss.currentDamage.add(attackDamage);
        if (boss.currentDamage >= boss.blood) {
            boss.died = true;
        }
        userInfo.damage = attackDamage;
       
        emit Attack(_msgSender(), attackDamage, boss.typeBoss, bossId);
    }

    function getUserInfo(uint256 bossId, address userAddress)
        public
        view
        returns (UserInfo memory user)
    {
        user = userInfos[bossId][userAddress];
    }

    function bossInfo(uint256 bossId)
        public
        view
        returns (Boss memory boss)
    {
        boss = bosses[bossId];
    }

    function setNFT(address _address) external onlyOwner {
        nft = IERC721(_address);
        nftCore = INFTCore(_address);
    }

    /**
     * @dev Withdraw bnb from this contract (Callable by owner only)
     */
    function handleForfeitedBalance(
        address coinAddress,
        uint256 value,
        address payable to
    ) public onlyOwner {
        if (coinAddress == address(0)) {
            return to.transfer(value);
        }
        IERC20(coinAddress).transfer(to, value);
    }
}