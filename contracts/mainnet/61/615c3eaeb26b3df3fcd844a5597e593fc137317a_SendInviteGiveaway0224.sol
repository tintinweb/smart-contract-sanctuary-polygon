/**
 *Submitted for verification at polygonscan.com on 2022-02-24
*/

// SPDX-License-Identifier: MIT

// This contract for CorianderDAO.eth Invite Giveaway

// UTC+8 Feb-24, 2022 Giveaway Contract

/**

Join CorianderDAO.eth >> https://discord.gg/mPFb9cHdSK

一個新的潛力項目，
還有很新穎的賦能模式，養成系的項目，讓大家一起建設一個新世界～～

加入連結：https://discord.gg/mPFb9cHdSK

E-mail: [email protected]

今日起我們將每天抽出 10 USDC，每邀請 5 人，每天都能夠獲取一次抽獎資格，
邀請 10 人每天有 2 次，邀請 15 人每天則有 3 次 ... 以此類推
（邀請人數可累計，過去邀請紀錄也算）。

邀請人數足夠之後請於每日台北時間 18:00 前填寫此表單才能
參加當日之抽獎（表單不一定要每天填，但如需更新邀請人數則需再填一次才會生效）

https://forms.gle/Svfr7eZjTDNEcPFU6

獎項我們會在每天台北時間 23:59 前透過智能合約抽出 

另外，每日累積邀請人數前十名我們還會在額外每天
再各送出 1 USDC（連續 30 天前十名就能拿到 30 USDC）

Roadmap 更新 2022.02.23

1.    我們預計三月發行我們的DAO會員NFT，用於募集DAO所需的初始資金。

2.    之後會發行 Coriander Coin其中50% 空投給會員 NFT 持有者，剩下 50% 將定期（暫定每季）空投給 Coriander Coin 持有者。

3.    作為CorianderDAO發展的第一步，我們將推出農地 NFT，會員 NFT 持有者將可優先認購，認購後將成為第一批進 Coriander World 開墾的農民與地主，而每塊農地將可切分為100塊種植地。

4.    每塊種植地可用於種植作物，種植作物須每天澆水、施肥照顧，經過一定時間成熟過後可換取收益。

5.    農地的地主可將其農地出租給其他地主後定期收取租金，也能自己種植作物。

6.    DAO 收益（包含廣告、NFT項目合作、NFT 版費（Royalty Fee） … 組織相關之收益）扣除成本之後80% 回饋給會員NFT 及 Coriander Coin 持有人，20% 捐贈給慈善機構。

7.    我們目前正在徵求商家一起合作，合作商家有機會認購更多我們的會員 NFT，進一步參與 Coriander World 的建設，並得到更多的曝光度，有興趣的可以到 🎗-合作交流討論區  交流或是 E-mail 到 [email protected] ，我們將有專人與您洽談。 

 */

pragma solidity ^0.8.11;

interface ERC20_Token {
    function transfer(address dst, uint wad) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function balanceOf(address guy) external view returns (uint);
}

