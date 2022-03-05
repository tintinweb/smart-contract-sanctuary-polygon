// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";

interface A1UtilityNFTs {
  // function setToken(A0TheStupidestKidsNFTs _a0TheStupidestKidsNFTs, A2RewardLogic _a2RewardLogic) external;
  function mintUtility(uint256 _id) external;
  function burn(uint256 _id) external;

  function onlyMintNFTs(bool _bool) external;
  function setURI(uint _id, string memory _uri) external;
  function reveal() external;
  function setUtilityPerHour(uint amount) external;

  function uri(uint _id) external  view returns (string memory);
  function getallUtilityNFTs(address _address) external view returns(uint[] memory);
  // function upgradeUtilityNFTBalance() external;

  function _burnBatch(
      address from,
      uint256[] memory ids,
      uint256[] memory amounts
  ) external;

  function burnUNFT(address _address, uint[] memory _ids) external;
}
interface A0TheStupidestKidsNFTs {

  receive () external payable;

  // function setToken(A2RewardLogic _a2RewardLogic) external;
  function mint(address _to, uint256 _id) external payable;
  function mintLegendary(uint256 _id) external;
  function needToUpdateCost (uint256 _id) external;
  function payForNFTUtilities(address _user, uint _payment) external;
  function renewAttacks() external;
  function attach() external;

  function earnedRewardPointsCounter() external;
  function burnRewardPoints(address _address) external returns (uint);

  function onlyMintNFTs(bool _bool) external;
  function setURI(uint _id, string memory _uri) external;
  function activateSecondPresale () external;
  function ActivateClaimReward(bool _bool)external;
  function reveal() external;

  function uPoints(address _user) external view returns (uint);
  function getAllNFTs() external view returns(uint[] memory);
  function uri(uint _id) external view returns (string memory);
  function areAvailableNFTs () external view returns (bool[] memory );
  function getRewardPoints(address _address) external view returns (uint);
  function getFuturePoints(address _address)external view returns(uint);

  function _burnBatch(
      address from,
      uint256[] memory ids,
      uint256[] memory amounts
  ) external;
  
  function getTotalNFTs(address _address)external view returns(uint);
}
interface TSKToken {

  event SwapAndLiquifyEnabledUpdated(bool enabled);
  event SwapAndLiquify(
      uint256 tokensSwapped,
      uint256 ethReceived,
      uint256 tokensIntoLiqudity
  );

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function setNFTcontract() external;

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  function increaseAllowance(address spender, uint256 addedValue) external  returns (bool);

  function decreaseAllowance(address spender, uint256 subtractedValue) external  returns (bool);

  function isExcludedFromReward(address account) external view returns (bool);

  function totalFees() external view returns (uint256);

  function burnedTokens() external view returns (uint256);

  function give(uint256 tAmount) external;

  function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns(uint256);

  function tokenFromReflection(uint256 rAmount) external view returns(uint256);

  function excludeFromReward(address account) external;

  function includeInReward(address account) external;

  function excludeFromFee(address account) external;

  function includeInFee(address account) external;

  function setSwapAndLiquifyEnabled(bool _enabled) external;

  receive() external payable;

  function _reflectFee(uint256 rFee, uint256 tFee, uint256 burnedAmount) external;

  function _getValues(uint256 tAmount) external view returns (uint256, uint256, uint256, uint256, uint256, uint256);

  function _getTValues(uint256 tAmount) external view returns (uint256, uint256, uint256);

