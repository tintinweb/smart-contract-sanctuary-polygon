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

contract Gacha_default is Initializable, IERC721Receiver, UUPSUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    enum TypeToken { ERC20, ERC721, ERC1155 }
    enum DividendStatus { DIVIDEND_PENDING, DIVIDEND_SUCCESS, DIVIDEND_FAIL }
    enum ChallengeState{PROCESSING, SUCCESS, FAILED, GAVE_UP,CLOSED}

    modifier onlyAdmin() {
        require(admins.contains(msg.sender), "NOT ADMIN.");
        _;
    }

    //This is RewardToken struct.
    struct RewardToken{
        address addressToken;
        uint256 unlockRate;
        uint256 rewardValue;
        uint256 indexToken;
        TypeToken typeToken;
        bool isMintNft;
    }

    //This is ChallengeInfo struct.
    struct ChallengeInfo{
        uint256 targetStepPerDay;
        uint256 challengeDuration;
        uint256 stepDataToSend;
        uint256 toleranceAmount;
        DividendStatus dividendStatus;
        uint256 amountBaseDeposit;
        uint256 amountTokenDeposit;
    }

    struct UserInfor{
        bool statusRandom;
        uint256 indexReward;
        uint256 indexToken;
        address tokenAddress;
        uint256 rewardValue;
        string nameReward;
    }

    event AddNewReward(address indexed _addressToken, uint256 _unlockRate, TypeToken _typeToken, address _gachaAddress);

    event DeleteReward(address indexed _caller, uint256 _indexOfTokenReward, address _gachaAddress);
   
    event SendDailyResultGacha(address indexed _caller, address _gachaAddress);

    event CloseChallenge(address indexed _caller, address _gachaAddress);

    EnumerableSet.AddressSet private admins;// This is a function to store the address of admin.
    mapping(uint256 => RewardToken) public rewardTokens; // This is a mapping to store the reward token.
    Counters.Counter private totalNumberReward; // This is a function to count the total number of reward.
    mapping(address => mapping(address => bool)) public isSendDailyResultWithGacha;
    uint256[] private listIdToken;
    mapping(address => UserInfor) public userInfor;
    ChallengeInfo public challengeInfo;
    EnumerableSet.AddressSet private requireBalanceNftAddress;
    mapping(address => bool) public typeNfts;
    bool public isDefaultGachaContract;
    string public gachaName;
    string public gachaSponsor;
    bool public iscloseGacha;

    function initialize(
        ChallengeInfo memory _challengeInfo,
        address[] memory _requireBalanceNftAddress, 
        bool[] memory _typeNfts,
        uint256 _rateOfLost,
        bool _isDefaultGachaContract,
        string memory _gachaName,
        string memory _gachaSponsor
    ) external initializer {
         __UUPSUpgradeable_init();
        require(_requireBalanceNftAddress.length == _typeNfts.length, "INVALID REQUIRE BALANCE NFT ADDRESS.");
        challengeInfo = _challengeInfo;
        for(uint256 i = 0; i < _requireBalanceNftAddress.length; i++) {
            requireBalanceNftAddress.add(_requireBalanceNftAddress[i]);
            typeNfts[_requireBalanceNftAddress[i]] = _typeNfts[i];
        }
        isDefaultGachaContract = _isDefaultGachaContract;
        gachaName = _gachaName;
        gachaSponsor = _gachaSponsor;
        admins.add(msg.sender);
        rewardTokens[0].unlockRate = _rateOfLost;
    }

    // This function is used to send daily result gacha.
    function randomRewards(address _challengeAddress) external returns(bool){
        require(
            !isSendDailyResultWithGacha[msg.sender][_challengeAddress], 
            "ALREADY SEND DAILY RESULT WITH GACHA CONTRACT."
        );

        require(
            _challengeAddress == msg.sender, 
            "ONLY CHALLENGE CONTRACT CAN CALL SEND DAILY RESULT WITH GACHA."
        );

        address challengerAddress = IChallenge(_challengeAddress).challenger();
        UserInfor memory newUserInfor;
        userInfor[challengerAddress] = newUserInfor;
        bool isWonThePrize = false;
        // This is a loop to check if the reward token is exist or not.
        uint256 randomIndexReward = checkAbilityReward();
        if(randomIndexReward != 0) {
            if(checkRewardConditions( _challengeAddress)) {
                uint256 indexTokenReward;
                address currentTokenAddress =  rewardTokens[randomIndexReward].addressToken;
                if(rewardTokens[randomIndexReward].typeToken == TypeToken.ERC20) {
                    // This is a function to transfer the reward token to the challenger address.
                    TransferHelper.safeTransfer(
                        currentTokenAddress,
                        challengerAddress,
                        rewardTokens[randomIndexReward].rewardValue
                    );
                } else {     
                    if(rewardTokens[randomIndexReward].typeToken == TypeToken.ERC721) {
                        uint256 currentIndexNFT = IChallenge(currentTokenAddress).nextTokenIdToMint();
                        if(rewardTokens[randomIndexReward].isMintNft) {
                            IChallenge(IChallenge(_challengeAddress).erc721Address(0)).safeMintNFT721Heper(
                                currentTokenAddress,
                                challengerAddress
                            );
                            indexTokenReward = currentIndexNFT;
                        } else {
                            for(uint256 j = 0; j < currentIndexNFT; j++) {
                                if(IChallenge(currentTokenAddress).ownerOf(j) == address(this)) {
                                    TransferHelper.safeTransferFrom(
                                        currentTokenAddress,
                                        address(this),
                                        challengerAddress,
                                        j
                                    );
                                    indexTokenReward = j;
                                    break;
                                }
                            }
                        }   
                    }  else {
                        if(rewardTokens[randomIndexReward].isMintNft) {
                            IChallenge(IChallenge(_challengeAddress).erc721Address(0)).safeMintNFT1155Heper(
                                currentTokenAddress,
                                challengerAddress,
                                rewardTokens[randomIndexReward].indexToken,
                                rewardTokens[randomIndexReward].rewardValue
                            );
                        } else {
                            TransferHelper.safeTransferNFT1155(
                                currentTokenAddress,
                                address(this),
                                challengerAddress,
                                rewardTokens[randomIndexReward].indexToken,
                                rewardTokens[randomIndexReward].rewardValue,
                                "ChallengeApp"
                            );
                        }

                        indexTokenReward = rewardTokens[randomIndexReward].indexToken;
                    }
                }

                isWonThePrize = true;

                userInfor[challengerAddress] = UserInfor(
                    true,
                    randomIndexReward,
                    indexTokenReward,
                    currentTokenAddress,
                    rewardTokens[randomIndexReward].rewardValue,
                    IChallenge(currentTokenAddress).name()
                );
            } 
        }

        if(isWonThePrize && IChallenge(_challengeAddress).isFinished()){
            isSendDailyResultWithGacha[msg.sender][_challengeAddress] = true;
        }

        emit SendDailyResultGacha(msg.sender, address(this));

        return isWonThePrize;
    } 

    function closeGacha() external onlyAdmin {
        require(!iscloseGacha, "GACHA ALREADY CLOSE.");
        for(uint256 i = 0; i < listIdToken.length; i++) {
            address tokenAddress = rewardTokens[listIdToken[i]].addressToken;
            if(!rewardTokens[listIdToken[i]].isMintNft) {
                if(rewardTokens[listIdToken[i]].typeToken != TypeToken.ERC1155) {
                    uint256 balanceToken = IERC20(tokenAddress).balanceOf(address(this));
                    if(balanceToken > 0) {
                        if(rewardTokens[listIdToken[i]].typeToken == TypeToken.ERC20) {
                            TransferHelper.safeTransfer(
                                tokenAddress,
                                admins.values()[0],
                                balanceToken
                            );
                        }

                        if(rewardTokens[listIdToken[i]].typeToken == TypeToken.ERC721) {
                            uint256 currentIndexNFT = IChallenge(tokenAddress).nextTokenIdToMint();
                            for(uint256 j = 0; j < currentIndexNFT; j++) {
                                if(IChallenge(tokenAddress).ownerOf(j) == address(this)) {
                                    TransferHelper.safeTransferFrom(
                                        tokenAddress,
                                        address(this),
                                        admins.values()[0],
                                        j
                                    );
                                }
                            }
                        }
                    }
                } else {
                    uint256 balanceTokenERC1155 = IERC1155(tokenAddress).balanceOf(address(this), rewardTokens[listIdToken[i]].indexToken);
                    if(balanceTokenERC1155 > 0) {
                        TransferHelper.safeTransferNFT1155(
                            tokenAddress,
                            address(this),
                            admins.values()[0],
                            rewardTokens[listIdToken[i]].indexToken,
                            balanceTokenERC1155,
                            "ChallengeApp"
                        );   
                    }
                }
            }
        }

        iscloseGacha = true;

        emit CloseChallenge(msg.sender, address(this));
    }
    
    // check reward 
    function checkAbilityReward() private view returns(uint256){
        uint256 totalUnlockReward = rewardTokens[0].unlockRate;
        for(uint256 i = 0; i < listIdToken.length; i++) {
            totalUnlockReward = totalUnlockReward.add(rewardTokens[listIdToken[i]].unlockRate);
        }
        uint256 ramdomNumber = checkRamdomNumber(totalUnlockReward);

        if(ramdomNumber <= rewardTokens[0].unlockRate) {
            return 0;
        }

        uint256 totalUnlock = rewardTokens[0].unlockRate;
        uint256 idReward;
        for(uint256 i = 0; i < listIdToken.length; i++) {
            if(ramdomNumber <= rewardTokens[listIdToken[i]].unlockRate + totalUnlock) {
                idReward = listIdToken[i];
                break;
            }
            totalUnlock = totalUnlock.add(rewardTokens[listIdToken[i]].unlockRate);
        }
        return idReward;
    }   
    
    // This function is used to add new reward.
    function addNewReward(
        address _addressToken,
        uint256 _unlockRate,
        uint256 _rewardValue,
        uint256 _indexToken,
        TypeToken _typeToken,
        bool _isMintNft
    ) external onlyAdmin{
        /*
        This is a function to check if the address token is not zero, 
        unlock rate is less than total rate and reward value is greater than zero.
        */
        require(_addressToken != address(0), "ZERO ADDRESS.");
        require(_rewardValue > 0, "INVALID REWARD VALUE.");

        // This function is used to add or update reward.
        uint256 indexOfTokenReward = 0;
        for(uint256 i = 1; i <= totalNumberReward.current(); i++) {
            if(rewardTokens[i].addressToken == address(0)) {
                indexOfTokenReward = i;
                break;
            }
        }

        if(indexOfTokenReward == 0 ){
            totalNumberReward.increment();
            indexOfTokenReward = totalNumberReward.current();
        }
        
        addReward(indexOfTokenReward, _addressToken, _unlockRate, _rewardValue, _indexToken, _typeToken, _isMintNft);
        listIdToken.push(indexOfTokenReward);

        emit AddNewReward(_addressToken, _unlockRate, _typeToken, address(this));
    }

    function checkRewardConditions(address _challengerAddress) public view returns(bool){
        uint256 challengeDuration = IChallenge(_challengerAddress).duration();
        // check balance NFT, require Balance Nft Address
        if(checkRequireBalanceNft(IChallenge(_challengerAddress).challenger())) {
            if(challengeInfo.targetStepPerDay <= IChallenge(_challengerAddress).goal()){
                if(challengeInfo.challengeDuration <= challengeDuration){
                    (, uint256[] memory challengeHiostoryData) = IChallenge(_challengerAddress).getChallengeHistory();
                    bool isCorrectStepDataToSend = false;
                    for(uint256 i = 0; i < challengeHiostoryData.length; i++) {
                        if(challengeInfo.stepDataToSend <= challengeHiostoryData[i]) {
                            isCorrectStepDataToSend = true;
                            break;
                        }
                    }
                    if(isCorrectStepDataToSend) {
                        if(IChallenge(_challengerAddress).dayRequired() >= challengeDuration.sub(challengeDuration.div(challengeInfo.toleranceAmount))) {
                            if(
                                challengeInfo.amountBaseDeposit <= IChallenge(_challengerAddress).totalReward() && 
                                IChallenge(_challengerAddress).allowGiveUp(1) ||
                                challengeInfo.amountTokenDeposit <= IChallenge(_challengerAddress).totalReward() &&
                                !IChallenge(_challengerAddress).allowGiveUp(1)
                            ) {
                                if(challengeInfo.dividendStatus == DividendStatus.DIVIDEND_PENDING){
                                    return true;
                                }

                                uint256[] memory awardReceiversPercent = IChallenge(_challengerAddress).getAwardReceiversPercent();

                                if(challengeInfo.dividendStatus == DividendStatus.DIVIDEND_SUCCESS) {
                                address donationAddress = IChallenge(IChallenge(_challengerAddress).erc721Address(0)).donationWalletAddress();
                                require(donationAddress != address(0), "DONATION ADDRESS SHOULD BE DEFINED.");
                                    if(awardReceiversPercent[0] == 98) {
                                        if(IChallenge(_challengerAddress).getAwardReceiversAtIndex(0, true) == donationAddress) {
                                            return true;
                                        }
                                    }
                                }
                                
                                if(challengeInfo.dividendStatus == DividendStatus.DIVIDEND_FAIL) {
                                    for(uint256 i = 1; i < awardReceiversPercent.length; i++) {
                                        if(awardReceiversPercent[i] == 98) {
                                            if(admins.contains(IChallenge(_challengerAddress).getAwardReceiversAtIndex(0, false)))
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
        return false;
    }
    

    // This function is used to delete reward.
    function deleteReward(uint256 _indexOfTokenReward) external {
        // Used to delete the reward token.
        bool isExistIndexToken = false;
        for(uint256 i = 0; i < listIdToken.length; i++) {
            if(_indexOfTokenReward == listIdToken[i]) {
                isExistIndexToken = true;
                break;
            }
        }
        require(isExistIndexToken, "INDEX OF TOKEN REWARD NOT EXIST.");
        
        delete rewardTokens[_indexOfTokenReward];
        for(uint256 i = 0; i < listIdToken.length; i++) {
            if(listIdToken[i] == _indexOfTokenReward) {
                listIdToken[i] = listIdToken[listIdToken.length.sub(1)];
            }
        }
        listIdToken.pop();

        emit DeleteReward(msg.sender, _indexOfTokenReward, address(this));
    }

    // This function is used to add or update reward.
    function addReward(
        uint256 _indexOfTokenReward,
        address _addressToken,
        uint256 _unlockRate,
        uint256 _rewardValue,
        uint256 _indexToken,
        TypeToken _typeToken,
        bool _isMintNft
    ) private {
        rewardTokens[_indexOfTokenReward] = RewardToken(
            _addressToken,
            _unlockRate,
            _rewardValue,
            _indexToken,
            _typeToken,
            _isMintNft
        );
    }

    // This function is used to find index of token reward.
    function findIndexOfTokenReward(address _addressToken) public view returns(uint256 indexOfTokenReward) {
        // This is a loop to check if the reward token is exist or not.
        for(uint256 i = 1; i <= totalNumberReward.current(); i++) {
            if(rewardTokens[i].addressToken == _addressToken) {
                indexOfTokenReward = i;
                break;
            }
        }
    }

    // This function is used to get total number of reward.
    function getTotalNumberReward() public view returns(uint256) {
        return totalNumberReward.current();
    }

    // This function is used to add or remove admin.
    function updateAdmin(address _adminAddr, bool _flag) external onlyAdmin {
        require(_adminAddr != address(0), "INVALID ADDRESS.");
        // This is a function to add or remove admin.
        if (_flag) {
            admins.add(_adminAddr);
        } else {
            admins.remove(_adminAddr);
        }
    }

    function updateChallengeInfor(ChallengeInfo memory _challengeInfo) external onlyAdmin{
        challengeInfo = _challengeInfo;
    }

    function updateRateOfLost(uint256 _rateOdLost) external onlyAdmin{
        rewardTokens[0].unlockRate = _rateOdLost;
    }

    // This function is used to get all admins.
    function getAdmins() external view returns (address[] memory) {
        return admins.values();
    }

    function checkRamdomNumber(uint256 _ramdomWithLimitValue) private view returns(uint256){
        require(_ramdomWithLimitValue > 0, "THE REWARD IS OVER.");
        // This is a function to generate random number.
        uint256 firstRamdomValue = uint256(
            keccak256(abi.encodePacked(
                block.number, block.difficulty, msg.sender, block.timestamp)
            )
        ) % _ramdomWithLimitValue;
        return firstRamdomValue.add(1);
    }
    
    // Check existence for index reward
    function checkExistenceIndexRewards(uint256[] memory data) private pure returns(bool){
        if(data.length == 1) {
            return true;
        }
        
        for(uint256 i = 0; i < data.length; i++) {
            for(uint256 j = i + 1; j < data.length; j++) {
                if(data[j] == data[i]) {
                    return false;
                }

            }
        }

        return true;
    }

    function checkRequireBalanceNft(address _fromAddress) public view returns(bool) {
        if(isDefaultGachaContract){
            return true;
        }

        for(uint256 i = 0; i < requireBalanceNftAddress.values().length; i++) {
            if(typeNfts[requireBalanceNftAddress.values()[i]]) {
                if(IERC721(requireBalanceNftAddress.values()[i]).balanceOf(_fromAddress) > 0) {
                    return true;
                }
            } else {
                uint256 currentIndexToken = IERC1155(requireBalanceNftAddress.values()[i]).nextTokenIdToMint();
                for(uint256 j = 0; j < currentIndexToken; j++) {
                    if(IERC1155(requireBalanceNftAddress.values()[i]).balanceOf(_fromAddress, j) > 0) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    function updateStatusDefaultGachaContract(bool _isDefaultGachaContract) external onlyAdmin {
        require(isDefaultGachaContract == isDefaultGachaContract, "THIS STATUS HAS BEEN SETTING.");
        isDefaultGachaContract = _isDefaultGachaContract;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyAdmin
        override
    {

    }

    function updateRequireBalanceNftAddress(address _nftAddress, bool _flag, bool _isTypeErc721) external onlyAdmin {
        require(_nftAddress != address(0), "INVALID NFT ADDRESS");
        if (_flag) {
            requireBalanceNftAddress.add(_nftAddress);
        } else {
            requireBalanceNftAddress.remove(_nftAddress);
        }
        typeNfts[_nftAddress] = _isTypeErc721;
    }

    function getRequireBalanceNftAddress() external view returns(address[] memory) {
        return requireBalanceNftAddress.values();
    }

    function getListIdToken() external view returns(uint256[] memory) {
        return listIdToken;
    }

    /**
     * @dev onERC721Received.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    
    /**
     * @dev onERC1155Received.
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
}