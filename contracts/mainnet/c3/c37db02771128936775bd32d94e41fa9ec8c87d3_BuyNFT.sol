/**
 *Submitted for verification at polygonscan.com on 2022-04-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
interface INftEmpresas{
    struct Empresa {
        uint256 id;
        string nombre;
        string pais; 
        string mercado; 
        string color; 
        string tipo; 
        string sector; 
        string icono;
        uint level;
    }
    function newNFT(address add, uint i) external returns (bool);
    function getEnabledNFTs() external view returns (Empresa [] memory);
    function getCapNFT(uint id) external view returns (uint);
    function getCountNFT(uint id) external view returns (uint);
}
interface ILiquidity {
    function getTokenPrice() external view returns(uint);
    function getToken0() external view returns(address);
    function getToken1() external view returns(address);
    function swapAndLiquify(uint256 amount) external;
}
interface IHamperBlock {
    function transfer(address _to, uint256 _amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function decimals() external pure returns (uint8);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
}
interface ICarterasDesbloqueadas {
    function setCartera(address ad,uint cartera) external;
    function getCartera(address ad) external view returns(uint);
}

contract BuyNFT {
    INftEmpresas empresa;
    ILiquidity public liquidity;
    ICarterasDesbloqueadas public unlocked_carteras;
    bool public enableSwapAndLiquify=false;
    uint public price_SB=2;
    uint public price_G=5;
    uint public minTokensToSwap;
    address private _token;
    address public devsAddress=0x6ce19c0edcD9E67d21110e2AEb2FAcAaEf17B103;
    mapping (address => bool) public permitedAddress;
    bool public paused;
    constructor() {
        permitedAddress[msg.sender]=true;
        paused=false;
    }
    modifier whenNotPaused() {
        require(paused == false);
        _;
    }
    modifier whenPermited() {
        require(permitedAddress[msg.sender],"Not permited");
        _;
    }
    function setPermitedAddress(address ad, bool permited) public whenPermited {
        permitedAddress[ad]=permited;
    }
    function setLiquidityAddress(address ad) public whenPermited {
        liquidity=ILiquidity(ad);
        _token=liquidity.getToken0();
    }
    function setEmpresasNFT(address ad) public whenPermited{
        empresa=INftEmpresas(ad);
    }
    function setCarterasDesbloquedas(address ad) public whenPermited{
        unlocked_carteras=ICarterasDesbloqueadas(ad);
    }
    function setSwapAndLiquify(bool value) public whenPermited {
        enableSwapAndLiquify=value;
    }
    function setPrice_SB(uint value) public whenPermited {
        price_SB=value;
    }
    function setPrice_G(uint value) public whenPermited {
        price_G=value;
    }
    function setMinTokensToSwap(uint value) public whenPermited {
        minTokensToSwap=value;
    }
    function setDevsAddress(address ad) public whenPermited {
        devsAddress=ad;
    }
    function pause() public whenPermited {
        paused=true;
    }
    function unpause() public whenPermited {
        paused=false;
    }
    function getToken() public view returns (address) {
        return _token;
    }
    function balanceOf(address ad) public view returns (uint){
        return IHamperBlock(_token).balanceOf(ad);
    }
    function getCartera(address ad) public view returns (uint){
        return unlocked_carteras.getCartera(ad);
    }
    //tipoNFT=0 es silver/bronze, tipoNFT=1 es gold
    function buyNFT(uint tipoNFT) public whenNotPaused {
        require(tipoNFT==0 || tipoNFT==1,"Invalid type of collection");
        require((tipoNFT==0 && getCartera(msg.sender)>3) || (tipoNFT==1 && getCartera(msg.sender)>4),"Cell doesn't unlock");
        uint tokens_needed=amountTokensForUSD(price_SB);
        if(tipoNFT==1){
            tokens_needed=amountTokensForUSD(price_G);
        }
        require(balanceOf(msg.sender) >= tokens_needed , "Insuficient Balance");
        IHamperBlock(_token).transferFrom(msg.sender,devsAddress,tokens_needed);
        sendNFT(getIdsNFT(tipoNFT));
        tryswap();
    }
    function tryswap() private{
        if(enableSwapAndLiquify){
            uint enough=IHamperBlock(_token).balanceOf(address(liquidity));
            if(enough>minTokensToSwap){
                liquidity.swapAndLiquify(minTokensToSwap);
            }
        }
    }
    function getIdsNFT(uint tipoNFT) public view returns (uint[] memory) {
        (uint[] memory result,uint count)=getIdsNFTCount(tipoNFT);
        uint[] memory fit_result = new uint[](count);
        for(uint i=0;i<count;i++){
            fit_result[i]=result[i];
        }
        return fit_result;
    }
    function getIdsNFTCount(uint tipoNFT) public view returns (uint[] memory, uint) {
        INftEmpresas.Empresa[] memory NFTs=getEnabledNFTs();
        uint[] memory result = new uint[](NFTs.length);
        uint count=0;
        for(uint i=0;i<NFTs.length;i++){
            uint id=NFTs[i].id;
            if(getCapNFT(id)>getCountNFT(id)){
                if(keccak256(abi.encodePacked(NFTs[i].color))==keccak256(abi.encodePacked("dorado"))){
                    if(tipoNFT==1){
                        result[count]=id;
                        count+=1;
                    }
                }else{
                    if(tipoNFT==0){
                        result[count]=id;
                        count+=1;
                    }
                }
            }
        }
        return (result,count);
    }
    function sendNFT(uint[] memory ids_NFT) private {
        require(ids_NFT.length>0, "No NFT available");
        empresa.newNFT(msg.sender, ids_NFT[_createRandomNum(ids_NFT.length,msg.sender)]);
    }
    function _createRandomNum(uint256 _mod,address ad) private view returns (uint256) {
        uint256 randomNum = uint256(keccak256(abi.encodePacked(block.timestamp, ad)));
        return randomNum % _mod; 
    }
    function amountTokensForUSD(uint usd) public view returns(uint){
        return usd*liquidity.getTokenPrice();
    }
    function getEnabledNFTs() public view returns(INftEmpresas.Empresa[] memory){
        return empresa.getEnabledNFTs();
    }
    function getCapNFT(uint id) public view returns(uint){
        return empresa.getCapNFT(id);
    }
    function getCountNFT(uint id) public view returns(uint){
        return empresa.getCountNFT(id);
    }
}