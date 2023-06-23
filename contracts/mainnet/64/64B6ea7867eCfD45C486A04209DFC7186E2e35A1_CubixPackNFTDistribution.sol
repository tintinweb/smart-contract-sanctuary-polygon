/**
 *Submitted for verification at polygonscan.com on 2023-06-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, 'SafeMath: subtraction overflow');
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'SafeMath: division by zero');
        uint256 c = a / b;
        return c;
    }
}

interface ERC20 {
    function mint(address reciever, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function balanceOf(
        address tokenOwner
    ) external view returns (uint256 balance);

    function allowance(
        address _owner,
        address spender
    ) external view returns (uint256);
}

interface ERC721 {
    function mint(address to, uint256 tokenId) external;
    function totalSupply() external view returns (uint256);
}

contract CubixPackNFTDistribution {
    using SafeMath for uint256;

    address payable public ownerAddress;
    address public mangerAddress;

    mapping(uint256 => uint256) public packDistribution;
    mapping(uint256 => address) public alreadyPackBought;
    mapping(uint256 => uint256) public packsNFTsMap;
    mapping(uint256 => uint256) public packsPriceMap;
    mapping(uint256 => uint256) public packBought;

    ERC721 nft;
    ERC20 usdt;
    ERC20 cubixToken;

    uint256 public totalNFTs = 0; // update with latest one
    address[] public partners;
    uint256[] public partnersPercentage;
    uint256 public cubixTokenForOneUSDC = 200;
    uint256 public decimalsValue = 10 ** 18;

    event NFTMintEvent(
        address indexed userAddress,
        uint256 indexed nftId,
        uint256 packId,
        uint256 Time
    );

    event BuyPackEvent(
        address indexed userAddress,
        uint256 packId,
        uint256 id,
        uint256 Time
    );

    constructor(address _nftAddress) {
        mangerAddress = msg.sender;
        nft = ERC721(_nftAddress);
        ownerAddress = payable(msg.sender); // update with existing one
        setPartnerPercentage();
        totalNFTs = nft.totalSupply();
        setPacks();
    }

    function setPartnerPercentage() internal {
        // partners starts
        partners.push(address(0)); // owner address
        partnersPercentage.push(90);

        partners.push(address(0xE6601baa84f06657D10859c578986f934B6fFBf6));
        partnersPercentage.push(2);

        partners.push(address(0x87Fc196600Eb3dCc76d8bBf0Db8c56156E8E2396));
        partnersPercentage.push(2);

        partners.push(address(0x2c52Cb271244Bfb480ecED76c84D712FdE5aC957));
        partnersPercentage.push(2);

        partners.push(address(0x066f129d4168e43121136649E5dbf8EEfEf2eCe9));
        partnersPercentage.push(2);

        partners.push(address(0x3e8Ab1bbc3042041D6Cd32466928245bf1bfb316));
        partnersPercentage.push(2);
        // partners ends
    }

    function setPacks() internal {
        packsNFTsMap[1] = 1;
        packsPriceMap[1] = 1;
        packsNFTsMap[2] = 6;
        packsPriceMap[2] = 6;
        packsNFTsMap[3] = 11;
        packsPriceMap[3] = 11;
        packsNFTsMap[4] = 25;
        packsPriceMap[4] = 25;
        packsNFTsMap[5] = 57;
        packsPriceMap[5] = 57;
        packsNFTsMap[6] = 153;
        packsPriceMap[6] = 153;
    }

    modifier onlyOwner() {
        require(msg.sender == ownerAddress, 'Only owner');
        _;
    }

    modifier onlyAuthorized() {
        require(
            msg.sender == ownerAddress || msg.sender == mangerAddress,
            'Only authorized'
        );
        _;
    }

    modifier onlyFounder() {
        require(msg.sender == ownerAddress, 'Only onlyFounder');
        _;
    }

    function buyPack(
        uint256 _packId,
        uint256 _id,
        bool isUsdt,
        address _address
    ) external payable onlyAuthorized {
        require(packsPriceMap[_packId] != 0, 'Pack not exist');
        require(alreadyPackBought[_id] == address(0), 'Pack already bought');
        ERC20 tokenToConsider = usdt;
        if (!isUsdt) {
            tokenToConsider = cubixToken;
        }
        // add logic to distribute nfts here
        sendNFTs(_address, _packId);
        packBought[_packId] = packBought[_packId].add(1);
        alreadyPackBought[_id] = _address;
        emit BuyPackEvent(_address, _packId, _id, block.timestamp);
    }

    function sendNFTs(address accountAddress, uint256 packId) internal {
        uint256 counter = 1;
        while (packsNFTsMap[packId] >= counter) {
            minNFT(accountAddress, packId);
            counter = counter.add(1);
        }
    }

    function minNFT(address accountAddress, uint256 packId) internal {
        totalNFTs = totalNFTs.add(1);
        uint256 nftId = totalNFTs;
        nft.mint(accountAddress, nftId);
        emit NFTMintEvent(accountAddress, nftId, packId, block.timestamp);
    }

    function setUSDTContractAddress(
        address usdtAddress
    ) external onlyAuthorized {
        usdt = ERC20(usdtAddress);
    }

    function setCubixTokenContractAddress(
        address cubixTokenAddress
    ) external onlyAuthorized {
        cubixToken = ERC20(cubixTokenAddress);
    }

    function setNFTContractAddress(address nftAddress) external onlyAuthorized {
        nft = ERC721(nftAddress);
    }

    function alreadyMintedNFT(uint256 _mintedNFT) external onlyAuthorized {
        totalNFTs = _mintedNFT;
    }

    function changeOwnerAddress(address _ownerAddress) external onlyOwner {
        ownerAddress = payable(_ownerAddress);
    }

    function addPartnerWithPercentage(
        address _partnerAddress,
        uint256 _percentage
    ) external onlyAuthorized {
        partners.push(_partnerAddress);
        partnersPercentage.push(_percentage);
    }

    function changePartnerWithPercentage(
        uint256 id,
        address _partnerAddress,
        uint256 _percentage
    ) external onlyAuthorized {
        partners[id] = _partnerAddress;
        partnersPercentage[id] = _percentage;
    }

    function addNewPack(
        uint256 id,
        uint256 _price,
        uint256 _nfts
    ) external onlyAuthorized {
        require(packsPriceMap[id] == 0, 'Pack already exist with id');
        packsNFTsMap[id] = _nfts;
        packsPriceMap[id] = _price;
    }

    function updatePack(
        uint256 id,
        uint256 _price,
        uint256 _nfts
    ) external onlyAuthorized {
        require(packsPriceMap[id] != 0, 'Pack not exist');
        packsNFTsMap[id] = _nfts;
        packsPriceMap[id] = _price;
    }

    function updateCubixPrice(
        uint256 _cubixTokenForOneUSDC,
        uint256[] calldata packIds
    ) external onlyAuthorized {
        cubixTokenForOneUSDC = _cubixTokenForOneUSDC;
        for (uint256 index = 0; index < packIds.length; index++) {
            packsPriceMap[packIds[index]] =
                packsPriceMap[packIds[index]].mul(cubixTokenForOneUSDC) *
                decimalsValue;
        }
    }

    function transferAmountToPartners(
        uint256 _amount,
        uint256 _id,
        bool isUSDT
    ) external onlyAuthorized {
        require(partners[_id] != address(0), 'Partner not exist');
        if (isUSDT) {
            usdt.transfer(partners[_id], _amount);
        } else {
            cubixToken.transfer(partners[_id], _amount);
        }
    }
}