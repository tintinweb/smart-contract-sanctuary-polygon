// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./Ownable.sol";
import "./IOriginLand.sol";
import "./IERC20.sol";
import "./IUniSwapPair.sol";
import "./ITokenVipPresaleContract.sol";

contract OriginLandsSaleMarketplaceV2 is Ownable {

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////                                                                                    ////////////////
    ////////////////     .88b  d88.   d888888b   d8b   db   d88888b   d8888b.   d888888b    .d88b.      ////////////////
    ////////////////     88'YbdP`88     `88'     888o  88   88'       88  `8D     `88'     .8P  Y8.     ////////////////
    ////////////////     88  88  88      88      88V8o 88   88ooooo   88oobY'      88      88    88     ////////////////
    ////////////////     88  88  88      88      88 V8o88   88~~~~~   88`8b        88      88    88     ////////////////
    ////////////////     88  88  88     .88.     88  V888   88.       88 `88.     .88.     `8b  d8'     ////////////////
    ////////////////     YP  YP  YP   Y888888P   VP   V8P   Y88888P   88   YD   Y888888P    `Y88P'      ////////////////
    ////////////////                                                                                    ////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////////////
    ////////////////////////////\     EVENTS      //////////////////////
    ////////////////////////////////////////////////////////////////////

    event BuySuccess(address buyer,uint256 price, uint256 tokenId);
    
    ////////////////////////////////////////////////////////////////////
    //////////////////////////\     VARIABLES      /////////////////////
    ////////////////////////////////////////////////////////////////////

    bool private saleActivated;

    address private originLandsContractAddress;

    address private holderWallet;

    // for static matic price
    bool private isMaticPriceStatic;
    uint256 private staticMaticPrice;

    // access for oracle to change base price
    address private basePriceChangerOracle;
    
    /**
     * the adderss which holds the payment tokens after the nft is bought from a wallet
     */
    address private tokenOwnerWallet;

    /**
     * the base price of every block inside the map (by wei)
     */
    uint private basePrice;

    //for lands that have special prices
    SpecialPriceFactorLand[] specialFactorLands;

    /**
     * the district factorr for each district. (*1,000,000,000)
     */
    mapping(uint256 => uint) private districtFactorPerGwei;


    //for calculating the price of MATIC token
    address private uniswapMaticUsdPair;
    address private WMATICAddress;


    // for auto adding the NFT wallets to token VIP presale contract
    bool private autoAddWalletToTokenVipPresale;
    address private tokenVipPresaleContractAddress;

    constructor(){
        tokenOwnerWallet = msg.sender;
        saleActivated = true;

        //uniswap Factory for Polygon mainnet
        uniswapMaticUsdPair = 0x604229c960e5CACF2aaEAc8Be68Ac07BA9dF81c3;
        //setting WMATIC token address
        WMATICAddress = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

        isMaticPriceStatic = false;
    }

    ////////////////////////////////////////////////////////////////////
    ///////////////////////////\     STRUCTS      //////////////////////
    ////////////////////////////////////////////////////////////////////

    struct SpecialPriceFactorLand{
        uint256 id;
        uint256 factorPerGwei;
    }

    ////////////////////////////////////////////////////////////////////
    //////////////////////////\     MODIFIERS      /////////////////////
    ////////////////////////////////////////////////////////////////////
    
    modifier whenSaleIsActive {
        require(saleActivated, "the sale is not activated");
        _;
    }
    
    modifier isBasePriceOracleOrOwner {
        require(msg.sender == basePriceChangerOracle || msg.sender == owner(), "the sale is not activated");
        _;
    }

    ////////////////////////////////////////////////////////////////////
    ///////////////////////\     Main Functions      ///////////////////
    ////////////////////////////////////////////////////////////////////


    

    /**
     * the buy function which is payable
     * user will call this and should send exact value with the lands price
     */
    function buy(uint256 _id) external payable whenSaleIsActive {
        // e.g. the buyer wants 100 tokens, needs to send 500 wei
        require(isListed(_id), 'the canBuy is false');
        uint256 price= priceOf(_id);
        require(msg.value >= price, 'Need to send exact amount of currency');
        require(msg.sender != IOriginLand(originLandsContractAddress).ownerOf(_id), 'already the owner');


        //returning back the additional value to user
        payable(msg.sender).transfer(msg.value - price);
        // send all Ether to owner
        // Owner can receive Ether since the address of owner is payable
        payable(tokenOwnerWallet).transfer(price);

        /*
         * sends the requested amount of tokens
         * from this contract address
         * to the buyer
         */
        IOriginLand(originLandsContractAddress).transferFrom(holderWallet, msg.sender, _id);

        //adding the wallet to VIP token presale address
        ITokenVipPresaleContract(tokenVipPresaleContractAddress).addVipWallet(msg.sender);

        //emit the result of buy
        emit BuySuccess(msg.sender, price, _id);
    }

    
    receive()external payable{}
    
    function transferAllMatic() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    function transferMatic(uint256 _amount, address _to) public onlyOwner {
        require(_amount<=address(this).balance, "Not enough balance");
        payable(_to).transfer(_amount);
    }
    function transferCustomToken(address _tokenAddress, uint256 _amount, address _to) public onlyOwner{

        require(IERC20(_tokenAddress).balanceOf(address(this))>=_amount, "Not enough balance");

        IERC20(_tokenAddress).transfer(_to, _amount);
    }


    ////////////////////////////////////////////////////////////////////
    /////////////////////////\     INTERNALS      //////////////////////
    ////////////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////////////
    //////////////////////////\     SETTEERS      //////////////////////
    ////////////////////////////////////////////////////////////////////

    function setOriginLandsContractAddress(address _originLandsContractAddress) public onlyOwner {
        originLandsContractAddress = _originLandsContractAddress;
    }

    function setHolderWallet(address _holderWallet) public onlyOwner {
        holderWallet = _holderWallet;
    }

    function setTokenOwnerWallet(address _tokenOwnerWallet) public onlyOwner {
        tokenOwnerWallet = _tokenOwnerWallet;
    }

    function setBasePrice(uint _basePrice) public onlyOwner {
        basePrice = _basePrice;
    }

    function setDistrictFactorPerGwei(uint256 _district, uint _factor) public onlyOwner {
        districtFactorPerGwei[_district] = _factor;
    }

    function setSaleActivated(bool _saleActivated) public onlyOwner {
        saleActivated = _saleActivated;
    }

    function setIsMaticPriceStatic(bool _isMaticPriceStatic) public onlyOwner {
        isMaticPriceStatic = _isMaticPriceStatic;
    }
    
    function setStaticMaticPrice(uint256 _staticMaticPrice) public onlyOwner {
        staticMaticPrice = _staticMaticPrice;
    }

    function setAutoAddWalletToTokenVipPresale(bool _enabled) public onlyOwner {
        autoAddWalletToTokenVipPresale = _enabled;
    }

    function setTokenVipPresaleContract(address _address) public onlyOwner {
        tokenVipPresaleContractAddress = _address;
    }

    function setPriceChangerOracle(address _address) public onlyOwner {
        basePriceChangerOracle = _address;
    }

    function setSpecialPriceFactorland(uint256 _id, uint256 _factorPerGwei) public onlyOwner {

        
        //search in special factor prices
        for(uint i=0;i<specialFactorLands.length;i++){
            if(specialFactorLands[i].id == _id){
                specialFactorLands[i].factorPerGwei =_factorPerGwei;
                return;
            }
        }

        specialFactorLands.push(SpecialPriceFactorLand(_id, _factorPerGwei));
    }

    ////////////////////////////////////////////////////////////////////
    //////////////////////////\     GETTEERS      //////////////////////
    ////////////////////////////////////////////////////////////////////


    function getMaticPrice() public view returns (uint256) {
        if(isMaticPriceStatic)
            return staticMaticPrice;


        (uint112 reserve0, uint112 reserve1, ) = IUniSwapPair(
            uniswapMaticUsdPair
        ).getReserves();

        uint256 token0Decimals = IERC20(
            IUniSwapPair(uniswapMaticUsdPair).token0()
        ).decimals();
        uint256 token1Decimals = IERC20(
            IUniSwapPair(uniswapMaticUsdPair).token1()
        ).decimals();

        uint256 token0Amount = reserve0;
        uint256 token1Amount = reserve1;

        if (token0Decimals < 18 && token0Decimals != 0)
            token0Amount = token0Amount * (10**(18 - token0Decimals));
        if (token1Decimals < 18 && token1Decimals != 0)
            token1Amount = token1Amount * (10**(18 - token1Decimals));

        uint256 price = 0;
        if (IUniSwapPair(uniswapMaticUsdPair).token0() == WMATICAddress)
            price = (token1Amount * (10**18)) / token0Amount;
        else price = (token0Amount * (10**18)) / token1Amount;

        return price;
    }


    function getOriginLandsContractAddress() public view returns (address) {
        return originLandsContractAddress;
    }

    function getHolderWallet() public view returns (address) {
        return holderWallet;
    }

    function getListedLands() public view returns (IOriginLand.LandInfo[] memory){
        uint256 count = IOriginLand(originLandsContractAddress).balanceOf(holderWallet);
        IOriginLand.LandInfo[] memory lands = new IOriginLand.LandInfo[](count);
        for(uint i=0;i<count;i++){
            lands[i] = IOriginLand(originLandsContractAddress).getLand(IOriginLand(originLandsContractAddress).tokenOfOwnerByIndex(holderWallet, i));
        }

        return lands;
    }

    function isListed (uint256 _id) public view returns (bool) {
        IOriginLand.LandInfo[] memory listedLands = getListedLands();
        for(uint i=0;i<listedLands.length;i++){
            if(listedLands[i].tokenId == _id){
                return true;
            }
        }
        return false;
    }
    
    function getTokenOwnerWallet() public view returns (address) {
        return tokenOwnerWallet;
    }

    function getBasePrice() public view returns (uint) {
        return basePrice;
    }

    
    /**
     * gets the _districtFactorPerGwei of a _districtId
     * if the district does not exists in the mapping, 
     * the function returns 1000000 by default (100%)
     */
    function districtFactorPerGweiValue(uint _districtId) public view virtual returns(uint) {
        if(districtFactorPerGwei[_districtId]==0)
            return 1_000_000_000;
        return districtFactorPerGwei[_districtId];
    }




    /**
     * calculates the price of the land and returns
     */
    function priceOf(uint256 _tokenId) public view virtual returns(uint256) {
        require(isListed(_tokenId), "Wrong tokenId");

        IOriginLand.LandInfo memory landInfo= IOriginLand(originLandsContractAddress).getLand(_tokenId);

        uint256 price = (((basePrice * 10**18) / getMaticPrice()) * landInfo.blocksCount * districtFactorPerGweiValue(landInfo.district) / 1_000_000_000 );

        //search in special factor prices
        for(uint i=0;i<specialFactorLands.length;i++){
            if(specialFactorLands[i].id == landInfo.tokenId){
                price = price * specialFactorLands[i].factorPerGwei / 1_000_000_000;
                break;
            }
        }

        return price;
    }

    function getSaleActivated() public view returns (bool) {
        return saleActivated;
    }

    function getSpecialFactorLands() public view returns (SpecialPriceFactorLand[] memory){
        return specialFactorLands;
    }

    function getIsMaticStatic() public view returns (bool){
        return isMaticPriceStatic;
    }
    
    function getStaticMaticPrice() public view returns (uint256){
        return staticMaticPrice;
    }

    
    function isAutoAddWalletToTokenVipPresale() public view returns(bool) {
        return autoAddWalletToTokenVipPresale;
    }

    function getTokenVipPresaleContractAddress() public view returns(address) {
        return tokenVipPresaleContractAddress;
    }

    function getPricechangerOracle()public view returns(address) {
        return basePriceChangerOracle;
    }


}