// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
__/\\\\____________/\\\\__/\\\\\\\\\\\\\\\__/\\\\____________/\\\\__/\\\\\\\\\\\\\\\________/\\\\\\\\\\\\\\\__/\\\\\\\\\\\\\\\__/\\\________/\\\_        
 _\/\\\\\\________/\\\\\\_\/\\\///////////__\/\\\\\\________/\\\\\\_\////////////\\\________\/\\\///////////__\///////\\\/////__\/\\\_______\/\\\_       
  _\/\\\//\\\____/\\\//\\\_\/\\\_____________\/\\\//\\\____/\\\//\\\___________/\\\/_________\/\\\___________________\/\\\_______\/\\\_______\/\\\_      
   _\/\\\\///\\\/\\\/_\/\\\_\/\\\\\\\\\\\_____\/\\\\///\\\/\\\/_\/\\\_________/\\\/___________\/\\\\\\\\\\\___________\/\\\_______\/\\\\\\\\\\\\\\\_     
    _\/\\\__\///\\\/___\/\\\_\/\\\///////______\/\\\__\///\\\/___\/\\\_______/\\\/_____________\/\\\///////____________\/\\\_______\/\\\/////////\\\_    
     _\/\\\____\///_____\/\\\_\/\\\_____________\/\\\____\///_____\/\\\_____/\\\/_______________\/\\\___________________\/\\\_______\/\\\_______\/\\\_   
      _\/\\\_____________\/\\\_\/\\\_____________\/\\\_____________\/\\\___/\\\/_________________\/\\\___________________\/\\\_______\/\\\_______\/\\\_  
       _\/\\\_____________\/\\\_\/\\\\\\\\\\\\\\\_\/\\\_____________\/\\\__/\\\\\\\\\\\\\\\__/\\\_\/\\\\\\\\\\\\\\\_______\/\\\_______\/\\\_______\/\\\_ 
        _\///______________\///__\///////////////__\///______________\///__\///////////////__\///__\///////////////________\///________\///________\///__*/

import {Owned} from "solmate/auth/Owned.sol";
import {SSTORE2} from "solmate/utils/SSTORE2.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {toWadUnsafe, toDaysWadUnsafe} from "solmate/utils/SignedWadMath.sol";

import {LibGOO} from "goo-issuance/LibGOO.sol";
import {LogisticVRGDA} from "VRGDAs/LogisticVRGDA.sol";

import {IPolyAdapter} from "./interfaces/IPolyAdapter.sol";
import {LibString} from "./libraries/LibString.sol";
import {NFTMeta} from "./libraries/NFTMeta.sol";
import {MemzERC721} from "./utils/token/MemzERC721.sol";
import {Goo} from "./Goo.sol";
import {Pages} from "./Pages.sol";

