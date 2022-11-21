// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./Founder.sol";
import "./InvestorLogin.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract PrivateRound is Ownable{

    // CUSTOM ERROR
    error roundIdNotLinkedToInvestor();
    error roundIdNotLinkedToFounder();
    error zeroAddress();
    error tokenAlreadyExist();
    error tokenNotSupported();

    // STATE VARIABLES
    address public contractOwner;
    // This state varibale holds the contract address necessary for the privateRound.
    address private InvestorLoginContract;
    address private FounderContract;
    // address public tokenContract;
    mapping(uint => address) public tokenContract;
    address private _grantedOwner;
    // holds the suitable tokens to be used for this contract. 
    bool private contractInitialized;
    // This is an incremental roundId setup for the contract.
    uint private roundIdContract;
    
    // EVENTS:
    event OwnershipGranted(address);
    event roundCreated(address indexed from, address indexed to, uint roundId);
    event deposited(address indexed from, address indexed to, uint256 indexed amount);
    event initialPercentageWithdrawn(address indexed to, uint256 indexed amount);
    event milestoneValidation(uint indexed milestone, uint indexed round, bool indexed status);
    event withdrawByInvestor(address indexed to, uint indexed amount);
    event withdrawByFounder(address indexed to, uint indexed amount);
    event batchWithdraw(address indexed to, uint indexed amount);
    event withdrawTax(address indexed to, uint indexed amount);

    // MODIFIERS:
    /*
        * This dynamically changes everytime token address is submitted.
        * Either by Investor or Founder.
    */    

    modifier onlyAdmin(){
        require(msg.sender == contractOwner,"Sender is not the owner of this contract");
        _;
    }

    modifier isInitialized(){
        require(contractInitialized == true,"The contract is not yet initialized");
        _;
    }

    // ARRAY
    address[] private tokenContractAddress;
    
    // STRUCT
    struct MilestoneSetup {
        uint256 _num;
        uint256 _date;
        uint256 _percent;
    }

    // MAPPINGS:
    mapping(address => mapping(uint => MilestoneSetup[])) private _milestone; // sets investor address to mileStones created by the founder.
    mapping(uint => mapping(address => uint)) public initialPercentage;  // round id => investor => initialPercentage   
    mapping(uint => mapping(address => address)) public seperateContractLink;  // round id => founder => uinstance contract address.   
    mapping(uint => bool) private roundIdControll; 
    /**
    create mapping for isWhether founder address is for this roundId.
    create mapping for isWhether investor address is for this roundId.
    */
    mapping(address => mapping(uint => bool)) private isRoundIdForFounder;
    mapping(address => mapping(uint => bool)) private isRoundIdForInvestor;
    mapping(address => uint[]) private getRoundId;
    mapping(uint => mapping(address => uint)) public remainingTokensOfInvestor;  // round id => investor => tokens   
    mapping(uint => mapping(address => uint)) public totalTokensOfInvestor;    // round id => investor => tokens 
    mapping(uint => mapping(address => uint)) public initialTokensForFounder;  // round id => founder => tokens
    mapping(uint => mapping(address => bool)) private initialWithdrawalStatus;
    mapping(uint => address) private contractAddress;
    mapping(address => bool) private addressExist;
    mapping(address => uint) public taxedTokens;
    mapping(uint => uint) private withdrawalFee;
    mapping(uint => mapping(uint => uint)) private rejectedByInvestor;
    mapping(uint => bool) private projectCancel;
    mapping(uint => mapping(uint => address)) private requestForValidation;
    mapping(uint => mapping(uint => int)) private milestoneApprovalStatus; // 0 - means default null, 1 - means approves, -1 means rejected.
    mapping(uint => mapping(uint => bool)) private milestoneWithdrawalStatus;
    mapping(address => mapping(uint => uint)) private investorWithdrawnTokens;  // investor add => roundid => withdrawn token
    
    
    // // After deploying the contract, deployer stricly needs to activate this function if initialize is not set.
    // function initialize() external initializer{
    //   ///@dev as there is no constructor, we need to initialise the OwnableUpgradeable explicitly
    //    __Ownable_init();
    //    contractOwner = msg.sender;
    //    contractInitialized = true;
    //    roundIdContract = 0;
    // }

    constructor (){
       contractOwner = msg.sender;
       contractInitialized = true;
       roundIdContract = 0;
    }

    // function _authorizeUpgrade(address) internal override onlyOwner {}
    
    /**
        * Whitelist contract this is necessary for InvestorLogin:
        * @param _contractAddressInvestor This sets the investorLoginContract Address.
    */
    function whitelistInvestorLoginContract(address _contractAddressInvestor) external onlyAdmin{
        if(_contractAddressInvestor == address(0)){ revert zeroAddress();}
        InvestorLoginContract = _contractAddressInvestor;
    }
    /**
        * Whitelist contract this is necessary for Founder:
        * @param _contractAddressFounder This sets the FounderContract Address.
    */
    function whitelistFounderContract(address _contractAddressFounder) external onlyAdmin{
        if(_contractAddressFounder == address(0)){ revert zeroAddress();}
        FounderContract = _contractAddressFounder;
    }
  
    // Write Functions:
    /**
        * createPrivateRound
        * @param  _founder Enter the founder address, for who private round is created.
        * @param _initialPercentage Enter the initial percantange of amount needs to be unlocked after deposit.
        * @param _mile Set the number of milestone for the founder.
    */

    function createPrivateRound(address _founder, uint _initialPercentage, MilestoneSetup[] memory _mile) external isInitialized returns(uint roundID){
        InvestorLogin investor = InvestorLogin(InvestorLoginContract);
        require(investor.verifyInvestor(msg.sender), "The address is not registered in the 'InvestorLogin' contract");
        roundIdContract = roundIdContract + 1;
        isRoundIdForInvestor[msg.sender][roundIdContract] = true;
        for(uint i = 0; i < _mile.length; ++i){
            _milestone[msg.sender][roundIdContract].push(_mile[i]);
            milestoneApprovalStatus[roundIdContract][_mile[i]._num] = 0;
            milestoneWithdrawalStatus[roundIdContract][_mile[i]._num] = false;
        }
        initialPercentage[roundIdContract][msg.sender] = _initialPercentage;
        getRoundId[msg.sender].push(roundIdContract);
        getRoundId[_founder].push(roundIdContract);
        emit roundCreated(msg.sender,_founder,roundIdContract);
        roundID = roundIdContract;
    }

    /**
        * whitelistToken.  
        * Whitelist the token address, so that only tokensfrom the whitelist works.
        * @param _tokenContract Enter the token contract address to be logged to the smart contract.
    */
    function whitelistToken(address _tokenContract) external onlyAdmin{
        if(_tokenContract == address(0)){ revert zeroAddress();}
        if(addressExist[_tokenContract] == true){ revert tokenAlreadyExist();}
        addressExist[_tokenContract] = true;
        tokenContractAddress.push(_tokenContract);
    }

    /**
        * depositTokens
        * @param _tokenContract Enter the token contract address.
        * @param _founder Enter the founder address.
        * @param _tokens Enter how many tokens needs to be deposited for the founder.
        * @param _roundId Enter the roundId generated while creating the privateRound.
    */
 
    function depositTokens(address _tokenContract, address _founder, uint _tokens, uint _roundId) external isInitialized{
        require(_tokenContract != address(0), "The smart contract address is invalid");
        InvestorLogin investor = InvestorLogin(InvestorLoginContract);
        require(investor.verifyInvestor(msg.sender), "The address is not registered in the 'InvestorLogin' contract");
        if(isRoundIdForInvestor[msg.sender][_roundId] != true){ revert roundIdNotLinkedToInvestor();}
        if(addressExist[_tokenContract] != true){ revert tokenNotSupported();}
        isRoundIdForFounder[_founder][_roundId] = true;
        tokenContract[_roundId] = _tokenContract;
        FundLock fl = new FundLock(msg.sender, _roundId, _tokens, address(this));
        seperateContractLink[_roundId][_founder] = address(fl);
        contractAddress[_roundId] = address(fl);
        remainingTokensOfInvestor[_roundId][msg.sender] = _tokens;
        totalTokensOfInvestor[_roundId][msg.sender] = _tokens;
        uint tax = _tokens * initialPercentage[_roundId][msg.sender] / 100;
        initialTokensForFounder[_roundId][_founder] += tax;
        remainingTokensOfInvestor[_roundId][msg.sender] -= initialTokensForFounder[_roundId][_founder];
        require(ERC20(_tokenContract).transferFrom(msg.sender, seperateContractLink[_roundId][_founder], _tokens), "transaction failed or reverted");
        emit deposited(msg.sender, _founder, _tokens);
    }

    /**
        * withdrawInitialPercentage
        * @param _tokenContract Enter the token contract address.
        * @param _roundId Enter the roundId generated while creating the privateRound.
    */
    
    function withdrawInitialPercentage(address _tokenContract, uint _roundId) external isInitialized{ // 2% tax should be levied on the each transaction
        if(addressExist[_tokenContract] != true){ revert tokenNotSupported();}
        Founder founder = Founder(FounderContract);
        require(founder.verifyFounder(msg.sender), "The address is not registered in the 'Founder' contract");
        if(initialWithdrawalStatus[_roundId][msg.sender]){
            revert("Initial withdrawal is already done");
        }
        if(isRoundIdForFounder[msg.sender][_roundId] != true){ revert roundIdNotLinkedToFounder();}
        FundLock fl = FundLock(seperateContractLink[_roundId][msg.sender]);
        uint tax = 2 * (initialTokensForFounder[_roundId][msg.sender] / 100);
        taxedTokens[_tokenContract] += tax;
        initialTokensForFounder[_roundId][msg.sender] -= tax;
        withdrawalFee[_roundId] += tax;
        initialWithdrawalStatus[_roundId][msg.sender] = true;
        require(ERC20(_tokenContract).transferFrom(address(fl), msg.sender, initialTokensForFounder[_roundId][msg.sender]), "transaction failed or reverted");
        emit initialPercentageWithdrawn(msg.sender, initialTokensForFounder[_roundId][msg.sender]);
    }

    /**
        * milestoneValidationRequest
        * @param _milestoneId Enter the milestoneID, for validation set during the privateRound creation.
        * @param _roundId Enter the roundId generated while creating the privateRound.
    */

    function milestoneValidationRequest(uint _milestoneId, uint _roundId) external isInitialized{
        Founder founder = Founder(FounderContract);
        require(founder.verifyFounder(msg.sender), "The address is not registered in the 'Founder' contract");
        if(isRoundIdForFounder[msg.sender][_roundId] != true){ revert roundIdNotLinkedToFounder();}
        requestForValidation[_roundId][_milestoneId] = msg.sender;
    }

    /**
        * validateMilestone
        * @param _milestoneId Enter the milestoneID, for validation set during the privateRound creation.
        * @param _roundId Enter the roundId generated while creating the privateRound.
        * @param _status Enter "true" for approved, or "false" for rejected.
    */

    function validateMilestone(uint _milestoneId, uint _roundId, bool _status) external isInitialized{
        InvestorLogin investor = InvestorLogin(InvestorLoginContract);
        require(investor.verifyInvestor(msg.sender), "The address is not registered in the 'InvestorLogin' contract");
        if(isRoundIdForInvestor[msg.sender][_roundId] != true){ revert roundIdNotLinkedToInvestor();}
        if(milestoneApprovalStatus[_roundId][_milestoneId] == 1){
            revert("The milestone is already approved");
        }
        if(_status){
            milestoneApprovalStatus[_roundId][_milestoneId] = 1;
        }else{
            rejectedByInvestor[_roundId][_milestoneId] += 1;
            milestoneApprovalStatus[_roundId][_milestoneId] = -1;
        }
        if(rejectedByInvestor[_roundId][_milestoneId] >= 3){
            projectCancel[_roundId] = true;
        }
        emit milestoneValidation(_milestoneId, _roundId, _status);
    }

    /**
        * withdrawIndividualMilestoneByFounder
        * @param _investor Enter the investor address.
        * @param _roundId Enter the roundId generated while creating the privateRound.
        * @param _milestoneId Enter the milestoneID, for validation set during the privateRound creation.
        * @param _percentage Enter the percentage set during the privateRound creation.
        * @param _tokenContract Enter the token contract address.
    */
    

    function withdrawIndividualMilestoneByFounder(address _investor, uint _roundId, uint _milestoneId, uint _percentage, address _tokenContract) external isInitialized{
        if(addressExist[_tokenContract] != true){ revert tokenNotSupported();}
        Founder founder = Founder(FounderContract);
        require(founder.verifyFounder(msg.sender), "The address is not registered in the 'Founder' contract");
        if(isRoundIdForFounder[msg.sender][_roundId] != true){ revert roundIdNotLinkedToFounder();}
        uint unlockedAmount = 0;
        if(milestoneApprovalStatus[_roundId][_milestoneId] == 1 && !milestoneWithdrawalStatus[_roundId][_milestoneId]){
            unlockedAmount = (totalTokensOfInvestor[_roundId][_investor] * _percentage)/ 100;
            milestoneWithdrawalStatus[_roundId][_milestoneId] = true;
            remainingTokensOfInvestor[_roundId][_investor] -= unlockedAmount;
        }
        if(unlockedAmount > 0){
            uint tax = (2 * unlockedAmount) / 100;
            taxedTokens[_tokenContract] += tax;
            unlockedAmount -= tax;
            withdrawalFee[_roundId] += tax;
            FundLock fl = FundLock(seperateContractLink[_roundId][msg.sender]);
            require(ERC20(_tokenContract).transferFrom(address(fl), msg.sender, unlockedAmount), "transaction failed or reverted");
            emit withdrawByFounder(msg.sender, unlockedAmount);
        }else{
            revert("No unlocked tokens to withdraw");
        } 
    }

    /**
        *  withdrawIndividualMilestoneByInvestor
        * @param _roundId Enter the roundId generated while creating the privateRound.
        * @param _founder Enter the founder address.
        * @param _milestoneId Enter the milestoneID, for validation set during the privateRound creation.
        * @param _percentage Enter the percentage set during the privateRound creation.
        * @param _tokenContract Enter the token contract address.
    */

    function withdrawIndividualMilestoneByInvestor(uint _roundId, address _founder, uint _milestoneId, uint _percentage, address _tokenContract) external isInitialized{
        if(addressExist[_tokenContract] != true){ revert tokenNotSupported();}
        InvestorLogin investor = InvestorLogin(InvestorLoginContract);
        require(investor.verifyInvestor(msg.sender), "The address is not registered in the 'InvestorLogin' contract");
        if(isRoundIdForInvestor[msg.sender][_roundId] != true){ revert roundIdNotLinkedToInvestor();}
        uint count = 0;
        for(uint i = 0; i < _milestone[msg.sender][_roundId].length; i++){
            if(block.timestamp > _milestone[msg.sender][_roundId][i]._date && requestForValidation[_roundId][_milestone[msg.sender][_roundId][i]._num] != _founder){
                count += 1;
            }
        }
        // if(projectCancel[_roundId] || count >= 2){
        //     defaultedByFounder = true;
        // }
        if(projectCancel[_roundId] || count >= 2){
            uint lockedAmount = 0;
            if(milestoneApprovalStatus[_roundId][_milestoneId] != 1){
                lockedAmount += (totalTokensOfInvestor[_roundId][msg.sender] * _percentage) / 100;
                remainingTokensOfInvestor[_roundId][msg.sender] -= lockedAmount;
            }
            if(lockedAmount > 0){
                FundLock fl = FundLock(seperateContractLink[_roundId][_founder]);
                uint tax = (2 * lockedAmount)/ 100;
                taxedTokens[_tokenContract] += tax;
                withdrawalFee[_roundId] += tax;
                lockedAmount -= tax;
                investorWithdrawnTokens[msg.sender][_roundId] = lockedAmount;
                require(ERC20(_tokenContract).transferFrom(address(fl), msg.sender, lockedAmount), "transaction failed or reverted"); 
                emit withdrawByInvestor(msg.sender, lockedAmount);
            }
        }
    }

    /**
        *  batchWithdrawByInvestors
        * @param _roundId Enter the roundId generated while creating the privateRound.
        * @param _founder Enter the founder address.
        * @param _tokenContract Enter the token contract address.
    */

    function batchWithdrawByInvestors(uint _roundId, address _founder, address _tokenContract) external isInitialized{
        if(addressExist[_tokenContract] != true){ revert tokenNotSupported();}
        InvestorLogin investor = InvestorLogin(InvestorLoginContract);
        require(investor.verifyInvestor(msg.sender), "The address is not registered in the 'InvestorLogin' contract");
        if(isRoundIdForInvestor[msg.sender][_roundId] != true){ revert roundIdNotLinkedToInvestor();}
        uint count = 0;
        for(uint i = 0; i < _milestone[msg.sender][_roundId].length; i++){
            if(block.timestamp > _milestone[msg.sender][_roundId][i]._date && requestForValidation[_roundId][_milestone[msg.sender][_roundId][i]._num] != _founder){
                count += 1;
            }
        }
        // if(projectCancel[_roundId] || count >= 2){
        //     defaultedByFounder = true;
        // }
        uint lockedAmount = 0;
        if(projectCancel[_roundId] || count >= 2){
            for(uint i = 0; i < _milestone[msg.sender][_roundId].length; i++){
                if(milestoneApprovalStatus[_roundId][_milestone[msg.sender][_roundId][i]._num] != 1){
                    lockedAmount += (totalTokensOfInvestor[_roundId][msg.sender] * _milestone[msg.sender][_roundId][i]._percent) / 100;
                    remainingTokensOfInvestor[_roundId][msg.sender] -= lockedAmount;
                }
            }
            if(lockedAmount > 0){
                FundLock fl = FundLock(seperateContractLink[_roundId][_founder]);
                uint tax = (2 * lockedAmount)/ 100;
                taxedTokens[_tokenContract] += tax;
                withdrawalFee[_roundId] += tax;
                lockedAmount -= tax;
                investorWithdrawnTokens[msg.sender][_roundId] = lockedAmount;
                require(ERC20(_tokenContract).transferFrom(address(fl), msg.sender, lockedAmount), "transaction failed or reverted"); 
                emit batchWithdraw(msg.sender, lockedAmount);
            }
        }
    }

    /**
        * grantOwnership.
        * Two factor ownership granting process.
        * @param newOwner , sets netOwner as admin for the contract, buts ownership needs to be claimed.
    */
    
    function grantOwnership(address newOwner) public virtual onlyAdmin {
        emit OwnershipGranted(newOwner);
        _grantedOwner = newOwner;
    }

    /**
        * claimOwnership.
        * Two factor ownership granting process.
    */

    function claimOwnership() public virtual {
        require(_grantedOwner == _msgSender(), "Ownable: caller is not the granted owner");
        emit OwnershipTransferred(contractOwner, _grantedOwner);
        contractOwner = _grantedOwner;
        _grantedOwner = address(0);
    }

    /**
        *  withdrawTaxTokens
        * @param _tokenContract Enter the token contract address.
        * @param _roundId Enter the roundId generated while creating the privateRound.
        * @param _founder Enter the founder address.
    */

    function withdrawTaxTokens(address _tokenContract, uint _roundId, address _founder) external onlyAdmin { // All the taxed tokens are there in the contract itself. no instance is created
        if(addressExist[_tokenContract] != true){ revert tokenNotSupported();}
        FundLock fl = FundLock(seperateContractLink[_roundId][_founder]);
        uint tax = taxedTokens[_tokenContract];
        taxedTokens[_tokenContract] = 0;
        require(ERC20(_tokenContract).transferFrom(address(fl), msg.sender, tax), "execution failed or reverted");
        emit withdrawTax(msg.sender, tax);
    }   

    /*
        * READ FUNCTIONS:
    */

    function GetRoundIdByInvestor(address _investor, uint256 _array) public view returns(uint256){
        return getRoundId[_investor][_array];
    }

    function GetRoundIdByFounder(address _founder, uint256 _array) public view returns(uint256){
        return getRoundId[_founder][_array];
    }

    function milestoneStatusChk(uint roundId, uint milestoneId) external view returns(int){
        return milestoneApprovalStatus[roundId][milestoneId];
    }

    function getContractAddress(uint _roundId) external view returns(address smartContractAddress){
        return contractAddress[_roundId];
    }

    function projectStatus(uint _roundId) external view returns(bool projectLiveOrNot){
        return projectCancel[_roundId];
    }

    function tokenStatus(uint _roundId, address _founder, address _investor) external view returns(uint unlockedAmount, uint lockedAmount, uint withdrawnTokensByFounder){
        uint unlockedTokens = 0;
        uint lockedTokens = 0;
        uint withdrawnTokens = 0;
        if(!initialWithdrawalStatus[_roundId][_founder]){
            unlockedTokens = initialTokensForFounder[_roundId][_founder];
        }else{
            withdrawnTokens = initialTokensForFounder[_roundId][_founder];
        }
        for(uint i = 0; i < _milestone[_investor][_roundId].length; i++){   
            uint id = _milestone[_investor][_roundId][i]._num;
            if(milestoneApprovalStatus[_roundId][id] == 1 && !milestoneWithdrawalStatus[_roundId][id]){
                unlockedTokens += (totalTokensOfInvestor[_roundId][_investor] * _milestone[_investor][_roundId][i]._percent)/ 100;
            } else if(milestoneApprovalStatus[_roundId][id] == 1 && milestoneWithdrawalStatus[_roundId][_milestone[_investor][_roundId][i]._num]){
                uint beforeTax = (totalTokensOfInvestor[_roundId][_investor] * _milestone[_investor][_roundId][i]._percent) / 100;
                uint tax = (2 * beforeTax)/ 100;
                withdrawnTokens += beforeTax - tax;
            }
        }
        lockedTokens = totalTokensOfInvestor[_roundId][_investor] - investorWithdrawnTokens[_investor][_roundId] - withdrawnTokens - withdrawalFee[_roundId] - unlockedTokens;
        return(
            unlockedTokens,
            lockedTokens,
            withdrawnTokens
        );
    }

    function investorWithdrawnToken(address _investor, uint _roundId) external view returns(uint investorWithdrawnTokenNumber){
        return investorWithdrawnTokens[_investor][_roundId];
    }

    function readTaxFee(uint _roundId) external view returns(uint transactionFee){
        return withdrawalFee[_roundId];
    }

    function milestoneWithdrawStatus(uint _roundId, uint _milestoneId) external view returns(bool){
        return milestoneWithdrawalStatus[_roundId][_milestoneId];
    }

    function initialWithdrawStatus(uint _roundId, address _founder) external view returns(bool initialWithdraw){
        return initialWithdrawalStatus[_roundId][_founder];
    }

    function availableTaxTokens(address _tokenContract) external view returns(uint taxTokens){
        return taxedTokens[_tokenContract];
    }
}

