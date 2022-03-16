// ░██████╗██████╗░██╗░░░██╗░█████╗░  ██████╗░██████╗░███████╗
// ██╔════╝██╔══██╗╚██╗░██╔╝██╔══██╗  ██╔══██╗╚════██╗██╔════╝
// ╚█████╗░██████╔╝░╚████╔╝░██║░░╚═╝  ██████╔╝░░███╔═╝█████╗░░
// ░╚═══██╗██╔═══╝░░░╚██╔╝░░██║░░██╗  ██╔═══╝░██╔══╝░░██╔══╝░░
// ██████╔╝██║░░░░░░░░██║░░░╚█████╔╝  ██║░░░░░███████╗███████╗
// ╚═════╝░╚═╝░░░░░░░░╚═╝░░░░╚════╝░  ╚═╝░░░░░╚══════╝╚══════╝

// ░██████╗████████╗░█████╗░██╗░░██╗██╗███╗░░██╗░██████╗░
// ██╔════╝╚══██╔══╝██╔══██╗██║░██╔╝██║████╗░██║██╔════╝░
// ╚█████╗░░░░██║░░░███████║█████═╝░██║██╔██╗██║██║░░██╗░
// ░╚═══██╗░░░██║░░░██╔══██║██╔═██╗░██║██║╚████║██║░░╚██╗
// ██████╔╝░░░██║░░░██║░░██║██║░╚██╗██║██║░╚███║╚██████╔╝
// ╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝░╚═════╝░

// ░█████╗░░█████╗░███╗░░██╗████████╗██████╗░░█████╗░░█████╗░████████╗
// ██╔══██╗██╔══██╗████╗░██║╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝
// ██║░░╚═╝██║░░██║██╔██╗██║░░░██║░░░██████╔╝███████║██║░░╚═╝░░░██║░░░
// ██║░░██╗██║░░██║██║╚████║░░░██║░░░██╔══██╗██╔══██║██║░░██╗░░░██║░░░
// ╚█████╔╝╚█████╔╝██║░╚███║░░░██║░░░██║░░██║██║░░██║╚█████╔╝░░░██║░░░
// ░╚════╝░░╚════╝░╚═╝░░╚══╝░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝░╚════╝░░░░╚═╝░░░

//http://superpunksyachtclub.live/
//https://twitter.com/SuperpunksNFTs
//https://discord.com/invite/8nwNmU6u99

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721.sol";
 import "./IERC721Receiver.sol";
 import "./Ownable.sol";
 import "./SUPER.sol";
