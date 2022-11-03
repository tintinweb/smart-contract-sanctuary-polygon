// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Marketplace/IERC721P.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IMortgageControl.sol";
import "../Marketplace/ILazymint.sol";
import "./IMarketplace.sol";
import "../Marketplace/IVaultRewards.sol";
import "../NFT Contracts/IwrapNFT.sol";
import "./IVaultLenders.sol";
import "../Mortgage/TokenInfo.sol";

contract Mortgages is AccessControl, ReentrancyGuard, IMortgageInterest, IERC721Receiver {

     ///@dev developer role created
    bytes32 public constant DEV_ROLE = keccak256("DEV_ROLE");

    event mortgageEvent(uint256 id,address user,address collection, address wrapContract, uint256 nftId, uint256 loan);
    event releaseEvent(uint256 idMortgage,address user, address collection,uint256 nftId, string status);
    event mortgageAgain(uint256 oldId,uint256 newId, address user,uint256 newLoan, uint256 newDebt);

     //Change to mainnet multisig-wallet
    address public walletPanoram = 0x526324c87e3e44630971fd2f6d9D69f3914e01DA; 
    address public mortgageControl;
    address public market;
    TokenInfo public tokenInfo;

    uint256 public mortgageId = 0;
    uint64 private maxLoan = 8000; //8000 is equal to 80%
    uint64 private minLoan = 1000; //1000 is equal to 10%
    uint64 private mortgageFee = 150; //150 is equal to 1.5%
    uint64 private mintingFee = 150; //150 is equal to 1.5%
    uint256 private feeLenders= 1500; //Equals 15%
    uint256 private feeRewards = 3500; //Equals 35%
    uint256 private feePanoram = 5000; //Equals 50%
    uint256 public feeBuyMarket = 75; //Equal 0.75%
    uint256 private maxperiod = 60; //60 months is equal to 5 years.

    ///@dev address1 collection address
    ///@dev address2 wrapcontract address
    mapping(address => address) private wrapData;

    constructor(address _tokenInfo,address _mortgageControl, address _market,address _token, address vaultLenders, 
    address vaultRewards, address RewardsLenders){
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEV_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, 0x526324c87e3e44630971fd2f6d9D69f3914e01DA);
        _setupRole(DEV_ROLE, 0x526324c87e3e44630971fd2f6d9D69f3914e01DA);
        _setupRole(DEV_ROLE, 0x988F94C0Ef61815AacD775789Af297713408D3B8);
        tokenInfo = TokenInfo(_tokenInfo);
        mortgageControl = _mortgageControl;
        market = _market;
         permissions(_token, vaultLenders, vaultRewards,RewardsLenders );
         approveToken(_token);
        /*IERC20(_token).approve(market, 2**255); //approve BUSD Testnet
        IERC20(_token).approve(address(vaultLenders), 2**255); //approve BUSD Testnet
        IERC20(_token).approve(address(vaultRewards), 2**255); //approve BUSD Testnet
        IERC20(_token).approve(address(RewardsLenders), 2**255); //approve BUSD Testnet */
    }

    modifier validToken(address _token){
        if(!tokenInfo.getToken(_token)){
            revert("Token not support");
        }
        _;
    }

    modifier onlydev() {
         if (!hasRole(DEV_ROLE, msg.sender)) {
            revert("have no dev role");
        }
        _;
    }

    struct LocalMortgage {
    address _collection;
    uint256 valuation;
    uint256 price;
    uint256 presalePrice;
    uint256 avaibleLoan;
    uint256 downPay;
    address wrapContract;
    uint256 fee;
    uint256 total;
    uint256 total2;
    uint256 total3;
    uint256 pan;
    uint256 rewards;
    uint256 lenders;
    uint256 pan2;
    uint256 rewards2;
    uint256 lenders2;
    }

    struct LocalMortgage2{
    uint256 amount;
    uint256 tokenId;
    string uri;
    uint256 minLoan;
    address owner;
    bool isPay;
    uint256 marketPrice;
    uint256 buyFee;
    bool mortgageAgain;
    uint256 linkId;
    uint256 subtotal;
    uint256 newLoan;
    uint256 mintfee;
    uint256 debt;
    uint256 maxAvaible;
    uint256 money;
    }

    struct LocalMortgage3{
        uint256 _loan;
        uint256 _period;
    }

    struct Localdebt {
        uint256 totalDebt;
        uint256 totalMonthlyPay;
        uint256 totalDelayedMonthlyPay;
        uint256 totalToPayOnLiquidation;
        uint256 lastTimePayment;
        bool isMonthlyPaymentPayed;
        bool isMonthlyPaymentDelayed;
        bool liquidate;
        uint256 newDebt;
    }

    struct LocalVaults {
        address vaultLenders;
        address vaultRewards;
        address RewardsLenders;
    }
   
    function openMortgage(address collection, uint256 loan, uint256 period,address token) public returns(uint256 id){
        LocalMortgage memory locals;
        LocalMortgage2 memory locals2;
        LocalMortgage3 memory locals3;
        LocalVaults memory vaults;
        
        locals3._loan = loan;
        locals3._period = period;
        
        locals._collection = collection;
        if(locals._collection == address(0)){
            revert ("is address 0");
        }

        if(period > maxperiod){
            revert ("exceed maximum period");
        }

        locals.valuation = ILazyNFT(locals._collection).nftValuation();
        locals.price = ILazyNFT(locals._collection).getPrice();
        locals.avaibleLoan;
        if(locals.price >= locals.valuation){
            locals.avaibleLoan = _getPortion(locals.valuation, maxLoan);
        }else{
            locals.avaibleLoan = _getPortion(locals.price, maxLoan);
        }
        if(locals3._loan > locals.avaibleLoan){
            revert ("exceed your maximum loan");
        }
        locals2.minLoan = _getPortion(locals.valuation, minLoan);
        if(locals3._loan < locals2.minLoan){
            revert ("Less than allowed");
        }
        locals.downPay = locals.price - locals3._loan;
        
        id = ++mortgageId;
        locals.wrapContract = wrapData[locals._collection];
        
        locals.fee = _getPortion(loan, mortgageFee);//mortgage fee calculation
        locals2.mintfee = _getPortion(locals.price, mintingFee);//minting fee calculation
        
        if(!IERC20(token).transferFrom(msg.sender, address(this), locals.downPay)){
                    revert("transfer fail");
         } //transfer downpayment

        (vaults.vaultLenders,vaults.RewardsLenders,vaults.vaultRewards) = tokenInfo.getVaultInfo(token);
        
        //Distribution fees
        locals2.debt = locals3._loan + locals.fee + locals2.mintfee;
        IVaultLenders(vaults.vaultLenders).withdraw(locals2.debt, token);
       
        (locals.pan, locals.rewards, locals.lenders) = calcFees(locals.fee); 
        (locals.pan2, locals.rewards2, locals.lenders2)= calcFees(locals2.mintfee); 
        locals.total2 = locals.rewards + locals.rewards2;
        locals.total3 = locals.lenders + locals.lenders2;
        
        IVaultRewards(vaults.vaultRewards).deposit(locals.total2, token);
        IVaultRewards(vaults.RewardsLenders).deposit(locals.total3, token);
        locals2.amount = locals.pan + locals.pan2 + locals.price;
        if(!IERC20(token).transfer(walletPanoram, locals2.amount)){
                    revert("transfer fail");
         }  //transfer percentage fee and NFT cost
        //Create and wrap NFT
        locals2.tokenId = INFTMarket(market).mintingMortgage(locals._collection, address(this), msg.sender,locals.price);
        locals2.uri = ILazyNFT(locals._collection).tokenURI(locals2.tokenId);
        IwrapNFT(locals.wrapContract).wrapNFT(msg.sender, locals2.tokenId, locals2.uri);
        ILazyNFT(locals._collection).transferFrom(address(this),locals.wrapContract,locals2.tokenId);
        //Register information
        IMortgageControl(mortgageControl).addMortgageId(locals._collection, locals2.tokenId , id);
        IMortgageControl(mortgageControl).addRegistry(id,msg.sender, locals._collection, locals.wrapContract,locals2.tokenId, locals2.debt,
        locals.downPay,locals.price, block.timestamp,locals3._period); 
        IMortgageControl(mortgageControl).addIdInfo(id,msg.sender);
        IMortgageControl(mortgageControl).updateLastTimeCalc(msg.sender, id, block.timestamp);

        emit mortgageEvent(id,msg.sender,locals._collection, locals.wrapContract,locals2.tokenId, locals2.debt);
    }

    function openPresaleMortgage (address collection/* , address user */, uint256 loan,uint256 period,address token) public returns(uint256 id) {
        LocalMortgage memory locals;
        LocalMortgage2 memory locals2;
        LocalMortgage3 memory locals3;
        LocalVaults memory vaults;
        locals._collection = collection;
        locals3._loan = loan;
        locals3._period = period;
        if(locals._collection == address(0)){
            revert ("is address 0");
        }
        if(period > maxperiod){
            revert ("exceed maximum period");
        }

        locals.valuation = ILazyNFT(locals._collection).nftValuation();
        locals.presalePrice = ILazyNFT(locals._collection).getPresale();
        locals.avaibleLoan;
        if(locals.presalePrice >= locals.valuation){
            locals.avaibleLoan = _getPortion(locals.valuation, maxLoan);
        }else{
            locals.avaibleLoan = _getPortion(locals.presalePrice, maxLoan);
        }
        if(locals3._loan > locals.avaibleLoan){
            revert ("exceed your maximum loan");
        }
        locals2.minLoan = _getPortion(locals.valuation, minLoan);
        if(locals3._loan < locals2.minLoan){
            revert ("Less than allowed");
        }
        locals.downPay = locals.presalePrice - locals3._loan;
        
        id = ++mortgageId;
        locals.wrapContract = wrapData[locals._collection];
     
        locals.fee = _getPortion(locals3._loan, mortgageFee); //mortgage fee calculation
        locals2.mintfee = _getPortion(locals.presalePrice, mintingFee); //minting fee calculation
        if(!IERC20(token).transferFrom(msg.sender, address(this), locals.downPay)){
                    revert("transfer fail");
         }  //transfer downpayment
        (vaults.vaultLenders,vaults.RewardsLenders,vaults.vaultRewards) = tokenInfo.getVaultInfo(token);
        //Distribution fees
        locals2.debt = locals3._loan + locals.fee + locals2.mintfee;
        
        IVaultLenders(vaults.vaultLenders).withdraw(locals2.debt, token);
        
        (locals.pan, locals.rewards, locals.lenders)= calcFees(locals.fee); 
   
     
        (locals.pan2, locals.rewards2, locals.lenders2)= calcFees(locals2.mintfee); 
     
        //locals.total = locals.pan +locals.pan2;
        locals.total2 = locals.rewards + locals.rewards2;
        locals.total3 = locals.lenders + locals.lenders2;
        
        IVaultRewards(vaults.vaultRewards).deposit(locals.total2, token);
        IVaultRewards(vaults.RewardsLenders).deposit(locals.total3, token);
        locals2.amount = locals.pan +locals.pan2 + locals.price;
        if(!IERC20(token).transfer(walletPanoram, locals2.amount)){
                    revert("transfer fail");
         }  //transfer percentage fee and NFT cost
        //Create and wrap NFT
        locals2.tokenId = INFTMarket(market).mintingPresaleMortgage(locals._collection, address(this), msg.sender,locals.presalePrice);
        locals2.uri = ILazyNFT(collection).tokenURI(locals2.tokenId);
        IwrapNFT(locals.wrapContract).wrapNFT(msg.sender, locals2.tokenId, locals2.uri);
        ILazyNFT(locals._collection).transferFrom(address(this),locals.wrapContract,locals2.tokenId);
        //Register information
        IMortgageControl(mortgageControl).addMortgageId(locals._collection, locals2.tokenId , id);
        IMortgageControl(mortgageControl).addRegistry(id,msg.sender, locals._collection, locals.wrapContract,locals2.tokenId, locals2.debt,
        locals.downPay,locals.presalePrice, block.timestamp,locals3._period); 
        IMortgageControl(mortgageControl).addIdInfo(id,msg.sender);
        IMortgageControl(mortgageControl).updateLastTimeCalc(msg.sender, id, block.timestamp);

        emit mortgageEvent(id,msg.sender,locals._collection, locals.wrapContract,locals2.tokenId, locals2.debt);
    }

    function openMarketMortgage(address collection,uint256 nftId, uint256 loan,
    uint256 period,address token) public returns(uint256 id){
     LocalMortgage memory locals;
     LocalMortgage2 memory locals2;
     LocalMortgage3 memory locals3;
     LocalVaults memory vaults;
     locals._collection = collection;
     locals3._loan = loan;
     locals3._period = period;
        if(locals._collection == address(0)){
            revert ("is address 0");
        }
        if(period > maxperiod){
            revert ("exceed maximum period");
        }
        locals2.marketPrice  = INFTMarket(market).getSalePrice(locals._collection,nftId);
        if(locals2.marketPrice == 0){
            revert ("no sale exists");
        }
        locals.valuation = ILazyNFT(locals._collection).nftValuation();
        locals.avaibleLoan;
        if(locals.presalePrice >= locals.valuation){
            locals.avaibleLoan = _getPortion(locals.valuation, maxLoan);
        }else{
            locals.avaibleLoan = _getPortion(locals2.marketPrice, maxLoan);
        }
        if(locals3._loan > locals.avaibleLoan){
            revert ("exceed your maximum loan");
        }
        locals2.minLoan = _getPortion(locals.valuation, minLoan);
        if(locals3._loan < locals2.minLoan){
            revert ("Less than allowed");
        }
        locals.downPay = locals2.marketPrice - locals3._loan;
        
        id = ++mortgageId;
        locals.wrapContract = wrapData[locals._collection];
    
        locals.fee = _getPortion(locals3._loan, mortgageFee); //mortgage fee calculation
        locals2.buyFee = _getPortion(locals2.marketPrice, feeBuyMarket); 
        if(!IERC20(token).transferFrom(msg.sender, address(this), locals.downPay)){
                    revert("transfer fail");
         }  //transfer downpayment
        (vaults.vaultLenders,,) = tokenInfo.getVaultInfo(token);
        //Distribution fees
        locals2.debt = locals3._loan + locals.fee + locals2.buyFee;
        IVaultLenders(vaults.vaultLenders).withdraw(locals2.debt, token);
        payFees(locals.fee,token);
    
        //Create and wrap NFT
        locals.total = locals2.marketPrice + locals2.buyFee;
        buyNFT(locals._collection, nftId, token, locals.total, locals2.buyFee);
        //INFTMarket(market).makeBid(collection, nftId, token, locals.total, locals2.buyFee); //buy NFT in Market
        locals2.uri = ILazyNFT(locals._collection).tokenURI(nftId);
        IwrapNFT(locals.wrapContract).wrapNFT(msg.sender, nftId, locals2.uri);
        ILazyNFT(locals._collection).transferFrom(address(this),locals.wrapContract,nftId);
        //Register information
        IMortgageControl(mortgageControl).addMortgageId(locals._collection, nftId, id);
        IMortgageControl(mortgageControl).addRegistry(id,msg.sender, locals._collection, locals.wrapContract,nftId, locals2.debt,
        locals.downPay,locals2.marketPrice, block.timestamp,locals3._period); 
        IMortgageControl(mortgageControl).addIdInfo(id,msg.sender);
        IMortgageControl(mortgageControl).updateLastTimeCalc(msg.sender, id, block.timestamp);

        emit mortgageEvent(id,msg.sender,locals._collection, locals.wrapContract,nftId, locals2.debt);
    }

    function buyNFT(address _collection, uint256 _nftId, address _token, uint256 _total, uint256 _buyFee) internal {
        INFTMarket(market).makeBid(_collection, _nftId, _token, _total, _buyFee, msg.sender); //buy NFT in Market
    }

    function payFees(uint256 _fee, address token) internal {
        (,address RewardsLenders, address vaultRewards) = tokenInfo.getVaultInfo(token);
        (uint256 pan, uint256 rewards, uint256 lenders)= calcFees(_fee); 
        IVaultRewards(vaultRewards).deposit(rewards, token);
        IVaultRewards(RewardsLenders).deposit(lenders, token);
        if(!IERC20(token).transfer(walletPanoram, pan)){
                    revert("transfer fail");
         }  //transfer percentage fee 
    }

    function remortgage(address collection, uint256 nftId, address user, uint256 loan, uint256 oldMortgage,
    uint256 period,address token) public returns(uint256 _newidMortgage){
       LocalMortgage memory locals;
       LocalMortgage2 memory locals2;
       LocalVaults memory vaults;
       Localdebt memory debt;
        if(collection == address(0)){
            revert ("is address 0");
        }
        if(period > maxperiod){
            revert ("exceed maximum period");
        }

        if(IMortgageControl(mortgageControl).getIdInfo(oldMortgage) == address(0)){
            revert ("mortgage not exist");
        }
        
        locals.wrapContract = wrapData[collection];
        (locals2.mortgageAgain, locals2.linkId) = IMortgageControl(mortgageControl).mortgageLink(user, oldMortgage);
        if(locals2.mortgageAgain || locals2.linkId != 0){
            revert("more than 1 re-mortgage");
        }
      
        locals.valuation = ILazyNFT(collection).nftValuation();
        locals.avaibleLoan = _getPortion(locals.valuation, maxLoan);
        locals2.minLoan = _getPortion(locals.valuation, minLoan);
        if(loan < locals2.minLoan){
            revert ("Less than allowed");
        }
        
        //check old mortagage
        (debt.totalDebt,,,,,debt.isMonthlyPaymentPayed,,) =
        IMortgageControl(mortgageControl).getFrontMortgageData(user, oldMortgage);
        if(!debt.isMonthlyPaymentPayed){
            revert("payment due");
        }
       
        //Mortgage calculations
        locals2.maxAvaible = locals.valuation - debt.totalDebt; //Max Loan Avaible
        locals.downPay = locals.valuation - locals.avaibleLoan; //downpayment
        locals2.newLoan = locals2.maxAvaible - locals.downPay; //Amount available for lending
        if(loan > locals2.newLoan){
            revert ("exceed your maximum loan");
        }
        
        //New Mortgage
        _newidMortgage = ++mortgageId;
        locals.fee = _getPortion(locals2.newLoan, mortgageFee); //mortgage fee calculation
        //Total debt owed by the customer to Panorama (new loan + what is still owed to Panorama).
        debt.newDebt = (locals.valuation - locals.downPay) + locals.fee;
        locals2.money = locals2.newLoan + locals.fee;
        (vaults.vaultLenders,vaults.RewardsLenders,vaults.vaultRewards) = tokenInfo.getVaultInfo(token);
        //Distribution fees
        IVaultLenders(vaults.vaultLenders).withdraw(locals2.money, token);
      
        (locals.pan, locals.rewards, locals.lenders)= calcFees(locals.fee); 
        IVaultRewards(vaults.vaultRewards).deposit(locals.rewards, token);
        IVaultRewards(vaults.RewardsLenders).deposit(locals.lenders, token);
        
        //transfer percentage fee and NFT cost
        if(!IERC20(token).transfer(walletPanoram, locals.pan)){
                    revert("transfer fail");
         } 
        //transfer avaible tokens to the user
        if(!IERC20(token).transfer(user,locals2.newLoan)){
                    revert("transfer fail");
         } 
        IMortgageControl(mortgageControl).addMortgageId(collection, nftId, _newidMortgage);
        IMortgageControl(mortgageControl).updateMortgageLink(oldMortgage,_newidMortgage,user,debt.newDebt, locals.downPay,
        block.timestamp, period, true);
        IMortgageControl(mortgageControl).addIdInfo(_newidMortgage,user);
        IMortgageControl(mortgageControl).resetDebt(user, oldMortgage);
        IMortgageControl(mortgageControl).updateLastTimeCalc(user, _newidMortgage, block.timestamp);

        emit mortgageAgain(oldMortgage,_newidMortgage,user,locals2.newLoan, debt.newDebt);
    }

    function mortgagePaid(uint256 idMortgage,address collection, address user, uint256 tokenId) public{
       LocalMortgage memory locals;
       LocalMortgage2 memory locals2;
       locals._collection = collection;
       locals2.tokenId = tokenId;
        if(locals._collection == address(0)){
            revert ("is address 0");
        }
        locals.wrapContract = wrapData[locals._collection];
        locals2.owner = IwrapNFT(locals.wrapContract).ownerOf(locals2.tokenId);
        if(locals2.owner != msg.sender){
            revert("not the owner");
        }
        locals2.isPay = IMortgageControl(mortgageControl).mortgageStatuts(user, idMortgage);
        if(!locals2.isPay){
            revert("active mortgage");
        }
        //burn wrapNFT and transfer the original NFT
        IwrapNFT(locals.wrapContract).unWrap(user, locals2.tokenId);

        IMortgageControl(mortgageControl).eraseMortgageId(collection, tokenId);
        
        emit releaseEvent(idMortgage,user,locals._collection,locals2.tokenId, "released"); 
    }

    function getRemortgageInfo(address user, uint256 oldMortgage) public view returns(uint256,uint256,uint256,uint256,uint256){
        LocalMortgage memory locals;
        LocalMortgage2 memory locals2;
        Localdebt memory debt;
        if(IMortgageControl(mortgageControl).getIdInfo(oldMortgage) == address(0)){
            revert ("mortgage not exist");
        }
       
        (locals2.mortgageAgain, locals2.linkId) = IMortgageControl(mortgageControl).mortgageLink(user, oldMortgage);
        if(locals2.mortgageAgain || locals2.linkId != 0){
            revert("more than 1 re-mortgage");
        }
        
        locals.valuation = ILazyNFT(locals._collection).nftValuation();
        locals.avaibleLoan = _getPortion(locals.valuation, maxLoan);
        locals2.minLoan = _getPortion(locals.valuation, minLoan);
        //check old mortagage
        (debt.totalDebt,,,,,debt.isMonthlyPaymentPayed,,) =
        IMortgageControl(mortgageControl).getFrontMortgageData(user, oldMortgage);
        if(!debt.isMonthlyPaymentPayed){
            revert("payment due");
        }
        //Mortgage calculations
        locals2.maxAvaible = locals.valuation - debt.totalDebt; //Max Loan Avaible
        locals.downPay = locals.valuation - locals.avaibleLoan; //downpayment
        locals2.newLoan = locals2.maxAvaible - locals.downPay; //Amount available for lending
       
        //New Mortgage
        locals.fee = _getPortion(locals2.newLoan, mortgageFee); //mortgage fee calculation
        //Total debt owed by the customer to Panorama (new loan + what is still owed to Panorama).
        debt.newDebt = (locals.valuation - locals.downPay) + locals.fee;
        return(locals2.maxAvaible,locals.downPay,locals2.newLoan, locals.fee,debt.newDebt);
    }

    function _getPortion(uint256 _valuation, uint256 _percentage)
        internal
        pure
        returns (uint256)
    {
        return (_valuation * (_percentage)) / 10000;
    }
    function calcFees(uint256 _fee) internal view returns(uint256 panoram, uint256 rewards, uint256 lenders){
        rewards = _getPortion(_fee, feeRewards);
        panoram = _getPortion(_fee, feePanoram);
        lenders =   _getPortion(_fee, feeLenders);
        return (panoram,rewards, lenders);
    }

    function addWrapData(address collection, address wrap) public {
          if (!hasRole(DEV_ROLE, msg.sender)) {
            revert("have no dev role");
        }
        wrapData[collection] = wrap;
    }

    function updateMaxPeriod(uint256 _maxPeriod) public {
        if (!hasRole(DEV_ROLE, msg.sender)) {
             revert("have no dev role");
        }
        maxperiod = _maxPeriod;
    }

     function updateControl(address _newControl) public {
        if (!hasRole(DEV_ROLE, msg.sender)) {
            revert("have no dev role");
        }
        mortgageControl = _newControl;
    }

    function updateMarket(address _newMarket) public {
         if (!hasRole(DEV_ROLE, msg.sender)) {
            revert("have no dev role");
        }
        market = _newMarket;
    }

    function updateTokenInfo(address _tokenInfo) public {
        if (!hasRole(DEV_ROLE, msg.sender)) {
             revert("have no dev role");
        }
        tokenInfo = TokenInfo(_tokenInfo);
    }

    function permissions(address _token, address _lender, address _rewards, address _lendersrewards) public onlydev validToken(_token) {
        IERC20(_token).approve(_lender, 2**255);
        IERC20(_token).approve(_rewards, 2**255);
        IERC20(_token).approve(_lendersrewards, 2**255);
    }

    function approveToken(address _token) public {
        IERC20(_token).approve(market, 2**255); //approve BUSD Testnet
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function updateMaxLoan(uint64 _maxLoan) public onlydev {
        maxLoan = _maxLoan;
    }
    function updateMinLoan(uint64 _minLoan) public onlydev {
        minLoan = _minLoan;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IERC721P is IERC165 {

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

    function holdInfo(uint256 tokenId) external view returns (uint32);

    function mintInfo(address _owner) external view  returns (uint32);

    function walletOfOwner(address _owner) external view returns (uint256[] memory, uint256 _length);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
interface ILazyNFT is IERC165{
    
    function redeem(
        address _redeem,
        uint256 _amount
    ) external returns (uint256);

    function preSale(
        address _redeem,
        uint256 _amount
    ) external returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

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

    function tokenURI(uint256 tokenId) external view returns (string memory base);

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory, uint256 _length);

    function totalSupply() external view returns (uint256);

    function maxSupply() external view returns (uint256);
     
    function getPrice() external view returns (uint256);
    
    function getPresale() external view returns (uint256);

    function getPresaleStatus() external view returns (bool);

    function nftValuation() external view returns (uint256 _nftValuation);

    function getValuation() external view returns (uint256 _valuation);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract TokenInfo is AccessControl {

    ///@dev developer role created
    bytes32 public constant DEV_ROLE = keccak256("DEV_ROLE");

    
    modifier onlydev() {
         if (!hasRole(DEV_ROLE, msg.sender)) {
            revert("have no dev role");
        }
        _;
    }

    constructor(){
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEV_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, 0x526324c87e3e44630971fd2f6d9D69f3914e01DA);
        _setupRole(DEV_ROLE, 0x526324c87e3e44630971fd2f6d9D69f3914e01DA);
        _setupRole(DEV_ROLE, 0x988F94C0Ef61815AacD775789Af297713408D3B8);
    }

    struct Vaults{
        address lender;
        address lenderRewards;
        address rewards;
    }
    //registration and control of approved tokens
    mapping(address => bool) internal tokens;
    //save the token contract and the vault for it
    mapping(address => Vaults) internal vaultsInfo;
    //save the collection contract and the rental vault contract to be used for each collection
    mapping(address => address) internal collectionToVault;

    function addToken(address _token) public onlydev {
        tokens[_token] = true;
    }

    function removeToken(address _token) public onlydev {
        tokens[_token] = false;
    }

    function getToken(address _token) public view returns(bool _ok){
        return tokens[_token];
    }

    function addVaultRegistry(address _token, address _lender,address _lenderRewards,address _rewards) public onlydev  {
        vaultsInfo[_token].lender = _lender;
        vaultsInfo[_token].lenderRewards = _lenderRewards;
        vaultsInfo[_token].rewards = _rewards;
    }

    function removeVaultRegistry(address _token) public onlydev  {
        vaultsInfo[_token].lender = address(0);
        vaultsInfo[_token].lenderRewards = address(0);
        vaultsInfo[_token].rewards = address(0);
    }

    function getVaultInfo(address _token) public view returns(address _lender, address _lenderRewards,address _rewards){
        return ( vaultsInfo[_token].lender,
        vaultsInfo[_token].lenderRewards,
        vaultsInfo[_token].rewards);
    }

    function addVaultRent(address _collection, address _vault) public onlydev {
        collectionToVault[_collection] = _vault;
    }

    function removeVaultRent(address _collection) public onlydev {
        collectionToVault[_collection] = address(0);
    }

    function getVaultRent(address _collection) public view returns(address _vault){
        return collectionToVault[_collection];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.10;

import "./IMortgageInterest.sol";

interface IMortgageControl is IMortgageInterest {

    function addIdInfo(uint256 id, address wallet) external;

    function updateCapitalPay(uint256 id, address wallet, uint256 _newDebt) external; 

    function getTotalMortgages() external view returns (uint256);

    function getCapitalPay(address _user, uint256 _mortgageId) external view returns(uint256 _capitalPay);

    function getDebtInfo(address _user, uint256 _mortgageId) external view returns(uint256,uint256,uint256);

    function mortgageStatuts(address _user, uint256 _mortgageId) external view returns (bool _isPay);

    function getMortgageLiquidationStatus(address _user, uint256 _mortgageId) external view returns(bool _status);

    function mortgageLink(address _user, uint256 _mortgageId) external view returns (bool _mortgageAgain, uint256 _linkId);

    function getMortgagesForWallet(address _wallet, address _collection)
        external
        view
        returns (uint256[] memory _idMortgagesForCollection);

    function getuserToMortgageInterest(address _wallet, uint256 _IdMortgage)
        external
        view
        returns (MortgageInterest memory);

    // Get FrontEnd Data
    function getFrontMortgageData(address _wallet, uint256 _IdMortage)
        external
        view
        returns (
            uint256 totalDebt,
            uint256 totalMonthlyPay,
            uint256 totalDelayedMonthlyPay,
            uint256 totalToPayOnLiquidation,
            uint256 lastTimePayment,
            bool isMonthlyPaymentPayed,
            bool isMonthlyPaymentDelayed,
            bool liquidate
        );

    function getIdInfo(uint256 id) external view returns (address _user);

    function getInterestRate() external view returns(uint64 _interest);

    function getMortgageId(address _collection, uint256 _nftId) external view returns(uint256 _mortgageId);

    function getStartDate(address _wallet, uint256 _mortgageID) external view returns(uint256);

    function getUserInfo(address _user, uint256 _mortgageId)
        external
        view
        returns (
            address,
            uint256,
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            bool,
            uint256
        );

    function getMortgageStatus(address _user, uint256 _mortgageId) external view returns(bool _status);

    function addMortgageId(address _collection, uint256 _nftId, uint256 _loanId) external;

    function eraseMortgageId(address _collection, uint256 _nftId) external;

    function addRegistry(uint256 id, address wallet, address _collection, address _wrapContract,uint256 _nftId, uint256 _loan,uint256 _downPay,
    uint256 _price,uint256 _startDate,uint256 _period ) external; 

    function updateMortgageLink(
        uint256 oldId,
        uint256 newId,
        address wallet,
        uint256 _loan,
        uint256 _downPay,
        uint256 _startDate,
        uint256 _period,
        bool _mortageState
    ) external;

    function updateMortgageState(
        uint256 id,
        address wallet,
        bool _state
    ) external;

    function updateMortgagePayment(uint256 id, address wallet) external;

    function addNormalMorgateInterestData(
        address _wallet,
        uint256 _idMortgage,
        MortgageInterest memory _mortgage
    ) external;

    function resetMortgageInterest(address _wallet, uint256 _idMortgage) external;
    
    function resetDebt(address _wallet, uint256 _idMortgage) external;
    
    function updateLastTimeCalc(address _wallet, uint256 _idMortgage,uint256 _lastTimeCalc) external;
    
    function addDelayedMorgateInterestData(
        address _wallet,
        uint256 _idMortgage,
        MortgageInterest memory _mortgage
    ) external;

    function updateOnPayMortgageInterest(
        address _wallet,
        uint256 _idMortgage,
        MortgageInterest memory mort
    ) external;

    function updateTotalDebtOnAdvancePayment(
        address _wallet,
        uint256 _idMortgage,
        uint256 _totalDebt
    ) external;

    function updateLastTimePayment(address _wallet, uint256 _idMortgage,uint256 _lastPayment) external;
    
    function getLastTimePayment(address _wallet, uint256 _idMortgage) external view returns(uint256);


    ///@dev only for test erase in production
    function getTestInfo(address _user, uint256 _mortgageId)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;
interface INFTMarket{
    function mintingMortgage(address _collection, address _owner, address _user,uint256 _value)  external returns(uint256 _nftId);

    function mintingPresaleMortgage(address _collection, address _owner, address _user,uint256 _value)  external returns(uint256 _nftId);

    function minting(address _collection, address _owner, uint256 _value, uint256 _fee, address _token) external;

    function batchmint(address _collection, address _owner, uint256 _amount ,uint256 _value, uint256 _fee, address _token) external;

    function presaleMint(address _collection, address _owner, uint256 _value, uint256 _fee, address _token) external;

    function presaleMintbatch(address _collection, address _owner, uint256 _amount ,uint256 _value, uint256 _fee, address _token) external;

    function makeBid(address _nftContractAddress, uint256 _tokenId, address _erc20Token, uint256 _tokenAmount, 
    uint256 _feeAmount, address _newOwner) external;

    function getSale(address collection, uint256 id) external view returns
    (uint256 _buyNowPrice,address _nftHighestBidder,address _nftSeller,address _ERC20Token,
    address[] memory _feeRecipients,uint32[] memory _feePercentages);       

    function getSalePrice(address collection, uint256 id) external view returns (uint256 _buyNowPrice);
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.10;

interface IVaultLenders {
    function deposit(uint256,address) external;

    function depositCapital(uint256,address) external;

    function withdraw(uint256,address) external;

    function withdrawAll() external;

    function totalSupply() external view returns (uint256);

    function getBorrows() external view returns(uint256 borrows);
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.10;

interface IVaultRewards {
    function deposit(uint256 _amount,  address _token) external;

    function withdraw(uint256 amount, address _token) external;

    function withdrawAll() external;

    function seeDaily() external view returns (uint256 tempRewards);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IwrapNFT is IERC165 {

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

    function holdInfo(uint256 tokenId) external view returns (uint32);

    function mintInfo(address _owner) external view  returns (uint32);

    function wrapNFT(address _wallet, uint256 _Id, string memory _tokenURI) external;

    function unWrap(address _wallet, uint256 _Id) external;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
        _checkRole(role);
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
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
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
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
pragma solidity ^0.8.9;

interface IMortgageInterest {
    struct MortgageInterest {
        uint256 totalDebt; // para guardar lo que adeuda el cliente despues de cada pago
        uint256 totalMonthlyPay; // total a pagar en pago puntual 100
        uint256 amountToPanoram; // cantidad que se ira a la wallet de Panoram
        uint256 amountToPool; // cantidad que se ira al Pool de rewards
        uint256 amountToVault; // cantidad que se regresa al vault de lenders
        uint256 totalDelayedMonthlyPay; // total a pagar en caso de ser pago moratorio, incluye pagar las cuotas atrasadas
        uint256 amountToPanoramDelayed; // cantidad que se ira a la wallet de Panoram
        uint256 amountToPoolDelayed; // cantidad que se ira al Pool de rewards
        uint256 totalToPayOnLiquidation; // sumar los 3 meses con los interes
        uint256 totalPoolLiquidation; // intereses al pool en liquidation
        uint256 totalPanoramLiquidation; // total a pagar de intereses a panoram en los 3 meses que no pago.
        uint256 lastTimePayment; // guardamos la fecha de su ultimo pago
        uint256 lastTimeCalc; // la ultima vez que se calculo sus interes: para evitar calcularle 2 veces el mismo dia
        uint8 strikes; // cuando sean 2 se pasa a liquidacion. Resetear estas variables cuando se haga el pago
        bool isMonthlyPaymentPayed; // validar si ya hizo el pago mensual
        bool isMonthlyPaymentDelayed; // validar si el pago es moratorio
        bool liquidate; // true si el credito se liquido, se liquida cuando el user tiene 3 meses sin pagar
    }

    ///@notice structure and mapping that keeps track of mortgage
    struct Information {
        address collection;
        uint256 nftId;
        address wrapContract;
        uint256 loan; // total prestado
        uint256 downPay;
        uint256 price;
        uint256 startDate;
        uint256 period; //months
        uint8 interestrate; //interest percentage diario
        uint256 payCounter; //Start in zero
        bool isPay; //default is false
        bool mortgageAgain; //default is false
        uint256 linkId; //link to the new mortgage
    }
}