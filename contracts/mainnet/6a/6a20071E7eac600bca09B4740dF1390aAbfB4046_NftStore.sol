// SPDX-License-Identifier: MIT
/// @author MrD 

pragma solidity >=0.8.11;

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/ERC1155Tradable.sol";
import "./NftPacks.sol";
import "./Squads.sol";

interface IDEXPair {function sync() external;}

contract NftStore is Ownable, IERC1155Receiver, ReentrancyGuard, AccessControlEnumerable {
    using SafeERC20 for IERC20;

    ERC1155Tradable private nft;
    NftPacks private nftPacks;
    
    Squads private squadsContract;
    IERC20 private primaryToken;
    IERC20 private stable;

    bytes32 public constant TEAM_ROLE = keccak256("TEAM_ROLE");
    bytes32 public constant WHITELIST_ROLE = keccak256("WHITELIST_ROLE");

    // team/marketing wallet
    address payable private operationsWallet;

    // dev share wallet
    address payable private devWallet;

    // LP holding wallet - used when in distribution mode
    address payable private lpAddress;

    address public constant burnAddress = address(0xdead);
    bool public storeActive;

    uint256 public tvlPercent;
    uint256 public lpPercent;

    // if the LP address is a lp pair, this will send to the pair and sync to rebalance
    bool public lpSync;

    uint256 public totalPurchasedAmount;
    uint256 public totalStableAmount;
    uint256 public totalBurnAmount;
    uint256 public totalPointsAmount;
    uint256 public totalNftsRedeemed;
    uint256 public totalPacksRedeemed;
    mapping(address => uint256) public totalExtraPurchasedAmount;


    uint256 public tokenPriceMod = 1 ether;
    uint256 public stablePriceMod = 1 ether;
    uint256 public nativePriceMod = 1 ether;

    // required seconds between purchases
    uint256 public purchaseCoolDown;

    struct ItemInfo {
        uint256 id; //pack/card id
        uint256 nativePrice; // cost in Native Token/ETH etc.
        uint256 burnCost; // primary token burn cost
        uint256 stableCost; // primary token burn cost
        uint256 pointsCost; // squads prize points cost
        IERC20 extraToken; // erc20/bep20 token address, can be set by itself or with the
        uint256 extraPrice; // the amount of the erc20 passed in to charge
        uint256 maxRedeem;  // max that can be redeemed
        uint256 totalRedeemed;// total redeemed 
        bool isActive; // flag to check if the item is still active
        uint256 maxPerAddress; //max one address can get
        bool useWhitelist; // if true only addresses whitelisted for this item can redeem
    }


    // keep track of nfts and packs per address
    mapping(address => uint256) public totalUserNfts;
    mapping(address => uint256) public totalUserPacks;
    mapping(address => uint256) public lastPurchase;
    mapping(address => mapping(uint256 => uint256)) public userTotalByNft;
    mapping(address => mapping(uint256 => uint256)) public userTotalByPack;
    
    mapping(uint256 => ItemInfo) public nfts;
    mapping(uint256 => ItemInfo) public packs;
    mapping(uint256 => mapping(address => bool)) private packsWhitelist;
    mapping(uint256 => mapping(address => bool)) private nftsWhitelist;
    
    mapping(uint256 => mapping(address => bool)) private packVoucher;
    mapping(uint256 => mapping(address => bool)) private cardVoucher;
    


    event NftSet(uint256 nftId, uint256 amount, uint256 burn, uint256 amountStable, uint256 max);
    event PackSet(uint256 packId, uint256 amount, uint256 burn, uint256 amountStable, uint256 max);
    event NftRedeemed(address indexed user, uint256 stable, uint256 native, uint256 burn, uint256 points);
    event PackRedeemed(address indexed user, uint256 stable, uint256 native, uint256 burn, uint256 points);
    event SetSquadsContract(address indexed user, Squads contractAddress);
    event SetOperationsWallet(address indexed user, address operationsWallet);
    event SetDevWallet(address indexed user, address devWallet);
    event SetLpAddress(address indexed user, address lpAddress, bool lpSync);
    event NftVoucherSet(address indexed user, address indexed sender, uint256 nftId, bool hasVoucher);
    event PackVoucherSet(address indexed user, address indexed sender, uint256 packId, bool hasVoucher);

    constructor(
        ERC1155Tradable _nftAddress, 
        NftPacks _nftPacksAddress, 
        Squads _squadsContract, 
        IERC20 _tokenAddress,
        IERC20 _stableAddress,
        address payable _operationsWallet, 
        address payable _devWallet, 
        address payable _lpAddress, 
        uint256 _tvlPercent,
        uint256 _lpPercent
    ) {
        require(_operationsWallet != address(0), 'bad address');
        require(_devWallet != address(0), 'bad address');

        nft = _nftAddress;
        nftPacks = _nftPacksAddress;
        squadsContract = _squadsContract;
        primaryToken = _tokenAddress;
        stable = _stableAddress;
        squadsContract = _squadsContract;
        operationsWallet = _operationsWallet;
        devWallet = _devWallet;
        lpAddress = _lpAddress;
        tvlPercent = _tvlPercent;
        lpPercent = _lpPercent;

        _tokenAddress.approve(address(this), type(uint256).max);
        _stableAddress.approve(address(squadsContract), type(uint256).max);
        _stableAddress.approve(address(this), type(uint256).max);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // modifier for functions only the team can call
    modifier onlyTeam() {
        require(hasRole(TEAM_ROLE,  msg.sender) || msg.sender == owner(), "Caller not in Team");
        _;
    }

    // modifier for limiting what addresses can whitelist packs and nfts
    modifier onlyWl() {
        require(hasRole(TEAM_ROLE,  msg.sender) || hasRole(WHITELIST_ROLE,  msg.sender) || msg.sender == owner(), "Caller not in Wl address");
        _;
    }

    function redeemNft(uint256 _nftId) public payable nonReentrant {

        require(storeActive && nfts[_nftId].isActive && nfts[_nftId].id != 0, "Nft not found");
        // require(, "Nft Inactive");
        require(purchaseCoolDown == 0 || block.timestamp >= lastPurchase[msg.sender] + purchaseCoolDown, "Purchase Cooldown Active");

        uint256 burnCost = (nfts[_nftId].burnCost * tokenPriceMod)/1 ether;
        uint256 stableCost = (nfts[_nftId].stableCost * stablePriceMod)/1 ether;
        uint256 nativeCost = (nfts[_nftId].nativePrice * nativePriceMod)/1 ether;

      /*  uint256 userLevel;
        if(address(gameCoordinator) != address(0)) {
            userLevel = gameCoordinator.getLevel(msg.sender);
        }*/

        require(( nfts[_nftId].maxRedeem == 0 || nfts[_nftId].totalRedeemed < nfts[_nftId].maxRedeem) && ( nfts[_nftId].maxPerAddress == 0 || userTotalByNft[msg.sender][_nftId] < nfts[_nftId].maxPerAddress), "Max nfts Redeemed");

        require(cardVoucher[_nftId][msg.sender] || msg.value >=  nfts[_nftId].nativePrice, "Not enough Native Token to redeem for card");
        require(cardVoucher[_nftId][msg.sender] || primaryToken.balanceOf(msg.sender) >=  burnCost, "Not enough primary tokens to burn to redeem card");
        require(cardVoucher[_nftId][msg.sender] || stable.balanceOf(msg.sender) >=  stableCost, "Not enough stable tokens to redeem card");
        require(cardVoucher[_nftId][msg.sender] || nfts[_nftId].pointsCost == 0 || squadsContract.getPrizePoints(msg.sender) >= nfts[_nftId].pointsCost, "Not enough points to redeem card");
        require(cardVoucher[_nftId][msg.sender] || nfts[_nftId].extraPrice == 0 || nfts[_nftId].extraToken.balanceOf(msg.sender) >=  nfts[_nftId].extraPrice, "Not enough secondary token to spend for card");

        require(nft.balanceOf(address(this),_nftId) > 0 || nft.totalSupply(_nftId) < nft.maxSupply(_nftId), "Out of Stock"); 


         // if we are taking Native Token transfer it
        if(!cardVoucher[_nftId][msg.sender] && nfts[_nftId].nativePrice > 0){
            totalPurchasedAmount += nativeCost;

            //20% of the remaining to dev
            uint256 toDev = nativeCost/5;
            devWallet.transfer(toDev);

            // the rest to the operations wallet
            operationsWallet.transfer(nativeCost - toDev);
        }

        // if we are taking stable Token transfer to the squadsContract
        if(!cardVoucher[_nftId][msg.sender] && nfts[_nftId].stableCost > 0){
            totalStableAmount +=  stableCost;

            stable.safeTransferFrom(msg.sender, address(this), stableCost);
          
            uint256 totalRemain = stableCost;

            if(tvlPercent > 0){
                // send 25% to the squadsContract
                uint256 toTvl = (stableCost * tvlPercent) / 100;
                totalRemain = stableCost - toTvl;
                stable.safeTransferFrom(address(this), address(squadsContract), toTvl);
            }

                    
            if(lpPercent > 0){
                uint256 toLp = (stableCost * lpPercent) / 100;
                stable.safeTransferFrom(address(this), address(lpAddress), toLp);
                if(lpSync) {
                    IDEXPair(lpAddress).sync();
                }
                totalRemain = totalRemain - toLp;
            }

            if(totalRemain > 0){
                //20% of the remaining to dev
                uint256 toDev = totalRemain/5;
                stable.safeTransferFrom(address(this), address(devWallet), toDev);
                totalRemain = totalRemain - toDev;
            }

            if(totalRemain > 0){
                // the rest to the operations wallet
                stable.safeTransferFrom(address(this), address(operationsWallet), totalRemain);
            }
        }

        // if we are taking a secondary Token transfer it
        if(!cardVoucher[_nftId][msg.sender] && nfts[_nftId].extraPrice > 0){
            totalExtraPurchasedAmount[address(nfts[_nftId].extraToken)] = totalExtraPurchasedAmount[address(nfts[_nftId].extraToken)] + nfts[_nftId].extraPrice;
            
            nfts[_nftId].extraToken.safeTransferFrom(msg.sender, operationsWallet, nfts[_nftId].extraPrice);
        }

        // if we need to burn burn it
        if(!cardVoucher[_nftId][msg.sender] && nfts[_nftId].burnCost > 0){
           
             totalBurnAmount = totalBurnAmount + burnCost;
             primaryToken.safeTransferFrom(msg.sender, burnAddress, burnCost);

        }

         // if we are taking points spend them
        if(!cardVoucher[_nftId][msg.sender] && nfts[_nftId].pointsCost > 0){
            totalPointsAmount += nfts[_nftId].pointsCost;
            squadsContract.spendPoints(msg.sender, nfts[_nftId].pointsCost);
        }

        // stats
        nfts[_nftId].totalRedeemed += 1;
        totalNftsRedeemed += 1;
        userTotalByNft[msg.sender][_nftId] += 1;
        totalUserNfts[msg.sender] += 1;
        lastPurchase[msg.sender] = block.timestamp;

        // remove the voucher if one was used
        if(cardVoucher[_nftId][msg.sender]){
            cardVoucher[_nftId][msg.sender] = false;
        }


        // mint if we need to
        if(nft.balanceOf(address(this),_nftId) == 0){
            nft.mint(address(this), _nftId, 1, "0x0");
        }
          
        // send the NFT
        nft.safeTransferFrom(address(this), msg.sender, _nftId, 1, "0x0");

        emit NftRedeemed(msg.sender, stableCost, nativeCost, burnCost, nfts[_nftId].pointsCost);
    }

    function redeemPack(uint256 _packId) public payable nonReentrant{

        require(packs[_packId].id != 0, "Pack not found");
        require(storeActive && packs[_packId].isActive, "Pack Inactive");
        require(purchaseCoolDown == 0 || block.timestamp >= lastPurchase[msg.sender] + purchaseCoolDown, "Purchase Cooldown Active");
        require(!packs[_packId].useWhitelist || packsWhitelist[_packId][msg.sender], "Not on the Whitelist");

        uint256 burnCost =  (packs[_packId].burnCost * tokenPriceMod) / 1 ether;  
        uint256 stableCost = (packs[_packId].stableCost * stablePriceMod)/1 ether;
        uint256 nativeCost = (packs[_packId].nativePrice * nativePriceMod)/1 ether;
        
        
/*
        uint256 userLevel;
        if(address(gameCoordinator) != address(0)) {
            userLevel = gameCoordinator.getLevel(msg.sender);
        }*/

        require(
            ( packs[_packId].maxRedeem == 0 || packs[_packId].totalRedeemed < packs[_packId].maxRedeem) && 
            ( packs[_packId].maxPerAddress == 0 || userTotalByPack[msg.sender][_packId] < packs[_packId].maxPerAddress), 
        "Max packs Redeemed"
        );

        require(packVoucher[_packId][msg.sender] || msg.value >=  nativeCost, "Not enough Native Token to redeem pack");
        require(packVoucher[_packId][msg.sender] || stable.balanceOf(msg.sender) >=  stableCost, "Not enough stable tokens to redeem pack");
        require(packVoucher[_packId][msg.sender] || primaryToken.balanceOf(msg.sender) >=  burnCost, "Not enough primary tokens to burn for pack");
        require(packVoucher[_packId][msg.sender] || packs[_packId].pointsCost == 0 || squadsContract.getPrizePoints(msg.sender) >= packs[_packId].pointsCost, "Not enough points to redeem card");
        require(packVoucher[_packId][msg.sender] || packs[_packId].extraPrice == 0 || packs[_packId].extraToken.balanceOf(msg.sender) >=  packs[_packId].extraPrice, "Not enough seondairy tokens to spend for pack");

        // if we are taking Native Token transfer it
        if(!packVoucher[_packId][msg.sender] && packs[_packId].nativePrice > 0){
            totalPurchasedAmount +=  nativeCost;
            
           //20% of the remaining to dev
            uint256 toDev = nativeCost/5;
            devWallet.transfer(toDev);

            // the rest to the operations wallet
            operationsWallet.transfer(nativeCost - toDev);

        }

        // if we are taking stable Token transfer, swap and send to the squadsContract
        if(!packVoucher[_packId][msg.sender] && packs[_packId].stableCost > 0){
            totalStableAmount += stableCost;

            stable.safeTransferFrom(msg.sender, address(this), stableCost);

            uint256 totalRemain = stableCost;

            if(tvlPercent > 0){
                // send 25% to the squadsContract
                uint256 toTvl = (stableCost * tvlPercent) / 100;
                totalRemain = stableCost - toTvl;
                stable.safeTransferFrom(address(this), address(squadsContract), toTvl);
            }

            if(lpPercent > 0){
                uint256 toLp = (stableCost * lpPercent) / 100;
                stable.safeTransferFrom(address(this), address(lpAddress), toLp);
                if(lpSync) {
                    IDEXPair(lpAddress).sync();
                }
                totalRemain = totalRemain - toLp;
            }

            if(totalRemain > 0){
                //20% of the remaining to dev
                uint256 toDev = totalRemain/5;
                stable.safeTransferFrom(address(this), address(devWallet), toDev);
                totalRemain = totalRemain - toDev;
            }

            if(totalRemain > 0){
                // the rest to the operations wallet
                stable.safeTransferFrom(address(this), address(operationsWallet), totalRemain);
            }
        }

        // if we are taking a secondary Token transfer it
        if(!packVoucher[_packId][msg.sender] && packs[_packId].extraPrice > 0){
            totalExtraPurchasedAmount[address(packs[_packId].extraToken)] += packs[_packId].extraPrice;
            packs[_packId].extraToken.safeTransferFrom(msg.sender, operationsWallet, packs[_packId].extraPrice);

        }

        // if we need to burn burn it
        if(!packVoucher[_packId][msg.sender] && packs[_packId].burnCost > 0){
             totalBurnAmount += burnCost;
             primaryToken.safeTransferFrom(msg.sender, burnAddress, burnCost);
        }

        // if we are taking points spend them
        if(!packVoucher[_packId][msg.sender] && packs[_packId].pointsCost > 0){
            totalPointsAmount += packs[_packId].pointsCost;
            squadsContract.spendPoints(msg.sender, packs[_packId].pointsCost);
        }
        
        // stats
        packs[_packId].totalRedeemed += 1;
        totalPacksRedeemed += 1;
        userTotalByPack[msg.sender][_packId] += 1;
        totalUserPacks[msg.sender] += 1;
        lastPurchase[msg.sender] = block.timestamp;

        // remove the voucher if one was used
        if(packVoucher[_packId][msg.sender]){
            packVoucher[_packId][msg.sender] = false;
        }

        //send them the pack
         nftPacks.open(
          _packId,
          msg.sender,
          1
        );

        emit PackRedeemed(msg.sender, stableCost, nativeCost, burnCost, packs[_packId].pointsCost);
    }


    function setPurchaseCoolDown(uint256 _purchaseCoolDown) public onlyTeam {
        purchaseCoolDown = _purchaseCoolDown;
    }

    /**
     * @dev Add or update a card
     */
    function setNft(
        uint256 _nftId, 
        uint256 _amountNative, 
        uint256 _amountBurn, 
        uint256 _amountPoints,
        uint256 _amountStable, 
        IERC20 _extraToken,
        uint256 _extraPrice,
        uint256 _maxRedeem, 
        uint256 _maxPerAddress) public onlyOwner {
        nfts[_nftId].id = _nftId;
        nfts[_nftId].nativePrice = _amountNative;
        nfts[_nftId].burnCost = _amountBurn;
        nfts[_nftId].stableCost = _amountStable;
        nfts[_nftId].pointsCost = _amountPoints;
        nfts[_nftId].extraToken = _extraToken;
        nfts[_nftId].extraPrice = _extraPrice;
        nfts[_nftId].maxRedeem = _maxRedeem;
        nfts[_nftId].isActive = true;
        nfts[_nftId].maxPerAddress = _maxPerAddress;

        if(address(_extraToken) != address(0)){
            _extraToken.approve(address(this), type(uint256).max);
        }

        emit NftSet(_nftId, _amountNative, _amountBurn, _amountStable, _maxRedeem);
    }

    /**
     * @dev Add or update a pack
     */
    function setPack(
        uint256 _packId, 
        uint256 _amountNative, 
        uint256 _amountBurn,
        uint256 _amountStable, 
        uint256 _amountPoints, 
        IERC20 _extraToken,
        uint256 _extraPrice,
        uint256 _maxRedeem, 
        uint256 _maxPerAddress, 
        bool _useWhitelist

    ) public onlyTeam {
        packs[_packId].id = _packId;
        packs[_packId].nativePrice = _amountNative;
        packs[_packId].burnCost = _amountBurn;
        packs[_packId].stableCost = _amountStable;
        packs[_packId].pointsCost = _amountPoints;
        packs[_packId].extraToken = _extraToken;
        packs[_packId].extraPrice = _extraPrice;
        packs[_packId].maxRedeem = _maxRedeem;
        packs[_packId].isActive = true;
        packs[_packId].maxPerAddress = _maxPerAddress;
        packs[_packId].useWhitelist = _useWhitelist;

        if(address(_extraToken) != address(0)){
            _extraToken.approve(address(this), type(uint256).max);
        }

        emit PackSet(_packId, _amountNative, _amountBurn, _amountStable, _maxRedeem);
    }

    function setNftActive(uint256 _nftId, bool _isActive) public onlyTeam {
        nfts[_nftId].isActive = _isActive;
    }

    function setPackActive(uint256 _packId, bool _isActive) public onlyTeam {
        packs[_packId].isActive = _isActive;
    }


    function bulkAddNftWhitelist(uint256 _nftId, address[] calldata _wlAddresses) public onlyWl {
        for (uint256 i = 0; i < _wlAddresses.length; ++i) {
            _addNftWhitelist(_nftId, _wlAddresses[i]);
        }
    }

    function bulkRemoveNftWhitelist(uint256 _nftId, address[] calldata _wlAddresses) public onlyWl {
        for (uint256 i = 0; i < _wlAddresses.length; ++i) {
            _removeNftWhitelist(_nftId, _wlAddresses[i]);
        }
    }

    function addNftWhitelist(uint256 _nftId, address _user) public onlyWl {
        _addNftWhitelist(_nftId, _user);
    }

    function removeNftWhitelist(uint256 _nftId, address _user) public onlyWl {
        _removeNftWhitelist(_nftId, _user);
    }

    function isWhitelistedNft(uint256 _nftId, address _user) public view returns(bool) {
        return nftsWhitelist[_nftId][_user];
    }

    function _addNftWhitelist(uint256 _nftId, address _user) private {
        nftsWhitelist[_nftId][_user] = true;
    }

    function _removeNftWhitelist(uint256 _nftId, address _user) private {
        nftsWhitelist[_nftId][_user] = false;
    }


    function bulkAddPackWhitelist(uint256 _packId, address[] calldata _wlAddresses) public onlyWl {
        for (uint256 i = 0; i < _wlAddresses.length; ++i) {
            _addPackWhitelist(_packId, _wlAddresses[i]);
        }
    }

    function bulkRemovePackWhitelist(uint256 _packId, address[] calldata _wlAddresses) public onlyWl {
        for (uint256 i = 0; i < _wlAddresses.length; ++i) {
            _removePackWhitelist(_packId, _wlAddresses[i]);
        }
    }

    function addPackWhitelist(uint256 _packId, address _user)  public onlyWl {
        _addPackWhitelist(_packId, _user);
    }

    function removePackWhitelist(uint256 _packId, address _user) public onlyWl {
        _removePackWhitelist(_packId, _user);
    }

    function isWhitelisted(uint256 _packId, address _user) public view returns(bool) {
        return packsWhitelist[_packId][_user];
    }

    function _addPackWhitelist(uint256 _packId, address _user) private {
        packsWhitelist[_packId][_user] = true;
    }

    function _removePackWhitelist(uint256 _packId, address _user) private {
        packsWhitelist[_packId][_user] = false;
    }


    function hasNftVoucher(uint256 _nftId, address _user) public view returns(bool) {
        return cardVoucher[_nftId][_user];
    }

    function hasPackVoucher(uint256 _packId, address _user) public view returns(bool) {
        return packVoucher[_packId][_user];
    }


    function setNftVoucher(uint256 _nftId, address _user, bool _hasVoucher)  public onlyWl {
        cardVoucher[_nftId][_user] = _hasVoucher;
        emit NftVoucherSet(_user, msg.sender, _nftId, _hasVoucher);
    }


    function setPackVoucher(uint256 _packId, address _user, bool _hasVoucher)  public onlyWl {
        packVoucher[_packId][_user] = _hasVoucher;
        emit PackVoucherSet(_user, msg.sender, _packId, _hasVoucher);
    }

     /**
     * @dev Update the main token address only callable by the owner
     */
    function setPrimaryTokenContract(IERC20 _primaryToken) public onlyOwner {
        primaryToken = _primaryToken;
       // emit SetMnopTokenContract(msg.sender, _primaryToken);
    }

    /**
     * @dev Update the card pack NFT contract address only callable by the owner
     */
    function setSquadsContract(Squads _squadsContract) public onlyOwner {
        squadsContract = _squadsContract;
        emit SetSquadsContract(msg.sender, _squadsContract);
    }


    /**
     * @dev Update the card NFT contract address only callable by the owner
     */
   function setNftContract(ERC1155Tradable _nftAddress) public onlyOwner {
        nft = _nftAddress;
        // emit SetNftContract(msg.sender, _nftAddress);
    }

    /**
     * @dev Update operations wallet
     */
    function setOperationsWallet(address payable _operationsWallet) public onlyOwner {
        require(_operationsWallet != address(0), 'bad address');
        operationsWallet = _operationsWallet;
        emit SetOperationsWallet(msg.sender, _operationsWallet);
    }

    /**
     * @dev Update the dev wallet
     */
    function setDevWallet(address payable _devWallet) public onlyOwner {
        require(_devWallet != address(0), 'bad address');
        devWallet = _devWallet;
        emit SetDevWallet(msg.sender, _devWallet);
    }

    /**
     * @dev Update the LP address
     */
    function setLpAddress(address payable _lpAddress, bool _lpSync) public onlyOwner {
        require(_lpAddress != address(0), 'bad address');
        lpAddress = _lpAddress;
        lpSync = _lpSync;
        emit SetLpAddress(msg.sender, _lpAddress, _lpSync);
    }

    /**
     * @dev Update the token price mod to scale all token prices
     */
    function setTokenPriceMod(uint256 _tokenPriceMod) public onlyTeam {
        tokenPriceMod = _tokenPriceMod;
    }

     /**
     * @dev Update the stable price mod to scale all stable prices
     */
    function setStablePriceMod(uint256 _stablePriceMod) public onlyTeam {
        stablePriceMod = _stablePriceMod;
    }

    /**
     * @dev Update the token price mod to scale all native prices
     */
    function setNativePriceMod(uint256 _nativePriceMod) public onlyTeam {
        nativePriceMod = _nativePriceMod;
    }

    /**
     * @dev Global flag to enable/disable the store
     */
    function setStoreActive(bool _storeActive) public onlyTeam {
        storeActive = _storeActive;
    }


    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure override returns(bytes4) {
      return 0xf23a6e61;
    }


    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external pure override returns(bytes4) {
      return 0xbc197c81;
    }

    function supportsInterface(bytes4 interfaceID) public view virtual override(IERC165,AccessControlEnumerable) returns (bool) {
      return  interfaceID == 0x01ffc9a7 ||    // ERC-165 support (i.e. `bytes4(keccak256('supportsInterface(bytes4)'))`).
      interfaceID == 0x4e2312e0;      // ERC-1155 `ERC1155TokenReceiver` support (i.e. `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) ^ bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
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
// OpenZeppelin Contracts v4.4.1 (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
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
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11; 

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import '@openzeppelin/contracts/utils/Strings.sol';
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

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

    string private _contractURI;
    string private _uriSuffix;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");


    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri

    ) ERC1155(_uri) {
        name = _name;
        symbol = _symbol;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);

    }

    function uri(uint256 _id) public override view returns (string memory) {
        require(_exists(_id), "erc721tradable#uri: NONEXISTENT_TOKEN");
        string memory _uri = super.uri(_id);
        return Concat.strConcat(_uri, Strings.toString(_id), _uriSuffix);
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

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
    
    function setContractURI(string memory _uri) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        _contractURI = _uri;
    }

    function setBaseURI(string memory _uri) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        _setURI(_uri);
    }

    function setURISuffix(string memory uriSuffix_) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        _uriSuffix = uriSuffix_;
    }

    function create(
        uint256 _maxSupply,
        uint256 _initialSupply,
        string calldata _uri,
        bytes calldata _data
    ) public returns (uint256 tokenId) {
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
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    ) public {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        
        uint256 newSupply = tokenSupply[_id].add(_quantity);
        require(newSupply <= tokenMaxSupply[_id], "max NFT supply reached");
         _mint(_to, _id, _quantity, _data);
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

        //_burnAndReduce(_address,_id,_amount);
         _burn(_address, _id, _amount);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual override {
        super._burn(from,id,amount);
        // reduce max supply
        tokenMaxSupply[id] = tokenMaxSupply[id] - amount;
    }
    

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings - The Beano of NFTs
     */
    function isApprovedForAll(address _owner, address _operator) public override view returns (bool isOperator) {

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

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

import "./SquadNfts.sol";

contract Squads is Ownable, IERC1155Receiver, ReentrancyGuard, VRFConsumerBaseV2  {
    using SafeERC20 for IERC20;

    struct SquadStats {
        int256 overall; // avg ovr stat
        int256 offense; // offense power
        int256 defense; // defense power
        int256 won; // how many wins
        int256 lost; // how many loses
        int256 tied; // how many ties
        uint256 prizePoints; // total points won
        uint256 prizePointsSpent; // total points spent 
        uint256 totalPaidOut; // total winnings
        bool isPlaying;
        // (prizePoints-prizePointsSpent = current point balance)
    }

    struct GameResult {
        uint256 gameId; 
        address player; // player address
        bool win; // if they won (tie is a loss)
        uint256 scoreFor; // how many goals they scored
        uint256 scoreAgainst; // how many goals against 
        uint256 prizePoints; // how many points they collected if they won
        uint256 paidOut; // how much they got for the win
        uint256 gameDate; // timestamp of this result
        uint256 opponentId; // opponent faced
        int256 offense;
        int256 defense;
        
    }

    struct Opponent {
        int256 overall; // avg ovr stat
        int256 offense; // offense power
        int256 defense; // defense power
        int256 won; // how many wins for this opponent
        int256 lost; // how many loses for this opponent
        int256 tied; // how many ties
        int256 reqOvr; // required overall rating to play this opponent
        int256 reqWins; // required amount of wins to play this opponent
        uint256 tokenFeePercent; // percent of the current supply to burn 
        uint256 entryFeePercent; // percent of the win to charge in entry fees
        uint256 prizePoints; // how many prize points they win from this opponent
        uint256 winPercent; // percent of total TVL this win gives out
        uint256 paidOut; // (wei) total winnings paid from this opponent
        uint256 lockDuration; // how long the squad is locked after this game
    }

    struct VrfQueue {
        address player; // player address
        uint256 opponentId; // opponent
        
        
    }

    // Chainlink VRF
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 subscriptionId;
    bytes32 internal keyHash;
    address internal vrfCoordinator;
    uint32 internal callbackGasLimit = 2500000;
    uint16 requestConfirmations = 3;
    mapping(uint256 => VrfQueue) private vrfQueue;
    
    // Dev address
    address payable public devAddress;

    // Ops address
    address payable public operationsAddress;

    // PvP address
    address public pvpAddress;

    // The burn address
    address public constant burnAddress = address(0xdead);   
    
    IERC20 public tokenContract;
    IERC20 public stableContract;
    SquadNfts public nftContract;

    // global flag to turn on/off all games
    bool public isActive;

    // hard coded max squad fee of 0.5% tokens
    uint256 public constant maxSquadFee = 500000;

    // 0.0002% of SQUAD supply
    uint256 public squadFee = 2;
    uint256 public squadBoostFee = 2;

    // max entry tax 25%
    uint256 public constant maxEntryTax = 250000;

    // max pvp tax 5%
    uint256 public constant maxPvpTax = 50000;

    // 10% tax
    uint256 public entryTax = 100000; 

    // 1% pvp tax = 10000
    uint256 public pvpTax; 

    // default number to base targeting off (1-100)
    int256 public defaultStartingTarget = 80;

    // amount to reduce the target each full round
    int256 public gameTargetReduce = 20;

    // 0 - use the defense rating as starting target
    // 1 - use the default target as the starting target 
    uint256 public gameTargetMode = 1;

    // 0 - rolls are capped at offensive power
    // 1 - rolls are capped at 100
    uint256 public gameRollCap = 1;

    uint256 public totalPayouts;
    
    // mapping of contracts allowed to spend points
    mapping(address => bool) public canSpend;

    // Opponent mappings
    mapping(uint256 => Opponent) public opponents;

    // users squad nft mappings
    // mapping(address => uint256[]) public squads;
    mapping(address => mapping(uint256 => uint256)) public squads;
    mapping(address => uint256) public squadBoosts;

    // squad stats
    mapping(address => SquadStats) public squadStats;

    mapping(address => bool) public squadSet;
    mapping(address => uint256) public squadSetTime;

    // timstamp of when squad unlocks
    mapping(address => uint256) public squadLocked;

    // timestamp of each user -> opponent unlocks
    mapping(address => mapping(uint256 => uint256)) public opponentsLock;

    // last game ID for each user
    // unset this when a game starts
    // sets this when the game ends
    mapping(address => uint256) public lastGame;

    // log of all games
    mapping(uint256 => GameResult) public gameResults;
    mapping(address => mapping(uint256 => uint256)) public userResults;
    mapping(address => uint256) public userTotalGames;

    uint256 public totalGames;

    constructor(
       
        address payable _devAddress, 
        address payable _operationsAddress,
        address payable _pvpAddress,
        IERC20 _tokenContract,
        IERC20 _stableContract,
        SquadNfts _nftContract,
        address _vrfCoordinator,
        bytes32 _vrfKeyHash, 
        uint64 _subscriptionId
    ) VRFConsumerBaseV2 (
        _vrfCoordinator
    )  {
        require(_devAddress != address(0) && _operationsAddress != address(0), 'invalid address');

        devAddress = _devAddress;
        operationsAddress = _operationsAddress;
        pvpAddress = _pvpAddress;
        
        setTokenContract(_tokenContract);
        setStableContract(_stableContract);
        // tokenContract = _tokenContract;
        // stableContract = _stableContract;
        nftContract = _nftContract;

        // set up chainlink
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        subscriptionId = _subscriptionId;
        vrfCoordinator = _vrfCoordinator;
        keyHash = _vrfKeyHash;

        canSpend[address(this)] = true;
        
    }

    /** 
    * @notice Modifier to only allow updates by the VRFCoordinator contract
    */
    modifier onlyVRFCoordinator {
        require(msg.sender == vrfCoordinator, 'VRF Only');
        _;
    }

    function setSquad(uint256[] memory _squad) public nonReentrant {

        // require(squadSet[msg.sender] == false, 'Squad already set');
        require(isActive, 'Squads not active');
        require(_squad.length == 11, 'Invalid Squad');
        require(block.timestamp >= squadLocked[msg.sender], 'Squad Locked');

        if(squadSet[msg.sender] == true){
            _unsetSquad();
        }

        // take a fee
        if(squadFee > 0){
            uint256 feeAmount = _calcPercent(tokenContract.totalSupply(),squadFee);
            require(tokenContract.balanceOf(msg.sender) >= feeAmount, 'low balance');
            tokenContract.safeTransferFrom(msg.sender, burnAddress, feeAmount);
        }

        // verify the positions are ok and average the stats
        int256 offTotal;
        int256 offDiv;

        int256 defTotal;
        int256 defDiv;

        
        //uint256[11] memory amounts;
        uint256[] memory amounts = new uint256[](11);
        uint256[] memory usedIds = new uint256[](11);
        for (uint256 i = 0; i < _squad.length; ++i) {
            uint256 _id = _squad[i];
            amounts[i] = 1;

            require(!_isInArray(_id,usedIds), 'duplicate player');
            
            int256[4] memory _attr = nftContract.getAttributes(_id);

            require(_id > 0 && _attr[0] > 0, 'not a valid player');

            // goalie
            if(i == 0){
                require(_attr[0] == 1, 'not a goalie');
                
                defTotal += (int256(_attr[2]) * 4);
                defDiv += 4;
            }

            // defenders
            if(i>0 && i<=4){
                require(_attr[0] == 2 || _attr[0] == 3, 'not a defender');   
                
                defTotal += (int256(_attr[2]) * 3);
                defDiv += 3;

                offTotal += int256(_attr[1]);
                offDiv += 1;
            }

            // midfielders
            if(i>4 && i<=7){
                require(_attr[0] == 3, 'not a midfielder');

                defTotal += (int256(_attr[2]) * 2);
                defDiv += 2;

                offTotal += (int256(_attr[1]) * 2);
                offDiv += 2;
            }

            // attackers
            if(i>7 && i<=10){
                require(_attr[0] == 3 || _attr[0] == 4, 'not an attacker');

                if(i<10){
                    defTotal += int256(_attr[2]);
                    defDiv += 1;

                    offTotal += (int256(_attr[1]) * 3);
                    offDiv += 3;
                } else {
                    offTotal += (int256(_attr[1]) * 4);
                    offDiv += 4;
                }
            }

            usedIds[i] = _id;
            squads[msg.sender][i] = _id;
            
        }

        int256 avgOff = offTotal/offDiv;
        int256 avgDef = defTotal/defDiv;

        squadStats[msg.sender].overall = (avgOff + avgDef) /2;
        squadStats[msg.sender].offense = avgOff;
        squadStats[msg.sender].defense = avgDef;

        squadSet[msg.sender] = true;
        squadSetTime[msg.sender] = block.timestamp;

        // transfer NFTS
        nftContract.safeBatchTransferFrom(msg.sender, address(this), _squad, amounts, "");

    }

    function _unsetSquad() internal {
        uint256[] memory amounts = new uint256[](11);
        uint256[] memory nftIds = new uint256[](11);
        // uint256[] memory amounts;
        for (uint256 i = 0; i < 11; ++i) {
            nftIds[i] = squads[msg.sender][i];
            amounts[i] = 1;
            squads[msg.sender][i] = 0;
        }

        // send back the NFTS
        nftContract.safeBatchTransferFrom( address(this), msg.sender, nftIds, amounts, "");

        // reset the squad
        delete squadLocked[msg.sender];

        squadStats[msg.sender].overall=0;
        squadStats[msg.sender].offense=0;
        squadStats[msg.sender].defense=0;

        squadSet[msg.sender] = false;
    }

    function unsetSquad() public nonReentrant {
        require(squadSet[msg.sender] == true, 'Squad not set');
        require(block.timestamp >= squadLocked[msg.sender], 'Squad Locked');

        _unsetSquad();
    }

    function setSquadBoost(uint256 _nftId) external nonReentrant{

        require(isActive, 'Squads not active');
        require(nftContract.balanceOf(msg.sender,_nftId) > 0, 'no balance');
        int256[4] memory _attr = nftContract.getAttributes(_nftId);

        require(_attr[0] == 0 && (_attr[1] > 0 || _attr[2] > 0), "Not a valid boost");

        // take a fee
        if(squadBoostFee > 0){
            uint256 feeAmount = _calcPercent(tokenContract.totalSupply(),squadBoostFee);
            require(tokenContract.balanceOf(msg.sender) >= feeAmount, 'low balance');
            tokenContract.safeTransferFrom(msg.sender, burnAddress, feeAmount);
        }

        if(squadBoosts[msg.sender] > 0 ){
            _unsetSquadBoost();
        }

        squadBoosts[msg.sender] = _nftId;
        squadSetTime[msg.sender] = block.timestamp;
        // transfer the nft to the contract
        nftContract.safeTransferFrom(msg.sender, address(this), _nftId, 1, "");
    }

    function unsetSquadBoost() public nonReentrant {
        _unsetSquadBoost();
    }

    function _unsetSquadBoost() internal {
        require(squadBoosts[msg.sender] > 0, "No boost set");

        uint256 nftId = squadBoosts[msg.sender];
        squadBoosts[msg.sender] = 0;

        // transfer from the contract back to the owner
        nftContract.safeTransferFrom(address(this), msg.sender, nftId, 1, "");
    }

    function reduceTime(uint256 _id, uint256 _opponentId) external nonReentrant {
        require(isActive, 'Squads not active');
        require(nftContract.balanceOf(msg.sender,_id) > 0, 'no balance');
        require(squadLocked[msg.sender] > block.timestamp || opponentsLock[msg.sender][_opponentId] > block.timestamp,'Not locked');
        require(!squadStats[msg.sender].isPlaying, 'Game in progress');

        int256[4] memory _attr = nftContract.getAttributes(_id);

        require(_attr[0] == 5 && _attr[3] > 0, 'invalid nft type');

        nftContract.burn(msg.sender,_id,1);

        uint256 newTime  = squadLocked[msg.sender] - uint256(_attr[3]);


        // unlock the squad
        squadLocked[msg.sender] = newTime > block.timestamp ? newTime : block.timestamp;

        // unlock an opponent

        if(_opponentId > 0){
            newTime  = opponentsLock[msg.sender][_opponentId] - uint256(_attr[3]);
            opponentsLock[msg.sender][_opponentId] = newTime > block.timestamp ? newTime : block.timestamp;
        }

    }

    function play(uint256 _opponentId) public nonReentrant returns (uint256)  {
        require(isActive, 'Squads not active');
        require(squadSet[msg.sender] == true, 'Squad not set');
        require(block.timestamp >= squadLocked[msg.sender], 'Squad Locked');
        require(block.timestamp >= opponentsLock[msg.sender][_opponentId], 'Opponent Locked');
        require(opponents[_opponentId].overall > 0, 'Not a valid Opponent');

        // squad boost
        int256 ovr = squadStats[msg.sender].overall;
        if(squadBoosts[msg.sender] > 0){
            int256[4] memory _boostAttr = nftContract.getAttributes(squadBoosts[msg.sender]);
            ovr = (squadStats[msg.sender].offense + _boostAttr[1] + squadStats[msg.sender].defense + _boostAttr[2]) /2;
        }

        require(ovr >= opponents[_opponentId].reqOvr, 'Ovr too low');
        require(squadStats[msg.sender].won >= opponents[_opponentId].reqWins, 'Wins too low');

        // burn the token fee
        if(opponents[_opponentId].tokenFeePercent > 0){
            uint256 tokenFee = _calcPercent(tokenContract.totalSupply(),opponents[_opponentId].tokenFeePercent);
            require(tokenContract.balanceOf(msg.sender) >= tokenFee, 'low balance');
            tokenContract.safeTransferFrom(msg.sender, burnAddress, tokenFee);
        }

        // take the stable fee
        if(opponents[_opponentId].entryFeePercent > 0){
            // how much is a win at time of roll
            uint256 winnings = _calcPercent(getBalance(),opponents[_opponentId].winPercent);

            uint256 entryFee = _calcPercent(winnings,opponents[_opponentId].entryFeePercent);
            // entryFeePercent
            require(stableContract.balanceOf(msg.sender) >= entryFee, 'low balance');

            // take the pvp tax if active
            if(pvpTax > 0 && pvpAddress != address(0)){
                uint256 _pvpTaxAmount = _calcPercent(entryFee,pvpTax);
                stableContract.safeTransferFrom(address(this), pvpAddress, _pvpTaxAmount);
            }

            // tax the entry fee
            uint256 _taxAmount = _calcPercent(entryFee,entryTax);
            stableContract.safeTransferFrom(msg.sender, address(this), entryFee);

            // dev share
            uint256 _devFee = _taxAmount/5;
            stableContract.safeTransferFrom(address(this), devAddress, _devFee);

            // operations
            stableContract.safeTransferFrom(address(this), operationsAddress, _taxAmount - _devFee);
        }

        // lock the opponent and squad 
        opponentsLock[msg.sender][_opponentId] = block.timestamp + opponents[_opponentId].lockDuration;

        // squad is locked 1/5 of the duration
        squadLocked[msg.sender] = block.timestamp + (opponents[_opponentId].lockDuration/5);

        uint256 _requestId = COORDINATOR.requestRandomWords(
          keyHash,
          subscriptionId,
          requestConfirmations,
          callbackGasLimit,
          6
        );

        vrfQueue[_requestId] = VrfQueue({
            player: msg.sender,
            opponentId: _opponentId
        }); 
        lastGame[msg.sender] = 0;
        squadStats[msg.sender].isPlaying = true;
        return _requestId;
    }

   // event VrfReturn(address player, uint256[6] rolls);

    /**
     * @notice Callback function used by VRF Coordinator
     * @dev Important! Add a modifier to only allow this function to be called by the VRFCoordinator
     * @dev The VRF Coordinator will only send this function verified responses.
     * @dev The VRF Coordinator will not pass randomness that could not be verified.
     * @dev Get a number between 2 and 12, and run the roll logic
     */
      function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
      ) internal override {

       /* uint256[6] memory _turns = [
            randomWords[0]%100 + 1,
            randomWords[1]%100 + 1,
            randomWords[2]%100 + 1,
            randomWords[3]%100 + 1,
            randomWords[4]%100 + 1,
            randomWords[5]%100 + 1
        ];*/

        address _player = vrfQueue[requestId].player;
        uint256 _opponentId = vrfQueue[requestId].opponentId;

        uint256[6] memory _turns;

        if(gameRollCap == 1){
            _turns = [
                randomWords[0]%100 + 1,
                randomWords[1]%100 + 1,
                randomWords[2]%100 + 1,
                randomWords[3]%100 + 1,
                randomWords[4]%100 + 1,
                randomWords[5]%100 + 1
            ];
        } else {    
            // max roll is the squad's offense power
            _turns  = [
                (randomWords[0]%100 + 1) > uint256(squadStats[_player].offense) ? uint256(squadStats[_player].offense) : (randomWords[0]%100 + 1),
                 (randomWords[1]%100 + 1) > uint256(opponents[_opponentId].offense) ? uint256(opponents[_opponentId].offense) : (randomWords[1]%100 + 1),
                 (randomWords[2]%100 + 1) > uint256(squadStats[_player].offense) ? uint256(squadStats[_player].offense) : (randomWords[2]%100 + 1),
                 (randomWords[3]%100 + 1) > uint256(opponents[_opponentId].offense) ? uint256(opponents[_opponentId].offense) : (randomWords[3]%100 + 1),
                 (randomWords[4]%100 + 1) > uint256(squadStats[_player].offense) ? uint256(squadStats[_player].offense) : (randomWords[4]%100 + 1),
                 (randomWords[5]%100 + 1) > uint256(opponents[_opponentId].offense) ? uint256(opponents[_opponentId].offense) : (randomWords[5]%100 + 1)
            ];
        }

       // emit VrfReturn(_player,_turns);
       _playGame(_turns, _player, _opponentId);

      }
  
      event GameComplete(address player, uint256 opponent, uint256[6] rolls, bool win, uint256 scoreFor, uint256 scoreAgainst, uint256 points, uint256 winnings);
   // event GameRound( uint256 roll, int256 target, int256 startingTarget, int256 off, int256 def, bool scored);
    function _playGame(uint256[6] memory _turns, address _player, uint256 _opponentId) private {
        uint256 scoreFor;
        uint256 scoreAgainst;
        int256 startingTarget = defaultStartingTarget;
        int256 playerOffense = squadStats[_player].offense;
        int256 playerDefense = squadStats[_player].defense;


        // squad boost
        if(squadBoosts[_player] > 0){
            int256[4] memory _boostAttr = nftContract.getAttributes(squadBoosts[_player]);
            playerOffense = playerOffense + _boostAttr[1];
            playerDefense = playerDefense + _boostAttr[2];
        }

        for (uint256 i = 0; i < _turns.length; ++i) {
            int256 delta;    
            int256 target;
            bool scored;
            if(i%2 == 0){
                // you on offense
                delta = opponents[_opponentId].defense - playerOffense;
                if(gameTargetMode == 1){
                    target = startingTarget + delta;
                } else {
                    target = (opponents[_opponentId].defense - (gameTargetReduce*int(i))) + delta;
                }
                if(_turns[i] >= uint256(target)){
                    scoreFor += 1;
                    scored = true;
                }
             //   emit GameRound(_turns[i],target,startingTarget,squadStats[_player].offense, opponents[_opponentId].defense,scored);
            } else {
                // you on deffense
                delta = playerDefense - opponents[_opponentId].offense;
                if(gameTargetMode == 1){
                    target = startingTarget + delta;
                } else {
                    target = (playerDefense - (gameTargetReduce*int(i))) + delta;
                }
                if(_turns[i] >=  uint256(target)){
                    scoreAgainst += 1;
                    scored = true;
                }

                // reduce the target for next pass
                startingTarget -= gameTargetReduce;
                // emit GameRound(_turns[i],target,startingTarget,opponents[_opponentId].offense,squadStats[_player].defense,scored);
            }        
             
        }

        bool win;
        uint256 winnings;
        uint256 prizePointsWon;
        if(scoreFor > scoreAgainst){
            // we won
            win = true;
            squadStats[_player].won += 1;
            opponents[_opponentId].lost += 1;
            
            // award the points
            squadStats[_player].prizePoints += opponents[_opponentId].prizePoints;
            prizePointsWon = opponents[_opponentId].prizePoints;
            // send any winnings 
            if(opponents[_opponentId].winPercent > 0){
                winnings = _calcPercent(getBalance(),opponents[_opponentId].winPercent);
                if(winnings > 0){
                    stableContract.safeTransferFrom(address(this), _player, winnings);
                    squadStats[_player].totalPaidOut += winnings;
                    
                    opponents[_opponentId].paidOut += winnings;
                    totalPayouts += winnings;
                }
                
            }

        } else {
            
            if(scoreFor == scoreAgainst){
                // we tied
                squadStats[_player].tied += 1;
                opponents[_opponentId].tied += 1;

                // lock for 3/4 the time
                opponentsLock[_player][_opponentId] = opponentsLock[_player][_opponentId] - (opponents[_opponentId].lockDuration/4);
                squadLocked[_player] = squadLocked[_player] - (opponents[_opponentId].lockDuration/20);
                //squadLocked[_player] = squadLocked[_player] - (opponents[_opponentId].lockDuration/4);

                // give 1/4 the points 
                // award the points
                prizePointsWon = (opponents[_opponentId].prizePoints/4);
                squadStats[_player].prizePoints += prizePointsWon;
            } else {
                // we lost
                squadStats[_player].lost += 1;
                opponents[_opponentId].won += 1;

                // subtract 1/2 the lock time
                opponentsLock[_player][_opponentId] = opponentsLock[_player][_opponentId] - (opponents[_opponentId].lockDuration/2);
                squadLocked[_player] = squadLocked[_player] - (opponents[_opponentId].lockDuration/10);
                
            }

                        

        }


        // log the game
        gameResults[totalGames] = GameResult({
            gameId: totalGames,
            player: _player,
            win: win,
            scoreFor: scoreFor,
            scoreAgainst: scoreAgainst,
            prizePoints: prizePointsWon,
            paidOut: winnings,
            gameDate: block.timestamp,
            opponentId: _opponentId,
            offense: playerOffense,
            defense: playerDefense

        });
        userResults[_player][userTotalGames[_player]] = totalGames;
        lastGame[_player] = totalGames;
        totalGames++;
        userTotalGames[_player]++;

        squadStats[_player].isPlaying = false;
        emit GameComplete(_player, _opponentId, _turns, win, scoreFor, scoreAgainst, prizePointsWon, winnings);
       
      
    }

    event PointsSpent(address player, uint256 amount, address operator);
    function spendPoints(address _player, uint256 _amount) public nonReentrant {
        require(canSpend[msg.sender], 'nope');
        require(_getPrizePoints(_player) >= _amount);
        squadStats[_player].prizePointsSpent += _amount;
        emit PointsSpent(_player, _amount, msg.sender);
    }

    function setOpponent(
        uint256 _opponentId, 
        int256 _offense, 
        int256 _defense, 
        int256 _reqOvr, 
        int256 _reqWins, 
        uint256 _tokenFeePercent,
        uint256 _entryFeePercent,
        uint256 _winPercent,
        uint256 _prizePoints,
        uint256 _lockDuration
    ) public onlyOwner {
        opponents[_opponentId].overall = (_offense + _defense)/2;
        opponents[_opponentId].offense = _offense;
        opponents[_opponentId].defense = _defense;
        opponents[_opponentId].reqOvr = _reqOvr;
        opponents[_opponentId].reqWins = _reqWins;
        opponents[_opponentId].tokenFeePercent = _tokenFeePercent;
        opponents[_opponentId].entryFeePercent = _entryFeePercent;
        opponents[_opponentId].winPercent = _winPercent;
        opponents[_opponentId].prizePoints = _prizePoints;
        opponents[_opponentId].lockDuration = _lockDuration;

    }


    function getSquadStats(address _player) public view returns(int256[3] memory){
        
        int256 playerOffense = squadStats[_player].offense;
        int256 playerDefense = squadStats[_player].defense;
        
        // squad boost
        if(squadBoosts[_player] > 0){
            int256[4] memory _boostAttr = nftContract.getAttributes(squadBoosts[_player]);
            playerOffense = playerOffense + _boostAttr[1];
            playerDefense = playerDefense + _boostAttr[2];
        }
        return [(playerOffense + playerDefense)/2,playerOffense,playerDefense];
    }

    function getGameResult(uint256 _gameId) external view returns (address, bool, uint256, uint256, uint256) {
        return (
            gameResults[_gameId].player,
            gameResults[_gameId].win,
            gameResults[_gameId].scoreFor,
            gameResults[_gameId].scoreAgainst,
            gameResults[_gameId].prizePoints);
    }

    function getBalance() public view returns(uint256) {
        return stableContract.balanceOf(address(this));
    }

    function getPrizePoints(address _player) public view returns(uint256) {
        return _getPrizePoints(_player);
    }

    function _getPrizePoints(address _player) internal view returns(uint256) {
        return squadStats[_player].prizePoints - squadStats[_player].prizePointsSpent;
    }

    function getSquadFee() external view returns(uint256){
        return _calcPercent(tokenContract.totalSupply(),squadFee);
    }

    function getBoostFee() external view returns(uint256){
        return _calcPercent(tokenContract.totalSupply(),squadBoostFee);
    }

    event SetIsActive(bool isActive);
    function setIsActive(bool _isActive) external onlyOwner {
        isActive = _isActive;
        emit SetIsActive(_isActive);
    }

    function setSquadFee(uint256 _squadFee) external onlyOwner {
        require(_squadFee <= maxSquadFee, 'fee too high');
        squadFee = _squadFee;
    }

    function setSquadBoostFee(uint256 _squadBoostFee) external onlyOwner {
        require(_squadBoostFee <= maxSquadFee, 'fee too high');
        squadBoostFee = _squadBoostFee;
    }

    function setEntryTax(uint256 _entryTax) external onlyOwner {
        require(_entryTax <= maxEntryTax, 'tax too high');
        entryTax = _entryTax;
    }

    function setPvpTax(uint256 _pvpTax) external onlyOwner {
        require(_pvpTax <= maxPvpTax, 'tax too high');
        pvpTax = _pvpTax;
    }

    function setStartingTarget(int256 _defaultStartingTarget, int256 _gameTargetReduce, uint256 _gameTargetMode, uint256 _gameRollCap) external onlyOwner {
        defaultStartingTarget = _defaultStartingTarget;
        gameTargetReduce = _gameTargetReduce;
        gameTargetMode = _gameTargetMode;
        gameRollCap = _gameRollCap;
    }


    event SetPvpAddress(address oldAddress, address newAddress);
    function setPvpAddress(address _pvpAddress) external onlyOwner {
        require(_pvpAddress != address(0), 'invalid address');
        emit SetPvpAddress(pvpAddress, _pvpAddress);
        pvpAddress = _pvpAddress;

    }

    function setCanSpend(address _operator, bool _canSpend) external onlyOwner {
        require(_operator != address(0), "=0");
        canSpend[_operator] = _canSpend;
    }

    
    // if vrf gets stuck or fails the owner can reset a player
    function resetIsPlaying(address _player) external onlyOwner {
        squadStats[_player].isPlaying = false;
    }

    function setLinkGas(uint32 _callbackGasLimit) external onlyOwner {
      callbackGasLimit = _callbackGasLimit;
    }

    function setTokenContract(IERC20 _tokenContract) public onlyOwner {
        tokenContract = _tokenContract;
        tokenContract.approve(address(this), type(uint256).max);
    }

    function setStableContract(IERC20 _stableContract) public onlyOwner {
        stableContract = _stableContract;
        stableContract.approve(address(this), type(uint256).max);
    }

    function setNftContract(SquadNfts _nftContract) public onlyOwner {
        nftContract = _nftContract;
    }

    // Calculates percents (1000 = 1%)
    function _calcPercent(uint256 amount, uint256 percent) private pure returns (uint256) {
        return (amount*percent) / 1000000;
    }

    function _isInArray(uint256 _value, uint256[] memory _array) internal pure returns(bool) {
        uint256 length = _array.length;
        for (uint256 i = 0; i < length; ++i) {
            if (_array[i] == _value) {
                return true;
            }
        }
        return false;
    }
    /**
     * @dev If we need to migrate contracts we need a way to get the BNB out of it
     */ 
    function withdrawNative() external onlyOwner{
        operationsAddress.transfer(address(this).balance);
    }

    // pull all the tokens out of the contract, needed for migrations/emergencies 
    function withdrawToken(IERC20 _token) external onlyOwner {
        _token.safeTransferFrom(address(msg.sender), address(this), _token.balanceOf(address(this)));
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
    /**
     * @dev Accept native tokens 
     */ 
    fallback() external  payable { }
    receive() external payable { }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./libs/ERC1155Tradable.sol";

contract SquadNfts is ERC1155Tradable {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct NftAttributes {
        int256 position; // index of player position type
        int256 offense; // offesne power
        int256 defense; // defense power
        int256 other; // lock time reduction/other stats


    }

    EnumerableSet.AddressSet private _systemContracts;

    // mapping of nft ids that are locked and can not be transfered to anything but a system contract
    mapping(uint256 => bool) public accountLocked;

    // attributes used in game play
    mapping(uint256 => NftAttributes) public nftAttributes;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC1155Tradable(_name, _symbol, _uri) {

        require(
            _systemContracts.add(address(0)) &&
            _systemContracts.add(address(this)), "error adding system contract");
    }

    function create(
        uint256 _maxSupply,
        uint256 _initialSupply,
        string calldata _uri,
        bytes calldata _data,
        bool _accountLocked,
        int256[4] calldata _attrs
    ) public returns (uint256 tokenId) {
        uint256 _id =  super.create(_maxSupply, _initialSupply,_uri,_data);
        
        nftAttributes[_id] = NftAttributes({
            position: _attrs[0],
            offense: _attrs[1],
            defense: _attrs[2],
            other: _attrs[3]

        });

        if(_accountLocked){
            accountLocked[_id] = true;
        }
        return _id;
    }

    function setAttributes(uint256 _id, int256[4] calldata _attrs)  external onlyOwner {
        nftAttributes[_id] = NftAttributes({
            position: _attrs[0],
            offense: _attrs[1],
            defense: _attrs[2],
            other: _attrs[3]
        });
    }

    function addSystemContractAddress(address _addr) external onlyOwner {
        require(_systemContracts.add(_addr), 'list error');
    }

    function removeSystemContractAddress(address _addr) external onlyOwner {
        require(_systemContracts.remove(_addr), 'list error');
    }

    function getAttributes(uint256 _id) external view returns (int256[4] memory){
        return [nftAttributes[_id].position,nftAttributes[_id].offense,nftAttributes[_id].defense,nftAttributes[_id].other];
    }


    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override virtual {
        super._beforeTokenTransfer(operator,from,to,ids,amounts,data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            if(to == burnWallet){
                _burn(from,id,amount);
            } else {
                require(!accountLocked[id] || _systemContracts.contains(to) || _systemContracts.contains(from), 'account locked');
            }

            
        }

    }

}

// SPDX-License-Identifier: MIT
/// @author MrD 

pragma solidity >=0.8.11;

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import '@openzeppelin/contracts/utils/Strings.sol';
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./libs/ERC1155Tradable.sol";

/**
 * @title NftPack 
 * NftPack - a randomized and openable lootbox of Nfts
 */

contract NftPacks is Ownable, Pausable, AccessControl, ReentrancyGuard, VRFConsumerBaseV2, IERC1155Receiver {
  using Strings for string;

  ERC1155Tradable public nftContract;

  // amount of items in each grouping/class
  mapping (uint256 => uint256) public Classes;
  bool[] public Option;

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant TEAM_ROLE = keccak256("TEAM_ROLE");

  uint256 constant INVERSE_BASIS_POINT = 10000;
  bool internal allowMint;

  // Chainlink VRF
  VRFCoordinatorV2Interface COORDINATOR;
  uint64 subscriptionId;
  bytes32 internal keyHash;
  address internal vrfCoordinator;
  uint32 internal callbackGasLimit = 2500000;
  uint16 requestConfirmations = 3;
  // uint256[] private _randomWords;
  uint256 private _randomness;
  uint256 private _seed;
  

  event cardPackOpened(uint256 indexed optionId, address indexed buyer, uint256 boxesPurchased, uint256 itemsMinted);
  event Warning(string message, address account);
  event SetLinkFee(address indexed user, uint256 fee);
  event SetNftContract(address indexed user, ERC1155Tradable nftContract);

  struct OptionSettings {
    // which group of classes this belongs to 
    uint256 groupingId;
    // Number of items to send per open.
    // Set to 0 to disable this Option.
    uint32 maxQuantityPerOpen;
    // Probability in basis points (out of 10,000) of receiving each class (descending)
    uint16[] classProbabilities; // NUM_CLASSES
    // Whether to enable `guarantees` below
    bool hasGuaranteedClasses;
    // Number of items you're guaranteed to get, for each class
    uint16[] guarantees; // NUM_CLASSES
  }

  /** 
   * @dev info on the current zck being opened 
   */
  struct PackQueueInfo {
    address userAddress; //user opening the pack
    uint256 optionId; //packId being opened
    uint256 amount; //amount of packs
  }

  uint256 private defaultNftId = 1;

  mapping (uint256 => OptionSettings) public optionToSettings;
  mapping (uint256 => mapping (uint256 => uint256[])) public classToTokenIds;

  // keep track of the times each token is minted, 
  // if internalMaxSupply is > 0 we use the internal data
  // if it is 0 we will use supply of the NFT contract instead
  mapping (uint256 => mapping (uint256 =>  mapping (uint256 => uint256)))  public internalMaxSupply;
  mapping (uint256 => mapping (uint256 =>  mapping (uint256 => uint256))) public internalTokensMinted;
  
  mapping (address => uint256[]) public lastOpen;
  mapping (address => uint256) public isOpening;
  mapping(uint256 => PackQueueInfo) private packQueue;


  constructor(
    ERC1155Tradable _nftAddress,
    address _vrfCoordinator,
    bytes32 _vrfKeyHash, 
    uint64 _subscriptionId
  ) VRFConsumerBaseV2(
    _vrfCoordinator
  ) {

    nftContract = _nftAddress;

    COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
    subscriptionId = _subscriptionId;
    vrfCoordinator = _vrfCoordinator;
    keyHash = _vrfKeyHash;

    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);

  }

   /** 
     * @notice Modifier to only allow updates by the VRFCoordinator contract
     */
    modifier onlyVRFCoordinator {
        require(msg.sender == vrfCoordinator, 'Fulfillment only allowed by VRFCoordinator');
        _;
    }

    // modifier for functions only the team can call
    modifier onlyTeam() {
        require(hasRole(TEAM_ROLE,  msg.sender) || msg.sender == owner(), "Caller not in Team");
        _;
    }

  /**
   * @dev Add a Class Id
   */
   function setClassLength(uint256 _groupingId, uint256 _classLength) public onlyOwner {
      Classes[_groupingId] = _classLength;
   }


  /**
   * @dev If the tokens for some class are pre-minted and owned by the
   * contract owner, they can be used for a given class by setting them here
   */
  function setClassForTokenId(
    uint256 _groupingId,
    uint256 _classId,
    uint256 _tokenId,
    uint256 _amount
  ) public onlyOwner {
  //  _checkTokenApproval();
    _addTokenIdToClass(_groupingId, _classId, _tokenId, _amount);
  }

  /**
   * @dev bulk replace all tokens for a class
   */
  function setClassTokenIds(
    uint256 _groupingId,
    uint256 _classId,
    uint256[] calldata _tokenIds
  ) public onlyOwner {
    classToTokenIds[_groupingId][_classId] = _tokenIds;
  }

 
  /**
   * @dev Remove all token ids for a given class, causing it to fall back to
   * creating/minting into the nft address
   */
  function resetClass(
    uint256 _groupingId,
    uint256 _classId
  ) public onlyOwner {
    delete classToTokenIds[_groupingId][_classId];
  }

  /**
   * @param _groupingId The Grouping this Option is for
   * @param _optionId The Option to set settings for
   * @param _maxQuantityPerOpen Maximum number of items to mint per open.
   *                            Set to 0 to disable this pack.
   * @param _classProbabilities Array of probabilities (basis points, so integers out of 10,000)
   *                            of receiving each class (the index in the array).
   *                            Should add up to 10k and be descending in value.
   * @param _guarantees         Array of the number of guaranteed items received for each class
   *                            (the index in the array).
   */
  function setOptionSettings(
    uint256 _groupingId,
    uint256 _optionId,
    uint32 _maxQuantityPerOpen,
    uint16[] calldata _classProbabilities,
    uint16[] calldata _guarantees
  ) external onlyOwner {
    addOption(_optionId);
    // Allow us to skip guarantees and save gas at mint time
    // if there are no classes with guarantees
    bool hasGuaranteedClasses = false;
    for (uint256 i = 0; i < Classes[_groupingId]; i++) {
      if (_guarantees[i] > 0) {
        hasGuaranteedClasses = true;
      }
    }

    OptionSettings memory settings = OptionSettings({
      groupingId: _groupingId,
      maxQuantityPerOpen: _maxQuantityPerOpen,
      classProbabilities: _classProbabilities,
      hasGuaranteedClasses: hasGuaranteedClasses,
      guarantees: _guarantees
    });

    
    optionToSettings[_optionId] = settings;
  }


  function getLastOpen(address _address) external view returns(uint256[] memory) {
    return lastOpen[_address];
  }

  function getIsOpening(address _address) external view returns(uint256) {
    return isOpening[_address];  
  }
  
  /**
   * @dev Add an option Id
   */
  function addOption(uint256 _optionId) internal onlyOwner{
    if(_optionId >= Option.length || _optionId == 0){
      Option.push(true);
    }
  }


  /**
   * @dev Open the NFT pack and send what's inside to _toAddress
   */
  function open(
    uint256 _optionId,
    address _toAddress,
    uint256 _amount
  ) external onlyRole(MINTER_ROLE) {
    _mint(_optionId, _toAddress, _amount, "");
  }


  /**
   * @dev Main minting logic for NftPacks
   */
  function _mint(
    uint256 _optionId,
    address _toAddress,
    uint256 _amount,
    bytes memory /* _data */
  ) internal whenNotPaused onlyRole(MINTER_ROLE) nonReentrant returns (uint256) {
    // Load settings for this box option
    
    OptionSettings memory settings = optionToSettings[_optionId];

    require(settings.maxQuantityPerOpen > 0, "NftPack#_mint: OPTION_NOT_ALLOWED");
    require(isOpening[_toAddress] == 0, "NftPack#_mint: OPEN_IN_PROGRESS");

   // require(LINK.balanceOf(address(this)) > linkFee, "Not enough LINK - fill contract with faucet");

    isOpening[_toAddress] = _optionId;
    uint256 _requestId = COORDINATOR.requestRandomWords(
      keyHash,
      subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      1
    );

    PackQueueInfo memory queue = PackQueueInfo({
      userAddress: _toAddress,
      optionId: _optionId,
      amount: _amount
    });
    
    packQueue[_requestId] = queue;

    return _requestId;
 
  }

  /**
   * @notice Callback function used by VRF Coordinator
  */
   function fulfillRandomWords(
    uint256 requestId,
    uint256[] memory randomWords
  ) internal override {

    // _randomWords = randomWords;
    _randomness = randomWords[0];
    
    PackQueueInfo memory _queueInfo = packQueue[requestId];
    doMint(_queueInfo.userAddress, _queueInfo.optionId, _queueInfo.amount);

  }

  function doMint(address _userAddress, uint256 _optionId, uint256 _amount) internal onlyVRFCoordinator {
    
    OptionSettings memory settings = optionToSettings[_optionId];
   
    isOpening[_userAddress] = 0;

    delete lastOpen[_userAddress];
    uint256 totalMinted = 0;
    // Iterate over the quantity of packs to open
    for (uint256 i = 0; i < _amount; i++) {
      // Iterate over the classes
      uint256 quantitySent = 0;
      if (settings.hasGuaranteedClasses) {
        // Process guaranteed token ids
        for (uint256 classId = 1; classId < settings.guarantees.length; classId++) {
            uint256 quantityOfGaranteed = settings.guarantees[classId];

            if(quantityOfGaranteed > 0) {
              lastOpen[_userAddress].push(_sendTokenWithClass(settings.groupingId, classId, _userAddress, quantityOfGaranteed));
              quantitySent += quantityOfGaranteed;    
            }
        }
      }

      // Process non-guaranteed ids
      while (quantitySent < settings.maxQuantityPerOpen) {
        uint256 quantityOfRandomized = 1;
        uint256 classId = _pickRandomClass(settings.classProbabilities);
        lastOpen[_userAddress].push(_sendTokenWithClass(settings.groupingId, classId, _userAddress, quantityOfRandomized));
        quantitySent += quantityOfRandomized;
      }
      totalMinted += quantitySent;
    }

    emit cardPackOpened(_optionId, _userAddress, _amount, totalMinted);
  }

  function numOptions() external view returns (uint256) {
    return Option.length;
  }

  function numClasses(uint256 _groupingId) external view returns (uint256) {
    return Classes[_groupingId];
  }

  // Returns the tokenId sent to _toAddress
  function _sendTokenWithClass(
    uint256 _groupingId,
    uint256 _classId,
    address _toAddress,
    uint256 _amount
  ) internal returns (uint256) {
     // ERC1155Tradable nftContract = ERC1155Tradable(nftAddress);


    uint256 tokenId = _pickRandomAvailableTokenIdForClass(_groupingId, _classId);
      
      //super fullback to a set ID
      if(tokenId == 0){
        tokenId = defaultNftId;
      }

      //nftContract.mint(_toAddress, tokenId, _amount, "0x0");

      // @dev some ERC1155 contract doesn't support the: _toAddress
      // we need to transfer it to the address after mint
      if(nftContract.balanceOf(address(this),tokenId) == 0 ){
        nftContract.mint(address(this), tokenId, _amount, "0x0");
      }
      
      nftContract.safeTransferFrom(address(this), _toAddress, tokenId, _amount, "0x0");
    

    return tokenId;
  }

  function _pickRandomClass(
    uint16[] memory _classProbabilities
  ) internal returns (uint256) {
    uint16 value = uint16(_random()%INVERSE_BASIS_POINT);
    // Start at top class (length - 1)
    for (uint256 i = _classProbabilities.length - 1; i > 0; i--) {
      uint16 probability = _classProbabilities[i];
      if (value < probability) {
        return i;
      } else {
        value = value - probability;
      }
    }
    return 1;
  }

  function _pickRandomAvailableTokenIdForClass(
    uint256 _groupingId,
    uint256 _classId
  ) internal returns (uint256) {

    uint256[] memory tokenIds = classToTokenIds[_groupingId][_classId];
    require(tokenIds.length > 0, "NftPack#_pickRandomAvailableTokenIdForClass: NO_TOKENS_ASSIGNED");
 
    uint256 randIndex = _random()%tokenIds.length;
    // ERC1155Tradable nftContract = ERC1155Tradable(nftAddress);

      for (uint256 i = randIndex; i < randIndex + tokenIds.length; i++) {
        uint256 tokenId = tokenIds[i % tokenIds.length];

        // first check if we have a balance in the contract
        if(nftContract.balanceOf(address(this),tokenId)  > 0 ){
          return tokenId;
        }

        if(allowMint){
          uint256 curSupply;
          uint256 maxSupply;
          if(internalMaxSupply[_groupingId][_classId][tokenId] > 0){
            maxSupply = internalMaxSupply[_groupingId][_classId][tokenId];
            curSupply = internalTokensMinted[_groupingId][_classId][tokenId];
          } else {
            maxSupply = nftContract.tokenMaxSupply(tokenId);
            curSupply = nftContract.tokenSupply(tokenId);
          }

          uint256 newSupply = curSupply + 1;
          if (newSupply <= maxSupply) {
            internalTokensMinted[_groupingId][_classId][tokenId] = internalTokensMinted[_groupingId][_classId][tokenId] + 1;
            return tokenId;
          }
        }


      }

      return 0;    
  }

  /**
   * @dev Take oracle return and generate a unique random number
   */
  function _random() internal returns (uint256) {
    uint256 randomNumber = uint256(keccak256(abi.encode(_randomness, _seed)));
    _seed += 1;
    return randomNumber;
  }


  /**
   * @dev emit a Warning if we're not approved to transfer nftAddress
   */
  function _checkTokenApproval() internal {
//    ERC1155Tradable nftContract = ERC1155Tradable(nftAddress);
    if (!nftContract.isApprovedForAll(owner(), address(this))) {
      emit Warning("NftContract contract is not approved for trading collectible by:", owner());
    }
  }

  function _addTokenIdToClass(uint256 _groupingId, uint256 _classId, uint256 _tokenId, uint256 _amount) internal {
    classToTokenIds[_groupingId][_classId].push(_tokenId);
    internalMaxSupply[_groupingId][_classId][_tokenId] = _amount;
  }

  /**
   * @dev set the nft contract address callable by owner only
   */
  function setNftContract(ERC1155Tradable _nftAddress) public onlyOwner {
      nftContract = _nftAddress;
      emit SetNftContract(msg.sender, _nftAddress);
  }

  function setDefaultNftId(uint256 _nftId) public onlyOwner {
      defaultNftId = _nftId;
  }
  
  function resetOpening(address _toAddress) public onlyTeam {
    isOpening[_toAddress] = 0;
  }

  function setAllowMint(bool _allowMint) public onlyOwner {
      allowMint = _allowMint;
  }

  /**
   * @dev transfer LINK out of the contract
   */
/*  function withdrawLink(uint256 _amount) public onlyOwner {
      require(LINK.transfer(msg.sender, _amount), "Unable to transfer");
  }*/

  // @dev transfer NFTs out of the contract to be able to move into packs on other chains or manage qty
  function transferNft(ERC1155Tradable _nftContract, uint256 _id, uint256 _amount) public onlyOwner {
      _nftContract.safeTransferFrom(address(this),address(owner()),_id, _amount, "0x00");
  }
  /**
   * @dev update the link fee amount
   */
  function setLinkGas(uint32 _callbackGasLimit) public onlyOwner {
      callbackGasLimit = _callbackGasLimit;
      // emit SetLinkFee(msg.sender, _linkFee);
  }

  function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure override returns(bytes4) {
      return 0xf23a6e61;
  }


  function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external pure override returns(bytes4) {
      return 0xbc197c81;
  }

  function supportsInterface(bytes4 interfaceID) public view virtual override(AccessControl,IERC165) returns (bool) {
      return  interfaceID == 0x01ffc9a7 ||    // ERC-165 support (i.e. `bytes4(keccak256('supportsInterface(bytes4)'))`).
      interfaceID == 0x4e2312e0;      // ERC-1155 `ERC1155TokenReceiver` support (i.e. `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) ^ bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
  }
}