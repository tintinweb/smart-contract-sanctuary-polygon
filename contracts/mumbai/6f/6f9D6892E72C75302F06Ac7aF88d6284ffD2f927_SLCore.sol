// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SLPuzzles.sol";

/// @title SLCore
/// @author Something Legendary
/// @dev This contract extends SLPuzzles and provides core functionalities for the system.
contract SLCore is SLPuzzles {
    /// @notice Initializes the new SLCore contract.
    /// @param _slLogicsAddress The address of the SLLogics contract.
    /// @param _slPermissionsAddress The address of the SLPermissions contract.
    constructor(address _slLogicsAddress, address _slPermissionsAddress) {
        if (_slLogicsAddress == address(0)) {
            revert InvalidAddress("SLLogics");
        }
        if (_slPermissionsAddress == address(0)) {
            revert InvalidAddress("SLPermissions");
        }

        slLogicsAddress = _slLogicsAddress;

        slPermissionsAddress = _slPermissionsAddress;
    }

    ///
    //-----------------USER FUNCTIONS----------------
    ///
    /// @notice Mints an entry token for the caller.
    /// @dev This function can only be called when entry minting is not paused and by non-reentrant calls.
    function mintEntry() public isEntryMintNotPaused nonReentrant {
        if (_whichLevelUserHas(msg.sender) != 0) {
            revert IncorrectUserLevel(_whichLevelUserHas(msg.sender), 0);
        }
        //run internal logic to mint entry token
        _buyEntryToken(msg.sender);
        //Initiliaze token and Ask for payment
        ISLLogics(slLogicsAddress).payEntryFee(msg.sender);
    }

    /// @notice Claims a puzzle piece for the caller.
    /// @dev This function can only be called when puzzle minting is not paused, by non-reentrant calls, and by users of at least level 1.
    function claimPiece()
        public
        isPuzzleMintNotPaused
        nonReentrant
        userHasLevel(1)
    {
        //claim the piece for the user
        _claimPiece(msg.sender, _whichLevelUserHas(msg.sender));
    }

    /// @notice Claims a level for the caller.
    /// @dev This function can only be called when puzzle minting is not paused, by non-reentrant calls, and by users of at least level 1.
    function claimLevel()
        public
        isPuzzleMintNotPaused
        nonReentrant
        userHasLevel(1)
    {
        //Check if user has the highest level
        if (_whichLevelUserHas(msg.sender) > 2) {
            revert IncorrectUserLevel(_whichLevelUserHas(msg.sender), 2);
        }

        //Claim next level for user depending on the level he has
        _claimLevel(msg.sender, _whichLevelUserHas(msg.sender) == 1 ? 30 : 31);
    }

    ///
    //---------------------ADMIN FUNCTIONS--------------------
    ///

    /// @notice Generates a new entry batch.
    /// @dev This function can only be called by the CEO and when the system is not globally stopped.
    /// @param _cap The cap for the new entry batch.
    /// @param _entryPrice The price for the new entry batch.
    /// @param _tokenUri The URI for the new entry batch.
    function generateNewEntryBatch(
        uint256 _cap,
        uint256 _entryPrice,
        string memory _tokenUri
    ) public isNotGloballyStoped isCEO {
        entryIdsArray.push(mountEntryValue(_cap, 0));
        ISLLogics(slLogicsAddress).setEntryPrice(_entryPrice, _tokenUri);
    }

    /// @notice Returns the URI for a given token ID.
    /// @param _collectionId The ID of the token to retrieve the URI for.
    /// @return The URI of the given token ID.
    function uri(
        uint256 _collectionId
    ) public view override returns (string memory) {
        return ISLLogics(slLogicsAddress).uri(_collectionId);
    }

    function mintTest(uint level) public {
        for (uint i = 0; i < 10; i++) {
            _mint(msg.sender, _getPuzzleCollectionIds(level)[i], 1, "");
            _incrementUserPuzzlePieces(msg.sender, level);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SLLevels.sol";

/// @title SLPuzzles
/// @author Something Legendary
/// @notice Manages levels
contract SLPuzzles is SLLevels {
    ///
    //--------------------OVERWRITTEN FUNCTIONS-------------------
    ///

    ///Added computation of the user level so user doesnt input his level when claiming
    /// @inheritdoc	SLBase
    function verifyClaim(
        address _claimer,
        uint256 _tokenIdOrPuzzleLevel
    ) public view override {
        //Check if given piece is a puzzle piece or a level
        if (_tokenIdOrPuzzleLevel == 31 || _tokenIdOrPuzzleLevel == 30) {
            //Check if user has the ability to burn the puzzle piece
            _userAllowedToBurnPuzzle(_claimer, _tokenIdOrPuzzleLevel);
        } else if (
            _tokenIdOrPuzzleLevel == 1 ||
            _tokenIdOrPuzzleLevel == 2 ||
            _tokenIdOrPuzzleLevel == 3
        ) {
            //Check if user has the ability to burn the puzzle piece
            ISLLogics(slLogicsAddress)._userAllowedToClaimPiece(
                _claimer,
                _tokenIdOrPuzzleLevel,
                _whichLevelUserHas(_claimer),
                getUserPuzzlePiecesForUserCurrentLevel(
                    _claimer,
                    _whichLevelUserHas(_claimer)
                )
            );
        } else {
            revert("Not a valid id");
        }
    }

    /// @inheritdoc	SLBase
    function _random() public view override returns (uint8) {
        return
            uint8(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp,
                            block.difficulty,
                            msg.sender
                        )
                    )
                ) % 10
            );
    }

    /// @inheritdoc	SLBase
    function _getPuzzleCollectionIds(
        uint256 level
    ) public view override returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](10);
        if (level == 1) {
            ids = getMultiplePositionsXInDivisionByY(COLLECTION_IDS, 1, 10, 2);
        } else if (level == 2) {
            ids = getMultiplePositionsXInDivisionByY(COLLECTION_IDS, 11, 10, 2);
        } else if (level == 3) {
            ids = getMultiplePositionsXInDivisionByY(COLLECTION_IDS, 21, 10, 2);
        } else {
            revert("Not a valid puzzle level");
        }
        return ids;
    }

    /// @inheritdoc	SLBase
    function _dealWithPuzzleClaiming(
        address _receiver,
        uint256 _puzzleLevel
    ) internal override returns (uint8 _collectionToMint) {
        //assuming user passed verifyClaim
        _incrementUserPuzzlePieces(_receiver, _puzzleLevel);
        //return the collection to mint
        return (uint8(_getPuzzleCollectionIds(_puzzleLevel)[_random()]));
    }

    ///
    //---------------------------------GETTERS------------------------------
    ///
    //Function to get how many puzzle pieces a user has from current level
    /// @notice Function to get how many puzzle pieces a user has from current level
    /// @dev If user is given a piece by transfer, it will not count as claimed piece
    /// @param _user user's address
    /// @param level the specified level
    /// @return uint256 number of pieces
    function getUserPuzzlePiecesForUserCurrentLevel(
        address _user,
        uint256 level
    ) public view returns (uint256) {
        return getPositionXInDivisionByY(userPuzzlePieces[_user], level, 3);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SLBase.sol";

/// @title SLLevels
/// @author Something Legendary
/// @notice contract that manages levels
contract SLLevels is SLBase {
    /// @notice Function to deal with data of buying a new NFT entry token
    /// @dev Call the function and add needed logic (Payment, etc)
    /// @param _receiver buyer
    function _buyEntryToken(address _receiver) internal {
        //Verify if the entry token btach exists
        if (entryIdsArray.length == 0) {
            revert InexistentEntryBatch();
        }
        //Verify if the entry token is still available
        if (getCurrentEntryBatchRemainingTokens() == 0) {
            revert NoTokensRemaining();
        }
        //get the current entry batch number
        uint256 batch = entryIdsArray.length - 1;
        //Get the entry token cap and currentID
        (
            uint256 entryTokenCap,
            uint256 entryTokenCurrentId
        ) = unmountEntryValue(entryIdsArray[batch]);
        //Increment the entry token current id
        entryIdsArray[batch] = mountEntryValue(
            entryTokenCap,
            entryTokenCurrentId + 1
        );
        //Mint the entry token to the user
        _transferTokensOnClaim(
            _receiver,
            mountEntryID(batch, entryTokenCap),
            1
        );
        emit TokensClaimed(_receiver, mountEntryID(batch, entryTokenCap));
    }

    ///
    //--------------------OVERWRITTEN FUNCTIONS-------------------
    ///

    /// Added logic that verifies the possibility of passing the level
    /// @inheritdoc	SLBase
    function _userAllowedToBurnPuzzle(
        address _claimer,
        uint256 _tokenId
    ) public view override {
        //Helper Arrays
        uint256 arraysLength = 10;
        address[] memory userAddress = _createUserAddressArray(
            _claimer,
            arraysLength
        );
        uint256[] memory amountsForBurn = new uint256[](arraysLength);
        uint256[] memory balance;
        //Fill needed arrays
        for (uint256 i; i < arraysLength; ++i) {
            amountsForBurn[i] = 1;
        }
        //Puzzle verification for passing to level2
        if (_tokenId == 30) {
            //Check for user level token ownership
            if (balanceOf(_claimer, _tokenId) != 0) {
                revert IncorrectUserLevel(2, 1);
            }
            //Get balance of the user
            balance = balanceOfBatch(userAddress, _getPuzzleCollectionIds(1));
            //verify if balance meets the condition
            uint256 balanceLength = balance.length;
            for (uint256 i; i < balanceLength; ++i) {
                if (balance[i] == 0) {
                    revert UserMustHaveCompletePuzzle(1);
                }
            }
            //Puzzle verification for passing to level3
        } else if (_tokenId == 31) {
            //Check for user level token ownership
            if (balanceOf(_claimer, _tokenId) != 0) {
                revert IncorrectUserLevel(3, 2);
            }
            //Get balance of the user
            balance = balanceOfBatch(userAddress, _getPuzzleCollectionIds(2));
            //verify if balance meets the condition
            uint256 balanceLength = balance.length;
            for (uint256 i; i < balanceLength; ++i) {
                if (balance[i] == 0) {
                    revert UserMustHaveCompletePuzzle(2);
                }
            }
        } else {
            //revert is for some reason the ID is not Level2 or 3 ID
            revert("Not a valid level token ID");
        }
    }

    /// @inheritdoc	SLBase
    function _getLevelTokenIds(
        uint256 _level
    ) internal view override returns (uint256[] memory) {
        if (_level == 1) {
            uint256 arrayLenght = entryIdsArray.length;
            uint256[] memory entryTokenIds = new uint256[](arrayLenght);
            for (uint256 i; i < arrayLenght; ++i) {
                //i is the batch number
                //get the entry token cap to mount the entry token id
                (uint256 entryTokenCap, ) = unmountEntryValue(entryIdsArray[i]);
                entryTokenIds[i] = mountEntryID(i, entryTokenCap);
            }
            return entryTokenIds;
        } else if (_level == 2 || _level == 3) {
            uint256[] memory level2And3Ids = new uint256[](2);
            level2And3Ids[0] = 30;
            level2And3Ids[1] = 31;
            return level2And3Ids;
        }
    }

    ///
    //-------------------INTERNAL FUNCTIONS-------------------
    ///

    /// @notice check users level
    /// @dev checks based on NFT balance, so the users are able to trade privileges
    /// @param _user user's address
    /// @return uint256 users level
    function _whichLevelUserHas(address _user) internal view returns (uint256) {
        //check if user has level 2 or 3
        //call function to check user balance of token id 30 and 31

        //Verify level 2 and 3 token ownership
        if (balanceOf(_user, 31) != 0) {
            return 3;
        } else if (balanceOf(_user, 30) != 0) {
            return 2;
        } else {
            uint256 level1IdsLength = _getLevelTokenIds(1).length;
            //If user doesnt have level 2 or 3, check if user has entry token
            //Get the balance of the user for each entry token id
            uint256[] memory userBalance = balanceOfBatch(
                _createUserAddressArray(_user, level1IdsLength),
                _getLevelTokenIds(1)
            );
            //Verify if the user has any entry token
            for (uint256 i; i < level1IdsLength; ++i) {
                if (userBalance[i] != 0) {
                    return 1;
                }
            }
            return 0;
        }
    }

    /// @notice check users level
    /// @dev checks based on NFT balance, so the users are able to trade privileges
    /// @param _user user's address
    /// @return uint256 users level
    function whichLevelUserHas(address _user) external view returns (uint256) {
        return (_whichLevelUserHas(_user));
    }

    ///
    //------------------GETTERS--------------------
    ///
    /// @notice get remaining tokens for current batch
    /// @dev uses SLMicroSlots to have access to such information
    /// @return uint256 tokens left
    function getCurrentEntryBatchRemainingTokens()
        public
        view
        returns (uint256)
    {
        (
            uint256 entryTokenCap,
            uint256 entryTokenCurrentId
        ) = unmountEntryValue(entryIdsArray[entryIdsArray.length - 1]);
        return (entryTokenCap - entryTokenCurrentId);
    }

    ////
    //------------------MODIFIERS--------------------
    ///
    /// @notice Verifies if user has the necessary NFT to interact with the function.
    /// @dev User should be at least the same level as the the reuqired by the function
    modifier userHasLevel(uint256 _level) {
        //use _whichLevelUserHas to check if user has the level
        if (_whichLevelUserHas(msg.sender) < _level) {
            revert IncorrectUserLevel(_level, _whichLevelUserHas(msg.sender));
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./SLMicroSlots.sol";
import "./ISLPermissions.sol";

//interface for SLLogics
interface ISLLogics {
    function _userAllowedToClaimPiece(
        address user,
        uint256 _tokenId,
        uint256 _currentUserLevel,
        uint256 _userPuzzlePiecesForUserCurrentLevel
    ) external view;

    function payEntryFee(address _user) external;

    function setEntryPrice(uint256 _newPrice, string memory tokenUri) external;

    function uri(uint256 _id) external view returns (string memory);
}

/// @title SLBase
/// @author Something Legendary
/// @notice Centralizes information on this contract, making sure that all of the ERC1155 communications and
/// memory writting calls happens thorugh here!
/// @dev Extra details about storage: https://app.diagrams.net/#G1Wi7A1SK0y8F9X-XDm65IUdfRJ81Fo7bF
contract SLBase is ERC1155, ReentrancyGuard, SLMicroSlots {
    ///
    //-----STATE VARIABLES------
    ///
    /// @notice Array to store the the levels and puzzles collection ids
    /// @dev Each ID is stored in 2 slots of the variable. Ex: IDs {00, 01, 02, ..., 30, 31}
    uint256 public constant COLLECTION_IDS =
        3130292827262524232221201918171615141312111009080706050403020100;
    /// @notice Array to store the entry batchs' IDs
    /// @dev Key: Entry batch number, reutrns enough to compute TokenID, max lotation and current token ID.
    uint24[] public entryIdsArray;
    /// @notice Mapping to tack number of user puzzle pieces
    /// @dev Key: Ke: user address, returns user puzzle pieces for all levels (separated the same way as COLLECTION_IDS).
    mapping(address => uint32) public userPuzzlePieces;
    /// @notice The address of SLLogics contract.
    /// @dev This value is set at the time of contract deployment.
    address public slLogicsAddress;
    /// @notice The address of Access control contract.
    /// @dev This value is set at the time of contract deployment.
    address public slPermissionsAddress;

    ///
    //-----EVENTS------
    ///
    /// @notice An event that is emitted when a user mint a level or a piece NFT.
    /// @param claimer The address of said user.
    /// @param tokenId The id of the collection minted from.
    event TokensClaimed(address indexed claimer, uint256 indexed tokenId);

    ///
    //-----ERRORS------
    ///
    /// @notice Reverts if a certain address == address(0)
    /// @param reason which address is missing
    error InvalidAddress(string reason);

    /// @notice Reverts if input is not in level range
    /// @param input level inputed
    /// @param min minimum level value
    /// @param max maximum level value
    error InvalidLevel(uint256 input, uint256 min, uint256 max);

    /// @notice Reverts if user is not at least at contract level
    /// @param expectedLevel expected user minimum level
    /// @param userLevel user level
    error IncorrectUserLevel(uint256 expectedLevel, uint256 userLevel);

    /// @notice Reverts if user don't have the complete puzzle
    /// @param level level of the required puzzle
    error UserMustHaveCompletePuzzle(uint256 level);

    /// @notice Reverts if there is no entry batch
    error InexistentEntryBatch();

    /// @notice Reverts if there is no tokens remaining on current entry batch
    error NoTokensRemaining();

    /// @notice Reverts if platform is paused
    error PlatformPaused();

    ///Function caller is not CEO level
    error EntryMintPaused();

    ///Function caller is not CEO level
    error ClaimingPaused();

    ///Function caller is not CEO level
    error NotCEO();

    constructor() ERC1155("Something Legendary") {}

    ///
    //-----WRITTING FUNCTIONS------
    ///
    /// @notice function call the necessary functions to try to pass the user to the next one
    /// @dev puzzle tokens required to pass the level are burned during the transaction
    /// @param _receiver the recevier of the level (the user).
    /// @param _tokenId the collection id that the user wants to mint from
    /// @custom:requires _tokenId should be 30(level 2) or 31(level 3)
    function _claimLevel(address _receiver, uint256 _tokenId) internal {
        if (_tokenId < 30) {
            revert InvalidLevel(_tokenId, 30, 31);
        }
        if (_tokenId > 31) {
            revert InvalidLevel(_tokenId, 30, 31);
        }
        //Check if user has the right to claim the next level or puzzle piece
        verifyClaim(msg.sender, _tokenId);

        //Burn puzzle pieces
        _dealWithPuzzleBurning(_receiver, _tokenId);
        //Transfer tokens to user
        _transferTokensOnClaim(_receiver, _tokenId, 1);

        emit TokensClaimed(_receiver, _tokenId);
    }

    /// @notice function call the necessary functions to try to mint a puzzle piece for the user
    /// @dev puser must be in the same level as the piece his minting
    /// @param _receiver the recevier of the puzzle piece (the user).
    /// @param _puzzleLevel the level from which the user wants to mint the puzzle from
    function _claimPiece(address _receiver, uint256 _puzzleLevel) internal {
        if (_puzzleLevel == 0) {
            revert InvalidLevel(_puzzleLevel, 1, 3);
        }
        if (_puzzleLevel > 3) {
            revert InvalidLevel(_puzzleLevel, 1, 3);
        }
        //Check if user has the right to claim the next level or puzzle piece
        verifyClaim(msg.sender, _puzzleLevel);
        //Transfer tokens to user
        _transferTokensOnClaim(
            _receiver,
            _dealWithPuzzleClaiming(_receiver, _puzzleLevel),
            1
        );

        emit TokensClaimed(_receiver, _puzzleLevel);
    }

    ///
    //-------------------------FUNCTIONS TO BE OVERRIDEN----------------------
    ///
    /// @notice Verifies if user can claim given piece or level NFT
    /// @dev Override the verify claim function to check if user has the right to claim the next level or puzzle piece
    /// @param _claimer the user's address
    /// @param _tokenIdOrPuzzleLevel The token id of the level (30 or 30) or LEvel of the piece (1,2,3)
    function verifyClaim(
        address _claimer,
        uint256 _tokenIdOrPuzzleLevel
    ) public view virtual {}

    /// @notice returns random number
    function _random() public view virtual returns (uint8) {}

    ///
    //-----------------INTERNAL OVERRIDE FUNCTIONS----------------
    ///
    /// @notice Function that defines which piece is going to be minted
    /// @dev Override to implement puzzle piece claiming logic
    /// @param _receiver the user's address
    /// @param _puzzleLevel The level of the piece (1,2,3)
    /// @return _collectionToMint the collection from which the piece is going to be minted
    function _dealWithPuzzleClaiming(
        address _receiver,
        uint256 _puzzleLevel
    ) internal virtual returns (uint8 _collectionToMint) {}

    /// @notice Auxiliary function to burn user puzzle depending on his level
    /// @dev burns in batch to be gas wiser
    /// @param _user the user's address
    /// @param _levelId The id of piece's level (lvl 2->30, lvl3->31)
    function _dealWithPuzzleBurning(address _user, uint256 _levelId) private {
        //Helpers
        uint256 helperSize = 10;
        uint256[] memory amountsForBurn = new uint256[](helperSize);
        //Fill needed arrays
        for (uint256 i; i < helperSize; ++i) {
            amountsForBurn[i] = 1;
        }
        //Puzzle verification for passing to level2
        if (_levelId == 30) {
            //Burn user puzzle right away (so verify claim doesnt get to big)
            _burnBatch(_user, _getPuzzleCollectionIds(1), amountsForBurn);
            //Puzzle verification for passing to level3
        } else if (_levelId == 31) {
            _burnBatch(_user, _getPuzzleCollectionIds(2), amountsForBurn);
        }
    }

    /// @notice Function that verifies if user is allowed to pass to the next level
    /// @dev function have no return, it should fail if user is not allowed to burn
    /// @param _claimer the user's address
    /// @param _levelId The id of piece's level (lvl 2->30, lvl3->31)
    function _userAllowedToBurnPuzzle(
        address _claimer,
        uint256 _levelId
    ) public view virtual {}

    ///
    //----------------INTERNAL NON-OVERRIDE FUNCTIONS------------------
    ///
    /// @notice Increments by 1 the number of user puzzle pieces in a specified level
    /// @dev Uses SLMicroSlots to write in a variable in such format "333222111"
    /// (where 333 -> Nº of LVL3 pieces, 222 -> Nº of LVL2 pieces, 111 -> Nº of LVL1 pieces)
    /// @param _user user's address
    /// @param _puzzleLevel level in which we want to increment the amount by 1
    function _incrementUserPuzzlePieces(
        address _user,
        uint256 _puzzleLevel
    ) internal {
        userPuzzlePieces[_user] = incrementXPositionInFactor3(
            userPuzzlePieces[_user],
            uint32(_puzzleLevel)
        );
    }

    /// @notice function to mint tokens on claim
    /// @param _receiver user's address
    /// @param _tokenId the id of the collection from which the NFT should be minted
    /// @param _quantity quantity to mint
    function _transferTokensOnClaim(
        address _receiver,
        uint256 _tokenId,
        uint256 _quantity
    ) internal {
        _mint(_receiver, _tokenId, _quantity, "");
    }

    ///
    //------------------GETTERS MOST OVERRIDEN------------------------
    ///
    /// @notice funtion that returns the level token ids
    /// @dev should be overriden
    /// @param level the level that we want the token IDs
    /// @return uint256[] memory with ids for level 2 and 3 (30,31) or all level 1 collection ids
    function _getLevelTokenIds(
        uint256 level
    ) internal view virtual returns (uint256[] memory) {}

    /// @notice funtion that returns the puzzle pieces for a specified level
    /// @dev should be overriden
    /// @param level the level that we want the token IDs
    /// @return uint256[] memory with 10 ids for 10 pieces
    function _getPuzzleCollectionIds(
        uint256 level
    ) public view virtual returns (uint256[] memory) {}

    //
    /// @notice function to create a user address array with the given size
    /// @param _user user intented to create the array
    /// @param _size size of new array
    /// @return uint256[] memory with size slots of user addresses
    function _createUserAddressArray(
        address _user,
        uint256 _size
    ) internal pure returns (address[] memory) {
        address[] memory userAddress = new address[](_size);
        for (uint256 i; i < _size; ++i) {
            userAddress[i] = _user;
        }
        return userAddress;
    }

    ///
    //---- MODIFIERS------
    ///
    /// @notice Verifies if user is CEO.
    /// @dev CEO has the right to interact with certain functions
    modifier isCEO() {
        if (!ISLPermissions(slPermissionsAddress).isCEO(msg.sender)) {
            revert NotCEO();
        }
        _;
    }
    /// @notice Verifies if entry minting is not paused.
    /// @dev If it is paused, the only available actions are claimLevel() and claimPiece()
    modifier isEntryMintNotPaused() {
        if (ISLPermissions(slPermissionsAddress).isEntryMintPaused()) {
            revert EntryMintPaused();
        }
        _;
    }
    /// @notice Verifies if puzzle and level 2 and 3 minting is stoped.
    /// @dev If it is paused, the only action available is mintEntry()
    modifier isPuzzleMintNotPaused() {
        if (ISLPermissions(slPermissionsAddress).isClaimPaused()) {
            revert ClaimingPaused();
        }
        _;
    }
    /// @notice Verifies if platform is paused.
    /// @dev If platform is paused, the whole contract is stopped
    modifier isNotGloballyStoped() {
        if (ISLPermissions(slPermissionsAddress).isPlatformPaused()) {
            revert PlatformPaused();
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISLPermissions {
    function isCEO(address _address) external view returns (bool);

    function isCFO(address _address) external view returns (bool);

    function isCLevel(address _address) external view returns (bool);

    function isAllowedContract(address _address) external view returns (bool);

    function isPlatformPaused() external view returns (bool);

    function isInvestmentsPaused() external view returns (bool);

    function isClaimPaused() external view returns (bool);

    function isEntryMintPaused() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title SLMicroSlots
/// @author Something Legendary
/// @notice Computes numbers that are stored in slots inside uint256 values
/// @dev this contract doesnt set state, it should be used in the inherited one
contract SLMicroSlots {
    /// @notice Reverts if input is not in level range
    /// @param input inputed number
    /// @param max max input value
    error InvalidNumber(uint256 input, uint256 max);

    //Get a number of digits in x position of a number
    /// @notice Returns the position X in slots of Y size in a given number.
    /// @param number the uint256 from where the result is extracted
    /// @param position the psotion of the result
    /// @param factor number of algarisms in result
    /// @return uint256 the specified position in a number
    function getPositionXInDivisionByY(
        uint256 number,
        uint256 position,
        uint256 factor
    ) internal view returns (uint256) {
        return
            ((number % (10 ** (factor * position))) -
                (number % (10 ** ((factor * position) - factor)))) /
            (10 ** (position * factor - factor));
    }

    /// @notice Returns an array of X positions in slots of Y size in a given number.
    /// @param number the uint256 from where the result is extracted
    /// @param startPosition the position of the 1st element
    /// @param numberOfResults number of results needed
    /// @param factor number of algarisms in each result
    /// @return uint256 the specified position in a number
    function getMultiplePositionsXInDivisionByY(
        uint256 number,
        uint256 startPosition,
        uint256 numberOfResults,
        uint256 factor
    ) internal view returns (uint256[] memory) {
        uint256[] memory results = new uint256[](numberOfResults);
        for (uint256 i; i < numberOfResults; ++i) {
            results[i] = (
                getPositionXInDivisionByY(number, startPosition + i, factor)
            );
        }
        return results;
    }

    /// @notice mount the entry value for storage
    /// @dev currentID can never be more than 9999
    /// @param cap Collection limit
    /// @param currentID the current token Id
    /// @return uint24 the current information of the current lvl1 batch
    function mountEntryValue(
        uint256 cap,
        uint256 currentID
    ) internal view returns (uint24) {
        return uint24((cap * 10000) + currentID);
    }

    /// @notice unmount the entry value for checking
    /// @dev the returns allows checking for limit of NFT minting
    /// @param value the information regarding current level1 batch
    /// @return cap Collection limit
    /// @return currentID the current token Id
    function unmountEntryValue(
        uint24 value
    ) internal view returns (uint256 cap, uint256 currentID) {
        currentID = getPositionXInDivisionByY(value, 1, 4);
        cap = (value - currentID) / 10000;
    }

    /// @notice mount the entry ID for ERC1155 minting
    /// @dev entryID is defined with 2 static parameters of an entry batch, the batch number and the limit of minting
    /// @param batch the number of the collection of entry NFTs
    /// @param cap Collection limit
    /// @return uint256 the ID from which the specified batch should be minted
    function mountEntryID(
        uint256 batch,
        uint256 cap
    ) internal view returns (uint256) {
        return ((batch * 10000) + cap);
    }

    /// @notice unmount the entry ID
    /// @dev This allows to relationate the batch with its cap
    /// @param id the level1 batch ID that needs to be read
    /// @return batch the number of the collection of entry NFTs
    /// @return cap Collection limit
    function unmountEntryID(
        uint256 id
    ) public view returns (uint256 batch, uint256 cap) {
        cap = getPositionXInDivisionByY(id, 1, 4);
        batch = (id - cap) / 10000;
    }

    /// @notice Function to increment a parcel of the number by 1
    /// @dev if number gets to 999 next number will be 0. since it is using a factor of 3 number per parcel
    /// @param number the uint256 where the number is going to be incremented
    /// @param position the position for incrementing
    /// @return _final the number with the incremented parcel
    function incrementXPositionInFactor3(
        uint32 number,
        uint32 position
    ) internal view returns (uint32 _final) {
        //Verify if digit is incrementable
        uint32 digit = uint32(getPositionXInDivisionByY(number, position, 3));
        if (digit == 999) {
            digit = 0;
        } else {
            digit++;
        }
        //remount the number with the incremented parcel
        _final = uint32(
            (number / 10 ** (position * 3)) *
                10 ** (position * 3) +
                digit *
                10 ** (position * 3 - 3) +
                (number % (10 ** (position * 3 - 3)))
        );
    }

    /// @notice Function to change a specific parcel of a number. -In parcels of 5 digits
    /// @dev Since it is using a facotr of 5, number cannot be bigger than 99999
    /// @param number the uint256 where the number is going to be replaced
    /// @param position the position for changing
    /// @param position the new parcel
    /// @return _final the number with the replaced parcel
    function changetXPositionInFactor5(
        uint256 number,
        uint32 position,
        uint256 newNumber
    ) internal view returns (uint256 _final) {
        //Verify if digit is incrementable
        if (newNumber > 99999) {
            revert InvalidNumber(newNumber, 99999);
        }

        //remount the number with new number using internal function
        _final =
            (number / 10 ** (position * 5)) *
            10 ** (position * 5) +
            newNumber *
            10 ** (position * 5 - 5) +
            (number % (10 ** (position * 5 - 5)));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/ERC1155.sol)

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
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) public view virtual override returns (uint256[] memory) {
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
        _setApprovalForAll(_msgSender(), operator, approved);
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
            "ERC1155: caller is not token owner or approved"
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
            "ERC1155: caller is not token owner or approved"
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
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

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

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

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
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
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

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address from, uint256 id, uint256 amount) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
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

    /**
     * @dev Hook that is called after any token transfer. This includes minting
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
    function _afterTokenTransfer(
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
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
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
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/IERC1155.sol)

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
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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