// SPDX-License-Identifier: MIT

// $$\                                           $$$$$$\                      $$\
// $$ |                                         $$  __$$\                     $$ |
// $$ |      $$$$$$\  $$$$$$$\   $$$$$$$\       $$ /  \__| $$$$$$\   $$$$$$\  $$ |
// $$ |     $$  __$$\ $$  __$$\ $$  _____|      $$ |$$$$\ $$  __$$\  \____$$\ $$ |
// $$ |     $$$$$$$$ |$$ |  $$ |\$$$$$$\        $$ |\_$$ |$$ /  $$ | $$$$$$$ |$$ |
// $$ |     $$   ____|$$ |  $$ | \____$$\       $$ |  $$ |$$ |  $$ |$$  __$$ |$$ |
// $$$$$$$$\\$$$$$$$\ $$ |  $$ |$$$$$$$  |      \$$$$$$  |\$$$$$$  |\$$$$$$$ |$$ |
// \________|\_______|\__|  \__|\_______/        \______/  \______/  \_______|\__|

// Team Lens Handles:
// grzegorz.lens            | Front-End and Smart Contract Developer
// leoawolanski.lens        | Smart Contract Engineer
// cryptocomical.lens       | Designer

pragma solidity 0.8.17;

import "LensGoalHelpers.sol";
import "AutomationCompatible.sol";
import "AutomationCompatibleInterface.sol";
import "FunctionsClient.sol";
import "IFC.sol";

