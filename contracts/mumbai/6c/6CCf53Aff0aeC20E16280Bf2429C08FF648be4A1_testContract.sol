// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

// Deployed to Polygon Mumbai 0x1c3449A42fBeCdf5ABd31C23BD2cBeF14676EB8F

contract testContract is Ownable, KeeperCompatibleInterface {
    //Mappings
    mapping(address => User) UserOf;
    mapping(address => bool) hasDonated;
    mapping(bytes32 => Program) idToProgram;
    mapping(bytes32 => mapping(address => uint256)) program_Adress_ToDonation; // user voted for a specific program
    mapping(bytes32 => mapping(address => UserVote)) program_Adress_ToVotes; // user voted for a specific program
    mapping(bytes32 => mapping(address => bool)) UserVoted; //user voted for a specific program true/false

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
        ACCEPT,
        REJECT
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
        uint256 fees; // matic
        uint256 fundGoal; // matic
        uint256 currentFunds; // matic
        address[] FundersList;
        address[] VotersList;
        uint256 votesRequired;
        uint256 votingTime;
        uint256 RaisingFundsTime;
        uint256 CurrentVotes;
        uint256 Rejects;
        bool fundsWithdrawn;
        // bool votingTimeRanOut;
        // bool fundRasisingTimeRanOut;
        State _state;
    }

    //Events
    event userCreated(
        address _user,
        uint256 TotalFundsDonated,
        UserVote _vote,
        bool HasVoted,
        uint256 programNo
    );
    // event programCreated(
    //     address programOwner,
    //     bytes32 programId,
    //     string programDataCID,
    //     uint256 fees,
    //     uint256 fundGoal,
    //     uint256 currentFunds,
    //     address[] FundersList,
    //     address[] VotersList,
    //     uint256 votesRequired,
    //     uint256 votingTime,
    //     uint256 RaisingFundsTime,
    //     uint256 CurrentVotes,
    //     uint256 Rejects,
    //     bool fundsWithdrawn,
    //     State _state
    // );

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
        uint256 Rejects
    );

    //  bool votingTimeRanOut,
    // bool fundRasisingTimeRanOut,

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

    event RefundFeesEvent(
        address organizer,
        uint256 amount,
        bool fees_refunded
    ); // Refund fees to Organizer
    event RefundFundsEvent(
        address user,
        uint256 amount_Refunded,
        bool refunded
    ); // Refund funds to all user
    event checkUpkeepEvent(
        bool upKeerNeeded,
        bytes performData,
        bytes32 programId
    ); // Checkup keep on which program
    event performEvent(State _state, bytes32 programId); // State change of which program

    function CreateNewProgram(
        uint256 fundGoal,
        // uint256 fees,
        string calldata programDataCID // uint256 votesRequired, // uint256 votingTime, // uint256 RaisingFundsTime, // uint256 currentFunds, // uint256 CurrentVotes, // uint256 Rejects
    ) external payable {
        bytes32 programId = keccak256(
            abi.encodePacked(msg.sender, address(this), fundGoal)
        );

        State _state;

        uint fees = 0.0000001 ether;
        // CurrentVotes = 0;
        // Rejects = 0;
        // currentFunds = 0;
        // uint256 month = 30 days;
        // uint256 year = 356 days;
        // require(fundGoal < 1000, "FundGoal can't be lower than 1000$");
        // require(
        //     msg.value >= fees,
        //     "Fees not paid  , program cannot be created"
        // );

        uint votesRequired = 2;
        uint votingTime = 1 days;
        uint RaisingFundsTime = 1 days;

        address[] memory FundersList;
        address[] memory VotersList;

        idToProgram[programId] = Program(
            msg.sender,
            programId,
            programDataCID,
            fees,
            fundGoal,
            0,
            FundersList,
            VotersList,
            votesRequired,
            votingTime,
            RaisingFundsTime,
            0,
            0,
            false,
            // false,
            // false,
            _state = State.VERIFYING_STATE
        );

        Program memory _program = idToProgram[programId];

        Allprograms.push(
            _program
            // Program(
            //     msg.sender,
            //     programId,
            //     programDataCID,
            //     0.0000001 ether,
            //     fundGoal,
            //     0,
            //     FundersList,
            //     VotersList,
            //     2,
            //     1 days,
            //     1 days,
            //     0,
            //     0,
            //     false,
            //     // false,
            //     // false,
            //     _state = State.VERIFYING_STATE
            // )
        );
        idArray.push(programId); // storing id in idArray

        // emit programCreated(
        //     msg.sender,
        //     _program.programId,
        //     _program.programDataCID,
        //     0.0000001 ether,
        //     _program.fundGoal,
        //     0,
        //     _program.FundersList,
        //     _program.VotersList,
        //     2,
        //     1 days,
        //     1 days,
        //     0,
        //     0,
        //     false,
        //     // false,
        //     // false,
        //     State.VERIFYING_STATE
        // );

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
            0
        );
    }

    // function emitCreateEvent() {
    //     emit programCreated(
    //         msg.sender,
    //         programId,
    //         programDataCID,
    //         0.0000001 ether,
    //         fundGoal,
    //         0,
    //         FundersList,
    //         VotersList,
    //         2,
    //         1 days,
    //         1 days,
    //         0,
    //         0,
    //         false,
    //         // false,
    //         // false,
    //         State.VERIFYING_STATE
    //     );
    // }

    //When accept button is clicked in voting section
    function Accept(bytes32 programId) external {
        Program storage myProgram = idToProgram[programId];
        require(
            UserVoted[programId][msg.sender] = false,
            "You have already Voted for this program"
        );
        uint256 TotalVotes = myProgram.CurrentVotes + myProgram.Rejects;

        require(
            myProgram.votesRequired <= TotalVotes,
            "Total Votes has been Reached"
        );

        UserVote _vote = UserVote.ACCEPT;

        // User storage _user = User(msg.sender, 0, _vote, true, 0);

        UserOf[msg.sender] = User(msg.sender, 0, _vote, true, 0);
        User storage _user = UserOf[msg.sender];

        myProgram.VotersList.push(msg.sender);
        myProgram.CurrentVotes += 1;
        program_Adress_ToVotes[programId][msg.sender] = _vote;
        userArray.push(User(msg.sender, 0, _vote, true, 0));
        _user.programNo += 1;
        UserVoted[programId][msg.sender] = true; // user has voted for this particular program
        emit userCreated(msg.sender, 0, _vote, true, _user.programNo);
    }

    //When Reject button is clicked in voting section
    function Reject(bytes32 programId) external {
        Program storage myProgram = idToProgram[programId];
        require(
            UserVoted[programId][msg.sender] = false,
            "You have already Voted for this program"
        );
        uint256 TotalVotes = myProgram.CurrentVotes + myProgram.Rejects;
        require(
            myProgram.votesRequired <= TotalVotes,
            "Total Votes has been Reached"
        );

        UserVote _vote = UserVote.REJECT;
        // User storage _user =
        UserOf[msg.sender] = User(msg.sender, 0, _vote, true, 0);
        User storage _user = UserOf[msg.sender];
        myProgram.VotersList.push(msg.sender);
        myProgram.Rejects += 1;
        program_Adress_ToVotes[programId][msg.sender] = _vote;
        userArray.push(User(msg.sender, 0, _vote, true, 0));
        UserVoted[programId][msg.sender] = true; // user has voted for this particular program
        _user.programNo += 1;
        emit userCreated(msg.sender, 0, _vote, true, _user.programNo);
    }

    //Donate button pressed
    function Donate(bytes32 programId) external payable {
        Program storage myProgram = idToProgram[programId];

        require(msg.value >= 0, "Can't donate zero fund");
        require(
            myProgram.fundGoal >= myProgram.currentFunds + msg.value,
            "Max amount Reached"
        );

        if (hasDonated[msg.sender] = false) {
            myProgram.FundersList.push(msg.sender);
        }

        myProgram.currentFunds += msg.value;
        hasDonated[msg.sender] = true;

        User storage user = UserOf[msg.sender];
        user.TotalFundsDonated += msg.value;
        // User donation for a specific event
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

        //Sending The owner of the contract fees
        (bool callSuccess1, ) = payable(address(this)).call{
            value: myProgram.fees
        }("");
        require(callSuccess1, "Program fees transfer failed");

        emit sendFeesToSmartContract(
            address(this),
            myProgram.fees,
            callSuccess1
        );

        //Sending The organizer the funds raised
        (bool callSuccess2, ) = payable(msg.sender).call{
            value: myProgram.fundGoal
        }("");

        require(callSuccess2, "Program funds Withdrawn failed");

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
        require(msg.sender == myProgram.programOwner);
        require(myProgram._state == State.FAILED_STATE);
        uint256 TotalVotes = myProgram.CurrentVotes + myProgram.Rejects;

        if (myProgram.votingTime == 0) {
            (bool callSuccess, ) = payable(msg.sender).call{
                value: myProgram.fees
            }("");

            require(callSuccess, "Program fees Refund failed");
        } else if (
            myProgram.Rejects >= myProgram.CurrentVotes &&
            myProgram.votesRequired == TotalVotes
        ) {
            (bool callSuccess, ) = payable(msg.sender).call{
                value: myProgram.fees
            }("");
            require(callSuccess, "Program fees Refund failed");
        }

        emit RefundFeesEvent(msg.sender, myProgram.fees, true);
    }

    function RefundFundsFunction(bytes32 programId) internal {
        Program storage myProgram = idToProgram[programId];

        if (myProgram.RaisingFundsTime == 0) {
            (bool callSuccess, ) = payable(myProgram.programOwner).call{
                value: myProgram.fees
            }("");
            require(callSuccess, "Program fees Refund failed");

            for (uint256 i = 0; i < myProgram.FundersList.length; i++) {
                // User memory user = UserOf[myProgram.FundersList[i]];
                (bool callSuccess2, ) = payable(myProgram.FundersList[i]).call{
                    value: program_Adress_ToDonation[programId][
                        myProgram.FundersList[i]
                    ]
                }("");

                require(callSuccess2, "User Refundfailed");

                emit RefundFundsEvent(
                    myProgram.FundersList[i],
                    program_Adress_ToDonation[programId][
                        myProgram.FundersList[i]
                    ],
                    true
                );
            }
        }
    }

    function WithdrawFees() external onlyOwner {
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");

        require(callSuccess, "Fees withdrawn to Owners account");
        emit WithdrawFeesEvent(msg.sender, address(this).balance, callSuccess);
    }

    function SoulBoundMint() external {}

    function ClaimNFT() external {}

    function PriceCalculator() public {}

    //Chain link Keepers Compatible automated functions
    //cond1 : Voting time runs out , rejects > current votes : move State from VERIFYING_STATE to Failed State ,  Refund Fees to organizer

    //cond2 : current votes > rejects and total votes are reached , time still remaining :  move State from VERIFYING_STATE to Raising_Fund_State

    //cond3 : Fund raising time runs out : Refund Fees + Refund Funds   , move State from RiasingFund_STATE to Failed_State

    //cond4 : currentFunds >= FundGoal  : move State from RiasingFund_STATE to Complete_State  , call WithdrawFundsRaised() , give Soul bounds to all people who donated at a certain amount

    function checkUpkeep(
        bytes calldata /*checkData */
    ) external override returns (bool upkeepNeeded, bytes memory performData) {
        uint256 TotalVotes;
        // idArray.length give dummy length
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
                (myProgram.currentFunds >= myProgram.fundGoal);

            performData = abi.encode(idArray[i]);
            emit checkUpkeepEvent(upkeepNeeded, performData, idArray[i]);
            return (upkeepNeeded, performData);
        }

        return (false, "");
    }

    function performUpkeep(bytes calldata performData) external override {
        bytes32 programId = abi.decode(performData, (bytes32));

        Program storage myProgram = idToProgram[programId];
        uint256 TotalVotes = myProgram.CurrentVotes + myProgram.Rejects;

        if (
            (myProgram.votingTime == 0 &&
                // myProgram.votingTimeRanOut == true &&
                myProgram._state == State.VERIFYING_STATE) ||
            (myProgram.Rejects > myProgram.CurrentVotes &&
                myProgram.votesRequired <= TotalVotes)
        ) {
            myProgram._state == State.FAILED_STATE;
            RefundFeesFunction(programId);
            emit performEvent(myProgram._state, programId);
        } else if (
            myProgram.CurrentVotes > myProgram.Rejects &&
            myProgram.votesRequired <= TotalVotes &&
            myProgram._state == State.VERIFYING_STATE
        ) {
            myProgram._state == State.RASING_FUNDS;
            emit performEvent(myProgram._state, programId);
        } else if (
            myProgram.RaisingFundsTime == 0 &&
            myProgram._state == State.RASING_FUNDS
        ) {
            myProgram._state == State.FAILED_STATE;
            RefundFeesFunction(programId);
            RefundFundsFunction(programId);
            emit performEvent(myProgram._state, programId);
        } else if (
            myProgram.currentFunds >= myProgram.fundGoal &&
            myProgram._state == State.RASING_FUNDS &&
            myProgram.RaisingFundsTime != 0
        ) {
            myProgram._state == State.COMPLETE_STATE;
            emit performEvent(myProgram._state, programId);
        }
    }

    //Getters functions

    function getIdArray() public view returns (bytes32[] memory) {
        return idArray;
    }

    function getAllPrograms() public view onlyOwner returns (Program[] memory) {
        return Allprograms;
    }

    function getUser() public view returns (User[] memory) {
        return userArray;
    }

    function getProgramFees(bytes32 programId) public view returns (uint256) {
        Program memory myProgram = idToProgram[programId];
        return myProgram.fees;
    }

    function getProgramState(bytes32 programId) public view returns (State) {
        Program memory myProgram = idToProgram[programId];
        return myProgram._state;
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

    function getAllUserVotes(bytes32 programId)
        external
        view
        returns (UserVote)
    {
        return program_Adress_ToVotes[programId][msg.sender];
    }

    function getAllUserDonations(bytes32 programId)
        external
        view
        returns (uint256)
    {
        return program_Adress_ToDonation[programId][msg.sender];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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