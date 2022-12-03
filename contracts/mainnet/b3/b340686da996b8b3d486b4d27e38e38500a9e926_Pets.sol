/**
 *Submitted for verification at polygonscan.com on 2022-12-03
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AccessControl {
    address payable public creatorAddress;
    uint16 public totalSeraphims = 0;
    mapping(address => bool) public seraphims;

    modifier onlyCREATOR() {
        require(
            msg.sender == creatorAddress,
            'You are not the contract creator'
        );
        _;
    }

    modifier onlySERAPHIM() {
        require(
            seraphims[msg.sender] == true,
            'You do not have permission to do this'
        );
        _;
    }

    // Constructor
    constructor() {
        creatorAddress = payable(msg.sender);
    }

    function addSERAPHIM(address _newSeraphim) public onlyCREATOR {
        if (seraphims[_newSeraphim] == false) {
            seraphims[_newSeraphim] = true;
            totalSeraphims += 1;
        }
    }

    function removeSERAPHIM(address _oldSeraphim) public onlyCREATOR {
        if (seraphims[_oldSeraphim] == true) {
            seraphims[_oldSeraphim] = false;
            totalSeraphims -= 1;
        }
    }

    function changeOwner(address payable _newOwner) public onlyCREATOR {
        creatorAddress = _newOwner;
    }
}

abstract contract IHalo {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual returns (bool);
}

abstract contract IABToken is AccessControl {
    function ownerOf(uint256 tokenId) public view virtual returns (address);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual;

    function mintABToken(
        address owner,
        uint8 _cardSeriesId,
        uint16 _power,
        uint16 _auraRed,
        uint16 _auraYellow,
        uint16 _auraBlue,
        string memory _name,
        uint16 _experience
    ) public virtual;

    function getABToken(uint256 tokenId)
        public
        view
        virtual
        returns (
            uint8 cardSeriesId,
            uint16 power,
            uint16 auraRed,
            uint16 auraYellow,
            uint16 auraBlue,
            string memory name,
            uint16 experience,
            uint64 lastBattleTime,
            address owner,
            uint16 oldId
        );

    function getBreedingCount(uint256 tokenId)
        public
        view
        virtual
        returns (uint8);

    function incrementBreedingCount(uint256 tokenId) external virtual;

    function getLastBreedingTime(uint256 tokenId)
        public
        view
        virtual
        returns (uint64);

    function setLastBreedingTime(uint256 tokenId) external virtual;
}

contract Pets is AccessControl {
    // Addresses for other contracts Pets interacts with.

    address public ABTokenDataContract = address(0);

    address public HaloContract = address(0);

    address public deadAddress = 0x000000000000000000000000000000000000dEaD;
    uint16 public maxRetireAura = 30;
    uint16 public minRetireAura = 10;

    uint64 public breedingDelay = 86400;
    uint256 public breedingPrice = 20000000000000000000;
    uint8 public upgradeChance = 25;

    uint8 public auraIncrease = 20;
    uint8 public auraDecrease = 5;

    uint8 public auraIncreaseChance = 75;

    /*** DATA TYPES ***/

    //Main ABCard Struct, but only using values used in this contract.
    struct ABCard {
        uint256 tokenId;
        uint8 cardSeriesId;
        //This is 0 to 23 for angels, 24 to 42 for pets, 43 to 60 for accessories, 61 to 72 for medals
        uint16 power;
        //This number is luck for pets and battlepower for angels
        uint16 auraRed;
        uint16 auraYellow;
        uint16 auraBlue;
        //string name;
        uint8 breedCount;
        uint64 lastBreedingTime;
    }

    function getRandomNumber(
        uint16 maxRandom,
        uint8 min,
        address privateAddress
    ) public view returns (uint8) {
        uint256 genNum = uint256(
            keccak256(abi.encodePacked(block.timestamp, privateAddress))
        );
        return uint8((genNum % (maxRandom - min + 1)) + min);
    }

    // write functions
    function DataContacts(address _ABTokenDataContract, address _HaloContract)
        external
        onlyCREATOR
    {
        ABTokenDataContract = _ABTokenDataContract;
        HaloContract = _HaloContract;
    }

    function setParameters(
        uint16 _minRetireAura,
        uint16 _maxRetireAura,
        uint64 _breedingDelay,
        uint256 _breedingPrice,
        uint8 _upgradeChance,
        uint8 _auraIncrease,
        uint8 _auraDecrease,
        uint8 _auraIncreaseChance
    ) external onlyCREATOR {
        minRetireAura = _minRetireAura;
        maxRetireAura = _maxRetireAura;
        breedingDelay = _breedingDelay;
        breedingPrice = _breedingPrice;
        upgradeChance = _upgradeChance;
        auraIncrease = _auraIncrease;
        auraDecrease = _auraDecrease;
        auraIncreaseChance = _auraIncreaseChance;
    }

    function getParameters()
        external
        view
        returns (
            uint16 _minRetireAura,
            uint16 _maxRetireAura,
            uint64 _breedingDelay,
            uint256 _breedingPrice,
            uint8 _upgradeChance,
            uint8 _auraIncrease,
            uint8 _auraDecrease
        )
    {
        _minRetireAura = minRetireAura;
        _maxRetireAura = maxRetireAura;
        _breedingDelay = breedingDelay;
        _breedingPrice = breedingPrice;
        _upgradeChance = upgradeChance;
        _auraIncrease = auraIncrease;
        _auraDecrease = auraDecrease;
    }

    //721 Retirement Functions
    //////////////////////////////////////////////////
    function checkPet(uint256 petId) private view returns (uint8) {
        IABToken ABTokenData = IABToken(ABTokenDataContract);
        //check if a pet both exists and is owned by the message sender.
        // This function also returns the petcardSeriesID.

        uint8 petCardSeriesId;

        (petCardSeriesId, , , , , , , , , ) = ABTokenData.getABToken(petId);
        if (ABTokenData.ownerOf(petId) != msg.sender) {
            return 0;
        }
        return petCardSeriesId;
    }

    function retirePets(
        uint256 pet1,
        uint256 pet2,
        uint256 pet3,
        uint256 pet4,
        uint256 pet5,
        uint256 pet6
    ) public {
        // Send this function the petIds of 6 of your (2 star pets) to receive 1 three star pet.
        // Send this function the petIds of 6 of your (3 star pets) to receive 1 four star pet.

        IABToken ABTokenData = IABToken(ABTokenDataContract);

        require(
            checkPet(pet1) >= 28 && checkPet(pet1) <= 35,
            'There was an issue with pet 1'
        );
        require(
            checkPet(pet2) >= 28 && checkPet(pet2) <= 35,
            'There was an issue with pet 2'
        );
        require(
            checkPet(pet3) >= 28 && checkPet(pet3) <= 35,
            'There was an issue with pet 3'
        );
        require(
            checkPet(pet4) >= 28 && checkPet(pet4) <= 35,
            'There was an issue with pet 4'
        );
        require(
            checkPet(pet5) >= 28 && checkPet(pet5) <= 35,
            'There was an issue with pet 5'
        );
        require(
            checkPet(pet6) >= 28 && checkPet(pet6) <= 35,
            'There was an issue with pet 6'
        );

        uint8 _newLuck = getRandomNumber(39, 30, msg.sender);
        uint8 base = 32; // 3-star pet
        if (
            (checkPet(pet1) > 31) &&
            (checkPet(pet2) > 31) &&
            (checkPet(pet3) > 31) &&
            (checkPet(pet4) > 31) &&
            (checkPet(pet5) > 31) &&
            (checkPet(pet6) > 31)
        ) {
            //Case of all 3 star pets, so send a 4 star pet.
            _newLuck = getRandomNumber(49, 40, msg.sender);
            base = 36; // 4-star pet
        }
        //Note, user MUST approve contract address on this address.
        ABTokenData.transferFrom(msg.sender, deadAddress, pet1);
        ABTokenData.transferFrom(msg.sender, deadAddress, pet2);
        ABTokenData.transferFrom(msg.sender, deadAddress, pet3);
        ABTokenData.transferFrom(msg.sender, deadAddress, pet4);
        ABTokenData.transferFrom(msg.sender, deadAddress, pet5);
        ABTokenData.transferFrom(msg.sender, deadAddress, pet6);

        getNewPetCard(getRandomNumber(base + 3, base, msg.sender), _newLuck);
    }

    function getNewPetCard(uint8 seriesId, uint8 _luck) private {
        uint16 _auraRed = getRandomNumber(
            maxRetireAura,
            uint8(minRetireAura),
            msg.sender
        );
        uint16 _auraYellow = getRandomNumber(
            maxRetireAura,
            uint8(minRetireAura),
            msg.sender
        );
        uint16 _auraBlue = getRandomNumber(
            maxRetireAura,
            uint8(minRetireAura),
            msg.sender
        );

        IABToken ABTokenData = IABToken(ABTokenDataContract);

        //create the new one.
        ABTokenData.mintABToken(
            msg.sender,
            seriesId,
            _luck,
            _auraRed,
            _auraYellow,
            _auraBlue,
            'Lucky',
            0
        );
    }

    ////////////////////////////////////////////////////////////////////////////////////////////
    // Breeding Functions //////
    ////////////////////////////////////////////////////////////////////////////////////////////
    function BreedElemental(
        uint16 newPetRed,
        uint16 newPetYellow,
        uint16 newPetBlue
    ) private {
        //find the largest aura
        uint16 largest = newPetRed;
        uint8 petCardSeriesId = 40;

        if ((newPetYellow) > largest) {
            petCardSeriesId = 42;
        }
        if ((newPetBlue) > largest) {
            petCardSeriesId = 41;
        }

        IABToken ABTokenData = IABToken(ABTokenDataContract);
        uint8 newPetPowerToCreate = getRandomNumber(59, 50, msg.sender);

        //Set Results
        ABTokenData.mintABToken(
            msg.sender,
            petCardSeriesId,
            newPetPowerToCreate,
            newPetRed,
            newPetYellow,
            newPetBlue,
            'lucky',
            0
        );
    }

    function Breed(uint256 pet1Id, uint256 pet2Id) external {
        //Link to the data contract.
        IABToken ABTokenData = IABToken(ABTokenDataContract);
        IHalo Halo = IHalo(HaloContract);

        // Burn the halo tokens. Will fail if not enough tokens
        // or if token not approved.
        Halo.transferFrom(msg.sender, deadAddress, breedingPrice);

        //check if breeding function has improper parameters

        //can't breed someone else's pets.
        require(
            ABTokenData.ownerOf(pet1Id) == msg.sender &&
                ABTokenData.ownerOf(pet2Id) == msg.sender,
            'You can only breed pets you own'
        );

        require(pet1Id != pet2Id, 'Pets cannot breed with themselves');

        ABCard memory pet1;
        (
            pet1.cardSeriesId,
            ,
            pet1.auraRed,
            pet1.auraYellow,
            pet1.auraBlue,
            ,
            ,
            ,
            ,

        ) = ABTokenData.getABToken(pet1Id);
        pet1.breedCount = ABTokenData.getBreedingCount(pet1Id);
        require(pet1.breedCount < 6, 'Pet 1 cannot breed more than 5 times');
        pet1.lastBreedingTime = ABTokenData.getLastBreedingTime(pet1Id);

        ABCard memory pet2;
        (
            pet2.cardSeriesId,
            ,
            pet2.auraRed,
            pet2.auraYellow,
            pet2.auraBlue,
            ,
            ,
            ,
            ,

        ) = ABTokenData.getABToken(pet2Id);
        pet2.breedCount = ABTokenData.getBreedingCount(pet2Id);
        require(pet2.breedCount < 6, 'Pet 2 cannot breed more than 5 times');
        pet2.lastBreedingTime = ABTokenData.getLastBreedingTime(pet2Id);

        require(
            block.timestamp >= (pet1.lastBreedingTime + breedingDelay) &&
                block.timestamp >= (pet2.lastBreedingTime + breedingDelay),
            'At least one of your pets needs to wait to breed'
        );

        //set now to avoid reentrancy.
        ABTokenData.setLastBreedingTime(pet1Id);
        ABTokenData.setLastBreedingTime(pet2Id);
        ABTokenData.incrementBreedingCount(pet1Id);
        ABTokenData.incrementBreedingCount(pet2Id);

        require(
            (pet1.cardSeriesId >= 24) &&
                (pet1.cardSeriesId < 40) &&
                (pet2.cardSeriesId >= 24) &&
                (pet2.cardSeriesId < 40),
            'Only pets can breed'
        );

        uint16 newPetRed = findAuras(pet1.auraRed, pet2.auraRed, 100);
        uint16 newPetYellow = findAuras(pet1.auraYellow, pet2.auraYellow, 99);
        uint16 newPetBlue = findAuras(pet1.auraBlue, pet2.auraBlue, 101);

        uint8 petPowerToCreate = getNewPetPower(
            pet1.cardSeriesId,
            pet2.cardSeriesId
        );

        if (petPowerToCreate > 50) {
            BreedElemental(newPetRed, newPetYellow, newPetBlue);
        } else {
            uint8 petSeriesIDtoCreate = getNewPetSeries(
                pet1.cardSeriesId,
                pet2.cardSeriesId,
                petPowerToCreate
            );

            //Set Results
            ABTokenData.mintABToken(
                msg.sender,
                petSeriesIDtoCreate,
                petPowerToCreate,
                newPetRed,
                newPetYellow,
                newPetBlue,
                'lucky',
                0
            );
        }
    }

    function getNewPetPower(uint8 pet1CardSeries, uint8 pet2CardSeries)
        public
        view
        returns (uint8)
    {
        uint8 upgradeRand = getRandomNumber(100, 0, msg.sender) + 1;
        uint8 petPowerRand = getRandomNumber(8, 0, msg.sender) + 1;

        //Get the number of pet stars
        uint8 pet1CardStars = ((pet1CardSeries - 24) / 4) + 1;
        uint8 pet2CardStars = ((pet2CardSeries - 24) / 4) + 1;

        // minimum is 1 stars
        uint8 newPetPower = 10 + petPowerRand;

        // create 2 star pet
        if (pet1CardStars + pet2CardStars >= 4) {
            newPetPower += 10;
        }

        // create 3 star pet
        if (pet1CardStars + pet2CardStars >= 6) {
            newPetPower += 10;
        }

        // create 4 star pet
        if (pet1CardStars + pet2CardStars >= 8) {
            newPetPower += 10;
        }

        // go up one more line if upgrade
        if (upgradeRand < upgradeChance) {
            newPetPower += 10;
        }

        return newPetPower;
    }

    function getNewPetLine(uint8 pet1CardSeries, uint8 pet2CardSeries)
        public
        view
        returns (uint8)
    {
        if (getRandomNumber(100, 1, msg.sender) <= 50) {
            return (pet1CardSeries % 4) + 1;
        } else {
            return (pet2CardSeries % 4) + 1;
        }
    }

    ////////////////

    function getNewPetSeries(
        uint8 pet1CardSeries,
        uint8 pet2CardSeries,
        uint16 newPetPower
    ) private view returns (uint8) {
        uint8 newPetLine = getNewPetLine(pet1CardSeries, pet2CardSeries);

        // 2 stars
        if (newPetPower < 30) {
            return (27 + newPetLine);
        }
        // 3 stars
        else if (newPetPower < 40) {
            return (31 + newPetLine);
        }
        // 4 stars
        else if (newPetPower >= 40) {
            return (35 + newPetLine);
        }
        // error condition
        return 0;
    }

    // Start with average aura of parents. With auraIncreaseChance, increase aura a random
    // amount between 1 and auraIncrease. Otherwise, decrease a random amount between 0
    // and decreaseChance.
    function findAuras(
        uint16 pet1Aura,
        uint16 pet2Aura,
        uint8 colorChance
    ) private view returns (uint16) {
        uint16 averagePetAuras = (pet1Aura + pet2Aura) / 2;
        if (getRandomNumber(colorChance, 1, msg.sender) <= auraIncreaseChance) {
            return (averagePetAuras +
                getRandomNumber(auraIncrease, 1, msg.sender));
        }

        uint8 decreaseAmount = getRandomNumber(auraDecrease, 0, msg.sender);

        if ((decreaseAmount + 2) < (averagePetAuras)) {
            return averagePetAuras - decreaseAmount;
        } else {
            return 2; // minimum
        }
    }
}