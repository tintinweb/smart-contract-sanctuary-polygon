/**
 *Submitted for verification at polygonscan.com on 2022-08-13
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.7;

//Zamiata Raffle Factory contract
contract ZamiataRaffleFactory{
    address public ZamiataFactoryContractAddress;
    address public FACTORYOWNER;
    address[] public zamiataDeployedRaffles;
    address[] public zamiataUserAddress;
    uint256 public poolCreationPercentage;
    uint256 public poolCreationCost;
    uint public minPlayer;
    uint public maxPlayer;
    uint public minEntryFee;
    uint public maxEntryFee;
    bool public isEnable;
    bool public isValidationEnable;
    uint public ownerFeePercentage;
    uint public ownerFeeAmount;
    uint public slotPrice;
    uint public slotsSold;
    uint private numberOfPlayers;
    uint private entryFee;
    uint public rng;
    uint private userID;


    constructor() {
        // assign owner address of this contract
        FACTORYOWNER = msg.sender;
        ZamiataFactoryContractAddress = address(this);  
    }

    //User Data Stuct
    struct UserDatabse{
        bool isAccountActive;
        address userAddress;
        uint userDeployedRaffleCount;
        uint userParticipatedRaffleCount;
        uint userSlotLimit;
        uint userUsedSlots;
        uint userBuySlotCount;
        uint winCount;
        uint winTotalJackpot;
        uint id;
        uint managerProfit;

    }
    mapping (address => UserDatabse) public userDataAddress;

    // Function modifire
    //Restricted modifire
    modifier onlyOwner() {
        require(msg.sender == FACTORYOWNER);
        _;
    }

    function withdraw() external payable onlyOwner(){
        payable (FACTORYOWNER).transfer(address(this).balance);
    }
    
    function enableRaffleDeployment() public onlyOwner{
        if(isEnable){
            isEnable = false;
        }else{
            isEnable = true;
        } 
    }

    function enablePoolValidation() public onlyOwner{
        if(isValidationEnable){
            isValidationEnable = false;
        }else{
            isValidationEnable = true;
        } 
    }

    function enableAndDesibelUSer(address _userAddress) public onlyOwner{
        require(_userAddress !=0x0000000000000000000000000000000000000000);
        UserDatabse storage user = userDataAddress[_userAddress];
        if(user.isAccountActive){
            user.isAccountActive = false;
        }else{
            user.isAccountActive = true;
        } 
    }

    function updateFactory(uint _ownerFeePercentage, uint _poolCreationPercentage) public onlyOwner{
        require(_poolCreationPercentage >= 1);
        require(_ownerFeePercentage >=1);
        poolCreationPercentage = _poolCreationPercentage;
        ownerFeePercentage = _ownerFeePercentage;
        
    }

    function updateRaffleValue(uint _minPalyer, uint _maxPalyer, uint _minEntryFee,uint _maxEntryFee) public onlyOwner{
        require(_minPalyer >= 2);
        require(_maxPalyer >=10);
        require(_minEntryFee >= 1);
        require(_maxEntryFee >=10);
        minPlayer = _minPalyer;
        maxPlayer = _maxPalyer;
        minEntryFee = _minEntryFee;
        maxEntryFee = _maxEntryFee;
        
    }
    function updateSlotPrice(uint _slotPrice) public onlyOwner{
        slotPrice = _slotPrice;
    }

    //sell slots
    function SellSlots() public payable{
        require(msg.sender != 0x0000000000000000000000000000000000000000);
        require(msg.value >= slotPrice);
        require(userDataAddress[msg.sender].userAddress == msg.sender);
        UserDatabse storage user = userDataAddress[msg.sender];
        user.userSlotLimit += 1;
        user.userBuySlotCount += 1;
        slotsSold += 1;
        
    }

    // Create Zamiata Raffles
    function createZamiataRaffle(uint _numberOfPlayers, uint _entryFee, uint _jackpotPercentage)public payable{
        require(msg.sender != 0x0000000000000000000000000000000000000000);
        require(isEnable);
        require(_numberOfPlayers >= minPlayer && _numberOfPlayers <= maxPlayer);
        require(_entryFee >= minEntryFee && _entryFee <= maxEntryFee);
        require(_jackpotPercentage >= 50 && _jackpotPercentage <= 95);
        numberOfPlayers = _numberOfPlayers;
        entryFee = _entryFee;
        poolCreationCost = (_numberOfPlayers*_entryFee*poolCreationPercentage)/100;
        ownerFeeAmount = (_entryFee*ownerFeePercentage)/100;
        require(msg.value >= poolCreationCost);
        rng = uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,msg.sender,rng)));
        if(userDataAddress[msg.sender].userAddress == msg.sender){
            require(userDataAddress[msg.sender].isAccountActive);
            UserDatabse storage user = userDataAddress[msg.sender];
            user.userDeployedRaffleCount += 1;
            address newZamiataRaffle = address (new ZamiataRaffle(ZamiataFactoryContractAddress, ownerFeeAmount, msg.sender, FACTORYOWNER, _numberOfPlayers, _entryFee, _jackpotPercentage,rng));
            zamiataDeployedRaffles.push(newZamiataRaffle);
        }else{
            userDataAddress[msg.sender] = UserDatabse
            ({
                isAccountActive: true, 
                userAddress: msg.sender, 
                userDeployedRaffleCount: 1, 
                userParticipatedRaffleCount: 0, 
                userSlotLimit: 1,
                userUsedSlots: 0,
                userBuySlotCount: 0,
                winCount: 0,
                winTotalJackpot: 0,
                id: userID,
                managerProfit: 0
            });
            address newZamiataRaffle = address (new ZamiataRaffle(ZamiataFactoryContractAddress, ownerFeeAmount, msg.sender, FACTORYOWNER, _numberOfPlayers, _entryFee, _jackpotPercentage,rng));
            zamiataDeployedRaffles.push(newZamiataRaffle);
            zamiataUserAddress.push(msg.sender);
            userID += 1;
        }
    }
    

    // Update userdataBase used slot limit on raffle validation
    function updateUsedSlotUsed(address _raffleAddress, address _userDataAddress) public{
        UserDatabse storage user = userDataAddress[_userDataAddress];
        require(msg.sender == _raffleAddress);
        require(userDataAddress[_userDataAddress].isAccountActive);
        require(user.userUsedSlots >= 0 && user.userUsedSlots < user.userSlotLimit);
        user.userUsedSlots += 1;
    }

    // Update or create userdataBase 
    function updateOrCreateUserDatabase(address _raffleAddress, address _userDataAddress) public{
        require(msg.sender == _raffleAddress);
        if(userDataAddress[_userDataAddress].userAddress ==_userDataAddress){
            require(userDataAddress[_userDataAddress].isAccountActive);
            UserDatabse storage user = userDataAddress[_userDataAddress];
            user.userParticipatedRaffleCount += 1;

        }else{
            userDataAddress[_userDataAddress] = UserDatabse
            ({
                isAccountActive: true, 
                userAddress: _userDataAddress, 
                userDeployedRaffleCount: 0, 
                userParticipatedRaffleCount: 1, 
                userSlotLimit: 1,
                userUsedSlots: 0,
                userBuySlotCount: 0,
                winCount: 0,
                winTotalJackpot: 0,
                id: userID,
                managerProfit:0
            });
            zamiataUserAddress.push(_userDataAddress);
            userID += 1;
        }
        
    }

    //update userdata on win
    function updateJackpotAmountWinCount(address _raffleAddress, address _userDataAddress, uint _jackpotAmount, uint _managerProfit, address _managerAddress) public{
        UserDatabse storage user = userDataAddress[_userDataAddress];
        require(msg.sender == _raffleAddress);
        user.winCount += 1;
        user.winTotalJackpot += _jackpotAmount;
        updateUserSLot(_userDataAddress,_managerProfit, _managerAddress);
        
    }

    // Update user slot
    function updateUserSLot(address _userDataAddress,uint _managerProfit,address _managerAddress)internal{
        require(userDataAddress[_userDataAddress].userAddress == _userDataAddress);
        UserDatabse storage user = userDataAddress[_managerAddress];
        user.managerProfit += _managerProfit;
        user.userUsedSlots -=1;
    }

    // user Struct
    function getUserdataStruct(address _userAddress) public view returns (uint) {
        return userDataAddress[_userAddress].userDeployedRaffleCount;

    }


    // Get list of raffles
    function getDeployedRaffles() public view returns(address[] memory){
        return zamiataDeployedRaffles;
    }

    function getRaffleUsers() public view returns(address[] memory){
        return zamiataUserAddress;
    }

    
    function getPoolCreationCost() public returns (uint){
        poolCreationCost = (numberOfPlayers*entryFee*poolCreationPercentage)/100;
        return poolCreationCost;
    }
    

    // Get all details of this contract
    function getFactoryDetails() public view returns(
        address, address, uint256, uint, uint, uint, uint, uint, uint, uint, bool, bool, uint
    ){
        return(
            ZamiataFactoryContractAddress,
            FACTORYOWNER,
            poolCreationPercentage,
            address(this).balance,
            ownerFeePercentage,
            minPlayer,
            maxPlayer,
            minEntryFee,
            maxEntryFee,
            zamiataDeployedRaffles.length,
            isEnable,
            isValidationEnable,
            slotPrice
        );
    }

}

// Zamiata Raffle Contract
contract ZamiataRaffle{
    address public OWNER;
    uint public OWNERFEECOST;
    address public FACTORYADDRESS;
    address public manager;
    address public raffleAddress;
    uint public baseEntryFee;
    uint public entryFee;
    uint private deposite; 
    uint public numberOfPlayers;
    address[] public players;
    address public lastWinner;
    uint public round;
    uint public jackpotPercentage;
    uint256 public jackpotAmount;
    bool public isStart;
    bool public isRaffleEnable = true;
    uint private rafflerng;
    bool private enterSeq = true;

    mapping(address => bool) public checkEntredUser;
    
    constructor(address _FactoryContractAddress, uint _ownerFeeAmount, address _raffleCreator, address _owner, uint _numberOfPlayers, uint _entryFee, uint _jackpotPercentage, uint _rng) {
        // assign manager address of this contract
        require(msg.sender == _FactoryContractAddress);
        OWNER = _owner;
        FACTORYADDRESS = _FactoryContractAddress;
        manager = _raffleCreator;
        raffleAddress = address(this);
        baseEntryFee = _entryFee;
        entryFee = baseEntryFee + _ownerFeeAmount;
        numberOfPlayers = _numberOfPlayers;
        jackpotPercentage = _jackpotPercentage;
        jackpotAmount = ((numberOfPlayers*baseEntryFee*jackpotPercentage)/100);
        rafflerng = uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,raffleAddress,_rng)));
        isStart = false;
    }

     struct Winners{
        address winnersAddress;
        uint winAmount;
    }
    Winners[] public winnersList;

  // Function modifire
    //Restricted modifire
    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }
    modifier onlyOwner() {
        require(msg.sender == OWNER);
        _;
    }

    function enableAndDesibleRaffle()public onlyOwner{
        if(isRaffleEnable){
            isRaffleEnable = false;
        }else{
            isRaffleEnable = true;
        } 
    }

    // Helper functions
    // Random number genrator function
    function random() private view returns(uint){
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,rafflerng,players)));    
    }
    //Manager can update Jackpot Percentage
    function updateJackpotPercentage(uint _jackpotPercentage) public onlyManager{
        require(players.length <= 1);
        require(_jackpotPercentage >= 50 && _jackpotPercentage <= 95);
        jackpotPercentage = _jackpotPercentage;
        jackpotAmount = (numberOfPlayers*baseEntryFee*jackpotPercentage)/100;
        ZamiataRaffleFactory factory = ZamiataRaffleFactory(FACTORYADDRESS);
        rafflerng = uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,rafflerng,factory.rng)));
    }
    // Manager have to start this raffle
    function startThisRaffle() public onlyManager  payable {
        ZamiataRaffleFactory factory = ZamiataRaffleFactory(FACTORYADDRESS);
        require(!isStart);
        require(isRaffleEnable);
        require(factory.isEnable());
        require(factory.isValidationEnable());
        factory.updateUsedSlotUsed(raffleAddress, msg.sender);
        rafflerng = uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,rafflerng,factory.rng)));
        OWNERFEECOST = (baseEntryFee*factory.ownerFeePercentage())/100;
        entryFee = OWNERFEECOST+baseEntryFee;
        deposite = entryFee*2;
        require(msg.value >= deposite);
        isStart = true;  
    }

    //Entry function
    function entry() public payable{
        require(msg.sender != 0x0000000000000000000000000000000000000000);
        require(isStart);
        require(msg.value >= entryFee);
        require(msg.sender != manager);
        ZamiataRaffleFactory factory = ZamiataRaffleFactory(FACTORYADDRESS);
        // for(uint i = 0; i < players.length; i++ ){
        //     require(players[i] != msg.sender);
        // }
        require(players.length <= numberOfPlayers);
        if(enterSeq){
            if(!checkEntredUser[msg.sender]){
                checkEntredUser[msg.sender] = true;
                
                factory.updateOrCreateUserDatabase(raffleAddress, msg.sender);
                payable (OWNER).transfer(OWNERFEECOST);
                players.push(msg.sender);
                if(players.length >= numberOfPlayers){
                    pickWinner();
                }
               
            }else{
                checkEntredUser[msg.sender] = true;
                
                factory.updateOrCreateUserDatabase(raffleAddress, msg.sender);
                payable (OWNER).transfer(OWNERFEECOST);
                players.push(msg.sender);
                
                if(players.length >= numberOfPlayers){
                    pickWinner();
                }
                checkEntredUser[msg.sender] = true;
            }
        }
        else if(!enterSeq){
            if(checkEntredUser[msg.sender]){
                checkEntredUser[msg.sender] = false;
                
                factory.updateOrCreateUserDatabase(raffleAddress, msg.sender);
                payable (OWNER).transfer(OWNERFEECOST);
                players.push(msg.sender);
                
                if(players.length >= numberOfPlayers){
                    pickWinner();
                }
                
            }else{
                checkEntredUser[msg.sender] = false;
                
                factory.updateOrCreateUserDatabase(raffleAddress, msg.sender);
                payable (OWNER).transfer(OWNERFEECOST);
                players.push(msg.sender);
                
                if(players.length >= numberOfPlayers){
                    pickWinner();
                }
            }
        }
    }
     // Pick Winner function
    function pickWinner() internal {
        ZamiataRaffleFactory factory = ZamiataRaffleFactory(FACTORYADDRESS);
        require(players.length >= numberOfPlayers);
        uint index = random() % players.length;
        payable (players[index]).transfer(jackpotAmount);
        uint managerProfit = address(this).balance - deposite;
        payable (manager).transfer(address(this).balance);
        factory.updateJackpotAmountWinCount(raffleAddress, players[index], jackpotAmount, managerProfit, manager);
        lastWinner = players[index];
        Winners memory newWinner = Winners(lastWinner, jackpotAmount);
        winnersList.push(newWinner);
        //Reset for next round
        deposite = 0;
        isStart = false;
        players = new address[](0);
        round++;
    }
    
    // Get all details of this contract
    function getDetails() public view returns(
        uint, uint, uint, uint, uint, address, uint, uint256, address, bool, bool
    ){
        return(
            round,
            address(this).balance,
            numberOfPlayers,
            entryFee,
            players.length,
            lastWinner,
            jackpotPercentage,
            jackpotAmount,
            manager,
            isStart,
            isRaffleEnable 
        );
    }

    // Get all player list
    function getPlayer() public view returns(address[] memory){
        return players;
    }

    // Get winner list
    function getWinners() public view returns(Winners[] memory){
        return winnersList;

    }
    
}