/// @title Memz.eth
/// 100% on-chain UGC (user-generated-content) RWE (real-world-events) NFT Protocol.
/// @author smarsx @_smarsx
/// @author Inspired by Art Gobblers (https://github.com/artgobblers/art-gobblers).
/// @dev "borrowing" PolyMarket's UMA oracles :)
/// @custom:experimental This is an experimental contract. (NO PROFESSIONAL AUDIT, USE AT YOUR OWN RISK)
contract Memz is MemzERC721, LogisticVRGDA, Owned {
    using LibString for uint256;

    /// @notice Max supply per question.
    uint256 public constant SUPPLY_PER_QUESTION = 500;

    /// @notice Max submissions per question.
    uint256 public constant MAX_SUBMISSIONS = 100;

    /// @notice The protocol fee numerator.
    uint256 public constant FEE_NUMERATOR = 5;

    /// @notice The protocol fee denominator.
    uint256 public constant FEE_DENOMINATOR = 100;

    /// @notice The royalty denominator.
    /// @dev Allows measurement in bps (basis points).
    uint256 public constant ROYALTY_DENOMINATOR = 10000;

    /// @notice The period post start that allows emergency resolve.
    uint256 public constant EMERGENCY_RESOLVE_TIME = 100 days;

    /// @notice The adapter to communicate with oracles.
    /// @dev Can update to add/sub support for oracles.
    IPolyAdapter public polyAdapter;

    /// @notice The address of Goo contract.
    Goo public immutable goo;

    /// @notice The address of Pages contract.
    Pages public immutable pages;

    /// @notice The address of Reserve vault.
    address public immutable vault;

    /// @notice The previously minted token id.
    uint96 public prevTokenID;

    /// @notice The url to access Memz.
    /// @dev BaseURI takes precedence over on-chain render in tokenURI.
    /// Can always call _tokenURI to use on-chain render.
    string private baseURI;

    /// @notice Outcomes for an event.
    enum Outcome {
        UNRESOLVED,
        YES,
        NO,
        TIE
    }

    /*//////////////////////////////////////////////////////////////
                            Question State
    //////////////////////////////////////////////////////////////*/

    struct Question {
        // Which oracle.
        IPolyAdapter.Adapter adapter;
        // The outcome of Question.
        Outcome outcome;
        // Tokens minted for Question.
        uint16 count;
        // Starting timestamp.
        uint48 start;
        // Winning pageId.
        uint64 winningPageId;
        // Total proceeds.
        uint112 proceeds;
        // Question title.
        string title;
        // Submissions to Question.
        uint256[] pages;
    }

    /// @notice Maps QuestionID to Question struct.
    mapping(bytes32 => Question) public questions;

    /// @notice Returns page ids[] submitted for a question.
    function getPages(bytes32 _questionID) public view returns (uint256[] memory) {
        return questions[_questionID].pages;
    }

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event NewQuestion(
        bytes32 indexed _questionID,
        IPolyAdapter.Adapter _adapter,
        uint256 _start,
        string _title
    );
    event NewArt(
        bytes32 indexed _questionID,
        address indexed _creator,
        uint256 _pageID,
        uint256 _royalty,
        string _description
    );
    event Vote(uint256 indexed _pageID, uint256 _amt);
    event NewOutcome(bytes32 indexed _questionID, Outcome _outcome);
    event Winner(bytes32 indexed _questionID, address indexed _creator, uint256 _pageID);
    event MemzUpgraded(uint256 _id);

    event GooBalanceUpdated(address indexed _user, uint256 _newGooBalance);
    event SetPolyAdapter(address _adapter);
    event SetBaseURI(string _baseURI);
    event EmergencyResolve(bytes32 indexed _questionID);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error InvalidID();
    error NoPages();

    error Resolved();
    error NotResolved();

    error ArtSet();
    error ArtNotSet();

    error BadOutcome();
    error AdapterError();

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets up initial conditions.
    /// @param _goo Address of the Goo contract.
    /// @param _pages Address of the Pages contract.
    /// @param _polyAdapter Address of the PolyAdapter contract.
    /// @param _vault Address of the reserve vault.
    constructor(
        Goo _goo,
        Pages _pages,
        IPolyAdapter _polyAdapter,
        address _vault
    )
        MemzERC721("Memz", "MEMZ")
        Owned(msg.sender)
        LogisticVRGDA(
            100e18, // Target price.
            0.31e18, // Price decay percent.
            toWadUnsafe(SUPPLY_PER_QUESTION),
            .066e18 // Per time unit.
        )
    {
        goo = _goo;
        pages = _pages;
        polyAdapter = _polyAdapter;
        vault = _vault;

        emit SetPolyAdapter(address(_polyAdapter));
    }

    /*///////////////////////////////////////////////////////////////////
                            QUESTION MANAGEMENT
    //////////////////////////////////////////////////////////////////*/

    /// @notice Create new question.
    /// @dev Utilizes a custom batchMint to mint the initial batch to a vault for artist/protocol.
    /// @param _questionID QuestionID.
    /// @param _adapter Oracle adapter.
    /// @param _start Timestamp to open minting.
    /// @param _title Title of question.
    function create(
        bytes32 _questionID,
        IPolyAdapter.Adapter _adapter,
        uint256 _start,
        string calldata _title
    ) external onlyOwner {
        if (questions[_questionID].start > 0) revert InvalidID();

        // cheaper than init new Question({})
        questions[_questionID].adapter = _adapter;
        questions[_questionID].start = uint48(_start);
        questions[_questionID].title = _title;
        questions[_questionID].count = uint16(VAULT_NUM);

        // batch mint to vault
        prevTokenID = uint96(_batchMint(address(vault), uint256(prevTokenID), _questionID));

        emit NewQuestion(_questionID, _adapter, _start, _title);

        // untrusted external calls
        // ensure questionID initialized in Uma ctx and not resolved else revert.
        (bool initialized, bool resolved) = polyAdapter.getInitializedAndResolved(
            _questionID,
            _adapter
        );
        if (initialized && !resolved) {} else {
            revert AdapterError();
        }
    }

    /// @notice Set outcome for a given question.
    /// @dev Reverts on different response from adapter.
    /// @param _questionID Question to set outcome for.
    /// @param _outcome Outcome to compare against adapter result.
    function setOutcome(bytes32 _questionID, Outcome _outcome) external {
        // cheaper to cache
        Outcome outcome = questions[_questionID].outcome;
        IPolyAdapter.Adapter adapter = questions[_questionID].adapter;

        if (outcome != Outcome.UNRESOLVED) revert Resolved();

        // optimistically write to state
        questions[_questionID].outcome = _outcome;

        emit NewOutcome(_questionID, _outcome);

        // untrusted external calls
        // revert if question not resolved
        (, bool resolved) = polyAdapter.getInitializedAndResolved(_questionID, adapter);
        if (!resolved) revert NotResolved();

        // if _outcome matches payouts, maintain optimistic state changes, else revert.
        uint256[] memory payouts = polyAdapter.getPayout(_questionID, adapter);
        if (_outcome == Outcome.YES) {
            if (payouts[0] == 1 && payouts[1] == 0) {} else {
                revert BadOutcome();
            }
        } else if (_outcome == Outcome.NO) {
            if (payouts[0] == 0 && payouts[1] == 1) {} else {
                revert BadOutcome();
            }
        } else if (_outcome == Outcome.TIE) {
            if (payouts[0] == 1 && payouts[1] == 1) {} else {
                revert BadOutcome();
            }
        } else {
            revert BadOutcome();
        }
    }

    /// @notice Tally votes and store winning PageID in Question.
    /// @param _questionID questionID.
    function setWinner(bytes32 _questionID) external {
        // smells like excessive caching but saves gas in my tests.
        Question memory question = questions[_questionID];
        uint256[] memory _pages = question.pages;
        uint256 len = _pages.length;

        // require event is resolved
        if (question.outcome == Outcome.UNRESOLVED) revert NotResolved();

        // require winning page not set.
        if (question.winningPageId > 0) revert ArtSet();

        // find top voted page
        if (len == 0) revert NoPages();

        uint256 largest;
        uint256 idx;
        for (uint256 i; i < len; ) {
            (, , uint256 votes) = pages.metadatas(_pages[i]);
            if (votes > largest) {
                idx = i;
                largest = votes;
            }
            unchecked {
                ++i;
            }
        }

        // cache top voted metadata
        uint256 pageID = _pages[idx];

        // write metadata to storage
        questions[_questionID].winningPageId = uint64(pageID);

        emit Winner(_questionID, pages.ownerOf(pageID), pageID);
    }

    /// @notice Payout (proceeds - fee) to owner of winning PageID.
    /// @param _questionID questionID.
    function payout(bytes32 _questionID) external {
        // cache saves gas
        // ownerOf reverts on owner = address(0).
        address creator = pages.ownerOf(questions[_questionID].winningPageId);
        uint256 proceeds = uint256(questions[_questionID].proceeds);

        if (proceeds > 0) {
            uint256 fee = FixedPointMathLib.mulDivDown(proceeds, FEE_NUMERATOR, FEE_DENOMINATOR);

            // clear proceeds before transfers.
            delete questions[_questionID].proceeds;

            SafeTransferLib.safeTransferETH(owner, fee);
            SafeTransferLib.safeTransferETH(creator, proceeds - fee);
        }
    }

    /*///////////////////////////////////////////////////////////////////
                                USER ACTIONS
    //////////////////////////////////////////////////////////////////*/

    /// @notice Mint Memz.
    /// @param _questionID questionID.
    /// @param _prediction Users prediction.
    /// @dev Allows any prediction, but 1,2,3 are the only "valid" inputs.
    function mint(bytes32 _questionID, uint256 _prediction) external payable {
        // cache start
        uint256 start = uint256(questions[_questionID].start);

        // at least 1 page has been submitted
        if (questions[_questionID].pages.length == 0) revert NoPages();
        // outcome is unresolved
        if (questions[_questionID].outcome != Outcome.UNRESOLVED) revert Resolved();
        // question exists (_start is only set in create())
        if (start == 0) revert InvalidID();

        // Note: We don't need to check question.count < SUPPLY_PER_QUESTION, because getVRGDAPrice will
        // revert if we're over the max mintable limit we set when constructing LogisticVRGDA.

        // unrealistic for price, or proceeds to overflow.
        unchecked {
            uint256 price = memzPrice(start, questions[_questionID].count);

            if (msg.value < price) revert("insufficient funds");

            // write to storage
            ++questions[_questionID].count;
            questions[_questionID].proceeds += uint96(price);

            _mint(msg.sender, ++prevTokenID, _questionID, _prediction);

            // refund overpaid
            SafeTransferLib.safeTransferETH(msg.sender, msg.value - price);
        }
    }

    /// @notice Submit art to a question.
    /// @dev No safeguards on question, typeuri, royalty, description, & blob inputs.
    /// @param _questionID QuestionID.
    /// @param _typeUri TypeURI enum. Only two options html/svg.
    /// @param _royalty Royalty in basis points.
    /// @param _description Description to be used in URI.
    /// @param _blob Html or svg string blob.
    function submit(
        bytes32 _questionID,
        uint256 _pageID,
        NFTMeta.TypeURI _typeUri,
        uint256 _royalty,
        string calldata _description,
        string calldata _blob
    ) external {
        // check max pages
        if (questions[_questionID].pages.length >= MAX_SUBMISSIONS) revert("maxsubs");

        // sender is owner of page
        if (pages.ownerOf(_pageID) != msg.sender) revert("owner");

        address pointer = SSTORE2.write(
            NFTMeta.constructTokenURI(
                NFTMeta.MetaParams({
                    typeUri: _typeUri,
                    name: questions[_questionID].title,
                    description: _description,
                    blob: _blob
                })
            )
        );

        // write royalty & pointer to metadata, reverts on pointer already set.
        pages.setMetadata(_pageID, _royalty, pointer);

        // add page to question pages list
        questions[_questionID].pages.push(_pageID);

        emit NewArt(_questionID, msg.sender, _pageID, _royalty, _description);
    }

    /// @notice Vote for a page.
    /// @param _pageID Page id to cast vote for.
    /// @param _goo Amount of goo to spend.
    /// @param _useVirtualBalance Use virtual balance vs. wallet balance.
    /// @dev Similar to submit, no safeguards. Allows voting for invalid pages (past, future, & invalid) pages.
    function vote(uint256 _pageID, uint256 _goo, bool _useVirtualBalance) external {
        // update user goo balance
        // reverts on balance < _goo
        _useVirtualBalance
            ? updateUserGooBalance(msg.sender, _goo, GooBalanceUpdateType.DECREASE)
            : goo.burnGoo(msg.sender, _goo);

        // update pages.votes balance
        pages.addVotes(_pageID, _goo);

        emit Vote(_pageID, _goo);
    }

    /// @notice Upgrade emission multiple.
    /// @dev If original prediction was correct, can upgrade emission multiple
    /// yes/no +2, tie +4.
    /// @param _id TokenID to upgrade.
    function upgradeEmissionMultiple(uint256 _id) external {
        if (getMemzData[_id].upgraded) revert("max");
        Outcome outcome = questions[getMemzData[_id].questionID].outcome;
        uint256 prediction = uint256(getMemzData[_id].prediction);
        if (outcome != Outcome.UNRESOLVED && outcome == Outcome(prediction)) {
            uint32 addition = outcome == Outcome.TIE ? 4 : prediction > 8 ? 3 : 2;
            getMemzData[_id].upgraded = true;
            getMemzData[_id].emissionMultiple += addition;
            getUserData[msg.sender].emissionMultiple += addition;
            emit MemzUpgraded(_id);
        }
    }

    /*//////////////////////////////////////////////////////////////
                                MEMZ LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Gets tokenURI from baseURI or _tokenURI.
    function tokenURI(uint256 _id) public view virtual override returns (string memory) {
        return
            bytes(baseURI).length == 0
                ? _tokenURI(_id)
                : string(abi.encodePacked(baseURI, _id.toString()));
    }

    /// @notice Render tokenURI.
    /// @param _id TokenID.
    function _tokenURI(uint256 _id) public view returns (string memory) {
        bytes32 questionID = getMemzData[_id].questionID;
        if (questionID == bytes32(0)) revert InvalidID();
        if (questions[questionID].winningPageId == 0) {
            // unrevealed
            return
                NFTMeta.constructBaseTokenURI(
                    questions[questionID].title,
                    getMemzData[_id].prediction
                );
        } else {
            // revealed
            (, address pointer, ) = pages.metadatas(questions[questionID].winningPageId);
            return
                NFTMeta.renderWithTraits(
                    string(SSTORE2.read(pointer)),
                    getMemzData[_id].emissionMultiple,
                    getMemzData[_id].upgraded
                );
        }
    }

    /// @notice Returns whether tokenID made correct prediction.
    /// @param _id TokenID.
    function wasCorrect(uint256 _id) public view returns (bool) {
        Outcome outcome = questions[getMemzData[_id].questionID].outcome;
        return outcome != Outcome.UNRESOLVED && outcome == Outcome(getMemzData[_id].prediction);
    }

    /// @notice Memz pricing in ether by question.
    /// @param _questionID questionID.
    function memzPrice(bytes32 _questionID) public view returns (uint256) {
        uint256 timeSinceStart = block.timestamp - questions[_questionID].start;
        uint256 numMinted = questions[_questionID].count;
        unchecked {
            return getVRGDAPrice(toDaysWadUnsafe(timeSinceStart), numMinted);
        }
    }

    /// @notice Memz pricing in ether.
    /// @dev Will revert if called before minting starts
    /// or if count > SUPPLY_PER_QUESTION. (logistic asymptote).
    /// @return Current price of a memz in terms of ether.
    function memzPrice(uint256 _mintStart, uint256 _numMinted) internal view returns (uint256) {
        unchecked {
            uint256 timeSinceStart = block.timestamp - _mintStart;
            return getVRGDAPrice(toDaysWadUnsafe(timeSinceStart), _numMinted);
        }
    }

    /*//////////////////////////////////////////////////////////////
                                GOO LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Calculate a user's virtual goo balance.
    /// @param _user The user to query balance for.
    function gooBalance(address _user) public view returns (uint256) {
        // Compute the user's virtual goo balance using LibGOO.
        // prettier-ignore
        return LibGOO.computeGOOBalance(
            getUserData[_user].emissionMultiple,
            getUserData[_user].lastBalance,
            uint256(toDaysWadUnsafe(block.timestamp - getUserData[_user].lastTimestamp))
        );
    }

    /// @notice Add goo to your emission balance,
    /// burning the corresponding ERC20 balance.
    /// @param _gooAmount The amount of goo to add.
    function addGoo(uint256 _gooAmount) external {
        // Burn goo being added to memz.
        goo.burnGoo(msg.sender, _gooAmount);

        // Increase msg.sender's virtual goo balance.
        updateUserGooBalance(msg.sender, _gooAmount, GooBalanceUpdateType.INCREASE);
    }

    /// @notice Remove goo from your emission balance, and
    /// add the corresponding amount to your ERC20 balance.
    /// @param _gooAmount The amount of goo to remove.
    function removeGoo(uint256 _gooAmount) external {
        // Decrease msg.sender's virtual goo balance.
        updateUserGooBalance(msg.sender, _gooAmount, GooBalanceUpdateType.DECREASE);

        // Mint the corresponding amount of ERC20 goo.
        goo.mintGoo(msg.sender, _gooAmount);
    }

    /// @notice Burn an amount of a user's virtual goo balance. Only callable
    /// by the Pages contract to enable purchasing pages with virtual balance.
    /// @param _user The user whose virtual goo balance we should burn from.
    /// @param _gooAmount The amount of goo to burn from the user's virtual balance.
    function burnGooForPages(address _user, uint256 _gooAmount) external {
        // The caller must be the Pages contract, revert otherwise.
        if (msg.sender != address(pages)) revert();

        // Burn the requested amount of goo from the user's virtual goo balance.
        // Will revert if the user doesn't have enough goo in their virtual balance.
        updateUserGooBalance(_user, _gooAmount, GooBalanceUpdateType.DECREASE);
    }

    /// @dev An enum for representing whether to
    /// increase or decrease a user's goo balance.
    enum GooBalanceUpdateType {
        INCREASE,
        DECREASE
    }

    /// @notice Update a user's virtual goo balance.
    /// @param _user The user whose virtual goo balance we should update.
    /// @param _gooAmount The amount of goo to update the user's virtual balance by.
    /// @param _updateType Whether to increase or decrease the user's balance by gooAmount.
    function updateUserGooBalance(
        address _user,
        uint256 _gooAmount,
        GooBalanceUpdateType _updateType
    ) internal {
        // Will revert due to underflow if we're decreasing by more than the user's current balance.
        // Don't need to do checked addition in the increase case, but we do it anyway for convenience.
        uint256 updatedBalance = _updateType == GooBalanceUpdateType.INCREASE
            ? gooBalance(_user) + _gooAmount
            : gooBalance(_user) - _gooAmount;

        // Snapshot the user's new goo balance with the current timestamp.
        getUserData[_user].lastBalance = uint128(updatedBalance);
        getUserData[_user].lastTimestamp = uint64(block.timestamp);

        emit GooBalanceUpdated(_user, updatedBalance);
    }

    /*///////////////////////////////////////////////////////////////////
                                EIP-2981 
    //////////////////////////////////////////////////////////////////*/

    /// @notice Called with the sale price to determine how much royalty
    // is owed and to whom.
    /// @param _tokenId The NFT asset queried for royalty information.
    /// @param _salePrice The sale price of the NFT asset specified by _tokenId.
    /// @return receiver Address of who should be sent the royalty payment.
    /// @return royaltyAmount The royalty payment amount for _salePrice.
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (address, uint256) {
        bytes32 questionID = getMemzData[_tokenId].questionID;
        uint256 winningPageId = uint256(questions[questionID].winningPageId);

        address creator = pages.ownerOf(winningPageId);
        (uint96 royalty, , ) = pages.metadatas(winningPageId);

        return (creator, (_salePrice * royalty) / ROYALTY_DENOMINATOR);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(MemzERC721) returns (bool) {
        return interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferFrom(address from, address to, uint256 id) public override {
        require(from == getMemzData[id].owner, "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from ||
                isApprovedForAll[from][msg.sender] ||
                msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        delete getApproved[id];

        getMemzData[id].owner = to;

        unchecked {
            uint32 emissionMultiple = getMemzData[id].emissionMultiple; // Caching saves gas.

            // We update their last balance before updating their emission multiple to avoid
            // penalizing them by retroactively applying their new (lower) emission multiple.
            getUserData[from].lastBalance = uint128(gooBalance(from));
            getUserData[from].lastTimestamp = uint64(block.timestamp);
            getUserData[from].emissionMultiple -= emissionMultiple;
            getUserData[from].memzOwned -= 1;

            // We update their last balance before updating their emission multiple to avoid
            // overpaying them by retroactively applying their new (higher) emission multiple.
            getUserData[to].lastBalance = uint128(gooBalance(to));
            getUserData[to].lastTimestamp = uint64(block.timestamp);
            getUserData[to].emissionMultiple += emissionMultiple;
            getUserData[to].memzOwned += 1;
        }

        emit Transfer(from, to, id);
    }

    /*///////////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////////*/

    /// @notice Update BaseURI / PolyAdapter
    /// @dev Combined to pass bytecode size limit :)
    function setAdapterOrUri(
        uint256 _action,
        address _polyAdapter,
        string memory _baseURI
    ) external onlyOwner {
        if (_action == 0) {
            baseURI = _baseURI;
            emit SetBaseURI(_baseURI);
        } else if (_action == 1) {
            polyAdapter = IPolyAdapter(_polyAdapter);
            emit SetPolyAdapter(_polyAdapter);
        } else {
            revert();
        }
    }

    /// @notice Emergency resolves a question to a tie.
    /// @param _questionID QuestionID to resolve.
    function emergencyResolve(bytes32 _questionID) external onlyOwner {
        if (
            questions[_questionID].start == 0 ||
            block.timestamp < questions[_questionID].start + EMERGENCY_RESOLVE_TIME
        ) revert();
        if (questions[_questionID].outcome != Outcome.UNRESOLVED) revert Resolved();

        // set to tie
        questions[_questionID].outcome = Outcome.TIE;
        emit EmergencyResolve(_questionID);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Read and write to persistent storage at a fraction of the cost.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SSTORE2.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol)
library SSTORE2 {
    uint256 internal constant DATA_OFFSET = 1; // We skip the first byte as it's a STOP opcode to ensure the contract can't be called.

    /*//////////////////////////////////////////////////////////////
                               WRITE LOGIC
    //////////////////////////////////////////////////////////////*/

    function write(bytes memory data) internal returns (address pointer) {
        // Prefix the bytecode with a STOP opcode to ensure it cannot be called.
        bytes memory runtimeCode = abi.encodePacked(hex"00", data);

        bytes memory creationCode = abi.encodePacked(
            //---------------------------------------------------------------------------------------------------------------//
            // Opcode  | Opcode + Arguments  | Description  | Stack View                                                     //
            //---------------------------------------------------------------------------------------------------------------//
            // 0x60    |  0x600B             | PUSH1 11     | codeOffset                                                     //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset                                                   //
            // 0x81    |  0x81               | DUP2         | codeOffset 0 codeOffset                                        //
            // 0x38    |  0x38               | CODESIZE     | codeSize codeOffset 0 codeOffset                               //
            // 0x03    |  0x03               | SUB          | (codeSize - codeOffset) 0 codeOffset                           //
            // 0x80    |  0x80               | DUP          | (codeSize - codeOffset) (codeSize - codeOffset) 0 codeOffset   //
            // 0x92    |  0x92               | SWAP3        | codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset)   //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset) //
            // 0x39    |  0x39               | CODECOPY     | 0 (codeSize - codeOffset)                                      //
            // 0xf3    |  0xf3               | RETURN       |                                                                //
            //---------------------------------------------------------------------------------------------------------------//
            hex"60_0B_59_81_38_03_80_92_59_39_F3", // Returns all code in the contract except for the first 11 (0B in hex) bytes.
            runtimeCode // The bytecode we want the contract to have after deployment. Capped at 1 byte less than the code size limit.
        );

        /// @solidity memory-safe-assembly
        assembly {
            // Deploy a new contract with the generated creation code.
            // We start 32 bytes into the code to avoid copying the byte length.
            pointer := create(0, add(creationCode, 32), mload(creationCode))
        }

        require(pointer != address(0), "DEPLOYMENT_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                               READ LOGIC
    //////////////////////////////////////////////////////////////*/

    function read(address pointer) internal view returns (bytes memory) {
        return readBytecode(pointer, DATA_OFFSET, pointer.code.length - DATA_OFFSET);
    }

    function read(address pointer, uint256 start) internal view returns (bytes memory) {
        start += DATA_OFFSET;

        return readBytecode(pointer, start, pointer.code.length - start);
    }

    function read(
        address pointer,
        uint256 start,
        uint256 end
    ) internal view returns (bytes memory) {
        start += DATA_OFFSET;
        end += DATA_OFFSET;

        require(pointer.code.length >= end, "OUT_OF_BOUNDS");

        return readBytecode(pointer, start, end - start);
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function readBytecode(
        address pointer,
        uint256 start,
        uint256 size
    ) private view returns (bytes memory data) {
        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            data := mload(0x40)

            // Update the free memory pointer to prevent overriding our data.
            // We use and(x, not(31)) as a cheaper equivalent to sub(x, mod(x, 32)).
            // Adding 31 to size and running the result through the logic above ensures
            // the memory pointer remains word-aligned, following the Solidity convention.
            mstore(0x40, add(data, and(add(add(size, 32), 31), not(31))))

            // Store the size of the data in the first 32 byte chunk of free memory.
            mstore(data, size)

            // Copy the code into memory right after the 32 bytes we used to store the size.
            extcodecopy(pointer, add(data, 32), start, size)
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Signed 18 decimal fixed point (wad) arithmetic library.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SignedWadMath.sol)
/// @author Modified from Remco Bloemen (https://xn--2-umb.com/22/exp-ln/index.html)

/// @dev Will not revert on overflow, only use where overflow is not possible.
function toWadUnsafe(uint256 x) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 1e18.
        r := mul(x, 1000000000000000000)
    }
}

/// @dev Takes an integer amount of seconds and converts it to a wad amount of days.
/// @dev Will not revert on overflow, only use where overflow is not possible.
/// @dev Not meant for negative second amounts, it assumes x is positive.
function toDaysWadUnsafe(uint256 x) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 1e18 and then divide it by 86400.
        r := div(mul(x, 1000000000000000000), 86400)
    }
}

/// @dev Takes a wad amount of days and converts it to an integer amount of seconds.
/// @dev Will not revert on overflow, only use where overflow is not possible.
/// @dev Not meant for negative day amounts, it assumes x is positive.
function fromDaysWadUnsafe(int256 x) pure returns (uint256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 86400 and then divide it by 1e18.
        r := div(mul(x, 86400), 1000000000000000000)
    }
}

/// @dev Will not revert on overflow, only use where overflow is not possible.
function unsafeWadMul(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by y and divide by 1e18.
        r := sdiv(mul(x, y), 1000000000000000000)
    }
}

/// @dev Will return 0 instead of reverting if y is zero and will
/// not revert on overflow, only use where overflow is not possible.
function unsafeWadDiv(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 1e18 and divide it by y.
        r := sdiv(mul(x, 1000000000000000000), y)
    }
}

function wadMul(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Store x * y in r for now.
        r := mul(x, y)

        // Equivalent to require(x == 0 || (x * y) / x == y)
        if iszero(or(iszero(x), eq(sdiv(r, x), y))) {
            revert(0, 0)
        }

        // Scale the result down by 1e18.
        r := sdiv(r, 1000000000000000000)
    }
}

