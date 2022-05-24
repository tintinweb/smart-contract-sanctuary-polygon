/**
 *Submitted for verification at polygonscan.com on 2022-05-23
*/

/**
 *Submitted for verification at polygonscan.com on 2022-05-07
*/
///add code



// SPDX-License-Identifier: Unlicensed
// OpenZeppel// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;
/**
 * @dev Required interface of an ERC721 compliant contract.
 */
 contract SMAuth {

        address public auth;
        address public auth2;
        bool internal locked;
       modifier onlyAuth {
        require(isAuthorized(msg.sender));
        _;
    }

    modifier nonReentrancy() {
        require(!locked, "No reentrancy allowed");

        locked = true;
        _;
        locked = false;
    }
    function setAuth(address src) public onlyAuth {
        auth2= src;
    }
    function isAuthorized(address src) internal view returns (bool) {
        if(src == auth){
            return true;
        } else if (src == auth2) {
            return true;
        } else return false;
    }
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

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;


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

contract ScholarMarket is SMAuth, ReentrancyGuard {
    IERC721 public nftContract;
    IERC20 public bmnContract;
    //IERC20 public usdtContract;
    constructor(IERC721 nftContract_, IERC20 bmnContract_){
        nftContract = nftContract_;
        bmnContract = bmnContract_;
       // usdtContract = usdtContract_;
        auth = msg.sender;
    }

    address fundingWallet;


    struct Scholar {
        uint256 matchesPlayed;
        uint256 matchesWon;
    }

    event ScholarUpdate(
        address scholar,
        uint256 matchesPlayed,
        uint256 matchesWon
    );

    struct Manager {
        address wallet;
        //unused 
    }

    struct Hired{
        address manager;
        address scholar;
        uint256 nftId;
        //uint256 matchFee;
        uint256 matchesAllowed;
        uint256 matchesPlayed;
        uint256 won;
        uint256 lost;
        uint256 stopLoss;
        uint256 endTime;
        uint256 accepted;
        // 0 : no response
        // 1: accepted
        // 2 : rejected
    }

    event Offer (
        address indexed manager,
        address indexed scholar,
        uint256 indexed nftId,
        //uint256 matchFee,
        uint256 matchesAllowed,
        uint256 matchesPlayed,
        uint256 won,
        uint256 lost,
        uint256 stopLoss,
        uint256 endTime,
        uint256 accepted
        // 0 : no response
        // 1: accepted
        // 2 : rejected
    );

    struct Match{
        uint256 matchId;
        uint256 time;
        uint256 totalPlayer;
        uint256 poolCollected;
        //uint256 matchFee;
        bool ended;
    }

    event MatchUpdate(
        uint256 MatchId,
        uint256 time,
        uint256 totalPlayer,
        uint256 poolCollected,
        bool ended
    );

    struct rewardDist{
        uint256 reward;
        uint256 time;
    }

    uint256 price = 5*10**18;

    mapping(address=>mapping(address=>uint256)) public scholarManagerLimit;
    mapping(address=>Scholar) public scholar;
   // mapping(address=>Manager) public manager;
    mapping(uint256=>Match) public matchData;

    mapping(uint256=>Hired) public nftManager;

    uint256 public matchCount=1;
    uint256 public adminfees;
    uint256 public managerSplit; 
    mapping (address => rewardDist) public rewards;
    mapping(uint256=>mapping(address=>bool)) public playerJoined;
    function hireScholar(address wallet, 
        uint256 nftId, 
       // uint256 matchFee, 
        uint256 matchesAllowed, 
        uint256 stopLoss 
        ) external {
            require(nftContract.ownerOf(nftId)== msg.sender);
            require(scholarManagerLimit[msg.sender][wallet]==0);
            
            nftContract.transferFrom(msg.sender, address(this), nftId);
            bmnContract.transferFrom(msg.sender, address(this ), (price * matchesAllowed));
            
            uint256 endTime = block.timestamp + 1 days;
            nftManager[nftId] = Hired(
                msg.sender,
                wallet,
                nftId,
              //  matchFee,
                matchesAllowed,
                0,
                0,
                0,
                stopLoss,
                endTime,
                0
            );

            emit Offer(
                msg.sender,
                wallet,
                nftId,
               // matchFee,
                matchesAllowed,
                0,
                0,
                0,
                stopLoss,
                endTime,
                0
                );
    }

    function respondOffer(uint256 nftId, uint256 response) external {
        require(nftManager[nftId].scholar == msg.sender);
        require(nftManager[nftId].accepted == 0);
        require(nftManager[nftId].endTime > block.timestamp);
        nftManager[nftId].accepted = response;
         emit Offer(
                nftManager[nftId].manager,
                nftManager[nftId].scholar,
                nftId,
                //nftManager[nftId].matchFee,
                nftManager[nftId].matchesAllowed,
                nftManager[nftId].matchesPlayed,
                nftManager[nftId].won,
                nftManager[nftId].lost,
                nftManager[nftId].stopLoss,
                nftManager[nftId].endTime,
                response
                );
    }

    function cancelOffer(uint256 nftId) external nonReentrant {
        require(nftManager[nftId].accepted == 0 || nftManager[nftId].accepted == 2);
        address manager_ = nftManager[nftId].manager;
        nftContract.transferFrom(address(this), manager_, nftId);
        bmnContract.transfer(manager_,  price * nftManager[nftId].matchesAllowed);
        nftManager[nftId] = Hired(
                manager_,
                0x0000000000000000000000000000000000000000,
                nftId,
                0,
                0,
                0,
                0,
                0,
                0,
                0
            );
            emit Offer(
                manager_,
                0x0000000000000000000000000000000000000000,
                nftId,
                0,
                0,
                0,
                0,
                0,
                0,
                0
                );

    }

    function settleNFT(uint256 nftId) external nonReentrant {
            require(nftManager[nftId].accepted == 1);
            uint256 lost_ = nftManager[nftId].lost;
            uint256 stopLoss_ = nftManager[nftId].stopLoss;
            uint256 endTime_ = nftManager[nftId].endTime;
            uint256 matchesPlayed_ = nftManager[nftId].matchesPlayed;
            uint256 matchesAllowed_ = nftManager[nftId].matchesAllowed;
            uint256 remainMatched = matchesPlayed_ -  matchesAllowed_ ;
            address manager_ = nftManager[nftId].manager;
            address scholar_ = nftManager[nftId].scholar;
            //uint256 status = nftManager[nftId].accepted;
            require(block.timestamp > endTime_ || lost_ > stopLoss_ || matchesPlayed_ == matchesAllowed_);

            if(matchesPlayed_ != matchesAllowed_)
            {
                bmnContract.transfer(manager_, remainMatched * price  );
            }

              

            nftContract.transferFrom(address(this), manager_, nftId);
            scholarManagerLimit[manager_][scholar_]=0;
            nftManager[nftId] = Hired(
                manager_,
                0x0000000000000000000000000000000000000000,
                nftId,
                0,
                0,
                0,
                0,
                0,
                0,
                0
            );
    }

    function startMatch(uint256 nftId, uint256 matchid) external nonReentrant {
        require(matchData[matchid].matchId != 0);
        require(isScholarAllowed(msg.sender, nftId) == true);
        require(matchData[matchid].ended == false);
        require(playerJoined[matchid][msg.sender] ==false);
        playerJoined[matchid][msg.sender] = true;
        scholar[msg.sender].matchesPlayed++;
        nftManager[nftId].matchesPlayed++;
        matchData[matchid].poolCollected += price;                
        matchData[matchid].totalPlayer++;
      //  bmnContract.transferFrom(msg.sender, nftManager[nftId].manager, nftManager[nftId].matchFee);
      //  bmnContract.transferFrom(msg.sender, address(this ), price);
        emit MatchUpdate(
            matchid,
            matchData[matchid].time,
            matchData[matchid].totalPlayer,
            matchData[matchid].poolCollected,
            false
        );
    }

    function isScholarAllowed(address scholar_, uint256 nftId_) public view returns(bool) {       
            address mScholar = nftManager[nftId_].scholar;
            uint256 acpt = nftManager[nftId_].accepted;
            uint256 time = nftManager[nftId_].endTime;
            uint256 curtime = block.timestamp;        

            if(mScholar== scholar_ && acpt == 1 && curtime < time){
                return true;
            } else return false;
    }

    function createMatch() external onlyAuth returns(uint256 matchId) {
        uint256 id = matchCount;
        matchCount++;
        matchData[id] = Match(
            id,
            block.timestamp,
            0,
            0,
            false
        );
        emit MatchUpdate(
            id,
            block.timestamp,
            0,
            0,
            false
        );
    return id;

    }

    function rewardDistribution(uint256[] memory  nftid, uint256 matchId) internal nonReentrant {
        require(matchData[matchId].ended == false);
        require(nftid.length == 3, "Only 3 winners");
        uint256 reward = matchData[matchId].poolCollected;
        uint8[3] memory dist = [5, 3, 2];
        for(uint256 i = 0; i< nftid.length; i++){
            address fss = nftManager[nftid[i]].scholar;
            address fmm = nftManager[nftid[i]].manager;
            rewards[fss].reward += (((reward * dist[i])) * (1 - managerSplit)) / 100;
            rewards[fmm].reward += (((reward * dist[i])) * managerSplit)/ 100;     
        scholar[nftManager[nftid[i]].scholar].matchesWon++;
        nftManager[nftid[i]].won++;
        emit ScholarUpdate(
            nftManager[nftid[i]].scholar, scholar[nftManager[nftid[i]].scholar].matchesPlayed, scholar[nftManager[nftid[i]].scholar].matchesWon
        );       
        }
        matchData[matchId].ended = true;
        bmnContract.transfer(fundingWallet,(matchData[matchId].poolCollected)/10);
    }

    function updateMatch(uint256[] memory LnftId, uint256[] memory wonnft, uint256 matchid) external nonReentrant onlyAuth {
        rewardDistribution(wonnft, matchid);
        for(uint256 i = 0; i < LnftId.length; i++){
            nftManager[LnftId[i]].lost++;
        }
    }


    function getReward() external nonReentrant {
        require(block.timestamp - rewards[msg.sender].time > 604800, "Already claimd once in a week");
        uint256 rew = rewards[msg.sender].reward;
        rewards[msg.sender].reward = 0;
        rewards[msg.sender].time = block.timestamp;
        bmnContract.transfer(msg.sender, rew);
    }
    function setFee(uint256 fee_) external onlyAuth {
        price = fee_;
    }

    function setfundingWallet( address wallet) public onlyAuth {
        fundingWallet = wallet;
    }

    function setBMN(IERC20 conad_) public onlyAuth {
        bmnContract = conad_;
    }
    function ownerWithdrawBMN (address _token ,uint256 amount ) public onlyAuth {
        IERC20(_token).transfer(msg.sender,amount);
    }
    function ownerWithdrawNft(uint256 tokenid) public onlyAuth 
    {
        nftContract.transfer(msg.sender, tokenid);
    }

    function setDistro(uint256 adminfee, uint256 managerd) external onlyAuth {
        require(managerd<100 && adminfee <100);
        adminfees = adminfee;
        managerSplit = managerd;
    }
}