// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IYousovStructs {
    enum SecretStatus{
        LOCK,
        UNLOCK
    }
    enum AccountType {
        REGULAR,
        PSEUDO
     }
    enum Gender {
        MALE,
        FEMALE,
        OTHER
    }
    enum UserStatus {
        OPT_IN,
        OPT_OUT

    }
    enum UserRole {
        SENIOR,
        JUNIOR,
        STANDARD,
        DENIED
    }
    enum RecoveryStatus {
        CREATED,
        IN_PROGRESS,
        OVER
    }
    enum RecoveryRole{
        QUESTION_AGENT,
        ANSWER_AGENT
    }
    enum AnswerStatus{
        ANSWERED,
        NOT_ANSWERED
        
    }
    struct SecretVault {
        string secret;
        SecretStatus secretStatus;
    }
    struct AnswerAgentsDetails{
        string initialAnswer;
        string actualAnswer;
        string challengeID;
        bool answer;
        AnswerStatus answerStatus;
    }
    struct RecoveryStats {
        bool isAllAnswersAgentsAnswered;
        uint256 totoalValidAnswers;
        
    }
    struct PII {
        string firstName;
        string middelName;
        string lastName;
        string cityOfBirth;
        string countryOfBirth;
        string countryOfCitizenship;
        string uid;
        uint256 birthDateTimeStamp;
        Gender gender;
    }
    struct Wallet{
        address publicAddr;
        string walletPassword;
        string privateKey;
    }
    struct Challenge {
        string question;
        string answer;
        string id;
    }
    enum TransactionType {
        TRANSACTION_IN, TRANSACTION_OUT
    }
    struct Transaction {
    TransactionType transactionType;
    uint256 transactionDate;
    uint256 amount;
    address from;
    address to;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17 ;
pragma experimental ABIEncoderV2;
import "../../interface/IYousovStructs.sol";
interface IUser is IYousovStructs {
    function pseudonym() view external returns (string memory pseudonym);
    function threashold() view external returns (uint256 threashold);
    function userChallenges() view external returns(string[] memory _userChallenges) ;
    function setSecret(string memory newSecret) external ;
    function setPseudoym(string memory newPseudonym) external ;
    function setPII(PII memory newPII) external ;
    function setWallet(string memory walletPassword) external ;
    function getWalletDetails() external view  returns (Wallet memory);
    function setAccountType(AccountType newAccountType) external;
    function getAccountType() external view  returns (AccountType);
    function setThreashold(uint256 newThreashold) external;
    function getPII() external view  returns (PII memory);
    function switchUserStatus(UserStatus newStatus) external;
    function lockSecretVault() external;
    function updateUserAccountTypeFromPiiToPseudo(string memory pseudo) external;
    function updateUserAccountTypeFromPseudoToPii(PII memory newPII) external;
    function setChallenges(Challenge[] memory newChallenges , uint256 newThreashold ) external;
    function checkWalletPassword(string memory walletPassword) view external  returns (Wallet memory wallet);
    function userChallengesDetails(string memory challengID) external view returns (Challenge memory challengDetail);
    function unlockSecretVault() external;
    function isSecretUnlocked() external  returns(bool);
    event SecretUpdated();
    event PseudonymUpdated();
    event PIIUpdated();
    event ChallengesUpdated();
    event WalletUpdated();
    event AccountTypeUpdated();
    event ThreasholdUpdated();
    event StatusUpdated();
    event UpdateUserIdentityFromPIIToPseudo();
    event UpdateUserIdentityFromPseudoToPII();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17 ;
import "../../interface/IYousovStructs.sol";
interface IUserUnicity is IYousovStructs {
    function checkUnicity(address[] memory userList,AccountType userAccountTpe , PII memory userPII , string memory userPseudo) external view returns(bool exists, address userContractAddr);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "./interface/IUserUnicity.sol";
import "./interface/IUser.sol";

contract UserUnicity is IUserUnicity {
   /*******************************************************************************
     **	@notice Check the unicity of the user. Returns true if the pii or pseudo already exists, return false instead.
     **	@param userAccountType The account type of the user (AccountType.REGULAR or AccountType.PSEUDO).
     **	@param userPII The pii of the user (firstName, middelName, lastName, cityOfBirth, countryOfBirth, countryOfCitizenship, uid, birthDateTimeStamp, gender).
     **	@param userPseudo The pseudo of the user.
     *******************************************************************************/
    function checkUnicity(
        address[] memory userList,
        AccountType userAccountTpe,
        PII memory userPII,
        string memory userPseudo
    ) external view override returns (bool exists, address userContractAddr) {
        for (uint i = 0; i < userList.length; ++i) {
            IUser _currentUser = IUser(userList[i]);

            if (userAccountTpe == AccountType.REGULAR) {
                if (
                    keccak256(
                        abi.encodePacked(
                            userPII.firstName,
                            userPII.middelName,
                            userPII.lastName,
                            userPII.cityOfBirth,
                            userPII.countryOfBirth,
                            userPII.countryOfCitizenship,
                            userPII.uid,
                            userPII.birthDateTimeStamp,
                            userPII.gender
                        )
                    ) ==
                    keccak256(
                        abi.encodePacked(
                            _currentUser.getPII().firstName,
                            _currentUser.getPII().middelName,
                            _currentUser.getPII().lastName,
                            _currentUser.getPII().cityOfBirth,
                            _currentUser.getPII().countryOfBirth,
                            _currentUser.getPII().countryOfCitizenship,
                            _currentUser.getPII().uid,
                            _currentUser.getPII().birthDateTimeStamp,
                            _currentUser.getPII().gender
                        )
                    )
                ) {
                    return (true, userList[i]);
                }
            } else if (userAccountTpe == AccountType.PSEUDO) {
                if (
                    keccak256(abi.encodePacked(userPseudo)) ==
                    keccak256(abi.encodePacked(_currentUser.pseudonym()))
                ) {
                    return (true, userList[i]);
                }
            }
        }
        return (false, address(0));
    }

}