// SPDX-License-Identifier: Copyright
//(We have a special set of skills. If any of this code is copied, we will find you, and we will kill you.)

pragma solidity ^0.8.8;


import "./Whoopy.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import "./VRFv2SubscriptionManager.sol";
import "./UpkeepManager.sol";

interface IImplementationinterface{
    function initialize(address _whoopyCreator) external ;
}

interface IVRFManager{
    function addConsumer(address consumerAddress) external ;
    function removeConsumer(address consumerAddress) external;
    function withdraw(uint256 wAmount, address to) external;

}

interface IUpkeepManager{
    function registerAndPredictID(
    string memory name,
    bytes memory encryptedEmail,
    address upkeepContract,
    uint32 gasLimit,
    bytes memory checkData,
    uint96 amount,
    uint8 source
  ) external returns (uint256 upkeepID) ;
}

contract WhoopyFactory {
    address public immutable implementationContract;
    address public immutable _manager;
    address public immutable _upkeep;
    address public constant contractOwner = 0xDD8C868Ee486e2D0778b7c174917a15ce2a4530A;
    address public immutable deployer;
    address[] public allWhoopys;

    event NewClone(address indexed _instance, address indexed creator);

    event NewConsumerAdded();

    event UpkeepAdded(uint256 _upkeepId);

    mapping(address => address[]) public whoopyList;


    constructor(address _implementation, address manager, address upkeep) {
		implementationContract = _implementation;
        _manager = manager;
        _upkeep = upkeep;
        deployer = msg.sender;
	}

	function createClone() external payable returns(address instance) { 
        require(msg.value == 10000000000000000000 wei);
		instance = Clones.clone(implementationContract);
        IImplementationinterface(instance).initialize(msg.sender);
        whoopyList[msg.sender].push(instance);
        allWhoopys.push(instance);
		emit NewClone(instance, msg.sender);

        IVRFManager(_manager).addConsumer(instance);
        emit NewConsumerAdded();
        
        uint256 upkeepID = IUpkeepManager(_upkeep).registerAndPredictID(
            "Whoopy",
            "0x",
            instance,
            5000000,
            "0x",
            5000000000000000000,
            0
        );
        emit UpkeepAdded(upkeepID);
        (bool success, ) = payable(contractOwner).call{value: 10000000000000000000}("");
        require(success, "tx failed");

        return instance;
	}

    function withdrawFunds(uint256 amount) public restricted {
        (bool success, ) = payable(contractOwner).call{value: amount}("");
        require(success, "tx failed");
    }

    modifier restricted() {
        require(msg.sender == contractOwner);
        _;
    }

}

// SPDX-License-Identifier: Copyright

pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol"; //upgradeable?
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error Whoopy__NotEnoughETHEntered();
error Whoopy__TransferFailed();
error Whoopy__NotOpen();
error Whoopy__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 whoopyState);
error Whoopy__NotSetUp();
error Whoopy__PlayerLimitReached();
error Whoopy__ContractOwnerTransferFailed();
error Whoopy__CreatorTransferFailed();
error Whoopy__WinnerLimitReached();
error Whoopy__NoPlayers();
error Whoopy__AlreadyEntered();

/**
 * @title Whoopy Contract Implementation
 * @author Whoopy
 *
 */