  function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) external pure returns (uint256, uint256, uint256);

  function _getRate() external view returns(uint256);

  function _getCurrentSupply() external view returns(uint256, uint256);

  function _userRewardArrayLiquidity(uint256 tLiquidity) external;

  function calculateTaxFee(uint256 _amount) external view returns (uint256);

  function calculateLiquidityFee(uint256 _amount) external view returns (uint256);

  function updateNumTokensBeforeLiquify(uint256 newAmount) external ;

  function removeAllFee() external;

  function _removeAllFee() external;

  function restoreAllFee() external;

  function _restoreAllFee() external;

  function isExcludedFromFee(address account) external view returns(bool);

  function _approve(address owner, address spender, uint256 amount) external;

  function _transfer( address from, address to, uint256 amount) external;

  function swapAndLiquify(uint256 contractTokenBalance) external;

  function swapTokensForEth(uint256 tokenAmount) external;

  function addLiquidity(uint256 tokenAmount, uint256 ethAmount) external;

  function _tokenTransfer(address sender, address recipient, uint256 amount,bool userRewardArrayFee) external;

  function _transferStandard(address sender, address recipient, uint256 tAmount) external;

  function _transferToExcluded(address sender, address recipient, uint256 tAmount) external;

  function _transferFromExcluded(address sender, address recipient, uint256 tAmount) external;

  function _transferBothExcluded(address sender, address recipient, uint256 tAmount) external;
}