import "./Context.sol";
import "./ERC20.sol";
contract NFTSTAKER is Ownable, IERC721Receiver {
    // struct to store a stake's token, owner, and earning values
    struct Stake {
        uint16 tokenId;
        uint80 value;
        address owner;
    }

    event TokenStaked(address owner, uint256 tokenId, uint256 value);
    event SUPERClaimed(uint256 tokenId, uint256 earned, bool unstaked);

    // reference to the SuperPunks NFT contract
    IERC721 public SuperPunks;
    // reference to the $SUPER contract for minting $SUPER earnings
    SPYC public SUP;
 
    // maps tokenId to stake
    mapping(uint256 => Stake) public war;

    // maps address to number of tokens staked
    mapping(address => uint256) public numTokensStaked;

    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // SuperPunks earn 2 $SUPER per day
    uint256 public Daily_Stake_rate = 10 ether;

    uint256 public SuperMinimum = 100 ether;

    mapping (address => uint256[]) public stakePortfolioByUser;
    mapping(uint256 => uint256) public indexOfTokenIdInStakePortfolio;
      mapping (uint256 => bool) public welcomeBonusCollected;
      mapping (address => uint256[]) public Rarity;
       mapping (address => uint256[]) public ReferPay;
    // number of SuperPunks staked in the War
    uint256 public totalSuperPunksStaked;

    // the last time $SUPER can be claimed
    uint256 public lastClaimTimestamp;

    // whether staking is active
    bool public stakeIsActive = true;
uint256 public welcomeBonusAmount;
uint256 public BurnBonusAmount;


    // Bonus $SUPER for elligible tokens
    uint256 public tokensElligibleForBonus;
    uint256 public bonusAmount;
    mapping(uint256 => bool) public bonusClaimed;

    
    constructor(
               uint256 _claimPeriod,
        uint256 _tokensElligibleForBonus,
        uint256 _bonusAmount
    ) {
        SuperPunks = IERC721(0x59366521e6CC12D1512abe6233DaAfD2311953BF);
        SUP = SPYC(0xC9e4271E39e029396617B34Ad25f86496032abbC);
        lastClaimTimestamp = block.timestamp + _claimPeriod;
        tokensElligibleForBonus = _tokensElligibleForBonus;
        bonusAmount = _bonusAmount;
         welcomeBonusAmount = 10 * 10 ** 18; // 100 tokens welcome bonus, only paid once per tokenId
        BurnBonusAmount=100 * 10 ** 18; 
       }

    /** STAKING */

    /**
     * adds SuperPunkss to the War
     * @param tokenIds the IDs of the SuperPunks to stake
     */
    function stakeBatch(uint16[] calldata tokenIds) external {
        require(stakeIsActive, "Staking is paused");
        if(SUP.balanceOf(msg.sender)>SuperMinimum)
        {

        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                SuperPunks.ownerOf(tokenIds[i]) == msg.sender,
                "Not your token"
            );
            SuperPunks.transferFrom(msg.sender, address(this), tokenIds[i]);
            _addSuperPunksToWar(msg.sender, tokenIds[i]);
            
        }
        }
    }



function BurnBatch(uint16[] calldata tokenIds) external {
        require(stakeIsActive, "Staking is paused");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                SuperPunks.ownerOf(tokenIds[i]) == msg.sender,
                "Not your token"
            );
            SuperPunks.transferFrom(msg.sender, address(0), tokenIds[i]);
           SUP.stakingMint(_msgSender(), BurnBonusAmount);
            
        }
    }


    function Addliquidity(address owner, uint256 amount) internal {

       SUP.initalliquidityadd(owner,amount);
    }

    /**
     * adds a single SuperPunks to the War
     * @param owner the address of the staker
     * @param tokenId the ID of the SuperPunks to add to the War
     */
 
    function _addSuperPunksToWar(address owner, uint256 tokenId) internal {

          if(SUP.balanceOf(msg.sender)>SuperMinimum)
        {
        war[tokenId] = Stake({
            owner: owner,
            tokenId: uint16(tokenId),
            value: uint80(block.timestamp)
        });
        _addTokenToOwnerEnumeration(owner, tokenId);
        totalSuperPunksStaked += 1;
        numTokensStaked[owner] += 1;
        emit TokenStaked(owner, tokenId, block.timestamp);
        stakePortfolioByUser[_msgSender()].push(tokenId);
        uint256 indexOfNewElement = stakePortfolioByUser[_msgSender()].length - 1;
        indexOfTokenIdInStakePortfolio[tokenId] = indexOfNewElement;
        if(!welcomeBonusCollected[tokenId]) {
            SUP.stakingMint(_msgSender(), welcomeBonusAmount);
            welcomeBonusCollected[tokenId] = true;
        }
        }
    }


