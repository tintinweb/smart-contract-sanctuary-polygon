/// SPDX-License-Identifier: BSD-3-Clause
/// SPDX-FileCopyrightText: © Florian "Fy" Gasquez <[email protected]> (0x110750F3C61E6Bd8A30c5BB812B063c75F0E3Ac6)
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./polymonInterfaces.sol";

/** @title PolymonSpeciesKittens. 
 */
contract PolymonSpeciesKittens is Ownable, AbstractPolymonSpecies  {
  string constant private _name  = 'Kitten';
  uint16 constant private  _id = 1;
  uint16 constant private _genomeSize = 8;
  uint public gen0Counter = 0;
  string public imageBaseURI;
  string[] public geneToString;
  string[][] public attributeToString;
  uint32[] private _genomesGen0;
  bool private _gen0Init;
  mapping(string => uint256) _typeStrToInt;

  /**
   * @notice set master contract (PolymonController) for onlyOwner modifier. 
   */
  function setMaster(address _master) external override onlyOwner {
    master = _master;
  }

  /**
   * @notice Name of the Polymon Species. 
   * @return string Name of the Polymon species.
   */
  function name() external override pure returns (string memory) {
    return _name;
  }

  /**
   * @notice Identifier of the Polymon Species. 
   * @return uint16 Identifier of the Polymon species.
   */
  function id() external override pure returns (uint16) {
    return _id;
  }

  /**
   * @notice Number of traits in the species genome. 
   * @return uint16 Number of traits in the species genome.
   */
  function genomeSize() external override pure returns (uint16) {
    return _genomeSize;
  }

  /**
   * @notice Increments the generation zero counter 
   */
  function incrementGen0() external override onlyMaster {
    gen0Counter++;
  }

  /**
   * @notice Gets the genome of the next generation zero Polymon for this species to be minted (minus genome species trait).
   * @return uint256 Possible Polymon genome/Token ID. 
   */
  function getNextGen0() external override view onlyMaster returns (uint256) {
    return _genomesGen0[gen0Counter];
  }

  /**
   * @notice Gets the number of remainging generation zero Polymon for this species.
   * @return uint256 Number of available generation zero Polymon.
   */
  function gen0Count() external override view onlyMaster returns (uint256) {
    return (_genomesGen0.length - gen0Counter > 0) ? _genomesGen0.length - gen0Counter : 0;
  }

  /**
   * @notice Check if there is any generation zero Polymon available.
   * @return bool True if there is at least one generation zero available.
   */
  function gen0Available() external override view onlyMaster returns (bool) {
    return _genomesGen0.length - gen0Counter > 0;
  }

  /**
   * @notice Gets basic information about this species.
   * @return SpeciesBaseData A struct containing basic informations (genome size, names of traits and genes, and the base of the image path).
   */
  function getSpeciesBase() external override view onlyMaster returns (SpeciesBaseData memory) {
    return SpeciesBaseData({
      genomeSize: _genomeSize,
      geneToString: geneToString,
      attributeToString: attributeToString,
      imageBasePath: imageBaseURI
    });
  }

  function getSpeciesBonusDamage(uint256 _p1, uint256 _p2) external override view onlyMaster returns (uint8 _q1, uint8 _d1) {
    _d1 = 1;
    _q1 = 1;
    uint16 i = 1;
    uint256 _p1Type = (_p1 % 10**(i + 1)) / 10**((i + 1) - 1);
    uint256 _p2Type = (_p2 % 10**(i + 1)) / 10**((i + 1) - 1);

    if (_p1Type == _typeStrToInt['Water'] && _p2Type == _typeStrToInt['Fire']) {
      _q1 = 1; // 1/2
      _d1 = 2;
    } else if (_p1Type == _typeStrToInt['Fire'] && _p2Type == _typeStrToInt['Water']) {
      _q1 = 2;
    } else if (_p1Type == _typeStrToInt['Water'] && _p2Type == _typeStrToInt['Nature']) {
      _q1 = 1; // 1/2
      _d1 = 2;
    } else if (_p1Type == _typeStrToInt['Nature'] && _p2Type == _typeStrToInt['Water']) {
      _q1 = 2;
    } else if (_p1Type == _typeStrToInt['Poison'] && _p2Type == _typeStrToInt['Fae']) {
      _q1 = 2;
    } else if (_p1Type == _typeStrToInt['Poison'] && _p2Type == _typeStrToInt['Neutral']) {
      _q1 = 1;
      _d1 = 2;
    } else if (_p1Type == _typeStrToInt['Fae'] && _p2Type == _typeStrToInt['Neutral']) {
      _q1 = 2;
    } else if (_p1Type == _typeStrToInt['Fae'] && _p2Type == _typeStrToInt['Air']) {
      _q1 = 1;
      _d1 = 2;
    } else if (_p1Type == _typeStrToInt['Air'] && _p2Type == _typeStrToInt['Electric']) {
      _q1 = 2;
    } else if (_p1Type == _typeStrToInt['Air'] && _p2Type == _typeStrToInt['Neutral']) {
      _q1 = 1;
      _d1 = 2;
    } else if (_p1Type == _typeStrToInt['Fire'] && _p2Type == _typeStrToInt['Nature']) {
      _q1 = 2;
    } else if (_p1Type == _typeStrToInt['Electric'] && _p2Type == _typeStrToInt['Water']) {
      _q1 = 2;
    } else if (_p1Type == _typeStrToInt['Electric'] && _p2Type == _typeStrToInt['Electric']) {
      _q1 = 1;
      _d1 = 2;  
    } else if (_p1Type == _typeStrToInt['Nature'] && _p2Type == _typeStrToInt['Fae']) {
      _q1 = 1;
      _d1 = 2;     
    } else if (_p1Type == _typeStrToInt['Neutral'] && _p2Type == _typeStrToInt['Water']) {
      _q1 = 1;
      _d1 = 2;  
    }
  }

  /**
   * @notice Mix genes of 2 polymons and gets a child based on block.timestamp (not random).
   * @param _firstParent Token ID / Genome of the first parent.
   * @param _secondParent Token ID / Genome of the second parent.
   * @return uint256 Genome / Token ID of a possible child.
   */
  function simpleDnaMix(uint8 _i, uint256 _firstParent, uint256 _secondParent) external override view onlyMaster returns (uint256) {
      uint256 newGenes = 0;
      uint256 rng = uint256(keccak256(abi.encodePacked(_i, _firstParent, _secondParent, block.timestamp)));
      for(uint16 i = 1; i <= _genomeSize; i++){
          if ((rng >> i) % 2 == 0) {
              newGenes = newGenes + (_firstParent % 10**i / 10**(i - 1)) * 10 ** (i - 1);
          } else {
              newGenes = newGenes + (_secondParent % 10**i / 10**(i - 1)) * 10 ** (i - 1);
          }
      }

      return newGenes;
  }

  function initGen0() public onlyOwner {
    require(!_gen0Init);
    _genomesGen0 = [32114450,40124210,44003264,22101520,12121242,41154631,41143651,40101230,30140131,33104620,3102550,4104213,30133261,41130521,21031550,43141204,24130604,23113561,40123631,33111203,34044550,34144452,23132524,34134200,34113421,22122400,23153132,22114044,44144554,22152464,31140440,20114400,31121571,20151413,31111673,43023262,21120231,21114202,42103521,24112451,32150273,21103250,3123240,22154562,31103643,33103230,31130603,34130074,43150561,20103604,32020553,23134273,34124214,40133240,30021272,23141623,41134114,24111660,33132452,42110241,42142142,40122102,41144224,40004564,40151520,20102433,24140442,41150262,22040554,44113164,41132201,30114544,24134454,41133620,41141241,22142624,30021510,44150253,143571,41153163,31120412,21020502,10112563,21041563,23152261,31003223,33103401,34142620,31040214,20123260,22134171,30142240,43102171,41152004,10100500,31104562,22130270,43143102,13141260,33121210,42123351,33054244,31150241,23111013,41130234,23111644,43142414,33132561,44124404,42023550,24012574,40000243,33150160,31014200,23122442,44111250,2140530,42031570,41101421,34133243,24144423,31101544,34022204,22004503,43113430,43124202,32023504,24103154,4050510,20132630,31153413,2151252,43120153,40134524,42154324,42140461,31132553,34131254,40150474,43102513,22110252,23130431,41133554,21112264,24131412,34151524,24130223,30104404,21121212,44152523,22141631,42143440,40134600,44034430,32120420,22121462,40102562,33124413,33100514,44144622,22100343,41104242,24111521,33120550,40141501,34152500,33131262,22144642,21141604,41133471,41131664,41044544,42100433,30122654,31110542,44102551,44101640,22104654,40112431,24122413,20132243,20130201,24010270,33122504,30153274,42021232,34124570,21024250,41124534,21100651,23100011,21151523,33134440,24120541,42102623,32143104,24100240,33052524,30141514,21153233,22150550,20101203,43111600,44110043,31143572,41151130,14111231,42131642,32131614,4102564,42111562,21140662,30102264,42103203,43101564,40144233,4101503,20112444,43140033,10153210,22133414,24124222,22101264,40154652,30141223,43121431,23114210,13131243,32131201,21111420,42111401,33103674,20114551,14142631,42154272,34134631,33152640,40144512,13150542,12143271,20043240,23104641,34141602,44101263,40050211,1130253,23140253,43002540,43100252,22131100,32101441,34142534,41131252,31143260,34123633,42122471,31140564,32054210,153530,22011532,32144241,34010130,24121504,31124243,33132223,31113234,41140100,3134204,43121503,41120572,32131453,41121260,4114232,44100654,40100422,33152033,1124502,41113210,43140271,32101212,24152202,23131220,22114263,30142672,44114673,22154470,44130401,32142513,32112634,24114513,31034271,23121572,32124260,11124553,43110510,20152673,44154530,32130264,41134672,43134211,22131574,42140222,31150533,34102522,4121244,44151672,40113560,43131540,20122234,41120644,24100613,31104634,31142273,20133570,30023551,132514,30054231,44132660,41151444,43103261,32110613,40122424,42141253,42154411,33143412,34143222,40140540,3132251,32122572,10124254,30132420,40134173,44142470,44123524,23120564,21142514,43150412,30102573,21032254,42114540,40100534,31100463,34154221,21141530,34051202,40131651,20012250,41140413,32120534,30113220,30140660,41110223,41100543,20122141,23144221,30110402,22102661,40112242,41012564,2134564,10152512,22112523,31141232,44131024,21110624,14133522,34030552,44141451,20131522,33134002,31142404,40130263,40022554,42110334,43132532,23111432,23110274,30131632,32142421,24011004,34102653,21023570,41101214,43154514,31144342,30103511,42141424,1111504,30120244,34111272,21143401,40123450,4140262,20140502,31122613,34014233,44104220,40152271,41141574,33133610,24141213,31134222,44122540,41144060,43010240,44114501,20003533,21153041,34052220,42121630,32100351,20142531,23013540,31152150,31124151,44121133,21124600,4151200,30143364,30153653,43103334,22130532,42124561,24152610,40132541,24101601,43152250,40104570,21054241,42112511,30010512,44133231,42112224,20103231,32114502,24131241,42053541,43111221,40122070,34121562,41100630,33102242,41123612,23154520,30151572,20140470,22032230,24153440,14120502,134543,44120563,34153664,34140230,40110662,42101452,34103362,34110560,21154443,22151622,41102032,21153474,32134663,34101510,21152412,40152410,34154563,23052270,44043513,32152531,42100672,44020244,24133551,22104200,32111533,24101473,1123513,41053572,20141261,44153212,21113152,31134501,40154503,43151242,41142634,33140474,24140524,33151513,20153611,42102270,33150453,42123220,21101552,30111561,20021253,24114462,30042543,44141560,23122653,23150503,20134262,32114031,33104271,12132530,40123573,33003564,44021442,4151542,40151432,32041564,32130500,32133571,30121440,2122222,21132461,30132502,34114604,23151531,1142261,40120551,42110020,42153660,22103451,34112410,31112251,41124463,33143254,23133672,43112403,44150504,23104053,32040242,32150512,24123621,21143242,43122160,31102220,31154510,24154060,44021523,24144614,23130340,42151573,42130450,24124340,21014530,30134234,20042570,44014212,4113520,31021241,22000522,30151610,20144411,33054503,43122521,31131560,23131404,33124601,10121524,32100140,31100254,34102474,112270,33140202,21134240,22140234,43152611,21111243,32144574,22123473,32103244,40121542,20102371,44131502,21104430,20113642,43033243,22104511,32024251,32123563,40133034,24142254,43104531,12130511,21110433,20121471,22123522,32153520,21134512,32101670,23000541,41121653,21152540,34142443,13104554,44150620,32142262,33113211,34134323,42151261,21102563,20041542,41142550,41103402,23114504,30043271,30150200,22111230,32113403,30151251,23153200,24122271,33031563,34140644,24011242,11102272,40113623,22114620,13122220,43104663,43134553,32102560,44113552,24133663,31013541,22132040,24123432,30150634,41143464,42114432,42131531,43141522,34041270,2150521,34122263,13134230,33024522,34100203,22122612,32112200,40103224,23124332,14144251,30123212,40001532,10131264,44052440,41130012,31002212,22102502,20150571,104431,42142564,34153250,33114252,33121454,34152244,31131213,22103272,44100512,40143211,30124521,40013254,30112550,31050500,42153422,30130671,40131513,22154231,40133353,40053260,40141443,43014231,32143370,21111371,32034520,20114364,13152400,33154551,24102420,42152174,24030212,23122510,31134464,40140254,32140332,32113640,41113533,43143563,22134224,33032231,23101251,21132232,42134243,33101633,22124530,3110531,42120213,32153202,42052213,33111574,22152253,42040510,40132622,41132373,32123324,30144553,34143561,34122511,20100523,32151240,33154662,44112602,42114614,34102231,21143553,33142570,34121650,23030203,44050521,30124673,44113611,41021273,11113551,33112512,40144661,41034532,24104572,22141054,40141272,24103500,30110233,22133543,30152463,32103552,24101232,33153263,43131463,21113631,34150414,42133262,23024551,24051231,40044520,43123322,44130242,44102442,31112422,14131653,34110651,43133501,41142212,33130624,43101112,40130614,21140210,14123223,24104261,23112671,43033560,32154333,42104504,22132211,24154651,42152552,30101001,20110514,30114201,23134634,21122223,21150204,23003202,23141410,22100404,43011542,32033272,22123634,41114261,41114474,31122202,21002542,40120232,33101521,34134542,20152220,40153544,43130200,42134130,42104251,142523,31154472,2110214,40042511,20101662,40103413,43103650,23123252,23100530,22100221,43114572,33140541,13111511,34011221,22133330,30152232,44120270,21112572,21120520,21122501,34001244,31011274,22013571,22140573,2141563,20102554,42120601,21144561,42133604,33120221,24150632,103553,20144132,43114244,20154214,33104543,34100571,21124274,20124563,30133533,43123233,33133341,31123530,21002233,23112460,40122253,33113523,41102641,33142603,34132212,1150552,21100273,30122401,21102670,20151564,41154200,23143574,40114150,22052262,30120030,42102044,30131270,41151551,20113503,23103243,23001500,32121621,33111331,20143650,30143500,32124444,41153221,22132472,34141573,154462,20154350,30104250,1150220,23103512,43114651,12151514,32141550,33121123,32110471,43041554,24132573,23102214,41123541,41101500,22121513,22123201,23153421,31101261,43041220,22000253,30114012,34013214,24151570,34133430,20131460,30113454,24150211,40030553,23142543,41123204,32010220,23102622,40142613,41154522,20031511,24133274,33130572,20153552,40102674,114223,43144500,42140643,33020254,21012201,3144451,44124241,22122544,13150231,21134621,33114530,24121642,22150663,41031503,20144603,23144552,44142221,24124164,42143532,20143434,33113162,24153534,31110270,43154223,42113100,44143200,24120103,43144343,21154554,23013221,44140531,32034401,12111213,44111413,20022513,44153433,42130544,40022241,31133363,42151654,44111534,21043532,24120460,22041244,20111224,32154254,30153441,1151231,44002273,24112530,24142562,41152243,43112554,13124261,20113321,40121161,42132503,44112233,31034514,34133514,42144670,23153654,20100212,32104223,20101541,30130554,31114160,23144464,22141202,31114611,10143252,44154264,21142333,43121614,23110602,24130510,33151234,22143223,20121550,44102204,14122554,2101602,43153570,42110553,24151461,43132274,41050534,43153603,24113253,42144523,33123542,34120252,24024263,43130122,40111470,34110224,24144270,42113574,41102454,23142272,23121263,3124571,22110501,43100470,42121274,31133442,31153504,40110111,42153234,31152621,14100274,20010520,42133510,34130462,43123474,23150222,41151312,30120513,10120273,31153632,22143560,21103524,24150354,34020261,31121224,41040231];
    attributeToString.push(["Bat Wings","Butterfly Wings","Cat Tail","Fluff","Long Tail"]);
    attributeToString.push(["Kitty","AquaEar","Cat","Hair","Antenna"]);
    attributeToString.push(["True","False"]);
    attributeToString.push(["Cat","Unhappy Teeths","Grin","Cat Open","Yelling","Open Teeths"]);
    attributeToString.push(["Poke","Sleepy","Greedy","Angry","Estonished"]);
    attributeToString.push(["Holy","Dear Horns","Swirls","Small Horns","Unicorn","Nothing","Polyglasses"]);
    attributeToString.push(["Water","Poison","Fae","Air","Fire","Electric","Nature","Neutral"]);
    attributeToString.push(["0ac3ff","d70aff","0affb6","ff320a","ffd70a"]);
    geneToString = ["Back","Front","Shiny","Mouth","Eye","Special","Type","AccentColor"];
    
    for (uint16 i = 0; i < attributeToString[6].length; i++) {
      _typeStrToInt[attributeToString[6][i]] = i;
    }
  }

  /**
   * @notice Check if two parents are compatible.
   * @param _firstParent First parent data (AbstractPolymonMaster.PolymonData).
   * @param _secondParent Second parent data (AbstractPolymonMaster.PolymonData).
   * @return bool True if they can breed.
   */
  function validMatingPair(
    AbstractPolymonMaster.PolymonData memory _firstParent, AbstractPolymonMaster.PolymonData memory _secondParent
  ) external override view onlyMaster returns (bool) {
    // Polymon cannot breed with itself (even if it really wants to).
    if (_firstParent.tokenId == _secondParent.tokenId) {
        return false;
    }

    // Polymon cannot breed with its parents.
    if (_secondParent.secondParent == _firstParent.tokenId || _secondParent.firstParent == _firstParent.tokenId) {
        return false;
    }
    if (_firstParent.secondParent == _secondParent.tokenId || _firstParent.firstParent == _secondParent.tokenId) {
        return false;
    }

    if ((_secondParent.secondParent == 0 && _secondParent.firstParent == 0) || (_firstParent.secondParent == 0 && _firstParent.firstParent == 0)) {
        return true;
    }
    
    // Polymon can't breed with full/half sibblings, they're not Lanisters.
    if (_secondParent.secondParent == _firstParent.secondParent || _secondParent.secondParent == _firstParent.firstParent) {
        return false;
    }
    if (_firstParent.secondParent == _secondParent.secondParent || _firstParent.secondParent == _secondParent.firstParent) {
        return false;
    }

    return true;
  }

  constructor() {
    imageBaseURI = "http://dev.godofinkscape.com:6042/images/";
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

/// SPDX-License-Identifier: BSD-3-Clause
/// SPDX-FileCopyrightText: © Florian "Fy" Gasquez <[email protected]> (0x110750F3C61E6Bd8A30c5BB812B063c75F0E3Ac6)
pragma solidity ^0.8.9;


abstract contract  AbstractPolymonMaster {
  struct PolymonData {
    uint256 tokenId;
    uint16 species;
    uint256 birthTime;
    uint256 firstParent;
    uint256 secondParent;
    uint16 generation;
    uint16 couplings;
  }
  event Birth(address owner, uint256 tokenId, uint256 parentTwoID, uint256 parentOneID);
  event Fight(address owner, uint256 tokenId, uint256 opponent, uint256 winner, uint256 fightIndex);
}

/** @title Slave contract of PolymonMaster or PolymonController. */
abstract contract AbstractPolySlave {
  address internal master;
  modifier onlyMaster {
    require(msg.sender == master && address(master) != address(0), "403");
    _;
  }
  function setMaster(address) virtual external; 
}

/** @dev Check implementation for documentation */
abstract contract AbstractPolymonState is AbstractPolySlave {
  enum PolymonStateData {
    Null,
    Sleeping,
    Eating,
    Playing,
    Bathing,
    Renting
  }
  struct PolymonRental {
    uint256 price;
    uint256 expires;
    uint256 count;
    uint256 tokenId;
  }
  struct DamageReceived {
    uint256 p1;
    uint256 hp1;
    uint256 p2;
    uint256 hp2;
    uint256 damageP1;
    uint256 damageP2;
  }
  struct FightLogResult {
    uint256 p1;
    uint256 p2;
    uint256 winner;
    uint256 created;
    DamageReceived[] damages;
  }
  struct FightLog {
    uint256 p1;
    uint256 p2;
    uint256 winner;
    uint256 created;
    uint256 fightIndex;
  }
  struct PolymonAttrs {
    uint256 hpMax;
    uint256 hpCurrent;
    uint256 exp;
    uint256 wins;
    uint256 losses;
  }
  struct PolymonPublicStateData {
    uint256 hpMax;
    uint256 hpCurrent;
    uint256 epxTotal;
    uint256 expLevel;
    uint256 expNextLevel;
    uint16 level;
    string name;
    bool isEgg;
    uint256 timeToHatch;
    uint16 cleanliness;
    uint16 satiety;
    uint16 happiness;
    uint16 sleepiness;
    uint16 attackPower;
    uint16 maxAttackPower;
    uint256 currentStateExpires;
    uint256 wins;
    uint256 losses;
    uint256 fights;
    PolymonStateData currentState;
  }
  function initState(uint256, uint256) virtual external;
  function updateState(uint256, PolymonStateData) virtual external;
  function getPolymonState(uint256) virtual external view returns (PolymonPublicStateData memory);
  function rename(uint256, string memory) virtual external;
  function fight(uint256, uint256, uint8, uint8, uint8, uint8) external virtual returns (FightLog memory _fightLog);
  function getFightLogs(uint256, uint256) external virtual view returns (FightLogResult memory);
  function getRentingState(uint256) view virtual external returns (PolymonRental memory);
  function updateRentingState(uint256, uint256) virtual external;
  function getRentals(uint16) virtual external view returns (PolymonRental[] memory);
}

/** @dev Check implementations for documentation */
abstract contract  AbstractPolymonSpecies is AbstractPolySlave {
    struct SpeciesBaseData {
      uint256 genomeSize;
      string[] geneToString;
      string[][] attributeToString;
      string imageBasePath;
    }

    function name() virtual external pure returns (string memory);
    function id() virtual external pure returns (uint16);
    function gen0Count() virtual external view returns (uint256);
    function getNextGen0() virtual external view returns (uint256);
    function incrementGen0() virtual external;
    function gen0Available() virtual external view returns (bool);
    function genomeSize() virtual external view returns (uint16);
    function simpleDnaMix(uint8, uint256, uint256) virtual external view returns (uint256);
    function getSpeciesBase() virtual external view returns (SpeciesBaseData memory);
    function validMatingPair(AbstractPolymonMaster.PolymonData memory, AbstractPolymonMaster.PolymonData memory) virtual external view returns (bool);
    function getSpeciesBonusDamage(uint256, uint256) virtual external view returns (uint8, uint8);
}

/** @dev Check implementation for documentation */
abstract contract AbstractPolymonMeta is AbstractPolySlave {
  function tokenURI(
    uint256,
    address,
    AbstractPolymonSpecies.SpeciesBaseData memory,
    AbstractPolymonState.PolymonPublicStateData memory,
    AbstractPolymonMaster.PolymonData memory
  ) virtual external pure returns (string memory);
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