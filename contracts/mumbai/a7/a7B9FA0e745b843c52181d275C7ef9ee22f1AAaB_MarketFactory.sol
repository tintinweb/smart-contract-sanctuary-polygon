// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@reality.eth/contracts/development/contracts/RealityETH-3.0.sol";
import "./Market.sol";
import "./manager/Manager.sol";

contract MarketFactory {
    using Clones for address;

    struct RealitioQuestion {
        uint256 templateID;
        string question;
        uint32 openingTS;
    }

    uint32 public constant QUESTION_TIMEOUT = 1.5 days;

    Market[] public markets;
    address public immutable arbitrator;
    address public immutable realitio;
    address public immutable nftDescriptor;
    uint256 public immutable submissionTimeout;

    address public market;
    address public governor;
    address public protocolTraesury;
    address public manager;
    uint256 public protocolFee;

    event NewMarket(address indexed market, bytes32 indexed hash, address manager);

    /**
     *  @dev Constructor.
     *  @param _market Address of the market contract that is going to be used for each new deployment.
     *  @param _arbitrator Address of the arbitrator that is going to resolve Realitio disputes.
     *  @param _realitio Address of the Realitio implementation.
     *  @param _nftDescriptor Address of the nft contract that is going to be used for each new deployment.
     *  @param _manager Address of the manager contract that is going to be used for each new deployment.
     *  @param _governor Address of the governor of this contract.
     *  @param _protocolFee protocol fee in basis points.
     *  @param _protocolTraesury address in which protocol fees will be received.
     *  @param _submissionTimeout Time players have to submit their rankings after the questions were answer in Realitio.
     */
    constructor(
        address _market,
        address _arbitrator,
        address _realitio,
        address _nftDescriptor,
        address _manager,
        address _governor,
        address _protocolTraesury,
        uint256 _protocolFee,
        uint256 _submissionTimeout
    ) {
        market = _market;
        arbitrator = _arbitrator;
        realitio = _realitio;
        nftDescriptor = _nftDescriptor;
        manager = _manager;
        governor = _governor;
        protocolTraesury = _protocolTraesury;
        protocolFee = _protocolFee;
        submissionTimeout = _submissionTimeout;
    }

    function changeGovernor(address _governor) external {
        require(msg.sender == governor, "Not authorized");
        governor = _governor;
    }

    function changeProtocolTreasury(address _protocolTraesury) external {
        require(msg.sender == governor, "Not authorized");
        protocolTraesury = _protocolTraesury;
    }

    function changeProtocolFee(uint256 _protocolFee) external {
        require(msg.sender == governor, "Not authorized");
        protocolFee = _protocolFee;
    }

    function changeMarket(address _market) external {
        require(msg.sender == governor, "Not authorized");
        market = _market;
    }

    function changeManager(address _manager) external {
        require(msg.sender == governor, "Not authorized");
        manager = _manager;
    }

    function createMarket(
        string memory marketName,
        string memory marketSymbol,
        address creator,
        uint256 creatorFee,
        uint256 closingTime,
        uint256 price,
        uint256 minBond,
        RealitioQuestion[] memory questionsData,
        uint16[] memory prizeWeights
    ) external returns (address) {
        Market instance = Market(market.clone());

        bytes32[] memory questionIDs = new bytes32[](questionsData.length);
        {
            // Extra scope prevents Stack Too Deep error.
            bytes32 previousQuestionID = bytes32(0);
            for (uint256 i = 0; i < questionsData.length; i++) {
                require(
                    questionsData[i].openingTS > closingTime,
                    "Cannot open question in the betting period"
                );
                bytes32 questionID = askRealitio(questionsData[i], minBond);
                require(questionID >= previousQuestionID, "Questions are in incorrect order");
                previousQuestionID = questionID;
                questionIDs[i] = questionID;
            }
        }

        address payable newManager = payable(address(manager.clone()));
        Manager(newManager).initialize(
            payable(creator),
            creatorFee,
            payable(protocolTraesury),
            protocolFee,
            address(instance)
        );

        Market.MarketInfo memory marketInfo;
        marketInfo.marketName = marketName;
        marketInfo.marketSymbol = marketSymbol;
        marketInfo.fee = uint16(protocolFee + creatorFee);
        marketInfo.royaltyFee = uint16(protocolFee);
        marketInfo.manager = newManager;
        instance.initialize(
            marketInfo,
            nftDescriptor,
            realitio,
            closingTime,
            price,
            submissionTimeout,
            questionIDs,
            prizeWeights
        );

        emit NewMarket(address(instance), keccak256(abi.encodePacked(questionIDs)), newManager);
        markets.push(instance);

        return address(instance);
    }

    function askRealitio(RealitioQuestion memory questionData, uint256 minBond)
        internal
        returns (bytes32 questionID)
    {
        bytes32 content_hash = keccak256(
            abi.encodePacked(questionData.templateID, questionData.openingTS, questionData.question)
        );
        bytes32 question_id = keccak256(
            abi.encodePacked(
                content_hash,
                arbitrator,
                QUESTION_TIMEOUT,
                minBond,
                address(realitio),
                address(this),
                uint256(0)
            )
        );
        if (RealityETH_v3_0(realitio).getTimeout(question_id) != 0) {
            // Question already exists.
            questionID = question_id;
        } else {
            questionID = RealityETH_v3_0(realitio).askQuestionWithMinBond(
                questionData.templateID,
                questionData.question,
                arbitrator,
                QUESTION_TIMEOUT,
                questionData.openingTS,
                0,
                minBond
            );
        }
    }

    function allMarkets() external view returns (Market[] memory) {
        return markets;
    }

    function marketCount() external view returns (uint256) {
        return markets.length;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.6;

import './BalanceHolder.sol';

contract RealityETH_v3_0 is BalanceHolder {

    address constant NULL_ADDRESS = address(0);

    // History hash when no history is created, or history has been cleared
    bytes32 constant NULL_HASH = bytes32(0);

    // An unitinalized finalize_ts for a question will indicate an unanswered question.
    uint32 constant UNANSWERED = 0;

    // An unanswered reveal_ts for a commitment will indicate that it does not exist.
    uint256 constant COMMITMENT_NON_EXISTENT = 0;

    // Commit->reveal timeout is 1/8 of the question timeout (rounded down).
    uint32 constant COMMITMENT_TIMEOUT_RATIO = 8;

    // Proportion withheld when you claim an earlier bond.
    uint256 constant BOND_CLAIM_FEE_PROPORTION = 40; // One 40th ie 2.5%

    // Special value representing a question that was answered too soon.
    // bytes32(-2). By convention we use bytes32(-1) for "invalid", although the contract does not handle this.
    bytes32 constant UNRESOLVED_ANSWER = 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe;

    event LogSetQuestionFee(
        address arbitrator,
        uint256 amount
    );

    event LogNewTemplate(
        uint256 indexed template_id,
        address indexed user, 
        string question_text
    );

    event LogNewQuestion(
        bytes32 indexed question_id,
        address indexed user, 
        uint256 template_id,
        string question,
        bytes32 indexed content_hash,
        address arbitrator, 
        uint32 timeout,
        uint32 opening_ts,
        uint256 nonce,
        uint256 created
    );

    event LogMinimumBond(
        bytes32 indexed question_id,
        uint256 min_bond
    );

    event LogFundAnswerBounty(
        bytes32 indexed question_id,
        uint256 bounty_added,
        uint256 bounty,
        address indexed user 
    );

    event LogNewAnswer(
        bytes32 answer,
        bytes32 indexed question_id,
        bytes32 history_hash,
        address indexed user,
        uint256 bond,
        uint256 ts,
        bool is_commitment
    );

    event LogAnswerReveal(
        bytes32 indexed question_id, 
        address indexed user, 
        bytes32 indexed answer_hash, 
        bytes32 answer, 
        uint256 nonce, 
        uint256 bond
    );

    event LogNotifyOfArbitrationRequest(
        bytes32 indexed question_id,
        address indexed user 
    );

    event LogCancelArbitration(
        bytes32 indexed question_id
    );

    event LogFinalize(
        bytes32 indexed question_id,
        bytes32 indexed answer
    );

    event LogClaim(
        bytes32 indexed question_id,
        address indexed user,
        uint256 amount
    );

    event LogReopenQuestion(
        bytes32 indexed question_id,
        bytes32 indexed reopened_question_id
    );

    struct Question {
        bytes32 content_hash;
        address arbitrator;
        uint32 opening_ts;
        uint32 timeout;
        uint32 finalize_ts;
        bool is_pending_arbitration;
        uint256 bounty;
        bytes32 best_answer;
        bytes32 history_hash;
        uint256 bond;
        uint256 min_bond;
    }

    // Stored in a mapping indexed by commitment_id, a hash of commitment hash, question, bond. 
    struct Commitment {
        uint32 reveal_ts;
        bool is_revealed;
        bytes32 revealed_answer;
    }

    // Only used when claiming more bonds than fits into a transaction
    // Stored in a mapping indexed by question_id.
    struct Claim {
        address payee;
        uint256 last_bond;
        uint256 queued_funds;
    }

    uint256 nextTemplateID = 0;
    mapping(uint256 => uint256) public templates;
    mapping(uint256 => bytes32) public template_hashes;
    mapping(bytes32 => Question) public questions;
    mapping(bytes32 => Claim) public question_claims;
    mapping(bytes32 => Commitment) public commitments;
    mapping(address => uint256) public arbitrator_question_fees; 
    mapping(bytes32 => bytes32) public reopened_questions;
    mapping(bytes32 => bool) public reopener_questions;


    modifier onlyArbitrator(bytes32 question_id) {
        require(msg.sender == questions[question_id].arbitrator, "msg.sender must be arbitrator");
        _;
    }

    modifier stateAny() {
        _;
    }

    modifier stateNotCreated(bytes32 question_id) {
        require(questions[question_id].timeout == 0, "question must not exist");
        _;
    }

    modifier stateOpen(bytes32 question_id) {
        require(questions[question_id].timeout > 0, "question must exist");
        require(!questions[question_id].is_pending_arbitration, "question must not be pending arbitration");
        uint32 finalize_ts = questions[question_id].finalize_ts;
        require(finalize_ts == UNANSWERED || finalize_ts > uint32(block.timestamp), "finalization deadline must not have passed");
        uint32 opening_ts = questions[question_id].opening_ts;
        require(opening_ts == 0 || opening_ts <= uint32(block.timestamp), "opening date must have passed"); 
        _;
    }

    modifier statePendingArbitration(bytes32 question_id) {
        require(questions[question_id].is_pending_arbitration, "question must be pending arbitration");
        _;
    }

    modifier stateOpenOrPendingArbitration(bytes32 question_id) {
        require(questions[question_id].timeout > 0, "question must exist");
        uint32 finalize_ts = questions[question_id].finalize_ts;
        require(finalize_ts == UNANSWERED || finalize_ts > uint32(block.timestamp), "finalization dealine must not have passed");
        uint32 opening_ts = questions[question_id].opening_ts;
        require(opening_ts == 0 || opening_ts <= uint32(block.timestamp), "opening date must have passed"); 
        _;
    }

    modifier stateFinalized(bytes32 question_id) {
        require(isFinalized(question_id), "question must be finalized");
        _;
    }

    modifier bondMustDoubleAndMatchMinimum(bytes32 question_id) {
        require(msg.value > 0, "bond must be positive"); 
        uint256 current_bond = questions[question_id].bond;
        if (current_bond == 0) {
            require(msg.value >= (questions[question_id].min_bond), "bond must exceed the minimum");
        } else {
            require(msg.value >= (current_bond * 2), "bond must be double at least previous bond");
        }
        _;
    }

    modifier previousBondMustNotBeatMaxPrevious(bytes32 question_id, uint256 max_previous) {
        if (max_previous > 0) {
            require(questions[question_id].bond <= max_previous, "bond must exceed max_previous");
        }
        _;
    }

    /// @notice Constructor, sets up some initial templates
    /// @dev Creates some generalized templates for different question types used in the DApp.
    constructor() {
        createTemplate('{"title": "%s", "type": "bool", "category": "%s", "lang": "%s"}');
        createTemplate('{"title": "%s", "type": "uint", "decimals": 18, "category": "%s", "lang": "%s"}');
        createTemplate('{"title": "%s", "type": "single-select", "outcomes": [%s], "category": "%s", "lang": "%s"}');
        createTemplate('{"title": "%s", "type": "multiple-select", "outcomes": [%s], "category": "%s", "lang": "%s"}');
        createTemplate('{"title": "%s", "type": "datetime", "category": "%s", "lang": "%s"}');
    }

    /// @notice Function for arbitrator to set an optional per-question fee. 
    /// @dev The per-question fee, charged when a question is asked, is intended as an anti-spam measure.
    /// @param fee The fee to be charged by the arbitrator when a question is asked
    function setQuestionFee(uint256 fee) 
        stateAny() 
    external {
        arbitrator_question_fees[msg.sender] = fee;
        emit LogSetQuestionFee(msg.sender, fee);
    }

    /// @notice Create a reusable template, which should be a JSON document.
    /// Placeholders should use gettext() syntax, eg %s.
    /// @dev Template data is only stored in the event logs, but its block number is kept in contract storage.
    /// @param content The template content
    /// @return The ID of the newly-created template, which is created sequentially.
    function createTemplate(string memory content) 
        stateAny()
    public returns (uint256) {
        uint256 id = nextTemplateID;
        templates[id] = block.number;
        template_hashes[id] = keccak256(abi.encodePacked(content));
        emit LogNewTemplate(id, msg.sender, content);
        nextTemplateID = id + 1;
        return id;
    }

    /// @notice Create a new reusable template and use it to ask a question
    /// @dev Template data is only stored in the event logs, but its block number is kept in contract storage.
    /// @param content The template content
    /// @param question A string containing the parameters that will be passed into the template to make the question
    /// @param arbitrator The arbitration contract that will have the final word on the answer if there is a dispute
    /// @param timeout How long the contract should wait after the answer is changed before finalizing on that answer
    /// @param opening_ts If set, the earliest time it should be possible to answer the question.
    /// @param nonce A user-specified nonce used in the question ID. Change it to repeat a question.
    /// @return The ID of the newly-created template, which is created sequentially.
    function createTemplateAndAskQuestion(
        string memory content, 
        string memory question, address arbitrator, uint32 timeout, uint32 opening_ts, uint256 nonce 
    ) 
        // stateNotCreated is enforced by the internal _askQuestion
    public payable returns (bytes32) {
        uint256 template_id = createTemplate(content);
        return askQuestion(template_id, question, arbitrator, timeout, opening_ts, nonce);
    }

    /// @notice Ask a new question and return the ID
    /// @dev Template data is only stored in the event logs, but its block number is kept in contract storage.
    /// @param template_id The ID number of the template the question will use
    /// @param question A string containing the parameters that will be passed into the template to make the question
    /// @param arbitrator The arbitration contract that will have the final word on the answer if there is a dispute
    /// @param timeout How long the contract should wait after the answer is changed before finalizing on that answer
    /// @param opening_ts If set, the earliest time it should be possible to answer the question.
    /// @param nonce A user-specified nonce used in the question ID. Change it to repeat a question.
    /// @return The ID of the newly-created question, created deterministically.
    function askQuestion(uint256 template_id, string memory question, address arbitrator, uint32 timeout, uint32 opening_ts, uint256 nonce) 
        // stateNotCreated is enforced by the internal _askQuestion
    public payable returns (bytes32) {

        require(templates[template_id] > 0, "template must exist");

        bytes32 content_hash = keccak256(abi.encodePacked(template_id, opening_ts, question));
        bytes32 question_id = keccak256(abi.encodePacked(content_hash, arbitrator, timeout, uint256(0), address(this), msg.sender, nonce));

        // We emit this event here because _askQuestion doesn't need to know the unhashed question. Other events are emitted by _askQuestion.
        emit LogNewQuestion(question_id, msg.sender, template_id, question, content_hash, arbitrator, timeout, opening_ts, nonce, block.timestamp);
        _askQuestion(question_id, content_hash, arbitrator, timeout, opening_ts, 0);

        return question_id;
    }

    /// @notice Ask a new question and return the ID
    /// @dev Template data is only stored in the event logs, but its block number is kept in contract storage.
    /// @param template_id The ID number of the template the question will use
    /// @param question A string containing the parameters that will be passed into the template to make the question
    /// @param arbitrator The arbitration contract that will have the final word on the answer if there is a dispute
    /// @param timeout How long the contract should wait after the answer is changed before finalizing on that answer
    /// @param opening_ts If set, the earliest time it should be possible to answer the question.
    /// @param nonce A user-specified nonce used in the question ID. Change it to repeat a question.
    /// @param min_bond The minimum bond that may be used for an answer.
    /// @return The ID of the newly-created question, created deterministically.
    function askQuestionWithMinBond(uint256 template_id, string memory question, address arbitrator, uint32 timeout, uint32 opening_ts, uint256 nonce, uint256 min_bond) 
        // stateNotCreated is enforced by the internal _askQuestion
    public payable returns (bytes32) {

        require(templates[template_id] > 0, "template must exist");

        bytes32 content_hash = keccak256(abi.encodePacked(template_id, opening_ts, question));
        bytes32 question_id = keccak256(abi.encodePacked(content_hash, arbitrator, timeout, min_bond, address(this), msg.sender, nonce));

        // We emit this event here because _askQuestion doesn't need to know the unhashed question.
        // Other events are emitted by _askQuestion.
        emit LogNewQuestion(question_id, msg.sender, template_id, question, content_hash, arbitrator, timeout, opening_ts, nonce, block.timestamp);
        _askQuestion(question_id, content_hash, arbitrator, timeout, opening_ts, min_bond);

        return question_id;
    }

    function _askQuestion(bytes32 question_id, bytes32 content_hash, address arbitrator, uint32 timeout, uint32 opening_ts, uint256 min_bond) 
        stateNotCreated(question_id)
    internal {

        // A timeout of 0 makes no sense, and we will use this to check existence
        require(timeout > 0, "timeout must be positive"); 
        require(timeout < 365 days, "timeout must be less than 365 days"); 

        uint256 bounty = msg.value;

        // The arbitrator can set a fee for asking a question. 
        // This is intended as an anti-spam defence.
        // The fee is waived if the arbitrator is asking the question.
        // This allows them to set an impossibly high fee and make users proxy the question through them.
        // This would allow more sophisticated pricing, question whitelisting etc.
        if (arbitrator != NULL_ADDRESS && msg.sender != arbitrator) {
            uint256 question_fee = arbitrator_question_fees[arbitrator];
            require(bounty >= question_fee, "ETH provided must cover question fee"); 
            bounty = bounty - question_fee;
            balanceOf[arbitrator] = balanceOf[arbitrator] + question_fee;
        }

        questions[question_id].content_hash = content_hash;
        questions[question_id].arbitrator = arbitrator;
        questions[question_id].opening_ts = opening_ts;
        questions[question_id].timeout = timeout;

        if (bounty > 0) {
            questions[question_id].bounty = bounty;
            emit LogFundAnswerBounty(question_id, bounty, bounty, msg.sender);
        }

        if (min_bond > 0) {
            questions[question_id].min_bond = min_bond;
            emit LogMinimumBond(question_id, min_bond);
        }

    }

    /// @notice Add funds to the bounty for a question
    /// @dev Add bounty funds after the initial question creation. Can be done any time until the question is finalized.
    /// @param question_id The ID of the question you wish to fund
    function fundAnswerBounty(bytes32 question_id) 
        stateOpen(question_id)
    external payable {
        questions[question_id].bounty = questions[question_id].bounty + msg.value;
        emit LogFundAnswerBounty(question_id, msg.value, questions[question_id].bounty, msg.sender);
    }

    /// @notice Submit an answer for a question.
    /// @dev Adds the answer to the history and updates the current "best" answer.
    /// May be subject to front-running attacks; Substitute submitAnswerCommitment()->submitAnswerReveal() to prevent them.
    /// @param question_id The ID of the question
    /// @param answer The answer, encoded into bytes32
    /// @param max_previous If specified, reverts if a bond higher than this was submitted after you sent your transaction.
    function submitAnswer(bytes32 question_id, bytes32 answer, uint256 max_previous) 
        stateOpen(question_id)
        bondMustDoubleAndMatchMinimum(question_id)
        previousBondMustNotBeatMaxPrevious(question_id, max_previous)
    external payable {
        _addAnswerToHistory(question_id, answer, msg.sender, msg.value, false);
        _updateCurrentAnswer(question_id, answer);
    }

    /// @notice Submit an answer for a question, crediting it to the specified account.
    /// @dev Adds the answer to the history and updates the current "best" answer.
    /// May be subject to front-running attacks; Substitute submitAnswerCommitment()->submitAnswerReveal() to prevent them.
    /// @param question_id The ID of the question
    /// @param answer The answer, encoded into bytes32
    /// @param max_previous If specified, reverts if a bond higher than this was submitted after you sent your transaction.
    /// @param answerer The account to which the answer should be credited
    function submitAnswerFor(bytes32 question_id, bytes32 answer, uint256 max_previous, address answerer)
        stateOpen(question_id)
        bondMustDoubleAndMatchMinimum(question_id)
        previousBondMustNotBeatMaxPrevious(question_id, max_previous)
    external payable {
        require(answerer != NULL_ADDRESS, "answerer must be non-zero");
        _addAnswerToHistory(question_id, answer, answerer, msg.value, false);
        _updateCurrentAnswer(question_id, answer);
    }

    // @notice Verify and store a commitment, including an appropriate timeout
    // @param question_id The ID of the question to store
    // @param commitment The ID of the commitment
    function _storeCommitment(bytes32 question_id, bytes32 commitment_id) 
    internal
    {
        require(commitments[commitment_id].reveal_ts == COMMITMENT_NON_EXISTENT, "commitment must not already exist");

        uint32 commitment_timeout = questions[question_id].timeout / COMMITMENT_TIMEOUT_RATIO;
        commitments[commitment_id].reveal_ts = uint32(block.timestamp) + commitment_timeout;
    }

    /// @notice Submit the hash of an answer, laying your claim to that answer if you reveal it in a subsequent transaction.
    /// @dev Creates a hash, commitment_id, uniquely identifying this answer, to this question, with this bond.
    /// The commitment_id is stored in the answer history where the answer would normally go.
    /// Does not update the current best answer - this is left to the later submitAnswerReveal() transaction.
    /// @param question_id The ID of the question
    /// @param answer_hash The hash of your answer, plus a nonce that you will later reveal
    /// @param max_previous If specified, reverts if a bond higher than this was submitted after you sent your transaction.
    /// @param _answerer If specified, the address to be given as the question answerer. Defaults to the sender.
    /// @dev Specifying the answerer is useful if you want to delegate the commit-and-reveal to a third-party.
    function submitAnswerCommitment(bytes32 question_id, bytes32 answer_hash, uint256 max_previous, address _answerer) 
        stateOpen(question_id)
        bondMustDoubleAndMatchMinimum(question_id)
        previousBondMustNotBeatMaxPrevious(question_id, max_previous)
    external payable {

        bytes32 commitment_id = keccak256(abi.encodePacked(question_id, answer_hash, msg.value));
        address answerer = (_answerer == NULL_ADDRESS) ? msg.sender : _answerer;
        _storeCommitment(question_id, commitment_id);
        _addAnswerToHistory(question_id, commitment_id, answerer, msg.value, true);

    }

    /// @notice Submit the answer whose hash you sent in a previous submitAnswerCommitment() transaction
    /// @dev Checks the parameters supplied recreate an existing commitment, and stores the revealed answer
    /// Updates the current answer unless someone has since supplied a new answer with a higher bond
    /// msg.sender is intentionally not restricted to the user who originally sent the commitment; 
    /// For example, the user may want to provide the answer+nonce to a third-party service and let them send the tx
    /// NB If we are pending arbitration, it will be up to the arbitrator to wait and see any outstanding reveal is sent
    /// @param question_id The ID of the question
    /// @param answer The answer, encoded as bytes32
    /// @param nonce The nonce that, combined with the answer, recreates the answer_hash you gave in submitAnswerCommitment()
    /// @param bond The bond that you paid in your submitAnswerCommitment() transaction
    function submitAnswerReveal(bytes32 question_id, bytes32 answer, uint256 nonce, uint256 bond) 
        stateOpenOrPendingArbitration(question_id)
    external {

        bytes32 answer_hash = keccak256(abi.encodePacked(answer, nonce));
        bytes32 commitment_id = keccak256(abi.encodePacked(question_id, answer_hash, bond));

        require(!commitments[commitment_id].is_revealed, "commitment must not have been revealed yet");
        require(commitments[commitment_id].reveal_ts > uint32(block.timestamp), "reveal deadline must not have passed");

        commitments[commitment_id].revealed_answer = answer;
        commitments[commitment_id].is_revealed = true;

        if (bond == questions[question_id].bond) {
            _updateCurrentAnswer(question_id, answer);
        }

        emit LogAnswerReveal(question_id, msg.sender, answer_hash, answer, nonce, bond);

    }

    function _addAnswerToHistory(bytes32 question_id, bytes32 answer_or_commitment_id, address answerer, uint256 bond, bool is_commitment) 
    internal 
    {
        bytes32 new_history_hash = keccak256(abi.encodePacked(questions[question_id].history_hash, answer_or_commitment_id, bond, answerer, is_commitment));

        // Update the current bond level, if there's a bond (ie anything except arbitration)
        if (bond > 0) {
            questions[question_id].bond = bond;
        }
        questions[question_id].history_hash = new_history_hash;

        emit LogNewAnswer(answer_or_commitment_id, question_id, new_history_hash, answerer, bond, block.timestamp, is_commitment);
    }

    function _updateCurrentAnswer(bytes32 question_id, bytes32 answer)
    internal {
        questions[question_id].best_answer = answer;
        questions[question_id].finalize_ts = uint32(block.timestamp) + questions[question_id].timeout;
    }

    // Like _updateCurrentAnswer but without advancing the timeout
    function _updateCurrentAnswerByArbitrator(bytes32 question_id, bytes32 answer)
    internal {
        questions[question_id].best_answer = answer;
        questions[question_id].finalize_ts = uint32(block.timestamp);
    }

    /// @notice Notify the contract that the arbitrator has been paid for a question, freezing it pending their decision.
    /// @dev The arbitrator contract is trusted to only call this if they've been paid, and tell us who paid them.
    /// @param question_id The ID of the question
    /// @param requester The account that requested arbitration
    /// @param max_previous If specified, reverts if a bond higher than this was submitted after you sent your transaction.
    function notifyOfArbitrationRequest(bytes32 question_id, address requester, uint256 max_previous) 
        onlyArbitrator(question_id)
        stateOpen(question_id)
        previousBondMustNotBeatMaxPrevious(question_id, max_previous)
    external {
        require(questions[question_id].finalize_ts > UNANSWERED, "Question must already have an answer when arbitration is requested");
        questions[question_id].is_pending_arbitration = true;
        emit LogNotifyOfArbitrationRequest(question_id, requester);
    }

    /// @notice Cancel a previously-requested arbitration and extend the timeout
    /// @dev Useful when doing arbitration across chains that can't be requested atomically
    /// @param question_id The ID of the question
    function cancelArbitration(bytes32 question_id) 
        onlyArbitrator(question_id)
        statePendingArbitration(question_id)
    external {
        questions[question_id].is_pending_arbitration = false;
        questions[question_id].finalize_ts = uint32(block.timestamp) + questions[question_id].timeout;
        emit LogCancelArbitration(question_id);
    }

    /// @notice Submit the answer for a question, for use by the arbitrator.
    /// @dev Doesn't require (or allow) a bond.
    /// If the current final answer is correct, the account should be whoever submitted it.
    /// If the current final answer is wrong, the account should be whoever paid for arbitration.
    /// However, the answerer stipulations are not enforced by the contract.
    /// @param question_id The ID of the question
    /// @param answer The answer, encoded into bytes32
    /// @param answerer The account credited with this answer for the purpose of bond claims
    function submitAnswerByArbitrator(bytes32 question_id, bytes32 answer, address answerer) 
        onlyArbitrator(question_id)
        statePendingArbitration(question_id)
    public {

        require(answerer != NULL_ADDRESS, "answerer must be provided");
        emit LogFinalize(question_id, answer);

        questions[question_id].is_pending_arbitration = false;
        _addAnswerToHistory(question_id, answer, answerer, 0, false);
        _updateCurrentAnswerByArbitrator(question_id, answer);

    }

    /// @notice Submit the answer for a question, for use by the arbitrator, working out the appropriate winner based on the last answer details.
    /// @dev Doesn't require (or allow) a bond.
    /// @param question_id The ID of the question
    /// @param answer The answer, encoded into bytes32
    /// @param payee_if_wrong The account to by credited as winner if the last answer given is wrong, usually the account that paid the arbitrator
    /// @param last_history_hash The history hash before the final one
    /// @param last_answer_or_commitment_id The last answer given, or the commitment ID if it was a commitment.
    /// @param last_answerer The address that supplied the last answer
    function assignWinnerAndSubmitAnswerByArbitrator(bytes32 question_id, bytes32 answer, address payee_if_wrong, bytes32 last_history_hash, bytes32 last_answer_or_commitment_id, address last_answerer) 
    external {
        bool is_commitment = _verifyHistoryInputOrRevert(questions[question_id].history_hash, last_history_hash, last_answer_or_commitment_id, questions[question_id].bond, last_answerer);

        address payee;
        // If the last answer is an unrevealed commit, it's always wrong.
        // For anything else, the last answer was set as the "best answer" in submitAnswer or submitAnswerReveal.
        if (is_commitment && !commitments[last_answer_or_commitment_id].is_revealed) {
            require(commitments[last_answer_or_commitment_id].reveal_ts < uint32(block.timestamp), "You must wait for the reveal deadline before finalizing");
            payee = payee_if_wrong;
        } else {
            payee = (questions[question_id].best_answer == answer) ? last_answerer : payee_if_wrong;
        }
        submitAnswerByArbitrator(question_id, answer, payee);
    }


    /// @notice Report whether the answer to the specified question is finalized
    /// @param question_id The ID of the question
    /// @return Return true if finalized
    function isFinalized(bytes32 question_id) 
    view public returns (bool) {
        uint32 finalize_ts = questions[question_id].finalize_ts;
        return ( !questions[question_id].is_pending_arbitration && (finalize_ts > UNANSWERED) && (finalize_ts <= uint32(block.timestamp)) );
    }

    /// @notice (Deprecated) Return the final answer to the specified question, or revert if there isn't one
    /// @param question_id The ID of the question
    /// @return The answer formatted as a bytes32
    function getFinalAnswer(bytes32 question_id) 
        stateFinalized(question_id)
    external view returns (bytes32) {
        return questions[question_id].best_answer;
    }

    /// @notice Return the final answer to the specified question, or revert if there isn't one
    /// @param question_id The ID of the question
    /// @return The answer formatted as a bytes32
    function resultFor(bytes32 question_id) 
        stateFinalized(question_id)
    public view returns (bytes32) {
        return questions[question_id].best_answer;
    }

    /// @notice Returns whether the question was answered before it had an answer, ie resolved to UNRESOLVED_ANSWER
    /// @param question_id The ID of the question 
    function isSettledTooSoon(bytes32 question_id)
    public view returns(bool) {
        return (resultFor(question_id) == UNRESOLVED_ANSWER);
    }

    /// @notice Like resultFor(), but errors out if settled too soon, or returns the result of a replacement if it was reopened at the right time and settled
    /// @param question_id The ID of the question 
    function resultForOnceSettled(bytes32 question_id)
    external view returns(bytes32) {
        bytes32 result = resultFor(question_id);
        if (result == UNRESOLVED_ANSWER) {
            // Try the replacement
            bytes32 replacement_id = reopened_questions[question_id];
            require(replacement_id != bytes32(0x0), "Question was settled too soon and has not been reopened");
            // We only try one layer down rather than recursing to keep the gas costs predictable
            result = resultFor(replacement_id);
            require(result != UNRESOLVED_ANSWER, "Question replacement was settled too soon and has not been reopened");
        }
        return result;
    }

    /// @notice Asks a new question reopening a previously-asked question that was settled too soon
    /// @dev A special version of askQuestion() that replaces a previous question that was settled too soon
    /// @param template_id The ID number of the template the question will use
    /// @param question A string containing the parameters that will be passed into the template to make the question
    /// @param arbitrator The arbitration contract that will have the final word on the answer if there is a dispute
    /// @param timeout How long the contract should wait after the answer is changed before finalizing on that answer
    /// @param opening_ts If set, the earliest time it should be possible to answer the question.
    /// @param nonce A user-specified nonce used in the question ID. Change it to repeat a question.
    /// @param min_bond The minimum bond that can be used to provide the first answer.
    /// @param reopens_question_id The ID of the question this reopens
    /// @return The ID of the newly-created question, created deterministically.
    function reopenQuestion(uint256 template_id, string memory question, address arbitrator, uint32 timeout, uint32 opening_ts, uint256 nonce, uint256 min_bond, bytes32 reopens_question_id)
        // stateNotCreated is enforced by the internal _askQuestion
    public payable returns (bytes32) {

        require(isSettledTooSoon(reopens_question_id), "You can only reopen questions that resolved as settled too soon");

        bytes32 content_hash = keccak256(abi.encodePacked(template_id, opening_ts, question));

        // A reopening must exactly match the original question, except for the nonce and the creator
        require(content_hash == questions[reopens_question_id].content_hash, "content hash mismatch");
        require(arbitrator == questions[reopens_question_id].arbitrator, "arbitrator mismatch");
        require(timeout == questions[reopens_question_id].timeout, "timeout mismatch");
        require(opening_ts == questions[reopens_question_id].opening_ts , "opening_ts mismatch");
        require(min_bond == questions[reopens_question_id].min_bond, "min_bond mismatch");

        // If the the question was itself reopening some previous question, you'll have to re-reopen the previous question first.
        // This ensures the bounty can be passed on to the next attempt of the original question.
        require(!reopener_questions[reopens_question_id], "Question is already reopening a previous question");

        // A question can only be reopened once, unless the reopening was also settled too soon in which case it can be replaced
        bytes32 existing_reopen_question_id = reopened_questions[reopens_question_id];

        // Normally when we reopen a question we will take its bounty and pass it on to the reopened version.
        bytes32 take_bounty_from_question_id = reopens_question_id;
        // If the question has already been reopened but was again settled too soon, we can transfer its bounty to the next attempt.
        if (existing_reopen_question_id != bytes32(0)) {
            require(isSettledTooSoon(existing_reopen_question_id), "Question has already been reopened");
            // We'll overwrite the reopening with our new question and move the bounty.
            // Once that's done we'll detach the failed reopener and you'll be able to reopen that too if you really want, but without the bounty.
            reopener_questions[existing_reopen_question_id] = false;
            take_bounty_from_question_id = existing_reopen_question_id;
        }

        bytes32 question_id = askQuestionWithMinBond(template_id, question, arbitrator, timeout, opening_ts, nonce, min_bond);

        reopened_questions[reopens_question_id] = question_id;
        reopener_questions[question_id] = true;

        questions[question_id].bounty = questions[take_bounty_from_question_id].bounty + questions[question_id].bounty;
        questions[take_bounty_from_question_id].bounty = 0;

        emit LogReopenQuestion(question_id, reopens_question_id);

        return question_id;
    }

    /// @notice Return the final answer to the specified question, provided it matches the specified criteria.
    /// @dev Reverts if the question is not finalized, or if it does not match the specified criteria.
    /// @param question_id The ID of the question
    /// @param content_hash The hash of the question content (template ID + opening time + question parameter string)
    /// @param arbitrator The arbitrator chosen for the question (regardless of whether they are asked to arbitrate)
    /// @param min_timeout The timeout set in the initial question settings must be this high or higher
    /// @param min_bond The bond sent with the final answer must be this high or higher
    /// @return The answer formatted as a bytes32
    function getFinalAnswerIfMatches(
        bytes32 question_id, 
        bytes32 content_hash, address arbitrator, uint32 min_timeout, uint256 min_bond
    ) 
        stateFinalized(question_id)
    external view returns (bytes32) {
        require(content_hash == questions[question_id].content_hash, "content hash must match");
        require(arbitrator == questions[question_id].arbitrator, "arbitrator must match");
        require(min_timeout <= questions[question_id].timeout, "timeout must be long enough");
        require(min_bond <= questions[question_id].bond, "bond must be high enough");
        return questions[question_id].best_answer;
    }

    /// @notice Assigns the winnings (bounty and bonds) to everyone who gave the accepted answer
    /// Caller must provide the answer history, in reverse order
    /// @dev Works up the chain and assign bonds to the person who gave the right answer
    /// If someone gave the winning answer earlier, they must get paid from the higher bond
    /// That means we can't pay out the bond added at n until we have looked at n-1
    /// The first answer is authenticated by checking against the stored history_hash.
    /// One of the inputs to history_hash is the history_hash before it, so we use that to authenticate the next entry, etc
    /// Once we get to a null hash we'll know we're done and there are no more answers.
    /// Usually you would call the whole thing in a single transaction, but if not then the data is persisted to pick up later.
    /// @param question_id The ID of the question
    /// @param history_hashes Second-last-to-first, the hash of each history entry. (Final one should be empty).
    /// @param addrs Last-to-first, the address of each answerer or commitment sender
    /// @param bonds Last-to-first, the bond supplied with each answer or commitment
    /// @param answers Last-to-first, each answer supplied, or commitment ID if the answer was supplied with commit->reveal
    function claimWinnings(
        bytes32 question_id, 
        bytes32[] memory history_hashes, address[] memory addrs, uint256[] memory bonds, bytes32[] memory answers
    ) 
        stateFinalized(question_id)
    public {

        require(history_hashes.length > 0, "at least one history hash entry must be provided");

        // These are only set if we split our claim over multiple transactions.
        address payee = question_claims[question_id].payee; 
        uint256 last_bond = question_claims[question_id].last_bond; 
        uint256 queued_funds = question_claims[question_id].queued_funds; 

        // Starts as the hash of the final answer submitted. It'll be cleared when we're done.
        // If we're splitting the claim over multiple transactions, it'll be the hash where we left off last time
        bytes32 last_history_hash = questions[question_id].history_hash;

        bytes32 best_answer = questions[question_id].best_answer;

        uint256 i;
        for (i = 0; i < history_hashes.length; i++) {
        
            // Check input against the history hash, and see which of 2 possible values of is_commitment fits.
            bool is_commitment = _verifyHistoryInputOrRevert(last_history_hash, history_hashes[i], answers[i], bonds[i], addrs[i]);
            
            queued_funds = queued_funds + last_bond; 
            (queued_funds, payee) = _processHistoryItem(
                question_id, best_answer, queued_funds, payee, 
                addrs[i], bonds[i], answers[i], is_commitment);
 
            // Line the bond up for next time, when it will be added to somebody's queued_funds
            last_bond = bonds[i];

            // Burn (just leave in contract balance) a fraction of all bonds except the final one.
            // This creates a cost to increasing your own bond, which could be used to delay resolution maliciously
            if (last_bond != questions[question_id].bond) {
                last_bond = last_bond - last_bond / BOND_CLAIM_FEE_PROPORTION;
            }

            last_history_hash = history_hashes[i];

        }
 
        if (last_history_hash != NULL_HASH) {
            // We haven't yet got to the null hash (1st answer), ie the caller didn't supply the full answer chain.
            // Persist the details so we can pick up later where we left off later.

            // If we know who to pay we can go ahead and pay them out, only keeping back last_bond
            // (We always know who to pay unless all we saw were unrevealed commits)
            if (payee != NULL_ADDRESS) {
                _payPayee(question_id, payee, queued_funds);
                queued_funds = 0;
            }

            question_claims[question_id].payee = payee;
            question_claims[question_id].last_bond = last_bond;
            question_claims[question_id].queued_funds = queued_funds;
        } else {
            // There is nothing left below us so the payee can keep what remains
            _payPayee(question_id, payee, queued_funds + last_bond);
            delete question_claims[question_id];
        }

        questions[question_id].history_hash = last_history_hash;

    }

    function _payPayee(bytes32 question_id, address payee, uint256 value) 
    internal {
        balanceOf[payee] = balanceOf[payee] + value;
        emit LogClaim(question_id, payee, value);
    }

    function _verifyHistoryInputOrRevert(
        bytes32 last_history_hash,
        bytes32 history_hash, bytes32 answer, uint256 bond, address addr
    )
    internal pure returns (bool) {
        if (last_history_hash == keccak256(abi.encodePacked(history_hash, answer, bond, addr, true)) ) {
            return true;
        }
        if (last_history_hash == keccak256(abi.encodePacked(history_hash, answer, bond, addr, false)) ) {
            return false;
        } 
        revert("History input provided did not match the expected hash");
    }

    function _processHistoryItem(
        bytes32 question_id, bytes32 best_answer, 
        uint256 queued_funds, address payee, 
        address addr, uint256 bond, bytes32 answer, bool is_commitment
    )
    internal returns (uint256, address) {

        // For commit-and-reveal, the answer history holds the commitment ID instead of the answer.
        // We look at the referenced commitment ID and switch in the actual answer.
        if (is_commitment) {
            bytes32 commitment_id = answer;
            // If it's a commit but it hasn't been revealed, it will always be considered wrong.
            if (!commitments[commitment_id].is_revealed) {
                delete commitments[commitment_id];
                return (queued_funds, payee);
            } else {
                answer = commitments[commitment_id].revealed_answer;
                delete commitments[commitment_id];
            }
        }

        if (answer == best_answer) {

            if (payee == NULL_ADDRESS) {

                // The entry is for the first payee we come to, ie the winner.
                // They get the question bounty.
                payee = addr;

                if (best_answer != UNRESOLVED_ANSWER && questions[question_id].bounty > 0) {
                    _payPayee(question_id, payee, questions[question_id].bounty);
                    questions[question_id].bounty = 0;
                }

            } else if (addr != payee) {

                // Answerer has changed, ie we found someone lower down who needs to be paid

                // The lower answerer will take over receiving bonds from higher answerer.
                // They should also be paid the takeover fee, which is set at a rate equivalent to their bond. 
                // (This is our arbitrary rule, to give consistent right-answerers a defence against high-rollers.)

                // There should be enough for the fee, but if not, take what we have.
                // There's an edge case involving weird arbitrator behaviour where we may be short.
                uint256 answer_takeover_fee = (queued_funds >= bond) ? bond : queued_funds;
                // Settle up with the old (higher-bonded) payee
                _payPayee(question_id, payee, queued_funds - answer_takeover_fee);

                // Now start queued_funds again for the new (lower-bonded) payee
                payee = addr;
                queued_funds = answer_takeover_fee;

            }

        }

        return (queued_funds, payee);

    }

    /// @notice Convenience function to assign bounties/bonds for multiple questions in one go, then withdraw all your funds.
    /// Caller must provide the answer history for each question, in reverse order
    /// @dev Can be called by anyone to assign bonds/bounties, but funds are only withdrawn for the user making the call.
    /// @param question_ids The IDs of the questions you want to claim for
    /// @param lengths The number of history entries you will supply for each question ID
    /// @param hist_hashes In a single list for all supplied questions, the hash of each history entry.
    /// @param addrs In a single list for all supplied questions, the address of each answerer or commitment sender
    /// @param bonds In a single list for all supplied questions, the bond supplied with each answer or commitment
    /// @param answers In a single list for all supplied questions, each answer supplied, or commitment ID 
    function claimMultipleAndWithdrawBalance(
        bytes32[] memory question_ids, uint256[] memory lengths, 
        bytes32[] memory hist_hashes, address[] memory addrs, uint256[] memory bonds, bytes32[] memory answers
    ) 
        stateAny() // The finalization checks are done in the claimWinnings function
    public {
        
        uint256 qi;
        uint256 i;
        for (qi = 0; qi < question_ids.length; qi++) {
            bytes32 qid = question_ids[qi];
            uint256 ln = lengths[qi];
            bytes32[] memory hh = new bytes32[](ln);
            address[] memory ad = new address[](ln);
            uint256[] memory bo = new uint256[](ln);
            bytes32[] memory an = new bytes32[](ln);
            uint256 j;
            for (j = 0; j < ln; j++) {
                hh[j] = hist_hashes[i];
                ad[j] = addrs[i];
                bo[j] = bonds[i];
                an[j] = answers[i];
                i++;
            }
            claimWinnings(qid, hh, ad, bo, an);
        }
        withdraw();
    }

    /// @notice Returns the questions's content hash, identifying the question content
    /// @param question_id The ID of the question 
    function getContentHash(bytes32 question_id) 
    public view returns(bytes32) {
        return questions[question_id].content_hash;
    }

    /// @notice Returns the arbitrator address for the question
    /// @param question_id The ID of the question 
    function getArbitrator(bytes32 question_id) 
    public view returns(address) {
        return questions[question_id].arbitrator;
    }

    /// @notice Returns the timestamp when the question can first be answered
    /// @param question_id The ID of the question 
    function getOpeningTS(bytes32 question_id) 
    public view returns(uint32) {
        return questions[question_id].opening_ts;
    }

    /// @notice Returns the timeout in seconds used after each answer
    /// @param question_id The ID of the question 
    function getTimeout(bytes32 question_id) 
    public view returns(uint32) {
        return questions[question_id].timeout;
    }

    /// @notice Returns the timestamp at which the question will be/was finalized
    /// @param question_id The ID of the question 
    function getFinalizeTS(bytes32 question_id) 
    public view returns(uint32) {
        return questions[question_id].finalize_ts;
    }

    /// @notice Returns whether the question is pending arbitration
    /// @param question_id The ID of the question 
    function isPendingArbitration(bytes32 question_id) 
    public view returns(bool) {
        return questions[question_id].is_pending_arbitration;
    }

    /// @notice Returns the current total unclaimed bounty
    /// @dev Set back to zero once the bounty has been claimed
    /// @param question_id The ID of the question 
    function getBounty(bytes32 question_id) 
    public view returns(uint256) {
        return questions[question_id].bounty;
    }

    /// @notice Returns the current best answer
    /// @param question_id The ID of the question 
    function getBestAnswer(bytes32 question_id) 
    public view returns(bytes32) {
        return questions[question_id].best_answer;
    }

    /// @notice Returns the history hash of the question 
    /// @param question_id The ID of the question 
    /// @dev Updated on each answer, then rewound as each is claimed
    function getHistoryHash(bytes32 question_id) 
    public view returns(bytes32) {
        return questions[question_id].history_hash;
    }

    /// @notice Returns the highest bond posted so far for a question
    /// @param question_id The ID of the question 
    function getBond(bytes32 question_id) 
    public view returns(uint256) {
        return questions[question_id].bond;
    }

    /// @notice Returns the minimum bond that can answer the question
    /// @param question_id The ID of the question
    function getMinBond(bytes32 question_id)
    public view returns(uint256) {
        return questions[question_id].min_bond;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@reality.eth/contracts/development/contracts/RealityETH-3.0.sol";
import "./interfaces/IERC2981.sol";
import "./BetNFTDescriptor.sol";

interface IManager {
    function creator() external view returns (address payable);
}

contract Market is ERC721, IERC2981 {
    struct MarketInfo {
        uint16 fee;
        uint16 royaltyFee;
        address payable manager;
        string marketName;
        string marketSymbol;
    }

    struct Result {
        uint256 tokenID;
        uint248 points;
        bool claimed;
    }

    struct BetData {
        uint256 count;
        bytes32[] predictions;
    }

    uint256 public constant DIVISOR = 10000;
    uint256 public constant CLEAN_TOKEN_ID = uint256(type(uint128).max);

    MarketInfo public marketInfo;
    address public betNFTDescriptor;
    RealityETH_v3_0 public realitio;
    uint256 public nextTokenID;
    bool public initialized;
    uint256 public resultSubmissionPeriodStart;
    uint256 public price;
    uint256 public closingTime;
    uint256 public submissionTimeout;
    uint256 public totalPrize;
    uint256 public managementReward;
    uint256 public totalAttributions;

    bytes32 public questionsHash;
    bytes32[] public questionIDs;
    uint16[] public prizeWeights;
    mapping(bytes32 => BetData) public bets; // bets[tokenHash]
    mapping(uint256 => Result) public ranking; // ranking[index]
    mapping(uint256 => bytes32) public tokenIDtoTokenHash; // tokenIDtoTokenHash[tokenID]
    mapping(uint256 => bool) public isRanked; // isRanked[tokenID]
    mapping(address => uint256) public attributionBalance; // attributionBalance[attribution]

    event FundingReceived(address indexed _funder, uint256 _amount, string _message);

    event PlaceBet(
        address indexed _player,
        uint256 indexed tokenID,
        bytes32 indexed _tokenHash,
        bytes32[] _predictions
    );

    event BetReward(uint256 indexed _tokenID, uint256 _reward);

    event RankingUpdated(uint256 indexed _tokenID, uint256 _points, uint256 _index);

    event Attribution(address indexed _provider);

    event ManagementReward(address _manager, uint256 _managementReward);

    event QuestionsRegistered(bytes32[] _questionIDs);

    event Prizes(uint16[] _prizes);

    constructor() ERC721("", "") {}

    function initialize(
        MarketInfo memory _marketInfo,
        address _nftDescriptor,
        address _realityETH,
        uint256 _closingTime,
        uint256 _price,
        uint256 _submissionTimeout,
        bytes32[] memory _questionIDs,
        uint16[] memory _prizeWeights
    ) external {
        require(!initialized, "Already initialized.");
        require(_marketInfo.fee < DIVISOR, "Management fee too big");
        require(_marketInfo.royaltyFee < DIVISOR, "Royalty fee too big");

        marketInfo = _marketInfo;
        betNFTDescriptor = _nftDescriptor;
        realitio = RealityETH_v3_0(_realityETH);
        closingTime = _closingTime;
        price = _price;
        submissionTimeout = _submissionTimeout;

        questionsHash = keccak256(abi.encodePacked(_questionIDs));
        questionIDs = _questionIDs;

        uint256 sumWeights;
        for (uint256 i = 0; i < _prizeWeights.length; i++) {
            sumWeights += uint256(_prizeWeights[i]);
        }
        require(sumWeights == DIVISOR, "Invalid weights");
        prizeWeights = _prizeWeights;

        initialized = true;
        emit QuestionsRegistered(questionIDs);
        emit Prizes(_prizeWeights);
    }

    /** @dev Places a bet by providing predictions to each question. A bet NFT is minted.
     *  @param _attribution Address that sent the referral. If 0x0, it's ignored.
     *  @param _results Answer predictions to the questions asked in Realitio.
     *  @return the minted token id.
     */
    function placeBet(address _attribution, bytes32[] calldata _results)
        external
        payable
        returns (uint256)
    {
        require(msg.value == price, "Wrong value sent");
        require(_results.length == questionIDs.length, "Results mismatch");
        require(block.timestamp < closingTime, "Bets not allowed");

        if (_attribution != address(0x0)) {
            attributionBalance[_attribution] += 1;
            totalAttributions += 1;
            emit Attribution(_attribution);
        }

        bytes32 tokenHash = keccak256(abi.encodePacked(_results));
        tokenIDtoTokenHash[nextTokenID] = tokenHash;
        BetData storage bet = bets[tokenHash];
        if (bet.count == 0) bet.predictions = _results;
        bet.count += 1;

        _mint(msg.sender, nextTokenID);
        emit PlaceBet(msg.sender, nextTokenID, tokenHash, _results);

        return nextTokenID++;
    }

    /** @dev Passes the contract state to the submission period if all the Realitio results are available.
     *  The management fee is paid to the manager address.
     */
    function registerAvailabilityOfResults() external {
        require(block.timestamp > closingTime, "Bets ongoing");
        require(resultSubmissionPeriodStart == 0, "Results already available");

        for (uint256 i = 0; i < questionIDs.length; i++) {
            realitio.resultForOnceSettled(questionIDs[i]); // Reverts if not finalized.
        }

        resultSubmissionPeriodStart = block.timestamp;
        uint256 marketBalance = address(this).balance;
        managementReward = (marketBalance * marketInfo.fee) / DIVISOR;
        totalPrize = marketBalance - managementReward;

        // Once the Market is created, the manager contract is immutable, created by the MarketFactory and will never block a transfer of funds.
        (bool success, ) = marketInfo.manager.call{value: managementReward}(new bytes(0));
        require(success, "Send XDAI failed");

        emit ManagementReward(marketInfo.manager, managementReward);
    }

    /** @dev Registers the points obtained by a bet after the results are known. Ranking should be filled
     *  in descending order. Bets which points were not registered cannot claimed rewards even if they
     *  got more points than the ones registered.
     *  @param _tokenID The token id of the bet which points are going to be registered.
     *  @param _rankIndex The alleged ranking position the bet belongs to.
     *  @param _duplicates The alleged number of tokens that are already registered and have the same points as _tokenID.
     */
    function registerPoints(
        uint256 _tokenID,
        uint256 _rankIndex,
        uint256 _duplicates
    ) external {
        require(resultSubmissionPeriodStart != 0, "Not in submission period");
        require(
            block.timestamp < resultSubmissionPeriodStart + submissionTimeout,
            "Submission period over"
        );
        require(_exists(_tokenID), "Token does not exist");
        require(!isRanked[_tokenID], "Token already registered");

        bytes32[] memory predictions = bets[tokenIDtoTokenHash[_tokenID]].predictions;
        uint248 totalPoints;
        for (uint256 i = 0; i < questionIDs.length; i++) {
            if (predictions[i] == realitio.resultForOnceSettled(questionIDs[i])) {
                totalPoints += 1;
            }
        }

        require(totalPoints > 0, "You are not a winner");
        // This ensures that ranking[N].points >= ranking[N+1].points always
        require(
            _rankIndex == 0 || totalPoints < ranking[_rankIndex - 1].points,
            "Invalid ranking index"
        );
        if (totalPoints > ranking[_rankIndex].points) {
            if (ranking[_rankIndex].points > 0) {
                // Rank position is being overwritten
                isRanked[ranking[_rankIndex].tokenID] = false;
            }
            ranking[_rankIndex].tokenID = _tokenID;
            ranking[_rankIndex].points = totalPoints;
            isRanked[_tokenID] = true;
            emit RankingUpdated(_tokenID, totalPoints, _rankIndex);
        } else if (ranking[_rankIndex].points == totalPoints) {
            uint256 realRankIndex = _rankIndex + _duplicates;
            require(totalPoints > ranking[realRankIndex].points, "Wrong _duplicates amount");
            require(totalPoints == ranking[realRankIndex - 1].points, "Wrong _duplicates amount");
            if (ranking[realRankIndex].points > 0) {
                // Rank position is being overwritten
                isRanked[ranking[realRankIndex].tokenID] = false;
            }
            ranking[realRankIndex].tokenID = _tokenID;
            ranking[realRankIndex].points = totalPoints;
            isRanked[_tokenID] = true;
            emit RankingUpdated(_tokenID, totalPoints, realRankIndex);
        }
    }

    /** @dev Register all winning bets and move the contract state to the claiming phase.
     *  This function is gas intensive and might not be available for markets in which lots of
     *  bets have been placed.
     */
    function registerAll() external {
        require(resultSubmissionPeriodStart != 0, "Not in submission period");
        require(
            block.timestamp < resultSubmissionPeriodStart + submissionTimeout,
            "Submission period over"
        );

        uint256 totalQuestions = questionIDs.length;
        bytes32[] memory results = new bytes32[](totalQuestions);
        for (uint256 i = 0; i < totalQuestions; i++) {
            results[i] = realitio.resultForOnceSettled(questionIDs[i]);
        }

        uint256[] memory auxRanking = new uint256[](nextTokenID);
        uint256 currentMin;
        uint256 freePos;
        for (uint256 tokenID = 0; tokenID < nextTokenID; tokenID++) {
            BetData storage betData = bets[tokenIDtoTokenHash[tokenID]];
            uint256 totalPoints;
            for (uint256 i = 0; i < totalQuestions; i++) {
                if (betData.predictions[i] == results[i]) totalPoints += 1;
            }

            if (totalPoints == 0 || (totalPoints < currentMin && freePos >= prizeWeights.length))
                continue;

            auxRanking[freePos++] = totalPoints | (tokenID << 128);

            if (totalPoints > currentMin) {
                sort(auxRanking, 0, int256(freePos - 1));

                currentMin = auxRanking[prizeWeights.length - 1] & CLEAN_TOKEN_ID;
                if (freePos > prizeWeights.length) {
                    while (currentMin > auxRanking[freePos] & CLEAN_TOKEN_ID) freePos--;
                    freePos++;
                }
            } else if (totalPoints < currentMin) {
                currentMin = totalPoints;
            }
        }

        for (uint256 rankIndex = 0; rankIndex < freePos; rankIndex++) {
            uint256 tokenID = auxRanking[rankIndex] >> 128;
            uint256 totalPoints = auxRanking[rankIndex] & CLEAN_TOKEN_ID;
            ranking[rankIndex].tokenID = tokenID;
            ranking[rankIndex].points = uint248(totalPoints);
            emit RankingUpdated(tokenID, totalPoints, rankIndex);
        }

        resultSubmissionPeriodStart = 1;
    }

    function sort(
        uint256[] memory arr,
        int256 left,
        int256 right
    ) internal pure {
        if (left == right) return;
        int256 i = left;
        int256 j = right;
        uint256 pivot = arr[uint256(left + (right - left) / 2)] & CLEAN_TOKEN_ID;
        while (i <= j) {
            while (arr[uint256(i)] & CLEAN_TOKEN_ID > pivot) i++;
            while (pivot > arr[uint256(j)] & CLEAN_TOKEN_ID) j--;
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
                i++;
                j--;
            }
        }
        if (left < j) sort(arr, left, j);
        if (i < right) sort(arr, i, right);
    }

    /** @dev Sends a prize to the token holder if applicable.
     *  @param _rankIndex The ranking position of the bet which reward is being claimed.
     *  @param _firstSharedIndex If there are many tokens sharing the same score, this is the first ranking position of the batch.
     *  @param _lastSharedIndex If there are many tokens sharing the same score, this is the last ranking position of the batch.
     */
    function claimRewards(
        uint256 _rankIndex,
        uint256 _firstSharedIndex,
        uint256 _lastSharedIndex
    ) external {
        require(resultSubmissionPeriodStart != 0, "Not in claim period");
        require(
            block.timestamp > resultSubmissionPeriodStart + submissionTimeout,
            "Submission period not over"
        );
        require(!ranking[_rankIndex].claimed, "Already claimed");

        uint248 points = ranking[_rankIndex].points;
        // Check that shared indexes are valid.
        require(points == ranking[_firstSharedIndex].points, "Wrong start index");
        require(points == ranking[_lastSharedIndex].points, "Wrong end index");
        require(points > ranking[_lastSharedIndex + 1].points, "Wrong end index");
        require(
            _firstSharedIndex == 0 || points < ranking[_firstSharedIndex - 1].points,
            "Wrong start index"
        );
        uint256 sharedBetween = _lastSharedIndex - _firstSharedIndex + 1;

        uint256 cumWeigths = 0;
        for (uint256 i = _firstSharedIndex; i < prizeWeights.length && i <= _lastSharedIndex; i++) {
            cumWeigths += prizeWeights[i];
        }

        uint256 reward = (totalPrize * cumWeigths) / (DIVISOR * sharedBetween);
        ranking[_rankIndex].claimed = true;
        payable(ownerOf(ranking[_rankIndex].tokenID)).transfer(reward);
        emit BetReward(ranking[_rankIndex].tokenID, reward);
    }

    /** @dev Edge case in which no one won or winners were not registered. All players who own a token
     *  are reimburse proportionally (management fee was discounted). Tokens are burnt.
     *  @param _tokenID The token id.
     */
    function reimbursePlayer(uint256 _tokenID) external {
        require(resultSubmissionPeriodStart != 0, "Not in claim period");
        require(
            block.timestamp > resultSubmissionPeriodStart + submissionTimeout,
            "Submission period not over"
        );
        require(ranking[0].points == 0, "Can't reimburse if there are winners");

        uint256 reimbursement = totalPrize / nextTokenID;
        address player = ownerOf(_tokenID);
        _burn(_tokenID); // Can only be reimbursed once.
        payable(player).transfer(reimbursement);
    }

    /** @dev Edge case in which there is a winner but one or more prizes are vacant.
     *  Vacant prizes are distributed equally among registered winner/s.
     */
    function distributeRemainingPrizes() external {
        require(resultSubmissionPeriodStart != 0, "Not in claim period");
        require(
            block.timestamp > resultSubmissionPeriodStart + submissionTimeout,
            "Submission period not over"
        );
        require(ranking[0].points > 0, "No winners");

        uint256 cumWeigths = 0;
        uint256 nWinners = 0;
        for (uint256 i = 0; i < prizeWeights.length; i++) {
            if (ranking[i].points == 0) {
                if (nWinners == 0) nWinners = i;
                require(!ranking[i].claimed, "Already claimed");
                ranking[i].claimed = true;
                cumWeigths += prizeWeights[i];
            }
        }

        require(cumWeigths > 0, "No vacant prizes");
        uint256 vacantPrize = (totalPrize * cumWeigths) / (DIVISOR * nWinners);
        for (uint256 rank = 0; rank < nWinners; rank++) {
            payable(ownerOf(ranking[rank].tokenID)).send(vacantPrize);
            emit BetReward(ranking[rank].tokenID, vacantPrize);
        }
    }

    /** @dev Increases the balance of the market without participating. Only callable during the betting period.
     *  @param _message The message to publish.
     */
    function fundMarket(string calldata _message) external payable {
        require(resultSubmissionPeriodStart == 0, "Results already available");
        emit FundingReceived(msg.sender, msg.value, _message);
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view override returns (string memory) {
        return marketInfo.marketName;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view override returns (string memory) {
        return marketInfo.marketSymbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return BetNFTDescriptor(betNFTDescriptor).tokenURI(tokenId);
    }

    function numberOfQuestions() external view returns (uint256) {
        return questionIDs.length;
    }

    function getPrizes() external view returns (uint256[] memory) {
        uint256[] memory prizeMultipliers = new uint256[](prizeWeights.length);
        for (uint256 i = 0; i < prizeWeights.length; i++) {
            prizeMultipliers[i] = uint256(prizeWeights[i]);
        }

        return prizeMultipliers;
    }

    function getPredictions(uint256 _tokenID) external view returns (bytes32[] memory) {
        require(_exists(_tokenID), "Token does not exist");
        return bets[tokenIDtoTokenHash[_tokenID]].predictions;
    }

    function getScore(uint256 _tokenID) external view returns (uint256 totalPoints) {
        require(resultSubmissionPeriodStart != 0, "Results not available");
        require(_exists(_tokenID), "Token does not exist");

        bytes32[] memory predictions = bets[tokenIDtoTokenHash[_tokenID]].predictions;
        for (uint256 i = 0; i < questionIDs.length; i++) {
            if (predictions[i] == realitio.resultForOnceSettled(questionIDs[i])) {
                totalPoints += 1;
            }
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        override(IERC2981)
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = IManager(marketInfo.manager).creator();
        royaltyAmount = (_salePrice * marketInfo.royaltyFee) / DIVISOR;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./../interfaces/IMarket.sol";

interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256);

    function transfer(address _to, uint256 _amount) external returns (bool);
}

contract Manager {
    address payable public creator;
    uint256 public creatorFee;
    address payable public protocolTreasury;
    uint256 public protocolFee;
    IMarket public market;

    bool public initialized;
    bool public managerRewardDistributed;
    mapping(address => bool) public claimed; // claimed[referral]
    uint256 public amountClaimed;
    uint256 public creatorReward;
    uint256 public protocolReward;

    constructor() {}

    function initialize(
        address payable _creator,
        uint256 _creatorFee,
        address payable _protocolTreasury,
        uint256 _protocolFee,
        address _market
    ) external {
        require(!initialized, "Already initialized.");

        creator = _creator;
        creatorFee = _creatorFee;
        protocolTreasury = _protocolTreasury;
        protocolFee = _protocolFee;
        market = IMarket(_market);

        initialized = true;
    }

    function distributeRewards() external {
        require(market.resultSubmissionPeriodStart() != 0, "Fees not received");
        require(!managerRewardDistributed, "Reward already claimed");

        managerRewardDistributed = true;

        uint256 totalFee = creatorFee + protocolFee;
        uint256 totalReward = market.managementReward();
        uint256 totalBets = market.nextTokenID();
        uint256 nonReferralShare = totalBets - market.totalAttributions();

        uint256 creatorMarketReward = (totalReward * creatorFee * nonReferralShare) /
            (totalBets * totalFee * 2);
        creatorMarketReward += (totalReward * creatorFee) / (totalFee * 2);
        creatorReward += creatorMarketReward;

        uint256 protocolMarketReward = (totalReward * protocolFee * nonReferralShare) /
            (totalBets * totalFee * 3);
        protocolMarketReward += (totalReward * protocolFee * 2) / (totalFee * 3);
        protocolReward += protocolMarketReward;

        amountClaimed += creatorMarketReward + protocolMarketReward;
    }

    function executeCreatorRewards() external {
        uint256 creatorRewardToSend = creatorReward;
        creatorReward = 0;
        requireSendXDAI(creator, creatorRewardToSend);
    }

    function executeProtocolRewards() external {
        uint256 protocolRewardToSend = protocolReward;
        protocolReward = 0;
        requireSendXDAI(protocolTreasury, protocolRewardToSend);
    }

    function claimReferralReward(address _referral) external {
        require(market.resultSubmissionPeriodStart() != 0, "Fees not received");
        require(!claimed[_referral], "Reward already claimed");

        uint256 totalFee = creatorFee + protocolFee;
        uint256 totalReward = market.managementReward();
        uint256 referralShare = market.attributionBalance(_referral);
        uint256 totalBets = market.nextTokenID();

        uint256 rewardFromCreator = (totalReward * creatorFee * referralShare) /
            (totalBets * totalFee * 2);
        uint256 rewardFromProtocol = (totalReward * protocolFee * referralShare) /
            (totalBets * totalFee * 3);

        claimed[_referral] = true;
        amountClaimed += rewardFromCreator + rewardFromProtocol;
        requireSendXDAI(payable(_referral), rewardFromCreator + rewardFromProtocol);
    }

    function distributeSurplus() external {
        require(market.resultSubmissionPeriodStart() != 0, "Can't distribute surplus yet");
        uint256 remainingManagementReward = market.managementReward() - amountClaimed;
        uint256 surplus = address(this).balance -
            remainingManagementReward -
            creatorReward -
            protocolReward;
        creatorReward += surplus / 2;
        protocolReward += surplus / 2;
    }

    function distributeERC20(IERC20 _token) external {
        uint256 tokenBalance = _token.balanceOf(address(this));
        _token.transfer(creator, tokenBalance / 2);
        _token.transfer(protocolTreasury, tokenBalance / 2);
    }

    function requireSendXDAI(address payable _to, uint256 _value) internal {
        (bool success, ) = _to.call{value: _value}(new bytes(0));
        require(success, "Send XDAI failed");
    }

    receive() external payable {}
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.6;

contract BalanceHolder {

    mapping(address => uint256) public balanceOf;

    event LogWithdraw(
        address indexed user,
        uint256 amount
    );

    function withdraw() 
    public {
        uint256 bal = balanceOf[msg.sender];
        balanceOf[msg.sender] = 0;
        payable(msg.sender).transfer(bal);
        emit LogWithdraw(msg.sender, bal);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

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
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
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
pragma solidity 0.8.9;

interface IERC2981 {
    // ERC165
    // royaltyInfo(uint256,uint256) => 0x2a55205a
    // IERC2981 => 0x2a55205a

    // @notice Called with the sale price to determine how much royalty
    //  is owed and to whom.
    // @param _tokenId - the NFT asset queried for royalty information
    // @param _salePrice - the sale price of the NFT asset specified by _tokenId
    // @return receiver - address of who should be sent the royalty payment
    // @return royaltyAmount - the royalty payment amount for _salePrice
    // ERC165 datum royaltyInfo(uint256,uint256) => 0x2a55205a
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import '@openzeppelin/contracts/utils/Strings.sol';
import 'base64-sol/base64.sol';
import "./interfaces/IMarket.sol";

interface ICurate {
    function isRegistered(bytes32 questionsHash) external view returns(bool);
    function getTitle(bytes32 _questionsHash) external view returns(string memory);
    function getTimestamp(bytes32 _questionsHash) external view returns(uint256);
}

interface IFirstPriceAuction {
    function getAd(address _market, uint256 _tokenID) external view returns (string memory);
    function getRef(address _market, uint256 _tokenID) external view returns (string memory);
}

library HexStrings {
    bytes16 internal constant ALPHABET = '0123456789abcdef';

    /// @notice Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length, without 0x.
    /// @dev Credit to Open Zeppelin under MIT license https://github.com/OpenZeppelin/openzeppelin-contracts/blob/243adff49ce1700e0ecb99fe522fb16cff1d1ddc/contracts/utils/Strings.sol#L55
    function toHexStringNoPrefix(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length);
        for (uint256 i = buffer.length; i > 0; i--) {
            buffer[i - 1] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
    }
}

contract BetNFTDescriptor is Initializable { 
    
    using Strings for uint256;
    using HexStrings for uint256;

    address public curatedMarkets;
    address public ads;

    function initialize(address _curatedMarkets) public initializer {
        curatedMarkets = _curatedMarkets;
    }

    function setAdsAddress(address _ads) external {
        require(ads == address(0x0), "address already set");
        ads = _ads;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        string memory marketName = getMarketName();
        string memory nftName = generateName(tokenId, marketName);
        string memory marketFee = generateFee();
        string memory descriptionPartOne = generateDescriptionPartOne();
        string memory descriptionPartTwo =
            generateDescriptionPartTwo(
                tokenId,
                marketName,
                marketFee
            );
        string memory image = Base64.encode(bytes(generateSVGImage(
            tokenId,
            marketName,
            marketFee
        )));
        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                nftName,
                                '", "description":"',
                                descriptionPartOne,
                                descriptionPartTwo,
                                '", "image": "',
                                'data:image/svg+xml;base64,',
                                image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function generateDescriptionPartOne() private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    'This NFT represents a betting position in a prediction market pool. ',
                    'The owner of this NFT may claim a prize if this bet wins.\\n\\n'
                )
            );
    }

    function generateDescriptionPartTwo(
        uint256 tokenId,
        string memory marketName,
        string memory fee
    ) private view returns (string memory) {
        string memory marketAddress = addressToString(msg.sender);
        string memory link = string(
                abi.encodePacked(
                    'https://prode.eth.limo/#/markets/',
                    marketAddress,
                    '/',
                    tokenId.toString()
                )
        );
        return
            string(
                abi.encodePacked(
                    'Market address: ',
                    marketAddress,
                    '\\nMarket name: ',
                    marketName,
                    '\\nFee: ',
                    fee,
                    '\\nToken ID: ',
                    tokenId.toString(),
                    '\\nFull display: ',
                    link,
                    '\\n\\n',
                    unicode'⚠️ DISCLAIMER: Due diligence is imperative when assessing this NFT. Make sure token addresses match the expected tokens, as token symbols may be imitated.'
                )
            );
    }

    function getMarketName() private view returns(string memory) {
        IMarket market = IMarket(msg.sender);
        bytes32 questionsHash = market.questionsHash();
        bool isRegistered = ICurate(curatedMarkets).isRegistered(questionsHash);

        if (isRegistered) {
            return ICurate(curatedMarkets).getTitle(questionsHash);
        } else {
            return market.name();
        }
    }

    function generateName(
        uint256 tokenId,
        string memory marketName
    ) private pure returns(string memory) {
        return
            string(
                abi.encodePacked(
                    'Bet ',
                    tokenId.toString(),
                    ' - ',
                    marketName
                )
            );
    }

    function generateFee() private view returns (string memory) {
        (uint16 fee,,,,) = IMarket(msg.sender).marketInfo();
        uint256 units = fee/100;
        uint256 decimals = uint256(fee) - 100 * units;
        if (decimals == 0) {
            return string(
                abi.encodePacked(
                    units.toString(),
                    '%'
                )
            );
        } else {
            return string(
                abi.encodePacked(
                    units.toString(),
                    '.',
                    decimals.toString(),
                    '%'
                )
            );
        }
    }

    function addressToString(address addr) internal pure returns (string memory) {
        return (uint256(uint160(addr))).toHexString(20);
    }

    function addThousandSeparator(string memory number) internal pure returns (string memory) {
        bytes memory numberBytes = bytes(number);
        uint256 totalSeparators = (numberBytes.length - 1) / 3;
        bytes memory buffer = new bytes(numberBytes.length + totalSeparators);
        uint256 nextDigit = 0;
        for (uint256 i = 0; i < buffer.length; i++) {
            if ((buffer.length - i) % 4 == 0 && i != 0 && i != buffer.length - 1) {
                buffer[i] = ",";
            } else {
                buffer[i] = numberBytes[nextDigit++];
            }   
        }
        return string(buffer);
    }

    function generateSVGImage(
        uint256 tokenId,
        string memory marketName,
        string memory marketFee
    ) internal view returns (string memory svg) {
        string memory jackpot = addThousandSeparator((msg.sender.balance / 10 ** 18).toString());

        string memory status = getStatus();

        IMarket market = IMarket(msg.sender);
        bytes32 tokenHash = market.tokenIDtoTokenHash(tokenId);
        string memory copies = market.bets(tokenHash).toString();

        return
            string(
                abi.encodePacked(
                    generateSVGDefs(),
                    generateLogo(),
                    generateSVGCardMantle(jackpot, marketFee, status, copies),
                    generateSVGFootText(marketName),
                    generateCurationMark(),
                    generatePredictionsFingerprint(tokenHash),
                    generateAd(tokenId),
                    '</svg>'
                )
            );
    }

    function getStatus() internal view returns(string memory status) {
        IMarket market = IMarket(msg.sender);
        uint256 resultSubmissionPeriodStart = market.resultSubmissionPeriodStart();
        uint256 closingTime = market.closingTime();
        uint256 submissionTimeout = market.submissionTimeout();
        if (block.timestamp < closingTime) {
            status = "open to bets";
        } else if (
            block.timestamp > closingTime &&
            resultSubmissionPeriodStart == 0) {
            status = "waiting for results";
        } else if (
            resultSubmissionPeriodStart > 0 &&
            block.timestamp < resultSubmissionPeriodStart + submissionTimeout) {
            status = "building ranking";
        } else if (
            resultSubmissionPeriodStart > 0 &&
            block.timestamp > resultSubmissionPeriodStart + submissionTimeout) {
            status = "claim period";
        }
    }

    function tokenToColorHex(uint256 token, uint256 offset) internal pure returns (string memory str) {
        return string((token >> offset).toHexStringNoPrefix(3));
    }

    function sliceTokenHex(uint256 token, uint256 offset) internal pure returns (uint256) {
        return uint256(uint8(token >> offset));
    }

    function generateSVGDefs() private view returns (string memory svg) {
        uint256 uintAddress = uint256(uint160(msg.sender));
        uint256 radius = 20 + sliceTokenHex(uintAddress, 32) & 0x7f;
        uint256 std = sliceTokenHex(uintAddress, 40) & 0x3f;
        if (std > radius) std = std/2;
        svg = string(
            abi.encodePacked(
                '<svg width="290" height="500" viewBox="0 0 290 500" xmlns="http://www.w3.org/2000/svg"',
                " xmlns:xlink='http://www.w3.org/1999/xlink'>",
                '<defs>',
                '<filter id="f1"><feImage result="p1" xlink:href="data:image/svg+xml;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            "<svg width='290' height='500' viewBox='0 0 290 500' xmlns='http://www.w3.org/2000/svg'>",
                            "<circle cx='17' cy='276' r='",
                            radius.toString(),
                            "px' fill='#",
                            tokenToColorHex(uintAddress, 0),
                            "'/></svg>"
                        )
                    )
                ),
                '"/><feGaussianBlur ',
                'in="p1" stdDeviation="',
                std.toString(),
                '" /></filter> ',
                '<filter id="f2"> ',
                '<feTurbulence type="turbulence" baseFrequency="0.6" numOctaves="2" result="turbulence"/>'
                '<feDisplacementMap in2="turbulence" in="SourceGraphic" scale="5" xChannelSelector="R" yChannelSelector="G"/>'
                '</filter>'
                '<clipPath id="corners"><rect width="290" height="500" rx="42" ry="42" /></clipPath>',
                '<clipPath id="ad-margin"><rect width="290" height="430" /></clipPath>',
                '<filter id="top-region-blur"><feGaussianBlur in="SourceGraphic" stdDeviation="24" /></filter>',
                '</defs>',
                '<g clip-path="url(#corners)">',
                '<rect x="0" y="0" width="290" height="500" rx="42" ry="42" fill="rgba(0,0,0,1)" stroke="rgba(255,255,255,0.2)" />',
                '<rect style="filter: url(#f1)" x="0px" y="0px" width="290px" height="500px" />',
                ' <g style="filter:url(#top-region-blur); transform:scale(1.5); transform-origin:center top;">',
                '<rect fill="none" x="0px" y="0px" width="290px" height="500px" />',
                '<ellipse cx="50%" cy="0px" rx="180px" ry="120px" fill="#000" opacity="0.85" /></g>',
                '</g>'
            )
        );
    }

    function generateSVGFootText(
        string memory marketName
    ) private view returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                '<text y="464px" x="18px" fill="white" font-family="\'Courier New\', monospace" font-size="10px">',
                marketName,
                '</text>',
                '<text y="479px" x="18px" fill="white" font-family="\'Courier New\', monospace" font-size="10px">',
                addressToString(msg.sender),
                '</text>'
            )
        );
    }

    function generateLogo() private pure returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                '<g><svg width="83" height="29" x="32px" y="15px" fill="none">',
                '<path d="M 82.176 15.015 L 71.033 15.015 L 71.033 12.803 L 82.093 12.803 L 80.96 13.578 Q 80.932 12.195 80.407 11.103 Q 79.881 10.011 78.914 9.375 A 4.185 4.185 0 0 0 76.563 8.739 Q 74.987 8.739 73.868 9.43 Q 72.748 10.121 72.167 11.324 Q 71.586 12.527 71.586 14.048 A 5.291 5.291 0 0 0 72.278 16.757 Q 72.969 17.946 74.186 18.637 A 5.553 5.553 0 0 0 76.978 19.329 Q 77.835 19.329 78.734 19.011 A 5.454 5.454 0 0 0 80.186 18.278 Q 80.6 17.974 81.084 17.96 A 1.465 1.465 0 0 1 81.126 17.959 A 1.203 1.203 0 0 1 81.928 18.25 A 1.31 1.31 0 0 1 82.425 19.163 A 0.989 0.989 0 0 1 82.427 19.218 A 0.991 0.991 0 0 1 81.983 20.02 Q 81.043 20.767 79.646 21.237 A 8.36 8.36 0 0 1 76.978 21.707 Q 74.683 21.707 72.9 20.725 Q 71.116 19.743 70.107 18.015 A 7.722 7.722 0 0 1 69.098 14.048 Q 69.098 11.78 70.052 10.052 A 6.975 6.975 0 0 1 72.692 7.342 Q 74.379 6.361 76.563 6.361 Q 78.72 6.361 80.269 7.315 Q 81.817 8.269 82.633 9.942 Q 83.448 11.614 83.448 13.799 A 1.157 1.157 0 0 1 83.089 14.67 Q 82.729 15.015 82.176 15.015 Z M 62.075 8.877 L 62.075 1.412 Q 62.075 0.776 62.476 0.388 A 1.394 1.394 0 0 1 63.485 0.001 Q 64.121 0.001 64.508 0.388 A 1.383 1.383 0 0 1 64.895 1.412 L 64.895 14.02 A 7.688 7.688 0 0 1 63.886 17.946 A 7.498 7.498 0 0 1 61.162 20.697 Q 59.448 21.707 57.291 21.707 A 7.56 7.56 0 0 1 53.407 20.697 Q 51.678 19.688 50.669 17.946 Q 49.66 16.204 49.66 14.02 A 8.15 8.15 0 0 1 50.586 10.107 A 7.172 7.172 0 0 1 53.116 7.37 Q 54.72 6.361 56.738 6.361 Q 58.37 6.361 59.752 7.038 Q 61.135 7.716 62.075 8.877 Z M 0.001 26.656 L 0.001 14.048 Q 0.028 11.863 1.024 10.121 Q 2.019 8.379 3.733 7.37 Q 5.448 6.361 7.604 6.361 A 7.539 7.539 0 0 1 11.503 7.37 Q 13.217 8.379 14.227 10.121 Q 15.236 11.863 15.236 14.048 A 8.15 8.15 0 0 1 14.309 17.96 A 7.172 7.172 0 0 1 11.78 20.697 Q 10.176 21.707 8.157 21.707 Q 6.526 21.707 5.157 21.029 Q 3.789 20.352 2.821 19.19 L 2.821 26.656 Q 2.821 27.264 2.434 27.665 Q 2.047 28.066 1.411 28.066 Q 0.802 28.066 0.402 27.665 Q 0.001 27.264 0.001 26.656 Z M 38.628 21.707 Q 36.388 21.707 34.674 20.725 Q 32.959 19.743 31.978 18.015 Q 30.996 16.287 30.996 14.048 Q 30.996 11.78 31.978 10.052 A 7.115 7.115 0 0 1 34.674 7.342 Q 36.388 6.361 38.628 6.361 Q 40.84 6.361 42.554 7.342 A 7.115 7.115 0 0 1 45.25 10.052 Q 46.231 11.78 46.231 14.048 Q 46.231 16.287 45.264 18.015 A 7.016 7.016 0 0 1 42.582 20.725 A 7.816 7.816 0 0 1 38.628 21.707 Z M 19.439 20.214 L 19.439 7.854 A 1.384 1.384 0 0 1 19.798 6.831 A 1.384 1.384 0 0 1 20.821 6.471 A 1.408 1.408 0 0 1 21.858 6.817 A 1.408 1.408 0 0 1 22.204 7.854 L 22.204 20.214 A 1.417 1.417 0 0 1 21.858 21.237 A 1.375 1.375 0 0 1 20.821 21.596 A 1.417 1.417 0 0 1 19.798 21.25 Q 19.439 20.905 19.439 20.214 Z M 38.628 19.218 Q 40.065 19.218 41.171 18.555 Q 42.277 17.891 42.9 16.73 Q 43.522 15.568 43.522 14.048 Q 43.522 12.527 42.9 11.352 A 4.617 4.617 0 0 0 41.171 9.513 Q 40.065 8.849 38.628 8.849 Q 37.19 8.849 36.084 9.513 Q 34.978 10.177 34.342 11.352 Q 33.706 12.527 33.706 14.048 A 5.494 5.494 0 0 0 34.342 16.73 A 4.74 4.74 0 0 0 36.084 18.555 Q 37.19 19.218 38.628 19.218 Z M 57.291 19.218 A 4.72 4.72 0 0 0 59.808 18.541 Q 60.914 17.863 61.55 16.674 Q 62.185 15.485 62.185 14.02 Q 62.185 12.527 61.55 11.366 Q 60.914 10.204 59.808 9.527 Q 58.702 8.849 57.291 8.849 Q 55.909 8.849 54.789 9.527 A 4.914 4.914 0 0 0 53.019 11.366 Q 52.37 12.527 52.37 14.02 Q 52.37 15.485 53.019 16.674 A 4.858 4.858 0 0 0 54.789 18.541 Q 55.909 19.218 57.291 19.218 Z M 7.604 19.218 A 4.72 4.72 0 0 0 10.121 18.541 Q 11.227 17.863 11.876 16.688 Q 12.526 15.513 12.526 14.048 Q 12.526 12.554 11.876 11.379 Q 11.227 10.204 10.121 9.527 Q 9.015 8.849 7.604 8.849 Q 6.222 8.849 5.102 9.527 Q 3.982 10.204 3.346 11.379 Q 2.71 12.554 2.71 14.048 A 5.458 5.458 0 0 0 3.346 16.688 Q 3.982 17.863 5.102 18.541 Q 6.222 19.218 7.604 19.218 Z M 22.204 12.14 L 20.793 12.14 A 5.518 5.518 0 0 1 21.609 9.167 A 5.979 5.979 0 0 1 23.807 7.08 Q 25.19 6.306 26.849 6.306 Q 28.508 6.306 29.323 6.845 A 1.225 1.225 0 0 1 29.983 7.852 A 1.109 1.109 0 0 1 29.946 8.13 A 1.062 1.062 0 0 1 29.628 8.725 A 1.098 1.098 0 0 1 29.088 8.988 Q 28.784 9.043 28.425 8.96 A 9.117 9.117 0 0 0 26.613 8.765 A 6.477 6.477 0 0 0 25.245 8.905 Q 23.835 9.209 23.019 10.038 Q 22.204 10.868 22.204 12.14 Z" fill="#4267B3"/>',
                '</svg></g>'
            )
        );
    }

    function generateSVGCardMantle(
        string memory jackpot,
        string memory fee,
        string memory status,
        string memory copies
    ) private pure returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                '<rect fill="none" x="0px" y="0px" width="290px" height="200px" /> ',
                '<text y="65px" x="32px" fill="white" font-family="\'Courier New\', monospace" font-size="14px">',
                'Jackpot: ',
                jackpot,
                ' xDAI</text>',
                '<text y="83px" x="32px" fill="white" font-family="\'Courier New\', monospace" font-size="10px">',
                'Management fee: ',
                fee,
                '</text>',
                '<text y="98px" x="32px" fill="white" font-family="\'Courier New\', monospace" font-size="10px">',
                'Status: ',
                status,
                '</text>',
                '<text y="113px" x="32px" fill="white" font-family="\'Courier New\', monospace" font-size="10px">',
                'Copies: ',
                copies,
                '</text>'
            )
        );
    }

    function generateCurationMark() private view returns (string memory svg) {
        IMarket market = IMarket(msg.sender);
        bytes32 questionsHash = market.questionsHash();
        bool isRegistered = ICurate(curatedMarkets).isRegistered(questionsHash);
        uint256 startTime = ICurate(curatedMarkets).getTimestamp(questionsHash);
        
        if (!isRegistered || market.closingTime() > startTime) return '';

        svg = string(
            abi.encodePacked(
                '<g style="transform:translate(243px, 11px)">',
                '<rect width="36px" height="36px" rx="8px" ry="8px" fill="none" stroke="rgba(255,255,255,0.2)" />',
                '<svg x="5px" y="6px" fill="#4CAF50"><path d="M9,16.2L4.8,12l-1.4,1.4L9,19L21,7l-1.4-1.4L9,16.2z"/></svg>',
                '<svg x="8px" y="6px" fill="#4CAF50"><path d="M9,16.2L4.8,12l-1.4,1.4L9,19L21,7l-1.4-1.4L9,16.2z"/></svg>',
                '</g>'
            )
        );
    }

    function generatePredictionsFingerprint(
        bytes32 predictionsHash
    ) private pure returns (string memory svg) {
        for (uint256 i = 0; i < 8; i++) {
            uint256 y = 82 + 30 * ( i % 4 );
            uint256 x = 0;
            if (i >= 4) {
                x = 30;
            }
            if (i % 4 >= 2) {
                y += 12;
            }
            string memory color = tokenToColorHex(uint256(predictionsHash), i * 4 * 8); // 4 bytes * 8 bits
            uint256 rx = sliceTokenHex(uint256(predictionsHash), (i * 4 + 3) * 8) & 0x0f;
            uint256 ry = (sliceTokenHex(uint256(predictionsHash), (i * 4 + 3) * 8) & 0xf0) >> 4;

            svg = string(
                abi.encodePacked(
                    svg,
                    '<rect style="filter: url(#f2)" width="20px" height="20px" y="',
                    y.toString(),
                    'px" x="',
                    x.toString(),
                    'px" rx="',
                    rx.toString(),
                    'px" ry="',
                    ry.toString(),
                    'px" fill="#',
                    color,
                    '" />'
                )
            );
        }
        svg = string(
            abi.encodePacked(
                '<g style="transform:translate(220px, 142px)">',
                svg,
                '</g>'
            )
        );
    }

    function generateAd(uint256 tokenId) private view returns (string memory) {
        string memory adSvg = IFirstPriceAuction(ads).getAd(msg.sender, tokenId);
        if (bytes(adSvg).length == 0) {
            return '';
        } else {
            adSvg = string(
                abi.encodePacked(
                    '<image xlink:href="data:image/svg+xml;base64,',
                    adSvg,
                    '" />'
                )
            );
        }

        string memory adLink = IFirstPriceAuction(ads).getRef(msg.sender, tokenId);
        if (bytes(adLink).length > 0) {
            adSvg = string(
            abi.encodePacked(
                '<a href="',
                adLink,
                '"  target="_blank">',
                adSvg,
                '</a>'
            )
        );
        }

        return string(
            abi.encodePacked(
                '<g clip-path="url(#corners)">',
                '<rect x="0" y="0" width="290" height="500" rx="42" ry="42" fill="rgba(0,0,0)" stroke="rgba(14,14,14)" />',
                '<g clip-path="url(#ad-margin)" style="transform:translate(0px, 35px)" >',
                adSvg,
                '</g><text y="25px" x="50px" fill="#D0D0D0A8" font-family="\'Courier New\', monospace" font-size="15px">Ad curated by Kleros</text>',
                '<animate dur="1s" attributeName="opacity" from="1" to="0" begin="2s" repeatCount="1" fill="freeze" /></g>'
            )
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
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
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IMarket is IERC721 {
    struct Result {
        uint256 tokenID;
        uint248 points;
        bool claimed;
    }

    function marketInfo()
        external
        view
        returns (
            uint16,
            uint16,
            address payable,
            string memory,
            string memory
        );

    function name() external view returns (string memory);

    function betNFTDescriptor() external view returns (address);

    function questionsHash() external view returns (bytes32);

    function resultSubmissionPeriodStart() external view returns (uint256);

    function closingTime() external view returns (uint256);

    function submissionTimeout() external view returns (uint256);

    function nextTokenID() external view returns (uint256);

    function price() external view returns (uint256);

    function totalPrize() external view returns (uint256);

    function getPrizes() external view returns (uint256[] memory);

    function prizeWeights(uint256 index) external view returns (uint16);

    function totalAttributions() external view returns (uint256);

    function attributionBalance(address _attribution) external view returns (uint256);

    function managementReward() external view returns (uint256);

    function tokenIDtoTokenHash(uint256 _tokenID) external view returns (bytes32);

    function placeBet(address _attribution, bytes32[] calldata _results)
        external
        payable
        returns (uint256);

    function bets(bytes32 _tokenHash) external view returns (uint256);

    function ranking(uint256 index) external view returns (Result memory);

    function fundMarket(string calldata _message) external payable;

    function numberOfQuestions() external view returns (uint256);

    function questionIDs(uint256 index) external view returns (bytes32);

    function realitio() external view returns (address);

    function ownerOf() external view returns (address);

    function getPredictions(uint256 _tokenID) external view returns (bytes32[] memory);

    function getScore(uint256 _tokenID) external view returns (uint256 totalPoints);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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