function wadDiv(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Store x * 1e18 in r for now.
        r := mul(x, 1000000000000000000)

        // Equivalent to require(y != 0 && ((x * 1e18) / 1e18 == x))
        if iszero(and(iszero(iszero(y)), eq(sdiv(r, 1000000000000000000), x))) {
            revert(0, 0)
        }

        // Divide r by y.
        r := sdiv(r, y)
    }
}

/// @dev Will not work with negative bases, only use when x is positive.
function wadPow(int256 x, int256 y) pure returns (int256) {
    // Equivalent to x to the power of y because x ** y = (e ** ln(x)) ** y = e ** (ln(x) * y)
    return wadExp((wadLn(x) * y) / 1e18); // Using ln(x) means x must be greater than 0.
}

function wadExp(int256 x) pure returns (int256 r) {
    unchecked {
        // When the result is < 0.5 we return zero. This happens when
        // x <= floor(log(0.5e18) * 1e18) ~ -42e18
        if (x <= -42139678854452767551) return 0;

        // When the result is > (2**255 - 1) / 1e18 we can not represent it as an
        // int. This happens when x >= floor(log((2**255 - 1) / 1e18) * 1e18) ~ 135.
        if (x >= 135305999368893231589) revert("EXP_OVERFLOW");

        // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
        // for more intermediate precision and a binary basis. This base conversion
        // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
        x = (x << 78) / 5**18;

        // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers
        // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
        // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
        int256 k = ((x << 96) / 54916777467707473351141471128 + 2**95) >> 96;
        x = x - k * 54916777467707473351141471128;

        // k is in the range [-61, 195].

        // Evaluate using a (6, 7)-term rational approximation.
        // p is made monic, we'll multiply by a scale factor later.
        int256 y = x + 1346386616545796478920950773328;
        y = ((y * x) >> 96) + 57155421227552351082224309758442;
        int256 p = y + x - 94201549194550492254356042504812;
        p = ((p * y) >> 96) + 28719021644029726153956944680412240;
        p = p * x + (4385272521454847904659076985693276 << 96);

        // We leave p in 2**192 basis so we don't need to scale it back up for the division.
        int256 q = x - 2855989394907223263936484059900;
        q = ((q * x) >> 96) + 50020603652535783019961831881945;
        q = ((q * x) >> 96) - 533845033583426703283633433725380;
        q = ((q * x) >> 96) + 3604857256930695427073651918091429;
        q = ((q * x) >> 96) - 14423608567350463180887372962807573;
        q = ((q * x) >> 96) + 26449188498355588339934803723976023;

        /// @solidity memory-safe-assembly
        assembly {
            // Div in assembly because solidity adds a zero check despite the unchecked.
            // The q polynomial won't have zeros in the domain as all its roots are complex.
            // No scaling is necessary because p is already 2**96 too large.
            r := sdiv(p, q)
        }

        // r should be in the range (0.09, 0.25) * 2**96.

        // We now need to multiply r by:
        // * the scale factor s = ~6.031367120.
        // * the 2**k factor from the range reduction.
        // * the 1e18 / 2**96 factor for base conversion.
        // We do this all at once, with an intermediate result in 2**213
        // basis, so the final right shift is always by a positive amount.
        r = int256((uint256(r) * 3822833074963236453042738258902158003155416615667) >> uint256(195 - k));
    }
}

