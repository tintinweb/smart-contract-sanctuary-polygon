// SPDX-License-Identifier: MIT

/*
 ___  ___  ________  ________  ___       ___  ___  ________      
|\  \|\  \|\   __  \|\   ___ \|\  \     |\  \|\  \|\   __  \     
\ \  \\\  \ \  \|\  \ \  \_|\ \ \  \    \ \  \\\  \ \  \|\  \    
 \ \   __  \ \  \\\  \ \  \ \\ \ \  \    \ \   __  \ \  \\\  \   
  \ \  \ \  \ \  \\\  \ \  \_\\ \ \  \____\ \  \ \  \ \  \\\  \  
   \ \__\ \__\ \_______\ \_______\ \_______\ \__\ \__\ \_____  \ 
    \|__|\|__|\|_______|\|_______|\|_______|\|__|\|__|\|___| \__\
                                                            \|__|
*/

pragma solidity ^0.8.7;

import "Ownable.sol";
import "VRFCoordinatorV2Interface.sol";
import "VRFConsumerBaseV2.sol";

contract KQCoolXClonesGiveawayTool is VRFConsumerBaseV2, Ownable {
    uint64 s_subscriptionId;
    address vrfCoordinator = 0xAE975071Be8F8eE67addBC1A82488F1C24858067;
    bytes32 s_keyHash = 0xd729dc84e21ae57ffb6be0053bf2b0668aa2aaf300a2a7b2ddf7dc0bb6e875a8;
    uint32 callbackGasLimit = 400000;
    uint16 requestConfirmations = 3;
    uint32 numWords =  1;
    VRFCoordinatorV2Interface COORDINATOR;
    uint public listLength = 55;

    address[55] public addressList = [
        address(0xc5E49AC5a5D11c8ca65d27309Aaf85d8CE8F8a4A),
        address(0xBF23F63FecEa0235A143a9bd94B8aae36f953B4d),
        address(0xAEc1ef944354faF21DFF3BEe76C2fCA5Ca58b3ce),
        address(0x715cc980013fA23F198a42aFBd9A479FcfFB464E),
        address(0x1440738DB5431b5B8CD0a00E9646A2c96E091f44),
        address(0x09332AC1638F390Af039c37a6B5C9382BE1bcfB8),
        address(0xd9C128EeEaaB4B80FA07C45431F89DAD10dDBF7A),
        address(0x6061098711B4ce3f107A509AC27247375E536D54),
        address(0x23c2477145Bc767e916E12ff6dB2CDe86faB8294),
        address(0x360cb7ebD85Fd8aDaD909BE393f9CDcC378b5cF6),
        address(0x3Ea40A276055DaDED71E326490cF1275F18BEf00),
        address(0xA2f3A2cf12FF3eddcc13a322B2eBe61A7AF5af6E),
        address(0xB5507Aa0Efd9e1B6C343c9eC3f5B4e5C40cEF654),
        address(0x534b8531e362Da97D808ba2ab3959fa2597BeF11),
        address(0xcD54FF0E52A61B6daB8c24D1348116ca3bB522A9),
        address(0x0Ef9D9b1b493069C264b373e1a42e0c8284d7951),
        address(0x785c8D210Ab8888dA6d121faA0a9568f75400B13),
        address(0xD1f25598ce30759F8F86e7e3b07c852bd36b49a7),
        address(0xAa6d90c3589473b278f47cC8586F8d2b9bfF7F29),
        address(0xEbcF567b673a1E1a1358C38B36E7384690dC7353),
        address(0x83Eb1f67E97906e7D21802C28F23f3D0eF16dE9D),
        address(0x31ab42f972841631c139E52Edfa990e67f3cc402),
        address(0x7BAce095602E2BaB41d09a26e0CBCCD13485D9eb),
        address(0xBA7A4c521DfCD18fEB7cdA4B7CA182d739B7A6a0),
        address(0x302DfdfDDb63f92c2c9985B0a6f9276F8697b436),
        address(0x427192C963Ebe7b600693eFE018d9526866398E4),
        address(0x2Cb94DFF679C15B3aEbb8E6beAb6012DA02dbC51),
        address(0xf4aEC459a622CF565De6a5446625E6a7A4f4C490),
        address(0xDDd7629086B612A8CCF8261887A47867419a1A18),
        address(0xd4305CE93d418d0Ee358EBf005425210980D341A),
        address(0x08492eaa6301b71aaBE8c269F03663b6B6a2d116),
        address(0x30d874A055c1A36161BB1cFE9B2feEd7E9930a01),
        address(0x20c350D67184b42d8626f6f38D487e0A08D37D11),
        address(0xb09209db8a7E4077d10A8Aea927CcF65242CFd9c),
        address(0x9D17F4E3f9FF2a6ea31bf75aFf1F23e5649E3976),
        address(0x5DcCd52f8425C4e9b05a90016D43Da64f8b1e472),
        address(0x94BBC2f753C4BF5f760a816560515cEe33d412FA),
        address(0x56fCf7dCa9B452ef252e8D59917AAf95aFcc9D67),
        address(0x19B10a0a9d911f56baD594222028a522B5F2D40c),
        address(0x5ac2379B7664d3729bcf82Db87C7A702Ef93F89b),
        address(0x67FcBC05CBe192abF58931f129992724A48C77B2),
        address(0x2DEC3F3c3f0B0c28F3fEd8003f3804853dc6F2A2),
        address(0x84705E94c98184b2D47026664CFaB2c38ccA1bf9),
        address(0x0B365305E034F8Ef63D39C9ed33fD060e05724dD),
        address(0xd10aF0000e7B124CAf601C87f95056f394aFeBC3),
        address(0x2aBEAd0274aB1304B16b6720019493a42F83b940),
        address(0xbd871A0119e63c410506beD673d3ee68054B869a),
        address(0xba55A4AD8B09C532fD5f330768A5C415e5cd689B),
        address(0xD06cB99d71fF3d6C2A1eE263db9A11dDD65Bd691),
        address(0x82a76439aCe5ba2B4e7830d3953891ab210df59F),
        address(0xA37FD8dCb5bD4bAEC2d1C96A1E3Df8A7901e7364),
        address(0x0Bdf418041922819d3a94D1B0a3b572C6f3C137B),
        address(0xAdfC4C71D50fEe1eC2dAf720Aa0b74A4d9a488f3),
        address(0x8Bb70849269d6Bf1106c0725E120794CA020C605),
        address(0xD520F4Fa8F2104630DCa20e0eC143859931381BE)
    ];

    constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
    }

    event Milked(uint256 indexed requestId, address winner);
    event StrippingTeat(uint256 indexed requestId, string meta);

    function StartStripping(string memory meta) public onlyOwner returns (uint256 requestId) {
        requestId = COORDINATOR.requestRandomWords(s_keyHash,s_subscriptionId,requestConfirmations,callbackGasLimit,numWords);
        emit StrippingTeat(requestId, meta);
    }

    function fulfillRandomWords(uint256 requestId , uint256[] memory randomWords) internal override {
        uint256 index = (randomWords[0] % listLength);
        emit Milked(requestId, addressList[index]);
    }
}