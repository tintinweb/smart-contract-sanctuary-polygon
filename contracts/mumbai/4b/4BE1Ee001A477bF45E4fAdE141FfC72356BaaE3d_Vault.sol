// SPDX-License-Identifier: MIT
/// @author MrD 

pragma solidity >=0.8.11;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./VaultMiner.sol";
import "./libs/ERC1155Tradable.sol";
import "./libs/PancakeLibs.sol";

/**
 * @title BlacklistAddress
 * @dev Manage the blacklist and add a modifier to prevent blacklisted addresses from taking action
 */
contract Vault is VaultMiner {
    // using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct VaultSettings {
        uint256 tokenBurnMultiplier;
        uint256 nftGiveMultiplier;
        uint256 nftBurnMultiplier;
        uint256 packThresh;
        uint256 burnThresh;
        uint256 shareMod;
        uint256 tokenShare;
        uint256 tokenPercent;
    }
   
    struct UserLock {
        uint256 tokenAmount; // total amount they locked
        uint256 claimedAmount; // total amount they have withdrawn
        uint256 vestShare; // how many tokens they get back each vesting period
        uint256 vestPeriod; // how many seconds each vest point is
        uint256 startTime; // start of the lock
        uint256 endTime; //when the lock ends
    }

    struct UserNftLock {
        uint256 amount; // amount they have locked
        uint256 sharePoints;  // total share points being given for this lock
        uint256 startTime; // start of the lock
        uint256 endTime; //when the lock ends
    }

    struct NftInfo {
        uint256 tokenId; // which token to lock (mPCKT or LP)
        uint256 lockDuration; // how long this nft needs you to lock
        uint256 tokenAmount; // how many tokens you must lock
        uint256 vestPoints; // lock time / vestPoints = each vesting period
        uint256 sharePoints;  // how many base share this is worth for locking (4x for giving)
        uint256 sharePercent;  // % value of vault shares, applies when value is > sharePoints
        uint256 givenAmount; // how many have been deposited into the contract
        uint256 burnedAmount; // how many have been deposited into the contract
        uint256 claimedAmount; // how many have been claimed from the contract
        uint256 lockedNfts; // how many nfts are currently locked
        bool toBurn; // if this should be burned or transferred when deposited
        bool isDisabled; // so we can hide ones we don't want
        address lastGiven; // address that last gave this nft so they can't reclaim
    } 

    VaultSettings public vaultSettings;
    
    mapping(address => mapping(uint256 => UserLock)) public userLocks;
    mapping(address => mapping(uint256 => UserNftLock)) public userNftLocks;
    mapping(uint256 => NftInfo) public nftInfo;
    mapping(uint256 => bool) public inNftPacks;
    mapping(uint256 => bool) public inNftRewards;
    mapping(uint256 => IERC20) public tokenIds;

    event Locked(address indexed account, uint256 nftId, uint256 unlock );
    event UnLocked(address indexed account, uint256 nftId);