contract Whoopy is Initializable, VRFConsumerBaseV2, KeeperCompatibleInterface, ReentrancyGuard {
    /* Type Declarations */
    enum WhoopyState {
        OPEN,
        CALCULATING,
        CLOSED
    }

    /* State Variables */
    address payable[] private s_players;
    address[] public addressIndexes;
    address[] public allWinners;
    address payable[] private s_recentWinners;
    VRFCoordinatorV2Interface private i_vrfCoordinator;
    bytes32 public constant keyHash =
        0xd729dc84e21ae57ffb6be0053bf2b0668aa2aaf300a2a7b2ddf7dc0bb6e875a8; 
    uint64 public immutable _subscriptionId;
    uint16 public constant REQUEST_CONFIRMATIONS = 3;
    uint32 public constant callbackGasLimit = 2000000;
    address public constant contractOwner = 0xDD8C868Ee486e2D0778b7c174917a15ce2a4530A;
    address public whoopyCreator;
    uint32 public constant NUM_WORDS = 3;
    uint32 public maxWinners;

    // Lottery Variables
    address private s_recentWinner;
    address private s_recentWinner2;
    address private s_recentWinner3;
    address private s_recentWinner4;
    address private s_recentWinner5;
    WhoopyState private s_whoopyState;
    uint256 private s_lastTimeStamp;
    uint256 private interval;
    string public whoopyName;
    uint256 public entryFee;
    uint256 public maxPlayers;
    uint256 public maxEntriesPerPlayer;
    address public immutable _vrfAdd;
    bool isActive;
    bool whoopyCreated;
    uint256 preloadAmount;
    bool private upkeepPerformed;
    bool emergencyMode;

    /* Events */
    event RequestedWhoopyWinner(uint256 indexed requestId);
    event WinnersPicked(address[] winners, address contractAddress);
    event WhoopyCreated(
        string whoopyName,
        uint256 entryFee,
        uint256 maxPlayers,
        uint32 maxWinners,
        uint256 maxEntriesPerPlayer,
        uint256 interval,
        address creatorAddress,
        address whoopyAddress,
        uint256 balance,
        uint256 totalPot
    );
    event PlayerEntered(
        address playerAddress,
        uint256 maxEntriesPerPlayer,
        uint256 balance,
        uint256 currentPlayersNumber,
        string whoopyName,
        address[] players,
        uint256 entryFee,
        uint256 maxPlayers,
        uint32 maxWinners, 
        address whoopyAddress,
        address creatorAddress,
        uint256 totalPot
    );
    event PlayersRefunded();
    event BalanceUpdated(address whoopyAddress, uint256 balance);
    event Received(address sender, uint256 value);

    /* Structs */
    struct Player {
        uint256 entryCount;
        uint256 index;
    }

    /*  Mappings */
    mapping(address => Player) players;
    mapping(address => uint256) balances;

    constructor(address vrfCoordinatorV2, uint64 subscriptionId)
        VRFConsumerBaseV2(vrfCoordinatorV2)
    {
        _vrfAdd = vrfCoordinatorV2;
        _subscriptionId = subscriptionId;
        isActive = true;
    }

    /* Functions */
    function initialize(address _whoopyCreator) public payable initializer {
        require(isActive == false, "contract constructor already called"); 
        s_whoopyState = WhoopyState.CLOSED;
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfAdd);
        whoopyCreator = _whoopyCreator;
        whoopyCreated = false;
        upkeepPerformed = false;
        emergencyMode = false;
    }

    function createWhoopy(
        string memory s_whoopyName,
        uint256 s_entryFee,
        uint256 s_maxPlayers,
        uint32 s_maxWinners,
        uint256 maxEntries,
        uint256 s_interval
    ) public restricted {
        require(msg.sender == whoopyCreator, "Only creator can create Whoopy");
        require(whoopyCreated == false, "Whoopy is already created");
        whoopyName = s_whoopyName;
        entryFee = s_entryFee;
        maxPlayers = s_maxPlayers;
        maxWinners = s_maxWinners;
        maxEntriesPerPlayer = maxEntries == 0 ? 1 : maxEntries;
        interval = s_interval; //* 86400; 
        s_whoopyState = WhoopyState.OPEN;
        s_lastTimeStamp = block.timestamp;
        whoopyCreated = true;
        uint256 maxPot = (s_entryFee * s_maxPlayers) + preloadAmount;
        emit WhoopyCreated(
            whoopyName,
            entryFee,
            maxPlayers,
            maxWinners,
            maxEntriesPerPlayer,
            interval,
            msg.sender,
            address(this),
            address(this).balance,
            maxPot //emit total pot size
        );
    }

    function preloadWhoopy(uint256 amount) public payable restricted {
        require(whoopyCreated==true, "whoopy not created");
        require(msg.value == amount * 1000000000000000000 wei);
        require(s_players.length == 0, "Cannot preload after players entered");
        preloadAmount = amount;
        emit BalanceUpdated(address(this), address(this).balance);
    }

    function enterWhoopy() external payable {
        require(msg.value == entryFee * 1000000000000000000 wei, "Please pay 1 eth to enter!"); 
        require(s_whoopyState == WhoopyState.OPEN, "Whoopy is not open!");
        require(
            players[msg.sender].entryCount < maxEntriesPerPlayer,
            "You have reached the max number of entries!"
        );
        require(whoopyCreated == true, "Whoopy is not created!");
        balances[msg.sender] += entryFee * 1000000000000000000;

        if (players[msg.sender].entryCount == 0) {
            addressIndexes.push(msg.sender);
            s_players.push(payable(msg.sender));
            players[msg.sender].entryCount = 1;
            players[msg.sender].index = addressIndexes.length;
        } else {
            players[msg.sender].entryCount += 1;
        }

        if (s_whoopyState != WhoopyState.OPEN) {
            revert Whoopy__NotOpen();
        }
        if (s_players.length > maxPlayers) {
            revert Whoopy__PlayerLimitReached();
        }
        uint256 totalPot = (maxPlayers * entryFee) + preloadAmount;
        emit PlayerEntered(
            msg.sender,
            maxEntriesPerPlayer,
            address(this).balance,
            s_players.length,
            whoopyName,
            addressIndexes,
            entryFee,
            maxPlayers,
            maxWinners,
            address(this),
            whoopyCreator,
            totalPot
        ); 
    }

    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        bool isOpen = (s_whoopyState == WhoopyState.OPEN);
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > interval);
        upkeepNeeded = (isOpen && timePassed);
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        require(upkeepNeeded, "Conditions not met");
        require (upkeepPerformed == false);
        upkeepPerformed = true;
        s_whoopyState = WhoopyState.CALCULATING;
        if (!upkeepNeeded) {
            revert Whoopy__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_whoopyState)
            );
        }
        if (s_players.length < 50 || maxWinners < 3 || maxWinners > 5) { 
            if (preloadAmount > 0) {
                if (s_players.length == 0) {
                    (bool sent1, ) = whoopyCreator.call{value: preloadAmount * 1000000000000000000}(""); 
                    require(sent1, "Preload refund failed");
                } else {
                    (bool sent1, ) = whoopyCreator.call{value: preloadAmount * 1000000000000000000}(""); 
                    require(sent1, "preload refund failed");
                    uint256 refundValue = address(this).balance / s_players.length;
                    for (uint256 i = 0; i < s_players.length; i++) {
                        address payable refundAddresses = s_players[i];
                        (bool sent, ) = refundAddresses.call{value: refundValue}("");
                        require(sent, "players refund failed"); 
                    }
                }
            } else {
                if (s_players.length == 0) {
                    s_whoopyState = WhoopyState.CLOSED;
                } else {
                    uint256 refundValue = address(this).balance / s_players.length;
                    for (uint256 i = 0; i < s_players.length; i++) {
                        address payable refundAddresses = s_players[i];
                        (bool sent, ) = refundAddresses.call{value: refundValue}("");
                        require(sent, "players refund failed");
                    }
                }
            }
            s_whoopyState = WhoopyState.CLOSED;
            emit PlayersRefunded();
        } else {
            uint256 requestId = i_vrfCoordinator.requestRandomWords(
                keyHash,
                _subscriptionId,
                REQUEST_CONFIRMATIONS,
                callbackGasLimit,
                maxWinners
            );
            emit RequestedWhoopyWinner(requestId);
            }

    }

    function fulfillRandomWords(
        uint256, /*requestId*/
        uint256[] memory randomWords
    ) internal override nonReentrant {
        if (maxWinners == 3) {
            uint256 indexOfWinner = randomWords[0] % s_players.length;
            uint256 indexOfWinner2 = randomWords[1] % s_players.length;
            uint256 indexOfWinner3 = randomWords[2] % s_players.length;
            address payable recentWinner = s_players[indexOfWinner];
            address payable recentWinner2 = s_players[indexOfWinner2];
            address payable recentWinner3 = s_players[indexOfWinner3];
            s_recentWinner = recentWinner;
            s_recentWinner2 = recentWinner2;
            s_recentWinner3 = recentWinner3;
            s_recentWinners.push(payable(recentWinner));
            s_recentWinners.push(payable(recentWinner2));
            s_recentWinners.push(payable(recentWinner3));
            allWinners.push(recentWinner);
            allWinners.push(recentWinner2);
            allWinners.push(recentWinner3);
            s_whoopyState = WhoopyState.CLOSED;
            s_lastTimeStamp = block.timestamp;
            (bool success1, ) = payable(contractOwner).call{value: address(this).balance / 5}("");
            (bool success2, ) = payable(whoopyCreator).call{value: address(this).balance / 4}("");
            (bool success3, ) = recentWinner.call{value: address(this).balance / 3}("");
            (bool success4, ) = recentWinner2.call{value: address(this).balance / 2}("");
            (bool success, ) = recentWinner3.call{value: address(this).balance}("");
            if (!success1) {
                revert Whoopy__ContractOwnerTransferFailed();
            }
            if (!success2) {
                revert Whoopy__CreatorTransferFailed();
            }
            if (!success3) {
                revert Whoopy__CreatorTransferFailed();
            }
            if (!success4) {
                revert Whoopy__CreatorTransferFailed();
            }
            if (!success) {
                revert Whoopy__TransferFailed();
            }
            emit WinnersPicked(allWinners, address(this));
        }
        if (maxWinners == 4) {
            uint256 indexOfWinner = randomWords[0] % s_players.length;
            uint256 indexOfWinner2 = randomWords[1] % s_players.length;
            uint256 indexOfWinner3 = randomWords[2] % s_players.length;
            uint256 indexOfWinner4 = randomWords[3] % s_players.length;
            address payable recentWinner = s_players[indexOfWinner];
            address payable recentWinner2 = s_players[indexOfWinner2];
            address payable recentWinner3 = s_players[indexOfWinner3];
            address payable recentWinner4 = s_players[indexOfWinner4];
            s_recentWinner = recentWinner;
            s_recentWinner2 = recentWinner2;
            s_recentWinner3 = recentWinner3;
            s_recentWinner4 = recentWinner4;
            s_recentWinners.push(payable(recentWinner));
            s_recentWinners.push(payable(recentWinner2));
            s_recentWinners.push(payable(recentWinner3));
            s_recentWinners.push(payable(recentWinner4));
            allWinners.push(recentWinner);
            allWinners.push(recentWinner2);
            allWinners.push(recentWinner3);
            allWinners.push(recentWinner4);
            s_whoopyState = WhoopyState.CLOSED;
            s_lastTimeStamp = block.timestamp;
            (bool success1, ) = payable(contractOwner).call{value: address(this).balance / 5}("");
            (bool success2, ) = payable(whoopyCreator).call{value: address(this).balance / 4}("");
            (bool success3, ) = recentWinner.call{value: address(this).balance / 4}("");
            (bool success4, ) = recentWinner2.call{value: address(this).balance / 3}("");
            (bool success5, ) = recentWinner3.call{value: address(this).balance / 2}("");
            (bool success, ) = recentWinner4.call{value: address(this).balance}("");
            if (!success1) {
                revert Whoopy__ContractOwnerTransferFailed();
            }
            if (!success2) {
                revert Whoopy__CreatorTransferFailed();
            }
            if (!success3) {
                revert Whoopy__CreatorTransferFailed();
            }
            if (!success4) {
                revert Whoopy__CreatorTransferFailed();
            }
            if (!success5) {
                revert Whoopy__CreatorTransferFailed();
            }
            if (!success) {
                revert Whoopy__TransferFailed();
            }
            emit WinnersPicked(allWinners, address(this));
        }

        if (maxWinners == 5) {
            uint256 indexOfWinner = randomWords[0] % s_players.length;
            uint256 indexOfWinner2 = randomWords[1] % s_players.length;
            uint256 indexOfWinner3 = randomWords[2] % s_players.length;
            uint256 indexOfWinner4 = randomWords[3] % s_players.length;
            uint256 indexOfWinner5 = randomWords[4] % s_players.length;
            address payable recentWinner = s_players[indexOfWinner];
            address payable recentWinner2 = s_players[indexOfWinner2];
            address payable recentWinner3 = s_players[indexOfWinner3];
            address payable recentWinner4 = s_players[indexOfWinner4];
            address payable recentWinner5 = s_players[indexOfWinner5];
            s_recentWinner = recentWinner;
            s_recentWinner2 = recentWinner2;
            s_recentWinner3 = recentWinner3;
            s_recentWinner4 = recentWinner4;
            s_recentWinner5 = recentWinner5;
            s_recentWinners.push(payable(recentWinner));
            s_recentWinners.push(payable(recentWinner2));
            s_recentWinners.push(payable(recentWinner3));
            s_recentWinners.push(payable(recentWinner4));
            s_recentWinners.push(payable(recentWinner5));
            allWinners.push(recentWinner);
            allWinners.push(recentWinner2);
            allWinners.push(recentWinner3);
            allWinners.push(recentWinner4);
            allWinners.push(recentWinner5);
            s_whoopyState = WhoopyState.CLOSED;
            s_lastTimeStamp = block.timestamp;
            (bool success1, ) = payable(contractOwner).call{value: address(this).balance / 5}("");
            (bool success2, ) = payable(whoopyCreator).call{value: address(this).balance / 4}(""); 
            (bool success3, ) = recentWinner.call{value: address(this).balance / 5}("");
            (bool success4, ) = recentWinner2.call{value: address(this).balance / 4}("");
            (bool success5, ) = recentWinner3.call{value: address(this).balance / 3}("");
            (bool success6, ) = recentWinner4.call{value: address(this).balance / 2}("");
            (bool success, ) = recentWinner5.call{value: address(this).balance}("");
            if (!success1) {
                revert Whoopy__ContractOwnerTransferFailed();
            }
            if (!success2) {
                revert Whoopy__CreatorTransferFailed();
            }
            if (!success3) {
                revert Whoopy__CreatorTransferFailed();
            }
            if (!success4) {
                revert Whoopy__CreatorTransferFailed();
            }
            if (!success5) {
                revert Whoopy__CreatorTransferFailed();
            }
            if (!success6) {
                revert Whoopy__CreatorTransferFailed();
            }
            if (!success) {
                revert Whoopy__TransferFailed();
            }
            emit WinnersPicked(allWinners, address(this));
        }
    }


