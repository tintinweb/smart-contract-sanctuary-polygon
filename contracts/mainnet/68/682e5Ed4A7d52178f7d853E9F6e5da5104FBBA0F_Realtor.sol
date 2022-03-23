// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "./Handlers.sol";
import "./Land.sol";
import "./Eggs.sol";
import "./Corn.sol";
import "./FarmStaker.sol";

contract Realtor is Handlers {
  FarmStaker staker;
  Land land;
  Eggs eggs;
  Corn corn;

  uint256 public maxFarmsPerLand = 3;
  uint256 public deposit = 30 ether;
  uint256 public inactivityPeriod = 3 days;
  bool paused;

  struct RentPaid {
    uint128 timestamp;
    uint120 amount;
    uint8 isEggs;
  }

  struct Farm {
    bool isOwner;
    uint64 landId;
    uint8 farmId;
  }

  struct LandStatus {
    uint64 landId;
    address owner;
    bool isOnMarket;
    uint8 farmsAvailable;  
    uint64 rentPercentage;
    address[] tenants;
  }

  struct FarmStatus {
    address tenant;
    uint256 lasAction;
    uint256 rent;
    bool isInactive;
  }

  mapping(uint256=>uint256) public rentPercentages;
  mapping(uint256=>mapping(uint256=>uint256)) public rentPerFarm;
  mapping(uint256=>bool) public isOnMarket;
  mapping(uint256=>mapping(uint256=>uint256)) public deposits;
  mapping(uint256=>mapping(uint256=>uint256)) public lastAction;
  mapping(uint256=>mapping(uint256=>address)) public tenants;
  mapping(uint256=>mapping(uint256=>RentPaid[])) public paidRents;
  mapping(address=>Farm[]) public farmsPerAddress;
  mapping(address=>Farm[]) public evictions;

  constructor(address _staker, address _land, address _eggs, address _corn) {
    staker = FarmStaker(_staker);
    land = Land(_land);
    eggs = Eggs(_eggs);
    corn = Corn(_corn);
  }

  function allFarmsOnLand(uint256 landId) public view returns (FarmStatus[] memory) {
    FarmStatus[] memory farms = new FarmStatus[](maxFarmsPerLand);
    for (uint256 i = 0; i < farms.length; i++) {
      farms[i] = FarmStatus(tenants[landId][i], lastAction[landId][i], rentPerFarm[landId][i], isInactive(landId, i));
    }
    return farms;
  }

  function allMarketFarms() public view returns (LandStatus[] memory) {
    uint256 totalLands = land.totalSupply();

    LandStatus[] memory lands = new LandStatus[](totalLands);

    for (uint256 i = 0; i < totalLands; i++) {
      bool market = isOnMarket[i+1];
      uint8 count = 0;
      if (market) {
        for (uint256 j = 0; j < maxFarmsPerLand; j++) {
          if (tenants[i+1][j] == address(0)) {
            count++;
          }
        }
      }

      address[] memory landTenants = new address[](maxFarmsPerLand);
      for(uint256 j = 0; j < maxFarmsPerLand; j++) {
        landTenants[j] = tenants[i+1][j];
      }

      lands[i] = LandStatus(uint64(i+1), land.ownerOf(i+1), market, count, uint64(rentPercentages[i+1]), landTenants);
    }

    return lands;
  }

  function isInactive(uint256 landId, uint256 farmId) public view returns (bool) {
    return (block.timestamp - lastAction[landId][farmId]) >= inactivityPeriod;
  }

  function getFarms(address account) public view returns (Farm[] memory) {
    return farmsPerAddress[account];
  }

  function getEvictions(address account) public view returns (Farm[] memory) {
    return evictions[account];
  }

  function setRent(uint256 landId, uint256 rentPercentage) public {
    require(!paused, "Contract paused");
    require(land.ownerOf(landId) == msg.sender, "You must own that land");
    require(rentPercentage <= 10000, "Invalid percentage");
    rentPercentages[landId] = rentPercentage;
    isOnMarket[landId] = true;
  }

  function takeOffMarket(uint256 landId) public {
    require(!paused, "Contract paused");
    require(land.ownerOf(landId) == msg.sender, "You must own that land");
    for (uint256 i = 0; i < maxFarmsPerLand; i++) {
      require(tenants[landId][i] == address(0) || tenants[landId][i] == msg.sender, "Already occupied. You must evict everyone before changing rent");
    }
    isOnMarket[landId] = false;
  }

  function occupyAsOwner(uint256 landId, uint256 farmId) public {
    require(!paused, "Contract paused");
    require(land.ownerOf(landId) == msg.sender, "You must own that land");
    require(farmId < maxFarmsPerLand, "Unavailable farm");
    require(tenants[landId][farmId] == address(0), "Already occupied");
    tenants[landId][farmId] = msg.sender;
    farmsPerAddress[msg.sender].push(Farm(true, uint64(landId), uint8(farmId)));
    rentPerFarm[landId][farmId] = 10000;
  }

  function enterRent(uint256 landId, uint256 farmId) public {
    require(!paused, "Contract paused");
    require(land.ownerOf(landId) != msg.sender, "You must not own that land");
    require(tenants[landId][farmId] == address(0), "Already occupied");
    require(isOnMarket[landId], "Must be available");
    require(farmId < maxFarmsPerLand, "Unavailable farm");
    eggs.transferFrom(msg.sender, address(this), deposit);
    deposits[landId][farmId] = deposit;
    lastAction[landId][farmId] = block.timestamp;
    tenants[landId][farmId] = msg.sender;
    farmsPerAddress[msg.sender].push(Farm(false, uint64(landId), uint8(farmId)));
    rentPerFarm[landId][farmId] = rentPercentages[landId];
  }

  function leaveFarm(uint256 landId, uint256 farmId) public {
    require(!paused, "Contract paused");
    require(tenants[landId][farmId] == msg.sender, "You must be using that farm");
    require(staker.countAllAssetsOnFarm(msg.sender, landId, farmId) == 0, "Farm must be empty");
    eggs.transfer(msg.sender, deposits[landId][farmId]);

    deposits[landId][farmId] = 0;
    tenants[landId][farmId] = address(0);
    
    Farm[] storage farms = farmsPerAddress[msg.sender];
    for (uint256 i = 0; i < farms.length; i++) {
      if (farms[i].landId == uint64(landId) && farms[i].farmId == uint8(farmId)) {
        farms[i] = farms[farms.length - 1];
        farms.pop();
        break;
      }
    }
  }

  function evict(uint256 landId, uint256 farmId) public {
    require(!paused, "Contract paused");
    require(land.ownerOf(landId) == msg.sender, "You must own that land");
    address tenant = tenants[landId][farmId];
    require(tenant != address(0), "Not occupied");
    require(isInactive(landId, farmId), "Must be inactive");

    Farm[] storage farms = farmsPerAddress[tenant];
    for (uint256 i = 0; i < farms.length; i++) {
      if (farms[i].landId == uint64(landId) && farms[i].farmId == uint8(farmId)) {
        farms[i] = farms[farms.length - 1];
        farms.pop();
        break;
      }
    }

    eggs.transfer(msg.sender, deposits[landId][farmId]);
    deposits[landId][farmId] = 0;
    tenants[landId][farmId] = address(0);
    evictions[tenant].push(Farm(false, uint64(landId), uint8(farmId)));
  }

  function clearEviction(uint256 landId, uint256 farmId) public {
    Farm[] storage farms = evictions[msg.sender];
    require(staker.countAllAssetsOnFarm(msg.sender, landId, farmId) == 0, "Farm must be empty");
    for (uint256 i = 0; i < farms.length; i++) {
      if (farms[i].landId == uint64(landId) && farms[i].farmId == uint8(farmId)) {
        farms[i] = farms[farms.length - 1];
        farms.pop();
        return;
      }
    }
    revert();
  }

  function payRent(address account, uint256 landId, uint256 farmId, address asset, uint256 amount) public isHandler returns (uint256) {
    require(tenants[landId][farmId] == account, "You must be a tenant of that");
    address landlord = land.ownerOf(landId);
    if (account == landlord) {
      return 0;
    }

    uint256 rent = rentPerFarm[landId][farmId] * amount / 10000;
    bool isEggs = asset == address(eggs);
    if (isEggs) {
      eggs.transferFrom(msg.sender, landlord, rent);
    } else if (asset == address(corn)) {
      corn.mint(landlord, rent);
    }

    paidRents[landId][farmId].push(RentPaid(uint128(block.timestamp), uint120(rent), isEggs ? 1 : 0));
    lastAction[landId][farmId] = block.timestamp;

    return rent;
  }

  function setDeposit(uint256 _deposit) public onlyOwner {
    deposit = _deposit;
  }

  function setMaxFarmsPerLand(uint256 _m) public onlyOwner {
    maxFarmsPerLand = _m;
  }

  function setInactivityPeriod(uint256 _p) public onlyOwner {
    inactivityPeriod = _p;
  }

  function setPause(bool _p) public onlyOwner {
    paused = _p;
  }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "./PolyBuildings.sol";
import "./FarmStaker.sol";
import "./FoxHen.sol";
import "./FarmCrops.sol";
import "./PolyFarmer.sol";
import "./FarmEnergy.sol";
import "./Realtor.sol";
import "./HenHouseS2.sol";
import "./FoxDenS2.sol";

contract StakerValidator is Ownable {
  FarmStaker staker;
  Realtor realtor;
  PolyBuildings buildings;
  FoxHen foxHen;
  FarmCrops crops;
  PolyFarmer farmer;
  FarmEnergy energy;
  HenHouseS2 henHouse;
  FoxDenS2 foxDen;

  uint256[] foxesPerLevel = [0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5];
  uint256[] hensPerLevel = [0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5];
  uint256 public timeoutPeriod = 24 hours;

  constructor(address _staker, address _realtor, address _foxHen, address _buildings, address _crops, address _farmer, address _energy, address _henHouse, address _foxDen) {
    staker = FarmStaker(_staker);
    realtor = Realtor(_realtor);
    foxHen = FoxHen(_foxHen);
    buildings = PolyBuildings(_buildings);
    crops = FarmCrops(_crops);
    farmer = PolyFarmer(_farmer);
    energy = FarmEnergy(_energy);
    henHouse = HenHouseS2(_henHouse);
    foxDen = FoxDenS2(_foxDen);
    farmer = PolyFarmer(_farmer);
  }

  function countFoxHenOfType(address account, uint256 landId, uint256 farmId, bool isFox) internal view returns (uint256) {
    return isFox ? staker.foxCount(account, landId, farmId) : staker.henCount(account, landId, farmId);
  }

  function isValid(address asset, address account, uint256 landId, uint256 farmId, uint256 tokenId) public view returns (bool) {
    require(realtor.tenants(landId, farmId) == account, "You must be adminitrating that farm");

    if (asset == address(farmer)) {
      uint256 level = staker.getBuildingLevel(account, landId, farmId, uint256(BuildingTypes.HOUSE));
      uint256 currentCount = staker.farmerCount(account, landId, farmId);
      uint256 max = energy.farmersPerLevel(level);
      require(currentCount < max, "Building at max. capacity");
      return true;
    }

    if (asset == address(foxHen)) {
      bool isFox = foxHen.isFox(tokenId);
      uint256 level = staker.getBuildingLevel(account, landId, farmId, uint256(isFox ? BuildingTypes.FOXDEN : BuildingTypes.HENHOUSE));
      uint256 currentCount = countFoxHenOfType(account, landId, farmId, isFox);
      uint256 max = isFox ? (level + 1) / 2 : (level == 0 ? 1 : 3 * level);
      require(currentCount < max, 'Building at max. capacity');
      return true;
    }

    return staker.isAllowed(asset);
  }

  function canUnstake(address asset, address account, uint256 landId, uint256 farmId, uint256 tokenId) public view returns (bool) {
    if (asset == address(buildings)) {
      uint256 buildingType = tokenId / 10;
      if (buildingType == uint256(BuildingTypes.HENHOUSE)) {
        require(staker.henCount(account, landId, farmId) == 0, "You have hens staked");
      } else if (buildingType == uint256(BuildingTypes.FOXDEN)) {
        require(staker.foxCount(account, landId, farmId) == 0, "You have foxes staked");
      } else if (buildingType == uint256(BuildingTypes.HOUSE)) {
        require(staker.farmerCount(account, landId, farmId) == 0, "You have farmers staked");
      } else if (buildingType == uint256(BuildingTypes.CROPS) || buildingType == uint256(BuildingTypes.WELL) || buildingType == uint256(BuildingTypes.SILO)) {
        uint256 level = tokenId % 10 + 1;
        for (uint256 i = 0; i < level; i++) {
          (, uint8 status,) = crops.plotStatus(account, landId, farmId, i);
          require(status == 0, "You have a crop growing");
        }
      }
      return true;
    } else if (asset == address(foxHen)) {
      bool isFox = foxHen.isFox(tokenId);
      if (isFox) {
        bytes32 key = staker.getKey(asset, account, landId, farmId, tokenId);
        (uint256 timestamp,,) = foxDen.foxesData(key);
        require(block.timestamp - timestamp > timeoutPeriod, "You need to wait since your last use");
      } else {
        uint256 timestamp = henHouse.lastClaim(tokenId);
        require(block.timestamp - timestamp > timeoutPeriod, "You need to wait since your last use");
      }
    } else if (asset == address(farmer)) {
      uint256 timestamp = energy.rechargeTimestamp(account, uint64(landId), uint8(farmId));
      require(block.timestamp - timestamp > timeoutPeriod, "You need to wait since your last use");
    }
    return staker.isAllowed(asset);
  }

  function setTimeoutPeriod(uint256 _p) public onlyOwner {
    timeoutPeriod = _p;
  }

  function setCropsContract(address _crops) public onlyOwner {
    crops = FarmCrops(_crops);
  }

  function setHenHouseContract(address _henHouse) public onlyOwner {
    henHouse = HenHouseS2(_henHouse);
  }

  function setFoxDenContract(address _foxDen) public onlyOwner {
    foxDen = FoxDenS2(_foxDen);
  }

  function setEnergyContract(address _energy) public onlyOwner {
    energy = FarmEnergy(_energy);
  }

  function setRealtorContract(address _realtor) public onlyOwner {
    realtor = Realtor(_realtor);
  }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "./Corn.sol";

interface FarmerMetadata {
  function tokenMetadata(
    uint256 tokenId,
    uint16[7] calldata traits
  ) external view returns (string memory);
}

contract PolyFarmer is ERC721A, Ownable, VRFConsumerBase {
  bytes32 internal keyHash;
  uint256 internal fee;
  uint256 public freeSupply = 3000;
  uint256 public maxSupply = 20000;
  uint256 public purchased;
  uint256 public blockIncrement = 200 ether;
  uint256 public saleStatus;
  uint256 constant public limitFree = 3;
  mapping(address=>uint256) public freeMintTimestamp;
  mapping(address=>uint256) public limitPerAddress;
  mapping(address=>bool) public whitelistAddresses;
  mapping(string=>uint256[]) public buckets;
  Corn corn;
  FarmerMetadata metadata;
  string unrevealedMetadata;
  PolyFarmer previousContract;

  struct Traits {
    uint128 tokenId;
    uint16 gender;
    uint16 skin;
    uint16 hair;
    uint16 clothes;
    uint16 hat;
    uint16 mouth;
    uint16 eyes;
  }

  mapping(bytes32=>bool) public traitsTaken;
  mapping(uint256=>Traits) public tokenTraits;

  uint256 public nextRevealed;

  constructor(address _corn, address _metadata, address _previousContract, address _vrf, address _link, bytes32 _keyHash, uint256 _fee) ERC721A("PolyFarmer", "PFARM") VRFConsumerBase(_vrf, _link) {
    corn = Corn(_corn);
    previousContract = PolyFarmer(_previousContract);
    keyHash = _keyHash;
    fee = _fee;
    metadata = FarmerMetadata(_metadata);

    buckets['gender'] = [maxSupply/2 + 100, maxSupply/2 + 100];
    buckets['skin'] = [2100, 4100, 4100, 4100, 4100, 2100];
    buckets['hair'] = [2300, 2300, 2300, 2300, 1600, 1600, 1200, 1200, 1200, 950, 950, 750, 550, 350, 100];
    buckets['clothes'] = [3090, 2900, 2890, 2690, 2490, 2290, 1890, 1490, 990, 590, 390, 100];
    buckets['hat'] = [4090, 4900, 3900, 3900, 1900, 1900, 1900, 590, 490, 100];
    buckets['mouth'] = [1290, 1290, 1900, 1900, 990, 990, 990, 990, 990, 990, 890, 890, 890, 890, 790, 790, 690, 690, 590, 590, 590, 590, 590, 390, 390, 390, 150, 190, 190, 90, 50, 10];
    buckets['eyes'] = [1590, 1590, 1590, 1390, 1390, 1390, 1390, 1190, 1900, 990, 990, 990, 790, 790, 790, 790, 590, 590, 590, 390, 390, 390, 150, 90, 50, 10];

    // require(IERC20(_link).approve(msg.sender, type(uint256).max));
    IERC20(_link).approve(msg.sender, type(uint256).max);
  }

  function totalMinted(address account) public view returns (uint256) {
    return _numberMinted(account);
  }

  function cost(uint256 amount) public view returns (uint256) {
    if (_currentIndex < freeSupply) {
      return 0;
    }
    uint256 blockCount = (_currentIndex - freeSupply) / 500;
    return (200 ether + blockIncrement * blockCount) * amount;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(tokenId < _currentIndex, "Token doesn't exist");
    if (tokenId >= nextRevealed) {
      return unrevealedMetadata;
    }
    Traits memory traits = tokenTraits[tokenId];
    return metadata.tokenMetadata(tokenId, [traits.gender, traits.skin, traits.hair, traits.clothes, traits.hat, traits.mouth, traits.eyes]);
  }

  function whitelistMint() public {
    require(saleStatus == 1, "Whitelist mint not available");
    require(whitelistAddresses[msg.sender], "Not in whitelist");
    require(purchased < freeSupply, "Sold out");

    purchased++;
    limitPerAddress[msg.sender]++;
    whitelistAddresses[msg.sender] = false;

    _mint(msg.sender, 1, "", false);
    requestRandomness(keyHash, fee);
  }

  function freeMint() public {
    require(saleStatus == 2, "Free mint not available");
    require(limitPerAddress[msg.sender] < limitFree, "Reached free mint limit");
    require(purchased < freeSupply, "Sold out");
    require(freeMintTimestamp[msg.sender] < block.timestamp, "You must wait between txs");
    
    purchased++;
    freeMintTimestamp[msg.sender] = block.timestamp;
    limitPerAddress[msg.sender]++;

    _mint(msg.sender, 1, "", false);
    requestRandomness(keyHash, fee);
  }

  function purchase(uint256 amount) public {
    uint256 totalCost = cost(amount);
    require(purchased >= freeSupply && saleStatus == 2, "Public mint not available");
    require(corn.balanceOf(msg.sender) >= totalCost && corn.allowance(msg.sender, address(this)) >= totalCost, "You must send enough CORN");
    require(amount > 0 && amount <= 20, "Too many or too few per tx");
    require(purchased + amount <= maxSupply, "Sold out");

    purchased += amount;
    corn.burn(msg.sender, totalCost);
    _mint(msg.sender, amount, "", false);

    for (uint16 i = 0; i < amount; i++) {
      requestRandomness(keyHash, fee);
    }
  }

  function getTrait(string memory traitType, uint256 seed) internal view returns (uint16) {
    uint256[] memory bucket = buckets[traitType];
    uint256 total = 0;
    for (uint256 i = 0; i < bucket.length; i++) {
      total += bucket[i];
    }
    seed = seed % total;
    for (uint16 i = 0; i < bucket.length; i++) {
      uint256 chance = bucket[i];
      if (seed < chance) {
        return i;
      }
      seed -= chance;
    }
    revert("No trait remaining");
  }

  function fulfillRandomness(bytes32, uint256 randomness) internal override {
    uint256 tokenId = nextRevealed++;
    require(tokenId < purchased, "Wrong tokenId");
    while(true) {
      uint16 gender = getTrait('gender', uint256(keccak256(abi.encode(randomness, 1))));
      uint16 skin = getTrait('skin', uint256(keccak256(abi.encode(randomness, 2))));
      uint16 hair = getTrait('hair', uint256(keccak256(abi.encode(randomness, 3))));
      uint16 clothes = getTrait('clothes', uint256(keccak256(abi.encode(randomness, 4))));
      uint16 hat = getTrait('hat', uint256(keccak256(abi.encode(randomness, 4))));
      uint16 mouth = getTrait('mouth', uint256(keccak256(abi.encode(randomness, 6))));
      uint16 eyes = getTrait('eyes', uint256(keccak256(abi.encode(randomness, 7))));
      bytes32 hsh = keccak256(abi.encode(gender, skin, hair, clothes, hat, mouth, eyes));
      if (!traitsTaken[hsh]) {
        buckets['gender'][gender]--;
        buckets['skin'][skin]--;
        buckets['hair'][hair]--;
        buckets['clothes'][clothes]--;
        buckets['hat'][hat]--;
        buckets['mouth'][mouth]--;
        buckets['eyes'][eyes]--;
        traitsTaken[hsh] = true;
        tokenTraits[tokenId] = Traits(uint128(tokenId), gender, skin, hair, clothes, hat, mouth, eyes);
        return;
      }
    }
  }

  function airdropPreviousTokens(uint256 until) public onlyOwner {
    uint256 prevPurchased = previousContract.purchased();
    uint256 nReveal = previousContract.nextRevealed();
    require(purchased <= until && until < prevPurchased, "All done");
    for (uint256 i = purchased; i <= until; i++) {
      if (i < nReveal) {
        (
          uint128 tokenId,
          uint16 gender,
          uint16 skin,
          uint16 hair,
          uint16 clothes,
          uint16 hat,
          uint16 mouth,
          uint16 eyes
        ) = previousContract.tokenTraits(i);
        bytes32 hsh = keccak256(abi.encode(gender, skin, hair, clothes, hat, mouth, eyes));
        buckets['gender'][gender]--;
        buckets['skin'][skin]--;
        buckets['hair'][hair]--;
        buckets['clothes'][clothes]--;
        buckets['hat'][hat]--;
        buckets['mouth'][mouth]--;
        buckets['eyes'][eyes]--;
        traitsTaken[hsh] = true;
        tokenTraits[tokenId] = Traits(tokenId, gender, skin, hair, clothes, hat, mouth, eyes);
        nextRevealed++;
      } else {
        requestRandomness(keyHash, fee);
      }
      address account = previousContract.ownerOf(i);
      _mint(account, 1, "", false);
    }
    purchased = until + 1;
  }

  function requestReveal(uint256 amount) public onlyOwner {
    for (uint16 i = 0; i < amount; i++) {
      requestRandomness(keyHash, fee);
    }
  }

  function setBlockIncrement(uint256 _increment) public onlyOwner {
    blockIncrement = _increment;
  }

  function setSaleStatus(uint256 _status) public onlyOwner {
    saleStatus = _status;
  }

  function setUnrevealedMetadata(string calldata _metadata) public onlyOwner {
    unrevealedMetadata = _metadata;
  }

  function setWhitelistAddresses(address[] calldata addresses, bool status) public onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      whitelistAddresses[addresses[i]] = status;
    }
  }

  function setMetadataContract(address _metadata) public onlyOwner {
    metadata = FarmerMetadata(_metadata);
  }
  
  function setCorn(address _corn) public onlyOwner {
    corn = Corn(_corn);
  }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC1155/ERC1155.sol";
import "./Base64.sol";

enum BuildingTypes {
  HOUSE,
  HENHOUSE,
  FOXDEN,
  CROPS,
  WELL,
  SILO
}

contract PolyBuildings is Ownable, ERC1155 {
  mapping(uint256=>string) images;
  mapping(uint256=>string) names;
  mapping(uint256=>uint256) public buildingCost;
  string public name;
  string public symbol;
  string public description;
  IERC20 eggs;

  constructor(address _eggs) ERC1155("") {
    eggs = IERC20(_eggs);
    name = 'PolyBuildings';
    symbol = 'PFBD';
    description = 'Buildings determine the capacity and power of a single Farm. Farmers starts to gather resources for buildings to maximize their production. Can you get them to the max level?';
    buildingCost[uint256(BuildingTypes.HOUSE)] = 50 ether;
    buildingCost[uint256(BuildingTypes.HENHOUSE)] = 25 ether;
    buildingCost[uint256(BuildingTypes.FOXDEN)] = 25 ether;
    buildingCost[uint256(BuildingTypes.CROPS)] = 30 ether;
    buildingCost[uint256(BuildingTypes.WELL)] = 15 ether;
    buildingCost[uint256(BuildingTypes.SILO)] = 30 ether;
    eggs.approve(msg.sender, type(uint256).max);
  }

  function getImage(uint256 tokenId) public view returns (bytes memory) {
    return abi.encodePacked(
      '<svg id="PolyBuildings" width="100%" height="100%" version="1.1" viewBox="0 0 216 216" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><image x="0" y="0" width="216" height="216" image-rendering="pixelated" preserveAspectRatio="xMidYMid"  xlink:href="data:image/png;base64,',
      images[tokenId],
      '"/></svg>'
    );
  }

  function uri(uint256 tokenId) public view virtual override returns (string memory) {
    bytes memory json = abi.encodePacked(
      '{"name": "',
      names[tokenId],
      '","description": "',
      description,
      '","image": "data:image/svg+xml;base64,',
      Base64.encode(getImage(tokenId)),
      '","external_url": "https://polyfarm.app"}'
    );
    return string(
      abi.encodePacked(
        "data:application/json;base64,",
        Base64.encode(json)
      )
    );
  }

  function mint(uint256 buildingType, uint16 amount) public {
    uint256 cost = buildingCost[buildingType];
    require(cost > 0, "Invalid building");
    uint256 eggPrice = cost * amount;

    eggs.transferFrom(msg.sender, address(this), eggPrice);

    _mint(msg.sender, uint256(buildingType) * 10, amount, "");
  }

  function merge(uint256 tokenId) public {
    require(tokenId % 10 < 9, "Building at max level");
    require(balanceOf(msg.sender, tokenId) >= 2, "You must have enough of those buildings");

    _burn(msg.sender, tokenId, 2);
    _mint(msg.sender, tokenId + 1, 1, "");
  }

  function mintAsOwner(uint256 buildingType, uint16 amount) public onlyOwner {
    _mint(msg.sender, buildingType * 10, amount, "");
  }

  function setBuildingCost(uint256 _type, uint256 cost) public onlyOwner {
    buildingCost[_type] = cost;
  }

  function setTokenMetadata(uint256 tokenId, string memory n, string memory image) public onlyOwner {
    names[tokenId] = n;
    images[tokenId] = image;
  }
  function setDescription(string memory descriptionText) public onlyOwner {
    description = descriptionText;
  }
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/Strings.sol";

contract Metadata is Ownable {
    using Strings for uint256;

    struct Trait {
        string name;
        string image;
    }

    string[4] categoryNames = ["Color", "Expression", "Accesory", "Hat"];

    mapping(uint8=>mapping(uint8=>Trait)) public traitData;

    constructor() {}

    function uploadTraits(uint8 category, Trait[] calldata traits)
        public
        onlyOwner
    {
        require(traits.length == 16, "Wrong length");
        for (uint8 i = 0; i < traits.length; i++) {
            traitData[category][i] = Trait(traits[i].name, traits[i].image);
        }
    }

    function drawTrait(Trait memory trait)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '<image x="0" y="0" width="64" height="64" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
                    trait.image,
                    '"/>'
                )
            );
    }

    function drawSVG(bool isFox, uint8[] memory traits)
        public
        view
        returns (string memory)
    {
        uint8 offset = isFox ? 4 : 0;
        string memory svgString = string(
            abi.encodePacked(
                drawTrait(traitData[offset][traits[0]]),
                drawTrait(traitData[1 + offset][traits[1]]),
                drawTrait(traitData[2 + offset][traits[2]]),
                drawTrait(traitData[3 + offset][traits[3]])
            )
        );

        return
            string(
                abi.encodePacked(
                    '<svg id="foxhen" width="100%" height="100%" version="1.1" viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                    svgString,
                    "</svg>"
                )
            );
    }

    function attributeForTypeAndValue(
        string memory categoryName,
        string memory value
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '{"trait_type":"',
                    categoryName,
                    '","value":"',
                    value,
                    '"}'
                )
            );
    }

    function compileAttributes(
        bool isFox,
        uint8[] memory traits,
        uint256 tokenId
    ) public view returns (string memory) {
        uint8 offset = isFox ? 4 : 0;
        string memory attributes = string(
            abi.encodePacked(
                attributeForTypeAndValue(
                    categoryNames[0],
                    traitData[offset][traits[0]].name
                ),
                ",",
                attributeForTypeAndValue(
                    categoryNames[1],
                    traitData[offset + 1][traits[1]].name
                ),
                ",",
                attributeForTypeAndValue(
                    categoryNames[2],
                    traitData[offset + 2][traits[2]].name
                ),
                ",",
                attributeForTypeAndValue(
                    categoryNames[3],
                    traitData[offset + 3][traits[3]].name
                ),
                ","
            )
        );
        return
            string(
                abi.encodePacked(
                    "[",
                    attributes,
                    '{"trait_type":"Generation","value":',
                    tokenId <= 10000 ? '"Gen 0"' : '"Gen 1"',
                    '},{"trait_type":"Type","value":',
                    isFox ? '"Fox"' : '"Hen"',
                    "}]"
                )
            );
    }

    function tokenMetadata(
        bool isFox,
        uint256 traitId,
        uint256 tokenId
    ) public view returns (string memory) {
        uint8[] memory traits = new uint8[](4);
        uint256 traitIdBackUp = traitId;
        for (uint8 i = 0; i < 4; i++) {
            uint8 exp = 3 - i;
            uint8 tmp = uint8(traitIdBackUp / (16**exp));
            traits[i] = tmp;
            traitIdBackUp -= tmp * 16**exp;
        }

        string memory svg = drawSVG(isFox, traits);

        string memory metadata = string(
            abi.encodePacked(
                '{"name": "',
                isFox ? "Fox #" : "Hen #",
                tokenId.toString(),
                '", "description": "A sunny day in the Summer begins, with the Farmlands and the Forest In its splendor, it seems like a normal day. But the cunning planning of the Foxes has begun, they know that the hens will do everything to protect their precious $EGG but can they keep them all without risk of losing them? A Risk-Reward economic game, where every action matters. No IPFS. No API. All stored and generated 100% on-chain", "image": "data:image/svg+xml;base64,',
                base64(bytes(svg)),
                '", "attributes":',
                compileAttributes(isFox, traits, tokenId),
                "}"
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    base64(bytes(metadata))
                )
            );
    }

    /** BASE 64 - Written by Brech Devos */

    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function base64(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

interface Meta {
  function tokenMetadata(uint256 tokenId, int256 x, int256 y) external view returns (string memory);
}

contract Land is ERC721Enumerable, Ownable {
  struct TokenWithMetadata {
    uint256 tokenId;
    int256 x;
    int256 y;
    string metadata;
  }

  mapping(int256=>mapping(int256=>uint256)) coordinatesTaken;
  mapping(uint256=>TokenWithMetadata) tokenData;
  mapping(address=>bool) allowed;

  Meta metadata;

  constructor(address _meta) ERC721("PolyFarm Land", 'PFL') {
    metadata = Meta(_meta);
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    TokenWithMetadata storage data = tokenData[tokenId];
    require(data.tokenId == tokenId, "Invalid token");
    return metadata.tokenMetadata(tokenId, data.x, data.y);
  }

  function allTokensOfOwner(address owner) public view returns (TokenWithMetadata[] memory) {
    uint256 balance = balanceOf(owner);
    TokenWithMetadata[] memory tokens = new TokenWithMetadata[](balance);
    for (uint256 i = 0; i < balance; i++) {
      uint256 tokenId = tokenOfOwnerByIndex(owner, i);
      TokenWithMetadata memory data = tokenData[tokenId];
      data.metadata = tokenURI(tokenId);
      tokens[i] = data;
    }
    return tokens;
  }

  // Admin
  function changeMetadata(address _meta) public onlyOwner {
    metadata = Meta(_meta);
  }

  function toggleAllowed(address a) public onlyOwner {
    allowed[a] = !allowed[a];
  }

  function mint(uint256[] memory tokenIds, address[] memory users, int256[] memory xs, int256[] memory ys) public {
    require(msg.sender == owner() || allowed[msg.sender], "Unauthorized");
    require(tokenIds.length == users.length && tokenIds.length == xs.length && tokenIds.length == ys.length, "Wrong data");

    for (uint16 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      address user = users[i];
      int256 x = xs[i];
      int256 y = ys[i];
      require(coordinatesTaken[x][y] == 0, "Wrong coordinates");
      tokenData[tokenId] = TokenWithMetadata(tokenId, x, y, "");
      coordinatesTaken[x][y] = tokenId;
      _mint(user, tokenId);
    }
  }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "./FoxHen.sol";
import "./FarmStaker.sol";
import "./Eggs.sol";
import "./FarmEnergy.sol";
import "./FoxDenS2.sol";
import "./PolyBuildings.sol";
import "./Realtor.sol";

contract HenHouseS2 is Ownable {
  FoxHen foxHen;
  Realtor realtor;
  FarmStaker staker;
  Eggs eggs;
  FarmEnergy energy;
  FoxDenS2 foxDen;

  enum Connections {
    STAKER,
    ENERGY,
    FOXDEN,
    REALTOR
  }

  bool public paused;
  uint256 public ratio = 0.000004 ether;
  uint16 public taxPercentage = 10;

  mapping(uint256=>uint256) public lastClaim;

  event Claim(address indexed account, uint64 indexed landId, uint8 indexed farmId, uint256 amount);

  constructor(address _foxHen, address _staker, address _realtor, address _eggs, address _energy) {
    foxHen = FoxHen(_foxHen);
    staker = FarmStaker(_staker);
    realtor = Realtor(_realtor);
    eggs = Eggs(_eggs);
    energy = FarmEnergy(_energy);

    eggs.approve(msg.sender, type(uint256).max);
    eggs.approve(_realtor, type(uint256).max);
  }

  function henTimestamp(bytes32 key) public view returns (uint256) {
    (,,,, uint32 tokenId, uint64 t) = staker.allStakings(key);
    uint256 claimTimestamp = lastClaim[uint256(tokenId)];
    return claimTimestamp == 0 ? uint256(t) : claimTimestamp;
  }

  function getTemporaryBalance(bytes32 key, bytes32 henHouseKey) public view returns (uint256) {
    (uint64 l, uint8 f, address account,, uint32 tokenId, uint64 t) = staker.allStakings(key);
    if (uint256(henHouseKey) == 0) {
      require(staker.getBuildingLevel(account, uint256(l), uint256(f), uint256(BuildingTypes.HENHOUSE)) == 0, "You already have a henhouse");
    } else {
      (uint64 hl, uint8 hf, address hAccount,, uint32 hTokenId, uint64 ht) = staker.allStakings(henHouseKey);

      require(hl == l && hf == f && hAccount == account && (hTokenId / 10) == uint32(BuildingTypes.HENHOUSE), "Wrong Henhouse");
      t = t > ht ? t : ht;
    }

    uint256 claimTimestamp = lastClaim[uint256(tokenId)];
    uint256 timestamp = t > claimTimestamp ? uint256(t) : claimTimestamp;
    uint256 timePassed = block.timestamp - timestamp;
    uint256 henHouseBalance = eggs.balanceOf(address(this));
    return henHouseBalance * timePassed * ratio / (1 days * 1 ether);
  }

  function getTemporaryBalanceBatch(bytes32[] calldata keys, bytes32 henHouseKey) public view returns (uint256, uint256[] memory) {
    uint256[] memory balances = new uint256[](keys.length);
    uint256 balance = 0;
    for (uint256 i = 0; i < keys.length; i++) {
      balances[i] = getTemporaryBalance(keys[i], henHouseKey);
      balance += balances[i];
    }
    return (balance, balances);
  }

  function claimEggs(uint64 landId, uint8 farmId, bytes32 key, bytes32 henHouseKey) internal returns (uint256) {
    (uint64 l, uint8 f, address owner, address asset, uint32 tokenId,) = staker.allStakings(key);
    require(asset == address(foxHen), "Incorrect key");
    require(!foxHen.isFox(tokenId), "Must be a hen");
    require(l == landId && f == farmId, "Incorrect farm");
    require(msg.sender == owner, "Unauthorized");
    require(!foxHen.isFox(uint256(tokenId)), "Only hens can lay eggs");
    uint256 balance = getTemporaryBalance(key, henHouseKey);
    lastClaim[uint256(tokenId)] = block.timestamp;
    return balance;
  }

  function claimEggsBatch(uint64 landId, uint8 farmId, bytes32[] calldata keys, bytes32 henHouseKey) public returns (uint256) {
    require(!paused, "Paused");
    uint256 henHouseLevel = staker.getBuildingLevel(msg.sender, landId, farmId, uint256(BuildingTypes.HENHOUSE));
    uint256 totalHens = staker.henCount(msg.sender, landId, farmId);
    require(totalHens <= (henHouseLevel == 0 ? 1 : 3 * henHouseLevel), "Wrong amount of hens");
    uint256 total = 0;
    energy.spendEnergy(msg.sender, landId, farmId);
    for (uint256 i = 0; i < keys.length; i++) {
      total += claimEggs(landId, farmId, keys[i], henHouseKey);
    }

    uint256 tax = taxPercentage * total / 100;
    total -= tax;

    uint256 rent = realtor.payRent(msg.sender, landId, farmId, address(eggs), total);
    total -= rent;

    eggs.transfer(msg.sender, total);
    foxDen.payFoxTax(tax);

    emit Claim(msg.sender, landId, farmId, total);
    return total;
  }

  function changeConnection(Connections connection, address endpoint) public onlyOwner {
    if (connection == Connections.STAKER) {
      staker = FarmStaker(endpoint);
    } else if (connection == Connections.ENERGY) {
      energy = FarmEnergy(endpoint);
    } else if (connection == Connections.FOXDEN) {
      if (address(foxDen) != address(0)) {
        eggs.approve(address(foxDen), 0);
      }
      eggs.approve(endpoint, type(uint256).max);
      foxDen = FoxDenS2(endpoint);
    } else if (connection == Connections.REALTOR) {
      if (address(realtor) != address(0)) {
        eggs.approve(address(realtor), 0);
      }
      eggs.approve(endpoint, type(uint256).max);
      realtor = Realtor(endpoint);
    }
  }

  function setRatio(uint256 _r) public onlyOwner {
    ratio = _r;
  }

  function setPaused(bool _p) public onlyOwner {
    paused = _p;
  }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "openzeppelin-solidity/contracts/access/Ownable.sol";

contract Handlers is Ownable {
  mapping(address=>bool) public handlers;

  function addHandler(address h) public onlyOwner {
    handlers[h] = true;
  }

  function removeHandler(address h) public onlyOwner {
    handlers[h] = false;
  }

  modifier isHandler() {
    address sender = _msgSender();
    require(owner() == sender || handlers[sender], "Handlers: Unauthorized");
    _;
  }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "./Metadata.sol";

contract FoxHen is ERC721Enumerable, Ownable, VRFConsumerBase {
  uint256 public constant MAX_TOKENS = 10000;
  uint256 public constant FREE_TOKENS = 3000;
  uint16 public purchased = 0;

  struct Minting {
    address minter;
    uint256 tokenId;
    bool fulfilled;
  }
  mapping(bytes32=>Minting) mintings;

  struct TokenWithMetadata {
    uint256 tokenId;
    bool isFox;
    string metadata;
  }

  mapping(uint256=>bool) public isFox;
  uint256[] public foxes;
  uint16 public stolenMints;
  mapping(uint256=>uint256) public traitsOfToken;
  mapping(uint256=>bool) public traitsTaken;
  bool public mainSaleStarted;
  mapping(bytes=>bool) public signatureUsed;
  mapping(address=>uint8) public freeMintsUsed;
  uint256 extrasCount;

  IERC20 eggs;
  Metadata metadata;

  bytes32 internal keyHash;
  uint256 internal fee;

  constructor(address _eggs, address _vrf, address _link, bytes32 _keyHash, uint256 _fee, address _metadata) ERC721("FoxHen", 'FH') VRFConsumerBase(_vrf, _link) {
    eggs = IERC20(_eggs);
    metadata = Metadata(_metadata);
    keyHash = _keyHash;
    fee = _fee;
    require(IERC20(_link).approve(msg.sender, type(uint256).max));
    require(eggs.approve(msg.sender, type(uint256).max));
  }

  // Internal
  function setTraits(uint256 tokenId, uint256 seed) internal returns (uint256) {
    uint256 maxTraits = 16 ** 4;
    uint256 nextRandom = uint256(keccak256(abi.encode(seed, 1)));
    uint256 traitsID = nextRandom % maxTraits;
    while(traitsTaken[traitsID]) {
      nextRandom = uint256(keccak256(abi.encode(nextRandom, 1)));
      traitsID = nextRandom % maxTraits;
    }
    traitsTaken[traitsID] = true;
    traitsOfToken[tokenId] = traitsID;
    return traitsID;
  }

  function setSpecies(uint256 tokenId, uint256 seed) internal returns (bool) {
    uint256 random = uint256(keccak256(abi.encode(seed, 2))) % 10;
    if (random == 0) {
      isFox[tokenId] = true;
      foxes.push(tokenId);
      return true;
    }
    return false;
  }

  function getRecipient(uint256 tokenId, address minter, uint256 seed) internal view returns (address) {
    if (tokenId > FREE_TOKENS && tokenId <= MAX_TOKENS && (uint256(keccak256(abi.encode(seed, 3))) % 10) == 0) {
      uint256 fox = foxes[uint256(keccak256(abi.encode(seed, 4))) % foxes.length];
      address owner = ownerOf(fox);
      if (owner != address(0)) {
        return owner;
      }
    }
    return minter;
  }

  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
    Minting storage minting = mintings[requestId];
    require(minting.minter != address(0));
    setSpecies(minting.tokenId, randomness);
    setTraits(minting.tokenId, randomness);

    address recipient = getRecipient(minting.tokenId, minting.minter, randomness);
    if (recipient != minting.minter) {
      stolenMints++;
    }
    _mint(recipient, minting.tokenId);
  }

  // Reads
  function eggsPrice(uint16 amount) public view returns (uint256) {
    require(purchased + amount >= FREE_TOKENS);
    uint16 secondGen = purchased + amount - uint16(FREE_TOKENS);
    return (secondGen / 500 + 1) * 40 ether;
  }

  function foxCount() public view returns (uint256) {
    return foxes.length;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    return metadata.tokenMetadata(isFox[tokenId], traitsOfToken[tokenId], tokenId);
  }

  function allTokensOfOwner(address owner) public view returns (TokenWithMetadata[] memory) {
    uint256 balance = balanceOf(owner);
    TokenWithMetadata[] memory tokens = new TokenWithMetadata[](balance);
    for (uint256 i = 0; i < balance; i++) {
      uint256 tokenId = tokenOfOwnerByIndex(owner, i);
      string memory data = tokenURI(tokenId);
      tokens[i] = TokenWithMetadata(tokenId, isFox[tokenId], data);
    }
    return tokens;
  }

  // Public
  function freeMint(uint8 amount) public payable {
    require(mainSaleStarted, "Main Sale hasn't started yet");
    address minter = _msgSender();
    require(freeMintsUsed[minter] + amount <= 5, "You can't free mint any more");
    require(tx.origin == minter, "Contracts not allowed");
    require(purchased + amount <= FREE_TOKENS, "Sold out");

    for (uint8 i = 0; i < amount; i++) {
      freeMintsUsed[minter]++;
      purchased++;
      bytes32 requestId = requestRandomness(keyHash, fee);
      mintings[requestId] = Minting(minter, purchased, false);
    }
  }

  function buyWithEggs(uint16 amount) public {
    address minter = _msgSender();
    require(mainSaleStarted, "Main Sale hasn't started yet");
    require(tx.origin == minter, "Contracts not allowed");
    require(amount > 0 && amount <= 20, "Max 20 mints per tx");
    require(purchased >= FREE_TOKENS, "Eggs sale not active");
    require(purchased + amount <= MAX_TOKENS, "Sold out");

    uint256 price = amount * eggsPrice(amount);
    require(price <= eggs.allowance(minter, address(this)) && price <= eggs.balanceOf(minter), "You need to send enough eggs");
    
    uint256 initialPurchased = purchased;
    purchased += amount;
    require(eggs.transferFrom(minter, address(this), price));

    for (uint16 i = 1; i <= amount; i++) {
      bytes32 requestId = requestRandomness(keyHash, fee);
      mintings[requestId] = Minting(minter, initialPurchased + i, false);
    }
  }

  function mintExtra(address recipient) public onlyOwner {
    require(extrasCount + 1 <= 30, "Max extras minted");
    extrasCount++;
    uint256 tokenId = MAX_TOKENS + extrasCount;
    bytes32 requestId = requestRandomness(keyHash, fee);
    mintings[requestId] = Minting(recipient, tokenId, false);
  }

  // Admin
  function mintL1Token(address recipient, uint256 tokenId, uint256 traitsID, bool fox) external onlyOwner {
    require(!mainSaleStarted, "Main Sale has already begun");
    require(purchased + 1 == tokenId, "Incorrect tokenId");
    require(!traitsTaken[traitsID], "Traits already in use");

    purchased++;
    if (fox) {
      isFox[tokenId] = true;
      foxes.push(tokenId);
    }
    traitsTaken[traitsID] = true;
    traitsOfToken[tokenId] = traitsID;
    _mint(recipient, tokenId);
  }

  function toggleMainSale() public onlyOwner {
    mainSaleStarted = !mainSaleStarted;
  }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol";
import "./HenHouseS2.sol";
import "./FarmStaker.sol";
import "./Eggs.sol";
import "./FoxHen.sol";
import "./Realtor.sol";
import "./FarmEnergy.sol";
import "./PolyBuildings.sol";

contract FoxDenS2 is Ownable, VRFConsumerBase {
  HenHouseS2 henHouse;
  Realtor realtor;
  FarmStaker staker;
  Eggs eggs;
  FoxHen foxHen;
  FarmEnergy energy;
  IERC20 weth;

  AggregatorInterface ethFeed;
  AggregatorInterface maticFeed;

  uint256[] public heistPrices = [250000000, 500000000, 750000000, 1000000000, 1250000000];
  bool public paused;
  uint256 public foxValue;
  struct Fox {
    uint256 timestamp;
    uint256 foxValue;
    uint256 dailyCount;
  }

  struct Cost {
    uint256 usd;
    uint256 matic;
    uint256 eth;
  }
  uint256 internal baseReward = 5 ether;
  uint256 internal maxBaseReward = 30 ether;

  uint256 public constant foxCount = 1032;
  mapping(bytes32 => Fox) public foxesData;
  mapping(bytes32 => bytes32) heists;
  uint256 public eggsHeisted;
  uint256 public heistCount;

  uint256 public jackpot = 1000;
  uint256 public jackpotAmount = 200 ether;

  uint256 public totalTaxAmount;

  bytes32 internal keyHash;
  uint256 internal fee;

  event Heist(
    address indexed owner,
    uint256 indexed fox,
    uint256 amount,
    uint64 landId,
    uint8 farmId
  );

  constructor(
    address[] memory refs,
    address _weth,
    address _vrf,
    address _link,
    bytes32 _keyHash,
    uint256 _fee,
    address _ethFeed,
    address _maticFeed
  ) VRFConsumerBase(_vrf, _link) {
    staker = FarmStaker(refs[0]);
    henHouse = HenHouseS2(refs[1]);
    eggs = Eggs(refs[2]);
    foxHen = FoxHen(refs[3]);
    realtor = Realtor(refs[4]);
    energy = FarmEnergy(refs[5]);
    weth = IERC20(_weth);
    keyHash = _keyHash;
    fee = _fee;
    ethFeed = AggregatorInterface(_ethFeed);
    maticFeed = AggregatorInterface(_maticFeed);
    eggs.approve(msg.sender, type(uint256).max);
    weth.approve(msg.sender, type(uint256).max);
    IERC20(_link).approve(msg.sender, type(uint256).max);
    eggs.approve(refs[4], type(uint256).max);
  }

  function ETHPrice(uint256 price) public view returns (uint256) {
    uint256 v = uint256(ethFeed.latestAnswer()); // Get real value
    return 1 ether * price / v;
  }

  function MATICPrice(uint256 price) public view returns (uint256) {
    uint256 v = uint256(maticFeed.latestAnswer()); // Get real value
    return 1 ether * price / v;
  }

  function heistCost(bytes32 key) public view returns (Cost memory) {
    uint256 exp = dailyCount(key);
    require(exp < heistPrices.length, "Over the daily count");
    uint256 usd = heistPrices[exp];

    return Cost(usd * 10 ** 10, MATICPrice(usd), ETHPrice(usd));
  }

  function dailyCount(bytes32 key) public view returns (uint256) {
    Fox storage fox = foxesData[key];
    uint256 diff = block.timestamp - fox.timestamp;
    return diff > 1 days ? 0 : fox.dailyCount;
  }

  function getFox(bytes32 key) public view returns (Fox memory) {
    Fox storage fox = foxesData[key];
    return Fox(fox.timestamp, foxValue - fox.foxValue, dailyCount(key));
  }

  function getFoxes(bytes32[] calldata keys) public view returns (Fox[] memory) {
    Fox[] memory list = new Fox[](keys.length);
    for (uint256 i = 0; i < keys.length; i++) {
      list[i] = getFox(keys[i]);
    }
    return list;
  }

  function claimTax(bytes32[] memory keys, bytes32 foxDenKey) public {
    uint256 total = 0;
    (uint64 landId, uint8 farmId, address account,, uint32 tokenId,) = staker.allStakings(foxDenKey);
    require(msg.sender == account && (tokenId / 10) == uint32(BuildingTypes.FOXDEN), "Incorrect FoxDen");
    for (uint256 i = 0; i < keys.length; i++) {
      Fox storage fox = foxesData[keys[i]];
      (uint64 l, uint8 f,,,,) = staker.allStakings(keys[i]);
      require(landId == l && farmId == f, "All foxes must be on the same farm");

      if (fox.foxValue < foxValue) {
        uint256 tax = foxValue - fox.foxValue;
        foxesData[keys[i]].foxValue = foxValue;
        total += tax;
      }
    }
    energy.spendEnergy(msg.sender, landId, farmId);

    totalTaxAmount += total;

    uint256 rent = realtor.payRent(msg.sender, uint256(landId), uint256(farmId), address(eggs), total);
    total -= rent;

    eggs.transfer(msg.sender, total);
  }

  function heist(bytes32 key) public payable {
    require(!paused, "Contract paused");
    (,, address owner, address asset, uint32 tokenId,) = staker.allStakings(key);

    require(
      asset == address(foxHen) && owner == msg.sender && foxHen.isFox(tokenId),
      "You must own that fox"
    );
    Fox storage fox = foxesData[key];

    uint256 diff = block.timestamp - fox.timestamp;
    if (diff > 1 days) {
      fox.timestamp = block.timestamp;
      fox.dailyCount = 0;
    }

    require(fox.dailyCount < heistPrices.length, "You can heist a maximum of 5 times per day");
    Cost memory cost = heistCost(key);
    fox.dailyCount++;

    if (msg.value > 0) {
      require(msg.value >= cost.matic, "You must pay the correct amount of MATIC");
    } else {
      uint256 allowance = weth.allowance(msg.sender, address(this));
      uint256 balance = weth.balanceOf(msg.sender);
      require(allowance >= cost.eth && balance >= cost.eth, "You must pay the correct amount of ETH");
      weth.transferFrom(msg.sender, address(this), cost.eth);
    }

    heistCount++;
    bytes32 requestId = requestRandomness(keyHash, fee);
    heists[requestId] = key;
  }

  function getRandomReward(uint256 seed) internal view returns (uint256) {
    if (seed % jackpot == 0) {
      return jackpotAmount;
    }
    return uint256(keccak256(abi.encode(seed))) % (maxBaseReward - baseReward) + baseReward;
  }

  function payFoxTax(uint256 amount) public {
    eggs.transferFrom(msg.sender, address(this), amount);
    foxValue += amount / foxCount;
  }

  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
    bytes32 key = heists[requestId];
    (uint64 l, uint8 f, address owner, address asset, uint32 tokenId,) = staker.allStakings(key);
    require(owner != address(0) && asset == address(foxHen));
    
    uint256 reward = getRandomReward(randomness);

    eggsHeisted += reward;
    eggs.transferFrom(address(henHouse), owner, reward);
    emit Heist(owner, tokenId, reward, l, f);
  }

  function withdraw() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  function togglePause() external onlyOwner {
    paused = !paused;
  }

  function setHeistPrice(uint8 index, uint256 price) external onlyOwner {
    require(index < heistPrices.length, "Incorrect index");
    heistPrices[index] = price;
  }

  function setBaseRewards(uint256 min, uint256 max) external onlyOwner {
    baseReward = min;
    maxBaseReward = max;
  }

  function setJackpot(uint256 _jackpot, uint256 _jackpotAmount) external onlyOwner {
    jackpot = _jackpot;
    jackpotAmount = _jackpotAmount;
  }

  function setHenHouseContract(address _henHouse) public onlyOwner {
    henHouse = HenHouseS2(_henHouse);
  }

  function setRealtorContract(address _realtor) public onlyOwner {
    if (address(realtor) != address(0)) {
      eggs.approve(address(realtor), 0);
    }
    eggs.approve(_realtor, type(uint256).max);
    realtor = Realtor(_realtor);
  }

  function setEnergyContract(address _energy) public onlyOwner {
    energy = FarmEnergy(_energy);
  }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "openzeppelin-solidity/contracts/token/ERC1155/IERC1155.sol";
import "openzeppelin-solidity/contracts/token/ERC721/IERC721.sol";
import "./PolyBuildings.sol";
import "./FoxHen.sol";
import "./StakerValidator.sol";
import "./PolyFarmer.sol";

interface MetadataGetter {
  function uri(uint256) external view returns (string memory);
  function tokenURI(uint256) external view returns (string memory);
}

contract FarmStaker is ERC1155Holder, Ownable {
  PolyBuildings buildings;
  address[] allowedAssets;
  FoxHen foxHen;
  PolyFarmer farmer;
  StakerValidator validator;
  bool public paused;

  struct Staking {
    uint64 landId;
    uint8 farmId;
    address owner; // uint160
    address asset; // uint160
    uint32 tokenId;
    uint64 timestamp;
    //uint24 remaining;
  }

  struct Asset {
    Staking staking;
    bytes32 key;
    string metadata;
  }

  uint256 reentrancyGuard = 1;

  mapping(address=>mapping(address=>bool)) public isApprovedForAll;

  mapping(bytes32=>Staking) public allStakings;
  mapping(address=>bytes32[]) stakingsByUser;
  mapping(address=>mapping(uint256=>mapping(uint256=>uint16))) public henCount;
  mapping(address=>mapping(uint256=>mapping(uint256=>uint16))) public foxCount;
  mapping(address=>mapping(uint256=>mapping(uint256=>uint16))) public farmerCount;

  constructor(address _buildings, address _foxHen, address _farmer) {
    buildings = PolyBuildings(_buildings);
    foxHen = FoxHen(_foxHen);
    farmer = PolyFarmer(_farmer);
  }

  function getKey(address asset, address account, uint256 landId, uint256 farmId, uint256 tokenId) public pure returns (bytes32) {
    return keccak256(abi.encode(asset, account, landId, farmId, tokenId));
  }

  function assetIs1155(address _asset) public view returns (bool) {
    IERC1155 asset = IERC1155(_asset);
    return asset.supportsInterface(type(IERC1155).interfaceId);
  }

  function isAllowed(address asset) public view returns (bool) {
    if (asset == address(buildings) || asset == address(foxHen) || asset == address(farmer)) {
      return true;
    }

    for (uint8 i = 0; i < allowedAssets.length; i++) {
      if (allowedAssets[i] == asset) {
        return true;
      }
    }

    return false;
  }

  function allUserAssets(address account) public view returns (Asset[] memory) {
    bytes32[] storage keys = stakingsByUser[account];
    Asset[] memory assets = new Asset[](keys.length);

    for (uint16 i = 0; i < keys.length; i++) {
      Staking storage staking = allStakings[keys[i]];
      bool is1555 = assetIs1155(staking.asset);
      MetadataGetter meta = MetadataGetter(staking.asset);
      string memory metadata = is1555 ? meta.uri(staking.tokenId) : meta.tokenURI(staking.tokenId);
      assets[i] = Asset(staking, keys[i], metadata);
    }
    return assets;
  }

  function allStakingsOfTypeOnFarm(address asset, address account, uint256 landId, uint256 farmId) public view returns (Staking[] memory) {
    bytes32[] storage keys = stakingsByUser[account];
    Staking[] memory assets = new Staking[](keys.length);
    uint256 index = 0;

    for (uint256 i = 0; i < keys.length; i++) {
      Staking memory staking = allStakings[keys[i]];
      if (staking.asset == asset && staking.landId == landId && staking.farmId == farmId && staking.owner == account) {
        assets[index++] = staking;
      }
    }

    Staking[] memory finalList = new Staking[](index);

    for (uint16 i = 0; i < index; i++) {
      finalList[i] = assets[i];
    }

    return finalList;
  }

  function countAllAssetsOnFarm(address account, uint256 landId, uint256 farmId) public view returns (uint256) {
    bytes32[] storage keys = stakingsByUser[account];
    uint256 count = 0;

    for (uint16 i = 0; i < keys.length; i++) {
      Staking storage staking = allStakings[keys[i]];
      if (staking.landId == landId && staking.farmId == farmId && staking.owner == account) {
        count++;
      }
    }

    return count;
  }

  function allAssetsOnFarm(address account, uint256 landId, uint256 farmId) public view returns (Asset[] memory) {
    bytes32[] storage keys = stakingsByUser[account];
    Asset[] memory assets = new Asset[](keys.length);
    uint256 index = 0;

    for (uint16 i = 0; i < keys.length; i++) {
      Staking storage staking = allStakings[keys[i]];
      if (staking.landId == landId && staking.farmId == farmId && staking.owner == account) {
        bool is1555 = assetIs1155(staking.asset);
        MetadataGetter meta = MetadataGetter(staking.asset);
        string memory metadata = is1555 ? meta.uri(staking.tokenId) : meta.tokenURI(staking.tokenId);
        assets[index++] = Asset(staking, keys[i], metadata);
      }
    }

    Asset[] memory finalList = new Asset[](index);

    for (uint16 i = 0; i < index; i++) {
      finalList[i] = assets[i];
    }

    return finalList;
  }

  function getBuildingLevel(address account, uint256 landId, uint256 farmId, uint256 buildingType) public view returns (uint256) {
    uint256 tokenId = buildingType * 10;
    for (uint256 i = 10; i > 0; i--) {
      bytes32 key = getKey(address(buildings), account, landId, farmId, tokenId + i - 1);
      if (allStakings[key].timestamp > uint64(0)) {
        return i;
      }
    }
    return 0;
  }

  function balanceOfBatch(address account, uint256 landId, uint256 farmId, address[] memory assets, uint256[] memory ids) public view returns (uint256[] memory) {
    require(assets.length == ids.length, "assets and ids length mismatch");
    uint256[] memory batchBalances = new uint256[](ids.length);
    for (uint256 i = 0; i < batchBalances.length; i++) {
      bytes32 key = getKey(assets[i], account, landId, farmId, ids[i]);
      if (allStakings[key].timestamp > 0) {
        batchBalances[i] = 1;
      }
    }
    return batchBalances;
  }

  function balanceOfKeys(bytes32[] calldata keys) public view returns (uint256[] memory) {
    uint256[] memory batchBalances = new uint256[](keys.length);
    for (uint256 i = 0; i < batchBalances.length; i++) {
      if (allStakings[keys[i]].timestamp > 0) {
        batchBalances[i] = 1;
      }
    }
    return batchBalances;
  }

  function stake(address asset, address account, uint256 landId, uint256 farmId, uint256 tokenId) public {
    require(!paused, "Paused");
    require(reentrancyGuard == 1, "Reentrancy");
    reentrancyGuard = 2;
    require(validator.isValid(asset, account, landId, farmId, tokenId), "Incorrect asset");
    require(account == msg.sender || isApprovedForAll[account][msg.sender], "Unauthorized");
    bytes32 key = getKey(asset, account, landId, farmId, tokenId);
    require(allStakings[key].timestamp == 0, "Already staked");

    if (asset == address(buildings)) {
      uint256 currentLevel = getBuildingLevel(account, landId, farmId, tokenId / 10);
      uint256 level = tokenId % 10 + 1;
      if (currentLevel > level) {
        revert("You already have a building bigger than this");
      }
      if (currentLevel > 0) {
        uint256 currentTokenId = 10 * (tokenId / 10) + currentLevel - 1;
        bytes32 currentKey = getKey(asset, account, landId, farmId, currentTokenId);
        Staking memory staking = allStakings[currentKey];
        require(staking.owner == account, "Wrong account on replacement");
        removeStakedToken(asset, account, landId, farmId, currentTokenId);
        IERC1155(asset).safeTransferFrom(address(this), account, currentTokenId, 1, "");
      }
    }

    bool is1555 = assetIs1155(asset);
    addStakedToken(asset, account, landId, farmId, tokenId);

    if (is1555) {
      IERC1155(asset).safeTransferFrom(account, address(this), tokenId, 1, "");
    } else {
      IERC721(asset).transferFrom(account, address(this), tokenId);
    }
    reentrancyGuard = 1;
  }

  function unstake(address asset, address account, uint256 landId, uint256 farmId, uint256 tokenId) public {
    require(!paused, "Paused");
    require(reentrancyGuard == 1, "Reentrancy");
    reentrancyGuard = 2;
    require(validator.canUnstake(asset, account, landId, farmId, tokenId), "Incorrect asset");
    require(account == msg.sender || isApprovedForAll[account][msg.sender], "Unauthorized");
    bytes32 key = getKey(asset, account, landId, farmId, tokenId);
    require(allStakings[key].timestamp > 0, "You don't have that token");
    bool is1555 = assetIs1155(asset);

    removeStakedToken(asset, account, landId, farmId, tokenId);
    if (is1555) {
      IERC1155(asset).safeTransferFrom(address(this), account, tokenId, 1, "");
    } else {
      IERC721(asset).transferFrom(address(this), account, tokenId);
    }
    reentrancyGuard = 1;
  }

  function multiStake(address asset, address account, uint256 landId, uint256 farmId, uint256[] calldata tokenIds) public {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      stake(asset, account, landId, farmId, tokenIds[i]);
    }
  }

  function multiUnstake(address asset, address account, uint256 landId, uint256 farmId, uint256[] calldata tokenIds) public {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      unstake(asset, account, landId, farmId, tokenIds[i]);
    }
  }

  function setApprovalForAll(address operator, bool isApproved) public {
    isApprovedForAll[msg.sender][operator] = isApproved;
  }

  function mergeBuilding(uint256 landId, address account, uint256 farmId, uint256 tokenId) public {
    require(account == msg.sender || isApprovedForAll[account][msg.sender], "Unauthorized");
    bytes32 key = getKey(address(buildings), account, landId, farmId, tokenId);
    require(allStakings[key].timestamp > 0, "You must have this token staked");

    buildings.safeTransferFrom(account, address(this), tokenId, 1, "");
    removeStakedToken(address(buildings), account, landId, farmId, tokenId);
    buildings.merge(tokenId);
    addStakedToken(address(buildings), account, landId, farmId, tokenId + 1);
  }

  function addStakedToken(address asset, address account, uint256 landId, uint256 farmId, uint256 tokenId) internal {
    bytes32 key = getKey(asset, account, landId, farmId, tokenId);
    allStakings[key] = Staking(uint64(landId), uint8(farmId), account, asset, uint32(tokenId), uint64(block.timestamp));
    stakingsByUser[account].push(key);
    if (asset == address(foxHen)) {
      if (foxHen.isFox(tokenId)) {
        foxCount[account][landId][farmId]++;
      } else {
        henCount[account][landId][farmId]++;
      }
    } else if (asset == address(farmer)) {
      farmerCount[account][landId][farmId]++;
    }
  }

  function removeStakedToken(address asset, address account, uint256 landId, uint256 farmId, uint256 tokenId) internal {
    bytes32 key = getKey(asset, account, landId, farmId, tokenId);
    delete allStakings[key];
    bytes32[] storage keys = stakingsByUser[account];
    for (uint16 i = 0; i < keys.length; i++) {
      if (keys[i] == key) {
        keys[i] = keys[keys.length - 1];
        keys.pop();
        break;
      }
    }
    if (asset == address(foxHen)) {
      if (foxHen.isFox(tokenId)) {
        foxCount[account][landId][farmId]--;
      } else {
        henCount[account][landId][farmId]--;
      }
    } else if (asset == address(farmer)) {
      farmerCount[account][landId][farmId]--;
    }
  }

  function addAllowedAsset(address asset) public onlyOwner {
    allowedAssets.push(asset);
  }

  function removeAllowedAsset(address asset) public onlyOwner {
    for (uint16 i = 0; i < allowedAssets.length; i++) {
      if (allowedAssets[i] == asset) {
        allowedAssets[i] = allowedAssets[allowedAssets.length - 1];
        allowedAssets.pop();
      }
    }
  }

  function setStakerValidator(address _address) public onlyOwner {
    validator = StakerValidator(_address);
  }

  function setPaused(bool _p) public onlyOwner {
    paused = _p;
  }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "./Handlers.sol";
import "./FarmStaker.sol";
import "./PolyFarmer.sol";
import "./PolyBuildings.sol";
import "./Corn.sol";
import "./Eggs.sol";

contract FarmEnergy is Handlers {
  FarmStaker staker;
  PolyFarmer polyFarmers;
  Corn corn;
  Eggs eggs;
      //  account =>       landId =>       farmId
  mapping(address=>mapping(uint64=>mapping(uint8=>uint256))) public energy;
  mapping(address=>mapping(uint64=>mapping(uint8=>uint256))) public rechargeTimestamp;
  mapping(address=>mapping(uint64=>mapping(uint8=>bytes32[]))) public farmers;
  
  uint256[] public farmersPerLevel = [1, 2, 3, 5, 7, 9, 11, 13, 15, 17, 20];
  uint8[] public cornCost = [5, 5, 5, 4, 4, 3, 3, 2, 2, 1, 1];
  uint256 public timeoutPeriod = 1 days;

  constructor(address _staker, address _polyFarmers, address _corn, address _eggs) {
    staker = FarmStaker(_staker);
    polyFarmers = PolyFarmer(_polyFarmers);
    corn = Corn(_corn);
    eggs = Eggs(_eggs);
    eggs.approve(msg.sender, type(uint256).max);
  }

  function checkFarmers(address account, uint64 landId, uint8 farmId, bytes32[] memory keys) internal view {
    for (uint256 i = 0; i < keys.length; i++) {
      (uint64 l, uint8 f, address owner, address asset,,) = staker.allStakings(keys[i]);
      require(asset == address(polyFarmers), "Wrong key");
      require(l == landId && f == farmId, "Wrong farm");
      require(owner == account, "You must own that token");
    }
  }

  function energyPerFarmers(uint256 farmerCount) public pure returns (uint256) {
    return 2 + farmerCount;
  }

  function rechargeEnergy(uint64 landId, uint8 farmId, bytes32[] memory keys) public {
    require(block.timestamp - rechargeTimestamp[msg.sender][landId][farmId] > timeoutPeriod, "Not enough time has passed");
    uint256 houseLevel = staker.getBuildingLevel(msg.sender, landId, farmId, uint256(BuildingTypes.HOUSE));
    require(houseLevel < 11, "Incorrect level");
    uint256 maxFarmers = farmersPerLevel[houseLevel];
    require(keys.length > 0 && keys.length <= maxFarmers, "Incorrect number of farmers");

    uint256 cornDue = keys.length * 1 ether * cornCost[houseLevel];
    uint256 eggsDue = cornDue / 5;

    checkFarmers(msg.sender, landId, farmId, keys);

    corn.burn(msg.sender, cornDue);
    eggs.transferFrom(msg.sender, address(this), eggsDue);

    energy[msg.sender][landId][farmId] = energyPerFarmers(keys.length);
    rechargeTimestamp[msg.sender][landId][farmId] = block.timestamp;
    farmers[msg.sender][landId][farmId] = keys;
  }

  function spendEnergy(address account, uint64 landId, uint8 farmId) public isHandler {
    checkFarmers(account, landId, farmId, farmers[account][landId][farmId]);
    uint256 diff = block.timestamp - rechargeTimestamp[account][landId][farmId];
    require(energy[account][landId][farmId] > 0 && diff < timeoutPeriod, "Not enough energy");
    energy[account][landId][farmId]--;
  }

  function setTimeoutPeriod(uint256 _t) public onlyOwner {
    timeoutPeriod = _t;
  }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "./Handlers.sol";
import "./FarmStaker.sol";
import "./PolyBuildings.sol";
import "./Corn.sol";
import "./FarmEnergy.sol";
import "./Realtor.sol";

contract FarmCrops is Handlers {
  FarmStaker staker;
  Realtor realtor;
  Corn corn;
  FarmEnergy energy;

  uint256 public seedsPerLine = 20 ether;
  uint256 public multiplier = 10;
  uint256 public timeoutPeriod = 12 hours;
  mapping(address=>mapping(address=>bool)) public isApprovedForAll;

  struct PlotStatus {
    uint128 timestamp;
    uint8 status;
    uint64 stolen;
  }

  //      account=>        landId=>         farmId=>         plot=>   Status
  mapping(address=>mapping(uint256=>mapping(uint256=>mapping(uint256=>PlotStatus)))) public plotStatus;

  struct Crop {
    address account;
    uint64 landId;
    uint8 farmId;
    uint8 plot;
  }

  Crop[] public crops;

  event Harvest(address indexed account, uint256 indexed landId, uint256 indexed farmId, uint256 collected, uint256 stolen);

  constructor (address _staker, address _realtor, address _corn, address _energy) {
    staker = FarmStaker(_staker);
    realtor = Realtor(_realtor);
    corn = Corn(_corn);
    energy = FarmEnergy(_energy);
  }

  function getAllCrops(address account, uint256 landId, uint256 farmId) public view returns (PlotStatus[] memory) {
    uint256 fieldLevel = staker.getBuildingLevel(account, landId, farmId, uint256(BuildingTypes.CROPS));
    if (fieldLevel == 0) {
      fieldLevel = 1;
    }
    PlotStatus[] memory plots = new PlotStatus[](fieldLevel);
    for (uint256 i = 0; i < fieldLevel; i++) {
      plots[i] = plotStatus[account][landId][farmId][i];
    }
    return plots;
  }

  function setApprovalForAll(address operator, bool isApproved) public {
    isApprovedForAll[msg.sender][operator] = isApproved;
  }

  function getCrop(uint256 index) public view returns (Crop memory, PlotStatus memory) {
    Crop memory crop = crops[index];
    PlotStatus memory status = plotStatus[crop.account][crop.landId][crop.farmId][crop.plot];
    return (crop, status);
  }

  function cropsLength() public view returns (uint256) {
    return crops.length;
  }

  function getFirstEmptyPlot(address account, uint256 landId, uint256 farmId) public view returns (uint256) {
    for (uint256 i = 0; i < 10; i++) {
      if (plotStatus[account][landId][farmId][i].status == 0) {
        return i;
      }
    }
    return 10;
  }

  function getFirstReadyPlot(address account, uint256 landId, uint256 farmId) public view returns (uint256) {
    for (uint256 i = 0; i < 10; i++) {
      PlotStatus memory plot = plotStatus[account][landId][farmId][i];
      if (plot.status == 4 && block.timestamp - uint256(plot.timestamp) > timeoutPeriod) {
        return i;
      }
    }
    return 10;
  }

  function getNthReadyPlots(address account, uint256 landId, uint256 farmId, uint256 amount) public view returns (uint256[] memory) {
    uint256[] memory plots = new uint256[](amount);
    uint256 lastPlot;
    for (uint256 i = 0; i < amount; i++) {
      for (uint256 j = lastPlot; j < 10; j++) {
        PlotStatus memory plot = plotStatus[account][landId][farmId][j];
        if (plot.status == 4 && block.timestamp - uint256(plot.timestamp) > timeoutPeriod) {
          lastPlot = j;
          plots[i] = j;
        }
      }
    }

    return plots;
  }

  function getCropIndex(address account, uint64 landId, uint8 farmId, uint8 plot) public view returns (uint256) {
    for (uint256 i = 0; i < crops.length; i++) {
      Crop memory crop = crops[i];
      if (crop.account == account && crop.landId == landId && crop.farmId == farmId && crop.plot == plot) {
        return i;
      }
    }
    revert();
  }

  function getCropIndexes(address account, uint64 landId, uint8 farmId, uint8[] calldata plots) public view returns (uint256[] memory) {
    uint256[] memory indexes = new uint256[](plots.length);
    for (uint256 i = 0; i < plots.length; i++) {
      indexes[i] = getCropIndex(account, landId, farmId, plots[i]);
    }
    return indexes;
  }

  function plantSeeds(address account, uint256 landId, uint256 farmId, uint256 plot) public {
    require(account == msg.sender || isApprovedForAll[account][msg.sender], "Unauthorized");
    uint256 fieldLevel = staker.getBuildingLevel(account, landId, farmId, uint256(BuildingTypes.CROPS));
    require(plot == 0 || plot < fieldLevel, "You don't have available plots");
    require(plotStatus[account][landId][farmId][plot].status == 0, "Plot must be unplanted");
    uint256 seeds = fieldLevel == 0 ? seedsPerLine / 2 : seedsPerLine;

    energy.spendEnergy(account, uint64(landId), uint8(farmId));
    corn.burn(account, seeds);
    plotStatus[account][landId][farmId][plot] = PlotStatus(uint128(block.timestamp), 1, 0);
    crops.push(Crop(account, uint64(landId), uint8(farmId), uint8(plot)));
  }

  function multiPlant(address account, uint256 landId, uint256 farmId, uint256[] calldata plotIds) public {
    for (uint256 i = 0; i < plotIds.length; i++) {
      plantSeeds(account, landId, farmId, plotIds[i]);
    }
  }

  function waterPlants(address account, uint256 landId, uint256 farmId, uint256[] calldata plotIds) public {
    require(account == msg.sender || isApprovedForAll[account][msg.sender], "Unauthorized");
    uint256 fieldLevel = staker.getBuildingLevel(account, landId, farmId, uint256(BuildingTypes.CROPS));
    uint256 wellLevel = staker.getBuildingLevel(account, landId, farmId, uint256(BuildingTypes.WELL));

    if (wellLevel == 0) {
      require(fieldLevel == 0, "You must upgrade your well");
    } else {
      require(plotIds.length <= wellLevel, "You can't water that many crops with your well");
    }

    energy.spendEnergy(account, uint64(landId), uint8(farmId));
    for (uint256 i = 0; i < plotIds.length; i++) {
      PlotStatus storage plot = plotStatus[account][landId][farmId][plotIds[i]];
      require((block.timestamp - uint256(plot.timestamp)) > timeoutPeriod && plot.status < 4 && plot.status > 0, "Plot can't be watered");
      plot.timestamp = uint128(block.timestamp);
      plot.status++;
    }
  }

  function harvest(address account, uint256 landId, uint256 farmId, uint256 plotIndex, uint256 cropIndex) public {
    require(account == msg.sender || isApprovedForAll[account][msg.sender], "Unauthorized");
    uint256 fieldLevel = staker.getBuildingLevel(account, landId, farmId, uint256(BuildingTypes.CROPS));
    uint256 siloLevel = staker.getBuildingLevel(account, landId, farmId, uint256(BuildingTypes.SILO));
    require(plotIndex <= fieldLevel, "There's no plot ready to harvest");
    PlotStatus storage plot = plotStatus[account][landId][farmId][plotIndex];
    require(plot.status == 4 && block.timestamp - uint256(plot.timestamp) > timeoutPeriod, "Plot not ready");

    Crop storage crop = crops[cropIndex];
    require(crop.account == account && crop.landId == uint64(landId) && crop.farmId == uint8(farmId) && crop.plot == uint8(plotIndex), "Incorrect crop");

    uint256 siloMultiplier = 100 + siloLevel * 3;
    uint256 reward = fieldLevel == 0 ? (seedsPerLine / 2) * multiplier : seedsPerLine * multiplier;
    reward = reward * siloMultiplier / 100;

    uint256 stolen = reward * plot.stolen / 100;
    reward -= stolen;

    uint256 rent = realtor.payRent(msg.sender, landId, farmId, address(corn), reward);
    reward -= rent;

    energy.spendEnergy(account, uint64(landId), uint8(farmId));
    plot.status = 0;

    crops[cropIndex] = crops[crops.length - 1];
    crops.pop();

    corn.mint(account, reward);
    emit Harvest(account, landId, farmId, reward, stolen);
  }

  function multiHarvest(address account, uint256 landId, uint256 farmId, uint256[] calldata plotIndexes, uint256[] calldata cropIndexes) public {
    require(plotIndexes.length == cropIndexes.length, "Both array parameters must have same size");
    for (uint256 i = 0; i < plotIndexes.length; i++) {
      harvest(account, landId, farmId, plotIndexes[i], cropIndexes[i]);
    }
  }

  function getRaided(address account, uint256 landId, uint256 farmId, uint256 plotIndex, uint256 amount) public isHandler {
    PlotStatus storage plot = plotStatus[account][landId][farmId][plotIndex];
    plot.stolen = uint64(amount);    
  }

  function setSeedsPerLine(uint256 _s) public onlyOwner {
    seedsPerLine = _s;
  }

  function setMultiplier(uint256 _m) public onlyOwner {
    multiplier = _m;
  }

  function setEnergyContract(address _energy) public onlyOwner {
    energy = FarmEnergy(_energy);
  }

  function setTimeoutPeriod(uint256 _p) public onlyOwner {
    timeoutPeriod = _p;
  }

  function setRealtorContract(address _realtor) public onlyOwner {
    realtor = Realtor(_realtor);
  }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract Eggs is ERC20 {
  constructor() ERC20("EGG", "EGG") {
    _mint(msg.sender, 5000000 ether);
  }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "./Handlers.sol";

contract Corn is ERC20, Handlers {
  constructor() ERC20("CORN", "CORN") {}

  function mint(address account, uint256 amount) public isHandler {
    _mint(account, amount);
  }

  function burn(address account, uint256 amount) public {
    if (msg.sender != account) {
      uint256 allow = allowance(account, msg.sender);
      require(allow >= amount, "Unauthorized");
      _approve(account, msg.sender, allow - amount);
    }
    _burn(account, amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT

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
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
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
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][account] = accountBalance - amount;
            }
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import 'openzeppelin-solidity/contracts/token/ERC721/IERC721.sol';
import 'openzeppelin-solidity/contracts/token/ERC721/IERC721Receiver.sol';
import 'openzeppelin-solidity/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import 'openzeppelin-solidity/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import 'openzeppelin-solidity/contracts/utils/Address.sol';
import 'openzeppelin-solidity/contracts/utils/Context.sol';
import 'openzeppelin-solidity/contracts/utils/Strings.sol';
import 'openzeppelin-solidity/contracts/utils/introspection/ERC165.sol';

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintedQueryForZeroAddress();
error BurnedQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerIndexOutOfBounds();
error OwnerQueryForNonexistentToken();
error TokenIndexOutOfBounds();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**128 - 1 (max value of uint128).
 */
contract ERC721A is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using Address for address;
    using Strings for uint256;

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
    }

    // Compiler will pack the following 
    // _currentIndex and _burnCounter into a single 256bit word.
    
    // The tokenId of the next token to be minted.
    uint128 internal _currentIndex;

    // The number of tokens burned.
    uint128 internal _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex times
        unchecked {
            return _currentIndex - _burnCounter;    
        }
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
     * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        uint256 numMintedSoFar = _currentIndex;
        uint256 tokenIdsIdx;

        // Counter overflow is impossible as the loop breaks when
        // uint256 i is equal to another uint256 numMintedSoFar.
        unchecked {
            for (uint256 i; i < numMintedSoFar; i++) {
                TokenOwnership memory ownership = _ownerships[i];
                if (!ownership.burned) {
                    if (tokenIdsIdx == index) {
                        return i;
                    }
                    tokenIdsIdx++;
                }
            }
        }
        revert TokenIndexOutOfBounds();
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
     * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        if (index >= balanceOf(owner)) revert OwnerIndexOutOfBounds();
        uint256 numMintedSoFar = _currentIndex;
        uint256 tokenIdsIdx;
        address currOwnershipAddr;

        // Counter overflow is impossible as the loop breaks when
        // uint256 i is equal to another uint256 numMintedSoFar.
        unchecked {
            for (uint256 i; i < numMintedSoFar; i++) {
                TokenOwnership memory ownership = _ownerships[i];
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    if (tokenIdsIdx == index) {
                        return i;
                    }
                    tokenIdsIdx++;
                }
            }
        }

        // Execution should never reach this point.
        revert();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    function _numberMinted(address owner) internal view returns (uint256) {
        if (owner == address(0)) revert MintedQueryForZeroAddress();
        return uint256(_addressData[owner].numberMinted);
    }

    function _numberBurned(address owner) internal view returns (uint256) {
        if (owner == address(0)) revert BurnedQueryForZeroAddress();
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    // Invariant: 
                    // There will always be an ownership that has an address and is not burned 
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return ownershipOf(tokenId).addr;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public override {
        if (operator == _msgSender()) revert ApproveToCaller();

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < _currentIndex && !_ownerships[tokenId].burned;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity, _data, true);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address to,
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 3.4e38 (2**128) - 1
        // updatedIndex overflows if _currentIndex + quantity > 3.4e38 (2**128) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;

            for (uint256 i; i < quantity; i++) {
                emit Transfer(address(0), to, updatedIndex);
                if (safe && !_checkOnERC721Received(address(0), to, updatedIndex, _data)) {
                    revert TransferToNonERC721ReceiverImplementer();
                }
                updatedIndex++;
            }

            _currentIndex = uint128(updatedIndex);
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
            isApprovedForAll(prevOwnership.addr, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**128.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            _ownerships[tokenId].addr = to;
            _ownerships[tokenId].startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            if (_ownerships[nextTokenId].addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId < _currentIndex) {
                    _ownerships[nextTokenId].addr = prevOwnership.addr;
                    _ownerships[nextTokenId].startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        _beforeTokenTransfers(prevOwnership.addr, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**128.
        unchecked {
            _addressData[prevOwnership.addr].balance -= 1;
            _addressData[prevOwnership.addr].numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            _ownerships[tokenId].addr = prevOwnership.addr;
            _ownerships[tokenId].startTimestamp = uint64(block.timestamp);
            _ownerships[tokenId].burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            if (_ownerships[nextTokenId].addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId < _currentIndex) {
                    _ownerships[nextTokenId].addr = prevOwnership.addr;
                    _ownerships[nextTokenId].startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(prevOwnership.addr, address(0), tokenId);
        _afterTokenTransfers(prevOwnership.addr, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked { 
            _burnCounter++;
        }
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert TransferToNonERC721ReceiverImplementer();
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer()
    external
    view
    returns (
      int256
    );
  
  function latestTimestamp()
    external
    view
    returns (
      uint256
    );

  function latestRound()
    external
    view
    returns (
      uint256
    );

  function getAnswer(
    uint256 roundId
  )
    external
    view
    returns (
      int256
    );

  function getTimestamp(
    uint256 roundId
  )
    external
    view
    returns (
      uint256
    );

  event AnswerUpdated(
    int256 indexed current,
    uint256 indexed roundId,
    uint256 updatedAt
  );

  event NewRound(
    uint256 indexed roundId,
    address indexed startedBy,
    uint256 startedAt
  );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

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
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
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
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}