contract LensGoal is LensGoalHelpers, AutomationCompatibleInterface{
    // wallet where funds will be transfered in case of goal failure
    // is currently the undefined, edit later

    address communityWallet;
    // LINK token address on polygon
    // used for subscription renewals
    address linkTokenAddress = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    // address to which chainlink req. functions will be sent 
    // deploy FunctionsConsumer.sol before LensGoal.sol and input contract address in constructor
    address clFunctionsConsumerAddress; 
    // only these addresses may call certain functions 
    address[] owners = [0x2cF29308548E6E15056FA0C8dE1fd7087053e5Ae, 0x327def07a8e64E001E23a96E90955eDC091Ee066, 0x74B4B8C7cb9A594a6440965f982deF10BB9570b9];

    modifier onlyOwners() {
        require(msg.sender == owners[0] || msg.sender == owners[1] || msg.sender==owners[2]);
        _;
    }

    function updateClFunctionsConsumerAddr(address newAddr) public onlyOwners{
        clFunctionsConsumerAddress = newAddr;
    }

    // update chainlink oracle address
    function updateOracleAddress(address oracle) external onlyOwners {
        IFunctionsConsumer(clFunctionsConsumerAddress).updateOracleAddress(oracle);
    }

    // used to identify whether stake is in ether or erc20
    enum TokenType {
        ETHER,
        ERC20
    }

    // GoalStatus enum, used to check goal status (e.g. "pending", "true", "false")
    enum Status {
        PENDING,
        VOTED_TRUE,
        VOTED_FALSE
    }

    struct Votes {
        uint256 yes;
        uint256 no;
    }

    struct Stake {
        // stake can be ether or erc20
        TokenType tokenType;
        uint256 amount;
        // is address(0) if token type is ether
        address tokenAddress;
    }

    struct GoalBasicInfo {
        address user;
        string description;
        string verificationCriteria;
        uint256 deadline;
        Status status;
        uint256 goalId;
    }

    struct Goal {
        GoalBasicInfo info;
        Stake stake;
        Votes votes;
        string preProof;
        string proof;
    }

    struct AdditionalStake {
        Stake stake;
        uint256 stakeId;
        // which goal this stake belongs to
        uint256 goalId;
        address staker;
        // used for withdrawStake()
        // if withdraw == true, stake cannot be withdrawn
        bool withdrawn;
    }

    // get address's stake and goal ids
    mapping(address => uint256[]) public userToGoalIds;
    mapping(address => uint256[]) public userToStakeIds;
    // each id = goal
    mapping(uint256 => Goal) public goalIdToGoal;
    // each id = stake
    mapping(uint256 => AdditionalStake) public stakeIdToStake;
    // maps goal to all stakeId of stakes for that goal
    mapping(uint256 => uint256[]) goalIdToStakeIds;

    // will be incremented when new goals/stakes are published
    uint256 goalId;
    uint256 stakeId;

    // events
    event GoalCreated(
        address indexed _user,
        string _description,
        string _verificationCriteria,
        uint256 _deadline,
        Status _status,
        uint256 indexed _goalId
    );

    event AdditionalStakeCreated(
        address indexed _staker,
        TokenType _tokenType,
        uint256 _amount,
        address _tokenAddress,
        uint256 indexed _stakeId,
        uint256 indexed _goalId
    );

    event StakeWithdrawn(
        TokenType _tokenType,
        uint256 _amount,
        address _tokenAddress,
        uint256 indexed _stakeId,
        uint256 indexed _goalId,
        address indexed _staker
    );

    event ProofAdded(
        address indexed _user,
        string _proof,
        uint256 indexed _goalId
    );

    event VoteCasted(address indexed _voter, bool _vote, uint256 _goalId);

    // allows user to make a new goal
    function makeNewGoal(
        string memory description,
        string memory verificationCriteria,
        bool inEther,
        uint256 tokenAmount,
        address tokenAddress,
        uint256 timestampEnd,
        string memory preProof
    ) external payable {
        if (inEther) {
            // require(msg.value > 0, "msg.value must be greater than 0");
            // why user can stake nothing:
            // so that user can have friends stake as "rewards" and themselves stake nothing
            userToGoalIds[msg.sender].push(goalId);
            goalIdToGoal[goalId] = Goal(
                GoalBasicInfo(
                    msg.sender,
                    description,
                    verificationCriteria,
                    timestampEnd,
                    Status.PENDING,
                    goalId
                ),
                defaultEtherStake(),
                Votes(0, 0),
                preProof,
                ""
            );
            emit GoalCreated(
                msg.sender,
                description,
                verificationCriteria,
                timestampEnd,
                Status.PENDING,
                goalId
            );
            // increment goalId for later goal instantiation
            goalId++;
        } else {
            // require(tokenAmount > 0, "tokenAmount must be greater than 0");
            // transfer tokens to contracts
            require(
                IERC20(tokenAddress).transferFrom(
                    msg.sender,
                    address(this),
                    tokenAmount
                ) == true,
                "token transfer failed. check your approvals"
            );
            Goal memory goal = Goal(
                // define info struct
                GoalBasicInfo(
                    msg.sender,
                    description,
                    verificationCriteria,
                    timestampEnd,
                    Status.PENDING,
                    goalId
                ),
                // get etherstake struct
                defaultEtherStake(),
                // votes struct
                Votes(0, 0),
                preProof,
                ""
            );
            // push goalId
            userToGoalIds[msg.sender].push(goalId);
            // define goalId
            goalIdToGoal[goalId] = goal;
            emit GoalCreated(
                msg.sender,
                description,
                verificationCriteria,
                timestampEnd,
                Status.PENDING,
                goalId
            );
            // increment goalId (for future use)
            goalId++;
        }
    }

    // used in frontend
    function getGoalByGoalId(
        uint256 _goalId
    ) public view returns (Goal memory) {
        return goalIdToGoal[_goalId];
    }

    function getStakeByStakeId(
        uint256 _stakeId
    ) public view returns (AdditionalStake memory) {
        return stakeIdToStake[_stakeId];
    }

    // quickly get a Stake struct where token is ether
    function defaultEtherStake() internal view returns (Stake memory) {
        return Stake(TokenType.ETHER, msg.value, address(0));
    }

    // allows users to make additional stakes
    function makeNewStake(
        /* which goal the stake is for**/ uint256 _goalId,
        bool inEther,
        uint256 tokenAmount,
        address tokenAddress
    ) external payable {
        if (inEther) {
            // cannot stake 0 tokens
            require(msg.value > 0, "msg.value must be greater than 0");
            AdditionalStake memory stake = AdditionalStake(
                defaultEtherStake(),
                stakeId,
                _goalId,
                msg.sender,
                false
            );
            // push stakeId
            userToStakeIds[msg.sender].push(stakeId);
            // add stake to goal
            goalIdToStakeIds[_goalId].push(stakeId);
            // define stake in mapping
            stakeIdToStake[stakeId] = stake;
            emit AdditionalStakeCreated(
                msg.sender,
                TokenType.ETHER,
                msg.value,
                address(0),
                stakeId,
                _goalId
            );
            // increment stakeId for future use
            stakeId++;
        } else {
            // cannot stake 0 tokens
            require(tokenAmount > 0, "tokenAmount must be greater than 0");
            AdditionalStake memory stake = AdditionalStake(
                Stake(TokenType.ERC20, tokenAmount, tokenAddress),
                stakeId,
                _goalId,
                msg.sender,
                false
            );
            // push stakeId
            userToStakeIds[msg.sender].push(stakeId);
            // add stake to goal
            goalIdToStakeIds[_goalId].push(stakeId);
            // define stake in mapping
            stakeIdToStake[stakeId] = stake;
            emit AdditionalStakeCreated(
                msg.sender,
                TokenType.ERC20,
                tokenAmount,
                tokenAddress,
                stakeId,
                _goalId
            );
            // increment stakeId for future use
            stakeId++;
        }
    }

    // users can write or link to proof on chain to convince voters to vote positevely
    function writeProofs(
        /** input of strings to write */ string memory proof,
        uint256 _goalId
    ) external {
        // check for user to be goal initiator
        require(
            goalIdToGoal[_goalId].info.user == msg.sender,
            "not goal creator"
        );
        // update proof
        goalIdToGoal[_goalId].proof = proof;
        emit ProofAdded(msg.sender, proof, _goalId);
    }

    // get info of goal (for front end)
    function getGoalBasicInfo(
        uint256 _goalId
    ) public view returns (GoalBasicInfo memory) {
        return goalIdToGoal[_goalId].info;
    }

    // vote on goal
    function vote(
        uint256 _goalId,
        bool input
    )
        external
        // TODO: IMPLEMENT ONLY FOLLOWER VOTING 
        //isFollowingAddress(goalIdToGoal[_goalId].info.user, msg.sender)
        /** make sure voting windows is open */ windowOpen(
            goalIdToGoal[_goalId].info.deadline
        )
    {
        require(goalIdToGoal[_goalId].info.status == Status.PENDING);
        if (input == true) {
            goalIdToGoal[_goalId].votes.yes++;
        } else {
            goalIdToGoal[_goalId].votes.no++;
        }
        emit VoteCasted(msg.sender, input, _goalId);
    }

    // checks if voting window is open
    modifier windowOpen(uint256 startTimestamp) {
        require(
            block.timestamp > startTimestamp &&
                // voting window is one day long, starts at deadline and ends at deadline + 1 days
                block.timestamp < startTimestamp + 1 days
        );
        _;
    }

    // allows stakers to withdraw stake so that they don't purposely vote negatively to get it back
    function withdrawStake(uint256 _stakeId) external {
        AdditionalStake memory stake = stakeIdToStake[_stakeId];
        // identity check
        require(stake.staker == msg.sender, "not staker");
        // safety check
        require(stake.withdrawn == false, "stake already withdrawn");
        // if stake is in ether, send ether back to msg.sender and set withdrawn to true
        if (stake.stake.tokenType == TokenType.ETHER) {
            stakeIdToStake[_stakeId].withdrawn = true;
            payable(msg.sender).transfer(stake.stake.amount);
        } else {
            stakeIdToStake[_stakeId].withdrawn = true;
            IERC20(stake.stake.tokenAddress).transfer(
                msg.sender,
                stake.stake.amount
            );
        }
        emit StakeWithdrawn(
            stake.stake.tokenType,
            stake.stake.amount,
            stake.stake.tokenAddress,
            stake.stakeId,
            stake.goalId,
            stake.staker
        );
    }

    function votingWindowClosedAndStatusIsPending(
        uint256 _goalId
    ) internal view returns (bool) {
        Goal memory goal = goalIdToGoal[_goalId];
        return
            block.timestamp > goal.info.deadline + 1 days &&
            goal.info.status == Status.PENDING;
    }

    // Chainlink view function. If returns true, Chainlink will run state-changing performUpkeep() function
    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        for (uint256 i; i < goalId; i++) {
            if (votingWindowClosedAndStatusIsPending(i)) {
                return (true, bytes("LensGoal"));
            }
        }
        return (false, bytes("LensGoal"));
    }

    // Chainlink state changing transaction. Will run if checkUpkeep() returns true
    function performUpkeep(bytes calldata /* performData */) external override {
        // loop through all goals
        for (uint256 i; i < goalId; i++) {
            // define goal var
            // check if voting window has closed and Status has not been set to pending
            // if status is pending, that means that the voting window has just closed
            if (votingWindowClosedAndStatusIsPending(i)) {
                // get result of votes
                bool accomplishedGoal = evaluateVotes(i);
                // if voted true, transfer stakes to user and update status
                Goal memory goal = goalIdToGoal[i];
                if (accomplishedGoal) {
                    goalIdToGoal[i].info.status = Status.VOTED_TRUE;
                    transferStakes(accomplishedGoal, goal.info.goalId);
                } else {
                    goalIdToGoal[i].info.status = Status.VOTED_FALSE;
                    transferStakes(accomplishedGoal, goal.info.goalId);
                }
            }
        }
    }

    // function evaluates votes
    function evaluateVotes(uint256 _goalId) internal view returns (bool) {
        Votes memory _votes = goalIdToGoal[_goalId].votes;
        // if 0 votes, send funds back to user
        if (_votes.yes == 0 && _votes.no == 0) {
            return true;
        }
        return _votes.yes >= _votes.no;
    }

    // function transfers additional stakes (if any) and user stake to user/community wallet
    function transferStakes(
        /* stakes will be transfered to user or to community wallet/back to stakers depending on this bool */ bool userAccomplishedGoal,
        uint256 _goalId
    ) internal {
        uint256[] memory stakeIds = goalIdToStakeIds[_goalId];
        // transfer stake to user or wallet, depending on whether or not they achived their goal
        transferUserStake(userAccomplishedGoal, _goalId);
        if (stakeIds.length > 0) {
            if (userAccomplishedGoal) {
                for (uint256 i; i < stakeIds.length; i++) {
                    transferStakeToUser(
                        stakeIdToStake[goalIdToStakeIds[_goalId][i]].stakeId
                    );
                }
            } else {
                for (uint256 i; i < stakeIds.length; i++) {
                    transferStakeBackToStaker(
                        stakeIdToStake[goalIdToStakeIds[_goalId][i]].stakeId
                    );
                }
            }
        }
    }

    // function transfers stake back to its staker
    function transferStakeBackToStaker(uint256 _stakeId) internal {
        AdditionalStake memory stake = stakeIdToStake[_stakeId];
        // safety check
        if (stake.withdrawn == false) {
            if (stake.stake.tokenType == TokenType.ETHER) {
                // if stake is in ether, transfer stake amount back to staker
                stakeIdToStake[_stakeId].withdrawn = true;
                payable(stake.staker).transfer(stake.stake.amount);
            } else {
                stakeIdToStake[_stakeId].withdrawn = true;
                // if stake is in erc20, transfer tokens back to staker
                IERC20(stake.stake.tokenAddress).transfer(
                    stake.staker,
                    stake.stake.amount
                );
            }
        }
    }

    // function transfers stake to user
    function transferStakeToUser(uint256 _stakeId) internal {
        address user = goalIdToGoal[stakeIdToStake[_stakeId].goalId].info.user;
        // local var to save gas
        AdditionalStake memory stake = stakeIdToStake[_stakeId];
        // safety check
        if (stake.withdrawn == false) {
            if (stake.stake.tokenType == TokenType.ETHER) {
                stakeIdToStake[_stakeId].withdrawn = true;
                // if stake is in ether, transfer stake amount to user
                payable(user).transfer(stake.stake.amount);
            } else {
                stakeIdToStake[_stakeId].withdrawn = true;
                // transfer tokens to user
                IERC20(stake.stake.tokenAddress).transfer(
                    user,
                    stake.stake.amount
                );
            }
        }
    }

    // function transfers user stake to user/community wallet
    function transferUserStake(
        bool accomplishedGoal,
        uint256 _goalId
    ) internal {
        // safety check
        // create goal var to save gas
        Goal memory goal = goalIdToGoal[_goalId];
        require(goal.info.status != Status.PENDING, "goal complete");

        if (accomplishedGoal) {
            // if stake is in ether, transfer ether back to user
            if (goal.stake.tokenType == TokenType.ETHER) {
                payable(goal.info.user).transfer(goal.stake.amount);
            }
            // if stake is in erc20, transfer tokens to user
            else {
                IERC20(goal.stake.tokenAddress).transfer(
                    goal.info.user,
                    goal.stake.amount
                );
            }
        } else {
            // if stake is in ether, transfer ether to community wallet
            if (goal.stake.tokenType == TokenType.ETHER) {
                payable(communityWallet).transfer(goal.stake.amount);
            }
            // if stake is in erc20, transfer tokens to community wallet
            else {
                IERC20(goal.stake.tokenAddress).transfer(
                    communityWallet,
                    goal.stake.amount
                );
            }
        }
    }

    // Chainlink request fuction 

    function executeRequestAndGetReturns(string calldata source,
        bytes calldata secrets,
        Functions.Location secretsLocation,
        string[] calldata args,
        uint64 subscriptionId,
        uint32 gasLimit) public returns(bytes memory response, bytes memory error) {
            IFunctionsConsumer(clFunctionsConsumerAddress).executeRequest(source, secrets, secretsLocation, args, subscriptionId, gasLimit);
            return(IFunctionsConsumer(clFunctionsConsumerAddress).getLatestReponseAndError());
        }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC721.sol";
