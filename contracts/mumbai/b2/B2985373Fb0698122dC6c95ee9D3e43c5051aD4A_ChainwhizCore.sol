// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;
pragma experimental ABIEncoderV2;

// import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "hardhat/console.sol";
import "./IWETHGateway.sol";
import "./ILendingPoolAddressesProvider.sol";
import "./IERC20.sol";
import "./IAaveIncentivesController.sol";

contract ChainwhizCore is ReentrancyGuard {
    //************************   State Variables   ************************ */
    address public ChainwhizAdmin;
    uint256 public MIN_REWARD_AMOUNT = 5 ether;
    uint256 public MAX_REWARD_AMOUNT = 40000 ether;
    uint256 public MIN_STAKING_AMOUNT = 5 ether;
    uint256 public MAX_STAKE_AMOUNT = 40 ether;
    uint256 public MIN_COMMUNITY_REWARD_AMOUNT = 5 ether;
    uint256 public MAX_COMMUNITY_REWARD_AMOUNT = 40000 ether;
    bool public isContractActive = true;
    address public ethGateWayAddress;
    address public lendingPoolProviderAddress;
    address public aaveIncentiveAddress;
    uint256 public ChainwhizTreasary;
    address public aMaticAddress;
    address[] public rewardAddress;

    //************************   Enums   ************************ */
    enum QuestionStatus {
        Solve,
        Vote,
        Escrow,
        Over
    }

    enum EscrowStatus {
        Initiate,
        Complete
    }

    //************************   Structures   ************************ */
    struct Bounty {
        address publisher;
        uint256 solverRewardAmount;
        uint256 communityVoterRewardAmount;
        uint256 startSolveTime;
        uint256 endSolveTime;
        uint256 startVoteTime;
        uint256 endVoteTime;
        bool isCommunityVote;
        address[] voterAddress;
        string[] solutionLinks;
        QuestionStatus questionStatus;
        bool isUnstakeSet;
        Solution choosenSolution;
        string tokenName;
    }

    struct Solution {
        address solver;
        string solutionLink;
        uint256 timeOfPosting;
        address[] voterAddress;
        uint256 totalStakedAmount;
        EscrowStatus escrowStatus;
    }

    //TODO: Add voter githubId or emit votergithubId in event
    struct Vote {
        address voter;
        uint256 amountStaked;
        uint256 returnRewardAmount;
        uint256 returnBaseAmount;
        string rewardToken;
        bool isUnstake;
    }

    //************************   Mappings   ************************ */
    //Mapping for Publisher
    //Overall mapping from publisher to issue detail (publisher address -> issue link -> issue detail)
    mapping(address => mapping(string => Bounty)) public bountyDetail;

    //Mapping for Voter
    //mapping solutionLink to voter address which in turn is mapped to vote details
    mapping(string => mapping(address => Vote)) public voteDetails;

    //Mapping for Solver
    //mapping issue link to solver githubid which is turn is mapped to the solution details
    mapping(string => mapping(string =>  Solution)) public solutionDetails;
    //mapping to store token name linked to their token address
    mapping(string => address) public tokenDetails;
    //************************   Events   ************************ */
    event DeactivateContract();
    event ActivateContract();
    event ETHGateWayAddressChanged(address newAddress);
    event LendingPoolProviderAddressChanged(address newAddress);
    event BountyPosted(
        address publisher,
        string bountyUrl,
        string bountyTitle,
        string[] tags
    );

    event SolutionSubmitted(
        string solutionLink,
        address publisherAddress,
        string issueGithubUrl
    );

    event VoteStaked(
        string solutionLink,
        address voter,
        uint256 amount
    );

    event UnstakeAmountSet(address publisher, string issueLink);

    event VoterUnstaked(
        string solutionLink,
        address voter
    );

    event EscorwInitiated(
        address publisher,
        address solver,
        string issueLink,
        string solutionLink
    );

    event EscrowTransferOwnership(
        address publisher,
        address solver,
        string issueLink,
        string solutionLink
    );

    //************************   Modifiers   ************************ */
    modifier onlyChainwhizAdmin() {
        require(msg.sender == ChainwhizAdmin, "ONLY_ADMIN");
        _;
    }

    modifier onlyActiveContract() {
        require(isContractActive == true, "DEACTIVATE_ERROR");
        _;
    }

    modifier onlyDeactiveContract() {
        require(isContractActive == false, "ACTIVE_ERROR");
        _;
    }

    //************************   Functions   ************************ */
    fallback() external payable {}

    receive() external payable {}

    /// @notice Constructor
    /// @dev constructor to initialise the admin address
    /// @param _ChainwhizAdmin the admin address needs to be passed
    constructor(address _ChainwhizAdmin) ReentrancyGuard() {
        ChainwhizAdmin = _ChainwhizAdmin;
        tokenDetails["MATIC"] = address(0);
    }

    /// @notice Used to set the new admin
    /// @dev The modifier onlyChainwhizAdmin is used so that the current admin can change the address
    /// @param _newChainwhizAdmin takes in the address of new admin

    function setChainwhizAdmin(address _newChainwhizAdmin)
        external
        onlyChainwhizAdmin
        onlyActiveContract
    {
        ChainwhizAdmin = _newChainwhizAdmin;
    }

    /// @notice Used to set the minimum reward amount
    /// @dev The modifier onlyChainwhizAdmin is used so that the current admin can change the minimum reward
    /// @param _newRewardAmount as input from admin

    function setMinimumRewardAmount(uint256 _newRewardAmount)
        external
        onlyChainwhizAdmin
        onlyActiveContract
    {
        MIN_REWARD_AMOUNT = _newRewardAmount;
    }

    /// @notice Used to set the minimum stake amount
    /// @dev The modifier onlyChainwhizAdmin is used so that the current admin can change the minimum stake
    /// @param _newStakeAmount as input from admin

    function setMinimumStakeAmount(uint256 _newStakeAmount)
        external
        onlyChainwhizAdmin
        onlyActiveContract
    {
        MIN_STAKING_AMOUNT = _newStakeAmount;
    }

    /// @notice Used to set the minimum stake amount
    /// @dev The modifier onlyChainwhizAdmin is used so that the current admin can change the minimum stake
    /// @param _newCommunityRewardAmount as input from admin

    function setMinimumCommunityRewardAmount(uint256 _newCommunityRewardAmount)
        external
        onlyChainwhizAdmin
        onlyActiveContract
    {
        MIN_COMMUNITY_REWARD_AMOUNT = _newCommunityRewardAmount;
    }

    /// @notice Used to deactive contract in case of security issue
    /// @dev Modifiers onlyChainwhizAdmin onlyActiveContract are used

    function deactivateContract()
        external
        onlyChainwhizAdmin
        onlyActiveContract
    {
        isContractActive = false;
        emit DeactivateContract();
    }

    /// @notice Used to activate contract
    /// @dev Modifiers onlyChainwhizAdmin onlyDeactiveContract are used

    function activateContract()
        external
        onlyChainwhizAdmin
        onlyDeactiveContract
    {
        isContractActive = true;
        emit ActivateContract();
    }

    /// @notice Set the address of ETHGateway Contract of Aave
    function setETHGatewayAddress(address _ethGateWayAddress)
        external
        onlyChainwhizAdmin
        onlyActiveContract
    {
        ethGateWayAddress = _ethGateWayAddress;
        emit ETHGateWayAddressChanged(_ethGateWayAddress);
    }

    /// @notice Set the address of LendingPoolAddressesProvider Contract of Aave
    function setLendingPoolProviderAddress(address _lendingPoolProviderAddress)
        external
        onlyChainwhizAdmin
        onlyActiveContract
    {
        lendingPoolProviderAddress = _lendingPoolProviderAddress;
        emit LendingPoolProviderAddressChanged(_lendingPoolProviderAddress);
    }

    /// @notice Set the address of AaveIncentiveAddress Contract of Aave
    function setAaveIncentiveAddress(address _aaveIncentiveAddress)
        external
        onlyChainwhizAdmin
        onlyActiveContract
    {
        aaveIncentiveAddress = _aaveIncentiveAddress;
    }

    /// @notice Set the address of Reward Contract of Aave
    function setReawrdArrayAddress(address _rewardAddress)
        external
        onlyChainwhizAdmin
        onlyActiveContract
    {
        rewardAddress.push(_rewardAddress);
    }

    /// @notice Set the address of aMatic Address of Aave
    function setaMaticAddress(address _aMaticAddress)
        external
        onlyChainwhizAdmin
        onlyActiveContract
    {
        aMaticAddress = _aMaticAddress;
    }

    /// @notice Set the token details
    function setTokenDetails(string memory tokenName, address tokenAddress)
        external
        onlyChainwhizAdmin
        onlyActiveContract
    {
        tokenDetails[tokenName] = tokenAddress;
    }

    /// @notice Post a bounty
    /// @dev The require check are there for various validations
    /// @param _githubUrl the github url
    /// @param _solverRewardAmount the bounty given to solver
    /// @param _communityVoterRewardAmount reward to voter for staking
    /// @param _endSolverTime Time at which solving will be over
    /// @param _startVoteTime Time at which voting will start
    /// @param _endVoteTime Time at which voting will over
    /// @param _tokenName Name of the token
    /// @return true if posted successfully or false
    function postBounty(
        string memory _issueTitle,
        string[] memory _tags,
        string memory _githubUrl,
        uint256 _solverRewardAmount,
        uint256 _communityVoterRewardAmount,
        uint256 _endSolverTime,
        uint256 _startVoteTime,
        uint256 _endVoteTime,
        string memory _tokenName
    ) public payable onlyActiveContract returns (bool) {

        //Check for the token to be either matic or valid token listed
        // store the value that would be used to check in rest of the function
        bool isMatic = tokenDetails[_tokenName] == address(0);
        require(
            isMatic || tokenDetails[_tokenName] != address(0),
            "INVALID TOKEN"
        );
        // Reward should be greater than min reward
        require(
            _solverRewardAmount >= MIN_REWARD_AMOUNT &&
                _solverRewardAmount <= MAX_REWARD_AMOUNT,
            "POST_ISSUE_B"
        );
        // Check user has enough balance based on wheather token
        if (isMatic) {
            require(
                msg.value >=
                    (_solverRewardAmount + _communityVoterRewardAmount),
                "POST_ISSUE_C"
            );
        } else {
            require(
                IERC20(tokenDetails[_tokenName]).balanceOf(msg.sender) >=
                    (_solverRewardAmount + _communityVoterRewardAmount),
                "POST_ISSUE_C_TOKEN"
            );
        }

        // Check if the sent fund and the total amount set for rewards matches or not
        if (isMatic) {
            require(
                msg.value >=
                    (_solverRewardAmount + _communityVoterRewardAmount),
                "POST_ISSUE_D"
            );
        } else {
            require(
                IERC20(tokenDetails[_tokenName]).allowance(
                    msg.sender,
                    address(this)
                ) >= (_solverRewardAmount + _communityVoterRewardAmount),
                "POST_ISSUE_D_TOKEN"
            );
        }
        if (_communityVoterRewardAmount != 0) {
            require(
                _communityVoterRewardAmount >= MIN_COMMUNITY_REWARD_AMOUNT &&
                    _communityVoterRewardAmount <= MAX_COMMUNITY_REWARD_AMOUNT,
                "POST_ISSUE_E"
            );
        }

        emit BountyPosted(
            msg.sender,
            _githubUrl,
            _issueTitle,
            _tags
        );
        bool _isCommunityReaward = (_communityVoterRewardAmount >=
            MIN_COMMUNITY_REWARD_AMOUNT &&
            _communityVoterRewardAmount <= MAX_COMMUNITY_REWARD_AMOUNT);

        // Store issue related info
        _postBounty(
            msg.sender,
            _githubUrl,
            _solverRewardAmount,
            _communityVoterRewardAmount,
            _endSolverTime,
            _startVoteTime,
            _endVoteTime,
            _isCommunityReaward,
            _tokenName,
            isMatic
        );
        return true;
    }

    /// @notice Post a bounty
    /// @dev - Create the struct and store the details.
    ///      - Trasnfer the token to the contract

    function _postBounty(
        address _publisher,
        string memory _githubUrl,
        uint256 _solverRewardAmount,
        uint256 _communityVoterRewardAmount,
        uint256 _endSolverTime,
        uint256 _startVoteTime,
        uint256 _endVoteTime,
        bool _isCommunityReaward,
        string memory _tokenName,
        bool _isMatic
    ) private onlyActiveContract nonReentrant {
        Bounty storage bounty = bountyDetail[msg.sender][_githubUrl];
        bounty.publisher = _publisher;
        bounty.solverRewardAmount = _solverRewardAmount;
        bounty.communityVoterRewardAmount = _communityVoterRewardAmount;
        bounty.startSolveTime = block.timestamp;
        bounty.endSolveTime = _endSolverTime;
        bounty.startVoteTime = _startVoteTime;
        bounty.endVoteTime = _endVoteTime;
        bounty.isCommunityVote = _isCommunityReaward;
        bounty.questionStatus = QuestionStatus.Solve;
        bounty.tokenName = _tokenName;
        bounty.questionStatus = QuestionStatus.Solve;
        // Based on token type call the transfer function
        if (_isMatic) {
            payable(address(this)).transfer(msg.value);
        } else {
            IERC20(tokenDetails[_tokenName]).transferFrom(
                msg.sender,
                address(this),
                (_communityVoterRewardAmount + _solverRewardAmount)
            );
        }

        //****************************  Logs for testing only  ****************************************** */
        // console.log((issueDetail[msg.sender][_githubUrl]).solverRewardAmount);
        // console.log((issueDetail[msg.sender][_githubUrl]).communityVoterRewardAmount);
        // console.log((issueDetail[msg.sender][_githubUrl]).startSolveTime);
        // console.log("Contract Balance");
        // console.log((address(this)).balance);
    }

    /// @notice To store the solution link
    /// @dev Need issue url and publisher address to fetch issue related information
    /// @param _solutionLink the solution link
    /// @param _publisherAddress address of publisher
    /// @param _bountyUrl github issue url
    /// @return bool type true for success or failure
    function postSolution(
        string memory _solutionLink,
        string memory _bountyUrl,
        address _publisherAddress
    ) public onlyActiveContract returns (bool) {
        // Work around to get timestamp: 1635532684
        // console.log(block.timestamp);
        // To prevent publisher from solving
        require(
           _publisherAddress != msg.sender
            ,
            "POST_SOLUTION_A"
        );
        // Fetch issue related details. It's marked as memory as it saves gas fees
        Bounty storage bounty = bountyDetail[_publisherAddress][
            _bountyUrl
        ];
        //Check if the bounty exists or not
        require(bounty.solverRewardAmount != 0, "POST_SOLUTION_C");
        // Check if the solver has posted within the solving time
        require(
            bounty.startSolveTime <= block.timestamp &&
                bounty.endSolveTime >= block.timestamp &&
                bounty.questionStatus == QuestionStatus.Solve,
            "POST_SOLUTION_D"
        );
        // Check if solver is posting multiple solutions
        require(
            solutionDetails[_bountyUrl][_solutionLink].solver != msg.sender,
            "POST_SOLUTION_E"
        );
        //check if the submitted solution exists or not
        _checkForDuplicateSolution(bounty.solutionLinks, _solutionLink);

        Solution storage solution = solutionDetails[_bountyUrl][_solutionLink];
        solution.solver = msg.sender;
        solution.solutionLink = _solutionLink;
        solution.timeOfPosting = block.timestamp;
        bounty.solutionLinks.push(_solutionLink);
        emit SolutionSubmitted(
            _solutionLink,
            _publisherAddress,
            _bountyUrl

        );
        return true;
    }

    function _checkForDuplicateSolution(
        string[] memory solutionArray,
        string memory solutionLink
    ) private pure {
        uint256 i = 0;
        for (i; i < solutionArray.length; i++) {
            require(
                keccak256(abi.encodePacked(solutionArray[i])) !=
                    keccak256(abi.encodePacked(solutionLink)),
                "POST_SOLUTION_F"
            );
        }
    }
    // Depricated
    // /// @notice Start the voting phase
    // /// @param _issueGithubUrl a parameter just like in doxygen (must be followed by parameter name)
    // /// @param _publisherGithubId a parameter just like in doxygen (must be followed by parameter name)
    // /// @param _publisherAddress a parameter just like in doxygen (must be followed by parameter name)
    // function startVotingStage(
    //     string memory _issueGithubUrl,
    //     string memory _publisherGithubId,
    //     address _publisherAddress
    // ) public onlyActiveContract {
    //     //work around to get the timestamp for testing
    //     // console.log(block.timestamp);
    //     //get issue detail
    //     Question storage questionDetail = issueDetail[_publisherAddress][
    //         _issueGithubUrl
    //     ];
    //     //Only with community vote enabled can be moves to voting phase
    //     require(
    //         questionDetail.isCommunityVote &&
    //             questionDetail.startVoteTime <= block.timestamp &&
    //             questionDetail.endVoteTime >= block.timestamp,
    //         "START_VOTE_A"
    //     );
    //     //Only chainwhiz admin or issue publihser can initiate it
    //     require(
    //         ChainwhizAdmin == msg.sender ||
    //             (publisher[_publisherGithubId] == msg.sender &&
    //                 msg.sender == _publisherAddress),
    //         "START_VOTE_B"
    //     );

    //     questionDetail.questionStatus = QuestionStatus.Vote;
    // }

    /// @notice Vote on the solution by staking Matic
    /// @dev Explain to a developer any extra details
    /// @param _bountyUrl The issue github url
    /// @param _publisherAddress Publisher address
    /// @param _solutionLink the solution link to be voted on
    function stakeVote(
        string memory _bountyUrl,
        address _publisherAddress,
        string memory _solutionLink
    ) external payable onlyActiveContract {
         //To check issue exists
        Bounty storage bounty = bountyDetail[_publisherAddress][
            _bountyUrl
        ];
        require(
                bounty
                    .solverRewardAmount !=
                0 &&
                bounty.isCommunityVote,
            "STAKE_VOTE_B"
        );
        //Check that the solution exists
        Solution storage solution = solutionDetails[_bountyUrl][_solutionLink];
        require(
                solution.solver != address(0) &&
                keccak256(abi.encodePacked(solution.solutionLink)) !=
                keccak256(abi.encodePacked("")) &&
                keccak256(abi.encodePacked(solution.solutionLink)) ==
                keccak256(abi.encodePacked(_solutionLink)),
            "STAKE_VOTE_C"
        );
        //Check if the staking is done within the time
        require(
            bounty.isCommunityVote &&
               bounty.startVoteTime <=
                block.timestamp &&
                bounty.endVoteTime >=
                block.timestamp,
            "STAKE_VOTE_D"
        );
        // To check github id of solver and publisher doesnt match with the voter
        require(
                solution.solver != msg.sender &&
                bounty.publisher != msg.sender,
            "STAKE_VOTE_E"
        );
        // To check is stake amount is within the limit
        require(
            msg.value >= MIN_STAKING_AMOUNT && msg.value <= MAX_STAKE_AMOUNT,
            "STAKE_VOTE_F"
        );
        //Voter shouldnt vote multiple times
        require(
            voteDetails[_solutionLink][msg.sender].voter == address(0),
            "STAKE_VOTE_G"
        );
        //If all conditions are alright and someone voted for first time, change the status to Vote
        if (
            bounty.questionStatus ==
            QuestionStatus.Solve
        )
            bounty
                .questionStatus = QuestionStatus.Vote;
        //Check if voter has alreay voted in any solution
        bool voterVoted = _checkAlreadyVoted(
            bounty.voterAddress,
            msg.sender
        );
        require(!voterVoted, "STAKE_VOTE_H");
        //store vote detail
        _storeVoteDetail(
            _solutionLink,
            msg.sender,
            msg.value,
            bounty.tokenName
        );

        bounty.voterAddress.push(msg.sender);
        solution.voterAddress.push(msg.sender);
        // lend to aave protocol
        _lendToAave(msg.value);
        //emit event
        emit VoteStaked(_solutionLink, msg.sender, msg.value);
    }

    function _checkAlreadyVoted(address[] memory _voterAddress, address _voter)
        private
        view
        onlyActiveContract
        returns (bool)
    {
        uint256 lengthOfArr = _voterAddress.length;
        for (uint256 i = 0; i < lengthOfArr; i++) {
            if (_voter == _voterAddress[i]) return true;
        }

        return false;
    }

    function _lendToAave(uint256 _amount) private nonReentrant {
        // Initialise the ETHGateway Contract
        IWETHGateway ethGateWay = IWETHGateway(ethGateWayAddress);
        // Initialise the LendingPoolAddressesProvider Contract
        ILendingPoolAddressesProvider lendingProvider = ILendingPoolAddressesProvider(
                lendingPoolProviderAddress
            );
        // console.log(lendingProvider.getLendingPool());
        // Lend the matic tokens to the Aave Protocol.
        ethGateWay.depositETH{value: _amount}(
            // Address of Lending Pool
            lendingProvider.getLendingPool(),
            // The address that would receive the aToken, in this case the contract
            address(this),
            // Referal Code: For now its 0
            0
        );
    }

    function _storeVoteDetail(
        string memory _solutionLink,
        address _voter,
        uint256 _stakeAmount,
        string memory _tokenName
    ) private onlyActiveContract nonReentrant {
        Vote storage vote = voteDetails[_solutionLink][_voter];
        vote.voter = _voter;
        vote.amountStaked = _stakeAmount;
        vote.rewardToken = _tokenName;
    }

    /// @notice Allows admin to set the amount to be unsstaked
    /// @dev Lets say there are two solution A,B & three votes X,Y,Z with amount as 2,3,4
    ///      X,Y staked on A & Z staked on B
    ///      the format of input will be  _solutionLinks[A,A,B], _voterAddress[X,Y,Z], _amount[2,3,4]
    /// @param _bountyUrl a parameter just like in doxygen (must be followed by parameter name)
    /// @param _publisher a parameter just like in doxygen (must be followed by parameter name)
    /// @param _solutionLinks a parameter just like in doxygen (must be followed by parameter name)
    /// @param _voterAddress a parameter just like in doxygen (must be followed by parameter name)
    /// @param _baseAmount a parameter just like in doxygen (must be followed by parameter name)
    /// @param _rewardAmount a parameter just like in doxygen (must be followed by parameter name)
    /// @param start a parameter just like in doxygen (must be followed by parameter name)
    /// @param end a parameter just like in doxygen (must be followed by parameter name)
    function setUnstakeAmount(
        string memory _bountyUrl,
        address _publisher,
        string[] memory _solutionLinks,
        address[] memory _voterAddress,
        uint256[] memory _baseAmount,
        uint256[] memory _rewardAmount,
        uint256 start,
        uint256 end
    ) external onlyActiveContract onlyChainwhizAdmin {
        Bounty memory bounty = bountyDetail[_publisher][_bountyUrl];
        require(
            _solutionLinks.length == end &&
                _voterAddress.length == end &&
                _baseAmount.length == end,
            "SET_UNSTAKE_A"
        );
        require(
            bounty.endVoteTime <=
                block.timestamp &&
                !bounty.isUnstakeSet,
            "SET_UNSTAKE_B"
        );
        for (uint256 i = start; i < end; i++) {
            Vote storage vote = voteDetails[_solutionLinks[i]][
                _voterAddress[i]
            ];
            require(vote.amountStaked != 0, "SET_UNSTAKE_C");
            vote.returnBaseAmount = _baseAmount[i];
            vote.returnRewardAmount = _rewardAmount[i];
            if (vote.amountStaked > vote.returnBaseAmount)
                ChainwhizTreasary += (vote.amountStaked -
                    vote.returnBaseAmount);
        }
        bounty.isUnstakeSet = true;
        emit UnstakeAmountSet(_publisher, _bountyUrl);
    }

    //For each voter to claim their staked amount(either slashed or with reward)
    //TODO: add the voter address too in the events
    function unstake(string memory _solutionLink) external onlyActiveContract {
        Vote storage vote = voteDetails[_solutionLink][msg.sender];
        _withdrawFromAave(vote.returnBaseAmount, msg.sender);
        bool isMatic = tokenDetails[vote.rewardToken] == address(0);
        if (vote.returnRewardAmount != 0) {
            if (isMatic) {
                payable(msg.sender).transfer(vote.returnRewardAmount);
            } else {
                IERC20(tokenDetails[vote.rewardToken]).transfer(
                    msg.sender,
                    vote.returnRewardAmount
                );
            }
        }

        vote.isUnstake = true;
        emit VoterUnstaked(_solutionLink, msg.sender);
    }

    function _withdrawFromAave(uint256 _amount, address _to)
        private
        onlyActiveContract
        nonReentrant
    {
        // Initialise the ETHGateway Contract
        IWETHGateway ethGateWay = IWETHGateway(ethGateWayAddress);
        // Initialise the LendingPoolAddressesProvider Contract
        ILendingPoolAddressesProvider lendingProvider = ILendingPoolAddressesProvider(
                lendingPoolProviderAddress
            );
        // Withdraw the matic tokens from the Aave Protocol.
        ethGateWay.withdrawETH(lendingProvider.getLendingPool(), _amount, _to);
    }

    /// @notice Publisher (in case of disperancy Chainwhiz Admin) can initiate the escrow
    /// @param _bountyUrl a parameter just like in doxygen (must be followed by parameter name)
    /// @param _solutionLink a parameter just like in doxygen (must be followed by parameter name)
    function initiateEscrow(
        string memory _bountyUrl,
        string memory _solutionLink
    ) external onlyActiveContract {
        //get question details
        Bounty storage bounty = bountyDetail[msg.sender][_bountyUrl];
        // console.log(question.isCommunityVote);
        //get solution details
        Solution storage solution = solutionDetails[_bountyUrl][_solutionLink];
        //only publisher or admin(in case of disperancy) can initiate the escrow
        require(
            bounty.publisher == msg.sender || ChainwhizAdmin == msg.sender,
            "INIT_ESCROW_A"
        );
        //check if solution is legitimate
        require(
            keccak256(abi.encodePacked(solution.solutionLink)) !=
                keccak256(abi.encodePacked("")) &&
                solution.solver != address(0),
            "INIT_ESCROW_B"
        );
        //1st condition for issue without vote and 2nd for with vote
        require(
            (bounty.endSolveTime <= block.timestamp &&
                bounty.questionStatus == QuestionStatus.Solve) ||
                (bounty.isCommunityVote &&
                    bounty.endVoteTime <= block.timestamp &&
                    bounty.questionStatus == QuestionStatus.Vote),
            "INIT_ESCROW_C"
        );
        //check for the state too
        require(
            bounty.questionStatus == QuestionStatus.Solve ||
                bounty.questionStatus == QuestionStatus.Vote,
            "INIT_ESCROW_D"
        );
        // finally update the status
        bounty.questionStatus = QuestionStatus.Escrow;
        solution.escrowStatus = EscrowStatus.Initiate;
        bounty.choosenSolution = solution;
        emit EscorwInitiated(
            bounty.publisher,
            solution.solver,
            _bountyUrl,
            solution.solutionLink
        );
    }

    // @notice Transfer the ownership of github repo to publisher
    // @dev We checked for if the solution is legitimate or not in first step so we can skop it here
    // @param _publisher a parameter just like in doxygen (must be followed by parameter name)
    // @param _issueLink a parameter just like in doxygen (must be followed by parameter name)
    function claimRewardAmount(address _publisher, string memory _bountyUrl)
        external
        onlyActiveContract
    {
        //get question details
        Bounty storage bounty = bountyDetail[_publisher][_bountyUrl];
        //only solver or admin(in case of disperancy) can initiate the escrow
        require(
            bounty.choosenSolution.solver == msg.sender ||
                ChainwhizAdmin == msg.sender,
            "TRANSFER_REWARD_A"
        );
        //check for the escrow and question status
        require(
            bounty.questionStatus == QuestionStatus.Escrow &&
                bounty.choosenSolution.escrowStatus == EscrowStatus.Initiate,
            "TRANSFER_REWARD_B"
        );
        // update the state
        bounty.choosenSolution.escrowStatus = EscrowStatus.Complete;
        bool isMatic = tokenDetails[bounty.tokenName] == address(0);
        _transferFunds(
            payable(bounty.choosenSolution.solver),
            bounty.solverRewardAmount,
            isMatic,
            bounty.tokenName
        );

        emit EscrowTransferOwnership(
            bounty.publisher,
            bounty.choosenSolution.solver,
            _bountyUrl,
            bounty.choosenSolution.solutionLink
        );
    }

    // /// @notice Transfer the ownership of github repo to publisher
    // /// @param _publisher a parameter just like in doxygen (must be followed by parameter name)
    // /// @param _issueLink a parameter just like in doxygen (must be followed by parameter name)
    // function transferRewardAmount(address _publisher, string memory _issueLink)
    //     external
    //     payable
    // {
    //     //get question details
    //     Question memory question = issueDetail[_publisher][_issueLink];
    //     //only solver or admin(in case of disperancy) can initiate the escrow
    //     require(
    //         question.publisher == msg.sender || ChainwhizAdmin == msg.sender,
    //         "Error in transferRewardAmount: Unauthorized"
    //     );
    //     //check for the escrow and question status
    //     require(
    //         question.questionStatus == QuestionStatus.Escrow &&
    //             question.choosenSolution.escrowStatus ==
    //             EscrowStatus.Initiate,
    //         "Error in transferRewardAmount: Not at right state"
    //     );
    //     // update the state
    //     question.choosenSolution.escrowStatus = EscrowStatus.Complete;
    //     _transferFunds(
    //         payable(question.choosenSolution.solver),
    //         question.solverRewardAmount
    //     );
    //     emit EscrowTransferOwnership(
    //         question.publisher,
    //         question.choosenSolution.solver,
    //         _issueLink,
    //         question.choosenSolution.solutionLink
    //     );
    // }

    function _transferFunds(
        address payable _receipient,
        uint256 _amount,
        bool _isMatic,
        string memory _tokenName
    ) private onlyActiveContract nonReentrant {
        if (_isMatic) {
            _receipient.transfer(_amount);
        } else {
            IERC20(tokenDetails[_tokenName]).transfer(_receipient, _amount);
        }
    }

    function claimInterest(address _claimer)
        external
        onlyActiveContract
        onlyChainwhizAdmin
        nonReentrant
    {
        IAaveIncentivesController incentive = IAaveIncentivesController(
            aaveIncentiveAddress
        );
        uint256 claimAmount = incentive.getRewardsBalance(
            rewardAddress,
            address(this)
        );
        incentive.claimRewards(rewardAddress, claimAmount, _claimer);
    }

    function withdrawFromTreasery(uint256 _amount, address _to)
        external
        onlyActiveContract
        onlyChainwhizAdmin
    {
        //check if the amount is less than the amount in treasery
        require(_amount <= ChainwhizTreasary, "TREASARY_WITHDRAW_A");
        require(_to != address(0), "TREASARY_WITHDRAW_B");
        _withdrawFromAave(_amount, _to);
    }

    function setApproval(uint256 _approvalAmount) public {
        IERC20(aMaticAddress).approve(ethGateWayAddress, _approvalAmount);
    }

    function payBackPublisher(
        address _publisherAddress,
        string memory _bountyUrl,
        bool flag
    ) external onlyActiveContract onlyChainwhizAdmin {
        Bounty storage bounty = bountyDetail[_publisherAddress][_bountyUrl];
        require(bounty.solverRewardAmount != 0, "REFUND_ERROR_A");
        require(
            bounty.questionStatus == QuestionStatus.Over ||
                bounty.questionStatus == QuestionStatus.Solve ||
                bounty.questionStatus == QuestionStatus.Vote,
            "REFUND_ERROR_B"
        );
        bool isMatic = tokenDetails[bounty.tokenName] == address(0);
        //if flag == true, transfer the whole reward back
        if (flag) {
            _transferFunds(
                payable(_publisherAddress),
                bounty.solverRewardAmount +
                    bounty.communityVoterRewardAmount,
                isMatic,
                bounty.tokenName
            );
        }
        //if flag == false, transfer only the solver reward back
        else {
            _transferFunds(
                payable(_publisherAddress),
                bounty.solverRewardAmount,
                isMatic,
                bounty.tokenName
            );
        }
    }
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

//SPDX-License-Identifier:UNLICENSED
pragma solidity >=0.6.0 <=0.9.0;

interface IWETHGateway {
  function depositETH(
    address lendingPool,
    address onBehalfOf,
    uint16 referralCode
  ) external payable;

  function withdrawETH(
    address lendingPool,
    uint256 amount,
    address onBehalfOf
  ) external;

}

//SPDX-License-Identifier:UNLICENSED
pragma solidity >=0.6.0 <0.9.0;

interface ILendingPoolAddressesProvider {
    function getLendingPool() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <=0.9.0;
interface IERC20 {
   function approve(address spender, uint256 amount) external returns (bool);
   function balanceOf(address account) external view returns (uint256);
   function allowance(address owner, address spender) external view returns (uint256);
   function transfer(address recipient, uint256 amount) external returns (bool);
   function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <=0.9.0;
interface IAaveIncentivesController{
       function claimRewards( address[] calldata assets,uint256 amount,address to) external returns (uint256);
       function getRewardsBalance(address[] calldata assets, address user)external view returns (uint256);
}