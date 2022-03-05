/**
 *Submitted for verification at polygonscan.com on 2022-03-05
*/

// SPDX-License-Identifier: MIT

// This contract for CorianderDAO.eth Invite Giveaway

// UTC+8 March-04, 2022 Giveaway Contract
 
/**

Join CorianderDAO.eth >> https://discord.gg/mPFb9cHdSK

一個新的潛力項目，
還有很新穎的賦能模式，養成系的項目，讓大家一起建設一個新世界～～

加入連結：https://discord.gg/mPFb9cHdSK

E-mail: [email protected]

獎勵規則如下：
1️. 加入 CorianderDAO 所有人皆可於每日抽 1 USDC，每天抽出 5 位，共 5 USDC。
2️. 邀請 8 人即可成為 @外交小尖兵，每日可以抽 5 USDC，每天抽出 1 位。 
3️. 邀請 20 人即可成為 @外交大使 ，每日可以抽 10 USDC，每天抽出 1 位。

Roadmap 更新 2022.02.23

1.    我們預計三月發行我們的DAO會員NFT，用於募集DAO所需的初始資金。

2.    之後會發行 Coriander Coin其中50% 空投給會員 NFT 持有者，剩下 50% 將定期（暫定每季）空投給 Coriander Coin 持有者。

3.    作為CorianderDAO發展的第一步，我們將推出農地 NFT，會員 NFT 持有者將可優先認購，認購後將成為第一批進 Coriander World 開墾的農民與地主，而每塊農地將可切分為100塊種植地。

4.    每塊種植地可用於種植作物，種植作物須每天澆水、施肥照顧，經過一定時間成熟過後可換取收益。

5.    農地的地主可將其農地出租給其他地主後定期收取租金，也能自己種植作物。

6.    DAO 收益（包含廣告、NFT項目合作、NFT 版費（Royalty Fee） … 組織相關之收益）扣除成本之後80% 回饋給會員NFT 及 Coriander Coin 持有人，20% 捐贈給慈善機構。

7.    我們目前正在徵求商家一起合作，合作商家有機會認購更多我們的會員 NFT，進一步參與 Coriander World 的建設，並得到更多的曝光度，有興趣的可以到 🎗-合作交流討論區  交流或是 E-mail 到 [email protected] ，我們將有專人與您洽談。 

 */

pragma solidity ^0.8.12;

interface ERC20_Token {
    function transfer(address dst, uint wad) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function balanceOf(address guy) external view returns (uint);
}

contract SendUsdcGiveaway0304 {
    ERC20_Token public usdcToken;
    address public contractOwner;
    
    constructor() {
        contractOwner = msg.sender;
        usdcToken = ERC20_Token(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    }

    function unstakeTokens(uint _amount) public {
        require(contractOwner==msg.sender, "Permission Denied");
        usdcToken.transfer(msg.sender, _amount);
    }

    function sendGiveaway() public {
        require(contractOwner==msg.sender, "Permission Denied");
        sendUsdc(0x674aa66718D010fB6BCE15798343B205B8eA7Eb1, 1); // matthew714｜MetaStore#8031 | v2#3428, 1U 
        sendUsdc(0x2fEf657Cb9f666c15DC37A1C9aEDc6171F46b48D, 1); // 狗勾～#9851, 1U
        sendUsdc(0x943B621d74824ba84543118Dc238dF3930396bb1, 1); // Ning | KX#6364, 1U
        sendUsdc(0x72cA5711DfF6905AeBAED56638a9c70141929e7A, 1); // xxivx#8833, 1U
        sendUsdc(0xE36c7F1B24a2A3498ffc4557b88ff5a3D44179EB, 1); // kuzfor3#8224, 1U .
        sendUsdc(0xa7D6c1c8f1B99CBd7A425A8312c8A4C00A3945B9, 5); //  Fifijen#7254, 5U .
        sendUsdc(0xE5C602f538fe0d32D587c6AFF7672898751a95e1, 10); // PowerTech#4165, 10U .
    }

    function sendUsdc(address recipientAddr, uint _amount) public {
        require(contractOwner==msg.sender, "Permission Denied");
        usdcToken.transfer(recipientAddr, _amount*10**6);
    }
}