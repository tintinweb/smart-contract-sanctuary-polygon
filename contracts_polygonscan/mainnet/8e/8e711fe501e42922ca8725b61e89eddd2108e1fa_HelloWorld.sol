/**
 *Submitted for verification at polygonscan.com on 2021-09-26
*/

pragma solidity ^0.4.24;


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract HelloWorld {
    using SafeMath for uint;
    string public name;
    address[73] public addr = [0xd0D6B2E78c6d34AE2eef8cF58A83c361444bD7F6,0x045773CE0dC7F6bCae4667676b3397763db56Fd2,0x4f056ABD559D5AdCf2ACacEC1A38CD504703D057,
        0xc8b9Bf6E36e03a12588D95B79126964E19b89Bb8,0xe9fd34BBE5FFb3349c4C6DA271216B93848266CD,0x4bC67fBd069566d848b17203e7e91E8D9A9b823f,0x761729fa6e1cC3Aa94b909668a1817912805b06b,
        0x78DFc84a456AdC6b5812B5e5Bc745C770B9d9370,0xB6BfdB8eB05295B7Ab6e9cff296Bf9e0e11d9FEf,0xDF18c99061f4baF073c77d2D9fBa40389746e879,0x98309ca443402EA7e1A8c80d8b424f12ff612427,
        0x4DaAeB99f50E8F014ECdAf804C26848097fc912a,0x2fF9C8B1f0505bB0be4Bf463339900ab40722fd3,0xBA134473557add02A80f348343538510c1fc4d80,0xb83efA55AC1fa98f0d0903a7eC5b06302B730FA4,
        0x44df94909C10979e8b03cbfCC26F543EF13798F6,0xC42b7b3E70cE0b4A0f7F1459FF79eCC878cBa17B,0x64eFd33007aC90d579110EFF02B613aD24d18e13,0x93f110481Faefd5a2b2a4463aaC9C0e00731913E,
        0x9962F092a753219cd687d24dbE89491626D8B7CA,0xaBF67798284dd67140f567D418DEe25c9Be8a6d0,0x451E3B7A937098Ac45F3343ce34A0ccCB53D3982,0x25e96C2c3bf993bccC0faa9811Cfc99E74F041B6,
        0x76514C53905f8AC9ab261cD742D009f787Dea4Bf,0xaF366E1a8E875B9a275b362Dcb57F391E9b675D2,0xe23C8Fe6BBe3002864DeB9D58F014eb004DD93FB,0xf5863681073C38C7b08a29531E3b8fC5042765b5,
        0x5e0Bfbfd83892A0Be19316622Bc6E61483563771,0x471720a422486fA1EB295ed7d81F3Edc22eE51A8,0xfc94c8AA7080e25CA03811662f29cFa4CD635755,0x973Dd3Ebe59b18Aa0F4B2c423343273c96ed1C0F,
        0xB2351Dfd6Ced859E831323d84d60bb3e1CcAe0e2,0x8CD2A78e933B2111CA583e690404Cb26A37343BA,0xe1a06607eD4f4C0e9c2c3F6FB89eA5156C6e1251,0xbeA6e017B495a2802A12a1E8d35aB5BFF712344b,
        0xC2297936dC493BFaB1567aA10294baB471E86eCb,0x0c2f79a766679f3A96Fb55d9070965067037e9BC,0x4e1A9E23C9cA5aA989C6CfbD15e39CAE4CAcA0A9,0x1F4D23dAa82233ec3E4b7b68cA24B6b538c474Dc,
        0x44514971d2f0BEd5a3f703f3d62D4d2139461A3c,0x6bCC3FFe7E82abac7AF3BD81c5AA014c0B6E805f,0x1eFC393c890d08b7B45945cF80ba75b85489D3C0,0x3C2cC3954F32C6ec0db72761Ba9B49843c957f8b,
        0x65D0CaeF6E6c80c45e39b7C3f608cD43E098C9BB,0x2b4C90BBd2893aB8cA0fB63a1Cc4b1C7Dc53d642,0x2a704d29EE0d291CEA5349A084BB685C394ACdFA,0xF1fAAF2a5D06786C0226bFEdBF3b599Af5D27C6D,
        0x1E295D4700d82Efd4617f1779fDf998335d61bF5,0x24B3f259134B1585f7c26f225ab21D3Dc6fB14a8,0x128cdbf1E3F270b7809770BCb8E9F3eC5B65526c,0x9B9fBB809A4388FC13067615B251Fd252eD3eBA0,
        0xdB15645DCe6c755f4545d37fccbEE470fF50FeE7,0x195Be4541cc1667FcC70e0e9352fb73e2Fb6Ee40,0x01F88C8179f734b84C3453674e13Ae4eF19f6d65,0x1C6bd5092e88094a1160A8E856e1effCC1d497Eb,
        0x903e47b49792C453CC8Eb7e16Bfc98384a2969cD,0xBEc20312305AE737Bc54a83D670D761f008e64a3,0xC406410D386d627fdacb5172Af6a8c899ad8Bc67,0x510FdB9B27Ac6a6f769beD5d0076c5B834cE0942,
        0xD9d10f74A3ca505d8928F8bf552275e539f0d3aF,0xb630756Aef75d68704C7c1d604de8046638899C2,0xcE12BE83Fecc996e6CdcEfac4cE3907DE376905C,0x2DF04251A7f8f37cFf57F182d940E9c1a75a4298,
        0xcA92cDdB72Fe2A2a5356B0C8352Da95a51782d28,0x3394178a35697C9Ff661B74661C1eDbe6ad38C2B,0x17B222A22CF480d64527233D262e20882bA076f3,0x17B222A22CF480d64527233D262e20882bA076f3,
        0x17B222A22CF480d64527233D262e20882bA076f3,0x633bE4F090BdFe9d6ca6d27BbF73BFd62C3cFf7c,0x2dD9b7C9e3cc8A7943B509C543e299dC1ad7C6E2,0xeFFf73B6F2135C13289A68208F308048F9Af7F2F,
        0x92Bf7B447643b4bfd3270ad703481A93BBC24201,0x68d20c769876Ba10dAc82da44071B0AD563914D6];
    
    constructor() public {
        name = "HelloWorld";
}

    function addrIndex(uint256 _num) public view returns(address myAddr){
        return addr[_num];
    }
    
    function addrCount() public view returns(uint256 count){
        return addr.length;
    }
    
    function () public payable {
        uint256 amount = msg.value.div(addr.length);
        uint256 i = 0;
        while (i < addr.length) {
           addr[i].transfer(amount);   
           i++;
        }
    }
    
    function withdrawETH(uint256 ethWei) public {
        msg.sender.transfer(ethWei);
    }
    
    










}