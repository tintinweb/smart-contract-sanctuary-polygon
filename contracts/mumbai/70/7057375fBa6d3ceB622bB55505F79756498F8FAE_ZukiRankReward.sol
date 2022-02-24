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

contract ZukiRankReward is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    uint256 public CLAIM_FEE = 0.001 ether;
    address public ZP_TOKEN = 0x985B61a18D1BC12E136Aa285c74729495783fD62;
    address public GP_TOKEN = 0xa5ca9Eaa17Baa1e5DF302DA0A9f566cE008fBF25;
    address payable public SALE_WALLET =
        0x8E8FCc1680a6A642521a5F9BE37eC2f26940E38A;
    uint256 public PERCENTS_DIVIDER = 100000;

    struct UserInfo {
        Campaign[] campaigns;
    }

    struct Campaign {
        uint256 campaignId;
        uint256 totalPoolZP;
        uint256 totalPoolGP;
        uint256 startTime;
        uint256 endTime;
        uint256 totalClaimed;
    }

    event FeeClaim(address indexed userAddress, uint256 fee);
    event ClaimZP(address indexed userAddress, uint256 amount);
    event ClaimGP(address indexed userAddress, uint256 amount);

    mapping(address => UserInfo) internal userInfos;
    mapping(address => uint256) public whiteList;
    mapping(address => bool) public whiteListAddr;
    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => uint256) public ranks;

    modifier onlySafe() {
        require(whiteListAddr[msg.sender], "require Safe Address.");
        _;
    }

    constructor() {
        whiteListAddr[_msgSender()] = true;
        ranks[1] = 5000;
        ranks[2] = 3000;
        ranks[3] = 2000;
        ranks[4] = 1000;
        ranks[5] = 1000;
        ranks[6] = 1000;
        ranks[7] = 1000;
        ranks[8] = 1000;
        ranks[9] = 1000;
        ranks[10] = 1000;
        ranks[11] = 500;
        ranks[12] = 400;
        ranks[13] = 300;
        ranks[14] = 200;
        ranks[15] = 100;
        ranks[16] = 90;
        ranks[16] = 80;
        ranks[17] = 62;
        campaigns[1] = Campaign(1,10000000000000000000000,100000000000000000000000,1645671600,1648090800,0);
    }

    function setFeeSale(uint256 _fee) external onlyOwner {
        CLAIM_FEE = _fee;
    }

    function setZPToken(address _address) external onlyOwner {
        ZP_TOKEN = _address;
    }

    function setGPToken(address _address) external onlyOwner {
        GP_TOKEN = _address;
    }

    function setSaleWallet(address payable _address) external onlyOwner {
        SALE_WALLET = _address;
    }

    function modifyWhiteList(address[] memory newAddr, uint256[] memory newRank)
        public
        onlySafe
    {
        require(newAddr.length == newRank.length, "length not match");
        for (uint256 index; index < newAddr.length; index++) {
            whiteList[newAddr[index]] = newRank[index];
        }
    }

    function modifyWhiteListAddr(
        address[] memory newAddr,
        address[] memory removedAddr
    ) public onlyOwner {
        for (uint256 index; index < newAddr.length; index++) {
            whiteListAddr[newAddr[index]] = true;
        }
        for (uint256 index; index < removedAddr.length; index++) {
            whiteListAddr[removedAddr[index]] = false;
        }
    }

    function modifyRanks(uint256[] memory newRank, uint256[] memory newPercent)
        public
        onlySafe
    {
        require(newRank.length == newPercent.length, "length not match");
        for (uint256 index; index < newRank.length; index++) {
            ranks[newRank[index]] = newPercent[newRank[index]];
        }
    }

    function modifyCampaign(uint256 campaignId, Campaign memory campaign)
        public
        onlySafe
    {
        campaigns[campaignId] = campaign;
    }

    function claimReward(uint256 campaignId)
        public
        payable
        nonReentrant
        whenNotPaused
    {
        require(whiteList[_msgSender()] > 0, "not in whiteList");
        require(
            campaigns[campaignId].startTime <= block.timestamp,
            "campaign not start"
        );
        require(
            campaigns[campaignId].endTime >= block.timestamp,
            "campaign already end"
        );
        require(msg.value == CLAIM_FEE, "fee not accepted");
        UserInfo storage userInfo = userInfos[_msgSender()];
        bool claimed;
        for (uint256 index = 0; index < userInfo.campaigns.length; index++) {
            if (userInfo.campaigns[index].campaignId == campaignId) {
                claimed = true;
            }
        }
        require(!claimed, "already claimed");
        SALE_WALLET.transfer(msg.value);
        emit FeeClaim(_msgSender(), CLAIM_FEE);
        uint256 zpAmount = campaigns[campaignId]
            .totalPoolZP
            .mul(ranks[whiteList[_msgSender()]])
            .div(PERCENTS_DIVIDER);
        uint256 gpAmount = campaigns[campaignId]
            .totalPoolGP
            .mul(ranks[whiteList[_msgSender()]])
            .div(PERCENTS_DIVIDER);
        IERC20(ZP_TOKEN).transfer(_msgSender(), zpAmount);
        emit ClaimZP(_msgSender(), zpAmount);
        IERC20(GP_TOKEN).transfer(_msgSender(), gpAmount);
        emit ClaimZP(_msgSender(), gpAmount);
        userInfo.campaigns.push(campaigns[campaignId]);
        campaigns[campaignId].totalClaimed = campaigns[campaignId].totalClaimed.add(1);
    }

    function getUserInfo(address userAddress)
        public
        view
        returns (UserInfo memory user)
    {
        user = userInfos[userAddress];
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