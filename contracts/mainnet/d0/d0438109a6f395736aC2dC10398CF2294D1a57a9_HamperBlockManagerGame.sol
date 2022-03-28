/**
 *Submitted for verification at polygonscan.com on 2022-03-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
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
    function getOwnerNfts(address _owner) external view returns (Empresa [] memory);
}
contract HamperBlockManagerGame {
    INftEmpresas public empresa;
    ILiquidity public liquidity;
    ICarterasDesbloqueadas public unlocked_carteras;
    struct datos_casilla {
        uint id;
        string nombre;
        string class;
        string tipo;
        string color;
        string icon;
        string instructions;
        uint price;
        bool home;
        bool bloqueada;
    }
    bool public enableSwapAndLiquify=false;
    uint public sumLVLNFTS=10;
    uint public minTokensToSwap;
    event UnlockCell(string, int, address);
    event ChangeCell(string, uint);
    uint[] public ids_gold_NFT;
    uint[] public ids_silver_NFT;
    uint[] public ids_bronze_NFT;
    mapping(address => uint) public usuario_casilla_;
    mapping(uint => datos_casilla) private datos_casilla_;
    mapping (address => bool) public permitedAddress;
    address private _token;
    address public rewardPoolAddress;
    address public owner;
    bool public paused;
    datos_casilla [] private alldata;
    constructor() {
        owner=msg.sender;
        paused=false;
        permitedAddress[owner]=true;
        SetDatosCasilla(39,"Cartera 22","property","trading","dark-blue","","",10,false,false);
        SetDatosCasilla(38,"MINERIA","fee income-tax","","","","Paga 10%",20,false,false);
        SetDatosCasilla(37,"Cartera 21","property","trading","dark-blue","","",20,true,false);
        SetDatosCasilla(36,"Suerte","chance","","","suerte","CARTA",0,false,false);
        SetDatosCasilla(35,"BONUS","railroad","","","bonus","CARTA",0,false,false);
        SetDatosCasilla(34,"Cartera 20","property","growth","green","","",35,false,false);
        SetDatosCasilla(33,"BLOCKCHAIN","community-chest","","","cubos","CARTA",8,false,false);
        SetDatosCasilla(32,"Cartera 19","property","growth","green","","",30,true,false);
        SetDatosCasilla(31,"Cartera 18","property","growth","green","","",35,false,false);
        SetDatosCasilla(30,"ESPECIAL","bonus2","","","","",0,false,false);
        SetDatosCasilla(29,"Cartera 17","property","inmobiliario","yellow","","",35,false,false);
        SetDatosCasilla(28,"MINERIA","fee income-tax","","","","Paga 10%",20,false,false);
        SetDatosCasilla(27,"Cartera 16","property","inmobiliario","yellow","","",30,true,false);
        SetDatosCasilla(26,"Cartera 15","property","inmobiliario","yellow","","",35,false,false);
        SetDatosCasilla(25,"BONUS","railroad","","","bonus","CARTA",0,false,false);
        SetDatosCasilla(24,"Cartera 14","property","criptomonedas","red","","",35,false,false);
        SetDatosCasilla(23,"Cartera 13","property","criptomonedas","red","","",30,true,false);
        SetDatosCasilla(22,"Suerte","chance","","","suerte","CARTA",0,false,false);
        SetDatosCasilla(21,"Cartera 12","property","criptomonedas","red","","",35,false,false);
        SetDatosCasilla(20,"ESPECIAL","bonus2","","","","",0,false,false);
        SetDatosCasilla(19,"Cartera 11","property","dividendos","orange","","",35,false,false);
        SetDatosCasilla(18,"Cartera 10","property","dividendos","orange","","",30,true,false);
        SetDatosCasilla(17,"BLOCKCHAIN","community-chest","","","cubos","CARTA",8,false,false);
        SetDatosCasilla(16,"Cartera 9","property","dividendos","orange","","",100,false,false);
        SetDatosCasilla(15,"BONUS","railroad","","","bonus","CARTA",0,false,false);
        SetDatosCasilla(14,"Cartera 8","property","staking","purple","","",75,false,false);
        SetDatosCasilla(13,"Cartera 7","property","staking","purple","","",50,true,false);
        SetDatosCasilla(12,"MINERIA","fee income-tax","","","","Paga 10%",20,false,false);
        SetDatosCasilla(11,"Cartera 6","property","staking","purple","","",35,false,false);
        SetDatosCasilla(10,"ESPECIAL","bonus2","","","","",0,false,false);
        SetDatosCasilla(9,"Cartera 5","property","indexados","light-blue","","",30,false,false);
        SetDatosCasilla(8,"Cartera 4","property","indexados","light-blue","","",25,false,false);
        SetDatosCasilla(7,"Suerte","chance","","","suerte","CARTA",0,false,false);
        SetDatosCasilla(6,"Cartera 3","property","indexados","light-blue","","",20,false,false);
        SetDatosCasilla(5,"BONUS","railroad","","","bonus","CARTA",0,false,false);
        SetDatosCasilla(4,"MINERIA","fee income-tax","","","","Paga 10%",20,false,false);
        SetDatosCasilla(3,"Cartera 2","property","estrategia","dark-purple","","",10,false,false);
        SetDatosCasilla(2,"BLOCKCHAIN","community-chest","","","cubos","CARTA",8,false,false);
        SetDatosCasilla(1,"Cartera 1","property","estrategia","dark-purple","","",5,true,false);
    }
    modifier whenNotPaused() {
        require(paused == false);
        _;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    modifier whenPermited() {
        require(permitedAddress[msg.sender],"Not permited");
        _;
    }
    function setEmpresasNFT(address ad) public whenPermited{
        empresa=INftEmpresas(ad);
    }
    function setCarterasDesbloquedas(address ad) public whenPermited{
        unlocked_carteras=ICarterasDesbloqueadas(ad);
    }
    function setGoldNfts(uint[] memory arr) public whenPermited {
        ids_gold_NFT=arr;
    }
    function setSilverNfts(uint[] memory arr) public whenPermited {
        ids_silver_NFT=arr;
    }
    function setBronzeNfts(uint[] memory arr) public whenPermited {
        ids_bronze_NFT=arr;
    }
    function setLiquidityAddress(address ad) public onlyOwner {
        liquidity=ILiquidity(ad);
        _token=liquidity.getToken0();
    }
    // Establece si alguien tiene permiso o no para usar determinadas funciones
    function setPermitedAddress(address ad, bool permited) public onlyOwner {
        permitedAddress[ad]=permited;
    }
    function setSwapAndLiquify(bool value) public onlyOwner {
        enableSwapAndLiquify=value;
    }
    function setSumLVLNFTS(uint value) public onlyOwner {
        sumLVLNFTS=value;
    }
    function setMinTokensToSwap(uint value) public onlyOwner {
        minTokensToSwap=value;
    }
    function setRewardPoolAddress(address ad) public onlyOwner {
        rewardPoolAddress=ad;
    }
    // Pausa algunas funciones del contrato
    function pause() public onlyOwner {
        paused=true;
    }
    // Restablece algunas funciones pausadas del contrato
    function unpause() public onlyOwner {
        paused=false;
    }
    // Establecer los datos de una casilla
    function SetDatosCasilla(uint id,string memory nombre,string memory class,string memory tipo,string memory color,string memory icon,string memory instructions,uint price,bool home,bool bloqueada) public whenPermited{
        datos_casilla memory casilla = datos_casilla(id,nombre,class,tipo,color,icon,instructions,price,home,bloqueada);
        datos_casilla_[id]=casilla;
        insertIntoAllData(casilla);
        emit ChangeCell(nombre, price);
    }
    // Añade o modifica los datos de una casilla
    function insertIntoAllData(datos_casilla memory casilla) internal{
        bool exist=false;
        for(uint i=0;i<alldata.length;i++){
            if(alldata[i].id==casilla.id){
                alldata[i]=casilla;
                exist=true;
                break;
            }
        }
        if(!exist){alldata.push(casilla);}
    }
    // Obtiene los datos de una casilla
    function GetDatosCasilla(uint id) public view returns (datos_casilla memory){
        return datos_casilla_[id];
    }
    // Obtiene todos los datos de las casilla
    function GetAllDatosCasilla() public view returns (datos_casilla [] memory){
        return alldata;
    }
    // Obtiene el token que se está usando en el contrato
    function getToken() public view returns (address) {
        return _token;
    }
    // Obtiene el balance de tokens por dirección
    function balanceOf(address ad) public view returns (uint){
        return IHamperBlock(_token).balanceOf(ad);
    }
    // Con esta funcion el usuario paga para desbloquear una tarjeta
    function unlockCell(uint idCasilla) public whenNotPaused {
        require(idCasilla<=39, "Invalid Cell");
        require(idCasilla == usuario_casilla_[msg.sender]+1, "Cell is unlocked :)");
        int tokens_tarjeta = getTokensTarjeta(idCasilla);
        require(int(balanceOf(msg.sender)) > tokens_tarjeta , "Insuficient Balance");
        if(tokens_tarjeta<=0){
            uint abs=uint(-1*tokens_tarjeta);
            IHamperBlock(_token).transferFrom(rewardPoolAddress,msg.sender, abs);
        }else{
            IHamperBlock(_token).transferFrom(msg.sender,address(this), uint(tokens_tarjeta));
        }
        usuario_casilla_[msg.sender]=idCasilla;
        setCartera(idCasilla);
        sendNFT(idCasilla);
        tryswap();
        emit UnlockCell(datos_casilla_[idCasilla].nombre, tokens_tarjeta, msg.sender);
    }
    function tryswap() private{
        if(enableSwapAndLiquify){
            uint enough=IHamperBlock(_token).balanceOf(address(liquidity));
            if(enough>minTokensToSwap){
                liquidity.swapAndLiquify(minTokensToSwap);
            }
        }
    }
    function setCartera(uint id) private {
        uint idCartera=0;
        if(id>=39){idCartera=22;}
        else if(id>=37){idCartera=21;}
        else if(id>=34){idCartera=20;}
        else if(id>=32){idCartera=19;}
        else if(id>=31){idCartera=18;}
        else if(id>=29){idCartera=17;}
        else if(id>=27){idCartera=16;}
        else if(id>=26){idCartera=15;}
        else if(id>=24){idCartera=14;}
        else if(id>=23){idCartera=13;}
        else if(id>=21){idCartera=12;}
        else if(id>=19){idCartera=11;}
        else if(id>=18){idCartera=10;}
        else if(id>=16){idCartera=9;}
        else if(id>=14){idCartera=8;}
        else if(id>=13){idCartera=7;}
        else if(id>=11){idCartera=6;}
        else if(id>=9){idCartera=5;}
        else if(id>=8){idCartera=4;}
        else if(id>=6){idCartera=3;}
        else if(id>=3){idCartera=2;}
        else if(id>=1){idCartera=1;}
        unlocked_carteras.setCartera(msg.sender,idCartera);
    }
    function sendNFT(uint id) private {
        if(id==10 || id==20 || id==30){
            empresa.newNFT(msg.sender, ids_gold_NFT[_createRandomNum(ids_gold_NFT.length)]);
        }
        if(id==5 || id==15 || id==25 || id==35){
            uint dado=_createRandomNum(100);
            if(dado>60){
                empresa.newNFT(msg.sender, ids_silver_NFT[_createRandomNum(ids_silver_NFT.length)]);
            }else{
                empresa.newNFT(msg.sender, ids_bronze_NFT[_createRandomNum(ids_bronze_NFT.length)]);
            }
        }
    }
    function getTokensTarjeta(uint id) private view returns(int){
        int tokens=int(liquidity.getTokenPrice()/2);
        uint tirada=_createRandomNum(100);
        if(id==2 || id==17 || id==33){
            if(tirada>70){tokens=0;}
            else if(tirada>40){tokens=-1*tokens;}
            else if(tirada>10){tokens=-2*tokens;}
            else{tokens=-3*tokens;}
        }
        if(id==4 || id==38 || id==28 || id==12){tokens=int(150+(tirada/2))*tokens/100;}
        if(id==7 || id==22 || id==36){
            if(tirada==0){tokens=-100*tokens;}
            else if(tirada>60){tokens=-4*tokens;}
            else{tokens=-2*tokens;}
            if(getSumaLVLNFTS()>=sumLVLNFTS){
                tokens=tokens*2;
            }
        }
        return tokens;
    }
    function getSumaLVLNFTS() private view returns(uint){
        uint n_nfts=empresa.getOwnerNfts(msg.sender).length;
        uint count=0;
        for(uint i=0;i<n_nfts;i++){
            count+=empresa.getOwnerNfts(msg.sender)[i].level;
        }
        return count;
    }
    // Última cartera del jugador
    function getCartera(address ad) public view returns (uint){
        return unlocked_carteras.getCartera(ad);
    }
    // Última casilla del jugador
    function lastCellByAddress(address ad) public view returns (uint){
        return usuario_casilla_[ad];
    }
    // Última casilla del jugador
    function myLastCell() public view returns (uint){
        return usuario_casilla_[msg.sender];
    }
    // Desbloquea la siguiente casilla
    function unlockNextCell() public whenNotPaused {
        unlockCell(usuario_casilla_[msg.sender]+1);
    }
    // Asignación de un número aleatorio
    function _createRandomNum(uint256 _mod) internal view returns (uint256) {
        uint256 randomNum = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender)));
        return randomNum % _mod; 
    }
    function amountTokensForUSD(uint usd) public view returns(uint){
        return usd*liquidity.getTokenPrice();
    }
}