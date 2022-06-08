/**
 *Submitted for verification at polygonscan.com on 2022-06-07
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: contracts/ILending.sol



pragma solidity ^0.8.0;

interface ILending {
    struct BreedApartment {
        address breeder;
        uint256 male;
        uint256 female;
        uint256 unlockAt;
    }

    struct BreedDog {
        uint256 partner;
        uint256 apartment;
        uint256 unlockAt;
    }

    function acceptOffer ( address _nftContractAddress, uint256 _tokenId, uint16 _duration ) external;
    function canUse ( address _nftContractAddress, uint256 _tokenId, address _user, uint256 _until ) external view returns ( bool );
    function cancelOffer ( address _nftContractAddress, uint256 _tokenId ) external;
    function createOffer ( address _nftContractAddress, uint256 _tokenId, address _to, address _erc20Token, uint256 _price, uint16 _minDuration, uint256 _expirtaion ) external;
    function erc20Tokens ( address ) external view returns ( bool isAllowed, uint32 feePercentage );
    function extendBorrowing ( address _nftContractAddress, uint256 _tokenId, uint16 _duration ) external;
    function feeRecipient (  ) external view returns ( address );
    function lent ( address, uint256 ) external view returns ( address from, address to, uint256 until );
    function offers ( address, uint256 ) external view returns ( address from, address to, address erc20Token, uint256 price, uint16 minDuration, uint256 expiration );
    function ownerOf ( address _nftContractAddress, uint256 _tokenId ) external view returns ( address );
    function owners ( address, uint256 ) external view returns ( address );
    function renounceOwnership (  ) external;
    function retrieveNft ( address _nftContractAddress, uint256 _tokenId ) external;
    function transferOwnership ( address newOwner ) external;
    function userOf ( address _nftContractAddress, uint256 _tokenId ) external view returns ( address );
    function withdraw ( address _currency, uint256 _amount ) external;
    function setErc20Token ( address _erc20Token, bool _isAllowed, uint32 _feePercentage ) external;
}

// File: contracts/IDog.sol



pragma solidity ^0.8.0;

interface IDog {
    struct Bio {
        string name;
        uint256 birthDate;
        bool sex;
        bool specialEdition;
        string editionName;
        string typeName;
        uint256 motherId;
        uint256 fatherId;
        string image;
    }
    
    struct Gaming {
        bool canFly;
        bool canDive;
        bool canSwim;
        bool laserEyes;
        bool freezeBreath;
    }
    
    struct Skills {
        uint8 speed;
        uint8 strength;
        uint8 feature1;
        uint8 feature2;
        uint8 feature3;
    }
    
    struct Appearance {
        uint8 color;
        uint256 outfit;
    }

    function energy ( uint256 ) external view returns ( uint256 );
    function getAppearance ( uint256 _tokenId ) external view returns ( Appearance memory );
    function getApproved ( uint256 tokenId ) external view returns ( address );
    function getBio ( uint256 _tokenId ) external view returns ( Bio memory );
    function getGaming ( uint256 _tokenId ) external view returns ( Gaming memory );
    function getProperties ( uint256 _tokenId ) external view returns ( Bio memory , Gaming memory , Skills memory , Appearance memory );
    function getSkills ( uint256 _tokenId ) external view returns ( Skills memory );
    function isBreeding ( uint256 _tokenId ) external view returns ( bool );
    function mint ( address _to, Bio calldata _bio, Skills calldata _skils, Gaming calldata _gaming, Appearance calldata _appearance ) external returns ( uint256 );
    function setAppearance ( uint256 _tokenId, Appearance calldata _appearance ) external;
    function setApprovalForAll ( address operator, bool approved ) external;
    function setEnergy ( uint256 _tokenId, uint256 _energy ) external;
    function setName ( uint256 _tokenId, string calldata _name ) external;
    function setRoyalties ( address recipient, uint256 value ) external;
    function setSkills ( uint256 _tokenId, Skills calldata _skills ) external;
}

// File: contracts/IApartment.sol



pragma solidity ^0.8.0;

interface IApartment {
    struct Bio {
        string apartmentAddress;
        string name;
        string district;
        uint256 dateBuilt;
        uint256 metrage;
        uint8 floor;
        bool commercial;
        string image;
    }
    
    struct Features {
        uint8 feature1;
        uint8 feature2;
        uint8 feature3;
    }

    function addKeyholder ( uint256 _tokenId, address _holder ) external;
    function energy ( uint256 ) external view returns ( uint256 );
    function getBio ( uint256 _tokenId ) external view returns ( Bio memory);
    function getFeatures ( uint256 _tokenId ) external view returns ( Features memory);
    function getKeyOwners ( uint256 _tokenId ) external view returns ( address[] memory);
    function hasKey ( uint256 _tokenId, address _holder ) external view returns ( bool );
    function isBreeding ( uint256 _tokenId ) external view returns ( bool );
    function mint ( address _to, Bio calldata _bio ) external;
    function removeKeyholder ( uint256 _tokenId, address _holder ) external;
    function setAddress ( uint256 _tokenId, string calldata _apartmentAddress ) external;
    function setEnergy ( uint256 _tokenId, uint256 _energy ) external;
    function setFeatures ( uint256 _tokenId, Features calldata _features ) external;
    function setName ( uint256 _tokenId, string calldata _name ) external;
}

// File: contracts/BreedV3.sol



pragma solidity ^0.8.0;






contract Breed is Ownable {
    IDog public dogContract;
    IApartment public apartmentContract;
    ILending public lendingContract;
    
    uint256 public lockTime;
    uint256 public sqmPerPair;
    uint256 public minBreedAge;
    uint256 public breedLimit;

    struct BreedApartment {
        address breeder;
        uint256 male;
        uint256 female;
        uint256 unlockAt;
    }

    struct BreedDog {
        uint256 partner;
        uint256 apartment;
        uint256 unlockAt;
    }

    mapping(uint256 => BreedApartment[]) apartmentBreedings;
    mapping(uint256 => BreedDog) dogBreeding;
    mapping(uint256 => uint256) public dogTotalBreedings;

    mapping(string => uint256) public birthRate;
    mapping(string => uint256) public birthPeriod;
    mapping(string => bool) public isPartnerEdition; // dog edition. Cannot breed two partner edition dogs.

    event BreedingStarted(
        address breeder,
        uint256 male,
        uint256 female,
        uint256 apartment,
        uint256 unlockAt
    );

    event BreedingCanceled(
        address breeder,
        uint256 male,
        uint256 female,
        uint256 apartment,
        uint256 unlockAt
    );

    event BreedingEnded(
        address breeder,
        uint256 male,
        uint256 female,
        uint256 apartment,
        uint256 unlockAt,
        uint256[] children
    );

    constructor(uint256 _lockTime, uint256 _sqmPerPair, uint256 _minBreedAge, uint256 _breedLimit) {
        lockTime = _lockTime;
        sqmPerPair = _sqmPerPair;
        minBreedAge = _minBreedAge;
        breedLimit = _breedLimit;
    }

    function setContracts(address _dogAddress, address _apartmentAddress, address _lendingAddress) external onlyOwner {
        dogContract = IDog(_dogAddress);
        apartmentContract = IApartment(_apartmentAddress);
        lendingContract = ILending(_lendingAddress);
    }
    
    // _time is measured in seconds.
    function setLockTime(uint256 _time) external onlyOwner {
        lockTime = _time;
    }
    
    function setSqmPerPair(uint256 _sqmPerPair) external onlyOwner {
        sqmPerPair = _sqmPerPair;
    }
    
    function setMinBreedAge(uint256 _minBreedAge) external onlyOwner {
        minBreedAge = _minBreedAge;
    }

    function setBreedLimit(uint256 _breedLimit) external onlyOwner {
        breedLimit = _breedLimit;
    }

    function setBirthRate(string calldata _district, uint256 _birthRate) external onlyOwner {
        birthRate[_district] = _birthRate;
    }
    
    function setBirthRateMultiple(string[] calldata _districts, uint256[] calldata _districtBirthRates) external onlyOwner {
        require(_districts.length == _districtBirthRates.length);
        for (uint256 i=0; i < _districts.length;) {
            birthRate[_districts[i]] = _districtBirthRates[i];
            unchecked{ i++; }
        }
    }

    function setBirthPeriod(string calldata _district, uint256 _birthPeriod) external onlyOwner {
        birthPeriod[_district] = _birthPeriod;
    }
    
    function setBirthPeriodMultiple(string[] calldata _districts, uint256[] calldata _districtBirthPeriods) external onlyOwner {
        require(_districts.length == _districtBirthPeriods.length);
        for (uint256 i=0; i < _districts.length;) {
            birthPeriod[_districts[i]] = _districtBirthPeriods[i];
            unchecked{ i++; }
        }
    }

    function setIsPartnerEdition(string calldata _editionName, bool _isPartnerEdition) external onlyOwner {
        isPartnerEdition[_editionName] = _isPartnerEdition;
    }
    
    function setIsPartnerEditionMultiple(string[] calldata _editionNames, bool[] calldata _isPartnerEdition) external onlyOwner {
        require(_editionNames.length == _isPartnerEdition.length);
        for (uint256 i=0; i < _editionNames.length;) {
            isPartnerEdition[_editionNames[i]] = _isPartnerEdition[i];
            unchecked{ i++; }
        }
    }
    
    function startBreed(uint256 _male, uint256 _female, uint256 _apartment) external {
        // dogs must not have more breedings than breedLimit
        require(dogTotalBreedings[_male] < breedLimit && dogTotalBreedings[_female] < breedLimit, "Breed limit reached");

        uint256 unlockAt = block.timestamp + lockTime;

        // user must own or borrow the dogs and apartment.
        require(lendingContract.canUse(address(dogContract), _male, msg.sender, unlockAt) &&
            lendingContract.canUse(address(dogContract), _female, msg.sender, unlockAt) &&
            lendingContract.canUse(address(apartmentContract), _apartment, msg.sender, unlockAt), "No right to use dogs/apartment");
        
        uint256 maleUnlockAt = dogBreeding[_male].unlockAt;
        uint256 femaleUnlockAt = dogBreeding[_female].unlockAt;

        // dogs must not be breeding 
        require(maleUnlockAt < block.timestamp && femaleUnlockAt < block.timestamp, "Already breeding");

        IApartment.Bio memory apartmentBio = apartmentContract.getBio(_apartment);

        // appartment must have enough space to breed
        require(apartmentBio.metrage / sqmPerPair > getApartmentActiveBreedings(_apartment), "Not enough space");
        
        uint256 _birthPeriod = birthPeriod[apartmentBio.district]; 

        // enough time must pass from last time the dogs breed
        require(block.timestamp - maleUnlockAt > _birthPeriod && block.timestamp - femaleUnlockAt > _birthPeriod, "Birth period not passed yet");

        IDog.Bio memory maleBio = dogContract.getBio(_male);
        IDog.Bio memory femaleBio = dogContract.getBio(_female);

        // dogs must be appropriate sex
        require(!maleBio.sex && femaleBio.sex, "Wrong sex");

        // at least one dog must be 0
        require(!isPartnerEdition[maleBio.editionName] || !isPartnerEdition[femaleBio.editionName], "Two partner edition dogs.");

        // dogs must be old enough to breed
        require((block.timestamp - maleBio.birthDate) >= minBreedAge && (block.timestamp - femaleBio.birthDate) >= minBreedAge,"Does not meet minBreedAge");

        dogBreeding[_male] = BreedDog(_female, _apartment, unlockAt);
        dogBreeding[_female] = BreedDog(_male, _apartment, unlockAt);
        dogTotalBreedings[_male]++;
        dogTotalBreedings[_female]++;
        apartmentBreedings[_apartment].push(BreedApartment(msg.sender, _male, _female, unlockAt));

        emit BreedingStarted(msg.sender, _male, _female, _apartment, unlockAt);
    }
    
    function cancelBreed(uint256 _male, uint256 _female, uint256 _apartment, uint256 _unlockAt) external {
        require(_unlockAt > block.timestamp, "Breeding ended");
        require(_endBreedApartment(_apartment, BreedApartment(msg.sender, _male, _female, _unlockAt)), "Invalid breeding");
        _cancelBreedDog(_male);
        _cancelBreedDog(_female);

        emit BreedingCanceled(msg.sender, _male, _female, _apartment, _unlockAt);
    }
    
    function _cancelBreedDog(uint256 _tokenId) internal {
        delete dogBreeding[_tokenId];
        dogTotalBreedings[_tokenId] -= 1;
    }   

    function _endBreedApartment(uint256 _tokenId, BreedApartment memory _breed) internal returns(bool) {
        BreedApartment[] memory _breedings = apartmentBreedings[_tokenId];
        for (uint256 i=0;i < _breedings.length;) {
            if (_breedings[i].male == _breed.male && _breedings[i].female == _breed.female && _breedings[i].breeder == _breed.breeder && _breedings[i].unlockAt == _breed.unlockAt) {
                apartmentBreedings[_tokenId][i] = apartmentBreedings[_tokenId][_breedings.length - 1];
                apartmentBreedings[_tokenId].pop();
                return true;
            }
            unchecked{ i++; }
        }
        return false;
    }
    
    function mint(uint256 _male, uint256 _female, uint256 _apartment, uint256 _unlockAt) external {
        require(_unlockAt <= block.timestamp, "Breeding not ended");
        require(_endBreedApartment(_apartment, BreedApartment(msg.sender, _male, _female, _unlockAt)), "Invalid breeding");

        bool maleSpecialEdition = dogContract.getBio(_male).specialEdition;
        bool femaleSpecialEdition = dogContract.getBio(_female).specialEdition;
        
        uint256 numOfChildren = birthRate[apartmentContract.getBio(_apartment).district];
        
        uint256[] memory children = new uint256[](numOfChildren);

        for (uint256 i = 0; i < numOfChildren;) {
            uint256 randomNumber = (uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.difficulty, _male, _female, i))) % 100) + 1;

    	    uint256 pickTraits = _male;

            if(maleSpecialEdition == femaleSpecialEdition) {
                if(randomNumber > 50) {
                    pickTraits = _female;
                }
            } else if(femaleSpecialEdition) {
                pickTraits = _female;
            }

            children[i] = _mint(_male, _female, randomNumber%2 == 0, pickTraits);

            unchecked{ i++; }
        }

        emit BreedingEnded(msg.sender, _male, _female, _apartment, _unlockAt, children);
    }

    function _mint(uint256 _male, uint256 _female, bool _sex, uint256 _traits) internal returns (uint256) {
        (IDog.Bio memory newDogBio, IDog.Gaming memory newDogGaming, IDog.Skills memory newDogSkills, IDog.Appearance memory newDogAppearance) = dogContract.getProperties(_traits);

        newDogBio.name = "";
        newDogBio.sex = _sex;
        newDogBio.fatherId = _male;
        newDogBio.motherId = _female;
        newDogBio.birthDate = block.timestamp;

        // if(!newDogBio.specialEdition) {
        //     newDogAppearance.color = 0;
        // }

        return dogContract.mint(msg.sender, newDogBio, newDogSkills, newDogGaming, newDogAppearance);
    }

    function isBreedingApartment(uint256 _tokenId) external view returns (bool) {
        BreedApartment[] memory _breedings = apartmentBreedings[_tokenId];
        for (uint256 i=0;i < _breedings.length;) {
            if(_breedings[i].unlockAt >= block.timestamp) {
                return true;
            }
            unchecked{ i++; }
        }
        return false;
    }

    function isBreedingDog(uint256 _tokenId) external view returns (bool) {
        return dogBreeding[_tokenId].unlockAt >= block.timestamp;
    }

    function getApartmentActiveBreedings(uint256 _tokenId) public view returns (uint256) {
        BreedApartment[] memory _breedings = apartmentBreedings[_tokenId];
        uint256 active = 0;
        for (uint256 i=0;i < _breedings.length;) {
            if(_breedings[i].unlockAt >= block.timestamp) {
               unchecked{ active++; }
            }
            unchecked{ i++; }
        }
        return active;
    }

    function getApartmentBreedings(uint256 _tokenId) external view returns (BreedApartment[] memory) {
        return apartmentBreedings[_tokenId];
    }

    function getDogBreeding(uint256 _tokenId) external view returns (BreedDog memory) {
        return dogBreeding[_tokenId];
    }
    
}