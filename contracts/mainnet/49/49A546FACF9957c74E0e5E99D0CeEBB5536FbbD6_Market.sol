//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../Mortgage/TokenInfo.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./MarketEvents.sol";
import "./Assistants.sol";
import "./ILazymint.sol";
import "../Rewards/IVaultRewards.sol";
import "./IControl.sol";
import "./IMarketControl.sol";
import "./IVaultNFT.sol";
//import "../Mortgage/IMortgageControl.sol";

/// @title A contract for selling single and batched NFTs
/// @notice This contract can be used for selling any NFTs, and accepts any ERC20 token as payment
contract Market is MarketEvents, Assistants, AccessControl, ReentrancyGuard {

    using SafeERC20 for IERC20;

    ///@dev developer role created
    bytes32 public constant DEV_ROLE = keccak256("DEV_ROLE");

    struct Localvars {
        address _nftContractAddress;
        uint256 _tokenId;
        address _token;
        uint256 _buyNowPrice;
        address _nftSeller;
        uint256 _amount;
        address _nftBuyer;
        address feeVaultAddress;
        address lendersVault;
    }
    struct LocalMint{
        bool _status;
        uint256 pan;
        uint256 rewards; 
        uint256 lenders;
        uint256 sell;
        uint256 value;
        uint amount;
        uint256 _nftId;
    }

    mapping(address => bool) public mortgage;

    TokenInfo public tokenInfo;
    address public control;
    address public marketControl;
    address public vaultNFT;
    //Change to mainnet multisig-wallet
    address public walletPanoram; 
    ///@notice If transfer fail save to withdraw later
    uint256 private tokenToContract;
    ///@notice Default values market fee
    uint256 public feeMarket = 75; //Equal 0.75%
    uint256 public feeBuyMarket = 75; //Equal 0.75%
    uint256 private feeLenders= 1800; //Equals 18%
    uint256 private feeRewards = 2200; //Equals 22%
    uint256 private feePanoram = 6000; //Equals 60%
    //address public mControl;
    bool paused = false;

    modifier isPaused(){
        if(paused){
            revert("contract paused");
        }
        _;
    }

    modifier onlydev() {
         if (!hasRole(DEV_ROLE, msg.sender)) {
            revert("have no dev role");
        }
        _;
    }

    modifier onlyMortgage(){
        if(!mortgage[msg.sender]){
            revert("mortgage only");
        }
        _;
    }

    modifier validToken(address _token){
        if(!tokenInfo.getToken(_token)){
            revert("Token not support");
        }
        _;
    }

    constructor(address _tokenInfo,address _control, address _marketControl, address _vaultNFT, address token, address _feeVaultAddress, address _lendersRewards, 
    address _walletPanoram) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEV_ROLE, msg.sender);
        _setupRole(DEV_ROLE, 0x526324c87e3e44630971fd2f6d9D69f3914e01DA);
        tokenInfo = TokenInfo(_tokenInfo);
        walletPanoram = _walletPanoram;
        if(_control != address(0) && token != address(0)){
        if(!tokenInfo.getToken(token)){
            revert("Token not support");
        }
        control = _control;
        //mControl = _mControl;
        marketControl = _marketControl;
        vaultNFT = _vaultNFT; //Once the market and the nft collection are displayed, the approve function must be called.
        permissions(token,_lendersRewards,_feeVaultAddress);
        }else{
            revert ("address Zero");
        }
    } 

    ///@dev Buy now price is set by the seller, check that the amount meets that price.
    function _validateSale(uint256 _saleId, address _nftContractAddress, uint256 _tokenId, uint256 amount)internal view returns (bool)
    {
        (,uint256 buyNowPrice) = IMarketControl(marketControl).getPrice(_nftContractAddress,_tokenId, _saleId);
        return amount == buyNowPrice;
    }

    function _verifyPayment(uint256 _saleId, address _nftContractAddress,uint256 _tokenId,address _ERC20Token,uint256 _tokenAmount) internal view returns (bool _condition) {
        address ERC20Address = IMarketControl(marketControl).getToken(_nftContractAddress, _tokenId, _saleId);
        if (ERC20Address == address(0)) {
            return false;
        }else if(msg.value == 0 && ERC20Address == _ERC20Token && _tokenAmount > 0){
            return true;
        }
    }

    function _transferNftToMarket( address _nftContractAddress, uint256 _tokenId, uint256 _saleId) internal {
        if (IERC721(_nftContractAddress).ownerOf(_tokenId) == msg.sender) {
                IERC721(_nftContractAddress).transferFrom(msg.sender,address(this),_tokenId);
                IVaultNFT(vaultNFT).safeguard(_nftContractAddress, _tokenId, _saleId);
        }else {
            revert("not your nft");
        }
    }

    ///@notice Allows for a standard sale mechanism.
    ///@dev check if buyNowPrice is meet and conclude sale.
    function createSale(address _nftContractAddress, uint256 _tokenId, address _erc20Token, uint256 _buyNowPrice, address _nftSeller)
    external isPaused validToken(_erc20Token) notZero(_buyNowPrice) nonReentrant{
        IMarketControl(marketControl).isTheOwner(_nftContractAddress, _tokenId, msg.sender);
        Localvars memory vars;
       
        vars._nftContractAddress = _nftContractAddress;
        vars._tokenId = _tokenId;
        vars._token = _erc20Token;
        vars._buyNowPrice = _buyNowPrice;
        vars._nftSeller = _nftSeller;

        uint _id = IMarketControl(marketControl).saveSells(vars._nftContractAddress, vars._tokenId,vars._token, vars._buyNowPrice, vars._nftSeller);

        _transferNftToMarket(vars._nftContractAddress, vars._tokenId, _id);

        emit SaleCreated(_id, vars._nftContractAddress,vars._tokenId,vars._nftSeller,vars._token,vars._buyNowPrice);       
    }

    ///@notice Buy NFT with ERC20 Token specified by the NFT seller.
    ///@notice Additionally, a buyer can pay the asking price to conclude a sale of an NFT.
    ///@param _tokenAmount is the selling price of the NFT + buyer's fee (0.75%)
    function purchase(uint256 _saleId, address _nftContractAddress, uint256 _tokenId,address _erc20Token,uint256 _tokenAmount,uint256 _feeAmount,address _newOwner) 
    external isPaused validToken(_erc20Token) nonReentrant {
        Localvars memory vars;
        vars._nftSeller = IMarketControl(marketControl).getSeller(_nftContractAddress, _tokenId, _saleId);
        if(msg.sender == vars._nftSeller){
            revert ("Not buy your NFT");
        }
        IERC20(_erc20Token).safeTransferFrom(msg.sender,address(this),_tokenAmount);
        
        if(!_verifyPayment(_saleId, _nftContractAddress, _tokenId, _erc20Token,_tokenAmount)){
            revert("Invalid Token/Amount");
        }
        
        vars._amount = _tokenAmount - _feeAmount;
        
       if (_validateSale(_saleId, _nftContractAddress, _tokenId,vars._amount)) {
            _transferNftAndPaySeller(_saleId,_nftContractAddress, _tokenId, msg.sender, vars._amount, _newOwner,_feeAmount, vars._nftSeller);
       }else{
            revert("less / more than price");
       }

        emit Purchase(_nftContractAddress,_tokenId, msg.sender,_erc20Token,_tokenAmount);
    }

   
  
    function _transferNftAndPaySeller(uint256 _saleId, address _nftContractAddress,uint256 _tokenId,address _buyer,uint256 amount,address _newOwner,uint256 _buyFee, address _seller) internal {
        Localvars memory vars;
        vars._nftSeller = _seller;
        vars._nftBuyer = _buyer;

        _feesAndPayments(_saleId, _nftContractAddress, _tokenId,vars._nftSeller,amount,_buyFee);

        IVaultNFT(vaultNFT).unlock(_nftContractAddress, _tokenId, _saleId, vars._nftBuyer);
    
        IControl(control).addQuantity(_newOwner, _nftContractAddress,1);
        IControl(control).removeQuantity(vars._nftSeller, _nftContractAddress,1);

        IMarketControl(marketControl).updateSell(_nftContractAddress, _tokenId, _saleId, vars._nftBuyer);

        emit NFTTransferredAndSellerPaid(_nftContractAddress,_tokenId,vars._nftSeller,vars._nftBuyer);
    }

    function _feesAndPayments(uint256 _saleId, address _nftContractAddress, uint256 _tokenId,address _nftSeller, uint256 _amount, uint256 _buyFee) internal {
        uint256 minusSellFee = _getFee(_amount, feeMarket);
        uint256 reward = _amount - minusSellFee;
        address token = IMarketControl(marketControl).getToken(_nftContractAddress, _tokenId, _saleId);
        _payout(_nftSeller,reward,token);
        ///@dev Transfer sell fees to the vault
        sendpayment(minusSellFee, _buyFee, token);
    }

    function sendpayment(uint256 minusfee, uint256 _buyFee, address _token) internal {
        (,address lendersVault,address feeVaultAddress) = tokenInfo.getVaultInfo(_token);

        //But fee transfer
        (uint256 pan, uint256 rewards, uint256 lenders) = calcFees(_buyFee);
        IVaultRewards(feeVaultAddress).deposit(rewards, _token);
        IVaultRewards(lendersVault).deposit(lenders, _token);
        IERC20(_token).safeTransfer(walletPanoram, pan);

        //sell fee transfer
        (uint256 pan2, uint256 rewards2, uint256 lenders2) = calcFees(minusfee); //sellFee
        IVaultRewards(feeVaultAddress).deposit(rewards2, _token);
        IVaultRewards(lendersVault).deposit(lenders2, _token);
        IERC20(_token).safeTransfer(walletPanoram, pan2);
    }


    ///@dev if the call failed, update their credit balance so they the seller can pull it later
    function _payout(address _recipient,uint256 _amount, address _token) internal {
        IERC20(_token).safeTransfer(_recipient, _amount);
    }

    ///@dev Only the owner of the NFT can prematurely close the sale or auction.
    function withdrawSell(uint256 _saleId, address _nftContractAddress, uint256 _tokenId)external isPaused {
        address _seller = IMarketControl(marketControl).getSeller(_nftContractAddress, _tokenId, _saleId);
        if(_seller != msg.sender){
           revert("not your sale");
        }

        IVaultNFT(vaultNFT).unlock(_nftContractAddress, _tokenId, _saleId, msg.sender);
        IMarketControl(marketControl).resetSell(_nftContractAddress, _tokenId,_saleId);

        emit WithdrawSale(_nftContractAddress, _tokenId, msg.sender);
    }

    function updateBuyPrice(uint256 _saleId, address _nftContractAddress,uint256 _tokenId,uint256 _newBuyNowPrice) external isPaused notZero(_newBuyNowPrice) {
        address _seller = IMarketControl(marketControl).getSeller(_nftContractAddress, _tokenId, _saleId);
        if(msg.sender != _seller){
            revert ("Only nft seller");
        }
        IMarketControl(marketControl).updateBuynowPrice(_nftContractAddress, _tokenId, _saleId, _newBuyNowPrice);
        
        emit BuyNowPriceUpdated(_nftContractAddress, _tokenId, _newBuyNowPrice);
    }

    function updateMortgage(address _newMortgage, bool _condition) public onlydev {
            mortgage[_newMortgage] = _condition;
    }


    function updateFeeMarket(uint256 _newfeeMarket) public onlydev{
            feeMarket = _newfeeMarket;
    }

    function updateBuyMarketFee(uint256 _feeBuyMarket) public onlydev{
            feeBuyMarket = _feeBuyMarket;
    }

    function updateFeeRewards(uint256 _newfeeRewards) public onlydev{
            feeRewards = _newfeeRewards;
    }

    function updateFeePanoram(uint256 _newfeePanoram) public onlydev{
            feePanoram = _newfeePanoram;
    }

    function updateFeeLenders(uint256 _newfeeLenders) public onlydev{
            feeLenders = _newfeeLenders;
    }

    function updateControl(address _newControl) public onlydev{
            control = _newControl;
    }

    function updateMarketControl(address _marketControl) public onlydev{
            marketControl = _marketControl;
    }

    function updatePaused(bool _Status) public onlydev{
        paused = _Status;
    }

     function updatePanoramWallet(address _newWalletPanoram) public onlydev{
            walletPanoram = _newWalletPanoram;
    }

    function updateTokenInfo(address _tokenInfo) public onlydev{
        tokenInfo = TokenInfo(_tokenInfo);
    }

    function permissions(address _token, address _lenderRwards, address _rewards) public onlydev validToken(_token) {
        IERC20(_token).approve(_lenderRwards, 2**255);
        IERC20(_token).approve(_rewards, 2**255);
    }

    function approve(address _vaultNFT, address[] calldata _collection) public onlydev  {
        uint256 length = _collection.length;
        for(uint i = 0; i < length; ) {
        IERC721(_collection[i]).setApprovalForAll(_vaultNFT, true);
            unchecked{
                ++i;
            }
        }
    }
    
    function mintingMortgage(address _collection, address _owner, address _user,uint256 _value) public isPaused onlyMortgage nonReentrant returns(uint256 _nftId){
        if(ILazyNFT(_collection).getPresaleStatus()){
            revert ("Presale Open");
        }
        _nftId = ILazyNFT(_collection).redeem(_owner, _value);
        addRegistry(_collection, _nftId, _user);
        emit NFTMinted(_collection, _nftId, _owner);
    }

    function mintingPresaleMortgage(address _collection, address _owner, address _user,uint256 _value) public isPaused onlyMortgage nonReentrant returns(uint256 _nftId){
        if(!ILazyNFT(_collection).getPresaleStatus()){
            revert ("Presale closed");
        }
        _nftId = ILazyNFT(_collection).preSale(_owner, _value);
        addRegistry(_collection, _nftId, _user);
        emit NFTMinted(_collection, _nftId, _owner);
    }

    function minting(address _collection, address _owner, uint256 _value, uint256 _fee, address _token) public isPaused validToken(_token) nonReentrant {
        if(!IERC20(_token).transferFrom(msg.sender, address(this), _value)){
            revert("transfer fail");
        }
        if(ILazyNFT(_collection).getPresaleStatus()){
            revert ("Presale Open");
        }
        (,address lendersVault,address feeVaultAddress) = tokenInfo.getVaultInfo(_token);
        (uint256 pan, uint256 rewards, uint256 lenders) = calcFees(_fee);
        uint256 sell = _value - _fee;
        IVaultRewards(feeVaultAddress).deposit(rewards, _token);
        IVaultRewards(lendersVault).deposit(lenders, _token);
        uint amount = pan + sell;
        if(!IERC20(_token).transfer(walletPanoram, amount)){
            revert("transfer fail");
        } //transfer percentage fee and NFT cost
        
        uint256 _nftId = ILazyNFT(_collection).redeem(_owner, sell);
        addRegistry(_collection, _nftId, _owner);

        emit NFTMinted(_collection, _nftId, _owner);
    }
    
    function batchmint(address _collection, address _owner, uint256 _amount ,uint256 _value, 
    uint256 _fee, address _token) public isPaused validToken(_token) nonReentrant {
        LocalMint memory locals;
        if(!IERC20(_token).transferFrom(msg.sender, address(this), _value)){
            revert("transfer fail");
        }
        if(ILazyNFT(_collection).getPresaleStatus()){
            revert ("Presale Open");
        }
        (,address lendersVault,address feeVaultAddress) = tokenInfo.getVaultInfo(_token);
        (locals.pan, locals.rewards, locals.lenders) = calcFees(_fee);
        locals.sell = _value - _fee;
        locals.value = locals.sell / _amount;
        IVaultRewards(feeVaultAddress).deposit(locals.rewards, _token);
        IVaultRewards(lendersVault).deposit(locals.lenders, _token);
        locals.amount = locals.pan + locals.sell;
        if(!IERC20(_token).transfer(walletPanoram, locals.amount)){
            revert("transfer fail");
        } //transfer percentage fee and NFT cost
       
        for(uint256 i=1; i <= _amount;){
            locals._nftId = ILazyNFT(_collection).redeem(_owner, locals.value);
            addRegistry(_collection, locals._nftId, _owner);
            emit NFTMinted(_collection, locals._nftId, _owner);
            unchecked {
             ++i;
            }
        }
    }

    function presaleMint(address _collection, address _owner, uint256 _value, uint256 _fee, address _token) public isPaused 
    validToken(_token) nonReentrant {
        if(!IERC20(_token).transferFrom(msg.sender, address(this), _value)){
            revert("transfer fail");
        }
        if(!ILazyNFT(_collection).getPresaleStatus()){
            revert ("Presale closed");
        }
        (,address lendersVault,address feeVaultAddress) = tokenInfo.getVaultInfo(_token);
        (uint256 pan, uint256 rewards, uint256 lenders) = calcFees(_fee);
        uint256 sell = _value - _fee;
        IVaultRewards(feeVaultAddress).deposit(rewards, _token);
        IVaultRewards(lendersVault).deposit(lenders, _token);
        uint amount = pan + sell;
        if(!IERC20(_token).transfer(walletPanoram, amount)){
            revert("transfer fail");
        } //transfer percentage fee and NFT cost
       
        uint256 _nftId = ILazyNFT(_collection).preSale(_owner, sell);
        addRegistry(_collection, _nftId, _owner);

        emit NFTPresale(_collection, _nftId, _owner);
    }

    function presaleMintbatch(address _collection, address _owner, uint256 _amount ,uint256 _value, 
    uint256 _fee, address _token) public isPaused validToken(_token) nonReentrant {
        Localvars memory vars;
        LocalMint memory locals;
        if(!IERC20(_token).transferFrom(msg.sender, address(this), _value)){
            revert("transfer fail");
        }
        if(!ILazyNFT(_collection).getPresaleStatus()){
            revert ("Presale closed");
        }
        (,vars.lendersVault,vars.feeVaultAddress) = tokenInfo.getVaultInfo(_token);
        (locals.pan, locals.rewards, locals.lenders) = calcFees(_fee);
        locals.sell = _value - _fee;
        IVaultRewards(vars.feeVaultAddress).deposit(locals.rewards, _token);
        IVaultRewards(vars.lendersVault).deposit(locals.lenders, _token);
        uint amount = locals.pan + locals.sell;
        if(!IERC20(_token).transfer(walletPanoram, amount)){
            revert("transfer fail");
        } //transfer percentage fee and NFT cost
        for(uint256 i=1; i <= _amount;){
            uint256 _nftId = ILazyNFT(_collection).preSale(_owner, locals.sell);
            addRegistry(_collection, _nftId, _owner);
            emit NFTPresale(_collection, _nftId, _owner);
            unchecked {
             ++i;
            }
        }
    }

    function calcFees(uint256 _fee) internal view returns(uint256 panoram, uint256 rewards, uint256 lenders){
        rewards = _getFee(_fee, feeRewards);
        panoram = _getFee(_fee, feePanoram);
        lenders =   _getFee(_fee, feeLenders);
        return (panoram,rewards, lenders);
    }

    function addRegistry(address _collection, uint256 _nftId, address _owner) internal {
        IControl(control).addCounter();
        IControl(control).addRegistry(_collection, _nftId, _owner, uint32(block.timestamp));
        IControl(control).addQuantity(_owner, _collection,1);
        IControl(control).addMinted(_owner,1);
    }

    fallback() external {
        //empty code
    }
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
        _setupRole(DEFAULT_ADMIN_ROLE, 0x30268390218B20226FC101cD5651A51b12C07470);
        _setupRole(DEV_ROLE, 0x30268390218B20226FC101cD5651A51b12C07470);
        _setupRole(DEV_ROLE, 0x1921a154365A82b8d54a3Cb6e2Fd7488cD0FFd23); 
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