function stakedNFTSByUser(address owner) external view returns (uint256[] memory){
        return stakePortfolioByUser[owner];
    }
    /** CLAIMING / UNSTAKING */

    /**
     * realize $SUPER earnings and optionally unstake tokens from the War
     * @param tokenIds the IDs of the tokens to claim earnings from
     * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
     */
    function claimManySPYC(uint16[] calldata tokenIds, bool unstake)
        external
    {
        uint256 owed = 0;

         
       


        for (uint256 i = 0; i < tokenIds.length; i++) {
             if((tokenIds[i]>810 &&tokenIds[i]<=840)||(tokenIds[i]>3040 && tokenIds[i]<=3050)||(tokenIds[i]>6313&&tokenIds[i]<=6360)||(tokenIds[i]>8194&&tokenIds[i]<=8600)||(tokenIds[i]>9950&&tokenIds[i]<=10000))
           {
               owed +=(2* _claimSPYCReward(tokenIds[i], unstake));
           }
           else if((tokenIds[i]>6360 &&tokenIds[i]<=6400)||(tokenIds[i]>8185 && tokenIds[i]<=8195))
           {
            owed +=(3* _claimSPYCReward(tokenIds[i], unstake));

           }
           else{ owed += _claimSPYCReward(tokenIds[i], unstake);}
            
        }
        if (owed == 0) return;
         if(SUP.SPYC_Coin_TotalSupply()/SUP.totalStakingSupply()<=2){
             SUP.stakingMint(msg.sender, owed/2);
         }
         else{SUP.stakingMint(msg.sender, owed);}
        
    }


    // claim rewards from SPYC Staking 

    function claimRewardOnly(address user)  external
         {
        uint256[] memory tokenIds = stakePortfolioByUser[user];

        uint256 owed = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            owed += _claimSPYCReward(tokenIds[i], false);
        }
        
        if (owed == 0) return;
        SUP.stakingMint(msg.sender, owed);
       
         }

    /**
     * realize $SUPER earnings for a single SuperPunks and optionally unstake it
     * @param tokenId the ID of the SuperPunks to claim earnings from
     * @param unstake whether or not to unstake the SuperPunks
     * @return owed - the amount of $SUPER earned
     */
    function _claimSPYCReward(uint256 tokenId, bool unstake)
        internal
        returns (uint256)
    {
        Stake memory stake = war[tokenId];
        if (stake.owner == address(0)) {
            // Unstaked SD tokens
            require(
                SuperPunks.ownerOf(tokenId) == msg.sender,
                "Not your token"
            );
            uint256 owed = _getClaimableSUPER(tokenId);
            bonusClaimed[tokenId] = true;
            emit SUPERClaimed(tokenId, owed, unstake);
            return owed;
        } else {
            // Staked SD tokens
            require(stake.owner == msg.sender, "Not your token");
            uint256 owed = _getClaimableSUPER(tokenId);
            if (_elligibleForBonus(tokenId)) {
                bonusClaimed[tokenId] = true;
            }
            if (unstake) {
                // Send back SuperPunks to owner
                SuperPunks.safeTransferFrom(
                    address(this),
                    msg.sender,
                    tokenId,
                    ""
                );
                _removeTokenFromOwnerEnumeration(stake.owner, stake.tokenId);
                delete war[tokenId];
                totalSuperPunksStaked -= 1;
                numTokensStaked[msg.sender] -= 1;
            } else {
                // Reset stake
                war[tokenId] = Stake({
                    owner: msg.sender,
                    tokenId: uint16(tokenId),
                    value: uint80(block.timestamp)
                });
            }
            emit SUPERClaimed(tokenId, owed, unstake);
            return owed;
        }
    }

     

     


    function getClaimableSUPERForMany(uint16[] calldata tokenIds)
        external
        view
        returns (uint256)
    {
        uint256 owed = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            owed += _getClaimableSUPER(tokenIds[i]);
        }
        return owed;
    }

    /**
     * Check if a SuperPunks token is elligible for bonus
     * @param tokenId the ID of the token to check for elligibility
     */
    function _elligibleForBonus(uint256 tokenId) internal view returns (bool) {
        return tokenId < tokensElligibleForBonus && !bonusClaimed[tokenId];
    }

    /**
     * Calculate claimable $SUPER earnings from a single staked SuperPunks
     * @param tokenId the ID of the token to claim earnings from
     */
    function _getClaimableSUPER(uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        uint256 owed = 0;
        if (tokenId < tokensElligibleForBonus && !bonusClaimed[tokenId]) {
            owed += bonusAmount;
        }
        Stake memory stake = war[tokenId];
        if (stake.value == 0) {} else {
            owed +=
                ((block.timestamp - stake.value) * Daily_Stake_rate) /
                1 days;
        }
        return owed;
    }

    /** ENUMERABLE */

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {numTokensStaked} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        returns (uint256)
    {
        require(index < numTokensStaked[owner], "Owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param owner address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address owner, uint256 tokenId)
        private
    {
        uint256 length = numTokensStaked[owner];
        _ownedTokens[owner][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures.
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param owner address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address owner, uint256 tokenId)
        private
    {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = numTokensStaked[owner] - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[owner][lastTokenIndex];

            _ownedTokens[owner][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[owner][lastTokenIndex];
    }

    /** UTILS */

    /**
     * @dev Returns the owner address of a staked SuperPunks token
     * @param tokenId the ID of the token to check for owner
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        Stake memory stake = war[tokenId];
        return stake.owner;
    }

    /**
     * @dev Returns whether a SuperPunks token is staked
     * @param tokenId the ID of the token to check for staking
     */
    function isStaked(uint256 tokenId) public view returns (bool) {
        Stake memory stake = war[tokenId];
        return stake.owner != address(0);
    }

    /** ADMIN */

    /**
     * enables owner to pause / unpause staking
     */
    function setStakingStatus(bool _status) external onlyOwner {
        stakeIsActive = _status;
    }

    function setWelcomeBonusAmount(uint256 coinAmount) external onlyOwner {
        welcomeBonusAmount = coinAmount;
    }

    function SetBurnBonusAmount(uint256 _BurnBonusAmount) external onlyOwner {
        BurnBonusAmount = _BurnBonusAmount;
    }

    function setdailyrate(uint256 _Daily_Stake_rate) external onlyOwner {
            Daily_Stake_rate=_Daily_Stake_rate;
    }

    /**
     * allows owner to unstake tokens from the War, return the tokens to the tokens' owner, and claim $SPYC earnings
     * @param tokenIds the IDs of the tokens to claim earnings from
     * @param tokenOwner the address of the SuperPunks tokens owner
     */
    function UnStakeNFT(uint16[] calldata tokenIds, address tokenOwner)
        external
        onlyOwner
    {
        uint256 owed = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if((tokenIds[i]>810 &&tokenIds[i]<=840)||(tokenIds[i]>3040 && tokenIds[i]<=3050)||(tokenIds[i]>6313&&tokenIds[i]<=6360)||(tokenIds[i]>8194&&tokenIds[i]<=8600)||(tokenIds[i]>9950&&tokenIds[i]<=10000))
           {
               owed +=(2* _Unstaker(tokenIds[i], tokenOwner));
           }
           else if((tokenIds[i]>6360 &&tokenIds[i]<=6400)||(tokenIds[i]>8185 && tokenIds[i]<=8195))
           {
            owed +=(3* _Unstaker(tokenIds[i], tokenOwner));

           }
           else{ owed += _Unstaker(tokenIds[i], tokenOwner);}
           
        }
        if (owed == 0) return;
        SUP.stakingMint(tokenOwner, owed);
    }

    /**
     * unstake a single SuperPunks from War and claim $SPYC earnings
     * @param tokenId the ID of the SuperPunks to rescue
     * @param tokenOwner the address of the SuperPunks token owner
     * @return owed - the amount of $SUPER earned
     */
    function _Unstaker(uint256 tokenId, address tokenOwner)
        internal
        returns (uint256)
    {
        Stake memory stake = war[tokenId];
        require(stake.owner == tokenOwner, "Not your token");
        uint256 owed = _getClaimableSUPER(tokenId);
        if (_elligibleForBonus(tokenId)) {
            bonusClaimed[tokenId] = true;
        }
        // Send back SuperPunks to owner
        SuperPunks.safeTransferFrom(address(this), tokenOwner, tokenId, "");
        _removeTokenFromOwnerEnumeration(stake.owner, stake.tokenId);
        delete war[tokenId];
       stakePortfolioByUser[_msgSender()][indexOfTokenIdInStakePortfolio[tokenId]] = 0;
        totalSuperPunksStaked -= 1;
        numTokensStaked[tokenOwner] -= 1;
        emit SUPERClaimed(tokenId, owed, true);
        return owed;
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Cannot send tokens to Staking directly");
        return IERC721Receiver.onERC721Received.selector;
    }
}