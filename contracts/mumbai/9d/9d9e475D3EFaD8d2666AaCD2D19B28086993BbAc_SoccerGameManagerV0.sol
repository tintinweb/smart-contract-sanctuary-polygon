/**
 *Submitted for verification at polygonscan.com on 2022-08-04
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// File: contracts/SoccerGameManager.sol



pragma solidity >=0.7.0 <0.9.0;



interface SoccerCoinInterface {
    function claimReward (address _toWhom, uint256 _amount, uint256 _decimals) external;
}


interface TeamBalanceInterface {
    function transferBalance() external payable;
}


interface GenericContractInterface {
    function ownerOf(uint256 tokenId) external view returns (address);
    function isHealthGreaterThanZero (uint256 _id) external view returns(bool);
    function gamePlayed(uint256 _id, bool _trainIt) external;
}


interface SoccerTransfersInterface {
    function playerInfo(address _collectionAddress, uint256 _id) external view returns(bool);
}

contract SoccerGameManagerV0 is Ownable {


    address teamBalanceAddress = 0x6866BDDc51b42B94e7466Abf12dEE8c6357FA506;
    TeamBalanceInterface teamBalanceInterface = TeamBalanceInterface(teamBalanceAddress);

    address soccerCoinAddress = 0xF8063643039e8c6E6F9f0Db136E9c33ed27B93E2;
    SoccerCoinInterface soccerCoinInstance = SoccerCoinInterface(soccerCoinAddress);

    address soccerTransfersAddress = 0x219EE83b2fa80f1B8858F30FdE9e78F3EF7188DC;
    SoccerTransfersInterface soccerTransfersInstance = SoccerTransfersInterface(soccerTransfersAddress); 

    mapping (address => bool) public playersContracts;


    struct History {
        uint256 win;
        uint256 draw;
        uint256 lose;
    }

    struct ChoosenPlayer {
        address collectionAddress;
        uint256 id;
        string role;
    }


    mapping(address => bool) public coaches;
    mapping(address => uint256) public trainings;
    mapping(address => History) public history;

    uint256 public playPrice = 1000000000000000000 wei;

    uint256 claimSoc = 5;
    uint256 decimalsSoc = 17;

    mapping(address => bool) public alreadyInList;
    mapping(address => bool) public userCanPlay;
    mapping(address => ChoosenPlayer[]) public activeTeam;
    address [] public users;

    string [] public roles = ["goalkeeper", "defender", "midfilder", "striker"];

    string private key;


    function playGame(string memory _key, int256 _playerRating, int256 _enemyRating) public payable returns(uint256) {
        require(keccak256(abi.encodePacked(key)) == keccak256(abi.encodePacked(_key)));
        require(userCanPlay[msg.sender]);
        require(msg.value >= playPrice);

        for(uint256 i = 0; i < activeTeam[msg.sender].length; i++) {
            GenericContractInterface contractInstance = GenericContractInterface(activeTeam[msg.sender][i].collectionAddress);
            require(contractInstance.isHealthGreaterThanZero(activeTeam[msg.sender][i].id));
        }

        uint256 isWinner = 0; // 1 win 2 lose 0 draw

        if(_playerRating - _enemyRating >= 10){
            isWinner = 1;
        } else if(_playerRating - _enemyRating <= -10){
            isWinner = 2;
        } else {
            isWinner = 0;
        }


        if(!coaches[msg.sender]){
            history[msg.sender] = History(0,0,0);
            coaches[msg.sender] = true;
            trainings[msg.sender] = 0;
        }

        if(isWinner == 1){
            history[msg.sender].win += 1;
            trainings[msg.sender] += 1;
            soccerCoinInstance.claimReward(msg.sender,claimSoc, decimalsSoc);
        } else if(isWinner == 2){
            history[msg.sender].lose += 1;
        } else if(isWinner == 0){
            history[msg.sender].draw += 1;
        }

        //train
        bool train = true;
        uint256 randomizer = 1;
        for(uint256 i = 0; i < activeTeam[msg.sender].length; i++) {
            GenericContractInterface contractInstance = GenericContractInterface(activeTeam[msg.sender][i].collectionAddress);
            if(train) {
                uint256 _random = random(randomizer, 100);
                if(_random >= 60) {
                    train = false;
                    contractInstance.gamePlayed(activeTeam[msg.sender][i].id, true);
                } else {
                    randomizer *= 7;
                    contractInstance.gamePlayed(activeTeam[msg.sender][i].id, false);
                }
            } else {
                contractInstance.gamePlayed(activeTeam[msg.sender][i].id, false);
            }       
            
        }

        transferToBalance();
        return isWinner;
    }


    function isTrainAvailable (address _coach) external returns (bool) {
        require(playersContracts[msg.sender]);
        if(coaches[_coach]){
            if(trainings[_coach] > 0){
                trainings[_coach] -= 1;
                return true;
            } 
        }

        return false;
    }
    // #############################################


    // MANAGE TEAM
    function addPlayerToTeam (address _collectionAddress, uint256 _id, uint256 _role) public {
        require(playersContracts[_collectionAddress], "insert a valid address");
        require(activeTeam[msg.sender].length < 5);
        require(!soccerTransfersInstance.playerInfo(_collectionAddress, _id));
        
        GenericContractInterface contractInstance = GenericContractInterface(_collectionAddress);
        require(contractInstance.ownerOf(_id) == msg.sender);

        bool goalkeeper = false;
        if(_role == 0) {
            goalkeeper = true;
        }
        
        bool goalkeeperAlreadyInTeam = false;
        bool alreadyInTeam = false;
        for(uint256 i = 0; i < activeTeam[msg.sender].length; i++) {
            bool checkGoalKeeper = keccak256(abi.encodePacked(activeTeam[msg.sender][i].role)) == keccak256(abi.encodePacked(roles[0]));
            if( activeTeam[msg.sender][i].id == _id && activeTeam[msg.sender][i].collectionAddress == _collectionAddress ) {
                alreadyInTeam = true;
            } if (checkGoalKeeper) {
                goalkeeperAlreadyInTeam = true;
            } 
        }

        require(!goalkeeper || !goalkeeperAlreadyInTeam);
        require(!alreadyInTeam);

        ChoosenPlayer memory p = ChoosenPlayer(_collectionAddress, _id, roles[_role]);
        activeTeam[msg.sender].push(p);

        if(activeTeam[msg.sender].length == 5) {
            if(goalkeeperAlreadyInTeam || goalkeeper) {
                userCanPlay[msg.sender] = true;
                if(!alreadyInList[msg.sender]) {
                    users.push(msg.sender);
                    alreadyInList[msg.sender] = true;
                }
            }
        }             
    }


    function removePlayerFromTeam (address _collectionAddress, uint256 _id) public {
        require(playersContracts[_collectionAddress], "insert a valid address");
        require(activeTeam[msg.sender].length > 0);

        for(uint256 i = 0; i < activeTeam[msg.sender].length; i++) {
            ChoosenPlayer memory p = activeTeam[msg.sender][i];
            if(p.id == _id && p.collectionAddress == _collectionAddress) {
                activeTeam[msg.sender][i] = activeTeam[msg.sender][activeTeam[msg.sender].length-1];
                activeTeam[msg.sender].pop();
                userCanPlay[msg.sender] = false;
                return;
            }
        }
        
    }


    function removePlayer (uint256 _id, address _coach) external {
        require(playersContracts[msg.sender]);
        require(activeTeam[_coach].length > 0);

        for(uint256 i = 0; i < activeTeam[_coach].length; i++) {
            ChoosenPlayer memory p = activeTeam[_coach][i];
            if(p.id == _id && p.collectionAddress == msg.sender) {
                activeTeam[_coach][i] = activeTeam[_coach][activeTeam[_coach].length-1];
                activeTeam[_coach].pop();
                userCanPlay[_coach] = false;
                return;
            }
        }    
    }


    function changeRole(address _collectionAddress, uint256 _id, uint256 _role) public {
        require(playersContracts[_collectionAddress], "insert a valid address");

        bool goalkeeper = false;
        if(_role == 0) {
            goalkeeper = true;
        }

        bool goalkeeperAlreadyInTeam = false;
        for(uint256 i = 0; i < activeTeam[msg.sender].length; i++) {
            if(keccak256(abi.encodePacked(activeTeam[msg.sender][i].role)) == keccak256(abi.encodePacked(roles[0]))) {
                goalkeeperAlreadyInTeam = true;
                break;
            }       
        }

        require(!goalkeeper || !goalkeeperAlreadyInTeam);

        bool exists = false;
        for(uint256 i = 0; i < activeTeam[msg.sender].length; i++) {
            if(activeTeam[msg.sender][i].id == _id && activeTeam[msg.sender][i].collectionAddress == _collectionAddress) {
                exists = true;
                break;
            }
        }

        require(exists);

        for(uint256 i = 0; i < activeTeam[msg.sender].length; i++) {
            if(activeTeam[msg.sender][i].id == _id && activeTeam[msg.sender][i].collectionAddress == _collectionAddress) {
                activeTeam[msg.sender][i].role = roles[_role];
                break;
            }
        }

        if(activeTeam[msg.sender].length == 5) {
            if(goalkeeperAlreadyInTeam || goalkeeper) {
                userCanPlay[msg.sender] = true;
                if(!alreadyInList[msg.sender]) {
                    users.push(msg.sender);
                    alreadyInList[msg.sender] = true;
                }
            }
        }  

    }


    function resetTeam() public {
        delete activeTeam[msg.sender];
        userCanPlay[msg.sender] = false;
    }


    function isPlayerInTeam (address _coach, uint256 _id) external view returns(bool) {
        require(playersContracts[msg.sender]);
        
        for(uint256 i = 0; i < activeTeam[_coach].length; i++) {
            if(activeTeam[_coach][i].id == _id && activeTeam[_coach][i].collectionAddress == msg.sender) {
                return true;
            }
        }
        return false;
    }
    // #############################################


    //MATCHMAKING
    function choosePlayer() public view returns(address){

        uint256 _randomizer = 0;
        uint256 _maxValue = users.length;
        address enemy;
        while(true) {
            uint256 _random = random(_randomizer, _maxValue);
            enemy = users[_random];
            if(userCanPlay[enemy] && enemy != msg.sender){
                break;
            } else{
                _randomizer += 1;
            }

        }

        return enemy;
    }


    function random(uint256 randomizer, uint256 _maxValue) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, block.number, randomizer))) % _maxValue;
    }
    // #############################################


    // Setting Functions
    function setPlayPrice (uint256 _newPlayPrice) public onlyOwner {
        playPrice = _newPlayPrice;
    }


    function setSecretKey (string memory _newSecretKey) public onlyOwner {
        key = _newSecretKey;
    }


    function setClaimSoc (uint256 _socClaim, uint256 _decimalsSoc) public onlyOwner {
        claimSoc = _socClaim;
        decimalsSoc = _decimalsSoc;
    }


    function approveContract(address _newAddress) public onlyOwner {
        playersContracts[_newAddress] = true;
    }


    function disapproveContract(address _oldAddress) public onlyOwner {
        playersContracts[_oldAddress] = false;
    }
    // ###############################################


    // ########## Manage Finance ##########
    function transferToBalance() internal {
        teamBalanceInterface.transferBalance{value: (address(this).balance)}();
    }
}