//In case of emergencies, such as if Chainlink Oracle fails, to ensure tokens are not locked in the contract,
//we will enable emergency mode and allow players to withdraw their balances.

    function refundPreload() emergency public {
        (bool success, ) = payable(whoopyCreator).call{value: preloadAmount * 1000000000000000000}("");
        require(success, "withdraw failed");
    }


    function setEmergencyMode() emergency public {
        emergencyMode = true;
    }

    function withdrawEntryFee() public {
        require(balances[msg.sender] >= entryFee * 1000000000000000000);
        require(emergencyMode == true);
        balances[msg.sender] -= entryFee * 1000000000000000000;
        (bool sent, ) = msg.sender.call{value: entryFee * 1000000000000000000}("");
        require(sent, "failed to send ether");
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
}

    modifier restricted() {
        require(msg.sender == whoopyCreator);
        _;
    }

    modifier emergency() {
        require(msg.sender == contractOwner);
        _;
    }
}

// SPDX-License-Identifier: MIT
// An example of a consumer contract that also owns and manages the subscription
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";


contract VRFv2SubscriptionManager is VRFConsumerBaseV2 {
  VRFCoordinatorV2Interface public COORDINATOR;
  LinkTokenInterface LINKTOKEN;

  // Goerli coordinator. For other networks,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  //address vrfCoordinatorV2 = 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D;

  // Goerli LINK token contract. For other networks, see
  // https://docs.chain.link/docs/vrf-contracts/#configurations
  address link_token_contract = 0xb0897686c545045aFc77CF20eC7A532E3120E0F1;

  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  bytes32 keyHash = 0xd729dc84e21ae57ffb6be0053bf2b0668aa2aaf300a2a7b2ddf7dc0bb6e875a8; //mumbai

  // A reasonable default is 100000, but this value could be different
  // on other networks.
  uint32 callbackGasLimit = 1000000;

  // The default is 3, but you can set this higher.
  uint16 requestConfirmations = 3;

  // For this example, retrieve 2 random values in one request.
  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
  uint32 numWords =  2;

  // Storage parameters
  uint256[] public s_randomWords;
  uint256 public s_requestId;
  uint64 public s_subscriptionId;
  address s_owner;
  uint256 amount = 9000000000000000000;
  uint256 value = 10000000000000000000;
  address public contractOwner = 0xDD8C868Ee486e2D0778b7c174917a15ce2a4530A;
  address public wfAddress;


  constructor(address vrfCoordinatorV2) VRFConsumerBaseV2(vrfCoordinatorV2) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinatorV2);
    LINKTOKEN = LinkTokenInterface(link_token_contract);
    s_owner = msg.sender;

    //Create a new subscription when you deploy the contract.
    createNewSubscription();
  }

  // Assumes the subscription is funded sufficiently.
  function requestRandomWords() external onlyOwner {
    // Will revert if subscription is not set and funded.
    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
  }

  function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory randomWords
  ) internal override {
    s_randomWords = randomWords;
  }

  // Create a new subscription when the contract is initially deployed.
  function createNewSubscription() private onlyOwner {
    s_subscriptionId = COORDINATOR.createSubscription();
  }

  // Assumes this contract owns link.
  // 1000000000000000000 = 1 LINK
  function topUpSubscription() public { 
    LINKTOKEN.transferAndCall(address(COORDINATOR), amount, abi.encode(s_subscriptionId));
  }

  function fundContract(address from, address to) external {
    LINKTOKEN.transferFrom(from, to, value);
  }

  function addConsumer(address consumerAddress) external onlyWFAddress {
    // Add a consumer contract to the subscription.
    COORDINATOR.addConsumer(s_subscriptionId, consumerAddress);
  }

  function removeConsumer(address consumerAddress) public onlyContractOwner {
    // Remove a consumer contract from the subscription.
    COORDINATOR.removeConsumer(s_subscriptionId, consumerAddress);
  }

  function cancelSubscription(address receivingWallet) public onlyContractOwner {
    // Cancel the subscription and send the remaining LINK to a wallet address.
    COORDINATOR.cancelSubscription(s_subscriptionId, receivingWallet);
    s_subscriptionId = 0;
  }

  // Transfer this contract's funds to an address.
  // 1000000000000000000 = 1 LINK
  function withdraw(uint256 wAmount, address to) public onlyContractOwner {
    LINKTOKEN.transfer(to, wAmount);
  }

  function getSubId() public view returns(uint64) {
    return s_subscriptionId;
  }

  function setWfAddress(address _wfAddress) public onlyContractOwner {
    wfAddress = _wfAddress;
  }

  modifier onlyOwner() {
    require(msg.sender == s_owner); 
    _;
  }

  modifier onlyContractOwner() {
    require(msg.sender == contractOwner);
    _;
  }

  modifier onlyWFAddress() {
    require(msg.sender == wfAddress); 
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

// UpkeepIDConsumerExample.sol imports functions from both ./KeeperRegistryInterface.sol and
// ./interfaces/LinkTokenInterface.sol

import {KeeperRegistryInterface, State, Config} from "@chainlink/contracts/src/v0.8/interfaces/KeeperRegistryInterface.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

/**
* THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
* THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
* DO NOT USE THIS CODE IN PRODUCTION.
*/

interface KeeperRegistrarInterface {
  function register(
    string memory name,
    bytes calldata encryptedEmail, //changed to memory from calldata
    address upkeepContract,
    uint32 gasLimit,
    address adminAddress,
    bytes calldata checkData, //changed to memory from calldata
    uint96 amount,
    uint8 source,
    address sender
  ) external;
}


contract UpkeepManager {

  LinkTokenInterface public immutable i_link; 
  address public immutable registrar = 0xDb8e8e2ccb5C033938736aa89Fe4fa1eDfD15a1d; //0xDb8e8e2ccb5C033938736aa89Fe4fa1eDfD15a1d; //changed to polygon
  KeeperRegistryInterface public immutable i_registry; 
  bytes4 registerSig = KeeperRegistrarInterface.register.selector;

  address private immutable linkAddress = 0xb0897686c545045aFc77CF20eC7A532E3120E0F1;
  address private immutable registryAddress =  0x02777053d6764996e594c3E88AF1D58D5363a2e6;

  address public contractOwner = 0xDD8C868Ee486e2D0778b7c174917a15ce2a4530A;
  address public wfAddress;

  event UpkeepAdded(uint256 _upkeepId);

  constructor(
  ) {
    i_link = LinkTokenInterface(linkAddress);
    i_registry = KeeperRegistryInterface(registryAddress);
  }

  function registerAndPredictID(
    string memory name,
    bytes calldata encryptedEmail,
    address upkeepContract,
    uint32 gasLimit,
    bytes calldata checkData,
    uint96 amount,
    uint8 source
  ) public onlyWFAddress returns (uint256 upkeepID) {
    (State memory state, Config memory _c, address[] memory _k) = i_registry.getState();
    uint256 oldNonce = state.nonce;
    bytes memory payload = abi.encode(
      name,
      encryptedEmail,
      upkeepContract,
      gasLimit,
      contractOwner,
      checkData,
      amount,
      source,
      address(this)
    );
    
    i_link.transferAndCall(registrar, amount, bytes.concat(registerSig, payload));
    (state, _c, _k) = i_registry.getState();
    uint256 newNonce = state.nonce;
    if (newNonce == oldNonce + 1) {
      upkeepID = uint256(
        keccak256(abi.encodePacked(blockhash(block.number - 1), address(i_registry), uint32(oldNonce)))
      );
      emit UpkeepAdded(upkeepID);
      return upkeepID;
    } else {
      revert("auto-approve disabled");
    }
  }

  function withdraw(uint256 wAmount, address to) public onlyContractOwner { // enter in 1000000000000000000
    i_link.transfer(to, wAmount);
  }

  function setWfAddress(address _wfAddress) public onlyContractOwner {
    wfAddress = _wfAddress;
  }

  modifier onlyContractOwner() {
    require(msg.sender == contractOwner); 
    _;
  }

  modifier onlyWFAddress() {
    require(msg.sender == wfAddress); 
    _;
  }
  
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

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
        /// @solidity memory-safe-assembly
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
        /// @solidity memory-safe-assembly
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
        /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
// A mock for testing code that relies on VRFCoordinatorV2.
pragma solidity ^0.8.4;

import "../interfaces/LinkTokenInterface.sol";
import "../interfaces/VRFCoordinatorV2Interface.sol";
import "../VRFConsumerBaseV2.sol";

contract VRFCoordinatorV2Mock is VRFCoordinatorV2Interface {
  uint96 public immutable BASE_FEE;
  uint96 public immutable GAS_PRICE_LINK;

  error InvalidSubscription();
  error InsufficientBalance();
  error MustBeSubOwner(address owner);

  event RandomWordsRequested(
    bytes32 indexed keyHash,
    uint256 requestId,
    uint256 preSeed,
    uint64 indexed subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords,
    address indexed sender
  );
  event RandomWordsFulfilled(uint256 indexed requestId, uint256 outputSeed, uint96 payment, bool success);
  event SubscriptionCreated(uint64 indexed subId, address owner);
  event SubscriptionFunded(uint64 indexed subId, uint256 oldBalance, uint256 newBalance);
  event SubscriptionCanceled(uint64 indexed subId, address to, uint256 amount);

  uint64 s_currentSubId;
  uint256 s_nextRequestId = 1;
  uint256 s_nextPreSeed = 100;
  struct Subscription {
    address owner;
    uint96 balance;
  }
  mapping(uint64 => Subscription) s_subscriptions; /* subId */ /* subscription */

  struct Request {
    uint64 subId;
    uint32 callbackGasLimit;
    uint32 numWords;
  }
  mapping(uint256 => Request) s_requests; /* requestId */ /* request */

  constructor(uint96 _baseFee, uint96 _gasPriceLink) {
    BASE_FEE = _baseFee;
    GAS_PRICE_LINK = _gasPriceLink;
  }

  /**
   * @notice fulfillRandomWords fulfills the given request, sending the random words to the supplied
   * @notice consumer.
   *
   * @dev This mock uses a simplified formula for calculating payment amount and gas usage, and does
   * @dev not account for all edge cases handled in the real VRF coordinator. When making requests
   * @dev against the real coordinator a small amount of additional LINK is required.
   *
   * @param _requestId the request to fulfill
   * @param _consumer the VRF randomness consumer to send the result to
   */
  function fulfillRandomWords(uint256 _requestId, address _consumer) external {
    uint256 startGas = gasleft();
    if (s_requests[_requestId].subId == 0) {
      revert("nonexistent request");
    }
    Request memory req = s_requests[_requestId];

    uint256[] memory words = new uint256[](req.numWords);
    for (uint256 i = 0; i < req.numWords; i++) {
      words[i] = uint256(keccak256(abi.encode(_requestId, i)));
    }

    VRFConsumerBaseV2 v;
    bytes memory callReq = abi.encodeWithSelector(v.rawFulfillRandomWords.selector, _requestId, words);
    (bool success, ) = _consumer.call{gas: req.callbackGasLimit}(callReq);

    uint96 payment = uint96(BASE_FEE + ((startGas - gasleft()) * GAS_PRICE_LINK));
    if (s_subscriptions[req.subId].balance < payment) {
      revert InsufficientBalance();
    }
    s_subscriptions[req.subId].balance -= payment;
    delete (s_requests[_requestId]);
    emit RandomWordsFulfilled(_requestId, _requestId, payment, success);
  }

  /**
   * @notice fundSubscription allows funding a subscription with an arbitrary amount for testing.
   *
   * @param _subId the subscription to fund
   * @param _amount the amount to fund
   */
  function fundSubscription(uint64 _subId, uint96 _amount) public {
    if (s_subscriptions[_subId].owner == address(0)) {
      revert InvalidSubscription();
    }
    uint96 oldBalance = s_subscriptions[_subId].balance;
    s_subscriptions[_subId].balance += _amount;
    emit SubscriptionFunded(_subId, oldBalance, oldBalance + _amount);
  }

  function requestRandomWords(
    bytes32 _keyHash,
    uint64 _subId,
    uint16 _minimumRequestConfirmations,
    uint32 _callbackGasLimit,
    uint32 _numWords
  ) external override returns (uint256) {
    if (s_subscriptions[_subId].owner == address(0)) {
      revert InvalidSubscription();
    }

    uint256 requestId = s_nextRequestId++;
    uint256 preSeed = s_nextPreSeed++;

    s_requests[requestId] = Request({subId: _subId, callbackGasLimit: _callbackGasLimit, numWords: _numWords});

    emit RandomWordsRequested(
      _keyHash,
      requestId,
      preSeed,
      _subId,
      _minimumRequestConfirmations,
      _callbackGasLimit,
      _numWords,
      msg.sender
    );
    return requestId;
  }

  function createSubscription() external override returns (uint64 _subId) {
    s_currentSubId++;
    s_subscriptions[s_currentSubId] = Subscription({owner: msg.sender, balance: 0});
    emit SubscriptionCreated(s_currentSubId, msg.sender);
    return s_currentSubId;
  }

  function getSubscription(uint64 _subId)
    external
    view
    override
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    )
  {
    if (s_subscriptions[_subId].owner == address(0)) {
      revert InvalidSubscription();
    }
    return (s_subscriptions[_subId].balance, 0, s_subscriptions[_subId].owner, new address[](0));
  }

  function cancelSubscription(uint64 _subId, address _to) external override onlySubOwner(_subId) {
    emit SubscriptionCanceled(_subId, _to, s_subscriptions[_subId].balance);
    delete (s_subscriptions[_subId]);
  }

  modifier onlySubOwner(uint64 _subId) {
    address owner = s_subscriptions[_subId].owner;
    if (owner == address(0)) {
      revert InvalidSubscription();
    }
    if (msg.sender != owner) {
      revert MustBeSubOwner(owner);
    }
    _;
  }

  function getRequestConfig()
    external
    pure
    override
    returns (
      uint16,
      uint32,
      bytes32[] memory
    )
  {
    return (3, 2000000, new bytes32[](0));
  }

  function addConsumer(uint64 _subId, address _consumer) external pure override {
    revert("not implemented");
  }

  function removeConsumer(uint64 _subId, address _consumer) external pure override {
    revert("not implemented");
  }

  function requestSubscriptionOwnerTransfer(uint64 _subId, address _newOwner) external pure override {
    revert("not implemented");
  }

  function acceptSubscriptionOwnerTransfer(uint64 _subId) external pure override {
    revert("not implemented");
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
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
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
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
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
pragma solidity ^0.8.0;

contract KeeperBase {
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

interface KeeperCompatibleInterface {
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
  function checkUpkeep(bytes calldata checkData) external virtual returns (bool upkeepNeeded, bytes memory performData);

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
  function performUpkeep(bytes calldata performData) external virtual ;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice config of the registry
 * @dev only used in params and return values
 * @member paymentPremiumPPB payment premium rate oracles receive on top of
 * being reimbursed for gas, measured in parts per billion
 * @member flatFeeMicroLink flat fee paid to oracles for performing upkeeps,
 * priced in MicroLink; can be used in conjunction with or independently of
 * paymentPremiumPPB
 * @member blockCountPerTurn number of blocks each oracle has during their turn to
 * perform upkeep before it will be the next keeper's turn to submit
 * @member checkGasLimit gas limit when checking for upkeep
 * @member stalenessSeconds number of seconds that is allowed for feed data to
 * be stale before switching to the fallback pricing
 * @member gasCeilingMultiplier multiplier to apply to the fast gas feed price
 * when calculating the payment ceiling for keepers
 * @member minUpkeepSpend minimum LINK that an upkeep must spend before cancelling
 * @member maxPerformGas max executeGas allowed for an upkeep on this registry
 * @member fallbackGasPrice gas price used if the gas price feed is stale
 * @member fallbackLinkPrice LINK price used if the LINK price feed is stale
 * @member transcoder address of the transcoder contract
 * @member registrar address of the registrar contract
 */
struct Config {
  uint32 paymentPremiumPPB;
  uint32 flatFeeMicroLink; // min 0.000001 LINK, max 4294 LINK
  uint24 blockCountPerTurn;
  uint32 checkGasLimit;
  uint24 stalenessSeconds;
  uint16 gasCeilingMultiplier;
  uint96 minUpkeepSpend;
  uint32 maxPerformGas;
  uint256 fallbackGasPrice;
  uint256 fallbackLinkPrice;
  address transcoder;
  address registrar;
}

/**
 * @notice config of the registry
 * @dev only used in params and return values
 * @member nonce used for ID generation
 * @ownerLinkBalance withdrawable balance of LINK by contract owner
 * @numUpkeeps total number of upkeeps on the registry
 */
struct State {
  uint32 nonce;
  uint96 ownerLinkBalance;
  uint256 expectedLinkBalance;
  uint256 numUpkeeps;
}

interface KeeperRegistryBaseInterface {
  function registerUpkeep(
    address target,
    uint32 gasLimit,
    address admin,
    bytes calldata checkData
  ) external returns (uint256 id);

  function performUpkeep(uint256 id, bytes calldata performData) external returns (bool success);

  function cancelUpkeep(uint256 id) external;

  function addFunds(uint256 id, uint96 amount) external;

  function setUpkeepGasLimit(uint256 id, uint32 gasLimit) external;

  function getUpkeep(uint256 id)
    external
    view
    returns (
      address target,
      uint32 executeGas,
      bytes memory checkData,
      uint96 balance,
      address lastKeeper,
      address admin,
      uint64 maxValidBlocknumber,
      uint96 amountSpent
    );

  function getActiveUpkeepIDs(uint256 startIndex, uint256 maxCount) external view returns (uint256[] memory);

  function getKeeperInfo(address query)
    external
    view
    returns (
      address payee,
      bool active,
      uint96 balance
    );

  function getState()
    external
    view
    returns (
      State memory,
      Config memory,
      address[] memory
    );
}

/**
 * @dev The view methods are not actually marked as view in the implementation
 * but we want them to be easily queried off-chain. Solidity will not compile
 * if we actually inherit from this interface, so we document it here.
 */
interface KeeperRegistryInterface is KeeperRegistryBaseInterface {
  function checkUpkeep(uint256 upkeepId, address from)
    external
    view
    returns (
      bytes memory performData,
      uint256 maxLinkPayment,
      uint256 gasLimit,
      int256 gasWei,
      int256 linkEth
    );
}

interface KeeperRegistryExecutableInterface is KeeperRegistryBaseInterface {
  function checkUpkeep(uint256 upkeepId, address from)
    external
    returns (
      bytes memory performData,
      uint256 maxLinkPayment,
      uint256 gasLimit,
      uint256 adjustedGasWei,
      uint256 linkEth
    );
}