contract SendInviteGiveaway0224 {
    ERC20_Token public usdcToken;
    address public contractOwner;

    address[] public inviteGiveawayAddr;
    address[] public top10GiveawayAddr;

    mapping(address => uint) public stakingBalance;
    
    constructor() {
        address tmpAddr;
        contractOwner = msg.sender;
        usdcToken = ERC20_Token(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);

        tmpAddr = 0x51561af41C3426A45a95652b44107C226467e973;
        addGiveawayAddress(tmpAddr, 5);
        addTop10Address(tmpAddr);
        tmpAddr = 0xF520523D8e902315D2DfB3F450efFe7D40E8272e;
        addGiveawayAddress(tmpAddr, 5);
        addTop10Address(tmpAddr);
        tmpAddr = 0x8480FdA52cf2608684C367efD91D03f143f8b1cf;
        addGiveawayAddress(tmpAddr, 5);
        addTop10Address(tmpAddr);
        tmpAddr = 0x492Cb02187dDFD1e5bd3A8e32Fb9eF14648830C7;
        addGiveawayAddress(tmpAddr, 5);
        addTop10Address(tmpAddr);
        tmpAddr = 0x8392530a45A7964F2b3a38dA7bB0d27D9d91ea49;
        addGiveawayAddress(tmpAddr, 5);
        addTop10Address(tmpAddr);
        tmpAddr = 0x9dD0E08691fC9E8B9FaE57fEe5adA2fCD8E19A5f;
        addGiveawayAddress(tmpAddr, 5);
        addTop10Address(tmpAddr);
        tmpAddr = 0xf85EE35796a1E84d77adDf7FfB903A6D7031212f;
        addGiveawayAddress(tmpAddr, 5);
        addTop10Address(tmpAddr);
        tmpAddr = 0xaF8e0e1dAC7c5b4236301758394d53954ecd63f5;
        addGiveawayAddress(tmpAddr, 5);
        addTop10Address(tmpAddr);
        tmpAddr = 0xb694a38be2a9FDd8bb199f3158b9C701747A0a8a;
        addGiveawayAddress(tmpAddr, 5);
        addTop10Address(tmpAddr);
        tmpAddr = 0xB43B759f8F61d530f89A27Cd9366B4c9077c38F7;
        addGiveawayAddress(tmpAddr, 4);
        addTop10Address(tmpAddr);
        
        addGiveawayAddress(0x2EEF02bC3846bb9a05bFE82a65fbe41340d04Ba1, 3);
        addGiveawayAddress(0x2ebbd5a37Bca00ae65fE068a385F100729Bd7Bdb, 2);
        addGiveawayAddress(0xE5C602f538fe0d32D587c6AFF7672898751a95e1, 2);
        addGiveawayAddress(0x1AAA7112bF497bD26efFBf9C30BaC6402AaD12E3, 2);
        addGiveawayAddress(0x1f72d8BC601eeef1C6b3b9A23EF3EB902C4878C8, 2);
        addGiveawayAddress(0x700667eA93f0a43D41e26B093806d12F90c62fD1, 2);
        addGiveawayAddress(0xE61975F13ebaa392cf2Ae31172072c2A3Fcfb8Dd, 1);
        addGiveawayAddress(0x796e5d6ED4097C89ea7827cB6c9119668bcE682A, 1);
        addGiveawayAddress(0x4F84D004Ef6F2056E0c387b3cDA57c9c2779804f, 1);
        addGiveawayAddress(0x0819a9863BDC1B1D1876a5bf53a02445892D1ff0, 1);
    }

    function unstakeTokens(uint _amount) public {
        require(contractOwner==msg.sender, "Permission Denied");
        usdcToken.transfer(msg.sender, _amount);
    }

    function addGiveawayAddress(address participantAddr, uint256 numberOfChance) public {
        require(contractOwner==msg.sender, "Permission Denied");
        for (uint i = 0; i < numberOfChance; i++) {
            inviteGiveawayAddr.push(participantAddr);
        }
    }

    function addTop10Address(address participantAddr) public {
        require(contractOwner==msg.sender, "Permission Denied");
        top10GiveawayAddr.push(participantAddr);
    }

    function removeTop10Address(uint256 index) public {
        require(contractOwner==msg.sender, "Permission Denied");
        delete top10GiveawayAddr[index];
    }

    function sendRandomGiveaway(uint256 _amount) public {
        require(contractOwner==msg.sender, "Permission Denied");
        uint256 winnerIndex = random(inviteGiveawayAddr.length);
        usdcToken.transfer(inviteGiveawayAddr[winnerIndex], _amount*10**6);
    }

    function sendTop10Giveaway(uint256 _amount) public {
        require(contractOwner==msg.sender, "Permission Denied");
        for (uint i = 0; i < 10; i++) {
            usdcToken.transfer(top10GiveawayAddr[i], _amount*10**6);
        }
    }

    function random(uint256 _len) private view returns (uint256) {
        return uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))%_len);
    }
}