/**
 *Submitted for verification at polygonscan.com on 2023-03-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

 

     function getBankOwner() external view returns (address);

    

    function mint(uint256 amount) external;

    function burn(uint256 amount) external;

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


interface IsoftwareNFT {
         


 struct softwareNftInfo {        
        uint256 tokenid;
        string licenseNo;
        uint256 baseValue;
        uint256 cLFIValue;
        uint256 emissionDate;
        uint256 licensePurchaseDate;
        uint256 licenseExpiryDate;
        uint256 baseTokenEmmission;
        string fileUri;
        address nftHolder;
        bool isAvailable;
    }

    function updateInfo (uint256 id ,string calldata _licenseNo , uint256 _emissionDate , uint256 _baseValue,uint256 _baseTokenEmmission  ,uint256 _licenseExpiryDate, string calldata imageUri_,string calldata metadataUri_) external;

    function tokenURI(uint256 tokenId) external view returns (string memory);

     function burnNft(address [] calldata _nftHolder,uint256 [] calldata id ) external;
     function getUriList(address _address) external view returns (string [] memory);
     function getSoftwareNftInfo(uint256 _tokenId) external view returns(softwareNftInfo memory);
     function safeTransferFrom(address from,address to,uint256 id,uint256 amount,bytes calldata data) external;
     function getBaseTokenEmmission(uint256 _tokenId) external view returns(uint256);
     function getBaseValue(uint256 _tokenId) external view returns(uint256);
     function getTotalSupply() external view returns(uint256);
     function getlicensePurchaseDate(uint256 _tokenId) external view returns(uint256);
     function getlicenseExpiryDate(uint256 _tokenId) external view returns(uint256);
     function getEmmissionDate(uint256 _tokenId) external view returns(uint256);
     function getcLFIValue(uint256 _tokenId) external view returns(uint256);
     function getlicenseNum(uint256 _tokenId) external view returns(string memory);
     function getMintCount() external view returns (uint256);
     function totalSupply() external view returns (uint256);


 }
 contract softwarenftstake  {
    IERC20 public CLFI;
    IERC20 public LFI;
    IsoftwareNFT public nftContract;
    //nftInterface public nftContract;
    address public owner;
    uint256 public contractCount;
    //uint256[] public contractsJoined;
    mapping(address=>uint256) stakedAmount;
    uint256 public p1 = 2;
    uint256 public p2 = 1;
    bool public isTimeBasedReward = true;

    struct stakingContract {
        uint256 contractNumber;
        uint256 nftNumber;
        uint256 emissionDate;
        uint256 baseValue;
        uint256 baseTokenEmission;
        uint256 mimValue;
        address staker;
        bool active;       
    }

    struct rewardDetails {
        uint256 tokenId;
        uint256 index;
        uint256 rewardStart;
        uint256 lastRewardClaim;
        uint256 diff;
        uint256 rewardEnd;
        uint256 currentReward;
        uint256 claimedReward;

    }

 

    mapping(string => uint256) clfiRequiredPerSoftware;  //how much clfi required for each software
    mapping(address => stakingContract) public contractOfStaking; //each users contract details
    mapping(address => mapping(uint256 => rewardDetails)) public stakingRewards; //each  users reward details per contract 
    mapping(address => uint256[]) public contractsJoinedByAddress; // users joined contract's identification number.
    mapping(address=>mapping(uint256=>stakingContract)) stakingContractDetails;
    mapping(address=>uint256) stakingCount; // mapping of count per user staking
    mapping(uint256=>address) stakersByAddress; // mapping of contract number to address of the user

    constructor(
        address _clfi,
        address _lfi,
        address _nftContract
    ) {
        CLFI = IERC20(_clfi);
        LFI = IERC20(_lfi);
       nftContract = IsoftwareNFT(_nftContract);
        owner = msg.sender;
    }
    function viewClfiValue(uint256 _tokenId) public view returns(uint256){
        return nftContract.getcLFIValue(_tokenId);
    }

function stake(uint256 _tokenId ) public {
  
        require(
        CLFI.balanceOf(msg.sender) >= nftContract.getcLFIValue(_tokenId),
        "not enough amount for staking");      
    nftContract.safeTransferFrom(msg.sender, address(this), _tokenId , 1 , '' );
        CLFI.transferFrom(
            msg.sender,
            address(this),
            nftContract.getcLFIValue(_tokenId)
        );
       uint256 index =stakingCount[msg.sender];
        stakingContractDetails[msg.sender][index] = stakingContract(
           index,
          _tokenId,
          nftContract.getEmmissionDate(_tokenId),
          nftContract.getBaseValue(_tokenId),
          nftContract.getBaseTokenEmmission(_tokenId),
          mimValue(_tokenId),
          msg.sender,
          true
         );
         stakingRewards[msg.sender][index] =  rewardDetails(_tokenId,index,block.timestamp,block.timestamp,0,block.timestamp + 15 minutes,0,0);
         stakingCount[msg.sender]++;
         contractsJoinedByAddress[msg.sender].push(index);
        
         stakersByAddress[contractCount] =msg.sender;
         contractCount++;

    }

mapping(address=>mapping(uint256=>uint256)) prevReward; // mapping from user address to contract count
     uint256 public t1;
    function updateRewardForStakers() public {
   
        require(owner==msg.sender,"Only Owner Can Update");
        require( block.timestamp - t1   >=  60 , " 2 min not completed");
        for(uint256 i=0;i<contractCount;i++){
            for(uint256 j=0;j<stakingCount[stakersByAddress[i]];j++){
                uint256 stakingPeriod;
                 prevReward[stakersByAddress[i]][i] = stakingRewards[stakersByAddress[i]][j].currentReward;
                 uint reward=  prevReward[stakersByAddress[i]][i];
                stakingPeriod = (block.timestamp -stakingRewards[stakersByAddress[i]][j].lastRewardClaim)/2;
                stakingRewards[stakersByAddress[i]][j].currentReward =mintProduction(stakersByAddress[i],j)*stakingPeriod+reward;
            }

            t1 = block.timestamp ;

        }
    }

function mintProduction(address user,uint256 index) public view returns(uint256 ){
uint256 baseTokenEmission =(stakingContractDetails[user][index].baseTokenEmission);
uint256 _mimValue = mimValue(stakingRewards[user][index].tokenId) ;
uint256 mintProductionValue;
if(p2>p1){
mintProductionValue = (baseTokenEmission * ( _mimValue - carryingCapacity())  * p2/p1 ) ;

}
else{
mintProductionValue =( baseTokenEmission * ( _mimValue - carryingCapacity()) );
}
    return (mintProductionValue);
}

function ShowmintProduction(uint256 _index) public view returns(uint256 ,uint256){
uint256 baseTokenEmission =(stakingContractDetails[msg.sender][_index].baseTokenEmission);
uint256 _mimValue = mimValue(stakingRewards[msg.sender][_index].tokenId) ;
uint256 mintProductionValue;
if(p2>p1){
mintProductionValue = (baseTokenEmission * ( _mimValue - carryingCapacity())  * p2/p1 );

}
else{
mintProductionValue = (baseTokenEmission * ( _mimValue - carryingCapacity()) ) ;
}
    return (mintProductionValue, baseTokenEmission);
}


    function claim(uint256 _index) public {
        uint256 amount = stakingRewards[msg.sender][_index].currentReward;
        require(amount > 0, " amount greater than 0");
        LFI.transfer(msg.sender, amount);
        stakingRewards[msg.sender][_index].diff = block.timestamp - stakingRewards[msg.sender][_index].lastRewardClaim ;
        uint256 claimed =stakingRewards[msg.sender][_index].claimedReward;
        stakingRewards[msg.sender][_index].claimedReward = amount+claimed;
        stakingRewards[msg.sender][_index].currentReward=0;
        prevReward[msg.sender][_index] = 0 ;
        stakingRewards[msg.sender][_index].lastRewardClaim =block.timestamp;
        
    }

function mintProductionReward(uint256 index) public view returns(uint256 ){
uint256 baseTokenEmission =(stakingContractDetails[msg.sender][index].baseTokenEmission);
uint256 _mimValue = mimValue(stakingRewards[msg.sender][index].tokenId) ;
uint256 mintProductionValue;
if(p2>p1){
mintProductionValue = (baseTokenEmission * ( _mimValue - carryingCapacity())  * p2/p1) ;

}
else{
mintProductionValue =( baseTokenEmission * ( _mimValue - carryingCapacity()));
}
    return (mintProductionValue);
}


function setTimeBasedReward( bool  _isTimeBasedReward) public {
    require(owner==msg.sender,"NOT A OWNER");
    isTimeBasedReward =_isTimeBasedReward;
}

function setValue ( uint256 _p1 , uint256 _p2) public  {
p1 = _p1;
p2 = _p2;

}

function mimValue(uint256 _tokenId) public view  returns(uint256 ){
uint256 emissionDate = nftContract.getEmmissionDate(_tokenId);
uint256 currentDate = block.timestamp  ;
uint256 diff = currentDate - emissionDate ;
uint256 cal = 0.0002778 * 10e8;
uint256 mimValue_ = nftContract.getBaseValue(_tokenId) * (10e8 - (diff * cal)) ;

return (mimValue_ );
}

function ShowMimValue(uint256 _tokenId) public view  returns(uint256 , uint256){
uint256 emissionDate = nftContract.getEmmissionDate(_tokenId);
uint256 currentDate = block.timestamp  ;
uint256 diff = currentDate - emissionDate ;
uint256 cal = 0.0002778 * 10e8;
//uint256 cal = 0.0002778 * 10e8;
uint256 mimValue_ = nftContract.getBaseValue(_tokenId) * (10e8 - (diff * cal)) ;

return (mimValue_ , diff);
}

function  carryingCapacity() public view returns(uint256){
    uint256 cc = (15  * ( nftContract.totalSupply() / 250000));
     return cc;

}

function showcarryingCapacity() public view returns(uint256){
uint256 cc = (150 *100 * nftContract.totalSupply()/25) ;
     return cc;
}

function nftHashRate() public view returns(uint256){
    return ((3695 *  nftContract.getTotalSupply()) );
}

function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

}