contract FundLock{
    address public _contractOwner;
    mapping(uint => mapping(address => uint)) public _amount;

    constructor (address investor, uint roundId, uint amount, address privateRoundContractAd) {
        _contractOwner = msg.sender;
        _amount[roundId][investor] = amount;
        require(ERC20(PrivateRound(privateRoundContractAd).tokenContract(roundId)).approve(privateRoundContractAd,amount), "execution failed or reverted");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";


contract Founder is Ownable{

    /*
        It saves bytecode to revert on custom errors instead of using require
        statements. We are just declaring these errors for reverting with upon various
        conditions later in this contract. Thanks, Chiru Labs!
    */
    error inputConnectedWalletAddress();
    error addressAlreadyRegistered();
    
    mapping(address => bool) private isFounder;
    address[] private pushFounders;

    // function initialize() external initializer{
    //   ///@dev as there is no constructor, we need to initialise the OwnableUpgradeable explicitly
    //    __Ownable_init();
    // }

    // function _authorizeUpgrade(address) internal override onlyOwner {}

    constructor (){
    }

    function addFounder(address _ad) external{
        if(msg.sender != _ad){ revert inputConnectedWalletAddress();}
        if(isFounder[_ad] == true){ revert addressAlreadyRegistered();}
        isFounder[_ad] = true;
        pushFounders.push(_ad);
    }

    function verifyFounder(address _ad) external view returns(bool condition){
        if(isFounder[_ad]){
            return true;
        }else{
            return false;
        }
    }

    function getAllFounderAddress() external view returns(address[] memory){
        return pushFounders;
    }    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";

contract InvestorLogin is Ownable{

    /*
        It saves bytecode to revert on custom errors instead of using require
        statements. We are just declaring these errors for reverting with upon various
        conditions later in this contract. Thanks, Chiru Labs!
    */
    error inputConnectedWalletAddress();
    error addressAlreadyRegistered();
    
    mapping(address => bool) private isInvestor;
    address[] private pushInvestors;

    constructor (){
    }

    // function initialize() external initializer{
    //   ///@dev as there is no constructor, we need to initialise the OwnableUpgradeable explicitly
    //    __Ownable_init();
    // }

    // function _authorizeUpgrade(address) internal override onlyOwner {}

    function addInvestor(address _ad) external{
        if(msg.sender != _ad){ revert inputConnectedWalletAddress();}
        if(isInvestor[_ad] == true){ revert addressAlreadyRegistered();}
        isInvestor[_ad] = true;
        pushInvestors.push(_ad);
    }

    function verifyInvestor(address _ad) external view returns(bool condition){
        if(isInvestor[_ad]){
            return true;
        }else{
            return false;
        }
    }

    function getAllInvestorAddress() external view returns(address[] memory){
        return pushInvestors;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
    event Approval(address indexed owner, address indexed spender, uint256 value);

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
    function allowance(address owner, address spender) external view returns (uint256);

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}