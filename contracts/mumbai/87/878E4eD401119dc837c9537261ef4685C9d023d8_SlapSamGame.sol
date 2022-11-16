/**
 *Submitted for verification at polygonscan.com on 2022-11-15
*/

/**
 *Submitted for verification at BscScan.com on 2022-08-28
 */

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract SlapSamGame {
    address payable ownerAddress;
    address rewardWallet;
   
    //lotto contract
    uint256 gameStartTime;
    IERC20 busd;
    uint256 lastId = 1;
    uint256 nftId = 1;

    //Nft contract
   
    address nftContract;
    SlapNftInterface NftMint;
    uint16 constant percentDivider = 10000;
    
   
//////////////////slap/////////////////////

uint256 totalNFTQuantity = 10000;


uint256 maxMintNFTPerWallet = 5; 

struct Player {   
        address userAddress;
        uint256 playerId;
        uint256 totalReward;
        uint256 mintingCount;
        uint256 timestamp;
    }

    struct MintingLevel{
        uint256 start;
        uint256 end;
        uint256 amount;
    }

//////////////////////slap/////////////////

    mapping(address => Player) public player;
    mapping(uint256 => MintingLevel) public MintingLevels;

    //mapping (uint => bool) public isResultDeclared;

   
    event nftBuy(uint256 nftId,uint256 amount,uint256 timestamp,address walletAddress);
   

    constructor(address payable _ownerAddress,address _rewardWallet)
    {

        MintingLevels[0].start = 1;
        MintingLevels[0].end = 2;
        MintingLevels[0].amount = 0;


        MintingLevels[1].start = 3;
        MintingLevels[1].end = 4;
        MintingLevels[1].amount = 0.01 ether;
        
        for(uint256 i = 2; i<9;i++)
        {
        MintingLevel memory _MintingLevel = MintingLevel({
                start: MintingLevels[i-1].end+1,
                end: MintingLevels[i-1].end+2,
                amount: MintingLevels[i-1].amount*2
            });

            MintingLevels[i] = _MintingLevel;
        }

        MintingLevels[9].start = 19;
        MintingLevels[9].end = 20;
        MintingLevels[9].amount = 0.09 ether;

        busd = IERC20(0x1FAdc992EA93CcCEbE3F965e72DF9c7d0F4035c9);
        nftContract = 0xdC6604Bf63108Cc3E64c53A4766CcfBd84Ba173B;
        

        NftMint = SlapNftInterface(nftContract);
        ownerAddress = _ownerAddress;
        rewardWallet = _rewardWallet;
        

        Player memory _Player = Player({
                userAddress: msg.sender,
                playerId: lastId,
                totalReward: 0,
                mintingCount : 1,
                timestamp : block.number
            });

            player[msg.sender] = _Player;

            lastId++;
    }

   
    function buyNft(uint256 price) public payable {

        require(player[msg.sender].mintingCount < maxMintNFTPerWallet,"Every wallet can buy upto 5 nft's");

        require(nftId < totalNFTQuantity,"Allready sold all nft");

        uint256 _amount = 0;

        for(uint256 i = 0; i<=9; i++)
        {
            if(nftId >= MintingLevels[i].start  && nftId <= MintingLevels[i].end)
            {
                _amount = MintingLevels[i].amount;
            }
        }
        require(price ==  _amount,"Invalid amount");
        
       if(_amount > 0)
       {
        payable(ownerAddress).transfer(_amount/2);
        
        payable(rewardWallet).transfer(_amount/2);
       }
        uint256 _nftId =  nftId++;
        NftMint.mintReward(msg.sender,_amount);

        if (player[msg.sender].playerId == 0) {
            Player memory _Player = Player({
                userAddress: msg.sender,
                playerId: lastId,
                totalReward: 0,
                mintingCount : 1,
                timestamp : block.number
            });

            player[msg.sender] = _Player;
            lastId++;
        }
        else
        {
            player[msg.sender].mintingCount++;
        }

        emit nftBuy(_nftId,_amount,block.number,msg.sender);
    }

    
    function setOwnerAddress(address payable _address) public {
        ownerAddress = _address;
    }

    function setRewardWallet(address _address) public {
        require(msg.sender == ownerAddress, "Only owner can set authaddress");
        rewardWallet = _address;
    }

   
    function getPlayerDetails(address _address)
        public
        view
        returns (Player memory)
    {
        return player[_address];
    }


   
}

// contract interface
interface SlapNftInterface {
    // function definition of the method we want to interact with
    function mintReward(address to,uint256 nftPrice) external;

    function ownerOf(uint256 tokenId) external view returns (address);

    function getNftMintedDate(uint256 nftId) external view returns(uint256);

    function getNftNftPrice(uint256 nftId) external view returns(uint256);
}