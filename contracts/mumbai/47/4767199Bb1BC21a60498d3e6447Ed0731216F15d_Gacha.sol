// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./EnumerableSet.sol";
import "./Counters.sol";
import "./IERC1155.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./TransferHelper.sol";
import "./SafeMath.sol";
import "./IChallenge.sol";
import "./IERC20.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./IVRFConsumerBase.sol";
import "./AccessControlUpgradeable.sol";

contract Gacha is Initializable, IERC721Receiver, AccessControlUpgradeable, UUPSUpgradeable {
    // Import necessary libraries
    // EnumerableSet for managing sets of addresses and uints
    using EnumerableSet for EnumerableSet.AddressSet;
    // Counters for managing the count of tokens
    using Counters for Counters.Counter;
    // SafeMath for safe arithmetic operations to prevent integer overflow or underflow
    using SafeMath for uint256;

    // Enum defining the types of tokens that can be used in the system
    enum TypeToken { ERC20, ERC721, ERC1155, NATIVE_TOKEN }

    // Enum defining the statuses for a dividend payout
    enum DividendStatus { DIVIDEND_PENDING, DIVIDEND_SUCCESS, DIVIDEND_FAIL }

    // Enum defining the states of a challenge
    enum ChallengeState { PROCESSING, SUCCESS, FAILED, GAVE_UP, CLOSED }

    // Enum defining the types of requirements for NFT balances
    enum TypeRequireBalanceNft { REQUIRE_BALANCE_WALLET, REQUIRE_BALANCE_CONTRACT, REQUIRE_BALANCE_ALL }

    /*
     * There are two types:
     * - NORMAL_RANDOM_NUMBER: Uses a normal random number generator
     * - VRF_CHAINLINK_RANDOM_NUMBER: Uses the Chainlink VRF (Verifiable Random Function) 
    */
    enum TypeRandomReward { NORMAL_RANDOM_NUMBER, VRF_CHAINLINK_RANDOM_NUMBER }
    
    /**
     * Definition of TimeRandomReward enum
     * 
     * - RANDOM_ONLY_TIME: only allowed to receive a random reward once during the specified time period
     * - RANDOM_MUTIPLE_TIME: allowed to receive random rewards multiple times during the specified time period
    */
    enum TimeRandomReward { RANDOM_ONLY_TIME, RANDOM_MUTIPLE_TIME } 
    
    /**
     * @dev This struct defines the properties of a RewardToken.
     * @param addressToken The address of the token to be rewarded.
     * @param unlockRate The unlock rate of the token.
     * @param rewardValue The reward value of the token.
     * @param indexToken The index of the token.
     * @param typeToken The type of the token.
     * @param isMintNft A boolean value to determine whether the token is an NFT.
    */
    struct RewardToken{
        address addressToken;
        uint256 unlockRate;
        uint256 rewardValue;
        uint256 indexToken;
        TypeToken typeToken;
        bool isMintNft;
    }
    
    /**
     * @dev Struct to store information about a challenge.
     * @param targetStepPerDay The target step count per day for the challenge.
     * @param challengeDuration The duration of the challenge in days.
     * @param stepDataToSend The step count data to send for the challenge.
     * @param toleranceAmount The amount of tolerance allowed for the challenge.
     *  @param dividendStatus The status of dividend for the challenge.
     * @param amountBaseDeposit The amount of base deposit for the challenge.
     * @param amountTokenDeposit The amount of token deposit for the challenge.
     * @param timeLimitActiveGacha The time limit for the active gacha instance for the challenge.
     * @param typeRequireBalanceNft The type of required balance NFT for the challenge.
    */
    struct ChallengeInfo{
        uint256 targetStepPerDay;
        uint256 challengeDuration;
        uint256 stepDataToSend;
        uint256 toleranceAmount;
        DividendStatus dividendStatus;
        uint256 amountBaseDeposit;
        uint256 amountTokenDeposit;
        uint256 timeLimitActiveGacha;
        TypeRequireBalanceNft typeRequireBalanceNft;
    }
    
    /**
     * @dev User information struct to store information about user's reward status.
     * @param statusRandom The status of user reward random.
     * @param indexReward The index of user reward.
     * @param indexToken The index of reward token.
     * @param tokenAddress The address of reward token.
     * @param rewardValue The value of reward.
     * @param nameReward The name of reward.
    */
    struct UserInfor{
        bool statusRandom;
        uint256 indexReward;
        uint256 indexToken;
        address tokenAddress;
        uint256 rewardValue;
        string nameReward;
    }
    
    /**
     * @dev Event emitted when a new reward is added to a gacha.
     * @param _addressToken The address of the token to be rewarded.
     * @param _unlockRate The rate at which the reward will be unlocked.
     * @param _typeToken The type of token to be rewarded.
     * @param _gachaAddress The address of the gacha the reward is being added to.
    */
    event AddNewReward(address indexed _addressToken, uint256 _unlockRate, TypeToken _typeToken, address _gachaAddress);
    
    /**
     * @dev Event emitted when a reward is deleted from a gacha.
     * @param _caller The address of the caller who deleted the reward.
     * @param _indexOfTokenReward The index of the reward being deleted.
     * @param _gachaAddress The address of the gacha the reward is being deleted from.
    */
    event DeleteReward(address indexed _caller, uint256 _indexOfTokenReward, address _gachaAddress);
    
    /**
     * @dev Event emitted when a daily result is sent for a gacha.
     * @param _caller The address of the caller who sent the daily result.
     * @param _gachaAddress The address of the gacha the daily result is being sent for.
    */
    event SendDailyResultGacha(address indexed _caller, address _gachaAddress);
    
    /**
     * @dev Event emitted when a challenge is closed for a gacha.
     * @param _caller The address of the caller who closed the challenge.
     * @param _gachaAddress The address of the gacha the challenge is being closed for.
    */
    event CloseGacha(address indexed _caller, address _gachaAddress);

    // Mapping to store information about reward tokens
    mapping(uint256 => RewardToken) public rewardTokens;

    // Counter to keep track of total number of rewards
    Counters.Counter private totalNumberReward; 

    // Mapping to keep track if the daily result has been sent with a specific gacha contract
    mapping(address => mapping(address => bool)) public isSendDailyResultWithGacha;

    // Array to store IDs of all tokens
    uint256[] private listIdToken;

    // Mapping to store user information
    mapping(address => UserInfor) public userInfor;

    // Struct to store challenge information
    ChallengeInfo public challengeInfo;

    // Set of addresses for required balance NFTs
    EnumerableSet.AddressSet private requireBalanceNftAddress;

    // Mapping to store whether an NFT is a required balance NFT
    mapping(address => bool) public typeNfts;

    // Boolean to check if the default gacha contract is being used
    bool public isDefaultGachaContract;

    // Name of the gacha game
    string public gachaName;

    // Sponsor of the gacha game
    string public gachaSponsor;

    // Boolean to check if the gacha game is closed
    bool public iscloseGacha;

    // Address of the wallet where returned NFTs are transferred to
    address public returnedNFTWallet;

    // Mapping to keep track of the number of times a gacha contract is activated
    mapping(address => mapping(uint256 => uint256)) public countTimeActiveGacha;

    // The type of random reward to be used
    TypeRandomReward public typeRandomReward;
    
    // The type of time-based random reward to be used
    TimeRandomReward public timeRandomReward;

    // Two different VRFConsumerBase contracts are used for different types of random reward generation
    // This address points to the VRFConsumerBase contract for RANDOM_MUTIPLE_TIME type
    address public VRFConsumerBaseMultipleTime;
    
    // This address points to the VRFConsumerBase contract for RANDOM_ONLY_TIME type
    address public VRFConsumerBaseOnlyTime;

    // The address of the contract containing the RandomNumberClassic interface, which is used to call the getRandomNumber function
    address public randomClassicAddress;
    
    // A public variable to store the address of the wallet that will receive the funds
    address public receiveAdminWallet;

    // Define the role that can upgrade the contract
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE"); 
    
    // Define the role that can update gacha reward 
    bytes32 public constant UPDATER_REWARDS_ROLE = keccak256("UPDATER_REWARDS_ROLE"); 
    
    // Define the role that can update contract activities
    bytes32 public constant UPDATER_ACTIVITIES_ROLE = keccak256("UPDATER_ACTIVITIES_ROLE"); 

    // Define the role that can close gạcha
    bytes32 public constant CLOSE_GACHA_ROLE = keccak256("CLOSE_GACHA_ROLE");
    
    /**
     * @dev Initialize the contract with ChallengeInfo and other necessary data.
     * @param _challengeInfo Challenge information including the target steps, duration, etc.
     * @param _requireBalanceNftAddress An array of addresses for the required balance NFTs for participating in the challenge.
     * @param _typeNfts An array of boolean values indicating whether the NFT at the corresponding index in _requireBalanceNftAddress is a Type 1 or Type 2 NFT.
     * @param _rateOfLost The rate at which rewards decrease with each passing day without submitting step count data.
     * @param _isDefaultGachaContract A boolean value indicating whether the contract is the default Gacha contract or not.
     * @param _gachaName The name of the Gacha contract.
     * @param _gachaSponsor The sponsor of the Gacha contract.
    */
    function initialize(
        ChallengeInfo memory _challengeInfo, 
        address[] memory _requireBalanceNftAddress, 
        bool[] memory _typeNfts,
        uint256 _rateOfLost,
        bool _isDefaultGachaContract,
        TypeRandomReward _typeRandomReward,
        TimeRandomReward _timeRandomReward,
        address _VRFConsumerBaseMultipleTime,
        address _VRFConsumerBaseOnlyTime,
        address[] memory receiveWallet,
        string memory _gachaName,
        string memory _gachaSponsor
    ) external initializer {
        // Call the parent contract's initializer.
        __UUPSUpgradeable_init(); 
        __AccessControl_init(); 
        
        // Set the required balance NFT addresses and their corresponding types
        require(_requireBalanceNftAddress.length == _typeNfts.length, "INVALID REQUIRE BALANCE NFT ADDRESS.");
        challengeInfo = _challengeInfo;
        for(uint256 i = 0; i < _requireBalanceNftAddress.length; i++) {
            requireBalanceNftAddress.add(_requireBalanceNftAddress[i]);
            typeNfts[_requireBalanceNftAddress[i]] = _typeNfts[i];
        }

        // Set the default gacha contract flag
        isDefaultGachaContract = _isDefaultGachaContract;

        // Set the name of the gacha
        gachaName = _gachaName;

        // Set the sponsor of the gacha
        gachaSponsor = _gachaSponsor;
        
        // Grant roles to specified addresses
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(UPDATER_REWARDS_ROLE, msg.sender);
        _grantRole(UPDATER_ACTIVITIES_ROLE, msg.sender);
        _grantRole(CLOSE_GACHA_ROLE, msg.sender);

        // Set the rate of lost rewards for reward
        rewardTokens[0].unlockRate = _rateOfLost; 

        // Set the type of random reward to be used
        typeRandomReward = _typeRandomReward;

        // Set the type of time-based random reward to be used
        timeRandomReward = _timeRandomReward;

        // Assigns new values to VRFConsumerBaseMultipleTime and VRFConsumerBaseOnlyTime
        VRFConsumerBaseMultipleTime = _VRFConsumerBaseMultipleTime;
        VRFConsumerBaseOnlyTime = _VRFConsumerBaseOnlyTime;

        // Set the receiveWallet wallet address
        returnedNFTWallet = receiveWallet[0];
        receiveAdminWallet = receiveWallet[1];
    }
    
    /**
     * @dev function to be able to accept native currency of the network.
     * @dev Fallback function to receive ETH payments.
    */
    receive() external payable 
    {

    }

    /**
     * @dev Function to generate random rewards for the user who has completed the daily step challenge.
     * @param _challengeAddress The address of the daily step challenge contract.
     * @return A boolean value indicating whether the function was successful or not.
    */
    function randomRewards(
        address _challengeAddress, 
        uint256[] memory _dataStep
    ) external returns(bool) {
        // Modifier to restrict access to only admins
        require(
            !isSendDailyResultWithGacha[msg.sender][_challengeAddress], 
            "ALREADY SEND DAILY RESULT WITH GACHA CONTRACT."
        );

        // Modifier only challenge address can call function
        require(
            _challengeAddress == msg.sender, 
            "ONLY CHALLENGE CONTRACT CAN CALL SEND DAILY RESULT WITH GACHA."
        );
        
        // Get the address of the challenger from the challenge contract
        address challengerAddress = IChallenge(_challengeAddress).challenger();

        // Get the address of the challenger from the challenge contract
        uint256 currentDate = block.timestamp.div(86400);

        // Check if the number of times the challenger has activated gacha on the current date has not exceeded the limit set in the challengeInfo
        require(
            countTimeActiveGacha[challengerAddress][currentDate] < challengeInfo.timeLimitActiveGacha,
            "THE NUMBER OF ACTIVE GACHA TIMES IN A DAY HAS EXCEEDED THE LIMIT."
        );

        // Increase the count of active gacha times for the current date of the challenger
        countTimeActiveGacha[challengerAddress][currentDate] = countTimeActiveGacha[challengerAddress][currentDate].add(1);

        // Initialize a new UserInfor object for the challenger
        UserInfor memory newUserInfor;
        userInfor[challengerAddress] = newUserInfor;

        // Set a flag to indicate whether the challenger won the prize or not
        bool isWonThePrize = false;

        /**
        * Check if the challenger has the required balance NFTs to participate in the gacha
        * and the NFT type is in the list of required NFT types
        * If not, return false and the gacha result will be skipped
        * Otherwise, continue to the next step
        */
        if(checkRequireBalanceNft(_challengeAddress, _dataStep)) {
            // Generate a random index for the reward
            uint256 randomIndexReward = checkAbilityReward();

            /**
            * If the random index reward is not equal to 0 (which means the user has the ability to win a reward),
            * then the function proceeds to the next steps to select and distribute the reward.
            */
            if(randomIndexReward != 0) {
                // Get the index of the selected reward token
                uint256 indexTokenReward;

                // Get the selected reward token's information from the rewardTokens mapping
                RewardToken memory currentRewardToken = rewardTokens[randomIndexReward];

                // Get the address of the selected reward token
                address currentTokenAddress = currentRewardToken.addressToken;
                
                // Check if the current reward token is an ERC20 token
                if(currentRewardToken.typeToken == TypeToken.ERC20) {
                    // Transfer the ERC20 token reward to the challenger's address
                    TransferHelper.safeTransfer(
                        currentTokenAddress,
                        challengerAddress,
                        currentRewardToken.rewardValue
                    );
                }
                
                // If the reward token type is ERC721
                if(currentRewardToken.typeToken == TypeToken.ERC721) {
                    // Get the next available token ID to mint
                    uint256 currentIndexNFT = IChallenge(currentTokenAddress).nextTokenIdToMint();

                    // If the reward is to mint a new NFT
                    if(currentRewardToken.isMintNft) {
                        // Mint a new NFT
                        IChallenge(IChallenge(_challengeAddress).erc721Address(0)).safeMintNFT721Heper(
                            currentTokenAddress,
                            challengerAddress
                        );
                        // Set the reward index to the newly minted token ID
                        indexTokenReward = currentIndexNFT;
                    } else {
                        /**
                        * If the reward is to transfer an existing NFT
                        * Loop through all available token IDs
                        */
                        for(uint256 j = 0; j < currentIndexNFT; j++) {
                            // If the token is owned by the Gacha contract
                            if(IChallenge(currentTokenAddress).ownerOf(j) == address(this)) {
                                TransferHelper.safeTransferFrom(
                                    currentTokenAddress,
                                    address(this),
                                    challengerAddress,
                                    j
                                );
                                // Set the reward index to the transferred token ID
                                indexTokenReward = j;
                                break;
                            }
                        }
                    }   
                }

                // Checks if the token is of type ERC1155
                if(currentRewardToken.typeToken == TypeToken.ERC1155) {
                    // If the token is to be minted, mint it using the safeMintNFT1155Heper function in the challenge's ERC721 contract
                    if(currentRewardToken.isMintNft) {
                        IChallenge(IChallenge(_challengeAddress).erc721Address(0)).safeMintNFT1155Heper(
                            currentTokenAddress, // The address of the ERC1155 token contract
                            challengerAddress, // The address of the challenger who won the reward
                            currentRewardToken.indexToken, // The index of the token to be minted
                            currentRewardToken.rewardValue // The reward value of the token
                        );
                    } else {
                        // If the token is not to be minted, transfer it from the contract address to the challenger's address using the safeTransferNFT1155 function
                        TransferHelper.safeTransferNFT1155(
                            currentTokenAddress, // The address of the ERC1155 token contract
                            address(this), // The address of the contract
                            challengerAddress, // The address of the challenger who won the reward
                            currentRewardToken.indexToken, // The index of the token to be transferred
                            currentRewardToken.rewardValue, // The reward value of the token
                            "ChallengeApp" // The data to be passed along with the transaction
                        );
                    }

                    // Set the index of the token reward to the current reward token's index
                    indexTokenReward = currentRewardToken.indexToken;
                }
                
                // Check if the reward token is of type native token (ETH)
                // Transfer the reward value in ETH to the challenger address
                if(currentRewardToken.typeToken == TypeToken.NATIVE_TOKEN){
                    TransferHelper.saveTransferEth(
                        payable(challengerAddress),
                        currentRewardToken.rewardValue
                    );
                }

                // Set isWonThePrize to true to indicate that the user has won a prize
                isWonThePrize = true;
                
                // Determine the name of the token, depending on whether it's a native token or an ERC20/ERC721/ERC1155 token
                string memory tokenName;
                if(currentRewardToken.typeToken == TypeToken.NATIVE_TOKEN) {
                    tokenName = "Native Token";
                } else {
                    tokenName = IChallenge(currentTokenAddress).name();
                }

                // Store the user's information into the userInfor mapping
                userInfor[challengerAddress] = UserInfor(
                    true, // Set the user's flag to indicate that they have won the challenge
                    randomIndexReward, // Store the index of the reward token that the user has won
                    indexTokenReward, // Store the index of the specific token within the ERC721/ERC1155 contract that the user has won (if applicable)
                    currentTokenAddress, // Store the address of the token that the user has won
                    currentRewardToken.rewardValue, // Store the amount of the token that the user has won
                    tokenName // Store the name of the token that the user has won
                );
            } 
        }
        
        // If the user won the prize and the challenge is finished, mark the user as having received the daily result with gacha for this challenge
        if(isWonThePrize && IChallenge(_challengeAddress).isFinished()){
            isSendDailyResultWithGacha[msg.sender][_challengeAddress] = true;
        }
        
        // Emit an event indicating that the daily result with gacha has been sent to the user
        emit SendDailyResultGacha(msg.sender, address(this));

        // Return whether the user won the prize or not
        return isWonThePrize;
    } 
    
    /**
     * This function is used by the admin to close the current gacha.
     * It is only callable by the admin address. Once the gacha is closed,
     * users will not be able to participate in it anymore.
     * After closing the gacha, the admin can distribute the prizes to the winners.
    */
    function closeGacha() external onlyRole(CLOSE_GACHA_ROLE) {
        // Make sure that the gacha is not already closed
        require(!iscloseGacha, "GACHA ALREADY CLOSE.");

        // Make sure that the address for returned NFT wallet is set up
        require(returnedNFTWallet != address(0), "RETURNED NFT WALLET NOT YET SET UP.");

        // Loop through each token ID in the list of token IDs
        for(uint256 i = 0; i < listIdToken.length; i++) {
            // Get the reward token associated with the current token ID
            RewardToken memory currentRewardToken = rewardTokens[listIdToken[i]];

            // Get the address of the token for the current reward token
            address tokenAddress = currentRewardToken.addressToken;

            // Check if the current reward token is not an ERC1155 mintable NFT, execute the following block of code if true
            if(!currentRewardToken.isMintNft) {
                // Check if currentRewardToken is not an ERC1155 token
                if(currentRewardToken.typeToken != TypeToken.ERC1155) {
                    // Check if currentRewardToken is a native token (ETH)
                    if(currentRewardToken.typeToken == TypeToken.NATIVE_TOKEN) {
                        // Transfer ETH to the returnedNFTWallet
                        TransferHelper.saveTransferEth(
                            payable(returnedNFTWallet),
                            address(this).balance
                        );
                    } else {
                        // Get the balance of tokens held by this contract
                        uint256 balanceToken = IERC20(tokenAddress).balanceOf(address(this));

                        // Check if there are tokens held by this contract
                        if(balanceToken > 0) {
                            // Check if currentRewardToken is an ERC20 token
                            if(currentRewardToken.typeToken == TypeToken.ERC20) {
                                // Transfer the ERC20 tokens to the returnedNFTWallet
                                TransferHelper.safeTransfer(
                                    tokenAddress,
                                    returnedNFTWallet,
                                    balanceToken
                                );
                            }

                            // Check if currentRewardToken is an ERC721 token
                            if(currentRewardToken.typeToken == TypeToken.ERC721) {
                                // Get the next token ID to mint
                                uint256 currentIndexNFT = IChallenge(tokenAddress).nextTokenIdToMint();
                                // Loop through each token ID
                                for(uint256 j = 0; j < currentIndexNFT; j++) {
                                    // Check if the contract is the owner of the token
                                    if(IChallenge(tokenAddress).ownerOf(j) == address(this)) {
                                        // Transfer the ERC721 token to the returnedNFTWallet
                                        TransferHelper.safeTransferFrom(
                                            tokenAddress,
                                            address(this),
                                            returnedNFTWallet,
                                            j
                                        );
                                    }
                                }
                            }
                        }
                    }
                } else {
                    // Get the balance of the ERC1155 token with the given index token for the current 
                    uint256 balanceTokenERC1155 = IERC1155(tokenAddress).balanceOf(address(this), currentRewardToken.indexToken);

                    // Check if the balance is greater than 0
                    if(balanceTokenERC1155 > 0) {
                        // Safely transfer the ERC1155 token to the returned NFT wallet using the TransferHelper library
                        TransferHelper.safeTransferNFT1155(
                            tokenAddress,
                            address(this),
                            returnedNFTWallet,
                            currentRewardToken.indexToken,
                            balanceTokenERC1155,
                            "ChallengeApp"
                        );   
                    }
                }
            }
        }
        
        // Set iscloseGacha flag to true
        iscloseGacha = true;
        
        // Emit an event to notify listeners that the challenge has been closed
        emit CloseGacha(msg.sender, address(this));
    }  
    
    /**
     * @dev Function to add a new reward to the list of available rewards.
     * @param _addressToken The address of the token to be used as a reward.
     * @param _unlockRate The unlock rate for the reward.
     * @param _rewardValue The amount of the reward to be distributed.
     * @param _indexToken The index of the reward token.
     * @param _typeToken The type of token used as a reward.
     * @param _isMintNft A boolean indicating whether the reward is an NFT that should be minted.
    */
    function addNewReward(
        address _addressToken,
        uint256 _unlockRate,
        uint256 _rewardValue,
        uint256 _indexToken,
        TypeToken _typeToken,
        bool _isMintNft
    ) external onlyRole(UPDATER_REWARDS_ROLE) {
        /**
        * Revert the transaction if the token address is zero and the token type is not a native token,
        * or if the token address is not zero and the token type is a native token.
        */
        if(
            _addressToken == address(0) && _typeToken != TypeToken.NATIVE_TOKEN ||
            _addressToken != address(0) && _typeToken == TypeToken.NATIVE_TOKEN
        ) {
            revert("ZERO ADDRESS.");
        }
        
        // Require the reward value to be greater than zero.
        require(_rewardValue > 0, "INVALID REWARD VALUE.");

        // Find the first empty slot in the list of rewards.
        uint256 indexOfTokenReward = 0;
        
        for(uint256 i = 1; i <= totalNumberReward.current(); i++) {
            if(
                rewardTokens[i].addressToken == address(0) && 
                rewardTokens[i].typeToken != TypeToken.NATIVE_TOKEN
            ) {
                indexOfTokenReward = i;
                break;
            }
        }

        // If there is no empty slot, increment the total number of rewards and use the new index.
        if(indexOfTokenReward == 0 ){
            totalNumberReward.increment();
            indexOfTokenReward = totalNumberReward.current();
        }
        
        // Add the new reward to the list of rewards and update the list of reward IDs.
        addReward(indexOfTokenReward, _addressToken, _unlockRate, _rewardValue, _indexToken, _typeToken, _isMintNft);
        listIdToken.push(indexOfTokenReward);

        // Emit an event to notify listeners that a new reward has been added.
        emit AddNewReward(_addressToken, _unlockRate, _typeToken, address(this));
    }

    /**
     * @dev Function to delete a token reward by its index.
     * @param _indexOfTokenReward Index of the token reward to be deleted.
    */
    function deleteReward(
        uint256 _indexOfTokenReward
    ) external onlyRole(UPDATER_REWARDS_ROLE) {
        // Loop through the list of token IDs to check if the given index of token reward exists
        bool isExistIndexToken = false;
        for(uint256 i = 0; i < listIdToken.length; i++) {
            if(_indexOfTokenReward == listIdToken[i]) {
                isExistIndexToken = true;
                break;
            }
        }
        
        // statement to ensure that the specified index of the reward token exists in the list of reward tokens
        require(isExistIndexToken, "INDEX OF TOKEN REWARD NOT EXIST.");
        
        // Delete the reward token from the rewardTokens mapping
        delete rewardTokens[_indexOfTokenReward];

        /**
        * Loop through the list of reward token IDs and find the index of the reward token to be deleted
        * Then replace the deleted token with the last token in the list and remove the last element of the list
        */
        for(uint256 i = 0; i < listIdToken.length; i++) {
            if(listIdToken[i] == _indexOfTokenReward) {
                listIdToken[i] = listIdToken[listIdToken.length.sub(1)];
            }
        }

        // Remove the last element from the list of token IDs
        listIdToken.pop();

        // Emit an event to signal that a reward has been deleted
        emit DeleteReward(msg.sender, _indexOfTokenReward, address(this));
    }

    /**
     * @dev Updates the challenge information.
     * @param _challengeInfo The new challenge information.
    */
    function updateChallengeInfor(
        ChallengeInfo memory _challengeInfo
    ) external onlyRole(UPDATER_ACTIVITIES_ROLE) {
        challengeInfo = _challengeInfo;
    }
    
    /**
     * @dev Updates the rate of lost rewards.
     * @param _rateOfLost The new rate of lost rewards.
    */
    function updateRateOfLost(
        uint256 _rateOfLost
    ) external onlyRole(UPDATER_ACTIVITIES_ROLE) {
        require(_rateOfLost > 0, "RATE OF LOST IS INVALID.");
        rewardTokens[0].unlockRate = _rateOfLost;
    }

    /**
     * @dev Updates the status of the default gacha contract flag.
     * @param _isDefaultGachaContract The new status of the flag.
    */
    function updateStatusDefaultGachaContract(
        bool _isDefaultGachaContract
    ) external onlyRole(UPDATER_ACTIVITIES_ROLE) {
         // Require that the new status is not equal to the current status.
        require(isDefaultGachaContract != _isDefaultGachaContract, "THIS STATUS HAS BEEN SETTING.");

        // Update the status.
        isDefaultGachaContract = _isDefaultGachaContract;
    }
    
    /**
     * This function updates the address of the wallet where returned NFTs will be sent.
     * It can only be called by the current returned NFT wallet address or if there is no current returned NFT wallet address set.
     * The new address must not be the zero address.
    */
    function updateReturnedNFTWallet(
        address _returnedNFTWallet
    ) external onlyRole(UPDATER_ACTIVITIES_ROLE) {
        require(
            _returnedNFTWallet != address(0), 
            "INVALID RETURNED NFT WALLET ADDRESS."
        );
        returnedNFTWallet = _returnedNFTWallet;
    }

    /**
     * @dev Updates the address of the wallet to receive administrative fees.
     * @param _receiveAdminWallet The new wallet address to receive administrative fees.
     * @notice Only the default admin role is allowed to call this function.
     * @notice Throws an error if the new address is invalid.
     */
    function updateReceiveAdminWallet(
        address _receiveAdminWallet
    ) public onlyRole(UPDATER_ACTIVITIES_ROLE) {
        require(
            _receiveAdminWallet != address(0),
            "RECEIVE ADMIN WALLET IS NOT INVALID"
        );
        receiveAdminWallet = _receiveAdminWallet;
    }
    
    /**
     * @dev Update the name and sponsor of the gacha.
     * @param _gachaName The new name of the gacha.
     * @param _gachaSponsor The new sponsor of the gacha.
    */
    function updateGachaNameAndGachaSponsor(
        string memory _gachaName, 
        string memory _gachaSponsor
    ) external onlyRole(UPDATER_REWARDS_ROLE) {
        gachaName = _gachaName;
        gachaSponsor = _gachaSponsor;
    }

    /**
     * @dev This function sets the type of random reward in the contract.
     * Only the admin is authorized to call this function.
     * @param _typeRandomReward The type of random reward to set.
     * @param _timeRandomReward The TimeRandomReward enum value to set
    */
    function setTypeRandomReward(
        TypeRandomReward _typeRandomReward, 
        TimeRandomReward _timeRandomReward
    ) external onlyRole(UPDATER_ACTIVITIES_ROLE) {
        typeRandomReward = _typeRandomReward;
        timeRandomReward = _timeRandomReward;
    }
    
    /**
     * @dev Sets the VRF consumer base addresses for both `VRFConsumerBaseMultipleTime`
     * and `VRFConsumerBaseOnlyTime` used to generate random numbers using Chainlink VRF.
     * @param _VRFConsumerBaseMultipleTime The VRF consumer base address for multiple-time gachas.
     * @param _VRFConsumerBaseOnlyTime The VRF consumer base address for only-time gachas.
     * @param _randomClassicAddress The address of the contract that generates random numbers using the classic method.
     * Requirements:
     * - `_VRFConsumerBaseMultipleTime`, `_VRFConsumerBaseOnlyTime`, and `_randomClassicAddress` cannot be zero addresses.
    */
    function setVRFConsumerBase(
        address _VRFConsumerBaseMultipleTime,
        address _VRFConsumerBaseOnlyTime,
        address _randomClassicAddress
    ) external onlyRole(UPDATER_ACTIVITIES_ROLE) {
        require(
            _VRFConsumerBaseMultipleTime != address(0) &&
            _VRFConsumerBaseOnlyTime != address(0) && 
            _randomClassicAddress != address(0),
            "VRF CONSUMER BASE IS INVALID."
        );
        VRFConsumerBaseMultipleTime = _VRFConsumerBaseMultipleTime;
        VRFConsumerBaseOnlyTime = _VRFConsumerBaseOnlyTime;
        randomClassicAddress = _randomClassicAddress;
    }

    /**
     * @dev Update the list of NFT addresses that must be held by the user in order to participate in the Gacha game.
     * @param _nftAddress Address of the NFT contract.
     * @param _flag Flag indicating whether the address of the NFT contract should be added or removed from the list.
     * @param _isTypeErc721 Boolean indicating whether the NFT contract is of type ERC721 or ERC1155.
     * @notice Only the admin can call this function.
    */
    function updateRequireBalanceNftAddress(
        address _nftAddress, 
        bool _flag, 
        bool _isTypeErc721
    ) external onlyRole(UPDATER_ACTIVITIES_ROLE) {
        require(_nftAddress != address(0), "INVALID NFT ADDRESS.");
        if (_flag) {
            requireBalanceNftAddress.add(_nftAddress);
        } else {
            requireBalanceNftAddress.remove(_nftAddress);
        }
        typeNfts[_nftAddress] = _isTypeErc721;
    }

    /**
     * @dev Add a reward token with the specified parameters to the rewardTokens mapping.
     * @param _indexOfTokenReward The index of the reward token to add.
     * @param _addressToken The address of the reward token contract.
     * @param _unlockRate The unlock rate of the reward token.
     * @param _rewardValue The reward value of the reward token.
     * @param _indexToken The index of the reward token in the listIdToken array.
     * @param _typeToken The type of the reward token.
     * @param _isMintNft Whether or not the reward token is an NFT that needs to be minted.
    */
    function addReward(
        uint256 _indexOfTokenReward,
        address _addressToken,
        uint256 _unlockRate,
        uint256 _rewardValue,
        uint256 _indexToken,
        TypeToken _typeToken,
        bool _isMintNft
    ) private {
        // Set the new reward token at the given index
        rewardTokens[_indexOfTokenReward] = RewardToken(
            _addressToken,
            _unlockRate,
            _rewardValue,
            _indexToken,
            _typeToken,
            _isMintNft
        );
    }

    /**
     * @dev Check if the reward conditions are met for the given challenge address
     * @param _challengeAddress The address of the challenge to check reward conditions for
     * @return A boolean indicating whether the reward conditions are met
    **/
    function checkRewardConditions(
        address _challengeAddress, 
        uint256[] memory _dataStep
    ) private view returns(bool) {
        /**
        @dev Retrieve the duration of the challenge from the IChallenge contract
        @param _challengeAddress The address of the challenge to retrieve information from
        @return uint256 representing the duration of the challenge
        */
        uint256 challengeDuration = IChallenge(_challengeAddress).duration();

        /**
        @dev Store the current challenge information in memory
        @param challengeInfo The struct containing the information about the current challenge  
        */
        ChallengeInfo memory currentChallengeInfo = challengeInfo;

        // Check if the target steps per day for the current challenge is less than or equal to the goal of the new challenge
        if(currentChallengeInfo.targetStepPerDay <= IChallenge(_challengeAddress).goal()){
            /**
            @dev Checks if the current challenge's duration is less than or equal to the challenge's duration of the given challenge address.
            @param _challengeAddress The address of the challenge contract to compare the duration with.
            @return A boolean indicating whether the current challenge's duration is less than or equal to the challenge's duration of the given challenge address.
            */
            if(currentChallengeInfo.challengeDuration <= challengeDuration){
                // A boolean variable to keep track of whether the step data to be sent is correct or not.
                bool isCorrectStepDataToSend = false;

                // Loop through each element in the _dataStep array
                for(uint256 i = 0; i < _dataStep.length; i++) {
                    // Check if the current stepDataToSend is less than or equal to the current element in the array
                    if(currentChallengeInfo.stepDataToSend <= _dataStep[i]) {
                        // If it is, set the isCorrectStepDataToSend variable to true and break out of the loop
                        isCorrectStepDataToSend = true;
                        break;
                    }
                }
                
                // Check if the step data to send is correct
                if(isCorrectStepDataToSend) {
                    // Check if the required days for the challenge is greater than or equal to the challenge duration minus the tolerated percentage of the challenge duration
                    if(IChallenge(_challengeAddress).dayRequired() >= challengeDuration.sub(challengeDuration.div(currentChallengeInfo.toleranceAmount))) {
                        // This condition checks if the current challenge meets the criteria for paying dividends to the investors
                        if(
                            // Check if the amount of base deposit is less than or equal to the total reward and allow give up, OR
                            currentChallengeInfo.amountBaseDeposit <= IChallenge(_challengeAddress).totalReward() && 
                            IChallenge(_challengeAddress).allowGiveUp(1) ||
                            // Check if the amount of token deposit is less than or equal to the total reward and not allow give up
                            currentChallengeInfo.amountTokenDeposit <= IChallenge(_challengeAddress).totalReward() &&
                            !IChallenge(_challengeAddress).allowGiveUp(1)
                        ) {
                            // Check if the dividend status is pending
                            if(currentChallengeInfo.dividendStatus == DividendStatus.DIVIDEND_PENDING){
                                return true;
                            }

                            // Get the percentage of award receivers
                            uint256[] memory awardReceiversPercent = IChallenge(_challengeAddress).getAwardReceiversPercent();

                            if(currentChallengeInfo.dividendStatus == DividendStatus.DIVIDEND_SUCCESS) {
                                // Get the donation address from the challenge's ERC721 contract
                                address donationAddress = IChallenge(IChallenge(_challengeAddress).erc721Address(0)).donationWalletAddress();
                                require(donationAddress != address(0), "DONATION ADDRESS SHOULD BE DEFINED.");

                                // Check if the first award receiver is the donation address with 98% of the reward
                                if(awardReceiversPercent[0] == 98) {
                                    if(IChallenge(_challengeAddress).getAwardReceiversAtIndex(0, true) == donationAddress) {
                                        return true;
                                    }
                                }
                            }
                            
                            // Check if the dividend distribution has failed
                            if(currentChallengeInfo.dividendStatus == DividendStatus.DIVIDEND_FAIL) {
                                /**
                                * Loop through the list of receivers and check if the receiver gets 98% of the reward and the receiver is an admin
                                * Check if any of the award receivers are admins with 98% of the reward
                                */
                                for(uint256 i = 1; i < awardReceiversPercent.length; i++) {
                                    if(awardReceiversPercent[i] == 98) {
                                        if(IChallenge(_challengeAddress).getAwardReceiversAtIndex(0, false) == receiveAdminWallet) {
                                            return true;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Return false if none of the conditions are met
        return false;
    }

    /**
     * @dev Private function to check the ability to reward based on current reward token
     * @return The index of the current reward token, or 0 if there is no valid token to reward
    */
    function checkAbilityReward() private returns(uint256) {
        // Calculate the total unlock reward by summing up the unlock rates of all reward tokens.
        uint256 totalUnlockReward = rewardTokens[0].unlockRate;

        // Loop through the list of token IDs and sum up their corresponding unlock rates
        for(uint256 i = 0; i < listIdToken.length; i++) {
            totalUnlockReward = totalUnlockReward.add(rewardTokens[listIdToken[i]].unlockRate);
        }

        // Declare a variable to store the random number
        uint256 randomNumber;
        
        // Check if the time random reward is set to RANDOM_MUTIPLE_TIME
        if(timeRandomReward == TimeRandomReward.RANDOM_MUTIPLE_TIME) {
            // Check if the type of random reward is set to normal random number
            if(typeRandomReward == TypeRandomReward.NORMAL_RANDOM_NUMBER) {
                // If so, generate a random number based on the total unlock reward
                randomNumber = IVRFConsumerBase(randomClassicAddress).createRandomNumberMultipleTime(totalUnlockReward);
            } else {
                // If not, generate a random number using VRFConsumerBase and the total unlock reward
                randomNumber = IVRFConsumerBase(VRFConsumerBaseMultipleTime).randomResult() % totalUnlockReward;

                // Call the getRandomNumber function on the VRFConsumerBase contract
                IVRFConsumerBase(VRFConsumerBaseMultipleTime).getRandomNumber();
            }
        } else {
            if(typeRandomReward == TypeRandomReward.NORMAL_RANDOM_NUMBER) {
                // Call the getRandomNumber function on the VRFConsumerBase contract
                IVRFConsumerBase(randomClassicAddress).createRandomNumberOnlyTime(totalUnlockReward);
                
                // If so, generate a random number based on the total unlock reward
                randomNumber = IVRFConsumerBase(randomClassicAddress).randomResult();
            } else {
                // If not, generate a random number using VRFConsumerBase and the total unlock reward
                randomNumber = IVRFConsumerBase(VRFConsumerBaseOnlyTime).randomResult() % totalUnlockReward;

                // Call the getRandomNumber function on the VRFConsumerBase contract
                IVRFConsumerBase(VRFConsumerBaseOnlyTime).getRandomNumber();
            }
        }

        // If the random number is less than or equal to the unlock rate of the first reward token, return the ID of the first reward token.
        if(randomNumber <= rewardTokens[0].unlockRate) {
            return 0;
        }

        // Otherwise, loop through all other reward tokens and check if the random number is within the unlock rate range of each token.
        uint256 totalUnlock = rewardTokens[0].unlockRate;
        uint256 idReward;

        // Loop through the list of token IDs and check if the random number falls within their unlock rates
        for(uint256 i = 0; i < listIdToken.length; i++) {
            if(randomNumber <= rewardTokens[listIdToken[i]].unlockRate + totalUnlock) {
                idReward = listIdToken[i];
                break;
            }
            totalUnlock = totalUnlock.add(rewardTokens[listIdToken[i]].unlockRate);
        }
        // Return the ID of the reward token to be given.
        return idReward;
    } 

    /**
     * @dev Checks if the required NFT balance conditions are met for the challenge.
     * @param _challengeAddress The address of the challenge contract.
     * @return A boolean indicating whether the required NFT balance conditions are met.
    */
    function checkRequireBalanceNft(
        address _challengeAddress, 
        uint256[] memory _dataStep
    ) public view returns(bool) {
        // Check if the reward conditions are met
        if(!checkRewardConditions(_challengeAddress, _dataStep)) {
            return false;
        }

        // If using the default gacha contract, return true
        if(isDefaultGachaContract){
            return true;
        }
        
        // Get the address of the challenger from the challenge contract
        address challangerAddress = IChallenge(_challengeAddress).challenger();

        // Check the balance of NFTs for the specific type of require balance
        if(challengeInfo.typeRequireBalanceNft == TypeRequireBalanceNft.REQUIRE_BALANCE_WALLET) {
            // Check the balance of NFTs in the challenger's wallet
            return checkBalanceNft(challangerAddress);
        }

        // Check the balance of NFTs in the challenge contract
        if(challengeInfo.typeRequireBalanceNft == TypeRequireBalanceNft.REQUIRE_BALANCE_CONTRACT) {
            return checkBalanceNft(_challengeAddress);
        } 

        // Check the balance of NFTs in both the challenger's wallet and the challenge contract
        if(challengeInfo.typeRequireBalanceNft == TypeRequireBalanceNft.REQUIRE_BALANCE_ALL) {
            return checkBalanceNft(challangerAddress) && checkBalanceNft(_challengeAddress);
        }

        // Return false if none of the above conditions are met
        return false;
    }

    /**
     * @dev Check if the specified address has the required balance of NFTs
     * @param _fromAddress The address to check the balance of NFTs for
     * @return True if the address has the required balance, false otherwise
    */
    function checkBalanceNft(
        address _fromAddress
    ) private view returns(bool) {
        // Loop through all the NFTs that are required for the challenge
        for(uint256 i = 0; i < requireBalanceNftAddress.values().length; i++) {
            // If the NFT is an ERC-721 token
            if(typeNfts[requireBalanceNftAddress.values()[i]]) {
                // If the address has a balance of this token
                if(IERC721(requireBalanceNftAddress.values()[i]).balanceOf(_fromAddress) > 0) {
                    return true;
                }
            } else {
                // If the NFT is an ERC-1155 token
                // Get the current index token for this NFT
                uint256 currentIndexToken = IERC1155(requireBalanceNftAddress.values()[i]).nextTokenIdToMint();
                
                // Loop through all the tokens for this NFT that the address has a balance of
                for(uint256 j = 0; j < currentIndexToken; j++) {
                    if(IERC1155(requireBalanceNftAddress.values()[i]).balanceOf(_fromAddress, j) > 0) {
                        return true;
                    }
                }
            }
        }

        // If the address doesn't have the required balance of NFTs for the challenge
        return false;
    }

    /**
     * @dev Returns an array of all the addresses in the `requireBalanceNftAddress` mapping.
    */
    function getRequireBalanceNftAddress() external view returns(address[] memory) {
        return requireBalanceNftAddress.values();
    }

    /**
     * @dev Returns an array of all token IDs that have been minted in the current contract.
     * @return An array of token IDs.
    */
    function getListIdToken() external view returns(uint256[] memory) {
        return listIdToken;
    }

    /**
     * @dev Returns the total number of rewards in the contract.
     * @return The total number of rewards.
    */
    function getTotalNumberReward() public view returns(uint256) {
        return totalNumberReward.current();
    }

    /**
     * @dev Internal function to authorize the upgrade of the contract implementation.
     * @param newImplementation Address of the new implementation contract.
    */
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {

    }

    /*
     * @dev Standard function that ERC721 token contracts must implement to allow safe transfer of tokens to this contract.
     * @param _operator The address which called safeTransferFrom function.
     * @param _from The address which previously owned the token.
     * @param _tokenId The NFT identifier which is being transferred.
     * @param _data Additional data with no specified format.
     * @return A bytes4 indicating success or failure.
    */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    
    /*
     * @dev Standard function that ERC1155 token contracts must implement to allow safe transfer of tokens to this contract.
     * @param _operator The address which called safeTransferFrom function.
     * @param _from The address which previously owned the token.
     * @param _tokenId The NFT identifier which is being transferred.
     * @param _data Additional data with no specified format.
     * @return A bytes4 indicating success or failure.
    */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * @dev Returns whether the contract supports a given interface.
     * Implements ERC165 and AccessControl interfaces.
     * @param interfaceId The interface identifier, as specified in ERC-165 and AccessControl.
     * @return True if the contract supports `interfaceId`, false otherwise.
    */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}