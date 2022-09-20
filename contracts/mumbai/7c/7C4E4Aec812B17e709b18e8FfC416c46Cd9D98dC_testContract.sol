// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "./soulbound.sol";

// Deployed to Polygon Mumbai

//errors

error FeesNotPaid();
error AlreadyVoted();
error NotIn_FundRaising_State();

error ZeroDonation();
error MaxAmountReached();
error callSuccessFailed();

// contract funder is Ownable, KeeperCompatibleInterface, soulbound {
contract testContract is KeeperCompatibleInterface, soulbound {
    //State variables
    uint votesRequired;
    uint votingTime;
    uint RaisingFundsTime;
    uint MinimumFundGoal;
    address Owner;

    //Mappings
    mapping(address => User) UserOf;

    mapping(bytes32 => mapping(address => bool)) hasDonated; // user donated for a specific program

    mapping(bytes32 => Program) idToProgram;
    mapping(bytes32 => mapping(address => uint256)) program_Adress_ToDonation; // user donation for a specific program
    mapping(bytes32 => mapping(address => UserVote)) program_Adress_ToVotes; // user voted for a specific program
    mapping(bytes32 => mapping(address => uint)) UserVoted; //user voted for a specific program true/false
    mapping(bytes32 => NFT) idToNFT;

    //Arrays
    bytes32[] idArray; // program id array
    Program[] Allprograms; // all programs array
    User[] userArray; // array of users

    //Enums
    enum State {
        VERIFYING_STATE,
        FAILED_STATE,
        RASING_FUNDS,
        COMPLETE_STATE
    }

    enum UserVote {
        REJECT,
        ACCEPT
    }

    //Structs
    struct User {
        address _user;
        uint256 TotalFundsDonated;
        UserVote _vote;
        bool HasVoted;
        uint256 programNo;
    }

    struct Program {
        address programOwner;
        bytes32 programId;
        string programDataCID;
        uint256 fees;
        uint256 fundGoal;
        uint256 currentFunds;
        address[] FundersList;
        address[] VotersList;
        uint256 votesRequired;
        uint256 votingTime;
        uint256 RaisingFundsTime;
        uint256 CurrentVotes;
        uint256 Rejects;
        bool fundsWithdrawn;
        bool feesRefunded;
        State _state;
    }

    struct NFT {
        string cid1; //NFT 1 who ever donates will get this
        string cid2; // NFT 2
        string cid3; // NFT 3 who ever donates at a certain amount
        uint256 value1; //  who ever donates at a value1 will get NFT2
        uint256 value2; //  who ever donates at a value2 will get NFT3
    }

    //Events

    // event for creation of user struct
    event userCreated(
        address _user,
        uint256 TotalFundsDonated,
        UserVote _vote,
        bool HasVoted,
        uint256 programNo
    );

    // event for creation of program struct
    event programCreated(
        address programOwner,
        bytes32 programId,
        string programDataCID,
        uint256 fundGoal,
        uint256 currentFunds,
        uint256 votesRequired,
        uint256 votingTime,
        uint256 RaisingFundsTime,
        uint256 CurrentVotes,
        uint256 Rejects,
        State _state
    );

    //  amount donated by user
    event donate(address userAddress, uint256 amount);

    // With draw funds raised by the organizer
    event WithdrawFundsRaisedEvent(
        address organizer,
        uint256 amount,
        bool fundsWithdrawn
    );

    // With draw fees from smart contract only owner
    event WithdrawFeesEvent(
        address _owner,
        uint256 amount,
        bool fundsWithdrawn
    );
    // With draw our fees from organizer
    event sendFeesToSmartContract(
        address SC_address,
        uint256 amount,
        bool fees_Send
    );

    // // Refund fees to the organizer
    // event RefundFeesEvent(
    //     address organizer,
    //     uint256 amount,
    //     bool fees_refunded
    // );

    // // Refund fees to the users
    // event RefundFundsEvent(
    //     address user,
    //     uint256 amount_Refunded,
    //     bool refunded
    // );

    // chainlink function
    event checkUpkeepEvent(
        bool upKeerNeeded,
        bytes performData,
        bytes32 programId
    );

    // chainlink function
    event performEvent(State _state, bytes32 programId); // track of State change of which program

    // info about struct program variables
    event Fund_Details(
        uint program_Fees,
        uint Program_CurrentFunds,
        State Program_State,
        uint Program_FundsRemaining
    );

    // info about struct program variables
    event Voting_Detail(
        uint votesRequired,
        uint TotalVotes,
        uint CurrentVotes,
        uint Rejects,
        uint votedForthisevent
    );

    // stored each program nft information in a struct
    event nft(
        string cid1,
        string cid2,
        string cid3,
        uint256 value1,
        uint256 value2
    );

    modifier _onlyOwner() {
        require(msg.sender == Owner);
        _;
    }

    constructor() public {
        MinimumFundGoal = 0.5 ether;
    }

    function CreateNewProgram(uint256 fundGoal, string calldata programDataCID)
        external
        payable
    {
        bytes32 programId = keccak256(
            abi.encodePacked(msg.sender, address(this), fundGoal)
        );

        State _state;

        uint fees = (fundGoal * 5) / 1000;

        if (msg.value < fees) {
            revert FeesNotPaid();
        }

        votesRequired = 3;
        votingTime = 3 minutes;
        RaisingFundsTime = 3 minutes;

        address[] memory FundersList;
        address[] memory VotersList;

        idToProgram[programId] = Program(
            msg.sender,
            programId,
            programDataCID,
            fees,
            fundGoal,
            0 ether,
            FundersList,
            VotersList,
            votesRequired,
            votingTime,
            RaisingFundsTime,
            0,
            0,
            false,
            false,
            _state = State.VERIFYING_STATE
        );

        Program memory _program = idToProgram[programId];

        Allprograms.push(_program);
        idArray.push(programId);

        emit programCreated(
            msg.sender,
            _program.programId,
            _program.programDataCID,
            _program.fundGoal,
            0,
            _program.votesRequired,
            _program.votingTime,
            _program.RaisingFundsTime,
            0,
            0,
            _program._state
        );
    }

    //When accept button is clicked in voting section

    function Accept(bytes32 programId) external {
        Program storage myProgram = idToProgram[programId];

        if (UserVoted[programId][msg.sender] == 1) {
            revert AlreadyVoted();
        }

        UserVote _vote = UserVote.ACCEPT;

        UserOf[msg.sender] = User(msg.sender, 0, _vote, true, 0);
        User storage _user = UserOf[msg.sender];

        myProgram.VotersList.push(msg.sender);
        myProgram.CurrentVotes += 1;
        program_Adress_ToVotes[programId][msg.sender] = _vote;
        userArray.push(User(msg.sender, 0, _vote, true, 0));
        _user.programNo += 1;
        UserVoted[programId][msg.sender] = 1;

        emit userCreated(msg.sender, 0, _vote, true, _user.programNo);
    }

    //When Reject button is clicked in voting section
    function Reject(bytes32 programId) external {
        Program storage myProgram = idToProgram[programId];

        if (UserVoted[programId][msg.sender] == 1) {
            revert AlreadyVoted();
        }

        UserVote _vote = UserVote.REJECT;

        UserOf[msg.sender] = User(msg.sender, 0, _vote, true, 0);
        User storage _user = UserOf[msg.sender];
        myProgram.VotersList.push(msg.sender);
        myProgram.Rejects += 1;
        program_Adress_ToVotes[programId][msg.sender] = _vote;
        userArray.push(User(msg.sender, 0, _vote, true, 0));
        UserVoted[programId][msg.sender] = 1; // user has voted for this particular program
        _user.programNo += 1;

        emit userCreated(msg.sender, 0, _vote, true, _user.programNo);
    }

    //Donate button pressed
    function Donate(bytes32 programId) external payable {
        Program storage myProgram = idToProgram[programId];

        require(myProgram._state == State.RASING_FUNDS, "w_state");

        if (msg.value < 0) {
            revert ZeroDonation();
        }

        if (myProgram.fundGoal < myProgram.currentFunds + msg.value) {
            revert MaxAmountReached();
        }

        if (hasDonated[programId][msg.sender] == false) {
            myProgram.FundersList.push(msg.sender);
        }

        myProgram.currentFunds += msg.value;
        hasDonated[programId][msg.sender] = true;

        User storage user = UserOf[msg.sender];
        user.TotalFundsDonated += msg.value;

        program_Adress_ToDonation[programId][msg.sender] += msg.value;

        emit donate(msg.sender, msg.value);
    }

    // Oraganizer withdrawing funds when the program is in COMPLETED STATE
    function WithdrawFundsRaised(bytes32 programId) external {
        Program storage myProgram = idToProgram[programId];
        require(msg.sender == myProgram.programOwner);
        require(myProgram._state == State.COMPLETE_STATE);
        require(myProgram.fundsWithdrawn == false);
        require(myProgram.currentFunds == myProgram.fundGoal);

        (bool callSuccess, ) = payable(msg.sender).call{
            value: myProgram.fundGoal
        }("");

        // require(callSuccess, "Program funds Withdrawn failed");

        if (callSuccess == false) {
            revert callSuccessFailed();
        }

        myProgram.fundsWithdrawn == true;
        emit WithdrawFundsRaisedEvent(
            myProgram.programOwner,
            myProgram.fundGoal,
            myProgram.fundsWithdrawn
        );
    }

    // Refund  organizer Fees , funds if failed
    function RefundFeesFunction(bytes32 programId) internal {
        Program storage myProgram = idToProgram[programId];
        require(myProgram._state == State.FAILED_STATE);
        require(myProgram.feesRefunded == false);

        (bool callSuccess, ) = payable(myProgram.programOwner).call{
            value: myProgram.fees
        }("");

        // require(callSuccess, "Program fees Refund failed");
        if (callSuccess == false) {
            revert callSuccessFailed();
        }

        myProgram.feesRefunded = true;

        // emit RefundFeesEvent(msg.sender, myProgram.fees, true);
    }

    function RefundFundsFunction(bytes32 programId) internal {
        Program storage myProgram = idToProgram[programId];
        require(myProgram._state == State.FAILED_STATE);

        if (myProgram.RaisingFundsTime == 0) {
            (bool callSuccess, ) = payable(myProgram.programOwner).call{
                value: myProgram.fees
            }("");
            // require(callSuccess, "Program fees Refund failed");

            if (callSuccess == false) {
                revert callSuccessFailed();
            }

            for (uint256 i = 0; i < myProgram.FundersList.length; i++) {
                (bool callSuccess2, ) = payable(myProgram.FundersList[i]).call{
                    value: program_Adress_ToDonation[programId][
                        myProgram.FundersList[i]
                    ]
                }("");

                // require(callSuccess2, "User Refundfailed");

                if (callSuccess2 == false) {
                    revert callSuccessFailed();
                }

                // emit RefundFundsEvent(
                //     myProgram.FundersList[i],
                //     program_Adress_ToDonation[programId][
                //         myProgram.FundersList[i]
                //     ],
                //     true
                // );
            }
        }
    }

    function WithdrawFees() external payable _onlyOwner {
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");

        // require(callSuccess, "Fees withdrawn to Owners account");
        if (callSuccess == false) {
            revert callSuccessFailed();
        }

        emit WithdrawFeesEvent(msg.sender, address(this).balance, callSuccess);
    }

    function checkUpkeep(
        bytes calldata /*checkData */
    ) external override returns (bool upkeepNeeded, bytes memory performData) {
        uint256 TotalVotes;

        for (uint i = 0; i < idArray.length; i++) {
            Program memory myProgram = idToProgram[idArray[i]];
            TotalVotes = myProgram.CurrentVotes + myProgram.Rejects;
            upkeepNeeded =
                ((myProgram.votingTime == 0) &&
                    (myProgram.Rejects > myProgram.CurrentVotes &&
                        myProgram.votesRequired <= TotalVotes)) ||
                (myProgram.CurrentVotes > myProgram.Rejects &&
                    myProgram.votesRequired <= TotalVotes) ||
                (myProgram.RaisingFundsTime == 0) ||
                (myProgram.currentFunds >= myProgram.fundGoal) ||
                (myProgram._state == State.COMPLETE_STATE);

            for (uint256 j = 0; j < myProgram.FundersList.length; j++) {
                upkeepNeeded = (hasDonated[idArray[i]][
                    myProgram.FundersList[j]
                ] = true);
            }

            performData = abi.encode(idArray[i]);
            emit checkUpkeepEvent(upkeepNeeded, performData, idArray[i]);
            return (upkeepNeeded, performData);
        }

        return (false, "");
    }

    event cond(bool performedRan);

    // values will be given on the Front end
    function storeNFTURI(
        string memory cid1,
        string memory cid2,
        string memory cid3,
        uint256 value1,
        uint256 value2,
        bytes32 programId
    ) public {
        idToNFT[programId] = NFT(cid1, cid2, cid3, value1, value2);

        emit nft(cid1, cid2, cid3, value1, value2);
    }

    function performUpkeep(bytes calldata performData) external override {
        bytes32 programId = abi.decode(performData, (bytes32));

        Program storage myProgram = idToProgram[programId];
        NFT storage _nft = idToNFT[programId];

        uint256 TotalVotes = myProgram.CurrentVotes + myProgram.Rejects;

        if (
            (myProgram.votingTime == 0 &&
                myProgram._state == State.VERIFYING_STATE) ||
            (myProgram.Rejects > myProgram.CurrentVotes &&
                myProgram.votesRequired <= TotalVotes)
        ) {
            myProgram._state = State.FAILED_STATE;
            RefundFeesFunction(programId);
            emit performEvent(myProgram._state, programId);
            emit cond(true);
        } else if (
            myProgram.CurrentVotes > myProgram.Rejects &&
            myProgram.votesRequired <= TotalVotes &&
            myProgram._state == State.VERIFYING_STATE
        ) {
            myProgram._state = State.RASING_FUNDS;

            emit performEvent(myProgram._state, programId);
            emit cond(true);
        } else if (
            myProgram.RaisingFundsTime == 0 &&
            myProgram._state == State.RASING_FUNDS
        ) {
            myProgram._state = State.FAILED_STATE;
            RefundFeesFunction(programId);
            RefundFundsFunction(programId);
            emit performEvent(myProgram._state, programId);
            emit cond(true);
        } else if (
            myProgram.currentFunds >= myProgram.fundGoal &&
            myProgram._state == State.RASING_FUNDS &&
            myProgram.RaisingFundsTime != 0
        ) {
            myProgram._state = State.COMPLETE_STATE;
            emit performEvent(myProgram._state, programId);
            emit cond(true);
        } else if (myProgram._state == State.COMPLETE_STATE) {
            for (uint256 j = 0; j < myProgram.FundersList.length; j++) {
                uint donation = program_Adress_ToDonation[programId][
                    myProgram.FundersList[j]
                ];
                if (hasDonated[programId][myProgram.FundersList[j]] = true) {
                    safeMint(myProgram.FundersList[j], _nft.cid1);

                    if (donation >= _nft.value1) {
                        safeMint(myProgram.FundersList[j], _nft.cid2);
                    }

                    if (donation >= _nft.value2) {
                        safeMint(myProgram.FundersList[j], _nft.cid3);
                    }
                    emit cond(true);
                }
            }
        } else {
            emit cond(false);
        }
    }

    //Getters functions

    function getIdArray() public view returns (bytes32[] memory) {
        return idArray;
    }

    function getId(uint index) public view returns (bytes32) {
        return idArray[index];
    }

    function getProgram_Voting_Detail(bytes32 programId)
        public
        returns (
            uint,
            uint,
            uint,
            uint,
            uint
        )
    {
        Program memory myProgram = idToProgram[programId];

        uint TotalVotes = myProgram.CurrentVotes + myProgram.Rejects;
        emit Voting_Detail(
            myProgram.votesRequired,
            TotalVotes,
            myProgram.CurrentVotes,
            myProgram.Rejects,
            UserVoted[programId][msg.sender]
        );
        return (
            myProgram.votesRequired,
            TotalVotes,
            myProgram.CurrentVotes,
            myProgram.Rejects,
            UserVoted[programId][msg.sender]
        );
    }

    // function getAllUserVotes(bytes32 programId)
    //     external
    //     view
    //     returns (UserVote)
    // {
    //     return program_Adress_ToVotes[programId][msg.sender];
    // }

    function getAllPrograms()
        public
        view
        _onlyOwner
        returns (Program[] memory)
    {
        return Allprograms;
    }

    // function getPrograms(uint index)
    //     public
    //     view
    //     _onlyOwner
    //     returns (Program memory)
    // {
    //     return Allprograms[index];
    // }

    function getProgram_Fund_Details(bytes32 programId)
        public
        returns (
            uint,
            uint,
            State,
            uint
        )
    {
        Program memory myProgram = idToProgram[programId];
        uint remaining = myProgram.fundGoal - myProgram.currentFunds;
        emit Fund_Details(
            myProgram.fees,
            myProgram.fundGoal,
            myProgram._state,
            remaining
        );
        return (
            myProgram.fees,
            myProgram.currentFunds,
            myProgram._state,
            remaining
        );
    }

    function getFundGoal(bytes32 programId) public view returns (uint256) {
        Program memory myProgram = idToProgram[programId];
        return myProgram.fundGoal;
    }

    function getVotersList(bytes32 programId)
        public
        view
        returns (address[] memory)
    {
        Program memory myProgram = idToProgram[programId];
        return myProgram.VotersList;
    }

    function getfundersList(bytes32 programId)
        public
        view
        returns (address[] memory)
    {
        Program memory myProgram = idToProgram[programId];
        return myProgram.FundersList;
    }

    // function getAllUserDonations(bytes32 programId)
    //     external
    //     view
    //     returns (uint256)
    // {
    //     return program_Adress_ToDonation[programId][msg.sender];
    // }

    function ChangeMinFundGoal(uint _amount) public _onlyOwner {
        MinimumFundGoal = _amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract soulbound is ERC721, ERC721URIStorage {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    event minted(address _user, uint256 tokenID, string uri);
    event MintSuccessful(bool success);

    constructor() ERC721("SoulBoundTest", "SBT") {}

    function safeMint(address to, string memory uri) public {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        emit minted(to, tokenId, uri);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(from == address(0), "Err: token transfer is BLOCKED");
        super._beforeTokenTransfer(from, to, tokenId);
        emit MintSuccessful(true);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

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
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
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
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
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
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
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
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
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
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
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

        _afterTokenTransfer(address(0), to, tokenId);
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

        _afterTokenTransfer(owner, address(0), tokenId);
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
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

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

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