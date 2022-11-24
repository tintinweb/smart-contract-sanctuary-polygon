/**
 *Submitted for verification at polygonscan.com on 2022-11-22
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

    function balanceOf(address tokenOwner)
        external
        view
        returns (uint256 balance);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);
}

interface ERC721 {
    function mint(address to, uint256 tokenId) external;
}

interface CubixPackSell {
    function currentId() external view returns (uint256);
    
    function totalNFTs() external view returns (uint256);

    function ownerAddress() external view returns (address payable);

    function packBought(uint256 packId) external view returns (uint256);

    function usersMapId(address _address) external view returns (address);

    function usersMapParentId(address _address) external view returns (address);

    function usersMapLevel(address _address) external view returns (uint256);

    function usersMapIncome(address _address) external view returns (uint256);

    function usersMapBusinessIncome(address _address)
        external
        view
        returns (uint256);

    function usersMapCreatedDate(address _address)
        external
        view
        returns (uint256);
}

contract CubixPackSellV2 {
    using SafeMath for uint256;
    struct UserStruct {
        address id;
        address parentId;
        uint256 level;
        uint256 income;
        uint256 businessIncome;
        uint256 createdDate;
    }

    struct PackStruct {
        uint256 id;
        uint256 price;
        uint256 nfts;
        uint256 sportId;
        uint256 buyLimit;
    }

    struct Limits {
        uint256 targets;
        uint256 directCommision;
    }

    uint256 public decimalsValue = 10**18;

    uint256 public currentId = 0; // done
    uint256 private maxLoopCounter = 500;
    address payable public ownerAddress; // done

    mapping(uint256 => uint256) public packBought; // done
    mapping(uint256 => Limits) public levelsMap; // done
    mapping(uint256 => PackStruct) public packsMap; // done
    mapping(address => UserStruct) public usersMap;
    mapping(address => uint256) public deposit;
    mapping(address => uint256) public depositOfCubix;

    ERC20 usdt;
    ERC20 cubixToken;
    ERC721 nft;
    CubixPackSell cubixPackSellV1;

    uint256 public totalNFTs = 0; // done
    uint256 maxLevel = 14;
    address[] public partners; // done
    uint256[] public partnersPercentage; // done

    event ChangeLevel(address indexed _address, uint256 Level);

    event RegUserEvent(
        address indexed userAddress,
        uint256 indexed userId,
        address referrer,
        uint256 packId,
        uint256 businessIncome,
        uint256 Time
    );
    event NFTMintEvent(
        address indexed userAddress,
        uint256 indexed nftId,
        uint256 packId,
        uint256 Time
    );
    event RefProfitForLevelEvent(
        address indexed profitFrom,
        uint256 totalIncome,
        uint256 businessIncome,
        address userAddress,
        uint256 level,
        uint256 amount,
        uint256 packId,
        uint256 percentage,
        uint256 incomeType
    );
    event BuyPackEvent(
        address indexed userAddress,
        uint256 packId,
        uint256 businessIncome,
        uint256 Time
    );
    event ClaimEvent(address indexed userAddress, uint256 amont, uint256 Time);

    constructor(
        address _nftAddress,
        address _cubixTokenAddress,
        address _cubixPackSellV1
    ) {
        ownerAddress = payable(msg.sender);
        nft = ERC721(_nftAddress);
        cubixToken = ERC20(_cubixTokenAddress);
        cubixPackSellV1 = CubixPackSell(_cubixPackSellV1);

        setLevelsMap();
        setPartnerPercentage();
        setPacks();
    }

    function copyDataFromV1() external onlyOwner {
        currentId = cubixPackSellV1.currentId();
        totalNFTs = cubixPackSellV1.totalNFTs();

        packBought[1] = cubixPackSellV1.packBought(1);
        packBought[2] = cubixPackSellV1.packBought(2);
        packBought[3] = cubixPackSellV1.packBought(3);
        packBought[4] = cubixPackSellV1.packBought(4);
        packBought[5] = cubixPackSellV1.packBought(5);
        packBought[6] = cubixPackSellV1.packBought(6);
        packBought[7] = cubixPackSellV1.packBought(7);
        packBought[8] = cubixPackSellV1.packBought(8);
    }

    function copyUser(address[] calldata existingAddress) external onlyOwner {
        for (uint256 index = 0; index < existingAddress.length; index++) {
            address _address = existingAddress[index];
            if (usersMap[_address].id == address(0)) {
                UserStruct memory userStruct;

                userStruct.id = cubixPackSellV1.usersMapId(_address);
                userStruct.parentId = cubixPackSellV1.usersMapParentId(
                    _address
                );
                userStruct.level = cubixPackSellV1.usersMapLevel(_address);
                userStruct.income = cubixPackSellV1.usersMapIncome(_address);
                userStruct.businessIncome = cubixPackSellV1
                    .usersMapBusinessIncome(_address)
                    .div(1000000)
                    .mul(decimalsValue);
                userStruct.createdDate = cubixPackSellV1
                    .usersMapCreatedDate(_address)
                    .div(1000000)
                    .mul(decimalsValue);

                usersMap[_address] = userStruct;
            }
        }
    }

    function setLevelsMap() internal {
        levelsMap[1] = Limits(30 * decimalsValue, 14);
        levelsMap[2] = Limits(5000 * decimalsValue, 17);
        levelsMap[3] = Limits(10000 * decimalsValue, 20);
        levelsMap[4] = Limits(20000 * decimalsValue, 22);
        levelsMap[5] = Limits(40000 * decimalsValue, 24);
        levelsMap[6] = Limits(80000 * decimalsValue, 26);
        levelsMap[7] = Limits(160000 * decimalsValue, 28);
        levelsMap[8] = Limits(320000 * decimalsValue, 30);
        levelsMap[9] = Limits(640000 * decimalsValue, 32);
        levelsMap[10] = Limits(1280000 * decimalsValue, 33);
        levelsMap[11] = Limits(2560000 * decimalsValue, 34);
        levelsMap[12] = Limits(5120000 * decimalsValue, 35);
        levelsMap[13] = Limits(1024000 * decimalsValue, 36);
        levelsMap[14] = Limits(20480000 * decimalsValue, 37);
    }

    function setPartnerPercentage() internal {
        // partners starts
        partners.push(msg.sender);
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
        packsMap[1] = PackStruct({
            id: 1,
            price: 30 * decimalsValue,
            nfts: 1,
            sportId: 1,
            buyLimit: 10500
        });
        packsMap[2] = PackStruct({
            id: 2,
            price: 150 * decimalsValue,
            nfts: 6,
            sportId: 1,
            buyLimit: 71500
        });
        packsMap[3] = PackStruct({
            id: 3,
            price: 250 * decimalsValue,
            nfts: 11,
            sportId: 1,
            buyLimit: 51000
        });
        packsMap[4] = PackStruct({
            id: 4,
            price: 500 * decimalsValue,
            nfts: 25,
            sportId: 1,
            buyLimit: 40000
        });
        packsMap[5] = PackStruct({
            id: 5,
            price: 1000 * decimalsValue,
            nfts: 57,
            sportId: 1,
            buyLimit: 10000
        });
        packsMap[6] = PackStruct({
            id: 6,
            price: 2500 * decimalsValue,
            nfts: 153,
            sportId: 1,
            buyLimit: 5000
        });
    }

    modifier onlyOwner() {
        require(msg.sender == ownerAddress, 'Only owner');
        _;
    }

    modifier onlyFounder() {
        require(msg.sender == ownerAddress, 'Only onlyFounder');
        _;
    }
}