function wadLn(int256 x) pure returns (int256 r) {
    unchecked {
        require(x > 0, "UNDEFINED");

        // We want to convert x from 10**18 fixed point to 2**96 fixed point.
        // We do this by multiplying by 2**96 / 10**18. But since
        // ln(x * C) = ln(x) + ln(C), we can simply do nothing here
        // and add ln(2**96 / 10**18) at the end.

        /// @solidity memory-safe-assembly
        assembly {
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))
            r := or(r, shl(2, lt(0xf, shr(r, x))))
            r := or(r, shl(1, lt(0x3, shr(r, x))))
            r := or(r, lt(0x1, shr(r, x)))
        }

        // Reduce range of x to (1, 2) * 2**96
        // ln(2^k * x) = k * ln(2) + ln(x)
        int256 k = r - 96;
        x <<= uint256(159 - k);
        x = int256(uint256(x) >> 159);

        // Evaluate using a (8, 8)-term rational approximation.
        // p is made monic, we will multiply by a scale factor later.
        int256 p = x + 3273285459638523848632254066296;
        p = ((p * x) >> 96) + 24828157081833163892658089445524;
        p = ((p * x) >> 96) + 43456485725739037958740375743393;
        p = ((p * x) >> 96) - 11111509109440967052023855526967;
        p = ((p * x) >> 96) - 45023709667254063763336534515857;
        p = ((p * x) >> 96) - 14706773417378608786704636184526;
        p = p * x - (795164235651350426258249787498 << 96);

        // We leave p in 2**192 basis so we don't need to scale it back up for the division.
        // q is monic by convention.
        int256 q = x + 5573035233440673466300451813936;
        q = ((q * x) >> 96) + 71694874799317883764090561454958;
        q = ((q * x) >> 96) + 283447036172924575727196451306956;
        q = ((q * x) >> 96) + 401686690394027663651624208769553;
        q = ((q * x) >> 96) + 204048457590392012362485061816622;
        q = ((q * x) >> 96) + 31853899698501571402653359427138;
        q = ((q * x) >> 96) + 909429971244387300277376558375;
        /// @solidity memory-safe-assembly
        assembly {
            // Div in assembly because solidity adds a zero check despite the unchecked.
            // The q polynomial is known not to have zeros in the domain.
            // No scaling required because p is already 2**96 too large.
            r := sdiv(p, q)
        }

        // r is in the range (0, 0.125) * 2**96

        // Finalization, we need to:
        // * multiply by the scale factor s = 5.549…
        // * add ln(2**96 / 10**18)
        // * add k * ln(2)
        // * multiply by 10**18 / 2**96 = 5**18 >> 78

        // mul s * 5e18 * 2**96, base is now 5**18 * 2**192
        r *= 1677202110996718588342820967067443963516166;
        // add ln(2) * k * 5e18 * 2**192
        r += 16597577552685614221487285958193947469193820559219878177908093499208371 * k;
        // add ln(2**96 / 10**18) * 5e18 * 2**192
        r += 600920179829731861736702779321621459595472258049074101567377883020018308;
        // base conversion: mul 2**18 / 2**192
        r >>= 174;
    }
}