//    event Claimed(address indexed account, uint256 nftId, uint256 amount);
    event NftGiven(address indexed account, uint256 nftId, uint256 shares);
    event NftLocked(address indexed account, uint256 nftId, uint256 unlock, uint256 shares);
    event TokensBurned(address indexed account, uint256 amount, uint256 shares);

    event NftUnLocked(address indexed account, uint256 nftId);


    constructor (
        ERC1155Tradable _nftContract, 
        TokenSwap _tokenSwap,
        IERC20 _token, // mpckt
        IERC20 _stable, // usdc
        address payable _devWallet,
        address payable _treasuryWallet,
        address payable _investWallet,
        address _router
    ) VaultMiner(_devWallet, _treasuryWallet, _investWallet, _tokenSwap, _token, _stable,  _nftContract, _router ) {
        // nftContract = _nftContract;
        // treasuryWallet = _treasuryWallet;
        // PancakeRouter = _router;
        
        _setToken(1,_token);

        canGive[address(this)] = true;
        canGive[owner()] = true;
            
        // default settings
        vaultSettings = VaultSettings({
            tokenBurnMultiplier: 6,
            nftGiveMultiplier: 4,
            nftBurnMultiplier: 3,
            packThresh: 3,
            burnThresh: 100,
            shareMod: 50,
            tokenShare: 5,
            tokenPercent: 10
        });

    }

    function setMultipliers(uint256 _tokenBurnMultiplier, uint256 _nftGiveMultiplier, uint256 _nftBurnMultiplier ) public onlyOwner {
        vaultSettings.tokenBurnMultiplier = _tokenBurnMultiplier;
        vaultSettings.nftGiveMultiplier = _nftGiveMultiplier;
        vaultSettings.nftBurnMultiplier = _nftBurnMultiplier;
    }

    function setThresholds(uint256 _packThresh, uint256 _burnThresh, uint256 _shareMod, uint256 _tokenmShare, uint256 _tokenPercent) public onlyOwner {
        vaultSettings.packThresh = _packThresh;
        vaultSettings.burnThresh = _burnThresh;
        vaultSettings.shareMod = _shareMod;
        vaultSettings.tokenShare = _tokenmShare;
        vaultSettings.tokenPercent = _tokenPercent;
    }

    function setAddresses(
        address _lpAddress,
        address _nftPacksAddress,
        address _nftRewardsAddress,
        address _gatewayAddress
    ) public onlyOwner {
        vaultAddresses.lpAddress = _lpAddress;
        vaultAddresses.nftPacksAddress = _nftPacksAddress;
        vaultAddresses.nftRewardsAddress = _nftRewardsAddress;
        vaultAddresses.gatewayAddress = _gatewayAddress;
    }
  

    function setToken(uint256 _tokenId, IERC20 _tokenAddress) public onlyOwner {
        _setToken(_tokenId, _tokenAddress);
        _tokenAddress.approve(address(pancakeRouter), type(uint256).max);
        _tokenAddress.approve(address(this), type(uint256).max);
    }

    function _setToken(uint256 _tokenId, IERC20 _tokenAddress) private {
        tokenIds[_tokenId] = _tokenAddress;
    }

    function setNftInPack(uint256 _nftId, bool _inPack) public onlyOwner {
        inNftPacks[_nftId] = _inPack;
    }

    function setNftInRewards(uint256 _nftId, bool _inRewards) public onlyOwner {
        inNftRewards[_nftId] = _inRewards;
    }

    function setNftInfo(
        uint256 _nftId, 
        uint256 _tokenId, 
        uint256 _lockDuration, 
        uint256 _tokenAmount, 
        uint256 _vestPoints, 
        uint256 _sharePoints, 
        uint256 _sharePercent, 
        bool _toBurn) public onlyOwner {

        require(address(tokenIds[_tokenId]) != address(0), "No valid token");

        nftInfo[_nftId].tokenId = _tokenId;
        nftInfo[_nftId].lockDuration = _lockDuration;
        nftInfo[_nftId].tokenAmount = _tokenAmount;
        nftInfo[_nftId].vestPoints = _vestPoints;
        nftInfo[_nftId].sharePoints = _sharePoints;
        nftInfo[_nftId].sharePercent = _sharePercent;
        nftInfo[_nftId].toBurn = _toBurn;

    }

    function setNftDisabled(uint256 _nftId, bool _isDisabled) public onlyOwner {
        nftInfo[_nftId].isDisabled = _isDisabled;        
    }

    function lock(uint256 _nftId) public nonReentrant {

        require(
            userLocks[msg.sender][_nftId].tokenAmount == 0 && 
            nftInfo[_nftId].lastGiven != address(msg.sender) &&    

            activeFeatures.vaultActive && activeFeatures.giveNfts && 
            tokenIds[nftInfo[_nftId].tokenId].balanceOf(msg.sender) >= nftInfo[_nftId].tokenAmount && 
            nftInfo[_nftId].tokenId  > 0 && !nftInfo[_nftId].isDisabled && 
            (vaultAddresses.nftContract.balanceOf(address(this), _nftId) - nftInfo[_nftId].lockedNfts) > 0, 'Cant Lock');
        
        // require(activeFeatures.vaultActive && activeFeatures.giveNfts && tokenIds[nftInfo[_nftId].tokenId].balanceOf(msg.sender) >= nftInfo[_nftId].tokenAmount && nftInfo[_nftId].tokenId  > 0 && !nftInfo[_nftId].isDisabled && (nftContract.balanceOf(address(this), _nftId) - nftInfo[_nftId].lockedNfts) > 0, 'Not Enough');
        // require(nftInfo[_nftId].lastGiven != address(msg.sender),'can not claim your own' );

        userLocks[msg.sender][_nftId].tokenAmount = nftInfo[_nftId].tokenAmount;
        userLocks[msg.sender][_nftId].startTime = block.timestamp; // block.timestamp;
        userLocks[msg.sender][_nftId].endTime = block.timestamp + nftInfo[_nftId].lockDuration; // block.timestamp.add(nftInfo[_nftId].lockDuration);
        userLocks[msg.sender][_nftId].vestShare = nftInfo[_nftId].tokenAmount / nftInfo[_nftId].vestPoints;
        userLocks[msg.sender][_nftId].vestPeriod = nftInfo[_nftId].lockDuration / nftInfo[_nftId].vestPoints;


        // move the tokens
        tokenIds[nftInfo[_nftId].tokenId].safeTransferFrom(address(msg.sender), address(this), nftInfo[_nftId].tokenAmount);

        // send the NFT
        vaultAddresses.nftContract.safeTransferFrom( address(this), msg.sender, _nftId, 1, "");

        emit Locked( msg.sender, _nftId, userLocks[msg.sender][_nftId].endTime );

    }


    function claimLock(uint256 _nftId) public nonReentrant {
        require(activeFeatures.vaultActive && 
                activeFeatures.giveNfts && 
                userLocks[msg.sender][_nftId].tokenAmount > 0 &&
                (userLocks[msg.sender][_nftId].tokenAmount - userLocks[msg.sender][_nftId].claimedAmount) > 0, 'Nothing to claim');
        

        // see how many vest points they have hit
        uint256 vested;
        for(uint256 i = 1; i <= nftInfo[_nftId].vestPoints; ++i){
            if(block.timestamp >= userLocks[msg.sender][_nftId].startTime + (userLocks[msg.sender][_nftId].vestPeriod * i)){    
                vested++;
            }
        }

        uint256 totalVested = userLocks[msg.sender][_nftId].vestShare * vested;

        // get the amount owed to them based on previous claims and current vesting period
        uint256 toClaim = totalVested - userLocks[msg.sender][_nftId].claimedAmount;

        require(toClaim > 0, 'Nothing to claim.');

        userLocks[msg.sender][_nftId].claimedAmount = userLocks[msg.sender][_nftId].claimedAmount + toClaim;

        // move the tokens
        tokenIds[nftInfo[_nftId].tokenId].safeTransfer(address(msg.sender), toClaim);

        if(block.timestamp >= userLocks[msg.sender][_nftId].endTime){
            delete userLocks[msg.sender][_nftId];
            emit UnLocked(msg.sender,_nftId);
        }
        
    }

    // Trade tokens directly for share points at 6:1 rate
    function tokensForShares(uint256 _amount) public nonReentrant {
        require(activeFeatures.vaultActive && activeFeatures.burnTokens && tokenIds[1].balanceOf(msg.sender) >= _amount, "Not enough tokens");

        uint256 adjustedShares = adjustTokenShares(_amount);

        _addShares(msg.sender,adjustedShares * vaultSettings.tokenBurnMultiplier, true );
        
        vaultStats.totalTokensBurned = vaultStats.totalTokensBurned + _amount;

        tokenIds[1].safeTransferFrom(address(msg.sender),burnAddress, _amount);
        emit TokensBurned(msg.sender, _amount, adjustedShares);
    }

    // give or burn an NFT
    function giveNft(uint256 _nftId, uint256 _amount) public nonReentrant {
        require(activeFeatures.vaultActive && activeFeatures.giveNfts && nftInfo[_nftId].sharePoints > 0  && !nftInfo[_nftId].isDisabled && vaultAddresses.nftContract.balanceOf(address(msg.sender), _nftId) >= _amount ,'cant give');

        // require(isActive && nftInfo[_nftId].sharePoints > 0  && !nftInfo[_nftId].isDisabled, 'NFT Not Registered');

        address toSend = address(this);
        uint256 multiplier = vaultSettings.nftGiveMultiplier;

        // check if we hit the burn thresh
        if(nftInfo[_nftId].toBurn && (vaultAddresses.nftContract.maxSupply(_nftId) - vaultAddresses.nftContract.balanceOf(address(burnAddress), _nftId) ) <= vaultSettings.burnThresh){
            nftInfo[_nftId].toBurn = false;
        }
        

        //see if we burn it
        if(nftInfo[_nftId].toBurn){
            toSend = burnAddress;
            multiplier =  vaultSettings.nftBurnMultiplier;
            nftInfo[_nftId].burnedAmount = nftInfo[_nftId].burnedAmount + _amount;
        } else {
            // check if it's in packs
            if(inNftPacks[_nftId] && (vaultAddresses.nftContract.balanceOf(address(this), _nftId) - nftInfo[_nftId].lockedNfts) >= vaultSettings.packThresh){
                toSend = address(vaultAddresses.nftPacksAddress);
            }
            // check if it's rewards
            if(inNftRewards[_nftId] && (vaultAddresses.nftContract.balanceOf(address(this), _nftId) - nftInfo[_nftId].lockedNfts) >= vaultSettings.packThresh){
                toSend = address(vaultAddresses.nftRewardsAddress);
            }
            nftInfo[_nftId].givenAmount = nftInfo[_nftId].givenAmount + _amount;
        }

        // give them shares for the NFTs
        uint256 adjustedShares = adjustNftShares(_nftId);
        _addShares(msg.sender, adjustedShares * _amount * multiplier, true );
        
        // send the NFT
        vaultAddresses.nftContract.safeTransferFrom( msg.sender, toSend, _nftId, _amount, "");

        emit NftGiven(msg.sender, _nftId, adjustedShares);

    }

    function adjustTokenShares(uint256 _amount) public view returns(uint256){
        return ((_calcAdjustedShares(vaultSettings.tokenShare, vaultSettings.tokenPercent) * _amount) * 10) / vaultSettings.shareMod;
    }

    function adjustNftShares(uint256 _nftId) public view returns(uint256) {
        return ((_calcAdjustedShares(nftInfo[_nftId].sharePoints, nftInfo[_nftId].sharePercent ) * 1 ether) * 10) / vaultSettings.shareMod;
    }
