/**
 *Submitted for verification at polygonscan.com on 2022-02-03
*/

// File: contracts/rpsGame.sol

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;


interface IRadom{
    function rand(address _user) external view returns(uint256);
    function randrange(uint a, uint b,address _user) external view returns(uint);
}
interface IRandomNumberVRF{
    function getRandomNumber() external returns (bytes32 requestId);
    function getRandomRangeNumber(address _user, uint a, uint b) external returns(uint256);
}
interface IstakingNFT{
    function newPlay(uint _amount) external;
}

contract rpsGame  {
    /* TODO: rock papper and seassors
    * Function : play
    * Function : setPrice (For Tokens or blockchain currenci? )
    * VARIABLES:
    * * feeForNFTHolders(2%)[]
    * * feeForDevs (1.5)
    * * PoolTransfers (this)
    * * maxDeal (apuesta maxima)
    * Laderboard(Top 500?)
    */
    address owner; // Dueño del contrato, maximo rango de acceso (mover fondos de la pool)
    address admin; // Funciones para editar parametros de nivel medio (editar precios, fees)
    IRadom randomContract; //Direccion del contrato de numeros aleatoreos
    IRandomNumberVRF randomLinkContract; //Direccion de VRF random contract
    IstakingNFT stakingContrac;


    address NFTHolders; //Direccion del contrato que repartira la recompenza a los holders
    uint public feeForNFTHolders = 200; //% del fee para nftHolders (100 = 1%)

    address devWalletFees;  //Direccion del fee para los devs
    uint public feeForDevs = 150; //Fee para los el equipo de desarrollo

    uint totalFee = feeForNFTHolders + feeForDevs;
    uint maxDeal; //Puja maxima en un mismo juego 
    
    string[3] RPSop = ['rock','paper', 'scissors']; // 0 = Rock, 1 = paper, 2=scissors
    //for testin gass
    uint public totalWins;
    uint public totalLoses;
    mapping(address => uint[2]) winLosesPerUser;
    mapping(address => uint[2]) winLosesRache;

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    modifier forAdmins() {
        require(msg.sender == admin || msg.sender == owner);
        _;
    }
//EVENTS
    event Play(address,uint,bool,uint);// User, your hand, computer hand
    event C_setNFTHoldersAddress(address); // C_(Change), addres owner
    event C_setDevAddress(address);//
    event C_setFeeForNFTHolders(address);
    event C_setFeeForDevs(address);
    event C_setMaxDeal(address);

    constructor (
        address _owner,         
        address _devWallet,
        IRadom _randomContract, 
        IRandomNumberVRF _randomLinkContract,
        IstakingNFT _stakingAdd 
    ){
        owner = _owner;
        admin = _owner;
        //NFTHolders = _nftholders;
        devWalletFees = _devWallet;
        randomContract = _randomContract;
        randomLinkContract = _randomLinkContract;
        stakingContrac = _stakingAdd;// es la misma que _devWallet
        maxDeal = 1 ether;
    }

//FUNCTIONS FOR USERS

    //MSG.value = deal + totalFEE%
    function playUno( uint _value) public payable returns(bool results){
        uint fee = calculateFee(_value);
        require(msg.value <= (maxDeal + fee));
        require( (_value+fee) == msg.value);
        uint rand = getRandom(msg.sender,0,100);
        if(rand >= 50){
            payable(msg.sender).transfer(_value * 2);
            results = true;
        }else {
            results = false;
        }
        payable(NFTHolders).transfer(_value * feeForNFTHolders / 10000);
        payable(devWalletFees).transfer(_value * feeForDevs  / 10000);
        emit Play(msg.sender,_value,results,rand);
        //leaderBoard(result)

    }
//other functions
    function calculateFee(uint _value)public view returns(uint){
        uint txFee = _value * totalFee / 10000;
        return txFee;
    }
    function calculateValue(uint _value)public view returns(uint){
        uint totalValue = calculateFee(_value) + _value;
        return totalValue;
    }

//internal
    function getRandom(address _user, uint a, uint b) public view returns(uint){
        uint random = randomContract.randrange(a,b,_user);
        if (random == 0 ) {random = 1;}
        return random;
    }
    function getRandomRangeLink(address _user,uint a, uint b) public returns(uint){
        uint random = randomLinkContract.getRandomRangeNumber(_user,a,b);
        if (random == 0 ) {random = 1;}
        return random;
    }


//SETTERS
    
    //Cambiar direccion del contrato a donde va el 2% para los que posen nfts
    function setNFTHoldersAddress(address _newNFTHolders) internal onlyOwner{
        NFTHolders = _newNFTHolders;
        emit C_setNFTHoldersAddress(msg.sender);
    }
    //Cambiar la direccion donde va el 1.5%(devFee)
    function setDevAddress(address _newDevWalletFees) internal onlyOwner {
        devWalletFees = _newDevWalletFees;
        emit C_setDevAddress(msg.sender);
    }
    //Cambia el % de fee que es destinado a holders
    function setFeeForNFTHolders(uint _newFeeForNFTHolders) internal forAdmins{
        require((feeForDevs + _newFeeForNFTHolders) < 5000);
        feeForNFTHolders = _newFeeForNFTHolders;
        totalFee = feeForNFTHolders + feeForDevs;
        emit C_setFeeForNFTHolders(msg.sender);
    }
    //Cambia el % de fee que es destinado a Devs
    function setFeeForDevs(uint _newFeeForDevs) internal forAdmins{
        require((_newFeeForDevs+feeForNFTHolders) < 5000);
        feeForDevs = _newFeeForDevs;
        totalFee = feeForNFTHolders + feeForDevs;
        emit C_setFeeForDevs(msg.sender);
    }
    //Cambia el maximo disponible en una misma jugada.
    function setMaxDeal(uint _newMaxDeal) internal forAdmins{
        require(_newMaxDeal > ((address(this).balance)/10));
        maxDeal = _newMaxDeal;
        emit C_setMaxDeal(msg.sender);
    }

    //trasnfiere valor, usao para testeo
    function trasnferFounds()public payable returns(bool){
        require(msg.value > 10);
        return true;
    }

    function playdos( uint _value) public payable returns(bool results){
        uint fee = calculateFee(_value);
        require(msg.value <= (maxDeal + fee));
        require( (_value+fee) == msg.value);
        uint rand = getRandom(msg.sender,0,100);
        if(rand >= 50){
            payable(msg.sender).transfer(_value * 2);
            results = true;
            totalWins++;
            winLosesPerUser[msg.sender][1]++;
            if(winLosesRache[msg.sender][0] == 1){
                winLosesRache[msg.sender][1]++;
            }else{
                winLosesRache[msg.sender][0] = 1;
                winLosesRache[msg.sender][1] = 1;
            }
        }else {
            results = false;
            totalLoses++;
            winLosesPerUser[msg.sender][0]++;
            if(winLosesRache[msg.sender][0] == 0){
                winLosesRache[msg.sender][1]++;
            }else{
                delete winLosesRache[msg.sender][0];
                winLosesRache[msg.sender][1] = 1;
            }
        }
        payable(NFTHolders).transfer(_value * feeForNFTHolders / 10000);
        payable(devWalletFees).transfer(_value * feeForDevs  / 10000);
        emit Play(msg.sender,_value,results,rand);
        //leaderBoard(result)

    }

    function playTres( uint _value) public payable returns(bool results){

        uint fee = calculateFee(_value);
        require(msg.value <= (maxDeal + fee));
        require( (_value+fee) == msg.value);
        uint rand = getRandom(msg.sender,0,100);
        if(rand >= 50){
            payable(msg.sender).transfer(_value * 2);
            results = true;
            totalWins++;
            winLosesPerUser[msg.sender][1]++;
            if(winLosesRache[msg.sender][0] == 1){
                winLosesRache[msg.sender][1]++;
            }else{
                winLosesRache[msg.sender][0] = 1;
                winLosesRache[msg.sender][1] = 1;
            }
        }else {
            results = false;
            totalLoses++;
            winLosesPerUser[msg.sender][0]++;
            if(winLosesRache[msg.sender][0] == 0){
                winLosesRache[msg.sender][1]++;
            }else{
                delete winLosesRache[msg.sender][0];
                winLosesRache[msg.sender][1] = 1;
            }
        }
        payable(NFTHolders).transfer(_value * feeForNFTHolders / 10000);
        payable(devWalletFees).transfer(_value * feeForDevs  / 10000);
        emit Play(msg.sender,_value,results,rand);
        stakingContrac.newPlay(fee);
        //leaderBoard(result)

    }

    function playCuatro( uint _value) public payable returns(bool results){
        uint fee = calculateFee(_value);
        require(msg.value <= (maxDeal + fee));
        require( (_value+fee) == msg.value);
        uint rand = getRandomRangeLink(msg.sender,1,100);
        if(rand >= 50){
            payable(msg.sender).transfer(_value * 2);
            results = true;
            totalWins++;
            winLosesPerUser[msg.sender][1]++;            
        }else {
            results = false;
            totalLoses++;
            winLosesPerUser[msg.sender][0]++;            
        }
        payable(NFTHolders).transfer(_value * feeForNFTHolders / 10000);
        payable(devWalletFees).transfer(_value * feeForDevs  / 10000);
        stakingContrac.newPlay(fee);
        emit Play(msg.sender,_value,results,rand);
        //leaderBoard(result)

    }

}