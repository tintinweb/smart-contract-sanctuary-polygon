// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract GameEngine is ReentrancyGuard {
    event OnParticipation(address indexed sender,  uint256 amount);
    event OnWithdraw(address indexed sender, uint256 amount);
    event OnJackpotDistribiton(address winner, uint256 amount);
    event OnTopUp(address sender, uint256 amount);
    event OnAddBalance(address indexed addr);
    event OnDeductBalance(address indexed addr);
    event OnGameEngineFundsTransfer(address indexed sender, address indexed receiver, uint256 amount);


    struct ParticipantAccount {
        address id;
        uint256 balance;
        bool init;
        address inTheGame;
        address referredBy;
    }

    address public systemAddress;
    address owner1;
    address owner2;
    // Should be adjusted before launch
    uint8 owner1PercentageFees = 1;
    uint8 owner2PercentageFees = 1;
    // Should be adjusted before launch
    uint8 jackpotPercentageFees = 1;
    uint256 public owner1Fees;
    uint256 public owner2Fees;
    uint256 public systemAddressFees;
    uint256 public jackpotFees;
    // Should be adjusted before launch 1:100
    uint256 public jackpotChance = 100;
    // Should be adjusted before launch
    uint256 public referealFees = 1;

    mapping(address => ParticipantAccount) public addressToParticipantAccounts;
    // ParticipantAddress -> GameAddress
    mapping(address => mapping( address => bool)) public approvedParticipantsGames;

    // List of the games approved by system to perform any operations with user balances
    mapping(address => bool) public systemAvailableGames;
    // Name mapping for quick access to the address
    mapping(string => address) public participantNameToAddress;
    // Name mapping for quick access to the name
    mapping(address => string) public adddressToParticipantName;

    modifier onlyFirstOwner {
        require(msg.sender == owner1, "Only owners can call this methods");
        _;
    }

     modifier onlySecondOwner {
        require(msg.sender == owner2, "Only owners can call this methods");
        _;
    }

    modifier onlySystemAddress {
        require(msg.sender == systemAddress, "G1");
        _;
    }

    modifier onlyApprovedSystemGame {
        require(isSystemAvailableGame(msg.sender), "Only approved game can call this method");
        _;
    }
    constructor(address _systemAddress, address _owner1, address _owner2) {
        systemAddress = _systemAddress;
        owner1 = _owner1;
        owner2 = _owner2;
    }


    ///////////////////////////////////////////////////////////
    //
    // PARTICIPANT/CONTRACT INTERACTIONS
    //
    ///////////////////////////////////////////////////////////

    // When user call this method he creates in game account
    // this account will be used as a deposit vault to easier interact with all GAMEv1 smart contracts in the system
    // user need to set participant name which will be displayed to other users during game process
    function createParticipantAccount(string memory _name) payable public nonReentrant returns(address) {
        require(bytes(_name).length <= 7, "Name should be max 7 symbols");
        require(getParticipantAddressByName(_name) == address(0), "Name is already exist");
        require(!getParticipantAccount(msg.sender).init, "Account is Already exists");

        ParticipantAccount memory createdAccount = ParticipantAccount({
            id: msg.sender,
            balance: msg.value,
            init: true,
            inTheGame: address(0),
            referredBy: address(0)
        });

        addressToParticipantAccounts[msg.sender] = createdAccount;
        participantNameToAddress[_name] = msg.sender;
        adddressToParticipantName[msg.sender] = _name;
        
        

        emit OnParticipation(msg.sender, msg.value);

        return msg.sender;
    }


    // When user call this method he creates in game account
    // this account will be used as a deposit vault to easier interact with all GAMEv1 smart contracts in the system
    // user need to set participant name which will be displayed to other users during game process
    // referalAddress - will be set as lifetime referal address which will get fees from all participantAccount wins in GAMEv1 contracts
    function createParticipantAccountWithRef(string memory _name, address _referalAddress) payable public nonReentrant returns(address) {
        require(bytes(_name).length <= 7, "Name should be max 7 symbols");
        require(getParticipantAddressByName(_name) == address(0), "Name is already exist");
        require(_referalAddress != msg.sender, "You cannot refer yourself");
        require(getParticipantAccount(_referalAddress).init, "Ref Address is not a participant");

        ParticipantAccount memory createdAccount = ParticipantAccount({
            id: msg.sender,
            balance: msg.value,
            init: true,
            inTheGame: address(0),
            referredBy: _referalAddress
        });

        addressToParticipantAccounts[msg.sender] = createdAccount;
        participantNameToAddress[_name] = msg.sender;
        adddressToParticipantName[msg.sender] = _name;

        emit OnParticipation(msg.sender, msg.value);

        return msg.sender;
    }


    // Participants should call this method when they want to add funds to thair game account
    // nonReentrant
    function topUpParticipantAccount() payable nonReentrant public  {
        require(getParticipantAccount(msg.sender).init, "Participant Account is not init yet");
        addressToParticipantAccounts[msg.sender].balance += msg.value;
        emit OnTopUp(msg.sender, msg.value);
    }

    
    // Participants are able to call this function to withdraw all funds from thair in-game accounts;
    function withdraw(uint256 _amount) public nonReentrant {
        require(addressToParticipantAccounts[msg.sender].init, "G2");
        require(addressToParticipantAccounts[msg.sender].inTheGame == address(0), "G9");
        require(addressToParticipantAccounts[msg.sender].balance >= _amount, "Balance should be more then amount");
        payable(msg.sender).transfer(_amount);
        addressToParticipantAccounts[msg.sender].balance -= _amount;

        emit OnWithdraw(msg.sender, _amount);
    }

    // Transfer funds from your ingame account to any others ingame account
    function transferGameEngineFunds(address _to, uint256 _amount) public nonReentrant {
        require(addressToParticipantAccounts[msg.sender].init, "G2");
        require(addressToParticipantAccounts[_to].init, "Receiver account does not exist");
        require(addressToParticipantAccounts[msg.sender].balance >= _amount, "Balance should be more then amount");
        addressToParticipantAccounts[msg.sender].balance -= _amount;
        addressToParticipantAccounts[_to].balance += _amount;
        emit OnGameEngineFundsTransfer(msg.sender, _to, _amount);
    }

    // Participants need to approve GEMEv1 contract before thay can participate in GEMEv1 contract
    function approveGame(address _gameAddress) public {
        require(isSystemAvailableGame(_gameAddress), "G4");
        require(addressToParticipantAccounts[msg.sender].init, "G5");
        require(!approvedParticipantsGames[msg.sender][_gameAddress], "G6");
        approvedParticipantsGames[msg.sender][_gameAddress] = true;
    }

    // Participants are able to remove game from thair approved GAMEv1 list
    // only if participant is not in the game
    function rejectGame(address _gameAddress) public {
        require(isSystemAvailableGame(_gameAddress), "G4");
        require(approvedParticipantsGames[msg.sender][_gameAddress], "G7");
        require(addressToParticipantAccounts[msg.sender].init, "G5");
        require(addressToParticipantAccounts[msg.sender].inTheGame == address(0), "G9");
        approvedParticipantsGames[msg.sender][_gameAddress] = false;
    }

    ///////////////////////////////////////////////////////////
    //
    // PARTICIPANT/CONTRACT INTERACTIONS
    //
    ///////////////////////////////////////////////////////////



    ///////////////////////////////////////////////////////////
    //
    // SYSTEM ADDRESS/CONTRACT INTERACTIONS
    //
    ///////////////////////////////////////////////////////////


    function addSystemGame(address _gameAddress) public onlySystemAddress {
        systemAvailableGames[_gameAddress] = true;
    }

    function removeSystemGame(address _gameAddress) public onlySystemAddress {
        delete systemAvailableGames[_gameAddress];
    }

    ///////////////////////////////////////////////////////////
    //
    // SYSTEM ADDRESS/CONTRACT INTERACTIONS
    //
    ///////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////
    //
    // APPROVED GAMEv1 CONTRACTS/CONTRACT INTERACTIONS
    //
    ///////////////////////////////////////////////////////////

    // Approved GAMEv1 are avaliable to change statuses of Participants Accounts 
    function changeInGameStatus(address _value, address _addr) external onlyApprovedSystemGame {
        require(approvedParticipantsGames[_addr][msg.sender], "G8");
        addressToParticipantAccounts[_addr].inTheGame = _value;
    }

    // Approved GAMEv1 are avaliable to change balances of Participants Accounts 
    function deductBalance(uint256 _value, address _addr) external onlyApprovedSystemGame {
        require(approvedParticipantsGames[_addr][msg.sender], "G8");
        addressToParticipantAccounts[_addr].balance -= _value;
        emit OnDeductBalance(_addr);
    }


    // Approved GAMEv1 are avaliable to deduct _jackpot, owner1, owner2 and system fees and return new gamePot with deducted fees
    // System fees is dynamic value which should be calcualted separately for each game type
    // As a developer you should always be sure that your game is addBalances for deductedAmount
    function deductPlatformFees(uint256 _gamePotValue, uint256 _systemFees) external onlyApprovedSystemGame returns (uint256){
        uint256 _jackpotFees = _getJackpotFee(_gamePotValue);
        uint256 _owner1Fees = _getFirstOwnerFeeFromAmount(_gamePotValue);
        uint256 _owner2Fees = _getSecondOwnerFeeFromAmount(_gamePotValue);
        uint256 totalFees = _owner1Fees + _owner2Fees + _jackpotFees + _systemFees;
        if(totalFees >= _gamePotValue) {
            return _gamePotValue;
        }

        owner1Fees += _owner1Fees;
        owner2Fees += _owner2Fees;
        systemAddressFees += _systemFees;
        jackpotFees += _jackpotFees;

        return _gamePotValue - totalFees;
    }

    // Approved GAMEv1 are avaliable to add balances of Participants Accounts.
    // As a developer you should always be sure that your game is addBalances for deductedAmount
    function addBalance(uint256 _value, address _addr) external onlyApprovedSystemGame {
        require(approvedParticipantsGames[_addr][msg.sender], "G8");

        // Distribute referal fees with 4 level depth
        address prevRefAddress = _addr;
        uint256 levelFees = _getReferalFees(_value);
        uint8 j = 0;

        while(addressToParticipantAccounts[_addr].referredBy != address(0) && j <= 4) {
            prevRefAddress = addressToParticipantAccounts[prevRefAddress].referredBy;
            addressToParticipantAccounts[prevRefAddress].balance += levelFees;
            levelFees = _getReferalFees(levelFees);
            j++;
        }

        if(addressToParticipantAccounts[_addr].referredBy != address(0)) {
            addressToParticipantAccounts[_addr].balance += _value - _getReferalFees(_value);
        } else {
            addressToParticipantAccounts[_addr].balance += _value;
        }
        emit OnAddBalance(_addr);
    }

    // Approved GAMEv1 are avaliable to add jackpot of Participants Accounts.
    function distributeJackpot(address _to) external onlyApprovedSystemGame {
       require(approvedParticipantsGames[_to][msg.sender], "G8");

       address prevRefAddress = _to;
       uint256 levelFees = _getReferalFees(jackpotFees);
       uint8 j = 0;

       while(addressToParticipantAccounts[_to].referredBy != address(0) && j <= 4) {
            prevRefAddress = addressToParticipantAccounts[prevRefAddress].referredBy;
            addressToParticipantAccounts[prevRefAddress].balance += levelFees;
            levelFees = _getReferalFees(levelFees);
            j++;
        }
    
        if(addressToParticipantAccounts[_to].referredBy == address(0)) {
            addressToParticipantAccounts[_to].balance += jackpotFees;  
        } else {
            addressToParticipantAccounts[_to].balance += jackpotFees - _getReferalFees(jackpotFees);  
        }
         

       // Increase chance to win jackpot

       jackpotChance += 1;

       emit OnJackpotDistribiton(_to, jackpotFees);

       jackpotFees = 0;
    }

    ///////////////////////////////////////////////////////////
    //
    // APPROVED GAMEv1 CONTRACTS/CONTRACT INTERACTIONS
    //
    ///////////////////////////////////////////////////////////


    ///////////////////////////////////////////////////////////
    //
    // OWNER ADDRESS CONTRACTS/CONTRACT INTERACTIONS
    //
    ///////////////////////////////////////////////////////////

    // Method to withdraw fees of owners
    // 
    function withdrawFirstOwnerFees() external onlyFirstOwner nonReentrant {
        require(owner1Fees > 0, "Balance should be more then 0");


        payable(owner1).transfer(owner1Fees);

        owner1Fees = 0;
    }

    // Method to withdraw fees of owners
    // 
    function withdrawSecondOwnerFees() external onlySecondOwner nonReentrant {
        require(owner2Fees > 0, "Balance should be more then 0");

        payable(owner2).transfer(owner2Fees);

        owner2Fees = 0;
    }

    // Method to withdraw fees of system Address to pay for Chainlink services

    function withdrawSystemAddressFees() external onlySystemAddress nonReentrant {
        require(systemAddressFees > 0, "Balance should be more then 0");

        payable(systemAddress).transfer(systemAddressFees);

        systemAddressFees = 0;
    }


    ///////////////////////////////////////////////////////////
    //
    // OWNER ADDRESS CONTRACTS/CONTRACT INTERACTIONS
    //
    ///////////////////////////////////////////////////////////


    ///////////////////////////////////////////////////////////
    //
    // PULBIC
    //
    ///////////////////////////////////////////////////////////

    function getOwners() public view returns(address, address) {
        return (address(owner1), address(owner2));
    } 

    function getParticipantAddressByName(string memory _name) public view returns(address) {
        return participantNameToAddress[_name];
    }

    function getParticipantNameByAddress(address _addr) public view returns(string memory) {
        return adddressToParticipantName[_addr];
    }
    
    function isApprovedParticipantGame(address _participantAddress, address _gameAddress) public view returns(bool) {
        return approvedParticipantsGames[_participantAddress][_gameAddress];
    }

    function getParticipantAccount(address _addr) public view returns(ParticipantAccount memory) {
        return addressToParticipantAccounts[_addr];
    }

    function isSystemAvailableGame(address _addr) public view returns(bool) {
        return systemAvailableGames[_addr];
    }

    ///////////////////////////////////////////////////////////
    //
    // INTERNAL
    //
    ///////////////////////////////////////////////////////////
    function _getFirstOwnerFeeFromAmount(uint256 amount) internal view returns(uint256) {
        return amount * owner1PercentageFees / 100;
    }

    function _getSecondOwnerFeeFromAmount(uint256 amount) internal view returns(uint256) {
        return amount * owner2PercentageFees / 100;
    }
    function _getJackpotFee(uint256 amount) internal view returns(uint256) {
        return amount * jackpotPercentageFees / 100;
    }
    function _getReferalFees(uint256 amount) internal view returns(uint256) {
        return amount * referealFees / 100;
    }
}