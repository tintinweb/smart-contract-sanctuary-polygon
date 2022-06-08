/**
 *Submitted for verification at polygonscan.com on 2022-06-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

interface IERC20 {
   
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

   
    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function burn(uint256 amount) external;
}
interface IERC721  {
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function transfer(address to, uint256 amount) external returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract BronStreamPlatform is Ownable, ReentrancyGuard  {
    using SafeMath for uint256;
     address public treasury;
     IERC721 public nftContract;
     IERC20 public tokenContract;
     uint256 uploadFee = 10**18;
     uint256 reviewFee = 10**18;
     uint256 contentWatchFee = 10**18 ;
     uint256 contentId = 1;
     uint256 streamId = 1;
     uint256 playlistId =1;
     /* STAKING REWARDS CLAIMED */
     uint256 internal totalRewardsClaimed;
     uint256 private constant ONE_MONTH_SEC = 2592000;

     address burnAddress=0x000000000000000000000000000000000000dEaD;

   struct User
   {
       uint256 reward;
       uint256 bronSpend;
       uint256 totalWatchMinute;
       uint256 playgames;
   }  

   struct StakeNfts
   {
        uint256 startTime;
        uint256 endTime;
        address owner;
        bool collected;
        uint256 claimed;
   }

   struct Contibutor
   {
       uint256 bronSpend;
       uint256 comments;
       uint256 review;
       uint256 reward;
       uint256 [] playlsistIds;
   }
    struct Partner
    {
        uint256 reward;
        uint256 bronSpend;
        bool allowed;
        uint256 watchtime;
        uint256[] contentIds;
        uint256[] streamIds;
    }
    struct Content
    {
        address wallet;
        string name;
        uint256 contentId;
        uint256 totalViews;
        uint256 review;
        uint256 avgRanking;  
        uint256 totalStar; // star should to be given 1 to 5        
    }
    
    struct Stream
    {
        address wallet;
        string name;
        uint256 streamId;
        uint256 totalWatchMinute;  
        uint256 startTime; 
        uint256 totalview;   
    }
    struct PlayList
    {
        string name;
        uint256[] conentIds;
    }

    /* Staking struct */
    struct stakes{
        address owner;
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        uint256 months;
        bool collected;
        uint256 claimed;
    }
    /* Event for Staking */
    event StakingUpdate(
        address wallet,
        uint256 amount,
        uint256 startTime,
        uint256 endTime,
        bool collected,
        uint256 claimed
    );
    /* Event when APY is set */
    event APYSet(
        uint256[] APYs
    );    
    event UploadContent(uint256 uploadId, address creator, string name);
    event ReviewContent(uint256 id,address contributor, uint256 stars);
    event StartStream(uint256 id, address creator, uint256 startTime,string name);
    event WatchStream(uint256 id, address user,uint256 watchtime);
    event WatchContent(uint256 id, address user,uint256 totalviews );
    event CreatePlaylist(uint256 id,address user,uint256[] contentids );
    event PlayGame(uint256 gameid,address user );


     mapping (address=> StakeNfts) public stakeNftsDetail;
     mapping (uint256 => Stream ) public streamDetail;
     mapping(address => Partner) public  creator;
     mapping(address=>Contibutor )public contibutorDetails;
     mapping (uint256 => Content ) public contentDetail;
     mapping(address => mapping(uint256=> PlayList)) public  playListDetail;
     mapping(address=> mapping(uint256=> bool) ) public isReviewd;
     mapping(address=>User)public UserDetail;
    
    /* Mapping of User wallet address to its stakes */
     mapping(address=>stakes[]) public Stakes;
     /* Total number of stake vault user have */
     mapping(address=> uint256) public userstakes;
     /* APY ACCORDING TO THE MONTHS */
     mapping(uint256=>uint256) public APY;


     
     constructor(IERC721 _nftContract,IERC20 _tokenContract, address treasuryAddress)
     {
         nftContract=_nftContract;
         tokenContract=_tokenContract;
         treasury = treasuryAddress;
     }

    function handlePayment(uint256 amount) internal {
    uint256 treasuryAmount = (amount.mul(90)).div(100);
        tokenContract.transfer(treasury,treasuryAmount);
        //burning 10%
     //   tokenContract.burn(amount.sub(treasuryAmount));
       tokenContract.transfer(burnAddress,amount.sub(treasuryAmount));
    }

     function uploadContent(string memory _name ) public 
     {
        require(creator[msg.sender].allowed==true,"you not have permission to upload content");
        tokenContract.transferFrom(msg.sender,address(this),uploadFee);
        handlePayment(uploadFee);

        contentDetail[contentId]=Content(
            msg.sender,
            _name,
            contentId,
            0,//means no comment 
            0,
            0,
            0
        );
        creator[msg.sender].bronSpend +=uploadFee;
        creator[msg.sender].contentIds.push(contentId);
        emit UploadContent(contentId,msg.sender,_name);
        contentId=contentId.add(1);
        

     }
      
      function reviewContent (uint256 _contentId,uint256 _star) public 
      {
        require (isReviewd[msg.sender][_contentId]==false,"this content already reviwed ");
        tokenContract.transferFrom(msg.sender,address(this),reviewFee);
        handlePayment(reviewFee);
        contentDetail[_contentId].review +=1;
        contentDetail[_contentId].totalStar +=_star;
        contentDetail[_contentId].avgRanking = contentDetail[_contentId].totalStar.div(contentDetail[_contentId].review);
        contibutorDetails[msg.sender].bronSpend +=uploadFee;
        contibutorDetails[msg.sender].review +=1;
        contibutorDetails[msg.sender].comments +=1;
        isReviewd[msg.sender][_contentId]=true;
        emit ReviewContent(_contentId, msg.sender, _star);
      }

     
    function startStream(string memory _name ) public {

        require(creator[msg.sender].allowed==true,"you not have permission to stream");
        tokenContract.transferFrom(msg.sender,address(this),uploadFee);
        streamDetail[streamId]=Stream(
           msg.sender,
           _name,
           streamId,
           0,
           block.timestamp,
           0
        );
        creator[msg.sender].bronSpend +=uploadFee;
        creator[msg.sender].streamIds.push(streamId);
        emit StartStream(streamId, msg.sender, block.timestamp,_name);
        streamId +=1;
    }
    function watchStream(uint256 _streamid,uint256  _totalwatchtime) public 
    {
         require(streamDetail[_streamid].streamId !=0,"stream not exist");
          tokenContract.transferFrom(msg.sender,address(this),contentWatchFee);
          handlePayment(contentWatchFee);
          UserDetail[msg.sender].bronSpend +=contentWatchFee;
          UserDetail[msg.sender].totalWatchMinute +=_totalwatchtime;
          streamDetail[_streamid].totalWatchMinute +=_totalwatchtime;
          streamDetail[_streamid].totalview +=1;
          emit WatchStream(_streamid, msg.sender, _totalwatchtime);

    }

     function watchContent(uint256 _contentid) public 
     {
        require(contentDetail[_contentid].contentId !=0,"content not exist"); 
        tokenContract.transferFrom(msg.sender,address(this),contentWatchFee);
        handlePayment(contentWatchFee);
         UserDetail[msg.sender].bronSpend +=contentWatchFee;
        contentDetail[_contentid].totalViews +=1;
        emit WatchContent(_contentid, msg.sender, contentDetail[_contentid].totalViews);
     }

     function createPlaylist(string memory _name,uint256[] memory _contentList)public 
     {
        tokenContract.transferFrom(msg.sender,address(this),contentWatchFee);
        handlePayment(contentWatchFee);
        playListDetail[msg.sender][playlistId].name=_name;
         contibutorDetails[msg.sender].bronSpend +=contentWatchFee;
        playListDetail[msg.sender][playlistId].conentIds=_contentList;
        contibutorDetails[msg.sender].playlsistIds.push(playlistId);
        emit CreatePlaylist(playlistId, msg.sender, _contentList);
        playlistId +=1;
      
     }
     
     function playGame(uint256 _gameid) public 
     {
           tokenContract.transferFrom(msg.sender,address(this),contentWatchFee);
           handlePayment(contentWatchFee);
           UserDetail[msg.sender].bronSpend +=contentWatchFee;
           UserDetail[msg.sender].playgames +=1;
           emit PlayGame(_gameid,msg.sender);
     } 

     function stakeNft(uint256 _nftid)public {
         require(nftContract.ownerOf(_nftid)== msg.sender);
         nftContract.transferFrom(msg.sender, address(this), _nftid);
         stakeNftsDetail[msg.sender]=StakeNfts(
             block.timestamp,
             0,
             msg.sender,
             false,
             0
         );

     }
      



     function  approvedPartner(bool _isallowed,address _partner) public onlyOwner
     {
          creator[_partner].allowed = _isallowed;
     }

    
     
     function changeContractAddress (IERC721 _nftContract,IERC20 _tokenContract) public onlyOwner
     {
           nftContract=_nftContract;
           tokenContract=_tokenContract;
     }

     function setFees(uint256 uploadFees, uint256 reviewFees, uint256 watchfees) public onlyOwner {
         uploadFee = uploadFees;
         reviewFee = reviewFees;
         contentWatchFee = watchfees;
     }


     /* STAKING FUNCTIONS STARTS HERE */

     function stake(uint256 amount, uint256 months) public nonReentrant {
        require(months == 1 || months == 3 || months == 6 || months == 9 || months == 12,"ENTER VALID MONTH");
        _stake(amount, months);
     }
     function _stake(uint256 amount, uint256 months) private {
        tokenContract.transferFrom(msg.sender, address(this), amount);
        userstakes[msg.sender]++;
        uint256 duration = block.timestamp + months*30 days;   
        Stakes[msg.sender].push(stakes(msg.sender, amount, block.timestamp, duration, months, false, 0));
        emit StakingUpdate(msg.sender, amount, block.timestamp, duration, false, 0);
     }

     function unStake(uint256 stakeId) public nonReentrant{
        require(Stakes[msg.sender][stakeId].collected == false ,"ALREADY WITHDRAWN");
        require(Stakes[msg.sender][stakeId].endTime < block.timestamp,"STAKING TIME NOT ENDED");
        _unstake(stakeId);
     }

        function _unstake(uint256 stakeId) private {
        Stakes[msg.sender][stakeId].collected = true;
        uint256 stakeamt = Stakes[msg.sender][stakeId].amount;
        uint256 rewards = getTotalRewards(msg.sender, stakeId) - Stakes[msg.sender][stakeId].claimed;
        Stakes[msg.sender][stakeId].claimed += rewards;
        totalRewardsClaimed = totalRewardsClaimed + rewards;
        tokenContract.transfer(msg.sender, stakeamt + rewards);
        emit StakingUpdate(msg.sender, stakeamt, Stakes[msg.sender][stakeId].startTime, Stakes[msg.sender][stakeId].endTime, true, getTotalRewards(msg.sender, stakeId));
    }
    function claimRewards(uint256 stakeId) public nonReentrant {
        require(Stakes[msg.sender][stakeId].claimed != getTotalRewards(msg.sender, stakeId));
        uint256 cuamt = getCurrentRewards(msg.sender, stakeId);
        uint256 clamt = cuamt - Stakes[msg.sender][stakeId].claimed;
        Stakes[msg.sender][stakeId].claimed += clamt;
        totalRewardsClaimed = totalRewardsClaimed + clamt;
        tokenContract.transfer(msg.sender, clamt);
        emit StakingUpdate(msg.sender, Stakes[msg.sender][stakeId].amount, Stakes[msg.sender][stakeId].startTime, Stakes[msg.sender][stakeId].endTime, true, Stakes[msg.sender][stakeId].claimed);
    }

    function getStakes( address wallet) public view returns(stakes[] memory){
        uint256 itemCount = userstakes[wallet];
        uint256 currentIndex = 0;
        stakes[] memory items = new stakes[](itemCount);

        for (uint256 i = 0; i < userstakes[wallet]; i++) {
                stakes storage currentItem = Stakes[wallet][i];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        return items;
    }

    function getTotalRewards(address wallet, uint256 stakeId) public view returns(uint256) {
        require(Stakes[wallet][stakeId].amount != 0);
        uint256 stakeamt = Stakes[wallet][stakeId].amount;
        uint256 mos = Stakes[wallet][stakeId].months;
        uint256 rewards = ((stakeamt * (APY[mos]) * mos/12 ))/100;
        return rewards;
    }

     function getCurrentRewards(address wallet, uint256 stakeId) public view returns(uint256) {
        require(Stakes[wallet][stakeId].amount != 0,"ZERO amount staked");
        uint256 stakeamt = Stakes[wallet][stakeId].amount;
        uint256 mos = Stakes[wallet][stakeId].months;
        uint256 timec = block.timestamp - Stakes[wallet][stakeId].startTime;
        uint256 rewards = ((stakeamt * (APY[mos]) * mos/12 ))/100;
        uint256 crewards = ((rewards * timec) / (mos*ONE_MONTH_SEC));
        return crewards;
    } 

    function rewardsClaimed() public view returns(uint256){
       return(totalRewardsClaimed);
    }

    function setAPYs(uint256[] memory apys) external onlyOwner {
       require(apys.length == 5,"5 INDEXED ARRAY ALLOWED");
        APY[1] = apys[0];
        APY[3] = apys[1];
        APY[6] = apys[2];
        APY[9] = apys[3];
        APY[12] = apys[4];
        emit APYSet(apys);
    }
    function rescueContract() external nonReentrant onlyOwner{
        tokenContract.transfer(owner(), tokenContract.balanceOf(address(this)));
    }






}