/*
    function adjustNftSharesTest(uint256 _nftId) public view returns(uint256) {
        return (nftInfo[_nftId].sharePercent * 1 ether * totalShares) / 10000000;
    }*/

    function _calcAdjustedShares(uint256 _baseShares, uint256 _sharePercent) internal view returns(uint256) {

        uint256 adjustedShares = (_sharePercent * totalShares ) / 10000000;

        if(adjustedShares > _baseShares) {
            return adjustedShares;
        }
        return _baseShares;

    }

    // locks an NFT for the amount of time and the user share points
    // dont't allow burnable NFTS to count
    function lockNft(uint256 _nftId, uint256 _amount) public nonReentrant {
        require(
            activeFeatures.vaultActive && 
            activeFeatures.giveNfts && 
            nftInfo[_nftId].sharePoints > 0  && 
            !nftInfo[_nftId].toBurn && 
            !nftInfo[_nftId].isDisabled && 
            vaultAddresses.nftContract.balanceOf(address(msg.sender), _nftId) >= _amount , "Can't Lock");
        // && userNftLocks[msg.sender][_nftId].startTime == 0
        
        // require(isActive && nftInfo[_nftId].sharePoints > 0  && !nftInfo[_nftId].toBurn && !nftInfo[_nftId].isDisabled, 'NFT Not Registered');

        userNftLocks[msg.sender][_nftId].amount = userNftLocks[msg.sender][_nftId].amount + _amount;
        userNftLocks[msg.sender][_nftId].startTime = block.timestamp; //  block.timestamp;
        userNftLocks[msg.sender][_nftId].endTime = block.timestamp + nftInfo[_nftId].lockDuration; // block.timestamp.add(nftInfo[_nftId].lockDuration);

        // update the locked count
        nftInfo[_nftId].lockedNfts = nftInfo[_nftId].lockedNfts + _amount;

        // give them shares for the NFTs 
        uint256 sp = adjustNftShares(_nftId) * _amount;

        userNftLocks[msg.sender][_nftId].sharePoints = userNftLocks[msg.sender][_nftId].sharePoints + sp;
        _addShares(msg.sender, sp, true);

        // send the NFT
        vaultAddresses.nftContract.safeTransferFrom( msg.sender, address(this), _nftId, _amount, "");

        emit NftLocked( msg.sender, _nftId, userNftLocks[msg.sender][_nftId].endTime,sp);

    }

    // unlocks and claims an NFT if allowed and removes the share points
    function unLockNft(uint256 _nftId) public nonReentrant {
        require(activeFeatures.vaultActive && activeFeatures.giveNfts && userNftLocks[msg.sender][_nftId].amount > 0  && block.timestamp >= userNftLocks[msg.sender][_nftId].endTime, 'cant unlock');
        // require(block.timestamp >= userNftLocks[msg.sender][_nftId].endTime, 'Still Locked');
        
        // see if they have reset the account
        if(userNftLocks[msg.sender][_nftId].startTime > userStats[msg.sender].lastReset){
            // remove the shares
            _removeShares(msg.sender, userNftLocks[msg.sender][_nftId].sharePoints,false);
        }

        uint256 amount = userNftLocks[msg.sender][_nftId].amount;
        delete userNftLocks[msg.sender][_nftId];
        // update the locked count
        nftInfo[_nftId].lockedNfts = nftInfo[_nftId].lockedNfts - amount;
        
        // send the NFT
        vaultAddresses.nftContract.safeTransferFrom(  address(this), msg.sender, _nftId, amount, "");

        emit NftUnLocked( msg.sender, _nftId);
    }

    event NftUsed(address indexed user, uint256 nftId, uint256 nftType);
    function useNft(uint256 _nftId) public isInitialized nonReentrant{
        require(activeFeatures.vaultActive && activeFeatures.useNft && minerNftInfo[_nftId].nftType > 0 && minerNftInfo[_nftId].nftType < 3 && !minerNftInfo[_nftId].isDisabled && vaultAddresses.nftContract.balanceOf(msg.sender,_nftId) > 0,'Cant Use');
        // require(!minerNftInfo[_nftId].isDisabled,'NFT Disabled');
        // require(vaultAddresses.nftContract.balanceOf(msg.sender,_nftId) > 0, 'No NFT Balance');

        // send the NFT
        vaultAddresses.nftContract.safeTransferFrom( msg.sender, address(this), _nftId, 1, "");
        
        // burn the NFT
        vaultAddresses.nftContract.safeTransferFrom( address(this), burnAddress, _nftId, 1, "");

        // if the type is instant, give them instant shares
        if(minerNftInfo[_nftId].nftType == 2){
            // direct amount
            claimedWorkers[msg.sender] = minerNftInfo[_nftId].amount * COST_FOR_SHARE;
            //claimedWorkers[msg.sender] = adjustTokenShares(minerNftInfo[_nftId].amount) * COST_FOR_SHARE;
            _claimWorkers(msg.sender,msg.sender,false);
        } else if(minerNftInfo[_nftId].nftType == 3){
            // adjusted amount
            claimedWorkers[msg.sender] = adjustTokenShares(minerNftInfo[_nftId].amount) * COST_FOR_SHARE;
            _claimWorkers(msg.sender,msg.sender,false);
        } else {
            // otherwise set the current multiplier    
            currentMultiplier[msg.sender].nftId = _nftId;
            currentMultiplier[msg.sender].lifetime = minerNftInfo[_nftId].lifetime;
            currentMultiplier[msg.sender].startTime = block.timestamp;
            currentMultiplier[msg.sender].endTime = block.timestamp + minerNftInfo[_nftId].lifetime;
            currentMultiplier[msg.sender].multiplier = minerNftInfo[_nftId].multiplier;
        }

        emit NftUsed(msg.sender, _nftId, minerNftInfo[_nftId].nftType );

    }

    //gets shares of an address
    function getShares(address _addr) public view returns(uint256){
        return getMyShares(_addr);
    }


    function giveShares(address _addr, uint256 _amount, bool _forceClaim) public {
        require(canGive[msg.sender], "Can't give");
        _addShares(_addr,_amount,_forceClaim);
    }

    function removeShares(address _addr, uint256 _amount) public {
        require(canGive[msg.sender], "Can't remove");
        _removeShares(_addr,_amount,false);
    }


    //adds shares
    function _addShares(address _addr, uint256 _amount, bool _forceClaim) private {

        claimedWorkers[_addr] = claimedWorkers[_addr] + (_amount * COST_FOR_SHARE) / 1 ether;
        if(_forceClaim){
            _claimWorkers(_addr,_addr,false);
        }
    }

    //removes shares
    function _removeShares(address _addr, uint256 _amount, bool direct) private {
        // claim first
        if(!direct){
            _claimWorkers(_addr,_addr,false);
        }

        uint256 toRemove = _amount/ 1 ether;
        userShares[_addr] = userShares[_addr] - toRemove;
        totalShares = totalShares - toRemove;
        
        // remove workers from the market

        marketWorkers = marketWorkers - ((toRemove * COST_FOR_SHARE)/5);
    }

    /**
     * @dev Exit the vault by giving up all of your shares
     * We give up to 50% of the shares value, up to their initial investment
     * user data is reset 
     */
    event UserGTFO(address indexed user, uint256 shares, uint256 amount); 
    function GTFO() public nonReentrant {
        require(
            userStats[msg.sender].purchaseValue > 0 &&
            block.timestamp >= (userStats[msg.sender].lastSell + minerSettings.sellDuration)
            , 'Cant GTFO');

        _claimWorkers(msg.sender,msg.sender,false);

        uint256 shares = getMyShares(msg.sender);
        uint256 maxReturn = getSharesValue(shares)/2;
        uint256 toSend = maxReturn;

        if(maxReturn > userStats[msg.sender].purchaseValue){
            toSend = userStats[msg.sender].purchaseValue;
        }


        // reset the user
        delete userStats[msg.sender];

        // flag the reset
        userStats[msg.sender].lastReset = block.timestamp;

        // remove the shares
        _removeShares(msg.sender,shares * 1 ether,true);

        if(toSend > 0) {
            (bool sent,) = payable(msg.sender).call{value: (toSend)}("");
            require(sent,"send failed");
        }

        emit UserGTFO(msg.sender, shares, toSend);

    }


    function extendLiquidityLock(uint256 secondsUntilUnlock) public onlyOwner {
        uint256 newUnlockTime = secondsUntilUnlock+block.timestamp;
        require(newUnlockTime>liquidityUnlockTime);
        liquidityUnlockTime=newUnlockTime;
    }

    // unlock time for contract LP
    uint256 public liquidityUnlockTime;

    // default for new lp added after release
    uint256 private constant DefaultLiquidityLockTime=14 days;

    //Release Liquidity Tokens once unlock time is over
    function releaseLiquidity() public onlyOwner {
        //Only callable if liquidity Unlock time is over
        require(block.timestamp >= liquidityUnlockTime, "Locked");
        liquidityUnlockTime=block.timestamp+DefaultLiquidityLockTime;       
        IPancakeERC20 liquidityToken = IPancakeERC20(vaultAddresses.lpAddress);
        // uint256 amount = liquidityToken.balanceOf(address(this));

        // only allow 20% 
        // amount=amount*2/10;
        liquidityToken.transfer(vaultAddresses.treasuryWallet, (liquidityToken.balanceOf(address(this)) * 2) / 10);
    }

    // // burn all mPCKT in the contract, this gets built up when adding LP
    // @TODO need to exclude locked tokens
    // function burnLeftovers() public onlyOwner {
    //     tokenIds[1].transferFrom(address(this), burnAddress, tokenIds[1].balanceOf(address(this)) );
    // }

    function processTokens(uint256 _amount) public {
        // move the tokens
        vaultAddresses.stable.safeTransferFrom(address(msg.sender), address(this), _amount);
        _processTokens(_amount);
    }

    event OnVaultReceive(address indexed sender, uint256 amount, uint256 toLp, uint256 toTvl);
    function _processTokens(uint256 stableTokens) public {
        // Send half to LP
        uint256 lpBal = stableTokens / 2;
        uint256 shareBal = stableTokens - lpBal;

        //if we have no shares 100% LP    
        if(totalShares <= 0){
            lpBal = stableTokens;
            shareBal = 0;
        }

        // send any cross chain vault sends or returned change to all the share holders 
        if(!activeFeatures.lpEnabled || msg.sender == address(pancakeRouter) || msg.sender == address(vaultAddresses.gatewayAddress)){
            lpBal = 0;
            shareBal = stableTokens;
        } else {

            // split the LP part in half
            uint256 stableToSpend = lpBal / 2;
            uint256 stableToPost = lpBal - stableToSpend;

            // get the current mPCKT balance
            uint256 contractTokenBal = vaultAddresses.token.balanceOf(address(this));
           
            // do the swap
            // vaultAddresses.tokenSwap.swapNativeForToken(stableToSpend, tokenIds[1], address(this));
            vaultAddresses.tokenSwap.swapTokenForToken(stableToSpend, vaultAddresses.stable, vaultAddresses.token, address(this));

            //new balance
            uint256 tokenToPost = vaultAddresses.token.balanceOf(address(this)) - contractTokenBal;

            // add LP
            vaultStats.totalLPNative+=stableToPost;
            vaultStats.totalLPToken+=tokenToPost;
            // vaultAddresses.tokenSwap.addLiquidityNative(tokenIds[1],tokenToPost, nativeToPost, address(this));
            vaultAddresses.tokenSwap.addLiquidity(vaultAddresses.token,vaultAddresses.stable, tokenToPost, stableToPost, address(this));

            emit OnVaultReceive(msg.sender, stableTokens, lpBal, shareBal);
        }
    }

    
    receive() external payable {


        // convert to stable
        // get the current stable balance 
        uint256 contractStableBal = vaultAddresses.stable.balanceOf(address(this));
        
        // do the swap
        vaultAddresses.tokenSwap.swapNativeForToken(msg.value, vaultAddresses.stable, address(this));

        //stable balance to split
        uint256 stableTokens =  vaultAddresses.stable.balanceOf(address(this)) - contractStableBal;

        _processTokens(stableTokens);

        
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;

interface IPancakeERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IPancakeRouter01 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getamountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getamountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getamountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getamountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11; 

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import '@openzeppelin/contracts/utils/Strings.sol';
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import './ProxyRegistry.sol';
import './Concat.sol';

/**
 * @title ERC1155Tradable
 * ERC1155Tradable - ERC1155 contract that whitelists an operator address,
 * has create and mint functionality, and supports useful standards from OpenZeppelin,
  like _exists(), name(), symbol(), and totalSupply()
 */
contract ERC1155Tradable is ERC1155, Ownable, AccessControl {
    using SafeMath for uint256;
    using Strings for string;

//    address proxyRegistryAddress;
    uint256 private _currentTokenID = 0;
    mapping(uint256 => address) public creators;
    mapping(uint256 => uint256) public tokenSupply;
    mapping(uint256 => uint256) public tokenMaxSupply;
    mapping(uint256 => uint256) public tokenInitialMaxSupply;

    address public constant burnWallet = address(0xdead);
    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");


    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
//        address _proxyRegistryAddress
    ) ERC1155(_uri) {
        name = _name;
        symbol = _symbol;
//        proxyRegistryAddress = _proxyRegistryAddress;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);

    }

    function uri(uint256 _id) public override view returns (string memory) {
        require(_exists(_id), "erc721tradable#uri: NONEXISTENT_TOKEN");
        string memory _uri = super.uri(_id);
        return Concat.strConcat(_uri, Strings.toString(_id));
    }


    function totalSupply(uint256 _id) public view returns (uint256) {
        return tokenSupply[_id];
    }

    function maxSupply(uint256 _id) public view returns (uint256) {
        return tokenMaxSupply[_id];
        // return tokenMaxSupply[_id];
    }

    function initialMaxSupply(uint256 _id) public view returns (uint256) {
        return tokenInitialMaxSupply[_id];
        // return tokenMaxSupply[_id];
    }

    function create(
        uint256 _maxSupply,
        uint256 _initialSupply,
        string calldata _uri,
        bytes calldata _data
    ) external returns (uint256 tokenId) {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        require(_initialSupply <= _maxSupply, "initial supply cannot be more than max supply");
        
        uint256 _id = _getNextTokenID();
        _incrementTokenTypeId();
        creators[_id] = msg.sender;

        if (bytes(_uri).length > 0) {
            emit URI(_uri, _id);
        }

         if (_initialSupply != 0) _mint(msg.sender, _id, _initialSupply, _data);
      
        tokenSupply[_id] = _initialSupply;
        tokenMaxSupply[_id] = _maxSupply;
        tokenInitialMaxSupply[_id] = _maxSupply;
        return _id;
    }

    function mint(
//        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    ) public {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        
        uint256 newSupply = tokenSupply[_id].add(_quantity);
        require(newSupply <= tokenMaxSupply[_id], "max NFT supply reached");
        // _mint(_to, _id, _quantity, _data);
        _mint(msg.sender, _id, _quantity, _data);
        tokenSupply[_id] = tokenSupply[_id].add(_quantity);
    }

    /**
        * @dev Mint tokens for each id in _ids
        * @param _to          The address to mint tokens to
        * @param _ids         Array of ids to mint
        * @param _quantities  Array of amounts of tokens to mint per id
        * @param _data        Data to pass if receiver is contract
    */
    function mintBatch(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _quantities,
        bytes memory _data
    ) public {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");

        for (uint256 i = 0; i < _ids.length; i++) {
          uint256 _id = _ids[i];
          uint256 quantity = _quantities[i];
          uint256 newSupply = tokenSupply[_id].add(quantity);
          require(newSupply <= tokenMaxSupply[_id], "max NFT supply reached");
          
          tokenSupply[_id] = tokenSupply[_id].add(quantity);
        }
        _mintBatch(_to, _ids, _quantities, _data);
    }

    function burn(
        address _address, 
        uint256 _id, 
        uint256 _amount
    ) external virtual {
        require((msg.sender == _address) || isApprovedForAll(_address, msg.sender), "ERC1155#burn: INVALID_OPERATOR");
        require(balanceOf(_address,_id) >= _amount, "Trying to burn more tokens than you own");

        // _burnAndReduce(_address,_id,_amount);
        _burn(_address, _id, _amount);
    }
/*
    function _burnAndReduce(
        address _address, 
        uint256 _id, 
        uint256 _amount
    ) internal {
        // reduce the total supply
        tokenMaxSupply[_id] = tokenMaxSupply[_id].sub(_amount);
        _burn(_address, _id, _amount);
    }
*/
    /* dev Check if we are sending to the burn address and burn and reduce supply instead */ 
  /*  function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator,from,to,ids,amounts,data);

        // check if to is the burn address and burn tokens
        if(to == burnWallet){
            for(uint256 i = 0; i <= ids.length; ++i){
                require(balanceOf(from,ids[i]) >= amounts[i], "Trying to burn more tokens than you own");
                _burnAndReduce(from,ids[i],amounts[i]);
            }
        }
    }
    */
    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings - The Beano of NFTs
     */
    function isApprovedForAll(address _owner, address _operator) public override view returns (bool isOperator) {
        // Whitelist OpenSea proxy contract for easy trading.
/*        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }
*/
        return ERC1155.isApprovedForAll(_owner, _operator);
    }

    function _exists(uint256 _id) internal view returns (bool) {
        return creators[_id] != address(0);
    }

    function _getNextTokenID() private view returns (uint256) {
        return _currentTokenID.add(1);
    }

    function _incrementTokenTypeId() private {
        _currentTokenID++;
    }

     /**
     * @notice Indicates whether a contract implements the `ERC1155TokenReceiver` functions and so can accept ERC1155 token types.
     * @param  interfaceID The ERC-165 interface ID that is queried for support.s
     * @dev This function MUST return true if it implements the ERC1155TokenReceiver interface and ERC-165 interface.
     *      This function MUST NOT consume more than 5,000 gas.
     * @return Wheter ERC-165 or ERC1155TokenReceiver interfaces are supported.
     */
    function supportsInterface(bytes4 interfaceID) public view virtual override(AccessControl,ERC1155) returns (bool) {
        return  interfaceID == 0x01ffc9a7 ||    // ERC-165 support (i.e. `bytes4(keccak256('supportsInterface(bytes4)'))`).
        interfaceID == 0x4e2312e0;      // ERC-1155 `ERC1155TokenReceiver` support (i.e. `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) ^ bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

library Concat {
  // via https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
  function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory) {
      bytes memory _ba = bytes(_a);
      bytes memory _bb = bytes(_b);
      bytes memory _bc = bytes(_c);
      bytes memory _bd = bytes(_d);
      bytes memory _be = bytes(_e);
      string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
      bytes memory babcde = bytes(abcde);
      uint k = 0;
      for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
      for (uint i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
      for (uint i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
      for (uint i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
      for (uint i = 0; i < _be.length; i++) babcde[k++] = _be[i];
      return string(babcde);
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
        return strConcat(_a, _b, "", "", "");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "./TokenSwap.sol";
import "./libs/ERC1155Tradable.sol";
import "./libs/PancakeLibs.sol";

contract VaultMiner is Context, Ownable, IERC1155Receiver, ReentrancyGuard {

    using SafeERC20 for IERC20;
    
   // IERC20 internal token;
   // ERC1155Tradable internal nftContract;

    // The burn address
    address public constant burnAddress = address(0xdead);

    // where the tokens get sent too after buys, default to burn
//    address internal tokenReceiver = address(0xdead);

    IPancakeRouter02 public immutable pancakeRouter;
    // address internal immutable pancakePair;

    uint256 internal constant COST_FOR_SHARE = 1080000;
    uint256 private PSN = 10000;
    uint256 private PSNH = 5000;
    

    bool private initialized = false;
//    address payable internal treasuryWallet;
//    address payable internal investWallet;
//    address payable internal devWallet;

    mapping (address => uint256) internal userShares;
    mapping (address => uint256) internal claimedWorkers;
    mapping (address => address) internal referrals;
    mapping (address => uint256) internal lastClaim;
    mapping (address => IERC20) public harvestToken;

    mapping(address => bool) internal canGive;
    uint256 public marketWorkers;

    uint256 public totalShares;    

    // hard cap Penalty fee of 60% max
    uint256 private constant MAX_PENALTY_FEE = 600;

    // hard cap buy in fee of 20% max
    uint256 private constant MAX_BUY_FEE = 200;

    // hard cap on the max NFT multiplier 3x max
    uint256 private constant MAX_NFT_MULTIPLIER = 300;

    // hard cap of 15% on the referral fees
    uint256 private constant MAX_REF_FEE = 150;

    struct VaultAddresses {
        address nftPacksAddress; // Nft Packs Address
        address nftRewardsAddress; // Nft Rewards Address
        address gatewayAddress; // bridge gateway
        address lpAddress; //LP token are locked in the contract
        TokenSwap tokenSwap; // contract to swap tokens and add LP
        IERC20 token;
        IERC20 stable;
        ERC1155Tradable nftContract;
        address tokenReceiver;
        address payable treasuryWallet;
        address payable investWallet;
        address payable devWallet;
    }

    struct ActiveFeatures {
        bool vaultActive; // global active flag
        bool lpEnabled; // if we add to lp or not
        bool giveNfts; // locking, giving and burning nfts
        bool minerBuy; // buying/selling in the miner 
        bool minerCompound; // compounding 
        bool burnTokens; // buring tokeins for hares
        bool useNft; // using vault NFTS
    }

    struct FeesInfo {
        uint256 refFee;
        uint256 buyFee;
        uint256 devFee;
        uint256 treasuryFee;
        uint256 investFee;
        uint256 buyPenalty;
        uint256 devPenalty;
        uint256 treasuryPenalty;
        uint256 investPenalty;
    }

    struct UserStats {
        uint256 purchases; // how many times they bought shares
        uint256 purchaseAmount; // total amount they have purchased
        uint256 purchaseValue; // total value they have purchased 
        uint256 compounds; // how many times they have compounded
        uint256 compoundAmount; // total amount they have compounded
        uint256 compoundValue; // total value they have compounded (at time of compound) 
        uint256 lastSell; // timestamp of last sell
        uint256 sells; // how many times they sold shares
        uint256 sellAmount; // total amount they have sold
        uint256 sellValue; // total value they have sold
        uint256 firstBuy; //when they made their first buy
        uint256 refRewards; // total value of ref rewards (at time of purchase) 
        uint256 lastReset; // the time stamp if they reset the account and GTFO
    }

    struct MinerNftInfo {
        uint256 nftType; // 1 for percent - 2 for instant shares 1:1 - 3 for instant shares adjusted
        uint256 amount; // how many shares this gives (only applies to type 2)
        uint256 lifetime; // time in seconds this is active (only applies to type 1)
        uint256 multiplier;  // multiply new shares by this amount (only applies to type 1)
        uint256 totalUsed; // how many nfts were used
        bool isDisabled; // so we can hide ones we don't want
    }

    struct MultiplierInfo {
        uint256 nftId; 
        uint256 lifetime; // time in seconds this is active 
        uint256 startTime; // time stamp it was staked
        uint256 endTime; // time stamp it when it ends
        uint256 multiplier;  // multiply new shares by this amount (only applies to type 1)
    }

    struct MinerSettings {
        uint256 maxPerAddress;
        uint256 minBuy;
        uint256 maxBuy;
        uint256 minRefAmount;
        uint256 maxRefMultiplier;
        uint256 sellDuration;
        // bool buyFromTokenEnabled;
        bool noSell;
        bool refCompoundEnabled;
    }

    struct VaultStats {
        uint256 totalLPNative; // total Native added to LP
        uint256 totalLPToken; // total token added to LP
        uint256 totalTokensBurned; // total tokens burne
    }
    
  
    mapping(uint256 => MinerNftInfo) public minerNftInfo;
    mapping(address => MultiplierInfo) public currentMultiplier;
    mapping(address => UserStats) public userStats;
    
    ActiveFeatures public activeFeatures;
    FeesInfo public fees;
    MinerSettings public minerSettings;
    VaultAddresses public vaultAddresses;
    VaultStats public vaultStats;

    event FeeChanged(uint256 refFee, uint256 fee, uint256 penaltyFees, uint256 timestamp);

    constructor(
        address payable _devWallet, 
        address payable _treasuryWallet, 
        address payable _investWallet, 
        TokenSwap _tokenSwap,
        IERC20 _token, 
        IERC20 _stable, 
        ERC1155Tradable _nftContract,
        address _router) {

        vaultAddresses.treasuryWallet = payable(_treasuryWallet);
        vaultAddresses.investWallet = payable(_investWallet);
        vaultAddresses.devWallet = payable(_devWallet);
        vaultAddresses.tokenReceiver = address(0xdead);
        vaultAddresses.tokenSwap = _tokenSwap;
        vaultAddresses.token = _token;
        vaultAddresses.stable = _stable;
        vaultAddresses.nftContract = _nftContract;
        
       
        // 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        IPancakeRouter02 _pancakeRouter = IPancakeRouter02(
            _router
        );
        // get a uniswap pair for this token
       // vaultAddresses.lpAddress = IPancakeFactory(_pancakeRouter.factory())
        //    .createPair(address(_token),address(_stable));

        vaultAddresses.lpAddress = vaultAddresses.tokenSwap.getTokenLpAddress(_token,_stable);
        pancakeRouter = _pancakeRouter;


        
        vaultAddresses.token.approve(address(pancakeRouter), type(uint256).max);
        vaultAddresses.stable.approve(address(pancakeRouter), type(uint256).max);

        vaultAddresses.token.approve(address(this), type(uint256).max);
        vaultAddresses.stable.approve(address(this), type(uint256).max);
        // nftContract.setApprovalForAll(address(this),true);

        // default fees
        fees = FeesInfo({
            refFee: 90,
            buyFee: 20,
            devFee: 6,
            treasuryFee: 24,
            investFee: 10,
            buyPenalty: 200,
            devPenalty: 60,
            treasuryPenalty: 240,
            investPenalty: 100
        });

        // default settings
        minerSettings = MinerSettings({
            maxPerAddress: 10000 * 1 ether,
            minBuy: 5 * 1 ether,
            maxBuy: 1000 * 1 ether,
            minRefAmount: 50 * 1 ether,
            maxRefMultiplier: 30,
            sellDuration: 6 days,
            // buyFromTokenEnabled: true,
            noSell: false,
            refCompoundEnabled: false
        });
    }
    
   // event SetHarvestToken(address indexed user, IERC20 token);
    function setHarvestToken(IERC20 _harvestToken)  external {
        harvestToken[msg.sender] = _harvestToken;
     //   emit SetHarvestToken(msg.sender, _harvestToken);
    }
    
    function claimWorkers(address ref) public isInitialized nonReentrant {
        _claimWorkers(msg.sender,ref, false);
    }

    function getMaxRefRewards(address addr) public view returns(uint256){
        return (userStats[addr].purchaseValue * minerSettings.maxRefMultiplier) / 10;
    }

    event WorkersClaimed(address indexed user, address indexed ref, uint256 newShares, uint256 userWorkers, uint256 refWorkers);
    function _claimWorkers(address addr, address ref, bool isBuy) internal {
        require(activeFeatures.vaultActive && activeFeatures.minerCompound, 'disabled');
        // require(isBuy || block.timestamp > (lastClaim[addr] + compoundDuration), 'Too soon' );
        if(ref == addr) {
            ref = address(0);
        }
        
        if(referrals[addr] == address(0) && referrals[addr] != addr && referrals[referrals[addr]] != addr) {
            referrals[addr] = ref;
        }

        bool hasRef = referrals[addr] != address(0) && referrals[addr] != addr && userStats[referrals[addr]].purchaseValue >= minerSettings.minRefAmount;
        
        uint256 workersUsed = getMyWorkers(addr);
        // uint256 userWorkers;
        uint256 refWorkers;

        if(hasRef && (isBuy || minerSettings.refCompoundEnabled)) {
            refWorkers = getFee(workersUsed,fees.refFee);

            // check if we hit max ref rewards
            if((userStats[referrals[addr]].refRewards + calculateWorkerSell(refWorkers)) < getMaxRefRewards(referrals[addr]) ){

                //send referral workers
                claimedWorkers[referrals[addr]] = claimedWorkers[referrals[addr]] + refWorkers;
                userStats[referrals[addr]].refRewards = userStats[referrals[addr]].refRewards + calculateWorkerSell(refWorkers);
                } else {
                    refWorkers =0;
                }
        }
       


        if(isBuy){
            userStats[addr].purchases = userStats[addr].purchases + 1;
            userStats[addr].purchaseAmount = userStats[addr].purchaseAmount + workersUsed; 
        } else {
            userStats[addr].compounds = userStats[addr].compounds + 1;
            userStats[addr].compoundAmount = userStats[addr].compoundAmount + workersUsed; 
            userStats[addr].compoundValue = userStats[addr].compoundValue + calculateWorkerSell(workersUsed); 
        }

        // uint256 newShares = userWorkers/COST_FOR_SHARE;
        uint256 newShares = workersUsed/COST_FOR_SHARE;
        
        userShares[addr] = userShares[addr] + newShares;
        totalShares = totalShares + newShares;

        claimedWorkers[addr] = 0;
        lastClaim[addr] = block.timestamp;
         
        //boost market to nerf shares hoarding
        marketWorkers = marketWorkers + (workersUsed/5);

        emit WorkersClaimed(addr, ref, newShares, workersUsed, refWorkers);
    }


    event WorkersSold(address indexed user,  uint256 amount, uint256 workersSold );
    function sellWorkers() public isInitialized nonReentrant {
        require(
            activeFeatures.vaultActive && 
            activeFeatures.minerBuy && 
            (!minerSettings.noSell || block.timestamp > (userStats[msg.sender].lastSell + minerSettings.sellDuration)), 
            'too soon to sell');

        uint256 hasWorkers = getMyWorkers(msg.sender);
        uint256 workerValue = calculateWorkerSell(hasWorkers);

        uint256 fee = getFee(workerValue,totalFees());
        uint256 toBuy = getFee(workerValue,fees.buyFee);
        uint256 toDev = getFee(workerValue,fees.devFee);
        uint256 toTreasury = getFee(workerValue,fees.treasuryFee);
        uint256 toInvest = getFee(workerValue,fees.investFee);

        if(!minerSettings.noSell && block.timestamp < (userStats[msg.sender].lastSell + minerSettings.sellDuration)){
            // use the penalty fees
            fee = getFee(workerValue, (fees.buyPenalty + fees.devPenalty + fees.treasuryPenalty + fees.investPenalty));
            toBuy = getFee(workerValue,fees.buyPenalty);
            toDev = getFee(workerValue,fees.devPenalty);
            toTreasury = getFee(workerValue,fees.treasuryPenalty);
            toInvest = getFee(workerValue,fees.investPenalty);
        }

        claimedWorkers[msg.sender] = 0;
        lastClaim[msg.sender] = block.timestamp;
        marketWorkers = marketWorkers + hasWorkers;

        userStats[msg.sender].lastSell = block.timestamp; 
        userStats[msg.sender].sells = userStats[msg.sender].sells + 1; 
        userStats[msg.sender].sellAmount = userStats[msg.sender].sellAmount + hasWorkers;
        userStats[msg.sender].sellValue = userStats[msg.sender].sellValue + (workerValue-fee);

        if(toDev > 0) {
            vaultAddresses.stable.safeTransferFrom(address(this), address( vaultAddresses.devWallet), toDev);
        }

        if(toTreasury > 0) {
            vaultAddresses.stable.safeTransferFrom(address(this), address( vaultAddresses.treasuryWallet), toTreasury);
        }

        if(toInvest > 0) {
            vaultAddresses.stable.safeTransferFrom(address(this), address( vaultAddresses.investWallet), toInvest);
        }
       
 
        if(toBuy > 0) {
            swapFromFees(toBuy);
        }

        if(harvestToken[msg.sender] == IERC20(address(0)) || harvestToken[msg.sender] == IERC20(vaultAddresses.stable) ){
            // send to the user
            vaultAddresses.stable.safeTransferFrom(address(this), address( msg.sender), workerValue-fee);
        } else if(harvestToken[msg.sender] == IERC20(address(1))){
            // convert to native
            vaultAddresses.tokenSwap.swapTokenForNative(workerValue-fee, vaultAddresses.stable, msg.sender); 
        } else {
            // swap to custom
            vaultAddresses.tokenSwap.swapTokenForToken(workerValue-fee, vaultAddresses.stable, harvestToken[msg.sender], msg.sender); 
        }
  
        emit WorkersSold(msg.sender, workerValue, hasWorkers );
    }
    
    function pendingRewards(address adr) public view returns(uint256) {
        uint256 hasWorkers = getMyWorkers(adr);
        if(hasWorkers == 0){
            return 0;
        }
        uint256 workerValue = calculateWorkerSell(hasWorkers);
        return workerValue;
    }
    
    function buyWorkers(address ref, uint256 amount) public isInitialized nonReentrant {
        return _buyWorkers(msg.sender, amount, ref, false);
    }
/*
    function contractBuyWorkers(address _user, address _ref, uint256 amount) public isInitialized {
        require(canGive[msg.sender], "Not Allowed");
        return _buyWorkers(_user, amount, _ref, true);
    }*/

    event WorkersBought(address indexed user, address indexed ref, uint256 amount, uint256 workersBought, bool fromSwap );
    function _buyWorkers(address user, uint256 amount, address ref,  bool fromSwap) internal {
        // require(amount >= minerSettings.minBuy, 'Buy too small');
        require(
            activeFeatures.vaultActive && 
            activeFeatures.minerBuy && 
            amount >= minerSettings.minBuy && 
            amount <= minerSettings.maxBuy &&
            (minerSettings.maxPerAddress == 0 || (userStats[user].purchaseValue + amount) <= minerSettings.maxPerAddress)
            , 'Cant Buy');
        // require(minerSettings.maxPerAddress == 0 || (userStats[user].purchaseValue + amount) <= minerSettings.maxPerAddress, 'Max buy amount reached');
        
        // move the tokens
        vaultAddresses.stable.safeTransferFrom(address(msg.sender), address(this), amount);

        uint256 fee = totalFees();
        
        uint256 workersBought = calculateWorkerBuy(amount,(vaultAddresses.stable.balanceOf(address(this)) - amount));
        workersBought = workersBought - getFee(workersBought,fee);

        // see if we have a valid multiplier nft
        if(currentMultiplier[user].startTime > 0) {
            if(currentMultiplier[user].endTime < block.timestamp) {
                // expired, reset the current multiplier
                delete currentMultiplier[user];
            } else {
                // valid multiplier, multiply the post fee amount 
                workersBought = ((workersBought * currentMultiplier[user].multiplier)/100);
            }
        }

        uint256 toBuy = getFee(amount,fees.buyFee);
        uint256 toDev = getFee(amount,fees.devFee);
        uint256 toTreasury = getFee(amount,fees.treasuryFee);
        uint256 toInvest = getFee(amount,fees.investFee);

        if(userStats[user].firstBuy == 0){
            userStats[user].firstBuy = block.timestamp;
        }

        userStats[user].purchaseValue = userStats[user].purchaseValue + amount; 
       
        
        if(toDev > 0) {
            vaultAddresses.stable.safeTransferFrom(address(this), address( vaultAddresses.devWallet), toDev);
        }

        if(toTreasury > 0) {
            vaultAddresses.stable.safeTransferFrom(address(this), address( vaultAddresses.treasuryWallet), toTreasury);
        }

        if(toInvest > 0) {
            vaultAddresses.stable.safeTransferFrom(address(this), address( vaultAddresses.investWallet), toInvest);
        }

        // do the buyback
        if(toBuy > 0) {
            swapFromFees(toBuy);
        }

        claimedWorkers[user] = claimedWorkers[user] + workersBought;

        emit WorkersBought(user, ref, amount, workersBought, fromSwap );

        _claimWorkers(msg.sender,ref,true);
    }

    


    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) internal view returns(uint256) {
        return (PSN * bs)/(PSNH + ( ((PSN * rs) + (PSNH * rt))/rt) );
    }
    
    function calculateWorkerSell(uint256 workers) public view returns(uint256) {
        return calculateTrade(workers,marketWorkers,vaultAddresses.stable.balanceOf(address(this)));
    }
    
    function calculateWorkerBuy(uint256 amount,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(amount,contractBalance,marketWorkers);
    }
    
    function calculateWorkerBuySimple(uint256 amount) public view returns(uint256) {
        return calculateWorkerBuy(amount,vaultAddresses.stable.balanceOf(address(this)));
    }
    
    function totalFees() internal view returns(uint256) {
        return fees.buyFee + fees.devFee + fees.treasuryFee + fees.investFee;
    }

    function getFee(uint256 amount, uint256 fee) internal pure returns(uint256) {
        return (amount * fee)/1000;
    }
    
    event MarketInitialized(uint256 timestamp);
    function seedMarket() public payable onlyOwner {
        require(marketWorkers == 0);

        initialized = true;
        marketWorkers = 108000000000;

        emit MarketInitialized(block.timestamp);
    }


    function setContracts(IERC20 _token, ERC1155Tradable _nftContract) public onlyOwner {
        vaultAddresses.token = _token;
        vaultAddresses.nftContract = _nftContract;
    }
    
    // manage which contracts/addresses can give shares to allow other contracts to interact
    function setCanGive(address _addr, bool _canGive) public onlyOwner {
        canGive[_addr] = _canGive;
    }


    function setWallets(
        address _devWallet, 
        address _treasuryWallet, 
        address _investWallet, 
        address _tokenReceiver 
    ) public onlyOwner {
        vaultAddresses.devWallet = payable(_devWallet);
        vaultAddresses.treasuryWallet = payable(_treasuryWallet);
        vaultAddresses.investWallet = payable(_investWallet);
        vaultAddresses.tokenReceiver = _tokenReceiver;
    }


    function setFees(
        uint256 _refFee,
        uint256 _buyFee, 
        uint256 _devFee, 
        uint256 _treasuryFee,
        uint256 _investFee,
        uint256 _buyPenalty, 
        uint256 _devPenalty, 
        uint256 _treasuryPenalty,
        uint256 _investPenalty
    ) public onlyOwner {

        require(_refFee <= MAX_REF_FEE && (_buyFee + _devFee + _treasuryFee + _investFee) <= MAX_BUY_FEE && (_buyPenalty + _devPenalty + _treasuryPenalty + _investPenalty) <= MAX_PENALTY_FEE, 'fee too high');
        // require((_buyFee + _devFee + _investFee) <= MAX_BUY_FEE, "Fee capped at 20%");
        // require((_buyPenalty + _devPenalty + _investPenalty) <= MAX_PENALTY_FEE, "Penalty capped at 60%");

         fees = FeesInfo({
            refFee: _refFee,
            buyFee: _buyFee,
            devFee: _devFee,
            treasuryFee: _treasuryFee,
            investFee: _investFee,
            buyPenalty: _buyPenalty,
            devPenalty: _devPenalty,
            treasuryPenalty: _treasuryPenalty,
            investPenalty: _investPenalty
        });

        emit FeeChanged(_refFee, (_buyFee + _devFee + _treasuryFee + _investFee), (_buyPenalty + _devPenalty + _treasuryPenalty + _investPenalty), block.timestamp);
    }

    function setActiveFeatures(
        bool _vaultActive,
        bool _lpEnabled,
        bool _giveNfts, 
        bool _minerBuy, 
        bool _minerCompound, 
        bool _burnTokens, 
        bool _useNft
    ) public onlyOwner {
        activeFeatures.vaultActive = _vaultActive;
        activeFeatures.lpEnabled = _lpEnabled;
        activeFeatures.giveNfts = _giveNfts;
        activeFeatures.minerBuy = _minerBuy;
        activeFeatures.minerCompound = _minerCompound;
        activeFeatures.burnTokens = _burnTokens;
        activeFeatures.useNft = _useNft;
    }

    function setMinerSettings(
        uint256 _maxPerAddress, 
        uint256 _minBuy, 
        uint256 _maxBuy,
        uint256 _minRefAmount, 
        uint256 _maxRefMultiplier,
        uint256 _sellDuration,
        // bool _buyFromTokenEnabled,
        bool _noSell,
        bool _refCompoundEnabled
    ) public onlyOwner {
        

         minerSettings = MinerSettings({
            maxPerAddress: _maxPerAddress,
            minBuy: _minBuy,
            maxBuy: _maxBuy,
            minRefAmount: _minRefAmount,
            maxRefMultiplier: _maxRefMultiplier,
            sellDuration: _sellDuration,
            // buyFromTokenEnabled: _buyFromTokenEnabled,
            noSell: _noSell,
            refCompoundEnabled: _refCompoundEnabled
        });

    }


    function setMinerNftInfo(
        uint256 _nftId, 
        uint256 _nftType,
        uint256 _amount,
        uint256 _lifetime,
        uint256 _multiplier) public onlyOwner {
        

        require(_multiplier <= MAX_NFT_MULTIPLIER, 'Multiplier too high');

        minerNftInfo[_nftId].nftType = _nftType;
        minerNftInfo[_nftId].amount = _amount; 
        minerNftInfo[_nftId].lifetime = _lifetime; 
        minerNftInfo[_nftId].multiplier = _multiplier; 

    }

    function setMinerNftDisabled(uint256 _nftId, bool _isDisabled) public onlyOwner {
        minerNftInfo[_nftId].isDisabled = _isDisabled;        
    }
    
    function getBalance() public view returns(uint256) {
        return vaultAddresses.stable.balanceOf(address(this));
    }
    
    function getMyShares(address adr) public view returns(uint256) {
        return userShares[adr];
    }
    
    function getMyWorkers(address adr) public view returns(uint256) {
        return claimedWorkers[adr] + getWorkersSinceLastClaim(adr);
    }
    
    function getWorkersSinceLastClaim(address adr) public view returns(uint256) {
        return min(COST_FOR_SHARE,(block.timestamp - lastClaim[adr])) * userShares[adr];
    }

    function getReferral(address adr) public view returns(address) {
        return referrals[adr];
    }

    function getLastClaim(address adr) public view returns(uint256) {
        return lastClaim[adr];
    }

    function getSharesValue(uint256 shares) public view returns(uint256) {
        return calculateWorkerSell(shares * COST_FOR_SHARE);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

/*    function buyFromToken(uint256 tokenAmount, IERC20 tokenAddress, address ref) public isInitialized {
        require(minerSettings.buyFromTokenEnabled,'not enabled');

        // transfer the ERC20 token
        tokenAddress.safeTransferFrom(address(msg.sender), address(this), tokenAmount);

        // get current balance
        uint256 currentBalance = vaultAddresses.stable.balanceOf(address(this));

        // do the swap
        vaultAddresses.tokenSwap.swapTokenForNative(tokenAmount, tokenAddress, address(this));

        // get new balance and amount to buy
        uint256 toBuy = vaultAddresses.stable.balanceOf(address(this)) - currentBalance;

        // make the buy
        _buyWorkers(msg.sender,toBuy,ref,true);
    }
*/
    
    // swap and send to the token receiver
    function swapFromFees(uint256 amount) private {
         // vaultAddresses.tokenSwap.swapNativeForToken(amount, token, address(vaultAddresses.tokenReceiver));
         vaultAddresses.tokenSwap.swapTokenForToken(amount, vaultAddresses.stable, vaultAddresses.token, address(vaultAddresses.tokenReceiver));
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure override returns(bytes4) {
      return 0xf23a6e61;
    }


    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external pure override returns(bytes4) {
      return 0xbc197c81;
    }

    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
      return  interfaceID == 0x01ffc9a7 ||    // ERC-165 support (i.e. `bytes4(keccak256('supportsInterface(bytes4)'))`).
      interfaceID == 0x4e2312e0;      // ERC-1155 `ERC1155TokenReceiver` support (i.e. `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) ^ bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
    }

    modifier isInitialized {
      require(initialized, "Vault Miner has not been initialized");
      _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./libs/PancakeLibs.sol";

contract TokenSwap is Ownable, ReentrancyGuard {

	using SafeERC20 for IERC20;

	IPancakeRouter02 public immutable pancakeRouter;
	
	constructor(address _router) {

        IPancakeRouter02 _pancakeRouter = IPancakeRouter02(
            _router
        );
       
       /*// get a uniswap pair for this token
        pancakePair = IPancakeFactory(_pancakeRouter.factory())
            .createPair(address(_token),address(_stable));
*/
        pancakeRouter = _pancakeRouter;

    }
	
	function getTokenLpAddress(IERC20 tokenA, IERC20 tokenB) public view returns(address) {
		return IPancakeFactory(pancakeRouter.factory())
            .getPair(address(tokenA),address(tokenB));
		
	}

	function getNativeLpAddress(IERC20 token) public view returns(address){
		return IPancakeFactory(pancakeRouter.factory())
            .getPair(address(token),pancakeRouter.WETH());
	}

	//swaps Native for a token
    function swapNativeForToken(uint256 amount, IERC20 toToken, address toAddress) public {
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = address(toToken);

        pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            address(toAddress),
            block.timestamp
        );
    }

    //swaps token for a native
    function swapTokenForNative(uint256 amount, IERC20 fromToken, address toAddress) public {
        address[] memory path = new address[](2);
        path[0] = address(fromToken);
        path[1] = pancakeRouter.WETH();

        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(toAddress),
            block.timestamp
        );
    }

    //swaps token for token
    function swapTokenForToken(uint256 amount, IERC20 fromToken, IERC20 toToken, address toAddress) public {
        address[] memory path = new address[](2);
        path[0] = address(fromToken);
        path[1] = address(toToken);

        pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(toAddress),
            block.timestamp
        );
    }

    // LP Functions

    function addLiquidity(IERC20 tokenA, IERC20 tokenB, uint256 tokenAAmount, uint256 tokenBAmount, address toAddress) public {

        try pancakeRouter.addLiquidity(
            address(tokenA),
            address(tokenB),
            tokenAAmount,
            tokenBAmount,
            0,
            0,
            address(toAddress),
            block.timestamp
        ){}
        catch{}
    }

    function removeLiquidity(IERC20 tokenA, IERC20 tokenB, uint256 lpAmount, address toAddress) public {

        try pancakeRouter.removeLiquidity(
            address(tokenA),
            address(tokenB),
            lpAmount,
            0,
            0,
            address(toAddress),
            block.timestamp
        ){}
        catch{}
    }


    function addLiquidityNative( IERC20 toToken, uint256 tokenamount, uint256 nativeamount, address toAddress) public {
        try pancakeRouter.addLiquidityETH{value: nativeamount}(
            address(toToken),
            tokenamount,
            0,
            0,
            address(toAddress),
            block.timestamp
        ){}
        catch{}
    }

    function removeLiquidityNative(IERC20 toToken, uint256 lpAmount, address toAddress) public {
        try pancakeRouter.removeLiquidityETH(
            address(toToken),
            lpAmount,
            0,
            0,
            address(toAddress),
            block.timestamp
        ){}
        catch{}
    }


    

}