// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

import "../character/ICharacter.sol";
import "../tavern/IRhum.sol";
import "../thesea/ITheTreasureSea.sol";
import "../treasuryhunt/ITreasureHunt.sol";

contract RentingPVE {
    IRhum internal rhum;
    ICharacter internal characters;
    ITheTreasureSea internal theSea;

    uint256 private constant percent = 100;
    uint256 private constant one = 1;
    uint256 private constant zero = 0;
    uint256 private constant BIG_NUM = 10**18;

    uint256 indexPublicOffer;

    address owner;

    mapping(uint256 => Rent) internal rents;
    struct Rent {
        address owner;
        address renter;
        bool isRenting;
        uint256 percentToRenter;
        uint256 amountRhumOwner;
        uint256 amountRhumRenter;
    }
    mapping(address => mapping(uint256 => mapping(address => bool)))
        internal ownerToTokenIdToAllowedHunt;

    mapping(address => bool) internal approvedHunt;

    constructor(
        IRhum _rhum,
        ICharacter _characters,
        ITheTreasureSea _theSea
    ) {
        rhum = _rhum;
        characters = _characters;
        theSea = _theSea;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner!");
        _;
    }

    function setOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function deleguateCharacterPrivate(
        uint256 tokenId,
        address renter,
        uint8 shareToRenter
    ) external {
        require(
            characters.ownerOf(tokenId) == msg.sender,
            "Not your Character!"
        );
        require(shareToRenter < 100, "Share isn't between 0 and 100!");
        Rent storage rent = rents[tokenId];
        rent.owner = msg.sender;
        rent.renter = renter;
        rent.percentToRenter = shareToRenter;
        rent.isRenting = true;
        characters.safeTransferFrom(msg.sender, address(this), tokenId);
    }

    function deleguateCharacterPublic(
        uint256 tokenId,
        uint8 shareToRenter,
        uint256 amountRhum
    ) external {
        require(
            characters.ownerOf(tokenId) == msg.sender,
            "Not your Character!"
        );
        require(shareToRenter < 100, "Share isn't between 0 and 100!");
        Rent storage rent = rents[tokenId];
        rent.owner = msg.sender;
        rent.percentToRenter = shareToRenter;
        rent.isRenting = false;
        rent.renter = address(0);
        characters.safeTransferFrom(msg.sender, address(this), tokenId);
        indexPublicOffer += one;
        if (amountRhum > zero) {
            rent.amountRhumOwner += amountRhum;
            rhum.transferFrom(msg.sender, address(this), amountRhum);
        }
    }

    function acceptPublicOffer(uint256 tokenId) external {
        Rent storage rent = rents[tokenId];
        require(
            characters.ownerOf(tokenId) == address(this),
            "Not Public Offer!"
        );
        require(rent.isRenting == false, "Already rent!");
        rent.renter = msg.sender;
        rent.isRenting = true;
        indexPublicOffer -= one;
    }

    function undeleguateCharacter(uint256 tokenId) external {
        Rent storage rent = rents[tokenId];
        require(rent.owner == msg.sender, "Not your character!");
        rent.isRenting = false;
        characters.safeTransferFrom(address(this), msg.sender, tokenId);
        if (rent.amountRhumOwner > zero) {
            rhum.transfer(rent.owner, rent.amountRhumOwner);
            rent.amountRhumOwner = zero;
        }
        if (rent.amountRhumRenter > zero) {
            rhum.transfer(rent.renter, rent.amountRhumRenter);
            rent.amountRhumRenter = zero;
        }
    }

    function launchBatchRentHunt(
        address hunt,
        uint256 tokenId,
        bool rhumOwnerBalance,
        uint256 numberOfHunts
    ) external {
        uint256 rhumPrice = ITreasureHunt(hunt).getHuntRhumPrice();
        Rent memory rent = rents[tokenId];
        require(approvedHunt[hunt] == true, "Not Approved Hunt!");
        require(
            ownerToTokenIdToAllowedHunt[rent.owner][tokenId][hunt] == true,
            "Not Allowed to launch this hunt!"
        );
        require(rent.renter == msg.sender, "Not your Rent!");
        require(rent.isRenting == true, "Character isn't renting!");
        if (rhumOwnerBalance == true) {
            require(
                rent.amountRhumOwner >= (rhumPrice * numberOfHunts),
                "Reload Rhum token to hunt!"
            );
            rhum.approve(hunt, (rhumPrice * numberOfHunts));
            ITreasureHunt(hunt).launchBatchTreasuryHunt(tokenId, numberOfHunts);
            rent.amountRhumOwner -= rhumPrice;
        } else if (rhumOwnerBalance == false) {
            require(
                rent.amountRhumRenter >= (rhumPrice * numberOfHunts),
                "Reload Rhum token to hunt!"
            );
            rhum.approve(hunt, (rhumPrice * numberOfHunts));
            ITreasureHunt(hunt).launchBatchTreasuryHunt(tokenId, numberOfHunts);
            rent.amountRhumRenter -= rhumPrice;
        }
    }

    function ClaimBatchRentHunt(address hunt, uint256 tokenId) external {
        Rent storage rent = rents[tokenId];

        require(approvedHunt[hunt] == true, "Not Approved Hunt!");
        require(
            ITreasureHunt(hunt).fetchToggleMint(address(this), tokenId) == true,
            "Hunt is not ending!"
        );
        require(
            rent.renter == msg.sender || rent.owner == msg.sender,
            "Not your Rent!"
        );
        ITreasureHunt(hunt).ClaimBatchTreasuryHunt(tokenId);
    }

    function OwnerLoadRhum(uint256 tokenId, uint256 amount) external {
        Rent storage rent = rents[tokenId];
        require(rent.owner == msg.sender, "Not your Character!");
        rent.amountRhumOwner += amount;
        rhum.transferFrom(msg.sender, address(this), amount);
    }

    function OwnerUnloadRhum(uint256 tokenId, uint256 amount) external {
        Rent storage rent = rents[tokenId];
        require(rent.owner == msg.sender, "Not your Character!");
        require(
            amount <= rent.amountRhumOwner,
            "Amount exced rhum balance character!"
        );
        rent.amountRhumOwner -= amount;
        rhum.transfer(msg.sender, amount);
    }

    function RenterLoadRhum(uint256 tokenId, uint256 amount) external {
        Rent storage rent = rents[tokenId];
        require(rent.renter == msg.sender, "Not your Character!");
        rent.amountRhumRenter += amount;
        rhum.transferFrom(msg.sender, address(this), amount);
    }

    function RenterUnloadRhum(uint256 tokenId, uint256 amount) external {
        Rent storage rent = rents[tokenId];
        require(rent.renter == msg.sender, "Not your Character!");
        require(
            amount <= rent.amountRhumRenter,
            "Amount exced rhum balance character!"
        );
        rent.amountRhumRenter -= amount;
        rhum.transfer(msg.sender, amount);
    }

    function addAllowedHunt(uint256 tokenId, address[] memory hunts) external {
        Rent memory rent = rents[tokenId];
        require(
            characters.ownerOf(tokenId) == msg.sender ||
                rent.owner == msg.sender
        );
        for (uint256 i = zero; i < hunts.length; i++) {
            ownerToTokenIdToAllowedHunt[msg.sender][tokenId][hunts[i]] = true;
        }
    }

    function removeAllowedHunt(uint256 tokenId, address[] memory hunts)
        external
    {
        Rent memory rent = rents[tokenId];
        require(
            characters.ownerOf(tokenId) == msg.sender ||
                rent.owner == msg.sender
        );
        for (uint256 i = zero; i < hunts.length; i++) {
            ownerToTokenIdToAllowedHunt[msg.sender][tokenId][hunts[i]] = false;
        }
    }

    function _calculRewardToShare(uint256 amount, uint256 share)
        internal
        pure
        returns (uint256)
    {
        return ((((amount * BIG_NUM) / percent) * share) / BIG_NUM);
    }

    function calculRewardToShare(uint256 amount, uint256 share)
        external
        pure
        returns (uint256)
    {
        return ((((amount * BIG_NUM) / percent) * share) / BIG_NUM);
    }

    function getRentData(uint256 tokenId)
        external
        view
        returns (Rent memory rent)
    {
        return rents[tokenId];
    }

    function fetchAllPublicOfferTokenIds()
        external
        view
        returns (uint256[] memory)
    {
        uint256 userTokenIds = indexPublicOffer;
        uint256 totalTokenIds = characters.balanceOf(address(this));
        uint256 currentIndex = zero;
        uint256[] memory PublicOffers = new uint256[](userTokenIds);
        for (uint256 i = zero; i < totalTokenIds; i++) {
            uint256 tokenId = characters.tokenOfOwnerByIndex(address(this), i);
            Rent memory rent = rents[tokenId];
            if (rent.isRenting == false) {
                PublicOffers[currentIndex] = tokenId;
                currentIndex++;
            }
        }
        return PublicOffers;
    }

    function addApprovedHunt(address _hunt) public onlyOwner {
        approvedHunt[_hunt] = true;
    }

    function removeApprovedHunt(address _hunt) public onlyOwner {
        approvedHunt[_hunt] = false;
    }

    function setCharacterAddress(address _newAddress) external onlyOwner {
        characters = ICharacter(_newAddress);
    }

    function setTheSea(address _newTheSea) public onlyOwner {
        theSea = ITheTreasureSea(_newTheSea);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ICharacter {
    struct Character {
        uint32 boarding;
        uint32 sailing;
        uint32 charisma;
        uint64 experience;
        uint64 specialisation;
        uint32 thirst;
        uint256 tokenId;
    }

    //View functions
    function addTreasuryHuntResult(
        uint256 tokenId,
        uint32 amountHunt,
        uint64 exp
    ) external;

    function generateCharacter(
        uint256 class,
        address user,
        uint32 numberOfmints
    ) external;

    function getCharacterInfos(uint256 tokenId)
        external
        view
        returns (Character memory characterInfos);

    function getLevelMax() external view returns (uint256);

    function getNumberOfCharacters() external view returns (uint256);

    function getCharacterTotalStats(uint256 tokenId)
        external
        view
        returns (
            uint32 boarding,
            uint32 sailing,
            uint32 charisma
        );

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function balanceOf(address owner) external view returns (uint256 balance);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function setApprovalForAll(address operator, bool _approved) external;

    function burn(uint256 tokenId) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IRhum {
    function mint(address to, uint amount) external;

    function burnFrom(address account, uint amount) external;

    function burn(uint amount) external;

    function fetchHalving() external view returns (uint256);
    
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

interface ITheTreasureSea {
    function mintTreasureMap(
        address user,
        uint256 amount,
        uint256 rarity
    ) external;

    function burn(
        address from,
        uint256 id,
        uint256 value
    ) external;

    function setApprovalForAll(address operator, bool approved) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

interface ITreasureHunt {
    function launchTreasuryHunt(uint256 tokenId) external;

    function launchBatchTreasuryHunt(uint256 characterId, uint256 numberOfHunts)
        external;

    function ClaimBatchTreasuryHunt(uint256 characterId) external;

    function ClaimTreasuryHunting(uint256 tokenId) external returns (bool);

    function fetchToggleMint(address user, uint256 tokenId)
        external
        view
        returns (bool);

    function getHuntRhumPrice() external view returns (uint256);

    function getHuntMapRewardAmount() external pure returns (uint256, uint256);
}