abstract contract Assistants {

    ///@dev Returns the percentage of the total bid (used to calculate fee payments)
    function _getFee(uint256 _totalBid, uint256 _percentage)
        internal
        pure
        returns (uint256)
    {
        return (_totalBid * (_percentage)) / 10000;
    }

    modifier notZero(uint256 _price) {
        if(_price <= 0) {
            revert ("Price cannot be 0");
        }
        _;
    }
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

    function setApprovalForAll(address operator, bool approved) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

abstract contract MarketEvents {
    /*///////////////////////////////////////////////////////////////
                              EVENTS            
    //////////////////////////////////////////////////////////////*/

    event SaleCreated(
        uint256 id,
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        address erc20Token,
        uint256 buyNowPrice
    );

    event Purchase(
        address nftContractAddress,
        uint256 tokenId,
        address bidder,
        address erc20Token,
        uint256 tokenAmount
    );


    event NFTTransferredAndSellerPaid(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        address nftBuyer
    );

    event WithdrawSale(
        address nftContractAddress,
        uint256 tokenId,
        address nftOwner
    );

    event BuyNowPriceUpdated(
        address nftContractAddress,
        uint256 tokenId,
        uint256 newBuyNowPrice
    );

    event NFTTransferred(
        address nftContractAddress,
        uint256 tokenId,
        address nftBuyer
    );

    event NFTMinted(
        address nftContractAddress,
        uint256 tokenId,
        address wallet
    );

    event NFTPresale(
        address nftContractAddress,
        uint256 tokenId,
        address wallet
    );

    /*///////////////////////////////////////////////////////////////
                              END EVENTS            
    //////////////////////////////////////////////////////////////*/
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.10;

/// @title Vault Rewards Builder & Holders Interface.
/// @author Panoram Finance.
/// @notice Use this interface in other contracts to connect to the Vault Rewards Builder & Holders Contract.
interface IVaultRewards {

    /// @dev Function to deposit money in the vault.
    function deposit(uint256 _amount,  address _token) external;

    /// @dev Function to withdraw money from the vault.
    function withdraw(uint256 amount, address _token) external;

    /// @dev Function for the Multisig to withdraw all the money from the vault if necessary in an emergency.
    function withdrawAll() external;

    /// @dev Function to read the amount of rewards to distribute each day.
    function seeDaily() external returns (uint256 tempRewards);

    /// @dev Function to get the last time the seeDaily flag was calculated.
    function getLastCall() external view returns(uint256 _last);

    /// @dev Function to get the available rewards in the vault to distribute.
    function getAvaibleRewards() external view returns(uint256 _avaible);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IVaultNFT {
    function safeguard(address _collection, uint256 _tokenId, uint256 _saleId) external;

    function unlock(address _collection, uint256 _tokenId, uint256 _saleId, address _buyer) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./IStructInfo.sol";
interface IMarketControl is IStructInfo {

    function saveSells(address _collection, uint256 _tokenId, address _erc20Token, uint256 _buyNowPrice, address _seller ) external returns(uint);

    function getPrice(address _collection, uint256 _tokenId, uint256 _saleId) external view returns(address _token, uint256 _price);

    function getToken(address _collection, uint256 _tokenId, uint256 _saleId) external view returns (address _token);

    function updateBuynowPrice(address _collection, uint256 _tokenId,  uint256 _saleId, uint256 _newBuyNowPrice) external;

    function getSeller(address _collection, uint256 _tokenId, uint256 _saleId) external view returns (address _owner);

    function isTheOwner(address _collection, uint256 _tokenId, address caller) external view;

    function resetSell(address _collection, uint256 _tokenId, uint256 _saleId) external;

    function updateSell(address _collection, uint256 _tokenId, uint256 _saleId, address _buyer) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.11;

interface IControl {

   function getNFTInfo(address _collection, uint256 _id)
        external
        view
        returns (
            address,
            uint256,
            address,
            uint32
        );

    function getNFTMinted(address _wallet) external view returns (uint256 _minted);

    function getNFTQuantity(address _wallet, address _collection)external view returns (uint256 _quantity);

    function getNFTTotal(address _wallet) external view returns (uint256 _total);

    function addRegistry(address _collection, uint256 _nftId, address _wallet,uint32 _timestamp) external;

    function removeRegistry(address _collection, uint256 _nftId) external;

    function addQuantity(address _wallet,address _collection,uint256 _amount) external;

    function removeQuantity(address _wallet,address _collection, uint256 _amount) external;

    function addMinted(address _wallet,uint256 _amount) external;

    function addCounter() external;

    function seeCounter() external view returns(uint256);

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IStructInfo {

      struct Sells {
        uint256 price;
        address nftBuyer;
        address nftSeller;
        address token;
        uint64 purchaseDate;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}