contract A2RewardLogics is Ownable {
  // using SafeMath for uint256;
  // LOGICA DEL JUEGO CON REWARDS
    // Se llevara el conteo de los nfts de cada usuario para gestionar las recompensas aqui mismo y poder reclamarlas
    // COMO ESTRUCTURAR LOS DATOS DE LOS NFT P QUE SE TIENEN PARA PODER ENPAQUETARLOS DE 3 EN 3. Y TAMBIEN QUITAR LOS BOOL (TRUE) CUANDO LOS VENDE
    // añadir mas tiradas si tienes mas NFT P, para poder obtener mas NFT U. y asi mas rewards.

    // HOY
    // TODO  xxxAgregar puntos L y S(DAO)
    // TODO  xxxRANKING - Poner un contador para ver que presi se ha llevado mas rewards
    // TODO  xxxVariar los precios
    // TODO  xxxAgregar la forma de mintear un NFT legendario. Al azar. Calcular cuando podran, porque obtendran todos 1, y habra que reservar tokens para entonces// O hacer que sea escalado, de alguna manera
    // TODO  xxxRevisar que los nft legend, se quemen al coger reward
    // TODO  xxxLos U p SI se queman. Los NFT u SI se queman

    // TODO  % pool rewards. En las primeras 3 semanas se reparte el 20% de la pool. Pensamos recuperar al menos un 3%
    /* De ahi nos quedamos con el 83% y de aqui ya se regula de forma constante */

    // TODO  Eliminar semanalmente los NFT Us
    // TODO  Max minteo DIARIO 5-10 por dia
    // TODO  Funciones para MARKET -> pagarConPuntosSobrantesYTokens
    // TODO  Quitar o agragar nfts, si se mintea, vende, compra o quema. DESDE A1 usando DELEGATECALL
    // TODO  Limitar el ClaimReward a 1 vez, o modificar funcion
    // TODO  Metodo Canjear los newRewardPoints por token
    // TODO  Reveal?

    // Se le enviaran los tokens reward a este contrato, y medieante metodos get y send llamara al contrato del token para consultar cuantos tokens
    //  quedan y para trasferir las recompensas (el reflect ira aqui)
    // TODO DUDA es posible mintear un id x que no tenga uri?
    // TODO WARNING! Los precios de los legendarios en el array, son de puntos, lo de mas de Matic
    // TODO WARNING! Si no se tienen todos los NFTU, el folks se quema.
    // TODO WARNING! Si no se hace claimReward, no se queman los UNFT ni los UP.

    // CONTRATO A1
    // MINTEO, BALANCE, QUEMA DE NFTS //(precio, pre-ventas)?
    // Eliminar semalmente los NFTs
    // Puntuaciones
    // Max minteo DIARIO 5-10 por dia

    // CONTRATO A2
    // (precio, pre-ventas), owner, A1 -> A2 delegatecall
    // Logica del reward con delegatecall
    // Votos


    // QUE NO SE HARA en este SC
    // Token taxes
    // Aairdrop
    // Staking
    // Repartir los tokens con otro contrato
    // Market (tendra que llamar al A1 pa quemar los puntos)



  // STRAGE VARIABLES

    A1UtilityNFTs public a1UtilityNFTs;
    A0TheStupidestKidsNFTs public a0TheStupidestKidsNFTs;
    TSKToken public tskToken;
    
    // todo AGREGAR
    address public mod;

    uint256 public waitToAttack = 1 days;
    uint256 attacksAvailablePeriod;
    uint256 attacksAvailable;
    uint256 private rewardAtLeastPeriod = 2 days;
    uint256 private waitToReward;

    uint256 public rewardsToSplitBetweenClaimers = 3000;
    uint256 public rewardAverage = 6;

    uint256 public votesYes;
    uint256 public votesNo;
    uint256 public votesYesIncreasePlayers;
    uint256 public votesNoIncreasePlayers;
    
    // VOTES PERIODS
    uint256 private voteWaitPeriod = 7 days;
    mapping(address => uint) public waitToVote; 
    
    // MINTING PERIODS
    uint256 mintBeforePresaleStart = 1647738000; //  (GMT): Sunday, 20 March 2022 1:00:00
    uint256 public waitToMint = 6 hours;
    mapping(uint => uint) public mintAvailablePeriod; 

    // to save, nfts uri // Se le puede dar al num5 un uri si el 4 no tiene?
    mapping(uint => string) public tokenURI;
    // to check each NFTs supply
    mapping(uint => uint) public nftsSupply;

    // Mapping from address to token ID to balances
    // mapping(address => mapping(uint256 => uint256)) public _nftBalances;
    // para checkear si tiene todas las utilidades
    mapping(address => mapping(uint256 => uint256)) private _ownedNftUtilityBalances;
    // Para llevar un mapping de los tikckets de cada uno
    mapping(address => uint256) public _ownedFolks;
    
    // ESPERAR PARA RETIRAR TOKENS
    uint waitToWithdraw = 10 days;
    mapping(address => uint[2][] ) public userReward;
    
    mapping(uint256 => uint256) public rankingPoints;
    // reveal
    mapping(uint => string) public notRevealedUri;
    bool public revealed = false;
    
    bool public isReadySecondPresale;
    bool public electionsResult;
    bool public electionsResultIncreasePlayers;
    bool public openElections;

    bytes32 contractA0;

  constructor(/* address _mod */) {
    mod = 0x31c29d407fb5e2d1073137ADa2C48D4AFB06F8e8;
  }
  //////////////////
  function logicaOnlyContractA0() public view{
    bytes32 A0 = keccak256(abi.encodePacked(msg.sender));
    require(contractA0 == A0,"no");
  }
  modifier onlyContractA0{
    logicaOnlyContractA0() ;
    _;
  }
  modifier onlyMod() {
    require(mod == _msgSender(), "Ownable: caller is not the owner");
    _;
  }
  //////////////////

  function setToken(A1UtilityNFTs _a1UtilityNFTs, A0TheStupidestKidsNFTs _a0TheStupidestKidsNFTs, TSKToken _tskToken) public onlyOwner {
    // require(!tokenAvailable, "Token is already inserted.");
    a1UtilityNFTs = _a1UtilityNFTs;
    a0TheStupidestKidsNFTs = _a0TheStupidestKidsNFTs;
    tskToken = _tskToken;
    contractA0 = keccak256(abi.encodePacked(a0TheStupidestKidsNFTs));
    // tokenAvailable = true;
  }

  function earnedRewardPoints(address _address, uint[] memory _allNFTs) external onlyContractA0 returns(uint[] memory, uint[] memory) {

    // uint [] allNFTs = a0TheStupidestKidsNFTs.getAllNFTs(msg.sender);
    bool hasAllUtilityNFT = true;
    uint [] memory allNFTs= _allNFTs;
    uint[] memory allUtilityNFTs = a1UtilityNFTs.getallUtilityNFTs(_address);
    uint newRewardPoints;
    // Para despues quemar los lNFT
    // uint [] memory lNFTs;
    uint[] memory lNFTs = new uint[](40);
    // uint [] memory lNFTsNumber;
    // Sacar NFTs de A0
    if( allNFTs[0] > 0 && allNFTs[1] > 0 && allNFTs[2] > 0){
      newRewardPoints += 1;
      rankingPoints[0] += 1;
      if (allNFTs[3] > 0){
        // Quitar de A0
        lNFTs[3] +=1;
        // allNFTs[3] -= 1;
        newRewardPoints += 1;
        rankingPoints[0] += 1;
      }
      if(hasAllUtilityNFT){
        (bool hasAll, uint [] memory _allUtility, uint newRP) = earnednewUtilityRewardPoints(allUtilityNFTs, newRewardPoints);
        hasAllUtilityNFT = hasAll;
        allUtilityNFTs = _allUtility;
        newRewardPoints += newRP;
      }
    }
    if( allNFTs[4] > 0 && allNFTs[5] > 0 && allNFTs[6] > 0){
      newRewardPoints += 1;
      rankingPoints[1] += 1;
      if (allNFTs[7] > 0){
        lNFTs[7] +=1;
        newRewardPoints += 1;
        rankingPoints[1] += 1;
      }
      if(hasAllUtilityNFT){
        (bool hasAll, uint [] memory _allUtility, uint newRP) = earnednewUtilityRewardPoints(allUtilityNFTs, newRewardPoints);
        hasAllUtilityNFT = hasAll;
        allUtilityNFTs = _allUtility;
        newRewardPoints += newRP;
      }
    }
    if( allNFTs[8] > 0 && allNFTs[9] > 0 && allNFTs[10] > 0){
      newRewardPoints += 1;
      rankingPoints[2] += 1;
      if (allNFTs[11] > 0){
        lNFTs[11] +=1;
        newRewardPoints += 1;
        rankingPoints[2] += 1;
      }
      if(hasAllUtilityNFT){
        (bool hasAll, uint [] memory _allUtility, uint newRP) = earnednewUtilityRewardPoints(allUtilityNFTs, newRewardPoints);
        hasAllUtilityNFT = hasAll;
        allUtilityNFTs = _allUtility;
        newRewardPoints += newRP;
      }
    }
    if( allNFTs[12] > 0 && allNFTs[13] > 0 && allNFTs[14] > 0){
      newRewardPoints += 1;
      rankingPoints[3] += 1;
      if (allNFTs[15] > 0){
        lNFTs[15] +=1;
        newRewardPoints += 1;
        rankingPoints[3] += 1;
      }
      if(hasAllUtilityNFT){
        (bool hasAll, uint [] memory _allUtility, uint newRP) = earnednewUtilityRewardPoints(allUtilityNFTs, newRewardPoints);
        hasAllUtilityNFT = hasAll;
        allUtilityNFTs = _allUtility;
        newRewardPoints += newRP;
      }
    }
    if( allNFTs[16] > 0 && allNFTs[17] > 0 && allNFTs[18] > 0){
      newRewardPoints += 1;
      rankingPoints[4] += 1;
      if (allNFTs[19] > 0){
        lNFTs[19] +=1;
        newRewardPoints += 1;
        rankingPoints[4] += 1;
      }
      if(hasAllUtilityNFT){
        (bool hasAll, uint [] memory _allUtility, uint newRP) = earnednewUtilityRewardPoints(allUtilityNFTs, newRewardPoints);
        hasAllUtilityNFT = hasAll;
        allUtilityNFTs = _allUtility;
        newRewardPoints += newRP;
      }
    }
    if( allNFTs[20] > 0 && allNFTs[21] > 0 && allNFTs[22] > 0){
      newRewardPoints += 1;
      rankingPoints[5] += 1;
      if (allNFTs[23] > 0){
        lNFTs[23] +=1;
        newRewardPoints += 1;
        rankingPoints[5] += 1;
      }
      if(hasAllUtilityNFT){
        (bool hasAll, uint [] memory _allUtility, uint newRP) = earnednewUtilityRewardPoints(allUtilityNFTs, newRewardPoints);
        hasAllUtilityNFT = hasAll;
        allUtilityNFTs = _allUtility;
        newRewardPoints += newRP;
      }
    }
    if( allNFTs[24] > 0 && allNFTs[25] > 0 && allNFTs[26] > 0){
      newRewardPoints += 1;
      rankingPoints[6] += 1;
      if (allNFTs[27] > 0){
        lNFTs[27] +=1;
        newRewardPoints += 1;
        rankingPoints[6] += 1;
      }
      if(hasAllUtilityNFT){
        (bool hasAll, uint [] memory _allUtility, uint newRP) = earnednewUtilityRewardPoints(allUtilityNFTs, newRewardPoints);
        hasAllUtilityNFT = hasAll;
        allUtilityNFTs = _allUtility;
        newRewardPoints += newRP;
      }
    }
    if( allNFTs[28] > 0 && allNFTs[29] > 0 && allNFTs[30] > 0){
      newRewardPoints += 1;
      rankingPoints[7] += 1;
      if (allNFTs[31] > 0){
        lNFTs[31] +=1;
        newRewardPoints += 1;
        rankingPoints[7] += 1;
      }
      if(hasAllUtilityNFT){
        (bool hasAll, uint [] memory _allUtility, uint newRP) = earnednewUtilityRewardPoints(allUtilityNFTs, newRewardPoints);
        hasAllUtilityNFT = hasAll;
        allUtilityNFTs = _allUtility;
        newRewardPoints += newRP;
      }
    }
    if( allNFTs[32] > 0 && allNFTs[33] > 0 && allNFTs[34] > 0){
      newRewardPoints += 1;
      rankingPoints[8] += 1;
      if (allNFTs[35] > 0){
        lNFTs[35] +=1;
        newRewardPoints += 1;
        rankingPoints[8] += 1;
      }
      if(hasAllUtilityNFT){
        (bool hasAll, uint [] memory _allUtility, uint newRP) = earnednewUtilityRewardPoints(allUtilityNFTs, newRewardPoints);
        hasAllUtilityNFT = hasAll;
        allUtilityNFTs = _allUtility;
        newRewardPoints += newRP;
      }
    }
    if( allNFTs[36] > 0 && allNFTs[37] > 0 && allNFTs[38] > 0){
      newRewardPoints += 1;
      rankingPoints[9] += 1;
      if (allNFTs[39] > 0){
        lNFTs[39] +=1;
        newRewardPoints += 1;
        rankingPoints[9] += 1;
      }
      if(hasAllUtilityNFT){
        (bool hasAll, uint [] memory _allUtility, uint newRP) = earnednewUtilityRewardPoints(allUtilityNFTs, newRewardPoints);
        hasAllUtilityNFT = hasAll;
        allUtilityNFTs = _allUtility;
        newRewardPoints += newRP;
      }
      
    }
    // TODO REVISAR - https://www.tutorialspoint.com/solidity/solidity_arrays.htm
    uint[] memory _ids = new uint[](40);
    uint counter;
    for (uint256 i = 0; i < 40; i++) {
      _ids[i] = counter;
      counter++;
    }
    a1UtilityNFTs.burnUNFT(_address, _ids);
    
    // Wait to withdraw
    uint rewardClaimPeriod = waitToWithdraw + block.timestamp;
    userReward[_address].push([newRewardPoints, rewardClaimPeriod]); //userReward
    return (_ids, lNFTs);
  }
  function earnednewUtilityRewardPoints(uint[] memory _allUtilityNFTs, uint newRewardPoints) private pure returns(bool, uint[] memory, uint){
    // ALL UTILITIES?
    bool hasAll = true;
    uint [] memory allUtilityNFTs = _allUtilityNFTs;
    uint256 allUtilities;
    for (uint256 i = 0; i < 7; i++) {
      if(allUtilityNFTs[i] > 0){
        allUtilityNFTs[i] --;
        allUtilities ++;
      }
    }

    // TODO REVISAR
    if(allUtilities >= 7){
      newRewardPoints += 1;
      // folks
      if( allUtilityNFTs[7] > 0 && allUtilityNFTs[8] > 0 ){
        allUtilityNFTs[7] --;
        allUtilityNFTs[8] --;
        newRewardPoints += 1;
      }
    } else{
      hasAll = false;
    }
    return (hasAll, _allUtilityNFTs, newRewardPoints);
  }

  //// REVEAL
  // TODO a traves de otro contrato
  function setNotRevealedURI(uint _id, string memory _notRevealedURI) public onlyOwner {
    notRevealedUri[_id] = _notRevealedURI;
  }
  function reveal() public onlyOwner{
      revealed = true;
  }
  function isRevealed() public view returns(bool){
      return revealed;
  }

  // TOKENS PAYMENT FROM POOL // TODO Agregar period
  function changeRewardForTokens() external {
    (uint _rest, uint _posR) = calculateRest();
    
    uint _fine = 1 - (_rest / waitToWithdraw);
    uint _rewardAmount = userReward[msg.sender][_posR][0] *= _fine;
    userReward[msg.sender][_posR][0] = 0;
    uint _percentage = calculate();
    uint _amount = _rewardAmount * _percentage;
    tskToken.transfer(msg.sender, _amount);
  }
  function calculateRest() private view returns(uint, uint){
    uint[2][] memory _userRewardArray = userReward[msg.sender];
    uint _rest;
    uint _daySeconds = 86400;
    uint _contador;
    uint _posicionReward;
    for (uint256 i = 0; i < _userRewardArray.length; i++) {
      if(_userRewardArray[i][0] > 0 && _contador == 0){
        uint lockTime = _userRewardArray[i][1];
        if(lockTime > block.timestamp){
          uint daysToClaimFree = lockTime - block.timestamp;
          _rest = daysToClaimFree / _daySeconds; // dias que faltan
          _contador ++;
          _posicionReward = i;
        }
      }
    }
    return (_rest, _posicionReward);
  }
   
  function calculate() internal view returns(uint){
    // % cuantos tokens hay, cuanto % se repartira
    // 300 - 150
    uint _tokenBalance = tskToken.balanceOf(address(this));
    uint _tokenSupply = tskToken.totalSupply();

    // 300/500 0,6  150/500 0,3     20/500 0,04
    uint _percentageRemainingToken = _tokenBalance / _tokenSupply;
    // Si quedan mas tokens sera mas alto el plus
    // 1,666         3,333    25
    uint256 _per = (1 / _percentageRemainingToken);

    // TODO calcular cuanta gente reclamara cada semana para ajustar el genteQueREclamaRecompensas
    // uint rewardsToSplitBetweenClaimers = 3000;// 3000 porciones de todos los tokens con un plus
    // Por lo tanto si cada semana se comen un 30% del pastel, ya que calculamos que cada semana habra 1000 personas reclamando las recompensas
    uint split = tskToken.balanceOf(address(this)) / rewardsToSplitBetweenClaimers;
    uint _price = split / _per;
    // Dividido por la media del numero de recompensas
    // TODO Revisar _rewardAverage
    // uint rewardAverage = 6;
    uint _amount = _price / rewardAverage; 
    
    return _amount;
  }
  // GET para ver cuantos rewards y a cuanto tiempo falta de retirar // cuantos dias faltan para claim - a cuanto se quedaria ahora - cuanto seria de esperar todos los dias
  function getAllRewardCalculator() external view returns(uint [] memory, uint [] memory, uint [] memory){
    uint _percentage = calculate();
    uint[2][] memory _userRewardArray = userReward[msg.sender];
    uint [] memory _rest;
    uint _daySeconds = 86400;
    uint [] memory _rewardAmount;
    uint [] memory _rewardAmountRest;
    for (uint256 i = 0; i < _userRewardArray.length; i++) {
      if(_userRewardArray[i][0] > 0){
        uint lockTime = _userRewardArray[i][1];
        if(lockTime > block.timestamp){
          uint daysToClaimFree = lockTime - block.timestamp;
          _rest[i] = daysToClaimFree / _daySeconds; // dias que faltan
          
          uint _fine = 1 - (_rest[i] / waitToWithdraw);
          _rewardAmount[i] = _userRewardArray[i][0] * _percentage;
          _rewardAmountRest[i] = _userRewardArray[i][0] *= _percentage * _fine;
        }
      }
    }
    return (_rest, _rewardAmountRest, _rewardAmount);
  }
  
  // TODO definir mates
  /* function changePercentageTokens(uint _rewardsToSplitBetweenClaimers, uint _rewardAverage) external onlyOwner{
    rewardsToSplitBetweenClaimers = _rewardsToSplitBetweenClaimers;
    rewardAverage = _rewardAverage;
  } */
  function activateSecondPresale () external onlyMod {
    isReadySecondPresale = true;
  }  

  ////////////////
  // VOTES 2 TYPES//
  ////////////////
  function startElections () external onlyMod{
    openElections = true;
  }
  function resetElections () external onlyMod{
    electionsResult = false;
    electionsResultIncreasePlayers = false;
  }
  
  // GENERAL
  function votesGeneral(uint256 _vote) external {
    require(openElections, "Can't vote yet");
    require(waitToVote[msg.sender] < block.timestamp, "You already vote");
    waitToVote[msg.sender] = block.timestamp + voteWaitPeriod;
    
    uint256 _votes = a0TheStupidestKidsNFTs.getFuturePoints(msg.sender);
    if(_vote == 1){
      votesYes += _votes;
    }else{
      votesNo += _votes;
    }
  }
  function closeElections()external onlyMod{
    if(votesYes > votesNo){
      electionsResult = true;
    } else{
      electionsResult = false;
    }
    votesYes = 0;
    votesNo = 0;
    openElections = false;
  }
  function isYesInElections() external view returns(bool) {
    return electionsResult;
  }
  
  // INCREASE PLAYERS
  function voteToIncreasePlayers(uint256 _vote) external {
    require(openElections, "Can't vote yet");
    require(waitToVote[msg.sender] < block.timestamp, "You already vote");
    waitToVote[msg.sender] = block.timestamp + voteWaitPeriod;
    
    uint256 _votes = a0TheStupidestKidsNFTs.getFuturePoints(msg.sender);
    if(_vote == 1){
      votesYesIncreasePlayers += _votes;
    }else{
      votesNoIncreasePlayers += _votes;
    }
  }
  function closeElectionsToIncreasePlayers()external onlyMod{
    if(votesYesIncreasePlayers > votesNoIncreasePlayers){
      electionsResultIncreasePlayers = true;
    } else{
      electionsResultIncreasePlayers = false;
    }
    votesYes = 0;
    votesNo = 0;
    openElections = false;
  }
  function isAbleToAddPlayers() external view returns(bool) {
    return electionsResultIncreasePlayers;
  }
  /////////////
  // A0 complementario //
  ////////////////
  function requiresBeforeMint(uint _id) external onlyContractA0{
    require(40 > _id, "You can't mint with that id");
    require(_id != 3 && _id != 7 && _id != 11 && _id != 15 && _id != 19 && _id != 23 && _id != 27 && _id != 31 && _id != 35 && _id != 39 , "You can't mint with that id");
    
    if(nftsSupply[_id] >= 50){
      require(mintBeforePresaleStart < block.timestamp, "One more available in less than six hours (from 20 March 2022)");
      require(mintAvailablePeriod[_id] < block.timestamp, "One more available in less than six hours");
      // El id es el del NFT
      mintAvailablePeriod[_id] = block.timestamp + waitToMint;
    }
    if(_id > 15){
      require(isReadySecondPresale, "This NFTs can't be minted yet");
    } 
  }
  function areAvailableNFTs () external view returns (bool[] memory ){
    bool[] memory areAvailable;
    for (uint256 i = 0; i < 40; i++) {
      if(mintAvailablePeriod[i] < block.timestamp){
      areAvailable[i] = true;
      }
    }
    return areAvailable;
  }

  ////////////////
  // GETTERS //
  ////////////////

  function getRankingPoints() external returns(uint[] memory){
    uint[] memory ranking;
    for (uint256 i = 0; i < 10; i++) {
      rankingPoints[i] = ranking[i];
    }
    return ranking;
  }
  function getUserRewardPoints() public view returns (uint[2][] memory) {
    return userReward[msg.sender];
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