import "ILensNFTContract.sol";

contract LensGoalHelpers {
    ILensNFTContract LNFTC =
        ILensNFTContract(0x60Ae865ee4C725cd04353b5AAb364553f56ceF82);

    // Get address list of all holders of NFT
    function getAddressesOfLensFrens(
        address _nftAddress
    ) public view returns (address[] memory) {
        // create address list
        address[] memory followerAddresses;

        // initialize nft object
        IERC721 NFT = IERC721(_nftAddress);

        // get total supply of nfts (used for iteration)
        uint256 totalNftSupply = NFT.totalSupply();

        // iterate from 0 to totalNftSupply-1
        for (uint256 i; i < totalNftSupply; i++) {
            if (
                NFT.ownerOf(i) != 0x0000000000000000000000000000000000000000 &&
                NFT.ownerOf(i) != 0x000000000000000000000000000000000000dEaD
            ) {
                followerAddresses[i] = (NFT.ownerOf(i));
            }
        }

        return followerAddresses;
    }

    modifier isFollowingAddress(address user, address follower) {
        address followerNFTAdrress = getFollowerNFTAddress(user);
        // check if user holds nft(s)
        require(IERC721(followerNFTAdrress).balanceOf(follower) > 0);
        _;
    }

    // Get Follower NFT of address using Lenster NFT Contract
    function getFollowerNFTAddress(address user) public view returns (address) {
        uint256 profileId = LNFTC.defaultProfile(user);
        return LNFTC.getFollowNFT(profileId);
    }

    function getLensFrensWithUserAddress(
        address user
    ) public view returns (address[] memory lensfrens) {
        return getAddressesOfLensFrens(getFollowerNFTAddress(user));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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

    function totalSupply() external view returns (uint256 _totalSupply);

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(
        uint256 tokenId
    ) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);
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

pragma solidity ^0.8.0;

interface ILensNFTContract {
    function defaultProfile(address wallet) external view returns (uint256);

    function getFollowNFT(
        uint256 profileId
    ) external view returns (address _nftContractAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "AutomationBase.sol";
import "AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is
    AutomationBase,
    AutomationCompatibleInterface
{}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
    error OnlySimulatedBackend();

    /**
     * @notice method that allows it to be simulated via eth_call by checking that
     * the sender is the zero address.
     */
    function preventExecution() internal view {
        if (tx.origin != address(0)) {
            revert OnlySimulatedBackend();
        }
    }

    /**
     * @notice modifier that allows it to be simulated via eth_call by checking
     * that the sender is the zero address.
     */
    modifier cannotExecute() {
        preventExecution();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
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
    function checkUpkeep(
        bytes calldata checkData
    ) external returns (bool upkeepNeeded, bytes memory performData);

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
pragma solidity ^0.8.6;

import "Functions.sol";
import "FunctionsClientInterface.sol";
import "FunctionsOracleInterface.sol";

/**
 * @title The Chainlink Functions client contract
 * @notice Contract writers can inherit this contract in order to create Chainlink Functions requests
 */
abstract contract FunctionsClient is FunctionsClientInterface {
  FunctionsOracleInterface internal s_oracle;
  mapping(bytes32 => address) internal s_pendingRequests;

  event RequestSent(bytes32 indexed id);
  event RequestFulfilled(bytes32 indexed id);

  error SenderIsNotRegistry();
  error RequestIsAlreadyPending();
  error RequestIsNotPending();

  constructor(address oracle) {
    setOracle(oracle);
  }

  /**
   * @inheritdoc FunctionsClientInterface
   */
  function getDONPublicKey() external view override returns (bytes memory) {
    return s_oracle.getDONPublicKey();
  }

  /**
   * @notice Estimate the total cost that will be charged to a subscription to make a request: gas re-imbursement, plus DON fee, plus Registry fee
   * @param req The initialized Functions.Request
   * @param subscriptionId The subscription ID
   * @param gasLimit gas limit for the fulfillment callback
   * @return billedCost Cost in Juels (1e18) of LINK
   */
  function estimateCost(
    Functions.Request memory req,
    uint64 subscriptionId,
    uint32 gasLimit,
    uint256 gasPrice
  ) public view returns (uint96) {
    return s_oracle.estimateCost(subscriptionId, Functions.encodeCBOR(req), gasLimit, gasPrice);
  }

  /**
   * @notice Sends a Chainlink Functions request to the stored oracle address
   * @param req The initialized Functions.Request
   * @param subscriptionId The subscription ID
   * @param gasLimit gas limit for the fulfillment callback
   * @return requestId The generated request ID
   */
  function sendRequest(
    Functions.Request memory req,
    uint64 subscriptionId,
    uint32 gasLimit
  ) internal returns (bytes32) {
    bytes32 requestId = s_oracle.sendRequest(subscriptionId, Functions.encodeCBOR(req), gasLimit);
    s_pendingRequests[requestId] = s_oracle.getRegistry();
    emit RequestSent(requestId);
    return requestId;
  }

  /**
   * @notice User defined function to handle a response
   * @param requestId The request ID, returned by sendRequest()
   * @param response Aggregated response from the user code
   * @param err Aggregated error from the user code or from the execution pipeline
   * Either response or error parameter will be set, but never both
   */
  function fulfillRequest(
    bytes32 requestId,
    bytes memory response,
    bytes memory err
  ) internal virtual;

  /**
   * @inheritdoc FunctionsClientInterface
   */
  function handleOracleFulfillment(
    bytes32 requestId,
    bytes memory response,
    bytes memory err
  ) external override recordChainlinkFulfillment(requestId) {
    fulfillRequest(requestId, response, err);
  }

  /**
   * @notice Sets the stored Oracle address
   * @param oracle The address of Functions Oracle contract
   */
  function setOracle(address oracle) internal {
    s_oracle = FunctionsOracleInterface(oracle);
  }

  /**
   * @notice Gets the stored address of the oracle contract
   * @return The address of the oracle contract
   */
  function getChainlinkOracleAddress() internal view returns (address) {
    return address(s_oracle);
  }

  /**
   * @notice Allows for a request which was created on another contract to be fulfilled
   * on this contract
   * @param oracleAddress The address of the oracle contract that will fulfill the request
   * @param requestId The request ID used for the response
   */
  function addExternalRequest(address oracleAddress, bytes32 requestId) internal notPendingRequest(requestId) {
    s_pendingRequests[requestId] = oracleAddress;
  }

  /**
   * @dev Reverts if the sender is not the oracle that serviced the request.
   * Emits RequestFulfilled event.
   * @param requestId The request ID for fulfillment
   */
  modifier recordChainlinkFulfillment(bytes32 requestId) {
    if (msg.sender != s_pendingRequests[requestId]) {
      revert SenderIsNotRegistry();
    }
    delete s_pendingRequests[requestId];
    emit RequestFulfilled(requestId);
    _;
  }

  /**
   * @dev Reverts if the request is already pending
   * @param requestId The request ID for fulfillment
   */
  modifier notPendingRequest(bytes32 requestId) {
    if (s_pendingRequests[requestId] != address(0)) {
      revert RequestIsAlreadyPending();
    }
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import {CBORChainlink} from "CBORChainlink.sol";
import {BufferChainlink} from "BufferChainlink.sol";

/**
 * @title Library for Chainlink Functions
 */
library Functions {
  uint256 internal constant DEFAULT_BUFFER_SIZE = 256;

  using CBORChainlink for BufferChainlink.buffer;

  enum Location {
    Inline,
    Remote
  }

  enum CodeLanguage {
    JavaScript
    // In future version we may add other languages
  }

  struct Request {
    Location codeLocation;
    Location secretsLocation;
    CodeLanguage language;
    string source; // Source code for Location.Inline or url for Location.Remote
    bytes secrets; // Encrypted secrets blob for Location.Inline or url for Location.Remote
    string[] args;
  }

  error EmptySource();
  error EmptyUrl();
  error EmptySecrets();
  error EmptyArgs();

  /**
   * @notice Encodes a Request to CBOR encoded bytes
   * @param self The request to encode
   * @return CBOR encoded bytes
   */
  function encodeCBOR(Request memory self) internal pure returns (bytes memory) {
    BufferChainlink.buffer memory buf;
    BufferChainlink.init(buf, DEFAULT_BUFFER_SIZE);

    buf.encodeString("codeLocation");
    buf.encodeUInt(uint256(self.codeLocation));

    buf.encodeString("language");
    buf.encodeUInt(uint256(self.language));

    buf.encodeString("source");
    buf.encodeString(self.source);

    if (self.args.length > 0) {
      buf.encodeString("args");
      buf.startArray();
      for (uint256 i = 0; i < self.args.length; i++) {
        buf.encodeString(self.args[i]);
      }
      buf.endSequence();
    }

    if (self.secrets.length > 0) {
      buf.encodeString("secretsLocation");
      buf.encodeUInt(uint256(self.secretsLocation));
      buf.encodeString("secrets");
      buf.encodeBytes(self.secrets);
    }

    return buf.buf;
  }

  /**
   * @notice Initializes a Chainlink Functions Request
   * @dev Sets the codeLocation and code on the request
   * @param self The uninitialized request
   * @param location The user provided source code location
   * @param language The programming language of the user code
   * @param source The user provided source code or a url
   */
  function initializeRequest(
    Request memory self,
    Location location,
    CodeLanguage language,
    string memory source
  ) internal pure {
    if (bytes(source).length == 0) revert EmptySource();

    self.codeLocation = location;
    self.language = language;
    self.source = source;
  }

  /**
   * @notice Initializes a Chainlink Functions Request
   * @dev Simplified version of initializeRequest for PoC
   * @param self The uninitialized request
   * @param javaScriptSource The user provided JS code (must not be empty)
   */
  function initializeRequestForInlineJavaScript(Request memory self, string memory javaScriptSource) internal pure {
    initializeRequest(self, Location.Inline, CodeLanguage.JavaScript, javaScriptSource);
  }

  /**
   * @notice Adds Inline user encrypted secrets to a Request
   * @param self The initialized request
   * @param secrets The user encrypted secrets (must not be empty)
   */
  function addInlineSecrets(Request memory self, bytes memory secrets) internal pure {
    if (secrets.length == 0) revert EmptySecrets();

    self.secretsLocation = Location.Inline;
    self.secrets = secrets;
  }

  /**
   * @notice Adds Remote user encrypted secrets to a Request
   * @param self The initialized request
   * @param encryptedSecretsURLs Encrypted comma-separated string of URLs pointing to off-chain secrets
   */
  function addRemoteSecrets(Request memory self, bytes memory encryptedSecretsURLs) internal pure {
    if (encryptedSecretsURLs.length == 0) revert EmptySecrets();

    self.secretsLocation = Location.Remote;
    self.secrets = encryptedSecretsURLs;
  }

  /**
   * @notice Adds args for the user run function
   * @param self The initialized request
   * @param args The array of args (must not be empty)
   */
  function addArgs(Request memory self, string[] memory args) internal pure {
    if (args.length == 0) revert EmptyArgs();

    self.args = args;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.19;

import {BufferChainlink} from "BufferChainlink.sol";

library CBORChainlink {
  using BufferChainlink for BufferChainlink.buffer;

  uint8 private constant MAJOR_TYPE_INT = 0;
  uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
  uint8 private constant MAJOR_TYPE_BYTES = 2;
  uint8 private constant MAJOR_TYPE_STRING = 3;
  uint8 private constant MAJOR_TYPE_ARRAY = 4;
  uint8 private constant MAJOR_TYPE_MAP = 5;
  uint8 private constant MAJOR_TYPE_TAG = 6;
  uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

  uint8 private constant TAG_TYPE_BIGNUM = 2;
  uint8 private constant TAG_TYPE_NEGATIVE_BIGNUM = 3;

  function encodeFixedNumeric(BufferChainlink.buffer memory buf, uint8 major, uint64 value) private pure {
    if(value <= 23) {
      buf.appendUint8(uint8((major << 5) | value));
    } else if (value <= 0xFF) {
      buf.appendUint8(uint8((major << 5) | 24));
      buf.appendInt(value, 1);
    } else if (value <= 0xFFFF) {
      buf.appendUint8(uint8((major << 5) | 25));
      buf.appendInt(value, 2);
    } else if (value <= 0xFFFFFFFF) {
      buf.appendUint8(uint8((major << 5) | 26));
      buf.appendInt(value, 4);
    } else {
      buf.appendUint8(uint8((major << 5) | 27));
      buf.appendInt(value, 8);
    }
  }

  function encodeIndefiniteLengthType(BufferChainlink.buffer memory buf, uint8 major) private pure {
    buf.appendUint8(uint8((major << 5) | 31));
  }

  function encodeUInt(BufferChainlink.buffer memory buf, uint value) internal pure {
    if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, value);
    } else {
      encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(value));
    }
  }

  function encodeInt(BufferChainlink.buffer memory buf, int value) internal pure {
    if(value < -0x10000000000000000) {
      encodeSignedBigNum(buf, value);
    } else if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, uint(value));
    } else if(value >= 0) {
      encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(uint256(value)));
    } else {
      encodeFixedNumeric(buf, MAJOR_TYPE_NEGATIVE_INT, uint64(uint256(-1 - value)));
    }
  }

  function encodeBytes(BufferChainlink.buffer memory buf, bytes memory value) internal pure {
    encodeFixedNumeric(buf, MAJOR_TYPE_BYTES, uint64(value.length));
    buf.append(value);
  }

  function encodeBigNum(BufferChainlink.buffer memory buf, uint value) internal pure {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_BIGNUM));
    encodeBytes(buf, abi.encode(value));
  }

  function encodeSignedBigNum(BufferChainlink.buffer memory buf, int input) internal pure {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_NEGATIVE_BIGNUM));
    encodeBytes(buf, abi.encode(uint256(-1 - input)));
  }

  function encodeString(BufferChainlink.buffer memory buf, string memory value) internal pure {
    encodeFixedNumeric(buf, MAJOR_TYPE_STRING, uint64(bytes(value).length));
    buf.append(bytes(value));
  }

  function startArray(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
  }

  function startMap(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
  }

  function endSequence(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev A library for working with mutable byte buffers in Solidity.
 *
 * Byte buffers are mutable and expandable, and provide a variety of primitives
 * for writing to them. At any time you can fetch a bytes object containing the
 * current contents of the buffer. The bytes object should not be stored between
 * operations, as it may change due to resizing of the buffer.
 */
library BufferChainlink {
  /**
   * @dev Represents a mutable buffer. Buffers have a current value (buf) and
   *      a capacity. The capacity may be longer than the current value, in
   *      which case it can be extended without the need to allocate more memory.
   */
  struct buffer {
    bytes buf;
    uint256 capacity;
  }

  /**
   * @dev Initializes a buffer with an initial capacity.
   * @param buf The buffer to initialize.
   * @param capacity The number of bytes of space to allocate the buffer.
   * @return The buffer, for chaining.
   */
  function init(buffer memory buf, uint256 capacity) internal pure returns (buffer memory) {
    if (capacity % 32 != 0) {
      capacity += 32 - (capacity % 32);
    }
    // Allocate space for the buffer data
    buf.capacity = capacity;
    assembly {
      let ptr := mload(0x40)
      mstore(buf, ptr)
      mstore(ptr, 0)
      mstore(0x40, add(32, add(ptr, capacity)))
    }
    return buf;
  }

  /**
   * @dev Initializes a new buffer from an existing bytes object.
   *      Changes to the buffer may mutate the original value.
   * @param b The bytes object to initialize the buffer with.
   * @return A new buffer.
   */
  function fromBytes(bytes memory b) internal pure returns (buffer memory) {
    buffer memory buf;
    buf.buf = b;
    buf.capacity = b.length;
    return buf;
  }

  function resize(buffer memory buf, uint256 capacity) private pure {
    bytes memory oldbuf = buf.buf;
    init(buf, capacity);
    append(buf, oldbuf);
  }

  function max(uint256 a, uint256 b) private pure returns (uint256) {
    if (a > b) {
      return a;
    }
    return b;
  }

  /**
   * @dev Sets buffer length to 0.
   * @param buf The buffer to truncate.
   * @return The original buffer, for chaining..
   */
  function truncate(buffer memory buf) internal pure returns (buffer memory) {
    assembly {
      let bufptr := mload(buf)
      mstore(bufptr, 0)
    }
    return buf;
  }

  /**
   * @dev Writes a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The start offset to write to.
   * @param data The data to append.
   * @param len The number of bytes to copy.
   * @return The original buffer, for chaining.
   */
  function write(
    buffer memory buf,
    uint256 off,
    bytes memory data,
    uint256 len
  ) internal pure returns (buffer memory) {
    require(len <= data.length);

    if (off + len > buf.capacity) {
      resize(buf, max(buf.capacity, len + off) * 2);
    }

    uint256 dest;
    uint256 src;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Start address = buffer address + offset + sizeof(buffer length)
      dest := add(add(bufptr, 32), off)
      // Update buffer length if we're extending it
      if gt(add(len, off), buflen) {
        mstore(bufptr, add(len, off))
      }
      src := add(data, 32)
    }

    // Copy word-length chunks while possible
    for (; len >= 32; len -= 32) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += 32;
      src += 32;
    }

    // Copy remaining bytes
    unchecked {
      uint256 mask = (256**(32 - len)) - 1;
      assembly {
        let srcpart := and(mload(src), not(mask))
        let destpart := and(mload(dest), mask)
        mstore(dest, or(destpart, srcpart))
      }
    }

    return buf;
  }

  /**
   * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @param len The number of bytes to copy.
   * @return The original buffer, for chaining.
   */
  function append(
    buffer memory buf,
    bytes memory data,
    uint256 len
  ) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, len);
  }

  /**
   * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function append(buffer memory buf, bytes memory data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, data.length);
  }

  /**
   * @dev Writes a byte to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write the byte at.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function writeUint8(
    buffer memory buf,
    uint256 off,
    uint8 data
  ) internal pure returns (buffer memory) {
    if (off >= buf.capacity) {
      resize(buf, buf.capacity * 2);
    }

    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Address = buffer address + sizeof(buffer length) + off
      let dest := add(add(bufptr, off), 32)
      mstore8(dest, data)
      // Update buffer length if we extended it
      if eq(off, buflen) {
        mstore(bufptr, add(buflen, 1))
      }
    }
    return buf;
  }

  /**
   * @dev Appends a byte to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendUint8(buffer memory buf, uint8 data) internal pure returns (buffer memory) {
    return writeUint8(buf, buf.buf.length, data);
  }

  /**
   * @dev Writes up to 32 bytes to the buffer. Resizes if doing so would
   *      exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @param len The number of bytes to write (left-aligned).
   * @return The original buffer, for chaining.
   */
  function write(
    buffer memory buf,
    uint256 off,
    bytes32 data,
    uint256 len
  ) private pure returns (buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    unchecked {
      uint256 mask = (256**len) - 1;
      // Right-align data
      data = data >> (8 * (32 - len));
      assembly {
        // Memory address of the buffer data
        let bufptr := mload(buf)
        // Address = buffer address + sizeof(buffer length) + off + len
        let dest := add(add(bufptr, off), len)
        mstore(dest, or(and(mload(dest), not(mask)), data))
        // Update buffer length if we extended it
        if gt(add(off, len), mload(bufptr)) {
          mstore(bufptr, add(off, len))
        }
      }
    }
    return buf;
  }

  /**
   * @dev Writes a bytes20 to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function writeBytes20(
    buffer memory buf,
    uint256 off,
    bytes20 data
  ) internal pure returns (buffer memory) {
    return write(buf, off, bytes32(data), 20);
  }

  /**
   * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chhaining.
   */
  function appendBytes20(buffer memory buf, bytes20 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, bytes32(data), 20);
  }

  /**
   * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendBytes32(buffer memory buf, bytes32 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, 32);
  }

  /**
   * @dev Writes an integer to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @param len The number of bytes to write (right-aligned).
   * @return The original buffer, for chaining.
   */
  function writeInt(
    buffer memory buf,
    uint256 off,
    uint256 data,
    uint256 len
  ) private pure returns (buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    uint256 mask = (256**len) - 1;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Address = buffer address + off + sizeof(buffer length) + len
      let dest := add(add(bufptr, off), len)
      mstore(dest, or(and(mload(dest), not(mask)), data))
      // Update buffer length if we extended it
      if gt(add(off, len), mload(bufptr)) {
        mstore(bufptr, add(off, len))
      }
    }
    return buf;
  }

  /**
   * @dev Appends a byte to the end of the buffer. Resizes if doing so would
   * exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer.
   */
  function appendInt(
    buffer memory buf,
    uint256 data,
    uint256 len
  ) internal pure returns (buffer memory) {
    return writeInt(buf, buf.buf.length, data, len);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/**
 * @title Chainlink Functions client interface.
 */
interface FunctionsClientInterface {
  /**
   * @notice Returns the DON's secp256k1 public key used to encrypt secrets
   * @dev All Oracles nodes have the corresponding private key
   * needed to decrypt the secrets encrypted with the public key
   * @return publicKey DON's public key
   */
  function getDONPublicKey() external view returns (bytes memory);

  /**
   * @notice Chainlink Functions response handler called by the designated transmitter node in an OCR round.
   * @param requestId The requestId returned by FunctionsClient.sendRequest().
   * @param response Aggregated response from the user code.
   * @param err Aggregated error either from the user code or from the execution pipeline.
   * Either response or error parameter will be set, but never both.
   */
  function handleOracleFulfillment(
    bytes32 requestId,
    bytes memory response,
    bytes memory err
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "FunctionsBillingRegistryInterface.sol";

/**
 * @title Chainlink Functions oracle interface.
 */
interface FunctionsOracleInterface {
  /**
   * @notice Gets the stored billing registry address
   * @return registryAddress The address of Chainlink Functions billing registry contract
   */
  function getRegistry() external view returns (address);

  /**
   * @notice Sets the stored billing registry address
   * @param registryAddress The new address of Chainlink Functions billing registry contract
   */
  function setRegistry(address registryAddress) external;

  /**
   * @notice Returns the DON's secp256k1 public key that is used to encrypt secrets
   * @dev All nodes on the DON have the corresponding private key
   * needed to decrypt the secrets encrypted with the public key
   * @return publicKey the DON's public key
   */
  function getDONPublicKey() external view returns (bytes memory);

  /**
   * @notice Sets DON's secp256k1 public key used to encrypt secrets
   * @dev Used to rotate the key
   * @param donPublicKey The new public key
   */
  function setDONPublicKey(bytes calldata donPublicKey) external;

  /**
   * @notice Sets a per-node secp256k1 public key used to encrypt secrets for that node
   * @dev Callable only by contract owner and DON members
   * @param node node's address
   * @param publicKey node's public key
   */
  function setNodePublicKey(address node, bytes calldata publicKey) external;

  /**
   * @notice Deletes node's public key
   * @dev Callable only by contract owner or the node itself
   * @param node node's address
   */
  function deleteNodePublicKey(address node) external;

  /**
   * @notice Return two arrays of equal size containing DON members' addresses and their corresponding
   * public keys (or empty byte arrays if per-node key is not defined)
   */
  function getAllNodePublicKeys() external view returns (address[] memory, bytes[] memory);

  /**
   * @notice Determine the fee charged by the DON that will be split between signing Node Operators for servicing the request
   * @param data Encoded Chainlink Functions request data, use FunctionsClient API to encode a request
   * @param billing The request's billing configuration
   * @return fee Cost in Juels (1e18) of LINK
   */
  function getRequiredFee(bytes calldata data, FunctionsBillingRegistryInterface.RequestBilling calldata billing)
    external
    view
    returns (uint96);

  /**
   * @notice Estimate the total cost that will be charged to a subscription to make a request: gas re-imbursement, plus DON fee, plus Registry fee
   * @param subscriptionId A unique subscription ID allocated by billing system,
   * a client can make requests from different contracts referencing the same subscription
   * @param data Encoded Chainlink Functions request data, use FunctionsClient API to encode a request
   * @param gasLimit Gas limit for the fulfillment callback
   * @return billedCost Cost in Juels (1e18) of LINK
   */
  function estimateCost(
    uint64 subscriptionId,
    bytes calldata data,
    uint32 gasLimit,
    uint256 gasPrice
  ) external view returns (uint96);

  /**
   * @notice Sends a request (encoded as data) using the provided subscriptionId
   * @param subscriptionId A unique subscription ID allocated by billing system,
   * a client can make requests from different contracts referencing the same subscription
   * @param data Encoded Chainlink Functions request data, use FunctionsClient API to encode a request
   * @param gasLimit Gas limit for the fulfillment callback
   * @return requestId A unique request identifier (unique per DON)
   */
  function sendRequest(
    uint64 subscriptionId,
    bytes calldata data,
    uint32 gasLimit
  ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/**
 * @title Chainlink Functions billing subscription registry interface.
 */
interface FunctionsBillingRegistryInterface {
  struct RequestBilling {
    // a unique subscription ID allocated by billing system,
    uint64 subscriptionId;
    // the client contract that initiated the request to the DON
    // to use the subscription it must be added as a consumer on the subscription
    address client;
    // customer specified gas limit for the fulfillment callback
    uint32 gasLimit;
    // the expected gas price used to execute the transaction
    uint256 gasPrice;
  }

  /**
   * @notice Get configuration relevant for making requests
   * @return uint32 global max for request gas limit
   * @return address[] list of registered DONs
   */
  function getRequestConfig() external view returns (uint32, address[] memory);

  /**
   * @notice Determine the charged fee that will be paid to the Registry owner
   * @param data Encoded Chainlink Functions request data, use FunctionsClient API to encode a request
   * @param billing The request's billing configuration
   * @return fee Cost in Juels (1e18) of LINK
   */
  function getRequiredFee(bytes calldata data, FunctionsBillingRegistryInterface.RequestBilling memory billing)
    external
    view
    returns (uint96);

  /**
   * @notice Estimate the total cost to make a request: gas re-imbursement, plus DON fee, plus Registry fee
   * @param gasLimit Encoded Chainlink Functions request data, use FunctionsClient API to encode a request
   * @param gasPrice The request's billing configuration
   * @param donFee Fee charged by the DON that is paid to Oracle Node
   * @param registryFee Fee charged by the DON that is paid to Oracle Node
   * @return costEstimate Cost in Juels (1e18) of LINK
   */
  function estimateCost(
    uint32 gasLimit,
    uint256 gasPrice,
    uint96 donFee,
    uint96 registryFee
  ) external view returns (uint96);

  /**
   * @notice Initiate the billing process for an Functions request
   * @param data Encoded Chainlink Functions request data, use FunctionsClient API to encode a request
   * @param billing Billing configuration for the request
   * @return requestId - A unique identifier of the request. Can be used to match a request to a response in fulfillRequest.
   * @dev Only callable by a node that has been approved on the Registry
   */
  function startBilling(bytes calldata data, RequestBilling calldata billing) external returns (bytes32);

  /**
   * @notice Finalize billing process for an Functions request by sending a callback to the Client contract and then charging the subscription
   * @param requestId identifier for the request that was generated by the Registry in the beginBilling commitment
   * @param response response data from DON consensus
   * @param err error from DON consensus
   * @param transmitter the Oracle who sent the report
   * @param signers the Oracles who had a part in generating the report
   * @param signerCount the number of signers on the report
   * @param reportValidationGas the amount of gas used for the report validation. Cost is split by all fulfillments on the report.
   * @param initialGas the initial amount of gas that should be used as a baseline to charge the single fulfillment for execution cost
   * @return success whether the callback was successsful
   * @dev Only callable by a node that has been approved on the Registry
   * @dev simulated offchain to determine if sufficient balance is present to fulfill the request
   */
  function fulfillAndBill(
    bytes32 requestId,
    bytes calldata response,
    bytes calldata err,
    address transmitter,
    address[31] memory signers, // 31 comes from OCR2Abstract.sol's maxNumOracles constant
    uint8 signerCount,
    uint256 reportValidationGas,
    uint256 initialGas
  ) external returns (bool success);

  /**
   * @notice Gets subscription owner.
   * @param subscriptionId - ID of the subscription
   * @return owner - owner of the subscription.
   */
  function getSubscriptionOwner(uint64 subscriptionId) external view returns (address owner);
}

// SPDX-License-Identifier: MIT 

// IFunctionsConsumer.sol

import "FunctionsClient.sol";

pragma solidity ^0.8.0;


interface IFunctionsConsumer {

    function executeRequest(
        string calldata source,
        bytes calldata secrets,
        Functions.Location secretsLocation,
        string[] calldata args,
        uint64 subscriptionId,
        uint32 gasLimit
    ) external returns (bytes32);

    function getLatestReponseAndError() external view returns(bytes memory response, bytes memory err);

    function updateOracleAddress(address oracle) external;
}