/// @dev Will return 0 instead of reverting if y is zero.
function unsafeDiv(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Divide x by y.
        r := sdiv(x, y)
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

/// @title GOO (Gradual Ownership Optimization) Issuance
/// @author transmissions11 <[email protected]>
/// @author FrankieIsLost <[email protected]>
/// @notice Implementation of the GOO Issuance mechanism.
library LibGOO {
    using FixedPointMathLib for uint256;

    /// @notice Compute goo balance based on emission multiple, last balance, and time elapsed.
    /// @param emissionMultiple The multiple on emissions to consider when computing the balance.
    /// @param lastBalanceWad The last checkpointed balance to apply the emission multiple over time to, scaled by 1e18.
    /// @param timeElapsedWad The time elapsed since the last checkpoint, scaled by 1e18.
    function computeGOOBalance(
        uint256 emissionMultiple,
        uint256 lastBalanceWad,
        uint256 timeElapsedWad
    ) internal pure returns (uint256) {
        unchecked {
            // We use wad math here because timeElapsedWad is, as the name indicates, a wad.
            uint256 timeElapsedSquaredWad = timeElapsedWad.mulWadDown(timeElapsedWad);

            // prettier-ignore
            return lastBalanceWad + // The last recorded balance.

            // Don't need to do wad multiplication since we're
            // multiplying by a plain integer with no decimals.
            // Shift right by 2 is equivalent to division by 4.
            ((emissionMultiple * timeElapsedSquaredWad) >> 2) +

            timeElapsedWad.mulWadDown( // Terms are wads, so must mulWad.
                // No wad multiplication for emissionMultiple * lastBalance
                // because emissionMultiple is a plain integer with no decimals.
                // We multiply the sqrt's radicand by 1e18 because it expects ints.
                (emissionMultiple * lastBalanceWad * 1e18).sqrt()
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {wadLn, unsafeDiv, unsafeWadDiv} from "solmate/utils/SignedWadMath.sol";

import {VRGDA} from "./VRGDA.sol";

/// @title Logistic Variable Rate Gradual Dutch Auction
/// @author transmissions11 <[email protected]>
/// @author FrankieIsLost <[email protected]>
/// @notice VRGDA with a logistic issuance curve.
abstract contract LogisticVRGDA is VRGDA {
    /*//////////////////////////////////////////////////////////////
                           PRICING PARAMETERS
    //////////////////////////////////////////////////////////////*/

    /// @dev The maximum number of tokens of tokens to sell + 1. We add
    /// 1 because the logistic function will never fully reach its limit.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 internal immutable logisticLimit;

    /// @dev The maximum number of tokens of tokens to sell + 1 multiplied
    /// by 2. We could compute it on the fly each time but this saves gas.
    /// @dev Represented as a 36 decimal fixed point number.
    int256 internal immutable logisticLimitDoubled;

    /// @dev Time scale controls the steepness of the logistic curve,
    /// which affects how quickly we will reach the curve's asymptote.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 internal immutable timeScale;

    /// @notice Sets pricing parameters for the VRGDA.
    /// @param _targetPrice The target price for a token if sold on pace, scaled by 1e18.
    /// @param _priceDecayPercent The percent price decays per unit of time with no sales, scaled by 1e18.
    /// @param _maxSellable The maximum number of tokens to sell, scaled by 1e18.
    /// @param _timeScale The steepness of the logistic curve, scaled by 1e18.
    constructor(
        int256 _targetPrice,
        int256 _priceDecayPercent,
        int256 _maxSellable,
        int256 _timeScale
    ) VRGDA(_targetPrice, _priceDecayPercent) {
        // Add 1 wad to make the limit inclusive of _maxSellable.
        logisticLimit = _maxSellable + 1e18;

        // Scale by 2e18 to both double it and give it 36 decimals.
        logisticLimitDoubled = logisticLimit * 2e18;

        timeScale = _timeScale;
    }

    /*//////////////////////////////////////////////////////////////
                              PRICING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @dev Given a number of tokens sold, return the target time that number of tokens should be sold by.
    /// @param sold A number of tokens sold, scaled by 1e18, to get the corresponding target sale time for.
    /// @return The target time the tokens should be sold by, scaled by 1e18, where the time is
    /// relative, such that 0 means the tokens should be sold immediately when the VRGDA begins.
    function getTargetSaleTime(int256 sold) public view virtual override returns (int256) {
        unchecked {
            return -unsafeWadDiv(wadLn(unsafeDiv(logisticLimitDoubled, sold + logisticLimit) - 1e18), timeScale);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPolyAdapter {
    enum Adapter {
        DEFAULT, // polymarket UmaCtfAdapter
        BINARY, // polymarket UmaCtfAdapterBinary
        INTERNAL // memz oracle resolver (not in use)
    }

    function umaAdapter() external view returns (address);

    function umaBinaryAdapter() external view returns (address);

    function getInitializedAndResolved(
        bytes32 _questionID,
        Adapter _adapter
    ) external returns (bool _initialized, bool _resolved);

    function getPayout(bytes32 _questionID, Adapter _adapter) external view returns (uint256[] memory _payout);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for converting numbers into strings and other string operations.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibString.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/LibString.sol)
library LibString {
    /// @dev Returns the base 10 decimal representation of `value`.
    function toString(uint256 value) internal pure returns (string memory str) {
        /// @solidity memory-safe-assembly
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits.
            str := add(mload(0x40), 0x80)
            // Update the free memory pointer to allocate.
            mstore(0x40, add(str, 0x20))
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            let w := not(0) // Tsk.
            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            for {
                let temp := value
            } 1 {

            } {
                str := add(str, w) // `sub(str, 1)`.
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                if iszero(temp) {
                    break
                }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Base64} from "./Base64.sol";
import {LibString} from "./LibString.sol";

/// @title NFTMeta
/// @author smarsx @_smarsx
/// @notice Provides functions for encoding html/svg in base64.
library NFTMeta {
    using LibString for uint32;

    enum TypeURI {
        SVG,
        HTML
    }

    struct MetaParams {
        TypeURI typeUri;
        string name;
        string description;
        string blob;
    }

    /// @notice Construct partial URI with no padding.
    /// @dev rest of URI will be added in render/renderWithTraits.
    /// we leave out the json closing bracket and use no padding to allow addition to json for traits
    function constructTokenURI(MetaParams memory params) public pure returns (bytes memory) {
        string memory blobHeader = params.typeUri == TypeURI.SVG
            ? '", "image": "data:image/svg+xml;base64,'
            : '", "animation_url": "data:text/html;base64,';

        string memory blob = Base64.encode(bytes(params.blob));

        return
            bytes(
                Base64.encode(
                    abi.encodePacked(
                        '{"name":"',
                        params.name,
                        '", "description":"',
                        params.description,
                        blobHeader,
                        blob,
                        '"'
                    ),
                    false,
                    // no-padding
                    true
                )
            );
    }

    /// @notice Render content with no added traits.
    /// @dev Decodes provided URI, appends a closing brace, re-encodes the concatenated result
    /// into base64. and prepends the data-uri prefix to form a valid data URI.
    function render(string memory uri) public pure returns (string memory) {
        bytes memory decodedUri = Base64.decode(uri);
        return
            string(
                abi.encodePacked(
                    bytes("data:application/json;base64,"),
                    Base64.encode(abi.encodePacked(decodedUri, bytes("}")))
                )
            );
    }

    /// @notice Render content with added traits.
    /// @dev Decode the given base64-encoded URI, concatenate it with the data-uri prefix
    /// and traits, and then re-encode the result into base64.
    function renderWithTraits(
        string memory uri,
        uint32 emissionMultiple,
        bool upgraded
    ) public pure returns (string memory) {
        string memory gold = upgraded ? ', {"value": "Gold"}' : "";
        return
            string(
                abi.encodePacked(
                    bytes("data:application/json;base64,"),
                    Base64.encode(
                        abi.encodePacked(
                            Base64.decode(uri),
                            abi.encodePacked(
                                ', "attributes": [{ "trait_type": "Emission Multiple", "value": "',
                                emissionMultiple.toString(),
                                '"}',
                                gold,
                                "]}"
                            )
                        )
                    )
                )
            );
    }

    /// @notice Construct Unrevealed URI.
    function constructBaseTokenURI(
        string memory name,
        uint56 prediction
    ) public pure returns (string memory) {
        string memory borderDescription = prediction == 1 ? "YES" : prediction == 2
            ? "NO"
            : prediction == 3
            ? "TIE"
            : "GG GL";
        string memory description = string.concat(
            "Unrevealed Memz. Prediction: ",
            borderDescription
        );
        string memory svg = Base64.encode(
            abi.encodePacked(
                generateSVGDefs(),
                generateSVGBorderText(name, borderDescription),
                "</svg>"
            )
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"',
                            name,
                            '", "description":"',
                            description,
                            '", "image": "data:image/svg+xml;base64,',
                            svg,
                            '"}'
                        )
                    )
                )
            );
    }

    function generateSVGDefs() private pure returns (string memory svg) {
        string memory a = string.concat(
            '<svg width="290" height="500" viewBox="0 0 290 500" xmlns="http://www.w3.org/2000/svg"',
            " xmlns:xlink='http://www.w3.org/1999/xlink'>",
            "<defs>",
            '<filter id="f1"><feImage result="p0" xlink:href="data:image/svg+xml;base64,',
            Base64.encode(
                abi.encodePacked(
                    "<svg width='290' height='500' viewBox='0 0 290 500' xmlns='http://www.w3.org/2000/svg'><rect width='290px' height='500px' fill='#AC3969'/></svg>"
                )
            )
        );

        string memory b = string.concat(
            '"/><feImage result="p1" xlink:href="data:image/svg+xml;base64,',
            Base64.encode(
                abi.encodePacked(
                    "<svg width='290' height='500' viewBox='0 0 290 500' xmlns='http://www.w3.org/2000/svg'><circle cx='200'cy='100'r='120px'fill='#7B68EE'/></svg>"
                )
            ),
            '"/><feImage result="p2" xlink:href="data:image/svg+xml;base64,',
            Base64.encode(
                abi.encodePacked(
                    "<svg width='290' height='500' viewBox='0 0 290 500' xmlns='http://www.w3.org/2000/svg'><circle cx='150'cy='250'r='120px'fill='#FF00FF'/></svg>"
                )
            ),
            '" />',
            '<feImage result="p3" xlink:href="data:image/svg+xml;base64,',
            Base64.encode(
                abi.encodePacked(
                    "<svg width='290' height='500' viewBox='0 0 290 500' xmlns='http://www.w3.org/2000/svg'><circle cx='130'cy='470'r='150px'fill='#87CEFA'/></svg>"
                )
            )
        );

        string memory c = string.concat(
            '" /><feBlend mode="overlay" in="p0" in2="p1" /><feBlend mode="exclusion" in2="p2" /><feBlend mode="overlay" in2="p3" result="blendOut" /><feGaussianBlur ',
            'in="blendOut" stdDeviation="42" /></filter> <clipPath id="corners"><rect width="290" height="500" rx="42" ry="42" /></clipPath>',
            '<path id="text-path-a" d="M40 12 H250 A28 28 0 0 1 278 40 V460 A28 28 0 0 1 250 488 H40 A28 28 0 0 1 12 460 V40 A28 28 0 0 1 40 12 z" />',
            '<path id="minimap" d="M234 444C234 457.949 242.21 463 253 463" />',
            '<filter id="top-region-blur"><feGaussianBlur in="SourceGraphic" stdDeviation="24" /></filter>',
            '<linearGradient id="grad-up" x1="1" x2="0" y1="1" y2="0"><stop offset="0.0" stop-color="white" stop-opacity="1" />',
            '<stop offset=".9" stop-color="white" stop-opacity="0" /></linearGradient>',
            '<linearGradient id="grad-down" x1="0" x2="1" y1="0" y2="1"><stop offset="0.0" stop-color="white" stop-opacity="1" /><stop offset="0.9" stop-color="white" stop-opacity="0" /></linearGradient>',
            '<mask id="fade-up" maskContentUnits="objectBoundingBox"><rect width="1" height="1" fill="url(#grad-up)" /></mask>',
            '<mask id="fade-down" maskContentUnits="objectBoundingBox"><rect width="1" height="1" fill="url(#grad-down)" /></mask>',
            '<mask id="none" maskContentUnits="objectBoundingBox"><rect width="1" height="1" fill="white" /></mask>',
            '<linearGradient id="grad-symbol"><stop offset="0.7" stop-color="white" stop-opacity="1" /><stop offset=".95" stop-color="white" stop-opacity="0" /></linearGradient>',
            '<mask id="fade-symbol" maskContentUnits="userSpaceOnUse"><rect width="290px" height="200px" fill="url(#grad-symbol)" /></mask></defs>',
            '<g clip-path="url(#corners)">',
            '<rect fill="#AC3969" x="0px" y="0px" width="290px" height="500px" />',
            '<rect style="filter: url(#f1)" x="0px" y="0px" width="290px" height="500px" />',
            ' <g style="filter:url(#top-region-blur); transform:scale(1.5); transform-origin:center top;">',
            '<rect fill="none" x="0px" y="0px" width="290px" height="500px" />',
            '<ellipse cx="50%" cy="0px" rx="180px" ry="120px" fill="#000" opacity="0.85" /></g>',
            '<rect x="0" y="0" width="290" height="500" rx="42" ry="42" fill="rgba(0,0,0,0)" stroke="rgba(255,255,255,0.2)" /></g>',
            '<g mask="url(#fade-symbol)"><rect fill="none" x="0px" y="0px" width="290px" height="200px" />',
            '<text y="70px" x="32px" fill="white" font-family="\'Courier New\', monospace" font-weight="200" font-size="36px">MEMZ.eth</text>',
            '<text y="95px" x="36px" fill="white" font-family="\'Courier New\', monospace" font-style="italic" font-weight="100" font-size="12px">acta non verba</text></g>'
        );

        svg = string(abi.encodePacked(a, b, c));
    }

    function generateSVGBorderText(
        string memory name,
        string memory description
    ) private pure returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                '<text text-rendering="optimizeSpeed">',
                '<textPath startOffset="-100%" fill="white" font-family="\'Courier New\', monospace" font-size="10px" xlink:href="#text-path-a">',
                name,
                unicode" • ",
                description,
                ' <animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" />',
                '</textPath> <textPath startOffset="0%" fill="white" font-family="\'Courier New\', monospace" font-size="10px" xlink:href="#text-path-a">',
                name,
                unicode" • ",
                description,
                ' <animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" /> </textPath></text>'
            )
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

import {ERC721TokenReceiver} from "solmate/tokens/ERC721.sol";

/// @notice ERC721 implementation optimized for Memz by packing balanceOf/ownerOf with user/attribute data.
/// @author smarsx @_smarsx
/// @author Modified from Art-Gobblers. (https://github.com/artgobblers/art-gobblers/blob/master/src/utils/token/GobblersERC721.sol)
/// @author Modified from Solmate. (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract MemzERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) external view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                         MEMZ/ERC721 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public constant VAULT_NUM = 10;
    uint256 public constant VAULT_PREDICTIONS =
        0x0000000000000000000000000000000000000000000001020302010102030201;

    /// @notice Struct holding memz data.
    struct MemzData {
        // The current owner of the memz.
        address owner;
        // Predicted outcome
        uint56 prediction;
        // Multiple on goo issuance.
        uint32 emissionMultiple;
        // upgraded
        bool upgraded;
        // questionID - adds an extra slot ug
        bytes32 questionID;
    }

    /// @notice Maps memz ids to their data.
    mapping(uint256 => MemzData) public getMemzData;

    /// @notice Struct holding data relevant to each user's account.
    struct UserData {
        // The total number of memz currently owned by the user.
        uint32 memzOwned;
        // The sum of the multiples of all memz the user holds.
        uint32 emissionMultiple;
        // User's goo balance at time of last checkpointing.
        uint128 lastBalance;
        // Timestamp of the last goo balance checkpoint.
        uint64 lastTimestamp;
    }

    /// @notice Maps user addresses to their account data.
    mapping(address => UserData) public getUserData;

    function ownerOf(uint256 id) external view returns (address owner) {
        require((owner = getMemzData[id].owner) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) external view returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return getUserData[owner].memzOwned;
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) external {
        address owner = getMemzData[id].owner;

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 id) public virtual;

    function safeTransferFrom(address from, address to, uint256 id) external {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(address from, address to, uint256 id, bytes calldata data) external {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id, bytes32 questionID, uint256 prediction) internal {
        // Does not check if the token was already minted or the recipient is address(0)
        // because Memz.sol manages its ids in such a way that it ensures it won't
        // double mint and will only mint to msg.sender who cannot be zero.

        // set emission multiple
        uint256 multiple = 12; // beyond 22459

        // The branchless expression below is equivalent to:
        // if (id <= 5082) newCurrentIdMultiple = 6;
        // else if (id <= 9438) newCurrentIdMultiple = 7;
        // else if (id <= 13250) newCurrentIdMultiple = 8;
        // else if (id <= 16638) newCurrentIdMultiple = 9;
        // else if (id <= 19687) newCurrentIdMultiple = 10;
        // else if (id <= 22459) newCurrentIdMultiple = 11;

        assembly {
            // prettier-ignore
            multiple := sub(sub(sub(sub(sub(sub(
                multiple, 
                lt(id, 22460)),
                lt(id, 19688)),
                lt(id, 16639)),
                lt(id, 13251)),
                lt(id, 9439)),
                lt(id, 5083)
            )
        }

        getMemzData[id].owner = to;
        getMemzData[id].questionID = questionID;
        getMemzData[id].prediction = uint56(prediction);
        getMemzData[id].emissionMultiple = uint32(multiple);

        unchecked {
            ++getUserData[to].memzOwned;
            getUserData[to].emissionMultiple += uint32(multiple);
        }

        emit Transfer(address(0), to, id);
    }

    function _batchMint(address to, uint256 id, bytes32 questionID) internal returns (uint256) {
        // Does not check if the token was already minted or the recipient is address(0)
        // because Memz.sol manages its ids in such a way that it ensures it won't
        // double mint and will only mint to owner who cannot be zero.

        // only called for initial allocation to vault

        // set emission multiple
        uint256 multiple = 12; // beyond 22459

        // The branchless expression below is equivalent to:
        // if (id <= 5082) newCurrentIdMultiple = 6;
        // else if (id <= 9438) newCurrentIdMultiple = 7;
        // else if (id <= 13250) newCurrentIdMultiple = 8;
        // else if (id <= 16638) newCurrentIdMultiple = 9;
        // else if (id <= 19687) newCurrentIdMultiple = 10;
        // else if (id <= 22459) newCurrentIdMultiple = 11;

        assembly {
            // prettier-ignore
            multiple := sub(sub(sub(sub(sub(sub(
                multiple, 
                lt(id, 22460)),
                lt(id, 19688)),
                lt(id, 16639)),
                lt(id, 13251)),
                lt(id, 9439)),
                lt(id, 5083)
            )
        }

        unchecked {
            getUserData[to].memzOwned += uint32(VAULT_NUM);
            getUserData[to].emissionMultiple += uint32(multiple * VAULT_NUM);

            for (uint256 i = 0; i < VAULT_NUM; ++i) {
                getMemzData[++id].owner = to;
                getMemzData[id].questionID = questionID;
                getMemzData[id].prediction = uint56((VAULT_PREDICTIONS >> (i * 8)) & 0xff);
                getMemzData[id].emissionMultiple = uint32(multiple);

                emit Transfer(address(0), to, id);
            }
            // return prev id
            return id;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC20} from "solmate/tokens/ERC20.sol";

/// @notice ERC20 continiously emitted by Memz. Used to purchase $PAGES and vote on Memz.
/// @dev Only callable by Memz & Pages contract.
contract Goo is ERC20("Goo", "GOO", 18) {
    error Unauthorized();

    address public immutable memz;
    address public immutable pages;

    constructor(address _memz, address _pages) {
        memz = _memz;
        pages = _pages;
    }

    /// @notice Requires caller address to match user address.
    modifier only(address user) {
        if (msg.sender != user) revert Unauthorized();

        _;
    }

    /// @notice Mint any amount of goo to a user. Can only be called by Memz.
    /// @param to The address of the user to mint goo to.
    /// @param amount The amount of goo to mint.
    function mintGoo(address to, uint256 amount) external only(memz) {
        _mint(to, amount);
    }

    /// @notice Burn any amount of goo from a user. Can only be called by Memz.
    /// @param from The address of the user to burn goo from.
    /// @param amount The amount of goo to burn.
    function burnGoo(address from, uint256 amount) external only(memz) {
        _burn(from, amount);
    }

    /// @notice Burn any amount of goo from a user. Can only be called by Pages.
    /// @param from The address of the user to burn goo from.
    /// @param amount The amount of goo to burn.
    function burnForPages(address from, uint256 amount) external only(pages) {
        _burn(from, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibString} from "solmate/utils/LibString.sol";
import {toDaysWadUnsafe} from "solmate/utils/SignedWadMath.sol";
import {SSTORE2} from "solmate/utils/SSTORE2.sol";

import {LinearVRGDA} from "VRGDAs/LinearVRGDA.sol";

import {PagesERC721} from "./utils/token/PagesERC721.sol";

import {Goo} from "./Goo.sol";
import {Memz} from "./Memz.sol";
import {NFTMeta} from "./libraries/NFTMeta.sol";

/// @title Pages NFT
/// @author smarsx @_smarsx
/// @author modified from Art-Gobblers Pages (https://github.com/artgobblers/art-gobblers/blob/master/src/Pages.sol)
/// @notice Pages is an ERC721 that can hold custom art in a SSTORE2 pointer.
contract Pages is PagesERC721, LinearVRGDA {
    using LibString for uint256;

    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /// @notice The address of the goo ERC20 token contract.
    Goo public immutable goo;

    /// @notice The address which receives pages reserved for the community.
    address public immutable vault;

    /*//////////////////////////////////////////////////////////////
                            VRGDA INPUT STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Timestamp for the start of the VRGDA mint.
    uint256 public immutable mintStart;

    /// @notice Id of the most recently minted page.
    /// @dev Will be 0 if no pages have been minted yet.
    uint128 public currentId;

    /*//////////////////////////////////////////////////////////////
                          COMMUNITY PAGES STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice The number of pages minted to the vault.
    uint128 public numMintedForVault;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event PagePurchased(address indexed user, uint256 indexed pageId, uint256 price);

    event VaultPageMinted(address indexed user, uint256 lastMintedPageId, uint256 numPages);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error ReserveImbalance();

    error PriceExceededMax(uint256 currentPrice);

    error Unauthorized();

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets VRGDA parameters, mint start, relevant addresses, and base URI.
    /// @param _mintStart Timestamp for the start of the VRGDA mint.
    /// @param _goo Address of the Goo contract.
    /// @param _vault Address of the vault.
    /// @param _memz Address of the Memz contract.
    constructor(
        // Mint config:
        uint256 _mintStart,
        // Addresses:
        Goo _goo,
        address _vault,
        Memz _memz
    )
        PagesERC721(_memz, "Pages", "PAGE")
        LinearVRGDA(
            0.0042069e18, // Target price.
            0.31e18, // Price decay percent.
            5e18 // Pages to target per day.
        )
    {
        mintStart = _mintStart;

        goo = _goo;

        vault = _vault;
    }

    /// @notice Requires caller address to match user address.
    modifier only(address user) {
        if (msg.sender != user) revert Unauthorized();

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               METADATA
    //////////////////////////////////////////////////////////////*/

    /// @notice Page metadata.
    struct Metadata {
        // use 96 bits to fill the 1st slot
        uint96 royalty;
        address pointer;
        uint256 votes;
    }

    /// @notice Map pageIds to metadata
    mapping(uint256 => Metadata) public metadatas;

    /// @notice Set royalty and SSTORE2 pointer for page.
    /// @dev Reverts if pointer is already set.
    /// @dev Doesn't overwrite votes. technically you can pre-vote for a given pageId.
    function setMetadata(uint256 _pageID, uint256 _royalty, address _pointer) external only(address(memz)) {
        if (metadatas[_pageID].pointer != address(0)) revert();
        metadatas[_pageID].royalty = uint96(_royalty);
        metadatas[_pageID].pointer = _pointer;
    }

    /// @notice Add votes to a page.
    /// @dev Only callable by Memz.
    /// @dev Goo is burned in Memz.
    /// @param _pageID Page to vote for.
    /// @param _votes Amt of goo to vote.
    function addVotes(uint256 _pageID, uint256 _votes) external only(address(memz)) {
        metadatas[_pageID].votes += _votes;
    }

    /*//////////////////////////////////////////////////////////////
                              MINTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Mint a page with goo, burning the cost.
    /// @param maxPrice Maximum price to pay to mint the page.
    /// @param useVirtualBalance Whether the cost is paid from the
    /// user's virtual goo balance, or from their ERC20 goo balance.
    /// @return pageId The id of the page that was minted.
    function mintFromGoo(uint256 maxPrice, bool useVirtualBalance) external returns (uint256 pageId) {
        // Will revert if prior to mint start.
        uint256 currentPrice = pagePrice();

        // If the current price is above the user's specified max, revert.
        if (currentPrice > maxPrice) revert PriceExceededMax(currentPrice);

        // Decrement the user's goo balance by the current
        // price, either from virtual balance or ERC20 balance.
        useVirtualBalance ? memz.burnGooForPages(msg.sender, currentPrice) : goo.burnForPages(msg.sender, currentPrice);

        unchecked {
            emit PagePurchased(msg.sender, pageId = ++currentId, currentPrice);

            _mint(msg.sender, pageId);
        }
    }

    /// @notice Calculate the mint cost of a page.
    /// @dev Reverts due to underflow if minting hasn't started yet. Done to save gas.
    function pagePrice() public view returns (uint256) {
        // We need checked math here to cause overflow
        // before minting has begun, preventing mints.
        uint256 timeSinceStart = block.timestamp - mintStart;

        unchecked {
            // The number of pages minted for the community reserve
            // should never exceed 10% of the total supply of pages.
            return getVRGDAPrice(toDaysWadUnsafe(timeSinceStart), currentId - numMintedForVault);
        }
    }

    /*//////////////////////////////////////////////////////////////
                      COMMUNITY PAGES MINTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Mint a number of pages to the community reserve.
    /// @param numPages The number of pages to mint to the reserve.
    /// @dev Pages minted to the reserve cannot comprise more than 10% of the sum of the
    /// supply of goo minted pages and the supply of pages minted to the community reserve.
    function mintVaultPages(uint256 numPages) external returns (uint256 lastMintedPageId) {
        unchecked {
            // Optimistically increment numMintedForCommunity, may be reverted below.
            // Overflow in this calculation is possible but numPages would have to be so
            // large that it would cause the loop in _batchMint to run out of gas quickly.
            uint256 newNumMintedForCommunity = numMintedForVault += uint128(numPages);

            // Ensure that after this mint pages minted to the community reserve won't comprise more than
            // 10% of the new total page supply. currentId is equivalent to the current total supply of pages.
            if (newNumMintedForCommunity > ((lastMintedPageId = currentId) + numPages) / 10) revert ReserveImbalance();

            // Mint the pages to the community reserve and update lastMintedPageId once minting is complete.
            lastMintedPageId = _batchMint(vault, numPages, lastMintedPageId);

            currentId = uint128(lastMintedPageId); // Update currentId with the last minted page id.

            emit VaultPageMinted(msg.sender, lastMintedPageId, numPages);
        }
    }

    /*//////////////////////////////////////////////////////////////
                             TOKEN URI LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns a page's URI if it has been minted.
    /// @param pageID The id of the page to get the URI for.
    function tokenURI(uint256 pageID) public view virtual override returns (string memory) {
        if (pageID == 0 || pageID > currentId) revert("NOT_MINTED");
        if (metadatas[pageID].pointer == address(0)) revert("NOT_SET");

        return NFTMeta.render(string(SSTORE2.read(metadatas[pageID].pointer)));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {wadExp, wadLn, wadMul, unsafeWadMul, toWadUnsafe} from "solmate/utils/SignedWadMath.sol";

/// @title Variable Rate Gradual Dutch Auction
/// @author transmissions11 <[email protected]>
/// @author FrankieIsLost <[email protected]>
/// @notice Sell tokens roughly according to an issuance schedule.
abstract contract VRGDA {
    /*//////////////////////////////////////////////////////////////
                            VRGDA PARAMETERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Target price for a token, to be scaled according to sales pace.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 public immutable targetPrice;

    /// @dev Precomputed constant that allows us to rewrite a pow() as an exp().
    /// @dev Represented as an 18 decimal fixed point number.
    int256 internal immutable decayConstant;

    /// @notice Sets target price and per time unit price decay for the VRGDA.
    /// @param _targetPrice The target price for a token if sold on pace, scaled by 1e18.
    /// @param _priceDecayPercent The percent price decays per unit of time with no sales, scaled by 1e18.
    constructor(int256 _targetPrice, int256 _priceDecayPercent) {
        targetPrice = _targetPrice;

        decayConstant = wadLn(1e18 - _priceDecayPercent);

        // The decay constant must be negative for VRGDAs to work.
        require(decayConstant < 0, "NON_NEGATIVE_DECAY_CONSTANT");
    }

    /*//////////////////////////////////////////////////////////////
                              PRICING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Calculate the price of a token according to the VRGDA formula.
    /// @param timeSinceStart Time passed since the VRGDA began, scaled by 1e18.
    /// @param sold The total number of tokens that have been sold so far.
    /// @return The price of a token according to VRGDA, scaled by 1e18.
    function getVRGDAPrice(int256 timeSinceStart, uint256 sold) public view virtual returns (uint256) {
        unchecked {
            // prettier-ignore
            return uint256(wadMul(targetPrice, wadExp(unsafeWadMul(decayConstant,
                // Theoretically calling toWadUnsafe with sold can silently overflow but under
                // any reasonable circumstance it will never be large enough. We use sold + 1 as
                // the VRGDA formula's n param represents the nth token and sold is the n-1th token.
                timeSinceStart - getTargetSaleTime(toWadUnsafe(sold + 1))
            ))));
        }
    }

    /// @dev Given a number of tokens sold, return the target time that number of tokens should be sold by.
    /// @param sold A number of tokens sold, scaled by 1e18, to get the corresponding target sale time for.
    /// @return The target time the tokens should be sold by, scaled by 1e18, where the time is
    /// relative, such that 0 means the tokens should be sold immediately when the VRGDA begins.
    function getTargetSaleTime(int256 sold) public view virtual returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library to encode strings in Base64.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/Base64.sol)
library Base64 {
    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// See: https://datatracker.ietf.org/doc/html/rfc4648
    /// @param fileSafe  Whether to replace '+' with '-' and '/' with '_'.
    /// @param noPadding Whether to strip away the padding.
    function encode(
        bytes memory data,
        bool fileSafe,
        bool noPadding
    ) internal pure returns (string memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            let dataLength := mload(data)

            if dataLength {
                // Multiply by 4/3 rounded up.
                // The `shl(2, ...)` is equivalent to multiplying by 4.
                let encodedLength := shl(2, div(add(dataLength, 2), 3))

                // Set `result` to point to the start of the free memory.
                result := mload(0x40)

                // Store the table into the scratch space.
                // Offsetted by -1 byte so that the `mload` will load the character.
                // We will rewrite the free memory pointer at `0x40` later with
                // the allocated size.
                // The magic constant 0x0230 will translate "-_" + "+/".
                mstore(0x1f, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef")
                mstore(0x3f, sub("ghijklmnopqrstuvwxyz0123456789-_", mul(iszero(fileSafe), 0x0230)))

                // Skip the first slot, which stores the length.
                let ptr := add(result, 0x20)
                let end := add(ptr, encodedLength)

                // Run over the input, 3 bytes at a time.
                for {

                } 1 {

                } {
                    data := add(data, 3) // Advance 3 bytes.
                    let input := mload(data)

                    // Write 4 bytes. Optimized for fewer stack operations.
                    mstore8(0, mload(and(shr(18, input), 0x3F)))
                    mstore8(1, mload(and(shr(12, input), 0x3F)))
                    mstore8(2, mload(and(shr(6, input), 0x3F)))
                    mstore8(3, mload(and(input, 0x3F)))
                    mstore(ptr, mload(0x00))

                    ptr := add(ptr, 4) // Advance 4 bytes.

                    if iszero(lt(ptr, end)) {
                        break
                    }
                }

                // Allocate the memory for the string.
                // Add 31 and mask with `not(31)` to round the
                // free memory pointer up the next multiple of 32.
                mstore(0x40, and(add(end, 31), not(31)))

                // Equivalent to `o = [0, 2, 1][dataLength % 3]`.
                let o := div(2, mod(dataLength, 3))

                // Offset `ptr` and pad with '='. We can simply write over the end.
                mstore(sub(ptr, o), shl(240, 0x3d3d))
                // Set `o` to zero if there is padding.
                o := mul(iszero(iszero(noPadding)), o)
                // Zeroize the slot after the string.
                mstore(sub(ptr, o), 0)
                // Write the length of the string.
                mstore(result, sub(encodedLength, o))
            }
        }
    }

    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// Equivalent to `encode(data, false, false)`.
    function encode(bytes memory data) internal pure returns (string memory result) {
        result = encode(data, false, false);
    }

    /// @dev Encodes base64 encoded `data`.
    ///
    /// Supports:
    /// - RFC 4648 (both standard and file-safe mode).
    /// - RFC 3501 (63: ',').
    ///
    /// Does not support:
    /// - Line breaks.
    ///
    /// Note: For performance reasons,
    /// this function will NOT revert on invalid `data` inputs.
    /// Outputs for invalid inputs will simply be undefined behaviour.
    /// It is the user's responsibility to ensure that the `data`
    /// is a valid base64 encoded string.
    function decode(string memory data) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            let dataLength := mload(data)

            if dataLength {
                let decodedLength := mul(shr(2, dataLength), 3)

                for {

                } 1 {

                } {
                    // If padded.
                    if iszero(and(dataLength, 3)) {
                        let t := xor(mload(add(data, dataLength)), 0x3d3d)
                        // forgefmt: disable-next-item
                        decodedLength := sub(
                            decodedLength,
                            add(iszero(byte(30, t)), iszero(byte(31, t)))
                        )
                        break
                    }

                    // If non-padded.
                    decodedLength := add(decodedLength, sub(and(dataLength, 3), 1))
                    break
                }
                result := mload(0x40)

                // Write the length of the bytes.
                mstore(result, decodedLength)

                // Skip the first slot, which stores the length.
                let ptr := add(result, 0x20)
                let end := add(ptr, decodedLength)

                // Load the table into the scratch space.
                // Constants are optimized for smaller bytecode with zero gas overhead.
                // `m` also doubles as the mask of the upper 6 bits.
                let m := 0xfc000000fc00686c7074787c8084888c9094989ca0a4a8acb0b4b8bcc0c4c8cc
                mstore(0x5b, m)
                mstore(0x3b, 0x04080c1014181c2024282c3034383c4044484c5054585c6064)
                mstore(0x1a, 0xf8fcf800fcd0d4d8dce0e4e8ecf0f4)

                for {

                } 1 {

                } {
                    // Read 4 bytes.
                    data := add(data, 4)
                    let input := mload(data)

                    // Write 3 bytes.
                    // forgefmt: disable-next-item
                    mstore(
                        ptr,
                        or(
                            and(m, mload(byte(28, input))),
                            shr(
                                6,
                                or(
                                    and(m, mload(byte(29, input))),
                                    shr(
                                        6,
                                        or(
                                            and(m, mload(byte(30, input))),
                                            shr(6, mload(byte(31, input)))
                                        )
                                    )
                                )
                            )
                        )
                    )

                    ptr := add(ptr, 3)

                    if iszero(lt(ptr, end)) {
                        break
                    }
                }

                // Allocate the memory for the string.
                // Add 31 and mask with `not(31)` to round the
                // free memory pointer up the next multiple of 32.
                mstore(0x40, and(add(end, 31), not(31)))
                // Zeroize the slot after the bytes.
                mstore(end, 0)
                // Restore the zero slot.
                mstore(0x60, 0)
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Efficient library for creating string representations of integers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/LibString.sol)
/// @author Modified from Solady (https://github.com/Vectorized/solady/blob/main/src/utils/LibString.sol)
library LibString {
    function toString(int256 value) internal pure returns (string memory str) {
        if (value >= 0) return toString(uint256(value));

        unchecked {
            str = toString(uint256(-value));

            /// @solidity memory-safe-assembly
            assembly {
                // Note: This is only safe because we over-allocate memory
                // and write the string from right to left in toString(uint256),
                // and thus can be sure that sub(str, 1) is an unused memory location.

                let length := mload(str) // Load the string length.
                // Put the - character at the start of the string contents.
                mstore(str, 45) // 45 is the ASCII code for the - character.
                str := sub(str, 1) // Move back the string pointer by a byte.
                mstore(str, add(length, 1)) // Update the string length.
            }
        }
    }

    function toString(uint256 value) internal pure returns (string memory str) {
        /// @solidity memory-safe-assembly
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but we allocate 160 bytes
            // to keep the free memory pointer word aligned. We'll need 1 word for the length, 1 word for the
            // trailing zeros padding, and 3 other words for a max of 78 digits. In total: 5 * 32 = 160 bytes.
            let newFreeMemoryPointer := add(mload(0x40), 160)

            // Update the free memory pointer to avoid overriding our string.
            mstore(0x40, newFreeMemoryPointer)

            // Assign str to the end of the zone of newly allocated memory.
            str := sub(newFreeMemoryPointer, 32)

            // Clean the last word of memory it may not be overwritten.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                // Move the pointer 1 byte to the left.
                str := sub(str, 1)

                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))

                // Keep dividing temp until zero.
                temp := div(temp, 10)

                 // prettier-ignore
                if iszero(temp) { break }
            }

            // Compute and cache the final total length of the string.
            let length := sub(end, str)

            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 32)

            // Store the string's length at the start of memory allocated for our string.
            mstore(str, length)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {unsafeWadDiv} from "solmate/utils/SignedWadMath.sol";

import {VRGDA} from "./VRGDA.sol";

/// @title Linear Variable Rate Gradual Dutch Auction
/// @author transmissions11 <[email protected]>
/// @author FrankieIsLost <[email protected]>
/// @notice VRGDA with a linear issuance curve.
abstract contract LinearVRGDA is VRGDA {
    /*//////////////////////////////////////////////////////////////
                           PRICING PARAMETERS
    //////////////////////////////////////////////////////////////*/

    /// @dev The total number of tokens to target selling every full unit of time.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 internal immutable perTimeUnit;

    /// @notice Sets pricing parameters for the VRGDA.
    /// @param _targetPrice The target price for a token if sold on pace, scaled by 1e18.
    /// @param _priceDecayPercent The percent price decays per unit of time with no sales, scaled by 1e18.
    /// @param _perTimeUnit The number of tokens to target selling in 1 full unit of time, scaled by 1e18.
    constructor(
        int256 _targetPrice,
        int256 _priceDecayPercent,
        int256 _perTimeUnit
    ) VRGDA(_targetPrice, _priceDecayPercent) {
        perTimeUnit = _perTimeUnit;
    }

    /*//////////////////////////////////////////////////////////////
                              PRICING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @dev Given a number of tokens sold, return the target time that number of tokens should be sold by.
    /// @param sold A number of tokens sold, scaled by 1e18, to get the corresponding target sale time for.
    /// @return The target time the tokens should be sold by, scaled by 1e18, where the time is
    /// relative, such that 0 means the tokens should be sold immediately when the VRGDA begins.
    function getTargetSaleTime(int256 sold) public view virtual override returns (int256) {
        return unsafeWadDiv(sold, perTimeUnit);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

import {ERC721TokenReceiver} from "solmate/tokens/ERC721.sol";
import {Memz} from "../../Memz.sol";

/// @notice ERC721 implementation optimized for Pages by pre-approving them to the Memz contract.
/// @author Modified from Solmate. (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract PagesERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) external view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    Memz public immutable memz;

    constructor(Memz _memz, string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        memz = _memz;
    }

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) external view returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) external view returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) internal _isApprovedForAll;

    function isApprovedForAll(address owner, address operator) public view returns (bool isApproved) {
        if (operator == address(memz)) return true; // Skip approvals for the Memz contract.

        return _isApprovedForAll[owner][operator];
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) external {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) external {
        _isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 id) public {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll(from, msg.sender) || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(address from, address to, uint256 id) external {
        transferFrom(from, to, id);

        if (to.code.length != 0)
            require(
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                    ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
    }

    function safeTransferFrom(address from, address to, uint256 id, bytes calldata data) external {
        transferFrom(from, to, id);

        if (to.code.length != 0)
            require(
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                    ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal {
        // Does not check the token has not been already minted
        // or is being minted to address(0) because ids in Pages.sol
        // are set using a monotonically increasing counter and only
        // minted to safe addresses or msg.sender who cannot be zero.

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _batchMint(address to, uint256 amount, uint256 lastMintedId) internal returns (uint256) {
        // Doesn't check if the tokens were already minted or the recipient is address(0)
        // because Pages.sol manages its ids in a way that it ensures it won't double
        // mint and will only mint to safe addresses or msg.sender who cannot be zero.

        unchecked {
            _balanceOf[to] += amount;

            for (uint256 i = 0; i < amount; ++i) {
                _ownerOf[++lastMintedId] = to;

                emit Transfer(address(0), to, lastMintedId);
            }
        }

        return lastMintedId;
    }
}