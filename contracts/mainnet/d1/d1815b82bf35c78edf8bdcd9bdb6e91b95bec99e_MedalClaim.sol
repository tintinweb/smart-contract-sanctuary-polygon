/**
 *Submitted for verification at polygonscan.com on 2023-01-15
*/

//SPDX-License-Identifier: MIT License
pragma solidity ^0.8.0;

contract AccessControl {
    address public creatorAddress;
    uint16 public totalSeraphims = 0;
    mapping(address => bool) public seraphims;

    modifier onlyCREATOR() {
        require(msg.sender == creatorAddress, 'You are not the creator');
        _;
    }

    modifier onlySERAPHIM() {
        require(
            seraphims[msg.sender] == true,
            'This function is reserved for seraphim'
        );
        _;
    }

    // Constructor
    constructor() {
        creatorAddress = msg.sender;
    }

    //Seraphims are contracts or addresses that have write access
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

abstract contract IABToken is AccessControl {
    function ownerOf(uint256 tokenId) public view virtual returns (address);

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

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual;

    function increasePower(uint256 tokenId, uint8 _amount) external virtual;

    function setExperience(uint256 tokenId, uint16 _experience)
        external
        virtual;

    function setAuras(
        uint256 tokenId,
        uint16 _red,
        uint16 _blue,
        uint16 _yellow
    ) external virtual;
}

abstract contract IABBattleSupport {
    function getAuraCode(uint256 angelId) public view virtual returns (uint8);
}

abstract contract IBattleMtnData is AccessControl {
    function cardOnBattleMtn(uint256 Id) external view virtual returns (bool);

    function getTeamByPosition(uint8 _position)
        external
        view
        virtual
        returns (
            uint8 position,
            uint256 angelId,
            uint256 petId,
            uint256 accessoryId,
            string memory slogan
        );
}

contract MedalClaim is AccessControl {
    // Addresses for other contracts MedalClaim interacts with.
    address public ABTokenDataContract = address(0);
    address public ABBattleSupportContract = address(0);
    address public BattleMtnDataContract = address(0);

    address public DeadAddress = 0x000000000000000000000000000000000000dEaD;

    // events
    event EventMedalSuccessful(address owner, uint64 Medal);

    /*** DATA TYPES ***/
    //  Main data structure for each token
    struct ABCard {
        uint256 tokenId;
        uint8 cardSeriesId;
        //This is 0 to 23 for angels, 24 to 42 for pets, 43 to 60 for accessories, 61 to 72 for medals

        uint16 power;
        //This number is luck for pets and battlepower for angels
        uint16 auraRed;
        uint16 auraYellow;
        uint16 auraBlue;
        string name;
        uint16 experience;
        uint64 lastBattleTime;
        uint64 lastBreedingTime;
    }

    // Stores which address have claimed which medals, to avoid one address claiming the same token twice.

    mapping(address => bool[12]) public claimedbyAddress;

    //Stores which cards have been used to claim medals, to avoid transfering a key card to another account and claiming another medal.
    mapping(uint256 => bool) public onePlyClaimedAngel;
    mapping(uint256 => bool) public cardboardClaimedAngel;
    mapping(uint256 => bool) public silverClaimedAngel;
    mapping(uint256 => bool) public goldClaimedAngel;
    mapping(uint256 => bool) public diamondClaimedAngel;
    mapping(uint256 => bool) public zeroniumClaimedAngel;
    mapping(uint256 => bool) public mainClaimedPets;

    mapping(uint256 => bool) public burnedSilver;
    mapping(uint256 => bool) public burnedGold;
    mapping(uint256 => bool) public burnedPlatinum;
    mapping(uint256 => bool) public burnedPink;
    mapping(uint256 => bool) public burnedOrichalcum;
    mapping(uint256 => bool) public burnedDiamond;
    mapping(uint256 => bool) public burnedZeronium;


    // write functions
    function setDataContacts(
        address _ABTokenDataContract,
        address _ABBattleSupportContract,
        address _BattleMtnDataContract
    ) external onlyCREATOR {
        ABTokenDataContract = _ABTokenDataContract;
        ABBattleSupportContract = _ABBattleSupportContract;
        BattleMtnDataContract = _BattleMtnDataContract;
    }

    // Verify card ownership
    function checkOwner(uint256 id, address owner) public view {
        IABToken ABTokenData = IABToken(ABTokenDataContract);
        require(ABTokenData.ownerOf(id) == owner, 'Not Card Owner');
    }

    function getCardSeries(uint256 id) public view returns (uint8) {
        IABToken ABTokenData = IABToken(ABTokenDataContract);
        uint8 cardSeriesId;
        (cardSeriesId, , , , , , , , , ) = ABTokenData.getABToken(id);
        return cardSeriesId;
    }

    function claim1Ply(
        uint256 id1,
        uint256 id2,
        uint256 id3,
        uint256 id4
    ) public {
        //can only claim each medal once per address or per key card.
        require(
            !onePlyClaimedAngel[id1] &&
                !onePlyClaimedAngel[id2] &&
                !onePlyClaimedAngel[id3] &&
                !onePlyClaimedAngel[id4],
            'You have already claimed this medal'
        );

        //angelIds must be called in ORDER. This prevents computationally expensive checks to avoid duplicates.
        require(
            (id1 < id2) && (id2 < id3) && (id3 < id4),
            'Angels must be different and called in order'
        );

        checkOwner(id1, msg.sender);
        checkOwner(id2, msg.sender);
        checkOwner(id3, msg.sender);
        checkOwner(id4, msg.sender);

        IABToken ABTokenData = IABToken(ABTokenDataContract);

        uint8 cardSeriesId;

        cardSeriesId = getCardSeries(id1);
        require(cardSeriesId > 0 && cardSeriesId < 24, 'Not Angel Card');

        cardSeriesId = getCardSeries(id2);
        require(cardSeriesId > 0 && cardSeriesId < 24, 'Not Angel Card');

        cardSeriesId = getCardSeries(id3);
        require(cardSeriesId > 0 && cardSeriesId < 24, 'Not Angel Card');

        cardSeriesId = getCardSeries(id4);
        require(cardSeriesId > 0 && cardSeriesId < 24, 'Not Angel Card');

        onePlyClaimedAngel[id1] = true;
        onePlyClaimedAngel[id2] = true;
        onePlyClaimedAngel[id3] = true;
        onePlyClaimedAngel[id4] = true;

        ABTokenData.mintABToken(msg.sender, 61, 0, 0, 0, 0, '1 ply', 0);

        emit EventMedalSuccessful(msg.sender, 0);
    }

    function claim2Ply(
        uint256 geckoId,
        uint256 parakeetId,
        uint256 catId,
        uint256 horseId
    ) public {
        //can only claim each medal once per pet card
        require(!mainClaimedPets[geckoId], 'Gecko already claimed');
        require(!mainClaimedPets[parakeetId], 'Parakeet already claimed');
        require(!mainClaimedPets[catId], 'Cat already claimed');
        require(!mainClaimedPets[horseId], 'Horse already claimed');

        require(getCardSeries(geckoId) == 24, 'Not a Gecko');
        require(getCardSeries(parakeetId) == 25, 'Not a Parakeet');
        require(getCardSeries(catId) == 26, 'Not a Cat');
        require(getCardSeries(horseId) == 27, 'Not an Horse');

        checkOwner(geckoId, msg.sender);
        checkOwner(parakeetId, msg.sender);
        checkOwner(catId, msg.sender);
        checkOwner(horseId, msg.sender);

        mainClaimedPets[geckoId] = true;
        mainClaimedPets[parakeetId] = true;
        mainClaimedPets[catId] = true;
        mainClaimedPets[horseId] = true;

        IABToken ABTokenData = IABToken(ABTokenDataContract);
        ABTokenData.mintABToken(msg.sender, 62, 0, 0, 0, 0, '2 ply', 0);
        emit EventMedalSuccessful(msg.sender, 1);
    }

    function claimCardboard(uint64 angelId) public {
        //can only claim each medal once per angel.
        require(
            !cardboardClaimedAngel[angelId],
            'This angel has already claimed this medal'
        );

        checkOwner(angelId, msg.sender);

        IABToken ABTokenData = IABToken(ABTokenDataContract);
        uint16 experience;
        uint8 cardSeriesId;
        (cardSeriesId, , , , , , experience, , , ) = ABTokenData.getABToken(
            angelId
        );

        require(cardSeriesId > 0 && cardSeriesId < 24, 'Not Angel Card');

        require(experience > 350, 'Not enough exp');

        emit EventMedalSuccessful(msg.sender, 2);

        cardboardClaimedAngel[angelId] = true;

        ABTokenData.mintABToken(msg.sender, 63, 0, 0, 0, 0, 'cardboard', 0);
    }

    function claimBronze(
        uint256 komodoId,
        uint256 falconId,
        uint256 bobcatId,
        uint256 unicornId
    ) public {
        //can only claim each medal once per pet card
        require(!mainClaimedPets[komodoId], 'Already claimed');
        require(!mainClaimedPets[falconId], 'Already claimed');
        require(!mainClaimedPets[bobcatId], 'Already claimed');
        require(!mainClaimedPets[unicornId], 'Already claimed');

        require(getCardSeries(komodoId) == 28, 'Not a Komodo');
        require(getCardSeries(falconId) == 29, 'Not a Falcon');
        require(getCardSeries(bobcatId) == 30, 'Not a Bobcat');
        require(getCardSeries(unicornId) == 31, 'Not a Unicorn');

        checkOwner(komodoId, msg.sender);
        checkOwner(falconId, msg.sender);
        checkOwner(bobcatId, msg.sender);
        checkOwner(unicornId, msg.sender);

        mainClaimedPets[komodoId] = true;
        mainClaimedPets[falconId] = true;
        mainClaimedPets[bobcatId] = true;
        mainClaimedPets[komodoId] = true;

        IABToken ABTokenData = IABToken(ABTokenDataContract);
        ABTokenData.mintABToken(msg.sender, 64, 0, 0, 0, 0, 'bronze', 0);
        emit EventMedalSuccessful(msg.sender, 1);
    }

    function claimSilver(
        uint64 redAngel,
        uint64 greenAngel,
        uint64 purpleAngel,
        uint64 yellowAngel
    ) public {
        //can only claim each medal once per angel.
        require(!silverClaimedAngel[redAngel], 'Red angel already claimed');
        require(!silverClaimedAngel[greenAngel], 'Green angel already claimed');
        require(
            !silverClaimedAngel[purpleAngel],
            'Purple angel already claimed'
        );
        require(
            !silverClaimedAngel[yellowAngel],
            'Yellow angel already claimed'
        );

        // Make sure the sender owns the angels
        checkOwner(redAngel, msg.sender);
        checkOwner(greenAngel, msg.sender);
        checkOwner(purpleAngel, msg.sender);
        checkOwner(yellowAngel, msg.sender);

        //read all Aura colors
        IABBattleSupport battleSupport = IABBattleSupport(
            ABBattleSupportContract
        );
        //Function that returns an Aura number 0 - blue, 1 - yellow, 2 - purple, 3 orange 4 - red, 5 green.

        require(battleSupport.getAuraCode(redAngel) == 4, 'Not red angel');
        require(battleSupport.getAuraCode(greenAngel) == 5, 'Not green angel');
        require(
            battleSupport.getAuraCode(purpleAngel) == 2,
            'Not purple angel'
        );
        require(
            battleSupport.getAuraCode(yellowAngel) == 1,
            'Not yellow angel'
        );

        silverClaimedAngel[redAngel] = true;
        silverClaimedAngel[greenAngel] = true;
        silverClaimedAngel[purpleAngel] = true;
        silverClaimedAngel[yellowAngel] = true;

        IABToken ABTokenData = IABToken(ABTokenDataContract);
        ABTokenData.mintABToken(msg.sender, 65, 0, 0, 0, 0, 'silver', 0);
        emit EventMedalSuccessful(msg.sender, 4);
    }

    function claimGold(uint256 angelId) public {
        require(!goldClaimedAngel[angelId], 'Angel already claimed');

        IBattleMtnData BattleMtnData = IBattleMtnData(BattleMtnDataContract);

        require(BattleMtnData.cardOnBattleMtn(angelId), 'Card not on mountain');

        goldClaimedAngel[angelId] = true;

        IABToken ABTokenData = IABToken(ABTokenDataContract);
        ABTokenData.mintABToken(msg.sender, 66, 0, 0, 0, 0, 'gold', 0);
        emit EventMedalSuccessful(msg.sender, 5);
    }

    function claimPlatinum(
        uint256 rockDragonId,
        uint256 archId,
        uint256 sabertoothId,
        uint256 pegasusId
    ) public {
        //can only claim each medal once per pet card
        require(!mainClaimedPets[rockDragonId], 'Rock dragon already claimed');
        require(!mainClaimedPets[archId], 'Archaeopteryx already claimed');
        require(!mainClaimedPets[sabertoothId], 'Sabertooth already claimed');
        require(!mainClaimedPets[pegasusId], 'Pegasus already claimed');

        require(getCardSeries(rockDragonId) == 32, 'Not a Rock Dragon');
        require(getCardSeries(archId) == 33, 'Not an Archaeopteryx');
        require(getCardSeries(sabertoothId) == 34, 'Not a Sabertooth');
        require(getCardSeries(pegasusId) == 35, 'Not a Pegasus');

        checkOwner(rockDragonId, msg.sender);
        checkOwner(archId, msg.sender);
        checkOwner(sabertoothId, msg.sender);
        checkOwner(pegasusId, msg.sender);

        mainClaimedPets[rockDragonId] = true;
        mainClaimedPets[archId] = true;
        mainClaimedPets[sabertoothId] = true;
        mainClaimedPets[pegasusId] = true;

        IABToken ABTokenData = IABToken(ABTokenDataContract);
        ABTokenData.mintABToken(msg.sender, 67, 0, 0, 0, 0, 'platinum', 0);
        emit EventMedalSuccessful(msg.sender, 7);
    }

    function claimStupidFluffyPink(
        uint256 direDragonId,
        uint256 phoenixId,
        uint256 ligerId,
        uint256 alicornId
    ) public {
        //can only claim each medal once per pet card
        require(!mainClaimedPets[direDragonId], 'Dire dragon already claimed');
        require(!mainClaimedPets[phoenixId], 'Phoenix already claimed');
        require(!mainClaimedPets[ligerId], 'Liger already claimed');
        require(!mainClaimedPets[alicornId], 'Alicorn already claimed');

        require(getCardSeries(direDragonId) == 36, 'Not a Dire Dragon');
        require(getCardSeries(phoenixId) == 37, 'Not a Phoenix');
        require(getCardSeries(ligerId) == 38, 'Not a Liger');
        require(getCardSeries(alicornId) == 39, 'Not an Alicorn');

        checkOwner(direDragonId, msg.sender);
        checkOwner(phoenixId, msg.sender);
        checkOwner(ligerId, msg.sender);
        checkOwner(alicornId, msg.sender);

        mainClaimedPets[direDragonId] = true;
        mainClaimedPets[phoenixId] = true;
        mainClaimedPets[ligerId] = true;
        mainClaimedPets[alicornId] = true;

        IABToken ABTokenData = IABToken(ABTokenDataContract);
        ABTokenData.mintABToken(
            msg.sender,
            68,
            0,
            0,
            0,
            0,
            'stupid fluffy pink',
            0
        );
        emit EventMedalSuccessful(msg.sender, 8);
    }

    function claimOrichalcum(uint256 elementalId) public {
        //can only claim each medal once per pet card
        require(!mainClaimedPets[elementalId], 'elemental already claimed');

        require(
            getCardSeries(elementalId) == 40 ||
                getCardSeries(elementalId) == 41 ||
                getCardSeries(elementalId) == 42,
            'Not an elemental'
        );

        checkOwner(elementalId, msg.sender);

        mainClaimedPets[elementalId] = true;

        IABToken ABTokenData = IABToken(ABTokenDataContract);
        ABTokenData.mintABToken(msg.sender, 69, 0, 0, 0, 0, 'orichalcum', 0);
        emit EventMedalSuccessful(msg.sender, 9);
    }

    function claimDiamond(uint256 angelId, uint8 position) public {
        require(!diamondClaimedAngel[angelId], 'angel already claimed');
        IBattleMtnData BattleMtnData = IBattleMtnData(BattleMtnDataContract);

        uint256 mountainAngelId;
        (, mountainAngelId, , , ) = BattleMtnData.getTeamByPosition(position);

        checkOwner(angelId, msg.sender);

        require(angelId != 0, 'Zero angel cannot claim');
        require(mountainAngelId == angelId, 'Angel not in position');

        diamondClaimedAngel[angelId] = true;

        IABToken ABTokenData = IABToken(ABTokenDataContract);
        ABTokenData.mintABToken(msg.sender, 70, 0, 0, 0, 0, 'diamond', 0);
        emit EventMedalSuccessful(msg.sender, 10);
    }

    function claimZeronium(uint256 angelId) public {
        require(!zeroniumClaimedAngel[angelId], 'angel already claimed');
        IBattleMtnData BattleMtnData = IBattleMtnData(BattleMtnDataContract);

        uint256 mountainAngelId;
        (, mountainAngelId, , , ) = BattleMtnData.getTeamByPosition(1);

        checkOwner(angelId, msg.sender);

        require(angelId != 0, 'Zero angel cannot claim');
        require(mountainAngelId == angelId, 'Angel not in position');
        zeroniumClaimedAngel[angelId] = true;

        IABToken ABTokenData = IABToken(ABTokenDataContract);
        ABTokenData.mintABToken(msg.sender, 72, 0, 0, 0, 0, 'zeronium', 0);
        emit EventMedalSuccessful(msg.sender, 12);
    }

    // ONE TIME BURN FUNCTIONS
    // Users will need to give approval to this contract 1x first

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

    function burnSimple(
        uint256 onePlyId,
        uint256 twoPlyId,
        uint256 cardboardId,
        uint256 bronzeId
    ) public {
        checkOwner(onePlyId, msg.sender);
        checkOwner(twoPlyId, msg.sender);
        checkOwner(cardboardId, msg.sender);
        checkOwner(bronzeId, msg.sender);

        require(getCardSeries(onePlyId) == 61, 'Not 1 ply medal');
        require(getCardSeries(twoPlyId) == 62, 'Not 2 ply medal');
        require(getCardSeries(cardboardId) == 63, 'Not cardboard medal');
        require(getCardSeries(bronzeId) == 64, 'Not bronze medal');

        // Burn the medals
        uint8 accessory = getRandomNumber(3, 1, msg.sender);
        IABToken ABTokenData = IABToken(ABTokenDataContract);
        ABTokenData.transferFrom(msg.sender, DeadAddress, onePlyId);
        ABTokenData.transferFrom(msg.sender, DeadAddress, twoPlyId);
        ABTokenData.transferFrom(msg.sender, DeadAddress, cardboardId);
        ABTokenData.transferFrom(msg.sender, DeadAddress, bronzeId);

        ABTokenData.mintABToken(msg.sender, 42 + accessory, 0, 0, 0, 0, '', 0);
    }

    function burnSilver(uint256 medalId, uint256 cardId) public {
        // Can only burn medals you own
        checkOwner(medalId, msg.sender);
        uint8 bonus = getRandomNumber(10, 5, msg.sender);
        IABToken ABTokenData = IABToken(ABTokenDataContract);

        // Only affects angels
        uint8 cardSeriesId = getCardSeries(cardId);
        require(cardSeriesId > 0 && cardSeriesId < 24, 'Not Angel Card');

        require(getCardSeries(medalId) == 65, 'Not silver medal');

        require(burnedSilver[cardId] == false, 'Card already buffed');

        burnedSilver[cardId] = true;

        // Burn the medal
        ABTokenData.transferFrom(msg.sender, DeadAddress, medalId);

        // Increase the angel's power
        ABTokenData.increasePower(cardId, bonus);
    }

    function burnGold(uint256 medalId, uint256 cardId) public {
        // Can only burn medals you own
        checkOwner(medalId, msg.sender);

        IABToken ABTokenData = IABToken(ABTokenDataContract);

        // Only affects angels

        uint8 cardSeriesId;
        uint16 experience;

        (cardSeriesId, , , , , , experience, , , ) = ABTokenData.getABToken(
            cardId
        );
        require(cardSeriesId > 0 && cardSeriesId < 24, 'Not Angel Card');

        require(getCardSeries(medalId) == 66, 'Not gold medal');

        require(burnedGold[cardId] == false, 'Card already buffed');

        burnedGold[cardId] = true;

        // Burn the medal
        ABTokenData.transferFrom(msg.sender, DeadAddress, medalId);

        // Increase the angel's power
        ABTokenData.setExperience(cardId, experience + 50);
    }

    // Send in 1 to increase your pet's red aura, 2 for blue, 3 for yellow
    function burnPlatinum(
        uint256 medalId,
        uint256 cardId,
        uint8 color
    ) public {
        // Can only burn medals you own
        checkOwner(medalId, msg.sender);

        IABToken ABTokenData = IABToken(ABTokenDataContract);

        // Only affects pets

        uint8 cardSeriesId;
        uint16 red;
        uint16 yellow;
        uint16 blue;

        (cardSeriesId, , red, yellow, blue, , , , , ) = ABTokenData.getABToken(
            cardId
        );
        require(cardSeriesId > 23 && cardSeriesId < 43, 'Not Pet Card');

        require(getCardSeries(medalId) == 67, 'Not platinum medal');

        require(burnedPlatinum[cardId] == false, 'Card already buffed');

        burnedPlatinum[cardId] = true;

        // Burn the medal
        ABTokenData.transferFrom(msg.sender, DeadAddress, medalId);

        // Increase the pet's aura as selected by the user
        if (color == 1) {
            ABTokenData.setAuras(cardId, red + 50, blue, yellow);
        }

        if (color == 2) {
            ABTokenData.setAuras(cardId, red, blue + 50, yellow);
        }

        if (color == 3) {
            ABTokenData.setAuras(cardId, red, blue, yellow + 50);
        }
    }

    // Send in 1 to increase your pet's red aura, 2 for blue, 3 for yellow
    function burnStupidFluffyPink(
        uint256 medalId,
        uint256 cardId,
        uint8 color
    ) public {
        // Can only burn medals you own
        checkOwner(medalId, msg.sender);

        IABToken ABTokenData = IABToken(ABTokenDataContract);

        // Only affects pets

        uint8 cardSeriesId;
        uint16 red;
        uint16 yellow;
        uint16 blue;

        (cardSeriesId, , red, yellow, blue, , , , , ) = ABTokenData.getABToken(
            cardId
        );
        require(cardSeriesId > 23 && cardSeriesId < 43, 'Not Pet Card');

        require(getCardSeries(medalId) == 68, 'Not stupid fluffy pink medal');

        require(burnedPink[cardId] == false, 'Card already buffed');

        burnedPink[cardId] = true;

        // Burn the medal
        ABTokenData.transferFrom(msg.sender, DeadAddress, medalId);

        // Increase the pet's aura as selected by the user
        if (color == 1) {
            ABTokenData.setAuras(cardId, red + 75, blue, yellow);
        }

        if (color == 2) {
            ABTokenData.setAuras(cardId, red, blue + 75, yellow);
        }

        if (color == 3) {
            ABTokenData.setAuras(cardId, red, blue, yellow + 75);
        }
    }

    // Send in 1 to increase your pet's red aura, 2 for blue, 3 for yellow
    function burnOrichalcum(
        uint256 medalId,
        uint256 cardId,
        uint8 color
    ) public {
        // Can only burn medals you own
        checkOwner(medalId, msg.sender);

        IABToken ABTokenData = IABToken(ABTokenDataContract);

        // Only affects pets

        uint8 cardSeriesId;
        uint16 red;
        uint16 yellow;
        uint16 blue;

        (cardSeriesId, , red, yellow, blue, , , , , ) = ABTokenData.getABToken(
            cardId
        );
        require(cardSeriesId > 23 && cardSeriesId < 43, 'Not Pet Card');

        require(getCardSeries(medalId) == 69, 'Not orichalcum medal');

        require(burnedOrichalcum[cardId] == false, 'Card already buffed');

        burnedOrichalcum[cardId] = true;

        // Burn the medal
        ABTokenData.transferFrom(msg.sender, DeadAddress, medalId);

        // Increase the pet's aura as selected by the user
        if (color == 1) {
            ABTokenData.setAuras(cardId, red + 100, blue, yellow);
        }

        if (color == 2) {
            ABTokenData.setAuras(cardId, red, blue + 100, yellow);
        }

        if (color == 3) {
            ABTokenData.setAuras(cardId, red, blue, yellow + 100);
        }
    }

    function burnDiamond(uint256 medalId, uint256 cardId) public {
        // Can only burn medals you own
        checkOwner(medalId, msg.sender);

        IABToken ABTokenData = IABToken(ABTokenDataContract);

        // Only affects angels

        uint8 cardSeriesId;
        uint16 experience;

        (cardSeriesId, , , , , , experience, , , ) = ABTokenData.getABToken(
            cardId
        );
        require(cardSeriesId > 0 && cardSeriesId < 24, 'Not Angel Card');

        require(getCardSeries(medalId) == 70, 'Not diamond medal');

        require(burnedDiamond[cardId] == false, 'Card already buffed');

        burnedDiamond[cardId] = true;

        // Burn the medal
        ABTokenData.transferFrom(msg.sender, DeadAddress, medalId);

        // Increase the angel's power
        ABTokenData.setExperience(cardId, experience + 200);
    }

    function burnTitanium(uint256 medalId, uint256 cardId) public {
        // Can only burn medals you own
        checkOwner(medalId, msg.sender);

        IABToken ABTokenData = IABToken(ABTokenDataContract);

        // Only affects pets

        uint8 cardSeriesId;
        uint16 power;

        (cardSeriesId, power, , , , , , , , ) = ABTokenData.getABToken(cardId);
        require(cardSeriesId > 23 && cardSeriesId < 43, 'Not Pet Card');

        require(getCardSeries(medalId) == 71, 'Not titanium medal');

        // Burn the medal
        ABTokenData.transferFrom(msg.sender, DeadAddress, medalId);

        uint8 top = 59;
       
        if ( cardSeriesId <= 39) {
            top = 49;
        }
         if ( cardSeriesId <= 35) {
            top = 39;
        }
        if ( cardSeriesId <= 31) {
            top = 29;
        }
        if ( cardSeriesId <= 27) {
            top = 19;
        }
        require(top > power, 'Pet already at max speed');
        // Top up pet's power
        ABTokenData.increasePower(
            cardId,
            uint8(top - power)
        );
    }

    function burnZeronium(uint256 medalId, uint256 cardId) public {
        // Can only burn medals you own
        checkOwner(medalId, msg.sender);
        uint8 bonus = getRandomNumber(25, 15, msg.sender);
        IABToken ABTokenData = IABToken(ABTokenDataContract);

        // Only affects angels
        uint8 cardSeriesId = getCardSeries(cardId);
        require(cardSeriesId > 0 && cardSeriesId < 24, 'Not Angel Card');

        require(getCardSeries(medalId) == 72, 'Not zeronium medal');

        require(burnedZeronium[cardId] == false, 'Card already buffed');

        burnedZeronium[cardId] = true;

        // Burn the medal
        ABTokenData.transferFrom(msg.sender, DeadAddress, medalId);

        // Increase the angel's power
        ABTokenData.increasePower(cardId, bonus);
    }
}